#!/bin/bash
set -ex
# Check if MONIKER is set
if [ -z "$MONIKER" ]; then
  echo "MONIKER environment variable is not set. Exiting."
  exit 1
fi

mkdir -p "/root-data/config"
mkdir -p "/root-data/cosmovisor"
mkdir -p "/root-data/cosmovisor/bin"
mkdir -p "/root-data/cosmovisor/genesis/bin"
mkdir -p "/root-data/cosmovisor/genesis/upgrades"



#Zenrockd setup

curl -Ls https://github.com/zenrocklabs/zrchain/releases/download/v$ZENROCKD_GENESIS_VERSION/zenrockd -o /root-data/cosmovisor/genesis/bin/zenrockd
chmod +x /root-data/cosmovisor/genesis/bin/zenrockd

#Cosmovisor setup

curl -L -s https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv$COSMOVISOR_VERSION/cosmovisor-v$COSMOVISOR_VERSION-linux-amd64.tar.gz | tar -C /root-data/cosmovisor/bin/ -xz

#Genesis

curl -s https://rpc.gardia.zenrocklabs.io/genesis | jq .result.genesis > /root-data/config/genesis.json

# Run the initialization command with the provided MONIKER
/root-data/cosmovisor/genesis/bin/zenrockd --home /tmp/cosmovisor init $MONIKER

# Start the cosmovisor process

cp /tmp/cosmovisor/config/node_key.json /root-data/config/node_key.json
cp /tmp/cosmovisor/config/priv_validator_key.json /root-data/config/priv_validator_key.json
mv /tmp/cosmovisor/data /root-data/
rm -rf /tmp/cosmovisor
