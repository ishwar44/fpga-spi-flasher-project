-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 15.9.2019 18:00:42 GMT

library ieee;
use ieee.std_logic_1164.all;

entity tb_top_level is
end tb_top_level;

architecture tb of tb_top_level is

    component top_level
        port (clk           : in std_logic;
              rst           : in std_logic;
              tx            : out std_logic;
              rx            : in std_logic;
              LED           : out std_logic_vector (15 downto 0);
              sdio          : inout std_logic;
              sdio1         : inout std_logic;
              sdio2         : inout std_logic;
              sdio3         : inout std_logic;
              command_debug : in std_logic);
    end component;

    signal clk           : std_logic;
    signal rst           : std_logic;
    signal tx            : std_logic;
    signal rx            : std_logic;
    signal LED           : std_logic_vector (15 downto 0);
    signal sdio          : std_logic;
    signal sdio1         : std_logic;
    signal sdio2         : std_logic;
    signal sdio3         : std_logic;
    signal command_debug : std_logic;

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : top_level
    port map (clk           => clk,
              rst           => rst,
              tx            => tx,
              rx            => rx,
              LED           => LED,
              sdio          => sdio,
              sdio1         => sdio1,
              sdio2         => sdio2,
              sdio3         => sdio3,
              command_debug => command_debug);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        rst <= '1';
        rx <= '1';
        command_debug <= '1';
        wait;
    end process;

end tb;

