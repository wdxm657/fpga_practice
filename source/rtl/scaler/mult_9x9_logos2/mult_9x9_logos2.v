// Created by IP Generator (Version 2022.1-rc1 build 98233)


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
// Filename: mult_9x9_logos2.v                 
//////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module mult_9x9_logos2
( 
     ce  ,
     rst ,
     clk ,
     a   ,
     b   ,
     p
);



localparam ASIZE               = 9 ; //@IPC int 2,82

localparam BSIZE               = 9 ; //@IPC int 2,82

localparam A_SIGNED            = 0 ; //@IPC enum 0,1

localparam B_SIGNED            = 0 ; //@IPC enum 0,1

localparam ASYNC_RST           = 1 ; //@IPC enum 0,1

localparam OPTIMAL_TIMING      = 0 ; //@IPC enum 0,1

localparam INREG_EN            = 0 ; //@IPC enum 0,1

localparam PIPEREG_EN_1        = 1 ; //@IPC enum 0,1

localparam PIPEREG_EN_2        = 0 ; //@IPC enum 0,1

localparam PIPEREG_EN_3        = 0 ; //@IPC enum 0,1

localparam OUTREG_EN           = 0 ; //@IPC enum 0,1

//tmp variable for ipc purpose 

localparam PIPE_STATUS         = 1 ; //@IPC enum 0,1,2,3,4,5

localparam ASYNC_RST_BOOL      = 1 ; //@IPC bool

localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool

localparam ADVANCED_BOOL       = 0 ; //@IPC bool

//end of tmp variable
localparam  GRS_EN       = "FALSE"         ;  

localparam  PSIZE = ASIZE + BSIZE          ;  

input                 ce  ;
input                 rst ;
input                 clk ;
input  [ASIZE-1:0]    a   ;
input  [BSIZE-1:0]    b   ;
output [PSIZE-1:0]    p   ;

ipm2l_mult_v1_2_mult_9x9_logos2
#(  
    .ASIZE           ( ASIZE            ),
    .BSIZE           ( BSIZE            ),
    .OPTIMAL_TIMING  ( OPTIMAL_TIMING   ), 

    .INREG_EN        ( INREG_EN         ),    
    .PIPEREG_EN_1    ( PIPEREG_EN_1     ),     
    .PIPEREG_EN_2    ( PIPEREG_EN_2     ),
    .PIPEREG_EN_3    ( PIPEREG_EN_3     ),
    .OUTREG_EN       ( OUTREG_EN        ),
    .PIPE_STATUS     ( PIPE_STATUS      ),

    .ADVANCED_BOOL   ( ADVANCED_BOOL    ),

    .GRS_EN          ( GRS_EN           ),  
    .A_SIGNED        ( A_SIGNED         ),     
    .B_SIGNED        ( B_SIGNED         ),     
    .ASYNC_RST       ( ASYNC_RST        )      
)u_ipm2l_mult_mult_9x9_logos2
(
    .ce              ( ce     ),
    .rst             ( rst    ),
    .clk             ( clk    ),
    .a               ( a      ),
    .b               ( b      ),
    .p               ( p      )
);

endmodule
