`include "../rtl/setup.v"
`timescale 1ns / 1ps

module top # (
	parameter PL_FAST_TRAIN       = "FALSE", // Simulation Speedup
	parameter PCIE_EXT_CLK        = "TRUE",    // Use External Clocking Module
	parameter PCIE_EXT_GT_COMMON  = "FALSE",
	parameter REF_CLK_FREQ        = 0,     // 0 - 100 MHz, 1 - 125 MHz, 2 - 250 MHz
	parameter C_DATA_WIDTH        = 64, // RX/TX interface data width
	parameter KEEP_WIDTH          = C_DATA_WIDTH / 8 // TSTRB width
) (
`ifdef ENABLE_XGMII01
	input xphy0_refclk_p, 
	input xphy0_refclk_n, 
`endif
	output [4:0] sfp_tx_disable, 
	output [3:0] sfp_tx_fault, 
`ifdef ENABLE_XGMII01
	output xphy0_txp, 
	output xphy0_txn, 
	input xphy0_rxp, 
	input xphy0_rxn,
	output xphy1_txp, 
	output xphy1_txn, 
	input xphy1_rxp, 
	input xphy1_rxn,
`endif
`ifdef ENABLE_XGMII23
	output xphy2_txp, 
	output xphy2_txn, 
	input xphy2_rxp, 
	input xphy2_rxn,
	output xphy3_txp, 
	output xphy3_txn, 
	input xphy3_rxp, 
	input xphy3_rxn,
`endif
`ifdef ENABLE_XGMII4
	input xphy4_refclk_p, 
	input xphy4_refclk_n, 
	output xphy4_txp, 
	output xphy4_txn, 
	input xphy4_rxp, 
	input xphy4_rxn,
`endif
`ifdef ENABLE_PCIE
	// PCI Express
	input sys_clk_p,
	input sys_clk_n,
	input sys_rst_n,
	output [3:0] pci_exp_txp,
	output [3:0] pci_exp_txn,
	input [3:0] pci_exp_rxp,
	input [3:0] pci_exp_rxn,
`endif
	output fmc_ok_led,
	input [1:0] fmc_gbtclk0_fsel,
	output fmc_clk_312_5,
	// BUTTON
	input button_n,
	input button_s,
	input button_w,
	input button_e,
	input button_c,
	// DIP SW
	input [3:0] dipsw,
	// Diagnostic LEDs
	output [7:0] led           
);

// Clock and Reset
wire sys_rst;
assign sys_rst = button_c; // 1'b0;
 
// -------------------
// -- Local Signals --
// -------------------

// Xilinx Hard Core Instantiation

wire		clk156;
`ifdef ENABLE_PCIE
wire		user_clk;
wire		user_reset;
`endif

wire [63:0]	xgmii0_txd, xgmii1_txd, xgmii2_txd, xgmii3_txd, xgmii4_txd;
wire [7:0]	xgmii0_txc, xgmii1_txc, xgmii2_txc, xgmii3_txc, xgmii4_txc;
wire [63:0]	xgmii0_rxd, xgmii1_rxd, xgmii2_rxd, xgmii3_rxd, xgmii4_rxd;
wire [7:0]	xgmii0_rxc, xgmii1_rxc, xgmii2_rxc, xgmii3_rxc, xgmii4_rxc;
  
wire [7:0]	xphy0_status, xphy1_status, xphy2_status, xphy3_status, xphy4_status;
  

wire		nw0_reset, nw1_reset, nw2_reset, nw3_reset, nw4_reset;
wire		txusrclk;
wire		txusrclk2;
wire		txclk322;
wire		areset_refclk_bufh;
wire		areset_clk156;
wire		mmcm_locked_clk156;
wire		gttxreset_txusrclk2;
wire		gttxreset;
wire		gtrxreset;
wire		txuserrdy;
wire		qplllock;
wire		qplloutclk;
wire		qplloutrefclk;
wire		qplloutclk1;
wire		qplloutclk2;
wire		qplloutrefclk1;
wire		qplloutrefclk2;
wire		reset_counter_done; 
wire		nw0_reset_i, nw1_reset_i, nw2_reset_i, nw3_reset_i, nw4_reset_i;
wire		xphy0_tx_resetdone, xphy1_tx_resetdone, xphy2_tx_resetdone, xphy3_tx_resetdone, xphy4_tx_resetdone;


  
//- Network Path signal declarations
wire [4:0]	xphy0_prtad;
wire		xphy0_signal_detect;
wire [4:0]	xphy1_prtad;
wire		xphy1_signal_detect;
wire [4:0]	xphy2_prtad;
wire		xphy2_signal_detect;
wire [4:0]	xphy3_prtad;
wire		xphy3_signal_detect;
wire [4:0]	xphy4_prtad;
wire		xphy4_signal_detect;
  

wire		xphyrefclk_i;    
wire		dclk_i;                     

wire		gt0_pma_resetout_i;
wire		gt0_pcs_resetout_i;         
wire		gt0_drpen_i;                
wire		gt0_drpwe_i;                
wire [15:0]	gt0_drpaddr_i;              
wire [15:0]	gt0_drpdi_i;                
wire [15:0]	gt0_drpdo_i;                
wire		gt0_drprdy_i;               
wire		gt0_resetdone_i;            
wire [31:0]	gt0_txd_i;                  
wire [7:0]	gt0_txc_i;                  
wire [31:0]	gt0_rxd_i;                  
wire [7:0]	gt0_rxc_i;                  
wire [2:0]	gt0_loopback_i;             
wire		gt0_txclk322_i;             
wire		gt0_rxclk322_i;             

wire		gt1_pma_resetout_i;
wire		gt1_pcs_resetout_i;         
wire		gt1_drpen_i;                
wire		gt1_drpwe_i;                
wire [15:0]	gt1_drpaddr_i;              
wire [15:0]	gt1_drpdi_i;                
wire [15:0]	gt1_drpdo_i;                
wire		gt1_drprdy_i;               
wire		gt1_resetdone_i;            
wire [31:0]	gt1_txd_i;                  
wire [7:0]	gt1_txc_i;                  
wire [31:0]	gt1_rxd_i;                  
wire [7:0]	gt1_rxc_i;                  
wire [2:0]	gt1_loopback_i;             
wire		gt1_txclk322_i;             
wire		gt1_rxclk322_i;             

