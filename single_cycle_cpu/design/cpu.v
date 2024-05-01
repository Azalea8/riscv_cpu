`timescale 1ns / 1ps

module cpu(
    input clk, rst
);

// 数据
wire [31: 0] instruction; // 指令
wire [31: 0] write_rd_data; // 寄存器 rd数据
wire [31: 0] read_rs1_data; // 寄存器 rs1的数据
wire [31: 0] read_rs2_data; // 寄存器 rs2的数据
wire [31: 0] imm_32; // 32位立即数
wire [31: 0] in_alu_a; // 输入给运算器的 a口
wire [31: 0] in_alu_b; // 输入给运算器的 b口
wire [31: 0] out_alu; // ALU的运算结果
wire [31: 0] out_mem; // 从内存中读的数据
wire [31: 0] pc; // 当前指令的内存地址
wire [31: 0] next_pc; // 下一条指令地址


wire [4:  0] rd, rs1, rs2; // 寄存器地址
wire [6: 0] opcode;
wire [2: 0] func3;
wire [6: 0] func7;

// 控制信号
wire [4:  0] aluc; // 控制 ALU运算
wire aluOut_WB_memOut; // 二路选择器
wire rs1Data_EX_PC; // 二路选择器
wire[1: 0] rs2Data_EX_imm32_4; // 三路选择器
wire write_reg; // 寄存器写信号
wire [1: 0] write_mem; // 写内存信号
wire [2: 0] read_mem; // 读内存信号
wire [2: 0] extOP; // 立即数产生信号
wire[1: 0] pcImm_NEXTPC_rs1Imm; // 无条件跳转
wire condition_branch; // 条件跳转

pc PC(
    .rst(rst),
    .clk(clk),
    .next_pc(next_pc),

    .pc(pc)
);

next_pc NEXT_PC(
    .pcImm_NEXTPC_rs1Imm(pcImm_NEXTPC_rs1Imm),
    .condition_branch(condition_branch),
    .pc(pc),
    .offset(imm_32),
    .rs1Data(read_rs1_data),

    .next_pc(next_pc)
);

controller CONTROLLER(
    .opcode(opcode),
    .func3(func3),
    .func7(func7),

    .aluc(aluc),
    .aluOut_WB_memOut(aluOut_WB_memOut),
    .rs1Data_EX_PC(rs1Data_EX_PC),
    .rs2Data_EX_imm32_4(rs2Data_EX_imm32_4),
    .write_reg(write_reg),
    .write_mem(write_mem),
    .read_mem(read_mem),
    .extOP(extOP),
    .pcImm_NEXTPC_rs1Imm(pcImm_NEXTPC_rs1Imm)
);

imm IMM(
    .instr(instruction),
    .extOP(extOP),

    .imm_32(imm_32)
);

id ID(
    .instr(instruction),

    // 译码的相关数据
    .opcode(opcode),
    .func3(func3),
    .func7(func7),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2)
);

instruction_mem INSTRUCTION_MEM(
    .pc(pc),

    .instruction(instruction)
);

reg_file REG_FILE(
    .rst(rst),
    .clk(clk),
    .write_reg(write_reg),
    .rs1(rs1),
    .rs2(rs2),
    .target_reg(rd),
    .write_rd_data(write_rd_data),

    .read_rs1_data(read_rs1_data),
    .read_rs2_data(read_rs2_data)
);

mux_2 MUX_WB(
    .signal(aluOut_WB_memOut),
    .a(out_alu),
    .b(out_mem),

    .out(write_rd_data)
);

mux_3 MUX_EX_B(
    .signal(rs2Data_EX_imm32_4),
    .a(read_rs2_data),
    .b(imm_32),
    .c(32'd4),

    .out(in_alu_b)
);

mux_2 MUX_EX_A(
    .signal(rs1Data_EX_PC),
    .a(read_rs1_data),
    .b(pc),

    .out(in_alu_a)
);

alu ALU(
    .aluc(aluc),
    .a(in_alu_a),
    .b(in_alu_b),

    .out(out_alu),
    .condition_branch(condition_branch)
);

data_mem DATA_MEM(
    .clk(clk),
    .rst(rst),
    .address(out_alu),
    .write_data(read_rs2_data),
    .write_mem(write_mem),
    .read_mem(read_mem),

    .out_mem(out_mem)
);
endmodule