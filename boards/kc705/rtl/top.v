`timescale 1ps / 1ps

module top (
    input                          xphy0_refclk_p, 
    input                          xphy0_refclk_n, 
    output [4:0]                   sfp_tx_disable, 
    output                         xphy0_txp, 
    output                         xphy0_txn, 
    input                          xphy0_rxp, 
    input                          xphy0_rxn,
    output                         xphy1_txp, 
    output                         xphy1_txn, 
    input                          xphy1_rxp, 
    input                          xphy1_rxn,

    input                          clk_ref_p,
    input                          clk_ref_n,
    input                          emcclk,
    output                         fmc_ok_led,
    input [1:0]                    fmc_gbtclk0_fsel,
    output                         fmc_clk_312_5,
    // BUTTON
    input                          button_n,
    input                          button_s,
    input                          button_w,
    input                          button_e,
    input                          button_c,
    // DIP SW
    input [3:0]                    dipsw,
    // Diagnostic LEDs
    output [7:0]                   led           
);



// Clock and Reset
wire sys_rst;
assign sys_rst = button_c; // 1'b0;

 
// -------------------
// -- Local Signals --
// -------------------

// Xilinx Hard Core Instantiation

wire                                  clk156;

wire [63:0]                           xgmii0_txd, xgmii1_txd;
wire [7:0]                            xgmii0_txc, xgmii1_txc;
wire [63:0]                           xgmii0_rxd, xgmii1_rxd;
wire [7:0]                            xgmii0_rxc, xgmii1_rxc;
  
wire [7:0]                            xphy0_status;
wire [7:0]                            xphy1_status;
wire                                  xphy0_tx_fault;
wire                                  xphy1_tx_fault;
  

wire                                  nw0_reset;  
wire                                  nw1_reset;  
wire                                  txusrclk             ;
wire                                  txusrclk2            ;
wire                                  txclk322             ;
wire                                  areset_refclk_bufh   ;
wire                                  areset_clk156        ;
wire                                  mmcm_locked_clk156   ;
wire                                  gttxreset_txusrclk2  ;
wire                                  gttxreset            ;
wire                                  gtrxreset            ;
wire                                  txuserrdy            ;
wire                                  qplllock             ;
wire                                  qplloutclk           ;
wire                                  qplloutrefclk        ;
wire                                  qplloutclk1          ;
wire                                  qplloutrefclk1       ;
wire                                  qplloutclk2          ;
wire                                  qplloutrefclk2       ;
wire                                  reset_counter_done   ; 
wire                                  nw0_reset_i      ;
wire                                  nw1_reset_i      ;
wire                                  xphy0_tx_resetdone      ;
wire                                  xphy1_tx_resetdone      ;


  
//- Network Path signal declarations
wire    [4:0]                                 xphy0_prtad;
wire                                          xphy0_signal_detect;
wire    [4:0]                                 xphy1_prtad;
wire                                          xphy1_signal_detect;
  

wire                                          xphyrefclk_i;    
wire                                          gt0_pma_resetout_i ;
wire                                          gt0_pcs_resetout_i;         
wire                                          gt0_drpen_i;                
wire                                          gt0_drpwe_i;                
wire   [15:0]                                 gt0_drpaddr_i;              
wire   [15:0]                                 gt0_drpdi_i;                
wire   [15:0]                                 gt0_drpdo_i;                
wire                                          gt0_drprdy_i;               
wire                                          gt0_resetdone_i;            
wire   [31:0]                                 gt0_txd_i;                  
wire   [7:0]                                  gt0_txc_i;                  
wire   [31:0]                                 gt0_rxd_i;                  
wire   [7:0]                                  gt0_rxc_i;                  
wire                                          gt0_rxgearboxslip_i;        
wire                                          gt0_tx_prbs31_en_i;         
wire                                          gt0_rx_prbs31_en_i;         
wire   [2:0]                                  gt0_loopback_i;             
wire                                          gt0_txclk322_i;             
wire                                          gt0_rxclk322_i;             
wire                                          gt1_drpen_i;                
wire                                          gt1_drpwe_i;                
wire   [15:0]                                 gt1_drpaddr_i;              
wire   [15:0]                                 gt1_drpdi_i;                
wire   [15:0]                                 gt1_drpdo_i;                
wire                                          gt1_drprdy_i;               
wire                                          gt1_txclk322_i;             
wire                                          gt1_rxclk322_i;             
wire                                          dclk_i;                     
wire                                          gt1_pma_resetout_i ;
wire                                          gt1_pcs_resetout_i;         
wire                                          gt1_resetdone_i;            
wire   [31:0]                                 gt1_txd_i;                  
wire   [7:0]                                  gt1_txc_i;                  
wire   [31:0]                                 gt1_rxd_i;                  
wire   [7:0]                                  gt1_rxc_i;                  
wire                                          gt1_rxgearboxslip_i;        
wire                                          gt1_tx_prbs31_en_i;         
wire                                          gt1_rx_prbs31_en_i;         
  
wire   [2:0]                                  gt1_loopback_i;             

  
// ---------------
// Clock and Reset
// ---------------

assign xphy0_tx_fault = 1'b0;
assign xphy1_tx_fault = 1'b0;

wire                                  gt0_pma_resetout;
wire                                  gt0_pcs_resetout;
wire                                  gt0_drpen;
wire                                  gt0_drpwe;
wire [15:0]                           gt0_drpaddr;
wire [15:0]                           gt0_drpdi;
wire [15:0]                           gt0_drpdo;
wire                                  gt0_drprdy;
wire                                  gt0_resetdone;
wire [63:0]                           gt0_txd;
wire [7:0]                            gt0_txc;
wire [63:0]                           gt0_rxd;
wire [7:0]                            gt0_rxc;
wire                                  gt0_rxgearboxslip;
wire                                  gt0_tx_prbs31_en;
wire                                  gt0_rx_prbs31_en;
wire [2:0]                            gt0_loopback;

wire                                  gt1_pma_resetout;
wire                                  gt1_pcs_resetout;
wire                                  gt1_drpen;
wire                                  gt1_drpwe;
wire [15:0]                           gt1_drpaddr;
wire [15:0]                           gt1_drpdi;
wire [15:0]                           gt1_drpdo;
wire                                  gt1_drprdy;
wire                                  gt1_resetdone;
wire [63:0]                           gt1_txd;
wire [7:0]                            gt1_txc;
wire [63:0]                           gt1_rxd;
wire [7:0]                            gt1_rxc;
wire                                  gt1_rxgearboxslip;
wire [2:0]                            gt1_loopback;

  
assign xphy0_prtad  = 5'd0;
assign xphy0_signal_detect = 1'b1;

network_path network_path_inst_0 (
    //XGEMAC PHY IO
    .txusrclk                         (txusrclk             ),
    .txusrclk2                        (txusrclk2            ),
    .txclk322                         (txclk322             ),
    .areset_refclk_bufh               (areset_refclk_bufh   ),
    .areset_clk156                    (areset_clk156        ),
    .mmcm_locked_clk156               (mmcm_locked_clk156   ),
    .gttxreset_txusrclk2              (gttxreset_txusrclk2  ),
    .gttxreset                        (gttxreset            ),
    .gtrxreset                        (gtrxreset            ),
    .txuserrdy                        (txuserrdy            ),
    .qplllock                         (qplllock             ),
`ifdef USE_DIFF_QUAD
    .qplloutclk                       (qplloutclk1          ),
    .qplloutrefclk                    (qplloutrefclk1       ),
