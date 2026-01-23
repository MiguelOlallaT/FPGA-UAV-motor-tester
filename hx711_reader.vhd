library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hx711_reader is
  generic(
    CLK_HZ : integer := 50_000_000;
    SCK_HZ : integer := 50_000
  );
  port(
    clk          : in  std_logic;
    reset        : in  std_logic;

    hx_dout0     : in  std_logic;
    hx_dout1     : in  std_logic;
    hx_dout2     : in  std_logic;
    hx_dout3     : in  std_logic;
    hx_dout4     : in  std_logic;
    hx_dout5     : in  std_logic;

    hx_sck       : out std_logic;

    raw_s0       : out std_logic_vector(23 downto 0);
    raw_s1       : out std_logic_vector(23 downto 0);
    raw_s2       : out std_logic_vector(23 downto 0);
    raw_s3       : out std_logic_vector(23 downto 0);
    raw_s4       : out std_logic_vector(23 downto 0);
    raw_s5       : out std_logic_vector(23 downto 0);

    valid_o      : out std_logic
  );
end entity;

architecture rtl of hx711_reader is
  constant HALF_PERIOD : integer := CLK_HZ / (SCK_HZ * 2);

  signal div_cnt  : integer range 0 to HALF_PERIOD-1 := 0;
  signal sck_tick : std_logic := '0';
  signal sck_int  : std_logic := '0';

  type state_t is (IDLE, ACTIVE);
  signal st : state_t := IDLE;

  signal fall_cnt  : integer range 0 to 25 := 0;

  signal shift0 : std_logic_vector(23 downto 0) := (others => '0');
  signal shift1 : std_logic_vector(23 downto 0) := (others => '0');
  signal shift2 : std_logic_vector(23 downto 0) := (others => '0');
  signal shift3 : std_logic_vector(23 downto 0) := (others => '0');
  signal shift4 : std_logic_vector(23 downto 0) := (others => '0');
  signal shift5 : std_logic_vector(23 downto 0) := (others => '0');

  signal dout0_ff1  : std_logic := '1';
  signal dout0_ff2  : std_logic := '1';
  signal dout1_ff1  : std_logic := '1';
  signal dout1_ff2  : std_logic := '1';
  signal dout2_ff1  : std_logic := '1';
  signal dout2_ff2  : std_logic := '1';
  signal dout3_ff1  : std_logic := '1';
  signal dout3_ff2  : std_logic := '1';
  signal dout4_ff1  : std_logic := '1';
  signal dout4_ff2  : std_logic := '1';
  signal dout5_ff1  : std_logic := '1';
  signal dout5_ff2  : std_logic := '1';

  signal dout0_sync : std_logic := '1';
  signal dout1_sync : std_logic := '1';
  signal dout2_sync : std_logic := '1';
  signal dout3_sync : std_logic := '1';
  signal dout4_sync : std_logic := '1';
  signal dout5_sync : std_logic := '1';

  signal all_ready : std_logic := '0';

begin

  hx_sck <= sck_int;

  process(clk)
  begin
    if rising_edge(clk) then
      dout0_ff1 <= hx_dout0;
      dout0_ff2 <= dout0_ff1;
      dout1_ff1 <= hx_dout1;
      dout1_ff2 <= dout1_ff1;
      dout2_ff1 <= hx_dout2;
      dout2_ff2 <= dout2_ff1;
      dout3_ff1 <= hx_dout3;
      dout3_ff2 <= dout3_ff1;
      dout4_ff1 <= hx_dout4;
      dout4_ff2 <= dout4_ff1;
      dout5_ff1 <= hx_dout5;
      dout5_ff2 <= dout5_ff1;
    end if;
  end process;

  dout0_sync <= dout0_ff2;
  dout1_sync <= dout1_ff2;
  dout2_sync <= dout2_ff2;
  dout3_sync <= dout3_ff2;
  dout4_sync <= dout4_ff2;
  dout5_sync <= dout5_ff2;

  all_ready <= '1' when (dout0_sync='0' and dout1_sync='0' and dout2_sync='0' and dout3_sync='0' and dout4_sync='0' and dout5_sync='0') else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        div_cnt  <= 0;
        sck_tick <= '0';
      else
        if div_cnt = HALF_PERIOD-1 then
          div_cnt  <= 0;
          sck_tick <= '1';
        else
          div_cnt  <= div_cnt + 1;
          sck_tick <= '0';
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable bitpos : integer;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        st       <= IDLE;
        sck_int  <= '0';
        fall_cnt <= 0;
        shift0   <= (others => '0');
        shift1   <= (others => '0');
        shift2   <= (others => '0');
        shift3   <= (others => '0');
        shift4   <= (others => '0');
        shift5   <= (others => '0');
        raw_s0   <= (others => '0');
        raw_s1   <= (others => '0');
        raw_s2   <= (others => '0');
        raw_s3   <= (others => '0');
        raw_s4   <= (others => '0');
        raw_s5   <= (others => '0');
        valid_o  <= '0';
      else
        valid_o <= '0';

        case st is
          when IDLE =>
            sck_int  <= '0';
            fall_cnt <= 0;
            if all_ready = '1' then
              shift0 <= (others => '0');
              shift1 <= (others => '0');
              shift2 <= (others => '0');
              shift3 <= (others => '0');
              shift4 <= (others => '0');
              shift5 <= (others => '0');
              st <= ACTIVE;
            end if;

          when ACTIVE =>
            if sck_tick = '1' then
              sck_int <= not sck_int;

              if sck_int = '1' then
                if fall_cnt < 24 then
                  bitpos := 23 - fall_cnt;
                  shift0(bitpos) <= dout0_sync;
                  shift1(bitpos) <= dout1_sync;
                  shift2(bitpos) <= dout2_sync;
                  shift3(bitpos) <= dout3_sync;
                  shift4(bitpos) <= dout4_sync;
                  shift5(bitpos) <= dout5_sync;
                end if;
                fall_cnt <= fall_cnt + 1;

                if fall_cnt = 24 then
                  raw_s0 <= shift0;
                  raw_s1 <= shift1;
                  raw_s2 <= shift2;
                  raw_s3 <= shift3;
                  raw_s4 <= shift4;
                  raw_s5 <= shift5;
                  valid_o <= '1';
                  st <= IDLE;
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture;
