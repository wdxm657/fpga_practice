`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/01 16:37:00
// Design Name: 
// Module Name: ip_tx
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


module ip_tx(
    input                clk         ,
    input                rstn        ,
    
    input  [47:0]        dest_mac_addr,  //destination mac address
    input  [47:0]        sour_mac_addr,  //source mac address
    input  [7:0]         ttl,
    input  [7:0]         ip_send_type,
    input  [31:0]        sour_ip_addr,
    input  [31:0]        dest_ip_addr,
    input  [7:0]         upper_layer_data,//data from udp or icmp
    output reg           upper_data_req,  //request data from udp or icmp
    input                upper_tx_ready,
    
    input                ip_tx_req,  //IP���ݱ���������
    output reg           ip_tx_ack,
    input  [15:0]        ip_send_data_length ,
    
    input                mac_tx_ack,
    input                mac_send_end,
    input                mac_data_req,
    
    output reg           ip_tx_ready,
    output reg [7:0]     ip_tx_data,
    output reg           ip_tx_end
) ;
    `include "check_sum.vh"   
    localparam MAC_TYPE      = 16'h0800 ;
    localparam IP_VERSION    = 4'h4     ;  //ipv4
    localparam HEADER_LEN    = 4'h5     ;  //header length
    
    reg            checksum_finish ;
    reg  [15:0]    identify_code ;
    reg  [15:0]    send_length_1d ;
    reg  [15:0]    ip_send_cnt ;
    reg  [15:0]    timeout ;
    reg  [3:0]     wait_cnt ;
    reg            mac_send_end_1d ;
    
    parameter IDLE             = 8'b0000_0001 ;
    parameter START            = 8'b0000_0010 ;
    parameter WAIT_DATA_LENGTH = 8'b0000_0100 ;
    parameter GEN_CHECKSUM     = 8'b0000_1000 ;
    parameter SEND_WAIT        = 8'b0001_0000 ;
    parameter WAIT_MAC         = 8'b0010_0000 ;
    parameter IP_SEND          = 8'b0100_0000 ;
    parameter IP_END           = 8'b1000_0000 ;
    
    reg [7:0]    state  ;
    reg [7:0]    next_state ;
    
    always @(posedge clk )
    begin
        if (~rstn)
            state  <=  IDLE  ;
        else
            state  <= next_state ;
    end
      
    always @(*)
    begin
        case(state)
            IDLE            :
            begin
                if (ip_tx_req)
                    next_state = START ;
                else
                    next_state = IDLE ;
            end
            START            :
            begin
                if (mac_tx_ack)
                    next_state = WAIT_DATA_LENGTH ;
                else
                    next_state = START ;
            end  
            WAIT_DATA_LENGTH   :
            begin
                if (wait_cnt == 4'd7)
                    next_state = GEN_CHECKSUM ;
                else
                    next_state = WAIT_DATA_LENGTH ;
            end
            GEN_CHECKSUM     :
            begin
                if (checksum_finish)
                    next_state = SEND_WAIT ;
                else
                    next_state = GEN_CHECKSUM ;
            end
            SEND_WAIT       :
            begin
                if (upper_tx_ready)
                    next_state = WAIT_MAC ;
                else if (timeout == 16'hffff)
                    next_state = IDLE ;
                else
                    next_state = SEND_WAIT ;
            end
            WAIT_MAC         :
            begin
                if (mac_data_req)
                    next_state = IP_SEND ;
                else if (timeout == 16'hffff)
                    next_state = IDLE ;
                else
                    next_state = WAIT_MAC ;
            end
            IP_SEND         :
            begin
                if (ip_send_cnt == 14 + send_length_1d)
                    next_state = IP_END ;
                else
                    next_state = IP_SEND ;
            end
    	    IP_END         :
            begin
                if (mac_send_end_1d)
                    next_state = IDLE ;
                else
                    next_state = IP_END ;
            end
            default          :
                next_state = IDLE ;
        endcase
    end
     
    always @(posedge clk )
    begin
        if (~rstn)
          mac_send_end_1d <= 1'b0 ;
        else 
          mac_send_end_1d <= mac_send_end ;
    end  
     
    always @(posedge clk )
    begin
        if (~rstn)
            ip_tx_ack <= 1'b0 ;
        else if (state == WAIT_DATA_LENGTH)
            ip_tx_ack <= 1'b1 ;
        else
            ip_tx_ack <= 1'b0 ;
    end  
      
    always @(posedge clk )
    begin
        if (~rstn)
            ip_tx_ready <= 1'b0 ;
        else if (state == WAIT_MAC)
            ip_tx_ready <= upper_tx_ready ;
        else
            ip_tx_ready <= 1'b0 ;
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
            ip_tx_end <= 1'b0 ;
        else if ((state == IP_SEND) && (ip_send_cnt == 12 + send_length_1d))
            ip_tx_end <= 1'b1 ;
        else
            ip_tx_end <= 1'b0 ;
    end
      
    //request data from icmp or udp
    always @(posedge clk )
    begin
        if (~rstn)
            upper_data_req <= 1'b0 ;
        else if (state == IP_SEND && ip_send_cnt == 16'd29)
            upper_data_req <= 1'b1 ;
        else
            upper_data_req <= 1'b0 ;
    end
      
    //timeout counter
    always @(posedge clk )
    begin
        if (~rstn)
            timeout <= 16'd0 ;
        else if (upper_tx_ready)
            timeout <= 16'd0 ;
        else if (state == SEND_WAIT || state == WAIT_MAC)
            timeout <= timeout + 1'b1 ;
        else
            timeout <= 16'd0 ;
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
            wait_cnt <= 4'd0 ;
        else if (state == WAIT_DATA_LENGTH)
            wait_cnt <= wait_cnt + 1'b1 ;
        else
            wait_cnt <= 4'd0 ;
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
            identify_code  <= 16'd0 ;
        else if (ip_tx_end)
            identify_code  <= identify_code + 1'b1 ;
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
            send_length_1d  <= 16'd0 ;
        else
        begin
            if (ip_send_data_length < 46)
                send_length_1d  <= 16'd46 ;
            else
                send_length_1d  <= ip_send_data_length ;
        end
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
          ip_send_cnt  <= 16'd0 ;
        else if (state == GEN_CHECKSUM || state == IP_SEND)
          ip_send_cnt <= ip_send_cnt + 1'b1 ;
        else
          ip_send_cnt <= 16'd0 ;
    end
    //checksum generation
    
    reg  [16:0] checksum_tmp0 ;
    reg  [16:0] checksum_tmp1 ;
    reg  [16:0] checksum_tmp2 ;
    reg  [16:0] checksum_tmp3 ;
    reg  [16:0] checksum_tmp4 ;
    reg  [17:0] checksum_tmp5 ;
    reg  [17:0] checksum_tmp6 ;
    reg  [18:0] checksum_tmp7 ;
    reg  [19:0] checksum_tmp8 ;
    reg  [19:0] check_out ;
    reg  [19:0] checkout_buf ;
    reg  [15:0] checksum ;
    
    always @(posedge clk )
    begin
        if (~rstn)
        begin
            checksum_tmp0 <= 17'd0 ;
            checksum_tmp1 <= 17'd0 ;
            checksum_tmp2 <= 17'd0 ;
            checksum_tmp3 <= 17'd0 ;
            checksum_tmp4 <= 17'd0 ;
            checksum_tmp5 <= 18'd0 ;
            checksum_tmp6 <= 18'd0 ;
            checksum_tmp7 <= 19'd0 ;
            checksum_tmp8 <= 20'd0 ;
            check_out     <= 20'd0 ;
            checkout_buf  <= 20'd0 ;
        end
        else if (state == GEN_CHECKSUM)
        begin
            checksum_tmp0 <= checksum_adder(16'h4500,ip_send_data_length);
            checksum_tmp1 <= checksum_adder(identify_code, 16'h4000) ;
            checksum_tmp2 <= checksum_adder({ttl,ip_send_type}, 16'h0000) ;
            checksum_tmp3 <= checksum_adder(sour_ip_addr[31:16], sour_ip_addr[15:0]) ;
            checksum_tmp4 <= checksum_adder(dest_ip_addr[31:16], dest_ip_addr[15:0]) ;
            checksum_tmp5 <= checksum_adder(checksum_tmp0, checksum_tmp1) ;
            checksum_tmp6 <= checksum_adder(checksum_tmp2, checksum_tmp3) ;
            checksum_tmp7 <= checksum_adder(checksum_tmp5, checksum_tmp6) ;
            checksum_tmp8 <= checksum_adder(checksum_tmp4, checksum_tmp7) ;
            check_out     <= checksum_out(checksum_tmp8) ;
            checkout_buf  <= checksum_out(check_out) ;
        end
        else if (state == IDLE)
        begin
            checksum_tmp0 <= 17'd0 ;
            checksum_tmp1 <= 17'd0 ;
            checksum_tmp2 <= 17'd0 ;
            checksum_tmp3 <= 17'd0 ;
            checksum_tmp4 <= 17'd0 ;
            checksum_tmp5 <= 18'd0 ;
            checksum_tmp6 <= 18'd0 ;
            checksum_tmp7 <= 19'd0 ;
            checksum_tmp8 <= 20'd0 ;
            check_out     <= 20'd0 ;
            checkout_buf  <= 20'd0 ;
        end
    end

    always @(posedge clk )
    begin
        if (~rstn)
            checksum <= 32'd0 ;
        else if (state == GEN_CHECKSUM)
            checksum <= ~checkout_buf[15:0] ;
    end

    //*******************************************************//
    always @(posedge clk )
    begin
        if (~rstn)
            checksum_finish <= 1'b0 ;
        else if (state == GEN_CHECKSUM && ip_send_cnt == 16'd13)
            checksum_finish <= 1'b1 ;
        else
            checksum_finish <= 1'b0 ;
    end
      
    always @(posedge clk )
    begin
        if (~rstn)
            ip_tx_data <= 8'h00 ;
        else if (state == IP_SEND)
        begin
            case(ip_send_cnt)
                16'd0   :  ip_tx_data <= dest_mac_addr[47:40]     ;
                16'd1   :  ip_tx_data <= dest_mac_addr[39:32]     ;
                16'd2   :  ip_tx_data <= dest_mac_addr[31:24]     ;
                16'd3   :  ip_tx_data <= dest_mac_addr[23:16]     ;
                16'd4   :  ip_tx_data <= dest_mac_addr[15:8]      ;
                16'd5   :  ip_tx_data <= dest_mac_addr[7:0]       ;
                16'd6   :  ip_tx_data <= sour_mac_addr[47:40]     ;
                16'd7   :  ip_tx_data <= sour_mac_addr[39:32]     ;
                16'd8   :  ip_tx_data <= sour_mac_addr[31:24]     ;
                16'd9   :  ip_tx_data <= sour_mac_addr[23:16]     ;
                16'd10  :  ip_tx_data <= sour_mac_addr[15:8]      ;
                16'd11  :  ip_tx_data <= sour_mac_addr[7:0]       ;
                16'd12  :  ip_tx_data <= MAC_TYPE[15:8]           ;
                16'd13  :  ip_tx_data <= MAC_TYPE[7:0]            ;//MAC HEAD
                16'd14  :  ip_tx_data <= {IP_VERSION, HEADER_LEN} ;
                16'd15  :  ip_tx_data <= 8'h00                    ;
                16'd16  :  ip_tx_data <= ip_send_data_length[15:8];
                16'd17  :  ip_tx_data <= ip_send_data_length[7:0] ;
                16'd18  :  ip_tx_data <= identify_code[15:8]      ;
                16'd19  :  ip_tx_data <= identify_code[7:0]       ;
                16'd20  :  ip_tx_data <= 8'h40                    ;
                16'd21  :  ip_tx_data <= 8'h00                    ;
                16'd22  :  ip_tx_data <= ttl                      ;
                16'd23  :  ip_tx_data <= ip_send_type             ;
                16'd24  :  ip_tx_data <= checksum[15:8]           ;
                16'd25  :  ip_tx_data <= checksum[7:0]            ;
                16'd26  :  ip_tx_data <= sour_ip_addr[31:24]      ;
                16'd27  :  ip_tx_data <= sour_ip_addr[23:16]      ;
                16'd28  :  ip_tx_data <= sour_ip_addr[15:8]       ;
                16'd29  :  ip_tx_data <= sour_ip_addr[7:0]        ;
                16'd30  :  ip_tx_data <= dest_ip_addr[31:24]      ;
                16'd31  :  ip_tx_data <= dest_ip_addr[23:16]      ;
                16'd32  :  ip_tx_data <= dest_ip_addr[15:8]       ;
                16'd33  :  ip_tx_data <= dest_ip_addr[7:0]        ;//IP HEAD
                default :  ip_tx_data <= upper_layer_data         ;
            endcase
        end
        else
            ip_tx_data  <= 8'h00 ;
    end
  
endmodule
