-------------------------------------------------------------------------------
--
-- Title       : fp_bitrev_ord
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     : 
--
-------------------------------------------------------------------------------
--
--	Version 1.0  13.08.2016
--			   	 Description: Universal bitreverse algorithm for FFT project
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

entity fp_bitrev_ord is
	generic (
		td			: time:=1ns; --! Time delay for simulation
		FWT			: boolean:=TRUE; --! Bitreverse mode: Even/Odd - "TRUE" or Half Pair - "FALSE". For FFT: "TRUE"		
		PAIR		: boolean:=TRUE; --! Bitreverse mode: Even/Odd - "TRUE" or Half Pair - "FALSE". For FFT: "TRUE"		
		STAGES		: integer:=4; --! FFT stages
		Nwidth		: integer:=16 --! Data width		
	);
	port(								
		clk  		: in  std_logic; --! Clock
		reset 		: in  std_logic; --! Reset		

		di_dt		: in  std_logic_vector(Nwidth-1 downto 0); --! Data input
		di_en		: in  std_logic; --! Data enable

		do_dt		: out std_logic_vector(Nwidth-1 downto 0); --! Data output	
		do_vl		: out std_logic --! Data valid		
	);	
end fp_bitrev_ord;

architecture fp_bitrev_ord of fp_bitrev_ord is

signal addra			: std_logic_vector(STAGES-1 downto 0);
signal addrx			: std_logic_vector(STAGES-1 downto 0);
signal addrb			: std_logic_vector(STAGES-1 downto 0);
signal cnt				: std_logic_vector(STAGES downto 0);	  

signal ram_di0			: std_logic_vector(Nwidth-1 downto 0);
signal ram_do0			: std_logic_vector(Nwidth-1 downto 0);
signal ram_di1			: std_logic_vector(Nwidth-1 downto 0);
signal ram_do1			: std_logic_vector(Nwidth-1 downto 0);

signal we0, we1			: std_logic;
signal rd0, rd1			: std_logic;
signal vl0, vl1			: std_logic;
signal cntz				: std_logic_vector(1 downto 0);
signal dmux				: std_logic;
signal valid			: std_logic;

function bit_pair(Len: integer; Dat: std_logic_vector) return std_logic_vector is
	variable Tmp : std_logic_vector(Len-1 downto 0);
begin 
	Tmp(Len-1) :=  Dat(0);
	for ii in 1 to Len-1 loop
		Tmp(ii-1) := Dat(ii);
	end loop;
	return Tmp; 
end function; 

function bit_pair2(Len: integer; Dat: std_logic_vector) return std_logic_vector is
	variable Tmp : std_logic_vector(Len-1 downto 0);
begin 
	Tmp(0) :=  Dat(Len-1);
	for ii in 1 to Len-1 loop
		Tmp(ii) := Dat(ii-1);
	end loop;
	return Tmp; 
end function; 

signal cnt1st		: std_logic_vector(STAGES downto 0);	

begin

-- Data out and valid proc --	
pr_cnt1: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '1') then
			cnt1st <= (others => '0');		
		else		
			if (valid = '1') then
				if (cnt1st(STAGES) = '0') then
					cnt1st <= cnt1st + '1';
				end if;
			end if;	
		end if;
	end if;
end process;	
	
xFWT_TRUE: if (FWT = TRUE) generate
	addra <= addrx;
	addrb <= bit_pair(STAGES, addrx);
end generate;
xFWT_FALSE: if (FWT = FALSE) generate
--	xPAIR_FALSE: if (PAIR = FALSE) generate
--		addra <= addrx;   
--		addrb <= addrx;
--	end generate;	
	xPAIR_FALSE: if (PAIR = FALSE) generate
		addra <= addrx;   
		addrb <= addrx;
	end generate;

	xPAIR_TRUE: if (PAIR = TRUE) generate
		addra <= bit_pair2(STAGES, addrx);
		G_BR_ADDR: for ii in 0 to STAGES-1 generate	   
			addrb(ii) <= cnt(STAGES-1-ii) after td when rising_edge(clk);
		end generate;
	end generate;	
	
end generate;	

addrx <= cnt(STAGES-1 downto 0) after td when rising_edge(clk);
--addrb <= cnt(STAGES-1 downto 0) after td when rising_edge(clk);

-------------------------------------------------------------------------------

-- Data out and valid proc --	
pr_dout: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '1') then
			do_dt <= (others => '0') after td;		
		else
			if (dmux = '0') then
				do_dt <= ram_do1 after td;
			else
				do_dt <= ram_do0 after td;
			end if;	
		end if;
	end if;
