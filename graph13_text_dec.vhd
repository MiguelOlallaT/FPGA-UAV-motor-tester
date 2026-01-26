library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graph13_text_dec is
  port(
    clk50     : in  std_logic;

    par_centi : in  std_logic_vector(31 downto 0);
    peso_deci : in  std_logic_vector(31 downto 0);

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
  constant TEXT_H    : integer := 16;
  constant TOP_GAP   : integer := 6;
  constant TIME_H    : integer := 12;
  constant AXIS_GAP  : integer := 8;
  constant LEFT_MARGIN  : integer := 70;
  constant RIGHT_MARGIN : integer := 70;
  constant GRAPH_W   : integer := H_ACTIVE - LEFT_MARGIN - RIGHT_MARGIN;
  constant GRAPH_H   : integer := V_ACTIVE - TEXT_H - TOP_GAP - TIME_H - AXIS_GAP;
  constant GRAPH_TOP : integer := TEXT_H + TOP_GAP;
  constant GRAPH_BOT : integer := GRAPH_TOP + GRAPH_H - 1;
  constant CLK_HZ    : integer := 50_000_000;
  constant SAMPLE_HZ : integer := 50;
  constant N_SAMPLES : integer := GRAPH_W;
  constant DIV_TICKS : integer := CLK_HZ / SAMPLE_HZ;
  constant SCALE_SHIFT : integer := 14;
  constant PAR_SCALE_K  : integer := (GRAPH_H-1) * (2**SCALE_SHIFT) / 2000;
  constant PESO_SCALE_K : integer := (GRAPH_H-1) * (2**SCALE_SHIFT) / 100000;
  constant LEFT_LABEL_X  : integer := 0;
  constant RIGHT_LABEL_X : integer := LEFT_MARGIN + GRAPH_W + 2;
  constant LABEL_W_L     : integer := LEFT_MARGIN - 2;
  constant LABEL_W_R     : integer := RIGHT_MARGIN - 2;
  constant TIME_Y        : integer := GRAPH_BOT + AXIS_GAP + 1;
  constant TIME_X0  : integer := LEFT_MARGIN;
  constant TIME_X2  : integer := LEFT_MARGIN + (GRAPH_W * 1) / 5;
  constant TIME_X4  : integer := LEFT_MARGIN + (GRAPH_W * 2) / 5;
  constant TIME_X6  : integer := LEFT_MARGIN + (GRAPH_W * 3) / 5;
  constant TIME_X8  : integer := LEFT_MARGIN + (GRAPH_W * 4) / 5;
  constant TIME_X10 : integer := LEFT_MARGIN + GRAPH_W - 24;

  constant TICK_Y10 : integer := GRAPH_TOP;
  constant TICK_Y9  : integer := GRAPH_TOP + ((GRAPH_H-1) * 1) / 10;
  constant TICK_Y8  : integer := GRAPH_TOP + ((GRAPH_H-1) * 2) / 10;
  constant TICK_Y7  : integer := GRAPH_TOP + ((GRAPH_H-1) * 3) / 10;
  constant TICK_Y6  : integer := GRAPH_TOP + ((GRAPH_H-1) * 4) / 10;
  constant TICK_Y5  : integer := GRAPH_TOP + ((GRAPH_H-1) * 5) / 10;
  constant TICK_Y4  : integer := GRAPH_TOP + ((GRAPH_H-1) * 6) / 10;
  constant TICK_Y3  : integer := GRAPH_TOP + ((GRAPH_H-1) * 7) / 10;
  constant TICK_Y2  : integer := GRAPH_TOP + ((GRAPH_H-1) * 8) / 10;
  constant TICK_Y1  : integer := GRAPH_TOP + ((GRAPH_H-1) * 9) / 10;
  constant TICK_Y0  : integer := GRAPH_BOT;

  type ram_t is array (0 to N_SAMPLES-1) of unsigned(8 downto 0);
  signal ram_par  : ram_t;
  signal ram_peso : ram_t;
  signal wr_ptr   : integer range 0 to N_SAMPLES-1 := 0;

  signal div_cnt     : integer range 0 to DIV_TICKS-1 := 0;
  signal sample_tick : std_logic := '0';

  function to_ascii_digit(d : unsigned(3 downto 0)) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(48 + to_integer(d), 8));
  end function;

  function to_bcd6(raw : unsigned(19 downto 0)) return std_logic_vector is
    variable mag : unsigned(19 downto 0);
    variable td5,td4,td3,td2,td1,td0 : unsigned(3 downto 0);
  begin
    mag := raw;
    td5:=(others=>'0'); td4:=(others=>'0'); td3:=(others=>'0'); td2:=(others=>'0'); td1:=(others=>'0'); td0:=(others=>'0');

    for i in 19 downto 0 loop
      if td5>=5 then td5:=td5+3; end if;
      if td4>=5 then td4:=td4+3; end if;
      if td3>=5 then td3:=td3+3; end if;
      if td2>=5 then td2:=td2+3; end if;
      if td1>=5 then td1:=td1+3; end if;
      if td0>=5 then td0:=td0+3; end if;

      td5 := td5(2 downto 0) & td4(3);
      td4 := td4(2 downto 0) & td3(3);
      td3 := td3(2 downto 0) & td2(3);
      td2 := td2(2 downto 0) & td1(3);
      td1 := td1(2 downto 0) & td0(3);
      td0 := td0(2 downto 0) & mag(i);
    end loop;

    return std_logic_vector(unsigned'(td5 & td4 & td3 & td2 & td1 & td0));
  end function;

  function font_row(ascii : std_logic_vector(7 downto 0); row : integer) return std_logic_vector is
    variable r : std_logic_vector(7 downto 0);
  begin
    r := (others => '0');
    case ascii is
      when x"20" => r := "00000000";
      when x"2B" => if row=1 or row=2 or row=4 or row=5 then r:="00011000"; elsif row=3 then r:="01111110"; end if;
      when x"2D" => if row=3 then r:="01111110"; end if;
      when x"2E" => if row=6 then r:="00011000"; end if;
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
      when x"41" => if row=0 then r:="00111000"; elsif row=1 then r:="01101100"; elsif row=2 then r:="11000110"; elsif row=3 then r:="11111110"; elsif row=4 or row=5 or row=6 then r:="11000110"; end if;
      when x"45" => if row=0 then r:="11111110"; elsif row=1 then r:="11000000"; elsif row=2 then r:="11000000"; elsif row=3 then r:="11111100"; elsif row=4 then r:="11000000"; elsif row=5 then r:="11000000"; elsif row=6 then r:="11111110"; end if;
      when x"47" => if row=0 then r:="01111100"; elsif row=1 then r:="11000110"; elsif row=2 then r:="11000000"; elsif row=3 then r:="11011110"; elsif row=4 then r:="11000110"; elsif row=5 then r:="11000110"; elsif row=6 then r:="01111100"; end if;
      when x"4D" => if row=0 then r:="11000110"; elsif row=1 then r:="11101110"; elsif row=2 then r:="11111110"; elsif row=3 then r:="11010110"; elsif row=4 or row=5 or row=6 then r:="11000110"; end if;
      when x"4E" => if row=0 then r:="11000110"; elsif row=1 then r:="11100110"; elsif row=2 then r:="11110110"; elsif row=3 then r:="11011110"; elsif row=4 then r:="11001110"; elsif row=5 or row=6 then r:="11000110"; end if;
      when x"4F" => if row=0 then r:="01111100"; elsif row=1 or row=2 or row=3 or row=4 or row=5 then r:="11000110"; elsif row=6 then r:="01111100"; end if;
      when x"50" => if row=0 then r:="11111100"; elsif row=1 or row=2 then r:="11000110"; elsif row=3 then r:="11111100"; elsif row=4 or row=5 or row=6 then r:="11000000"; end if;
      when x"52" => if row=0 then r:="11111100"; elsif row=1 or row=2 then r:="11000110"; elsif row=3 then r:="11111100"; elsif row=4 then r:="11011000"; elsif row=5 then r:="11001100"; elsif row=6 then r:="11000110"; end if;
      when x"53" => if row=0 then r:="01111100"; elsif row=1 then r:="11000000"; elsif row=2 then r:="11000000"; elsif row=3 then r:="01111100"; elsif row=4 then r:="00000110"; elsif row=5 then r:="00000110"; elsif row=6 then r:="11111100"; end if;
      when x"4B" => if row=0 then r:="11000110"; elsif row=1 then r:="11001100"; elsif row=2 then r:="11011000"; elsif row=3 then r:="11110000"; elsif row=4 then r:="11011000"; elsif row=5 then r:="11001100"; elsif row=6 then r:="11000110"; end if;
      when x"73" => if row=1 then r:="01111100"; elsif row=2 then r:="11000000"; elsif row=3 then r:="01111100"; elsif row=4 then r:="00000110"; elsif row=5 then r:="11111100"; end if;
      when others => r := "00000000";
    end case;
    return r;
  end function;

  signal par_bcd  : std_logic_vector(23 downto 0) := (others => '0');
  signal peso_bcd : std_logic_vector(23 downto 0) := (others => '0');
  signal par_neg  : std_logic := '0';
  signal peso_neg : std_logic := '0';

begin

  process(clk50)
    variable par_s  : signed(31 downto 0);
    variable peso_s : signed(31 downto 0);
    variable par_abs  : unsigned(31 downto 0);
    variable peso_abs : unsigned(31 downto 0);
    variable par_lim  : unsigned(19 downto 0);
    variable peso_lim : unsigned(19 downto 0);
    variable par_norm : integer;
    variable peso_norm : integer;
    variable par_y : integer;
    variable peso_y : integer;
  begin
    if rising_edge(clk50) then
      if div_cnt = DIV_TICKS-1 then
        div_cnt <= 0; sample_tick <= '1';
      else
        div_cnt <= div_cnt + 1; sample_tick <= '0';
      end if;

      par_s := signed(par_centi);
      peso_s := signed(peso_deci);

      par_neg  <= par_s(31);
      peso_neg <= peso_s(31);

      if par_s(31) = '1' then
        par_abs := unsigned(-par_s);
      else
        par_abs := unsigned(par_s);
      end if;

      if peso_s(31) = '1' then
        peso_abs := unsigned(-peso_s);
      else
        peso_abs := unsigned(peso_s);
      end if;

      if par_abs > to_unsigned(2000, 32) then
        par_lim := to_unsigned(2000, 20);
      else
        par_lim := par_abs(19 downto 0);
      end if;

      if peso_abs > to_unsigned(100000, 32) then
        peso_lim := to_unsigned(100000, 20);
      else
        peso_lim := peso_abs(19 downto 0);
      end if;

        par_bcd  <= to_bcd6(par_lim);
        peso_bcd <= to_bcd6(peso_lim);

        if sample_tick = '1' then
          par_norm := to_integer(par_s);
          if par_norm > 2000 then
            par_norm := 2000;
          elsif par_norm < 0 then
            par_norm := 0;
          end if;

          peso_norm := to_integer(peso_s);
          if peso_norm > 100000 then
            peso_norm := 100000;
          elsif peso_norm < 0 then
            peso_norm := 0;
          end if;

          par_y := (GRAPH_H-1) - ((par_norm * PAR_SCALE_K) / (2**SCALE_SHIFT));
          peso_y := (GRAPH_H-1) - ((peso_norm * PESO_SCALE_K) / (2**SCALE_SHIFT));

          ram_par(wr_ptr) <= to_unsigned(par_y, 9);
          ram_peso(wr_ptr) <= to_unsigned(peso_y, 9);

          if wr_ptr = N_SAMPLES-1 then
            wr_ptr <= 0;
          else
            wr_ptr <= wr_ptr + 1;
          end if;
        end if;
    end if;
  end process;

  process(pixel_row, pixel_col, ram_par, ram_peso, wr_ptr, par_bcd, peso_bcd, par_neg, peso_neg)
    variable x,y : integer;
    variable idx,s : integer;
    variable y_par,y_peso : integer;
    variable x_graph : integer;
    variable s_prev : integer;
    variable y_prev_par,y_prev_peso : integer;
    variable y_line_par,y_line_peso : integer;
    variable y_min,y_max : integer;
    variable row_i,col_i,char_i,line_i : integer;
    variable ascii : std_logic_vector(7 downto 0);
    variable bits  : std_logic_vector(7 downto 0);
    variable text_on : boolean;
    variable label_on : boolean;

    variable d5,d4,d3,d2,d1,d0 : unsigned(3 downto 0);
    variable show5,show4,show3,show2 : boolean;
    variable color_r,color_g,color_b : std_logic;
  begin
    x := to_integer(unsigned(pixel_col));
    y := to_integer(unsigned(pixel_row));

    red<='1'; green<='1'; blue<='1';

    if x < H_ACTIVE and y < V_ACTIVE then
      if y < TEXT_H then
        text_on := false;
        line_i := y / 8;
        row_i  := y mod 8;
        char_i := x / 8;
        col_i  := x mod 8;

        if line_i = 0 then
          d5 := unsigned(par_bcd(23 downto 20));
          d4 := unsigned(par_bcd(19 downto 16));
          d3 := unsigned(par_bcd(15 downto 12));
          d2 := unsigned(par_bcd(11 downto 8));
          d1 := unsigned(par_bcd(7 downto 4));
          d0 := unsigned(par_bcd(3 downto 0));

          show5 := (d3 /= 0);
          show4 := show5 or (d2 /= 0);
          show3 := show4 or (d1 /= 0);
          show2 := show3 or (d0 /= 0);

          case char_i is
            when 0 => ascii:=x"50";
            when 1 => ascii:=x"41";
            when 2 => ascii:=x"52";
            when 3 => ascii:=x"3D";
            when 4 => if par_neg='1' then ascii:=x"2D"; else ascii:=x"2B"; end if;
            when 5 => if not show5 then ascii:=x"20"; else ascii:=to_ascii_digit(d3); end if;
            when 6 => if not show4 then ascii:=x"20"; else ascii:=to_ascii_digit(d2); end if;
            when 7 => ascii:=x"2E";
            when 8 => ascii:=to_ascii_digit(d1);
            when 9 => ascii:=to_ascii_digit(d0);
            when 10 => ascii:=x"4E";
            when 11 => ascii:=x"4D";
            when others => ascii:=x"20";
          end case;
          color_r := '1'; color_g := '0'; color_b := '0';
        else
          d5 := unsigned(peso_bcd(23 downto 20));
          d4 := unsigned(peso_bcd(19 downto 16));
          d3 := unsigned(peso_bcd(15 downto 12));
          d2 := unsigned(peso_bcd(11 downto 8));
          d1 := unsigned(peso_bcd(7 downto 4));
          d0 := unsigned(peso_bcd(3 downto 0));

          show5 := (d4 /= 0);
          show4 := show5 or (d3 /= 0);
          show3 := show4 or (d2 /= 0);
          show2 := show3 or (d1 /= 0);

          case char_i is
            when 0 => ascii:=x"50";
            when 1 => ascii:=x"45";
            when 2 => ascii:=x"53";
            when 3 => ascii:=x"4F";
            when 4 => ascii:=x"3D";
            when 5 => if peso_neg='1' then ascii:=x"2D"; else ascii:=x"2B"; end if;
            when 6 => if not show5 then ascii:=x"20"; else ascii:=to_ascii_digit(d4); end if;
            when 7 => if not show4 then ascii:=x"20"; else ascii:=to_ascii_digit(d3); end if;
            when 8 => if not show3 then ascii:=x"20"; else ascii:=to_ascii_digit(d2); end if;
            when 9 => if not show2 then ascii:=x"20"; else ascii:=to_ascii_digit(d1); end if;
            when 10 => ascii:=x"2E";
            when 11 => ascii:=to_ascii_digit(d0);
            when 12 => ascii:=x"47";
            when others => ascii:=x"20";
          end case;
          color_r := '0'; color_g := '0'; color_b := '1';
        end if;

        if (line_i = 0 and x < 96) or (line_i = 1 and x < 104) then
          bits := font_row(ascii, row_i);
          if bits(7-col_i)='1' then text_on := true; end if;
        else
          text_on := false;
        end if;

        if text_on then
          red <= color_r; green <= color_g; blue <= color_b;
        end if;
      else
        label_on := false;

        if (y >= TIME_Y) and (y < V_ACTIVE) then
          row_i := y - TIME_Y;
          if (x >= TIME_X0) and (x < TIME_X0 + 16) then
            char_i := (x-TIME_X0) / 8;
            col_i := (x-TIME_X0) mod 8;
            if char_i = 0 then ascii := x"30"; else ascii := x"73"; end if;
            label_on := true;
          elsif (x >= TIME_X2) and (x < TIME_X2 + 16) then
            char_i := (x-TIME_X2) / 8;
            col_i := (x-TIME_X2) mod 8;
            if char_i = 0 then ascii := x"32"; else ascii := x"73"; end if;
            label_on := true;
          elsif (x >= TIME_X4) and (x < TIME_X4 + 16) then
            char_i := (x-TIME_X4) / 8;
            col_i := (x-TIME_X4) mod 8;
            if char_i = 0 then ascii := x"34"; else ascii := x"73"; end if;
            label_on := true;
          elsif (x >= TIME_X6) and (x < TIME_X6 + 16) then
            char_i := (x-TIME_X6) / 8;
            col_i := (x-TIME_X6) mod 8;
            if char_i = 0 then ascii := x"36"; else ascii := x"73"; end if;
            label_on := true;
          elsif (x >= TIME_X8) and (x < TIME_X8 + 16) then
            char_i := (x-TIME_X8) / 8;
            col_i := (x-TIME_X8) mod 8;
            if char_i = 0 then ascii := x"38"; else ascii := x"73"; end if;
            label_on := true;
          elsif (x >= TIME_X10) and (x < TIME_X10 + 24) then
            char_i := (x-TIME_X10) / 8;
            col_i := (x-TIME_X10) mod 8;
            if char_i = 0 then
              ascii := x"31";
            elsif char_i = 1 then
              ascii := x"30";
            else
              ascii := x"73";
            end if;
            label_on := true;
          end if;

          if label_on then
            bits := font_row(ascii, row_i);
            if bits(7-col_i)='1' then
              red <= '0'; green <= '0'; blue <= '0';
            end if;
          end if;
        elsif (x >= LEFT_LABEL_X) and (x < LEFT_LABEL_X + LABEL_W_L) then
          label_on := false;
          char_i := (x-LEFT_LABEL_X) / 8;
          col_i := (x-LEFT_LABEL_X) mod 8;
          if (y >= TICK_Y10) and (y < TICK_Y10 + 8) then
            row_i := y - TICK_Y10;
            case char_i is
              when 0 => ascii:=x"32";
              when 1 => ascii:=x"30";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y9) and (y < TICK_Y9 + 8) then
            row_i := y - TICK_Y9;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"38";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y8) and (y < TICK_Y8 + 8) then
            row_i := y - TICK_Y8;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"36";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y7) and (y < TICK_Y7 + 8) then
            row_i := y - TICK_Y7;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"34";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y6) and (y < TICK_Y6 + 8) then
            row_i := y - TICK_Y6;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"32";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y5) and (y < TICK_Y5 + 8) then
            row_i := y - TICK_Y5;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"30";
              when 2 => ascii:=x"4E";
              when 3 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y4) and (y < TICK_Y4 + 8) then
            row_i := y - TICK_Y4;
            case char_i is
              when 0 => ascii:=x"38";
              when 1 => ascii:=x"4E";
              when 2 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y3) and (y < TICK_Y3 + 8) then
            row_i := y - TICK_Y3;
            case char_i is
              when 0 => ascii:=x"36";
              when 1 => ascii:=x"4E";
              when 2 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y2) and (y < TICK_Y2 + 8) then
            row_i := y - TICK_Y2;
            case char_i is
              when 0 => ascii:=x"34";
              when 1 => ascii:=x"4E";
              when 2 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y1) and (y < TICK_Y1 + 8) then
            row_i := y - TICK_Y1;
            case char_i is
              when 0 => ascii:=x"32";
              when 1 => ascii:=x"4E";
              when 2 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y0) and (y < TICK_Y0 + 8) then
            row_i := y - TICK_Y0;
            case char_i is
              when 0 => ascii:=x"30";
              when 1 => ascii:=x"4E";
              when 2 => ascii:=x"4D";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          end if;

          if label_on then
            bits := font_row(ascii, row_i);
            if bits(7-col_i)='1' then
              red <= '1'; green <= '0'; blue <= '0';
            end if;
          end if;
        elsif (x >= RIGHT_LABEL_X) and (x < RIGHT_LABEL_X + LABEL_W_R) then
          label_on := false;
          char_i := (x-RIGHT_LABEL_X) / 8;
          col_i := (x-RIGHT_LABEL_X) mod 8;
          if (y >= TICK_Y10) and (y < TICK_Y10 + 8) then
            row_i := y - TICK_Y10;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"30";
              when 2 => ascii:=x"4B";
              when 3 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y9) and (y < TICK_Y9 + 8) then
            row_i := y - TICK_Y9;
            case char_i is
              when 0 => ascii:=x"39";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y8) and (y < TICK_Y8 + 8) then
            row_i := y - TICK_Y8;
            case char_i is
              when 0 => ascii:=x"38";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y7) and (y < TICK_Y7 + 8) then
            row_i := y - TICK_Y7;
            case char_i is
              when 0 => ascii:=x"37";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y6) and (y < TICK_Y6 + 8) then
            row_i := y - TICK_Y6;
            case char_i is
              when 0 => ascii:=x"36";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y5) and (y < TICK_Y5 + 8) then
            row_i := y - TICK_Y5;
            case char_i is
              when 0 => ascii:=x"35";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y4) and (y < TICK_Y4 + 8) then
            row_i := y - TICK_Y4;
            case char_i is
              when 0 => ascii:=x"34";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y3) and (y < TICK_Y3 + 8) then
            row_i := y - TICK_Y3;
            case char_i is
              when 0 => ascii:=x"33";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y2) and (y < TICK_Y2 + 8) then
            row_i := y - TICK_Y2;
            case char_i is
              when 0 => ascii:=x"32";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y1) and (y < TICK_Y1 + 8) then
            row_i := y - TICK_Y1;
            case char_i is
              when 0 => ascii:=x"31";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          elsif (y >= TICK_Y0) and (y < TICK_Y0 + 8) then
            row_i := y - TICK_Y0;
            case char_i is
              when 0 => ascii:=x"30";
              when 1 => ascii:=x"4B";
              when 2 => ascii:=x"47";
              when others => ascii:=x"20";
            end case;
            label_on := true;
          end if;

          if label_on then
            bits := font_row(ascii, row_i);
            if bits(7-col_i)='1' then
              red <= '0'; green <= '0'; blue <= '1';
            end if;
          end if;
        elsif (y = GRAPH_TOP-1) or (y = GRAPH_BOT+1) or (x = LEFT_MARGIN-1) or (x = LEFT_MARGIN+GRAPH_W) then
          red <= '0'; green <= '0'; blue <= '0';
        elsif (y = TICK_Y10) or (y = TICK_Y9) or (y = TICK_Y8) or (y = TICK_Y7) or (y = TICK_Y6) or (y = TICK_Y5) or (y = TICK_Y4) or (y = TICK_Y3) or (y = TICK_Y2) or (y = TICK_Y1) or (y = TICK_Y0) then
          if (x >= LEFT_MARGIN) and (x < LEFT_MARGIN + GRAPH_W) then
            red <= '0'; green <= '0'; blue <= '0';
          end if;
        elsif (x >= LEFT_MARGIN) and (x < LEFT_MARGIN + GRAPH_W) and (x mod 64 = 0) and (y >= GRAPH_TOP) and (y <= GRAPH_BOT) then
          red <= '0'; green <= '0'; blue <= '0';
        else
          if (x >= LEFT_MARGIN) and (x < LEFT_MARGIN + GRAPH_W) and (y >= GRAPH_TOP) and (y <= GRAPH_BOT) then
            x_graph := x - LEFT_MARGIN;
            idx := wr_ptr + x_graph;
            if idx >= N_SAMPLES then s := idx - N_SAMPLES; else s := idx; end if;

            if s = 0 then
              s_prev := N_SAMPLES-1;
            else
              s_prev := s - 1;
            end if;

            y_line_par := GRAPH_TOP + to_integer(ram_par(s));
            y_line_peso := GRAPH_TOP + to_integer(ram_peso(s));
            y_prev_par := GRAPH_TOP + to_integer(ram_par(s_prev));
            y_prev_peso := GRAPH_TOP + to_integer(ram_peso(s_prev));

            if y >= GRAPH_TOP and y <= GRAPH_BOT then
              y_min := y_prev_par;
              y_max := y_line_par;
              if y_min > y_max then
                y_min := y_line_par;
                y_max := y_prev_par;
              end if;
              if (y >= y_min-1 and y <= y_max+1) then
                red <= '1'; green <= '0'; blue <= '0';
              end if;

              y_min := y_prev_peso;
              y_max := y_line_peso;
              if y_min > y_max then
                y_min := y_line_peso;
                y_max := y_prev_peso;
              end if;
              if (y >= y_min-1 and y <= y_max+1) then
                red <= '0'; green <= '0'; blue <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;
