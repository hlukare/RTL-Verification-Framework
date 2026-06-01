`timescale 1ns/1ps

module arbiter_sva #(
  parameter int N = 4
) (
  input logic         clk,
  input logic         rst_n,
  input logic [N-1:0] req,
  input logic         ready,
  input logic [N-1:0] grant,
  input logic         valid
);

  property grant_is_onehot_or_zero;
    @(posedge clk) disable iff (!rst_n) $onehot0(grant);
  endproperty

  property valid_matches_grant;
    @(posedge clk) disable iff (!rst_n) valid == (|grant);
  endproperty

  property grants_only_requested_clients;
    @(posedge clk) disable iff (!rst_n) (grant & ~req) == '0;
  endproperty

  property no_request_no_valid;
    @(posedge clk) disable iff (!rst_n) (req == '0) |-> (!valid && grant == '0);
  endproperty

  property backpressure_holds_grant;
    @(posedge clk) disable iff (!rst_n)
      (valid && !ready && req == $past(req)) |=> grant == $past(grant);
  endproperty

  assert property (grant_is_onehot_or_zero);
  assert property (valid_matches_grant);
  assert property (grants_only_requested_clients);
  assert property (no_request_no_valid);
  assert property (backpressure_holds_grant);

  cover property (@(posedge clk) disable iff (!rst_n) &req);
  cover property (@(posedge clk) disable iff (!rst_n) valid && ready);
endmodule

