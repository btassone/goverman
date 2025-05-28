#!/bin/bash

# Go Version Uninstaller Script
# Usage: ./uninstall_go_version.sh [version]
# Example: ./uninstall_go_version.sh 1.23.9

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <version>"
    echo "Example: $0 1.23.9"
    echo ""
    echo "This script uninstalls Go versions installed via 'go install golang.org/dl/goX.Y.Z@latest'"
    echo "It removes both the binary and the downloaded Go installation directory."
    exit 1
}

# Function to safely remove directory
safe_remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        # Additional safety check - make sure it's a Go directory
        if [[ "$dir" == *"/go"* ]] || [[ "$dir" == *"/sdk/go"* ]] || [[ -f "$dir/bin/go" ]]; then
            echo "Removing directory: $dir"
            rm -rf "$dir"
            echo "✓ Directory removed"
        else
            echo "Warning: Directory doesn't appear to be a Go installation: $dir"
            echo "Skipping removal for safety"
        fi
    else
        echo "Directory not found: $dir"
    fi
}

# Function to safely remove binary
safe_remove_binary() {
    local binary="$1"
    if [[ -f "$binary" ]]; then
        echo "Removing binary: $binary"
        rm -f "$binary"
        echo "✓ Binary removed"
    else
        echo "Binary not found: $binary"
    fi
}

# Function to check and handle default symlink
check_default_symlink() {
    local version="$1"
    local go_binary="go${version}"
    local gobin="$2"
    local go_link="$gobin/go"
    
    if [[ -L "$go_link" ]]; then
        local link_target=$(readlink "$go_link" | xargs basename)
        if [[ "$link_target" == "$go_binary" ]]; then
            echo ""
            echo "Warning: This version is currently set as the default 'go' command"
            echo "Removing the default symlink..."
            rm -f "$go_link"
            echo "✓ Default symlink removed"
            echo ""
            echo "Note: You'll need to set another version as default or the system Go will be used"
            echo "Run: ./install-go.sh set-default <version> to set a new default"
        fi
    fi
}

# Check if version argument is provided
if [[ $# -eq 0 ]]; then
    echo "Error: No version specified"
    show_usage
fi

VERSION="$1"
GO_BINARY="go${VERSION}"

echo "Uninstalling Go version ${VERSION}..."
echo "======================================="

# Step 1: Check if the go binary exists and get its GOROOT
echo "Step 1: Checking for Go binary and getting GOROOT..."

# Find the binary in common locations
BINARY_PATH=""
SEARCH_LOCATIONS=(
    "$HOME/go/bin/$GO_BINARY"
    "/usr/local/bin/$GO_BINARY"
    "$HOME/.local/bin/$GO_BINARY"
)

# Add GOBIN and GOPATH locations if Go is available
if command -v go >/dev/null 2>&1; then
    GOBIN_PATH=$(go env GOBIN 2>/dev/null || echo "")
    GOPATH_PATH=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    
    if [[ -n "$GOBIN_PATH" ]]; then
        SEARCH_LOCATIONS=("$GOBIN_PATH/$GO_BINARY" "${SEARCH_LOCATIONS[@]}")
    fi
    
    if [[ -n "$GOPATH_PATH" ]]; then
        SEARCH_LOCATIONS=("$GOPATH_PATH/bin/$GO_BINARY" "${SEARCH_LOCATIONS[@]}")
    fi
fi

# Search for the binary
for location in "${SEARCH_LOCATIONS[@]}"; do
    if [[ -f "$location" ]]; then
        BINARY_PATH="$location"
        break
    fi
done

if [[ -z "$BINARY_PATH" ]]; then
    echo "Warning: Go binary '$GO_BINARY' not found in common locations"
    echo "Searched in:"
    for location in "${SEARCH_LOCATIONS[@]}"; do
        echo "  - $location"
    done
    echo ""
    echo "You may need to manually locate and remove the binary."
else
    echo "Found binary: $BINARY_PATH"
    
    # Step 2: Get GOROOT from the binary
    echo ""
    echo "Step 2: Getting GOROOT..."
    
    if GOROOT_PATH=$("$BINARY_PATH" env GOROOT 2>/dev/null); then
        echo "GOROOT: $GOROOT_PATH"
        
        # Step 3: Remove the GOROOT directory
        echo ""
        echo "Step 3: Removing Go installation directory..."
        safe_remove_dir "$GOROOT_PATH"
    else
        echo "Warning: Could not get GOROOT from $GO_BINARY"
        echo "The Go installation directory may need to be removed manually."
    fi
    
    # Check if this version is set as default
    GOBIN_DIR=$(dirname "$BINARY_PATH")
    check_default_symlink "$VERSION" "$GOBIN_DIR"
    
    # Step 4: Remove the binary
    echo ""
    echo "Step 4: Removing Go binary..."
    safe_remove_binary "$BINARY_PATH"
fi

echo ""
echo "======================================="
echo "Uninstallation process completed!"
echo ""

# Step 5: Verification
echo "Step 5: Verification..."
echo "Checking if $GO_BINARY is still accessible..."

if command -v "$GO_BINARY" >/dev/null 2>&1; then
    echo "⚠️  Warning: $GO_BINARY is still accessible. You may need to:"
    echo "   - Check your PATH environment variable"
    echo "   - Restart your terminal"
    echo "   - Look for additional installations in other locations"
else
    echo "✓ $GO_BINARY is no longer accessible"
fi

echo ""
echo "Note: If you have multiple Go installations, make sure to check:"
echo "  - /usr/local/go (system-wide installation)"
echo "  - ~/go-versions/ (custom installations)"
echo "  - Other custom installation directories"
