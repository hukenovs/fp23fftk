-------------------------------------------------------------------------------
--
-- Title       : fp_m1_pkg
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : FP useful package
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
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

package	fp_m1_pkg is

	-- Useful types of ROM data for twiddle factor: data width = 16 bit --
	type std_array_16x1    is array (0 to 0)      of std_logic_vector(15 downto 00); 	
	type std_array_16x2    is array (0 to 1)      of std_logic_vector(15 downto 00); 	
	type std_array_16x4    is array (0 to 3)      of std_logic_vector(15 downto 00); 	
	type std_array_16x8    is array (0 to 7)      of std_logic_vector(15 downto 00); 	
	type std_array_16x16   is array (0 to 15)     of std_logic_vector(15 downto 00); 	
	type std_array_16x32   is array (0 to 31)     of std_logic_vector(15 downto 00); 	
	type std_array_16x64   is array (0 to 63)     of std_logic_vector(15 downto 00); 		
	type std_array_16x128  is array (0 to 127)    of std_logic_vector(15 downto 00); 		
	type std_array_16x256  is array (0 to 255)    of std_logic_vector(15 downto 00); 		
	type std_array_16x512  is array (0 to 511)    of std_logic_vector(15 downto 00); 		
	type std_array_16x1K   is array (0 to 1023)   of std_logic_vector(15 downto 00); 
	type std_array_16x2K   is array (0 to 2047)   of std_logic_vector(15 downto 00); 	
	type std_array_16x4K   is array (0 to 4095)   of std_logic_vector(15 downto 00); 	
	type std_array_16x8K   is array (0 to 8191)   of std_logic_vector(15 downto 00); 	
	type std_array_16x16K  is array (0 to 16383)  of std_logic_vector(15 downto 00); 	
	type std_array_16x32K  is array (0 to 32767)  of std_logic_vector(15 downto 00); 	
	type std_array_16x64K  is array (0 to 65535)  of std_logic_vector(15 downto 00); 	
	type std_array_16x128K is array (0 to 131071) of std_logic_vector(15 downto 00); 	
	type std_array_16x256K is array (0 to 262143) of std_logic_vector(15 downto 00);  
	type std_array_16x512K is array (0 to 524287) of std_logic_vector(15 downto 00);  
	
	-- Useful types of ROM data for twiddle factor: data width = 32 bit --
	type std_array_32x1    is array (0 to 0)      of std_logic_vector(31 downto 00); 	
	type std_array_32x2    is array (0 to 1)      of std_logic_vector(31 downto 00); 	
	type std_array_32x4    is array (0 to 3)      of std_logic_vector(31 downto 00); 	
	type std_array_32x8    is array (0 to 7)      of std_logic_vector(31 downto 00); 	
	type std_array_32x16   is array (0 to 15)     of std_logic_vector(31 downto 00); 	
	type std_array_32x32   is array (0 to 31)     of std_logic_vector(31 downto 00); 	
	type std_array_32x64   is array (0 to 63)     of std_logic_vector(31 downto 00); 		
	type std_array_32x128  is array (0 to 127)    of std_logic_vector(31 downto 00); 		
	type std_array_32x256  is array (0 to 255)    of std_logic_vector(31 downto 00); 		
	type std_array_32x512  is array (0 to 511)    of std_logic_vector(31 downto 00); 		
	type std_array_32x1K   is array (0 to 1023)   of std_logic_vector(31 downto 00); 
	type std_array_32x2K   is array (0 to 2047)   of std_logic_vector(31 downto 00); 	
	type std_array_32x4K   is array (0 to 4095)   of std_logic_vector(31 downto 00); 	
	type std_array_32x8K   is array (0 to 8191)   of std_logic_vector(31 downto 00); 	
	type std_array_32x16K  is array (0 to 16383)  of std_logic_vector(31 downto 00); 	
	type std_array_32x32K  is array (0 to 32767)  of std_logic_vector(31 downto 00); 	
	type std_array_32x64K  is array (0 to 65535)  of std_logic_vector(31 downto 00); 	
	type std_array_32x128K is array (0 to 131071) of std_logic_vector(31 downto 00); 	
	type std_array_32x256K is array (0 to 262143) of std_logic_vector(31 downto 00);  
	type std_array_32x512K is array (0 to 524287) of std_logic_vector(31 downto 00); 
	
	
	---- SIN / COS CALCULATING ----
	constant xNFFT : integer:=11;
	type std_logic_array_Kx16 is array (0 to 2**(xNFFT-1)-1) of std_logic_vector(15 downto 0);	
	type std_logic_array_Kx32 is array (0 to 2**(xNFFT-1)-1) of std_logic_vector(31 downto 0);
	
	function find_sin(xx : integer) return std_logic_array_Kx16;
	function find_cos(xx : integer) return std_logic_array_Kx16; 

	-- constant sin_rom : std_logic_array_Kx16:= find_sin(xNFFT);	
	-- constant cos_rom : std_logic_array_Kx16:= find_cos(xNFFT);	
	-- constant ww32x1K : std_logic_array_Kx32:= merge_vec(xNFFT, sin_rom, cos_rom);	
	
	type int16_complex is record
		re : std_logic_vector(15 downto 00);
		im : std_logic_vector(15 downto 00);
	end record;	
	
	type fp23_data is record
		exp 	: std_logic_vector(5 downto 0); 
		sig 	: std_logic;
		man 	: std_logic_vector(15 downto 0);
	end record;	
	
	type fp25_data is record
		exp 	: std_logic_vector(7 downto 0); 
		sig 	: std_logic;
		man 	: std_logic_vector(15 downto 0);
	end record;		
	
	type fp23_complex is record
		re : fp23_data;
		im : fp23_data;
	end record;
	
	type fp25_complex is record
		re : fp25_data;
		im : fp25_data;
	end record;	
	
	procedure find_fp(
		data_i	: in std_logic_vector(15 downto 0);
		data_o	: out std_logic_vector(22 downto 0)
	);		
	
	procedure find_float(
		data_i	: in std_logic_vector(15 downto 0);
		data_o	: out fp23_data
	);		
	
	component fp23_fix2float_m1 is
		generic(
			td			: time:=1ns	-- Time delay for simulation
			);
		port(
			din			: in  std_logic_vector(15 downto 0);	-- Fixed input data					
			ena			: in  std_logic;						-- Data enable 		
			dout		: out fp23_data;						-- Float output data
			vld			: out std_logic;						-- Data out valid      
			clk			: in  std_logic;						-- Clock            
			reset		: in  std_logic							-- Negative Reset            
		);
	end component;	
	
	component fp23_float2fix_m1 is
	generic(
		td			: time:=1ns; -- Time delay for simulation
		DW			: integer:=16 -- Output data width
	);
		port(
			din			: in  fp23_data;						-- Float input data	
			ena			: in  std_logic;						-- Data enable                        
			scale		: in  std_logic_vector(05 downto 0);	-- Scale factor 	   
			dout		: out std_logic_vector(DW-1 downto 0);	-- Fixed output data
			vld			: out std_logic;						-- Data out valid
			clk			: in  std_logic;						-- Clock
			reset		: in  std_logic;						-- Negative reset			
			overflow	: out std_logic							-- Flag overflow 		                      
		);
	end component;	
	
	component fp23_mult_m1 is
		generic(
			XSERIES : string:="7SERIES"; --! Xilinx series
			td		: time:=1ns	--! Time delay for simulation
		);
		port(
			aa 		: in  fp23_data;	-- Multiplicand A
			bb 		: in  fp23_data;	-- Multiplier B
			cc 		: out fp23_data;	-- Product C
			enable 	: in  std_logic;	-- Input data enable
			valid	: out std_logic;	-- Output data valid
			reset  	: in  std_logic;	-- Reset
			clk 	: in  std_logic		-- Clock	
		);	
	end component;	
	
	component fp23_addsub_m1 is
		generic (
			td		: time:=1ns			-- Time delay for simulation
			--addsub	: string(3 downto 1):="add"	-- add/sub attribute
		);
		port(
			aa 		: in  fp23_data;	-- Summand/Minuend A   
			bb 		: in  fp23_data;	-- Summand/Substrahend B     
			cc 		: out fp23_data;	-- Sum/Dif C        
			addsub	: in  std_logic;	-- '0' - Add, '1' - Sub
			enable 	: in  std_logic;	-- Input data enable
			valid	: out std_logic;	-- Output data valid
			reset  	: in  std_logic;	-- Reset            
			clk 	: in  std_logic		-- Clock	         
		);
	end component;	
	
	
