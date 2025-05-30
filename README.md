# Zenrock Gardia Validator Node Setup


This guide explains how to set up a validator node on the Zenrock Gardia blockchain
using Kubernetes and Helm.

Note: Funds for the validators would have to be requested from the Zenrock team. Do not use the faucet for it!

## Prerequisites

### Kubernetes Cluster

Ensure you have a Kubernetes cluster ready for deploying the Helm chart.

### Add Helm Chart Repository

Add the Zenrock Helm chart repository by running:

``` sh
helm repo add zenrock https://zenrocklabs.github.io/zenrock-validators/
```

### Generation of keys
We provide scripts in the utils folder for generating the required keys for the validator.
### Compiling ECDSA and BLS Based on CPU Architecture
#### To compile ECDSA and BLS for the specific CPU architecture, follow these steps:
### For ECDSA:

```bash
cd utils/keygen/ecdsa
go build -o ecdsa2 main.go

```
###  For BLS:
```bash
cd utils/keygen/bls
go build -o bls main.go
```
#### Checking Architecture (ARM vs AMD)
Before building, verify the architecture of the generated binary (ARM or AMD) using the following commands
```
cd utils/keygen/ecdsa
file ecdsa
cd utils/keygen/bls
file bls
```
* Note: This will help ensure that you are using the correct binary for your system's architecture.
### ECDSA key
The ECDSA key is used by the eigen operator.

``` sh
cd utils/keygen/ecdsa
./ecdsa --password mypassword
```

:


Once the ECDSA key is generated, fund it with tokens on the Holesky network.

### BLS key
The BLS key is used by the eigen operator.

``` sh
cd utils/keygen/bls
./bls --password mypassword
```

### validator keys
These are the CometBFT keys used by the validator.

``` sh
./zenrockd --home /tmp/my-validator init my-validator
cat /tmp/my-validator/config/node_key.json
cat /tmp/my-validator/config/priv_validator_key.json
```


### Write keys in kubernetes secrets
The keys need to be available in Kubernetes. Below is an example of how to store them in Kubernetes Secrets,
which will be referenced in the Helm chart.
It's recommended to encrypt sensitive secrets using tools like SOPS.

1. CometBFT keys

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: validator-cometbft-keys
stringData:
  priv_validator_key.json: |
    # Replace this content with the key generated in the validator keys step.
  node_key.json: |
    # Replace this content with the key generated in the validator keys step.

```

2. Eigen operator keys

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: validator-eigen-keys
stringData:
  OPERATOR_ECDSA_KEY_PASSWORD: "mypassword"
  OPERATOR_BLS_KEY_PASSWORD: "mypassword"
  ecdsa.key.json: |
    # Replace this content with the key generated in the ECDSA key step.
  bls.key.json: |
    # Replace this content with the key generated in the BLS key step.

```
3. (Optional) sidecar config


# Testnet

``` yaml
apiVersion: v1
kind: Secret
metadata:
    name: validator-sidecar-config
stringData:
    config.yaml: |  
        enabled: true
        grpc_port: 9191
        zrchain_rpc: "localhost:9790"
        state_file: "cache.json"
        operator_config: "/root-data/sidecar/eigen_operator_config.yaml"
        network: "testnet"
        eth_rpc:
            local: "http://127.0.0.1:8545"
            testnet: "https://rpc-endpoint-holesky-here"  # Replace this endpoint with a valid one
            mainnet: "https://rpc-endpoint-mainnet-here"  # Replace this endpoint with a valid one
        # Contract addresses + more are now defined in shared/types.go
        solana_rpc:
            testnet: "https://api.testnet.solana.com"
            mainnet: "https://api.mainnet-beta.solana.com/"
        neutrino:
          path: "/root-data/neutrino"
        proxy_rpc:
          url: #To be provided by the Zenrock team
          user: #To be provided by the Zenrock team
          password: #To be provided by the Zenrock team
```

# Mainnet

``` yaml
apiVersion: v1
kind: Secret
metadata:
    name: validator-sidecar-config
stringData:
    config.yaml: |  
        enabled: true
        grpc_port: 9191
        zrchain_rpc: "localhost:9790"
        state_file: "cache.json"
        operator_config: "/root-data/sidecar/eigen_operator_config.yaml"
        network: "mainnet"
        eth_rpc:
          # local: "http://127.0.0.1:8545"
          testnet: "https://rpc-endpoint-holesky-here"  # Replace this endpoint with a valid one
          mainnet: "https://rpc-endpoint-mainnet-here"  # Replace this endpoint with a valid one
        solana_rpc:
          testnet: "https://api.testnet.solana.com"
          mainnet: "https://api.mainnet-beta.solana.com/"
        neutrino:
          path: "/root-data/neutrino"
```

