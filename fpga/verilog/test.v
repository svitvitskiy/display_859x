`timescale 1ns / 1ps
`define CORE_TYPE				`MEGA_XMEGA_1
`define ROM_ADDR_WIDTH			10
`define BUS_ADDR_DATA_LEN		14
`define RAM_ADDR_WIDTH			12
`define RESERVED_RAM_FOR_IO		8192

//`define VECTOR_INT_TABLE_SIZE	0
//`define WATCHDOG_CNT_WIDTH		0
`define VECTOR_INT_TABLE_SIZE	11
`define WATCHDOG_CNT_WIDTH		27

module io_bus_dmux # (
		parameter NR_OF_BUSSES_IN = 1
		)(
		input [NR_OF_BUSSES_IN - 1 : 0]bus_req,
		input [(NR_OF_BUSSES_IN * 8) - 1 : 0]bus_in,
		output reg[7:0]bus_out
		);
reg [NR_OF_BUSSES_IN - 1 : 0]tmp_busses_bits;
integer cnt_add_busses;
integer cnt_add_bits;
		always @ *
		begin
			for(cnt_add_bits = 0; cnt_add_bits < 8; cnt_add_bits = cnt_add_bits + 1)
			begin: DMUX_IO_DATA_BITS
				for(cnt_add_busses = 0; cnt_add_busses < NR_OF_BUSSES_IN; cnt_add_busses = cnt_add_busses + 1)
				begin: DMUX_IO_DATA_BUSES
					tmp_busses_bits[cnt_add_busses] = bus_in[(cnt_add_busses * 8) + cnt_add_bits];
				end
				bus_out[cnt_add_bits] = |tmp_busses_bits;
			end
		end
endmodule

