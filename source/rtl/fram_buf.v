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
    input                         vin_clk,
    input                         wr_fsync,
    input                         wr_en,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
    output reg                    init_done=0,
    output reg                    cpu_init_done=0,
    // ddr
    input                         ddr_clk,
    input                         ddr_rstn,
    // pcie
    input                        pcie_clk,
    input                        pcie_init_done,
    input                        i_pcie_mwr_en /*synthesis PAP_MARK_DEBUG="1"*/,
    output [127:0]               o_ddr_data    /*synthesis PAP_MARK_DEBUG="1"*/,
    // cpu
    input                        cpu_data_en   /*synthesis PAP_MARK_DEBUG="1"*/,
    input  [127:0]               cpu_data      /*synthesis PAP_MARK_DEBUG="1"*/,
    // hdmi
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    output                        vout_de,
    output [PIX_WIDTH- 1'b1 : 0]  vout_data,
    
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
    
    wire                        ddr_wreq;     
    wire [CTRL_ADDR_WIDTH- 1'b1 : 0] ddr_waddr;    
    wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len;   
    wire                        ddr_wrdy;     
    wire                        ddr_wdone;    
    wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata;    
    wire                        ddr_wdata_req;
    
    wire                        rd_cmd_en   ;
    wire [CTRL_ADDR_WIDTH-1:0]  rd_cmd_addr ;
    wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len  ;
    wire                        rd_cmd_ready;
    wire                        rd_cmd_done;
                                
    wire                        read_ready  = 1'b1;
    wire [8*MEM_DQ_WIDTH-1:0]   read_rdata  ;
    wire                        read_en     ;
    wire                        ddr_wr_bac;

    wire                        ddr_wreq_1;     
    wire [CTRL_ADDR_WIDTH- 1'b1 : 0] ddr_waddr_1;    
    wire [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len_1;   
    wire                        ddr_wrdy_1;     
    wire                        ddr_wdone_1;    
    wire [8*MEM_DQ_WIDTH-1 : 0] ddr_wdata_1;    
    wire                        ddr_wdata_req_1;
    
    wire                        rd_cmd_en_1   ;
    wire [CTRL_ADDR_WIDTH-1:0]  rd_cmd_addr_1 ;
    wire [LEN_WIDTH- 1'b1: 0]   rd_cmd_len_1  ;
    wire                        rd_cmd_ready_1;
    wire                        rd_cmd_done_1;
                                
    wire                        read_ready_1  = 1'b1;
    wire [8*MEM_DQ_WIDTH-1:0]   read_rdata_1  ;
    wire                        ddr_wr_bac_1;
    wire                        read_en_1;

    wire hdmi_ddr_cur_fram;
    wire hdmi_ddr_cur_fram_pcie;
    reg current_fram_addr;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge pcie_clk)begin
        if(~pcie_init_done)
            current_fram_addr <= 1'b0;
        else if(cpu_data_en && cpu_data == {32{4'b1000}})
            current_fram_addr <= ~hdmi_ddr_cur_fram;
        else current_fram_addr <= current_fram_addr;
    end
    reg current_fram_addr_pcie;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge pcie_clk)begin
        if(~pcie_init_done)
            current_fram_addr_pcie <= 1'b0;
        else if(cpu_data_en && cpu_data == {32{4'b1000}})
            current_fram_addr_pcie <= ~hdmi_ddr_cur_fram_pcie;
        else current_fram_addr_pcie <= current_fram_addr_pcie;
    end
    wr_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET      (  32'd0            ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) wr_buf (                                       
        .ddr_clk          (  ddr_clk          ),//input                         ddr_clk,
        .ddr_rstn         (  ddr_rstn         ),//input                         ddr_rstn,
                                              
        .wr_clk           (  vin_clk          ),//input                         wr_clk,
        .wr_fsync         (  wr_fsync         ),//input                         wr_fsync,
        .wr_en            (  wr_en            ),//input                         wr_en,
        .wr_data          (  wr_data          ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
        
        .rd_bac           (  ddr_wr_bac       ),//input                         rd_bac,                                      
        .ddr_wreq         (  ddr_wreq         ),//output                        ddr_wreq,
        .ddr_waddr        (  ddr_waddr        ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
        .ddr_wr_len       (  ddr_wr_len       ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
        .ddr_wrdy         (  ddr_wrdy         ),//input                         ddr_wrdy,
        .ddr_wdone        (  ddr_wdone        ),//input                         ddr_wdone,
        .ddr_wdata        (  ddr_wdata        ),//output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
        .ddr_wdata_req    (  ddr_wdata_req    ),//input                         ddr_wdata_req,
                                              
        .frame_wcnt       (                   ),//output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
        .frame_wirq       (  frame_wirq       ), //output                        frame_wirq
        .hdmi_ddr_cur_fram(hdmi_ddr_cur_fram  )
    );
    
    always @(posedge ddr_clk)
    if(~ddr_rstn)begin
        init_done <= 1'b0;
    end
    else begin
        if(frame_wirq)
            init_done <= 1'b1;
        else
            init_done <= init_done;
    end 
    
    pcie_rd_buf #(
        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
    ) pcie_rd_buf (
        .ddr_clk         (  ddr_clk           ),//input                         ddr_clk,
        .ddr_rstn        (  ddr_rstn          ),//input                         ddr_rstn,

        // pcie
        .pcie_clk        (pcie_clk),
        .pcie_vs         (pcie_vs),
        .pcie_init_done  (pcie_init_done),
        .i_pcie_mwr_en   (i_pcie_mwr_en),
        .o_ddr_data      (o_ddr_data),
        
        .cpu_data         (cpu_data),
        .cpu_data_en      (cpu_data_en),

        .current_fram_addr(current_fram_addr),//input
        .init_done       (  init_done         ),//input                         init_done,
      
        .ddr_rreq        (  rd_cmd_en         ),//output                        ddr_rreq,
        .ddr_raddr       (  rd_cmd_addr       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len      (  rd_cmd_len        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rrdy        (  rd_cmd_ready      ),//input                         ddr_rrdy,
        .ddr_rdone       (  rd_cmd_done       ),//input                         ddr_rdone,
                                              
        .ddr_rdata       (  read_rdata        ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en    (  read_en           ) //input                         ddr_rdata_en,
    );
    

    reg pcie;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge pcie_clk)begin
        if(~pcie_init_done)
            pcie <= 1'b0;
/*
        else if(cpu_data_en && cpu_data == {32{4'b1000}})
            pcie <= 1'b1;
        else if(cpu_data_en && cpu_data == {32{4'b1001}})
            pcie <= 1'b0;
        else
            pcie <= pcie;*/
    end
    reg pcie_vs;/*synthesis PAP_MARK_DEBUG="1"*/
    always @(posedge pcie_clk)begin
        if(~pcie_init_done)
            pcie_vs <= 1'b0;
        else if(cpu_data_en && cpu_data == {32{4'b1000}})
            pcie_vs <= 1'b1;
        else pcie_vs <= 1'b0;
    end


    wr_rd_ctrl_top#(
        .CTRL_ADDR_WIDTH  (  CTRL_ADDR_WIDTH  ),//parameter                    CTRL_ADDR_WIDTH      = 28,
        .MEM_DQ_WIDTH     (  MEM_DQ_WIDTH     ) //parameter                    MEM_DQ_WIDTH         = 16
    )wr_rd_ctrl_top (                         
        .clk              (  ddr_clk          ),//input                        clk            ,            
        .rstn             (  ddr_rstn         ),//input                        rstn           ,     
        .pcie             (pcie               ),       
                                              
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


        .wr_cmd_en_1        (  ddr_wreq_1         ),//input                        wr_cmd_en   ,
        .wr_cmd_addr_1      (  ddr_waddr_1        ),//input  [CTRL_ADDR_WIDTH-1:0] wr_cmd_addr ,
        .wr_cmd_len_1       (  ddr_wr_len_1       ),//input  [31??0]               wr_cmd_len  ,
        .wr_cmd_ready_1     (  ddr_wrdy_1         ),//output                       wr_cmd_ready,
        .wr_cmd_done_1      (  ddr_wdone_1        ),//output                       wr_cmd_done,
        .wr_bac_1           (  ddr_wr_bac_1       ),//output                       wr_bac,                                     
        .wr_ctrl_data_1     (  ddr_wdata_1        ),//input  [MEM_DQ_WIDTH*8-1:0]  wr_ctrl_data,
        .wr_data_re_1       (  ddr_wdata_req_1    ),//output                       wr_data_re  ,
                                              
        .rd_cmd_en_1        (  rd_cmd_en_1        ),//input                        rd_cmd_en   ,
        .rd_cmd_addr_1      (  rd_cmd_addr_1      ),//input  [CTRL_ADDR_WIDTH-1:0] rd_cmd_addr ,
        .rd_cmd_len_1       (  rd_cmd_len_1       ),//input  [31??0]               rd_cmd_len  ,
        .rd_cmd_ready_1     (  rd_cmd_ready_1     ),//output                       rd_cmd_ready, 
        .rd_cmd_done_1      (  rd_cmd_done_1      ),//output                       rd_cmd_done,
                                              
        .read_ready_1       (  read_ready_1       ),//input                        read_ready  ,    
        .read_rdata_1       (  read_rdata_1       ),//output [MEM_DQ_WIDTH*8-1:0]  read_rdata  ,     
        .read_en_1          (read_en_1),                                      
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

//pcie_wr_buf #(
//        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
//        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
//        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
//        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
//        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
//        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
//        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
//        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
//        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
//)
//pcie_wr_buf(
//        .ddr_clk          (  ddr_clk          ),//input                         ddr_clk,
//        .ddr_rstn         (  ddr_rstn         ),//input                         ddr_rstn,
//                                              
//        .wr_clk           (  pcie_clk          ),//input                        wr_clk,
//        .wr_fsync         (pcie_vs),
//        .pcie_init_done    (pcie_init_done),
//        .wr_en            (  cpu_data_en            ),//input                         wr_en,
//        .wr_data          (  cpu_data          ),//input  [PIX_WIDTH- 1'b1 : 0]  wr_data,
//        
//        .rd_bac           (  ddr_wr_bac_1       ),//input                         rd_bac,                                      
//        .ddr_wreq         (  ddr_wreq_1         ),//output                        ddr_wreq,
//        .ddr_waddr        (  ddr_waddr_1        ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
//        .ddr_wr_len       (  ddr_wr_len_1       ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
//        .ddr_wrdy         (  ddr_wrdy_1         ),//input                         ddr_wrdy,
//        .ddr_wdone        (  ddr_wdone_1        ),//input                         ddr_wdone,
//        .ddr_wdata        (  ddr_wdata_1        ),//output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
//        .ddr_wdata_req    (  ddr_wdata_req_1    ),//input                         ddr_wdata_req,
//                                              
//        .hdmi_ddr_cur_fram(hdmi_ddr_cur_fram_pcie),
//        .frame_wcnt       (                   ),//output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
//        .frame_wirq       (  cpu_frame_wirq       ) //output                        frame_wirq
//);
//wire cpu_frame_wirq;
//    always @(posedge ddr_clk)
//    if(~ddr_rstn)begin
//        cpu_init_done <= 1'b0;
//    end
//    else begin
//        if(cpu_frame_wirq)
//            cpu_init_done <= 1'b1;
//        else
//            cpu_init_done <= cpu_init_done;
//    end 
//wire pcie_able;
//rd_buf#(
//        .ADDR_WIDTH       (  CTRL_ADDR_WIDTH  ),//parameter                     ADDR_WIDTH      = 6'd27,
//        .ADDR_OFFSET      (  32'h0000_0000    ),//parameter                     ADDR_OFFSET     = 32'h0000_0000,
//        .H_NUM            (  H_NUM            ),//parameter                     H_NUM           = 12'd1920,
//        .V_NUM            (  V_NUM            ),//parameter                     V_NUM           = 12'd1080,
//        .DQ_WIDTH         (  MEM_DQ_WIDTH     ),//parameter                     DQ_WIDTH        = 7'd32,
//        .LEN_WIDTH        (  LEN_WIDTH        ),//parameter                     LEN_WIDTH       = 6'd16,
//        .PIX_WIDTH        (  PIX_WIDTH        ),//parameter                     PIX_WIDTH       = 6'd24,
//        .LINE_ADDR_WIDTH  (  LINE_ADDR_WIDTH  ),//parameter                     LINE_ADDR_WIDTH = 4'd19,
//        .FRAME_CNT_WIDTH  (  FRAME_CNT_WIDTH  ) //parameter                     FRAME_CNT_WIDTH = 4'd8
//) 
//rd_buf(
//        .ddr_clk         (  ddr_clk           ),//input                         ddr_clk,
//        .ddr_rstn        (  ddr_rstn          ),//input                         ddr_rstn,
//
//        .vout_clk        (  vout_clk          ),//input                         vout_clk,
//        .rd_fsync        (  rd_fsync          ),//input                         rd_fsync,
//        .rd_en           (  rd_en             ),//input                         rd_en,
//        .vout_de         (  vout_de           ),//output                        vout_de,
//        .vout_data       (  vout_data         ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,
//
////        .current_fram_addr(current_fram_addr_pcie),
//      
//        .ddr_rreq        (  rd_cmd_en_1         ),//output                        ddr_rreq,
//        .ddr_raddr       (  rd_cmd_addr_1       ),//output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
//        .ddr_rd_len      (  rd_cmd_len_1        ),//output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
//        .ddr_rrdy        (  rd_cmd_ready_1      ),//input                         ddr_rrdy,
//        .ddr_rdone       (  rd_cmd_done_1       ),//input                         ddr_rdone,
//        .ddr_rdata       (  read_rdata_1        ),//input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
//        .ddr_rdata_en    (  read_en_1           ), //input                         ddr_rdata_en,
//        .pcie_able       (pcie_able)
//);

endmodule