This configuration can be set in the Helm chart values, but if you want to encrypt any sensitive data such as
RPC endpoint tokens, you can use this secret.


### Zenrock account
The binary releases can be downloaded from here:

https://github.com/Zenrock-Foundation/zrchain/releases

e.g. with latest release ( of the time of writing the documentation ) you'd download:

``` sh
sudo curl -Ls https://github.com/Zenrock-Foundation/zrchain/releases/download/v5.5.0/zenrockd -o zenrockd
```

Create a zenrock account and note the address generated.

``` sh
./zenrockd keys add my-validator
```

### Get the zenvaloper address
``` sh
cd utils/val_addr
./val_addr <zenrock address from the previous step>
```

### Fund the Validator's account

Transfer tokens to the validator's address. As per the note, contact the Zenrock team, in order to request funds.

### Create the validator

Create a file named `validator-info.json` with the following content, replacing the placeholder values:

``` json
{
    "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"PUB_KEY"},
    "amount": "1000000000urock",
    "moniker": "my-validator",
    "identity": "optional identity signature (ex. UPort or Keybase)",
    "website": "validator's (optional) website",
    "security": "validator's (optional) security contact email",
    "details": "validator's (optional) details",
    "commission-rate": "0.1",
    "commission-max-rate": "0.2",
    "commission-max-change-rate": "0.01",
    "min-self-delegation": "1"
}

```

Replace "PUB_KEY" with your validator's public key, which can be obtained running the following command:

``` sh
./zenrockd --home /tmp/my-validator tendermint show-validator
```


Submit the validator creation transaction:


# Mainnet

``` sh
./zenrockd tx validation create-validator [path/to/validator-info.json] \
    --node https://rpc.diamond.zenrocklabs.io \
    --fees 500000urock \
    --from my-validator \
    --chain-id diamond-1
```

# Testnet

``` sh
./zenrockd tx validation create-validator [path/to/validator-info.json] \
    --node https://rpc.gardia.zenrocklabs.io \
    --fees 500000urock \
    --from my-validator \
    --chain-id gardia-7
```


## Helm chart values

Create a custom values file for your Helm chart configuration:


# Mainnet

``` yaml
nameOverride: my-validator
fullnameOverride: my-validator

images:
  cosmovisor: alpine:3.20.2
  init_zenrock: alpine:3.20.2
  sidecar: alpine:3.20.2

cosmovisor:
  version: v1.6.0

sidecar:
  releases_url: "https://github.com/Zenrock-Foundation/zrchain/releases/download"
  version: "6.1.23"
  configFromSecret: <validator-sidecar-config>
  eigen_operator:
    keysFromSecret: "<validator-eigen-keys>"
    aggregator_address: avs-aggregator.diamond.zenrocklabs.io:8090
    eth_rpc_url: <ETH ENDPOINT HERE>
    eth_ws_url: <ETH ENDPOINT HERE>
    enable_metrics: true
    metrics_address: 0.0.0.0:9292
    enable_node_api: true
    node_api_address: 0.0.0.0:9191
    register_on_startup: true
    operator_address: <VALUE FROM STEP - ECDSA key>
    operator_validator_address: <VALUE FROM STEP - zenvaloper address>
    avs_registry_coordinator_address: 0xFbFECE8f29f499c32206d8bFfA57da2b124790C7
    operator_state_retriever_address: 0x03d0452e70711f169eB6B6F5Ab33d8571c313ef6
    token_strategy_addr: 0xa5430Ca83713F877B77b54d5A24FD3D230DF854B


zenrock:
  chain_id: diamond-1
  releases_url: "https://github.com/Zenrock-Foundation/zrchain/releases/download"
  genesis_url: "https://rpc.diamond.zenrocklabs.io/genesis"
  genesis_version: "5.3.8"
  nodeKeyFromSecret: <validator-cometbft-keys>
  config:
    allow_duplicate_ip: true
    external_address: ""
    log_format: plain
    log_level: info
    moniker: <MY_VALIDATOR>
    p2p_recv_rate: 512000000
    p2p_send_rate: 512000000
    persistent_peers: "a5c64669d5d5c27fcde2c37e89da57c6d0576a7b@sentry-1.diamond.zenrocklabs.io:26656,5ad8a5de6318529994da817043b268ef617e37ba@sentry-2.diamond.zenrocklabs.io:36656,4f93fec81eadc205dee1b63e766cc33d9f2e6767@sentry-3.diamond.zenrocklabs.io:46656,36840303211712d936647da0f74d1498a7e298d1@sentry-4.diamond.zenrocklabs.io:56656"
    unconditional_peer_ids: "a5c64669d5d5c27fcde2c37e89da57c6d0576a7b,5ad8a5de6318529994da817043b268ef617e37ba,4f93fec81eadc205dee1b63e766cc33d9f2e6767,36840303211712d936647da0f74d1498a7e298d1"
    pex: true
    pruning: nothing
    pruning_interval: "100"
    pruning_keep_recent: "100000"
  metrics:
    enabled: true
  persistence:
    claimName: validator-data-1
    enabled: true
    existingClaim: false
  resources:
    limits:
      cpu: 2000m
      memory: 2512Mi
    requests:
      cpu: 500m
      memory: 1024Mi
```

