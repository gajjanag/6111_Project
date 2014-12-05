// From Lab 4 

module Square #(parameter Hz = 27000000) (
	input clock, reset,
	output reg square = 0);

	wire oneHertz_enable;

	Divider #(.Hz(Hz)) Sqr (
		.clock(clock),
		.reset(reset),
		.fastMode(1'b0),
		.oneHertz_enable(oneHertz_enable)
	);

	always @ (posedge oneHertz_enable) begin
		square <= ~square;
	end
endmodule