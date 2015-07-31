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
///////////////////////////////////////////////////////////////////////////////////////////////////
// this module generates a VERY SLOW clk by a simple counter
// note: this method is NOT robust to timing issues, and for slowing
// down/speeding up a clk by a reasonable multiple (e.g 2, 3), use DCM instead
// to guarantee phase locking, elimination of most skew, etc
// Here, the intent is only to generate a pulse with a time period of order of
// seconds
///////////////////////////////////////////////////////////////////////////////////////////////////
module slow_clk(input clk, output slow_clk);
    parameter TICKS = 27'd49_999_999;

    reg [31:0] count = 0;
    reg sig_reg = 0;

    always @(posedge clk) begin
        if (count == TICKS) begin
            // flip at half period
            sig_reg <= ~sig_reg;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
    assign slow_clk = sig_reg;
endmodule
