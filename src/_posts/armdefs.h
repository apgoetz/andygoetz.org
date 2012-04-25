/* 
   Author: Andy Goetz
   Copyright 2011 All Rights Reserved
*/

/*
  This file contains useful definititions to make code writing easier
 */

#ifndef __ARMDEFS_H__
#define __ARMDEFS_H__
#include <stdint.h>
/* gplr0 */
volatile int * const GPLR0_addr = (int*)0x40E00000;	/* GPIO Pin-Level register GPIO[31:0] */
#define GPLR0 *GPLR0_addr
/* gpcr0 */
volatile int * const GPDR0_addr = (int*)0x40E0000C;	/* GPIO Pin Direction Register GPIO[31:0] */
#define GPDR0 *GPDR0_addr
/* gpdr0 */
volatile int * const GPCR0_addr = (int*)0x40E00024;	/* GPIO Pin Output Clear Register GPIO[31:0] */
#define GPCR0 *GPCR0_addr
/* gpsr0 */
volatile int * const GPSR0_addr = (int*)0x40E00018; /* GPIO Pin Output Set Register GPIO[31:0] */
#define GPSR0 *GPSR0_addr

/* grer0 */
volatile int * const GRER0_addr = (int*)0x40E00030; /* GPIO Rising Edge Detect Register GPIO[31:0] */
#define GRER0 *GRER0_addr

/* gedr0 */
volatile int * const GEDR0_addr = (int*)0x40E00048; /* GPIO Edge Detect Status Register GPIO[31:0] */
#define GEDR0 *GEDR0_addr



/* grer2 */
volatile int * const GRER2_addr = (int*)0x40E00038; /* GPIO Rising Edge Detect Register GPIO[95:64] */
#define GRER2 *GRER2_addr

/* gedr2 */
volatile int * const GEDR2_addr = (int*)0x40E00050; /* GPIO Edge Detect Status Register GPIO[95:64] */
#define GEDR2 *GEDR2_addr

/* grer3 */
volatile int * const GRER3_addr = (int*)0x40E00130; /* GPIO Rising Edge Detect Register GPIO[120:96] */
#define GRER3 *GRER3_addr


/* icmr */
volatile int * const ICMR_addr = (int*)0x40D00004; /* Interrupt Controller Mask Register */
#define ICMR *ICMR_addr

/* RHR2 */
volatile uint8_t * const RHR2_addr = (uint8_t*)0x10800000; /* COM2 Receive Holding Register */
#define RHR2 *RHR2_addr

/* THR2 */
volatile uint8_t * const THR2_addr = (uint8_t*)0x10800000; /* COM2 Transmit Holding Register*/
#define THR2 *THR2_addr

/* DLL2 */
volatile uint8_t * const DLL2_addr = (uint8_t*)0x10800000; /* COM2 Divisor LSB*/
#define DLL2 *DLL2_addr

/* DLM2 */
volatile uint8_t * const DLM2_addr = (uint8_t*)0x10800002; /* COM2 Divisor MSB*/
#define DLM2 *DLM2_addr

/* IER2 */
volatile uint8_t * const IER2_addr = (uint8_t*)0x10800002; /* COM2 Uint8_Terrupt Enable Register*/
#define IER2 *IER2_addr

/* ISR2 */
volatile uint8_t * const ISR2_addr = (uint8_t*)0x10800004; /* COM2 Uint8_Terrupt Status Register*/
#define ISR2 *ISR2_addr

/* FCR2 */
volatile uint8_t * const FCR2_addr = (uint8_t*)0x10800004; /* COM2 FIFO Control Register */
#define FCR2 *FCR2_addr

/* LCR2 */
volatile uint8_t * const LCR2_addr = (uint8_t*)0x10800006; /* COM2 Line Control Register*/
#define LCR2 *LCR2_addr

/* MCR2 */
volatile uint8_t * const MCR2_addr = (uint8_t*)0x10800008; /* COM2 Modem Control Register*/
#define MCR2 *MCR2_addr

/* LSR2 */
volatile uint8_t * const LSR2_addr = (uint8_t*)0x1080000a; /* COM2 Line Status Register*/
#define LSR2 *LSR2_addr

/* MSR2 */
volatile uint8_t * const MSR2_addr = (uint8_t*)0x1080000c; /* COM2 Modem Status Register*/
#define MSR2 *MSR2_addr

/* SPR2 */
volatile uint8_t * const SPR2_addr = (uint8_t*)0x1080000e; /* COM2 Scratch Pad Register*/
#define SPR2 *SPR2_addr

/* RTAR */
volatile uint32_t * const RTAR_addr = (uint32_t*)0x40900004; /* RTC Alarm Register*/
#define RTAR *RTAR_addr

/* RCNR */
volatile uint32_t * const RCNR_addr = (uint32_t*)0x40900000; /* RTC Counter Register*/
#define RCNR *RCNR_addr

/* RTSR */
volatile uint32_t * const RTSR_addr = (uint32_t*)0x40900008; /* RTC Status Register*/
#define RTSR *RTSR_addr


/* OSCC */
volatile uint32_t * const OSCC_addr = (uint32_t*)0x41300008; /* Oscillator Configuration Register*/
#define OSCC *OSCC_addr





#endif