wire		gt2_pma_resetout_i;
wire		gt2_pcs_resetout_i;         
wire		gt2_drpen_i;                
wire		gt2_drpwe_i;                
wire [15:0]	gt2_drpaddr_i;              
wire [15:0]	gt2_drpdi_i;                
wire [15:0]	gt2_drpdo_i;                
wire		gt2_drprdy_i;               
wire		gt2_resetdone_i;            
wire [31:0]	gt2_txd_i;                  
wire [7:0]	gt2_txc_i;                  
wire [31:0]	gt2_rxd_i;                  
wire [7:0]	gt2_rxc_i;                  
wire [2:0]	gt2_loopback_i;             
wire		gt2_txclk322_i;             
wire		gt2_rxclk322_i;             

wire		gt3_pma_resetout_i;
wire		gt3_pcs_resetout_i;         
wire		gt3_drpen_i;                
wire		gt3_drpwe_i;                
wire [15:0]	gt3_drpaddr_i;              
wire [15:0]	gt3_drpdi_i;                
wire [15:0]	gt3_drpdo_i;                
wire		gt3_drprdy_i;               
wire		gt3_resetdone_i;            
wire [31:0]	gt3_txd_i;                  
wire [7:0]	gt3_txc_i;                  
wire [31:0]	gt3_rxd_i;                  
wire [7:0]	gt3_rxc_i;                  
wire [2:0]	gt3_loopback_i;             
wire		gt3_txclk322_i;             
wire		gt3_rxclk322_i;             

wire		gt4_pma_resetout_i;
wire		gt4_pcs_resetout_i;         
wire		gt4_drpen_i;                
wire		gt4_drpwe_i;                
wire [15:0]	gt4_drpaddr_i;              
wire [15:0]	gt4_drpdi_i;                
wire [15:0]	gt4_drpdo_i;                
wire		gt4_drprdy_i;               
wire		gt4_resetdone_i;            
wire [31:0]	gt4_txd_i;                  
wire [7:0]	gt4_txc_i;                  
wire [31:0]	gt4_rxd_i;                  
wire [7:0]	gt4_rxc_i;                  
wire [2:0]	gt4_loopback_i;             
wire		gt4_txclk322_i;             
wire		gt4_rxclk322_i;             
  
// ---------------
// Clock and Reset
// ---------------

wire		gt0_pma_resetout;
wire		gt0_pcs_resetout;
wire		gt0_drpen;
wire		gt0_drpwe;
wire [15:0]	gt0_drpaddr;
wire [15:0]	gt0_drpdi;
wire [15:0]	gt0_drpdo;
wire		gt0_drprdy;
wire		gt0_resetdone;
wire [63:0]	gt0_txd;
wire [7:0]	gt0_txc;
wire [63:0]	gt0_rxd;
wire [7:0]	gt0_rxc;
wire [2:0]	gt0_loopback;

wire		gt1_pma_resetout;
wire		gt1_pcs_resetout;
wire		gt1_drpen;
wire		gt1_drpwe;
wire [15:0]	gt1_drpaddr;
wire [15:0]	gt1_drpdi;
wire [15:0]	gt1_drpdo;
wire		gt1_drprdy;
wire		gt1_resetdone;
wire [63:0]	gt1_txd;
wire [7:0]	gt1_txc;
wire [63:0]	gt1_rxd;
wire [7:0]	gt1_rxc;
wire [2:0]	gt1_loopback;

wire		gt2_pma_resetout;
wire		gt2_pcs_resetout;
wire		gt2_drpen;
wire		gt2_drpwe;
wire [15:0]	gt2_drpaddr;
wire [15:0]	gt2_drpdi;
wire [15:0]	gt2_drpdo;
wire		gt2_drprdy;
wire		gt2_resetdone;
wire [63:0]	gt2_txd;
wire [7:0]	gt2_txc;
wire [63:0]	gt2_rxd;
wire [7:0]	gt2_rxc;
wire [2:0]	gt2_loopback;

wire		gt3_pma_resetout;
wire		gt3_pcs_resetout;
wire		gt3_drpen;
wire		gt3_drpwe;
wire [15:0]	gt3_drpaddr;
wire [15:0]	gt3_drpdi;
wire [15:0]	gt3_drpdo;
wire		gt3_drprdy;
wire		gt3_resetdone;
wire [63:0]	gt3_txd;
wire [7:0]	gt3_txc;
wire [63:0]	gt3_rxd;
wire [7:0]	gt3_rxc;
wire [2:0]	gt3_loopback;

wire		gt4_pma_resetout;
wire		gt4_pcs_resetout;
wire		gt4_drpen;
wire		gt4_drpwe;
wire [15:0]	gt4_drpaddr;
wire [15:0]	gt4_drpdi;
wire [15:0]	gt4_drpdo;
wire		gt4_drprdy;
wire		gt4_resetdone;
wire [63:0]	gt4_txd;
wire [7:0]	gt4_txc;
wire [63:0]	gt4_rxd;
wire [7:0]	gt4_rxc;
wire [2:0]	gt4_loopback;

`ifdef ENABLE_XGMII01
// ---------------
// GT0 instance
// ---------------
 
assign xphy0_prtad = 5'd0;
assign xphy0_signal_detect = 1'b1;
assign nw0_reset = nw0_reset_i;

wire [63:0] xgmii0_rxdtmp;
wire [7:0] xgmii0_rxctmp;

network_path network_path_inst_0 (
	//XGEMAC PHY IO
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.txclk322(txclk322),
	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.qplllock(qplllock),
`ifdef USE_DIFF_QUAD
	.qplloutclk(qplloutclk1),
	.qplloutrefclk(qplloutrefclk1),
`else
	.qplloutclk(qplloutclk),
	.qplloutrefclk(qplloutrefclk),
`endif
	.reset_counter_done(reset_counter_done), 
	.txp(xphy0_txp),
	.txn(xphy0_txn),
	.rxp(xphy0_rxp),
	.rxn(xphy0_rxn),
	.tx_resetdone(xphy0_tx_resetdone),
    
	.signal_detect(xphy0_signal_detect),
	.tx_fault(sfp_tx_fault[0]),
	.prtad(xphy0_prtad),
	.xphy_status(xphy0_status),
	.clk156(clk156),
	.soft_reset(~axi_str_c2s0_aresetn),
	.sys_rst((sys_rst & ~mmcm_locked_clk156)),
	.nw_rst_out(nw0_reset_i),   
	.dclk(dclk_i),
	.xgmii_txd(xgmii0_txd),
	.xgmii_txc(xgmii0_txc),
	.xgmii_rxd(xgmii0_rxdtmp),
	.xgmii_rxc(xgmii0_rxctmp)
); 

