/*
Copyright (C) {2014}  {Shawn Jain} <shawnjain.08@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
// From Lab 4
// Sends a pulse on oneHertz_enable every Hz clock cycles

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
