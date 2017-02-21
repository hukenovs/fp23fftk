-------------------------------------------------------------------------------
--
-- Title       : fp23_bfly_empty_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP23 butterfly
--
-------------------------------------------------------------------------------
--
--	Version 1.0  22.05.2015
--			   	 Description: Empty butterfly for testing purpose			
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

library work;
use work.fp_m1_pkg.fp23_complex;

entity fp23_bfly_empty_m1 is
	generic (
		td		: time:=1ns	--! Time delay for simulation
	);	
	port(
		IA 			: in  fp23_complex; --! Even data in part
		IB 			: in  fp23_complex; --! Odd data in part
		DIN_EN 		: in  std_logic;	--! Data enable
		WW 			: in  fp23_complex; --! Twiddle data
		OA 			: out fp23_complex; --! Even data out
		OB 			: out fp23_complex; --! Odd data out
		DOUT_VAL	: out std_logic;	--! Data valid			
		RESET  		: in  std_logic;	--! Global reset
		CLK 		: in  std_logic		--! Clock	
	);
end fp23_bfly_empty_m1;

architecture fp23_bfly_empty_m1 of fp23_bfly_empty_m1 is

begin
	
OA <= IA;
OB <= IB;
DOUT_VAL <= DIN_EN;

end fp23_bfly_empty_m1;