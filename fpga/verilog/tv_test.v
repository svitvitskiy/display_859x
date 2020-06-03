module tv_test(EEP_I2C_SCLK, EEP_I2C_SDAT, CLOCK_50, KEY, SW, GPIO, LEDG);
  inout  EEP_I2C_SCLK;
  inout  EEP_I2C_SDAT;
  input  CLOCK_50;
  input  [3:0]  KEY;
  input  [17:0] SW;
  output [35:0] GPIO;
  output [7:0]  LEDG;
  
  reg  [15:0] counter;
  wire        clk;
  reg  [7:0]  i2c_state;
  wire [7:0]  addr;
  reg  [7:0]  data;
  reg         error;
  wire [7:0]  zebra;
  
  reg         sdat_drv, sclk_drv;
  
  reg  [2:0]  data_ptr;
  
  assign clk       = SW[0] ? counter[15] : 1'bz;
  
  assign GPIO[0]   = EEP_I2C_SDAT;
  assign GPIO[1]   = EEP_I2C_SCLK;
  assign GPIO[2]   = clk;
  
  assign addr      = 8'hA1;
  
  assign EEP_I2C_SDAT = sdat_drv ? 1'b0 : 1'bz;
  assign EEP_I2C_SCLK = sclk_drv ? 1'b0 : 1'bz;
  assign LEDG         = data;
  assign zebra        = 8'b10101010;
  
  always @ (posedge CLOCK_50) counter <= counter + 1;
  
  always @ (posedge clk or negedge KEY[0]) begin
    if (!KEY[0]) begin
	   i2c_state <= 6'h00;
		sdat_drv  <= 1'b0;
		sclk_drv  <= 1'b0;
		error     <= 1'b0;
		data_ptr  <= 3'b000;
		data      <= 8'h00;
	 end
	 else begin
	   if (!SW[1]) begin
			case (i2c_state)
			// start
			6'd0: begin error <= (EEP_I2C_SDAT == 1'b0) || (EEP_I2C_SCLK == 1'b0); end
			6'd1: begin sdat_drv <= 1'b1; end
			6'd2: begin sclk_drv <= 1'b1; end
			6'd3: begin end
			
			// addr
			6'd4, 6'd7,6'd10,6'd13,6'd16,6'd19,6'd22,6'd25: begin
			  sdat_drv <= ~addr[7 - data_ptr];
			  data_ptr <= data_ptr + 1;
			end
		
			6'd5, 6'd8,6'd11,6'd14,6'd17,6'd20,6'd23,6'd26: begin
			  sclk_drv <= 1'b0;
			end
			
			6'd6, 6'd9,6'd12,6'd15,6'd18,6'd21,6'd24,6'd27: begin
			  sclk_drv <= 1'b1;
			end
			
			6'd28: begin
			  sdat_drv <= 1'b0;
			end
			
			// ack
			6'd29: begin error <= EEP_I2C_SDAT; end
		
			6'd30,6'd33,6'd36,6'd39,6'd42,6'd45,6'd48,6'd51: begin
			  sclk_drv <= 1'b0;
			end
			
			6'd31,6'd34,6'd37,6'd40,6'd43,6'd46,6'd49,6'd52: begin
			  sclk_drv <= 1'b1;
			end
			
			6'd32,6'd35,6'd38,6'd41,6'd44,6'd47,6'd50,6'd53: begin
				data[7 - data_ptr] <= EEP_I2C_SDAT;
				data_ptr <= data_ptr + 1;
			end
			
			// stop seq
			6'd54: begin sdat_drv <= 1'b1; end
			6'd55: begin sclk_drv <= 1'b0; end
			6'd56: begin sdat_drv <= 1'b0; end
			default: begin sdat_drv <= 1'b0; sclk_drv <= 1'b0; end
			endcase
			i2c_state <= i2c_state != 6'd57 ? i2c_state + 1 : i2c_state;
			end
		else begin
			case (i2c_state)
			// start
			8'd0: begin error <= (EEP_I2C_SDAT == 1'b0) || (EEP_I2C_SCLK == 1'b0); end
			8'd1: begin sdat_drv <= 1'b1; end
			8'd2: begin sclk_drv <= 1'b1; end
			8'd3: begin end
			
			// addr
			8'd4, 8'd7,8'd10,8'd13,8'd16,8'd19,8'd22: begin
			  sdat_drv <= ~addr[7 - data_ptr];
			  data_ptr <= data_ptr + 1;
			end
			8'd25: begin
			  sdat_drv <= 1'b1;
			  data_ptr <= 1'b0;
			end
		
			8'd5, 8'd8,8'd11,8'd14,8'd17,8'd20,8'd23,8'd26: begin
			  sclk_drv <= 1'b0;
			end
			
			8'd6, 8'd9,8'd12,8'd15,8'd18,8'd21,8'd24,8'd27: begin
			  sclk_drv <= 1'b1;
			end
			
			8'd28: begin
			  sdat_drv <= 1'b0;
			end
			
			// ack
			8'd29: begin sclk_drv <= 1'b0; error <= EEP_I2C_SDAT; end
			8'd30: begin sclk_drv <= 1'b1; end
			
			// hi addr
			8'd31,8'd34,8'd37,8'd40,8'd43,8'd46,8'd49,8'd52: begin
			  sdat_drv <= 1'b1;
			end
					
			8'd32,8'd35,8'd38,8'd41,8'd44,8'd47,8'd50,8'd53: begin
			  sclk_drv <= 1'b0;
			end
			
			8'd33,8'd36,8'd39,8'd42,8'd45,8'd48,8'd51,8'd54: begin
			  sclk_drv <= 1'b1;
			end
			
			8'd55: begin
			  sdat_drv <= 1'b0;
			end
			
			// ack
			8'd56: begin sclk_drv <= 1'b0; error <= EEP_I2C_SDAT; end
			8'd57: begin sclk_drv <= 1'b1; end
			
			// lo addr
			8'd58,8'd61,8'd64,8'd67,8'd70,8'd73,8'd76,8'd79: begin
			  sdat_drv <= 1'b1;
			end
		
			8'd59,8'd62,8'd65,8'd68,8'd71,8'd74,8'd77,8'd80: begin
			  sclk_drv <= 1'b0;
			end
			
			8'd60,8'd63,8'd66,8'd69,8'd72,8'd75,8'd78,8'd81: begin
			  sclk_drv <= 1'b1;
			end
			
			8'd82: begin
			  sdat_drv <= 1'b0;
			end
			
			// ack
			8'd83: begin sclk_drv <= 1'b0; error <= EEP_I2C_SDAT; end
			8'd84: begin sclk_drv <= 1'b1; end
			
			// data
			8'd85,8'd88,8'd91,8'd94,8'd97,8'd100,8'd103,8'd106: begin
			  sdat_drv <= ~zebra[7 - data_ptr];
			  data_ptr <= data_ptr + 1;
			end
		
			8'd86,8'd89,8'd92,8'd95,8'd98,8'd101,8'd104,8'd107: begin
			  sclk_drv <= 1'b0;
			end
			
			8'd87,8'd90,8'd93,8'd96,8'd99,8'd102,8'd105,8'd108: begin
			  sclk_drv <= 1'b1;
			end
			
			8'd109: begin
			  sdat_drv <= 1'b0;
			end
			
			// ack
			8'd110: begin sclk_drv <= 1'b0; error <= EEP_I2C_SDAT; end
			8'd111: begin sclk_drv <= 1'b1; end
		
			// stop seq
			8'd112: begin sdat_drv <= 1'b1; end
			8'd113: begin sclk_drv <= 1'b0; end
			8'd114: begin sdat_drv <= 1'b0; end
			default: begin sdat_drv <= 1'b0; sclk_drv <= 1'b0; end
			endcase
			if (i2c_state < 115)
			  i2c_state <= i2c_state + 1;
		end
	 end
  end
endmodule