# Default values
TARGET_NAME="target.dat"
TARGET_PATH="."
ASSEMBLY_CODE="your_assembly_code.s"

# Parse command line arguments
if [ $# -ge 1 ]; then
    TARGET_NAME=$1
fi

if [ $# -ge 2 ]; then
    TARGET_PATH=$2
fi

if [ $# -ge 3 ]; then
    ASSEMBLY_CODE=$3
fi

echo ".text" > test.s
echo ".globl _start" >> test.s  
echo "_start:" >> test.s
cat "$ASSEMBLY_CODE" >> test.s

# 3. 汇编和链接
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o test.o test.s
riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x00000000 -o test.elf test.o

# 4. 提取二进制代码
riscv64-unknown-elf-objcopy -O binary test.elf test.bin

# 5. 转换为十六进制格式的 .dat 文件
hexdump -v -e '1/4 "%08x\n"' test.bin > test.dat

# 修改生成的文件名
mv test.dat "$TARGET_NAME"

# 6. 生成 COE 文件
COE_NAME="${TARGET_NAME%.*}.coe"
python3 convert_coe.py "$TARGET_NAME"

mv "$COE_NAME" "$TARGET_PATH/"
mv "$TARGET_NAME" "$TARGET_PATH/"

# 清理中间文件
rm -f test.s test.o test.elf test.bin
