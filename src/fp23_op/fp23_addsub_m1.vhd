-------------------------------------------------------------------------------
--
-- Title       : fp23_addsub_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : floating point adder/subtractor
--
-------------------------------------------------------------------------------
--
--	Version 1.0  19.02.2013
--			   	 Description: Common FP24 adder for FFT, 	
--								10 bits - exp, 1 bit - sign, 16 bis - frac
--
--	Version 1.1  26.08.2014
--			   	 Description: Data width has been changed from 27 to 24.
--					16 bits - fraction,
--					1 bit   - sign,
--					7 bits  - exponent
--
--					> 2 DSP48E1 blocks used;
--				
--	Version 1.2  08.10.2015 
--			   	 Description: Reduced DSP48E1 to 1. Barrel shifter is used.
--			
--					> 1 DSP48E1 blocks used;
--
--	Version 1.3  09.10.2015 
--			   	 Add and Sub in 1 component
--			
--	Version 1.4  14.10.2015 
--			   	 Description: Reduced DSP48E1 to 0. 2x Barrel shifter is used.
--			
--					> 0 DSP48E1 blocks used; 
--
--	Version 1.5  19.10.2015 
--			   	 FP24 -> FP23. Reduce 2 bits.
--					Total time delay is 14 clocks! 
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

library unisim;
use unisim.vcomponents.DSP48E1;

entity fp23_addsub_m1 is
	generic (
		td		: time:=1ns			--! Time delay for simulation
		--addsub	: string(3 downto 1):="add"	--! add/sub attribute
	);
	port(
		aa 		: in  fp23_data;	--! Summand/Minuend A   
		bb 		: in  fp23_data;	--! Summand/Substrahend B     
		cc 		: out fp23_data;	--! Sum/Dif C        
		addsub	: in  std_logic;	--! '0' - Add, '1' - Sub
		enable 	: in  std_logic;	--! Input data enable
		valid	: out std_logic;	--! Output data valid
		reset  	: in  std_logic;	--! Reset            
		clk 	: in  std_logic		--! Clock	         
	);
end fp23_addsub_m1;

architecture fp23_addsub_m1 of fp23_addsub_m1 is 

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

type std_logic_array_9x6 is array (7 downto 0) of std_logic_vector(5 downto 0);
type std_logic_array_5x16 is array (4 downto 0) of std_logic_vector(15 downto 0);

signal rstp				: std_logic; 

signal aa_z			   	: fp23_data;	  
signal bb_z				: fp23_data;
signal aatr				: std_logic_vector(21 downto 0);
signal bbtr				: std_logic_vector(21 downto 0); 

signal muxa             : fp23_data;
signal muxb             : fp23_data;
signal muxaz            : fp23_data;
signal muxbz            : std_logic_vector(15 downto 0);

signal exp_dif			: std_logic_vector(5 downto 0);

signal implied_a		: std_logic;
signal implied_b		: std_logic; 

signal man_az			: std_logic_vector(16 downto 0);
signal subtract         : std_logic_vector(2 downto 0);

signal sum_manz			: std_logic_array_5x16;

signal msb_dec			: std_logic_vector(31 downto 0);
signal msb_num			: std_logic_vector(4 downto 0);
signal msb_numn			: std_logic_vector(5 downto 0);

signal expc				: std_logic_vector(5 downto 0);
signal norm_c           : std_logic_vector(15 downto 0);
signal frac           	: std_logic_vector(15 downto 0);
signal expci			: std_logic_vector(5 downto 0);
signal expciz			: std_logic_vector(5 downto 0);
signal expcizz			: std_logic_vector(5 downto 0);
signal set_zero			: std_logic;

signal expaz			: std_logic_array_9x6;
signal exp_underflow	: std_logic;
signal exp_underflowz	: std_logic;
signal sign_c			: std_logic_vector(9 downto 0);

signal exch				: std_logic;
signal exchange			: std_logic; 
--signal sum_manx			: std_logic_vector(31 downto 0);
signal msb_numz			: std_logic_vector(4 downto 0);
signal msb_numzz		: std_logic_vector(4 downto 0);

signal dout_val_v		: std_logic_vector(12 downto 0);

