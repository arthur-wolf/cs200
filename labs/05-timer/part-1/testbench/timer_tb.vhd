library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity timer_tb is
end;

architecture testbench of timer_tb is
    constant CLK_PERIOD : time    := 40 ns;
    signal iscorrect    : boolean := true;
    signal finished     : boolean := false;

    constant STATUS  : std_logic_vector(1 downto 0) := "11";
    constant CONTROL : std_logic_vector(1 downto 0) := "10";
    constant PERIOD  : std_logic_vector(1 downto 0) := "01";
    constant COUNTER : std_logic_vector(1 downto 0) := "00";

    signal clk     : std_logic := '1';
    signal reset_n : std_logic;
    signal irq     : std_logic;
    signal cs      : std_logic;
    signal read    : std_logic;
    signal write   : std_logic;
    signal address : std_logic_vector(1 downto 0);
    signal wrdata  : std_logic_vector(31 downto 0);
    signal rddata  : std_logic_vector(31 downto 0);

    component timer is
        port(
            -- bus interface
            clk     : in  std_logic;
            reset_n : in  std_logic;
            cs      : in  std_logic;
            read    : in  std_logic;
            write   : in  std_logic;
            address : in  std_logic_vector(1 downto 0);
            wrdata  : in  std_logic_vector(31 downto 0);

            irq     : out std_logic;
            rddata  : out std_logic_vector(31 downto 0)
        );
    end component;

    procedure printf(text : in string) is
        variable line_output : line;
    begin
        line_output := new string'(text);
        writeline(output, line_output);
    end printf;

    procedure clearsignals(
        signal address : out std_logic_vector(1 downto 0);
        signal cs      : out std_logic;
        signal read    : out std_logic;
        signal write   : out std_logic;
        signal wrdata  : out std_logic_vector(31 downto 0)) is
    begin
        address <= STATUS;
        cs      <= '0';
        read    <= '0';
        write   <= '0';
        wrdata  <= (others => '0');
    end clearsignals;

    procedure readonly(
        addr           : in  std_logic_vector(1 downto 0);
        signal address : out std_logic_vector(1 downto 0);
        signal cs      : out std_logic;
        signal read    : out std_logic;
        signal write   : out std_logic) is
    begin
        address <= addr;
        cs      <= '1';
        read    <= '1';
        write   <= '0';
    end readonly;

    procedure writeonly(
        addr           : in  std_logic_vector(1 downto 0);
        data           : in  integer;
        signal address : out std_logic_vector(1 downto 0);
        signal cs      : out std_logic;
        signal read    : out std_logic;
        signal write   : out std_logic;
        signal wrdata  : out std_logic_vector(31 downto 0)) is
    begin
        address <= addr;
        wrdata  <= std_logic_vector(to_unsigned(data, 32));
        cs      <= '1';
        read    <= '0';
        write   <= '1';
    end writeonly;

begin
    timer_0 : timer port map(
            clk     => clk,
            reset_n => reset_n,
            irq     => irq,
            cs      => cs,
            read    => read,
            write   => write,
            address => address,
            wrdata  => wrdata,
            rddata  => rddata
        );

    -- generate clk
    process
        variable line_output : line;
    begin
        if (finished) then
            printf("#############################################");
            printf("Simulation ended successfully!");
            printf("#############################################");
            wait;
        elsif (not iscorrect) then
            printf("#############################################");
            printf("Some errors where encountered during simulation.");
            printf("#############################################");
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
        end if;
    end process;

    -- test the timer
    process
    begin
        -- initialize data
        reset_n <= '0';
        clearsignals(address, cs, read, write, wrdata);
        wait for CLK_PERIOD;

        reset_n <= '1';
        printf("- Writing in the period register");
        writeonly(PERIOD, 15, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;
        printf("- Testing the tri-state buffer");
        if (rddata /= (31 downto 0 => 'Z')) then
            report "Except during a read, rddata must be disconnected (high-impedance = Z)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Reading back the period register");
        readonly(PERIOD, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 15) then
            report "while reading back in period register: period = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (15)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Reading the counter register");
        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 15) then
            report "The counter register must take the value written in period: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (15)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Starting the timer");
        writeonly(CONTROL, 8, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;

        printf("- Testing if running");
        readonly(STATUS, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 1) then
            report "When the counter is started, the RUN bit of the status register must be 1: status = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (1)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Testing current counter value");
        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 13) then
            report "After a start, the timer must count down: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (13)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Waiting for timeout and reading status register");
        readonly(STATUS, address, cs, read, write);
        wait for 14 * CLK_PERIOD;
        if (unsigned(rddata) /= 2) then
            report "After a timeout with cont=0, counter must stop and TO must be 1: status = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (2)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Verifying the counter register");
        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 15) then
            report "After a timeout with cont=0, counter must reload from the period value: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (15)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Enabling the IRQ and resume the counter");
        writeonly(CONTROL, 10, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;
        clearsignals(address, cs, read, write, wrdata);
        wait for 4 * CLK_PERIOD;

        printf("- Verifying that irq is enabled");
        if (irq /= '1') then
            report "IRQ should be set to 1." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Stopping the counter");
        writeonly(CONTROL, 4, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;
        clearsignals(address, cs, read, write, wrdata);
        wait for 4 * CLK_PERIOD;

        printf("- Verifying the counter value");
        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 10) then
            report "If the timer is stopped, the internal counter should not be decremented: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (10)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Starting the counter in continuous mode");
        writeonly(CONTROL, 11, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;
        clearsignals(address, cs, read, write, wrdata);
        wait for 13 * CLK_PERIOD;

        printf("- Verifying the counter value");
        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 12) then
            report "In continuous mode, the counter should continusously decrement from PERIOD to 0: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (12)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Clearing the TO bit");
        writeonly(STATUS, 0, address, cs, read, write, wrdata);
        wait for CLK_PERIOD;

        printf("- Verifying status register");
        readonly(STATUS, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 1) then
            report "Once cleared the TO bit should be 0, and RUN keep it's value: status = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (1)." severity error;
            iscorrect <= false;
            wait;
        end if;

        printf("- Verifying that irq is disabled");
        if (irq /= '0') then
            report "IRQ should be set to 0." severity error;
            iscorrect <= false;
            wait;
        end if;

        reset_n <= '0';
        wait for CLK_PERIOD;
        reset_n <= '1';
        printf("- Verifying that everything is initialized to 0");

        readonly(STATUS, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 0) then
            report "the status register should be 0: status = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (0)." severity error;
            iscorrect <= false;
            wait;
        end if;

        readonly(CONTROL, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 0) then
            report "the control register should be 0: control = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (0)." severity error;
            iscorrect <= false;
            wait;
        end if;

        readonly(PERIOD, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 0) then
            report "the period register should be 0: period = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (0)." severity error;
            iscorrect <= false;
            wait;
        end if;

        readonly(COUNTER, address, cs, read, write);
        wait for CLK_PERIOD;
        if (unsigned(rddata) /= 0) then
            report "the counter register should be 0: counter = " & integer'image(to_integer(unsigned(rddata))) & " instead of expected value (0)." severity error;
            iscorrect <= false;
            wait;
        end if;

        finished <= true;
        wait;
    end process;

end testbench;
