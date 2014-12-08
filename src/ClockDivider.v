// From Lab 4

module ClockDivider #(parameter Hz = 27000000)(
	input clock, reset, fastMode,
	output reg oneHertz_enable
	);
	
	reg [24:0] counter = 25'b0;

	always @ (posedge clock) begin
		if (reset) begin
			counter <= 25'b0;
			oneHertz_enable <= 1'b0;
		end
		else if (counter == (fastMode ? 3:Hz)) begin
			oneHertz_enable <= 1'b1;
			counter <= 25'b0;
		end
		else begin
			counter <= counter + 1;
			oneHertz_enable <= 1'b0;
		end
	end

endmodule