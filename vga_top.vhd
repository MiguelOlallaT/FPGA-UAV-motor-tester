library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_top is
  Port (
    clk_50MHz  : in  STD_LOGIC;
    reset      : in  STD_LOGIC;

    -- HX711
    hx_dout    : in  STD_LOGIC;
    hx_sck     : out STD_LOGIC;

    -- VGA
    vga_red    : out STD_LOGIC_VECTOR (2 downto 0);
    vga_green  : out STD_LOGIC_VECTOR (2 downto 0);
    vga_blue   : out STD_LOGIC_VECTOR (1 downto 0);
    vga_hsync  : out STD_LOGIC;
    vga_vsync  : out STD_LOGIC;

    -- 7 segmentos
    seg        : out STD_LOGIC_VECTOR(6 downto 0);
    dp         : out STD_LOGIC;
    an         : out STD_LOGIC_VECTOR(3 downto 0)
  );
end vga_top;

architecture Behavioral of vga_top is

  -- VGA clock
  signal ck_25 : STD_LOGIC := '0';

  -- VGA internals
  signal s_red, s_green, s_blue : STD_LOGIC;
  signal red_o, green_o, blue_o : STD_LOGIC;
  signal pixel_row : STD_LOGIC_VECTOR(9 downto 0);
  signal pixel_col : STD_LOGIC_VECTOR(9 downto 0);

  -- HX711 internal SCK (NO leer el puerto out)
  signal hx_sck_i : std_logic := '0';
  signal hx_dout_ff1, hx_dout_ff2 : std_logic := '1';
  signal hx_dout_sync : std_logic := '1';

  -- HX711 raw signed
  signal raw_s        : signed(23 downto 0) := (others => '0');
  signal sample_valid : std_logic := '0';

  -- RAW standard unsigned 24b
  signal raw_std_u    : unsigned(23 downto 0) := (others => '0');

  -- 13 bits para display
  signal v13_u        : unsigned(12 downto 0) := (others => '0');
  signal v13_sig      : std_logic_vector(12 downto 0);

  -- Bias para raw_std = raw_s + 2^23
  constant BIAS_S25 : signed(24 downto 0) := to_signed(2**23, 25);

  ------------------------------------------------------------------------------
  -- ChipScope signals (preparados; cores comentados)
  ------------------------------------------------------------------------------
  signal CONTROL   : std_logic_vector(35 downto 0);
  signal ILA_DATA  : std_logic_vector(63 downto 0);
  signal ILA_TRIG0 : std_logic_vector(0 downto 0);

begin

  ------------------------------------------------------------------------------
  -- Conectar salida real de SCK al pin
  ------------------------------------------------------------------------------
  hx_sck <= hx_sck_i;

  ------------------------------------------------------------------------------
  -- 50 -> 25 MHz para VGA
  ------------------------------------------------------------------------------
  process(clk_50MHz)
  begin
    if rising_edge(clk_50MHz) then
      ck_25 <= not ck_25;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Sincronizar hx_dout a clk_50MHz (recomendado)
  ------------------------------------------------------------------------------
  process(clk_50MHz)
  begin
    if rising_edge(clk_50MHz) then
      hx_dout_ff1 <= hx_dout;
      hx_dout_ff2 <= hx_dout_ff1;
    end if;
  end process;
  hx_dout_sync <= hx_dout_ff2;

  ------------------------------------------------------------------------------
  -- HX711 reader
  ------------------------------------------------------------------------------
  U_HX: entity work.hx711_reader
    generic map(
      CLK_HZ => 50_000_000,
      SCK_HZ => 50_000
    )
    port map(
      clk          => clk_50MHz,
      reset        => reset,
      hx_dout      => hx_dout_sync,
      hx_sck       => hx_sck_i,
      sample       => raw_s,
      sample_valid => sample_valid
    );

  ------------------------------------------------------------------------------
  -- raw_std = raw_s + 2^23  (tu formato estndar)
  ------------------------------------------------------------------------------
