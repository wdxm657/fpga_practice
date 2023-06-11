module test_scaler #   (

    parameter VSYNC_PLUS_VBP   = 20   
	
)(
    input                           rst_n          ,			
    input                           scaler_clk     ,
		
    input                           pclk_in        ,
    input       [24 -1:0]           pix_data_in    ,
    input                           vs_in          ,
    input                           hs_in          ,
    input                           de_in          ,	

    output                          hdmi_en         ,
    input                           hdmi_clk        ,
    input                           hdmi_req        ,
    input                           hdmi_vs         ,
    output      [24         -1:0]   hdmi_data       
   );

localparam  FIFO_DEPTH  = 9     ;

wire [1:0] output_mode = 2'd01;

//scaler 
wire                          wr_ready          /* synthesis syn_keep = 1 */;
reg [ 24-1:0]                 pixel_din         /* synthesis syn_keep = 1 */;
reg                           pixel_din_vld     /* synthesis syn_keep = 1 */;
wire                          frame_start       /* synthesis syn_keep = 1 */;

wire [24-1:0]                 scaler_data_out   /* synthesis syn_keep = 1 */;
wire                          scaler_data_vld   /* synthesis syn_keep = 1 */;
wire                          scaler_rd_req     /* synthesis syn_keep = 1 */;

wire                          scaler_out_eol   /* synthesis syn_keep = 1 */;
wire                          scaler_out_eof   /* synthesis syn_keep = 1 */;


//fifo
wire                          fifo_rst          /* synthesis syn_keep = 1 */;
wire                          wr_full           /* synthesis syn_keep = 1 */;
wire                          rd_en             /* synthesis syn_keep = 1 */;
reg                           rd_en_r0          /* synthesis syn_keep = 1 */;
wire                          rd_empty          /* synthesis syn_keep = 1 */;
wire[24-1:0]                  rd_data           /* synthesis syn_keep = 1 */;


reg [11-1:0]                  de_in_cnt     /* synthesis syn_keep = 1 */;
reg                           de_in_d       /* synthesis syn_keep = 1 */;

//
wire[11-1:0]                  h_size_src    /* synthesis syn_keep = 1 */;
wire[11-1:0]                  v_size_src    /* synthesis syn_keep = 1 */;
reg [11-1:0]                  h_size_src_r0 /* synthesis syn_keep = 1 */;
reg [11-1:0]                  v_size_src_r0 /* synthesis syn_keep = 1 */;
reg [11-1:0]                  h_size_src_r1 /* synthesis syn_keep = 1 */;
reg [11-1:0]                  v_size_src_r1 /* synthesis syn_keep = 1 */;
wire                          src_eol       /* synthesis syn_keep = 1 */;
wire                          src_eof       /* synthesis syn_keep = 1 */;
reg [18-1:0]                  HOR_SCALE_DET /* synthesis syn_keep = 1 */;           
reg [18-1:0]                  VER_SCALE_DET /* synthesis syn_keep = 1 */;
reg [18-1:0]                  HOR_SCALE     /* synthesis syn_keep = 1 */;           
reg [18-1:0]                  VER_SCALE     /* synthesis syn_keep = 1 */;  

reg [11-1:0]                  output_h_size /* synthesis syn_keep = 1 */;
reg [11-1:0]                  output_v_size /* synthesis syn_keep = 1 */;
reg [2-1:0 ]                  output_mode_r0;
reg [2-1:0 ]                  output_mode_r1;

wire                          buffer_err     /* synthesis syn_keep = 1 */;   
always@(posedge scaler_clk  or  negedge rst_n)begin
		if(~rst_n)begin
			output_h_size <= 11'd1920;
			output_v_size <= 11'd1080;
		end 
		else begin
				case(output_mode)
						2'b00 : begin
											output_h_size <= 11'd1920;
											output_v_size <= 11'd1080;
										end 
										
						2'b01 : begin
											output_h_size <= 11'd1280;
											output_v_size <= 11'd720 ;
										end 
  					2'b10 : begin
											output_h_size <= 11'd640;
											output_v_size <= 11'd480 ;
										end 
										
  					2'b11 : begin
											output_h_size <= 11'd960;
											output_v_size <= 11'd540 ;
										end 
						default:begin
											output_h_size <= 11'd1920;
											output_v_size <= 11'd1080;						
						        end 
				endcase						
		end 	
end

//input detect 
src_timing_detect  u_src_timing_detect (
.clk          ( pclk_in           ),     
.rst_n        ( rst_n             ),
.vs_in        ( vs_in             ),
.de_in        ( de_in             ),
.eol          ( src_eol           ),
.eof          ( src_eof           ),
.h_size       ( h_size_src        ),
.v_size       ( v_size_src        )
);	


