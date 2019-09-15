LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY spi_quad_master IS
  GENERIC(
	cpol 	  : STD_LOGIC := '0'; --spi clock polarity
	cpha 	  : STD_LOGIC := '0'; --spi clock phase
    slaves    : INTEGER := 1;  --number of spi slaves
    cmd_width : INTEGER := 8;  --command bus width
    d_width   : INTEGER := 8); --data bus width
  PORT(
    clock   : IN     STD_LOGIC;                              --system clock
    reset_n : IN     STD_LOGIC;                              --asynchronous reset
    enable  : IN     STD_LOGIC;                              --initiate transaction
    clk_div : IN     INTEGER;                                --system clock cycles per 1/2 period of sclk
    addr    : IN     INTEGER;                                --address of slave
	cont	: IN		STD_LOGIC;
	cmd_only : IN		STD_LOGIC;
    rw      : IN     STD_LOGIC;                              --'0' for read, '1' for write
    tx_cmd  : IN     STD_LOGIC_VECTOR(cmd_width-1 DOWNTO 0); --command to transmit
    tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --data to transmit
    sclk    : BUFFER STD_LOGIC;                              --spi clock
    ss_n    : BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);    --slave select
	mode_sel : IN STD_LOGIC_VECTOR(1 downto 0);				 --"00" extended, "01" dual, "10" quad
    sdio    : INOUT  STD_LOGIC;                              --serial data input output
	sdio_1  : INOUT  STD_LOGIC;                              --serial data input output
	sdio_2  : INOUT  STD_LOGIC;                              --serial data input output
	sdio_3  : INOUT  STD_LOGIC;                              --serial data input output
    busy    : OUT    STD_LOGIC;                              --busy / data ready signal
    rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)
    --Debug     : IN STD_LOGIC;
    --Debug_data    :    IN        STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)
    );  --data received
END spi_quad_master;

ARCHITECTURE logic OF spi_quad_master IS
  TYPE   machine IS(ready, execute,execute_dual,execute_quad);                                 --state machine data type  debug_state
  SIGNAL state       : machine;                                      --current state
  SIGNAL slave       : INTEGER;                                      --slave selected for current transaction
  SIGNAL clk_ratio   : INTEGER;                                      --current clk_div
  SIGNAL count       : INTEGER;                                      --counter to trigger sclk from system clock
  SIGNAL clk_toggles : INTEGER RANGE 0 TO (cmd_width+d_width)*2 + 2; --count spi clock toggles
  SIGNAL assert_data : STD_LOGIC;                                    --'1' is tx sclk toggle, '0' is rx sclk toggle
  SIGNAL rw_buffer   : STD_LOGIC;                                    --read/write buffer
  SIGNAL cmd_buffer  : STD_LOGIC_VECTOR(cmd_width-1 DOWNTO 0);       --command buffer
  SIGNAL d_buffer    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);         --data buffer
  SIGNAL last_bit_rx : INTEGER RANGE 0 TO (cmd_width+d_width)*2;     --last rx data bit location
  SIGNAL continue    : STD_LOGIC;                            --flag to continue transaction
  constant debug_delay : positive := 10;
  signal debug_counter : unsigned(3 downto 0) := (others => '0');
  signal cmd_only_buffer :STD_LOGIC;
