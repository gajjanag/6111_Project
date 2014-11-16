////////////////////////////////////////////////////////////////////////////////
// move_cursor: This module implements a simple UI for manually adjusting the
// projector correction
////////////////////////////////////////////////////////////////////////////////
module move_cursor(input clk,
                input up,
                input down,
                input left,
                input right,
                input override,
                input switch0,
                input switch1,
                input[9:0] x1_raw,
                input[8:0] y1_raw,
                input[9:0] x2_raw,
                input[8:0] y2_raw,
                input[9:0] x3_raw,
                input[8:0] y3_raw,
                input[9:0] x4_raw,
                input[8:0] y4_raw,
                output reg[9:0] x1,
                output reg[8:0] y1,
                output reg[9:0] x2,
                output reg[8:0] y2,
                output reg[9:0] x3,
                output reg[8:0] y3,
                output reg[9:0] x4,
                output reg[8:0] y4);

param OVERRIDE = 1'b0;
reg cur_state = ~OVERRIDE;

always @(posedge clk) begin
    if (override && !(cur_state == OVERRIDE)) begin
        cur_state <= OVERRIDE;
        x1 <= x1_raw;
        y1 <= y1_raw;
        x2 <= x2_raw;
        y2 <= y2_raw;
        x3 <= x3_raw;
        y3 <= y3_raw;
        x4 <= x4_raw;
        y4 <= y4_raw;
    end
    else if (override) begin
        if ((!switch0) && (!switch1)) begin
            if (down) begin
                y1 <= (y1 < 472) ? (y1 + 8) : y1;
            end
            else if (up) begin
                y1 <= (y1 > 8) ? (y1 - 8) : y1;
            end
            else if (left) begin
                x1 <= (x1 > 8) ? (x1 - 8) : x1;
            end
            else if (right) begin
                x1 <= (x1 < 632) ? (x1 + 8) : x1;
            end
        end
        else if ((switch0) && (!switch1)) begin
            if (down) begin
                y2 <= (y2 < 472) ? (y2 + 8) : y2;
            end
            else if (up) begin
                y2 <= (y2 > 8) ? (y2 - 8) : y2;
            end
            else if (left) begin
                x2 <= (x2 > 8) ? (x2 - 8) : x2;
            end
            else if (right) begin
                x2 <= (x2 < 632) ? (x2 + 8) : x2;
            end
        end
        else if ((!switch0) && (switch1)) begin
            if (down) begin
                y3 <= (y3 < 472) ? (y3 + 8) : y3;
            end
            else if (up) begin
                y3 <= (y3 > 8) ? (y3 - 8) : y3;
            end
            else if (left) begin
                x3 <= (x3 > 8) ? (x3 - 8) : x3;
            end
            else if (right) begin
                x3 <= (x3 < 632) ? (x3 + 8) : x3;
            end
        end
        else if ((switch0) && (switch1)) begin
            if (down) begin
                y4 <= (y4 < 472) ? (y4 + 8) : y4;
            end
            else if (up) begin
                y4 <= (y4 > 8) ? (y4 - 8) : y4;
            end
            else if (left) begin
                x4 <= (x4 > 8) ? (x4 - 8) : x4;
            end
            else if (right) begin
                x4 <= (x4 < 632) ? (x4 + 8) : x4;
            end
        end
    end
    else begin
        x1 <= x1_raw;
        y1 <= y1_raw;
        x2 <= x2_raw;
        y2 <= y2_raw;
        x3 <= x3_raw;
        y3 <= y3_raw;
        x4 <= x4_raw;
        y4 <= y4_raw;
    end
end

endmodule
