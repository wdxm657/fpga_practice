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
    input    [15:0]              hdmi_565,
    
    input                        ov_clk,
    input                        ov_vld,
    input                        ov_vsync,
    input    [15:0]              ov_565
   );

reg hdmi_rst = 1;/*synthesis PAP_MARK_DEBUG="1"*/
reg ov_rst   = 1;/*synthesis PAP_MARK_DEBUG="1"*/

always @(posedge pcie_clk) 
begin
     if(cpu_wr_en) begin
        case (cpu_wr_data)
            {32{4'hA}}: begin
                            hdmi_rst <= 0;
                            ov_rst   <= 1;
                        end
            {32{4'hB}}: begin
                            hdmi_rst <= 1;
                            ov_rst   <= 0;
                        end
            default: begin
                hdmi_rst <= hdmi_rst;
                ov_rst   <= ov_rst;
            end
        endcase
     end
end

reg [11:0] hdmi_x_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hdmi_rst)
        hdmi_x_cnt <= 12'd0;
    else if(hdmi_vld)
        hdmi_x_cnt <= hdmi_x_cnt + 1'b1;
    else if(hdmi_x_cnt == 960 - 1)
        hdmi_x_cnt <= 12'd0;
end 

reg [11:0] hdmi_y_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always @(posedge hdmi_clk)
begin
    if(hdmi_rst)
        hdmi_y_cnt <= 12'd0;
    else if(hdmi_vld & hdmi_x_cnt == 960 - 1)
        hdmi_y_cnt <= hdmi_y_cnt + 1'b1;
    else if(hdmi_y_cnt == 540 - 1)
        hdmi_y_cnt <= 12'd0;
end 

reg [15:0]                test_data;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge hdmi_clk)
begin
    if(hdmi_rst) begin
        test_data <= 16'b0;
    end
    else if(hdmi_vld) begin
        if(hdmi_x_cnt < 239)begin
            test_data <= 16'h0000;
        end
        else if(hdmi_x_cnt < 479)begin
            test_data <= 16'hF81F;        //Æ·ºì    
        end
        else if(hdmi_x_cnt < 719)begin
            test_data <= 16'h07E07BE0;    //éÏé­ÂÌ      
        end
        else begin
            test_data <= 16'h000F;        //ÉîÀ¶É«  
        end
    end
    else test_data <= 16'b0;
end

//wire [12:0]wr_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
//wire [9:0] rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
//wire hdmi_almost_full;/*synthesis PAP_MARK_DEBUG="1"*/
//wire hdmi_almost_empty;/*synthesis PAP_MARK_DEBUG="1"*/
//wire hdmi_rd_en;/*synthesis PAP_MARK_DEBUG="1"*/
//wire [127:0] hdmi_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
//assign hdmi_rd_en  = hdmi_almost_empty ? 0 : cpu_rd_en;
//assign cpu_rd_data = hdmi_almost_empty ? {8{16'hCCCC}} : hdmi_rd_data;
//frame_2_pcie_fifo hdmi_fifo (
//  .wr_clk            (hdmi_clk),     
//  .wr_rst            (hdmi_rst),     
//  .wr_en             (hdmi_vld),     
//  .wr_data           (test_data),    
//  .wr_full           (hdmi_wr_full),      
//  .almost_full       (hdmi_almost_full),  
//  .wr_water_level    (wr_water_level),   
//
//  .rd_clk            (pcie_clk),     
//  .rd_rst            (hdmi_rst),     
//  .rd_en             (hdmi_rd_en),    
//  .rd_data           (hdmi_rd_data),  
//  .rd_empty          (hdmi_rd_empty),     
//  .almost_empty      (hdmi_almost_empty),
//  .rd_water_level    (rd_water_level)
//);

endmodule