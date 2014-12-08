// FROM: http://www.deathbylogic.com/2013/12/binary-to-binary-coded-decimal-bcd-converter/
// Converts an 8-bit binary number into a decimal number.
module BCD(
   input wire [7:0] number,
   output reg [3:0] hundreds,
   output reg [3:0] tens,
   output reg [3:0] ones);
   
   always @ (number) begin  
      case(number)
         0: begin ones <= 0; tens <= 0; end
         1: begin ones <= 1; tens <= 0; end
         2: begin ones <= 2; tens <= 0; end
         3: begin ones <= 3; tens <= 0; end
         4: begin ones <= 4; tens <= 0; end
         5: begin ones <= 5; tens <= 0; end
         6: begin ones <= 6; tens <= 0; end
         7: begin ones <= 7; tens <= 0; end
         8: begin ones <= 8; tens <= 0; end
         9: begin ones <= 9; tens <= 0; end
         10: begin ones <= 0; tens <= 1; end
         11: begin ones <= 1; tens <= 1; end
         12: begin ones <= 2; tens <= 1; end
         13: begin ones <= 3; tens <= 1; end
         14: begin ones <= 4; tens <= 1; end
         15: begin ones <= 5; tens <= 1; end
         16: begin ones <= 6; tens <= 1; end
         17: begin ones <= 7; tens <= 1; end
         18: begin ones <= 8; tens <= 1; end
         19: begin ones <= 9; tens <= 1; end
         20: begin ones <= 0; tens <= 2; end
         21: begin ones <= 1; tens <= 2; end
         22: begin ones <= 2; tens <= 2; end
         23: begin ones <= 3; tens <= 2; end
         24: begin ones <= 4; tens <= 2; end
         25: begin ones <= 5; tens <= 2; end
         26: begin ones <= 6; tens <= 2; end
         27: begin ones <= 7; tens <= 2; end
         28: begin ones <= 8; tens <= 2; end
         29: begin ones <= 9; tens <= 2; end
         30: begin ones <= 0; tens <= 3; end
         31: begin ones <= 1; tens <= 3; end
         32: begin ones <= 2; tens <= 3; end
         33: begin ones <= 3; tens <= 3; end
         34: begin ones <= 4; tens <= 3; end
         35: begin ones <= 5; tens <= 3; end
         36: begin ones <= 6; tens <= 3; end
         37: begin ones <= 7; tens <= 3; end
         38: begin ones <= 8; tens <= 3; end
         39: begin ones <= 9; tens <= 3; end
         40: begin ones <= 0; tens <= 4; end
         41: begin ones <= 1; tens <= 4; end
         42: begin ones <= 2; tens <= 4; end
         43: begin ones <= 3; tens <= 4; end
         44: begin ones <= 4; tens <= 4; end
         45: begin ones <= 5; tens <= 4; end
         46: begin ones <= 6; tens <= 4; end
         47: begin ones <= 7; tens <= 4; end
         48: begin ones <= 8; tens <= 4; end
         49: begin ones <= 9; tens <= 4; end
         50: begin ones <= 0; tens <= 5; end
         51: begin ones <= 1; tens <= 5; end
         52: begin ones <= 2; tens <= 5; end
         53: begin ones <= 3; tens <= 5; end
         54: begin ones <= 4; tens <= 5; end
         55: begin ones <= 5; tens <= 5; end
         56: begin ones <= 6; tens <= 5; end
         57: begin ones <= 7; tens <= 5; end
         58: begin ones <= 8; tens <= 5; end
         59: begin ones <= 9; tens <= 5; end
         60: begin ones <= 0; tens <= 6; end
         61: begin ones <= 1; tens <= 6; end
         62: begin ones <= 2; tens <= 6; end
         63: begin ones <= 3; tens <= 6; end
         64: begin ones <= 4; tens <= 6; end
         65: begin ones <= 5; tens <= 6; end
         66: begin ones <= 6; tens <= 6; end
         67: begin ones <= 7; tens <= 6; end
         68: begin ones <= 8; tens <= 6; end
         69: begin ones <= 9; tens <= 6; end
         70: begin ones <= 0; tens <= 7; end
         71: begin ones <= 1; tens <= 7; end
         72: begin ones <= 2; tens <= 7; end
         73: begin ones <= 3; tens <= 7; end
         74: begin ones <= 4; tens <= 7; end
         75: begin ones <= 5; tens <= 7; end
         76: begin ones <= 6; tens <= 7; end
         77: begin ones <= 7; tens <= 7; end
         78: begin ones <= 8; tens <= 7; end
         79: begin ones <= 9; tens <= 7; end
         80: begin ones <= 0; tens <= 8; end
         81: begin ones <= 1; tens <= 8; end
         82: begin ones <= 2; tens <= 8; end
         83: begin ones <= 3; tens <= 8; end
         84: begin ones <= 4; tens <= 8; end
         85: begin ones <= 5; tens <= 8; end
         86: begin ones <= 6; tens <= 8; end
         87: begin ones <= 7; tens <= 8; end
         88: begin ones <= 8; tens <= 8; end
         89: begin ones <= 9; tens <= 8; end
         90: begin ones <= 0; tens <= 9; end
         91: begin ones <= 1; tens <= 9; end
         92: begin ones <= 2; tens <= 9; end
         93: begin ones <= 3; tens <= 9; end
         94: begin ones <= 4; tens <= 9; end
         95: begin ones <= 5; tens <= 9; end
         96: begin ones <= 6; tens <= 9; end
         97: begin ones <= 7; tens <= 9; end
         98: begin ones <= 8; tens <= 9; end
         99: begin ones <= 9; tens <= 9; end
         default: begin ones <= 0; tens <= 0; end
      endcase
      hundreds <= 0;
   end
endmodule

// module BCDTest;
//    reg [7:0] number;
//    reg [3:0] hundreds;
//    reg [3:0] tens;
//    reg [3:0] ones;

//    BCD BCD(number, hundreds, tens, ones);

//    initial begin
//       number = 8'd89;
//       #10
//       number = 8'd99;
//       #10
//       $display("%d, %d, %d, %d", number, hundreds, tens, ones);
//    end

   
//    // always @ (*) begin 
      
//    // end
// endmodule