#include <cstring>

#include <array>
#include <fstream>
#include <iostream>
#include <vector>

constexpr uint16_t BORTFS_VERSION = 0x0001;

constexpr uint64_t UNUSED_BLOCK   = 0x0000'0000'0000'0000;
constexpr uint64_t RESERVED_BLOCK = 0xFFFF'FFFF'FFFF'FFFE;
constexpr uint64_t END_OF_CHAIN   = 0xFFFF'FFFF'FFFF'FFFF;

struct DirectoryEntry {
    uint8_t  name[48];
    uint64_t first_block;
    uint64_t size;
};

void print_usage() {
    std::cout << "Usage: bortfs-utils [action] [disk_image_file] [arguments...]\n";
}

size_t get_file_size(std::fstream& file) {
    file.seekg(0, std::ios::end);
    const auto size = file.tellg();
    file.seekg(0, std::ios::beg);
    return size;
}

template <typename T> T read_value(std::fstream& file, const size_t location) {
    file.seekg(location, std::ios::beg);
    T value;
    file.read(reinterpret_cast<char*>(&value), sizeof(T));
    return value;
}

template <typename T>
std::vector<T> read_array(std::fstream& file, const size_t location, const size_t length) {
    std::vector<T> result(length);
    file.seekg(location, std::ios::beg);
    file.read(reinterpret_cast<char*>(result.data()), length);
    return result;
}

template <typename T> void write_value(std::fstream& file, const size_t location, const T& value) {
    file.seekp(location, std::ios::beg);
    file.write(reinterpret_cast<const char*>(&value), sizeof(T));
}

template <typename T>
void write_array(std::fstream& file, const size_t location, const T array[], const size_t length) {
    file.seekp(location, std::ios::beg);
    file.write(reinterpret_cast<const char*>(array), sizeof(T) * length);
}

int format(std::fstream& image_file, const uint16_t block_size, const uint32_t reserved_blocks) {
    const auto image_size = get_file_size(image_file);
    const auto block_count = image_size / block_size;
    const auto main_dir_size = block_count / 20;         // 5% of the disk size.

    if (reserved_blocks > block_count) {
        std::cerr << "Error: Requested more reserved blocks that are available." << std::endl;
        return 1;
    }
    if (main_dir_size == 0) {
        std::cerr << "Error: Image size too small." << std::endl;
        return 1;
    }

    write_value<uint16_t>(image_file, 0, 0x1EEB);           // JMP SHORT.
    write_array          (image_file, 2, "BortFS", 6);      // Signature.
    write_value<uint16_t>(image_file, 8, BORTFS_VERSION);   // Version.
    write_value<uint32_t>(image_file, 12, block_size);      // Size of a block.
    write_value<uint64_t>(image_file, 16, block_count);     // Number of blocks.
    write_value<uint32_t>(image_file, 24, reserved_blocks); // Number of reserved blocks.
    write_value<uint32_t>(image_file, 28, main_dir_size);   // Size of the main dir in blocks.

    const auto fat_offset = reserved_blocks * block_size;

    // Reserved blocks.
    for (size_t i = 0; i < reserved_blocks; i += 1) {
        write_value<uint64_t>(image_file, fat_offset + i * sizeof(uint64_t), RESERVED_BLOCK);
    }

    // FAT blocks.
    const auto fat_start = reserved_blocks;
    const auto fat_entries_per_block = block_size / sizeof(uint64_t);
    const auto fat_end =
            fat_start + (block_count + fat_entries_per_block - 1) / fat_entries_per_block;
    for (size_t i = fat_start; i < fat_end; i += 1) {
        write_value<uint64_t>(image_file, fat_offset + i * sizeof(uint64_t), RESERVED_BLOCK);
    }

    // Main directory blocks.
    const auto fat_main_dir_start = fat_end;
    const auto fat_main_dir_end = fat_main_dir_start + main_dir_size;
    for (size_t i = fat_main_dir_start; i < fat_main_dir_end; i += 1) {
        write_value<uint64_t>(image_file, fat_offset + i * sizeof(uint64_t), RESERVED_BLOCK);
    }

    // Rest of blocks.
    for (size_t i = fat_main_dir_end; i < block_count; i += 1) {
        write_value<uint64_t>(image_file, fat_offset + i * sizeof(uint64_t), UNUSED_BLOCK);
    }

    // Zero main directory.
    const auto fat_size = block_count * sizeof(uint64_t);
    const auto main_dir_offset = fat_offset + fat_size;
    constexpr DirectoryEntry null_dir_entry{{'\0'}, 0, 0};
    for (size_t i = 0; i < main_dir_size * block_size / sizeof(DirectoryEntry); i += 1) {
        const auto dir_entry_offset = main_dir_offset + i * sizeof(DirectoryEntry);
        write_value<DirectoryEntry>(image_file, dir_entry_offset, null_dir_entry);
    }

    return 0;
}

void copy_file_data(std::fstream& in, std::fstream& out, size_t from, size_t to, size_t count) {
    write_array(out, to, read_array<uint8_t>(in, from, count).data(), count);
}

