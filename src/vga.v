////////////////////////////////////////////////////////////////////////////////
// vga: Generate XVGA display signals (640 x 480 @ 60Hz)
// Credits: module heavily draws from Jose's project (Fall 2011),
// also staff xvga module
////////////////////////////////////////////////////////////////////////////////

module vga(input vclock,
            output reg ['LOG_HCOUNT:0] hcount,    // pixel number on current line
            output reg ['LOG_VCOUNT:0] vcount,	 // line number
            output reg vsync,hsync,blank);

   // horizontal: 800 pixels total
   // display 640 pixels per line
   reg hblank,vblank;
   wire hsyncon,hsyncoff,hreset,hblankon;
   assign hblankon = (hcount == 'VGA_HBLANKON);
   assign hsyncon = (hcount == 'VGA_HSYNCON);
   assign hsyncoff = (hcount == 'VGA_HYSNCOFF);
   assign hreset = (hcount == 'VGA_HRESET);

   // vertical: 524 lines total
   // display 480 lines
   wire vsyncon,vsyncoff,vreset,vblankon;
   assign vblankon = hreset & (vcount == 'VGA_VBLANKON);
   assign vsyncon = hreset & (vcount == 'VGA_VSYNCON);
   assign vsyncoff = hreset & (vcount == 'VGA_VSYNCOFF);
   assign vreset = hreset & (vcount == 'VGA_VRESET);

   // sync and blanking
   wire next_hblank,next_vblank;
   assign next_hblank = hreset ? 0 : hblankon ? 1 : hblank;
   assign next_vblank = vreset ? 0 : vblankon ? 1 : vblank;
   always @(posedge vclock) begin
      hcount <= hreset ? 0 : hcount + 1;
      hblank <= next_hblank;
      hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync;  // active low

      vcount <= hreset ? (vreset ? 0 : vcount + 1) : vcount;
      vblank <= next_vblank;
      vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;  // active low

      blank <= next_vblank | (next_hblank & ~hreset);
   end
endmodule
