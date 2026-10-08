#!/usr/bin/env python3
"""Maintain the config's external tools without changing their install providers."""

import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request


ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "scripts/tools.json"

if sys.version_info < (3, 12):
    sys.exit("This updater requires Python 3.12 or newer; select an existing compatible python3 on PATH")


def run(argv, *, env=None, capture=False, cwd=ROOT):
    print("  " + shlex.join(map(str, argv)), flush=True)
    return subprocess.run(
        argv, check=True, cwd=cwd, env=env, text=True,
        stdout=subprocess.PIPE if capture else None,
    )


def release_metadata(repository, version):
    endpoint = "latest" if version == "latest" else "tags/v" + version.removeprefix("v")
    request = urllib.request.Request(
        f"https://api.github.com/repos/{repository}/releases/{endpoint}",
        headers={"Accept": "application/vnd.github+json", "User-Agent": "nvim-config-updater"},
    )

    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def activate(executable, link):
    link.parent.mkdir(parents=True, exist_ok=True)

    if link.exists() and not link.is_symlink():
        raise RuntimeError(f"Refusing to replace a non-symlink executable: {link}")

    with tempfile.TemporaryDirectory(prefix=".link-", dir=link.parent) as directory:
        temporary_link = Path(directory) / link.name
        temporary_link.symlink_to(executable)
        temporary_link.replace(link)


def verify_executable(executable, version):
    result = run([str(executable), "--version"], capture=True)
    lines = result.stdout.splitlines()

    if not lines:
        raise RuntimeError(f"Executable returned no version: {executable}")

    first_line = lines[0]

    if not re.search(rf"(?<![\d.]){re.escape(version)}(?![\d.])", first_line):
        raise RuntimeError(f"Unexpected executable version: {first_line}")

    print("  " + first_line, flush=True)


def install_manual(tool, version="latest"):
    if platform.system() != "Darwin":
        raise RuntimeError("This manifest describes your macOS installation; add other platform assets before using it there")

    arch = tool["architectures"].get(platform.machine())

    if not arch:
        raise RuntimeError(f"Unsupported architecture for {tool['name']}: {platform.machine()}")

    metadata = release_metadata(tool["repository"], version)
    tag = metadata["tag_name"]

    if not re.fullmatch(r"v?\d+\.\d+\.\d+", tag) or metadata.get("draft") or metadata.get("prerelease"):
        raise RuntimeError(f"Not a stable versioned release: {tag}")

    resolved_version = tag.removeprefix("v")
    asset_name = tool["asset"].format(arch=arch)
    asset = next((asset for asset in metadata["assets"] if asset["name"] == asset_name), None)

    if not asset or not re.fullmatch(r"sha256:[0-9a-f]{64}", asset.get("digest") or ""):
        raise RuntimeError(f"Missing asset or official SHA256 digest: {asset_name}")

    local_root = Path.home() / ".local"
    install_root = local_root / "opt"
    destination = install_root / f"{tool['name']}-{resolved_version}"
    executable = destination / "bin" / tool["name"]
    install_root.mkdir(parents=True, exist_ok=True)

    if destination.exists():
        verify_executable(executable, resolved_version)
    else:
        with tempfile.TemporaryDirectory(prefix=f".{tool['name']}-", dir=install_root) as directory:
            staging = Path(directory)
            archive = staging / asset_name
            request = urllib.request.Request(asset["browser_download_url"], headers={"User-Agent": "nvim-config-updater"})
            print(f"  Downloading {asset['browser_download_url']}", flush=True)

            with urllib.request.urlopen(request, timeout=60) as response, archive.open("wb") as output:
                shutil.copyfileobj(response, output)

            with archive.open("rb") as downloaded:
                digest = hashlib.file_digest(downloaded, "sha256").hexdigest()

            if digest != asset["digest"].split(":", 1)[1]:
                raise RuntimeError(f"SHA256 mismatch: {asset_name}")

            if tool["format"] == "tar.gz":
                with tarfile.open(archive, "r:gz") as distribution:
                    distribution.extractall(staging / "unpacked", filter="data")

                payload = staging / "unpacked" / tool["archive_root"].format(arch=arch)
            elif tool["format"] == "gz":
                payload = staging / "payload"
                (payload / "bin").mkdir(parents=True)
                unpacked = payload / "bin" / tool["name"]

                with gzip.open(archive, "rb") as source, unpacked.open("wb") as output:
                    shutil.copyfileobj(source, output)

                unpacked.chmod(0o755)
            else:
                raise RuntimeError(f"Unknown archive format: {tool['format']}")

            verify_executable(payload / "bin" / tool["name"], resolved_version)
            payload.rename(destination)

    activate(executable, local_root / "bin" / tool["name"])

    if tool["name"] == "nvim":
        version_file = ROOT / ".nvim-version"

        with tempfile.NamedTemporaryFile(mode="w", dir=ROOT, prefix=".nvim-version-", delete=False) as output:
            output.write(resolved_version + "\n")
            temporary_version = Path(output.name)

        temporary_version.replace(version_file)

    print(f"  Active: {executable} (previous versions retained)", flush=True)


def expand_steps(group, context):
    return [[argument.format_map(context) for argument in step] for step in group["steps"]]