BEGIN
  PROCESS(clock, reset_n)
  BEGIN

    IF(reset_n = '0') THEN        --reset system
      busy <= '1';                --set busy signal
      ss_n <= (OTHERS => '1');    --deassert all slave select lines
      sdio <= 'Z';                --set master data io to high impedance
	  sdio_1 <= 'Z';                --set master data io to high impedance
	  sdio_2 <= 'Z';                --set master data io to high impedance
	  sdio_3 <= 'Z';                --set master data io to high impedance
      rx_data <= (OTHERS => '0'); --clear receive data port
      state <= ready;             --go to ready state when reset is exited

    ELSIF(clock'EVENT AND clock = '1') THEN
      CASE state IS                 --state machine

        WHEN ready =>
		  continue <= '0';         --clear continue flag
          busy <= '0';              --clock out not busy signal
          ss_n <= (OTHERS => '1');  --set all slave select outputs high
          sdio <= 'Z';            	--set master data io to high impedance   
		  sdio_1 <= 'Z';
		  sdio_2 <= 'Z';
		  sdio_3 <= 'Z';
		  d_buffer <= (others => '0');
          --user input to initiate transaction
          IF(enable = '1') THEN       
            busy <= '1';             --set busy signal
            cmd_only_buffer <= cmd_only;
            IF(addr < slaves) THEN   --check for valid slave address
              slave <= addr;         --clock in current slave selection if valid
            ELSE
              slave <= 0;            --set to first slave if not valid
            END IF;
            IF(clk_div = 0) THEN     --check for valid spi speed
              clk_ratio <= 1;        --set to maximum speed if zero
              count <= 1;            --initiate system-to-spi clock counter
            ELSE
              clk_ratio <= clk_div;  --set to input selection if valid
              count <= clk_div;      --initiate system-to-spi clock counter
            END IF;
            sclk <= cpol;            --set spi clock polarity
            assert_data <= NOT cpha; --set spi clock phase
            rw_buffer <= rw;         --clock in read/write instruction
            cmd_buffer <= tx_cmd;    --clock in command for transmit into buffer
            d_buffer <= tx_data;     --clock in data for transmit into buffer
            clk_toggles <= 0;        --initiate clock toggle counter
            last_bit_rx <= (cmd_width+d_width)*2 + conv_integer(cpha) - 1; --set last rx data bit
            if(mode_sel = "00") then
                state <= execute;
            elsif(mode_sel = "01") then
                state <= execute_dual;
            elsif(mode_sel = "10") then
                state <= execute_quad;
            else
                state <= execute;
            end if;
          ELSE
            state <= ready;          --remain in ready state
          END IF;
        

        WHEN execute =>
          busy <= '1';        --set busy signal
          ss_n(slave) <= '0'; --set proper slave select output
          
          --system clock to sclk ratio is met
          IF(count = clk_ratio) THEN        
            count <= 1;                      --reset system-to-spi clock counter
            assert_data <= NOT assert_data;  --switch transmit/receive indicator
            clk_toggles <= clk_toggles + 1;  --increment spi clock toggles counter
            
            --spi clock toggle needed
            IF(clk_toggles < (cmd_width+d_width)*2 + 1 AND ss_n(slave) = '0') THEN 
              sclk <= NOT sclk;  --toggle spi clock
            END IF;
            
            --transmit spi clock toggle
            IF(assert_data = '1' AND clk_toggles < last_bit_rx - d_width*2) THEN  --command part of transaction
              sdio <= cmd_buffer(cmd_width-1);                                    --clock out command bit
              cmd_buffer <= cmd_buffer(cmd_width-2 DOWNTO 0) & '0';               --shift command transmit buffer
            END IF;
            IF(assert_data = '1' AND rw_buffer = '1' AND clk_toggles > last_bit_rx - d_width*2) THEN  --write command and data part of transaction
              sdio <= d_buffer(d_width-1);                                                            --clock out data bit
              d_buffer <= d_buffer(d_width-2 DOWNTO 0) & '0';                                         --shift data transmit buffer
            END IF;
           IF(assert_data = '1' AND rw_buffer = '0' AND clk_toggles > last_bit_rx - d_width*2) THEN  --read command and data part of transaction
              --sdio_1 <= 'Z';
              sdio <= '0';                                                                         --set serial data line to high impedance
            END IF;
        
            --receive spi clock toggle
            IF(assert_data = '0' AND clk_toggles < last_bit_rx + 1) THEN 
              IF(rw_buffer = '0' AND clk_toggles > last_bit_rx - d_width*2) THEN --read transaction and data part of transaction
                d_buffer <= d_buffer(d_width-2 DOWNTO 0) & sdio_1;                 --shift in received bit
              END IF;
            END IF;
				
			IF(cont = '1' AND clk_toggles = last_bit_rx) THEN
				if(rw_buffer = '1') then
					d_buffer <= tx_data;
				end if;
				clk_toggles <= last_bit_rx - d_width*2 + 1;
				continue <= '1';
			END IF;
			

			IF(continue = '1') THEN  
				continue <= '0';      --clear continue flag
				busy <= '0';          --clock out signal that first receive data is ready
				rw_buffer <= rw;
				if(rw_buffer = '0') then
					rx_data <= d_buffer; --clock out received data to output port
				end if;
         END IF;
         
            
            --end of transaction
            IF((clk_toggles = (cmd_width+d_width)*2 + 1) AND cont = '0') THEN  
              busy <= '0';              --clock out not busy signal
              ss_n <= (OTHERS => '1');  --set all slave selects high
              sdio <= 'Z';              --set master data io to high impedance
              IF(rw_buffer = '0') THEN  --if transaction was a read
                rx_data <= d_buffer;    --clock out received data to output port
              END IF;
                state <= ready;         --return to ready state
              ELSE                      --not end of transaction
                state <= execute;       --remain in execute state
            END IF;
          
          ELSE                   --system clock to sclk ratio not met
            count <= count + 1;  --increment counter
            state <= execute;    --remain in execute state
          END IF;
          
          
          if(cmd_only_buffer = '1' and clk_toggles = (cmd_width + 1)*2 - 1) then
                state <= ready;
                busy <= '0';
                  ss_n <= (OTHERS => '1');
                  sdio <= 'Z';
           end if;
		
		when execute_dual =>
			busy <= '1';       
			ss_n(slave) <= '0';
			IF(count = clk_ratio) THEN
				count <= 1;
				assert_data <= NOT assert_data;
				clk_toggles <= clk_toggles + 1;
				IF(clk_toggles < (cmd_width+d_width) + 1 AND ss_n(slave) = '0') THEN 
					sclk <= NOT sclk;  --toggle spi clock
				END IF;
				IF(assert_data = '1' AND clk_toggles < (last_bit_rx - d_width*2)/2) THEN
					sdio_1 <= cmd_buffer(cmd_width-1);
					sdio <= cmd_buffer(cmd_width-2); 				  
					cmd_buffer <= cmd_buffer(cmd_width-3 DOWNTO 0) & "00";          
				END IF;
				IF(assert_data = '1' AND rw_buffer = '1' AND clk_toggles > (last_bit_rx - d_width*2)/2) THEN
					sdio_1 <= d_buffer(d_width-1);
					sdio <= d_buffer(d_width-2); 
					d_buffer <= d_buffer(d_width-3 DOWNTO 0) & "00"; 
				END IF;
				IF(assert_data = '1' AND rw_buffer = '0' AND clk_toggles > (last_bit_rx - d_width*2)/2) THEN  
					sdio_1 <= 'Z';
					sdio <= 'Z';				  
				END IF;

				IF(assert_data = '0' AND clk_toggles < (last_bit_rx + 1)/2) THEN 
				  IF(rw_buffer = '0' AND clk_toggles > last_bit_rx - d_width*2) THEN 
					d_buffer <= d_buffer(d_width-3 DOWNTO 0) & sdio_1 & sdio;
				  END IF;
				END IF;
				
				IF(cont = '1' AND clk_toggles = last_bit_rx/2) THEN
					if(rw_buffer = '1') then
						d_buffer <= tx_data;
					end if;
					clk_toggles <= (last_bit_rx - d_width*2 + 1)/2;
					continue <= '1';
				END IF;
				
				IF(continue = '1') THEN  
					continue <= '0'; 
					busy <= '0';   
					if(rw_buffer = '0') then
						rx_data <= d_buffer;
					end if;
				END IF;
				
				IF(clk_toggles = (cmd_width+d_width) + 1) THEN  
					busy <= '0';  
					ss_n <= (OTHERS => '1');
					sdio_1 <= 'Z';
					sdio <= 'Z';              
				  IF(rw_buffer = '0') THEN 
					rx_data <= d_buffer;    
				  END IF;
					state <= ready;  
				  ELSE                      
					state <= execute_dual;      
				END IF;
				
			ELSE              
				count <= count + 1;  
				state <= execute_dual;    
			END IF;
		when execute_quad =>
			busy <= '1';       
			ss_n(slave) <= '0';
			IF(count = clk_ratio) THEN
				count <= 1;
				assert_data <= NOT assert_data;
				clk_toggles <= clk_toggles + 1;
				IF(clk_toggles < (cmd_width+d_width)/2 + 1 AND ss_n(slave) = '0') THEN 
					sclk <= NOT sclk;  --toggle spi clock
				END IF;
				IF(assert_data = '1' AND clk_toggles < (last_bit_rx - d_width*2)/4) THEN
					sdio_3 <= cmd_buffer(cmd_width-1);
					sdio_2 <= cmd_buffer(cmd_width-2);
					sdio_1 <= cmd_buffer(cmd_width-3);
					sdio <= cmd_buffer(cmd_width-4); 
					cmd_buffer <= cmd_buffer(cmd_width-5 DOWNTO 0) & "0000";          
				END IF;
				IF(assert_data = '1' AND rw_buffer = '1' AND clk_toggles > (last_bit_rx - d_width*2)/4) THEN
					sdio_3 <= d_buffer(d_width-1);
					sdio_2 <= d_buffer(d_width-2);
					sdio_1 <= d_buffer(d_width-3);
					sdio <= d_buffer(d_width-4);
					d_buffer <= d_buffer(d_width-5 DOWNTO 0) & "0000"; 
				END IF;
				IF(assert_data = '1' AND rw_buffer = '0' AND clk_toggles > (last_bit_rx - d_width*2)/4) THEN  
					sdio <= 'Z';
					sdio_1 <= 'Z';
					sdio_2 <= 'Z';
					sdio_3 <= 'Z';							
				END IF;

                IF(assert_data = '0' AND clk_toggles <= ((last_bit_rx + 1)/4)+1) THEN 
				  IF(rw_buffer = '0' AND clk_toggles > (last_bit_rx+1 - d_width*2)/4) THEN 
					d_buffer <= d_buffer(d_width-5 DOWNTO 0) & sdio_3 & sdio_2 & sdio_1 & sdio;
				  END IF;
				END IF;
				
				
				IF(cont = '1' AND clk_toggles = last_bit_rx/4) THEN
					if(rw_buffer = '1') then
						d_buffer <= tx_data;
					end if;
					clk_toggles <= (last_bit_rx - d_width*2 + 1)/4;
					continue <= '1';
				END IF;
				
				IF(continue = '1') THEN  
					continue <= '0';
					rw_buffer <= rw;
					busy <= '0';   
					if(rw_buffer = '0') then
						rx_data <= d_buffer;
					end if;
				END IF;
				
				
				IF(clk_toggles = (cmd_width+d_width)/2 + 1) THEN  
					busy <= '0';  
					ss_n <= (OTHERS => '1');
					sdio <= 'Z';
					sdio_1 <= 'Z';
					sdio_2 <= 'Z';
					sdio_3 <= 'Z';
				  IF(rw_buffer = '0') THEN 
					rx_data <= d_buffer;    
				  END IF;
					state <= ready;  
				ELSE                      
					state <= execute_quad;      
				END IF;
				
			ELSE              
				count <= count + 1;  
				state <= execute_quad;    
			END IF;   
      END CASE;
    END IF;
  END PROCESS; 
END logic;
