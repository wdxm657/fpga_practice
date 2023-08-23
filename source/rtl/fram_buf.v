`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 14:17:29
// Design Name: 
// Module Name: fram_buf
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
module fram_buf #(
    parameter                     MEM_ROW_WIDTH        = 15    ,
    parameter                     MEM_COLUMN_WIDTH     = 10    ,
    parameter                     MEM_BANK_WIDTH       = 3     ,
    parameter                     CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH,
    parameter                     MEM_DQ_WIDTH         = 32    ,
    parameter                     H_NUM                = 12'd1280,//12'd1920,
    parameter                     V_NUM                = 12'd720,//12'd1080,//12'd106,//
    parameter                     PIX_WIDTH            = 16//24 
)(
    // ov5640 
    input                         l_ov_vin_clk,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         l_ov_wr_fsync,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         l_ov_wr_en,
    input  [24 - 1'b1 : 0]        l_ov_wr_data,
    // ov5640 
    input                         r_ov_vin_clk,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         r_ov_wr_fsync,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         r_ov_wr_en,
    input  [24 - 1'b1 : 0]        r_ov_wr_data,
    // hdmi 
    input                         hdmi_vin_clk,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         hdmi_wr_fsync,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         hdmi_wr_en,
    input  [24 - 1'b1 : 0]        hdmi_wr_data,
    // eth 
    input                         eth_vin_clk,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         eth_wr_fsync,/*synthesis PAP_MARK_DEBUG="1"*/
    input                         eth_wr_en,
    input  [16 - 1'b1 : 0]        eth_wr_data,

    output reg                    init_done=0,

    // ddr
    input                         ddr_clk,
    input                         ddr_rstn,
    // hdmi
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    output                        vout_de,
    output [PIX_WIDTH - 1'b1 : 0]  vout_data,
    
    output [CTRL_ADDR_WIDTH-1:0]  axi_awaddr     ,
    output [3:0]                  axi_awid       ,
    output [3:0]                  axi_awlen      ,
    output [2:0]                  axi_awsize     ,
    output [1:0]                  axi_awburst    ,
    input                         axi_awready    ,
    output                        axi_awvalid    ,
                                                  
    output [MEM_DQ_WIDTH*8-1:0]   axi_wdata      ,
    output [MEM_DQ_WIDTH -1 :0]   axi_wstrb      ,
    input                         axi_wlast      ,
    output                        axi_wvalid     ,
    input                         axi_wready     ,
    input  [3 : 0]                axi_bid        ,

    output [CTRL_ADDR_WIDTH-1:0]  axi_araddr     ,
    output [3:0]                  axi_arid       ,
    output [3:0]                  axi_arlen      ,
    output [2:0]                  axi_arsize     ,
    output [1:0]                  axi_arburst    ,
    output                        axi_arvalid    ,
    input                         axi_arready    ,

    output                        axi_rready     ,
    input  [MEM_DQ_WIDTH*8-1:0]   axi_rdata      ,
    input                         axi_rvalid     ,
    input                         axi_rlast      ,
    input  [3:0]                  axi_rid            
);
    parameter LEN_WIDTH       = MEM_DQ_WIDTH;
    parameter LINE_ADDR_WIDTH = 22;//1920*1080:22 1280*720:20 1440*1080:22
    parameter FRAME_CNT_WIDTH = CTRL_ADDR_WIDTH - LINE_ADDR_WIDTH;
    
    wire                             ddr_wr_bac;
    wire                             ddr_wreq;  /*synthesis PAP_MARK_DEBUG="1"*/   
    wire [CTRL_ADDR_WIDTH- 1'b1 : 0] ddr_waddr;  /*synthesis PAP_MARK_DEBUG="1"*/  
    wire [LEN_WIDTH- 1'b1 : 0]       ddr_wr_len;  
    wire                             ddr_wrdy;     
    wire                             ddr_wdone;    
    wire [8*MEM_DQ_WIDTH-1 : 0]      ddr_wdata;   
    wire                             ddr_wdata_req;


    wire                        rd_cmd_en   ;
    wire [CTRL_ADDR_WIDTH-1:0]  rd_cmd_addr ;
    wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len  ;
    wire                        rd_cmd_ready;
    wire                        rd_cmd_done;
                                
    wire                        read_ready  = 1'b1;
    wire [8*MEM_DQ_WIDTH-1:0]   read_rdata  ;
    wire                        read_en     ;


wire [23:0] hdmi_scale;
wire [15:0] hdmi_scale_565;
assign hdmi_scale_565 = {(hdmi_scale[23:19]), (hdmi_scale[15:10]), (hdmi_scale[7:3])};
wire  hdmi_scaler_vld;
scaler#(
    .H(1920),
    .V(1080),
    .H_SCALE(640),
    .V_SCALE(360) 
) hdmi_scaler(
    .clk            (hdmi_vin_clk),
    .rst_n          (ddr_rstn),
    .vs_in          (hdmi_wr_fsync), 
    .de_in          (hdmi_wr_en),
    .data_in        (hdmi_wr_data),
    
    .scaler_data_out         (hdmi_scale),
    .scaler_data_vld         (hdmi_scaler_vld)
);

wire [23:0] l_ov_scale;
wire [15:0] l_ov_scale_565;
assign l_ov_scale_565 = {(l_ov_scale[23:19]), (l_ov_scale[15:10]), (l_ov_scale[7:3])};
wire   l_ov_scaler_vld;
scaler#(
    .H(1280),
    .V(720),
    .H_SCALE(640),
    .V_SCALE(360) 
) ov5640_scaler_l(
    .clk            (l_ov_vin_clk),
    .rst_n          (ddr_rstn), 
    .vs_in          (l_ov_wr_fsync), 
    .de_in          (l_ov_wr_en),
    .data_in        (l_ov_wr_data),
    
    .scaler_data_out         (l_ov_scale),
    .scaler_data_vld         (l_ov_scaler_vld)
);

wire [23:0] r_ov_scale;
wire [15:0] r_ov_scale_565;
assign r_ov_scale_565 = {(r_ov_scale[23:19]), (r_ov_scale[15:10]), (r_ov_scale[7:3])};
wire   r_ov_scaler_vld;
scaler#(
    .H(1280),
    .V(720),
    .H_SCALE(640),
    .V_SCALE(360) 
) ov5640_scaler_r(
    .clk            (r_ov_vin_clk),
    .rst_n          (ddr_rstn), 
    .vs_in          (r_ov_wr_fsync), 
    .de_in          (r_ov_wr_en),
    .data_in        (r_ov_wr_data),
    
    .scaler_data_out         (r_ov_scale),
    .scaler_data_vld         (r_ov_scaler_vld)
);

wire hdmi_frame_wirq;
wire ddr_frame_done;/*synthesis PAP_MARK_DEBUG="1"*/
wire [3:0] current_4_frame_flag;
    wr_scale_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET      (  0                ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  1280            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  720            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) wr_2_ddr_buf (                                       
        .ddr_clk          (  ddr_clk          ),//input                         ddr_clk,
        .ddr_rstn         (  ddr_rstn         ),//input                         ddr_rstn,

        .wr_fsync         (  hdmi_wr_fsync         ),//input                         wr_fsync,                                  
        .wr_clk           (  hdmi_vin_clk          ),//input                         wr_clk,
        .wr_en            (  hdmi_scaler_vld            ),//input                         wr_en,
        .wr_data          (  hdmi_scale_565     ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,

        .l_ov_wr_fsync         (  l_ov_wr_fsync         ),//input                         wr_fsync,                                  
        .l_ov_wr_clk           (  l_ov_vin_clk          ),//input                         wr_clk,
        .l_ov_wr_en            (  l_ov_scaler_vld            ),//input                         wr_en,
        .l_ov_wr_data          (  l_ov_scale_565     ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,

        .r_ov_wr_fsync         (  r_ov_wr_fsync         ),//input                         wr_fsync,                                  
        .r_ov_wr_clk           (  r_ov_vin_clk          ),//input                         wr_clk,
        .r_ov_wr_en            (  r_ov_scaler_vld            ),//input                         wr_en,
        .r_ov_wr_data          (  r_ov_scale_565     ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,

        .eth_wr_fsync         (  eth_wr_fsync         ),//input                         wr_fsync,                                  
        .eth_wr_clk           (  eth_vin_clk          ),//input                         wr_clk,
        .eth_wr_en            (  eth_wr_en            ),//input                         wr_en,
        .eth_wr_data          (  eth_wr_data     ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
        
        .rd_bac           (  ddr_wr_bac       ),//input                         rd_bac,                                      
        .o_ddr_wreq         (  ddr_wreq         ),//output                        ddr_wreq,
        .ddr_waddr        (  ddr_waddr        ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
        .ddr_wr_len       (  ddr_wr_len       ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
        .ddr_wrdy         (  ddr_wrdy         ),//input                         ddr_wrdy,
        .i_ddr_wdone        (  ddr_wdone        ),//input                         ddr_wdone,
        .ddr_wdata        (  ddr_wdata        ),//output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
        .ddr_wdata_req    (  ddr_wdata_req    ),//input                         ddr_wdata_req,

        .current_4_frame_flag(current_4_frame_flag),
        .ddr_frame_done   (  ddr_frame_done    )//output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
    );

    always @(posedge ddr_clk)
    begin
        if(ddr_frame_done)
            init_done <= 1'b1;
        else
            init_done <= init_done;
    end 
    
    rd_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) rd_f_ddr_buf (
        .ddr_clk         (  ddr_clk           ),//input                         ddr_clk,
        .ddr_rstn        (  ddr_rstn          ),//input                         ddr_rstn,

        .vout_clk        (  vout_clk          ),//input                         vout_clk,
        .rd_fsync        (  rd_fsync          ),//input                         rd_fsync,
        .rd_en           (  rd_en             ),//input                         rd_en,
        .vout_de         (  vout_de           ),//output                        vout_de,
        .vout_data       (  vout_data         ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
        .current_4_frame_flag        (current_4_frame_flag),
      
        .ddr_rreq        (  rd_cmd_en         ),//output                        ddr_rreq,
        .ddr_raddr       (  rd_cmd_addr       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len      (  rd_cmd_len        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rrdy        (  rd_cmd_ready      ),//input                         ddr_rrdy,
        .ddr_rdone       (  rd_cmd_done       ),//input                         ddr_rdone,
                                              
        .ddr_rdata       (  read_rdata        ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en    (  read_en           ) //input                         ddr_rdata_en,
    );
    
    wr_rd_ctrl_top#(
        .CTRL_ADDR_WIDTH  (  CTRL_ADDR_WIDTH  ),//parameter                    CTRL_ADDR_WIDTH      = 28,
        .MEM_DQ_WIDTH     (  MEM_DQ_WIDTH     ) //parameter                    MEM_DQ_WIDTH         = 16
    )wr_rd_ctrl_top (                         
        .clk              (  ddr_clk          ),//input                        clk            ,            
        .rstn             (  ddr_rstn         ),//input                        rstn           ,            
                                              
        .wr_cmd_en        (  ddr_wreq         ),//input                        wr_cmd_en   ,
        .wr_cmd_addr      (  ddr_waddr        ),//input  [CTRL_ADDR_WIDTH-1:0] wr_cmd_addr ,
        .wr_cmd_len       (  ddr_wr_len       ),//input  [31??0]               wr_cmd_len  ,
        .wr_cmd_ready     (  ddr_wrdy         ),//output                       wr_cmd_ready,
        .wr_cmd_done      (  ddr_wdone        ),//output                       wr_cmd_done,
        .wr_bac           (  ddr_wr_bac       ),//output                       wr_bac,                                     
        .wr_ctrl_data     (  ddr_wdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  wr_ctrl_data,
        .wr_data_re       (  ddr_wdata_req    ),//output                       wr_data_re  ,
                                              
        .rd_cmd_en        (  rd_cmd_en        ),//input                        rd_cmd_en   ,
        .rd_cmd_addr      (  rd_cmd_addr      ),//input  [CTRL_ADDR_WIDTH-1:0] rd_cmd_addr ,
        .rd_cmd_len       (  rd_cmd_len       ),//input  [31??0]               rd_cmd_len  ,
        .rd_cmd_ready     (  rd_cmd_ready     ),//output                       rd_cmd_ready, 
        .rd_cmd_done      (  rd_cmd_done      ),//output                       rd_cmd_done,
                                              
        .read_ready       (  read_ready       ),//input                        read_ready  ,    
        .read_rdata       (  read_rdata       ),//output [MEM_DQ_WIDTH*8-1:0]  read_rdata  ,    
        .read_en          (  read_en          ),//output                       read_en     ,                                          
        // write channel                        
        .axi_awaddr       (  axi_awaddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_awaddr     ,  
        .axi_awid         (  axi_awid         ),//output [3:0]                 axi_awid       ,
        .axi_awlen        (  axi_awlen        ),//output [3:0]                 axi_awlen      ,
        .axi_awsize       (  axi_awsize       ),//output [2:0]                 axi_awsize     ,
        .axi_awburst      (  axi_awburst      ),//output [1:0]                 axi_awburst    , //only support 2'b01: INCR
        .axi_awready      (  axi_awready      ),//input                        axi_awready    ,
        .axi_awvalid      (  axi_awvalid      ),//output                       axi_awvalid    ,
                                              
        .axi_wdata        (  axi_wdata        ),//output [MEM_DQ_WIDTH*8-1:0]  axi_wdata      ,
        .axi_wstrb        (  axi_wstrb        ),//output [MEM_DQ_WIDTH -1 :0]  axi_wstrb      ,
        .axi_wlast        (  axi_wlast        ),//output                       axi_wlast      ,
        .axi_wvalid       (  axi_wvalid       ),//output                       axi_wvalid     ,
        .axi_wready       (  axi_wready       ),//input                        axi_wready     ,
        .axi_bid          (  4'd0             ),//input  [3 : 0]               axi_bid        , // Master Interface Write Response.
        .axi_bresp        (  2'd0             ),//input  [1 : 0]               axi_bresp      , // Write response. This signal indicates the status of the write transaction.
        .axi_bvalid       (  1'b0             ),//input                        axi_bvalid     , // Write response valid. This signal indicates that the channel is signaling a valid write response.
        .axi_bready       (                   ),//output                       axi_bready     ,
                                              
        // read channel                          
        .axi_araddr       (  axi_araddr       ),//output [CTRL_ADDR_WIDTH-1:0] axi_araddr     ,    
        .axi_arid         (  axi_arid         ),//output [3:0]                 axi_arid       ,
        .axi_arlen        (  axi_arlen        ),//output [3:0]                 axi_arlen      ,
        .axi_arsize       (  axi_arsize       ),//output [2:0]                 axi_arsize     ,
        .axi_arburst      (  axi_arburst      ),//output [1:0]                 axi_arburst    ,
        .axi_arvalid      (  axi_arvalid      ),//output                       axi_arvalid    , 
        .axi_arready      (  axi_arready      ),//input                        axi_arready    , //only support 2'b01: INCR
                                              
        .axi_rready       (  axi_rready       ),//output                       axi_rready     ,
        .axi_rdata        (  axi_rdata        ),//input  [MEM_DQ_WIDTH*8-1:0]  axi_rdata      ,
        .axi_rvalid       (  axi_rvalid       ),//input                        axi_rvalid     ,
        .axi_rlast        (  axi_rlast        ),//input                        axi_rlast      ,
        .axi_rid          (  axi_rid          ),//input  [3:0]                 axi_rid        ,
        .axi_rresp        (  2'd0             ) //input  [1:0]                 axi_rresp      
    );


endmodule