size_t find_first_free_fat_entry(
        std::fstream& file, size_t fat_offset, size_t fat_size, size_t start_from) {
    for (size_t i = start_from; i < fat_size; i += 1) {
        if (read_value<uint64_t>(file, fat_offset + i * sizeof(uint64_t)) == UNUSED_BLOCK) {
            return i;
        }
    }
    return -1;
}

size_t find_free_main_dir_entry(std::fstream& file, const size_t main_dir_offset) {
    for (size_t i = 0; i < 512 /*TODO*/; i += 1) {
        const auto entry_offset = main_dir_offset + i * sizeof(DirectoryEntry);
        DirectoryEntry entry = read_value<DirectoryEntry>(file, entry_offset);
        if (entry.name[0] == '\0') {
            return 0;
        }
    }
    return -1;
}

int copy_file(std::fstream& image_file, const std::string_view source_file_path,
        const std::string_view target_file_path) {
    const auto signature = read_array<uint8_t>(image_file, 2, 6);
    const auto block_size = read_value<uint32_t>(image_file, 12);
    const auto block_count = read_value<uint64_t>(image_file, 16);
    const auto reserved_blocks = read_value<uint32_t>(image_file, 24);

    if (std::strncmp(reinterpret_cast<const char*>(signature.data()), "BortFS", 6) != 0) {
        std::cout << "Error: This is not a valid BortFS disk image." << std::endl;
        return 1;
    }

    const auto fat_offset = reserved_blocks * block_size;
    const auto fat_entries_per_block = block_size / sizeof(uint64_t);
    const auto fat_blocks = (block_count + fat_entries_per_block - 1) / fat_entries_per_block;

    std::fstream source_file{source_file_path.data(), std::ios::binary | std::ios::in};
    if (!source_file.good()) {
        std::cerr << "Error: Couldn't read from file \"" << source_file_path << "\"." << std::endl;
        return 1;
    }

    const auto source_file_size = get_file_size(source_file);
    const auto file_blocks = (source_file_size + block_size - 1) / block_size;

    size_t first_block = find_first_free_fat_entry(image_file, fat_offset, block_count, 0);
    size_t free_entry = first_block;
    for (size_t i = 0; i < file_blocks; i += 1) {
        const auto entry_offset = fat_offset + free_entry * sizeof(uint64_t);
        if (i == file_blocks - 1) {
            write_value<uint64_t>(image_file, entry_offset, END_OF_CHAIN);
            const auto from_offset = i * block_size;
            const auto to_offset = free_entry * block_size;
            if (source_file_size % block_size == 0) {
                copy_file_data(source_file, image_file, from_offset, to_offset, block_size);
            } else {
                copy_file_data(source_file, image_file, from_offset, to_offset, source_file_size % block_size);
            }
        } else {
            copy_file_data(source_file, image_file, block_size * i, free_entry * block_size, block_size);
            free_entry =
                    find_first_free_fat_entry(image_file, fat_offset, block_count, free_entry + 1);
            write_value<uint32_t>(image_file, entry_offset, free_entry);
        }
    }

    const auto fat_size = fat_blocks * block_size;
    const auto main_dir_offset = fat_offset + fat_size;
    const auto free_main_dir_entry = find_free_main_dir_entry(image_file, main_dir_offset);
    DirectoryEntry dir_entry{};
    std::copy(target_file_path.cbegin(), target_file_path.cend(), dir_entry.name);
    dir_entry.first_block = first_block;
    dir_entry.size = source_file_size;

    const auto entry_offset = main_dir_offset + free_main_dir_entry * sizeof(DirectoryEntry);
    write_value<DirectoryEntry>(image_file, entry_offset, dir_entry);
    return 0;
}

int main(const int argc, const char* argv[]) {
    if (argc < 3) {
        print_usage();
        return 0;
    }

    std::fstream image_file{argv[2], std::ios::in | std::ios::out | std::ios::binary};
    if (!image_file.good()) {
        std::cerr << "Error: Failed to open the specified disk image file.\n";
        return 1;
    }

    if (std::strcmp(argv[1], "format") == 0) {
        if (argc < 4) {
            std::cerr << "Error: Missing block size argument." << std::endl;
        }
        if (argc < 5) {
            std::cerr << "Error: Missing number of reserved blocks argument." << std::endl;
        }

        try {
            const uint16_t block_size = std::stoi(argv[3]);
            const uint16_t reserved_blocks = std::stoi(argv[4]);
            return format(image_file, block_size, reserved_blocks);
        } catch (std::invalid_argument& e) {
            std::cerr << "Error: Invalid argument." << std::endl;
            return 1;
        }
    } else if (std::strcmp(argv[1], "copy") == 0) {
        if (argc < 4) {
            std::cerr << "Error: Missing source file path." << std::endl;
        }
        if (argc < 5) {
            std::cerr << "Error: Missing destination file path." << std::endl;
        }
        return copy_file(image_file, argv[3], argv[4]);
    } else {
        std::cerr << "Error: Unknown action specified." << std::endl;
        return 1;
    }

    return 0;
}
