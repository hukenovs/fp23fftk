-------------------------------------------------------------------------------
--
-- Title       : rom_twiddle_m4
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP/INT twiddle factor with Taylor stages
--
-------------------------------------------------------------------------------
--
--	Version 1.0  22.05.2015
--			   	 Description: Twiddle factor (coeffs) in ROM/RAM for FFT/IFFT.
-- 	
--	Version 2.0  14.07.2015
--			   	 Description: Twiddle factor has the Taylor ROM calculation 
--								This math code uses several DSP48 slices and
--								fix RAMBs (3 for FP24 format).
--		 
--	Version 3.0  12.08.2016
--			   	 Description: You can choose INT of FP COE data for TWIDDLE.
-- 			 		 
--	Version 3.1  18.08.2016
--			   	 Description: You don't need to create ROM file for twiddle.
--								Trig func can be calculated with MATH package
--
--	Version 3.2  04.09.2016
--			   	 Description: Improved logic for twiddle factor and data delays
--								Only 1/4 part of sin period is used.
--
--	Version 3.3  06.09.2016
--			   	 Description: DATATYPE = 16 for integer twiddle factor,
--								DATATYPE = 23 for floating twiddle factor.
--	
--			Delay lines stages:
--				ST: 00 --> (Z = 1) --> (1 FD)
--				ST: 01 --> (Z = 1) --> (1 FD)
--				ST: 02 --> (Z = 3) --> (2 FD)
--				ST: 03 --> (Z = 3) --> (4 FD)
--				ST: 04 --> (Z = 3) --> (8 FD)
--				ST: 05 --> (Z = 3) --> (16 FD)
--				ST: 06 --> (Z = 3) --> (1/4 or 1/8 SLICEM or 32 FD)
--				ST: 07 --> (Z = 3) --> (1/4 SLICEM)
--				ST: 08 --> (Z = 3) --> (2/4 SLICEM)
--				ST: 09 --> (Z = 3) --> (1 SLICEM or 1 RAMBs) 
--				ST: 10 --> (Z = 3) --> (1 RAMBs) 
--				ST: 11 --> (Z = 3) --> (2 RAMBs)  
--				ST: 12 --> (Z = 3) --> (4 RAMBs)  
--				ST: 13 --> (Z = 3) --> (8 RAMBs)  
--				ST: 14 --> (Z = 3) --> (16 RAMBs)  
--				ST: 15 --> (Z = 3) --> (32 RAMBs)  
--				ST: 16 --> (Z = 3) --> (64 RAMBs)  
--				...
--
--			Delay lines Taylor (NFFT - 12 > STAGE):
--
--				ST: INT  COE --> (Z = 8) --> (2 RAMBs + 2/3 DSP48) 
--				ST: FP23 COE --> (Z = 25) --> (3 RAMBs + 4 DSP48) 
--
--			Note: fix2float operation takes 9 clocks (!!)
-- 
--	Version 4.0  11.02.2017
--			   	 Description: DATATYPE = 23 (ONLY) !
--			   	     SCALE = "TRUE" - MAX RAMBS
--			   	     SCALE = "FALSE" - USE TAYLOR SCHEME
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
use ieee.std_logic_1164.all;  
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

library work;
use work.fp_m1_pkg.int16_complex;
use work.fp_m1_pkg.fp23_complex;
use work.fp_m1_pkg.find_fp;


entity rom_twiddle_m4 is
	generic(
		TD			: time:=1ns;	--! Delay time
		NFFT		: integer:=11;	--! FFT lenght
		STAGE 		: integer:=0;	--! FFT stage		
		XSERIES		: string:="7SERIES"; --! FPGA family: for 6/7 series: "7SERIES"; for ULTRASCALE: "ULTRA";
		USE_SCALE	: boolean:=false --! use full scale rambs for twiddle factor or Taylor algotihm		
	);
	port(
		ww			: out fp23_complex; --! Twiddle factor
		clk 		: in std_logic;	--! Clock
		ww_ena 		: in std_logic;	--! Enable for coeffs
		reset  		: in std_logic	--! Reset
	);
