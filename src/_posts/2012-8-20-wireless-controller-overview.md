I have been working on developing a kit to use SNES controllers
wirelessly. This document outlines the design decisions made so far.

<a name='more'></a>

# Motivation and High Level Overview

Many classic arcade and console video games can be
played with a D-pad. While one can use modern controllers with these
programs, they lack the elegance of the older designs. However, if one
uses one of these older controllers with a USB adapter, one is forced
to be tethered to the computer. 

Wireless SNES controllers have been done before. However, they usually
don't pay close attention to power usage, and none support multiple
controllers using a single interface. 

The purpose of this project then, is to develop a low latency,
ultra-low power device to interface with the original SNES hardware,
and connect it to a modern PC. This device must be relatively cheap to
manufacture, use components that are currently being manufactured,
support multiple devices without interference, and must minimally
modify the hardware. Additionally, it should use techniques developed for
packet radio to allow for multiple transmitters on the same channel.

It is immediately obvious that one of the most important design
decisions is the choice of wireless for use in the controllers. There
are several widely available solutions that were considered:

* IR

* Bluetooth

* ZigBee

* Unlicenced 433/315MHz

* Unlicenced 2.4GHz

Below is a discussion of the pros and cons of each technology:

## IR

38kHz modulated IR light is commonly used for TV remotes. It is well
suited for this application: data transmission is one-way, and the
transceiver is only energized when actually tranceiving. However, the
one-way transmission makes it hard to build in support for handling
multiple controllers at once.

## Bluetooth

Bluetooth is an attractive technology, because its widespread use
eliminates the need for any kind of specialized receiver
hardware. Many PCs have built-in bluetooth support. Additionally,
bluetooth already has a proven track record in low-power, low-latency
devices. The Sony PS3 uses bluetooth to communicate with its
controllers. However, there are some drawbacks to the bluetooth
solution. The Bluetooth HID protocol is simply a wrapper around the
USB protocol, and has considerable latency in its inputs. The PS3
requires a custom, low latency hardware stack to meet its
deadlines. Also, DIY-friendly bluetooth solutions are typically rather
expensive, and usually are optimized for transmitting data with
guaranteed deliveries, something that is unnecessary for the wireless controller. 

## Zigbee

The pros and cons of Zigbee are very similar to that of Bluetooth,
save that a custom receiver would also be required. 

## Unlicenced 433/315MHz 

