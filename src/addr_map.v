// a module for mapping hcount and vcount to address in bram

module addr_map(input[9:0] hcount,
                input[9:0] vcount,
                output[16:0] addr);

assign addr = (vcount << 7) + (vcount << 5) + (hcount >> 1);
endmodule
