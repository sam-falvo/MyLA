//
// Parameters
//
// `QBITS specifies how deep the queue runs.  A value of 8, for example,
// indicates a queue of 256 (2^8) elements.  Default is 4 for benchtesting
// purposes.
//
// `DBITS specifies how many bits to store per element, and also determines
// the MYLA bus interface width.  For example, 16 indicates we want to store
// 16 bits of information per queued element.
//

`define QBITS		4
`define DBITS		16

//
// MYLA registers
//

`define LAQSTAT		0
`define LAQDATA		1

// MYLA status flag bits

`define LAQSF_EMPTY (`DBITS'h1)
`define LAQSF_FULL  (`DBITS'h2)