end fp_m1_pkg;

package body fp_m1_pkg is

	function find_sin(xx : integer) return std_logic_array_Kx16 is
		variable pi_new : real:=0.0;
		variable si_new : std_logic_array_Kx16;
	begin
		for ii in 0 to 2**(xx-1)-1 loop
			pi_new := (real(ii) * MATH_PI)/(2.0**xx);
			si_new(ii) := STD_LOGIC_VECTOR(CONV_SIGNED(INTEGER(32767.0*SIN(-pi_new)),16));
		end loop;
		return si_new;
	end find_sin;

	function find_cos(xx : integer) return std_logic_array_Kx16 is
		variable pi_new : real:=0.0;
		variable co_new : std_logic_array_Kx16;
	begin
		for ii in 0 to 2**(xx-1)-1 loop
			pi_new := (real(ii) * MATH_PI)/(2.0**xx);
			co_new(ii) := STD_LOGIC_VECTOR(CONV_SIGNED(INTEGER(32767.0*COS(pi_new)),16));
		end loop;
		return co_new;
	end find_cos;	

	procedure find_float(
		data_i	: in std_logic_vector(15 downto 0);
		data_o	: out fp23_data
	) 
	is
		variable msb	: std_logic_vector(05 downto 00):="000001";
		variable man 	: std_logic_vector(15 downto 00):=(others=>'0');
	begin
		if (data_i(15) = '1') then
			man := data_i xor x"FFFF";
		else
			man := data_i;
		end if;
	
		xl: for jj in 0 to 15 loop
			if (man = x"0000") then
				msb := "100000";
				exit;
			else
				if (man(15) = '1') then
					man := man(14 downto 00) & '0';	
					exit;
				else	
					msb := msb + '1';
					man := man(14 downto 00) & '0';
				end if;
			end if;
		end loop;
		msb := "100000" - msb;
		
		data_o.sig := data_i(15);
		data_o.man := man;
		data_o.exp := msb;
	end find_float;	
	
	procedure find_fp(
		data_i	: in  std_logic_vector(15 downto 0);
		data_o	: out std_logic_vector(22 downto 0)
	) 
	is
		variable msb : std_logic_vector(05 downto 00):="000001";
		variable man : std_logic_vector(15 downto 00):=(others=>'0');
	begin
		if (data_i(15) = '1') then
			man := data_i xor x"FFFF";
		else
			man := data_i;
		end if;
	
		xl: for jj in 0 to 15 loop
			if (man = x"0000") then
				msb := "100000";
				exit;
			else
				if (man(15) = '1') then
					man := man(14 downto 00) & '0';	
					exit;
				else	
					msb := msb + '1';
					man := man(14 downto 00) & '0';
				end if;
			end if;
		end loop;
		msb := "100000" - msb;
		
		data_o(16) := data_i(15);
		data_o(15 downto 00) := man;
		data_o(22 downto 17) := msb;
	end find_fp;	
	

end package	body fp_m1_pkg;