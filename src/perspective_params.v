////////////////////////////////////////////////////////////////////////////////
// perspective_params: Generate the parameters for the perspective transform from the
// rectangle to the quadrilateral inside it
// Note that this is the forward mapping
// The math is described as follows
// Let (x1, y1), (x2, y2), (x3, y3), (x4, y4) be the four points inside the
// screen
// Let the (forward) perspective map be given by:
// (X, Y) = ((p1*x + p2*y + p3)/(p7*x + p8*y + p9), (p4*x + p5*y + p6)/(p7*x
// + p8*y + p9))
// Then our task is to determine the values of p_i given the values of the x_i
// This is a system of equations in 8 unknowns
// It turns out that a pretty simple closed form solution exists, given by
//
// p7 = 3((x1-x4)(y2-y3) + 3(y1-y4)(x3-x2))
// p8 = 4((x1-x2)(y3-y4) + 4(x4-x3)(y1-y2))
// denom = x4(y2-y3) + x2(y3-y4) + x3(y4-y2)
// p9 = 1920*denom (2^7 * 15 * denom)
// p3 = 1920*x1*denom (2^7 * 15 * x1 * denom)
// p6 = 1920*y1*denom (2^7 * 15 * y1 * denom)
// p1 = x4*p7 + 3(x2-x1)*denom
// p2 = x2*p8 + 4(x4-x1)*denom
// p4 = y4*p7 + 3(y4-y1)*denom
// p5 = y2*p8 + 4(y2-y1)*denom
//
// The main issue is picking a good fixed point representation
// I settled on the following:
// p7, p8 -> exact numbers in terms of the xi, yi
// p3, p6 -> exact numbers in terms of the xi,yi, so finally need to
// nultiply by 2^7
// p9 -> exact numbers in terms of the xi, yi, so finally need to multiply by
// 2^7
// p1, p2, p4, p5 -> exact numbers in terms of the xi, yi
// equivalently, can scale all params by a constant
// (THIS MODULE DOES NOT DO ANY OF THAT)
////////////////////////////////////////////////////////////////////////////////

module perspective_params(input clk,
                input[9:0] x1,
                input[8:0] y1,
                input[9:0] x2,
                input[8:0] y2,
                input[9:0] x3,
                input[8:0] y3,
                input[9:0] x4,
                input[8:0] y4,
                // reason for the hardcoded numbers is FPGA limitations on
                // multiplier bitwidths (s18 x s18 yields s35)
                // Note: guaranteed, mathematically proven bitwidths are:
                // 36, 36, 44, 35, 35, 43, 24, 24, 33
                output reg signed[35:0] p1,
                output reg signed[35:0] p2,
                output reg signed[43:0] p3,
                output reg signed[34:0] p4,
                output reg signed[34:0] p5,
                output reg signed[42:0] p6,
                output reg signed[23:0] p7,
                output reg signed[23:0] p8,
                output reg signed[32:0] p9);

wire signed[10:0] sx1, sx2, sx3, sx4;
wire signed[9:0] sy1, sy2, sy3, sy4;
wire signed[10:0] d_x1_x2,d_x2_x3,d_x3_x4,d_x4_x1;
wire signed[9:0] d_y1_y2, d_y2_y3, d_y3_y4, d_y4_y1, d_y4_y2;

// p7, p8 computation
wire signed[20:0] num0, num1, num2, num3;
wire signed[21:0] p7_temp, p8_temp;
wire signed[23:0] p7_wire, p8_wire;

// denom computation
wire signed[20:0] denom0, denom1, denom2;
wire signed[21:0] denom;

// p3, p6, p9 computation
wire signed[25:0] denom_15;
wire signed[32:0] p9_wire;
wire signed[32:0] x1_denom;
wire signed[36:0] x1_denom_15;
wire signed[43:0] p3_wire;
wire signed[31:0] y1_denom;
wire signed[35:0] y1_denom_15;
wire signed[42:0] p6_wire;

