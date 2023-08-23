`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 00:51:04
// Design Name: 
// Module Name: eth_test_top
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


module eth_test_top(
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
              
    wire         rgmii_clk;        
    wire         rgmii_clk_90p; 
    wire         mac_rx_data_valid;
    wire [7:0]   mac_rx_data;    
    wire         mac_data_valid;  
    wire  [7:0]  mac_tx_data;  
    reg          arp_req;
    
    wire clk_125m;
    wire clk_200m;
    ref_clock ref_clock(
        .clkout0 ( clk_200m  ), // output clk_out1
        .clkout1 ( clk_125m  ), // output clk_out2
        .pll_lock( rstn      ), // output locked
        .clkin1  ( clk_40m   )  // input clk_in1
    );
assign phy_rstn = rstn;
    wire               udp_rec_data_valid;
    wire [7:0]         udp_rec_rdata ;    
    wire [15:0]        udp_rec_data_length;
    
    wire [55:0] ack_data;
    eth_udp_test eth_udp_test(
        .rgmii_clk              (  rgmii_clk            ),//input                rgmii_clk,
        .rstn                   (  rstn                 ),//input                rstn,
        .gmii_rx_dv             (  mac_rx_data_valid    ),//input                gmii_rx_dv,
        .gmii_rxd               (  mac_rx_data          ),//input  [7:0]         gmii_rxd,
        .gmii_tx_en             (  mac_data_valid       ),//output reg           gmii_tx_en,
        .gmii_txd               (  mac_tx_data          ),//output reg [7:0]     gmii_txd,
        .ack_data               (ack_data),
                                                      
        .udp_rec_data_valid     (  udp_rec_data_valid   ),//output               udp_rec_data_valid,         
        .udp_rec_rdata          (  udp_rec_rdata        ),//output [7:0]         udp_rec_rdata ,             
        .udp_rec_data_length    (  udp_rec_data_length  ) //output [15:0]        udp_rec_data_length         
    );

gen_pix gen_pix(
    .rgmii_rxc               (rgmii_rxc) ,
    .rstn                    (rstn) ,
    .udp_rec_data_valid      (udp_rec_data_valid) ,
    .udp_rec_rdata           (udp_rec_rdata),
    .udp_rec_data_length     (udp_rec_data_length  ),
    .ack_data                (ack_data)
);
    
    wire        arp_found;
    wire        mac_not_exist;
    wire [7:0]  state;
    
    rgmii_interface rgmii_interface(
        .rst                       (  ~rstn              ),//input        rst,
        .rgmii_clk                 (  rgmii_clk          ),//output       rgmii_clk,
        .rgmii_clk_90p             (  rgmii_clk_90p      ),//input        rgmii_clk_90p,
  
        .mac_tx_data_valid         (  mac_data_valid     ),//input        mac_tx_data_valid,
        .mac_tx_data               (  mac_tx_data        ),//input [7:0]  mac_tx_data,
    
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

assign led =  (udp_rec_data_valid== 1'b1 ? (|udp_rec_rdata) : (&udp_rec_data_length));
endmodule
