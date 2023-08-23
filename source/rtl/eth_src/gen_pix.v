module gen_pix(
    input  rgmii_rxc,
    input  rstn,
    input  udp_rec_data_valid/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [7:0] udp_rec_rdata/*synthesis PAP_MARK_DEBUG="1"*/,
    input  [15:0] udp_rec_data_length/*synthesis PAP_MARK_DEBUG="1"*/,

    output reg [55:0] ack_data,
    output eth_vs      ,
    output eth_de_en   ,
    output [15:0] eth_pix_data
   );
localparam VSYNC_R = 64'h56_73_5f_52_69_73_65_21;
localparam VSYNC_F = 64'h56_73_5f_46_61_6C_6C_21;
localparam HSYNC_R = 64'h48_73_5f_52_69_73_65_21;
localparam HSYNC_F = 64'h48_73_5f_46_61_6C_6C_21;

reg vsync,vsync_d1,vsync_d2;/*synthesis PAP_MARK_DEBUG="1"*/
reg hsync,hsync_d1,hsync_d2;/*synthesis PAP_MARK_DEBUG="1"*/
reg udp_rec_data_valid_d1,udp_rec_data_valid_d2,udp_rec_data_valid_d3,udp_rec_data_valid_d4;/*synthesis PAP_MARK_DEBUG="1"*/
reg [7:0] udp_rec_rdata_d1,udp_rec_rdata_d2,udp_rec_rdata_d3,udp_rec_rdata_d4;/*synthesis PAP_MARK_DEBUG="1"*/
wire v_rise,v_fall,udp_rise;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        udp_rec_data_valid_d1 <= 1'b0;
        vsync_d1 <= 0;
        vsync_d2 <= 0;
    end
    else begin
        udp_rec_data_valid_d1 <= udp_rec_data_valid;
        udp_rec_data_valid_d2 <= udp_rec_data_valid_d1;
        udp_rec_data_valid_d3 <= udp_rec_data_valid_d2;
        udp_rec_data_valid_d4 <= udp_rec_data_valid_d3;
        udp_rec_rdata_d1 <= udp_rec_rdata;
        udp_rec_rdata_d2 <= udp_rec_rdata_d1;
        udp_rec_rdata_d3 <= udp_rec_rdata_d2;
        udp_rec_rdata_d4 <= udp_rec_rdata_d3;
        vsync_d1 <= vsync;
        vsync_d2 <= vsync_d1;
    end
end
assign v_rise = ~vsync_d2 & vsync_d1;
assign v_fall = vsync_d2 & ~vsync_d1;
assign udp_rise = udp_rec_data_valid & ~udp_rec_data_valid_d1;
reg [8*8-1:0] sync_reg;/*synthesis PAP_MARK_DEBUG="1"*/ // Vs_Rise! Hs_Rise! .....
reg [15:0] serial_num,s_n_reg,last_s_n_reg;/*synthesis PAP_MARK_DEBUG="1"*/  // 0 - 480
always@(*)begin
   case(sync_reg)
       VSYNC_R: vsync <= 1;
       VSYNC_F: vsync <= 0;
       //HSYNC_R: hsync <= udp_rec_data_valid_d3;
       //VSYNC_F: hsync <= udp_rec_data_valid_d1;
   default: vsync <= vsync;
   endcase
end

always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        sync_reg <= 64'h0;
        serial_num <= 16'h0;
    end
    else if(udp_rec_data_valid & (total_data_cnt < 1470))begin
        sync_reg <= {sync_reg[55:0],udp_rec_rdata};
        serial_num <= {serial_num[7:0],udp_rec_rdata};
    end
end

always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        s_n_reg <= 16'h0;
    end
    else if(total_data_cnt == 2)begin
        s_n_reg <= serial_num;
    end
end

reg newst_line_flag;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        last_s_n_reg <= 16'h0;
        newst_line_flag <= 1'b0;
    end
    else if(data_vld_flag & total_data_cnt == 3 & udp_rec_data_length != 8)begin
        if(s_n_reg != last_s_n_reg)begin
            last_s_n_reg <= s_n_reg;
            newst_line_flag <= 1'b1;
        end
        else begin
            last_s_n_reg <= last_s_n_reg;
            newst_line_flag <= 1'b0;
        end
    end
    else if(data_vld_flag & total_data_cnt != 0) begin
        last_s_n_reg <= last_s_n_reg;
        newst_line_flag <= newst_line_flag;
    end
    else begin
        last_s_n_reg <= last_s_n_reg;
        newst_line_flag <= 0;
    end
end

always@(*) begin 
    ack_data <= {"A", "C","K", ":", s_n_reg,"\n"};
end

reg [15:0] total_data_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        total_data_cnt <= 16'h0;
    end
    else if(udp_rec_data_valid)begin
        total_data_cnt <= total_data_cnt + 1'b1;
    end
    else if(total_data_cnt == udp_rec_data_length)begin
        total_data_cnt <= 16'b0;
    end
end

