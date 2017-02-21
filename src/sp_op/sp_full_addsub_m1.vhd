-------------------------------------------------------------------------------
--
-- Title       : sp_full_addsub
-- Design      : fp24fftk
-- Author      : Kapitanov
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- Description : version 1.0 
--
-------------------------------------------------------------------------------
--
--	Version 1.0  10.01.2013
--					Description : 1-bit full adder with BEL and RLOC options;
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--	The MIT License (MIT)
--	Copyright (c) 2016 Kapitanov Alexander 													 
--		                                          				 
-- Permission is hereby granted, free of charge, to any person obtaining a copy 
-- of this software and associated documentation files (the "Software"), 
-- to deal in the Software without restriction, including without limitation 
-- the rights to use, copy, modify, merge, publish, distribute, sublicense, 
-- and/or sell copies of the Software, and to permit persons to whom the 
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in 
-- all copies or substantial portions of the Software.
--
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
-- IN THE SOFTWARE.
-- 		                                                 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all; 
library unisim;
use unisim.vcomponents.all;

entity sp_full_addsub_m1 is	
	generic(
		pos 	: integer :=0);	
	port(
		clk		: in  std_logic;		
		ce		: in  std_logic;	
		rst     : in  std_logic;
					  
		da		: in  std_logic;
		db 		: in  std_logic;
		cin		: in  std_logic;
		dc		: out std_logic;
		cout	: out std_logic; 	
		add_sub : in  std_logic
	);

end sp_full_addsub_m1;


architecture sp_full_addsub_m1 of sp_full_addsub_m1 is

signal lut_out		: std_logic;
signal xor_c		: std_logic;

signal dcz			: std_logic;

attribute BEL		: string;
attribute RLOC		: string;
--attribute U_SET 	: string;

type str_array is array (3 downto 0) of string(1 downto 1);	
constant str : str_array:=(0=>"A", 1=>"B", 2=>"C",3=>"D"); 

attribute BEL of lut_uut	: label is str(pos) & "6LUT";
attribute BEL of fdre_uut	: label is "FF" & str(pos);
attribute RLOC of lut_uut	: label is "X0Y0"; 
attribute RLOC of fdre_uut	: label is "X0Y0";	
--attribute U_SET of lut_uut	: label is "uset";
--attribute U_SET of fdre_uut	: label is "uset";

begin		  
	
lut_uut : LUT3
generic map(INIT => X"69")
port map(
	O	=> lut_out,
	I0	=> da,
	I1	=> db,
	I2	=> add_sub
);
	
xor_uut: XORCY 
port map(
	O 	=> xor_c, 
	CI 	=> cin, 
	LI 	=> lut_out 
);

mux_uut: MUXCY 
port map(
	O 	=> cout,
	CI 	=> cin,
	DI 	=> da,
	S  	=> lut_out
);	 

fdre_uut: FDRE 
generic map(INIT => '0')
port map(
	Q 	=> dcz,
	C   => clk, 
	CE  => ce,
	R 	=> rst,
	D   => xor_c 
);
dc <= dcz after 0.9 ns;
	
end sp_full_addsub_m1;