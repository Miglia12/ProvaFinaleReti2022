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
            i_getStream       : in  std_logic;
            i_increaseCounter : in  std_logic;
            rstream_load      : in  std_logic;
            rmaxAddress_load  : in  std_logic;
            rcounter_load     : in  std_logic;
            o_endFile         : in  std_logic);
    end component;

signal i_getStream  std_logic;
signal i_increaseCounter std_logic;
signal rstream_load std_logic;
signal rmaxAddress_load std_logic;
signal rcounter_load std_logic;
signal o_endFile std_logic;
signal o_address std_logic_vector(15 downto 0);
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
        i_getStream;
        i_increaseCounter;
        rstream_load;
        rmaxAddress_load;
        rcounter_load;
        o_endFile
    );


end Behavioral;
