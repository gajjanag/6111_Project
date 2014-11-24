////////////////////////////////////////////////////////////////////////////////
// move_cursor: This module implements a simple UI for manually adjusting the
// projector correction via pressing the arrow keys, and selecting which
// corner of the quadrilateral the user is manipulating via switch positions
// 00 -> point 1, 01 -> point 2, 10 -> point 3, 11 -> point 4
// all the adjustments can only happen when the override switch is pressed
// inputs are xi_raw, yi_raw (obtained from accelerometer lut)
// outputs are xi, yi
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

parameter OVERRIDE = 1'b0;

parameter XSPEED = 1'd1;
parameter YSPEED = 1'd1;

// 640 x 480 screen
parameter SCR_WIDTH = 10'd639;
parameter SCR_HEIGHT = 9'd479;

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

        // point (x1, y1)
        if ((!switch0) && (!switch1)) begin
            if (down) begin
                y1 <= (y1 <= SCR_HEIGHT-YSPEED) ? (y1 + YSPEED) : y1;
            end
            else if (up) begin
                y1 <= (y1 >= YSPEED) ? (y1 - YSPEED) : y1;
            end
            else if (left) begin
                x1 <= (x1 >= XSPEED) ? (x1 - XSPEED) : x1;
            end
            else if (right) begin
                x1 <= (x1 <= SCR_WIDTH-XSPEED) ? (x1 + XSPEED) : x1;
            end
        end

        // point (x2, y2)
        else if ((switch0) && (!switch1)) begin
            if (down) begin
                y2 <= (y2 <= SCR_HEIGHT-YSPEED) ? (y2 + YSPEED) : y2;
            end
            else if (up) begin
                y2 <= (y2 >= YSPEED) ? (y2 - YSPEED) : y2;
            end
            else if (left) begin
                x2 <= (x2 >= XSPEED) ? (x2 - XSPEED) : x2;
            end
            else if (right) begin
                x2 <= (x2 <= SCR_WIDTH-XSPEED) ? (x2 + XSPEED) : x2;
            end
        end

        // point (x3, y3)
        else if ((!switch0) && (switch1)) begin
            if (down) begin
                y3 <= (y3 <= SCR_HEIGHT-YSPEED) ? (y3 + YSPEED) : y3;
            end
            else if (up) begin
                y3 <= (y3 >= YSPEED) ? (y3 - YSPEED) : y3;
            end
            else if (left) begin
                x3 <= (x3 >= XSPEED) ? (x3 - XSPEED) : x3;
            end
            else if (right) begin
                x3 <= (x3 <= SCR_WIDTH-XSPEED) ? (x3 + XSPEED) : x3;
            end
        end

        // point (x4, y4)
        else if ((switch0) && (switch1)) begin
            if (down) begin
                y4 <= (y4 <= SCR_HEIGHT-YSPEED) ? (y4 + YSPEED) : y4;
            end
            else if (up) begin
                y4 <= (y4 >= YSPEED) ? (y4 - YSPEED) : y4;
            end
            else if (left) begin
                x4 <= (x4 >= XSPEED) ? (x4 - XSPEED) : x4;
            end
            else if (right) begin
                x4 <= (x4 <= SCR_WIDTH-XSPEED) ? (x4 + XSPEED) : x4;
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
        cur_state <= ~OVERRIDE;
    end
end

endmodule
