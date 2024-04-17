module instruction_mem (
    input [31: 0] pc,

    output [31: 0] instruction
);

reg [31: 0] inst_mem[15: 0];

assign instruction = inst_mem[pc >> 2];

initial begin
    // 指令
end

endmodule