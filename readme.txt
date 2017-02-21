-------------------------------------------------------------------------------
--
-- Title       : Readme
-- Design      : fpfftk
-- Author      : Kapitanov
-- Company     : insys.ru
--
-- Description : Floating point FFT/IFFT core used on Xilinx FPGA
--					Supported families: 6/7 series, Ultrascale.
--					Source files: VHDL only!
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

How to check IP Core:

1. Run Matlab/Octave script ( ./math dir): for example test_inverse_fpfftk.m 

You can set some variables:
> NFFT - number of FFT points (from 8 to 256K),
> Asig - signal magnitude (from -2^15 to 2^15-1),
> Fsig - signal frequency,
> F0 - signal phase(starting frequency),
> Fm - mod. frequency for Chirp signal (linear).

I use Chirp signal for testing because it has several advantages. 
You can test all spectrum harmonics when using Chirp signal. 
For sin/cos signal you should make a lot of tests for each harmonics.


2. Create project with C++ source files (I did it in Microsoft VS Community 2015)
3. Build Solution and Run project ( ./cpp dir). 

You can set some variables:

> N_FFT - number of FFT points (from 8 to 256K),
> SCALE - scale factor for float2fix converter (values from 0x0 to 0x3F),
> _Tay - use Taylor algorithm for NFFT > 4K. '1' - use, '0' - don't use.


4. Create HDL project and add source files ( ./src dir) 
5. Run simulation with "fp_test.vhd" file

You can set some variables:

> NFFT - number of FFT points (from 8 to 256K),
> SCALE - scale factor for float2fix converter (values from 0x0 to 0x3F),
> USE_FLY_FFT - '1' - use butterflies in FFT core, '0' - don't use,
> USE_FLY_IFFT - '1' - use butterflies in IFFT core, '0' - don't use,
> USE_SCALE - use Scale/Taylor algorithm for NFFT > 4K. '1' - Scale, '0' - Taylor

6. Run *.m script again and compare results for C++ and RTL model.