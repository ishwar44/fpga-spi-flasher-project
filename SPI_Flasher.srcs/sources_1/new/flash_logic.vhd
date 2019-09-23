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
use WORK.util.all;

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
		memory_size         :   INTEGER     :=  32768--in bytes
		);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           uart_tx_en : out STD_LOGIC;
           uart_tx_data :out STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_tx_busy : in STD_LOGIC;
           uart_rx_data :in STD_LOGIC_VECTOR(uart_data_width - 1 downto 0);
           uart_rx_busy : in STD_LOGIC;
           led : out STD_LOGIC_VECTOR(15 downto 0)  := (others => '0');
           rw : out std_logic := '0';
           cont_spi : out std_logic := '0';
           SPI_CMD_out : out STD_LOGIC_VECTOR(spi_cmd_width - 1 downto 0)  := (others => '0');
           SPI_data_out : out STD_LOGIC_VECTOR(spi_data_width - 1 downto 0)  := (others => '0');
           mode_sel : out STD_LOGIC_VECTOR(1 downto 0)  := (others => '0');
           cmd_only : out STD_LOGIC:= '0';
           SPI_data_in : in STD_LOGIC_VECTOR(spi_data_width - 1 downto 0);
           SPI_busy : in std_logic;
           SPI_ena : out std_logic;
           command_debug :in STD_LOGIC
           );
end flash_logic;

architecture Behavioral of flash_logic is
type byte_arr is array (0 to 255) of std_logic_vector(7 downto 0);
constant Number_of_Address_Bytes: positive := 2;
type address_bytes is array (0 to Number_of_Address_Bytes) of unsigned(7 downto 0);
type state_type is (wait_for_clock,uart_welecome,wait_for_uart_cmd,get_uart_data_cmd,check_cmd_byte,send_uart_data,send_to_spi,flash_memory_address,flash_memory_data,set_num_bytes,read_from_start_address,read_from_start_data,wait_for_uart,get_uart_data,set_address,get_status,set_dual_mode,set_quad_mode,set_write_enable,misc_read,misc_write,misc_single);
signal state,next_state,saved_state,next_saved_state: state_type:= uart_welecome; -- current and next state
constant Hello_msg : String (1 to 12) := "Hello,World!";

signal current_index : unsigned(7 downto 0) := (others => '0');
signal next_index : unsigned(7 downto 0) := (others => '0');

signal current_uart_data : std_logic_vector(uart_data_width -1 downto 0);
signal next_uart_data : std_logic_vector(uart_data_width -1 downto 0);

signal current_address : address_bytes :=(others => (others => '0'));
signal next_address :address_bytes :=(others => (others => '0'));

signal current_data : byte_arr := (others => (others => '0'));
signal next_data : byte_arr := (others => (others => '0'));

signal current_num_bytes : unsigned(7 downto 0) := to_unsigned(4,8);
signal next_num_bytes : unsigned(7 downto 0) := to_unsigned(4,8);

signal current_spi_mode : std_logic_vector(1 downto 0) := (others => '0');
signal next_spi_mode : std_logic_vector(1 downto 0) := (others => '0');

signal current_dummy_bytes : positive := 1;
signal next_dummy_bytes : positive := 1;

signal current_misc_command : std_logic_vector(7 downto 0) := (others => '0');
signal next_misc_command : std_logic_vector(7 downto 0) := (others => '0');

constant write_ins : std_logic_vector(7 downto 0) := "00000010";
constant read_ins : std_logic_vector(7 downto 0) := "00000011";
constant dual_ins : std_logic_vector(7 downto 0) := "00111011";
constant quad_ins : std_logic_vector(7 downto 0) := "00111000";
constant reset_ins : std_logic_vector(7 downto 0) := "11111111";
constant write_en_ins : std_logic_vector(7 downto 0) := "00000110";
constant write_dis_ins : std_logic_vector(7 downto 0) := "00000100";



begin

