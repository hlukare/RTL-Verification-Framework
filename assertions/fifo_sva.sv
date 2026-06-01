`timescale 1ns/1ps

module fifo_sva #(
  parameter int DATA_WIDTH = 8,
  parameter int DEPTH = 16,
  localparam int COUNT_WIDTH = $clog2(DEPTH + 1)
) (
  input logic                   clk,
  input logic                   rst_n,
  input logic                   wr_en,
  input logic                   rd_en,
  input logic [DATA_WIDTH-1:0]  din,
  input logic [DATA_WIDTH-1:0]  dout,
  input logic                   full,
  input logic                   empty,
  input logic                   almost_full,
  input logic                   almost_empty,
  input logic [COUNT_WIDTH-1:0] count
);

  property reset_clears_fifo;
    @(posedge clk) !rst_n |=> (empty && !full && count == 0);
  endproperty

  property count_never_overflows;
    @(posedge clk) disable iff (!rst_n) count <= DEPTH;
  endproperty

  property full_matches_count;
    @(posedge clk) disable iff (!rst_n) full == (count == DEPTH);
  endproperty

  property empty_matches_count;
    @(posedge clk) disable iff (!rst_n) empty == (count == 0);
  endproperty

  property almost_flags_match_count;
    @(posedge clk) disable iff (!rst_n)
      (almost_full == (count >= DEPTH - 1)) &&
      (almost_empty == (count <= 1));
  endproperty

  property no_write_when_full_changes_count;
    @(posedge clk) disable iff (!rst_n)
      (wr_en && full && !rd_en) |=> count == $past(count);
  endproperty

  property no_read_when_empty_changes_count;
    @(posedge clk) disable iff (!rst_n)
      (rd_en && empty && !wr_en) |=> count == $past(count);
  endproperty

  assert property (reset_clears_fifo);
  assert property (count_never_overflows);
  assert property (full_matches_count);
  assert property (empty_matches_count);
  assert property (almost_flags_match_count);
  assert property (no_write_when_full_changes_count);
  assert property (no_read_when_empty_changes_count);

  cover property (@(posedge clk) disable iff (!rst_n) full);
  cover property (@(posedge clk) disable iff (!rst_n) empty);
  cover property (@(posedge clk) disable iff (!rst_n) wr_en && rd_en && !full && !empty);
endmodule
