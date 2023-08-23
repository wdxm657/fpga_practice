

module gmii2rgmii (
    output reg      led,
    input           rgmii_rxc,//add
    input           reset,
    output  [ 3:0]  rgmii_td,
    output          rgmii_tx_ctl,
    output          rgmii_txc,
    
    input   [ 3:0]  rgmii_rd,
    input           rgmii_rx_ctl,
    output          gmii_rx_clk,
    
    input   [ 7:0]  gmii_txd,
    input           gmii_tx_en,
    input           gmii_tx_er,
    output          gmii_tx_clk,
    
    output  [ 7:0]  gmii_rxd,
    output          gmii_rx_dv,
    output          gmii_rx_er,
    input  [ 1:0]   speed_selection, // 1x gigabit, 01 100Mbps, 00 10mbps
    input           duplex_mode      // 1 full, 0 half
);
  
  wire gigabit;
  wire gmii_tx_clk_s;
  wire gmii_rx_dv_s;

  wire  [ 7:0]    gmii_rxd_s;
  wire            rgmii_rx_ctl_delay;
  wire            rgmii_rx_ctl_s;
  // registers
  reg             tx_reset_d1;
  reg             tx_reset_sync;
  reg             rx_reset_d1;
  reg   [ 7:0]    gmii_txd_r;
  reg             gmii_tx_en_r;
  reg             gmii_tx_er_r;
  reg   [ 7:0]    gmii_txd_r_d1;
  reg             gmii_tx_en_r_d1;
  reg             gmii_tx_er_r_d1;

  reg             rgmii_tx_ctl_r;
  reg   [ 3:0]    gmii_txd_low;
  reg             gmii_col;
  reg             gmii_crs;

  reg  [ 7:0]     gmii_rxd;
  reg             gmii_rx_dv;
  reg             gmii_rx_er;
  wire         padt1     ;
  wire         padt2     ;
  wire         padt3     ;
  wire         padt4     ;
  wire         padt5     ;
  wire         padt6    ;
  wire         stx_txc   ;
  wire         stx_ctr   ;
  wire  [3:0]  stxd_rgm  ;
  assign gigabit        = speed_selection [1];
 assign gmii_tx_clk    = gmii_tx_clk_s;
  assign gmii_tx_clk_s  = gmii_rx_clk;

//test led
reg[28:0] cnt_timer;
  always @(posedge gmii_tx_clk_s)
  begin
  cnt_timer<=cnt_timer+1'b1;
