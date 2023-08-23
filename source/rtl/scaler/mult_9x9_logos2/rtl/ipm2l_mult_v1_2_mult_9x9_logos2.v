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
// Filename:ipm2l_mult.v
// Function: p=a*b
//           asize:2-73(singed)/72(unsigned)
//           bsize:2-82(singed)/81(unsigned)
//           psize:asize+bszie
/////////////////////////////////////////////////////////////////////////////
module ipm2l_mult_v1_2_mult_9x9_logos2
#(
    parameter   ASIZE           = 54,
    parameter   BSIZE           = 27,
    parameter   PSIZE           = ASIZE + BSIZE,
    //signed
    parameter   A_SIGNED        = 0,
    parameter   B_SIGNED        = 0,

    parameter   OPTIMAL_TIMING  = 0,
    //pipeline
    parameter   INREG_EN        = 0,
    parameter   PIPEREG_EN_1    = 0,
    parameter   PIPEREG_EN_2    = 0,
    parameter   PIPEREG_EN_3    = 0,
    parameter   OUTREG_EN       = 0,
    parameter   PIPE_STATUS     = 3,

    parameter   ADVANCED_BOOL   = 0,

    parameter   GRS_EN          = "FALSE",      //"TRUE","FALSE",enable global reset

    parameter   ASYNC_RST       = 1             // RST is sync/async

)(
    input                       ce  ,
    input                       rst ,
    input                       clk ,
    input       [ASIZE-1:0]     a   ,           //unsigned:72, signed:73
    input       [BSIZE-1:0]     b   ,           //unsigned:81, signed:82
    output wire [PSIZE-1:0]     p
);


localparam OPTIMAL_TIMING_BOOL = 0 ; //@IPC bool


localparam ASIZE_SIGNED  = (A_SIGNED == 1) ? ASIZE : (ASIZE + 1);

localparam BSIZE_SIGNED  = (B_SIGNED == 1) ? BSIZE : (BSIZE + 1);

localparam MAX_DATA_SIZE = (ASIZE_SIGNED >= BSIZE_SIGNED)? ASIZE_SIGNED : BSIZE_SIGNED;

localparam MIN_DATA_SIZE = (ASIZE_SIGNED <  BSIZE_SIGNED)? ASIZE_SIGNED : BSIZE_SIGNED;

localparam USE_SIMD      = (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9) ? 1 : 0;  // single addsub25_mult25_add48 / dual addsub12_mult12_add24

localparam USE_POSTADD   = 1'b1;