module test(LEDR, LEDG, SW, GPIO, CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
  output [17:0] LEDR;
  output [ 7:0] LEDG;
  input  [17:0] SW;
  inout  [35:0] GPIO;
  input         CLOCK_50;
  input  [3:0]  KEY;
  output [6:0]  HEX0;
  output [6:0]  HEX1;
  output [6:0]  HEX2;
  output [6:0]  HEX3;
  output [6:0]  HEX4;
  output [6:0]  HEX5;
  output [6:0]  HEX6;
  output [6:0]  HEX7;
  
  reg    [23:0] counter;
  wire          core_clk;
  wire          core_stall_0;
  wire          core_stall_1;
  
  assign core_clk = SW[17] & !core_stall_0 & counter[23];
  assign bus_clk  = SW[17] & counter[23];
  
  always @ (posedge CLOCK_50) counter <= counter + 1;
  
  wire [`ROM_ADDR_WIDTH-1:0]pgm_addr;
  wire [15:0]pgm_data;
  wire [`BUS_ADDR_DATA_LEN-1:0]data_addr;
  wire [7:0]core_data_out;
  wire data_write;
  wire [7:0]core_data_in;
  wire data_read;
  wire [5:0]io_addr;
  wire [7:0]io_out;
  wire io_write;
  wire [7:0]io_in;
  wire io_read;
  wire wdt_rst;

  wire ram_data_sel   = data_addr >= `RESERVED_RAM_FOR_IO;
  wire pioA_bus_req   = data_addr == 0;

  wire pll_locked;
  wire rst;
  assign pll_locked = 1'b1;
  assign rst = KEY[0];
  reg [7:0] ledg;
  assign LEDG = ledg;
  
  wire [7:0]pioA_bus_out = (io_read && ~|io_addr) ? SW[7:0] : 8'h00000000;
  assign LEDR[0] = rst;
  assign LEDR[3:1] = 3'b000;
  assign LEDR[17:4] = pgm_addr;
  
  always @(posedge bus_clk or negedge rst)
  begin
	if(~rst)
	begin
		ledg <= 8'hff;
	end
	else if(io_write && ~|io_addr[5:2])
	begin
		case(io_addr[1:0])
		2'h0: ledg <= io_out[7:0];
		2'h1: ledg <= ledg | io_out[7:0];
		2'h2: ledg <= ledg & ~io_out[7:0];
		endcase
	end
  end

  rom  #(
  .ADDR_ROM_BUS_WIDTH(`ROM_ADDR_WIDTH),
  .ROM_PATH("core1ROM.mem")
  )rom(
	.clk(bus_clk),
	.a(pgm_addr),
	.d(pgm_data)
  );
  
  wire [7:0]ram_bus_out;
  wire ram_bus_req = ram_data_sel;
  ram  #(
  .ADDR_BUS_WIDTH(`RAM_ADDR_WIDTH),
  .RAM_PATH("")
  )ram(
	.clk(bus_clk),
	.re(data_read & ram_data_sel),
	.we(data_write & ram_data_sel),
	.a(data_addr - `RESERVED_RAM_FOR_IO),
	.d_in(core_data_out),
	.d_out(ram_bus_out)
  );
  
  wire [7:0] eeprom_bus_out;
  wire [7:0] tv_bus_out;
  
  wire eeprom_bus_req;
  wire tv_bus_req;
  
  io_bus_dmux #(
    .NR_OF_BUSSES_IN(4)
  ) io_bus_dmux_inst(
    .bus_req({
	   pioA_bus_req,
      ram_bus_req,
      eeprom_bus_req,
		tv_bus_req
    }),
    .bus_in({
      pioA_bus_out, 
      ram_bus_out,
      eeprom_bus_out,
		tv_bus_out
    }),
    .bus_out(core_data_in)
  );
	
  seven_segm #(
    .ADDRESS('h40),
    .BUS_ADDR_DATA_LEN(`BUS_ADDR_DATA_LEN)
  ) seven_segm_inst (
   .rst(~rst),
	.clk(bus_clk),
   .addr(data_addr),
   .wr(data_write),
   .bus_in (core_data_out),
   .HEX0(HEX0),
   .HEX1(HEX1),
   .HEX2(HEX2),
   .HEX3(HEX3),
   .HEX4(HEX4),
   .HEX5(HEX5),
   .HEX6(HEX6),
   .HEX7(HEX7)
  );
  
  eeprom_24lc #(
    .ADDRESS('h100),
    .BUS_ADDR_DATA_LEN(`BUS_ADDR_DATA_LEN),
	 .EEPROM_SIZE('h100)
  ) eeprom_24lc_inst (
    .rst(~rst),
    .clk(bus_clk),
    .addr(data_addr),
    .wr(data_write),
	 .rd(data_read),
	 .bus_in (core_data_out),
	 .bus_out (eeprom_bus_out),
	 .req_bus (eeprom_bus_req),
	 .stall (core_stall_1),
	 .EEP_I2C_SCLK(EEP_I2C_SCLK),
    .EEP_I2C_SDAT(EEP_I2C_SCLK)
  );
  
  tv_adv7180 #(
    .ADDRESS('h200),
    .BUS_ADDR_DATA_LEN(`BUS_ADDR_DATA_LEN)
  ) tv_adv7180_inst (
    .rst(~rst),
    .clk(bus_clk),
    .addr(data_addr),
    .wr(data_write),
	 .rd(data_read),
	 .bus_in (core_data_out),
	 .bus_out (tv_bus_out),
	 .req_bus (tv_bus_req),
	 .stall (core_stall_0),
	 .sclk(I2C_SCLK),
    .sdat(I2C_SCLK)
  );
  
  xmega # (
	.PLATFORM("XILINX"),
	.CORE_TYPE(`CORE_TYPE),
	.ROM_ADDR_WIDTH(`ROM_ADDR_WIDTH),
	.RAM_ADDR_WIDTH(`BUS_ADDR_DATA_LEN),
	.WATCHDOG_CNT_WIDTH(`WATCHDOG_CNT_WIDTH),/* If is 0 the watchdog is disabled */
	.VECTOR_INT_TABLE_SIZE(`VECTOR_INT_TABLE_SIZE)

	) xmega_1_inst(
	.rst(~rst),
	.sys_rst_out(wdt_rst),
	.clk(core_clk),
	.clk_wdt(core_clk),
	.pgm_addr(pgm_addr),
	.pgm_data(pgm_data),
	.data_addr(data_addr),
	.data_out(core_data_out),
	.data_write(data_write),
	.data_in(core_data_in),
	.data_read(data_read),
	.io_addr(io_addr),
	.io_out(io_out),
	.io_write(io_write),
	.io_in(pioA_bus_out),
	.io_read(io_read),
	.hold(1'b0),
	.int_sig(),
	.int_rst()
  );

endmodule