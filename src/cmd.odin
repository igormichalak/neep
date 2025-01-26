package neep

import "core:fmt"
import "core:os"

print_usage :: proc(exec_name: string) {
	fmt.println("Usage:", flush=false)
	fmt.printf("%s disassemble file.bin\n", exec_name)
}

cmd_disassemble :: proc(args: []string) -> (code: int) {
	for arg in args {
		if !os.is_file_path(arg) {
			fmt.eprintf("%q is not a file!\n", arg)
			return 1
		}
	}
	for arg in args {
		data, err := os.read_entire_file_or_err(arg)
		if err != os.ERROR_NONE {
			fmt.eprintf("Could not read file %q!\n")
			fmt.eprintln("Error:", err)
			return 1
		}

		out_str := disassemble_bin(data)
		fmt.print(out_str)

		delete(out_str)
		delete(data)
	}
	return 0
}

main :: proc() {
	if len(os.args) == 1 {
		fmt.eprint("Not enough arguments!\n\n")
		print_usage(os.args[0])
		os.exit(1)
	}
	switch os.args[1] {
	case "disassemble":
		os.exit(cmd_disassemble(os.args[2:]))
	case:
		fmt.eprint("Unrecognized command!\n\n")
		print_usage(os.args[0])
		os.exit(1)
	}
}
