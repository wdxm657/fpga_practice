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
                                  
    input                         wr_clk,
    input                         wr_fsync,
    input                         wr_en,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
                                  
    input                         ov_wr_clk,
    input                         ov_wr_fsync,
    input                         ov_wr_en,
    input  [PIX_WIDTH- 1'b1 : 0]  ov_wr_data, 
    
    input                         rd_bac, // un
    output                        o_ddr_wreq,
    output  [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len, // RD_ONE_LINE_NUM
    input                         ddr_wrdy, // un
    input                         i_ddr_wdone,/*synthesis PAP_MARK_DEBUG="1"*/
    output  [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req,
    
    output                        ddr_frame_done
);
    localparam HDMI_1 = 2'b00;
    localparam HDMI_2 = 2'b01;
    localparam HDMI_3 = 2'b10;
    localparam HDMI_4 = 2'b11;
reg ddr_wdone;
wire ddr_rstn_2d,ddr_frame_done_0,rd_pulse,write_en,cur_frame;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] wr_addr;
wire [31:0] write_data;
wire  [8:0] rd_addr;
wire [255:0] hdmi_rd_wdata;
wire  [255:0] rd_wdata_1d;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt;
wire ddr_wdata_req_1d,ddr_wreq;
reg ddr_wdone_1;
wire ddr_rstn_2d_1,ddr_frame_done_1,rd_pulse_1,write_en_1,cur_frame_1;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] wr_addr_1;
wire [31:0] write_data_1;
wire  [8:0] rd_addr_1;
wire [255:0] hdmi_rd_wdata_1;
wire  [255:0] rd_wdata_1d_1;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt_1;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt_1;
wire ddr_wdata_req_1d_1,ddr_wreq_1;
reg ddr_wdone_2;
wire ddr_rstn_2d_2,ddr_frame_done_2,rd_pulse_2,write_en_2,cur_frame_2;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] wr_addr_2;
wire [31:0] write_data_2;
wire  [8:0] rd_addr_2;
wire [255:0] hdmi_rd_wdata_2;
wire  [255:0] rd_wdata_1d_2;
wire [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt_2;             
wire [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt_2;
wire ddr_wdata_req_1d_2,ddr_wreq_2;
reg ddr_wdone_3;
wire ddr_rstn_2d_3,ddr_frame_done_3,rd_pulse_3,write_en_3,cur_frame_3;/*synthesis PAP_MARK_DEBUG="1"*/
wire [11:0] wr_addr_3;
wire [31:0] write_data_3;
wire  [8:0] rd_addr_3;
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
    .wr_clk   (wr_clk) ,       
    .wr_fsync (wr_fsync)   ,   
    .wr_en    (wr_en),         
    .ddr_rstn (ddr_rstn)   ,   
    .wr_data  (wr_data)  ,     
    .ddr_rstn_2d(ddr_rstn_2d),
    .cur_frame (cur_frame),
    .ddr_frame_done(ddr_frame_done_0),
    .ddr_wdone(ddr_wdone),
    //.ddr_wdone               (i_ddr_wdone)     ,
    .rd_pulse (rd_pulse) ,
    .wr_addr  (wr_addr) ,
    .write_en (write_en) ,
    .write_data(write_data)
);

// require addr len >= 11(1920 | 1280)
// 256 / 32 = 8, so 8 wr_addr equal 1 rd_addr
// so rd_addr len = addr len - 3
// such as 16 * 16 = 256, wr_addr = 256 / 32 = 8
//                        rd_addr = 8 >> 3 = 1
wr_fram_buf hdmi_wr_fram_buf (
    .wr_data            (  write_data     ),// input [31:0]
    .wr_addr            (  wr_addr        ),// input [11:0]
    .wr_en              (  write_en       ),// input
    .wr_clk             (  wr_clk         ),// input
    .wr_rst             (  ~ddr_rstn_2d   ),// input
                
    .rd_addr            (  rd_addr        ),// input [8:0]
    .rd_data            (  hdmi_rd_wdata       ),// output [255:0]
    .rd_clk             (  ddr_clk        ),// input
    .rd_rst             (  ~ddr_rstn      ) // input
);

testt #(
    .OFFSET (0),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi(
    .ddr_clk                 (ddr_clk)           ,
    .wr_fsync                (wr_fsync)        ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata)          ,
    .ddr_wdata_req           (ddr_wdata_req)     ,
    .ddr_frame_done          (ddr_frame_done_0)  ,
    .ddr_wdone               (ddr_wdone)     ,
    //.ddr_wdone               (i_ddr_wdone)     ,

    .ddr_wdata_req_1d        (ddr_wdata_req_1d),
    .ddr_wreq                (ddr_wreq)    ,
    //.ddr_wreq                (o_ddr_wreq)    ,
    .rd_addr                 (rd_addr)       ,
    .rd_cnt                  (rd_cnt)      ,
    .rd_frame_cnt            (rd_frame_cnt)    ,
    .rd_wdata_1d             (rd_wdata_1d)   
);


