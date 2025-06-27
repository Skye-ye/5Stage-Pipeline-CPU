import sys
import os

def convert_dat_to_coe(input_filename):
    # 检查输入文件是否存在
    if not os.path.exists(input_filename):
        print(f"错误: 文件 '{input_filename}' 不存在")
        return False
    
    # 生成输出文件名，将 .dat 扩展名替换为 .coe
    base_name = os.path.splitext(input_filename)[0]
    output_filename = base_name + '.coe'
    
    try:
        # 读取输入文件
        with open(input_filename, 'r') as file1:
            lines = file1.readlines()
        
        # 写入输出文件
        with open(output_filename, 'w') as file2:
            file2.write("memory_initialization_radix=16;\n")
            file2.write("memory_initialization_vector=\n")
            
            count = 0
            for line in lines:
                if count == 0:
                    file2.write("{}".format(line[0:8]))
                    count = 1
                else:
                    file2.write(",\n{}".format(line[0:8]))
            
            file2.write(";")
        
        print(f"成功转换: {input_filename} -> {output_filename}")
        return True
        
    except Exception as e:
        print(f"转换过程中出错: {e}")
        return False

def main():
    # 检查命令行参数
    if len(sys.argv) != 2:
        print("用法: python prep-coe-code.py <输入文件名>")
        print("示例: python prep-coe-code.py riscv-studentnosorting.dat")
        sys.exit(1)
    
    input_filename = sys.argv[1]
    convert_dat_to_coe(input_filename)

if __name__ == "__main__":
    main()