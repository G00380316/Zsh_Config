#!/usr/bin/env bash
set -e

# --- CONFIGURATION & ARGUMENT PARSING ---

# Initialize Dry Run flag
DRY_RUN=false

# Process command-line arguments for dry run flag
for arg in "$@"; do
	case $arg in
	--dry=true)
		DRY_RUN=true
		shift
		;;
	esac
done

# Package list includes all entries from your final block.
packages=(
	"coreutils" "fzf" "bob" "gcc" "firefox"
	"kitty" "kodi" "node" "python" "git"
	"rust" "zoxide" "lsd" "fastfetch" "imagemagick" "lazygit"
	"temurin@8" "temurin@21" "ripgrep" "libplist" "ipatool"
	"font-jetbrains-mono" "font-caskaydia-cove-nerd-font" "watchman" "ngrok"
	"db-browser-for-sqlite" "fd" "bat" "github" "tldr" "git-lfs"
	"tree-sitter-cli" "docker" "docker-compose" "docker-desktop"
    "mpv" "mas" "xcp" "sioyek"
    # "visual-studio-code"
	"lua-language-server" "basedpyright" "typescript-language-server" "xcode-build-server"
	"bash-language-server" "texlab" "harper" "jdtls" "markdown-oxide"
	"pyrefly" "quick-lint-js" "ruff" "rust-analyzer" "sqruff"
	"superhtml" "llvm" "ty" "tinymist" "docker-language-server"
)

npm_packages=(
  "css-variables-language-server" "vscode-langservers-extracted"
  "cssmodules-language-server" "oxlint" "@tailwindcss/language-server"
  "devsense-php-ls" "@microsoft/compose-language-service"
)


# Colors and labels for script output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"

# Announce Dry Run Mode if active
if $DRY_RUN; then
	echo "${WARN} --- DRY RUN MODE IS ACTIVE ---"
	echo "${WARN} No actual installation, configuration, or file changes will occur."
fi

# Initial Setup
mkdir -p ~/.config
mkdir -p Install-Logs

LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

# --- HOMEBREW SETUP ---

echo "${CAT} Checking for Homebrew installation..."
if ! command -v brew &>/dev/null; then
	echo "${ERROR} Homebrew not found. Installing..."
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would install Xcode Command Line Tools and Homebrew."
	else
		xcode-select --install || true
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
		eval "$(/opt/homebrew/bin/brew shellenv)"
	fi
else
	echo "${OK} Homebrew already installed. Updating environment."
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "${INFO} Font casks are now part of the main Homebrew repo — no separate tap needed."

# --- SYSTEM SETUP ---

echo "${CAT} Setting system host and computer names to Enoch-MacBook or Enoch-MacMini..."
if $DRY_RUN; then
	echo "${INFO} (DRY RUN): Would set HostName/LocalHostName/ComputerName."
else
	NAMES=("Enoch-MacBook" "Enoch-MacMini")

	for i in "${!NAMES[@]}"; do
		echo "$((i + 1))) ${NAMES[$i]}"
	done

	echo -n "Enter your choice (1 or 2): "
	read -r CHOICE

	if [[ "$CHOICE" == "1" ]]; then
		sudo scutil --set HostName "Enoch-MacBook"
		sudo scutil --set LocalHostName "Enoch-MacBook"
		sudo scutil --set ComputerName "Enoch-MacBook"
	elif [[ "$CHOICE" == "2" ]]; then
		sudo scutil --set HostName "Enoch-MacMini"
		sudo scutil --set LocalHostName "Enoch-MacMini"
		sudo scutil --set ComputerName "Enoch-MacMini"
	else
		echo "Invalid option"
		exit 1
	fi
fi

echo "${CAT} Installing Rosetta 2 (for Apple Silicon Macs)..."
if $DRY_RUN; then
	echo "${INFO} (DRY RUN): Would run 'sudo softwareupdate --install-rosetta --agree-to-license'."
else
	sudo softwareupdate --install-rosetta --agree-to-license || true
fi

# --- FUNCTIONS ---

# Progress indicator function (simplified) - only used in actual install
show_progress() {
	local pid=$1
	local pkg=$2
	local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
	local i=0
	tput civis
	while ps -p "$pid" &>/dev/null; do
		printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$pkg" "${spin_chars[i]}"
		i=$(((i + 1) % 10))
		sleep 0.1
	done
	printf "\r${OK} ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$pkg" ""
	tput cnorm
}

