-- hdl/pwm_core.vhd
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity pwm_core is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    enable    : in  std_logic;
    polarity  : in  std_logic;                    -- 1 = invert (active-low fan)
    period    : in  unsigned(31 downto 0);        -- cycles per PWM period
    duty      : in  unsigned(31 downto 0);        -- high cycles (0..period)
    pwm_out   : out std_logic;
    raw_level : out std_logic
  );
end;
architecture rtl of pwm_core is
  signal cnt : unsigned(31 downto 0) := (others=>'0');
  signal raw : std_logic := '0';
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' or enable = '0' then
        cnt <= (others=>'0');
        raw <= '0';
      else
        if cnt + 1 >= period then
          cnt <= (others=>'0');
        else
          cnt <= cnt + 1;
        end if;
        if cnt < duty then raw <= '1'; else raw <= '0'; end if;
      end if;
    end if;
  end process;
  raw_level <= raw;
  pwm_out   <= raw xor polarity;
end;
