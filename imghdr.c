#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

/* Patch a kernel image with header */

struct header {
#define IMG_MAGIC	0x124620AB
	uint32_t magic;
	uint32_t size;
	uint32_t cksum;
	uint32_t drv;
} hdr;

int
main(int argc, char **argv)
{
	char *name = argv[1];
	uint32_t buf[32 * 1024 / sizeof(uint32_t)];
	int fd, i;
	uint32_t sum = 0, size = 0;

	hdr.magic = IMG_MAGIC;
	hdr.drv   = 0x80;
	fd = open(name, O_RDWR);
	if (fd < 0)
		return (0);
	while (read(fd, buf, sizeof(buf)) > 0)
		size += sizeof(buf);
	hdr.size  = size;
	hdr.cksum = 0;
	lseek(fd, 4, SEEK_SET);
	(void)write(fd, &hdr, sizeof(hdr));
	lseek(fd, 0, SEEK_SET);
	memset(buf, 0, sizeof(buf));
	while (read(fd, buf, sizeof(buf)) > 0) {
		for (i = 0; i < sizeof(buf) / sizeof(uint32_t); i ++)
			sum += buf[i];
		memset(buf, 0, sizeof(buf));
	}
	hdr.cksum = ~sum + 1;
	lseek(fd, 4, SEEK_SET);
	(void)write(fd, &hdr, sizeof(hdr));
	close(fd);

	return (0);
}
