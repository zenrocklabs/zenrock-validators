package main

import (
	"fmt"
	"os"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

func main() {
	addr := sdk.MustAccAddressFromBech32(os.Args[1])
	fmt.Println(sdk.ValAddress(addr).String())
}
