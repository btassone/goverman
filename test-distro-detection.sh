#!/bin/bash

# Test Linux distribution detection functionality

echo "Testing Linux Distribution Detection"
echo "===================================="
echo ""

# Source the detect_linux_distro function from gman
SCRIPT_DIR="$(dirname "$0")"
# Extract the detect_linux_distro function from gman
eval "$(sed -n '/^# Function to detect Linux distribution/,/^}$/p' "$SCRIPT_DIR/gman" | sed -n '/^detect_linux_distro()/,/^}$/p')"

# Run the detection
distro=$(detect_linux_distro)

echo "Detection Results:"
echo "------------------"
echo "Detected distribution: $distro"
echo ""

echo "System Information:"
echo "------------------"
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo ""

# Check for distribution files
echo "Distribution Files:"
echo "------------------"
echo "/etc/os-release exists: $(test -f /etc/os-release && echo "yes" || echo "no")"
if [[ -f /etc/os-release ]]; then
    echo "Contents:"
    grep -E "^(NAME|ID|VERSION)" /etc/os-release | sed 's/^/  /'
fi

echo ""
echo "/etc/redhat-release exists: $(test -f /etc/redhat-release && echo "yes" || echo "no")"
if [[ -f /etc/redhat-release ]]; then
    echo "Contents: $(cat /etc/redhat-release)"
fi

echo ""
echo "/etc/alpine-release exists: $(test -f /etc/alpine-release && echo "yes" || echo "no")"
if [[ -f /etc/alpine-release ]]; then
    echo "Alpine version: $(cat /etc/alpine-release)"
fi

# Check package managers
echo ""
echo "Package Managers:"
echo "-----------------"
echo "dnf command exists: $(command -v dnf >/dev/null 2>&1 && echo "yes (AlmaLinux/RHEL/Fedora)" || echo "no")"
echo "yum command exists: $(command -v yum >/dev/null 2>&1 && echo "yes (RHEL-based)" || echo "no")"
echo "apt command exists: $(command -v apt >/dev/null 2>&1 && echo "yes (Debian/Ubuntu)" || echo "no")"
echo "apk command exists: $(command -v apk >/dev/null 2>&1 && echo "yes (Alpine)" || echo "no")"
echo "zypper command exists: $(command -v zypper >/dev/null 2>&1 && echo "yes (openSUSE/SLES)" || echo "no")"

# Test compatibility message
echo ""
echo "Go Binary Compatibility:"
echo "-----------------------"
case "$distro" in
    alpine)
        echo "⚠️  Alpine Linux detected - using musl libc"
        echo "Official Go binaries may have limited compatibility"
        ;;
    almalinux|centos|rhel*)
        echo "✓ RHEL-based distribution detected - using glibc"
        echo "Official Go binaries should work without issues"
        echo "Note: AlmaLinux is 1:1 binary compatible with RHEL"
        ;;
    ubuntu|debian)
        echo "✓ Debian-based distribution detected - using glibc"
        echo "Official Go binaries should work without issues"
        ;;
    opensuse*|sles*)
        echo "✓ SUSE-based distribution detected - using glibc"
        echo "Official Go binaries should work without issues"
        echo "Note: openSUSE uses zypper package manager"
        ;;
    *)
        echo "✓ Standard Linux detected - using glibc"
        echo "Official Go binaries should work without issues"
        ;;
esac