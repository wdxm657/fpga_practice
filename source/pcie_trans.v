module pcie_trans(
    // pcie
    input                        pcie_clk,
    input                        pcie_init_done,
    input                        cpu_rd_en      /*synthesis PAP_MARK_DEBUG="1"*/,
    output reg [127:0]               cpu_rd_data    /*synthesis PAP_MARK_DEBUG="1"*/,
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

assign wr_rst = (~hdmi_vsync_d1 & hdmi_vsync);

reg [11:0] hdmi_x_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(wr_rst)
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
wire [127:0] hdmi_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
reg hdmi_rd_en = 0;

reg [31:0] cnt = 0;/*synthesis PAP_MARK_DEBUG="1"*/
reg sel = 0;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge pcie_clk)
begin
    if(cpu_rd_en)begin
        if(sel == 0 & wr_water_level > 1278) begin
            hdmi_rd_en <= 0;
            cpu_rd_data <= 128'hA;
            sel <= 1;
            cnt <= 0;
        end
        else if(sel == 1) begin
            cnt <= cnt + 1'b1;
            hdmi_rd_en <= cpu_rd_en;
            cpu_rd_data <= hdmi_rd_data;
            if (cnt == 640 - 1) begin
                sel <= 0;
                cnt <= 0;
            end
        end
        else begin
            hdmi_rd_en <= 0;
            cpu_rd_data <= 0;
            sel <= 0;
            cnt <= 0;
        end
    end
end

// hs hb    vsync 

frame_2_pcie_fifo hdmi_fifo (
// 16 pix
  .wr_clk            (hdmi_clk),             // input           34Mhz 
  .wr_rst            (wr_rst),               // input           
  .wr_en             (hdmi_vld),             // input           
  .wr_data           (test_data),            // input [15:0]    
  .wr_full           (hdmi_wr_full),         // output          
  .almost_full       (hdmi_almost_full),     // output [12:0]   
  .wr_water_level    (wr_water_level),       // output   
       
// 1CLK 128wei    16pix     640DW 
  .rd_clk            (pcie_clk),             // input           100Mhz
  .rd_rst            (~pcie_init_done),      // input           
  .rd_en             (hdmi_rd_en),            // input           
  .rd_data           (hdmi_rd_data),         // output [127:0]  
  .rd_empty          (hdmi_rd_empty),        // output          
  .almost_empty      (hdmi_almost_empty),    // output [9:0]    
  .rd_water_level    (rd_water_level)        // output          
);

endmodule