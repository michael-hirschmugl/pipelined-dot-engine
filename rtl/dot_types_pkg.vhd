library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package dot_types_pkg is
  type vec_a_t is array (natural range <>) of signed;
  type vec_b_t is array (natural range <>) of signed;

  function ceil_log2(n : positive) return natural;
end package;

package body dot_types_pkg is
  function ceil_log2(n : positive) return natural is
    variable v : natural := 1;
    variable r : natural := 0;
  begin
    -- smallest r such that 2^r >= n
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;
end package body;
