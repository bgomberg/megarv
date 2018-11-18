/*
 * Basic module which sets the result to the sum of a and b on the rising edge of the clock
 */
module basic(clk, a, b, result);

input clk;
input [2:0] a;
input [2:0] b;
output [2:0] result;

reg	[2:0] result;

initial result = 0;
always @(posedge clk) begin
	result <= a + b;
end

/*
 * Formal properties
 */
`ifdef FORMAL

initial	f_past_valid = 1'b0;
always @(posedge clk) begin
	f_past_valid <= 1'b1;
end

always @(posedge clk) begin
	if (f_past_valid) begin
		assert(result == $past(a) + $past(b));
	end
end

`endif

endmodule
