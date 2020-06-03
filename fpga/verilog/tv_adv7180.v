module tv_adv7180 #(
	parameter ADDRESS = 0,
	parameter BUS_ADDR_DATA_LEN = 16
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
	inout  sclk,
   inout  sdat
	);

`define DEVICE_ADDR_WR  'h40
`define DEVICE_ADDR_RD  'h41
`define DEVICE_LST_REG  'hff

assign req_bus = addr >= ADDRESS && addr <= (ADDRESS + `DEVICE_LST_REG);
wire rd_int = req_bus && rd;
wire wr_int = req_bus && wr;

reg       [2:0] state;
reg             rd_running;
reg             wr_running;

reg             sclk_drv;
reg             sdat_drv;
reg       [3:0] send_bit;
reg       [1:0] send_wrd;
reg       [7:0] data[0:1];
reg             ack_good;  // did slave acknowledge?

assign sclk = sclk_drv ? 1'b0 : 1'bz;
assign sdat = sdat_drv ? 1'b0 : 1'bz;

`define STATE_WR_INIT1  0
`define STATE_WR_INIT2  1
`define STATE_WR_DATA   2
`define STATE_WR_PULSE1 3
`define STATE_WR_PULSE2 4
`define STATE_WR_DONE   5
`define STATE_WR_DONE1  6
`define STATE_RD_INIT1  7
`define STATE_RD_INIT2  8
`define STATE_RD_DATA   9
`define STATE_RD_PULSE1 10
`define STATE_RD_PULSE2 11
`define STATE_RD_DONE   12
`define STATE_STOP      13

