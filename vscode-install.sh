#!/bin/bash

set -e
set -u

SCRIPT_NAME=$(basename "$0")
PACKAGE_NAME="visual-studio-code-bin"

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install or update Visual Studio Code on Manjaro Linux.

OPTIONS:
    -h, --help      Show this help message
    --dry-run       Show what would be done without executing
    --force         Force reinstallation even if up to date

DESCRIPTION:
    This script will:
    1. Check if Visual Studio Code is already installed
    2. If installed, check if an update is available
    3. Install or update as needed
    4. Do nothing if already installed and up to date

    Note: Installs the official Microsoft build from AUR (visual-studio-code-bin).

EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

install_aur_helper() {
    local dry_run=${1:-false}
    
    log "No AUR helper found. Installing 'yay'..."
    if [[ "$dry_run" == "true" ]]; then
        log "[DRY RUN] Would install yay AUR helper"
        return 0
    fi
    
    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        log "Installing git (required for AUR helper)..."
        sudo pacman -S --noconfirm git
    fi
    
    # Check if base-devel is installed
    if ! pacman -Qi base-devel >/dev/null 2>&1; then
        log "Installing base-devel (required for AUR helper)..."
        sudo pacman -S --noconfirm base-devel
    fi
    
    # Install yay
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd /
    rm -rf "$temp_dir"
    
    log "yay installed successfully"
}

check_aur_helper() {
    local dry_run=${1:-false}
    
    if command -v yay >/dev/null 2>&1; then
        echo "yay"
    elif command -v paru >/dev/null 2>&1; then
        echo "paru"
    else
        log "No AUR helper found"
        echo -n "Would you like to install 'yay' automatically? (y/n): "
        read -r reply
        if [[ $reply =~ ^[Yy]$ ]]; then
            install_aur_helper "$dry_run"
            echo "yay"
        else
            error "AUR helper is required. Please install 'yay' or 'paru' manually and try again."
        fi
    fi
}

get_installed_version() {
    if pacman -Qi "$PACKAGE_NAME" >/dev/null 2>&1; then
        pacman -Qi "$PACKAGE_NAME" | grep "Version" | awk '{print $3}'
    else
        echo ""
    fi
}

get_available_version() {
    local aur_helper=$1
    $aur_helper -Si "$PACKAGE_NAME" 2>/dev/null | grep "Version" | awk '{print $3}' | head -1
}

is_package_installed() {
    pacman -Qi "$PACKAGE_NAME" >/dev/null 2>&1
}

version_compare() {
    local version1=$1
    local version2=$2
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local ver1_clean=$(echo "$version1" | sed 's/-[0-9]*$//')
    local ver2_clean=$(echo "$version2" | sed 's/-[0-9]*$//')
    
    if printf '%s\n%s\n' "$ver1_clean" "$ver2_clean" | sort -V -C; then
        return 1
    else
        return 2
    fi
}

install_vscode() {
    local aur_helper=$1
    local dry_run=${2:-false}
    
    log "Installing Visual Studio Code..."
    if [[ "$dry_run" == "true" ]]; then
        log "[DRY RUN] Would execute: $aur_helper -S --noconfirm $PACKAGE_NAME"
    else
        $aur_helper -S --noconfirm "$PACKAGE_NAME"
        log "Visual Studio Code installed successfully"
        log "You can now launch VSCode with the 'code' command"
    fi
}

update_vscode() {
    local aur_helper=$1
    local dry_run=${2:-false}
    
    log "Updating Visual Studio Code..."
    if [[ "$dry_run" == "true" ]]; then
        log "[DRY RUN] Would execute: $aur_helper -S --noconfirm $PACKAGE_NAME"
    else
        $aur_helper -S --noconfirm "$PACKAGE_NAME"
        log "Visual Studio Code updated successfully"
    fi
}

main() {
    local dry_run=false
    local force=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
    
    log "Starting Visual Studio Code installation/update check..."
    
    local aur_helper
    aur_helper=$(check_aur_helper "$dry_run")
    log "Using AUR helper: $aur_helper"
    
    if is_package_installed; then
        local installed_version
        local available_version
        
        installed_version=$(get_installed_version)
        log "Visual Studio Code is already installed (version: $installed_version)"
        
        if [[ "$force" == "true" ]]; then
            log "Force flag specified, reinstalling..."
            update_vscode "$aur_helper" "$dry_run"
            return 0
        fi
        
        log "Checking for updates..."
        available_version=$(get_available_version "$aur_helper")
        
        if [[ -z "$available_version" ]]; then
            error "Could not retrieve available version information"
        fi
        
        log "Available version: $available_version"
        
        version_compare "$installed_version" "$available_version"
        local cmp_result=$?
        
        case $cmp_result in
            0)
                log "Visual Studio Code is up to date (version: $installed_version)"
                ;;
            1)
                log "Update available: $installed_version -> $available_version"
                update_vscode "$aur_helper" "$dry_run"
                ;;
            2)
                log "Installed version ($installed_version) is newer than available ($available_version)"
                log "No action needed"
                ;;
        esac
    else
        log "Visual Studio Code is not installed"
        install_vscode "$aur_helper" "$dry_run"
    fi
    
    log "Script completed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi