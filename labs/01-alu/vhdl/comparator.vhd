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
    r <= '1' when (op = "001" and ((a_31 = '1' and b_31 = '0') or ((a_31 = '1' xnor b_31 = '1') and (diff_31 = '1' or zero = '1')))) or   -- A <= B signed
                  (op = "010" and ((a_31 = '0' and b_31 = '1') or ((a_31 = '1' xnor b_31 = '1') and (diff_31 = '0' and zero = '0')))) or  -- A > B signed
                  ((op = "011" or op = "000" or op = "111") and zero = '0') or                            -- A /= B
                  (op = "100" and zero = '1') or                            -- A = B
                  (op = "101" and (carry = '0' or zero = '1')) or           -- A <= B unsigned
                  (op = "110" and (carry = '1' and zero = '0')) else '0';   -- A > B unsigned
end synth;
