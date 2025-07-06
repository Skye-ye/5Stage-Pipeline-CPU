#!/bin/bash

# Create unified memory image combining instructions and data
set -e

if [ ! -f "morse.elf" ]; then
    echo "Error: morse.elf not found. Run build.sh first."
    exit 1
fi

echo "Creating unified memory image..."

# Simple approach: extract complete binary from ELF
echo "Extracting complete binary from ELF..."
riscv64-unknown-elf-objcopy -O binary morse.elf unified.bin

# Check the size and pad to 4KB if needed
ACTUAL_SIZE=$(stat -c%s unified.bin 2>/dev/null || stat -f%z unified.bin)
TARGET_SIZE=16384

if [ $ACTUAL_SIZE -lt $TARGET_SIZE ]; then
    echo "Padding binary from $ACTUAL_SIZE to $TARGET_SIZE bytes"
    dd if=/dev/zero bs=1 count=$((TARGET_SIZE - ACTUAL_SIZE)) >> unified.bin 2>/dev/null
fi

# Convert to hex format for Verilog
echo "Converting to hex format..."
hexdump -v -e '1/4 "%08x\n"' unified.bin > program.dat

# Create COE file for Block RAM
echo "Creating COE file..."
cat > program.coe << 'EOF'
memory_initialization_radix=16;
memory_initialization_vector=
EOF

# Add hex values to COE file
sed 's/$/,/' program.dat | sed '$s/,$/;/' >> program.coe

# Cleanup temporary files
rm -f unified.bin

echo "Generated unified memory image:"
echo "  - program.dat ($(wc -l < program.dat) words)"
echo "  - program.coe (for Block RAM initialization)"
echo "Memory layout preserved with instructions and data at correct addresses."

# Also create program.hex for compatibility
cp program.dat program.hex