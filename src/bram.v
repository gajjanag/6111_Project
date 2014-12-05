`default_nettype none
///////////////////////////////////////////////////////////////////////////////////////////////////
// A simple true dual-port bram module, with hardcoded sizes
// number of lines: 320*240 = 76800
// data word width: 12 bits (4 bits r, 4 bits g, 4 bits b, one pixel per line)
// use here is to store a (downsampled) 640x480 frame at reduced resolution
// that can fit in bram (approx 1 Mbit usage per instantiation)
// Xilinx ISE infers the correct synthesis, and thus this module avoids
// unnecessary Coregen usage
//
// credits: http://danstrother.com/2010/09/11/inferring-rams-in-fpgas/
///////////////////////////////////////////////////////////////////////////////////////////////////
module bram(input wire a_clk,
    input wire a_wr,
    input wire[16:0] a_addr,
    input wire[11:0] a_din,
    input wire b_clk,
    input wire[16:0] b_addr,
    output reg[11:0] b_dout);

// Shared memory
reg[11:0] mem[76799:0];

// Port A
always @(posedge a_clk) begin
    if (a_wr) begin
        mem[a_addr] <= a_din;
    end
end

// Port B
always @(posedge b_clk) begin
    b_dout <= mem[b_addr];
end

endmodule
