export ROOT_DIR      := $(patsubst %/,%,$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
export BUILD_DIR     ?= $(ROOT_DIR)/build
export BINARY_DIR    := $(ROOT_DIR)/binary
export LIBRARIES_DIR := $(ROOT_DIR)/libraries
export SOURCE_DIR    := $(ROOT_DIR)/source
export TOOLS_DIR     := $(BUILD_DIR)/tools

export IMAGE_PATH ?= $(BUILD_DIR)/bort-os.iso

export ASM  ?= nasm
export BCC  ?= bcc
export LD86 ?= ld86

export QEMU           := qemu-system-x86_64
export QEMU_FLAGS     := -no-reboot -no-shutdown -monitor stdio -m 2M
export QEMU_FLAGS_KVM := $(QEMU_FLAGS) -enable-kvm

MODULES := bootloader kernel

all-qemu: all
	$(QEMU) $(QEMU_FLAGS_KVM) -drive format=raw,file=$(IMAGE_PATH)

all-qemu-no-kvm: all
	$(QEMU) $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

run-qemu:
	$(QEMU) $(QEMU_FLAGS_KVM) -drive format=raw,file=$(IMAGE_PATH)

run-qemu-no-kvm:
	$(QEMU) $(QEMU_FLAGS) -drive format=raw,file=$(IMAGE_PATH)

all: modules
	@$(MAKE) -C $(ROOT_DIR)/tools

	@cp $(BUILD_DIR)/bootloader/bootloader.bin $(IMAGE_PATH)
	@dd if=/dev/zero bs=1K count=2048 >> $(IMAGE_PATH) 2> /dev/null
	@truncate $(IMAGE_PATH) --size=-$(shell stat -c %s $(BUILD_DIR)/bootloader/bootloader.bin)
	@$(TOOLS_DIR)/bortfs-utils format $(IMAGE_PATH) 4096 4
	@$(TOOLS_DIR)/bortfs-utils copy $(IMAGE_PATH) $(BUILD_DIR)/kernel/kernel.bin kernel.bin

modules:
	@for module in $(MODULES); do                      \
	    echo "Entering module $$module";               \
	    $(MAKE) -C $(SOURCE_DIR)/$$module -f build.mk; \
	done

clean:
	@rm -rf $(BUILD_DIR)