SYNC_PROC: process (clk) 
  begin
    if rising_edge(clk) then
      if (rst = '0') then 
        state <= uart_welecome;
        saved_state <= uart_welecome;
        current_index <= (others => '0');
        current_uart_data <= (others => '0');
        current_address <= (others => (others => '0'));
        current_data <= (others => (others => '0'));
        current_num_bytes <= to_unsigned(4,8);
        current_spi_mode <= (others => '0');
        current_dummy_bytes <= 1;
        current_misc_command <=(others => '0');
      else
        state <= next_state;
        current_index <= next_index;
        saved_state <= next_saved_state;
        current_uart_data <= next_uart_data;
        current_address <= next_address;
        current_data <= next_data;
        current_num_bytes <= next_num_bytes;
        current_spi_mode <= next_spi_mode;
        current_dummy_bytes <= next_dummy_bytes;
        current_misc_command <= next_misc_command;
      end if;
    end if;
  end process;


  OUTPUT_DECODE: process (state,saved_state,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index,current_uart_data,current_address,current_data,current_num_bytes,SPI_busy,command_debug,current_spi_mode,current_dummy_bytes,current_misc_command)
  begin
    uart_tx_en <= '0';
    uart_tx_data <= (others => '0');
    led <= (others => '0');
    rw <= '0';
    cont_spi <= '0';
    SPI_CMD_out <= (others => '0');
    SPI_data_out <= (others => '0');
    mode_sel <= current_spi_mode;
    cmd_only <= '0';
    SPI_ena <= '0';
    case (state) is
      when uart_welecome =>
        uart_tx_data <=  std_logic_vector( to_unsigned( character'pos(Hello_msg(to_integer(current_index)+ 1)), uart_data_width));
        if(uart_tx_busy = '0') then
            uart_tx_en <= '1';
        else
            uart_tx_en <= '0';
        end if;
        
      when wait_for_uart_cmd =>
      
      when wait_for_uart =>
      
      when get_uart_data =>
        
      when get_uart_data_cmd =>
        led(15 downto 1) <=(others => '0') ;
        led(0) <= uart_rx_busy;
     
     when check_cmd_byte =>
     

        
     
      
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
       
       
       when flash_memory_address =>
         SPI_CMD_out <= write_ins;
         if(current_uart_data = "01100110") then
            SPI_data_out <= (others => '0');
         else
            SPI_data_out <= std_logic_vector(current_address(to_integer(current_index)));
         end if;    
         rw <= '1';
         cont_spi <= '1';
         SPI_ena <= '1';
       
       when flash_memory_data =>
        SPI_CMD_out <= write_ins;
        SPI_data_out <= current_data(to_integer(current_index));
        rw <= '1';
        cont_spi <= '1';
        SPI_ena <= '1';
      
      when read_from_start_address =>
        SPI_CMD_out <= read_ins;
        if(current_uart_data = "01110011") then
            SPI_data_out <= (others => '0');
        else
            SPI_data_out <= std_logic_vector(current_address(to_integer(current_index)));
        end if;
        rw <= '1';
        cont_spi <= '1';
        SPI_ena <= '1';
      
     when read_from_start_data =>
        SPI_CMD_out <= read_ins;
        SPI_data_out <= (others => '0');
        rw <= '0';
        cont_spi <= '1';
        SPI_ena <= '1';
      
      when wait_for_clock =>
      
      when get_status =>
        if(current_index <= Number_of_Address_Bytes) then
            uart_tx_data <=  std_logic_vector(current_address(to_integer(current_index)));
        else
            uart_tx_data <= std_logic_vector(current_num_bytes);
        end if; 
         if(uart_tx_busy = '0') then
             uart_tx_en <= '1';
         else
             uart_tx_en <= '0';
         end if;
      
      when set_dual_mode =>
        cmd_only <= '1';
        SPI_CMD_out <= dual_ins;
        SPI_ena <= '1';
      
      when set_quad_mode =>
        cmd_only <= '1';
        SPI_CMD_out <= quad_ins;
        SPI_ena <= '1';
      
      when set_write_enable =>
          cmd_only <= '1';
          SPI_CMD_out <= write_en_ins;
          SPI_ena <= '1';
      
      
      when misc_read =>
         SPI_CMD_out <= current_data(0);
         SPI_data_out <= (others => '0');
         rw <= '0';
         cont_spi <= '1';
         SPI_ena <= '1';
      
      when misc_write =>
        SPI_CMD_out <= current_misc_command;
        SPI_data_out <= current_data(to_integer(current_index));
        rw <= '1';
        cont_spi <= '1';
        SPI_ena <= '1';
        
      when misc_single =>
        cmd_only <= '1';
        SPI_CMD_out <= current_data(0);
        SPI_ena <= '1';
      
      when others => 
         uart_tx_en <= '0';
         uart_tx_data <= (others => '0');
    end case;
  end process;


  NEXT_STATE_DECODE: process (state ,saved_state ,uart_tx_busy,uart_rx_data,uart_rx_busy,current_index,current_uart_data,current_address,current_data,current_num_bytes,SPI_busy,command_debug,current_spi_mode,current_dummy_bytes,current_misc_command)
  begin
  
    next_state <= state;
    next_index <= current_index;
    next_saved_state <= saved_state;
    next_uart_data <= current_uart_data;
    next_address <= current_address;
    next_data <= current_data;
    next_num_bytes <= current_num_bytes;
    next_spi_mode <= current_spi_mode;
    next_dummy_bytes <= current_dummy_bytes;
    next_misc_command <= current_misc_command;
    case (state) is
      when wait_for_clock =>
        next_state <= saved_state;
        
      when uart_welecome =>
        if(uart_tx_busy = '0') then 
            if(current_index = 11) then
                next_index <=(others => '0');
                next_state <= wait_for_uart_cmd;
            else
                next_index <= current_index + 1;
                next_state <= wait_for_clock;
                next_saved_state <= uart_welecome;
            end if;
         else
            next_state <= uart_welecome;
         end if;
        
      when wait_for_uart_cmd =>
        if(uart_rx_busy = '1') then
            next_state <= get_uart_data_cmd;
        else
            next_state <= wait_for_uart_cmd;
        end if;
        if(command_debug = '1') then
            next_data(0) <= "01100110";
            next_data(1) <= "00110001";
            next_data(2) <= "00110010";
            next_data(3) <= "00110011";
            next_state <= check_cmd_byte;
        end if;
      
      when get_uart_data_cmd =>
        if(uart_rx_busy = '0') then
           next_uart_data <= uart_rx_data;
           next_state <= check_cmd_byte;
       else
           next_state <= get_uart_data_cmd;
       end if;
     
     when check_cmd_byte =>
        next_index <= (others => '0');
        --next_uart_data <= (others => '0');
        if (current_uart_data = "01110100") then --t for test currently  just echoing uart data
            next_state <= send_uart_data;
        elsif (current_uart_data = "01100110") then -- f to flash memory at address 0
            next_state <= flash_memory_address;
        elsif (current_uart_data = "01110111") then -- w to write to memory at a given address
            next_state <= flash_memory_address;
        elsif (current_uart_data = "01110011") then -- s to read from the start of memory
            next_state <= read_from_start_address;
        elsif (current_uart_data = "01110010") then -- r to read from the memory at a given address
            next_state <= read_from_start_address;
        elsif (current_uart_data = "01100001") then  -- a to set the address
            next_state <= wait_for_uart;
        elsif (current_uart_data = "01100010") then  -- b to set the number of bytes
            next_state <= wait_for_uart;
        elsif (current_uart_data = "01100101") then  -- e to enable the write access
            next_state <= set_write_enable;
        elsif (current_uart_data = "01100111") then  -- g to get data from uart
            next_state <= wait_for_uart;
        elsif (current_uart_data = "01111000") then  -- x to get the status of the flaher on the uart
            next_state <= get_status;
        elsif (current_uart_data = "01100100") then  -- d to put the memory and SPI port into dual SPI mode
            next_state <= set_dual_mode;
        elsif (current_uart_data = "01110001") then  -- q to put the memory and SPI port into quad SPI mode
            next_state <= set_quad_mode;
        elsif (current_uart_data = "01010010") then  -- R misc read use the g command to load the command
            next_state <= wait_for_uart;
        elsif (current_uart_data = "01010111") then  -- W misc read use the g command to load the command
            next_state <= misc_write;
            next_misc_command <= current_data(0);
            next_index <= to_unsigned(1,8);
        elsif (current_uart_data = "00110001") then  -- 1 misc to send 1 byte.
            next_state <= misc_single;
        else
            next_state <= wait_for_uart_cmd;
        end if;
      
     when wait_for_uart =>
        if(uart_rx_busy = '1') then
             next_state <= get_uart_data;
         else
             next_state <= wait_for_uart;
         end if;
         
     when get_uart_data =>
        if(uart_rx_busy = '0') then
            if(current_uart_data = "01100010") then
                next_data(to_integer(current_index)) <= uart_rx_data;
                next_state <= set_num_bytes;
            elsif(current_uart_data = "01100001") then
                next_data(to_integer(current_index)) <= uart_rx_data;
                if(current_index = Number_of_Address_Bytes) then
                   next_index <= (others => '0');
                   next_state <= set_address;
                else
                   next_index <= current_index + 1;
                   next_state <= wait_for_uart;
                end if;
            elsif(current_uart_data = "01010010") then
                next_data(0) <= uart_rx_data;
                next_state <= misc_read;
            else
                next_data(to_integer(current_index)) <= uart_rx_data;
                if(current_index = current_num_bytes - 1) then
                   next_index <= (others => '0');
                   next_state <= wait_for_uart_cmd;
                else
                   next_index <= current_index + 1;
                   next_state <= wait_for_uart;
                end if;
            end if;
        else
            next_state <= get_uart_data;
        end if;
        
     
         
     when send_uart_data =>
        if(uart_tx_busy = '0') then
           if(current_index = current_num_bytes - 1) then
              next_index <= (others => '0');
              next_state <= wait_for_uart_cmd;
           else
              next_state <= wait_for_clock;
              next_saved_state <= send_uart_data;
              next_index <= current_index + 1;
           end if;
        else
            next_state <= send_uart_data;
        end if;
       
     when  flash_memory_address =>
         if(SPI_busy = '0') then
           if(current_index = Number_of_Address_Bytes) then
              next_index <= (others => '0');
              next_state <= flash_memory_data;
           else
              next_state <= wait_for_clock;
              next_saved_state <= flash_memory_address;
              next_index <= current_index + 1;
           end if;
        else
            next_state <= flash_memory_address;
        end if;
    
     when  flash_memory_data =>
        if(SPI_busy = '0') then
          if(current_index = current_num_bytes - 1) then
             next_index <= (others => '0');
             next_state <= wait_for_uart_cmd;
          else
             next_state <= wait_for_clock;
             next_saved_state <= flash_memory_data;
             next_index <= current_index + 1;
          end if;
       else
           next_state <= flash_memory_data;
       end if;
     
     when read_from_start_address =>
         if(SPI_busy = '0') then
           if(current_index = Number_of_Address_Bytes) then
              next_index <= (others => '0');
              next_state <= read_from_start_data;
           else
              next_state <= wait_for_clock;
              next_saved_state <= read_from_start_address;
              next_index <= current_index + 1;
           end if;
        else
            next_state <= read_from_start_address;
        end if;
        
     when read_from_start_data =>
        if(SPI_busy = '0') then
           if(current_index > current_dummy_bytes - 1) then
            next_data(to_integer(current_index)-current_dummy_bytes) <= SPI_data_in;
           end if;
           if(current_index = current_num_bytes + current_dummy_bytes - 1 ) then
              next_index <= (others => '0');
              next_state <= send_uart_data; -- this is for debug purposes 
           else
              next_state <= wait_for_clock;
              next_saved_state <= read_from_start_data;
              next_index <= current_index + 1;
           end if;
        else
            next_state <= read_from_start_data;
        end if;
     
     
        
     
     when set_num_bytes =>
        next_state <= wait_for_uart_cmd;
         if(unsigned(current_data(0)) > 1) then
               next_num_bytes <= unsigned(current_data(0));
          end if;
     
     when set_address =>
        next_state <= wait_for_uart_cmd;
        for i in 0 to Number_of_Address_Bytes loop
            next_address(i) <=  unsigned(current_data(i));
        end loop;
    
    when get_status =>
        if(uart_tx_busy = '0') then
           if(current_index = Number_of_Address_Bytes + 1) then
              next_index <= (others => '0');
              next_state <= wait_for_uart_cmd;
           else
              next_state <= wait_for_clock;
              next_saved_state <= get_status;
              next_index <= current_index + 1;
           end if;
        else            
            next_state <= get_status;
        end if;
     
     when set_dual_mode =>
        if(SPI_busy = '0') then
            next_spi_mode <= "01";
            next_state <= wait_for_uart_cmd;
        else
            next_state <= set_dual_mode;
        end if;
     
      when set_quad_mode =>
       next_dummy_bytes <= 2;
       if(SPI_busy = '0') then
           next_spi_mode <= "10";
           next_state <= wait_for_uart_cmd;
       else
           next_state <= set_dual_mode;
       end if;
      
      when set_write_enable =>
        if(SPI_busy = '0') then
             next_state <= wait_for_uart_cmd;
         else
             next_state <= set_write_enable;
         end if;
        
     
      
     when misc_single =>
        if(SPI_busy = '0') then
              next_state <= wait_for_uart_cmd;
          else
              next_state <= misc_single;
          end if;
        
     when misc_read =>
     if(SPI_busy = '0') then
        if(current_index > current_dummy_bytes - 1) then
         next_data(to_integer(current_index)-current_dummy_bytes) <= SPI_data_in;
        end if;
        if(current_index = current_num_bytes + current_dummy_bytes - 1 ) then
           next_index <= (others => '0');
           next_state <= send_uart_data; -- this is for debug purposes 
        else
           next_state <= wait_for_clock;
           next_saved_state <= misc_read;
           next_index <= current_index + 1;
        end if;
     else
         next_state <= misc_read;
     end if;
    
    when  misc_write =>
     if(SPI_busy = '0') then
       if(current_index = current_num_bytes - 1) then
          next_index <= (others => '0');
          next_state <= wait_for_uart_cmd;
       else
          next_state <= wait_for_clock;
          next_saved_state <= misc_write;
          next_index <= current_index + 1;
       end if;
    else
        next_state <= misc_write;
    end if;
        
      
      when others =>  
        next_state <= uart_welecome;
    end case;
  end process;


end Behavioral;