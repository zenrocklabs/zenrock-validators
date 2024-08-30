package main

import (
	"flag"
	"fmt"
	"time"

	"github.com/Layr-Labs/eigensdk-go/crypto/bls"
)

const keystorePath = "keystore/"

func main() {
	passwordFlag := flag.String("password", "", "Password for the keystore file")
	flag.Parse()

	keys, err := bls.GenRandomBlsKeys()
	if err != nil {
		panic(err)
	}

	filename := keystorePath + time.Now().Format("2006-01-02_15-04-05.000")
	if err = keys.SaveToFile(filename, *passwordFlag); err != nil {
		panic(err)
	}

	fmt.Printf("BLS keypair saved to: %s\n", filename)
}
