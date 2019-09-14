library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;

package util is

    type frequency is range -2147483647 to 2147483647 -- (2^31)-1
    units
        Hz;
        kHz = 1000 Hz;
        MHz = 1000 kHz;
        GHz = 1000 MHz;
        THz = 1000 GHz;
    end units;

    subtype  byte             is                             std_logic_vector(7 downto 0);
    type     byte_vector      is array (natural range <>) of byte;

    subtype  rgbLED             is                             std_logic_vector(23 downto 0);
    type     rgbLED_vector      is array (natural range <>) of rgbLED;
     
    constant white : rgbLED := "111111111111111111111111";

    constant byte_unknown: byte      := "XXXXXXXX";
    constant byte_null:    byte      := "00000000";
    constant byte_255:     byte      := "11111111";
    constant byte_CR:      byte      := std_logic_vector(to_unsigned(13, 8));
    constant byte_LF:      byte      := std_logic_vector(to_unsigned(10, 8));
    constant byte_space:   byte      := std_logic_vector(to_unsigned(character'pos(' '), 8));
    constant byte_zero:    byte      := std_logic_vector(to_unsigned(character'pos('0'), 8));
    constant byte_one:     byte      := std_logic_vector(to_unsigned(character'pos('1'), 8));

    type    positive_vector is array (natural range <>) of positive;

    subtype  bcd_digit        is                             unsigned(3 downto 0);
    type     bcd_digit_vector is array (natural range <>) of bcd_digit;
    
    constant bcd_unknown:  bcd_digit := "XXXX";
    constant bcd_zero:     bcd_digit := X"0";
    constant bcd_one:      bcd_digit := X"1";
    constant bcd_two:      bcd_digit := X"2";
    constant bcd_three:    bcd_digit := X"3";
    constant bcd_four:     bcd_digit := X"4";
    constant bcd_five:     bcd_digit := X"5";
    constant bcd_six:      bcd_digit := X"6";
    constant bcd_seven:    bcd_digit := X"7";
    constant bcd_eight:    bcd_digit := X"8";
    constant bcd_nine:     bcd_digit := X"9";
    constant bcd_plus:     bcd_digit := X"A";
    constant bcd_minus:    bcd_digit := X"B";
    constant bcd_dot:      bcd_digit := X"C";
    constant bcd_colon:    bcd_digit := X"D";
    constant bcd_error:    bcd_digit := X"E";
    constant bcd_space:    bcd_digit := X"F";
    
    constant byte_bcd: byte_vector(0 to 15) :=
    (
        std_logic_vector(to_unsigned(character'pos('0'), 8)),
        std_logic_vector(to_unsigned(character'pos('1'), 8)),
        std_logic_vector(to_unsigned(character'pos('2'), 8)),
        std_logic_vector(to_unsigned(character'pos('3'), 8)),
        std_logic_vector(to_unsigned(character'pos('4'), 8)),
        std_logic_vector(to_unsigned(character'pos('5'), 8)),
        std_logic_vector(to_unsigned(character'pos('6'), 8)),
        std_logic_vector(to_unsigned(character'pos('7'), 8)),
        std_logic_vector(to_unsigned(character'pos('8'), 8)),
        std_logic_vector(to_unsigned(character'pos('9'), 8)),
        std_logic_vector(to_unsigned(character'pos('+'), 8)),
        std_logic_vector(to_unsigned(character'pos('-'), 8)),
        std_logic_vector(to_unsigned(character'pos('.'), 8)),
        std_logic_vector(to_unsigned(character'pos(':'), 8)),
        std_logic_vector(to_unsigned(character'pos('E'), 8)),
        std_logic_vector(to_unsigned(character'pos(' '), 8))
    );

    constant byte_hex: byte_vector(0 to 15) :=
    (
        std_logic_vector(to_unsigned(character'pos('0'), 8)),
        std_logic_vector(to_unsigned(character'pos('1'), 8)),
        std_logic_vector(to_unsigned(character'pos('2'), 8)),
        std_logic_vector(to_unsigned(character'pos('3'), 8)),
        std_logic_vector(to_unsigned(character'pos('4'), 8)),
        std_logic_vector(to_unsigned(character'pos('5'), 8)),
        std_logic_vector(to_unsigned(character'pos('6'), 8)),
        std_logic_vector(to_unsigned(character'pos('7'), 8)),
        std_logic_vector(to_unsigned(character'pos('8'), 8)),
        std_logic_vector(to_unsigned(character'pos('9'), 8)),
        std_logic_vector(to_unsigned(character'pos('A'), 8)),
        std_logic_vector(to_unsigned(character'pos('B'), 8)),
        std_logic_vector(to_unsigned(character'pos('C'), 8)),
        std_logic_vector(to_unsigned(character'pos('D'), 8)),
        std_logic_vector(to_unsigned(character'pos('E'), 8)),
        std_logic_vector(to_unsigned(character'pos('F'), 8))
    );

    constant ssg_hex: byte_vector(0 to 15) :=
    (
        "11000000", 
        "11111001", 
        "10100100", 
        "10110000",
        "10011001", 
        "10010010", 
        "10000010", 
        "11111000",
        "10000000", 
        "10010000", 
        "10001000", 
        "10000011",
        "11000110", 
        "10100001", 
        "10000110", 
        "10001110");

    type chr_file is file of character;

    function n_bits(x: natural) return natural;
    function slv_and(slv: std_logic_vector) return std_logic;
    function slv_or(slv: std_logic_vector) return std_logic;
    function slv_xor(slv: std_logic_vector) return std_logic;
    function slv_rev(slv: std_logic_vector) return std_logic_vector;
    
    function max(a: natural; b: natural) return natural;
    function min(a: natural; b: natural) return natural;

    function str_len(s: string) return natural;

    function gen_byte_vector(l: natural; c: character) return byte_vector;
    function to_byte_vector(s: string) return byte_vector;

    function space_to_zero(bvi: bcd_digit_vector) return bcd_digit_vector;

    function chr_to_byte(c: character) return byte;
    function byte_to_chr(b: byte) return character;

--synopsys synthesis_off

    function to_string(slv: std_logic_vector) return string;
    function to_hstring(slv: std_logic_vector) return string;
    function str_to_int(s: string) return integer;
    function int_to_str(i: integer) return string;
    function str_to_real(s: string) return real;
    function hex_to_chr(s: string) return character;
    procedure copy_str(a: inout line; b: inout  line);
    function cmp(c: character; e: string) return boolean;
    function find(s: string; e: string; i_start: integer; i_end: integer) return integer;
    function skip_whitespace(s: string; idx: integer; ws: string; fwd: boolean) return integer;

    procedure write(f: inout chr_file; s: string);
    procedure writeln(f: inout chr_file; s: string);

    procedure print(c: character);
    procedure print(s: string);
    procedure println(s: string);
    procedure println(l: inout line);

--synopsys synthesis_on

end util;

package body util is

    function n_bits(x: natural) return natural is
        variable temp: natural := max(x, 1);
        variable n:    natural := 1;
    begin
    
        while temp > 1 loop
            temp := temp / 2;
            n    := n + 1;
        end loop;
        
        return n;
    end function;

    function slv_and(slv: std_logic_vector) return std_logic is
        variable r: std_logic := '0';
    begin
    
        for i in slv'range loop
            r := r and slv(i);
        end loop;
        
        return r;   
    end function;

    function slv_or(slv: std_logic_vector) return std_logic is
        variable r: std_logic := '0';
    begin
    
        for i in slv'range loop
            r := r or slv(i);
        end loop;
        
        return r;
    end function;

    function slv_xor(slv: std_logic_vector) return std_logic is
        variable r: std_logic := '0';
    begin
    
        for i in slv'range loop
            r := r xor slv(i);
        end loop;
        
        return r;   
    end function;

    function slv_rev(slv: std_logic_vector) return std_logic_vector is
        variable r: std_logic_vector(slv'range) := (others => '0');
    begin
    
        for i in slv'range loop
            r(i) := slv(slv'left + slv'right - i);
        end loop;
        
        return r;
    end;

    function max(a: natural; b: natural) return natural is
    begin
    
        if (a > b) then
            return a;
        else
            return b;
        end if;

    end function;

    function min(a: natural; b: natural) return natural is
    begin
    
        if (a < b) then
            return a;
        else
            return b;
        end if;

    end function;

    function str_len(s: string) return natural is
    begin
        return s'high - s'low + 1;
    end function str_len;

    function gen_byte_vector(l: natural; c: character) return byte_vector is
        variable b: byte_vector(0 to max(l, 1) - 1);
    begin
    
        for i in b'range loop
            b(i) := std_logic_vector(to_unsigned(character'pos(c), 8));
        end loop;

        return b;

    end function;
    
    function to_byte_vector(s: string) return byte_vector is
        variable b: byte_vector(s'low to s'high);
    begin
    
        for i in b'range loop
            b(i) := std_logic_vector(to_unsigned(character'pos(s(i)), 8));
        end loop;

        return b;

    end function;

    function space_to_zero(bvi: bcd_digit_vector) return bcd_digit_vector is
        variable bvo: bcd_digit_vector(bvi'low to bvi'high);
    begin
    
        for i in bvi'range loop
        
            if (bvi(i) = bcd_space) then
                bvo(i) := bcd_zero;
            else
                bvo(i) := bvi(i);
            end if;

        end loop;

        return bvo;

    end function;

    function chr_to_byte(c: character) return byte is
    begin
    
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    
    end function;

    function byte_to_chr(b: byte) return character is
    begin
    
        return character'val(to_integer(unsigned(b)));
    
    end function;

--synopsys synthesis_off

    function to_string(slv: std_logic_vector) return string is
        variable l: line;
    begin
    
        for i in slv'range loop
            write(l, slv(i));
        end loop;
        
        return l.all;

    end function;

    function to_hstring(slv: std_logic_vector) return string is
        variable l: line;
    begin

        hwrite(l, slv);
        return l.all;

    end;

    file nd: text open write_mode is "nul";
    --file nd: text open write_mode is "/dev/null";

    function str_to_int(s: string) return integer is
    begin
        return integer'value(s);
    end function;
    
    function int_to_str(i: integer) return string is
    begin
        return integer'image(i);
    end function;
    
    function str_to_real(s: string) return real is
    begin
        return real'value(s);
    end function;
    
    function hex_to_chr(s: string) return character is
    begin
        
        if (s = "'\n'") then
            return LF;
        elsif (s(1) = ''') and (s(3) = ''') then
            return s(2);
        end if;

        report "Unknown character value '" & s & "'" severity failure; 
    end function;

    procedure copy_str(a: inout line; b: inout  line) is
        constant empty_str: string := "";
    begin
        writeline(nd, a);

        if (b /= null) then
            write(a, b.all);
        else
            write(a, empty_str);
        end if;

    end;

    function cmp(c: character; e: string) return boolean is
    begin
    
        for i in e'range loop
        
            if (c = e(i)) then
                return true;
            end if;
            
        end loop;
        
        return false;
    end function;
    
    function find(s: string; e: string; i_start: integer; i_end: integer) return integer is
    begin

        if (i_start < i_end) then

            for i in i_start to i_end loop

                if (cmp(s(i), e)) then
                    return i;
                end if;

            end loop;
            
        else

            for i in i_start downto i_end loop

                if (cmp(s(i), e)) then
                    return i;
                end if;

            end loop;
            
        end if;
        
        return -1;
    end function;

    function skip_whitespace(s: string; idx: integer; ws: string; fwd: boolean) return integer is
        variable i: integer;
    begin
        i := idx;
        
        if (fwd) then
        
            while i < s'high loop
            
                if (cmp(s(i), ws)) then
                    i := i + 1;
                else
                    return i;
                end if;
                
            end loop;
            
        else
        
            while i > s'low loop
            
                if (cmp(s(i), ws)) then
                    i := i - 1;
                else
                    return i;
                end if;
                
            end loop;

        end if;
        
        return i;
    
    end function;

    procedure write(f: inout chr_file; s: string) is
    begin

        for i in s'range loop

           write(f, s(i));

        end loop;

    end procedure;
    
    procedure writeln(f: inout chr_file; s: string) is
    begin

        write(f, s & LF);

    end procedure;

    file std_out: chr_file open write_mode is "STD_OUTPUT";
    
    procedure print(c: character) is
    begin

        write(std_out, c);

    end procedure;

    procedure print(s: string) is
    begin
    
       write(std_out, s);

    end procedure;

    procedure println(s: string) is
    begin

        writeln(std_out, s);

    end procedure;

    procedure println(l: inout line) is
    begin

        writeln(std_out, l.all);
        writeline(nd, l);

    end procedure;

--synopsys synthesis_on
    
end util;
