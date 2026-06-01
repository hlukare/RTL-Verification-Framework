`timescale 1ns/1ps

module uart_tx_tb;
  import tb_utils_pkg::*;

  localparam int DATA_WIDTH = 8;
  localparam int CLKS_PER_BIT = 8;

  logic clk;
  logic rst_n;
  logic start;
  logic [DATA_WIDTH-1:0] data_i;
  logic tx;
  logic busy;
  logic done;

`ifndef IVERILOG
  covergroup uart_tx_cg @(posedge clk);
    option.per_instance = 1;
    cp_start: coverpoint start;
    cp_busy: coverpoint busy;
    cp_done: coverpoint done;
    cp_data_on_start: coverpoint data_i iff (start) {
      bins zero = {8'h00};
      bins ones = {8'hff};
      bins alternating[] = {8'ha5, 8'h5a, 8'h3c, 8'hc3};
      bins random_payloads = default;
    }
    frame_control: cross cp_start, cp_busy;
  endgroup

  uart_tx_cg cg = new();
`endif

  uart_tx #(
    .DATA_WIDTH(DATA_WIDTH),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_i(data_i),
    .tx(tx),
    .busy(busy),
    .done(done)
  );

`ifndef IVERILOG
  uart_tx_sva #(
    .DATA_WIDTH(DATA_WIDTH),
    .CLKS_PER_BIT(CLKS_PER_BIT)
  ) sva (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .tx(tx),
    .busy(busy),
    .done(done)
  );
`endif

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic reset_dut;
    rst_n = 1'b0;
    start = 1'b0;
    data_i = '0;
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    check_true(tx, "UART TX line must idle high");
    check_true(!busy, "UART TX must be idle after reset");
  endtask

  task automatic send_byte(input logic [7:0] data);
    data_i <= data;
    start <= 1'b1;
    @(posedge clk);
    start <= 1'b0;
  endtask

  task automatic wait_clks(input int cycles);
    repeat (cycles) @(posedge clk);
    #1;
  endtask

  task automatic check_serial_frame(input logic [7:0] expected);
    wait (busy);
    wait_clks(CLKS_PER_BIT / 2);
    check_true(tx == 1'b0, "UART start bit must be low");

    for (int bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx++) begin
      wait_clks(CLKS_PER_BIT);
      check_true(tx == expected[bit_idx], $sformatf("UART bit %0d mismatch expected=%0b actual=%0b", bit_idx, expected[bit_idx], tx));
    end

    wait_clks(CLKS_PER_BIT);
    check_true(tx == 1'b1, "UART stop bit must be high");
    wait (done);
    @(posedge clk);
    #1;
    check_true(!done, "UART done must be a one-cycle pulse");
  endtask

  task automatic transaction(input logic [7:0] data);
    fork
      send_byte(data);
      check_serial_frame(data);
    join
  endtask

  initial begin
    print_banner("uart_tx verification");
    $dumpfile("build/waves/uart_tx_tb.vcd");
    $dumpvars(0, uart_tx_tb);

    reset_dut();
    transaction(8'h00);
    transaction(8'hff);
    transaction(8'ha5);
    transaction(8'h3c);
    for (int i = 0; i < 20; i++) begin
      transaction($urandom());
    end
    repeat (6) @(posedge clk);
    finish_test("uart_tx");
  end
endmodule
