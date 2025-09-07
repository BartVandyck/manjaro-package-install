#!/bin/bash

set -e
set -u

SCRIPT_NAME=$(basename "$0")
PACKAGE_NAME="fish"

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install or update Fish shell on Manjaro Linux.

OPTIONS:
    -h, --help      Show this help message
    --dry-run       Show what would be done without executing
    --force         Force reinstallation even if up to date

DESCRIPTION:
    This script will:
    1. Check if Fish shell is already installed
    2. If installed, check if an update is available
    3. Install or update as needed
    4. Do nothing if already installed and up to date

    Note: Fish is available in official repositories, so no AUR helper is needed.

EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

get_installed_version() {
    if pacman -Qi "$PACKAGE_NAME" >/dev/null 2>&1; then
        pacman -Qi "$PACKAGE_NAME" | grep "Version" | awk '{print $3}'
    else
        echo ""
    fi
}

get_available_version() {
    pacman -Si "$PACKAGE_NAME" 2>/dev/null | grep "Version" | awk '{print $3}' | head -1
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

install_fish() {
    local dry_run=${1:-false}
    
    log "Installing Fish shell..."
    if [[ "$dry_run" == "true" ]]; then
        log "[DRY RUN] Would execute: sudo pacman -S --noconfirm $PACKAGE_NAME"
    else
        sudo pacman -S --noconfirm "$PACKAGE_NAME"
        log "Fish shell installed successfully"
        log "To set Fish as your default shell, run: chsh -s /usr/bin/fish"
    fi
}

update_fish() {
    local dry_run=${1:-false}
    
    log "Updating Fish shell..."
    if [[ "$dry_run" == "true" ]]; then
        log "[DRY RUN] Would execute: sudo pacman -S --noconfirm $PACKAGE_NAME"
    else
        sudo pacman -S --noconfirm "$PACKAGE_NAME"
        log "Fish shell updated successfully"
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
    
    log "Starting Fish shell installation/update check..."
    
    if is_package_installed; then
        local installed_version
        local available_version
        
        installed_version=$(get_installed_version)
        log "Fish shell is already installed (version: $installed_version)"
        
        if [[ "$force" == "true" ]]; then
            log "Force flag specified, reinstalling..."
            update_fish "$dry_run"
            return 0
        fi
        
        log "Checking for updates..."
        available_version=$(get_available_version)
        
        if [[ -z "$available_version" ]]; then
            error "Could not retrieve available version information"
        fi
        
        log "Available version: $available_version"
        
        version_compare "$installed_version" "$available_version"
        local cmp_result=$?
        
        case $cmp_result in
            0)
                log "Fish shell is up to date (version: $installed_version)"
                ;;
            1)
                log "Update available: $installed_version -> $available_version"
                update_fish "$dry_run"
                ;;
            2)
                log "Installed version ($installed_version) is newer than available ($available_version)"
                log "No action needed"
                ;;
        esac
    else
        log "Fish shell is not installed"
        install_fish "$dry_run"
    fi
    
    log "Script completed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi