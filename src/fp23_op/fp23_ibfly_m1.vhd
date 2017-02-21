-------------------------------------------------------------------------------
--
-- Title       : fp23_ibfly_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP23 butterfly
--
-------------------------------------------------------------------------------
--
--	Version 1.0  07.04.2013
--			   	 Description: Simple butterfly Radix-2 for FFT (DIT)
--					Algorithm: Decimation in time
--					Delays: Multiplier = 5, Add/Sub = 14, Total = 14+14+5=33.					
--					X = A+B*W, Y = A-B*W					
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
use ieee.std_logic_unsigned.all;

library work;
use work.fp_m1_pkg.fp23_mult_m1;
use work.fp_m1_pkg.fp23_addsub_m1;
use work.fp_m1_pkg.fp23_complex;
use work.fp_m1_pkg.fp23_data;

entity fp23_ibfly_m1 is
	generic (
		use_conj : boolean:=FALSE; --! Use conjugation for IFFT
		td	: time:=1ns	--! Time delay for simulation
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
end fp23_ibfly_m1;

architecture fp23_ibfly_m1 of fp23_ibfly_m1 is

type complex_fp23x18 is array(18 downto 0) of fp23_complex;

signal sum 			: fp23_complex; 
signal dif 			: fp23_complex;
signal bw 			: fp23_complex;

signal re_x_re 		: fp23_data;
signal im_x_im 		: fp23_data;
signal re_x_im 		: fp23_data;
signal im_x_re 		: fp23_data;

signal ia_del 		: complex_fp23x18;
signal dval_en		: std_logic_vector(2 downto 0);

begin
 
ia_del <= ia_del(17 downto 0) & IA after td when rising_edge(clk);

-------- PROD = IB * WW --------	
RE_RE_MUL : fp23_mult_m1
	generic map ( 
		td  => td
	)	
	port map (
		aa 		=> IB.re,
		bb 		=> WW.re,
		cc 		=> re_x_re,
		enable 	=> DIN_EN,
		valid 	=> dval_en(0),		
		reset 	=> reset,
		clk 	=> clk
	); 
	
IM_IM_MUL : fp23_mult_m1
	generic map ( 
		td  => td
	)	
	port map (
		aa 		=> IB.im,
		bb 		=> WW.im,
		cc 		=> im_x_im,
		enable 	=> DIN_EN,
		reset 	=> reset,
		clk 	=> clk
	);	
	
RE_IM_MUL : fp23_mult_m1
	generic map ( 
		td  => td
	)	
	port map (
		aa 		=> IB.re,
		bb 		=> WW.im,
		cc 		=> re_x_im,
		enable 	=> DIN_EN,
		reset 	=> reset,
		clk 	=> clk
	);
	
IM_RE_MUL : fp23_mult_m1
	generic map ( 
		td  => td
	)	
	port map (
		aa 		=> IB.im,
		bb 		=> WW.re,
		cc 		=> im_x_re,
		enable 	=> DIN_EN,
		reset 	=> reset,
		clk 	=> clk
	);	
	
G_CONJ_FALSE: if use_conj = FALSE generate
begin
	-------- WW conjugation --------
	OB_IM_SUB: fp23_addsub_m1 
		generic map ( 
			td  => td
		)	
		port map(
			aa 		=> im_x_re, -- ?? 		
			bb 		=> re_x_im, 		
			cc 		=> bw.im,	
			addsub	=> '1',
			enable 	=> dval_en(0),	
			reset  	=> reset,  	
			clk 	=> clk 	
		);	
		
	OB_RE_ADD: fp23_addsub_m1 
		generic map ( 
			td  => td
		)	
		port map(
			aa 		=> re_x_re, 		
			bb 		=> im_x_im, 		
			cc 		=> bw.re, 	
			addsub	=> '0',
			enable 	=> dval_en(0), 	
			valid 	=> dval_en(1),
			reset  	=> reset,  	
			clk 	=> clk 	
		);	
end generate; 	
G_CONJ_TRUE: if use_conj = TRUE generate
begin
	-------- WW conjugation --------
	OB_IM_ADD: fp23_addsub_m1 
		generic map ( 
			td  => td
		)	
		port map(
			aa 		=> im_x_re, 		
			bb 		=> re_x_im, 		
			cc 		=> bw.im,	
			addsub	=> '0',
			enable 	=> dval_en(0),	
			reset  	=> reset,  	
			clk 	=> clk 	
		);	
		
	OB_RE_SUB: fp23_addsub_m1 
		generic map ( 
			td  => td
		)	
		port map(
			aa 		=> re_x_re, 		
			bb 		=> im_x_im, 		
			cc 		=> bw.re, 	
			addsub	=> '1',
			enable 	=> dval_en(0), 	
			valid 	=> dval_en(1),
			reset  	=> reset,  	
			clk 	=> clk 	
		);	
end generate; 

-------- OA & OB --------	
ADD_RE: fp23_addsub_m1 
	generic map ( 
		td  => td
	)	
	port map(
		aa 		=> ia_del(18).re, 		
		bb 		=> bw.re, 		
		cc 		=> sum.re, 
		addsub	=> '0',		
		enable 	=> dval_en(1), 	
		reset  	=> reset,  	
		clk 	=> clk 	
	);
	
ADD_IM: fp23_addsub_m1 
	generic map ( 
		td  => td
	)		
	port map(
		aa 		=> ia_del(18).im, 		
		bb 		=> bw.im, 		
		cc 		=> sum.im,
		addsub	=> '0',		
		enable 	=> dval_en(1), 
		valid	=> dval_en(2),
		reset  	=> reset,  	
		clk 	=> clk 	
	);	

SUB_RE: fp23_addsub_m1 
	generic map ( 
		td  => td
	)	
	port map(
		aa 		=> ia_del(18).re, 		
		bb 		=> bw.re, 		
		cc 		=> dif.re, 
		addsub	=> '1',		
		enable 	=> dval_en(1), 	
		reset  	=> reset,  	
		clk 	=> clk 	
	);
	
SUB_IM: fp23_addsub_m1 
	generic map ( 
		td  => td
	)		
	port map(
		aa 		=> ia_del(18).im, 		
		bb 		=> bw.im, 		
		cc 		=> dif.im,
		addsub	=> '1',		
		enable 	=> dval_en(1),
		reset  	=> reset,  	
		clk 	=> clk 	
	);
	
OA		 <=	sum;
OB		 <=	dif;
DOUT_VAL <= dval_en(2);

end fp23_ibfly_m1;