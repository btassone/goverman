#!/bin/bash

# Test Alpine Linux detection functionality

echo "Testing Alpine Linux Detection"
echo "=============================="
echo ""

# Source the detect_musl function from gman
SCRIPT_DIR="$(dirname "$0")"
# Extract the detect_musl function from gman (handle the comment lines before it)
eval "$(sed -n '/^# Function to detect if using musl/,/^}$/p' "$SCRIPT_DIR/gman" | sed -n '/^detect_musl()/,/^}$/p')"

# Run the detection
is_musl=$(detect_musl)

echo "Detection Results:"
echo "------------------"
echo "Musl libc detected: $is_musl"
echo ""

echo "System Information:"
echo "------------------"
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo ""

# Check for Alpine-specific files
echo "Alpine Indicators:"
echo "------------------"
echo "/etc/alpine-release exists: $(test -f /etc/alpine-release && echo "yes" || echo "no")"
if [[ -f /etc/alpine-release ]]; then
    echo "Alpine version: $(cat /etc/alpine-release)"
fi

echo "apk command exists: $(command -v apk >/dev/null 2>&1 && echo "yes" || echo "no")"

# Check ldd version
echo ""
echo "libc Information:"
echo "-----------------"
if command -v ldd >/dev/null 2>&1; then
    echo "ldd version:"
    ldd --version 2>&1 | head -n 1
else
    echo "ldd command not found"
fi

# Test what happens with Go binary downloads
echo ""
echo "Go Binary Compatibility:"
echo "-----------------------"
if [[ "$is_musl" == "true" ]]; then
    echo "⚠️  Alpine Linux detected - using musl libc"
    echo "Note: Official Go binaries are built for glibc and may have limited compatibility"
    echo "Recommendation: Use 'apk add go' for native Alpine Go installation"
else
    echo "✓ Standard Linux detected - using glibc"
    echo "Official Go binaries should work without issues"
fi