`timescale 1ns/1ps

module uart_tx_sva #(
  parameter int DATA_WIDTH = 8,
  parameter int CLKS_PER_BIT = 16
) (
  input logic clk,
  input logic rst_n,
  input logic start,
  input logic tx,
  input logic busy,
  input logic done
);

  localparam int FRAME_CLKS = (DATA_WIDTH + 2) * CLKS_PER_BIT;

  property idle_line_high;
    @(posedge clk) disable iff (!rst_n) (!busy && !start) |-> tx;
  endproperty

  property start_sets_busy;
    @(posedge clk) disable iff (!rst_n) (start && !busy) |=> busy;
  endproperty

  property done_is_single_cycle;
    @(posedge clk) disable iff (!rst_n) done |=> !done;
  endproperty

  property done_after_frame_window;
    @(posedge clk) disable iff (!rst_n)
      (start && !busy) |-> ##[FRAME_CLKS-1:FRAME_CLKS+1] done;
  endproperty

  assert property (idle_line_high);
  assert property (start_sets_busy);
  assert property (done_is_single_cycle);
  assert property (done_after_frame_window);

  cover property (@(posedge clk) disable iff (!rst_n) start && !busy);
  cover property (@(posedge clk) disable iff (!rst_n) done);
endmodule