`else
    .qplloutclk                       (qplloutclk           ),
    .qplloutrefclk                    (qplloutrefclk        ),
`endif
    .reset_counter_done               (reset_counter_done   ), 
    .txp                              (xphy0_txp                  ),
    .txn                              (xphy0_txn                  ),
    .rxp                              (xphy0_rxp                  ),
    .rxn                              (xphy0_rxn                  ),
    .tx_resetdone                     (xphy0_tx_resetdone         ),
    
    .signal_detect                    (xphy0_signal_detect      ),
    .tx_fault                         (xphy0_tx_fault             ),
    .prtad                            (xphy0_prtad                ),
    .xphy_status                      (xphy0_status               ),
    .clk156                           (clk156            ),
    .soft_reset                       (~axi_str_c2s0_aresetn       ),
    .sys_rst                          ((sys_rst & ~mmcm_locked_clk156)),
    .nw_rst_out                       (nw0_reset_i                ),   
    .dclk                             (dclk_i                     ),
    .xgmii_txd                        (xgmii0_txd),
    .xgmii_txc                        (xgmii0_txc),
    .xgmii_rxd                        (xgmii0_rxd),
    .xgmii_rxc                        (xgmii0_rxc)
); 

assign xphy1_prtad  = 5'd1;
assign xphy1_signal_detect = 1'b1;
 
