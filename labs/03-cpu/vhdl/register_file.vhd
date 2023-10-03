library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port(
        clk    : in  std_logic;                     -- clock
        aa     : in  std_logic_vector(4 downto 0);  -- address a for reading
        ab     : in  std_logic_vector(4 downto 0);  -- address b for reading
        aw     : in  std_logic_vector(4 downto 0);  -- address for writing
        wren   : in  std_logic;                     -- write enable
        wrdata : in  std_logic_vector(31 downto 0); -- data for writing
        a      : out std_logic_vector(31 downto 0); -- output a for reading
        b      : out std_logic_vector(31 downto 0)  -- output b for reading
    );
end register_file;

architecture synth of register_file is
    type reg_array is array(0 to 31) of std_logic_vector(31 downto 0);
    signal reg : reg_array;
    
begin
        a <= reg(to_integer(unsigned(aa))); -- read aa
        b <= reg(to_integer(unsigned(ab))); -- read ab

    process(clk)
    begin
        if rising_edge(clk) then
            reg(0) <= (others => '0');
            if (wren = '1') then  -- write
                reg(to_integer(unsigned(aw))) <= wrdata;
            end if;
        end if;

    end process;
end synth;