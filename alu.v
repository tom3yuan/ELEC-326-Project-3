`timescale 1ns/1ns

`define NOP 4'b0000
`define ARITH_2OP 4'b0001
`define ARITH_1OP 4'b0010
`define MOVI 4'b0011
`define ADDI 4'b0100
`define SUBI 4'b0101
`define LOAD 4'b0110
`define STOR 4'b0111
`define BEQ 4'b1000
`define BGE 4'b1001
`define BLE 4'b1010
`define BC 4'b1011
`define J 4'b1100
`define CONTROL 4'b1111

`define ADD 3'b000
`define ADDC 3'b001
`define SUB 3'b010
`define SUBB 3'b011
`define AND 3'b100
`define OR 3'b101
`define XOR 3'b110
`define XNOR 3'b111

`define NOT 3'b000
`define SHIFTL 3'b001
`define SHIFTR 3'b010
`define CP 3'b011

`define STC    12'b000000000001
`define STB    12'b000000000010
`define RESET  12'b101010101010
`define HALT   12'b111111111111


module alu (
    input             arith_1op_pi,
    input             arith_2op_pi,
    input  [2:0]      alu_func_pi,
    input             addi_pi,
    input             subi_pi,
    input             load_or_store_pi,
    input  [15:0]     reg1_data_pi,
    input  [15:0]     reg2_data_pi,
    input  [5:0]      immediate_pi,
    input             stc_cmd_pi,
    input             stb_cmd_pi,
    input             carry_in_pi,
    input             borrow_in_pi,

    output reg [15:0] alu_result_po,
    output reg        carry_out_po,
    output reg        borrow_out_po
);

    reg [16:0] tmp;

    always @(*) begin
        alu_result_po = 16'b0;
        carry_out_po  = carry_in_pi;
        borrow_out_po = borrow_in_pi;

        if (arith_1op_pi) begin
            case (alu_func_pi)
                `NOT:    alu_result_po = ~reg1_data_pi;
                `SHIFTL: alu_result_po = reg1_data_pi << 1;
                `SHIFTR: alu_result_po = reg1_data_pi >> 1;
                `CP:     alu_result_po = reg1_data_pi;
                default: alu_result_po = 16'b0;
            endcase

        end else if (arith_2op_pi) begin
            case (alu_func_pi)
                `ADD: begin
                    tmp = {1'b0, reg1_data_pi} + {1'b0, reg2_data_pi};
                    alu_result_po = tmp[15:0];
                    carry_out_po  = tmp[16];
                end

                `ADDC: begin
                    tmp = {1'b0, reg1_data_pi} + {1'b0, reg2_data_pi} + carry_in_pi;
                    alu_result_po = tmp[15:0];
                    carry_out_po  = tmp[16];
                end

                `SUB: begin
                    tmp = {1'b0, reg1_data_pi} - {1'b0, reg2_data_pi};
                    alu_result_po = tmp[15:0];
                    borrow_out_po = tmp[16];
                end

                `SUBB: begin
                    tmp = {1'b0, reg1_data_pi} - {1'b0, reg2_data_pi} - borrow_in_pi;
                    alu_result_po = tmp[15:0];
                    borrow_out_po = tmp[16];
                end

                `AND:  alu_result_po = reg1_data_pi & reg2_data_pi;
                `OR:   alu_result_po = reg1_data_pi | reg2_data_pi;
                `XOR:  alu_result_po = reg1_data_pi ^ reg2_data_pi;
                `XNOR: alu_result_po = ~(reg1_data_pi ^ reg2_data_pi);

                default: alu_result_po = 16'b0;
            endcase

        end else if (load_or_store_pi) begin
            tmp = {1'b0, reg1_data_pi} + {{11{1'b0}}, immediate_pi};
            alu_result_po = tmp[15:0];

        end else if (addi_pi) begin
            tmp = {1'b0, reg1_data_pi} + {{11{1'b0}}, immediate_pi};
            alu_result_po = tmp[15:0];
            carry_out_po  = tmp[16];

        end else if (subi_pi) begin
            tmp = {1'b0, reg1_data_pi} - {{11{1'b0}}, immediate_pi};
            alu_result_po = tmp[15:0];
            borrow_out_po = tmp[16];

        end else if (stc_cmd_pi) begin
            alu_result_po = 16'b0;
            carry_out_po  = 1'b1;

        end else if (stb_cmd_pi) begin
            alu_result_po = 16'b0;
            borrow_out_po = 1'b1;

        end else begin
            alu_result_po = 16'b0;
        end
    end

endmodule
