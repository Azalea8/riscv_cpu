module mux_3(
    input [1: 0] signal,
    input [31: 0] a, b, c,

    output [31: 0] out
);

assign out = (signal == 2'b00) ? a :
             (signal == 2'b01) ? b : c;


endmodule