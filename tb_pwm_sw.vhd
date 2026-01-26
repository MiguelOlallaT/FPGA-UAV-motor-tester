library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pwm_sw is
end entity;

architecture sim of tb_pwm_sw is
  constant CLK_HZ : integer := 50_000_000;
  constant PWM_HZ : integer := 100;

  signal clk      : std_logic := '0';
  signal enable   : std_logic := '0';
  signal duty_sel : std_logic_vector(5 downto 0) := (others => '0');
  signal pwm_out  : std_logic;
  signal duty_pct : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 10 ns;

  UUT: entity work.pwm_sw
    generic map(
      CLK_HZ => CLK_HZ,
      PWM_HZ => PWM_HZ
    )
    port map(
      clk      => clk,
      enable   => enable,
      duty_sel => duty_sel,
      pwm_out  => pwm_out,
      duty_pct => duty_pct
    );

  process
  begin
    wait for 1 ms;
    enable <= '1';

    duty_sel <= std_logic_vector(to_unsigned(0, 6));
    wait for 30 ms;

    duty_sel <= std_logic_vector(to_unsigned(16, 6));
    wait for 30 ms;

    duty_sel <= std_logic_vector(to_unsigned(32, 6));
    wait for 30 ms;

    duty_sel <= std_logic_vector(to_unsigned(48, 6));
    wait for 30 ms;

    duty_sel <= std_logic_vector(to_unsigned(63, 6));
    wait for 30 ms;

    enable <= '0';
    wait for 10 ms;

    assert false report "Simulation finished" severity failure;
  end process;
end architecture;
