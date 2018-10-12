-------------------------------------------------------------------------------
--
-- Title       : fp23_addsub_m3
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
use work.reduce_pack.or_reduce;
use work.fp_m1_pkg.fp23_data;

library unisim;
use unisim.vcomponents.DSP48E1;

entity fp23_addsub_m3 is
	generic (
		XSERIES : string:="7SERIES" --! Xilinx series
	);	
	port (
		aa 		: in  fp23_data;	--! Summand/Minuend A   
		bb 		: in  fp23_data;	--! Summand/Substrahend B     
		cc 		: out fp23_data;	--! Sum/Dif C        
		addsub	: in  std_logic;	--! '0' - Add, '1' - Sub
		reset	: in  std_logic;	--! '0' - Reset
		enable 	: in  std_logic;	--! Input data enable
		valid	: out std_logic;	--! Output data valid          
		clk 	: in  std_logic		--! Clock	         
	);
end fp23_addsub_m3;

architecture fp23_addsub_m3 of fp23_addsub_m3 is 

type std_logic_array_5x6 is array (5 downto 0) of std_logic_vector(5 downto 0);

signal aa_z			   	: fp23_data;	  
signal bb_z				: fp23_data;
signal comp				: std_logic_vector(22 downto 0); 

signal muxa             : fp23_data;
signal muxb             : fp23_data;
signal muxaz            : fp23_data;

signal exp_dif			: std_logic_vector(5 downto 0);

signal impl_a			: std_logic;
signal impl_b			: std_logic; 

signal man_az			: std_logic_vector(16 downto 0);
signal subtract         : std_logic;

signal msb_num			: std_logic_vector(4 downto 0);

signal expc				: std_logic_vector(5 downto 0);
signal frac           	: std_logic_vector(15 downto 0);

signal set_zero			: std_logic;

signal expaz			: std_logic_array_5x6;
signal sign_c			: std_logic_vector(4 downto 0);

signal dout_val_v		: std_logic_vector(7 downto 0);

signal exp_a0			: std_logic;
signal exp_b0			: std_logic;
signal exp_ab			: std_logic;
signal exp_zz			: std_logic_vector(5 downto 0);

signal new_man			: std_logic_vector(15 downto 0);

signal shift_man    	: std_logic_vector(15 downto 0);

signal alu_mode			: std_logic_vector(3 downto 0);

signal dsp_aa			: std_logic_vector(29 downto 0);
signal dsp_bb			: std_logic_vector(17 downto 0);
signal dsp_cc			: std_logic_vector(47 downto 0);
signal sum_man			: std_logic_vector(47 downto 0);

signal dsp_mlt			: std_logic;

constant CONST_ONE		: std_logic_vector(15 downto 0):=x"8000";

begin	

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

exp_a0 <= or_reduce(aa.exp) when rising_edge(clk);
exp_b0 <= or_reduce(bb.exp) when rising_edge(clk);

