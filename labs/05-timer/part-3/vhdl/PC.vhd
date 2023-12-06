library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
    port(
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        en           : in  std_logic;
        sel_a        : in  std_logic;
        sel_imm      : in  std_logic;
        sel_ihandler : in  std_logic;
        add_imm      : in  std_logic;
        imm          : in  std_logic_vector(15 downto 0);
        a            : in  std_logic_vector(15 downto 0);
        addr         : out std_logic_vector(31 downto 0)
    );
end PC;

architecture synth of PC is
    constant RESET_ADDRESS : std_logic_vector := x"0000_0000";

    signal s_curr : std_logic_vector(31 downto 0);
    signal s_next : std_logic_vector(31 downto 0);
begin
    addr <= "0000000000000000" & s_curr(15 downto 2) & "00";

    flipflop : process(clk, reset_n)
    begin
        if reset_n = '0' then
            s_curr <= RESET_ADDRESS;
        else
            if rising_edge(clk) then
                if(en = '1') then
                    s_curr <= s_next;
                end if;
            end if;
        end if;
    end process flipflop;

    compute : process(sel_a, sel_imm, sel_ihandler, add_imm, imm, a, s_curr)
    begin
        if (add_imm = '1') then
            -- result of the addition of the current PC and the imm input
            s_next <= std_logic_vector(signed(s_curr) + signed(imm));

        elsif(sel_imm = '1') then
            -- imm input shifted to left by 2 bits on 32 bits
            s_next <= "00000000000000" & imm & "00";

        elsif(sel_a = '1') then
            -- imm input on 32 bits
            s_next <= x"0000" & a;

        elsif (sel_ihandler = '1') then
            -- interrupt handler address on 32 bits
            s_next <= x"0000_0004";

        else
            -- PC + 4
            s_next <= std_logic_vector(unsigned(s_curr) + to_unsigned(4, 32));
        end if;
    end process compute;

end synth;
