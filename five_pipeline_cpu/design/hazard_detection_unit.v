module hazard_detection_unit(
    input [2: 0] ex_readMem,
    input [4: 0] ex_rd, id_rs1, id_rs2,

    output reg pause
);

always @(*) begin
    pause = 1'b0;
    if((ex_readMem != 3'b000) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
        pause = 1'b1;
    end
end

endmodule