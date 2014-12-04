///////////////////////////////////////////////////////////////////////////////////////////////////
// this module generates a VERY SLOW clk by a simple counter
// note: this method is NOT robust to timing issues, and for slowing
// down/speeding up a clk by a reasonable multiple (e.g 2, 3), use DCM instead
// to guarantee phase locking, elimination of most skew, etc
// Here, the intent is only to generate a pulse with a time period of order of
// seconds
///////////////////////////////////////////////////////////////////////////////////////////////////
module slow_clk(input clk,
                output slow_clk);

reg[31:0] count = 0;
reg slow_clk_reg = 0;
parameter JIFFIES = 27'd100_000_000;
always @(posedge clk) begin
    count <= (count < JIFFIES) ? count + 1 : 0;
    if (count == 0) begin
        slow_clk_reg <= ~slow_clk_reg;
    end
end
assign slow_clk = slow_clk_reg;
endmodule

