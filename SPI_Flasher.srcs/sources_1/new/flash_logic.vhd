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
use work.util.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity flash_logic is
    GENERIC(
		clk_freq	:	INTEGER		:= 100000000;
		uart_data_width		:	INTEGER		:= 8;
		spi_data_width		:	INTEGER		:= 8;
		spi_cmd_width		:	INTEGER		:= 8;
		memory_size         :   INTEGER     :=  131072--in bytes
		);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           uart_tx_en : out STD_LOGIC;
           uart_tx_data :out STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_tx_busy : in STD_LOGIC;
           uart_rx_data :in STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_rx_busy : in STD_LOGIC;
           led : out STD_LOGIC_VECTOR(15 downto 0)  := (others => '0');
           rw_sig : out std_logic := '0';
           cont_spi : out std_logic := '0';
           SPI_CMD_out : out STD_LOGIC_VECTOR(spi_cmd_width - 1 downto 0)  := (others => '0');
           SPI_data_out : out STD_LOGIC_VECTOR(spi_data_width - 1 downto 0)  := (others => '0');
           mode_sel : out STD_LOGIC_VECTOR(1 downto 0)  := (others => '0');
           cmd_only : out STD_LOGIC:= '0';
           SPI_data_in : in STD_LOGIC_VECTOR(spi_data_width - 1 downto 0)
           );
end flash_logic;

architecture Behavioral of flash_logic is
type byte_arr is array (0 to 255) of std_logic_vector(7 downto 0);
type state_type is (wait_for_clock,uart_welecome,wait_for_uart,get_uart_data,check_cmd_byte,send_uart_data,send_to_spi,wait_for_uart_main,get_uart_data_main);
signal state,next_state,saved_state,next_saved_state: state_type:= uart_welecome; -- current and next state
constant Hello_msg : String (1 to 12) := "Hello,World!";

signal current_index : unsigned(7 downto 0) := (others => '0');
signal next_index : unsigned(7 downto 0) := (others => '0');

signal current_uart_data : std_logic_vector(uart_data_width -1 downto 0);
signal next_uart_data : std_logic_vector(uart_data_width -1 downto 0);

signal current_address : unsigned(n_bits(memory_size-1) -1 downto 0);
signal next_address : unsigned(n_bits(memory_size-1) -1 downto 0);

signal current_data : byte_arr := (others => (others => '0'));
signal next_data : byte_arr := (others => (others => '0'));
begin

SYNC_PROC: process (clk) 
  begin
    if rising_edge(clk) then
      if (rst = '0') then 
        state <= uart_welecome;
        saved_state <= uart_welecome;
        current_index <= (others => '0');
        current_uart_data <= (others => '0');
        current_address <= (others => '0');
        current_data <= (others => (others => '0'));
      else
        state <= next_state;
        current_index <= next_index;
        saved_state <= next_saved_state;
        current_uart_data <= next_uart_data;
        current_address <= next_address;
        current_data <= next_data;
      end if;
    end if;
  end process;


  OUTPUT_DECODE: process (state,saved_state,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index,current_uart_data,current_address,current_data)
  begin
    uart_tx_en <= '0';
    uart_tx_data <= (others => '0');
    led <= (others => '0');
    
    case (state) is
      when uart_welecome =>
        uart_tx_data <=  std_logic_vector( to_unsigned( character'pos(Hello_msg(to_integer(current_index)+ 1)), uart_data_width));
        if(uart_tx_busy = '0') then
            uart_tx_en <= '1';
        else
            uart_tx_en <= '0';
        end if;
        
      when wait_for_uart =>
        
        
      when get_uart_data =>
        led(15 downto 1) <=(others => '0') ;
        led(0) <= uart_rx_busy;
     
     when check_cmd_byte =>
     
     when wait_for_uart_main =>
               
               
     when get_uart_data_main =>
       led(15 downto 1) <=(others => '0') ;
       led(0) <= uart_rx_busy;
        
        
      
      when send_uart_data =>
      led(15 downto 2) <=(others => '0') ;
      led(1) <= uart_rx_busy;
      led(0) <= '0' ;
       uart_tx_data <=  current_data(to_integer(current_index));
       if(uart_tx_busy = '0') then
           uart_tx_en <= '1';
       else
           uart_tx_en <= '0';
       end if;
       
       when send_to_spi =>
       
      
      when wait_for_clock =>
        
      
      when others => 
         uart_tx_en <= '0';
         uart_tx_data <= (others => '0');
    end case;
  end process;


  NEXT_STATE_DECODE: process (state ,saved_state ,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index,current_uart_data,current_address,current_data)
  begin
  
    next_state <= state;
    next_index <= current_index;
    next_saved_state <= saved_state;
    next_uart_data <= current_uart_data;
    next_address <= current_address;
    next_data <= current_data;
    case (state) is
      when wait_for_clock =>
        next_state <= saved_state;
        
      when uart_welecome =>
        if(uart_tx_busy = '0') then 
            if(current_index = 11) then
                next_index <=(others => '0');
                next_state <= wait_for_uart;
            else
                next_index <= current_index + 1;
                next_state <= wait_for_clock;
                next_saved_state <= uart_welecome;
            end if;
         else
            next_state <= uart_welecome;
         end if;
        
      when wait_for_uart =>
        if(uart_rx_busy = '1') then
            next_state <= get_uart_data;
        else
            next_state <= wait_for_uart;
        end if;
      
      when get_uart_data =>
         if(uart_rx_busy = '0') then
             next_state <= check_cmd_byte;
             next_uart_data <= uart_rx_data;
         else
             next_state <= get_uart_data;
         end if;
     
     when check_cmd_byte =>
        next_index <= (others => '0');
        if (current_uart_data = "01110100") then --t for test currently  just echoing uart data
            next_state <= wait_for_uart_main;
            next_uart_data <= (others => '0');
        elsif (current_uart_data = "01100110") then -- f to flash memory at address 0
        
        elsif (current_uart_data = "01110111") then -- w to write to memory at a given address
        
        elsif (current_uart_data = "01110011") then -- s to read from the start of memory
        
        elsif (current_uart_data = "01110010") then -- r to read from the memory at a given address
        
        else
            next_state <= wait_for_uart;
        end if;
        
     
     when wait_for_uart_main =>
        if(uart_rx_busy = '1') then
            next_state <= get_uart_data_main;
        else
            next_state <= wait_for_uart_main;
        end if;
      
      when get_uart_data_main =>
         if(uart_rx_busy = '0') then
             next_data(to_integer(current_index)) <= uart_rx_data;
             if(current_index = 15) then
                next_index <= (others => '0');
                next_state <= send_uart_data;
             else
                next_index <= current_index + 1;
                next_state <= wait_for_uart_main;
             end if;
         else
             next_state <= get_uart_data_main;
         end if;
        
         
     when send_uart_data =>
        if(uart_tx_busy = '0') then
           if(current_index = 15) then
              next_index <= (others => '0');
              next_state <= check_cmd_byte;
           else
              next_state <= wait_for_clock;
              next_saved_state <= send_uart_data;
              next_index <= current_index + 1;
           end if;
        else
            next_state <= send_uart_data;
        end if;
       
        
     when send_to_spi =>
        
      
      
      when others =>  
        next_state <= uart_welecome;
    end case;
  end process;


end Behavioral;
