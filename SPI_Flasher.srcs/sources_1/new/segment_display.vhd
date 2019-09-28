library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity segment_display is
    Port ( clk             : in  STD_LOGIC;
           rst             : in STD_LOGIC;
           number          : in  STD_LOGIC_VECTOR (31 downto 0);
           anode           : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1'); --anode and cathode are active low
           cathode         : out  STD_LOGIC_VECTOR (7 downto 0):= (others => '1')
           );
end segment_display;

architecture Behavioral of segment_display is
type nibble_arr is array (0 to 7) of std_logic_vector(3 downto 0);
type byte_arr is array (0 to 15) of std_logic_vector(7 downto 0);
type state is (get_number, output_digits);
signal current_state : state := get_number;
signal digits : nibble_arr := (others => (others => '0'));
signal current_digit : unsigned(2 downto 0) := (others => '0');
signal current_anode : STD_LOGIC_VECTOR (7 downto 0):= (others => '1');

signal timer : unsigned(17 downto 0) := (others => '0');


constant zero :std_logic_vector(7 downto 0) := "00000011";
constant one  :std_logic_vector(7 downto 0) := "10011111";
constant two  :std_logic_vector(7 downto 0) := "00100101";
constant three:std_logic_vector(7 downto 0) := "00001101";
constant four :std_logic_vector(7 downto 0) := "10011001";
constant five :std_logic_vector(7 downto 0) := "01001001";
constant six  :std_logic_vector(7 downto 0) := "01000001";
constant seven:std_logic_vector(7 downto 0) := "00011111";
constant eight:std_logic_vector(7 downto 0) := "00000001";
constant nine :std_logic_vector(7 downto 0) := "00001001";
constant hex_a:std_logic_vector(7 downto 0) := "00010001";
constant hex_b:std_logic_vector(7 downto 0) := "11000001";
constant hex_c:std_logic_vector(7 downto 0) := "01100011";
constant hex_d:std_logic_vector(7 downto 0) := "10000101";
constant hex_e:std_logic_vector(7 downto 0) := "01100001";
constant hex_f:std_logic_vector(7 downto 0) := "01110001";
constant digit_arr : byte_arr := 
(
    zero,
    one,
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    hex_a,
    hex_b,
    hex_c,
    hex_d,
    hex_e,
    hex_f
);
begin
process(clk)
begin
    if(rst = '0') then

    elsif(clk'event and clk = '1') then
        case(current_state) is
        
            when get_number =>
                current_state <= output_digits;
                for i in 0 to 7 loop
                    digits(i) <= number((4*i) + 3 downto (4*i));
                end loop;
                cathode <= (others => '1');
                anode <= current_anode(6 downto 0) & '0';
                current_anode <= current_anode(6 downto 0) & '0';
                
            when output_digits =>
                
                cathode <= digit_arr(to_integer(unsigned(digits(to_integer(current_digit)))));
                
                if(current_digit = 7) then	
                    if(timer = 100000) then 
                        current_state <= get_number;
                        current_digit <= (others => '0');
                        anode <= current_anode(6 downto 0) & '1';
                        current_anode <= current_anode(6 downto 0) & '1';
                        timer <= (others => '0');
                    else
                        current_state <= output_digits;
                        timer <= timer + 1;
                    end if;
            
                else
                    if(timer = 100000) then
                        timer <= (others => '0');
                        current_digit <= current_digit + 1;
                        anode <= current_anode(6 downto 0) & '1';
                        current_anode <= current_anode(6 downto 0) & '1';
                    else
                        timer <= timer + 1;
                    end if;
                    current_state <= output_digits;
                end if;
                 
        end case;
    end if;

end process;
end Behavioral;