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

#### List Available Versions

View available Go versions that can be installed:
```bash
# Show recent versions (top 20)
gman list-available

# Show all available versions
gman list-available --all
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

### Operating Systems

- **Linux**
  - Standard distributions (Ubuntu, Debian, Fedora, etc.)
  - Enterprise distributions (AlmaLinux, CentOS, RHEL, Rocky Linux)
  - SUSE-based distributions (openSUSE Leap, openSUSE Tumbleweed, SLES)
  - Arch-based distributions (Arch Linux, Manjaro, EndeavourOS)
  - Source-based distributions (Gentoo, Funtoo)
  - Alpine Linux (musl libc) - with limitations*
- **macOS**
  - macOS 12 (Monterey) and later
  - Both Intel and Apple Silicon
- **Windows**
  - Windows 10/11 via Git Bash or WSL
  - Windows Server 2019 and later

### Architectures

- **amd64** (x86_64) - Intel/AMD 64-bit processors
- **arm64** (aarch64) - ARM 64-bit processors (Apple Silicon, AWS Graviton, etc.)
- **armv6l** - ARM 32-bit processors (Raspberry Pi, etc.)

### Distribution Detection

Goverman automatically detects your Linux distribution and displays it during installation. This helps with:
- Diagnosing compatibility issues
- Providing distribution-specific recommendations
- Better support and troubleshooting

Detected distributions include: Ubuntu, Debian, Fedora, AlmaLinux, CentOS, RHEL, Rocky Linux, openSUSE, SLES, Arch Linux, Gentoo, Alpine, and more.

### Notes on Alpine Linux Support

Alpine Linux uses musl libc instead of glibc, which can affect Go binary compatibility:
- Official Go binaries from go.dev are built for glibc and may have limited compatibility
- For best results on Alpine, consider using Alpine's package manager: `apk add go`
- The direct installation method may work better than the official method
- Some older Go versions may not work at all due to libc differences

## Testing

Goverman has comprehensive test coverage across multiple platforms:
- Automated CI/CD tests run on every push and pull request
- Tests run on 10+ different OS configurations including:
  - Ubuntu (latest, 22.04)
  - macOS (latest Apple Silicon, Intel)
  - Windows (via Git Bash)
  - Alpine Linux (musl libc)
  - AlmaLinux 8 & 9
  - openSUSE Leap & Tumbleweed
  - Arch Linux
  - Gentoo
- Run tests locally with `./test-go-scripts.sh`

## Contributing

Pull requests are welcome! Please ensure all tests pass by running `./test-go-scripts.sh` before submitting.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
