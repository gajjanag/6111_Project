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
module pixel_map(input clk,
                input signed[67:0] p1_inv,
                input signed[68:0] p2_inv,
                input signed[78:0] p3_inv,
                input signed[67:0] p4_inv,
                input signed[68:0] p5_inv,
                input signed[78:0] p6_inv,
                input signed[58:0] p7_inv,
                input signed[59:0] p8_inv,
                input signed[70:0] p9_inv,
                input signed[78:0] dec_numx_horiz,
                input signed[78:0] dec_numy_horiz,
                input signed[70:0] dec_denom_horiz,
                input[11:0] pixel_in,
                output reg[11:0] pixel_out,
                output[16:0] ntsc_out_addr,
                output reg vga_in_wr,
                output[16:0] vga_in_addr);

// instantiate an address mapper (for the vga_in)
addr_map addr_map_vga(.hcount(cur_x),
                .vcount(cur_y),
                .addr(vga_in_addr));

always @(posedge clk) begin
    vga_in_wr <= 1;

    if ((cur_x == 639) && (cur_y == 479)) begin
        cur_x <= 0;
        cur_y <= 0;
    end
    else if ((cur_x == 639) && (cur_y !=  479)) begin
        cur_x <= 0;
        cur_y <= cur_y + 1;
    end
    else if (cur_x != 639) begin
        cur_x <= cur_x + 1;
        cur_y <= cur_y;
    end
end
endmodule
