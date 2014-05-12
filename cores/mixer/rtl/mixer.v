module mixer # (
	parameter FrameEndSize = 4'h4
) (
	input         sys_rst,
	input         sys_clk,
	// in FIFO
	input [71:0]  port0_dout,
	input         port0_empty,
	output reg    port0_rd_en,
	input [71:0]  port1_dout,
	input         port1_empty,
	output reg    port1_rd_en,
	input [71:0]  port2_dout,
	input         port2_empty,
	output reg    port2_rd_en,
	input [71:0]  port3_dout,
	input         port3_empty,
	output reg    port3_rd_en,
	input [71:0]  port4_dout,
	input         port4_empty,
	output reg    port4_rd_en,
	// out FIFO
	output reg [71:0] din,
	input         full,
	output reg    wr_en
);

reg [71:0] xmixq_din;
reg txmixq_wr_en;
wire txmixq_full;
wire [71:0] xmixq_dout;
wire txmixq_empty;
reg txmixq_rd_en;
wire [11:0] txmixq_data_count;

//-----------------------------------
// TX_MIXERQ FIFO
//-----------------------------------
`ifdef SIMULATION
sfifo # (
	.DATA_WIDTH(72),
	.ADDR_WIDTH(12)
) tx0_mixq (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(txmixq_din),
	.full(txmixq_full),
	.wr_cs(txmixq_wr_en),
	.wr_en(txmixq_wr_en),

	.dout(txmixq_dout),
	.empty(txmixq_empty),
	.rd_cs(txmixq_rd_en),
	.rd_en(txmixq_rd_en),

	.data_count(txmixq_data_count)
);
`else
sfifo72_12 tx0_mixq (
	.clk(sys_clk),
	.rst(sys_rst),

	.din(txmixq_din),
	.full(txmixq_full),
	.wr_en(txmixq_wr_en),

	.dout(txmixq_dout),
	.empty(txmixq_empty),
	.rd_en(txmixq_rd_en),

	.data_count(txmixq_data_count)
);
`endif

wire txmixq_half = txmixq_data_count[11];

reg [2:0] mixer_state;
reg find_frame_data;
reg [3:0] find_frame_end;
parameter STATE_IDLE  = 3'h0;
parameter STATE_PORT0 = 3'h1;
parameter STATE_PORT1 = 3'h2;
parameter STATE_PORT2 = 3'h3;
parameter STATE_PORT3 = 3'h4;
parameter STATE_PORT4 = 3'h5;

//-----------------------------------
// Check multi pot FIFOs
//-----------------------------------
always @(posedge sys_clk) begin
	if (sys_rst) begin
		find_frame_data <= 1'b0;
		find_frame_end <= 4'h0;
		mixer_state <= STATE_IDLE;
		port0_rd_en <= 1'b0;
		port1_rd_en <= 1'b0;
		port2_rd_en <= 1'b0;
		port3_rd_en <= 1'b0;
		port4_rd_en <= 1'b0;
		txmixq_wr_en <= 1'b0;
	end else begin
		port0_rd_en <= 1'b0;
		port1_rd_en <= 1'b0;
		port2_rd_en <= 1'b0;
		port3_rd_en <= 1'b0;
		port4_rd_en <= 1'b0;
		txmixq_wr_en <= 1'b0;
		case (mixer_state)
			STATE_IDLE: begin
				find_frame_data <= 1'b0;
				find_frame_end <= 4'h0;
				if (port0_empty == 1'b0) begin
					port0_rd_en <= 1'b1;
					mixer_state <= STATE_PORT0;
				end else if (port1_empty == 1'b0) begin
					port1_rd_en <= 1'b1;
					mixer_state <= STATE_PORT1;
				end else if (port2_empty == 1'b0) begin
					port2_rd_en <= 1'b1;
					mixer_state <= STATE_PORT2;
				end else if (port3_empty == 1'b0) begin
					port3_rd_en <= 1'b1;
					mixer_state <= STATE_PORT3;
				end else if (port4_empty == 1'b0) begin
					port4_rd_en <= 1'b1;
					mixer_state <= STATE_PORT4;
				end
			end
			STATE_PORT0: begin
				if (port0_rd_en == 1'b1) begin
					txmixq_din <= port0_dout[8:0];
					txmixq_wr_en <= 1'b1;
					if (port0_dout[8] == 1'b1)
						find_frame_data <= 1'b1;
					else if (find_frame_data == 1'b1)
						find_frame_end <= find_frame_end + 4'h1;
				end
				if (port0_empty == 1'b0)
					port0_rd_en <= 1'b1;
				if (find_frame_end == FrameEndSize || port0_empty == 1'b1)
					if (port1_empty == 1'b0) begin
						port1_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT1;
					end else if (port2_empty == 1'b0) begin
						port2_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT2;
					end else if (port3_empty == 1'b0) begin
						port3_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT3;
					end else if (port4_empty == 1'b0) begin
						port4_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT4;
					end else
						mixer_state <= STATE_IDLE;
			end
			STATE_PORT1: begin
				if (port1_rd_en == 1'b1) begin
					txmixq_din <= port1_dout[8:0];
					txmixq_wr_en <= 1'b1;
					if (port1_dout[8] == 1'b1)
						find_frame_data <= 1'b1;
					else if (find_frame_data == 1'b1)
						find_frame_end <= find_frame_end + 4'h1;
				end
				if (port1_empty == 1'b0)
					port1_rd_en <= 1'b1;
				if (find_frame_end == FrameEndSize || port1_empty == 1'b1)
					if (port2_empty == 1'b0) begin
						port2_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT2;
					end else if (port3_empty == 1'b0) begin
						port3_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT3;
					end else if (port4_empty == 1'b0) begin
						port4_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT4;
					end else if (port0_empty == 1'b0) begin
						port0_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT0;
					end else
						mixer_state <= STATE_IDLE;
			end
			STATE_PORT2: begin
				if (port2_rd_en == 1'b1) begin
					txmixq_din <= port2_dout[8:0];
					txmixq_wr_en <= 1'b1;
					if (port2_dout[8] == 1'b1)
						find_frame_data <= 1'b1;
					else if (find_frame_data == 1'b1)
						find_frame_end <= find_frame_end + 4'h1;
				end
				if (port2_empty == 1'b0)
					port2_rd_en <= 1'b1;
				if (find_frame_end == FrameEndSize || port2_empty == 1'b1)
					if (port3_empty == 1'b0) begin
						port3_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT3;
					end else if (port4_empty == 1'b0) begin
						port4_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT4;
					end else if (port0_empty == 1'b0) begin
						port0_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT0;
					end else if (port1_empty == 1'b0) begin
						port1_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT1;
					end else
						mixer_state <= STATE_IDLE;
			end
			STATE_PORT3: begin
				if (port3_rd_en == 1'b1) begin
					txmixq_din <= port3_dout[8:0];
					txmixq_wr_en <= 1'b1;
					if (port3_dout[8] == 1'b1)
						find_frame_data <= 1'b1;
					else if (find_frame_data == 1'b1)
						find_frame_end <= find_frame_end + 4'h1;
				end
				if (port3_empty == 1'b0)
					port3_rd_en <= 1'b1;
				if (find_frame_end == FrameEndSize || port3_empty == 1'b1)
					if (port4_empty == 1'b0) begin
						port4_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT4;
					end else if (port0_empty == 1'b0) begin
						port0_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT0;
					end else if (port1_empty == 1'b0) begin
						port1_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT1;
					end else if (port2_empty == 1'b0) begin
						port2_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT2;
					end else
						mixer_state <= STATE_IDLE;
			end
			STATE_PORT4: begin
				if (port4_rd_en == 1'b1) begin
					txmixq_din <= port4_dout[8:0];
					txmixq_wr_en <= 1'b1;
					if (port4_dout[8] == 1'b1)
						find_frame_data <= 1'b1;
					else if (find_frame_data == 1'b1)
						find_frame_end <= find_frame_end + 4'h1;
				end
				if (port4_empty == 1'b0)
					port4_rd_en <= 1'b1;
				if (find_frame_end == FrameEndSize || port4_empty == 1'b1)
					if (port0_empty == 1'b0) begin
						port0_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT0;
					end else if (port1_empty == 1'b0) begin
						port1_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT1;
					end else if (port2_empty == 1'b0) begin
						port2_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT2;
					end else if (port3_empty == 1'b0) begin
						port3_rd_en <= 1'b1;
						find_frame_data <= 1'b0;
						find_frame_end <= 4'h0;
						mixer_state <= STATE_PORT3;
					end else
						mixer_state <= STATE_IDLE;
			end
		endcase
	end
end

//-----------------------------------
// Distribute to multi port FIFO
//-----------------------------------
always @(posedge sys_clk) begin
	if (sys_rst) begin
       		txmixq_rd_en <= 1'b0;
		wr_en <= 1'b0;
	end else begin
		txmixq_rd_en <= ~txmixq_empty;
		wr_en <= 1'b0;
		if (txmixq_rd_en == 1'b1) begin
			din <= txmixq_dout[8:0];
			wr_en <= 1'b1;
		end
	end
end

endmodule

