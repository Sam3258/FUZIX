/*
 *	Functionality only used in the 32bit ports
 */

#ifndef __FUZIX__KERNEL_32_H
#define __FUZIX__KERNEL_32_H

/* malloc.c */
extern void *kmalloc(size_t);
extern void *kzalloc(size_t);
extern void kfree(void *);
extern void kmemaddblk(void *, size_t);
extern unsigned long kmemavail(void);
extern unsigned long kmemused(void);

#if defined(CONFIG_FLAT)

/* flat.c */
extern void pagemap_switch(ptptr p);
extern void *pagemap_base(void);
#define PROGLOAD (uint32_t)pagemap_base()
#define PROGTOP	0 /* dummy */

#endif

extern uint32_t ugetl(void *uaddr);
extern int uputl(uint32_t val, void *uaddr);

#endif
