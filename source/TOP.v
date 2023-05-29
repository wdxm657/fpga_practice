`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-03-17  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
//cmos1、cmos2二选一，作为视频源输入
//`define CMOS_1      //cmos1作为视频输入；
`define CMOS_2      //cmos2作为视频输入；

module TOP#(
	parameter MEM_ROW_ADDR_WIDTH   = 15         ,
	parameter MEM_COL_ADDR_WIDTH   = 10         ,
	parameter MEM_BADDR_WIDTH      = 3          ,
	parameter MEM_DQ_WIDTH         =  32        ,
	parameter MEM_DQS_WIDTH        =  32/8
)(
	input                                sys_clk              ,//50Mhz
/**/
//OV5647
    output  [1:0]                        cmos_init_done       ,//OV5640寄存器初始化完成
    //coms1	
    inout                                cmos1_scl            ,//cmos1 i2c 
    inout                                cmos1_sda            ,//cmos1 i2c 
    input                                cmos1_vsync          ,//cmos1 vsync
    input                                cmos1_href           ,//cmos1 hsync refrence,data valid
    input                                cmos1_pclk           ,//cmos1 pxiel clock
    input   [7:0]                        cmos1_data           ,//cmos1 data
    output                               cmos1_reset          ,//cmos1 reset
    //coms2
    inout                                cmos2_scl            ,//cmos2 i2c 
    inout                                cmos2_sda            ,//cmos2 i2c 
    input                                cmos2_vsync          ,//cmos2 vsync
    input                                cmos2_href           ,//cmos2 hsync refrence,data valid
    input                                cmos2_pclk           ,//cmos2 pxiel clock
    input   [7:0]                        cmos2_data           ,//cmos2 data
    output                               cmos2_reset          ,//cmos2 reset
/**/
//DDR
    output                               mem_rst_n                 ,
    output                               mem_ck                    ,
    output                               mem_ck_n                  ,
    output                               mem_cke                   ,
    output                               mem_cs_n                  ,
    output                               mem_ras_n                 ,
    output                               mem_cas_n                 ,
    output                               mem_we_n                  ,
    output                               mem_odt                   ,
    output      [MEM_ROW_ADDR_WIDTH-1:0] mem_a                     ,
    output      [MEM_BADDR_WIDTH-1:0]    mem_ba                    ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs                   ,
    inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs_n                 ,
    inout       [MEM_DQ_WIDTH-1:0]       mem_dq                    ,
    output      [MEM_DQ_WIDTH/8-1:0]     mem_dm                    ,
    output reg                           heart_beat_led            ,
    output                               ddr_init_done             ,
//MS72xx       
    output                               rstn_out                  ,
    output                               iic_scl,
    inout                                iic_sda, 
    output                               iic_tx_scl                ,
    inout                                iic_tx_sda                ,
   // output                               hdmi_int_led            ,
//HDMI_IN
    input                                pixclk_in                ,                            
    input                                vs_in                    , 
    input                                hs_in                    , 
    input                                de_in                    ,
    input     [7:0]                      r_in                     , 
    input     [7:0]                      g_in                     , 
    input     [7:0]                      b_in                     ,  
//HDMI_OUT
    output                              pix_clk_1080p            /*synthesis PAP_MARK_DEBUG="1"*/,              
    output   reg                          vs_out                  , 
    output   reg                          hs_out                   , 
    output   reg                          de_out                   , 
    output   reg   [7:0]                  r_out                    , 
    output   reg   [7:0]                  g_out                    , 
    output   reg   [7:0]                  b_out                    ,
//PCIE
    input                       button_rst_n    ,
    input                       perst_n         ,
    input                       pcie_ref_clk_n  ,
    input                       pcie_ref_clk_p  ,
    input           [1:0]       rxn             ,
    input           [1:0]       rxp             ,
    output  wire    [1:0]       txn             ,
    output  wire    [1:0]       txp             
);
/////////////////////////////////////////////////////////////////////////////////////
// ENABLE_DDR
    parameter CTRL_ADDR_WIDTH = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH;//28
    parameter TH_1S = 27'd33000000;
// PCIE
localparam  DEVICE_TYPE   = 3'b000;//@IPC enum 3'b000,3'b001,3'b100
localparam AXIS_SLAVE_NUM = 3      ;  //@IPC enum 1 2 3

// pcie wire sigs
wire pcie_ref_clk;
wire pcie_pclk;
wire pcie_pclk_div2;
wire sync_perst_n;
wire            pcie_cfg_ctrl_en        ;
wire            axis_master_tready_cfg  ;

wire            cfg_axis_slave0_tvalid  ;
wire    [127:0] cfg_axis_slave0_tdata   ;
wire            cfg_axis_slave0_tlast   ;
wire            cfg_axis_slave0_tuser   ;

//for mux
wire            axis_master_tready_mem  ;
wire            axis_master_tvalid_mem  ;
wire    [127:0] axis_master_tdata_mem   ;
wire    [3:0]   axis_master_tkeep_mem   ;
wire            axis_master_tlast_mem   ;
wire    [7:0]   axis_master_tuser_mem   ;

wire            cross_4kb_boundary      ;

wire            dma_axis_slave0_tvalid  ;
wire    [127:0] dma_axis_slave0_tdata   ;
wire            dma_axis_slave0_tlast   ;
wire            dma_axis_slave0_tuser   ;

//RESET DEBOUNCE and SYNC
wire            sync_button_rst_n       ;
wire            s_pclk_rstn             ;
wire            s_pclk_div2_rstn        ;

//********************** internal signal
//AXIS master interface
wire            axis_master_tvalid      ;
wire            axis_master_tready      ;
wire    [127:0] axis_master_tdata       ;
wire    [3:0]   axis_master_tkeep       ;
wire            axis_master_tlast       ;
wire    [7:0]   axis_master_tuser       ;

//axis slave 0 interface
wire            axis_slave0_tready      ;
wire            axis_slave0_tvalid      ;
wire    [127:0] axis_slave0_tdata       ;
wire            axis_slave0_tlast       ;
wire            axis_slave0_tuser       ;

//axis slave 1 interface
wire            axis_slave1_tready      ;
wire            axis_slave1_tvalid      ;
wire    [127:0] axis_slave1_tdata       ;
wire            axis_slave1_tlast       ;
wire            axis_slave1_tuser       ;

//axis slave 2 interface
wire            axis_slave2_tready      ;
wire            axis_slave2_tvalid      ;
wire    [127:0] axis_slave2_tdata       ;
wire            axis_slave2_tlast       ;
wire            axis_slave2_tuser       ;

wire    [7:0]   cfg_pbus_num            ;
wire    [4:0]   cfg_pbus_dev_num        ;
wire    [2:0]   cfg_max_rd_req_size     ;
wire    [2:0]   cfg_max_payload_size    ;
wire            cfg_rcb                 ;

wire            cfg_ido_req_en          ;
wire            cfg_ido_cpl_en          ;
wire    [7:0]   xadm_ph_cdts            ;
wire    [11:0]  xadm_pd_cdts            ;
wire    [7:0]   xadm_nph_cdts           ;
wire    [11:0]  xadm_npd_cdts           ;
wire    [7:0]   xadm_cplh_cdts          ;
wire    [11:0]  xadm_cpld_cdts          ;

assign cfg_ido_req_en   =   1'b0;
assign cfg_ido_cpl_en   =   1'b0;
assign xadm_ph_cdts     =   8'b0;
assign xadm_pd_cdts     =   12'b0;
assign xadm_nph_cdts    =   8'b0;
assign xadm_npd_cdts    =   12'b0;
assign xadm_cplh_cdts   =   8'b0;
assign xadm_cpld_cdts   =   12'b0;

/////////////////////////////////////////////////////////////////////////////////////
    reg  [15:0]                 rstn_1ms            ;

    wire                        cmos_scl            ;//cmos i2c clock
    wire                        cmos_sda            ;//cmos i2c data
    wire                        cmos_vsync          ;//cmos vsync
    wire                        cmos_href           ;//cmos hsync refrence,data valid
    wire                        cmos_pclk           ;//cmos pxiel clock
    wire   [7:0]                cmos_data           ;//cmos data
    wire                        cmos_reset          ;//cmos reset
    wire                        initial_en          ;
    wire[15:0]                  cmos1_d_16bit       ;
    wire                        cmos1_href_16bit    ;
    reg [7:0]                   cmos1_d_d0          ;
    reg                         cmos1_href_d0       ;
    reg                         cmos1_vsync_d0      ;
    wire                        cmos1_pclk_16bit    ;
    wire[15:0]                  cmos2_d_16bit       ;
    wire                        cmos2_href_16bit    ;
    reg [7:0]                   cmos2_d_d0          ;
    reg                         cmos2_href_d0       ;
    reg                         cmos2_vsync_d0      ;
    wire                        cmos2_pclk_16bit    ;
    wire[15:0]                  o_rgb565            ;
    wire                        pclk_in_test        ;    
    wire                        vs_in_test          ;
    wire                        de_in_test          ;
    wire[15:0]                  i_rgb565            ;
    wire                        de_re               ;
    wire                        hs_o               ;
//axi bus   
    wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr                 ;
    wire                        axi_awuser_ap              ;
    wire [3:0]                  axi_awuser_id              ;
    wire [3:0]                  axi_awlen                  ;
    wire                        axi_awready                ;
    wire                        axi_awvalid                ;
    wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
    wire [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb                  ;
    wire                        axi_wready                 ;
    wire [3:0]                  axi_wusero_id              ;
    wire                        axi_wusero_last            ;
    wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr                 ;
    wire                        axi_aruser_ap              ;
    wire [3:0]                  axi_aruser_id              ;
    wire [3:0]                  axi_arlen                  ;
    wire                        axi_arready                ;/*synthesis PAP_MARK_DEBUG="1"*/
    wire                        axi_arvalid                ;
    wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata                   /* synthesis syn_keep = 1 */;
    wire                        axi_rvalid                 ;
    wire [3:0]                  axi_rid                    ;
    wire                        axi_rlast                  ;
    reg  [26:0]                 cnt                        ;
    reg  [15:0]                 cnt_1                      ;
/////////////////////////////////////////////////////////////////////////////////////
wire pix_clk;
//PLL
    ip_pll u_pll (
        .clkin1   (  sys_clk    ),//50MHz
        .clkout0  (  pix_clk    ),//37.125M 720P30 | 148.5M 1080P60
        .clkout1  (  cfg_clk    ),//10MHz
        .clkout2  (  clk_25M    ),//25M
        .pll_lock (  locked     )
    );
wire init_over_tx;/*synthesis PAP_MARK_DEBUG="1"*/
//配置7210
    ms72xx_ctl ms72xx_ctl(
        .clk             (  cfg_clk        ), //input       clk,
        .rst_n           (  rstn_out       ), //input       rstn,
        .init_over_tx    (  init_over_tx   ), //output      init_over,                                
        .init_over_rx    (  init_over_rx   ), //output      init_over,
        .iic_tx_scl      (  iic_tx_scl     ), //output      iic_scl,
        .iic_tx_sda      (  iic_tx_sda     ), //inout       iic_sda
        .iic_scl         (  iic_scl        ), //output      iic_scl,
        .iic_sda         (  iic_sda        )  //inout       iic_sda
    );
  // assign    hdmi_int_led    =    init_over_tx; 
    
    always @(posedge cfg_clk)
    begin
    	if(!locked)
    	    rstn_1ms <= 16'd0;
    	else
    	begin
    		if(rstn_1ms == 16'h2710)
    		    rstn_1ms <= rstn_1ms;
    		else
    		    rstn_1ms <= rstn_1ms + 1'b1;
    	end
    end
    
    assign rstn_out = (rstn_1ms == 16'h2710);

//配置CMOS///////////////////////////////////////////////////////////////////////////////////
/**/
//OV5640 register configure enable    
    power_on_delay	power_on_delay_inst(
    	.clk_50M                 (sys_clk        ),//input
    	.reset_n                 (1'b1           ),//input	
    	.camera1_rstn            (cmos1_reset    ),//output
    	.camera2_rstn            (cmos2_reset    ),//output	
    	.camera_pwnd             (               ),//output
    	.initial_en              (initial_en     ) //output		
    );
//CMOS1 Camera  
    reg_config	coms1_reg_config(
    	.clk_25M                 (clk_25M            ),//input
    	.camera_rstn             (cmos1_reset        ),//input
    	.initial_en              (initial_en         ),//input		
    	.i2c_sclk                (cmos1_scl          ),//output
    	.i2c_sdat                (cmos1_sda          ),//inout
    	.reg_conf_done           (cmos_init_done[0]  ),//output config_finished
    	.reg_index               (                   ),//output reg [8:0]
    	.clock_20k               (                   ) //output reg
    );

//CMOS2 Camera 
    reg_config	coms2_reg_config(
    	.clk_25M                 (clk_25M            ),//input
    	.camera_rstn             (cmos2_reset        ),//input
    	.initial_en              (initial_en         ),//input		
    	.i2c_sclk                (cmos2_scl          ),//output
    	.i2c_sdat                (cmos2_sda          ),//inout
    	.reg_conf_done           (cmos_init_done[1]  ),//output config_finished
    	.reg_index               (                   ),//output reg [8:0]
    	.clock_20k               (                   ) //output reg
    );
//CMOS 8bit转16bit///////////////////////////////////////////////////////////////////////////////////
//CMOS1
    always@(posedge cmos1_pclk)
        begin
            cmos1_d_d0        <= cmos1_data    ;
            cmos1_href_d0     <= cmos1_href    ;
            cmos1_vsync_d0    <= cmos1_vsync   ;
        end

    cmos_8_16bit cmos1_8_16bit(
    	.pclk           (cmos1_pclk       ),//input
    	.rst_n          (cmos_init_done[0]),//input
    	.pdata_i        (cmos1_d_d0       ),//input[7:0]
    	.de_i           (cmos1_href_d0    ),//input
    	.vs_i           (cmos1_vsync_d0    ),//input
    	
    	.pixel_clk      (cmos1_pclk_16bit ),//output
    	.pdata_o        (cmos1_d_16bit    ),//output[15:0]
    	.de_o           (cmos1_href_16bit ) //output
    );
//CMOS2
    always@(posedge cmos2_pclk)
        begin
            cmos2_d_d0        <= cmos2_data    ;
            cmos2_href_d0     <= cmos2_href    ;
            cmos2_vsync_d0    <= cmos2_vsync   ;
        end

    cmos_8_16bit cmos2_8_16bit(
    	.pclk           (cmos2_pclk       ),//input
    	.rst_n          (cmos_init_done[1]),//input
    	.pdata_i        (cmos2_d_d0       ),//input[7:0]
    	.de_i           (cmos2_href_d0    ),//input
    	.vs_i           (cmos2_vsync_d0    ),//input
    	
    	.pixel_clk      (cmos2_pclk_16bit ),//output
    	.pdata_o        (cmos2_d_16bit    ),//output[15:0]
    	.de_o           (cmos2_href_16bit ) //output
    );
//输入视频源选择//////////////////////////////////////////////////////////////////////////////////////////
`ifdef CMOS_1
assign     pclk_in_test    =    cmos1_pclk_16bit    ;
assign     vs_in_test      =    cmos1_vsync_d0      ;
assign     de_in_test      =    cmos1_href_16bit    ;
assign     i_rgb565        =    {cmos1_d_16bit[4:0],cmos1_d_16bit[10:5],cmos1_d_16bit[15:11]};//{r,g,b}
`elsif CMOS_2
assign     pclk_in_test    =    cmos2_pclk_16bit    ;
assign     vs_in_test      =    cmos2_vsync_d0      ;
assign     de_in_test      =    cmos2_href_16bit    ;
assign     i_rgb565        =    {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]};//{r,g,b}
`endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
/**/

