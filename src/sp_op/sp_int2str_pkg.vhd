-------------------------------------------------------------------------------
--
-- Title       : sp_int2str_pkg
-- Design      : fp24fftk
-- Author      : Kapitanov
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- Description : fixed point integer to string
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
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package sp_int2str_pkg is
	function itoa ( num: in integer; pow: in integer) return string;
	function nat2str( num: in integer; pow: in integer) return string;
--	function xil_dev( num: in integer) return string;
end sp_int2str_pkg;

package	body sp_int2str_pkg	is
	function itoa( num: in integer; pow: in integer) return string is
	 variable str: string( pow downto 1 );
	 variable pw: integer:=1; 
	 variable powe: integer;
	 variable dig: integer;
	 variable tnum: integer;
	begin
		tnum:=num;
		for jj in 0 to pow-1 loop
			powe:=pow-jj-1;
			pw:=1;
			for ii in 0 to powe loop
				pw:=(pw*10);
			end loop;
			pw:=pw/10;	
			dig:=0;	
			for kk in 0 to 9 loop					
				if (tnum<pw) then exit; else dig:=kk+1; tnum:=tnum-pw; end if;			
			end loop;
		  	 case dig is
				when 0 => str(pow-jj) := '0';
				when 1 => str(pow-jj) := '1';
				when 2 => str(pow-jj) := '2';
				when 3 => str(pow-jj) := '3';
				when 4 => str(pow-jj) := '4';
				when 5 => str(pow-jj) := '5';
				when 6 => str(pow-jj) := '6';
				when 7 => str(pow-jj) := '7';
				when 8 => str(pow-jj) := '8';
				when 9 => str(pow-jj) := '9';
				when others => null;
			 end case;
		 end loop;	 
	  return str;
	end itoa;
		 
	function nat2str( num: in integer; pow: in integer) return string is
	variable str: string( pow downto 1 );
	variable pw: integer:=1; 
	variable powe: integer;
	variable dig: integer;
	variable tnum: integer;
	variable nnn :integer;
	begin
		nnn:=1;
	for ii in 1 to pow loop
			pw:=1;
			for jj in 0 to ii loop
				pw:=(pw*10);
			end loop;
			
			pw:=pw/10;	-- 10^ii						 
			
			if num>=pw then nnn:=ii+1; end if;		
	end loop;	
	return itoa(num,nnn);
	end nat2str;
	
--	function xil_dev( num: in integer) return string is
--	variable str: string(7 downto 1);
--	begin
--		if num = 5 then
--			str := "VIRTEX5";
--		elsif num = 6 then
--			str := "VIRTEX6";
--		elsif num = 7 then
--			str := "7SERIES";
--		else
--			str := "7SERIES";
--		end if;
--	return str;
--	end xil_dev;	
	
end sp_int2str_pkg;