//****************************************data_size error check**********************************************************
localparam N = (MIN_DATA_SIZE < 2 )  ? 0 :
               (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? 1 :       //25x18
               (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? 2 :       //25x34
               (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? 2 :       //49x18
               (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? 3 :       //25x50
               (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? 3 :       //73x18
               (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) ? 4 :       //25x66
               (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) ? 4 :       //49x34
               (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) ? 5 :       //25x82
               (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) ? 6 :       //49x50
               (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) ? 6 :       //73x34
               (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) ? 8 :       //49x66
               (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) ? 9 :       //73x50
               (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) ? 10 :      //49x82
               (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) ? 12 :      //73x66
               (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) ? 15 :  0 ; //73x82

localparam GTP_APM_E2_NUM = N;
//****************************************************************DATA WIDTH****************************************
localparam M_A_DATA_WIDTH   = (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 ) ? MAX_DATA_SIZE :     //12x9
                              (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? MAX_DATA_SIZE :     //25x18
                              (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? MIN_DATA_SIZE :     //25x34
                              (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? MAX_DATA_SIZE :     //49x18
                              (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? MIN_DATA_SIZE :     //25x50
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? MAX_DATA_SIZE :     //73x18
                              (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) ? MIN_DATA_SIZE :     //25x66
                              (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) ? MAX_DATA_SIZE :     //49x34
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) ? MIN_DATA_SIZE :     //25x82
                              (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) ? MIN_DATA_SIZE :     //49x50
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) ? MAX_DATA_SIZE :     //73x34
                              (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) ? MIN_DATA_SIZE :     //49x66
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) ? MAX_DATA_SIZE :     //73x50
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) ? MIN_DATA_SIZE :     //49x82
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) ? MAX_DATA_SIZE :     //73x66
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) ? MIN_DATA_SIZE : MAX_DATA_SIZE;  //73x82

localparam M_B_DATA_WIDTH   = (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 ) ? MIN_DATA_SIZE :     //12x9
                              (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? MIN_DATA_SIZE :     //25x18
                              (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? MAX_DATA_SIZE :     //25x34
                              (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? MIN_DATA_SIZE :     //49x18
                              (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? MAX_DATA_SIZE :     //25x50
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? MIN_DATA_SIZE :     //73x18
                              (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) ? MAX_DATA_SIZE :     //25x66
                              (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) ? MIN_DATA_SIZE :     //49x34
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) ? MAX_DATA_SIZE :     //25x82
                              (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) ? MAX_DATA_SIZE :     //49x50
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) ? MIN_DATA_SIZE :     //73x34
                              (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) ? MAX_DATA_SIZE :     //49x66
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) ? MIN_DATA_SIZE :     //73x50
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) ? MAX_DATA_SIZE :     //49x82
                              (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) ? MIN_DATA_SIZE :     //73x66
                              (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) ? MAX_DATA_SIZE : MIN_DATA_SIZE;  //73x82

//****************************************************************GTP_APM_E2 cascade****************************************
localparam [14:0] X_SEL = (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 ) ? 15'b0 :                             //12x9
                          (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? 15'b0 :                             //25x18
                          (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? 15'b0 :                             //25x34
                          (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? 15'b0 :                             //49x18
                          (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? 15'b000_0000_0000_0110 :            //25x50
                          (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? 15'b0 :                             //73x18
                          (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) ? 15'b000_0000_0000_1110 :            //25x66
                          (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) ? 15'b000_0000_0000_1010 :            //49x34
                          (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) ? 15'b000_0000_0001_1110 :            //25x82
                          (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) ? 15'b000_0000_0010_0010 :            //49x50
                          (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) ? 15'b000_0000_0010_1010 :            //73x34
                          (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) ? 15'b000_0000_1000_0010 :            //49x66
                          (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) ? 15'b000_0001_0000_0010 :            //73x50
                          (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) ? 15'b000_0010_0000_0010 :            //49x82
                          (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) ? 15'b000_1000_0000_0010 :            //73x66
                          (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) ? 15'b100_0000_0000_0010 : 15'b0 ;    //73x82

localparam [14:0] CXO_REG = (OPTIMAL_TIMING == 0 ) ? 15'b0 :
                            (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 ) ? 15'b0 :                           //12x9
                            (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? 15'b0 :                           //25x18
                            (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? 15'b0 :                           //25x34
                            (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? 15'b0 :                           //49x18
                            (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? 15'b0 :                           //25x50
                            (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? 15'b0 :                           //73x18
                            (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) ? 15'b000_0000_0000_0010 :          //25x66
                            (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) ? 15'b0 :                           //49x34
                            (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) ? 15'b000_0000_0000_1010 :          //25x82
                            (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) ? 15'b0 :                           //49x50
                            (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) ? 15'b0 :                           //73x34
                            (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) ? 15'b0 :                           //49x66
                            (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) ? 15'b000_0000_1000_0000 :          //73x50
                            (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) ? 15'b0 :                           //49x82
                            (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) ? 15'b0 :                           //73x66
                            (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) ? 15'b0100_0000_0000_000 : 15'b0 ;  //73x82

localparam [14:0] CPO_REG = (OPTIMAL_TIMING == 0 ) ? 16'b0 :
                            (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) ? 15'b0 :  //25x18
                            (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) ? 15'b0 :  //25x34
                            (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18) ? 15'b0 :  //49x18
                            (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) ? 15'b0 :  //25x50
                            (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) ? 15'b0 :  //73x18
                            15'b010_1010_1010_1010;   //other ouput reg

//**************************************************************************************************************************
initial
begin
    if (N == 0)
        $display("apm_mult parameter setting error!!! DATA_SIZE must between 2*2-73*82(signed)/72*81(unsigned)");
end

//**********************************************************reg & wire******************************************************
wire [ASIZE_SIGNED-1:0]     a_signed;
wire [BSIZE_SIGNED-1:0]     b_signed;

wire [MAX_DATA_SIZE-1:0]    max_data;
wire [MIN_DATA_SIZE-1:0]    min_data;

wire [M_A_DATA_WIDTH-1:0]   m_a;
wire [M_B_DATA_WIDTH-1:0]   m_b;

wire [47:0]     m_p[14:0];
wire [47:0]     cpo[15:0];
wire [29:0]     cxo[15:0];

wire [24:0]     m_a_0;
wire [24:0]     m_a_1;
wire [24:0]     m_a_2;
wire [17:0]     m_b_0;
wire [17:0]     m_b_1;
wire [17:0]     m_b_2;
wire [17:0]     m_b_3;
wire [17:0]     m_b_4;
wire [72:0]     m_a_sign_ext;
wire [81:0]     m_b_sign_ext;

reg  [2:0]      modez_in[14:0]; //3'd0:add zero;
                                //3'd3:shift 0;
                                //3'd4:shift 17;
                                //3'd5:shift 24;
                                //3'd6:shift 16;
                                //3'd7:shift 8;

reg  [24:0]     m_a_div   [14:0];
reg  [24:0]     m_a_div_ff[14:0];
reg  [17:0]     m_b_div   [14:0];
reg  [17:0]     m_b_div_ff[14:0];
wire [24:0]     m_a_in    [14:0];
wire [17:0]     m_b_in    [14:0];

wire [154:0]    m_p_o     ;
reg  [154:0]    m_p_o_ff  ;

wire            rst_sync  ;
wire            rst_async ;


//rst
assign rst_sync  = (ASYNC_RST == 0)  ? rst : 1'b0;
assign rst_async = (ASYNC_RST == 1)  ? rst : 1'b0;

assign a_signed = (A_SIGNED == 1) ? a : {1'b0,a}; //unsigned -> signed
assign b_signed = (B_SIGNED == 1) ? b : {1'b0,b}; //unsigned -> signed

assign max_data = (ASIZE_SIGNED >= BSIZE_SIGNED) ? a_signed : b_signed;
assign min_data = (ASIZE_SIGNED <  BSIZE_SIGNED) ? a_signed : b_signed;

//data a
generate
begin
    if(MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 )          //12x9
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18)    //25x18
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25)    //25x34
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18)    //49x18
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25)    //25x50
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18)    //73x18
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25)    //25x66
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34)    //49x34
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25)    //25x82
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49)    //49x50
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34)    //73x34
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49)    //49x66
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50)    //73x50
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49)    //49x82
        assign m_a = min_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66)    //73x66
        assign m_a = max_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73)    //73x82
        assign m_a = min_data;
