module if_id(
    input clk, rst, pause, flush,
    input [31: 0] if_pc,
    input [31: 0] if_instr,

    output reg [31: 0] id_pc,
    output reg [31: 0] id_instr
);

always @(posedge clk) begin
    if(rst || flush) begin
        id_pc = 32'd0;
        id_instr = {12'h0, 5'b0, 3'b000, 5'b0, 7'b0010011};
    end else if(pause) begin
        // 空操作
        // 阻止寄存器值改变
    end else begin
        id_pc <= if_pc;
        id_instr <= if_instr;
    end
end

endmodule