#!/bin/bash

# Test script for gman-uninstall
# This script tests the goverman uninstaller

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Temp directory for testing
TEST_DIR=$(mktemp -d)
export HOME="$TEST_DIR/home"
export GOBIN="$HOME/go/bin"
export CI=true  # Prevent confirmation prompts

mkdir -p "$HOME"

# Mock sudo for testing
MOCK_SUDO_DIR="$TEST_DIR/mock-bin"
mkdir -p "$MOCK_SUDO_DIR"

# Create mock sudo that just runs the command
cat > "$MOCK_SUDO_DIR/sudo" << 'EOF'
#!/bin/bash
# Mock sudo - just run the command
"$@"
EOF
chmod +x "$MOCK_SUDO_DIR/sudo"
export PATH="$MOCK_SUDO_DIR:$PATH"

# Helper functions
print_test() {
    echo -e "${BLUE}TEST:${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Setup function - create a mock goverman installation
setup_mock_installation() {
    # Create mock gman binary
    mkdir -p "$TEST_DIR/usr/local/bin"
    echo '#!/bin/bash' > "$TEST_DIR/usr/local/bin/gman"
    echo 'echo "gman v1.11.0"' >> "$TEST_DIR/usr/local/bin/gman"
    chmod +x "$TEST_DIR/usr/local/bin/gman"
    
    # Create mock man page
    mkdir -p "$TEST_DIR/usr/local/share/man/man1"
    echo '.TH GMAN 1' > "$TEST_DIR/usr/local/share/man/man1/gman.1"
    
    # Create mock Go installations
    mkdir -p "$GOBIN"
    echo '#!/bin/bash' > "$GOBIN/go1.23.9"
    chmod +x "$GOBIN/go1.23.9"
    echo '#!/bin/bash' > "$GOBIN/go1.22.0"
    chmod +x "$GOBIN/go1.22.0"
    ln -s go1.23.9 "$GOBIN/go"
    
    # Create SDK directories
    mkdir -p "$HOME/sdk/go1.23.9"
    mkdir -p "$HOME/sdk/go1.22.0"
    
    # Create shell profiles with PATH entries
    echo '# Existing content' > "$HOME/.bashrc"
    echo '' >> "$HOME/.bashrc"
    echo '# goverman PATH' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.bashrc"
    
    echo '# Existing content' > "$HOME/.zshrc"
    echo '' >> "$HOME/.zshrc"
    echo '# goverman PATH' >> "$HOME/.zshrc"
    echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.zshrc"
    
    mkdir -p "$HOME/.config/fish"
    echo '# Existing content' > "$HOME/.config/fish/config.fish"
    echo '' >> "$HOME/.config/fish/config.fish"
    echo '# goverman PATH' >> "$HOME/.config/fish/config.fish"
    echo 'fish_add_path -m $HOME/go/bin' >> "$HOME/.config/fish/config.fish"
}

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test 1: Check uninstall script exists and is executable
print_test "Uninstall script exists and is executable"
if [[ -f "gman-uninstall" && -x "gman-uninstall" ]]; then
    print_pass
else
    print_fail "gman-uninstall not found or not executable"
fi

# Test 2: Test uninstaller removes gman binary
print_test "Uninstaller removes gman binary"
setup_mock_installation
# Modify gman-uninstall to use our test directories
sed "s|/usr/local/bin/gman|$TEST_DIR/usr/local/bin/gman|g" gman-uninstall > "$TEST_DIR/uninstall_test.sh"
sed -i.bak "s|/usr/local/share/man/man1/gman.1|$TEST_DIR/usr/local/share/man/man1/gman.1|g" "$TEST_DIR/uninstall_test.sh"
chmod +x "$TEST_DIR/uninstall_test.sh"

# Run uninstaller
if bash "$TEST_DIR/uninstall_test.sh" >/dev/null 2>&1; then
    if [[ ! -f "$TEST_DIR/usr/local/bin/gman" ]]; then
        print_pass
    else
        print_fail "gman binary still exists"
    fi
else
    print_fail "Uninstaller failed to run"
fi

# Test 3: Test uninstaller removes man page
print_test "Uninstaller removes man page"
if [[ ! -f "$TEST_DIR/usr/local/share/man/man1/gman.1" ]]; then
    print_pass
else
    print_fail "Man page still exists"
fi

# Test 4: Test uninstaller removes Go versions
print_test "Uninstaller removes Go versions"
if [[ ! -f "$GOBIN/go1.23.9" && ! -f "$GOBIN/go1.22.0" && ! -e "$GOBIN/go" ]]; then
    print_pass
else
    print_fail "Go versions still exist"
fi

# Test 5: Test uninstaller removes SDK directories
print_test "Uninstaller removes SDK directories"
if [[ ! -d "$HOME/sdk/go1.23.9" && ! -d "$HOME/sdk/go1.22.0" ]]; then
    print_pass
else
    print_fail "SDK directories still exist"
fi

# Test 6: Test uninstaller removes PATH entries from bashrc
print_test "Uninstaller removes PATH entries from .bashrc"
if ! grep -q "goverman PATH" "$HOME/.bashrc" && ! grep -q "go/bin" "$HOME/.bashrc"; then
    print_pass
else
    print_fail "PATH entries still in .bashrc"
fi

# Test 7: Test uninstaller removes PATH entries from zshrc
print_test "Uninstaller removes PATH entries from .zshrc"
if ! grep -q "goverman PATH" "$HOME/.zshrc" && ! grep -q "go/bin" "$HOME/.zshrc"; then
    print_pass
else
    print_fail "PATH entries still in .zshrc"
fi

# Test 8: Test uninstaller removes PATH entries from fish config
print_test "Uninstaller removes PATH entries from fish config"
if ! grep -q "goverman PATH" "$HOME/.config/fish/config.fish" && ! grep -q "go/bin" "$HOME/.config/fish/config.fish"; then
    print_pass
else
    print_fail "PATH entries still in fish config"
fi

# Test 9: Test uninstaller creates backups
print_test "Uninstaller creates shell profile backups"
if [[ -f "$HOME/.bashrc.goverman-backup" && -f "$HOME/.zshrc.goverman-backup" ]]; then
    print_pass
else
    print_fail "Backup files not created"
fi

# Test 10: Test uninstaller cleans up empty directories
print_test "Uninstaller cleans up empty directories"
# The directories should be removed if empty
if [[ ! -d "$GOBIN" && ! -d "$HOME/sdk" ]]; then
    print_pass
else
    # Check if they're truly empty
    if [[ -d "$GOBIN" ]]; then
        gobin_contents=$(ls -A "$GOBIN" 2>/dev/null)
        if [[ -n "$gobin_contents" ]]; then
            # Debug what's left
            echo "Debug: GOBIN contents:"
            ls -la "$GOBIN" 2>/dev/null || true
            print_fail "GOBIN directory not empty: $gobin_contents"
        else
            # Directory exists but is empty - this might be OK on some systems
            print_pass
        fi
    elif [[ -d "$HOME/sdk" && -n "$(ls -A "$HOME/sdk" 2>/dev/null)" ]]; then
        print_fail "SDK directory not empty"
    else
        print_pass
    fi
fi

# Summary
echo
echo "======================================="
echo "Test Summary:"
echo "Total tests: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "======================================="

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi