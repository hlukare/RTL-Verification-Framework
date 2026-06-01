`timescale 1ns/1ps

package tb_utils_pkg;
  int unsigned error_count = 0;

  task automatic check_true(input bit condition, input string message);
    if (!condition) begin
      error_count++;
      $error("%s", message);
    end
  endtask

  task automatic print_banner(input string name);
    $display("");
    $display("============================================================");
    $display("  %s", name);
    $display("============================================================");
  endtask

  task automatic finish_test(input string name);
    if (error_count == 0) begin
      $display("[PASS] %s completed with no scoreboard errors", name);
      $finish;
    end else begin
      $display("[FAIL] %s completed with %0d scoreboard errors", name, error_count);
      $fatal(1, "%s failed", name);
    end
  endtask
endpackage
