library ieee;
use ieee.std_logic_1164.all;

entity controller is
    port(
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        -- instruction opcode
        op         : in  std_logic_vector(5 downto 0);
        opx        : in  std_logic_vector(5 downto 0);
        -- activates branch condition
        branch_op  : out std_logic;
        -- immediate value sign extention
        imm_signed : out std_logic;
        -- instruction register enable
        ir_en      : out std_logic;
        -- PC control signals
        pc_add_imm : out std_logic;
        pc_en      : out std_logic;
        pc_sel_a   : out std_logic;
        pc_sel_imm : out std_logic;
        -- register file enable
        rf_wren    : out std_logic;
        -- multiplexers selections
        sel_addr   : out std_logic;
        sel_b      : out std_logic;
        sel_mem    : out std_logic;
        sel_pc     : out std_logic;
        sel_ra     : out std_logic;
        sel_rC     : out std_logic;
        -- write memory output
        read       : out std_logic;
        write      : out std_logic;
        -- alu op
        op_alu     : out std_logic_vector(5 downto 0)
    );
end controller;

architecture synth of controller is
    type state is (FETCH1, FETCH2, DECODE, R_OP, STORE, BREAK, LOAD1, LOAD2, I_OP);
    signal s_current_state, s_next_state : state:= FETCH1;
    signal s_op, s_opx : std_logic_vector(5 downto 0);

    -- R-type operations + opx
    constant c_rtype_op : std_logic_vector(5 downto 0) := "111010"; -- 0x3A
    
    constant c_break : std_logic_vector(5 downto 0) := "110100"; -- 0x34
    constant c_callr : std_logic_vector(5 downto 0) := "011101"; -- 0x1D
    constant c_jmp : std_logic_vector(5 downto 0) := "001101"; -- 0x0D
    constant c_ret : std_logic_vector(5 downto 0) := "000101"; -- 0x05

    constant c_add : std_logic_vector(5 downto 0) := "110001"; -- 0x31
    constant c_sub : std_logic_vector(5 downto 0) := "111001"; -- 0x39
    constant c_cmple : std_logic_vector(5 downto 0) := "001000"; -- 0x08
    constant c_cmpgt : std_logic_vector(5 downto 0) := "010000"; -- 0x10
    constant c_nor : std_logic_vector(5 downto 0) := "000110"; -- 0x06
    constant c_and : std_logic_vector(5 downto 0) := "001110"; -- 0x0E
    constant c_or : std_logic_vector(5 downto 0) := "010110"; -- 0x16
    constant c_xnor : std_logic_vector(5 downto 0) := "011110"; -- 0x1E
    constant c_sll : std_logic_vector(5 downto 0) := "010011"; -- 0x13
    constant c_srl : std_logic_vector(5 downto 0) := "011011"; -- 0x1B
    constant c_sra : std_logic_vector(5 downto 0) := "111011"; -- 0x3B

    constant c_slli : std_logic_vector(5 downto 0) := "010010"; -- 0x12
    constant c_srli : std_logic_vector(5 downto 0) := "011010"; -- 0x1A
    constant c_srai : std_logic_vector(5 downto 0) := "111010"; -- 0x3A
    constant c_roli : std_logic_vector(5 downto 0) := "000010"; -- 0x02

    constant c_cmpne : std_logic_vector(5 downto 0) := "011000"; -- 0x18
    constant c_cmpeq : std_logic_vector(5 downto 0) := "100000"; -- 0x20
    constant c_cmpleu : std_logic_vector(5 downto 0) := "101000"; -- 0x28
    constant c_cmpgtu : std_logic_vector(5 downto 0) := "110000"; -- 0x30
    constant c_rol : std_logic_vector(5 downto 0) := "000011"; -- 0x03
    constant c_ror : std_logic_vector(5 downto 0) := "001011"; -- 0x0B
    
    -- I-type operations
    constant c_itype_op : std_logic_vector(5 downto 0) := "111110"; -- 0x3E
    constant c_store : std_logic_vector(5 downto 0) := "010101"; -- 0x15
    constant c_load1 : std_logic_vector(5 downto 0) := "010111"; -- 0x17
    constant c_jumpi : std_logic_vector(5 downto 0) := "000001"; -- 0x01
    constant c_addi : std_logic_vector(5 downto 0) := "000100"; -- 0x04
    constant c_andi : std_logic_vector(5 downto 0) := "001100"; -- 0x0C
    constant c_ori : std_logic_vector(5 downto 0) := "010100"; -- 0x14
    constant c_xnori : std_logic_vector(5 downto 0) := "011100"; -- 0x1C
    constant c_call : std_logic_vector(5 downto 0) := "000000"; -- 0x00
    constant c_cmplei : std_logic_vector(5 downto 0) := "001000"; -- 0x08
    constant c_cmpgti : std_logic_vector(5 downto 0) := "010000"; -- 0x10
    constant c_cmpnei : std_logic_vector(5 downto 0) := "011000"; -- 0x18
    constant c_cmpeqi : std_logic_vector(5 downto 0) := "100000"; -- 0x20
    constant c_cmpleui : std_logic_vector(5 downto 0) := "101000"; -- 0x28
    constant c_cmpgtui : std_logic_vector(5 downto 0) := "110000"; -- 0x30

    -- branch op
    constant c_br : std_logic_vector(5 downto 0) := "000110"; -- 0x06
    constant c_ble : std_logic_vector(5 downto 0) := "001110"; -- 0x0E
    constant c_bgt : std_logic_vector(5 downto 0) := "010110"; -- 0x16
    constant c_bne : std_logic_vector(5 downto 0) := "011110"; -- 0x1E
    constant c_beq : std_logic_vector(5 downto 0) := "100110"; -- 0x26
    constant c_bleu : std_logic_vector(5 downto 0) := "101110"; -- 0x2E
    constant c_bgtu : std_logic_vector(5 downto 0) := "110110"; -- 0x36

