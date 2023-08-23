`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/02 11:14:02
// Design Name: 
// Module Name: rgmii_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rgmii_test(
    input        clk_40m,
    output       led,
    output       phy_rstn,

    input        rgmii_rxc,
    input        rgmii_rx_ctl,
    input [3:0]  rgmii_rxd,
                 
    output       rgmii_txc,
    output       rgmii_tx_ctl,
    output [3:0] rgmii_txd 
);
    
    wire       rst;              
    wire       rgmii_clk;        
    wire       rgmii_clk_90p;       
   
    wire       mac_rx_data_valid;
    wire [7:0] mac_rx_data;      

    eth_clock eth_clock(
        // Clock out ports
        .clk_out1          (  rgmii_clk_90p  ),// output clk_out1           
        .locked            (  rstn           ),// output locked             
        .clk_in1           (  rgmii_clk      ) // input clk_in1             
    );
    
    wire clk_125m;
    wire clk_200m;
    wire locked;
    wire idelayctrl_rdy;
    reg  idelay_ctl_rst;
    reg  [3:0] setup_cnt=4'hF;
    ref_clock ref_clock(
        // Clock out ports
        .clk_out1 ( clk_200m  ), // output clk_out1
        .clk_out2 ( clk_125m  ), // output clk_out2
        .locked   ( locked    ), // output locked
        .clk_in1  ( clk_40m   )  // input clk_in1
    );
    
    always @(posedge clk_200m)
    begin
        if(~locked)
            setup_cnt <= 4'd0;
        else
        begin
            if(setup_cnt == 4'hF)
                setup_cnt <= setup_cnt;
            else
                setup_cnt <= setup_cnt + 1'b1;
        end
    end
    
    always @(posedge clk_200m)
    begin
        if(~locked)
            idelay_ctl_rst <= 1'b1;
        else if(setup_cnt == 4'hF)
            idelay_ctl_rst <= 1'b0;
        else
            idelay_ctl_rst <= 1'b1;
    end
    
   // An IDELAYCTRL primitive needs to be instantiated for the Fixed Tap Delay
   // mode of the IDELAY.
   IDELAYCTRL  #(
      .SIM_DEVICE (  "7SERIES"    )
   ) idelayctrl_inst(
      .RDY        (  idelayctrl_rdy ),
      .REFCLK     (  clk_200m       ),
      .RST        (  idelay_ctl_rst )
   );
    
    rgmii_ila rgmii_ila (
    	.clk     (  clk_125m           ),// input wire clk
                                       
    	.probe0  (  mac_rx_data_valid  ),// input wire [0:0]  probe0  
    	.probe1  (  mac_rx_data        ) // input wire [7:0]  probe1
    );
    
    rgmii_interface rgmii_interface(
        .rst                       (  ~rstn              ),//input        rst,
        .rgmii_clk                 (  rgmii_clk          ),//output       rgmii_clk,
        .rgmii_clk_90p             (  rgmii_clk_90p      ),//input        rgmii_clk_90p,
  
        .mac_tx_data_valid         (  1'b0               ),//input        mac_tx_data_valid,
        .mac_tx_data               (  8'hff              ),//input [7:0]  mac_tx_data,
    
        .mac_rx_error              (                     ),//output       mac_rx_error,
        .mac_rx_data_valid         (  mac_rx_data_valid  ),//output       mac_rx_data_valid,
        .mac_rx_data               (  mac_rx_data        ),//output [7:0] mac_rx_data,
                                                         
        .rgmii_rxc                 (  rgmii_rxc          ),//input        rgmii_rxc,
        .rgmii_rx_ctl              (  rgmii_rx_ctl       ),//input        rgmii_rx_ctl,
        .rgmii_rxd                 (  rgmii_rxd          ),//input [3:0]  rgmii_rxd,
                                                         
        .rgmii_txc                 (  rgmii_txc          ),//output       rgmii_txc,
        .rgmii_tx_ctl              (  rgmii_tx_ctl       ),//output       rgmii_tx_ctl,
        .rgmii_txd                 (  rgmii_txd          ) //output [3:0] rgmii_txd 
    );
    
    assign led = mac_rx_data_valid== 1'b1 ? (|mac_rx_data) : (&mac_rx_data);
    assign phy_rstn = locked;
    
endmodule
