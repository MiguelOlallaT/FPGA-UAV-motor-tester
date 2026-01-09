library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity input_value is
  port(
    clk      : in  std_logic;
    reset    : in  std_logic;
    sw       : in  std_logic_vector(7 downto 0);
    value_o  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of input_value is
begin
  -- Para empezar: directo desde switches.
  -- (clk/reset quedan por si luego metes filtrado/lectura de sensor)
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        value_o <= (others => '0');
      else
        value_o <= sw;
      end if;
    end if;
  end process;
end architecture;


