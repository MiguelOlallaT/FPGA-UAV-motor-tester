library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_dec13 is
  generic(
    CLK_HZ      : integer := 50_000_000;
    REFRESH_HZ  : integer := 1000;
    ACTIVE_LOW  : boolean := true
  );
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;
    value_in : in  std_logic_vector(12 downto 0);
    seg      : out std_logic_vector(6 downto 0);
    dp       : out std_logic;
    an       : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl_dec of sevenseg_dec13 is
  constant DIV_TICKS : integer := CLK_HZ / (REFRESH_HZ * 4);

  signal div_cnt   : integer range 0 to DIV_TICKS-1 := 0;
  signal tick      : std_logic := '0';
  signal digit_sel : unsigned(1 downto 0) := (others => '0');

  signal bcd_reg : unsigned(15 downto 0) := (others => '0');

  function dec_to_7seg_i(n : integer) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    case n is
      when 0 => s := "1111110";
      when 1 => s := "0110000";
      when 2 => s := "1101101";
      when 3 => s := "1111001";
      when 4 => s := "0110011";
      when 5 => s := "1011011";
      when 6 => s := "1011111";
      when 7 => s := "1110000";
      when 8 => s := "1111111";
      when 9 => s := "1111011";
      when others => s := "0000001";
    end case;
    return s;
  end function;

  signal seg_o : std_logic_vector(6 downto 0) := (others => '0');
  signal an_o  : std_logic_vector(3 downto 0) := (others => '1');

begin

  gen_dp_low_dec : if ACTIVE_LOW generate
    dp <= '1';
  end generate;
  gen_dp_high_dec : if (not ACTIVE_LOW) generate
    dp <= '0';
  end generate;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        div_cnt   <= 0;
        tick      <= '0';
        digit_sel <= (others => '0');
      else
        tick <= '0';
        if div_cnt = DIV_TICKS-1 then
          div_cnt   <= 0;
          tick      <= '1';
          digit_sel <= digit_sel + 1;
        else
          div_cnt <= div_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  process(value_in)
    variable bcd : unsigned(15 downto 0);
    variable bin : unsigned(12 downto 0);
    variable i   : integer;
  begin
    bin := unsigned(value_in);
    bcd := (others => '0');

    for i in 12 downto 0 loop
      if bcd(3 downto 0)  >= 5 then bcd(3 downto 0)  := bcd(3 downto 0)  + 3; end if;
      if bcd(7 downto 4)  >= 5 then bcd(7 downto 4)  := bcd(7 downto 4)  + 3; end if;
      if bcd(11 downto 8) >= 5 then bcd(11 downto 8) := bcd(11 downto 8) + 3; end if;
      if bcd(15 downto 12)>= 5 then bcd(15 downto 12):= bcd(15 downto 12)+ 3; end if;

      bcd := bcd(14 downto 0) & bin(i);
    end loop;

    bcd_reg <= bcd;
  end process;

  process(digit_sel, bcd_reg)
    variable dig : integer range 0 to 15;
    variable an_t : std_logic_vector(3 downto 0);
    variable seg_t: std_logic_vector(6 downto 0);
  begin
    an_t := "0000";
    case digit_sel is
      when "00" => dig := to_integer(bcd_reg(3 downto 0));    an_t := "0001";
      when "01" => dig := to_integer(bcd_reg(7 downto 4));    an_t := "0010";
      when "10" => dig := to_integer(bcd_reg(11 downto 8));   an_t := "0100";
      when others => dig := to_integer(bcd_reg(15 downto 12)); an_t := "1000";
    end case;

    seg_t := dec_to_7seg_i(dig);

    if ACTIVE_LOW then
      seg_o <= not seg_t;
      an_o  <= not an_t;
    else
      seg_o <= seg_t;
      an_o  <= an_t;
    end if;
  end process;

  seg <= seg_o;
  an  <= an_o;

end architecture;
