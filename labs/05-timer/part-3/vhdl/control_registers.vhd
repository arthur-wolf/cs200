library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_registers is
    port(
        clk       : in  std_logic;                      -- system clock
        reset_n   : in  std_logic;                      -- reset, active low
        write_n   : in  std_logic;                      -- write, active low
        backup_n  : in  std_logic;                      -- backup, active low
        restore_n : in  std_logic;                      -- restore, active low
        address   : in  std_logic_vector(2 downto 0);   -- control register address
        irq       : in  std_logic_vector(31 downto 0);  -- interrupt source vector
        wrdata    : in  std_logic_vector(31 downto 0);  -- write data

        ipending  : out std_logic;                      -- interrupt pending
        rddata    : out std_logic_vector(31 downto 0)   -- read data
    );
end control_registers;

architecture synth of control_registers is
    signal s_PIE : std_logic;                           -- ctl0 -> status
    signal s_EPIE : std_logic;                          -- ctl1 -> estatus
    signal s_BPIE : std_logic;                          -- ctl2 -> btatus
    signal s_ienable : std_logic_vector (31 downto 0);  -- ctl3 -> ienable
    signal s_ipending : std_logic_vector (31 downto 0); -- ctl4 -> iending
    signal s_cpuid : std_logic_vector (31 downto 0);    -- ctl5 -> cpuid

    constant ZEROS : std_logic_vector (31 downto 0) := x"00000000";

begin
    ipending <= '1' when s_PIE = '1' and unsigned(s_ipending) /= 0 else '0';

    flipflop : process (clk, reset_n, s_ienable, irq)
    begin
        if (reset_n = '0') then
            s_PIE <= '0';
            s_EPIE <= '0';
            s_BPIE <= '0';
            s_ienable <= ZEROS;
            s_ipending <= ZEROS;
            s_cpuid <= ZEROS;

        elsif (rising_edge(clk)) then
            if (write_n = '0') then
                case address is
                    when "000" =>
                        s_PIE <= wrdata(0);
                    when "001" =>
                        s_EPIE <= wrdata(0);
                    when "010" =>
                        s_BPIE <= wrdata(0);
                    when "011" =>
                        s_ienable <= wrdata;
                    when "100" =>
                    when "101" =>
                        s_cpuid <= wrdata;
                    when others =>
                end case;

            elsif (backup_n = '0') then
                s_EPIE <= s_PIE;
                s_PIE <= '0';

            elsif (restore_n = '0') then 
                s_PIE <= s_EPIE;

            end if;
        end if;

        s_ipending <= irq and s_ienable;

    end process flipflop;

    select_rddata : process (address, s_BPIE, s_cpuid, s_EPIE, s_ienable, s_ipending, s_PIE)
    begin
        case address is
            when "000" =>
                rddata <= "0000000000000000000000000000000" & s_PIE;
            when "001" =>
                rddata <= "0000000000000000000000000000000" & s_EPIE;
            when "010" =>
                rddata <= "0000000000000000000000000000000" & s_BPIE;
            when "011" =>
                rddata <= s_ienable;
            when "100" =>
                rddata <= s_ipending;
            when "101" =>
                rddata <= s_cpuid;
            when others =>
        end case;
    end process select_rddata;
end synth;