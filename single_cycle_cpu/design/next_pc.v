module next_pc(
    input [31: 0] pc,

    output reg [31: 0] next_pc
);

always @(*) begin
    next_pc = pc + 4;
end

endmodule