end rom_twiddle_m4;

architecture rom_twiddle_m4 of rom_twiddle_m4 is 

constant Nww		: integer:=16;

signal dpo  		: std_logic_vector(31 downto 0);
signal ww_node		: std_logic_vector(31 downto 0);	

constant N_INV		: integer:=NFFT-stage-1;

function calc_string(xx : integer) return string is
begin 
	if (xx < 10) then -- 11 or 12
		return "distributed";
	else
		return "block";
	end if;
end calc_string;
constant ramb_str 	: string:=calc_string(N_INV);

attribute rom_style : string;
attribute rom_style of dpo : signal is ramb_str;

signal div 			: std_logic;
signal rstp			: std_logic;

signal ww_i	   		: fp23_complex;
signal ww_o	   		: fp23_complex;		

begin 
	
rstp <= not reset when rising_edge(clk); 

-- Output data in (INT to FP) format --
xFP_RE: entity work.fp23_fix2float_m1
	port map (
		din		=> ww_node(15 downto 00), 				
		ena		=> '1',	
		dout	=> ww_i.re,
		vld		=> open,
		clk		=> clk,          
		reset	=> reset           
	);
	
xFP_IM: entity work.fp23_fix2float_m1
	port map (
		din		=> ww_node(31 downto 16), 				
		ena		=> '1',	
		dout	=> ww_i.im,
		vld		=> open,
		clk		=> clk,          
		reset	=> reset           
	);
	
-- Twiddle Re/Im parts calculating --
pr_ww: process(clk) is
begin
	if rising_edge(clk) then
		if (div = '0') then
			ww_node <= dpo;
		else      
			ww_node(15 downto 00) <= dpo(31 downto 16);
			ww_node(31 downto 16) <= not dpo(15 downto 00); -- NEGATIVE!!
		end if;
	end if;
end process; 

-- Low part for Twiddle factor based on FD --
X_GEN_M0: if (N_INV < 2) generate	
	
	function rom_twiddle return std_logic_vector is
		variable sc_int : std_logic_vector(31 downto 00);
	begin
		sc_int(31 downto 16) := STD_LOGIC_VECTOR(CONV_SIGNED(INTEGER(32767.0*SIN(0.0)), 16));
		sc_int(15 downto 00) := STD_LOGIC_VECTOR(CONV_SIGNED(INTEGER(32767.0*COS(0.0)), 16));
		return sc_int;
	end rom_twiddle;	
	constant ww32x1K : std_logic_vector(31 downto 00):= rom_twiddle;
	
begin
	-- USE ONLY 1 FD for STORAGE DATA --
	X_GEN_NEG0: if (N_INV = 0) generate
		div <= '0'; 
	end generate;
	
	X_GEN_NEG1: if (N_INV = 1) generate	
		signal cnt : std_logic;	
	begin	
		pr_cnt: process(clk) is
		begin
			if rising_edge(clk) then
				if (rstp = '1') then
					cnt	<= '0';
				elsif (ww_ena = '1') then
					cnt <= not cnt;
				end if;
			end if;
		end process;	
		div <= cnt;
	end generate;
	
	dpo <= ww32x1K;	
	ww <= ww_i;
end generate;

