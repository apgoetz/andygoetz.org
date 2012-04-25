Recently I took a class on Embedded Systems at Portand State
University, and was required to program a bare metal ARM development
board. This is a continuation of my notes on how to program the
board. You can read the first part
[here](http://www.andygoetz.org/2011-05-16-a-bare-metal-ARM-environment.html).

In order for this development environment to work, we need to
implement the syscalls that newlib will use for the C standard
library. Most of the required syscalls are necessary in order to
access abstractions that wont make sense on the development board. For
example, with a concept of a process, there is no need for the fork()
system call. In fact, the only system call we really need to implement
is sbrk().

sbrk() is used to implement the malloc() family of functions. Without
sbrk(), there is no way to dynamically allocate memory to the running
program. One could argue that even this is not needed in a bare-bones
environment, but on the offchance that it is needed, the sbrk() system
call is easy to implement:

	/* Increase program data space */
	caddr_t _sbrk(int incr)
	{
	    extern char _end;
	    static char *heap_end;
	    char *prev_heap_end;
	    register char * stack_ptr __asm__ ("sp");
	    if(heap_end == 0)
	    {
	        heap_end = &_end;
	    }
	    prev_heap_end = heap_end;
	    if(heap_end + incr > stack_ptr)
	    {
	        _write(1, "Heap and stack collision\n", 25);
		abort();
	    }
	    heap_end += incr;
	    return (caddr_t) prev_heap_end;
	}

sbrk() increases the space in a program by the specified number of
bytes. On success, it returns the previous end of memory space for the
program. You can read more about sbrk() by running the command "man 2
sbrk". sbrk() is important in a proper multi-programmed operating
system because it provides a safe way for programs to expand without
stepping on one another. In our single-user, single-program embedded
world, all we need to worry about is sbrk overflowing the stack.

The rest of the system calls are listed in the source files at the
bottom of this post.

It is very hard to find meaningful results in a test of a program
intended for embedded use without running it on real
hardware. However, one can simulate a program by using GDB's ARM
micro-architecture simulator. Here is an example program that busy
waits for approximately 1 second on a PXA270 microprocessor, and then
blinks an LED:


	/*
	 Author: Andy Goetz
	 Copyright 2011 All Rights Reserved
	*/
	
	#include
	#include "armdefs.h"
	#include 
	
	/* This file contains an example program that uses a simple spin loop
	to toggle an LED */
	
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

The macros GPSR0, GPCR0 and GPDR0 are defined in "armdefs.h". They are
the hardware-specific registers for the PXA270's GPIOs. To compile
this example, use the following code:

	arm-elf-gcc --std=c99 -g -o test test.c syscalls.c

This will produce the binary file containing our program. We can use
GDB to step through a simulated execution of the program. GDB won't
blink an LED: the memory-mapped registers will behave like normal
memory locations, but we can see how the program runs, and look at its
disassembly:

	arm-elf-gdb test

We need to start up the simulator, and load in our code:

	target sim
	Connected to the simulator.
	(gdb) load
	Loading section .init, size 0x20 vma 0x8000
	Loading section .text, size 0x171c vma 0x8020
	Loading section .fini, size 0x1c vma 0x973c
	Loading section .rodata, size 0x8c vma 0x9758
	Loading section .eh_frame, size 0x45c vma 0x97e4
	Loading section .ctors, size 0x8 vma 0x11c40
	Loading section .dtors, size 0x8 vma 0x11c48
	Loading section .jcr, size 0x4 vma 0x11c50
	Loading section .data, size 0x848 vma 0x11c54
	Start address 0x810c
	Transfer rate: 74976 bits in <1 sec.

Now we can set breakpoints and step through our code:

	(gdb) break main
	Breakpoint 1 at 0x821c: file test.c, line 18.
	(gdb) run
	Starting program: /home/agoetz/test 
	
	Breakpoint 1, main () at test.c:18
	18 const int DELAY_VAL = 0x0A74FB05/3;

Next time, I will demonstrate how to mix C and assembly, and how to
implement an Interrupt Service Routine using this development
environment.

Source Files:
[armdefs.h](armdefs.h)
[syscalls.h](syscalls.h)
[syscalls.c](syscalls.c)
[test.c](test.c)




