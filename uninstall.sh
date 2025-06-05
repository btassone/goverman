#!/bin/bash
# goverman uninstallation script
# This script completely removes gman (Go Version Manager) and all installed Go versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
GMAN_BIN="/usr/local/bin/gman"
MAN_FILE="/usr/local/share/man/man1/gman.1"
GOBIN="${GOBIN:-${GOPATH:-$HOME/go}/bin}"
SDK_DIR="$HOME/sdk"

# Track what we remove
REMOVED_ITEMS=()

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

# Check if running with appropriate permissions
check_permissions() {
    local needs_sudo=false
    
    # Check if we need sudo for system files
    if [[ -f "$GMAN_BIN" && ! -w "$(dirname "$GMAN_BIN")" ]]; then
        needs_sudo=true
    fi
    if [[ -f "$MAN_FILE" && ! -w "$(dirname "$MAN_FILE")" ]]; then
        needs_sudo=true
    fi
    
    if [[ "$needs_sudo" == "true" ]]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
            print_info "Uninstallation requires sudo privileges for system files"
        else
            print_error "Cannot write to system directories and sudo is not available"
            print_info "Please run this script as root or install sudo"
            exit 1
        fi
    else
        SUDO=""
    fi
}

# Remove gman binary
remove_gman_binary() {
    if [[ -f "$GMAN_BIN" ]]; then
        print_info "Removing gman binary..."
        $SUDO rm -f "$GMAN_BIN"
        REMOVED_ITEMS+=("gman binary from $GMAN_BIN")
        print_success "Removed gman binary"
    else
        print_info "gman binary not found at $GMAN_BIN"
    fi
}

# Remove man page
remove_man_page() {
    if [[ -f "$MAN_FILE" ]]; then
        print_info "Removing man page..."
        $SUDO rm -f "$MAN_FILE"
        REMOVED_ITEMS+=("man page from $MAN_FILE")
        print_success "Removed man page"
        
        # Update man database if available
        if command -v mandb >/dev/null 2>&1; then
            $SUDO mandb >/dev/null 2>&1 || true
        fi
    else
        print_info "Man page not found at $MAN_FILE"
    fi
}

# Find all gman-installed Go versions
find_go_versions() {
    local versions=()
    
    # Check in GOBIN
    if [[ -d "$GOBIN" ]]; then
        for file in "$GOBIN"/go[0-9]*; do
            if [[ -x "$file" ]]; then
                versions+=("$file")
            fi
        done
    fi
    
    # Check for default symlink
    if [[ -L "$GOBIN/go" ]]; then
        local target=$(readlink "$GOBIN/go")
        if [[ "$target" =~ go[0-9] ]]; then
            versions+=("$GOBIN/go")
        fi
    fi
    
    echo "${versions[@]}"
}

