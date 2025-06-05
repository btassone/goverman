#!/bin/bash
# goverman installation script
# This script installs gman (Go Version Manager) and sets up the environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
REPO_URL="https://github.com/btassone/goverman"
INSTALL_DIR="/usr/local/bin"
MAN_DIR="/usr/local/share/man/man1"
TEMP_DIR=$(mktemp -d)

# Functions
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Detect OS and architecture
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
        linux|darwin)
            ;;
        mingw*|msys*|cygwin*)
            os="windows"
            ;;
        *)
            print_error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
    
    case "$arch" in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l|armv6l)
            arch="arm"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    echo "$os-$arch"
}

# Check if running with appropriate permissions
check_permissions() {
    if [[ -w "$INSTALL_DIR" ]]; then
        SUDO=""
    else
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
            print_info "Installation requires sudo privileges"
        else
            print_error "Cannot write to $INSTALL_DIR and sudo is not available"
            print_info "Please run this script as root or install sudo"
            exit 1
        fi
    fi
}

# Detect user's shell
detect_shell() {
    if [[ -n "$SHELL" ]]; then
        case "$SHELL" in
            */bash)
                echo "bash"
                ;;
            */zsh)
                echo "zsh"
                ;;
            */fish)
                echo "fish"
                ;;
            *)
                echo "bash"  # Default to bash
                ;;
        esac
    else
        echo "bash"  # Default to bash
    fi
}

# Get shell profile file
get_shell_profile() {
    local shell=$1
    case "$shell" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.bashrc"
            ;;
    esac
}

# Download file with curl or wget
download_file() {
    local url=$1
    local output=$2
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        print_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
}

# Main installation
main() {
    echo -e "${GREEN}goverman installer${NC}"
    echo "==================="
    echo
    
    # Detect platform
    print_info "Detecting platform..."
    PLATFORM=$(detect_platform)
    print_success "Platform: $PLATFORM"
    
    # Check permissions
    check_permissions
    
    # Create temp directory
    cd "$TEMP_DIR"
    
    # Download gman script
    print_info "Downloading gman..."
    download_file "${REPO_URL}/raw/main/gman" "gman"
    chmod +x gman
    print_success "Downloaded gman"
    
    # Download man page (optional - may not exist yet)
    print_info "Downloading man page..."
    if download_file "${REPO_URL}/raw/main/gman.1" "gman.1" 2>/dev/null; then
        print_success "Downloaded man page"
        INSTALL_MAN=true
    else
        print_warning "Man page not found in repository (will skip man page installation)"
        INSTALL_MAN=false
    fi
    
    # Install gman
    print_info "Installing gman to $INSTALL_DIR..."
    $SUDO mv gman "$INSTALL_DIR/"
    print_success "Installed gman"
    
    # Install man page if downloaded
    if [[ "$INSTALL_MAN" == "true" ]]; then
        print_info "Installing man page..."
        $SUDO mkdir -p "$MAN_DIR"
        $SUDO mv gman.1 "$MAN_DIR/"
        if command -v mandb >/dev/null 2>&1; then
            $SUDO mandb >/dev/null 2>&1 || true
        fi
        print_success "Installed man page"
    fi
    
    # Setup PATH for user
    print_info "Setting up PATH..."
    local shell=$(detect_shell)
    local profile=$(get_shell_profile "$shell")
    local gobin_path="\$HOME/go/bin"
    
    # Check if PATH setup is needed
    if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        print_info "Adding $gobin_path to PATH in $profile"
        
        # Create profile file if it doesn't exist
        if [[ ! -f "$profile" ]]; then
            mkdir -p "$(dirname "$profile")"
            touch "$profile"
        fi
        
        # Add PATH export based on shell type
        if [[ "$shell" == "fish" ]]; then
            echo "" >> "$profile"
            echo "# goverman PATH" >> "$profile"
            echo "fish_add_path -m $gobin_path" >> "$profile"
        else
            echo "" >> "$profile"
            echo "# goverman PATH" >> "$profile"
            echo "export PATH=\"$gobin_path:\$PATH\"" >> "$profile"
        fi
        
        print_success "Added PATH configuration to $profile"
        print_warning "Please restart your shell or run: source $profile"
    else
        print_success "PATH already configured"
    fi
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
    
    # Success message
    echo
    echo -e "${GREEN}✓ goverman installation completed!${NC}"
    echo
    echo "To get started:"
    echo "  1. Restart your shell or run: source $(get_shell_profile $(detect_shell))"
    echo "  2. Run: gman help"
    echo "  3. Install your first Go version: gman install 1.23.9 --default"
    echo
    echo "For more information:"
    if [[ "$INSTALL_MAN" == "true" ]]; then
        echo "  - Run: man gman"
    fi
    echo "  - Visit: $REPO_URL"
    echo
}

# Run main function
main "$@"