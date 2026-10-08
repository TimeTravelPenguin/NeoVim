"""Offline regression checks; never update the user's actual installations."""

import contextlib
import gzip
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("update_tools", Path(__file__).with_name("update-tools.py"))
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class ManualInstallTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary.name).resolve()
        self.root = self.home / "config"
        self.root.mkdir()
        (self.root / ".nvim-version").write_text("0.0.1\n")
        self.home_patch = patch.object(Path, "home", return_value=self.home)
        self.root_patch = patch.object(updater, "ROOT", self.root)
        self.platform_patch = patch.object(updater.platform, "system", return_value="Darwin")
        self.arch_patch = patch.object(updater.platform, "machine", return_value="arm64")

        for patcher in [self.home_patch, self.root_patch, self.platform_patch, self.arch_patch]:
            patcher.start()
            self.addCleanup(patcher.stop)

        self.addCleanup(self.temporary.cleanup)
        self.tool = {
            "name": "nvim", "repository": "test/nvim", "asset": "nvim-{arch}.tar.gz",
            "architectures": {"arm64": "arm64"}, "format": "tar.gz", "archive_root": "nvim-arm64",
        }

        self.old_executable = self.home / ".local/opt/nvim-0.0.1/bin/nvim"
        self.old_executable.parent.mkdir(parents=True)
        self.old_executable.write_text("old installation")
        self.link = self.home / ".local/bin/nvim"
        self.link.parent.mkdir(parents=True)
        self.link.symlink_to(self.old_executable)

    def archive(self, *, unsafe=False):
        archive = io.BytesIO()

        with tarfile.open(fileobj=archive, mode="w:gz") as distribution:
            entries = {
                "nvim-arm64/bin/nvim": b"#!/bin/sh\nprintf 'NVIM v1.2.3\\n'\n",
                "nvim-arm64/share/nvim/runtime/sentinel": b"runtime retained",
            }

            if unsafe:
                entries["../outside"] = b"unsafe"

            for name, content in entries.items():
                member = tarfile.TarInfo(name)
                member.size = len(content)
                member.mode = 0o755 if name.endswith("/nvim") else 0o644
                distribution.addfile(member, io.BytesIO(content))

        return archive.getvalue()

    def install(self, archive, *, digest=None, tool=None):
        metadata = {
            "tag_name": "v1.2.3", "assets": [{
                "name": (tool or self.tool)["asset"].format(arch="arm64"),
                "digest": digest or "sha256:" + hashlib.sha256(archive).hexdigest(),
                "browser_download_url": "https://example.invalid/archive",
            }],
        }

        with patch.object(updater, "release_metadata", return_value=metadata), \
                patch.object(updater.urllib.request, "urlopen", return_value=io.BytesIO(archive)), \
                contextlib.redirect_stdout(io.StringIO()):
            updater.install_manual(tool or self.tool)

    def test_verified_install_keeps_runtime_old_version_and_switches_link(self):
        self.install(self.archive())
        installed = self.home / ".local/opt/nvim-1.2.3"
        self.assertEqual(self.link.resolve(), installed / "bin/nvim")
        self.assertEqual((installed / "share/nvim/runtime/sentinel").read_text(), "runtime retained")
        self.assertEqual(self.old_executable.read_text(), "old installation")
        self.assertEqual((self.root / ".nvim-version").read_text(), "1.2.3\n")

    def test_bad_checksum_leaves_active_editor_and_pin_unchanged(self):
        with self.assertRaisesRegex(RuntimeError, "SHA256 mismatch"):
            self.install(self.archive(), digest="sha256:" + "0" * 64)

        self.assertEqual(self.link.resolve(), self.old_executable)
        self.assertEqual((self.root / ".nvim-version").read_text(), "0.0.1\n")
        self.assertFalse((self.home / ".local/opt/nvim-1.2.3").exists())

    def test_unsafe_archive_leaves_editor_and_outside_files_unchanged(self):
        with self.assertRaises(tarfile.FilterError):
            self.install(self.archive(unsafe=True))

        self.assertEqual(self.link.resolve(), self.old_executable)
        self.assertFalse((self.home / ".local/opt/outside").exists())

    def test_downloaded_version_must_match_release_before_activation(self):
        archive = gzip.compress(b"#!/bin/sh\nprintf 'tree-sitter 9.9.9\\n'\n")
        tool = {
            "name": "tree-sitter", "repository": "test/tree-sitter", "asset": "tree-sitter-{arch}.gz",
            "architectures": {"arm64": "arm64"}, "format": "gz",
        }

        with self.assertRaisesRegex(RuntimeError, "Unexpected executable version"):
            self.install(archive, tool=tool)

        self.assertFalse((self.home / ".local/bin/tree-sitter").exists())
        self.assertFalse((self.home / ".local/opt/tree-sitter-1.2.3").exists())

    def test_existing_regular_executable_is_not_overwritten(self):
        self.link.unlink()
        self.link.write_text("user-owned executable")

        with self.assertRaisesRegex(RuntimeError, "non-symlink"):
            self.install(self.archive())

        self.assertEqual(self.link.read_text(), "user-owned executable")
        self.assertEqual((self.root / ".nvim-version").read_text(), "0.0.1\n")


