module instruction_mem (
    input [31: 0] pc,

    output [31: 0] instruction
);

reg [31: 0] inst_mem[63: 0];

assign instruction = inst_mem[pc >> 2];

initial begin
    inst_mem[0] = {12'h1, 5'b0, 3'b000, 5'b1, 7'b0010011}; // addi
    inst_mem[1] = {12'h001, 5'b1, 3'b000, 5'h2, 7'b0010011}; // addi

    // R型指令
    inst_mem[2] = {7'b0, 5'b1, 5'h2, 3'b000, 5'h3, 7'b0110011}; // add
    inst_mem[3] = {7'b010_0000, 5'h2, 5'h3, 3'b000, 5'h4, 7'b0110011}; // sub
    inst_mem[4] = {7'b0, 5'h2, 5'h4, 3'b110, 5'h1, 7'b0110011}; // or
    inst_mem[5] = {7'b0, 5'b0, 5'h1, 3'b111, 5'h1, 7'b0110011}; // and
    inst_mem[6] = {7'b0, 5'd2, 5'd3, 3'b100, 5'd1, 7'b0110011}; // xor
    inst_mem[7] = {7'b0, 5'd1, 5'd3, 3'b001, 5'd3, 7'b0110011}; // sll
    inst_mem[8] = {7'b010_0000, 5'd3, 5'd1, 3'b000, 5'h1, 7'b0110011}; //sub
    inst_mem[9] = {7'b0, 5'd3, 5'd1, 3'b010, 5'd2, 7'b0110011}; // slt
    inst_mem[10] = {7'b0, 5'd3, 5'd1, 3'b011, 5'd2, 7'b0110011}; // sltu
    inst_mem[11] = {7'b0, 5'd2, 5'd1, 3'b101, 5'd1, 7'b0110011}; // srl
    inst_mem[12] = {7'b010_0000, 5'd4, 5'd1, 3'b101, 5'd1, 7'b0110011}; // sra

    inst_mem[13] = {12'hfff, 5'd1, 3'b010, 5'd2, 7'b0010011}; // slti
    inst_mem[14] = {12'hfff, 5'd2, 3'b011, 5'd2, 7'b0010011}; // sltiu
    inst_mem[15] = {12'h009, 5'd3, 3'b100, 5'd3, 7'b0010011}; // xori
    inst_mem[16] = {12'hffd, 5'd3, 3'b110, 5'd2, 7'b0010011}; // ori
    inst_mem[17] = {12'h1, 5'd2, 3'b111, 5'd2, 7'b0010011}; // andi
    inst_mem[18] = {12'h2, 5'd2, 3'b001, 5'd2, 7'b0010011}; //slli
    inst_mem[19] = {12'b1000000_00000, 5'd1, 3'b101, 5'd1, 7'b0010011}; // srli
    inst_mem[20] = {12'b1100000_00001, 5'd1, 3'b101, 5'd1, 7'b0010011}; // srai

    // S型指令
    inst_mem[21] = {7'h0, 5'd3, 5'd0, 3'b010, 5'd2, 7'b0100011}; // sw

    // L型指令
    inst_mem[22] = {12'd1, 5'd4, 3'b010, 5'd2, 7'b0000011}; // lw

    inst_mem[23] = {7'h0, 5'd1, 5'd4, 3'b001, 5'd5, 7'b0100011}; //sh

    inst_mem[24] = {12'd5, 5'd0, 3'b001, 5'd3, 7'b0000011}; // lh;

    inst_mem[25] = {7'h0, 5'd4, 5'd4, 3'b000, 5'd5, 7'b0100011}; // sb

    inst_mem[26] = {12'd6, 5'd0, 3'b000, 5'd3, 7'b0000011}; // lb

    inst_mem[27] = {12'd7, 5'd0, 3'b100, 5'd4, 7'b0000011}; // lbu

    inst_mem[28] = {12'd6, 5'd0, 3'b101, 5'd4, 7'b0000011}; // lhu

    inst_mem[29] = {1'b0, 10'd4, 1'b0, 8'b0, 5'd4, 7'b1101111}; // jal

    inst_mem[31] = {20'b1, 5'd4, 7'b0110111}; // lui

    inst_mem[32] = {20'b1, 5'd4, 7'b0010111}; // auipc

    inst_mem[33] = {12'd4, 5'd0, 3'b000, 5'd4, 7'b1100111}; // jalr
end

endmodule