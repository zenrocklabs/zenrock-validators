#!/bin/bash
set -e

#This version should not be changed, it is the version used at genesis time
ZENROCK_GENESIS_VERSION='4.7.1'

COSMOVISOR_VERSION='1.6.0'
SIDECAR_VERSION='5.3.2'


DIR="$(cd "$(dirname "$0")" && pwd)"
gecho() {
  echo -e "\033[32m$1\033[0m"
}



read -e -p "Enter the FULL path where you want to create the Application directory or where it exists: " user_path
    declare -g user_path

paths_init() {
read -e -p "Enter name for your validator: " validator_name
    declare -g validator_name
# Check if the path already exists
if [ -d "$user_path" ]; then
  echo "The path already exists."
else
  # Create the directory path
  eval mkdir -p "$user_path"
  gecho "Directory created successfully at: $user_path"
fi

# Create the subdirectories within the main directory
  eval mkdir -p "$user_path/config"
  eval mkdir -p "$user_path/cosmovisor"
  eval mkdir -p "$user_path/cosmovisor/bin"
  eval mkdir -p "$user_path/cosmovisor/genesis/bin"
  eval mkdir -p "$user_path/cosmovisor/genesis/upgrades"
  eval mkdir -p "$user_path/sidecar/bin"
  eval mkdir -p "$user_path/sidecar/keys"
}


##### Service setup ####
service_setup() {

cp $DIR/configs_testnet/eigen_operator_config.yaml "$user_path/sidecar/"
cp $DIR/configs_testnet/config.yaml "$user_path/sidecar/"

echo "Downloading latest zenrockd release"
if ! [ -f "$user_path/cosmovisor/genesis/bin/zenrockd" ]; then
    curl -s "https://releases.gardia.zenrocklabs.io/zenrockd-$ZENROCK_GENESIS_VERSION" \
      -o "$user_path/cosmovisor/genesis/bin/zenrockd"
    chmod +x "$user_path/cosmovisor/genesis/bin/zenrockd"
    gecho "Zenrockd setup completed in : $user_path/cosmovisor/genesis/bin/zenrockd"
    $user_path/cosmovisor/genesis/bin/zenrockd --home $user_path/cosmovisor/config init $validator_name >/dev/null 2>&1
fi

echo "Downloading latest validator sidecar release"
if ! [ -f "$user_path/sidecar/bin/validator_sidecar" ]; then
    curl -Ls "https://github.com/Zenrock-Foundation/zrchain/releases/download/v$SIDECAR_VERSION/validator_sidecar" \
      -o "$user_path/sidecar/bin/validator_sidecar"
    chmod +x "$user_path/sidecar/bin/validator_sidecar"
    gecho "Validator sidecar setup completed in : $user_path/sidecar/bin/validator_sidecar"
fi

echo "Downloading latest cosmovisor release"

if ! [ -f "$user_path/cosmovisor/bin/cosmovisor" ]; then
  curl -L -s https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv$COSMOVISOR_VERSION/cosmovisor-v$COSMOVISOR_VERSION-linux-amd64.tar.gz | tar -C $user_path/cosmovisor/bin/ -xz
  gecho "Cosmovisor setup completed in: $user_path/cosmovisor/bin/cosmovisor"
fi

cp -r $user_path/cosmovisor/config/config/node_key.json $user_path/config/
cp -r $user_path/cosmovisor/config/config/priv_validator_key.json $user_path/config/
cp -r $DIR/configs_testnet/app.toml $user_path/config/
cp -r $DIR/configs_testnet/client.toml $user_path/config/
cp -r $DIR/configs_testnet/config.toml $user_path/config/
mv $user_path/cosmovisor/config/data $user_path
curl -s https://rpc.gardia.zenrocklabs.io/genesis | jq .result.genesis > $user_path/config/genesis.json
sed -i "s|MY_VALIDATOR|$validator_name|g" $user_path/config/config.toml
sed -i "s|EIGEN_OPERATOR_CONFIG|$user_path/sidecar/eigen_operator_config.yaml|g" $user_path/sidecar/config.yaml
}

paths_init
service_setup
