//go:build ignore
package main

import (
	"bufio"
	_ "embed"
	"fmt"
	"os"
	"strconv"
	"strings"
)

//go:embed mnemonics.txt
var MNEMONICS string

const MaxJumpTableSize = 256

var ASSO = [26]int{
	16, 0, 3, 4, 14, 50, 50, 14, 16, 4, 0, 1, 21,
	14, 11, 15, 15, 0, 9, 10, 20, 13, 19, 9, 25, 9,
}

func hash(s string) (n int) {
	bytes := []byte(s)
	slen := len(bytes)
	for i := 0; i < slen; i++ {
		ch := bytes[i]
		switch {
		case 'a' <= ch && ch <= 'z':
			bytes[i] = ch - 'a'
		case 'A' <= ch && ch <= 'Z':
			bytes[i] = ch - 'A'
		}
	}
	n += ASSO[bytes[1]]
	n += ASSO[bytes[0]+1]
	n += ASSO[bytes[slen-1]]
	return
}

func run() error {
	var jmptable [][]string
	rd := strings.NewReader(MNEMONICS)
	scanner := bufio.NewScanner(rd)

	for scanner.Scan() {
		mnemonic := scanner.Text()

		idx := hash(mnemonic)
		if idx >= MaxJumpTableSize {
			return fmt.Errorf("jump table longer than %d "+
				"should not be needed", MaxJumpTableSize)
		}

		for len(jmptable) <= idx {
			jmptable = append(jmptable, nil)
		}

		jmptable[idx] = append(jmptable[idx], mnemonic)
	}

	collisions := 0

	idxColumnWidth := len(strconv.Itoa(MaxJumpTableSize))

	for i, row := range jmptable {
		if len(row) > 1 {
			collisions += len(row) - 1
		}
		fmt.Printf("%0*d: ", idxColumnWidth, i)
		for j, mnemonic := range row {
			if j == len(row)-1 {
				fmt.Print(mnemonic)
			} else if j == 4 {
				fmt.Print("...")
				break
			} else {
				fmt.Printf("%s, ", mnemonic)
			}
		}
		fmt.Print("\n")
	}

	fmt.Printf("Collisions: %d\n", collisions)
	fmt.Printf("Jump table length: %d\n", len(jmptable))

	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	os.Exit(0)
}
