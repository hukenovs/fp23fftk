%% -----------------------------------------------------------------------
%
% Title       : test_fastconv_chirp.m
% Author      : Alexander Kapitanov	
% Project     : Fast Convolution
% Company     : 
% E-mail      : sallador@bk.ru 
%
%-------------------------------------------------------------------------
%
% Description : 
%    Top level for testing HDL Fast Convolution Floating-point FP23 format
%
%-------------------------------------------------------------------------
%
% How to check Fast Convolution HDL model:
%
% 1. Create *.xpr (Vivado project), select 7-series or Ultrascale FPGA.
% 2. Add sources from /src to your project.
% 3. Set testbench file as top for simulation from /src/testbench dir
% 4. Run *.m file from math/ directory. Set NFFT and other signal parameters.
%      Change input signal or use my model. 
%      After this you will get test file "test_signal.dat" with complex signal.
% 5. Run simulation into Vivado / Aldec Active-HDL / ModelSim. 
%      Set time of simulation > 100 us. For NFFT > 32K set 500 us or more.
% 6. Return to Octave/MATLAB and run *.m script again. 
% 7. Compare an ideal result of Fast Convolution (double) and HDL results (fp23).
%
%-------------------------------------------------------------------------	   

% Preparing to work
close all;
clear all;

set(0, 'DefaultAxesFontSize', 14, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 14, 'DefaultTextFontName', 'Times New Roman'); 

% Settings
NFFT = 2^8;             % Sampling Frequency
SIG_MAGN = 2^15-1;      % Magnitude
SIG_FREQ = 9;           % Lin part of Chirp freq OR frequency for sine wave
SIG_BETA = 0.85;        % Chirp 'Base'
SIG_CUTS = 2;           % Cut the signal 
SNR = -75;              % Signal-noise ratio

%% -------------------------------------------------------------------------- %%
% ---------------- 0: CREATE INPUT DATA FOR CPP/RTL -------------------------- % 
%% -------------------------------------------------------------------------- %%
DATA_RE = zeros(NFFT,1);
DATA_IM = zeros(NFFT,1);
for ii = 0:NFFT-1
  % Cutted chirp signal
  if (ii < NFFT/SIG_CUTS)
    DATA_RE(ii+1,1) = round(
      SIG_MAGN * cos(SIG_BETA*ii*ii * SIG_CUTS*pi/NFFT) * 
      abs(sin(SIG_CUTS*ii*pi/NFFT))
    );
    DATA_IM(ii+1,1) = round(
      SIG_MAGN * sin(SIG_BETA*ii*ii * SIG_CUTS*pi/NFFT) * 
      abs(sin(SIG_CUTS*ii*pi/NFFT))
    );    
  else
    DATA_RE(ii+1,1) = 0;
    DATA_IM(ii+1,1) = 0;
  end
  
  % Harmonic signal
  DATA_RE(ii+1,1) = round(SIG_MAGN * cos(SIG_FREQ*ii*2*pi/NFFT));
  DATA_IM(ii+1,1) = round(SIG_MAGN * sin(SIG_FREQ*ii*2*pi/NFFT)); 
  
  % True chirp signal
  DATA_RE(ii+1,1) = round(
    SIG_MAGN * cos((SIG_FREQ*ii + SIG_BETA*ii*ii/2) * 2*pi/NFFT) * 
    sin(ii*1*pi/NFFT)
   );
  DATA_IM(ii+1,1) = round(
    SIG_MAGN * sin((SIG_FREQ*ii + SIG_BETA*ii*ii/2) * 2*pi/NFFT) * 
    sin(ii*1*pi/NFFT)
   );     
end

% Add noise
DATA_SNR(:,1) = round(awgn(DATA_RE, SNR, 0, 2));     
DATA_SNR(:,2) = round(awgn(DATA_IM, SNR, 0, 2));     

% Find max value
MAXDT = max(max(abs(DATA_SNR(:,1))), max(abs(DATA_SNR(:,2))));

DATA_IN = round((SIG_MAGN/MAXDT) * DATA_SNR);
DT_IN = DATA_IN(:,1) + 1j*DATA_IN(:,2);

% Save data to file
fid = fopen ("test_signal.dat", "w");
for ii = 1:NFFT/2
  fprintf(fid, "%d %d %d %d\n", DATA_IN(2*ii-1,1), DATA_IN(2*ii,1), DATA_IN(2*ii-1,2), DATA_IN(2*ii,2));
end
fclose(fid);

% Calculate Forward FFT
DT_FFT = fft(DATA_IN(:,1) + 1j*DATA_IN(:,2));
DATA_FFT(:,1) = real(DT_FFT);
DATA_FFT(:,2) = imag(DT_FFT);

%% -------------------------------------------------------------------------- %%
% ---------------- 2:  SUPPORT FUNCTION FOR FC-FILTER ------------------------ % 
%% -------------------------------------------------------------------------- %%
NFIR  = NFFT/2;        % Number of taps for FIR filter = NFFT/2
BETA  = 8;             % Add window: Beta (Kaiser)

WIND = kaiser(NFIR+1, BETA);
% Filter: "low", "high", "stop", "pass", "bandpass", "DC-0", or "DC-1"
FIR_HC = fir1(NFIR, [0.1, 0.7], 'pass', WIND);

FIR_RE = real(FIR_HC);
FIR_IM = imag(FIR_HC);
% Chirp signal for FC:

