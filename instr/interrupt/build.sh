#!/bin/bash

# Build script for RV32I Interrupt Test

set -e

echo "Building RV32I Interrupt Test..."

# Clean
rm -f *.o *.elf *.bin *.dis *.hex *.coe

# Compile C code (32-bit)
echo "Compiling..."
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -O2 -c int.c -o int.o

# Assemble startup code (32-bit)
echo "Assembling..."
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 startup.s -o startup.o

# Link with new linker script that places .rodata in data memory
echo "Linking..."
riscv64-unknown-elf-ld -m elf32lriscv -T linker.ld startup.o int.o -o int.elf --no-gc-sections

# Generate disassembly
riscv64-unknown-elf-objdump -d int.elf > int.dis

echo "Creating unified memory image..."
bash create_image.sh

# Clean up temporary files
rm -f int.o startup.o