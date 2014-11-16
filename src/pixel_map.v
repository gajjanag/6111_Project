////////////////////////////////////////////////////////////////////////////////
// pixel_map: Given the parameters of the perspective transform, find where
// a point in the original rectangle maps onto
// This is described by the simple eqn: (X, Y) = ((p1x + p2y + p3)/(p7x + p8y
// + p9), (p4x + p5y + p6)/(p7x + p8y + p9))
// the rest is just keeping track of fixed point, etc
// module accepts coord x, y (in the 640x480 screen), and outputs coord ox, oy by using p1, p2, p3,
// p4, p5, p6, p7, p8, p9 as inputs
////////////////////////////////////////////////////////////////////////////////
`include "divider.v"
module pixel_map(input clk,
                input[9:0] x,
                input[8:0] y,
                input wire signed[25:0] p1,
                input wire signed[25:0] p2,
                input wire signed[27:0] p3,
                input wire signed[24:0] p4,
                input wire signed[24:0] p5,
                input wire signed[26:0] p6,
                input wire signed[17:0] p7,
                input wire signed[17:0] p8,
                input wire signed[19:0] p9,
                output wire signed[36:0] num_x,
                output wire signed[36:0] denom,
                output wire signed[36:0] num_y,
                output wire signed[36:0] ox_signed,
                output wire signed[36:0] oy_signed,
                output[9:0] ox,
                output[8:0] oy,
                output ready);

    wire signed[10:0] sx;
    wire signed[9:0] sy;

    wire signed[36:0] p1_x;
    wire signed[35:0] p2_y;
    wire signed[35:0] p4_x;
    wire signed[34:0] p5_y;
    wire signed[25:0] p7_x;
    wire signed[24:0] p8_y;

    wire signed[14:0] scale_p7;
    wire signed[14:0] scale_p8;
    wire signed[26:0] scale_p9;
    wire signed[34:0] scale_p3;
    wire signed[33:0] scale_p6;

    //wire signed[36:0] num_x;
    //wire signed[36:0] num_y;
    //wire signed[36:0] denom;

    wire x_divider_start;
    wire y_divider_start;

    assign x_divider_start = clk;
    assign y_divider_start = clk;

    //wire signed[36:0] ox_signed;
    //wire signed[36:0] oy_signed;
    wire signed[36:0] ox_remainder;
    wire signed[36:0] oy_remainder;

    wire ox_ready;
    wire oy_ready;

    divider #(37) x_divider( .clk(clk), .sign(1'b1), .start(x_divider_start),
        .dividend(num_x), .divider(denom), .quotient(ox_signed), .remainder(ox_remainder), .ready(ox_ready));

    divider #(37) y_divider( .clk(clk), .sign(1'b1), .start(y_divider_start),
        .dividend(num_y), .divider(denom), .quotient(oy_signed), .remainder(oy_remainder), .ready(oy_ready));


    assign sx = {0'b0, x};
    assign sy = {0'b0, y};

    assign scale_p3 = (p3 <<< 7);
    assign scale_p6 = (p6 <<< 7);
    assign scale_p7 = (p7 >>> 3);
    assign scale_p8 = (p8 >>> 3);
    assign scale_p9 = (p9 <<< 7);

    assign p1_x = sx * p1;
    assign p2_y = sy * p2;
    assign p4_x = sx * p4;
    assign p5_y = sy * p5;
    assign p7_x = sx * scale_p7;
    assign p8_y = sy * scale_p8;

    assign num_x = p1_x + p2_y + scale_p3;
    assign num_y = p4_x + p5_y + scale_p6;
    assign denom = p7_x + p8_y + scale_p9;

    assign ox = $unsigned(ox_signed) <<< 3;
    assign oy = $unsigned(oy_signed) <<< 3;
    assign ready = (ox_ready && oy_ready);

endmodule
