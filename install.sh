#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"
OHMYZSH_DIR="$HOME/.oh-my-zsh"
CONFIG_DIR="$HOME/.config"
REPO_URL="https://github.com/joey00072/dotfiles"

# Background jobs
RUST_TOOLS_PID=""

# URLs
OHMYZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
POWERLEVEL10K_URL="https://github.com/romkatv/powerlevel10k.git"

# Neovim URLs
NVIM_MACOS_ARM64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-macos-arm64.tar.gz"
NVIM_MACOS_X86_64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-macos-x86_64.tar.gz"
NVIM_LINUX_X86_64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Styled output (uses gum when available)
styled_echo() {
    local message="$1"
    local style="${2:-info}"

    if command_exists gum; then
        case "$style" in
            info) gum style --foreground 39 "$message" ;;
            success) gum style --foreground 42 "$message" ;;
            warning) gum style --foreground 214 "$message" ;;
            error) gum style --foreground 196 "$message" ;;
            title) gum style --bold --foreground 99 "$message" ;;
            *) echo -e "$message" ;;
        esac
        return
    fi

    case "$style" in
        info) echo -e "${BLUE}$message${NC}" ;;
        success) echo -e "${GREEN}$message${NC}" ;;
        warning) echo -e "${YELLOW}$message${NC}" ;;
        error) echo -e "${RED}$message${NC}" ;;
        title) echo -e "${BLUE}$message${NC}" ;;
        *) echo -e "$message" ;;
    esac
}

# Logging functions
log_info() {
    styled_echo "[INFO] $1" "info"
}

log_success() {
    styled_echo "[SUCCESS] $1" "success"
}

log_warning() {
    styled_echo "[WARNING] $1" "warning"
}

log_error() {
    styled_echo "[ERROR] $1" "error"
}

# Install gum using README curl installer
install_gum() {
    if command_exists gum; then
        log_info "gum is already installed"
        return 0
    fi

    log_info "Installing gum (README curl installer)..."
    curl -fsSL https://repo.charm.sh/install.sh | sudo bash

    if command_exists gum; then
        log_success "gum installed successfully"
    else
        log_warning "gum install failed; continuing with regular output"
    fi
}

# Backup existing file/directory
backup_existing() {
    local target="$1"
    if [ -e "$target" ]; then
        local backup="${target}_old"
        log_warning "$target already exists, backing up to $backup"
        mv "$target" "$backup"
    fi
}

# Create symbolic link with backup
create_symlink() {
    local source="$1"
    local target="$2"
    backup_existing "$target"
    ln -sf "$source" "$target"
    log_success "Created symlink: $target -> $source"
}

# Install Oh My Zsh
install_ohmyzsh() {
    if [ ! -d "$OHMYZSH_DIR" ]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL $OHMYZSH_URL)" "" --unattended
        log_success "Oh My Zsh installed successfully"
    else
        log_info "Oh My Zsh is already installed"
    fi
}

# Install Neovim
install_neovim() {
    if ! command_exists nvim; then
        log_info "Installing Neovim..."

        # Create .local directory if it doesn't exist
        mkdir -p "$HOME/.local"

        # Detect system architecture
        local system="$(uname)"
        local arch="$(uname -m)"
        local nvim_url=""

        case "$system" in
            "Darwin")
                case "$arch" in
                    "arm64") nvim_url=$NVIM_MACOS_ARM64_URL ;;
                    "x86_64") nvim_url=$NVIM_MACOS_X86_64_URL ;;
                    *) log_error "Unsupported architecture: $arch" && exit 1 ;;
                esac
                ;;
            "Linux")
                case "$arch" in
                    "x86_64") nvim_url=$NVIM_LINUX_X86_64_URL ;;
                    *) log_error "Unsupported architecture: $arch" && exit 1 ;;
                esac
                ;;
            *) log_error "Unsupported system: $system" && exit 1 ;;
        esac

        # Download and install Neovim
        log_info "Downloading Neovim for $system $arch..."
        curl -L "$nvim_url" -o /tmp/nvim.tar.gz
        tar xzf /tmp/nvim.tar.gz -C /tmp
        mv /tmp/nvim-* "$HOME/.local/"

        # Create symlink
        local nvim_bin="$HOME/.local/nvim-*/bin/nvim"
        if [ "$system" = "Darwin" ]; then
            sudo ln -sf "$nvim_bin" /usr/local/bin/nvim
        else
            sudo ln -sf "$nvim_bin" /usr/bin/nvim
        fi

        rm /tmp/nvim.tar.gz
        log_success "Neovim installed successfully"
    else
        log_info "Neovim is already installed"
    fi
}