# Testnet

``` yaml
nameOverride: my-validator
fullnameOverride: my-validator

images:
  cosmovisor: alpine:3.20.2
  init_zenrock: alpine:3.20.2
  sidecar: alpine:3.20.2

cosmovisor:
  version: v1.6.0

sidecar:
  #To be updated
  enabled: true
  version: 6.3.3
  configFromSecret: <validator-sidecar-config>
  eigen_operator:
    aggregator_address: avs-aggregator.gardia.zenrocklabs.io:8090
    avs_registry_coordinator_address: 0xdc3A1b2a44D18c6B98a1d6c8C042247d2F5AC722
    enable_metrics: true
    enable_node_api: true
    eth_rpc_url: <HOLESKY ENDPOINT HERE>
    eth_ws_url: <HOLESKY ENDPOINT HERE>
    keysFromSecret: <validator-eigen-keys>
    metrics_address: 0.0.0.0:9292
    node_api_address: 0.0.0.0:9191
    register_on_startup: true
    operator_address: <VALUE FROM STEP - ECDSA key>
    operator_validator_address: <VALUE FROM STEP - zenvaloper address>
    avs_registry_coordinator_address: 0xdc3A1b2a44D18c6B98a1d6c8C042247d2F5AC722
    operator_state_retriever_address: 0xdB55356826a16DfFBD86ba334b84fC4E37113d97
    token_strategy_addr: 0x80528D6e9A2BAbFc766965E0E26d5aB08D9CFaF9

zenrock:
  chain_id: gardia-7
  nodeKeyFromSecret: <validator-cometbft-keys>
  config:
    allow_duplicate_ip: true
    external_address: ""
    log_format: plain
    log_level: info
    moniker: <MY_VALIDATOR>
    p2p_recv_rate: 512000000
    p2p_send_rate: 512000000
    persistent_peers: "07b6d8891e7b0239abf6744a2794e4eaa6cc76a4@sentry-1.gardia.zenrocklabs.io:26656,1dfbd854bab6ca95be652e8db078ab7a069eae6f@sentry-2.gardia.zenrocklabs.io:36656,63014f89cf325d3dc12cc8075c07b5f4ee666d64@sentry-3.gardia.zenrocklabs.io:46656,12f0463250bf004107195ff2c885be9b480e70e2@sentry-4.gardia.zenrocklabs.io:56656"
    unconditional_peer_ids: "07b6d8891e7b0239abf6744a2794e4eaa6cc76a4,1dfbd854bab6ca95be652e8db078ab7a069eae6f,63014f89cf325d3dc12cc8075c07b5f4ee666d64,12f0463250bf004107195ff2c885be9b480e70e2"
    pex: true
    pruning: nothing
    pruning_interval: "100"
    pruning_keep_recent: "100000"
  genesis_url: https://rpc.gardia.zenrocklabs.io/genesis
  genesis_version: 5.3.8
  metrics:
    enabled: true
  persistence:
    claimName: validator-data-1
    enabled: true
    existingClaim: false
  resources:
    limits:
      cpu: 2000m
      memory: 2512Mi
    requests:
      cpu: 500m
      memory: 1024Mi
```

## Install the helm chart

Install the validator Helm chart with the custom values file:

``` yaml
helm install zenrock-validator zenrock/zenrock -f custom_values.yaml
```

## Post-Setup Steps

- If you don't want to run a full ( Archive ) node, feel free to configure the pruning in the custom values file ( or in app.toml if you're usign systemd services)

```
    pruning: custom
    pruning_interval: "50"
    pruning_keep_recent: "100"
```

- Monitor the node's status and performance regularly.
- Participate in the Gardia community by following social media channels, forums, and Discord to stay informed about network updates and proposals.
