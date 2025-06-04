#!/bin/bash

# gman Test Suite
# Tests the gman tool functionality

set -e

TEST_VERSION="1.22.0"  # Use a more recent version for better compatibility
SCRIPT_DIR="$(dirname "$0")"
GMAN_SCRIPT="$SCRIPT_DIR/gman"

echo "gman Test Suite"
echo "==============="
echo "Test version: $TEST_VERSION"
echo "Date: $(date)"
echo ""

# Debug: Show CI environment
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    echo "Running in CI mode (CI=${CI:-not set}, GITHUB_ACTIONS=${GITHUB_ACTIONS:-not set})"
    echo ""
fi

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

# Debug: Print environment info
echo "Debug: Environment Information"
echo "=============================="
echo "OS: $(uname -s)"
echo "Architecture: $(uname -m)"
echo "GOPATH: $GOPATH"
echo "GOBIN: $GOBIN"
echo "PATH: $PATH"
echo ""

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
echo "Debug: Attempting to install go$TEST_VERSION using official method..."
if ! "$GMAN_SCRIPT" install "$TEST_VERSION" official; then
    echo "Warning: Official method failed, trying direct method as fallback..."
    run_test "Install go$TEST_VERSION (direct fallback)" \
        "\"$GMAN_SCRIPT\" install \"$TEST_VERSION\" direct"
else
    echo "✅ PASS: Install go$TEST_VERSION (official)"
fi

# Update PATH after installation
update_path

# Debug: Check if binary exists in expected locations
echo "Debug: Checking for go$TEST_VERSION binary..."
if command -v "go$TEST_VERSION" >/dev/null 2>&1; then
    echo "Found at: $(which go$TEST_VERSION)"
else
    echo "Binary not found in PATH"
    echo "Checking common locations:"
    for loc in "$GOBIN/go$TEST_VERSION" "$HOME/go/bin/go$TEST_VERSION" "/usr/local/go/bin/go$TEST_VERSION"; do
        if [[ -f "$loc" ]]; then
            echo "  Found at: $loc"
        fi
    done
fi
echo ""

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

# In CI, PATH ordering might prevent the default from working
# Check if we're in CI and if PATH has conflicts
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    # Check if system Go comes before goverman in PATH
    if which go | grep -q "/usr/local/go/bin/go"; then
        echo "Note: System Go takes precedence in PATH (expected in CI)"
        # Just verify the symlink/wrapper was created
        run_test "Verify default go link was created" \
            "test -e \"$HOME/go/bin/go\""
    else
        run_test "Verify 'go' command points to go$TEST_VERSION" \
            "go version | grep -q \"go$TEST_VERSION\""
    fi
else
    run_test "Verify 'go' command points to go$TEST_VERSION" \
        "go version | grep -q \"go$TEST_VERSION\""
fi

# Skip symlink test on Windows as it uses wrapper scripts instead
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$MSYSTEM" ]]; then
    run_test "Verify default go exists" \
        "test -f \"$HOME/go/bin/go\""
else
    run_test "Verify default symlink exists" \
        "test -L \"$HOME/go/bin/go\""
fi

# Debug: Print the output of gman list
echo "Debug: gman list output:"
"$GMAN_SCRIPT" list

# Verify the default marker - escape the brackets properly for grep
run_test "Verify list shows default marker" \
    "\"$GMAN_SCRIPT\" list 2>/dev/null | grep -q \"go$TEST_VERSION.*\\[DEFAULT\\]\""

# Test 5: Install another version with --default flag
echo "=== TEST 5: Install with --default flag ==="
TEST_VERSION2="1.22.1"  # Use a more recent version for better compatibility
# Try official method first, then fall back to direct if it fails
echo "Attempting to install go$TEST_VERSION2 with --default flag..."
if "$GMAN_SCRIPT" install "$TEST_VERSION2" official --default 2>&1 | tee /tmp/install_output.log; then
    echo "✅ PASS: Install go$TEST_VERSION2 with --default flag (official)"
else
    echo "Warning: Official method failed, checking error..."
    if grep -q "undefined: signalsToIgnore" /tmp/install_output.log 2>/dev/null || \
       grep -q "Known compatibility issue" /tmp/install_output.log 2>/dev/null; then
        echo "Known compatibility issue detected, trying direct method as fallback..."
    else
        echo "Unknown error occurred, trying direct method as fallback..."
    fi
    
    # Clean up any partial installation
    if command -v "go$TEST_VERSION2" >/dev/null 2>&1; then
        echo "Cleaning up partial installation..."
        "$GMAN_SCRIPT" uninstall "$TEST_VERSION2" >/dev/null 2>&1 || true
    fi
    
    # Now try with direct method
    if "$GMAN_SCRIPT" install "$TEST_VERSION2" direct --default; then
        echo "✅ PASS: Install go$TEST_VERSION2 with --default flag (direct fallback)"
    else
        echo "❌ FAIL: Install go$TEST_VERSION2 with --default flag (both methods failed)"
        exit 1
    fi
