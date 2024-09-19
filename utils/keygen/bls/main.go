package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/Layr-Labs/eigensdk-go/crypto/bls"
)

const keystorePath = "keystore/"

func main() {
	passwordFlag := flag.String("password", "", "Password for the keystore file")
	outputFileFlag := flag.String("output-file", "", "Path to the output file including the filename")
	flag.Parse()

	keys, err := bls.GenRandomBlsKeys()
	if err != nil {
		panic(err)
	}

	var filename string
	if *outputFileFlag != "" {
		filename = *outputFileFlag
	} else {
		filename = keystorePath + time.Now().Format("2006-01-02_15-04-05.000")
	}

	// Ensure the directory exists
	outputDir := filepath.Dir(filename)
	if err := os.MkdirAll(outputDir, 0700); err != nil {
		panic(err)
	}

	if err = keys.SaveToFile(filename, *passwordFlag); err != nil {
		panic(err)
	}

	fmt.Printf("BLS keypair saved to: %s\n", filename)
}
