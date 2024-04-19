module data_mem(
    input clk, rst, 
    input write_mem_4B, write_mem_2B, write_mem_1B, 
    input read_mem_4B, read_mem_2B, read_mem_1B,
    input extension_mem,

    input [31: 0] address, write_data,

    output reg [31: 0] out_mem
);

reg [7: 0] data [63: 0];

always @(*) begin
    if(read_mem_4B)begin
        out_mem = {data[address + 3], data[address + 2], data[address + 1], data[address]};
    end 
    else if (read_mem_2B) begin
        if(extension_mem) out_mem = {{16{data[address + 1][7]}}, data[address + 1], data[address]};
        else out_mem = {16'b0, data[address + 1], data[address]};
    end
    else if (read_mem_1B) begin
        if(extension_mem) out_mem = {{24{data[address][7]}}, data[address]};
        else out_mem = {24'b0, data[address]};
    end else begin
        out_mem = 32'b0;
    end
end

always @(posedge clk) begin
    if(write_mem_4B)begin
        data[address + 3] = write_data[31: 24];
        data[address + 2] = write_data[23: 16];
        data[address + 1] = write_data[15: 8];
        data[address] = write_data[7: 0];
    end else if (write_mem_2B) begin
        data[address + 1] = write_data[15: 8];
        data[address] = write_data[7: 0];
    end else if(write_mem_1B) begin
        data[address] = write_data[7: 0];
    end
end
endmodule