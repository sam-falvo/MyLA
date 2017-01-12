`timescale 1 ns / 1 ps


`include "myla.vh"


module TEST_MYLA;
	parameter DBITS = `DBITS;
	parameter QBITS = `QBITS;

	// To test the MYLA, we need a Wishbone bus.
	reg 			CLK_O;
	reg 			RES_O;

	// The MYLA will communicate with the microprocessor through
	// a typical memory bus interface.
	reg			ADR_O;
	reg			WE_O;
	reg			CYC_O;
	reg			STB_O;
	wire			ACK_I;
	wire	[DBITS-1:0]	DAT_I;

	// The MYLA must also accept stimuli from input channels.
	reg	[DBITS-1:0]	CHAN_O;
	reg			GATE_O;

	// This register is used to identify a specific test in progress.
	// This eases correspondence between waveform traces and their
	// corresponding (successful) tests.
	reg	[15:0]		STORY_O;

	// The MYLA under test.
	MYLA #(
		.DBITS(DBITS),
		.QBITS(QBITS)
	) myla(
		.CLK_I(CLK_O),
		.RES_I(RES_O),
		.ADR_I(ADR_O),
		.WE_I(WE_O),
		.CYC_I(CYC_O),
		.STB_I(STB_O),
		.ACK_O(ACK_I),
		.DAT_O(DAT_I),
		
		.CHAN_I(CHAN_O),
		.GATE_I(GATE_O)
	);

	always begin
		#50 CLK_O <= ~CLK_O;
	end

	task push_data;
	input [DBITS-1:0] data;
	begin
		CHAN_O <= data;
		GATE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
	end
	endtask

	task check_data;
	input [DBITS-1:0] expected;
	input [DBITS-1:0] status_expected;
	begin
		ADR_O <= `LAQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I !== expected) begin
			$display("Pattern mismatch on byte %d.", expected); $stop;
		end

		ADR_O <= `LAQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `LAQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I !== status_expected) begin
			$display("Unexpected status $%04X; did we read beyond end of queue?", DAT_I); $stop;
		end
	end
	endtask
	
	initial begin
		$dumpfile("wtf.vcd");
		$dumpvars;

		RES_O <= 0;
		CLK_O <= 0;
		ADR_O <= `LAQSTAT;
		WE_O <= 0;
		CYC_O <= 0;
		STB_O <= 0;
		CHAN_O <= 0;
		GATE_O <= 0;
		wait(CLK_O);
		wait(~CLK_O);

		// AS A systems programmer
		// I WANT the MYLA to report an empty queue after reset
		// SO THAT I can start the operating system with a clean slate.

		STORY_O <= 0;
		RES_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `LAQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'h01) begin
			$display("Expected queue to be empty."); $stop;
		end

		// AS A systems programmer
		// I WANT the MYLA to report a non-empty queue after receiving a keycode
		// SO THAT I can pull the key code from the queue.

		STORY_O <= 16'h0010;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		push_data(5);
		ADR_O <= `LAQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		GATE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'h00) begin
			$display("Expected queue to be neither full nor empty."); $stop;
		end

		// AS A systems programmer
		// I WANT the keyboard queue to faithfully record the received scan code
		// SO THAT I can respond intelligently to user input.

		STORY_O <= 16'h0020;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		push_data(5);
		ADR_O <= `LAQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		GATE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != `DBITS'd5) begin
			$display("Head of the queue doesn't have the right data byte."); $stop;
		end

		// AS A systems programmer
		// I WANT the queue to capture multiple data bytes while I'm busy
		// SO THAT I don't have to have such stringent real-time requirements.

		STORY_O <= 16'h0030;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		push_data(1);
		push_data(2);
		GATE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `LAQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != `DBITS'd1) begin
			$display("Expected 1 for first entry."); $stop;
		end
		ADR_O <= `LAQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `LAQDATA;
		WE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != `DBITS'd2) begin
			$display("Expected 2 for second byte."); $stop;
		end

		// AS A verilog engineer
		// I WANT the MYLA to drop excess samples when the queue is full
		// SO THAT software engineers don't have to worry about overrun issues.

		STORY_O <= 16'h0040;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		push_data(0);
		push_data(1);
		push_data(2);
		push_data(3);
		push_data(4);
		push_data(5);
		push_data(6);
		push_data(7);
		push_data(8);
		push_data(9);
		push_data(10);
		push_data(11);
		push_data(12);
		push_data(13);
		push_data(14);
		push_data(15);
		push_data(16);
		GATE_O <= 0;

		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `LAQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != `LAQSF_FULL) begin
			$display("Before popping first byte, queue must be full."); $stop;
		end

		check_data(0, 0);
		check_data(1, 0); STORY_O <= 16'h0140;
		check_data(2, 0); STORY_O <= 16'h0240;
		check_data(3, 0); STORY_O <= 16'h0340;
		check_data(4, 0); STORY_O <= 16'h0440;
		check_data(5, 0); STORY_O <= 16'h0540;
		check_data(6, 0); STORY_O <= 16'h0640;
		check_data(7, 0); STORY_O <= 16'h0740;
		check_data(8, 0); STORY_O <= 16'h0840;
		check_data(9, 0); STORY_O <= 16'h0940;
		check_data(10, 0); STORY_O <= 16'h0A40;
		check_data(11, 0); STORY_O <= 16'h0B40;
		check_data(12, 0); STORY_O <= 16'h0C40;
		check_data(13, 0); STORY_O <= 16'h0D40;
		check_data(14, `LAQSF_EMPTY);

		STORY_O <= -1;
		wait(CLK_O); wait(~CLK_O);
		$stop;
	end
endmodule
