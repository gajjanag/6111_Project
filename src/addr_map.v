///////////////////////////////////////////////////////////////////////////////////////////////////
// a simple module for mapping hcount and vcount to address in bram
// the math:
// bram is 320*240 = 76800 lines, 320 columns, and 240 rows
// each line of bram corresponds to one pixel
// currently, each line is 12 bits (4 pixels r, 4 pixels g, 4 pixels b)
// hcount and vcount are in the 640x480 space
// Thus, the desired address is: 320*(vcount/2) + (hcount/2)
// = (128 + 32)vcount + hcount/2
///////////////////////////////////////////////////////////////////////////////////////////////////

module addr_map(input[9:0] hcount,
                input[9:0] vcount,
                output[16:0] addr);

assign addr = (vcount[9:1] << 8) + (vcount[9:1] << 6) + (hcount >> 1);
endmodule
