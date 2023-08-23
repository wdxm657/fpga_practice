module testt #(
    parameter                     FRAME_CNT_WIDTH = 3'd6,
    parameter                     LINE_ADDR_WIDTH = 3'd22,
    parameter                     OFFSET = 19'd0
)(
    input ddr_clk,
    input wr_fsync,
    input ddr_rstn,
    input rd_pulse,
    input [255:0]  hdmi_rd_wdata,
    input ddr_wdata_req,
    input ddr_wdone,

    output ddr_wreq,
    output      ddr_rd_en,
    output     reg [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt=0,
    output     reg [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt=0,
    output     [255:0] rd_wdata
   );
    reg  ddr_wdata_req_1d;
    reg      rd_fsync_1d,rd_fsync_2d,rd_fsync_3d;
    wire     rd_rst;
    always @(posedge ddr_clk)
    begin
        rd_fsync_1d <= wr_fsync;
        rd_fsync_2d <= rd_fsync_1d;
        rd_fsync_3d <= rd_fsync_2d;
    end 
    
    assign rd_rst = (~rd_fsync_3d && rd_fsync_2d) | (~ddr_rstn);
    reg rd_pulse_1d,rd_pulse_2d,rd_pulse_3d;
    always @(posedge ddr_clk)
    begin 
        rd_pulse_1d <= rd_pulse;
        rd_pulse_2d <= rd_pulse_1d;
    end 
    
    wire rd_trig;
    assign rd_trig = ~rd_pulse_2d && rd_pulse_1d;
    
    reg ddr_wr_req=0;
    reg ddr_wr_req_1d;
    assign ddr_wreq = ddr_wr_req;
    
    always @(posedge ddr_clk)
    begin 
        ddr_wr_req_1d <= ddr_wr_req;
        if(rd_trig)
            ddr_wr_req <= 1'b1;
        else if(ddr_wdata_req)
            ddr_wr_req <= 1'b0;
        else
            ddr_wr_req <= ddr_wr_req;
    end 
    
    reg  rd_en_1d;
    always @(posedge ddr_clk)
    begin
        ddr_wdata_req_1d <= ddr_wdata_req;
        rd_en_1d <= ~ddr_wr_req_1d & ddr_wr_req;
    end 
    
    reg line_flag=0;
    always@(posedge ddr_clk)
    begin
        if(rd_rst)
            line_flag <= 1'b0;
        else if(rd_trig)
            line_flag <= 1'b1;
        else
            line_flag <= line_flag;
    end
    
    assign ddr_rd_en = (~ddr_wr_req_1d & ddr_wr_req) | ddr_wdata_req;

    reg [255:0] rd_wdata_1d;
    always @(posedge ddr_clk)
    begin
        if(ddr_wdata_req_1d | rd_en_1d)
            rd_wdata_1d <= hdmi_rd_wdata;
        else 
            rd_wdata_1d <= rd_wdata_1d;
    end 
    
    always @(posedge ddr_clk)
    begin 
        if(~ddr_rstn)
            rd_frame_cnt <= 'd0;
        else if(~rd_fsync_3d && rd_fsync_2d)
            rd_frame_cnt <= rd_frame_cnt + 1'b1;
        else
            rd_frame_cnt <= rd_frame_cnt;
    end 

    always @(posedge ddr_clk)
    begin 
        if(rd_rst)
            rd_cnt <= OFFSET;
        else if(ddr_wdone)
            rd_cnt <= rd_cnt + 640; // 960 | 480
        else
            rd_cnt <= rd_cnt;
    end 
    assign rd_wdata = ~ddr_wdata_req_1d   & ddr_wdata_req ? rd_wdata_1d : hdmi_rd_wdata;

endmodule