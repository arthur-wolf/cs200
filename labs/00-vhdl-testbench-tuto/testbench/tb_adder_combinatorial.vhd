library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adder_combinatorial is
end tb_adder_combinatorial;

architecture test of tb_adder_combinatorial is

    constant TIME_DELTA : time := 100 ns;
    -- GENERICS
    constant N_BITS : positive range 2 to positive'right := 4;

    -- PORTS
    signal OP1 : std_logic_vector(N_BITS - 1 downto 0);
    signal OP2 : std_logic_vector(N_BITS - 1 downto 0);
    signal SUM : std_logic_vector(N_BITS downto 0);
    
    begin
    -- Instantiate DUT
    dut : entity work.adder_combinatorial
        generic map(N_BITS => N_BITS)
        port map(
            OP1 => OP1,
            OP2 => OP2,
            SUM => SUM);

    simulation : process
        procedure check_add(constant in1 : in natural;
                            constant in2 : in natural;
                            constant res_expected : in natural) is
                            variable res : natural;
        begin   
            OP1 <= std_logic_vector(to_unsigned(in1, OP1'length));
            OP2 <= std_logic_vector(to_unsigned(in2, OP2'length));
            wait for TIME_DELTA;

            res := to_integer(unsigned(SUM));
            assert res = res_expected
                report "ERROR: " & integer'image(res) & " /= " & integer'image(res_expected)
                severity error;
        end procedure check_add;

    begin
        check_add(12, 8, 20);
        check_add(10, 6, 16);
        check_add(4, 1, 5);
        check_add(11, 7, 18);
        check_add(10, 12, 23);
        check_add(8, 7, 15);
        check_add(1, 9, 10);
        check_add(7, 3, 10);
        check_add(1, 4, 5);
        check_add(8, 0, 8);
        wait;
    end process simulation;        
end architecture test;