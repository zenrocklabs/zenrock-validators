import sys
import json
from datetime import datetime
from py_ecc import optimized_bn128 as bn128
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import scrypt
from Crypto.Random import get_random_bytes
import os

def point_to_two_numbers(point):
    x_coord = point[0].coeffs[0] + (point[0].coeffs[1] << 256)
    y_coord = point[1].coeffs[0] + (point[1].coeffs[1] << 256)
    return [x_coord, y_coord]

def encrypt_private_key(private_key, password):
    salt = os.urandom(32)
    key = scrypt(password.encode(), salt, key_len=32, N=262144, r=8, p=1)
    nonce = os.urandom(8)  # AES CTR mode uses an 8-byte nonce
    cipher = AES.new(key, AES.MODE_CTR, nonce=nonce)
    ciphertext = cipher.encrypt(private_key.to_bytes(32, 'big'))

    mac = scrypt(key + ciphertext, salt, key_len=32, N=262144, r=8, p=1)

    return {
        "cipher": "aes-128-ctr",
        "ciphertext": ciphertext.hex(),
        "cipherparams": {"iv": (nonce + cipher.nonce).hex()},  # Combine nonce and counter
        "kdf": "scrypt",
        "kdfparams": {
            "dklen": 32,
            "n": 262144,
            "p": 1,
            "r": 8,
            "salt": salt.hex()
        },
        "mac": mac.hex()
    }

def export_bls_key(private_key, password):
    # Generate public key from private key
    public_key = bn128.multiply(bn128.G2, private_key)
    encrypted_private_key = encrypt_private_key(private_key, password)
    export_data = {
        "pubKey": f"E({point_to_two_numbers(public_key)})",
        "crypto": encrypted_private_key
    }

    return json.dumps(export_data, separators=(',', ':'))

def save_keystore(keystore, public_key):
    timestamp = datetime.utcnow().replace(microsecond=0).isoformat().replace(':', '-')
    filename = f"UTC--{timestamp}--{public_key[:8]}.json"
    with open(filename, 'w') as f:
        json.dump(json.loads(keystore), f, indent=2)
    print(f"Keystore saved to {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <private_key_hex> <password>")
        sys.exit(1)

    private_key_hex = sys.argv[1]
    password = sys.argv[2]

    try:
        private_key = int(private_key_hex, 16)
        keystore = export_bls_key(private_key, password)
        public_key = json.loads(keystore)["pubKey"]
        save_keystore(keystore, public_key)
    except Exception as e:
        print(f"Error generating BLS keystore: {e}")
        sys.exit(1)
