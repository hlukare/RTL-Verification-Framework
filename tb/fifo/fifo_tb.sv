`timescale 1ns/1ps

module fifo_tb;
  import tb_utils_pkg::*;

  localparam int DATA_WIDTH = 8;
  localparam int DEPTH = 8;
  localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

  logic clk;
  logic rst_n;
  logic wr_en;
  logic rd_en;
  logic [DATA_WIDTH-1:0] din;
  logic [DATA_WIDTH-1:0] dout;
  logic full;
  logic empty;
  logic almost_full;
  logic almost_empty;
  logic [COUNT_WIDTH-1:0] count;

  logic [DATA_WIDTH-1:0] model_q [$];

`ifndef IVERILOG
  covergroup fifo_cg @(posedge clk);
    option.per_instance = 1;
    cp_count: coverpoint count {
      bins empty = {0};
      bins low = {[1:2]};
      bins middle = {[3:DEPTH-2]};
      bins high = {DEPTH-1};
      bins full = {DEPTH};
    }
    cp_operation: coverpoint {wr_en, rd_en} {
      bins idle = {2'b00};
      bins write_only = {2'b10};
      bins read_only = {2'b01};
      bins simultaneous = {2'b11};
    }
    cp_flags: coverpoint {full, empty, almost_full, almost_empty};
    count_x_operation: cross cp_count, cp_operation;
  endgroup

  fifo_cg cg = new();
`endif

  sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .din(din),
    .dout(dout),
    .full(full),
    .empty(empty),
    .almost_full(almost_full),
    .almost_empty(almost_empty),
    .count(count)
  );

`ifndef IVERILOG
  fifo_sva #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) sva (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .din(din),
    .dout(dout),
    .full(full),
    .empty(empty),
    .almost_full(almost_full),
    .almost_empty(almost_empty),
    .count(count)
  );
`endif

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic reset_dut;
    wr_en = 1'b0;
    rd_en = 1'b0;
    din = '0;
    rst_n = 1'b0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    check_true(empty, "FIFO must be empty after reset");
    check_true(count == 0, "FIFO count must be zero after reset");
  endtask

  task automatic drive_cycle(input bit do_wr, input bit do_rd, input logic [DATA_WIDTH-1:0] data);
    logic [DATA_WIDTH-1:0] expected;
    bit expect_read;
    bit expect_write;

    expect_write = do_wr && !full;
    expect_read = do_rd && !empty;
    if (expect_read) expected = model_q[0];

    wr_en <= do_wr;
    rd_en <= do_rd;
    din <= data;
    @(posedge clk);
    #1;

    if (expect_read) begin
      check_true(dout == expected, $sformatf("FIFO read data mismatch expected=0x%0h actual=0x%0h", expected, dout));
      expected = model_q.pop_front();
    end

    if (expect_write) begin
      model_q.push_back(data);
    end

    check_true(count == model_q.size(), $sformatf("FIFO count mismatch expected=%0d actual=%0d", model_q.size(), count));
    check_true(full == (model_q.size() == DEPTH), "FIFO full flag mismatch");
    check_true(empty == (model_q.size() == 0), "FIFO empty flag mismatch");
  endtask

  task automatic directed_tests;
    for (int i = 0; i < DEPTH; i++) begin
      drive_cycle(1'b1, 1'b0, i[DATA_WIDTH-1:0]);
    end
    check_true(full, "FIFO must assert full after DEPTH writes");

    drive_cycle(1'b1, 1'b0, 8'hff);
    check_true(model_q.size() == DEPTH, "Overflow write must be ignored");

    for (int i = 0; i < DEPTH; i++) begin
      drive_cycle(1'b0, 1'b1, '0);
    end
    check_true(empty, "FIFO must assert empty after all reads");

    drive_cycle(1'b0, 1'b1, '0);
    check_true(model_q.size() == 0, "Underflow read must be ignored");
  endtask

  task automatic randomized_tests;
    for (int i = 0; i < 200; i++) begin
      bit do_wr;
      bit do_rd;
      do_wr = ($urandom_range(0, 99) < 65);
      do_rd = ($urandom_range(0, 99) < 55);
      drive_cycle(do_wr, do_rd, $urandom());
    end
  endtask

  initial begin
    print_banner("sync_fifo verification");
    $dumpfile("build/waves/fifo_tb.vcd");
    $dumpvars(0, fifo_tb);

    reset_dut();
    directed_tests();
    randomized_tests();
    wr_en <= 1'b0;
    rd_en <= 1'b0;
    repeat (5) @(posedge clk);
    finish_test("sync_fifo");
  end
endmodule
