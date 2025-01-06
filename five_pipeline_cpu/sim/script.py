import re

def generate_verilog(mem_file, asm_file):
    with open(asm_file, 'r') as asm_f, open(mem_file, 'w') as mem_f:
        lines = asm_f.readlines()
        
        index = 0
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('file format'):
                continue 

            match = re.match(r'^([0-9a-fA-F]+):\s+([0-9a-fA-F]{8})\s+(.+)$', line)
            if match:
                instruction = match.group(2)  # 机器码部分
                comment = match.group(3) if match.group(3) else ''  # 指令部分
                
                # 写入
                mem_f.write(f"inst_mem[{index}] = 32'h{instruction};        // {comment}\n")
                index += 1
            else:
                # 如果不符合指令格式，打印调试信息
                print(f"Invalid instruction format || {line}")

# 文件名
asm_file = 'main.s'
mem_file = 'instruction.text'

# 脚本写入，避免多次复制
generate_verilog(mem_file, asm_file)
