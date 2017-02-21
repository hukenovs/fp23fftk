-------------------------------------------------------------------------------
--
-- Title       : fp23_fix2float_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     : 
--
-------------------------------------------------------------------------------
--
-- Description : Signed fix 16 bit to float fp23 converter
--
-------------------------------------------------------------------------------
--
--	Version 1.0  25.05.2013
--			   	 Description:
--					Bus width for:
--					din = 15
--					dout = 23	
-- 					exp = 6
-- 					sign = 1
-- 					mant = 15 + 1
--				 Math expression: 
--					A = (-1)^sign(A) * 2^(exp(A)-31) * mant(A)
--				 NB:
--				 1's complement
--				 Converting from fixed to float takes only 9 clock cycles
--
--	MODES: 	Mode0	: normal fix2float (1's complement data)
--			Mode1	: +1 fix2float for negative data (uncomment and 
--					change this code a little: add a component 
-- 					sp_addsub_m1 and some signals): 2's complement data.
--	
--
--	Version 1.1  15.01.2015
--			   	 Description:
--					Based on fp27_fix2float_m3 (FP27 FORMAT)
--					New version of FP (Reduced fraction width)
--	
--	Version 1.2  18.03.2015
--			   	 Description:
--					Changed CE signal
--					This version has ena. See OR5+OR5 stages
--
--	Version 1.3  24.03.2015
--			   	 Description:
--					Deleted ENABLE signal
--					This version is fully pipelined !!!
--
--	Version 1.4  04.10.2015
--			   	 Description:
--					DSP48E1 has been removed. Barrel shift is used now.
--					Delay 9 clocks
--							 
--	Version 1.5  04.01.2016
--			   	 Description:
--					New barrel shifter with minimum resources. 
--					New FP format: FP24 -> FP23.
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fp_m1_pkg.fp23_data;

entity fp23_fix2float_m1 is
	generic(
		td			: time:=1ns	--! Time delay for simulation
		);
	port(
		din			: in  std_logic_vector(15 downto 0);	--! Fixed input data					
		ena			: in  std_logic;						--! Data enable 		
		dout		: out fp23_data;						--! Float output data
		vld			: out std_logic;						--! Data out valid      
		clk			: in  std_logic;						--! Clock            
		reset		: in  std_logic							--! Negative Reset            
	);
end fp23_fix2float_m1;

architecture fp23_fix2float_m1 of fp23_fix2float_m1 is 

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

component sp_msb_decoder_m2 is
	port(
		din 	: in  std_logic_vector(31 downto 0);
		din_en  : in  std_logic;
		clk 	: in  std_logic;
		reset 	: in  std_logic;
		dout 	: out std_logic_vector(4 downto 0)
	);
end component;

type std_logic_array_5x15 is array (4 downto 0) of std_logic_vector(14 downto 0);  

signal true_form		: std_logic_vector(15 downto 0):=(others => '0');	
signal rstp				: std_logic;

signal sum_man		    : std_logic_vector(31 downto 0);
signal sum_manz			: std_logic_array_5x15:=(others => (others => '0'));
signal msb_num			: std_logic_vector(4 downto 0);
signal msb_numn			: std_logic_vector(5 downto 0);

constant exp_in			: std_logic_vector(5 downto 0):="011110";-- x = 32 - exp!	
signal expc				: std_logic_vector(5 downto 0);
signal expci			: std_logic_vector(5 downto 0);	
signal norm_c           : std_logic_vector(14 downto 0);
signal frac           	: std_logic_vector(15 downto 0);	
signal exp_underflow	: std_logic;
signal exp_underflow_n	: std_logic;

signal sign_c			: std_logic_vector(6 downto 0);
signal valid			: std_logic_vector(7 downto 0);
--signal dinz			: std_logic_vector(15 downto 0);

begin

--dinz <= din after td when rising_edge(clk);

-- -- UNCOMMENT TO CHANGE FLOATING MODE DATA: 1s OR 2s COMPLEMENTED!
--din_conq <= not din(15);
--din15z	<= din(15) when rising_edge(clk);

--add_din: sp_addsub_m1	-- +1 for negative data
--	generic map(N => 15) 
--	port map(
--	data_a 	=> din,
--	data_b 	=> x"0000",  
--	data_c 	=> din_buf, 		
--	add_sub	=> '1',--din_conq,--'0', 
--	cin     => '0',--din(15), 
----	cout    => ,	 
--	clk    	=> clk, 
--	ce 		=> enable, --
--	aclr  	=> rstp 
--	);	
	
rstp <= not reset when rising_edge(clk);

---- make abs(data) by using XOR ----
pr_abs: process(clk) is
begin
	if rising_edge(clk) then
		if (ena = '1') then	
			true_form(15) <= din(15) after td;	--din15z;	--din(15);
			for ii in 0 to 14 loop
				true_form(ii) <= din(ii) xor din(15) after td;	--din_buf(ii) xor din_buf(15);
			end loop;
		end if;	
	end if;
end process;	

sum_man(31 downto 31) <= "0";
sum_man(30 downto 16) <= true_form(14 downto 0);
sum_man(15 downto 00) <= (others => '0');

---- find MSB (highest '1' position) ----
MSB_SEEKER: sp_msb_decoder_m2 
port map(
	din 	=> sum_man(31 downto 0), 	
	din_en  => '1', 					
	clk 	=> clk, 					
	reset 	=> rstp, 					
	dout 	=> msb_num 			 						
); 	

msb_numn <= "0" & (not msb_num) after td when rising_edge(clk);

---- fraction delay ----
pr_man: process(clk) begin
	if rising_edge(clk) then 
		sum_manz(0) <= true_form(14 downto 0) after td; 
		for ii in 0 to 3 loop			
			sum_manz(ii+1) <= sum_manz(ii) after td;
		end loop;
	end if;
end process; 

---- barrel shifter by 0-15 ----
norm_c <= STD_LOGIC_VECTOR(SHL(UNSIGNED(sum_manz(4)), UNSIGNED(msb_numn(3 downto 0)))) after td when rising_edge(clk);
frac <= norm_c & '0' after td when rising_edge(clk);

---- find exponent (inv msb - 32) ---- 
NORM_SUB: sp_addsub_m1
	generic map(N => 6) 
	port map(
		data_a 	=> exp_in,
		data_b 	=> msb_numn,  
		data_c 	=> expc, 		
		add_sub	=> '0', 
		cin     => '1', 
		cout    => exp_underflow,	 
		clk    	=> clk, 
		ce 		=> '1',--valid(5),
		aclr  	=> rstp 
	);					 
exp_underflow_n <= not exp_underflow after td when rising_edge(clk); 

---- exponent increment (+1) ---- 
EXP_INC: sp_addsub_m1
	generic map(N => 6)
	port map(
		data_a 	=> expc, 
		data_b 	=> "000000", 
		data_c 	=> expci, 		
		add_sub	=> '1', 
		cin     => '1',--true_form(15), 
		--cout    =>  ,	 
		clk    	=> clk, 
		ce 		=> '1',--valid(6),
		aclr  	=> exp_underflow_n--set_zero 
	); 																								

---- sign delay ----
sign_c <= sign_c(5 downto 0) & true_form(15) after td when rising_edge(clk);--sign_c <= (others => '0');		   

---- output data ---- 
pr_out: process(clk) is 
begin
	if rising_edge(clk) then
		if (rstp = '1') then
			dout <= ("000000", '0', x"0000") after td;
		elsif (valid(7) = '1') then
			dout <= (expci, sign_c(6), frac) after td;
		end if;
	end if;
end process; 

valid <= valid(6 downto 0) & ena after td when rising_edge(clk);	
vld <= valid(7) after td when rising_edge(clk);--valid(8); -- 8 clock corresponds actual data (+1 for mode 1)		

end fp23_fix2float_m1;