end process;	
do_vl <= valid and cnt1st(STAGES) after td when rising_edge(clk);
		
-- Common proc --	
ram_di0 <= di_dt when rising_edge(clk);
ram_di1 <= di_dt when rising_edge(clk);	
	
pr_cnt: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '1') then
			cnt <= (others => '0') after td;		
		else
			if (di_en = '1') then
				cnt <= cnt + '1' after td;
			end if;	
		end if;
	end if;
end process;
cntz <= cntz(0) & cnt(STAGES) after td when rising_edge(clk);

pr_we: process(clk) is
begin
	if rising_edge(clk) then
		if (reset = '1') then
			we0 <= '0' after td;
			we1 <= '0' after td;	
		else
			we0 <= not cnt(STAGES) and di_en after td;
			we1 <= cnt(STAGES) and di_en after td;
		end if;
	end if;
end process;

-- Read / Address proc --	
rd0 <= we1;
rd1 <= we0;

vl0 <= we1 after td when rising_edge(clk);
vl1 <= we0 after td when rising_edge(clk);

--addrx <= cnt(STAGES-1 downto 0) after td when rising_edge(clk);
----addrb <= cnt(STAGES-1 downto 0) after td when rising_edge(clk);
--addrb <= bit_pair(STAGES, addrx);
--G_BR_ADDR: for ii in 0 to STAGES-1 generate	   
----	addrb(ii) <= cnt(STAGES-1-ii) after td when rising_edge(clk);
--end generate;

-- RAMB generator --	
G_LOW_STAGE: if (STAGES < 9) generate	
	type ram_t is array(0 to 2**(STAGES)-1) of std_logic;--_vector(31 downto 0);	
begin
	X_GEN_SRL0: for ii in 0 to Nwidth-1 generate
	begin
		pr_srlram0: process(clk) is
			variable ram0 : ram_t;
		begin
			if (clk'event and clk = '1') then
				if (we0 = '1') then
					ram0(conv_integer(addra)) := ram_di0(ii);
				end if;
				--ram_do0 <= ram0(conv_integer(addra)) after td; -- signle port
				if (rd0 = '1') then
					ram_do0(ii) <= ram0(conv_integer(addrb)) after td; -- dual port
				end if;
			end if;	
		end process;
		
		pr_srlram1: process(clk) is
			variable ram1 : ram_t;
		begin
			if (clk'event and clk = '1') then
				if (we1 = '1') then
					ram1(conv_integer(addra)) := ram_di1(ii);
				end if;
				--ram_do1 <= ram1(conv_integer(addra)) after td; -- signle port
				if (rd1 = '1') then
					ram_do1(ii) <= ram1(conv_integer(addrb)) after td; -- dual port
				end if;
			end if;	
		end process;		
	end generate;
	
	dmux <= cntz(1);
	valid <= (vl0 or vl1);
end generate; 

G_HIGH_STAGE: if (STAGES >= 9) generate
	type ram_t is array(0 to 2**(STAGES)-1) of std_logic_vector(Nwidth-1 downto 0);
	signal ram0, ram1			: ram_t;
	signal dout0, dout1			: std_logic_vector(Nwidth-1 downto 0);

	attribute ram_style			: string;
	attribute ram_style of RAM0 : signal is "block";	
    attribute ram_style of RAM1 : signal is "block";  
	
begin
	PR_RAMB0: process(clk) is
	begin
		if (clk'event and clk = '1') then
			ram_do0 <= dout0 after td;
			if (reset = '1') then 
				dout0 <= (others => '0');
			else
				if (rd0 = '1') then
					dout0 <= ram0(conv_integer(addrb)) after td; -- dual port
				end if;
			end if;				
			if (we0 = '1') then
				ram0(conv_integer(addra)) <= ram_di0;
			end if;
		end if;	
	end process;

	PR_RAMB1: process(clk) is
	begin
		if (clk'event and clk = '1') then
			ram_do1 <= dout1 after td;
			if (reset = '1') then
				dout1 <= (others => '0');
			else
				if (rd1 = '1') then
					dout1 <= ram1(conv_integer(addrb)) after td; -- dual port
				end if;
			end if;				
			if (we1 = '1') then
				ram1(conv_integer(addra)) <= ram_di1;
			end if;
		end if;	
	end process;
	
	dmux <= cntz(1) after td when rising_edge(clk);
	valid <= (vl0 or vl1) after td when rising_edge(clk);
end generate;

end fp_bitrev_ord;