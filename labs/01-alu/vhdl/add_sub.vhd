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
    signal sub_32 : std_logic_vector(31 downto 0);
    signal r_out  : std_logic_vector(32 downto 0);
begin
    with sub_mode select sub_32 <= x"FFFFFFFF" when '1',
                                   x"00000000" when others;

    logic : process(a, b, sub_32, sub_mode)
    begin
        r_out <= a or (b xor sub_32) or std_logic_vector(sub_mode);

        if r_out = std_logic_vector(0) then
                zero <= '1';
            else
                zero <= '0';
        end if;

        r <= r_out;

        -- if sub_mode = '1' then
        --     r <= std_logic_vector(unsigned(a) - unsigned(b));

        --     if unsigned(a) - unsigned(b) = 0 then
        --         zero <= '1';
        --     else
        --         zero <= '0';
        --     end if;
        -- else
        --     r <= std_logic_vector(unsigned(a) + unsigned(b));

        --     if unsigned(a) + unsigned(b) = 0 then
        --         zero <= '1';
        --     else
        --         zero <= '0';
        --     end if;
        -- end if;
    end process logic;
end synth;
