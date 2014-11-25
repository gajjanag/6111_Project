//manages all the stuff needed to read and write to the flash ROM
module flash_manager(
	clock, reset, 
	dots, 
	writemode, 
	wdata, 
	dowrite, 
	raddr, 
	frdata, 
	doread, 
	busy, 
	flash_data, 
	flash_address, 
	flash_ce_b, 
	flash_oe_b, 
	flash_we_b, 
	flash_reset_b, 
	flash_sts, 
	flash_byte_b, 
	fsmstate);
	 
	input reset, clock;			//clock and reset
	output [639:0] dots;		//outputs to dot-matrix to help debug flash, not necessary
	input writemode;			//if true then we're in write mode, else we're in read mode
	input [15:0] wdata;			//data to be written
	input dowrite;				//putting this high tells the manager the data it has is new, write it
	input [22:0] raddr;			//address to read from
	output[15:0] frdata;		//data being read
	reg[15:0]    rdata;
	input doread;				//putting this high tells the manager to perform a read on the current address
	output busy;				//and an output to tell folks we're still working on the last thing
	reg busy;

	inout [15:0] flash_data;					//direct passthrough from labkit to low-level modules (flash_int and test_fsm)
    output [23:0] flash_address;
    output flash_ce_b, flash_oe_b, flash_we_b;
    output flash_reset_b, flash_byte_b;
    input  flash_sts;

	wire flash_busy;		//except these, which are internal to the interface
	wire[15:0] fwdata;
	wire[15:0] frdata;
	wire[22:0] address;							
	wire [1:0] op;	
	
	reg [1:0] mode;
	wire fsm_busy;
	
	reg[2:0] state;					//210
	
	output[11:0] fsmstate;
	wire [7:0] fsmstateinv;
	assign fsmstate = {state,flash_busy,fsm_busy,fsmstateinv[4:0],mode};	//for debugging only
	
										//this guy takes care of /some/ of flash's tantrums
	flash_int flash(reset, clock, op, address, fwdata, frdata, flash_busy, flash_data, flash_address, flash_ce_b, flash_oe_b, flash_we_b, flash_reset_b, flash_sts, flash_byte_b);
										//and this guy takes care of the rest of its tantrums
	test_fsm  fsm  (reset, clock, op, address, fwdata, frdata, flash_busy, dots, mode, fsm_busy, wdata, raddr, fsmstateinv);

	parameter MODE_IDLE	= 0;
	parameter MODE_INIT	= 1;
	parameter MODE_WRITE = 2;
	parameter MODE_READ	= 3;
	
	parameter HOME 		= 3'd0;
	parameter MEM_INIT 	= 3'd1;
	parameter MEM_WAIT 	= 3'd2;
	parameter WRITE_READY= 3'd3;
	parameter WRITE_WAIT	= 3'd4;
	parameter READ_READY	= 3'd5;
	parameter READ_WAIT 	= 3'd6;
	
	always @ (posedge clock)
		if(reset)
			begin
				busy <= 1;
				state <= HOME;
				mode <= MODE_IDLE;
			end
		else begin		
			case(state)
				HOME://0				//we always start here
					if(!fsm_busy)
						begin
							busy <= 0;
							if(writemode)
								begin
									busy <= 1;
									state <= MEM_INIT;
								end
							else
								begin
									busy <= 1;
									state <= READ_READY;
								end
						end
					else
						mode <= MODE_IDLE;
					
				MEM_INIT://1							//begin wiping the memory
					begin
						busy <= 1;
						mode <= MODE_INIT;
						if(fsm_busy)					//to give the fsm a chance to raise its busy signal
							state <= MEM_WAIT;
					end
					
				MEM_WAIT://2						//finished wiping
					if(!fsm_busy)
						begin
							busy <= 0;
							state<= WRITE_READY;
						end
					else
						mode <= MODE_IDLE;

				WRITE_READY://3					//waiting for data to write to flash
					if(dowrite)
						begin
							busy <= 1;
							mode <= MODE_WRITE;
						end
					else if(busy)
						state <= WRITE_WAIT;
					else if(!writemode)
						state <= READ_READY;
				 
				WRITE_WAIT://4				//waiting for flash to finish writing
					if(!fsm_busy)
						begin
							busy <= 0;
							state <= WRITE_READY;
						end
					else
						mode <= MODE_IDLE;
				
				READ_READY://5				//ready to read data
					if(doread)
						begin
							busy <= 1;
							mode <= MODE_READ;
							if(busy)			//lets the fsm raise its busy level
								state <= READ_WAIT;
						end
					else
						busy <= 0;
				
				READ_WAIT://6			//waiting for flash to give the data up
					if(!fsm_busy)
						begin
							busy <= 0;
							state <= READ_READY;
						end
					else
						mode <= MODE_IDLE;
				
				default: begin		//should never happen...
					state <= 3'd7;
				end
			endcase
	end
endmodule