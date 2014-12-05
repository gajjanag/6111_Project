`default_nettype none
///////////////////////////////////////////////////////////////////////////////////////////////////
// pixel_map: This module performs the core perspective transformation
// It computes (X, Y) = ((p1*x+p2*y+p3)/(p7*x+p8*y+p9),
// (p4*x+p5*y+p6)/(p7*x+p8*y+p9)) given values pi (computed in
// perspective_params.v)
// The module also does the necessary pixel read form ntsc_buf, and writes the
// output to vga_buf
//
// Future work:
// 1) Note the huge bit width of the divider. This results in a ridiculous ~80
// clock cycles per pixel. Pipelining of 80 bit divider can't be done in
// coregen, and will need to be done manually. It would be a nice feature,
// since this would enable a real time projector display as opposed to current
// ~1-2 frames per second
//
// 2) reduce bit widths: these bit widths are conservative, and mathematically
// guaranteed never to lose precision. Software indicates that I can lose up
// to 20 bits of precision, and still be ok. A careful analysis of this needs
// to be performed
///////////////////////////////////////////////////////////////////////////////////////////////////
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

// internal registers for numerator and denominator computation
// see perspective_params.v for the equations
reg signed[78:0] num_x = 0;
reg signed[78:0] num_y = 0;
reg signed[78:0] denom = 0;

// internal registers for pixel index
reg[9:0] cur_x = 0;
reg[9:0] cur_y = 0;

// divider outputs
wire signed[78:0] inv_x;
wire signed[78:0] inv_y;
wire signed[78:0] dummy_remx;
wire signed[78:0] dummy_remy;
reg div_start;
wire div_done_x;
wire div_done_y;

// instantiate dividers
divider #(.WIDTH(79)) divider_x(.clk(clk),
                                .sign(1'b1),
                                .start(div_start),
                                .dividend(num_x),
                                .divider(denom),
                                .quotient(inv_x),
                                .remainder(dummy_remx),
                                .ready(div_done_x));

divider #(.WIDTH(79)) divider_y(.clk(clk),
                                .sign(1'b1),
                                .start(div_start),
                                .dividend(num_y),
                                .divider(denom),
                                .quotient(inv_y),
                                .remainder(dummy_remy),
                                .ready(div_done_y));

// instantiate an address mapper (for the vga_in)
addr_map addr_map_vga(.hcount(cur_x),
                .vcount(cur_y),
                .addr(vga_in_addr));

// instantiate an address mapper (for the ntsc_out)
addr_map addr_map_ntsc(.hcount(inv_x[9:0]),
                    .vcount(inv_y[9:0]),
                    .addr(ntsc_out_addr));

parameter NEXT_PIXEL_ST = 2'b00;
parameter WAIT_FOR_DIV_ST = 2'b01;
parameter WAIT_FOR_MEM_ST = 2'b10;
parameter BLACK = 12'd0;
parameter WHITE = 12'hfff;
reg[1:0] cur_state = NEXT_PIXEL_ST;
always @(posedge clk) begin
    max_state <= (cur_state > max_state) ? cur_state : max_state;
    case (cur_state)
        NEXT_PIXEL_ST: begin
            vga_in_wr <= 0;
            div_start <= 1;
            cur_state <= WAIT_FOR_DIV_ST;
            if ((cur_x == 639) && (cur_y == 479)) begin
                cur_x <= 0;
                cur_y <= 0;
                num_x <= p3_inv;
                num_y <= p6_inv;
                denom <= p9_inv;
            end
            else if ((cur_x == 639) && (cur_y !=  479)) begin
                cur_x <= 0;
                cur_y <= cur_y + 1;
                num_x <= num_x - dec_numx_horiz + p2_inv;
                num_y <= num_y - dec_numy_horiz + p5_inv;
                denom <= denom - dec_denom_horiz + p8_inv;
            end
            else if (cur_x != 639) begin
                cur_x <= cur_x + 1;
                cur_y <= cur_y;
                num_x <= num_x + p1_inv;
                num_y <= num_y + p4_inv;
                denom <= denom + p7_inv;
            end
        end

        WAIT_FOR_DIV_ST: begin
           vga_in_wr <= 0;
           div_start <= 0;
           if (div_done_x == 1) begin
               cur_state <= WAIT_FOR_MEM_ST;
           end
        end

        WAIT_FOR_MEM_ST: begin
            if ((inv_x < 0) || (inv_x > 639) || (inv_y < 0) || (inv_y > 479)) begin
                pixel_out <= WHITE;
                vga_in_wr <= 1;
                cur_state <= NEXT_PIXEL_ST;
            end
            else begin
                pixel_out <= pixel_in;
                vga_in_wr <= 1;
                cur_state <= NEXT_PIXEL_ST;
            end
        end

    endcase
end
endmodule

