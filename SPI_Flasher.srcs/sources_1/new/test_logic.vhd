----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.09.2019 22:16:33
-- Design Name: 
-- Module Name: test_logic - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_logic is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           busy : in STD_LOGIC;
           req : out STD_LOGIC := '0';
           data_in : in STD_LOGIC_VECTOR (7 downto 0);
           address : out STD_LOGIC_VECTOR (31 downto 0);
           requested_bytes : out UNSIGNED (7 downto 0) := (others => '0');
           done : in STD_LOGIC;
           anode           : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1'); --anode and cathode are active low
           cathode         : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1')
           );
end test_logic;

architecture Behavioral of test_logic is

COMPONENT segment_display
port(
       clk             : in  STD_LOGIC;
       rst             : in STD_LOGIC;
       number          : in  STD_LOGIC_VECTOR (31 downto 0);
       anode           : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1'); --anode and cathode are active low
       cathode         : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1')
    );
end COMPONENT;
type state_type is (request,wait_for_data,wait1,wait2);
signal state : state_type:= request; -- current and next state

signal number_sig : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
signal data4 : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
signal counter : unsigned(26 downto 0) := (others => '0');
begin

inst_segment_display : segment_display
port map
(
    clk => clk,
    rst => rst,
    number => number_sig,
    anode => anode,
    cathode => cathode
);


process(clk)
begin
    if rising_edge(clk) then
        if(rst = '0') then
        
        else
            req <= '0';
            address <= (others => '0');
            requested_bytes <= to_unsigned(3,8);
            number_sig <= number_sig;
            data4 <= data4;
            state <= state;
            case (state) is
                when request =>
                    req <= '1';
                    state <= wait1;
                
                when wait1 =>
                    state <= wait_for_data;
                
                when wait_for_data =>
                    if(done = '1' and busy = '1') then
                        number_sig(7 downto 0) <= data_in;
                        state <= wait2;
                    elsif(busy = '1' and done = '0')then
                        state <= wait_for_data;
                    else
                        state <= wait_for_data;
                    end if;
                when wait2 =>
                    if(counter = 100000000) then
                        counter <= (others => '0');
                        state <= request;
                    else
                        counter <= counter + 1;
                        state <= wait2;
                    end if;
            
            end case;
        end if;
 
    end if;
end process;

end Behavioral;
