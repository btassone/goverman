#!/bin/bash

# Test script for gman self-update functionality
# This creates a temporary installation to test updates

set -e

echo "Testing gman self-update functionality..."
echo "========================================"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy gman to temp location
cp gman "$TEMP_DIR/gman"
chmod +x "$TEMP_DIR/gman"

# Test 1: Check update command
echo "Test 1: Check for updates"
"$TEMP_DIR/gman" check-update
echo "✓ Test 1 passed"
echo ""

# Test 2: Verify self-update detects git repo
echo "Test 2: Self-update in git repo (should fail)"
if ./gman self-update 2>&1 | grep -q "git repository"; then
    echo "✓ Test 2 passed - correctly detected git repo"
else
    echo "✗ Test 2 failed - did not detect git repo"
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
if curl -sI "$DOWNLOAD_URL" | grep -q "200 OK"; then
    echo "✓ Test 4 passed - download URL is accessible"
else
    echo "✗ Test 4 failed - download URL not accessible"
    exit 1
fi
echo ""

# Test 5: Simulate version mismatch (would trigger update in real scenario)
echo "Test 5: Simulate old version"
# Modify version in temp copy
sed -i.bak 's/GMAN_VERSION="v[0-9.]*"/GMAN_VERSION="v1.0.0"/' "$TEMP_DIR/gman"
if "$TEMP_DIR/gman" check-update | grep -q "Update available"; then
    echo "✓ Test 5 passed - correctly detected update available"
else
    echo "✗ Test 5 failed - did not detect update"
    exit 1
fi
echo ""

echo "======================================"
echo "All tests passed!"
echo ""
echo "Note: Full self-update test requires running outside git repo"
echo "To test actual update:"
echo "  1. Copy gman to /usr/local/bin/"
echo "  2. Run: gman self-update"