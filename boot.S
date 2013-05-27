#include <machine.h>

.text
.code16

#define DATA_START	0x8000
#define DATA_END	0xC000
#define PT_START	DATA_END
#define IMG_MAGIC	0x124620AB

#define PRTCH				\
	movw	$0x3f8,		%dx;	\
	outb	%al,		%dx;	\
	addb	$5,		%dl;	\
9:					\
	inb	%dx;			\
	test	$0x20,		%al;	\
	jz	9b

#define DBG(x)				\
	movb	x,		%al;	\
	PRTCH

.globl	_start
_start:
	jmp	1f
.org	4, 0
magic:
	.long	0
size:
	.long	0
cksum:
	.long	0
drv:
	.long	0
1:
	/* Disable Interrupt */
	cli

	movw	%sp,		%ax
	movw	$DATA_START+2,	%sp
	call	1f
1:
	xorl	%ebp,		%ebp
	popw	%bp
	subw	$1b-_start,	%bp
	subl	$_start,	%ebp
	/* Restore stack pointer */
	movw	%ax,		%sp

	movl	magic(%ebp),	%eax
	cmpl	$IMG_MAGIC,	%eax
	jne	die

	/* Enable A20  */
	inb	$0x92,		%al
	orb	$2,		%al
	outb	%al,		$0x92

	addl	%ebp,		gdtboot+2(%ebp)

	movl	$_start,	%edi
	/* Read Disk */
	xorl	%ecx,		%ecx
1:
	movb	$0x42,		%ah	/* Extended Read */
	movb	drv(%ebp),	%dl	/* Drive         */
	lea	dap(%ebp),	%esi
	pushl	%ebp
	int	$0x13
	popl	%ebp
	addw	$0x40,		lba(%ebp)

	/* Unreal Mode */
	lgdt	%cs:gdtboot(%ebp)
	movl	%cr0,		%eax
	/* Protect Enable */
	orb	$1,		%al
	movl	%eax,		%cr0
	jmp	1f
1:
.code32
	movl	$24,		%ebx
	mov	%bx,		%ds
	mov	%bx,		%es
	/* Back to Real */
	andb	$0xfe,		%al
	movl	%eax,		%cr0
.code16
	xorw	%ax,		%ax
	movw	%ax,		%ds
	movw	%ax,		%es

	movl	$DATA_START,	%esi

2:	/* In unreal mode, string move does not seem to work */
	movl	(%esi),		%eax
	addl	%eax,		%ecx
	movl	%eax,		(%edi)
	addl	$4,		%esi
	addl	$4,		%edi
	cmpl	$DATA_END,	%esi
	jl	2b

	movl	$_start,	%eax
	addl	size(%ebp),	%eax
	cmpl	%eax,		%edi
	jl	1b
	cmpl	$0,		%ecx
	jne	die

	/* E820 stuff */
	xorl	%ebx,		%ebx
	movl	$0x534d4150,	%edx
	movl	$DATA_START,	%edi
1:
	movl	$0xe820,	%eax
	/* Make sure entry is valid, ACPI 3.0 */
	movw	$1,		20(%di)
	movl	$24,		%ecx
	int	$0x15
	jc	1f
	movl	$0x534d4150,	%edx
	cmpl	%eax,		%edx
	jne	1f
	testb	$1,		20(%di)
	je	1b
	addl	$24,		%edi
	cmpl	$0,		%ebx
	jne	1b
1:
	movw	$0,		20(%di)

	/*
	 * Switch to long mode.
	 * clear 16KB page table buffer.
	 */
	movw	$PT_START,	%di
	pushw	%di
	movl	$0x4000,	%ecx
	xorb	%al,		%al
	cld
	rep	stosb

	/* P4 PDP PDT */
	popw	%si
	lea	0x1003(%si),	%eax
	movl	%eax,		(%si)
	addw	$0x1000,	%si
	lea	0x1003(%si),	%eax
	movl	%eax,		(%si)
	addw	$0x1000,	%si
	lea	0x1003(%si),	%eax
	movl	%eax,		(%si)

	/* PT = Global, 4KB*2048 size, RW, P */
	movl	$0x103,		%eax
	addw	$0x1000,	%si
	lea	0x1000(%si),	%di
1:
	movl	%eax,		(%si)
	addw	$8,		%si
	addl	$0x1000,	%eax
	cmpw	%di,		%si
	jne	1b

	lidt	%cs:idt(%ebp)
	xorl	%eax,		%eax
	/* PGE | PAE */
	movb	$0xa0,		%al
	movl	%eax,		%cr4

	movl	$PT_START,	%eax
	movl	%eax,		%cr3

	/* EFER |= LME | SYSCALL */
	movl	$0xc0000080,	%ecx
	rdmsr
	orl	$0x101,		%eax
	wrmsr

	movl	%cr0,		%eax
	/* PE | PG */
	orl	$0x80000001,	%eax
	movl	%eax,		%cr0

	lgdt	%cs:gdtboot(%ebp)
	ljmpl	$8,		$longmode
