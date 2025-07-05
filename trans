#!/bin/bash

# Check if assembly file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <assembly_file>"
    echo "Example: $0 instr/forwarding/sim1.asm"
    exit 1
fi

ASSEMBLY_FILE="$1"

# Check if assembly file exists
if [ ! -f "$ASSEMBLY_FILE" ]; then
    echo "Error: Assembly file '$ASSEMBLY_FILE' not found!"
    exit 1
fi

# Extract directory, filename, and basename
ASSEMBLY_DIR=$(dirname "$ASSEMBLY_FILE")
ASSEMBLY_BASENAME=$(basename "$ASSEMBLY_FILE" .asm)
TARGET_NAME="${ASSEMBLY_BASENAME}.dat"
COE_NAME="${ASSEMBLY_BASENAME}.coe"
SCRIPT_DIR=$(dirname "$0")

# Define linker script location
LINKER_SCRIPT="$SCRIPT_DIR/riscv32-minimal.ld"

# Check if linker script exists
if [ ! -f "$LINKER_SCRIPT" ]; then
    echo "Error: Linker script not found at $LINKER_SCRIPT"
    echo "Please ensure riscv32-minimal.ld is in the same directory as trans.sh"
    exit 1
fi

echo "Processing: $ASSEMBLY_FILE"
echo "Output directory: $ASSEMBLY_DIR"
echo "Output files: $TARGET_NAME, $COE_NAME"
echo "Using linker script: $LINKER_SCRIPT"

# Create temporary assembly file with required headers
echo ".text" > test.s
echo ".globl _start" >> test.s  
echo "_start:" >> test.s
cat "$ASSEMBLY_FILE" >> test.s

# Assemble and link
echo "Assembling and linking..."
riscv64-unknown-elf-as -march=rv32i_zicsr -mabi=ilp32 -o test.o test.s
if [ $? -ne 0 ]; then
    echo "Error: Assembly failed!"
    rm -f test.s test.o
    exit 1
fi

# Link with the linker script
riscv64-unknown-elf-ld -m elf32lriscv -T "$LINKER_SCRIPT" -o test.elf test.o
if [ $? -ne 0 ]; then
    echo "Error: Linking failed!"
    rm -f test.s test.o test.elf
    exit 1
fi

# Check what sections we have
echo "Checking ELF sections..."
riscv64-unknown-elf-objdump -h test.elf

# Extract binary (text + data, but not bss)
echo "Extracting binary..."
riscv64-unknown-elf-objcopy -O binary \
    -j .text -j .data -j .rodata \
    test.elf test.bin

# Convert to hexadecimal .dat file
echo "Converting to .dat format..."
hexdump -v -e '1/4 "%08x\n"' test.bin > test.dat

# Show size information
echo "=== Size Information ==="
echo "Size: $(wc -l < test.dat) words"

# Show memory layout
echo ""
echo "=== Memory Layout ==="
riscv64-unknown-elf-objdump -h test.elf | grep -E "\.text|\.data|\.rodata|\.bss"

# Move .dat file to target directory
mv test.dat "$ASSEMBLY_DIR/$TARGET_NAME"

# Generate COE file
echo "Generating .coe file..."
python3 "$SCRIPT_DIR/script/convert_coe.py" "$ASSEMBLY_DIR/$TARGET_NAME"

# Move COE file to target directory (if needed)
if [ -f "$COE_NAME" ]; then
    mv "$COE_NAME" "$ASSEMBLY_DIR/"
fi

# Clean up temporary files
rm -f test.s test.o test.elf test.bin

echo ""
echo "Success! Generated files:"
echo "  - $ASSEMBLY_DIR/$TARGET_NAME"
echo "  - $ASSEMBLY_DIR/$COE_NAME"