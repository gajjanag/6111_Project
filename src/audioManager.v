`default_nettype none

module audioManager(
  input wire clock,            // 27mhz system clock
  input wire reset,                // 1 to reset to initial state

  // User I/O
  input wire startSwitch,
  input wire [3:0] audioSelector, 
  input wire writeSwitch,             // 1=Write, 0=Read
  output wire [63:0] hexdisp,
  input wire buttonup,
  input wire buttondown,
  input wire audioTrigger, // 1=Begin Playback as determined by audioSelector
  
  // AC97 I/O
  input wire ready,                // 1 when AC97 data is available
  input wire [7:0] from_ac97_data, // 8-bit PCM data from mic
  output reg [7:0] to_ac97_data,    // 8-bit PCM data to headphone

  // Flash I/O
  output wire [15:0] flash_data,
  output wire [23:0] flash_address,
  output wire flash_ce_b,
  output wire flash_oe_b,
  output wire flash_we_b,
  output wire flash_reset_b,
  output wire flash_byte_b,
  input wire flash_sts,
  output wire busy,

  // USB I/O
  input wire [7:0] data, //the data pins from the USB fifo
  input wire rxf, //the rxf pin from the USB fifo
  output wire rd // the rd pin from the USB fifo (OUTPUT)
);
  
  reg writemode = 0;         //1=write mode; 0=read mode
  reg [15:0] wdata = 0;      //writeData
  reg dowrite = 0;           //1=new data, write it
  reg [22:0] raddr = 2;      //readAddress
  wire [15:0] frdata;        //readData
  reg doread = 0;            //1=execute read

  // UNUSED
  wire [11:0] fsmstate;
  // END UNUSED

  // FlashManager
  flash_manager fm(
    .clock(clock), 
    .reset(reset), 

    // Interface I/O
    .writemode(writemode), 
    .wdata(wdata), 
    .dowrite(dowrite), 
    .raddr(raddr), 
    .frdata(frdata), 
    .doread(doread), 
    .busy(busy), 

    // Flash I/O
    .flash_data(flash_data), 
    .flash_address(flash_address), 
    .flash_ce_b(flash_ce_b), 
    .flash_oe_b(flash_oe_b), 
    .flash_we_b(flash_we_b), 
    .flash_reset_b(flash_reset_b), 
    .flash_sts(flash_sts), 
    .flash_byte_b(flash_byte_b), 

    // Debug
    .fsmstate(fsmstate)
  );

  //wire rd;        
  wire [7:0] out; // data from FIFO (OUTPUT)
  wire newout;  // newout=1 out contains new data (OUTPUT)
  wire hold;     //hold=1 the module will not accept new data from the FIFO
  wire [3:0] state; //for debugging purposes

  assign hold = 1'b0; 

  usb_input usbtest(
    .clk(clock),
    .reset(reset),

    // USB FTDI I/O
    .data(data[7:0]),
    .rxf(rxf),
    .rd(rd),

    // Interface
    .out(out[7:0]),
    .newout(newout),
    .hold(hold),

    // Debug
    .state(state)
  );

  // frdata has no guaruntees when not in read mode
  assign hexdisp = {out, 8'h0, raddr[15:0], 12'h0, 1'h0, fsmstate[11:9], frdata};

  reg lastButtonup;
  reg lastButtondown;
  reg lastAudioTrigger;
  reg [2:0] eighth = 0;

  always @ (posedge clock) begin
    lastButtonup <= buttonup;
    lastButtondown <= buttondown;
    lastAudioTrigger <= audioTrigger;

    if (startSwitch) begin
      // write USB RX data if switch is up
      if (writeSwitch) begin
        writemode <= 1'b1;
        doread <= 1'b0;
        dowrite <= 1'b0; // only write on new data // WATCH OUT!!
        if (newout) begin
          wdata <= {out, 8'b0};
          dowrite <= 1'b1;
        end
      end

      // if button is DOWN - scroll through addresses via buttons
      if (~writeSwitch) begin 
        dowrite <= 1'b0;
        writemode <= 1'b0;
        doread <= 1'b1;
        
        // scroll through addresses with buttons
        if(buttonup & ~lastButtonup) begin
          raddr <= raddr + 1;
        end
        else if (buttondown & ~lastButtondown) begin
          raddr <= raddr - 1;
        end

        if (audioTrigger & ready) begin  
          eighth <= eighth + 1;

          if (eighth == 7) begin // on every eighth ac97 sample (48/8 = 6kHz file sample)
            raddr <= raddr + 1;
            to_ac97_data <= frdata[15:8];
            // eighth <= 0;
          end
        end // if (audioTrigger)

        // if entering this state, assign start address
        if (audioTrigger & ~lastAudioTrigger) begin
          // For testing, play 12K addresses (2 sec) for each trigger
          case(audioSelector)
            0: raddr <= 1;
            1: raddr <= 20001;
            2: raddr <= 24001;
            3: raddr <= 36001;
            default: raddr <= 48001;
          endcase
        end // if (audioTrigger & ~lastAudioTrigger) 

      end // if (~writeSwitch)
    end // if (startSwitch)
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
