`define SIMULATION
module tb_forwarder();

/* 125MHz system clock */
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

/* 33MHz PCI clock */
reg pci_clk;
initial pci_clk = 1'b0;
always #30 pci_clk = ~pci_clk;

/* 62.5MHz CPCI clock */
reg cpci_clk;
initial cpci_clk = 1'b0;
always #16 cpci_clk = ~cpci_clk;

/* 125MHz RX clock */
reg phy_rx_clk;
initial phy_rx_clk = 1'b0;
always #8 phy_rx_clk = ~phy_rx_clk;

/* 125MHz TX clock */
reg phy_tx_clk;
initial phy_tx_clk = 1'b0;
always #8 phy_tx_clk = ~phy_tx_clk;


reg sys_rst;

wire req;
wire ack;
wire [47:0] src_mac, dest_mac;
wire [4:0] forward_port;

/*
lookupfib # (
	.MaxPort(4'h1)
) lookupfib_tb (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.int_0_mac_addr(48'h00a0de1c07e2),
	.int_1_mac_addr(48'h00a0de1c07e8),
	.int_2_mac_addr(),
	.int_3_mac_addr(),

	.req(req),

	.ack(ack),
	.src_mac(src_mac),
	.dest_mac(dest_mac),
	.forward_port(forward_port)
);
*/

reg [71:0] dout;
reg empty;
wire rd_en;
wire [71:0] port0_din, port1_din, port2_din, port3_din, port4_din;
reg port0_full, port1_full, port2_full, port3_full, port4_full;
reg port0_half, port1_half, port2_half, port3_half, port4_half;
wire port0_wr_en, port1_wr_en, port2_wr_en, port3_wr_en, port4_wr_en;

forwarder # (
	.Port(2'h0)
//	.MaxPort(2'h1)
) forwarder_tb (
	.sys_rst(sys_rst),
	.sys_clk(sys_clk),

	.dout(dout),
	.empty(empty),
	.rd_en(rd_en),

	.port0_din(port0_din),
	.port0_full(port0_full),
	.port0_half(port0_half),
	.port0_wr_en(port0_wr_en),

	.port1_din(port1_din),
	.port1_full(port1_full),
	.port1_half(port1_half),
	.port1_wr_en(port1_wr_en),

	.port2_din(port2_din),
	.port2_full(port2_full),
	.port2_half(port2_half),
	.port2_wr_en(port2_wr_en),

	.port3_din(port3_din),
	.port3_full(port3_full),
	.port3_half(port3_half),
	.port3_wr_en(port3_wr_en),

	.port4_din(port4_din),
	.port4_full(port4_full),
	.port4_half(port4_half),
	.port4_wr_en(port4_wr_en),

	.req(req),
	.src_mac(src_mac),
	.dest_mac(dest_mac),
	.ack(ack),
	.forward_port(forward_port)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

always @(posedge sys_clk) begin
	if (rd_en == 1'b1)
		$display("empty: %x dout: %x", empty, dout);
end

reg [11:0] counter;
reg [71:0] rom [0:511];

always #1 begin
	dout <= rom[ counter ];
	empty <= 1'b0;
end

always @(posedge phy_tx_clk) begin
	if (rd_en == 1'b1)
		counter <= counter + 1;
end

initial begin
        $dumpfile("./test.vcd");
	$dumpvars(0, tb_forwarder);
	$readmemh("./phy_test.hex", rom);
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;
	counter = 0;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;


	#10000;

	$finish;
end

endmodule
