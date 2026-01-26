library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_top is
  Port (
    clk_50MHz     : in  STD_LOGIC;

    sw            : in  STD_LOGIC_VECTOR(7 downto 0);

    btn_tare_par  : in  STD_LOGIC;
    btn_cal_par   : in  STD_LOGIC;
    btn_tare_peso : in  STD_LOGIC;
    btn_cal_peso  : in  STD_LOGIC;

    hx_dout0      : in  STD_LOGIC;
    hx_dout1      : in  STD_LOGIC;
    hx_dout2      : in  STD_LOGIC;
    hx_dout3      : in  STD_LOGIC;
    hx_dout4      : in  STD_LOGIC;
    hx_dout5      : in  STD_LOGIC;

    hx_sck        : out STD_LOGIC;

    pwm_out       : out STD_LOGIC;

    vga_red       : out STD_LOGIC_VECTOR (2 downto 0);
    vga_green     : out STD_LOGIC_VECTOR (2 downto 0);
    vga_blue      : out STD_LOGIC_VECTOR (1 downto 0);
    vga_hsync     : out STD_LOGIC;
    vga_vsync     : out STD_LOGIC;

    seg           : out STD_LOGIC_VECTOR(6 downto 0);
    an            : out STD_LOGIC_VECTOR(3 downto 0)
  );
end vga_top;

architecture Behavioral of vga_top is

  signal ck_25 : std_logic := '0';

  signal pixel_row : std_logic_vector(9 downto 0);
  signal pixel_col : std_logic_vector(9 downto 0);

  signal par_centi : std_logic_vector(31 downto 0) := (others => '0');
  signal peso_deci : std_logic_vector(31 downto 0) := (others => '0');
  signal peso_gram : std_logic_vector(13 downto 0) := (others => '0');

  signal pwm_pct : std_logic_vector(7 downto 0) := (others => '0');

  signal s_red   : std_logic := '0';
  signal s_green : std_logic := '0';
  signal s_blue  : std_logic := '0';

  signal red_o   : std_logic := '0';
  signal green_o : std_logic := '0';
  signal blue_o  : std_logic := '0';

begin

  process(clk_50MHz)
  begin
    if rising_edge(clk_50MHz) then
      ck_25 <= not ck_25;
    end if;
  end process;

  U_INPUT: entity work.input_value
    port map(
      clk           => clk_50MHz,
      btn_tare_par  => btn_tare_par,
      btn_cal_par   => btn_cal_par,
      btn_tare_peso => btn_tare_peso,
      btn_cal_peso  => btn_cal_peso,
      hx_dout0      => hx_dout0,
      hx_dout1      => hx_dout1,
      hx_dout2      => hx_dout2,
      hx_dout3      => hx_dout3,
      hx_dout4      => hx_dout4,
      hx_dout5      => hx_dout5,
      hx_sck        => hx_sck,
      par_centi     => par_centi,
      peso_deci     => peso_deci,
      peso_gram     => peso_gram
    );

  U_PWM: entity work.pwm_sw
    generic map(
      CLK_HZ => 50_000_000,
      PWM_HZ => 100
    )
    port map(
      clk      => clk_50MHz,
      enable   => sw(6),
      duty_sel => sw(5 downto 0),
      pwm_out  => pwm_out,
      duty_pct => pwm_pct
    );

	 U_7SEG: entity work.sevenseg_dec13
    generic map(
      CLK_HZ     => 50_000_000,
      REFRESH_HZ => 1000,
      ACTIVE_LOW => true
    )
    port map(
      clk      => clk_50MHz,
      value_main => peso_gram,
      value_alt  => pwm_pct,
      sel_alt    => sw(7),
      seg      => seg,
      an       => an
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

  U_GRAPH: entity work.graph13_text_dec
    port map(
      clk50     => clk_50MHz,
      par_centi => par_centi,
      peso_deci => peso_deci,
      pixel_row => pixel_row,
      pixel_col => pixel_col,
      red       => s_red,
      green     => s_green,
      blue      => s_blue
    );

  vga_red   <= (others => red_o);
  vga_green <= (others => green_o);
  vga_blue  <= (others => blue_o);

end Behavioral;
