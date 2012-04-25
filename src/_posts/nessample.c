/* 
   AUTHOR: Andy Goetz
   Date:   5/25/2010
   LICENSE: 

     Copyright (C) 2010 Andy Goetz

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#define F_CPU 8000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
/* hella ton of macros for ports */
#define P_LATCH 0
#define P_CLK 1
#define P_DAT 2
#define LEN      0b10000000
#define LDIR     0b01000000
#define REN      0b00100000
#define RDIR     0b00010000
#define P_BUMP   0b00000011
#define B_A      0b00000001
#define B_B      0b00000010
#define B_SELECT 0b00000100
#define B_START  0b00001000
#define B_UP     0b00010000
#define B_DOWN   0b00100000
#define B_LEFT   0b01000000
#define B_RIGHT  0b10000000


#define ISPRESSED(x,y) ((x) & (y))
/* Gets the buttons of the NES controller. Keep in mind this function is 
blocking, and that the NES buttons are active low*/
int get_data()
{
  int i;
  int rval = 0xff;
  int tmp;
  /* here we pull the latch high for 5 us  */
  

  PORTA &= ~(1 << P_CLK);
  PORTA |= 1 << P_LATCH;
  _delay_us(100.0); 
  PORTA &= ~(1 << P_LATCH);

  /* for every bit, pulse the clock, and get the input */
  for (i = 0; i < 8; i++)
    {
      tmp = 0;
      tmp = (((1  << P_DAT) & PINA) >> P_DAT) << i;
      rval &= ~tmp;

      _delay_us(100.0);
      PORTA |= 1 << P_CLK;
      _delay_us(100.0);
      PORTA &= ~(1 << P_CLK);
      
    }
  
  return rval;
}

int main()
{
  int data;
  DDRA |= (1 << P_LATCH) | (1 << P_CLK) ;
  PORTB |= P_BUMP;
  DDRB |= 0x04;
  //DDRB |= 0x0f;
  DDRA |= 0xf0;
  for (;;)
    {
      
      data = get_data();
      PORTA |= LEN | LDIR | REN | RDIR ;      
      /* example of how to use the ispressed macro to simplify 
	 the state of the outputs*/
      if (ISPRESSED(B_UP, data) && ISPRESSED(B_RIGHT, data))
	{
	  PORTA &= ~LEN; 
	}
      else if (ISPRESSED(B_UP, data) && ISPRESSED(B_LEFT, data))
	{
	  PORTA &= ~ REN; 
	}
      else if (ISPRESSED(B_DOWN, data) && ISPRESSED(B_LEFT, data))
	{
	  PORTA &= ~( REN | RDIR); 
	}
      else if (ISPRESSED(B_DOWN, data) && ISPRESSED(B_RIGHT, data))
	{
	  PORTA &= ~(LEN |  LDIR); 
	}
      else if (ISPRESSED(B_UP, data))
	{
	  PORTA &= ~(LEN | REN); 
	}
      else if (ISPRESSED(B_DOWN, data))
	{
	  PORTA &= ~(LEN | REN | LDIR | RDIR); 
	}
      else if (ISPRESSED(B_LEFT, data))
	{
	  PORTA &= ~(LEN | REN | LDIR); 
	}
      else if (ISPRESSED(B_RIGHT, data))
	{
	  PORTA &= ~( LEN | REN | RDIR); 
	}
      
      if((P_BUMP & PINB) ^ P_BUMP)
	{
	  PORTA |= (1 << P_LATCH) | (1 << P_CLK) | 4;
	  _delay_ms(25.0);
	  PORTA &= ~((1 << P_LATCH) | (1 << P_CLK) | 4);
	}
      
    }
  return 0;
}
