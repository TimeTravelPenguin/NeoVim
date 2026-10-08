set positional-arguments

# Show the available maintenance commands.
default:
    @just --list

# Show installation methods and commands without downloading or changing anything.
plan:
    @python3 scripts/update-tools.py plan

# Check recipe formatting and exercise installers with offline temporary fixtures.
check:
    @just --fmt --check
    @python3 -B scripts/update-tools-test.py

# Download and activate the latest stable Neovim, or a specific release such as 0.12.5.
[confirm("Download and install Neovim? Previous installations will be retained.")]
update-nvim version="latest":
    @python3 scripts/update-tools.py nvim --version "$1"

# Install/update the external tools used by this configuration.
[confirm("Install/update the configured tools using their existing package managers?")]
update-tools:
    @python3 scripts/update-tools.py tools

# Update Neovim and its external tools in one run.
[confirm("Download and install Neovim and update its configured external tools?")]
update version="latest":
    @python3 scripts/update-tools.py all --version "$1"

# Update the Nix flake and rebuild the entire existing Nix-Darwin system.
[confirm("Update the Nix flake and rebuild the whole Nix-Darwin system? This also updates non-Neovim packages.")]
update-nix:
    @python3 scripts/update-tools.py nix
