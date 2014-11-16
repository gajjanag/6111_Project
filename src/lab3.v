///////////////////////////////////////////////////////////////////////////////
//
// Pushbutton Debounce Module (video version - 24 bits)  
//
///////////////////////////////////////////////////////////////////////////////

module debounce (input reset, clock, noisy,
                 output reg clean);

   reg [19:0] count;
   reg new;

   always @(posedge clock)
     if (reset) begin new <= noisy; clean <= noisy; count <= 0; end
     else if (noisy != new) begin new <= noisy; count <= 0; end
     else if (count == 650000) clean <= new;
     else count <= count+1;

endmodule

///////////////////////////////////////////////////////////////////////////////
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
// 2012-Sep-15: Converted to 24bit RGB
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

module lab3   (beep, audio_reset_b, ac97_sdata_out, ac97_sdata_in, ac97_synch,
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
   input  tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, tv_in_aef,
	  tv_in_hff, tv_in_aff;
   output tv_in_i2c_clock, tv_in_fifo_read, tv_in_fifo_clock, tv_in_iso,
	  tv_in_reset_b, tv_in_clock;
   inout  tv_in_i2c_data;
        
   inout  [35:0] ram0_data;
   output [18:0] ram0_address;
   output ram0_adv_ld, ram0_clk, ram0_cen_b, ram0_ce_b, ram0_oe_b, ram0_we_b;
   output [3:0] ram0_bwe_b;
   
   inout  [35:0] ram1_data;
   output [18:0] ram1_address;
   output ram1_adv_ld, ram1_clk, ram1_cen_b, ram1_ce_b, ram1_oe_b, ram1_we_b;
   output [3:0] ram1_bwe_b;

   input  clock_feedback_in;
   output clock_feedback_out;
   
   inout  [15:0] flash_data;
   output [23:0] flash_address;
   output flash_ce_b, flash_oe_b, flash_we_b, flash_reset_b, flash_byte_b;
   input  flash_sts;
   
   output rs232_txd, rs232_rts;
   input  rs232_rxd, rs232_cts;

   input  mouse_clock, mouse_data, keyboard_clock, keyboard_data;

   input  clock_27mhz, clock1, clock2;

   output disp_blank, disp_clock, disp_rs, disp_ce_b, disp_reset_b;  
   input  disp_data_in;
   output  disp_data_out;
   
   input  button0, button1, button2, button3, button_enter, button_right,
	  button_left, button_down, button_up;
   input  [7:0] switch;
   output [7:0] led;

   inout [31:0] user1, user2, user3, user4;
   
   inout [43:0] daughtercard;

   inout  [15:0] systemace_data;
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
   assign tv_in_i2c_clock = 1'b0;
   assign tv_in_fifo_read = 1'b0;
   assign tv_in_fifo_clock = 1'b0;
   assign tv_in_iso = 1'b0;
   assign tv_in_reset_b = 1'b0;
   assign tv_in_clock = 1'b0;
   assign tv_in_i2c_data = 1'bZ;
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

   // LED Displays
   assign disp_blank = 1'b1;
   assign disp_clock = 1'b0;
   assign disp_rs = 1'b0;
   assign disp_ce_b = 1'b1;
   assign disp_reset_b = 1'b0;
   assign disp_data_out = 1'b0;
   // disp_data_in is an input

   // Buttons, Switches, and Individual LEDs
   //lab3 assign led = 8'hFF;
   // button0, button1, button2, button3, button_enter, button_right,
   // button_left, button_down, button_up, and switches are inputs

   // User I/Os
   assign user1 = 32'hZ;
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
   // lab3 : a simple pong game
   //
   ////////////////////////////////////////////////////////////////////////////

   // use FPGA's digital clock manager to produce a
   // 65MHz clock (actually 64.8MHz)
   wire clock_65mhz_unbuf,clock_65mhz;
   DCM vclk1(.CLKIN(clock_27mhz),.CLKFX(clock_65mhz_unbuf));
   // synthesis attribute CLKFX_DIVIDE of vclk1 is 10
   // synthesis attribute CLKFX_MULTIPLY of vclk1 is 24
   // synthesis attribute CLK_FEEDBACK of vclk1 is NONE
   // synthesis attribute CLKIN_PERIOD of vclk1 is 37
   BUFG vclk2(.O(clock_65mhz),.I(clock_65mhz_unbuf));

   // power-on reset generation
   wire power_on_reset;    // remain high for first 16 clocks
   SRL16 reset_sr (.D(1'b0), .CLK(clock_65mhz), .Q(power_on_reset),
		   .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
   defparam reset_sr.INIT = 16'hFFFF;

   // ENTER button is user reset
   wire reset,user_reset;
   debounce db1(.reset(power_on_reset),.clock(clock_65mhz),.noisy(~button_enter),.clean(user_reset));
   assign reset = user_reset | power_on_reset;
   
   // UP and DOWN buttons for pong paddle
   wire up,down;
   debounce db2(.reset(reset),.clock(clock_65mhz),.noisy(~button_up),.clean(up));
   debounce db3(.reset(reset),.clock(clock_65mhz),.noisy(~button_down),.clean(down));

   // generate basic XVGA video signals
   wire [10:0] hcount;
   wire [9:0]  vcount;
   wire hsync,vsync,blank;
   xvga xvga1(.vclock(clock_65mhz),.hcount(hcount),.vcount(vcount),
              .hsync(hsync),.vsync(vsync),.blank(blank));

   // feed XVGA signals to user's pong game
   wire [23:0] pixel;
   wire phsync,pvsync,pblank;
   pong_game pg(.vclock(clock_65mhz),.reset(reset),
                .up(up),.down(down),.pspeed(switch[7:4]),
		.hcount(hcount),.vcount(vcount),
                .hsync(hsync),.vsync(vsync),.blank(blank),
		.phsync(phsync),.pvsync(pvsync),.pblank(pblank),.pixel(pixel));

   // switch[1:0] selects which video generator to use:
   //  00: user's pong game
   //  01: 1 pixel outline of active video area (adjust screen controls)
   //  10: color bars
   reg [23:0] rgb;
   wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767);
   
   reg b,hs,vs;
   always @(posedge clock_65mhz) begin
      if (switch[1:0] == 2'b01) begin
	 // 1 pixel outline of visible area (white)
	 hs <= hsync;
	 vs <= vsync;
	 b <= blank;
	 rgb <= {24{border}};
      end else if (switch[1:0] == 2'b10) begin
	 // color bars
	 hs <= hsync;
	 vs <= vsync;
	 b <= blank;
	 rgb <= {{8{hcount[8]}}, {8{hcount[7]}}, {8{hcount[6]}}} ;
      end else begin
         // default: pong
	 hs <= phsync;
	 vs <= pvsync;
	 b <= pblank;
	 rgb <= pixel;
      end
   end

   // VGA Output.  In order to meet the setup and hold times of the
   // AD7125, we send it ~clock_65mhz.
   assign vga_out_red = rgb[23:16];
   assign vga_out_green = rgb[15:8];
   assign vga_out_blue = rgb[7:0];
   assign vga_out_sync_b = 1'b1;    // not used
   assign vga_out_blank_b = ~b;
   assign vga_out_pixel_clock = ~clock_65mhz;
   assign vga_out_hsync = hs;
   assign vga_out_vsync = vs;
   
   assign led = ~{3'b000,up,down,reset,switch[1:0]};

endmodule

////////////////////////////////////////////////////////////////////////////////
//
// xvga: Generate XVGA display signals (1024 x 768 @ 60Hz)
//
////////////////////////////////////////////////////////////////////////////////

module xvga(input vclock,
            output reg [10:0] hcount,    // pixel number on current line
            output reg [9:0] vcount,	 // line number
            output reg vsync,hsync,blank);

   // horizontal: 1344 pixels total
   // display 1024 pixels per line
   reg hblank,vblank;
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount == 1023);    
   assign hsyncon = (hcount == 1047);
   assign hsyncoff = (hcount == 1183);
   assign hreset = (hcount == 1343);

   // vertical: 806 lines total
   // display 768 lines
   wire vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount == 767);    
   assign vsyncon = hreset & (vcount == 776);
   assign vsyncoff = hreset & (vcount == 782);
   assign vreset = hreset & (vcount == 805);

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
   end
endmodule

//////////////////////////////////////////////////////////////////////
//
// blob: generate rectangle on screen
// top left corner is in x, y
//////////////////////////////////////////////////////////////////////
module blob
   #(parameter WIDTH = 64,            // default width: 64 pixels
               HEIGHT = 64,           // default height: 64 pixels
               COLOR = 24'hFF_FF_FF)  // default color: white
   (input [10:0] x,hcount,
    input [9:0] y,vcount,
    output reg [23:0] pixel);

   always @ * begin
      if ((hcount >= x && hcount < (x+WIDTH)) &&
	 (vcount >= y && vcount < (y+HEIGHT)))
	pixel = COLOR;
      else pixel = 0;
   end
endmodule

////////////////////////////////////////////////////////////////////////////////
//
// pong_game: the game itself!
//
////////////////////////////////////////////////////////////////////////////////

module pong_game (
   input vclock,	// 65MHz clock
   input reset,		// 1 to initialize module
   input up,		// 1 when paddle should move up
   input down,  	// 1 when paddle should move down
   input [3:0] pspeed,  // puck speed in pixels/tick 
   input [10:0] hcount,	// horizontal index of current pixel (0..1023)
   input [9:0] 	vcount, // vertical index of current pixel (0..767)
   input hsync,		// XVGA horizontal sync signal (active low)
   input vsync,		// XVGA vertical sync signal (active low)
   input blank,		// XVGA blanking (1 means output black pixel)
 	
   output phsync,	// pong game's horizontal sync
   output pvsync,	// pong game's vertical sync
   output pblank,	// pong game's blanking
   output [23:0] pixel	// pong game's pixel  // r=23:16, g=15:8, b=7:0
   );
	parameter SCR_WIDTH = 11'd1023;
	parameter SCR_HEIGHT = 10'd767;
	parameter PUCK_COLOR = 24'h00_00_FF;
	parameter PUCK_WIDTH = 16;
	parameter PUCK_HEIGHT = 16;
	parameter PADDLE_WIDTH = 16;
	parameter PADDLE_HEIGHT = 128;
	parameter PADDLE_SPEED = 4;
	parameter PADDLE_COLOR = 24'hFF_FF_00;
	parameter SQUARE_WIDTH = 128;
	parameter SQUARE_HEIGHT = 128;
	parameter SQUARE_COLOR = 24'hFF_00_00;
	parameter SQUARE_X = (SCR_WIDTH>>1) - (SQUARE_WIDTH>>1);
	parameter SQUARE_Y = (SCR_HEIGHT>>1) - (SQUARE_HEIGHT>>1);
	parameter X_POSMOVE = 1'b1; // puck in +x dir
	parameter Y_POSMOVE = 1'b1; // puck in +y dir
	parameter X_NEGMOVE = 1'b0; // puck in -x dir
	parameter Y_NEGMOVE = 1'b0; // puck in -y dir
	parameter HALTED = 1'b1; // halted state representation

	// collision state representaiton
	parameter COLL_PADDLE_TOP = 1'b1;
	parameter COLL_PADDLE_BOTTOM = 1'b1;
	parameter COLL_PADDLE_SIDE = 1'b1;
	parameter COLL_SCR_TOP = 1'b1;
	parameter COLL_SCR_BOTTOM = 1'b1;
	parameter COLL_SCR_RIGHT = 1'b1;
	
	wire[3:0] puck_xvel = pspeed;
	wire[3:0] puck_yvel = pspeed;
	
	wire[23:0] puck_pixel;
	wire[23:0] paddle_pixel;
	wire[23:0] square_pixel;
	
   assign phsync = hsync;
   assign pvsync = vsync;
   assign pblank = blank;

	
	// initialize all collision/direction/halt registers
	reg halted = ~HALTED;
	reg xdir = X_POSMOVE;
	reg ydir = Y_POSMOVE;
	reg coll_paddle_top = ~COLL_PADDLE_TOP;
	reg coll_paddle_bottom = ~COLL_PADDLE_BOTTOM;
	reg coll_paddle_side = ~COLL_PADDLE_SIDE;
	reg coll_scr_top = ~COLL_SCR_TOP;
	reg coll_scr_bottom = ~COLL_SCR_BOTTOM;
	reg coll_scr_right = ~COLL_SCR_RIGHT;
	
	// initialize puck in the center
	reg[10:0] puck_x = (SCR_WIDTH>>1) - (PUCK_WIDTH>>1);
	reg[9:0] puck_y = (SCR_HEIGHT>>1) - (PUCK_HEIGHT>>1);
	
	// initialize paddle in the center
	reg[9:0] paddle_y = (SCR_HEIGHT>>1) - (PADDLE_HEIGHT>>1);
	
	always @(posedge vsync) begin
		// handle reset
		if (reset) begin
			puck_x <= (SCR_WIDTH>>1) - (PUCK_WIDTH>>1);
			puck_y <= (SCR_HEIGHT>>1) - (PUCK_HEIGHT>>1);
			paddle_y <= (SCR_HEIGHT>>1) - (PADDLE_HEIGHT>>1);
			halted <= ~HALTED;
			coll_paddle_top <= ~COLL_PADDLE_TOP;
			coll_paddle_bottom <= ~COLL_PADDLE_BOTTOM;
			coll_paddle_side <= ~COLL_PADDLE_SIDE;
			coll_scr_top <= ~COLL_SCR_TOP;
			coll_scr_bottom <= ~COLL_SCR_BOTTOM;
			coll_scr_right <= ~COLL_SCR_RIGHT;
			xdir <= X_POSMOVE;
			ydir <= Y_POSMOVE;
		end
		
		else if (!halted) begin
			// movement of paddle
			if (up || down) begin
				if (up && (paddle_y > PADDLE_SPEED)) begin
					paddle_y <= paddle_y - PADDLE_SPEED;
				end
				else if (up && (paddle_y < PADDLE_SPEED)) begin
					paddle_y <= 0;
				end
				else if (down && (paddle_y < (SCR_HEIGHT-PADDLE_HEIGHT-PADDLE_SPEED))) begin
					paddle_y <= paddle_y + PADDLE_SPEED;
				end
				else if (down && (paddle_y > (SCR_HEIGHT-PADDLE_HEIGHT-PADDLE_SPEED))) begin
					paddle_y <= SCR_HEIGHT-PADDLE_HEIGHT;
				end
			end
			
			// if some collision took place
			if (	coll_paddle_side || 
					coll_paddle_top || 
					coll_paddle_bottom || 
					coll_scr_right ||
					coll_scr_top ||
					coll_scr_bottom
				) begin
				// what to do on the collisions
				if (coll_paddle_side) begin
					xdir <= X_POSMOVE;
					puck_x <= puck_x + puck_xvel;
					coll_paddle_side <= ~COLL_PADDLE_SIDE;
				end
				if (coll_paddle_top) begin
					ydir <= Y_NEGMOVE;
					puck_y <= puck_y - puck_yvel;
					coll_paddle_top <= ~COLL_PADDLE_TOP;
				end
				if (coll_paddle_bottom) begin
					ydir <= Y_POSMOVE;
					puck_y <= puck_y + puck_yvel;
					coll_paddle_bottom <= ~COLL_PADDLE_BOTTOM;
				end
				if (coll_scr_right) begin
					xdir <= X_NEGMOVE;
					puck_x <= puck_x - puck_xvel;
					coll_scr_right <= ~COLL_SCR_RIGHT;
				end
				if (coll_scr_top) begin
					ydir <= Y_POSMOVE;
					puck_y <= puck_y + puck_yvel;
					coll_scr_top <= ~COLL_SCR_TOP;
				end
				if (coll_scr_bottom) begin
					ydir <= Y_NEGMOVE;
					puck_y <= puck_y - puck_yvel;
					coll_scr_bottom <= ~COLL_SCR_BOTTOM;
				end
			end
			
			// all other cases
			else begin
				// condition for ``about to collide'' with left end of screen
				if ((puck_x <= puck_xvel)) begin
					puck_x <= 1;
					halted <= HALTED;
				end
				// condition for ``about to collide'' with side of paddle
				else if ((puck_x <= (PADDLE_WIDTH+puck_xvel)) && (paddle_y <= (puck_y+PUCK_HEIGHT))  && (puck_y <= (paddle_y+PADDLE_HEIGHT))) begin
					puck_x <= PADDLE_WIDTH;
					coll_paddle_side <= COLL_PADDLE_SIDE;
				end
				// condition for ``about to collide'' with top of paddle
				if (((puck_y+puck_yvel+PUCK_HEIGHT) >= paddle_y) && (puck_x <= PADDLE_WIDTH)) begin
					puck_y <= paddle_y-PUCK_HEIGHT;
					coll_paddle_top <= COLL_PADDLE_TOP;
				end			
				// condition for ``about to collide'' with bottom of paddle
				if ((puck_y <= (puck_yvel+paddle_y+PADDLE_HEIGHT)) && (puck_x <= PADDLE_WIDTH)) begin
					puck_y <= paddle_y+PADDLE_HEIGHT;
					coll_paddle_bottom <= COLL_PADDLE_BOTTOM;
				end		
				// condition for ``about to collide'' with right end of screen
				if (xdir == X_POSMOVE && ((puck_x + puck_xvel) > (SCR_WIDTH-PUCK_WIDTH))) begin
					puck_x <= SCR_WIDTH-PUCK_WIDTH;
					coll_scr_right <= COLL_SCR_RIGHT;
				end
				// condition for ``about to collide'' with top of screen
				if (ydir == Y_NEGMOVE && (puck_y < puck_yvel)) begin
					puck_y <= 0;
					coll_scr_top <= COLL_SCR_TOP;
				end
				// condition for ``about to collide'' with bottom of screen
				if (ydir == Y_POSMOVE && ((puck_y + puck_yvel) > (SCR_HEIGHT-PUCK_HEIGHT))) begin
					puck_y <= SCR_HEIGHT-PUCK_HEIGHT;
					coll_scr_bottom <= COLL_SCR_BOTTOM;
				end

		

				// normal movement of puck
				else begin
					if (xdir == X_POSMOVE) begin
						puck_x <= puck_x + puck_xvel;
					end
					if (xdir == X_NEGMOVE) begin
						puck_x <= puck_x - puck_xvel;
					end
					if (ydir == Y_POSMOVE) begin
						puck_y <= puck_y + puck_yvel;
					end
					if (ydir == Y_NEGMOVE) begin
						puck_y <= puck_y - puck_yvel;
					end				
				end
			end
		end
	end		

	
	// instantiate a white puck in the center
	blob #(.WIDTH(PUCK_WIDTH), .HEIGHT(PUCK_HEIGHT), .COLOR(PUCK_COLOR))
     puck(	.x(puck_x),
				.y(puck_y),
				.hcount(hcount),
				.vcount(vcount),
            .pixel(puck_pixel));
	
	// initialize a red square in the middle
	blob #(.WIDTH(SQUARE_WIDTH), .HEIGHT(SQUARE_HEIGHT), .COLOR(SQUARE_COLOR))
		square(	.x(SQUARE_X),
					.y(SQUARE_Y),
					.hcount(hcount),
					.vcount(vcount),
					.pixel(square_pixel));
	
	// intialize a yellow paddle on the side
	blob #(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT), .COLOR(PADDLE_COLOR))
		paddle(	.x(0),
					.y(paddle_y),
					.hcount(hcount),
					.vcount(vcount),
					.pixel(paddle_pixel));
	
	wire[7:0] mixedpixel_b = (puck_pixel[7:0] + square_pixel[7:0]) >> 1;
	wire[7:0] mixedpixel_g = (puck_pixel[15:8] + square_pixel[15:8]) >> 1;
	wire[7:0] mixedpixel_r = (puck_pixel[23:16] + square_pixel[23:16]) >> 1;
	
	assign pixel = {mixedpixel_r, mixedpixel_g, mixedpixel_b} + paddle_pixel;
     
endmodule
