# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains installation scripts for various packages on Manjaro Linux. Each script is designed to automate the installation process for specific software packages.

## Project Structure

- `*.sh` files: Individual installation scripts for different packages
- Each script should be executable and self-contained
- Scripts are named with the pattern `{package-name}-install.sh`

## Development Commands

### Making Scripts Executable
```bash
chmod +x script-name.sh
```

### Testing Scripts
```bash
# Test script syntax
bash -n script-name.sh

# Run script in dry-run mode if supported
./script-name.sh --dry-run
```

### Script Development Guidelines

- All scripts should include proper error handling with `set -e` and `set -u`
- Include usage information and help text
- Test package manager availability before attempting installation
- Provide clear output messages for user feedback
- Handle both AUR and official repository packages appropriately using `pacman` and/or `yay`/`paru`

## Common Manjaro Package Management Commands

```bash
# Update system packages
sudo pacman -Syu

# Install from official repositories
sudo pacman -S package-name

# Install from AUR (requires AUR helper like yay or paru)
yay -S package-name
paru -S package-name

# Check if package is installed
pacman -Qi package-name
```

### Post Development
After each push commands I want you to also copy all files to this location 
 "C:\Users\Bart\OneDrive - Capri-Technology BVBA\Scripts\linuxInstall"

 You only have to do this when run on the windows machine "LEGION"