export ROOT_DIR      := $(patsubst %/,%,$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
export BUILD_DIR     ?= $(ROOT_DIR)/build
export BINARY_DIR    := $(ROOT_DIR)/binary
export LIBRARIES_DIR := $(ROOT_DIR)/libraries
export SOURCE_DIR    := $(ROOT_DIR)/source

export IMAGE_PATH ?= $(BUILD_DIR)/bort-os.iso

export ASM  ?= nasm
export BCC  ?= bcc
export LD86 ?= ld86

export QEMU       := qemu-system-x86_64
export QEMU_FLAGS := -enable-kvm

MODULES := bootloader

qemu: all
	$(QEMU) $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

all: $(MODULES)
	cp $(BUILD_DIR)/bootloader/bootloader.bin $(IMAGE_PATH)

$(MODULES):
	@for module in $(MODULES); do                      \
	    $(MAKE) -C $(SOURCE_DIR)/$$module -f build.mk; \
	done

clean:
	@rm -rf $(BUILD_DIR)
