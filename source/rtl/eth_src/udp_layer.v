`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/16 23:31:11
// Design Name: 
// Module Name: udp_layer
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


module udp_layer #(
    parameter LOCAL_PORT_NUM = 16'hf000,    //Դ�˿ں�
    parameter       LOCAL_IP  = 32'hC0_A8_01_6E, 
    parameter       DEST_IP   = 32'hC0_A8_01_6D
) (
    input              udp_send_clk,      //ʱ���ź�                                                                                                                                                                                                                                                                                                                                                                
    input              rstn,              //��λ�źţ��͵�ƽ��Ч                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                    
    //from software app                                                                                                                                                                                                                                                                                                                                                                                             
    input              app_data_in_valid, //��ģ����ⲿ�����յ����������Ч�źţ��ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                        
    input      [7:0]   app_data_in,       //��ģ����ⲿ�����յ��������                                                                                                                                                                                                                                                                                                                                            
    input      [15:0]  app_data_length,   //��ģ����ⲿ�����յĵ�ǰ���ݰ��ĳ��ȣ�����udp��ip��mac �ײ�������λ���ֽ�                                                                                                                                                                                                                                                                                               
    input      [15:0]  udp_dest_port,     //��ģ����ⲿ�����յ����ݰ���Դ�˿ں�                                                                                                                                                                                                                                                                                                                                    
    input              app_data_request,  //�û��ӿ����ݷ������󣬸ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                    
    output             udp_send_ready,    //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
    output             udp_send_ack,      //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                                                                                    
    input              ip_send_ready,     //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
    input              ip_send_ack,       //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
    //to IP_send                                                                                                                                                                                                                                                                                                                                                                                                    
    output             udp_send_request,  //�û��ӿ����ݷ������󣬸ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                        
    output             udp_data_out_valid,//���͵����������Ч�źţ��ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                      
    output     [7:0]   udp_data_out,      //���͵��������                                                                                                                                                                                                                                                                                                                                                          
    output     [15:0]  udp_packet_length, //��ǰ���ݰ��ĳ��ȣ�����udp��ip��mac �ײ�������λ���ֽ�  
    
    input      [7:0]   udp_rx_data,
    input              udp_rx_req,
    
    input              ip_checksum_error,
    input              ip_addr_check_error,
    
    output     [7:0]   udp_rec_rdata ,      //udp ram read data
    output     [15:0]  udp_rec_data_length, //udp data length
    output             udp_rec_data_vld_for_send,
    output             udp_rec_data_valid   //udp data valid
);
    
    udp_tx #(
        .LOCAL_PORT_NUM        (  LOCAL_PORT_NUM      ) //parameter LOCAL_PORT_NUM = 16'hf000    //Դ�˿ں�
    ) udp_tx(
        .udp_send_clk          (  udp_send_clk        ),//input wire         udp_send_clk,      //ʱ���ź�                                                                                                                                                                                                                                                                                                                                                                
        .rstn                  (  rstn                ),//input wire         rstn,              //��λ�źţ��͵�ƽ��Ч                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                           
        //from software app                                                                                                                                                                                                                                                                                                                                                                                             
        .app_data_in_valid     (  app_data_in_valid   ),//input wire         app_data_in_valid, //��ģ����ⲿ�����յ����������Ч�źţ��ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                        
        .app_data_in           (  app_data_in         ),//input wire [7:0]   app_data_in,       //��ģ����ⲿ�����յ��������                                                                                                                                                                                                                                                                                                                                            
        .app_data_length       (  app_data_length     ),//input wire [15:0]  app_data_length,   //��ģ����ⲿ�����յĵ�ǰ���ݰ��ĳ��ȣ�����udp��ip��mac �ײ�������λ���ֽ�                                                                                                                                                                                                                                                                                               
        .udp_dest_port         (  udp_dest_port       ),//input wire [15:0]  udp_dest_port,     //��ģ����ⲿ�����յ����ݰ���Դ�˿ں�                                                                                                                                                                                                                                                                                                                                    
        .app_data_request      (  app_data_request    ),//input wire         app_data_request,  //�û��ӿ����ݷ������󣬸ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                                                          
        .udp_send_ready        (  udp_send_ready      ),//output wire        udp_send_ready,    //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
        .udp_send_ack          (  udp_send_ack        ),//output wire        udp_send_ack,      //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                                                                                                                           
        .ip_send_ready         (  ip_send_ready       ),//input wire         ip_send_ready,     //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
        .ip_send_ack           (  ip_send_ack         ),//input wire         ip_send_ack,       //�����ǻ��� ready��request��ack�����ź���ʵ�ֵ�                                                                                                                                                                                                                                                                                                                          
        //to IP_send                                                                                                                                                                                                                                                                                                                                                                                                    
        .udp_send_request      (  udp_send_request    ),//output wire        udp_send_request,  //�û��ӿ����ݷ������󣬸ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                        
        .udp_data_out_valid    (  udp_data_out_valid  ),//output reg         udp_data_out_valid,//���͵����������Ч�źţ��ߵ�ƽ��Ч                                                                                                                                                                                                                                                                                                                                      
        .udp_data_out          (  udp_data_out        ),//output reg [7:0]   udp_data_out,      //���͵��������                                                                                                                                                                                                                                                                                                                                                          
        .udp_packet_length     (  udp_packet_length   ) //output reg [15:0]  udp_packet_length  //��ǰ���ݰ��ĳ��ȣ�����udp��ip��mac �ײ�������λ���ֽ�                                                                                                                                                                                                                                                                                                                   
    );
    
    udp_rx #(
        .LOCAL_PORT_NUM          (  LOCAL_PORT_NUM      ), //parameter LOCAL_PORT = 16'hf000    //Դ�˿ں�
        .LOCAL_IP                (  LOCAL_IP            ),
        .DEST_IP                 (  DEST_IP             )
    )udp_rx (
        .clk                   (  udp_send_clk        ),//input                  clk,   
        .rstn                  (  rstn                ),//input                  rstn,  
                                                      
        .udp_rx_data           (  udp_rx_data         ),//input      [7:0]       udp_rx_data,
        .udp_rx_req            (  udp_rx_req          ),//input                  udp_rx_req,
                                                      
        .ip_checksum_error     (  ip_checksum_error   ),//input                  ip_checksum_error,
        .ip_addr_check_error   (  ip_addr_check_error ),//input                  ip_addr_check_error,
                                                      
        .udp_rec_rdata         (  udp_rec_rdata       ),//output     [7:0]       udp_rec_rdata ,      //udp ram read data
        .udp_rec_data_length   (  udp_rec_data_length ),//output reg [15:0]      udp_rec_data_length,     //udp data length
        .udp_rec_data_vld_for_send(udp_rec_data_vld_for_send),
        .udp_rec_data_valid    (  udp_rec_data_valid  ) //output reg             udp_rec_data_valid       //udp data valid
    );
    
endmodule
