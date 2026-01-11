library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graph13_text_dec is
  port(
    clk50     : in  std_logic;
    reset     : in  std_logic;

    raw24_in  : in  std_logic_vector(23 downto 0);

    pixel_row : in  std_logic_vector(9 downto 0);
    pixel_col : in  std_logic_vector(9 downto 0);

    red       : out std_logic;
    green     : out std_logic;
    blue      : out std_logic
  );
end entity;

architecture rtl of graph13_text_dec is
  constant H_ACTIVE  : integer := 640;
  constant V_ACTIVE  : integer := 480;

  constant SAMPLE_HZ : integer := 64;
  constant WIN_SEC   : integer := 10;
  constant N_SAMPLES : integer := 640;
  constant DIV_TICKS : integer := 781250;

  type ram_t is array (0 to N_SAMPLES-1) of unsigned(12 downto 0);
  signal ram    : ram_t;
  signal wr_ptr : integer range 0 to N_SAMPLES-1 := 0;

  signal div_cnt     : integer range 0 to DIV_TICKS-1 := 0;
  signal sample_tick : std_logic := '0';

  -- BCD 8 dgitos
  signal d7,d6,d5,d4,d3,d2,d1,d0 : unsigned(3 downto 0) := (others => '0');

  function to_ascii_digit(d : unsigned(3 downto 0)) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(48 + to_integer(d), 8));
  end function;

  -- fuente 8x8 mnima (igual que la tuya, recortada a lo necesario)
  function font_row(ascii : std_logic_vector(7 downto 0); row : integer) return std_logic_vector is
    variable r : std_logic_vector(7 downto 0);
  begin
    r := (others => '0');
    case ascii is
      when x"20" => r := "00000000"; -- ' '
      when x"52" => if row=0 then r:="11111100"; elsif row=1 or row=2 then r:="11000110"; elsif row=3 then r:="11111100"; elsif row=4 then r:="11011000"; elsif row=5 then r:="11001100"; elsif row=6 then r:="11000110"; end if;
      when x"41" => if row=0 then r:="00111000"; elsif row=1 then r:="01101100"; elsif row=2 then r:="11000110"; elsif row=3 then r:="11111110"; elsif row=4 or row=5 or row=6 then r:="11000110"; end if;
      when x"57" => if row=0 or row=1 or row=2 then r:="11000110"; elsif row=3 or row=4 then r:="11010110"; elsif row=5 then r:="11101110"; elsif row=6 then r:="01101100"; end if;
      when x"3D" => if row=2 or row=4 then r:="11111110"; end if;
      when x"30" => if row=0 or row=6 then r:="01111100"; elsif row=1 or row=5 then r:="11000110"; elsif row=2 then r:="11001110"; elsif row=3 then r:="11010110"; elsif row=4 then r:="11100110"; end if;
      when x"31" => if row=0 then r:="00110000"; elsif row=1 then r:="01110000"; elsif row>=2 and row<=5 then r:="00110000"; elsif row=6 then r:="11111100"; end if;
      when x"32" => if row=0 then r:="01111100"; elsif row=1 then r:="11000110"; elsif row=2 then r:="00000110"; elsif row=3 then r:="00011100"; elsif row=4 then r:="01110000"; elsif row=5 then r:="11000000"; elsif row=6 then r:="11111110"; end if;
      when x"33" => if row=0 then r:="01111100"; elsif row=1 then r:="11000110"; elsif row=2 or row=3 then r:="00001100"; elsif row=4 then r:="00000110"; elsif row=5 then r:="11000110"; elsif row=6 then r:="01111100"; end if;
      when x"34" => if row=0 then r:="00011100"; elsif row=1 then r:="00111100"; elsif row=2 then r:="01101100"; elsif row=3 then r:="11001100"; elsif row=4 then r:="11111110"; elsif row=5 or row=6 then r:="00001100"; end if;
      when x"35" => if row=0 then r:="11111110"; elsif row=1 then r:="11000000"; elsif row=2 then r:="11111100"; elsif row=3 or row=4 then r:="00000110"; elsif row=5 then r:="11000110"; elsif row=6 then r:="01111100"; end if;
      when x"36" => if row=0 then r:="00111100"; elsif row=1 then r:="01100000"; elsif row=2 then r:="11000000"; elsif row=3 then r:="11111100"; elsif row=4 or row=5 then r:="11000110"; elsif row=6 then r:="01111100"; end if;
      when x"37" => if row=0 then r:="11111110"; elsif row=1 then r:="00000110"; elsif row=2 then r:="00001100"; elsif row=3 then r:="00011000"; elsif row=4 or row=5 or row=6 then r:="00110000"; end if;
      when x"38" => if row=0 or row=3 or row=6 then r:="01111100"; elsif row=1 or row=2 or row=4 or row=5 then r:="11000110"; end if;
      when x"39" => if row=0 then r:="01111100"; elsif row=1 or row=2 then r:="11000110"; elsif row=3 then r:="01111110"; elsif row=4 then r:="00000110"; elsif row=5 then r:="00001100"; elsif row=6 then r:="01111000"; end if;
      when others => r := "00000000";
    end case;
    return r;
  end function;

