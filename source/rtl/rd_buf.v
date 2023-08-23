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
module rd_buf #(
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
    
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en/*synthesis PAP_MARK_DEBUG="1"*/,
    output                        vout_de,
    output [PIX_WIDTH- 1'b1 : 0]  vout_data,
    
    output                        ddr_rreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    input                         ddr_rrdy,
    input                         ddr_rdone,
    input                 [3:0]   current_4_frame_flag/*synthesis PAP_MARK_DEBUG="1"*/,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en 
);
    localparam SIM            = 1'b0;
    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_ONE_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH;  // 1280 * 16 / 32 = 640
    localparam RD_ONE_LINE_NUM    = WR_ONE_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // 640 * 32 / 256 = 80
    localparam DDR_ADDR_OFFSET= RD_ONE_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH;  // 80 * 256 / 32 = 640
    
    //===========================================================================
    reg       rd_fsync_1d;
    reg       rd_en_1d,rd_en_2d;
    wire      rd_rst;
    reg       ddr_rstn_1d,ddr_rstn_2d;
    always @(posedge vout_clk)
    begin
        rd_fsync_1d <= rd_fsync;
        rd_en_1d <= rd_en; 
        rd_en_2d <= rd_en_1d;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
    end 
    assign rd_rst = ~rd_fsync_1d &rd_fsync;
    
    reg [11:0] h_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge vout_clk)
    begin
        if(rd_fsync)
            h_cnt <= 12'd0;
        else if(rd_en)
            h_cnt <= h_cnt + 12'd1;
        else h_cnt <= 12'd0;
    end 
    reg [11:0] v_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge vout_clk)
    begin
        if(rd_fsync)
            v_cnt <= 12'd0;
        else if(h_cnt == H_NUM)
            v_cnt <= v_cnt + 12'd1;
        else v_cnt <= v_cnt;
    end 

