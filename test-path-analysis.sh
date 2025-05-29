#!/bin/bash

# Source the analyze_path_for_go function from install-go.sh
source <(grep -A 30 "^analyze_path_for_go()" install-go.sh)

# Test the function
echo "Testing PATH analysis..."
echo "Current PATH: $PATH"
echo ""

# Assuming default gobin is ~/go/bin
gobin="$HOME/go/bin"
echo "Testing with gobin: $gobin"

result=$(analyze_path_for_go "$gobin")
issues_found=$(echo "$result" | cut -d'|' -f1)
gobin_position=$(echo "$result" | cut -d'|' -f2)
conflicting_positions=$(echo "$result" | cut -d'|' -f3)

echo "Analysis results:"
echo "  Issues found: $issues_found"
echo "  Gobin position: $gobin_position"
echo "  Conflicting positions: $conflicting_positions"