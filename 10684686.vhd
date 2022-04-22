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
             i_clk : in STD_LOGIC;                                           --segnale clock
             i_rst : in STD_LOGIC;                                           --segnale reset
             i_start : in STD_LOGIC;                                         --segnale start
             i_data : in STD_LOGIC_VECTOR (7 downto 0);                      --segnale in ingresso dalla mem
             o_address : out STD_LOGIC_VECTOR (15 downto 0);                 --indirizzo lettura/scrittura mem
             o_done : out STD_LOGIC;                                         --segnale di fine elaborazioni
             o_en : out STD_LOGIC;                                           --segnale di enable per attivare la mem
             o_we : out STD_LOGIC;                                           --segnale da attivare con enable per scrivere in mem
             o_data : out STD_LOGIC_VECTOR (7 downto 0));                    --segnale che trasporta i dati da sctrivere in memoria
    );
end progetto_reti_logiche;

architecture Behavioral of progetto_reti_logiche is
  component datapath is
    port  (
            i_clk             : in  std_logic;
            i_rst             : in  std_logic;
            i_data            : in  std_logic_vector(7 downto 0);
            i_address         : in std_logic_vector(15 downto 0);
            o_data            : out  std_logic_vector(7 downto 0);
            o_address         : out std_logic_vector(15 downto 0);
            o_increaseAddress : out  std_logic;
            o_nextWord        : out std_logic;
            o_endFile         : out  std_logic);
    end component;

signal rstream_load std_logic;
signal rmaxAddress_load std_logic;
signal rcounter_load std_logic;
type S is (S0, Reset, Init, Load, S4);
signal cur_state, next_state : S;

begin
    DATAPATH0: datapath port map(
        i_clk => i_clk;
        i_rst => i_rst;
        i_data => i_data;
        i_address => i_address;
        o_data => o_data;
        o_address => o_address;
        o_increaseAddress => o_increaseAddress;
        o_nextWord => o_nextWord;
        o_endFile => o_endFile
    );

--PROCESSO HANDLING RESET
--permette di resettare la macchina a stati con rst = 1, altrimenti al fronte di salita passa allo stato successivo
    process(i_clk, i_rst)
    begin
      if(i_rst = '1') then
        cur_state <= S0;
      elsif i_clk'event and i_clk = '1' then
        cur_state <= next_state;
      end if;
    end process;

--PROCESSO PASSAGGIO STATI
--gestisce il passaggio tra stati tramite i parametri
    process(cur_state, i_start, o_endFile)
    begin
      next_state <= cur_state; --si assicura di rimanere nel combinatorio
      case cur_state is --condizioni di cambiamento tra stati
        when S0 => --stato di IDLE, se i_start = 1 passa allo stato di Reset
          if i_start = '1' then
            next_state <= Reset;
          end if;
        when Reset => --stato di Reset, passa immediatamente allo stato di Init
          next_state <= Init;
        when Init => --stato di Init, se il file non e terminato passa allo stato di Load, altrimenti torna a S0
          if o_endFile = '0' then
            next_state <= Load;
          else
            next_state <= S0;
          end if;
        when Load => --stato di Load, se il file non e terminato passa alla fase di elaborazione
          if(o_endFile = '0') then
            next_state <= S4;
          else
            next_state <= S0;
          end if;
        when S4 =>
          if(o_nextWord = '1')
            next_state <= Load;
          else
            next_state <= S4;
          end if;
      end case;
    end process;

--PROCESSO USCITE STATI
--funzione di uscita della macchina a stati, dipende solo dallo stato corrente
    process(cur_state)
    begin
      --inizilizzazione dei segnali
      rcounter_load <= '0';
      rmaxAddress_load <= '0';
      o_increaseAddress <= '0';
      o_endFile <= '0';
      o_we <= '0';
      o_en <= '0';
      --gestione del comportamento per ogni stato
      case cur_state is
        when s0 =>  --stato di IDLE
        when Reset =>  --stato di reset, azzera il contatore
          o_increaseAddress <= '0';
          rstream_load <= '0';
          rcounter_load <= '1';
        when Init =>  --stato iniziale, carica il numero di parole da leggere, e si prepara a leggere la prima parola
          o_en <= '1';
          o_we <= '0';
          rmaxAddress_load <= '1';
          o_increaseAddress <= '1';
          rcounter_load <= '1';
        when Load => --stato di Load, carica la parola corente, si prepara a leggere la successiva
          o_en <= '1';
          o_we <= '0';
          rstream_load <= '1';
          o_increaseAddress <= '1';
          rcounter_load <= '1';
        when S4 =>
          o_nextWord <= '1';
      end case;
    end process;

end Behavioral;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
