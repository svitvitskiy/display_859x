///////
// I2C driver block
//
module i2c(SDAT, SCLK, COMMAND, BUSY, ERROR, CLK, RST, DATA_IN, DATA_OUT);
  output       SCLK;
  inout        SDAT;
  input  [2:0] COMMAND;
  output       BUSY;
  input        CLK;
  input        RST;
  output       ERROR;
  input  [7:0] DATA_IN;
  output [7:0] DATA_OUT;

  reg          running;
  reg          busy;
  reg  [4:0]   i2c_state;
  reg  [2:0]   command;
  reg          error;
  reg          sdat_drv, sclk_drv;
  reg  [7:0]   data;
  reg  [2:0]   data_ptr;
  
  assign BUSY     = busy;
  assign ERROR    = error;
  assign SDAT     = sdat_drv ? 1'b0 : 1'bz;
  assign SCLK     = sclk_drv ? 1'b0 : 1'bz;
  assign DATA_OUT = data;
  
  always @ (negedge CLK or posedge RST) begin
    
	 if (RST) begin
		running   <= 1'b0;
      busy      <= 1'b0;
      i2c_state <= 5'd0;
      command   <= 3'h0;
      error     <= 1'b0;
      sdat_drv  <= 1'b0;
		sclk_drv  <= 1'b0;
      data      <= 8'h00;
		data_ptr  <= 3'b000;
	 end
	 else if (!busy) begin
	   if (COMMAND[0]) begin
		  command   <= COMMAND;
		  busy      <= 1'b1;
		  if (COMMAND[1] == 1'b1)
		    data    <= DATA_IN;
		  i2c_state <= running ? 2 : 0;
		  running   <= 1'b1;
		  data_ptr  <= 3'b000;
		  sdat_drv  <= 1'b0;
		end
	 end
	 else begin
		case (i2c_state)
		5'd0: begin sdat_drv <= 1'b1; end
		5'd1: begin sclk_drv <= 1'b1; end
      5'd2,5'd5,5'd8,5'd11,5'd14,5'd17,5'd20,5'd23: begin
		  if (command[1] == 1'b1)
          sdat_drv <= ~data[7 - data_ptr];
		  else
		    data[7 - data_ptr] <= SDAT;
        data_ptr <= data_ptr + 1;
      end
      5'd3,5'd6,5'd9,5'd12,5'd15,5'd18,5'd21,5'd24: begin
        sclk_drv <= 1'b0;
      end
      5'd4,5'd7,5'd10,5'd13,5'd16,5'd19,5'd22,5'd25: begin
        sclk_drv <= 1'b1;
      end
      6'd26: begin
        sdat_drv <= 1'b0;
      end
      // ack
      6'd27: begin sclk_drv <= 1'b0; error <= SDAT; end
      6'd28: begin sclk_drv <= 1'b1; end
		// stop
      6'd29: begin sdat_drv <= 1'b1; end
		6'd30: begin sclk_drv <= 1'b0; end
		6'd31: begin sdat_drv <= 1'b0; end
		endcase

		if (i2c_state == 31 || (i2c_state == 28 && !command[2])) begin
	     i2c_state <= 5'd0;
		  command   <= 3'd0;
		  busy      <= 1'b0;
		  running   <= !command[2];
		end
		else
        i2c_state <= i2c_state + 1;
    end
  end
endmodule