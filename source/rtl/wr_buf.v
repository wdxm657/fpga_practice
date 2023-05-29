`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 07/03/23 19:13:35
// Design Name: 
// Module Name: wr_buf
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
`define UD #1
module wr_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8
) (                               
    input                         ddr_clk,
    input                         ddr_rstn,
                                  
    input                         wr_clk,
    input                         wr_fsync,
    input                         wr_en,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
    
    input                         rd_bac, // un
    output                        ddr_wreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len, // RD_ONE_LINE_NUM
    input                         ddr_wrdy, // un
    input                         ddr_wdone,
    output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req,
    
    output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
    output                        frame_wirq,
    output                        hdmi_ddr_cur_fram
);
    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8; //256
    localparam WR_ONE_LINE_NUM    = H_NUM*PIX_WIDTH/RAM_WIDTH; //1280 * 16 / 32 = 640
                                                               //1920 * 16 / 32 = 960
    localparam RD_ONE_LINE_NUM    = WR_ONE_LINE_NUM*RAM_WIDTH/DDR_DATA_WIDTH; // 640 * 32 / 256 = 80
                                                                              // 960 * 32 / 256 = 120
    localparam DDR_ADDR_OFFSET = RD_ONE_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;  // 80 * 256 / 32 = 640
                                                                           // 120 * 256 / 32 = 960
    
    //===========================================================================
    reg       wr_fsync_1d;
    reg       wr_en_1d;
    wire      wr_rst;
    reg       wr_enable=0;
    
    reg       ddr_rstn_1d,ddr_rstn_2d;
    
    always @(posedge wr_clk)
    begin
        wr_fsync_1d <= wr_fsync;
        wr_en_1d <= wr_en;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
        
        if(~wr_fsync_1d & wr_fsync && ddr_rstn_2d) 
            wr_enable <= 1'b1;
        else 
            wr_enable <= wr_enable;
    end 
    
    assign wr_rst = (~wr_fsync_1d & wr_fsync) | (~ddr_rstn_2d);
    
    //===========================================================================
    reg      rd_fsync_1d,rd_fsync_2d,rd_fsync_3d;
    wire     rd_rst;
    always @(posedge ddr_clk)
    begin
        rd_fsync_1d <= wr_fsync;
        rd_fsync_2d <= rd_fsync_1d;
        rd_fsync_3d <= rd_fsync_2d;
    end 
    
    assign rd_rst = (~rd_fsync_3d && rd_fsync_2d) | (~ddr_rstn);

    //===========================================================================
    // wr_addr control
    reg [11:0]                 x_cnt;
    reg [11:0]                 y_cnt;
    reg [31 : 0]  write_data;
    reg [PIX_WIDTH- 1'b1 : 0]  wr_data_1d;
    reg                        write_en;
    
generate
    if(PIX_WIDTH == 6'd24)
    begin
        always @(posedge wr_clk)
        begin
            wr_data_1d <= wr_data;
            
            write_en <= (x_cnt[1:0] != 0);
            
            if(x_cnt[1:0] == 2'd1)
                write_data <= {wr_data[7:0],wr_data_1d};    // 8 + 24
            else if(x_cnt[1:0] == 2'd2)
                write_data <= {wr_data[15:0],wr_data_1d[PIX_WIDTH-1'b1:8]}; // 16 + high 16
            else if(x_cnt[1:0] == 2'd3)
                write_data <= {wr_data,wr_data_1d[PIX_WIDTH-1'b1:16]};  // 24 + high 8
            else
                write_data <= write_data;
        end 
    end
    else if(PIX_WIDTH == 6'd16)
    begin
        always @(posedge wr_clk)
        begin
            wr_data_1d <= wr_data;
            
            write_en <= x_cnt[0];
            if(x_cnt[0])
                write_data <= {wr_data,wr_data_1d};
            else
                write_data <= write_data;
        end
    end
    else
    begin
        always @(posedge wr_clk)
        begin
            write_data <= wr_data;
            write_en <= wr_en;
        end 
    end
endgenerate

    reg [11:0]                 wr_addr=0;
    always @(posedge wr_clk)
    begin
        if(wr_rst)
            wr_addr <= 12'd0;
        else
        begin
            if(write_en & wr_enable)
                wr_addr <= wr_addr + 12'd1;
            else
                wr_addr <= wr_addr;
        end 
    end

    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            x_cnt <= 12'd0;
        // data in valid, x++
        else if(wr_en & wr_enable)
            x_cnt <= x_cnt + 1'b1;
        else
            x_cnt <= 12'd0;
    end 
    
    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            y_cnt <= 12'd0;
        // data in pos, y++
        else if(~wr_en_1d & wr_en & wr_enable)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end 
    
    reg rd_pulse;
    always @(posedge wr_clk)
    begin
        if(x_cnt > H_NUM - 5'd20  & wr_enable)
            rd_pulse <= 1'b1;
        else
            rd_pulse <= 1'b0; 
    end 
    
    reg  [8:0] rd_addr=0;
    wire [255:0] rd_wdata;
    reg  [255:0] rd_wdata_1d=0;
    // require addr len >= 11(1920 | 1280)
    // 256 / 32 = 8, so 8 wr_addr equal 1 rd_addr
    // so rd_addr len = addr len - 3
    // such as 16 * 16 = 256, wr_addr = 256 / 32 = 8
    //                        rd_addr = 8 >> 3 = 1
    wr_fram_buf wr_fram_buf (
        .wr_data            (  write_data     ),// input [31:0]               
        .wr_addr            (  wr_addr        ),// input [11:0]              
        .wr_en              (  write_en       ),// input                      
        .wr_clk             (  wr_clk         ),// input                      
        .wr_rst             (  ~ddr_rstn_2d   ),// input    
                          
        .rd_addr            (  rd_addr        ),// input [8:0]                
        .rd_data            (  rd_wdata       ),// output [255:0]             
        .rd_clk             (  ddr_clk        ),// input                      
        .rd_rst             (  ~ddr_rstn      ) // input                      
    );
    
    reg rd_pulse_1d,rd_pulse_2d,rd_pulse_3d;
    always @(posedge ddr_clk)
    begin 
        rd_pulse_1d <= rd_pulse;
        rd_pulse_2d <= rd_pulse_1d;
        rd_pulse_3d <= rd_pulse_2d;
    end 
    
    wire rd_trig;
    assign rd_trig = ~rd_pulse_3d && rd_pulse_2d;
    
    reg ddr_wr_req=0;
    reg ddr_wr_req_1d;
    assign ddr_wreq =ddr_wr_req;
    
    always @(posedge ddr_clk)
    begin 
        ddr_wr_req_1d <= ddr_wr_req;
        
        if(rd_trig)
            ddr_wr_req <= 1'b1;
        else if(ddr_wdata_req)
            ddr_wr_req <= 1'b0;
        else
            ddr_wr_req <= ddr_wr_req;
    end 
    
    reg  rd_en_1d;
    reg  ddr_wdata_req_1d;
    always @(posedge ddr_clk)
    begin
        ddr_wdata_req_1d <= ddr_wdata_req;
        rd_en_1d <= ~ddr_wr_req_1d & ddr_wr_req;
    end 
    
    always @(posedge ddr_clk)
    begin
        if(ddr_wdata_req_1d | rd_en_1d)
            rd_wdata_1d <= rd_wdata;
        else 
            rd_wdata_1d <= rd_wdata_1d;
    end 
    
    reg line_flag=0;
    always@(posedge ddr_clk)
    begin
        if(rd_rst)
            line_flag <= 1'b0;
        else if(rd_trig)
            line_flag <= 1'b1;
        else
            line_flag <= line_flag;
    end 
    
    always @(posedge ddr_clk)
    begin 
        if(rd_rst)
            rd_addr <= 1'b0;
        else if(~ddr_wr_req_1d & ddr_wr_req)
            rd_addr <= rd_addr + 1'b1;
        else if(ddr_wdata_req)
            rd_addr <= rd_addr + 1'b1;
        else if(rd_trig & line_flag)
            rd_addr <= rd_addr - 1'b1;
        else
            rd_addr <= rd_addr;
    end 
    
    reg [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt=1;
    always @(posedge ddr_clk)
    begin 
        if(~ddr_rstn)
            rd_frame_cnt <= 'd0;
        else if(~rd_fsync_3d && rd_fsync_2d)
            rd_frame_cnt <= rd_frame_cnt + 1'b1;
        else
            rd_frame_cnt <= rd_frame_cnt;
    end 

    reg [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt;
    always @(posedge ddr_clk)
    begin 
        if(rd_rst)
            rd_cnt <= 19'd0;
        else if(ddr_wdone)
            rd_cnt <= rd_cnt + DDR_ADDR_OFFSET; // 640 | 960
        else
            rd_cnt <= rd_cnt;
    end 
    
    reg wirq_en=0;
    always @(posedge ddr_clk)
    begin
        if (~rd_fsync_2d && rd_fsync_3d)
            wirq_en <= 1'b1;
        else
            wirq_en <= wirq_en;
    end 
    
    assign ddr_wdata = (~ddr_wdata_req_1d & ddr_wdata_req) ? rd_wdata_1d : rd_wdata;
    assign ddr_waddr = {rd_frame_cnt[0],rd_cnt} + ADDR_OFFSET;
    assign ddr_wr_len = RD_ONE_LINE_NUM;
    assign frame_wcnt = rd_frame_cnt;
    assign frame_wirq = wirq_en && rd_fsync_3d;
    assign hdmi_ddr_cur_fram = rd_frame_cnt[0];
endmodule
