`default_nettype none
`define assert(condition) if(!((|{condition{)===1)) begin $display("FAIL"); $finish(1); end

module pixels_lot_test;

reg[9:0] x1;
reg[8:0] y1;
reg[9:0] x2;
reg[8:0] y2;
reg[9:0] x3;
reg[8:0] y3;
reg[9:0] x4;
reg[8:0] y4;

wire[6:0] percent_lost;

initial begin
x1 = 10'd80;
y1 = 9'd80;
x2 = 10'd80;
y2 = 9'd160;
x3 = 10'd160;
y3 = 9'd160;
x4 = 10'd160;
y4 = 9'd80;
end

reg clock = 0;
pixels_lost pixels_lost(clock, x1, y1, x2, y2, x3, y3, x4, y4, percent_lost);
always #1 clock <= !clock;
always @(posedge clock) begin
$display("%d, %d, %d, %d, %d, %d, %d, %d, %d", x1, y1, x2, y2, x3, y3, x4, y4, percent_lost);
end

endmodule
