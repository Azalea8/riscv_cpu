module control_unit(
    input [6: 0] opcode, 
    input [2: 0] fun3,
    input [6: 0] fun7,

    output reg [1: 0] aluc,
    output reg aluOut_WB_memOut, write_mem, rs2Data_EX_imm32, write_reg
);

always @(*) begin
    
end

endmodule