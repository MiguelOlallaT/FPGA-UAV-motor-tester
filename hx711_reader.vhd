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

    hx_dout      : in  std_logic;
    hx_sck       : out std_logic;

    sample       : out signed(23 downto 0);
    sample_valid : out std_logic
  );
end entity;

architecture rtl of hx711_reader is
  constant HALF_PERIOD : integer := CLK_HZ / (SCK_HZ * 2);

  signal div_cnt  : integer range 0 to HALF_PERIOD-1 := 0;
  signal sck_tick : std_logic := '0';
  signal sck_int  : std_logic := '0';

  type state_t is (IDLE, ACTIVE);
  signal st : state_t := IDLE;

  signal rise_cnt  : integer range 0 to 25 := 0; -- 25 subidas (24 datos + 1 extra)
  signal shift_reg : std_logic_vector(23 downto 0) := (others => '0');
begin
  hx_sck <= sck_int;

  -- tick cada medio periodo
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
        st           <= IDLE;
        sck_int      <= '0';
        rise_cnt     <= 0;
        shift_reg    <= (others => '0');
        sample       <= (others => '0');
        sample_valid <= '0';
      else
        sample_valid <= '0';

        case st is
          when IDLE =>
            sck_int  <= '0';
            rise_cnt <= 0;
            if hx_dout = '0' then
              shift_reg <= (others => '0');
              st <= ACTIVE;
            end if;

          when ACTIVE =>
            if sck_tick = '1' then
              sck_int <= not sck_int;

              if sck_int = '0' then
                -- flanco de subida (0->1)
                if rise_cnt < 24 then
                  bitpos := 23 - rise_cnt;      -- MSB primero
                  shift_reg(bitpos) <= hx_dout;
                end if;
                rise_cnt <= rise_cnt + 1;

              else
                -- flanco de bajada (1->0)
                if rise_cnt = 25 then
                  sample <= signed(shift_reg);
                  sample_valid <= '1';
                  st <= IDLE;
                end if;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

end architecture;



