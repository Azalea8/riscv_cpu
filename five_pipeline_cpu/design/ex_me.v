module ex_me(
    input clk, rst,
    input ex_aluOut_WB_memOut,
    input ex_writeReg,
    input [1: 0] ex_writeMem,
    input [2: 0] ex_readMem,
    input [1: 0] ex_pcImm_NEXTPC_rs1Imm,
    input ex_conditionBranch,
    input [31: 0] ex_pcImm,
    input [31: 0] ex_rs1Imm,
    input [31: 0] ex_outAlu,
    input [31: 0] ex_rs2Data,
    input [4: 0] ex_rd,

    output reg me_aluOut_WB_memOut,
    output reg me_writeReg,
    output reg [1: 0] me_writeMem,
    output reg [2: 0] me_readMem,
    output reg [1: 0] me_pcImm_NEXTPC_rs1Imm,
    output reg me_conditionBranch,
    output reg [31: 0] me_pcImm,
    output reg [31: 0] me_rs1Imm,
    output reg [31: 0] me_outAlu,
    output reg [31: 0] me_rs2Data,
    output reg [4: 0] me_rd
);

always @(posedge clk) begin
    me_aluOut_WB_memOut <= ex_aluOut_WB_memOut;
    me_writeReg <= ex_writeReg;
    me_writeMem <= ex_writeMem;
    me_readMem <= ex_readMem;
    me_pcImm_NEXTPC_rs1Imm <= ex_pcImm_NEXTPC_rs1Imm;
    me_conditionBranch <= ex_conditionBranch;
    me_pcImm <= ex_pcImm;
    me_rs1Imm <= ex_rs1Imm;
    me_outAlu <= ex_outAlu;
    me_rs2Data <= ex_rs2Data;
    me_rd <= ex_rd;
end

endmodule