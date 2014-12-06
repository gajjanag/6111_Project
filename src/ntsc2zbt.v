/**
NOTE: Code borrowed heavily from Pranav Kaundinya, et. al. (2012).
*/

module ntsc_to_bram(clk, vclk, fvh, dv, din, ntsc_addr, ntsc_data, ntsc_we, sw);

   input 	 clk;	// system clock
   input 	 vclk;	// video clock from camera
   input [2:0] 	 fvh;
   input 	 dv;
   input [29:0] 	 din;
	input sw;
   output reg [16:0] ntsc_addr;
   output reg [11:0] ntsc_data;
   output 	 ntsc_we;	// write enable for NTSC data
   parameter 	 COL_START = 10'd0;
   parameter 	 ROW_START = 10'd0;

   	reg [9:0] 	 col = 0;
	reg [9:0] 	 row = 0;
	reg [29:0] 	 vdata = 0;
	reg 		 vwe;
	reg 		 old_dv;
	reg 		 old_frame;	// frames are even / odd interlaced
	reg 		 even_odd;	// decode interlaced frame to this wire
	
	wire 	 frame = fvh[2];
	wire 	 frame_edge = frame & ~old_frame;
     
	always @ (posedge vclk) begin//LLC1 is reference   
	   
			old_dv <= dv;
			vwe <= dv && !fvh[2] & ~old_dv; // if data valid, write it

			old_frame <= frame;
			even_odd = frame_edge ? ~even_odd : even_odd;

			if (!fvh[2]) begin
			     col <= fvh[0] ? COL_START : 
				    (!fvh[2] && !fvh[1] && dv && (col < 1024)) ? col + 1 : col;
			     row <= fvh[1] ? ROW_START : 
				    (!fvh[2] && fvh[0] && (row < 768)) ? row + 1 : row;
			     vdata <= (dv && !fvh[2]) ? din : vdata;			
		  	end
	end

   // synchronize with system clock

	reg [9:0] x[1:0],y[1:0];
	reg [29:0] data[1:0];
	reg       we[1:0];
	reg 	  eo[1:0];

	always @(posedge clk)begin 
     	
		{x[1],x[0]} <= {x[0],col};
		{y[1],y[0]} <= {y[0],row};
		{data[1],data[0]} <= {data[0],vdata};
		{we[1],we[0]} <= {we[0],vwe};
		{eo[1],eo[0]} <= {eo[0],even_odd};
     end

   // edge detection on write enable signal

   	reg old_we;
	wire we_edge = we[1] & ~old_we;
	always @(posedge clk) old_we <= we[1];

   // shift each set of four bytes into a large register for the ZBT
   
   	// compute address to store data in
   	wire [9:0] y_addr = {y[1][8:0], eo[1]};
   	wire [9:0] x_addr = x[1];
		
		wire [7:0] R, G, B;
		ycrcb2rgb conv( R, G, B, clk, 1'b0, data[1][29:20],
			data[1][19:10], data[1][9:0] );
	
   	wire [16:0] myaddr_o = (y_addr[7:0] << 8) + (y_addr[7:0] << 6) + x_addr[8:0];
		wire [16:0] myaddr;
		synchronize #(.NSYNC(3), .W(17)) myaddr_sync(clk, myaddr_o, myaddr);
   // update the output address and data only when four bytes ready

   	wire ntsc_we_o = (x_addr < COL_START + 10'd320 && y_addr < ROW_START + 10'd240) && (we_edge);

		synchronize #(.NSYNC(3)) we_sync(clk, ntsc_we_o, ntsc_we);
   	always @(posedge clk)
     	if ( ntsc_we ) begin
	  			ntsc_addr <= myaddr;	// normal and expanded modes
	  			ntsc_data <= ~sw ? {R[7:4], G[7:4], B[7:4]} :
					{x_addr[9], 3'b0, x_addr[8], 3'b0, x_addr[7], 3'b0};
       	end
   
endmodule // ntsc_to_zbt
