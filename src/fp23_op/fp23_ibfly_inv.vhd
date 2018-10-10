-------------------------------------------------------------------------------
--
-- Title       : fp23_ibfly_inv
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
-- E-mail      : sallador@bk.ru
--
-- Description : DIT butterfly (Radix-2)
--
-------------------------------------------------------------------------------
--
--	Version 1.0  10.12.2017
--    Description: Simple butterfly Radix-2 for FFT (DIT)
--
--    Algorithm: Decimation in time
--
--    X = A+B*W, 
--    Y = A-B*W;
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
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LDT_IABLE FOR ANY CLAIM, DAMAGES OR OTHER 
-- LDT_IABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
-- IN THE SOFTWARE.
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fp_m1_pkg.fp23_complex;
use work.fp_m1_pkg.fp23_data;

entity fp23_ibfly_inv is
	generic (
		STAGE		: integer:=0; --! Butterfly stage
		USE_CONJ 	: boolean:=FALSE; --! Use conjugation for IFFT
		XSERIES		: string:="7SERIES"	--! FPGA family: for 6/7 series: "7SERIES"; for ULTRASCALE: "ULTRA";
	);	
	port(
		DT_IA 		: in  fp23_complex; --! Even data in part
		DT_IB 		: in  fp23_complex; --! Odd data in part
		DI_EN 		: in  std_logic;	--! Data enable
		WW 			: in  fp23_complex; --! Twiddle data
		DT_OA 		: out fp23_complex; --! Even data out
		DT_OB 		: out fp23_complex; --! Odd data out
		DO_VL		: out std_logic;	--! Data valid
		RESET  		: in  std_logic;	--! Global reset
		CLK 		: in  std_logic		--! Clock	
	);
end fp23_ibfly_inv;

architecture fp23_ibfly_inv of fp23_ibfly_inv is

signal sum 			: fp23_complex; 
signal dif 			: fp23_complex;
signal bw 			: fp23_complex;

signal aw 			: fp23_complex;
signal dval_en		: std_logic_vector(2 downto 0);

begin
 
 
---- First butterfly: don't need multipliers! WW0 = {1, 0} ----
xST0: if (STAGE = 0) generate
begin
	bw <= DT_IB;
	aw <= DT_IA;
	dval_en(1) <= DI_EN;
end generate;
 
---- Second butterfly: WW0 = {1, 0} and WW1 = {0, -1} ----
xST1: if (STAGE = 1) generate
	signal dt_sw	: std_logic;
begin
	---- Counter for twiddle factor ----
	pr_cnt: process(clk) is
	begin
		if rising_edge(clk) then
			if (RESET = '0') then
				dt_sw <= '0';
			elsif (DI_EN = '1') then
				dt_sw <= not dt_sw;
			end if;
		end if;
	end process;
	
	G_CONJ_FALSE: if (USE_CONJ = FALSE) generate
		---- Flip twiddles ----
		pr_inv: process(clk) is
		begin
			if rising_edge(clk) then
				---- WW(0){Re,Im} = {1, 0} ----
				if (dt_sw = '0') then
					bw.re <= DT_IB.re;
					bw.im <= DT_IB.im;
				---- WW(1){Re,Im} = {0, 1} ----
				else
					bw.re <= (DT_IB.im.exp, not(DT_IB.im.sig), DT_IB.im.man);
					bw.im <= DT_IB.re;
				end if;
				aw <= DT_IA;
				dval_en(1) <= DI_EN;
			end if;
		end process;
	end generate;
	
	G_CONJ_TRUE: if (USE_CONJ = TRUE) generate
		---- Flip twiddles ----
		pr_inv: process(clk) is
		begin
			if rising_edge(clk) then
				---- WW(0){Re,Im} = {1, 0} ----
				if (dt_sw = '0') then
					bw.re <= DT_IB.re;
					bw.im <= DT_IB.im;
				---- WW(1){Re,Im} = {0, 1} ----
				else
					bw.re <= DT_IB.im;
					bw.im <= (DT_IB.re.exp, not(DT_IB.re.sig), DT_IB.re.man);
				end if;
				aw <= DT_IA;
				dval_en(1) <= DI_EN;
			end if;
		end process;
	end generate;	
	
end generate;

xSTn: if (STAGE > 1) generate
	signal re_x_re 		: fp23_data;
	signal im_x_im 		: fp23_data;
	signal re_x_im 		: fp23_data;
	signal im_x_re 		: fp23_data;
	
	type complex_fp23x14 is array(14 downto 0) of fp23_complex;
	signal dt_ia_del 	: complex_fp23x14;
	
