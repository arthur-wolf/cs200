library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        write   : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        wrdata  : in  std_logic_vector(31 downto 0);
        rddata  : out std_logic_vector(31 downto 0));
end RAM;

architecture synth of RAM is
    type reg_type is array (0 to 1023) of std_logic_vector(31 downto 0);
    signal reg : reg_type;

    signal s_address : std_logic_vector(9 downto 0);
    signal s_reg_read : std_logic;
begin
    dff : process(clk) is
    begin
        if rising_edge(clk) then
            s_address <= address;
            s_reg_read <= read;

            if(write = '1' and cs = '1') then
                reg(to_integer(unsigned(address(9 downto 0)))) <= wrdata;
            end if;
        end if;
    end process dff;

    rddata <= reg(to_integer(unsigned(s_address(9 downto 0)))) when (s_reg_read = '1') else (others => 'Z');
end synth;
