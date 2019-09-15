----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.09.2019 12:28:03
-- Design Name: 
-- Module Name: top_level - Behavioral
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

entity top_level is
    GENERIC(
		clk_freq	:	INTEGER		:= 100000000;
		uart_data_width		:	INTEGER		:= 8;
		spi_data_width    : positive := 8;
		spi_cmd_width  : positive := 8;
		slaves : positive := 1
		);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           tx : out STD_LOGIC;
           rx : in STD_LOGIC;
           LED : out STD_LOGIC_VECTOR(15 downto 0);
           sclk : buffer std_logic;
           ss: buffer std_logic_vector(slaves - 1 downto 0);
           sdio : inout std_logic;
           sdio1 : inout std_logic;
           sdio2: inout std_logic;
           sdio3 : inout std_logic
           );
end top_level;

architecture Behavioral of top_level is
signal uart_tx_data_sig : std_logic_vector(uart_data_width - 1 downto 0);
signal uart_tx_ena_sig : std_logic;
signal uart_rx_busy_sig : std_logic;
signal uart_rx_error_sig : std_logic;
signal uart_rx_data_sig : std_logic_vector(uart_data_width - 1 downto 0);
signal uart_tx_busy_sig : std_logic;
signal spi_ena_sig : std_logic;
signal rw_sig : std_logic;
signal cont_spi_sig : std_logic;
signal SPI_CMD_out_sig : std_logic_vector(spi_cmd_width - 1 downto 0);
signal spi_tx_data_sig : std_logic_vector(spi_data_width - 1 downto 0);
signal spi_rx_data_sig : std_logic_vector(spi_data_width - 1 downto 0);
signal cmd_only_sig : std_logic;
signal mode_sel_sig : std_logic_vector(1 downto 0);
signal spi_busy_sig : std_logic;

begin

uart : entity work.uart
generic map
(
    clk_freq =>  clk_freq,
    baud_rate =>  1000000,
    os_rate	 => 8,		
    d_width	 => uart_data_width,
    parity	=> 0,	
    parity_eo => '0'
)
port map
(
    clk => clk,
    reset_n	=> rst,
    tx_ena	=> uart_tx_ena_sig,
    tx_data	=>	uart_tx_data_sig,
    rx	=> rx,
    rx_busy	 => uart_rx_busy_sig,	
    rx_error => uart_rx_error_sig,	
    rx_data	=> uart_rx_data_sig,
    tx_busy	=> uart_tx_busy_sig,
    tx => tx
);	


flasher : entity work.flash_logic
generic map
(
    clk_freq =>  clk_freq,
    uart_data_width	 => uart_data_width
)
port map
(
    clk => clk,
    rst => rst,
    uart_tx_en => uart_tx_ena_sig,
    uart_tx_data => uart_tx_data_sig,
    uart_tx_busy => uart_tx_busy_sig, 
    uart_rx_data => uart_rx_data_sig,
    uart_rx_busy => uart_rx_busy_sig,
    rw => rw_sig,
    SPI_CMD_out => SPI_CMD_out_sig,
    SPI_data_out => spi_tx_data_sig,
    SPI_data_in => spi_rx_data_sig,
    mode_sel => mode_sel_sig,
    cmd_only => cmd_only_sig,
    led => LED,
    SPI_busy =>spi_busy_sig,
    SPI_ena =>spi_ena_sig,
    command_debug => '0',
    cont_spi => cont_spi_sig
);

spi : entity work.spi_quad_master
  generic map(
  cpol  => '0',
  cpha => '0',
  slaves => 1,  
  cmd_width => spi_cmd_width, 
  d_width => spi_data_width
  )
  
  port map
  (
    clock => clk,
    reset_n => rst,
    enable => spi_ena_sig,
    clk_div => 200,
    addr =>  0,   
    rw  => rw_sig,
    cont => cont_spi_sig,    
    tx_cmd =>  SPI_CMD_out_sig,
    tx_data => spi_tx_data_sig,
    sclk => sclk,
    cmd_only => cmd_only_sig,
    ss_n  => ss, 
    mode_sel => mode_sel_sig,
    sdio => sdio, 
    sdio_1 => sdio1, 
    sdio_2  => sdio2, 
    sdio_3 => sdio3, 
    busy  => spi_busy_sig, 
    rx_data => spi_rx_data_sig
  );

end Behavioral;
