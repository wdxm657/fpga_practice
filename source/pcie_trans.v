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
    input                        hdmi_vld,
    input                        hdmi_vsync,
    input    [15:0]              hdmi_565
   );

reg pcie_rdy = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg hdmi_rst = 1;/*synthesis PAP_MARK_DEBUG="1"*/

always @(posedge pcie_clk) 
begin
     if(cpu_wr_en & cpu_wr_data == {32{4'h8}}) 
         pcie_rdy <= 1;
     else 
         pcie_rdy <= pcie_rdy;
end

always @(posedge hdmi_clk) 
begin
     if(pcie_rdy & hdmi_vsync) 
         hdmi_rst <= 0;
     else 
         hdmi_rst <= hdmi_rst;
end

reg [11:0] hdmi_x_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hdmi_vsync)
        hdmi_x_cnt <= 12'd0;
    else if(hdmi_vld)
        hdmi_x_cnt <= hdmi_x_cnt + 1'b1;
    else if(hdmi_x_cnt == 1280 - 1)
        hdmi_x_cnt <= 12'd0;
end 

reg [11:0] hdmi_y_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hdmi_vsync)
        hdmi_y_cnt <= 12'd0;
    else if(hdmi_vld & hdmi_x_cnt == 1280 - 1)
        hdmi_y_cnt <= hdmi_y_cnt + 1'b1;
    else if(hdmi_y_cnt == 720 - 1)
        hdmi_y_cnt <= 12'd0;
end 

reg [15:0]                test_data;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge hdmi_clk)
begin
    if(hdmi_vsync) begin
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
wire [9:0] rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_almost_full;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_almost_empty;/*synthesis PAP_MARK_DEBUG="1"*/
wire hdmi_rd_en;/*synthesis PAP_MARK_DEBUG="1"*/
wire [127:0] hdmi_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
assign hdmi_rd_en  = hdmi_almost_full ? 0 : cpu_rd_en;
assign cpu_rd_data = hdmi_rd_en ? {8{16'hCCCC}} : hdmi_rd_data;
frame_2_pcie_fifo hdmi_fifo (
  .wr_clk            (hdmi_clk),             // input           
  .wr_rst            (hdmi_rst),             // input           
  .wr_en             (hdmi_vld),             // input           
  .wr_data           (test_data),            // input [15:0]    
  .wr_full           (hdmi_wr_full),         // output          
  .almost_full       (hdmi_almost_full),     // output [12:0]   
  .wr_water_level    (wr_water_level),       // output   
       
  .rd_clk            (pcie_clk),             // input           
  .rd_rst            (hdmi_rst),             // input           
  .rd_en             (hdmi_rd_en),           // input           
  .rd_data           (hdmi_rd_data),         // output [127:0]  
  .rd_empty          (hdmi_rd_empty),        // output          
  .almost_empty      (hdmi_almost_empty),    // output [9:0]    
  .rd_water_level    (rd_water_level)        // output          
);

endmodule