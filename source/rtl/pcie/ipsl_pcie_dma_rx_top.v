//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:ipsl_pcie_dma_rx_top.v
//////////////////////////////////////////////////////////////////////////////
module ipsl_pcie_dma_rx_top #(
    parameter                           DEVICE_TYPE = 3'd0      ,   //3'd0:EP,3'd1:Legacy EP,3'd4:RC
    parameter                           ADDR_WIDTH  = 4'd9
)(
    input                               clk                     ,   //gen1:62.5MHz,gen2:125MHz
    input                               rst_n                   ,
    input           [2:0]               i_cfg_max_rd_req_size   ,
    //**********************************************************************
    //AXIS master interface
    input                               i_axis_master_tvld      ,
    output  wire                        o_axis_master_trdy      ,
    input           [127:0]             i_axis_master_tdata     ,
    input           [3:0]               i_axis_master_tkeep     ,
    input                               i_axis_master_tlast     ,
    input           [7:0]               i_axis_master_tuser     ,
    output  wire    [2:0]               o_trgt1_radm_pkt_halt   ,
//    input           [5:0]               i_radm_grant_tlp_type   ,
    //**********************************************************************
    //bar0 rd interface
    input                               i_bar0_rd_clk_en        ,
    input           [ADDR_WIDTH-1:0]    i_bar0_rd_addr          ,
    output  wire    [127:0]             o_bar0_rd_data          ,

    //bar2 rd interface
    input                               i_bar2_rd_clk_en        ,
    input           [ADDR_WIDTH-1:0]    i_bar2_rd_addr          ,
    output  wire    [127:0]             o_bar2_rd_data          ,

    //bar1 wr interface
    output  reg                         o_bar1_wr_en            ,
    output  reg     [ADDR_WIDTH-1:0]    o_bar1_wr_addr          ,
    output  reg     [127:0]             o_bar1_wr_data          ,
    output  reg     [15:0]              o_bar1_wr_byte_en       ,
    //**********************************************************************
    //to tx top
    //req rcv
    output  wire    [2:0]               o_mrd_tc                ,
    output  wire    [2:0]               o_mrd_attr              ,
    output  wire    [9:0]               o_mrd_length            ,
    output  wire    [15:0]              o_mrd_id                ,
    output  wire    [7:0]               o_mrd_tag               ,
    output  wire    [63:0]              o_mrd_addr              ,

    output  wire                        o_cpld_req_vld          ,
    input                               i_cpld_req_rdy          ,
    input                               i_cpld_tx_rdy           ,
    //cpld rcv
    output wire                         o_cpld_rcv,
    output    wire                      o_cpld_data_valid    ,
    output    wire   [127:0]                   axis_rx_data  ,
    output wire     [7:0]               o_cpld_tag              ,
    input                               i_tag_full              ,
    //rst tlp cnt
    output wire     [63:0]              o_dma_check_result      ,
    input                               i_tx_restart            ,
    
    // to ddr rd_buf
    output                              o_bar2_wr_en              ,
    input           [127:0]             i_rd_from_ddr             

);

wire                        mwr_wr_start;
wire    [9:0]               mwr_length;
wire    [7:0]               mwr_dwbe;
wire    [127:0]             mwr_data;
wire    [3:0]               mwr_dw_vld;
wire    [63:0]              mwr_addr;

wire                        cpld_wr_start;
wire    [9:0]               cpld_length;
wire    [6:0]               cpld_low_addr;
wire    [11:0]              cpld_byte_cnt;
wire    [127:0]             cpld_data;
wire    [3:0]               cpld_dw_vld;
wire                        multicpld_flag;

wire    [1:0]               bar_hit;