def mason(env, *, plan=False):
    mason_env = {**env, "NVIM_TOOLS_MANIFEST": str(MANIFEST_PATH), "NVIM_TOOLS_ROOT": str(ROOT)}
    argv = ["nvim", "--headless", "-i", "NONE", "-n"]

    if plan:
        mason_env["NVIM_TOOLS_PLAN"] = "1"
        argv.extend(["-u", "NONE", "--cmd", "lua vim.opt.rtp:prepend(vim.env.NVIM_TOOLS_ROOT)"])

    run([*argv, "+luafile scripts/install-mason.lua"], env=mason_env)


def update_brew(manifest, env):
    packages = manifest["brew"]

    if not packages:
        return

    brew_env = {
        **env, "HOMEBREW_NO_AUTO_UPDATE": "1", "HOMEBREW_NO_INSTALL_CLEANUP": "1", "HOMEBREW_NO_ASK": "1",
    }

    run(["brew", "update"], env=brew_env)
    installed = set(run(["brew", "list", "--formula", "-1"], env=brew_env, capture=True).stdout.splitlines())
    missing = [package for package in packages if package not in installed]
    present = [package for package in packages if package in installed]

    if missing:
        run(["brew", "install", "--formula", *missing], env=brew_env)

    if present:
        run(["brew", "upgrade", "--formula", *present], env=brew_env)


def texlive(manifest, env):
    config = manifest["texlive"]
    manager = Path(config["bin"]) / "tlmgr"

    if not manager.exists():
        raise RuntimeError("Existing MacTeX installation not found; install MacTeX before maintaining its packages")

    installed = run([str(manager), "--version"], env=env, capture=True).stdout

    if f"version {config['year']}" not in installed:
        raise RuntimeError("TeX Live year changed: update scripts/tools.json's year and matching repository first")

    prefix = ["sudo", str(manager), "--repository", config["repository"]]
    run([*prefix, "update", "--self"], env=env)
    run([*prefix, "install", *config["packages"]], env=env)
    run([*prefix, "update", *config["packages"]], env=env)


def check_managed(manifest):
    missing = []

    for provider, executables in manifest["managed"].items():
        for executable in executables:
            path = shutil.which(executable)
            print(f"  {provider}: {executable} → {path or 'MISSING'}", flush=True)

            if not path:
                missing.append(executable)

    if missing:
        raise RuntimeError("Missing externally managed tools: " + ", ".join(missing) + "; run just update-nix for Nix packages")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["plan", "nvim", "tools", "all", "nix"])
    parser.add_argument("--version", default="latest")
    args = parser.parse_args()

    if not re.fullmatch(r"latest|v?\d+\.\d+\.\d+", args.version):
        parser.error("version must be latest or a stable release number such as 0.12.5")

    manifest = json.loads(MANIFEST_PATH.read_text())
    context = {
        "home": str(Path.home()), "bin": str(Path.home() / ".local/bin"),
        "stack_resolver": os.environ.get("NVIM_STACK_RESOLVER", manifest["stack_resolver"]),
    }

    context["nix_directory"] = manifest["nix"]["directory"].format_map(context)
    env = {**os.environ, "NVIM_LOG_FILE": "/dev/null"}
    env["PATH"] = os.pathsep.join([
        context["bin"], str(Path.home() / ".cargo/bin"), str(Path.home() / ".ghcup/bin"),
        str(Path.home() / ".elan/bin"), manifest["texlive"]["bin"], env.get("PATH", ""),
    ])
    failures = []

    def attempt(name, operation):
        print(f"\n{name}", flush=True)

        try:
            operation()
        except (OSError, RuntimeError, ValueError, tarfile.TarError, subprocess.CalledProcessError) as error:
            failures.append(name)
            print(f"FAILED: {error}", file=sys.stderr, flush=True)

    if args.action == "plan":
        for tool in manifest["manual"]:
            print(f"Manual download: {tool['name']} ← {tool['repository']} (verified SHA256, ~/.local/opt)")

        print("Homebrew install/upgrade: " + ", ".join(manifest["brew"]))

        for group in manifest["commands"]:
            print(group["name"])

            for step in expand_steps(group, context):
                print("  " + shlex.join(step))

        print(f"TeX Live {manifest['texlive']['year']}: maintain {', '.join(manifest['texlive']['packages'])} using the matching archived repository (sudo)")
        attempt("Externally managed tools (Nix updates use the separate update-nix recipe)", lambda: check_managed(manifest))
        attempt("Mason packages from opts.mason plus supplemental entries", lambda: mason(env, plan=True))
    else:
        if args.action in {"nvim", "all"}:
            tool = next(tool for tool in manifest["manual"] if tool["name"] == "nvim")
            attempt("Neovim", lambda: install_manual(tool, args.version))

            if failures:
                return 1

        if args.action in {"tools", "all"}:
            attempt("Homebrew tools", lambda: update_brew(manifest, env))

            for tool in manifest["manual"]:
                if tool["name"] != "nvim":
                    attempt(tool["name"], lambda tool=tool: install_manual(tool))

            for group in manifest["commands"]:
                for step in expand_steps(group, context):
                    attempt(group["name"] + ": " + shlex.join(step), lambda step=step: run(step, env=env))

            attempt("Mason tools", lambda: mason(env))
            attempt("TeX Live packages", lambda: texlive(manifest, env))
            attempt("Externally managed tools", lambda: check_managed(manifest))

        if args.action == "nix":
            for step in expand_steps(manifest["nix"], context):
                run(step, env=env)

    if failures:
        print("\nFailed steps:\n  " + "\n  ".join(failures), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
