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

entity project_reti_logiche is
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
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

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
          rAddOn_load1           : in STD_LOGIC;
          rAddOn_load                : in STD_LOGIC;
          rP1_load                     : STD_LOGIC;
          rP2_load                     : STD_LOGIC;
          sel_increaseAddress : in STD_LOGIC;
          sel_decreaseCounter : in STD_LOGIC;
          sel_increseMemAddress : in STD_LOGIC;
          sel_AddressOutput : in STD_LOGIC;
          sel_DataOutput : in STD_LOGIC;
          sel_saveLastBit : in STD_LOGIC;
          start_convolution : in STD_LOGIC;
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
signal rAddOn_load1           : STD_LOGIC;
signal rAddOn_load                :  STD_LOGIC;
signal rP1_load                     : STD_LOGIC;
signal rP2_load                     : STD_LOGIC;
signal sel_increaseAddress : STD_LOGIC;
signal sel_decreaseCounter : STD_LOGIC;
signal sel_increseMemAddress : STD_LOGIC;
signal sel_AddressOutput : STD_LOGIC;
signal sel_DataOutput : STD_LOGIC;
signal sel_saveLastBit : STD_LOGIC;
signal start_convolution : STD_LOGIC;
signal o_endWord : STD_LOGIC;
signal o_endFile : STD_LOGIC;
type S is (S0, Reset, InitLoad, WaitMem1, Load, WaitMem2, InitConvolution, Convolute, WaitP, SaveP1, SaveP2, CloseMem, Done);
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
          rAddOn_load1              => rAddOn_load1 ,
          rAddOn_load              =>   rAddOn_load,
          rP1_load                   =>   rP1_load,
          rP2_load                   =>   rP2_load,
          sel_increaseAddress   => sel_increaseAddress ,
          sel_decreaseCounter   => sel_decreaseCounter ,
          sel_increseMemAddress => sel_increseMemAddress ,
          sel_AddressOutput => sel_AddressOutput , 
          sel_DataOutput => sel_DataOutput ,
          sel_saveLastBit => sel_saveLastBit , 
          start_convolution => start_convolution ,
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
    process(cur_state, i_start, o_endFile, o_endWord)
    begin
      next_state <= cur_state; --si assicura di rimanere nel combinatorio
      case cur_state is --condizioni di cambiamento tra stati
        when S0 => --stato di IDLE, se i_start = 1 passa allo stato di Reset
          if i_start = '1' then
            next_state <= Reset;
          else 
            next_state <= S0;
          end if;
        when Reset => --stato di Reset, passa immediatamente allo stato di InitLoad
          next_state <= InitLoad;
        when InitLoad => --stato di InitLoad, se il file non e terminato passa allo stato di Load, altrimenti torna a S0
            next_state <= WaitMem1;
        when WaitMem1 => --stato di Wait, permette di caricare il valore corretto dalla memoria
            next_state <= Load;
        when Load => --stato di Load, se il file non e terminato passa alla fase di elaborazione
          if(o_endFile = '0') then
            next_state <= WaitMem2 ;
          else
            next_state <= CloseMem;
          end if;
        when WaitMem2   => --stato di Wait, permette di caricare il valore corretto dalla memoria
            next_state <= InitConvolution;
        when InitConvolution => --stato per iniziare la convoluzione, passa subito allo stato successivo
          next_state <= Convolute;
        when Convolute => --stato per eseguire la convoluzione di una data parola
         if (o_endWord = '1') then
                next_state <= WaitP;
            else 
                next_state <= Convolute;
            end if; 
         when WaitP =>
            next_state <= SaveP1; 
         when SaveP1 => --stato per salvare in memoria il risultato dello Convolute 
            next_state <= SaveP2 ;
         when SaveP2 =>  --stato per salvare in memoria il risultato dello Convolute 
            next_state <= Load ;
         when CloseMem => --stato finale, setta a zero l'accesso alla memoria
            next_state <= Done;
         when Done =>
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
      rAddOn_load1 <= '0';
      rAddOn_load <= '0';
      rP1_load  <= '0';
      rP2_load  <= '0';
      sel_increaseAddress <= '0';
      sel_decreaseCounter <= '0';
      sel_increseMemAddress <= '0';
      sel_AddressOutput <= '0';
      sel_DataOutput <= '0';
      sel_saveLastBit <= '0';
      start_convolution <= '0';
      o_done <= '0';
      o_we <= '0';
      o_en <= '0';
      --gestione del comportamento per ogni stato
      case cur_state is
        when s0 =>  --stato di IDLE
        o_done <= '0';
        when Reset =>  --stato di reset, azzera i contatori e gli indirizzi
          o_en <= '0';
          o_we <= '0';
          sel_increaseAddress <= '0';
          rstream_load <= '0';
          rAddress_load <= '1';
          sel_decreaseCounter <= '0';
          rCounter_load <= '1';
          sel_increseMemAddress <= '0';
          rMemAddress_load <= '1';
          sel_saveLastBit <= '0';
          rAddOn_load <= '1';
          start_convolution <= '0';
        when InitLoad =>  --stato iniziale, carica il numero di parole da leggere, e si prepara a leggere la prima parola
          o_en <= '1';
          o_we <= '0';
          sel_increaseAddress <= '1';
          sel_AddressOutput <= '0';
          rCounter_load <= '0';
          rAddress_load <= '1';
          rMemAddress_load <= '0';
        when WaitMem1 => --aspetta che la parola sia effettivamente caricata
          rmaxAddress_load <= '1';
        when Load => --stato di Load, carica la parola corrente, si prepara a leggere la successiva
          o_en <= '1';
          o_we <= '0';
          sel_increaseAddress <= '1';
          rAddress_load <= '1';
          rMemAddress_load <= '0';
          sel_AddressOutput <= '0';
          sel_decreaseCounter <= '0';
          rCounter_load <= '1';
          rAddOn_load1 <= '0';
          start_convolution <= '0';
        when WaitMem2 => --aspetta che la parola sia effettivamente caricata
          rstream_load <= '1';
        when InitConvolution => --setta i segnali per iniziare la convoluzione
          o_en <= '0';
          o_we <= '0';
          rstream_load <= '0';
          rAddress_load <= '0';
          sel_decreaseCounter <= '1';
          rCounter_load <= '1';
        when Convolute => 
           sel_decreaseCounter <= '1';
           rCounter_load <= '1';
           sel_saveLastBit <= '1';
           rAddOn_load1 <= '1';
           start_convolution <= '1';
        when WaitP =>
           rP1_load  <= '1';
           rP2_load  <= '1';
        when SaveP1 => 
           o_en <= '1';
           o_we <= '1'; 
           sel_decreaseCounter <= '0';
           rCounter_load <= '0';
           sel_increseMemAddress <= '1';
           rMemAddress_load <= '1';
           sel_AddressOutput  <= '1';
           sel_DataOutput <= '0';
           start_convolution <= '0';
           rP1_load  <= '0';
           rP2_load  <= '0';
         when SaveP2 =>
           o_en <= '1';
           o_we <= '1'; 
           sel_increseMemAddress <= '1';
           rMemAddress_load <= '1';
           sel_AddressOutput  <= '1';
           sel_DataOutput <= '1';       
         when CloseMem => 
           o_done <= '1';
           o_en <= '0';
           o_we <= '0'; 
         when Done =>
           o_done <= '1';
      end case;
    end process;

