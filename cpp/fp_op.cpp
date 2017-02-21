#include <math.h>
#include "fp_op.h"

/*****************************************************************/
int float_collapse23(VarFltst fRes)
{
	int _fp;
	_fp = ((fRes.ex << 16) & 0x003F0000) + ((fRes.sig << 22) & 0x400000) + (fRes.man);
	return _fp;
}
/*****************************************************************/
int float2fix23(int _fp, int _scale)
{
	int _mant = (_fp & 0xFFFF);
	int _exp =  (_fp >> 16) & 0x003F;
	int _sign = (_fp >> 22) & 0x0001;

	int new_exp = (_exp - _scale) & 0xF;
	
	int zero = (_exp - _scale);
// 	if (zero < 0) // ADD THIS TO VHDl CODE
// 		new_exp = 0x0;

	if (_exp == 0)
		_mant = _mant;
	else
		_mant = _mant + 0x10000;

	int mant_16 = (_mant << new_exp) & 0xFFFF0000;
	mant_16 = (mant_16 >> 16) & 0xFFFF;

	int _FIX = 0;
	if (_sign == 1)
		_FIX = -mant_16 -1;// ^ 0xFFFF;
	else
		_FIX = mant_16;

	int exp_hi = zero & 0x30;
	int exp_lo = zero & 0x0F;

	if ((exp_hi) || (exp_lo == 0xF))
	{
		if (_sign == 0)
			_FIX = 0x7FFF;
		else
			_FIX =  -0x7FFF-1;
	}

	if (zero < 0)
		_FIX = 0x0000;

	return _FIX;
}
/*****************************************************************/
int fix2float23(int _fix)
{
	int msb = 1;
	int sign_fp = (_fix >> 15) & 0x1;
	
	int mant_fp = 0;
	if (sign_fp == 1)
		mant_fp = 0xFFFFFFFF ^ (_fix);
	else
		mant_fp = _fix;

	for (int jj=0; jj<16; jj++)
	{
		if (mant_fp==0) 
		{
			msb = 32;
			break;
		}
		else
		{
			if (mant_fp & 0x8000)
			{
				mant_fp = mant_fp << 1;
				break;
			}
			else 
			{
				mant_fp = mant_fp << 1;
				msb++;
			}
		}
	}
	int msb_fp = 32-msb;
	mant_fp &= 0xFFFF;
	int FP = ((sign_fp << 22) & 0x400000) + ((msb_fp << 16) & 0x3F0000) + (mant_fp);

	return FP;
}
/*****************************************************************/
int fix2float32(int _fix)
{
	int msb = 1;
	int sign_fp = (_fix >> 22) & 0x1;

	int mant_fp = 0;
	if (sign_fp == 1)
		mant_fp = 0xFFFFFFFF ^ (_fix);
	else
		mant_fp = _fix;

	for (int jj = 0; jj<24; jj++)
	{
		if (mant_fp == 0)
		{
			msb = 46;
			break;
		}
		else
		{
			if (mant_fp & 0x800000)
			{
				mant_fp = mant_fp << 1;
				break;
			}
			else
			{
				mant_fp = mant_fp << 1;
				msb++;
			}
		}
	}
	int msb_fp = 32 - msb;
	mant_fp &= 0xFFFF;
	int FP = ((sign_fp << 30) & 0x80000000) + ((msb_fp << 24) & 0xFF000000) + (mant_fp);

	return FP;
}
/*****************************************************************/
VarFltst float_expand23(int _fp)
{
	VarFltst _fRes;
	_fRes.man	= (_fp & 0xFFFF);
	_fRes.sig	= (_fp >> 22) & 0x1;
	_fRes.ex	= (_fp >> 16) & 0x3F;
	return _fRes;
}
/*****************************************************************/
VarFltst float_mult23(VarFltst _aa, VarFltst _bb)
{
	VarFltst AA;
	VarFltst BB;
	VarFltst CC;

	AA.sig	= _aa.sig; 
	AA.ex	= _aa.ex;
	AA.man	= _aa.man;

	BB.sig	= _bb.sig;
	BB.ex	= _bb.ex;
	BB.man	= _bb.man;

	CC.sig = (AA.sig ^ BB.sig);

	long long a1 = AA.man | 0x00010000;
	long long a2 = BB.man | 0x00010000;	
	long long mant = (a1) * (a2);

	int msb = (mant >> 33) & 0x00000001;
	if (msb == 1)
		CC.man = (mant >> 17) & 0x0000FFFF;
	else
		CC.man = (mant >> 16) & 0x0000FFFF;

	CC.ex  = (AA.ex + BB.ex - 16 - 15) + msb; // double -16 for Fourier
	/*CC.ex  = (AA.ex + BB.ex - 16 - 16) + msb;*/

	if ((AA.ex == 0) | (BB.ex == 0))
	{
		CC.ex = 0x0;
		CC.man = 0x0;
		CC.sig = 0x0;
	}
	return CC;
}
/*****************************************************************/
VarFltst float_add23(VarFltst _aa, VarFltst _bb, char addsub)
{
	VarFltst AA;
	VarFltst BB;
	VarFltst CC;

	int Aexpman = 0;
	int Bexpman = 0;
	//int Cexp = 0;
	int Csub = 0;

	long long sum_man = 0;

	int impA = 0;
	int impB = 0;

	AA.sig	= _aa.sig;
	AA.ex	= _aa.ex;
	AA.man	= _aa.man;
	BB.sig	= _bb.sig;
	BB.ex	= _bb.ex;
	BB.man	= _bb.man;

	if (addsub == 's')
		BB.sig = (~BB.sig & 0x1);

	Aexpman = (AA.ex << 16) | AA.man;
	Bexpman = (BB.ex << 16) | BB.man;

	CC = AA;
	if ((Aexpman - Bexpman) < 0)
	{
		AA = BB;
		BB = CC;
	}

	if (AA.ex == 0)
		impA = 0x0;
	else
		impA = 0x00010000;
	if (BB.ex == 0)
		impB = 0x0;
	else
		impB = 0x00010000;

	AA.man |= impA;
	BB.man |= impB;

	Csub = AA.sig ^ BB.sig;

	int exp_dif = (AA.ex-BB.ex) & 0xF;
	int mant = BB.man >> exp_dif; 
	
	int exp3 = (AA.ex-BB.ex) & 0x30;
	if (exp3 != 0)
		mant = 0x0;

	if (Csub == 0)
		sum_man = AA.man + mant;
	else
		sum_man = AA.man - mant;

	int msb_num = 0;
	int com_msb = 0;
	int Afor = (((sum_man >> 2) & 0x0000FFFF) << 16) & 0xFFFF0000;
	// MSB SEEKER
	for (int ii=0;ii<32;ii++)
	{
		com_msb = Afor & 0x00000001;
		if (com_msb == 1)
			msb_num = ii;

		Afor = Afor >> 1;
	}

	int msbn = ~(msb_num);
	msbn = msbn & 0x0000001F;
// 	shmask <<= msbn;
// 	shmask &= 0x0000FFFF;

	int LUT = (sum_man >> 1) << msbn;

	int set_zero = 0;
	if ((AA.ex - msbn) < 0)
		set_zero = 1;
	else
		set_zero = 0;

	if (set_zero==0)
		CC.ex  = (AA.ex - msbn) + 1;
	else
		CC.ex  = 0x0;
	CC.sig = AA.sig; 
	CC.man = LUT & 0x0000FFFF;

	return CC;
}
/*****************************************************************/