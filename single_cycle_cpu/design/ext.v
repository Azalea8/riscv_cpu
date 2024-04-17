module ext(
    input [11: 0] imm_12,

    output [31: 0] imm_32
);

assign imm_32 = imm_12[11] ? {20'hf_ffff, imm_12} : {20'h0_0000, imm_12};

endmodule