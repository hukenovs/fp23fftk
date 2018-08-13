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
--	Version 1.6  01.11.2017 
--			   	 Remove old UNISIM logic for 6/7 series. Works w/ Ultrascale.
--					Reduce total delay on 4 clocks. (-4 taps).
--					Total time delay is 10 clocks! 
--
--	Version 1.7  21.02.2018 
--			   	 Fixed subnormal zeros calculation.
--
--	Version 1.8  24.02.2018 
--			   	 Added: SET_ZERO: when Exponent shifting = b'11111;
--						SET_ONES: when Exp(A) < Exp shifting (exp out = 0x01)
--						EXP_NORM: when Exp(A) >= Exp shifting (normal op)
--
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

entity fp23_addsub_m1 is
	port(
		aa 		: in  fp23_data;	--! Summand/Minuend A   
		bb 		: in  fp23_data;	--! Summand/Substrahend B     
		cc 		: out fp23_data;	--! Sum/Dif C        
		addsub	: in  std_logic;	--! '0' - Add, '1' - Sub
		reset	: in  std_logic;	--! '0' - Reset
		enable 	: in  std_logic;	--! Input data enable
		valid	: out std_logic;	--! Output data valid          
		clk 	: in  std_logic		--! Clock	         
	);
end fp23_addsub_m1;

architecture fp23_addsub_m1 of fp23_addsub_m1 is 

type std_logic_array_4x6 is array (4 downto 0) of std_logic_vector(5 downto 0);

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

signal sum_manz			: std_logic_vector(15 downto 0);
signal sum_mant			: std_logic_vector(15 downto 0);

signal msb_dec			: std_logic_vector(15 downto 0);
signal msb_num			: std_logic_vector(4 downto 0);
signal msb_numn			: std_logic_vector(5 downto 0);

signal expc				: std_logic_vector(5 downto 0);
signal norm_c           : std_logic_vector(15 downto 0);
signal frac           	: std_logic_vector(15 downto 0);

signal set_zero			: std_logic;
signal set_ones			: std_logic;

signal expaz			: std_logic_array_4x6;
signal sign_c			: std_logic_vector(5 downto 0);

signal exch				: std_logic;

signal dout_val_v		: std_logic_vector(8 downto 0);

signal man_shift		: std_logic_vector(16 downto 0);
signal norm_man			: std_logic_vector(16 downto 0);
signal diff_man			: std_logic_vector(16 downto 0);

signal diff_exp			: std_logic_vector(4 downto 0);
signal man_azz			: std_logic_vector(16 downto 0);

signal sum_mt			: std_logic_vector(17 downto 0);
signal addsign			: std_logic;

signal rstp				: std_logic;

signal exp_a0			: std_logic;
signal exp_b0			: std_logic;
signal exp_ab			: std_logic;
signal exp_zz			: std_logic_vector(6 downto 0);

begin	
	
rstp <= not reset when rising_edge(clk); 	

-- add or sub operation --
aa_z <= aa when rising_edge(clk);
pr_addsub: process(clk) is
begin
	if rising_edge(clk) then
		if (addsub = '0') then
			bb_z <= bb;
		else
			bb_z <= (bb.exp, not bb.sig, bb.man);
		end if;
	end if;
end process;

exp_a0 <= (aa.exp(0) or aa.exp(1) or aa.exp(2) or aa.exp(3) or aa.exp(4) or aa.exp(5)) when rising_edge(clk) and enable = '1';
exp_b0 <= (bb.exp(0) or bb.exp(1) or bb.exp(2) or bb.exp(3) or bb.exp(4) or bb.exp(5)) when rising_edge(clk) and enable = '1';

