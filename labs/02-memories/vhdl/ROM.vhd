library ieee;
use ieee.std_logic_1164.all;

entity ROM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        rddata  : out std_logic_vector(31 downto 0)
    );
end ROM;

architecture synth of ROM is

    signal sig_q    : std_logic_vector(31 downto 0);
    signal sig_read : std_logic;

    component ROM_Block is
        port( 
            address : in  std_logic_vector(9 downto 0);
            clock   : in  std_logic;
            q       : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    dff : process(clk)
    begin
        if rising_edge(clk) then
            -- save inputs
            sig_read <= cs and read;
        end if;
    end process dff;

    -- read
    rddata <= sig_q when sig_read = '1' else (others => 'Z');

    rom_bl : ROM_Block 
    port map(
        address => address,
        clock   => clk,
        q       => sig_q
        );

end synth;