//1111
test#(
    .H_NUM(640),
    .V_NUM(360)
)  hdmi_test_1(
    .wr_clk   (wr_clk) ,       
    .wr_fsync (wr_fsync)   ,   
    .wr_en    (wr_en),         
    .ddr_rstn (ddr_rstn)   ,   
    .wr_data  (wr_data)  ,     
    .ddr_rstn_2d(ddr_rstn_2d_1),
    .ddr_wdone               (ddr_wdone_1)     ,
    //.ddr_wdone               (i_ddr_wdone)     ,
    .cur_frame (cur_frame_1),
    .ddr_frame_done(ddr_frame_done_1),
    .rd_pulse (rd_pulse_1) ,
    .wr_addr  (wr_addr_1) ,
    .write_en (write_en_1) ,
    .write_data(write_data_1)    
);

wr_fram_buf hdmi_wr_fram_buf_1 (
    .wr_data            (  write_data_1     ),// input [31:0]
    .wr_addr            (  wr_addr_1        ),// input [11:0]
    .wr_en              (  write_en_1       ),// input
    .wr_clk             (  wr_clk         ),// input
    .wr_rst             (  ~ddr_rstn_2d_1   ),// input
                
    .rd_addr            (  rd_addr_1        ),// input [8:0]
    .rd_data            (  hdmi_rd_wdata_1       ),// output [255:0]
    .rd_clk             (  ddr_clk        ),// input
    .rd_rst             (  ~ddr_rstn      ) // input
);

testt #(
    .OFFSET (320),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_1(
    .ddr_clk                 (ddr_clk)           ,
    .wr_fsync                (wr_fsync)        ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_1)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_1)          ,
    .ddr_wdata_req           (ddr_wdata_req)     ,
    .ddr_frame_done          (ddr_frame_done_1)  ,
    .ddr_wdone               (ddr_wdone_1)     ,
    //.ddr_wdone               (i_ddr_wdone)     ,

    .ddr_wdata_req_1d        (ddr_wdata_req_1d_1),
    .ddr_wreq                (ddr_wreq_1)    ,
    //.ddr_wreq                (o_ddr_wreq)    ,
    .rd_addr                 (rd_addr_1)       ,
    .rd_cnt                  (rd_cnt_1)      ,
    .rd_frame_cnt            (rd_frame_cnt_1)    ,
    .rd_wdata_1d             (rd_wdata_1d_1)   
);


// 2222
test#(
    .H_NUM(640),
    .V_NUM(360)
) hdmi_test_2(
    .wr_clk   (ov_wr_clk) ,       
    .wr_fsync (ov_wr_fsync)   ,   
    .wr_en    (ov_wr_en),         
    .ddr_rstn (ddr_rstn)   ,   
    .wr_data  (ov_wr_data)  ,     
    .ddr_rstn_2d(ddr_rstn_2d_2),
    .ddr_wdone(ddr_wdone_2),
    //.ddr_wdone               (i_ddr_wdone)     ,
    .cur_frame (cur_frame_2),
    .ddr_frame_done(ddr_frame_done_2),
    .rd_pulse (rd_pulse_2) ,
    .wr_addr  (wr_addr_2) ,
    .write_en (write_en_2) ,
    .write_data(write_data_2)    
);

wr_fram_buf hdmi_wr_fram_buf_2 (
    .wr_data            (  write_data_2     ),// input [31:0]
    .wr_addr            (  wr_addr_2        ),// input [11:0]
    .wr_en              (  write_en_2       ),// input
    .wr_clk             (  ov_wr_clk         ),// input
    .wr_rst             (  ~ddr_rstn_2d_2   ),// input
                
    .rd_addr            (  rd_addr_2        ),// input [8:0]
    .rd_data            (  hdmi_rd_wdata_2       ),// output [255:0]
    .rd_clk             (  ddr_clk        ),// input
    .rd_rst             (  ~ddr_rstn      ) // input
);

