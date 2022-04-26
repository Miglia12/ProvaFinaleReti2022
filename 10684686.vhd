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
          i_clk             : in  STD_LOGIC;
          i_rst             : in  STD_LOGIC;
          i_data            : in  STD_LOGIC_VECTOR(7 downto 0);
          rStream_load      : in STD_LOGIC;
          rMaxAddress_load  : in STD_LOGIC;
          rAddress_load     : in STD_LOGIC;
          rCounter_load     : in STD_LOGIC;
          rMemAddress_load      : in STD_LOGIC;
          sel_increaseAddress : in STD_LOGIC;
          sel_decreaseCounter : in STD_LOGIC;
          sel_increseMemAddress : in STD_LOGIC;
          sel_AddressOutput : in STD_LOGIC;
          sel_DataOutput : in STD_LOGIC;
          startConvolution : in STD_LOGIC;
          o_data            : out  STD_LOGIC_VECTOR(7 downto 0);
          o_address         : out STD_LOGIC_VECTOR(15 downto 0);
          o_endWord      : out STD_LOGIC;
          o_endFile         : out  STD_LOGIC
          );
    end component;

signal rMaxAddress_load  : STD_LOGIC;
signal rStream_load :  STD_LOGIC;
signal rAddress_load : STD_LOGIC;
signal rCounter_load :  STD_LOGIC;
signal rMemAddress_load :  STD_LOGIC;
signal sel_increaseAddress : STD_LOGIC;
signal sel_decreaseCounter : STD_LOGIC;
signal sel_increseMemAddress : STD_LOGIC;
signal sel_AddressOutput : STD_LOGIC;
signal sel_DataOutput : STD_LOGIC;
signal startConvolution : STD_LOGIC;
signal o_endWord : STD_LOGIC;
signal o_endFile : STD_LOGIC;
type S is (S0, Reset, InitLoad, Load, InitConvolution, Convolute, SaveP1, SaveP2, CloseMem);
signal cur_state, next_state : S;

