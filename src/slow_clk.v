// this module generates a slow clock (e.g 1 hz signal)
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

