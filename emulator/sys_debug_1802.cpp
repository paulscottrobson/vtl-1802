// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		sys_debug_vip.c
//		Purpose:	Debugger Code (System Dependent)
//		Created:	1st November 2016
//		Author:		Paul Robson (paul@robsons->org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gfx.h"
#include "sys_processor.h"
#include "debugger.h"
#include "hardware.h"

static const char*_mnemonics[256] = {												// Mnenonics array.
#include "__1802mnemonics.h"
};

static const BYTE8 _mcmFont[] = {													// MCM6571 Font.
#include "__font7x9_mcmfont.h"
};

#define DBGC_ADDRESS 	(0x0F0)														// Colour scheme.
#define DBGC_DATA 		(0x0FF)														// (Background is in main.c)
#define DBGC_HIGHLIGHT 	(0xFF0)

// *******************************************************************************************************************************
//											This renders the debug screen
// *******************************************************************************************************************************

static const char *labels[] = { "D","DF","P","X","T","Q","IE","RP","RX","CY","BP", NULL };

void DBGXRender(int *address,int showDisplay) {
	int n = 0;
	char buffer[32];
	CPUSTATUS *s = CPUGetStatus();
	GFXSetCharacterSize(32,23);
	DBGVerticalLabel(15,0,labels,DBGC_ADDRESS,-1);									// Draw the labels for the register

	#define DN(v,w) GFXNumber(GRID(18,n++),v,16,w,GRIDSIZE,DBGC_DATA,-1)			// Helper macro

	n = 0;
	DN(s->d,2);DN(s->df,1);DN(s->p,1);DN(s->x,1);DN(s->t,2);DN(s->q,1);DN(s->ie,1);	// Registers
	DN(s->pc,4);DN(s->r[s->x],4);DN(s->cycles,4);DN(address[3],4);					// Others

	for (int i = 0;i < 16;i++) {													// 16 bit registers
		sprintf(buffer,"R%x",i);
		GFXString(GRID(i % 4 * 8,i/4+12),buffer,GRIDSIZE,DBGC_ADDRESS,-1);
		GFXString(GRID(i % 4 * 8+2,i/4+12),":",GRIDSIZE,DBGC_HIGHLIGHT,-1);
		GFXNumber(GRID(i % 4 * 8+3,i/4+12),s->r[i],16,4,GRIDSIZE,DBGC_DATA,-1);
	}

	int a = address[1];																// Dump Memory.
	for (int row = 17;row < 23;row++) {
		GFXNumber(GRID(2,row),a,16,4,GRIDSIZE,DBGC_ADDRESS,-1);
		GFXCharacter(GRID(6,row),':',GRIDSIZE,DBGC_HIGHLIGHT,-1);
		for (int col = 0;col < 8;col++) {
			GFXNumber(GRID(7+col*3,row),CPUReadMemory(a),16,2,GRIDSIZE,DBGC_DATA,-1);
			a = (a + 1) & 0xFFFF;
		}		
	}

	int p = address[0];																// Dump program code. 
	int opc;

	for (int row = 0;row < 11;row++) {
		int isPC = (p == ((s->pc) & 0xFFFF));										// Tests.
		int isBrk = (p == address[3]);
		GFXNumber(GRID(0,row),p,16,4,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_ADDRESS,	// Display address / highlight / breakpoint
																	isBrk ? 0xF00 : -1);
		opc = CPUReadMemory(p);p = (p + 1) & 0xFFFF;								// Read opcode.
		strcpy(buffer,_mnemonics[opc]);												// Work out the opcode.
		char *at = buffer+strlen(buffer)-2;											// 2nd char from end
		if (*at == '$') {															// Operand ?
			if (at[1] == '1') {
				sprintf(at,"%02x",CPUReadMemory(p));
				p = (p+1) & 0xFFFF;
			}
			else if (at[1] == '2') {
				sprintf(at,"%02x%02x",CPUReadMemory(p),CPUReadMemory(p+1));
				p = (p+2) & 0xFFFF;
			}
		}
		GFXString(GRID(5,row),buffer,GRIDSIZE,isPC ? DBGC_HIGHLIGHT:DBGC_DATA,-1);	// Print the mnemonic
	}

	if (showDisplay) {
	int xSize = 3;
	int ySize = 3;
	int ySpacing = 4;
    int revs;

	SDL_Rect rc;
	rc.w = 8 * 32 * xSize;										// 7 x 9 font, 32 x 16 grid
	rc.h = (ySpacing+9)* 16 * ySize;								// Variable vertical spacing.
	rc.x = WIN_WIDTH/2-rc.w/2;rc.y = WIN_HEIGHT-64-rc.h;
	SDL_Rect rc2 = rc;
	rc2.x -= 10;rc2.y -= 10;rc2.w += 20;rc2.h += 20;
	GFXRectangle(&rc2,0xFFF);
	rc2.x += 2;rc2.y += 2;rc2.w -= 4;rc2.h -= 4;
	GFXRectangle(&rc2,0x000);

	SDL_Rect rpix;rpix.w = xSize;rpix.h = ySize	;
	for (int x = 0;x < 32;x++) {
		for (int y = 0;y < 16;y++) {
			int ch = HWIReadVideoMemory(x+y*32) & 0x7F;
			if (ch != 32) {
				for (int y1 = 0;y1 < 9;y1++) {
					rpix.x = x * 8 * xSize + rc.x;
					rpix.y = y * (9 + ySpacing) * ySize + y1 * ySize + rc.y;
					int bits = _mcmFont[ch * 9 + y1];
					while (bits != 0) {
						if (bits & 0x80) GFXRectangle(&rpix,0xF80);
						rpix.x += xSize;
						bits = (bits << 1) & 0xFF;
					}
				}
			}
		}
	}
	}
}	
