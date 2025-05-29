# Claude Context for Goverman Project

## Project Overview
**goverman** is a Go version manager that allows installing and managing multiple Go versions on a single system. The project provides a unified tool called `gman` to easily install, uninstall, and switch between different Go versions without affecting the system's default Go installation.

## Key Features
- Install multiple Go versions side-by-side using versioned binaries (e.g., `go1.23.9`)
- Two installation methods:
  - **Official**: Uses `go install golang.org/dl/goX.Y.Z@latest` (recommended)
  - **Direct**: Downloads and extracts binary directly from go.dev (fallback for ARM64 issues)
- Set any installed version as the default `go` command
- Automatic PATH setup for different shells (bash, zsh, fish)
- List all installed versions with clear status indicators
- Clean uninstall of specific versions

## Technical Implementation
- Single bash script `gman` that handles all operations
- Supports multiple architectures: amd64, arm64, armv6l
- Works on Linux, macOS, and Windows (via WSL)
- Detects user's shell and updates appropriate profile files
- Handles both GOBIN and GOPATH configurations
- Creates wrapper scripts for direct installations that set proper GOROOT

## Recent Development History
Based on git commits, we've recently worked on:

1. **PATH Ordering Issues** (commits bb2c258, dd04218)
   - Fixed problems where system or Homebrew Go installations took precedence
   - Ensured goverman-managed versions appear first in PATH
   - Added detection for conflicting Go installations

2. **Default Version Management** (commits de4a622, b368ddd)
   - Implemented `--default` flag during installation
   - Fixed detection of Homebrew Go conflicts
   - Added proper PATH analysis to warn about conflicts

3. **Shell Profile Handling** (commit bb2c258)
   - Fixed PATH exports to append at end of shell profiles
   - Improved shell detection logic
   - Better handling of different shell configurations

4. **Project Refactoring** (commit 25d4c7a)
   - Combined separate install/uninstall scripts into unified `gman` tool
   - Simplified user interface with single entry point

## Current State
- The project has a comprehensive test suite (`test-go-scripts.sh`)
- GitHub Actions CI/CD is set up for automated testing
- All major features are implemented and working
- Edge cases around PATH ordering and shell detection have been addressed

## Known Issues and Considerations
- When Homebrew Go is installed, PATH ordering can cause conflicts
- The tool offers to fix PATH ordering when conflicts are detected
- Direct installation method is provided as fallback for ARM64 CGO issues

## Session Memory

### 2025-05-29 Session (Part 1)
- Explored implementing a memory system for Claude sessions
- Initially considered `.claude/sessions.md` approach but decided CLAUDE.md is the appropriate place
- Cleaned up experimental `.claude` directory structure
- Consolidated all context into this CLAUDE.md file for persistence across sessions

### 2025-05-29 Session (Part 2)
- Added `version` command to gman tool
  - Shows current version using `git describe` when in git repo
  - Falls back to hardcoded version outside git repos
  - Supports `-v` and `--version` flags
- Created and pushed v1.3.1 release with proper GitHub release notes
- Standardized all previous release notes to consistent format
- Rewrote git history to correct commit authorship
  - Changed all commits to show Brandon Tassone as author
  - Preserved commit messages and history
  - Force pushed to update remote repository
- Expanded GitHub Actions test matrix
  - Added Ubuntu 22.04 and 20.04 for LTS coverage
  - Added macOS 13 and 12 for broader macOS testing
  - Added Windows support with Git Bash
  - Now testing on 7 different OS configurations

## Usage Reminders
```bash
# Install a Go version
gman install 1.23.9 [official|direct] [--default]

# Uninstall a version
gman uninstall 1.23.9

# List installed versions
gman list

# Set default version
gman set-default 1.23.9

# Check gman version
gman version

# Run tests
./test-go-scripts.sh
```

## Future Considerations
- Consider adding version listing from go.dev
- Possible integration with go.mod for project-specific versions
- Enhanced conflict resolution for system Go installations