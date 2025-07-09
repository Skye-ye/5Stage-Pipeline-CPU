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
COE_OUTPUT="$ASSEMBLY_DIR/$COE_NAME"

# Check if .dat file exists
if [ ! -f "$ASSEMBLY_DIR/$TARGET_NAME" ]; then
    echo "Error: .dat file not found at $ASSEMBLY_DIR/$TARGET_NAME"
    exit 1
fi

# Create COE file header
cat > "$COE_OUTPUT" << 'EOF'
memory_initialization_radix=16;
memory_initialization_vector=
EOF

# Convert .dat to .coe format
# First, collect all hex values into an array
hex_values=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove whitespace and newlines
    line=$(echo "$line" | tr -d ' \t\n\r')
    
    # Skip empty lines
    if [ -n "$line" ]; then
        # Take first 8 characters (32-bit hex value)
        hex_value="${line:0:8}"
        hex_values+=("$hex_value")
    fi
done < "$ASSEMBLY_DIR/$TARGET_NAME"

# Write the hex values with proper comma formatting
for i in "${!hex_values[@]}"; do
    if [ $i -eq 0 ]; then
        # First line - no comma
        echo "${hex_values[i]}," >> "$COE_OUTPUT"
    elif [ $i -eq $((${#hex_values[@]} - 1)) ]; then
        # Last line - no comma, add semicolon
        echo "${hex_values[i]};" >> "$COE_OUTPUT"
    else
        # Middle lines - add comma
        echo "${hex_values[i]}," >> "$COE_OUTPUT"
    fi
done

echo "COE file generated successfully"

# Clean up temporary files
rm -f test.s test.o test.elf test.bin

echo ""
echo "Success! Generated files:"
echo "  - $ASSEMBLY_DIR/$TARGET_NAME"
echo "  - $ASSEMBLY_DIR/$COE_NAME"