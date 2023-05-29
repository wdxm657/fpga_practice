`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 15:02:21
// Design Name: 
// Module Name: rd_buf
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
module pcie_rd_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8
)  (
    input                         ddr_clk,
    input                         ddr_rstn,

    // pcie
    input                         pcie_clk,
    input                         pcie_vs,
    input                         i_pcie_mwr_en,
    input                         pcie_init_done,
    output [127:0]                o_ddr_data,
    output                        o_pcie_mwr_en,
    
    input                         cpu_data_en,
    input  [127:0]                cpu_data,
    input                         init_done,
    input                         current_fram_addr/*synthesis PAP_MARK_DEBUG="1"*/,    

    output                        ddr_rreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en 
);
    localparam SIM            = 1'b0;
    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_ONE_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH;  // 1920 * 16 / 32 = 960
    localparam RD_ONE_LINE_NUM    = WR_ONE_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // 960 * 32 / 256 = 120
    localparam DDR_ADDR_OFFSET= RD_ONE_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;  // 120 * 256 / 32 = 960

    // =========================================================================
    reg   [7:0]   pcie_rd_h_cnt;
    reg   [10:0]   pcie_rd_f_cnt;
    reg     pcie_hsync;
    reg     pcie_vsync;
    // 记录pcie读取一帧的总次数
    // i_pcie_mwr_en再此延迟1个时钟
    // pcie_vsync low 表示读FIFO复位
    // 一行1920*16=30720个数据   PCIE读30720/128=240次为1行
    always @(posedge pcie_clk)
    if(~init_done)begin
        pcie_rd_h_cnt <= 8'd1;
        pcie_rd_f_cnt <= 11'd1;
        pcie_hsync <= 1'b0;
        pcie_vsync <= 1'b0;
    end
    else if(i_pcie_mwr_en & pcie_init_done & (pcie_rd_h_cnt < 8'd240))
    begin
        pcie_rd_h_cnt <= pcie_rd_h_cnt + 1'b1;
        pcie_hsync <= 1'b1;
        if (pcie_rd_f_cnt < V_NUM)
            pcie_vsync <= 1'b1;
        else begin
            pcie_vsync <= 1'b0;
            pcie_rd_f_cnt <= 11'd0;
        end
    end 
    else if(pcie_rd_h_cnt == 8'd240) begin
        pcie_rd_h_cnt <= 8'd0;
        pcie_rd_f_cnt <= pcie_rd_f_cnt + 1'b1;
        pcie_hsync <= 1'b0;
    end
    else pcie_hsync <= pcie_hsync;

    wire     wr_rst;
    reg      wr_fsync_1d,wr_fsync_2d,wr_fsync_3d;
    reg      init_done_d1,init_done_d2,init_done_d3;
    reg      wr_en_1d,wr_en_2d,wr_en_3d;
    reg      wr_trig;
    reg [11:0] wr_line;
    // 这个模块消耗
    always @(posedge ddr_clk)
    begin
        init_done_d1 <= init_done;
        init_done_d2 <= init_done_d1;
        init_done_d3 <= init_done_d2;
        // vs in
        wr_fsync_1d <= pcie_vs;
        wr_fsync_2d <= wr_fsync_1d;
        wr_fsync_3d <= wr_fsync_2d;
        
        // de in
        wr_en_1d <= pcie_hsync;
        wr_en_2d <= wr_en_1d;
        wr_en_3d <= wr_en_2d;
        
        // 使用PCIE一行读完的下降沿作为复位给到ddr读信号，即DDR一直在读，但是由于是复位信号，不会影响FIFO和DDR读写的地址
        // 使用PCIE帧读取信号的下降沿作为复位信号，准备数据给下一帧使用
        wr_trig <= wr_rst || (~wr_en_3d && wr_en_2d && wr_line != V_NUM);
    end 
    always @(posedge ddr_clk)
    begin
        if(wr_rst || (~ddr_rstn))
            wr_line <= 12'd1;
        else if(wr_trig)
            wr_line <= wr_line + 12'd1;
    end 
    
    assign wr_rst = (~wr_fsync_3d && wr_fsync_2d) | (~init_done_d3 && init_done_d2);
    
    //==========================================================================
    reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt=0;
    always @(posedge ddr_clk)
    begin
        if(wr_rst)
            wr_frame_cnt <= wr_frame_cnt + 1'b1;
        else
            wr_frame_cnt <= wr_frame_cnt;
    end 

    reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    always @(posedge ddr_clk)
    begin 
        if(wr_rst)
            wr_cnt <= 9'd0;
        else if(ddr_rdone)
            wr_cnt <= wr_cnt + DDR_ADDR_OFFSET;
        else
            wr_cnt <= wr_cnt;
    end 
    
    assign ddr_rreq = wr_trig;
    assign ddr_raddr = {wr_frame_cnt[0],wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = RD_ONE_LINE_NUM;
    
    reg  [ 8:0]           wr_addr;
    reg  [ 8:0]           rd_addr;
    wire [256-1:0]  rd_data;
    
    //===========================================================================
    always @(posedge ddr_clk)
    begin
        if(wr_rst)
            wr_addr <= (SIM == 1'b1) ? 9'd180 : 9'd0;
        else if(ddr_rdata_en)
            wr_addr <= wr_addr + 9'd1;
        else
            wr_addr <= wr_addr;
    end 

    pcie_rd_fram_buf pcie_rd_fram_buf (
        .wr_data    (  ddr_rdata       ),// input [255:0]            
        .wr_addr    (  wr_addr         ),// input [8:0]              
        .wr_en      (  ddr_rdata_en    ),// input                    
        .wr_clk     (  ddr_clk         ),// input                    
        .wr_rst     (  ~ddr_rstn       ),// input                    
        .rd_addr    (  rd_addr         ),// input [8:0]             
        .rd_data    (  rd_data         ),// output [255:0]            
        .rd_clk     (  pcie_clk        ),// input                    
        .rd_rst     (  ~ddr_rstn_2d    ) // input                    
    );
    
    reg [1:0] rd_cnt;
    wire      read_en;
    always @(posedge pcie_clk)
    begin
        // de_in cnt
        if(i_pcie_mwr_en)
            rd_cnt <= rd_cnt + 1'b1;
        else
            rd_cnt <= 2'd0;
    end

    reg       rd_fsync_1d;
    reg       rd_en_1d,rd_en_2d;
    wire      rd_rst;
    reg       ddr_rstn_1d,ddr_rstn_2d;
    always @(posedge pcie_clk)
    begin
        rd_fsync_1d <= pcie_vs;
        rd_en_1d <= i_pcie_mwr_en; 
        rd_en_2d <= rd_en_1d;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
    end 
    assign rd_rst = (~rd_fsync_1d && pcie_vs);

    always @(posedge pcie_clk)
    begin
        if(rd_rst)
            rd_addr <= 'd0;
        else if(read_en)
            rd_addr <= rd_addr + 1'b1;
        else
            rd_addr <= rd_addr;
    end 
    
    reg [127:0] read_data;
    reg [255:0] rd_data_1d;
    always @(posedge pcie_clk)
    begin
        rd_data_1d <= rd_data;
    end 
    
    assign read_en = i_pcie_mwr_en && (rd_cnt[0] != 1'b1);
    
    always @(posedge pcie_clk)
    begin
        if(rd_en_1d)
        begin
            if(rd_cnt[0])
                read_data <= rd_data[127:0];
            else
                read_data <= rd_data_1d[255:128];
        end 
        else
            read_data <= 'd0;
    end 
    
    assign o_pcie_mwr_en = rd_en_2d;
    assign o_ddr_data = read_data;
endmodule
