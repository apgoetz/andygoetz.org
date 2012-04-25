/* 
   Author: Andy Goetz
   Copyright 2011 All Rights Reserved
*/

#include <stdlib.h>
#include "armdefs.h"
#include <stdint.h>

/* This file contains an example program that uses a simple spin loop to toggle an LED */

#define LED_BIT 13
#define LED_MASK (1 << LED_BIT)
int main()
{
 
  /* Delay value needed for wait loop */
  const int DELAY_VAL = 0x0A74FB05/3;
  
  /* set up GPIO 13 as input */
  /* make sure starting value is low */
  GPCR0 = LED_MASK;


  GPDR0 |= LED_MASK;
  while (1)
    {
      for(int i = 0; i < DELAY_VAL; i++)
	__asm__("nop");
      GPSR0 = LED_MASK;

      for(int i = 0; i < DELAY_VAL; i++)
	__asm__("nop");
      GPCR0 = LED_MASK;
    }

  
}
