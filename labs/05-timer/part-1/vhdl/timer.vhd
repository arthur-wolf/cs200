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

    signal s_counter, s_period, s_control, s_status : std_logic_vector(31 downto 0);

    signal s_read: std_logic;   
begin
    rddata <= 
        s_counter when (s_read = '1' and address = "00") else 
        s_period when (s_read = '1' and address = "01") else 
        s_control when (s_read = '1' and address = "10") else 
        s_status when (s_read = '1' and address = "11") else 
        (others => 'Z');

    irq <= '1' when (s_control(1) = '1' and s_status(1) = '1') else '0';

    write_flipflop: process(reset_n, clk) is 
    begin

        if (reset_n = '0') then 

            s_counter <= (others => '0');
            s_period <= (others => '0');
            s_control <= (others => '0');
            s_status <= (others => '0');

        elsif(rising_edge(clk)) then 

            s_read <= cs and read;

            if(s_status(0) = '1') then 
                s_counter <= std_logic_vector(unsigned(s_counter) - 1);

                if((to_integer(unsigned(s_counter))) = 1) then
                    s_status(1) <= '1';
                end if;
    
                if((to_integer(unsigned(s_counter))) = 0) then 
                    s_counter <= s_period;
                    if(s_control(0) = '0') then
                    s_status(0) <= '0';
                    end if;
                end if;
            end if; 
    
            if(cs = '1' AND write = '1') then 
                case address is 

                    when "01" => 
                        s_period <= wrdata; 
                        s_counter <= wrdata;
                        s_status(0) <= '0';

                    when "10" => 
                        s_control(1 downto 0) <= wrdata(1 downto 0); 
                        if(wrdata(3) = '1' AND s_status(0) = '0') then
                            s_status(0) <= '1';
                        elsif(wrdata(2) = '1' AND s_status(0) = '1') then
                            s_status(0) <= '0';
                        end if;

                    when "11" => 
                        if(wrdata(1) = '0') then
                            s_status(1) <= '0';
                        end if;

                    when OTHERS => null;

                end case;
            end if;
        end if;
    end process write_flipflop;
end synth;