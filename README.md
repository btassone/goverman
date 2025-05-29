# goverman

[![Test Go Scripts](https://github.com/btassone/goverman/actions/workflows/test.yml/badge.svg)](https://github.com/btassone/goverman/actions/workflows/test.yml)

A simple Go version manager that allows you to install and manage multiple Go versions on your system. Goverman provides a unified tool called `gman` to easily install, uninstall, and switch between different Go versions without affecting your system's default Go installation.

## Overview

Goverman helps developers who need to work with multiple Go versions by:
- Installing specific Go versions alongside your default installation
- Managing multiple Go versions without conflicts
- Providing easy version switching capabilities
- Supporting multiple architectures (amd64, arm64, armv6l)
- Offering both official and direct download installation methods

## Prerequisites

- Bash-compatible shell (bash, zsh, fish, etc.)
- curl or wget (for direct installation method)
- Go 1.17+ (for official installation method)
- Standard UNIX tools (tar, grep, sed)

## Installation

Clone this repository:

```bash
git clone https://github.com/yourusername/goverman.git
cd goverman
chmod +x gman
```

## Shell Support

Goverman automatically detects your shell and adds the Go binary path to the appropriate configuration file:

- **Bash**: Updates `~/.bashrc` or `~/.bash_profile`
- **Zsh**: Updates `~/.zshrc` or `~/.zprofile`
- **Fish**: Updates `~/.config/fish/config.fish`
- **Other shells**: Falls back to `~/.profile`

The installer will:
1. Detect your default shell from the `$SHELL` environment variable
2. Show which shell was detected
3. Prompt you to add the PATH to the correct profile file
4. Provide instructions to apply changes immediately

## Usage

The `gman` tool provides all functionality through a single command:

```bash
gman <command> [options]
```

### Commands

#### Installing a Go Version

The install command supports two installation methods:

**Official Method (default)** - Uses `go install` to download and install Go versions:
```bash
gman install 1.23.9
```

**Direct Method** - Downloads Go binaries directly from the official Go website:
```bash
gman install 1.23.9 direct
```

**Install and Set as Default** - Install a version and set it as the default `go` command:
```bash
gman install 1.23.9 --default
```

#### Uninstalling a Go Version

Remove a specific Go version:
```bash
gman uninstall 1.23.9
```

#### List Installed Versions

View all Go versions installed by goverman:
```bash
gman list
```

#### Set Default Version

Set an installed version as the default `go` command:
```bash
gman set-default 1.23.9
```

#### Help

Show usage information:
```bash
gman help
```

### Using Installed Go Versions

After installation, versioned binaries are available in your PATH:

```bash
# Use a specific version
go1.23.9 version

# Run go commands with a specific version
go1.23.9 build ./...
go1.23.9 test ./...
```

### Testing gman

Run the automated test suite to verify gman works correctly:

```bash
./test-go-scripts.sh
```

The test script will:
- Test both installation methods
- Verify correct version installation
- Test reinstallation scenarios
- Test the set-default functionality
- Clean up test installations

## How It Works

1. **gman**: A unified tool that combines all functionality:
   - **install**: Creates versioned Go binaries (e.g., `go1.23.9`)
     - Installs to `$GOBIN` or `$GOPATH/bin`
     - Sets up PATH if needed
     - Supports multiple architectures automatically
     - Can optionally set the installed version as default
   - **uninstall**: Removes the versioned binary and cleans up the associated GOROOT directory
   - **list**: Shows all installed Go versions and identifies the default
   - **set-default**: Creates a symlink to use a specific version as the default `go` command
   - **help**: Shows usage information

2. **test-go-scripts.sh**:
   - Automated testing of gman functionality
   - Tests install/uninstall operations
   - Verifies set-default functionality
   - Ensures gman works correctly across different scenarios

## Supported Platforms

- Linux (amd64, arm64, armv6l)
- macOS (amd64, arm64)
- Windows (amd64) - via Git Bash or WSL

## Contributing

Pull requests are welcome! Please ensure all tests pass by running `./test-go-scripts.sh` before submitting.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
