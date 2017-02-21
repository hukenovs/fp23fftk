%% -----------------------------------------------------------------------
%
% Title       : test.m
% Author      : Alexander Kapitanov	
% Company     : Insys
% E-mail      : sallador@bk.ru 
% Version     : 1.0	 
%
%-------------------------------------------------------------------------
%
% Description : 
%    Top level for testing FPFFTK model
%
%-------------------------------------------------------------------------
%
% Version     : 1.0 
% Date        : 2016.11.11 
%
%-------------------------------------------------------------------------	   

% Preparing to work
close all;
clear all;

set(0, 'DefaultAxesFontSize', 14, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 14, 'DefaultTextFontName', 'Times New Roman'); 

% Settings
NFFT = 2^12;            % Sampling Frequency
t = 0:1/NFFT:1-1/NFFT;  % Time vector #1
tt = 1:NFFT;            % Time vector #2
VAL_SHIFT = 0;

Asig = (2^14)-1;
Fsig = 16;
F0 = 0;
Fm = NFFT/2;
B = Fm / NFFT;
Ffm = 1;
% For testing FORWARD and INVERSE FFT: FWT

STAGE = log2(NFFT);

%% -------------------------------------------------------------------------- %%
% ---------------- 0: CREATE INPUT DATA FOR CPP/RTL -------------------------- % 
%% -------------------------------------------------------------------------- %%

for i = 1:NFFT
    Dre(i,1) = round(Asig * cos(F0 + (Fsig*i + B*i*i/2) * 2*pi/NFFT) * sin(i * Ffm * pi / NFFT));
    Dim(i,1) = round(Asig * sin(F0 + (Fsig*i + B*i*i/2) * 2*pi/NFFT) * sin(i * Ffm * pi / NFFT));    
%    Dre(i,1) = i-1;
%    Dim(i,1) = i-1;    
end

for i = 1:NFFT
    if (i > VAL_SHIFT)
        Xre(i,1) = Dre(i-VAL_SHIFT, 1);
        Xim(i,1) = Dim(i-VAL_SHIFT, 1);
    else
        Xre(i,1) = Dre(NFFT-VAL_SHIFT+i, 1);
        Xim(i,1) = Dim(NFFT-VAL_SHIFT+i, 1);   
    end
end
Dre = Xre;
Dim = Xim;

% Adding noise to real signal 
SNR = -50;
SEED = 1;

DatRe = awgn(Dre, SNR, 0, SEED);     
DatIm = awgn(Dim, SNR, 0, SEED);     

DSVRe = round(DatRe);
DSVIm = round(DatIm);

% Save data to file
fid = fopen ("din_re.dat", "w");
for i = 1:NFFT
    fprintf(fid, "%d \n", DSVRe(i,1));
end
fclose(fid);

fid = fopen ("din_im.dat", "w");
for i = 1:NFFT
    fprintf(fid, "%d \n", DSVIm(i,1));
end
fclose(fid);

Din(:,1) = DSVRe;
Din(:,2) = DSVIm;

figure(1) % Plot loaded data in Time Domain
for i = 1:2
    subplot(2,1,i)
    plot(tt(1:NFFT), Din(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    hold on
    axis tight      
    title(['Test Data in Time Domain'])   
end

%% -------------------------------------------------------------------------- %%
% ---------------- 1: LOAD MODEL DATA FROM C++ CORE -------------------------- % 
%% -------------------------------------------------------------------------- %%
DT_OPT = load ("C:/share/fpfftk/fp_octave.dat");
for i = 1:NFFT
    AXX_RE(i,1) = DT_OPT(i,1);
    AXX_IM(i,1) = DT_OPT(i,2);  
    %NATT(i,1) = DT_OPT(i,3);    
end
%DT_OP(:,1) = bitrevorder(DT_OPT(:,1));
%DT_OP(:,2) = bitrevorder(DT_OPT(:,2));
DT_OP(:,1) = DT_OPT(:,1);
DT_OP(:,2) = DT_OPT(:,2);

%figure(1) % Plot loaded data in Freq Domain
%for i = 1:2
%    subplot(2,1,i)
%    plot(tt(1:NFFT), DT_OP(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
%    grid on
%    axis tight 
%    title(['FP CPP TEST (C++ MODEL)'])  
%end

%% -------------------------------------------------------------------------- %%
% ---------------- 2:  LOAD RTL DATA (FROM HDL CORE) ------------------------- % 
%% -------------------------------------------------------------------------- %%

DATA = load ("C:/share/fpfftk/rtl_out.dat");
for i = 1:NFFT
    RTL_DT(i,1) = DATA(i,1);
    RTL_DT(i,2) = DATA(i,2);
end

figure(2) 
for i = 1:2
    subplot(3,2,i)
    plot(tt(1:NFFT), DT_OP(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    hold on
    axis tight 
    title(['FP CPP DATA']) 
end

figure(2) 
for i = 1:2
    subplot(3,2,i+2)
    plot(tt(1:NFFT), RTL_DT(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    hold on
    axis tight 
    title(['FP RTL DATA']) 
end

figure(2) 
for i = 1:2
    subplot(3,2,i+4)
    plot(tt(1:NFFT), RTL_DT(1:NFFT,i)-DT_OP(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    axis tight 
    title(['FP DIFF TEST']) 
end

%% -------------------------------------------------------------------------- %%
% ---------------- 3:  COMPL DATA (TEST MATH SIGNAL) ------------------------- % 
%% -------------------------------------------------------------------------- %%

% Combine new data to matrix
Din(:,1) = DSVRe;
Din(:,2) = DSVIm;

figure(4) % Plot loaded data in Time Domain
for i = 1:2
    subplot(2,2,i)
    plot(tt(1:NFFT), Din(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    axis tight      
    title(['Test Data in Time Domain'])   
end

figure(4) % Plot loaded data in Time Domain
for i = 1:2
    subplot(2,2,i+2)
    plot(tt(1:NFFT), Din(1:NFFT,i)-RTL_DT(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0  i-1])
    grid on
    axis tight      
    title(['Difference FP23 vs FP32 IEEE-754'])   
end