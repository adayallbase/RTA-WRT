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

# Define repositories with proper quoting and error handling
declare -A REPOS
initialize_repositories() {
    local version="24.10"
    REPOS=(
        ["KIDDIN9"]="https://dl.openwrt.ai/releases/${version}/packages/${ARCH_3}/kiddin9"
        ["IMMORTALWRT"]="https://downloads.immortalwrt.org/releases/packages-${version}/${ARCH_3}"
        ["OPENWRT"]="https://downloads.openwrt.org/releases/packages-${version}/${ARCH_3}"
        ["GSPOTX2F"]="https://github.com/gSpotx2f/packages-openwrt/raw/refs/heads/master/current"
        ["FANTASTIC"]="https://fantastic-packages.github.io/packages/releases/${VEROP}/packages/mipsel_24kc"
    )
}

# Define package categories with improved structure
declare_packages() {
    packages_custom=(
        # OPENWRT packages
        "modemmanager-rpcd_|${REPOS[OPENWRT]}/packages"
        "luci-proto-modemmanager_|${REPOS[OPENWRT]}/luci"
        "libqmi_|${REPOS[OPENWRT]}/packages"
        "libmbim_|${REPOS[OPENWRT]}/packages"
        "modemmanager_|${REPOS[OPENWRT]}/packages"

        # KIDDIN9 packages
        "luci-app-diskman_|${REPOS[KIDDIN9]}"
        "xmm-modem_|${REPOS[KIDDIN9]}"

        # IMMORTALWRT packages
        "luci-app-openclash_|${REPOS[IMMORTALWRT]}/luci"

        # GSPOTX2F packages
        "luci-app-internet-detector_|${REPOS[GSPOTX2F]}"
        "internet-detector_|${REPOS[GSPOTX2F]}"
        "internet-detector-mod-modem-restart_|${REPOS[GSPOTX2F]}"
        "luci-app-temp-status_|${REPOS[GSPOTX2F]}"
    )

    if [[ "${TYPE}" == "OPHUB" ]]; then
        log "INFO" "Adding Amlogic-specific packages..."
        packages_custom+=(
            "luci-app-amlogic_|https://api.github.com/repos/ophub/luci-app-amlogic/releases/latest"
        )
    fi
}

# Main execution function
main() {
    local rc=0

    initialize_repositories
    declare_packages

    # Download Custom packages
    log "INFO" "Downloading Custom packages..."
    if ! download_packages packages_custom; then
        rc=1
    fi

    if [[ $rc -eq 0 ]]; then
        log "SUCCESS" "All packages downloaded and verified successfully"
    else
        error_msg "Some packages failed to download or verify"
    fi

    return $rc
}

# Run main function if script is not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi