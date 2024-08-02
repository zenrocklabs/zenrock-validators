#!/usr/bin/env sh

# Gardia variables
GARDIA_PEERS="6ef43e8d5be8d0499b6c57eb15d3dd6dee809c1e@sentry-1.gardia.zenrocklabs.io:26656,1dfbd854bab6ca95be652e8db078ab7a069eae6f@sentry-2.gardia.zenrocklabs.io:36656"
GARDIA_RPC_HOST="https://rpc.gardia.zenrocklabs.io"
GARDIA_CHAIN="gardia-1"
ZENROCKD_RELEASES_URL="https://releases.gardia.zenrocklabs.io"
ZENROCKD_VERSION="1.28.2"
ZENROCKD_BINARY_URL="${ZENROCKD_RELEASES_URL}/zenrockd-${ZENROCKD_VERSION}"
ZENROCK_HOME=$(pwd)
VALIDATOR_MONIKER="validator-x"
SNAPSHOT_URL="https://releases.gardia.zenrocklabs.io/zenrock-latest.tar.gz"


fetch_genesis() {
    curl -s ${GARDIA_RPC_HOST}/genesis | jq .result.genesis > "${ZENROCK_HOME}"/config/genesis.json
}

fetch_zenrockd() {
    curl -s -o zenrockd ${ZENROCKD_BINARY_URL}
    chmod +x zenrockd
}

set_persistent_peers() {
    sed -i "s|persistent_peers = \"\"|persistent_peers = \"${GARDIA_PEERS}\"|" "${ZENROCK_HOME}"/config/config.toml
}

main() {
    fetch_zenrockd
    ./zenrockd init "${VALIDATOR_MONIKER}" \
        --home "${ZENROCK_HOME}" \
        --chain-id "${GARDIA_CHAIN}" \
        --download-snapshot "${SNAPSHOT_URL}" 2> /dev/null
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Failed to initialize zenrockd"
        exit 1
    fi
    fetch_genesis
    set_persistent_peers
}

main
