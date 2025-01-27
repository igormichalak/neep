BINARY_NAME = neep
ARGS ?=

.PHONY: all
all: run

.PHONY: run
run:
	odin run ./src/ -vet -out:$(BINARY_NAME) -- $(ARGS)
