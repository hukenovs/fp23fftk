-------------------------------------------------------------------------------
--
-- Title       : FFT_logic
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : fft_align_delays_m3
--
-- Version 1.0 : Delay correction for TWIDDLE factor and BFLYes 
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

library work;
use work.fp_m1_pkg.fp23_complex;

entity fft_align_delays_m3 is 
	generic( 
		TD				: time:=1ns;	--! Delay time
		NFFT			: integer:=16;	--! FFT lenght
		STAGE 			: integer:=0;	--! FFT stage		
		USE_SCALE		: boolean:=true --! Use Taylor for twiddles			
	);
	port(	
		clk				: in  std_logic; --! Clock
		-- DATA FROM BUTTERFLY --
		ia				: in  fp23_complex; --! Input data (A)
		ib				: in  fp23_complex; --! Input data (B)
		-- DATA TO BUTTERFLY
		iax				: out fp23_complex; --! Output data (A)
		ibx				: out fp23_complex; --! Output data (B)		
		
		-- ENABLEs FROM/TO BUTTERFLY -
		bfly_en			: in  std_logic;
		bfly_enx		: out std_logic;
		coe_en			: out std_logic
	);
end fft_align_delays_m3;

architecture fft_align_delays_m3 of fft_align_delays_m3 is   		  

begin 

-- LOW STAGES: Z = 1 (from twiddle) + 9 (from int2fp) + 4 (to mult) = 14 (adder latency)
LOW_WW: if (NFFT-3 < STAGE) generate
	signal ww_ena : std_logic_vector(3 downto 0); 
begin
	ww_ena <= ww_ena(2 downto 0) & bfly_en after td when rising_edge(clk);	
	coe_en <= ww_ena(3);
	
	iax <= ia;   	
	ibx <= ib;   	
	bfly_enx <= bfly_en;
end generate;

-- MEDIUM STAGES: Z = 3 (from twiddle) + 9 (from int2fp) + 2 (to mult) = 14 (adder latency)
MED_WW: if (NFFT-3 >= STAGE) and (NFFT-13 < STAGE) generate
	signal ww_ena : std_logic;--_vector(1 downto 0); 
begin
	ww_ena <= bfly_en after td when rising_edge(clk); -- ww_ena(0) & 		
	coe_en <= ww_ena after td when rising_edge(clk);		

	iax <= ia;   	
	ibx <= ib;   	
	bfly_enx <= bfly_en;	
end generate;			

-- LONG STAGES: Z = 3 (from twiddle) + 9 (from int2fp) + 2 (to mult) = 14 (adder latency)
LONG_WW: if (NFFT-13 >= STAGE) generate
	X_TLR_NO: if (USE_SCALE = TRUE) generate
		signal ww_ena : std_logic;--_vector(1 downto 0); 
	begin			

		ww_ena <= bfly_en after td when rising_edge(clk);			
		coe_en <= ww_ena after td when rising_edge(clk);	
	
		iax <= ia;   	
		ibx <= ib;   	
		bfly_enx <= bfly_en;		
	end generate; 			

	-- LONG STAGES: Z = 3 (from twiddle) + 9 (from int2fp) + 25 (dsp twiidle) - 23 (!) = 14 (adder latency)	
	X_TLR_YES: if (USE_SCALE = FALSE) generate
		signal bfly_enz 	: std_logic_vector(20 downto 0);
		type complex_fp23xM is array (20 downto 0) of fp23_complex;
		signal iaz 			: complex_fp23xM;
		signal ibz 			: complex_fp23xM; 
		
	begin	
		coe_en <= bfly_en; -- after td when rising_edge(clk);
		
		iax <= iaz(20);   	
		ibx <= ibz(20);   	
		
		iaz <= iaz(19 downto 0) & ia after td when rising_edge(clk);   	
		ibz <= ibz(19 downto 0) & ib after td when rising_edge(clk);   					
		bfly_enz <= bfly_enz(19 downto 0) & bfly_en after td when rising_edge(clk); 
		bfly_enx <= bfly_enz(20);	
	end generate;		
end generate;

end fft_align_delays_m3; 