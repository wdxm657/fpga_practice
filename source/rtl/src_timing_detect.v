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
//  |____  |   \ _|  | |   Description   : video source  size  detect  
//       | |         | |                   
//       | |_________| |                  
//       |_____________|
//
//============================================================================= 
//  Revision History:
//  Date          By            Version     Revision Description
//-----------------------------------------------------------------------------
//  2020/7/20      xzliu       1.0         Initial version
//=============================================================================
module src_timing_detect (
    input                   clk         ,
    input                   rst_n       ,
    input                   vs_in       ,	
    input                   de_in       ,		
    output                  eol         ,		
    output                  eof         ,		
    output reg[11-1:0]      h_size      ,  
    output [11-1:0]         v_size        
 
);


reg [11-1:0]                   cnt_line     ;
reg [11-1:0]                   cnt_line_reg ;
reg [11-1:0]                   cnt_de       ;
reg                            vs_in_d       ;
reg                            de_in_d       ;
reg [11-1:0]                   vs_cnt_reg ;
		
		

assign   eol = 	~de_in && de_in_d;	
assign   eof = 	eol && cnt_de == vs_cnt_reg -1;	
			
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			vs_in_d <= 0;
		else 
			vs_in_d <= vs_in;
end 


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			de_in_d <= 0;
		else 
			de_in_d <= de_in;
end 


	
 	
//cnt_line
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_line <= 0;
    else if(de_in) begin
				cnt_line <= cnt_line + 1;				
    end
		else 
			  cnt_line <=0;
end

//cnt_line_reg 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_line_reg <= 0;
    else if(~de_in && de_in_d)
			  cnt_line_reg <= cnt_line;
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_de <= 0;
    else if( vs_in && ~vs_in_d)
			  cnt_de <= 0;
		else if(~de_in && de_in_d)
				cnt_de <= cnt_de + 1 ;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			vs_cnt_reg <= 0;
		else if(vs_in && ~vs_in_d)
			vs_cnt_reg <= cnt_de;
end 			

// 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
			h_size <= 0;
		else if(vs_in && ~vs_in_d)
			h_size <= cnt_line_reg;
end 			


//assign   h_size  = cnt_line_reg ;
assign   v_size  = vs_cnt_reg   ;



endmodule