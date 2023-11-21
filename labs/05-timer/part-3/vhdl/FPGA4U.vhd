-- Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus II License Agreement,
-- the Altera MegaCore Function License Agreement, or other 
-- applicable license agreement, including, without limitation, 
-- that your use is for the sole purpose of programming logic 
-- devices manufactured by Altera and sold by Altera or its 
-- authorized distributors.  Please refer to the applicable 
-- agreement for further details.

-- PROGRAM		"Quartus II 64-Bit"
-- VERSION		"Version 15.0.0 Build 145 04/22/2015 SJ Web Edition"
-- CREATED		"Sat Jan 30 11:43:28 2016"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY FPGA4U IS 
GENERIC (FREQ : INTEGER := 50
		);
	PORT
	(
		clk :  IN  STD_LOGIC;
		reset_n :  IN  STD_LOGIC;
		rx :  IN  STD_LOGIC;
		in_buttons :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		tx :  OUT  STD_LOGIC;
		out_LEDs :  OUT  STD_LOGIC_VECTOR(95 DOWNTO 0)
	);
END FPGA4U;

ARCHITECTURE bdf_type OF FPGA4U IS 

COMPONENT buttons
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 write : IN STD_LOGIC;
		 address : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 buttons : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 irq : OUT STD_LOGIC;
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT cpu
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 irq : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 rddata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 write : OUT STD_LOGIC;
		 read : OUT STD_LOGIC;
		 address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 wrdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT decoder
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 cs_RAM : OUT STD_LOGIC;
		 cs_LEDs : OUT STD_LOGIC;
		 cs_UART : OUT STD_LOGIC;
		 cs_TIMER : OUT STD_LOGIC;
		 cs_BUTTONS : OUT STD_LOGIC;
		 cs_ROM : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT timer
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 write : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 irq : OUT STD_LOGIC;
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT leds
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 write : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 LEDs : OUT STD_LOGIC_VECTOR(95 DOWNTO 0);
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT ram
	PORT(clk : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 write : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT rom
	PORT(clk : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT uart
GENERIC (FREQ : INTEGER
			);
	PORT(clk : IN STD_LOGIC;
		 reset_n : IN STD_LOGIC;
		 cs : IN STD_LOGIC;
		 write : IN STD_LOGIC;
		 rx : IN STD_LOGIC;
		 read : IN STD_LOGIC;
		 address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 wrdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 irq : OUT STD_LOGIC;
		 tx : OUT STD_LOGIC;
		 rddata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	address :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	cs_BUTTONS :  STD_LOGIC;
SIGNAL	cs_LEDs :  STD_LOGIC;
SIGNAL	cs_RAM :  STD_LOGIC;
SIGNAL	cs_ROM :  STD_LOGIC;
SIGNAL	cs_TIMER :  STD_LOGIC;
SIGNAL	cs_UART :  STD_LOGIC;
SIGNAL	irq :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	rddata :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	read :  STD_LOGIC;
SIGNAL	wrdata :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	write :  STD_LOGIC;


BEGIN 



b2v_buttons_0 : buttons
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 cs => cs_BUTTONS,
		 write => write,
		 address => address(2),
		 read => read,
		 buttons => in_buttons,
		 wrdata => wrdata,
		 irq => irq(2),
		 rddata => rddata);


b2v_cpu_0 : cpu
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 irq => irq,
		 rddata => rddata,
		 write => write,
		 read => read,
		 address => address,
		 wrdata => wrdata);


b2v_decoder_0 : decoder
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 address => address,
		 cs_RAM => cs_RAM,
		 cs_LEDs => cs_LEDs,
		 cs_UART => cs_UART,
		 cs_TIMER => cs_TIMER,
		 cs_BUTTONS => cs_BUTTONS,
		 cs_ROM => cs_ROM);


b2v_inst : timer
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 cs => cs_TIMER,
		 write => write,
		 read => read,
		 address => address(3 DOWNTO 2),
		 wrdata => wrdata,
		 irq => irq(0),
		 rddata => rddata);


b2v_LEDs_0 : leds
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 cs => cs_LEDs,
		 write => write,
		 read => read,
		 address => address(3 DOWNTO 2),
		 wrdata => wrdata,
		 LEDs => out_LEDs,
		 rddata => rddata);


b2v_ram_0 : ram
PORT MAP(clk => clk,
		 cs => cs_RAM,
		 write => write,
		 read => read,
		 address => address(11 DOWNTO 2),
		 wrdata => wrdata,
		 rddata => rddata);


b2v_rom_0 : rom
PORT MAP(clk => clk,
		 cs => cs_ROM,
		 read => read,
		 address => address(11 DOWNTO 2),
		 rddata => rddata);


b2v_uart_0 : uart
GENERIC MAP(FREQ => 50
			)
PORT MAP(clk => clk,
		 reset_n => reset_n,
		 cs => cs_UART,
		 write => write,
		 rx => rx,
		 read => read,
		 address => address(3 DOWNTO 2),
		 wrdata => wrdata,
		 irq => irq(1),
		 tx => tx,
		 rddata => rddata);


END bdf_type;