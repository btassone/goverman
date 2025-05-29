#!/bin/bash

# Go Version Installer Script
# Usage: ./install_go_version.sh [version] [method]
# Example: ./install_go_version.sh 1.23.9
# Example: ./install_go_version.sh 1.23.9 direct

set -e

# Function to display usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  <version> [method] [--default]   Install a Go version"
    echo "  set-default <version>            Set a version as the default 'go' command"
    echo "  list                             List installed Go versions"
    echo ""
    echo "Arguments:"
    echo "  version    Go version to install/set (e.g., 1.23.9, 1.21.5)"
    echo "  method     Installation method: 'official' (default) or 'direct'"
    echo ""
    echo "Options:"
    echo "  --default  Set this version as the default 'go' command after installation"
    echo ""
    echo "Methods:"
    echo "  official   Use 'go install golang.org/dl/goX.Y.Z@latest' (recommended)"
    echo "  direct     Download and extract binary directly (fallback for ARM64 issues)"
    echo ""
    echo "Examples:"
    echo "  $0 1.23.9                        # Install using official method"
    echo "  $0 1.23.9 direct                 # Install using direct binary download"
    echo "  $0 1.21.5 official --default     # Install and set as default"
    echo "  $0 set-default 1.21.5            # Set existing version as default"
    echo "  $0 list                          # List all installed versions"
    exit 1
}

# Function to detect architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv6l"
            ;;
        *)
            echo "Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
}

# Function to detect OS
detect_os() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $os in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "darwin"
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            exit 1
            ;;
    esac
}

# Function to check if Go is installed
check_go_installed() {
    if ! command -v go >/dev/null 2>&1; then
        echo "Error: Go is not installed. Please install Go first before installing additional versions."
        echo "Visit: https://go.dev/doc/install"
        exit 1
    fi
    echo "✓ Go is installed: $(go version)"
}

# Function to detect user's shell
detect_shell() {
    local shell_name=""
    
    # Use the SHELL environment variable which represents the user's default shell
    # This is more reliable than checking the current process since the script
    # runs in bash regardless of the user's shell
    if [[ -n "$SHELL" ]]; then
        shell_name=$(basename "$SHELL")
    else
        # Fallback: check passwd file for user's default shell
        local user_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ -n "$user_shell" ]]; then
            shell_name=$(basename "$user_shell")
        else
            # Last resort: try parent process
            local ppid_shell=$(ps -p $PPID -o comm= 2>/dev/null | sed 's/^-//')
            if [[ -n "$ppid_shell" ]]; then
                shell_name="$ppid_shell"
            fi
        fi
    fi
    
    echo "$shell_name"
}

# Function to get shell profile file
get_shell_profile() {
    local shell_name=$(detect_shell)
    local profile_file=""
    
    case "$shell_name" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                profile_file="$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                profile_file="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            if [[ -f "$HOME/.zshrc" ]]; then
                profile_file="$HOME/.zshrc"
            elif [[ -f "$HOME/.zprofile" ]]; then
                profile_file="$HOME/.zprofile"
            fi
            ;;
        fish)
            profile_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            # Default to .profile for unknown shells
            profile_file="$HOME/.profile"
            ;;
    esac
    
    echo "$profile_file"
}

# Function to add PATH to shell profile
add_to_shell_profile() {
    local gobin="$1"
    local profile_file=$(get_shell_profile)
    local shell_name=$(detect_shell)
    
    if [[ -z "$profile_file" ]]; then
        echo "Warning: Could not determine shell profile file" >&2
        return 1
    fi
    
    # Check if PATH export already exists
    local path_export_line="export PATH=\"$gobin:\$PATH\""
    local path_marker="# Added by goverman"
    
    # Check if already added
    if [[ -f "$profile_file" ]] && grep -q "$gobin" "$profile_file" 2>/dev/null; then
        echo "✓ $gobin already in $profile_file" >&2
        return 0
    fi
    
    echo "" >&2
    echo "Detected shell: $shell_name" >&2
    echo "Would you like to add $gobin to your PATH permanently?" >&2
    echo "This will add the following line to $profile_file:" >&2
    echo "  $path_export_line" >&2
    read -p "Add to PATH? (y/N): " -n 1 -r
    echo >&2
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create profile file if it doesn't exist
        if [[ ! -f "$profile_file" ]]; then
            touch "$profile_file"
        fi
        
        # Add PATH export with marker comment
        echo "" >> "$profile_file"
        echo "$path_marker" >> "$profile_file"
        echo "$path_export_line" >> "$profile_file"
        
        echo "✓ Added $gobin to PATH in $profile_file" >&2
        echo "" >&2
        echo "To use it in the current session, run:" >&2
        echo "  source $profile_file" >&2
        echo "Or restart your terminal." >&2
    else
        echo "Skipped adding to PATH permanently." >&2
    fi
}

