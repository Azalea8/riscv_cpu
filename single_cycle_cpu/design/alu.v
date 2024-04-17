module alu(
    input[1: 0] aluc,
    input [31: 0] a, b,

    output reg [31: 0] out
);

always @(*) begin
    case (aluc)
        2'b00: out = a + b;
        2'b01: out = a - b;
        2'b10: out = a & b;
        2'b11: out = a | b;
        default: out = 0;
    endcase
end

endmodule