always @ (posedge clk or posedge rst) begin
  // didn't get the ack? reset everything to the
  // initial state
  if (rst) begin
    state      <= `STATE_WR_INIT1;
	 stall      <= 0;
	 rd_running <= 0;
	 wr_running <= 0;
	 sclk_drv   <= 0;
	 sdat_drv   <= 0;
	 send_bit   <= 0;
	 send_wrd   <= 0;
	 ack_good   <= 1;
  end
  else if (!ack_good) begin
    state      <= `STATE_WR_INIT1;
	 stall      <= 0;
	 wr_running <= 0;
	 sclk_drv   <= 0;
	 sdat_drv   <= 0;
	 send_bit   <= 0;
	 send_wrd   <= 0;
	 ack_good   <= 1;
  end
  else if (wr_int | wr_running) begin
    case (state)
	 `STATE_WR_INIT1: begin
	   stall      <= 1;
		wr_running <= 1;
		// start condition
		sdat_drv   <= 1;
		// latching the data to send through i2c
		data[1]    <= addr - ADDRESS;
		data[2]    <= bus_in;
		state      <= 1;
	 end
	 `STATE_WR_INIT2: begin
	   sclk_drv   <= 1;
	   state      <= `STATE_WR_DATA;
	 end
	 `STATE_WR_DATA: begin	 
		// data or ack bit
		sdat_drv   <= (send_bit != 8) ?
	                   (send_wrd == 0 ? ~`DEVICE_ADDR_WR[send_bit] : ~data[send_wrd - 1][send_bit]) : 0;
		// sence ack bit
		ack_good   <= send_bit == 8 ? ~sdat : 1;
      state      <= `STATE_WR_PULSE1;
    end
	 `STATE_WR_PULSE1: begin 
	   sclk_drv   <= 0; 
		state      <= `STATE_WR_PULSE2;
    end
	 `STATE_WR_PULSE2: begin
      sclk_drv   <= 1;
		send_bit   <= (send_bit == 8) ? 0 : send_bit + 1;		
		send_wrd   <= (send_wrd == 2) ? 0 : send_wrd + 1;
		sdat_drv   <= (send_bit == 7) ? 0 : 1;
		state      <= (send_bit == 8) && (send_wrd == 2) ? `STATE_WR_DONE : `STATE_WR_DATA;
    end	 
	 `STATE_WR_DONE: begin 
	   // grab the data
	   sdat_drv   <= 1;
	 	state      <= `STATE_WR_DONE1;
    end
	 `STATE_WR_DONE1: begin 
	   // let go the clock, ready yto stop
      sclk_drv   <= 0;
      state      <= `STATE_WR_STOP;
    end
	 default: begin
	   // stop cond: clk: hi, data->hi
	   sdat_drv   <= 0 
	   stall      <= 0;
		wr_running <= 0;
		ack_good   <= 1;
		state      <= `STATE_WR_INIT1;;
    end
	 endcase 
  end
  else if (rd_int | rd_running) begin
    case (state)
	 `STATE_WR_INIT1: begin
	   stall      <= 1;
		rd_running <= 1;
		// start condition
		sdat_drv   <= 1;
		data[0]    <= addr - ADDRESS;
		state      <= `STATE_WR_INIT2;
	 end
	 `STATE_WR_INIT2: begin
	   sclk_drv   <= 1;
	   state      <= `STATE_WR_DATA;
	 end
	 `STATE_WR_DATA: begin
		// data or ack bit
		sdat_drv   <= send_bit != 8 ? 
                      (send_wrd == 0 ? ~`DEVICE_ADDR_WR[send_bit] : ~data[0][send_bit]) :
							 0;
		// sence ack bit
		ack_good   <= send_bit == 8 ? ~sdat : 1;
      state      <= `STATE_WR_PULSE1;
    end
	 `STATE_WR_PULSE1: begin 
	   sclk_drv   <= 0;
		state      <= `STATE_WR_PULSE2;
    end
	 `STATE_WR_PULSE2: begin
	   sclk_drv   <= 1;
		send_bit   <= (send_bit == 8) ? 0 : send_bit + 1;		
		send_wrd   <= (send_wrd == 1) ? 0 : send_wrd + 1;
		sdat_drv   <= (send_bit == 7) ? 0 : 1;
		state      <= (send_bit == 8 && send_wrd == 1) ? `STATE_WR_DONE : `STATE_WR_DATA;
    end
	 `STATE_WR_DONE: begin
	   // let go of the clock, ready to restart
		sclk_drv   <= 0;
		state      <= `STATE_RD_INIT1;
	 end
	 `STATE_RD_INIT1: begin
	   // start condition
	   sdat_drv   <= 1;
		state      <= `STATE_RD_INIT2;
	 end
	 `STATE_RD_INIT2: begin
      sclk_drv   <= 1;
		state      <= `STATE_RD_DATA;
	 end
	 `STATE_RD_DATA: begin
	   // send addr or ack bit
		sdat_drv   <= send_bit != 8 && send_wrd == 0 ?  ~`DEVICE_ADDR_RD[send_bit] : 
		                send_bit == 8 && send_wrd == 1 ? 1 : 0;
						  
		// sence ack bit
		ack_good   <= send_bit == 8 && send_wrd == 0 ? ~sdat : ack_good;
		// sence data
		if (send_bit != 8)
        data[1][send_bit] <= send_wrd == 1 ? sdat : 0;
		  
		state      <= `STATE_RD_PULSE1;
    end
	 `STATE_RD_PULSE1: begin 
	   sclk_drv   <= 0; 
		state      <= `STATE_RD_PULSE2;
    end
	 `STATE_RD_PULSE2: begin
	   sclk_drv   <= 1;      
		send_bit   <= (send_bit == 8) ? 0 : send_bit + 1;		
		send_wrd   <= (send_wrd == 1) ? 0 : send_wrd + 1;
		sdat_drv   <= (send_bit == 7 && send_wrd == 0 || send_bit < 7 && send_wrd == 1) ? 0 : 1;
		state      <= (send_bit == 8) && (send_wrd == 1) ? `STATE_RD_DONE : `STATE_RD_DATA;	 
    end
	 `STATE_RD_DONE: begin 
	   // let go clk, ready to stop
	   sck_drv    <= 0;
	 	state      <= `STATE_STOP;
    end	 
	 default: begin
	   // stop condition, clk: hi, data->hi
	   sdat_drv   <= 0; 
	   stall      <= 0;
		wr_running <= 0;
		ack_good   <= 1;
		state      <= `STATE_WR_INIT1;
    end
	 endcase 
  end
end

endmodule