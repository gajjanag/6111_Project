///////////////////////////////////////////////////////////////////////////////
//
// 6.111 FPGA Labkit -- ZBT RAM clock generation
//
//
// Created: April 27, 2004
// Author: Nathan Ickes
//
///////////////////////////////////////////////////////////////////////////////
//
// This module generates deskewed clocks for driving the ZBT SRAMs and FPGA 
// registers. A special feedback trace on the labkit PCB (which is length 
// matched to the RAM traces) is used to adjust the RAM clock phase so that 
// rising clock edges reach the RAMs at exactly the same time as rising clock 
// edges reach the registers in the FPGA.
//
// The RAM clock signals are driven by DDR output buffers, which further 
// ensures that the clock-to-pad delay is the same for the RAM clocks as it is 
// for any other registered RAM signal.
//
// When the FPGA is configured, the DCMs are enabled before the chip-level I/O
// drivers are released from tristate. It is therefore necessary to
// artificially hold the DCMs in reset for a few cycles after configuration. 
// This is done using a 16-bit shift register. When the DCMs have locked, the 
// <lock> output of this mnodule will go high. Until the DCMs are locked, the 
// ouput clock timings are not guaranteed, so any logic driven by the 
// <fpga_clock> should probably be held inreset until <locked> is high.
//
///////////////////////////////////////////////////////////////////////////////

module ramclock(ref_clock, fpga_clock, fpga_clock_d2,
            fpga_clock_90, fpga_clock_270, 
            ram0_clock, ram1_clock, 
	        clock_feedback_in, clock_feedback_out, locked);
   
   input ref_clock;                 // Reference clock input
   output fpga_clock;               // Output clock to drive FPGA   logic
   output fpga_clock_d2;
   output fpga_clock_90;
   output fpga_clock_270;
   output ram0_clock, ram1_clock;   // Output clocks for each RAM chip
   input  clock_feedback_in;        // Output to feedback trace
   output clock_feedback_out;       // Input from feedback trace
   output locked;                   // Indicates that clock outputs are stable
   
   wire  ref_clk, fpga_clk, fpga_clk_d2, fpga_clk_90, fpga_clk_270,
   ram_clk, fb_clk, lock1, lock2, dcm_reset;

   ////////////////////////////////////////////////////////////////////////////
   
   //IBUFG ref_buf (.O(ref_clk), .I(ref_clock));
   assign ref_clk = ref_clock;
   
   BUFG int_buf (.O(fpga_clock), .I(fpga_clk));
   BUFG int_buf_d2 (.O(fpga_clock_d2), .I(fpga_clk_d2));
   BUFG int_buf_90 (.O(fpga_clock_90), .I(fpga_clk_90));
   BUFG int_buf_270 (.O(fpga_clock_270), .I(fpga_clk_90));

   DCM int_dcm (.CLKFB(fpga_clock),
		.CLKIN(ref_clk),
		.RST(dcm_reset),
		.CLK0(fpga_clk),
        .CLKDV(fpga_clk_d2),
        .CLK90(fpga_clk_90),
        .CLK180(fpga_clk_270),
		.LOCKED(lock1));
   // synthesis attribute DLL_FREQUENCY_MODE of int_dcm is "LOW"
   // synthesis attribute DUTY_CYCLE_CORRECTION of int_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of int_dcm is "FALSE"
   // synthesis attribute DFS_FREQUENCY_MODE of int_dcm is "LOW"
   // synthesis attribute CLK_FEEDBACK of int_dcm  is "1X"
   // synthesis attribute CLKOUT_PHASE_SHIFT of int_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of int_dcm is 0
   // synthesis attribute CLKDV_DIVIDE of int_dcm is 2
   
   BUFG ext_buf (.O(ram_clock), .I(ram_clk));
   
   IBUFG fb_buf (.O(fb_clk), .I(clock_feedback_in));
   
   DCM ext_dcm (.CLKFB(fb_clk), 
		    .CLKIN(ref_clk), 
		    .RST(dcm_reset),
		    .CLK0(ram_clk),
		    .LOCKED(lock2));
   // synthesis attribute DLL_FREQUENCY_MODE of ext_dcm is "LOW"
   // synthesis attribute DUTY_CYCLE_CORRECTION of ext_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of ext_dcm is "FALSE"
   // synthesis attribute DFS_FREQUENCY_MODE of ext_dcm is "LOW"
   // synthesis attribute CLK_FEEDBACK of ext_dcm  is "1X"
   // synthesis attribute CLKOUT_PHASE_SHIFT of ext_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of ext_dcm is 0

   SRL16 dcm_rst_sr (.D(1'b0), .CLK(ref_clk), .Q(dcm_reset),
		     .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
   // synthesis attribute init of dcm_rst_sr is "000F";
   

   OFDDRRSE ddr_reg0 (.Q(ram0_clock), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));
   OFDDRRSE ddr_reg1 (.Q(ram1_clock), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));
   OFDDRRSE ddr_reg2 (.Q(clock_feedback_out), .C0(ram_clock), .C1(~ram_clock),
		      .CE (1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));

   assign locked = lock1 && lock2;
   
endmodule