# Install Zsh plugins (manual paths)
install_zsh_plugins() {
    log_info "Installing Zsh plugins manually..."

    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$HOME/.oh-my-zsh/custom/themes"

    # zsh-autosuggestions manual install
    if [ ! -d "$plugin_dir" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
    else
        log_info "zsh-autosuggestions is already installed"
    fi

    # Powerlevel10k
    if [ ! -d "$p10k_dir" ]; then
        git clone --depth=1 "$POWERLEVEL10K_URL" "$p10k_dir"
    else
        log_info "powerlevel10k is already installed"
    fi

    log_success "Zsh plugins installed successfully"
}

# Install system packages based on distribution
install_system_packages() {
    log_info "Installing system packages..."

    if command_exists apt-get; then
        # Debian/Ubuntu based
        log_info "Updating package lists..."
        sudo apt-get update

        log_info "Installing essential packages..."
        sudo apt-get install -y wget git curl build-essential python3 python3-pip nodejs npm tmux clang

    elif command_exists dnf; then
        # Fedora/RHEL based
        log_info "Updating package lists..."
        sudo dnf update -y

        log_info "Installing essential packages..."
        sudo dnf install -y wget git curl gcc gcc-c++ make python3 python3-pip nodejs npm tmux clang

    elif command_exists pacman; then
        # Arch Linux based
        log_info "Updating package lists..."
        sudo pacman -Syu --noconfirm

        log_info "Installing essential packages..."
        sudo pacman -S --noconfirm wget git curl base-devel python python-pip nodejs npm tmux clang

    else
        log_warning "Unsupported package manager. Please install the following packages manually:"
        log_warning "wget git curl build-essential python3 python3-pip nodejs npm tmux clang"
        return 1
    fi

    log_success "System packages installed successfully"
}

# Install zellij quickly from official release tarball
install_zellij_binary() {
    if command_exists zellij; then
        log_info "zellij is already installed"
        return 0
    fi

    local system
    local arch

    system="$(uname -s)"
    arch="$(uname -m)"

    log_info "Installing zellij via release tarball..."

    if [ "$system" = "Linux" ] && { [ "$arch" = "x86_64" ] || [ "$arch" = "amd64" ]; }; then
        curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz -o /tmp/zellij.tgz && tar -xzf /tmp/zellij.tgz -C /tmp && sudo mv /tmp/zellij /usr/local/bin/ && rm /tmp/zellij.tgz
        sudo chmod +x /usr/local/bin/zellij
    elif [ "$system" = "Darwin" ] && [ "$arch" = "x86_64" ]; then
        curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-apple-darwin.tar.gz -o /tmp/zellij.tgz && tar -xzf /tmp/zellij.tgz -C /tmp && sudo mv /tmp/zellij /usr/local/bin/ && rm /tmp/zellij.tgz
        sudo chmod +x /usr/local/bin/zellij
    elif [ "$system" = "Darwin" ] && [ "$arch" = "arm64" ]; then
        curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-aarch64-apple-darwin.tar.gz -o /tmp/zellij.tgz && tar -xzf /tmp/zellij.tgz -C /tmp && sudo mv /tmp/zellij /usr/local/bin/ && rm /tmp/zellij.tgz
        sudo chmod +x /usr/local/bin/zellij
    else
        log_warning "Skipping zellij binary install: unsupported OS/arch ($system/$arch)."
        return 0
    fi

    log_success "zellij installed successfully"
}

# Install zsh and fish
install_shells() {
    log_info "Installing zsh and fish..."

    if command_exists apt-get; then
        sudo apt-get install -y zsh fish

    elif command_exists dnf; then
        sudo dnf install -y zsh fish

    elif command_exists pacman; then
        sudo pacman -S --noconfirm zsh fish

    else
        log_warning "Unsupported package manager. Please install zsh and fish manually."
        return 1
    fi

    # Set zsh as default shell if it's not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        log_info "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
    fi

    log_success "Shells installed successfully"
}

# Install rustup and Rust
install_rust() {
    log_info "Installing rustup and Rust..."

    if ! command_exists rustup; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # Add rust to the current shell's PATH
    source "$HOME/.cargo/env"

    # Ensure stable toolchain is active
    rustup default stable

    log_success "Rust is ready"
}

# Install sccache before installing the rest of Rust tooling
install_sccache() {
    if ! command_exists rustup; then
        log_error "rustup is required before installing sccache"
        return 1
    fi

    source "$HOME/.cargo/env"

    if ! command_exists sccache; then
        log_info "Installing sccache first..."
        cargo install sccache
    else
        log_info "sccache is already installed"
    fi

    export RUSTC_WRAPPER="$HOME/.cargo/bin/sccache"
    log_success "Configured RUSTC_WRAPPER to use sccache"
}

# Install Rust-based tools
install_rust_tools() {
    log_info "Installing Rust-based tools..."

    source "$HOME/.cargo/env"
    export RUSTC_WRAPPER="$HOME/.cargo/bin/sccache"

    # List of tools to install
    local tools=("exa" "zoxide" "bat" "aichat" "atuin" "ripgrep")

    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            log_info "Installing $tool..."
            cargo install "$tool"
        else
            log_info "$tool is already installed"
        fi
    done

    log_success "Rust-based tools installed successfully"
}

start_rust_tools_install_in_background() {
    log_info "Starting Rust tools installation in background..."
    install_rust_tools &
    RUST_TOOLS_PID=$!
    log_info "Rust tools installation running with PID: $RUST_TOOLS_PID"
}

wait_for_background_jobs() {
    if [ -n "$RUST_TOOLS_PID" ]; then
        log_info "Waiting for background Rust tools installation to finish..."
        if command_exists gum; then
            gum spin --spinner dot --title "Installing Rust tools in background..." -- bash -c "while kill -0 $RUST_TOOLS_PID 2>/dev/null; do sleep 1; done"
        fi
        wait "$RUST_TOOLS_PID"
        log_success "Background Rust tools installation completed"
    fi
}

# Install uv and create virtual environment
install_uv_and_venv() {
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    if [ ! -d "$HOME/.venv" ]; then
        log_info "Creating virtual environment with uv..."
        uv venv "$HOME/.venv"
        log_success "Virtual environment created at $HOME/.venv"
    else
        log_info "Virtual environment already exists at $HOME/.venv"
    fi
}

# Main installation process
main() {
    styled_echo "\n*** Starting Dotfiles Installation ***\n" "title"

    # Check if dotfiles directory exists
    if [ -d "$DOTFILES_DIR" ]; then
        log_error ".dotfiles directory already exists. Please remove it for installation."
        exit 1
    fi

    # Install system packages
    install_system_packages

    # Install gum early so the rest of the script is prettier
    install_gum

    # Install zellij/tmux first so user gets multiplexer fast
    install_zellij_binary

    # Install shells
    install_shells

    # Install rustup and Rust
    install_rust

    # Install sccache before other cargo installs
    install_sccache

    # Install Rust-based tools in the background
    start_rust_tools_install_in_background

    # Install uv and create virtual environment
    install_uv_and_venv

    # Create necessary directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DOTFILES_DIR"

    # Install dependencies
    install_ohmyzsh
    install_neovim

    # Clone dotfiles repository
    log_info "Cloning dotfiles repository..."
    cd "$DOTFILES_DIR" || exit 1
    git init
    git remote add origin "$REPO_URL"
    git pull origin master

    # Create symlinks
    create_symlink "$DOTFILES_DIR/nvim" "$CONFIG_DIR/nvim"
    create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

    # Install Zsh plugins
    install_zsh_plugins

    # Ensure background installs are done before success
    wait_for_background_jobs

    styled_echo "\n*** Installation Complete! ***\n" "success"
    styled_echo "Please restart your terminal or run: source ~/.zshrc" "warning"
}

# Run the main function
main "$@"
