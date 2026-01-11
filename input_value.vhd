library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity input_value is
  port(
    clk        : in  std_logic;
    reset      : in  std_logic;

    hx_dout    : in  std_logic;
    hx_sck     : out std_logic;

    -- raw standard unsigned 24-bit:
    -- -2^23 -> 0, 0 -> 2^23, +max -> 2^24-1
    raw_std_o  : out std_logic_vector(23 downto 0);
    valid_o    : out std_logic
  );
end entity;

architecture rtl of input_value is
  signal raw_s : signed(23 downto 0) := (others => '0');
  signal vld   : std_logic := '0';

  constant BIAS_S25 : signed(24 downto 0) := to_signed(2**23, 25); -- +8,388,608
begin

  U_HX: entity work.hx711_reader
    generic map(
      CLK_HZ => 50_000_000,
      SCK_HZ => 50_000
    )
    port map(
      clk          => clk,
      reset        => reset,
      hx_dout      => hx_dout,
      hx_sck       => hx_sck,
      sample       => raw_s,
      sample_valid => vld
    );

  process(clk)
    variable raw25  : signed(24 downto 0);
    variable sum25s : signed(24 downto 0);
  begin
    if rising_edge(clk) then
      if reset = '1' then
        raw_std_o <= (others => '0');
        valid_o   <= '0';
      else
        valid_o <= '0';

        if vld = '1' then
          valid_o <= '1';

          raw25  := resize(raw_s, 25);
          sum25s := raw25 + BIAS_S25;

          -- sum25s siempre cae en 0..2^24-1
          raw_std_o <= std_logic_vector(unsigned(sum25s(23 downto 0)));
        end if;
      end if;
    end if;
  end process;

end architecture;








