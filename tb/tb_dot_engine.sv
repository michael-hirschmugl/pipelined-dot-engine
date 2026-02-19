// tb_dot_engine.sv
`timescale 1ns/1ps

module tb_dot_engine;

  

  import dot_types_pkg::*;
localparam int unsigned A_WIDTH   = 8;
  localparam int unsigned B_WIDTH   = 8;
  localparam int unsigned OUT_WIDTH = 18;
  localparam int unsigned VEC_LEN   = 4;

  logic signed [A_WIDTH-1:0] a [0:VEC_LEN-1];
  logic signed [B_WIDTH-1:0] b [0:VEC_LEN-1];

  logic clk;
  logic reset;

  logic in_valid;
  logic in_ready;

  logic out_valid;
  logic out_ready;

  logic signed [OUT_WIDTH-1:0] result;

  localparam time CLK_PERIOD = 10ns;

  // DUT
  dot_engine #(
    .A_WIDTH(A_WIDTH),
    .B_WIDTH(B_WIDTH),
    .OUT_WIDTH(OUT_WIDTH),
    .VEC_LEN(VEC_LEN)
  ) dut (
    .a(a),
    .b(b),
    .clk(clk),
    .reset(reset),
    .in_valid(in_valid),
    .in_ready(in_ready),
    .out_valid(out_valid),
    .out_ready(out_ready),
    .result(result)
  );

  // Clock
  initial clk = 1'b0;
  always begin
    #(CLK_PERIOD/2);
    clk = ~clk;
  end
  // VCD
  initial begin
    $dumpfile("dot_engine_sim.vcd");
    $dumpvars(0, tb_dot_engine);
  end

  // Stimulus
  initial begin
      logic signed [OUT_WIDTH-1:0] expected;
expected = 70; // 1*5 + 2*6 + 3*7 + 4*8

    // init
    for (int i = 0; i < VEC_LEN; i++) begin
      a[i] = '0;
      b[i] = '0;
    end
    in_valid  = 1'b0;
    out_ready = 1'b1;

    // reset (2 cycles)
    reset = 1'b1;
    @(posedge clk);
    @(posedge clk);
    reset = 1'b0;

    // Example vectors
    a[0] = 1;  b[0] = 5;
    a[1] = 2;  b[1] = 6;
    a[2] = 3;  b[2] = 7;
    a[3] = 4;  b[3] = 8;

    @(posedge clk); // settle

    // Send input (valid/ready handshake)
    in_valid = 1'b1;
    while (!in_ready) @(posedge clk);
    @(posedge clk); // handshake occurs in S_IDLE
    in_valid = 1'b0;

    // Wait for output valid
    while (!out_valid) @(posedge clk);
    @(posedge clk); // sample one cycle later (result is registered)

    if (result !== expected) begin
      $display("[FAIL] result=%0d expected=%0d", $signed(result), expected);
      $fatal(1);
    end else begin
      $display("[PASS] result=%0d", $signed(result));
    end

    // Let a few cycles run for waveform readability, then finish
    repeat (5) @(posedge clk);
    $finish;
  end

endmodule