end
endgenerate

//data b
generate
begin
    if(MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 )          //12x9
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18)    //25x18
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25)    //25x34
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18)    //49x18
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25)    //25x50
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18)    //73x18
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25)    //25x66
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34)    //49x34
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25)    //25x82
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49)    //49x50
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34)    //73x34
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49)    //49x66
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50)    //73x50
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49)    //49x82
        assign m_b = max_data;
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66)    //73x66
        assign m_b = min_data;
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73)    //73x82
        assign m_b = max_data;
end
endgenerate
//*******************************************************partition input data***********************************************
assign m_a_sign_ext = {{{73-M_A_DATA_WIDTH}{m_a[M_A_DATA_WIDTH-1]}},m_a};
assign m_b_sign_ext = {{{82-M_B_DATA_WIDTH}{m_b[M_B_DATA_WIDTH-1]}},m_b};

//partition data a
generate
begin:partition_data_a
    if (M_A_DATA_WIDTH <= 25)
    begin
        assign m_a_0 = m_a_sign_ext[24:0];
    end
    else if (M_A_DATA_WIDTH <= 49)
    begin
        assign m_a_0 = {1'b0,m_a_sign_ext[23:0]};
        assign m_a_1 = m_a_sign_ext[48:24];
    end
    else if (M_A_DATA_WIDTH <= 73)
    begin
        assign m_a_0 = {1'b0,m_a_sign_ext[23:0]};
        assign m_a_1 = {1'b0,m_a_sign_ext[47:24]};
        assign m_a_2 = m_a_sign_ext[72:48];
    end
end
endgenerate

//partition data b
generate
begin:partition_data_b
    if (M_B_DATA_WIDTH <= 18)
    begin
        assign m_b_0 = m_b_sign_ext[17:0];
    end
    else if (M_B_DATA_WIDTH <= 34)
    begin
        assign m_b_0 = {2'b0,m_b_sign_ext[15:0]};
        assign m_b_1 = m_b_sign_ext[33:16];
    end
    else if (M_B_DATA_WIDTH <= 50)
    begin
        assign m_b_0 = {2'b0,m_b_sign_ext[15:0]};
        assign m_b_1 = {2'b0,m_b_sign_ext[31:16]};
        assign m_b_2 = m_b_sign_ext[49:32];
    end
    else if (M_B_DATA_WIDTH <= 66)
    begin
        assign m_b_0 = {2'b0,m_b_sign_ext[15:0]};
        assign m_b_1 = {2'b0,m_b_sign_ext[31:16]};
        assign m_b_2 = {2'b0,m_b_sign_ext[47:32]};
        assign m_b_3 = m_b_sign_ext[65:48];
    end
    else if (M_B_DATA_WIDTH <= 82)
    begin
        assign m_b_0 = {2'b0,m_b_sign_ext[15:0]};
        assign m_b_1 = {2'b0,m_b_sign_ext[31:16]};
        assign m_b_2 = {2'b0,m_b_sign_ext[47:32]};
        assign m_b_3 = {2'b0,m_b_sign_ext[63:48]};
        assign m_b_4 = m_b_sign_ext[81:64];
    end
end
endgenerate

//for cpo_reg sum
reg  [3:0]  reg_sum [13:0];
wire [13:0] cpo_cnt;
assign cpo_cnt = CPO_REG;
integer k;
always@(*)
begin
    reg_sum[0] = {3'b0, cpo_cnt[0]};
    for(k = 1; k < 14; k = k + 1)
    begin
        reg_sum[k] = reg_sum[k-1] + cpo_cnt[k];
    end
end        

//for data pipeline
wire [24:0] a_0  [14:0];
wire [24:0] a_1  [14:0];
wire [24:0] a_2  [14:0];
wire [17:0] b_0  [14:0];
wire [17:0] b_1  [14:0];
wire [17:0] b_2  [14:0];
wire [17:0] b_3  [14:0];
wire [17:0] b_4  [14:0];
wire [42:0] p_0  [14:0];
wire [42:0] p_1  [14:0];
wire [42:0] p_2  [14:0];
wire [42:0] p_3  [14:0];
wire [42:0] p_4  [14:0];
wire [42:0] p_5  [14:0];
wire [42:0] p_6  [14:0];
wire [42:0] p_7  [14:0];
wire [42:0] p_8  [14:0];
wire [42:0] p_9  [14:0];
wire [42:0] p_10 [14:0];
wire [42:0] p_11 [14:0];
wire [42:0] p_12 [14:0];
wire [42:0] p_13 [14:0];

genvar pipe_i;
generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_a_0_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 25 )
        )
        m_a_0_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_a_0       ),
            .addr ( pipe_i      ),
            .dout ( a_0[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_a_1_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 25 )
        )
        m_a_1_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_a_1       ),
            .addr ( pipe_i      ),
            .dout ( a_1[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_a_2_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 25 )
        )
        m_a_2_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_a_2       ),
            .addr ( pipe_i      ),
            .dout ( a_2[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_b_0_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 18 )
        )
        m_b_0_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_b_0       ),
            .addr ( pipe_i      ),
            .dout ( b_0[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_b_1_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 18 )
        )
        m_b_1_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_b_1       ),
            .addr ( pipe_i      ),
            .dout ( b_1[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_b_2_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 18 )
        )
        m_b_2_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_b_2       ),
            .addr ( pipe_i      ),
            .dout ( b_2[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_b_3_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 18 )
        )
        m_b_3_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_b_3       ),
            .addr ( pipe_i      ),
            .dout ( b_3[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_b_4_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 18 )
        )
        m_b_4_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_b_4       ),
            .addr ( pipe_i      ),
            .dout ( b_4[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_0_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_0_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[0]      ),
            .addr ( pipe_i      ),
            .dout ( p_0[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_1_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_1_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[1]      ),
            .addr ( pipe_i      ),
            .dout ( p_1[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_2_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_2_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[2]      ),
            .addr ( pipe_i      ),
            .dout ( p_2[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_3_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_3_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[3]      ),
            .addr ( pipe_i      ),
            .dout ( p_3[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_4_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_4_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[4]      ),
            .addr ( pipe_i      ),
            .dout ( p_4[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_5_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_5_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[5]      ),
            .addr ( pipe_i      ),
            .dout ( p_5[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_6_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_6_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[6]      ),
            .addr ( pipe_i      ),
            .dout ( p_6[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_7_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_7_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[7]      ),
            .addr ( pipe_i      ),
            .dout ( p_7[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_8_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_8_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[8]      ),
            .addr ( pipe_i      ),
            .dout ( p_8[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_9_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_9_pipe
        (
            .clk  ( clk         ),
            .rst  ( rst         ),
            .din  ( m_p[9]      ),
            .addr ( pipe_i      ),
            .dout ( p_9[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_10_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_10_pipe
        (
            .clk  ( clk          ),
            .rst  ( rst          ),
            .din  ( m_p[10]      ),
            .addr ( pipe_i       ),
            .dout ( p_10[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_11_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_11_pipe
        (
            .clk  ( clk          ),
            .rst  ( rst          ),
            .din  ( m_p[11]      ),
            .addr ( pipe_i       ),
            .dout ( p_11[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_12_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_12_pipe
        (
            .clk  ( clk          ),
            .rst  ( rst          ),
            .din  ( m_p[12]      ),
            .addr ( pipe_i       ),
            .dout ( p_12[pipe_i] )
        );
    end
endgenerate

generate
    for (pipe_i = 0; pipe_i < 15; pipe_i = pipe_i + 1)
    begin:m_p_13_pipe
        ipm2l_apm_data_pipeline
        #(
            .DATA_WIDTH ( 43 )
        )
        m_p_13_pipe
        (
            .clk  ( clk          ),
            .rst  ( rst          ),
            .din  ( m_p[13]      ),
            .addr ( pipe_i       ),
            .dout ( p_13[pipe_i] )
        );
    end
endgenerate
//*******************************************************input data***********************************************************
generate
begin:data_for_GTP
    if (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 ) //12x9
    begin:mode_12_9
        always@(*)
        begin
            m_a_div[0]   = {13'b0,m_a_0[11:0]};
            m_b_div[0]   = {9'b0,m_b_0[8:0]};
            modez_in[0]  = 3'd0;
        end
    end
    else if (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18) //25x18
    begin:mode_25_18
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_b_div[0]   = m_b_0;
            modez_in[0]  = 3'd0;
        end
    end
    else if (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25) //25x34
    begin:mode_25_34
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18)  //49x18
    begin:mode_49_18
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_1[reg_sum[0]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_0[reg_sum[0]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd5; //shift 24
        end
    end
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25) //25x50
    begin:mode_25_50
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_0[reg_sum[1]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_2[reg_sum[1]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18) //73x18
    begin:mode_73_18
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_1[reg_sum[0]];
            m_a_div[2]   = a_2[reg_sum[1]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_0[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd5; //shift 24
            modez_in[2]  = 3'd5; //shift 24
        end
    end
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25) //25x66
    begin:mode_25_66
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_0[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_2[reg_sum[1]];
            m_b_div[3]   = b_3[reg_sum[2]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd6; //shift 16
            modez_in[3]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34) //49x34
    begin:mode_49_34
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_1[reg_sum[2]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_1[reg_sum[2]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25) //25x82
    begin:mode_25_82
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_0[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_0[reg_sum[3]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_2[reg_sum[1]];
            m_b_div[3]   = b_3[reg_sum[2]];
            m_b_div[4]   = b_4[reg_sum[3]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd6; //shift 16
            modez_in[3]  = 3'd6; //shift 16
            modez_in[4]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49) //49x50
    begin:mode_49_50
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_1[reg_sum[4]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_2[reg_sum[4]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34) //73x34
    begin:mode_73_34
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_1[reg_sum[2]];
            m_a_div[4]   = a_2[reg_sum[3]];
            m_a_div[5]   = a_2[reg_sum[4]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_1[reg_sum[2]];
            m_b_div[4]   = b_0[reg_sum[3]];
            m_b_div[5]   = b_1[reg_sum[4]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd6; //shift 16
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49) //49x66
    begin:mode_49_66
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_0[reg_sum[4]];
            m_a_div[6]   = a_1[reg_sum[5]];
            m_a_div[7]   = a_1[reg_sum[6]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_3[reg_sum[4]];
            m_b_div[6]   = b_2[reg_sum[5]];
            m_b_div[7]   = b_3[reg_sum[6]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd7; //shift 8
            modez_in[6]  = 3'd7; //shift 8
            modez_in[7]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50) //73x50
    begin:mode_73_50
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_2[reg_sum[4]];
            m_a_div[6]   = a_1[reg_sum[5]];
            m_a_div[7]   = a_2[reg_sum[6]];
            m_a_div[8]   = a_2[reg_sum[7]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_0[reg_sum[4]];
            m_b_div[6]   = b_2[reg_sum[5]];
            m_b_div[7]   = b_1[reg_sum[6]];
            m_b_div[8]   = b_2[reg_sum[7]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd7; //shift 8
            modez_in[6]  = 3'd7; //shift 8
            modez_in[7]  = 3'd7; //shift 8
            modez_in[8]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49) //49x82
    begin:mode_49_82
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_0[reg_sum[4]];
            m_a_div[6]   = a_1[reg_sum[5]];
            m_a_div[7]   = a_0[reg_sum[6]];
            m_a_div[8]   = a_1[reg_sum[7]];
            m_a_div[9]   = a_1[reg_sum[8]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_3[reg_sum[4]];
            m_b_div[6]   = b_2[reg_sum[5]];
            m_b_div[7]   = b_4[reg_sum[6]];
            m_b_div[8]   = b_3[reg_sum[7]];
            m_b_div[9]   = b_4[reg_sum[8]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd7; //shift 8
            modez_in[6]  = 3'd7; //shift 8
            modez_in[7]  = 3'd7; //shift 8
            modez_in[8]  = 3'd7; //shift 8
            modez_in[9]  = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66) //73x66
    begin:mode_73_66
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_0[reg_sum[4]];
            m_a_div[6]   = a_2[reg_sum[5]];
            m_a_div[7]   = a_1[reg_sum[6]];
            m_a_div[8]   = a_2[reg_sum[7]];
            m_a_div[9]   = a_1[reg_sum[8]];
            m_a_div[10]  = a_2[reg_sum[9]];
            m_a_div[11]  = a_2[reg_sum[10]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_3[reg_sum[4]];
            m_b_div[6]   = b_0[reg_sum[5]];
            m_b_div[7]   = b_2[reg_sum[6]];
            m_b_div[8]   = b_1[reg_sum[7]];
            m_b_div[9]   = b_3[reg_sum[8]];
            m_b_div[10]  = b_2[reg_sum[9]];
            m_b_div[11]  = b_3[reg_sum[10]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd7; //shift 8
            modez_in[6]  = 3'd3; //shift 0
            modez_in[7]  = 3'd7; //shift 8
            modez_in[8]  = 3'd7; //shift 8
            modez_in[9]  = 3'd7; //shift 8
            modez_in[10] = 3'd7; //shift 8
            modez_in[11] = 3'd6; //shift 16
        end
    end
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73) //73x82
    begin:mode_73_82
        always@(*)
        begin
            m_a_div[0]   = m_a_0;
            m_a_div[1]   = a_0[reg_sum[0]];
            m_a_div[2]   = a_1[reg_sum[1]];
            m_a_div[3]   = a_0[reg_sum[2]];
            m_a_div[4]   = a_1[reg_sum[3]];
            m_a_div[5]   = a_0[reg_sum[4]];
            m_a_div[6]   = a_2[reg_sum[5]];
            m_a_div[7]   = a_1[reg_sum[6]];
            m_a_div[8]   = a_2[reg_sum[7]];
            m_a_div[9]   = a_0[reg_sum[8]];
            m_a_div[10]  = a_1[reg_sum[9]];
            m_a_div[11]  = a_2[reg_sum[10]];
            m_a_div[12]  = a_1[reg_sum[11]];
            m_a_div[13]  = a_2[reg_sum[12]];
            m_a_div[14]  = a_2[reg_sum[13]];
            m_b_div[0]   = m_b_0;
            m_b_div[1]   = b_1[reg_sum[0]];
            m_b_div[2]   = b_0[reg_sum[1]];
            m_b_div[3]   = b_2[reg_sum[2]];
            m_b_div[4]   = b_1[reg_sum[3]];
            m_b_div[5]   = b_3[reg_sum[4]];
            m_b_div[6]   = b_0[reg_sum[5]];
            m_b_div[7]   = b_2[reg_sum[6]];
            m_b_div[8]   = b_1[reg_sum[7]];
            m_b_div[9]   = b_4[reg_sum[8]];
            m_b_div[10]  = b_3[reg_sum[9]];
            m_b_div[11]  = b_2[reg_sum[10]];
            m_b_div[12]  = b_4[reg_sum[11]];
            m_b_div[13]  = b_3[reg_sum[12]];
            m_b_div[14]  = b_4[reg_sum[13]];
            modez_in[0]  = 3'd0;
            modez_in[1]  = 3'd6; //shift 16
            modez_in[2]  = 3'd7; //shift 8
            modez_in[3]  = 3'd7; //shift 8
            modez_in[4]  = 3'd7; //shift 8
            modez_in[5]  = 3'd7; //shift 8
            modez_in[6]  = 3'd3; //shift 0
            modez_in[7]  = 3'd7; //shift 8
            modez_in[8]  = 3'd7; //shift 8
            modez_in[9]  = 3'd3; //shift 0
            modez_in[10] = 3'd7; //shift 8
            modez_in[11] = 3'd7; //shift 8
            modez_in[12] = 3'd7; //shift 8
            modez_in[13] = 3'd7; //shift 8
            modez_in[14] = 3'd6; //shift 16
        end
    end
end
endgenerate

genvar m_i;
generate
    for (m_i=0; m_i < GTP_APM_E2_NUM; m_i=m_i+1)
    begin:data_in
        always@(posedge clk or posedge rst_async)
        begin:inreg
            if (rst_async)
            begin
                m_a_div_ff[m_i]  <= 25'b0;
                m_b_div_ff[m_i]  <= 18'b0;
            end
            else if (rst_sync)
            begin
                m_a_div_ff[m_i]  <= 25'b0;
                m_b_div_ff[m_i]  <= 18'b0;
            end
            else if (ce)
            begin
                m_a_div_ff[m_i]  <= m_a_div[m_i];
                m_b_div_ff[m_i]  <= m_b_div[m_i];
            end
        end

        assign m_a_in[m_i] = (INREG_EN == 1) ? m_a_div_ff[m_i] : m_a_div[m_i];
        assign m_b_in[m_i] = (INREG_EN == 1) ? m_b_div_ff[m_i] : m_b_div[m_i];
    end
endgenerate

//************************************************************GTP*********************************************************
genvar i;
generate
    for (i=0; i< GTP_APM_E2_NUM; i=i+1)
    begin:mult
        GTP_APM_E2 #(
            .GRS_EN         ( GRS_EN                 ) ,  //"TRUE","FALSE",enable global reset
            .USE_POSTADD    ( USE_POSTADD            ) ,  //enable postadder 0/1
            .USE_PREADD     ( 1'b0                   ) ,  //enable preadder 0/1
            .PREADD_REG     ( 1'b0                   ) ,  //preadder reg 0/1

            .X_REG          ( PIPEREG_EN_1           ) ,  //X input reg 0/1
            .CXO_REG        ( {1'b0,CXO_REG[i]}      ) ,  //X cascade out reg latency, 0/1/2/3
            .XB_REG         ( 1'b0                   ) ,  //XB input reg 0/1
            .Y_REG          ( PIPEREG_EN_1           ) ,  //Y input reg 0/1
            .Z_REG          ( PIPEREG_EN_1           ) ,  //Z input reg 0/1
            .MULT_REG       ( PIPEREG_EN_2           ) ,  //multiplier reg 0/1
            .P_REG          ( PIPEREG_EN_3           ) ,  //post adder reg 0/1
            .MODEY_REG      ( 1'b0                   ) ,  //MODEY reg
            .MODEZ_REG      ( 1'b0                   ) ,  //MODEZ reg
            .MODEIN_REG     ( 1'b0                   ) ,  //MODEZ reg

            .X_SEL          ( X_SEL[i]               ) ,  // mult X input select X/CXI
            .XB_SEL         ( 2'b0                   ) ,  //X back propagate mux select. 0/1/2/3
            .ASYNC_RST      ( ASYNC_RST              ) ,  // RST is sync/async
            .USE_SIMD       ( USE_SIMD               ) ,  // single addsub25_mult25_add48 / dual addsub12_mult12_add24
            .P_INIT0        ( {48{1'b0}}             ) ,  //P constant input0 (RTI parameter in APM of PG family)
            .P_INIT1        ( {48{1'b0}}             ) ,  //P constant input1 (RTI parameter in APM of PG family)
            .ROUNDMODE_SEL  ( 1'b0                   ) ,  //round mode selection

            .CPO_REG        ( CPO_REG[i]             ) ,  // CPO,COUT use register output
            .USE_ACCLOW     ( 1'b0                   ) ,  // accumulator use lower 18-bit feedback only
            .CIN_SEL        ( 1'b0                   )    // select CIN for postadder carry in

        )
        mult
        (
            .P         ( m_p[i]                ) ,
            .CPO       ( cpo[i+1]              ) , //p cascade output
            .COUT      (                       ) ,
            .CXO       ( cxo[i+1]              ) , //x cascade output
            .CXBO      (                       ) , //x backward cascade output

            .X         ( {{5{1'b1}},m_a_in[i]} ) ,
            .CXI       ( cxo[i]                ) , //x cascade input
            .CXBI      ( 25'b0                 ) , //x backward cascade input
            .XB        ( {25{1'b1}}            ) , //x backward cascade input
            .Y         ( m_b_in[i]             ) ,
            .Z         ( {48{1'b1}}            ) ,
            .CPI       ( cpo[i]                ) , //p cascade input
            .CIN       ( 1'b0                  ) ,
            .MODEY     ( 3'b1                  ) ,
            .MODEZ     ( {1'b0,modez_in[i]}    ) ,
            .MODEIN    ( 5'b00010              ) ,

            .CLK       ( clk ) ,

            .CEX1      ( ce  ) , //X1 enable signals
            .CEX2      ( ce  ) , //X2 enable signals
            .CEX3      ( ce  ) , //X3 enable signals
            .CEXB      ( ce  ) , //XB enable signals
            .CEY1      ( ce  ) , //Y1 enable signals
            .CEY2      ( ce  ) , //Y2 enable signals
            .CEZ       ( ce  ) , //Z enable signals
            .CEPRE     ( ce  ) , //PRE enable signals
            .CEM       ( ce  ) , //M enable signals
            .CEP       ( ce  ) , //P enable signals
            .CEMODEY   ( ce  ) , //MODEY enable signals
            .CEMODEZ   ( ce  ) , //MODEZ enable signals
            .CEMODEIN  ( ce  ) , //MODEIN enable signals

            .RSTX      ( rst ) , //X reset signals
            .RSTXB     ( rst ) , //XB reset signals
            .RSTY      ( rst ) , //Y reset signals
            .RSTZ      ( rst ) , //Z reset signals
            .RSTPRE    ( rst ) , //PRE reset signals
            .RSTM      ( rst ) , //M reset signals
            .RSTP      ( rst ) , //P reset signals
            .RSTMODEY  ( rst ) , //MODEY reset signals
            .RSTMODEZ  ( rst ) , //MODEZ reset signals
            .RSTMODEIN ( rst )   //MODEIN reset signals

        );
    end
endgenerate
//*****************************************************************output***************************************************
generate
begin:outdata
    if (MAX_DATA_SIZE <= 12 && MIN_DATA_SIZE <= 9 )  //12x9
        assign m_p_o[20:0] = m_p[0][20:0];
    else if (MAX_DATA_SIZE <= 25 && MIN_DATA_SIZE <= 18)    //25x18
        assign m_p_o[42:0] = m_p[0][42:0];
    else if (MAX_DATA_SIZE <= 34 && MIN_DATA_SIZE <= 25)    //25x34
        assign m_p_o[58:0] = {m_p[1][42:0],p_0[reg_sum[0]][15:0]};
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 18)    //49x18
        assign m_p_o[66:0] = {m_p[1][42:0],p_0[reg_sum[0]][23:0]};
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 25)    //25x50
        assign m_p_o[74:0] = {m_p[2][42:0],p_1[reg_sum[1]-reg_sum[0]][15:0],p_0[reg_sum[1]][15:0]};
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 18)    //73x18
        assign m_p_o[90:0] = {m_p[2][42:0],p_1[reg_sum[1]-reg_sum[0]][23:0],p_0[reg_sum[1]][23:0]};
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 25)    //25x66
        assign m_p_o[90:0] = {m_p[3][42:0],p_2[reg_sum[2]-reg_sum[1]][15:0],p_1[reg_sum[2]-reg_sum[0]][15:0],p_0[reg_sum[2]][15:0]};
    else if (MAX_DATA_SIZE <= 49 && MIN_DATA_SIZE <= 34)    //49x34
        assign m_p_o[82:0] = {m_p[3][42:0],p_2[reg_sum[2]-reg_sum[1]][15:0],p_1[reg_sum[2]-reg_sum[0]][7:0],p_0[reg_sum[2]][15:0]};
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 25)    //25x82
        assign m_p_o[106:0] = {m_p[4][42:0],p_3[reg_sum[3]-reg_sum[2]][15:0],p_2[reg_sum[3]-reg_sum[1]][15:0],p_1[reg_sum[3]-reg_sum[0]][15:0],p_0[reg_sum[3]][15:0]};
    else if (MAX_DATA_SIZE <= 50 && MIN_DATA_SIZE <= 49)    //49x50
        assign m_p_o[98:0] = {m_p[5][42:0],p_4[reg_sum[4]-reg_sum[3]][15:0],p_3[reg_sum[4]-reg_sum[2]][7:0],p_2[reg_sum[4]-reg_sum[1]][7:0],p_1[reg_sum[4]-reg_sum[0]][7:0],p_0[reg_sum[4]][15:0]};
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 34)    //73x34
        assign m_p_o[106:0] = {m_p[5][42:0],p_4[reg_sum[4]-reg_sum[3]][15:0],p_3[reg_sum[4]-reg_sum[2]][7:0],p_2[reg_sum[4]-reg_sum[1]][15:0],p_1[reg_sum[4]-reg_sum[0]][7:0],p_0[reg_sum[4]][15:0]};
    else if (MAX_DATA_SIZE <= 66 && MIN_DATA_SIZE <= 49)    //49x66
        assign m_p_o[114:0] = {m_p[7][42:0],p_6[reg_sum[6]-reg_sum[5]][15:0],p_5[reg_sum[6]-reg_sum[4]][7:0],p_4[reg_sum[6]-reg_sum[3]][7:0],p_3[reg_sum[6]-reg_sum[2]][7:0],p_2[reg_sum[6]-reg_sum[1]][7:0],p_1[reg_sum[6]-reg_sum[0]][7:0],p_0[reg_sum[6]][15:0]};
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 50)    //73x50
        assign m_p_o[122:0] = {m_p[8][42:0],p_7[reg_sum[7]-reg_sum[6]][15:0],p_6[reg_sum[7]-reg_sum[5]][7:0],p_5[reg_sum[7]-reg_sum[4]][7:0],p_4[reg_sum[7]-reg_sum[3]][7:0],p_3[reg_sum[7]-reg_sum[2]][7:0],p_2[reg_sum[7]-reg_sum[1]][7:0],p_1[reg_sum[7]-reg_sum[0]][7:0],p_0[reg_sum[7]][15:0]};
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 49)    //49x82
        assign m_p_o[130:0] = {m_p[9][42:0],p_8[reg_sum[8]-reg_sum[7]][15:0],p_7[reg_sum[8]-reg_sum[6]][7:0],p_6[reg_sum[8]-reg_sum[5]][7:0],p_5[reg_sum[8]-reg_sum[4]][7:0],p_4[reg_sum[8]-reg_sum[3]][7:0],p_3[reg_sum[8]-reg_sum[2]][7:0],p_2[reg_sum[8]-reg_sum[1]][7:0],p_1[reg_sum[8]-reg_sum[0]][7:0],p_0[reg_sum[8]][15:0]};
    else if (MAX_DATA_SIZE <= 73 && MIN_DATA_SIZE <= 66)    //73x66
        assign m_p_o[138:0] = {m_p[11][42:0],p_10[reg_sum[10]-reg_sum[9]][15:0],p_9[reg_sum[10]-reg_sum[8]][7:0],p_8[reg_sum[10]-reg_sum[7]][7:0],p_7[reg_sum[10]-reg_sum[6]][7:0],p_6[reg_sum[10]-reg_sum[5]][7:0],p_4[reg_sum[10]-reg_sum[3]][7:0],p_3[reg_sum[10]-reg_sum[2]][7:0],p_2[reg_sum[10]-reg_sum[1]][7:0],p_1[reg_sum[10]-reg_sum[0]][7:0],p_0[reg_sum[10]][15:0]};
    else if (MAX_DATA_SIZE <= 82 && MIN_DATA_SIZE <= 73)    //73x82
        assign m_p_o[154:0] = {m_p[14][42:0],p_13[reg_sum[13]-reg_sum[12]][15:0],p_12[reg_sum[13]-reg_sum[11]][7:0],p_11[reg_sum[13]-reg_sum[10]][7:0],p_10[reg_sum[13]-reg_sum[9]][7:0],p_9[reg_sum[13]-reg_sum[8]][7:0],p_7[reg_sum[13]-reg_sum[6]][7:0],p_6[reg_sum[13]-reg_sum[5]][7:0],p_4[reg_sum[13]-reg_sum[3]][7:0],p_3[reg_sum[13]-reg_sum[2]][7:0],p_2[reg_sum[13]-reg_sum[1]][7:0],p_1[reg_sum[13]-reg_sum[0]][7:0],p_0[reg_sum[13]][15:0]};
end
endgenerate
//**************************************************************output reg***********************************************************
always@(posedge clk or posedge rst_async)
begin:outreg
    if (rst_async)
        m_p_o_ff <= 155'b0;
    else if (rst_sync)
        m_p_o_ff <= 155'b0;
    else if (ce)
        m_p_o_ff <= m_p_o;
end

assign p = (OUTREG_EN == 1) ? m_p_o_ff[PSIZE-1:0] : m_p_o[PSIZE-1:0];

endmodule
