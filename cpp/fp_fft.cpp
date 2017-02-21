#include "stdafx.h"
#include <stdio.h>
#include <math.h>
#include <cstdlib>

#include "fp_op.h" 

void FLOAT_FFT(ComplexVarFltst* _AF, ComplexVarFltst* _AR, ComplexVarFltst* _BR, int stages, char _nat, char _inv)
{
	int stFFT = _log2(N_FFT);
	
	// TWIDDLE FACTOR: COE DATA
	ComplexVarFltst* CFW = (ComplexVarFltst*)malloc(N_FFT*sizeof(ComplexVarFltst));
	Twiddle_WW(N_FFT, CFW, _inv);

	// test only
	ComplexVarFltst* Ax = (ComplexVarFltst*)malloc((N_FFT/2)*sizeof(ComplexVarFltst));
	ComplexVarFltst* Bx = (ComplexVarFltst*)malloc((N_FFT/2)*sizeof(ComplexVarFltst));
	ComplexVarFltst* Cx = (ComplexVarFltst*)malloc(N_FFT*sizeof(ComplexVarFltst));

	for (int ii=0; ii<N_FFT; ii++)
	{
		Cx[ii].re = _AF[ii].re; 
		Cx[ii].im = _AF[ii].im; 
	}

	if (_inv == 'f')
	{
		printf("\n**** Forward FFT Calculation start! ****\n");
		// **************************** FFT CALCULATE **************************** //
		for (int cnt=1; cnt<stages+1; cnt++)
		{
			printf("Fwd FFT stage: 0x%02X\n", cnt);
			
			int CNT_ii = pow(2.0,(stFFT-cnt)); 
			int CNT_jj = pow(2.0,(cnt-1));
			int counter = 0x0;
			
			for (int jj=0; jj<CNT_jj; jj++)
			{
				for (int ii=0; ii<CNT_ii; ii++)
				{
					int jN = ii+jj*(N_FFT/pow(2.0,cnt-1));
					int iN = N_FFT/(pow(2.0,cnt));
					//printf("%04X\t", ii);

					int _var = jj*N_FFT/pow(2.0,cnt);

					Ax[ii+_var].re = Cx[jN].re; 
					Ax[ii+_var].im = Cx[jN].im;
					Bx[ii+_var].re = Cx[jN+iN].re; 
					Bx[ii+_var].im = Cx[jN+iN].im; 

					ButterflyFP(Ax, Bx, CFW, ii+_var, ii+_var, ii*CNT_jj, cnt, 'f', 1);

					Cx[jN].re = Ax[ii+_var].re; 
					Cx[jN].im = Ax[ii+_var].im; 
					Cx[jN+iN].re = Bx[ii+_var].re;
					Cx[jN+iN].im = Bx[ii+_var].im;
					counter++;
				}
			}
		}
	}
	else if (_inv == 'i')
	{
		printf("\n**** Inverse FFT Calculation start! ****\n");
		// **************************** IFFT CALCULATE **************************** //
		//for (int cnt=1; cnt<stages+1; cnt++)
		for (int cnt = 1; cnt<stages +1; cnt++)
		{
			printf("Inv FFT stage: 0x%02X\n", cnt);
			int CNT_ii = pow(2.0,(cnt-1));
			int CNT_jj = pow(2.0,(stFFT-cnt));	
			int counter = 0x0;
			for (int jj=0; jj<CNT_jj; jj++)
			{
				for (int ii=0; ii<CNT_ii; ii++)
				{
					int jN = ii+jj*(pow(2.0,cnt));
					int iN = pow(2.0,cnt-1);
					//printf("%04X\t", ii);
					int _var = ii*N_FFT/pow(2.0,cnt);

					Ax[jj+_var].re = Cx[jN].re; 
					Ax[jj+_var].im = Cx[jN].im;
					Bx[jj+_var].re = Cx[jN+iN].re; 
					Bx[jj+_var].im = Cx[jN+iN].im; 

					ButterflyFP(Ax, Bx, CFW, jj+_var, jj+_var, ii*CNT_jj, cnt, 't', 1);

					Cx[jN].re = Ax[jj+_var].re; 
					Cx[jN].im = Ax[jj+_var].im; 
					Cx[jN+iN].re = Bx[jj+_var].re;
					Cx[jN+iN].im = Bx[jj+_var].im;
					counter++;
				}
			}
		}
	}
	else
	{
		printf("**** CANNOT CALCULATE FFT/IFFT (SET _INV to 'f' or 'i') ****\n\n");
	}
	printf("**** Calculation finish! ****\n\n");
	
	// BIT-REVERSE
	VarFltst* Na_re = (VarFltst*)malloc((N_FFT/2)*sizeof(VarFltst));
	VarFltst* Na_im = (VarFltst*)malloc((N_FFT/2)*sizeof(VarFltst));
	VarFltst* Nb_re = (VarFltst*)malloc((N_FFT/2)*sizeof(VarFltst));
	VarFltst* Nb_im = (VarFltst*)malloc((N_FFT/2)*sizeof(VarFltst));

	fill_reverse(N_FFT);
	for (int ii=0; ii<N_FFT/2; ii++)
	{
		if (_nat == 'n')
		{
			int Rev_ii = Reverse[ii];
			Na_re[ii] = Ax[Rev_ii].re;
			Na_im[ii] = Ax[Rev_ii].im;
			Nb_re[ii] = Bx[Rev_ii].re;
			Nb_im[ii] = Bx[Rev_ii].im;
		}
		else if (_nat == 'r')
		{
			Na_re[ii] = Ax[ii].re;
			Na_im[ii] = Ax[ii].im;
			Nb_re[ii] = Bx[ii].re;
			Nb_im[ii] = Bx[ii].im;
		}
		else
		{
			printf("Incorrect variable /Reverse/ !!\n");
			break;
		}
	}

	for (int ii=0; ii<N_FFT/2; ii++)
	{
		_AR[ii].re = Na_re[ii];
		_AR[ii].im = Na_im[ii];
		_BR[ii].re = Nb_re[ii];
		_BR[ii].im = Nb_im[ii];
	}

	if (_inv == 'f')
	{
		for (int ii=0; ii<N_FFT/2; ii++)
		{
			_AF[2*ii].re = _AR[ii].re;
			_AF[2*ii].im = _AR[ii].im;
			_AF[2*ii+1].re = _BR[ii].re;
			_AF[2*ii+1].im = _BR[ii].im;
		}
	}
	if (_inv == 'i')
	{
		for (int ii=0; ii<N_FFT/2; ii++)
		{
			_AF[ii].re = _AR[ii].re;
			_AF[ii].im = _AR[ii].im;
			_AF[ii+N_FFT/2].re = _BR[ii].re;
			_AF[ii+N_FFT/2].im = _BR[ii].im;
		}
	}

	free(Na_re); free(Na_im);
	free(Nb_re); free(Nb_im);
	free(Ax); free(Bx); free(Cx);
	free(CFW);

	//printf("DONE FFT F24 NEW!!\n");
}
