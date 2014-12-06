`default_nettype none
////////////////////////////////////////////////////////////////////////////////
//
// 6.111 FPGA Labkit -- Template Toplevel Module
//
// For Labkit Revision 004
//
//
// Created: October 31, 2004, from revision 003 file
// Author: Nathan Ickes
//
///////////////////////////////////////////////////////////////////////////////
//
// CHANGES FOR BOARD REVISION 004
//
// 1) Added signals for logic analyzer pods 2-4.
// 2) Expanded "tv_in_ycrcb" to 20 bits.
// 3) Renamed "tv_out_data" to "tv_out_i2c_data" and "tv_out_sclk" to
//    "tv_out_i2c_clock".
// 4) Reversed disp_data_in and disp_data_out signals, so that "out" is an
//    output of the FPGA, and "in" is an input.
//
// CHANGES FOR BOARD REVISION 003
//
// 1) Combined flash chip enables into a single signal, flash_ce_b.
//
// CHANGES FOR BOARD REVISION 002
//
// 1) Added SRAM clock feedback path input and output
// 2) Renamed "mousedata" to "mouse_data"
// 3) Renamed some ZBT memory signals. Parity bits are now incorporated into 
//    the data bus, and the byte write enables have been combined into the
//    4-bit ram#_bwe_b bus.
// 4) Removed the "systemace_clock" net, since the SystemACE clock is now
//    hardwired on the PCB to the oscillator.
//
///////////////////////////////////////////////////////////////////////////////
//
// Complete change history (including bug fixes)
//
// 2006-Mar-08: Corrected default assignments to "vga_out_red", "vga_out_green"
//              and "vga_out_blue". (Was 10'h0, now 8'h0.)
//
// 2005-Sep-09: Added missing default assignments to "ac97_sdata_out",
//              "disp_data_out", "analyzer[2-3]_clock" and
//              "analyzer[2-3]_data".
//
// 2005-Jan-23: Reduced flash address bus to 24 bits, to match 128Mb devices
//              actually populated on the boards. (The boards support up to
//              256Mb devices, with 25 address lines.)
//
// 2004-Oct-31: Adapted to new revision 004 board.
//
// 2004-May-01: Changed "disp_data_in" to be an output, and gave it a default
//              value. (Previous versions of this file declared this port to
//              be an input.)
//
// 2004-Apr-29: Reduced SRAM address busses to 19 bits, to match 18Mb devices
//              actually populated on the boards. (The boards support up to
//              72Mb devices, with 21 address lines.)
//
// 2004-Apr-29: Change history started
//
///////////////////////////////////////////////////////////////////////////////

module labkit (beep, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch,
	       ac97_bit_clock,
	       
	       vga_out_red, vga_out_green, vga_out_blue, vga_out_sync_b,
	       vga_out_blank_b, vga_out_pixel_clock, vga_out_hsync,
	       vga_out_vsync,

	       tv_out_ycrcb, tv_out_reset_b, tv_out_clock, tv_out_i2c_clock,
	       tv_out_i2c_data, tv_out_pal_ntsc, tv_out_hsync_b,
	       tv_out_vsync_b, tv_out_blank_b, tv_out_subcar_reset,

	       tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1,
	       tv_in_line_clock2, tv_in_aef, tv_in_hff, tv_in_aff,
	       tv_in_i2c_clock, tv_in_i2c_data, tv_in_fifo_read,
	       tv_in_fifo_clock, tv_in_iso, tv_in_reset_b, tv_in_clock,

	       ram0_data, ram0_address, ram0_adv_ld, ram0_clk, ram0_cen_b,
	       ram0_ce_b, ram0_oe_b, ram0_we_b, ram0_bwe_b, 

	       ram1_data, ram1_address, ram1_adv_ld, ram1_clk, ram1_cen_b,
	       ram1_ce_b, ram1_oe_b, ram1_we_b, ram1_bwe_b,

	       clock_feedback_out, clock_feedback_in,

	       flash_data, flash_address, flash_ce_b, flash_oe_b, flash_we_b,
	       flash_reset_b, flash_sts, flash_byte_b,

	       rs232_txd, rs232_rxd, rs232_rts, rs232_cts,

	       mouse_clock, mouse_data, keyboard_clock, keyboard_data,

	       clock_27mhz, clock1, clock2,

	       disp_blank, disp_data_out, disp_clock, disp_rs, disp_ce_b,
	       disp_reset_b, disp_data_in,

	       button0, button1, button2, button3, button_enter, button_right,
	       button_left, button_down, button_up,

	       switch,

	       led,
	       
	       user1, user2, user3, user4,
	       
	       daughtercard,

	       systemace_data, systemace_address, systemace_ce_b,
	       systemace_we_b, systemace_oe_b, systemace_irq, systemace_mpbrdy,
	       
	       analyzer1_data, analyzer1_clock,
 	       analyzer2_data, analyzer2_clock,
 	       analyzer3_data, analyzer3_clock,
 	       analyzer4_data, analyzer4_clock);

   output beep, audio_reset_b, ac97_synch, ac97_sdata_out;
   input  ac97_bit_clock, ac97_sdata_in;
   
   output [7:0] vga_out_red, vga_out_green, vga_out_blue;
   output vga_out_sync_b, vga_out_blank_b, vga_out_pixel_clock,
	  vga_out_hsync, vga_out_vsync;

   output [9:0] tv_out_ycrcb;
   output tv_out_reset_b, tv_out_clock, tv_out_i2c_clock, tv_out_i2c_data,
	  tv_out_pal_ntsc, tv_out_hsync_b, tv_out_vsync_b, tv_out_blank_b,
	  tv_out_subcar_reset;
   
   input  [19:0] tv_in_ycrcb;
   input   tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, tv_in_aef,
	  tv_in_hff, tv_in_aff;
   output  tv_in_i2c_clock, tv_in_fifo_read, tv_in_fifo_clock, tv_in_iso,
	  tv_in_reset_b, tv_in_clock;
   inout   tv_in_i2c_data;
        
   inout  [35:0] ram0_data;
   output [18:0] ram0_address;
   output ram0_adv_ld, ram0_clk, ram0_cen_b, ram0_ce_b, ram0_oe_b, ram0_we_b;
   output [3:0] ram0_bwe_b;
   
   inout  [35:0] ram1_data;
   output [18:0] ram1_address;
   output ram1_adv_ld, ram1_clk, ram1_cen_b, ram1_ce_b, ram1_oe_b, ram1_we_b;
   output [3:0] ram1_bwe_b;

   input   clock_feedback_in;
   output  clock_feedback_out;
   
   inout  [15:0] flash_data;
   output [23:0] flash_address;
   output  flash_ce_b, flash_oe_b, flash_we_b, flash_reset_b, flash_byte_b;
   input   flash_sts;
   
   output  rs232_txd, rs232_rts;
   input  rs232_rxd, rs232_cts;

   input  mouse_clock, mouse_data, keyboard_clock, keyboard_data;

   input  clock_27mhz, clock1, clock2;

   output  disp_blank, disp_clock, disp_rs, disp_ce_b, disp_reset_b;  
   input   disp_data_in;
   output   disp_data_out;
   
   input button0, button1, button2, button3, button_enter, button_right,
	  button_left, button_down, button_up;
   input  [7:0] switch;
   output [7:0] led;

   inout [31:0] user1, user2, user3, user4;
   
   inout [43:0] daughtercard;

   inout [15:0] systemace_data;
   output [6:0]  systemace_address;
   output systemace_ce_b, systemace_we_b, systemace_oe_b;
   input  systemace_irq, systemace_mpbrdy;

   output [15:0] analyzer1_data, analyzer2_data, analyzer3_data, 
		 analyzer4_data;
   output analyzer1_clock, analyzer2_clock, analyzer3_clock, analyzer4_clock;

   ////////////////////////////////////////////////////////////////////////////
   //
   // I/O Assignments
   //
   ////////////////////////////////////////////////////////////////////////////
   
   // Audio Input and Output
   assign beep= 1'b0;
   assign audio_reset_b = 1'b0;
   assign ac97_synch = 1'b0;
   assign ac97_sdata_out = 1'b0;
   // ac97_sdata_in is an input

   // Video Output
   assign tv_out_ycrcb = 10'h0;
   assign tv_out_reset_b = 1'b0;
   assign tv_out_clock = 1'b0;
   assign tv_out_i2c_clock = 1'b0;
   assign tv_out_i2c_data = 1'b0;
   assign tv_out_pal_ntsc = 1'b0;
   assign tv_out_hsync_b = 1'b1;
   assign tv_out_vsync_b = 1'b1;
   assign tv_out_blank_b = 1'b1;
   assign tv_out_subcar_reset = 1'b0;
   
   // Video Input
   // assign tv_in_i2c_clock = 1'b0;
   assign tv_in_fifo_read = 1'b0;
   assign tv_in_fifo_clock = 1'b0;
   assign tv_in_iso = 1'b0;
   // assign tv_in_reset_b = 1'b0;
   assign tv_in_clock = 1'b0;
   // assign tv_in_i2c_data = 1'bZ;
   // tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, 
   // tv_in_aef, tv_in_hff, and tv_in_aff are inputs
   
   // SRAMs
   assign ram0_data = 36'hZ;
   assign ram0_address = 19'h0;
   assign ram0_adv_ld = 1'b0;
   assign ram0_clk = 1'b0;
   assign ram0_cen_b = 1'b1;
   assign ram0_ce_b = 1'b1;
   assign ram0_oe_b = 1'b1;
   assign ram0_we_b = 1'b1;
   assign ram0_bwe_b = 4'hF;
   assign ram1_data = 36'hZ;
   assign ram1_address = 19'h0;
   assign ram1_adv_ld = 1'b0;
   assign ram1_clk = 1'b0;
   assign ram1_cen_b = 1'b1;
   assign ram1_ce_b = 1'b1;
   assign ram1_oe_b = 1'b1;
   assign ram1_we_b = 1'b1;
   assign ram1_bwe_b = 4'hF;
   assign clock_feedback_out = 1'b0;
   // clock_feedback_in is an input
   
   // Flash ROM
   assign flash_data = 16'hZ;
   assign flash_address = 24'h0;
   assign flash_ce_b = 1'b1;
   assign flash_oe_b = 1'b1;
   assign flash_we_b = 1'b1;
   assign flash_reset_b = 1'b0;
   assign flash_byte_b = 1'b1;
   // flash_sts is an input

   // RS-232 Interface
   assign rs232_txd = 1'b1;
   assign rs232_rts = 1'b1;
   // rs232_rxd and rs232_cts are inputs

   // PS/2 Ports
   // mouse_clock, mouse_data, keyboard_clock, and keyboard_data are inputs


   // Buttons, Switches, and Individual LEDs
   //assign led = 8'hFF;
   // button0, button1, button2, button3, button_enter, button_right,
   // button_left, button_down, button_up, and switches are inputs

   // User I/Os
   assign user1[31:4] = 28'hZ;
   assign user2 = 32'hZ;
   assign user3 = 32'hZ;
   assign user4 = 32'hZ;

   // Daughtercard Connectors
   assign daughtercard = 44'hZ;
   
   // SystemACE Microprocessor Port
   assign systemace_data = 16'hZ;
   assign systemace_address = 7'h0;
   assign systemace_ce_b = 1'b1;
   assign systemace_we_b = 1'b1;
   assign systemace_oe_b = 1'b1;
   // systemace_irq and systemace_mpbrdy are inputs

   // Logic Analyzer
   assign analyzer1_data = 16'h0;
   assign analyzer1_clock = 1'b1;
   assign analyzer2_data = 16'h0;
   assign analyzer2_clock = 1'b1;
   assign analyzer3_data = 16'h0;
   assign analyzer3_clock = 1'b1;
   assign analyzer4_data = 16'h0;
   assign analyzer4_clock = 1'b1;
			    
////////////////////////////////////////////////////////////////////////////
  //
  // Reset Generation
  //
  // A shift register primitive is used to generate an active-high reset
  // signal that remains high for 16 clock cycles after configuration finishes
  // and the FPGA's internal clocks begin toggling.
  //
  ////////////////////////////////////////////////////////////////////////////
wire reset;
SRL16 reset_sr(.D(1'b0), .CLK(clock_27mhz), .Q(reset),
         .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
defparam reset_sr.INIT = 16'hFFFF;

///////////////////////////////////////////////////////////////////////////////////////////////////
// create clocks
// use FPGA's digital clock manager to produce a 50 MHz clock
// this clock is our system clock
// to drive VGA at 640x480 (60 Hz), we need a 25 MHz vga clock
// credits to Jose for computing the required clock values
// and use of ramclock module
///////////////////////////////////////////////////////////////////////////////////////////////////
wire sys_clk_unbuf, sys_clk, vga_clk, vga_clk_unbuf;
wire slow_clk;
wire clk_locked;
DCM vclk1(.CLKIN(clock_27mhz),.CLKFX(sys_clk_unbuf));
// synthesis attribute CLKFX_DIVIDE of vclk1 is 15
// synthesis attribute CLKFX_MULTIPLY of vclk1 is 28
// synthesis attribute CLK_FEEDBACK of vclk1 is NONE
// synthesis attribute CLKIN_PERIOD of vclk1 is 37
BUFG vclk2(.O(sys_clk),.I(sys_clk_unbuf));
DCM int_dcm(.CLKIN(sys_clk), .CLKFX(vga_clk_unbuf), .LOCKED(clk_locked));
// synthesis attribute CLKFX_DIVIDE of int_dcm is 4
// synthesis attribute CLKFX_MULTIPLY of int_dcm is 2
// synthesis attribute CLK_FEEDBACK of int_dcm is NONE
// synthesis attribute CLKIN_PERIOD of int_dcm is 20
BUFG int_dcm2(.O(vga_clk), .I(vga_clk_unbuf));
assign led[7] = ~clk_locked;
assign led[5:0] = {7{1'b1}};
slow_clk slow(.clk(vga_clk),
            .slow_clk(slow_clk));
assign led[6] = ~slow_clk;

///////////////////////////////////////////////////////////////////////////////////////////////////
// create debounced buttons
///////////////////////////////////////////////////////////////////////////////////////////////////
wire btn_up_clean, btn_down_clean, btn_left_clean, btn_right_clean;
wire btn_up_sw, btn_down_sw, btn_left_sw, btn_right_sw;
debounce btn_up_debounce(.reset(reset), .clock(clock_27mhz), .noisy(button_up), .clean(btn_up_clean));
debounce btn_down_debounce(.reset(reset), .clock(clock_27mhz), .noisy(button_down), .clean(btn_down_clean));
debounce btn_left_debounce(.reset(reset), .clock(clock_27mhz), .noisy(button_left), .clean(btn_left_clean));
debounce btn_right_debounce(.reset(reset), .clock(clock_27mhz), .noisy(button_right), .clean(btn_right_clean));
assign btn_up_sw = ~btn_up_clean;
assign btn_down_sw = ~btn_down_clean;
assign btn_left_sw = ~btn_left_clean;
assign btn_right_sw = ~btn_right_clean;


///////////////////////////////////////////////////////////////////////////////////////////////////
// create switches
///////////////////////////////////////////////////////////////////////////////////////////////////
wire override_sw;
wire[1:0] quad_corner_sw;
assign override_sw = switch[7];
assign quad_corner_sw = switch[1:0];

///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate vga
///////////////////////////////////////////////////////////////////////////////////////////////////
wire[9:0] hcount;
wire[9:0] vcount;
wire vsync, hsync, blank;
vga vga(.vclock(vga_clk),
        .hcount(hcount),
        .vcount(vcount),
        .vsync(vsync),
        .hsync(hsync),
        .blank(blank));


///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate accel_lut and move_cursor
// essentially, corners of quadrilateral logic
///////////////////////////////////////////////////////////////////////////////////////////////////
wire acc_ready;
wire signed [15:0] acc_x;
wire signed [15:0] acc_y;
acc a(.clk(sys_clk), .sdo(user1[0]), .reset(reset),
.ncs(user1[1]), .sda(user1[2]), .scl(user1[3]),
.ready(acc_ready), .x(acc_x), .y(acc_y));
		
wire[11:0] accel_val;
wire[75:0] quad_corners;
wire[9:0] x1_raw;
wire[8:0] y1_raw;
wire[9:0] x2_raw;
wire[8:0] y2_raw;
wire[9:0] x3_raw;
wire[8:0] y3_raw;
wire[9:0] x4_raw;
wire[8:0] y4_raw;
wire[9:0] x1;
wire[8:0] y1;
wire[9:0] x2;
wire[8:0] y2;
wire[9:0] x3;
wire[8:0] y3;
wire[9:0] x4;
wire[8:0] y4;
wire[9:0] display_x;
wire[8:0] display_y;
assign accel_val = {~acc_x[15], acc_x[7:4], 1'b0, ~acc_y[15], acc_y[7:4], 1'b0}; 
accel_lut accel_lut(.clk(slow_clk),
                .accel_val(accel_val),
                .quad_corners(quad_corners));
assign y4_raw = quad_corners[8:0];
assign x4_raw = quad_corners[18:9];
assign y3_raw = quad_corners[27:19];
assign x3_raw = quad_corners[37:28];
assign y2_raw = quad_corners[46:38];
assign x2_raw = quad_corners[56:47];
assign y1_raw = quad_corners[65:57];
assign x1_raw = quad_corners[75:66];
move_cursor move_cursor(.clk(vsync),
                    .up(btn_up_sw),
                    .down(btn_down_sw),
                    .left(btn_left_sw),
                    .right(btn_right_sw),
                    .override(override_sw),
                    .switch(quad_corner_sw),
                    .x1_raw(x1_raw),
                    .y1_raw(y1_raw),
                    .x2_raw(x2_raw),
                    .y2_raw(y2_raw),
                    .x3_raw(x3_raw),
                    .y3_raw(y3_raw),
                    .x4_raw(x4_raw),
                    .y4_raw(y4_raw),
                    .x1(x1),
                    .y1(y1),
                    .x2(x2),
                    .y2(y2),
                    .x3(x3),
                    .y3(y3),
                    .x4(x4),
                    .y4(y4),
                    .display_x(display_x),
                    .display_y(display_y));


///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate pixels_lost module
///////////////////////////////////////////////////////////////////////////////////////////////////
wire[6:0] percent_lost;
pixels_lost pixels_lost(.clk(vsync),
                .x1(x1),
                .y1(y1),
                .x2(x2),
                .y2(y2),
                .x3(x3),
                .y3(y3),
                .x4(x4),
                .y4(y4),
                .percent_lost(percent_lost));


///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate perspective_params module
///////////////////////////////////////////////////////////////////////////////////////////////////
wire signed[67:0] p1_inv;
wire signed[68:0] p2_inv;
wire signed[78:0] p3_inv;
wire signed[67:0] p4_inv;
wire signed[68:0] p5_inv;
wire signed[78:0] p6_inv;
wire signed[58:0] p7_inv;
wire signed[59:0] p8_inv;
wire signed[70:0] p9_inv;
wire signed[78:0] dec_numx_horiz;
wire signed[78:0] dec_numy_horiz;
wire signed[70:0] dec_denom_horiz;

perspective_params perspective_params(.clk(slow_clk),
                                    .x1(x1),
                                    .y1(y1),
                                    .x2(x2),
                                    .y2(y2),
                                    .x3(x3),
                                    .y3(y3),
                                    .x4(x4),
                                    .y4(y4),
                                    .p1_inv(p1_inv),
                                    .p2_inv(p2_inv),
                                    .p3_inv(p3_inv),
                                    .p4_inv(p4_inv),
                                    .p5_inv(p5_inv),
                                    .p6_inv(p6_inv),
                                    .p7_inv(p7_inv),
                                    .p8_inv(p8_inv),
                                    .p9_inv(p9_inv),
                                    .dec_numx_horiz(dec_numx_horiz),
                                    .dec_numy_horiz(dec_numy_horiz),
                                    .dec_denom_horiz(dec_denom_horiz));



///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate bram blocks
///////////////////////////////////////////////////////////////////////////////////////////////////

// declarations of necessary stuff
reg[16:0] ntsc_cb_in_addr = 0;
wire[16:0] ntsc_out_addr;
wire[16:0] vga_in_addr;
wire[16:0] vga_out_addr;
wire[11:0] ntsc_cb_din;
wire[11:0] ntsc_dout;
wire[11:0] vga_din;
wire[11:0] vga_dout;
wire ntsc_cb_in_wr;
wire vga_in_wr;
assign ntsc_cb_in_wr = 1;

// ntsc

adv7185init adv7185(.reset(reset), .clock_27mhz(clock_27mhz), 
			 .source(1'b0), .tv_in_reset_b(tv_in_reset_b), 
			 .tv_in_i2c_clock(tv_in_i2c_clock), 
			 .tv_in_i2c_data(tv_in_i2c_data));
			 
wire [29:0] ycrcb;	// video data (luminance, chrominance)
wire [2:0] fvh;	// sync for field, vertical, horizontal
wire       dv;	// data valid

ntsc_decode decode (.clk(tv_in_line_clock1), .reset(reset),
			 .tv_in_ycrcb(tv_in_ycrcb[19:10]), 
			 .ycrcb(ycrcb), .f(fvh[2]),
			 .v(fvh[1]), .h(fvh[0]), .data_valid(dv));
			 
// code to write NTSC data to video memory

wire [16:0] ntsc_addr;
wire [11:0] ntsc_data;
wire        ntsc_we;
ntsc_to_bram n2b (tv_in_line_clock1, tv_in_line_clock1, fvh, dv,
		 ycrcb, ntsc_addr, ntsc_data, ntsc_we, switch[6]);

// dump a checkerboard into "ntsc" buffer
reg[9:0] cur_x = 0;
reg[9:0] cur_y = 0;
wire[2:0] checkerboard;
assign checkerboard = cur_x[7:5] + cur_y[7:5];
assign ntsc_cb_din = {{4{checkerboard[2]}}, {4{checkerboard[1]}}, {4{checkerboard[0]}}};
always @(posedge tv_in_line_clock1) begin
    ntsc_cb_in_addr <= (ntsc_cb_in_addr < 76799) ? (ntsc_cb_in_addr + 1) : 0;
    cur_x <= (cur_x < 319) ? (cur_x + 1) : 0;
    if ((cur_x == 319) && (cur_y == 239)) begin
        cur_y <= 0;
    end
    else if (cur_x == 319) begin
        cur_y <= cur_y + 1;
    end
end

// instantiate the pixel_map module
pixel_map pixel_map(.clk(sys_clk),
                .p1_inv(p1_inv),
                .p2_inv(p2_inv),
                .p3_inv(p3_inv),
                .p4_inv(p4_inv),
                .p5_inv(p5_inv),
                .p6_inv(p6_inv),
                .p7_inv(p7_inv),
                .p8_inv(p8_inv),
                .p9_inv(p9_inv),
                .dec_numx_horiz(dec_numx_horiz),
                .dec_numy_horiz(dec_numy_horiz),
                .dec_denom_horiz(dec_denom_horiz),
                .pixel_in(ntsc_dout),
                .pixel_out(vga_din),
                .ntsc_out_addr(ntsc_out_addr),
                .vga_in_wr(vga_in_wr),
                .vga_in_addr(vga_in_addr));

// read from vga buffer for display
addr_map addr_map(.hcount(hcount),
                .vcount(vcount),
                .addr(vga_out_addr));

/*always @(posedge sys_clk) begin
    vga_in_addr <= (vga_in_addr < 76799) ? (vga_in_addr + 1) : 0;
    ntsc_out_addr <= (ntsc_out_addr < 76799) ? (ntsc_out_addr + 1) : 0;
    vga_in_wr <= 1;
end*/

// create the brams
bram ntsc_buf(.a_clk(tv_in_line_clock1),
            .a_wr(switch[5] ? ntsc_cb_in_wr : ntsc_we),
            .a_addr(switch[5] ? ntsc_cb_in_addr : ntsc_addr),
            .a_din(switch[5] ? ntsc_cb_din : ntsc_data),
            .b_clk(sys_clk),
            .b_addr(ntsc_out_addr),
            .b_dout(ntsc_dout));

bram vga_buf(.a_clk(sys_clk),
            .a_wr(vga_in_wr),
            .a_addr(vga_in_addr),
            .a_din(vga_din),
            .b_clk(vga_clk),
            .b_addr(vga_out_addr),
            .b_dout(vga_dout));

///////////////////////////////////////////////////////////////////////////////////////////////////
// Create VGA output signals
// In order to meet the setup and hold times of AD7125, we send it ~vga_clk
///////////////////////////////////////////////////////////////////////////////////////////////////
assign vga_out_red = {vga_dout[11:8], 4'b0};
assign vga_out_green = {vga_dout[7:4], 4'b0};
assign vga_out_blue = {vga_dout[3:0], 4'b0};
assign vga_out_sync_b = 1'b1;    // not used
assign vga_out_blank_b = ~blank;
assign vga_out_pixel_clock = ~vga_clk;
assign vga_out_hsync = hsync;
assign vga_out_vsync = vsync;


///////////////////////////////////////////////////////////////////////////////////////////////////
// instantiate hex display
///////////////////////////////////////////////////////////////////////////////////////////////////
wire[63:0] hex_disp_data;
// lower 32 bits, keep nice separator of 0 between x, y
assign hex_disp_data[8:0] = display_y;
assign hex_disp_data[15:9] = 7'd0;
assign hex_disp_data[25:16] = display_x;
assign hex_disp_data[31:26] = 6'd0;
// higher bits, put the percent_lost
assign hex_disp_data[63:32] = {10'b0, accel_val[11:6], 10'b0, accel_val[5:0]};
display_16hex display_16hex(.reset(reset),
            .clock_27mhz(clock_27mhz),
            .data(hex_disp_data),
            .disp_blank(disp_blank),
            .disp_clock(disp_clock),
            .disp_data_out(disp_data_out),
            .disp_rs(disp_rs),
            .disp_ce_b(disp_ce_b),
            .disp_reset_b(disp_reset_b));
endmodule