testt #(
    .OFFSET (230400),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_2(
    .ddr_clk                 (ddr_clk)           ,
    .wr_fsync                (ov_wr_fsync)        ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_2)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_2)          ,
    .ddr_wdata_req           (ddr_wdata_req)     ,
    .ddr_frame_done          (ddr_frame_done_2)  ,
    .ddr_wdone               (ddr_wdone_2)     ,
    //.ddr_wdone               (i_ddr_wdone)     ,

    .ddr_wdata_req_1d        (ddr_wdata_req_1d_2),
    .ddr_wreq                (ddr_wreq_2)    ,
    //.ddr_wreq                (o_ddr_wreq)    ,
    .rd_addr                 (rd_addr_2)       ,
    .rd_cnt                  (rd_cnt_2)      ,
    .rd_frame_cnt            (rd_frame_cnt_2)    ,
    .rd_wdata_1d             (rd_wdata_1d_2)   
);

// 3333
test#(
    .H_NUM(640),
    .V_NUM(360)
) hdmi_test_3(
    .wr_clk   (ov_wr_clk) ,       
    .wr_fsync (ov_wr_fsync)   ,   
    .wr_en    (ov_wr_en),         
    .ddr_rstn (ddr_rstn)   ,   
    .wr_data  (ov_wr_data)  ,     
    .ddr_rstn_2d(ddr_rstn_2d_3),
    .ddr_wdone(ddr_wdone_3),
    //.ddr_wdone               (i_ddr_wdone)     ,
    .cur_frame (cur_frame_3),
    .ddr_frame_done(ddr_frame_done_3),
    .rd_pulse (rd_pulse_3) ,
    .wr_addr  (wr_addr_3) ,
    .write_en (write_en_3) ,
    .write_data(write_data_3)    
);

wr_fram_buf hdmi_wr_fram_buf_3 (
    .wr_data            (  write_data_3     ),// input [31:0]
    .wr_addr            (  wr_addr_3        ),// input [11:0]
    .wr_en              (  write_en_3       ),// input
    .wr_clk             (  ov_wr_clk         ),// input
    .wr_rst             (  ~ddr_rstn_2d_3   ),// input
                
    .rd_addr            (  rd_addr_3        ),// input [8:0]
    .rd_data            (  hdmi_rd_wdata_3       ),// output [255:0]
    .rd_clk             (  ddr_clk        ),// input
    .rd_rst             (  ~ddr_rstn      ) // input
);

testt #(
    .OFFSET (230720),
    .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
    .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH)
) testt_hdmi_3(
    .ddr_clk                 (ddr_clk)           ,
    .wr_fsync                (ov_wr_fsync)        ,
    .ddr_rstn                (ddr_rstn)        ,
    .rd_pulse                (rd_pulse_3)        ,
    .hdmi_rd_wdata           (hdmi_rd_wdata_3)          ,
    .ddr_wdata_req           (ddr_wdata_req)     ,
    .ddr_frame_done          (ddr_frame_done_3)  ,
    .ddr_wdone               (ddr_wdone_3)     ,
    //.ddr_wdone               (i_ddr_wdone)     ,

    .ddr_wdata_req_1d        (ddr_wdata_req_1d_3),
    .ddr_wreq                (ddr_wreq_3)    ,
    //.ddr_wreq                (o_ddr_wreq)    ,
    .rd_addr                 (rd_addr_3)       ,
    .rd_cnt                  (rd_cnt_3)      ,
    .rd_frame_cnt            (rd_frame_cnt_3)    ,
    .rd_wdata_1d             (rd_wdata_1d_3)   
);

