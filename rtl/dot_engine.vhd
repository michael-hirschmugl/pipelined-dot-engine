library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.dot_types_pkg.all;

entity dot_engine is
  generic (
    A_WIDTH   : positive := 8;
    B_WIDTH   : positive := 8;
    OUT_WIDTH : positive := 18;
    VEC_LEN   : positive := 4
  );
  port (
    a         : in  vec_a_t(0 to VEC_LEN-1)(A_WIDTH-1 downto 0);
    b         : in  vec_b_t(0 to VEC_LEN-1)(B_WIDTH-1 downto 0);
    clk       : in  std_logic;
    reset     : in  std_logic;

    in_valid  : in  std_logic;
    in_ready  : out std_logic;

    out_valid : out std_logic;
    out_ready : in  std_logic;

    result    : out signed(OUT_WIDTH-1 downto 0)
  );
end dot_engine;

architecture fsm of dot_engine is

  -- currently hard-wire the ports to length 4.
  constant FIXED_VEC_LEN : integer := 4;

  -- ceil_log2 expects positive; FIXED_VEC_LEN is constant 4 so cast is safe.
  constant MIN_OUT_W : integer :=
    A_WIDTH + B_WIDTH + integer(ceil_log2(positive(FIXED_VEC_LEN)));

  component mac
    generic (
      A_WIDTH   : positive := 8;
      B_WIDTH   : positive := 8;
      OUT_WIDTH : positive := 17
    );
    port (
      a         : in  signed (A_WIDTH-1 downto 0);
      b         : in  signed (B_WIDTH-1 downto 0);
      clk       : in  std_logic;
      reset     : in  std_logic;
      eof       : in  std_logic;
      result    : out signed (OUT_WIDTH-1 downto 0);
      valid_in  : in  std_logic;
      valid_out : out std_logic;
      enable    : in  std_logic
    );
  end component;

  type state_t is (
    S_IDLE,
    S_LOAD01,
    S_LOAD23,
    S_STOP_VALID,
    S_WAIT0,
    S_WAIT1,
    S_CAPTURE,
    S_SUM,
    S_HOLD_OUT
  );

  signal state_r : state_t;

  signal accept_in_s : std_logic;

  signal a0_s, b0_s : signed(A_WIDTH-1 downto 0);
  signal a1_s, b1_s : signed(A_WIDTH-1 downto 0);

  signal v_in_s : std_logic;
  signal en_s   : std_logic;
  signal eof_s  : std_logic;

  signal r0_s, r1_s : signed(OUT_WIDTH-1 downto 0);
  signal v0_s, v1_s : std_logic;

  signal r0_cap_r, r1_cap_r : signed(OUT_WIDTH-1 downto 0);
  signal sum_r              : signed(OUT_WIDTH-1 downto 0);
  signal out_valid_r        : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Compile-time / elaboration-time sanity checks
  ---------------------------------------------------------------------------
  assert VEC_LEN = FIXED_VEC_LEN
    report "This version supports VEC_LEN=4 only (ports are fixed to 4)."
    severity failure;

  assert OUT_WIDTH >= MIN_OUT_W
    report "OUT_WIDTH too small for dot-product width."
    severity failure;

  ---------------------------------------------------------------------------
  -- Batch-mode enable: always run
  ---------------------------------------------------------------------------
  en_s <= '1';

  in_ready    <= '1' when state_r = S_IDLE else '0';
  accept_in_s <= in_valid and in_ready;

  out_valid <= out_valid_r;
  result    <= sum_r;

  mac0 : mac
    generic map (
      A_WIDTH   => A_WIDTH,
      B_WIDTH   => B_WIDTH,
      OUT_WIDTH => OUT_WIDTH
    )
    port map (
      a         => a0_s,
      b         => b0_s,
      clk       => clk,
      reset     => reset,
      eof       => eof_s,
      result    => r0_s,
      valid_in  => v_in_s,
      valid_out => v0_s,
      enable    => en_s
    );

  mac1 : mac
    generic map (
      A_WIDTH   => A_WIDTH,
      B_WIDTH   => B_WIDTH,
      OUT_WIDTH => OUT_WIDTH
    )
    port map (
      a         => a1_s,
      b         => b1_s,
      clk       => clk,
      reset     => reset,
      eof       => eof_s,
      result    => r1_s,
      valid_in  => v_in_s,
      valid_out => v1_s,
      enable    => en_s
    );

  ---------------------------------------------------------------------------
  -- FSM + datapath
  ---------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state_r     <= S_IDLE;

        a0_s        <= (others => '0');
        b0_s        <= (others => '0');
        a1_s        <= (others => '0');
        b1_s        <= (others => '0');

        v_in_s      <= '0';
        eof_s       <= '0';

        r0_cap_r    <= (others => '0');
        r1_cap_r    <= (others => '0');
        sum_r       <= (others => '0');
        out_valid_r <= '0';

      else
        case state_r is
          when S_IDLE =>
            v_in_s      <= '0';
            eof_s       <= '0';
            out_valid_r <= '0';

            if accept_in_s = '1' then
              state_r <= S_LOAD01;
            end if;

          when S_LOAD01 =>
            a0_s   <= signed(a(0));
            b0_s   <= signed(b(0));
            a1_s   <= signed(a(1));
            b1_s   <= signed(b(1));
            v_in_s <= '1';
            eof_s  <= '0';
            state_r <= S_LOAD23;

          when S_LOAD23 =>
            a0_s   <= signed(a(2));
            b0_s   <= signed(b(2));
            a1_s   <= signed(a(3));
            b1_s   <= signed(b(3));
            v_in_s <= '1';
            eof_s  <= '1';
            state_r <= S_STOP_VALID;

          when S_STOP_VALID =>
            v_in_s <= '0';
            eof_s  <= '0';
            state_r <= S_WAIT0;

          when S_WAIT0 =>
            state_r <= S_WAIT1;

          when S_WAIT1 =>
            state_r <= S_CAPTURE;

          when S_CAPTURE =>
            r0_cap_r <= r0_s;
            r1_cap_r <= r1_s;
            state_r  <= S_SUM;

          when S_SUM =>
            sum_r       <= resize(r0_cap_r, OUT_WIDTH) + resize(r1_cap_r, OUT_WIDTH);
            out_valid_r <= '1';
            state_r     <= S_HOLD_OUT;

          when S_HOLD_OUT =>
            if out_ready = '1' then
              out_valid_r <= '0';
              state_r     <= S_IDLE;
            end if;

        end case;
      end if;
    end if;
  end process;

end fsm;
