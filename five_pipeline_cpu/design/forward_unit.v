module forward_unit(
    input me_writeReg, wb_writeReg,
    input [4: 0] me_rd, wb_rd,
    input [4: 0] ex_rs1, ex_rs2,
    input [4: 0] me_rs2,

    output reg [1: 0] ex_forwardA, ex_forwardB,
    output reg me_forwardC
);

always @(*) begin
    ex_forwardA = 2'b00;
    ex_forwardB = 2'b00;
    me_forwardC = 1'b0;

    if(wb_writeReg && (wb_rd != 5'd0) && (wb_rd == ex_rs1)) begin
        ex_forwardA = 2'b10;
    end

    if(wb_writeReg && (wb_rd != 5'd0) && (wb_rd == ex_rs2)) begin
        ex_forwardB = 2'b10;
    end

    if(me_writeReg && (me_rd != 5'd0) && (me_rd == ex_rs1)) begin
        ex_forwardA = 2'b01;
    end

    if(me_writeReg && (me_rd != 5'd0) && (me_rd == ex_rs2)) begin
        ex_forwardB = 2'b01;
    end

    // lw, sw数据冒险
    if(wb_writeReg && (wb_rd != 5'd0) && (wb_rd == me_rs2)) begin
        me_forwardC = 1'b1;
    end
end

endmodule