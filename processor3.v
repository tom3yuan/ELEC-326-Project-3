`timescale 1ns/1ns

module processor (
    
);

    assign DP = 1'b1;

    wire cpu_clk_en;
    wire display_clk_en;

    wire reset = BTN[0];
    wire clock_enable = cpu_clk_en;

    wire [15:0] instr;
    wire [15:0] pc;
    wire [15:0] pc_next;

    wire [2:0] alu_op;
    wire       reg_write;
    wire       mem_write;
    wire       branch_en;
    wire       alu_src;

    wire [2:0] rs1, rs2, rd;

    wire [15:0] rd1, rd2;
    wire [15:0] alu_b_input;
    wire [15:0] alu_result;

    wire branch_taken;
    wire [15:0] branch_target;

    wire [15:0] mem_read_data;
    wire [15:0] write_back_data;

    wire [15:0] display_num;

    decoder myDecoder(
        .instr_pi(instr),
        .alu_op_po(alu_op),
        .reg_write_po(reg_write),
        .alu_src_po(alu_src),
        .mem_write_po(mem_write),
        .branch_po(branch_en),
        .rs1_po(rs1),
        .rs2_po(rs2),
        .rd_po(rd)
    );

    regfile myRegfile(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .we_pi(reg_write),
        .rs1_pi(rs1),
        .rs2_pi(rs2),
        .rd_pi(rd),
        .wd_pi(write_back_data),
        .rd1_po(rd1),
        .rd2_po(rd2)
    );

    assign alu_b_input = (alu_src) ? {{8{instr[7]}}, instr[7:0]} : rd2;

    alu myALU(
        .op_pi(alu_op),
        .a_pi(rd1),
        .b_pi(alu_b_input),
        .result_po(alu_result)
    );

    branch myBranch(
        .pc_pi(pc),
        .instr_pi(instr),
        .branch_en_pi(branch_en),
        .rs1_data_pi(rd1),
        .rs2_data_pi(rd2),
        .branch_taken_po(branch_taken),
        .branch_target_po(branch_target)
    );

    assign pc_next = (branch_taken) ? branch_target : (pc + 16'd1);

    program_counter myProgram_counter(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .reset_pi(reset),
        .pc_next_pi(pc_next),
        .pc_po(pc)
    );

    instruction_mem myInstruction_mem(
        .addr_pi(pc),
        .instr_po(instr)
    );

    data_mem myData_mem(
        .clk_pi(CLK),
        .clk_en_pi(clock_enable),
        .mem_write_pi(mem_write),
        .addr_pi(alu_result),
        .wd_pi(rd2),
        .rd_po(mem_read_data)
    );

    assign write_back_data = (mem_write) ? mem_read_data : alu_result;

    assign LED = alu_result[7:0];
    assign display_num = alu_result;
   //clock divider modules
    display_clkdiv Idisplay_clkdiv(
        .clk_pi(CLK),
        .clk_en_po(display_clk_en)
    );

    display_clkdiv #(.SIZE(12)) Icpu_clkdiv(
        .clk_pi(CLK),
        .clk_en_po(cpu_clk_en)
    );
   //display module
    sevenSegDisplay IsevenSegDisplay(
        .clk_pi(CLK),
        .clk_en_pi(display_clk_en),
        .num_pi(display_num),
        .seg_po(SEG),
        .an_po(AN)
    );

endmodule
