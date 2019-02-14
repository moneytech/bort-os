CURRENT_DIR := $(patsubst %/,%,$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

ASM := nasm
CXX := x86_64-elf-gcc
LD  := x86_64-elf-ld

CXX_FLAGS := -std=c++17 -Wall -Wextra -Wpedantic -O0 -g0
CXX_FLAGS += -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-red-zone
CXX_FLAGS += -fno-stack-protector -ffreestanding -fno-builtin -fno-rtti -fno-exceptions
CXX_FLAGS += -I$(CURRENT_DIR)

LD_FLAGS := -n -T $(CURRENT_DIR)/linker.ld

SOURCE_FILES := $(shell find $(CURRENT_DIR) -name '*.cpp' -type f)
SOURCE_FILES += $(shell find $(CURRENT_DIR) -name '*.asm' -type f)

OBJECT_FILES := $(patsubst $(CURRENT_DIR)/%,$(BUILD_DIR)/kernel/%,$(SOURCE_FILES))
OBJECT_FILES := $(addsuffix .o,$(OBJECT_FILES))

all: $(OBJECT_FILES)
	$(LD) $(LD_FLAGS) -o $(BUILD_DIR)/kernel/kernel.bin $(OBJECT_FILES)

$(BUILD_DIR)/kernel/%.cpp.o: $(CURRENT_DIR)/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXX_FLAGS) -c -o $@ $<

$(BUILD_DIR)/kernel/%.asm.o: $(CURRENT_DIR)/%.asm
	@mkdir -p $(@D)
	$(ASM) $(ASM_FLAGS) -o $@ $<
