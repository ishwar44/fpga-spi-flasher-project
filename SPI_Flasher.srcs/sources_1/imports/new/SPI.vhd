LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY spi_quad_master IS
  GENERIC(
	cpol 	  : STD_LOGIC := '0'; 
	cpha 	  : STD_LOGIC := '0'; 
    slaves    : positive := 1;  
    cmd_width : positive := 8; 
    d_width   : positive := 8);
  PORT(
    clk   : IN     STD_LOGIC;                          
    rst : IN     STD_LOGIC;                         
    enable  : IN     STD_LOGIC;       
    clk_div : IN     positive;
    addr    : IN     INTEGER;              
	cont	: IN		STD_LOGIC;
	cmd_only : IN		STD_LOGIC;
    rw      : IN     STD_LOGIC;   
    tx_cmd  : IN     STD_LOGIC_VECTOR(cmd_width-1 DOWNTO 0);
    tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  
    sclk    : BUFFER STD_LOGIC;       
    ss_n    : BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);
	mode_sel : IN STD_LOGIC_VECTOR(1 downto 0);	
    sdio    : INOUT  STD_LOGIC;   
	sdio_1  : INOUT  STD_LOGIC;                          
	sdio_2  : INOUT  STD_LOGIC;   
	sdio_3  : INOUT  STD_LOGIC; 
    busy    : OUT    STD_LOGIC;   
    rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)
    );  
END spi_quad_master;

ARCHITECTURE logic OF spi_quad_master IS
  TYPE   machine IS(ready, execute,execute_dual,execute_quad);     
  SIGNAL state       : machine;                                      
  SIGNAL slave       : INTEGER;                                     
  SIGNAL clk_ratio   : positive;                                      
  SIGNAL count       : INTEGER;                                     
  SIGNAL clk_toggles : INTEGER RANGE 0 TO (cmd_width+d_width)*2 + 2;
  SIGNAL assert_data : STD_LOGIC;                                  
  SIGNAL rw_buffer   : STD_LOGIC;                                  
  SIGNAL cmd_buffer  : STD_LOGIC_VECTOR(cmd_width-1 DOWNTO 0);      
  SIGNAL d_buffer    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);        
  SIGNAL last_bit_rx : INTEGER RANGE 0 TO (cmd_width+d_width)*2;     
  SIGNAL continue    : STD_LOGIC;                          
  constant debug_delay : positive := 10;
  signal debug_counter : unsigned(3 downto 0) := (others => '0');
  signal cmd_only_buffer :STD_LOGIC;
BEGIN
  PROCESS(clk)
  BEGIN

    IF(rst = '0') THEN        
      busy <= '1';                
      ss_n <= (OTHERS => '1');  
      sdio <= 'Z';               
	  sdio_1 <= 'Z';                
	  sdio_2 <= 'Z';               
	  sdio_3 <= 'Z';               
      rx_data <= (OTHERS => '0'); 
      state <= ready;        

    ELSIF(clk'EVENT AND clk = '1') THEN
      CASE state IS                

        WHEN ready =>
		  continue <= '0';         
          busy <= '0';              
          ss_n <= (OTHERS => '1');  
          sdio <= 'Z';          
		  sdio_1 <= 'Z';
		  sdio_2 <= 'Z';
		  sdio_3 <= 'Z';
		  d_buffer <= (others => '0');
          IF(enable = '1') THEN       
            busy <= '1';            
            cmd_only_buffer <= cmd_only;
            IF(addr < slaves) THEN   
              slave <= addr;         
            ELSE
              slave <= 0;            
            END IF;
            IF(clk_div = 0) THEN    
              clk_ratio <= 1;       
              count <= 1;            
            ELSE
              clk_ratio <= clk_div;  
              count <= clk_div;      
            END IF;
            sclk <= cpol;            
            assert_data <= NOT cpha; 
            rw_buffer <= rw;         
            cmd_buffer <= tx_cmd;   
            d_buffer <= tx_data;     
            clk_toggles <= 0;        
            last_bit_rx <= (cmd_width+d_width)*2 + conv_integer(cpha) - 1;
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
            state <= ready;
          END IF;
        

        WHEN execute =>
          busy <= '1';       
          ss_n(slave) <= '0'; 
          
          IF(count = clk_ratio) THEN        
            count <= 1;                     
            assert_data <= NOT assert_data; 
            clk_toggles <= clk_toggles + 1; 
            
   
            IF(clk_toggles < (cmd_width+d_width)*2 + 1 AND ss_n(slave) = '0') THEN 
              sclk <= NOT sclk;
            END IF;
            
            IF(assert_data = '1' AND clk_toggles < last_bit_rx - d_width*2) THEN 
              sdio <= cmd_buffer(cmd_width-1); 
              cmd_buffer <= cmd_buffer(cmd_width-2 DOWNTO 0) & '0'; 
            END IF;
            IF(assert_data = '1' AND rw_buffer = '1' AND clk_toggles > last_bit_rx - d_width*2) THEN  
              sdio <= d_buffer(d_width-1);                                                           
              d_buffer <= d_buffer(d_width-2 DOWNTO 0) & '0';                               
            END IF;
           IF(assert_data = '1' AND rw_buffer = '0' AND clk_toggles > last_bit_rx - d_width*2) THEN 
              sdio <= '0';                                                                        
            END IF;
        
            IF(assert_data = '0' AND clk_toggles < last_bit_rx + 1) THEN 
              IF(rw_buffer = '0' AND clk_toggles > last_bit_rx - d_width*2) THEN 
                d_buffer <= d_buffer(d_width-2 DOWNTO 0) & sdio_1; 
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
				continue <= '0';      
				busy <= '0';          
				rw_buffer <= rw;
				if(rw_buffer = '0') then
					rx_data <= d_buffer; 
				end if;
         END IF;
         
            
            IF((clk_toggles = (cmd_width+d_width)*2 + 1) AND cont = '0') THEN  
              busy <= '0';              
              ss_n <= (OTHERS => '1');  
              sdio <= 'Z';              
              IF(rw_buffer = '0') THEN  
                rx_data <= d_buffer;    
              END IF;
                state <= ready;       
              ELSE                    
                state <= execute;      
            END IF;
          
          ELSE                  
            count <= count + 1; 
            state <= execute;    
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
