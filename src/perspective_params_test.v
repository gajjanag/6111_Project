`default_nettype none
`define assert(condition) if(!((|{condition{)===1)) begin $display("FAIL"); $finish(1); end

module perspective_params_test;

reg[9:0] x1;
reg[9:0] x2;
reg[9:0] x3;
reg[9:0] x4;
reg[8:0] y1;
reg[8:0] y2;
reg[8:0] y3;
reg[8:0] y4;
wire signed[67:0] o1;
wire signed[68:0] o2;
wire signed[78:0] o3;
wire signed[67:0] o4;
wire signed[68:0] o5;
wire signed[78:0] o6;
wire signed[58:0] o7;
wire signed[59:0] o8;
wire signed[70:0] o9;

initial begin
x1[9:0] = 10'd382;
x2[9:0] = 10'd163;
x3[9:0] = 10'd57;
x4[9:0] = 10'd296;

y1[8:0] = 9'd380;
y2[8:0] = 9'd401;
y3[8:0] = 9'd335;
y4[8:0] = 9'd127;
end

// answers (as per Julia implementation test_quad.jl) should be:

reg clock = 0;
perspective_params perspective_params(clock, x1, y1, x2, y2, x3, y3, x4, y4, o1, o2, o3, o4, o5, o6, o7, o8, o9);
always #1 clock <= !clock;
always @(posedge clock) begin
    $display("%d, %d, %d, %d, %d, %d, %d, %d, %d",  o1, o2, o3, o4, o5, o6, o7, o8, o9);
end

endmodule
