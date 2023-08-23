onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/vin_clk
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_fsync
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_en
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_data
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/init_done
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_clk
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_rstn
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/vout_clk
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_fsync
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_en
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/vout_de
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/vout_data
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awaddr
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awlen
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awsize
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awburst
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_awvalid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_wdata
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_wstrb
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_wlast
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_wvalid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_wready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_bid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_araddr
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arlen
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arsize
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arburst
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arvalid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_arready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_rready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_rdata
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_rvalid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_rlast
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/axi_rid
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wreq
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_waddr
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wr_len
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wrdy
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wdone
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wdata
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wdata_req
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_cmd_en
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_cmd_addr
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_cmd_len
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_cmd_ready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/rd_cmd_done
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/read_ready
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/read_rdata
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/read_en
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/ddr_wr_bac
add wave -noupdate -expand -group fram_buf /ddr_test_top_tb/u_ddr/fram_buf/frame_wirq
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_clk
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_rstn
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_clk
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_fsync
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_en
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_data
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_bac
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wreq
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_waddr
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wr_len
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wrdy
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wdone
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wdata
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wdata_req
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/frame_wcnt
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/frame_wirq
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_fsync_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_en_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_rst
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_enable
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_rstn_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_rstn_2d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_fsync_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_fsync_2d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_fsync_3d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_rst
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/x_cnt
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/y_cnt
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/write_data
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_data_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/write_en
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wr_addr
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_pulse
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_addr
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_wdata
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_wdata_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_pulse_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_pulse_2d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_pulse_3d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_trig
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wr_req
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wr_req_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_en_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/ddr_wdata_req_1d
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/line_flag
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_frame_cnt
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/rd_cnt
add wave -noupdate -group wr_buf /ddr_test_top_tb/u_ddr/fram_buf/wr_buf/wirq_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/clk
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rstn
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_addr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_len
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_ready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_done
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_bac
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl_data
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_data_re
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_cmd_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_cmd_addr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_cmd_len
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_cmd_ready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_cmd_done
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/read_ready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/read_rdata
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/read_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awaddr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awlen
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awsize
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awburst
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_awvalid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_wdata
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_wstrb
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_wlast
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_wvalid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_wready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_bid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_bresp
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_bvalid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_bready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_araddr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arlen
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arsize
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arburst
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arvalid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_arready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rdata
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rvalid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rlast
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rid
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/axi_rresp
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_addr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_id
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_len
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_done
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ready
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_data_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_data
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_en
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_addr
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_id
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_len
add wave -noupdate -group wr_rd_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/rd_done_p
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/clk
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rstn
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_addr
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_ready
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_done
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_bac
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_ctrl_data
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_data_re
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_addr
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_id
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_data_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_data
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_ready
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_done
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_addr
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_ready
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_done
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/read_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_en
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_addr
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_id
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_done_p
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_done_1d
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_en_1d
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cnt
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/write_enable
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_trans_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_cmd_trig
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/burst_cnt
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/wr_data_re_reg
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/read_enable
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cnt
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_done_1d
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_en_1d
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_trans_len
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_cmd_trig
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/read_enable_1d
add wave -noupdate -group wr_cmd_trans /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_cmd_trans/rd_data_cnt
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/clk
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/rst_n
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_en
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_addr
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_id
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_len
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_cmd_done
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_ready
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_data_en
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_data
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/wr_bac
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awaddr
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awid
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awlen
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awsize
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awburst
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awready
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_awvalid
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wdata
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wstrb
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wlast
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wvalid
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wready
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_bid
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_bresp
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_bvalid
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_bready
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/test_wr_state
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/cmd_cnt
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/trans_len
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/burst_finish
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/write_en
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_data_cnt
add wave -noupdate -group wr_ctrl /ddr_test_top_tb/u_ddr/fram_buf/wr_rd_ctrl_top/wr_ctrl/axi_wready_1d
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {72467444410 fs} 0} {{Cursor 2} {830829178150 fs} 0} {{Cursor 3} {276558203550 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 397
configure wave -valuecolwidth 79
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {144036532080 fs}
