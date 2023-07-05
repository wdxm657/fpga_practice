module pcie_trans(
    // pcie
    input                        pcie_clk,
    input                        pcie_init_done,
    input                        cpu_rd_en      /*synthesis PAP_MARK_DEBUG="1"*/,
    output [127:0]               cpu_rd_data    /*synthesis PAP_MARK_DEBUG="1"*/,
    // cpu
    input                        cpu_wr_en        /*synthesis PAP_MARK_DEBUG="1"*/,
    input  [127:0]               cpu_wr_data      /*synthesis PAP_MARK_DEBUG="1"*/,

    input                        hdmi_clk,
    input                        hdmi_vld        /*synthesis PAP_MARK_DEBUG="1"*/,      
    input                        hdmi_hsync      /*synthesis PAP_MARK_DEBUG="1"*/,    
    input                        hdmi_vsync,
    input    [15:0]              hdmi_565
   );

reg hdmi_vsync_d1 = 0;
wire wr_rst;
always @(posedge hdmi_clk)
begin
    hdmi_vsync_d1 <= hdmi_vsync;
end 

wire hs_rst;
reg hdmi_hsync_d1 = 0;
always @(posedge hdmi_clk)
begin
    hdmi_hsync_d1 <= hdmi_hsync;
end 

assign wr_rst = (~hdmi_vsync_d1 & hdmi_vsync);
assign hs_rst = (~hdmi_hsync_d1 & hdmi_hsync);

reg [11:0] hdmi_x_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hs_rst)
        hdmi_x_cnt <= 12'd0;
    else if(hdmi_vld)
        hdmi_x_cnt <= hdmi_x_cnt + 1'b1;
end 

reg [11:0] hdmi_y_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)
        hdmi_y_cnt <= 12'd0;
    else if(hdmi_vld & hdmi_x_cnt == 1280 - 1)
        hdmi_y_cnt <= hdmi_y_cnt + 1'b1;
    else if(hdmi_y_cnt == 720 - 1)
        hdmi_y_cnt <= 12'd0;
end 

reg [15:0]                test_data;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge hdmi_clk)
begin
    if(wr_rst) begin
        test_data <= 16'b0;
    end
    else if(hdmi_vld) begin
        if(hdmi_x_cnt < 319)begin
            test_data <= 16'h0000;
        end
        else if(hdmi_x_cnt < 639)begin
            test_data <= 16'hF800;        //red    
        end
        else if(hdmi_x_cnt < 959)begin
            test_data <= 16'h0400;        //green
        end
        else begin
            test_data <= 16'h001F;        //blue  
        end
    end
    else test_data <= 16'b0;
end

wire [12:0]wr_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire [9:0]rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire [127:0] hdmi_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
reg hdmi_rd_en = 0;

reg [31:0] cnt = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg [127:0] data_to_cpu=128'hF800F801F802F803F804F805F806F807;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge pcie_clk)
begin
    if(cpu_rd_en)begin
        if(rd_water_level > 158) begin
            hdmi_rd_en <= cpu_rd_en;
            // data_to_cpu <= hdmi_rd_data;
        end
        else if(data_to_cpu == 160 - 1)begin
            data_to_cpu <= 0;
        end
        else data_to_cpu <= data_to_cpu + 1'b1;
    end
    else begin
        hdmi_rd_en <= 0;
        data_to_cpu <= data_to_cpu;
    end
end

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

// hs hb    vsync 

frame_2_pcie_fifo hdmi_fifo (
// 16 pix
  .wr_clk            (hdmi_clk),             // input           34Mhz 
  .wr_rst            (hs_rst),               // input           
  .wr_en             (hdmi_vld),             // input           
  .wr_data           (test_data),            // input [15:0]    
  .wr_full           (hdmi_wr_full),         // output          
  .almost_full       (hdmi_almost_full),     // output [12:0]   
  .wr_water_level    (wr_water_level),       // output   
       
// 1CLK 128wei    16pix     640DW 
  .rd_clk            (pcie_clk),             // input           100Mhz
  .rd_rst            (hs_rst),      // input           
  .rd_en             (hdmi_rd_en),            // input           
  .rd_data           (hdmi_rd_data),         // output [127:0]  
  .rd_empty          (hdmi_rd_empty),        // output          
  .almost_empty      (hdmi_almost_empty),    // output [9:0]    
  .rd_water_level    (rd_water_level)        // output          
);

endmodule