reg data_vld_flag;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        data_vld_flag <= 1'b0;
    end
    else if(v_fall)begin
        data_vld_flag <= 1'b1;
    end
    else if((total_pix_cnt == 20'd691200))begin
        data_vld_flag <= 1'b0;
    end
end

wire pix_byte_vld;/*synthesis PAP_MARK_DEBUG="1"*/
assign pix_byte_vld = data_vld_flag & newst_line_flag & udp_rec_data_valid_d2;
wire [11:0] fifo_rd_water_level;/*synthesis PAP_MARK_DEBUG="1"*/
wire [7:0] sync_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
sync_fifo sync_fifo (
  .clk(rgmii_rxc),                          // input
  .rst(v_rise),                          // input
  .wr_en(pix_byte_vld),                      // input
  .wr_data(udp_rec_rdata_d2),                  // input [7:0]
  .wr_full(),                  // output
  .almost_full(),          // output
  .rd_en(sync_rd_en),                      // input
  .rd_data(sync_rd_data),                  // output [7:0]
  .rd_empty(),                // output
  .rd_water_level(fifo_rd_water_level),    // output [11:0]
  .almost_empty()         // output
);
reg sync_rd_en,sync_rd_en_d1;/*synthesis PAP_MARK_DEBUG="1"*/
reg [10:0] sync_rd_en_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        sync_rd_en <= 1'd0;
    end
    else if(fifo_rd_water_level > 1919)begin
        sync_rd_en <= 1'b1;
    end
    else if(sync_rd_en_cnt == 1919)
        sync_rd_en <= 1'b0;
end
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        sync_rd_en_cnt <= 11'd0;
    end
    else if(sync_rd_en & sync_rd_en_cnt < 1919)begin
        sync_rd_en_cnt <= sync_rd_en_cnt + 1'b1;
    end
    else if(sync_rd_en_cnt == 1919)begin
        sync_rd_en_cnt <= 11'b0;
    end
end

reg [2:0] pix_vld_limit_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        pix_vld_limit_cnt <= 3'd1;
    end
    else if(sync_rd_en_d1 & (pix_vld_limit_cnt < 3))begin
        pix_vld_limit_cnt <= pix_vld_limit_cnt + 1'b1;
    end
    else if(pix_vld_limit_cnt == 3)begin
        pix_vld_limit_cnt <= 3'd1;
    end
end
reg [23:0] pix_data;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        pix_data <= 23'd0;
    end
    else begin
        pix_data <= {pix_data[15:0], sync_rd_data};
    end
end

reg pix_vld;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        pix_vld <= 1'b0;
    end
    else if(sync_rd_en_d1 & (pix_vld_limit_cnt == 3)) begin
        pix_vld <= 1;
    end
    else pix_vld <= 0;
end

wire [15:0] pix_565;/*synthesis PAP_MARK_DEBUG="1"*/
assign pix_565 = {(pix_data[23:19]), (pix_data[15:10]), (pix_data[7:3])};
//always@(posedge rgmii_rxc)begin
//    if(~rstn)begin
//        pix_565 <= 16'b0;
//    end
//    else pix_565 <= {(pix_data[23:19]), (pix_data[15:10]), (pix_data[7:3])};
//end

wire [11:0] rd_water_level;
gen_en_fifo gen_en_fifo (
  .clk(rgmii_rxc),                          // input
  .rst(v_rise),                          // input
  .wr_en(pix_vld),                      // input
  .wr_data(pix_565),                  // input [15:0]
  .wr_full(),                  // output
  .almost_full(),          // output
  .rd_en(rd_en),                      // input
  .rd_data(rd_data),                  // output [15:0]
  .rd_empty(),                // output
  .rd_water_level(rd_water_level),    // output [11:0]
  .almost_empty(almost_empty)         // output
);

reg rd_en,rd_en_d1;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] rd_en_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
wire [15:0] rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        rd_en <= 1'd0;
    end
    else if(rd_water_level > 639)begin
        rd_en <= 1'b1;
    end
    else if(rd_en_cnt == 639)begin
        rd_en <= 1'b0;
    end
end
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        rd_en_cnt <= 10'd0;
    end
    else if(rd_en & rd_en_cnt < 639)begin
        rd_en_cnt <= rd_en_cnt + 1'b1;
    end
    else if(rd_en_cnt == 639)begin
        rd_en_cnt <= 10'b0;
    end
end

always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        rd_en_d1 <= 1'd0;
    end
    else rd_en_d1 <= rd_en;
end
always@(posedge rgmii_rxc)begin
    if(~rstn)begin
        sync_rd_en_d1 <= 1'd0;
    end
    else sync_rd_en_d1 <= sync_rd_en;
end

assign eth_vs = vsync;
assign eth_de_en = rd_en_d1;
assign eth_pix_data = rd_data;

// for hard simulation signals
reg [8:0] v_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] h_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        v_cnt <= 9'd0;
    end
    else if((h_cnt == (640 - 1)) & pix_vld)begin
        v_cnt <= v_cnt + 1'd1;
    end
end

always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        h_cnt <= 10'd0;
    end
    else if(pix_vld & (h_cnt < (640 - 1)))begin
        h_cnt <= h_cnt + 1'd1;
    end
    else if((h_cnt == (640 - 1)) & pix_vld)begin
        h_cnt <= 10'd0;
    end
    else h_cnt <= h_cnt;
end

reg [12:0] rd_en_r_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
wire rd_en_rise;
assign rd_en_rise = ~rd_en_d1 & rd_en;
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        rd_en_r_cnt <= 13'd0;
    end
    else if(rd_en_rise)begin
        rd_en_r_cnt <= rd_en_r_cnt + 1'd1;
    end
end

reg [12:0] sync_rd_en_r_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
wire sync_rd_en_rise;
assign sync_rd_en_rise = ~sync_rd_en_d1 & sync_rd_en;
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        sync_rd_en_r_cnt <= 13'd0;
    end
    else if(sync_rd_en_rise)begin
        sync_rd_en_r_cnt <= sync_rd_en_r_cnt + 1'd1;
    end
end

reg [19:0] total_pix_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
always@(posedge rgmii_rxc)begin
    if(~rstn || v_rise)begin
        total_pix_cnt <= 19'd0;
    end
    else if(pix_byte_vld)begin
        total_pix_cnt <= total_pix_cnt + 1'd1;
    end
end


endmodule