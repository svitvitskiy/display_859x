module tv_test1(EEP_I2C_SCLK, EEP_I2C_SDAT, CLOCK_50, KEY, SW, GPIO, LEDG, LEDR);
  inout  EEP_I2C_SCLK;
  inout  EEP_I2C_SDAT;
  input  CLOCK_50;
  input  [3:0]  KEY;
  input  [17:0] SW;
  output [17:0] LEDR;
  output [35:0] GPIO;
  output [7:0]  LEDG;
  
  reg    [15:0]   counter;
  wire            clk;
  wire            rst;
  reg    [3:0]    state;
  reg    [2:0]    COMMAND;
  reg    [7:0]    DATA_OUT;
  wire   [7:0]    DATA_IN;
  wire            BUSY;
  wire            ERROR;
  reg    [1:0]    delay;
  
  assign GPIO[0]   = EEP_I2C_SDAT;
  assign GPIO[1]   = EEP_I2C_SCLK;
  assign GPIO[2]   = clk;
  assign GPIO[3]   = BUSY;
  
  assign GPIO[4]   = DATA_OUT[4];
  assign GPIO[5]   = DATA_OUT[5];
  assign GPIO[6]   = DATA_OUT[6];
  assign GPIO[7]   = DATA_OUT[7];
  
  assign LEDR      = SW;

  assign LEDG = DATA_IN;
  assign clk  = SW[0] ? counter[15] : 1'b0;
  assign rst  = !KEY[0];
  
  always @ (posedge CLOCK_50) counter <= counter + 1;
  
  i2c i2c_0 (EEP_I2C_SDAT, EEP_I2C_SCLK, COMMAND, BUSY, ERROR, clk, rst, DATA_OUT, DATA_IN);
  
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
	   state    <= 3'h0;
		COMMAND  <= 3'b000;
		DATA_OUT <= 3'h00;
		delay    <= 3'b11;
	 end
	 else if (delay) begin
	   delay <= delay - 1;
	 end
	 else if (!BUSY) begin
	   if (!SW[1]) begin
        case (state)
		  3'd0: begin
		    DATA_OUT <= 8'hA0;
		    COMMAND  <= 3'b011;
		  end
		  3'd1: begin
		    DATA_OUT <= 8'h00;
		    COMMAND  <= 3'b011;
		  end
		  3'd2: begin
		    DATA_OUT <= 8'h00;
		    COMMAND  <= 3'b111;
		  end
		  3'd3: begin
		    DATA_OUT <= 8'hA1;
		    COMMAND  <= 3'b011;
		  endtv_test1.v
		  3'd4:    COMMAND <= 3'b101;
		  default: COMMAND <= 3'd000;
        endcase
        state <= state != 3'd5 ? state + 1 : state;
      end
      else begin
	     case (state)
		  3'd0: begin
		    DATA_OUT <= 8'hA0;
		    COMMAND  <= 3'b011;
		  end
		  3'd1: begin
		    DATA_OUT <= 8'h00;
		    COMMAND  <= 3'b011;
		  end
		  3'd2: begin
		    DATA_OUT <= 8'h00;
		    COMMAND  <= 3'b011;
		  end
		  3'd3: begin
		    DATA_OUT <= 8'b10101010;
		    COMMAND  <= 3'b111;
		  end
		  default: COMMAND <= 3'd000;
        endcase
        state <= state != 3'd4 ? state + 1 : state;
	   end
    end
  end
endmodule