begin
	dt_ia_del <= dt_ia_del(dt_ia_del'left-1 downto 0) & DT_IA when rising_edge(clk);
	
	-------- PROD = DT_IB * WW --------	
	RE_RE_MUL : entity work.fp23_mult_m2
		generic map ( 
			XSERIES => XSERIES
		)	
		port map (
			aa 		=> DT_IB.re,
			bb 		=> WW.re,
			cc 		=> re_x_re,
			enable 	=> DI_EN,
			valid 	=> dval_en(0),
			reset 	=> reset,
			clk 	=> clk
		); 
		
	IM_IM_MUL : entity work.fp23_mult_m2
		generic map ( 
			XSERIES => XSERIES
		)	
		port map (
			aa 		=> DT_IB.im,
			bb 		=> WW.im,
			cc 		=> im_x_im,
			enable 	=> DI_EN,
			reset 	=> reset,
			clk 	=> clk
		);	
		
	RE_IM_MUL : entity work.fp23_mult_m2
		generic map ( 
			XSERIES => XSERIES
		)	
		port map (
			aa 		=> DT_IB.re,
			bb 		=> WW.im,
			cc 		=> re_x_im,
			enable 	=> DI_EN,
			reset 	=> reset,
			clk 	=> clk
		);
		
	IM_RE_MUL : entity work.fp23_mult_m2
		generic map ( 
			XSERIES => XSERIES
		)	
		port map (
			aa 		=> DT_IB.im,
			bb 		=> WW.re,
			cc 		=> im_x_re,
			enable 	=> DI_EN,
			reset 	=> reset,
			clk 	=> clk
		);	
		
	G_CONJ_FALSE: if use_conj = FALSE generate
	begin
		-------- WW conjugation --------
		DT_OB_IM_SUB: entity work.fp23_addsub_m2 
			port map(
				aa 		=> im_x_re, 
				bb 		=> re_x_im,
				cc 		=> bw.im,
				addsub	=> '1',
				reset 	=> reset,
				enable 	=> dval_en(0),	
				clk 	=> clk 	
			);	
			
		DT_OB_RE_ADD: entity work.fp23_addsub_m2 
			port map(
				aa 		=> re_x_re,
				bb 		=> im_x_im,
				cc 		=> bw.re, 	
				addsub	=> '0',
				reset 	=> reset,
				enable 	=> dval_en(0), 	
				valid 	=> dval_en(1), 	
				clk 	=> clk 	
			);	
	end generate; 
	
	G_CONJ_TRUE: if use_conj = TRUE generate
	begin
		-------- WW conjugation --------
		DT_OB_IM_ADD: entity work.fp23_addsub_m2 
			port map(
				aa 		=> im_x_re,
				bb 		=> re_x_im,
				cc 		=> bw.im,	
				reset 	=> reset,
				addsub	=> '0',
				enable 	=> dval_en(0),
				clk 	=> clk 	
			);	
			
		DT_OB_RE_SUB: entity work.fp23_addsub_m2 
			port map(
				aa 		=> re_x_re,
				bb 		=> im_x_im,
				cc 		=> bw.re, 	
				addsub	=> '1',
				reset 	=> reset,
				enable 	=> dval_en(0), 	
				valid 	=> dval_en(1),	
				clk 	=> clk 	
			);	
	end generate; 
	
	
	aw <= dt_ia_del(14);
	
end generate;

-------- DT_OA & DT_OB --------	
ADD_RE: entity work.fp23_addsub_m2 	
	port map(
		aa 		=> aw.re,
		bb 		=> bw.re,
		cc 		=> sum.re, 
		reset 	=> reset,
		addsub	=> '0',		
		enable 	=> dval_en(1), 	
		clk 	=> clk 	
	);
	
ADD_IM: entity work.fp23_addsub_m2
	port map(
		aa 		=> aw.im,
		bb 		=> bw.im,
		cc 		=> sum.im,
		reset 	=> reset,
		addsub	=> '0',		
		enable 	=> dval_en(1), 
		valid	=> dval_en(2), 	
		clk 	=> clk 	
	);	

SUB_RE: entity work.fp23_addsub_m2 	
	port map(
		aa 		=> aw.re,
		bb 		=> bw.re, 		
		cc 		=> dif.re, 
		reset 	=> reset,
		addsub	=> '1',		
		enable 	=> dval_en(1),
		clk 	=> clk 	
	);
	
SUB_IM: entity work.fp23_addsub_m2
	port map(
		aa 		=> aw.im,
		bb 		=> bw.im,
		cc 		=> dif.im,
		reset 	=> reset,
		addsub	=> '1',		
		enable 	=> dval_en(1), 	
		clk 	=> clk 	
	);
	
DT_OA <= sum;
DT_OB <= dif;
DO_VL <= dval_en(2);

end fp23_ibfly_inv;