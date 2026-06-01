`timescale 1ns/1ps

module arbiter_tb;
  import tb_utils_pkg::*;

  localparam int N = 4;

  logic clk;
  logic rst_n;
  logic [N-1:0] req;
  logic ready;
  logic [N-1:0] grant;
  logic valid;
  int unsigned expected_pointer;

`ifndef IVERILOG
  covergroup arbiter_cg @(posedge clk);
    option.per_instance = 1;
    cp_req: coverpoint req {
      bins none = {4'b0000};
      bins single[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins all = {4'b1111};
      bins sparse = default;
    }
    cp_grant: coverpoint grant {
      bins none = {4'b0000};
      bins gnt[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
    }
    cp_ready: coverpoint ready;
    cp_valid: coverpoint valid;
    ready_x_valid: cross cp_ready, cp_valid;
  endgroup

  arbiter_cg cg = new();
`endif

  round_robin_arbiter #(.N(N)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .req(req),
    .ready(ready),
    .grant(grant),
    .valid(valid)
  );

`ifndef IVERILOG
  arbiter_sva #(.N(N)) sva (
    .clk(clk),
    .rst_n(rst_n),
    .req(req),
    .ready(ready),
    .grant(grant),
    .valid(valid)
  );
`endif

  initial clk = 1'b0;
  always #5 clk = ~clk;

  function automatic logic [N-1:0] expected_grant(input logic [N-1:0] r, input int unsigned ptr);
    logic [N-1:0] g;
    g = '0;
    for (int offset = 0; offset < N; offset++) begin
      int unsigned idx;
      idx = (ptr + offset) % N;
      if (g == '0 && r[idx]) begin
        g[idx] = 1'b1;
      end
    end
    return g;
  endfunction

  task automatic reset_dut;
    rst_n = 1'b0;
    req = '0;
    ready = 1'b0;
    expected_pointer = 0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    check_true(!valid && grant == '0, "Arbiter must be idle after reset");
  endtask

  task automatic drive_cycle(input logic [N-1:0] req_i, input bit ready_i);
    logic [N-1:0] exp_g;
    req <= req_i;
    ready <= ready_i;
    #1;
    exp_g = expected_grant(req_i, expected_pointer);
    check_true(grant == exp_g, $sformatf("Grant mismatch req=%b ptr=%0d expected=%b actual=%b", req_i, expected_pointer, exp_g, grant));
    check_true(valid == (|exp_g), "Valid must match grant activity");
    @(posedge clk);
    #1;
    if ((|exp_g) && ready_i) begin
      for (int i = 0; i < N; i++) begin
        if (exp_g[i]) expected_pointer = (i + 1) % N;
      end
    end
  endtask

  task automatic directed_tests;
    drive_cycle(4'b0000, 1'b1);
    drive_cycle(4'b1111, 1'b1);
    drive_cycle(4'b1111, 1'b1);
    drive_cycle(4'b1111, 1'b1);
    drive_cycle(4'b1111, 1'b1);
    drive_cycle(4'b0101, 1'b0);
    drive_cycle(4'b0101, 1'b1);
    drive_cycle(4'b1000, 1'b1);
  endtask

  task automatic randomized_tests;
    for (int i = 0; i < 150; i++) begin
      drive_cycle($urandom_range(0, (1 << N) - 1), $urandom_range(0, 1));
    end
  endtask

  initial begin
    print_banner("round_robin_arbiter verification");
    $dumpfile("build/waves/arbiter_tb.vcd");
    $dumpvars(0, arbiter_tb);

    reset_dut();
    directed_tests();
    randomized_tests();
    req <= '0;
    ready <= 1'b0;
    repeat (4) @(posedge clk);
    finish_test("round_robin_arbiter");
  end
endmodule
