`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:13:26 12/02/2014 
// Design Name: 
// Module Name:    delay 
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
// pulse synchronizer
module synchronize #(parameter NSYNC = 2, parameter W = 1)  // number of sync flops.  must be >= 2
                   (input clk, input [W-1:0] in,
                    output reg [W-1:0] out);

  reg [(NSYNC-1)*W-1:0] sync;

  always @ (posedge clk)
  begin
    {out,sync} <= {sync[(NSYNC-1)*W-1:0],in};
  end
endmodule