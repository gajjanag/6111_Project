// A simple bram module
// stores 12 bit words (each is 1 pixel)
// the number of words is 320x240 (we store that resolution)
module bram(input wire a_clk,
	input wire a_wr,
	input wire[16:0] a_addr,
	input wire[11:0] a_din,
	output reg[11:0] a_dout,
	input wire b_clk,
	input wire b_wr,
	input wire[16:0] b_addr,
	input wire[11:0] b_din,
	output reg[11:0] b_dout);

// Shared memory
reg [11:0] mem [76799:0];

// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end

// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end

endmodule
