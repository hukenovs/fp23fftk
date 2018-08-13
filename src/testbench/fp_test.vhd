-------------------------------------------------------------------------------
--
-- Title       : FFT_logic
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP logic
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
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

use ieee.std_logic_textio.all;
use std.textio.all;	

use work.fp_m1_pkg.all;

entity fp_main_test is 
	generic(													    
		NFFT			: integer:=10;			
		XSERIES			: string:="7SERIES"
		);
end fp_main_test;

architecture fp_main_test of fp_main_test is   		  


-- ******************************** --
-- CHANGE STAGES TO EDIT FFT TEST!! --
constant	SCALE			: std_logic_vector(5 downto 0):="011010"; 
constant	USE_FLY_FFT		: std_logic:='1';	
constant	USE_FLY_IFFT	: std_logic:='1';	
constant	USE_SCALE		: boolean:=FALSE; -- TRUE - MAX RAMBs, FALSE - TAYLOR ALGO	
-- ******************************** -- 

constant Nst2x			: integer:=2**(NFFT);
signal clk				: std_logic:='0';
signal reset			: std_logic:='0';
		
signal din_re			: std_logic_vector(15 downto 0):=x"0000"; 
signal din_im			: std_logic_vector(15 downto 0):=x"0000"; 
signal din_en			: std_logic:='0';

signal dout0			: std_logic_vector(15 downto 0);
signal dout1 			: std_logic_vector(15 downto 0);
signal dval				: std_logic;

begin
	
clk <= not clk after 5 ns;
reset <= '0', '1' after 100 ns;
-------------------------------------------------------------------------------- 
read_din: process is
	file file_dt_re	: text; 	   
	file file_dt_im	: text; 
	
	variable l		: line;	
	variable lt		: integer:=0;
	variable lt1	: integer:=0; 
	variable lt2	: integer:=0; 
	variable count  : integer:=0;
begin  	  	
	wait for 5 ns;
	if (reset = '0') then	
		din_en <= '0';
		din_re <= (others => '0');
		din_im <= (others => '0');
	else	
		wait for 100 ns;
		lp_inf: for jj in 0 to 31 loop	   
			file_close( file_dt_re);
			file_close( file_dt_im);				
			file_open( file_dt_re, "../../../../../math/din_re.dat", read_mode );
			file_open( file_dt_im, "../../../../../math/din_im.dat", read_mode );						
			count :=0;
			
			wait for 50 ns;
			
			lp_32k: for ii in 0 to Nst2x-1 loop
				wait until rising_edge(clk);

				-- if (ii < 5) then
					-- readline( file_dt_re, l );
					-- readline( file_dt_im, l );
					-- count :=0;
					-- din_en <= '0'; 
				-- else
					
					readline( file_dt_re, l );
					read( l, lt1 );	
					readline( file_dt_im, l );
					read( l, lt2 );	 
					
					din_re <= conv_std_logic_vector( lt1, 16 ) after 1 ns;
					din_im <= conv_std_logic_vector( lt2, 16 ) after 1 ns;
					din_en <= '1' after 1 ns; 
					count := count + 1;
			end loop;	
			
			wait until rising_edge(clk);
			din_en <= '0' after 1 ns;
			din_re <= ( others => '0') after 1 ns;
			din_im <= ( others => '0') after 1 ns;				
		
			wait for 100 ns;
		end loop;
	end if;
end process;  
--------------------------------------------------------------------------------
write_dout: process(clk) is    -- write file_io.out (++ done goes to '1')
	file log 					: TEXT open WRITE_MODE is "../../../../../math/dat_out.dat";
	variable str 				: LINE;
	variable spc 				: string(1 to 4) := (others => ' ');
	variable cnt 				: integer range -1 to 1600000000;	
begin
	if rising_edge(clk) then
		if reset = '0' then
			cnt := -1;		
		elsif dval = '1' then
			cnt := cnt + 1;	
			--------------------------------
			write(str, CONV_INTEGER(dout0), LEFT);
			write(str, spc);			
			--------------------------------
			write(str, CONV_INTEGER(dout1), LEFT);
			writeline(log, str);
		else
			null;
		end if;
	end if;
end process; 		
--------------------------------------------------------------------------------
uut: entity work.fp23_logic_m2
	generic map (
		USE_CONJ	=> FALSE,			
		USE_PAIR	=> TRUE,		
		XSERIES		=> XSERIES,			
		NFFT		=> NFFT,								
		USE_SCALE	=> USE_SCALE				
	)
	port map ( 
		reset		=> reset,	
		clk			=> clk,	
 
        use_fly	    => USE_FLY_FFT,
        use_ifly    => USE_FLY_IFFT,

		dt_rev		=> '0',
		dt_mux		=> "11",
		dt_fft		=> '0',
		fpscale		=> SCALE, 

		din_re		=> din_re,
		din_im		=> din_im,
		din_en		=> din_en,	
	
		d_re		=> dout0, 		
		d_im		=> dout1, 		
		d_vl		=> dval
	);
	
end fp_main_test; 