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
    signal sub_32 : unsigned(32 downto 0);
    signal r_out  : std_logic_vector(32 downto 0);
    signal bxor   : std_logic_vector(31 downto 0);
begin
    sub_32 <= to_unsigned(1, 33) when sub_mode = '1' else to_unsigned(0, 33);
    bxor   <= b xor std_logic_vector(sub_32(31 downto 0));
    r_out  <= std_logic_vector( unsigned(a) + unsigned(bxor) + sub_32 );
    zero   <= '1' when r_out(31 downto 0) = std_logic_vector(to_unsigned(0, 32)) else '0';
    r      <= r_out(31 downto 0);
    carry  <= r_out(32);
end synth;
