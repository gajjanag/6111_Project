`define STATUS_RESET             4'h0
`define STATUS_READ_ID           4'h1
`define STATUS_CLEAR_LOCKS       4'h2
`define STATUS_ERASING           4'h3
`define STATUS_WRITING           4'h4
`define STATUS_READING           4'h5
`define STATUS_SUCCESS           4'h6
`define STATUS_BAD_MANUFACTURER  4'h7
`define STATUS_BAD_SIZE          4'h8
`define STATUS_LOCK_BIT_ERROR    4'h9
`define STATUS_ERASE_BLOCK_ERROR 4'hA
`define STATUS_WRITE_ERROR       4'hB
`define STATUS_READ_WRONG_DATA   4'hC

`define NUM_BLOCKS 128
`define BLOCK_SIZE 64*1024
`define LAST_BLOCK_ADDRESS ((`NUM_BLOCKS-1)*`BLOCK_SIZE)
`define LAST_ADDRESS (`NUM_BLOCKS*`BLOCK_SIZE-1)

`define FLASHOP_IDLE  2'b00
`define FLASHOP_READ  2'b01
`define FLASHOP_WRITE 2'b10

module test_fsm (reset, clock, fop, faddress, fwdata, frdata, fbusy, dots, mode, busy, datain, addrin, state);
   input reset, clock;
   output [1:0] fop;
   output [22:0] faddress;
   output [15:0] fwdata;
   input [15:0]  frdata;
   input fbusy;
   output [639:0] dots;
   input [1:0] mode;
   output busy;
   input [15:0] datain;
   input [22:0] addrin;
   output state;

   reg [1:0] fop;
   reg [22:0] faddress;
   reg [15:0] fwdata;
   reg [639:0] dots;
   reg busy;
   reg [15:0] data_to_store;
      
   ////////////////////////////////////////////////////////////////////////////
   //   
   // State Machine
   //
   ////////////////////////////////////////////////////////////////////////////

   reg [7:0] state;
   reg [3:0] status;
	
   parameter MODE_IDLE	= 0;
   parameter MODE_INIT	= 1;
   parameter MODE_WRITE = 2;
   parameter MODE_READ	= 3;

   parameter MAX_ADDRESS = 23'h030000;

   parameter HOME = 8'h12;

   
   always @(posedge clock)
     if (reset)
       begin
			state <= HOME;
			status <= `STATUS_RESET;
			faddress <= 0;
			fop <= `FLASHOP_IDLE;
			busy <= 1;
       end
     else if (!fbusy && (fop == `FLASHOP_IDLE))
       case (state)
		 
	 HOME://12
		case(mode)
			MODE_INIT: begin
				state <= 8'h00;
				busy <= 1;
			end

			MODE_WRITE: begin
				state <= 8'h0C;
				busy <= 1;
			end

			MODE_READ: begin
				busy <= 1;
				if(status == `STATUS_READING)
					state <= 8'h11;
				else
					state <= 8'h10;
			end
			
			default: begin
				state <= HOME;
				busy <= 0;
			end
		endcase
	 
	 //////////////////////////////////////////////////////////////////////
	 // Wipe It
	 //////////////////////////////////////////////////////////////////////
	 8'h00:
		begin
			// Issue "read id codes" command
			status <= `STATUS_READ_ID;
			faddress <= 0;
			fwdata <= 16'h0090;
			fop <= `FLASHOP_WRITE;
			state <= state+1;
		end
	 
	 8'h01:
	   begin
	      // Read manufacturer code
	      faddress <= 0;
	      fop <= `FLASHOP_READ;
	      state <= state+1;
	   end
	 
	 8'h02:
	   if (frdata != 16'h0089) // 16'h0089 = Intel
	     status <= `STATUS_BAD_MANUFACTURER;
	   else
	     begin
		// Read the device size code
		faddress <= 1;
		fop <= `FLASHOP_READ;
		state <= state+1;
	     end
	 
	 8'h03:
	   if (frdata != 16'h0018) // 16'h0018 = 128Mbit
	     status <= `STATUS_BAD_SIZE;
	   else
	     begin
		faddress <= 0;
		fwdata <= 16'hFF;
		fop <= `FLASHOP_WRITE;
		state <= state+1;
	     end
		  
	 8'h04:
	   begin
	      // Issue "clear lock bits" command
	      status <= `STATUS_CLEAR_LOCKS;
	      faddress <= 0;
	      fwdata <= 16'h60;
	      fop <= `FLASHOP_WRITE;
	      state <= state+1;
	   end
		
	 8'h05:
	   begin
	      // Issue "confirm clear lock bits" command
	      faddress <= 0;
	      fwdata <= 16'hD0;
	      fop <= `FLASHOP_WRITE;
	      state <= state+1;
	   end
		
	 8'h06:
	   begin
	      // Read status
	      faddress <= 0;
	      fop <= `FLASHOP_READ;
	      state <= state+1;
	   end
		
	 8'h07:
	   if (frdata[7] == 1) // Done clearing lock bits
	     if (frdata[6:1] == 0) // No errors
	       begin
		  faddress <= 0;
		  fop <= `FLASHOP_IDLE;
		  state <= state+1;
	       end
	     else
	       status <= `STATUS_LOCK_BIT_ERROR;
	   else // Still busy, reread status register
	     begin
		faddress <= 0;
		fop <= `FLASHOP_READ;
	     end
	 
	 //////////////////////////////////////////////////////////////////////
	 // Block Erase Sequence
	 //////////////////////////////////////////////////////////////////////
	 8'h08:
	   begin
	      status <= `STATUS_ERASING;
	      fwdata <= 16'h20; // Issue "erase block" command
	      fop <= `FLASHOP_WRITE;
	      state <= state+1;
	   end
		
	 8'h09:
	   begin
	      fwdata <= 16'hD0; // Issue "confirm erase" command
	      fop <= `FLASHOP_WRITE;
	      state <= state+1;
	   end
	 8'h0A:
	   begin
	      fop <= `FLASHOP_READ;
	      state <= state+1;
	   end
	 8'h0B:
	   if (frdata[7] == 1) // Done erasing block
	     if (frdata[6:1] == 0) // No errors
	       if (faddress != MAX_ADDRESS) // `LAST_BLOCK_ADDRESS)
		 begin
		    faddress <= faddress+`BLOCK_SIZE;
		    fop <= `FLASHOP_IDLE;
		    state <= state-3;
		 end
	       else
		 begin
		    faddress <= 0;
		    fop <= `FLASHOP_IDLE;
		    state <= HOME;		//done erasing, go home
		 end
	     else // Erase error detected
	       status <= `STATUS_ERASE_BLOCK_ERROR;
	   else // Still busy
	     fop <= `FLASHOP_READ;
	 
	 //////////////////////////////////////////////////////////////////////
	 // Write Mode
	 //////////////////////////////////////////////////////////////////////
	 8'h0C:
		begin
			data_to_store <= datain;
			status <= `STATUS_WRITING;
			fwdata <= 16'h40; // Issue "setup write" command
			fop <= `FLASHOP_WRITE;
			state <= state+1;
		end
			
	 8'h0D:
	   begin
	      fwdata <= data_to_store; // Finish write
	      fop <= `FLASHOP_WRITE;
	      state <= state+1;
	   end
	 8'h0E:
	   begin
	      // Read status register
	      fop <= `FLASHOP_READ;
	      state <= state+1;
	   end
	 8'h0F:
	   if (frdata[7] == 1) // Done writing
	     if (frdata[6:1] == 0) // No errors
	       if (faddress != 23'h7FFFFF) // `LAST_ADDRESS)
				begin
					faddress <= faddress+1;
					fop <= `FLASHOP_IDLE;
					state <= HOME;
				end
			 else
				status <= `STATUS_WRITE_ERROR;
	     else // Write error detected
	       status <= `STATUS_WRITE_ERROR;
	   else // Still busy
	     fop <= `FLASHOP_READ;
	 
	 //////////////////////////////////////////////////////////////////////
	 // Read Mode INIT
	 //////////////////////////////////////////////////////////////////////
	 8'h10:
	   begin
	      status <= `STATUS_READING;
	      fwdata <= 16'hFF; // Issue "read array" command
	      fop <= `FLASHOP_WRITE;
	      faddress <= 0;
	      state <= state+1;
	   end

	 //////////////////////////////////////////////////////////////////////
	 // Read Mode
	 //////////////////////////////////////////////////////////////////////
	 8'h11:
	   begin
		  faddress <= addrin;
	      fop <= `FLASHOP_READ;
	      state <= HOME;
	   end
	
	default:
		begin
			status <= `STATUS_BAD_MANUFACTURER;
			faddress <= 0;
			state <= HOME;
		end
	
	endcase
     else
       fop <= `FLASHOP_IDLE;
       
   function [39:0] nib2char;
      input [3:0] nib;
      begin
	 case (nib)
	   4'h0: nib2char = 40'b00111110_01010001_01001001_01000101_00111110;
	   4'h1: nib2char = 40'b00000000_01000010_01111111_01000000_00000000;
	   4'h2: nib2char = 40'b01100010_01010001_01001001_01001001_01000110;
	   4'h3: nib2char = 40'b00100010_01000001_01001001_01001001_00110110;
	   4'h4: nib2char = 40'b00011000_00010100_00010010_01111111_00010000;
	   4'h5: nib2char = 40'b00100111_01000101_01000101_01000101_00111001;
	   4'h6: nib2char = 40'b00111100_01001010_01001001_01001001_00110000;
	   4'h7: nib2char = 40'b00000001_01110001_00001001_00000101_00000011;
	   4'h8: nib2char = 40'b00110110_01001001_01001001_01001001_00110110;
	   4'h9: nib2char = 40'b00000110_01001001_01001001_00101001_00011110;
	   4'hA: nib2char = 40'b01111110_00001001_00001001_00001001_01111110;
	   4'hB: nib2char = 40'b01111111_01001001_01001001_01001001_00110110;
	   4'hC: nib2char = 40'b00111110_01000001_01000001_01000001_00100010;
	   4'hD: nib2char = 40'b01111111_01000001_01000001_01000001_00111110;
	   4'hE: nib2char = 40'b01111111_01001001_01001001_01001001_01000001;
	   4'hF: nib2char = 40'b01111111_00001001_00001001_00001001_00000001;
	 endcase
      end
   endfunction

   wire [159:0] data_dots;
   assign data_dots = {nib2char(frdata[15:12]), nib2char(frdata[11:8]),
		       nib2char(frdata[7:4]), nib2char(frdata[3:0])};

   wire [239:0] address_dots;
   assign address_dots = {nib2char({ 1'b0, faddress[22:20]}),
			  nib2char(faddress[19:16]),
			  nib2char(faddress[15:12]),
			  nib2char(faddress[11:8]),
			  nib2char(faddress[7:4]),
			  nib2char(faddress[3:0])};
				      
   always @(status or address_dots or data_dots)
     case (status)
       `STATUS_RESET:
	 dots <= {40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b00000001_00000001_01111111_00000001_00000001, // T
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00001000_00001000_00001000_00001000_00001000, // -
		  40'b00001000_00001000_00001000_00001000_00001000, // -
		  40'b00001000_00001000_00001000_00001000_00001000, // -
		  40'b00001000_00001000_00001000_00001000_00001000, // -
		  40'b00001000_00001000_00001000_00001000_00001000, // -
		  40'b00001000_00001000_00001000_00001000_00001000};// -
       `STATUS_READ_ID:
	 dots <= {40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b01111111_01000001_01000001_01000001_00111110, // D
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b01111111_01000001_01000001_01000001_00111110, // D
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  address_dots}; 
       `STATUS_CLEAR_LOCKS:
	 dots <= {40'b00111110_01000001_01000001_01000001_00100010, // C
		  40'b01111111_01000000_01000000_01000000_01000000, // L
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b01111111_01000000_01000000_01000000_01000000, // L
		  40'b00111110_01000001_01000001_01000001_00111110, // O
		  40'b00111110_01000001_01000001_01000001_00100010, // C
		  40'b01111111_00001000_00010100_00100010_01000001, // K
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  address_dots};
       `STATUS_ERASING:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b01111111_00000010_00000100_00001000_01111111, // N
		  40'b00111110_01000001_01001001_01001001_00111010, // G
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  address_dots};
       `STATUS_WRITING:
	 dots <= {40'b01111111_00100000_00011000_00100000_01111111, // W
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b00000001_00000001_01111111_00000001_00000001, // T
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b01111111_00000010_00000100_00001000_01111111, // N
		  40'b00111110_01000001_01001001_01001001_00111010, // G
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  address_dots};
       `STATUS_READING:
	 dots <= {40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b01111111_01000001_01000001_01000001_00111110, // D
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b01111111_00000010_00000100_00001000_01111111, // N
		  40'b00111110_01000001_01001001_01001001_00111010, // G
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  address_dots};
       `STATUS_SUCCESS:
	 dots <= {40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b01111111_00001001_00001001_00001001_00000110, // P
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_01000001_01000001_01000001_00111110, // D
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00101010_00011100_01111111_00011100_00101010, // *
		  40'b00000000_00000000_00000000_00000000_00000000};//
       `STATUS_BAD_MANUFACTURER:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000, // 
		  40'b01111111_00000010_00001100_00000010_01111111, // M
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b01111111_00000010_00000100_00001000_01111111, // N
		  40'b01111111_00001001_00001001_00001001_00000001, // U
		  40'b01111111_00001001_00001001_00001001_00000001, // F
		  40'b00000000_00000000_00000000_00000000_00000000, // 
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  data_dots};
       `STATUS_BAD_SIZE:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b01100001_01010001_01001001_01000101_01000011, // Z
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b00000000_00000000_00000000_00000000_00000000,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  data_dots};
       `STATUS_LOCK_BIT_ERROR:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b01111111_01000000_01000000_01000000_01000000, // L
		  40'b00111110_01000001_01000001_01000001_00111110, // O
		  40'b00111110_01000001_01000001_01000001_00100010, // C
		  40'b01111111_00001000_00010100_00100010_01000001, // K
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b00000000_00000000_00000000_00000000_00000000,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  data_dots};
       `STATUS_ERASE_BLOCK_ERROR:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111110_00001001_00001001_00001001_01111110, // A
		  40'b00100110_01001001_01001001_01001001_00110010, // S
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b00000000_00000000_00000000_00000000_00000000,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  data_dots};
       `STATUS_WRITE_ERROR:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000, //
		  40'b01111111_00100000_00011000_00100000_01111111, // W
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_01000001_01111111_01000001_00000000, // I
		  40'b00000001_00000001_01111111_00000001_00000001, // T
		  40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b00000000_00000000_00000000_00000000_00000000,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  data_dots};
       `STATUS_READ_WRONG_DATA:
	 dots <= {40'b01111111_01001001_01001001_01001001_01000001, // E
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b01111111_00001001_00011001_00101001_01000110, // R
		  40'b00000000_00110110_00110110_00000000_00000000, // :
		  40'b00000000_00000000_00000000_00000000_00000000,
		  address_dots,
		  40'b00000000_00000000_00000000_00000000_00000000,
		  data_dots};
	 default:
	 dots <= {16{40'b01010101_00101010_01010101_00101010_01010101}};
     endcase
   
endmodule
