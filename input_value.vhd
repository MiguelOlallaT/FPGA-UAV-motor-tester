library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity input_value is
  port(
    clk           : in  std_logic;

    btn_tare_par  : in  std_logic;
    btn_cal_par   : in  std_logic;
    btn_tare_peso : in  std_logic;
    btn_cal_peso  : in  std_logic;

    hx_dout0      : in  std_logic;
    hx_dout1      : in  std_logic;
    hx_dout2      : in  std_logic;
    hx_dout3      : in  std_logic;
    hx_dout4      : in  std_logic;
    hx_dout5      : in  std_logic;

    hx_sck        : out std_logic;

    par_centi     : out std_logic_vector(31 downto 0);
    peso_deci     : out std_logic_vector(31 downto 0);
    peso_gram     : out std_logic_vector(13 downto 0)
  );
end entity;

architecture rtl of input_value is

  constant PAR_SCALE  : unsigned(9 downto 0) := to_unsigned(1000, 10);
  constant PESO_SCALE : unsigned(13 downto 0) := to_unsigned(10000, 14);

  signal raw_s0  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s1  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s2  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s3  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s4  : std_logic_vector(23 downto 0) := (others => '0');
  signal raw_s5  : std_logic_vector(23 downto 0) := (others => '0');

  signal sample_valid : std_logic := '0';

  signal sum_par_s  : signed(25 downto 0) := (others => '0');
  signal sum_peso_s : signed(25 downto 0) := (others => '0');

  signal zero_par   : signed(25 downto 0) := (others => '0');
  signal cal_par    : signed(25 downto 0) := (others => '0');
  signal zero_peso  : signed(25 downto 0) := (others => '0');
  signal cal_peso   : signed(25 downto 0) := (others => '0');

  signal par_centi_s  : signed(31 downto 0) := (others => '0');
  signal peso_deci_s  : signed(31 downto 0) := (others => '0');

  signal btn_tp_ff1  : std_logic := '1';
  signal btn_tp_ff2  : std_logic := '1';
  signal btn_cp_ff1  : std_logic := '1';
  signal btn_cp_ff2  : std_logic := '1';
  signal btn_tpe_ff1 : std_logic := '1';
  signal btn_tpe_ff2 : std_logic := '1';
  signal btn_cpe_ff1 : std_logic := '1';
  signal btn_cpe_ff2 : std_logic := '1';

  signal btn_tp_cnt  : unsigned(19 downto 0) := (others => '0');
  signal btn_cp_cnt  : unsigned(19 downto 0) := (others => '0');
  signal btn_tpe_cnt : unsigned(19 downto 0) := (others => '0');
  signal btn_cpe_cnt : unsigned(19 downto 0) := (others => '0');

  signal btn_tp_db   : std_logic := '1';
  signal btn_cp_db   : std_logic := '1';
  signal btn_tpe_db  : std_logic := '1';
  signal btn_cpe_db  : std_logic := '1';

  signal btn_tp_prev : std_logic := '1';
  signal btn_cp_prev : std_logic := '1';
  signal btn_tpe_prev: std_logic := '1';
  signal btn_cpe_prev: std_logic := '1';

  signal btn_tp_pulse : std_logic := '0';
  signal btn_cp_pulse : std_logic := '0';
  signal btn_tpe_pulse: std_logic := '0';
  signal btn_cpe_pulse: std_logic := '0';

  signal par_num_reg  : unsigned(39 downto 0) := (others => '0');
  signal par_den_reg  : unsigned(25 downto 0) := (others => '0');
  signal par_rem      : unsigned(26 downto 0) := (others => '0');
  signal par_quot     : unsigned(39 downto 0) := (others => '0');
  signal par_cnt      : integer range 0 to 39 := 0;
  signal par_busy     : std_logic := '0';
  signal par_sign     : std_logic := '0';
  signal par_start    : std_logic := '0';

  signal peso_num_reg : unsigned(39 downto 0) := (others => '0');
  signal peso_den_reg : unsigned(25 downto 0) := (others => '0');
  signal peso_rem     : unsigned(26 downto 0) := (others => '0');
  signal peso_quot    : unsigned(39 downto 0) := (others => '0');
  signal peso_cnt     : integer range 0 to 39 := 0;
  signal peso_busy    : std_logic := '0';
  signal peso_sign    : std_logic := '0';
  signal peso_start   : std_logic := '0';

  signal gram_num_reg : unsigned(31 downto 0) := (others => '0');
  signal gram_rem     : unsigned(5 downto 0) := (others => '0');
  signal gram_quot    : unsigned(31 downto 0) := (others => '0');
  signal gram_cnt     : integer range 0 to 31 := 0;
  signal gram_busy    : std_logic := '0';
  signal peso_gram_u  : unsigned(13 downto 0) := (others => '0');

