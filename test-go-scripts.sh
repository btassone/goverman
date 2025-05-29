#!/bin/bash

# gman Test Suite
# Tests the gman tool functionality

set -e

TEST_VERSION="1.21.5"  # Use an older version for testing
SCRIPT_DIR="$(dirname "$0")"
GMAN_SCRIPT="$SCRIPT_DIR/gman"

echo "gman Test Suite"
echo "==============="
echo "Test version: $TEST_VERSION"
echo "Date: $(date)"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to update PATH to include Go binaries
update_path() {
    GOPATH=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    GOBIN=$(go env GOBIN 2>/dev/null || echo "")
    
    # If GOBIN is empty, use GOPATH/bin
    if [[ -z "$GOBIN" ]]; then
        GOBIN="$GOPATH/bin"
    fi
    
    # Only add to PATH if not already there
    if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
        export PATH="$GOBIN:$PATH"
        echo "Updated PATH with: $GOBIN"
    else
        echo "PATH already contains: $GOBIN"
    fi
}

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Testing: $test_name"
    echo "Command: $test_command"
    
    if eval "$test_command"; then
        echo "✅ PASS: $test_name"
    else
        echo "❌ FAIL: $test_name"
        return 1
    fi
    echo ""
}

# Setup PATH for all tests
# First, ensure we have access to system Go
if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc" 2>/dev/null || true
elif [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Add common Go installation paths
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

# Now setup Go paths
GOPATH=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
GOBIN=$(go env GOBIN 2>/dev/null || echo "$GOPATH/bin")
export PATH="$GOBIN:$PATH"

# Check if Go is available
if ! command -v go >/dev/null 2>&1; then
    echo "Error: Go is not installed. The test requires a base Go installation."
    echo "Please install Go first: https://go.dev/doc/install"
    echo ""
    echo "On Ubuntu/Debian: sudo apt install golang-go"
    echo "Or download from: https://go.dev/dl/"
    exit 1
fi

echo "Using Go: $(which go)"
echo "Go version: $(go version)"
echo ""

# Test shell detection
echo "Testing shell detection..."
echo "========================="
# Source the detect_shell function from install script
detect_shell() {
    local shell_name=""
    if [[ -n "$SHELL" ]]; then
        shell_name=$(basename "$SHELL")
    else
        local user_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ -n "$user_shell" ]]; then
            shell_name=$(basename "$user_shell")
        else
            local ppid_shell=$(ps -p $PPID -o comm= 2>/dev/null | sed 's/^-//')
            if [[ -n "$ppid_shell" ]]; then
                shell_name="$ppid_shell"
            fi
        fi
    fi
    echo "$shell_name"
}

DETECTED_SHELL=$(detect_shell)
echo "Detected shell: $DETECTED_SHELL"
echo "SHELL env var: $SHELL"

# Verify shell detection is reasonable
if [[ -z "$DETECTED_SHELL" ]]; then
    echo "Warning: Could not detect shell"
elif [[ "$DETECTED_SHELL" != "bash" && "$DETECTED_SHELL" != "zsh" && "$DETECTED_SHELL" != "fish" && "$DETECTED_SHELL" != "sh" ]]; then
    echo "Warning: Detected unusual shell: $DETECTED_SHELL"
fi
echo ""

# Pre-test cleanup
echo "Pre-test cleanup..."
if command_exists "go$TEST_VERSION"; then
    echo "Removing existing go$TEST_VERSION..."
    "$GMAN_SCRIPT" uninstall "$TEST_VERSION" || true
fi
echo ""

# Test 1: Install with official method
echo "=== TEST 1: Install with official method ==="
run_test "Install go$TEST_VERSION (official)" \
    "\"$GMAN_SCRIPT\" install \"$TEST_VERSION\" official"

# Update PATH after installation
update_path

run_test "Verify go$TEST_VERSION binary exists" \
    "command_exists \"go$TEST_VERSION\""

run_test "Verify go$TEST_VERSION version output" \
    "go$TEST_VERSION version | grep -q \"go$TEST_VERSION\""

run_test "Verify architecture is correct" \
    "go$TEST_VERSION version | grep -E \"(arm64|amd64)\""

# Test 2: Uninstall
echo "=== TEST 2: Uninstall ==="
run_test "Uninstall go$TEST_VERSION" \
    "\"$GMAN_SCRIPT\" uninstall \"$TEST_VERSION\""

run_test "Verify go$TEST_VERSION is removed" \
    "! command_exists \"go$TEST_VERSION\""

# Test 3: Install with direct method
echo "=== TEST 3: Install with direct method ==="
run_test "Install go$TEST_VERSION (direct)" \
    "\"$GMAN_SCRIPT\" install \"$TEST_VERSION\" direct"

# Update PATH after installation
update_path

run_test "Verify go$TEST_VERSION binary exists (direct)" \
    "command_exists \"go$TEST_VERSION\""

run_test "Verify go$TEST_VERSION version output (direct)" \
    "go$TEST_VERSION version | grep -q \"go$TEST_VERSION\""

run_test "Verify architecture is correct (direct)" \
    "go$TEST_VERSION version | grep -E \"(arm64|amd64)\""

run_test "Verify GOROOT is set correctly" \
    "go$TEST_VERSION env GOROOT | grep -q \"sdk/go$TEST_VERSION\""

# Test 4: Set as default version
echo "=== TEST 4: Set as default version ==="
run_test "Set go$TEST_VERSION as default" \
    "\"$GMAN_SCRIPT\" set-default \"$TEST_VERSION\""

run_test "Verify 'go' command points to go$TEST_VERSION" \
    "go version | grep -q \"go$TEST_VERSION\""

run_test "Verify default symlink exists" \
    "test -L \"$HOME/go/bin/go\""

run_test "Verify list shows default marker" \
    "\"$GMAN_SCRIPT\" list 2>/dev/null | grep -q \"go$TEST_VERSION.*\[DEFAULT\]\""

# Test 5: Install another version with --default flag
echo "=== TEST 5: Install with --default flag ==="
TEST_VERSION2="1.20.14"
run_test "Install go$TEST_VERSION2 with --default flag" \
    "\"$GMAN_SCRIPT\" install \"$TEST_VERSION2\" official --default"

# Update PATH after installation
update_path

run_test "Verify go$TEST_VERSION2 is now default" \
    "go version | grep -q \"go$TEST_VERSION2\""

run_test "Verify list shows new default" \
    "\"$GMAN_SCRIPT\" list 2>/dev/null | grep -q \"go$TEST_VERSION2.*\[DEFAULT\]\""

# Test 6: Uninstall default version
echo "=== TEST 6: Uninstall default version ==="
# First uninstall and capture output
echo "Uninstalling default version go$TEST_VERSION2..."
"$GMAN_SCRIPT" uninstall "$TEST_VERSION2"

# Then verify the symlink was removed
run_test "Verify default symlink is removed after uninstall" \
    "! test -L \"$HOME/go/bin/go\""

# Test 7: Reinstall over existing
echo "=== TEST 7: Reinstall over existing ==="
run_test "Reinstall go$TEST_VERSION (should work)" \
    "echo 'y' | \"$GMAN_SCRIPT\" install \"$TEST_VERSION\" direct"

# Update PATH after reinstallation
update_path

# Test 8: Final cleanup
echo "=== TEST 8: Final cleanup ==="
run_test "Final uninstall go$TEST_VERSION" \
    "\"$GMAN_SCRIPT\" uninstall \"$TEST_VERSION\""

echo "================================"
echo "🎉 All tests completed successfully!"
echo "The gman tool is working properly."
echo ""
echo "gman is ready for production use."
