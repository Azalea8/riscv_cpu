module id(
    input [31: 0] instruction,

    output reg [3: 0] aluc,
    output reg aluOut_WB_memOut, write_reg, rs1Data_EX_PC,
    output reg [1: 0] rs2Data_EX_imm32_4,
    output reg write_mem_1B, write_mem_2B, write_mem_4B,
    output reg read_mem_1B, read_mem_2B, read_mem_4B,
    output reg extension_mem,
    output reg [1: 0] not_NEXTPC_pcImm_rs1Imm,

    output reg [4:  0] rd, rs1, rs2,
    output reg [31: 0] imm_32
);

wire [6: 0] opcode = instruction[6: 0];
wire [4: 0] _rd = instruction[11: 7];
wire [2: 0] func3 = instruction[14: 12];
wire [4: 0] _rs1 = instruction[19: 15];
wire [4: 0] _rs2 = instruction[24: 20];
wire [6: 0] func7 = instruction[31: 25];
wire [11: 0] _imm_12 = instruction[31: 20];
wire [19: 0] _imm_20 = instruction[31: 12];
reg [20: 0] imm_21;
reg [11: 0] imm_12;

always @(*) begin
    case (opcode)
        // lui
        7'b0110111:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = _rd;
            rs1 = 5'b0;
            rs2 = 5'b0;
            imm_32 = {_imm_20, 12'b0};
        end
        // auipc
        7'b0010111:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = _rd;
            rs1 = 5'b0;
            rs2 = 5'b0;
            imm_32 = {_imm_20, 12'b0};
        end
        // jal
        7'b1101111:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b11;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b01;

            rd = _rd;
            rs1 = 5'b0;
            rs2 = 5'b0;
            imm_21 = {_imm_20[19], _imm_20[7: 0], _imm_20[8], _imm_20[18: 9], 1'b0};
            imm_32 = {{11{imm_21[20]}}, imm_21};
        end
        // jalr
        7'b1100111:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b11;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b10;

            rd = _rd;
            rs1 = _rs1;
            rs2 = 5'b0;
            imm_32 = {{20{_imm_12[11]}}, _imm_12};
        end
        // L型指令
        7'b0000011:begin
            write_reg = 1;
            aluOut_WB_memOut = 1;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = _rd;
            rs1 = _rs1;
            rs2 = 5'h0;
            imm_32 = {{20{_imm_12[11]}}, _imm_12};
            case (func3)
                // lw
                3'b010:begin
                    read_mem_4B = 1; 
                end
                // lh
                3'b001:begin
                    read_mem_2B = 1;
                    extension_mem = 1;
                end
                // lb
                3'b000:begin
                    read_mem_1B = 1;
                    extension_mem = 1;
                end
                // lbu
                3'b100:begin
                    read_mem_1B = 1;
                    extension_mem = 0;
                end
                // lhu
                3'b101:begin
                    read_mem_2B = 1;
                    extension_mem = 0;
                end
                default: begin
                    write_reg = 0;
                    rd = 5'h0;
                    rs1 = 5'h0;
                    rs2 = 5'h0;
                end
            endcase
        end
        // S型指令
        7'b0100011:begin
            write_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            aluc = 4'b0000;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = 5'h0;
            rs1 = _rs1;
            rs2 = _rs2;
            imm_12 = {_imm_12[11: 5], _rd};
            imm_32 = {{20{imm_12[11]}}, imm_12};
            case (func3)
                // sw
                3'b010:begin
                    write_mem_4B = 1;
                end
                // sh
                3'b001:begin
                    write_mem_2B = 1;
                end
                // sb
                3'b000:begin
                    write_mem_1B = 1;
                end
                default: begin
                    write_reg = 0;
                    rd = 5'h0;
                    rs1 = 5'h0;
                    rs2 = 5'h0;
                end
            endcase
        end
        // I型指令
        7'b0010011:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = _rd;
            rs1 = _rs1;
            rs2 = 5'h0;
            imm_32 = {{20{_imm_12[11]}}, _imm_12};
            case (func3)
                // addi
                3'b000:begin
                    aluc = 4'b0000;
                end
                // slti
                3'b010:begin
                    aluc = 4'b0110;
                end
                // sltiu
                3'b011:begin
                    aluc = 4'b0111;
                end
                // xori
                3'b100:begin
                    aluc = 4'b0100;
                end
                // ori
                3'b110:begin
                    aluc = 4'b0011;
                end
                // andi
                3'b111:begin
                    aluc = 4'b0010;
                end
                // slli
                3'b001:begin
                    aluc = 4'b0101;
                    imm_12 = {7'b0 ,_imm_12[4: 0]};
                    imm_32 = {{20{imm_12[11]}}, imm_12};
                end
                // srli, srai
                3'b101:begin
                    imm_12 = {7'b0 ,_imm_12[4: 0]};
                    imm_32 = {{20{imm_12[11]}}, imm_12};
                    if(func7[5]) aluc = 4'b1001;
                    else aluc = 4'b1000;
                end
                default:begin
                    write_reg = 0;
                    rd = 5'h0;
                    rs1 = 5'h0;
                    rs2 = 5'h0;
                end
            endcase
        end
        // R型指令
        7'b0110011:begin
            write_reg = 1;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b00;
            write_mem_4B = 0; write_mem_2B = 0; write_mem_1B = 0;
            read_mem_4B = 0; read_mem_2B = 0; read_mem_1B = 0;
            extension_mem = 0;
            not_NEXTPC_pcImm_rs1Imm = 2'b00;

            rd = _rd;
            rs1 = _rs1;
            rs2 = _rs2;
            imm_12 = 12'b0;
            imm_32 = {{20{imm_12[11]}}, imm_12};
            case (func3)
                // sub, add
                3'b000:begin
                    if(func7[5])begin
                        aluc = 4'b0001;
                    end else begin
                        aluc = 4'b0000;
                    end
                end
                // or
                3'b110:begin
                    aluc = 4'b0011;
                end
                // and
                3'b111:begin
                    aluc = 4'b0010;
                end
                // xor
                3'b100:begin
                    aluc = 4'b0100;
                end
                // sll
                3'b001:begin
                    aluc = 4'b0101;
                end
                // slt
                3'b010:begin
                    aluc = 4'b0110;
                end
                // sltu
                3'b011:begin
                    aluc = 4'b0111;
                end
                // srl, sra
                3'b101:begin
                    if(func7[5]) aluc = 4'b1001;
                    else aluc = 4'b1000;
                end 
                default: begin
                    write_reg = 0;
                    rd = 5'h0;
                    rs1 = 5'h0;
                    rs2 = 5'h0;
                end
            endcase
        end
        default: begin
            write_reg = 0;
            rd = 5'h0;
            rs1 = 5'h0;
            rs2 = 5'h0;
        end
    endcase
end
endmodule