begin

  U_HX6: entity work.hx711_reader
    generic map(
      CLK_HZ => 50_000_000,
      SCK_HZ => 50_000
    )
    port map(
      clk      => clk,
      hx_dout0 => hx_dout0,
      hx_dout1 => hx_dout1,
      hx_dout2 => hx_dout2,
      hx_dout3 => hx_dout3,
      hx_dout4 => hx_dout4,
      hx_dout5 => hx_dout5,
      hx_sck   => hx_sck,
      raw_s0   => raw_s0,
      raw_s1   => raw_s1,
      raw_s2   => raw_s2,
      raw_s3   => raw_s3,
      raw_s4   => raw_s4,
      raw_s5   => raw_s5,
      valid_o  => sample_valid
    );

  process(clk)
  begin
    if rising_edge(clk) then
      btn_tp_ff1  <= btn_tare_par;
      btn_tp_ff2  <= btn_tp_ff1;
      btn_cp_ff1  <= btn_cal_par;
      btn_cp_ff2  <= btn_cp_ff1;
      btn_tpe_ff1 <= btn_tare_peso;
      btn_tpe_ff2 <= btn_tpe_ff1;
      btn_cpe_ff1 <= btn_cal_peso;
      btn_cpe_ff2 <= btn_cpe_ff1;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if btn_tp_ff2 = '0' then
        if btn_tp_cnt /= x"FFFFF" then
          btn_tp_cnt <= btn_tp_cnt + 1;
        end if;
      else
        btn_tp_cnt <= (others => '0');
      end if;

      if btn_cp_ff2 = '0' then
        if btn_cp_cnt /= x"FFFFF" then
          btn_cp_cnt <= btn_cp_cnt + 1;
        end if;
      else
        btn_cp_cnt <= (others => '0');
      end if;

      if btn_tpe_ff2 = '0' then
        if btn_tpe_cnt /= x"FFFFF" then
          btn_tpe_cnt <= btn_tpe_cnt + 1;
        end if;
      else
        btn_tpe_cnt <= (others => '0');
      end if;

      if btn_cpe_ff2 = '0' then
        if btn_cpe_cnt /= x"FFFFF" then
          btn_cpe_cnt <= btn_cpe_cnt + 1;
        end if;
      else
        btn_cpe_cnt <= (others => '0');
      end if;

      if btn_tp_cnt = x"FFFFF" then
        btn_tp_db <= '0';
      else
        btn_tp_db <= '1';
      end if;

      if btn_cp_cnt = x"FFFFF" then
        btn_cp_db <= '0';
      else
        btn_cp_db <= '1';
      end if;

      if btn_tpe_cnt = x"FFFFF" then
        btn_tpe_db <= '0';
      else
        btn_tpe_db <= '1';
      end if;

      if btn_cpe_cnt = x"FFFFF" then
        btn_cpe_db <= '0';
      else
        btn_cpe_db <= '1';
      end if;

      btn_tp_pulse  <= '0';
      btn_cp_pulse  <= '0';
      btn_tpe_pulse <= '0';
      btn_cpe_pulse <= '0';

      if btn_tp_prev = '1' and btn_tp_db = '0' then
        btn_tp_pulse <= '1';
      end if;
      if btn_cp_prev = '1' and btn_cp_db = '0' then
        btn_cp_pulse <= '1';
      end if;
      if btn_tpe_prev = '1' and btn_tpe_db = '0' then
        btn_tpe_pulse <= '1';
      end if;
      if btn_cpe_prev = '1' and btn_cpe_db = '0' then
        btn_cpe_pulse <= '1';
      end if;

      btn_tp_prev  <= btn_tp_db;
      btn_cp_prev  <= btn_cp_db;
      btn_tpe_prev <= btn_tpe_db;
      btn_cpe_prev <= btn_cpe_db;
    end if;
  end process;

  process(clk)
    variable sum_par_v  : signed(25 downto 0);
    variable sum_peso_v : signed(25 downto 0);
    variable delta_par  : signed(25 downto 0);
    variable delta_peso : signed(25 downto 0);
    variable den_par    : signed(25 downto 0);
    variable den_peso   : signed(25 downto 0);
    variable abs_delta  : unsigned(25 downto 0);
    variable abs_den    : unsigned(25 downto 0);
    variable num_par    : unsigned(39 downto 0);
    variable num_peso   : unsigned(39 downto 0);
  begin
    if rising_edge(clk) then
      par_start <= '0';
      peso_start <= '0';

      if sample_valid = '1' then
        sum_par_v  := resize(signed(raw_s0),26) + resize(signed(raw_s1),26) + resize(signed(raw_s2),26);
        sum_peso_v := resize(signed(raw_s3),26) + resize(signed(raw_s4),26) + resize(signed(raw_s5),26);
        sum_par_s  <= sum_par_v;
        sum_peso_s <= sum_peso_v;
      else
        sum_par_v  := sum_par_s;
        sum_peso_v := sum_peso_s;
      end if;

      if btn_tp_pulse = '1' then
        zero_par <= sum_par_v;
      end if;
      if btn_cp_pulse = '1' then
        cal_par <= sum_par_v - zero_par;
      end if;
      if btn_tpe_pulse = '1' then
        zero_peso <= sum_peso_v;
      end if;
      if btn_cpe_pulse = '1' then
        cal_peso <= sum_peso_v - zero_peso;
      end if;

      if sample_valid = '1' and par_busy = '0' then
        den_par := cal_par;
        delta_par := sum_par_v - zero_par;
        if den_par /= 0 then
          if delta_par(25) = '1' then
            abs_delta := unsigned(-delta_par);
          else
            abs_delta := unsigned(delta_par);
          end if;
          if den_par(25) = '1' then
            abs_den := unsigned(-den_par);
          else
            abs_den := unsigned(den_par);
          end if;
          par_sign <= delta_par(25) xor den_par(25);
          num_par := resize(abs_delta,40) * resize(PAR_SCALE,40);
          par_num_reg <= num_par;
          par_den_reg <= abs_den;
          par_start <= '1';
        end if;
      end if;

      if sample_valid = '1' and peso_busy = '0' then
        den_peso := cal_peso;
        delta_peso := sum_peso_v - zero_peso;
        if den_peso /= 0 then
          if delta_peso(25) = '1' then
            abs_delta := unsigned(-delta_peso);
          else
            abs_delta := unsigned(delta_peso);
          end if;
          if den_peso(25) = '1' then
            abs_den := unsigned(-den_peso);
          else
            abs_den := unsigned(den_peso);
          end if;
          peso_sign <= delta_peso(25) xor den_peso(25);
          num_peso := resize(abs_delta,40) * resize(PESO_SCALE,40);
          peso_num_reg <= num_peso;
          peso_den_reg <= abs_den;
          peso_start <= '1';
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable rem_next : unsigned(26 downto 0);
    variable quot_next : unsigned(39 downto 0);
  begin
    if rising_edge(clk) then
      if par_start = '1' then
        par_busy <= '1';
        par_cnt <= 39;
        par_rem <= (others => '0');
        par_quot <= (others => '0');
      elsif par_busy = '1' then
        rem_next := par_rem(25 downto 0) & par_num_reg(par_cnt);
        quot_next := par_quot;
        if rem_next >= ('0' & par_den_reg) then
          rem_next := rem_next - ('0' & par_den_reg);
          quot_next(par_cnt) := '1';
        else
          quot_next(par_cnt) := '0';
        end if;
        par_rem <= rem_next;
        par_quot <= quot_next;
        if par_cnt = 0 then
          par_busy <= '0';
          if par_sign = '1' then
            par_centi_s <= -signed(quot_next(31 downto 0));
          else
            par_centi_s <= signed(quot_next(31 downto 0));
          end if;
        else
          par_cnt <= par_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable rem_next : unsigned(26 downto 0);
    variable quot_next : unsigned(39 downto 0);
  begin
    if rising_edge(clk) then
      if peso_start = '1' then
        peso_busy <= '1';
        peso_cnt <= 39;
        peso_rem <= (others => '0');
        peso_quot <= (others => '0');
      elsif peso_busy = '1' then
        rem_next := peso_rem(25 downto 0) & peso_num_reg(peso_cnt);
        quot_next := peso_quot;
        if rem_next >= ('0' & peso_den_reg) then
          rem_next := rem_next - ('0' & peso_den_reg);
          quot_next(peso_cnt) := '1';
        else
          quot_next(peso_cnt) := '0';
        end if;
        peso_rem <= rem_next;
        peso_quot <= quot_next;
        if peso_cnt = 0 then
          peso_busy <= '0';
          if peso_sign = '1' then
            peso_deci_s <= -signed(quot_next(31 downto 0));
          else
            peso_deci_s <= signed(quot_next(31 downto 0));
          end if;
        else
          peso_cnt <= peso_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable rem_next : unsigned(5 downto 0);
    variable quot_next : unsigned(31 downto 0);
    variable abs_peso : unsigned(31 downto 0);
  begin
    if rising_edge(clk) then
      if gram_busy = '0' then
        if peso_deci_s(31) = '1' then
          abs_peso := unsigned(-peso_deci_s);
        else
          abs_peso := unsigned(peso_deci_s);
        end if;
        gram_num_reg <= abs_peso;
        gram_rem <= (others => '0');
        gram_quot <= (others => '0');
        gram_cnt <= 31;
        gram_busy <= '1';
      else
        rem_next := gram_rem(4 downto 0) & gram_num_reg(gram_cnt);
        quot_next := gram_quot;
        if rem_next >= to_unsigned(10,6) then
          rem_next := rem_next - to_unsigned(10,6);
          quot_next(gram_cnt) := '1';
        else
          quot_next(gram_cnt) := '0';
        end if;
        gram_rem <= rem_next;
        gram_quot <= quot_next;
        if gram_cnt = 0 then
          gram_busy <= '0';
          if quot_next > to_unsigned(9999, 32) then
            peso_gram_u <= to_unsigned(9999, 14);
          else
            peso_gram_u <= quot_next(13 downto 0);
          end if;
        else
          gram_cnt <= gram_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  par_centi <= std_logic_vector(par_centi_s);
  peso_deci <= std_logic_vector(peso_deci_s);
  peso_gram <= std_logic_vector(peso_gram_u);

end architecture;
