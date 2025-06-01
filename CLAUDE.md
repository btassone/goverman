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

### 2025-05-30 Session - GitHub Actions Test Failures Investigation
- Investigated test failures on Ubuntu 20.04, macOS 12, and macOS 13
- Identified root causes:
  - golang.org/dl installation failures with "undefined: signalsToIgnore" error
  - Known issue when installing older Go versions with newer base Go versions
  - OS-specific issues with getent command availability on macOS
  - PATH configuration issues in GitHub Actions environment
- Implemented fixes:
  - Updated test versions from 1.21.5/1.20.14 to 1.22.0/1.21.8 for better compatibility
  - Added error detection for known golang.org/dl issues
  - Enhanced debugging output for environment information
  - Improved fallback mechanisms (test falls back to direct method if official fails)
  - Better error handling for curl/wget downloads
  - Fixed getent fallback for systems without it
- Created github-actions-fixes.md documenting all issues and solutions

### 2025-06-01 Session - Alpine Linux Support
- Added comprehensive Alpine Linux support to goverman
- Implemented Alpine/musl libc detection:
  - Created `detect_musl()` function that checks for musl via ldd, /etc/alpine-release, or apk
  - Both installation methods now detect and warn Alpine users about compatibility
- Updated CI/CD pipeline:
  - Initially added separate Alpine test job, then refactored to unified matrix
  - Alpine tests run in alpine:latest container with all dependencies
  - All tests passing on Alpine Linux
- Documentation improvements:
  - Added comprehensive platform support section to README
  - Documented all supported operating systems and architectures
  - Added missing `list-available` command documentation
  - Included Alpine Linux compatibility notes and recommendations
- Created test-alpine-detection.sh for verification
- Released v1.6.0 with full Alpine Linux support

## Usage Reminders
```bash
# Install a Go version
gman install 1.23.9 [official|direct] [--default]

# Uninstall a version
gman uninstall 1.23.9

# List installed versions
gman list

# List available versions to install
gman list-available

# Set default version
gman set-default 1.23.9

# Check gman version
gman version

# Run tests
./test-go-scripts.sh
```

## Future Considerations
- Possible integration with go.mod for project-specific versions
- Enhanced conflict resolution for system Go installations
- Add support for beta/RC versions
- Cache available versions list for offline use