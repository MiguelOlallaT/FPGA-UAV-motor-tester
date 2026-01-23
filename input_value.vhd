library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity input_value is
  port(
    clk        : in  std_logic;
    reset      : in  std_logic;

    raw_s_i    : in  std_logic_vector(23 downto 0);
    valid_i    : in  std_logic;

    raw_s_o    : out std_logic_vector(23 downto 0);
    raw_std_o  : out std_logic_vector(23 downto 0);
    valid_o    : out std_logic
  );
end entity;

architecture rtl of input_value is
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        raw_s_o   <= (others => '0');
        raw_std_o <= (others => '0');
        valid_o   <= '0';
      else
        valid_o <= '0';
        if valid_i = '1' then
          raw_s_o   <= raw_s_i;
          raw_std_o <= std_logic_vector(unsigned(raw_s_i) xor x"800000");
          valid_o   <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture;
