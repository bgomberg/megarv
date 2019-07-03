`include "program_counter.sv"
`include "memory.sv"
`include "instruction_decode.sv"
`include "register_file.sv"
`include "alu.sv"
`include "adder32_sync.sv"
`include "csr.sv"
`include "fsm.sv"

/*
 * The core which controls and integrates the individual components of the CPU.
 */
module core(
    input clk, // Clock signal
    input reset_n, // Reset signal (active low)
    input ext_int // External interrupt
);

    /* FSM */
    wire [`NUM_STAGES-1:0] stage_done;
    assign stage_done[`STAGE_CONTROL] = 1'b1;
    assign stage_done[`STAGE_FETCH] = ~mem_busy;
    assign stage_done[`STAGE_DECODE] = ~decode_busy;
    assign stage_done[`STAGE_READ] = 1'b1;
    assign stage_done[`STAGE_EXECUTE] = ~alu_busy & ~csr_busy;
    assign stage_done[`STAGE_MEMORY] = ~mem_busy;
    assign stage_done[`STAGE_WRITE_BACK] = ~pc_busy;
    /* verilator lint_off UNOPT */
    wire [`NUM_STAGES-1:0] stage_active /* verilator public */;
    /* verilator lint_on UNOPT */
    wire [1:0] control_op /* verilator public */;
    wire control_op_normal = control_op[1] & control_op[0];
    wire control_op_trap = ~control_op[1] & ~control_op[0];
    reg [2:0] fault_num /* verilator public */;
    fsm fsm_module(
        clk,
        reset_n,
        stage_done,
        decode_fault | mem_op_fault | alu_fault | csr_fault,
        mem_addr_fault,
        mem_access_fault,
        decode_ma_mem_microcode[3],
        ext_int,
        1'b0, // TODO: SW interrupt
        stage_active,
        control_op,
        fault_num);

    /* Program counter */
    wire [31:0] pc_pc /* verilator public */;
    reg [31:0] pc_next_pc /* verilator public */;
    wire [31:0] pc_offset_pc /* verilator public */;
    wire [31:0] pc_in = (decode_wb_pc_mux_position == 2'b00) ? pc_next_pc : (
        (decode_wb_pc_mux_position == 2'b01) ? ex_out : (
        (decode_wb_pc_mux_position == 2'b10) ? pc_offset_pc : (
        (decode_wb_pc_mux_position == 2'b11) ? (alu_out[0] ? pc_offset_pc : pc_next_pc) : 32'b0)));
    wire pc_busy;
    program_counter pc_module(
        clk,
        reset_n,
        stage_active[`STAGE_WRITE_BACK],
        pc_in,
        pc_pc,
        pc_busy);
    adder32_sync next_pc_adder_module(
        clk & stage_active[`STAGE_DECODE],
        pc_pc,
        32'd4,
        pc_next_pc);
    adder32_sync offset_pc_adder_module(
        clk & stage_active[`STAGE_EXECUTE],
        pc_pc,
        decode_imm,
        pc_offset_pc);

    /* Memory */
    wire [31:0] mem_out /* verilator public */;
    wire mem_busy;
    wire mem_op_fault;
    wire mem_addr_fault;
    wire mem_access_fault;
    memory mem_module(
        clk,
        reset_n,
        (stage_active[`STAGE_FETCH] & control_op_normal) | (stage_active[`STAGE_MEMORY] & decode_has_mem_stage),
        stage_active[`STAGE_MEMORY] & decode_ma_mem_microcode[3],
        stage_active[`STAGE_MEMORY] & decode_ma_mem_microcode[2],
        stage_active[`STAGE_FETCH] ? 2'b10 : decode_ma_mem_microcode[1:0],
        stage_active[`STAGE_FETCH] ? pc_pc : alu_out,
        rf_read_data_b,
        mem_out,
        mem_busy,
        mem_op_fault,
        mem_addr_fault,
        mem_access_fault);

    /* Instruction decode */
    wire [31:0] decode_imm /* verilator public */;
    wire decode_alu_a_mux_position /* verilator public */;
    wire decode_alu_b_mux_position /* verilator public */;
    wire [1:0] decode_csr_mux_position /* verilator public */;
    wire [1:0] decode_wb_mux_position /* verilator public */;
    wire [7:0] decode_rd_rf_microcode /* verilator public */;
    wire [5:0] decode_ex_alu_microcode /* verilator public */;
    wire [15:0] decode_ex_csr_microcode /* verilator public */;
    wire [3:0] decode_ma_mem_microcode /* verilator public */;
    /* verilator lint_off UNOPT */
    wire [9:0] decode_wb_rf_microcode /* verilator public */;
    /* verilator lint_on UNOPT */
    wire [1:0] decode_wb_pc_mux_position /* verilator public */;
    wire decode_has_mem_stage;
    wire decode_has_read_stage;
    wire decode_fault;
    wire [31:0] instr /* verilator public */ = control_op_normal ? mem_out : 32'h00000073;
    wire decode_busy;
    instruction_decode decode_module(
        clk,
        reset_n,
        stage_active[`STAGE_DECODE],
        instr,
        decode_imm,
        decode_alu_a_mux_position,
        decode_alu_b_mux_position,
        decode_csr_mux_position,
        decode_wb_mux_position,
        {decode_has_read_stage, decode_rd_rf_microcode},
        decode_ex_alu_microcode,
        {decode_has_mem_stage, decode_ma_mem_microcode},
        decode_ex_csr_microcode,
        decode_wb_rf_microcode,
        decode_wb_pc_mux_position,
        decode_busy,
        decode_fault);

    /* Register file */
    wire [31:0] ex_out = decode_ex_alu_microcode[5] ? alu_out : csr_read_value;
    wire [31:0] rf_write_data /* verilator public */ = (decode_wb_mux_position == 2'b00) ? ex_out : (
        (decode_wb_mux_position == 2'b01) ? decode_imm : (
        (decode_wb_mux_position == 2'b10) ? mem_out :
        pc_next_pc));
    wire [31:0] rf_read_data_a /* verilator public */;
    wire [31:0] rf_read_data_b /* verilator public */;
    register_file rf_module(
        clk & (((stage_active[`STAGE_READ] & decode_has_read_stage) | (stage_active[`STAGE_WRITE_BACK] & decode_wb_rf_microcode[9]))),
        ~(stage_active[`STAGE_READ] & decode_has_read_stage) & decode_wb_rf_microcode[8],
        decode_wb_rf_microcode[7:4],
        rf_write_data,
        decode_rd_rf_microcode[7:4],
        rf_read_data_a,
        decode_rd_rf_microcode[3:0],
        rf_read_data_b);

    /* ALU */
    wire [31:0] alu_out /* verilator public */;
    wire [31:0] alu_in_a = decode_alu_a_mux_position ? pc_pc : rf_read_data_a;
    wire alu_busy;
    wire alu_fault;
    alu alu_module(
        clk,
        reset_n,
        stage_active[`STAGE_EXECUTE] & decode_ex_alu_microcode[5],
        decode_ex_alu_microcode[4:0],
        alu_in_a,
        decode_alu_b_mux_position ? decode_imm : rf_read_data_b,
        alu_out,
        alu_busy,
        alu_fault);

    /* CSR */
    wire [11:0] csr_addr_exception /* verilator public */ = control_op_trap ? {9'b0, fault_num} : decode_ex_csr_microcode[14:3];
    wire [31:0] csr_in /* verilator public */ = (decode_csr_mux_position == 2'b00) ? rf_read_data_a : (
        (decode_csr_mux_position == 2'b01) ? decode_imm : (
        (decode_csr_mux_position == 2'b10) ? (control_op_trap ? pc_pc : pc_next_pc) :
        32'b0));
    wire [31:0] csr_read_value /* verilator public */;
    wire csr_busy;
    wire csr_fault;
    csr csr_module(
        clk,
        reset_n,
        stage_active[`STAGE_EXECUTE] & decode_ex_csr_microcode[15],
        decode_ex_csr_microcode[2:0],
        csr_addr_exception,
        csr_in,
        csr_read_value,
        csr_busy,
        csr_fault
    );

endmodule