These transmitters are extremely cheap, on the order of $2-3 dollars
for a receiver/transmitter pair. In fact, this solution has already
been used for building [wireless SNES
Controllers](http://www.ppl-pilot.com/SnesHack/index.htm). However,
there are several drawbacks to this solution. First of all, the
transmitter and receiver are not integrated, and would require two
discrete circuits to be included into the SNES Controller, taking up
valuable space. Additionally, the extremely low bandwidth (on the
order of 1Kbps) of the RF link would limit the refresh frequency of
the controller, to say nothing of allowing for multiple controllers. 

## Unlicensed 2.4GHz

This solution is by far the most promising. This is backed up by
real-world evidence. All gaming-quality wireless mice use a custom
wireless protocol instead of bluetooth, as does Microsoft's Xbox
360. 2.4GHz allows for higher bandwidth links with lower power
consumption, at the expense of reduced range. 

The 2.4GHz solution examined in detail in this document is the Nordic
Semiconductor
[nRF24L01+](http://www.nordicsemi.com/kor/Products/2.4GHz-RF/nRF24L01P). This
chip is commonly used in industry. For example, it is used in Nike+
Shoes to communicate with iPods, as well as in Microsoft-branded
wireless keyboards. In fact, this chip has already been used in some [wireless SNES controller designs](http://imgur.com/a/8H3Ci), however, these designs have not necessarily been executed well. 

Unfortunately, the chip is only available in the hard-to-solder QFN
package. However, breakout boards are available from 3rd parties such
as
[MDFly](http://www.mdfly.com/index.php?main_page=product_info&cPath=8_52&products_id=81)
for less than $7. This chip has hardware support for Media Access Control
and packet checksumming. This makes it extremely easy to transmit data
at high data rates, over 1Mbps, without having to worry about handling
packet framing in the microcontroller. Additionally, the transceiver
supports operating on over 100 different channels in the 2.4GHz
spectrum, enabling multiple system to operate in the same environment.

# Protocol Design

In order to guarantee the successful behaviour of the SNES Controller,
it is important to make sure that the wireless protocol is robust
enough to meet timing deadlines, in the face of interferance from
multiple transmitters.

The simplest protocol useable that allows from multiple transmitters
in the same network is a packetized protocol called [Pure
ALOHA](http://en.wikipedia.org/wiki/ALOHAnet#Pure_ALOHA). In this
protocol, all packets are the same length, and all transmitters
transmit at the same data rate. This wireless model suits this
controller design, as all of the controllers should ideally update at
the same rate, and always have the same data to send. Mathematically,
we can develop a formula to determine the probability of a successful
transmission based on a mathmatical analysis of the protocol:

$$
P = e ^\frac{-2 N_tfD_s}{B}
$$

In this equation, $P$ is the probablity of a successful transmission,
$N_t$ is the number of transmitters in the network, $f$, is the
frequency with which they update their value, $D_s$ is the size in
bits of the transmitted packet, and $B$ is the bandwidth of the
medium.

This equation can also be manipulated to solve for any of the
variables in the above equation. For instance, assuming a successful
transmission rate of 0.95, 4 transmitting controllers, a packet size
of 100 bits (The maximum supported by the nRF24L01+), and a bandwidth
of 1 Mbps, the maximum refresh rate of the controllers is 64 Hz, which
is greater than the 55Hz supported by the original SNES. 

There is more to the protocol than just guaranteeing there is enough
bandwidth for low latency communication. The protocol also needs to
support pairing new controllers. Ideally, the receiver unit would also
determine the most noise-free section of the spectrum to transmit on
in order to prevent interference from wifi-routers or other
controllers. Additionally, it would be nice if metadata, for example,
the current charge rate of the controllers, could also be transmitted.
These details still need to hashed out.

# Hardware Design 
The hardware design of the SNES Controller has not been completely
decided, however, a rough idea has emerged. 

## Circuit Components

A Li-Poly battery will be used to power the SNES controller. The
[MCP73831T](http://www.digikey.com/product-detail/en/MCP73831T-2ATI%2FOT/MCP73831T-2ATI%2FOTCT-ND/1979803)
will be used to charge the Li-Poly battery, with the
[TC54](http://www.digikey.com/product-detail/en/TC54VC3002ECB713/TC54VC3002ECB713CT-ND/1979841)
being used to prevent the battery from being over-discharged. An
Atmega328p will be used for the controller brains, due to its ease of
use and wide supply range. Also, the
[TPS79325DBVR](http://www.digikey.com/product-detail/en/TPS79325DBVR/296-12156-1-ND/411991)
will be used as a linear LDO regulator. The choice of the unusual
supply voltage for this circuit, (2.5V), is a function of the
lithium-polymer battery used in this design. A lithium-polymer battery
is considered charged at 4.7 volts, and discharged at 3.0 volts. This
straddles the commonly-used voltage of 3.3V. In order to prevent the
use of a complex buck/boost converter to stablize the output at 3.3V,
2.5V was chosen, since it is lowever than the lowest discharged
voltage of the lithium-polymer device while still being supported by
the major ICs (the AtMega328p and the nRF42L01+). A 3.3V LDO regulator
could be used, but this would prevent the Lithium-Polymer battery from
being discharged past this voltage, which would prevent the entire
charge in the battery from being used. 

Note that the Receiver design will be similar to the transmitter design, save that it is powered and controlled over USB.

## Industrial Design

The industrial design of the controller has not been considered
muuch. Ideally, no external switches would be added to the controller,
with all wireless control being done through rare button combinations
(i.e Start + Select + L + R). However, some external indication will
be needed to show that pairing is in progress, or that the controller
needs charging. Perhaps this can implemented similarly to the above
controllers.