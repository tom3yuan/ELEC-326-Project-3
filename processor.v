`timescale 1ns/1ns

/*
 * Module: processor
 * Description:
 *   Top-level integration of the 16-bit processor.
 *   This module instantiates and connects the program counter,
 *   instruction memory, decoder, register file, ALU, branch, and data memory.
 */

module processor(
    input  CLK_pi,
    input  CPU_RESET_pi
);
    wire cpu_clk_en = 1'b1;
    wire reset;
    wire clock_enable;

    assign reset = CPU_RESET_pi;
    assign clock_enable = cpu_clk_en;

    wire [15:0] pc_out;
    wire [15:0] instr;

    wire [2:0]  rs_addr;
    wire [2:0]  rt_addr;
    wire [2:0]  rd_addr;
    wire        reg_write_en;
    wire        mem_write_en;
    wire        mem_read_en;
    wire [3:0]  alu_op;

    wire [15:0] reg_rs_data;
    wire [15:0] reg_rt_data;

    wire [15:0] alu_result;
    wire        zero_flag;

    wire        branch_taken;
    wire [15:0] branch_target;

    wire [15:0] mem_read_data;

    wire [15:0] writeback_data;

    assign writeback_data = (mem_read_en) ? mem_read_data : alu_result;

    program_counter myProgramCounter(
        .CLK_pi(CLK_pi),
        .RESET_pi(reset),
        .clock_enable_pi(clock_enable),
        .branch_taken_pi(branch_taken),
        .branch_target_pi(branch_target),
        .pc_po(pc_out)
    );

    instruction_mem myInstructionMem(
        .addr_pi(pc_out),
        .instruction_po(instr)
    );

    decoder myDecoder(
        .instruction_pi(instr),
        .rs_addr_po(rs_addr),
        .rt_addr_po(rt_addr),
        .rd_addr_po(rd_addr),
        .alu_op_po(alu_op),
        .reg_write_en_po(reg_write_en),
        .mem_write_en_po(mem_write_en),
        .mem_read_en_po(mem_read_en)
    );

    regfile myRegfile(
        .CLK_pi(CLK_pi),
        .RESET_pi(reset),
        .WE_pi(reg_write_en),
        .rs_pi(rs_addr),
        .rt_pi(rt_addr),
        .rd_pi(rd_addr),
        .wd_pi(writeback_data),
        .rs_data_po(reg_rs_data),
        .rt_data_po(reg_rt_data)
    );

    alu myALU(
        .in1_pi(reg_rs_data),
        .in2_pi(reg_rt_data),
        .alu_op_pi(alu_op),
        .result_po(alu_result),
        .zero_po(zero_flag)
    );
	
    branch myBranch(
        .pc_in_pi(pc_out),
        .immediate_pi(instr[7:0]),
        .zero_pi(zero_flag),
        .branch_taken_po(branch_taken),
        .branch_target_po(branch_target)
    );

    data_mem myDataMem(
        .CLK_pi(CLK_pi),
        .addr_pi(alu_result),
        .write_data_pi(reg_rt_data),
        .mem_write_en_pi(mem_write_en),
        .mem_read_en_pi(mem_read_en),
        .read_data_po(mem_read_data)
    );

endmodule