`include "../rtl/setup.v"

module measure_core # ( parameter
	Int_ipv4_addr = {8'd10, 8'd0, 8'd21, 8'd105},
	Int_ipv6_addr = 128'h3776_0000_0000_0021_0000_0000_0000_0105,
	Int_mac_addr = 48'h003776_000101
) (
	input sys_rst,
	input sys_clk,
	input pci_clk,
	input sec_oneshot,
	input [31:0] global_counter,

	// XGMII interfaces for 4 MACs
	output [63:0] xgmii_txd,
	output xgmii_txc,
	input [63:0] xgmii_rxd,
	input xgmii_rxc,

	// PCI user registers
	output reg [31:0] rx_pps,
	output reg [31:0] rx_throughput,
	output reg [23:0] rx_latency,
	output reg [31:0] rx_ipv4_ip,

	// mode
	input tx_ipv6,

	output reg [31:0] count_2976_latency
);

reg [31:0] rx_pps1, rx_pps2;
reg [31:0] rx_throughput1, rx_throughput2;
reg [23:0] rx_latency1, rx_latency2;
reg [31:0] rx_ipv4_ip1, rx_ipv4_ip2;

always @(posedge pci_clk) begin
	rx_pps2 <= rx_pps1;
	rx_throughput2 <= rx_throughput1;
	rx_latency2 <= rx_latency1;
	rx_ipv4_ip2 <= rx_ipv4_ip1;
	rx_pps <= rx_pps2;
	rx_throughput <= rx_throughput2;
	rx_latency <= rx_latency2;
	rx_ipv4_ip <= rx_ipv4_ip2;
end


//-----------------------------------
// Recive logic
//-----------------------------------
reg [15:0] rx_count = 0;
reg [39:0] rx_magic;
reg [31:0] counter_start;
reg [31:0] counter_end;
reg [31:0] pps;
reg [31:0] throughput;
reg [15:0] rx_type;         // frame type
reg [47:0] rx_src_mac;
reg [31:0] rx_ipv4_srcip;
reg [15:0] rx_opcode;
reg [ 7:0] v6type;
reg arp_request;
reg neighbor_replay;
reg [47:0] tx_dst_mac;
reg [31:0] tx_ipv4_dstip;
reg [31:0] rx_arp_dst;

reg [11:0] count_2976;

always @(posedge sys_clk) begin
	if (sys_rst) begin
		rx_count <= 16'h0;
		rx_magic <= 40'b0;
		counter_start <= 32'h0;
		counter_end <= 32'h0;
		pps <= 32'h0;
		throughput <= 32'h0;
		rx_pps1 <= 32'h0;
		rx_throughput1 <= 32'h0;
		rx_ipv4_ip1 <= 32'h0;
		rx_type <= 16'h0;
		rx_opcode <= 16'h0;
		rx_src_mac <= 48'h0;
		rx_ipv4_srcip <= 32'h0;
		v6type <= 8'h0;
		arp_request <= 1'b0;
		neighbor_replay <= 1'b0;
		tx_dst_mac <= 48'h0;
		tx_ipv4_dstip <= 32'h0;
		rx_arp_dst <= 32'h0;
		count_2976 <= 12'h0;
		count_2976_latency <= 31'h0;
	end else begin
		if (count_2976 == 12'h0) begin
			count_2976_latency <= 32'h0;
		end else begin
			if (count_2976 != 12'd2976) begin
				count_2976_latency <= count_2976_latency + 32'h1;
			end
		end

		if (sec_oneshot == 1'b1) begin
			rx_pps1 <= pps;
			rx_throughput1 <= throughput;
			pps <= 32'h0;
			throughput <= 32'h0;
		end

		if (xgmii_rxc[7:0] != 8'hff) begin
			rx_count <= rx_count + 16'h8;
			case (rx_count)
			16'h00: if (sec_oneshot == 1'b0)
				pps <= pps + 32'h1;
			16'h08: {rx_src_mac[47:40] <= xgmii_rxd;// Ethernet hdr: Source MAC
			16'h07: rx_src_mac[39:32] <= xgmii_rxd;
			16'h08: rx_src_mac[31:24] <= xgmii_rxd;
			16'h09: rx_src_mac[23:16] <= xgmii_rxd;
			16'h0a: rx_src_mac[15: 8] <= xgmii_rxd;
			16'h0b: rx_src_mac[ 7: 0] <= xgmii_rxd;
			16'h0c: rx_type[15:8] <= xgmii_rxd;    // Type: IP=0800,ARP=0806
			16'h0d: rx_type[ 7:0] <= xgmii_rxd;
			16'h14: rx_opcode[15:8] <= xgmii_rxd;  // ARP: Operation (ARP reply: 0x0002)
			16'h15: rx_opcode[ 7:0] <= xgmii_rxd;  // Opcode ARP Request=1
			16'h1c: rx_ipv4_srcip[31:24] <= xgmii_rxd;  // ARP: Source IP address
			16'h1d: rx_ipv4_srcip[23:16] <= xgmii_rxd;
			16'h1e: begin
				rx_ipv4_srcip[15: 8] <= xgmii_rxd;
				rx_ipv4_ip1[31:24]   <= xgmii_rxd;
			end
			16'h1f: begin
				rx_ipv4_srcip[ 7: 0] <= xgmii_rxd;
				rx_ipv4_ip1[23:16] <= xgmii_rxd;
			end
			16'h20: rx_ipv4_ip1[15: 8] <= xgmii_rxd;
			16'h21: rx_ipv4_ip1[ 7: 0] <= xgmii_rxd;
			16'h26: rx_arp_dst[31:24]  <= xgmii_rxd; // target IP for ARP
			16'h27: rx_arp_dst[23:16]  <= xgmii_rxd;
			16'h28: rx_arp_dst[15: 8]  <= xgmii_rxd;
			16'h29: rx_arp_dst[ 7: 0]  <= xgmii_rxd;
			16'h2a: rx_magic[39:32] <= xgmii_rxd;
			16'h2b: rx_magic[31:24] <= xgmii_rxd;
			16'h2c: rx_magic[23:16] <= xgmii_rxd;
			16'h2d: rx_magic[15:8]  <= xgmii_rxd;
			16'h2e: rx_magic[7:0]   <= xgmii_rxd;
			16'h2f: counter_start[31:24] <= xgmii_rxd;
			16'h30: counter_start[23:16] <= xgmii_rxd;
			16'h31: counter_start[15:8]  <= xgmii_rxd;
			16'h32: counter_start[7:0]   <= xgmii_rxd;
			16'h33: begin
				if (rx_magic[39:0] == `MAGIC_CODE) begin
					rx_latency1 <= global_counter - counter_start;
					if (count_2976 != 12'd2976) begin
						count_2976 <= count_2976 + 12'd1;
					end
				end else if (rx_type == 16'h0806 && rx_opcode == 16'h1 && rx_arp_dst == Int_ipv4_addr) begin  // rx_magic[39:8] is Target IP Addres (ARP)
					tx_dst_mac    <= rx_src_mac;
					tx_ipv4_dstip <= rx_ipv4_srcip;
					arp_request <= 1'b1;
				end
			end
			16'h36: v6type            <= xgmii_rxd;
			16'h3e: rx_magic[39:32] <= xgmii_rxd;
			16'h3f: rx_magic[31:24] <= xgmii_rxd;
			16'h40: rx_magic[23:16] <= xgmii_rxd;
			16'h41: rx_magic[15:8]  <= xgmii_rxd;
			16'h42: rx_magic[7:0]   <= xgmii_rxd;
			16'h43: counter_start[31:24] <= xgmii_rxd;
			16'h44: counter_start[23:16] <= xgmii_rxd;
			16'h45: counter_start[15:8]  <= xgmii_rxd;
			16'h46: counter_start[7:0]   <= xgmii_rxd;
			16'h47: begin
				if (rx_magic[39:0] == `MAGIC_CODE) begin
					rx_latency1 <= global_counter - counter_start;
				end
			end
			// frame type=IPv6(0x86dd) && Next Header=ICMPv6(0x3a) && Type=Router Advertisement(134)
			16'h48:  if (rx_type == 16'h86dd && rx_opcode[15:8] == 8'h3a && v6type == 8'h86) begin
					tx_dst_mac <= rx_src_mac;
					neighbor_replay <= 1'b1;
				end
			endcase
		end else begin
			arp_request <= 1'b0;
			neighbor_replay <= 1'b0;
			if (rx_count != 16'h0 && sec_oneshot == 1'b0) begin
				throughput <= throughput + {16'h0, rx_count};
			end
			rx_count <= 16'h0;
		end
	end
end

//-----------------------------------
// ARP/ICMPv6 CRC
//-----------------------------------
reg [6:0] arp_count;
reg [6:0] neighbor_count;
reg [63:0] txd;
reg crc_init = 1'b0;
reg crc_rewrite = 1'b0;
assign crc_data_en = ~crc_init;
wire [31:0] crc_out, crc_out2;
assign crc_out2 = ~{ crc_out[24],crc_out[25],crc_out[26],crc_out[27],crc_out[28],crc_out[29],crc_out[30],crc_out[31], crc_out[16],crc_out[17],crc_out[18],crc_out[19],crc_out[20],crc_out[21],crc_out[22],crc_out[23], crc_out[ 8],crc_out[ 9],crc_out[10],crc_out[11],crc_out[12],crc_out[13],crc_out[14],crc_out[15], crc_out[ 0],crc_out[ 1],crc_out[ 2],crc_out[ 3],crc_out[ 4],crc_out[ 5],crc_out[ 6],crc_out[ 7] };

crc32_d64 crc32_d64_inst (
	.rst(crc_init),
	.clk(sys_clk),
	.crc_en(crc_data_en),
	.data_in({
txd[00],txd[01],txd[02],txd[03],txd[04],txd[05],txd[06],txd[07],txd[08],txd[09],
txd[10],txd[11],txd[12],txd[13],txd[14],txd[15],txd[16],txd[17],txd[18],txd[19],
txd[20],txd[21],txd[22],txd[23],txd[24],txd[25],txd[26],txd[27],txd[28],txd[29],
txd[30],txd[31],txd[32],txd[33],txd[34],txd[35],txd[36],txd[37],txd[38],txd[39],
txd[40],txd[41],txd[42],txd[43],txd[44],txd[45],txd[46],txd[47],txd[48],txd[49],
txd[50],txd[51],txd[52],txd[53],txd[54],txd[55],txd[56],txd[57],txd[58],txd[59],
txd[60],txd[61],txd[62],txd[63]
}),     // 64bit
  .crc_out(crc_out)     // 32bit
);

//-----------------------------------
// ARP/ICMPv6 logic
//-----------------------------------
wire [47:0] tx_src_mac    = Int_mac_addr;
wire [31:0] tx_ipv4_srcip = Int_ipv4_addr;
wire [127:0] tx_ipv6_srcip = Int_ipv6_addr;
reg txc;
reg [1:0] arp_state;
parameter ARP_IDLE = 2'h0;
parameter ARP_SEND = 2'h1;
parameter NEIGHBOR_SEND = 2'h2;

always @(posedge sys_clk) begin
	if (sys_rst) begin
		txd <= 8'h00;
		txc  <= 1'b0;
		arp_crc_rd  <= 1'b0;
		arp_count <= 7'h0;
		neighbor_count <= 7'h0;
		arp_state <= ARP_IDLE;
	end else begin
		case (arp_state)
		ARP_IDLE: begin
			if (tx_ipv6 == 1'b0 && arp_request == 1'b1) begin
				arp_count <= 7'h0;
				arp_state <= ARP_SEND;
			end else if (tx_ipv6 == 1'b1 && sec_oneshot == 1'b1) begin
				neighbor_count <= 7'h0;
				arp_state <= NEIGHBOR_SEND;
			end
		end
		ARP_SEND: begin
			case (arp_count)
			7'h00: begin
				txd <= 8'h55;
				txc <= 1'b1;
			end
			7'h01: txd <= 8'h55;     // preamble
			7'h02: txd <= 8'h55;
			7'h03: txd <= 8'h55;
			7'h04: txd <= 8'h55;
			7'h05: txd <= 8'h55;
			7'h06: txd <= 8'h55;
			7'h07: txd <= 8'hd5;     // preamble + SFD (0b1101_0101)
			7'h08: txd <= tx_dst_mac[47:40];   // Ethernet hdr: Destination MAC
			7'h09: txd <= tx_dst_mac[39:32];
			7'h0a: txd <= tx_dst_mac[31:24];
			7'h0b: txd <= tx_dst_mac[23:16];
			7'h0c: txd <= tx_dst_mac[15:8];
			7'h0d: txd <= tx_dst_mac[7:0];
			7'h0e: txd <= tx_src_mac[47:40];   // Ethernet hdr: Source MAC
			7'h0f: txd <= tx_src_mac[39:32];
			7'h10: txd <= tx_src_mac[31:24];
			7'h11: txd <= tx_src_mac[23:16];
			7'h12: txd <= tx_src_mac[15:8];
			7'h13: txd <= tx_src_mac[7:0];
			7'h14: txd <= 8'h08;     // Ethernet hdr: Protocol type: ARP
			7'h15: txd <= 8'h06;
			7'h16: txd <= 8'h00;     // ARP: Hardware type: Ethernet (1)
			7'h17: txd <= 8'h01;
			7'h18: txd <= 8'h08;     // ARP: Protocol type: IPv4 (0x0800)
			7'h19: txd <= 8'h00;
			7'h1a: txd <= 8'h06;     // ARP: MAC length
			7'h1b: txd <= 8'h04;     // ARP: IP address length
			7'h1c: txd <= 8'h00;     // ARP: Operation (ARP reply: 0x0002)
			7'h1d: txd <= 8'h02;
			7'h1e: txd <= tx_src_mac[47:40];   // ARP: Source MAC
			7'h1f: txd <= tx_src_mac[39:32];
			7'h20: txd <= tx_src_mac[31:24];
			7'h21: txd <= tx_src_mac[23:16];
			7'h22: txd <= tx_src_mac[15:8];
			7'h23: txd <= tx_src_mac[7:0];
			7'h24: txd <= tx_ipv4_srcip[31:24];  // ARP: Source IP address
			7'h25: txd <= tx_ipv4_srcip[23:16];
			7'h26: txd <= tx_ipv4_srcip[15:8];
			7'h27: txd <= tx_ipv4_srcip[7:0];
			7'h28: txd <= tx_dst_mac[47:40];   // ARP: Destination MAC
			7'h29: txd <= tx_dst_mac[39:32];
			7'h2a: txd <= tx_dst_mac[31:24];
			7'h2b: txd <= tx_dst_mac[23:16];
			7'h2c: txd <= tx_dst_mac[15:8];
			7'h2d: txd <= tx_dst_mac[7:0];
			7'h2e: txd <= tx_ipv4_dstip[31:24];  // ARP: Destination Address
			7'h2f: txd <= tx_ipv4_dstip[23:16];
			7'h30: txd <= tx_ipv4_dstip[15:8];
			7'h31: txd <= tx_ipv4_dstip[7:0];
			7'h32: txd <= 8'h00;     // Padding (frame size = 64 byte)
			7'h33: txd <= 8'h00;
			7'h34: txd <= 8'h00;
			7'h35: txd <= 8'h00;
			7'h36: txd <= 8'h00;
			7'h37: txd <= 8'h00;
			7'h38: txd <= 8'h00;
			7'h39: txd <= 8'h00;
			7'h3a: txd <= 8'h00;
			7'h3b: txd <= 8'h00;
			7'h3c: txd <= 8'h00;
			7'h3d: txd <= 8'h00;
			7'h3e: txd <= 8'h00;
			7'h3f: txd <= 8'h00;
			7'h40: txd <= 8'h00;
			7'h41: txd <= 8'h00;
			7'h42: txd <= 8'h00;
			7'h43: txd <= 8'h00;
			7'h44: begin         // FCS (CRC)
				arp_crc_rd  <= 1'b1;
				txd <= arp_crc_out[31:24];
	 		nd
			7'h45: txd <= arp_crc_out[23:16];
			7'h46: txd <= arp_crc_out[15:8];
			7'h47: txd <= arp_crc_out[7:0];
			7'h48: begin
				txc   <= 1'b0;
				arp_crc_rd  <= 1'b0;
				txd <= 8'h0;
				arp_state <= ARP_IDLE;
			end
			default: txd <= 8'h00;
			endcase
			arp_count <= arp_count + 7'h1;
		end
		NEIGHBOR_SEND: begin
			case (neighbor_count)
			7'h00: begin
				txd <= 8'h55;
				txc <= 1'b1;
			end
			7'h01: txd <= 8'h55;    // preamble
			7'h02: txd <= 8'h55;
			7'h03: txd <= 8'h55;
			7'h04: txd <= 8'h55;
			7'h05: txd <= 8'h55;
			7'h06: txd <= 8'h55;
			7'h07: txd <= 8'hd5;    // preamble + SFD (0b1101_0101)
			7'h08: txd <= 8'hff;  // Ethernet hdr: Destination MAC
			7'h09: txd <= 8'hff;
			7'h0a: txd <= 8'hff;
			7'h0b: txd <= 8'hff;
			7'h0c: txd <= 8'hff;
			7'h0d: txd <= 8'hff;
			7'h0e: txd <= tx_src_mac[47:40];  // Ethernet hdr: Source MAC
			7'h0f: txd <= tx_src_mac[39:32];
			7'h10: txd <= tx_src_mac[31:24];
			7'h11: txd <= tx_src_mac[23:16];
			7'h12: txd <= tx_src_mac[15:8];
			7'h13: txd <= tx_src_mac[7:0];
			7'h14: txd <= 8'h86;    // Ethernet hdr: Protocol type:IPv6
			7'h15: txd <= 8'hdd;
			7'h16: txd <= 8'h60;    // Version:6 Flowlabel: 0x00000
			7'h17: txd <= 8'h00;
			7'h18: txd <= 8'h00;
			7'h19: txd <= 8'h00;
			7'h1a: txd <= 8'h00;    // Payload Length: 8
			7'h1b: txd <= 8'h08;
			7'h1c: txd <= 8'h3a;    // Next header: ICMPv6 (0x3a)
			7'h1d: txd <= 8'hff;    // Hop limit: 255
			7'h1e: txd <= 8'hfe;                // Source IPv6
			7'h1f: txd <= 8'h80;
			7'h20: txd <= 8'h00;
			7'h21: txd <= 8'h00;
			7'h22: txd <= 8'h00;
			7'h23: txd <= 8'h00;
			7'h24: txd <= 8'h00;
			7'h25: txd <= 8'h00;
			7'h26: txd <= 8'h00;
			7'h27: txd <= 8'h00;
			7'h28: txd <= tx_src_mac[ 47: 40];
			7'h29: txd <= tx_src_mac[ 39: 32];
			7'h2a: txd <= tx_src_mac[ 31: 24];
			7'h2b: txd <= tx_src_mac[ 23: 16];
			7'h2c: txd <= tx_src_mac[ 15:  8];
			7'h2d: txd <= tx_src_mac[  7:  0];
			7'h2e: txd <= 8'hff;                // dest IPv6 (All routers address: ff02::2)
			7'h2f: txd <= 8'h02;
			7'h30: txd <= 8'h00;
			7'h31: txd <= 8'h00;
			7'h32: txd <= 8'h00;
			7'h33: txd <= 8'h00;
			7'h34: txd <= 8'h00;
			7'h35: txd <= 8'h00;
			7'h36: txd <= 8'h00;
			7'h37: txd <= 8'h00;
			7'h38: txd <= 8'h00;
			7'h39: txd <= 8'h00;
			7'h3a: txd <= 8'h00;
			7'h3b: txd <= 8'h00;
			7'h3c: txd <= 8'h00;
			7'h3d: txd <= 8'h02;
			7'h3e: txd <= 8'h85;    // Type: Router Solicitation (type: 133)
			7'h3f: txd <= 8'h00;    // Code: 0
			7'h40: txd <= 8'h00;    // Checksum
			7'h41: txd <= 8'h00;
			7'h42: txd <= 8'h00;    // Reserved
			7'h43: txd <= 8'h00;
			7'h44: txd <= 8'h00;
			7'h45: txd <= 8'h00;
			7'h46: begin         // FCS (CRC)
				arp_crc_rd  <= 1'b1;
				txd <= arp_crc_out[31:24];
			end
			7'h47: txd <= arp_crc_out[23:16];
			7'h48: txd <= arp_crc_out[15:8];
			7'h49: txd <= arp_crc_out[7:0];
			7'h4a: begin
				txc   <= 1'b0;
				arp_crc_rd  <= 1'b0;
				txd <= 8'h0;
				arp_state <= ARP_IDLE;
			end
			default: txd <= 8'h00;
			endcase
			neighbor_count <= neighbor_count + 7'h1;
		end
		endcase
	end
end

assign xgmii_txd = txd;
assign xgmii_txc = txc;

endmodule
