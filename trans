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

echo "Processing: $ASSEMBLY_FILE"
echo "Output directory: $ASSEMBLY_DIR"
echo "Output files: $TARGET_NAME, $COE_NAME"

# Create temporary assembly file with required headers
echo ".text" > test.s
echo ".globl _start" >> test.s  
echo "_start:" >> test.s
cat "$ASSEMBLY_FILE" >> test.s

# Assemble and link
echo "Assembling and linking..."
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o test.o test.s
if [ $? -ne 0 ]; then
    echo "Error: Assembly failed!"
    rm -f test.s test.o
    exit 1
fi

riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x00000000 -o test.elf test.o
if [ $? -ne 0 ]; then
    echo "Error: Linking failed!"
    rm -f test.s test.o test.elf
    exit 1
fi

# Extract binary code
echo "Extracting binary..."
riscv64-unknown-elf-objcopy -O binary test.elf test.bin

# Convert to hexadecimal .dat file
echo "Converting to .dat format..."
hexdump -v -e '1/4 "%08x\n"' test.bin > test.dat

# Move .dat file to target directory
mv test.dat "$ASSEMBLY_DIR/$TARGET_NAME"

# Generate COE file
echo "Generating .coe file..."
# Get the script directory (where trans.sh is located)
SCRIPT_DIR=$(dirname "$0")
python3 "$SCRIPT_DIR/script/convert_coe.py" "$ASSEMBLY_DIR/$TARGET_NAME"

# Move COE file to target directory (it should already be there, but just in case)
if [ -f "$COE_NAME" ]; then
    mv "$COE_NAME" "$ASSEMBLY_DIR/"
fi

# Clean up temporary files
rm -f test.s test.o test.elf test.bin

echo "Success! Generated files:"
echo "  - $ASSEMBLY_DIR/$TARGET_NAME"
echo "  - $ASSEMBLY_DIR/$COE_NAME"