end Behavioral;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
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
          rAddOn_load1           : in STD_LOGIC;
          rAddOn_load               : in STD_LOGIC;
          rP1_load                       : in STD_LOGIC;
          rP2_load                       : in STD_LOGIC;
          sel_increaseAddress : in STD_LOGIC;
          sel_decreaseCounter : in STD_LOGIC;
          sel_increseMemAddress : in STD_LOGIC;
          sel_AddressOutput : in STD_LOGIC;
          sel_DataOutput : in STD_LOGIC;
          sel_saveLastBit : in STD_LOGIC;
          start_convolution : in STD_LOGIC;
          o_data            : out  STD_LOGIC_VECTOR(7 downto 0);
          o_address         : out STD_LOGIC_VECTOR(15 downto 0);
          o_endWord      : out STD_LOGIC;
          o_endFile         : out  STD_LOGIC);
end datapath;

architecture Behavioral of datapath is
  signal o_rStream : STD_LOGIC_VECTOR(7 downto 0);
  signal o_rAddOn : STD_LOGIC_VECTOR(1 downto 0);
  signal ConvInput : STD_LOGIC_VECTOR(9 downto 0);
  signal data_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal o_rMaxAddress : STD_LOGIC_VECTOR(7 downto 0);
  signal mux_rAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal o_rAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal MaxAddress_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal address_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal endFile_sub : STD_LOGIC_VECTOR(15 downto 0);
  signal P1k  : STD_LOGIC_VECTOR(7 downto 0);
  signal P2k : STD_LOGIC_VECTOR(7 downto 0);
  signal P1  : STD_LOGIC_VECTOR(7 downto 0);
  signal P2 : STD_LOGIC_VECTOR(7 downto 0);
  signal o_rMemAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal mux_rMemAddress : STD_LOGIC_VECTOR(15 downto 0);
  signal mux_rAddOn : STD_LOGIC_VECTOR(1 downto 0);
  signal MemAddress_sum : STD_LOGIC_VECTOR(15 downto 0);
  signal o_datatemp : STD_LOGIC_VECTOR(15 downto 0);
  signal rAddOn_load2 : STD_LOGIC;
  signal o_rCounter : integer ; 
  signal mux_rCounter : integer ;
  signal rCounter_sub : integer ;
  signal tempData : integer ;
  signal tempAddress : integer;
