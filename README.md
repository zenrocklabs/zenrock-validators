# Zenrock Gardia Validator Node Setup

This guide explains how to set up a validator node on the Zenrock Gardia blockchain.

## Requirements

- **Operating System**: Linux-based systems (Ubuntu, Debian, CentOS, etc.)
- **Dependencies**:
  - `curl`
  - `jq`
  - `sed`
  - `tar`
- **Storage**: Ensure you have sufficient disk space for the blockchain data.
- **Network**: Reliable internet connection.

## Step-by-Step Setup

### 1. Clone this repository

``` sh
git clone https://github.com/zenrocklabs/zenrock-validators.git
cd zenrock-validators
```

### 2. Run the Initialization Script

``` sh
./init_gardia.sh
```

*NOTE:* Replace the variable `VALIDATOR_MONIKER` and optionally `ZENROCK_HOME`

### 3. Run the node

``` sh
./zenrockd start --home ZENROCK_HOME
```
*NOTE:* Replace ZENROCK_HOME with the value used in step 2 (current directory by default)

### 3. Create a New Zenrockd Account

Create a new account for your validator:

``` sh
./zenrockd keys add validator-x
```

### 4. Fund Your Validator Account

Transfer tokens to the validator's address. You can use a faucet or another method to get the necessary tokens.

### 5. Create a Validator

Create a file named `validator-info.json` with the following content, replacing the placeholder values:

``` json
{
    "pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"PUB_KEY"},
    "amount": "150000000000000urock",
    "moniker": "validator-x",
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

Replace "PUB_KEY" with your validator's public key obtained from the previous step.

Submit the validator creation transaction:

``` sh
./zenrockd tx staking create-validator [path/to/validator-info.json] \
    --home ./ \
    --node https://rpc.gardia.zenrocklabs.io \
    --gas-prices 10000urock \
    --from validator-x
```

## Post-Setup Steps

- Monitor the node's status and performance regularly.
- Update the zenrockd binary periodically to ensure you have the latest security patches and features.
- Participate in the Gardia community by following social media channels, forums, and Discord to stay informed about network updates and proposals.
