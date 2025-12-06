`timescale 1ns/1ns

module processor (
    input        CLK,
    input  [7:0] SW,
    input  [3:0] BTN,
    output [7:0] LED, 
    output [6:0] SEG,
    output       DP,
    output [3:0] AN
);

    assign DP = 1'b1; 
    assign LED = 8'b00000000;

    wire cpu_clk_en;

    wire CPU_RESET_pi = BTN[0];

    wire [15:0] pc;
    wire [15:0] instruction;

    wire [2:0] alu_func;
    wire [2:0] rd;
    wire [2:0] rs1;
    wire [2:0] rs2;
    wire [11:0] imm;

    wire arith2;
    wire arith1;
    wire movi_lo;
    wire movi_hi;
    wire addi;
    wire subi;
    wire ld;
    wire st;
    wire beq;
    wire bge;
    wire ble;
    wire bc;
    wire jump;
    wire stc_cmd;
    wire stb_cmd;
    wire halt_cmd;
    wire rst_cmd;

    wire [15:0] reg1_data;
    wire [15:0] reg2_data;
    wire [15:0] regD_data;
    wire carry_flag;
    wire borrow_flag;

    wire [15:0] alu_result;
    wire alu_carry;
    wire alu_borrow;

    wire is_branch_taken;

    wire [15:0] data_out;

    wire reset        = CPU_RESET_pi | rst_cmd;     
    wire clock_enable = cpu_clk_en & ~halt_cmd;  

   
    display_clkdiv #(.SIZE(12)) cpu_clock_div (
        .clk_pi(CLK),
        .clk_en_po(cpu_clk_en)
    );

    decoder myDecoder(
        .instruction_pi(instruction),

        .alu_func_po(alu_func),
        .destination_reg_po(rd),
        .source_reg1_po(rs1),
        .source_reg2_po(rs2),

        .immediate_po(imm),

        .arith_2op_po(arith2),
        .arith_1op_po(arith1),

        .movi_lower_po(movi_lo),
        .movi_higher_po(movi_hi),

        .addi_po(addi),
        .subi_po(subi),

        .load_po(ld),
        .store_po(st),

        .branch_eq_po(beq),
        .branch_ge_po(bge),
        .branch_le_po(ble),
        .branch_carry_po(bc),

        .jump_po(jump),

        .stc_cmd_po(stc_cmd),
        .stb_cmd_po(stb_cmd),
        .halt_cmd_po(halt_cmd),
        .rst_cmd_po(rst_cmd)
    ); 

    alu myALU(
        .arith_1op_pi(arith1),
        .arith_2op_pi(arith2),
        .alu_func_pi(alu_func),
        .addi_pi(addi),
        .subi_pi(subi),
        .load_or_store_pi(ld | st),
        .reg1_data_pi(reg1_data),
        .reg2_data_pi(reg2_data),
        .immediate_pi(imm[5:0]),
        .stc_cmd_pi(stc_cmd),
        .stb_cmd_pi(stb_cmd),
        .carry_in_pi(carry_flag),
        .borrow_in_pi(borrow_flag),

        .alu_result_po(alu_result),
        .carry_out_po(alu_carry),
        .borrow_out_po(alu_borrow)
    );

    branch myBranch( 
        .branch_eq_pi(beq),
        .branch_ge_pi(bge),
        .branch_le_pi(ble),
        .branch_carry_pi(bc),
        .reg1_data_pi(reg1_data),
        .reg2_data_pi(reg2_data),
        .alu_carry_bit_pi(alu_carry),
        .is_branch_taken_po(is_branch_taken)
    );

    regfile   myRegfile(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .reset_pi(reset),

        .source_reg1_pi(rs1),
        .source_reg2_pi(rs2),

        .destination_reg_pi(rd),
        .dest_result_data_pi((ld) ? data_out : alu_result),
        .wr_destination_reg_pi(arith1 | arith2 | addi | subi | ld),

        .movi_lower_pi(movi_lo),
        .movi_higher_pi(movi_hi),
        .immediate_pi(imm[7:0]),

        .new_carry_pi(alu_carry),
        .new_borrow_pi(alu_borrow),

        .reg1_data_po(reg1_data),
        .reg2_data_po(reg2_data),

        .current_carry_po(carry_flag),
        .current_borrow_po(borrow_flag),

        .regD_data_po(regD_data)
    );

    program_counter myProgram_counter(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .reset_pi(reset),

        .branch_taken_pi(is_branch_taken),
        .branch_immediate_pi(imm[5:0]),
        .jump_taken_pi(jump),
        .jump_immediate_pi(imm[11:0]),

        .pc_po(pc)
    );

    instruction_mem myInstruction_mem(
        .pc_pi(pc),
        .instruction_po(instruction)
    );

    wire [15:0] display_num; 

    data_mem myData_mem(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .reset_pi(reset),

        .write_pi(st),
        .wdata_pi(regD_data),
        .addr_pi(alu_result),

        .rdata_po(data_out),
        .display_num_po(display_num)  
    );

    wire display_clk_en; 

    display_clkdiv displayClockDivider ( 
        .clk_pi(CLK),
        .clk_en_po(display_clk_en)
    );

    sevenSegDisplay myDisplay ( 
        .clk_pi(CLK),
        .clk_en_pi(display_clk_en),
        .num_pi(display_num),
        .seg_po(SEG),
        .an_po(AN)
    );

endmodule
