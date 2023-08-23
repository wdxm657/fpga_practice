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
module wr_scale_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 19'd0,
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
                                  
    input                         wr_clk/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         wr_fsync/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         wr_en/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
                                  
    input                         l_ov_wr_clk/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         l_ov_wr_fsync/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         l_ov_wr_en/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [PIX_WIDTH- 1'b1 : 0]  l_ov_wr_data, 

    input                         r_ov_wr_clk/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         r_ov_wr_fsync/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         r_ov_wr_en/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [PIX_WIDTH- 1'b1 : 0]  r_ov_wr_data, 

    input                         eth_wr_clk/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         eth_wr_fsync/*synthesis PAP_MARK_DEBUG="1"*/,
    input                         eth_wr_en/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [PIX_WIDTH- 1'b1 : 0]  eth_wr_data, 
    
    input                         rd_bac, // un
    output                     reg   o_ddr_wreq,
    output reg [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,/*synthesis PAP_MARK_DEBUG="1"*/
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len, // RD_ONE_LINE_NUM
    input                         ddr_wrdy, // un
    input                         i_ddr_wdone,/*synthesis PAP_MARK_DEBUG="1"*/
    output reg  [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req,/*synthesis PAP_MARK_DEBUG="1"*/

    output                        ddr_frame_done,
    output                  [3:0] current_4_frame_flag
);

reg ddr_wdone,ddr_wdata_req_0,rd_pulse;/*synthesis PAP_MARK_DEBUG="1"*/
wire ddr_rstn_2d,ddr_frame_done_0,write_en,ddr_rd_en;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire [31:0] write_data;
wire [255:0] hdmi_rd_wdata;/*synthesis PAP_MARK_DEBUG="1"*/
wire  [255:0] rd_wdata_1d;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt;
wire ddr_wdata_req_1d,ddr_wreq;/*synthesis PAP_MARK_DEBUG="1"*/
reg ddr_wdone_1,ddr_wdata_req_1,rd_pulse_1;/*synthesis PAP_MARK_DEBUG="1"*/
wire ddr_rstn_2d_1,ddr_frame_done_1,write_en_1,ddr_rd_en_1;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] rd_water_level_1;/*synthesis PAP_MARK_DEBUG="1"*/
wire [31:0] write_data_1;
wire [255:0] hdmi_rd_wdata_1;
wire  [255:0] rd_wdata_1d_1;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt_1;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt_1;
wire ddr_wdata_req_1d_1,ddr_wreq_1;/*synthesis PAP_MARK_DEBUG="1"*/
reg ddr_wdone_2,ddr_wdata_req_2,rd_pulse_2;/*synthesis PAP_MARK_DEBUG="1"*/
wire ddr_rstn_2d_2,ddr_frame_done_2,write_en_2,ddr_rd_en_2;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] rd_water_level_2;
wire [31:0] write_data_2;
wire [255:0] hdmi_rd_wdata_2;
wire  [255:0] rd_wdata_1d_2;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt_2;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt_2;
wire ddr_wdata_req_1d_2,ddr_wreq_2;
reg ddr_wdone_3,ddr_wdata_req_3,rd_pulse_3;/*synthesis PAP_MARK_DEBUG="1"*/
wire ddr_rstn_2d_3,ddr_frame_done_3,write_en_3,ddr_rd_en_3;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] rd_water_level_3;
wire [31:0] write_data_3;
wire [255:0] hdmi_rd_wdata_3;
wire  [255:0] rd_wdata_1d_3;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt_3;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt_3;
wire ddr_wdata_req_1d_3,ddr_wreq_3;

//0000
test #(
    .H_NUM(640),
    .V_NUM(360)
) hdmi_test(
    .wr_clk   (l_ov_wr_clk) ,       
    .wr_fsync (l_ov_wr_fsync)   ,   
    .wr_en    (l_ov_wr_en),             
    .wr_data  (l_ov_wr_data)  ,    
    .ddr_rstn (ddr_rstn)   ,   
    .ddr_rstn_2d(ddr_rstn_2d),
    .ddr_frame_done(ddr_frame_done_0),
    .ddr_wdone(ddr_wdone),
    .write_en (write_en) ,
    .write_data(write_data)
);

