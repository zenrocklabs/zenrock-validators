package main

import (
	"crypto/ecdsa"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/ethereum/go-ethereum/accounts/keystore"
	"github.com/ethereum/go-ethereum/crypto"
)

func main() {
	passwordFlag := flag.String("password", "", "Password for the keystore file")
	mnemonicFlag := flag.String("mnemonic", "", "Mnemonic phrase to derive the private key")
	privateKeyFlag := flag.String("private-key", "", "Private key in hexadecimal format")
	flag.Parse()

	var privateKey *ecdsa.PrivateKey
	var err error

	// Determine the source of the private key
	if *mnemonicFlag != "" {
		privateKey, err = privateKeyFromMnemonic(*mnemonicFlag)
	} else if *privateKeyFlag != "" {
		privateKey, err = crypto.HexToECDSA(*privateKeyFlag)
	} else {
		privateKey, err = crypto.GenerateKey()
	}

	if err != nil {
		log.Fatalf("Failed to get or generate private key: %v", err)
	}

	// Create keystore directory
	keystoreDir := "./keystore"
	if err := os.MkdirAll(keystoreDir, 0700); err != nil {
		log.Fatalf("Failed to create keystore directory: %v", err)
	}

	// Create keystore
	ks := keystore.NewKeyStore(keystoreDir, keystore.StandardScryptN, keystore.StandardScryptP)

	// Import the private key into the keystore
	account, err := ks.ImportECDSA(privateKey, *passwordFlag)
	if err != nil {
		log.Fatalf("Failed to import private key: %v", err)
	}

	// Get the absolute path of the keystore file
	keystorePath, err := filepath.Abs(account.URL.Path)
	if err != nil {
		log.Fatalf("Failed to get absolute path: %v", err)
	}

	fmt.Printf("Keystore file created: %s\n", keystorePath)

	// Print public address
	address := crypto.PubkeyToAddress(privateKey.PublicKey)
	fmt.Printf("Public address: %s\n", address.Hex())
}

func privateKeyFromMnemonic(mnemonic string) (*ecdsa.PrivateKey, error) {
	seed := crypto.Keccak256([]byte(mnemonic))

	privateKey, err := crypto.ToECDSA(seed[:32])
	if err != nil {
		return nil, fmt.Errorf("failed to create private key: %v", err)
	}

	return privateKey, nil
}
