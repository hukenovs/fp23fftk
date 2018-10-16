--------------------------------------------------------------------------------
--
-- Title       : fp23_mult
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : floating point multiplier
--
-------------------------------------------------------------------------------
--
--	Version 1.0  22.02.2013
--			   	 Description:
--				  Multiplier for FP - 2DSP48E1 slices
--				  4 clock cycles delay
--
--
--	Version 1.2  15.01.2014
--			   	 Description:
--				  5 clock cycles delay, improved logic	
--	
--	Version 1.3  24.03.2015
--			   	 Description:
--					Deleted din_en signal
--					This version is fully pipelined with 1 DSP48E1!
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
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.DSP48E1;	
use unisim.vcomponents.DSP48E2;
	
library work;
use work.reduce_pack.all;
use work.fp_m1_pkg.fp23_data;

entity fp23_mult is
	generic(
		EXP_DIF	: std_logic_vector(5 downto 0):="011111"; -- DIFF_EXP
		XSERIES : string:="7SERIES" --! Xilinx series
	);
	port(
		aa 		: in  fp23_data;	--! Multiplicand A
		bb 		: in  fp23_data;	--! Multiplier B
		cc 		: out fp23_data;	--! Product C
		enable 	: in  std_logic;	--! Input data enable
		valid	: out std_logic;	--! Output data valid
		reset  	: in  std_logic;	--! Reset
		clk 	: in  std_logic		--! Clock	
	);	
end fp23_mult;

architecture fp23_mult of fp23_mult is 

type std_logic_array_4x6 is array(3 downto 0) of std_logic_vector(5 downto 0);
 
signal man_aa			: std_logic_vector(29 downto 0);
signal man_bb			: std_logic_vector(17 downto 0);

type std_logic_array_2x5 is array(1 downto 0) of std_logic_vector(5 downto 0);
signal exp_az 			: std_logic_array_2x5;
signal exp_bz			: std_logic_array_2x5;	

signal exp_cc 			: std_logic_vector(5 downto 0);
signal exp_df 			: std_logic_vector(6 downto 0);

signal sig_cc 			: std_logic;
signal man_cc			: std_logic_vector(15 downto 0);
signal prod				: std_logic_vector(47 downto 0);

signal sig_ccz			: std_logic_vector(2 downto 0);

signal exp_underflow	: std_logic;
signal exp_underflowz	: std_logic;
---------------------------------------
signal expa_or			: std_logic;
signal expb_or			: std_logic;

signal exp_zero 		: std_logic;
signal exp_zeroz		: std_logic;

signal enaz				: std_logic_vector(3 downto 0); 

begin

---- finding zero exponents for multipliers ----
expa_or <= or_reduce(aa.exp) when rising_edge(clk);
expb_or <= or_reduce(bb.exp) when rising_edge(clk);
exp_zero <= (expa_or and expb_or) when rising_edge(clk);
exp_zeroz <= exp_zero when rising_edge(clk);

-- forming fractions for mulptiplier
man_aa(29 downto 18) <= x"000";
man_aa(17 downto 0) <= "01" & aa.man;
man_bb <= "01" & bb.man;

x7SERIES: if (XSERIES = "7SERIES") generate
	NORMALIZE: DSP48E1
		generic map (
			-- Feature Control Attributes: Data Path Selection
			A_INPUT 			=> "DIRECT",
			B_INPUT 			=> "DIRECT",
			USE_DPORT 			=> FALSE,
			USE_MULT 			=> "MULTIPLY",
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 			=> 1,
			ADREG 				=> 1,
			ALUMODEREG 			=> 1,
			AREG 				=> 1,
			BCASCREG 			=> 1,
			BREG 				=> 1,
			CARRYINREG 			=> 1,
			CARRYINSELREG 		=> 1,
			CREG 				=> 1,
			DREG 				=> 1,
			INMODEREG 			=> 1,
			MREG 				=> 1,
			OPMODEREG 			=> 1,
			PREG 				=> 1 
		)
		port map (
			-- Cascade: 30-bit (each) output: Cascade Ports
			ACOUT 				=> open,
			BCOUT 				=> open,
			CARRYCASCOUT 		=> open,
			MULTSIGNOUT 		=> open,
			PCOUT 				=> open,
			-- Control: 1-bit (each) output: Control Inputs/Status Bits
			OVERFLOW 			=> open,
			PATTERNBDETECT 		=> open,
			PATTERNDETECT 		=> open,
			UNDERFLOW 			=> open,
			-- Data: 4-bit (each) output: Data Ports
			CARRYOUT 			=> open,
			P 					=> prod,
			-- Cascade: 30-bit (each) input: Cascade Ports
			ACIN 				=> (others=>'0'),
			BCIN 				=> (others=>'0'),
			CARRYCASCIN 		=> '0',
			MULTSIGNIN 			=> '0',
			PCIN 				=> (others=>'0'),
			-- Control: 4-bit (each) input: Control Inputs/Status Bits
			ALUMODE 			=> (others=>'0'),
			CARRYINSEL 			=> (others=>'0'),
			CLK 				=> clk, 
			INMODE 				=> (others=>'0'),
			OPMODE 				=> "0000101", 
			-- Data: 30-bit (each) input: Data Ports
			A 					=> man_aa,
			B 					=> man_bb,
			C 					=> (others=>'0'),
			CARRYIN 			=> '0',
			D 					=> (others=>'0'),
			-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
			CEA1 				=> enable, 
			CEA2 				=> '1',
			CEAD 				=> '0',
			CEALUMODE 			=> '1',
			CEB1 				=> enable,
			CEB2 				=> '1',
			CEC 				=> '1',
			CECARRYIN 			=> '1',
			CECTRL 				=> '1',
			CED 				=> '1',
			CEINMODE 			=> '1',
			CEM 				=> '1',
			CEP 				=> '1',
			RSTA				=> reset,
			RSTALLCARRYIN 		=> reset,
			RSTALUMODE 			=> reset,
			RSTB 				=> reset,
			RSTC 				=> reset,
			RSTCTRL 			=> reset,
			RSTD 				=> reset, 
			RSTINMODE 			=> reset,
			RSTM 				=> reset,
			RSTP 				=> reset 
		);
