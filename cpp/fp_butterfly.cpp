#include <iostream>
#include "stdafx.h"
#include <stdio.h>
#include <math.h>
#include "fp_op.h"
#include <cstdlib>
#include <cstring>

void ButterflyFP (ComplexVarFltst *FA, ComplexVarFltst *FB, ComplexVarFltst *FcoeArr, int aa, int bb, int ww, int stage, char decim, int _use)
{
	// LOAD DATA IN
	VarFltst A_RE = (FA[aa].re);		VarFltst A_IM = (FA[aa].im);    
	VarFltst B_RE = (FB[bb].re);		VarFltst B_IM = (FB[bb].im);    
	VarFltst W_RE = (FcoeArr[ww].re);	VarFltst W_IM = (FcoeArr[ww].im); 

	VarFltst X_RE; VarFltst X_IM;
	VarFltst Y_RE; VarFltst Y_IM; 

	if (_use =! 0)
	{
		if (decim == 'f') // Decimation in frequency
		{	
			VarFltst AB_RE;	VarFltst AB_IM;
			VarFltst ABW_RE; VarFltst ABW_IM;		
			VarFltst ABW_RE2; VarFltst ABW_IM2;	
			// X = A+B	
			X_RE = float_add23(A_RE, B_RE, 'a');
			X_IM = float_add23(A_IM, B_IM, 'a');

			// Y = (A-B)*W
			AB_RE = float_add23(A_RE, B_RE, 's');
			AB_IM = float_add23(A_IM, B_IM, 's');		

			ABW_RE = float_mult23(AB_RE, W_RE);
			ABW_IM = float_mult23(AB_IM, W_IM);

			ABW_RE2 = float_mult23(AB_RE, W_IM);
			ABW_IM2 = float_mult23(AB_IM, W_RE);

			Y_RE = float_add23(ABW_RE, ABW_IM, 's');	
			Y_IM = float_add23(ABW_RE2, ABW_IM2, 'a');	
		}
		else if (decim == 't') // Decimation in time
		{
			VarFltst BW_RE; VarFltst BW_IM;	
			VarFltst ABW_RE; VarFltst ABW_IM;	

			BW_RE = float_mult23(B_RE, W_RE);
			BW_IM = float_mult23(B_IM, W_IM);
			/*ABW_RE = float_add23(BW_RE, BW_IM, 's');*/
			ABW_RE = float_add23(BW_RE, BW_IM, 'a');

			BW_RE = float_mult23(B_RE, W_IM);
			BW_IM = float_mult23(B_IM, W_RE);
			/*ABW_IM = float_add23(BW_RE, BW_IM, 'a');*/
			ABW_IM = float_add23(BW_IM, BW_RE, 's');
			
			// X = A + B*W
			X_RE = float_add23(A_RE, ABW_RE, 'a');
			X_IM = float_add23(A_IM, ABW_IM, 'a');

			// Y = A - B*W
			Y_RE = float_add23(A_RE, ABW_RE, 's');
			Y_IM = float_add23(A_IM, ABW_IM, 's');
		}
		// SAVE DATA OUT
		FA[aa].re = X_RE;	FA[aa].im = X_IM; // You can get normal FFT-iFFT if IM part would be negative !!
		FB[bb].re = Y_RE;	FB[bb].im = Y_IM;
	}
	else
	{
		FA[aa].re = A_RE;   
		FA[aa].im = A_IM;
		FB[bb].re = B_RE;
		FB[bb].im = A_IM;
	}
}

void Twiddle_WW(int _nFFT, ComplexVarFltst* CFPW, int coefs)
{
	int x_stages = _log2(_nFFT / 2);
	VarFltst FPWR, FPWI;

	char str[80];
	char prev[80] = "H:\\Work\\_MATH\\twiddle\\fp23ww_";
	char numb[80];
	itoa(x_stages, numb, 10);

	char last[80] = ".dat";

	strcpy(str, "");
	strcat(str, prev);
	strcat(str, numb);
	
	if (x_stages > 12)
	{
		if (_Tay == 1)
		{
			char tay[80] = "_tay";
			strcat(str, tay);
		}
		else
		{
			char tay[80] = "";
			strcat(str, tay);
		}
	}
	strcat(str, last);

	char str_wr[80];
	char numb_wr[80];
	char last_wr[80] = ".dat";
	itoa(x_stages, numb_wr, 10);
	//char prev_wr[80] = "H:\\Work\\_MATH\\twiddle\\test_";

	//strcpy(str_wr, "");
	//strcat(str_wr, prev_wr);
	//strcat(str_wr, numb_wr);
	//strcat(str_wr, last_wr);

	FILE* FFRD = fopen(str, "r");
	//FILE* FFWR = fopen(str_wr, "wt");
	
	for (int ii = 0; ii < _nFFT / 2; ii++)
	{
		fscanf(FFRD, "%d %d %d %d %d %d", &FPWR.ex, &FPWR.sig, &FPWR.man, &FPWI.ex, &FPWI.sig, &FPWI.man);
		//fprintf(FFWR, "%d %d %d %d %d %d\n", &FPWR.ex, &FPWR.sig, &FPWR.man, &FPWI.ex, &FPWI.sig, &FPWI.man);

		CFPW[ii].re = FPWR;
		CFPW[ii].im = FPWI;
	}
	fclose(FFRD);
	//fclose(FFWR);
}