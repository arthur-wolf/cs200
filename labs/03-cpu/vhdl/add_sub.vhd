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
    signal subxorb_out: std_logic_vector(31 downto 0);
    signal adder: std_logic_vector(32 downto 0);
    signal s_sub: unsigned(32 downto 0);
    constant zero_vector: std_logic_vector(31 downto 0) := (others => '0');
begin
    subxorb_out <= b xor (31 downto 0 => sub_mode);
    s_sub <= to_unsigned(1, 33) when sub_mode = '1' else to_unsigned(0, 33);
    adder <= std_logic_vector(unsigned('0' & a) + unsigned('0' & subxorb_out) + s_sub); 
    r <= adder(31 downto 0);
    zero <= '1' when (adder(31 downto 0) = zero_vector) else '0';
    carry <= std_logic(adder(32));
end synth;
