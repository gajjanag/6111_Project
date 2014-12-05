///////////////////////////////////////////////////////////////////////////////////////////////////
// this module generates a VERY SLOW clk by a simple counter
// note: this method is NOT robust to timing issues, and for slowing
// down/speeding up a clk by a reasonable multiple (e.g 2, 3), use DCM instead
// to guarantee phase locking, elimination of most skew, etc
// Here, the intent is only to generate a pulse with a time period of order of
// seconds
///////////////////////////////////////////////////////////////////////////////////////////////////
module slow_clk(input clk, output slow_clk);
    parameter TICKS = 27'd49_999_999;

    reg [31:0] count = 0;
    reg sig_reg = 0;

    always @(posedge clk) begin
        if (count == TICKS) begin
            // flip at half period
            sig_reg <= ~sig_reg;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end
    assign slow_clk = sig_reg;
endmodule
