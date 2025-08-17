# Makefile for repository tasks

.PHONY: sync-nushell-config sync-vimrc

# Copy nushell configuration files into the user's nushell config directory.
# This mirrors the behavior in install.sh: create ~/.config/nushell and copy
# repo's config.nu and env.nu into it.
sync-nushell-config:
	@dest="$(HOME)/.config/nushell"; \
	if [ ! -d "$$dest" ]; then \
		mkdir -p "$$dest"; \
		echo "Created $$dest"; \
	fi; \
	cp -a config.nu env.nu "$$dest/"; \
	echo "Copied config.nu and env.nu to $$dest"

sync-vimrc:
	cp -a .vimrc "$(HOME)"