# Function to setup Go binary path
setup_go_path() {
    local gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    local gobin_env=$(go env GOBIN 2>/dev/null || echo "")
    local gobin
    
    # Use GOBIN if set and not empty, otherwise use GOPATH/bin
    if [[ -n "$gobin_env" ]]; then
        gobin="$gobin_env"
    else
        gobin="$gopath/bin"
    fi
    
    # Create bin directory if it doesn't exist
    mkdir -p "$gobin"
    
    # Check if Go bin is in PATH
    if [[ ":$PATH:" != *":$gobin:"* ]]; then
        echo "Warning: $gobin is not in your PATH" >&2
        
        # Temporarily add to PATH for this session
        export PATH="$gobin:$PATH"
        echo "✓ Temporarily added $gobin to PATH for this session" >&2
        
        # Offer to add permanently
        add_to_shell_profile "$gobin"
    else
        echo "✓ Go bin directory is in PATH" >&2
    fi
    
    echo "$gobin"
}

# Function to install via official method
install_official() {
    local version="$1"
    local go_binary="go${version}"
    
    echo "Installing Go ${version} using official method..."
    echo "================================================="
    
    # Try with CGO enabled first
    echo "Attempting installation with CGO enabled..."
    if go install "golang.org/dl/go${version}@latest" 2>/dev/null; then
        echo "✓ Installation successful with CGO enabled"
    else
        echo "Installation failed with CGO enabled, trying with CGO disabled..."
        if CGO_ENABLED=0 go install "golang.org/dl/go${version}@latest"; then
            echo "✓ Installation successful with CGO disabled"
        else
            echo "Error: Official installation method failed"
            echo "Try using the direct method: $0 $version direct"
            exit 1
        fi
    fi
    
    # Get the actual install location
    local gobin=$(setup_go_path)
    local install_target
    
    # Check multiple possible locations
    if [[ -f "$gobin/$go_binary" ]]; then
        install_target="$gobin/$go_binary"
    elif [[ -f "$HOME/go/bin/$go_binary" ]]; then
        install_target="$HOME/go/bin/$go_binary"
        gobin="$HOME/go/bin"
    else
        # Try to find where go install actually put it
        echo "Searching for installed binary..."
        install_target=$(find "$HOME" -name "$go_binary" -type f -executable 2>/dev/null | head -1)
        if [[ -n "$install_target" ]]; then
            gobin=$(dirname "$install_target")
            echo "Found binary at: $install_target"
        fi
    fi
    
    # Verify binary was installed
    if [[ -z "$install_target" || ! -f "$install_target" ]]; then
        echo "Error: Binary $go_binary not found after installation"
        echo "Debug info:"
        echo "  Expected: $gobin/$go_binary" 
        echo "  GOPATH: $(go env GOPATH)"
        echo "  GOBIN: $(go env GOBIN)"
        echo "  Directory contents of $gobin:"
        ls -la "$gobin/" 2>/dev/null || echo "  Directory doesn't exist"
        echo "  Searching for $go_binary in home directory:"
        find "$HOME" -name "$go_binary" -type f 2>/dev/null || echo "  Not found"
        exit 1
    fi
    
    echo "✓ Binary installed: $install_target"
    
    # Download the Go version
    echo ""
    echo "Downloading Go ${version}..."
    
    # Make sure the binary directory is in PATH
    export PATH="$gobin:$PATH"
    
    if "$install_target" download; then
        echo "✓ Go ${version} downloaded successfully"
    else
        echo "Error: Failed to download Go ${version}"
        echo "Binary path: $install_target"
        echo "Binary exists: $(test -f "$install_target" && echo "yes" || echo "no")"
        echo "Binary executable: $(test -x "$install_target" && echo "yes" || echo "no")"
        exit 1
    fi
}

