//go:build ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

const TableStartMarker = "OPCODE_TABLE := [256]Instruction_Specifier {"
const TableEndMarker = "}"

func squashWhitespace(line string) string  {
	var sb strings.Builder
	var prevR rune
	indent := true
	for _, r := range line {
		if indent && !isIndentRune(r) {
			indent = false
		}
		adjacentWhitespace := (r == ' ' && prevR == ' ')
		write := indent || !adjacentWhitespace
		if write {
			sb.WriteRune(r)
			prevR = r
		}
	}
	return sb.String()
}

func isIndentRune(r rune) bool {
	return r == ' ' || r == '\t'
}

func runeIndices(s string, searchR rune) []int {
	var indices []int
	for i, r := range s {
		if r == searchR {
			indices = append(indices, i)
		}
	}
	return indices
}

func formatLine(line string, bracketIdx, col int) string {
	var sb strings.Builder
	currentBracketIdx := 0
	for i, r := range line {
		if r == '{' {
			if currentBracketIdx == bracketIdx {
				for pad := col - i; pad > 0; pad-- {
					sb.WriteRune(' ')
				}
			}
			currentBracketIdx++
		}
		sb.WriteRune(r)
	}
	return sb.String()
}

func run() error {
	if len(os.Args) <= 1 {
		return fmt.Errorf("Please specify filepath!")
	}
	file, err := os.Open(os.Args[1])
	if err != nil {
		return fmt.Errorf("Failed to open file: %w", err)
	}
	defer file.Close()

	var sb strings.Builder
	scanner := bufio.NewScanner(file)

	var foundTable, insideTable bool
	leftBrackets := 0

	// first pass: squash whitespace
	for scanner.Scan() {
		line := scanner.Text()
		if insideTable && line == TableEndMarker {
			insideTable = false
		}
		if insideTable {
			if leftBrackets == 0 {
				leftBrackets = strings.Count(line, "{")
			}
			sb.WriteString(squashWhitespace(line))
		} else {
			sb.WriteString(line)
		}
		sb.WriteRune('\n')
		if line == TableStartMarker {
			foundTable = true
			insideTable = true
		}
	}

	foundTable = foundTable && !insideTable

	if !foundTable {
		return fmt.Errorf("Table cannot be identified!")
	}

	lastMeasuredCol := 0
	passes := leftBrackets * 2

	for i := 0;  i < passes; i++ {
		bracketIdx := i / 2
		measure := i % 2 == 0

		scanner = bufio.NewScanner(strings.NewReader(sb.String()))
		sb.Reset()

		for scanner.Scan() {
			line := scanner.Text()
			if insideTable && line == TableEndMarker {
				insideTable = false
			}
			bracketCols := runeIndices(line, '{')
			if insideTable && len(bracketCols) == 3 {
				if measure {
					lastMeasuredCol = max(lastMeasuredCol, bracketCols[bracketIdx])
					sb.WriteString(line)
				} else {
					sb.WriteString(formatLine(line, bracketIdx, lastMeasuredCol))
				}
			} else {
				sb.WriteString(line)
			}
			sb.WriteRune('\n')
			if line == TableStartMarker {
				foundTable = true
				insideTable = true
			}
		}
	}
	fmt.Print(sb.String())
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
	os.Exit(0)
}
