module next_pc(
    input [1: 0] pcImm_NEXTPC_rs1Imm,
    input condition_branch,
    input [31: 0] pc4, pcImm, rs1Imm,

    output reg [31: 0] next_pc,
    output reg flush
);

always @(*) begin
    if(pcImm_NEXTPC_rs1Imm == 2'b01) begin
        next_pc = pcImm;
        flush = 1'b1;
    end else if(pcImm_NEXTPC_rs1Imm == 2'b10) begin 
        next_pc = rs1Imm;
        flush = 1'b1;
    end else if(condition_branch) begin 
        next_pc = pcImm;
        flush = 1'b1;
    end else if(pc4 == 32'h98) begin 
        next_pc = 32'h94;
        flush = 1'b0;
    end else begin 
        next_pc = pc4;
        flush = 1'b0;
    end
end

endmodule