always@(*)begin
	case(output_h_size)
			11'd1920:begin
									case(h_size_src_r1)
											11'd1920:HOR_SCALE_DET = 32'h4000*1920/1920;
											11'd1280:HOR_SCALE_DET = 32'h4000*(1280-1 )/(1920-1) -1;
											11'd960 :HOR_SCALE_DET = 32'h4000*(960-1  )/(1920-1) -1 ;
											11'd640 :HOR_SCALE_DET = 32'h4000*(640-1  )/(1920-1) -1 ;	
											default :HOR_SCALE_DET = 32'h4000*(1280-1 )/(1920-1) -1;
									endcase 
			         end 	
							 
			11'd1280:begin
									case(h_size_src_r1)
											11'd1920:HOR_SCALE_DET = 32'h4000*(1920-1 )/(1280-1) -1;
											11'd1280:HOR_SCALE_DET = 32'h4000*1;
											11'd960 :HOR_SCALE_DET = 32'h4000*(960-1  )/(1280-1) -1 ;
											11'd640 :HOR_SCALE_DET = 32'h4000*(640-1  )/(1280-1) -1 ;	
											default :HOR_SCALE_DET = 32'h4000*(1280-1 )/(1280-1) -1;
									endcase 
							 end 
		 11'd640:begin
									case(h_size_src_r1)
											11'd1920:HOR_SCALE_DET = 32'h4000*1920/640;
											11'd1280:HOR_SCALE_DET = 32'h4000*1280/640;
											11'd960 :HOR_SCALE_DET = 32'h4000*(960-1  )/(640-1) -1 ;
											11'd640 :HOR_SCALE_DET = 32'h4000*640/640 ;		
											default :HOR_SCALE_DET = 32'h4000*(1280-1 )/(640-1) -1;
									endcase 
							 end
							 
			default:begin
									case(h_size_src_r1)
											11'd1920:HOR_SCALE_DET = 32'h4000*1920/1920;
											11'd1280:HOR_SCALE_DET = 32'h4000*(1280-1 )/(1920-1) -1;
											11'd960 :HOR_SCALE_DET = 32'h4000*(960-1  )/(1920-1) -1 ;
											11'd640 :HOR_SCALE_DET = 32'h4000*(640-1  )/(1920-1) -1 ;	
											default :HOR_SCALE_DET = 32'h4000*(1280-1 )/(1920-1) -1;
									endcase 
			        end 					 
	endcase
end 	

always@(*)begin
	case(output_v_size)
			11'd1080:begin
									case(v_size_src_r1)
											11'd1080:VER_SCALE_DET = 32'h4000*1080/1080;
											11'd720 :VER_SCALE_DET = 32'h4000*(720-1  )/(1080-1) -1;
											11'd540 :VER_SCALE_DET = 32'h4000*(540-1  )/(1080-1) -1 ;
											11'd480 :VER_SCALE_DET = 32'h4000*(480-1  )/(1080-1) -1 ;	
											default :VER_SCALE_DET = 32'h4000*(720-1  )/(1080-1) -1;
									endcase 
			         end 	
							 
			11'd720:begin
									case(v_size_src_r1)
											11'd1080:VER_SCALE_DET = 32'h4000*(1080-1 )/(720-1) -1;
											11'd720 :VER_SCALE_DET = 32'h4000*720/720;
											11'd540 :VER_SCALE_DET = 32'h4000*(540-1  )/(720-1) -1 ;
											11'd480 :VER_SCALE_DET = 32'h4000*(480-1  )/(720-1) -1 ;	
											default :VER_SCALE_DET = 32'h4000*720/720;
									endcase 
							 end 
		 11'd480:begin
									case(v_size_src_r1)
											11'd1080:VER_SCALE_DET = 32'h4000*(1080-1)/(480-1)-1;
											11'd720 :VER_SCALE_DET = 32'h4000*(720-1 )/(480-1)-1;
											11'd540 :VER_SCALE_DET = 32'h4000*(540-1  )/(480-1) -1 ;
											11'd480 :VER_SCALE_DET = 32'h4000* 480/480 ;
											default :VER_SCALE_DET = 32'h4000*(720-1 )/(480-1 ) -1;
									endcase 
							 end
							 
			default:begin
									case(v_size_src_r1)
											11'd1080:VER_SCALE_DET = 32'h4000*1080/1080;
											11'd720 :VER_SCALE_DET = 32'h4000*(720-1  )/(1080-1) -1;
											11'd540 :VER_SCALE_DET = 32'h4000*(540-1  )/(1080-1) -1 ;
											11'd480 :VER_SCALE_DET = 32'h4000*(480-1  )/(1080-1) -1 ;	
											default :VER_SCALE_DET = 32'h4000*(720-1  )/(1080-1) -1;
									endcase 
			        end 					 
	endcase
