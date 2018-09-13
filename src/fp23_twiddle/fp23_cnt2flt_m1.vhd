-------------------------------------------------------------------------------
--
-- Title       : fp23_cnt2flt_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : version 1.0 
--
-- 			Data decoder for twiddle factor.
-- 			Main algorithm for calculation FFT coefficients	by Taylor scheme.
--
--			Wcos(x) = cos(x)+sin(x)*pi*cnt(x)/NFFT; *
--			Wsin(x) = sin(x)-cos(x)*pi*cnt(x)/NFFT;
--
--			* where	pi is 
--				ii = 01 -> x"239220"; -- 008K FFT	 
--				ii = 02 -> x"229220"; -- 016K FFT	
--				ii = 04 -> x"219220"; -- 032K FFT
--				ii = 08 -> x"209220"; -- 064K FFT
--				ii = 16 -> x"1F9220"; -- 128K FFT
--				ii = 32 -> x"1E9220"; -- 256K FFT
--				ii = 64 -> x"1D9220"; -- 512K FFT	
--
--			RAMB (Width * Depth) is constant value and equals 48x1K,
-- 
--			Taylor alrogithm takes 3 Mults and 2 Adders in FP format. 
--
-- Summary:
--			Twiddle factor generator takes 3 DSP48s and 3 RAMBs 18K.
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
use IEEE.STD_LOGIC_unsigned.all; 
use IEEE.NUMERIC_STD.all;

library WORK;
use WORK.fp_m1_pkg.fp23_data;
use WORK.fp_m1_pkg.fp23_complex;

entity fp23_cnt2flt_m1 is
	generic(
		XSERIES	: string:="7SERIES"; --! FPGA family: for 6/7 series: "7SERIES"; for ULTRASCALE: "ULTRA";
		ii	: integer:=4 --! 0, 1, 2, 3, 4, 5 -- 16-stages-stage_num
	);
	port (
		rom_ww		: in  fp23_complex;	--! input data coefficient
	   	rom_en		: in  std_logic;	--! input data enable
		   
		dsp_ww		: out fp23_complex;	--! output data coefficient   
		int_cnt		: in  std_logic_vector(ii downto 0);	--! counter for ROM		
		
		clk 		: in  std_logic;	--! global clock
		rstn  		: in  std_logic		--! negative reset
	);
end fp23_cnt2flt_m1;

architecture fp23_cnt2flt_m1 of fp23_cnt2flt_m1 is 

function find_pi (stage: in integer) return std_logic_vector is
begin
	case stage is -- 109220 equals 3.1416015625 
		when 0 => return x"239220"; -- = pi * 2^19 = (sign, exp, man) 	 
		when 1 => return x"229220"; -- 16K	
		when 2 => return x"219220";	-- 32K
		when 3 => return x"209220"; -- 64K
		when 4 => return x"1F9220"; -- 128K
		when 5 => return x"1E9220"; -- 256K
		when 6 => return x"1D9220"; -- 512K		
		when others => return x"000000";
	end case;
end;
constant std_pi		: std_logic_vector(23 downto 00):=find_pi(ii);
constant fp23_pi	: fp23_data:=(std_pi(21 downto 16), '0', std_pi(15 downto 00));

constant MUL_DT		: natural:=1; -- Mult delay	
constant ADD_DT		: natural:=4; -- Mult delay	
type std_logic_array_Mx24 is array (ADD_DT-1 downto 0) of fp23_data;

signal del_a_sin	: std_logic_array_Mx24;
signal del_a_cos	: std_logic_array_Mx24;

signal res_sin		: fp23_data; 
signal res_cos		: fp23_data; 
signal mlt1_cos		: fp23_data;
signal mlt1_sin		: fp23_data;
signal add2_cos		: fp23_data;
signal add2_sin		: fp23_data;

signal pi_mult		: fp23_data;
signal fp_cnt 		: fp23_data;

signal pi_en		: std_logic;
signal mt_en		: std_logic;

function fp_converter(jj : integer) return std_logic_vector is
	variable value 	: std_logic_vector(21 downto 0);
	variable msb 	: integer:=1;
	variable man	: std_logic_vector(15 downto 0);
