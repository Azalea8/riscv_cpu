module alu(
    input[3: 0] aluc,
    input [31: 0] a, b,

    output reg [31: 0] out
);

always @(*) begin
    case (aluc)
        4'b0000: out = a + b;
        4'b0001: out = a - b;
        4'b0010: out = a & b;
        4'b0011: out = a | b;
        4'b0100: out = a ^ b;
        4'b0101: out = a << b;
        4'b0110: out = ($signed(a) < ($signed(b))) ? 32'b1 : 32'b0;
        4'b0111: out = (a < b) ? 32'b1 : 32'b0;
        4'b1000: out = a >> b;
        4'b1001: out = ($signed(a)) >>> b;
        default: out = 0;
    endcase
end

endmodule