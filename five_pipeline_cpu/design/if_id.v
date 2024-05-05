module if_id(
    input clk, rst,
    input [31: 0] if_pc,
    input [31: 0] if_instr,

    output reg [31: 0] id_pc,
    output reg [31: 0] id_instr
);

always @(posedge clk) begin
    id_pc <= if_pc;
    id_instr <= if_instr;
end

endmodule