video_fifo hdmi_wr_fram_fifo (
  .wr_clk(l_ov_wr_clk),                // input
  .wr_rst(~ddr_rstn_2d),                // input
  .wr_en(write_en),                  // input
  .wr_data(write_data),              // input [31:0]
  .wr_full(),              // output
  .wr_water_level(wr_water_level),    // output [10:0]
  .almost_full(),      // output

  .rd_clk(ddr_clk),                // input
  .rd_rst(~ddr_rstn),                // input
  .rd_en(ddr_rd_en),                  // input
  .rd_data(hdmi_rd_wdata),              // output [255:0]
  .rd_water_level(rd_water_level),    // output [8:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

testt #(
    .OFFSET (0),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi(
    .wr_fsync                (l_ov_wr_fsync)        ,
    .ddr_clk                 (ddr_clk)           ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata)          ,
    .ddr_wdata_req           (ddr_wdata_req_0)     ,
    .ddr_wdone               (ddr_wdone)     ,

    .ddr_rd_en     (ddr_rd_en),
    .ddr_wreq                (ddr_wreq)    ,
    .rd_cnt                  (rd_cnt)      ,
    .rd_frame_cnt            (rd_frame_cnt)    ,
    .rd_wdata             (rd_wdata_1d)   
);

//1111
test#(
    .H_NUM(640),
    .V_NUM(360)
)  hdmi_test_1(
    .wr_clk   (l_ov_wr_clk) ,       
    .wr_fsync (r_ov_wr_fsync)   ,   
    .wr_en    (r_ov_wr_en),   
    .wr_data  (r_ov_wr_data)  ,         
    .ddr_rstn (ddr_rstn)   ,   
    .ddr_rstn_2d(ddr_rstn_2d_1),
    .ddr_wdone               (ddr_wdone_1)     ,
    .ddr_frame_done(ddr_frame_done_1),
    .write_en (write_en_1) ,
    .write_data(write_data_1)    
);

video_fifo hdmi_wr_fram_fifo_1 (
  .wr_clk(l_ov_wr_clk),                // input
  .wr_rst(~ddr_rstn_2d),                // input
  .wr_en(write_en_1),                  // input
  .wr_data(write_data_1),              // input [31:0]
  .wr_full(),              // output
  .wr_water_level(wr_water_level_1),    // output [10:0]
  .almost_full(),      // output

  .rd_clk(ddr_clk),                // input
  .rd_rst(~ddr_rstn),                // input
  .rd_en(ddr_rd_en_1),                  // input
  .rd_data(hdmi_rd_wdata_1),              // output [255:0]
  .rd_water_level(rd_water_level_1),    // output [8:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

testt #(
    .OFFSET (320),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_1(
    .wr_fsync                (r_ov_wr_fsync)        ,
    .ddr_clk                 (ddr_clk)           ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_1)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_1)          ,
    .ddr_wdata_req           (ddr_wdata_req_1)     ,
    .ddr_wdone               (ddr_wdone_1)     ,

    .ddr_rd_en    (ddr_rd_en_1),
    .ddr_wreq                (ddr_wreq_1)    ,
    .rd_cnt                  (rd_cnt_1)      ,
    .rd_frame_cnt            (rd_frame_cnt_1)    ,
    .rd_wdata             (rd_wdata_1d_1)   
);
//
//
// 2222
test#(
    .H_NUM(640),
    .V_NUM(360)
) hdmi_test_2(
    .wr_clk   (eth_wr_clk) ,       
    .wr_fsync (eth_wr_fsync)   ,   
    .wr_en    (eth_wr_en),      
    .wr_data  (eth_wr_data)  ,  
    .ddr_rstn (ddr_rstn)   ,   
    .ddr_rstn_2d(ddr_rstn_2d_2),
    .ddr_wdone(ddr_wdone_2),
    .ddr_frame_done(ddr_frame_done_2),
    .write_en (write_en_2) ,
    .write_data(write_data_2)    
);

video_fifo hdmi_wr_fram_fifo_2 (
  .wr_clk(eth_wr_clk),                // input
  .wr_rst(~ddr_rstn_2d),                // input
  .wr_en(write_en_2),                  // input
  .wr_data(write_data_2),              // input [31:0]
  .wr_full(),              // output
  .wr_water_level(wr_water_level_2),    // output [10:0]
  .almost_full(),      // output

  .rd_clk(ddr_clk),                // input
  .rd_rst(~ddr_rstn),                // input
  .rd_en(ddr_rd_en_2),                  // input
  .rd_data(hdmi_rd_wdata_2),              // output [255:0]
  .rd_water_level(rd_water_level_2),    // output [8:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

testt #(
    .OFFSET (230400),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_2(
    .wr_fsync                (eth_wr_fsync)        ,
    .ddr_clk                 (ddr_clk)           ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_2)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_2)          ,
    .ddr_wdata_req           (ddr_wdata_req_2)     ,
    .ddr_wdone               (ddr_wdone_2)     ,

    .ddr_rd_en        (ddr_rd_en_2),
    .ddr_wreq                (ddr_wreq_2)    ,
    .rd_cnt                  (rd_cnt_2)      ,
    .rd_frame_cnt            (rd_frame_cnt_2)    ,
    .rd_wdata             (rd_wdata_1d_2)   
);

