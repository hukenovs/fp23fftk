# Floating point (FP23) FFT/IFFT cores

This project contains **fully pipelined** floating-point FFT/IFFT cores for Xilinx FPGA, Scheme: Radix-2, Decimation in frequency and decimation in time;    
Integer data type and twiddles with configurable data width. 
**Code language** - VHDL, Verilog 
**Vendor**: Xilinx, 6/7-series, Ultrascale, Ultrascale+;  

License: GNU GPL 3.0. 

### Main information

| **Title**         | Universal floating point FFT cores (Xilinx FPGAs) |
| -- | -- |
| **Author**        | Alexander Kapitanov                        |
| **Contact**       | <hidden>                                   |
| **Project lang**  | VHDL, Verilog                              |
| **Vendor**        | Xilinx: 6/7-series, Ultrascale, US+        |
| **Release Date**  | 02 Feb 2015                                |
| **Last Update**   | 27 Jun 2019                                |

#### Floating-point (custom format)

Floating point 23-bit vector (optimized for FPGAs): 
- EXPONENT - 6-bits 
- SIGN - 1-bit 
- MANTISSA - 16+1 bits 
'1' means hidden bit for normalized floating-point values; 

#### Math: 
**A = (-1)^sign(A) * 2^(exp(A)-31) * mant(A)**

### List of complements:
- FFTs:
   * fp23_fftNk  – main core - Floating-point FFT, Radix-2, DIF, input flow - natural, output flow - bit-reversed. 
   * fp23_ifftNk – main core - Floating-point FFT, Radix-2, DIT, input flow - bit-reversed, output flow - natural.

- Butterflies:
   * fp23_bfly_fwd – Floating-point butterfly Radix-2, decimation in frequency, 
   * fp23_ibfly_inv – Floating-point butterfly Radix-2, decimation in time. 

- Math (in fp23):
   * fp23_addsub – adder / substractor, 
   * fp23_addsub_dbl – adder and substractor, 
   * fp23_fix2float – int16 to fp23 converter, 
   * fp23_float2fix – fp23 to int16 converter,
   * fp23_mult – multiplier,
   * fp23_cmult – complex multiplier.

- Delay line:
  * fp_delay_line – main delay line, cross-commutation data between butterflies,
  * fp23fft_align_data – data and twiddle factor alignment for butterflies in FFT core,
  * fp23ifft_align_data – data and twiddle factor alignment for butterflies in IFFT core.

- Twiddles:
  * rom_twiddle_int – 1/4-periodic signal, twiddle factor generator based on memory and sometimes uses DSP48 units for large FFTs
  * row_twiddle_tay – twiddle factor generator which used Taylor scheme for calculation twiddles.

- Buffers:
  * fp_Ndelay_in  – input delay line (for simple flow with 1 data word in clock cycle),
  * fp_Ndelay_out – output delay line (for simple flow with 1 data word in clock cycle),
  * fp_bitrev_ord – converter data from bit-reverse to natural order.

### Fast Convolution:
- FFTs:
   * fp23_fconv_core  – main core: Input buffer, Lin Fast Convolution, Output buffer, Support function,
   * fp23_linconv_dbl – Forward FFT, Inverse FFT, Complex multiplier etc,
   * fp23_fftNk2_core - Double Path Forward / Inverse Floating-point FFT, Radix-2, DIF/DIT,

- Buffers:
  * iobuf_fft_hlf2 – delay second part of data for Linear Fast Convolution, 
  * iobuf_fft_int2 – delay first part of data for Linear Fast Convolution, 
  * inbuf_fastconv_int2 – Input buffer for linear fast convolution and interleave-2 data, 
  * int_delay_wrap - delay line for wrap-mode. You don't need collecting NFFT data words. Fully pipelined.
  * fp23_sfunc_dbl - Support function: two buffers 0/1 can store filter responce into freq domain.

#### How to check Fast Convolution HDL model:
- Create Vivado project *example.xpr*, select 7-series or Ultrascale/+ FPGA.
- Add sources from */src* directory to your project.
- Set testbench file as top for simulation from */src/testbench* dir directory
- Run Octave / MATLAB *.m* file from *math/* directory. Set **NFFT** and other signal parameters. Change input signal or use my model. After this you will get test file *test_signal.dat* with complex signal.
- Run simulation into Vivado / Aldec Active-HDL / ModelSim. Set time of simulation > 100 us. For N > 32K set 500 us or more.
- Return to Octave / MATLAB and run *.m* script again. 
- Compare Fast Convolution: an ideal result in double prec. and HDL results (fp23).


### Link (Russian collaborative IT blog)
  * https://habr.com/users/capitanov/
  
### Authors:
  * Kapitanov Alexander  
  
### First Release:
  * 2015/02/02
