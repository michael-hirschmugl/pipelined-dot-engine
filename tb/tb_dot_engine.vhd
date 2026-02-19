library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.dot_types_pkg.all;

entity tb_dot_engine is
  generic (
    A_WIDTH   : positive := 8;
    B_WIDTH   : positive := 8;
    OUT_WIDTH : positive := 18;
    VEC_LEN   : positive := 4
  );
end tb_dot_engine;

architecture tb of tb_dot_engine is

  component dot_engine
    generic (
      A_WIDTH   : integer := 8;
      B_WIDTH   : integer := 8;
      OUT_WIDTH : integer := 18;
      VEC_LEN   : integer := 4
    );
    port (
      a         : in  vec_a_t(0 to 4-1)(A_WIDTH-1 downto 0);
      b         : in  vec_b_t(0 to 4-1)(B_WIDTH-1 downto 0);
      clk       : in  std_logic;
      reset     : in  std_logic;

      in_valid  : in  std_logic;
      in_ready  : out std_logic;

      out_valid : out std_logic;
      out_ready : in  std_logic;

      result    : out signed(OUT_WIDTH-1 downto 0)
    );
  end component;

  signal a         : vec_a_t(0 to 4-1)(A_WIDTH-1 downto 0);
  signal b         : vec_b_t(0 to 4-1)(B_WIDTH-1 downto 0);

  signal clk       : std_logic := '0';
  signal reset     : std_logic := '0';

  signal in_valid  : std_logic := '0';
  signal in_ready  : std_logic;

  signal out_valid : std_logic;
  signal out_ready : std_logic := '1';

  signal result    : signed(OUT_WIDTH-1 downto 0);

  constant CLK_PERIOD : time := 10 ns;

begin

  -- DUT
  dut : dot_engine
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

  -- Clock
  clk <= not clk after CLK_PERIOD/2;

  -- Stimulus
  stim : process
  begin
    -- init
    for i in 0 to 3 loop
      a(i) <= (others => '0');
      b(i) <= (others => '0');
    end loop;
    in_valid  <= '0';
    out_ready <= '1';

    -- reset (2 cycles)
    reset <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    reset <= '0';

    -- Beispiel-Vektoren
    a(0) <= to_signed(1, A_WIDTH);  b(0) <= to_signed(5, B_WIDTH);
    a(1) <= to_signed(2, A_WIDTH);  b(1) <= to_signed(6, B_WIDTH);
    a(2) <= to_signed(3, A_WIDTH);  b(2) <= to_signed(7, B_WIDTH);
    a(3) <= to_signed(4, A_WIDTH);  b(3) <= to_signed(8, B_WIDTH);

    wait until rising_edge(clk); -- settle

    -- Input "abschicken"
    in_valid <= '1';
    loop
      wait until rising_edge(clk);
      exit when in_ready = '1';
    end loop;
    in_valid <= '0';

    -- warten
    while out_valid /= '1' loop
      wait until rising_edge(clk);
    end loop;

    wait until rising_edge(clk);

    wait;
  end process;

end tb;
