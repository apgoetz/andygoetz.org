I recently took a class on Embedded systems design at PSU. In this
class, we covered designing memory systems, serial busses, as well as
sensors, transducers, and outputs. The labs for this class used an ARM
development board based on the (then Intel) PXA270
microprocessor. Students were supposed to develop software in ARM
assembly to demonstrate what was learned in class.

I decided to implement my solutions in C to provide more of a
challenge. In order to do this, I needed to set up a development
environment to cross-compile C code for the PXA270.

The development boards we were using ran a bootloader known as
[RedBoot](http://www.cygwin.com/redboot/). This made it easy to load
code and have it run as close to the hardware as possible, while still
allowing for the niceties of debuggers. One can even single-step
through Interrupt Service Routines with RedBoot.

In order to build this cross-platform development environment, you
will need to get your hands on a copy of the source of GNU binutils,
gcc, newlib, and gdb. Build the software in the following order:

Configure binutils with the following options:

	./configure \
		--target=arm-elf \
		--enable-interwork --enable-multilib \
		--disable-nls --disable-shared --disable-threads \
		--with-gcc --with-gnu-as --with-gnu-ld \


Follow this up with the standard make and make install. Next, we need
to build gcc for the first time:

	./configure \
		 --target=arm-elf \
		 --disable-nls --disable-shared --disable-threads \
		 --with-gcc --with-gnu-ld --with-gnu-as --with-dwarf2 \
		 --enable-languages=c,c++ --enable-interwork --enable-multilib \
		 --with-newlib --with-headers=../newlib-$NEWLIB_VER/newlib/libc/include \
		 --disable-libssp --disable-libstdcxx-pch --disable-libmudflap \
		 --disable-libgomp -v make all-gcc make install-gcc

The important thing here is that newlib is being used as the C
standard library. This will allow us to use all of the standard
library functions, such as atoi(), and malloc(). Using newlib has some
interesting implications that we will get into. Now we will build
newlib.


	./configure \
		    --target=arm-elf \
		    --enable-interwork --enable-multilib \
		    --disable-newlib-supplied-syscalls make make install

The important option here is 'disable-newlib-supplied-syscalls'. In
order for the C standard library to operate, there needs to be a
special set of functions, called syscalls, already implemented by the
operating system. For example, in order to use the printf() function,
the write() syscall must be available to write out data. Because we
are developing on a bare metal platform, there is no operating system
to provide this code, so we must provide it ourselves. Newlib
helpfully provides a version of these syscalls, but unfortunately,
they wont work for our platform. Now that newlib is done being built,
we can build the rest of gcc.

	make
	make install

The last piece of software to build is optional, but will probably
turn out to be extremely useful: gdb.

	./configure --target=arm-elf
	make
	make install

This concludes setting up the build environment for baremetal arm
development. Next time, I will show an example of a simple program
built using this environment.