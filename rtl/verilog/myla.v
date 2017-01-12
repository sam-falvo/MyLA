`timescale 1ns / 1ps


`include "myla.vh"


module MYLA(
	input			CLK_I,
	input			RES_I,

	input			ADR_I,
	input			WE_I,
	input			CYC_I,
	input			STB_I,
	output			ACK_O,
	output	[DBITS-1:0]	DAT_O,

	input	[DBITS-1:0]	CHAN_I,
	input			GATE_I
);
	parameter DBITS = `DBITS;
	parameter QBITS = `QBITS;

	reg	[DBITS-1:0]	queue[0:(1<<QBITS)-1];
	reg	[QBITS-1:0]	rp;
	reg	[QBITS-1:0]	wp;
	wire	[QBITS-1:0]	next_wp;
	wire			queue_full;
	wire			queue_empty;
	reg ack;

	assign next_wp     = wp + 1;
	assign queue_full  = (next_wp == rp);
	assign queue_empty = (rp == wp);

	assign ACK_O = ack;
	always @(posedge CLK_I) begin
		if(~RES_I) begin
			ack <= CYC_I & STB_I;
		end else begin
			ack <= 0;
		end
	end

	wire laqstat_addressed	= (ADR_I == `LAQSTAT) & ack & ~WE_I;
	wire laqdata_addressed  = (ADR_I == `LAQDATA) & ack & ~WE_I;
	wire laqpop_addressed   = (ADR_I == `LAQDATA) & ack & WE_I & ~queue_empty;
	wire [DBITS-1:0] laqstat_value	= {`DBITS'd0, queue_full, queue_empty};
	wire [DBITS-1:0] laqdata_value	= queue[rp];
	wire [QBITS-1:0] next_rp	= RES_I ? 0 : (laqpop_addressed ? rp+1 : rp);
	assign DAT_O =
		(laqstat_addressed ? laqstat_value : 0) |
		(laqdata_addressed ? laqdata_value : 0);

	always @(posedge CLK_I) begin
		rp <= next_rp;
	end

	always @(posedge CLK_I) begin
		if(~RES_I) begin
			if(GATE_I & ~queue_full) begin
				queue[wp] <= CHAN_I;
				wp <= next_wp;
			end
		end else begin
			wp <= 0;
		end
	end
endmodule
