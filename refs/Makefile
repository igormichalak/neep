AS = as31
OBJCOPY = objcopy

ASFLAGS = -Fhex

SOURCE = blink.asm
TARGET_HEX = $(SOURCE:.asm=.hex)
TARGET_BIN = $(SOURCE:.asm=.bin)

.PHONY: all
all: clean $(TARGET_BIN)

$(TARGET_HEX): $(SOURCE)
	$(AS) $(ASFLAGS) $(SOURCE)

$(TARGET_BIN): $(TARGET_HEX)
	$(OBJCOPY) -I ihex -O binary $(TARGET_HEX) $(TARGET_BIN)

.PHONY: clean
clean:
	rm -f $(TARGET_HEX) $(TARGET_BIN)
