-------------------------------------------------------------------------------
--
-- Title       : fp_delay_line_m1
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-------------------------------------------------------------------------------
--
-- Description : version 1.1 
--
-------------------------------------------------------------------------------
--
--	Version 1.0  29.09.2015
--			   	 Description: Common delay line for FFT	
--					It is a huge delay line which combines all of delay line NFFT (short/medium/long)
--					For (N and stage) pair you will see area resources after process of mapping.
--					SLICEM and LUTs used for short delay line.
--					(SLICEM and LUTs) or (RAMB36 and RAMB18) used for medium delay line.
--					RAMB36 and RAMB18 used for long delay line.
--			
--	
--	Version 1.1  03.10.2015 
--				 Delay line: 
--					N = 0004, delay = 001 - FD,
--					N = 0008, delay = 002 - 2*FD,			 
--					N = 0016, delay = 004 - SLISEM/8 (SRL16),
--					N = 0032, delay = 008 - SLISEM/4 (SRL16),
--					N = 0064, delay = 016 - SLISEM/2 (SRL16),
--					N = 0128, delay = 032 - SLISEM (SRL32),
--					N = 0256, delay = 064 - 2*SLISEM (CLB/2),
--					N = 0512, delay = 128 - 4*SLISEM (CLB), 
--					N = 001K, delay = 256 - 8*SLISEM (2*CLB), ** OR 4+1 RAMB18E1
--					N = 002K, delay = 512 - 4+1 RAMB18E1
--					N = 004K, delay = 01K - 6+1 RAMB18E1
--					N = 008K, delay = 02K - 12+1 RAMB18E1		 
--					N = 016K, delay = 04K - 24+1 RAMB18E1
--					N = 032K, delay = 08K - 48+1 RAMB18E1
--					N = 064K, delay = 16K - 96+1 RAMB18E1 
--					N = 128K, delay = 32K - 96+1 RAMB36E1 
--					N = 256K, delay = 64K - 128+1 RAMB36E1 etc.
--	
--	Version 1.2  03.03.2016 
--				 Removed suboptimal logic blocks.
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

entity fp_delay_line_m1 is
	generic(
		td			: time:=1ns; --! Time delay for simulation	
		NFFT		: integer:=18; --! FFT NFFT
		stage 		: integer:=0; --! Stage number
		Nwidth		: integer:=48 --! Data width
	);
	port(
		ia 			: in  std_logic_vector(Nwidth-1 downto 0); --! Data in even
		ib 			: in  std_logic_vector(Nwidth-1 downto 0); --! Data in odd
		din_en 		: in  std_logic; --! Data enable
		
		oa 			: out std_logic_vector(Nwidth-1 downto 0); --! Data out even
		ob 			: out std_logic_vector(Nwidth-1 downto 0); --! Data out odd
		dout_val	: out std_logic; --! Data valid
		
		reset  		: in  std_logic; --! Reset
		clk 		: in  std_logic --! Clock	
	);	
end fp_delay_line_m1;

architecture fp_delay_line_m1 of fp_delay_line_m1 is 

constant N_INV			: integer:=NFFT-stage-2; 

signal cross			: std_logic:='0';
signal cnt_wrcr			: std_logic_vector(N_INV downto 0);
signal oa_e				: std_logic_vector(Nwidth-1 downto 0);	
signal ob_e				: std_logic_vector(Nwidth-1 downto 0);

signal din_enz			: std_logic;
signal rstp				: std_logic;

signal ram0_din			: std_logic_vector(Nwidth-1 downto 0):=(others => '0');
signal ram0_dout    	: std_logic_vector(Nwidth-1 downto 0):=(others => '0');
signal ram1_din			: std_logic_vector(Nwidth-1 downto 0):=(others => '0');
signal ram1_dout    	: std_logic_vector(Nwidth-1 downto 0):=(others => '0');

signal iaz 				: std_logic_vector(Nwidth-1 downto 0);

begin
 
-- Common processes for delay lines --
rstp <= not reset after td when rising_edge(clk);	
	
pr_cnt_wrcr: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '0') then 
			cnt_wrcr <= (others => '0');			
		else
			if (din_enz = '1') then
				cnt_wrcr <= cnt_wrcr + '1' after td;
			end if;
		end if;	
	end if;
end process;	

pr_din: process(clk) is
begin		
	if rising_edge(clk) then
		if (rstp = '1') then
			ram0_din <=	(others => '0');
			ram1_din <=	(others => '0');
		else
			if (din_en = '1') then
				ram0_din <=	ib after td;
			end if;
			if (cross = '1') then
				ram1_din <= ram0_dout after td; 
			else
				ram1_din <= iaz after td; 
			end if;							
		end if;
	end if;
end process; 

oa	<=	oa_e;

G_DEL_SHORT: if (N_INV < 9) generate
	signal ram_del : std_logic_vector(2**(N_INV)-1 downto 0):=(others=>'0');
begin
	
	din_enz <= din_en;
	cross <= cnt_wrcr(N_INV);	
	iaz <= ia;
	
	ram_del <= ram_del(2**(N_INV)-2 downto 0) & din_en after td when rising_edge(clk);
	-- RAMB delay line -- 
	GEN_GRT1: if (N_INV > 0) generate
		constant delay  : integer:=2**(N_INV)-2;
		type std_logic_array_NarrxNwidth is array (delay downto 0) of std_logic_vector(Nwidth-1 downto 0);	
		signal dout0, dout1	: std_logic_array_NarrxNwidth;
	begin			
		dout1 <= dout1(delay-1 downto 0) & ram1_din after td when rising_edge(clk);	
		dout0 <= dout0(delay-1 downto 0) & ram0_din after td when rising_edge(clk);

		ram1_dout <= dout1(delay);
		ram0_dout <= dout0(delay);
	end generate;
	
	GEN_LOW1: if (N_INV = 0 ) generate	
		ram0_dout <= ram0_din;
		ram1_dout <= ram1_din;
	end generate;
	
	dout_val <= ram_del(2**(N_INV)-1) after td when rising_edge(clk);
	
	pr_out: process(clk) is
	begin
		if rising_edge(clk) then
			if (ram_del(2**(N_INV)-1) = '1') then
				oa_e <= ram1_dout after td;
				if (cross = '1') then
					ob_e <= ia after td;   			
				else
					ob_e <= ram0_dout after td; 			
				end if;
			end if;
		end if;
	end process; 
	
	ob	<=	ob_e;
