module pc(
    input rst, clk,
    input [31: 0] next_pc,

    output reg [31: 0] pc
);

always @(posedge clk) begin
    if(rst) pc <= 32'h5c;
    else pc <= next_pc;
end

always @(posedge rst) begin
    pc = 0;
end

endmodule