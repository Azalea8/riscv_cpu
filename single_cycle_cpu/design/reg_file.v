module reg_file(
    input rst, clk, write_reg,
    input [4: 0] rs1, rs2, target_reg,
    input [31: 0] write_rd_data,

    output reg [31: 0] read_rs1_data,
    output reg [31: 0] read_rs2_data
);

reg [31: 0] regs[31: 0];

always @(posedge rst) begin
    regs[0] = 32'h0000_0000;
    for(integer i = 1; i < 32;i = i + 1) begin
        regs[i] = 32'hffff_ffff;
    end
end

always @(posedge clk) begin
    if(write_reg) regs[target_reg] = write_rd_data;
end

always @(*) begin
    read_rs1_data = regs[rs1];
end

always @(*) begin
    read_rs2_data = regs[rs2];
end

endmodule