class ProviderTests(unittest.TestCase):
    def test_empty_version_is_reported_as_an_installer_failure(self):
        with patch.object(updater, "run", return_value=subprocess.CompletedProcess([], 0, "")), \
                contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(RuntimeError, "no version"):
                updater.verify_executable(Path("unused"), "1.2.3")

    def test_brew_installs_missing_and_upgrades_only_named_existing_formulae(self):
        def result(argv, **kwargs):
            return subprocess.CompletedProcess(argv, 0, "tombi\nunrelated-formula\n")

        with patch.object(updater, "run", side_effect=result) as runner:
            updater.update_brew({"brew": ["tombi", "d2"]}, {})

        self.assertEqual([call.args[0] for call in runner.call_args_list], [
            ["brew", "update"], ["brew", "list", "--formula", "-1"],
            ["brew", "install", "--formula", "d2"], ["brew", "upgrade", "--formula", "tombi"],
        ])

    def test_mason_plan_uses_no_configuration_startup(self):
        with patch.object(updater, "run") as runner:
            updater.mason({}, plan=True)

        argv = runner.call_args.args[0]
        self.assertEqual(argv[argv.index("-u") + 1], "NONE")
        self.assertEqual(runner.call_args.kwargs["env"]["NVIM_TOOLS_PLAN"], "1")

    def test_failed_neovim_update_stops_combined_update(self):
        with patch("sys.argv", ["update-tools.py", "all"]), \
                patch.object(updater, "install_manual", side_effect=RuntimeError("download failed")), \
                patch.object(updater, "update_brew") as brew, \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(updater.main(), 1)

        brew.assert_not_called()

    def test_tool_failures_do_not_skip_other_providers_and_return_nonzero(self):
        with patch("sys.argv", ["update-tools.py", "tools"]), \
                patch.object(updater, "update_brew", side_effect=RuntimeError("brew failed")), \
                patch.object(updater, "install_manual"), patch.object(updater, "run"), \
                patch.object(updater, "mason") as mason, patch.object(updater, "texlive") as texlive, \
                patch.object(updater, "check_managed"), \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(updater.main(), 1)

        mason.assert_called_once()
        texlive.assert_called_once()


@unittest.skipUnless(shutil.which("just"), "just is not installed")
class JustRecipeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.addCleanup(self.temporary.cleanup)
        self.capture = self.directory / "arguments"
        python = self.directory / "python3"
        python.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$NVIM_TEST_CAPTURE"\n')
        python.chmod(0o755)
        self.env = {
            **os.environ, "PATH": str(self.directory) + os.pathsep + os.environ["PATH"],
            "NVIM_TEST_CAPTURE": str(self.capture), "JUST_YES": "false",
        }

    def recipe(self, *arguments, answer=""):
        return subprocess.run(
            [shutil.which("just"), "--justfile", str(updater.ROOT / "justfile"), *arguments],
            input=answer, text=True, capture_output=True, env=self.env,
        )

    def test_declined_confirmation_does_not_invoke_installer(self):
        result = self.recipe("update-nvim", answer="n\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.capture.exists())

    def test_confirmed_recipe_forwards_requested_version(self):
        result = self.recipe("--yes", "update-nvim", "0.12.5")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.capture.read_text().splitlines(), [
            "scripts/update-tools.py", "nvim", "--version", "0.12.5",
        ])


if __name__ == "__main__":
    unittest.main()
