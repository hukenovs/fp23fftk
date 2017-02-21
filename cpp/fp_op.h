// ---------------- constants ---------------- //
#define pi 3.141592653589793238462643383279502884

#define _log2(a) int(log(double(N_FFT))/log(2.0))
#define _log2x(a) int(log(double(N_FFT/8192))/log(2.0))


#define N_FFT 4096//1024//2048//4096//8192//16384//32768//65536/
#define SCALE 0x1C	// Scale factor for FFT/IFFT
#define _Tay 1	// 1 - use Teylor coeffs, 0 - don't use

// ---------------- structures ---------------- //
struct VarFltst
{
	int sig;
	int ex;
	int man;
};

struct ComplexVarFltst
{
	VarFltst re;
	VarFltst im;
};

struct ComplexInt {
	int re;
	int im;
};

// ---------------- reverse ---------------- //
void fill_reverse(int m);
extern int Reverse[65536];
// ---------------- FFTs ---------------- //
void FLOAT_FFT(ComplexVarFltst* _AF, ComplexVarFltst* _AR, ComplexVarFltst* _BR, int stages, char _nat, char _inv);
// ---------------- butterflies ---------------- //
void ButterflyFP(ComplexVarFltst *FA, ComplexVarFltst *FB, ComplexVarFltst *FcoeArr, int aa, int bb, int ww, int stage, char decim, int _use);
void Twiddle_WW(int _nFFT, ComplexVarFltst* CFPW, int coefs);
// ---------------- float operators ---------------- // 
int fix2float23(int _fix);
int float2fix23(int _fp, int _scale);

VarFltst float_expand23(int _fp);
int float_collapse23(VarFltst fRes);

VarFltst float_mult23(VarFltst _aa, VarFltst _bb);
VarFltst float_add23(VarFltst _aa, VarFltst _bb, char addsub); // decim = 0 - DIF, decim = 1 - DIT