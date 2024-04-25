module alu(
    input[4: 0] aluc,
    input [31: 0] a, b,

    output reg [31: 0] out, 
    output reg condition_branch
);

always @(*) begin
    condition_branch = 0;
    out = 32'b0;
    case (aluc)
        5'b00000: out = a + b;
        5'b00001: out = a - b;
        5'b00010: out = a & b;
        5'b00011: out = a | b;
        5'b00100: out = a ^ b;
        5'b00101: out = a << b;
        5'b00110: out = ($signed(a) < ($signed(b))) ? 32'b1 : 32'b0;
        5'b00111: out = (a < b) ? 32'b1 : 32'b0;
        5'b01000: out = a >> b;
        5'b01001: out = ($signed(a)) >>> b;
        5'b01010: begin 
            out = a + b;
            out[0] = 1'b0;
        end
        5'b01011: condition_branch = (a == b) ? 1'b1 : 1'b0;
        5'b01100: condition_branch = (a != b) ? 1'b1 : 1'b0;
        5'b01101: condition_branch = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;
        5'b01110: condition_branch = ($signed(a) >= $signed(b)) ? 1'b1 : 1'b0;
        5'b01111: condition_branch = (a < b) ? 1'b1: 1'b0;
        5'b10000: condition_branch = (a >= b) ? 1'b1: 1'b0;
        default: out = 32'b0;
    endcase
end

endmodule