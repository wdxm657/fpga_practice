`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/16 23:11:05
// Design Name: 
// Module Name: udp_rx
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


module udp_rx #(
    parameter              LOCAL_PORT_NUM= 16'hF000,
    parameter       LOCAL_IP  = 32'hC0_A8_01_6E, 
    parameter       DEST_IP   = 32'hC0_A8_01_6D
)(
    input                  clk/*synthesis PAP_MARK_DEBUG="1"*/,   
    input                  rstn,  
    
    input      [7:0]       udp_rx_data/*synthesis PAP_MARK_DEBUG="1"*/,
    input                  udp_rx_req/*synthesis PAP_MARK_DEBUG="1"*/,
    
    input                  ip_checksum_error,
    input                  ip_addr_check_error,
    
    output reg [7:0]       udp_rec_rdata/*synthesis PAP_MARK_DEBUG="1"*/,      //udp ram read data
    output reg [15:0]      udp_rec_data_length/*synthesis PAP_MARK_DEBUG="1"*/,     //udp data length
    output                 udp_rec_data_valid/*synthesis PAP_MARK_DEBUG="1"*/,       //udp data valid
    output reg             udp_rec_data_vld_for_send
);

    reg  [15:0]             udp_rx_cnt/*synthesis PAP_MARK_DEBUG="1"*/ ;
    reg  [15:0]             udp_data_length/*synthesis PAP_MARK_DEBUG="1"*/ ;
    reg  [15:0]             udp_dest_port;

    localparam IDLE             =  8'b0000_0001  ;
    localparam REC_HEAD         =  8'b0000_0010  ;
    localparam REC_DATA         =  8'b0000_0100  ;
    localparam REC_ODD_DATA     =  8'b0000_1000  ;
    localparam VERIFY_CHECKSUM  =  8'b0001_0000  ;
    localparam REC_ERROR        =  8'b0010_0000  ;
    localparam REC_END_WAIT     =  8'b0100_0000  ;
    localparam REC_END          =  8'b1000_0000  ;
    
    reg [7:0]     state      ;
    reg [7:0]     state_n ;
    
    always @(posedge clk)
    begin
      if (~rstn)
        state <= IDLE ;
      else 
        state <= state_n ;
    end
    
    always @(*)
    begin
        case(state)
         IDLE            :
         begin
             if (udp_rx_req == 1'b1)
                 state_n = REC_HEAD ;
             else
                 state_n = IDLE ;
         end
         REC_HEAD       :
         begin
             if (ip_checksum_error | ip_addr_check_error)
                 state_n = REC_ERROR ;
             else if (udp_head_cnt == 16'd6)
             begin
                 if(udp_dest_port == LOCAL_PORT_NUM)
                     state_n = REC_DATA ;
                 else
                     state_n = REC_ERROR ;
             end
             else
                 state_n = REC_HEAD ;
         end
         REC_DATA       :
         begin
             if (udp_rx_cnt == (udp_rec_data_length - 2))
                 state_n = REC_END ;
             else
                 state_n = REC_DATA ;
         end
         REC_ERROR      : state_n = IDLE  ; 
         REC_END        : state_n = IDLE  ;
         default        : state_n = IDLE  ;
         endcase
    end

    always @(posedge clk)
    begin
        if (~rstn)
            udp_dest_port <= 16'd0 ;
        else if (state == REC_HEAD && udp_head_cnt > 16'd1 && udp_head_cnt < 16'd4)
            udp_dest_port <= {udp_dest_port[7:0],udp_rx_data};
    end

    //udp data length 
    always @(posedge clk)
    begin
        if (~rstn)
            udp_data_length <= 16'd0 ;
        else if (state == REC_HEAD && udp_head_cnt > 16'd3 && udp_head_cnt < 16'd6)
            udp_data_length <= {udp_data_length[7:0],udp_rx_data};
    end
    
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rec_data_length <= 16'd0 ;
        else if (state == REC_HEAD)
            udp_rec_data_length <= udp_data_length - 16'd8;
    end
    reg [5:0] udp_head_cnt;
    always @(posedge clk)
    begin
        if (~rstn)
            udp_head_cnt <= 16'd0 ;
        else if (state == REC_HEAD)
            udp_head_cnt <= udp_head_cnt + 1'b1 ;
        else
            udp_head_cnt <= 16'd0 ;
    end
    
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rx_cnt <= 16'd0 ;
        else if (state == REC_DATA && udp_rec_data_vld)
            udp_rx_cnt <= udp_rx_cnt + 1'b1 ;
        else if (state == REC_DATA)
            udp_rx_cnt <= udp_rx_cnt;
        else
            udp_rx_cnt <= 16'd0 ;
    end

    always @(posedge clk)
    begin
        if (~rstn)
            udp_rec_data_vld_for_send <= 1'b0 ;
        else if (state == REC_DATA)
            udp_rec_data_vld_for_send <= 1'b1;
        else
            udp_rec_data_vld_for_send <= 1'b0 ;
    end
    
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rec_rdata <= 8'd0 ;
        else if(/*udp_rx_cnt > 16'd7 && udp_rx_cnt < (udp_data_length - 1) &&*/ udp_rec_data_vld)
            udp_rec_rdata <= udp_rx_data ;
    end

    //**************************************************//
    //generate udp rx end
    reg  udp_rx_end;
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rx_end <= 1'b0 ;       
        else if (state == REC_END)    
            udp_rx_end <= 1'b1 ;   
        else
            udp_rx_end <= 1'b0 ;    
    end 
    
// 接收超过1470的数据时，第一次的有效数据长度为1470
// 超出的数据为每次1480
// 在收到ETH帧包之后的HEADER中没有端口、长度信息了，结束头部之后直接跟的是真实数据
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rec_data_vld <= 1'b0 ;
        else if (state == REC_DATA & udp_rec_data_length <= 1470) // 小于1470直接拉高不动
            udp_rec_data_vld <= 1'b1 ;
        else if (state == REC_DATA & (udp_rec_data_length > 1470) & (udp_rx_cnt < 1471)) //第一次拉高使用这个信号
            udp_rec_data_vld <= 1'b1 ;
        else if (((data_vld_cnt > 16'd32) & (data_vld_cnt < 16'd1513)) & state == REC_DATA) // 后续拉高都使用wait_cnt
            udp_rec_data_vld <= 1'b1 ;
        else
            udp_rec_data_vld <= 1'b0 ;
    end

// 寄存ETH包中的des ip和local ip 为了拉高data valid信号
assign udp_rec_data_valid = udp_rec_data_valid_d1;
reg udp_rec_data_vld,udp_rec_data_valid_d1;
    always @(posedge clk)
    begin
        if (~rstn)
            udp_rec_data_valid_d1 <= 1'b0;
        else
            udp_rec_data_valid_d1 <= udp_rec_data_vld;
    end
reg [15:0] data_vld_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
reg [55:0] data_vld_sig;/*synthesis PAP_MARK_DEBUG="1"*/
reg data_vld;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge clk)
    begin
        if (~rstn)
            data_vld_sig <= 56'b0;
        else if (state == REC_DATA & ~udp_rec_data_vld)
            data_vld_sig <= {data_vld_sig[47:0], udp_rx_data};
        else
            data_vld_sig <= 56'b0;
    end
    always @(posedge clk)
    begin
        if (~rstn)
            data_vld <= 1'b0;
        else if (state == REC_DATA & data_vld_sig == 56'h55_55_55_55_55_55_55)
            data_vld <= 1'b1;
        else if(udp_rec_data_valid_d1 & ~udp_rec_data_vld) // 下降沿清零
            data_vld <= 1'b0;
    end
    always @(posedge clk)
    begin
        if (~rstn)
            data_vld_cnt <= 16'b0;
        else if (data_vld)
            data_vld_cnt <= data_vld_cnt + 1'b1;
        else
            data_vld_cnt <= 16'b0;
    end


reg oor_data_first_flag;// out of range data means data length more than 1470
    always @(posedge clk)
    begin
        if (~rstn)
            oor_data_first_flag <= 1'b0 ;
        else if (udp_rx_cnt > 5 & (udp_data_length > 1470))
            oor_data_first_flag <= 1'b1 ;
        else if (udp_rx_cnt > 1479)
            oor_data_first_flag <= 1'b0 ;
    end

endmodule
