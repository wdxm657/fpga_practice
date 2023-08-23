`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/01 22:01:53
// Design Name: 
// Module Name: ip_rx
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

module arp_tx(
    input                clk             ,                 
    input                rstn            ,                 
    
    input  [47:0]        sour_mac_addr   , //source mac address          
    input  [31:0]        sour_ip_addr    , //source ip address  
    
    //arp master request control
    input  [47:0]        dest_mac_addr   , //destination mac address         
    input  [31:0]        dest_ip_addr    , //destination ip address
    input                arp_request_req,         //arp request
    
    //arp rx connect
    input                arp_reply_req,           //arp reply request from arp rx module
    output reg           arp_reply_ack,           //arp reply ack to arp rx module
    input  [31:0]        arp_rec_sour_ip_addr,
    input  [47:0]        arp_rec_sour_mac_addr ,
    
    //mac tx connect
    input                mac_data_req,            //mac layer request data
    output reg           arp_tx_req,
    input                mac_send_end,
    input                mac_tx_ack,
    output reg           arp_tx_ready,
    output reg [7:0]     arp_tx_data,
    output reg           arp_tx_end
) ;
       
    localparam MAC_TYPE         = 16'h0806 ;
    localparam HARDWARE_TYPE    = 16'h0001 ;
    localparam PROTOCOL_TYPE    = 16'h0800 ;
    localparam MAC_LENGTH       = 8'h06    ;
    localparam IP_LENGTH        = 8'h04    ;
    
    localparam ARP_REQUEST_CODE = 16'h0001 ;
    localparam ARP_REPLY_CODE   = 16'h0002 ;
    
    reg  [15:0]        op ;
    
    reg  [31:0]        arp_dest_ip_addr ;
    reg  [47:0]        arp_dest_mac_addr  ;
    reg  [15:0]        arp_send_cnt ;
    reg  [15:0]        timeout ;
    reg                mac_send_end_d0 ;
    
    parameter IDLE               = 8'b00000001 ;
    parameter ARP_REQUEST_WAIT_0 = 8'b00000010 ;
    parameter ARP_REQUEST_WAIT_1 = 8'b00000100 ;
    parameter ARP_REQUEST        = 8'b00001000 ;
    parameter ARP_REPLY_WAIT_0   = 8'b00010000 ;
    parameter ARP_REPLY_WAIT_1   = 8'b00100000 ;
    parameter ARP_REPLY          = 8'b01000000 ;
    parameter ARP_END            = 8'b10000000 ;
    
    reg [7:0]    state  ;
    reg [7:0]    next_state ;
    
    always @(posedge clk)
    begin
        if (~rstn)
            state  <=  IDLE  ;
        else
            state  <= next_state ;
    end
      
    always @(*)
    begin
        case(state)
            IDLE             :
            begin
                if (arp_request_req)
                    next_state = ARP_REQUEST_WAIT_0 ;
                else if (arp_reply_req)
                    next_state = ARP_REPLY_WAIT_0  ;
                else
                    next_state = IDLE ;
            end
    	    ARP_REQUEST_WAIT_0 :
            begin
                if (mac_tx_ack)
                    next_state = ARP_REQUEST_WAIT_1     ;
                else
                    next_state = ARP_REQUEST_WAIT_0 ;
            end
            ARP_REQUEST_WAIT_1 :
            begin
                if (mac_data_req)
                    next_state = ARP_REQUEST     ;
                else if (timeout == 16'hffff)
                    next_state = IDLE ;
                else
                    next_state = ARP_REQUEST_WAIT_1 ;
            end
            ARP_REQUEST      :
            begin
                if (arp_tx_end)
                    next_state = ARP_END     ;
                else
                    next_state = ARP_REQUEST ;
            end
    	    ARP_REPLY_WAIT_0   :
            begin
                if (mac_tx_ack)
                    next_state = ARP_REPLY_WAIT_1     ;
                else
                    next_state = ARP_REPLY_WAIT_0 ;
            end
            ARP_REPLY_WAIT_1   :
            begin
                if (mac_data_req)
                    next_state = ARP_REPLY     ;
                else if (timeout == 16'hffff)
                    next_state = IDLE ;
                else
                    next_state = ARP_REPLY_WAIT_1 ;
            end
            ARP_REPLY        :
            begin
                if (arp_tx_end)
                    next_state = ARP_END ;
                else
                    next_state = ARP_REPLY ;
            end
    	    ARP_END :
    		begin
                if (mac_send_end_d0)
                    next_state = IDLE ;
                else
                    next_state = ARP_END ;
            end
            default          :
                next_state = IDLE ;
        endcase
    end
     
    always @(posedge clk)
    begin
        if (~rstn)
            mac_send_end_d0 <= 1'b0 ;
        else 
            mac_send_end_d0 <= mac_send_end ;
    end  
     
     always @(posedge clk)
    begin
        if (~rstn)
            arp_tx_req <= 1'b0 ;
        else if (state == ARP_REQUEST_WAIT_0 || state == ARP_REPLY_WAIT_0)
            arp_tx_req <= 1'b1  ;
        else
            arp_tx_req <= 1'b0 ;
    end 
      
    always @(posedge clk)
    begin
        if (~rstn)
            op <= 16'd0 ;
        else if (state == ARP_REPLY)
            op <= ARP_REPLY_CODE  ;
        else
            op <= ARP_REQUEST_CODE ;
    end
      
    always @(posedge clk)
    begin
        if (~rstn)
            arp_tx_ready <= 1'b0 ;
        else if (state == ARP_REQUEST_WAIT_1 || state == ARP_REPLY_WAIT_1)
            arp_tx_ready <= 1'b1 ;
        else
            arp_tx_ready <= 1'b0 ;
    end
      
    always @(posedge clk)
    begin
        if (~rstn)
            arp_tx_end <= 1'b0 ;
        else if ((state == ARP_REQUEST && arp_send_cnt == 13 + 46 ) || (state == ARP_REPLY && arp_send_cnt == 13 + 46 ))
            arp_tx_end <= 1'b1 ;
        else
            arp_tx_end <= 1'b0 ;
    end
 
    //timeout counter
    always @(posedge clk)
    begin
        if (~rstn)
            timeout <= 16'd0 ;
        else if (state == ARP_REQUEST_WAIT_1 || state == ARP_REPLY_WAIT_1)
            timeout <= timeout + 1'b1 ;
        else
            timeout <= 16'd0 ;
    end
     
    always @(posedge clk)
    begin
        if (~rstn)
            arp_dest_ip_addr  <=  32'd0  ;
        else if (state == ARP_REQUEST_WAIT_1)
            arp_dest_ip_addr  <= dest_ip_addr ;
        else if (state == ARP_REPLY_WAIT_1)
            arp_dest_ip_addr  <= arp_rec_sour_ip_addr ;
    end
      
    always @(posedge clk)
    begin
        if (~rstn)
            arp_dest_mac_addr  <=  48'd0  ;
        else if (state == ARP_REQUEST_WAIT_1)
            arp_dest_mac_addr  <= dest_mac_addr ;
        else if (state == ARP_REPLY_WAIT_1)
            arp_dest_mac_addr  <= arp_rec_sour_mac_addr ;
    end
      
    always @(posedge clk)
    begin
        if (~rstn)
            arp_reply_ack  <=  1'b0 ;
        else if (state == ARP_REPLY_WAIT_1)
            arp_reply_ack  <= 1'b1 ;
        else
            arp_reply_ack  <=  1'b0 ;
    end

    always @(posedge clk)
    begin
        if (~rstn)
            arp_send_cnt  <= 16'd0 ;
        else if (state == ARP_REQUEST || state == ARP_REPLY)
            arp_send_cnt <= arp_send_cnt + 1'b1 ;
        else
            arp_send_cnt <= 16'd0 ;
    end

    always @(posedge clk)
    begin
        if (~rstn)
            arp_tx_data <= 8'd0 ;
        else if(state == ARP_REQUEST || state == ARP_REPLY)
        begin
            case(arp_send_cnt)
                16'd0   :  arp_tx_data <= arp_dest_mac_addr[47:40];
                16'd1   :  arp_tx_data <= arp_dest_mac_addr[39:32];
                16'd2   :  arp_tx_data <= arp_dest_mac_addr[31:24];
                16'd3   :  arp_tx_data <= arp_dest_mac_addr[23:16];
                16'd4   :  arp_tx_data <= arp_dest_mac_addr[15:8] ;
                16'd5   :  arp_tx_data <= arp_dest_mac_addr[7:0]  ;
                16'd6   :  arp_tx_data <= sour_mac_addr[47:40]    ;
                16'd7   :  arp_tx_data <= sour_mac_addr[39:32]    ;
                16'd8   :  arp_tx_data <= sour_mac_addr[31:24]    ;
                16'd9   :  arp_tx_data <= sour_mac_addr[23:16]    ;
                16'd10  :  arp_tx_data <= sour_mac_addr[15:8]     ;
                16'd11  :  arp_tx_data <= sour_mac_addr[7:0]      ;
                16'd12  :  arp_tx_data <= MAC_TYPE[15:8]          ;      //frame type
                16'd13  :  arp_tx_data <= MAC_TYPE[7:0]           ;
                16'd14  :  arp_tx_data <= HARDWARE_TYPE[15:8]     ;      //hardware type
                16'd15  :  arp_tx_data <= HARDWARE_TYPE[7:0]      ;
                16'd16  :  arp_tx_data <= PROTOCOL_TYPE[15:8]     ;      //protocol type using IP 0800
                16'd17  :  arp_tx_data <= PROTOCOL_TYPE[7:0]      ;
                16'd18  :  arp_tx_data <= MAC_LENGTH              ;      //MAC address length
                16'd19  :  arp_tx_data <= IP_LENGTH               ;      //IP address length
                16'd20  :  arp_tx_data <= op[15:8]                ;
                16'd21  :  arp_tx_data <= op[7:0]                 ;
                16'd22  :  arp_tx_data <= sour_mac_addr[47:40]    ;
                16'd23  :  arp_tx_data <= sour_mac_addr[39:32]    ;
                16'd24  :  arp_tx_data <= sour_mac_addr[31:24]    ;
                16'd25  :  arp_tx_data <= sour_mac_addr[23:16]    ;
                16'd26  :  arp_tx_data <= sour_mac_addr[15:8]     ;
                16'd27  :  arp_tx_data <= sour_mac_addr[7:0]      ;
                16'd28  :  arp_tx_data <= sour_ip_addr[31:24]     ;
                16'd29  :  arp_tx_data <= sour_ip_addr[23:16]     ;
                16'd30  :  arp_tx_data <= sour_ip_addr[15:8]      ;
                16'd31  :  arp_tx_data <= sour_ip_addr[7:0]       ;
                16'd32  :  arp_tx_data <= arp_dest_mac_addr[47:40];
                16'd33  :  arp_tx_data <= arp_dest_mac_addr[39:32];
                16'd34  :  arp_tx_data <= arp_dest_mac_addr[31:24];
                16'd35  :  arp_tx_data <= arp_dest_mac_addr[23:16];
                16'd36  :  arp_tx_data <= arp_dest_mac_addr[15:8] ;
                16'd37  :  arp_tx_data <= arp_dest_mac_addr[7:0]  ;
                16'd38  :  arp_tx_data <= arp_dest_ip_addr[31:24] ;
                16'd39  :  arp_tx_data <= arp_dest_ip_addr[23:16] ;
                16'd40  :  arp_tx_data <= arp_dest_ip_addr[15:8]  ;
                16'd41  :  arp_tx_data <= arp_dest_ip_addr[7:0]   ;
                default :  arp_tx_data <= 8'd0                    ;
            endcase
        end
        else if(state == ARP_END)
            arp_tx_data  <= 8'hA5 ;
        else
            arp_tx_data  <= 8'd0 ;
    end
  
endmodule
