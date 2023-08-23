module pcie_trans(
    // pcie
    input                        pcie_clk,
    input                        pcie_init_done,
    input                        cpu_rd_en      /*synthesis PAP_MARK_DEBUG="1"*/,
    output [127:0]               cpu_rd_data    /*synthesis PAP_MARK_DEBUG="1"*/,
    output                       cpu_rd_vld    ,
    // cpu
    input                        cpu_wr_en        /*synthesis PAP_MARK_DEBUG="1"*/,
    input  [127:0]               cpu_wr_data      /*synthesis PAP_MARK_DEBUG="1"*/,

    input                        hdmi_clk,
    input                        hdmi_vld        /*synthesis PAP_MARK_DEBUG="1"*/,      
    input                        hdmi_hsync      /*synthesis PAP_MARK_DEBUG="1"*/,    
    input                        hdmi_vsync,
    input    [15:0]              hdmi_565
   );

reg hdmi_vsync_d1 = 0;/*synthesis PAP_MARK_DEBUG="1"*/
wire wr_rst;
always @(posedge hdmi_clk)
begin
    hdmi_vsync_d1 <= hdmi_vsync;
end 

wire hs_rst;/*synthesis PAP_MARK_DEBUG="1"*/
reg hdmi_hsync_d1 = 0;
always @(posedge hdmi_clk)
begin
    hdmi_hsync_d1 <= hdmi_hsync;
end 

wire cpu_rd_rise;/*synthesis PAP_MARK_DEBUG="1"*/
wire cpu_rd_fall;/*synthesis PAP_MARK_DEBUG="1"*/
reg cpu_rd_en_d1 = 0;
reg cpu_rd_en_d2 = 0;
always @(posedge pcie_clk)
begin
    cpu_rd_en_d1 <= cpu_rd_en;
    cpu_rd_en_d2 <= cpu_rd_en_d1;
end 
assign cpu_rd_vld = cpu_rd_en_d1;
assign wr_rst      = (~hdmi_vsync_d1 & hdmi_vsync);
assign hs_rst      = (~hdmi_hsync_d1 & hdmi_hsync);
assign cpu_rd_rise = (~cpu_rd_en_d1 & cpu_rd_en);
assign cpu_rd_fall = (cpu_rd_en_d1 & ~cpu_rd_en);

reg [11:0] hdmi_x_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hs_rst)
        hdmi_x_cnt <= 12'd0;
    else if(hdmi_vld)
        hdmi_x_cnt <= hdmi_x_cnt + 1'b1;
    else hdmi_x_cnt <= 12'd0;
end 
reg [11:0] hdmi_y_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)
        hdmi_y_cnt <= 12'd0;
    else if(hdmi_vld & hdmi_x_cnt == 1280 - 1 & hdmi_y_cnt < 720 - 1)
        hdmi_y_cnt <= hdmi_y_cnt + 1'b1;
    else if(hdmi_y_cnt == 720 - 1 & hdmi_x_cnt == 1280 - 1)
        hdmi_y_cnt <= 12'd0;
end 

reg [19:0] hdmi_total_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)
        hdmi_total_cnt <= 19'd0;
    else if(hdmi_vld)
        hdmi_total_cnt <= hdmi_total_cnt + 1'b1;
end 

wire hdmi_wr_trig;/*synthesis PAP_MARK_DEBUG="1"*/
reg [2:0] hdmi_wr_trig_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)begin
        hdmi_wr_trig_cnt <= 0;
    end
    else if(hdmi_vld & hdmi_wr_trig_cnt < 5)begin
        hdmi_wr_trig_cnt <= hdmi_wr_trig_cnt + 1'b1;
    end
    else if(hdmi_vld & hdmi_wr_trig_cnt ==  5) begin
        hdmi_wr_trig_cnt <= 0;
    end
    else begin
        hdmi_wr_trig_cnt <= hdmi_wr_trig_cnt;
    end
end
assign hdmi_wr_trig = hdmi_wr_trig_cnt == 5 ? 1 : 0;

reg hdmi_wr_trig_d1 = 0;
always @(posedge hdmi_clk)
begin
    if(wr_rst)begin
        hdmi_wr_trig_d1 <= 0;
    end
    else begin
        hdmi_wr_trig_d1 <= hdmi_wr_trig;
    end
end

reg [15:0] hdmi_565_d1,hdmi_565_d2,hdmi_565_d3,hdmi_565_d4,hdmi_565_d5;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)begin
        hdmi_565_d1 <= 0;
        hdmi_565_d2 <= 0;
        hdmi_565_d3 <= 0;
        hdmi_565_d4 <= 0;
        hdmi_565_d5 <= 0;
    end
    else begin
        //hdmi_565_d1 <= test_data;
        hdmi_565_d1 <= hdmi_565;
        hdmi_565_d2 <= hdmi_565_d1;
        hdmi_565_d3 <= hdmi_565_d2;
        hdmi_565_d4 <= hdmi_565_d3;
        hdmi_565_d5 <= hdmi_565_d4;
    end
end

reg [127:0] hdmi_wr_shift;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)begin
        hdmi_wr_shift <= 128'b0;
    end
//    else if(hdmi_wr_trig & hdmi_x_cnt == 5 & hdmi_y_cnt == 0)begin
//        hdmi_wr_shift <= {4'b0000,8'b0, hdmi_total_cnt, hdmi_565_d5, hdmi_565_d4, hdmi_565_d3, hdmi_565_d2, hdmi_565_d1, test_data};
//    end
    else if(hdmi_wr_trig)begin
        hdmi_wr_shift <= {hdmi_565_d5, hdmi_565_d4, hdmi_565_d3, hdmi_565_d2, hdmi_565_d1, hdmi_565, 4'b0000,8'b0, hdmi_total_cnt};
    end
    else
        hdmi_wr_shift <= 128'b0;
