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
// denom = x4(y2-y3) + x2(y3-y4) + x3(y4-y2)
// p9 = 1920*denom (2^7 * 15 * denom)
// p3 = 1920*x1*denom (2^7 * x1 * denom)
// p6 = 1920*y1*denom (2^7 * y1 * denom)
// p7 = 3((x1-x4)(y2-y3) + 3(y1-y4)(x3-x2))
// p8 = 4((x1-x2)(y3-y4) + 4(x4-x3)(y1-y2))
// p1 = x4*p7 + 3(x2-x1)*denom
// p2 = x2*p8 + 4(x4-x1)*denom
// p4 = y4*p7 + 3(y4-y1)*denom
// p5 = y2*p8 + 4(y2-y1)*denom
//
// The main issue is picking a good fixed point representation
// I settled on the following:
// xi, yi -> multiples of 8 pixels, so x <= 80, y <= 60
// rationale is that adjustment past 2% of scr_width/height is not noticeable
// p7, p8 -> exact numbers in terms of the xi, yi, so finally need to multiply
// by 2^6
// p3, p6 -> exact numbers in terms of the xi,yi, so finally need to
// nultiply by 2^7 * 2^9 = 2^16
// p9 -> exact numbers in terms of the xi, yi, so finally need to multiply by
// 2^13
// p1, p2, p4, p5 -> exact numbers in terms of the xi, yi, so finally need to
// multiply by 2^9
// equivalently, can scale all params by a constant
// (THIS MODULE DOES NOT DO ANY OF THAT)
////////////////////////////////////////////////////////////////////////////////

module perspective_params(input[6:0] x1, // x, y are pixel coords divided by 8, i.e x <= 80, y <= 60
                input[5:0] y1,
                input[6:0] x2,
                input[5:0] y2,
                input[6:0] x3,
                input[5:0] y3,
                input[6:0] x4,
                input[5:0] y4,
                // reason for the hardcoded numbers is FPGA limitations on
                // multiplier bitwidths (s18 x s18 yields s35)
                // Note: guaranteed, mathematically proven bitwidths are:
                // 26, 26, 28, 25, 25, 27, 18, 18, 20
                output wire signed[25:0] p1,
                output wire signed[25:0] p2,
                output wire signed[27:0] p3,
                output wire signed[24:0] p4,
                output wire signed[24:0] p5,
                output wire signed[26:0] p6,
                output wire signed[17:0] p7,
                output wire signed[17:0] p8,
                output wire signed[19:0] p9);

    wire signed[7:0] d_x1_x2,d_x2_x3,d_x3_x4,d_x4_x1;
    wire signed[6:0] d_y1_y2, d_y2_y3, d_y3_y4, d_y4_y1, d_y4_y2;
    wire signed[7:0] sx1, sx2, sx3, sx4;
    wire signed[6:0] sy1, sy2, sy3, sy4;
    wire signed[14:0] denom0, denom1, denom2;
    wire signed[15:0] denom;
    wire signed[14:0] num0, num1, num2, num3;
    wire signed[15:0] p7_temp, p8_temp;
    wire signed[22:0] p3_temp, p6_temp;
    wire signed[16:0] p9_temp;
    wire signed[21:0] p1_temp, p2_temp;
    wire signed[20:0] p4_temp, p5_temp;
    wire signed[11:0] scr_lcm_x1;
    wire signed[10:0] scr_lcm_y1;
    wire signed[23:0] d_x1_x2_denom;
    wire signed[23:0] d_x4_x1_denom;
    wire signed[22:0] d_y4_y1_denom;
    wire signed[22:0] d_y1_y2_denom;
    wire signed[25:0] d_x1_x2_denom_scale;
    wire signed[25:0] d_x4_x1_denom_scale;
    wire signed[24:0] d_y4_y1_denom_scale;
    wire signed[24:0] d_y1_y2_denom_scale;
    wire signed[25:0] x4_p7;
    wire signed[25:0] x2_p8;
    wire signed[24:0] y4_p7;
    wire signed[24:0] y2_p8;


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

    // computation of denom
    assign denom0 = sx4 * d_y2_y3;
    assign denom1 = sx2 * d_y3_y4;
    assign denom2 = sx3 * d_y4_y2;
    assign denom = denom0 + denom1 + denom2; // TODO: check overflow

    // computation of p3, p6, p9
    // observe that 1920 = 2^7 * 15
    assign p9_temp = (denom <<< 4) - denom; // denom*15
    assign scr_lcm_x1 = (sx1 <<< 4) - sx1; // x1*15
    assign scr_lcm_y1 = (sy1 <<< 4) - sy1; // x2*15
    assign p3_temp = scr_lcm_x1 * denom;
    assign p6_temp = scr_lcm_y1 * denom;
    assign p9 = p9_temp;
    assign p6 = p6_temp;
    assign p3 = p3_temp;

    // computation of p7, p8
    assign num0 = -d_x4_x1 * d_y2_y3;
    assign num1 = d_y4_y1 * d_x2_x3;
    assign num2 = d_x1_x2 * d_y3_y4;
    assign num3 = -d_x3_x4 * d_y1_y2;
    assign p7_temp = num0 + num1;
    assign p8_temp = num2 + num3;
    assign p7 = (p7_temp <<< 1) + p7_temp;
    assign p8 = (p8_temp <<< 2);

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
    assign p1_temp = x4_p7 - d_x1_x2_denom_scale;
    assign p2_temp = x2_p8 + d_x4_x1_denom_scale;
    assign p4_temp = y4_p7 + d_y4_y1_denom_scale;
    assign p5_temp = y2_p8 - d_y1_y2_denom_scale;
    assign p1 = p1_temp;
    assign p2 = p2_temp;
    assign p4 = p4_temp;
    assign p5 = p5_temp;

endmodule
