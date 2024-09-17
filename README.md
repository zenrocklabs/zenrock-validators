# Zenrock Gardia Validator Node Setup

This guide explains how to set up a validator node on the Zenrock Gardia blockchain 
using Kubernetes and Helm.

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

### ECDSA key
The ECDSA key is used by the eigen operator.

``` sh
cd utils/keygen/ecdsa
./ecdsa --password mypassword
```

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

``` yaml
apiVersion: v1
kind: Secret
metadata:
    name: validator-sidecar-config
stringData:
    config.yaml: |
        grpc_port: 9191
        state_file: "cache.json"
        operator_config: "/root-data/sidecar/eigen_operator_config.yaml"
        eth_oracle:
          rpc:
            local: "http://127.0.0.1:8545"
            testnet: "https://rpc-endpoint-holesky-here"  # Replace this endpoint with a valid one
            mainnet: "https://rpc-endpoint-mainnet-here"  # Replace this endpoint with a valid one
          network: "testnet"
          contract_addrs:
            service_manager: "0xb48F00b89A4017f78794F35cb1ef540EDA5d201B"
            price_feed: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
            network_name: "Holešky Ethereum Testnet"
```
This configuration can be set in the Helm chart values, but if you want to encrypt any sensitive data such as 
RPC endpoint tokens, you can use this secret.


### Zenrock account
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

Transfer tokens to the validator's address. You can use a faucet or another method to get the necessary tokens.

### Create the validator

Create a file named `validator-info.json` with the following content, replacing the placeholder values:

``` json
{
    "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"PUB_KEY"},
    "amount": "1000000000000urock",
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

``` sh
./zenrockd tx staking create-validator [path/to/validator-info.json] \
    --node https://rpc.gardia.zenrocklabs.io \
    --gas-prices 10000urock \
    --from my-validator \
    --chain-id gardia-2
```


## Helm chart values

Create a custom values file for your Helm chart configuration:

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
  enabled: true
  version: 1.2.2
  configFromSecret: <validator-sidecar-config>
  eigen_operator:
    aggregator_address: avs-aggregator.gardia.zenrocklabs.io:443
    avs_registry_coordinator_address: 0xD4BdE8DD7B82C04E4c1617B0F477f4F8B2CcdE2F
    enable_metrics: true
    enable_node_api: true
    eth_rpc_url: <HOLESKY ENDPOINT HERE>
    eth_ws_url: <HOLESKY ENDPOINT HERE>
    keysFromSecret: <validator-eigen-keys>
    metrics_address: 0.0.0.0:9292
    node_api_address: 0.0.0.0:9191
    operator_address: <VALUE FROM STEP #>
    operator_state_retriever_address: 0x148e80620b9464Fa0731467d504A2F760E7242C8
    operator_validator_address: <VALUE FROM STEP #>
    register_on_startup: true
    service_manager_address: 0xb48F00b89A4017f78794F35cb1ef540EDA5d201B
    token_strategy_addr: 0x80528D6e9A2BAbFc766965E0E26d5aB08D9CFaF9

zenrock:
  chain_id: gardia-2
  nodeKeyFromSecret: <validator-cometbft-keys>
  config:
    allow_duplicate_ip: true
    external_address: ""
    log_format: plain
    log_level: info
    moniker: <MY_VALIDATOR>
    p2p_recv_rate: 512000000
    p2p_send_rate: 512000000
    persistent_peers: "6ef43e8d5be8d0499b6c57eb15d3dd6dee809c1e@sentry-1.gardia.zenrocklabs.io:26656,1dfbd854bab6ca95be652e8db078ab7a069eae6f@sentry-2.gardia.zenrocklabs.io:36656"
    unconditional_peer_ids: "6ef43e8d5be8d0499b6c57eb15d3dd6dee809c1e@sentry-1.gardia.zenrocklabs.io:26656,1dfbd854bab6ca95be652e8db078ab7a069eae6f@sentry-2.gardia.zenrocklabs.io:36656"
    pex: true
    pruning: nothing
    pruning_interval: "100"
    pruning_keep_recent: "100000"
  genesis_url: https://rpc.gardia.zenrocklabs.io/genesis
  genesis_version: 4.7.0
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

- Monitor the node's status and performance regularly.
- Participate in the Gardia community by following social media channels, forums, and Discord to stay informed about network updates and proposals.
