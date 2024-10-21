----------------------------------------------------------

## Manual setup

Note: If you're setting all services from scratch, you can use the standalone_setup.sh script, otherwise, please check the scaffold_setup folder for instructions on configuring a scaffold configuration.

The script is provided as-is. We recommend using the Helm Chart as the primary installation method. Its configured only for testnet, with mainnet launch it will be re-configured

Make sure that you have your Zenrockd Address generated with the command:

```
./zenrockd keys add my-validator
```

Executing the script, it will prompt you to input the validator initialization path 

```
root@test:~/zenrock-validators# bash standalone_setup.sh
Enter the path where you want to create the Application directory or where it exists: /validator-test
```

Make sure to follow the on-screen instructions. E.G.:

```
Select an option:
1 - Initialize service
2 - Update service
3 - Cleanup service setup
Enter your choice (1/2/3): 1
Enter your Zenrock address: 
```
Here you include your Zenrock address generated with the above zenrockd command
```
Enter name for your validator: YOUR_MONIKER_NAME

Enter your mainnet eth endpoint without https:// : 
Enter your holesky eth endpoint without https:// : 
```

Here you include your Mainnet/Holesky endpoints withoout any prefix

```
Directory created successfully at: /validator-test
Downloading latest zenrockd release
Zenrockd setup completed in : /validator-test/cosmovisor/genesis/bin/zenrockd
Cosmovisor initialization completed successfully.
Downloading latest validator sidecar release
Validator sidecar setup completed in : /validator-test/sidecar/bin/validator_sidecar
Downloading latest cosmovisor release
Cosmovisor setup completed in: /validator-test/cosmovisor/bin/cosmovisor
Enter password for the ECDSA key: passwordecdsa
Public address:  0x3D530EA935031723bE70A41aA352E5835A4713cC
Please fund this address before proceeding further
Type 'yes' to proceed, once you confirm that the Address has been funded with tokens: yes
```

Once you have the ECDSA key generated, the script will provide you the public address you need to fund tokens on the Holesky network. In this example we need to fund our Address - 0x3D530EA935031723bE70A41aA352E5835A4713cC - with tokens. Once this is done we can proceded further with the script execution

```
Proceeding to the next step...
Enter password for the BLS key: passwordbls
BLS keypair saved to: keystore/2024-09-24_08-11-29.655
Giving some time for the funds to reflect in the address balance
Created symlink /etc/systemd/system/multi-user.target.wants/validator-sidecar.service → /etc/systemd/system/validator-sidecar.service.
Waiting for validator-sidecar service initialization
validator-sidecar has been started successfully.
Created symlink /etc/systemd/system/multi-user.target.wants/cosmovisor.service → /etc/systemd/system/cosmovisor.service.
Waiting for cosmovisor service initialization
cosmovisor has been started successfully.
```

Once the setup is completed, you just need to follow the same steps as in the Helmchart setup which are:

1. Seting up the validator-info.json configuration file
2. Submit the validator creation transaction



