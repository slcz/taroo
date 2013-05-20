
OUTPUT_FORMAT(	"elf64-x86-64",
		"elf64-x86-64",
		"elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

SECTIONS
{
	.text :
	{
		boot.o(.text)
		*(.text .text.*)
		*(.text .text.*)
		*(.rodata .rodata.*)
		. = ALIGN(8);
	}
	_etext = .;

	.data :
	{
		*.(.data .data.*)
		. = ALIGN(8);
	}
	_edata = .;

	.bss :
	{
		*(.bss .bss.*)
		*(COMMON)
		. = ALIGN(8);
	}
	_end = .;
}