# Check if a package or cask is installed
is_installed() {
	brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

npm_is_installed() {
  npm list -g --depth=0 "$1" &>/dev/null
}

mac_app_is_installed() {
  mas list "$1" &>/dev/null
}

# Install all packages from the list
install_packages() {
	local installed=0
	local skipped=0
	local failed=0

	for pkg in "${packages[@]}"; do
		if is_installed "$pkg"; then
			echo "${INFO} ${YELLOW}$pkg${RESET} already installed — skipping..."
			echo "[SKIPPED] $pkg already installed" >>"$LOG"
			((skipped++))
			continue
		fi

		echo "${NOTE} Installing ${YELLOW}$pkg${RESET}..."

		if $DRY_RUN; then
			local install_type="formula"
			if brew info "$pkg" | grep -q "Cask"; then
				install_type="cask"
			fi
			echo "${INFO} (DRY RUN): Would run 'brew install --$install_type $pkg'"
			echo "[DRY RUN] Would install $pkg" >>"$LOG"
			printf "\r${OK} ${YELLOW}%s${RESET} (DRY RUN) Action logged!%-20s\n" "$pkg" ""
			((installed++)) # Increment installed count for summary clarity in dry run
			continue
		fi

		# --- Actual Installation Block ---
		if (brew info "$pkg" | grep -q "Cask"); then
			(brew install --cask "$pkg" >>"$LOG" 2>&1) &
		else
			(brew install "$pkg" >>"$LOG" 2>&1) &
		fi

		pid=$!
		show_progress $pid "$pkg"

		if wait $pid; then
			((installed++))
		else
			echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Check ${LOG}"
			echo "[ERROR] $pkg installation failed" >>"$LOG"
			((failed++))
		fi
	done

	echo
	echo "${OK} Installation Summary:"
	echo "  ✅ Installed: ${installed}"
	echo "  ⚙️  Skipped: ${skipped}"
	echo "  ❌ Failed: ${failed}"
	echo
	echo "Full logs saved to ${LOG}"
}

install_npm_packages() {
  echo "${CAT} Installing global npm packages..."

  local installed=0
  local skipped=0
  local failed=0

  for pkg in "${npm_packages[@]}"; do
    if npm_is_installed "$pkg"; then
      echo "${INFO} ${YELLOW}$pkg${RESET} already installed — skipping..."
      ((skipped++))
      continue
    fi

    echo "${NOTE} Installing ${YELLOW}$pkg${RESET} (npm -g)..."

    if $DRY_RUN; then
      echo "${INFO} (DRY RUN): Would run 'npm install -g $pkg'"
      ((installed++))
      continue
    fi

    if npm install -g "$pkg" >>"$LOG" 2>&1; then
      echo "${OK} ${YELLOW}$pkg${RESET} installed successfully"
      ((installed++))
    else
      echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install"
      ((failed++))
    fi
  done

  echo
  echo "${OK} npm Installation Summary:"
  echo "  ✅ Installed: ${installed}"
  echo "  ⚙️  Skipped: ${skipped}"
  echo "  ❌ Failed: ${failed}"
  echo
}

install_mac_apps() {
  echo "${CAT} Installing Mac apps..."

  local installed=0
  local skipped=0
  local failed=0

  for pkg in "${mac_apps[@]}"; do
    if mac_app_is_installed "$pkg"; then
      echo "${INFO} ${YELLOW}$pkg${RESET} already installed — skipping..."
      ((skipped++))
      continue
    fi

    echo "${NOTE} Installing ${YELLOW}$pkg${RESET} (mas install)..."

    if $DRY_RUN; then
      echo "${INFO} (DRY RUN): Would run 'mas install $pkg'"
      ((installed++))
      continue
    fi

    if mas install "$pkg" >>"$LOG" 2>&1; then
      echo "${OK} ${YELLOW}$pkg${RESET} installed successfully"
      ((installed++))
    else
      echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install"
      ((failed++))
    fi
  done

  echo
  echo "${OK} npm Installation Summary:"
  echo "  ✅ Installed: ${installed}"
  echo "  ⚙️  Skipped: ${skipped}"
  echo "  ❌ Failed: ${failed}"
  echo
}

# Function to move config and asset files
move_assets() {
	echo "${CAT} Moving asset files to config directory..."

	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would create directories and copy configuration files to ~/.config and ~/"
		return
	fi

	# --- Actual File Operations ---
	mkdir -p ~/.config/fastfetch
	mkdir -p ~/.config/kitty
	mkdir -p ~/.config/scripts/
	mkdir -p ~/Documents/Github/Mac_Install/

	if ! $DRY_RUN; then
		if command -v git &>/dev/null; then
			if [ -d "$HOME/Documents/Github/Mac_Install/.git" ]; then
				echo "[ACTION] Repo exists. Pulling updates..."
				git -C "$HOME/Documents/Github/Mac_Install" pull --rebase
			else
				echo "[ACTION] Cloning repo..."
				git clone --recursive https://github.com/G00380316/Mac_Install.git "$HOME/Documents/Github/Mac_Install"
			fi
		else
			echo "[ERROR] Git is not installed."
			exit 1
		fi
	fi

	cp -r ~/Documents/Github/Mac_Install/assets/config-compact.jsonc ~/.config/fastfetch/
	cp -r ~/Documents/Github/Mac_Install/assets/.zshrc ~/
	cp -r ~/Documents/Github/Mac_Install/assets/.zshenv ~/
	cp -r ~/Documents/Github/Mac_Install/assets/pm.sh ~/.config/scripts/
	cp -r ~/Documents/Github/Mac_Install/assets/cht.sh ~/.config/scripts/
	cp -r ~/Documents/Github/Mac_Install/assets/.p10k.zsh ~/
	cp -r ~/Documents/Github/Mac_Install/assets/kitty.conf ~/.config/kitty/
	mkdir -p ~/.hammerspoon/
	cp -r ~/Documents/Github/Mac_Install/assets/init.lua ~/.hammerspoon/

	sudo mkdir -p /usr/local/bin || true
	sudo chown -R "$USER" ~/.config
	chmod -R u=rwX,go=rX,go-w ~/.config
	chmod +x ~/.config/scripts/*

	echo "${OK} Asset files moved."
}

# --- MAIN INSTALL LOOP ---

echo "${CAT} Starting Homebrew package installation..."
install_packages

echo "${CAT} Configuring assets and scripts..."
move_assets

echo "${CAT} Starting Npm package installation..."
install_npm_packages

echo "${CAT} Starting App Store apps installation..."
install_mac_apps 

# Install Pokemon Colorscripts
if [ -f "$HOME/Documents/Github/Mac_Install/assets/Pokemon-ColorScript-Mac/install.sh" ]; then
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would run 'sudo ~/Documents/Github/Mac_Install/assets/Pokemon-ColorScript-Mac/install.sh'"
	else
		cd "$HOME/Documents/Github/Mac_Install/assets/Pokemon-ColorScript-Mac/"
		./install.sh
	fi
else
	echo "${WARN} Could not find assets/pokemon-colorscripts/install.sh - skipping." >>"$LOG"
fi

echo "${NOTE} Setting up Swift in Neovim..."
if [ -d /Applications/Xcode.app/Contents/Developer ]; then
	echo "${INFO} Trying to Point to Xcode Swift Compiler..."
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would run 'sudo xcode-select -s /Applications/Xcode.app/Contents/Developer'"
	else
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
		echo "${INFO} xcode-build-server Setup Completed!"
	fi
else
	echo "${INFO} Xcode not installed trying to install..."
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would run 'sudo xcode-select -s /Applications/Xcode.app/Contents/Developer' and Installing Xcode"
	else
		echo "${INFO} Installing Xcode..."
        mas install 497799835
		echo "${INFO} Xcode installed!"
	    echo "${INFO} Trying to Point to Xcode Swift Compiler..."
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
		echo "${INFO} xcode-build-server Setup Completed!"
	fi
fi

echo "${NOTE} Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
	echo "${INFO} Updating existing nvim config..."
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would run 'git -C ~/.config/nvim pull'"
	else
		git -C ~/.config/nvim pull
	fi
else
	echo "${INFO} Cloning nvim config..."
	if $DRY_RUN; then
		echo "${INFO} (DRY RUN): Would run 'git clone https://github.com/G00380316/nvim.git ~/.config/nvim'."
	else
		echo "${INFO} Installing Neovim nightly..."
        bob install nightly
		echo "${INFO} Neovim nightly installed!"
        bob use nightly
		echo "${INFO} Using Neovim nightly."
		git clone https://github.com/G00380316/nvim.git ~/.config/nvim
		echo "${INFO} Cloning finished!"
	fi
fi

echo
echo "${OK} All package installations and configurations complete. Logs saved to ${LOG}"
