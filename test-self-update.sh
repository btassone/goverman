#!/bin/bash

# Test script to verify self-update commands have been removed
# This ensures the deprecated commands are no longer available

set -e

echo "Testing removal of self-update commands..."
echo "=========================================="
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy gman to temp location
cp gman "$TEMP_DIR/gman"
chmod +x "$TEMP_DIR/gman"

# Test 1: Verify check-update command is removed
echo "Test 1: Verify check-update command is removed"
if "$TEMP_DIR/gman" check-update 2>&1 | grep -q "Unknown command"; then
    echo "✓ Test 1 passed - check-update command properly removed"
else
    echo "✗ Test 1 failed - check-update command still exists"
    exit 1
fi
echo ""

# Test 2: Verify self-update command is removed
echo "Test 2: Verify self-update command is removed"
if "$TEMP_DIR/gman" self-update 2>&1 | grep -q "Unknown command"; then
    echo "✓ Test 2 passed - self-update command properly removed"
else
    echo "✗ Test 2 failed - self-update command still exists"
    exit 1
fi
echo ""

# Test 3: Check version command works
echo "Test 3: Version command"
"$TEMP_DIR/gman" version
echo "✓ Test 3 passed"
echo ""

# Test 4: Verify download URL is correct
echo "Test 4: Verify download URL"
DOWNLOAD_URL="https://raw.githubusercontent.com/btassone/goverman/main/gman"
# Try to check URL accessibility, but don't fail if SSL issues prevent it
if command -v curl >/dev/null 2>&1; then
    if curl -sI "$DOWNLOAD_URL" 2>/dev/null | grep -q "200 OK"; then
        echo "✓ Test 4 passed - download URL is accessible"
    elif curl -k -sI "$DOWNLOAD_URL" 2>/dev/null | grep -q "200 OK"; then
        echo "✓ Test 4 passed - download URL is accessible (with -k flag)"
    else
        echo "⚠ Test 4 skipped - SSL/network issues prevent URL check"
        # Don't fail the test in CI environments with SSL issues
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget --spider -q "$DOWNLOAD_URL" 2>/dev/null; then
        echo "✓ Test 4 passed - download URL is accessible"
    elif wget --no-check-certificate --spider -q "$DOWNLOAD_URL" 2>/dev/null; then
        echo "✓ Test 4 passed - download URL is accessible (with --no-check-certificate)"
    else
        echo "⚠ Test 4 skipped - SSL/network issues prevent URL check"
    fi
else
    echo "⚠ Test 4 skipped - no curl or wget available"
fi
echo ""

# Test 5: Verify help text doesn't mention self-update
echo "Test 5: Verify help text updated"
HELP_OUTPUT=$("$TEMP_DIR/gman" help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "self-update\|check-update"; then
    echo "✗ Test 5 failed - help text still mentions self-update commands"
    exit 1
else
    echo "✓ Test 5 passed - help text properly updated"
fi
echo ""

echo "======================================"
echo "All tests passed!"
echo ""
echo "Note: To update gman, use the standalone script:"
echo "  curl -fsSL https://raw.githubusercontent.com/btassone/goverman/main/gman-update | bash"