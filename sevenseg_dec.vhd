library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_dec is
  generic(
    CLK_HZ      : integer := 50_000_000;
    REFRESH_HZ  : integer := 1000;
    ACTIVE_LOW  : boolean := true
  );
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;
    value_in : in  std_logic_vector(7 downto 0); -- 0..255

    seg      : out std_logic_vector(6 downto 0); -- a..g
    dp       : out std_logic;
    an       : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of sevenseg_dec is
  constant DIV_TICKS : integer := CLK_HZ / (REFRESH_HZ * 4);
  signal div_cnt     : integer range 0 to DIV_TICKS-1 := 0;
  signal tick        : std_logic := '0';
  signal digit_sel   : unsigned(1 downto 0) := (others => '0');

  signal bcd_h : unsigned(3 downto 0) := (others => '0');
  signal bcd_t : unsigned(3 downto 0) := (others => '0');
  signal bcd_u : unsigned(3 downto 0) := (others => '0');

  -- segmentos activos en '1' (se invierte si ACTIVE_LOW)
  function digit_to_7seg(d : unsigned(3 downto 0)) return std_logic_vector is
    variable s : std_logic_vector(6 downto 0);
  begin
    case to_integer(d) is
      when 0 => s := "1111110";
      when 1 => s := "0110000";
      when 2 => s := "1101101";
      when 3 => s := "1111001";
      when 4 => s := "0110011";
      when 5 => s := "1011011";
      when 6 => s := "1011111";
      when 7 => s := "1110000";
      when 8 => s := "1111111";
      when others => s := "1111011"; -- 9
    end case;
    return s;
  end function;

  constant SEG_BLANK : std_logic_vector(6 downto 0) := "0000000";

  signal seg_raw : std_logic_vector(6 downto 0);
  signal an_raw  : std_logic_vector(3 downto 0);
begin

  -- divisor multiplexado
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        div_cnt <= 0;
        tick    <= '0';
      else
        if div_cnt = DIV_TICKS-1 then
          div_cnt <= 0;
          tick    <= '1';
        else
          div_cnt <= div_cnt + 1;
          tick    <= '0';
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

  -- BIN8 -> BCD (double dabble)
  process(value_in)
    variable bin : unsigned(7 downto 0);
    variable h,t,u : unsigned(3 downto 0);
  begin
    bin := unsigned(value_in);
    h := (others => '0');
    t := (others => '0');
    u := (others => '0');

    for i in 7 downto 0 loop
      if h >= 5 then h := h + 3; end if;
      if t >= 5 then t := t + 3; end if;
      if u >= 5 then u := u + 3; end if;

      h := h(2 downto 0) & t(3);
      t := t(2 downto 0) & u(3);
      u := u(2 downto 0) & bin(i);
    end loop;

    bcd_h <= h;
    bcd_t <= t;
    bcd_u <= u;
  end process;

  -- Selección dígito + blanking ceros izq
  process(digit_sel, bcd_h, bcd_t, bcd_u, value_in)
    variable v_is_zero : boolean;
    variable blank_h   : boolean;
    variable blank_t   : boolean;
  begin
    v_is_zero := (value_in = x"00");
    blank_h := (bcd_h = 0);
    blank_t := (blank_h and (bcd_t = 0));

    an_raw  <= "0000";
    seg_raw <= SEG_BLANK;

    case digit_sel is
      when "00" => -- unidades
        an_raw <= "0001";
        if v_is_zero then
          seg_raw <= digit_to_7seg(to_unsigned(0,4));
        else
          seg_raw <= digit_to_7seg(bcd_u);
        end if;

      when "01" => -- decenas
        an_raw <= "0010";
        if blank_t then
          seg_raw <= SEG_BLANK;
        else
          seg_raw <= digit_to_7seg(bcd_t);
        end if;

      when "10" => -- centenas
        an_raw <= "0100";
        if blank_h then
          seg_raw <= SEG_BLANK;
        else
          seg_raw <= digit_to_7seg(bcd_h);
        end if;

      when others => -- millares (no usado)
        an_raw  <= "1000";
        seg_raw <= SEG_BLANK;
    end case;
  end process;

  -- Polaridad common anode (active-low)
  process(seg_raw, an_raw)
  begin
    if ACTIVE_LOW then
      seg <= not seg_raw;
      an  <= not an_raw;
      dp  <= '1';       -- apagado
    else
      seg <= seg_raw;
      an  <= an_raw;
      dp  <= '0';
    end if;
  end process;

end architecture;