if( cnt_timer==29'h3ffffff)
begin
   led=~led;
    cnt_timer<=29'h0;
end
  end

wire gmii_rx_clk;


GTP_CLKBUFG GTP_CLKBUFG_RXSHFT(
    .CLKIN     (rgmii_rxc),
    .CLKOUT    (gmii_rx_clk)
);

//assign gmii_rx_clk=rgmii_rxc;
  always @(posedge gmii_rx_clk)
  begin
    gmii_rxd       = gmii_rxd_s;
    gmii_rx_dv     = gmii_rx_dv_s;
    gmii_rx_er     = gmii_rx_dv_s ^ rgmii_rx_ctl_s;
  end

  always @(posedge gmii_tx_clk_s) begin
    tx_reset_d1    <= reset;
    tx_reset_sync  <= tx_reset_d1;
  end

  always @(posedge gmii_tx_clk_s)
  begin
      rgmii_tx_ctl_r <= gmii_tx_en_r ^ gmii_tx_er_r;
      gmii_txd_low   <= gigabit ? gmii_txd_r[7:4] :  gmii_txd_r[3:0];
  end

    always @(posedge gmii_tx_clk_s) begin
//        if (tx_reset_sync == 1'b1) begin
//            gmii_txd_r   <= 8'h0;
//            gmii_tx_en_r <= 1'b0;
//            gmii_tx_er_r <= 1'b0;
//        end
//        else
//        begin
            gmii_txd_r   <= gmii_txd;
            gmii_tx_en_r <= gmii_tx_en;
            gmii_tx_er_r <= gmii_tx_er;
            gmii_txd_r_d1   <= gmii_txd_r;
            gmii_tx_en_r_d1 <= gmii_tx_en_r;
            gmii_tx_er_r_d1 <= gmii_tx_er_r;
//        end
    end

    generate 
        genvar i;
        for (i=0; i<4; i=i+1) 
        begin : rgmii_tx_data
            GTP_OSERDES_E2 #(
                .GRS_EN ("TRUE"),
                .OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
                .TSERDES_EN ("FALSE"),
                .UPD0_SHIFT_EN ("FALSE"), 
                .UPD1_SHIFT_EN ("FALSE"), 
                .INIT_SET (2'b00), 
                .GRS_TYPE_DQ ("RESET"), 
                .LRS_TYPE_DQ0 ("ASYNC_RESET"), 
                .LRS_TYPE_DQ1 ("ASYNC_RESET"), 
                .LRS_TYPE_DQ2 ("ASYNC_RESET"), 
                .LRS_TYPE_DQ3 ("ASYNC_RESET"), 
                .GRS_TYPE_TQ ("RESET"), 
                .LRS_TYPE_TQ0 ("ASYNC_RESET"), 
                .LRS_TYPE_TQ1 ("ASYNC_RESET"), 
                .LRS_TYPE_TQ2 ("ASYNC_RESET"), 
                .LRS_TYPE_TQ3 ("ASYNC_RESET"), 
                .TRI_EN  ("FALSE"),
                .TBYTE_EN ("FALSE"), 
                .MIPI_EN ("FALSE"), 
                .OCASCADE_EN ("FALSE")
            ) GTP_OSERDES_E2_INST1 (
                .RST (tx_reset_sync),
                .OCE (1'b1),
                .TCE (1'b0),
                .OCLKDIV (gmii_tx_clk_s),
                .SERCLK (gmii_tx_clk_s),
                .OCLK (gmii_tx_clk_s),
                .MIPI_CTRL (),
                .UPD0_SHIFT (1'b0),
                .UPD1_SHIFT (1'b0),
                .OSHIFTIN0 (),
                .OSHIFTIN1 (),
                .DI ({6'd0,gmii_txd_low[i],gmii_txd_r_d1[i]}),    // DDR capture data
                .TI (),
                .TBYTE_IN (),
                .OSHIFTOUT0 (),
                .OSHIFTOUT1 (),
                .DO (stxd_rgm[i]),
                .TQ (padt2)
            );
               
            GTP_OUTBUF  gtp_outbuf2
            (
                
                .I(stxd_rgm[i]),     
                .O(rgmii_td[i])        
            );
        end
    endgenerate

    //------------------------------------
    GTP_OSERDES_E2 #(
        .GRS_EN ("TRUE"),
        .OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
        .TSERDES_EN ("FALSE"),
        .UPD0_SHIFT_EN ("FALSE"), 
        .UPD1_SHIFT_EN ("FALSE"), 
        .INIT_SET (2'b00), 
        .GRS_TYPE_DQ ("RESET"), 
        .LRS_TYPE_DQ0 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ1 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ2 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ3 ("ASYNC_RESET"), 
        .GRS_TYPE_TQ ("RESET"), 
        .LRS_TYPE_TQ0 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ1 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ2 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ3 ("ASYNC_RESET"), 
        .TRI_EN  ("FALSE"),
        .TBYTE_EN ("FALSE"), 
        .MIPI_EN ("FALSE"), 
        .OCASCADE_EN ("FALSE")
    ) GTP_OSERDES_E2_INST0 (
        .RST (tx_reset_sync),
        .OCE (1'b1),
        .TCE (1'b0),
        .OCLKDIV (gmii_tx_clk_s),
        .SERCLK (gmii_tx_clk_s),
        .OCLK (gmii_tx_clk_s),
        .MIPI_CTRL (),
        .UPD0_SHIFT (1'b0),
        .UPD1_SHIFT (1'b0),
        .OSHIFTIN0 (),
        .OSHIFTIN1 (),
        .DI ({6'd0,rgmii_tx_ctl_r,gmii_tx_en_r_d1}),
        .TI (),
        .TBYTE_IN (),
        .OSHIFTOUT0 (),
        .OSHIFTOUT1 (),
        .DO (stx_ctr),
        .TQ (padt1)
    );
    
    
    GTP_OUTBUF  gtp_outbuf1(
        .I(stx_ctr),     
        .O(rgmii_tx_ctl)        
    );
    //-----------------------------
    GTP_OSERDES_E2 #
    (
        .GRS_EN ("TRUE"),
        .OSERDES_MODE ("DDR2TO1_SAME_EDGE"),
        .TSERDES_EN ("FALSE"),
        .UPD0_SHIFT_EN ("FALSE"), 
        .UPD1_SHIFT_EN ("FALSE"), 
        .INIT_SET (2'b00), 
        .GRS_TYPE_DQ ("RESET"), 
        .LRS_TYPE_DQ0 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ1 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ2 ("ASYNC_RESET"), 
        .LRS_TYPE_DQ3 ("ASYNC_RESET"), 
        .GRS_TYPE_TQ ("RESET"), 
        .LRS_TYPE_TQ0 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ1 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ2 ("ASYNC_RESET"), 
        .LRS_TYPE_TQ3 ("ASYNC_RESET"), 
        .TRI_EN  ("FALSE"),
        .TBYTE_EN ("FALSE"), 
        .MIPI_EN ("FALSE"), 
        .OCASCADE_EN ("FALSE")
    ) GTP_OSERDES_E2_INST5 (
        .RST (tx_reset_sync),
        .OCE (1'b1),
        .TCE (1'b0),
        .OCLKDIV (gmii_tx_clk_s),
        .SERCLK (gmii_tx_clk_s),
        .OCLK (gmii_tx_clk_s),
        .MIPI_CTRL (),
        .UPD0_SHIFT (1'b0),
        .UPD1_SHIFT (1'b0),
        .OSHIFTIN0 (),
        .OSHIFTIN1 (),
        .DI (8'b00000001),    
        .TI (),
        .TBYTE_IN (),
        .OSHIFTOUT0 (),
        .OSHIFTOUT1 (),
        .DO (stx_txc),
        .TQ (padt6)
    );
    
    
    wire [7:0] delay_step_b ;
    wire [7:0] delay_step_gray ;
    
    assign delay_step_b = 8'd0;   // 0~247 , 10ps/step
    
    assign delay_step_gray=((delay_step_b>>1)^delay_step_b);  // only support gray code
    
    GTP_IODELAY_E2 #(
        .DELAY_STEP_SEL ("PORT"),//PORT PARAMETER
        .DELAY_STEP_VALUE( )
    ) GTP_IODELAY_E2_inst0 (
        .DI (stx_txc),                     // rx clk input 
        .DELAY_SEL (1'b1),
        .DELAY_STEP (delay_step_gray),
        .DO (rgmii_txc) ,           // rx clk output
        .EN_N(1'b0)       // INPUT  
    );

    //---------------------------------------
    wire [23:0] rxd_nc;
    generate 
        genvar j;
        for (j=0; j<4; j=j+1)
        begin : rgmii_rx_data

            GTP_ISERDES_E2 #(
                .ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
                .CASCADE_MODE("MASTER"),
                .BITSLIP_EN("FALSE"),
                .GRS_EN ("TRUE"),
                .NUM_ICE(1'b0),
                .GRS_TYPE_Q0("RESET"),
                .GRS_TYPE_Q1("RESET"),
                .GRS_TYPE_Q2("RESET"),
                .GRS_TYPE_Q3("RESET"),
                .LRS_TYPE_Q0("ASYNC_RESET"),
                .LRS_TYPE_Q1("ASYNC_RESET"),
                .LRS_TYPE_Q2("ASYNC_RESET"),
                .LRS_TYPE_Q3("ASYNC_RESET")
           ) gtp_iserdes_inst3 (
                .RST(1'b0),
                .ICE0(1'b1),
                .ICE1(1'b0),
                .DESCLK (gmii_rx_clk),
                .ICLK (gmii_rx_clk),
                .ICLKDIV(gmii_rx_clk),
                .DI (rgmii_rd[j]),
                .BITSLIP(),
                .ISHIFTIN0(),
                .ISHIFTIN1(),
                .IFIFO_WADDR(),
                .IFIFO_RADDR(),
                .DO ({rxd_nc[j*6 +: 6],gmii_rxd_s[j+4],gmii_rxd_s[j]}),
                .ISHIFTOUT0(),
                .ISHIFTOUT1()
            );
        end
    endgenerate

    //------------------------------------------
    wire [5:0] nc5;
    GTP_ISERDES_E2 #(
        .ISERDES_MODE ("DDR1TO2_SAME_PIPELINED"), 
        .CASCADE_MODE("MASTER"),
        .BITSLIP_EN("FALSE"),
        .GRS_EN ("TRUE"),
        .NUM_ICE(1'b0),
        .GRS_TYPE_Q0("RESET"),
        .GRS_TYPE_Q1("RESET"),
        .GRS_TYPE_Q2("RESET"),
        .GRS_TYPE_Q3("RESET"),
        .LRS_TYPE_Q0("ASYNC_RESET"),
        .LRS_TYPE_Q1("ASYNC_RESET"),
        .LRS_TYPE_Q2("ASYNC_RESET"),
        .LRS_TYPE_Q3("ASYNC_RESET")
    ) gtp_iserdes_inst4 (
        .RST(1'b0),
        .ICE0(1'b1),
        .ICE1(1'b0),
        .DESCLK (gmii_rx_clk),
        .ICLK (gmii_rx_clk),
        .ICLKDIV(gmii_rx_clk),
        .DI (rgmii_rx_ctl),
        .BITSLIP(),
        .ISHIFTIN0(),
        .ISHIFTIN1(),
        .IFIFO_WADDR(),
        .IFIFO_RADDR(),
        .DO ({nc5,rgmii_rx_ctl_s,gmii_rx_dv_s}),
        .ISHIFTOUT0(),
        .ISHIFTOUT1()
    );
endmodule