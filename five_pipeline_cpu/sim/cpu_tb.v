`timescale 1ns / 1ps

module test_cpu();

    reg clk, rst;
    
    cpu CPU(clk, rst);
    
    initial begin
        clk = 1'b0;
        rst = 1'b0;
        #1 rst = 1'b1;
        #1 rst = 1'b0;
    end

    always begin
        #1 clk = ~clk;
    end
    
endmodule