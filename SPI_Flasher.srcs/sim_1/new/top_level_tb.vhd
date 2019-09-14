-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 14.9.2019 12:25:32 GMT

library ieee;
use ieee.std_logic_1164.all;

entity tb_top_level is
end tb_top_level;

architecture tb of tb_top_level is

    component top_level
        port (clk : in std_logic;
              rst : in std_logic;
              tx  : out std_logic;
              rx  : in std_logic;
              LED : out std_logic_vector (15 downto 0));
    end component;

    signal clk : std_logic;
    signal rst : std_logic;
    signal tx  : std_logic;
    signal rx  : std_logic;
    signal LED : std_logic_vector (15 downto 0);

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : top_level
    port map (clk => clk,
              rst => rst,
              tx  => tx,
              rx  => rx,
              LED => LED);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        rst <= '1';
        rx <= '1';

        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_top_level of tb_top_level is
    for tb
    end for;
end cfg_tb_top_level;