#!/bin/bash

# Test script for PATH setup functionality

echo "Testing shell detection and PATH setup..."
echo "========================================="
echo ""

# Test shell detection
echo "1. Detecting shell:"
shell_name=""
if [[ -n "$SHELL" ]]; then
    shell_name=$(basename "$SHELL")
fi
echo "   Detected shell: $shell_name"
echo "   SHELL env var: $SHELL"
echo ""

# Test profile detection
echo "2. Getting shell profile:"
profile_file=""
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
    *)
        profile_file="$HOME/.profile"
        ;;
esac
echo "   Shell profile: $profile_file"
echo "   Profile exists: $(test -f "$profile_file" && echo "yes" || echo "no")"
echo ""

# Check current PATH
echo "3. Checking current PATH:"
gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
gobin="$gopath/bin"
echo "   GOPATH: $gopath"
echo "   GOBIN: $gobin"
if [[ ":$PATH:" == *":$gobin:"* ]]; then
    echo "   ✓ $gobin is already in PATH"
else
    echo "   ✗ $gobin is NOT in PATH"
fi
echo ""

echo "4. Go-related PATH entries:"
echo "$PATH" | tr ':' '\n' | grep -E "(go|Go)" | while read -r path; do
    echo "   - $path"
done

# Check if goverman was already added
echo ""
echo "5. Checking if goverman already added to profile:"
if [[ -f "$profile_file" ]] && grep -q "# Added by goverman" "$profile_file"; then
    echo "   ✓ Found goverman PATH entry in $profile_file"
    grep -A1 "# Added by goverman" "$profile_file" | sed 's/^/   /'
else
    echo "   ✗ No goverman PATH entry found in $profile_file"
fi