exp_ab <= not (exp_a0 or exp_b0) when rising_edge(clk);
-- exp_ab <= '0';
exp_zz <= exp_zz(exp_zz'left-1 downto 0) & exp_ab when rising_edge(clk);

-- check difference (least/most attribute) --
aatr <= aa.exp & aa.man;
bbtr <= bb.exp & bb.man;

pr_ex: process(clk) is
begin
	if rising_edge(clk) then
		if (aatr < bbtr) then
			exch <= '0';
		else
			exch <= '1';
		end if;
	end if;
end process; 

-- data switch multiplexer --			
pr_mux: process(clk) is
begin
	if rising_edge(clk) then
		if (exch = '0') then
			muxa <= bb_z;
			muxb <= aa_z;
		else
			muxa <= aa_z;
			muxb <= bb_z;
		end if;
		muxaz <= muxa; 
		muxbz <= muxb.man;			
	end if;							   
end process;

-- implied '1' for fraction --
pr_imp: process(clk) is
begin
	if rising_edge(clk) then
		if (muxa.exp = "000000") then
			implied_a <= '0';
		else
			implied_a <= '1';
		end if;
		
		if (muxb.exp = "000000") then	
			implied_b <= '0';
		else
			implied_b <= '1';
		end if;	
	end if;
end process;

-- find exponent --
exp_dif <= muxa.exp - muxb.exp when rising_edge(clk);
diff_exp <= exp_dif(5 downto 1) when rising_edge(clk);

pr_del: process(clk) is
begin
	if rising_edge(clk) then
		man_az <= implied_a & muxaz.man;
		subtract(0) <= muxa.sig xor muxb.sig;
		subtract(1) <= subtract(0);
		subtract(2) <= subtract(1);
	end if;
end process;

man_shift <= implied_b & muxbz;	
norm_man <= STD_LOGIC_VECTOR(SHR(UNSIGNED(man_shift), UNSIGNED(exp_dif(3 downto 0)))) when rising_edge(clk);	

pr_norm_man: process(clk) is
begin
	if rising_edge(clk) then
		if (diff_exp(4 downto 3) = "00") then
			diff_man <= norm_man;
		else
			diff_man <= (others => '0');
		end if;
	end if;
end process;

man_azz <= man_az when rising_edge(clk);
addsign <= not subtract(1) when rising_edge(clk); 


-- sum of fractions --
pr_man: process(clk) is
begin
	if rising_edge(clk) then
		if (addsign = '1') then
			sum_mt <= ('0' & man_azz) + ('0' & diff_man);
		else
			sum_mt <= ('0' & man_azz) - ('0' & diff_man);
		end if;
	end if;
end process;

msb_dec <= sum_mt(17 downto 2);

---- find MSB (highest '1' position) ----
pr_leadms: process(clk) is
begin 
	if rising_edge(clk) then 
		if    (msb_dec(15-00)='1') then msb_num <= "00000";-- "11111";
		elsif (msb_dec(15-01)='1') then msb_num <= "00001";-- "11110";
		elsif (msb_dec(15-02)='1') then msb_num <= "00010";-- "11101";
		elsif (msb_dec(15-03)='1') then msb_num <= "00011";-- "11100";
		elsif (msb_dec(15-04)='1') then msb_num <= "00100";-- "11011";
		elsif (msb_dec(15-05)='1') then msb_num <= "00101";-- "11010";
		elsif (msb_dec(15-06)='1') then msb_num <= "00110";-- "11001";
		elsif (msb_dec(15-07)='1') then msb_num <= "00111";-- "11000";
		elsif (msb_dec(15-08)='1') then msb_num <= "01000";-- "10111";
		elsif (msb_dec(15-09)='1') then msb_num <= "01001";-- "10110";
		elsif (msb_dec(15-10)='1') then msb_num <= "01010";-- "10101";
		elsif (msb_dec(15-11)='1') then msb_num <= "01011";-- "10100";
		elsif (msb_dec(15-12)='1') then msb_num <= "01100";-- "10011";
		elsif (msb_dec(15-13)='1') then msb_num <= "01101";-- "10010";
		elsif (msb_dec(15-14)='1') then msb_num <= "01110";-- "10001";
		elsif (msb_dec(15-15)='1') then msb_num <= "01111";-- "10000";
		else msb_num <= "11111";                    
		end if;	
	end if;
end process;	
	
msb_numn <= ("0" & msb_num) when rising_edge(clk);
----------------------------------------
pr_manz: process(clk) is
begin
	if rising_edge(clk) then 
		sum_mant <= sum_mt(16 downto 1);
		sum_manz <= sum_mant;
	end if;
end process;

----------------------------------------

-- second barrel shifter --
--norm_c <= sum_manx(31-conv_integer(msb_numn(3 downto 0)) downto 16-conv_integer(msb_numn(3 downto 0))) when rising_edge(clk); 
norm_c <= STD_LOGIC_VECTOR(SHL(UNSIGNED(sum_mant), UNSIGNED(msb_num(4 downto 0)))) when rising_edge(clk);	
frac <= norm_c when rising_edge(clk);

-- pr_set: process(clk) is
-- begin
	-- if rising_edge(clk) then 
		-- if (expaz(3) <= msb_num) then
			-- -- set_zero <= '1';
		-- -- else
			-- -- set_zero <= '0';
			-- set_zero <= '1';
		-- else
			-- set_zero <= '0';			
		-- end if;
	-- end if;
-- end process;				 
  
pr_set0: process(clk) is
begin
	if rising_edge(clk) then 
		set_zero <= (msb_num(4) and msb_num(3) and msb_num(2) and msb_num(1) and msb_num(0));
	end if;
end process;  

pr_set1: process(clk) is
begin
	if rising_edge(clk) then 
		if (expaz(3) < ('0' & msb_num)) then
			set_ones <= '1';
		else
			set_ones <= '0';
		end if;
	end if;
end process; 
  
-- exponent increment --	
pr_expx: process(clk) is
begin
	if rising_edge(clk) then 
		if (set_zero = '0') then
			if (set_ones = '0') then
				expc <= expaz(4) - msb_numn + '1';
			else
				expc <= "000001";
			end if;
		else
			expc <= "000000";
		end if;
	end if;
end process;

-- exp & sign delay --
pr_expz: process(clk) is
begin
	if rising_edge(clk) then
		expaz(0) <= muxaz.exp;
		for ii in 0 to 3 loop
			expaz(ii+1) <= expaz(ii);
		end loop;		
	end if;
end process;	

sign_c <= sign_c(sign_c'left-1 downto 0) & muxaz.sig when rising_edge(clk);
-- data out and result --	
--cc <= (expc, sign_c(sign_c'left), frac) when rising_edge(clk);

pr_dout: process(clk) is
begin 		
	if rising_edge(clk) then
		if (rstp = '1') then
			cc <= ("000000", '0', x"0000");
		else
			if (exp_zz(exp_zz'left) = '1') then
				cc <= ("000000", sign_c(sign_c'left), frac);
			else
				cc <= (expc,     sign_c(sign_c'left), frac);
			end if;
		end if;
	end if;
end process;

dout_val_v <= dout_val_v(dout_val_v'left-1 downto 0) & enable when rising_edge(clk);
valid <= dout_val_v(dout_val_v'left) when rising_edge(clk);

end fp23_addsub_m1;