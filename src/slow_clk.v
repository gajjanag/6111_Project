// this module generates a slow clock (e.g 1 hz signal)
module slow_clk(input clk,
                output reg slow_clk);

reg[31:0] count = 0;
slow_clk = 0;
parameter JIFFIES = 27'd100_000_000;
always @(posedge clk) begin
    count <= (count < JIFFIES) ? count + 1 : 0;
    if (count == 0) begin
        slow_clk <= ~slow_clk;
    end
end
endmodule

