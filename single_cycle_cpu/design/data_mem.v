module data_mem(
    input clk, rst, 
    input [1: 0] write_mem, 
    input [2: 0] read_mem,

    input [31: 0] address, write_data,

    output reg [31: 0] out_mem
);

reg [7: 0] data [127: 0];

always @(*) begin
    case (read_mem[1: 0])
        2'b00:begin
            out_mem = 32'b0;
        end
        2'b01:begin
            out_mem = {data[address + 3], data[address + 2], data[address + 1], data[address]};
        end
        2'b10:begin
            if(read_mem[2]) out_mem = {{16{data[address + 1][7]}}, data[address + 1], data[address]};
            else out_mem = {16'b0, data[address + 1], data[address]};
        end
        2'b11:begin
            if(read_mem[2]) out_mem = {{24{data[address][7]}}, data[address]};
            else out_mem = {24'b0, data[address]};
        end 
        default:begin
            out_mem = 32'b0;
        end
    endcase
end

always @(posedge clk) begin
    case (write_mem)
        2'b01:begin
            data[address + 3] = write_data[31: 24];
            data[address + 2] = write_data[23: 16];
            data[address + 1] = write_data[15: 8];
            data[address] = write_data[7: 0];
        end
        2'b10:begin
            data[address + 1] = write_data[15: 8];
            data[address] = write_data[7: 0];
        end
        2'b11:begin
            data[address] = write_data[7: 0];
        end 
        default: begin
            
        end
    endcase
end
endmodule