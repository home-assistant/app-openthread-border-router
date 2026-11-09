#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configure OTBR depending on app settings
# ==============================================================================

# Run an ot-ctl command quietly; log its output only if it fails
function otctl() {
    local output

    if output="$(ot-ctl "$@" 2>&1)" && [[ "${output}" == *Done ]]; then
        return 0
    fi

    bashio::log.warning "ot-ctl $* failed: ${output}"
    return 1
}

otctl trel enable

if bashio::config.true 'nat64'; then
    bashio::log.info "Enabling NAT64."
    otctl nat64 enable
    otctl dns server upstream enable
fi

mdns_localhostname="$(hostname)-otbr"
bashio::log.info "Setting OpenThread mDNS local hostname to ${mdns_localhostname}."
otctl mdns localhostname "${mdns_localhostname}"
otctl mdns enable

# To avoid asymmetric link quality the TX power from the controller should not
# exceed that of what other Thread routers devices typically use.
otctl txpower 6