end 

always @(posedge scaler_clk or negedge rst_n) begin
    if(!rst_n)begin
			h_size_src_r0  <= 0;
			h_size_src_r1  <= 0;
			v_size_src_r0  <= 0;
			v_size_src_r1  <= 0;
		end 
		else  begin
			h_size_src_r0  <= h_size_src;
			h_size_src_r1  <= h_size_src_r0;
			v_size_src_r0  <= v_size_src;
			v_size_src_r1  <= v_size_src_r0;
		end 
end		
		
always @(posedge scaler_clk or negedge rst_n) begin
    if(!rst_n)begin
			HOR_SCALE        <= 0;
			VER_SCALE        <= 0;
		end
		else begin
			HOR_SCALE        <= HOR_SCALE_DET;
			VER_SCALE        <= VER_SCALE_DET;
		end
end 

//async clock  deal with
assign   fifo_rst  = ~rst_n || frame_start ;
assign   rd_en     = wr_ready && ~rd_empty ;

drm_fifo24to24  drm_fifo24to24_scaler_in (
  .wr_clk        (  pclk_in      ),     
  .wr_rst        (  fifo_rst     ),     
  .wr_en         (  de_in        ),     
  .wr_data       (  pix_data_in  ),     
  .wr_full       (  wr_full      ),     
  .almost_full   (               ),     
	               
  .rd_clk        (  scaler_clk  ),              
  .rd_rst        (  fifo_rst    ),              
  .rd_en         (  rd_en       ),               
  .rd_data       (  rd_data     ),             
  .rd_empty      (  rd_empty    ),      
  .almost_empty  (              )   
);   

always @(posedge scaler_clk or negedge rst_n) begin
    if(!rst_n)
				rd_en_r0 <= 0;
		else if(wr_ready)
	//		#1  pixel_din_vld <= ~rd_empty;
			#1  rd_en_r0 <= ~rd_empty;
				
end 			

always @(posedge scaler_clk or negedge rst_n) begin
    if(!rst_n)begin
				pixel_din_vld <= 0;
				pixel_din     <= 0 ;
		end 
		else begin
				pixel_din_vld <= rd_en_r0;
				pixel_din     <= rd_data;
		end 
end 		

//assign     pixel_din         = rd_data ;


//
assign     scaler_rd_req     = 1'b1     ;

//
frame_start_ctrl #(
 .VSYNC_PLUS_VBP  ( VSYNC_PLUS_VBP   ) 
) frame_start_ctrl (
.clk         ( scaler_clk  ),
.rst_n       ( rst_n       ),
.vs_in       ( vs_in       ),
.hs_in       ( hs_in       ),
.frame_start ( frame_start )
);	

//SCALE_UP parameter 
//when INPUT_H_SIZE>OUTPUT_H_SIZE ,must selet SCALE_UP == "FALSE";
//when INPUT_H_SIZE<=OUTPUT_H_SIZE,parameter SCALE_UP can select "TRUE" to save 1 multipier;
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
	
) scaler_bilinear_inst (
  .clk                 ( scaler_clk       ),
  .rst_n               ( rst_n            ),
//param             
  .INPUT_H_SIZE        ( h_size_src_r1-1   ),//input  source hor size minus 1		
  .INPUT_V_SIZE        ( v_size_src_r1-1   ),//input  source ver size minus 1                    
  .OUTPUT_H_SIZE       ( output_h_size-1   ),//output source hor size minus 1		
  .OUTPUT_V_SIZE       ( output_v_size-1   ),//output source ver size minus 1                    
  .H_SCALE_COEFF       ( HOR_SCALE         ),//hor scaler coeff		
  .V_SCALE_COEFF       ( VER_SCALE         ),//ver scaler coeff	
  .HOR_OFFSET          ( 0                 ),
  .VER_OFFSET          ( 0                 ),
//user interface  
   //write port                   
  .pixel_din           ( pixel_din        ), //pixel input 
  .pixel_din_vld       ( pixel_din_vld    ), //pixel input valid  
  .wr_ready            ( wr_ready         ), //output,write enable 
  .frame_start         ( frame_start      ), //frame sync input 
  //read port                      
  .pixel_dout          ( scaler_data_out  ), //pixel output 
  .pixel_dout_vld      ( scaler_data_vld  ), //pixel output valid 
  .read_req            ( scaler_rd_req    ), //read req                      
  .out_eol             ( scaler_out_eol   ),//output end of line  flag
  .out_eof             ( scaler_out_eof   ) //output end of frame flag
);	


endmodule