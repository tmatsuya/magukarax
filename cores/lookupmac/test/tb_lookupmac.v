module tb_lookupfib();

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
reg req;
reg [31:0] search_ip;
wire ack;
wire [31:0] dest_ip;
wire [47:0] src_mac, dest_mac;
wire [3:0] forward_port;

lookupfib # (
        .MaxPort(4'h3)
) lookupfib_tb (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),

        .int_0_mac_addr(48'h00a0de1c07e2),
        .int_1_mac_addr(48'h00a0de1c07e8),
        .int_2_mac_addr(),
        .int_3_mac_addr(),

	.req(req),
	.search_ip(search_ip),

	.ack(ack),
	.dest_ip(dest_ip),
	.src_mac(src_mac),
	.dest_mac(dest_mac),
	.forward_port(forward_port)
);

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

always @(posedge sys_clk) begin
	if (ack == 1'b1)
		$display("dest_ip:%d.%d.%d.%d  src_mac:%x  dest_mac:%x  forward_port:%b",  dest_ip[31:24], dest_ip[23:16], dest_ip[15:8], dest_ip[7:0], src_mac, dest_mac, forward_port);
end

initial begin
        $dumpfile("./test.vcd");
	$dumpvars(0, tb_lookupfib); 
	/* Reset / Initialize our logic */
	sys_rst = 1'b1;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd20, 8'd10};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd20, 8'd105};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd20, 8'd106};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd21, 8'd105};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd22, 8'd105};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	req = 1'b1;
	search_ip = {8'd10, 8'd0, 8'd23, 8'd105};
	waitclock;
	req = 1'b0;
	search_ip = 32'h0;
	waitclock;
	waitclock;
	waitclock;

	waitclock;
	waitclock;
	waitclock;

	#300;

	$finish;
end

endmodule
