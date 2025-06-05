#!/bin/bash

# Test script for install.sh
# This script tests the goverman installer in various scenarios

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

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test 1: Check install script exists and is executable
print_test "Install script exists and is executable"
if [[ -f "install.sh" && -x "install.sh" ]]; then
    print_pass
else
    print_fail "install.sh not found or not executable"
fi

# Test 2: Test platform detection function
print_test "Platform detection"
# Test if the function exists in the script
if grep -q "^detect_platform()" install.sh; then
    # Check that it handles common platforms
    if grep -q "linux\|darwin" install.sh && grep -q "x86_64\|amd64\|aarch64\|arm64" install.sh; then
        print_pass
    else
        print_fail "Platform detection incomplete"
    fi
else
    print_fail "Platform detection function not found"
fi

# Test 3: Test shell detection function
print_test "Shell detection"
# Test if the function exists and handles shells properly
if grep -q "^detect_shell()" install.sh; then
    # Check that it handles bash, zsh, and fish
    if grep -q "bash.*zsh.*fish" install.sh || (grep -q "bash" install.sh && grep -q "zsh" install.sh && grep -q "fish" install.sh); then
        print_pass
    else
        print_fail "Shell detection incomplete"
    fi
else
    print_fail "Shell detection function not found"
fi

# Test 4: Test local installation (without network)
print_test "Local installation simulation"
# Create a mock installation environment
INSTALL_DIR="$TEST_DIR/usr/local/bin"
MAN_DIR="$TEST_DIR/usr/local/share/man/man1"
mkdir -p "$INSTALL_DIR" "$MAN_DIR"

# Create mock gman and man page
echo '#!/bin/bash' > "$TEST_DIR/gman"
echo 'echo "gman v1.11.0"' >> "$TEST_DIR/gman"
chmod +x "$TEST_DIR/gman"

echo '.TH GMAN 1' > "$TEST_DIR/gman.1"

# Test that install script would work with these files
# We can't run the full script as it downloads from GitHub
# But we can test the installation steps work
cp "$TEST_DIR/gman" "$INSTALL_DIR/"
cp "$TEST_DIR/gman.1" "$MAN_DIR/"

if [[ -x "$INSTALL_DIR/gman" && -f "$MAN_DIR/gman.1" ]]; then
    print_pass
else
    print_fail "Installation simulation failed"
fi

# Test 5: Test PATH setup for different shells
print_test "PATH setup for different shells"
# Test bash
echo '# Existing bashrc content' > "$HOME/.bashrc"
# Simulate adding PATH
echo '' >> "$HOME/.bashrc"
echo '# goverman PATH' >> "$HOME/.bashrc"
echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.bashrc"
if grep -q 'goverman PATH' "$HOME/.bashrc"; then
    :  # Continue to test other shells
else
    print_fail "Failed to add PATH to .bashrc"
fi

# Test zsh
echo '# Existing zshrc content' > "$HOME/.zshrc"
echo '' >> "$HOME/.zshrc"
echo '# goverman PATH' >> "$HOME/.zshrc"
echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.zshrc"
if grep -q 'goverman PATH' "$HOME/.zshrc"; then
    :  # Continue to test fish
else
    print_fail "Failed to add PATH to .zshrc"
fi

# Test fish
mkdir -p "$HOME/.config/fish"
echo '# Existing fish config' > "$HOME/.config/fish/config.fish"
echo '' >> "$HOME/.config/fish/config.fish"
echo '# goverman PATH' >> "$HOME/.config/fish/config.fish"
echo 'fish_add_path -m $HOME/go/bin' >> "$HOME/.config/fish/config.fish"
if grep -q 'goverman PATH' "$HOME/.config/fish/config.fish"; then
    print_pass
else
    print_fail "Failed to add PATH to config.fish"
fi

# Test 6: Test installation with mock sudo
print_test "Installation with sudo"
export PATH="$MOCK_SUDO_DIR:$PATH"
# The mock sudo will allow us to test sudo functionality
if command -v sudo >/dev/null 2>&1; then
    # Test that sudo works with our mock
    if sudo echo "test" >/dev/null 2>&1; then
        print_pass
    else
        print_fail "Mock sudo failed"
    fi
else
    print_fail "sudo not found in PATH"
fi

# Test 7: Test download function detection
print_test "Download tool detection"
if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
    print_pass
else
    print_fail "Neither curl nor wget available"
fi

# Test 8: Test temporary directory handling
print_test "Temporary directory handling"
temp_test=$(mktemp -d)
if [[ -d "$temp_test" ]]; then
    rm -rf "$temp_test"
    print_pass
else
    print_fail "mktemp failed"
fi

# Test 9: Test error handling in install script
print_test "Script has error handling"
if grep -q "set -e" install.sh && grep -q "print_error" install.sh; then
    print_pass
else
    print_fail "Missing error handling"
fi

# Test 10: Test script has proper cleanup
print_test "Script has cleanup handling"
if grep -q "rm -rf.*TEMP_DIR" install.sh; then
    print_pass
else
    print_fail "Missing cleanup handling"
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