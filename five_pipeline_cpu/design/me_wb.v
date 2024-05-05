module me_wb(
    input clk, rst,
    input me_aluOut_WB_memOut,
    input me_writeReg,
    input [31: 0] me_outMem,
    input [31: 0] me_outAlu,
    input [4: 0] me_rd,

    output reg wb_aluOut_WB_memOut,
    output reg wb_writeReg,
    output reg [31: 0] wb_outMem,
    output reg [31: 0] wb_outAlu,
    output reg [4: 0] wb_rd
);

always @(posedge clk) begin
    wb_aluOut_WB_memOut <= me_aluOut_WB_memOut;
    wb_writeReg <= me_writeReg;
    wb_outMem <= me_outMem;
    wb_outAlu <= me_outAlu;
    wb_rd <= me_rd;
end

endmodule