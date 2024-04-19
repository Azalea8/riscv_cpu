`timescale 1ns / 1ps

module cpu(
    input clk, rst
);

// 数据
wire [31: 0] instruction;
wire [31: 0] write_rd_data;
wire [31: 0] read_rs1_data;
wire [31: 0] read_rs2_data;
wire [31: 0] imm_32;
wire [31: 0] in_alu_a;
wire [31: 0] in_alu_b;
wire [31: 0] in_alu_b_temp;
wire [31: 0] out_alu;
wire [31: 0] out_mem;
wire [31: 0] pc;
wire [31: 0] next_pc;


wire [4:  0] rd, rs1, rs2;

// 控制信号
wire [3:  0] aluc;
wire aluOut_WB_memOut;
wire rs1Data_EX_PC;
wire[1: 0] rs2Data_EX_imm32_4;
wire write_reg;
wire write_mem_4B, write_mem_2B, write_mem_1B;
wire read_mem_4B, read_mem_2B, read_mem_1B;
wire extension_mem;
wire[1: 0] not_NEXTPC_pcImm_rs1Imm;

pc PC(
    .rst(rst),
    .clk(clk),
    .next_pc(next_pc),

    .pc(pc)
);

next_pc NEXT_PC(
    .not_NEXTPC_pcImm_rs1Imm(not_NEXTPC_pcImm_rs1Imm),
    .pc(pc),
    .offset(imm_32),
    .rs1Data(read_rs1_data),
    .next_pc(next_pc)
);

id ID(
    .instruction(instruction),

    // 传出的控制信号
    .aluc(aluc),
    .aluOut_WB_memOut(aluOut_WB_memOut),
    .rs1Data_EX_PC(rs1Data_EX_PC),
    .rs2Data_EX_imm32_4(rs2Data_EX_imm32_4),
    .write_reg(write_reg),
    .write_mem_1B(write_mem_1B), .write_mem_2B(write_mem_2B), .write_mem_4B(write_mem_4B),
    .read_mem_1B(read_mem_1B), .read_mem_2B(read_mem_2B), .read_mem_4B(read_mem_4B),
    .extension_mem(extension_mem),
    .not_NEXTPC_pcImm_rs1Imm(not_NEXTPC_pcImm_rs1Imm),

    // 译码的相关数据
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm_32(imm_32)
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

    .out(out_alu)
);

data_mem DATA_MEM(
    .clk(clk),
    .rst(rst),
    .address(out_alu),
    .write_data(read_rs2_data),
    .write_mem_1B(write_mem_1B), .write_mem_2B(write_mem_2B), .write_mem_4B(write_mem_4B),
    .read_mem_1B(read_mem_1B), .read_mem_2B(read_mem_2B), .read_mem_4B(read_mem_4B),
    .extension_mem(extension_mem),

    .out_mem(out_mem)
);
endmodule