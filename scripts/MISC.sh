#!/bin/bash

. ./scripts/INCLUDE.sh

# Initialize environment
init_environment() {
    log "INFO" "Start Downloading Misc files and setup configuration!"
    log "INFO" "Current Path: $PWD"
}

# Setup base-specific configurations
setup_base_config() {
    # Update date in init settings
    sed -i "s/Ouc3kNF6/${DATE}/g" files/etc/uci-defaults/99-init-settings.sh
    
    case "${BASE}}" in
        "openwrt")
            log "INFO" "Configuring OpenWrt specific settings"
            sed -i '/# setup misc settings/ a\mv \/www\/luci-static\/resources\/view\/status\/include\/29_temp.js \/www\/luci-static\/resources\/view\/status\/include\/17_temp.js' files/etc/uci-defaults/99-init-settings.sh
            ;;
        "immortalwrt")
            log "INFO" "Configuring ImmortalWrt specific settings"
            ;;
        *)
            log "INFO" "Unknown base system: ${BASE}}"
            ;;
    esac
}

# Handle Amlogic-specific files
handle_amlogic_files() {
    case "${TYPE}" in
        "OPHUB")
            log "INFO" "Removing Amlogic-specific files"
            rm -f files/etc/uci-defaults/70-rootpt-resize
            rm -f files/etc/uci-defaults/80-rootfs-resize
            rm -f files/etc/sysupgrade.conf
            ;;
        "ULO")
            log "INFO" "Removing Amlogic-specific files"
            rm -f files/etc/uci-defaults/70-rootpt-resize
            rm -f files/etc/uci-defaults/80-rootfs-resize
            rm -f files/etc/sysupgrade.conf
            ;;
        *)
            log "INFO" "system type: ${TYPE}"
            ;;
    esac
}

# Setup branch-specific configurations
setup_branch_config() {
    local branch_major=$(echo "${BRANCH}" | cut -d'.' -f1)
    case "$branch_major" in
        "24")
            log "INFO" "Configuring for branch 24.x"
            ;;
        "23")
            log "INFO" "Configuring for branch 23.x"
            ;;
        *)
            log "INFO" "Unknown branch version: ${BRANCH}"
            ;;
    esac
}

# Main execution
main() {
    init_environment
    setup_base_config
    handle_amlogic_files
    setup_branch_config
    log "SUCCESS" "All custom configuration setup completed!"
}

# Execute main function
main