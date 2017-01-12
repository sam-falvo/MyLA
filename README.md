# MyLA

The MYLA core ("My Logic Analyzer") is designed to capture a certain amount of arbitrary data into a FIFO,
under controlled conditions,
and which can then be analyzed by the host processor.
The data can be fed into the FIFO as fast as the Wishbone interface's clock.
E.g., if MYLA's Wishbone bus is clocked at 25MHz, it can accept data at up to 25 megasamples per second.
It can also go slower, of course, based on the state of the `GATE_I` signal during any given clock cycle.

The FIFO depth is determined by the core's `QBITS` parameter.
This determines the number of bits needed to address all the elements in the queue.
As shipped, the default setting (as defined in `myla.vh`) is 4,
meaning that the FIFO occupies only 16 elements.
This small size is intended to facilitate benchtesting.
Real-world instantiations of this core are expected to specify larger values of `QBITS`.

The Wishbone word size, and hence the FIFO element width,
is determined by the `DBITS` parameter.
By default, this equals 16,
meaning that the Wishbone interface exposes 16-bit wide registers,
and the FIFO stores 16-bit words.

## Features

* Configurable number of channels.
* Configurable sample buffer size.
* Wishbone B3 non-pipelined slave interface.
* Single clock domain design.

## Signals

### Wishbone Interface

|Signal|Description|
|:----:|:----------|
|ACK\_O|Terminates the current Wishbone transaction.  This signal also qualifies the `DAT_O` signal.|
|ADR\_I|Selects between one of two registers offered by the core.|
|CLK\_I|Wishbone bus clock.  All slaves and masters on this Wishbone segment are synchronized to the rising edge of this clock.|
|CYC\_I|Asserted by a master when it reserves the Wishbone bus for its own use.|
|DAT\_O|Feeds data back to the current Wishbone master.|
|RES\_I|Synchronous reset.|
|STB\_I|Asserted by a master during a read or write bus transaction.|
|WE\_I|Asserted by a master to indicate a write transaction.  If not asserted, the transaction is a read transaction.|

### Logic Analyzer Interface

|Signal|Description|
|:----:|:----------|
|CHAN\_I|Inputs to be stored into the sample buffer.  The value on this signal is registered on the next rising edge of `CLK_I` if, and only if, `GATE_I` is also asserted at that time.|
|GATE\_I|Controls when to record a sample.  If asserted and upon the next rising edge of `CLK_I`, and further assuming enough space to store the sample, the `CHAN_I` inputs are registered and stored internally in a FIFO.|

## Registers

Currently, two registers are supported, one of which has dual purpose depending on if read or if written.

|Offset|Name|R/W|Description|
|:------:|:--:|:-:|:----------|
|0|LAQSTAT|R/O|Provides FIFO status for the host processor.|
|1|LAQDATA|R/O|Provides the value at the current head of the FIFO.|
|1|LAQPOP|W/O|Pops the queue if not empty.|

The **LAQSTAT** register has the following layout:

|*DBITS-1* .. 2| 1 | 0 |
|:------------:|:-:|:-:|
| 0 |IsFull|IsEmpty|

The meaning of the bits are as follows:

|Bit|Name|Meaning|
|:-:|:--:|:------|
|0|IsEmpty|**1** if the queue is currently empty; **0** otherwise.|
|1|IsFull|**1** if the queue cannot accept more data; **0** otherwise.|

## Origins

MYLA is actually a modified
[KIA core](Registe://github.com/KestrelComputer/kestrel/tree/master/cores/KIA)
which is more generic and configurable,
and which has the built-in serial to parallel converter removed and the raw parallel interface exposed.

