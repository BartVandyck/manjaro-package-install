#!/bin/bash

set -e
set -u

SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Install or update all applications using individual *-install.sh scripts.

OPTIONS:
    -h, --help      Show this help message
    --dry-run       Show what would be done without executing
    --force         Force reinstallation even if up to date
    --continue      Continue on errors (don't stop if one script fails)
    --list          List all available install scripts and exit

DESCRIPTION:
    This script will automatically discover and execute all *-install.sh scripts
    in the current directory. Each script will be run with the same options
    passed to this wrapper script.
    
    Available install scripts will be executed in alphabetical order.
    
    By default, the script stops on the first error. Use --continue to 
    keep installing other applications even if one fails.

EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

warning() {
    echo "[WARNING] $*" >&2
}

list_install_scripts() {
    local scripts=()
    
    while IFS= read -r -d '' script; do
        scripts+=("$(basename "$script")")
    done < <(find "$SCRIPT_DIR" -name "*-install.sh" -not -name "install-all.sh" -print0 | sort -z)
    
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "No *-install.sh scripts found in $SCRIPT_DIR"
        return 1
    fi
    
    echo "Available install scripts:"
    for script in "${scripts[@]}"; do
        local app_name=$(echo "$script" | sed 's/-install\.sh$//')
        echo "  - $script ($app_name)"
    done
    
    return 0
}

run_install_scripts() {
    local dry_run=${1:-false}
    local force=${2:-false}
    local continue_on_error=${3:-false}
    
    local scripts=()
    local failed_scripts=()
    local successful_scripts=()
    
    # Find all *-install.sh scripts except this one
    while IFS= read -r -d '' script; do
        scripts+=("$script")
    done < <(find "$SCRIPT_DIR" -name "*-install.sh" -not -name "install-all.sh" -print0 | sort -z)
    
    if [ ${#scripts[@]} -eq 0 ]; then
        error "No *-install.sh scripts found in $SCRIPT_DIR"
    fi
    
    log "Found ${#scripts[@]} install script(s) to execute"
    
    # Build arguments for individual scripts
    local script_args=()
    if [[ "$dry_run" == "true" ]]; then
        script_args+=("--dry-run")
    fi
    if [[ "$force" == "true" ]]; then
        script_args+=("--force")
    fi
    
    # Execute each script
    for script in "${scripts[@]}"; do
        local script_name=$(basename "$script")
        local app_name=$(echo "$script_name" | sed 's/-install\.sh$//')
        
        log "=================================================="
        log "Executing: $script_name ($app_name)"
        log "=================================================="
        
        if [[ "$dry_run" == "true" ]]; then
            log "[DRY RUN] Would execute: $script ${script_args[*]}"
        else
            if "$script" "${script_args[@]}"; then
                successful_scripts+=("$script_name")
                log "✓ $script_name completed successfully"
            else
                failed_scripts+=("$script_name")
                warning "✗ $script_name failed"
                
                if [[ "$continue_on_error" == "false" ]]; then
                    error "Stopping due to failure in $script_name. Use --continue to skip failed scripts."
                else
                    warning "Continuing with remaining scripts..."
                fi
            fi
        fi
        
        echo
    done
    
    # Summary
    log "=================================================="
    log "INSTALLATION SUMMARY"
    log "=================================================="
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY RUN completed - no actual changes made"
        log "Would have processed ${#scripts[@]} script(s)"
    else
        log "Successful installations (${#successful_scripts[@]}):"
        for script in "${successful_scripts[@]}"; do
            local app_name=$(echo "$script" | sed 's/-install\.sh$//')
            log "  ✓ $app_name"
        done
        
        if [ ${#failed_scripts[@]} -gt 0 ]; then
            log "Failed installations (${#failed_scripts[@]}):"
            for script in "${failed_scripts[@]}"; do
                local app_name=$(echo "$script" | sed 's/-install\.sh$//')
                log "  ✗ $app_name"
            done
        fi
    fi
    
    if [ ${#failed_scripts[@]} -gt 0 ] && [[ "$continue_on_error" == "true" ]]; then
        exit 1
    fi
}

main() {
    local dry_run=false
    local force=false
    local continue_on_error=false
    local list_only=false
    
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
            --continue)
                continue_on_error=true
                shift
                ;;
            --list)
                list_only=true
                shift
                ;;
            *)
                error "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
    
    if [[ "$list_only" == "true" ]]; then
        list_install_scripts
        exit 0
    fi
    
    log "Starting batch installation of all applications..."
    
    if [[ "$dry_run" == "true" ]]; then
        log "DRY RUN MODE - No actual changes will be made"
    fi
    
    if [[ "$continue_on_error" == "true" ]]; then
        log "CONTINUE MODE - Will attempt all scripts even if some fail"
    fi
    
    run_install_scripts "$dry_run" "$force" "$continue_on_error"
    
    log "Batch installation completed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi