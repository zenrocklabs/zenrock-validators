
import sys
import json
import datetime
from eth_account import Account

def export_ecdsa_key_to_keystore(private_key_hex, password):
    # Create an account from the private key
    account = Account.from_key(private_key_hex)

    # Generate the V3 keystore
    v3_keystore = Account.encrypt(account.key, password)

    # Get the address
    address = account.address

    # Create the filename
    timestamp = datetime.datetime.now(datetime.UTC).replace(microsecond=0).isoformat().replace(':', '-')
    filename = f"UTC--{timestamp}--{address[2:]}.json"

    # Write the keystore to a file
    with open(filename, 'w') as f:
        json.dump(v3_keystore, f, indent=2)

    print(f"Keystore saved to {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <private_key_hex> <password>")
        sys.exit(1)

    private_key_hex = sys.argv[1]
    password = sys.argv[2]

    try:
        export_ecdsa_key_to_keystore(private_key_hex, password)
    except Exception as e:
        print(f"Error generating V3 wallet: {e}")
        sys.exit(1)
