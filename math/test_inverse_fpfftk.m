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
NFFT = 2^8;            

Asig = 32767;
Fsig = 1;
B = 0.85;
% For testing FORWARD and INVERSE FFT: FWT
STAGE = log2(NFFT);

%% -------------------------------------------------------------------------- %%
% ---------------- 0: CREATE INPUT DATA FOR CPP/RTL -------------------------- % 
%% -------------------------------------------------------------------------- %%
F = 2;
for i = 0:NFFT
  Dre(i+1,1) = Asig * cos(Fsig*i* 2*pi/NFFT);
  Dim(i+1,1) = Asig * sin(Fsig*i* 2*pi/NFFT);

  Dre(i+1,1) = round(Asig * cos((Fsig*i + B*i*i/2) * 2*pi/NFFT) * sin(i * pi / NFFT));
  Dim(i+1,1) = round(Asig * sin((Fsig*i + B*i*i/2) * 2*pi/NFFT) * sin(i * pi / NFFT));
end

% Adding noise to real signal 
SNR = -10;

DatRe = awgn(Dre, SNR, 0, 1);     
DatIm = awgn(Dim, SNR, 0, 1);     

Mre = max(abs(DatRe));
Mim = max(abs(DatIm));
Mdt = max(Mre, Mim);

DSVRe = round(((2^15 - 1)/Mdt)*DatRe);
DSVIm = round(((2^15 - 1)/Mdt)*DatIm);

DatIn(:,1) = DSVRe;
DatIn(:,2) = DSVIm;

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


DatX = DSVRe + 1j*DatIm;
DatFFT = fft(DatX);

DtFFT(:,1) = real(DatFFT);
DtFFT(:,2) = imag(DatFFT);

figure(1) % Plot loaded data in Time Domain
for i = 1:2
  subplot(2,1,1)
  plot(DatIn(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0 i-1])
  grid on; hold on; axis tight;  
  title(['Input signal'])    
    
  subplot(2,1,2)
  plot(DtFFT(1:NFFT,i), '-', 'LineWidth', 1, 'Color',[2-i 0 i-1])
  grid on; hold on; axis tight;  
  title(['FFT data'])   

end

