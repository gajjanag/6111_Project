/*
Copyright (C) {2014}  {Ganesh Ajjanagadde} <gajjanagadde@gmail.com>

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
`default_nettype none
`define assert(condition) if(!((|{condition{)===1)) begin $display("FAIL"); $finish(1); end

module pixels_lost_test;

reg[9:0] x1;
reg[8:0] y1;
reg[9:0] x2;
reg[8:0] y2;
reg[9:0] x3;
reg[8:0] y3;
reg[9:0] x4;
reg[8:0] y4;

wire[6:0] percent_lost;

initial begin
x1 = 10'd80;
y1 = 9'd80;
x2 = 10'd80;
y2 = 9'd160;
x3 = 10'd160;
y3 = 9'd160;
x4 = 10'd160;
y4 = 9'd80;
end

reg clock = 0;
pixels_lost pixels_lost(clock, x1, y1, x2, y2, x3, y3, x4, y4, percent_lost);
always #1 clock <= !clock;
always @(posedge clock) begin
$display("%d, %d, %d, %d, %d, %d, %d, %d, %d", x1, y1, x2, y2, x3, y3, x4, y4, percent_lost);
end

endmodule
