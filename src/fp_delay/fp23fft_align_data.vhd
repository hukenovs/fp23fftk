-------------------------------------------------------------------------------
--
-- Title       : FFT_logic
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     :
--
-- Description : fp23fft_align_data
--
-- Version 1.0 : Delay correction for TWIDDLE factor and BFLYes 
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--  The MIT License (MIT)
--  Copyright (c) 2019 Kapitanov Alexander
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

library work;
use work.fp_m1_pkg.fp23_complex;

entity fp23fft_align_data is 
    generic ( 
        NFFT            : integer:=16;  --! FFT lenght
        STAGE           : integer:=0;   --! FFT stage
        USE_SCALE       : boolean:=true --! Use Taylor for twiddles
    );
    port (
        clk             : in  std_logic; --! Clock
        ---- DATA FROM BUTTERFLY ----
        dt_ia           : in  fp23_complex; --! Input data (A)
        dt_ib           : in  fp23_complex; --! Input data (B)
        ---- DATA TO BUTTERFLY ----
        dt_xa           : out fp23_complex; --! Output data (A)
        dt_xb           : out fp23_complex; --! Output data (B)
        ---- ENABLEs FROM/TO BUTTERFLY ----
        fl_en           : in  std_logic;
        fl_vl           : out std_logic;
        tw_vl           : out std_logic
    );
end fp23fft_align_data;

architecture fp23fft_align_data of fp23fft_align_data is

begin

X_TLR_NO: if (USE_SCALE = TRUE) generate
    tw_vl <= fl_en;
    dt_xa <= dt_ia;
    dt_xb <= dt_ib;
    fl_vl <= fl_en;
end generate;

X_TLR_YES: if (USE_SCALE = FALSE) generate

    SHORT_WW: if (NFFT-13 < STAGE) generate
        tw_vl <= fl_en;
        dt_xa <= dt_ia;
        dt_xb <= dt_ib;
        fl_vl <= fl_en;
    end generate;

    LONG_WW: if (NFFT-13 >= STAGE) generate
        signal fl_enz     : std_logic_vector(13 downto 0);
        type complex_fp23xM is array (13 downto 0) of fp23_complex;
        signal dt_iaz     : complex_fp23xM;
        signal dt_ibz     : complex_fp23xM;
    begin       
        tw_vl <= fl_en;
        fl_vl <= fl_enz(fl_enz'left);
        dt_xa <= dt_iaz(dt_iaz'left);
        dt_xb <= dt_ibz(dt_ibz'left);

        dt_iaz <= dt_iaz(dt_iaz'left-1 downto 0) & dt_ia when rising_edge(clk);
        dt_ibz <= dt_ibz(dt_ibz'left-1 downto 0) & dt_ib when rising_edge(clk);
        fl_enz <= fl_enz(fl_enz'left-1 downto 0) & fl_en when rising_edge(clk); 

    end generate;
end generate;

end fp23fft_align_data; 