# Remove all installed Go versions
remove_go_versions() {
    print_info "Looking for gman-installed Go versions..."
    
    local versions=($(find_go_versions))
    
    if [[ ${#versions[@]} -eq 0 ]]; then
        print_info "No gman-installed Go versions found"
        return
    fi
    
    print_warning "Found ${#versions[@]} gman-installed Go version(s)"
    
    # Ask for confirmation if not in CI
    if [[ "${CI:-false}" != "true" ]]; then
        echo "The following will be removed:"
        for version in "${versions[@]}"; do
            echo "  - $version"
        done
        echo
        read -p "Continue with removal? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Go version removal"
            return
        fi
    fi
    
    # Remove versions
    for version in "${versions[@]}"; do
        rm -f "$version"
        REMOVED_ITEMS+=("Go binary: $version")
    done
    
    # Remove SDK directories
    if [[ -d "$SDK_DIR" ]]; then
        local sdk_count=$(find "$SDK_DIR" -maxdepth 1 -name "go*" -type d 2>/dev/null | wc -l)
        if [[ $sdk_count -gt 0 ]]; then
            print_info "Removing $sdk_count SDK director(ies) from $SDK_DIR..."
            rm -rf "$SDK_DIR"/go*
            REMOVED_ITEMS+=("SDK directories from $SDK_DIR")
        fi
    fi
    
    print_success "Removed all gman-installed Go versions"
}

# Remove PATH entries from shell profiles
remove_path_entries() {
    print_info "Removing PATH entries from shell profiles..."
    
    local profiles=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.config/fish/config.fish"
    )
    
    for profile in "${profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            # Create backup
            cp "$profile" "$profile.goverman-backup"
            
            # Remove goverman PATH entries
            if [[ "$profile" == *"fish"* ]]; then
                # Fish shell uses different syntax
                sed -i.tmp '/# goverman PATH/,/fish_add_path.*go\/bin/d' "$profile"
            else
                # Bash/Zsh
                sed -i.tmp '/# goverman PATH/,/export PATH.*go\/bin/d' "$profile"
            fi
            
            # Check if anything was removed
            if ! cmp -s "$profile" "$profile.goverman-backup"; then
                REMOVED_ITEMS+=("PATH entry from $profile")
                print_success "Removed PATH entry from $(basename "$profile")"
                rm -f "$profile.tmp"
            else
                rm -f "$profile.tmp" "$profile.goverman-backup"
            fi
        fi
    done
}

# Clean up empty directories
cleanup_directories() {
    print_info "Cleaning up directories..."
    
    # Remove empty GOBIN directory
    if [[ -d "$GOBIN" ]]; then
        if [[ -z "$(ls -A "$GOBIN" 2>/dev/null)" ]]; then
            rmdir "$GOBIN" 2>/dev/null || rm -rf "$GOBIN"
            REMOVED_ITEMS+=("Empty directory: $GOBIN")
        fi
    fi
    
    # Remove empty SDK directory
    if [[ -d "$SDK_DIR" ]]; then
        if [[ -z "$(ls -A "$SDK_DIR" 2>/dev/null)" ]]; then
            rmdir "$SDK_DIR" 2>/dev/null || rm -rf "$SDK_DIR"
            REMOVED_ITEMS+=("Empty directory: $SDK_DIR")
        fi
    fi
    
    # Remove empty go directory if it exists
    local go_dir="${GOPATH:-$HOME/go}"
    if [[ -d "$go_dir" ]]; then
        # First try to remove the bin subdirectory if it's empty and is our GOBIN
        if [[ -d "$go_dir/bin" && "$GOBIN" == "$go_dir/bin" ]]; then
            if [[ -z "$(ls -A "$go_dir/bin" 2>/dev/null)" ]]; then
                rmdir "$go_dir/bin" 2>/dev/null || rm -rf "$go_dir/bin" 2>/dev/null || true
            fi
        fi
        # Then try to remove the go directory if it's empty
        if [[ -z "$(ls -A "$go_dir" 2>/dev/null)" ]]; then
            rmdir "$go_dir" 2>/dev/null || rm -rf "$go_dir"
            REMOVED_ITEMS+=("Empty directory: $go_dir")
        fi
    fi
}

# Main uninstallation
main() {
    echo -e "${RED}goverman uninstaller${NC}"
    echo "====================="
    echo
    
    print_warning "This will remove gman and all gman-installed Go versions"
    echo
    
    # Check permissions
    check_permissions
    
    # Remove components
    remove_gman_binary
    remove_man_page
    remove_go_versions
    remove_path_entries
    cleanup_directories
    
    # Summary
    echo
    echo -e "${GREEN}✓ Uninstallation completed!${NC}"
    echo
    
    if [[ ${#REMOVED_ITEMS[@]} -gt 0 ]]; then
        echo "The following items were removed:"
        for item in "${REMOVED_ITEMS[@]}"; do
            echo "  - $item"
        done
        echo
    fi
    
    echo "Notes:"
    echo "  - Shell profile backups were created with .goverman-backup extension"
    echo "  - Restart your shell or open a new terminal for PATH changes to take effect"
    echo "  - System Go installations (if any) were not affected"
    echo
    
    # Check if there's a system Go
    if command -v go >/dev/null 2>&1; then
        local go_version=$(go version 2>/dev/null || echo "unknown")
        print_info "System Go detected: $go_version"
    fi
}

# Run main function
main "$@"