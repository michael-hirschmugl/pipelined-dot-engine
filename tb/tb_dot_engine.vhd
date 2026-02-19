library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library dot_core;
use dot_core.dot_types_pkg.all;

use std.env.all;

entity tb_dot_engine is
  generic (
    A_WIDTH   : positive := 8;
    B_WIDTH   : positive := 8;
    OUT_WIDTH : positive := 18;
    VEC_LEN   : positive := 4
  );
end tb_dot_engine;

architecture tb of tb_dot_engine is

  signal a         : vec_a_t(0 to VEC_LEN-1)(A_WIDTH-1 downto 0);
  signal b         : vec_b_t(0 to VEC_LEN-1)(B_WIDTH-1 downto 0);

  signal clk       : std_logic := '0';
  signal reset     : std_logic := '0';

  signal in_valid  : std_logic := '0';
  signal in_ready  : std_logic;

  signal out_valid : std_logic;
  signal out_ready : std_logic := '1';

  signal result    : signed(OUT_WIDTH-1 downto 0);

  constant CLK_PERIOD : time := 10 ns;

begin

  dut : entity dot_core.dot_engine
    generic map (
      A_WIDTH   => A_WIDTH,
      B_WIDTH   => B_WIDTH,
      OUT_WIDTH => OUT_WIDTH,
      VEC_LEN   => VEC_LEN
    )
    port map (
      a         => a,
      b         => b,
      clk       => clk,
      reset     => reset,
      in_valid  => in_valid,
      in_ready  => in_ready,
      out_valid => out_valid,
      out_ready => out_ready,
      result    => result
    );

  clk <= not clk after CLK_PERIOD/2;

  stim : process
    constant EXPECTED : integer := 70; -- 1*5+2*6+3*7+4*8
  begin
    for i in 0 to VEC_LEN-1 loop
      a(i) <= (others => '0');
      b(i) <= (others => '0');
    end loop;
    in_valid  <= '0';
    out_ready <= '1';

    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';

    a(0) <= to_signed(1, A_WIDTH);  b(0) <= to_signed(5, B_WIDTH);
    a(1) <= to_signed(2, A_WIDTH);  b(1) <= to_signed(6, B_WIDTH);
    a(2) <= to_signed(3, A_WIDTH);  b(2) <= to_signed(7, B_WIDTH);
    a(3) <= to_signed(4, A_WIDTH);  b(3) <= to_signed(8, B_WIDTH);

    wait until rising_edge(clk);

    in_valid <= '1';
    loop
      wait until rising_edge(clk);
      exit when in_ready = '1';
    end loop;
    in_valid <= '0';

    while out_valid /= '1' loop
      wait until rising_edge(clk);
    end loop;

    wait until rising_edge(clk);

    assert result = to_signed(EXPECTED, OUT_WIDTH)
      report "Mismatch! result=" & integer'image(to_integer(result)) &
             " expected=" & integer'image(EXPECTED)
      severity failure;

    report "PASS: result=" & integer'image(to_integer(result));

    finish;
  end process;

end tb;

