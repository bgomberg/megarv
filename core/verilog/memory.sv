/*
 * Memory access unit.
 */

`ifdef verilator
import "DPI-C" function bit mem_op_setup(input bit is_write, input bit op_1, input bit op_0, input int addr, input int write_data, input bit read_is_unsigned);
import "DPI-C" function bit mem_op_is_busy();
import "DPI-C" function int mem_read_get_result();
`else
function mem_op_setup;
    mem_op_setup = 1'b0;
endfunction
function mem_op_is_busy;
    mem_op_is_busy = 1'b0;
endfunction
function mem_read_get_result;
    mem_read_get_result = 32'b0;
endfunction
`endif

`define STATE_IDLE          2'b00
`define STATE_IN_PROGRESS   2'b01
`define STATE_DONE          2'b10

module memory(
    input clk, // Clock signal
    input reset, // Reset signal
    input available, // Operation available
    input is_write, // Whether or not the operation is a write
    input is_unsigned, // Whether or not the read byte/half-word value should be zero-extended (vs. sign-extended)
    input [1:0] op /* verilator public */, // Size of the operation (2'b00=byte, 2'b01=half-word, 2'b10=word)
    input [31:0] addr, // Address to access
    input [31:0] in, // Input data
    output [31:0] out, // Output data
    output busy, // Operation busy
    output op_fault, // Invalid op fault
    output addr_fault, // Misaligned address fault
    output access_fault // Access fault
);

    /* Outputs */
    reg [31:0] out;
    reg busy;
    reg op_fault;
    reg addr_fault;
    reg access_fault;

    /* Basic Decode */
    wire op_is_invalid = op[1] & op[0];
    wire addr_is_misaligned = (op[1] & (addr[1] | addr[0])) | (op[0] & addr[0]);

    /* Memory Access */
    reg setup_failed;
    reg [1:0] state;
    always @(posedge clk) begin
        if (reset) begin
            busy <= 1'b0;
            state <= `STATE_IDLE;
            op_fault <= 1'b0;
            addr_fault <= 1'b0;
            access_fault <= 1'b0;
            setup_failed <= 1'b0;
        end else begin
            addr_fault <= available & addr_is_misaligned;
            op_fault <= available & op_is_invalid;
            access_fault <= setup_failed;
            case (state)
                `STATE_IDLE: begin
                    if (available) begin
                        // Starting a new operation
                        setup_failed <= mem_op_setup(is_write, op[1], op[0], addr, in, is_unsigned);
                        state <= `STATE_IN_PROGRESS;
                        busy <= 1'b1;
                    end else begin
                        busy <= 1'b0;
                    end
                end
                `STATE_IN_PROGRESS: begin
                    if (setup_failed | !mem_op_is_busy()) begin
                        // Operation is complete
                        if (!is_write & ~setup_failed) begin
                            out <= mem_read_get_result();
                        end
                        busy <= 1'b0;
                        state <= `STATE_DONE;
                    end
                end
                `STATE_DONE: begin
                    if (!available) begin
                        state <= `STATE_IDLE;
                    end
                end
                default: begin
                    // should never get here
                end
            endcase
        end
    end

`ifdef FORMAL
    initial assume(reset);
    reg f_past_valid;
    initial f_past_valid = 0;
    always @(posedge clk) begin
        f_past_valid <= 1;
    end

    /* Read path */
    always @(posedge clk) begin
        if (f_past_valid) begin
            assume(state != 2'b11);
            if ($past(reset)) begin
                assert(!busy);
                assert(!op_fault);
                assert(!addr_fault);
                assert(!access_fault);
            end else if (state == `STATE_DONE && $past(state) == `STATE_IN_PROGRESS) begin
                case ($past(op))
                    2'b00: begin // byte
                        assert(!op_fault);
                        assert(!addr_fault);
                        assert(!access_fault);
                    end
                    2'b01: begin // half-word
                        assert(!op_fault);
                        assert(!access_fault);
                        if ($past(addr[0])) begin
                            assert(addr_fault);
                        end else begin
                            assert(!addr_fault);
                        end
                    end
                    2'b10: begin // word
                        assert(!op_fault);
                        assert(!access_fault);
                        if ($past(addr[1:0])) begin
                            assert(addr_fault);
                        end else begin
                            assert(!addr_fault);
                        end
                    end
                    default: begin
                        assert(op_fault);
                    end
                endcase
            end
        end
    end
`endif

endmodule