signal man_shift		: std_logic_vector(16 downto 0);
signal norm_man			: std_logic_vector(16 downto 0);
signal diff_man			: std_logic_vector(16 downto 0);

signal diff_exp			: std_logic_vector(4 downto 0);
signal man_azz			: std_logic_vector(16 downto 0);
signal sum_co			: std_logic; 
signal ext_sum			: std_logic;

signal sum_mt			: std_logic_vector(16 downto 0);
signal addsign			: std_logic;

begin	
	
rstp <= not reset after td when rising_edge(clk); 

--x_addgen: if addsub = "add" generate
--	bb_z <= bb after td when rising_edge(clk);
--end generate;
--x_subgen: if addsub = "sub" generate
--	bb_z <= (bb(21 downto 16) & (not bb(15)) & bb(14 downto 0)) after td when rising_edge(clk);
--end generate;	 

-- add or sub operation --
aa_z <= aa after td when rising_edge(clk);
pr_addsub: process(clk) is
begin
	if rising_edge(clk) then
		if (addsub = '0') then
			bb_z <= bb after td;
		else
			bb_z <= (bb.exp, not bb.sig, bb.man) after td;
		end if;
	end if;
end process;

-- check difference (least/most attribute) --
aatr <= aa.exp & aa.man;
bbtr <= bb.exp & bb.man;

AB_SUB: sp_addsub_m1
	generic map(N => 22)
	port map(
		data_a 	=> aatr, 
		data_b 	=> bbtr, 
		--data_c 	=> , 		
		add_sub	=> '0', 				
		cin     => '1', 	
		cout    => exchange,	
		clk    	=> clk, 				
		ce 		=> enable, 								
		aclr  	=> rstp 				
	);
  
-- exchange data --	
pr_ex: process(clk) is
begin
	if rising_edge(clk) then
		if (rstp = '1') then
			exch <= '1' after td;
		else	
			exch <= exchange after td; 
		end if;
	end if;
end process;

-- data switch multiplexer --			
pr_mux: process(clk) is
begin
	if rising_edge(clk) then
		if (exch = '0') then
			muxa <= bb_z after td;
			muxb <= aa_z after td;
		else
			muxa <= aa_z after td;
			muxb <= bb_z after td;
		end if;
	end if;							   
end process;

muxaz <= muxa after td when rising_edge(clk);
muxbz <= muxb.man after td when rising_edge(clk);			

-- implied '1' for fraction --
pr_imp: process(clk) is
begin
	if rising_edge(clk) then
		if (muxa.exp = "000000") then
			implied_a <= '0' after td;
		else
			implied_a <= '1' after td;
		end if;
		
		if (muxb.exp = "000000") then	
			implied_b <= '0' after td;
		else
			implied_b <= '1' after td;
		end if;	
	end if;
end process;

-- find exponent --
EXP_SUB: sp_addsub_m1
	generic map(N => 6) 
	port map(
		data_a 	=> muxa.exp, 
		data_b 	=> muxb.exp, 
		data_c 	=> exp_dif, 		
		add_sub	=> '0', 				
		cin     => '1', 	
		--cout    => ,	
		clk    	=> clk, 				
		ce 		=> '1', 								
		aclr  	=> rstp 				
	);
	
diff_exp <= exp_dif(5 downto 1) after td when rising_edge(clk);

pr_del: process(clk) is
begin
	if rising_edge(clk) then
		man_az <= implied_a & muxaz.man after td;
		subtract(0) <= muxa.sig xor muxb.sig after td;
		subtract(1) <= subtract(0) after td;
		subtract(2) <= subtract(1) after td;
	end if;
end process;

man_shift <= implied_b & muxbz;	
norm_man <= STD_LOGIC_VECTOR(SHR(UNSIGNED(man_shift), UNSIGNED(exp_dif(3 downto 0)))) after td when rising_edge(clk);	

pr_norm_man: process(clk) is
begin
	if rising_edge(clk) then
		if (diff_exp(4 downto 3) = "00") then
			diff_man <= norm_man after td;
		else
			diff_man <= (others => '0') after td;
		end if;
	end if;
end process;

man_azz <= man_az after td when rising_edge(clk);
addsign <= not subtract(1) after td when rising_edge(clk); 