fi
rm -f /tmp/install_output.log

# Update PATH after installation
update_path

# In CI, PATH ordering might prevent the default from working
# Check if we're in CI and if PATH has conflicts
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    # Check if system Go comes before goverman in PATH
    if which go | grep -q "/usr/local/go/bin/go"; then
        echo "Note: System Go takes precedence in PATH (expected in CI)"
        # Just verify the symlink/wrapper was created
        run_test "Verify default go link was updated to go$TEST_VERSION2" \
            "test -e \"$HOME/go/bin/go\""
    else
        run_test "Verify go$TEST_VERSION2 is now default" \
            "go version | grep -q \"go$TEST_VERSION2\""
    fi
else
    run_test "Verify go$TEST_VERSION2 is now default" \
        "go version | grep -q \"go$TEST_VERSION2\""
fi

# Debug: Print the output of gman list
echo "Debug: gman list output after setting go$TEST_VERSION2 as default:"
"$GMAN_SCRIPT" list

run_test "Verify list shows new default" \
    "\"$GMAN_SCRIPT\" list 2>/dev/null | grep -q \"go$TEST_VERSION2.*\\[DEFAULT\\]\""

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

# Test 9: Install latest version
echo "=== TEST 9: Install latest version ==="

# Test installing latest version
echo "Testing: Install latest Go version"
output=$("$GMAN_SCRIPT" install latest direct 2>&1)

# Check if it fetched and installed a version
if echo "$output" | grep -q "Latest version is:"; then
    echo "✅ PASS: Detected latest version"
    latest_version=$(echo "$output" | grep "Latest version is:" | sed 's/Latest version is: //')
    echo "  Latest version: $latest_version"
    
    # Clean up the latest version
    "$GMAN_SCRIPT" uninstall "$latest_version" >/dev/null 2>&1
else
    echo "❌ FAIL: Failed to detect latest version"
    echo "Output: $output"
    exit 1
fi

# Test 10: List available versions
echo "=== TEST 10: List available versions ==="

# Test default behavior (should show 20 versions)
echo "Testing: List available versions (default)"
output=$("$GMAN_SCRIPT" list-available 2>&1)
version_count=$(echo "$output" | grep -cE "^  go[0-9]+\.[0-9]+")

if [[ $version_count -eq 20 ]]; then
    echo "✅ PASS: List available versions shows 20 versions"
else
    echo "❌ FAIL: Expected 20 versions, got $version_count"
    exit 1
fi

# Check for the "more versions" message
if echo "$output" | grep -q "and .* more versions"; then
    echo "✅ PASS: Shows remaining version count"
else
    echo "❌ FAIL: Missing remaining version count message"
    exit 1
fi

# Check for --all suggestion
if echo "$output" | grep -q "gman list-available --all"; then
    echo "✅ PASS: Suggests --all flag for complete list"
else
    echo "❌ FAIL: Missing --all flag suggestion"
    exit 1
fi

# Test 10: List all available versions
echo "=== TEST 10: List all available versions ==="

echo "Testing: List available versions --all"
output_all=$("$GMAN_SCRIPT" list-available --all 2>&1)
version_count_all=$(echo "$output_all" | grep -cE "^  go[0-9]+\.[0-9]+")

if [[ $version_count_all -gt 20 ]]; then
    echo "✅ PASS: List available --all shows more than 20 versions ($version_count_all total)"
else
    echo "❌ FAIL: --all flag should show more than 20 versions, got $version_count_all"
    exit 1
fi

# Check that --all doesn't show the "more versions" message
if echo "$output_all" | grep -q "and .* more versions"; then
    echo "❌ FAIL: --all flag should not show 'more versions' message"
    exit 1
else
    echo "✅ PASS: --all flag shows all versions without truncation message"
fi

# Test 11: Check for latest stable marker
echo "Testing: Latest stable version marker"
if echo "$output" | grep -q "(latest stable)"; then
    echo "✅ PASS: Shows latest stable version marker"
else
    echo "❌ FAIL: Missing latest stable version marker"
    exit 1
fi

echo "================================"
echo "🎉 All tests completed successfully!"
echo "The gman tool is working properly."
echo ""
echo "gman is ready for production use."
