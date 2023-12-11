#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
HOURGLASS='\xE2\x8C\x9B'

download_url="https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz"
app_filename="nvim-v0.9.4-linux64.tar.gz"
app_path="/tmp/$app_filename"
temp_app_path="$app_path.temp"
installation_directory=$HOME/.nvim

echo_color() {
    local color_name=$1
    typeset -n color=$color_name
    local text=$2

    echo -e "$color${text}${NC}"
}

handle_error() {
    local exit_code=$1
    local error_message=$2

    echo ""
    echo -e "${RED}${CROSSMARK} Error: $error_message${NC}"
    exit $exit_code
}

install_neovim() {
    echo_color BLUE "Installing NEOVIM ..."

    echo ""
    if [ -f "$app_path" ]; then
        echo_color BLUE "Cache found, installing from cached $app_path ..."
    else
        echo_color BLUE "Cache not found, downloading resources from remote ..."
        echo ""
        wget --no-cache -c --show-progress -O "$temp_app_path" "$download_url"
        if [ $? -ne 0 ]; then
            handle_error 1 "Failed to download the application."
        fi
        mv "$temp_app_path" "$app_path" >/dev/null 2>&1
        echo_color BLUE "Download complete, installing from downloaded $app_path ..."
    fi

    echo ""
    mkdir -p "$installation_directory"
    tar zxvf $app_path -C $installation_directory >/dev/null 2>&1
    case $(basename "$SHELL") in
    fish)
        echo_color MAGENTA "Fish shell detected."

        fish_config=$HOME/.config/fish/config.fish
        echo "set --export PATH $installation_directory/nvim-linux64/bin \$PATH" >>"$fish_config"
        ;;
    zsh)
        echo_color MAGENTA "Zsh shell detected."

        zsh_config=$HOME/.zshrc
        echo "export PATH=\"$installation_directory/nvim-linux64/bin:\$PATH\"" >>"$zsh_config"
        ;;
    bash)
        echo_color MAGENTA "Bash shell detected."

        bash_configs=(
            "$HOME/.bashrc"
            "$HOME/.bash_profile"
        )
        if [[ ${XDG_CONFIG_HOME:-} ]]; then
            bash_configs+=(
                "$XDG_CONFIG_HOME/.bash_profile"
                "$XDG_CONFIG_HOME/.bashrc"
                "$XDG_CONFIG_HOME/bash_profile"
                "$XDG_CONFIG_HOME/bashrc"
            )
        fi

        for bash_config in "${bash_configs[@]}"; do
            echo "export PATH=$installation_directory/nvim-linux64/bin:\$PATH" >>"$bash_config"
        done
        ;;
    *)
        echo_color YELLOW "Unknown shell: $(basename "$SHELL")"
        echo_color BLUE "Manually add the directory to ~/.bashrc (or similar):"
        info_bold "  export PATH=\"$installation_directory/nvim-linux64/bin:\$PATH\""
        ;;
    esac

    echo ""
    echo_color GREEN "Successfully installed NEOVIM."
}

echo ""
echo_color BLUE "Setting up NEOVIM ..."
echo ""
if [ -x "$(command -v nvim &>/dev/null)" ] && ! [ -x "$(command -v $installation_directory/nvim-linux64/bin/nvim &>/dev/null)" ]; then
    echo_color YELLOW "NEOVIM is already installed at $(which nvim) ."
    echo_color YELLOW "It's suggested to uninstall it first."
    echo_color YELLOW "Do you still want to install it?"
    read -p "(y/n): " install
    echo ""
    if [ "$install" = "y" ]; then
        install_neovim
    else
        echo_color RED "Setup cancelled."
        exit 0
    fi
else
    install_neovim
fi

echo ""
echo_color BLUE "Setting up NVIM User Configuration."
# if [ -x "$(command -v git &>/dev/null)" ]; then
#     echo_color YELLOW "Git is not installed. Installing it now."
#     sudo apt install git
# fi
echo ""
echo_color BLUE "Backing up user configuration ..."
mv ~/.config/nvim ~/.config/nvim.bak >/dev/null 2>&1
echo_color GREEN "User configuration successfully backed up."
echo ""
echo_color BLUE "Installing AstroNvim ..."
git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim >/dev/null 2>&1
echo_color GREEN "AstroNvim successfully installed."
echo ""
echo_color BLUE "Setting up user configuration ..."
git clone https://github.com/banahaker/nvim-setup.git ~/.config/nvim/lua/user >/dev/null 2>&1
echo_color GREEN "User configuration successfully configured."

echo ""
echo_color GREEN "Setup complete."
