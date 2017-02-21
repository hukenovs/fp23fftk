#include "stdafx.h"
#include <stdio.h>

int Reverse[262144];

int reverse8( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 4;
	if ( x & 2)		h+= 2;
	if ( x & 4)		h+= 1;
	return h;
}

int reverse16( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 8;
	if ( x & 2)		h+= 4;
	if ( x & 4)		h+= 2;
	if ( x & 8)		h+= 1;
	return h;
}

int reverse32( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 16;
	if ( x & 2)		h+= 8;
	if ( x & 4)		h+= 4;
	if ( x & 8)		h+= 2;
	if ( x & 16)	h+= 1;
	return h;
}

int reverse64( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 32;
	if ( x & 2)		h+= 16;
	if ( x & 4)		h+= 8;
	if ( x & 8)		h+= 4;
	if ( x & 16)	h+= 2;
	if ( x & 32)	h+= 1;
	return h;
}

int reverse128( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 64;
	if ( x & 2)		h+= 32;
	if ( x & 4)		h+= 16;
	if ( x & 8)		h+= 8;
	if ( x & 16)	h+= 4;
	if ( x & 32)	h+= 2;
	if ( x & 64)	h+= 1;
	return h;
}

int reverse256( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 128;
	if ( x & 2)		h+= 64;
	if ( x & 4)		h+= 32;
	if ( x & 8)		h+= 16;
	if ( x & 16)	h+= 8;
	if ( x & 32)	h+= 4;
	if ( x & 64)	h+= 2;
	if ( x & 128)	h+= 1;
	return h;
}

int reverse512( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 256;
	if ( x & 2)		h+= 128;
	if ( x & 4)		h+= 64;
	if ( x & 8)		h+= 32;
	if ( x & 16)	h+= 16;
	if ( x & 32)	h+= 8;
	if ( x & 64)	h+= 4;
	if ( x & 128)	h+= 2;
	if ( x & 256)	h+= 1;
	return h;
}

int reverse1024( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 512;
	if ( x & 2)		h+= 256;
	if ( x & 4)		h+= 128;
	if ( x & 8)		h+= 64;
	if ( x & 16)	h+= 32;
	if ( x & 32)	h+= 16;
	if ( x & 64)	h+= 8;
	if ( x & 128)	h+= 4;
	if ( x & 256)	h+= 2;
	if ( x & 512)	h+= 1;
	return h;
}

int reverse2048( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 1024;
	if ( x & 2)		h+= 512;
	if ( x & 4)		h+= 256;
	if ( x & 8)		h+= 128;
	if ( x & 16)	h+= 64;
	if ( x & 32)	h+= 32;
	if ( x & 64)	h+= 16;
	if ( x & 128)	h+= 8;
	if ( x & 256)	h+= 4;
	if ( x & 512)	h+= 2;
	if ( x & 1024)	h+= 1;
	return h;
}

int reverse4096( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 2048;
	if ( x & 2)		h+= 1024;
	if ( x & 4)		h+= 512;
	if ( x & 8)		h+= 256;
	if ( x & 16)	h+= 128;
	if ( x & 32)	h+= 64;
	if ( x & 64)	h+= 32;
	if ( x & 128)	h+= 16;
	if ( x & 256)	h+= 8;
	if ( x & 512)	h+= 4;
	if ( x & 1024)	h+= 2;
	if ( x & 2048)	h+= 1;
	return h;
}

int reverse8192( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 4096;
	if ( x & 2)		h+= 2048;
	if ( x & 4)		h+= 1024;
	if ( x & 8)		h+= 512;
	if ( x & 16)	h+= 256;
	if ( x & 32)	h+= 128;
	if ( x & 64)	h+= 64;
	if ( x & 128)	h+= 32;
	if ( x & 256)	h+= 16;
	if ( x & 512)	h+= 8;
	if ( x & 1024)	h+= 4;
	if ( x & 2048)	h+= 2;
	if ( x & 4096)	h+= 1;
	return h;
}

int reverse16384( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 8192;
	if ( x & 2)		h+= 4096;
	if ( x & 4)		h+= 2048;
	if ( x & 8)		h+= 1024;
	if ( x & 16)	h+= 512;
	if ( x & 32)	h+= 256;
	if ( x & 64)	h+= 128;
	if ( x & 128)	h+= 64;
	if ( x & 256)	h+= 32;
	if ( x & 512)	h+= 16;
	if ( x & 1024)	h+= 8;
	if ( x & 2048)	h+= 4;
	if ( x & 4096)	h+= 2;
	if ( x & 8192)	h+= 1;
	return h;
}

