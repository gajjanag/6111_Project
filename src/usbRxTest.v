`default_nettype none

module usbRxTest(
  input wire clock,
  input wire reset,
  input wire [7:0] data, //the data pins from the USB fifo
  input wire rxf, //the rxf pin from the USB fifo
  output wire rd, // the rd pin from the USB fifo (OUTPUT)
  input wire triggerSwitch,
  output reg [63:0] hexdisp,
  output reg newout_on = 0
);
  
  //wire rd;        
  wire [7:0] out; // data from FIFO (OUTPUT)
  wire newout;  // newout=1 out contains new data (OUTPUT)
  wire hold;     //hold=1 the module will not accept new data from the FIFO
  wire [3:0] state; //for debugging purposes

  assign hold = triggerSwitch; //triggerSwitch

  usb_input usbtest(
    .clk(clock),
    .reset(reset),
    .data(data[7:0]),
    .rxf(rxf),
    .rd(rd),
    .out(out[7:0]),
    .newout(newout),
    .hold(hold),
    .state(state)
  );

  always @ (posedge clock) begin
    if (newout) begin
      newout_on <= 1;
      // display most recent byte RX'ed
      hexdisp <= {56'h0, out};
    end
  end

endmodule