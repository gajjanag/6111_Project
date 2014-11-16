`default_nettype none
`define assert(condition) if(!((|{condition{)===1)) begin $display("FAIL"); $finish(1); end

module perspective_params_test;

reg[6:0] x1;
reg[6:0] x2;
reg[6:0] x3;
reg[6:0] x4;
reg[5:0] y1;
reg[5:0] y2;
reg[5:0] y3;
reg[5:0] y4;
wire signed[25:0] o1;
wire signed[25:0] o2;
wire signed[27:0] o3;
wire signed[24:0] o4;
wire signed[24:0] o5;
wire signed[26:0] o6;
wire signed[17:0] o7;
wire signed[17:0] o8;
wire signed[19:0] o9;

initial begin
x1[6:0] = 7'd50;
x2[6:0] = 7'd45;
x3[6:0] = 7'd29;
x4[6:0] = 7'd45;

y1[5:0] = 6'd30;
y2[5:0] = 6'd51;
y3[5:0] = 6'd47;
y4[5:0] = 6'd16;
end

reg clock = 0;
perspective_params perspective_params(x1, y1, x2, y2, x3, y3, x4, y4, o1, o2, o3, o4, o5, o6, o7, o8, o9);
always #1 clock <= !clock;
always @(posedge clock) begin
$display("%d, %d, %d, %d, %d, %d, %d, %d, %d", o1, o2, o3, o4, o5, o6, o7, o8, o9);
end

endmodule