// 3333
test#(
    .H_NUM(640),
    .V_NUM(360)
) hdmi_test_3(
    .wr_clk   (wr_clk) ,       
    .wr_fsync (wr_fsync)   ,   
    .wr_en    (wr_en),         
    .wr_data  (wr_data)  ,    
    .ddr_rstn (ddr_rstn)   ,   
    .ddr_rstn_2d(ddr_rstn_2d_3),
    .ddr_wdone(ddr_wdone_3),
    .ddr_frame_done(ddr_frame_done_3),
    .write_en (write_en_3) ,
    .write_data(write_data_3)    
);

video_fifo hdmi_wr_fram_fifo_3 (
  .wr_clk(wr_clk),                // input
  .wr_rst(~ddr_rstn_2d),                // input
  .wr_en(write_en_3),                  // input
  .wr_data(write_data_3),              // input [31:0]
  .wr_full(),              // output
  .wr_water_level(wr_water_level_3),    // output [10:0]
  .almost_full(),      // output

  .rd_clk(ddr_clk),                // input
  .rd_rst(~ddr_rstn),                // input
  .rd_en(ddr_rd_en_3),                  // input
  .rd_data(hdmi_rd_wdata_3),              // output [255:0]
  .rd_water_level(rd_water_level_3),    // output [8:0]
  .rd_empty(),            // output
  .almost_empty()     // output
);

testt #(
    .OFFSET (230720),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_3(
    .wr_fsync                (wr_fsync)        ,
    .ddr_clk                 (ddr_clk)           ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_3)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_3)          ,
    .ddr_wdata_req           (ddr_wdata_req_3)     ,
    .ddr_wdone               (ddr_wdone_3)     ,

    .ddr_rd_en               (ddr_rd_en_3),
    .ddr_wreq                (ddr_wreq_3)    ,
    .rd_cnt                  (rd_cnt_3)      ,
    .rd_frame_cnt            (rd_frame_cnt_3)    ,
    .rd_wdata                (rd_wdata_1d_3)   
);

    localparam HDMI_1 = 2'b00;
    localparam HDMI_2 = 2'b01;
    localparam HDMI_3 = 2'b10;
    localparam HDMI_4 = 2'b11;
    localparam IDLE = 4'h0;
    localparam DDR3_DONE = 4'h1;
    localparam WRITE_CHAN_0 = 4'h2;
    localparam WRITE_CHAN_1 = 4'h3;
    localparam WRITE_CHAN_2 = 4'h4;
    localparam WRITE_CHAN_3 = 4'h5;
    localparam ERROR = 4'hA;

