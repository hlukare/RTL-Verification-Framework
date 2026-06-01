`timescale 1ns/1ps

package rvf_pkg;
  parameter int DEFAULT_DATA_WIDTH = 8;
  parameter int DEFAULT_FIFO_DEPTH = 16;

  typedef enum logic [1:0] {
    UART_IDLE,
    UART_START,
    UART_DATA,
    UART_STOP
  } uart_tx_state_e;

  function automatic int clog2_safe(input int value);
    int result;
    begin
      result = 0;
      value = value - 1;
      while (value > 0) begin
        result++;
        value = value >> 1;
      end
      return (result == 0) ? 1 : result;
    end
  endfunction
endpackage
