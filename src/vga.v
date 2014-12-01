////////////////////////////////////////////////////////////////////////////////
// vga: Generate XVGA display signals (640 x 480)
// also generates num_x, num_y, denom signals that are used in pixel_map
// Credits: module heavily draws from Jose's project (Fall 2011),
// also staff xvga module
////////////////////////////////////////////////////////////////////////////////

module vga(input vclock,
            input sys_clock,
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
            output reg[23:0] rgb,
            output reg vsync,hsync,blank);

// VGA (640x480)
parameter VGA_HBLANKON  =  10'd639;
parameter VGA_HSYNCON   =  10'd655;
parameter VGA_HYSNCOFF  =  10'd751;
parameter VGA_HRESET    =  10'd799;
parameter VGA_VBLANKON  =  10'd479;
parameter VGA_VSYNCON   =  10'd490;
parameter VGA_VSYNCOFF  =  10'd492;
parameter VGA_VRESET    =  10'd523;

// pixel info
reg[9:0] hcount;
reg[8:0] vcount;
reg[23:0] rgb;

// internal registers for numerator and denominator computation
// see perspective_params.v for the equations
reg signed[78:0] num_x;
reg signed[78:0] num_y;
reg signed[78:0] denom;

// horizontal: 800 pixels total
// display 640 pixels per line
reg hblank,vblank;
wire hsyncon,hsyncoff,hreset,hblankon;
assign hblankon = (hcount == VGA_HBLANKON);
assign hsyncon = (hcount == VGA_HSYNCON);
assign hsyncoff = (hcount == VGA_HYSNCOFF);
assign hreset = (hcount == VGA_HRESET);

// vertical: 524 lines total
// display 480 lines
wire vsyncon,vsyncoff,vreset,vblankon;
assign vblankon = hreset & (vcount == VGA_VBLANKON);
assign vsyncon = hreset & (vcount == VGA_VSYNCON);
assign vsyncoff = hreset & (vcount == VGA_VSYNCOFF);
assign vreset = hreset & (vcount == VGA_VRESET);

// sync and blanking
wire next_hblank,next_vblank;
assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;

// divider outputs
reg signed[78:0] inv_x;
reg signed[78:0] inv_y;
reg signed[78:0] dummy_remx;
reg signed[78:0] dummy_remy;
reg div_start;
reg div_done_x;
reg div_done_y;

divider #(.WIDTH(79)) divider_x(.clk(sys_clock),
                                .sign(1'b1),
                                .start(div_start),
                                .dividend(num_x),
                                .divider(denom),
                                .quotient(inv_x),
                                .remainder(dummy_remx),
                                .ready(div_done_x));

divider #(.WIDTH(79)) divider_y(.clk(sys_clock),
                                .sign(1'b1),
                                .start(div_start),
                                .dividend(num_y),
                                .divider(denom),
                                .quotient(inv_y),
                                .remainder(dummy_remy),
                                .ready(div_done_y));

// color values
parameter BLACK = 24'd0;

// checkerboard computation
// uses three bits from the coordinates to generate the checkerboard
// (similar to Lab 3)
assign checkerboard = inv_x[8:6] + inv_y[8:6];

always @(posedge vclock) begin
    hcount <= hreset ? 0 : hcount + 1;
    hblank <= next_hblank;
    hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low
    vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
    vblank <= next_vblank;
    vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low
    blank <= next_vblank | (next_hblank & ~hreset);

    // parameter updates
    if (hreset && vreset) begin
        num_x <= p3_inv;
        num_y <= p6_inv;
        denom <= p9_inv;
    end
    else if (hreset && ~vreset) begin
        num_x <= num_x - dec_numx_horiz + p2_inv;
        num_y <= num_y - dec_numy_horiz + p5_inv;
        denom <= denom - dec_denom_horiz + p8_inv;
    end
    else if (~hreset && ~vreset) begin
        num_x <= num_x + p1_inv;
        num_y <= num_y + p4_inv;
        denom <= denom + p7_inv;
    end
    if ((inv_x < 0) || (inv_x > 639) || (inv_y < 0) || (inv_y > 479)) begin
        rgb[23:0] <= BLACK;
    end
    else begin
        rgb[23:0] <= {{8{checkerboard[2]}}, {8{checkerboard[1]}}, {8{checkerboard[0]}}};
    end
end

reg vclock_prev;
parameter WAIT_FOR_DIVIDER_ST = 1'b0;
parameter WAIT_FOR_VCLOCK_ST = 1'b1;
reg cur_state = WAIT_FOR_VCLOCK_ST;

always @(posedge sys_clock) begin
    vclock_prev <= vclock;
    case (cur_state) begin
        WAIT_FOR_VCLOCK_ST: begin
            if ((vclock == 1) && (vclock_prev == 0)) begin
                cur_state <= WAIT_FOR_DIVIDER_ST;
                div_start <= 1;
            end
        end
        WAIT_FOR_DIVIDER_ST: begin
            div_start <= 0;
            if ((div_done_x == 1) && (div_done_y == 1)) begin
                cur_state <= WAIT_FOR_VCLOCK_ST;
            end
        end
    endcase
end
endmodule
