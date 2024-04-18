module data_mem(
    input clk, rst, write_mem,
    input [31: 0] address, write_data,

    output reg [31: 0] out_mem
);

reg [31: 0] data [63: 0];

always @(*) begin
    if(address == 32'h0000_0000)begin
        out_mem = 32'h0000_0000;
    end else begin
        out_mem = data[address >> 2];
    end
end

always @(posedge clk) begin
    if(write_mem) data[address >> 2] = write_data;
end
endmodule