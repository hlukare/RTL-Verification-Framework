`timescale 1ns/1ps

module round_robin_arbiter #(
  parameter int N = 4
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [N-1:0] req,
  input  logic         ready,
  output logic [N-1:0] grant,
  output logic         valid
);

  localparam int PTR_WIDTH = (N <= 2) ? 1 : $clog2(N);
  localparam logic [PTR_WIDTH-1:0] LAST_INDEX = PTR_WIDTH'(N - 1);

  logic [PTR_WIDTH-1:0] pointer_q;
  logic [PTR_WIDTH-1:0] grant_idx;
  logic [PTR_WIDTH-1:0] scan_idx;

  always_comb begin
    grant = '0;
    valid = 1'b0;
    grant_idx = pointer_q;
    scan_idx = pointer_q;

    for (int offset = 0; offset < N; offset++) begin
      if (!valid && req[scan_idx]) begin
        grant[scan_idx] = 1'b1;
        valid = 1'b1;
        grant_idx = scan_idx;
      end

      if (scan_idx == LAST_INDEX) begin
        scan_idx = '0;
      end else begin
        scan_idx = scan_idx + 1'b1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pointer_q <= '0;
    end else if (valid && ready) begin
      if (grant_idx == LAST_INDEX) begin
        pointer_q <= '0;
      end else begin
        pointer_q <= grant_idx + 1'b1;
      end
    end
  end

endmodule
