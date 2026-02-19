// dot_engine.sv
`timescale 1ns/1ps

module dot_engine #(
  parameter int unsigned A_WIDTH   = 8,
  parameter int unsigned B_WIDTH   = 8,
  parameter int unsigned OUT_WIDTH = 18,
  parameter int unsigned VEC_LEN   = 4
)(
  input  logic signed [A_WIDTH-1:0]   a [0:VEC_LEN-1],
  input  logic signed [B_WIDTH-1:0]   b [0:VEC_LEN-1],
  input  logic                        clk,
  input  logic                        reset,     // synchronous, active high

  input  logic                        in_valid,
  output logic                        in_ready,

  output logic                        out_valid,
  input  logic                        out_ready,

  output logic signed [OUT_WIDTH-1:0] result
);

  

  import dot_types_pkg::*;
// ---------------------------------------------------------------------------
  // Compile-time / elaboration-time sanity checks
  // ---------------------------------------------------------------------------
  localparam int unsigned FIXED_VEC_LEN = 4;

  localparam int unsigned MIN_OUT_W =
      A_WIDTH + B_WIDTH + $clog2(FIXED_VEC_LEN);

  initial begin
    if (VEC_LEN != FIXED_VEC_LEN) begin
      $fatal(1, "This version supports VEC_LEN=4 only (ports are fixed to 4).");
    end
    if (OUT_WIDTH < MIN_OUT_W) begin
      $fatal(1, "OUT_WIDTH too small for dot-product width. Need >= %0d", MIN_OUT_W);
    end
  end

  // ---------------------------------------------------------------------------
  // FSM
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    S_IDLE       = 4'd0,
    S_LOAD01     = 4'd1,
    S_LOAD23     = 4'd2,
    S_STOP_VALID = 4'd3,
    S_WAIT0      = 4'd4,
    S_WAIT1      = 4'd5,
    S_CAPTURE    = 4'd6,
    S_SUM        = 4'd7,
    S_HOLD_OUT   = 4'd8
  } state_t;

  state_t state_r;

  logic accept_in_s;

  logic signed [A_WIDTH-1:0] a0_s, a1_s;
  logic signed [B_WIDTH-1:0] b0_s, b1_s;

  logic v_in_s;
  logic eof_s;

  logic signed [OUT_WIDTH-1:0] r0_s, r1_s;
  logic signed [OUT_WIDTH-1:0] r0_cap_r, r1_cap_r;
  logic signed [OUT_WIDTH-1:0] sum_r;
  logic out_valid_r;

  // Always run in batch-mode
  logic en_s;
  assign en_s = 1'b1;

  assign in_ready    = (state_r == S_IDLE);
  assign accept_in_s = in_valid & in_ready;

  assign out_valid = out_valid_r;
  assign result    = sum_r;

  // ---------------------------------------------------------------------------
  // MAC instantiation (direct module instantiation)
  // ---------------------------------------------------------------------------
  mac #(
    .A_WIDTH(A_WIDTH),
    .B_WIDTH(B_WIDTH),
    .OUT_WIDTH(OUT_WIDTH)
  ) mac0 (
    .a(a0_s),
    .b(b0_s),
    .clk(clk),
    .reset(reset),
    .eof(eof_s),
    .result(r0_s),
    .valid_in(v_in_s),
    .valid_out(),
    .enable(en_s)
  );

  mac #(
    .A_WIDTH(A_WIDTH),
    .B_WIDTH(B_WIDTH),
    .OUT_WIDTH(OUT_WIDTH)
  ) mac1 (
    .a(a1_s),
    .b(b1_s),
    .clk(clk),
    .reset(reset),
    .eof(eof_s),
    .result(r1_s),
    .valid_in(v_in_s),
    .valid_out(),
    .enable(en_s)
  );

  // ---------------------------------------------------------------------------
  // FSM + datapath (registered)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (reset) begin
      state_r     <= S_IDLE;

      a0_s        <= '0;
      b0_s        <= '0;
      a1_s        <= '0;
      b1_s        <= '0;

      v_in_s      <= 1'b0;
      eof_s       <= 1'b0;

      r0_cap_r    <= '0;
      r1_cap_r    <= '0;
      sum_r       <= '0;
      out_valid_r <= 1'b0;

    end else begin
      unique case (state_r)
        S_IDLE: begin
          v_in_s      <= 1'b0;
          eof_s       <= 1'b0;
          out_valid_r <= 1'b0;

          if (accept_in_s) begin
            state_r <= S_LOAD01;
          end
        end

        S_LOAD01: begin
          a0_s   <= a[0];
          b0_s   <= b[0];
          a1_s   <= a[1];
          b1_s   <= b[1];
          v_in_s <= 1'b1;
          eof_s  <= 1'b0;
          state_r <= S_LOAD23;
        end

        S_LOAD23: begin
          a0_s   <= a[2];
          b0_s   <= b[2];
          a1_s   <= a[3];
          b1_s   <= b[3];
          v_in_s <= 1'b1;
          eof_s  <= 1'b1;
          state_r <= S_STOP_VALID;
        end

        S_STOP_VALID: begin
          v_in_s <= 1'b0;
          eof_s  <= 1'b0;
          state_r <= S_WAIT0;
        end

        S_WAIT0: begin
          state_r <= S_WAIT1;
        end

        S_WAIT1: begin
          state_r <= S_CAPTURE;
        end

        S_CAPTURE: begin
          r0_cap_r <= r0_s;
          r1_cap_r <= r1_s;
          state_r  <= S_SUM;
        end

        S_SUM: begin
          sum_r       <= r0_cap_r + r1_cap_r;
          out_valid_r <= 1'b1;
          state_r     <= S_HOLD_OUT;
        end

        S_HOLD_OUT: begin
          if (out_ready) begin
            out_valid_r <= 1'b0;
            state_r     <= S_IDLE;
          end
        end

        default: begin
          state_r <= S_IDLE;
        end
      endcase
    end
  end

  // Optional: unused valid_out signals are available for alignment/debug
  // but are not required by this batch-mode FSM.
  // logic unused = v0_s ^ v1_s; // placeholder to avoid lint warnings if desired

endmodule
