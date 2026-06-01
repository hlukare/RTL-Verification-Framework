`timescale 1ns/1ps

module sync_fifo #(
  parameter int DATA_WIDTH = 8,
  parameter int DEPTH = 16,
  localparam int ADDR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH),
  localparam int COUNT_WIDTH = $clog2(DEPTH + 1)
) (
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  wr_en,
  input  logic                  rd_en,
  input  logic [DATA_WIDTH-1:0] din,
  output logic [DATA_WIDTH-1:0] dout,
  output logic                  full,
  output logic                  empty,
  output logic                  almost_full,
  output logic                  almost_empty,
  output logic [COUNT_WIDTH-1:0] count
);

  logic [DATA_WIDTH-1:0] mem [DEPTH];
  logic [ADDR_WIDTH-1:0] wr_ptr;
  logic [ADDR_WIDTH-1:0] rd_ptr;
  localparam logic [COUNT_WIDTH-1:0] DEPTH_VALUE = COUNT_WIDTH'(DEPTH);
  localparam logic [COUNT_WIDTH-1:0] ALMOST_FULL_VALUE = COUNT_WIDTH'(DEPTH - 1);
  localparam logic [ADDR_WIDTH-1:0] LAST_ADDR_VALUE = ADDR_WIDTH'(DEPTH - 1);

  wire write_fire = wr_en && !full;
  wire read_fire  = rd_en && !empty;

  function automatic logic [ADDR_WIDTH-1:0] ptr_next(input logic [ADDR_WIDTH-1:0] ptr);
    if (ptr == LAST_ADDR_VALUE) begin
      return '0;
    end
    return ptr + 1'b1;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
      dout   <= '0;
    end else begin
      if (write_fire) begin
        mem[wr_ptr] <= din;
        wr_ptr <= ptr_next(wr_ptr);
      end

      if (read_fire) begin
        dout <= mem[rd_ptr];
        rd_ptr <= ptr_next(rd_ptr);
      end

      case ({write_fire, read_fire})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: count <= count;
      endcase
    end
  end

  assign full         = (count == DEPTH_VALUE);
  assign empty        = (count == '0);
  assign almost_full  = (count >= ALMOST_FULL_VALUE);
  assign almost_empty = (count <= 1);

endmodule