//mwr wr
wire                        mwr_wr_en;
wire    [ADDR_WIDTH-1:0]    mwr_wr_addr;
wire    [127:0]             mwr_wr_data;
wire    [15:0]              mwr_wr_be;
wire    [1:0]               mwr_wr_bar_hit;
//cpld wr
wire                        cpld_wr_en;
wire    [ADDR_WIDTH-1:0]    cpld_wr_addr;
wire    [127:0]             cpld_wr_data;
wire    [15:0]              cpld_wr_be;
wire    [1:0]               cpld_wr_bar_hit;
//bar0 wr interface
reg                         bar0_wr_en;
reg     [ADDR_WIDTH-1:0]    bar0_wr_addr;
reg     [127:0]             bar0_wr_data;
reg     [15:0]              bar0_wr_byte_en;
//bar2 wr interface

wire    [ADDR_WIDTH-1:0]    bar2_wr_addr;
wire    [127:0]             bar2_wr_data;
wire    [15:0]              bar2_wr_byte_en;

ipsl_pcie_dma_tlp_rcv #(
    .DEVICE_TYPE            (DEVICE_TYPE            )
)
u_ipsl_pcie_dma_tlp_rcv
(
    .clk                    (clk                    ),  //gen1:62.5MHz,gen2:125MHz
    .rst_n                  (rst_n                  ),

    //**********************************************************************
    //AXIS master interface
    .i_axis_master_tvld     (i_axis_master_tvld     ),
    .o_axis_master_trdy     (o_axis_master_trdy     ),
    .i_axis_master_tdata    (i_axis_master_tdata    ),
    .i_axis_master_tkeep    (i_axis_master_tkeep    ),
    .i_axis_master_tlast    (i_axis_master_tlast    ),
    .i_axis_master_tuser    (i_axis_master_tuser    ),
    .o_trgt1_radm_pkt_halt  (o_trgt1_radm_pkt_halt  ),
//    .i_radm_grant_tlp_type  (i_radm_grant_tlp_type  ),

    //**********************************************************************
    //to mwr write control
    .o_mwr_wr_start         (mwr_wr_start           ),
    .o_mwr_length           (mwr_length             ),
    .o_mwr_dwbe             (mwr_dwbe               ),
    .o_mwr_data             (mwr_data               ),
    .o_mwr_dw_vld           (mwr_dw_vld             ),
    .o_mwr_addr             (mwr_addr               ),
    //to cpld write control
    .o_cpld_wr_start        (cpld_wr_start          ),
    .o_cpld_length          (cpld_length            ),
    .o_cpld_low_addr        (cpld_low_addr          ),
    .o_cpld_byte_cnt        (cpld_byte_cnt          ),
    .o_cpld_data            (cpld_data              ),
    .axis_rx_data           (axis_rx_data),
    .o_cpld_dw_vld          (cpld_dw_vld            ),
    .o_multicpld_flag       (multicpld_flag         ),
    //write bar hit
    .o_bar_hit              (bar_hit                ),
    //**********************************************************************
    //to tx top
    //req rcv
    .o_mrd_tc               (o_mrd_tc               ),
    .o_mrd_attr             (o_mrd_attr             ),
    .o_mrd_length           (o_mrd_length           ),
    .o_mrd_id               (o_mrd_id               ),
    .o_mrd_tag              (o_mrd_tag              ),
    .o_mrd_addr             (o_mrd_addr             ),

    .o_cpld_req_vld         (o_cpld_req_vld         ),
    .i_cpld_req_rdy         (i_cpld_req_rdy         ),
    .i_cpld_tx_rdy          (i_cpld_tx_rdy          ),
    //cpld rcv
    // *** mrd cpld rcv. ,master data contain the rc data ***
    .o_cpld_rcv             (o_cpld_rcv             ),
    .cpld_data_valid        (o_cpld_data_valid),
    .o_cpld_tag             (o_cpld_tag             ),
    .i_tag_full             (i_tag_full             ),
    //rst tlp cnt
    .o_dma_check_result     (o_dma_check_result     ),
    .i_tx_restart           (i_tx_restart           )
    //.o_dbg_bus              (o_dbg_bus_rx_ctrl      ),
    //.o_dbg_tlp_rcv_cnt      (o_dbg_tlp_rcv_cnt      )
);


