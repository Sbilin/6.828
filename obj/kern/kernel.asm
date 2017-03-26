
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 be 55 00 00       	call   f010561f <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 5c 10 f0       	push   $0xf0105cc0
f010006d:	e8 4b 35 00 00       	call   f01035bd <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 1b 35 00 00       	call   f0103597 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 29 6e 10 f0 	movl   $0xf0106e29,(%esp)
f0100083:	e8 35 35 00 00       	call   f01035bd <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 ec 07 00 00       	call   f0100881 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 c0 26 f0       	mov    $0xf026c008,%eax
f01000a6:	2d b0 92 22 f0       	sub    $0xf02292b0,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 b0 92 22 f0       	push   $0xf02292b0
f01000b3:	e8 31 4f 00 00       	call   f0104fe9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 5d 10 f0       	push   $0xf0105d2c
f01000ca:	e8 ee 34 00 00       	call   f01035bd <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 34 11 00 00       	call   f0101208 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 39 2d 00 00       	call   f0102e12 <env_init>
	trap_init();
f01000d9:	e8 c5 35 00 00       	call   f01036a3 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 1d 52 00 00       	call   f0105300 <mp_init>
	lapic_init();
f01000e3:	e8 52 55 00 00       	call   f010563a <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 f7 33 00 00       	call   f01034e4 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 94 57 00 00       	call   f010588d <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 5c 10 f0       	push   $0xf0105ce4
f010010f:	6a 59                	push   $0x59
f0100111:	68 47 5d 10 f0       	push   $0xf0105d47
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 66 52 10 f0       	mov    $0xf0105266,%eax
f0100123:	2d ec 51 10 f0       	sub    $0xf01051ec,%eax
f0100128:	50                   	push   %eax
f0100129:	68 ec 51 10 f0       	push   $0xf01051ec
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 fe 4e 00 00       	call   f0105036 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 d8 54 00 00       	call   f010561f <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010016b:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 07 56 00 00       	call   f0105788 <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0100196:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST) 
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 a0 fb 19 f0       	push   $0xf019fba0
f01001a9:	e8 30 2e 00 00       	call   f0102fde <env_create>
	//ENV_CREATE(user_hello, ENV_TYPE_USER);
	
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 e3 3d 00 00       	call   f0103f96 <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 08 5d 10 f0       	push   $0xf0105d08
f01001cb:	6a 70                	push   $0x70
f01001cd:	68 47 5d 10 f0       	push   $0xf0105d47
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 3b 54 00 00       	call   f010561f <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 53 5d 10 f0       	push   $0xf0105d53
f01001ed:	e8 cb 33 00 00       	call   f01035bd <cprintf>

	lapic_init();
f01001f2:	e8 43 54 00 00       	call   f010563a <lapic_init>
	env_init_percpu();
f01001f7:	e8 e6 2b 00 00       	call   f0102de2 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 d0 33 00 00       	call   f01035d1 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 19 54 00 00       	call   f010561f <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 69 56 00 00       	call   f010588d <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 6d 3d 00 00       	call   f0103f96 <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 69 5d 10 f0       	push   $0xf0105d69
f010023e:	e8 7a 33 00 00       	call   f01035bd <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 48 33 00 00       	call   f0103597 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 29 6e 10 f0 	movl   $0xf0106e29,(%esp)
f0100256:	e8 62 33 00 00       	call   f01035bd <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f01002a0:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f8 00 00 00    	je     f01003cb <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002d3:	a8 20                	test   $0x20,%al
f01002d5:	0f 85 f6 00 00 00    	jne    f01003d1 <kbd_proc_data+0x10c>
f01002db:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 36                	jns    f0100335 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 e0 5e 10 f0 	movzbl -0xfefa120(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 e0 5e 10 f0 	movzbl -0xfefa120(%edx),%eax
f0100358:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010035e:	0f b6 8a e0 5d 10 f0 	movzbl -0xfefa220(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d c0 5d 10 f0 	mov    -0xfefa240(,%ecx,4),%ecx
f0100378:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010037f:	a8 08                	test   $0x8,%al
f0100381:	74 1b                	je     f010039e <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100383:	89 da                	mov    %ebx,%edx
f0100385:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100388:	83 f9 19             	cmp    $0x19,%ecx
f010038b:	77 05                	ja     f0100392 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010038d:	83 eb 20             	sub    $0x20,%ebx
f0100390:	eb 0c                	jmp    f010039e <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 19             	cmp    $0x19,%edx
f010039b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 33                	jne    f01003d7 <kbd_proc_data+0x112>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 2b                	jne    f01003d7 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 83 5d 10 f0       	push   $0xf0105d83
f01003b4:	e8 04 32 00 00       	call   f01035bd <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	ba 92 00 00 00       	mov    $0x92,%edx
f01003be:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c7:	89 d8                	mov    %ebx,%eax
f01003c9:	eb 0e                	jmp    f01003d9 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d0:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d7:	89 d8                	mov    %ebx,%eax
}
f01003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003dc:	c9                   	leave  
f01003dd:	c3                   	ret    

f01003de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
f01003e1:	57                   	push   %edi
f01003e2:	56                   	push   %esi
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 1c             	sub    $0x1c,%esp
f01003e7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003e9:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ee:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f8:	eb 09                	jmp    f0100403 <cons_putc+0x25>
f01003fa:	89 ca                	mov    %ecx,%edx
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	ec                   	in     (%dx),%al
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100400:	83 c3 01             	add    $0x1,%ebx
f0100403:	89 f2                	mov    %esi,%edx
f0100405:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100406:	a8 20                	test   $0x20,%al
f0100408:	75 08                	jne    f0100412 <cons_putc+0x34>
f010040a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100410:	7e e8                	jle    f01003fa <cons_putc+0x1c>
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100417:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010041c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100422:	be 79 03 00 00       	mov    $0x379,%esi
f0100427:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042c:	eb 09                	jmp    f0100437 <cons_putc+0x59>
f010042e:	89 ca                	mov    %ecx,%edx
f0100430:	ec                   	in     (%dx),%al
f0100431:	ec                   	in     (%dx),%al
f0100432:	ec                   	in     (%dx),%al
f0100433:	ec                   	in     (%dx),%al
f0100434:	83 c3 01             	add    $0x1,%ebx
f0100437:	89 f2                	mov    %esi,%edx
f0100439:	ec                   	in     (%dx),%al
f010043a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100440:	7f 04                	jg     f0100446 <cons_putc+0x68>
f0100442:	84 c0                	test   %al,%al
f0100444:	79 e8                	jns    f010042e <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100455:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100460:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100461:	89 fa                	mov    %edi,%edx
f0100463:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100469:	89 f8                	mov    %edi,%eax
f010046b:	80 cc 07             	or     $0x7,%ah
f010046e:	85 d2                	test   %edx,%edx
f0100470:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100473:	89 f8                	mov    %edi,%eax
f0100475:	0f b6 c0             	movzbl %al,%eax
f0100478:	83 f8 09             	cmp    $0x9,%eax
f010047b:	74 74                	je     f01004f1 <cons_putc+0x113>
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	7f 0a                	jg     f010048c <cons_putc+0xae>
f0100482:	83 f8 08             	cmp    $0x8,%eax
f0100485:	74 14                	je     f010049b <cons_putc+0xbd>
f0100487:	e9 99 00 00 00       	jmp    f0100525 <cons_putc+0x147>
f010048c:	83 f8 0a             	cmp    $0xa,%eax
f010048f:	74 3a                	je     f01004cb <cons_putc+0xed>
f0100491:	83 f8 0d             	cmp    $0xd,%eax
f0100494:	74 3d                	je     f01004d3 <cons_putc+0xf5>
f0100496:	e9 8a 00 00 00       	jmp    f0100525 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010049b:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004ef:	eb 52                	jmp    f0100543 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 e3 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 d9 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 cf fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 c5 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 bb fe ff ff       	call   f01003de <cons_putc>
f0100523:	eb 1e                	jmp    f0100543 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100525:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 ce 4a 00 00       	call   f0105036 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010056e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100574:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057a:	83 c4 10             	add    $0x10,%esp
f010057d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100582:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100585:	39 d0                	cmp    %edx,%eax
f0100587:	75 f4                	jne    f010057d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100589:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f01005a6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005a9:	89 d8                	mov    %ebx,%eax
f01005ab:	66 c1 e8 08          	shr    $0x8,%ax
f01005af:	89 f2                	mov    %esi,%edx
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c2:	5b                   	pop    %ebx
f01005c3:	5e                   	pop    %esi
f01005c4:	5f                   	pop    %edi
f01005c5:	5d                   	pop    %ebp
f01005c6:	c3                   	ret    

f01005c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005c7:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005ce:	74 11                	je     f01005e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005d6:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005db:	e8 a2 fc ff ff       	call   f0100282 <cons_intr>
}
f01005e0:	c9                   	leave  
f01005e1:	f3 c3                	repz ret 

f01005e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e3:	55                   	push   %ebp
f01005e4:	89 e5                	mov    %esp,%ebp
f01005e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005e9:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005ee:	e8 8f fc ff ff       	call   f0100282 <cons_intr>
}
f01005f3:	c9                   	leave  
f01005f4:	c3                   	ret    

f01005f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005fb:	e8 c7 ff ff ff       	call   f01005c7 <serial_intr>
	kbd_intr();
f0100600:	e8 de ff ff ff       	call   f01005e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100605:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f010060a:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f010061b:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100622:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100624:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062a:	75 11                	jne    f010063d <cons_getc+0x48>
			cons.rpos = 0;
f010062c:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f0100633:	00 00 00 
f0100636:	eb 05                	jmp    f010063d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	57                   	push   %edi
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100648:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100656:	5a a5 
	if (*cp != 0xA55A) {
f0100658:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100663:	74 11                	je     f0100676 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100665:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f010066c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100674:	eb 16                	jmp    f010068c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100676:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010067d:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f0100684:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100687:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010068c:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f0100692:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100697:	89 fa                	mov    %edi,%edx
f0100699:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069a:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069d:	89 da                	mov    %ebx,%edx
f010069f:	ec                   	in     (%dx),%al
f01006a0:	0f b6 c8             	movzbl %al,%ecx
f01006a3:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 da                	mov    %ebx,%edx
f01006b0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b1:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 90 2d 00 00       	call   f010346c <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e6:	89 f2                	mov    %esi,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006ee:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006f9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ee                   	out    %al,(%dx)
f0100701:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100706:	b8 00 00 00 00       	mov    $0x0,%eax
f010070b:	ee                   	out    %al,(%dx)
f010070c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100711:	b8 03 00 00 00       	mov    $0x3,%eax
f0100716:	ee                   	out    %al,(%dx)
f0100717:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100727:	b8 01 00 00 00       	mov    $0x1,%eax
f010072c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100732:	ec                   	in     (%dx),%al
f0100733:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100735:	83 c4 10             	add    $0x10,%esp
f0100738:	3c ff                	cmp    $0xff,%al
f010073a:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f0100741:	89 f2                	mov    %esi,%edx
f0100743:	ec                   	in     (%dx),%al
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	80 f9 ff             	cmp    $0xff,%cl
f010074a:	75 10                	jne    f010075c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 8f 5d 10 f0       	push   $0xf0105d8f
f0100754:	e8 64 2e 00 00       	call   f01035bd <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010075f:	5b                   	pop    %ebx
f0100760:	5e                   	pop    %esi
f0100761:	5f                   	pop    %edi
f0100762:	5d                   	pop    %ebp
f0100763:	c3                   	ret    

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 6c fc ff ff       	call   f01003de <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 76 fe ff ff       	call   f01005f5 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100795:	68 e0 5f 10 f0       	push   $0xf0105fe0
f010079a:	68 fe 5f 10 f0       	push   $0xf0105ffe
f010079f:	68 03 60 10 f0       	push   $0xf0106003
f01007a4:	e8 14 2e 00 00       	call   f01035bd <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 6c 60 10 f0       	push   $0xf010606c
f01007b1:	68 0c 60 10 f0       	push   $0xf010600c
f01007b6:	68 03 60 10 f0       	push   $0xf0106003
f01007bb:	e8 fd 2d 00 00       	call   f01035bd <cprintf>
	return 0;
}
f01007c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c5:	c9                   	leave  
f01007c6:	c3                   	ret    

f01007c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c7:	55                   	push   %ebp
f01007c8:	89 e5                	mov    %esp,%ebp
f01007ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007cd:	68 15 60 10 f0       	push   $0xf0106015
f01007d2:	e8 e6 2d 00 00       	call   f01035bd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d7:	83 c4 08             	add    $0x8,%esp
f01007da:	68 0c 00 10 00       	push   $0x10000c
f01007df:	68 94 60 10 f0       	push   $0xf0106094
f01007e4:	e8 d4 2d 00 00       	call   f01035bd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	68 0c 00 10 00       	push   $0x10000c
f01007f1:	68 0c 00 10 f0       	push   $0xf010000c
f01007f6:	68 bc 60 10 f0       	push   $0xf01060bc
f01007fb:	e8 bd 2d 00 00       	call   f01035bd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 a1 5c 10 00       	push   $0x105ca1
f0100808:	68 a1 5c 10 f0       	push   $0xf0105ca1
f010080d:	68 e0 60 10 f0       	push   $0xf01060e0
f0100812:	e8 a6 2d 00 00       	call   f01035bd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 b0 92 22 00       	push   $0x2292b0
f010081f:	68 b0 92 22 f0       	push   $0xf02292b0
f0100824:	68 04 61 10 f0       	push   $0xf0106104
f0100829:	e8 8f 2d 00 00       	call   f01035bd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 08 c0 26 00       	push   $0x26c008
f0100836:	68 08 c0 26 f0       	push   $0xf026c008
f010083b:	68 28 61 10 f0       	push   $0xf0106128
f0100840:	e8 78 2d 00 00       	call   f01035bd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100845:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f010084a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084f:	83 c4 08             	add    $0x8,%esp
f0100852:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100857:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010085d:	85 c0                	test   %eax,%eax
f010085f:	0f 48 c2             	cmovs  %edx,%eax
f0100862:	c1 f8 0a             	sar    $0xa,%eax
f0100865:	50                   	push   %eax
f0100866:	68 4c 61 10 f0       	push   $0xf010614c
f010086b:	e8 4d 2d 00 00       	call   f01035bd <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100870:	b8 00 00 00 00       	mov    $0x0,%eax
f0100875:	c9                   	leave  
f0100876:	c3                   	ret    

f0100877 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100877:	55                   	push   %ebp
f0100878:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010087a:	b8 00 00 00 00       	mov    $0x0,%eax
f010087f:	5d                   	pop    %ebp
f0100880:	c3                   	ret    

f0100881 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100881:	55                   	push   %ebp
f0100882:	89 e5                	mov    %esp,%ebp
f0100884:	57                   	push   %edi
f0100885:	56                   	push   %esi
f0100886:	53                   	push   %ebx
f0100887:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010088a:	68 78 61 10 f0       	push   $0xf0106178
f010088f:	e8 29 2d 00 00       	call   f01035bd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100894:	c7 04 24 9c 61 10 f0 	movl   $0xf010619c,(%esp)
f010089b:	e8 1d 2d 00 00       	call   f01035bd <cprintf>

	if (tf != NULL)
f01008a0:	83 c4 10             	add    $0x10,%esp
f01008a3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008a7:	74 0e                	je     f01008b7 <monitor+0x36>
		print_trapframe(tf);
f01008a9:	83 ec 0c             	sub    $0xc,%esp
f01008ac:	ff 75 08             	pushl  0x8(%ebp)
f01008af:	e8 b9 31 00 00       	call   f0103a6d <print_trapframe>
f01008b4:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01008b7:	83 ec 0c             	sub    $0xc,%esp
f01008ba:	68 2e 60 10 f0       	push   $0xf010602e
f01008bf:	e8 ce 44 00 00       	call   f0104d92 <readline>
f01008c4:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008c6:	83 c4 10             	add    $0x10,%esp
f01008c9:	85 c0                	test   %eax,%eax
f01008cb:	74 ea                	je     f01008b7 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008cd:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008d4:	be 00 00 00 00       	mov    $0x0,%esi
f01008d9:	eb 0a                	jmp    f01008e5 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008db:	c6 03 00             	movb   $0x0,(%ebx)
f01008de:	89 f7                	mov    %esi,%edi
f01008e0:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008e3:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008e5:	0f b6 03             	movzbl (%ebx),%eax
f01008e8:	84 c0                	test   %al,%al
f01008ea:	74 63                	je     f010094f <monitor+0xce>
f01008ec:	83 ec 08             	sub    $0x8,%esp
f01008ef:	0f be c0             	movsbl %al,%eax
f01008f2:	50                   	push   %eax
f01008f3:	68 32 60 10 f0       	push   $0xf0106032
f01008f8:	e8 af 46 00 00       	call   f0104fac <strchr>
f01008fd:	83 c4 10             	add    $0x10,%esp
f0100900:	85 c0                	test   %eax,%eax
f0100902:	75 d7                	jne    f01008db <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100904:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100907:	74 46                	je     f010094f <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100909:	83 fe 0f             	cmp    $0xf,%esi
f010090c:	75 14                	jne    f0100922 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010090e:	83 ec 08             	sub    $0x8,%esp
f0100911:	6a 10                	push   $0x10
f0100913:	68 37 60 10 f0       	push   $0xf0106037
f0100918:	e8 a0 2c 00 00       	call   f01035bd <cprintf>
f010091d:	83 c4 10             	add    $0x10,%esp
f0100920:	eb 95                	jmp    f01008b7 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100922:	8d 7e 01             	lea    0x1(%esi),%edi
f0100925:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100929:	eb 03                	jmp    f010092e <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010092b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010092e:	0f b6 03             	movzbl (%ebx),%eax
f0100931:	84 c0                	test   %al,%al
f0100933:	74 ae                	je     f01008e3 <monitor+0x62>
f0100935:	83 ec 08             	sub    $0x8,%esp
f0100938:	0f be c0             	movsbl %al,%eax
f010093b:	50                   	push   %eax
f010093c:	68 32 60 10 f0       	push   $0xf0106032
f0100941:	e8 66 46 00 00       	call   f0104fac <strchr>
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	85 c0                	test   %eax,%eax
f010094b:	74 de                	je     f010092b <monitor+0xaa>
f010094d:	eb 94                	jmp    f01008e3 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f010094f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100956:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100957:	85 f6                	test   %esi,%esi
f0100959:	0f 84 58 ff ff ff    	je     f01008b7 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010095f:	83 ec 08             	sub    $0x8,%esp
f0100962:	68 fe 5f 10 f0       	push   $0xf0105ffe
f0100967:	ff 75 a8             	pushl  -0x58(%ebp)
f010096a:	e8 df 45 00 00       	call   f0104f4e <strcmp>
f010096f:	83 c4 10             	add    $0x10,%esp
f0100972:	85 c0                	test   %eax,%eax
f0100974:	74 1e                	je     f0100994 <monitor+0x113>
f0100976:	83 ec 08             	sub    $0x8,%esp
f0100979:	68 0c 60 10 f0       	push   $0xf010600c
f010097e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100981:	e8 c8 45 00 00       	call   f0104f4e <strcmp>
f0100986:	83 c4 10             	add    $0x10,%esp
f0100989:	85 c0                	test   %eax,%eax
f010098b:	75 2f                	jne    f01009bc <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010098d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100992:	eb 05                	jmp    f0100999 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100994:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100999:	83 ec 04             	sub    $0x4,%esp
f010099c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010099f:	01 d0                	add    %edx,%eax
f01009a1:	ff 75 08             	pushl  0x8(%ebp)
f01009a4:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01009a7:	51                   	push   %ecx
f01009a8:	56                   	push   %esi
f01009a9:	ff 14 85 cc 61 10 f0 	call   *-0xfef9e34(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009b0:	83 c4 10             	add    $0x10,%esp
f01009b3:	85 c0                	test   %eax,%eax
f01009b5:	78 1d                	js     f01009d4 <monitor+0x153>
f01009b7:	e9 fb fe ff ff       	jmp    f01008b7 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009bc:	83 ec 08             	sub    $0x8,%esp
f01009bf:	ff 75 a8             	pushl  -0x58(%ebp)
f01009c2:	68 54 60 10 f0       	push   $0xf0106054
f01009c7:	e8 f1 2b 00 00       	call   f01035bd <cprintf>
f01009cc:	83 c4 10             	add    $0x10,%esp
f01009cf:	e9 e3 fe ff ff       	jmp    f01008b7 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009d7:	5b                   	pop    %ebx
f01009d8:	5e                   	pop    %esi
f01009d9:	5f                   	pop    %edi
f01009da:	5d                   	pop    %ebp
f01009db:	c3                   	ret    

f01009dc <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009dc:	55                   	push   %ebp
f01009dd:	89 e5                	mov    %esp,%ebp
f01009df:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009e1:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f01009e8:	75 0f                	jne    f01009f9 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ea:	b8 07 d0 26 f0       	mov    $0xf026d007,%eax
f01009ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f4:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009f9:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f01009fe:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100a04:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a0a:	01 c2                	add    %eax,%edx
f0100a0c:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	return result;
}
f0100a12:	5d                   	pop    %ebp
f0100a13:	c3                   	ret    

f0100a14 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a14:	55                   	push   %ebp
f0100a15:	89 e5                	mov    %esp,%ebp
f0100a17:	56                   	push   %esi
f0100a18:	53                   	push   %ebx
f0100a19:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a1b:	83 ec 0c             	sub    $0xc,%esp
f0100a1e:	50                   	push   %eax
f0100a1f:	e8 1a 2a 00 00       	call   f010343e <mc146818_read>
f0100a24:	89 c6                	mov    %eax,%esi
f0100a26:	83 c3 01             	add    $0x1,%ebx
f0100a29:	89 1c 24             	mov    %ebx,(%esp)
f0100a2c:	e8 0d 2a 00 00       	call   f010343e <mc146818_read>
f0100a31:	c1 e0 08             	shl    $0x8,%eax
f0100a34:	09 f0                	or     %esi,%eax
}
f0100a36:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a39:	5b                   	pop    %ebx
f0100a3a:	5e                   	pop    %esi
f0100a3b:	5d                   	pop    %ebp
f0100a3c:	c3                   	ret    

f0100a3d <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a3d:	89 d1                	mov    %edx,%ecx
f0100a3f:	c1 e9 16             	shr    $0x16,%ecx
f0100a42:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a45:	a8 01                	test   $0x1,%al
f0100a47:	74 52                	je     f0100a9b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a4e:	89 c1                	mov    %eax,%ecx
f0100a50:	c1 e9 0c             	shr    $0xc,%ecx
f0100a53:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100a59:	72 1b                	jb     f0100a76 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a5b:	55                   	push   %ebp
f0100a5c:	89 e5                	mov    %esp,%ebp
f0100a5e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a61:	50                   	push   %eax
f0100a62:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0100a67:	68 94 03 00 00       	push   $0x394
f0100a6c:	68 49 6b 10 f0       	push   $0xf0106b49
f0100a71:	e8 ca f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a76:	c1 ea 0c             	shr    $0xc,%edx
f0100a79:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a7f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a86:	89 c2                	mov    %eax,%edx
f0100a88:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a8b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a90:	85 d2                	test   %edx,%edx
f0100a92:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a97:	0f 44 c2             	cmove  %edx,%eax
f0100a9a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100aa0:	c3                   	ret    

f0100aa1 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100aa1:	55                   	push   %ebp
f0100aa2:	89 e5                	mov    %esp,%ebp
f0100aa4:	57                   	push   %edi
f0100aa5:	56                   	push   %esi
f0100aa6:	53                   	push   %ebx
f0100aa7:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aaa:	84 c0                	test   %al,%al
f0100aac:	0f 85 a0 02 00 00    	jne    f0100d52 <check_page_free_list+0x2b1>
f0100ab2:	e9 ad 02 00 00       	jmp    f0100d64 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ab7:	83 ec 04             	sub    $0x4,%esp
f0100aba:	68 dc 61 10 f0       	push   $0xf01061dc
f0100abf:	68 c7 02 00 00       	push   $0x2c7
f0100ac4:	68 49 6b 10 f0       	push   $0xf0106b49
f0100ac9:	e8 72 f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ace:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ad1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ad4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ad7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100ae2:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ae8:	0f 95 c2             	setne  %dl
f0100aeb:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100aee:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100af2:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100af4:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af8:	8b 00                	mov    (%eax),%eax
f0100afa:	85 c0                	test   %eax,%eax
f0100afc:	75 dc                	jne    f0100ada <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100afe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b01:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b07:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b0a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b0d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b0f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b12:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b17:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b1c:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100b22:	eb 53                	jmp    f0100b77 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b24:	89 d8                	mov    %ebx,%eax
f0100b26:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100b2c:	c1 f8 03             	sar    $0x3,%eax
f0100b2f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b32:	89 c2                	mov    %eax,%edx
f0100b34:	c1 ea 16             	shr    $0x16,%edx
f0100b37:	39 f2                	cmp    %esi,%edx
f0100b39:	73 3a                	jae    f0100b75 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b3b:	89 c2                	mov    %eax,%edx
f0100b3d:	c1 ea 0c             	shr    $0xc,%edx
f0100b40:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100b46:	72 12                	jb     f0100b5a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b48:	50                   	push   %eax
f0100b49:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0100b4e:	6a 58                	push   $0x58
f0100b50:	68 55 6b 10 f0       	push   $0xf0106b55
f0100b55:	e8 e6 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b5a:	83 ec 04             	sub    $0x4,%esp
f0100b5d:	68 80 00 00 00       	push   $0x80
f0100b62:	68 97 00 00 00       	push   $0x97
f0100b67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6c:	50                   	push   %eax
f0100b6d:	e8 77 44 00 00       	call   f0104fe9 <memset>
f0100b72:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b75:	8b 1b                	mov    (%ebx),%ebx
f0100b77:	85 db                	test   %ebx,%ebx
f0100b79:	75 a9                	jne    f0100b24 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b80:	e8 57 fe ff ff       	call   f01009dc <boot_alloc>
f0100b85:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b88:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b8e:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100b94:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100b99:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b9c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba2:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ba5:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100baa:	e9 52 01 00 00       	jmp    f0100d01 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100baf:	39 ca                	cmp    %ecx,%edx
f0100bb1:	73 19                	jae    f0100bcc <check_page_free_list+0x12b>
f0100bb3:	68 63 6b 10 f0       	push   $0xf0106b63
f0100bb8:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100bbd:	68 e1 02 00 00       	push   $0x2e1
f0100bc2:	68 49 6b 10 f0       	push   $0xf0106b49
f0100bc7:	e8 74 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bcc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bcf:	72 19                	jb     f0100bea <check_page_free_list+0x149>
f0100bd1:	68 84 6b 10 f0       	push   $0xf0106b84
f0100bd6:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100bdb:	68 e2 02 00 00       	push   $0x2e2
f0100be0:	68 49 6b 10 f0       	push   $0xf0106b49
f0100be5:	e8 56 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bea:	89 d0                	mov    %edx,%eax
f0100bec:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bef:	a8 07                	test   $0x7,%al
f0100bf1:	74 19                	je     f0100c0c <check_page_free_list+0x16b>
f0100bf3:	68 00 62 10 f0       	push   $0xf0106200
f0100bf8:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100bfd:	68 e3 02 00 00       	push   $0x2e3
f0100c02:	68 49 6b 10 f0       	push   $0xf0106b49
f0100c07:	e8 34 f4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c0c:	c1 f8 03             	sar    $0x3,%eax
f0100c0f:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c12:	85 c0                	test   %eax,%eax
f0100c14:	75 19                	jne    f0100c2f <check_page_free_list+0x18e>
f0100c16:	68 98 6b 10 f0       	push   $0xf0106b98
f0100c1b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100c20:	68 e6 02 00 00       	push   $0x2e6
f0100c25:	68 49 6b 10 f0       	push   $0xf0106b49
f0100c2a:	e8 11 f4 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c34:	75 19                	jne    f0100c4f <check_page_free_list+0x1ae>
f0100c36:	68 a9 6b 10 f0       	push   $0xf0106ba9
f0100c3b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100c40:	68 e7 02 00 00       	push   $0x2e7
f0100c45:	68 49 6b 10 f0       	push   $0xf0106b49
f0100c4a:	e8 f1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c54:	75 19                	jne    f0100c6f <check_page_free_list+0x1ce>
f0100c56:	68 34 62 10 f0       	push   $0xf0106234
f0100c5b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100c60:	68 e8 02 00 00       	push   $0x2e8
f0100c65:	68 49 6b 10 f0       	push   $0xf0106b49
f0100c6a:	e8 d1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c74:	75 19                	jne    f0100c8f <check_page_free_list+0x1ee>
f0100c76:	68 c2 6b 10 f0       	push   $0xf0106bc2
f0100c7b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100c80:	68 e9 02 00 00       	push   $0x2e9
f0100c85:	68 49 6b 10 f0       	push   $0xf0106b49
f0100c8a:	e8 b1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c8f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c94:	0f 86 f1 00 00 00    	jbe    f0100d8b <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c9a:	89 c7                	mov    %eax,%edi
f0100c9c:	c1 ef 0c             	shr    $0xc,%edi
f0100c9f:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100ca2:	77 12                	ja     f0100cb6 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ca4:	50                   	push   %eax
f0100ca5:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0100caa:	6a 58                	push   $0x58
f0100cac:	68 55 6b 10 f0       	push   $0xf0106b55
f0100cb1:	e8 8a f3 ff ff       	call   f0100040 <_panic>
f0100cb6:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cbc:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100cbf:	0f 86 b6 00 00 00    	jbe    f0100d7b <check_page_free_list+0x2da>
f0100cc5:	68 58 62 10 f0       	push   $0xf0106258
f0100cca:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100ccf:	68 ea 02 00 00       	push   $0x2ea
f0100cd4:	68 49 6b 10 f0       	push   $0xf0106b49
f0100cd9:	e8 62 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100cde:	68 dc 6b 10 f0       	push   $0xf0106bdc
f0100ce3:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100ce8:	68 ec 02 00 00       	push   $0x2ec
f0100ced:	68 49 6b 10 f0       	push   $0xf0106b49
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100cf7:	83 c6 01             	add    $0x1,%esi
f0100cfa:	eb 03                	jmp    f0100cff <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100cfc:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cff:	8b 12                	mov    (%edx),%edx
f0100d01:	85 d2                	test   %edx,%edx
f0100d03:	0f 85 a6 fe ff ff    	jne    f0100baf <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d09:	85 f6                	test   %esi,%esi
f0100d0b:	7f 19                	jg     f0100d26 <check_page_free_list+0x285>
f0100d0d:	68 f9 6b 10 f0       	push   $0xf0106bf9
f0100d12:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100d17:	68 f4 02 00 00       	push   $0x2f4
f0100d1c:	68 49 6b 10 f0       	push   $0xf0106b49
f0100d21:	e8 1a f3 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d26:	85 db                	test   %ebx,%ebx
f0100d28:	7f 19                	jg     f0100d43 <check_page_free_list+0x2a2>
f0100d2a:	68 0b 6c 10 f0       	push   $0xf0106c0b
f0100d2f:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100d34:	68 f5 02 00 00       	push   $0x2f5
f0100d39:	68 49 6b 10 f0       	push   $0xf0106b49
f0100d3e:	e8 fd f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d43:	83 ec 0c             	sub    $0xc,%esp
f0100d46:	68 a0 62 10 f0       	push   $0xf01062a0
f0100d4b:	e8 6d 28 00 00       	call   f01035bd <cprintf>
}
f0100d50:	eb 49                	jmp    f0100d9b <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d52:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100d57:	85 c0                	test   %eax,%eax
f0100d59:	0f 85 6f fd ff ff    	jne    f0100ace <check_page_free_list+0x2d>
f0100d5f:	e9 53 fd ff ff       	jmp    f0100ab7 <check_page_free_list+0x16>
f0100d64:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100d6b:	0f 84 46 fd ff ff    	je     f0100ab7 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d71:	be 00 04 00 00       	mov    $0x400,%esi
f0100d76:	e9 a1 fd ff ff       	jmp    f0100b1c <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d7b:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d80:	0f 85 76 ff ff ff    	jne    f0100cfc <check_page_free_list+0x25b>
f0100d86:	e9 53 ff ff ff       	jmp    f0100cde <check_page_free_list+0x23d>
f0100d8b:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d90:	0f 85 61 ff ff ff    	jne    f0100cf7 <check_page_free_list+0x256>
f0100d96:	e9 43 ff ff ff       	jmp    f0100cde <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100d9b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d9e:	5b                   	pop    %ebx
f0100d9f:	5e                   	pop    %esi
f0100da0:	5f                   	pop    %edi
f0100da1:	5d                   	pop    %ebp
f0100da2:	c3                   	ret    

f0100da3 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100da3:	55                   	push   %ebp
f0100da4:	89 e5                	mov    %esp,%ebp
f0100da6:	56                   	push   %esi
f0100da7:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
        page_free_list = NULL;
f0100da8:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0100daf:	00 00 00 
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
f0100db2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db7:	e8 20 fc ff ff       	call   f01009dc <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dbc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100dc1:	77 15                	ja     f0100dd8 <page_init+0x35>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100dc3:	50                   	push   %eax
f0100dc4:	68 08 5d 10 f0       	push   $0xf0105d08
f0100dc9:	68 3b 01 00 00       	push   $0x13b
f0100dce:	68 49 6b 10 f0       	push   $0xf0106b49
f0100dd3:	e8 68 f2 ff ff       	call   f0100040 <_panic>
f0100dd8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ddd:	c1 e8 0c             	shr    $0xc,%eax
	for (i = 0; i < npages; i++) 
f0100de0:	be 00 00 00 00       	mov    $0x0,%esi
f0100de5:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100dea:	ba 00 00 00 00       	mov    $0x0,%edx
f0100def:	eb 7c                	jmp    f0100e6d <page_init+0xca>
	{
            if(i==0)
f0100df1:	85 d2                	test   %edx,%edx
f0100df3:	75 14                	jne    f0100e09 <page_init+0x66>
             {
		pages[i].pp_ref = 1;
f0100df5:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
f0100dfb:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100e01:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100e07:	eb 61                	jmp    f0100e6a <page_init+0xc7>
             }
             else if((i >= low_pgm && i < upp_pgm))
f0100e09:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100e0f:	76 1b                	jbe    f0100e2c <page_init+0x89>
f0100e11:	39 c2                	cmp    %eax,%edx
f0100e13:	73 17                	jae    f0100e2c <page_init+0x89>
             {
                pages[i].pp_ref=1;
f0100e15:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
f0100e1b:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100e1e:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100e24:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100e2a:	eb 3e                	jmp    f0100e6a <page_init+0xc7>
             }
	     else if(i==PGNUM(MPENTRY_PADDR))
f0100e2c:	83 fa 07             	cmp    $0x7,%edx
f0100e2f:	75 15                	jne    f0100e46 <page_init+0xa3>
	     {
		 pages[i].pp_ref=1;
f0100e31:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
f0100e37:	66 c7 41 3c 01 00    	movw   $0x1,0x3c(%ecx)
		 pages[i].pp_link=NULL;
f0100e3d:	c7 41 38 00 00 00 00 	movl   $0x0,0x38(%ecx)
f0100e44:	eb 24                	jmp    f0100e6a <page_init+0xc7>
f0100e46:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
	     }
             else
             {
                 pages[i].pp_ref=0;
f0100e4d:	89 ce                	mov    %ecx,%esi
f0100e4f:	03 35 90 ae 22 f0    	add    0xf022ae90,%esi
f0100e55:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
                 pages[i].pp_link = page_free_list;
f0100e5b:	89 1e                	mov    %ebx,(%esi)
                 page_free_list = &pages[i];
f0100e5d:	89 cb                	mov    %ecx,%ebx
f0100e5f:	03 1d 90 ae 22 f0    	add    0xf022ae90,%ebx
f0100e65:	be 01 00 00 00       	mov    $0x1,%esi
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100e6a:	83 c2 01             	add    $0x1,%edx
f0100e6d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100e73:	0f 82 78 ff ff ff    	jb     f0100df1 <page_init+0x4e>
f0100e79:	89 f0                	mov    %esi,%eax
f0100e7b:	84 c0                	test   %al,%al
f0100e7d:	74 06                	je     f0100e85 <page_init+0xe2>
f0100e7f:	89 1d 40 a2 22 f0    	mov    %ebx,0xf022a240
                 pages[i].pp_ref=0;
                 pages[i].pp_link = page_free_list;
                 page_free_list = &pages[i];
             }
          }
}
f0100e85:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e88:	5b                   	pop    %ebx
f0100e89:	5e                   	pop    %esi
f0100e8a:	5d                   	pop    %ebp
f0100e8b:	c3                   	ret    

f0100e8c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e8c:	55                   	push   %ebp
f0100e8d:	89 e5                	mov    %esp,%ebp
f0100e8f:	53                   	push   %ebx
f0100e90:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
        if(page_free_list==NULL)
f0100e93:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100e99:	85 db                	test   %ebx,%ebx
f0100e9b:	74 58                	je     f0100ef5 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100e9d:	8b 03                	mov    (%ebx),%eax
f0100e9f:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
        result->pp_link=NULL;
f0100ea4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if(alloc_flags & ALLOC_ZERO)
f0100eaa:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100eae:	74 45                	je     f0100ef5 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100eb0:	89 d8                	mov    %ebx,%eax
f0100eb2:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100eb8:	c1 f8 03             	sar    $0x3,%eax
f0100ebb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ebe:	89 c2                	mov    %eax,%edx
f0100ec0:	c1 ea 0c             	shr    $0xc,%edx
f0100ec3:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100ec9:	72 12                	jb     f0100edd <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ecb:	50                   	push   %eax
f0100ecc:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0100ed1:	6a 58                	push   $0x58
f0100ed3:	68 55 6b 10 f0       	push   $0xf0106b55
f0100ed8:	e8 63 f1 ff ff       	call   f0100040 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100edd:	83 ec 04             	sub    $0x4,%esp
f0100ee0:	68 00 10 00 00       	push   $0x1000
f0100ee5:	6a 00                	push   $0x0
f0100ee7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100eec:	50                   	push   %eax
f0100eed:	e8 f7 40 00 00       	call   f0104fe9 <memset>
f0100ef2:	83 c4 10             	add    $0x10,%esp
	return result;
}
f0100ef5:	89 d8                	mov    %ebx,%eax
f0100ef7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100efa:	c9                   	leave  
f0100efb:	c3                   	ret    

f0100efc <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100efc:	55                   	push   %ebp
f0100efd:	89 e5                	mov    %esp,%ebp
f0100eff:	83 ec 08             	sub    $0x8,%esp
f0100f02:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0 || pp->pp_link == NULL);  
f0100f05:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f0a:	74 1e                	je     f0100f2a <page_free+0x2e>
f0100f0c:	83 38 00             	cmpl   $0x0,(%eax)
f0100f0f:	74 19                	je     f0100f2a <page_free+0x2e>
f0100f11:	68 c4 62 10 f0       	push   $0xf01062c4
f0100f16:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0100f1b:	68 7d 01 00 00       	push   $0x17d
f0100f20:	68 49 6b 10 f0       	push   $0xf0106b49
f0100f25:	e8 16 f1 ff ff       	call   f0100040 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100f2a:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f30:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100f32:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
}
f0100f37:	c9                   	leave  
f0100f38:	c3                   	ret    

f0100f39 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f39:	55                   	push   %ebp
f0100f3a:	89 e5                	mov    %esp,%ebp
f0100f3c:	83 ec 08             	sub    $0x8,%esp
f0100f3f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f42:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f46:	83 e8 01             	sub    $0x1,%eax
f0100f49:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f4d:	66 85 c0             	test   %ax,%ax
f0100f50:	75 0c                	jne    f0100f5e <page_decref+0x25>
		page_free(pp);
f0100f52:	83 ec 0c             	sub    $0xc,%esp
f0100f55:	52                   	push   %edx
f0100f56:	e8 a1 ff ff ff       	call   f0100efc <page_free>
f0100f5b:	83 c4 10             	add    $0x10,%esp
}
f0100f5e:	c9                   	leave  
f0100f5f:	c3                   	ret    

f0100f60 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f60:	55                   	push   %ebp
f0100f61:	89 e5                	mov    %esp,%ebp
f0100f63:	56                   	push   %esi
f0100f64:	53                   	push   %ebx
f0100f65:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	uint32_t pdx=PDX(va);
	uint32_t ptx=PTX(va);
f0100f68:	89 de                	mov    %ebx,%esi
f0100f6a:	c1 ee 0c             	shr    $0xc,%esi
f0100f6d:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t *po_entry;   
 	pde_t *pt_entry=pgdir+pdx;
f0100f73:	c1 eb 16             	shr    $0x16,%ebx
f0100f76:	c1 e3 02             	shl    $0x2,%ebx
f0100f79:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pt_entry&PTE_P))
f0100f7c:	f6 03 01             	testb  $0x1,(%ebx)
f0100f7f:	75 2d                	jne    f0100fae <pgdir_walk+0x4e>
	{
		if(create==0)
f0100f81:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f85:	74 59                	je     f0100fe0 <pgdir_walk+0x80>
			return NULL;
		struct PageInfo *pp=page_alloc(1);
f0100f87:	83 ec 0c             	sub    $0xc,%esp
f0100f8a:	6a 01                	push   $0x1
f0100f8c:	e8 fb fe ff ff       	call   f0100e8c <page_alloc>
			if(pp==NULL)
f0100f91:	83 c4 10             	add    $0x10,%esp
f0100f94:	85 c0                	test   %eax,%eax
f0100f96:	74 4f                	je     f0100fe7 <pgdir_walk+0x87>
			{
				return NULL;
			}
		pp->pp_ref++;
f0100f98:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
f0100f9d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100fa3:	c1 f8 03             	sar    $0x3,%eax
f0100fa6:	c1 e0 0c             	shl    $0xc,%eax
f0100fa9:	83 c8 07             	or     $0x7,%eax
f0100fac:	89 03                	mov    %eax,(%ebx)
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
f0100fae:	8b 03                	mov    (%ebx),%eax
f0100fb0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb5:	89 c2                	mov    %eax,%edx
f0100fb7:	c1 ea 0c             	shr    $0xc,%edx
f0100fba:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100fc0:	72 15                	jb     f0100fd7 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc2:	50                   	push   %eax
f0100fc3:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0100fc8:	68 b8 01 00 00       	push   $0x1b8
f0100fcd:	68 49 6b 10 f0       	push   $0xf0106b49
f0100fd2:	e8 69 f0 ff ff       	call   f0100040 <_panic>
	return po_entry+ptx;
f0100fd7:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100fde:	eb 0c                	jmp    f0100fec <pgdir_walk+0x8c>
	pte_t *po_entry;   
 	pde_t *pt_entry=pgdir+pdx;
	if(!(*pt_entry&PTE_P))
	{
		if(create==0)
			return NULL;
f0100fe0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe5:	eb 05                	jmp    f0100fec <pgdir_walk+0x8c>
		struct PageInfo *pp=page_alloc(1);
			if(pp==NULL)
			{
				return NULL;
f0100fe7:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
	return po_entry+ptx;
}
f0100fec:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fef:	5b                   	pop    %ebx
f0100ff0:	5e                   	pop    %esi
f0100ff1:	5d                   	pop    %ebp
f0100ff2:	c3                   	ret    

f0100ff3 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ff3:	55                   	push   %ebp
f0100ff4:	89 e5                	mov    %esp,%ebp
f0100ff6:	57                   	push   %edi
f0100ff7:	56                   	push   %esi
f0100ff8:	53                   	push   %ebx
f0100ff9:	83 ec 1c             	sub    $0x1c,%esp
f0100ffc:	89 c7                	mov    %eax,%edi
f0100ffe:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101001:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f0101004:	bb 00 00 00 00       	mov    $0x0,%ebx
	{	
		po_entry=pgdir_walk(pgdir,(char *)va,1);
		*po_entry=pa|perm|PTE_P;
f0101009:	8b 45 0c             	mov    0xc(%ebp),%eax
f010100c:	83 c8 01             	or     $0x1,%eax
f010100f:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f0101012:	eb 1f                	jmp    f0101033 <boot_map_region+0x40>
	{	
		po_entry=pgdir_walk(pgdir,(char *)va,1);
f0101014:	83 ec 04             	sub    $0x4,%esp
f0101017:	6a 01                	push   $0x1
f0101019:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010101c:	01 d8                	add    %ebx,%eax
f010101e:	50                   	push   %eax
f010101f:	57                   	push   %edi
f0101020:	e8 3b ff ff ff       	call   f0100f60 <pgdir_walk>
		*po_entry=pa|perm|PTE_P;
f0101025:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101028:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f010102a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101030:	83 c4 10             	add    $0x10,%esp
f0101033:	89 de                	mov    %ebx,%esi
f0101035:	03 75 08             	add    0x8(%ebp),%esi
f0101038:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010103b:	72 d7                	jb     f0101014 <boot_map_region+0x21>
		*po_entry=pa|perm|PTE_P;
		pa=pa+PGSIZE;
		va=va+PGSIZE;
	}		
	
}
f010103d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101040:	5b                   	pop    %ebx
f0101041:	5e                   	pop    %esi
f0101042:	5f                   	pop    %edi
f0101043:	5d                   	pop    %ebp
f0101044:	c3                   	ret    

f0101045 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101045:	55                   	push   %ebp
f0101046:	89 e5                	mov    %esp,%ebp
f0101048:	53                   	push   %ebx
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f010104f:	6a 00                	push   $0x0
f0101051:	ff 75 0c             	pushl  0xc(%ebp)
f0101054:	ff 75 08             	pushl  0x8(%ebp)
f0101057:	e8 04 ff ff ff       	call   f0100f60 <pgdir_walk>
	if(po_entry==NULL)
f010105c:	83 c4 10             	add    $0x10,%esp
f010105f:	85 c0                	test   %eax,%eax
f0101061:	74 37                	je     f010109a <page_lookup+0x55>
	{
		return NULL;
	}
	if(!(*po_entry&PTE_P))
f0101063:	f6 00 01             	testb  $0x1,(%eax)
f0101066:	74 39                	je     f01010a1 <page_lookup+0x5c>
	{
		return NULL;
	}
	if(pte_store!=0)
f0101068:	85 db                	test   %ebx,%ebx
f010106a:	74 02                	je     f010106e <page_lookup+0x29>
	{
		*pte_store=po_entry;
f010106c:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010106e:	8b 00                	mov    (%eax),%eax
f0101070:	c1 e8 0c             	shr    $0xc,%eax
f0101073:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101079:	72 14                	jb     f010108f <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f010107b:	83 ec 04             	sub    $0x4,%esp
f010107e:	68 ec 62 10 f0       	push   $0xf01062ec
f0101083:	6a 51                	push   $0x51
f0101085:	68 55 6b 10 f0       	push   $0xf0106b55
f010108a:	e8 b1 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010108f:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0101095:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
f0101098:	eb 0c                	jmp    f01010a6 <page_lookup+0x61>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f010109a:	b8 00 00 00 00       	mov    $0x0,%eax
f010109f:	eb 05                	jmp    f01010a6 <page_lookup+0x61>
	}
	if(!(*po_entry&PTE_P))
	{
		return NULL;
f01010a1:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
}	
f01010a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010a9:	c9                   	leave  
f01010aa:	c3                   	ret    

f01010ab <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010ab:	55                   	push   %ebp
f01010ac:	89 e5                	mov    %esp,%ebp
f01010ae:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01010b1:	e8 69 45 00 00       	call   f010561f <cpunum>
f01010b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01010b9:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01010c0:	74 16                	je     f01010d8 <tlb_invalidate+0x2d>
f01010c2:	e8 58 45 00 00       	call   f010561f <cpunum>
f01010c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01010ca:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01010d0:	8b 55 08             	mov    0x8(%ebp),%edx
f01010d3:	39 50 60             	cmp    %edx,0x60(%eax)
f01010d6:	75 06                	jne    f01010de <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010db:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01010de:	c9                   	leave  
f01010df:	c3                   	ret    

f01010e0 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010e0:	55                   	push   %ebp
f01010e1:	89 e5                	mov    %esp,%ebp
f01010e3:	56                   	push   %esi
f01010e4:	53                   	push   %ebx
f01010e5:	83 ec 14             	sub    $0x14,%esp
f01010e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010eb:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f01010ee:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f01010f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010f8:	50                   	push   %eax
f01010f9:	56                   	push   %esi
f01010fa:	53                   	push   %ebx
f01010fb:	e8 45 ff ff ff       	call   f0101045 <page_lookup>
	if(pp==NULL)
f0101100:	83 c4 10             	add    $0x10,%esp
f0101103:	85 c0                	test   %eax,%eax
f0101105:	74 1f                	je     f0101126 <page_remove+0x46>
	{
		return;
	}
	page_decref(pp);
f0101107:	83 ec 0c             	sub    $0xc,%esp
f010110a:	50                   	push   %eax
f010110b:	e8 29 fe ff ff       	call   f0100f39 <page_decref>
	*pte_store=0;
f0101110:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101113:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);	
f0101119:	83 c4 08             	add    $0x8,%esp
f010111c:	56                   	push   %esi
f010111d:	53                   	push   %ebx
f010111e:	e8 88 ff ff ff       	call   f01010ab <tlb_invalidate>
f0101123:	83 c4 10             	add    $0x10,%esp
}
f0101126:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101129:	5b                   	pop    %ebx
f010112a:	5e                   	pop    %esi
f010112b:	5d                   	pop    %ebp
f010112c:	c3                   	ret    

f010112d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010112d:	55                   	push   %ebp
f010112e:	89 e5                	mov    %esp,%ebp
f0101130:	57                   	push   %edi
f0101131:	56                   	push   %esi
f0101132:	53                   	push   %ebx
f0101133:	83 ec 10             	sub    $0x10,%esp
f0101136:	8b 75 08             	mov    0x8(%ebp),%esi
f0101139:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f010113c:	6a 01                	push   $0x1
f010113e:	ff 75 10             	pushl  0x10(%ebp)
f0101141:	56                   	push   %esi
f0101142:	e8 19 fe ff ff       	call   f0100f60 <pgdir_walk>
	if(po_entry==NULL)
f0101147:	83 c4 10             	add    $0x10,%esp
f010114a:	85 c0                	test   %eax,%eax
f010114c:	74 50                	je     f010119e <page_insert+0x71>
f010114e:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0101150:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*po_entry)&PTE_P)
f0101155:	f6 00 01             	testb  $0x1,(%eax)
f0101158:	74 1b                	je     f0101175 <page_insert+0x48>
	{
		tlb_invalidate(pgdir,va);
f010115a:	83 ec 08             	sub    $0x8,%esp
f010115d:	ff 75 10             	pushl  0x10(%ebp)
f0101160:	56                   	push   %esi
f0101161:	e8 45 ff ff ff       	call   f01010ab <tlb_invalidate>
		page_remove(pgdir,va);
f0101166:	83 c4 08             	add    $0x8,%esp
f0101169:	ff 75 10             	pushl  0x10(%ebp)
f010116c:	56                   	push   %esi
f010116d:	e8 6e ff ff ff       	call   f01010e0 <page_remove>
f0101172:	83 c4 10             	add    $0x10,%esp
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
f0101175:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f010117b:	c1 fb 03             	sar    $0x3,%ebx
f010117e:	c1 e3 0c             	shl    $0xc,%ebx
f0101181:	8b 45 14             	mov    0x14(%ebp),%eax
f0101184:	83 c8 01             	or     $0x1,%eax
f0101187:	09 c3                	or     %eax,%ebx
f0101189:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)]|=perm;
f010118b:	8b 45 10             	mov    0x10(%ebp),%eax
f010118e:	c1 e8 16             	shr    $0x16,%eax
f0101191:	8b 55 14             	mov    0x14(%ebp),%edx
f0101194:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0101197:	b8 00 00 00 00       	mov    $0x0,%eax
f010119c:	eb 05                	jmp    f01011a3 <page_insert+0x76>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f010119e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
	pgdir[PDX(va)]|=perm;
	return 0;
}
f01011a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a6:	5b                   	pop    %ebx
f01011a7:	5e                   	pop    %esi
f01011a8:	5f                   	pop    %edi
f01011a9:	5d                   	pop    %ebp
f01011aa:	c3                   	ret    

f01011ab <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011ab:	55                   	push   %ebp
f01011ac:	89 e5                	mov    %esp,%ebp
f01011ae:	53                   	push   %ebx
f01011af:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	uintptr_t ret=base;
f01011b2:	8b 1d 00 f3 11 f0    	mov    0xf011f300,%ebx
	size=ROUNDUP(size,PGSIZE);
f01011b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011bb:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f01011c1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	base=base+size;
f01011c7:	8d 04 0b             	lea    (%ebx,%ecx,1),%eax
f01011ca:	a3 00 f3 11 f0       	mov    %eax,0xf011f300
	if(base>MMIOLIM)
f01011cf:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01011d4:	76 17                	jbe    f01011ed <mmio_map_region+0x42>
		panic("mmio_map_region not implemented");
f01011d6:	83 ec 04             	sub    $0x4,%esp
f01011d9:	68 0c 63 10 f0       	push   $0xf010630c
f01011de:	68 72 02 00 00       	push   $0x272
f01011e3:	68 49 6b 10 f0       	push   $0xf0106b49
f01011e8:	e8 53 ee ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir,ret,size,pa,PTE_PCD|PTE_W|PTE_PWT);
f01011ed:	83 ec 08             	sub    $0x8,%esp
f01011f0:	6a 1a                	push   $0x1a
f01011f2:	ff 75 08             	pushl  0x8(%ebp)
f01011f5:	89 da                	mov    %ebx,%edx
f01011f7:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01011fc:	e8 f2 fd ff ff       	call   f0100ff3 <boot_map_region>
	return (void*)ret;
}
f0101201:	89 d8                	mov    %ebx,%eax
f0101203:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101206:	c9                   	leave  
f0101207:	c3                   	ret    

f0101208 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101208:	55                   	push   %ebp
f0101209:	89 e5                	mov    %esp,%ebp
f010120b:	57                   	push   %edi
f010120c:	56                   	push   %esi
f010120d:	53                   	push   %ebx
f010120e:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101211:	b8 15 00 00 00       	mov    $0x15,%eax
f0101216:	e8 f9 f7 ff ff       	call   f0100a14 <nvram_read>
f010121b:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010121d:	b8 17 00 00 00       	mov    $0x17,%eax
f0101222:	e8 ed f7 ff ff       	call   f0100a14 <nvram_read>
f0101227:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101229:	b8 34 00 00 00       	mov    $0x34,%eax
f010122e:	e8 e1 f7 ff ff       	call   f0100a14 <nvram_read>
f0101233:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101236:	85 c0                	test   %eax,%eax
f0101238:	74 07                	je     f0101241 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010123a:	05 00 40 00 00       	add    $0x4000,%eax
f010123f:	eb 0b                	jmp    f010124c <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101241:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101247:	85 f6                	test   %esi,%esi
f0101249:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010124c:	89 c2                	mov    %eax,%edx
f010124e:	c1 ea 02             	shr    $0x2,%edx
f0101251:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101257:	89 c2                	mov    %eax,%edx
f0101259:	29 da                	sub    %ebx,%edx
f010125b:	52                   	push   %edx
f010125c:	53                   	push   %ebx
f010125d:	50                   	push   %eax
f010125e:	68 2c 63 10 f0       	push   $0xf010632c
f0101263:	e8 55 23 00 00       	call   f01035bd <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101268:	b8 00 10 00 00       	mov    $0x1000,%eax
f010126d:	e8 6a f7 ff ff       	call   f01009dc <boot_alloc>
f0101272:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f0101277:	83 c4 0c             	add    $0xc,%esp
f010127a:	68 00 10 00 00       	push   $0x1000
f010127f:	6a 00                	push   $0x0
f0101281:	50                   	push   %eax
f0101282:	e8 62 3d 00 00       	call   f0104fe9 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101287:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010128c:	83 c4 10             	add    $0x10,%esp
f010128f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101294:	77 15                	ja     f01012ab <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101296:	50                   	push   %eax
f0101297:	68 08 5d 10 f0       	push   $0xf0105d08
f010129c:	68 92 00 00 00       	push   $0x92
f01012a1:	68 49 6b 10 f0       	push   $0xf0106b49
f01012a6:	e8 95 ed ff ff       	call   f0100040 <_panic>
f01012ab:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012b1:	83 ca 05             	or     $0x5,%edx
f01012b4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f01012ba:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01012bf:	c1 e0 03             	shl    $0x3,%eax
f01012c2:	e8 15 f7 ff ff       	call   f01009dc <boot_alloc>
f01012c7:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
        memset(pages,0,npages*sizeof(struct PageInfo));
f01012cc:	83 ec 04             	sub    $0x4,%esp
f01012cf:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01012d5:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012dc:	52                   	push   %edx
f01012dd:	6a 00                	push   $0x0
f01012df:	50                   	push   %eax
f01012e0:	e8 04 3d 00 00       	call   f0104fe9 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=(struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01012e5:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01012ea:	e8 ed f6 ff ff       	call   f01009dc <boot_alloc>
f01012ef:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
	memset(envs,0,NENV*sizeof(struct Env));
f01012f4:	83 c4 0c             	add    $0xc,%esp
f01012f7:	68 00 f0 01 00       	push   $0x1f000
f01012fc:	6a 00                	push   $0x0
f01012fe:	50                   	push   %eax
f01012ff:	e8 e5 3c 00 00       	call   f0104fe9 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101304:	e8 9a fa ff ff       	call   f0100da3 <page_init>
	check_page_free_list(1);
f0101309:	b8 01 00 00 00       	mov    $0x1,%eax
f010130e:	e8 8e f7 ff ff       	call   f0100aa1 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101313:	83 c4 10             	add    $0x10,%esp
f0101316:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f010131d:	75 17                	jne    f0101336 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010131f:	83 ec 04             	sub    $0x4,%esp
f0101322:	68 1c 6c 10 f0       	push   $0xf0106c1c
f0101327:	68 08 03 00 00       	push   $0x308
f010132c:	68 49 6b 10 f0       	push   $0xf0106b49
f0101331:	e8 0a ed ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101336:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010133b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101340:	eb 05                	jmp    f0101347 <mem_init+0x13f>
		++nfree;
f0101342:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101345:	8b 00                	mov    (%eax),%eax
f0101347:	85 c0                	test   %eax,%eax
f0101349:	75 f7                	jne    f0101342 <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010134b:	83 ec 0c             	sub    $0xc,%esp
f010134e:	6a 00                	push   $0x0
f0101350:	e8 37 fb ff ff       	call   f0100e8c <page_alloc>
f0101355:	89 c7                	mov    %eax,%edi
f0101357:	83 c4 10             	add    $0x10,%esp
f010135a:	85 c0                	test   %eax,%eax
f010135c:	75 19                	jne    f0101377 <mem_init+0x16f>
f010135e:	68 37 6c 10 f0       	push   $0xf0106c37
f0101363:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101368:	68 10 03 00 00       	push   $0x310
f010136d:	68 49 6b 10 f0       	push   $0xf0106b49
f0101372:	e8 c9 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101377:	83 ec 0c             	sub    $0xc,%esp
f010137a:	6a 00                	push   $0x0
f010137c:	e8 0b fb ff ff       	call   f0100e8c <page_alloc>
f0101381:	89 c6                	mov    %eax,%esi
f0101383:	83 c4 10             	add    $0x10,%esp
f0101386:	85 c0                	test   %eax,%eax
f0101388:	75 19                	jne    f01013a3 <mem_init+0x19b>
f010138a:	68 4d 6c 10 f0       	push   $0xf0106c4d
f010138f:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101394:	68 11 03 00 00       	push   $0x311
f0101399:	68 49 6b 10 f0       	push   $0xf0106b49
f010139e:	e8 9d ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	6a 00                	push   $0x0
f01013a8:	e8 df fa ff ff       	call   f0100e8c <page_alloc>
f01013ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013b0:	83 c4 10             	add    $0x10,%esp
f01013b3:	85 c0                	test   %eax,%eax
f01013b5:	75 19                	jne    f01013d0 <mem_init+0x1c8>
f01013b7:	68 63 6c 10 f0       	push   $0xf0106c63
f01013bc:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01013c1:	68 12 03 00 00       	push   $0x312
f01013c6:	68 49 6b 10 f0       	push   $0xf0106b49
f01013cb:	e8 70 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013d0:	39 f7                	cmp    %esi,%edi
f01013d2:	75 19                	jne    f01013ed <mem_init+0x1e5>
f01013d4:	68 79 6c 10 f0       	push   $0xf0106c79
f01013d9:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01013de:	68 15 03 00 00       	push   $0x315
f01013e3:	68 49 6b 10 f0       	push   $0xf0106b49
f01013e8:	e8 53 ec ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013f0:	39 c6                	cmp    %eax,%esi
f01013f2:	74 04                	je     f01013f8 <mem_init+0x1f0>
f01013f4:	39 c7                	cmp    %eax,%edi
f01013f6:	75 19                	jne    f0101411 <mem_init+0x209>
f01013f8:	68 68 63 10 f0       	push   $0xf0106368
f01013fd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101402:	68 16 03 00 00       	push   $0x316
f0101407:	68 49 6b 10 f0       	push   $0xf0106b49
f010140c:	e8 2f ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101411:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101417:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f010141d:	c1 e2 0c             	shl    $0xc,%edx
f0101420:	89 f8                	mov    %edi,%eax
f0101422:	29 c8                	sub    %ecx,%eax
f0101424:	c1 f8 03             	sar    $0x3,%eax
f0101427:	c1 e0 0c             	shl    $0xc,%eax
f010142a:	39 d0                	cmp    %edx,%eax
f010142c:	72 19                	jb     f0101447 <mem_init+0x23f>
f010142e:	68 8b 6c 10 f0       	push   $0xf0106c8b
f0101433:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101438:	68 17 03 00 00       	push   $0x317
f010143d:	68 49 6b 10 f0       	push   $0xf0106b49
f0101442:	e8 f9 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101447:	89 f0                	mov    %esi,%eax
f0101449:	29 c8                	sub    %ecx,%eax
f010144b:	c1 f8 03             	sar    $0x3,%eax
f010144e:	c1 e0 0c             	shl    $0xc,%eax
f0101451:	39 c2                	cmp    %eax,%edx
f0101453:	77 19                	ja     f010146e <mem_init+0x266>
f0101455:	68 a8 6c 10 f0       	push   $0xf0106ca8
f010145a:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010145f:	68 18 03 00 00       	push   $0x318
f0101464:	68 49 6b 10 f0       	push   $0xf0106b49
f0101469:	e8 d2 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010146e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101471:	29 c8                	sub    %ecx,%eax
f0101473:	c1 f8 03             	sar    $0x3,%eax
f0101476:	c1 e0 0c             	shl    $0xc,%eax
f0101479:	39 c2                	cmp    %eax,%edx
f010147b:	77 19                	ja     f0101496 <mem_init+0x28e>
f010147d:	68 c5 6c 10 f0       	push   $0xf0106cc5
f0101482:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101487:	68 19 03 00 00       	push   $0x319
f010148c:	68 49 6b 10 f0       	push   $0xf0106b49
f0101491:	e8 aa eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101496:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010149b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010149e:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f01014a5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 da f9 ff ff       	call   f0100e8c <page_alloc>
f01014b2:	83 c4 10             	add    $0x10,%esp
f01014b5:	85 c0                	test   %eax,%eax
f01014b7:	74 19                	je     f01014d2 <mem_init+0x2ca>
f01014b9:	68 e2 6c 10 f0       	push   $0xf0106ce2
f01014be:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01014c3:	68 20 03 00 00       	push   $0x320
f01014c8:	68 49 6b 10 f0       	push   $0xf0106b49
f01014cd:	e8 6e eb ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014d2:	83 ec 0c             	sub    $0xc,%esp
f01014d5:	57                   	push   %edi
f01014d6:	e8 21 fa ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f01014db:	89 34 24             	mov    %esi,(%esp)
f01014de:	e8 19 fa ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f01014e3:	83 c4 04             	add    $0x4,%esp
f01014e6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014e9:	e8 0e fa ff ff       	call   f0100efc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f5:	e8 92 f9 ff ff       	call   f0100e8c <page_alloc>
f01014fa:	89 c6                	mov    %eax,%esi
f01014fc:	83 c4 10             	add    $0x10,%esp
f01014ff:	85 c0                	test   %eax,%eax
f0101501:	75 19                	jne    f010151c <mem_init+0x314>
f0101503:	68 37 6c 10 f0       	push   $0xf0106c37
f0101508:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010150d:	68 27 03 00 00       	push   $0x327
f0101512:	68 49 6b 10 f0       	push   $0xf0106b49
f0101517:	e8 24 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010151c:	83 ec 0c             	sub    $0xc,%esp
f010151f:	6a 00                	push   $0x0
f0101521:	e8 66 f9 ff ff       	call   f0100e8c <page_alloc>
f0101526:	89 c7                	mov    %eax,%edi
f0101528:	83 c4 10             	add    $0x10,%esp
f010152b:	85 c0                	test   %eax,%eax
f010152d:	75 19                	jne    f0101548 <mem_init+0x340>
f010152f:	68 4d 6c 10 f0       	push   $0xf0106c4d
f0101534:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101539:	68 28 03 00 00       	push   $0x328
f010153e:	68 49 6b 10 f0       	push   $0xf0106b49
f0101543:	e8 f8 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101548:	83 ec 0c             	sub    $0xc,%esp
f010154b:	6a 00                	push   $0x0
f010154d:	e8 3a f9 ff ff       	call   f0100e8c <page_alloc>
f0101552:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101555:	83 c4 10             	add    $0x10,%esp
f0101558:	85 c0                	test   %eax,%eax
f010155a:	75 19                	jne    f0101575 <mem_init+0x36d>
f010155c:	68 63 6c 10 f0       	push   $0xf0106c63
f0101561:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101566:	68 29 03 00 00       	push   $0x329
f010156b:	68 49 6b 10 f0       	push   $0xf0106b49
f0101570:	e8 cb ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101575:	39 fe                	cmp    %edi,%esi
f0101577:	75 19                	jne    f0101592 <mem_init+0x38a>
f0101579:	68 79 6c 10 f0       	push   $0xf0106c79
f010157e:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101583:	68 2b 03 00 00       	push   $0x32b
f0101588:	68 49 6b 10 f0       	push   $0xf0106b49
f010158d:	e8 ae ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101592:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101595:	39 c7                	cmp    %eax,%edi
f0101597:	74 04                	je     f010159d <mem_init+0x395>
f0101599:	39 c6                	cmp    %eax,%esi
f010159b:	75 19                	jne    f01015b6 <mem_init+0x3ae>
f010159d:	68 68 63 10 f0       	push   $0xf0106368
f01015a2:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01015a7:	68 2c 03 00 00       	push   $0x32c
f01015ac:	68 49 6b 10 f0       	push   $0xf0106b49
f01015b1:	e8 8a ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 00                	push   $0x0
f01015bb:	e8 cc f8 ff ff       	call   f0100e8c <page_alloc>
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	74 19                	je     f01015e0 <mem_init+0x3d8>
f01015c7:	68 e2 6c 10 f0       	push   $0xf0106ce2
f01015cc:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01015d1:	68 2d 03 00 00       	push   $0x32d
f01015d6:	68 49 6b 10 f0       	push   $0xf0106b49
f01015db:	e8 60 ea ff ff       	call   f0100040 <_panic>
f01015e0:	89 f0                	mov    %esi,%eax
f01015e2:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01015e8:	c1 f8 03             	sar    $0x3,%eax
f01015eb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015ee:	89 c2                	mov    %eax,%edx
f01015f0:	c1 ea 0c             	shr    $0xc,%edx
f01015f3:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01015f9:	72 12                	jb     f010160d <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015fb:	50                   	push   %eax
f01015fc:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0101601:	6a 58                	push   $0x58
f0101603:	68 55 6b 10 f0       	push   $0xf0106b55
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010160d:	83 ec 04             	sub    $0x4,%esp
f0101610:	68 00 10 00 00       	push   $0x1000
f0101615:	6a 01                	push   $0x1
f0101617:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010161c:	50                   	push   %eax
f010161d:	e8 c7 39 00 00       	call   f0104fe9 <memset>
	page_free(pp0);
f0101622:	89 34 24             	mov    %esi,(%esp)
f0101625:	e8 d2 f8 ff ff       	call   f0100efc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010162a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101631:	e8 56 f8 ff ff       	call   f0100e8c <page_alloc>
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	85 c0                	test   %eax,%eax
f010163b:	75 19                	jne    f0101656 <mem_init+0x44e>
f010163d:	68 f1 6c 10 f0       	push   $0xf0106cf1
f0101642:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101647:	68 32 03 00 00       	push   $0x332
f010164c:	68 49 6b 10 f0       	push   $0xf0106b49
f0101651:	e8 ea e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101656:	39 c6                	cmp    %eax,%esi
f0101658:	74 19                	je     f0101673 <mem_init+0x46b>
f010165a:	68 0f 6d 10 f0       	push   $0xf0106d0f
f010165f:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101664:	68 33 03 00 00       	push   $0x333
f0101669:	68 49 6b 10 f0       	push   $0xf0106b49
f010166e:	e8 cd e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101673:	89 f0                	mov    %esi,%eax
f0101675:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010167b:	c1 f8 03             	sar    $0x3,%eax
f010167e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101681:	89 c2                	mov    %eax,%edx
f0101683:	c1 ea 0c             	shr    $0xc,%edx
f0101686:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010168c:	72 12                	jb     f01016a0 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010168e:	50                   	push   %eax
f010168f:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0101694:	6a 58                	push   $0x58
f0101696:	68 55 6b 10 f0       	push   $0xf0106b55
f010169b:	e8 a0 e9 ff ff       	call   f0100040 <_panic>
f01016a0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01016a6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016ac:	80 38 00             	cmpb   $0x0,(%eax)
f01016af:	74 19                	je     f01016ca <mem_init+0x4c2>
f01016b1:	68 1f 6d 10 f0       	push   $0xf0106d1f
f01016b6:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01016bb:	68 36 03 00 00       	push   $0x336
f01016c0:	68 49 6b 10 f0       	push   $0xf0106b49
f01016c5:	e8 76 e9 ff ff       	call   f0100040 <_panic>
f01016ca:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01016cd:	39 d0                	cmp    %edx,%eax
f01016cf:	75 db                	jne    f01016ac <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01016d1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016d4:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f01016d9:	83 ec 0c             	sub    $0xc,%esp
f01016dc:	56                   	push   %esi
f01016dd:	e8 1a f8 ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f01016e2:	89 3c 24             	mov    %edi,(%esp)
f01016e5:	e8 12 f8 ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f01016ea:	83 c4 04             	add    $0x4,%esp
f01016ed:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016f0:	e8 07 f8 ff ff       	call   f0100efc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016f5:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01016fa:	83 c4 10             	add    $0x10,%esp
f01016fd:	eb 05                	jmp    f0101704 <mem_init+0x4fc>
		--nfree;
f01016ff:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101702:	8b 00                	mov    (%eax),%eax
f0101704:	85 c0                	test   %eax,%eax
f0101706:	75 f7                	jne    f01016ff <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101708:	85 db                	test   %ebx,%ebx
f010170a:	74 19                	je     f0101725 <mem_init+0x51d>
f010170c:	68 29 6d 10 f0       	push   $0xf0106d29
f0101711:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101716:	68 43 03 00 00       	push   $0x343
f010171b:	68 49 6b 10 f0       	push   $0xf0106b49
f0101720:	e8 1b e9 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101725:	83 ec 0c             	sub    $0xc,%esp
f0101728:	68 88 63 10 f0       	push   $0xf0106388
f010172d:	e8 8b 1e 00 00       	call   f01035bd <cprintf>
	uintptr_t mm1, mm2;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101732:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101739:	e8 4e f7 ff ff       	call   f0100e8c <page_alloc>
f010173e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101741:	83 c4 10             	add    $0x10,%esp
f0101744:	85 c0                	test   %eax,%eax
f0101746:	75 19                	jne    f0101761 <mem_init+0x559>
f0101748:	68 37 6c 10 f0       	push   $0xf0106c37
f010174d:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101752:	68 a8 03 00 00       	push   $0x3a8
f0101757:	68 49 6b 10 f0       	push   $0xf0106b49
f010175c:	e8 df e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101761:	83 ec 0c             	sub    $0xc,%esp
f0101764:	6a 00                	push   $0x0
f0101766:	e8 21 f7 ff ff       	call   f0100e8c <page_alloc>
f010176b:	89 c3                	mov    %eax,%ebx
f010176d:	83 c4 10             	add    $0x10,%esp
f0101770:	85 c0                	test   %eax,%eax
f0101772:	75 19                	jne    f010178d <mem_init+0x585>
f0101774:	68 4d 6c 10 f0       	push   $0xf0106c4d
f0101779:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010177e:	68 a9 03 00 00       	push   $0x3a9
f0101783:	68 49 6b 10 f0       	push   $0xf0106b49
f0101788:	e8 b3 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010178d:	83 ec 0c             	sub    $0xc,%esp
f0101790:	6a 00                	push   $0x0
f0101792:	e8 f5 f6 ff ff       	call   f0100e8c <page_alloc>
f0101797:	89 c6                	mov    %eax,%esi
f0101799:	83 c4 10             	add    $0x10,%esp
f010179c:	85 c0                	test   %eax,%eax
f010179e:	75 19                	jne    f01017b9 <mem_init+0x5b1>
f01017a0:	68 63 6c 10 f0       	push   $0xf0106c63
f01017a5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01017aa:	68 aa 03 00 00       	push   $0x3aa
f01017af:	68 49 6b 10 f0       	push   $0xf0106b49
f01017b4:	e8 87 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017b9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01017bc:	75 19                	jne    f01017d7 <mem_init+0x5cf>
f01017be:	68 79 6c 10 f0       	push   $0xf0106c79
f01017c3:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01017c8:	68 ad 03 00 00       	push   $0x3ad
f01017cd:	68 49 6b 10 f0       	push   $0xf0106b49
f01017d2:	e8 69 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017d7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017da:	74 04                	je     f01017e0 <mem_init+0x5d8>
f01017dc:	39 c3                	cmp    %eax,%ebx
f01017de:	75 19                	jne    f01017f9 <mem_init+0x5f1>
f01017e0:	68 68 63 10 f0       	push   $0xf0106368
f01017e5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01017ea:	68 ae 03 00 00       	push   $0x3ae
f01017ef:	68 49 6b 10 f0       	push   $0xf0106b49
f01017f4:	e8 47 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017f9:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01017fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101801:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101808:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010180b:	83 ec 0c             	sub    $0xc,%esp
f010180e:	6a 00                	push   $0x0
f0101810:	e8 77 f6 ff ff       	call   f0100e8c <page_alloc>
f0101815:	83 c4 10             	add    $0x10,%esp
f0101818:	85 c0                	test   %eax,%eax
f010181a:	74 19                	je     f0101835 <mem_init+0x62d>
f010181c:	68 e2 6c 10 f0       	push   $0xf0106ce2
f0101821:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101826:	68 b5 03 00 00       	push   $0x3b5
f010182b:	68 49 6b 10 f0       	push   $0xf0106b49
f0101830:	e8 0b e8 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101835:	83 ec 04             	sub    $0x4,%esp
f0101838:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010183b:	50                   	push   %eax
f010183c:	6a 00                	push   $0x0
f010183e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101844:	e8 fc f7 ff ff       	call   f0101045 <page_lookup>
f0101849:	83 c4 10             	add    $0x10,%esp
f010184c:	85 c0                	test   %eax,%eax
f010184e:	74 19                	je     f0101869 <mem_init+0x661>
f0101850:	68 a8 63 10 f0       	push   $0xf01063a8
f0101855:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010185a:	68 b8 03 00 00       	push   $0x3b8
f010185f:	68 49 6b 10 f0       	push   $0xf0106b49
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101869:	6a 02                	push   $0x2
f010186b:	6a 00                	push   $0x0
f010186d:	53                   	push   %ebx
f010186e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101874:	e8 b4 f8 ff ff       	call   f010112d <page_insert>
f0101879:	83 c4 10             	add    $0x10,%esp
f010187c:	85 c0                	test   %eax,%eax
f010187e:	78 19                	js     f0101899 <mem_init+0x691>
f0101880:	68 e0 63 10 f0       	push   $0xf01063e0
f0101885:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010188a:	68 bb 03 00 00       	push   $0x3bb
f010188f:	68 49 6b 10 f0       	push   $0xf0106b49
f0101894:	e8 a7 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101899:	83 ec 0c             	sub    $0xc,%esp
f010189c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010189f:	e8 58 f6 ff ff       	call   f0100efc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01018a4:	6a 02                	push   $0x2
f01018a6:	6a 00                	push   $0x0
f01018a8:	53                   	push   %ebx
f01018a9:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018af:	e8 79 f8 ff ff       	call   f010112d <page_insert>
f01018b4:	83 c4 20             	add    $0x20,%esp
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	74 19                	je     f01018d4 <mem_init+0x6cc>
f01018bb:	68 10 64 10 f0       	push   $0xf0106410
f01018c0:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01018c5:	68 bf 03 00 00       	push   $0x3bf
f01018ca:	68 49 6b 10 f0       	push   $0xf0106b49
f01018cf:	e8 6c e7 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018d4:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018da:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f01018df:	89 c1                	mov    %eax,%ecx
f01018e1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018e4:	8b 17                	mov    (%edi),%edx
f01018e6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018ef:	29 c8                	sub    %ecx,%eax
f01018f1:	c1 f8 03             	sar    $0x3,%eax
f01018f4:	c1 e0 0c             	shl    $0xc,%eax
f01018f7:	39 c2                	cmp    %eax,%edx
f01018f9:	74 19                	je     f0101914 <mem_init+0x70c>
f01018fb:	68 40 64 10 f0       	push   $0xf0106440
f0101900:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101905:	68 c0 03 00 00       	push   $0x3c0
f010190a:	68 49 6b 10 f0       	push   $0xf0106b49
f010190f:	e8 2c e7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101914:	ba 00 00 00 00       	mov    $0x0,%edx
f0101919:	89 f8                	mov    %edi,%eax
f010191b:	e8 1d f1 ff ff       	call   f0100a3d <check_va2pa>
f0101920:	89 da                	mov    %ebx,%edx
f0101922:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101925:	c1 fa 03             	sar    $0x3,%edx
f0101928:	c1 e2 0c             	shl    $0xc,%edx
f010192b:	39 d0                	cmp    %edx,%eax
f010192d:	74 19                	je     f0101948 <mem_init+0x740>
f010192f:	68 68 64 10 f0       	push   $0xf0106468
f0101934:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101939:	68 c1 03 00 00       	push   $0x3c1
f010193e:	68 49 6b 10 f0       	push   $0xf0106b49
f0101943:	e8 f8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101948:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010194d:	74 19                	je     f0101968 <mem_init+0x760>
f010194f:	68 34 6d 10 f0       	push   $0xf0106d34
f0101954:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101959:	68 c2 03 00 00       	push   $0x3c2
f010195e:	68 49 6b 10 f0       	push   $0xf0106b49
f0101963:	e8 d8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101968:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010196b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101970:	74 19                	je     f010198b <mem_init+0x783>
f0101972:	68 45 6d 10 f0       	push   $0xf0106d45
f0101977:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010197c:	68 c3 03 00 00       	push   $0x3c3
f0101981:	68 49 6b 10 f0       	push   $0xf0106b49
f0101986:	e8 b5 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010198b:	6a 02                	push   $0x2
f010198d:	68 00 10 00 00       	push   $0x1000
f0101992:	56                   	push   %esi
f0101993:	57                   	push   %edi
f0101994:	e8 94 f7 ff ff       	call   f010112d <page_insert>
f0101999:	83 c4 10             	add    $0x10,%esp
f010199c:	85 c0                	test   %eax,%eax
f010199e:	74 19                	je     f01019b9 <mem_init+0x7b1>
f01019a0:	68 98 64 10 f0       	push   $0xf0106498
f01019a5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01019aa:	68 c6 03 00 00       	push   $0x3c6
f01019af:	68 49 6b 10 f0       	push   $0xf0106b49
f01019b4:	e8 87 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019be:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01019c3:	e8 75 f0 ff ff       	call   f0100a3d <check_va2pa>
f01019c8:	89 f2                	mov    %esi,%edx
f01019ca:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f01019d0:	c1 fa 03             	sar    $0x3,%edx
f01019d3:	c1 e2 0c             	shl    $0xc,%edx
f01019d6:	39 d0                	cmp    %edx,%eax
f01019d8:	74 19                	je     f01019f3 <mem_init+0x7eb>
f01019da:	68 d4 64 10 f0       	push   $0xf01064d4
f01019df:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01019e4:	68 c7 03 00 00       	push   $0x3c7
f01019e9:	68 49 6b 10 f0       	push   $0xf0106b49
f01019ee:	e8 4d e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01019f3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019f8:	74 19                	je     f0101a13 <mem_init+0x80b>
f01019fa:	68 56 6d 10 f0       	push   $0xf0106d56
f01019ff:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101a04:	68 c8 03 00 00       	push   $0x3c8
f0101a09:	68 49 6b 10 f0       	push   $0xf0106b49
f0101a0e:	e8 2d e6 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a13:	83 ec 0c             	sub    $0xc,%esp
f0101a16:	6a 00                	push   $0x0
f0101a18:	e8 6f f4 ff ff       	call   f0100e8c <page_alloc>
f0101a1d:	83 c4 10             	add    $0x10,%esp
f0101a20:	85 c0                	test   %eax,%eax
f0101a22:	74 19                	je     f0101a3d <mem_init+0x835>
f0101a24:	68 e2 6c 10 f0       	push   $0xf0106ce2
f0101a29:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101a2e:	68 cb 03 00 00       	push   $0x3cb
f0101a33:	68 49 6b 10 f0       	push   $0xf0106b49
f0101a38:	e8 03 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a3d:	6a 02                	push   $0x2
f0101a3f:	68 00 10 00 00       	push   $0x1000
f0101a44:	56                   	push   %esi
f0101a45:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101a4b:	e8 dd f6 ff ff       	call   f010112d <page_insert>
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	85 c0                	test   %eax,%eax
f0101a55:	74 19                	je     f0101a70 <mem_init+0x868>
f0101a57:	68 98 64 10 f0       	push   $0xf0106498
f0101a5c:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101a61:	68 ce 03 00 00       	push   $0x3ce
f0101a66:	68 49 6b 10 f0       	push   $0xf0106b49
f0101a6b:	e8 d0 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a75:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a7a:	e8 be ef ff ff       	call   f0100a3d <check_va2pa>
f0101a7f:	89 f2                	mov    %esi,%edx
f0101a81:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a87:	c1 fa 03             	sar    $0x3,%edx
f0101a8a:	c1 e2 0c             	shl    $0xc,%edx
f0101a8d:	39 d0                	cmp    %edx,%eax
f0101a8f:	74 19                	je     f0101aaa <mem_init+0x8a2>
f0101a91:	68 d4 64 10 f0       	push   $0xf01064d4
f0101a96:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101a9b:	68 cf 03 00 00       	push   $0x3cf
f0101aa0:	68 49 6b 10 f0       	push   $0xf0106b49
f0101aa5:	e8 96 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101aaa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aaf:	74 19                	je     f0101aca <mem_init+0x8c2>
f0101ab1:	68 56 6d 10 f0       	push   $0xf0106d56
f0101ab6:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101abb:	68 d0 03 00 00       	push   $0x3d0
f0101ac0:	68 49 6b 10 f0       	push   $0xf0106b49
f0101ac5:	e8 76 e5 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101aca:	83 ec 0c             	sub    $0xc,%esp
f0101acd:	6a 00                	push   $0x0
f0101acf:	e8 b8 f3 ff ff       	call   f0100e8c <page_alloc>
f0101ad4:	83 c4 10             	add    $0x10,%esp
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	74 19                	je     f0101af4 <mem_init+0x8ec>
f0101adb:	68 e2 6c 10 f0       	push   $0xf0106ce2
f0101ae0:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101ae5:	68 d4 03 00 00       	push   $0x3d4
f0101aea:	68 49 6b 10 f0       	push   $0xf0106b49
f0101aef:	e8 4c e5 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101af4:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101afa:	8b 02                	mov    (%edx),%eax
f0101afc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b01:	89 c1                	mov    %eax,%ecx
f0101b03:	c1 e9 0c             	shr    $0xc,%ecx
f0101b06:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101b0c:	72 15                	jb     f0101b23 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b0e:	50                   	push   %eax
f0101b0f:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0101b14:	68 d7 03 00 00       	push   $0x3d7
f0101b19:	68 49 6b 10 f0       	push   $0xf0106b49
f0101b1e:	e8 1d e5 ff ff       	call   f0100040 <_panic>
f0101b23:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b28:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b2b:	83 ec 04             	sub    $0x4,%esp
f0101b2e:	6a 00                	push   $0x0
f0101b30:	68 00 10 00 00       	push   $0x1000
f0101b35:	52                   	push   %edx
f0101b36:	e8 25 f4 ff ff       	call   f0100f60 <pgdir_walk>
f0101b3b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b3e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b41:	83 c4 10             	add    $0x10,%esp
f0101b44:	39 d0                	cmp    %edx,%eax
f0101b46:	74 19                	je     f0101b61 <mem_init+0x959>
f0101b48:	68 04 65 10 f0       	push   $0xf0106504
f0101b4d:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101b52:	68 d8 03 00 00       	push   $0x3d8
f0101b57:	68 49 6b 10 f0       	push   $0xf0106b49
f0101b5c:	e8 df e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b61:	6a 06                	push   $0x6
f0101b63:	68 00 10 00 00       	push   $0x1000
f0101b68:	56                   	push   %esi
f0101b69:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101b6f:	e8 b9 f5 ff ff       	call   f010112d <page_insert>
f0101b74:	83 c4 10             	add    $0x10,%esp
f0101b77:	85 c0                	test   %eax,%eax
f0101b79:	74 19                	je     f0101b94 <mem_init+0x98c>
f0101b7b:	68 44 65 10 f0       	push   $0xf0106544
f0101b80:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101b85:	68 db 03 00 00       	push   $0x3db
f0101b8a:	68 49 6b 10 f0       	push   $0xf0106b49
f0101b8f:	e8 ac e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b94:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101b9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9f:	89 f8                	mov    %edi,%eax
f0101ba1:	e8 97 ee ff ff       	call   f0100a3d <check_va2pa>
f0101ba6:	89 f2                	mov    %esi,%edx
f0101ba8:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101bae:	c1 fa 03             	sar    $0x3,%edx
f0101bb1:	c1 e2 0c             	shl    $0xc,%edx
f0101bb4:	39 d0                	cmp    %edx,%eax
f0101bb6:	74 19                	je     f0101bd1 <mem_init+0x9c9>
f0101bb8:	68 d4 64 10 f0       	push   $0xf01064d4
f0101bbd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101bc2:	68 dc 03 00 00       	push   $0x3dc
f0101bc7:	68 49 6b 10 f0       	push   $0xf0106b49
f0101bcc:	e8 6f e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bd1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bd6:	74 19                	je     f0101bf1 <mem_init+0x9e9>
f0101bd8:	68 56 6d 10 f0       	push   $0xf0106d56
f0101bdd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101be2:	68 dd 03 00 00       	push   $0x3dd
f0101be7:	68 49 6b 10 f0       	push   $0xf0106b49
f0101bec:	e8 4f e4 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bf1:	83 ec 04             	sub    $0x4,%esp
f0101bf4:	6a 00                	push   $0x0
f0101bf6:	68 00 10 00 00       	push   $0x1000
f0101bfb:	57                   	push   %edi
f0101bfc:	e8 5f f3 ff ff       	call   f0100f60 <pgdir_walk>
f0101c01:	83 c4 10             	add    $0x10,%esp
f0101c04:	f6 00 04             	testb  $0x4,(%eax)
f0101c07:	75 19                	jne    f0101c22 <mem_init+0xa1a>
f0101c09:	68 84 65 10 f0       	push   $0xf0106584
f0101c0e:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101c13:	68 de 03 00 00       	push   $0x3de
f0101c18:	68 49 6b 10 f0       	push   $0xf0106b49
f0101c1d:	e8 1e e4 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c22:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101c27:	f6 00 04             	testb  $0x4,(%eax)
f0101c2a:	75 19                	jne    f0101c45 <mem_init+0xa3d>
f0101c2c:	68 67 6d 10 f0       	push   $0xf0106d67
f0101c31:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101c36:	68 df 03 00 00       	push   $0x3df
f0101c3b:	68 49 6b 10 f0       	push   $0xf0106b49
f0101c40:	e8 fb e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c45:	6a 02                	push   $0x2
f0101c47:	68 00 10 00 00       	push   $0x1000
f0101c4c:	56                   	push   %esi
f0101c4d:	50                   	push   %eax
f0101c4e:	e8 da f4 ff ff       	call   f010112d <page_insert>
f0101c53:	83 c4 10             	add    $0x10,%esp
f0101c56:	85 c0                	test   %eax,%eax
f0101c58:	74 19                	je     f0101c73 <mem_init+0xa6b>
f0101c5a:	68 98 64 10 f0       	push   $0xf0106498
f0101c5f:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101c64:	68 e2 03 00 00       	push   $0x3e2
f0101c69:	68 49 6b 10 f0       	push   $0xf0106b49
f0101c6e:	e8 cd e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c73:	83 ec 04             	sub    $0x4,%esp
f0101c76:	6a 00                	push   $0x0
f0101c78:	68 00 10 00 00       	push   $0x1000
f0101c7d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101c83:	e8 d8 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101c88:	83 c4 10             	add    $0x10,%esp
f0101c8b:	f6 00 02             	testb  $0x2,(%eax)
f0101c8e:	75 19                	jne    f0101ca9 <mem_init+0xaa1>
f0101c90:	68 b8 65 10 f0       	push   $0xf01065b8
f0101c95:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101c9a:	68 e3 03 00 00       	push   $0x3e3
f0101c9f:	68 49 6b 10 f0       	push   $0xf0106b49
f0101ca4:	e8 97 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ca9:	83 ec 04             	sub    $0x4,%esp
f0101cac:	6a 00                	push   $0x0
f0101cae:	68 00 10 00 00       	push   $0x1000
f0101cb3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101cb9:	e8 a2 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101cbe:	83 c4 10             	add    $0x10,%esp
f0101cc1:	f6 00 04             	testb  $0x4,(%eax)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xad7>
f0101cc6:	68 ec 65 10 f0       	push   $0xf01065ec
f0101ccb:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101cd0:	68 e4 03 00 00       	push   $0x3e4
f0101cd5:	68 49 6b 10 f0       	push   $0xf0106b49
f0101cda:	e8 61 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101cdf:	6a 02                	push   $0x2
f0101ce1:	68 00 00 40 00       	push   $0x400000
f0101ce6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ce9:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101cef:	e8 39 f4 ff ff       	call   f010112d <page_insert>
f0101cf4:	83 c4 10             	add    $0x10,%esp
f0101cf7:	85 c0                	test   %eax,%eax
f0101cf9:	78 19                	js     f0101d14 <mem_init+0xb0c>
f0101cfb:	68 24 66 10 f0       	push   $0xf0106624
f0101d00:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101d05:	68 e7 03 00 00       	push   $0x3e7
f0101d0a:	68 49 6b 10 f0       	push   $0xf0106b49
f0101d0f:	e8 2c e3 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d14:	6a 02                	push   $0x2
f0101d16:	68 00 10 00 00       	push   $0x1000
f0101d1b:	53                   	push   %ebx
f0101d1c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d22:	e8 06 f4 ff ff       	call   f010112d <page_insert>
f0101d27:	83 c4 10             	add    $0x10,%esp
f0101d2a:	85 c0                	test   %eax,%eax
f0101d2c:	74 19                	je     f0101d47 <mem_init+0xb3f>
f0101d2e:	68 60 66 10 f0       	push   $0xf0106660
f0101d33:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101d38:	68 ea 03 00 00       	push   $0x3ea
f0101d3d:	68 49 6b 10 f0       	push   $0xf0106b49
f0101d42:	e8 f9 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d47:	83 ec 04             	sub    $0x4,%esp
f0101d4a:	6a 00                	push   $0x0
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d57:	e8 04 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101d5c:	83 c4 10             	add    $0x10,%esp
f0101d5f:	f6 00 04             	testb  $0x4,(%eax)
f0101d62:	74 19                	je     f0101d7d <mem_init+0xb75>
f0101d64:	68 ec 65 10 f0       	push   $0xf01065ec
f0101d69:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101d6e:	68 eb 03 00 00       	push   $0x3eb
f0101d73:	68 49 6b 10 f0       	push   $0xf0106b49
f0101d78:	e8 c3 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d7d:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101d83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d88:	89 f8                	mov    %edi,%eax
f0101d8a:	e8 ae ec ff ff       	call   f0100a3d <check_va2pa>
f0101d8f:	89 c1                	mov    %eax,%ecx
f0101d91:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d94:	89 d8                	mov    %ebx,%eax
f0101d96:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101d9c:	c1 f8 03             	sar    $0x3,%eax
f0101d9f:	c1 e0 0c             	shl    $0xc,%eax
f0101da2:	39 c1                	cmp    %eax,%ecx
f0101da4:	74 19                	je     f0101dbf <mem_init+0xbb7>
f0101da6:	68 9c 66 10 f0       	push   $0xf010669c
f0101dab:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101db0:	68 ee 03 00 00       	push   $0x3ee
f0101db5:	68 49 6b 10 f0       	push   $0xf0106b49
f0101dba:	e8 81 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc4:	89 f8                	mov    %edi,%eax
f0101dc6:	e8 72 ec ff ff       	call   f0100a3d <check_va2pa>
f0101dcb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101dce:	74 19                	je     f0101de9 <mem_init+0xbe1>
f0101dd0:	68 c8 66 10 f0       	push   $0xf01066c8
f0101dd5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101dda:	68 ef 03 00 00       	push   $0x3ef
f0101ddf:	68 49 6b 10 f0       	push   $0xf0106b49
f0101de4:	e8 57 e2 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101de9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dee:	74 19                	je     f0101e09 <mem_init+0xc01>
f0101df0:	68 7d 6d 10 f0       	push   $0xf0106d7d
f0101df5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101dfa:	68 f1 03 00 00       	push   $0x3f1
f0101dff:	68 49 6b 10 f0       	push   $0xf0106b49
f0101e04:	e8 37 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e09:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e0e:	74 19                	je     f0101e29 <mem_init+0xc21>
f0101e10:	68 8e 6d 10 f0       	push   $0xf0106d8e
f0101e15:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101e1a:	68 f2 03 00 00       	push   $0x3f2
f0101e1f:	68 49 6b 10 f0       	push   $0xf0106b49
f0101e24:	e8 17 e2 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e29:	83 ec 0c             	sub    $0xc,%esp
f0101e2c:	6a 00                	push   $0x0
f0101e2e:	e8 59 f0 ff ff       	call   f0100e8c <page_alloc>
f0101e33:	83 c4 10             	add    $0x10,%esp
f0101e36:	39 c6                	cmp    %eax,%esi
f0101e38:	75 04                	jne    f0101e3e <mem_init+0xc36>
f0101e3a:	85 c0                	test   %eax,%eax
f0101e3c:	75 19                	jne    f0101e57 <mem_init+0xc4f>
f0101e3e:	68 f8 66 10 f0       	push   $0xf01066f8
f0101e43:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101e48:	68 f5 03 00 00       	push   $0x3f5
f0101e4d:	68 49 6b 10 f0       	push   $0xf0106b49
f0101e52:	e8 e9 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e57:	83 ec 08             	sub    $0x8,%esp
f0101e5a:	6a 00                	push   $0x0
f0101e5c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101e62:	e8 79 f2 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e67:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101e6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e72:	89 f8                	mov    %edi,%eax
f0101e74:	e8 c4 eb ff ff       	call   f0100a3d <check_va2pa>
f0101e79:	83 c4 10             	add    $0x10,%esp
f0101e7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xc92>
f0101e81:	68 1c 67 10 f0       	push   $0xf010671c
f0101e86:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101e8b:	68 f9 03 00 00       	push   $0x3f9
f0101e90:	68 49 6b 10 f0       	push   $0xf0106b49
f0101e95:	e8 a6 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e9f:	89 f8                	mov    %edi,%eax
f0101ea1:	e8 97 eb ff ff       	call   f0100a3d <check_va2pa>
f0101ea6:	89 da                	mov    %ebx,%edx
f0101ea8:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101eae:	c1 fa 03             	sar    $0x3,%edx
f0101eb1:	c1 e2 0c             	shl    $0xc,%edx
f0101eb4:	39 d0                	cmp    %edx,%eax
f0101eb6:	74 19                	je     f0101ed1 <mem_init+0xcc9>
f0101eb8:	68 c8 66 10 f0       	push   $0xf01066c8
f0101ebd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101ec2:	68 fa 03 00 00       	push   $0x3fa
f0101ec7:	68 49 6b 10 f0       	push   $0xf0106b49
f0101ecc:	e8 6f e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ed1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ed6:	74 19                	je     f0101ef1 <mem_init+0xce9>
f0101ed8:	68 34 6d 10 f0       	push   $0xf0106d34
f0101edd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101ee2:	68 fb 03 00 00       	push   $0x3fb
f0101ee7:	68 49 6b 10 f0       	push   $0xf0106b49
f0101eec:	e8 4f e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ef1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ef6:	74 19                	je     f0101f11 <mem_init+0xd09>
f0101ef8:	68 8e 6d 10 f0       	push   $0xf0106d8e
f0101efd:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101f02:	68 fc 03 00 00       	push   $0x3fc
f0101f07:	68 49 6b 10 f0       	push   $0xf0106b49
f0101f0c:	e8 2f e1 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f11:	6a 00                	push   $0x0
f0101f13:	68 00 10 00 00       	push   $0x1000
f0101f18:	53                   	push   %ebx
f0101f19:	57                   	push   %edi
f0101f1a:	e8 0e f2 ff ff       	call   f010112d <page_insert>
f0101f1f:	83 c4 10             	add    $0x10,%esp
f0101f22:	85 c0                	test   %eax,%eax
f0101f24:	74 19                	je     f0101f3f <mem_init+0xd37>
f0101f26:	68 40 67 10 f0       	push   $0xf0106740
f0101f2b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101f30:	68 ff 03 00 00       	push   $0x3ff
f0101f35:	68 49 6b 10 f0       	push   $0xf0106b49
f0101f3a:	e8 01 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101f3f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f44:	75 19                	jne    f0101f5f <mem_init+0xd57>
f0101f46:	68 9f 6d 10 f0       	push   $0xf0106d9f
f0101f4b:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101f50:	68 00 04 00 00       	push   $0x400
f0101f55:	68 49 6b 10 f0       	push   $0xf0106b49
f0101f5a:	e8 e1 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101f5f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f62:	74 19                	je     f0101f7d <mem_init+0xd75>
f0101f64:	68 ab 6d 10 f0       	push   $0xf0106dab
f0101f69:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101f6e:	68 01 04 00 00       	push   $0x401
f0101f73:	68 49 6b 10 f0       	push   $0xf0106b49
f0101f78:	e8 c3 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f7d:	83 ec 08             	sub    $0x8,%esp
f0101f80:	68 00 10 00 00       	push   $0x1000
f0101f85:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101f8b:	e8 50 f1 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f90:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101f96:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f9b:	89 f8                	mov    %edi,%eax
f0101f9d:	e8 9b ea ff ff       	call   f0100a3d <check_va2pa>
f0101fa2:	83 c4 10             	add    $0x10,%esp
f0101fa5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa8:	74 19                	je     f0101fc3 <mem_init+0xdbb>
f0101faa:	68 1c 67 10 f0       	push   $0xf010671c
f0101faf:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101fb4:	68 05 04 00 00       	push   $0x405
f0101fb9:	68 49 6b 10 f0       	push   $0xf0106b49
f0101fbe:	e8 7d e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fc3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc8:	89 f8                	mov    %edi,%eax
f0101fca:	e8 6e ea ff ff       	call   f0100a3d <check_va2pa>
f0101fcf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fd2:	74 19                	je     f0101fed <mem_init+0xde5>
f0101fd4:	68 78 67 10 f0       	push   $0xf0106778
f0101fd9:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101fde:	68 06 04 00 00       	push   $0x406
f0101fe3:	68 49 6b 10 f0       	push   $0xf0106b49
f0101fe8:	e8 53 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0101fed:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ff2:	74 19                	je     f010200d <mem_init+0xe05>
f0101ff4:	68 c0 6d 10 f0       	push   $0xf0106dc0
f0101ff9:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0101ffe:	68 07 04 00 00       	push   $0x407
f0102003:	68 49 6b 10 f0       	push   $0xf0106b49
f0102008:	e8 33 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010200d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102012:	74 19                	je     f010202d <mem_init+0xe25>
f0102014:	68 8e 6d 10 f0       	push   $0xf0106d8e
f0102019:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010201e:	68 08 04 00 00       	push   $0x408
f0102023:	68 49 6b 10 f0       	push   $0xf0106b49
f0102028:	e8 13 e0 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010202d:	83 ec 0c             	sub    $0xc,%esp
f0102030:	6a 00                	push   $0x0
f0102032:	e8 55 ee ff ff       	call   f0100e8c <page_alloc>
f0102037:	83 c4 10             	add    $0x10,%esp
f010203a:	85 c0                	test   %eax,%eax
f010203c:	74 04                	je     f0102042 <mem_init+0xe3a>
f010203e:	39 c3                	cmp    %eax,%ebx
f0102040:	74 19                	je     f010205b <mem_init+0xe53>
f0102042:	68 a0 67 10 f0       	push   $0xf01067a0
f0102047:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010204c:	68 0b 04 00 00       	push   $0x40b
f0102051:	68 49 6b 10 f0       	push   $0xf0106b49
f0102056:	e8 e5 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010205b:	83 ec 0c             	sub    $0xc,%esp
f010205e:	6a 00                	push   $0x0
f0102060:	e8 27 ee ff ff       	call   f0100e8c <page_alloc>
f0102065:	83 c4 10             	add    $0x10,%esp
f0102068:	85 c0                	test   %eax,%eax
f010206a:	74 19                	je     f0102085 <mem_init+0xe7d>
f010206c:	68 e2 6c 10 f0       	push   $0xf0106ce2
f0102071:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102076:	68 0e 04 00 00       	push   $0x40e
f010207b:	68 49 6b 10 f0       	push   $0xf0106b49
f0102080:	e8 bb df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102085:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f010208b:	8b 11                	mov    (%ecx),%edx
f010208d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102093:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102096:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010209c:	c1 f8 03             	sar    $0x3,%eax
f010209f:	c1 e0 0c             	shl    $0xc,%eax
f01020a2:	39 c2                	cmp    %eax,%edx
f01020a4:	74 19                	je     f01020bf <mem_init+0xeb7>
f01020a6:	68 40 64 10 f0       	push   $0xf0106440
f01020ab:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01020b0:	68 11 04 00 00       	push   $0x411
f01020b5:	68 49 6b 10 f0       	push   $0xf0106b49
f01020ba:	e8 81 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01020bf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020cd:	74 19                	je     f01020e8 <mem_init+0xee0>
f01020cf:	68 45 6d 10 f0       	push   $0xf0106d45
f01020d4:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01020d9:	68 13 04 00 00       	push   $0x413
f01020de:	68 49 6b 10 f0       	push   $0xf0106b49
f01020e3:	e8 58 df ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01020e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020eb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020f1:	83 ec 0c             	sub    $0xc,%esp
f01020f4:	50                   	push   %eax
f01020f5:	e8 02 ee ff ff       	call   f0100efc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020fa:	83 c4 0c             	add    $0xc,%esp
f01020fd:	6a 01                	push   $0x1
f01020ff:	68 00 10 40 00       	push   $0x401000
f0102104:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010210a:	e8 51 ee ff ff       	call   f0100f60 <pgdir_walk>
f010210f:	89 c7                	mov    %eax,%edi
f0102111:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102114:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102119:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010211c:	8b 40 04             	mov    0x4(%eax),%eax
f010211f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102124:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010212a:	89 c2                	mov    %eax,%edx
f010212c:	c1 ea 0c             	shr    $0xc,%edx
f010212f:	83 c4 10             	add    $0x10,%esp
f0102132:	39 ca                	cmp    %ecx,%edx
f0102134:	72 15                	jb     f010214b <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102136:	50                   	push   %eax
f0102137:	68 e4 5c 10 f0       	push   $0xf0105ce4
f010213c:	68 1a 04 00 00       	push   $0x41a
f0102141:	68 49 6b 10 f0       	push   $0xf0106b49
f0102146:	e8 f5 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010214b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102150:	39 c7                	cmp    %eax,%edi
f0102152:	74 19                	je     f010216d <mem_init+0xf65>
f0102154:	68 d1 6d 10 f0       	push   $0xf0106dd1
f0102159:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010215e:	68 1b 04 00 00       	push   $0x41b
f0102163:	68 49 6b 10 f0       	push   $0xf0106b49
f0102168:	e8 d3 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010216d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102170:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102177:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010217a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102180:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102186:	c1 f8 03             	sar    $0x3,%eax
f0102189:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010218c:	89 c2                	mov    %eax,%edx
f010218e:	c1 ea 0c             	shr    $0xc,%edx
f0102191:	39 d1                	cmp    %edx,%ecx
f0102193:	77 12                	ja     f01021a7 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102195:	50                   	push   %eax
f0102196:	68 e4 5c 10 f0       	push   $0xf0105ce4
f010219b:	6a 58                	push   $0x58
f010219d:	68 55 6b 10 f0       	push   $0xf0106b55
f01021a2:	e8 99 de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021a7:	83 ec 04             	sub    $0x4,%esp
f01021aa:	68 00 10 00 00       	push   $0x1000
f01021af:	68 ff 00 00 00       	push   $0xff
f01021b4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01021b9:	50                   	push   %eax
f01021ba:	e8 2a 2e 00 00       	call   f0104fe9 <memset>
	page_free(pp0);
f01021bf:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021c2:	89 3c 24             	mov    %edi,(%esp)
f01021c5:	e8 32 ed ff ff       	call   f0100efc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021ca:	83 c4 0c             	add    $0xc,%esp
f01021cd:	6a 01                	push   $0x1
f01021cf:	6a 00                	push   $0x0
f01021d1:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01021d7:	e8 84 ed ff ff       	call   f0100f60 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021dc:	89 fa                	mov    %edi,%edx
f01021de:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f01021e4:	c1 fa 03             	sar    $0x3,%edx
f01021e7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021ea:	89 d0                	mov    %edx,%eax
f01021ec:	c1 e8 0c             	shr    $0xc,%eax
f01021ef:	83 c4 10             	add    $0x10,%esp
f01021f2:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01021f8:	72 12                	jb     f010220c <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021fa:	52                   	push   %edx
f01021fb:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0102200:	6a 58                	push   $0x58
f0102202:	68 55 6b 10 f0       	push   $0xf0106b55
f0102207:	e8 34 de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010220c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102212:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102215:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010221b:	f6 00 01             	testb  $0x1,(%eax)
f010221e:	74 19                	je     f0102239 <mem_init+0x1031>
f0102220:	68 e9 6d 10 f0       	push   $0xf0106de9
f0102225:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010222a:	68 25 04 00 00       	push   $0x425
f010222f:	68 49 6b 10 f0       	push   $0xf0106b49
f0102234:	e8 07 de ff ff       	call   f0100040 <_panic>
f0102239:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010223c:	39 d0                	cmp    %edx,%eax
f010223e:	75 db                	jne    f010221b <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102240:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102245:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010224b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010224e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102254:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102257:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f010225d:	83 ec 0c             	sub    $0xc,%esp
f0102260:	50                   	push   %eax
f0102261:	e8 96 ec ff ff       	call   f0100efc <page_free>
	page_free(pp1);
f0102266:	89 1c 24             	mov    %ebx,(%esp)
f0102269:	e8 8e ec ff ff       	call   f0100efc <page_free>
	page_free(pp2);
f010226e:	89 34 24             	mov    %esi,(%esp)
f0102271:	e8 86 ec ff ff       	call   f0100efc <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102276:	83 c4 08             	add    $0x8,%esp
f0102279:	68 01 10 00 00       	push   $0x1001
f010227e:	6a 00                	push   $0x0
f0102280:	e8 26 ef ff ff       	call   f01011ab <mmio_map_region>
f0102285:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102287:	83 c4 08             	add    $0x8,%esp
f010228a:	68 00 10 00 00       	push   $0x1000
f010228f:	6a 00                	push   $0x0
f0102291:	e8 15 ef ff ff       	call   f01011ab <mmio_map_region>
f0102296:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102298:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f010229e:	83 c4 10             	add    $0x10,%esp
f01022a1:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01022a7:	76 07                	jbe    f01022b0 <mem_init+0x10a8>
f01022a9:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01022ae:	76 19                	jbe    f01022c9 <mem_init+0x10c1>
f01022b0:	68 c4 67 10 f0       	push   $0xf01067c4
f01022b5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01022ba:	68 35 04 00 00       	push   $0x435
f01022bf:	68 49 6b 10 f0       	push   $0xf0106b49
f01022c4:	e8 77 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01022c9:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01022cf:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01022d5:	77 08                	ja     f01022df <mem_init+0x10d7>
f01022d7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01022dd:	77 19                	ja     f01022f8 <mem_init+0x10f0>
f01022df:	68 ec 67 10 f0       	push   $0xf01067ec
f01022e4:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01022e9:	68 36 04 00 00       	push   $0x436
f01022ee:	68 49 6b 10 f0       	push   $0xf0106b49
f01022f3:	e8 48 dd ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01022f8:	89 da                	mov    %ebx,%edx
f01022fa:	09 f2                	or     %esi,%edx
f01022fc:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102302:	74 19                	je     f010231d <mem_init+0x1115>
f0102304:	68 14 68 10 f0       	push   $0xf0106814
f0102309:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010230e:	68 38 04 00 00       	push   $0x438
f0102313:	68 49 6b 10 f0       	push   $0xf0106b49
f0102318:	e8 23 dd ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010231d:	39 c6                	cmp    %eax,%esi
f010231f:	73 19                	jae    f010233a <mem_init+0x1132>
f0102321:	68 00 6e 10 f0       	push   $0xf0106e00
f0102326:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010232b:	68 3a 04 00 00       	push   $0x43a
f0102330:	68 49 6b 10 f0       	push   $0xf0106b49
f0102335:	e8 06 dd ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010233a:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0102340:	89 da                	mov    %ebx,%edx
f0102342:	89 f8                	mov    %edi,%eax
f0102344:	e8 f4 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102349:	85 c0                	test   %eax,%eax
f010234b:	74 19                	je     f0102366 <mem_init+0x115e>
f010234d:	68 3c 68 10 f0       	push   $0xf010683c
f0102352:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102357:	68 3c 04 00 00       	push   $0x43c
f010235c:	68 49 6b 10 f0       	push   $0xf0106b49
f0102361:	e8 da dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102366:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010236c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010236f:	89 c2                	mov    %eax,%edx
f0102371:	89 f8                	mov    %edi,%eax
f0102373:	e8 c5 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102378:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010237d:	74 19                	je     f0102398 <mem_init+0x1190>
f010237f:	68 60 68 10 f0       	push   $0xf0106860
f0102384:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102389:	68 3d 04 00 00       	push   $0x43d
f010238e:	68 49 6b 10 f0       	push   $0xf0106b49
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102398:	89 f2                	mov    %esi,%edx
f010239a:	89 f8                	mov    %edi,%eax
f010239c:	e8 9c e6 ff ff       	call   f0100a3d <check_va2pa>
f01023a1:	85 c0                	test   %eax,%eax
f01023a3:	74 19                	je     f01023be <mem_init+0x11b6>
f01023a5:	68 90 68 10 f0       	push   $0xf0106890
f01023aa:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01023af:	68 3e 04 00 00       	push   $0x43e
f01023b4:	68 49 6b 10 f0       	push   $0xf0106b49
f01023b9:	e8 82 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01023be:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01023c4:	89 f8                	mov    %edi,%eax
f01023c6:	e8 72 e6 ff ff       	call   f0100a3d <check_va2pa>
f01023cb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023ce:	74 19                	je     f01023e9 <mem_init+0x11e1>
f01023d0:	68 b4 68 10 f0       	push   $0xf01068b4
f01023d5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01023da:	68 3f 04 00 00       	push   $0x43f
f01023df:	68 49 6b 10 f0       	push   $0xf0106b49
f01023e4:	e8 57 dc ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01023e9:	83 ec 04             	sub    $0x4,%esp
f01023ec:	6a 00                	push   $0x0
f01023ee:	53                   	push   %ebx
f01023ef:	57                   	push   %edi
f01023f0:	e8 6b eb ff ff       	call   f0100f60 <pgdir_walk>
f01023f5:	83 c4 10             	add    $0x10,%esp
f01023f8:	f6 00 1a             	testb  $0x1a,(%eax)
f01023fb:	75 19                	jne    f0102416 <mem_init+0x120e>
f01023fd:	68 e0 68 10 f0       	push   $0xf01068e0
f0102402:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102407:	68 41 04 00 00       	push   $0x441
f010240c:	68 49 6b 10 f0       	push   $0xf0106b49
f0102411:	e8 2a dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102416:	83 ec 04             	sub    $0x4,%esp
f0102419:	6a 00                	push   $0x0
f010241b:	53                   	push   %ebx
f010241c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102422:	e8 39 eb ff ff       	call   f0100f60 <pgdir_walk>
f0102427:	8b 00                	mov    (%eax),%eax
f0102429:	83 c4 10             	add    $0x10,%esp
f010242c:	83 e0 04             	and    $0x4,%eax
f010242f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102432:	74 19                	je     f010244d <mem_init+0x1245>
f0102434:	68 24 69 10 f0       	push   $0xf0106924
f0102439:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010243e:	68 42 04 00 00       	push   $0x442
f0102443:	68 49 6b 10 f0       	push   $0xf0106b49
f0102448:	e8 f3 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010244d:	83 ec 04             	sub    $0x4,%esp
f0102450:	6a 00                	push   $0x0
f0102452:	53                   	push   %ebx
f0102453:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102459:	e8 02 eb ff ff       	call   f0100f60 <pgdir_walk>
f010245e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102464:	83 c4 0c             	add    $0xc,%esp
f0102467:	6a 00                	push   $0x0
f0102469:	ff 75 d4             	pushl  -0x2c(%ebp)
f010246c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102472:	e8 e9 ea ff ff       	call   f0100f60 <pgdir_walk>
f0102477:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010247d:	83 c4 0c             	add    $0xc,%esp
f0102480:	6a 00                	push   $0x0
f0102482:	56                   	push   %esi
f0102483:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102489:	e8 d2 ea ff ff       	call   f0100f60 <pgdir_walk>
f010248e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102494:	c7 04 24 12 6e 10 f0 	movl   $0xf0106e12,(%esp)
f010249b:	e8 1d 11 00 00       	call   f01035bd <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f01024a0:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024a5:	83 c4 10             	add    $0x10,%esp
f01024a8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024ad:	77 15                	ja     f01024c4 <mem_init+0x12bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024af:	50                   	push   %eax
f01024b0:	68 08 5d 10 f0       	push   $0xf0105d08
f01024b5:	68 b9 00 00 00       	push   $0xb9
f01024ba:	68 49 6b 10 f0       	push   $0xf0106b49
f01024bf:	e8 7c db ff ff       	call   f0100040 <_panic>
f01024c4:	83 ec 08             	sub    $0x8,%esp
f01024c7:	6a 05                	push   $0x5
f01024c9:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ce:	50                   	push   %eax
f01024cf:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01024d4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024d9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01024de:	e8 10 eb ff ff       	call   f0100ff3 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U|PTE_P);
f01024e3:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024e8:	83 c4 10             	add    $0x10,%esp
f01024eb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024f0:	77 15                	ja     f0102507 <mem_init+0x12ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024f2:	50                   	push   %eax
f01024f3:	68 08 5d 10 f0       	push   $0xf0105d08
f01024f8:	68 c1 00 00 00       	push   $0xc1
f01024fd:	68 49 6b 10 f0       	push   $0xf0106b49
f0102502:	e8 39 db ff ff       	call   f0100040 <_panic>
f0102507:	83 ec 08             	sub    $0x8,%esp
f010250a:	6a 05                	push   $0x5
f010250c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102511:	50                   	push   %eax
f0102512:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102517:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010251c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102521:	e8 cd ea ff ff       	call   f0100ff3 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102526:	83 c4 10             	add    $0x10,%esp
f0102529:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f010252e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102533:	77 15                	ja     f010254a <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102535:	50                   	push   %eax
f0102536:	68 08 5d 10 f0       	push   $0xf0105d08
f010253b:	68 cd 00 00 00       	push   $0xcd
f0102540:	68 49 6b 10 f0       	push   $0xf0106b49
f0102545:	e8 f6 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f010254a:	83 ec 08             	sub    $0x8,%esp
f010254d:	6a 03                	push   $0x3
f010254f:	68 00 50 11 00       	push   $0x115000
f0102554:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102559:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010255e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102563:	e8 8b ea ff ff       	call   f0100ff3 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,ROUNDUP(0xffffffff-KERNBASE,PGSIZE),0x0,PTE_W|PTE_P);
f0102568:	83 c4 08             	add    $0x8,%esp
f010256b:	6a 03                	push   $0x3
f010256d:	6a 00                	push   $0x0
f010256f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102574:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102579:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010257e:	e8 70 ea ff ff       	call   f0100ff3 <boot_map_region>
f0102583:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f010258a:	83 c4 10             	add    $0x10,%esp
f010258d:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f0102592:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102597:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010259d:	77 15                	ja     f01025b4 <mem_init+0x13ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010259f:	53                   	push   %ebx
f01025a0:	68 08 5d 10 f0       	push   $0xf0105d08
f01025a5:	68 0f 01 00 00       	push   $0x10f
f01025aa:	68 49 6b 10 f0       	push   $0xf0106b49
f01025af:	e8 8c da ff ff       	call   f0100040 <_panic>
	int i;
	//uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	for(i=0;i<NCPU;i++)
	{
		uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir,kstacktop_i-KSTKSIZE,KSTKSIZE,PADDR(percpu_kstacks[i]),PTE_W|PTE_P);
f01025b4:	83 ec 08             	sub    $0x8,%esp
f01025b7:	6a 03                	push   $0x3
f01025b9:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025c5:	89 f2                	mov    %esi,%edx
f01025c7:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025cc:	e8 22 ea ff ff       	call   f0100ff3 <boot_map_region>
f01025d1:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01025d7:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	int i;
	//uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	for(i=0;i<NCPU;i++)
f01025dd:	83 c4 10             	add    $0x10,%esp
f01025e0:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f01025e5:	39 d8                	cmp    %ebx,%eax
f01025e7:	75 ae                	jne    f0102597 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025e9:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01025ef:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01025f4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01025f7:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01025fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102603:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102606:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010260c:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010260f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102614:	eb 55                	jmp    f010266b <mem_init+0x1463>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102616:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010261c:	89 f8                	mov    %edi,%eax
f010261e:	e8 1a e4 ff ff       	call   f0100a3d <check_va2pa>
f0102623:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010262a:	77 15                	ja     f0102641 <mem_init+0x1439>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010262c:	56                   	push   %esi
f010262d:	68 08 5d 10 f0       	push   $0xf0105d08
f0102632:	68 5b 03 00 00       	push   $0x35b
f0102637:	68 49 6b 10 f0       	push   $0xf0106b49
f010263c:	e8 ff d9 ff ff       	call   f0100040 <_panic>
f0102641:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102648:	39 c2                	cmp    %eax,%edx
f010264a:	74 19                	je     f0102665 <mem_init+0x145d>
f010264c:	68 58 69 10 f0       	push   $0xf0106958
f0102651:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102656:	68 5b 03 00 00       	push   $0x35b
f010265b:	68 49 6b 10 f0       	push   $0xf0106b49
f0102660:	e8 db d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102665:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010266b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010266e:	77 a6                	ja     f0102616 <mem_init+0x140e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102670:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102676:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102679:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010267e:	89 da                	mov    %ebx,%edx
f0102680:	89 f8                	mov    %edi,%eax
f0102682:	e8 b6 e3 ff ff       	call   f0100a3d <check_va2pa>
f0102687:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010268e:	77 15                	ja     f01026a5 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102690:	56                   	push   %esi
f0102691:	68 08 5d 10 f0       	push   $0xf0105d08
f0102696:	68 60 03 00 00       	push   $0x360
f010269b:	68 49 6b 10 f0       	push   $0xf0106b49
f01026a0:	e8 9b d9 ff ff       	call   f0100040 <_panic>
f01026a5:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01026ac:	39 d0                	cmp    %edx,%eax
f01026ae:	74 19                	je     f01026c9 <mem_init+0x14c1>
f01026b0:	68 8c 69 10 f0       	push   $0xf010698c
f01026b5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01026ba:	68 60 03 00 00       	push   $0x360
f01026bf:	68 49 6b 10 f0       	push   $0xf0106b49
f01026c4:	e8 77 d9 ff ff       	call   f0100040 <_panic>
f01026c9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026cf:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01026d5:	75 a7                	jne    f010267e <mem_init+0x1476>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026d7:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01026da:	c1 e6 0c             	shl    $0xc,%esi
f01026dd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026e2:	eb 30                	jmp    f0102714 <mem_init+0x150c>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01026e4:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01026ea:	89 f8                	mov    %edi,%eax
f01026ec:	e8 4c e3 ff ff       	call   f0100a3d <check_va2pa>
f01026f1:	39 c3                	cmp    %eax,%ebx
f01026f3:	74 19                	je     f010270e <mem_init+0x1506>
f01026f5:	68 c0 69 10 f0       	push   $0xf01069c0
f01026fa:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01026ff:	68 64 03 00 00       	push   $0x364
f0102704:	68 49 6b 10 f0       	push   $0xf0106b49
f0102709:	e8 32 d9 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010270e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102714:	39 f3                	cmp    %esi,%ebx
f0102716:	72 cc                	jb     f01026e4 <mem_init+0x14dc>
f0102718:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010271d:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102720:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102723:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102726:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010272c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010272f:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102731:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102734:	05 00 80 00 20       	add    $0x20008000,%eax
f0102739:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010273c:	89 da                	mov    %ebx,%edx
f010273e:	89 f8                	mov    %edi,%eax
f0102740:	e8 f8 e2 ff ff       	call   f0100a3d <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102745:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010274b:	77 15                	ja     f0102762 <mem_init+0x155a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010274d:	56                   	push   %esi
f010274e:	68 08 5d 10 f0       	push   $0xf0105d08
f0102753:	68 6c 03 00 00       	push   $0x36c
f0102758:	68 49 6b 10 f0       	push   $0xf0106b49
f010275d:	e8 de d8 ff ff       	call   f0100040 <_panic>
f0102762:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102765:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f010276c:	39 d0                	cmp    %edx,%eax
f010276e:	74 19                	je     f0102789 <mem_init+0x1581>
f0102770:	68 e8 69 10 f0       	push   $0xf01069e8
f0102775:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010277a:	68 6c 03 00 00       	push   $0x36c
f010277f:	68 49 6b 10 f0       	push   $0xf0106b49
f0102784:	e8 b7 d8 ff ff       	call   f0100040 <_panic>
f0102789:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010278f:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102792:	75 a8                	jne    f010273c <mem_init+0x1534>
f0102794:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102797:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f010279d:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027a0:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01027a2:	89 da                	mov    %ebx,%edx
f01027a4:	89 f8                	mov    %edi,%eax
f01027a6:	e8 92 e2 ff ff       	call   f0100a3d <check_va2pa>
f01027ab:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027ae:	74 19                	je     f01027c9 <mem_init+0x15c1>
f01027b0:	68 30 6a 10 f0       	push   $0xf0106a30
f01027b5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f01027ba:	68 6e 03 00 00       	push   $0x36e
f01027bf:	68 49 6b 10 f0       	push   $0xf0106b49
f01027c4:	e8 77 d8 ff ff       	call   f0100040 <_panic>
f01027c9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01027cf:	39 f3                	cmp    %esi,%ebx
f01027d1:	75 cf                	jne    f01027a2 <mem_init+0x159a>
f01027d3:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01027d6:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01027dd:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01027e4:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01027ea:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f01027ef:	39 f0                	cmp    %esi,%eax
f01027f1:	0f 85 2c ff ff ff    	jne    f0102723 <mem_init+0x151b>
f01027f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01027fc:	eb 2a                	jmp    f0102828 <mem_init+0x1620>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027fe:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102804:	83 fa 04             	cmp    $0x4,%edx
f0102807:	77 1f                	ja     f0102828 <mem_init+0x1620>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102809:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010280d:	75 7e                	jne    f010288d <mem_init+0x1685>
f010280f:	68 2b 6e 10 f0       	push   $0xf0106e2b
f0102814:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102819:	68 79 03 00 00       	push   $0x379
f010281e:	68 49 6b 10 f0       	push   $0xf0106b49
f0102823:	e8 18 d8 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102828:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010282d:	76 3f                	jbe    f010286e <mem_init+0x1666>
				assert(pgdir[i] & PTE_P);
f010282f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102832:	f6 c2 01             	test   $0x1,%dl
f0102835:	75 19                	jne    f0102850 <mem_init+0x1648>
f0102837:	68 2b 6e 10 f0       	push   $0xf0106e2b
f010283c:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102841:	68 7d 03 00 00       	push   $0x37d
f0102846:	68 49 6b 10 f0       	push   $0xf0106b49
f010284b:	e8 f0 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102850:	f6 c2 02             	test   $0x2,%dl
f0102853:	75 38                	jne    f010288d <mem_init+0x1685>
f0102855:	68 3c 6e 10 f0       	push   $0xf0106e3c
f010285a:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010285f:	68 7e 03 00 00       	push   $0x37e
f0102864:	68 49 6b 10 f0       	push   $0xf0106b49
f0102869:	e8 d2 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010286e:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102872:	74 19                	je     f010288d <mem_init+0x1685>
f0102874:	68 4d 6e 10 f0       	push   $0xf0106e4d
f0102879:	68 6f 6b 10 f0       	push   $0xf0106b6f
f010287e:	68 80 03 00 00       	push   $0x380
f0102883:	68 49 6b 10 f0       	push   $0xf0106b49
f0102888:	e8 b3 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010288d:	83 c0 01             	add    $0x1,%eax
f0102890:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102895:	0f 86 63 ff ff ff    	jbe    f01027fe <mem_init+0x15f6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010289b:	83 ec 0c             	sub    $0xc,%esp
f010289e:	68 54 6a 10 f0       	push   $0xf0106a54
f01028a3:	e8 15 0d 00 00       	call   f01035bd <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028a8:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028ad:	83 c4 10             	add    $0x10,%esp
f01028b0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028b5:	77 15                	ja     f01028cc <mem_init+0x16c4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028b7:	50                   	push   %eax
f01028b8:	68 08 5d 10 f0       	push   $0xf0105d08
f01028bd:	68 e5 00 00 00       	push   $0xe5
f01028c2:	68 49 6b 10 f0       	push   $0xf0106b49
f01028c7:	e8 74 d7 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01028cc:	05 00 00 00 10       	add    $0x10000000,%eax
f01028d1:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d9:	e8 c3 e1 ff ff       	call   f0100aa1 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01028de:	0f 20 c0             	mov    %cr0,%eax
f01028e1:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01028e4:	0d 23 00 05 80       	or     $0x80050023,%eax
f01028e9:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028ec:	83 ec 0c             	sub    $0xc,%esp
f01028ef:	6a 00                	push   $0x0
f01028f1:	e8 96 e5 ff ff       	call   f0100e8c <page_alloc>
f01028f6:	89 c3                	mov    %eax,%ebx
f01028f8:	83 c4 10             	add    $0x10,%esp
f01028fb:	85 c0                	test   %eax,%eax
f01028fd:	75 19                	jne    f0102918 <mem_init+0x1710>
f01028ff:	68 37 6c 10 f0       	push   $0xf0106c37
f0102904:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102909:	68 57 04 00 00       	push   $0x457
f010290e:	68 49 6b 10 f0       	push   $0xf0106b49
f0102913:	e8 28 d7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102918:	83 ec 0c             	sub    $0xc,%esp
f010291b:	6a 00                	push   $0x0
f010291d:	e8 6a e5 ff ff       	call   f0100e8c <page_alloc>
f0102922:	89 c7                	mov    %eax,%edi
f0102924:	83 c4 10             	add    $0x10,%esp
f0102927:	85 c0                	test   %eax,%eax
f0102929:	75 19                	jne    f0102944 <mem_init+0x173c>
f010292b:	68 4d 6c 10 f0       	push   $0xf0106c4d
f0102930:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102935:	68 58 04 00 00       	push   $0x458
f010293a:	68 49 6b 10 f0       	push   $0xf0106b49
f010293f:	e8 fc d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102944:	83 ec 0c             	sub    $0xc,%esp
f0102947:	6a 00                	push   $0x0
f0102949:	e8 3e e5 ff ff       	call   f0100e8c <page_alloc>
f010294e:	89 c6                	mov    %eax,%esi
f0102950:	83 c4 10             	add    $0x10,%esp
f0102953:	85 c0                	test   %eax,%eax
f0102955:	75 19                	jne    f0102970 <mem_init+0x1768>
f0102957:	68 63 6c 10 f0       	push   $0xf0106c63
f010295c:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102961:	68 59 04 00 00       	push   $0x459
f0102966:	68 49 6b 10 f0       	push   $0xf0106b49
f010296b:	e8 d0 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102970:	83 ec 0c             	sub    $0xc,%esp
f0102973:	53                   	push   %ebx
f0102974:	e8 83 e5 ff ff       	call   f0100efc <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102979:	89 f8                	mov    %edi,%eax
f010297b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102981:	c1 f8 03             	sar    $0x3,%eax
f0102984:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102987:	89 c2                	mov    %eax,%edx
f0102989:	c1 ea 0c             	shr    $0xc,%edx
f010298c:	83 c4 10             	add    $0x10,%esp
f010298f:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102995:	72 12                	jb     f01029a9 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102997:	50                   	push   %eax
f0102998:	68 e4 5c 10 f0       	push   $0xf0105ce4
f010299d:	6a 58                	push   $0x58
f010299f:	68 55 6b 10 f0       	push   $0xf0106b55
f01029a4:	e8 97 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029a9:	83 ec 04             	sub    $0x4,%esp
f01029ac:	68 00 10 00 00       	push   $0x1000
f01029b1:	6a 01                	push   $0x1
f01029b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029b8:	50                   	push   %eax
f01029b9:	e8 2b 26 00 00       	call   f0104fe9 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029be:	89 f0                	mov    %esi,%eax
f01029c0:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01029c6:	c1 f8 03             	sar    $0x3,%eax
f01029c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029cc:	89 c2                	mov    %eax,%edx
f01029ce:	c1 ea 0c             	shr    $0xc,%edx
f01029d1:	83 c4 10             	add    $0x10,%esp
f01029d4:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01029da:	72 12                	jb     f01029ee <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029dc:	50                   	push   %eax
f01029dd:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01029e2:	6a 58                	push   $0x58
f01029e4:	68 55 6b 10 f0       	push   $0xf0106b55
f01029e9:	e8 52 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01029ee:	83 ec 04             	sub    $0x4,%esp
f01029f1:	68 00 10 00 00       	push   $0x1000
f01029f6:	6a 02                	push   $0x2
f01029f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029fd:	50                   	push   %eax
f01029fe:	e8 e6 25 00 00       	call   f0104fe9 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a03:	6a 02                	push   $0x2
f0102a05:	68 00 10 00 00       	push   $0x1000
f0102a0a:	57                   	push   %edi
f0102a0b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102a11:	e8 17 e7 ff ff       	call   f010112d <page_insert>
	assert(pp1->pp_ref == 1);
f0102a16:	83 c4 20             	add    $0x20,%esp
f0102a19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a1e:	74 19                	je     f0102a39 <mem_init+0x1831>
f0102a20:	68 34 6d 10 f0       	push   $0xf0106d34
f0102a25:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102a2a:	68 5e 04 00 00       	push   $0x45e
f0102a2f:	68 49 6b 10 f0       	push   $0xf0106b49
f0102a34:	e8 07 d6 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a39:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a40:	01 01 01 
f0102a43:	74 19                	je     f0102a5e <mem_init+0x1856>
f0102a45:	68 74 6a 10 f0       	push   $0xf0106a74
f0102a4a:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102a4f:	68 5f 04 00 00       	push   $0x45f
f0102a54:	68 49 6b 10 f0       	push   $0xf0106b49
f0102a59:	e8 e2 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a5e:	6a 02                	push   $0x2
f0102a60:	68 00 10 00 00       	push   $0x1000
f0102a65:	56                   	push   %esi
f0102a66:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102a6c:	e8 bc e6 ff ff       	call   f010112d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a71:	83 c4 10             	add    $0x10,%esp
f0102a74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a7b:	02 02 02 
f0102a7e:	74 19                	je     f0102a99 <mem_init+0x1891>
f0102a80:	68 98 6a 10 f0       	push   $0xf0106a98
f0102a85:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102a8a:	68 61 04 00 00       	push   $0x461
f0102a8f:	68 49 6b 10 f0       	push   $0xf0106b49
f0102a94:	e8 a7 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102a99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102a9e:	74 19                	je     f0102ab9 <mem_init+0x18b1>
f0102aa0:	68 56 6d 10 f0       	push   $0xf0106d56
f0102aa5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102aaa:	68 62 04 00 00       	push   $0x462
f0102aaf:	68 49 6b 10 f0       	push   $0xf0106b49
f0102ab4:	e8 87 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ab9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102abe:	74 19                	je     f0102ad9 <mem_init+0x18d1>
f0102ac0:	68 c0 6d 10 f0       	push   $0xf0106dc0
f0102ac5:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102aca:	68 63 04 00 00       	push   $0x463
f0102acf:	68 49 6b 10 f0       	push   $0xf0106b49
f0102ad4:	e8 67 d5 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ad9:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102ae0:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ae3:	89 f0                	mov    %esi,%eax
f0102ae5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102aeb:	c1 f8 03             	sar    $0x3,%eax
f0102aee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af1:	89 c2                	mov    %eax,%edx
f0102af3:	c1 ea 0c             	shr    $0xc,%edx
f0102af6:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102afc:	72 12                	jb     f0102b10 <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afe:	50                   	push   %eax
f0102aff:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0102b04:	6a 58                	push   $0x58
f0102b06:	68 55 6b 10 f0       	push   $0xf0106b55
f0102b0b:	e8 30 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b10:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b17:	03 03 03 
f0102b1a:	74 19                	je     f0102b35 <mem_init+0x192d>
f0102b1c:	68 bc 6a 10 f0       	push   $0xf0106abc
f0102b21:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102b26:	68 65 04 00 00       	push   $0x465
f0102b2b:	68 49 6b 10 f0       	push   $0xf0106b49
f0102b30:	e8 0b d5 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b35:	83 ec 08             	sub    $0x8,%esp
f0102b38:	68 00 10 00 00       	push   $0x1000
f0102b3d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102b43:	e8 98 e5 ff ff       	call   f01010e0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b48:	83 c4 10             	add    $0x10,%esp
f0102b4b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b50:	74 19                	je     f0102b6b <mem_init+0x1963>
f0102b52:	68 8e 6d 10 f0       	push   $0xf0106d8e
f0102b57:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102b5c:	68 67 04 00 00       	push   $0x467
f0102b61:	68 49 6b 10 f0       	push   $0xf0106b49
f0102b66:	e8 d5 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b6b:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102b71:	8b 11                	mov    (%ecx),%edx
f0102b73:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b79:	89 d8                	mov    %ebx,%eax
f0102b7b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b81:	c1 f8 03             	sar    $0x3,%eax
f0102b84:	c1 e0 0c             	shl    $0xc,%eax
f0102b87:	39 c2                	cmp    %eax,%edx
f0102b89:	74 19                	je     f0102ba4 <mem_init+0x199c>
f0102b8b:	68 40 64 10 f0       	push   $0xf0106440
f0102b90:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102b95:	68 6a 04 00 00       	push   $0x46a
f0102b9a:	68 49 6b 10 f0       	push   $0xf0106b49
f0102b9f:	e8 9c d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102ba4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102baa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102baf:	74 19                	je     f0102bca <mem_init+0x19c2>
f0102bb1:	68 45 6d 10 f0       	push   $0xf0106d45
f0102bb6:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0102bbb:	68 6c 04 00 00       	push   $0x46c
f0102bc0:	68 49 6b 10 f0       	push   $0xf0106b49
f0102bc5:	e8 76 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102bca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102bd0:	83 ec 0c             	sub    $0xc,%esp
f0102bd3:	53                   	push   %ebx
f0102bd4:	e8 23 e3 ff ff       	call   f0100efc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bd9:	c7 04 24 e8 6a 10 f0 	movl   $0xf0106ae8,(%esp)
f0102be0:	e8 d8 09 00 00       	call   f01035bd <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102be5:	83 c4 10             	add    $0x10,%esp
f0102be8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102beb:	5b                   	pop    %ebx
f0102bec:	5e                   	pop    %esi
f0102bed:	5f                   	pop    %edi
f0102bee:	5d                   	pop    %ebp
f0102bef:	c3                   	ret    

f0102bf0 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102bf0:	55                   	push   %ebp
f0102bf1:	89 e5                	mov    %esp,%ebp
f0102bf3:	57                   	push   %edi
f0102bf4:	56                   	push   %esi
f0102bf5:	53                   	push   %ebx
f0102bf6:	83 ec 1c             	sub    $0x1c,%esp
f0102bf9:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102bfc:	8b 45 0c             	mov    0xc(%ebp),%eax
	uintptr_t lva=(uintptr_t)va;
f0102bff:	89 c3                	mov    %eax,%ebx
	uintptr_t rva=(uintptr_t)va+len-1;
f0102c01:	8b 55 10             	mov    0x10(%ebp),%edx
f0102c04:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0102c08:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm=perm|PTE_U|PTE_P;
f0102c0b:	8b 75 14             	mov    0x14(%ebp),%esi
f0102c0e:	83 ce 05             	or     $0x5,%esi
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f0102c11:	eb 4b                	jmp    f0102c5e <user_mem_check+0x6e>
	{
		if(idx_va>=ULIM)
f0102c13:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102c19:	76 0d                	jbe    f0102c28 <user_mem_check+0x38>
		{
			user_mem_check_addr=idx_va;
f0102c1b:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return-E_FAULT;
f0102c21:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c26:	eb 40                	jmp    f0102c68 <user_mem_check+0x78>
		}
		pte=pgdir_walk(env->env_pgdir,(void*)idx_va,0);
f0102c28:	83 ec 04             	sub    $0x4,%esp
f0102c2b:	6a 00                	push   $0x0
f0102c2d:	53                   	push   %ebx
f0102c2e:	ff 77 60             	pushl  0x60(%edi)
f0102c31:	e8 2a e3 ff ff       	call   f0100f60 <pgdir_walk>
		if(pte==NULL||(*pte&perm)!=perm)
f0102c36:	83 c4 10             	add    $0x10,%esp
f0102c39:	85 c0                	test   %eax,%eax
f0102c3b:	74 08                	je     f0102c45 <user_mem_check+0x55>
f0102c3d:	89 f1                	mov    %esi,%ecx
f0102c3f:	23 08                	and    (%eax),%ecx
f0102c41:	39 ce                	cmp    %ecx,%esi
f0102c43:	74 0d                	je     f0102c52 <user_mem_check+0x62>
		{
			user_mem_check_addr=idx_va;
f0102c45:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return-E_FAULT;
f0102c4b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c50:	eb 16                	jmp    f0102c68 <user_mem_check+0x78>
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
f0102c52:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t lva=(uintptr_t)va;
	uintptr_t rva=(uintptr_t)va+len-1;
	perm=perm|PTE_U|PTE_P;
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f0102c58:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c5e:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102c61:	76 b0                	jbe    f0102c13 <user_mem_check+0x23>
			user_mem_check_addr=idx_va;
			return-E_FAULT;
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
	}
	return	0;
f0102c63:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c68:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c6b:	5b                   	pop    %ebx
f0102c6c:	5e                   	pop    %esi
f0102c6d:	5f                   	pop    %edi
f0102c6e:	5d                   	pop    %ebp
f0102c6f:	c3                   	ret    

f0102c70 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102c70:	55                   	push   %ebp
f0102c71:	89 e5                	mov    %esp,%ebp
f0102c73:	53                   	push   %ebx
f0102c74:	83 ec 04             	sub    $0x4,%esp
f0102c77:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102c7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7d:	83 c8 04             	or     $0x4,%eax
f0102c80:	50                   	push   %eax
f0102c81:	ff 75 10             	pushl  0x10(%ebp)
f0102c84:	ff 75 0c             	pushl  0xc(%ebp)
f0102c87:	53                   	push   %ebx
f0102c88:	e8 63 ff ff ff       	call   f0102bf0 <user_mem_check>
f0102c8d:	83 c4 10             	add    $0x10,%esp
f0102c90:	85 c0                	test   %eax,%eax
f0102c92:	79 21                	jns    f0102cb5 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102c94:	83 ec 04             	sub    $0x4,%esp
f0102c97:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102c9d:	ff 73 48             	pushl  0x48(%ebx)
f0102ca0:	68 14 6b 10 f0       	push   $0xf0106b14
f0102ca5:	e8 13 09 00 00       	call   f01035bd <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102caa:	89 1c 24             	mov    %ebx,(%esp)
f0102cad:	e8 18 06 00 00       	call   f01032ca <env_destroy>
f0102cb2:	83 c4 10             	add    $0x10,%esp
	}
}
f0102cb5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102cb8:	c9                   	leave  
f0102cb9:	c3                   	ret    

f0102cba <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102cba:	55                   	push   %ebp
f0102cbb:	89 e5                	mov    %esp,%ebp
f0102cbd:	57                   	push   %edi
f0102cbe:	56                   	push   %esi
f0102cbf:	53                   	push   %ebx
f0102cc0:	83 ec 0c             	sub    $0xc,%esp
f0102cc3:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
f0102cc5:	89 d3                	mov    %edx,%ebx
f0102cc7:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
f0102ccd:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102cd4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *pp;
	while(low<high)
f0102cda:	eb 5d                	jmp    f0102d39 <region_alloc+0x7f>
	{
		pp=page_alloc(ALLOC_ZERO );
f0102cdc:	83 ec 0c             	sub    $0xc,%esp
f0102cdf:	6a 01                	push   $0x1
f0102ce1:	e8 a6 e1 ff ff       	call   f0100e8c <page_alloc>
		pp->pp_ref++;
f0102ce6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		if(pp==NULL)
f0102ceb:	83 c4 10             	add    $0x10,%esp
f0102cee:	85 c0                	test   %eax,%eax
f0102cf0:	75 17                	jne    f0102d09 <region_alloc+0x4f>
		{
			panic("page_alloc is wrong in region_alloc\n");
f0102cf2:	83 ec 04             	sub    $0x4,%esp
f0102cf5:	68 5c 6e 10 f0       	push   $0xf0106e5c
f0102cfa:	68 26 01 00 00       	push   $0x126
f0102cff:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0102d04:	e8 37 d3 ff ff       	call   f0100040 <_panic>
		}
		int i=page_insert(e->env_pgdir,pp,(void *)low,PTE_P|PTE_U|PTE_W);
f0102d09:	6a 07                	push   $0x7
f0102d0b:	53                   	push   %ebx
f0102d0c:	50                   	push   %eax
f0102d0d:	ff 77 60             	pushl  0x60(%edi)
f0102d10:	e8 18 e4 ff ff       	call   f010112d <page_insert>
		if(i!=0)
f0102d15:	83 c4 10             	add    $0x10,%esp
f0102d18:	85 c0                	test   %eax,%eax
f0102d1a:	74 17                	je     f0102d33 <region_alloc+0x79>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
f0102d1c:	83 ec 04             	sub    $0x4,%esp
f0102d1f:	68 84 6e 10 f0       	push   $0xf0106e84
f0102d24:	68 2b 01 00 00       	push   $0x12b
f0102d29:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0102d2e:	e8 0d d3 ff ff       	call   f0100040 <_panic>
		}
		low=low+PGSIZE;
f0102d33:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
	struct PageInfo *pp;
	while(low<high)
f0102d39:	39 f3                	cmp    %esi,%ebx
f0102d3b:	72 9f                	jb     f0102cdc <region_alloc+0x22>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
		}
		low=low+PGSIZE;
	}
} 
f0102d3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d40:	5b                   	pop    %ebx
f0102d41:	5e                   	pop    %esi
f0102d42:	5f                   	pop    %edi
f0102d43:	5d                   	pop    %ebp
f0102d44:	c3                   	ret    

f0102d45 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102d45:	55                   	push   %ebp
f0102d46:	89 e5                	mov    %esp,%ebp
f0102d48:	56                   	push   %esi
f0102d49:	53                   	push   %ebx
f0102d4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d4d:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102d50:	85 c0                	test   %eax,%eax
f0102d52:	75 1a                	jne    f0102d6e <envid2env+0x29>
		*env_store = curenv;
f0102d54:	e8 c6 28 00 00       	call   f010561f <cpunum>
f0102d59:	6b c0 74             	imul   $0x74,%eax,%eax
f0102d5c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102d62:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102d65:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102d67:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d6c:	eb 70                	jmp    f0102dde <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102d6e:	89 c3                	mov    %eax,%ebx
f0102d70:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102d76:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102d79:	03 1d 44 a2 22 f0    	add    0xf022a244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102d7f:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102d83:	74 05                	je     f0102d8a <envid2env+0x45>
f0102d85:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102d88:	74 10                	je     f0102d9a <envid2env+0x55>
		*env_store = 0;
f0102d8a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d8d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102d93:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102d98:	eb 44                	jmp    f0102dde <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102d9a:	84 d2                	test   %dl,%dl
f0102d9c:	74 36                	je     f0102dd4 <envid2env+0x8f>
f0102d9e:	e8 7c 28 00 00       	call   f010561f <cpunum>
f0102da3:	6b c0 74             	imul   $0x74,%eax,%eax
f0102da6:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102dac:	74 26                	je     f0102dd4 <envid2env+0x8f>
f0102dae:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102db1:	e8 69 28 00 00       	call   f010561f <cpunum>
f0102db6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102db9:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102dbf:	3b 70 48             	cmp    0x48(%eax),%esi
f0102dc2:	74 10                	je     f0102dd4 <envid2env+0x8f>
		*env_store = 0;
f0102dc4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dc7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102dcd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102dd2:	eb 0a                	jmp    f0102dde <envid2env+0x99>
	}

	*env_store = e;
f0102dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dd7:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102dd9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102dde:	5b                   	pop    %ebx
f0102ddf:	5e                   	pop    %esi
f0102de0:	5d                   	pop    %ebp
f0102de1:	c3                   	ret    

f0102de2 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102de2:	55                   	push   %ebp
f0102de3:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102de5:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102dea:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ded:	b8 23 00 00 00       	mov    $0x23,%eax
f0102df2:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102df4:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102df6:	b8 10 00 00 00       	mov    $0x10,%eax
f0102dfb:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102dfd:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102dff:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102e01:	ea 08 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e08
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102e08:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e0d:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102e10:	5d                   	pop    %ebp
f0102e11:	c3                   	ret    

f0102e12 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102e12:	55                   	push   %ebp
f0102e13:	89 e5                	mov    %esp,%ebp
f0102e15:	56                   	push   %esi
f0102e16:	53                   	push   %ebx
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f0102e17:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
f0102e1d:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102e23:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102e26:	ba 00 00 00 00       	mov    $0x0,%edx
f0102e2b:	89 c1                	mov    %eax,%ecx
f0102e2d:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status=ENV_FREE;
f0102e34:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link=env_free_list;
f0102e3b:	89 50 44             	mov    %edx,0x44(%eax)
f0102e3e:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list=&envs[i];
f0102e41:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
f0102e43:	39 d8                	cmp    %ebx,%eax
f0102e45:	75 e4                	jne    f0102e2b <env_init+0x19>
f0102e47:	89 35 48 a2 22 f0    	mov    %esi,0xf022a248
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}	
	//cprintf("%d\n",sizeof(struct Env));	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102e4d:	e8 90 ff ff ff       	call   f0102de2 <env_init_percpu>
}
f0102e52:	5b                   	pop    %ebx
f0102e53:	5e                   	pop    %esi
f0102e54:	5d                   	pop    %ebp
f0102e55:	c3                   	ret    

f0102e56 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102e56:	55                   	push   %ebp
f0102e57:	89 e5                	mov    %esp,%ebp
f0102e59:	53                   	push   %ebx
f0102e5a:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102e5d:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
f0102e63:	85 db                	test   %ebx,%ebx
f0102e65:	0f 84 62 01 00 00    	je     f0102fcd <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102e6b:	83 ec 0c             	sub    $0xc,%esp
f0102e6e:	6a 01                	push   $0x1
f0102e70:	e8 17 e0 ff ff       	call   f0100e8c <page_alloc>
f0102e75:	83 c4 10             	add    $0x10,%esp
f0102e78:	85 c0                	test   %eax,%eax
f0102e7a:	0f 84 54 01 00 00    	je     f0102fd4 <env_alloc+0x17e>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102e80:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e85:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102e8b:	c1 f8 03             	sar    $0x3,%eax
f0102e8e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e91:	89 c2                	mov    %eax,%edx
f0102e93:	c1 ea 0c             	shr    $0xc,%edx
f0102e96:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102e9c:	72 12                	jb     f0102eb0 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e9e:	50                   	push   %eax
f0102e9f:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0102ea4:	6a 58                	push   $0x58
f0102ea6:	68 55 6b 10 f0       	push   $0xf0106b55
f0102eab:	e8 90 d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102eb0:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f0102eb5:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102eb8:	83 ec 04             	sub    $0x4,%esp
f0102ebb:	68 00 10 00 00       	push   $0x1000
f0102ec0:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ec6:	50                   	push   %eax
f0102ec7:	e8 d2 21 00 00       	call   f010509e <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102ecc:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ecf:	83 c4 10             	add    $0x10,%esp
f0102ed2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ed7:	77 15                	ja     f0102eee <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ed9:	50                   	push   %eax
f0102eda:	68 08 5d 10 f0       	push   $0xf0105d08
f0102edf:	68 c7 00 00 00       	push   $0xc7
f0102ee4:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0102ee9:	e8 52 d1 ff ff       	call   f0100040 <_panic>
f0102eee:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102ef4:	83 ca 05             	or     $0x5,%edx
f0102ef7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102efd:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f00:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f05:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f0a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f0f:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f12:	89 da                	mov    %ebx,%edx
f0102f14:	2b 15 44 a2 22 f0    	sub    0xf022a244,%edx
f0102f1a:	c1 fa 02             	sar    $0x2,%edx
f0102f1d:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102f23:	09 d0                	or     %edx,%eax
f0102f25:	89 43 48             	mov    %eax,0x48(%ebx)
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102f28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f2b:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102f2e:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102f35:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102f3c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102f43:	83 ec 04             	sub    $0x4,%esp
f0102f46:	6a 44                	push   $0x44
f0102f48:	6a 00                	push   $0x0
f0102f4a:	53                   	push   %ebx
f0102f4b:	e8 99 20 00 00       	call   f0104fe9 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102f50:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102f56:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102f5c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102f62:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102f69:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102f6f:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102f76:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102f7a:	8b 43 44             	mov    0x44(%ebx),%eax
f0102f7d:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	*newenv_store = e;
f0102f82:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f85:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f87:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102f8a:	e8 90 26 00 00       	call   f010561f <cpunum>
f0102f8f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102f92:	83 c4 10             	add    $0x10,%esp
f0102f95:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f9a:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0102fa1:	74 11                	je     f0102fb4 <env_alloc+0x15e>
f0102fa3:	e8 77 26 00 00       	call   f010561f <cpunum>
f0102fa8:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fab:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102fb1:	8b 50 48             	mov    0x48(%eax),%edx
f0102fb4:	83 ec 04             	sub    $0x4,%esp
f0102fb7:	53                   	push   %ebx
f0102fb8:	52                   	push   %edx
f0102fb9:	68 c4 6e 10 f0       	push   $0xf0106ec4
f0102fbe:	e8 fa 05 00 00       	call   f01035bd <cprintf>
	return 0;
f0102fc3:	83 c4 10             	add    $0x10,%esp
f0102fc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fcb:	eb 0c                	jmp    f0102fd9 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102fcd:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102fd2:	eb 05                	jmp    f0102fd9 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102fd4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102fd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102fdc:	c9                   	leave  
f0102fdd:	c3                   	ret    

f0102fde <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102fde:	55                   	push   %ebp
f0102fdf:	89 e5                	mov    %esp,%ebp
f0102fe1:	57                   	push   %edi
f0102fe2:	56                   	push   %esi
f0102fe3:	53                   	push   %ebx
f0102fe4:	83 ec 34             	sub    $0x34,%esp
f0102fe7:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f0102fea:	6a 00                	push   $0x0
f0102fec:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102fef:	50                   	push   %eax
f0102ff0:	e8 61 fe ff ff       	call   f0102e56 <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f0102ff5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ff8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f0102ffb:	83 c4 10             	add    $0x10,%esp
f0102ffe:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103004:	74 17                	je     f010301d <env_create+0x3f>
		panic("binary document is error\n");
f0103006:	83 ec 04             	sub    $0x4,%esp
f0103009:	68 d9 6e 10 f0       	push   $0xf0106ed9
f010300e:	68 70 01 00 00       	push   $0x170
f0103013:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0103018:	e8 23 d0 ff ff       	call   f0100040 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
f010301d:	89 fb                	mov    %edi,%ebx
f010301f:	03 5f 1c             	add    0x1c(%edi),%ebx
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
f0103022:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103025:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103028:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010302d:	77 15                	ja     f0103044 <env_create+0x66>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010302f:	50                   	push   %eax
f0103030:	68 08 5d 10 f0       	push   $0xf0105d08
f0103035:	68 73 01 00 00       	push   $0x173
f010303a:	68 b9 6e 10 f0       	push   $0xf0106eb9
f010303f:	e8 fc cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103044:	05 00 00 00 10       	add    $0x10000000,%eax
f0103049:	0f 22 d8             	mov    %eax,%cr3
	for(i=0;i<elf->e_phnum;i++)
f010304c:	be 00 00 00 00       	mov    $0x0,%esi
f0103051:	eb 40                	jmp    f0103093 <env_create+0xb5>
	{
		if(ph->p_type==ELF_PROG_LOAD)
f0103053:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103056:	75 35                	jne    f010308d <env_create+0xaf>
		{
			//cprintf("load\n");
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f0103058:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010305b:	8b 53 08             	mov    0x8(%ebx),%edx
f010305e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103061:	e8 54 fc ff ff       	call   f0102cba <region_alloc>
			memset((void *)(ph->p_va),0,ph->p_memsz);
f0103066:	83 ec 04             	sub    $0x4,%esp
f0103069:	ff 73 14             	pushl  0x14(%ebx)
f010306c:	6a 00                	push   $0x0
f010306e:	ff 73 08             	pushl  0x8(%ebx)
f0103071:	e8 73 1f 00 00       	call   f0104fe9 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f0103076:	83 c4 0c             	add    $0xc,%esp
f0103079:	ff 73 10             	pushl  0x10(%ebx)
f010307c:	89 f8                	mov    %edi,%eax
f010307e:	03 43 04             	add    0x4(%ebx),%eax
f0103081:	50                   	push   %eax
f0103082:	ff 73 08             	pushl  0x8(%ebx)
f0103085:	e8 14 20 00 00       	call   f010509e <memcpy>
f010308a:	83 c4 10             	add    $0x10,%esp
			//cprintf("%08x\n",ph->p_va);
		}
		ph++;
f010308d:	83 c3 20             	add    $0x20,%ebx
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
	for(i=0;i<elf->e_phnum;i++)
f0103090:	83 c6 01             	add    $0x1,%esi
f0103093:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0103097:	39 c6                	cmp    %eax,%esi
f0103099:	72 b8                	jb     f0103053 <env_create+0x75>
		}
		ph++;
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	e->env_tf.tf_eip=elf->e_entry;
f010309b:	8b 47 18             	mov    0x18(%edi),%eax
f010309e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01030a1:	89 47 30             	mov    %eax,0x30(%edi)
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f01030a4:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01030a9:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01030ae:	89 f8                	mov    %edi,%eax
f01030b0:	e8 05 fc ff ff       	call   f0102cba <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01030b5:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030bf:	77 15                	ja     f01030d6 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030c1:	50                   	push   %eax
f01030c2:	68 08 5d 10 f0       	push   $0xf0105d08
f01030c7:	68 85 01 00 00       	push   $0x185
f01030cc:	68 b9 6e 10 f0       	push   $0xf0106eb9
f01030d1:	e8 6a cf ff ff       	call   f0100040 <_panic>
f01030d6:	05 00 00 00 10       	add    $0x10000000,%eax
f01030db:	0f 22 d8             	mov    %eax,%cr3
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f01030de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030e1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030e4:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f01030e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030ea:	5b                   	pop    %ebx
f01030eb:	5e                   	pop    %esi
f01030ec:	5f                   	pop    %edi
f01030ed:	5d                   	pop    %ebp
f01030ee:	c3                   	ret    

f01030ef <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01030ef:	55                   	push   %ebp
f01030f0:	89 e5                	mov    %esp,%ebp
f01030f2:	57                   	push   %edi
f01030f3:	56                   	push   %esi
f01030f4:	53                   	push   %ebx
f01030f5:	83 ec 1c             	sub    $0x1c,%esp
f01030f8:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01030fb:	e8 1f 25 00 00       	call   f010561f <cpunum>
f0103100:	6b c0 74             	imul   $0x74,%eax,%eax
f0103103:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f0103109:	75 29                	jne    f0103134 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010310b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103110:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103115:	77 15                	ja     f010312c <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103117:	50                   	push   %eax
f0103118:	68 08 5d 10 f0       	push   $0xf0105d08
f010311d:	68 ac 01 00 00       	push   $0x1ac
f0103122:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0103127:	e8 14 cf ff ff       	call   f0100040 <_panic>
f010312c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103131:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103134:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103137:	e8 e3 24 00 00       	call   f010561f <cpunum>
f010313c:	6b c0 74             	imul   $0x74,%eax,%eax
f010313f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103144:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010314b:	74 11                	je     f010315e <env_free+0x6f>
f010314d:	e8 cd 24 00 00       	call   f010561f <cpunum>
f0103152:	6b c0 74             	imul   $0x74,%eax,%eax
f0103155:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010315b:	8b 50 48             	mov    0x48(%eax),%edx
f010315e:	83 ec 04             	sub    $0x4,%esp
f0103161:	53                   	push   %ebx
f0103162:	52                   	push   %edx
f0103163:	68 f3 6e 10 f0       	push   $0xf0106ef3
f0103168:	e8 50 04 00 00       	call   f01035bd <cprintf>
f010316d:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103170:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103177:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010317a:	89 d0                	mov    %edx,%eax
f010317c:	c1 e0 02             	shl    $0x2,%eax
f010317f:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103182:	8b 47 60             	mov    0x60(%edi),%eax
f0103185:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103188:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010318e:	0f 84 a8 00 00 00    	je     f010323c <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103194:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010319a:	89 f0                	mov    %esi,%eax
f010319c:	c1 e8 0c             	shr    $0xc,%eax
f010319f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01031a2:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f01031a8:	77 15                	ja     f01031bf <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031aa:	56                   	push   %esi
f01031ab:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01031b0:	68 bb 01 00 00       	push   $0x1bb
f01031b5:	68 b9 6e 10 f0       	push   $0xf0106eb9
f01031ba:	e8 81 ce ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031c2:	c1 e0 16             	shl    $0x16,%eax
f01031c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031c8:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01031cd:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01031d4:	01 
f01031d5:	74 17                	je     f01031ee <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031d7:	83 ec 08             	sub    $0x8,%esp
f01031da:	89 d8                	mov    %ebx,%eax
f01031dc:	c1 e0 0c             	shl    $0xc,%eax
f01031df:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01031e2:	50                   	push   %eax
f01031e3:	ff 77 60             	pushl  0x60(%edi)
f01031e6:	e8 f5 de ff ff       	call   f01010e0 <page_remove>
f01031eb:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031ee:	83 c3 01             	add    $0x1,%ebx
f01031f1:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01031f7:	75 d4                	jne    f01031cd <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01031f9:	8b 47 60             	mov    0x60(%edi),%eax
f01031fc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031ff:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103206:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103209:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010320f:	72 14                	jb     f0103225 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103211:	83 ec 04             	sub    $0x4,%esp
f0103214:	68 ec 62 10 f0       	push   $0xf01062ec
f0103219:	6a 51                	push   $0x51
f010321b:	68 55 6b 10 f0       	push   $0xf0106b55
f0103220:	e8 1b ce ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103225:	83 ec 0c             	sub    $0xc,%esp
f0103228:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010322d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103230:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103233:	50                   	push   %eax
f0103234:	e8 00 dd ff ff       	call   f0100f39 <page_decref>
f0103239:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010323c:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103240:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103243:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103248:	0f 85 29 ff ff ff    	jne    f0103177 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010324e:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103251:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103256:	77 15                	ja     f010326d <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103258:	50                   	push   %eax
f0103259:	68 08 5d 10 f0       	push   $0xf0105d08
f010325e:	68 c9 01 00 00       	push   $0x1c9
f0103263:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0103268:	e8 d3 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010326d:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103274:	05 00 00 00 10       	add    $0x10000000,%eax
f0103279:	c1 e8 0c             	shr    $0xc,%eax
f010327c:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103282:	72 14                	jb     f0103298 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103284:	83 ec 04             	sub    $0x4,%esp
f0103287:	68 ec 62 10 f0       	push   $0xf01062ec
f010328c:	6a 51                	push   $0x51
f010328e:	68 55 6b 10 f0       	push   $0xf0106b55
f0103293:	e8 a8 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103298:	83 ec 0c             	sub    $0xc,%esp
f010329b:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01032a1:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01032a4:	50                   	push   %eax
f01032a5:	e8 8f dc ff ff       	call   f0100f39 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01032aa:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01032b1:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f01032b6:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01032b9:	89 3d 48 a2 22 f0    	mov    %edi,0xf022a248
}
f01032bf:	83 c4 10             	add    $0x10,%esp
f01032c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032c5:	5b                   	pop    %ebx
f01032c6:	5e                   	pop    %esi
f01032c7:	5f                   	pop    %edi
f01032c8:	5d                   	pop    %ebp
f01032c9:	c3                   	ret    

f01032ca <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01032ca:	55                   	push   %ebp
f01032cb:	89 e5                	mov    %esp,%ebp
f01032cd:	53                   	push   %ebx
f01032ce:	83 ec 04             	sub    $0x4,%esp
f01032d1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01032d4:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01032d8:	75 19                	jne    f01032f3 <env_destroy+0x29>
f01032da:	e8 40 23 00 00       	call   f010561f <cpunum>
f01032df:	6b c0 74             	imul   $0x74,%eax,%eax
f01032e2:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01032e8:	74 09                	je     f01032f3 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01032ea:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01032f1:	eb 43                	jmp    f0103336 <env_destroy+0x6c>
	}

	env_free(e);
f01032f3:	83 ec 0c             	sub    $0xc,%esp
f01032f6:	53                   	push   %ebx
f01032f7:	e8 f3 fd ff ff       	call   f01030ef <env_free>
	
	if (curenv == e) {
f01032fc:	e8 1e 23 00 00       	call   f010561f <cpunum>
f0103301:	6b c0 74             	imul   $0x74,%eax,%eax
f0103304:	83 c4 10             	add    $0x10,%esp
f0103307:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f010330d:	75 27                	jne    f0103336 <env_destroy+0x6c>
		cprintf("free %08x\n",e->env_id);
f010330f:	83 ec 08             	sub    $0x8,%esp
f0103312:	ff 73 48             	pushl  0x48(%ebx)
f0103315:	68 09 6f 10 f0       	push   $0xf0106f09
f010331a:	e8 9e 02 00 00       	call   f01035bd <cprintf>
		curenv = NULL;
f010331f:	e8 fb 22 00 00       	call   f010561f <cpunum>
f0103324:	6b c0 74             	imul   $0x74,%eax,%eax
f0103327:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f010332e:	00 00 00 
		sched_yield();
f0103331:	e8 60 0c 00 00       	call   f0103f96 <sched_yield>
	}
}
f0103336:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103339:	c9                   	leave  
f010333a:	c3                   	ret    

f010333b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010333b:	55                   	push   %ebp
f010333c:	89 e5                	mov    %esp,%ebp
f010333e:	53                   	push   %ebx
f010333f:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103342:	e8 d8 22 00 00       	call   f010561f <cpunum>
f0103347:	6b c0 74             	imul   $0x74,%eax,%eax
f010334a:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103350:	e8 ca 22 00 00       	call   f010561f <cpunum>
f0103355:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103358:	8b 65 08             	mov    0x8(%ebp),%esp
f010335b:	61                   	popa   
f010335c:	07                   	pop    %es
f010335d:	1f                   	pop    %ds
f010335e:	83 c4 08             	add    $0x8,%esp
f0103361:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103362:	83 ec 04             	sub    $0x4,%esp
f0103365:	68 14 6f 10 f0       	push   $0xf0106f14
f010336a:	68 01 02 00 00       	push   $0x201
f010336f:	68 b9 6e 10 f0       	push   $0xf0106eb9
f0103374:	e8 c7 cc ff ff       	call   f0100040 <_panic>

f0103379 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103379:	55                   	push   %ebp
f010337a:	89 e5                	mov    %esp,%ebp
f010337c:	53                   	push   %ebx
f010337d:	83 ec 04             	sub    $0x4,%esp
f0103380:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0103383:	e8 97 22 00 00       	call   f010561f <cpunum>
f0103388:	6b c0 74             	imul   $0x74,%eax,%eax
f010338b:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103392:	74 29                	je     f01033bd <env_run+0x44>
f0103394:	e8 86 22 00 00       	call   f010561f <cpunum>
f0103399:	6b c0 74             	imul   $0x74,%eax,%eax
f010339c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01033a2:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01033a6:	75 15                	jne    f01033bd <env_run+0x44>
	{
		curenv->env_status=ENV_RUNNABLE;
f01033a8:	e8 72 22 00 00       	call   f010561f <cpunum>
f01033ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01033b0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01033b6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv=e;
f01033bd:	e8 5d 22 00 00       	call   f010561f <cpunum>
f01033c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c5:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status=ENV_RUNNING;
f01033cb:	e8 4f 22 00 00       	call   f010561f <cpunum>
f01033d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033d3:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01033d9:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f01033e0:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(curenv->env_pgdir));
f01033e4:	e8 36 22 00 00       	call   f010561f <cpunum>
f01033e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ec:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01033f2:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033fa:	77 15                	ja     f0103411 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033fc:	50                   	push   %eax
f01033fd:	68 08 5d 10 f0       	push   $0xf0105d08
f0103402:	68 26 02 00 00       	push   $0x226
f0103407:	68 b9 6e 10 f0       	push   $0xf0106eb9
f010340c:	e8 2f cc ff ff       	call   f0100040 <_panic>
f0103411:	05 00 00 00 10       	add    $0x10000000,%eax
f0103416:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103419:	83 ec 0c             	sub    $0xc,%esp
f010341c:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103421:	e8 04 25 00 00       	call   f010592a <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103426:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f0103428:	e8 f2 21 00 00       	call   f010561f <cpunum>
f010342d:	83 c4 04             	add    $0x4,%esp
f0103430:	6b c0 74             	imul   $0x74,%eax,%eax
f0103433:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103439:	e8 fd fe ff ff       	call   f010333b <env_pop_tf>

f010343e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010343e:	55                   	push   %ebp
f010343f:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103441:	ba 70 00 00 00       	mov    $0x70,%edx
f0103446:	8b 45 08             	mov    0x8(%ebp),%eax
f0103449:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010344a:	ba 71 00 00 00       	mov    $0x71,%edx
f010344f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103450:	0f b6 c0             	movzbl %al,%eax
}
f0103453:	5d                   	pop    %ebp
f0103454:	c3                   	ret    

f0103455 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103455:	55                   	push   %ebp
f0103456:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103458:	ba 70 00 00 00       	mov    $0x70,%edx
f010345d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103460:	ee                   	out    %al,(%dx)
f0103461:	ba 71 00 00 00       	mov    $0x71,%edx
f0103466:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103469:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010346a:	5d                   	pop    %ebp
f010346b:	c3                   	ret    

f010346c <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010346c:	55                   	push   %ebp
f010346d:	89 e5                	mov    %esp,%ebp
f010346f:	56                   	push   %esi
f0103470:	53                   	push   %ebx
f0103471:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103474:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f010347a:	80 3d 4c a2 22 f0 00 	cmpb   $0x0,0xf022a24c
f0103481:	74 5a                	je     f01034dd <irq_setmask_8259A+0x71>
f0103483:	89 c6                	mov    %eax,%esi
f0103485:	ba 21 00 00 00       	mov    $0x21,%edx
f010348a:	ee                   	out    %al,(%dx)
f010348b:	66 c1 e8 08          	shr    $0x8,%ax
f010348f:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103494:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103495:	83 ec 0c             	sub    $0xc,%esp
f0103498:	68 20 6f 10 f0       	push   $0xf0106f20
f010349d:	e8 1b 01 00 00       	call   f01035bd <cprintf>
f01034a2:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01034a5:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01034aa:	0f b7 f6             	movzwl %si,%esi
f01034ad:	f7 d6                	not    %esi
f01034af:	0f a3 de             	bt     %ebx,%esi
f01034b2:	73 11                	jae    f01034c5 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f01034b4:	83 ec 08             	sub    $0x8,%esp
f01034b7:	53                   	push   %ebx
f01034b8:	68 b3 73 10 f0       	push   $0xf01073b3
f01034bd:	e8 fb 00 00 00       	call   f01035bd <cprintf>
f01034c2:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01034c5:	83 c3 01             	add    $0x1,%ebx
f01034c8:	83 fb 10             	cmp    $0x10,%ebx
f01034cb:	75 e2                	jne    f01034af <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01034cd:	83 ec 0c             	sub    $0xc,%esp
f01034d0:	68 29 6e 10 f0       	push   $0xf0106e29
f01034d5:	e8 e3 00 00 00       	call   f01035bd <cprintf>
f01034da:	83 c4 10             	add    $0x10,%esp
}
f01034dd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034e0:	5b                   	pop    %ebx
f01034e1:	5e                   	pop    %esi
f01034e2:	5d                   	pop    %ebp
f01034e3:	c3                   	ret    

f01034e4 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01034e4:	c6 05 4c a2 22 f0 01 	movb   $0x1,0xf022a24c
f01034eb:	ba 21 00 00 00       	mov    $0x21,%edx
f01034f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034f5:	ee                   	out    %al,(%dx)
f01034f6:	ba a1 00 00 00       	mov    $0xa1,%edx
f01034fb:	ee                   	out    %al,(%dx)
f01034fc:	ba 20 00 00 00       	mov    $0x20,%edx
f0103501:	b8 11 00 00 00       	mov    $0x11,%eax
f0103506:	ee                   	out    %al,(%dx)
f0103507:	ba 21 00 00 00       	mov    $0x21,%edx
f010350c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103511:	ee                   	out    %al,(%dx)
f0103512:	b8 04 00 00 00       	mov    $0x4,%eax
f0103517:	ee                   	out    %al,(%dx)
f0103518:	b8 03 00 00 00       	mov    $0x3,%eax
f010351d:	ee                   	out    %al,(%dx)
f010351e:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103523:	b8 11 00 00 00       	mov    $0x11,%eax
f0103528:	ee                   	out    %al,(%dx)
f0103529:	ba a1 00 00 00       	mov    $0xa1,%edx
f010352e:	b8 28 00 00 00       	mov    $0x28,%eax
f0103533:	ee                   	out    %al,(%dx)
f0103534:	b8 02 00 00 00       	mov    $0x2,%eax
f0103539:	ee                   	out    %al,(%dx)
f010353a:	b8 01 00 00 00       	mov    $0x1,%eax
f010353f:	ee                   	out    %al,(%dx)
f0103540:	ba 20 00 00 00       	mov    $0x20,%edx
f0103545:	b8 68 00 00 00       	mov    $0x68,%eax
f010354a:	ee                   	out    %al,(%dx)
f010354b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103550:	ee                   	out    %al,(%dx)
f0103551:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103556:	b8 68 00 00 00       	mov    $0x68,%eax
f010355b:	ee                   	out    %al,(%dx)
f010355c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103561:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103562:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103569:	66 83 f8 ff          	cmp    $0xffff,%ax
f010356d:	74 13                	je     f0103582 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010356f:	55                   	push   %ebp
f0103570:	89 e5                	mov    %esp,%ebp
f0103572:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103575:	0f b7 c0             	movzwl %ax,%eax
f0103578:	50                   	push   %eax
f0103579:	e8 ee fe ff ff       	call   f010346c <irq_setmask_8259A>
f010357e:	83 c4 10             	add    $0x10,%esp
}
f0103581:	c9                   	leave  
f0103582:	f3 c3                	repz ret 

f0103584 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103584:	55                   	push   %ebp
f0103585:	89 e5                	mov    %esp,%ebp
f0103587:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010358a:	ff 75 08             	pushl  0x8(%ebp)
f010358d:	e8 d2 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0103592:	83 c4 10             	add    $0x10,%esp
f0103595:	c9                   	leave  
f0103596:	c3                   	ret    

f0103597 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103597:	55                   	push   %ebp
f0103598:	89 e5                	mov    %esp,%ebp
f010359a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010359d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01035a4:	ff 75 0c             	pushl  0xc(%ebp)
f01035a7:	ff 75 08             	pushl  0x8(%ebp)
f01035aa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01035ad:	50                   	push   %eax
f01035ae:	68 84 35 10 f0       	push   $0xf0103584
f01035b3:	e8 0c 13 00 00       	call   f01048c4 <vprintfmt>
	return cnt;
}
f01035b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035bb:	c9                   	leave  
f01035bc:	c3                   	ret    

f01035bd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01035bd:	55                   	push   %ebp
f01035be:	89 e5                	mov    %esp,%ebp
f01035c0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01035c3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01035c6:	50                   	push   %eax
f01035c7:	ff 75 08             	pushl  0x8(%ebp)
f01035ca:	e8 c8 ff ff ff       	call   f0103597 <vcprintf>
	va_end(ap);

	return cnt;
}
f01035cf:	c9                   	leave  
f01035d0:	c3                   	ret    

f01035d1 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01035d1:	55                   	push   %ebp
f01035d2:	89 e5                	mov    %esp,%ebp
f01035d4:	57                   	push   %edi
f01035d5:	56                   	push   %esi
f01035d6:	53                   	push   %ebx
f01035d7:	83 ec 0c             	sub    $0xc,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0=KSTACKTOP-cpunum()*(KSTKSIZE+KSTKGAP);
f01035da:	e8 40 20 00 00       	call   f010561f <cpunum>
f01035df:	89 c3                	mov    %eax,%ebx
f01035e1:	e8 39 20 00 00       	call   f010561f <cpunum>
f01035e6:	6b db 74             	imul   $0x74,%ebx,%ebx
f01035e9:	c1 e0 10             	shl    $0x10,%eax
f01035ec:	89 c2                	mov    %eax,%edx
f01035ee:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01035f3:	29 d0                	sub    %edx,%eax
f01035f5:	89 83 30 b0 22 f0    	mov    %eax,-0xfdd4fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0=GD_KD;
f01035fb:	e8 1f 20 00 00       	call   f010561f <cpunum>
f0103600:	6b c0 74             	imul   $0x74,%eax,%eax
f0103603:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f010360a:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f010360c:	e8 0e 20 00 00       	call   f010561f <cpunum>
f0103611:	8d 58 05             	lea    0x5(%eax),%ebx
f0103614:	e8 06 20 00 00       	call   f010561f <cpunum>
f0103619:	89 c7                	mov    %eax,%edi
f010361b:	e8 ff 1f 00 00       	call   f010561f <cpunum>
f0103620:	89 c6                	mov    %eax,%esi
f0103622:	e8 f8 1f 00 00       	call   f010561f <cpunum>
f0103627:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f010362e:	f0 67 00 
f0103631:	6b ff 74             	imul   $0x74,%edi,%edi
f0103634:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f010363a:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103641:	f0 
f0103642:	6b d6 74             	imul   $0x74,%esi,%edx
f0103645:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f010364b:	c1 ea 10             	shr    $0x10,%edx
f010364e:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103655:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f010365c:	99 
f010365d:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103664:	40 
f0103665:	6b c0 74             	imul   $0x74,%eax,%eax
f0103668:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010366d:	c1 e8 18             	shr    $0x18,%eax
f0103670:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;
f0103677:	e8 a3 1f 00 00       	call   f010561f <cpunum>
f010367c:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f0103683:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+sizeof(struct Segdesc)*cpunum());
f0103684:	e8 96 1f 00 00       	call   f010561f <cpunum>
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103689:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103690:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103693:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103698:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f010369b:	83 c4 0c             	add    $0xc,%esp
f010369e:	5b                   	pop    %ebx
f010369f:	5e                   	pop    %esi
f01036a0:	5f                   	pop    %edi
f01036a1:	5d                   	pop    %ebp
f01036a2:	c3                   	ret    

f01036a3 <trap_init>:
}


void
trap_init(void)
{
f01036a3:	55                   	push   %ebp
f01036a4:	89 e5                	mov    %esp,%ebp
f01036a6:	83 ec 08             	sub    $0x8,%esp
	extern void floating_point_error();
	extern void alignment_check();
	extern void machine_check(); 
	extern void simd_floating_error();
	extern void system_call(); 
	SETGATE(idt[0],0,GD_KT,divide_error,0);
f01036a9:	b8 4c 3e 10 f0       	mov    $0xf0103e4c,%eax
f01036ae:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f01036b4:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f01036bb:	08 00 
f01036bd:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01036c4:	c6 05 65 a2 22 f0 8e 	movb   $0x8e,0xf022a265
f01036cb:	c1 e8 10             	shr    $0x10,%eax
f01036ce:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[1],0,GD_KT,debuf_exception,0);
f01036d4:	b8 52 3e 10 f0       	mov    $0xf0103e52,%eax
f01036d9:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01036df:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f01036e6:	08 00 
f01036e8:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f01036ef:	c6 05 6d a2 22 f0 8e 	movb   $0x8e,0xf022a26d
f01036f6:	c1 e8 10             	shr    $0x10,%eax
f01036f9:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[2],0,GD_KT,nmi_interrupt,0);
f01036ff:	b8 58 3e 10 f0       	mov    $0xf0103e58,%eax
f0103704:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f010370a:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f0103711:	08 00 
f0103713:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f010371a:	c6 05 75 a2 22 f0 8e 	movb   $0x8e,0xf022a275
f0103721:	c1 e8 10             	shr    $0x10,%eax
f0103724:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[3],0,GD_KT,break_point,3);
f010372a:	b8 5e 3e 10 f0       	mov    $0xf0103e5e,%eax
f010372f:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103735:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f010373c:	08 00 
f010373e:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103745:	c6 05 7d a2 22 f0 ee 	movb   $0xee,0xf022a27d
f010374c:	c1 e8 10             	shr    $0x10,%eax
f010374f:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[4],0,GD_KT,overflow,0);
f0103755:	b8 64 3e 10 f0       	mov    $0xf0103e64,%eax
f010375a:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103760:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103767:	08 00 
f0103769:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103770:	c6 05 85 a2 22 f0 8e 	movb   $0x8e,0xf022a285
f0103777:	c1 e8 10             	shr    $0x10,%eax
f010377a:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[5],0,GD_KT,bound_check,0);
f0103780:	b8 6a 3e 10 f0       	mov    $0xf0103e6a,%eax
f0103785:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f010378b:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103792:	08 00 
f0103794:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f010379b:	c6 05 8d a2 22 f0 8e 	movb   $0x8e,0xf022a28d
f01037a2:	c1 e8 10             	shr    $0x10,%eax
f01037a5:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[6],0,GD_KT,illegal_opcode,0);
f01037ab:	b8 70 3e 10 f0       	mov    $0xf0103e70,%eax
f01037b0:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f01037b6:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f01037bd:	08 00 
f01037bf:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01037c6:	c6 05 95 a2 22 f0 8e 	movb   $0x8e,0xf022a295
f01037cd:	c1 e8 10             	shr    $0x10,%eax
f01037d0:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[7],0,GD_KT,device_not_available,0);
f01037d6:	b8 76 3e 10 f0       	mov    $0xf0103e76,%eax
f01037db:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01037e1:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01037e8:	08 00 
f01037ea:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01037f1:	c6 05 9d a2 22 f0 8e 	movb   $0x8e,0xf022a29d
f01037f8:	c1 e8 10             	shr    $0x10,%eax
f01037fb:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[8],0,GD_KT,segment_not_present,0);
f0103801:	ba 84 3e 10 f0       	mov    $0xf0103e84,%edx
f0103806:	66 89 15 a0 a2 22 f0 	mov    %dx,0xf022a2a0
f010380d:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f0103814:	08 00 
f0103816:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f010381d:	c6 05 a5 a2 22 f0 8e 	movb   $0x8e,0xf022a2a5
f0103824:	89 d1                	mov    %edx,%ecx
f0103826:	c1 e9 10             	shr    $0x10,%ecx
f0103829:	66 89 0d a6 a2 22 f0 	mov    %cx,0xf022a2a6
	SETGATE(idt[10],0,GD_KT,invalid_tss,0);
f0103830:	b8 80 3e 10 f0       	mov    $0xf0103e80,%eax
f0103835:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f010383b:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f0103842:	08 00 
f0103844:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f010384b:	c6 05 b5 a2 22 f0 8e 	movb   $0x8e,0xf022a2b5
f0103852:	c1 e8 10             	shr    $0x10,%eax
f0103855:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[11],0,GD_KT,segment_not_present,0);
f010385b:	66 89 15 b8 a2 22 f0 	mov    %dx,0xf022a2b8
f0103862:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103869:	08 00 
f010386b:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103872:	c6 05 bd a2 22 f0 8e 	movb   $0x8e,0xf022a2bd
f0103879:	66 89 0d be a2 22 f0 	mov    %cx,0xf022a2be
	SETGATE(idt[12],0,GD_KT,stack_exception,0);
f0103880:	b8 88 3e 10 f0       	mov    $0xf0103e88,%eax
f0103885:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f010388b:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103892:	08 00 
f0103894:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f010389b:	c6 05 c5 a2 22 f0 8e 	movb   $0x8e,0xf022a2c5
f01038a2:	c1 e8 10             	shr    $0x10,%eax
f01038a5:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[13],0,GD_KT, general_protection_fault,0);
f01038ab:	b8 8c 3e 10 f0       	mov    $0xf0103e8c,%eax
f01038b0:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f01038b6:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f01038bd:	08 00 
f01038bf:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01038c6:	c6 05 cd a2 22 f0 8e 	movb   $0x8e,0xf022a2cd
f01038cd:	c1 e8 10             	shr    $0x10,%eax
f01038d0:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[14],0,GD_KT,page_fault,0);
f01038d6:	b8 90 3e 10 f0       	mov    $0xf0103e90,%eax
f01038db:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01038e1:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01038e8:	08 00 
f01038ea:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01038f1:	c6 05 d5 a2 22 f0 8e 	movb   $0x8e,0xf022a2d5
f01038f8:	c1 e8 10             	shr    $0x10,%eax
f01038fb:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6
	SETGATE(idt[16],0,GD_KT,floating_point_error,0);
f0103901:	b8 94 3e 10 f0       	mov    $0xf0103e94,%eax
f0103906:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f010390c:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f0103913:	08 00 
f0103915:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f010391c:	c6 05 e5 a2 22 f0 8e 	movb   $0x8e,0xf022a2e5
f0103923:	c1 e8 10             	shr    $0x10,%eax
f0103926:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6
	SETGATE(idt[17],0,GD_KT,alignment_check,0);
f010392c:	b8 9a 3e 10 f0       	mov    $0xf0103e9a,%eax
f0103931:	66 a3 e8 a2 22 f0    	mov    %ax,0xf022a2e8
f0103937:	66 c7 05 ea a2 22 f0 	movw   $0x8,0xf022a2ea
f010393e:	08 00 
f0103940:	c6 05 ec a2 22 f0 00 	movb   $0x0,0xf022a2ec
f0103947:	c6 05 ed a2 22 f0 8e 	movb   $0x8e,0xf022a2ed
f010394e:	c1 e8 10             	shr    $0x10,%eax
f0103951:	66 a3 ee a2 22 f0    	mov    %ax,0xf022a2ee
	SETGATE(idt[18],0,GD_KT,machine_check,0);
f0103957:	b8 9e 3e 10 f0       	mov    $0xf0103e9e,%eax
f010395c:	66 a3 f0 a2 22 f0    	mov    %ax,0xf022a2f0
f0103962:	66 c7 05 f2 a2 22 f0 	movw   $0x8,0xf022a2f2
f0103969:	08 00 
f010396b:	c6 05 f4 a2 22 f0 00 	movb   $0x0,0xf022a2f4
f0103972:	c6 05 f5 a2 22 f0 8e 	movb   $0x8e,0xf022a2f5
f0103979:	c1 e8 10             	shr    $0x10,%eax
f010397c:	66 a3 f6 a2 22 f0    	mov    %ax,0xf022a2f6
	SETGATE(idt[19],0,GD_KT,simd_floating_error,0);
f0103982:	b8 a4 3e 10 f0       	mov    $0xf0103ea4,%eax
f0103987:	66 a3 f8 a2 22 f0    	mov    %ax,0xf022a2f8
f010398d:	66 c7 05 fa a2 22 f0 	movw   $0x8,0xf022a2fa
f0103994:	08 00 
f0103996:	c6 05 fc a2 22 f0 00 	movb   $0x0,0xf022a2fc
f010399d:	c6 05 fd a2 22 f0 8e 	movb   $0x8e,0xf022a2fd
f01039a4:	c1 e8 10             	shr    $0x10,%eax
f01039a7:	66 a3 fe a2 22 f0    	mov    %ax,0xf022a2fe
	SETGATE(idt[48],0,GD_KT,system_call,3);
f01039ad:	b8 aa 3e 10 f0       	mov    $0xf0103eaa,%eax
f01039b2:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f01039b8:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f01039bf:	08 00 
f01039c1:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f01039c8:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f01039cf:	c1 e8 10             	shr    $0x10,%eax
f01039d2:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6
	// Per-CPU setup 
	trap_init_percpu();
f01039d8:	e8 f4 fb ff ff       	call   f01035d1 <trap_init_percpu>
}
f01039dd:	c9                   	leave  
f01039de:	c3                   	ret    

f01039df <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039df:	55                   	push   %ebp
f01039e0:	89 e5                	mov    %esp,%ebp
f01039e2:	53                   	push   %ebx
f01039e3:	83 ec 0c             	sub    $0xc,%esp
f01039e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039e9:	ff 33                	pushl  (%ebx)
f01039eb:	68 34 6f 10 f0       	push   $0xf0106f34
f01039f0:	e8 c8 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039f5:	83 c4 08             	add    $0x8,%esp
f01039f8:	ff 73 04             	pushl  0x4(%ebx)
f01039fb:	68 43 6f 10 f0       	push   $0xf0106f43
f0103a00:	e8 b8 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a05:	83 c4 08             	add    $0x8,%esp
f0103a08:	ff 73 08             	pushl  0x8(%ebx)
f0103a0b:	68 52 6f 10 f0       	push   $0xf0106f52
f0103a10:	e8 a8 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a15:	83 c4 08             	add    $0x8,%esp
f0103a18:	ff 73 0c             	pushl  0xc(%ebx)
f0103a1b:	68 61 6f 10 f0       	push   $0xf0106f61
f0103a20:	e8 98 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a25:	83 c4 08             	add    $0x8,%esp
f0103a28:	ff 73 10             	pushl  0x10(%ebx)
f0103a2b:	68 70 6f 10 f0       	push   $0xf0106f70
f0103a30:	e8 88 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a35:	83 c4 08             	add    $0x8,%esp
f0103a38:	ff 73 14             	pushl  0x14(%ebx)
f0103a3b:	68 7f 6f 10 f0       	push   $0xf0106f7f
f0103a40:	e8 78 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a45:	83 c4 08             	add    $0x8,%esp
f0103a48:	ff 73 18             	pushl  0x18(%ebx)
f0103a4b:	68 8e 6f 10 f0       	push   $0xf0106f8e
f0103a50:	e8 68 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a55:	83 c4 08             	add    $0x8,%esp
f0103a58:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a5b:	68 9d 6f 10 f0       	push   $0xf0106f9d
f0103a60:	e8 58 fb ff ff       	call   f01035bd <cprintf>
}
f0103a65:	83 c4 10             	add    $0x10,%esp
f0103a68:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a6b:	c9                   	leave  
f0103a6c:	c3                   	ret    

f0103a6d <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103a6d:	55                   	push   %ebp
f0103a6e:	89 e5                	mov    %esp,%ebp
f0103a70:	56                   	push   %esi
f0103a71:	53                   	push   %ebx
f0103a72:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a75:	e8 a5 1b 00 00       	call   f010561f <cpunum>
f0103a7a:	83 ec 04             	sub    $0x4,%esp
f0103a7d:	50                   	push   %eax
f0103a7e:	53                   	push   %ebx
f0103a7f:	68 01 70 10 f0       	push   $0xf0107001
f0103a84:	e8 34 fb ff ff       	call   f01035bd <cprintf>
	print_regs(&tf->tf_regs);
f0103a89:	89 1c 24             	mov    %ebx,(%esp)
f0103a8c:	e8 4e ff ff ff       	call   f01039df <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a91:	83 c4 08             	add    $0x8,%esp
f0103a94:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a98:	50                   	push   %eax
f0103a99:	68 1f 70 10 f0       	push   $0xf010701f
f0103a9e:	e8 1a fb ff ff       	call   f01035bd <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103aa3:	83 c4 08             	add    $0x8,%esp
f0103aa6:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103aaa:	50                   	push   %eax
f0103aab:	68 32 70 10 f0       	push   $0xf0107032
f0103ab0:	e8 08 fb ff ff       	call   f01035bd <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ab5:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103ab8:	83 c4 10             	add    $0x10,%esp
f0103abb:	83 f8 13             	cmp    $0x13,%eax
f0103abe:	77 09                	ja     f0103ac9 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ac0:	8b 14 85 a0 72 10 f0 	mov    -0xfef8d60(,%eax,4),%edx
f0103ac7:	eb 1f                	jmp    f0103ae8 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ac9:	83 f8 30             	cmp    $0x30,%eax
f0103acc:	74 15                	je     f0103ae3 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103ace:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ad1:	83 fa 10             	cmp    $0x10,%edx
f0103ad4:	b9 cb 6f 10 f0       	mov    $0xf0106fcb,%ecx
f0103ad9:	ba b8 6f 10 f0       	mov    $0xf0106fb8,%edx
f0103ade:	0f 43 d1             	cmovae %ecx,%edx
f0103ae1:	eb 05                	jmp    f0103ae8 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103ae3:	ba ac 6f 10 f0       	mov    $0xf0106fac,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ae8:	83 ec 04             	sub    $0x4,%esp
f0103aeb:	52                   	push   %edx
f0103aec:	50                   	push   %eax
f0103aed:	68 45 70 10 f0       	push   $0xf0107045
f0103af2:	e8 c6 fa ff ff       	call   f01035bd <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103af7:	83 c4 10             	add    $0x10,%esp
f0103afa:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b00:	75 1a                	jne    f0103b1c <print_trapframe+0xaf>
f0103b02:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b06:	75 14                	jne    f0103b1c <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103b08:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b0b:	83 ec 08             	sub    $0x8,%esp
f0103b0e:	50                   	push   %eax
f0103b0f:	68 57 70 10 f0       	push   $0xf0107057
f0103b14:	e8 a4 fa ff ff       	call   f01035bd <cprintf>
f0103b19:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b1c:	83 ec 08             	sub    $0x8,%esp
f0103b1f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b22:	68 66 70 10 f0       	push   $0xf0107066
f0103b27:	e8 91 fa ff ff       	call   f01035bd <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b2c:	83 c4 10             	add    $0x10,%esp
f0103b2f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b33:	75 49                	jne    f0103b7e <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b35:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b38:	89 c2                	mov    %eax,%edx
f0103b3a:	83 e2 01             	and    $0x1,%edx
f0103b3d:	ba e5 6f 10 f0       	mov    $0xf0106fe5,%edx
f0103b42:	b9 da 6f 10 f0       	mov    $0xf0106fda,%ecx
f0103b47:	0f 44 ca             	cmove  %edx,%ecx
f0103b4a:	89 c2                	mov    %eax,%edx
f0103b4c:	83 e2 02             	and    $0x2,%edx
f0103b4f:	ba f7 6f 10 f0       	mov    $0xf0106ff7,%edx
f0103b54:	be f1 6f 10 f0       	mov    $0xf0106ff1,%esi
f0103b59:	0f 45 d6             	cmovne %esi,%edx
f0103b5c:	83 e0 04             	and    $0x4,%eax
f0103b5f:	be 31 71 10 f0       	mov    $0xf0107131,%esi
f0103b64:	b8 fc 6f 10 f0       	mov    $0xf0106ffc,%eax
f0103b69:	0f 44 c6             	cmove  %esi,%eax
f0103b6c:	51                   	push   %ecx
f0103b6d:	52                   	push   %edx
f0103b6e:	50                   	push   %eax
f0103b6f:	68 74 70 10 f0       	push   $0xf0107074
f0103b74:	e8 44 fa ff ff       	call   f01035bd <cprintf>
f0103b79:	83 c4 10             	add    $0x10,%esp
f0103b7c:	eb 10                	jmp    f0103b8e <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b7e:	83 ec 0c             	sub    $0xc,%esp
f0103b81:	68 29 6e 10 f0       	push   $0xf0106e29
f0103b86:	e8 32 fa ff ff       	call   f01035bd <cprintf>
f0103b8b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b8e:	83 ec 08             	sub    $0x8,%esp
f0103b91:	ff 73 30             	pushl  0x30(%ebx)
f0103b94:	68 83 70 10 f0       	push   $0xf0107083
f0103b99:	e8 1f fa ff ff       	call   f01035bd <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b9e:	83 c4 08             	add    $0x8,%esp
f0103ba1:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ba5:	50                   	push   %eax
f0103ba6:	68 92 70 10 f0       	push   $0xf0107092
f0103bab:	e8 0d fa ff ff       	call   f01035bd <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bb0:	83 c4 08             	add    $0x8,%esp
f0103bb3:	ff 73 38             	pushl  0x38(%ebx)
f0103bb6:	68 a5 70 10 f0       	push   $0xf01070a5
f0103bbb:	e8 fd f9 ff ff       	call   f01035bd <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bc0:	83 c4 10             	add    $0x10,%esp
f0103bc3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bc7:	74 25                	je     f0103bee <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bc9:	83 ec 08             	sub    $0x8,%esp
f0103bcc:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bcf:	68 b4 70 10 f0       	push   $0xf01070b4
f0103bd4:	e8 e4 f9 ff ff       	call   f01035bd <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103bd9:	83 c4 08             	add    $0x8,%esp
f0103bdc:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103be0:	50                   	push   %eax
f0103be1:	68 c3 70 10 f0       	push   $0xf01070c3
f0103be6:	e8 d2 f9 ff ff       	call   f01035bd <cprintf>
f0103beb:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bee:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bf1:	5b                   	pop    %ebx
f0103bf2:	5e                   	pop    %esi
f0103bf3:	5d                   	pop    %ebp
f0103bf4:	c3                   	ret    

f0103bf5 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bf5:	55                   	push   %ebp
f0103bf6:	89 e5                	mov    %esp,%ebp
f0103bf8:	57                   	push   %edi
f0103bf9:	56                   	push   %esi
f0103bfa:	53                   	push   %ebx
f0103bfb:	83 ec 0c             	sub    $0xc,%esp
f0103bfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c01:	0f 20 d6             	mov    %cr2,%esi
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c04:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c07:	e8 13 1a 00 00       	call   f010561f <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c0c:	57                   	push   %edi
f0103c0d:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c0e:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c11:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103c17:	ff 70 48             	pushl  0x48(%eax)
f0103c1a:	68 7c 72 10 f0       	push   $0xf010727c
f0103c1f:	e8 99 f9 ff ff       	call   f01035bd <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103c24:	89 1c 24             	mov    %ebx,(%esp)
f0103c27:	e8 41 fe ff ff       	call   f0103a6d <print_trapframe>
	env_destroy(curenv);
f0103c2c:	e8 ee 19 00 00       	call   f010561f <cpunum>
f0103c31:	83 c4 04             	add    $0x4,%esp
f0103c34:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c37:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103c3d:	e8 88 f6 ff ff       	call   f01032ca <env_destroy>
}
f0103c42:	83 c4 10             	add    $0x10,%esp
f0103c45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c48:	5b                   	pop    %ebx
f0103c49:	5e                   	pop    %esi
f0103c4a:	5f                   	pop    %edi
f0103c4b:	5d                   	pop    %ebp
f0103c4c:	c3                   	ret    

f0103c4d <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103c4d:	55                   	push   %ebp
f0103c4e:	89 e5                	mov    %esp,%ebp
f0103c50:	57                   	push   %edi
f0103c51:	56                   	push   %esi
f0103c52:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103c55:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103c56:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103c5d:	74 01                	je     f0103c60 <trap+0x13>
		asm volatile("hlt");
f0103c5f:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103c60:	e8 ba 19 00 00       	call   f010561f <cpunum>
f0103c65:	6b d0 74             	imul   $0x74,%eax,%edx
f0103c68:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103c6e:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c73:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103c77:	83 f8 02             	cmp    $0x2,%eax
f0103c7a:	75 10                	jne    f0103c8c <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103c7c:	83 ec 0c             	sub    $0xc,%esp
f0103c7f:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103c84:	e8 04 1c 00 00       	call   f010588d <spin_lock>
f0103c89:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103c8c:	9c                   	pushf  
f0103c8d:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103c8e:	f6 c4 02             	test   $0x2,%ah
f0103c91:	74 19                	je     f0103cac <trap+0x5f>
f0103c93:	68 d6 70 10 f0       	push   $0xf01070d6
f0103c98:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0103c9d:	68 11 01 00 00       	push   $0x111
f0103ca2:	68 ef 70 10 f0       	push   $0xf01070ef
f0103ca7:	e8 94 c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103cac:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103cb0:	83 e0 03             	and    $0x3,%eax
f0103cb3:	66 83 f8 03          	cmp    $0x3,%ax
f0103cb7:	0f 85 a0 00 00 00    	jne    f0103d5d <trap+0x110>
f0103cbd:	83 ec 0c             	sub    $0xc,%esp
f0103cc0:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103cc5:	e8 c3 1b 00 00       	call   f010588d <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock be  fore doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103cca:	e8 50 19 00 00       	call   f010561f <cpunum>
f0103ccf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd2:	83 c4 10             	add    $0x10,%esp
f0103cd5:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103cdc:	75 19                	jne    f0103cf7 <trap+0xaa>
f0103cde:	68 fb 70 10 f0       	push   $0xf01070fb
f0103ce3:	68 6f 6b 10 f0       	push   $0xf0106b6f
f0103ce8:	68 19 01 00 00       	push   $0x119
f0103ced:	68 ef 70 10 f0       	push   $0xf01070ef
f0103cf2:	e8 49 c3 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103cf7:	e8 23 19 00 00       	call   f010561f <cpunum>
f0103cfc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cff:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d05:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d09:	75 2d                	jne    f0103d38 <trap+0xeb>
			env_free(curenv);
f0103d0b:	e8 0f 19 00 00       	call   f010561f <cpunum>
f0103d10:	83 ec 0c             	sub    $0xc,%esp
f0103d13:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d16:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d1c:	e8 ce f3 ff ff       	call   f01030ef <env_free>
			curenv = NULL;
f0103d21:	e8 f9 18 00 00       	call   f010561f <cpunum>
f0103d26:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d29:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103d30:	00 00 00 
			sched_yield();
f0103d33:	e8 5e 02 00 00       	call   f0103f96 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103d38:	e8 e2 18 00 00       	call   f010561f <cpunum>
f0103d3d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d40:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d46:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103d4b:	89 c7                	mov    %eax,%edi
f0103d4d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103d4f:	e8 cb 18 00 00       	call   f010561f <cpunum>
f0103d54:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d57:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103d5d:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103d63:	8b 46 28             	mov    0x28(%esi),%eax
f0103d66:	83 f8 27             	cmp    $0x27,%eax
f0103d69:	75 1d                	jne    f0103d88 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103d6b:	83 ec 0c             	sub    $0xc,%esp
f0103d6e:	68 02 71 10 f0       	push   $0xf0107102
f0103d73:	e8 45 f8 ff ff       	call   f01035bd <cprintf>
		print_trapframe(tf);
f0103d78:	89 34 24             	mov    %esi,(%esp)
f0103d7b:	e8 ed fc ff ff       	call   f0103a6d <print_trapframe>
f0103d80:	83 c4 10             	add    $0x10,%esp
f0103d83:	e9 83 00 00 00       	jmp    f0103e0b <trap+0x1be>
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	//print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
f0103d88:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103d8d:	75 17                	jne    f0103da6 <trap+0x159>
		panic("unhandled trap in kernel");
f0103d8f:	83 ec 04             	sub    $0x4,%esp
f0103d92:	68 1f 71 10 f0       	push   $0xf010711f
f0103d97:	68 e6 00 00 00       	push   $0xe6
f0103d9c:	68 ef 70 10 f0       	push   $0xf01070ef
f0103da1:	e8 9a c2 ff ff       	call   f0100040 <_panic>
	else {
		//cprintf("asdas\n");
		if(tf->tf_trapno ==T_PGFLT)
f0103da6:	83 f8 0e             	cmp    $0xe,%eax
f0103da9:	75 0e                	jne    f0103db9 <trap+0x16c>
		{
			page_fault_handler(tf);
f0103dab:	83 ec 0c             	sub    $0xc,%esp
f0103dae:	56                   	push   %esi
f0103daf:	e8 41 fe ff ff       	call   f0103bf5 <page_fault_handler>
f0103db4:	83 c4 10             	add    $0x10,%esp
f0103db7:	eb 52                	jmp    f0103e0b <trap+0x1be>
		}
		else if(tf->tf_trapno==T_BRKPT)
f0103db9:	83 f8 03             	cmp    $0x3,%eax
f0103dbc:	75 0e                	jne    f0103dcc <trap+0x17f>
		{
			monitor(tf);
f0103dbe:	83 ec 0c             	sub    $0xc,%esp
f0103dc1:	56                   	push   %esi
f0103dc2:	e8 ba ca ff ff       	call   f0100881 <monitor>
f0103dc7:	83 c4 10             	add    $0x10,%esp
f0103dca:	eb 3f                	jmp    f0103e0b <trap+0x1be>
		}
		else if(tf->tf_trapno==T_SYSCALL)
f0103dcc:	83 f8 30             	cmp    $0x30,%eax
f0103dcf:	75 21                	jne    f0103df2 <trap+0x1a5>
		{
			tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103dd1:	83 ec 08             	sub    $0x8,%esp
f0103dd4:	ff 76 04             	pushl  0x4(%esi)
f0103dd7:	ff 36                	pushl  (%esi)
f0103dd9:	ff 76 10             	pushl  0x10(%esi)
f0103ddc:	ff 76 18             	pushl  0x18(%esi)
f0103ddf:	ff 76 14             	pushl  0x14(%esi)
f0103de2:	ff 76 1c             	pushl  0x1c(%esi)
f0103de5:	e8 1a 02 00 00       	call   f0104004 <syscall>
f0103dea:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103ded:	83 c4 20             	add    $0x20,%esp
f0103df0:	eb 19                	jmp    f0103e0b <trap+0x1be>
		}
		else
		{
		
			env_destroy(curenv);
f0103df2:	e8 28 18 00 00       	call   f010561f <cpunum>
f0103df7:	83 ec 0c             	sub    $0xc,%esp
f0103dfa:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfd:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e03:	e8 c2 f4 ff ff       	call   f01032ca <env_destroy>
f0103e08:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103e0b:	e8 0f 18 00 00       	call   f010561f <cpunum>
f0103e10:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e13:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103e1a:	74 2a                	je     f0103e46 <trap+0x1f9>
f0103e1c:	e8 fe 17 00 00       	call   f010561f <cpunum>
f0103e21:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e24:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103e2a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e2e:	75 16                	jne    f0103e46 <trap+0x1f9>
	{
		env_run(curenv);
f0103e30:	e8 ea 17 00 00       	call   f010561f <cpunum>
f0103e35:	83 ec 0c             	sub    $0xc,%esp
f0103e38:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e3b:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e41:	e8 33 f5 ff ff       	call   f0103379 <env_run>
	}
	else
	{
		sched_yield();
f0103e46:	e8 4b 01 00 00       	call   f0103f96 <sched_yield>
f0103e4b:	90                   	nop

f0103e4c <divide_error>:
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
TRAPHANDLER_NOEC(divide_error,T_DIVIDE)
f0103e4c:	6a 00                	push   $0x0
f0103e4e:	6a 00                	push   $0x0
f0103e50:	eb 5e                	jmp    f0103eb0 <_alltraps>

f0103e52 <debuf_exception>:
TRAPHANDLER_NOEC(debuf_exception,T_DEBUG)
f0103e52:	6a 00                	push   $0x0
f0103e54:	6a 01                	push   $0x1
f0103e56:	eb 58                	jmp    f0103eb0 <_alltraps>

f0103e58 <nmi_interrupt>:
TRAPHANDLER_NOEC(nmi_interrupt,T_NMI)
f0103e58:	6a 00                	push   $0x0
f0103e5a:	6a 02                	push   $0x2
f0103e5c:	eb 52                	jmp    f0103eb0 <_alltraps>

f0103e5e <break_point>:
TRAPHANDLER_NOEC(break_point,T_BRKPT)
f0103e5e:	6a 00                	push   $0x0
f0103e60:	6a 03                	push   $0x3
f0103e62:	eb 4c                	jmp    f0103eb0 <_alltraps>

f0103e64 <overflow>:
TRAPHANDLER_NOEC(overflow,T_OFLOW)
f0103e64:	6a 00                	push   $0x0
f0103e66:	6a 04                	push   $0x4
f0103e68:	eb 46                	jmp    f0103eb0 <_alltraps>

f0103e6a <bound_check>:
TRAPHANDLER_NOEC(bound_check,T_BOUND);
f0103e6a:	6a 00                	push   $0x0
f0103e6c:	6a 05                	push   $0x5
f0103e6e:	eb 40                	jmp    f0103eb0 <_alltraps>

f0103e70 <illegal_opcode>:
TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)
f0103e70:	6a 00                	push   $0x0
f0103e72:	6a 06                	push   $0x6
f0103e74:	eb 3a                	jmp    f0103eb0 <_alltraps>

f0103e76 <device_not_available>:
TRAPHANDLER_NOEC(device_not_available,T_DEVICE)
f0103e76:	6a 00                	push   $0x0
f0103e78:	6a 07                	push   $0x7
f0103e7a:	eb 34                	jmp    f0103eb0 <_alltraps>

f0103e7c <double_fault>:
TRAPHANDLER(double_fault,T_DBLFLT)
f0103e7c:	6a 08                	push   $0x8
f0103e7e:	eb 30                	jmp    f0103eb0 <_alltraps>

f0103e80 <invalid_tss>:
TRAPHANDLER(invalid_tss,T_TSS)
f0103e80:	6a 0a                	push   $0xa
f0103e82:	eb 2c                	jmp    f0103eb0 <_alltraps>

f0103e84 <segment_not_present>:
TRAPHANDLER(segment_not_present,T_SEGNP)
f0103e84:	6a 0b                	push   $0xb
f0103e86:	eb 28                	jmp    f0103eb0 <_alltraps>

f0103e88 <stack_exception>:
TRAPHANDLER(stack_exception,T_STACK)
f0103e88:	6a 0c                	push   $0xc
f0103e8a:	eb 24                	jmp    f0103eb0 <_alltraps>

f0103e8c <general_protection_fault>:
TRAPHANDLER(general_protection_fault,T_GPFLT)
f0103e8c:	6a 0d                	push   $0xd
f0103e8e:	eb 20                	jmp    f0103eb0 <_alltraps>

f0103e90 <page_fault>:
TRAPHANDLER(page_fault,T_PGFLT)
f0103e90:	6a 0e                	push   $0xe
f0103e92:	eb 1c                	jmp    f0103eb0 <_alltraps>

f0103e94 <floating_point_error>:
TRAPHANDLER_NOEC(floating_point_error,T_FPERR)
f0103e94:	6a 00                	push   $0x0
f0103e96:	6a 10                	push   $0x10
f0103e98:	eb 16                	jmp    f0103eb0 <_alltraps>

f0103e9a <alignment_check>:
TRAPHANDLER(alignment_check,T_ALIGN)
f0103e9a:	6a 11                	push   $0x11
f0103e9c:	eb 12                	jmp    f0103eb0 <_alltraps>

f0103e9e <machine_check>:
TRAPHANDLER_NOEC(machine_check,T_MCHK)
f0103e9e:	6a 00                	push   $0x0
f0103ea0:	6a 12                	push   $0x12
f0103ea2:	eb 0c                	jmp    f0103eb0 <_alltraps>

f0103ea4 <simd_floating_error>:
TRAPHANDLER_NOEC(simd_floating_error,T_SIMDERR)
f0103ea4:	6a 00                	push   $0x0
f0103ea6:	6a 13                	push   $0x13
f0103ea8:	eb 06                	jmp    f0103eb0 <_alltraps>

f0103eaa <system_call>:
TRAPHANDLER_NOEC(system_call,T_SYSCALL)
f0103eaa:	6a 00                	push   $0x0
f0103eac:	6a 30                	push   $0x30
f0103eae:	eb 00                	jmp    f0103eb0 <_alltraps>

f0103eb0 <_alltraps>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
_alltraps:
pushl %ds
f0103eb0:	1e                   	push   %ds
pushl %es
f0103eb1:	06                   	push   %es
pushal
f0103eb2:	60                   	pusha  
movl $GD_KD,%eax
f0103eb3:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax,%ds
f0103eb8:	8e d8                	mov    %eax,%ds
movw %ax,%es
f0103eba:	8e c0                	mov    %eax,%es
pushl %esp
f0103ebc:	54                   	push   %esp
call trap
f0103ebd:	e8 8b fd ff ff       	call   f0103c4d <trap>

f0103ec2 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103ec2:	55                   	push   %ebp
f0103ec3:	89 e5                	mov    %esp,%ebp
f0103ec5:	83 ec 08             	sub    $0x8,%esp
f0103ec8:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0103ecd:	8d 50 54             	lea    0x54(%eax),%edx
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103ed0:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103ed5:	8b 02                	mov    (%edx),%eax
f0103ed7:	83 e8 01             	sub    $0x1,%eax
f0103eda:	83 f8 02             	cmp    $0x2,%eax
f0103edd:	76 10                	jbe    f0103eef <sched_halt+0x2d>
sched_halt(void)
{
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103edf:	83 c1 01             	add    $0x1,%ecx
f0103ee2:	83 c2 7c             	add    $0x7c,%edx
f0103ee5:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103eeb:	75 e8                	jne    f0103ed5 <sched_halt+0x13>
f0103eed:	eb 08                	jmp    f0103ef7 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103eef:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103ef5:	75 1f                	jne    f0103f16 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103ef7:	83 ec 0c             	sub    $0xc,%esp
f0103efa:	68 f0 72 10 f0       	push   $0xf01072f0
f0103eff:	e8 b9 f6 ff ff       	call   f01035bd <cprintf>
f0103f04:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103f07:	83 ec 0c             	sub    $0xc,%esp
f0103f0a:	6a 00                	push   $0x0
f0103f0c:	e8 70 c9 ff ff       	call   f0100881 <monitor>
f0103f11:	83 c4 10             	add    $0x10,%esp
f0103f14:	eb f1                	jmp    f0103f07 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103f16:	e8 04 17 00 00       	call   f010561f <cpunum>
f0103f1b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1e:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103f25:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103f28:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f2d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f32:	77 12                	ja     f0103f46 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f34:	50                   	push   %eax
f0103f35:	68 08 5d 10 f0       	push   $0xf0105d08
f0103f3a:	6a 4e                	push   $0x4e
f0103f3c:	68 19 73 10 f0       	push   $0xf0107319
f0103f41:	e8 fa c0 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103f46:	05 00 00 00 10       	add    $0x10000000,%eax
f0103f4b:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103f4e:	e8 cc 16 00 00       	call   f010561f <cpunum>
f0103f53:	6b d0 74             	imul   $0x74,%eax,%edx
f0103f56:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103f5c:	b8 02 00 00 00       	mov    $0x2,%eax
f0103f61:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103f65:	83 ec 0c             	sub    $0xc,%esp
f0103f68:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103f6d:	e8 b8 19 00 00       	call   f010592a <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103f72:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103f74:	e8 a6 16 00 00       	call   f010561f <cpunum>
f0103f79:	6b c0 74             	imul   $0x74,%eax,%eax
	//cprintf("in the halt\n");
	// Reset stack pointer, enable interrupts and then halt.
	//cprintf("this cpu:%08x\n",thiscpu->cpu_ts.ts_esp0);
	//for(;;);
	
	asm volatile (
f0103f7c:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0103f82:	bd 00 00 00 00       	mov    $0x0,%ebp
f0103f87:	89 c4                	mov    %eax,%esp
f0103f89:	6a 00                	push   $0x0
f0103f8b:	6a 00                	push   $0x0
f0103f8d:	fb                   	sti    
f0103f8e:	f4                   	hlt    
f0103f8f:	eb fd                	jmp    f0103f8e <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0103f91:	83 c4 10             	add    $0x10,%esp
f0103f94:	c9                   	leave  
f0103f95:	c3                   	ret    

f0103f96 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0103f96:	55                   	push   %ebp
f0103f97:	89 e5                	mov    %esp,%ebp
f0103f99:	56                   	push   %esi
f0103f9a:	53                   	push   %ebx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
f0103f9b:	e8 7f 16 00 00       	call   f010561f <cpunum>
f0103fa0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fa3:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
f0103fa9:	85 f6                	test   %esi,%esi
f0103fab:	74 0b                	je     f0103fb8 <sched_yield+0x22>
f0103fad:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103fb0:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0103fb6:	eb 05                	jmp    f0103fbd <sched_yield+0x27>
f0103fb8:	b9 00 00 00 00       	mov    $0x0,%ecx
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f0103fbd:	8b 1d 44 a2 22 f0    	mov    0xf022a244,%ebx
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
f0103fc3:	89 c8                	mov    %ecx,%eax
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f0103fc5:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0103fc8:	01 da                	add    %ebx,%edx
f0103fca:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0103fce:	75 09                	jne    f0103fd9 <sched_yield+0x43>
       		{	   
       		        env_run(&envs[i]);  
f0103fd0:	83 ec 0c             	sub    $0xc,%esp
f0103fd3:	52                   	push   %edx
f0103fd4:	e8 a0 f3 ff ff       	call   f0103379 <env_run>
	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
f0103fd9:	83 c0 01             	add    $0x1,%eax
f0103fdc:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103fe1:	39 c1                	cmp    %eax,%ecx
f0103fe3:	75 e0                	jne    f0103fc5 <sched_yield+0x2f>
       		        env_run(&envs[i]);  
            		return ;  
        	}  
   	 }  
  
        if (idle && idle->env_status == ENV_RUNNING)  
f0103fe5:	85 f6                	test   %esi,%esi
f0103fe7:	74 0f                	je     f0103ff8 <sched_yield+0x62>
f0103fe9:	83 7e 54 03          	cmpl   $0x3,0x54(%esi)
f0103fed:	75 09                	jne    f0103ff8 <sched_yield+0x62>
	{  
       	 	env_run(idle);  
f0103fef:	83 ec 0c             	sub    $0xc,%esp
f0103ff2:	56                   	push   %esi
f0103ff3:	e8 81 f3 ff ff       	call   f0103379 <env_run>
        	return ;  
    	}  
  
    // sched_halt never returns  
    sched_halt();
f0103ff8:	e8 c5 fe ff ff       	call   f0103ec2 <sched_halt>
}
f0103ffd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104000:	5b                   	pop    %ebx
f0104001:	5e                   	pop    %esi
f0104002:	5d                   	pop    %ebp
f0104003:	c3                   	ret    

f0104004 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104004:	55                   	push   %ebp
f0104005:	89 e5                	mov    %esp,%ebp
f0104007:	57                   	push   %edi
f0104008:	56                   	push   %esi
f0104009:	53                   	push   %ebx
f010400a:	83 ec 1c             	sub    $0x1c,%esp
f010400d:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) 
f0104010:	83 f8 0a             	cmp    $0xa,%eax
f0104013:	0f 87 4b 04 00 00    	ja     f0104464 <syscall+0x460>
f0104019:	ff 24 85 60 73 10 f0 	jmp    *-0xfef8ca0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f0104020:	e8 fa 15 00 00       	call   f010561f <cpunum>
f0104025:	6a 04                	push   $0x4
f0104027:	ff 75 10             	pushl  0x10(%ebp)
f010402a:	ff 75 0c             	pushl  0xc(%ebp)
f010402d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104030:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104036:	e8 35 ec ff ff       	call   f0102c70 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010403b:	83 c4 0c             	add    $0xc,%esp
f010403e:	ff 75 0c             	pushl  0xc(%ebp)
f0104041:	ff 75 10             	pushl  0x10(%ebp)
f0104044:	68 26 73 10 f0       	push   $0xf0107326
f0104049:	e8 6f f5 ff ff       	call   f01035bd <cprintf>
f010404e:	83 c4 10             	add    $0x10,%esp
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
		default:
			return -E_INVAL;
	}
	return 0;
f0104051:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104056:	e9 0e 04 00 00       	jmp    f0104469 <syscall+0x465>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010405b:	e8 95 c5 ff ff       	call   f01005f5 <cons_getc>
f0104060:	89 c3                	mov    %eax,%ebx
	 {
		case 0:
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
f0104062:	e9 02 04 00 00       	jmp    f0104469 <syscall+0x465>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104067:	e8 b3 15 00 00       	call   f010561f <cpunum>
f010406c:	6b c0 74             	imul   $0x74,%eax,%eax
f010406f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104075:	8b 58 48             	mov    0x48(%eax),%ebx
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
		case 2:
			return sys_getenvid();	
f0104078:	e9 ec 03 00 00       	jmp    f0104469 <syscall+0x465>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010407d:	83 ec 04             	sub    $0x4,%esp
f0104080:	6a 01                	push   $0x1
f0104082:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104085:	50                   	push   %eax
f0104086:	ff 75 0c             	pushl  0xc(%ebp)
f0104089:	e8 b7 ec ff ff       	call   f0102d45 <envid2env>
f010408e:	83 c4 10             	add    $0x10,%esp
		return r;
f0104091:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104093:	85 c0                	test   %eax,%eax
f0104095:	0f 88 ce 03 00 00    	js     f0104469 <syscall+0x465>
		return r;
	if (e == curenv)
f010409b:	e8 7f 15 00 00       	call   f010561f <cpunum>
f01040a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01040a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01040a6:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f01040ac:	75 23                	jne    f01040d1 <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01040ae:	e8 6c 15 00 00       	call   f010561f <cpunum>
f01040b3:	83 ec 08             	sub    $0x8,%esp
f01040b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01040b9:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01040bf:	ff 70 48             	pushl  0x48(%eax)
f01040c2:	68 2b 73 10 f0       	push   $0xf010732b
f01040c7:	e8 f1 f4 ff ff       	call   f01035bd <cprintf>
f01040cc:	83 c4 10             	add    $0x10,%esp
f01040cf:	eb 25                	jmp    f01040f6 <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01040d1:	8b 5a 48             	mov    0x48(%edx),%ebx
f01040d4:	e8 46 15 00 00       	call   f010561f <cpunum>
f01040d9:	83 ec 04             	sub    $0x4,%esp
f01040dc:	53                   	push   %ebx
f01040dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01040e0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01040e6:	ff 70 48             	pushl  0x48(%eax)
f01040e9:	68 46 73 10 f0       	push   $0xf0107346
f01040ee:	e8 ca f4 ff ff       	call   f01035bd <cprintf>
f01040f3:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01040f6:	83 ec 0c             	sub    $0xc,%esp
f01040f9:	ff 75 e4             	pushl  -0x1c(%ebp)
f01040fc:	e8 c9 f1 ff ff       	call   f01032ca <env_destroy>
f0104101:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104104:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104109:	e9 5b 03 00 00       	jmp    f0104469 <syscall+0x465>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010410e:	e8 83 fe ff ff       	call   f0103f96 <sched_yield>
	//   allocated!

	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
f0104113:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010411a:	0f 87 d6 00 00 00    	ja     f01041f6 <syscall+0x1f2>
f0104120:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104127:	0f 85 d3 00 00 00    	jne    f0104200 <syscall+0x1fc>
	{
		return -E_INVAL;
	}
	if(envid2env(envid,&e,1)<0)
f010412d:	83 ec 04             	sub    $0x4,%esp
f0104130:	6a 01                	push   $0x1
f0104132:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104135:	50                   	push   %eax
f0104136:	ff 75 0c             	pushl  0xc(%ebp)
f0104139:	e8 07 ec ff ff       	call   f0102d45 <envid2env>
f010413e:	83 c4 10             	add    $0x10,%esp
f0104141:	85 c0                	test   %eax,%eax
f0104143:	0f 88 c1 00 00 00    	js     f010420a <syscall+0x206>
		return -E_BAD_ENV;
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104149:	8b 45 14             	mov    0x14(%ebp),%eax
f010414c:	83 e0 05             	and    $0x5,%eax
f010414f:	83 f8 05             	cmp    $0x5,%eax
f0104152:	0f 85 bc 00 00 00    	jne    f0104214 <syscall+0x210>
		return -E_INVAL;
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f0104158:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010415b:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f0104161:	0f 85 b7 00 00 00    	jne    f010421e <syscall+0x21a>
		return -E_INVAL;
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
f0104167:	83 ec 0c             	sub    $0xc,%esp
f010416a:	6a 01                	push   $0x1
f010416c:	e8 1b cd ff ff       	call   f0100e8c <page_alloc>
f0104171:	89 c6                	mov    %eax,%esi
	if(p==NULL)
f0104173:	83 c4 10             	add    $0x10,%esp
f0104176:	85 c0                	test   %eax,%eax
f0104178:	0f 84 aa 00 00 00    	je     f0104228 <syscall+0x224>
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir,p,(void *)va,perm)<0)
f010417e:	ff 75 14             	pushl  0x14(%ebp)
f0104181:	ff 75 10             	pushl  0x10(%ebp)
f0104184:	50                   	push   %eax
f0104185:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104188:	ff 70 60             	pushl  0x60(%eax)
f010418b:	e8 9d cf ff ff       	call   f010112d <page_insert>
f0104190:	83 c4 10             	add    $0x10,%esp
f0104193:	85 c0                	test   %eax,%eax
f0104195:	79 16                	jns    f01041ad <syscall+0x1a9>
	{
		page_free(p);
f0104197:	83 ec 0c             	sub    $0xc,%esp
f010419a:	56                   	push   %esi
f010419b:	e8 5c cd ff ff       	call   f0100efc <page_free>
f01041a0:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f01041a3:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
f01041a8:	e9 bc 02 00 00       	jmp    f0104469 <syscall+0x465>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01041ad:	2b 35 90 ae 22 f0    	sub    0xf022ae90,%esi
f01041b3:	c1 fe 03             	sar    $0x3,%esi
f01041b6:	c1 e6 0c             	shl    $0xc,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01041b9:	89 f0                	mov    %esi,%eax
f01041bb:	c1 e8 0c             	shr    $0xc,%eax
f01041be:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01041c4:	72 12                	jb     f01041d8 <syscall+0x1d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01041c6:	56                   	push   %esi
f01041c7:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01041cc:	6a 58                	push   $0x58
f01041ce:	68 55 6b 10 f0       	push   $0xf0106b55
f01041d3:	e8 68 be ff ff       	call   f0100040 <_panic>
	}
	memset(page2kva(p),0,PGSIZE);
f01041d8:	83 ec 04             	sub    $0x4,%esp
f01041db:	68 00 10 00 00       	push   $0x1000
f01041e0:	6a 00                	push   $0x0
f01041e2:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01041e8:	56                   	push   %esi
f01041e9:	e8 fb 0d 00 00       	call   f0104fe9 <memset>
f01041ee:	83 c4 10             	add    $0x10,%esp
f01041f1:	e9 73 02 00 00       	jmp    f0104469 <syscall+0x465>
	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
	{
		return -E_INVAL;
f01041f6:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01041fb:	e9 69 02 00 00       	jmp    f0104469 <syscall+0x465>
f0104200:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104205:	e9 5f 02 00 00       	jmp    f0104469 <syscall+0x465>
	}
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f010420a:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f010420f:	e9 55 02 00 00       	jmp    f0104469 <syscall+0x465>
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
		return -E_INVAL;
f0104214:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104219:	e9 4b 02 00 00       	jmp    f0104469 <syscall+0x465>
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
		return -E_INVAL;
f010421e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104223:	e9 41 02 00 00       	jmp    f0104469 <syscall+0x465>
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
	if(p==NULL)
		return -E_NO_MEM;
f0104228:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
			return sys_env_destroy(a1);	
		case SYS_yield:
		 	sys_yield();	
			break;
		case SYS_page_alloc:
			return sys_page_alloc(a1,(void *)a2,(int )a3);
f010422d:	e9 37 02 00 00       	jmp    f0104469 <syscall+0x465>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
f0104232:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104239:	0f 87 cf 00 00 00    	ja     f010430e <syscall+0x30a>
f010423f:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104246:	0f 85 cc 00 00 00    	jne    f0104318 <syscall+0x314>
f010424c:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104253:	0f 87 bf 00 00 00    	ja     f0104318 <syscall+0x314>
f0104259:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104260:	0f 85 bc 00 00 00    	jne    f0104322 <syscall+0x31e>
		return -E_INVAL;
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104266:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104269:	83 e0 05             	and    $0x5,%eax
f010426c:	83 f8 05             	cmp    $0x5,%eax
f010426f:	0f 85 b7 00 00 00    	jne    f010432c <syscall+0x328>
		return -E_INVAL;
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f0104275:	8b 5d 1c             	mov    0x1c(%ebp),%ebx
f0104278:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f010427e:	0f 85 b2 00 00 00    	jne    f0104336 <syscall+0x332>
		return -E_INVAL;
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
f0104284:	83 ec 04             	sub    $0x4,%esp
f0104287:	6a 01                	push   $0x1
f0104289:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010428c:	50                   	push   %eax
f010428d:	ff 75 0c             	pushl  0xc(%ebp)
f0104290:	e8 b0 ea ff ff       	call   f0102d45 <envid2env>
f0104295:	83 c4 10             	add    $0x10,%esp
f0104298:	85 c0                	test   %eax,%eax
f010429a:	0f 88 a0 00 00 00    	js     f0104340 <syscall+0x33c>
		return -E_BAD_ENV;
	if(envid2env(dstenvid,&desenv,1)<0)
f01042a0:	83 ec 04             	sub    $0x4,%esp
f01042a3:	6a 01                	push   $0x1
f01042a5:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01042a8:	50                   	push   %eax
f01042a9:	ff 75 14             	pushl  0x14(%ebp)
f01042ac:	e8 94 ea ff ff       	call   f0102d45 <envid2env>
f01042b1:	83 c4 10             	add    $0x10,%esp
f01042b4:	85 c0                	test   %eax,%eax
f01042b6:	0f 88 8e 00 00 00    	js     f010434a <syscall+0x346>
		return -E_BAD_ENV;
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
f01042bc:	83 ec 04             	sub    $0x4,%esp
f01042bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01042c2:	50                   	push   %eax
f01042c3:	ff 75 10             	pushl  0x10(%ebp)
f01042c6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01042c9:	ff 70 60             	pushl  0x60(%eax)
f01042cc:	e8 74 cd ff ff       	call   f0101045 <page_lookup>
	if (p==NULL||((perm*PTE_W)>0&&(*po_entry&PTE_W)==0))
f01042d1:	83 c4 10             	add    $0x10,%esp
f01042d4:	85 c0                	test   %eax,%eax
f01042d6:	74 7c                	je     f0104354 <syscall+0x350>
f01042d8:	8b 7d 1c             	mov    0x1c(%ebp),%edi
f01042db:	8d 14 3f             	lea    (%edi,%edi,1),%edx
f01042de:	85 d2                	test   %edx,%edx
f01042e0:	7e 08                	jle    f01042ea <syscall+0x2e6>
f01042e2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01042e5:	f6 02 02             	testb  $0x2,(%edx)
f01042e8:	74 74                	je     f010435e <syscall+0x35a>
		return -E_INVAL;
	if(page_insert(desenv->env_pgdir,p,dstva,perm)<0)
f01042ea:	ff 75 1c             	pushl  0x1c(%ebp)
f01042ed:	ff 75 18             	pushl  0x18(%ebp)
f01042f0:	50                   	push   %eax
f01042f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042f4:	ff 70 60             	pushl  0x60(%eax)
f01042f7:	e8 31 ce ff ff       	call   f010112d <page_insert>
f01042fc:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f01042ff:	85 c0                	test   %eax,%eax
f0104301:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104306:	0f 48 d8             	cmovs  %eax,%ebx
f0104309:	e9 5b 01 00 00       	jmp    f0104469 <syscall+0x465>
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
		return -E_INVAL;
f010430e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104313:	e9 51 01 00 00       	jmp    f0104469 <syscall+0x465>
f0104318:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010431d:	e9 47 01 00 00       	jmp    f0104469 <syscall+0x465>
f0104322:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104327:	e9 3d 01 00 00       	jmp    f0104469 <syscall+0x465>
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
		return -E_INVAL;
f010432c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104331:	e9 33 01 00 00       	jmp    f0104469 <syscall+0x465>
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
		return -E_INVAL;
f0104336:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010433b:	e9 29 01 00 00       	jmp    f0104469 <syscall+0x465>
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
		return -E_BAD_ENV;
f0104340:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104345:	e9 1f 01 00 00       	jmp    f0104469 <syscall+0x465>
	if(envid2env(dstenvid,&desenv,1)<0)
		return -E_BAD_ENV;
f010434a:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f010434f:	e9 15 01 00 00       	jmp    f0104469 <syscall+0x465>
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
	if (p==NULL||((perm*PTE_W)>0&&(*po_entry&PTE_W)==0))
		return -E_INVAL;
f0104354:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104359:	e9 0b 01 00 00       	jmp    f0104469 <syscall+0x465>
f010435e:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104363:	e9 01 01 00 00       	jmp    f0104469 <syscall+0x465>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
f0104368:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010436f:	77 3f                	ja     f01043b0 <syscall+0x3ac>
f0104371:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104378:	75 40                	jne    f01043ba <syscall+0x3b6>
		return -E_INVAL;
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
f010437a:	83 ec 04             	sub    $0x4,%esp
f010437d:	6a 01                	push   $0x1
f010437f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104382:	50                   	push   %eax
f0104383:	ff 75 0c             	pushl  0xc(%ebp)
f0104386:	e8 ba e9 ff ff       	call   f0102d45 <envid2env>
f010438b:	83 c4 10             	add    $0x10,%esp
f010438e:	85 c0                	test   %eax,%eax
f0104390:	78 32                	js     f01043c4 <syscall+0x3c0>
		return -E_BAD_ENV;
	page_remove(e->env_pgdir,va);
f0104392:	83 ec 08             	sub    $0x8,%esp
f0104395:	ff 75 10             	pushl  0x10(%ebp)
f0104398:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010439b:	ff 70 60             	pushl  0x60(%eax)
f010439e:	e8 3d cd ff ff       	call   f01010e0 <page_remove>
f01043a3:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043a6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01043ab:	e9 b9 00 00 00       	jmp    f0104469 <syscall+0x465>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
		return -E_INVAL;
f01043b0:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043b5:	e9 af 00 00 00       	jmp    f0104469 <syscall+0x465>
f01043ba:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043bf:	e9 a5 00 00 00       	jmp    f0104469 <syscall+0x465>
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f01043c4:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_page_alloc(a1,(void *)a2,(int )a3);
		case SYS_page_map:
			return 	sys_page_map((envid_t) a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int) a5); 
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
f01043c9:	e9 9b 00 00 00       	jmp    f0104469 <syscall+0x465>

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	//cprintf("%08x\n",curenv->env_id);
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f01043ce:	e8 4c 12 00 00       	call   f010561f <cpunum>
f01043d3:	83 ec 08             	sub    $0x8,%esp
f01043d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d9:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01043df:	ff 70 48             	pushl  0x48(%eax)
f01043e2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043e5:	50                   	push   %eax
f01043e6:	e8 6b ea ff ff       	call   f0102e56 <env_alloc>
f01043eb:	83 c4 10             	add    $0x10,%esp
	{
		return r;
f01043ee:	89 c3                	mov    %eax,%ebx

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	//cprintf("%08x\n",curenv->env_id);
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f01043f0:	85 c0                	test   %eax,%eax
f01043f2:	78 75                	js     f0104469 <syscall+0x465>
	{
		return r;
	}
	newenv->env_status=ENV_NOT_RUNNABLE;
f01043f4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043f7:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv->env_tf=curenv->env_tf;
f01043fe:	e8 1c 12 00 00       	call   f010561f <cpunum>
f0104403:	6b c0 74             	imul   $0x74,%eax,%eax
f0104406:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
f010440c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104411:	89 df                	mov    %ebx,%edi
f0104413:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv->env_tf.tf_regs.reg_eax=0;
f0104415:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104418:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return newenv->env_id;
f010441f:	8b 58 48             	mov    0x48(%eax),%ebx
f0104422:	eb 45                	jmp    f0104469 <syscall+0x465>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
f0104424:	8b 45 10             	mov    0x10(%ebp),%eax
f0104427:	83 e8 02             	sub    $0x2,%eax
f010442a:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f010442f:	75 28                	jne    f0104459 <syscall+0x455>
		return -E_INVAL;
	struct Env *e;
	int r=envid2env(envid,&e,1);
f0104431:	83 ec 04             	sub    $0x4,%esp
f0104434:	6a 01                	push   $0x1
f0104436:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104439:	50                   	push   %eax
f010443a:	ff 75 0c             	pushl  0xc(%ebp)
f010443d:	e8 03 e9 ff ff       	call   f0102d45 <envid2env>
	if(r<0)	
f0104442:	83 c4 10             	add    $0x10,%esp
f0104445:	85 c0                	test   %eax,%eax
f0104447:	78 17                	js     f0104460 <syscall+0x45c>
		return r;
	e->env_status=status;
f0104449:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010444c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010444f:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f0104452:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104457:	eb 10                	jmp    f0104469 <syscall+0x465>
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
		return -E_INVAL;
f0104459:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010445e:	eb 09                	jmp    f0104469 <syscall+0x465>
	struct Env *e;
	int r=envid2env(envid,&e,1);
	if(r<0)	
		return r;
f0104460:	89 c3                	mov    %eax,%ebx
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
f0104462:	eb 05                	jmp    f0104469 <syscall+0x465>
		default:
			return -E_INVAL;
f0104464:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
	}
	return 0;
}
f0104469:	89 d8                	mov    %ebx,%eax
f010446b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010446e:	5b                   	pop    %ebx
f010446f:	5e                   	pop    %esi
f0104470:	5f                   	pop    %edi
f0104471:	5d                   	pop    %ebp
f0104472:	c3                   	ret    

f0104473 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104473:	55                   	push   %ebp
f0104474:	89 e5                	mov    %esp,%ebp
f0104476:	57                   	push   %edi
f0104477:	56                   	push   %esi
f0104478:	53                   	push   %ebx
f0104479:	83 ec 14             	sub    $0x14,%esp
f010447c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010447f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104482:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104485:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104488:	8b 1a                	mov    (%edx),%ebx
f010448a:	8b 01                	mov    (%ecx),%eax
f010448c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010448f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104496:	eb 7f                	jmp    f0104517 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104498:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010449b:	01 d8                	add    %ebx,%eax
f010449d:	89 c6                	mov    %eax,%esi
f010449f:	c1 ee 1f             	shr    $0x1f,%esi
f01044a2:	01 c6                	add    %eax,%esi
f01044a4:	d1 fe                	sar    %esi
f01044a6:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01044a9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044ac:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01044af:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01044b1:	eb 03                	jmp    f01044b6 <stab_binsearch+0x43>
			m--;
f01044b3:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01044b6:	39 c3                	cmp    %eax,%ebx
f01044b8:	7f 0d                	jg     f01044c7 <stab_binsearch+0x54>
f01044ba:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01044be:	83 ea 0c             	sub    $0xc,%edx
f01044c1:	39 f9                	cmp    %edi,%ecx
f01044c3:	75 ee                	jne    f01044b3 <stab_binsearch+0x40>
f01044c5:	eb 05                	jmp    f01044cc <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01044c7:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01044ca:	eb 4b                	jmp    f0104517 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01044cc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01044cf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044d2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01044d6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01044d9:	76 11                	jbe    f01044ec <stab_binsearch+0x79>
			*region_left = m;
f01044db:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01044de:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01044e0:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044e3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01044ea:	eb 2b                	jmp    f0104517 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01044ec:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01044ef:	73 14                	jae    f0104505 <stab_binsearch+0x92>
			*region_right = m - 1;
f01044f1:	83 e8 01             	sub    $0x1,%eax
f01044f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044f7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01044fa:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01044fc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104503:	eb 12                	jmp    f0104517 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104505:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104508:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010450a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010450e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104510:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104517:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010451a:	0f 8e 78 ff ff ff    	jle    f0104498 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104520:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104524:	75 0f                	jne    f0104535 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104526:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104529:	8b 00                	mov    (%eax),%eax
f010452b:	83 e8 01             	sub    $0x1,%eax
f010452e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104531:	89 06                	mov    %eax,(%esi)
f0104533:	eb 2c                	jmp    f0104561 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104535:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104538:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010453a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010453d:	8b 0e                	mov    (%esi),%ecx
f010453f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104542:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104545:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104548:	eb 03                	jmp    f010454d <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010454a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010454d:	39 c8                	cmp    %ecx,%eax
f010454f:	7e 0b                	jle    f010455c <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104551:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104555:	83 ea 0c             	sub    $0xc,%edx
f0104558:	39 df                	cmp    %ebx,%edi
f010455a:	75 ee                	jne    f010454a <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010455c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010455f:	89 06                	mov    %eax,(%esi)
	}
}
f0104561:	83 c4 14             	add    $0x14,%esp
f0104564:	5b                   	pop    %ebx
f0104565:	5e                   	pop    %esi
f0104566:	5f                   	pop    %edi
f0104567:	5d                   	pop    %ebp
f0104568:	c3                   	ret    

f0104569 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104569:	55                   	push   %ebp
f010456a:	89 e5                	mov    %esp,%ebp
f010456c:	57                   	push   %edi
f010456d:	56                   	push   %esi
f010456e:	53                   	push   %ebx
f010456f:	83 ec 2c             	sub    $0x2c,%esp
f0104572:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104575:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104578:	c7 06 8c 73 10 f0    	movl   $0xf010738c,(%esi)
	info->eip_line = 0;
f010457e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104585:	c7 46 08 8c 73 10 f0 	movl   $0xf010738c,0x8(%esi)
	info->eip_fn_namelen = 9;
f010458c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104593:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104596:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010459d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01045a3:	0f 87 a3 00 00 00    	ja     f010464c <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
f01045a9:	e8 71 10 00 00       	call   f010561f <cpunum>
f01045ae:	6a 00                	push   $0x0
f01045b0:	6a 10                	push   $0x10
f01045b2:	68 00 00 20 00       	push   $0x200000
f01045b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ba:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01045c0:	e8 2b e6 ff ff       	call   f0102bf0 <user_mem_check>
f01045c5:	83 c4 10             	add    $0x10,%esp
f01045c8:	85 c0                	test   %eax,%eax
f01045ca:	0f 88 d4 01 00 00    	js     f01047a4 <debuginfo_eip+0x23b>
			return -1;
		stabs = usd->stabs;
f01045d0:	a1 00 00 20 00       	mov    0x200000,%eax
f01045d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01045d8:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01045de:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01045e4:	89 55 cc             	mov    %edx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01045e7:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01045ec:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
f01045ef:	e8 2b 10 00 00       	call   f010561f <cpunum>
f01045f4:	6a 00                	push   $0x0
f01045f6:	89 da                	mov    %ebx,%edx
f01045f8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01045fb:	29 ca                	sub    %ecx,%edx
f01045fd:	c1 fa 02             	sar    $0x2,%edx
f0104600:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104606:	52                   	push   %edx
f0104607:	51                   	push   %ecx
f0104608:	6b c0 74             	imul   $0x74,%eax,%eax
f010460b:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104611:	e8 da e5 ff ff       	call   f0102bf0 <user_mem_check>
f0104616:	83 c4 10             	add    $0x10,%esp
f0104619:	85 c0                	test   %eax,%eax
f010461b:	0f 88 8a 01 00 00    	js     f01047ab <debuginfo_eip+0x242>
f0104621:	e8 f9 0f 00 00       	call   f010561f <cpunum>
f0104626:	6a 00                	push   $0x0
f0104628:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010462b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010462e:	29 ca                	sub    %ecx,%edx
f0104630:	52                   	push   %edx
f0104631:	51                   	push   %ecx
f0104632:	6b c0 74             	imul   $0x74,%eax,%eax
f0104635:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010463b:	e8 b0 e5 ff ff       	call   f0102bf0 <user_mem_check>
f0104640:	83 c4 10             	add    $0x10,%esp
f0104643:	85 c0                	test   %eax,%eax
f0104645:	79 1f                	jns    f0104666 <debuginfo_eip+0xfd>
f0104647:	e9 66 01 00 00       	jmp    f01047b2 <debuginfo_eip+0x249>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010464c:	c7 45 d0 44 4a 11 f0 	movl   $0xf0114a44,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104653:	c7 45 cc 3d 14 11 f0 	movl   $0xf011143d,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010465a:	bb 3c 14 11 f0       	mov    $0xf011143c,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010465f:	c7 45 d4 78 78 10 f0 	movl   $0xf0107878,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104666:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104669:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010466c:	0f 83 47 01 00 00    	jae    f01047b9 <debuginfo_eip+0x250>
f0104672:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104676:	0f 85 44 01 00 00    	jne    f01047c0 <debuginfo_eip+0x257>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010467c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104683:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0104686:	c1 fb 02             	sar    $0x2,%ebx
f0104689:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f010468f:	83 e8 01             	sub    $0x1,%eax
f0104692:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104695:	83 ec 08             	sub    $0x8,%esp
f0104698:	57                   	push   %edi
f0104699:	6a 64                	push   $0x64
f010469b:	8d 55 e0             	lea    -0x20(%ebp),%edx
f010469e:	89 d1                	mov    %edx,%ecx
f01046a0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01046a6:	89 d8                	mov    %ebx,%eax
f01046a8:	e8 c6 fd ff ff       	call   f0104473 <stab_binsearch>
	if (lfile == 0)
f01046ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046b0:	83 c4 10             	add    $0x10,%esp
f01046b3:	85 c0                	test   %eax,%eax
f01046b5:	0f 84 0c 01 00 00    	je     f01047c7 <debuginfo_eip+0x25e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01046bb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01046be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046c1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01046c4:	83 ec 08             	sub    $0x8,%esp
f01046c7:	57                   	push   %edi
f01046c8:	6a 24                	push   $0x24
f01046ca:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01046cd:	89 d1                	mov    %edx,%ecx
f01046cf:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01046d2:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01046d5:	89 d8                	mov    %ebx,%eax
f01046d7:	e8 97 fd ff ff       	call   f0104473 <stab_binsearch>

	if (lfun <= rfun) {
f01046dc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01046df:	83 c4 10             	add    $0x10,%esp
f01046e2:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01046e5:	7f 24                	jg     f010470b <debuginfo_eip+0x1a2>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01046e7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01046ea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01046ed:	8d 14 87             	lea    (%edi,%eax,4),%edx
f01046f0:	8b 02                	mov    (%edx),%eax
f01046f2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01046f5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01046f8:	29 f9                	sub    %edi,%ecx
f01046fa:	39 c8                	cmp    %ecx,%eax
f01046fc:	73 05                	jae    f0104703 <debuginfo_eip+0x19a>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01046fe:	01 f8                	add    %edi,%eax
f0104700:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104703:	8b 42 08             	mov    0x8(%edx),%eax
f0104706:	89 46 10             	mov    %eax,0x10(%esi)
f0104709:	eb 06                	jmp    f0104711 <debuginfo_eip+0x1a8>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010470b:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010470e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104711:	83 ec 08             	sub    $0x8,%esp
f0104714:	6a 3a                	push   $0x3a
f0104716:	ff 76 08             	pushl  0x8(%esi)
f0104719:	e8 af 08 00 00       	call   f0104fcd <strfind>
f010471e:	2b 46 08             	sub    0x8(%esi),%eax
f0104721:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104724:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104727:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010472a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010472d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104730:	83 c4 10             	add    $0x10,%esp
f0104733:	eb 06                	jmp    f010473b <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104735:	83 eb 01             	sub    $0x1,%ebx
f0104738:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010473b:	39 fb                	cmp    %edi,%ebx
f010473d:	7c 2d                	jl     f010476c <debuginfo_eip+0x203>
	       && stabs[lline].n_type != N_SOL
f010473f:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104743:	80 fa 84             	cmp    $0x84,%dl
f0104746:	74 0b                	je     f0104753 <debuginfo_eip+0x1ea>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104748:	80 fa 64             	cmp    $0x64,%dl
f010474b:	75 e8                	jne    f0104735 <debuginfo_eip+0x1cc>
f010474d:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104751:	74 e2                	je     f0104735 <debuginfo_eip+0x1cc>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104753:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104756:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104759:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010475c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010475f:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104762:	29 f8                	sub    %edi,%eax
f0104764:	39 c2                	cmp    %eax,%edx
f0104766:	73 04                	jae    f010476c <debuginfo_eip+0x203>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104768:	01 fa                	add    %edi,%edx
f010476a:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010476c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010476f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104772:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104777:	39 cb                	cmp    %ecx,%ebx
f0104779:	7d 58                	jge    f01047d3 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
f010477b:	8d 53 01             	lea    0x1(%ebx),%edx
f010477e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104781:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104784:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104787:	eb 07                	jmp    f0104790 <debuginfo_eip+0x227>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104789:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010478d:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104790:	39 ca                	cmp    %ecx,%edx
f0104792:	74 3a                	je     f01047ce <debuginfo_eip+0x265>
f0104794:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104797:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f010479b:	74 ec                	je     f0104789 <debuginfo_eip+0x220>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010479d:	b8 00 00 00 00       	mov    $0x0,%eax
f01047a2:	eb 2f                	jmp    f01047d3 <debuginfo_eip+0x26a>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
			return -1;
f01047a4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047a9:	eb 28                	jmp    f01047d3 <debuginfo_eip+0x26a>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
		{
			return -1;
f01047ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047b0:	eb 21                	jmp    f01047d3 <debuginfo_eip+0x26a>
f01047b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047b7:	eb 1a                	jmp    f01047d3 <debuginfo_eip+0x26a>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01047b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047be:	eb 13                	jmp    f01047d3 <debuginfo_eip+0x26a>
f01047c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047c5:	eb 0c                	jmp    f01047d3 <debuginfo_eip+0x26a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01047c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047cc:	eb 05                	jmp    f01047d3 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01047ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01047d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047d6:	5b                   	pop    %ebx
f01047d7:	5e                   	pop    %esi
f01047d8:	5f                   	pop    %edi
f01047d9:	5d                   	pop    %ebp
f01047da:	c3                   	ret    

f01047db <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01047db:	55                   	push   %ebp
f01047dc:	89 e5                	mov    %esp,%ebp
f01047de:	57                   	push   %edi
f01047df:	56                   	push   %esi
f01047e0:	53                   	push   %ebx
f01047e1:	83 ec 1c             	sub    $0x1c,%esp
f01047e4:	89 c7                	mov    %eax,%edi
f01047e6:	89 d6                	mov    %edx,%esi
f01047e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01047eb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01047f1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01047f4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01047f7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01047fc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01047ff:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104802:	39 d3                	cmp    %edx,%ebx
f0104804:	72 05                	jb     f010480b <printnum+0x30>
f0104806:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104809:	77 45                	ja     f0104850 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010480b:	83 ec 0c             	sub    $0xc,%esp
f010480e:	ff 75 18             	pushl  0x18(%ebp)
f0104811:	8b 45 14             	mov    0x14(%ebp),%eax
f0104814:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104817:	53                   	push   %ebx
f0104818:	ff 75 10             	pushl  0x10(%ebp)
f010481b:	83 ec 08             	sub    $0x8,%esp
f010481e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104821:	ff 75 e0             	pushl  -0x20(%ebp)
f0104824:	ff 75 dc             	pushl  -0x24(%ebp)
f0104827:	ff 75 d8             	pushl  -0x28(%ebp)
f010482a:	e8 f1 11 00 00       	call   f0105a20 <__udivdi3>
f010482f:	83 c4 18             	add    $0x18,%esp
f0104832:	52                   	push   %edx
f0104833:	50                   	push   %eax
f0104834:	89 f2                	mov    %esi,%edx
f0104836:	89 f8                	mov    %edi,%eax
f0104838:	e8 9e ff ff ff       	call   f01047db <printnum>
f010483d:	83 c4 20             	add    $0x20,%esp
f0104840:	eb 18                	jmp    f010485a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104842:	83 ec 08             	sub    $0x8,%esp
f0104845:	56                   	push   %esi
f0104846:	ff 75 18             	pushl  0x18(%ebp)
f0104849:	ff d7                	call   *%edi
f010484b:	83 c4 10             	add    $0x10,%esp
f010484e:	eb 03                	jmp    f0104853 <printnum+0x78>
f0104850:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104853:	83 eb 01             	sub    $0x1,%ebx
f0104856:	85 db                	test   %ebx,%ebx
f0104858:	7f e8                	jg     f0104842 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010485a:	83 ec 08             	sub    $0x8,%esp
f010485d:	56                   	push   %esi
f010485e:	83 ec 04             	sub    $0x4,%esp
f0104861:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104864:	ff 75 e0             	pushl  -0x20(%ebp)
f0104867:	ff 75 dc             	pushl  -0x24(%ebp)
f010486a:	ff 75 d8             	pushl  -0x28(%ebp)
f010486d:	e8 de 12 00 00       	call   f0105b50 <__umoddi3>
f0104872:	83 c4 14             	add    $0x14,%esp
f0104875:	0f be 80 96 73 10 f0 	movsbl -0xfef8c6a(%eax),%eax
f010487c:	50                   	push   %eax
f010487d:	ff d7                	call   *%edi
}
f010487f:	83 c4 10             	add    $0x10,%esp
f0104882:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104885:	5b                   	pop    %ebx
f0104886:	5e                   	pop    %esi
f0104887:	5f                   	pop    %edi
f0104888:	5d                   	pop    %ebp
f0104889:	c3                   	ret    

f010488a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010488a:	55                   	push   %ebp
f010488b:	89 e5                	mov    %esp,%ebp
f010488d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104890:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104894:	8b 10                	mov    (%eax),%edx
f0104896:	3b 50 04             	cmp    0x4(%eax),%edx
f0104899:	73 0a                	jae    f01048a5 <sprintputch+0x1b>
		*b->buf++ = ch;
f010489b:	8d 4a 01             	lea    0x1(%edx),%ecx
f010489e:	89 08                	mov    %ecx,(%eax)
f01048a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01048a3:	88 02                	mov    %al,(%edx)
}
f01048a5:	5d                   	pop    %ebp
f01048a6:	c3                   	ret    

f01048a7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01048a7:	55                   	push   %ebp
f01048a8:	89 e5                	mov    %esp,%ebp
f01048aa:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01048ad:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01048b0:	50                   	push   %eax
f01048b1:	ff 75 10             	pushl  0x10(%ebp)
f01048b4:	ff 75 0c             	pushl  0xc(%ebp)
f01048b7:	ff 75 08             	pushl  0x8(%ebp)
f01048ba:	e8 05 00 00 00       	call   f01048c4 <vprintfmt>
	va_end(ap);
}
f01048bf:	83 c4 10             	add    $0x10,%esp
f01048c2:	c9                   	leave  
f01048c3:	c3                   	ret    

f01048c4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01048c4:	55                   	push   %ebp
f01048c5:	89 e5                	mov    %esp,%ebp
f01048c7:	57                   	push   %edi
f01048c8:	56                   	push   %esi
f01048c9:	53                   	push   %ebx
f01048ca:	83 ec 2c             	sub    $0x2c,%esp
f01048cd:	8b 75 08             	mov    0x8(%ebp),%esi
f01048d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048d3:	8b 7d 10             	mov    0x10(%ebp),%edi
f01048d6:	eb 12                	jmp    f01048ea <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01048d8:	85 c0                	test   %eax,%eax
f01048da:	0f 84 42 04 00 00    	je     f0104d22 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f01048e0:	83 ec 08             	sub    $0x8,%esp
f01048e3:	53                   	push   %ebx
f01048e4:	50                   	push   %eax
f01048e5:	ff d6                	call   *%esi
f01048e7:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01048ea:	83 c7 01             	add    $0x1,%edi
f01048ed:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01048f1:	83 f8 25             	cmp    $0x25,%eax
f01048f4:	75 e2                	jne    f01048d8 <vprintfmt+0x14>
f01048f6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01048fa:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104901:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104908:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010490f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104914:	eb 07                	jmp    f010491d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104916:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104919:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010491d:	8d 47 01             	lea    0x1(%edi),%eax
f0104920:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104923:	0f b6 07             	movzbl (%edi),%eax
f0104926:	0f b6 d0             	movzbl %al,%edx
f0104929:	83 e8 23             	sub    $0x23,%eax
f010492c:	3c 55                	cmp    $0x55,%al
f010492e:	0f 87 d3 03 00 00    	ja     f0104d07 <vprintfmt+0x443>
f0104934:	0f b6 c0             	movzbl %al,%eax
f0104937:	ff 24 85 60 74 10 f0 	jmp    *-0xfef8ba0(,%eax,4)
f010493e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104941:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104945:	eb d6                	jmp    f010491d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104947:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010494a:	b8 00 00 00 00       	mov    $0x0,%eax
f010494f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104952:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104955:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104959:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010495c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010495f:	83 f9 09             	cmp    $0x9,%ecx
f0104962:	77 3f                	ja     f01049a3 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104964:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104967:	eb e9                	jmp    f0104952 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104969:	8b 45 14             	mov    0x14(%ebp),%eax
f010496c:	8b 00                	mov    (%eax),%eax
f010496e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104971:	8b 45 14             	mov    0x14(%ebp),%eax
f0104974:	8d 40 04             	lea    0x4(%eax),%eax
f0104977:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010497a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010497d:	eb 2a                	jmp    f01049a9 <vprintfmt+0xe5>
f010497f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104982:	85 c0                	test   %eax,%eax
f0104984:	ba 00 00 00 00       	mov    $0x0,%edx
f0104989:	0f 49 d0             	cmovns %eax,%edx
f010498c:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010498f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104992:	eb 89                	jmp    f010491d <vprintfmt+0x59>
f0104994:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104997:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010499e:	e9 7a ff ff ff       	jmp    f010491d <vprintfmt+0x59>
f01049a3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01049a6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01049a9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01049ad:	0f 89 6a ff ff ff    	jns    f010491d <vprintfmt+0x59>
				width = precision, precision = -1;
f01049b3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01049b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01049b9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01049c0:	e9 58 ff ff ff       	jmp    f010491d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01049c5:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01049cb:	e9 4d ff ff ff       	jmp    f010491d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01049d0:	8b 45 14             	mov    0x14(%ebp),%eax
f01049d3:	8d 78 04             	lea    0x4(%eax),%edi
f01049d6:	83 ec 08             	sub    $0x8,%esp
f01049d9:	53                   	push   %ebx
f01049da:	ff 30                	pushl  (%eax)
f01049dc:	ff d6                	call   *%esi
			break;
f01049de:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01049e1:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01049e7:	e9 fe fe ff ff       	jmp    f01048ea <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01049ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01049ef:	8d 78 04             	lea    0x4(%eax),%edi
f01049f2:	8b 00                	mov    (%eax),%eax
f01049f4:	99                   	cltd   
f01049f5:	31 d0                	xor    %edx,%eax
f01049f7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01049f9:	83 f8 08             	cmp    $0x8,%eax
f01049fc:	7f 0b                	jg     f0104a09 <vprintfmt+0x145>
f01049fe:	8b 14 85 c0 75 10 f0 	mov    -0xfef8a40(,%eax,4),%edx
f0104a05:	85 d2                	test   %edx,%edx
f0104a07:	75 1b                	jne    f0104a24 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0104a09:	50                   	push   %eax
f0104a0a:	68 ae 73 10 f0       	push   $0xf01073ae
f0104a0f:	53                   	push   %ebx
f0104a10:	56                   	push   %esi
f0104a11:	e8 91 fe ff ff       	call   f01048a7 <printfmt>
f0104a16:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104a19:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104a1f:	e9 c6 fe ff ff       	jmp    f01048ea <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104a24:	52                   	push   %edx
f0104a25:	68 81 6b 10 f0       	push   $0xf0106b81
f0104a2a:	53                   	push   %ebx
f0104a2b:	56                   	push   %esi
f0104a2c:	e8 76 fe ff ff       	call   f01048a7 <printfmt>
f0104a31:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104a34:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a3a:	e9 ab fe ff ff       	jmp    f01048ea <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104a3f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a42:	83 c0 04             	add    $0x4,%eax
f0104a45:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104a48:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a4b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104a4d:	85 ff                	test   %edi,%edi
f0104a4f:	b8 a7 73 10 f0       	mov    $0xf01073a7,%eax
f0104a54:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104a57:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104a5b:	0f 8e 94 00 00 00    	jle    f0104af5 <vprintfmt+0x231>
f0104a61:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104a65:	0f 84 98 00 00 00    	je     f0104b03 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104a6b:	83 ec 08             	sub    $0x8,%esp
f0104a6e:	ff 75 d0             	pushl  -0x30(%ebp)
f0104a71:	57                   	push   %edi
f0104a72:	e8 0c 04 00 00       	call   f0104e83 <strnlen>
f0104a77:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104a7a:	29 c1                	sub    %eax,%ecx
f0104a7c:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104a7f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104a82:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104a86:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104a89:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104a8c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104a8e:	eb 0f                	jmp    f0104a9f <vprintfmt+0x1db>
					putch(padc, putdat);
f0104a90:	83 ec 08             	sub    $0x8,%esp
f0104a93:	53                   	push   %ebx
f0104a94:	ff 75 e0             	pushl  -0x20(%ebp)
f0104a97:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104a99:	83 ef 01             	sub    $0x1,%edi
f0104a9c:	83 c4 10             	add    $0x10,%esp
f0104a9f:	85 ff                	test   %edi,%edi
f0104aa1:	7f ed                	jg     f0104a90 <vprintfmt+0x1cc>
f0104aa3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104aa6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104aa9:	85 c9                	test   %ecx,%ecx
f0104aab:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ab0:	0f 49 c1             	cmovns %ecx,%eax
f0104ab3:	29 c1                	sub    %eax,%ecx
f0104ab5:	89 75 08             	mov    %esi,0x8(%ebp)
f0104ab8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104abb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104abe:	89 cb                	mov    %ecx,%ebx
f0104ac0:	eb 4d                	jmp    f0104b0f <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104ac2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104ac6:	74 1b                	je     f0104ae3 <vprintfmt+0x21f>
f0104ac8:	0f be c0             	movsbl %al,%eax
f0104acb:	83 e8 20             	sub    $0x20,%eax
f0104ace:	83 f8 5e             	cmp    $0x5e,%eax
f0104ad1:	76 10                	jbe    f0104ae3 <vprintfmt+0x21f>
					putch('?', putdat);
f0104ad3:	83 ec 08             	sub    $0x8,%esp
f0104ad6:	ff 75 0c             	pushl  0xc(%ebp)
f0104ad9:	6a 3f                	push   $0x3f
f0104adb:	ff 55 08             	call   *0x8(%ebp)
f0104ade:	83 c4 10             	add    $0x10,%esp
f0104ae1:	eb 0d                	jmp    f0104af0 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0104ae3:	83 ec 08             	sub    $0x8,%esp
f0104ae6:	ff 75 0c             	pushl  0xc(%ebp)
f0104ae9:	52                   	push   %edx
f0104aea:	ff 55 08             	call   *0x8(%ebp)
f0104aed:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104af0:	83 eb 01             	sub    $0x1,%ebx
f0104af3:	eb 1a                	jmp    f0104b0f <vprintfmt+0x24b>
f0104af5:	89 75 08             	mov    %esi,0x8(%ebp)
f0104af8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104afb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104afe:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104b01:	eb 0c                	jmp    f0104b0f <vprintfmt+0x24b>
f0104b03:	89 75 08             	mov    %esi,0x8(%ebp)
f0104b06:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104b09:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b0c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104b0f:	83 c7 01             	add    $0x1,%edi
f0104b12:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104b16:	0f be d0             	movsbl %al,%edx
f0104b19:	85 d2                	test   %edx,%edx
f0104b1b:	74 23                	je     f0104b40 <vprintfmt+0x27c>
f0104b1d:	85 f6                	test   %esi,%esi
f0104b1f:	78 a1                	js     f0104ac2 <vprintfmt+0x1fe>
f0104b21:	83 ee 01             	sub    $0x1,%esi
f0104b24:	79 9c                	jns    f0104ac2 <vprintfmt+0x1fe>
f0104b26:	89 df                	mov    %ebx,%edi
f0104b28:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b2b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b2e:	eb 18                	jmp    f0104b48 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104b30:	83 ec 08             	sub    $0x8,%esp
f0104b33:	53                   	push   %ebx
f0104b34:	6a 20                	push   $0x20
f0104b36:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104b38:	83 ef 01             	sub    $0x1,%edi
f0104b3b:	83 c4 10             	add    $0x10,%esp
f0104b3e:	eb 08                	jmp    f0104b48 <vprintfmt+0x284>
f0104b40:	89 df                	mov    %ebx,%edi
f0104b42:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b45:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b48:	85 ff                	test   %edi,%edi
f0104b4a:	7f e4                	jg     f0104b30 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104b4c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104b4f:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b55:	e9 90 fd ff ff       	jmp    f01048ea <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104b5a:	83 f9 01             	cmp    $0x1,%ecx
f0104b5d:	7e 19                	jle    f0104b78 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0104b5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b62:	8b 50 04             	mov    0x4(%eax),%edx
f0104b65:	8b 00                	mov    (%eax),%eax
f0104b67:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b6a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104b6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b70:	8d 40 08             	lea    0x8(%eax),%eax
f0104b73:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b76:	eb 38                	jmp    f0104bb0 <vprintfmt+0x2ec>
	else if (lflag)
f0104b78:	85 c9                	test   %ecx,%ecx
f0104b7a:	74 1b                	je     f0104b97 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0104b7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b7f:	8b 00                	mov    (%eax),%eax
f0104b81:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b84:	89 c1                	mov    %eax,%ecx
f0104b86:	c1 f9 1f             	sar    $0x1f,%ecx
f0104b89:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104b8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b8f:	8d 40 04             	lea    0x4(%eax),%eax
f0104b92:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b95:	eb 19                	jmp    f0104bb0 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0104b97:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b9a:	8b 00                	mov    (%eax),%eax
f0104b9c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b9f:	89 c1                	mov    %eax,%ecx
f0104ba1:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ba4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104ba7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104baa:	8d 40 04             	lea    0x4(%eax),%eax
f0104bad:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104bb0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104bb3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104bb6:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104bbb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104bbf:	0f 89 0e 01 00 00    	jns    f0104cd3 <vprintfmt+0x40f>
				putch('-', putdat);
f0104bc5:	83 ec 08             	sub    $0x8,%esp
f0104bc8:	53                   	push   %ebx
f0104bc9:	6a 2d                	push   $0x2d
f0104bcb:	ff d6                	call   *%esi
				num = -(long long) num;
f0104bcd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104bd0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104bd3:	f7 da                	neg    %edx
f0104bd5:	83 d1 00             	adc    $0x0,%ecx
f0104bd8:	f7 d9                	neg    %ecx
f0104bda:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104bdd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104be2:	e9 ec 00 00 00       	jmp    f0104cd3 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104be7:	83 f9 01             	cmp    $0x1,%ecx
f0104bea:	7e 18                	jle    f0104c04 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0104bec:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bef:	8b 10                	mov    (%eax),%edx
f0104bf1:	8b 48 04             	mov    0x4(%eax),%ecx
f0104bf4:	8d 40 08             	lea    0x8(%eax),%eax
f0104bf7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104bfa:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104bff:	e9 cf 00 00 00       	jmp    f0104cd3 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104c04:	85 c9                	test   %ecx,%ecx
f0104c06:	74 1a                	je     f0104c22 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0104c08:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c0b:	8b 10                	mov    (%eax),%edx
f0104c0d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c12:	8d 40 04             	lea    0x4(%eax),%eax
f0104c15:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104c18:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c1d:	e9 b1 00 00 00       	jmp    f0104cd3 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104c22:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c25:	8b 10                	mov    (%eax),%edx
f0104c27:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c2c:	8d 40 04             	lea    0x4(%eax),%eax
f0104c2f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104c32:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c37:	e9 97 00 00 00       	jmp    f0104cd3 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0104c3c:	83 ec 08             	sub    $0x8,%esp
f0104c3f:	53                   	push   %ebx
f0104c40:	6a 58                	push   $0x58
f0104c42:	ff d6                	call   *%esi
			putch('X', putdat);
f0104c44:	83 c4 08             	add    $0x8,%esp
f0104c47:	53                   	push   %ebx
f0104c48:	6a 58                	push   $0x58
f0104c4a:	ff d6                	call   *%esi
			putch('X', putdat);
f0104c4c:	83 c4 08             	add    $0x8,%esp
f0104c4f:	53                   	push   %ebx
f0104c50:	6a 58                	push   $0x58
f0104c52:	ff d6                	call   *%esi
			break;
f0104c54:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0104c5a:	e9 8b fc ff ff       	jmp    f01048ea <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0104c5f:	83 ec 08             	sub    $0x8,%esp
f0104c62:	53                   	push   %ebx
f0104c63:	6a 30                	push   $0x30
f0104c65:	ff d6                	call   *%esi
			putch('x', putdat);
f0104c67:	83 c4 08             	add    $0x8,%esp
f0104c6a:	53                   	push   %ebx
f0104c6b:	6a 78                	push   $0x78
f0104c6d:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104c6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c72:	8b 10                	mov    (%eax),%edx
f0104c74:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104c79:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104c7c:	8d 40 04             	lea    0x4(%eax),%eax
f0104c7f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104c82:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104c87:	eb 4a                	jmp    f0104cd3 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104c89:	83 f9 01             	cmp    $0x1,%ecx
f0104c8c:	7e 15                	jle    f0104ca3 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0104c8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c91:	8b 10                	mov    (%eax),%edx
f0104c93:	8b 48 04             	mov    0x4(%eax),%ecx
f0104c96:	8d 40 08             	lea    0x8(%eax),%eax
f0104c99:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104c9c:	b8 10 00 00 00       	mov    $0x10,%eax
f0104ca1:	eb 30                	jmp    f0104cd3 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104ca3:	85 c9                	test   %ecx,%ecx
f0104ca5:	74 17                	je     f0104cbe <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0104ca7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104caa:	8b 10                	mov    (%eax),%edx
f0104cac:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104cb1:	8d 40 04             	lea    0x4(%eax),%eax
f0104cb4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104cb7:	b8 10 00 00 00       	mov    $0x10,%eax
f0104cbc:	eb 15                	jmp    f0104cd3 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104cbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc1:	8b 10                	mov    (%eax),%edx
f0104cc3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104cc8:	8d 40 04             	lea    0x4(%eax),%eax
f0104ccb:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104cce:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104cd3:	83 ec 0c             	sub    $0xc,%esp
f0104cd6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104cda:	57                   	push   %edi
f0104cdb:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cde:	50                   	push   %eax
f0104cdf:	51                   	push   %ecx
f0104ce0:	52                   	push   %edx
f0104ce1:	89 da                	mov    %ebx,%edx
f0104ce3:	89 f0                	mov    %esi,%eax
f0104ce5:	e8 f1 fa ff ff       	call   f01047db <printnum>
			break;
f0104cea:	83 c4 20             	add    $0x20,%esp
f0104ced:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104cf0:	e9 f5 fb ff ff       	jmp    f01048ea <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104cf5:	83 ec 08             	sub    $0x8,%esp
f0104cf8:	53                   	push   %ebx
f0104cf9:	52                   	push   %edx
f0104cfa:	ff d6                	call   *%esi
			break;
f0104cfc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104d02:	e9 e3 fb ff ff       	jmp    f01048ea <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104d07:	83 ec 08             	sub    $0x8,%esp
f0104d0a:	53                   	push   %ebx
f0104d0b:	6a 25                	push   $0x25
f0104d0d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104d0f:	83 c4 10             	add    $0x10,%esp
f0104d12:	eb 03                	jmp    f0104d17 <vprintfmt+0x453>
f0104d14:	83 ef 01             	sub    $0x1,%edi
f0104d17:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104d1b:	75 f7                	jne    f0104d14 <vprintfmt+0x450>
f0104d1d:	e9 c8 fb ff ff       	jmp    f01048ea <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104d22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d25:	5b                   	pop    %ebx
f0104d26:	5e                   	pop    %esi
f0104d27:	5f                   	pop    %edi
f0104d28:	5d                   	pop    %ebp
f0104d29:	c3                   	ret    

f0104d2a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104d2a:	55                   	push   %ebp
f0104d2b:	89 e5                	mov    %esp,%ebp
f0104d2d:	83 ec 18             	sub    $0x18,%esp
f0104d30:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d33:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104d36:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104d39:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104d3d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104d40:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104d47:	85 c0                	test   %eax,%eax
f0104d49:	74 26                	je     f0104d71 <vsnprintf+0x47>
f0104d4b:	85 d2                	test   %edx,%edx
f0104d4d:	7e 22                	jle    f0104d71 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104d4f:	ff 75 14             	pushl  0x14(%ebp)
f0104d52:	ff 75 10             	pushl  0x10(%ebp)
f0104d55:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104d58:	50                   	push   %eax
f0104d59:	68 8a 48 10 f0       	push   $0xf010488a
f0104d5e:	e8 61 fb ff ff       	call   f01048c4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104d63:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104d66:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104d69:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104d6c:	83 c4 10             	add    $0x10,%esp
f0104d6f:	eb 05                	jmp    f0104d76 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104d71:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104d76:	c9                   	leave  
f0104d77:	c3                   	ret    

f0104d78 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104d78:	55                   	push   %ebp
f0104d79:	89 e5                	mov    %esp,%ebp
f0104d7b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104d7e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104d81:	50                   	push   %eax
f0104d82:	ff 75 10             	pushl  0x10(%ebp)
f0104d85:	ff 75 0c             	pushl  0xc(%ebp)
f0104d88:	ff 75 08             	pushl  0x8(%ebp)
f0104d8b:	e8 9a ff ff ff       	call   f0104d2a <vsnprintf>
	va_end(ap);

	return rc;
}
f0104d90:	c9                   	leave  
f0104d91:	c3                   	ret    

f0104d92 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104d92:	55                   	push   %ebp
f0104d93:	89 e5                	mov    %esp,%ebp
f0104d95:	57                   	push   %edi
f0104d96:	56                   	push   %esi
f0104d97:	53                   	push   %ebx
f0104d98:	83 ec 0c             	sub    $0xc,%esp
f0104d9b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104d9e:	85 c0                	test   %eax,%eax
f0104da0:	74 11                	je     f0104db3 <readline+0x21>
		cprintf("%s", prompt);
f0104da2:	83 ec 08             	sub    $0x8,%esp
f0104da5:	50                   	push   %eax
f0104da6:	68 81 6b 10 f0       	push   $0xf0106b81
f0104dab:	e8 0d e8 ff ff       	call   f01035bd <cprintf>
f0104db0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104db3:	83 ec 0c             	sub    $0xc,%esp
f0104db6:	6a 00                	push   $0x0
f0104db8:	e8 c8 b9 ff ff       	call   f0100785 <iscons>
f0104dbd:	89 c7                	mov    %eax,%edi
f0104dbf:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104dc2:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104dc7:	e8 a8 b9 ff ff       	call   f0100774 <getchar>
f0104dcc:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104dce:	85 c0                	test   %eax,%eax
f0104dd0:	79 18                	jns    f0104dea <readline+0x58>
			cprintf("read error: %e\n", c);
f0104dd2:	83 ec 08             	sub    $0x8,%esp
f0104dd5:	50                   	push   %eax
f0104dd6:	68 e4 75 10 f0       	push   $0xf01075e4
f0104ddb:	e8 dd e7 ff ff       	call   f01035bd <cprintf>
			return NULL;
f0104de0:	83 c4 10             	add    $0x10,%esp
f0104de3:	b8 00 00 00 00       	mov    $0x0,%eax
f0104de8:	eb 79                	jmp    f0104e63 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104dea:	83 f8 08             	cmp    $0x8,%eax
f0104ded:	0f 94 c2             	sete   %dl
f0104df0:	83 f8 7f             	cmp    $0x7f,%eax
f0104df3:	0f 94 c0             	sete   %al
f0104df6:	08 c2                	or     %al,%dl
f0104df8:	74 1a                	je     f0104e14 <readline+0x82>
f0104dfa:	85 f6                	test   %esi,%esi
f0104dfc:	7e 16                	jle    f0104e14 <readline+0x82>
			if (echoing)
f0104dfe:	85 ff                	test   %edi,%edi
f0104e00:	74 0d                	je     f0104e0f <readline+0x7d>
				cputchar('\b');
f0104e02:	83 ec 0c             	sub    $0xc,%esp
f0104e05:	6a 08                	push   $0x8
f0104e07:	e8 58 b9 ff ff       	call   f0100764 <cputchar>
f0104e0c:	83 c4 10             	add    $0x10,%esp
			i--;
f0104e0f:	83 ee 01             	sub    $0x1,%esi
f0104e12:	eb b3                	jmp    f0104dc7 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104e14:	83 fb 1f             	cmp    $0x1f,%ebx
f0104e17:	7e 23                	jle    f0104e3c <readline+0xaa>
f0104e19:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104e1f:	7f 1b                	jg     f0104e3c <readline+0xaa>
			if (echoing)
f0104e21:	85 ff                	test   %edi,%edi
f0104e23:	74 0c                	je     f0104e31 <readline+0x9f>
				cputchar(c);
f0104e25:	83 ec 0c             	sub    $0xc,%esp
f0104e28:	53                   	push   %ebx
f0104e29:	e8 36 b9 ff ff       	call   f0100764 <cputchar>
f0104e2e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104e31:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104e37:	8d 76 01             	lea    0x1(%esi),%esi
f0104e3a:	eb 8b                	jmp    f0104dc7 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104e3c:	83 fb 0a             	cmp    $0xa,%ebx
f0104e3f:	74 05                	je     f0104e46 <readline+0xb4>
f0104e41:	83 fb 0d             	cmp    $0xd,%ebx
f0104e44:	75 81                	jne    f0104dc7 <readline+0x35>
			if (echoing)
f0104e46:	85 ff                	test   %edi,%edi
f0104e48:	74 0d                	je     f0104e57 <readline+0xc5>
				cputchar('\n');
f0104e4a:	83 ec 0c             	sub    $0xc,%esp
f0104e4d:	6a 0a                	push   $0xa
f0104e4f:	e8 10 b9 ff ff       	call   f0100764 <cputchar>
f0104e54:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104e57:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104e5e:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104e63:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e66:	5b                   	pop    %ebx
f0104e67:	5e                   	pop    %esi
f0104e68:	5f                   	pop    %edi
f0104e69:	5d                   	pop    %ebp
f0104e6a:	c3                   	ret    

f0104e6b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104e6b:	55                   	push   %ebp
f0104e6c:	89 e5                	mov    %esp,%ebp
f0104e6e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e71:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e76:	eb 03                	jmp    f0104e7b <strlen+0x10>
		n++;
f0104e78:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104e7b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104e7f:	75 f7                	jne    f0104e78 <strlen+0xd>
		n++;
	return n;
}
f0104e81:	5d                   	pop    %ebp
f0104e82:	c3                   	ret    

f0104e83 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104e83:	55                   	push   %ebp
f0104e84:	89 e5                	mov    %esp,%ebp
f0104e86:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e89:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e8c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104e91:	eb 03                	jmp    f0104e96 <strnlen+0x13>
		n++;
f0104e93:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104e96:	39 c2                	cmp    %eax,%edx
f0104e98:	74 08                	je     f0104ea2 <strnlen+0x1f>
f0104e9a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104e9e:	75 f3                	jne    f0104e93 <strnlen+0x10>
f0104ea0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104ea2:	5d                   	pop    %ebp
f0104ea3:	c3                   	ret    

f0104ea4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104ea4:	55                   	push   %ebp
f0104ea5:	89 e5                	mov    %esp,%ebp
f0104ea7:	53                   	push   %ebx
f0104ea8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104eab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104eae:	89 c2                	mov    %eax,%edx
f0104eb0:	83 c2 01             	add    $0x1,%edx
f0104eb3:	83 c1 01             	add    $0x1,%ecx
f0104eb6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104eba:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104ebd:	84 db                	test   %bl,%bl
f0104ebf:	75 ef                	jne    f0104eb0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104ec1:	5b                   	pop    %ebx
f0104ec2:	5d                   	pop    %ebp
f0104ec3:	c3                   	ret    

f0104ec4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104ec4:	55                   	push   %ebp
f0104ec5:	89 e5                	mov    %esp,%ebp
f0104ec7:	53                   	push   %ebx
f0104ec8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ecb:	53                   	push   %ebx
f0104ecc:	e8 9a ff ff ff       	call   f0104e6b <strlen>
f0104ed1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104ed4:	ff 75 0c             	pushl  0xc(%ebp)
f0104ed7:	01 d8                	add    %ebx,%eax
f0104ed9:	50                   	push   %eax
f0104eda:	e8 c5 ff ff ff       	call   f0104ea4 <strcpy>
	return dst;
}
f0104edf:	89 d8                	mov    %ebx,%eax
f0104ee1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104ee4:	c9                   	leave  
f0104ee5:	c3                   	ret    

f0104ee6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104ee6:	55                   	push   %ebp
f0104ee7:	89 e5                	mov    %esp,%ebp
f0104ee9:	56                   	push   %esi
f0104eea:	53                   	push   %ebx
f0104eeb:	8b 75 08             	mov    0x8(%ebp),%esi
f0104eee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ef1:	89 f3                	mov    %esi,%ebx
f0104ef3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ef6:	89 f2                	mov    %esi,%edx
f0104ef8:	eb 0f                	jmp    f0104f09 <strncpy+0x23>
		*dst++ = *src;
f0104efa:	83 c2 01             	add    $0x1,%edx
f0104efd:	0f b6 01             	movzbl (%ecx),%eax
f0104f00:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104f03:	80 39 01             	cmpb   $0x1,(%ecx)
f0104f06:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104f09:	39 da                	cmp    %ebx,%edx
f0104f0b:	75 ed                	jne    f0104efa <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104f0d:	89 f0                	mov    %esi,%eax
f0104f0f:	5b                   	pop    %ebx
f0104f10:	5e                   	pop    %esi
f0104f11:	5d                   	pop    %ebp
f0104f12:	c3                   	ret    

f0104f13 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104f13:	55                   	push   %ebp
f0104f14:	89 e5                	mov    %esp,%ebp
f0104f16:	56                   	push   %esi
f0104f17:	53                   	push   %ebx
f0104f18:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f1b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104f1e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104f21:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104f23:	85 d2                	test   %edx,%edx
f0104f25:	74 21                	je     f0104f48 <strlcpy+0x35>
f0104f27:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104f2b:	89 f2                	mov    %esi,%edx
f0104f2d:	eb 09                	jmp    f0104f38 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104f2f:	83 c2 01             	add    $0x1,%edx
f0104f32:	83 c1 01             	add    $0x1,%ecx
f0104f35:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104f38:	39 c2                	cmp    %eax,%edx
f0104f3a:	74 09                	je     f0104f45 <strlcpy+0x32>
f0104f3c:	0f b6 19             	movzbl (%ecx),%ebx
f0104f3f:	84 db                	test   %bl,%bl
f0104f41:	75 ec                	jne    f0104f2f <strlcpy+0x1c>
f0104f43:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104f45:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104f48:	29 f0                	sub    %esi,%eax
}
f0104f4a:	5b                   	pop    %ebx
f0104f4b:	5e                   	pop    %esi
f0104f4c:	5d                   	pop    %ebp
f0104f4d:	c3                   	ret    

f0104f4e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104f4e:	55                   	push   %ebp
f0104f4f:	89 e5                	mov    %esp,%ebp
f0104f51:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f54:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104f57:	eb 06                	jmp    f0104f5f <strcmp+0x11>
		p++, q++;
f0104f59:	83 c1 01             	add    $0x1,%ecx
f0104f5c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104f5f:	0f b6 01             	movzbl (%ecx),%eax
f0104f62:	84 c0                	test   %al,%al
f0104f64:	74 04                	je     f0104f6a <strcmp+0x1c>
f0104f66:	3a 02                	cmp    (%edx),%al
f0104f68:	74 ef                	je     f0104f59 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f6a:	0f b6 c0             	movzbl %al,%eax
f0104f6d:	0f b6 12             	movzbl (%edx),%edx
f0104f70:	29 d0                	sub    %edx,%eax
}
f0104f72:	5d                   	pop    %ebp
f0104f73:	c3                   	ret    

f0104f74 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104f74:	55                   	push   %ebp
f0104f75:	89 e5                	mov    %esp,%ebp
f0104f77:	53                   	push   %ebx
f0104f78:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f7b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104f7e:	89 c3                	mov    %eax,%ebx
f0104f80:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104f83:	eb 06                	jmp    f0104f8b <strncmp+0x17>
		n--, p++, q++;
f0104f85:	83 c0 01             	add    $0x1,%eax
f0104f88:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104f8b:	39 d8                	cmp    %ebx,%eax
f0104f8d:	74 15                	je     f0104fa4 <strncmp+0x30>
f0104f8f:	0f b6 08             	movzbl (%eax),%ecx
f0104f92:	84 c9                	test   %cl,%cl
f0104f94:	74 04                	je     f0104f9a <strncmp+0x26>
f0104f96:	3a 0a                	cmp    (%edx),%cl
f0104f98:	74 eb                	je     f0104f85 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104f9a:	0f b6 00             	movzbl (%eax),%eax
f0104f9d:	0f b6 12             	movzbl (%edx),%edx
f0104fa0:	29 d0                	sub    %edx,%eax
f0104fa2:	eb 05                	jmp    f0104fa9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104fa4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104fa9:	5b                   	pop    %ebx
f0104faa:	5d                   	pop    %ebp
f0104fab:	c3                   	ret    

f0104fac <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104fac:	55                   	push   %ebp
f0104fad:	89 e5                	mov    %esp,%ebp
f0104faf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fb2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104fb6:	eb 07                	jmp    f0104fbf <strchr+0x13>
		if (*s == c)
f0104fb8:	38 ca                	cmp    %cl,%dl
f0104fba:	74 0f                	je     f0104fcb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104fbc:	83 c0 01             	add    $0x1,%eax
f0104fbf:	0f b6 10             	movzbl (%eax),%edx
f0104fc2:	84 d2                	test   %dl,%dl
f0104fc4:	75 f2                	jne    f0104fb8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104fc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104fcb:	5d                   	pop    %ebp
f0104fcc:	c3                   	ret    

f0104fcd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104fcd:	55                   	push   %ebp
f0104fce:	89 e5                	mov    %esp,%ebp
f0104fd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fd3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104fd7:	eb 03                	jmp    f0104fdc <strfind+0xf>
f0104fd9:	83 c0 01             	add    $0x1,%eax
f0104fdc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104fdf:	38 ca                	cmp    %cl,%dl
f0104fe1:	74 04                	je     f0104fe7 <strfind+0x1a>
f0104fe3:	84 d2                	test   %dl,%dl
f0104fe5:	75 f2                	jne    f0104fd9 <strfind+0xc>
			break;
	return (char *) s;
}
f0104fe7:	5d                   	pop    %ebp
f0104fe8:	c3                   	ret    

f0104fe9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104fe9:	55                   	push   %ebp
f0104fea:	89 e5                	mov    %esp,%ebp
f0104fec:	57                   	push   %edi
f0104fed:	56                   	push   %esi
f0104fee:	53                   	push   %ebx
f0104fef:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ff2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104ff5:	85 c9                	test   %ecx,%ecx
f0104ff7:	74 36                	je     f010502f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104ff9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104fff:	75 28                	jne    f0105029 <memset+0x40>
f0105001:	f6 c1 03             	test   $0x3,%cl
f0105004:	75 23                	jne    f0105029 <memset+0x40>
		c &= 0xFF;
f0105006:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010500a:	89 d3                	mov    %edx,%ebx
f010500c:	c1 e3 08             	shl    $0x8,%ebx
f010500f:	89 d6                	mov    %edx,%esi
f0105011:	c1 e6 18             	shl    $0x18,%esi
f0105014:	89 d0                	mov    %edx,%eax
f0105016:	c1 e0 10             	shl    $0x10,%eax
f0105019:	09 f0                	or     %esi,%eax
f010501b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010501d:	89 d8                	mov    %ebx,%eax
f010501f:	09 d0                	or     %edx,%eax
f0105021:	c1 e9 02             	shr    $0x2,%ecx
f0105024:	fc                   	cld    
f0105025:	f3 ab                	rep stos %eax,%es:(%edi)
f0105027:	eb 06                	jmp    f010502f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105029:	8b 45 0c             	mov    0xc(%ebp),%eax
f010502c:	fc                   	cld    
f010502d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010502f:	89 f8                	mov    %edi,%eax
f0105031:	5b                   	pop    %ebx
f0105032:	5e                   	pop    %esi
f0105033:	5f                   	pop    %edi
f0105034:	5d                   	pop    %ebp
f0105035:	c3                   	ret    

f0105036 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105036:	55                   	push   %ebp
f0105037:	89 e5                	mov    %esp,%ebp
f0105039:	57                   	push   %edi
f010503a:	56                   	push   %esi
f010503b:	8b 45 08             	mov    0x8(%ebp),%eax
f010503e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105041:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105044:	39 c6                	cmp    %eax,%esi
f0105046:	73 35                	jae    f010507d <memmove+0x47>
f0105048:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010504b:	39 d0                	cmp    %edx,%eax
f010504d:	73 2e                	jae    f010507d <memmove+0x47>
		s += n;
		d += n;
f010504f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105052:	89 d6                	mov    %edx,%esi
f0105054:	09 fe                	or     %edi,%esi
f0105056:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010505c:	75 13                	jne    f0105071 <memmove+0x3b>
f010505e:	f6 c1 03             	test   $0x3,%cl
f0105061:	75 0e                	jne    f0105071 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0105063:	83 ef 04             	sub    $0x4,%edi
f0105066:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105069:	c1 e9 02             	shr    $0x2,%ecx
f010506c:	fd                   	std    
f010506d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010506f:	eb 09                	jmp    f010507a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105071:	83 ef 01             	sub    $0x1,%edi
f0105074:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105077:	fd                   	std    
f0105078:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010507a:	fc                   	cld    
f010507b:	eb 1d                	jmp    f010509a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010507d:	89 f2                	mov    %esi,%edx
f010507f:	09 c2                	or     %eax,%edx
f0105081:	f6 c2 03             	test   $0x3,%dl
f0105084:	75 0f                	jne    f0105095 <memmove+0x5f>
f0105086:	f6 c1 03             	test   $0x3,%cl
f0105089:	75 0a                	jne    f0105095 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010508b:	c1 e9 02             	shr    $0x2,%ecx
f010508e:	89 c7                	mov    %eax,%edi
f0105090:	fc                   	cld    
f0105091:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105093:	eb 05                	jmp    f010509a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105095:	89 c7                	mov    %eax,%edi
f0105097:	fc                   	cld    
f0105098:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010509a:	5e                   	pop    %esi
f010509b:	5f                   	pop    %edi
f010509c:	5d                   	pop    %ebp
f010509d:	c3                   	ret    

f010509e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010509e:	55                   	push   %ebp
f010509f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01050a1:	ff 75 10             	pushl  0x10(%ebp)
f01050a4:	ff 75 0c             	pushl  0xc(%ebp)
f01050a7:	ff 75 08             	pushl  0x8(%ebp)
f01050aa:	e8 87 ff ff ff       	call   f0105036 <memmove>
}
f01050af:	c9                   	leave  
f01050b0:	c3                   	ret    

f01050b1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01050b1:	55                   	push   %ebp
f01050b2:	89 e5                	mov    %esp,%ebp
f01050b4:	56                   	push   %esi
f01050b5:	53                   	push   %ebx
f01050b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01050b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01050bc:	89 c6                	mov    %eax,%esi
f01050be:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01050c1:	eb 1a                	jmp    f01050dd <memcmp+0x2c>
		if (*s1 != *s2)
f01050c3:	0f b6 08             	movzbl (%eax),%ecx
f01050c6:	0f b6 1a             	movzbl (%edx),%ebx
f01050c9:	38 d9                	cmp    %bl,%cl
f01050cb:	74 0a                	je     f01050d7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01050cd:	0f b6 c1             	movzbl %cl,%eax
f01050d0:	0f b6 db             	movzbl %bl,%ebx
f01050d3:	29 d8                	sub    %ebx,%eax
f01050d5:	eb 0f                	jmp    f01050e6 <memcmp+0x35>
		s1++, s2++;
f01050d7:	83 c0 01             	add    $0x1,%eax
f01050da:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01050dd:	39 f0                	cmp    %esi,%eax
f01050df:	75 e2                	jne    f01050c3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01050e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01050e6:	5b                   	pop    %ebx
f01050e7:	5e                   	pop    %esi
f01050e8:	5d                   	pop    %ebp
f01050e9:	c3                   	ret    

f01050ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01050ea:	55                   	push   %ebp
f01050eb:	89 e5                	mov    %esp,%ebp
f01050ed:	53                   	push   %ebx
f01050ee:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01050f1:	89 c1                	mov    %eax,%ecx
f01050f3:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01050f6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01050fa:	eb 0a                	jmp    f0105106 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01050fc:	0f b6 10             	movzbl (%eax),%edx
f01050ff:	39 da                	cmp    %ebx,%edx
f0105101:	74 07                	je     f010510a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105103:	83 c0 01             	add    $0x1,%eax
f0105106:	39 c8                	cmp    %ecx,%eax
f0105108:	72 f2                	jb     f01050fc <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010510a:	5b                   	pop    %ebx
f010510b:	5d                   	pop    %ebp
f010510c:	c3                   	ret    

f010510d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010510d:	55                   	push   %ebp
f010510e:	89 e5                	mov    %esp,%ebp
f0105110:	57                   	push   %edi
f0105111:	56                   	push   %esi
f0105112:	53                   	push   %ebx
f0105113:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105116:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105119:	eb 03                	jmp    f010511e <strtol+0x11>
		s++;
f010511b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010511e:	0f b6 01             	movzbl (%ecx),%eax
f0105121:	3c 20                	cmp    $0x20,%al
f0105123:	74 f6                	je     f010511b <strtol+0xe>
f0105125:	3c 09                	cmp    $0x9,%al
f0105127:	74 f2                	je     f010511b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105129:	3c 2b                	cmp    $0x2b,%al
f010512b:	75 0a                	jne    f0105137 <strtol+0x2a>
		s++;
f010512d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105130:	bf 00 00 00 00       	mov    $0x0,%edi
f0105135:	eb 11                	jmp    f0105148 <strtol+0x3b>
f0105137:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010513c:	3c 2d                	cmp    $0x2d,%al
f010513e:	75 08                	jne    f0105148 <strtol+0x3b>
		s++, neg = 1;
f0105140:	83 c1 01             	add    $0x1,%ecx
f0105143:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105148:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010514e:	75 15                	jne    f0105165 <strtol+0x58>
f0105150:	80 39 30             	cmpb   $0x30,(%ecx)
f0105153:	75 10                	jne    f0105165 <strtol+0x58>
f0105155:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105159:	75 7c                	jne    f01051d7 <strtol+0xca>
		s += 2, base = 16;
f010515b:	83 c1 02             	add    $0x2,%ecx
f010515e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105163:	eb 16                	jmp    f010517b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105165:	85 db                	test   %ebx,%ebx
f0105167:	75 12                	jne    f010517b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105169:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010516e:	80 39 30             	cmpb   $0x30,(%ecx)
f0105171:	75 08                	jne    f010517b <strtol+0x6e>
		s++, base = 8;
f0105173:	83 c1 01             	add    $0x1,%ecx
f0105176:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010517b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105180:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105183:	0f b6 11             	movzbl (%ecx),%edx
f0105186:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105189:	89 f3                	mov    %esi,%ebx
f010518b:	80 fb 09             	cmp    $0x9,%bl
f010518e:	77 08                	ja     f0105198 <strtol+0x8b>
			dig = *s - '0';
f0105190:	0f be d2             	movsbl %dl,%edx
f0105193:	83 ea 30             	sub    $0x30,%edx
f0105196:	eb 22                	jmp    f01051ba <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105198:	8d 72 9f             	lea    -0x61(%edx),%esi
f010519b:	89 f3                	mov    %esi,%ebx
f010519d:	80 fb 19             	cmp    $0x19,%bl
f01051a0:	77 08                	ja     f01051aa <strtol+0x9d>
			dig = *s - 'a' + 10;
f01051a2:	0f be d2             	movsbl %dl,%edx
f01051a5:	83 ea 57             	sub    $0x57,%edx
f01051a8:	eb 10                	jmp    f01051ba <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01051aa:	8d 72 bf             	lea    -0x41(%edx),%esi
f01051ad:	89 f3                	mov    %esi,%ebx
f01051af:	80 fb 19             	cmp    $0x19,%bl
f01051b2:	77 16                	ja     f01051ca <strtol+0xbd>
			dig = *s - 'A' + 10;
f01051b4:	0f be d2             	movsbl %dl,%edx
f01051b7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01051ba:	3b 55 10             	cmp    0x10(%ebp),%edx
f01051bd:	7d 0b                	jge    f01051ca <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01051bf:	83 c1 01             	add    $0x1,%ecx
f01051c2:	0f af 45 10          	imul   0x10(%ebp),%eax
f01051c6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01051c8:	eb b9                	jmp    f0105183 <strtol+0x76>

	if (endptr)
f01051ca:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01051ce:	74 0d                	je     f01051dd <strtol+0xd0>
		*endptr = (char *) s;
f01051d0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01051d3:	89 0e                	mov    %ecx,(%esi)
f01051d5:	eb 06                	jmp    f01051dd <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01051d7:	85 db                	test   %ebx,%ebx
f01051d9:	74 98                	je     f0105173 <strtol+0x66>
f01051db:	eb 9e                	jmp    f010517b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01051dd:	89 c2                	mov    %eax,%edx
f01051df:	f7 da                	neg    %edx
f01051e1:	85 ff                	test   %edi,%edi
f01051e3:	0f 45 c2             	cmovne %edx,%eax
}
f01051e6:	5b                   	pop    %ebx
f01051e7:	5e                   	pop    %esi
f01051e8:	5f                   	pop    %edi
f01051e9:	5d                   	pop    %ebp
f01051ea:	c3                   	ret    
f01051eb:	90                   	nop

f01051ec <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01051ec:	fa                   	cli    

	xorw    %ax, %ax
f01051ed:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01051ef:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01051f1:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01051f3:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01051f5:	0f 01 16             	lgdtl  (%esi)
f01051f8:	74 70                	je     f010526a <mpsearch1+0x3>
	movl    %cr0, %eax
f01051fa:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01051fd:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105201:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105204:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010520a:	08 00                	or     %al,(%eax)

f010520c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010520c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105210:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105212:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105214:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105216:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010521a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010521c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010521e:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0105223:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105226:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105229:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010522e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105231:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105237:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010523c:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0105241:	ff d0                	call   *%eax

f0105243 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105243:	eb fe                	jmp    f0105243 <spin>
f0105245:	8d 76 00             	lea    0x0(%esi),%esi

f0105248 <gdt>:
	...
f0105250:	ff                   	(bad)  
f0105251:	ff 00                	incl   (%eax)
f0105253:	00 00                	add    %al,(%eax)
f0105255:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010525c:	00                   	.byte 0x0
f010525d:	92                   	xchg   %eax,%edx
f010525e:	cf                   	iret   
	...

f0105260 <gdtdesc>:
f0105260:	17                   	pop    %ss
f0105261:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105266 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105266:	90                   	nop

f0105267 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105267:	55                   	push   %ebp
f0105268:	89 e5                	mov    %esp,%ebp
f010526a:	57                   	push   %edi
f010526b:	56                   	push   %esi
f010526c:	53                   	push   %ebx
f010526d:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105270:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0105276:	89 c3                	mov    %eax,%ebx
f0105278:	c1 eb 0c             	shr    $0xc,%ebx
f010527b:	39 cb                	cmp    %ecx,%ebx
f010527d:	72 12                	jb     f0105291 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010527f:	50                   	push   %eax
f0105280:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0105285:	6a 57                	push   $0x57
f0105287:	68 81 77 10 f0       	push   $0xf0107781
f010528c:	e8 af ad ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105291:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105297:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105299:	89 c2                	mov    %eax,%edx
f010529b:	c1 ea 0c             	shr    $0xc,%edx
f010529e:	39 ca                	cmp    %ecx,%edx
f01052a0:	72 12                	jb     f01052b4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01052a2:	50                   	push   %eax
f01052a3:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01052a8:	6a 57                	push   $0x57
f01052aa:	68 81 77 10 f0       	push   $0xf0107781
f01052af:	e8 8c ad ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01052b4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01052ba:	eb 2f                	jmp    f01052eb <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01052bc:	83 ec 04             	sub    $0x4,%esp
f01052bf:	6a 04                	push   $0x4
f01052c1:	68 91 77 10 f0       	push   $0xf0107791
f01052c6:	53                   	push   %ebx
f01052c7:	e8 e5 fd ff ff       	call   f01050b1 <memcmp>
f01052cc:	83 c4 10             	add    $0x10,%esp
f01052cf:	85 c0                	test   %eax,%eax
f01052d1:	75 15                	jne    f01052e8 <mpsearch1+0x81>
f01052d3:	89 da                	mov    %ebx,%edx
f01052d5:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01052d8:	0f b6 0a             	movzbl (%edx),%ecx
f01052db:	01 c8                	add    %ecx,%eax
f01052dd:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01052e0:	39 d7                	cmp    %edx,%edi
f01052e2:	75 f4                	jne    f01052d8 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01052e4:	84 c0                	test   %al,%al
f01052e6:	74 0e                	je     f01052f6 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01052e8:	83 c3 10             	add    $0x10,%ebx
f01052eb:	39 f3                	cmp    %esi,%ebx
f01052ed:	72 cd                	jb     f01052bc <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01052ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01052f4:	eb 02                	jmp    f01052f8 <mpsearch1+0x91>
f01052f6:	89 d8                	mov    %ebx,%eax
}
f01052f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052fb:	5b                   	pop    %ebx
f01052fc:	5e                   	pop    %esi
f01052fd:	5f                   	pop    %edi
f01052fe:	5d                   	pop    %ebp
f01052ff:	c3                   	ret    

f0105300 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105300:	55                   	push   %ebp
f0105301:	89 e5                	mov    %esp,%ebp
f0105303:	57                   	push   %edi
f0105304:	56                   	push   %esi
f0105305:	53                   	push   %ebx
f0105306:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105309:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0105310:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105313:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010531a:	75 16                	jne    f0105332 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010531c:	68 00 04 00 00       	push   $0x400
f0105321:	68 e4 5c 10 f0       	push   $0xf0105ce4
f0105326:	6a 6f                	push   $0x6f
f0105328:	68 81 77 10 f0       	push   $0xf0107781
f010532d:	e8 0e ad ff ff       	call   f0100040 <_panic>

	static_assert(sizeof(*mp) == 16);

	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);
	cprintf("bda   %08x\n",bda);
f0105332:	83 ec 08             	sub    $0x8,%esp
f0105335:	68 00 04 00 f0       	push   $0xf0000400
f010533a:	68 96 77 10 f0       	push   $0xf0107796
f010533f:	e8 79 e2 ff ff       	call   f01035bd <cprintf>
	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105344:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f010534b:	83 c4 10             	add    $0x10,%esp
f010534e:	85 c0                	test   %eax,%eax
f0105350:	74 16                	je     f0105368 <mp_init+0x68>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105352:	c1 e0 04             	shl    $0x4,%eax
f0105355:	ba 00 04 00 00       	mov    $0x400,%edx
f010535a:	e8 08 ff ff ff       	call   f0105267 <mpsearch1>
f010535f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105362:	85 c0                	test   %eax,%eax
f0105364:	75 3c                	jne    f01053a2 <mp_init+0xa2>
f0105366:	eb 20                	jmp    f0105388 <mp_init+0x88>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105368:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010536f:	c1 e0 0a             	shl    $0xa,%eax
f0105372:	2d 00 04 00 00       	sub    $0x400,%eax
f0105377:	ba 00 04 00 00       	mov    $0x400,%edx
f010537c:	e8 e6 fe ff ff       	call   f0105267 <mpsearch1>
f0105381:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105384:	85 c0                	test   %eax,%eax
f0105386:	75 1a                	jne    f01053a2 <mp_init+0xa2>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105388:	ba 00 00 01 00       	mov    $0x10000,%edx
f010538d:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105392:	e8 d0 fe ff ff       	call   f0105267 <mpsearch1>
f0105397:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f010539a:	85 c0                	test   %eax,%eax
f010539c:	0f 84 5d 02 00 00    	je     f01055ff <mp_init+0x2ff>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01053a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053a5:	8b 70 04             	mov    0x4(%eax),%esi
f01053a8:	85 f6                	test   %esi,%esi
f01053aa:	74 06                	je     f01053b2 <mp_init+0xb2>
f01053ac:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01053b0:	74 15                	je     f01053c7 <mp_init+0xc7>
		cprintf("SMP: Default configurations not implemented\n");
f01053b2:	83 ec 0c             	sub    $0xc,%esp
f01053b5:	68 f4 75 10 f0       	push   $0xf01075f4
f01053ba:	e8 fe e1 ff ff       	call   f01035bd <cprintf>
f01053bf:	83 c4 10             	add    $0x10,%esp
f01053c2:	e9 38 02 00 00       	jmp    f01055ff <mp_init+0x2ff>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01053c7:	89 f0                	mov    %esi,%eax
f01053c9:	c1 e8 0c             	shr    $0xc,%eax
f01053cc:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01053d2:	72 15                	jb     f01053e9 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01053d4:	56                   	push   %esi
f01053d5:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01053da:	68 90 00 00 00       	push   $0x90
f01053df:	68 81 77 10 f0       	push   $0xf0107781
f01053e4:	e8 57 ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01053e9:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01053ef:	83 ec 04             	sub    $0x4,%esp
f01053f2:	6a 04                	push   $0x4
f01053f4:	68 a2 77 10 f0       	push   $0xf01077a2
f01053f9:	53                   	push   %ebx
f01053fa:	e8 b2 fc ff ff       	call   f01050b1 <memcmp>
f01053ff:	83 c4 10             	add    $0x10,%esp
f0105402:	85 c0                	test   %eax,%eax
f0105404:	74 15                	je     f010541b <mp_init+0x11b>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105406:	83 ec 0c             	sub    $0xc,%esp
f0105409:	68 24 76 10 f0       	push   $0xf0107624
f010540e:	e8 aa e1 ff ff       	call   f01035bd <cprintf>
f0105413:	83 c4 10             	add    $0x10,%esp
f0105416:	e9 e4 01 00 00       	jmp    f01055ff <mp_init+0x2ff>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010541b:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010541f:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105423:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105426:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010542b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105430:	eb 0d                	jmp    f010543f <mp_init+0x13f>
		sum += ((uint8_t *)addr)[i];
f0105432:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105439:	f0 
f010543a:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010543c:	83 c0 01             	add    $0x1,%eax
f010543f:	39 c7                	cmp    %eax,%edi
f0105441:	75 ef                	jne    f0105432 <mp_init+0x132>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105443:	84 d2                	test   %dl,%dl
f0105445:	74 15                	je     f010545c <mp_init+0x15c>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105447:	83 ec 0c             	sub    $0xc,%esp
f010544a:	68 58 76 10 f0       	push   $0xf0107658
f010544f:	e8 69 e1 ff ff       	call   f01035bd <cprintf>
f0105454:	83 c4 10             	add    $0x10,%esp
f0105457:	e9 a3 01 00 00       	jmp    f01055ff <mp_init+0x2ff>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f010545c:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105460:	3c 01                	cmp    $0x1,%al
f0105462:	74 1d                	je     f0105481 <mp_init+0x181>
f0105464:	3c 04                	cmp    $0x4,%al
f0105466:	74 19                	je     f0105481 <mp_init+0x181>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105468:	83 ec 08             	sub    $0x8,%esp
f010546b:	0f b6 c0             	movzbl %al,%eax
f010546e:	50                   	push   %eax
f010546f:	68 7c 76 10 f0       	push   $0xf010767c
f0105474:	e8 44 e1 ff ff       	call   f01035bd <cprintf>
f0105479:	83 c4 10             	add    $0x10,%esp
f010547c:	e9 7e 01 00 00       	jmp    f01055ff <mp_init+0x2ff>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105481:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105485:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105489:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010548e:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105493:	01 ce                	add    %ecx,%esi
f0105495:	eb 0d                	jmp    f01054a4 <mp_init+0x1a4>
f0105497:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f010549e:	f0 
f010549f:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01054a1:	83 c0 01             	add    $0x1,%eax
f01054a4:	39 c7                	cmp    %eax,%edi
f01054a6:	75 ef                	jne    f0105497 <mp_init+0x197>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01054a8:	89 d0                	mov    %edx,%eax
f01054aa:	02 43 2a             	add    0x2a(%ebx),%al
f01054ad:	74 15                	je     f01054c4 <mp_init+0x1c4>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01054af:	83 ec 0c             	sub    $0xc,%esp
f01054b2:	68 9c 76 10 f0       	push   $0xf010769c
f01054b7:	e8 01 e1 ff ff       	call   f01035bd <cprintf>
f01054bc:	83 c4 10             	add    $0x10,%esp
f01054bf:	e9 3b 01 00 00       	jmp    f01055ff <mp_init+0x2ff>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01054c4:	85 db                	test   %ebx,%ebx
f01054c6:	0f 84 33 01 00 00    	je     f01055ff <mp_init+0x2ff>
		return;
	ismp = 1;
f01054cc:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01054d3:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01054d6:	8b 43 24             	mov    0x24(%ebx),%eax
f01054d9:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01054de:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01054e1:	be 00 00 00 00       	mov    $0x0,%esi
f01054e6:	e9 85 00 00 00       	jmp    f0105570 <mp_init+0x270>
		switch (*p) {
f01054eb:	0f b6 07             	movzbl (%edi),%eax
f01054ee:	84 c0                	test   %al,%al
f01054f0:	74 06                	je     f01054f8 <mp_init+0x1f8>
f01054f2:	3c 04                	cmp    $0x4,%al
f01054f4:	77 55                	ja     f010554b <mp_init+0x24b>
f01054f6:	eb 4e                	jmp    f0105546 <mp_init+0x246>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01054f8:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01054fc:	74 11                	je     f010550f <mp_init+0x20f>
				bootcpu = &cpus[ncpu];
f01054fe:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0105505:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010550a:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f010550f:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f0105514:	83 f8 07             	cmp    $0x7,%eax
f0105517:	7f 13                	jg     f010552c <mp_init+0x22c>
				cpus[ncpu].cpu_id = ncpu;
f0105519:	6b d0 74             	imul   $0x74,%eax,%edx
f010551c:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f0105522:	83 c0 01             	add    $0x1,%eax
f0105525:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f010552a:	eb 15                	jmp    f0105541 <mp_init+0x241>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f010552c:	83 ec 08             	sub    $0x8,%esp
f010552f:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105533:	50                   	push   %eax
f0105534:	68 cc 76 10 f0       	push   $0xf01076cc
f0105539:	e8 7f e0 ff ff       	call   f01035bd <cprintf>
f010553e:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105541:	83 c7 14             	add    $0x14,%edi
			continue;
f0105544:	eb 27                	jmp    f010556d <mp_init+0x26d>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105546:	83 c7 08             	add    $0x8,%edi
			continue;
f0105549:	eb 22                	jmp    f010556d <mp_init+0x26d>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010554b:	83 ec 08             	sub    $0x8,%esp
f010554e:	0f b6 c0             	movzbl %al,%eax
f0105551:	50                   	push   %eax
f0105552:	68 f4 76 10 f0       	push   $0xf01076f4
f0105557:	e8 61 e0 ff ff       	call   f01035bd <cprintf>
			ismp = 0;
f010555c:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f0105563:	00 00 00 
			i = conf->entry;
f0105566:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f010556a:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010556d:	83 c6 01             	add    $0x1,%esi
f0105570:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105574:	39 c6                	cmp    %eax,%esi
f0105576:	0f 82 6f ff ff ff    	jb     f01054eb <mp_init+0x1eb>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010557c:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105581:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105588:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f010558f:	75 26                	jne    f01055b7 <mp_init+0x2b7>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105591:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f0105598:	00 00 00 
		lapicaddr = 0;
f010559b:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f01055a2:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01055a5:	83 ec 0c             	sub    $0xc,%esp
f01055a8:	68 14 77 10 f0       	push   $0xf0107714
f01055ad:	e8 0b e0 ff ff       	call   f01035bd <cprintf>
		return;
f01055b2:	83 c4 10             	add    $0x10,%esp
f01055b5:	eb 48                	jmp    f01055ff <mp_init+0x2ff>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01055b7:	83 ec 04             	sub    $0x4,%esp
f01055ba:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f01055c0:	0f b6 00             	movzbl (%eax),%eax
f01055c3:	50                   	push   %eax
f01055c4:	68 a7 77 10 f0       	push   $0xf01077a7
f01055c9:	e8 ef df ff ff       	call   f01035bd <cprintf>

	if (mp->imcrp) {
f01055ce:	83 c4 10             	add    $0x10,%esp
f01055d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01055d4:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01055d8:	74 25                	je     f01055ff <mp_init+0x2ff>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01055da:	83 ec 0c             	sub    $0xc,%esp
f01055dd:	68 40 77 10 f0       	push   $0xf0107740
f01055e2:	e8 d6 df ff ff       	call   f01035bd <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01055e7:	ba 22 00 00 00       	mov    $0x22,%edx
f01055ec:	b8 70 00 00 00       	mov    $0x70,%eax
f01055f1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01055f2:	ba 23 00 00 00       	mov    $0x23,%edx
f01055f7:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01055f8:	83 c8 01             	or     $0x1,%eax
f01055fb:	ee                   	out    %al,(%dx)
f01055fc:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01055ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105602:	5b                   	pop    %ebx
f0105603:	5e                   	pop    %esi
f0105604:	5f                   	pop    %edi
f0105605:	5d                   	pop    %ebp
f0105606:	c3                   	ret    

f0105607 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105607:	55                   	push   %ebp
f0105608:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f010560a:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f0105610:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105613:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105615:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010561a:	8b 40 20             	mov    0x20(%eax),%eax
}
f010561d:	5d                   	pop    %ebp
f010561e:	c3                   	ret    

f010561f <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010561f:	55                   	push   %ebp
f0105620:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105622:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105627:	85 c0                	test   %eax,%eax
f0105629:	74 08                	je     f0105633 <cpunum+0x14>
		return lapic[ID] >> 24;
f010562b:	8b 40 20             	mov    0x20(%eax),%eax
f010562e:	c1 e8 18             	shr    $0x18,%eax
f0105631:	eb 05                	jmp    f0105638 <cpunum+0x19>
	return 0;
f0105633:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105638:	5d                   	pop    %ebp
f0105639:	c3                   	ret    

f010563a <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f010563a:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f010563f:	85 c0                	test   %eax,%eax
f0105641:	0f 84 21 01 00 00    	je     f0105768 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105647:	55                   	push   %ebp
f0105648:	89 e5                	mov    %esp,%ebp
f010564a:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f010564d:	68 00 10 00 00       	push   $0x1000
f0105652:	50                   	push   %eax
f0105653:	e8 53 bb ff ff       	call   f01011ab <mmio_map_region>
f0105658:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010565d:	ba 27 01 00 00       	mov    $0x127,%edx
f0105662:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105667:	e8 9b ff ff ff       	call   f0105607 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010566c:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105671:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105676:	e8 8c ff ff ff       	call   f0105607 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010567b:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105680:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105685:	e8 7d ff ff ff       	call   f0105607 <lapicw>
	lapicw(TICR, 10000000); 
f010568a:	ba 80 96 98 00       	mov    $0x989680,%edx
f010568f:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105694:	e8 6e ff ff ff       	call   f0105607 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105699:	e8 81 ff ff ff       	call   f010561f <cpunum>
f010569e:	6b c0 74             	imul   $0x74,%eax,%eax
f01056a1:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01056a6:	83 c4 10             	add    $0x10,%esp
f01056a9:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f01056af:	74 0f                	je     f01056c0 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01056b1:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056b6:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01056bb:	e8 47 ff ff ff       	call   f0105607 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01056c0:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056c5:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01056ca:	e8 38 ff ff ff       	call   f0105607 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01056cf:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01056d4:	8b 40 30             	mov    0x30(%eax),%eax
f01056d7:	c1 e8 10             	shr    $0x10,%eax
f01056da:	3c 03                	cmp    $0x3,%al
f01056dc:	76 0f                	jbe    f01056ed <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01056de:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056e3:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01056e8:	e8 1a ff ff ff       	call   f0105607 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01056ed:	ba 33 00 00 00       	mov    $0x33,%edx
f01056f2:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01056f7:	e8 0b ff ff ff       	call   f0105607 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01056fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0105701:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105706:	e8 fc fe ff ff       	call   f0105607 <lapicw>
	lapicw(ESR, 0);
f010570b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105710:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105715:	e8 ed fe ff ff       	call   f0105607 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f010571a:	ba 00 00 00 00       	mov    $0x0,%edx
f010571f:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105724:	e8 de fe ff ff       	call   f0105607 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105729:	ba 00 00 00 00       	mov    $0x0,%edx
f010572e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105733:	e8 cf fe ff ff       	call   f0105607 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105738:	ba 00 85 08 00       	mov    $0x88500,%edx
f010573d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105742:	e8 c0 fe ff ff       	call   f0105607 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105747:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010574d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105753:	f6 c4 10             	test   $0x10,%ah
f0105756:	75 f5                	jne    f010574d <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105758:	ba 00 00 00 00       	mov    $0x0,%edx
f010575d:	b8 20 00 00 00       	mov    $0x20,%eax
f0105762:	e8 a0 fe ff ff       	call   f0105607 <lapicw>
}
f0105767:	c9                   	leave  
f0105768:	f3 c3                	repz ret 

f010576a <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f010576a:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105771:	74 13                	je     f0105786 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105773:	55                   	push   %ebp
f0105774:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105776:	ba 00 00 00 00       	mov    $0x0,%edx
f010577b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105780:	e8 82 fe ff ff       	call   f0105607 <lapicw>
}
f0105785:	5d                   	pop    %ebp
f0105786:	f3 c3                	repz ret 

f0105788 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105788:	55                   	push   %ebp
f0105789:	89 e5                	mov    %esp,%ebp
f010578b:	56                   	push   %esi
f010578c:	53                   	push   %ebx
f010578d:	8b 75 08             	mov    0x8(%ebp),%esi
f0105790:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105793:	ba 70 00 00 00       	mov    $0x70,%edx
f0105798:	b8 0f 00 00 00       	mov    $0xf,%eax
f010579d:	ee                   	out    %al,(%dx)
f010579e:	ba 71 00 00 00       	mov    $0x71,%edx
f01057a3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01057a8:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01057a9:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f01057b0:	75 19                	jne    f01057cb <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057b2:	68 67 04 00 00       	push   $0x467
f01057b7:	68 e4 5c 10 f0       	push   $0xf0105ce4
f01057bc:	68 98 00 00 00       	push   $0x98
f01057c1:	68 c4 77 10 f0       	push   $0xf01077c4
f01057c6:	e8 75 a8 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01057cb:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01057d2:	00 00 
	wrv[1] = addr >> 4;
f01057d4:	89 d8                	mov    %ebx,%eax
f01057d6:	c1 e8 04             	shr    $0x4,%eax
f01057d9:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01057df:	c1 e6 18             	shl    $0x18,%esi
f01057e2:	89 f2                	mov    %esi,%edx
f01057e4:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01057e9:	e8 19 fe ff ff       	call   f0105607 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01057ee:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01057f3:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01057f8:	e8 0a fe ff ff       	call   f0105607 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01057fd:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105802:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105807:	e8 fb fd ff ff       	call   f0105607 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010580c:	c1 eb 0c             	shr    $0xc,%ebx
f010580f:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105812:	89 f2                	mov    %esi,%edx
f0105814:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105819:	e8 e9 fd ff ff       	call   f0105607 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010581e:	89 da                	mov    %ebx,%edx
f0105820:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105825:	e8 dd fd ff ff       	call   f0105607 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010582a:	89 f2                	mov    %esi,%edx
f010582c:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105831:	e8 d1 fd ff ff       	call   f0105607 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105836:	89 da                	mov    %ebx,%edx
f0105838:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010583d:	e8 c5 fd ff ff       	call   f0105607 <lapicw>
		microdelay(200);
	}
}
f0105842:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105845:	5b                   	pop    %ebx
f0105846:	5e                   	pop    %esi
f0105847:	5d                   	pop    %ebp
f0105848:	c3                   	ret    

f0105849 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105849:	55                   	push   %ebp
f010584a:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010584c:	8b 55 08             	mov    0x8(%ebp),%edx
f010584f:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105855:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010585a:	e8 a8 fd ff ff       	call   f0105607 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010585f:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105865:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010586b:	f6 c4 10             	test   $0x10,%ah
f010586e:	75 f5                	jne    f0105865 <lapic_ipi+0x1c>
		;
}
f0105870:	5d                   	pop    %ebp
f0105871:	c3                   	ret    

f0105872 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105872:	55                   	push   %ebp
f0105873:	89 e5                	mov    %esp,%ebp
f0105875:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105878:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f010587e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105881:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105884:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f010588b:	5d                   	pop    %ebp
f010588c:	c3                   	ret    

f010588d <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f010588d:	55                   	push   %ebp
f010588e:	89 e5                	mov    %esp,%ebp
f0105890:	56                   	push   %esi
f0105891:	53                   	push   %ebx
f0105892:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105895:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105898:	74 14                	je     f01058ae <spin_lock+0x21>
f010589a:	8b 73 08             	mov    0x8(%ebx),%esi
f010589d:	e8 7d fd ff ff       	call   f010561f <cpunum>
f01058a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01058a5:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01058aa:	39 c6                	cmp    %eax,%esi
f01058ac:	74 07                	je     f01058b5 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f01058ae:	ba 01 00 00 00       	mov    $0x1,%edx
f01058b3:	eb 20                	jmp    f01058d5 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01058b5:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01058b8:	e8 62 fd ff ff       	call   f010561f <cpunum>
f01058bd:	83 ec 0c             	sub    $0xc,%esp
f01058c0:	53                   	push   %ebx
f01058c1:	50                   	push   %eax
f01058c2:	68 d4 77 10 f0       	push   $0xf01077d4
f01058c7:	6a 41                	push   $0x41
f01058c9:	68 38 78 10 f0       	push   $0xf0107838
f01058ce:	e8 6d a7 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01058d3:	f3 90                	pause  
f01058d5:	89 d0                	mov    %edx,%eax
f01058d7:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01058da:	85 c0                	test   %eax,%eax
f01058dc:	75 f5                	jne    f01058d3 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01058de:	e8 3c fd ff ff       	call   f010561f <cpunum>
f01058e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01058e6:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01058eb:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01058ee:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01058f1:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01058f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01058f8:	eb 0b                	jmp    f0105905 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01058fa:	8b 4a 04             	mov    0x4(%edx),%ecx
f01058fd:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105900:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105902:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105905:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f010590b:	76 11                	jbe    f010591e <spin_lock+0x91>
f010590d:	83 f8 09             	cmp    $0x9,%eax
f0105910:	7e e8                	jle    f01058fa <spin_lock+0x6d>
f0105912:	eb 0a                	jmp    f010591e <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105914:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f010591b:	83 c0 01             	add    $0x1,%eax
f010591e:	83 f8 09             	cmp    $0x9,%eax
f0105921:	7e f1                	jle    f0105914 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105923:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105926:	5b                   	pop    %ebx
f0105927:	5e                   	pop    %esi
f0105928:	5d                   	pop    %ebp
f0105929:	c3                   	ret    

f010592a <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f010592a:	55                   	push   %ebp
f010592b:	89 e5                	mov    %esp,%ebp
f010592d:	57                   	push   %edi
f010592e:	56                   	push   %esi
f010592f:	53                   	push   %ebx
f0105930:	83 ec 4c             	sub    $0x4c,%esp
f0105933:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105936:	83 3e 00             	cmpl   $0x0,(%esi)
f0105939:	74 18                	je     f0105953 <spin_unlock+0x29>
f010593b:	8b 5e 08             	mov    0x8(%esi),%ebx
f010593e:	e8 dc fc ff ff       	call   f010561f <cpunum>
f0105943:	6b c0 74             	imul   $0x74,%eax,%eax
f0105946:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f010594b:	39 c3                	cmp    %eax,%ebx
f010594d:	0f 84 a5 00 00 00    	je     f01059f8 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105953:	83 ec 04             	sub    $0x4,%esp
f0105956:	6a 28                	push   $0x28
f0105958:	8d 46 0c             	lea    0xc(%esi),%eax
f010595b:	50                   	push   %eax
f010595c:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010595f:	53                   	push   %ebx
f0105960:	e8 d1 f6 ff ff       	call   f0105036 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105965:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105968:	0f b6 38             	movzbl (%eax),%edi
f010596b:	8b 76 04             	mov    0x4(%esi),%esi
f010596e:	e8 ac fc ff ff       	call   f010561f <cpunum>
f0105973:	57                   	push   %edi
f0105974:	56                   	push   %esi
f0105975:	50                   	push   %eax
f0105976:	68 00 78 10 f0       	push   $0xf0107800
f010597b:	e8 3d dc ff ff       	call   f01035bd <cprintf>
f0105980:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105983:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105986:	eb 54                	jmp    f01059dc <spin_unlock+0xb2>
f0105988:	83 ec 08             	sub    $0x8,%esp
f010598b:	57                   	push   %edi
f010598c:	50                   	push   %eax
f010598d:	e8 d7 eb ff ff       	call   f0104569 <debuginfo_eip>
f0105992:	83 c4 10             	add    $0x10,%esp
f0105995:	85 c0                	test   %eax,%eax
f0105997:	78 27                	js     f01059c0 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105999:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f010599b:	83 ec 04             	sub    $0x4,%esp
f010599e:	89 c2                	mov    %eax,%edx
f01059a0:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01059a3:	52                   	push   %edx
f01059a4:	ff 75 b0             	pushl  -0x50(%ebp)
f01059a7:	ff 75 b4             	pushl  -0x4c(%ebp)
f01059aa:	ff 75 ac             	pushl  -0x54(%ebp)
f01059ad:	ff 75 a8             	pushl  -0x58(%ebp)
f01059b0:	50                   	push   %eax
f01059b1:	68 48 78 10 f0       	push   $0xf0107848
f01059b6:	e8 02 dc ff ff       	call   f01035bd <cprintf>
f01059bb:	83 c4 20             	add    $0x20,%esp
f01059be:	eb 12                	jmp    f01059d2 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01059c0:	83 ec 08             	sub    $0x8,%esp
f01059c3:	ff 36                	pushl  (%esi)
f01059c5:	68 9a 77 10 f0       	push   $0xf010779a
f01059ca:	e8 ee db ff ff       	call   f01035bd <cprintf>
f01059cf:	83 c4 10             	add    $0x10,%esp
f01059d2:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01059d5:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01059d8:	39 c3                	cmp    %eax,%ebx
f01059da:	74 08                	je     f01059e4 <spin_unlock+0xba>
f01059dc:	89 de                	mov    %ebx,%esi
f01059de:	8b 03                	mov    (%ebx),%eax
f01059e0:	85 c0                	test   %eax,%eax
f01059e2:	75 a4                	jne    f0105988 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01059e4:	83 ec 04             	sub    $0x4,%esp
f01059e7:	68 5f 78 10 f0       	push   $0xf010785f
f01059ec:	6a 67                	push   $0x67
f01059ee:	68 38 78 10 f0       	push   $0xf0107838
f01059f3:	e8 48 a6 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01059f8:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01059ff:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0105a06:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a0b:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105a0e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a11:	5b                   	pop    %ebx
f0105a12:	5e                   	pop    %esi
f0105a13:	5f                   	pop    %edi
f0105a14:	5d                   	pop    %ebp
f0105a15:	c3                   	ret    
f0105a16:	66 90                	xchg   %ax,%ax
f0105a18:	66 90                	xchg   %ax,%ax
f0105a1a:	66 90                	xchg   %ax,%ax
f0105a1c:	66 90                	xchg   %ax,%ax
f0105a1e:	66 90                	xchg   %ax,%ax

f0105a20 <__udivdi3>:
f0105a20:	55                   	push   %ebp
f0105a21:	57                   	push   %edi
f0105a22:	56                   	push   %esi
f0105a23:	53                   	push   %ebx
f0105a24:	83 ec 1c             	sub    $0x1c,%esp
f0105a27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105a2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105a2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105a33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105a37:	85 f6                	test   %esi,%esi
f0105a39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105a3d:	89 ca                	mov    %ecx,%edx
f0105a3f:	89 f8                	mov    %edi,%eax
f0105a41:	75 3d                	jne    f0105a80 <__udivdi3+0x60>
f0105a43:	39 cf                	cmp    %ecx,%edi
f0105a45:	0f 87 c5 00 00 00    	ja     f0105b10 <__udivdi3+0xf0>
f0105a4b:	85 ff                	test   %edi,%edi
f0105a4d:	89 fd                	mov    %edi,%ebp
f0105a4f:	75 0b                	jne    f0105a5c <__udivdi3+0x3c>
f0105a51:	b8 01 00 00 00       	mov    $0x1,%eax
f0105a56:	31 d2                	xor    %edx,%edx
f0105a58:	f7 f7                	div    %edi
f0105a5a:	89 c5                	mov    %eax,%ebp
f0105a5c:	89 c8                	mov    %ecx,%eax
f0105a5e:	31 d2                	xor    %edx,%edx
f0105a60:	f7 f5                	div    %ebp
f0105a62:	89 c1                	mov    %eax,%ecx
f0105a64:	89 d8                	mov    %ebx,%eax
f0105a66:	89 cf                	mov    %ecx,%edi
f0105a68:	f7 f5                	div    %ebp
f0105a6a:	89 c3                	mov    %eax,%ebx
f0105a6c:	89 d8                	mov    %ebx,%eax
f0105a6e:	89 fa                	mov    %edi,%edx
f0105a70:	83 c4 1c             	add    $0x1c,%esp
f0105a73:	5b                   	pop    %ebx
f0105a74:	5e                   	pop    %esi
f0105a75:	5f                   	pop    %edi
f0105a76:	5d                   	pop    %ebp
f0105a77:	c3                   	ret    
f0105a78:	90                   	nop
f0105a79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105a80:	39 ce                	cmp    %ecx,%esi
f0105a82:	77 74                	ja     f0105af8 <__udivdi3+0xd8>
f0105a84:	0f bd fe             	bsr    %esi,%edi
f0105a87:	83 f7 1f             	xor    $0x1f,%edi
f0105a8a:	0f 84 98 00 00 00    	je     f0105b28 <__udivdi3+0x108>
f0105a90:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105a95:	89 f9                	mov    %edi,%ecx
f0105a97:	89 c5                	mov    %eax,%ebp
f0105a99:	29 fb                	sub    %edi,%ebx
f0105a9b:	d3 e6                	shl    %cl,%esi
f0105a9d:	89 d9                	mov    %ebx,%ecx
f0105a9f:	d3 ed                	shr    %cl,%ebp
f0105aa1:	89 f9                	mov    %edi,%ecx
f0105aa3:	d3 e0                	shl    %cl,%eax
f0105aa5:	09 ee                	or     %ebp,%esi
f0105aa7:	89 d9                	mov    %ebx,%ecx
f0105aa9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105aad:	89 d5                	mov    %edx,%ebp
f0105aaf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105ab3:	d3 ed                	shr    %cl,%ebp
f0105ab5:	89 f9                	mov    %edi,%ecx
f0105ab7:	d3 e2                	shl    %cl,%edx
f0105ab9:	89 d9                	mov    %ebx,%ecx
f0105abb:	d3 e8                	shr    %cl,%eax
f0105abd:	09 c2                	or     %eax,%edx
f0105abf:	89 d0                	mov    %edx,%eax
f0105ac1:	89 ea                	mov    %ebp,%edx
f0105ac3:	f7 f6                	div    %esi
f0105ac5:	89 d5                	mov    %edx,%ebp
f0105ac7:	89 c3                	mov    %eax,%ebx
f0105ac9:	f7 64 24 0c          	mull   0xc(%esp)
f0105acd:	39 d5                	cmp    %edx,%ebp
f0105acf:	72 10                	jb     f0105ae1 <__udivdi3+0xc1>
f0105ad1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105ad5:	89 f9                	mov    %edi,%ecx
f0105ad7:	d3 e6                	shl    %cl,%esi
f0105ad9:	39 c6                	cmp    %eax,%esi
f0105adb:	73 07                	jae    f0105ae4 <__udivdi3+0xc4>
f0105add:	39 d5                	cmp    %edx,%ebp
f0105adf:	75 03                	jne    f0105ae4 <__udivdi3+0xc4>
f0105ae1:	83 eb 01             	sub    $0x1,%ebx
f0105ae4:	31 ff                	xor    %edi,%edi
f0105ae6:	89 d8                	mov    %ebx,%eax
f0105ae8:	89 fa                	mov    %edi,%edx
f0105aea:	83 c4 1c             	add    $0x1c,%esp
f0105aed:	5b                   	pop    %ebx
f0105aee:	5e                   	pop    %esi
f0105aef:	5f                   	pop    %edi
f0105af0:	5d                   	pop    %ebp
f0105af1:	c3                   	ret    
f0105af2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105af8:	31 ff                	xor    %edi,%edi
f0105afa:	31 db                	xor    %ebx,%ebx
f0105afc:	89 d8                	mov    %ebx,%eax
f0105afe:	89 fa                	mov    %edi,%edx
f0105b00:	83 c4 1c             	add    $0x1c,%esp
f0105b03:	5b                   	pop    %ebx
f0105b04:	5e                   	pop    %esi
f0105b05:	5f                   	pop    %edi
f0105b06:	5d                   	pop    %ebp
f0105b07:	c3                   	ret    
f0105b08:	90                   	nop
f0105b09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105b10:	89 d8                	mov    %ebx,%eax
f0105b12:	f7 f7                	div    %edi
f0105b14:	31 ff                	xor    %edi,%edi
f0105b16:	89 c3                	mov    %eax,%ebx
f0105b18:	89 d8                	mov    %ebx,%eax
f0105b1a:	89 fa                	mov    %edi,%edx
f0105b1c:	83 c4 1c             	add    $0x1c,%esp
f0105b1f:	5b                   	pop    %ebx
f0105b20:	5e                   	pop    %esi
f0105b21:	5f                   	pop    %edi
f0105b22:	5d                   	pop    %ebp
f0105b23:	c3                   	ret    
f0105b24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105b28:	39 ce                	cmp    %ecx,%esi
f0105b2a:	72 0c                	jb     f0105b38 <__udivdi3+0x118>
f0105b2c:	31 db                	xor    %ebx,%ebx
f0105b2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105b32:	0f 87 34 ff ff ff    	ja     f0105a6c <__udivdi3+0x4c>
f0105b38:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105b3d:	e9 2a ff ff ff       	jmp    f0105a6c <__udivdi3+0x4c>
f0105b42:	66 90                	xchg   %ax,%ax
f0105b44:	66 90                	xchg   %ax,%ax
f0105b46:	66 90                	xchg   %ax,%ax
f0105b48:	66 90                	xchg   %ax,%ax
f0105b4a:	66 90                	xchg   %ax,%ax
f0105b4c:	66 90                	xchg   %ax,%ax
f0105b4e:	66 90                	xchg   %ax,%ax

f0105b50 <__umoddi3>:
f0105b50:	55                   	push   %ebp
f0105b51:	57                   	push   %edi
f0105b52:	56                   	push   %esi
f0105b53:	53                   	push   %ebx
f0105b54:	83 ec 1c             	sub    $0x1c,%esp
f0105b57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105b5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105b5f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105b63:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105b67:	85 d2                	test   %edx,%edx
f0105b69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105b6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105b71:	89 f3                	mov    %esi,%ebx
f0105b73:	89 3c 24             	mov    %edi,(%esp)
f0105b76:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105b7a:	75 1c                	jne    f0105b98 <__umoddi3+0x48>
f0105b7c:	39 f7                	cmp    %esi,%edi
f0105b7e:	76 50                	jbe    f0105bd0 <__umoddi3+0x80>
f0105b80:	89 c8                	mov    %ecx,%eax
f0105b82:	89 f2                	mov    %esi,%edx
f0105b84:	f7 f7                	div    %edi
f0105b86:	89 d0                	mov    %edx,%eax
f0105b88:	31 d2                	xor    %edx,%edx
f0105b8a:	83 c4 1c             	add    $0x1c,%esp
f0105b8d:	5b                   	pop    %ebx
f0105b8e:	5e                   	pop    %esi
f0105b8f:	5f                   	pop    %edi
f0105b90:	5d                   	pop    %ebp
f0105b91:	c3                   	ret    
f0105b92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105b98:	39 f2                	cmp    %esi,%edx
f0105b9a:	89 d0                	mov    %edx,%eax
f0105b9c:	77 52                	ja     f0105bf0 <__umoddi3+0xa0>
f0105b9e:	0f bd ea             	bsr    %edx,%ebp
f0105ba1:	83 f5 1f             	xor    $0x1f,%ebp
f0105ba4:	75 5a                	jne    f0105c00 <__umoddi3+0xb0>
f0105ba6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105baa:	0f 82 e0 00 00 00    	jb     f0105c90 <__umoddi3+0x140>
f0105bb0:	39 0c 24             	cmp    %ecx,(%esp)
f0105bb3:	0f 86 d7 00 00 00    	jbe    f0105c90 <__umoddi3+0x140>
f0105bb9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105bbd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105bc1:	83 c4 1c             	add    $0x1c,%esp
f0105bc4:	5b                   	pop    %ebx
f0105bc5:	5e                   	pop    %esi
f0105bc6:	5f                   	pop    %edi
f0105bc7:	5d                   	pop    %ebp
f0105bc8:	c3                   	ret    
f0105bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105bd0:	85 ff                	test   %edi,%edi
f0105bd2:	89 fd                	mov    %edi,%ebp
f0105bd4:	75 0b                	jne    f0105be1 <__umoddi3+0x91>
f0105bd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0105bdb:	31 d2                	xor    %edx,%edx
f0105bdd:	f7 f7                	div    %edi
f0105bdf:	89 c5                	mov    %eax,%ebp
f0105be1:	89 f0                	mov    %esi,%eax
f0105be3:	31 d2                	xor    %edx,%edx
f0105be5:	f7 f5                	div    %ebp
f0105be7:	89 c8                	mov    %ecx,%eax
f0105be9:	f7 f5                	div    %ebp
f0105beb:	89 d0                	mov    %edx,%eax
f0105bed:	eb 99                	jmp    f0105b88 <__umoddi3+0x38>
f0105bef:	90                   	nop
f0105bf0:	89 c8                	mov    %ecx,%eax
f0105bf2:	89 f2                	mov    %esi,%edx
f0105bf4:	83 c4 1c             	add    $0x1c,%esp
f0105bf7:	5b                   	pop    %ebx
f0105bf8:	5e                   	pop    %esi
f0105bf9:	5f                   	pop    %edi
f0105bfa:	5d                   	pop    %ebp
f0105bfb:	c3                   	ret    
f0105bfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105c00:	8b 34 24             	mov    (%esp),%esi
f0105c03:	bf 20 00 00 00       	mov    $0x20,%edi
f0105c08:	89 e9                	mov    %ebp,%ecx
f0105c0a:	29 ef                	sub    %ebp,%edi
f0105c0c:	d3 e0                	shl    %cl,%eax
f0105c0e:	89 f9                	mov    %edi,%ecx
f0105c10:	89 f2                	mov    %esi,%edx
f0105c12:	d3 ea                	shr    %cl,%edx
f0105c14:	89 e9                	mov    %ebp,%ecx
f0105c16:	09 c2                	or     %eax,%edx
f0105c18:	89 d8                	mov    %ebx,%eax
f0105c1a:	89 14 24             	mov    %edx,(%esp)
f0105c1d:	89 f2                	mov    %esi,%edx
f0105c1f:	d3 e2                	shl    %cl,%edx
f0105c21:	89 f9                	mov    %edi,%ecx
f0105c23:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105c27:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105c2b:	d3 e8                	shr    %cl,%eax
f0105c2d:	89 e9                	mov    %ebp,%ecx
f0105c2f:	89 c6                	mov    %eax,%esi
f0105c31:	d3 e3                	shl    %cl,%ebx
f0105c33:	89 f9                	mov    %edi,%ecx
f0105c35:	89 d0                	mov    %edx,%eax
f0105c37:	d3 e8                	shr    %cl,%eax
f0105c39:	89 e9                	mov    %ebp,%ecx
f0105c3b:	09 d8                	or     %ebx,%eax
f0105c3d:	89 d3                	mov    %edx,%ebx
f0105c3f:	89 f2                	mov    %esi,%edx
f0105c41:	f7 34 24             	divl   (%esp)
f0105c44:	89 d6                	mov    %edx,%esi
f0105c46:	d3 e3                	shl    %cl,%ebx
f0105c48:	f7 64 24 04          	mull   0x4(%esp)
f0105c4c:	39 d6                	cmp    %edx,%esi
f0105c4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105c52:	89 d1                	mov    %edx,%ecx
f0105c54:	89 c3                	mov    %eax,%ebx
f0105c56:	72 08                	jb     f0105c60 <__umoddi3+0x110>
f0105c58:	75 11                	jne    f0105c6b <__umoddi3+0x11b>
f0105c5a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105c5e:	73 0b                	jae    f0105c6b <__umoddi3+0x11b>
f0105c60:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105c64:	1b 14 24             	sbb    (%esp),%edx
f0105c67:	89 d1                	mov    %edx,%ecx
f0105c69:	89 c3                	mov    %eax,%ebx
f0105c6b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105c6f:	29 da                	sub    %ebx,%edx
f0105c71:	19 ce                	sbb    %ecx,%esi
f0105c73:	89 f9                	mov    %edi,%ecx
f0105c75:	89 f0                	mov    %esi,%eax
f0105c77:	d3 e0                	shl    %cl,%eax
f0105c79:	89 e9                	mov    %ebp,%ecx
f0105c7b:	d3 ea                	shr    %cl,%edx
f0105c7d:	89 e9                	mov    %ebp,%ecx
f0105c7f:	d3 ee                	shr    %cl,%esi
f0105c81:	09 d0                	or     %edx,%eax
f0105c83:	89 f2                	mov    %esi,%edx
f0105c85:	83 c4 1c             	add    $0x1c,%esp
f0105c88:	5b                   	pop    %ebx
f0105c89:	5e                   	pop    %esi
f0105c8a:	5f                   	pop    %edi
f0105c8b:	5d                   	pop    %ebp
f0105c8c:	c3                   	ret    
f0105c8d:	8d 76 00             	lea    0x0(%esi),%esi
f0105c90:	29 f9                	sub    %edi,%ecx
f0105c92:	19 d6                	sbb    %edx,%esi
f0105c94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105c98:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105c9c:	e9 18 ff ff ff       	jmp    f0105bb9 <__umoddi3+0x69>