end generate;

xULTRA: if (XSERIES = "ULTRA") generate
	NORMALIZE : DSP48E2
		generic map (
			-- Feature Control Attributes: Data Path Selection
			AMULTSEL 			=> "A",
			A_INPUT 			=> "DIRECT",
			BMULTSEL 			=> "B",
			B_INPUT 			=> "DIRECT",
			PREADDINSEL 		=> "A",
			USE_MULT 			=> "MULTIPLY",
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 			=> 1,
			ADREG 				=> 1,
			ALUMODEREG 			=> 1,
			AREG 				=> 1,
			BCASCREG 			=> 1,
			BREG 				=> 1,
			CARRYINREG 			=> 1,
			CARRYINSELREG 		=> 1,
			CREG 				=> 1,
			DREG 				=> 1,
			INMODEREG 			=> 1,
			MREG 				=> 1,
			OPMODEREG 			=> 1,
			PREG 				=> 1 
		)
		port map (
			-- Cascade: 30-bit (each) output: Cascade Ports
			ACOUT 				=> open,
			BCOUT 				=> open,
			CARRYCASCOUT 		=> open,
			MULTSIGNOUT 		=> open,
			PCOUT 				=> open,
			-- Control: 1-bit (each) output: Control Inputs/Status Bits
			OVERFLOW 			=> open,
			PATTERNBDETECT 		=> open,
			PATTERNDETECT 		=> open,
			UNDERFLOW 			=> open,
			-- Data: 4-bit (each) output: Data Ports
			CARRYOUT 			=> open,
			P 					=> prod,
			XOROUT 				=> open,
			-- Cascade: 30-bit (each) input: Cascade Ports
			ACIN 				=> (others=>'0'),
			BCIN 				=> (others=>'0'),
			CARRYCASCIN 		=> '0',
			MULTSIGNIN 			=> '0',
			PCIN 				=> (others=>'0'),
			-- Control: 4-bit (each) input: Control Inputs/Status Bits
			ALUMODE 			=> (others=>'0'),
			CARRYINSEL 			=> (others=>'0'),
			CLK 				=> clk, 
			INMODE 				=> (others=>'0'),
			OPMODE 				=> "000000101", 
			-- Data inputs: Data Ports
			A 					=> man_aa,
			B 					=> man_bb,
			C 					=> (others=>'0'),
			CARRYIN 			=> '0',
			D 					=> (others=>'0'),
			-- Reset/Clock Enable inputs: Reset/Clock Enable Inputs
			CEA1 				=> enable,
			CEA2 				=> '1',
			CEAD 				=> '0',
			CEALUMODE 			=> '1',
			CEB1 				=> enable,
			CEB2 				=> '1',
			CEC 				=> '1',
			CECARRYIN 			=> '1',
			CECTRL 				=> '1',
			CED 				=> '1',
			CEINMODE 			=> '1',
			CEM 				=> '1',
			CEP 				=> '1',
			RSTA				=> reset,
			RSTALLCARRYIN 		=> reset,
			RSTALUMODE 			=> reset,
			RSTB 				=> reset,
			RSTC 				=> reset,
			RSTCTRL 			=> reset,
			RSTD 				=> reset, 
			RSTINMODE 			=> reset,
			RSTM 				=> reset,
			RSTP 				=> reset 
	   );
end generate;		

---- exp difference ----	
pr_exp: process(clk) is
begin
	if rising_edge(clk) then
		exp_az <= exp_az(0) & aa.exp; 
		exp_bz <= exp_bz(0) & bb.exp; 	
		exp_df <= ('0' & exp_az(1)) + ('0' & exp_bz(1)) - ('0' & EXP_DIF);
		
		if (exp_df(exp_df'left) = '0') then
			exp_cc <= exp_df(exp_df'left-1 downto 0) + prod(33);
		else
			exp_cc <= (others=>'0');
		end if;
	end if;
end process;

 
-- find sign as xor of signs --
pr_sign: process(clk) is
begin
	if rising_edge(clk) then
		sig_cc <= aa.sig xor bb.sig;
		sig_ccz <= sig_ccz(1 downto 0) & sig_cc;
	end if;
end process; 

-- find fraction --	
pr_frac: process(clk) is
begin
	if rising_edge(clk) then
		if (prod(33) = '0') then
			man_cc <= prod(31 downto 16);
		else
			man_cc <= prod(32 downto 17);
		end if;
	end if;
end process;

-- data out and result --	
--exp_underflowz <= (exp_underflow and exp_zeroz) when rising_edge(clk);
exp_underflowz <= (exp_zeroz) when rising_edge(clk);

pr_dout: process(clk) is
begin 		
	if rising_edge(clk) then
		if (exp_underflowz = '0') then
			cc <= ("000000", '0', x"0000");
		else
			cc <= (exp_cc, sig_ccz(2), man_cc);
		end if;
	end if;
end process;	

enaz <= enaz(2 downto 0) & enable when rising_edge(clk);
valid <= enaz(3) when rising_edge(clk);

end fp23_mult;