int reverse32768( int x) 
{
	int h = 0;
	if ( x & 1)		h+= 16384;
	if ( x & 2)		h+= 8192;
	if ( x & 4)		h+= 4096;
	if ( x & 8)		h+= 2048;
	if ( x & 16)	h+= 1024;
	if ( x & 32)	h+= 512;
	if ( x & 64)	h+= 256;
	if ( x & 128)	h+= 128;
	if ( x & 256)	h+= 64;
	if ( x & 512)	h+= 32;
	if ( x & 1024)	h+= 16;
	if ( x & 2048)	h+= 8;
	if ( x & 4096)	h+= 4;
	if ( x & 8192)	h+= 2;
	if ( x & 16384)	h+= 1;
	return h;
}

int reverse65536( int x)
{
	int h = 0;
	if ( x & 1)		h+= 32768;
	if ( x & 2)		h+= 16384;
	if ( x & 4)		h+= 8192;
	if ( x & 8)		h+= 4096;
	if ( x & 16)	h+= 2048;
	if ( x & 32)	h+= 1024;
	if ( x & 64)	h+= 512;
	if ( x & 128)	h+= 256;
	if ( x & 256)	h+= 128;
	if ( x & 512)	h+= 64;
	if ( x & 1024)	h+= 32;
	if ( x & 2048)	h+= 16;
	if ( x & 4096)	h+= 8;
	if ( x & 8192)	h+= 4;
	if ( x & 16384)	h+= 2;
	if ( x & 32768)	h+= 1;
	return h;
}

int reverse131072( int x)
{
	int h = 0;
	if ( x & 1)		h+= 65536;
	if ( x & 2)		h+= 32768;
	if ( x & 4)		h+= 16384;
	if ( x & 8)		h+= 8192;
	if ( x & 16)	h+= 4096;
	if ( x & 32)	h+= 2048;
	if ( x & 64)	h+= 1024;
	if ( x & 128)	h+= 512;
	if ( x & 256)	h+= 256;
	if ( x & 512)	h+= 128;
	if ( x & 1024)	h+= 64;
	if ( x & 2048)	h+= 32;
	if ( x & 4096)	h+= 16;
	if ( x & 8192)	h+= 8;
	if ( x & 16384)	h+= 4;
	if ( x & 32768)	h+= 2;
	if ( x & 65536)	h+= 1;
	return h;
}

int reverse262144( int x)
{
	int h = 0;
	if ( x & 1)		h+= 131072;
	if ( x & 2)		h+= 65536;
	if ( x & 4)		h+= 32768;
	if ( x & 8)		h+= 16384;
	if ( x & 16)	h+= 8192;
	if ( x & 32)	h+= 4096;
	if ( x & 64)	h+= 2048;
	if ( x & 128)	h+= 1024;
	if ( x & 256)	h+= 512;
	if ( x & 512)	h+= 256;
	if ( x & 1024)	h+= 128;
	if ( x & 2048)	h+= 64;
	if ( x & 4096)	h+= 32;
	if ( x & 8192)	h+= 16;
	if ( x & 16384)	h+= 8;
	if ( x & 32768)	h+= 4;
	if ( x & 65536)	h+= 2;
	if ( x & 131072)h+= 1;
	return h;
}

void fill_reverse(int m)
{
	//int reverse[j]=0;

	for(int j=0; j<m; j++)
	{
		if ( m == 8)
			Reverse[j] = reverse8(j);
		else if ( m == 16)
			Reverse[j] = reverse16(j);
		else if ( m == 32)
			Reverse[j] = reverse32(j);
		else if ( m == 64)
			Reverse[j] = reverse64(j);
		else if ( m == 128)
			Reverse[j]= reverse128(j);
		else if ( m == 256)
			Reverse[j]= reverse256(j);
		else if ( m == 512)
			Reverse[j]= reverse512(j);
		else if ( m == 1024)
			Reverse[j]= reverse1024(j);
		else if ( m == 2048)
			Reverse[j]= reverse2048(j);
		else if ( m == 4096)
			Reverse[j]= reverse4096(j);
		else if ( m == 8192)
			Reverse[j]= reverse8192(j);
		else if ( m == 16384)
			Reverse[j]= reverse16384(j);
		else if ( m == 32768)
			Reverse[j]= reverse32768(j);
		else if ( m == 65536)
			Reverse[j]= reverse65536(j);
		else if ( m == 131072)
			Reverse[j]= reverse131072(j);
		else if ( m == 262144)
			Reverse[j]= reverse262144(j);
		else
			printf("ERROR WHILE SETTING FFT LENGTH!\n");
	}
	//return reverse[j];
}
