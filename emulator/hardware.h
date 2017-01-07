// *******************************************************************************************************************************
// *******************************************************************************************************************************
//
//		Name:		hardware.h
//		Purpose:	Hardware Interface (header)
//		Created:	1st November 2016
//		Author:		Paul Robson (paul@robsons.org.uk)
//
// *******************************************************************************************************************************
// *******************************************************************************************************************************

#ifndef _HARDWARE_H
#define _HARDWARE_H

void HWIEndFrame(void);
void HWIReset(void);
BYTE8 HWIProcessKey(BYTE8 key,BYTE8 isRunMode);
BYTE8 HWIReadVideoMemory(WORD16 address);
void HWIWriteVideoPort(BYTE8 n);
BYTE8 HWIReadKeyboard(void);

#endif