xgmiisync xgmiisync_0 (
	.sys_rst(sys_rst),
	.xgmii_rx_clk(clk156),
	.xgmii_rxd_i(xgmii0_rxdtmp),
	.xgmii_rxc_i(xgmii0_rxctmp),
	.xgmii_rxd_o(xgmii0_rxd),
	.xgmii_rxc_o(xgmii0_rxc)
);



// ---------------
// GT1 instance
// ---------------

assign xphy1_prtad  = 5'd1;
assign xphy1_signal_detect = 1'b1;
assign nw1_reset = nw1_reset_i;
 
wire [63:0] xgmii1_rxdtmp;
wire [7:0] xgmii1_rxctmp;

network_path network_path_inst_1 (
	//XGEMAC PHY IO
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.txclk322(),
	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.qplllock(qplllock),
`ifdef USE_DIFF_QUAD
	.qplloutclk(qplloutclk2),
	.qplloutrefclk(qplloutrefclk2),
`else
	.qplloutclk(qplloutclk),
	.qplloutrefclk(qplloutrefclk),
`endif
	.reset_counter_done(reset_counter_done), 
	.txp(xphy1_txp),
	.txn(xphy1_txn),
	.rxp(xphy1_rxp),
	.rxn(xphy1_rxn),
	.tx_resetdone(xphy1_tx_resetdone),
    
	.signal_detect(xphy1_signal_detect),
	.tx_fault(sfp_tx_fault[1]),
	.prtad(xphy1_prtad),
	.xphy_status(xphy1_status),
	.clk156(clk156),
	.soft_reset(~axi_str_c2s1_aresetn),
	.sys_rst((sys_rst & ~mmcm_locked_clk156)),
	.nw_rst_out(nw1_reset_i),   
	.dclk(dclk_i), 
	.xgmii_txd(xgmii1_txd),
	.xgmii_txc(xgmii1_txc),
	.xgmii_rxd(xgmii1_rxdtmp),
	.xgmii_rxc(xgmii1_rxctmp)
); 
`endif

xgmiisync xgmiisync_1 (
	.sys_rst(sys_rst),
	.xgmii_rx_clk(clk156),
	.xgmii_rxd_i(xgmii1_rxdtmp),
	.xgmii_rxc_i(xgmii1_rxctmp),
	.xgmii_rxd_o(xgmii1_rxd),
	.xgmii_rxc_o(xgmii1_rxc)
);

`ifdef ENABLE_XGMII23
// ---------------
// GT2 instance
// ---------------

assign xphy2_prtad  = 5'd2;
assign xphy2_signal_detect = 1'b1;
assign nw2_reset = nw2_reset_i;
 
wire [63:0] xgmii2_rxdtmp;
wire [7:0] xgmii2_rxctmp;

network_path network_path_inst_2 (
	//XGEMAC PHY IO
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.txclk322(),
	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.qplllock(qplllock),
`ifdef USE_DIFF_QUAD
	.qplloutclk(qplloutclk2),
	.qplloutrefclk(qplloutrefclk2),
`else
	.qplloutclk(qplloutclk),
	.qplloutrefclk(qplloutrefclk),
`endif
	.reset_counter_done(reset_counter_done), 
	.txp(xphy2_txp),
	.txn(xphy2_txn),
	.rxp(xphy2_rxp),
	.rxn(xphy2_rxn),
	.tx_resetdone(xphy2_tx_resetdone),
    
	.signal_detect(xphy2_signal_detect),
	.tx_fault(sfp_tx_fault[2]),
	.prtad(xphy2_prtad),
	.xphy_status(xphy2_status),
	.clk156(clk156),
	.soft_reset(~axi_str_c2s1_aresetn),
	.sys_rst((sys_rst & ~mmcm_locked_clk156)),
	.nw_rst_out(nw2_reset_i),   
	.dclk(dclk_i), 
	.xgmii_txd(xgmii2_txd),
	.xgmii_txc(xgmii2_txc),
	.xgmii_rxd(xgmii2_rxdtmp),
	.xgmii_rxc(xgmii2_rxctmp)
); 

xgmiisync xgmiisync_2 (
	.sys_rst(sys_rst),
	.xgmii_rx_clk(clk156),
	.xgmii_rxd_i(xgmii2_rxdtmp),
	.xgmii_rxc_i(xgmii2_rxctmp),
	.xgmii_rxd_o(xgmii2_rxd),
	.xgmii_rxc_o(xgmii2_rxc)
);

// ---------------
// GT3 instance
// ---------------

assign xphy3_prtad  = 5'd3;
assign xphy3_signal_detect = 1'b1;
assign nw3_reset = nw3_reset_i;
 
wire [63:0] xgmii3_rxdtmp;
wire [7:0] xgmii3_rxctmp;

network_path network_path_inst_3 (
	//XGEMAC PHY IO
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.txclk322(),
	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.qplllock(qplllock),
`ifdef USE_DIFF_QUAD
	.qplloutclk(qplloutclk2),
	.qplloutrefclk(qplloutrefclk2),
`else
	.qplloutclk(qplloutclk),
	.qplloutrefclk(qplloutrefclk),
`endif
	.reset_counter_done(reset_counter_done), 
	.txp(xphy3_txp),
	.txn(xphy3_txn),
	.rxp(xphy3_rxp),
	.rxn(xphy3_rxn),
	.tx_resetdone(xphy3_tx_resetdone),
    
	.signal_detect(xphy3_signal_detect),
	.tx_fault(sfp_tx_fault[3]),
	.prtad(xphy3_prtad),
	.xphy_status(xphy3_status),
	.clk156(clk156),
	.soft_reset(~axi_str_c2s1_aresetn),
	.sys_rst((sys_rst & ~mmcm_locked_clk156)),
	.nw_rst_out(nw3_reset_i),   
	.dclk(dclk_i), 
	.xgmii_txd(xgmii3_txd),
	.xgmii_txc(xgmii3_txc),
	.xgmii_rxd(xgmii3_rxdtmp),
	.xgmii_rxc(xgmii3_rxctmp)
); 

xgmiisync xgmiisync_3 (
	.sys_rst(sys_rst),
	.xgmii_rx_clk(clk156),
	.xgmii_rxd_i(xgmii3_rxdtmp),
	.xgmii_rxc_i(xgmii3_rxctmp),
	.xgmii_rxd_o(xgmii3_rxd),
	.xgmii_rxc_o(xgmii3_rxc)
);

`endif    //ENABLE_XGMII23

`ifdef ENABLE_XGMII4
// ---------------
// GT4 instance
// ---------------

assign xphy4_prtad  = 5'd4;
assign xphy4_signal_detect = 1'b1;
assign nw4_reset = nw4_reset_i;
 
wire [63:0] xgmii4_rxdtmp;
wire [7:0] xgmii4_rxctmp;

network_path network_path_inst_4 (
	//XGEMAC PHY IO
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.txclk322(txclk322),
	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.qplllock(qplllock),
`ifdef USE_DIFF_QUAD
	.qplloutclk(qplloutclk2),
	.qplloutrefclk(qplloutrefclk2),
`else
	.qplloutclk(qplloutclk),
	.qplloutrefclk(qplloutrefclk),
`endif
	.reset_counter_done(reset_counter_done), 
	.txp(xphy4_txp),
	.txn(xphy4_txn),
	.rxp(xphy4_rxp),
	.rxn(xphy4_rxn),
	.tx_resetdone(xphy4_tx_resetdone),
    
	.signal_detect(xphy4_signal_detect),
	.tx_fault(sfp_tx_fault[3]),
	.prtad(xphy4_prtad),
	.xphy_status(xphy4_status),
	.clk156(clk156),
	.soft_reset(~axi_str_c2s1_aresetn),
	.sys_rst((sys_rst & ~mmcm_locked_clk156)),
	.nw_rst_out(nw4_reset_i),   
	.dclk(dclk_i), 
	.xgmii_txd(xgmii4_txd),
	.xgmii_txc(xgmii4_txc),
	.xgmii_rxd(xgmii4_rxdtmp),
	.xgmii_rxc(xgmii4_rxctmp)
); 

