////////////////////////////////////////////////////////////////////////////////
// pixels_lost: Calculates the percentage of pixels lost, given the
// coordinates of the four points of the quadrilateral
// the output is synchronized to clk
////////////////////////////////////////////////////////////////////////////////

module pixels_lost(input clk,
                input[9:0] x1,
                input[8:0] y1,
                input[9:0] x2,
                input[8:0] y2,
                input[9:0] x3,
                input[8:0] y3,
                input[9:0] x4,
                input[8:0] y4,
                output reg[6:0] percent_lost); // percent_lost ranges from 0 to 100, a 7 bit number

wire signed[10:0] sx1, sx2, sx3, sx4;
wire signed[9:0] sy1, sy2, sy3, sy4;
wire signed[10:0] d_x1_x3, d_x2_x4;
wire signed[9:0] d_y1_y3, d_y2_y4;
wire signed[20:0] prod0, prod1;
wire signed[20:0] prod;
wire signed[20:0] abs_prod;
wire[20:0] unsigned_prod;
wire[13:0] shift_prod_7;
wire[11:0] shift_prod_9;
wire[9:0] shift_prod_11;
wire[14:0] sum_shift_prod;
wire[8:0] percent_kept;
wire[6:0] percent_lost_wire;

// sign extensions
assign sx1 = {1'b0, x1};
assign sx2 = {1'b0, x2};
assign sx3 = {1'b0, x3};
assign sx4 = {1'b0, x4};
assign sy1 = {1'b0, y1};
assign sy2 = {1'b0, y2};
assign sy3 = {1'b0, y3};
assign sy4 = {1'b0, y4};

// difference terms
assign d_x1_x3 = sx1 - sx3;
assign d_x2_x4 = sx2 - sx4;
assign d_y1_y3 = sy1 - sy3;
assign d_y2_y4 = sy2 - sy4;

// multipliers
assign prod0 = d_x1_x3 * d_y2_y4;
assign prod1 = d_y1_y3 * d_x2_x4;

// final area calculation
assign prod = prod0 - prod1; // this is twice the area

// but first, we need to take its absolute value
assign abs_prod = (prod < 0) ? -prod : prod;
assign unsigned_prod = abs_prod;

// to compute the percentage of pixels covered, here is the calculation
// we want (100*A)/(640*480), or A/(64*48)
// what we have is temp=2*A
// thus, we need temp/(128*48) = temp/(6144) = temp/(2^11 * 3) = (temp >> 11) / 3
// to avoid the division by 3, we approximate 3 ~= 21/64 (accurate to
// within 1%)
// thus, we want ((temp >> 11)*21) >> 6
// but mult by 21 is same as mult by (16 + 4 + 1)
// thus, our final calculation is ((temp >> 7) + (temp >> 9) + (temp >> 11))>>6
assign shift_prod_7 = unsigned_prod >> 7;
assign shift_prod_9 = unsigned_prod >> 9;
assign shift_prod_11 = unsigned_prod >> 11;
assign sum_shift_prod = shift_prod_7 + shift_prod_9 + shift_prod_11;
assign percent_kept = sum_shift_prod >> 6;
assign percent_lost_wire = 7'd100 - percent_kept;

// synchronous output
always @(posedge clk) begin
    percent_lost <= percent_lost_wire;
end

endmodule