wire [15:0] hdmi_rgb565;
assign hdmi_rgb565 = {r_in[7:3],g_in[7:2],b_in[7:3]};

wire i_pcie_mwr_en;
wire [127:0] o_ddr_data;
wire cpld_data_valid;
wire [127:0] axis_rx_data;
wire init_done;
/* ddr buffer sig*/
//修改ddr读写模块v1   此模块用于HDMI 2 DDR 2 PCIE MWR
    fram_buf#(
    .H_NUM (1920),
    .V_NUM (1080)
    ) fram_buf(
        .ddr_clk        (  core_clk             ),//input                         ddr_clk,
        .ddr_rstn       (  ddr_init_done        ),//input                         ddr_rstn,
        //data_in  
/*        cmos_ov5640       720p                
        .vin_clk        (  pclk_in_test         ),//input                         vin_clk,
        .wr_fsync       (  vs_in_test           ),//input                         wr_fsync,
        .wr_en          (  de_in_test           ),//input                         wr_en,
        .wr_data        (  i_rgb565             ),//input  [15 : 0]  wr_data,
/**/
/*        hdmi_in              1080p */           
        .vin_clk        (  pixclk_in            ),//input                         vin_clk,
        .wr_fsync       (  vs_in                ),//input                         wr_fsync,
        .wr_en          (  de_in                ),//input                         wr_en,
        .wr_data        (  hdmi_rgb565          ),//input  [15 : 0]  wr_data,

/**/
        //data_out
        //pcie

        .pcie_clk       (pcie_pclk_div2),
        .pcie_init_done (pcie_init_done),
        .i_pcie_mwr_en  (i_pcie_mwr_en),
        .o_ddr_data     (o_ddr_data),
        
        .cpu_data       (axis_rx_data),
        .cpu_data_en    (cpld_data_valid),

        // init done的话就是hdmi  ddr  hdmi
        // cpu init done 就是 hdmi  pcie  pcie  hdmi
        .init_done      (  init_done            ),//output reg                    init_done,
        //.cpu_init_done      (  init_done            ),//output reg                    init_done,

        .vout_clk       (  pixclk_in              ),//input                         vout_clk,
        .rd_fsync       (  vs_o               ),//input                         rd_fsync,
        .rd_en          (  de_re                ),//input                         rd_en, 
        .vout_de        (  de_o               ),//output                        vout_de,
        .vout_data      (  o_rgb565             ),//output [PIX_WIDTH- 1'b1 : 0]  vout_data,


        //axi bus
        .axi_awaddr     (  axi_awaddr           ),// output[27:0]
        .axi_awid       (  axi_awuser_id        ),// output[3:0]
        .axi_awlen      (  axi_awlen            ),// output[3:0]
        .axi_awsize     (                       ),// output[2:0]
        .axi_awburst    (                       ),// output[1:0]
        .axi_awready    (  axi_awready          ),// input
        .axi_awvalid    (  axi_awvalid          ),// output               
        .axi_wdata      (  axi_wdata            ),// output[255:0]
        .axi_wstrb      (  axi_wstrb            ),// output[31:0] //(32)1
        .axi_wlast      (  axi_wusero_last      ),// input
        .axi_wvalid     (                       ),// output
        .axi_wready     (  axi_wready           ),// input
        .axi_bid        (  4'd0                 ),// input[3:0]
        .axi_araddr     (  axi_araddr           ),// output[27:0]
        .axi_arid       (  axi_aruser_id        ),// output[3:0]
        .axi_arlen      (  axi_arlen            ),// output[3:0]
        .axi_arsize     (                       ),// output[2:0]
        .axi_arburst    (                       ),// output[1:0]
        .axi_arvalid    (  axi_arvalid          ),// output
        .axi_arready    (  axi_arready          ),// input
        .axi_rready     (                       ),// output
        .axi_rdata      (  axi_rdata            ),// input[255:0]
        .axi_rvalid     (  axi_rvalid           ),// input
        .axi_rlast      (  axi_rlast            ),// input
        .axi_rid        (  axi_rid              ) // input[3:0]         
    );

// pcie dma -----------------------------------------------------------
ipsl_pcie_dma #(
    .DEVICE_TYPE            (DEVICE_TYPE            ),
    .AXIS_SLAVE_NUM         (AXIS_SLAVE_NUM         )
)
u_ipsl_pcie_dma
(
    .clk                    (pcie_pclk_div2              ),  //gen1:62.5MHz,gen2:125MHz
    .rst_n                  (core_rst_n             ),

    // ddr
    .o_pcie_mwr_en          (i_pcie_mwr_en)           ,
    .i_ddr_data             (o_ddr_data)              ,
    
    .o_cpld_data_valid       (cpld_data_valid),
    .axis_rx_data            (axis_rx_data),

    //num
    .i_cfg_pbus_num         (cfg_pbus_num           ),  //input [7:0]
    .i_cfg_pbus_dev_num     (cfg_pbus_dev_num       ),  //input [4:0]
    .i_cfg_max_rd_req_size  (cfg_max_rd_req_size    ),  //input [2:0]
    .i_cfg_max_payload_size (cfg_max_payload_size   ),  //input [2:0]
    //**********************************************************************
    //axis master interface
    .i_axis_master_tvld     (axis_master_tvalid_mem ),
    .o_axis_master_trdy     (axis_master_tready_mem ),
    .i_axis_master_tdata    (axis_master_tdata_mem  ),
    .i_axis_master_tkeep    (axis_master_tkeep_mem  ),
    .i_axis_master_tlast    (axis_master_tlast_mem  ),
    .i_axis_master_tuser    (axis_master_tuser_mem  ),

    //**********************************************************************
    //axis_slave0 interface
    .i_axis_slave0_trdy     (axis_slave0_tready     ),
    .o_axis_slave0_tvld     (dma_axis_slave0_tvalid ),
    .o_axis_slave0_tdata    (dma_axis_slave0_tdata  ),
    .o_axis_slave0_tlast    (dma_axis_slave0_tlast  ),
    .o_axis_slave0_tuser    (dma_axis_slave0_tuser  ),
    //axis_slave1 interface
    .i_axis_slave1_trdy     (axis_slave1_tready     ),
    .o_axis_slave1_tvld     (axis_slave1_tvalid     ),
    .o_axis_slave1_tdata    (axis_slave1_tdata      ),
    .o_axis_slave1_tlast    (axis_slave1_tlast      ),
    .o_axis_slave1_tuser    (axis_slave1_tuser      ),
    //axis_slave2 interface
    .i_axis_slave2_trdy     (axis_slave2_tready     ),
    .o_axis_slave2_tvld     (axis_slave2_tvalid     ),
    .o_axis_slave2_tdata    (axis_slave2_tdata      ),
    .o_axis_slave2_tlast    (axis_slave2_tlast      ),
    .o_axis_slave2_tuser    (axis_slave2_tuser      ),
    //from pcie
    .i_cfg_ido_req_en       (cfg_ido_req_en         ),
    .i_cfg_ido_cpl_en       (cfg_ido_cpl_en         ),
    .i_xadm_ph_cdts         (xadm_ph_cdts           ),
    .i_xadm_pd_cdts         (xadm_pd_cdts           ),
    .i_xadm_nph_cdts        (xadm_nph_cdts          ),
    .i_xadm_npd_cdts        (xadm_npd_cdts          ),
    .i_xadm_cplh_cdts       (xadm_cplh_cdts         ),
    .i_xadm_cpld_cdts       (xadm_cpld_cdts         )
);

