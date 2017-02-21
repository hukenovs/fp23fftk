// fp_conv.cpp : Defines the entry point for the console application.

#include <math.h>
#include <conio.h>
#include "stdafx.h"
#include <cstdlib>

#include "fp_op.h"
#include <cstdlib>
#include <cstring>

int _tmain(int argc, _TCHAR* argv[])
{
	// ---------------- LOAD DATA ---------------- //
	char str_re[80] = "H:\\Work\\_MATH\\din_re.dat";
	char str_im[80] = "H:\\Work\\_MATH\\din_im.dat";
	FILE* FFRE = fopen(str_re, "r");
	FILE* FFIM = fopen(str_im, "r");

	int _xsin = 0;
	int _xcos = 0;
	VarFltst _sin, _cos;
	ComplexVarFltst* _CF = (ComplexVarFltst*)malloc(N_FFT * sizeof(ComplexVarFltst));

	// ---------------- FIX2FLOAT ---------------- //
	for (int ii = 0; ii < (N_FFT); ii++)
	{
			
		fscanf(FFRE, "%d", &_xcos);
		fscanf(FFIM, "%d", &_xsin);
		{
			int __sscos = fix2float23(_xcos);
			int __sssin = fix2float23(_xsin);
			_cos = float_expand23(__sscos);
			_sin = float_expand23(__sssin);
			
			_CF[ii].re = _cos;
			_CF[ii].im = _sin;
		}
	}
	fclose(FFRE);
	fclose(FFIM);

	// ---------------- CALCULATE ---------------- //
	int g_stages = _log2(N_FFT);
	ComplexVarFltst* _Ax = (ComplexVarFltst*)malloc(N_FFT * sizeof(ComplexVarFltst));
	ComplexVarFltst* _Bx = (ComplexVarFltst*)malloc(N_FFT * sizeof(ComplexVarFltst));



	// ---------------- FORWARD FFT ---------------- //
	FLOAT_FFT(_CF, _Ax, _Bx, g_stages, 'r', 'f');
	// ---------------- INVERSE FFT ---------------- //
	FLOAT_FFT(_CF, _Ax, _Bx, g_stages, 'r', 'i');
	// --------------------------------------------- //
	


	// ---------------- OUTPUT DATA ---------------- //	
	ComplexInt* _T24 = (ComplexInt*)malloc(N_FFT * sizeof(ComplexInt));
	FILE* FTX = fopen("H:\\Work\\_MATH\\fp_cpp.dat", "wt");
	for (int ii = 0; ii < N_FFT; ii++)
	{
		int Rev_ii = Reverse[ii];
		int _re, _im;
		
		_re = float_collapse23(_CF[ii].re);
		_im = float_collapse23(_CF[ii].im);

		_re = float2fix23(_re, SCALE);
		_im = float2fix23(_im, SCALE);
		_T24[ii].re = _re;
		_T24[ii].im = _im;
		fprintf(FTX, "%d    %d\n", _T24[ii].re, _T24[ii].im);
		//fprintf(FTX, "%d    %d    %d    \n", _T24[ii].re, _T24[ii].im, Rev_ii);
	}
	fclose(FTX);

}