wire hdmi1,hdmi2,hdmi3,hdmi4;/*synthesis PAP_MARK_DEBUG="1"*/
assign hdmi1 = h_cnt >= 1 & h_cnt <= 3;/*synthesis PAP_MARK_DEBUG="1"*/
assign hdmi2 = h_cnt >= 641 & h_cnt <= 643;/*synthesis PAP_MARK_DEBUG="1"*/
assign hdmi3 = v_cnt >= 0 & v_cnt <= 359;/*synthesis PAP_MARK_DEBUG="1"*/
assign hdmi4 = v_cnt >= 360 & v_cnt <= 720;/*synthesis PAP_MARK_DEBUG="1"*/
reg hdmi1_d1,hdmi1_d2,hdmi1_d3;
reg hdmi2_d1,hdmi2_d2,hdmi2_d3;
    //===========================================================================
    reg      wr_fsync_1d,wr_fsync_2d,wr_fsync_3d;
    wire     wr_rst;
    
    reg      wr_en_1d,wr_en_2d,wr_en_3d;/*synthesis PAP_MARK_DEBUG="1"*/
    reg      wr_trig;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] wr_line;
    always @(posedge ddr_clk)
    begin
        // vs in
        wr_fsync_1d <= rd_fsync;
        wr_fsync_2d <= wr_fsync_1d;
        wr_fsync_3d <= wr_fsync_2d;
        
        // de in
        hdmi1_d1 <= hdmi1;
        hdmi1_d2 <= hdmi1_d1;
        hdmi1_d3 <= hdmi1_d2;
        hdmi2_d1 <= hdmi2;
        hdmi2_d2 <= hdmi2_d1;
        hdmi2_d3 <= hdmi2_d2;
        wr_en_1d <= rd_en;
        wr_en_2d <= wr_en_1d;
        wr_en_3d <= wr_en_2d;
        
        // de_in pos
        wr_trig <= wr_rst || (normal_line && (wr_line != V_NUM));
        //wr_trig <= wr_rst || (line_fist || line_secd && (wr_line != V_NUM * 2));
    end 
    always @(posedge ddr_clk)
    begin
        if(wr_rst || (~ddr_rstn))
            wr_line <= 12'd1;
        else if(wr_trig)
            wr_line <= wr_line + 12'd1;
    end 
    wire normal_line;/*synthesis PAP_MARK_DEBUG="1"*/
    assign normal_line = wr_en_2d & ~wr_en_3d;
    wire line_fist;/*synthesis PAP_MARK_DEBUG="1"*/
    assign line_fist = hdmi1_d2 & ~hdmi1_d3;
    wire line_secd;/*synthesis PAP_MARK_DEBUG="1"*/
    assign line_secd = hdmi2_d2 & ~hdmi2_d3;
    // vs pos
    assign wr_rst = ~wr_fsync_3d && wr_fsync_2d;
    
    //==========================================================================
   reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt;
   always @(posedge ddr_clk)
   begin 
       if(wr_rst)
           wr_frame_cnt <= wr_frame_cnt + 1'b1;
       else
           wr_frame_cnt <= wr_frame_cnt;
   end 
   //always @(*)
   //begin 
   //    if(wr_trig)begin
   //        if (hdmi3 & hdmi1)
   //            wr_frame_cnt <= ~current_4_frame_flag[3];
   //        else if (hdmi3 & hdmi2)
   //            wr_frame_cnt <= ~current_4_frame_flag[2];
   //        else if (hdmi4 & hdmi1)
   //            wr_frame_cnt <= ~current_4_frame_flag[1];
   //        else if (hdmi4 & hdmi2)
   //            wr_frame_cnt <= ~current_4_frame_flag[0];
   //        else wr_frame_cnt <= 0;
   //    end
   //    else wr_frame_cnt <= wr_frame_cnt;
   //end 

    reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    always @(posedge ddr_clk)
    begin 
        if(wr_rst)
            wr_cnt <= 9'd0;
        else if(ddr_rdone)
            wr_cnt <= wr_cnt + 640;
        else
            wr_cnt <= wr_cnt;
    end 
    
    assign ddr_rreq = wr_trig;
    assign ddr_raddr = {wr_frame_cnt[0],wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = 80;
    
    reg  [ 8:0]           wr_addr;
    reg  [11:0]           rd_addr;
    wire [RAM_WIDTH-1:0]  rd_data;
    
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

    rd_fram_buf rd_fram_buf (
        .wr_data    (  ddr_rdata       ),// input [255:0]            
        .wr_addr    (  wr_addr         ),// input [8:0]              
        .wr_en      (  ddr_rdata_en    ),// input                    
        .wr_clk     (  ddr_clk         ),// input                    
        .wr_rst     (  ~ddr_rstn       ),// input                    
        .rd_addr    (  rd_addr         ),// input [11:0]             
        .rd_data    (  rd_data         ),// output [31:0]            
        .rd_clk     (  vout_clk        ),// input                    
        .rd_rst     (  ~ddr_rstn_2d    ) // input                    
    );
    
    reg [1:0] rd_cnt;
    wire      read_en;
    always @(posedge vout_clk)
    begin
        // de_in cnt
        if(rd_en)
            rd_cnt <= rd_cnt + 1'b1;
        else
            rd_cnt <= 2'd0;
    end 
    
    always @(posedge vout_clk)
    begin
        if(rd_rst)
            rd_addr <= 'd0;
        else if(read_en)
            rd_addr <= rd_addr + 1'b1;
        else
            rd_addr <= rd_addr;
    end 
    
    reg [PIX_WIDTH- 1'b1 : 0] read_data;
    reg [RAM_WIDTH-1:0]       rd_data_1d;
    always @(posedge vout_clk)
    begin
        rd_data_1d <= rd_data;
    end 
    
    generate
    if(PIX_WIDTH == 6'd24)
    begin
        // de_in
        assign read_en = rd_en && (rd_cnt != 2'd3);
        
        always @(posedge vout_clk)
        begin
            if(rd_en_1d)
            begin
                if(rd_cnt[1:0] == 2'd1)
                    read_data <= rd_data[PIX_WIDTH-1:0];
                else if(rd_cnt[1:0] == 2'd2)
                    read_data <= {rd_data[15:0],rd_data_1d[31:PIX_WIDTH]};
                else if(rd_cnt[1:0] == 2'd3)
                    read_data <= {rd_data[7:0],rd_data_1d[31:16]};
                else
                    read_data <= rd_data_1d[31:8];
            end 
            else
                read_data <= 'd0;
        end 
    end
    else if(PIX_WIDTH == 6'd16)
    begin
        assign read_en = rd_en && (rd_cnt[0] != 1'b1);
        
        always @(posedge vout_clk)
        begin
            if(rd_en_1d)
            begin
                if(rd_cnt[0])
                    read_data <= rd_data[15:0];
                else
                    read_data <= rd_data_1d[31:16];
            end 
            else
                read_data <= 'd0;
        end 
    end
    else
    begin
        assign read_en = rd_en;
        
        always @(posedge vout_clk)
        begin
            read_data <= rd_data;
        end 
    end
endgenerate

    assign vout_de = rd_en_2d;
    assign vout_data = read_data;

endmodule
