#ifndef _MACHINE_H_
#define _MACHINE_H_

#define NRIDT		(256)
#define KSTACK_SIZE	(16384)

#define	E_DIV0		0
#define E_DBG		1
#define E_NMI		2
#define E_BREAKPOINT	3
#define E_OVERFLOW	4
#define E_BOUND		5
#define E_INVOP		6
#define E_DEVNA		7
#define E_DOUBLEFAULT	8
#define E_RESERVED	9
#define E_TSS		10
#define E_SEGNP		11
#define E_STACK		12
#define E_GENPROT	13
#define E_PAGEFAULT	14
#define E_FLOATING	15
#define E_ALIGNMENT	16
#define E_MACHINECHECK	17
#define E_SSE		18

#endif /* _MACHINE_H_ */