ipsl_pcie_dma_rx_cpld_wr_ctrl #(
    .ADDR_WIDTH             (ADDR_WIDTH             )
)
u_cpld_wr_ctrl
(
    .clk                    (clk                    ),  //gen1:62.5MHz,gen2:125MHz
    .rst_n                  (rst_n                  ),
    .i_cfg_max_rd_req_size  (i_cfg_max_rd_req_size  ),  //input [2:0]
    //****************************************
    .i_cpld_wr_start        (cpld_wr_start          ),
    .i_cpld_length          (cpld_length            ),
    .i_cpld_low_addr        (cpld_low_addr          ),
    .i_cpld_byte_cnt        (cpld_byte_cnt          ),
    .i_cpld_data            (cpld_data              ),
    .i_cpld_dw_vld          (cpld_dw_vld            ),
    .i_cpld_tag             (o_cpld_tag             ),
    .i_bar_hit              (bar_hit                ),
    .i_multicpld_flag       (multicpld_flag         ),
    //****************************************
    .o_cpld_wr_en           (cpld_wr_en             ),
    .o_cpld_wr_addr         (cpld_wr_addr           ),
    .o_cpld_wr_data         (cpld_wr_data           ),
    .o_cpld_wr_be           (cpld_wr_be             ),
    .o_cpld_wr_bar_hit      (cpld_wr_bar_hit        )
);

ipsl_pcie_dma_rx_mwr_wr_ctrl #(
    .ADDR_WIDTH             (ADDR_WIDTH             )
)
u_mwr_wr_ctrl
(
    .clk                    (clk                    ),  //gen1:62.5MHz,gen2:125MHz
    .rst_n                  (rst_n                  ),
    //****************************************
    .i_mwr_wr_start         (mwr_wr_start           ),
    .i_mwr_length           (mwr_length             ),
    .i_mwr_dwbe             (mwr_dwbe               ),
    .i_mwr_data             (mwr_data               ),
    .i_mwr_dw_vld           (mwr_dw_vld             ),
    .i_mwr_addr             (mwr_addr               ),
    .i_bar_hit              (bar_hit                ),
    //****************************************
    .o_mwr_wr_en            (mwr_wr_en              ),
    .o_mwr_wr_addr          (mwr_wr_addr            ),
    .o_mwr_wr_data          (mwr_wr_data            ),
    .o_mwr_wr_be            (mwr_wr_be              ),
    .o_mwr_wr_bar_hit       (mwr_wr_bar_hit         )
);

