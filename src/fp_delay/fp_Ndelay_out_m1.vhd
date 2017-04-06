-------------------------------------------------------------------------------
--
-- Title       : fp_Ndelay_out_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : version 1.0 
--
-- Universal output buffer for FFT project
-- It has several independent DPRAM components for FFT stages between 2k and 64k
--
-- 16.04.2015
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

entity fp_Ndelay_out_m1 is
	generic (
		td			: time:=1ns; --! Time delay for simulation
		STAGES		: integer:=7; --! FFT stages
		Nwidth		: integer:=48 --! Data width
	);
	port(
		dout_re		: out std_logic_vector(Nwidth-1 downto 0); --! Data Real
		dout_im		: out std_logic_vector(Nwidth-1 downto 0); --! Data Imag
		dout_val	: out std_logic; --! Data vaid
							
		clk  		: in  std_logic; --! Clock
		reset 		: in  std_logic; --! Reset		
		
		ca_re		: in  std_logic_vector(Nwidth-1 downto 0); --! Even Real
		ca_im		: in  std_logic_vector(Nwidth-1 downto 0); --! Even Imag
		cb_re		: in  std_logic_vector(Nwidth-1 downto 0); --! Odd Real 
		cb_im		: in  std_logic_vector(Nwidth-1 downto 0); --! Odd Imag 		
		din_en		: in  std_logic --! Data enable	
	);	
end fp_Ndelay_out_m1;

architecture fp_Ndelay_out_m1 of fp_Ndelay_out_m1 is

signal addra			: std_logic_vector(STAGES-2 downto 0);
signal addrb			: std_logic_vector(STAGES-1 downto 0);
signal cnt				: std_logic_vector(STAGES-1 downto 0);	  

signal din_rez			: std_logic_vector(Nwidth-1 downto 0);
signal din_imz			: std_logic_vector(Nwidth-1 downto 0);

signal ram_din			: std_logic_vector(2*Nwidth-1 downto 0);
signal ram_dout			: std_logic_vector(2*Nwidth-1 downto 0);

signal rstp				: std_logic;
signal ena, enb			: std_logic;
signal enaz				: std_logic;

signal muxa				: std_logic_vector(Nwidth-1 downto 0);
signal muxb				: std_logic_vector(Nwidth-1 downto 0);

signal dat_ena			: std_logic:='0';

begin

rstp <= not reset after td when rising_edge(clk);	

din_rez <= ca_re after td when rising_edge(clk);
din_imz <= ca_im after td when rising_edge(clk);

pr_cnt: process(clk) is
begin	
	if rising_edge(clk) then
		if (rstp = '1') then
			cnt <= (others => '0') after td;
		else
			if (cnt(STAGES-1) = '1') then
				cnt(STAGES-1) <= '0' after td;
			else
				if din_en = '1' then
					cnt <= cnt + '1' after td;
				end if;
			end if;
		end if;
	end if;
end process;
addra <= cnt(STAGES-2 downto 0);

dat_ena <= '1' when cnt(STAGES-1) = '1' else '0' when addrb(STAGES-1) = '1';

enaz <= ena after td when rising_edge(clk);
 
pr_cnt2: process(clk) is
begin
	if rising_edge(clk) then
		if (rstp = '1') then
			addrb <= (others => '0');		
		else
			if (dat_ena = '1') then
				addrb <= addrb + '1' after td;
			else
				addrb(STAGES-1) <= '0' after td;
			end if;
		end if;
	end if;
end process;

ena 		<= din_en;
enb 		<= dat_ena after td when rising_edge(clk);
ram_din 	<= cb_im & cb_re;

G_HIGH_STAGE: if (STAGES >= 10) generate
	type ram_t is array(0 to 2**(STAGES-1)-1) of std_logic_vector(2*Nwidth-1 downto 0);
	signal ram					: ram_t;
	signal dout					: std_logic_vector(2*Nwidth-1 downto 0);
	
	attribute ram_style			: string;
	attribute ram_style of RAM	: signal is "block";	
	
	signal din_rezz				: std_logic_vector(Nwidth-1 downto 0);
	signal din_imzz				: std_logic_vector(Nwidth-1 downto 0); 
    
	signal din_rezzz			: std_logic_vector(Nwidth-1 downto 0);
	signal din_imzzz			: std_logic_vector(Nwidth-1 downto 0); 	
	
	signal addrbz				: std_logic_vector(STAGES-2 downto 0);
	signal enbz					: std_logic; 
	signal enazz				: std_logic;
	signal enbzz				: std_logic; 
	signal dat_val				: std_logic;
	
begin
	enbz  <= enb after td when rising_edge(clk); 
	enazz <= enaz after td when rising_edge(clk);
	enbzz <= enbz after td when rising_edge(clk);	
	
	pr_ramb: process (clk) is
	begin
		if (clk'event and clk = '1') then
			ram_dout <= dout after td;
			if (rstp = '1') then
				dout <= (others => '0');
			else
				if (enb = '1') then
					dout <= ram(conv_integer(addrbz)) after td; -- dual port
				end if;
			end if;				
			if (ena = '1') then
				ram(conv_integer(addra)) <= ram_din;
			end if;
		end if;	
	end process;
	addrbz <= addrb(STAGES-2 downto 0) after td when rising_edge(clk);
	
	pr_mux: process (clk) is
	begin
		if (clk'event and clk = '1') then
			if (enbzz = '0') then
				muxa <= din_rezzz after td;
				muxb <= din_imzzz after td;
			else
				muxa <= ram_dout(1*Nwidth-1 downto 00) after td;  				
				muxb <= ram_dout(2*Nwidth-1 downto Nwidth) after td;  				
			end if;
		end if;	
	end process;	

	din_rezzz 	<= din_rezz after td when rising_edge(clk);
	din_imzzz 	<= din_imzz after td when rising_edge(clk);		
	
	din_rezz 	<= din_rez after td when rising_edge(clk);
	din_imzz 	<= din_imz after td when rising_edge(clk);	
	
	dout_val	<= dat_val after td when rising_edge(clk);	
	dat_val 	<= (enbz or enazz) after td when rising_edge(clk);	

end generate;

G_LOW_STAGE: if (STAGES < 10) generate	
	type ram_t is array(0 to 2**(STAGES-1)-1) of std_logic;--_vector(31 downto 0);	
	--signal ram 		: ram_t; 
begin
	X_GEN_W: for ii in 0 to 2*Nwidth-1 generate
	begin
		pr_srlram: process (clk) is
			variable ram : ram_t;
		begin
			if (clk'event and clk = '1') then
				if (ena = '1') then
					ram(conv_integer(addra)) := ram_din(ii);
				end if;
				--ram_dout <= ram(conv_integer(addra)) after td; -- signle port
				ram_dout(ii) <= ram(conv_integer(addrb(stages-2 downto 0))) after td; -- dual port
			end if;	
		end process;
	end generate;
	
	pr_mux: process (clk) is
	begin
		if (clk'event and clk = '1') then
			if (enb = '0') then
				muxa <= din_rez after td;
				muxb <= din_imz after td;
			else
				muxa <= ram_dout(1*Nwidth-1 downto 00) after td;  				
				muxb <= ram_dout(2*Nwidth-1 downto Nwidth) after td;  				
			end if;
		end if;	
	end process;
	
	dout_val <= (enb or enaz) after td when rising_edge(clk);
end generate; 

dout_re	<= muxa;
dout_im	<= muxb;

end fp_Ndelay_out_m1;