begin
    s_op <= op;
    s_opx <= opx;

    -- state machine
    flipflop: process(clk, reset_n)
    begin
        if reset_n = '0' then
            s_current_state <= FETCH1;
        elsif rising_edge(clk) then
            s_current_state <= s_next_state;
        end if;
    end process flipflop;

    fsm : process(s_current_state, s_op)
    begin
        -- default values
        write <= '0';
        read <= '0';
        pc_en <= '0';
        ir_en <= '0';
        sel_b <= '0';
        sel_rC <= '0';
        sel_addr <= '0';
        sel_mem <= '0';
        rf_wren <= '0';
        branch_op <= '0';
        pc_add_imm <= '0';
        sel_ra <= '0';
        pc_sel_imm <= '0';
        sel_pc  <= '0';
        pc_sel_a  <= '0';

        case s_current_state is 
            when FETCH1 =>
                read <= '1';
                s_next_state <= FETCH2;

            when FETCH2 =>
                pc_en <= '1';
                ir_en <= '1';
                s_next_state <= DECODE;

            when DECODE =>
                case s_op is
                    when c_rtype_op =>
                        s_next_state <= R_OP;
                    when c_store =>
                        s_next_state <= STORE;
                    when c_break =>
                        s_next_state <= BREAK;
                    when c_load1 =>
                        s_next_state <= LOAD1;
                    when c_itype_op =>
                        s_next_state <= I_OP;
                    when others => -- default state for non valid opcodes
                        s_next_state <= FETCH1;
                end case;

            when R_OP =>
                sel_b <= '1';
                sel_rC <= '1';
                rf_wren <= '1';
                s_next_state <= FETCH1;

            when STORE =>
                imm_signed <= '1';
                write <= '1';
                sel_addr <= '1';
                s_next_state <= FETCH1;

            when BREAK =>
                s_next_state <= BREAK;

            when LOAD1 =>
                read <= '1';
                sel_addr <= '1';
                imm_signed <= '1';
                s_next_state <= LOAD2;

            when LOAD2 =>
                sel_mem <= '1';
                rf_wren <= '1';
                s_next_state <= FETCH1;

            when I_OP =>
                imm_signed <= '1';
                rf_wren <= '1';
                s_next_state <= FETCH1;

        end case;
    end process fsm;

    op_pr : process(s_op, s_opx) is
    begin
        case (s_op) is
            -- R-type instructions
            when c_rtype_op =>
                case (s_opx) is
                    when c_and => op_alu <= "10XX01";
                    when c_srl => op_alu <= "11X001";
                end case;

            -- I-type instructions
            when c_addi => op_alu <= "000XXX";

            -- Branch instructions

            when others =>
                op_alu <= "XXXXXX";
        end case;
    end process op_pr;

end synth;
