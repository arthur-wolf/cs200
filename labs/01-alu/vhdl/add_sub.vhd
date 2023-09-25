library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
    port(
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        sub_mode : in  std_logic;
        carry    : out std_logic;
        zero     : out std_logic;
        r        : out std_logic_vector(31 downto 0)
    );
end add_sub;

architecture synth of add_sub is
begin
    logic : process(a, b, sub_mode)
    begin
        if sub_mode = '1' then
            r <= std_logic_vector(unsigned(a) - unsigned(b));

            if unsigned(a) - unsigned(b) = 0 then
                zero <= '1';
            else
                zero <= '0';
            end if;
        else
            r <= std_logic_vector(unsigned(a) + unsigned(b));

            if unsigned(a) + unsigned(b) = 0 then
                zero <= '1';
            else
                zero <= '0';
            end if;
        end if;
    end process logic;
end synth;
