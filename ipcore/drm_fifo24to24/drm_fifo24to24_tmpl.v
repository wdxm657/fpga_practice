// Created by IP Generator (Version 2022.1 build 99559)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


drm_fifo24to24 the_instance_name (
  .wr_clk(wr_clk),                // input
  .wr_rst(wr_rst),                // input
  .wr_en(wr_en),                  // input
  .wr_data(wr_data),              // input [23:0]
  .wr_full(wr_full),              // output
  .almost_full(almost_full),      // output
  .rd_clk(rd_clk),                // input
  .rd_rst(rd_rst),                // input
  .rd_en(rd_en),                  // input
  .rd_data(rd_data),              // output [23:0]
  .rd_empty(rd_empty),            // output
  .almost_empty(almost_empty)     // output
);