die:
	jmp	die

dap:
	.byte	0x10	/* size */
	.byte	0
	.word	0x40	/* 64 sectors a time   */
	.word	DATA_START
	.word	0
lba:	.long	0, 0

.align	16
gdtboot:
	.word	_gdtbootlen-1				/* entry 0 */
	.long	gdtboot
	.word	0
	.byte	0,    0,    0, 0, 0, 0x98, 0x20, 0	/* text 64 */
	.byte	0,    0,    0, 0, 0, 0x90, 0,    0	/* data 64 */
	.byte	0xff, 0xff, 0, 0, 0, 0x92, 0xcf, 0	/* flat 16 */
_gdtbootlen = . - gdtboot

idt:
	.word	0
	.long	0

.org	510, 0
signature:
	.byte	0x55, 0xaa

.code64
longmode:
	movq	$_end,		%rcx
	movq	%rcx,		%rsp
	addq	$KSTACK_SIZE,	%rsp

	/* Clear BSS, qw aligned */
	movq	$_edata,	%rdi
	subq	%rdi,		%rcx
	shr	$3,		%rcx
	xorq	%rax,		%rax
	cld
	rep	stosq
	movq	$DATA_START,	%rdi
	call	init64
1:	jmp	1b

.globl loadidt
loadidt:
	lidt	(%rdi)
	sti
	retq

.globl putchar
putchar:
	movw	%di,		%ax
	cmpb	$'\n',		%al
	jne	1f
	movw	$'\r',		%di
	callq	putchar
	movb	$'\n',		%al
1:
	PRTCH
	retq

#define DEFINE_EXC0(func,code)	\
.globl	exc_ ## func		;\
exc_ ## func:			\
	pushq	$0		;\
	pushq	$(code)

#define DEFINE_EXC(func,code)	\
.globl exc_ ## func		;\
exc_ ## func :			\
	pushq	$(code)

DEFINE_EXC0(div0, E_DIV0)
	jmp	exc_common

DEFINE_EXC0(dbg, E_DBG)
	jmp	exc_common

DEFINE_EXC0(nmi, E_NMI)
	jmp	exc_common

DEFINE_EXC0(bp, E_BREAKPOINT)
	jmp	exc_common

DEFINE_EXC0(of, E_OVERFLOW)
	jmp	exc_common

DEFINE_EXC0(br, E_BOUND)
	jmp	exc_common

DEFINE_EXC0(ud, E_INVOP)
	jmp	exc_common

DEFINE_EXC0(nm, E_DEVNA)
	jmp	exc_common

DEFINE_EXC(df, E_DOUBLEFAULT)
	jmp	exc_common

DEFINE_EXC0(reserved, E_RESERVED)
	jmp	exc_common

DEFINE_EXC(tss, E_TSS)
	jmp	exc_common

DEFINE_EXC(np, E_SEGNP)
	jmp	exc_common

DEFINE_EXC(ss, E_STACK)
	jmp	exc_common

DEFINE_EXC(gp, E_GENPROT)
	jmp	exc_common

DEFINE_EXC(pf, E_PAGEFAULT)
	jmp	exc_common

DEFINE_EXC0(mf, E_FLOATING)
	jmp	exc_common

DEFINE_EXC(ac, E_ALIGNMENT)
	jmp	exc_common

DEFINE_EXC0(mc, E_MACHINECHECK)
	jmp	exc_common

DEFINE_EXC0(xf, E_SSE)
	jmp	exc_common

exc_common:
	/* Save Registers */
	pushq	%rax
	pushq	%rbx
	pushq	%rcx
	pushq	%rdx
	pushq	%rsi
	pushq	%rdi
	pushq	%rbp
	pushq	%r8
	pushq	%r9
	pushq	%r10
	pushq	%r11
	pushq	%r12
	pushq	%r13
	pushq	%r14
	pushq	%r15
	cld
	movq	%rsp,		%rdi
	callq	intr
1:
	jmp	1b

.globl reboot
reboot:
	cli
1:
	inb	$0x64,		%al
	testb	$1,		%al
	je	2f
	inb	$0x60	/* consume kbd buffer */
2:
	testb	$2,		%al
	jne	1b
	movb	$0xfe,		%al	/* reset command */
	outb	%al,		$0x64
1:
	hlt
	jmp	1b

.globl cominit
cominit:
	/* Init COM port to 115200 */
	movw	$0x3f8,		%dx
	/* enable DLAB */
	addb	$3,		%dl
	movb	$0x80,		%al
	outb	%al,		%dx
	/* divisor lo */
	subb	$3,		%dl
	movb	$1,		%al
	outb	%al,		%dx
	/* divisor hi */
	xorb	%al,		%al
	addb	$1,		%dl
	outb	%al,		%dx
	/* 8b, np, 1s */
	addb	$2,		%dl
	movb	$3,		%al
	outb	%al,		%dx
	retq
