#!/bin/bash

# Go Scripts Test Suite
# Tests both install and uninstall scripts

set -e

TEST_VERSION="1.21.5"  # Use an older version for testing
SCRIPT_DIR="$(dirname "$0")"
INSTALL_SCRIPT="$SCRIPT_DIR/install-go.sh"
UNINSTALL_SCRIPT="$SCRIPT_DIR/uninstall-go.sh"

echo "Go Scripts Test Suite"
echo "===================="
echo "Test version: $TEST_VERSION"
echo "Date: $(date)"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# Pre-test cleanup
echo "Pre-test cleanup..."
if command_exists "go$TEST_VERSION"; then
    echo "Removing existing go$TEST_VERSION..."
    "$UNINSTALL_SCRIPT" "$TEST_VERSION" || true
fi
echo ""

# Test 1: Install with official method
echo "=== TEST 1: Install with official method ==="
run_test "Install go$TEST_VERSION (official)" \
    "\"$INSTALL_SCRIPT\" \"$TEST_VERSION\" official"

run_test "Verify go$TEST_VERSION binary exists" \
    "command_exists \"go$TEST_VERSION\""

run_test "Verify go$TEST_VERSION version output" \
    "go$TEST_VERSION version | grep -q \"go$TEST_VERSION\""

run_test "Verify architecture is correct" \
    "go$TEST_VERSION version | grep -E \"(arm64|amd64)\""

# Test 2: Uninstall
echo "=== TEST 2: Uninstall ==="
run_test "Uninstall go$TEST_VERSION" \
    "\"$UNINSTALL_SCRIPT\" \"$TEST_VERSION\""

run_test "Verify go$TEST_VERSION is removed" \
    "! command_exists \"go$TEST_VERSION\""

# Test 3: Install with direct method
echo "=== TEST 3: Install with direct method ==="
run_test "Install go$TEST_VERSION (direct)" \
    "\"$INSTALL_SCRIPT\" \"$TEST_VERSION\" direct"

run_test "Verify go$TEST_VERSION binary exists (direct)" \
    "command_exists \"go$TEST_VERSION\""

run_test "Verify go$TEST_VERSION version output (direct)" \
    "go$TEST_VERSION version | grep -q \"go$TEST_VERSION\""

run_test "Verify architecture is correct (direct)" \
    "go$TEST_VERSION version | grep -E \"(arm64|amd64)\""

run_test "Verify GOROOT is set correctly" \
    "go$TEST_VERSION env GOROOT | grep -q \"sdk/go$TEST_VERSION\""

# Test 4: Reinstall over existing
echo "=== TEST 4: Reinstall over existing ==="
run_test "Reinstall go$TEST_VERSION (should work)" \
    "echo 'y' | \"$INSTALL_SCRIPT\" \"$TEST_VERSION\" direct"

# Test 5: Final cleanup
echo "=== TEST 5: Final cleanup ==="
run_test "Final uninstall go$TEST_VERSION" \
    "\"$UNINSTALL_SCRIPT\" \"$TEST_VERSION\""

echo "================================"
echo "🎉 All tests completed successfully!"
echo "Both install and uninstall scripts are working properly."
echo ""
echo "The scripts are ready for production use."
