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

# URLs
OHMYZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
ZSH_AUTOSUGGESTIONS_URL="https://github.com/zsh-users/zsh-autosuggestions"
POWERLEVEL10K_URL="https://github.com/romkatv/powerlevel10k.git"

# Neovim URLs
NVIM_MACOS_ARM64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-macos-arm64.tar.gz"
NVIM_MACOS_X86_64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-macos-x86_64.tar.gz"
NVIM_LINUX_X86_64_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Install Zsh plugins
install_zsh_plugins() {
    log_info "Installing Zsh plugins..."
    
    # Zsh autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone $ZSH_AUTOSUGGESTIONS_URL "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    fi
    
    # Powerlevel10k
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 $POWERLEVEL10K_URL "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
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
        # Add rust to the current shell's PATH
        source "$HOME/.cargo/env"
        
        # Install stable toolchain
        rustup default stable
        
        log_success "Rust installed successfully"
    else
        log_info "Rust is already installed"
    fi
}

# Install Rust-based tools
install_rust_tools() {
    log_info "Installing Rust-based tools..."
    
    # List of tools to install
    local tools=("zellij" "exa" "zoxide" "bat" "aichat" "atuin" "ripgrep" "sccache")
    
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
    echo -e "\n${BLUE}*** Starting Dotfiles Installation ***${NC}\n"
    
    # Check if dotfiles directory exists
    if [ -d "$DOTFILES_DIR" ]; then
        log_error ".dotfiles directory already exists. Please remove it for installation."
        exit 1
    fi
    
    # Install system packages
    install_system_packages
    
    # Install shells
    install_shells
    
    # Install rustup and Rust
    install_rust
    
    # Install Rust-based tools
    install_rust_tools
    
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
    
    echo -e "\n${GREEN}*** Installation Complete! ***${NC}\n"
    echo -e "Please restart your terminal or run: ${YELLOW}source ~/.zshrc${NC}"
}

# Run the main function
main "$@"
