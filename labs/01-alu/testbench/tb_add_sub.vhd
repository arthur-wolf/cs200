library ieee;
use ieee.std_logic_1164.all;

entity tb_add_sub is
end tb_add_sub;

architecture testbench of tb_add_sub is
    signal a, b, r : std_logic_vector(31 downto 0);
    signal sub_mode      : std_logic;

    -- declaration of the add_sub interface
    component add_sub is
        port(
            a  : in  std_logic_vector(31 downto 0);
            b  : in  std_logic_vector(31 downto 0);
            sub_mode : in  std_logic;
            carry : out std_logic;
            zero  : out std_logic;
            r  : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    -- add_sub unit instance
    add_sub_0 : add_sub port map(
            a  => a,
            b  => b,
            sub_mode => sub_mode,
            carry => open,
            zero  => open,
            r  => r
        );

    -- proess for verification of the add_sub unit
    check : process
    begin
        -- test 1 // 0 + 0 = 0
        a <= (31 downto 0 => '0');
        b <= (31 downto 0 => '0');
        sub_mode <= '0';
        wait for 10 ns;
        assert r = (31 downto 0 => '0') 
            report "test 1 failed" 
            severity warning;

        -- test 2   // 5 + 7 = 12
        a <= (31 downto 3 => '0') & "101";
        b <= (31 downto 3 => '0') & "111";
        sub_mode <= '0';
        wait for 10 ns;
        assert r = (31 downto 4 => '0') & "1100"
            report "test 2 failed"
            severity warning;

        -- test 3 // 0 - 0 = 0
        a <= (31 downto 0 => '0');
        b <= (31 downto 0 => '0');
        sub_mode <= '1';
        wait for 10 ns;
        assert r = (31 downto 0 => '0') 
            report "test 3 failed" 
            severity warning;
        
        -- test 4 // 7 - 5 = 2
        a <= (31 downto 3 => '0') & "111";
        b <= (31 downto 3 => '0') & "101";
        sub_mode <= '1';
        wait for 10 ns;
        assert r = (31 downto 2 => '0') & "10"
            report "test 4 failed" 
            severity warning;
        

        wait;                           -- wait forever
    end process;

end testbench;