# Function to install via direct method
install_direct() {
    local version="$1"
    local os=$(detect_os)
    local arch=$(detect_arch)
    local filename="go${version}.${os}-${arch}.tar.gz"
    local url="https://go.dev/dl/${filename}"
    local go_binary="go${version}"
    
    echo "Installing Go ${version} using direct method..."
    echo "=============================================="
    echo "OS: $os"
    echo "Architecture: $arch"
    echo "Download URL: $url"
    echo ""
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Download the binary
    echo "Downloading $filename..."
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$temp_dir/$filename" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L --progress-bar -o "$temp_dir/$filename" "$url"
    else
        echo "Error: Neither wget nor curl is available for download"
        exit 1
    fi
    
    echo "✓ Download completed"
    
    # Setup paths
    local gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    local gobin=$(setup_go_path)
    local install_dir="$HOME/sdk/go${version}"
    
    # Create SDK directory
    mkdir -p "$HOME/sdk"
    
    # Extract Go
    echo "Extracting Go ${version}..."
    tar -C "$HOME/sdk" -xzf "$temp_dir/$filename"
    mv "$HOME/sdk/go" "$install_dir"
    echo "✓ Extracted to: $install_dir"
    
    # Create wrapper binary
    echo "Creating wrapper binary..."
    
    # Create the wrapper script with the actual path directly
    cat > "$gobin/$go_binary" << EOF
#!/bin/bash
export GOROOT="$install_dir"
exec "$install_dir/bin/go" "\$@"
EOF
    
    chmod +x "$gobin/$go_binary"
    echo "✓ Wrapper binary created: $gobin/$go_binary"
}

# Function to verify installation
verify_installation() {
    local version="$1"
    local go_binary="go${version}"
    
    echo ""
    echo "Verifying installation..."
    echo "========================"
    
    if command -v "$go_binary" >/dev/null 2>&1; then
        echo "✓ $go_binary is accessible"
        echo "Version: $($go_binary version)"
        echo "GOROOT: $($go_binary env GOROOT)"
        echo ""
        echo "🎉 Installation completed successfully!"
        echo ""
        echo "Usage:"
        echo "  $go_binary version                    # Check version"
        echo "  $go_binary build main.go             # Build with this Go version"
        echo "  $go_binary env                       # Show environment"
    else
        echo "❌ Error: $go_binary is not accessible"
        echo "You may need to:"
        echo "  1. Restart your terminal"
        echo "  2. Add Go bin directory to your PATH"
        echo "  3. Run: source ~/.bashrc (or your shell profile)"
        exit 1
    fi
}

# Function to analyze PATH and detect conflicting Go installations
analyze_path_for_go() {
    local gobin="$1"
    local issues_found=false
    local gobin_position=-1
    local conflicting_positions=""
    local position=1
    
    # Find position of gobin and any conflicting Go installations
    IFS=':' read -ra PATH_ARRAY <<< "$PATH"
    for dir in "${PATH_ARRAY[@]}"; do
        if [[ "$dir" == "$gobin" ]]; then
            gobin_position=$position
        elif [[ -x "$dir/go" ]] && [[ "$dir" != "$gobin" ]]; then
            # Found another go binary
            if [[ $gobin_position -eq -1 ]] || [[ $position -lt $gobin_position ]]; then
                conflicting_positions="$conflicting_positions $position:$dir"
                issues_found=true
            fi
        elif [[ "$dir" == "/opt/homebrew/bin" ]] && [[ -x "/opt/homebrew/bin/go" ]]; then
            # Special case for Homebrew on Apple Silicon
            if [[ $gobin_position -eq -1 ]] || [[ $position -lt $gobin_position ]]; then
                conflicting_positions="$conflicting_positions $position:$dir"
                issues_found=true
            fi
        elif [[ "$dir" == "/usr/local/bin" ]] && [[ -x "/usr/local/bin/go" ]]; then
            # Special case for Homebrew on Intel or other installs
            if [[ $gobin_position -eq -1 ]] || [[ $position -lt $gobin_position ]]; then
                conflicting_positions="$conflicting_positions $position:$dir"
                issues_found=true
            fi
        fi
        position=$((position + 1))
    done
    
    echo "$issues_found|$gobin_position|$conflicting_positions"
}

