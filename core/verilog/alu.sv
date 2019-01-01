`include "adder32.sv"

/*
 * An ALU which can perform all the math operations (opcodes 0b0010011 and 0b0110011) of the RV31I/E instruction set.
 */
module alu(
    input clk, // Clock signal
    input [4:0] op, // Operation to be performed
    input [31:0] in_a, // Input data (bus A)
    input [31:0] in_b, // Input data (bus B)
    output [31:0] out, // Output data
    output fault // Invalid operation
);

    /* Internal variables */
    reg [31:0] out;
    reg fault;

    /* Op decoding */
    wire is_invalid_op = (op[3] & op[1]) | (op[4] & op[3]) | (op[3] & ~op[2] & op[0]) | (op[3] & op[2] & ~op[0]) | (op[4] & ~op[2] & op[1]);

    /* Bitwise operations */
    wire [31:0] xor_result = in_a ^ in_b;
    wire [31:0] or_result = in_a | in_b;
    wire [31:0] and_result = in_a & in_b;

    /* Adder */
    wire adder_carry_in = op[3];
    wire [31:0] adder_a = in_a;
    wire [31:0] adder_b = in_b ^ {32{op[3]}};
    wire [31:0] adder_sum;
    adder32 adder(adder_a, adder_b, adder_carry_in, adder_sum);

    /* Comparison operations */
    wire signed_lt_result = ($signed(in_a) < $signed(in_b)) ? 1'b1 : 1'b0;
    wire unsigned_lt_result = (in_a < in_b) ? 1'b1 : 1'b0;
    wire eq_result = (xor_result == 32'b0) ? 1'b1 : 1'b0;

    /* Logic */
    always @(posedge clk) begin
        if (~op[4] & (op[2:0] == 3'b0)) // ADD,SUB
            out <= adder_sum;
        else if (op == 5'b00001) // SLL
            out <= in_a << in_b[4:0];
        else if (op[4:1] == 4'b0001) // SLT,SLTU
            out <= {31'b0, ((op[0] & unsigned_lt_result) | (~op[0] & signed_lt_result))};
        else if (op == 5'b00100) // XOR
            out <= xor_result;
        else if (op == 5'b00101) // SRL
            out <= in_a >> in_b[4:0];
        else if (op == 5'b00110) // OR
            out <= or_result;
        else if (op == 5'b00111) // AND
            out <= and_result;
        else if (op == 5'b01101) // SRA
            out <= in_a >>> in_b[4:0];
        else if (op[4:1] == 4'b1000) // BEQ,BNE
            out <= {31'b0, eq_result ^ op[0]};
        else if (op[4:2] == 3'b101) // BLT,BGE,BLTU,BGEU
            out <= {31'b0, ((op[1] & unsigned_lt_result) | (~op[1] & signed_lt_result)) ^ op[0]};
        fault <= is_invalid_op;
    end

`ifdef FORMAL
    reg f_past_valid;
    initial f_past_valid = 0;
    always @(posedge clk) begin
        f_past_valid = 1;
    end

    /* Validate logic */
    always @(posedge clk) begin
    	if (f_past_valid) begin
            case ($past(op))
                5'b0000: begin // ADD
                    assert(!fault);
                    assert(out == ($past(in_a) + $past(in_b)));
                end
                5'b00001: begin // SLL
                    assert(!fault);
                    assert(out == ($past(in_a) << $past(in_b[4:0])));
                end
                5'b00010: begin // SLT
                    assert(!fault);
                    assert(out == (($signed($past(in_a)) < $signed($past(in_b))) ? 1 : 0));
                end
                5'b00011: begin // SLTU
                    assert(!fault);
                    assert(out == (($past(in_a) < $past(in_b)) ? 1 : 0));
                end
                5'b00100: begin // XOR
                    assert(!fault);
                    assert(out == ($past(in_a) ^ $past(in_b)));
                end
                5'b00101: begin // SRL
                    assert(!fault);
                    assert(out == ($past(in_a) >> $past(in_b[4:0])));
                end
                5'b00110: begin // OR
                    assert(!fault);
                    assert(out == ($past(in_a) | $past(in_b)));
                end
                5'b00111: begin // AND
                    assert(!fault);
                    assert(out == ($past(in_a) & $past(in_b)));
                end
                5'b01000: begin // SUB
                    assert(!fault);
                    assert(out == ($past(in_a) - $past(in_b)));
                end
                5'b01101: begin // SRA
                    assert(!fault);
                    assert(out == ($past(in_a) >>> $past(in_b[4:0])));
                end
                5'b10000: begin // BEQ
                    assert(!fault);
                    assert(out == (($past(in_a) == $past(in_b)) ? 1'b1 : 1'b0));
                end
                5'b10001: begin // BNE
                    assert(!fault);
                    assert(out == (($past(in_a) != $past(in_b)) ? 1'b1 : 1'b0));
                end
                5'b10100: begin // BLT
                    assert(!fault);
                    assert(out == (($signed($past(in_a)) < $signed($past(in_b))) ? 1'b1 : 1'b0));
                end
                5'b10101: begin // BGE
                    assert(!fault);
                    assert(out == (($signed($past(in_a)) >= $signed($past(in_b))) ? 1'b1 : 1'b0));
                end
                5'b10110: begin // BLTU
                    assert(!fault);
                    assert(out == (($past(in_a) < $past(in_b)) ? 1'b1 : 1'b0));
                end
                5'b10111: begin // BGEU
                    assert(!fault);
                    assert(out == (($past(in_a) >= $past(in_b)) ? 1'b1 : 1'b0));
                end
                default: begin
                    assert(fault);
                end
            endcase
        end
    end
`endif

endmodule