library ieee;
use ieee.std_logic_1164.all;

entity comparator is
    port(
        a_31    : in  std_logic;
        b_31    : in  std_logic;
        diff_31 : in  std_logic;
        carry   : in  std_logic;
        zero    : in  std_logic;
        op      : in  std_logic_vector(2 downto 0);
        r       : out std_logic
    );
end comparator;

architecture synth of comparator is
begin
    with op select r <= (a_31 and not(b_31)) or ((a_31 xnor b_31) and (diff_31 or zero)) when "001",            -- A <= B signed
                        (not(a_31) and b_31) or ((a_31 xnor b_31) and (not(diff_31) and not(zero))) when "010", -- A > B
                        not(zero) when "011",                                                                   -- A /= B
                        (not(carry) or zero) when "101",                                                        -- A <= B unsigned
                        carry and not(zero) when "110",                                                         -- A > B unsigned
                        zero when OTHERS;                                                                       -- A = B 
end synth;