end generate; 

G_DEL_LONG: if (N_INV >= 9) generate
	
	signal cnt_wr 		: std_logic_vector(N_INV-1 downto 0);	
	
	signal addrs		: std_logic_vector(N_INV-1 downto 0); 
	signal addrs1		: std_logic_vector(N_INV-1 downto 0);
	signal addrz		: std_logic_vector(N_INV-1 downto 0); 
	signal addrz1		: std_logic_vector(N_INV-1 downto 0);
	
	signal dir_dia		: std_logic_vector(Nwidth-1 downto 0);
	signal obz			: std_logic_vector(Nwidth-1 downto 0);	  
	signal ob_z			: std_logic_vector(Nwidth-1 downto 0);	
	
	signal del_o		: std_logic;
	signal cnt_rd		: std_logic_vector(NFFT-3-stage downto 0);
	
	signal we			: std_logic:='0';
	signal wes			: std_logic:='0';
	signal wes1			: std_logic:='0';
	signal wez			: std_logic:='0';
	signal wez1			: std_logic:='0';
	signal val			: std_logic:='0';
	
	type ram_d is array(0 to 2**(N_INV)-1) of std_logic; 
	
	signal ram_del		: ram_d;
	attribute ram_style	: string;
	attribute ram_style of RAM_DEL : signal is "block";
	

	type ram_t is array(0 to 2**(N_INV)-1) of std_logic_vector(Nwidth-1 downto 0);  
	signal bram0					: ram_t;
	signal bram1					: ram_t;	
	attribute ram_style of bram0	: signal is "block";		
	attribute ram_style of bram1	: signal is "block";
	
	signal ia_ze 		: std_logic_vector(Nwidth-1 downto 0);
	
begin
	
	din_enz <= din_en after td when rising_edge(clk);	
	cross <= cnt_wrcr(N_INV) after td when rising_edge(clk);	 	
	ia_ze <= ia after td when rising_edge(clk);
	iaz <= ia_ze after td when rising_edge(clk);
	
	we   <=	din_en after td when rising_edge(clk);
	wez  <=	we after td when rising_edge(clk);

	wes  <=	wez after td when rising_edge(clk);
	
	wez1 <=	del_o after td when rising_edge(clk); 	
	wes1 <=	wez1 after td when rising_edge(clk); 
	val <= wes1 after td when rising_edge(clk);
	dout_val <= val after td when rising_edge(clk);	
	
	addrz   <= cnt_wrcr(N_INV-1 downto 0) after td when rising_edge(clk);
	addrz1  <= cnt_wr after td when rising_edge(clk);	
	addrs   <= addrz after td when rising_edge(clk);
	addrs1  <= addrz1 after td when rising_edge(clk);	
	
	pr_cnt: process(clk) is
	begin
		if rising_edge(clk) then
			if (rstp = '1') then 
				cnt_wr <= (others => '0');
				cnt_rd <= (others => '0');
			else
				cnt_rd <= cnt_rd + '1' after td;
				if (del_o = '1') then
					cnt_wr <= cnt_wr + '1' after td;
				end if;	
			end if;
		end if;
	end process;
	
	pr_ob: process(clk) is
	begin
		if rising_edge(clk) then
			if (cross = '1') then
				ob_e <= dir_dia after td;   			
			else
				ob_e <= ram0_dout after td; 			
			end if;
		end if;
	end process;
	
	dir_dia	<= ia_ze after td when rising_edge(clk);	
																				   
	ob_z 	<= ob_e after td when rising_edge(clk);
	ob		<= ob_z after td when rising_edge(clk);
	oa_e 	<= ram1_dout after td when rising_edge(clk);
	
	-- RAMB enable delay line -- 
	RAMV: process(clk) is
	begin
		if (clk'event and clk = '1') then
			if (rstp = '1') then
				del_o <= '0';
			else
				del_o <= ram_del(conv_integer(cnt_rd)) after td; -- dual port
			end if;				
			ram_del(conv_integer(cnt_rd)) <= din_en after td;
		end if;	
	end process;  
	-- First RAMB delay line -- 
	RAM0: process(clk) is
	begin
		if (clk'event and clk = '1') then
			if (rstp = '1') then
				ram0_dout <= (others => '0');
			else
				if (del_o = '1') then
					ram0_dout <= bram0(conv_integer(cnt_wr)) after td; -- dual port
				end if;
			end if;				
			if (we = '1') then
				bram0(conv_integer(cnt_wrcr(N_INV-1 downto 0))) <= ram0_din after td;
			end if;
		end if;	
	end process;
    -- Second RAMB delay line --        		
	RAM1: process(clk) is
	begin
		if (clk'event and clk = '1') then
			if (rstp = '1') then
				ram1_dout <= (others => '0');
			else
				if (wes1 = '1') then
					ram1_dout <= bram1(conv_integer(addrs1)) after td; -- dual port
				end if;
			end if;				
			if (wes = '1') then
				bram1(conv_integer(addrs)) <= ram1_din after td;
			end if;
		end if;	
	end process;	
end generate;

end fp_delay_line_m1;