//ddr heart beat sig
     always@(posedge core_clk) begin
        if (!ddr_init_done)
            cnt <= 27'd0;
        else if ( cnt >= TH_1S )
            cnt <= 27'd0;
        else
            cnt <= cnt + 27'd1;
     end

     always @(posedge core_clk)
        begin
        if (!ddr_init_done)
            heart_beat_led <= 1'd1;
        else if ( cnt >= TH_1S )
            heart_beat_led <= ~heart_beat_led;
    end

/////////////////////////////////////////////////////////////////////////////////////
//产生visa时序 
     sync_vg #(
//MODE_1080p
    .V_TOTAL   (12'd1125),
    .V_FP      (12'd4   ),
    .V_BP      (12'd36  ),
    .V_SYNC    (12'd5   ),
    .V_ACT     (12'd1080),
    .H_TOTAL   (12'd2200),
    .H_FP      (12'd88  ),
    .H_BP      (12'd148 ),
    .H_SYNC    (12'd44  ),
    .H_ACT     (12'd1920),
    .HV_OFFSET (12'd0   ) 
    )    
     sync_vg(                            
        .clk            (  pixclk_in              ),//input                   clk,                                 
        .rstn           (  init_done            ),//input                   rstn,                            
        .vs_out         (  vs_o                 ),//output reg              vs_out,                                                                                                                                      
        .hs_out         (  hs_o                 ),//output reg              hs_out,            
        .de_out         (                       ),//output reg              de_out, 
        .de_re          (  de_re                )    
    );  
/*
     reg vs_o_d1, vs_o_d2;
     reg hs_o_d1, hs_o_d2;
    always@(posedge pixclk_in) begin
        vs_o_d1<=vs_o;
        vs_o_d2<=vs_o_d1;
        hs_o_d1<=hs_o;
        hs_o_d2<=hs_o_d1;
     end
    assign pix_clk_1080p   =  pixclk_in    ;
    assign r_out = {o_rgb565[15:11],o_rgb565[15:13]   };
    assign g_out = {o_rgb565[10:5],o_rgb565[10:9]    };
    assign b_out = {o_rgb565[4:0],o_rgb565[4:2]    };
    assign vs_out = vs_o_d2;
    assign hs_out = hs_o_d2;
    assign de_out = de_o; 
/**/
/* hdmi out = hdmi in */

assign pix_clk_1080p   =  pixclk_in    ;

    always  @(posedge pix_clk_1080p)begin
        if(!init_over_tx)begin
            vs_out       <=  1'b0        ;
            hs_out       <=  1'b0        ;
            de_out       <=  1'b0        ;
            r_out        <=  8'b0        ;
            g_out        <=  8'b0        ;
            b_out        <=  8'b0        ;
        end
    	    else begin
            vs_out       <=  vs_in        ;
            hs_out       <=  hs_in        ;
            de_out       <=  de_in        ;
            r_out        <=  r_in         ;
            g_out        <=  g_in         ;
            b_out        <=  b_in         ;
        end
    end
/**/
/**/

//----------------------------------------------------------rst debounce ----------------------------------------------------------
//ASYNC RST  define IPSL_PCIE_SPEEDUP_SIM when simulation
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPSL_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_buttonrstn_debounce(
    .clk                (pcie_ref_clk            ),
    .rstn_in            (button_rst_n       ),
    .rstn_out           (sync_button_rst_n  )
);

hsst_rst_cross_sync_v1_0 #(
    `ifdef IPSL_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_perstn_debounce(
    .clk                (pcie_ref_clk            ),
    .rstn_in            (perst_n            ),
    .rstn_out           (sync_perst_n       )
);

ipsl_pcie_sync_v1_0  u_ref_core_rstn_sync    (
    .clk                (pcie_ref_clk            ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (ref_core_rst_n     )
);

ipsl_pcie_sync_v1_0  u_pclk_core_rstn_sync   (
    .clk                (pcie_pclk               ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (s_pclk_rstn        )
);

ipsl_pcie_sync_v1_0  u_pclk_div2_core_rstn_sync   (
    .clk                (pcie_pclk_div2          ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (s_pclk_div2_rstn   )
);

assign axis_slave0_tvalid      = dma_axis_slave0_tvalid;
assign axis_slave0_tlast       = dma_axis_slave0_tlast;
assign axis_slave0_tuser       = dma_axis_slave0_tuser;
assign axis_slave0_tdata       = dma_axis_slave0_tdata;

assign axis_master_tvalid_mem  = axis_master_tvalid;
assign axis_master_tdata_mem   = axis_master_tdata;
assign axis_master_tkeep_mem   = axis_master_tkeep;
assign axis_master_tlast_mem   = axis_master_tlast;
assign axis_master_tuser_mem   = axis_master_tuser;

assign axis_master_tready      = axis_master_tready_mem;
wire pcie_init_done;
wire smlh_link_up;
wire rdlh_link_up;
assign pcie_init_done = smlh_link_up & rdlh_link_up;
//ddr    
        ip_ddr3 u_DDR3_50H (
             .ref_clk                   (sys_clk            ),
             .resetn                    (rstn_out           ),// input
             .ddr_init_done             (ddr_init_done      ),// output
             .ddrphy_clkin              (core_clk           ),// output
             .pll_lock                  (pll_lock           ),// output

             .axi_awaddr                (axi_awaddr         ),// input [27:0]
             .axi_awuser_ap             (1'b0               ),// input
             .axi_awuser_id             (axi_awuser_id      ),// input [3:0]
             .axi_awlen                 (axi_awlen          ),// input [3:0]
             .axi_awready               (axi_awready        ),// output
             .axi_awvalid               (axi_awvalid        ),// input
             .axi_wdata                 (axi_wdata          ),
             .axi_wstrb                 (axi_wstrb          ),// input [31:0]
             .axi_wready                (axi_wready         ),// output
             .axi_wusero_id             (                   ),// output [3:0]
             .axi_wusero_last           (axi_wusero_last    ),// output
             .axi_araddr                (axi_araddr         ),// input [27:0]
             .axi_aruser_ap             (1'b0               ),// input
             .axi_aruser_id             (axi_aruser_id      ),// input [3:0]
             .axi_arlen                 (axi_arlen          ),// input [3:0]
             .axi_arready               (axi_arready        ),// output
             .axi_arvalid               (axi_arvalid        ),// input
             .axi_rdata                 (axi_rdata          ),// output [255:0]
             .axi_rid                   (axi_rid            ),// output [3:0]
             .axi_rlast                 (axi_rlast          ),// output
             .axi_rvalid                (axi_rvalid         ),// output

             .apb_clk                   (1'b0               ),// input
             .apb_rst_n                 (1'b1               ),// input
             .apb_sel                   (1'b0               ),// input
             .apb_enable                (1'b0               ),// input
             .apb_addr                  (8'b0               ),// input [7:0]
             .apb_write                 (1'b0               ),// input
             .apb_ready                 (                   ), // output
             .apb_wdata                 (16'b0              ),// input [15:0]
             .apb_rdata                 (                   ),// output [15:0]
             .apb_int                   (                   ),// output

             .mem_rst_n                 (mem_rst_n          ),// output
             .mem_ck                    (mem_ck             ),// output
             .mem_ck_n                  (mem_ck_n           ),// output
             .mem_cke                   (mem_cke            ),// output
             .mem_cs_n                  (mem_cs_n           ),// output
             .mem_ras_n                 (mem_ras_n          ),// output
             .mem_cas_n                 (mem_cas_n          ),// output
             .mem_we_n                  (mem_we_n           ),// output
             .mem_odt                   (mem_odt            ),// output
             .mem_a                     (mem_a              ),// output [14:0]
             .mem_ba                    (mem_ba             ),// output [2:0]
             .mem_dqs                   (mem_dqs            ),// inout [3:0]
             .mem_dqs_n                 (mem_dqs_n          ),// inout [3:0]
             .mem_dq                    (mem_dq             ),// inout [31:0]
             .mem_dm                    (mem_dm             ),// output [3:0]
             //debug
             .debug_data                (                   ),// output [135:0]
             .debug_slice_state         (                   ),// output [51:0]
             .debug_calib_ctrl          (                   ),// output [21:0]
             .ck_dly_set_bin            (                   ),// output [7:0]
             .force_ck_dly_en           (1'b0               ),// input
             .force_ck_dly_set_bin      (8'h05              ),// input [7:0]
             .dll_step                  (                   ),// output [7:0]
             .dll_lock                  (                   ),// output
             .init_read_clk_ctrl        (2'b0               ),// input [1:0]
             .init_slip_step            (4'b0               ),// input [3:0]
             .force_read_clk_ctrl       (1'b0               ),// input
             .ddrphy_gate_update_en     (1'b0               ),// input
             .update_com_val_err_flag   (                   ),// output [3:0]
             .rd_fake_stop              (1'b0               ) // input
       );

// pcie warp -----------------------------------------------------------
ip_pcie my_pcie (
  .free_clk                     (sys_clk)          ,// input
  .pclk                         (pcie_pclk)              ,// output
  .pclk_div2                    (pcie_pclk_div2)         ,// output
  .ref_clk                      (pcie_ref_clk)           ,// output
  .ref_clk_n                    (pcie_ref_clk_n)         ,// input
  .ref_clk_p                    (pcie_ref_clk_p)         ,// input

  .button_rst_n                 (sync_button_rst_n)           ,// input
  .power_up_rst_n               (sync_perst_n)         ,// input
  .perst_n                      (sync_perst_n)                ,// input

  .core_rst_n                   (core_rst_n)             ,// output

  //PHY diff signals
    .rxn                        (rxn                    ),      //input   max[3:0]
    .rxp                        (rxp                    ),      //input   max[3:0]
    .txn                        (txn                    ),      //output  max[3:0]
    .txp                        (txp                    ),      //output  max[3:0]
    
    .pcs_nearend_loop           ({2{1'b0}}              ),      //input
    .pma_nearend_ploop          ({2{1'b0}}              ),      //input
    .pma_nearend_sloop          ({2{1'b0}}              ),      //input
    
    //AXIS master interface
    .axis_master_tvalid         (axis_master_tvalid     ),      //output
    .axis_master_tready         (axis_master_tready     ),      //input
    .axis_master_tdata          (axis_master_tdata      ),      //output [127:0]
    .axis_master_tkeep          (axis_master_tkeep      ),      //output [3:0]
    .axis_master_tlast          (axis_master_tlast      ),      //output
    .axis_master_tuser          (axis_master_tuser      ),      //output [7:0]
    
    //axis slave 0 interface
    .axis_slave0_tready         (axis_slave0_tready     ),      //output
    .axis_slave0_tvalid         (axis_slave0_tvalid     ),      //input
    .axis_slave0_tdata          (axis_slave0_tdata      ),      //input  [127:0]
    .axis_slave0_tlast          (axis_slave0_tlast      ),      //input
    .axis_slave0_tuser          (axis_slave0_tuser      ),      //input
    
    //axis slave 1 interface
    .axis_slave1_tready         (axis_slave1_tready     ),      //output
    .axis_slave1_tvalid         (axis_slave1_tvalid     ),      //input
    .axis_slave1_tdata          (axis_slave1_tdata      ),      //input  [127:0]
    .axis_slave1_tlast          (axis_slave1_tlast      ),      //input
    .axis_slave1_tuser          (axis_slave1_tuser      ),      //input
    //axis slave 2 interface
    .axis_slave2_tready         (axis_slave2_tready     ),      //output
    .axis_slave2_tvalid         (axis_slave2_tvalid     ),      //input
    .axis_slave2_tdata          (axis_slave2_tdata      ),      //input  [127:0]
    .axis_slave2_tlast          (axis_slave2_tlast      ),      //input
    .axis_slave2_tuser          (axis_slave2_tuser      ),      //input
     
    .pm_xtlh_block_tlp          (                       ),      //output
    
    .cfg_send_cor_err_mux       (                       ),      //output
    .cfg_send_nf_err_mux        (                       ),      //output
    .cfg_send_f_err_mux         (                       ),      //output
    .cfg_sys_err_rc             (                       ),      //output
    .cfg_aer_rc_err_mux         (                       ),      //output
    //radm timeout
    .radm_cpl_timeout           (                       ),      //output
    
    //configuration signals
    .cfg_max_rd_req_size        (cfg_max_rd_req_size    ),      //output [2:0]
    .cfg_bus_master_en          (                       ),      //output
    .cfg_max_payload_size       (cfg_max_payload_size   ),      //output [2:0]
    .cfg_ext_tag_en             (                       ),      //output
    .cfg_rcb                    (/*cfg_rcb*/            ),      //output
    .cfg_mem_space_en           (                       ),      //output
    .cfg_pm_no_soft_rst         (                       ),      //output
    .cfg_crs_sw_vis_en          (                       ),      //output
    .cfg_no_snoop_en            (                       ),      //output
    .cfg_relax_order_en         (                       ),      //output
    .cfg_tph_req_en             (                       ),      //output [2-1:0]
    .cfg_pf_tph_st_mode         (                       ),      //output [3-1:0]
    .rbar_ctrl_update           (                       ),      //output
    .cfg_atomic_req_en          (                       ),      //output
    
    .cfg_pbus_num               (cfg_pbus_num           ),      //output [7:0]
    .cfg_pbus_dev_num           (cfg_pbus_dev_num       ),      //output [4:0]
    
    //debug signals
    .radm_idle                  (                       ),      //output
    .radm_q_not_empty           (                       ),      //output
    .radm_qoverflow             (                       ),      //output
    .diag_ctrl_bus              (2'b0                   ),      //input   [1:0]
    .cfg_link_auto_bw_mux       (                       ),      //output              merge cfg_link_auto_bw_msi and cfg_link_auto_bw_int
    .cfg_bw_mgt_mux             (                       ),      //output              merge cfg_bw_mgt_int and cfg_bw_mgt_msi
    .cfg_pme_mux                (                       ),      //output              merge cfg_pme_int and cfg_pme_msi
    .app_ras_des_sd_hold_ltssm  (1'b0                   ),      //input
    .app_ras_des_tba_ctrl       (2'b0                   ),      //input   [1:0]
    
    .dyn_debug_info_sel         (4'b0                   ),      //input   [3:0]
    .debug_info_mux             (                       ),      //output  [132:0]
    
    //system signal
    .smlh_link_up               (smlh_link_up           ),      //output
    .rdlh_link_up               (rdlh_link_up          ),      //output
    .smlh_ltssm_state           (/*smlh_ltssm_state*/     )       //output  [4:0]
);
                 
/////////////////////////////////////////////////////////////////////////////////////
endmodule
