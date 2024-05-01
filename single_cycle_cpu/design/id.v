module id(
    input [31: 0] instr,

    output [6: 0] opcode,
    output [2: 0] func3,
    output [6: 0] func7,
    output [4: 0] rd,
    output [4: 0] rs1,
    output [4: 0] rs2
);

assign  opcode  = instr[6:0];
assign  rs1 = instr[19:15];
assign  rs2 = instr[24:20];
assign  rd  = instr[11:7];
assign  func3  = instr[14:12];
assign  func7  = instr[31:25];

endmodule;