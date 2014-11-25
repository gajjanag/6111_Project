`default_nettype none

module audioManager(
  input wire clock,            // 27mhz system clock
  input wire reset,                // 1 to reset to initial state
  input wire writeSwitch,             // 1 for writeSwitch, 0 for record
  input wire ready,                // 1 when AC97 data is available
  input wire filter,               // 1 when using low-pass filter
  input wire [7:0] from_ac97_data, // 8-bit PCM data from mic
  output reg [7:0] to_ac97_data,    // 8-bit PCM data to headphone
  output wire [63:0] hexdisp, 
  output wire [15:0] flash_data,
  output wire [23:0] flash_address,
  output wire flash_ce_b,
  output wire flash_oe_b,
  output wire flash_we_b,
  output wire flash_reset_b,
  output wire flash_byte_b,
  input wire flash_sts,
  output wire busy,
  input wire startSwitch,
  input wire [3:0] otherSwitches
);
  
  wire [639:0] dots;
  reg writemode = 0;         //1=write mode; 0=read mode
  reg [15:0] wdata = 0;      //writeData
  reg dowrite = 0;           //1=new data, write it
  reg [22:0] raddr = 1;      //readAddress
  wire [15:0] frdata;        //readData
  reg doread = 0;            //1=execute read

  // UNUSED
  wire [11:0] fsmstate;
  // END UNUSED

  // FlashManager
  flash_manager fm(
    .clock(clock), 
    .reset(reset), 
    .dots(dots), 
    .writemode(writemode), 
    .wdata(wdata), 
    .dowrite(dowrite), 
    .raddr(raddr), 
    .frdata(frdata), 
    .doread(doread), 
    .busy(busy), 
    .flash_data(flash_data), 
    .flash_address(flash_address), 
    .flash_ce_b(flash_ce_b), 
    .flash_oe_b(flash_oe_b), 
    .flash_we_b(flash_we_b), 
    .flash_reset_b(flash_reset_b), 
    .flash_sts(flash_sts), 
    .flash_byte_b(flash_byte_b), 
    .fsmstate(fsmstate)
  );
  
  // frdata has no guaruntees when not in read mode
  assign hexdisp = {1'h0, fsmstate[11:9], 48'h0, frdata};

  always @ (posedge clock) begin
    if (startSwitch) begin
      // write arbitrary data to CF if writeSwitch is UP
      if (writeSwitch) begin
        writemode <= 1'b1;
        doread <= 1'b0;
        //if (~busy) begin
          wdata <= {12'h000, otherSwitches};
          dowrite <= 1'b1;
        //end
      end

      // if button is DOWN
      if (~writeSwitch) begin 
        // show on display
        dowrite <= 1'b0;
        writemode <= 1'b0;
        raddr <= 2;
        doread <= 1'b1;
      end // if (writeSwitch)
    end
    else begin
      // TO ENABLE RESET:
      // writemode <= 1
      // dowrite <= 0
      // doread <= 0 // to be safe

      // Reset First, Write Second, Read Later
      writemode <= 1'h1;
      doread <= 1'h0;
      dowrite <= 1'h0;
    end
  end // always @
endmodule