# Function to fix PATH ordering
fix_path_ordering() {
    local gobin="$1"
    local profile_file=$(get_shell_profile)
    local shell_name=$(detect_shell)
    
    # Get detailed PATH analysis
    local path_analysis=$(analyze_path_for_go "$gobin")
    local conflicting_positions=$(echo "$path_analysis" | cut -d'|' -f3)
    
    echo "" >&2
    echo "PATH Ordering Fix" >&2
    echo "=================" >&2
    echo "" >&2
    echo "Detected issues with PATH ordering:" >&2
    echo "- $gobin needs to come before other Go installations" >&2
    echo "" >&2
    echo "Conflicting Go installations found:" >&2
    for conflict in $conflicting_positions; do
        local pos=$(echo "$conflict" | cut -d':' -f1)
        local dir=$(echo "$conflict" | cut -d':' -f2)
        echo "  Position $pos: $dir" >&2
        if [[ -x "$dir/go" ]]; then
            local go_ver=$("$dir/go" version 2>/dev/null | awk '{print $3}' || echo "unknown")
            echo "    └─ $go_ver" >&2
        fi
    done
    echo "" >&2
    echo "Would you like to fix this by prepending $gobin to your PATH?" >&2
    echo "This will update $profile_file" >&2
    read -p "Fix PATH ordering? (y/N): " -n 1 -r
    echo >&2
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove any existing goverman PATH entries
        if [[ -f "$profile_file" ]]; then
            # Create backup
            cp "$profile_file" "$profile_file.backup.$(date +%s)"
            
            # Create temp file without goverman entries
            local temp_clean=$(mktemp)
            # Remove lines that contain "# Added by goverman" and the following line
            awk '/# Added by goverman/{getline; next} 1' "$profile_file" > "$temp_clean"
            # Also remove any standalone PATH exports for gobin
            grep -v "export PATH=\"$gobin:\$PATH\"" "$temp_clean" > "$profile_file"
            rm -f "$temp_clean"
        fi
        
        # Add new PATH entry at the beginning of the file (after shebang if present)
        local temp_file=$(mktemp)
        local path_export_line="export PATH=\"$gobin:\$PATH\""
        local path_marker="# Added by goverman"
        
        # Check if file starts with shebang
        if [[ -f "$profile_file" ]] && head -n1 "$profile_file" | grep -q "^#!"; then
            # Keep shebang, add PATH after it
            head -n1 "$profile_file" > "$temp_file"
            echo "" >> "$temp_file"
            echo "$path_marker" >> "$temp_file"
            echo "$path_export_line" >> "$temp_file"
            echo "" >> "$temp_file"
            tail -n +2 "$profile_file" >> "$temp_file"
        else
            # Add PATH at the very beginning
            echo "$path_marker" > "$temp_file"
            echo "$path_export_line" >> "$temp_file"
            if [[ -f "$profile_file" ]]; then
                echo "" >> "$temp_file"
                cat "$profile_file" >> "$temp_file"
            fi
        fi
        
        mv "$temp_file" "$profile_file"
        
        echo "✓ Updated $profile_file to prioritize $gobin" >&2
        echo "" >&2
        echo "To apply changes in the current session, run:" >&2
        echo "  source $profile_file" >&2
        echo "" >&2
        
        # Also update current session
        export PATH="$gobin:$PATH"
        echo "✓ Updated PATH for current session" >&2
        
        return 0
    else
        echo "Skipped PATH fix. You may need to manually adjust your PATH." >&2
        return 1
    fi
}

