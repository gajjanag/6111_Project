//reads data and puts it on out
module usb_input(clk,reset,data,rd,rxf,out,newout,hold,state);
	input clk, reset;	//clock and reset
	input [7:0] data;	//the data pins from the USB fifo
	input rxf;			//the rxf pin from the USB fifo
	output rd;			//the rd pin from the USB fifo
	reg rd;

	output[7:0] out;	//this is where data goes when it has been read from the fifo
	reg[7:0] out;
	output newout;		//when this is high, out contains a new chunk of data
	reg newout;
	input hold;			//as long as hold is high, this module sits
						//still module and will not accept new data from the fifo
	
	output state;		//for debugging purposes
	reg[3:0] state;
	
	parameter RESET 		= 0;		//state data
	parameter WAIT			= 1;
	parameter WAIT2			= 2;
	parameter WAIT3			= 3;
	parameter DATA_COMING	= 4;
	parameter DATA_COMING_2	= 5;
	parameter DATA_COMING_3	= 6;
	parameter DATA_COMING_4	= 7;
	parameter DATA_COMING_5	= 8;
	parameter DATA_HERE  	= 9;
	parameter DATA_LEAVING	=10;
	parameter DATA_LEAVING_2=11;
	parameter DATA_LEAVING_3=12;
	parameter DATA_LEAVING_4=13;
	parameter DATA_LEAVING_5=14;
	parameter DATA_LEAVING_6=15;
	
	initial
		state <= WAIT;
	
	always @ (posedge clk)
		if(reset)
			begin
				newout <= 0;
				rd <= 1;			//we can't read data
				state <= WAIT;
			end
		else
			if(~hold)
				begin
					newout <= 0;
					case(state)
					WAIT:
						if(~rxf)		//if rxf is low and nobody's asking us to wait then there is data waiting for us
							begin
								rd <= 1;					//so ask for it
								state <= WAIT2;	//and start waiting for it
							end
							
					WAIT2:
						if(~rxf)		//double check
							begin
								rd <= 1;		
								state <= WAIT3;	
							end
						else
							state <= WAIT;
					
					WAIT3:
						if(~rxf)		//and triple check (should only need one, but oh well...)
							begin
								rd <= 0;			
								state <= DATA_COMING;
							end
						else
							state <= WAIT;
								
					DATA_COMING:		//once rd goes low we gotta wait a bit for the data to stabilize
						state <= DATA_COMING_2;
				
					DATA_COMING_2:
						state <= DATA_COMING_3;

					DATA_COMING_3:
						state <= DATA_HERE;

					DATA_HERE:
						begin
							out <= data;	//the data is valid by now so read it
							state <= DATA_LEAVING;
							newout <= 1;	//let folks know we've got new data
						end
			
					DATA_LEAVING:			//wait a cycle to clear the data to make sure we latch onto it correctly
						begin
							//rd <= 1; // ORIGINAL
							state <= DATA_LEAVING_2;
							newout <= 0;	//let folks know the data's a clock cycle old now
						end
					
					DATA_LEAVING_2:		//wait another cycle to make sure that the RD to RD pre-charge time is met
						state <= DATA_LEAVING_3;								
					
					DATA_LEAVING_3:		//wait another cycle to make sure that the RD to RD pre-charge time is met
						state <= DATA_LEAVING_4;								

					DATA_LEAVING_4:		//wait another cycle to make sure that the RD to RD pre-charge time is met
						state <= DATA_LEAVING_5;

					DATA_LEAVING_5:		//wait another cycle to make sure that the RD to RD pre-charge time is met
						state <= DATA_LEAVING_6;																

					DATA_LEAVING_6:		//wait another cycle to make sure that the RD to RD pre-charge time is met
						begin
							state <= WAIT;							
							rd <= 1;
						end
					default:
						state <= WAIT;
				endcase		
			end
endmodule