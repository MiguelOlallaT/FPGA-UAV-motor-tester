library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_top is
  Port (
    clk_50MHz  : in  STD_LOGIC;
    reset      : in  STD_LOGIC;

    hx_dout0   : in  STD_LOGIC;
    hx_dout1   : in  STD_LOGIC;
    hx_dout2   : in  STD_LOGIC;
    hx_dout3   : in  STD_LOGIC;
    hx_dout4   : in  STD_LOGIC;
    hx_dout5   : in  STD_LOGIC;

    hx_sck     : out STD_LOGIC;

    vga_red    : out STD_LOGIC_VECTOR (2 downto 0);
    vga_green  : out STD_LOGIC_VECTOR (2 downto 0);
    vga_blue   : out STD_LOGIC_VECTOR (1 downto 0);
    vga_hsync  : out STD_LOGIC;
    vga_vsync  : out STD_LOGIC;

    seg        : out STD_LOGIC_VECTOR(6 downto 0);
    dp         : out STD_LOGIC;
    an         : out STD_LOGIC_VECTOR(3 downto 0)
  );
end vga_top;

architecture Behavioral of vga_top is

  signal ck_25 : std_logic := '0';

  signal pixel_row : std_logic_vector(9 downto 0);
  signal pixel_col : std_logic_vector(9 downto 0);

  signal raw_s_slv0    : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s_slv1    : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s_slv2    : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s_slv3    : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s_slv4    : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s_slv5    : std_logic_vector(23 downto 0) := (others => '0');

  signal raw_std_slv0  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_std_slv1  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_std_slv2  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_std_slv3  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_std_slv4  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_std_slv5  : std_logic_vector(23 downto 0) := (others => '0');

  signal sample_valid0 : std_logic := '0';
  signal sample_valid1 : std_logic := '0';
  signal sample_valid2 : std_logic := '0';
  signal sample_valid3 : std_logic := '0';
  signal sample_valid4 : std_logic := '0';
  signal sample_valid5 : std_logic := '0';

  signal sample_valid_all : std_logic := '0';

  signal raw_std_u0    : unsigned(23 downto 0) := (others => '0');

  signal value13_u  : unsigned(12 downto 0) := (others => '0');
  signal value13_slv: std_logic_vector(12 downto 0) := (others => '0');

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
      if reset = '1' then
        ck_25 <= '0';
      else
        ck_25 <= not ck_25;
      end if;
    end if;
  end process;

  U_HX6: entity work.hx711_reader
    generic map(
      CLK_HZ => 50_000_000,
      SCK_HZ => 50_000
    )
    port map(
      clk      => clk_50MHz,
      reset    => reset,
      hx_dout0 => hx_dout0,
      hx_dout1 => hx_dout1,
      hx_dout2 => hx_dout2,
      hx_dout3 => hx_dout3,
      hx_dout4 => hx_dout4,
      hx_dout5 => hx_dout5,
      hx_sck   => hx_sck,
      raw_s0   => raw_s_slv0,
      raw_s1   => raw_s_slv1,
      raw_s2   => raw_s_slv2,
      raw_s3   => raw_s_slv3,
      raw_s4   => raw_s_slv4,
      raw_s5   => raw_s_slv5,
      valid_o  => sample_valid_all
    );

  U_IN0: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv0,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv0,
      valid_o   => sample_valid0
    );

  U_IN1: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv1,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv1,
      valid_o   => sample_valid1
    );

  U_IN2: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv2,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv2,
      valid_o   => sample_valid2
    );

  U_IN3: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv3,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv3,
      valid_o   => sample_valid3
    );

  U_IN4: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv4,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv4,
      valid_o   => sample_valid4
    );

  U_IN5: entity work.input_value
    port map(
      clk       => clk_50MHz,
      reset     => reset,
      raw_s_i   => raw_s_slv5,
      valid_i   => sample_valid_all,
      raw_s_o   => open,
      raw_std_o => raw_std_slv5,
      valid_o   => sample_valid5
    );

  raw_std_u0 <= unsigned(raw_std_slv0);

  value13_u   <= raw_std_u0(23 downto 11);
  value13_slv <= std_logic_vector(value13_u);

  U_7SEG: entity work.sevenseg_dec13
    generic map(
      CLK_HZ     => 50_000_000,
      REFRESH_HZ => 1000,
      ACTIVE_LOW => true
    )
    port map(
      clk      => clk_50MHz,
      reset    => reset,
      value_in => value13_slv,
      seg      => seg,
      dp       => dp,
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
      reset     => reset,
      raw24_in0 => raw_std_slv0,
      raw24_in1 => raw_std_slv1,
      raw24_in2 => raw_std_slv2,
      raw24_in3 => raw_std_slv3,
      raw24_in4 => raw_std_slv4,
      raw24_in5 => raw_std_slv5,
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
