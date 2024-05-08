module pc(
    input rst, clk, pause,
    input [31: 0] next_pc,

    output reg [31: 0] pc
);

always @(posedge clk) begin
    if(rst) begin
        pc = 32'd52;
    end else if(pause) begin
        // 空操作
        // 阻止寄存器值改变
    end else begin
        pc <= next_pc;
    end 
end

always @(posedge rst) begin
    pc = 0;
end

endmodule