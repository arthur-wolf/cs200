library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
    port(
        clk     : in  std_logic;
        reset_n : in  std_logic;
        en      : in  std_logic;
        sel_a   : in  std_logic;
        sel_imm : in  std_logic;
        add_imm : in  std_logic;
        imm     : in  std_logic_vector(15 downto 0);
        a       : in  std_logic_vector(15 downto 0);
        addr    : out std_logic_vector(31 downto 0)
    );
end PC;

architecture synth of PC is
    constant INIT_ADDRESS : std_logic_vector := x"0000";
begin
    dff: process(clk, reset_n)
    begin
        if reset_n = '0' then
            addr <= INIT_ADDRESS;
        elsif rising_edge(clk) then
            addr <= addr + 4;
        end if;
    end process dff;
end synth;
