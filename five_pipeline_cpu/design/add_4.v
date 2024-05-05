module add_4(
    input [31: 0] pc,

    output [31: 0] pc_4
);

assign pc_4 = pc + 4;

endmodule;