// p1, p2, p4, p5 computation
wire signed[32:0] d_x1_x2_denom;
wire signed[32:0] d_x4_x1_denom;
wire signed[31:0] d_y4_y1_denom;
wire signed[31:0] d_y1_y2_denom;
wire signed[34:0] d_x1_x2_denom_scale;
wire signed[34:0] d_x4_x1_denom_scale;
wire signed[33:0] d_y4_y1_denom_scale;
wire signed[33:0] d_y1_y2_denom_scale;
wire signed[34:0] x4_p7;
wire signed[34:0] x2_p8;
wire signed[33:0] y4_p7;
wire signed[33:0] y2_p8;
wire signed[35:0] p1_wire, p2_wire;
wire signed[34:0] p4_wire, p5_wire;

// sign extensions
assign sx1 = {0'b0, x1};
assign sx2 = {0'b0, x2};
assign sx3 = {0'b0, x3};
assign sx4 = {0'b0, x4};
assign sy1 = {0'b0, y1};
assign sy2 = {0'b0, y2};
assign sy3 = {0'b0, y3};
assign sy4 = {0'b0, y4};

// difference values for computation
assign d_x1_x2 = sx1 - sx2;
assign d_x2_x3 = sx2 - sx3;
assign d_x3_x4 = sx3 - sx4;
assign d_x4_x1 = sx4 - sx1;
assign d_y1_y2 = sy1 - sy2;
assign d_y2_y3 = sy2 - sy3;
assign d_y3_y4 = sy3 - sy4;
assign d_y4_y1 = sy4 - sy1;
assign d_y4_y2 = sy4 - sy2;

// computation of p7, p8
assign num0 = -d_x4_x1 * d_y2_y3;
assign num1 = d_y4_y1 * d_x2_x3;
assign num2 = d_x1_x2 * d_y3_y4;
assign num3 = -d_x3_x4 * d_y1_y2;
assign p7_temp = num0 + num1;
assign p8_temp = num2 + num3;
assign p7_wire = (p7_temp <<< 1) + p7_temp;
assign p8_wire = (p8_temp <<< 2);

// computation of denom
assign denom0 = sx4 * d_y2_y3;
assign denom1 = sx2 * d_y3_y4;
assign denom2 = sx3 * d_y4_y2;
assign denom = denom0 + denom1 + denom2;

// computation of p3, p6, p9
// observe that 1920 = 2^7 * 15
assign denom_15 = (denom <<< 4) - denom; // denom * 15
assign p9_wire = denom_15 <<< 7; // denom * 1920
assign x1_denom = sx1 * denom; // x1 * denom
assign x1_denom_15 = (x1_denom <<< 4) - x1_denom; // x1 * denom * 15
assign p3_wire = x1_denom_15 <<< 7; // x1 * denom * 1920
assign y1_denom = sy1 * denom; // y1 * denom
assign y1_denom_15 = (y1_denom <<< 4) - y1_denom; // y1 * denom * 15
assign p6_wire = y1_denom_15 <<< 7; // y1 * denom * 1920

// computation of p1, p2, p4, p5
assign d_x1_x2_denom = d_x1_x2 * denom;
assign d_x4_x1_denom = d_x4_x1 * denom;
assign d_y4_y1_denom = d_y4_y1 * denom;
assign d_y1_y2_denom = d_y1_y2 * denom;
assign d_x1_x2_denom_scale = (d_x1_x2_denom <<< 1) + d_x1_x2_denom; // d_x1_x2_denom*3
assign d_x4_x1_denom_scale = (d_x4_x1_denom <<< 2); // d_x4_x1_denom*4
assign d_y4_y1_denom_scale = (d_y4_y1_denom <<< 1) + d_y4_y1_denom; // d_y4_y1_denom*3
assign d_y1_y2_denom_scale = (d_y1_y2_denom <<< 2); // d_y1_y2_denom*4
assign x4_p7 = sx4 * p7;
assign x2_p8 = sx2 * p8;
assign y4_p7 = sy4 * p7;
assign y2_p8 = sy2 * p8;
assign p1_wire = x4_p7 - d_x1_x2_denom_scale;
assign p2_wire = x2_p8 + d_x4_x1_denom_scale;
assign p4_wire = y4_p7 + d_y4_y1_denom_scale;
assign p5_wire = y2_p8 - d_y1_y2_denom_scale;

always @(posedge clk) begin
    p1 <= p1_wire;
    p2 <= p2_wire;
    p3 <= p3_wire;
    p4 <= p4_wire;
    p5 <= p5_wire;
    p6 <= p6_wire;
    p7 <= p7_wire;
    p8 <= p8_wire;
    p9 <= p9_wire;
end

endmodule
