#!/usr/bin/env python3
import sys
import json
import datetime
from eth_account import Account
import secrets

def generate_and_export_ecdsa_key_to_keystore(password):
    # Generate a new Ethereum account
    account = Account.create(secrets.token_bytes(32))
    # Get the private key and address
    private_key = account.key
    address = account.address

    # Generate the V3 keystore
    v3_keystore = Account.encrypt(private_key, password)

    # Create the filename
    timestamp = datetime.datetime.now(datetime.UTC).replace(microsecond=0).isoformat().replace(':', '-')
    filename = f"UTC--{timestamp}--{address[2:]}.json"

    # Write the keystore to a file
    with open(filename, 'w') as f:
        json.dump(v3_keystore, f, indent=2)

    print(f"Keystore saved to {filename}")
    print(f"Address: {address}")
    print(f"Private Key: 0x{private_key.hex()}")  # Be cautious with displaying the private key

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python genECDSA.py <password>")
        sys.exit(1)

    password = sys.argv[1]

    try:
        generate_and_export_ecdsa_key_to_keystore(password)
    except Exception as e:
        print(f"Error generating V3 wallet: {e}")
        sys.exit(1)
