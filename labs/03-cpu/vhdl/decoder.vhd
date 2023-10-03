library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
    port(
        address : in  std_logic_vector(15 downto 0);
        cs_LEDS : out std_logic;
        cs_RAM  : out std_logic;
        cs_ROM  : out std_logic;
        cs_buttons : out std_logic
    );
end decoder;

architecture synth of decoder is
    constant rom_start : integer := 16#0000#;
    constant rom_end : integer := 16#0FFC#;
    constant ram_start : integer := 16#1000#;
    constant ram_end : integer := 16#1FFC#;
    constant leds_start : integer := 16#2000#;
    constant leds_end : integer := 16#200C#;
    constant buttons_start : integer := 16#2030#;
    constant buttons_end : integer := 16#2034#;

    signal s_address_int : integer;
begin
    s_address_int <= to_integer(unsigned(address));

    selection : process(s_address_int)
    begin
        cs_ROM <= '0';
        cs_RAM <= '0';
        cs_LEDS <= '0';
        if((s_address_int >= rom_start) and (s_address_int <= rom_end)) then 
            cs_ROM <= '1';
        elsif((s_address_int >= ram_start) and (s_address_int <= ram_end)) then 
            cs_RAM <= '1';
        elsif((s_address_int >= leds_start) and (s_address_int <= leds_end)) then 
            cs_LEDS <= '1';
        elsif((s_address_int >= buttons_start) and (s_address_int <= buttons_end)) then 
            cs_buttons <= '1';
        end if;
    end process selection;
end synth;