# Function to set a Go version as default
set_default_version() {
    local version="$1"
    local go_binary="go${version}"
    local gobin=$(setup_go_path)
    
    # Check if the version exists
    if ! command -v "$go_binary" >/dev/null 2>&1; then
        echo "Error: Go version $version is not installed" >&2
        echo "Run '$0 $version' to install it first" >&2
        return 1
    fi
    
    # Create or update the 'go' symlink in gobin
    local go_link="$gobin/go"
    
    # Check if there's already a go command in gobin
    if [[ -L "$go_link" ]]; then
        echo "Current default: $(readlink "$go_link" | xargs basename)" >&2
    elif [[ -f "$go_link" ]]; then
        echo "Warning: $go_link exists but is not a symlink" >&2
        echo "Please remove it manually before setting a default version" >&2
        return 1
    fi
    
    # Create the symlink (use relative path for portability)
    cd "$gobin"
    ln -sf "$go_binary" "go"
    cd - >/dev/null
    
    echo "✓ Set go${version} as the default 'go' command" >&2
    echo "" >&2
    echo "Note: This will only work if $gobin comes before system Go in your PATH" >&2
    echo "Current PATH order:" >&2
    echo "$PATH" | tr ':' '\n' | grep -n "go" | head -5 | sed 's/^/  /' >&2
    
    # Clear command hash table to ensure we get fresh results
    hash -r 2>/dev/null || true
    
    # Verify it works
    echo "" >&2
    echo "Verification:" >&2
    echo "  which go: $(which go)" >&2
    local actual_go_version=$(go version 2>/dev/null || echo "failed")
    echo "  go version: $actual_go_version" >&2
    
    # Check if the PATH ordering is causing issues
    local expected_go_path="$gobin/go"
    local actual_go_path=$(which go 2>/dev/null)
    
    if [[ "$actual_go_path" != "$expected_go_path" ]]; then
        echo "" >&2
        echo "⚠️  WARNING: The 'go' command is not using the goverman-managed version!" >&2
        echo "  Expected: $expected_go_path" >&2
        echo "  Actual: $actual_go_path" >&2
        
        # Analyze PATH for issues
        local path_analysis=$(analyze_path_for_go "$gobin")
        local issues_found=$(echo "$path_analysis" | cut -d'|' -f1)
        
        if [[ "$issues_found" == "true" ]]; then
            echo "" >&2
            echo "This is because another Go installation appears earlier in your PATH." >&2
            
            # Offer to fix
            fix_path_ordering "$gobin"
        else
            echo "" >&2
            echo "PATH is already correctly ordered." >&2
        fi
    else
        echo "✓ Go $version is now the default 'go' command" >&2
    fi
    
    return 0
}