reg [11:0] del_cnt=0;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge ddr_clk)
    begin 
        if(ddr_frame_done_0 || ddr_frame_done_1 || ddr_frame_done_2 || ddr_frame_done_3)
            del_cnt <= 11'd0;
        else if(del_cnt == 12'hfff)
            del_cnt <= del_cnt;
        else del_cnt <= del_cnt + 1'b1;
    end 
//reg first = 1;
//    always @(posedge ddr_clk)
//    begin 
//        if(ddr_frame_done_0)
//            first <= 1'b0;
//    end 
reg [1:0] sel = HDMI_1;/*synthesis PAP_MARK_DEBUG="1"*/
//assign sel = ddr_frame_done_0 ? HDMI_2 :
//             ddr_frame_done_1 ? HDMI_3 :
//             ddr_frame_done_2 ? HDMI_1 :
//             ddr_frame_done_3 ? HDMI_1 :
//                        first ? HDMI_1 :
//                                sel    ;
//assign sel = HDMI_2;

    always @(posedge ddr_clk)
    begin 
        if(ddr_frame_done_0)begin
            sel <= HDMI_2;
        end
        else if(ddr_frame_done_1) begin
            sel <= HDMI_3;
        end
        else if(ddr_frame_done_2) begin
            sel <= HDMI_4;
        end
        else if(ddr_frame_done_3) begin
            sel <= HDMI_1;
        end
    end 


assign o_ddr_wreq = sel == HDMI_1 ? ddr_wreq   :
                    sel == HDMI_2 ? ddr_wreq_1 :
                    sel == HDMI_3 ? ddr_wreq_2 :
                    sel == HDMI_4 ? ddr_wreq_3 :
                                    0;

//assign ddr_wdone   = sel == HDMI_1 & del_cnt > 10 ? i_ddr_wdone : 0;
//assign ddr_wdone_1 = sel == HDMI_2 & del_cnt > 10 ? i_ddr_wdone : 0;
//assign ddr_wdone_2 = sel == HDMI_3 & del_cnt > 10 ? i_ddr_wdone : 0;
//assign ddr_wdone_3 = sel == HDMI_4 & del_cnt > 10 ? i_ddr_wdone : 0;


    always @(posedge ddr_clk)
    begin 
        if(sel == HDMI_1 & del_cnt > 50)begin
            ddr_wdone <= i_ddr_wdone;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= 0;
        end
        else if(sel == HDMI_2 & del_cnt > 50) begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= i_ddr_wdone;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= 0;
        end
        else if(sel == HDMI_3 & del_cnt > 50)begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= i_ddr_wdone;
            ddr_wdone_3 <= 0;
        end
        else if(sel == HDMI_4 & del_cnt > 50)begin
            ddr_wdone <= 0;
            ddr_wdone_1 <= 0;
            ddr_wdone_2 <= 0;
            ddr_wdone_3 <= i_ddr_wdone;
        end
    end 

    assign ddr_wdata  = sel == HDMI_1 & ~ddr_wdata_req_1d   & ddr_wdata_req ? rd_wdata_1d   : 
                        sel == HDMI_2 & ~ddr_wdata_req_1d_1 & ddr_wdata_req ? rd_wdata_1d_1 : 
                        sel == HDMI_3 & ~ddr_wdata_req_1d_2 & ddr_wdata_req ? rd_wdata_1d_2 : 
                        sel == HDMI_4 & ~ddr_wdata_req_1d_3 & ddr_wdata_req ? rd_wdata_1d_3 : 
                        sel == HDMI_1 ? hdmi_rd_wdata   : 
                        sel == HDMI_2 ? hdmi_rd_wdata_1 : 
                        sel == HDMI_3 ? hdmi_rd_wdata_2 : 
                        sel == HDMI_4 ? hdmi_rd_wdata_3 : 0;

    assign ddr_waddr  = sel == HDMI_1 ? {test_f_rd_cnt[0],rd_cnt}     :   
                        sel == HDMI_2 ? {test_f_rd_cnt[0],rd_cnt_1} :   
                        sel == HDMI_3 ? {test_f_rd_cnt[0],rd_cnt_2} :   
                        sel == HDMI_4 ? {test_f_rd_cnt[0],rd_cnt_3} : 0;
    reg [FRAME_CNT_WIDTH - 1'b1 :0] test_f_rd_cnt = 0;
    always @(posedge ddr_clk)
    begin 
        if(ddr_frame_done_1) begin
            test_f_rd_cnt <= test_f_rd_cnt + 1'b1;
        end
    end 
/*
    assign ddr_wdata  = (~ddr_wdata_req_1d_1) & ddr_wdata_req ? rd_wdata_1d_1 : hdmi_rd_wdata_1;
    assign ddr_waddr  = {rd_frame_cnt_1[0],rd_cnt_1};

    assign ddr_wdata  = (~ddr_wdata_req_1d_2) & ddr_wdata_req ? rd_wdata_1d_2 : hdmi_rd_wdata_2;
    assign ddr_waddr  = {rd_frame_cnt_2[0],rd_cnt_2};

    assign ddr_wdata  = (~ddr_wdata_req_1d_3) & ddr_wdata_req ? rd_wdata_1d_3 : hdmi_rd_wdata_3;
    assign ddr_waddr  = {rd_frame_cnt_3[0],rd_cnt_3};
*/
    assign ddr_frame_done = ddr_frame_done_0 || ddr_frame_done_1 || ddr_frame_done_2 || ddr_frame_done_3;
    assign ddr_wr_len = 40; // 120 -- 60
    
endmodule