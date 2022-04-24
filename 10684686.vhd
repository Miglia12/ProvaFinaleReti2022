---------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if using
---- arithmetic functions with Signed or Unsigned values
----use IEEE.NUMERIC_STD.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx leaf cells in this code.
----library UNISIM;
----use UNISIM.VComponents.all;

entity progetto_reti_logiche is
    port  (
             i_clk : in STD_LOGIC;                                           --segnale clock
             i_rst : in STD_LOGIC;                                           --segnale reset
             i_start : in STD_LOGIC;                                         --segnale start
             i_data : in STD_LOGIC_VECTOR (7 downto 0);                      --segnale in ingresso dalla mem
             o_address : out STD_LOGIC_VECTOR (15 downto 0);                 --indirizzo lettura/scrittura mem
             o_done : out STD_LOGIC;                                         --segnale di fine elaborazioni
             o_data : out STD_LOGIC_VECTOR (7 downto 0);                    --segnale che trasporta i dati da sctrivere in memoria
             o_en : out STD_LOGIC;                                           --segnale di enable per attivare la mem
             o_we : out STD_LOGIC                                      --segnale da attivare con enable per scrivere in mem
          );
end progetto_reti_logiche;

architecture Behavioral of progetto_reti_logiche is

  component datapath is
    port  (
           i_clk                   : in  STD_LOGIC;
          i_rst                     : in  STD_LOGIC;
          i_data                  : in  STD_LOGIC_VECTOR(7 downto 0);
          i_address            : in STD_LOGIC_VECTOR(15 downto 0);
          rStream_load     : in STD_LOGIC;
          rMaxAddress_load  : in STD_LOGIC;
          rAddress_load     : in STD_LOGIC;
          sel_increaseAddress :in STD_LOGIC;
          o_address             : out STD_LOGIC_VECTOR(15 downto 0);
          o_done                  : out STD_LOGIC;
          o_data                 : out STD_LOGIC_VECTOR (7 downto 0);
          o_increaseAddress : out  STD_LOGIC;
          o_nextWord        : out STD_LOGIC;
          o_endFile           : out  STD_LOGIC
          );
    end component;

signal i_address : STD_LOGIC_VECTOR(15 downto 0);
signal rMaxAddress_load  : STD_LOGIC;
signal rStream_load :  STD_LOGIC;
signal rAddress_load : STD_LOGIC;
signal sel_increaseAddress : STD_LOGIC;
signal o_increaseAddress : STD_LOGIC;
signal o_nextWord : STD_LOGIC;
signal o_endFile : STD_LOGIC;
type S is (S0, Reset, Init, Load, S4);
signal cur_state, next_state : S;

begin
    DATAPATH0: datapath port map(
          i_clk  => i_clk ,
          i_rst  => i_rst ,
          i_data => i_data ,
          i_address  => i_address,
          rStream_load => rStream_load, 
          rMaxAddress_load => rMaxAddress_load,
          rAddress_load => rAddress_load,
          sel_increaseAddress => sel_increaseAddress,
          o_data => o_data,
          o_address => o_address,
          o_increaseAddress => o_increaseAddress,
          o_nextWord => o_nextWord,
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
          if(o_nextWord = '1') then
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
      rAddress_load <= '0';
      rmaxAddress_load <= '0';
      sel_increaseAddress <= '0';
      o_endFile <= '0';
      o_we <= '0';
      o_en <= '0';
      --gestione del comportamento per ogni stato
      case cur_state is
        when s0 =>  --stato di IDLE
        when Reset =>  --stato di reset, azzera il contatore
          sel_increaseAddress <= '0';
          rstream_load <= '0';
          rAddress_load <= '1';
        when Init =>  --stato iniziale, carica il numero di parole da leggere, e si prepara a leggere la prima parola
          o_en <= '1';
          o_we <= '0';
          rmaxAddress_load <= '1';
          sel_increaseAddress <= '1';
          rAddress_load <= '1';
        when Load => --stato di Load, carica la parola corrente, si prepara a leggere la successiva
          o_en <= '1';
          o_we <= '0';
          rstream_load <= '1';
          sel_increaseAddress <= '1';
          rAddress_load <= '1';
        when S4 =>
          o_nextWord <= '1';
      end case;
    end process;

end Behavioral;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.numeric_std_unsigned.all;

entity datapath is
  port  (
          i_clk             : in  STD_LOGIC;
          i_rst             : in  STD_LOGIC;
          i_data            : in  STD_LOGIC_VECTOR(7 downto 0);
          i_address         : in STD_LOGIC_VECTOR(15 downto 0);
          rStream_load      : in STD_LOGIC;
          rMaxAddress_load  : in STD_LOGIC;
          rAddress_load     : in STD_LOGIC;
          sel_increaseAddress :in STD_LOGIC;
          o_data            : out  STD_LOGIC_VECTOR(7 downto 0);
          o_address         : out STD_LOGIC_VECTOR(15 downto 0);
          o_increaseAddress : out  STD_LOGIC;
          o_nextWord        : out STD_LOGIC;
          o_endFile         : out  STD_LOGIC);
end datapath;

architecture Behavioral of datapath is
  signal o_rStream : STD_LOGIC_VECTOR(7 downto 0);
  signal data_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal o_rMaxAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal mux_rAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal o_rAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal MaxAddress_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal address_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal endFile_sub : STD_LOGIC_VECTOR(15 downto 0);
begin

--configurazione del registro Stream
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rStream <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rStream_load = '1') then
        o_rStream <= i_data;
      end if;
    end if;
  end process;

  --configurazione MaxAddressSum, aumenta di 1 il MaxAddress
  MaxAddress_sum <= ("00000000" & i_data)  + 1;

  --configurazione del registro MaxAddress
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rMaxAddress <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rMaxAddress_load = '1') then
        o_rMaxAddress <= MaxAddress_sum;
      end if;
    end if;
  end process;

  --configurazione mux per l'aumento o il reset del contatore Address
  with sel_increaseAddress select  mux_rAddress <=   
    (others => '0') when '0',
    address_sum  when '1',
    (others => 'X') when others;

  --configurazione registro Address, che contiene l'indirizzo da leggere in memoria
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rAddress <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rAddress_load = '1') then
        o_rAddress <= mux_rAddress;
      end if;
    end if;
  end process;
    
    --configurazione endFIle_sub, si occupa di confrontare il MaxAddress con líndirizzo corrrente (o_raddress) aumentato di 1 => address_sum
    endFile_sub <= o_rMaxAddress - address_sum;
    o_endFile  <=  '1' when (endFile_sub = "0000000000000000" ) else '0';
    
    
    
end Behavioral;
