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
wire [31: 0] in_alu_b;
wire [31: 0] out_alu;
wire [31: 0] out_mem;
wire [31: 0] pc;
wire [31: 0] next_pc;


wire [4:  0] rd, rs1, rs2;
wire [11: 0] imm_12;

// 控制信号
wire [3:  0] aluc;
wire aluOut_WB_memOut;
wire write_mem;
wire rs2Data_EX_imm32;
wire write_reg;


pc PC(
    .rst(rst),
    .clk(clk),
    .next_pc(next_pc),

    .pc(pc)
);

next_pc NEXT_PC(
    .pc(pc),

    .next_pc(next_pc)
);

id ID(
    .instruction(instruction),

    .aluc(aluc),
    .aluOut_WB_memOut(aluOut_WB_memOut),
    .write_mem(write_mem),
    .rs2Data_EX_imm32(rs2Data_EX_imm32),
    .write_reg(write_reg),

    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .imm_12(imm_12)
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

mux MUX_WB(
    .signal(aluOut_WB_memOut),
    .a(out_alu),
    .b(out_mem),

    .out(write_rd_data)
);

mux MUX_EX(
    .signal(rs2Data_EX_imm32),
    .a(read_rs2_data),
    .b(imm_32),

    .out(in_alu_b)
);

ext EXT(
    .imm_12(imm_12),

    .imm_32(imm_32)
);

alu ALU(
    .aluc(aluc),
    .a(read_rs1_data),
    .b(in_alu_b),

    .out(out_alu)
);

data_mem DATA_MEM(
    .clk(clk),
    .rst(rst),
    .write_mem(write_mem),
    .address(out_alu),
    .write_data(read_rs2_data),

    .out_mem(out_mem)
);
endmodule