library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.check_functions.all;

entity control_registers_tb is
end;

architecture testbench of control_registers_tb is
    signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;

    component control_registers is
        port(
            clk       : in  std_logic;
            reset_n   : in  std_logic;
            irq       : in  std_logic_vector(31 downto 0);
            write_n   : in  std_logic;
            backup_n  : in  std_logic;
            restore_n : in  std_logic;
            address   : in  std_logic_vector(2 downto 0);
            wrdata    : in  std_logic_vector(31 downto 0);

            ipending  : out std_logic;
            rddata    : out std_logic_vector(31 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 5 ns;

    signal clk       : std_logic                     := '0';
    signal reset_n   : std_logic                     := '0';
    signal irq       : std_logic_vector(31 downto 0) := (others => '0');
    signal ipending  : std_logic;
    signal write_n   : std_logic                     := '1';
    signal backup_n  : std_logic                     := '1';
    signal restore_n : std_logic                     := '1';
    signal address   : std_logic_vector(2 downto 0)  := (others => '0');
    signal wrdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal rddata    : std_logic_vector(31 downto 0);

begin
    control_registers_0 : control_registers port map(
            clk       => clk,
            reset_n   => reset_n,
            irq       => irq,
            ipending  => ipending,
            write_n   => write_n,
            backup_n  => backup_n,
            restore_n => restore_n,
            address   => address,
            wrdata    => wrdata,
            rddata    => rddata
        );

    check : process
        constant filename : string := "CR/report.txt";
        file text_report : text is out filename;
        variable line_output : line;
        file text_input : text is in "CR/in.txt";
        variable line_input : line;
        variable counter    : integer := 0;

        variable success : boolean := true;

        variable check_ipending : std_logic;
        variable ipending_cmp   : std_logic;
        variable check_rddata   : std_logic;
        variable rddata_cmp     : std_logic_vector(31 downto 0);

        variable SINGLE_BIT : std_logic;
        variable NIBBLE     : std_logic_vector(3 downto 0);
        variable WORD       : std_logic_vector(31 downto 0);

    begin
        line_input := new string'("");

        if (endfile(text_input)) then
            finished    <= true;
            line_output := new string'("===================================================================");
            writeline(output, line_output);
            if (success) then
                line_output := new string'("Simulation is successful");
            else
                line_output := new string'("Errors encountered during simulation. Refer to the " & filename & " file.");
            end if;
            writeline(output, line_output);
            line_output := new string'("===================================================================");
            writeline(output, line_output);
            wait;
        end if;

        counter := counter + 1;

        readline(text_input, line_input);

        if (line_input'length /= 0) then
            if (line_input(1) = '-') then -- Print message
                line_output := line_input;
                writeline(output, line_input);
            elsif (line_input(1) /= '#') then
                wait until clk = '1';

                read(line_input, SINGLE_BIT);
                reset_n <= SINGLE_BIT;
                hread(line_input, WORD);
                irq <= WORD;
                read(line_input, SINGLE_BIT);
                write_n <= SINGLE_BIT;
                read(line_input, SINGLE_BIT);
                backup_n <= SINGLE_BIT;
                read(line_input, SINGLE_BIT);
                restore_n <= SINGLE_BIT;
                hread(line_input, NIBBLE);
                address <= NIBBLE(2 downto 0);
                hread(line_input, WORD);
                wrdata <= WORD;

                wait until clk = '0';

                -- Check ipending output signal
                read(line_input, check_ipending);
                read(line_input, ipending_cmp);
                if check_ipending = '1' then
                    success := fcheck(ipending, ipending_cmp, "ipending", filename, counter, currenttime, "") and success;
                end if;

                -- Check rddata output signal
                read(line_input, check_rddata);
                hread(line_input, rddata_cmp);
                if check_rddata = '1' then
                    success := fcheck(rddata, rddata_cmp, "rddata", filename, counter, currenttime, "") and success;
                end if;
            end if;
        end if;
    end process;

    process
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process;

end testbench;
