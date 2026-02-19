// dot_types_pkg.sv
`timescale 1ns/1ps

package dot_types_pkg;
  // Helper: ceil(log2(n)) for n >= 1
  function automatic int unsigned ceil_log2(input int unsigned n);
    int unsigned v;
    int unsigned r;
    begin
      v = 1;
      r = 0;
      while (v < n) begin
        v = v << 1;
        r++;
      end
      return r;
    end
  endfunction
endpackage