exp_ab <= not (exp_a0 or exp_b0) when rising_edge(clk);
exp_zz <= exp_zz(exp_zz'left-1 downto 0) & exp_ab when rising_edge(clk);

-- check difference (least/most attribute) --

pr_ex: process(clk) is
begin
	if rising_edge(clk) then
		comp <= ('0' & aa.exp & aa.man) - ('0' & bb.exp & bb.man);
	end if;
end process; 

---- data switch multiplexer --
pr_mux: process(clk) is
begin
	if rising_edge(clk) then
		if (comp(22) = '1') then
			muxa <= bb_z;
			muxb <= aa_z; 
		else
			muxa <= aa_z;
			muxb <= bb_z;
		end if;
		muxaz <= muxa; 
	end if;
end process;

---- implied '1' for fraction --
pr_imp: process(clk) is
begin
	if rising_edge(clk) then
		if (comp(22) = '1') then
			impl_a <= exp_b0;
			impl_b <= exp_a0; 
		else
			impl_a <= exp_a0;
			impl_b <= exp_b0;
		end if;
	end if;
end process;

---- Find exponent ----
exp_dif <= muxa.exp - muxb.exp when rising_edge(clk);

pr_mlt: process(clk) is
begin
	if rising_edge(clk) then
		if (exp_dif(5 downto 4) = "00") then
			dsp_mlt <= '0';
		else
			dsp_mlt <= '1';
		end if;
	end if;
end process;

---- Shift vector for fraction ----
shift_man <= STD_LOGIC_VECTOR(SHR(UNSIGNED(CONST_ONE), UNSIGNED(exp_dif(4 downto 0)))) when rising_edge(clk);	

pr_manz: process(clk) is
begin
	if rising_edge(clk) then 
		subtract <= muxa.sig xor muxb.sig;
		alu_mode <= "00" & subtract & subtract;
	end if;
end process;

---- Find fraction by using DSP48 ----
dsp_aa(16 downto 00) <= impl_b & muxb.man;
dsp_aa(29 downto 17) <= (others=>'0');
dsp_bb <= "00" & shift_man;

man_az <= impl_a & muxa.man when rising_edge(clk);
dsp_cc(14 downto 00) <= (others =>'0');
dsp_cc(31 downto 15) <= man_az when rising_edge(clk);
dsp_cc(47 downto 32) <= (others =>'0');

xDSP48E1: if (XSERIES = "7SERIES") generate
	align_add: DSP48E1
		generic map (
			ALUMODEREG		=> 1,
			ADREG			=> 0,
			AREG			=> 2,
			BCASCREG		=> 0,
			BREG			=> 0,
			CREG			=> 1,
			DREG			=> 0,
			MREG			=> 1,
			PREG			=> 1
		)		
		port map (     
			P               => sum_man, 
			A               => dsp_aa,
			ACIN			=> (others=>'0'),
			ALUMODE			=> alu_mode,
			B               => dsp_bb, 
			BCIN            => (others=>'0'), 
			C               => dsp_cc,
			CARRYCASCIN		=> '0',
			CARRYIN         => '0', 
			CARRYINSEL      => (others=>'0'),
			CEA1            => '1',
			CEA2            => '1',
			CEAD            => '1',
			CEALUMODE       => '1',
			CEB1            => '1',
			CEB2            => '1',
			CEC             => '1',
			CECARRYIN       => '1',
			CECTRL          => '1',
			CED				=> '1',
			CEINMODE		=> '1',
			CEM             => '1',
			CEP             => '1',
			CLK             => clk,
			D               => (others=>'0'),
			INMODE			=> "00000",
			MULTSIGNIN		=> '0',
			OPMODE          => "0110101",
			PCIN            => (others=>'0'),
			RSTA            => reset,
			RSTALLCARRYIN	=> reset,
			RSTALUMODE   	=> reset,
			RSTB            => reset,
			RSTC            => reset,
			RSTCTRL         => reset,
			RSTD			=> reset,
			RSTINMODE		=> reset,
			RSTM            => dsp_mlt,
			RSTP            => reset 
		);
end generate;

xDSP48E2: if (XSERIES = "ULTRA") generate
	align_add: DSP48E1
		generic map (
			ADREG			=> 0,
			AREG			=> 2,
			BCASCREG		=> 0,
			BREG			=> 0,
			CREG			=> 1,
			DREG			=> 0,
			MREG			=> 1,
			PREG			=> 1
		)		
		port map (     
			P               => sum_man, 
			A               => dsp_aa,
			ACIN			=> (others=>'0'),
			ALUMODE			=> alu_mode,
			B               => dsp_bb, 
			BCIN            => (others=>'0'), 
			C               => dsp_cc,
			CARRYCASCIN		=> '0',
			CARRYIN         => '0', 
			CARRYINSEL      => (others=>'0'),
			CEA1            => '1',
			CEA2            => '1',
			CEAD            => '1',
			CEALUMODE       => '1',
			CEB1            => '1',
			CEB2            => '1',
			CEC             => '1',
			CECARRYIN       => '1',
			CECTRL          => '1',
			CED				=> '1',
			CEINMODE		=> '1',
			CEM             => '1',
			CEP             => '1',
			CLK             => clk,
			D               => (others=>'0'),
			INMODE			=> "00000",
			MULTSIGNIN		=> '0',
			OPMODE          => "000110101",
			PCIN            => (others=>'0'),
			RSTA            => reset,
			RSTALLCARRYIN	=> reset,
			RSTALUMODE   	=> reset,
			RSTB            => reset,
			RSTC            => reset,
			RSTCTRL         => reset,
			RSTD			=> reset,
			RSTINMODE		=> reset,
			RSTM            => dsp_mlt,
			RSTP            => reset 
		);
end generate;

---- find MSB (highest '1' position) ----
pr_align: process(clk) is 
begin
	if rising_edge(clk) then
		if    (sum_man(sum_man'left-00-15)='1') then msb_num <= "00000";-- "11111";
		elsif (sum_man(sum_man'left-01-15)='1') then msb_num <= "00001";-- "11110";
		elsif (sum_man(sum_man'left-02-15)='1') then msb_num <= "00010";-- "11101";
		elsif (sum_man(sum_man'left-03-15)='1') then msb_num <= "00011";-- "11100";
		elsif (sum_man(sum_man'left-04-15)='1') then msb_num <= "00100";-- "11011";
		elsif (sum_man(sum_man'left-05-15)='1') then msb_num <= "00101";-- "11010";
		elsif (sum_man(sum_man'left-06-15)='1') then msb_num <= "00110";-- "11001";
		elsif (sum_man(sum_man'left-07-15)='1') then msb_num <= "00111";-- "11000";
		elsif (sum_man(sum_man'left-08-15)='1') then msb_num <= "01000";-- "10111";
		elsif (sum_man(sum_man'left-09-15)='1') then msb_num <= "01001";-- "10110";
		elsif (sum_man(sum_man'left-10-15)='1') then msb_num <= "01010";-- "10101";
		elsif (sum_man(sum_man'left-11-15)='1') then msb_num <= "01011";-- "10100";
		elsif (sum_man(sum_man'left-12-15)='1') then msb_num <= "01100";-- "10011";
		elsif (sum_man(sum_man'left-13-15)='1') then msb_num <= "01101";-- "10010";
		elsif (sum_man(sum_man'left-14-15)='1') then msb_num <= "01110";-- "10001";
		elsif (sum_man(sum_man'left-15-15)='1') then msb_num <= "01111";-- "10000";
		else msb_num <= "11111";
		end if;
	end if;
end process;

new_man <= sum_man(31 downto 31-15) when rising_edge(clk);

frac <= STD_LOGIC_VECTOR(SHL(UNSIGNED(new_man), UNSIGNED(msb_num(3 downto 0)))) when rising_edge(clk);	

set_zero <= msb_num(4);

---- exponent increment ----	
pr_expx: process(clk) is
begin
	if rising_edge(clk) then 
		---- Set ones (error of rounding fp data ----
		if (set_zero = '0') then
			if (expaz(3) < ('0' & msb_num)) then
				expc <= "000000";
			else
				expc <= expaz(3) - msb_num + '1';
			end if;
		else
			expc <= "000000";
		end if;		
	end if;
end process;

---- exp & sign delay ----
pr_expz: process(clk) is
begin
	if rising_edge(clk) then
		expaz <= expaz(expaz'left-1 downto 0) & muxaz.exp;
		sign_c <= sign_c(sign_c'left-1 downto 0) & muxaz.sig;
	end if;
end process;

---- output product ----
pr_dout: process(clk) is
begin 		
	if rising_edge(clk) then
		if (exp_zz(exp_zz'left) = '1') then
			cc <= ("000000", '0', x"0000");
		else
			cc <= (expc, sign_c(sign_c'left), frac);
		end if;
	end if;
end process;

dout_val_v <= dout_val_v(dout_val_v'left-1 downto 0) & enable when rising_edge(clk);
valid <= dout_val_v(dout_val_v'left) when rising_edge(clk);

end fp23_addsub_m3;