
OBJS=boot.o main.o printf.o subr_prf.o vsprintf.o

LDS=taroo.lds
CC=gcc
HOSTCC=gcc
LD=ld
OBJCOPY=objcopy

LDS=taroo.lds

CFLAGS=-c -fno-builtin -g -O2 -I. -pipe -Wall -Werror -nostdinc

LDFLAGS=-nostdlib -Wl,-e,_start -Wl,-T./taroo.lds -Wl,--build-id=none -Wl,-Ttext=0x100000

taroo.vdi: taroo.bin
	@dd if=$^ of=$^.dsk ibs=1G conv=sync,sparse
	@rm -f $@
	@vboxmanage convertfromraw $^.dsk $@ --uuid 6fc5e387-dcc8-4578-be77-fa8aa7dc8a74

imghdr: imghdr.c
	$(HOSTCC)	-O2 $^ -o $@

taroo.bin: taroo.elf imghdr
	@$(OBJCOPY) -O binary taroo.elf $@
	@./imghdr $@

taroo.elf: $(OBJS)
	@echo -n "Linking $@		--- "
	@$(CC) -o $@ $(LDFLAGS) $(OBJS)
	@echo "Done"

clean:
	@rm -f imghdr taroo.elf taroo.bin $(OBJS) $(OBJS:.o=.d) taroo.bin.dsk taroo.vdi

%.o: %.c
	@echo -n "Building $@		--- "
	@$(CC) -c $(CFLAGS) $*.c -o $*.o
	@$(CC) -MM $(CFLAGS) $*.c > $*.d
	@cp -f $*.d $*.d.tmp
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
		sed -e 's/^ *//' -e 's/$$/:/' -e 's/^.*\.o:/&/' >> $*.d
	@rm -f $*.d.tmp
	@sed -i -e 's/^.*\.o:/&/' $*.d
	@echo "Done"

%.o: %.S
	@echo -n "Building $@		--- "
	@$(CC) -c $(CFLAGS) $*.S -o $*.o
	@$(CC) -MM $(CFLAGS) $*.S > $*.d
	@cp -f $*.d $*.d.tmp
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
		sed -e 's/^ *//' -e 's/$$/:/' -e 's/^.*\.o:/&/' >> $*.d
	@rm -f $*.d.tmp
	@sed -i -e 's/^.*\.o:/&/' $*.d
	@echo "Done"
