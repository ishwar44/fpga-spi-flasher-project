----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.09.2019 12:26:36
-- Design Name: 
-- Module Name: flash_logic - Behavioral
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

entity flash_logic is
    GENERIC(
		clk_freq	:	INTEGER		:= 100000000;
		uart_data_width		:	INTEGER		:= 8);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           uart_tx_en : out STD_LOGIC;
           uart_tx_data :out STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_tx_busy : in STD_LOGIC;
           uart_rx_data :in STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_rx_busy : in STD_LOGIC;
           led : out STD_LOGIC_VECTOR(15 downto 0)  := (others => '0')
           
           );
end flash_logic;

architecture Behavioral of flash_logic is
type state_type is (wait_for_clock,uart_test,wait_for_uart);
signal state,next_state,saved_state,next_saved_state: state_type:= uart_test; -- current and next state
constant Hello_msg : String (1 to 12) := "Hello,World!";
signal current_index : unsigned(7 downto 0) := (others => '0');
signal next_index : unsigned(7 downto 0) := (others => '0');
begin

SYNC_PROC: process (clk) 
  begin
    if rising_edge(clk) then
      if (rst = '0') then 
        state <= uart_test;
        saved_state <= uart_test;
        current_index <= (others => '0');
      else
        state <= next_state;
        current_index <= next_index;
        saved_state <= next_saved_state;
      end if;
    end if;
  end process;


  OUTPUT_DECODE: process (state,saved_state,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index)
  begin
    uart_tx_en <= '0';
    uart_tx_data <= (others => '0');
    led <= (others => '0');
    
    case (state) is
      when uart_test =>
        uart_tx_data <=  std_logic_vector( to_unsigned( character'pos(Hello_msg(to_integer(current_index)+ 1)), uart_data_width));
        if(uart_tx_busy = '0') then
            uart_tx_en <= '1';
        else
            uart_tx_en <= '0';
        end if;
        
      when wait_for_uart =>
        led <= (others => '1');
      when wait_for_clock =>
        
      when others => 
         uart_tx_en <= '0';
         uart_tx_data <= (others => '0');
    end case;
  end process;


  NEXT_STATE_DECODE: process (state ,saved_state ,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index)
  begin
  
    next_state <= state;
    next_index <= current_index;
    next_saved_state <= saved_state;
    case (state) is
      when wait_for_clock =>
        next_state <= saved_state;
      when uart_test =>
        if(uart_tx_busy = '0') then 
            if(current_index = 11) then
                next_index <=(others => '0');
                next_state <= wait_for_uart;
            else
                next_index <= current_index + 1;
                next_state <= wait_for_clock;
                next_saved_state <= uart_test;
            end if;
         else
            next_state <= uart_test;
         end if;
        
      when wait_for_uart =>
      
      
      when others =>  
        next_state <= uart_test;
    end case;
  end process;


end Behavioral;
