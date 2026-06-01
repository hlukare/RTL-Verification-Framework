`timescale 1ns/1ps

package rvf_pkg;
  typedef enum logic [1:0] {
    UART_IDLE,
    UART_START,
    UART_DATA,
    UART_STOP
  } uart_tx_state_e;
endpackage