FIR_RE = zeros(NFFT,1);
FIR_IM = zeros(NFFT,1);
for ii = 0:NFFT-1
  FIR_RE(ii+1,1) = cos((SIG_BETA*ii*ii/2) * 2*pi/NFFT) * sin(ii*1*pi/NFFT);
  FIR_IM(ii+1,1) = sin((SIG_BETA*ii*ii/2) * 2*pi/NFFT) * sin(ii*1*pi/NFFT);     
end

% Fast convolution (time method)
FIR_HC = FIR_RE + 1j*FIR_IM;
FIR_CJ = (conv(DT_IN, (FIR_RE - 1j*FIR_IM)));
DATA_FC(:,1) = real(FIR_CJ);
DATA_FC(:,2) = imag(FIR_CJ);

% FFT for FIR filter responce
DATA_SF = fft(FIR_HC, NFFT);

% Preparing data to int16
SF_INT(:,1) = round( 32767 * real(DATA_SF)/max(abs(real(DATA_SF))));
SF_INT(:,2) = round(-32767 * imag(DATA_SF)/max(abs(imag(DATA_SF))));

% Write FC0/1 to file: {Im(i+N/2) Re(i+N/2) Im(i) Re(i)}, i - 0..N/2
fid = fopen ("sf0_x64.dat", "w");
for ii = 1:NFFT/2
  fprintf(fid, "%d %d %d %d\n", SF_INT(ii+NFFT/2,2), SF_INT(ii+NFFT/2,1), SF_INT(ii,2), SF_INT(ii,1));
  % fprintf(fid, "%d %d %d %d\n", i+NFFT/2, i+NFFT/2, i, i);
end
fclose(fid);

fid = fopen ("sf1_x64.dat", "w");
for ii = 1:NFFT/2
  fprintf(fid, "%d %d %d %d\n",  0, 32767, 0, 32767);
end
fclose(fid);

DT_SF = real(DATA_SF) - 1j*imag(DATA_SF);
DT_CM = DT_FFT .* DT_SF;
DATA_CM(:,1) = real(DT_CM);
DATA_CM(:,2) = imag(DT_CM);

DT_IFFT = ifft(DT_CM);
DATA_IFFT(:,1) = real(DT_IFFT) / max(abs(real(DT_IFFT)));
DATA_IFFT(:,2) = imag(DT_IFFT) / max(abs(imag(DT_IFFT)));

%% -------------------------------------------------------------------------- %%
% ---------------- 3:  PLOT RESULTS ------------------------------------------ % 
%% -------------------------------------------------------------------------- %%
figure(1, 'name', 'Check FFT');
subplot(5,1,1)
plot(DATA_SNR(:,1), '-', 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(DATA_SNR(:,2), '-', 'LineWidth', 1.0, 'Color', [0 0 1]);
grid on;
axis tight;
title(['Input signal']);

subplot(5,1,2)
plot(DATA_FC(:,1), '-', 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(DATA_FC(:,2), '-', 'LineWidth', 1.0, 'Color', [0 0 1]);
grid on;
axis tight;
title(['Time: Convolution']);

subplot(5,1,3)
plot(DATA_IFFT(:,1), '-', 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(DATA_IFFT(:,2), '-', 'LineWidth', 1.0, 'Color', [0 0 1]);
grid on;
axis tight;
title(['Freq: Fast Convolution']);

%% -------------------------------------------------------------------------- %%
% ---------------- 4:  READ DATA FROM HDL MODEL ------------------------------ % 
%% -------------------------------------------------------------------------- %%

% FORWARD FFT:
DT_HDL = load("test_result.dat");

LIN = 1;
for i = 1:NFFT/2
  AX_RE(i,1) = DT_HDL(i+NFFT*LIN,1);
  AX_IM(i,1) = DT_HDL(i+NFFT*LIN,2);
  BX_RE(i,1) = DT_HDL(i+NFFT*LIN,3);
  BX_IM(i,1) = DT_HDL(i+NFFT*LIN,4);
end

% Interleave-2 mode
for ii = 1:NFFT/2
  AI_IN(2*ii-1,1) = AX_RE(ii,1);
  AI_IN(2*ii-0,1) = BX_RE(ii,1);
  AQ_IN(2*ii-1,1) = AX_IM(ii,1);
  AQ_IN(2*ii-0,1) = BX_IM(ii,1);
end

DATA_HDL(:,1) = AI_IN;
DATA_HDL(:,2) = AQ_IN;

% Find diff error:
DT_BIT = 2^8;     % Plot Y: number of bits
DT_ERR(:,1) = (2^15)*abs((AI_IN/max(abs(AI_IN)) - DATA_IFFT(:,1)));
DT_ERR(:,2) = (2^15)*abs((AQ_IN/max(abs(AQ_IN)) - DATA_IFFT(:,2)));


figure(1, 'name', 'Check FFT');
subplot(5,1,4)
plot(DATA_HDL(:,1), '-', 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(DATA_HDL(:,2), '-', 'LineWidth', 1.0, 'Color', [0 0 1]);
grid on;
axis tight;
title(['HDL: Result Data']);

subplot(5,1,5)
plot(DT_ERR(:,1), '-', 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(DT_ERR(:,2), '-', 'LineWidth', 1.0, 'Color', [0 0 1]);
grid on;
axis([1 NFFT 0 DT_BIT]);
title(['Error (Ideal vs. HDL)']);