begin
    DATAPATH0: datapath port map(
          i_clk                         => i_clk ,
          i_rst                          => i_rst ,
          i_data                       => i_data ,
          rStream_load           => rStream_load ,
          rMaxAddress_load    => rMaxAddress_load ,
          rAddress_load            => rAddress_load ,
          rCounter_load            => rCounter_load ,
          rMemAddress_load      => rMemAddress_load ,
          sel_increaseAddress   => sel_increaseAddress ,
          sel_decreaseCounter   => sel_decreaseCounter ,
          sel_increseMemAddress => sel_increseMemAddress ,
          sel_AddressOutput => sel_AddressOutput , 
          sel_DataOutput => sel_DataOutput ,
          startConvolution => startConvolution ,
          o_data            => o_data ,
          o_address        => o_address ,
          o_endWord      => o_endWord ,
          o_endFile         => o_endFile 
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
        when Reset => --stato di Reset, passa immediatamente allo stato di InitLoad
          next_state <= InitLoad;
        when InitLoad => --stato di InitLoad, se il file non e terminato passa allo stato di Load, altrimenti torna a S0
          if o_endFile = '0' then
            next_state <= Load;
          else
            next_state <= S0;
          end if;
        when Load => --stato di Load, se il file non e terminato passa alla fase di elaborazione
          if(o_endFile = '0') then
            next_state <= InitConvolution;
          else
            next_state <= CloseMem;
          end if;
        when InitConvolution => --stato per iniziare la convoluzione, passa subito allo stato successivo
          next_state <= Convolute;
        when Convolute => --stato per eseguire la convoluzione di una data parola
            if (o_endWord = '0') then
                next_state <= Convolute;
            else 
                next_state <= SaveP1;
            end if; 
         when SaveP1 => --stato per salvare in memoria il risultato dello Convolute 
            next_state <= SaveP2 ;
         when SaveP2 => 
            next_state <= Load ;
         when CloseMem => --stato finale, setta a zero l'accesso alla memoria
            next_state <= S0;
      end case;
    end process;
    

--PROCESSO USCITE STATI
--funzione di uscita della macchina a stati, dipende solo dallo stato corrente
    process(cur_state)
    begin
      --inizilizzazione dei segnali
      rStream_load <= '0';
      rAddress_load <= '0';
      rMaxAddress_load <= '0';
      rCounter_load <= '0';
      rMemAddress_load <= '0';
      sel_increaseAddress <= '0';
      sel_decreaseCounter <= '0';
      sel_increseMemAddress <= '0';
      startConvolution <= '0';
      o_endWord <= '0';
      o_endFile <= '0';
      o_we <= '0';
      o_en <= '0';
      --gestione del comportamento per ogni stato
      case cur_state is
        when s0 =>  --stato di IDLE
        when Reset =>  --stato di reset, azzera il contatore
          o_en <= '0';
          o_we <= '0';
          sel_increaseAddress <= '0';
          rstream_load <= '0';
          rAddress_load <= '1';
          sel_decreaseCounter <= '0';
          rCounter_load <= '1';
          sel_increseMemAddress <= '0';
          rMemAddress_load <= '1';
          startConvolution  <= '0';
        when InitLoad =>  --stato iniziale, carica il numero di parole da leggere, e si prepara a leggere la prima parola
          o_en <= '1';
          o_we <= '0';
          rmaxAddress_load <= '1';
          sel_increaseAddress <= '1';
          rAddress_load <= '1';
          rCounter_load <= '0';
          rMemAddress_load <= '0';
        when Load => --stato di Load, carica la parola corrente, si prepara a leggere la successiva
          o_en <= '1';
          o_we <= '0';
          o_endWord <= '0';
          rstream_load <= '1';
          sel_increaseAddress <= '1';
          rAddress_load <= '1';
          startConvolution  <= '0';
          rMemAddress_load <= '0';
          sel_AddressOutput <= '0';
        when InitConvolution =>
          o_en <= '0';
          o_we <= '0';
          rstream_load <= '0';
          rAddress_load <= '0';
          sel_decreaseCounter <= '1';
          rCounter_load <= '1';
          startConvolution  <= '1';
        when Convolute => 
          sel_decreaseCounter <= '1';     
          rCounter_load <= '1';
        when SaveP1 => 
           o_en <= '1';
           o_we <= '1'; 
           sel_decreaseCounter <= '0';
           rCounter_load <= '0';
           startConvolution  <= '0';
           sel_increseMemAddress <= '1';
           rMemAddress_load <= '1';
           sel_AddressOutput  <= '1';
           sel_DataOutput <= '0';
         when SaveP2 =>
           o_en <= '1';
           o_we <= '1'; 
           sel_increseMemAddress <= '1';
           rMemAddress_load <= '1';
           sel_AddressOutput  <= '1';
           sel_DataOutput <= '1';
         when CloseMem => 
           o_en <= '0';
           o_we <= '0'; 
      end case;
    end process;

end Behavioral;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
  port  (
          i_clk             : in  STD_LOGIC;
          i_rst             : in  STD_LOGIC;
          i_data            : in  STD_LOGIC_VECTOR(7 downto 0);
          rStream_load      : in STD_LOGIC;
          rMaxAddress_load  : in STD_LOGIC;
          rAddress_load     : in STD_LOGIC;
          rCounter_load     : in STD_LOGIC;
          rMemAddress_load      : in STD_LOGIC;
          sel_increaseAddress : in STD_LOGIC;
          sel_decreaseCounter : in STD_LOGIC;
          sel_increseMemAddress : in STD_LOGIC;
          sel_AddressOutput : in STD_LOGIC;
          sel_DataOutput : in STD_LOGIC;
          startConvolution : in STD_LOGIC;
          o_data            : out  STD_LOGIC_VECTOR(7 downto 0);
          o_address         : out STD_LOGIC_VECTOR(15 downto 0);
          o_endWord      : out STD_LOGIC;
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
  signal P1  : STD_LOGIC_VECTOR(7 downto 0);
  signal P2 : STD_LOGIC_VECTOR(7 downto 0);
  signal o_rMemAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal mux_rMemAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal MemAddress_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal o_datatemp : STD_LOGIC_VECTOR(15 downto 0);
  signal o_rCounter : integer ; 
  signal mux_rCounter : integer ;
  signal rCounter_sub : integer ;
  signal tempData : integer ;
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
  tempData <= (to_integer(unsigned(i_data)) + 1);
  MaxAddress_sum <= std_logic_vector(to_unsigned(tempData, MaxAddress_sum 'length));

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
  endFile_sub <= std_logic_vector(unsigned(o_rMaxAddress (15 downto 0)) - unsigned(address_sum(15 downto 0)));
  o_endFile  <=  '1' when (endFile_sub = "0000000000000000" ) else '0';
    
  --configurazione registro Counter, che contiene il numero di bit letti
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rCounter <= 0;
    elsif i_clk'event and i_clk = '1' then
      if(rCounter_load = '1') then
        o_rCounter <= mux_rCounter;
      end if;
    end if;
  end process;
    
  --configurazione rCounter_sub, si occpura di diminuire il counter e notificare quando questo raggiunge il valore 0
  rCounter_sub <= o_rCounter - 1;
  o_endWord <= '1' when (rCounter_sub = 0) else '0';
  
  --configurazione mux per il decremento o il reset del contatore Counter
  with sel_decreaseCounter select mux_rCounter <=   
    7 when '0',
    rCounter_sub   when '1',
    8 when others;
    
  --processo convolutore  
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      P1 <= (others => '0');
      P2 <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
        if (startConvolution = '1') then
             case o_rCounter  is
                when 7 =>
                    P1 (o_rCounter ) <= (o_rStream(o_rCounter) xor '0');
                    P2 (o_rCounter ) <= (o_rStream(o_rCounter) xor '0' xor '0');
                when 6 => 
                    P1 (o_rCounter ) <= (o_rStream(o_rCounter) xor '0');
                    P2 (o_rCounter ) <= (o_rStream(o_rCounter) xor o_rStream(o_rCounter + 1) xor '0');
                when 5 | 4 | 3 | 2 | 1 | 0 =>
                    P1 (o_rCounter ) <= (o_rStream(o_rCounter) xor o_rStream(o_rCounter + 2));
                    P2 (o_rCounter ) <= (o_rStream(o_rCounter) xor o_rStream(o_rCounter + 1) xor o_rStream(o_rCounter + 2));
--                    if (o_rCounter = 0) then
--                        o_endWord <= '1';
--                    end if;
                 when others => 
                    P1 <= (others => 'X');
                    P2 <= (others => 'X');
              end case;
         end if;
    end if;
  end process;
 
  --configurazione registro memAddress, che contiene l'indirizzo in cui scrivere in memoria e si occupa di fare output dei dati
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rMemAddress <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rMemAddress_load = '1') then
        o_rMemAddress <= mux_rMemAddress;
      end if;
    end if;
  end process;
  
  --configurazione MemAddressSum, aumenta di 1 il MemAddress
  MemAddress_sum <= std_logic_vector(to_unsigned(to_integer(unsigned( o_rMemAddress)) + 1, MemAddress_sum'length));
  --configurazione mux per l'aumento o il reset del contatore MemAddress
  with sel_increseMemAddress select mux_rMemAddress <=   
    std_logic_vector(to_unsigned(1000, mux_rMemAddress'length)) when '0',
    MemAddress_sum  when '1',
    (others => 'X') when others;
    
    --configurazione mux per output address 
    with sel_AddressOutput select o_address <=
    o_rAddress when '0',
    o_rMemAddress when '1',
    (others => 'X') when others;
    
     --configurazione mux per output address 
    with sel_DataOutput select o_data <=
    P1 when '0',
    P2 when '1',
    (others => 'X') when others;
    
end Behavioral;