begin

--configurazione del registro Stream
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rStream <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rStream_load = '1') then
        o_rStream <= ( i_data);
      end if;
    end if;
  end process;
  
  --configurazione del registro AddOn
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rAddOn  <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rAddOn_load1 = '1' and rAddOn_load2 = '1') then
        o_rAddOn  <=  mux_rAddOn;
      end if;
      if(rAddOn_load = '1') then
        o_rAddOn  <=  mux_rAddOn;
      end if;
    end if;
  end process;
  
  with o_rCounter select  rAddOn_load2 <=   
    '1' when 6,
    '0' when others;
    
   --configurazione mux per il registro AddOn
  with sel_saveLastBit select  mux_rAddOn <=   
    (others => '0') when '0',
    o_rStream(1 downto 0)   when '1',
    (others => '0') when others;
    
--configurazione ConvInput
    ConvInput  <= (o_rAddOn & o_rStream);
    
  --configurazione MaxAddressSum, aumenta di 1 il MaxAddress
    tempData <= (to_integer(unsigned(o_rMaxAddress)) + 1);
    MaxAddress_sum <= std_logic_vector(to_unsigned(tempData, MaxAddress_sum 'length));

  --configurazione del registro MaxAddress
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      o_rMaxAddress <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rMaxAddress_load = '1') then
        o_rMaxAddress <= i_data; 
      end if;
    end if;
  end process;
  
  --configurazione del nodo sommatore address_sum 
  tempAddress  <= (to_integer(unsigned(o_rAddress)) + 1);
  address_sum <= std_logic_vector(to_unsigned(tempAddress, address_sum 'length));

  --configurazione mux per l'aumento o il reset del contatore Address
  with sel_increaseAddress select  mux_rAddress <=   
    (others => '0') when '0',
    address_sum  when '1',
    (others => '0') when others;

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
    
  --configurazione endFIle_sub, si occupa di confrontare il MaxAddress con l?ndirizzo corrrente (o_raddress) aumentato di 1 => address_sum
  endFile_sub <= std_logic_vector(unsigned(MaxAddress_sum) - unsigned(o_rAddress ));
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
  o_endWord <= '1' when (rCounter_sub  = -1) else '0';
 
  
  --configurazione mux per il decremento o il reset del contatore Counter
  with sel_decreaseCounter select mux_rCounter <=   
    8 when '0',
    rCounter_sub   when '1',
    10 when others;
    
  --processo convolutore  
  process(i_clk, i_rst)
  begin
    if (i_rst = '1' or o_rCounter = 8) then
      P1k <= (others => '0');
      P2k <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
        if (start_convolution = '1') then
            case (o_rCounter) is
                when 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 =>
                    P1k (o_rCounter ) <= (ConvInput(o_rCounter) xor ConvInput(o_rCounter + 2));
                    P2k (o_rCounter ) <= (ConvInput(o_rCounter) xor ConvInput(o_rCounter + 1) xor ConvInput(o_rCounter + 2));
                when others =>
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
    (others => '0') when others;
    
    --configurazione mux per output address 
    with sel_AddressOutput select o_address <=
    o_rAddress when '0',
    o_rMemAddress when '1',
    (others => 'X') when others;
    
    --configurazione del registro P1
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      P1 <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rP1_load = '1') then
            P1(7) <= P1k (7);
            P1(6) <= P2k(7); 
            P1(5) <= P1k (6);
            P1(4) <= P2k(6); 
            P1(3) <= P1k (5);
            P1(2) <= P2k (5);
            P1(1) <= P1k (4);
            P1(0) <= P2k (4);
      end if;
    end if;
  end process;
    
        --configurazione del registro P2
  process(i_clk, i_rst)
  begin
    if (i_rst = '1') then
      P2 <= (others => '0');
    elsif i_clk'event and i_clk = '1' then
      if(rP2_load = '1') then
                P2(7) <= P1k (3);
                P2(6) <= P2k(3); 
                P2(5) <= P1k (2);
                P2(4) <= P2k(2); 
                P2(3) <= P1k (1);
                P2(2) <= P2k (1);
                P2(1) <= P1k (0);
                P2(0) <= P2k (0);
      end if;
    end if;
  end process;

     --configurazione mux per output address 
    with sel_DataOutput select o_data <=
    P1 when '0',
    P2 when '1',
    (others => 'X') when others;
    
end Behavioral;
