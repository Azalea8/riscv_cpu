module next_pc(
    input [1: 0] not_NEXTPC_pcImm_rs1Imm,
    input [31: 0] pc, offset, rs1Data,

    output reg [31: 0] next_pc
);

always @(*) begin
    if(not_NEXTPC_pcImm_rs1Imm == 2'b01) next_pc = pc + offset;
    else if(not_NEXTPC_pcImm_rs1Imm == 2'b10) next_pc = rs1Data + offset;
    else if(pc == 32'd132) next_pc = 0;
    else next_pc = pc + 4;
end

endmodule