# Function to list installed versions
list_installed_versions() {
    echo "Locally Installed Go Versions"
    echo "============================="
    
    local found_versions=0
    local seen_versions=""  # Track versions we've already seen (space-separated list)
    
    # Get gobin directory
    local gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    local gobin_env=$(go env GOBIN 2>/dev/null || echo "")
    local gobin
    if [[ -n "$gobin_env" ]]; then
        gobin="$gobin_env"
    else
        gobin="$gopath/bin"
    fi
    
    # Check if there's a default symlink in gobin
    local default_symlink=""
    if [[ -L "$gobin/go" ]]; then
        default_symlink=$(readlink "$gobin/go" | xargs basename)
    fi
    
    # First, show the system default Go
    echo "System default Go:"
    echo "------------------"
    if command -v go >/dev/null 2>&1; then
        local default_version=$(go version 2>/dev/null || echo "unknown")
        local default_root=$(go env GOROOT 2>/dev/null || echo "unknown")
        local default_path=$(which go 2>/dev/null || echo "unknown")
        local is_default_marker=""
        
        # Check if this is the goverman-managed default
        if [[ "$default_path" == "$gobin/go" && -n "$default_symlink" ]]; then
            is_default_marker=" (goverman default → $default_symlink)"
        fi
        
        echo "  go$is_default_marker"
        echo "    Binary: $default_path"
        echo "    Version: $default_version"
        echo "    GOROOT: $default_root"
        echo ""
        found_versions=$((found_versions + 1))
    else
        echo "  No system Go installation found"
        echo ""
    fi
    
    # Now find additional Go versions
    local gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    local gobin_env=$(go env GOBIN 2>/dev/null || echo "")
    
    # Build list of directories to check (remove duplicates)
    local search_dirs=()
    if [[ -n "$gobin_env" ]]; then
        search_dirs+=("$gobin_env")
    fi
    search_dirs+=("$gopath/bin")
    search_dirs+=("$HOME/go/bin")
    search_dirs+=("/usr/local/bin")
    search_dirs+=("$HOME/.local/bin")
    
    echo "Additional Go versions:"
    echo "----------------------"
    
    # Find go binaries, avoiding duplicates
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            for binary in "$dir"/go[0-9]*; do
                if [[ -x "$binary" && -f "$binary" ]]; then
                    local version_name=$(basename "$binary")
                    if [[ "$version_name" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                        # Skip if we've already seen this version
                        if [[ " $seen_versions " == *" $version_name "* ]]; then
                            continue
                        fi
                        seen_versions="$seen_versions $version_name "
                        
                        local version_info=$("$binary" version 2>/dev/null || echo "unknown")
                        local goroot_info=$("$binary" env GOROOT 2>/dev/null || echo "unknown")
                        local default_marker=""
                        
                        # Check if this is the default
                        if [[ "$version_name" == "$default_symlink" ]]; then
                            default_marker=" [DEFAULT]"
                        fi
                        
                        echo "  $version_name$default_marker"
                        echo "    Binary: $binary"
                        echo "    Version: $version_info"
                        echo "    GOROOT: $goroot_info"
                        echo ""
                        found_versions=$((found_versions + 1))
                    fi
                fi
            done
        fi
    done
    
    # Check for orphaned SDK installations (SDK without wrapper binary)
    if [[ -d "$HOME/sdk" ]]; then
        local orphaned_found=false
        
        for sdk_dir in "$HOME/sdk"/go[0-9]*; do
            if [[ -d "$sdk_dir" && -f "$sdk_dir/bin/go" ]]; then
                local version_name=$(basename "$sdk_dir")
                if [[ "$version_name" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    # Check if we already found a binary for this version
                    if [[ " $seen_versions " != *" $version_name "* ]]; then
                        if [[ "$orphaned_found" == "false" ]]; then
                            echo "SDK installations without wrapper binaries:"
                            echo "-------------------------------------------"
                            orphaned_found=true
                        fi
                        
                        local version_info=$("$sdk_dir/bin/go" version 2>/dev/null || echo "unknown")
                        echo "  $version_name"
                        echo "    Location: $sdk_dir"
                        echo "    Version: $version_info"
                        echo "    ⚠️  No wrapper binary - not accessible as '$version_name'"
                        echo "    To create wrapper: ln -s $sdk_dir/bin/go ~/go/bin/$version_name"
                        echo ""
                        found_versions=$((found_versions + 1))
                    fi
                fi
            fi
        done
    fi
    
    echo "================================"
    echo "Total Go installations: $found_versions"
    echo ""
    
    if [[ $found_versions -gt 1 ]]; then
        echo "Usage:"
        echo "  go version               # Use system default"
        echo "  go1.21.5 version         # Use specific version"
        echo ""
        echo "To uninstall a version:"
        echo "  ./uninstall-go.sh 1.21.5"
    else
        echo "To install additional Go versions:"
        echo "  $0 1.23.9         # Install using official method"
        echo "  $0 1.23.9 direct  # Install using direct method"
    fi
}

# Main script logic
main() {
    # Check arguments
    if [[ $# -eq 0 ]]; then
        echo "Error: No command specified"
        echo ""
        list_installed_versions
        echo ""
        show_usage
    fi
    
    local command="$1"
    
    # Handle special commands
    case "$command" in
        list)
            list_installed_versions
            exit 0
            ;;
        set-default)
            if [[ -z "$2" ]]; then
                echo "Error: No version specified for set-default"
                show_usage
            fi
            set_default_version "$2"
            exit $?
            ;;
        -h|--help|help)
            show_usage
            ;;
    esac
    
    # If not a special command, assume it's a version to install
    local version="$command"
    local method="official"
    local set_default=false
    
    # Parse remaining arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            official|direct)
                method="$1"
                ;;
            --default)
                set_default=true
                ;;
            *)
                echo "Error: Unknown argument '$1'"
                show_usage
                ;;
        esac
        shift
    done
    
    # Validate version format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format '$version'. Use format like '1.23.9'"
        exit 1
    fi
    
    echo "Go Version Installer"
    echo "==================="
    echo "Version: $version"
    echo "Method: $method"
    echo "Date: $(date)"
    echo ""
    
    # Check if Go is installed
    check_go_installed
    
    # Check if version is already installed
    local go_binary="go${version}"
    if command -v "$go_binary" >/dev/null 2>&1; then
        echo "Warning: Go $version appears to be already installed"
        echo "Current installation: $($go_binary version)"
        echo "GOROOT: $($go_binary env GOROOT)"
        echo ""
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 0
        fi
    fi
    
    # Install based on method
    case "$method" in
        "official")
            install_official "$version"
            ;;
        "direct")
            install_direct "$version"
            ;;
    esac
    
    # Verify installation
    verify_installation "$version"
    
    # Set as default if requested
    if [[ "$set_default" == "true" ]]; then
        echo ""
        echo "Setting as default Go version..."
        echo "================================"
        set_default_version "$version"
    fi
}

# Handle special arguments
case "${1:-}" in
    -h|--help|help)
        show_usage
        ;;
    *)
        main "$@"
        ;;
esac
