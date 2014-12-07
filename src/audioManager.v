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

  // DEBUG
  output reg skipAddrOn = 0
);
  
  // Playback addresses:
  parameter TRACK_LENGTH = 48000; // approx 1 sec
  // numbers

  parameter ONE_INDEX = 0;
  parameter TWO_INDEX = 1;
  parameter THREE_INDEX = 2;
  parameter FOUR_INDEX = 3;
  parameter FIVE_INDEX = 4;
  parameter SIX_INDEX = 5;
  parameter SEVEN_INDEX = 6;
  parameter EIGHT_INDEX = 7;
  parameter NINE_INDEX = 8;
  parameter TEN_INDEX = 9;
  parameter ELEVEN_INDEX = 10;
  parameter TWELVE_INDEX = 11;
  parameter THIRTEEN_INDEX = 12;
  parameter FOURTEEN_INDEX = 13;
  parameter FIFTEEN_INDEX = 14;
  parameter TWENTY_INDEX = 15;
  parameter THIRTY_INDEX = 16;
  parameter FOURTY_INDEX = 17;
  parameter FIFTY_INDEX = 18;
  parameter FIFTY_INDEX = 19;
  parameter SIXTY_INDEX = 20;
  parameter SIXTY_INDEX = 21;
  parameter SEVENTY_INDEX = 22;
  parameter EIGHTY_INDEX = 23;
  parameter NINETY_INDEX = 24;
  parameter HUNDRED_INDEX = 25;
  parameter TEEN_INDEX = 26;
  parameter PERCENT_INDEX = 27;
  parameter USED_INDEX = 28;
  parameter HELP_AUDIO_INDEX = 29;
  parameter SKIP_ADDR = 30;
  parameter UNUSED_ADDR = 31;

  //  raddr <= cur_index * TRACK_LENGTH

  parameter ONE_ADDR = 1'b1;
  parameter TWO_ADDR = ONE_ADDR + TRACK_LENGTH;
  parameter THREE_ADDR = TWO_ADDR + TRACK_LENGTH;
  parameter FOUR_ADDR = THREE_ADDR + TRACK_LENGTH;
  parameter FIVE_ADDR = FOUR_ADDR + TRACK_LENGTH;
  parameter SIX_ADDR = FIVE_ADDR + TRACK_LENGTH;
  parameter SEVEN_ADDR = SIX_ADDR + TRACK_LENGTH;
  parameter EIGHT_ADDR = SEVEN_ADDR + TRACK_LENGTH;
  parameter NINE_ADDR = EIGHT_ADDR + TRACK_LENGTH;
  parameter TEN_ADDR = NINE_ADDR + TRACK_LENGTH;
  parameter ELEVEN_ADDR = TEN_ADDR + TRACK_LENGTH;
  parameter TWELVE_ADDR = ELEVEN_ADDR + TRACK_LENGTH;
  parameter THIRTEEN_ADDR = TWELVE_ADDR + TRACK_LENGTH;
  parameter FOURTEEN_ADDR = THIRTEEN_ADDR + TRACK_LENGTH;
  parameter FIFTEEN_ADDR = FOURTEEN_ADDR + TRACK_LENGTH;
  parameter TWENTY_ADDR = FIFTEEN_ADDR + TRACK_LENGTH;
  parameter THIRTY_ADDR = TWENTY_ADDR + TRACK_LENGTH;
  parameter FOURTY_ADDR = THIRTY_ADDR + TRACK_LENGTH;
  parameter FIFTY_ADDR = FOURTY_ADDR + TRACK_LENGTH;
  parameter SIXTY_ADDR = FIFTY_ADDR + TRACK_LENGTH;
  parameter SEVENTY_ADDR = SIXTY_ADDR + TRACK_LENGTH;
  parameter EIGHTY_ADDR = SEVENTY_ADDR + TRACK_LENGTH;
  parameter NINETY_ADDR = EIGHTY_ADDR + TRACK_LENGTH;
  parameter HUNDRED_ADDR = NINETY_ADDR + TRACK_LENGTH;
  // other speech
  parameter TEEN_ADDR = HUNDRED_ADDR + TRACK_LENGTH;
  parameter PERCENT_ADDR = TEEN_ADDR + TRACK_LENGTH;
  parameter USED_ADDR = PERCENT_ADDR + TRACK_LENGTH;
  parameter HELP_AUDIO_ADDR = USED_ADDR + TRACK_LENGTH;
  // Not a used track:
  parameter UNUSED_ADDR = 23'hFFFFFF; // Signals end of playback
  parameter SKIP_ADDR = 23'hFFFFFE; // Signals track to be skipped

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

  wire [3:0] hundreds;
  wire [3:0] tens;
  wire [3:0] ones;

  BCD inputToBCD(
    .number({3'b000, audioSelector}),
    .hundreds(hundreds),
    .tens(tens),
    .ones(ones)
  );

  reg [15:0] bytesRxed = 0;

  // frdata has no guaruntees when not in read mode
  assign hexdisp = {bytesRxed[15:0], 9'h0, raddr[22:0], frdata};

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

  // REMOVE 
  wire [19:0] tone;
  tone750hz xxx(.clock(clock),.ready(slowClockPulse),.pcm_data(tone));
  reg [5:0] index;

  // Set of 4 addresses that represent a playback sequence
  // First track in bottom 23 bits[22:0]. Last track in top bits [91:68].
  // 23'hFFFFFF means track not used.
  reg [91:0] playbackSeq = 2;
  reg [22:0] trackEndAddr = 0;
  reg playing = 0;
  reg lastPlaying = 0;
  
  reg [7:0] dataFromFifo;
  always @ (posedge rd) begin
    dataFromFifo <= out; // out & data have same results
  end

  always @ (posedge clock) begin
    lastButtonup <= buttonup;
    lastButtondown <= buttondown;
    lastAudioTrigger <= audioTrigger;
    lastReady <= ready;
    lastSlowClock <= slowClock;
    lastPlaying <= playing;

    if (startSwitch) begin
      // write USB RX data if switch is up
      if (writeSwitch) begin
        writemode <= 1'b1;
        doread <= 1'b0;
        //dowrite <= 1'b0; // only write on new data // WATCH OUT!!
        if (newout) begin
          bytesRxed <= bytesRxed + 1;
          wdata <= {dataFromFifo, 8'b0};//{out, 8'b0};
          dowrite <= 1'b1;
        end

        if (1'h0) begin//audioSelector[2]) begin // tone750Hz to flash
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

        if (playing & audioTrigger & ready) begin // REMOVE audioTrigger
          if (raddr < trackEndAddr) begin
            // Normal 48K Playback
            raddr <= raddr + 1;
            to_ac97_data <= frdata[15:8]; // PUT BACK
            // Repeat at addr 63 for tone750Hz
            // if(audioSelector[3] & raddr == 63) begin
            //   raddr <= 0;
            // end
          end
          else begin 
            if (playbackSeq[45:23] < UNUSED_ADDR) begin
              // change raddr to next track
              raddr <= playbackSeq[45:23];
              // shift playbackSeq down
              playbackSeq <= {UNUSED_ADDR, playbackSeq[91:23]};
              // update trackEndAddr
              trackEndAddr <= playbackSeq[45:23] + TRACK_LENGTH;
            end
            else if (playbackSeq[45:23] == UNUSED_ADDR) begin
              playing <= 0;
              raddr <= 0; // reset for safety - lower than UNUSED_ADDR
            end
          end
        end // if (playing & audioTrigger & ready)

        // if entering this state, assign start address
        if (audioTrigger & ~lastAudioTrigger) begin
          playing <= 1;
          // For testing, play 12K addresses (2 sec) for each trigger
          // case(audioSelector[4:0])
          //   0: begin playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, ONE_ADDR}; raddr <= 1; end
          //   1: raddr <= 20001;
          //   2: raddr <= 24001;
          //   3: raddr <= 36001;
          //   default: raddr <= 1;
          // endcase
          case(ones)
            0: playbackSeq[91:23] <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR};
            1: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, ONE_ADDR};
            2: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, TWO_ADDR};
            3: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, THREE_ADDR};
            4: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, FOUR_ADDR};
            5: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, FIVE_ADDR};
            6: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, SIX_ADDR};
            7: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, SEVEN_ADDR};
            8: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, EIGHT_ADDR};
            9: playbackSeq[91:23] <= {USED_ADDR, PERCENT_ADDR, NINE_ADDR};
            default:  playbackSeq <= {USED_ADDR, PERCENT_ADDR, UNUSED_ADDR}; // error
          endcase
          case (tens)
            0: playbackSeq[22:0] <= SKIP_ADDR;
            1: playbackSeq[22:0] <= TEN_ADDR;
            2: playbackSeq[22:0] <= TWENTY_ADDR;
            3: playbackSeq[22:0] <= THIRTY_ADDR;
            4: playbackSeq[22:0] <= FOURTY_ADDR;
            5: playbackSeq[22:0] <= FIFTY_ADDR;
            6: playbackSeq[22:0] <= SIXTY_ADDR;
            7: playbackSeq[22:0] <= SEVENTY_ADDR;
            8: playbackSeq[22:0] <= EIGHTY_ADDR;
            9: playbackSeq[22:0] <= NINETY_ADDR;
            default: playbackSeq[22:0] <= UNUSED_ADDR;
          endcase
          case (hundreds)
            0: begin end
            1: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, HUNDRED_ADDR}; // error
          endcase
          case (audioSelector)
            11: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, ELEVEN_ADDR};
            12: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, TWELVE_ADDR};
            13: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, THIRTEEN_ADDR};
            14: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, FOURTEEN_ADDR};
            15: playbackSeq <= {UNUSED_ADDR, USED_ADDR, PERCENT_ADDR, FIFTEEN_ADDR};
            16: playbackSeq <= {USED_ADDR, PERCENT_ADDR, TEEN_ADDR, SIX_ADDR};
            17: playbackSeq <= {USED_ADDR, PERCENT_ADDR, TEEN_ADDR, SEVEN_ADDR};
            18: playbackSeq <= {USED_ADDR, PERCENT_ADDR, TEEN_ADDR, EIGHT_ADDR};
            19: playbackSeq <= {USED_ADDR, PERCENT_ADDR, TEEN_ADDR, NINE_ADDR};
            default: begin end
          endcase
        end // if (audioTrigger & ~lastAudioTrigger) 

        // just started playing - need to set raddr
        // Assuming this happens once playbackSeq has been properly set
        if (playing & ~lastPlaying) begin
          if (playbackSeq[22:0] == SKIP_ADDR) begin
            skipAddrOn <= 1;
            playbackSeq <= {UNUSED_ADDR, playbackSeq[91:23]};
            raddr <= playbackSeq[45:23];
            trackEndAddr <= playbackSeq[45:23] + TRACK_LENGTH;
          end
          else begin
            raddr <= playbackSeq[22:0];
            trackEndAddr <= playbackSeq[22:0] + TRACK_LENGTH;
          end
        end
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
