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
    logic : process(op)
    begin
        case op is 
            when "011001" => -- signed less or equal

            when "011010" => -- signed greater

            when "011011" => -- comparison : is not equal

            when "011100" => -- comparison : is equal

            when "011101" => -- unsigned less or equal

            when "011110" => -- unsigned greater
            
            when others =>
                r <= 'X';
        end case;
    end process logic;
end synth;
