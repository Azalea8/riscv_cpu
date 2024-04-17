module data_mem(
    input clk, rst, write_mem,
    input [31: 0] address, write_data,

    output [31: 0] out_mem
);

reg [31: 0] data [63: 0];

always @(posedge rst) begin
    for(integer i = 0;i < 64;i = i + 1)begin
        data[i] = 32'h0000_0000;
    end
end

assign out_mem = data[address];

always @(negedge clk) begin
    if(write_mem) data[address] = write_data;
end
endmodule