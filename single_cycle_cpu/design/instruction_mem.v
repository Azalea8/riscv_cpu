module instruction_mem (
    input [31: 0] pc,

    output [31: 0] instruction
);

reg [31: 0] inst_mem[63: 0];

assign instruction = inst_mem[pc >> 2];

initial begin
    inst_mem[0] =	32'hfe010113;          	// addi	sp,sp,-32
    inst_mem[1] =	32'h00812e23;          	// sw	s0,28(sp)
    inst_mem[2] =	32'h02010413;          	// addi	s0,sp,32
    inst_mem[3] =	32'hfea42623;          	// sw	a0,-20(s0)
    inst_mem[4] =	32'hfec42783;          	// lw	a5,-20(s0)
    inst_mem[5] =	32'h0007a703;          	// lw	a4,0(a5)
    inst_mem[6] =	32'h00200793;          	// li	a5,2
    inst_mem[7] =	32'h00f71e63;          	// bne	a4,a5,38 <fun+0x38>
    inst_mem[8] =	32'hfec42783;          	// lw	a5,-20(s0)
    inst_mem[9] =	32'h0007a783;          	// lw	a5,0(a5)
    inst_mem[10] =	32'h00178713;          	// addi	a4,a5,1
    inst_mem[11] =	32'hfec42783;          	// lw	a5,-20(s0)
    inst_mem[12] =	32'h00e7a023;          	// sw	a4,0(a5)
    inst_mem[13] =	32'h01c0006f;          	// j	50 <fun+0x50>
    inst_mem[14] =	32'hfec42783;         	// lw	a5,-20(s0)
    inst_mem[15] =	32'h0007a783;          	// lw	a5,0(a5)
    inst_mem[16] =	32'h00a78713;          	// addi	a4,a5,10
    inst_mem[17] =	32'hfec42783;          	// lw	a5,-20(s0)
    inst_mem[18] =	32'h00e7a023;          	// sw	a4,0(a5)
    inst_mem[19] =	32'h00000013;          	// nop
    inst_mem[20] =	32'h01c12403;          	// lw	s0,28(sp)
    inst_mem[21] =	32'h02010113;          	// addi	sp,sp,32
    inst_mem[22] =	32'h00008067;          	// ret

    inst_mem[23] =	32'hfe010113;         	//addi	sp,sp,-32
    inst_mem[24] =	32'h00112e23;          	// sw	ra,28(sp)
    inst_mem[25] =	32'h00812c23;          	// sw	s0,24(sp)
    inst_mem[26] =	32'h02010413;          	// addi	s0,sp,32
    inst_mem[27] =	32'h00100793;          	// li	a5,1
    inst_mem[28] =	32'hfef42623;          	// sw	a5,-20(s0)
    inst_mem[29] =	32'hfec40793;          	// addi	a5,s0,-20
    inst_mem[30] =	32'h00078513;          	// mv	a0,a5
    inst_mem[31] =	32'hf85ff0ef;          	// jal	ra,0 <fun>
    inst_mem[32] =	32'h00000793;          	// li	a5,0
    inst_mem[33] =	32'h00078513;         	// mv	a0,a5
    inst_mem[34] =	32'h01c12083;          	// lw	ra,28(sp)
    inst_mem[35] =	32'h01812403;          	// lw	s0,24(sp)
    inst_mem[36] =	32'h02010113;          	// addi	sp,sp,32
    // inst_mem[0] =	32'h00008067;          	// ret

    inst_mem[37] = {12'h0, 5'b0, 3'b000, 5'b0, 7'b0010011}; // nop


    // inst_mem[0] = {12'h1, 5'b0, 3'b000, 5'b1, 7'b0010011}; // addi
    // inst_mem[1] = {12'h001, 5'b1, 3'b000, 5'h2, 7'b0010011}; // addi

    // // R型指令
    // inst_mem[2] = {7'b0, 5'b1, 5'h2, 3'b000, 5'h3, 7'b0110011}; // add
    // inst_mem[3] = {7'b010_0000, 5'h2, 5'h3, 3'b000, 5'h4, 7'b0110011}; // sub
    // inst_mem[4] = {7'b0, 5'h2, 5'h4, 3'b110, 5'h1, 7'b0110011}; // or
    // inst_mem[5] = {7'b0, 5'b0, 5'h1, 3'b111, 5'h1, 7'b0110011}; // and
    // inst_mem[6] = {7'b0, 5'd2, 5'd3, 3'b100, 5'd1, 7'b0110011}; // xor
    // inst_mem[7] = {7'b0, 5'd1, 5'd3, 3'b001, 5'd3, 7'b0110011}; // sll
    // inst_mem[8] = {7'b010_0000, 5'd3, 5'd1, 3'b000, 5'h1, 7'b0110011}; //sub
    // inst_mem[9] = {7'b0, 5'd3, 5'd1, 3'b010, 5'd2, 7'b0110011}; // slt
    // inst_mem[10] = {7'b0, 5'd3, 5'd1, 3'b011, 5'd2, 7'b0110011}; // sltu
    // inst_mem[11] = {7'b0, 5'd2, 5'd1, 3'b101, 5'd1, 7'b0110011}; // srl
    // inst_mem[12] = {7'b010_0000, 5'd4, 5'd1, 3'b101, 5'd1, 7'b0110011}; // sra

    // inst_mem[13] = {12'hfff, 5'd1, 3'b010, 5'd2, 7'b0010011}; // slti
    // inst_mem[14] = {12'hfff, 5'd2, 3'b011, 5'd2, 7'b0010011}; // sltiu
    // inst_mem[15] = {12'h009, 5'd3, 3'b100, 5'd3, 7'b0010011}; // xori
    // inst_mem[16] = {12'hffd, 5'd3, 3'b110, 5'd2, 7'b0010011}; // ori
    // inst_mem[17] = {12'h1, 5'd2, 3'b111, 5'd2, 7'b0010011}; // andi
    // inst_mem[18] = {12'h2, 5'd2, 3'b001, 5'd2, 7'b0010011}; //slli
    // inst_mem[19] = {12'b1000000_00000, 5'd1, 3'b101, 5'd1, 7'b0010011}; // srli
    // inst_mem[20] = {12'b1100000_00001, 5'd1, 3'b101, 5'd1, 7'b0010011}; // srai

    // // S型指令
    // inst_mem[21] = {7'h0, 5'd3, 5'd0, 3'b010, 5'd2, 7'b0100011}; // sw

    // // L型指令
    // inst_mem[22] = {12'd1, 5'd4, 3'b010, 5'd2, 7'b0000011}; // lw

    // inst_mem[23] = {7'h0, 5'd1, 5'd4, 3'b001, 5'd5, 7'b0100011}; //sh

    // inst_mem[24] = {12'd5, 5'd0, 3'b001, 5'd3, 7'b0000011}; // lh;

    // inst_mem[25] = {7'h0, 5'd4, 5'd4, 3'b000, 5'd5, 7'b0100011}; // sb

    // inst_mem[26] = {12'd6, 5'd0, 3'b000, 5'd3, 7'b0000011}; // lb

    // inst_mem[27] = {12'd7, 5'd0, 3'b100, 5'd4, 7'b0000011}; // lbu

    // inst_mem[28] = {12'd6, 5'd0, 3'b101, 5'd4, 7'b0000011}; // lhu

    // inst_mem[29] = {1'b0, 10'd4, 1'b0, 8'b0, 5'd4, 7'b1101111}; // jal

    // inst_mem[31] = {20'b1, 5'd4, 7'b0110111}; // lui

    // inst_mem[32] = {20'b1, 5'd4, 7'b0010111}; // auipc

    // inst_mem[33] = {12'd4, 5'd0, 3'b000, 5'd4, 7'b1100111}; // jalr
end

endmodule