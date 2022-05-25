# shellcheck shell=bash

# Name:
# Idempotent Setup
#
# Description:
# Idempotently configures the desktop. This includes:
# - Ensures mount to /storage/ur
# - Strip ~/.bashrc, etc. dotfiles from random appendage
# - Symlinks ~/.ssh, etc. software not mananged by dotfox
# - Symlinks directories to ~/.home

action() {
	# -------------------------------------------------------- #
	#                         DO MOUNT                         #
	# -------------------------------------------------------- #
	if ! grep -q /storage/ur /etc/fstab; then
		local part_uuid="c875b5ca-08a6-415e-bc11-fc37ec94ab8f"
		local mnt='/storage/ur'
		printf '%s\n' "PARTUUID=$part_uuid  $mnt  btrfs  defaults,noatime,X-mount.mkdir  0 0" \
			| sudo tee -a /etc/fstab >/dev/null
		sudo mount "$mnt"
	fi


	# -------------------------------------------------------- #
	#                   STRIP SHELL DOTFILES                   #
	# -------------------------------------------------------- #
	for file in ~/.profile ~/.bashrc ~/.bash_profile "${ZDOTDIR:-$HOME}/.zshrc" "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"; do
		if [ ! -f "$file" ]; then
			continue
		fi

		local file_string=
		while IFS= read -r line; do
			file_string+="$line"$'\n'

			if [[ "$line" == '# ---' ]]; then
				break
			fi
		done < "$file"; unset -v line

		printf '%s' "$file_string" > "$file"
	done; unset -v file
	print.info 'Cleaned shell dotfiles'


	# -------------------------------------------------------- #
	#                  REMOVE BROKEN SYMLINKS                  #
	# -------------------------------------------------------- #
	for file in "$HOME"/*; do
		if [ -L "$file" ] && [ ! -e "$file" ]; then
			unlink "$file"
		fi
	done


	# -------------------------------------------------------- #
	#               CREATE DIRECTORIES AND FILES               #
	# -------------------------------------------------------- #
	must_dir "$HOME/.dots/.home"
	must_dir "$HOME/.dots/.repos"
	must_dir "$HOME/.dots/.usr"/{bin,include,lib,libexec,local,share,src}
	must_dir "$HOME/.gnupg"
	must_dir "$HOME/.ssh"
	must_dir "$XDG_STATE_HOME/history"
	must_dir "$XDG_DATA_HOME/maven"
	must_dir "$XDG_DATA_HOME"/nano/backups
	must_dir "$XDG_DATA_HOME/zsh"
	must_dir "$XDG_DATA_HOME/X11"
	must_dir "$XDG_DATA_HOME/xsel"
	must_dir "$XDG_DATA_HOME/tig"
	must_dir "$XDG_CONFIG_HOME/sage" # $DOT_SAGE
	must_dir "$XDG_CONFIG_HOME/less" # $LESSKEY
	must_dir "$XDG_CONFIG_HOME/Code - OSS/User"
	must_dir "$XDG_DATA_HOME/gq/gq-state" # $GQ_STATE
	must_dir "$XDG_DATA_HOME/sonarlint" # $SONARLINT_USER_HOME
	must_dir "$XDG_DATA_HOME/nvm"
	must_file "$XDG_CONFIG_HOME/yarn/config"
	must_file "$XDG_DATA_HOME/tig/history"
	chmod 0700 "$HOME/.gnupg"
	chmod 0700 "$HOME/.ssh"


	# -------------------------------------------------------- #
	#               REMOVE AUTOGENERATED DOTFILES              #
	# -------------------------------------------------------- #
	must_rm .bash_history
	must_rm .dir_colors
	must_rm .dircolors
	must_rm .flutter
	must_rm .flutter_tool_state
	must_rm .gitconfig
	must_rm .gmrun_history
	must_rm .inputrc
	must_rm .lesshst
	must_rm .mkshrc
	must_rm .pulse-cookie
	must_rm .pythonhist
	must_rm .sqlite_history
	must_rm .viminfo
	must_rm .wget-hsts
	must_rm .zlogin
	must_rm .zshenv
	must_rm .zshrc
	must_rm .zprofile
	must_rm .zcompdump


	# -------------------------------------------------------- #
	#                      CREATE SYMLINKS                     #
	# -------------------------------------------------------- #
	local -r storage='/storage'
	local -r storage_home='/storage/ur/storage_home'
	local -r storage_other='/storage/ur/storage_other'

	must_link "$HOME/.dots/user/scripts" "$HOME/scripts"
	must_link "$XDG_CONFIG_HOME/X11/Xcompose" "$HOME/.Xcompose"
	must_link "$XDG_CONFIG_HOME/X11/Xmodmap" "$HOME/.Xmodmap"
	must_link "$XDG_CONFIG_HOME/X11/Xresources" "$HOME/.Xresources"
	must_link "$XDG_CONFIG_HOME/Code/User/settings.json" "$XDG_CONFIG_HOME/Code - OSS/User/settings.json"

	local -ra directoriesDefault=(
		# ~/Desktop
		~/Downloads
		~/Templates ~/Public ~/Documents
		# ~/Music
		~/Pictures
		~/Videos
	)
	local -ra directoriesCustom=(
		# ~/Desktop
		~/Dls
		~/Docs/Templates ~/Docs/Public ~/Docs
		# ~/Music
		~/Pics
		~/Vids
	)
	local -ra directoriesShared=(
		~/Desktop
		~/Music
	)
	# Use 'cp -f' for "$XDG_CONFIG_HOME/user-dirs.dirs"; sotherwise unlink/link operation races
	if [ -d "$storage" ]; then
		cp -f "$HOME/.dots/user/.config/user-dirs.dirs/user-dirs-custom.conf" "$XDG_CONFIG_HOME/user-dirs.dirs"

		# XDG User Directories
		local dir=
		for dir in "${directoriesDefault[@]}"; do
			must_rmdir "$dir"
		done; unset -v dir
		for dir in "${directoriesShared[@]}"; do
			must_dir "$dir"
		done; unset -v dir
		must_link "$storage_home/Desktop" "$HOME/Desktop"
		must_link "$storage_home/Dls" "$HOME/Dls"
		must_link "$storage_home/Docs" "$HOME/Docs"
		must_link "$storage_home/Music" "$HOME/Music"
		must_link "$storage_home/Pics" "$HOME/Pics"
		must_link "$storage_home/Vids" "$HOME/Vids"

		# Populate ~/.dots/.home/
		must_link "$HOME/Desktop" "$HOME/.dots/.home/Desktop"
		must_link "$HOME/Dls" "$HOME/.dots/.home/Downloads"
		must_link "$HOME/Docs" "$HOME/.dots/.home/Documents"
		must_link "$HOME/Music" "$HOME/.dots/.home/Music"
		must_link "$HOME/Pics" "$HOME/.dots/.home/Pictures"
		must_link "$HOME/Vids" "$HOME/.dots/.home/Videos"

		# Miscellaneous
		must_link "$storage_other/mozilla" "$HOME/.mozilla"
		if [ ! -L "$HOME/.ssh" ]; then rm -f "$HOME/.ssh/known_hosts"; fi
		must_link "$storage_other/ssh" "$HOME/.ssh"
		must_link "$storage_other/BraveSoftware" "$XDG_CONFIG_HOME/BraveSoftware"
		must_link "$storage_other/fonts" "$XDG_CONFIG_HOME/fonts"
		must_link "$storage_other/password-store" "$XDG_DATA_HOME/password-store"
	else
		cp -f "$HOME/.dots/user/.config/user-dirs.dirs/user-dirs-default.conf" "$XDG_CONFIG_HOME/user-dirs.dirs"

		# XDG User Directories
		local dir=
		for dir in "${directoriesCustom[@]}"; do
			must_rmdir "$dir"
		done; unset -v dir
		for dir in "${directoriesShared[@]}"; do
			must_dir "$dir"
		done; unset -v dir
		must_dir "$HOME/Desktop"
		must_dir "$HOME/Downloads"
		must_dir "$HOME/Documents"
		must_dir "$HOME/Templates"
		must_dir "$HOME/Public"
		must_dir "$HOME/Music"
		must_dir "$HOME/Pictures"
		must_dir "$HOME/Videos"

		# Populate ~/.dots/.home/
		must_link "$HOME/Desktop" "$HOME/.dots/.home/Desktop"
		must_link "$HOME/Downloads" "$HOME/.dots/.home/Downloads"
		must_link "$HOME/Documents" "$HOME/.dots/.home/Documents"
		must_link "$HOME/Music" "$HOME/.dots/.home/Music"
		must_link "$HOME/Pictures" "$HOME/.dots/.home/Pictures"
		must_link "$HOME/Videos" "$HOME/.dots/.home/Videos"

		# Miscellaneous
	fi

	if [ -d "$HOME/Docs/Programming" ]; then
		must_link "$HOME/Docs/Programming/challenges" "$HOME/challenges"
		must_link "$HOME/Docs/Programming/experiments" "$HOME/experiments"
		must_link "$HOME/Docs/Programming/git" "$HOME/git"
		must_link "$HOME/Docs/Programming/repos" "$HOME/repos"
		must_link "$HOME/Docs/Programming/workspaces" "$HOME/workspaces"

		local file=
		for file in ~/.dots/.usr/bin/*; do unlink "$file"; done
		for file in "$HOME/Docs/Programming/repos/Groups/Bash"/{bake,basalt,choose,hookah,foxomate,glue,rho,shelldoc,shelltest,woof}/pkg/bin/*; do
			ln -fs  "$file" ~/.dots/.usr/bin
		done; unset -v file
	else
		local file=
		for file in ~/.dots/.usr/bin/*; do unlink "$file"; done
		for file in "$HOME/Documents"/{bake,basalt,choose,hookah,foxomate,glue,rho,shelldoc,shelltest,woof}/pkg/bin/*; do
			ln -fs "$file" ~/.dots/.usr/bin
		done; unset -v file
	fi

	# Dependent on symlinking
	must_dir "$HOME/.dots/.home/Documents/Shared"
	must_dir "$HOME/.dots/.home/Pictures/Screenshots"
	must_link ~/.dots/bootstrap/dotmgr/bin/dotmgr ~/.dots/.usr/bin/dotmgr


	# -------------------------------------------------------- #
	#                DESKTOP ENVIRONMENT TWEAKS                #
	# -------------------------------------------------------- #
	set-json-key() {
		local file="$1"
		local key="$2"
		local value="$3"

		mv "$file"{,.orig}
		jq -r "$key |= $value" "$file.orig" > "$file"
		rm "$file.orig"
	}

	if [ -n "$(dconf list /org/nemo/)" ]; then
		gsettings set org.nemo.preferences.menu-config selection-menu-copy 'false'
		gsettings set org.nemo.preferences.menu-config selection-menu-cut 'false'
		gsettings set org.nemo.preferences.menu-config selection-menu-paste 'false'
		gsettings set org.nemo.preferences.menu-config selection-menu-duplicate 'false'
		gsettings set org.nemo.preferences.menu-config selection-menu-open-in-new-tab 'false'
		gsettings set org.nemo.preferences show-advanced-permissions 'true'
		gsettings set org.nemo.preferences default-folder-viewer "'list-view'"
	fi

	hotkeys.apply_screenshots() {
		# 1. Screenshot
		# 2. Screenshot clip (interactive)
		# 3. Window screenshot
		# 4. Windows screenshot clip (interactive)
		case $1 in
		cinnamon)
			;;
		mate)
			;;
		gnome)
			# Old ones?
			gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Super><Shift>p']"
			gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot-clip "['<Super>p']"
			gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['<Super><Alt>p']"
			gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot-clip "['<Super><Alt><Shift>p']"

			# Fedora, etc.
			gsettings set org.gnome.shell.keybindings.screenshot "['<Shift><Super>p']"
			gsettings set org.gnome.shell.keybindings.show-screenshot-ui "['<Super>p']"
			gsettings set org.gnome.shell.keybindings.screenshot-window "['<Alt><Super>p']"
			;;
		esac
	}

	if [ "$XDG_SESSION_DESKTOP" = 'cinnamon' ]; then
		local file="$HOME/.cinnamon/configs/menu@cinnamon.org/0.json"
		local image_file=
		for image_file in '/storage/ur/storage_home/Pics/Icons/Panda1_Transprent.png' "$HOME/Dropbox/Pictures/Icons/Panda1_Transparent.png"; do
			if [ -f "$image_file" ]; then
				set-json-key "$file" '."menu-icon".value' "\"$image_file\""
			fi
		done; unset -v image_file
		set-json-key "$file" '."menu-icon-size".value' '"36"'
		set-json-key "$file" '."menu-label".value' '""'


		local file="$HOME/.cinnamon/configs/calendar@cinnamon.org/17.json"
		set-json-key "$file" '."use-custom-format".value' 'false'

		gsettings set org.cinnamon.desktop.wm.preferences mouse-button-modifier '"<Super>"'
		gsettings set org.cinnamon.desktop.interface clock-show-date 'true'
		gsettings set org.cinnamon.desktop.keybindings looking-glass-keybinding "['']"
		gsettings set org.cinnamon.desktop.keybindings magnifier-zoom-in "['']"
		gsettings set org.cinnamon.desktop.keybindings magnifier-zoom-out "['']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot "['<Super><Shift>p']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot-clip "['<Super>p']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys restart-cinnamon "['']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys screenreader "['']" # FIXME
		gsettings set org.cinnamon.desktop.keybindings.media-keys screenreader "['XF86ScreenSaver']" # Default includes '<Control><Alt>l'
		gsettings set org.cinnamon.desktop.keybindings.media-keys screensaver "['']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys video-outputs "['XF86Display']" # Default includes '<Super>p'
		gsettings set org.cinnamon.desktop.keybindings.media-keys screenshot "['<Super><Control><Shift>p']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys screenshot-clip "['<Super><Control>p']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['<Super>Return']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys shutdown "['XF86PowerOff']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys video-rotation-lock "['']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys window-screenshot "['<Super><Alt>p']"
		gsettings set org.cinnamon.desktop.keybindings.media-keys window-screenshot-clip "['<Super><Alt><Shift>p']"
		# General window manager hotkeys
		gsettings set org.cinnamon.desktop.keybindings.wm toggle-fullscreen "['<Super>f']"
		gsettings set org.cinnamon.desktop.keybindings.wm toggle-maximized "['<Super><Shift>f']"
		# Navigating workspaces
		gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "['<Super><Control>l', '<Super><Control>Up']"
		gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-down "['<Super><Control>j', '<Super><Control>Down']"
		gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Super><Control>h', '<Super><Control>Left']"
		gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-up "['<Super><Control>k', '<Super><Control>Up']"
		# Moving window to workspace
		gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-up "['<Super><Control><Shift>k', '<Super><Control><Shift>Up']"
		gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-right "['<Super><Control><Shift>l', '<Super><Control><Shift>Right']"
		gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-down "['<Super><Control><Shift>j', '<Super><Control><Shift>Down']"
		gsettings set org.cinnamon.desktop.keybindings.wm move-to-workspace-left "['<Super><Control><Shift>h', '<Super><Control><Shift>Left']"
		# Moving window in workspace, `push-snap` is identical to `push-tile` except for the fact that snapped windows won't get covered by other maximized windows
		gsettings set org.cinnamon.desktop.keybindings.wm push-snap-up "['']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-snap-right "['']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-snap-down "['']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-snap-left "['']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-tile-up "['<Super><Alt>k', '<Super><Alt>Up']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-tile-right "['<Super><Alt>l', '<Super><Alt>Right']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-tile-down "['<Super><Alt>j', '<Super><Alt>Down']"
		gsettings set org.cinnamon.desktop.keybindings.wm push-tile-left "['<Super><Alt>h', '<Super><Alt>Left']"
	elif [ "$XDG_SESSION_DESKTOP" = 'mate' ]; then
		gsettings set org.mate.Marco.general mouse-button-modifier '<Super>'
		gsettings set org.mate.Marco.global-keybindings run-command-screenshot '<Mod4>p'
		gsettings set org.mate.Marco.global-keybindings.run-command-window-screenshot '<Super><Alt>p'
		gsettings set org.mate.Marco.global-keybindings run-command-terminal '<Mod4>Return'
		gsettings set org.mate.SettingsDaemon.plugins.media-keys power ''
		gsettings set org.mate.SettingsDaemon.plugins.media-keys screensaver ''

		gsettings set org.mate.terminal.global use-mnemonics 'false'
		gsettings set org.mate.terminal.global use-menu-accelerators 'false'
	elif [ "$XDG_SESSION_DESKTOP" = 'gnome' ]; then
		gsettings set org.gnome.desktop.wm.keybindings minimize "[]"
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]"
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "[]"
		gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "[]"
		gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "[]"
		gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
		gsettings set org.gnome.mutter.keybindings switch-monitor "['XF86Display']"

		gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
		gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver-static "[]"

		hotkeys.apply_screenshots "$XDG_SESSION_DESKTOP"

		gsettings set org.gnome.desktop.wm.keybindings.show-desktop "['<Super>d']"

		gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super>f']"
		gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super><Shift>f']"
		# Navigating workspaces
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super><Control>l', '<Super><Control>Up']"
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Super><Control>j', '<Super><Control>Down']"
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super><Control>h', '<Super><Control>Left']"
		gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Super><Control>k', '<Super><Control>Up']"
		# Moving window to workspace
		gsettings set org.gnome.desktop.wm.keybindiLngs move-to-workspace-up "['<Super><Control><Shift>k', '<Super><Control><Shift>Up']"
		gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Super><Control><Shift>l', '<Super><Control><Shift>Right']"
		gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Super><Control><Shift>j', '<Super><Control><Shift>Down']"
		gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Super><Control><Shift>h', '<Super><Control><Shift>Left']"
	elif [ "$XDG_SESSION_DESKTOP" = 'pop' ]; then
		:
	elif [ -z "$XDG_SESSION_DESKTOP" ]; then
		print.warn "Variable '\$XDG_SESSION_DESKTOP' is empty"
	fi


	# -------------------------------------------------------- #
	#                    OTHER APPLICATIONS                    #
	# -------------------------------------------------------- #
	print.info 'Running dotshellextract'
	helper.dotshellextract
	print.info 'Running dotshellgen'
	helper.dotshellgen
	print.info 'Running dotfox_deploy'
	helper.dotfox_deploy
	VBoxManage setproperty machinefolder '/storage/vault/rodinia/VirtualBox_Machines'
}


# -------------------------------------------------------- #
#                     HELPER FUNCTIONS                     #
# -------------------------------------------------------- #
must_rm() {
	util.get_path "$1"
	local file="$REPLY"

	if [ -f "$file" ]; then
		local output=
		if output=$(rm -f -- "$file" 2>&1); then
			print.info "Removed file '$file'"
		else
			print.warn "Failed to remove file '$file'"
			printf '  -> %s\n' "$output"
		fi
	fi
}

must_rmdir() {
	util.get_path "$1"
	local dir="$REPLY"

	if [ -d "$dir" ]; then
		local output=
		if output=$(rmdir -- "$dir" 2>&1); then
			print.info "Removed directory '$dir'"
		else
			print.warn "Failed to remove directory '$dir'"
			printf '  -> %s\n' "$output"
		fi
	fi
}

must_dir() {
	local d=
	for d; do
		util.get_path "$d"
		local dir="$REPLY"

		if [ ! -d "$dir" ]; then
			local output=
			if output=$(mkdir -p -- "$dir" 2>&1); then
				print.info "Created directory '$dir'"
			else
				print.warn "Failed to create directory '$dir'"
				printf '  -> %s\n' "$output"
			fi
		fi
	done; unset -v d
}

must_file() {
	util.get_path "$1"
	local file="$REPLY"

	if [ ! -f "$file" ]; then
		local output=
		if output=$(mkdir -p -- "${file%/*}" && touch -- "$file" 2>&1); then
			print.info "Created file '$file'"
		else
			print.warn "Failed to create file '$file'"
			printf '  -> %s\n' "$output"
		fi
	fi
}

must_link() {
	util.get_path "$1"
	local src="$REPLY"

	util.get_path "$2"
	local link="$REPLY"

	if [ -z "$1" ]; then
		print.warn "must_link: First parameter is emptys"
		return
	fi

	if [ -z "$2" ]; then
		print.warn "must_link: Second parameter is empty"
		return
	fi

	# Skip if already is correct
	if [ -L "$link" ] && [ "$(readlink "$link")" = "$src" ]; then
		return
	fi

	# If it is an empty directory (and not a symlink) automatically remove it
	if [ -d "$link" ] && [ ! -L "$link" ]; then
		local children=("$link"/*)
		if (( ${#children[@]} == 0)); then
			rmdir "$link"
		else
			print.warn "Skipping symlink from '$src' to '$link'"
			return
		fi
	fi
	if [ ! -e "$src" ]; then
		print.warn "Skipping symlink from '$src' to $link"
		return
	fi

	local output=
	if output=$(ln -sfT "$src" "$link" 2>&1); then
		print.info "Symlinking '$src' to $link"
	else
		print.warn "Failed to symlink from '$src' to '$link'"
		printf '  -> %s\n' "$output"
	fi
}

util.get_path() {
	if [[ ${1::1} == / ]]; then
		REPLY="$1"
	else
		REPLY="$HOME/$1"
	fi
}