assign  nw0_reset = nw0_reset_i;
assign  nw1_reset = nw1_reset_i;
 
network_path network_path_inst_1 (
    //XGEMAC PHY IO
    .txusrclk                         (txusrclk             ),
    .txusrclk2                        (txusrclk2            ),
    .txclk322                         (                     ),
    .areset_refclk_bufh               (areset_refclk_bufh   ),
    .areset_clk156                    (areset_clk156        ),
    .mmcm_locked_clk156               (mmcm_locked_clk156   ),
    .gttxreset_txusrclk2              (gttxreset_txusrclk2  ),
    .gttxreset                        (gttxreset            ),
    .gtrxreset                        (gtrxreset            ),
    .txuserrdy                        (txuserrdy            ),
    .qplllock                         (qplllock             ),
`ifdef USE_DIFF_QUAD
    .qplloutclk                       (qplloutclk2          ),
    .qplloutrefclk                    (qplloutrefclk2       ),
`else
    .qplloutclk                       (qplloutclk           ),
    .qplloutrefclk                    (qplloutrefclk        ),
`endif
    .reset_counter_done               (reset_counter_done   ), 
    .txp                              (xphy1_txp                  ),
    .txn                              (xphy1_txn                  ),
    .rxp                              (xphy1_rxp                  ),
    .rxn                              (xphy1_rxn                  ),
    .tx_resetdone                     (xphy1_tx_resetdone         ),
    
    .signal_detect                    (xphy1_signal_detect      ),
    .tx_fault                         (xphy1_tx_fault             ),
    .prtad                            (xphy1_prtad                ),
    .xphy_status                      (xphy1_status               ),
    .clk156                           (clk156            ),
    .soft_reset                       (~axi_str_c2s1_aresetn       ),
    .sys_rst                          ((sys_rst & ~mmcm_locked_clk156)),
    .nw_rst_out                       (nw1_reset_i                ),   
    .dclk                             (dclk_i                     ), 
    .xgmii_txd                        (xgmii1_txd),
    .xgmii_txc                        (xgmii1_txc),
    .xgmii_rxd                        (xgmii1_rxd),
    .xgmii_rxc                        (xgmii1_rxc)
); 


`ifdef USE_DIFF_QUAD
xgbaser_gt_diff_quad_wrapper xgbaser_gt_wrapper_inst_0 (
     .areset(sys_rst),
     .refclk_p(xphy0_refclk_p),
     .refclk_n(xphy0_refclk_n),
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
     .refclk_p(xphy0_refclk_p),
     .refclk_n(xphy0_refclk_n),
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
// Measure
// ---------------
measure measure_inst (
  .sys_rst(sys_rst),
  .sys_clk(clk156),

  .xgmii_0_txd(xgmii0_txd),
  .xgmii_0_txc(xgmii0_txc),
  .xgmii_0_rxd(xgmii0_rxd),
  .xgmii_0_rxc(xgmii0_rxc),

  .xgmii_1_txd(xgmii1_txd),
  .xgmii_1_txc(xgmii1_txc),
  .xgmii_1_rxd(xgmii1_rxd),
  .xgmii_1_rxc(xgmii1_rxc),

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
  .tx0_ipv4_dstip(tx0_ipv4_dstip),
  .tx0_pps(tx0_pps),
  .tx0_throughput(tx0_throughput),
  .tx0_ipv4_ip(tx0_ipv4_ip),

  .rx1_pps(rx1_pps),
  .rx1_throughput(rx1_throughput),
  .rx1_latency(rx1_latency),
  .rx1_ipv4_ip(rx1_ipv4_ip),

  .global_counter(global_counter),
  .count_2976_latency(count_2976_latency)
);


assign led[0] = xphy0_status[0]; 
assign led[1] = xphy1_status[0]; 
assign led[2] = 1'b0; 
assign led[3] = 1'b0; 
assign led[4] = 1'b0;
assign led[5] = 1'b0;
assign led[6] = 1'b0;
assign led[7] = 1'b0;

//- Tie off related to SFP+
assign sfp_tx_disable = 5'b10000;	// all ports enable

//- This LED indicates FMC connected OK
assign fmc_ok_led = 1'b1;
//- This LED indicates FMC GBTCLK0 programmed OK
assign fmc_clk_312_5 = (fmc_gbtclk0_fsel == 2'b11) ? 1'b1 : 1'b0;

endmodule
