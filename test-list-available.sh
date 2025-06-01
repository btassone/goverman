#!/bin/bash

# Test script for list-available functionality

set -e

SCRIPT_DIR="$(dirname "$0")"
GMAN_SCRIPT="$SCRIPT_DIR/gman"

echo "Testing list-available functionality"
echo "===================================="
echo ""

# Test 1: Basic functionality
echo "Test 1: Basic list-available command"
output=$("$GMAN_SCRIPT" list-available 2>&1)
if echo "$output" | grep -q "Available Go versions:"; then
    echo "✅ PASS: Command executes successfully"
else
    echo "❌ FAIL: Command failed to execute"
    exit 1
fi

# Test 2: Default shows 20 versions
echo ""
echo "Test 2: Default shows exactly 20 versions"
version_count=$(echo "$output" | grep -cE "^  go[0-9]+\.[0-9]+")
if [[ $version_count -eq 20 ]]; then
    echo "✅ PASS: Shows exactly 20 versions (got $version_count)"
else
    echo "❌ FAIL: Expected 20 versions, got $version_count"
    exit 1
fi

# Test 3: Shows "more versions" message
echo ""
echo "Test 3: Shows remaining version count"
if echo "$output" | grep -q "and .* more versions"; then
    echo "✅ PASS: Shows remaining version count"
else
    echo "❌ FAIL: Missing remaining version count"
    exit 1
fi

# Test 4: Suggests --all flag
echo ""
echo "Test 4: Suggests --all flag"
if echo "$output" | grep -q "gman list-available --all"; then
    echo "✅ PASS: Suggests --all flag"
else
    echo "❌ FAIL: Missing --all flag suggestion"
    exit 1
fi

# Test 5: Latest stable marker
echo ""
echo "Test 5: Shows latest stable marker"
if echo "$output" | grep -q "(latest stable)"; then
    echo "✅ PASS: Shows latest stable marker"
else
    echo "❌ FAIL: Missing latest stable marker"
    exit 1
fi

# Test 6: --all flag shows more versions
echo ""
echo "Test 6: --all flag functionality"
output_all=$("$GMAN_SCRIPT" list-available --all 2>&1)
version_count_all=$(echo "$output_all" | grep -cE "^  go[0-9]+\.[0-9]+")
if [[ $version_count_all -gt 20 ]]; then
    echo "✅ PASS: --all shows more than 20 versions ($version_count_all total)"
else
    echo "❌ FAIL: --all should show more than 20 versions, got $version_count_all"
    exit 1
fi

# Test 7: --all doesn't show truncation message
echo ""
echo "Test 7: --all doesn't show truncation message"
if echo "$output_all" | grep -q "and .* more versions"; then
    echo "❌ FAIL: --all should not show 'more versions' message"
    exit 1
else
    echo "✅ PASS: --all shows all versions without truncation"
fi

# Test 8: Installation instructions present
echo ""
echo "Test 8: Shows installation instructions"
if echo "$output" | grep -q "gman install"; then
    echo "✅ PASS: Shows installation instructions"
else
    echo "❌ FAIL: Missing installation instructions"
    exit 1
fi

echo ""
echo "===================================="
echo "✅ All list-available tests passed!"