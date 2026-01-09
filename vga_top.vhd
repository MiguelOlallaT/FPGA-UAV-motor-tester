library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga_top is
  Port (
    clk_50MHz  : in  STD_LOGIC;
    reset      : in  STD_LOGIC;
    sw         : in  STD_LOGIC_VECTOR(7 downto 0);

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
  signal ck_25 : STD_LOGIC := '0';

  signal s_red, s_green, s_blue : STD_LOGIC;
  signal red_o, green_o, blue_o : STD_LOGIC;

  signal pixel_row : STD_LOGIC_VECTOR(9 downto 0);
  signal pixel_col : STD_LOGIC_VECTOR(9 downto 0);

  signal value_sig : STD_LOGIC_VECTOR(7 downto 0);
begin

  process(clk_50MHz)
  begin
    if rising_edge(clk_50MHz) then
      ck_25 <= not ck_25;
    end if;
  end process;

  U_IN: entity work.input_value
    port map(
      clk     => clk_50MHz,
      reset   => reset,
      sw      => sw,
      value_o => value_sig
    );

  U_7SEG: entity work.sevenseg_dec
    generic map(
      CLK_HZ     => 50_000_000,
      REFRESH_HZ => 1000,
      ACTIVE_LOW => true
    )
    port map(
      clk      => clk_50MHz,
      reset    => reset,
      value_in => value_sig,
      seg      => seg,
      dp       => dp,
      an       => an
    );

  U_GRAPH: entity work.graph
    port map(
      clk50     => clk_50MHz,
      reset     => reset,
      value_in  => value_sig,
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

end Behavioral;

