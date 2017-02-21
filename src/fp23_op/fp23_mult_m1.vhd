--------------------------------------------------------------------------------
--
-- Title       : fp23_mult_m1
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
--use unisim.vcomponents.DSP48E2;
	
library work;
use work.reduce_pack.all;
use work.fp_m1_pkg.fp23_data;

entity fp23_mult_m1 is
	generic(
		XSERIES : string:="7SERIES"; --! Xilinx series
		td		: time:=1ns	--! Time delay for simulation
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
end fp23_mult_m1;

architecture fp23_mult_m1 of fp23_mult_m1 is 

component sp_addsub_m1 is
	generic(	
		N 		: integer
	);
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
end component;

type std_logic_array_4x6 is array(3 downto 0) of std_logic_vector(5 downto 0);

signal rstp				: std_logic;   
signal man_aa			: std_logic_vector(29 downto 0);
signal man_bb			: std_logic_vector(17 downto 0);
               		
signal exp_cc 			: std_logic_vector(5 downto 0);
signal exp_ccz			: std_logic_vector(5 downto 0);
signal exp_cczz			: std_logic_vector(5 downto 0);
signal exp_dec  		: std_logic_vector(5 downto 0);

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
--signal overflow			: std_logic;

begin
	
rstp <= not reset after td when rising_edge(clk); 	

-- finding zero exponents for multipliers
expa_or <= or_reduce(aa.exp) after td when rising_edge(clk);
expb_or <= or_reduce(bb.exp) after td when rising_edge(clk);
exp_zero <= (expa_or and expb_or) after td when rising_edge(clk);
exp_zeroz <= exp_zero after td when rising_edge(clk);-- and enaz(1) = '1';

-- form overflow via exponents:
--overflow <= expa_or(22) or expb_or(22) after td when rising_edge(clk);

-- forming fractions for mulptiplier
man_aa(29 downto 18) <= x"000";
man_aa(17 downto 0) <= "01" & aa.man;	
man_bb <= "01" & bb.man;

x7SERIES: if (XSERIES = "7SERIES") generate
	NORMALIZE: DSP48E1 --   +/-(A*B+Cin)   -- for Virtex-6 and 7 families
		generic map (
			-- Feature Control Attributes: Data Path Selection
			A_INPUT 			=> "DIRECT",           
			B_INPUT 			=> "DIRECT",           
			USE_DPORT 			=> FALSE,              
			USE_MULT 			=> "MULTIPLY",         
			USE_SIMD 			=> "ONE48",            
			-- Pattern Detector Attributes: Pattern Detection Configuration
			AUTORESET_PATDET 	=> "NO_RESET",    	
			MASK 				=> X"3fffffffffff", 
			PATTERN 			=> X"000000000000", 
			SEL_MASK 			=> "MASK",          
			SEL_PATTERN 		=> "PATTERN",       
			USE_PATTERN_DETECT 	=> "NO_PATDET", 	
			-- Register Control Attributes: Pipeline Register Configuration
			ACASCREG 			=> 1,
			ADREG 				=> 0,
			ALUMODEREG 			=> 1,
			AREG 				=> 1,
			BCASCREG 			=> 1,
			BREG 				=> 1,
			CARRYINREG 			=> 1,
			CARRYINSELREG 		=> 1,
			CREG 				=> 1,
			DREG 				=> 0,
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
			CEAD 				=> '1',    
			CEALUMODE 			=> '1',           
			CEB1 				=> enable,                     
			CEB2 				=> '1',                     
			CEC 				=> '1',                       
			CECARRYIN 			=> '1',         
			CECTRL 				=> '1',            
			CED 				=> '1',               
			CEINMODE 			=> '1',          
			CEM 				=> '1',--enaz(0),                       
			CEP 				=> '1',--enaz(1),                       
			RSTA				=> rstp,           
			RSTALLCARRYIN 		=> rstp,  
			RSTALUMODE 			=> rstp,     
			RSTB 				=> rstp,           
			RSTC 				=> rstp,           
			RSTCTRL 			=> rstp,        
			RSTD 				=> rstp,           
			RSTINMODE 			=> rstp,      
			RSTM 				=> rstp,           
			RSTP 				=> rstp            
		);
end generate;

--xULTRA: if (XSERIES = "ULTRA") generate
--	NORMALIZE : DSP48E2
--		generic map (
--			-- Feature Control Attributes: Data Path Selection
--			AMULTSEL 			=> "A",             
--			A_INPUT 			=> "DIRECT",        
--			BMULTSEL 			=> "B",             
--			B_INPUT 			=> "DIRECT",        
--			PREADDINSEL 		=> "A",             
--			RND 				=> X"000000000000", 
--			USE_MULT 			=> "MULTIPLY",      
--			USE_SIMD 			=> "ONE48",         
--			USE_WIDEXOR 		=> "FALSE",         
--			XORSIMD 			=> "XOR24_48_96",   
--			-- Pattern Detector Attributes: Pattern Detection Configuration
--			AUTORESET_PATDET 	=> "NO_RESET", 
--			AUTORESET_PRIORITY 	=> "RESET",    
--			MASK 				=> X"3fffffffffff",           
--			PATTERN 			=> X"000000000000",        
--			SEL_MASK 			=> "MASK",                
--			SEL_PATTERN 		=> "PATTERN",          
--			USE_PATTERN_DETECT 	=> "NO_PATDET", 
--			-- Register Control Attributes: Pipeline Register Configuration
--			ACASCREG 			=> 1,
--			ADREG 				=> 0,
--			ALUMODEREG 			=> 1,
--			AREG 				=> 1,
--			BCASCREG 			=> 1,
--			BREG 				=> 1,
--			CARRYINREG 			=> 1,
--			CARRYINSELREG 		=> 1,
--			CREG 				=> 1,
--			DREG 				=> 0,
--			INMODEREG 			=> 1,
--			MREG 				=> 1,
--			OPMODEREG 			=> 1,
--			PREG 				=> 1 
--		)
--		port map (
--			-- Cascade: 30-bit (each) output: Cascade Ports
--			ACOUT 				=> open,    
--			BCOUT 				=> open,    
--			CARRYCASCOUT 		=> open,    
--			MULTSIGNOUT 		=> open,    
--			PCOUT 				=> open,   
--			-- Control: 1-bit (each) output: Control Inputs/Status Bits
--			OVERFLOW 			=> open,
--			PATTERNBDETECT 		=> open,
--			PATTERNDETECT 		=> open,
--			UNDERFLOW 			=> open,
--			-- Data: 4-bit (each) output: Data Ports
--			CARRYOUT 			=> open,
--			P 					=> prod,
--			XOROUT 				=> open,
--			-- Cascade: 30-bit (each) input: Cascade Ports
--			ACIN 				=> (others=>'0'),
--			BCIN 				=> (others=>'0'),
--			CARRYCASCIN 		=> '0',    
--			MULTSIGNIN 			=> '0',    
--			PCIN 				=> (others=>'0'),              
--			-- Control: 4-bit (each) input: Control Inputs/Status Bits
--			ALUMODE 			=> (others=>'0'),
--			CARRYINSEL 			=> (others=>'0'),
--			CLK 				=> clk, 
--			INMODE 				=> (others=>'0'),
--			OPMODE 				=> "0000101", 
--			-- Data inputs: Data Ports
--			A 					=> man_aa,    
--			B 					=> man_bb,    
--			C 					=> (others=>'0'),         
--			CARRYIN 			=> '0',
--			D 					=> (others=>'0'),
--			-- Reset/Clock Enable inputs: Reset/Clock Enable Inputs
--			CEA1 				=> enable, 
--			CEA2 				=> '1',    
--			CEAD 				=> '1',    
--			CEALUMODE 			=> '1',           
--			CEB1 				=> enable,                     
--			CEB2 				=> '1',                     
--			CEC 				=> '1',                       
--			CECARRYIN 			=> '1',         
--			CECTRL 				=> '1',            
--			CED 				=> '1',               
--			CEINMODE 			=> '1',          
--			CEM 				=> '1',--enaz(0),                       
--			CEP 				=> '1',--enaz(1),                       
--			RSTA				=> rstp,           
--			RSTALLCARRYIN 		=> rstp,  
--			RSTALUMODE 			=> rstp,     
--			RSTB 				=> rstp,           
--			RSTC 				=> rstp,           
--			RSTCTRL 			=> rstp,        
--			RSTD 				=> rstp,           
--			RSTINMODE 			=> rstp,      
--			RSTM 				=> rstp,           
--			RSTP 				=> rstp   
--	   );
--end generate;		

-- exp difference --	
EXP_SUB: sp_addsub_m1
	generic map(N => 6)
	port map(
		data_a 	=> aa.exp, 
		data_b 	=> bb.exp, 
		data_c 	=> exp_cc, 		
		add_sub	=> '1', 				
		cin     => '0', 	
		--cout    => ,	
		clk    	=> clk, 				
		ce 		=> enable, 								
		aclr  	=> rstp 				
	);								  	
exp_ccz <= exp_cc after td when rising_edge(clk);
exp_cczz <= exp_ccz after td when rising_edge(clk);

EXP_DIFF: sp_addsub_m1 	-- "0001111" = FOR NORMAL MULTIPLICATION,  "0011111", = FOR FFT
	generic map(N => 6)
	port map(
		data_a 	=> exp_cczz, --exp_cc, 
		data_b 	=> "011110", --"0100000", -- 
		data_c 	=> exp_dec, 		
		add_sub	=> '0', 				
		cin     => prod(33),--'0',	
		cout    => exp_underflow,	
		clk    	=> clk, 				
		ce 		=> '1',--enaz(2),-- 				 				
		aclr  	=> rstp 				
	);
 
-- find sign as xor of signs --		
pr_sign: process(clk) is
begin
	if rising_edge(clk) then
		if (enable = '1') then
			sig_cc <= aa.sig xor bb.sig after td;
		end if;
		sig_ccz <= sig_ccz(1 downto 0) & sig_cc after td;
	end if;
end process; 

-- find fraction --	
pr_frac: process(clk) is
begin
	if rising_edge(clk) then
		if (prod(33) = '0') then
			man_cc <= prod(31 downto 16) after td;
		else
			man_cc <= prod(32 downto 17) after td;
		end if;
	end if;
end process;

-- data out and result --	
--exp_underflowz <= (exp_underflow and exp_zeroz) after td when rising_edge(clk);
exp_underflowz <= (exp_zeroz) after td when rising_edge(clk);

pr_dout: process(clk) is
begin 		
	if rising_edge(clk) then
		if (rstp = '1') then
			cc <= ("000000", '0', x"0000") after td;		
		else
			if (enaz(3) = '1') then
				if (exp_underflowz = '0') then
					cc <= ("000000", '0', x"0000") after td;
				else
					cc <= (exp_dec, sig_ccz(2), man_cc) after td;
				end if;
			end if;
		end if;
	end if;
end process;	

enaz <= enaz(2 downto 0) & enable after td when rising_edge(clk);
valid <= enaz(3) after td when rising_edge(clk);

end fp23_mult_m1;