-- sum of fractions --
MAN_ADD: sp_addsub_m1
	generic map(N => 17) 
	port map(
		data_a 	=> man_azz, 
		data_b 	=> diff_man, 
		data_c 	=> sum_mt, 		
		add_sub	=> addsign, 				
		cin     => subtract(2), 	
		cout    => sum_co,	
		clk    	=> clk, 				
		ce 		=> '1', 								
		aclr  	=> rstp 				
	);
	
ext_sum <= (sum_co xor subtract(2)) after td when rising_edge(clk);	

msb_dec(31 downto 16) <= ext_sum & sum_mt(16 downto 2); -- ???
msb_dec(15 downto 0) <= x"0000";

msb_seeker: sp_msb_decoder_m2 
	port map(
	din 	=> msb_dec, 	
	din_en  => '1', 					
	clk 	=> clk, 					
	reset 	=> rstp, 					
	dout 	=> msb_num 			
	--dout_val=> 						
	);
	
msb_numn <= ("0" & not msb_num) after td when rising_edge(clk);
msb_numz <= msb_num(4 downto 0) after td when rising_edge(clk);
msb_numzz <= msb_numz after td when rising_edge(clk);
----------------------------------------

pr_manz: process(clk) is
begin
	if rising_edge(clk) then 
		sum_manz(0) <= sum_mt(16 downto 1); --sum_man(33 downto 16);
		xdel: for ii in 0 to 3 loop			
			sum_manz(ii+1) <= sum_manz(ii) after td;
		end loop;	
	end if;
end process;

--sum_manx(31 downto 16) <= sum_manz(4);
--sum_manx(15 downto 00) <= (others => '0');
----------------------------------------

-- second barrel shifter --
--norm_c <= sum_manx(31-conv_integer(msb_numn(3 downto 0)) downto 16-conv_integer(msb_numn(3 downto 0))) after td when rising_edge(clk); 
norm_c <= STD_LOGIC_VECTOR(SHL(UNSIGNED(sum_manz(4)), UNSIGNED(msb_numn(3 downto 0)))) after td when rising_edge(clk);	
frac <= norm_c after td when rising_edge(clk);

-- normalize MSB for exp --
NORM_SUB: sp_addsub_m1
	generic map(N => 6)
	port map(
		data_a 	=> expaz(7),  --expaz(8), --
		data_b 	=> msb_numn, 
		data_c 	=> expc, 		
		add_sub	=> '0', 
		cin     => '1', 
		cout    => exp_underflow ,	 
		clk    	=> clk, 
		ce 		=> '1',--dout_val_v(10),
		aclr  	=> rstp 
	);					 
  
-- exponent increment --	
EXP_INC: sp_addsub_m1
	generic map(N => 6)
	port map(
		data_a 	=> expc, 
		data_b 	=> "000000", 
		data_c 	=> expci, 		
		add_sub	=> '1', 
		cin     => '1', 
		--cout    =>  ,	 
		clk    	=> clk, 
		ce 		=> '1',--dout_val_v(11),
		aclr  	=> set_zero 
	); 
	
-- underflow flag for data --	
pr_und: process(clk) is 
begin
	if rising_edge(clk) then
		--if dout_val_v(10) = '1' then
			exp_underflowz <= exp_underflow;
		--end if;
	end if;
end process;
set_zero <= not ((msb_numzz(4) or msb_numzz(3) or msb_numzz(2) or msb_numzz(1) or msb_numzz(0)) and exp_underflowz);

-- exp & sign delay --
pr_expz: process(clk) is
begin
	if rising_edge(clk) then
		expaz(0) <= muxaz.exp after td;
		for ii in 0 to 6 loop
			expaz(ii+1) <= expaz(ii) after td;
		end loop;		
	end if;
end process;	

sign_c <= sign_c(8 downto 0) & muxaz.sig after td when rising_edge(clk);

-- data out and result --	
cc <= (expci, sign_c(9), frac) after td when rising_edge(clk);

dout_val_v <= dout_val_v(11 downto 0) & enable after td when rising_edge(clk);
valid <= dout_val_v(12) after td when rising_edge(clk);

end fp23_addsub_m1;