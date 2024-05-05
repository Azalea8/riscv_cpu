module next_pc(
    input [1: 0] pcImm_NEXTPC_rs1Imm,
    input condition_branch,
    input [31: 0] pc4, pcImm, rs1Imm,

    output reg [31: 0] next_pc
);

always @(*) begin
    if(pcImm_NEXTPC_rs1Imm == 2'b01) next_pc = pcImm;
    else if(pcImm_NEXTPC_rs1Imm == 2'b10) next_pc = rs1Imm;
    else if(condition_branch) next_pc = pcImm;
    else if(pc4 == 32'h6c) next_pc = 32'h6c;
    else next_pc = pc4;
end

endmodule