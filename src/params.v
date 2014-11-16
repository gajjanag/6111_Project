// clock frequencies
'define FPGA_CLK    26'd60_000_000
'define VGA_CLK     26'd25_175_000
'define NTSC_CLK    25'd12_587_500

// bitwidths of clks
'define LOG_FPGA_CLK    26
'define LOG_VGA_CLK     26
'define LOG_NTSC_CLK    25

// image sizes
'define NUM_PIXELS      19'd307_200
'define SCR_WIDTH       10'd640
'define SCR_HEIGHT      9'd480
'define SCR_LCM         11'd1920

// bitwdiths of image sizes
'define LOG_NUM_PIXELS  19
'define LOG_SCR_WIDTH   10
'define LOG_SCR_HEIGHT  9

// VGA (640x480) @ 60 Hz
'define VGA_HBLANKON    10'd639
'define VGA_HSYNCON     10'd655
'define VGA_HYSNCOFF    10'd751
'define VGA_HRESET      10'd799
'define VGA_VBLANKON    10'd479
'define VGA_VSYNCON     10'd490
'define VGA_VSYNCOFF    10'd492
'define VGA_VRESET      10'd523

// bidwidths of VGA params
'define LOG_HCOUNT 10
'define LOG_VCOUNT 10

