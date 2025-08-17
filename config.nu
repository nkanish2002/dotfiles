# config.nu
#
# Installed by:
# version = "0.106.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# Preferred editor
$env.config.buffer_editor = "nvim"

# Ensure common user bins are on PATH (~/.local/bin, ~/.cargo/bin)
$env.PATH ++= [($env.HOME + '/.local/bin'), ($env.HOME + '/.cargo/bin')]

# Useful aliases
alias ll = ls -la
alias l = ls -lah
alias gs = git status
alias o = xdg-open  # Debian-friendly opener
alias vim = nvim
alias vi = nvim

# Shortcuts / convenience functions
def mkcd [name] {
    mkdir $name
    cd $name
}

# Keep history size modest
$env.config.history.max_size = 5000

source ~/.local/share/atuin/init.nu
source ~/.cache/carapace/init.nu