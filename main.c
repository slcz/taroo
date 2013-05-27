/*
 *2345678901234567890123456789012345678901234567890123456789012345678901234567
 */
#include <stdint.h>
#include <stand.h>
#include <machine.h>

struct {
	uint16_t limit;
	uint64_t offset;
} __attribute__((aligned(16), packed)) pidt;

struct gate {
	uint16_t	offlo;
	uint16_t	sel;
	uint8_t		ist;
	uint8_t		attr;
#define	GATE_TYPE_LDT		0x02
#define GATE_TYPE_A_TSS		0x09
#define GATE_TYPE_B_TSS		0x0B
#define GATE_TYPE_CALL		0x0C
#define GATE_TYPE_INT		0x0E
#define GATE_TYPE_TRAP		0x0F
#define GATE_PRESENT		0x80
	uint16_t	offmi;
	uint32_t	offhi;
	uint32_t	rsv;
} __attribute__((packed));

struct gate idt[NRIDT] __attribute((aligned(16)));

extern uint64_t _end[];
intptr_t avail;

#define ALIGN(p,x)	(((p) + (x) - 1) & ~((x) - 1))

void *
memset(void *s, int c, size_t n)
{
	uint32_t i;
	uint8_t *_s = (uint8_t *)s;

	for (i = 0; i < n; i ++)
		_s[i] = c;
	return (s);
}

void *
kalloc(uint32_t size, uint32_t align)
{
	void *addr;

	avail = ALIGN(avail, align);
	addr  = (void *)avail;
	avail += size;
	return (addr);
}

void loadidt(void *);
void cominit(void);
void reboot(void);

void exc_div0(void);
void exc_dbg(void);
void exc_nmi(void);
void exc_bp(void);
void exc_of(void);
void exc_br(void);
void exc_ud(void);
void exc_nm(void);
void exc_df(void);
void exc_reserved(void);
void exc_tss(void);
void exc_np(void);
void exc_ss(void);
void exc_gp(void);
void exc_pf(void);
void exc_mf(void);
void exc_ac(void);
void exc_mc(void);
void exc_xf(void);

void (*except[])(void) = {
	exc_div0, exc_dbg, exc_nmi, exc_bp,
	exc_of, exc_br, exc_ud, exc_nm,
	exc_df, exc_reserved, exc_tss, exc_np,
	exc_ss, exc_gp, exc_pf, exc_reserved,
	exc_mf, exc_ac, exc_mc, exc_xf,
	exc_reserved, exc_reserved, exc_reserved, exc_reserved,
	exc_reserved, exc_reserved, exc_reserved, exc_reserved,
	exc_reserved, exc_reserved, exc_reserved, exc_reserved
};

int a = 0, b = 0;

int
init64(uint32_t *mem)
{
	intptr_t addr;
	uint32_t *memmap = (uint32_t *)0x8000;
	int i;

	memset(idt, 0, sizeof(idt));

	cominit();
	printf("HELLO WORLD\n");
	for (;memmap[5]; memmap += 6) {
		printf("%x %x | %x %x | %x %x\n", memmap[0], memmap[1], memmap[2], memmap[3], memmap[4], memmap[5]);
	}

	avail = (intptr_t)_end;
	avail += KSTACK_SIZE;
	pidt.limit  = sizeof(idt) - 1;
	pidt.offset = (uint64_t)idt;
	for (i = 0; i < 32; i ++) {
		addr = (intptr_t)(except[i]);
		idt[i].offlo = (uint16_t)((addr) & 0xFFFF);
		idt[i].offmi = (uint16_t)(((addr) >> 16) & 0xFFFF);
		idt[i].offhi = (uint32_t)((addr) >> 32);
		idt[i].rsv   = 0;
		idt[i].sel   = 8;
		idt[i].attr  = GATE_TYPE_INT | GATE_PRESENT;
		idt[i].ist   = 0;
	}
	loadidt(&pidt);
	a = a / b;

	return (0);
}

struct frame {
	uint64_t	r15, r14, r13, r12;
	uint64_t	r11, r10, r9,  r8;
	uint64_t	rbp, rdi, rsi, rdx;
	uint64_t	rcx, rbx, rax, vec;
	uint64_t	error_code, rip, rcs, rflag;
	uint64_t	rsp, rss;
};

void
intr(struct frame *frame)
{
	printf("EXCEPTION\n");
	printf("rax=%lx\n", frame->rax);
	printf("rbx=%lx\n", frame->rbx);
	printf("rcx=%lx\n", frame->rcx);
	printf("rdx=%lx\n", frame->rdx);
	printf("rsi=%lx\n", frame->rsi);
	printf("rdi=%lx\n", frame->rdi);
	printf("rsp=%lx\n", frame->rsp);
	printf("rbp=%lx\n", frame->rbp);
	printf("r8=%lx\n", frame->r8);
	printf("r9=%lx\n", frame->r9);
	printf("r10=%lx\n", frame->r10);
	printf("r11=%lx\n", frame->r11);
	printf("r12=%lx\n", frame->r12);
	printf("r13=%lx\n", frame->r13);
	printf("r14=%lx\n", frame->r14);
	printf("r15=%lx\n", frame->r15);
	printf("vec=%lx\n", frame->vec);
	printf("error=%lx\n", frame->error_code);
	printf("rip=%lx\n", frame->rip);
	printf("rcs=%lx\n", frame->rcs);
	printf("rflag=%lx\n", frame->rflag);
	printf("rss=%lx\n", frame->rss);
	reboot();
}
