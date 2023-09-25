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
    signal sub_32 : std_logic_vector(31 downto 0);
    signal r_out  : std_logic_vector(32 downto 0);
begin
    with sub_mode select sub_32 <= x"FFFFFFFF" when '1',
                                   x"00000000" when others;

    logic : process(a, b, sub_32, sub_mode, r_out)
    begin
        r_out <= std_logic_vector( unsigned(a) + unsigned(b xor sub_32) + unsigned(sub_mode) );

        if r_out = std_logic_vector(0) then
                zero <= '1';
            else
                zero <= '0';
        end if;

        carry <= r_out(32);

        r <= r_out(31 downto 0);
        
    end process logic;
end synth;
