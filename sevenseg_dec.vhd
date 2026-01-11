library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_hex4 is
  generic(
    CLK_HZ      : integer := 50_000_000;
    REFRESH_HZ  : integer := 1000;
    ACTIVE_LOW  : boolean := true
  );
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;

    hex_in   : in  std_logic_vector(15 downto 0); -- 4 nibbles

    seg      : out std_logic_vector(6 downto 0);  -- a..g
    dp       : out std_logic;
    an       : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of sevenseg_hex4 is
  constant DIV_TICKS : integer := CLK_HZ / (REFRESH_HZ * 4);
  signal div_cnt     : integer range 0 to DIV_TICKS-1 := 0;
  signal tick        : std_logic := '0';
  signal digit_sel   : unsigned(1 downto 0) := (others => '0');

  -- segmentos activos en '1' (luego se invierte si ACTIVE_LOW)
  function hex_to_7seg(n : std_logic_vector(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    case n is
      when "0000" => s := "1111110"; -- 0
      when "0001" => s := "0110000"; -- 1
      when "0010" => s := "1101101"; -- 2
      when "0011" => s := "1111001"; -- 3
      when "0100" => s := "0110011"; -- 4
      when "0101" => s := "1011011"; -- 5
      when "0110" => s := "1011111"; -- 6
      when "0111" => s := "1110000"; -- 7
      when "1000" => s := "1111111"; -- 8
      when "1001" => s := "1111011"; -- 9
      when "1010" => s := "1110111"; -- A
      when "1011" => s := "0011111"; -- b
      when "1100" => s := "1001110"; -- C
      when "1101" => s := "0111101"; -- d
      when "1110" => s := "1001111"; -- E
      when others => s := "1000111"; -- F
    end case;
    return s;
  end function;

  signal seg_raw : std_logic_vector(6 downto 0);
  signal an_raw  : std_logic_vector(3 downto 0);
  signal nibble  : std_logic_vector(3 downto 0);

begin

  -- tick multiplex
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        div_cnt <= 0; tick <= '0';
      else
        if div_cnt = DIV_TICKS-1 then
          div_cnt <= 0; tick <= '1';
        else
          div_cnt <= div_cnt + 1; tick <= '0';
        end if;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        digit_sel <= (others => '0');
      elsif tick = '1' then
        digit_sel <= digit_sel + 1;
      end if;
    end if;
  end process;

  -- seleccionar dgito (an0=LS digit normalmente)
  process(digit_sel, hex_in)
  begin
    an_raw  <= "0000";
    nibble  <= "0000";

    case digit_sel is
      when "00" =>
        an_raw <= "0001";                -- dig 0 (derecha)
        nibble <= hex_in(3 downto 0);
      when "01" =>
        an_raw <= "0010";
        nibble <= hex_in(7 downto 4);
      when "10" =>
        an_raw <= "0100";
        nibble <= hex_in(11 downto 8);
      when others =>
        an_raw <= "1000";                -- dig 3 (izquierda)
        nibble <= hex_in(15 downto 12);
    end case;

    seg_raw <= hex_to_7seg(nibble);
  end process;

  -- polaridad
  process(seg_raw, an_raw)
  begin
    if ACTIVE_LOW then
      seg <= not seg_raw;
      an  <= not an_raw;
      dp  <= '1'; -- apagado
    else
      seg <= seg_raw;
      an  <= an_raw;
      dp  <= '0';
    end if;
  end process;

end architecture;

