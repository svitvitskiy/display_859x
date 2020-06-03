module seven_segm #(
  parameter ADDRESS = 0,
  parameter BUS_ADDR_DATA_LEN = 16
  )(
  input rst,
  input clk,
  input [BUS_ADDR_DATA_LEN-1:0]addr,
  input wr,
  input [7:0]bus_in,
  output reg[6:0] HEX0,
  output reg[6:0] HEX1,
  output reg[6:0] HEX2,
  output reg[6:0] HEX3,
  output reg[6:0] HEX4,
  output reg[6:0] HEX5,
  output reg[6:0] HEX6,
  output reg[6:0] HEX7
  );

`define CHAR_0 7'b1000000
`define CHAR_1 7'b1111001
`define CHAR_2 7'b0100100
`define CHAR_3 7'b0110000
`define CHAR_4 7'b0011001
`define CHAR_5 7'b0010010
`define CHAR_6 7'b0000010
`define CHAR_7 7'b1111000
`define CHAR_8 7'b0000000
`define CHAR_9 7'b0010000
`define CHAR_A 7'b0001000
`define CHAR_B 7'b0000011
`define CHAR_C 7'b1000110
`define CHAR_D 7'b0100001
`define CHAR_E 7'b0000110
`define CHAR_F 7'b0001110

wire wr_int = (addr >= ADDRESS && addr < (ADDRESS + 4)) && wr;
wire [6:0] codebook[0:15];
assign codebook[0] = `CHAR_0;
assign codebook[1] = `CHAR_1;
assign codebook[2] = `CHAR_2;
assign codebook[3] = `CHAR_3;
assign codebook[4] = `CHAR_4;
assign codebook[5] = `CHAR_5;
assign codebook[6] = `CHAR_6;
assign codebook[7] = `CHAR_7;
assign codebook[8] = `CHAR_8;
assign codebook[9] = `CHAR_9;
assign codebook[10] = `CHAR_A;
assign codebook[11] = `CHAR_B;
assign codebook[12] = `CHAR_C;
assign codebook[13] = `CHAR_D;
assign codebook[14] = `CHAR_E;
assign codebook[15] = `CHAR_F;

always @ (posedge clk or posedge rst) begin
  if(rst) begin
  end
  else begin
    if(wr_int) begin
	   case (addr[1:0])
		0: begin
	     HEX0 <= codebook[bus_in[3:0]];
		  HEX1 <= codebook[bus_in[7:4]];
		end
		1: begin
	     HEX2 <= codebook[bus_in[3:0]];
		  HEX3 <= codebook[bus_in[7:4]];
		end
		2: begin
	     HEX4 <= codebook[bus_in[3:0]];
		  HEX5 <= codebook[bus_in[7:4]];
		end
		3: begin
	     HEX6 <= codebook[bus_in[3:0]];
		  HEX7 <= codebook[bus_in[7:4]];
		end
		endcase
    end
  end
 end

endmodule