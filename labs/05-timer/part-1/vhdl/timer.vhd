library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    port(
        -- bus interface
        clk     : in  std_logic;
        reset_n : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        write   : in  std_logic;
        address : in  std_logic_vector(1 downto 0);
        wrdata  : in  std_logic_vector(31 downto 0);

        irq     : out std_logic;
        rddata  : out std_logic_vector(31 downto 0)
    );
end timer;

architecture synth of timer is

    signal s_TO, s_RUN, s_ITO, s_CONT                       : std_logic;
    signal s_counter, s_period                              : std_logic_vector(31 downto 0);
    signal next_counter, to_write                           : std_logic_vector(31 downto 0);

begin

    next_counter <= std_logic_vector(unsigned(s_counter) - 1) when not( unsigned(s_counter) = 0 ) else s_period;

    irq <= '1' when ( s_TO = '1' and s_ITO = '1' ) else '0';

    read_process : Process(clk, reset_n)
    begin
        if reset_n = '0' then
            to_write <= (others => '0');
        else if rising_edge(clk) then
            if ( read = '1' ) and ( cs = '1' ) then
                case address is
                    when "00" =>
                        to_write <= s_counter;
                    when "01" =>
                        to_write <= s_period;
                    when "10" =>
                        to_write <= "00000000000000000000000000000000" or (s_ITO & s_CONT);
                    when "11" =>
                        to_write <= "00000000000000000000000000000000" or (s_TO & s_RUN);
                    when others =>
                        to_write <= (others => '0');
                end case;
                rddata <= to_write;
            else
                rddata <= (others => 'X');
            end if;
        end if;
        end if;
    end process read_process;

    write_process : Process(clk, reset_n)
    begin
        if reset_n = '0' then
            s_counter <= (others => '0');
            s_period <= (others => '0');
            s_ITO     <= '0';
            s_CONT    <= '0';
            s_TO      <= '0';
            s_RUN     <= '0';
        else if rising_edge(clk) then
            if ( write = '1' ) and ( cs = '1' ) then
                case address is
                    when "00" =>
                        s_counter <= wrdata;
                    when "01" =>
                        s_period <= wrdata;
                        s_counter <= wrdata;
                        s_RUN <= '0';
                    when "10" =>
                        if s_RUN = '0' and wrdata(3) = '1' then
                            s_RUN <= '1';            
                        end if;
                        if s_RUN = '1' and wrdata(2) = '1' then
                            s_RUN <= '0';
                        end if;
                        s_ITO <= wrdata(1);
                        s_CONT <= wrdata(0);
                    when "11" =>
                        s_TO <= wrdata(1);
                        s_RUN <= wrdata(0);
                    when others =>
                        null;
                end case;
            end if;
            if s_RUN = '1' then
                s_counter <= next_counter;
                if unsigned(s_counter) = 0 then
                    s_TO <= '1';
                    if s_CONT = '1' then
                        s_RUN <= '0';
                    end if;
                end if;
            end if;
        end if;
        end if;
    end process write_process;

end synth;