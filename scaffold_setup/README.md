
# Manual setup


## Scaffold setup
Execute either :

   1. init_mainnet.sh -> for setting up mainnet validator config/structure
   2. init_testnet.sh -> for setting up testnet validator config/structure

There will be only two inputs you need to include:


    1. The path where you wan to setup the validator
    2. Your validator ( Moniker) name

Note: sudo is used only if you're running the script with a user different from the root user.”  e.g.

```
$ sudo bash init.sh
Enter the FULL path where you want to create the Application directory or where it exists: /mnt/validator/test
Enter name for your validator: my-validator
Directory created successfully at: /mnt/validator/test
Downloading latest zenrockd release
Zenrockd setup completed in : /mnt/validator/test/cosmovisor/genesis/bin/zenrockd
Downloading latest validator sidecar release
Validator sidecar setup completed in : /mnt/validator/test/sidecar/bin/validator_sidecar
Downloading latest cosmovisor release
Cosmovisor setup completed in: /mnt/validator/test/cosmovisor/bin/cosmovisor
```

### ECDSA key 

The ECDSA key is used by the eigen operator.

```
cd utils/keygen/ecdsa
sudo ./ecdsa --password mypassword
```

you can also add the --ouput-path argument to set the key in specific directory e.g

```
sudo ./ecdsa --password testpassword --output-file /mnt/validator/zenrock/sidecar/keys/ecdsa.key.json
```

Once the ECDSA key is generated, fund it with tokens on the Holesky network.


### BLS key

The BLS key is used by the eigen operator.

```
cd utils/keygen/bls
./bls --password mypassword
```

Same as for the ECDSA you can use the --output-file argument here as well

```
sudo ./bls --password testpassword --output-file /mnt/validator/zenrock/sidecar/keys/bls.key.json
```

### Zenrock account setup

Create a Zenrock account ( if you don't have one already ) and note the address generated e.g.

```
sudo /mnt/validator/test/cosmovisor/genesis/bin/zenrockd keys add my-validator
```

Get the zenvaloper address

```
cd utils/val_addr
./val_addr <zenrock address from the previous step>
```

### Sidecar config setup

Update the sidecar setup files located in your Application directory:

```
<APP_DIR generated by init script>/sidecar/config.yaml
<APP_DIR generated by init script>/sidecar/eigen_operator_config.yaml
```

#### config.yaml
Update

```
TESTNET_HOLESKY_ENDPOINT - your holesky ETH endpoint
MAINNET_ENDPOINT - your mainnet ETH endpoint
```

#### eigen_operator_config.yaml

Update

Testnet
```
OPERATOR_ADDRESS - the address generated by the ECDSA key 0x......
OPERATOR_VALIDATOR_ADDRESS - zenvaloper address
ETH_RPC_URL - your HOLESKY RPC endpoint ( should be the same as TESTNET_HOLESKY_ENDPOINT)
ETH_WS_URL - your HOLESKY WS endpoint ( should start with wss://)
ECDSA_KEY_PATH - path to you ECDSA key 
BLS_KEY_PATH - path to your BLS key
```

Mainnet
```
OPERATOR_ADDRESS - the address generated by the ECDSA key 0x......
OPERATOR_VALIDATOR_ADDRESS - zenvaloper address
ETH_RPC_URL - your MAINNET RPC endpoint ( should be the same as MAINNET__ENDPOINT)
ETH_WS_URL - your MAINNET WS endpoint ( should start with wss://)
ECDSA_KEY_PATH - path to you ECDSA key 
BLS_KEY_PATH - path to your BLS key
```
### Systemd service

Examples are provided for the systemd service; they can be further adjusted per your needs. Make sure to update the corresponding variables.

validator-sidecar

```
[Unit]
Description=Validator sidecar service

[Service]
Type=simple
Environment="DAEMON_RESTART_DELAY=5s"
Environment="DAEMON_SHUTDOWN_GRACE=5s"
Environment="UNSAFE_SKIP_BACKUP=false"

# Replace with your environment variables as needed
Environment="OPERATOR_BLS_KEY_PASSWORD=<password for BLS key>"
Environment="OPERATOR_ECDSA_KEY_PASSWORD=<password for ECDSA key>"
Environment="SIDECAR_CONFIG_FILE=<APP_DIR generated by init script>/sidecar/config.yaml"
ExecStart=<APP_DIR generated by init script>sidecar/bin/validator_sidecar 
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

cosmovisor

```
[Unit]
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
Environment="DAEMON_HOME=<APP_DIR generated by init script>"
Environment="DAEMON_NAME=zenrockd"
Environment="DAEMON_POLL_INTERVAL=5s"
Environment="DAEMON_PREUPGRADE_MAX_RETRIES=0"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_RESTART_DELAY=5s"
Environment="DAEMON_SHUTDOWN_GRACE=5s"
Environment="UNSAFE_SKIP_BACKUP=false"


ExecStart=<APP_DIR generated by init script>/cosmovisor/bin/cosmovisor run start --home <APP_DIR generated by init script>
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Once the setup is completed, you just need to follow the same steps as in the Helmchart setup which are:

    Seting up the validator-info.json configuration file
    Submit the validator creation transaction

FYI: Make sure that the validator is fully synched up before submitting the validator creation transaction as otherwise your node might get jailed.