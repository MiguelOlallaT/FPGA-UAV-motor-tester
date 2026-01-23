library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graph13_text_dec is
  port(
    clk50     : in  std_logic;
    reset     : in  std_logic;

    raw24_in0 : in  std_logic_vector(23 downto 0);
    raw24_in1 : in  std_logic_vector(23 downto 0);
    raw24_in2 : in  std_logic_vector(23 downto 0);
    raw24_in3 : in  std_logic_vector(23 downto 0);
    raw24_in4 : in  std_logic_vector(23 downto 0);
    raw24_in5 : in  std_logic_vector(23 downto 0);

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

  function to_ascii_digit(d : unsigned(3 downto 0)) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(48 + to_integer(d), 8));
  end function;

  function to_bcd8(raw : std_logic_vector(23 downto 0)) return std_logic_vector is
    variable mag : unsigned(23 downto 0);
    variable td7,td6,td5,td4,td3,td2,td1,td0 : unsigned(3 downto 0);
  begin
    mag := unsigned(raw);
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

    return std_logic_vector(td7 & td6 & td5 & td4 & td3 & td2 & td1 & td0);
  end function;

  function font_row(ascii : std_logic_vector(7 downto 0); row : integer) return std_logic_vector is
    variable r : std_logic_vector(7 downto 0);
  begin
    r := (others => '0');
    case ascii is
      when x"20" => r := "00000000";
      when x"52" => if row=0 then r:="11111100"; elsif row=1 or row=2 then r:="11000110"; elsif row=3 then r:="11111100"; elsif row=4 then r:="11011000"; elsif row=5 then r:="11001100"; elsif row=6 then r:="11000110"; end if;
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

  signal bcd0 : std_logic_vector(31 downto 0);
  signal bcd1 : std_logic_vector(31 downto 0);
  signal bcd2 : std_logic_vector(31 downto 0);
  signal bcd3 : std_logic_vector(31 downto 0);
  signal bcd4 : std_logic_vector(31 downto 0);
  signal bcd5 : std_logic_vector(31 downto 0);

begin

  bcd0 <= to_bcd8(raw24_in0);
  bcd1 <= to_bcd8(raw24_in1);
  bcd2 <= to_bcd8(raw24_in2);
  bcd3 <= to_bcd8(raw24_in3);
  bcd4 <= to_bcd8(raw24_in4);
  bcd5 <= to_bcd8(raw24_in5);

  process(pixel_row, pixel_col, bcd0, bcd1, bcd2, bcd3, bcd4, bcd5)
    variable x,y : integer;
    variable row_i,col_i,char_i,line_i : integer;
    variable ascii : std_logic_vector(7 downto 0);
    variable bits  : std_logic_vector(7 downto 0);
    variable text_on : boolean;
    variable bcd : std_logic_vector(31 downto 0);
    variable d7,d6,d5,d4,d3,d2,d1,d0 : unsigned(3 downto 0);
    variable show7,show6,show5,show4,show3,show2,show1 : boolean;
    variable dig : unsigned(3 downto 0);
  begin
    x := to_integer(unsigned(pixel_col));
    y := to_integer(unsigned(pixel_row));

    red<='1'; green<='1'; blue<='1';

    if x < H_ACTIVE and y < V_ACTIVE then
      text_on := false;
      if (y < 48) and (x < 88) then
        line_i := y / 8;
        row_i  := y mod 8;
        char_i := x / 8;
        col_i  := x mod 8;

        case line_i is
          when 0 => bcd := bcd0;
          when 1 => bcd := bcd1;
          when 2 => bcd := bcd2;
          when 3 => bcd := bcd3;
          when 4 => bcd := bcd4;
          when others => bcd := bcd5;
        end case;

        d7 := unsigned(bcd(31 downto 28));
        d6 := unsigned(bcd(27 downto 24));
        d5 := unsigned(bcd(23 downto 20));
        d4 := unsigned(bcd(19 downto 16));
        d3 := unsigned(bcd(15 downto 12));
        d2 := unsigned(bcd(11 downto 8));
        d1 := unsigned(bcd(7 downto 4));
        d0 := unsigned(bcd(3 downto 0));

        show7 := (d7 /= 0);
        show6 := show7 or (d6 /= 0);
        show5 := show6 or (d5 /= 0);
        show4 := show5 or (d4 /= 0);
        show3 := show4 or (d3 /= 0);
        show2 := show3 or (d2 /= 0);
        show1 := show2 or (d1 /= 0);

        if char_i=0 then
          ascii:=x"52";
        elsif char_i=1 then
          ascii:=to_ascii_digit(to_unsigned(line_i,4));
        elsif char_i=2 then
          ascii:=x"3D";
        else
          case char_i is
            when 3  => dig:=d7; if not show7 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 4  => dig:=d6; if not show6 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 5  => dig:=d5; if not show5 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 6  => dig:=d4; if not show4 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 7  => dig:=d3; if not show3 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 8  => dig:=d2; if not show2 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
            when 9  => dig:=d1; if not show1 then ascii:=x"20"; else ascii:=to_ascii_digit(dig); end if;
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
