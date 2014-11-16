`default_nettype none
`define assert(condition) if(!((|{condition{)===1)) begin $display("FAIL"); $finish(1); end

module pixel_map_test;

reg[9:0] x;
reg[8:0] y;
reg signed[25:0] p1;
reg signed[25:0] p2;
reg signed[27:0] p3;
reg signed[24:0] p4;
reg signed[24:0] p5;
reg signed[26:0] p6;
reg signed[17:0] p7;
reg signed[17:0] p8;
reg signed[19:0] p9;

wire signed[36:0] num_x;
wire signed[36:0] denom;
wire signed[36:0] num_y;
wire[9:0] ox;
wire[8:0] oy;
wire ready;
wire signed[36:0] ox_signed;
wire signed[36:0] oy_signed;

initial begin
x = 10'd0;
y = 9'd0;
p1[25:0] = -26'd35_940;
p2[25:0] = -26'd43_780;
p3[27:0] = 28'd420_000;
p4[24:0] = -25'd33_312;
p5[24:0] = 25'd10_116;
p6[26:0] = 27'd252_000;
p7[17:0] = -18'd612;
p8[17:0] = -18'd724;
p9[19:0] = 20'd8400;
end

reg clock = 0;
pixel_map pixel_map(clock, x, y, p1, p2, p3, p4, p5, p6, p7, p8, p9, num_x, denom, num_y, ox_signed, oy_signed, ox, oy, ready);
always #50 clock <= !clock;
always @(posedge clock) begin
$display("%d, %d, %d, %d, %d, %d, %d, %d", ox, oy, ready, num_x, denom, num_y, ox_signed, oy_signed);
end

endmodule
