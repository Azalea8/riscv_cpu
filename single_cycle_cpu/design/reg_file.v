module reg_file(
    input rst, clk, write_reg,
    input [4: 0] rs1, rs2, target_reg,
    input [31: 0] write_rd_data,

    output reg [31: 0] read_rs1_data,
    output reg [31: 0] read_rs2_data
);

reg [31: 0] regs[31: 0];

always @(posedge clk) begin
    if(write_reg && target_reg != 5'h0) regs[target_reg] = write_rd_data;
end

initial begin
    regs[5'd2] = 32'd128;
end

always @(*) begin
    if(rs1 == 5'h0)begin
        read_rs1_data = 32'h0000_0000;
    end else begin
        read_rs1_data = regs[rs1];
    end
end

always @(*) begin
    if(rs2 == 5'h0)begin
        read_rs2_data = 32'h0000_0000;
    end else begin
        read_rs2_data = regs[rs2];
    end
end

endmodule