-- High part for Twiddle factor based on SLICEM and RAMBs --
X_GEN_M12: if (N_INV >= 2) generate
	
	function ww_width(ii : integer; mode : boolean) return integer is
		variable value : integer:=0;
	begin
		if (mode = TRUE) then 
			value := N_INV;
		else
			if (ii < 12) then
				value := N_INV;
			else
				value := 11;
			end if;
		end if;
		return value;
	end ww_width;	 	
	constant WWID : integer := ww_width(N_INV, USE_SCALE);	

	type std_array_32xN is array (0 to 2**(WWID-1)-1) of std_logic_vector(31 downto 00); 
	
	function rom_twiddle(xx : integer) return std_array_32xN is
		variable pi_new : real:=0.0;
		variable sc_int : std_array_32xN;
		
		variable re_int : integer:=0;
		variable im_int : integer:=0;
	begin
		for ii in 0 to 2**(xx-1)-1 loop
			pi_new := (real(ii) * MATH_PI)/(2.0**xx);
			
			re_int := INTEGER(32768.0*COS(pi_new));	
			im_int := INTEGER(32768.0*SIN(-pi_new));
			
			-- Check overflow Amax
			if (re_int = 32768) then
				re_int := re_int-1;
			end if;			
			-- Check zero-value in 1'comp code 
			if (sc_int(ii)(31 downto 16) = x"8000") then
				sc_int(ii)(31 downto 16) := x"8001";
			end if;					
			
			sc_int(ii)(31 downto 16) := STD_LOGIC_VECTOR(CONV_SIGNED(im_int, 16));
			sc_int(ii)(15 downto 00) := STD_LOGIC_VECTOR(CONV_SIGNED(re_int, 16));	
		end loop;
		
		return sc_int;		
	end rom_twiddle;	
	
	constant ww32x1K : std_array_32xN:= rom_twiddle(WWID);
	
	signal half	: std_logic;
	signal cnt	: std_logic_vector(N_INV-1 downto 0);
	signal addr : std_logic_vector(N_INV-2 downto 0);
	
begin
	pr_cnt: process(clk) is
	begin
		if rising_edge(clk) then
			if (rstp = '1') then
				cnt	<=	(others	=>	'0');			
			elsif (ww_ena = '1') then
				cnt <= cnt + '1';
			end if;
		end if;
	end process;	

	addr <= cnt(N_INV-2 downto 0) when rising_edge(clk);
	half <= cnt(N_INV-1) when rising_edge(clk);		
	div  <= half when rising_edge(clk);	
	
	X_GEN_M1: if ((N_INV < 12) or (USE_SCALE = TRUE)) generate		
	begin
		dpo <= ww32x1K(conv_integer(unsigned(addr))) when rising_edge(clk);
		ww <= ww_i;
	end generate;		
		
	X_GEN_M2: if ((N_INV >= 12) and (USE_SCALE = FALSE)) generate	 	
		signal addrx		: std_logic_vector(9 downto 0);	
		signal ww_enaz 		: std_logic_vector(3 downto 0);
		signal count 		: std_logic_vector(N_INV-12 downto 0);
		
		type std_array_cnt is array (1 downto 0) of std_logic_vector(N_INV-12 downto 0); 
		signal cntzz 		: std_array_cnt;
	begin	
		addrx <= addr(N_INV-2 downto N_INV-11);	
		dpo <= ww32x1K(conv_integer(unsigned(addrx))) when rising_edge(clk);
		
		ww_enaz <= ww_enaz(2 downto 0) & ww_ena when rising_edge(clk);	
		count <= addr(N_INV-12 downto 0);
		
		cntzz <= cntzz(0 downto 0) & count when rising_edge(clk);	
		X_TAYLOR_COE: entity work.fp23_cnt2flt_m1
			generic map (
				XSERIES  	=> XSERIES,
				ii			=> N_INV-12
			)
			port map (
				rom_ww		=> ww_i,
				rom_en		=> ww_enaz(3),--ww_ena,--ww_ena,
				   
				dsp_ww		=> ww_o,			
				int_cnt		=> cntzz(1),	
				
				clk 		=> clk,
				rstn  		=> reset
			);	
			
			ww <= ww_o;	
--		G_TAYLOR_TRUE: if (USE_TAYLOR = TRUE) generate			
--		begin 			
--		end generate;
	end generate;	
	
--	G_TAYLOR_FALSE: if (USE_TAYLOR = FALSE) generate	
--		ww <= ww_i;
--	end generate;		
end generate;


end rom_twiddle_m4;