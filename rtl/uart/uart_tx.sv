`timescale 1ns/1ps

module uart_tx #(
  parameter int DATA_WIDTH = 8,
  parameter int CLKS_PER_BIT = 16
) (
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  start,
  input  logic [DATA_WIDTH-1:0] data_i,
  output logic                  tx,
  output logic                  busy,
  output logic                  done
);

  import rvf_pkg::*;

  localparam int BIT_CNT_WIDTH = (DATA_WIDTH <= 2) ? 1 : $clog2(DATA_WIDTH);
  localparam int BAUD_CNT_WIDTH = (CLKS_PER_BIT <= 2) ? 1 : $clog2(CLKS_PER_BIT);
  localparam logic [BIT_CNT_WIDTH-1:0] DATA_LAST_BIT = BIT_CNT_WIDTH'(DATA_WIDTH - 1);
  localparam logic [BAUD_CNT_WIDTH-1:0] BAUD_LAST_COUNT = BAUD_CNT_WIDTH'(CLKS_PER_BIT - 1);

  uart_tx_state_e state_q, state_d;
  logic [DATA_WIDTH-1:0] shift_q, shift_d;
  logic [BIT_CNT_WIDTH-1:0] bit_cnt_q, bit_cnt_d;
  logic [BAUD_CNT_WIDTH-1:0] baud_cnt_q, baud_cnt_d;
  logic baud_tick;

  assign baud_tick = (baud_cnt_q == BAUD_LAST_COUNT);

  always @* begin
    state_d = state_q;
    shift_d = shift_q;
    bit_cnt_d = bit_cnt_q;
    baud_cnt_d = baud_tick ? '0 : baud_cnt_q + 1'b1;
    tx = 1'b1;
    done = 1'b0;

    case (state_q)
      UART_IDLE: begin
        tx = 1'b1;
        baud_cnt_d = '0;
        bit_cnt_d = '0;
        if (start) begin
          shift_d = data_i;
          state_d = UART_START;
        end
      end

      UART_START: begin
        tx = 1'b0;
        if (baud_tick) begin
          state_d = UART_DATA;
        end
      end

      UART_DATA: begin
        tx = shift_q[0];
        if (baud_tick) begin
          shift_d = {1'b0, shift_q[DATA_WIDTH-1:1]};
          if (bit_cnt_q == DATA_LAST_BIT) begin
            bit_cnt_d = '0;
            state_d = UART_STOP;
          end else begin
            bit_cnt_d = bit_cnt_q + 1'b1;
          end
        end
      end

      UART_STOP: begin
        tx = 1'b1;
        if (baud_tick) begin
          done = 1'b1;
          state_d = UART_IDLE;
        end
      end

      default: begin
        state_d = UART_IDLE;
        tx = 1'b1;
      end
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_q <= UART_IDLE;
      shift_q <= '0;
      bit_cnt_q <= '0;
      baud_cnt_q <= '0;
    end else begin
      state_q <= state_d;
      shift_q <= shift_d;
      bit_cnt_q <= bit_cnt_d;
      baud_cnt_q <= baud_cnt_d;
    end
  end

  assign busy = (state_q != UART_IDLE);

endmodule
