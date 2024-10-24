#!/bin/bash
set -e
if [ "$(id -u)" -eq 0 ]; then
    umask 0077
else
    umask 0022
fi

#This version should not be changed, it is the version used at genesis time
ZENROCK_GENESIS_VERSION='4.7.1'

COSMOVISOR_VERSION='1.6.0'
SIDECAR_VERSION='1.2.3'


DIR="$(cd "$(dirname "$0")" && pwd)"

service_exists() {
    local service_name="$1"
    if [ "$(id -u)" -eq 0 ]; then
       systemctl list-units --type=service | grep -q "$service_name"
    else
       systemctl --user list-units --type=service | grep -q "$service_name"
    fi
}

spinner(){
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

keygen_exec_check() {
  set +e
  $DIR/utils/keygen/ecdsa/ecdsa --password test >/dev/null 2>&1
  local status=$?
  set -e
  if ! [ $status -eq 0 ]; then
    echo "Need to reconfigure keygen binaries, please wait..."
    cd $DIR/utils/keygen/ecdsa
      go mod tidy >/dev/null 2>&1; go build >/dev/null 2>&1 &
      spinner 
    cd $DIR/utils/keygen/bls
      go mod tidy >/dev/null 2>&1; go build >/dev/null 2>&1 &
      spinner 
  fi
}

usage() {
    echo "Usage: $0"
    echo "Select an option:"
    echo "1 - Initialize service"
    echo "2 - Update service"
    echo "3 - Cleanup service setup"
    exit 1
}


gecho() {
  echo -e "\033[32m$1\033[0m"
}

recho() {
  echo -e "\033[31m$1\033[0m"
}

wait_for_input() {
    while true; do
        read -e -p "Type 'yes' to proceed, once you confirm that the Address has been funded with tokens: " user_input
        if [[ "$user_input" == "yes" ]]; then
            echo "Proceeding to the next step..."
            break
        else
            recho "Invalid input. Please try again."
            service_cleanup
            exit 1

        fi
    done
}


read -e -p "Enter the FULL path where you want to create the Application directory or where it exists: " user_path
    declare -g user_path

service_cleanup() {
    read -e -p "!!! THIS WILL REMOVE THE VALIDATOR AND SIDECAR SERVICES, PLEASE CONFIRM (yes/no): " confirm_removal
    if [[ "$confirm_removal" == "yes" ]]; then
        if [ "$(id -u)" -eq 0 ]; then 
            if [ -f "/etc/systemd/system/validator-sidecar.service" ]; then
                systemctl stop validator-sidecar.service
                systemctl disable validator-sidecar.service
                rm -f /etc/systemd/system/validator-sidecar.service
            fi
            if [ -f "/etc/systemd/system/cosmovisor.service" ]; then
                systemctl stop cosmovisor.service
                systemctl disable cosmovisor.service
                rm -f /etc/systemd/system/cosmovisor.service
            fi
            systemctl daemon-reload
            rm -rf "$user_path"
            echo "Service removal completed"
        else  
            if [ -f "$HOME/.config/systemd/user/validator-sidecar.service" ]; then
                systemctl --user stop validator-sidecar.service
                systemctl --user disable validator-sidecar.service
                rm -f "$HOME/.config/systemd/user/validator-sidecar.service"
            fi
            if [ -f "$HOME/.config/systemd/user/cosmovisor.service" ]; then
                systemctl --user stop cosmovisor.service
                systemctl --user disable cosmovisor.service
                rm -f "$HOME/.config/systemd/user/cosmovisor.service"
            fi
            systemctl --user daemon-reload
            rm -rf "$user_path"
            echo "Service removal completed"
        fi
    else
        exit 0
    fi
}


start_service() {
    SERVICE=$1
    if [ "$(id -u)" -eq 0 ]; then
       systemctl daemon-reload
       systemctl start "$SERVICE.service"
    else
       systemctl --user daemon-reload
       systemctl --user start "$SERVICE.service"
    fi 
    echo "Waiting for $SERVICE service initialization"
    sleep 10 &
    spinner 

    if [ "$(id -u)" -eq 0 ]; then
        if  systemctl status "$SERVICE.service" > /dev/null 2>error.log; then
            gecho "$SERVICE has been started successfully."
        else
            echo "Error: Initialization failed."
            cat error.log
            exit 1
        fi
    else
        if  systemctl --user status "$SERVICE.service" > /dev/null 2>error.log; then
            gecho "$SERVICE has been started successfully."
        else
            echo "Error: Initialization failed."
            cat error.log
            exit 1
        fi
    fi
}


paths_init() {
  read -e -p "Enter your Zenrock address: " zenrock_address
    declare -g zenrock_address
  read -e -p "Enter name for your validator: " validator_name
    declare -g validator_name
  read -e -p "Enter your mainnet eth endpoint (with http/https) : " mainnet_input
    declare -g mainnet_input
  read -e -p "Enter your holesky eth endpoint (with http/https) : " testnet_input
    declare -g testnet_input
  read -e -p "Enter your holesky eth WS endpoint ( with wss ) : " testnet_ws_input
    declare -g testnet_input

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
  if [ "$(id -u)" -eq 0 ]; then
    eval mkdir -p "$HOME/.config/systemd/user"
  fi
}


##### Service setup ####
service_setup() {

cp $DIR/configs/eigen_operator_config.yaml "$user_path/sidecar/"
cp $DIR/configs/config.yaml "$user_path/sidecar/"

echo "Downloading latest zenrockd release"
if ! [ -f "$user_path/cosmovisor/genesis/bin/zenrockd" ]; then
    curl -s "https://releases.gardia.zenrocklabs.io/zenrockd-$ZENROCK_GENESIS_VERSION" \
      -o "$user_path/cosmovisor/genesis/bin/zenrockd"
    chmod +x "$user_path/cosmovisor/genesis/bin/zenrockd"
    gecho "Zenrockd setup completed in : $user_path/cosmovisor/genesis/bin/zenrockd"
    $user_path/cosmovisor/genesis/bin/zenrockd --home $user_path/cosmovisor/config init $validator_name > /dev/null 2>error.log

      if [ $? -eq 0 ]; then
        gecho "Cosmovisor initialization completed successfully."
      else
        echo "Error: Initialization failed."
        cat error.log
        service_cleanup
        exit 1
     fi
fi

echo "Downloading latest validator sidecar release"
if ! [ -f "$user_path/sidecar/bin/validator_sidecar" ]; then
    curl -s "https://releases.gardia.zenrocklabs.io/validator_sidecar-$SIDECAR_VERSION" \
      -o "$user_path/sidecar/bin/validator_sidecar"
    chmod +x "$user_path/sidecar/bin/validator_sidecar"
    gecho "Validator sidecar setup completed in : $user_path/sidecar/bin/validator_sidecar"
fi

echo "Downloading latest cosmovisor release"

if ! [ -f "$user_path/cosmovisor/bin/cosmovisor" ]; then
  curl -L -s https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv$COSMOVISOR_VERSION/cosmovisor-v$COSMOVISOR_VERSION-linux-amd64.tar.gz | tar -C $user_path/cosmovisor/bin/ -xz
  gecho "Cosmovisor setup completed in: $user_path/cosmovisor/bin/cosmovisor"
fi
}


#### Service Update ####

binary_update() {

   if [ -f "$user_path/sidecar/bin/validator_sidecar" ]; then
    read -e -p "Do you want to update the Validator sidecar service? (yes/no): " confirm

    if [[ "$confirm" == "yes" ]]; then
        if [ "$(id -u)" -eq 0 ]; then
          systemctl stop cosmovisor.service
          systemctl stop validator-sidecar.service
        else
          systemctl --user stop cosmovisor.service
          systemctl --user stop validator-sidecar.service
        fi
        rm -f "$user_path/sidecar/bin/validator_sidecar"
        curl -s "https://releases.gardia.zenrocklabs.io/validator_sidecar-$SIDECAR_VERSION" \
          -o "$user_path/sidecar/bin/validator_sidecar"
        chmod +x "$user_path/sidecar/bin/validator_sidecar"
        gecho "Service Validator sidecar updated to version $SIDECAR_VERSION"
        start_service "validator-sidecar"
        start_service "cosmovisor"
    else
        echo "No changes made."
    fi
  fi
   

  if [ -f "$user_path/cosmovisor/bin/cosmovisor" ]; then
    read -e -p "Do you want to update the Cosmovisor service? (yes/no): " confirm

    if [[ "$confirm" == "yes" ]]; then
        if [ "$(id -u)" -eq 0 ]; then
          systemctl stop cosmovisor.service
          systemctl stop validator-sidecar.service
        else
          systemctl --user stop cosmovisor.service
          systemctl --user stop validator-sidecar.service
        fi
        rm -f "$user_path/cosmovisor/bin/*"
        curl -L -s https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv$COSMOVISOR_VERSION/cosmovisor-v$COSMOVISOR_VERSION-linux-amd64.tar.gz | tar -C $user_path/cosmovisor/bin/ -xz
        gecho "Service Cosmovisor updated to version $COSMOVISOR_VERSION"
        start_service "validator-sidecar"
        start_service "cosmovisor"
    else
        echo "No changes made."
    fi  
  fi
}

keys_setup() {

# ECDSA key creation
read -e -p "Enter password for the ECDSA key: " ecdsa_pass
  declare -g ecdsa_pass

  ecdsa_creation=$($DIR/utils/keygen/ecdsa/ecdsa --password $ecdsa_pass --output-file $user_path/sidecar/keys/ecdsa.key.json)
  ecdsa_address=$(echo "$ecdsa_creation" | grep "Public address" | cut -d: -f2)
  declare -g ecdsa_address

  echo "Public address: $ecdsa_address"
  echo "Please fund this address before proceeding further"
  wait_for_input

# BLS key creation
read -e -p "Enter password for the BLS key: " bls_pass

  $DIR/utils/keygen/bls/bls --password $bls_pass --output-file $user_path/sidecar/keys/bls.key.json
}


#### Sidecar Service setup ####
sidecar_service_setup() {
zenvelop_address=$($DIR/utils/val_addr/val_addr $zenrock_address)
  sed -i "s|EIGEN_OPERATOR_CONFIG|$user_path/sidecar/eigen_operator_config.yaml|g" $user_path/sidecar/config.yaml
  sed -i "s|TESTNET_HOLESKY_ENDPOINT|$testnet_input|g" $user_path/sidecar/config.yaml
  sed -i "s|MAINNET_ENDPOINT|$mainnet_input|g" $user_path/sidecar/config.yaml
  sed -i "s|OPERATOR_VALIDATOR_ADDRESS_TBD|$zenvelop_address|g" $user_path/sidecar/eigen_operator_config.yaml
  sed -i "s|OPERATOR_ADDRESS_TBU|$ecdsa_address|g" $user_path/sidecar/eigen_operator_config.yaml
  sed -i "s|ETH_RPC_URL|$testnet_input|g" $user_path/sidecar/eigen_operator_config.yaml
  sed -i "s|ETH_WS_URL|$testnet_ws_input|g" $user_path/sidecar/eigen_operator_config.yaml
  sed -i "s|ECDSA_KEY_PATH|$user_path/sidecar/keys/ecdsa.key.json|g" $user_path/sidecar/eigen_operator_config.yaml
  sed -i "s|BLS_KEY_PATH|$user_path/sidecar/keys/bls.key.json|g" $user_path/sidecar/eigen_operator_config.yaml

  echo "Giving some time for the funds to reflect in the address balance"
  sleep 10 &
  spinner 

if [ "$(id -u)" -eq 0 ]; then
    config_path="/etc/systemd/system/validator-sidecar.service"
else
    config_path="$HOME/.config/systemd/user/validator-sidecar.service"
fi

tee "$config_path" > /dev/null <<EOL
[Unit]
Description=Validator sidecar service

[Service]
Type=simple
Environment="DAEMON_RESTART_DELAY=5s"
Environment="DAEMON_SHUTDOWN_GRACE=5s"
Environment="UNSAFE_SKIP_BACKUP=false"

# Replace with your environment variables as needed
Environment="OPERATOR_BLS_KEY_PASSWORD=$bls_pass"
Environment="OPERATOR_ECDSA_KEY_PASSWORD=$ecdsa_pass"
Environment="SIDECAR_CONFIG_FILE=$user_path/sidecar/config.yaml"
ExecStart=$user_path/sidecar/bin/validator_sidecar

[Install]
WantedBy=multi-user.target
EOL
if [ "$(id -u)" -eq 0 ]; then
    systemctl enable validator-sidecar.service
else
    systemctl --user enable validator-sidecar.service
fi
start_service "validator-sidecar"
}

#### Cosmovisor ####

cosmovisor_service_setup() {

cp -r $user_path/cosmovisor/config/config/node_key.json $user_path/config/
cp -r $user_path/cosmovisor/config/config/priv_validator_key.json $user_path/config/
cp -r $DIR/configs/app.toml $user_path/config/
cp -r $DIR/configs/client.toml $user_path/config/
cp -r $DIR/configs/config.toml $user_path/config/
mv $user_path/cosmovisor/config/data $user_path
curl -s https://rpc.gardia.zenrocklabs.io/genesis | jq .result.genesis > $user_path/config/genesis.json

sed -i "s|MY_VALIDATOR|$validator_name|g" $user_path/config/config.toml

if [ "$(id -u)" -eq 0 ]; then
    config_path="/etc/systemd/system/cosmovisor.service"
else
    config_path="$HOME/.config/systemd/user/cosmovisor.service"
fi

tee "$config_path" > /dev/null <<EOL
[Unit]
StartLimitBurst=2
StartLimitInterval=11  
Description=Cosmovisor service

[Service]
Type=simple
Environment="COSMOVISOR_COLOR_LOGS=true"
Environment="COSMOVISOR_DISABLE_LOGS=false"
Environment="COSMOVISOR_DISABLE_RECASE=false"
Environment="COSMOVISOR_TIMEFORMAT_LOGS=kitchen"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_DOWNLOAD_MUST_HAVE_CHECKSUM=false"
Environment="COSMOVISOR_CUSTOM_PREUPGRADE="
Environment="DAEMON_DATA_BACKUP_DIR="
Environment="DAEMON_HOME=$user_path"
Environment="DAEMON_NAME=zenrockd"
Environment="DAEMON_POLL_INTERVAL=5s"
Environment="DAEMON_PREUPGRADE_MAX_RETRIES=0"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_RESTART_DELAY=5s"
Environment="DAEMON_SHUTDOWN_GRACE=5s"
Environment="UNSAFE_SKIP_BACKUP=false"


ExecStart=$user_path/cosmovisor/bin/cosmovisor run start --home $user_path
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOL

if [ "$(id -u)" -eq 0 ]; then
    systemctl enable cosmovisor.service
else
    systemctl --user enable cosmovisor.service
fi
start_service "cosmovisor"
}


service_check() {
  if service_exists "cosmovisor" || service_exists "validator-sidecar"; then
    recho "One or more of the required services exists, aborting the initial setup"
    exit 1
  fi
}

clear
echo "Select an option:"
echo "1 - Initialize service"
echo "2 - Update service"
echo "3 - Cleanup service setup"
read -e -p "Enter your choice (1/2/3): " choice

case "$choice" in
    1)
        service_check
        keygen_exec_check
        paths_init
        service_setup
        keys_setup
        sidecar_service_setup
        cosmovisor_service_setup
        ;;
    2)
        binary_update
        ;;
    3)
        service_cleanup
        ;;
    *)
        usage
        ;;
esac
