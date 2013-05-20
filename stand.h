#ifndef __STAND_H__
#define __STAND_H__

void putchar(int);
void vprintf(const char *, va_list);
int vsnprintf(char *, size_t, const char *, va_list);
void printf(const char *, ...);

#endif
