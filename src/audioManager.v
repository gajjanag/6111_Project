`default_nettype none

module audioManager(
  input wire clock,            // 27mhz system clock
  input wire reset,                // 1 to reset to initial state

  // User I/O
  input wire startSwitch,
  input wire [4:0] audioSelector, 
  input wire writeSwitch,             // 1=Write, 0=Read
  output wire [63:0] hexdisp,
  input wire buttonup,
  input wire buttondown,
  input wire audioTrigger, // 1=Begin Playback as determined by audioSelector
  
  // AC97 I/O
  input wire ready,                // 1 when AC97 data is available
  input wire [7:0] from_ac97_data, // 8-bit PCM data from mic
  output reg [7:0] to_ac97_data,    // 8-bit PCM data to headphone // PUT BACK: REG

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
  output wire rd, // the rd pin from the USB fifo (OUTPUT)
  output wire newout,
  output reg flashError = 0
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
  //wire newout;  // newout=1 out contains new data (OUTPUT)
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

  reg [15:0] bytesRxed = 0;

  // frdata has no guaruntees when not in read mode
  assign hexdisp = {bytesRxed[15:0], raddr[15:0], 12'h0, 1'h0, fsmstate[11:9], frdata};

  reg lastButtonup;
  reg lastButtondown;
  reg lastAudioTrigger;
  reg [2:0] third = 0;
  reg lastReady;

  // REMOVE
  wire slowClock;
  reg lastSlowClock;
  wire slowClockPulse;
  assign slowClockPulse = slowClock & ~lastSlowClock;
  Square #(.Hz(3000)) freq2 (
    .clock(clock),
    .reset(reset),
    .square(slowClock)
  );

  reg [7:0] mem_out_zeroed;
  wire signed [17:0] reconst_mem_out;
  fir31 reconst (
    .clock(clock),
    .reset(reset),
    .ready(ready),
    .x(mem_out_zeroed),
    .y(reconst_mem_out)
  );

  // REMOVE 
  wire [19:0] tone;
  tone750hz xxx(.clock(clock),.ready(slowClockPulse),.pcm_data(tone));
  reg [5:0] index;
  
  reg [7:0] dataFromFifo;
  always @ (posedge rd) begin
    dataFromFifo <= out; // out & data have same results
  end
  // reg [7:0] cachedDataFromFifo;
  reg cached = 0;

  always @ (posedge clock) begin
    lastButtonup <= buttonup;
    lastButtondown <= buttondown;
    lastAudioTrigger <= audioTrigger;
    lastReady <= ready;
    lastSlowClock <= slowClock;

    if (startSwitch) begin
      // write USB RX data if switch is up
      if (writeSwitch) begin
        writemode <= 1'b1;
        doread <= 1'b0;
        //dowrite <= 1'b0; // only write on new data // WATCH OUT!!
        if (newout || cached) begin
          // if (~busy) begin
            bytesRxed <= bytesRxed + 1;
            wdata <= {dataFromFifo, 8'b0};//{out, 8'b0};
            dowrite <= 1'b1;
            // cached <= 0;
          // end
          // else begin
          //   flashError <= 1;
          //   cached <= 1;
          //   // cachedDataFromFifo <= 
          // end
        end

        if (audioSelector[2]) begin // tone750Hz to flash
          if (slowClockPulse) begin // WAS: READY
            if (index <= 6'h3F) begin
              wdata <= {tone[19:12], 8'b0};
              dowrite <= 1'b1;
              index <= index + 1;
            end
          end
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
          
          // FILTERING ATTEMPT
          if (audioSelector[4]) begin 
            // Our audio plays back 50% too fast (approx) so we need 1 zero per 2 real samples
            third <= third + 1;
            // if (third == 2) begin // on every third ac97 sample (48/8 = 6kHz file sample)
            //   // add a zero
            //   mem_out_zeroed <= 0;
            //   third <= 0;
            // end
            // else begin
              mem_out_zeroed <= frdata[15:8];
              raddr <= raddr + 1;
            // end
            to_ac97_data <= reconst_mem_out[14:7];
          end // if (audioSelector[4])
          // END FILTERING ATTEMPT

          // Normal 48K Playback
          else begin 
            // 48K sample rate
            raddr <= raddr + 1;
            to_ac97_data <= frdata[15:8]; // PUT BACK
            if(audioSelector[3] & raddr == 63) begin
              raddr <= 0;
            end
          end
        end // if (audioTrigger)

        // if entering this state, assign start address
        if (audioTrigger & ~lastAudioTrigger) begin
          // For testing, play 12K addresses (2 sec) for each trigger
          case(audioSelector[1:0])
            0: raddr <= 1;
            1: raddr <= 20001;
            2: raddr <= 24001;
            3: raddr <= 36001;
            default: raddr <= 1;
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

// REMOVE
module recorder(
  input wire clock,            // 27mhz system clock
  input wire reset,                // 1 to reset to initial state
  input wire playback,             // 1 for playback, 0 for record
  input wire ready,                // 1 when AC97 data is available
  input wire [7:0] from_ac97_data, // 8-bit PCM data from mic
  output reg [7:0] to_ac97_data    // 8-bit PCM data to headphone
);  
   // test: playback 750hz tone, or loopback using incoming data
   wire [19:0] tone;
   tone750hz xxx(.clock(clock),.ready(ready),.pcm_data(tone));

   always @ (posedge clock) begin
      if (ready) begin
       // get here when we've just received new data from the AC97
       //to_ac97_data <= playback ? tone[19:12] : from_ac97_data; // RESTORE FOR 750Hz
      end
   end
endmodule