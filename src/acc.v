`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:26:11 11/16/2014 
// Design Name: 
// Module Name:    acc 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
/*
output starts on same cycle start is asserted
high-order bits produced first
input only needs to be supplied on the cycle that start is high
produces zeros if input exhausted
assume W > 1
*/
module par_to_ser #(parameter W=8)
	(input clk /* device clock */, input[W-1:0] par,
	input start, output ser);	
	reg[W-1:0] par_reg = 0;

	always @(posedge clk) begin
		if (start) begin
			par_reg <= {par[W-2:0], 1'b0};	
		end
		else begin
			par_reg <= {par_reg[W-2:0], 1'b0};
		end
	end	

	assign ser = start ? par[W-1] : par_reg[W-1];
endmodule

/*
output appears W-1 clock cycles after first serial bit sent
assume high-order bits are input first
assume W > 2
*/
module ser_to_par #(parameter W=8)
	(input clk /* device clock */, input ser,
	output[W-1:0] par);	
	reg[W-2:0] par_reg = 0;
	
	always @(posedge clk) begin
		par_reg <= {par_reg[W-3:0], ser};
	end	

	assign par = {par_reg, ser};
endmodule

/*
reduces the system clock by a factor of 6
*/
module acc_clk(input clk /* system clock */, output dev_clk);
	parameter TICKS = 9;
	
	reg [3:0] count = 0;
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
	assign dev_clk = sig_reg;
endmodule

/*
assert in_ready when a new datapoint is available, avg_ready will
be signalled after 32 data points have been folded into the average
*/
module moving_avg(
  input clock, in_ready, reset,
  input signed [15:0] data,
  output signed [15:0] avg,
  output avg_ready
);
	// circular buffer
	reg signed [15:0] samples [31:0];
	
	reg [4:0] offset = 0;
	reg signed [15:0] accum = 0;
	reg [5:0] num_samples = 0;
	reg signed [15:0] data_right_shift;
	
	always @(*) begin
		data_right_shift = {data[15], data[15], data[15], data[15],
			data[15], data[15:5]};
	end
	
	always @(posedge clock) begin
		if (reset) begin
			accum <= 0;
			num_samples <= 0;
			offset <= 0;
		end
		else if (in_ready) begin
			num_samples <= (num_samples == 6'd32) ? num_samples : num_samples + 1;
			samples[offset] <= data_right_shift;
			if (num_samples == 6'd32) begin
				accum <= accum + data_right_shift - samples[offset];
			end
			else begin
				accum <= accum + data_right_shift;
			end
			offset <= offset + 1;
		end
	end
  
  assign avg = accum;
  assign avg_ready = (num_samples == 6'd32) ? 1 : 0;
endmodule

/*
ready permanently asserted after initialization completed
acc operates completely with the slowed accelerometer clock
*/
module acc(input clk /* system clock */, sdo, reset,
	output ncs, sda, scl, ready, output signed [15:0] x, y);
	// TODO use state machine -- transition through all of the initiatialization states (each
	// register), then rotate through the value reading states
	// one cycle gap between states to allow for CS deassertion
	parameter MEASURE_INIT = 0;
	parameter X_READ = 1;
	parameter Y_READ = 2;
	reg[1:0] state = MEASURE_INIT; // TODO: set the right number of bits for this
	reg[4:0] count = 0; // TODO: set the right number of bits for this
	
	reg ncs_reg;

	wire dev_clk;
	acc_clk ac(.clk(clk), .dev_clk(dev_clk));

	reg[7:0] par_in;
	reg pts_start;
	par_to_ser pts(.clk(dev_clk), .par(par_in), .start(pts_start), .ser(sda));

	wire[7:0] par_out;
	ser_to_par stp(.clk(dev_clk), .ser(sdo), .par(par_out));
	
	reg ma_x_in_ready;
	reg [7:0] x_low_bits = 0;
	reg signed [15:0] ma_x_in;
	wire ma_x_avg_ready;
	wire signed [15:0] ma_x_avg;
	moving_avg ma_x(
	  .clock(dev_clk), .in_ready(ma_x_in_ready), .reset(reset),
	  .data(ma_x_in),
	  .avg(ma_x_avg),
	  .avg_ready(ma_x_avg_ready)
	);
	
	reg ma_y_in_ready;
	reg [7:0] y_low_bits = 0;
	reg signed [15:0] ma_y_in;
	wire ma_y_avg_ready;
	wire signed [15:0] ma_y_avg;
	moving_avg ma_y(
	  .clock(dev_clk), .in_ready(ma_y_in_ready), .reset(reset),
	  .data(ma_y_in),
	  .avg(ma_y_avg),
	  .avg_ready(ma_y_avg_ready)
	);
	
	// invariants: when transitioning out of a state always set counter to 0
	always @(posedge dev_clk) begin
		case (state)
			MEASURE_INIT: begin
				if (count == 5'd18) begin
					count <= 0;
					state <= X_READ;
				end
				else begin
					count <= count + 1;
				end
			end
			X_READ: begin
				if (count == 5'd25) begin
					count <= 0;
					state <= Y_READ;
				end
				else begin
					count <= count + 1;
				end
				if (count == 5'd17) begin
					x_low_bits <= par_out;
				end
			end
			Y_READ: begin
				if (count == 5'd25) begin
					count <= 0;
					state <= X_READ;
				end
				else begin
					count <= count + 1;
				end
				if (count == 5'd17) begin
					y_low_bits <= par_out;
				end
			end
		endcase
	end
	
	always @(*) begin
		case (state)
			MEASURE_INIT: begin
				pts_start = (count == 5'd2 || count == 5'd10) ? 1 : 0;
				if (count == 5'd2) begin
					par_in = 8'h2D; // 0 for W, 0 for MB
				end
				else if (count == 5'd10) begin
					par_in = 8'h08; // set measure bit
				end
				else begin
					par_in = 0;
				end
				ma_x_in_ready = 0; ma_x_in = 0;
				ma_y_in_ready = 0; ma_y_in = 0;
				ncs_reg = (count == 5'd18 || count == 5'd0) ? 1 : 0;
			end
			X_READ: begin
				pts_start = (count == 5'd1) ? 1 : 0;
				par_in = (count == 5'd1) ? 8'hF2 : 0; // 1 for R, 1 for MB 
				ma_x_in_ready = (count == 5'd25) ? 1 : 0;
				ma_x_in = (count == 5'd25) ? {par_out, x_low_bits} : 0;
				ma_y_in_ready = 0; ma_y_in = 0;
				ncs_reg = (count == 5'd25) ? 1 : 0;
			end
			Y_READ: begin
				pts_start = (count == 5'd1) ? 1 : 0;
				par_in = (count == 5'd1) ? 8'hF4 : 0; // 1 for R, 1 for MB 
				ma_y_in_ready = (count == 5'd25) ? 1 : 0;
				ma_y_in = (count == 5'd25) ? {par_out, y_low_bits} : 0;
				ma_x_in_ready = 0; ma_x_in = 0;
				ncs_reg = (count == 5'd25) ? 1 : 0;			
			end
		endcase
	end

	
	assign scl = (ncs_reg == 1 || (state == MEASURE_INIT && count == 5'd1
		|| state != MEASURE_INIT && count == 5'd0)) ? 1 : dev_clk;
	assign ncs = ncs_reg;
	assign ready = ma_x_avg_ready && ma_y_avg_ready;
	assign x = ma_x_avg;
	assign y = ma_y_avg;
endmodule