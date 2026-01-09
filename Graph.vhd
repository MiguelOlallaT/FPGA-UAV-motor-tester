library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity graph is
  generic(
    CLK_HZ      : integer := 50_000_000;
    SAMPLE_HZ   : integer := 64;         -- 64 muestras/s
    WIN_SEC     : integer := 10;         -- 10 s
    H_ACTIVE    : integer := 640;
    V_ACTIVE    : integer := 480
  );
  port(
    clk50       : in  std_logic;
    reset       : in  std_logic;

    value_in    : in  std_logic_vector(7 downto 0);

    pixel_row   : in  std_logic_vector(9 downto 0);
    pixel_col   : in  std_logic_vector(9 downto 0);

    red         : out std_logic;
    green       : out std_logic;
    blue        : out std_logic
  );
end entity;

architecture rtl of graph is

  constant N_SAMPLES : integer := SAMPLE_HZ * WIN_SEC;  -- 640

  type ram_t is array (0 to N_SAMPLES-1) of unsigned(7 downto 0);
  signal ram : ram_t;

  signal wr_ptr : integer range 0 to N_SAMPLES-1 := 0;

  constant DIV_TICKS : integer := CLK_HZ / SAMPLE_HZ; -- 781250
  signal div_cnt     : integer range 0 to DIV_TICKS-1 := 0;
  signal sample_tick : std_logic := '0';

begin

  -- Tick de muestreo
  process(clk50)
  begin
    if rising_edge(clk50) then
      if reset = '1' then
        div_cnt     <= 0;
        sample_tick <= '0';
      else
        if div_cnt = DIV_TICKS-1 then
          div_cnt     <= 0;
          sample_tick <= '1';
        else
          div_cnt     <= div_cnt + 1;
          sample_tick <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Muestreo + buffer circular
  process(clk50)
  begin
    if rising_edge(clk50) then
      if reset = '1' then
        wr_ptr <= 0;
      elsif sample_tick = '1' then
        ram(wr_ptr) <= unsigned(value_in);

        if wr_ptr = N_SAMPLES-1 then
          wr_ptr <= 0;
        else
          wr_ptr <= wr_ptr + 1;
        end if;
      end if;
    end if;
  end process;

  -- Render (fondo blanco, línea azul, grosor 2px como tu último)
  process(pixel_row, pixel_col, ram, wr_ptr)
    variable x, y     : integer;
    variable idx_in_w : integer; -- 0..639
    variable tmp_idx  : integer;
    variable samp_idx : integer;
    variable val      : integer; -- 0..255
    variable y_pix    : integer; -- 0..479
  begin
    x := to_integer(unsigned(pixel_col));
    y := to_integer(unsigned(pixel_row));

    -- fondo blanco
    red   <= '1';
    green <= '1';
    blue  <= '1';

    if (x < H_ACTIVE and y < V_ACTIVE) then
      idx_in_w := x;

      tmp_idx := wr_ptr + idx_in_w;
      if tmp_idx >= N_SAMPLES then
        samp_idx := tmp_idx - N_SAMPLES;
      else
        samp_idx := tmp_idx;
      end if;

      val := to_integer(ram(samp_idx));

      y_pix := (V_ACTIVE - 1) - ((val * V_ACTIVE) / 256);
      if y_pix < 0 then y_pix := 0; end if;
      if y_pix > V_ACTIVE-1 then y_pix := V_ACTIVE-1; end if;

      -- línea azul (2px: y_pix y y_pix-1)
      if (y = y_pix) or (y = y_pix-1) then
        red   <= '0';
        green <= '0';
        blue  <= '1';
      end if;
    end if;
  end process;

end architecture;

