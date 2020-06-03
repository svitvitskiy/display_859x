module eeprom_24lc #(
	parameter ADDRESS = 0,
	parameter BUS_ADDR_DATA_LEN = 16,
	parameter EEPROM_SIZE = 'h80
	)(
	input  rst,
	input  clk,
	input  [BUS_ADDR_DATA_LEN-1:0]addr,
	input  wr,
	input  rd,
	input  [7:0]bus_in,
	output reg[7:0]bus_out,
	output req_bus,
	output reg stall,
	inout  EEP_I2C_SCLK,
   inout  EEP_I2C_SDAT
	);

`define DEVICE_ADDR_WR  8'hA0
`define DEVICE_ADDR_RD  8'hA1

reg    [3:0]    state;
reg    [2:0]    COMMAND;
wire            BUSY;
wire            ERROR;

reg    [15:0]   eeprom_addr;
reg    [7:0]    eeprom_data;
reg    [7:0]    cmd[0:2];
reg             rd_running;
reg             wr_running;

assign req_bus = addr >= ADDRESS && addr < (ADDRESS + EEPROM_SIZE);
wire rd_int = req_bus && rd;
wire wr_int = req_bus && wr;

reg    [7:0]    DATA_OUT;
wire   [7:0]    DATA_IN;

i2c i2c_0 (EEP_I2C_SDAT, EEP_I2C_SCLK, COMMAND, BUSY, ERROR, clk, rst, DATA_OUT, DATA_IN);
  
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state      <= 3'h0;
    COMMAND    <= 3'b000;
	 stall      <= 1'b0;
	 rd_running <= 1'b0;
	 wr_running <= 1'b0;
  end 
  else if (!BUSY) begin
    if (rd_int | rd_running) begin
      case (state)
      3'd0: begin
        DATA_OUT      <= `DEVICE_ADDR_WR;
        COMMAND       <= 3'b011;
		  stall         <= 1'b1;
		  eeprom_addr   <= addr - ADDRESS;
		  rd_running    <= 1'b1;
      end
      3'd1: begin
        DATA_OUT   <= eeprom_addr[15:8];
        COMMAND    <= 3'b011;
      end
      3'd2: begin
        DATA_OUT   <= eeprom_addr[7:0];
        COMMAND    <= 3'b111;
      end
      3'd3: begin
        DATA_OUT   <= `DEVICE_ADDR_RD;
        COMMAND    <= 3'b011;
      end
      3'd4:    COMMAND <= 3'b101;
      default: begin
        bus_out    <= DATA_IN;
        COMMAND    <= 3'd000;
        stall      <= 1'b0;
        rd_running <= 1'b0;
      end
      endcase
      state <= state != 3'd5 ? state + 1 : state;
    end
    else if (wr_int | wr_running) begin
      case (state)
      3'd0: begin
        DATA_OUT    <= `DEVICE_ADDR_WR;
        COMMAND     <= 3'b011;
        stall       <= 1'b1;
        eeprom_addr <= addr - ADDRESS;
        eeprom_data <= bus_in;
        wr_running  <= 1'b1;
      end
      3'd1: begin
        DATA_OUT    <= eeprom_addr[15:8];
        COMMAND     <= 3'b011;
      end
      3'd2: begin
        DATA_OUT    <= eeprom_addr[7:0];
        COMMAND     <= 3'b011;
      end
      3'd3: begin
        DATA_OUT    <= eeprom_data;
        COMMAND     <= 3'b111;
      end
      default: begin
        COMMAND     <= 3'd000;
        stall       <= 1'b0;
        wr_running  <= 1'b0;
      end
      endcase
      state <= state != 3'd4 ? state + 1 : state;
	 end
  end
end

endmodule