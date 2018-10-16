-------------------------------------------------------------------------------
--
-- Title       : fp_Ndelay_in
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
--	Version 1.0  03.04.2015
--			   	 Description: Universal input buffer for FFT project
-- 					It has several independent DPRAM components for FFT stages 
-- 					between 2k and 64k
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

entity fp_Ndelay_in is
	generic (
		td			: time:=1ns; --! Time delay for simulation
		STAGES		: integer:=7; --! FFT stages
		Nwidth		: integer:=48 --! Data width		
	);
	port(
		din_re		: in  std_logic_vector(Nwidth-1 downto 0); --! Data Real
		din_im		: in  std_logic_vector(Nwidth-1 downto 0); --! Data Imag
		din_en		: in  std_logic; --! Data enable

		clk  		: in  std_logic; --! Clock
		reset 		: in  std_logic; --! Reset		
		
		ca_re		: out std_logic_vector(Nwidth-1 downto 0); --! Even Real
		ca_im		: out std_logic_vector(Nwidth-1 downto 0); --! Even Imag
		cb_re		: out std_logic_vector(Nwidth-1 downto 0); --! Odd Real 
		cb_im		: out std_logic_vector(Nwidth-1 downto 0); --! Odd Imag 		
		dout_val	: out std_logic --! Data valid		
	);	
end fp_Ndelay_in;

architecture fp_Ndelay_in of fp_Ndelay_in is

signal addra			: std_logic_vector(STAGES-2 downto 0);
signal addrb			: std_logic_vector(STAGES-2 downto 0);
signal cnt				: std_logic_vector(STAGES-1 downto 0);	  

signal din_rez			: std_logic_vector(Nwidth-1 downto 0);
signal din_imz			: std_logic_vector(Nwidth-1 downto 0);
signal din_rezz			: std_logic_vector(Nwidth-1 downto 0);
signal din_imzz			: std_logic_vector(Nwidth-1 downto 0); 


signal ram_din			: std_logic_vector(2*Nwidth-1 downto 0);
signal ram_dout			: std_logic_vector(2*Nwidth-1 downto 0);

signal dout_en			: std_logic; 
signal dout_enz			: std_logic; 
signal ena				: std_logic;
signal wea				: std_logic;

begin	
	
-- Common processes for delay lines --
din_rez <= din_re after td when rising_edge(clk);
din_imz <= din_im after td when rising_edge(clk);

din_rezz <= din_rez after td when rising_edge(clk);
din_imzz <= din_imz after td when rising_edge(clk);

pr_cnt: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '1') then
			cnt <= (others => '0') after td;		
		else
			if (din_en = '1') then
				cnt <= cnt + '1' after td;
			end if;	
		end if;
	end if;
end process;

addra <= cnt(STAGES-2 downto 0);
addrb <= cnt(STAGES-2 downto 0) after td when rising_edge(clk);

ena 		<= din_en;
wea			<= not cnt(STAGES-1);
ram_din 	<= din_im & din_re;
dout_en 	<= cnt(STAGES-1) and din_en after td when rising_edge(clk);
dout_enz	<= dout_en after td when rising_edge(clk);

dout_val 	<= dout_enz after td when rising_edge(clk);
cb_re 		<= din_rezz after td when rising_edge(clk) and dout_enz = '1';
cb_im 		<= din_imzz after td when rising_edge(clk) and dout_enz = '1';	

G_HIGH_STAGE: if (STAGES >= 10) generate
	type ram_t is array(0 to 2**(STAGES-1)-1) of std_logic_vector(2*Nwidth-1 downto 0);
	signal ram					: ram_t;
	signal dout					: std_logic_vector(2*Nwidth-1 downto 0);
	signal enb					: std_logic;
	
	attribute ram_style			: string;
	attribute ram_style of RAM	: signal is "block";	
                   		
begin
	enb <= cnt(STAGES-1) and din_en after td when rising_edge(clk);
	
	PR_RAMB: process(clk) is
	begin
		if (clk'event and clk = '1') then
			ram_dout <= dout after td;
			if (reset = '1') then
				dout <= (others => '0');
			else
				if (enb = '1') then
					dout <= ram(conv_integer(addrb)) after td; -- dual port
				end if;
			end if;				
			if (ena = '1') then
				if (wea = '1') then
					ram(conv_integer(addra)) <= ram_din;
				end if;
			end if;
		end if;	
	end process;

	ca_re <= ram_dout(1*Nwidth-1 downto 0); --after td when rising_edge(clk);
	ca_im <= ram_dout(2*Nwidth-1 downto Nwidth); --after td when rising_edge(clk);		
end generate;

G_LOW_STAGE: if (STAGES < 10) generate	
	type ram_t is array(0 to 2**(STAGES-1)-1) of std_logic;--_vector(31 downto 0);	
	--signal ram 		: ram_t; 
begin
	X_GEN_SRL: for ii in 0 to 2*Nwidth-1 generate
	begin
		pr_srlram: process(clk) is
			variable ram : ram_t;
		begin
			if (clk'event and clk = '1') then
				if (wea = '1') then
					ram(conv_integer(addra)) := ram_din(ii);
				end if;
				--ram_dout <= ram(conv_integer(addra)) after td; -- signle port
				ram_dout(ii) <= ram(conv_integer(addrb)) after td; -- dual port
			end if;	
		end process;
	end generate;

	ca_re <= ram_dout(1*Nwidth-1 downto 0) after td when rising_edge(clk) and dout_enz = '1';
	ca_im <= ram_dout(2*Nwidth-1 downto Nwidth) after td when rising_edge(clk) and dout_enz = '1';			
end generate; 

end fp_Ndelay_in;