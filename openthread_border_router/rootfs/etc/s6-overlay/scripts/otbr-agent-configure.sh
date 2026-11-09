#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configure OTBR depending on app settings
# ==============================================================================

# Run an ot-ctl command quietly, only logging its output on failure.
# A non-zero exit (e.g. otbr-agent not reachable) is fatal via errexit.
# ot-ctl exits 0 even when the CLI reports "Error <n>: ...", such CLI errors
# are detected by the missing final "Done" line and are only logged.
function otctl() {
    local output

    if ! output="$(ot-ctl "$@" 2>&1)"; then
        bashio::log.error "ot-ctl $* failed: ${output}"
        return 1
    fi

    if [[ "${output//[[:space:]]/}" != *Done ]]; then
        bashio::log.warning "ot-ctl $* failed: ${output}"
    fi
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
