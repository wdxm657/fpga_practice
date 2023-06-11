// Created by IP Generator (Version 2021.3 build 83302)



//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2014 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename:ips2t_apm_data_pipeline.v
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
module ipm2l_apm_data_pipeline
#(
    parameter DATA_WIDTH = 25
)
(
    din       ,

    addr      ,

    clk       ,
    rst       ,
    dout
);

localparam FIXED_DEPTH = 4 ; // @IPC int 1,1024

localparam VARIABLE_MAX_DEPTH = 15 ; // @IPC int 1,1024

localparam SHIFT_REG_TYPE = "dynamic_latency" ; // @IPC enum fixed_latency,dynamic_latency

localparam SHIFT_REG_TYPE_BOOL = 1 ; // @IPC bool

localparam RST_TYPE = "ASYNC" ; // @IPC enum ASYNC,SYNC

localparam DEPTH = (SHIFT_REG_TYPE=="fixed_latency"  ) ? FIXED_DEPTH :
                   (SHIFT_REG_TYPE=="dynamic_latency") ? VARIABLE_MAX_DEPTH : 0;

localparam ADDR_WIDTH = (DEPTH<=16)   ? 4 :
                        (DEPTH<=32)   ? 5 :
                        (DEPTH<=64)   ? 6 :
                        (DEPTH<=128)  ? 7 :
                        (DEPTH<=256)  ? 8 :
                        (DEPTH<=512)  ? 9 : 10 ;


input  wire     [DATA_WIDTH-1:0]       din     ;

input  wire     [ADDR_WIDTH-1:0]       addr    ;
 
input  wire                            clk     ;
input  wire                            rst     ;
output wire     [DATA_WIDTH-1:0]       dout    ;

reg  [DATA_WIDTH-1:0] din_ff;
wire [DATA_WIDTH-1:0] dout_mem;
wire [ADDR_WIDTH-1:0] addr_mem;

always@(posedge clk or posedge rst)
begin
    if(rst)
        din_ff <= {DATA_WIDTH{1'b0}};
    else
        din_ff <= din;
end

assign dout = (addr == 0) ? din : 
              (addr == 1) ? din_ff : dout_mem;

assign addr_mem = (addr < 2) ? {ADDR_WIDTH{1'b0}} : (addr - 1);

ipm2l_apm_distributed_shiftregister
   #(
    .FIXED_DEPTH         (FIXED_DEPTH        )  ,
    .VARIABLE_MAX_DEPTH  (VARIABLE_MAX_DEPTH )  ,
    .DATA_WIDTH          (DATA_WIDTH         )  ,
    .SHIFT_REG_TYPE      (SHIFT_REG_TYPE     )  ,
    .RST_TYPE            (RST_TYPE           )
    )u_ipm2l_apm_distributed_shiftregister
    (
    .din                 (din                )  ,
     
    .addr                (addr_mem           )  ,
    
    .clk                 (clk                )  ,
    .rst                 (rst                )  ,
    .dout                (dout_mem           )
    );
endmodule
