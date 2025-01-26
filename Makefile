BINARY_NAME = neep

.PHONY: all
all: run

.PHONY: run
run:
	odin run ./src/ -vet -out:$(BINARY_NAME)