--  process(clk_50MHz)
--    variable raw25  : signed(24 downto 0);
--    variable sum25s : signed(24 downto 0);
--  begin
--    if rising_edge(clk_50MHz) then
--      if reset = '1' then
--        raw_std_u <= (others => '0');
--      elsif sample_valid = '1' then
--        raw25  := resize(raw_s, 25);
--        sum25s := raw25 + BIAS_S25;
--        raw_std_u <= unsigned(sum25s(23 downto 0));
--      end if;
--    end if;
--  end process;
  
	process(clk_50MHz)
	begin
	  if rising_edge(clk_50MHz) then
		 if reset = '1' then
			raw_std_u <= (others => '0');
		 elsif sample_valid = '1' then
			raw_std_u <= unsigned(abs(raw_s));
		 end if;
	  end if;
	end process;


  ------------------------------------------------------------------------------
  -- 13 bits para 7 segmentos (truncado MSB)
  ------------------------------------------------------------------------------
  v13_u   <= raw_std_u(23 downto 11);
  
  --v13_u <= unsigned(raw_s(23 downto 11));
  --v13_u(12) <= not v13_u(12);
  v13_sig <= std_logic_vector(v13_u);
 -- v13_sig <= std_logic_vector(raw_s(23 downto 11));
  
  U_7SEG: entity work.sevenseg_dec13
    generic map(
      CLK_HZ     => 50_000_000,
      REFRESH_HZ => 1000,
      ACTIVE_LOW => true
    )
    port map(
      clk      => clk_50MHz,
      reset    => reset,
      value_in => v13_sig,
      seg      => seg,
      dp       => dp,
      an       => an
    );

  ------------------------------------------------------------------------------
  -- Graph + VGA sync (si an no tienes graph, comenta U_GRAPH)
  ------------------------------------------------------------------------------
  U_GRAPH: entity work.graph13_text_dec
    port map(
      clk50     => clk_50MHz,
      reset     => reset,
      raw24_in  => std_logic_vector(raw_std_u),
      pixel_row => pixel_row,
      pixel_col => pixel_col,
      red       => s_red,
      green     => s_green,
      blue      => s_blue
    );

  U_SYNC: entity work.vga_sync
    port map(
      clock_25MHz => ck_25,
      red         => s_red,
      green       => s_green,
      blue        => s_blue,
      red_out     => red_o,
      green_out   => green_o,
      blue_out    => blue_o,
      hsync       => vga_hsync,
      vsync       => vga_vsync,
      pixel_row   => pixel_row,
      pixel_col   => pixel_col
    );

  vga_red   <= (others => red_o);
  vga_green <= (others => green_o);
  vga_blue  <= (others => blue_o);

  ------------------------------------------------------------------------------
  -- Preparar bus ILA (64 bits)
  ------------------------------------------------------------------------------
  ILA_DATA(63 downto 40) <= std_logic_vector(raw_std_u);
  ILA_DATA(39 downto 16) <= std_logic_vector(raw_s);
  ILA_DATA(15 downto 3)  <= std_logic_vector(v13_u);
  ILA_DATA(2)            <= sample_valid;
  ILA_DATA(1)            <= hx_dout_sync;
  ILA_DATA(0)            <= hx_sck_i;

  ILA_TRIG0(0) <= sample_valid;

  ------------------------------------------------------------------------------
  -- ChipScope cores (DESCOMENTA cuando hayas generado icon.ngc e ila.ngc)
  ------------------------------------------------------------------------------
--  U_ICON : entity work.icon
--    port map(
--      CONTROL0 => CONTROL
--    );
--
--  U_ILA : entity work.ila
--    port map(
--      CONTROL => CONTROL,
--      CLK     => clk_50MHz,
--      TRIG0   => ILA_TRIG0,
--      DATA    => ILA_DATA
--    );

end Behavioral;