end

reg [15:0]                test_data=0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge hdmi_clk)
begin
    if(wr_rst) begin
        test_data <= 16'b0;
    end
    else if(hdmi_vld)begin
            test_data <= test_data + 1'b1;
    end
    else test_data <= test_data;
end
//always@(posedge hdmi_clk)
//begin
//    if(hdmi_vld) begin
//        if(hdmi_x_cnt < 640)begin
//            test_data <= test_data + 1'b1;
//        end
//        else begin
//            if(hdmi_y_cnt < 240) begin
//                test_data <= 16'h001F;        //blue  
//            end
//            else if(hdmi_y_cnt < 480) begin
//                test_data <= 16'h0400;        //green
//            end
//            else begin
//                test_data <= 16'hF800;        //red  
//            end
//        end
//    end
//    else test_data <= 16'b0;
//end

reg [5:0] dw_total = 0;
always@(posedge pcie_clk)
begin
    if(cpu_wr_en)begin
        dw_total <= cpu_wr_data[5:0];
    end
end

reg [8:0] cpu_rd_cnt = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge pcie_clk)
begin
    if(cpu_rd_en & cpu_rd_cnt < 255)begin
        cpu_rd_cnt <= cpu_rd_cnt + 1;
    end
    else if(cpu_rd_cnt == 255)
        cpu_rd_cnt <= 0;
    else begin
        cpu_rd_cnt <= cpu_rd_cnt;
    end
end

wire cpu_en_merge,cpu_en_merge_rise;/*synthesis PAP_MARK_DEBUG="1"*/
reg cpu_en_merge_d1=0;/*synthesis PAP_MARK_DEBUG="1"*/
assign cpu_en_merge = (cpu_rd_cnt >  0 & cpu_rd_cnt < 255) ? 1 : 0;

always@(posedge pcie_clk)
begin
    cpu_en_merge_d1 <= cpu_en_merge;
end
assign cpu_en_merge_rise      = (~cpu_en_merge_d1 & cpu_en_merge);

reg [31:0] cpu_en_merge_cnt = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge pcie_clk)
begin
    if(wr_rst) cpu_en_merge_cnt <= 0;
    else if(cpu_en_merge_rise)
        cpu_en_merge_cnt <= cpu_en_merge_cnt + 1'b1;
    else cpu_en_merge_cnt <= cpu_en_merge_cnt;
end

reg [31:0] total_cnt = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge pcie_clk)
begin
    if(wr_rst) total_cnt <= 0;
    else if(hdmi_rd_en)
        total_cnt <= total_cnt + 6;
    else total_cnt <= total_cnt;
end

assign hdmi_rd_en  = ~hdmi_rd_empty ? cpu_rd_en : 0;
assign data_to_cpu = ~hdmi_rd_empty ? hdmi_rd_data : 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

wire [127:0] data_to_cpu;/*synthesis PAP_MARK_DEBUG="1"*/
assign cpu_rd_data = endian_convert(data_to_cpu);
//convert from little endian into big endian
function [127:0] endian_convert;
    input [127:0] data_in;
    begin
        endian_convert[32*0+31:32*0+0] = {data_in[32*0+7:32*0+0], data_in[32*0+15:32*0+8], data_in[32*0+23:32*0+16], data_in[32*0+31:32*0+24]};
        endian_convert[32*1+31:32*1+0] = {data_in[32*1+7:32*1+0], data_in[32*1+15:32*1+8], data_in[32*1+23:32*1+16], data_in[32*1+31:32*1+24]};
        endian_convert[32*2+31:32*2+0] = {data_in[32*2+7:32*2+0], data_in[32*2+15:32*2+8], data_in[32*2+23:32*2+16], data_in[32*2+31:32*2+24]};
        endian_convert[32*3+31:32*3+0] = {data_in[32*3+7:32*3+0], data_in[32*3+15:32*3+8], data_in[32*3+23:32*3+16], data_in[32*3+31:32*3+24]};
    end
endfunction

wire [127:0] hdmi_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_rd_en;/*synthesis PAP_MARK_DEBUG="1"*/
wire [12:0]wr_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire [12:0]rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_wr_full;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_rd_empty;/*synthesis PAP_MARK_DEBUG="1"*/

reg rst=1;
always@(posedge pcie_clk)
begin
    if(cpu_rd_en & pcie_init_done) rst <= 0;
end
frame_2_pcie_fifo hdmi_fifo (
// 12'b0 + 20'btotal_cbt + 16 pix * 6
  .wr_clk            (hdmi_clk),             // input           34Mhz 
  .wr_rst            (rst),               // input           
  .wr_en             (hdmi_wr_trig_d1),             // input           
  .wr_data           (hdmi_wr_shift),            // input [127:0]    
  .wr_full           (hdmi_wr_full),         // output          
  .almost_full       (hdmi_almost_full),     // output [11:0]   
  .wr_water_level    (wr_water_level),       // output   
       
// 1CLK 128'b 
  .rd_clk            (pcie_clk),             // input           100Mhz
  .rd_rst            (rst),      // input           
  .rd_en             (hdmi_rd_en),            // input           
  .rd_data           (hdmi_rd_data),         // output [127:0]  
  .rd_empty          (hdmi_rd_empty),        // output          
  .almost_empty      (hdmi_almost_empty),    // output [11:0]    
  .rd_water_level    (rd_water_level)        // output          
);

endmodule