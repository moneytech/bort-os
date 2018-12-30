CURRENT_DIR := $(patsubst %/,%,$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

ASM_FLAGS := -f bin -I$(CURRENT_DIR)/

all:
	@mkdir -p $(BUILD_DIR)/bootloader
	@$(ASM) $(ASM_FLAGS) -o $(BUILD_DIR)/bootloader/bootloader.bin $(CURRENT_DIR)/bootloader.asm
