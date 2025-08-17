# dotfiles


My dotfiles

## Installation

These dotfiles include an opinionated installer script, `install.sh`, which will install and configure several tools on Debian-based systems (nushell, oh-my-posh, pyenv, rust, atuin, carapace, etc.). Recommended approach is to run the installer from this repository root.

Quick (recommended)

```bash
chmod +x install.sh
./install.sh
```

The script uses `sudo` for system-level steps. If `sudo` is not available you may need to run the script as root.

Manual nushell install (Fury apt repo)

If you prefer to install nushell yourself using the Fury apt repository, run the following commands:

```bash
curl -fsSL https://apt.fury.io/nushell/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/fury-nushell.gpg
echo "deb https://apt.fury.io/nushell/ /" | sudo tee /etc/apt/sources.list.d/fury.list
sudo apt update
sudo apt install -y nushell
```

> TODO: Integrate with GNU Stow

Optional: deploy dotfiles with GNU Stow

If you use GNU Stow to symlink package directories into your `$HOME`, you can run the following from the repo root:

```bash
sudo apt update && sudo apt install -y stow   # if stow is missing
cd $(pwd)                                     # ensure you're in the repo root
stow -t $HOME <package-name>                  # e.g. stow -t $HOME bash
```

Notes

- The installer targets Debian-like systems. It will warn if it doesn't detect a Debian derivative but will continue.
- After running the installer, log out and back in (or restart your session) so shell and PATH changes take effect.
- See `install.sh` for details and for steps the script performs.


