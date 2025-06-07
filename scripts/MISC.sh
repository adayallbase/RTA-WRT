#!/bin/bash

# Source the include file containing common functions and variables
if [[ ! -f "./scripts/INCLUDE.sh" ]]; then
    echo "ERROR: INCLUDE.sh not found in ./scripts/" >&2
    exit 1
fi

set -o errexit  # Exit on error
set -o nounset  # Exit on unset variables
set -o pipefail # Exit if any command in a pipe fails

. ./scripts/INCLUDE.sh

# Initialize environment
init_environment() {
    log "INFO" "Starting: Downloading misc files and setting up configuration"
    log "INFO" "Current path: $PWD"
}

# Setup base-specific configurations
setup_base_config() {
    # Update date in init settings
    sed -i "s/Ouc3kNF6/${DATE}/g" files/etc/uci-defaults/99-init-settings.sh

    case "${BASE}" in
        openwrt)
            log "INFO" "Applying OpenWrt-specific configuration"
            sed -i '/# setup misc settings/ a\mv \/www\/luci-static\/resources\/view\/status\/include\/29_temp.js \/www\/luci-static\/resources\/view\/status\/include\/17_temp.js' files/etc/uci-defaults/99-init-settings.sh
            ;;
        immortalwrt)
            log "INFO" "Applying ImmortalWrt-specific configuration"
            ;;
        *)
            log "WARN" "Unknown base system: ${BASE}"
            ;;
    esac
}

# Handle Amlogic-specific files
handle_amlogic_files() {
    case "${TYPE}" in
        OPHUB|ULO)
            log "INFO" "Removing Amlogic-specific files"
            rm -f files/etc/uci-defaults/70-rootpt-resize
            rm -f files/etc/uci-defaults/80-rootfs-resize
            rm -f files/etc/sysupgrade.conf
            ;;
        *)
            log "INFO" "Non-Amlogic system type: ${TYPE}"
            ;;
    esac
}

# Setup branch-specific configurations
setup_branch_config() {
    local branch_major
    branch_major=$(echo "${BRANCH}" | cut -d'.' -f1)

    case "${branch_major}" in
        24)
            log "INFO" "Applying settings for branch 24.x"
            ;;
        23)
            log "INFO" "Applying settings for branch 23.x"
            ;;
        *)
            log "WARN" "Unknown branch version: ${BRANCH}"
            ;;
    esac
}

# Main execution
main() {
    init_environment
    setup_base_config
    handle_amlogic_files
    setup_branch_config
    log "SUCCESS" "All custom configuration steps completed successfully!"
}

# Execute main
main
