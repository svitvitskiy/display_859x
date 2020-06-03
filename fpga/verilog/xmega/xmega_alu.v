/*
 * This IP is the MEGA/XMEGA ALU implementation.
 * 
 * Copyright (C) 2018  Iulian Gheorghiu (morgoth.creator@gmail.com)
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

`timescale 1ns / 1ps

`include "xmega_v.v"

module xmega_alu # (
		parameter  [`CORE_TYPE_BUS_LEN - 1:0]CORE_TYPE = `MEGA_XMEGA_1
		)(
	input [15:0]inst,
	input [4:0]rs1a,
	input [15:0]rs1,
	input [4:0]rs2a,
	input [15:0]rs2,
	input [4:0]rda,
	output reg [15:0]rd,
	input [7:0]sreg_in,
	output reg[7:0]sreg_out
);

reg [7:0]TMP;

//#pragma HLS RESOURCE variable=temp core=FMul_nodsp
(* use_dsp48 = "yes" *)
wire [15:0]mul_result_int = rs1 * rs2;
//wire mul_sign_int = rs1[7] ^ rs2[7];

wire flag_h_adc_sub_cp = |{(~rs1[3] & rs2[3]), (rs2[3] & rd[3]), (rd[3] & ~rs1[3])};
wire flag_h_subi_sbci_cpi = |{(~rs1[3] & inst[3]), (inst[3] & rd[3]), (rd[3] & ~rs1[3])};
wire flag_v_add_adc = (&{rs1[7], rs2[7], ~rd[7]}) | (&{~rs1[7], ~rs2[7], rd[7]});
wire flag_v_sub_sbc = (&{rs1[7], ~rs2[7], ~rd[7]}) | (&{~rs1[7], rs2[7], rd[7]});
wire flag_v_subi_sbci_cpi = (&{rs1[7], ~inst[11], ~rd[7]}) | (&{~rs1[1], inst[11], rd[7]});

wire in_addr_1_and_2_equal = rs1a == rs2a;

wire RD_8_IS_ZERO = ~(|rd[7:0]);
wire RD_16_IS_ZERO = ~(|rd);
wire FLAG_S_NEG_INC_DEC_ADD_ADC = rd[7] ^ sreg_out[`XMEGA_FLAG_V];
wire FLAG_S_SUB_SBC_CP_CPC = rd[7] ^ flag_v_sub_sbc;
wire FLAG_S_SUBI_SBCI_CPI = rd[7] ^ flag_v_subi_sbci_cpi;
wire FLAG_S_ADIW_SBIW = rd[15] ^ sreg_out[`XMEGA_FLAG_C];
wire FLAG_S_ADD_ADC = rd[7] ^ flag_v_add_adc;
wire [8:0]RESULT_SUBI_SBCI_CPI = rs1[7:0] - {inst[11:8], inst[3:0]};
wire [8:0]RESULT_ADD_ADC = rs1[7:0] + rs2[7:0];
wire [8:0]RESULT_SUB_SBC = rs1[7:0] - rs2[7:0];
//wire [15:0]RESULT_ADIW = rs1 + {inst[7:6], inst[3:0]};
//wire [15:0]RESULT_SBIW = rs1 - {inst[7:6], inst[3:0]};

always @ *
begin
	sreg_out = sreg_in;
	casex({CORE_TYPE, inst})
	`INSTRUCTION_MOVW,
	`INSTRUCTION_MOV: 
	begin
		rd = rs2;
	end
	`INSTRUCTION_MUL:
	begin
		rd = mul_result_int;
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_MULS:
	begin
		case({rs1[7], rs2[7]})
		2'b00: rd = {mul_result_int[15:8], mul_result_int[7:0]};/* Positive multiply */
		2'b10, 2'b01: rd = {~mul_result_int[15:8], mul_result_int[7:0]};/* One of operands are negative*/
		default: rd = {1'b0, 7'h00 - mul_result_int[14:8], mul_result_int[7:0]};/* Both operands are negative*/
		endcase
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_MULSU:
	begin
		rd = {(rs1[7] ? ~mul_result_int[15:8] : mul_result_int[15:8]), mul_result_int[7:0]};
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_FMUL:
	begin
		rd = {mul_result_int[14:0], 1'b0};
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_FMULS:
	begin
		case({rs1[7], rs2[7]})
		2'b00: rd = {mul_result_int[14:8], mul_result_int[7:0], 1'b0};/* Positive multiply */
		2'b10, 2'b01: rd = {~mul_result_int[14:8], mul_result_int[7:0], 1'b0};/* One of operands are negative*/
		default: rd = {7'h00 - mul_result_int[14:8], mul_result_int[7:0], 1'b0};/* Both operands are negative*/
		endcase
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_FMULSU:
	begin
		rd = {(rs1[7] ? ~mul_result_int[14:8] : mul_result_int[14:8]), mul_result_int[7:0], 1'b0};
		sreg_out[`XMEGA_FLAG_C] = rd[15];
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_SUB: 
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUB_SBC;
		sreg_out[`XMEGA_FLAG_H] = flag_h_adc_sub_cp;
		sreg_out[`XMEGA_FLAG_V] = flag_v_sub_sbc;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUB_SBC_CP_CPC;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_SBC: 
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUB_SBC - sreg_in[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_H] = flag_h_adc_sub_cp;
		sreg_out[`XMEGA_FLAG_V] = flag_v_sub_sbc;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUB_SBC_CP_CPC;
		sreg_out[`XMEGA_FLAG_Z] = &{~rd[7:0], sreg_in[`XMEGA_FLAG_Z]};
	end
	`INSTRUCTION_ADD:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_ADD_ADC;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
		if(in_addr_1_and_2_equal)
		begin // LSL
			sreg_out[`XMEGA_FLAG_H] = rs1[3];
			sreg_out[`XMEGA_FLAG_V] = rd[7] ^ sreg_out[`XMEGA_FLAG_C];
			sreg_out[`XMEGA_FLAG_S] = FLAG_S_NEG_INC_DEC_ADD_ADC;
		end
		else
		begin // ADD
			sreg_out[`XMEGA_FLAG_H] = |{(rs1[3] & rs2[3]), (rs2[3] & ~rd[3]), (~rd[3] & rs1[3])};
			sreg_out[`XMEGA_FLAG_V] = flag_v_add_adc;
			sreg_out[`XMEGA_FLAG_S] = FLAG_S_ADD_ADC;
		end
	end
	`INSTRUCTION_ADC: 
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_ADD_ADC + sreg_in[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
		if(in_addr_1_and_2_equal)
		begin // ROL
			sreg_out[`XMEGA_FLAG_H] = rs1[3];
			sreg_out[`XMEGA_FLAG_V] = rd[7] ^ sreg_out[`XMEGA_FLAG_C];
			sreg_out[`XMEGA_FLAG_S] = FLAG_S_NEG_INC_DEC_ADD_ADC;
		end
		else
		begin // ADC
			sreg_out[`XMEGA_FLAG_H] = |{(rs1[3] & rs2[3]), (rs2[3] & rd[3]), (~rd[3] & ~rs1[3])};
			sreg_out[`XMEGA_FLAG_V] = flag_v_add_adc;
			sreg_out[`XMEGA_FLAG_S] = FLAG_S_ADD_ADC;
		end
	end
	`INSTRUCTION_AND:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = rs1[7:0] & rs2[7:0];
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_EOR:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = rs1[7:0] ^ rs2[7:0];
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_OR:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = rs1[7:0] | rs2[7:0];
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_SUBI:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUBI_SBCI_CPI;
		sreg_out[`XMEGA_FLAG_H] = flag_h_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_V] = flag_v_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUBI_SBCI_CPI;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_SBCI:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUBI_SBCI_CPI - sreg_in[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_H] = flag_h_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_V] = flag_v_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUBI_SBCI_CPI;
		sreg_out[`XMEGA_FLAG_Z] = &{~rd[7:0], sreg_in[`XMEGA_FLAG_Z]};
	end
	`INSTRUCTION_ORI_SBR:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = rs1 | {inst[11:8], inst[3:0]};
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_ANDI_CBR:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = rs1 & {inst[11:8], inst[3:0]};
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_COM:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = {1'b1, 8'hFF - rs1[7:0]};
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_NEG:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = {|rs1[7:0], (8'h00 - rs1[7:0])};
		sreg_out[`XMEGA_FLAG_H] = rd[3] + ~rs1[3];
		sreg_out[`XMEGA_FLAG_V] = &{rd[7], ~rd[6:0]};
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_NEG_INC_DEC_ADD_ADC;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_SWAP:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = {rs1[3:0] , rs1[7:4]};
	end
	`INSTRUCTION_INC:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = rs1[7:0] + 1;
		sreg_out[`XMEGA_FLAG_V] = &{~rd[7], rd[6:0]};
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_NEG_INC_DEC_ADD_ADC;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_DEC:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = rs1[7:0] - 1;
		sreg_out[`XMEGA_FLAG_V] = &{~rd[7], rd[6:0]};
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_NEG_INC_DEC_ADD_ADC;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_ASR:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = {rs1[0], rs1[7], rs1[7:1]};
		sreg_out[`XMEGA_FLAG_V] = 1'b0;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = rd[7] ^ 1'b0;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_LSR:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = {rs1[0], 1'b0, rs1[7:1]};
		sreg_out[`XMEGA_FLAG_H] = rs1[3];
		sreg_out[`XMEGA_FLAG_N] = 1'b0;
		sreg_out[`XMEGA_FLAG_V] = 1'b0 ^ sreg_out[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_S] = 1'b0 ^ sreg_out[`XMEGA_FLAG_V];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_ROR:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = {rs1[0], sreg_in[`XMEGA_FLAG_C], rs1[7:1]};
		sreg_out[`XMEGA_FLAG_H] = rs1[3];
		sreg_out[`XMEGA_FLAG_N] = 1'b0;
		sreg_out[`XMEGA_FLAG_V] = 1'b0 ^ sreg_out[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_S] = 1'b0 ^ sreg_out[`XMEGA_FLAG_V];
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_CP:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUB_SBC;
		sreg_out[`XMEGA_FLAG_H] = flag_h_adc_sub_cp;
		sreg_out[`XMEGA_FLAG_V] = flag_v_sub_sbc;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUB_SBC_CP_CPC;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_CPC:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUB_SBC - sreg_in[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_H] = flag_h_adc_sub_cp;
		sreg_out[`XMEGA_FLAG_V] = flag_v_sub_sbc;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUB_SBC_CP_CPC;
		sreg_out[`XMEGA_FLAG_Z] = &{~rd[7:0], sreg_in[`XMEGA_FLAG_Z]};
	end
	`INSTRUCTION_CPI:
	begin
		//rd[15:8] = 8'h00;
		{sreg_out[`XMEGA_FLAG_C], rd[7:0]} = RESULT_SUBI_SBCI_CPI;
		sreg_out[`XMEGA_FLAG_H] = flag_h_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_V] = flag_v_subi_sbci_cpi;
		sreg_out[`XMEGA_FLAG_N] = rd[7];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_SUBI_SBCI_CPI;
		sreg_out[`XMEGA_FLAG_Z] = RD_8_IS_ZERO;
	end
	`INSTRUCTION_SEx_CLx:
	begin
		//rd[15:8] = 8'h00;
		sreg_out[inst[6:4]] = ~inst[7];
	end
	`INSTRUCTION_ADIW:
	begin
		{sreg_out[`XMEGA_FLAG_C], rd} = rs1 + {inst[7:6], inst[3:0]};
		sreg_out[`XMEGA_FLAG_V] = sreg_out[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_N] = rd[15];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_ADIW_SBIW;
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_SBIW:
	begin
		{sreg_out[`XMEGA_FLAG_C], rd} = rs1 - {inst[7:6], inst[3:0]};
		sreg_out[`XMEGA_FLAG_V] = sreg_out[`XMEGA_FLAG_C];
		sreg_out[`XMEGA_FLAG_N] = rd[15];
		sreg_out[`XMEGA_FLAG_S] = FLAG_S_ADIW_SBIW;
		sreg_out[`XMEGA_FLAG_Z] = RD_16_IS_ZERO;
	end
	`INSTRUCTION_LDI:
	begin
		//rd[15:8] = 8'h00;
		rd[7:0] = {inst[11:8], inst[3:0]};
	end
	`INSTRUCTION_BLD:
	begin
		//rd[15:8] = 8'h00;
		case(inst[2:0])
		3'h0: rd[7:0] = {rs1[7:1], sreg_in[`XMEGA_FLAG_T]};
		3'h1: rd[7:0] = {rs1[7:2], sreg_in[`XMEGA_FLAG_T], rs1[0]};
		3'h2: rd[7:0] = {rs1[7:3], sreg_in[`XMEGA_FLAG_T], rs1[1:0]};
		3'h3: rd[7:0] = {rs1[7:4], sreg_in[`XMEGA_FLAG_T], rs1[2:0]};
		3'h4: rd[7:0] = {rs1[7:5], sreg_in[`XMEGA_FLAG_T], rs1[3:0]};
		3'h5: rd[7:0] = {rs1[7:6], sreg_in[`XMEGA_FLAG_T], rs1[4:0]};
		3'h6: rd[7:0] = {rs1[7], sreg_in[`XMEGA_FLAG_T], rs1[5:0]};
		3'h7: rd[7:0] = {sreg_in[`XMEGA_FLAG_T], rs1[6:0]};
		endcase
	end
	`INSTRUCTION_BST:
	begin
		sreg_out[`XMEGA_FLAG_T] = rs1[inst[2:0]];
	end
	endcase
end
endmodule