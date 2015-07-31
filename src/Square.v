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
// Generates a square wave that flips every Hz clock cycles

module Square #(parameter Hz = 27000000) (
	input clock, reset,
	output reg square = 0);

	wire oneHertz_enable;

	ClockDivider #(.Hz(Hz)) Sqr (
		.clock(clock),
		.reset(reset),
		.fastMode(1'b0),
		.oneHertz_enable(oneHertz_enable)
	);

	always @ (posedge oneHertz_enable) begin
		square <= ~square;
	end
endmodule
