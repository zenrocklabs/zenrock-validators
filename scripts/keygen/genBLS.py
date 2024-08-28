import json
import sys
import datetime
from py_ecc import optimized_bn128 as bn128
from Crypto.Cipher import AES
from Crypto.Protocol.KDF import scrypt
from Crypto.Random import get_random_bytes
import os

def generate_bls_keypair():
    private_key = int.from_bytes(get_random_bytes(32), 'big') % bn128.curve_order
    public_key = bn128.multiply(bn128.G2, private_key)
    return private_key, public_key

def point_to_two_numbers(point):
    # Extract x coordinate (first two elements of the point)
    x_coord = point[0].coeffs[0] + (point[0].coeffs[1] << 256)
    # Extract y coordinate (last two elements of the point)
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

def export_bls_key(sk, pk, password):
    encrypted_private_key = encrypt_private_key(sk, password)

    export_data = {
        "pubKey": f"E({point_to_two_numbers(pk)})",
        "crypto": encrypted_private_key
    }

    return export_data

def main():
    if len(sys.argv) != 2:
        print("Usage: python genBLS.py <password>")
        sys.exit(1)

    password = sys.argv[1]
    sk, pk = generate_bls_keypair()
    exported_key = export_bls_key(sk, pk, password)
    # Create the filename
    timestamp = datetime.datetime.now(datetime.UTC).replace(microsecond=0).isoformat().replace(':', '-')
    filename = f"UTC--{timestamp}--bls.json"

    # Write the keystore to a file
    with open(filename, 'w') as f:
        json.dump(exported_key, f, indent=2)

if __name__ == "__main__":
    main()
