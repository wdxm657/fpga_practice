//  ALL RIGHTS RESERVED.
// 
//  THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
//  IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
//  PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//=============================================================================
//   _____________
//  |  _________  |
//  | |         | |         
//  | |   _     | |____    
//  | |  |  \   |  __  |   Author        : xzliu
//  | |  |  _\ _| |  | |   IDE Version   : 
//  | |__| |  \   |  | |   Device Part   : 
//  |____  |   \ _|  | |   Description   : generate  frame start  signal from  BLANK  
//       | |         | |                   
//       | |_________| |                  
//       |_____________|
//
//============================================================================= 
//  Revision History:
//  Date          By            Version     Revision Description
//-----------------------------------------------------------------------------
//  2020/7/3      xzliu       1.0         Initial version
//=============================================================================
module frame_start_ctrl #(	
    parameter VSYNC_PLUS_VBP          = 20            	
	
)(
    input                   clk         ,
    input                   rst_n       ,
    input                   vs_in       ,	
    input                   hs_in       ,		
    output                  frame_start  
 
);


reg [9-1:0]                   cnt_hs     ;
wire                          add_cnt_hs ;
wire                          end_cnt_hs ;
reg                           add_hs_flag;

reg [2:0]                     vs_in_d    ;
reg [2:0]                     hs_in_d    ;

reg [1:0]                     vs_cnt     ;

localparam                    FRAME_NUM =2 ;

		
			
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			vs_in_d <= 0;
		else 
			vs_in_d <= {vs_in_d[1:0],vs_in};
end 


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			hs_in_d <= 0;
		else 
			hs_in_d <= {hs_in_d[1:0],hs_in};
end 

		

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			vs_cnt <= 0;
		else if(vs_cnt == FRAME_NUM)
			vs_cnt <= vs_cnt ;
		else if(vs_in_d[1] && ~vs_in_d[2])
			vs_cnt <= vs_cnt + 1;
end 			



			
//add_hs_flag
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
				add_hs_flag <= 0;
		else if(vs_in_d[1] && ~vs_in_d[2])
				add_hs_flag <= 1;
		else if(end_cnt_hs)
				add_hs_flag <= 0;
end 				
			
			

//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_hs <= 0;
    else if(add_cnt_hs) begin
        if(end_cnt_hs)
            cnt_hs <= 0;
        else
            cnt_hs <= cnt_hs+1;
    end
end
assign add_cnt_hs = add_hs_flag &&  hs_in_d[2] && ~hs_in_d[1] ;
assign end_cnt_hs = add_cnt_hs && cnt_hs == VSYNC_PLUS_VBP-1;

//assign  frame_start  = end_cnt_hs ;
//assign  frame_start  = cnt_hs == VSYNC_PLUS_VBP-1 && hs_in_d[2]; //hs 宽度
assign  frame_start  = cnt_hs == VSYNC_PLUS_VBP-1 && hs_in_d[2] && vs_cnt == FRAME_NUM; //从第二帧开始 ，第一帧,第二帧还在计算输入的分辨率


endmodule