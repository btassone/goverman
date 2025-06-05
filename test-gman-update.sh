#!/bin/bash

# Test script for gman-update functionality
# This tests the standalone update script

set -e

echo "Testing gman-update functionality..."
echo "====================================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=10

# Helper function to check test result
check_test() {
    if [[ $1 -eq 0 ]]; then
        echo "✓ Test $2 passed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ Test $2 failed"
    fi
    echo ""
}

# Create temporary directory for testing
TEMP_DIR=$(mktemp -d)
trap "chmod -R 755 $TEMP_DIR 2>/dev/null; rm -rf $TEMP_DIR" EXIT

# Test 1: Script exists and is executable
echo "Test 1: Check gman-update exists and is executable"
if [[ -f "gman-update" ]] && [[ -x "gman-update" ]]; then
    check_test 0 1
else
    check_test 1 1
fi

# Test 2: Script has proper shebang
echo "Test 2: Check gman-update has proper shebang"
if head -1 gman-update | grep -q "^#!/bin/bash"; then
    check_test 0 2
else
    check_test 1 2
fi

# Test 3: Test gman-update output structure
echo "Test 3: Check gman-update runs and produces expected output"
if bash gman-update 2>&1 | grep -q "gman Update Script"; then
    check_test 0 3
else
    check_test 1 3
fi

# Test 4: Test with gman in git repository
echo "Test 4: Detect git repository"
(
    # Create a fake git repo
    mkdir -p "$TEMP_DIR/repo/.git"
    cp gman "$TEMP_DIR/repo/gman"
    chmod +x "$TEMP_DIR/repo/gman"
    export PATH="$TEMP_DIR/repo:/usr/bin:/bin"
    cd "$TEMP_DIR"
    if bash "$OLDPWD/gman-update" 2>&1 | grep -q "git repository"; then
        exit 0
    else
        exit 1
    fi
)
check_test $? 4

# Test 5: Test version detection
echo "Test 5: Version detection from gman script"
(
    # Create a test gman with known version
    mkdir -p "$TEMP_DIR/bin"
    cat > "$TEMP_DIR/bin/gman" << 'EOF'
#!/bin/bash
GMAN_VERSION="v1.0.0"
echo "test"
EOF
    chmod +x "$TEMP_DIR/bin/gman"
    export PATH="$TEMP_DIR/bin:/usr/bin:/bin"
    cd "$TEMP_DIR"
    
    # The update script should detect the version
    if bash "$OLDPWD/gman-update" 2>&1 | grep -q "Current version: v1.0.0"; then
        exit 0
    else
        exit 1
    fi
)
check_test $? 5

# Test 6: Test permission check by checking gman-update code
echo "Test 6: Check permission handling in gman-update"
if grep -q "No write permission" gman-update && grep -q '\-w.*gman_path' gman-update; then
    check_test 0 6
else
    check_test 1 6
fi

# Test 7: Test curl download functionality
echo "Test 7: Check curl download in gman-update"
if grep -q 'curl -fsSL -o "$temp_file" "$download_url"' gman-update; then
    check_test 0 7
else
    check_test 1 7
fi

# Test 8: Test wget fallback
echo "Test 8: Check wget fallback in gman-update"
if grep -q 'wget -qO "$temp_file" "$download_url"' gman-update; then
    check_test 0 8
else
    check_test 1 8
fi

# Test 9: Test backup functionality mentioned
echo "Test 9: Check backup functionality"
if grep -q "backup" gman-update && grep -q '${gman_path}.backup' gman-update; then
    check_test 0 9
else
    check_test 1 9
fi

# Test 10: Test SSL fallback options
echo "Test 10: Check SSL fallback handling"
if grep -q "\-k\|--no-check-certificate" gman-update; then
    check_test 0 10
else
    check_test 1 10
fi

# Summary
echo "=================================="
echo "Test Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed"
echo ""

if [[ $TESTS_PASSED -eq $TESTS_TOTAL ]]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi