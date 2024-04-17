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

// 指令译码
wire [6:  0] opcode;
wire [2:  0] func3;
wire [6:  0] func7;
wire [5:  0] rd, rs1, rs2;
wire [11: 0] imm_12;

// 控制信号
wire [1:  0] aluc;
wire [0:  0] aluOut_WB_memOut;
wire [0:  0] write_mem;
wire [0:  0] rs2Data_EX_imm32;
wire [0:  0] write_reg;

assign opcode = instruction[6: 0];
assign rd = instruction[11: 7];
assign func3 = instruction[14: 12];
assign rs1 = instruction[19: 15];
assign rs2 = instruction[24: 20];
assign func7 = instruction[31: 25];
assign imm_12 = instruction[31: 20];

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

control_unit CONTROL_UNIT(
    .opcode(opcode),
    .func3(func3),
    .func7(func7),

    .aluc(aluc),
    .aluOut_WB_memOut(aluOut_WB_memOut),
    .write_mem(write_mem),
    .rs2Data_EX_imm32(rs2Data_EX_imm32),
    .write_reg(write_reg)
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