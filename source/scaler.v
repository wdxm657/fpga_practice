module scaler #(
   parameter H = 1920,
   parameter V = 1080,
   parameter H_SCALE = 960,
   parameter V_SCALE = 540
)(
   input clk,
   input rst_n,
   input vs_in,
   input de_in,
   input [23:0] data_in, 

   output [23:0] scaler_data_out,/*synthesis PAP_MARK_DEBUG="1"*/
   output scaler_data_vld /*synthesis PAP_MARK_DEBUG="1"*/
   );

wire                          fifo_rst          ;/*synthesis PAP_MARK_DEBUG="1"*/
wire                          rd_en             ;/*synthesis PAP_MARK_DEBUG="1"*/
reg                           rd_en_r0          ;/*synthesis PAP_MARK_DEBUG="1"*/
wire                          rd_empty          ;/*synthesis PAP_MARK_DEBUG="1"*/
wire[16-1:0]                  rd_data           ;/*synthesis PAP_MARK_DEBUG="1"*/
assign   rd_en     = wr_ready && ~rd_empty ;
assign   fifo_rst  = ~rst_n || vs_in ;
wire [15:0] in_565;
assign in_565 = {(data_in[23:19]), (data_in[15:10]), (data_in[7:3])};
drm_fifo24to24  drm_fifo24to24_scaler_in (
  .wr_clk        (  clk      ),     
  .wr_rst        (  fifo_rst     ),     
  .wr_en         (  de_in        ),     
  .wr_data       (  in_565  ),     
  .wr_full       (        ),     
  .almost_full   (               ),     
	               
  .rd_clk        (  clk  ),              
  .rd_rst        (  fifo_rst    ),              
  .rd_en         (  rd_en  ),               
  .rd_data       (  rd_data     ),             
  .rd_empty      (  rd_empty    ),      
  .almost_empty  (              )   
);
wire [23:0] out_888;
assign out_888 = {rd_data[15:11],rd_data[15:13],rd_data[10:5],rd_data[10:9],rd_data[4:0],rd_data[4:2]};
reg [ 24-1:0]                 pixel_din         ;/*synthesis PAP_MARK_DEBUG="1"*/
reg                           pixel_din_vld     ;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
				rd_en_r0 <= 0;
		else if(wr_ready)
			#1  rd_en_r0 <= ~rd_empty;
				
end 			

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
				pixel_din_vld <= 0;
				pixel_din     <= 0 ;
		end 
		else begin
				pixel_din_vld <= rd_en_r0;
				pixel_din     <= out_888;
		end 
end 	

localparam H_SCALE_COEFF = 32'h4000 * (H) / (H_SCALE)-1;
localparam V_SCALE_COEFF = 32'h4000 * (V) / (V_SCALE)-1;

scaler_bilinear #(
  .DEVICE_FAMILY       ( "LOGOS"   ),// "LOGOS","LOGOS2"
  .SCALE_UP            ( "FALSE"   ),
  .DATA_WIDTH          ( 8         ),//1 color channel 8bit 
  .LANES               ( 3         ),//R,G,B 
  .INPUT_H_SIZE_WIDTH  ( 11        ),//0~2047
  .INPUT_V_SIZE_WIDTH  ( 11        ),//0~2047
  .OUTPUT_H_SIZE_WIDTH ( 11        ),//0~2047
  .OUTPUT_V_SIZE_WIDTH ( 11        ),//0~2047
  .BUFF_LINE           ( 4         ) //BUFF_LINE:INPUT_V_SIZE>=OUTPUT_V_SIZE,need >=4line,otherwise need >=3line  
) hdmi_scaler_bilinear_inst (
  .clk                 ( clk       ),
  .rst_n               ( rst_n            ),
//param              
  .INPUT_H_SIZE        ( H-1   ),//input  source hor size minus 1		
  .INPUT_V_SIZE        ( V-1   ),//input  source ver size minus 1                    
  .OUTPUT_H_SIZE       ( H_SCALE-1   ),//output source hor size minus 1		
  .OUTPUT_V_SIZE       ( V_SCALE-1   ),//output source ver size minus 1                    
  .H_SCALE_COEFF       ( H_SCALE_COEFF         ),//hor scaler coeff		
  .V_SCALE_COEFF       ( V_SCALE_COEFF         ),//ver scaler coeff	
  .HOR_OFFSET          ( 0                 ),
  .VER_OFFSET          ( 0                 ),
//user interface  
   //write port                   
  .pixel_din           ( pixel_din        ), //pixel input 
  .pixel_din_vld       ( pixel_din_vld    ), //pixel input valid  
  .wr_ready            ( wr_ready         ), //output,write enable 
  .frame_start         ( vs_in      ), //frame sync input 
  //read port                      
  .pixel_dout          ( scaler_data_out  ), //pixel output 
  .pixel_dout_vld      ( scaler_data_vld  ), //pixel output valid 
  .read_req            ( 1    ), //read req                      
  .out_eol             ( /*scaler_out_eol*/   ),//output end of line  flag
  .out_eof             ( /*scaler_out_eof*/   ) //output end of frame flag
);	
endmodule