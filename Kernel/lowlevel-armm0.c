#include <kernel.h>
#include <kdata.h>
#include <printf.h>
#include <stdarg.h>

/* Called with interrupts off and on the user stack, immediately before
 * returning into the user program. A signal may longjmp out, so this may not
 * return. */
void deliver_signals(void)
{
	uint8_t cursig = udata.u_cursig;
	if (cursig)
	{
		panic("signals not supported yet");
	}
}

void doexec(uaddr_t entrypoint)
{
	asm volatile ("mov sp, %0\nisb\nbx %1"
		:: "r" (udata.u_sp), "r" (entrypoint));
    __builtin_unreachable();
}
