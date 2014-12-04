module pixel_map(input clk,
                input reg[11:0] pixel_data,
                output reg[16:0] ntsc_out_addr,
                output reg[16:0] vga_in_addr);

reg[9:0] cur_x;
reg[9:0] cur_y;
reg[
assign cur_x = 0;
assign cur_y = 0;
parameter NEXT_PIXEL_ST = 2'b00;
reg[1:0] cur_state;
always @(posedge clk) begin
    case (cur_state)
        NEXT_PIXEL_ST: begin
            cur_x <= (cur_x < 639) ? cur_x + 1 : 0;
            if ((cur_x == 639) && (cur_y == 479)) begin
                cur_y <= 0;
            end
            else if (cur_x == 639) begin
                cur_y <= cur_y + 1;
            end

    endcase

end
endmodule

