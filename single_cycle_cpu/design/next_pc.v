module next_pc(
    input [31: 0] pc,

    output reg [31: 0] next_pc
);

always @(*) begin
    if(pc == 32'd88) next_pc = 0;
    else next_pc = pc + 4;
end

endmodule