xgmiisync xgmiisync_4 (
	.sys_rst(sys_rst),
	.xgmii_rx_clk(clk156),
	.xgmii_rxd_i(xgmii4_rxdtmp),
	.xgmii_rxc_i(xgmii4_rxctmp),
	.xgmii_rxd_o(xgmii4_rxd),
	.xgmii_rxc_o(xgmii4_rxc)
);
`endif    //ENABLE_XGMII4

`ifdef USE_DIFF_QUAD
xgbaser_gt_diff_quad_wrapper xgbaser_gt_wrapper_inst_0 (
	.areset(sys_rst),
`ifdef ENABLE_XGMII4
	.refclk_p(xphy4_refclk_p),
	.refclk_n(xphy4_refclk_n),
`else
	.refclk_p(xphy0_refclk_p),
	.refclk_n(xphy0_refclk_n),
`endif
	.txclk322(txclk322),
	.gt0_tx_resetdone(xphy0_tx_resetdone),
	.gt1_tx_resetdone(xphy1_tx_resetdone),

	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.reset_counter_done(reset_counter_done),
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.clk156(clk156),
	.dclk(dclk_i),
	.qpllreset(qpllreset),
	.qplllock(qplllock),
	.qplloutclk1(qplloutclk1), 
	.qplloutrefclk1(qplloutrefclk1), 
	.qplloutclk2(qplloutclk2), 
	.qplloutrefclk2(qplloutrefclk2) 
);
`else
xgbaser_gt_same_quad_wrapper xgbaser_gt_wrapper_inst_0 (
	.areset(sys_rst),
`ifdef ENABLE_XGMII4
	.refclk_p(xphy4_refclk_p),
	.refclk_n(xphy4_refclk_n),
`else
	.refclk_p(xphy0_refclk_p),
	.refclk_n(xphy0_refclk_n),
`endif
	.txclk322(txclk322),
	.gt0_tx_resetdone(xphy0_tx_resetdone),
	.gt1_tx_resetdone(xphy1_tx_resetdone),

	.areset_refclk_bufh(areset_refclk_bufh),
	.areset_clk156(areset_clk156),
	.mmcm_locked_clk156(mmcm_locked_clk156),
	.gttxreset_txusrclk2(gttxreset_txusrclk2),
	.gttxreset(gttxreset),
	.gtrxreset(gtrxreset),
	.txuserrdy(txuserrdy),
	.reset_counter_done(reset_counter_done),
	.txusrclk(txusrclk),
	.txusrclk2(txusrclk2),
	.clk156(clk156),
	.dclk(dclk_i),
	.qpllreset(qpllreset),
	.qplllock(qplllock),
	.qplloutclk(qplloutclk), 
	.qplloutrefclk(qplloutrefclk) 
);
`endif    //USE_DIFF_QUAD



// ---------------
// PCIe user 
// ---------------
wire tx0_enable;
wire tx0_ipv6;
wire tx0_fullroute;
wire tx0_req_arp;
wire [15:0] tx0_frame_len;
wire [31:0] tx0_inter_frame_gap;
wire [31:0] tx0_ipv4_srcip;
wire [47:0] tx0_src_mac;
wire [31:0] tx0_ipv4_gwip;
wire [47:0] tx0_dst_mac;
wire [31:0] tx0_ipv4_dstip;
wire [127:0] tx0_ipv6_srcip;
wire [127:0] tx0_ipv6_dstip;
wire [31:0] tx0_pps;
wire [31:0] tx0_throughput;
wire [31:0] tx0_ipv4_ip;
wire [31:0] rx0_pps;
wire [31:0] rx0_throughput;
wire [23:0] rx0_latency;
wire [31:0] rx0_ipv4_ip;
wire [31:0] rx1_pps;
wire [31:0] rx1_throughput;
wire [23:0] rx1_latency;
wire [31:0] rx1_ipv4_ip;
wire [31:0] rx2_pps;
wire [31:0] rx2_throughput;
wire [23:0] rx2_latency;
wire [31:0] rx2_ipv4_ip;
wire [31:0] rx3_pps;
wire [31:0] rx3_throughput;
wire [23:0] rx3_latency;
wire [31:0] rx3_ipv4_i;

wire [31:0] global_counter;

// ---------------
// Measure
// ---------------
measure measure_inst (
	.sys_rst(sys_rst),
	.sys_clk(clk156),
	.pci_clk(user_clk),

	.xgmii_0_txd(xgmii0_txd),
	.xgmii_0_txc(xgmii0_txc),
	.xgmii_0_rxd(xgmii0_rxd),
	.xgmii_0_rxc(xgmii0_rxc),

	.xgmii_1_txd(xgmii1_txd),
	.xgmii_1_txc(xgmii1_txc),
	.xgmii_1_rxd(xgmii1_rxd),
	.xgmii_1_rxc(xgmii1_rxc),

`ifdef ENABLE_XGMII23
	.xgmii_2_txd(xgmii2_txd),
	.xgmii_2_txc(xgmii2_txc),
	.xgmii_2_rxd(xgmii2_rxd),
	.xgmii_2_rxc(xgmii2_rxc),

	.xgmii_3_txd(xgmii3_txd),
	.xgmii_3_txc(xgmii3_txc),
	.xgmii_3_rxd(xgmii3_rxd),
	.xgmii_3_rxc(xgmii3_rxc),
`endif

	.tx0_enable(tx0_enable),
	.tx0_ipv6(tx0_ipv6),
	.tx0_fullroute(tx0_fullroute),
	.tx0_req_arp(tx0_req_arp),
	.tx0_frame_len(tx0_frame_len),
	.tx0_inter_frame_gap(tx0_inter_frame_gap),
	.tx0_ipv4_srcip(tx0_ipv4_srcip),
	.tx0_src_mac(tx0_src_mac),
	.tx0_ipv4_gwip(tx0_ipv4_gwip),
	.tx0_ipv6_srcip(tx0_ipv6_srcip),
	.tx0_ipv6_dstip(tx0_ipv6_dstip),
	.tx0_dst_mac(tx0_dst_mac),
	.tx0_ipv4_dstip({tx0_ipv4_dstip}),
	.tx0_pps(tx0_pps),
	.tx0_throughput(tx0_throughput),
	.tx0_ipv4_ip(tx0_ipv4_ip),

	.rx0_pps(rx0_pps),
	.rx0_throughput(rx0_throughput),
	.rx0_latency(rx0_latency),
	.rx0_ipv4_ip(rx0_ipv4_ip),

	.rx1_pps(rx1_pps),
	.rx1_throughput(rx1_throughput),
	.rx1_latency(rx1_latency),
	.rx1_ipv4_ip(rx1_ipv4_ip),

	.global_counter(global_counter)
);


assign led[0] = xphy0_status[0]; 
assign led[1] = xphy1_status[0]; 
assign led[2] = xphy2_status[0]; 
assign led[3] = xphy3_status[0]; 
`ifndef ENABLE_PCIE
assign led[4] = 1'b0;
assign led[5] = 1'b0;
assign led[6] = 1'b0;
assign led[7] = 1'b0;
`endif

//- Tie off related to SFP+
assign sfp_tx_disable = 5'b10000;	// all ports enable

//- This LED indicates FMC connected OK
assign fmc_ok_led = 1'b1;
//- This LED indicates FMC GBTCLK0 programmed OK
assign fmc_clk_312_5 = (fmc_gbtclk0_fsel == 2'b11) ? 1'b1 : 1'b0;






`ifdef ENABLE_PCIE
// Wire Declarations
  wire                                        pipe_mmcm_rst_n;
  wire                                        user_lnk_up;

  // Tx
  wire                                        s_axis_tx_tready;
  wire [3:0]                                  s_axis_tx_tuser;
  wire [C_DATA_WIDTH-1:0]                     s_axis_tx_tdata;
  wire [KEEP_WIDTH-1:0]                       s_axis_tx_tkeep;
  wire                                        s_axis_tx_tlast;
  wire                                        s_axis_tx_tvalid;

  // Rx
  wire [C_DATA_WIDTH-1:0]                     m_axis_rx_tdata;
  wire [KEEP_WIDTH-1:0]                       m_axis_rx_tkeep;
  wire                                        m_axis_rx_tlast;
  wire                                        m_axis_rx_tvalid;
  wire                                        m_axis_rx_tready;
  wire  [21:0]                                m_axis_rx_tuser;

  wire                                        tx_cfg_gnt;
  wire                                        rx_np_ok;
  wire                                        rx_np_req;
  wire                                        cfg_turnoff_ok;
  wire                                        cfg_trn_pending;
  wire                                        cfg_pm_halt_aspm_l0s;
  wire                                        cfg_pm_halt_aspm_l1;
  wire                                        cfg_pm_force_state_en;
  wire   [1:0]                                cfg_pm_force_state;
  wire                                        cfg_pm_wake;
  wire  [63:0]                                cfg_dsn;

  // Flow Control
  wire [2:0]                                  fc_sel;

  //-------------------------------------------------------
  // Configuration (CFG) Interface
  //-------------------------------------------------------
  wire                                        cfg_err_ecrc;
  wire                                        cfg_err_cor;
  wire                                        cfg_err_ur;
  wire                                        cfg_err_cpl_timeout;
  wire                                        cfg_err_cpl_abort;
  wire                                        cfg_err_cpl_unexpect;
  wire                                        cfg_err_posted;
  wire                                        cfg_err_locked;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire [127:0]                                cfg_err_aer_headerlog;
  wire   [4:0]                                cfg_aer_interrupt_msgnum;

  wire                                        cfg_interrupt;
  wire                                        cfg_interrupt_assert;
  wire   [7:0]                                cfg_interrupt_di;
  wire                                        cfg_interrupt_stat;
  wire   [4:0]                                cfg_pciecap_interrupt_msgnum;

  wire                                        cfg_to_turnoff;
  wire   [7:0]                                cfg_bus_number;
  wire   [4:0]                                cfg_device_number;
  wire   [2:0]                                cfg_function_number;

  wire  [31:0]                                cfg_mgmt_di;
  wire   [3:0]                                cfg_mgmt_byte_en;
  wire   [9:0]                                cfg_mgmt_dwaddr;
  wire                                        cfg_mgmt_wr_en;
  wire                                        cfg_mgmt_rd_en;
  wire                                        cfg_mgmt_wr_readonly;

  //-------------------------------------------------------
  // Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------
  wire                                        pl_directed_link_auton;
  wire [1:0]                                  pl_directed_link_change;
  wire                                        pl_directed_link_speed;
  wire [1:0]                                  pl_directed_link_width;
  wire                                        pl_upstream_prefer_deemph;

  wire                                        sys_rst_n_c;
  wire                                        sys_clk;


// Register Declaration

  reg                                         user_reset_q;
  reg                                         user_lnk_up_q;
  reg    [25:0]                               user_clk_heartbeat = 'h0;

// Local Parameters
  localparam TCQ               = 1;
  localparam USER_CLK_FREQ     = 3;
  localparam USER_CLK2_DIV2    = "FALSE";
  localparam USERCLK2_FREQ     = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ: USER_CLK_FREQ;

 //-----------------------------I/O BUFFERS------------------------//

  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

  IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));

  assign led[4] = sys_rst_n_c;
  assign led[5] = !user_reset;
  assign led[6] = user_lnk_up;
  assign led[7] = user_clk_heartbeat[25];
//  OBUF   led_4_obuf (.O(led[4]), .I(sys_rst_n_c));
//  OBUF   led_5_obuf (.O(led[5]), .I(!user_reset));
//  OBUF   led_6_obuf (.O(led[6]), .I(user_lnk_up));
//  OBUF   led_7_obuf (.O(led[7]), .I(user_clk_heartbeat[25]));

  always @(posedge user_clk) begin
    user_reset_q  <= user_reset;
    user_lnk_up_q <= user_lnk_up;
  end

  // Create a Clock Heartbeat on LED #3
  always @(posedge user_clk) begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
  end


      assign pipe_mmcm_rst_n                        = 1'b1;



pcie_7x_0_support #
   (	 
    .LINK_CAP_MAX_LINK_WIDTH        ( 4 ),  // PCIe Lane Width
    .C_DATA_WIDTH                   ( C_DATA_WIDTH ),                       // RX/TX interface data width
    .KEEP_WIDTH                     ( KEEP_WIDTH ),                         // TSTRB width
    .PCIE_REFCLK_FREQ               ( REF_CLK_FREQ ),                       // PCIe reference clock frequency
    .PCIE_USERCLK1_FREQ             ( USER_CLK_FREQ +1 ),                   // PCIe user clock 1 frequency
    .PCIE_USERCLK2_FREQ             ( USERCLK2_FREQ +1 ),                   // PCIe user clock 2 frequency             
    .PCIE_USE_MODE                  ("3.0"),           // PCIe use mode
    .PCIE_GT_DEVICE                 ("GTX")              // PCIe GT device
   ) 
pcie_7x_0_support_i
  (

  //----------------------------------------------------------------------------------------------------------------//
  // PCI Express (pci_exp) Interface                                                                                //
  //----------------------------------------------------------------------------------------------------------------//
  // Tx
  .pci_exp_txn                               ( pci_exp_txn ),
  .pci_exp_txp                               ( pci_exp_txp ),

  // Rx
  .pci_exp_rxn                               ( pci_exp_rxn ),
  .pci_exp_rxp                               ( pci_exp_rxp ),

  //----------------------------------------------------------------------------------------------------------------//
  // Clocking Sharing Interface                                                                                     //
  //----------------------------------------------------------------------------------------------------------------//
  .pipe_pclk_out_slave                        ( ),
  .pipe_rxusrclk_out                          ( ),
  .pipe_rxoutclk_out                          ( ),
  .pipe_dclk_out                              ( ),
  .pipe_userclk1_out                          ( ),
  .pipe_oobclk_out                            ( ),
  .pipe_userclk2_out                          ( ),
  .pipe_mmcm_lock_out                         ( ),
  .pipe_pclk_sel_slave                        ( 4'b0),
  .pipe_mmcm_rst_n                            ( pipe_mmcm_rst_n ),        // Async      | Async


  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//

  // Common
  .user_clk_out                              ( user_clk ),
  .user_reset_out                            ( user_reset ),
  .user_lnk_up                               ( user_lnk_up ),
  .user_app_rdy                              ( ),

  // TX
  .s_axis_tx_tready                          ( s_axis_tx_tready ),
  .s_axis_tx_tdata                           ( s_axis_tx_tdata ),
  .s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
  .s_axis_tx_tuser                           ( s_axis_tx_tuser ),
  .s_axis_tx_tlast                           ( s_axis_tx_tlast ),
  .s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),

  // Rx
  .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
  .m_axis_rx_tready                          ( m_axis_rx_tready ),
  .m_axis_rx_tuser                           ( m_axis_rx_tuser ),

  // Flow Control
  .fc_cpld                                   ( ),
  .fc_cplh                                   ( ),
  .fc_npd                                    ( ),
  .fc_nph                                    ( ),
  .fc_pd                                     ( ),
  .fc_ph                                     ( ),
  .fc_sel                                    ( fc_sel ),

  // Management Interface
  .cfg_mgmt_di                               ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en                          ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                           ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                            ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                            ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly                      ( cfg_mgmt_wr_readonly ),

  //------------------------------------------------//
  // EP and RP                                      //
  //------------------------------------------------//
  .cfg_mgmt_do                               ( ),
  .cfg_mgmt_rd_wr_done                       ( ),
  .cfg_mgmt_wr_rw1c_as_rw                    ( 1'b0 ),

  // Error Reporting Interface
  .cfg_err_ecrc                              ( cfg_err_ecrc ),
  .cfg_err_ur                                ( cfg_err_ur ),
  .cfg_err_cpl_timeout                       ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_unexpect                      ( cfg_err_cpl_unexpect ),
  .cfg_err_cpl_abort                         ( cfg_err_cpl_abort ),
  .cfg_err_posted                            ( cfg_err_posted ),
  .cfg_err_cor                               ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked             ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor                      ( cfg_err_internal_cor ),
  .cfg_err_malformed                         ( cfg_err_malformed ),
  .cfg_err_mc_blocked                        ( cfg_err_mc_blocked ),
  .cfg_err_poisoned                          ( cfg_err_poisoned ),
  .cfg_err_norecovery                        ( cfg_err_norecovery ),
  .cfg_err_tlp_cpl_header                    ( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy                           ( ),
  .cfg_err_locked                            ( cfg_err_locked ),
  .cfg_err_acs                               ( cfg_err_acs ),
  .cfg_err_internal_uncor                    ( cfg_err_internal_uncor ),

  //----------------------------------------------------------------------------------------------------------------//
  // AER Interface                                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog                     ( cfg_err_aer_headerlog ),
  .cfg_err_aer_headerlog_set                 ( ),
  .cfg_aer_ecrc_check_en                     ( ),
  .cfg_aer_ecrc_gen_en                       ( ),
  .cfg_aer_interrupt_msgnum                  ( cfg_aer_interrupt_msgnum ),

  .tx_cfg_gnt                                ( tx_cfg_gnt ),
  .rx_np_ok                                  ( rx_np_ok ),
  .rx_np_req                                 ( rx_np_req ),
  .cfg_trn_pending                           ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en                     ( cfg_pm_force_state_en ),
  .cfg_pm_force_state                        ( cfg_pm_force_state ),
  .cfg_dsn                                   ( cfg_dsn ),
  .cfg_turnoff_ok                            ( cfg_turnoff_ok ),
  .cfg_pm_wake                               ( cfg_pm_wake ),
  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .cfg_pm_send_pme_to                        ( 1'b0 ),
  .cfg_ds_bus_number                         ( 8'b0 ),
  .cfg_ds_device_number                      ( 5'b0 ),
  .cfg_ds_function_number                    ( 3'b0 ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .cfg_interrupt                             ( cfg_interrupt ),
  .cfg_interrupt_rdy                         ( ),
  .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
  .cfg_interrupt_di                          ( cfg_interrupt_di ),
  .cfg_interrupt_do                          ( ),
  .cfg_interrupt_mmenable                    ( ),
  .cfg_interrupt_msienable                   ( ),
  .cfg_interrupt_msixenable                  ( ),
  .cfg_interrupt_msixfm                      ( ),
  .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),

  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_status                                ( ),
  .cfg_command                               ( ),
  .cfg_dstatus                               ( ),
  .cfg_lstatus                               ( ),
  .cfg_pcie_link_state                       ( ),
  .cfg_dcommand                              ( ),
  .cfg_lcommand                              ( ),
  .cfg_dcommand2                             ( ),

  .cfg_pmcsr_pme_en                          ( ),
  .cfg_pmcsr_powerstate                      ( ),
  .cfg_pmcsr_pme_status                      ( ),
  .cfg_received_func_lvl_rst                 ( ),
  .tx_buf_av                                 ( ),
  .tx_err_drop                               ( ),
  .tx_cfg_req                                ( ),
  .cfg_to_turnoff                            ( cfg_to_turnoff ),
  .cfg_bus_number                            ( cfg_bus_number ),
  .cfg_device_number                         ( cfg_device_number ),
  .cfg_function_number                       ( cfg_function_number ),
  .cfg_bridge_serr_en                        ( ),
  .cfg_slot_control_electromech_il_ctl_pulse ( ),
  .cfg_root_control_syserr_corr_err_en       ( ),
  .cfg_root_control_syserr_non_fatal_err_en  ( ),
  .cfg_root_control_syserr_fatal_err_en      ( ),
  .cfg_root_control_pme_int_en               ( ),
  .cfg_aer_rooterr_corr_err_reporting_en     ( ),
  .cfg_aer_rooterr_non_fatal_err_reporting_en( ),
  .cfg_aer_rooterr_fatal_err_reporting_en    ( ),
  .cfg_aer_rooterr_corr_err_received         ( ),
  .cfg_aer_rooterr_non_fatal_err_received    ( ),
  .cfg_aer_rooterr_fatal_err_received        ( ),
  //----------------------------------------------------------------------------------------------------------------//
  // VC interface                                                                                                  //
  //---------------------------------------------------------------------------------------------------------------//
  .cfg_vc_tcvc_map                           ( ),

  .cfg_msg_received                          ( ),
  .cfg_msg_data                              ( ),
  .cfg_msg_received_err_cor                  ( ),
  .cfg_msg_received_err_non_fatal            ( ),
  .cfg_msg_received_err_fatal                ( ),
  .cfg_msg_received_pm_as_nak                ( ),
  .cfg_msg_received_pme_to_ack               ( ),
  .cfg_msg_received_assert_int_a             ( ),
  .cfg_msg_received_assert_int_b             ( ),
  .cfg_msg_received_assert_int_c             ( ),
  .cfg_msg_received_assert_int_d             ( ),
  .cfg_msg_received_deassert_int_a           ( ),
  .cfg_msg_received_deassert_int_b           ( ),
  .cfg_msg_received_deassert_int_c           ( ),
  .cfg_msg_received_deassert_int_d           ( ),
  .cfg_msg_received_pm_pme                  ( ),
  .cfg_msg_received_setslotpowerlimit       ( ),

  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_change                   ( pl_directed_link_change ),
  .pl_directed_link_width                    ( pl_directed_link_width ),
  .pl_directed_link_speed                    ( pl_directed_link_speed ),
  .pl_directed_link_auton                    ( pl_directed_link_auton ),
  .pl_upstream_prefer_deemph                 ( pl_upstream_prefer_deemph ),

  .pl_sel_lnk_rate                           ( ),
  .pl_sel_lnk_width                          ( ),
  .pl_ltssm_state                            ( ),
  .pl_lane_reversal_mode                     ( ),

  .pl_phy_lnk_up                             ( ),
  .pl_tx_pm_state                            ( ),
  .pl_rx_pm_state                            ( ),

  .pl_link_upcfg_cap                         ( ),
  .pl_link_gen2_cap                          ( ),
  .pl_link_partner_gen2_supported            ( ),
  .pl_initial_link_width                     ( ),

  .pl_directed_change_done                   ( ),

  //------------------------------------------------//
  // EP Only                                        //
  //------------------------------------------------//
  .pl_received_hot_rst                       ( ),

  //------------------------------------------------//
  // RP Only                                        //
  //------------------------------------------------//
  .pl_transmit_hot_rst                       ( 1'b0 ),
  .pl_downstream_deemph_source               ( 1'b0 ),

  //----------------------------------------------------------------------------------------------------------------//
  // PCIe DRP (PCIe DRP) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .pcie_drp_clk                               ( 1'b1 ),
  .pcie_drp_en                                ( 1'b0 ),
  .pcie_drp_we                                ( 1'b0 ),
  .pcie_drp_addr                              ( 9'h0 ),
  .pcie_drp_di                                ( 16'h0 ),
  .pcie_drp_rdy                               ( ),
  .pcie_drp_do                                ( ),



  //----------------------------------------------------------------------------------------------------------------//
  // System  (SYS) Interface                                                                                        //
  //----------------------------------------------------------------------------------------------------------------//
  .sys_clk                                    ( sys_clk ),
  .sys_rst_n                                  ( sys_rst_n_c )

);


pcie_app_7x  #(
  .C_DATA_WIDTH( C_DATA_WIDTH ),
  .TCQ( TCQ )

) app (

  //----------------------------------------------------------------------------------------------------------------//
  // AXI-S Interface                                                                                                //
  //----------------------------------------------------------------------------------------------------------------//

  // Common
  .user_clk                       ( user_clk ),
  .user_reset                     ( user_reset_q ),
  .user_lnk_up                    ( user_lnk_up_q ),

  // Tx
  .s_axis_tx_tready               ( s_axis_tx_tready ),
  .s_axis_tx_tdata                ( s_axis_tx_tdata ),
  .s_axis_tx_tkeep                ( s_axis_tx_tkeep ),
  .s_axis_tx_tuser                ( s_axis_tx_tuser ),
  .s_axis_tx_tlast                ( s_axis_tx_tlast ),
  .s_axis_tx_tvalid               ( s_axis_tx_tvalid ),

  // Rx
  .m_axis_rx_tdata                ( m_axis_rx_tdata ),
  .m_axis_rx_tkeep                ( m_axis_rx_tkeep ),
  .m_axis_rx_tlast                ( m_axis_rx_tlast ),
  .m_axis_rx_tvalid               ( m_axis_rx_tvalid ),
  .m_axis_rx_tready               ( m_axis_rx_tready ),
  .m_axis_rx_tuser                ( m_axis_rx_tuser ),

  .tx_cfg_gnt                     ( tx_cfg_gnt ),
  .rx_np_ok                       ( rx_np_ok ),
  .rx_np_req                      ( rx_np_req ),
  .cfg_turnoff_ok                 ( cfg_turnoff_ok ),
  .cfg_trn_pending                ( cfg_trn_pending ),
  .cfg_pm_halt_aspm_l0s           ( cfg_pm_halt_aspm_l0s ),
  .cfg_pm_halt_aspm_l1            ( cfg_pm_halt_aspm_l1 ),
  .cfg_pm_force_state_en          ( cfg_pm_force_state_en ),
  .cfg_pm_force_state             ( cfg_pm_force_state ),
  .cfg_pm_wake                    ( cfg_pm_wake ),
  .cfg_dsn                        ( cfg_dsn ),

  // Flow Control
  .fc_sel                         ( fc_sel ),

  //----------------------------------------------------------------------------------------------------------------//
  // Configuration (CFG) Interface                                                                                  //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_cor                    ( cfg_err_cor ),
  .cfg_err_atomic_egress_blocked  ( cfg_err_atomic_egress_blocked ),
  .cfg_err_internal_cor           ( cfg_err_internal_cor ),
  .cfg_err_malformed              ( cfg_err_malformed ),
  .cfg_err_mc_blocked             ( cfg_err_mc_blocked ),
  .cfg_err_poisoned               ( cfg_err_poisoned ),
  .cfg_err_norecovery             ( cfg_err_norecovery ),
  .cfg_err_ur                     ( cfg_err_ur ),
  .cfg_err_ecrc                   ( cfg_err_ecrc ),
  .cfg_err_cpl_timeout            ( cfg_err_cpl_timeout ),
  .cfg_err_cpl_abort              ( cfg_err_cpl_abort ),
  .cfg_err_cpl_unexpect           ( cfg_err_cpl_unexpect ),
  .cfg_err_posted                 ( cfg_err_posted ),
  .cfg_err_locked                 ( cfg_err_locked ),
  .cfg_err_acs                    ( cfg_err_acs ), //1'b0 ),
  .cfg_err_internal_uncor         ( cfg_err_internal_uncor ), //1'b0 ),
  .cfg_err_tlp_cpl_header         ( cfg_err_tlp_cpl_header ),
  //----------------------------------------------------------------------------------------------------------------//
  // Advanced Error Reporting (AER) Interface                                                                       //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_err_aer_headerlog          ( cfg_err_aer_headerlog ),
  .cfg_aer_interrupt_msgnum       ( cfg_aer_interrupt_msgnum ),

  .cfg_to_turnoff                 ( cfg_to_turnoff ),
  .cfg_bus_number                 ( cfg_bus_number ),
  .cfg_device_number              ( cfg_device_number ),
  .cfg_function_number            ( cfg_function_number ),

  //----------------------------------------------------------------------------------------------------------------//
  // Management (MGMT) Interface                                                                                    //
  //----------------------------------------------------------------------------------------------------------------//
  .cfg_mgmt_di                    ( cfg_mgmt_di ),
  .cfg_mgmt_byte_en               ( cfg_mgmt_byte_en ),
  .cfg_mgmt_dwaddr                ( cfg_mgmt_dwaddr ),
  .cfg_mgmt_wr_en                 ( cfg_mgmt_wr_en ),
  .cfg_mgmt_rd_en                 ( cfg_mgmt_rd_en ),
  .cfg_mgmt_wr_readonly           ( cfg_mgmt_wr_readonly ),

  //----------------------------------------------------------------------------------------------------------------//
  // Physical Layer Control and Status (PL) Interface                                                               //
  //----------------------------------------------------------------------------------------------------------------//
  .pl_directed_link_auton         ( pl_directed_link_auton ),
  .pl_directed_link_change        ( pl_directed_link_change ),
  .pl_directed_link_speed         ( pl_directed_link_speed ),
  .pl_directed_link_width         ( pl_directed_link_width ),
  .pl_upstream_prefer_deemph      ( pl_upstream_prefer_deemph ),

  .cfg_interrupt                  ( cfg_interrupt ),
  .cfg_interrupt_assert           ( cfg_interrupt_assert ),
  .cfg_interrupt_di               ( cfg_interrupt_di ),
  .cfg_interrupt_stat             ( cfg_interrupt_stat ),
  .cfg_pciecap_interrupt_msgnum   ( cfg_pciecap_interrupt_msgnum ),

	// PCIe user registers
	.tx0_enable(tx0_enable),
	.tx0_ipv6(tx0_ipv6),
	.tx0_fullroute(tx0_fullroute),
	.tx0_req_arp(tx0_req_arp),
	.tx0_frame_len(tx0_frame_len),
	.tx0_inter_frame_gap(tx0_inter_frame_gap),
	.tx0_ipv4_srcip(tx0_ipv4_srcip),
	.tx0_src_mac(tx0_src_mac),
	.tx0_ipv4_gwip(tx0_ipv4_gwip),
	.tx0_dst_mac(tx0_dst_mac),
	.tx0_ipv4_dstip(tx0_ipv4_dstip),
	.tx0_ipv6_srcip(tx0_ipv6_srcip),
	.tx0_ipv6_dstip(tx0_ipv6_dstip),
	.tx0_pps(tx0_pps),
	.tx0_throughput(tx0_throughput),
	.tx0_ipv4_ip(tx0_ipv4_ip),
	.rx0_pps(rx0_pps),
	.rx0_throughput(rx0_throughput),
	.rx0_latency(rx0_latency),
	.rx0_ipv4_ip(rx0_ipv4_ip),
	.rx1_pps(rx1_pps),
	.rx1_throughput(rx1_throughput),
	.rx1_latency(rx1_latency),
	.rx1_ipv4_ip(rx1_ipv4_ip),
	.rx2_pps(rx2_pps),
	.rx2_throughput(rx2_throughput),
	.rx2_latency(rx2_latency),
	.rx2_ipv4_ip(rx2_ipv4_ip),
	.rx3_pps(rx3_pps),
	.rx3_throughput(rx3_throughput),
	.rx3_latency(rx3_latency),
	.rx3_ipv4_ip(rx3_ipv4_ip)
);
`endif

endmodule