begin
  -- tick 64Hz
  process(clk50)
  begin
    if rising_edge(clk50) then
      if reset='1' then
        div_cnt <= 0; sample_tick <= '0';
      else
        if div_cnt = DIV_TICKS-1 then
          div_cnt <= 0; sample_tick <= '1';
        else
          div_cnt <= div_cnt + 1; sample_tick <= '0';
        end if;
      end if;
    end if;
  end process;

  -- RAM: el graph TRUNCA aqu (13 MSB)
  process(clk50)
    variable v13_now : unsigned(12 downto 0);
  begin
    if rising_edge(clk50) then
      if reset='1' then
        wr_ptr <= 0;
      elsif sample_tick='1' then
        v13_now := unsigned(raw24_in(23 downto 11));
        ram(wr_ptr) <= v13_now;
        if wr_ptr = N_SAMPLES-1 then wr_ptr <= 0; else wr_ptr <= wr_ptr + 1; end if;
      end if;
    end if;
  end process;

  -- raw24 unsigned -> BCD 8 dgitos (double dabble sin slices variables)
  process(raw24_in)
    variable mag : unsigned(23 downto 0);
    variable td7,td6,td5,td4,td3,td2,td1,td0 : unsigned(3 downto 0);
  begin
    mag := unsigned(raw24_in);
    td7:=(others=>'0'); td6:=(others=>'0'); td5:=(others=>'0'); td4:=(others=>'0');
    td3:=(others=>'0'); td2:=(others=>'0'); td1:=(others=>'0'); td0:=(others=>'0');

    for i in 23 downto 0 loop
      if td7>=5 then td7:=td7+3; end if;
      if td6>=5 then td6:=td6+3; end if;
      if td5>=5 then td5:=td5+3; end if;
      if td4>=5 then td4:=td4+3; end if;
      if td3>=5 then td3:=td3+3; end if;
      if td2>=5 then td2:=td2+3; end if;
      if td1>=5 then td1:=td1+3; end if;
      if td0>=5 then td0:=td0+3; end if;

      td7 := td7(2 downto 0) & td6(3);
      td6 := td6(2 downto 0) & td5(3);
      td5 := td5(2 downto 0) & td4(3);
      td4 := td4(2 downto 0) & td3(3);
      td3 := td3(2 downto 0) & td2(3);
      td2 := td2(2 downto 0) & td1(3);
      td1 := td1(2 downto 0) & td0(3);
      td0 := td0(2 downto 0) & mag(i);
    end loop;

    d7<=td7; d6<=td6; d5<=td5; d4<=td4; d3<=td3; d2<=td2; d1<=td1; d0<=td0;
  end process;

  -- render VGA: fondo blanco, lnea azul 2px, texto negro "RAW= 12345678"
  process(pixel_row, pixel_col, ram, wr_ptr, d7,d6,d5,d4,d3,d2,d1,d0)
    variable x,y : integer;
    variable idx,s : integer;
    variable val13,y_pix : integer;

    variable char_i,col_i,row_i : integer;
    variable ascii : std_logic_vector(7 downto 0);
    variable bits  : std_logic_vector(7 downto 0);
    variable text_on : boolean;

    variable show7,show6,show5,show4,show3,show2,show1 : boolean;
    variable dig : unsigned(3 downto 0);
  begin
    x := to_integer(unsigned(pixel_col));
    y := to_integer(unsigned(pixel_row));

    red<='1'; green<='1'; blue<='1';

    if x < H_ACTIVE and y < V_ACTIVE then
      idx := wr_ptr + x;
      if idx >= N_SAMPLES then s := idx - N_SAMPLES; else s := idx; end if;

      val13 := to_integer(ram(s)); -- 0..8191
      y_pix := (V_ACTIVE-1) - ((val13 * V_ACTIVE) / 8192);

      if (y = y_pix) or (y = y_pix-1) then
        red<='0'; green<='0'; blue<='1';
      end if;

      -- texto 13 chars = 104 px
      text_on := false;
      if (y < 8) and (x < 104) then
        char_i := x / 8;
        col_i  := x mod 8;
        row_i  := y;

        show7 := (d7 /= 0);
        show6 := show7 or (d6 /= 0);
        show5 := show6 or (d5 /= 0);
        show4 := show5 or (d4 /= 0);
        show3 := show4 or (d3 /= 0);
        show2 := show3 or (d2 /= 0);
        show1 := show2 or (d1 /= 0);

        if char_i=0 then ascii:=x"52";
        elsif char_i=1 then ascii:=x"41";
        elsif char_i=2 then ascii:=x"57";
        elsif char_i=3 then ascii:=x"3D";
        elsif char_i=4 then ascii:=x"20";
        else
          case char_i is
            when 5  => dig:=d7; if not show7 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 6  => dig:=d6; if not show6 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 7  => dig:=d5; if not show5 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 8  => dig:=d4; if not show4 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 9  => dig:=d3; if not show3 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 10 => dig:=d2; if not show2 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 11 => dig:=d1; if not show1 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when others => dig:=d0; ascii:=to_ascii_digit(dig);
          end case;
        end if;

        bits := font_row(ascii, row_i);
        if bits(7-col_i)='1' then text_on := true; end if;

        if text_on then
          red<='0'; green<='0'; blue<='0';
        end if;
      end if;
    end if;
  end process;

end architecture;


