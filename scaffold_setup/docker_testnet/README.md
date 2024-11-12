
# Docker setup for Zenrock Gardia ( Testnet)


## Adjust the configuration files 
Update:

    1. config/config.toml
    2. docker-compose.yaml

And replace - <MY_MONIKER_NAM> - with your preferred name

### Initializaiton

Run the init service to generate the folder structure and download the required binaries

```
docker-compose up -d init
```

it should complete in about 30-60 seconds, the container should exit afterwards



### Start the zenrockd service 

Once the initialization is completed you can start the zenrockd service:

```
docker-compose up -d zenrock
```
