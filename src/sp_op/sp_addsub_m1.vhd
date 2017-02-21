-------------------------------------------------------------------------------
--
-- Title       : sp_addsub_m1
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
--					Description : adder/subtractor with BEL and RLOC options	
-- 									SLICEL contains 4 6LUT + 8 FD: Virtex-5,6,7
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.sp_int2str_pkg.all;

entity sp_addsub_m1 is
	generic(	
		N 		: integer:=64);
	port(
		data_a 	: in  std_logic_vector(N-1 downto 0);
		data_b 	: in  std_logic_vector(N-1 downto 0);
		data_c 	: out std_logic_vector(N-1 downto 0);
		add_sub	: in  std_logic;  -- '0' - add, '1' - sub
		cin     : in  std_logic:='0';
		cout    : out std_logic;
		clk    	: in  std_logic;
		ce 		: in  std_logic:='1';	
		aclr  	: in  std_logic:='1'
	);				 
end sp_addsub_m1;

architecture sp_addsub_m1 of sp_addsub_m1 is 

component sp_full_addsub_m1 is	
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

end component;

signal cix		: std_logic_vector(N-0 downto 0):=(others=>'0');
signal cox 		: std_logic_vector(N-1 downto 0):=(others=>'0'); 
attribute RLOC	: string;

begin 

gen_slice: for ii in 0 to N-1 generate  

constant xx : natural:=0; 
constant yy	: natural:=conv_integer(conv_std_logic_vector(ii, 16)(7 downto 2));
constant rloc_str : string :="X" & nat2str(xx,2) & "Y" & nat2str(yy,2) ;
attribute RLOC of full_slice : label is rloc_str; 

begin	

full_slice: sp_full_addsub_m1
	generic map( pos => conv_integer(conv_std_logic_vector(ii, 16)(1 downto 0))
	)
	port map(
		da		=> data_a(ii), 
		db 		=> data_b(ii), 
		dc		=> data_c(ii), 
		cin		=> cix(ii), 
		cout	=> cox(ii), 
		add_sub => add_sub, 
		ce		=> ce,
		rst		=> aclr, 
		clk		=> clk 
	); 
	cix(ii+1) <= cox(ii);
end generate;

cix(0) <= cin;
cout <= cox(N-1);

end sp_addsub_m1;