reg [1:0]  sel;/*synthesis PAP_MARK_DEBUG="1"*/  //这个变量是个轮询的控制计数值，代表当前ddr写正在访问哪一个通道，看看这个通道有没有写的需求
reg [3:0] state_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
//DDR3读写逻辑实现
always @(posedge ddr_clk) begin
    if(~ddr_rstn) begin
        state_cnt    <= IDLE;
        sel          <= HDMI_1;
    end
    else begin
        case(state_cnt)     //
            IDLE:begin
                if(ddr_rstn)
                    state_cnt <= DDR3_DONE ;
                else
                    state_cnt <= IDLE;
            end         
            DDR3_DONE:begin
                if(sel==HDMI_1) begin
                    if(rd_water_level > 9'd37) begin
                        rd_pulse <= 1;
                        state_cnt <=WRITE_CHAN_0;
                    end
                    else begin
                        sel<=HDMI_2; 
                        state_cnt <= state_cnt ;
                    end
                end
                else if(sel==HDMI_2)begin
                    if(rd_water_level_1 > 9'd37) begin
                        rd_pulse_1 <= 1;
                        state_cnt <=WRITE_CHAN_1;
                    end
                    else begin
                        sel<=HDMI_3; 
                        state_cnt <= state_cnt ;
                    end
                end
                else if  (sel==HDMI_3)begin
                    if(rd_water_level_2 > 12'd38) begin
                        rd_pulse_2 <= 1;
                        state_cnt <=WRITE_CHAN_2;
                    end
                    else begin
                        sel<=HDMI_4; 
                        state_cnt <= state_cnt ;
                    end
                end
                else if  (sel==HDMI_4)begin
                    if(rd_water_level_3 > 12'd38) begin
                        rd_pulse_3 <= 1;
                        state_cnt <=WRITE_CHAN_3;
                    end
                    else begin
                        sel<=HDMI_1; 
                        state_cnt <= state_cnt ;
                    end
                end
            end        
            WRITE_CHAN_0:begin
                o_ddr_wreq <= ddr_wreq;
                if(ddr_wdata_req_0) rd_pulse <= 1'b0;
                if(i_ddr_wdone)begin
                    state_cnt <= DDR3_DONE;
                end
                else state_cnt <= state_cnt;
            end
            WRITE_CHAN_1:begin
                o_ddr_wreq <= ddr_wreq_1;
                if(ddr_wdata_req_1) rd_pulse_1 <= 1'b0;
                if(i_ddr_wdone)begin
                    state_cnt <= DDR3_DONE;
                end
                else state_cnt <= state_cnt;
            end
            WRITE_CHAN_2:begin
                o_ddr_wreq <= ddr_wreq_2;
                if(ddr_wdata_req_2) rd_pulse_2 <= 1'b0;
                if(i_ddr_wdone)begin
                    state_cnt <= DDR3_DONE;
                end
                else state_cnt <= state_cnt;
            end
            WRITE_CHAN_3:begin
                o_ddr_wreq <= ddr_wreq_3;
                if(ddr_wdata_req_3) rd_pulse_3 <= 1'b0;
                if(i_ddr_wdone)begin
                    state_cnt <= DDR3_DONE;
                end
                else state_cnt <= state_cnt;
            end
            default:begin
                state_cnt    <= ERROR;
            end
        endcase
    end
end

assign current_4_frame_flag = {rd_frame_cnt[0],rd_frame_cnt_1[0],rd_frame_cnt_2[0],rd_frame_cnt_3[0]};
    always @(*)
    begin 
        if(sel == HDMI_1)begin
            ddr_wdone <= i_ddr_wdone;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= 0;
            ddr_wdata_req_0 <= ddr_wdata_req;
            ddr_wdata_req_1 <= 0;
            ddr_wdata_req_2 <= 0;
            ddr_wdata_req_3 <= 0;
            ddr_wdata  <= rd_wdata_1d;
            ddr_waddr  <= {rd_frame_cnt[0],rd_cnt};
        end
        else if(sel == HDMI_2) begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= i_ddr_wdone;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= 0;
            ddr_wdata_req_0 <= 0;
            ddr_wdata_req_1 <= ddr_wdata_req;
            ddr_wdata_req_2 <= 0;
            ddr_wdata_req_3 <= 0;
            ddr_wdata  <= rd_wdata_1d_1;
            ddr_waddr  <= {rd_frame_cnt_1[0],rd_cnt_1};
        end
        else if(sel == HDMI_3)begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= i_ddr_wdone;
            ddr_wdone_3 <= 0;
            ddr_wdata_req_0 <= 0;
            ddr_wdata_req_1 <= 0;
            ddr_wdata_req_2 <= ddr_wdata_req;
            ddr_wdata_req_3 <= 0;
            ddr_wdata  <= rd_wdata_1d_2;
            ddr_waddr  <= {rd_frame_cnt_2[0],rd_cnt_2};
        end
        else if(sel == HDMI_4)begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= i_ddr_wdone;
            ddr_wdata_req_0 <= 0;
            ddr_wdata_req_1 <= 0;
            ddr_wdata_req_2 <= 0;
            ddr_wdata_req_3 <= ddr_wdata_req;
            ddr_wdata  <= rd_wdata_1d_3;
            ddr_waddr  <= {rd_frame_cnt_3[0],rd_cnt_3};
        end
    end 
    assign ddr_frame_done = ddr_frame_done_0 || ddr_frame_done_1 || ddr_frame_done_2 || ddr_frame_done_3;
    assign ddr_wr_len = 40; // 120 -- 60
endmodule