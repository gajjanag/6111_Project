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
end

module divider #(parameter WIDTH = 8) 
  (input clk, sign, start,
   input [WIDTH-1:0] dividend, 
   input [WIDTH-1:0] divider,
   output reg [WIDTH-1:0] quotient,
   output [WIDTH-1:0] remainder,
   output ready);

wire signed[78:0] inv_x_wire;
wire signed[78:0] inv_y_wire;
wire signed[78:0] dummy_remx;
wire signed[78:0] dummy_remy;

divider #(.WIDTH(79)) divider_x(.clk(sys_clock),
                                .sign(1'b1),
                                .start(),
                                .dividend(num_x),
                                .divider(denom),
                                .quotient(inv_x_wire),
                                .remainder(dummy_remx),
                                .ready());
                                
divider #(.WIDTH(79)) divider_y(.clk(sys_clock),
                                .sign(1'b1),
                                .start(),
                                .dividend(num_y),
                                .divider(denom),
                                .quotient(inv_y_wire),
                                .remainder(dummy_remy),
                                .ready());                          
always @(posedge sys_clock) begin

endmodule