//bar0 interface
always@(*)
begin
    if(mwr_wr_bar_hit == 2'b0)
    begin
        bar0_wr_en       = mwr_wr_en;
        bar0_wr_addr     = mwr_wr_addr;
        bar0_wr_data     = mwr_wr_data;
        bar0_wr_byte_en  = mwr_wr_be;
    end
    else`
    begin
        bar0_wr_en       = 1'b0;
        bar0_wr_addr     = {ADDR_WIDTH{1'b0}};
        bar0_wr_data     = 128'b0;
        bar0_wr_byte_en  = 16'b0;
    end
end

//bar1 interface
always@(*)
begin
    if(bar_hit == 2'b1 && (DEVICE_TYPE == 3'b000 || DEVICE_TYPE == 3'b001))
    begin
        o_bar1_wr_en       = 1'b1;
        o_bar1_wr_addr     = mwr_addr[ADDR_WIDTH-1:0];
        o_bar1_wr_data     = mwr_data;
        o_bar1_wr_byte_en  = {{4{mwr_dwbe[3]}},{4{mwr_dwbe[2]}},{4{mwr_dwbe[1]}},{4{mwr_dwbe[0]}}};
    end
    else
    begin
        o_bar1_wr_en       = 1'b0;
        o_bar1_wr_addr     = {ADDR_WIDTH{1'b0}};
        o_bar1_wr_data     = 128'b0;
        o_bar1_wr_byte_en  = 16'b0;
    end
end

wire bar2_wr_en;/*synthesis PAP_MARK_DEBUG="1"*/
assign bar2_wr_en       = cpld_wr_en;
assign bar2_wr_addr     = cpld_wr_addr;
assign bar2_wr_data     = cpld_wr_data;
assign bar2_wr_byte_en  = cpld_wr_be;

// mwr and mrd is not assioated with bar0
ipsl_pcie_dma_ram ipsl_pcie_dma_bar0 (
    .wr_data            (bar0_wr_data               ),  // input [127:0]
    //.wr_data            (128'b1               ),  // input [127:0]
    .wr_addr            (bar0_wr_addr               ),  // input [8:0]
    .wr_en              (bar0_wr_en                 ),  // input
    .wr_byte_en         (bar0_wr_byte_en            ),  // input [15:0]
    .wr_clk             (clk                        ),  // input
    .wr_rst             (~rst_n                     ),  // input
    .rd_addr            (i_bar0_rd_addr             ),  // input [8:0]
    .rd_data            (o_bar0_rd_data             ),  // output [127:0]
    .rd_clk             (clk                        ),  // input
    .rd_clk_en          (i_bar0_rd_clk_en           ),  // input
    .rd_rst             (~rst_n                     )   // input
);

//// ddr中缓存的图像数据
//
//reg                        bar2_wr_en_d1;
//reg    [ADDR_WIDTH-1:0]    bar2_wr_addr_d1;
//reg    [15:0]              bar2_wr_byte_en_d1;
//reg                        bar2_wr_en_d2;
//reg    [ADDR_WIDTH-1:0]    bar2_wr_addr_d2;
//reg    [15:0]              bar2_wr_byte_en_d2;
//
//// 记录cpu读取的次数，2025次表示1帧读取完毕
//reg [127:0]                test_data;/*synthesis PAP_MARK_DEBUG="1"*/
//always@(posedge clk)
//begin
//    if(~rst_n) begin
//        test_data <= 128'b0;
//    end
//    // when bar2_wr_en. read pixel data from ddr3
//    // cpu 读一次dma目前最大512个DW  每次4个DW为128位
//    // 即： cpu读一次有512/4=128个128位    即每次从DDR FIFO中读取128*128 = 16384位数据
//    // HDMI 配置为1920*1080@60Hz DDR中的数据为16位一个像素，HDMI的数据也可以16位一个像素  
//    // 一行数据为1920*16=30720  一帧数据为1920*1080*16=33177600
//    // CPU需要读取33177600/16384=2025次为1帧完整图像或33177600/128=259200个PCIE CLK
//    // DDR的数据位宽为32*8=256，所以CPU每读2次即bar2_wr_en高电平2个周期读一次DDR
//    // 即 ~cpu_dma_rd_cnt[0] & bar2_wr_en 时读一次DDR
//    // 将bar2_wr_en为读DDR有效信号发送给DDR模块，使用这种应该会方便很多，
//    // 将bar2_wr_en发送给DDR模块，DDR模块根据此信号返回读出的数据到PCIE模块即可
//    // 同时注意读取DDR中的数据消耗了几个时钟周期，对于的使能和地址信号应当进行延迟
//    else if(bar2_wr_en) begin
//        if(col_cnt < 60)begin
//            test_data <= {8{16'h0000}};
//        end
//        else if(col_cnt < 120)begin
//            test_data <= {{16'hF800},{16'hF801},{16'hF802},{16'hF803},{16'hF804},{16'hF805},{16'hF806},{16'hF807}};
//        end
//        else if(col_cnt < 180)begin
//            test_data <= {8{16'h07E0}};
//        end
//        else begin
//            test_data <= {8{16'h867D}};
//        end
//    end
//    else test_data <= 128'b0;
//end
//
//assign o_bar2_wr_en = bar2_wr_en;
//always@(posedge clk)
//begin
//    if(~rst_n) begin 
//        bar2_wr_en_d1 <= 0;
//        bar2_wr_addr_d1 <= 0;
//        bar2_wr_byte_en_d1 <= 0;
//        bar2_wr_en_d2 <= 0;
//        bar2_wr_addr_d2 <= 0;
//        bar2_wr_byte_en_d2 <= 0;
//    end
//    else begin
//        bar2_wr_en_d1 <= bar2_wr_en;
//        bar2_wr_addr_d1 <= bar2_wr_addr;
//        bar2_wr_byte_en_d1 <= bar2_wr_byte_en;
//        bar2_wr_en_d2 <= bar2_wr_en_d1;
//        bar2_wr_addr_d2 <= bar2_wr_addr_d1;
//        bar2_wr_byte_en_d2 <= bar2_wr_byte_en_d1;
//    end
//end
//
//// 128位有8个pix   8*240=1920为一行
//reg [7:0]  col_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
//reg [10:0] row_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
//always@(posedge clk)
//begin
//    if(~rst_n) begin
//        col_cnt <= 8'b0;
//    end
//    else if(bar2_wr_en && col_cnt < 239) begin
//        col_cnt <= col_cnt + 1'b1;
//    end
//    else if(col_cnt == 239) col_cnt <= 8'b0;
//    else col_cnt <= col_cnt;
//end
//always@(posedge clk)
//begin
//    if(~rst_n) begin
//        row_cnt <= 10'b0;
//    end
//    else if(col_cnt == 239) begin
//        row_cnt <= row_cnt + 1'b1;
//    end
//    else if(row_cnt == 1079) row_cnt <= 8'b0;
//    else row_cnt <= row_cnt;
//end
//
//// test data use d1, ddr data use d2
//wire [127:0] data_to_cpu;/*synthesis PAP_MARK_DEBUG="1"*/
////assign data_to_cpu = endian_convert(test_data);
//assign data_to_cpu = endian_convert(i_rd_from_ddr);
//               
////convert from little endian into big endian
//function [127:0] endian_convert;
//    input [127:0] data_in;
//    begin
//        endian_convert[32*0+31:32*0+0] = {data_in[32*0+7:32*0+0], data_in[32*0+15:32*0+8], data_in[32*0+23:32*0+16], data_in[32*0+31:32*0+24]};
//        endian_convert[32*1+31:32*1+0] = {data_in[32*1+7:32*1+0], data_in[32*1+15:32*1+8], data_in[32*1+23:32*1+16], data_in[32*1+31:32*1+24]};
//        endian_convert[32*2+31:32*2+0] = {data_in[32*2+7:32*2+0], data_in[32*2+15:32*2+8], data_in[32*2+23:32*2+16], data_in[32*2+31:32*2+24]};
//        endian_convert[32*3+31:32*3+0] = {data_in[32*3+7:32*3+0], data_in[32*3+15:32*3+8], data_in[32*3+23:32*3+16], data_in[32*3+31:32*3+24]};
//    end
//endfunction

// mwr wr data
/*
ipsl_pcie_dma_ram ipsl_pcie_dma_bar2 (
    //.wr_data            (bar2_wr_data               ),  // input [127:0]
    .wr_data            (i_rd_from_ddr               ),  // input [127:0]
    .wr_addr            (bar2_wr_addr_d1               ),  // input [8:0]
    .wr_en              (bar2_wr_en_d1                 ),  // input
    .wr_byte_en         (bar2_wr_byte_en_d1            ),  // input [15:0]
    .wr_clk             (clk                        ),  // input
    .wr_rst             (~rst_n                     ),  // input
    .rd_addr            (i_bar2_rd_addr             ),  // input [8:0]
    .rd_data            (o_bar2_rd_data             ),  // output [127:0]
    .rd_clk             (clk                        ),  // input
    .rd_clk_en          (i_bar2_rd_clk_en           ),  // input
    .rd_rst             (~rst_n                     )   // input
);*/

endmodule