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



reg [31:0] tx_counter;
reg [63:0] txd;
reg [7:0] txc;
always @(posedge clk156) begin
        if ( sys_rst ) begin
                tx_counter <= 32'h0;
                txd <= 64'h0707070707070707;
                txc <= 8'hff;
        end else begin
                tx_counter <= tx_counter + 32'h8;
                case (tx_counter[15:0] )
                        16'h00: {txc, txd} <= {8'h01, 64'hd5_55_55_55_55_55_55_fb};
                        16'h08: {txc, txd} <= {8'h00, 64'hde_a0_00_d6_7b_1d_25_11};
                        16'h10: {txc, txd} <= {8'h00, 64'h00_00_45_00_08_e8_07_1c};
                        16'h18: {txc, txd} <= {8'h00, 64'h44_01_40_00_00_99_f8_54};
                        16'h20: {txc, txd} <= {8'h00, 64'h16_00_0a_69_15_00_0a_9d};
                        16'h28: {txc, txd} <= {8'h00, 64'h00_07_b8_45_d5_00_08_64};
                        16'h30: {txc, txd} <= {8'h00, 64'hab_05_00_06_84_ac_4f_07};
                        16'h38: {txc, txd} <= {8'h00, 64'h0e_0d_0c_0b_0a_09_08_f0};
                        16'h40: {txc, txd} <= {8'h00, 64'h16_15_14_13_12_11_10_0f};
                        16'h48: {txc, txd} <= {8'h00, 64'h1e_1d_1c_1b_1a_19_18_17};
                        16'h50: {txc, txd} <= {8'h00, 64'h26_25_24_23_22_21_20_1f};
                        16'h58: {txc, txd} <= {8'h00, 64'h2e_2d_2c_2b_2a_29_28_27};
                        16'h60: {txc, txd} <= {8'h00, 64'h36_35_34_33_32_31_30_2f};
                        16'h68: {txc, txd} <= {8'he0, 64'h07_07_fd_ba_fc_4f_47_37};
                        default: begin
                                {txc, txd} <= {8'hff, 64'h07_07_07_07_07_07_07_07};
                        end
                endcase
        end
end


assign xgmii0_txd = txd;
assign xgmii0_txc = txc;
assign xgmii1_txd = txd;
assign xgmii1_txc = txc;


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