begin
	man := std_logic_vector(to_unsigned(jj, man'length));
	ml: for jj in 0 to man'length-1 loop
		if (man = 0) then
			msb := 32;
			exit;
		else
			if (man(man'length-1) = '1') then
				man := man(man'length-2 downto 0) & '0';
				exit;
			else
				man := man(man'length-2 downto 0) & '0';
				msb := msb + 1;
			end if;
		end if;
	end loop;
	msb := 32-msb;	
	--value(22) := '0'; -- sign always = 0
	value(15 downto 0) := man;
	value(21 downto 16) := std_logic_vector(to_unsigned(msb, 6));	
	return value;
end fp_converter;	

constant Nww		: integer:=2**(ii+1);
type rom_stdxn		is array (0 to Nww-1) of std_logic_vector(21 downto 0);
type rom_fpxxn		is array (0 to Nww-1) of fp23_data;

function read_converter(NCNT : integer) return rom_fpxxn is
	variable rom0 : rom_stdxn;
	variable rom1 : rom_fpxxn;	
begin
	for jj in 0 to NCNT-1 loop
		rom0(jj) := fp_converter(jj); 
		rom1(jj) := (rom0(jj)(21 downto 16), '0', rom0(jj)(15 downto 00));
	end loop;
	return rom1;
end read_converter;

constant cnt_rom 	: rom_fpxxn:=read_converter(Nww);

begin 	
  
dsp_ww.re <= add2_cos;	
dsp_ww.im <= add2_sin;	

del_a_sin <= del_a_sin(ADD_DT-2 downto 0) &	rom_ww.im when rising_edge(clk);
del_a_cos <= del_a_cos(ADD_DT-2 downto 0) &	rom_ww.re when rising_edge(clk);	

res_sin <= del_a_sin(ADD_DT-1) when rising_edge(clk); 
res_cos <= del_a_cos(ADD_DT-1) when rising_edge(clk);

fp_cnt <= cnt_rom(conv_integer(int_cnt)) when rising_edge(clk);	

-------------------------------------------------------------------------------
------------------------ FLOATING POINT CALCULATION: --------------------------
-------------------------------------------------------------------------------

CALC_314_MULT : entity work.fp23_mult_m2
	generic map ( 
		XSERIES => XSERIES)
	port map(
		aa 		=> fp_cnt,
		bb 		=> fp23_pi,
		cc 		=> pi_mult,
		enable 	=> rom_en,
		valid	=> pi_en,
		reset 	=> rstn,
		clk 	=> clk
	);	
	
CALC_PI_SIN: entity work.fp23_mult_m2 
	generic map ( 
		XSERIES => XSERIES)
	port map(
		aa 		=> rom_ww.im,--del_m_sin, 
		bb 		=> pi_mult, 
		cc		=> mlt1_sin,  
		enable 	=> pi_en, --din_en,
		valid	=> mt_en,
		reset  	=> rstn, 
		clk 	=> clk 
	);	

CALC_PI_COS: entity work.fp23_mult_m2 
	generic map ( 
		XSERIES => XSERIES)
	port map(
		aa 		=> rom_ww.re, 
		bb 		=> pi_mult, 
		cc		=> mlt1_cos,  
		enable 	=> pi_en, --din_en,
		valid	=> open,
		reset  	=> rstn, 
		clk 	=> clk 
	);
		
CALC_ADD_COS: entity work.fp23_addsub_m2 	
	port map(
		aa 		=> res_cos, 
		bb 		=> mlt1_sin, 
		cc		=> add2_cos,  
		addsub 	=> '0',
		reset  	=> rstn, 
		enable 	=> mt_en, --din_en,
		valid	=> open,
		clk 	=> clk 
	);			
	
CALC_ADD_SIN: entity work.fp23_addsub_m2 	
	port map(
		aa 		=> res_sin, 
		bb 		=> mlt1_cos, 
		cc		=> add2_sin,  
		addsub 	=> '1',
		reset  	=> rstn, 
		enable 	=> mt_en, --din_en,
		valid	=> open,--ad2_en, --ad2_en,
		clk 	=> clk 
	);		
	
end fp23_cnt2flt_m1;