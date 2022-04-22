----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 04/21/2022 06:16:53 PM
-- Design Name:
-- Module Name: progetto_reti_logiche - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity progetto_reti_logiche is
    port  (
            i_clk             : in  std_logic;
            i_start           : in  std_logic;
            i_rst             : in  std_logic;
            i_data            : in  std_logic_vector(7 downto 0);
            o_data            : in  std_logic_vector(7 downto 0);
            o_address         : out std_logic_vector(15 downto 0);
            o_done            : out std_logic;
            o_en              : out std_logic;
            o_we              : out std_logic;
            o_data            : out std_logic_vector(7 downto 0)
    );
end progetto_reti_logiche;

architecture Behavioral of progetto_reti_logiche is
  component datapath is
    port  (
            i_clk             : in  std_logic;
            i_rst             : in  std_logic;
            i_data            : in  std_logic_vector(7 downto 0);
            o_data            : in  std_logic_vector(7 downto 0);
            i_address         : out std_logic_vector(15 downto 0);
            o_address         : out std_logic_vector(15 downto 0);
            o_increaseAddress : in  std_logic;
            rstream_load      : in  std_logic;
            rmaxAddress_load  : in  std_logic;
            rcounter_load     : in  std_logic;
            o_endFile         : in  std_logic);
    end component;

signal rstream_load std_logic;
signal rmaxAddress_load std_logic;
signal rcounter_load std_logic;
type S is (S0, S1, S3, S4);
signal cur_state, next_state : S;

begin
    DATAPATH0: datapath port map(
        i_clk;
        i_rst;
        i_data;
        o_data;
        i_address;
        o_address;
        o_increaseAddress;
        o_endFile
    );

--permette di resettare la macchina a stati con rst = 1, altrimenti al fronte di salita passa allo stato successivo
    process(i_clk, i_rst)
    begin
      if(i_rst = '1') then
        cur_state <= s0;
      elsif i_clk'event and i_clk = '1' then
        cur_state <= next_state;
      end if;
    end process;

--gestisce il passaggio tra stati tramite i parametri
    process(cur_state, i_start, o_endFile)
    begin
      next_state <= cur_state; --si assicura di rimanere nel combinatorio
      case cur_state is --condizioni di cambiamento tra stati
        when s0 =>
          if i_start = '1' then
            next_state <= s1;
          end if;
        when s1 =>
          next_state <= s2;
        when s2 =>
          next_state <= s3;
        when s3 =>
          if(o_endFile = '0')
            next_state <= s3;
          elsif (o_endFile = '1') then
            next_state <= s0;
          end if;
      end case;
    end process;

    --funzione di uscita della macchina a stati, dipende solo dallo stato corrente
    process(cur_state)
    begin
      --inizilizzazione dei segnali
      rcounter_load <= '0';
      rmaxAddress_load <= '0';
      o_increaseAddress <= '0';
      o_address <= "00";
      o_endFile <= '0';
      o_we <= '0';
      o_en <= '0';
      --gestione del comportamento per ogni stato
      case cur_state is
        when s0 =>  --stato di IDLE
        when s1 =>  --stato di reset, azzera il contatore
          o_increaseAddress <= '0';
          rcounter_load <= '1';
        when s2 =>  --stato iniziale, carica il numero di parole da leggere, e si prepara a leggere la prima parola
          o_address <= "00";
          o_en <= '1';
          o_we <= '0';
          rmaxAddress_load <= '1';
          o_increaseAddress <= '1';
          rcounter_load <= '1';
        when s3 =>
          o_en <= '1';
          o_we <= '0';
        




















end Behavioral;
