module test #(
    parameter PIX_WIDTH = 16,
    parameter H_NUM = 960,
    parameter V_NUM = 540
) (
    input wr_clk,
    input wr_fsync,
    input wr_en,
    input ddr_rstn,
    input [PIX_WIDTH-1:0] wr_data,
    input ddr_wdone,
    output reg ddr_rstn_2d,
    output  ddr_frame_done,
    output rd_pulse,
    output     reg [11:0]                 wr_addr=0,
    output     reg                        write_en,
    output     reg [31 : 0]  write_data
   );

    //===========================================================================
    reg       wr_fsync_1d;
    reg       wr_en_1d;
    reg       wr_enable=0;
    
    reg       ddr_rstn_1d;
    
    always @(posedge wr_clk)
    begin
        wr_fsync_1d <= wr_fsync;
        wr_en_1d <= wr_en;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
        
        if(~wr_fsync_1d & wr_fsync && ddr_rstn_2d) 
            wr_enable <= 1'b1;
        else 
            wr_enable <= wr_enable;
    end 
    
    assign wr_rst = (~wr_fsync_1d & wr_fsync) | (~ddr_rstn_2d);

    //===========================================================================
    // wr_addr control
    reg [11:0]                 x_cnt;
    reg [11:0]                 y_cnt;
    reg [PIX_WIDTH- 1'b1 : 0]  wr_data_1d;
    
    begin
        always @(posedge wr_clk)
        begin
            wr_data_1d <= wr_data;
            
            write_en <= x_cnt[0];
            if(x_cnt[0])
                write_data <= {wr_data,wr_data_1d};
            else
                write_data <= write_data;
        end
    end


    always @(posedge wr_clk)
    begin
        if(wr_rst)
            wr_addr <= 12'd0;
        else
        begin
            if(write_en & wr_enable)
                wr_addr <= wr_addr + 12'd1;
            else
                wr_addr <= wr_addr;
        end 
    end

    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            x_cnt <= 12'd0;
        // data in valid, x++
        else if(wr_en & wr_enable)
            x_cnt <= x_cnt + 1'b1;
        else
            x_cnt <= 12'd0;
    end 
    
    assign ddr_frame_done = (y_cnt == V_NUM - 1) & ddr_wdone;
    always @(posedge wr_clk)
    begin 
        if(wr_rst)
            y_cnt <= 12'd0;
        // data in pos, y++
        else if(~wr_en_1d & wr_en & wr_enable)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end 
    
    reg rd_pulse;
    always @(posedge wr_clk)
    begin
        if(x_cnt > H_NUM - 5'd20  & wr_enable)
            rd_pulse <= 1'b1;
        else
            rd_pulse <= 1'b0; 
    end 
endmodule