library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_sw is
  generic(
    CLK_HZ : integer := 50_000_000;
    PWM_HZ : integer := 100
  );
  port(
    clk      : in  std_logic;
    enable   : in  std_logic;
    duty_sel : in  std_logic_vector(5 downto 0);
    pwm_out  : out std_logic;
    duty_pct : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of pwm_sw is
  constant PWM_PERIOD : integer := CLK_HZ / PWM_HZ;

  type lut_pulse_t is array(0 to 63) of unsigned(18 downto 0);
  constant PULSE_LUT : lut_pulse_t := (
    0 => to_unsigned(45000,19),
    1 => to_unsigned(45950,19),
    2 => to_unsigned(46900,19),
    3 => to_unsigned(47850,19),
    4 => to_unsigned(48800,19),
    5 => to_unsigned(49750,19),
    6 => to_unsigned(50700,19),
    7 => to_unsigned(51650,19),
    8 => to_unsigned(52600,19),
    9 => to_unsigned(53550,19),
    10 => to_unsigned(54500,19),
    11 => to_unsigned(55500,19),
    12 => to_unsigned(56450,19),
    13 => to_unsigned(57400,19),
    14 => to_unsigned(58350,19),
    15 => to_unsigned(59300,19),
    16 => to_unsigned(60250,19),
    17 => to_unsigned(61200,19),
    18 => to_unsigned(62150,19),
    19 => to_unsigned(63100,19),
    20 => to_unsigned(64050,19),
    21 => to_unsigned(65000,19),
    22 => to_unsigned(65950,19),
    23 => to_unsigned(66900,19),
    24 => to_unsigned(67850,19),
    25 => to_unsigned(68800,19),
    26 => to_unsigned(69750,19),
    27 => to_unsigned(70700,19),
    28 => to_unsigned(71650,19),
    29 => to_unsigned(72600,19),
    30 => to_unsigned(73550,19),
    31 => to_unsigned(74500,19),
    32 => to_unsigned(75500,19),
    33 => to_unsigned(76450,19),
    34 => to_unsigned(77400,19),
    35 => to_unsigned(78350,19),
    36 => to_unsigned(79300,19),
    37 => to_unsigned(80250,19),
    38 => to_unsigned(81200,19),
    39 => to_unsigned(82150,19),
    40 => to_unsigned(83100,19),
    41 => to_unsigned(84050,19),
    42 => to_unsigned(85000,19),
    43 => to_unsigned(85950,19),
    44 => to_unsigned(86900,19),
    45 => to_unsigned(87850,19),
    46 => to_unsigned(88800,19),
    47 => to_unsigned(89750,19),
    48 => to_unsigned(90700,19),
    49 => to_unsigned(91650,19),
    50 => to_unsigned(92600,19),
    51 => to_unsigned(93550,19),
    52 => to_unsigned(94500,19),
    53 => to_unsigned(95500,19),
    54 => to_unsigned(96450,19),
    55 => to_unsigned(97400,19),
    56 => to_unsigned(98350,19),
    57 => to_unsigned(99300,19),
    58 => to_unsigned(100250,19),
    59 => to_unsigned(101200,19),
    60 => to_unsigned(102150,19),
    61 => to_unsigned(103100,19),
    62 => to_unsigned(104050,19),
    63 => to_unsigned(105000,19)
  );

  type lut_pct_t is array(0 to 63) of unsigned(7 downto 0);
  constant PCT_LUT : lut_pct_t := (
    0 => to_unsigned(0,8),
    1 => to_unsigned(2,8),
    2 => to_unsigned(3,8),
    3 => to_unsigned(5,8),
    4 => to_unsigned(6,8),
    5 => to_unsigned(8,8),
    6 => to_unsigned(10,8),
    7 => to_unsigned(11,8),
    8 => to_unsigned(13,8),
    9 => to_unsigned(14,8),
    10 => to_unsigned(16,8),
    11 => to_unsigned(17,8),
    12 => to_unsigned(19,8),
    13 => to_unsigned(21,8),
    14 => to_unsigned(22,8),
    15 => to_unsigned(24,8),
    16 => to_unsigned(25,8),
    17 => to_unsigned(27,8),
    18 => to_unsigned(29,8),
    19 => to_unsigned(30,8),
    20 => to_unsigned(32,8),
    21 => to_unsigned(33,8),
    22 => to_unsigned(35,8),
    23 => to_unsigned(37,8),
    24 => to_unsigned(38,8),
    25 => to_unsigned(40,8),
    26 => to_unsigned(41,8),
    27 => to_unsigned(43,8),
    28 => to_unsigned(44,8),
    29 => to_unsigned(46,8),
    30 => to_unsigned(48,8),
    31 => to_unsigned(49,8),
    32 => to_unsigned(51,8),
    33 => to_unsigned(52,8),
    34 => to_unsigned(54,8),
    35 => to_unsigned(56,8),
    36 => to_unsigned(57,8),
    37 => to_unsigned(59,8),
    38 => to_unsigned(60,8),
    39 => to_unsigned(62,8),
    40 => to_unsigned(63,8),
    41 => to_unsigned(65,8),
    42 => to_unsigned(67,8),
    43 => to_unsigned(68,8),
    44 => to_unsigned(70,8),
    45 => to_unsigned(71,8),
    46 => to_unsigned(73,8),
    47 => to_unsigned(75,8),
    48 => to_unsigned(76,8),
    49 => to_unsigned(78,8),
    50 => to_unsigned(79,8),
    51 => to_unsigned(81,8),
    52 => to_unsigned(83,8),
    53 => to_unsigned(84,8),
    54 => to_unsigned(86,8),
    55 => to_unsigned(87,8),
    56 => to_unsigned(89,8),
    57 => to_unsigned(90,8),
    58 => to_unsigned(92,8),
    59 => to_unsigned(94,8),
    60 => to_unsigned(95,8),
    61 => to_unsigned(97,8),
    62 => to_unsigned(98,8),
    63 => to_unsigned(100,8)
  );

  signal pulse_cnt : unsigned(18 downto 0) := (others => '0');
  signal pct_sel   : unsigned(7 downto 0) := (others => '0');
  signal pwm_cnt   : unsigned(18 downto 0) := (others => '0');
begin
  process(duty_sel)
    variable idx : integer range 0 to 63;
  begin
    idx := to_integer(unsigned(duty_sel));
    pulse_cnt <= PULSE_LUT(idx);
    pct_sel <= PCT_LUT(idx);
  end process;

  duty_pct <= std_logic_vector(pct_sel);

  process(clk)
  begin
    if rising_edge(clk) then
      if pwm_cnt = to_unsigned(PWM_PERIOD-1, 19) then
        pwm_cnt <= (others => '0');
      else
        pwm_cnt <= pwm_cnt + 1;
      end if;

      if enable = '1' and pwm_cnt < pulse_cnt then
        pwm_out <= '1';
      else
        pwm_out <= '0';
      end if;
    end if;
  end process;
end architecture;
