#!/bin/bash

# Build script for RV32I Morse Decoder with .rodata support

set -e

echo "Building RV32I Morse Decoder with .rodata support..."

# Clean
rm -f *.o *.elf *.bin *.dis *.hex *.coe rodata*.bin

# Compile C code (32-bit)
echo "Compiling..."
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -O1 -c morse.c -o morse.o

# Assemble startup code (32-bit)
echo "Assembling..."
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 startup.s -o startup.o

# Link with new linker script that places .rodata in data memory
echo "Linking..."
riscv64-unknown-elf-ld -m elf32lriscv -T linker.ld startup.o morse.o -o morse.elf --no-gc-sections

# Generate disassembly
riscv64-unknown-elf-objdump -d morse.elf > morse.dis

echo "Creating unified memory image..."
bash create_unified_image.sh

# Clean up temporary files
rm -f morse.o startup.o