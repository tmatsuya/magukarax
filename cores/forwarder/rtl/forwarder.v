module forwarder # (
	parameter Port = 2'h0
) (
	input         sys_rst,
	input         sys_clk,
	// interface
	input [2:0]   port_num,
	// in FIFO
	input [71:0]  dout,
	input         empty,
	output reg    rd_en,
	// out FIFO
	output [71:0] port0_din,
	input         port0_full,
	input         port0_half,
	output reg    port0_wr_en,
	output [71:0] port1_din,
	input         port1_full,
	input         port1_half,
	output reg    port1_wr_en,
	output [71:0] port2_din,
	input         port2_full,
	input         port2_half,
	output reg    port2_wr_en,
	output [71:0] port3_din,
	input         port3_full,
	input         port3_half,
	output reg    port3_wr_en,
	output [71:0] port4_din,
	input         port4_full,
	input         port4_half,
	output reg    port4_wr_en,
	// lookup MAC learnning table
	output reg    req,
	output reg [47:0] src_mac,
	output reg [47:0] dest_mac,
	input         ack,
	input [4:0]   forward_port
);

reg [71:0]port_din;

//-----------------------------------
// Pipeline regsters
//-----------------------------------
reg [72:0] dout01, dout02, dout03, dout04, dout05, dout06, dout07,dout08, dout09, dout10;
reg [72:0] dout11, dout12;
reg [7:0] txd;
reg tx_en;
reg [11:0] counter, counter12;
reg [47:0] eth_dest;
reg [47:0] eth_src;
reg [15:0] eth_type;
reg [4:0] fwd_port, fwd2_port;
reg [4:0]  half_port;
reg in_frame;

assign is_dout_data = dout[71:64] != 8'hff;
assign is_dout12_data = dout12[71:64] != 8'hff;

always @(posedge sys_clk) begin
	if (sys_rst) begin
		counter <= 12'h0;
		counter12 <= 12'h0;
		eth_dest <= 48'h0;
		eth_src <= 48'h0;
		eth_type <= 16'h0;
		port_din <= 9'h0;
		rd_en <= 1'b0;
		dout01 <=74'h0;dout02 <=74'h0;dout03 <=74'h0;dout04 <=74'h0;dout05 <=74'h0;
		dout06 <=74'h0;dout07 <=74'h0;dout08 <=74'h0;dout09 <=74'h0;dout10 <=74'h0;
		dout11 <=74'h0;dout12 <=74'h0;
		req <= 1'b0;
		dest_mac <= 48'h0;
		src_mac <= 48'h0;
		fwd_port <= 5'h0;
		fwd2_port <= 5'h0;
		half_port <= 5'h0;
		rd_en <= 1'b0;
		in_frame <= 1'b0;
		port0_wr_en <= 1'b0;
		port1_wr_en <= 1'b0;
		port2_wr_en <= 1'b0;
		port3_wr_en <= 1'b0;
		port4_wr_en <= 1'b0;
	end else begin
              	rd_en  <= ~empty;
		req <= 1'b0;
		dest_mac <= 48'h0;
		src_mac <= 48'h0;
		port0_wr_en <= 1'b0;
		port1_wr_en <= 1'b0;
		port2_wr_en <= 1'b0;
		port3_wr_en <= 1'b0;
		port4_wr_en <= 1'b0;
		if (rd_en == 1'b1 || in_frame == 1'b1) begin
			dout01<={rd_en,dout};dout02<=dout01;dout03<=dout02;dout04<=dout03;dout05<=dout04;
			dout06<=dout05;dout07<=dout06;dout08<=dout07;dout09<=dout08;dout10<=dout09;
			dout11<=dout10;dout12<=dout11;
			if (rd_en == 1'b1) begin
				counter <= counter + 12'h1;
				if (is_dout_data == 1'b1) begin
					case (counter)
						12'h00: ;  // Preamble
						12'h01: {eth_src[15:0], eth_dest[47:00]} <= dout[63:0];
						12'h02: begin
							{eth_type[15:0], eth_src[47:16]} <= dout[47:0];
							req <= 1'b1;
							dest_mac <= eth_dest;
							src_mac  <= eth_src;
							fwd_port <= 5'b11111;
						end
					endcase
					if (ack == 1'b1 && forward_port != 5'b00000) begin
// packet filter rules are here (forwarding, reject) ipv4_protocol, ipv4_src_ip, ipv4_dest_ip, ipv4_src_ip, ipv4_src_port, ipv4_dest_port
//						if (ipv4_ttl != 8'h0)
							fwd_port <= forward_port;
					end
				end else begin
					counter <= 12'h0;
				end
			end
			if (dout12[72] == 1'b1) begin
				in_frame <= is_dout12_data;
				if (is_dout12_data == 1'b1)
					counter12 <= counter12 + 12'h1;
				else
					counter12 <= 12'h0;
				if (is_dout12_data == 1'b1) begin
					case (counter12)
						12'h00: begin
							port_din <= dout12[71:0];
							fwd2_port <= fwd_port;
							half_port <= {port4_half, port3_half, port2_half, port1_half, port0_half};
							port0_wr_en <= fwd_port[0] & ~port0_half;
							port1_wr_en <= fwd_port[1] & ~port1_half;
							port2_wr_en <= fwd_port[2] & ~port2_half;
							port3_wr_en <= fwd_port[3] & ~port3_half;
							port4_wr_en <= fwd_port[4] & ~port4_half;
						end
						default: begin
							port_din <= dout12[71:0];
						end
					endcase
				end else begin
					port_din <= 72'h0;
				end
				port0_wr_en <= fwd2_port[0] & ~half_port[0];
				port1_wr_en <= fwd2_port[1] & ~half_port[1];
				port2_wr_en <= fwd2_port[2] & ~half_port[2];
				port3_wr_en <= fwd2_port[3] & ~half_port[3];
				port4_wr_en <= fwd2_port[4] & ~half_port[4];
			end
		end
	end
end

assign port0_din = port_din;
assign port1_din = port_din;
assign port2_din = port_din;
assign port3_din = port_din;
assign port4_din = port_din;

endmodule
