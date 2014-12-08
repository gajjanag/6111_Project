`default_nettype none

module audioManager(
  input wire clock,            // 27mhz system clock
  input wire reset,                // 1 to reset to initial state

  // User I/O
  input wire startSwitch,
  input wire [6:0] audioSelector, 
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
  parameter TRACK_LENGTH = 69000; // approx 1 sec
  // numbers
  //25% longer 
  //

  parameter ONE_INDEX = 23'd0;
  parameter TWO_INDEX = 23'd1;
  parameter THREE_INDEX = 23'd2;
  parameter FOUR_INDEX = 23'd3;
  parameter FIVE_INDEX = 23'd4;
  parameter SIX_INDEX = 23'd5;
  parameter SEVEN_INDEX = 23'd6;
  parameter EIGHT_INDEX = 23'd7;
  parameter NINE_INDEX = 23'd8;
  parameter TEN_INDEX = 23'd9;
  parameter ELEVEN_INDEX = 23'd10; // A
  parameter TWELVE_INDEX = 23'd11; // B
  parameter THIRTEEN_INDEX = 23'd12; // C
  parameter FOURTEEN_INDEX = 23'd13; // D
  parameter FIFTEEN_INDEX = 23'd14; // E
  parameter TWENTY_INDEX = 23'd15; // F
  parameter THIRTY_INDEX = 23'd16; // 10
  parameter FOURTY_INDEX = 23'd17; // 11
  parameter FIFTY_INDEX = 23'd18; // 12
  parameter SIXTY_INDEX = 23'd19; // 13
  parameter SEVENTY_INDEX = 23'd20; // 14
  parameter EIGHTY_INDEX = 23'd21; // 15
  parameter NINETY_INDEX = 23'd22; // 16
  parameter HUNDRED_INDEX = 23'd23; // 17
  parameter TEEN_INDEX = 23'd24; // 18
  parameter PERCENT_INDEX = 23'd25; // 19
  parameter USED_INDEX = 23'd26; // 1A
  parameter HELP_AUDIO_INDEX = 23'd27; // 1B
  parameter SKIP_INDEX = 23'd28; // 1C
  parameter UNUSED_INDEX = 23'd31; // 1F

  //  raddr <= cur_index * TRACK_LENGTH

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
    .number(audioSelector),
    .hundreds(hundreds),
    .tens(tens),
    .ones(ones)
  );

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
  reg [15:0] bytesRxed = 0;

  // frdata has no guaruntees when not in read mode
  assign hexdisp = {playbackSeq[30:23], playbackSeq[7:0], 1'h0 ,trackEndAddr, 1'h0, raddr[22:0]};
  
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
            if (playbackSeq[45:23] < UNUSED_INDEX) begin
              // change raddr to next track
              raddr <= playbackSeq[45:23] * TRACK_LENGTH;
              // shift playbackSeq down
              playbackSeq <= {UNUSED_INDEX, playbackSeq[91:23]};
              // update trackEndAddr
              trackEndAddr <= playbackSeq[45:23] * TRACK_LENGTH + TRACK_LENGTH;
            end
            else if (playbackSeq[45:23] == UNUSED_INDEX) begin
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
            0: playbackSeq[91:23] <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX};
            1: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, ONE_INDEX};
            2: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, TWO_INDEX};
            3: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, THREE_INDEX};
            4: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, FOUR_INDEX};
            5: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, FIVE_INDEX};
            6: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, SIX_INDEX};
            7: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, SEVEN_INDEX};
            8: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, EIGHT_INDEX};
            9: playbackSeq[91:23] <= {USED_INDEX, PERCENT_INDEX, NINE_INDEX};
            default:  playbackSeq <= {USED_INDEX, PERCENT_INDEX, UNUSED_INDEX}; // error
          endcase
          case (tens)
            0: playbackSeq[22:0] <= SKIP_INDEX;
            1: playbackSeq[22:0] <= TEN_INDEX;
            2: playbackSeq[22:0] <= TWENTY_INDEX;
            3: playbackSeq[22:0] <= THIRTY_INDEX;
            4: playbackSeq[22:0] <= FOURTY_INDEX;
            5: playbackSeq[22:0] <= FIFTY_INDEX;
            6: playbackSeq[22:0] <= SIXTY_INDEX;
            7: playbackSeq[22:0] <= SEVENTY_INDEX;
            8: playbackSeq[22:0] <= EIGHTY_INDEX;
            9: playbackSeq[22:0] <= NINETY_INDEX;
            default: playbackSeq[22:0] <= UNUSED_INDEX;
          endcase
          case (hundreds)
            0: begin end
            1: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, HUNDRED_INDEX}; // error
          endcase
          case (audioSelector)
            11: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, ELEVEN_INDEX};
            12: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, TWELVE_INDEX};
            13: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, THIRTEEN_INDEX};
            14: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, FOURTEEN_INDEX};
            15: playbackSeq <= {UNUSED_INDEX, USED_INDEX, PERCENT_INDEX, FIFTEEN_INDEX};
            16: playbackSeq <= {USED_INDEX, PERCENT_INDEX, TEEN_INDEX, SIX_INDEX};
            17: playbackSeq <= {USED_INDEX, PERCENT_INDEX, TEEN_INDEX, SEVEN_INDEX};
            18: playbackSeq <= {USED_INDEX, PERCENT_INDEX, TEEN_INDEX, EIGHT_INDEX};
            19: playbackSeq <= {USED_INDEX, PERCENT_INDEX, TEEN_INDEX, NINE_INDEX};
            default: begin end
          endcase
        end // if (audioTrigger & ~lastAudioTrigger) 

        // just started playing - need to set raddr
        // Assuming this happens once playbackSeq has been properly set
        if (playing & ~lastPlaying) begin
          if (playbackSeq[22:0] == SKIP_INDEX) begin
            skipAddrOn <= 1;
            playbackSeq <= {UNUSED_INDEX, playbackSeq[91:23]};
            raddr <= playbackSeq[45:23] * TRACK_LENGTH;
            trackEndAddr <= playbackSeq[45:23] * TRACK_LENGTH + TRACK_LENGTH;
          end
          else begin
            raddr <= playbackSeq[22:0] * TRACK_LENGTH;
            trackEndAddr <= playbackSeq[22:0] * TRACK_LENGTH + TRACK_LENGTH;
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
