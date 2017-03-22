
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
f0100015:	b8 00 c0 11 00       	mov    $0x11c000,%eax
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
f0100034:	bc 00 c0 11 f0       	mov    $0xf011c000,%esp

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
f0100048:	83 3d 80 9e 22 f0 00 	cmpl   $0x0,0xf0229e80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 9e 22 f0    	mov    %esi,0xf0229e80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 d6 51 00 00       	call   f0105237 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 58 10 f0       	push   $0xf01058c0
f010006d:	e8 49 35 00 00       	call   f01035bb <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 19 35 00 00       	call   f0103595 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 29 6a 10 f0 	movl   $0xf0106a29,(%esp)
f0100083:	e8 33 35 00 00       	call   f01035bb <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 0a 08 00 00       	call   f010089f <monitor>
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
f01000a1:	b8 08 b0 26 f0       	mov    $0xf026b008,%eax
f01000a6:	2d b0 82 22 f0       	sub    $0xf02282b0,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 b0 82 22 f0       	push   $0xf02282b0
f01000b3:	e8 4a 4b 00 00       	call   f0104c02 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 a0 05 00 00       	call   f010065d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 59 10 f0       	push   $0xf010592c
f01000ca:	e8 ec 34 00 00       	call   f01035bb <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 52 11 00 00       	call   f0101226 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 47 2d 00 00       	call   f0102e20 <env_init>
	trap_init();
f01000d9:	e8 c3 35 00 00       	call   f01036a1 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 35 4e 00 00       	call   f0104f18 <mp_init>
	lapic_init();
f01000e3:	e8 6a 51 00 00       	call   f0105252 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 f5 33 00 00       	call   f01034e2 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 e3 11 f0 	movl   $0xf011e3c0,(%esp)
f01000f4:	e8 ac 53 00 00       	call   f01054a5 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 9e 22 f0 07 	cmpl   $0x7,0xf0229e88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 58 10 f0       	push   $0xf01058e4
f010010f:	6a 56                	push   $0x56
f0100111:	68 47 59 10 f0       	push   $0xf0105947
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 7e 4e 10 f0       	mov    $0xf0104e7e,%eax
f0100123:	2d 04 4e 10 f0       	sub    $0xf0104e04,%eax
f0100128:	50                   	push   %eax
f0100129:	68 04 4e 10 f0       	push   $0xf0104e04
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 17 4b 00 00       	call   f0104c4f <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 a0 22 f0       	mov    $0xf022a020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 f0 50 00 00       	call   f0105237 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 a0 22 f0       	sub    $0xf022a020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 30 23 f0       	add    $0xf0233000,%eax
f010016b:	a3 84 9e 22 f0       	mov    %eax,0xf0229e84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 1f 52 00 00       	call   f01053a0 <lapic_startap>
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
f010018f:	6b 05 c4 a3 22 f0 74 	imul   $0x74,0xf022a3c4,%eax
f0100196:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_idle, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 9c d9 18 f0       	push   $0xf018d99c
f01001a9:	e8 3e 2e 00 00       	call   f0102fec <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001ae:	83 c4 08             	add    $0x8,%esp
f01001b1:	6a 00                	push   $0x0
f01001b3:	68 9c 62 19 f0       	push   $0xf019629c
f01001b8:	e8 2f 2e 00 00       	call   f0102fec <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001bd:	83 c4 08             	add    $0x8,%esp
f01001c0:	6a 00                	push   $0x0
f01001c2:	68 9c 62 19 f0       	push   $0xf019629c
f01001c7:	e8 20 2e 00 00       	call   f0102fec <env_create>
	
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001cc:	e8 41 3d 00 00       	call   f0103f12 <sched_yield>

f01001d1 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001d7:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e1:	77 12                	ja     f01001f5 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e3:	50                   	push   %eax
f01001e4:	68 08 59 10 f0       	push   $0xf0105908
f01001e9:	6a 6d                	push   $0x6d
f01001eb:	68 47 59 10 f0       	push   $0xf0105947
f01001f0:	e8 4b fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001f5:	05 00 00 00 10       	add    $0x10000000,%eax
f01001fa:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001fd:	e8 35 50 00 00       	call   f0105237 <cpunum>
f0100202:	83 ec 08             	sub    $0x8,%esp
f0100205:	50                   	push   %eax
f0100206:	68 53 59 10 f0       	push   $0xf0105953
f010020b:	e8 ab 33 00 00       	call   f01035bb <cprintf>

	lapic_init();
f0100210:	e8 3d 50 00 00       	call   f0105252 <lapic_init>
	env_init_percpu();
f0100215:	e8 d6 2b 00 00       	call   f0102df0 <env_init_percpu>
	trap_init_percpu();
f010021a:	e8 b0 33 00 00       	call   f01035cf <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010021f:	e8 13 50 00 00       	call   f0105237 <cpunum>
f0100224:	6b d0 74             	imul   $0x74,%eax,%edx
f0100227:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010022d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100232:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100236:	c7 04 24 c0 e3 11 f0 	movl   $0xf011e3c0,(%esp)
f010023d:	e8 63 52 00 00       	call   f01054a5 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100242:	e8 cb 3c 00 00       	call   f0103f12 <sched_yield>

f0100247 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100247:	55                   	push   %ebp
f0100248:	89 e5                	mov    %esp,%ebp
f010024a:	53                   	push   %ebx
f010024b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010024e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100251:	ff 75 0c             	pushl  0xc(%ebp)
f0100254:	ff 75 08             	pushl  0x8(%ebp)
f0100257:	68 69 59 10 f0       	push   $0xf0105969
f010025c:	e8 5a 33 00 00       	call   f01035bb <cprintf>
	vcprintf(fmt, ap);
f0100261:	83 c4 08             	add    $0x8,%esp
f0100264:	53                   	push   %ebx
f0100265:	ff 75 10             	pushl  0x10(%ebp)
f0100268:	e8 28 33 00 00       	call   f0103595 <vcprintf>
	cprintf("\n");
f010026d:	c7 04 24 29 6a 10 f0 	movl   $0xf0106a29,(%esp)
f0100274:	e8 42 33 00 00       	call   f01035bb <cprintf>
	va_end(ap);
}
f0100279:	83 c4 10             	add    $0x10,%esp
f010027c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010027f:	c9                   	leave  
f0100280:	c3                   	ret    

f0100281 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100281:	55                   	push   %ebp
f0100282:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100284:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100289:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028a:	a8 01                	test   $0x1,%al
f010028c:	74 0b                	je     f0100299 <serial_proc_data+0x18>
f010028e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100293:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100294:	0f b6 c0             	movzbl %al,%eax
f0100297:	eb 05                	jmp    f010029e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 04             	sub    $0x4,%esp
f01002a7:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002a9:	eb 2b                	jmp    f01002d6 <cons_intr+0x36>
		if (c == 0)
f01002ab:	85 c0                	test   %eax,%eax
f01002ad:	74 27                	je     f01002d6 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002af:	8b 0d 24 92 22 f0    	mov    0xf0229224,%ecx
f01002b5:	8d 51 01             	lea    0x1(%ecx),%edx
f01002b8:	89 15 24 92 22 f0    	mov    %edx,0xf0229224
f01002be:	88 81 20 90 22 f0    	mov    %al,-0xfdd6fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002c4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ca:	75 0a                	jne    f01002d6 <cons_intr+0x36>
			cons.wpos = 0;
f01002cc:	c7 05 24 92 22 f0 00 	movl   $0x0,0xf0229224
f01002d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d6:	ff d3                	call   *%ebx
f01002d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002db:	75 ce                	jne    f01002ab <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002dd:	83 c4 04             	add    $0x4,%esp
f01002e0:	5b                   	pop    %ebx
f01002e1:	5d                   	pop    %ebp
f01002e2:	c3                   	ret    

f01002e3 <kbd_proc_data>:
f01002e3:	ba 64 00 00 00       	mov    $0x64,%edx
f01002e8:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002e9:	a8 01                	test   $0x1,%al
f01002eb:	0f 84 f8 00 00 00    	je     f01003e9 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002f1:	a8 20                	test   $0x20,%al
f01002f3:	0f 85 f6 00 00 00    	jne    f01003ef <kbd_proc_data+0x10c>
f01002f9:	ba 60 00 00 00       	mov    $0x60,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100301:	3c e0                	cmp    $0xe0,%al
f0100303:	75 0d                	jne    f0100312 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f0100305:	83 0d 00 90 22 f0 40 	orl    $0x40,0xf0229000
		return 0;
f010030c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100311:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100312:	55                   	push   %ebp
f0100313:	89 e5                	mov    %esp,%ebp
f0100315:	53                   	push   %ebx
f0100316:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100319:	84 c0                	test   %al,%al
f010031b:	79 36                	jns    f0100353 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010031d:	8b 0d 00 90 22 f0    	mov    0xf0229000,%ecx
f0100323:	89 cb                	mov    %ecx,%ebx
f0100325:	83 e3 40             	and    $0x40,%ebx
f0100328:	83 e0 7f             	and    $0x7f,%eax
f010032b:	85 db                	test   %ebx,%ebx
f010032d:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100330:	0f b6 d2             	movzbl %dl,%edx
f0100333:	0f b6 82 e0 5a 10 f0 	movzbl -0xfefa520(%edx),%eax
f010033a:	83 c8 40             	or     $0x40,%eax
f010033d:	0f b6 c0             	movzbl %al,%eax
f0100340:	f7 d0                	not    %eax
f0100342:	21 c8                	and    %ecx,%eax
f0100344:	a3 00 90 22 f0       	mov    %eax,0xf0229000
		return 0;
f0100349:	b8 00 00 00 00       	mov    $0x0,%eax
f010034e:	e9 a4 00 00 00       	jmp    f01003f7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100353:	8b 0d 00 90 22 f0    	mov    0xf0229000,%ecx
f0100359:	f6 c1 40             	test   $0x40,%cl
f010035c:	74 0e                	je     f010036c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010035e:	83 c8 80             	or     $0xffffff80,%eax
f0100361:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100363:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100366:	89 0d 00 90 22 f0    	mov    %ecx,0xf0229000
	}

	shift |= shiftcode[data];
f010036c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010036f:	0f b6 82 e0 5a 10 f0 	movzbl -0xfefa520(%edx),%eax
f0100376:	0b 05 00 90 22 f0    	or     0xf0229000,%eax
f010037c:	0f b6 8a e0 59 10 f0 	movzbl -0xfefa620(%edx),%ecx
f0100383:	31 c8                	xor    %ecx,%eax
f0100385:	a3 00 90 22 f0       	mov    %eax,0xf0229000

	c = charcode[shift & (CTL | SHIFT)][data];
f010038a:	89 c1                	mov    %eax,%ecx
f010038c:	83 e1 03             	and    $0x3,%ecx
f010038f:	8b 0c 8d c0 59 10 f0 	mov    -0xfefa640(,%ecx,4),%ecx
f0100396:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010039a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010039d:	a8 08                	test   $0x8,%al
f010039f:	74 1b                	je     f01003bc <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f01003a1:	89 da                	mov    %ebx,%edx
f01003a3:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003a6:	83 f9 19             	cmp    $0x19,%ecx
f01003a9:	77 05                	ja     f01003b0 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01003ab:	83 eb 20             	sub    $0x20,%ebx
f01003ae:	eb 0c                	jmp    f01003bc <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01003b0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003b3:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003b6:	83 fa 19             	cmp    $0x19,%edx
f01003b9:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003bc:	f7 d0                	not    %eax
f01003be:	a8 06                	test   $0x6,%al
f01003c0:	75 33                	jne    f01003f5 <kbd_proc_data+0x112>
f01003c2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003c8:	75 2b                	jne    f01003f5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ca:	83 ec 0c             	sub    $0xc,%esp
f01003cd:	68 83 59 10 f0       	push   $0xf0105983
f01003d2:	e8 e4 31 00 00       	call   f01035bb <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d7:	ba 92 00 00 00       	mov    $0x92,%edx
f01003dc:	b8 03 00 00 00       	mov    $0x3,%eax
f01003e1:	ee                   	out    %al,(%dx)
f01003e2:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003e5:	89 d8                	mov    %ebx,%eax
f01003e7:	eb 0e                	jmp    f01003f7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003ee:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003f4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f5:	89 d8                	mov    %ebx,%eax
}
f01003f7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003fa:	c9                   	leave  
f01003fb:	c3                   	ret    

f01003fc <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003fc:	55                   	push   %ebp
f01003fd:	89 e5                	mov    %esp,%ebp
f01003ff:	57                   	push   %edi
f0100400:	56                   	push   %esi
f0100401:	53                   	push   %ebx
f0100402:	83 ec 1c             	sub    $0x1c,%esp
f0100405:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100407:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010040c:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100411:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100416:	eb 09                	jmp    f0100421 <cons_putc+0x25>
f0100418:	89 ca                	mov    %ecx,%edx
f010041a:	ec                   	in     (%dx),%al
f010041b:	ec                   	in     (%dx),%al
f010041c:	ec                   	in     (%dx),%al
f010041d:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f010041e:	83 c3 01             	add    $0x1,%ebx
f0100421:	89 f2                	mov    %esi,%edx
f0100423:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100424:	a8 20                	test   $0x20,%al
f0100426:	75 08                	jne    f0100430 <cons_putc+0x34>
f0100428:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010042e:	7e e8                	jle    f0100418 <cons_putc+0x1c>
f0100430:	89 f8                	mov    %edi,%eax
f0100432:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100435:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010043a:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010043b:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100440:	be 79 03 00 00       	mov    $0x379,%esi
f0100445:	b9 84 00 00 00       	mov    $0x84,%ecx
f010044a:	eb 09                	jmp    f0100455 <cons_putc+0x59>
f010044c:	89 ca                	mov    %ecx,%edx
f010044e:	ec                   	in     (%dx),%al
f010044f:	ec                   	in     (%dx),%al
f0100450:	ec                   	in     (%dx),%al
f0100451:	ec                   	in     (%dx),%al
f0100452:	83 c3 01             	add    $0x1,%ebx
f0100455:	89 f2                	mov    %esi,%edx
f0100457:	ec                   	in     (%dx),%al
f0100458:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010045e:	7f 04                	jg     f0100464 <cons_putc+0x68>
f0100460:	84 c0                	test   %al,%al
f0100462:	79 e8                	jns    f010044c <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100464:	ba 78 03 00 00       	mov    $0x378,%edx
f0100469:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010046d:	ee                   	out    %al,(%dx)
f010046e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100473:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100478:	ee                   	out    %al,(%dx)
f0100479:	b8 08 00 00 00       	mov    $0x8,%eax
f010047e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010047f:	89 fa                	mov    %edi,%edx
f0100481:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100487:	89 f8                	mov    %edi,%eax
f0100489:	80 cc 07             	or     $0x7,%ah
f010048c:	85 d2                	test   %edx,%edx
f010048e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100491:	89 f8                	mov    %edi,%eax
f0100493:	0f b6 c0             	movzbl %al,%eax
f0100496:	83 f8 09             	cmp    $0x9,%eax
f0100499:	74 74                	je     f010050f <cons_putc+0x113>
f010049b:	83 f8 09             	cmp    $0x9,%eax
f010049e:	7f 0a                	jg     f01004aa <cons_putc+0xae>
f01004a0:	83 f8 08             	cmp    $0x8,%eax
f01004a3:	74 14                	je     f01004b9 <cons_putc+0xbd>
f01004a5:	e9 99 00 00 00       	jmp    f0100543 <cons_putc+0x147>
f01004aa:	83 f8 0a             	cmp    $0xa,%eax
f01004ad:	74 3a                	je     f01004e9 <cons_putc+0xed>
f01004af:	83 f8 0d             	cmp    $0xd,%eax
f01004b2:	74 3d                	je     f01004f1 <cons_putc+0xf5>
f01004b4:	e9 8a 00 00 00       	jmp    f0100543 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004b9:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f01004c0:	66 85 c0             	test   %ax,%ax
f01004c3:	0f 84 e6 00 00 00    	je     f01005af <cons_putc+0x1b3>
			crt_pos--;
f01004c9:	83 e8 01             	sub    $0x1,%eax
f01004cc:	66 a3 28 92 22 f0    	mov    %ax,0xf0229228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d2:	0f b7 c0             	movzwl %ax,%eax
f01004d5:	66 81 e7 00 ff       	and    $0xff00,%di
f01004da:	83 cf 20             	or     $0x20,%edi
f01004dd:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
f01004e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004e7:	eb 78                	jmp    f0100561 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004e9:	66 83 05 28 92 22 f0 	addw   $0x50,0xf0229228
f01004f0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004f1:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f01004f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004fe:	c1 e8 16             	shr    $0x16,%eax
f0100501:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100504:	c1 e0 04             	shl    $0x4,%eax
f0100507:	66 a3 28 92 22 f0    	mov    %ax,0xf0229228
f010050d:	eb 52                	jmp    f0100561 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 e3 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 d9 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100523:	b8 20 00 00 00       	mov    $0x20,%eax
f0100528:	e8 cf fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f010052d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100532:	e8 c5 fe ff ff       	call   f01003fc <cons_putc>
		cons_putc(' ');
f0100537:	b8 20 00 00 00       	mov    $0x20,%eax
f010053c:	e8 bb fe ff ff       	call   f01003fc <cons_putc>
f0100541:	eb 1e                	jmp    f0100561 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100543:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f010054a:	8d 50 01             	lea    0x1(%eax),%edx
f010054d:	66 89 15 28 92 22 f0 	mov    %dx,0xf0229228
f0100554:	0f b7 c0             	movzwl %ax,%eax
f0100557:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
f010055d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100561:	66 81 3d 28 92 22 f0 	cmpw   $0x7cf,0xf0229228
f0100568:	cf 07 
f010056a:	76 43                	jbe    f01005af <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010056c:	a1 2c 92 22 f0       	mov    0xf022922c,%eax
f0100571:	83 ec 04             	sub    $0x4,%esp
f0100574:	68 00 0f 00 00       	push   $0xf00
f0100579:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010057f:	52                   	push   %edx
f0100580:	50                   	push   %eax
f0100581:	e8 c9 46 00 00       	call   f0104c4f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100586:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
f010058c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100592:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100598:	83 c4 10             	add    $0x10,%esp
f010059b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005a0:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005a3:	39 d0                	cmp    %edx,%eax
f01005a5:	75 f4                	jne    f010059b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005a7:	66 83 2d 28 92 22 f0 	subw   $0x50,0xf0229228
f01005ae:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005af:	8b 0d 30 92 22 f0    	mov    0xf0229230,%ecx
f01005b5:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ba:	89 ca                	mov    %ecx,%edx
f01005bc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005bd:	0f b7 1d 28 92 22 f0 	movzwl 0xf0229228,%ebx
f01005c4:	8d 71 01             	lea    0x1(%ecx),%esi
f01005c7:	89 d8                	mov    %ebx,%eax
f01005c9:	66 c1 e8 08          	shr    $0x8,%ax
f01005cd:	89 f2                	mov    %esi,%edx
f01005cf:	ee                   	out    %al,(%dx)
f01005d0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d5:	89 ca                	mov    %ecx,%edx
f01005d7:	ee                   	out    %al,(%dx)
f01005d8:	89 d8                	mov    %ebx,%eax
f01005da:	89 f2                	mov    %esi,%edx
f01005dc:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005e0:	5b                   	pop    %ebx
f01005e1:	5e                   	pop    %esi
f01005e2:	5f                   	pop    %edi
f01005e3:	5d                   	pop    %ebp
f01005e4:	c3                   	ret    

f01005e5 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005e5:	80 3d 34 92 22 f0 00 	cmpb   $0x0,0xf0229234
f01005ec:	74 11                	je     f01005ff <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005ee:	55                   	push   %ebp
f01005ef:	89 e5                	mov    %esp,%ebp
f01005f1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005f4:	b8 81 02 10 f0       	mov    $0xf0100281,%eax
f01005f9:	e8 a2 fc ff ff       	call   f01002a0 <cons_intr>
}
f01005fe:	c9                   	leave  
f01005ff:	f3 c3                	repz ret 

f0100601 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100607:	b8 e3 02 10 f0       	mov    $0xf01002e3,%eax
f010060c:	e8 8f fc ff ff       	call   f01002a0 <cons_intr>
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
f0100616:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100619:	e8 c7 ff ff ff       	call   f01005e5 <serial_intr>
	kbd_intr();
f010061e:	e8 de ff ff ff       	call   f0100601 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100623:	a1 20 92 22 f0       	mov    0xf0229220,%eax
f0100628:	3b 05 24 92 22 f0    	cmp    0xf0229224,%eax
f010062e:	74 26                	je     f0100656 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100630:	8d 50 01             	lea    0x1(%eax),%edx
f0100633:	89 15 20 92 22 f0    	mov    %edx,0xf0229220
f0100639:	0f b6 88 20 90 22 f0 	movzbl -0xfdd6fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100640:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100642:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100648:	75 11                	jne    f010065b <cons_getc+0x48>
			cons.rpos = 0;
f010064a:	c7 05 20 92 22 f0 00 	movl   $0x0,0xf0229220
f0100651:	00 00 00 
f0100654:	eb 05                	jmp    f010065b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100656:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	57                   	push   %edi
f0100661:	56                   	push   %esi
f0100662:	53                   	push   %ebx
f0100663:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100666:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010066d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100674:	5a a5 
	if (*cp != 0xA55A) {
f0100676:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010067d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100681:	74 11                	je     f0100694 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100683:	c7 05 30 92 22 f0 b4 	movl   $0x3b4,0xf0229230
f010068a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010068d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100692:	eb 16                	jmp    f01006aa <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100694:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069b:	c7 05 30 92 22 f0 d4 	movl   $0x3d4,0xf0229230
f01006a2:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a5:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006aa:	8b 3d 30 92 22 f0    	mov    0xf0229230,%edi
f01006b0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006b5:	89 fa                	mov    %edi,%edx
f01006b7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006b8:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bb:	89 da                	mov    %ebx,%edx
f01006bd:	ec                   	in     (%dx),%al
f01006be:	0f b6 c8             	movzbl %al,%ecx
f01006c1:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006c9:	89 fa                	mov    %edi,%edx
f01006cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006cc:	89 da                	mov    %ebx,%edx
f01006ce:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006cf:	89 35 2c 92 22 f0    	mov    %esi,0xf022922c
	crt_pos = pos;
f01006d5:	0f b6 c0             	movzbl %al,%eax
f01006d8:	09 c8                	or     %ecx,%eax
f01006da:	66 a3 28 92 22 f0    	mov    %ax,0xf0229228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006e0:	e8 1c ff ff ff       	call   f0100601 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006e5:	83 ec 0c             	sub    $0xc,%esp
f01006e8:	0f b7 05 a8 e3 11 f0 	movzwl 0xf011e3a8,%eax
f01006ef:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006f4:	50                   	push   %eax
f01006f5:	e8 70 2d 00 00       	call   f010346a <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006fa:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0100704:	89 f2                	mov    %esi,%edx
f0100706:	ee                   	out    %al,(%dx)
f0100707:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010070c:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100711:	ee                   	out    %al,(%dx)
f0100712:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100717:	b8 0c 00 00 00       	mov    $0xc,%eax
f010071c:	89 da                	mov    %ebx,%edx
f010071e:	ee                   	out    %al,(%dx)
f010071f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100724:	b8 00 00 00 00       	mov    $0x0,%eax
f0100729:	ee                   	out    %al,(%dx)
f010072a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010072f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100734:	ee                   	out    %al,(%dx)
f0100735:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010073a:	b8 00 00 00 00       	mov    $0x0,%eax
f010073f:	ee                   	out    %al,(%dx)
f0100740:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100745:	b8 01 00 00 00       	mov    $0x1,%eax
f010074a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010074b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100750:	ec                   	in     (%dx),%al
f0100751:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100753:	83 c4 10             	add    $0x10,%esp
f0100756:	3c ff                	cmp    $0xff,%al
f0100758:	0f 95 05 34 92 22 f0 	setne  0xf0229234
f010075f:	89 f2                	mov    %esi,%edx
f0100761:	ec                   	in     (%dx),%al
f0100762:	89 da                	mov    %ebx,%edx
f0100764:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100765:	80 f9 ff             	cmp    $0xff,%cl
f0100768:	75 10                	jne    f010077a <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010076a:	83 ec 0c             	sub    $0xc,%esp
f010076d:	68 8f 59 10 f0       	push   $0xf010598f
f0100772:	e8 44 2e 00 00       	call   f01035bb <cprintf>
f0100777:	83 c4 10             	add    $0x10,%esp
}
f010077a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010077d:	5b                   	pop    %ebx
f010077e:	5e                   	pop    %esi
f010077f:	5f                   	pop    %edi
f0100780:	5d                   	pop    %ebp
f0100781:	c3                   	ret    

f0100782 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100782:	55                   	push   %ebp
f0100783:	89 e5                	mov    %esp,%ebp
f0100785:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100788:	8b 45 08             	mov    0x8(%ebp),%eax
f010078b:	e8 6c fc ff ff       	call   f01003fc <cons_putc>
}
f0100790:	c9                   	leave  
f0100791:	c3                   	ret    

f0100792 <getchar>:

int
getchar(void)
{
f0100792:	55                   	push   %ebp
f0100793:	89 e5                	mov    %esp,%ebp
f0100795:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100798:	e8 76 fe ff ff       	call   f0100613 <cons_getc>
f010079d:	85 c0                	test   %eax,%eax
f010079f:	74 f7                	je     f0100798 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a1:	c9                   	leave  
f01007a2:	c3                   	ret    

f01007a3 <iscons>:

int
iscons(int fdnum)
{
f01007a3:	55                   	push   %ebp
f01007a4:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01007ab:	5d                   	pop    %ebp
f01007ac:	c3                   	ret    

f01007ad <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007ad:	55                   	push   %ebp
f01007ae:	89 e5                	mov    %esp,%ebp
f01007b0:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007b3:	68 e0 5b 10 f0       	push   $0xf0105be0
f01007b8:	68 fe 5b 10 f0       	push   $0xf0105bfe
f01007bd:	68 03 5c 10 f0       	push   $0xf0105c03
f01007c2:	e8 f4 2d 00 00       	call   f01035bb <cprintf>
f01007c7:	83 c4 0c             	add    $0xc,%esp
f01007ca:	68 6c 5c 10 f0       	push   $0xf0105c6c
f01007cf:	68 0c 5c 10 f0       	push   $0xf0105c0c
f01007d4:	68 03 5c 10 f0       	push   $0xf0105c03
f01007d9:	e8 dd 2d 00 00       	call   f01035bb <cprintf>
	return 0;
}
f01007de:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e3:	c9                   	leave  
f01007e4:	c3                   	ret    

f01007e5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007eb:	68 15 5c 10 f0       	push   $0xf0105c15
f01007f0:	e8 c6 2d 00 00       	call   f01035bb <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007f5:	83 c4 08             	add    $0x8,%esp
f01007f8:	68 0c 00 10 00       	push   $0x10000c
f01007fd:	68 94 5c 10 f0       	push   $0xf0105c94
f0100802:	e8 b4 2d 00 00       	call   f01035bb <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100807:	83 c4 0c             	add    $0xc,%esp
f010080a:	68 0c 00 10 00       	push   $0x10000c
f010080f:	68 0c 00 10 f0       	push   $0xf010000c
f0100814:	68 bc 5c 10 f0       	push   $0xf0105cbc
f0100819:	e8 9d 2d 00 00       	call   f01035bb <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010081e:	83 c4 0c             	add    $0xc,%esp
f0100821:	68 b1 58 10 00       	push   $0x1058b1
f0100826:	68 b1 58 10 f0       	push   $0xf01058b1
f010082b:	68 e0 5c 10 f0       	push   $0xf0105ce0
f0100830:	e8 86 2d 00 00       	call   f01035bb <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 b0 82 22 00       	push   $0x2282b0
f010083d:	68 b0 82 22 f0       	push   $0xf02282b0
f0100842:	68 04 5d 10 f0       	push   $0xf0105d04
f0100847:	e8 6f 2d 00 00       	call   f01035bb <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 08 b0 26 00       	push   $0x26b008
f0100854:	68 08 b0 26 f0       	push   $0xf026b008
f0100859:	68 28 5d 10 f0       	push   $0xf0105d28
f010085e:	e8 58 2d 00 00       	call   f01035bb <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100863:	b8 07 b4 26 f0       	mov    $0xf026b407,%eax
f0100868:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010086d:	83 c4 08             	add    $0x8,%esp
f0100870:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100875:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010087b:	85 c0                	test   %eax,%eax
f010087d:	0f 48 c2             	cmovs  %edx,%eax
f0100880:	c1 f8 0a             	sar    $0xa,%eax
f0100883:	50                   	push   %eax
f0100884:	68 4c 5d 10 f0       	push   $0xf0105d4c
f0100889:	e8 2d 2d 00 00       	call   f01035bb <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010088e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100893:	c9                   	leave  
f0100894:	c3                   	ret    

f0100895 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100895:	55                   	push   %ebp
f0100896:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100898:	b8 00 00 00 00       	mov    $0x0,%eax
f010089d:	5d                   	pop    %ebp
f010089e:	c3                   	ret    

f010089f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010089f:	55                   	push   %ebp
f01008a0:	89 e5                	mov    %esp,%ebp
f01008a2:	57                   	push   %edi
f01008a3:	56                   	push   %esi
f01008a4:	53                   	push   %ebx
f01008a5:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008a8:	68 78 5d 10 f0       	push   $0xf0105d78
f01008ad:	e8 09 2d 00 00       	call   f01035bb <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008b2:	c7 04 24 9c 5d 10 f0 	movl   $0xf0105d9c,(%esp)
f01008b9:	e8 fd 2c 00 00       	call   f01035bb <cprintf>

	if (tf != NULL)
f01008be:	83 c4 10             	add    $0x10,%esp
f01008c1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008c5:	74 0e                	je     f01008d5 <monitor+0x36>
		print_trapframe(tf);
f01008c7:	83 ec 0c             	sub    $0xc,%esp
f01008ca:	ff 75 08             	pushl  0x8(%ebp)
f01008cd:	e8 0b 31 00 00       	call   f01039dd <print_trapframe>
f01008d2:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01008d5:	83 ec 0c             	sub    $0xc,%esp
f01008d8:	68 2e 5c 10 f0       	push   $0xf0105c2e
f01008dd:	e8 c9 40 00 00       	call   f01049ab <readline>
f01008e2:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008e4:	83 c4 10             	add    $0x10,%esp
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 ea                	je     f01008d5 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008eb:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008f2:	be 00 00 00 00       	mov    $0x0,%esi
f01008f7:	eb 0a                	jmp    f0100903 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008f9:	c6 03 00             	movb   $0x0,(%ebx)
f01008fc:	89 f7                	mov    %esi,%edi
f01008fe:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100901:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100903:	0f b6 03             	movzbl (%ebx),%eax
f0100906:	84 c0                	test   %al,%al
f0100908:	74 63                	je     f010096d <monitor+0xce>
f010090a:	83 ec 08             	sub    $0x8,%esp
f010090d:	0f be c0             	movsbl %al,%eax
f0100910:	50                   	push   %eax
f0100911:	68 32 5c 10 f0       	push   $0xf0105c32
f0100916:	e8 aa 42 00 00       	call   f0104bc5 <strchr>
f010091b:	83 c4 10             	add    $0x10,%esp
f010091e:	85 c0                	test   %eax,%eax
f0100920:	75 d7                	jne    f01008f9 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100922:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100925:	74 46                	je     f010096d <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100927:	83 fe 0f             	cmp    $0xf,%esi
f010092a:	75 14                	jne    f0100940 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010092c:	83 ec 08             	sub    $0x8,%esp
f010092f:	6a 10                	push   $0x10
f0100931:	68 37 5c 10 f0       	push   $0xf0105c37
f0100936:	e8 80 2c 00 00       	call   f01035bb <cprintf>
f010093b:	83 c4 10             	add    $0x10,%esp
f010093e:	eb 95                	jmp    f01008d5 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100940:	8d 7e 01             	lea    0x1(%esi),%edi
f0100943:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100947:	eb 03                	jmp    f010094c <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100949:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010094c:	0f b6 03             	movzbl (%ebx),%eax
f010094f:	84 c0                	test   %al,%al
f0100951:	74 ae                	je     f0100901 <monitor+0x62>
f0100953:	83 ec 08             	sub    $0x8,%esp
f0100956:	0f be c0             	movsbl %al,%eax
f0100959:	50                   	push   %eax
f010095a:	68 32 5c 10 f0       	push   $0xf0105c32
f010095f:	e8 61 42 00 00       	call   f0104bc5 <strchr>
f0100964:	83 c4 10             	add    $0x10,%esp
f0100967:	85 c0                	test   %eax,%eax
f0100969:	74 de                	je     f0100949 <monitor+0xaa>
f010096b:	eb 94                	jmp    f0100901 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f010096d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100974:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100975:	85 f6                	test   %esi,%esi
f0100977:	0f 84 58 ff ff ff    	je     f01008d5 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010097d:	83 ec 08             	sub    $0x8,%esp
f0100980:	68 fe 5b 10 f0       	push   $0xf0105bfe
f0100985:	ff 75 a8             	pushl  -0x58(%ebp)
f0100988:	e8 da 41 00 00       	call   f0104b67 <strcmp>
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	85 c0                	test   %eax,%eax
f0100992:	74 1e                	je     f01009b2 <monitor+0x113>
f0100994:	83 ec 08             	sub    $0x8,%esp
f0100997:	68 0c 5c 10 f0       	push   $0xf0105c0c
f010099c:	ff 75 a8             	pushl  -0x58(%ebp)
f010099f:	e8 c3 41 00 00       	call   f0104b67 <strcmp>
f01009a4:	83 c4 10             	add    $0x10,%esp
f01009a7:	85 c0                	test   %eax,%eax
f01009a9:	75 2f                	jne    f01009da <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009ab:	b8 01 00 00 00       	mov    $0x1,%eax
f01009b0:	eb 05                	jmp    f01009b7 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009b2:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01009b7:	83 ec 04             	sub    $0x4,%esp
f01009ba:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009bd:	01 d0                	add    %edx,%eax
f01009bf:	ff 75 08             	pushl  0x8(%ebp)
f01009c2:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01009c5:	51                   	push   %ecx
f01009c6:	56                   	push   %esi
f01009c7:	ff 14 85 cc 5d 10 f0 	call   *-0xfefa234(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009ce:	83 c4 10             	add    $0x10,%esp
f01009d1:	85 c0                	test   %eax,%eax
f01009d3:	78 1d                	js     f01009f2 <monitor+0x153>
f01009d5:	e9 fb fe ff ff       	jmp    f01008d5 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009da:	83 ec 08             	sub    $0x8,%esp
f01009dd:	ff 75 a8             	pushl  -0x58(%ebp)
f01009e0:	68 54 5c 10 f0       	push   $0xf0105c54
f01009e5:	e8 d1 2b 00 00       	call   f01035bb <cprintf>
f01009ea:	83 c4 10             	add    $0x10,%esp
f01009ed:	e9 e3 fe ff ff       	jmp    f01008d5 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009f5:	5b                   	pop    %ebx
f01009f6:	5e                   	pop    %esi
f01009f7:	5f                   	pop    %edi
f01009f8:	5d                   	pop    %ebp
f01009f9:	c3                   	ret    

f01009fa <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009fa:	55                   	push   %ebp
f01009fb:	89 e5                	mov    %esp,%ebp
f01009fd:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009ff:	83 3d 38 92 22 f0 00 	cmpl   $0x0,0xf0229238
f0100a06:	75 0f                	jne    f0100a17 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a08:	b8 07 c0 26 f0       	mov    $0xf026c007,%eax
f0100a0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a12:	a3 38 92 22 f0       	mov    %eax,0xf0229238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a17:	a1 38 92 22 f0       	mov    0xf0229238,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f0100a1c:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100a22:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a28:	01 c2                	add    %eax,%edx
f0100a2a:	89 15 38 92 22 f0    	mov    %edx,0xf0229238
	return result;
}
f0100a30:	5d                   	pop    %ebp
f0100a31:	c3                   	ret    

f0100a32 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a32:	55                   	push   %ebp
f0100a33:	89 e5                	mov    %esp,%ebp
f0100a35:	56                   	push   %esi
f0100a36:	53                   	push   %ebx
f0100a37:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a39:	83 ec 0c             	sub    $0xc,%esp
f0100a3c:	50                   	push   %eax
f0100a3d:	e8 fa 29 00 00       	call   f010343c <mc146818_read>
f0100a42:	89 c6                	mov    %eax,%esi
f0100a44:	83 c3 01             	add    $0x1,%ebx
f0100a47:	89 1c 24             	mov    %ebx,(%esp)
f0100a4a:	e8 ed 29 00 00       	call   f010343c <mc146818_read>
f0100a4f:	c1 e0 08             	shl    $0x8,%eax
f0100a52:	09 f0                	or     %esi,%eax
}
f0100a54:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a57:	5b                   	pop    %ebx
f0100a58:	5e                   	pop    %esi
f0100a59:	5d                   	pop    %ebp
f0100a5a:	c3                   	ret    

f0100a5b <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a5b:	89 d1                	mov    %edx,%ecx
f0100a5d:	c1 e9 16             	shr    $0x16,%ecx
f0100a60:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a63:	a8 01                	test   $0x1,%al
f0100a65:	74 52                	je     f0100ab9 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a67:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a6c:	89 c1                	mov    %eax,%ecx
f0100a6e:	c1 e9 0c             	shr    $0xc,%ecx
f0100a71:	3b 0d 88 9e 22 f0    	cmp    0xf0229e88,%ecx
f0100a77:	72 1b                	jb     f0100a94 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a79:	55                   	push   %ebp
f0100a7a:	89 e5                	mov    %esp,%ebp
f0100a7c:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a7f:	50                   	push   %eax
f0100a80:	68 e4 58 10 f0       	push   $0xf01058e4
f0100a85:	68 94 03 00 00       	push   $0x394
f0100a8a:	68 49 67 10 f0       	push   $0xf0106749
f0100a8f:	e8 ac f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a94:	c1 ea 0c             	shr    $0xc,%edx
f0100a97:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a9d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aa4:	89 c2                	mov    %eax,%edx
f0100aa6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aa9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aae:	85 d2                	test   %edx,%edx
f0100ab0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ab5:	0f 44 c2             	cmove  %edx,%eax
f0100ab8:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100ab9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100abe:	c3                   	ret    

f0100abf <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100abf:	55                   	push   %ebp
f0100ac0:	89 e5                	mov    %esp,%ebp
f0100ac2:	57                   	push   %edi
f0100ac3:	56                   	push   %esi
f0100ac4:	53                   	push   %ebx
f0100ac5:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ac8:	84 c0                	test   %al,%al
f0100aca:	0f 85 a0 02 00 00    	jne    f0100d70 <check_page_free_list+0x2b1>
f0100ad0:	e9 ad 02 00 00       	jmp    f0100d82 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ad5:	83 ec 04             	sub    $0x4,%esp
f0100ad8:	68 dc 5d 10 f0       	push   $0xf0105ddc
f0100add:	68 c7 02 00 00       	push   $0x2c7
f0100ae2:	68 49 67 10 f0       	push   $0xf0106749
f0100ae7:	e8 54 f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aec:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aef:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100af2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100af8:	89 c2                	mov    %eax,%edx
f0100afa:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f0100b00:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b06:	0f 95 c2             	setne  %dl
f0100b09:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b0c:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b10:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b12:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b16:	8b 00                	mov    (%eax),%eax
f0100b18:	85 c0                	test   %eax,%eax
f0100b1a:	75 dc                	jne    f0100af8 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b1f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b28:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b2b:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b2d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b30:	a3 40 92 22 f0       	mov    %eax,0xf0229240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b35:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b3a:	8b 1d 40 92 22 f0    	mov    0xf0229240,%ebx
f0100b40:	eb 53                	jmp    f0100b95 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b42:	89 d8                	mov    %ebx,%eax
f0100b44:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0100b4a:	c1 f8 03             	sar    $0x3,%eax
f0100b4d:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b50:	89 c2                	mov    %eax,%edx
f0100b52:	c1 ea 16             	shr    $0x16,%edx
f0100b55:	39 f2                	cmp    %esi,%edx
f0100b57:	73 3a                	jae    f0100b93 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b59:	89 c2                	mov    %eax,%edx
f0100b5b:	c1 ea 0c             	shr    $0xc,%edx
f0100b5e:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0100b64:	72 12                	jb     f0100b78 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b66:	50                   	push   %eax
f0100b67:	68 e4 58 10 f0       	push   $0xf01058e4
f0100b6c:	6a 58                	push   $0x58
f0100b6e:	68 55 67 10 f0       	push   $0xf0106755
f0100b73:	e8 c8 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b78:	83 ec 04             	sub    $0x4,%esp
f0100b7b:	68 80 00 00 00       	push   $0x80
f0100b80:	68 97 00 00 00       	push   $0x97
f0100b85:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b8a:	50                   	push   %eax
f0100b8b:	e8 72 40 00 00       	call   f0104c02 <memset>
f0100b90:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b93:	8b 1b                	mov    (%ebx),%ebx
f0100b95:	85 db                	test   %ebx,%ebx
f0100b97:	75 a9                	jne    f0100b42 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b99:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9e:	e8 57 fe ff ff       	call   f01009fa <boot_alloc>
f0100ba3:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba6:	8b 15 40 92 22 f0    	mov    0xf0229240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bac:	8b 0d 90 9e 22 f0    	mov    0xf0229e90,%ecx
		assert(pp < pages + npages);
f0100bb2:	a1 88 9e 22 f0       	mov    0xf0229e88,%eax
f0100bb7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100bba:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bbd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bc0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bc3:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bc8:	e9 52 01 00 00       	jmp    f0100d1f <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bcd:	39 ca                	cmp    %ecx,%edx
f0100bcf:	73 19                	jae    f0100bea <check_page_free_list+0x12b>
f0100bd1:	68 63 67 10 f0       	push   $0xf0106763
f0100bd6:	68 6f 67 10 f0       	push   $0xf010676f
f0100bdb:	68 e1 02 00 00       	push   $0x2e1
f0100be0:	68 49 67 10 f0       	push   $0xf0106749
f0100be5:	e8 56 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bea:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bed:	72 19                	jb     f0100c08 <check_page_free_list+0x149>
f0100bef:	68 84 67 10 f0       	push   $0xf0106784
f0100bf4:	68 6f 67 10 f0       	push   $0xf010676f
f0100bf9:	68 e2 02 00 00       	push   $0x2e2
f0100bfe:	68 49 67 10 f0       	push   $0xf0106749
f0100c03:	e8 38 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c08:	89 d0                	mov    %edx,%eax
f0100c0a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c0d:	a8 07                	test   $0x7,%al
f0100c0f:	74 19                	je     f0100c2a <check_page_free_list+0x16b>
f0100c11:	68 00 5e 10 f0       	push   $0xf0105e00
f0100c16:	68 6f 67 10 f0       	push   $0xf010676f
f0100c1b:	68 e3 02 00 00       	push   $0x2e3
f0100c20:	68 49 67 10 f0       	push   $0xf0106749
f0100c25:	e8 16 f4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c2a:	c1 f8 03             	sar    $0x3,%eax
f0100c2d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c30:	85 c0                	test   %eax,%eax
f0100c32:	75 19                	jne    f0100c4d <check_page_free_list+0x18e>
f0100c34:	68 98 67 10 f0       	push   $0xf0106798
f0100c39:	68 6f 67 10 f0       	push   $0xf010676f
f0100c3e:	68 e6 02 00 00       	push   $0x2e6
f0100c43:	68 49 67 10 f0       	push   $0xf0106749
f0100c48:	e8 f3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c4d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c52:	75 19                	jne    f0100c6d <check_page_free_list+0x1ae>
f0100c54:	68 a9 67 10 f0       	push   $0xf01067a9
f0100c59:	68 6f 67 10 f0       	push   $0xf010676f
f0100c5e:	68 e7 02 00 00       	push   $0x2e7
f0100c63:	68 49 67 10 f0       	push   $0xf0106749
f0100c68:	e8 d3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c6d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c72:	75 19                	jne    f0100c8d <check_page_free_list+0x1ce>
f0100c74:	68 34 5e 10 f0       	push   $0xf0105e34
f0100c79:	68 6f 67 10 f0       	push   $0xf010676f
f0100c7e:	68 e8 02 00 00       	push   $0x2e8
f0100c83:	68 49 67 10 f0       	push   $0xf0106749
f0100c88:	e8 b3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c8d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c92:	75 19                	jne    f0100cad <check_page_free_list+0x1ee>
f0100c94:	68 c2 67 10 f0       	push   $0xf01067c2
f0100c99:	68 6f 67 10 f0       	push   $0xf010676f
f0100c9e:	68 e9 02 00 00       	push   $0x2e9
f0100ca3:	68 49 67 10 f0       	push   $0xf0106749
f0100ca8:	e8 93 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cad:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cb2:	0f 86 f1 00 00 00    	jbe    f0100da9 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cb8:	89 c7                	mov    %eax,%edi
f0100cba:	c1 ef 0c             	shr    $0xc,%edi
f0100cbd:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100cc0:	77 12                	ja     f0100cd4 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cc2:	50                   	push   %eax
f0100cc3:	68 e4 58 10 f0       	push   $0xf01058e4
f0100cc8:	6a 58                	push   $0x58
f0100cca:	68 55 67 10 f0       	push   $0xf0106755
f0100ccf:	e8 6c f3 ff ff       	call   f0100040 <_panic>
f0100cd4:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cda:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100cdd:	0f 86 b6 00 00 00    	jbe    f0100d99 <check_page_free_list+0x2da>
f0100ce3:	68 58 5e 10 f0       	push   $0xf0105e58
f0100ce8:	68 6f 67 10 f0       	push   $0xf010676f
f0100ced:	68 ea 02 00 00       	push   $0x2ea
f0100cf2:	68 49 67 10 f0       	push   $0xf0106749
f0100cf7:	e8 44 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100cfc:	68 dc 67 10 f0       	push   $0xf01067dc
f0100d01:	68 6f 67 10 f0       	push   $0xf010676f
f0100d06:	68 ec 02 00 00       	push   $0x2ec
f0100d0b:	68 49 67 10 f0       	push   $0xf0106749
f0100d10:	e8 2b f3 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d15:	83 c6 01             	add    $0x1,%esi
f0100d18:	eb 03                	jmp    f0100d1d <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d1a:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d1d:	8b 12                	mov    (%edx),%edx
f0100d1f:	85 d2                	test   %edx,%edx
f0100d21:	0f 85 a6 fe ff ff    	jne    f0100bcd <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d27:	85 f6                	test   %esi,%esi
f0100d29:	7f 19                	jg     f0100d44 <check_page_free_list+0x285>
f0100d2b:	68 f9 67 10 f0       	push   $0xf01067f9
f0100d30:	68 6f 67 10 f0       	push   $0xf010676f
f0100d35:	68 f4 02 00 00       	push   $0x2f4
f0100d3a:	68 49 67 10 f0       	push   $0xf0106749
f0100d3f:	e8 fc f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d44:	85 db                	test   %ebx,%ebx
f0100d46:	7f 19                	jg     f0100d61 <check_page_free_list+0x2a2>
f0100d48:	68 0b 68 10 f0       	push   $0xf010680b
f0100d4d:	68 6f 67 10 f0       	push   $0xf010676f
f0100d52:	68 f5 02 00 00       	push   $0x2f5
f0100d57:	68 49 67 10 f0       	push   $0xf0106749
f0100d5c:	e8 df f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d61:	83 ec 0c             	sub    $0xc,%esp
f0100d64:	68 a0 5e 10 f0       	push   $0xf0105ea0
f0100d69:	e8 4d 28 00 00       	call   f01035bb <cprintf>
}
f0100d6e:	eb 49                	jmp    f0100db9 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d70:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f0100d75:	85 c0                	test   %eax,%eax
f0100d77:	0f 85 6f fd ff ff    	jne    f0100aec <check_page_free_list+0x2d>
f0100d7d:	e9 53 fd ff ff       	jmp    f0100ad5 <check_page_free_list+0x16>
f0100d82:	83 3d 40 92 22 f0 00 	cmpl   $0x0,0xf0229240
f0100d89:	0f 84 46 fd ff ff    	je     f0100ad5 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d8f:	be 00 04 00 00       	mov    $0x400,%esi
f0100d94:	e9 a1 fd ff ff       	jmp    f0100b3a <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d99:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d9e:	0f 85 76 ff ff ff    	jne    f0100d1a <check_page_free_list+0x25b>
f0100da4:	e9 53 ff ff ff       	jmp    f0100cfc <check_page_free_list+0x23d>
f0100da9:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dae:	0f 85 61 ff ff ff    	jne    f0100d15 <check_page_free_list+0x256>
f0100db4:	e9 43 ff ff ff       	jmp    f0100cfc <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100db9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dbc:	5b                   	pop    %ebx
f0100dbd:	5e                   	pop    %esi
f0100dbe:	5f                   	pop    %edi
f0100dbf:	5d                   	pop    %ebp
f0100dc0:	c3                   	ret    

f0100dc1 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dc1:	55                   	push   %ebp
f0100dc2:	89 e5                	mov    %esp,%ebp
f0100dc4:	56                   	push   %esi
f0100dc5:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
        page_free_list = NULL;
f0100dc6:	c7 05 40 92 22 f0 00 	movl   $0x0,0xf0229240
f0100dcd:	00 00 00 
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
f0100dd0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd5:	e8 20 fc ff ff       	call   f01009fa <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dda:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ddf:	77 15                	ja     f0100df6 <page_init+0x35>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100de1:	50                   	push   %eax
f0100de2:	68 08 59 10 f0       	push   $0xf0105908
f0100de7:	68 3b 01 00 00       	push   $0x13b
f0100dec:	68 49 67 10 f0       	push   $0xf0106749
f0100df1:	e8 4a f2 ff ff       	call   f0100040 <_panic>
f0100df6:	05 00 00 00 10       	add    $0x10000000,%eax
f0100dfb:	c1 e8 0c             	shr    $0xc,%eax
	for (i = 0; i < npages; i++) 
f0100dfe:	be 00 00 00 00       	mov    $0x0,%esi
f0100e03:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e08:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e0d:	eb 7c                	jmp    f0100e8b <page_init+0xca>
	{
            if(i==0)
f0100e0f:	85 d2                	test   %edx,%edx
f0100e11:	75 14                	jne    f0100e27 <page_init+0x66>
             {
		pages[i].pp_ref = 1;
f0100e13:	8b 0d 90 9e 22 f0    	mov    0xf0229e90,%ecx
f0100e19:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100e1f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100e25:	eb 61                	jmp    f0100e88 <page_init+0xc7>
             }
             else if((i >= low_pgm && i < upp_pgm))
f0100e27:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100e2d:	76 1b                	jbe    f0100e4a <page_init+0x89>
f0100e2f:	39 c2                	cmp    %eax,%edx
f0100e31:	73 17                	jae    f0100e4a <page_init+0x89>
             {
                pages[i].pp_ref=1;
f0100e33:	8b 0d 90 9e 22 f0    	mov    0xf0229e90,%ecx
f0100e39:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100e3c:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100e42:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100e48:	eb 3e                	jmp    f0100e88 <page_init+0xc7>
             }
	     else if(i==PGNUM(MPENTRY_PADDR))
f0100e4a:	83 fa 07             	cmp    $0x7,%edx
f0100e4d:	75 15                	jne    f0100e64 <page_init+0xa3>
	     {
		 pages[i].pp_ref=1;
f0100e4f:	8b 0d 90 9e 22 f0    	mov    0xf0229e90,%ecx
f0100e55:	66 c7 41 3c 01 00    	movw   $0x1,0x3c(%ecx)
		 pages[i].pp_link=NULL;
f0100e5b:	c7 41 38 00 00 00 00 	movl   $0x0,0x38(%ecx)
f0100e62:	eb 24                	jmp    f0100e88 <page_init+0xc7>
f0100e64:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
	     }
             else
             {
                 pages[i].pp_ref=0;
f0100e6b:	89 ce                	mov    %ecx,%esi
f0100e6d:	03 35 90 9e 22 f0    	add    0xf0229e90,%esi
f0100e73:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
                 pages[i].pp_link = page_free_list;
f0100e79:	89 1e                	mov    %ebx,(%esi)
                 page_free_list = &pages[i];
f0100e7b:	89 cb                	mov    %ecx,%ebx
f0100e7d:	03 1d 90 9e 22 f0    	add    0xf0229e90,%ebx
f0100e83:	be 01 00 00 00       	mov    $0x1,%esi
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100e88:	83 c2 01             	add    $0x1,%edx
f0100e8b:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0100e91:	0f 82 78 ff ff ff    	jb     f0100e0f <page_init+0x4e>
f0100e97:	89 f0                	mov    %esi,%eax
f0100e99:	84 c0                	test   %al,%al
f0100e9b:	74 06                	je     f0100ea3 <page_init+0xe2>
f0100e9d:	89 1d 40 92 22 f0    	mov    %ebx,0xf0229240
                 pages[i].pp_ref=0;
                 pages[i].pp_link = page_free_list;
                 page_free_list = &pages[i];
             }
          }
}
f0100ea3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ea6:	5b                   	pop    %ebx
f0100ea7:	5e                   	pop    %esi
f0100ea8:	5d                   	pop    %ebp
f0100ea9:	c3                   	ret    

f0100eaa <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100eaa:	55                   	push   %ebp
f0100eab:	89 e5                	mov    %esp,%ebp
f0100ead:	53                   	push   %ebx
f0100eae:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
        if(page_free_list==NULL)
f0100eb1:	8b 1d 40 92 22 f0    	mov    0xf0229240,%ebx
f0100eb7:	85 db                	test   %ebx,%ebx
f0100eb9:	74 58                	je     f0100f13 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100ebb:	8b 03                	mov    (%ebx),%eax
f0100ebd:	a3 40 92 22 f0       	mov    %eax,0xf0229240
        result->pp_link=NULL;
f0100ec2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if(alloc_flags & ALLOC_ZERO)
f0100ec8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ecc:	74 45                	je     f0100f13 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ece:	89 d8                	mov    %ebx,%eax
f0100ed0:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0100ed6:	c1 f8 03             	sar    $0x3,%eax
f0100ed9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100edc:	89 c2                	mov    %eax,%edx
f0100ede:	c1 ea 0c             	shr    $0xc,%edx
f0100ee1:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0100ee7:	72 12                	jb     f0100efb <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee9:	50                   	push   %eax
f0100eea:	68 e4 58 10 f0       	push   $0xf01058e4
f0100eef:	6a 58                	push   $0x58
f0100ef1:	68 55 67 10 f0       	push   $0xf0106755
f0100ef6:	e8 45 f1 ff ff       	call   f0100040 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100efb:	83 ec 04             	sub    $0x4,%esp
f0100efe:	68 00 10 00 00       	push   $0x1000
f0100f03:	6a 00                	push   $0x0
f0100f05:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f0a:	50                   	push   %eax
f0100f0b:	e8 f2 3c 00 00       	call   f0104c02 <memset>
f0100f10:	83 c4 10             	add    $0x10,%esp
	return result;
}
f0100f13:	89 d8                	mov    %ebx,%eax
f0100f15:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f18:	c9                   	leave  
f0100f19:	c3                   	ret    

f0100f1a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f1a:	55                   	push   %ebp
f0100f1b:	89 e5                	mov    %esp,%ebp
f0100f1d:	83 ec 08             	sub    $0x8,%esp
f0100f20:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0 || pp->pp_link == NULL);  
f0100f23:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f28:	74 1e                	je     f0100f48 <page_free+0x2e>
f0100f2a:	83 38 00             	cmpl   $0x0,(%eax)
f0100f2d:	74 19                	je     f0100f48 <page_free+0x2e>
f0100f2f:	68 c4 5e 10 f0       	push   $0xf0105ec4
f0100f34:	68 6f 67 10 f0       	push   $0xf010676f
f0100f39:	68 7d 01 00 00       	push   $0x17d
f0100f3e:	68 49 67 10 f0       	push   $0xf0106749
f0100f43:	e8 f8 f0 ff ff       	call   f0100040 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100f48:	8b 15 40 92 22 f0    	mov    0xf0229240,%edx
f0100f4e:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100f50:	a3 40 92 22 f0       	mov    %eax,0xf0229240
}
f0100f55:	c9                   	leave  
f0100f56:	c3                   	ret    

f0100f57 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f57:	55                   	push   %ebp
f0100f58:	89 e5                	mov    %esp,%ebp
f0100f5a:	83 ec 08             	sub    $0x8,%esp
f0100f5d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f60:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f64:	83 e8 01             	sub    $0x1,%eax
f0100f67:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f6b:	66 85 c0             	test   %ax,%ax
f0100f6e:	75 0c                	jne    f0100f7c <page_decref+0x25>
		page_free(pp);
f0100f70:	83 ec 0c             	sub    $0xc,%esp
f0100f73:	52                   	push   %edx
f0100f74:	e8 a1 ff ff ff       	call   f0100f1a <page_free>
f0100f79:	83 c4 10             	add    $0x10,%esp
}
f0100f7c:	c9                   	leave  
f0100f7d:	c3                   	ret    

f0100f7e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f7e:	55                   	push   %ebp
f0100f7f:	89 e5                	mov    %esp,%ebp
f0100f81:	56                   	push   %esi
f0100f82:	53                   	push   %ebx
f0100f83:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	uint32_t pdx=PDX(va);
	uint32_t ptx=PTX(va);
f0100f86:	89 de                	mov    %ebx,%esi
f0100f88:	c1 ee 0c             	shr    $0xc,%esi
f0100f8b:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t *po_entry;   
 	pde_t *pt_entry=pgdir+pdx;
f0100f91:	c1 eb 16             	shr    $0x16,%ebx
f0100f94:	c1 e3 02             	shl    $0x2,%ebx
f0100f97:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pt_entry&PTE_P))
f0100f9a:	f6 03 01             	testb  $0x1,(%ebx)
f0100f9d:	75 2d                	jne    f0100fcc <pgdir_walk+0x4e>
	{
		if(create==0)
f0100f9f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fa3:	74 59                	je     f0100ffe <pgdir_walk+0x80>
			return NULL;
		struct PageInfo *pp=page_alloc(1);
f0100fa5:	83 ec 0c             	sub    $0xc,%esp
f0100fa8:	6a 01                	push   $0x1
f0100faa:	e8 fb fe ff ff       	call   f0100eaa <page_alloc>
			if(pp==NULL)
f0100faf:	83 c4 10             	add    $0x10,%esp
f0100fb2:	85 c0                	test   %eax,%eax
f0100fb4:	74 4f                	je     f0101005 <pgdir_walk+0x87>
			{
				return NULL;
			}
		pp->pp_ref++;
f0100fb6:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
f0100fbb:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0100fc1:	c1 f8 03             	sar    $0x3,%eax
f0100fc4:	c1 e0 0c             	shl    $0xc,%eax
f0100fc7:	83 c8 07             	or     $0x7,%eax
f0100fca:	89 03                	mov    %eax,(%ebx)
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
f0100fcc:	8b 03                	mov    (%ebx),%eax
f0100fce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd3:	89 c2                	mov    %eax,%edx
f0100fd5:	c1 ea 0c             	shr    $0xc,%edx
f0100fd8:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0100fde:	72 15                	jb     f0100ff5 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fe0:	50                   	push   %eax
f0100fe1:	68 e4 58 10 f0       	push   $0xf01058e4
f0100fe6:	68 b8 01 00 00       	push   $0x1b8
f0100feb:	68 49 67 10 f0       	push   $0xf0106749
f0100ff0:	e8 4b f0 ff ff       	call   f0100040 <_panic>
	return po_entry+ptx;
f0100ff5:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100ffc:	eb 0c                	jmp    f010100a <pgdir_walk+0x8c>
	pte_t *po_entry;   
 	pde_t *pt_entry=pgdir+pdx;
	if(!(*pt_entry&PTE_P))
	{
		if(create==0)
			return NULL;
f0100ffe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101003:	eb 05                	jmp    f010100a <pgdir_walk+0x8c>
		struct PageInfo *pp=page_alloc(1);
			if(pp==NULL)
			{
				return NULL;
f0101005:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
	return po_entry+ptx;
}
f010100a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010100d:	5b                   	pop    %ebx
f010100e:	5e                   	pop    %esi
f010100f:	5d                   	pop    %ebp
f0101010:	c3                   	ret    

f0101011 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101011:	55                   	push   %ebp
f0101012:	89 e5                	mov    %esp,%ebp
f0101014:	57                   	push   %edi
f0101015:	56                   	push   %esi
f0101016:	53                   	push   %ebx
f0101017:	83 ec 1c             	sub    $0x1c,%esp
f010101a:	89 c7                	mov    %eax,%edi
f010101c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010101f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f0101022:	bb 00 00 00 00       	mov    $0x0,%ebx
	{	
		po_entry=pgdir_walk(pgdir,(char *)va,1);
		*po_entry=pa|perm|PTE_P;
f0101027:	8b 45 0c             	mov    0xc(%ebp),%eax
f010102a:	83 c8 01             	or     $0x1,%eax
f010102d:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f0101030:	eb 1f                	jmp    f0101051 <boot_map_region+0x40>
	{	
		po_entry=pgdir_walk(pgdir,(char *)va,1);
f0101032:	83 ec 04             	sub    $0x4,%esp
f0101035:	6a 01                	push   $0x1
f0101037:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010103a:	01 d8                	add    %ebx,%eax
f010103c:	50                   	push   %eax
f010103d:	57                   	push   %edi
f010103e:	e8 3b ff ff ff       	call   f0100f7e <pgdir_walk>
		*po_entry=pa|perm|PTE_P;
f0101043:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101046:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	size_t i;
	for(i=0;i<size;i+=PGSIZE)
f0101048:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010104e:	83 c4 10             	add    $0x10,%esp
f0101051:	89 de                	mov    %ebx,%esi
f0101053:	03 75 08             	add    0x8(%ebp),%esi
f0101056:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101059:	72 d7                	jb     f0101032 <boot_map_region+0x21>
		*po_entry=pa|perm|PTE_P;
		pa=pa+PGSIZE;
		va=va+PGSIZE;
	}		
	
}
f010105b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010105e:	5b                   	pop    %ebx
f010105f:	5e                   	pop    %esi
f0101060:	5f                   	pop    %edi
f0101061:	5d                   	pop    %ebp
f0101062:	c3                   	ret    

f0101063 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101063:	55                   	push   %ebp
f0101064:	89 e5                	mov    %esp,%ebp
f0101066:	53                   	push   %ebx
f0101067:	83 ec 08             	sub    $0x8,%esp
f010106a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f010106d:	6a 00                	push   $0x0
f010106f:	ff 75 0c             	pushl  0xc(%ebp)
f0101072:	ff 75 08             	pushl  0x8(%ebp)
f0101075:	e8 04 ff ff ff       	call   f0100f7e <pgdir_walk>
	if(po_entry==NULL)
f010107a:	83 c4 10             	add    $0x10,%esp
f010107d:	85 c0                	test   %eax,%eax
f010107f:	74 37                	je     f01010b8 <page_lookup+0x55>
	{
		return NULL;
	}
	if(!(*po_entry&PTE_P))
f0101081:	f6 00 01             	testb  $0x1,(%eax)
f0101084:	74 39                	je     f01010bf <page_lookup+0x5c>
	{
		return NULL;
	}
	if(pte_store!=0)
f0101086:	85 db                	test   %ebx,%ebx
f0101088:	74 02                	je     f010108c <page_lookup+0x29>
	{
		*pte_store=po_entry;
f010108a:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010108c:	8b 00                	mov    (%eax),%eax
f010108e:	c1 e8 0c             	shr    $0xc,%eax
f0101091:	3b 05 88 9e 22 f0    	cmp    0xf0229e88,%eax
f0101097:	72 14                	jb     f01010ad <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0101099:	83 ec 04             	sub    $0x4,%esp
f010109c:	68 ec 5e 10 f0       	push   $0xf0105eec
f01010a1:	6a 51                	push   $0x51
f01010a3:	68 55 67 10 f0       	push   $0xf0106755
f01010a8:	e8 93 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01010ad:	8b 15 90 9e 22 f0    	mov    0xf0229e90,%edx
f01010b3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
f01010b6:	eb 0c                	jmp    f01010c4 <page_lookup+0x61>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f01010b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010bd:	eb 05                	jmp    f01010c4 <page_lookup+0x61>
	}
	if(!(*po_entry&PTE_P))
	{
		return NULL;
f01010bf:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
}	
f01010c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010c7:	c9                   	leave  
f01010c8:	c3                   	ret    

f01010c9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010c9:	55                   	push   %ebp
f01010ca:	89 e5                	mov    %esp,%ebp
f01010cc:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01010cf:	e8 63 41 00 00       	call   f0105237 <cpunum>
f01010d4:	6b c0 74             	imul   $0x74,%eax,%eax
f01010d7:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f01010de:	74 16                	je     f01010f6 <tlb_invalidate+0x2d>
f01010e0:	e8 52 41 00 00       	call   f0105237 <cpunum>
f01010e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01010e8:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01010ee:	8b 55 08             	mov    0x8(%ebp),%edx
f01010f1:	39 50 60             	cmp    %edx,0x60(%eax)
f01010f4:	75 06                	jne    f01010fc <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f9:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01010fc:	c9                   	leave  
f01010fd:	c3                   	ret    

f01010fe <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010fe:	55                   	push   %ebp
f01010ff:	89 e5                	mov    %esp,%ebp
f0101101:	56                   	push   %esi
f0101102:	53                   	push   %ebx
f0101103:	83 ec 14             	sub    $0x14,%esp
f0101106:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101109:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f010110c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f0101113:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101116:	50                   	push   %eax
f0101117:	56                   	push   %esi
f0101118:	53                   	push   %ebx
f0101119:	e8 45 ff ff ff       	call   f0101063 <page_lookup>
	if(pp==NULL)
f010111e:	83 c4 10             	add    $0x10,%esp
f0101121:	85 c0                	test   %eax,%eax
f0101123:	74 1f                	je     f0101144 <page_remove+0x46>
	{
		return;
	}
	page_decref(pp);
f0101125:	83 ec 0c             	sub    $0xc,%esp
f0101128:	50                   	push   %eax
f0101129:	e8 29 fe ff ff       	call   f0100f57 <page_decref>
	*pte_store=0;
f010112e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101131:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);	
f0101137:	83 c4 08             	add    $0x8,%esp
f010113a:	56                   	push   %esi
f010113b:	53                   	push   %ebx
f010113c:	e8 88 ff ff ff       	call   f01010c9 <tlb_invalidate>
f0101141:	83 c4 10             	add    $0x10,%esp
}
f0101144:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101147:	5b                   	pop    %ebx
f0101148:	5e                   	pop    %esi
f0101149:	5d                   	pop    %ebp
f010114a:	c3                   	ret    

f010114b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	57                   	push   %edi
f010114f:	56                   	push   %esi
f0101150:	53                   	push   %ebx
f0101151:	83 ec 10             	sub    $0x10,%esp
f0101154:	8b 75 08             	mov    0x8(%ebp),%esi
f0101157:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f010115a:	6a 01                	push   $0x1
f010115c:	ff 75 10             	pushl  0x10(%ebp)
f010115f:	56                   	push   %esi
f0101160:	e8 19 fe ff ff       	call   f0100f7e <pgdir_walk>
	if(po_entry==NULL)
f0101165:	83 c4 10             	add    $0x10,%esp
f0101168:	85 c0                	test   %eax,%eax
f010116a:	74 50                	je     f01011bc <page_insert+0x71>
f010116c:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f010116e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*po_entry)&PTE_P)
f0101173:	f6 00 01             	testb  $0x1,(%eax)
f0101176:	74 1b                	je     f0101193 <page_insert+0x48>
	{
		tlb_invalidate(pgdir,va);
f0101178:	83 ec 08             	sub    $0x8,%esp
f010117b:	ff 75 10             	pushl  0x10(%ebp)
f010117e:	56                   	push   %esi
f010117f:	e8 45 ff ff ff       	call   f01010c9 <tlb_invalidate>
		page_remove(pgdir,va);
f0101184:	83 c4 08             	add    $0x8,%esp
f0101187:	ff 75 10             	pushl  0x10(%ebp)
f010118a:	56                   	push   %esi
f010118b:	e8 6e ff ff ff       	call   f01010fe <page_remove>
f0101190:	83 c4 10             	add    $0x10,%esp
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
f0101193:	2b 1d 90 9e 22 f0    	sub    0xf0229e90,%ebx
f0101199:	c1 fb 03             	sar    $0x3,%ebx
f010119c:	c1 e3 0c             	shl    $0xc,%ebx
f010119f:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a2:	83 c8 01             	or     $0x1,%eax
f01011a5:	09 c3                	or     %eax,%ebx
f01011a7:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)]|=perm;
f01011a9:	8b 45 10             	mov    0x10(%ebp),%eax
f01011ac:	c1 e8 16             	shr    $0x16,%eax
f01011af:	8b 55 14             	mov    0x14(%ebp),%edx
f01011b2:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f01011b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ba:	eb 05                	jmp    f01011c1 <page_insert+0x76>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f01011bc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
	pgdir[PDX(va)]|=perm;
	return 0;
}
f01011c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c4:	5b                   	pop    %ebx
f01011c5:	5e                   	pop    %esi
f01011c6:	5f                   	pop    %edi
f01011c7:	5d                   	pop    %ebp
f01011c8:	c3                   	ret    

f01011c9 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011c9:	55                   	push   %ebp
f01011ca:	89 e5                	mov    %esp,%ebp
f01011cc:	53                   	push   %ebx
f01011cd:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	uintptr_t ret=base;
f01011d0:	8b 1d 00 e3 11 f0    	mov    0xf011e300,%ebx
	size=ROUNDUP(size,PGSIZE);
f01011d6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d9:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f01011df:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	base=base+size;
f01011e5:	8d 04 0b             	lea    (%ebx,%ecx,1),%eax
f01011e8:	a3 00 e3 11 f0       	mov    %eax,0xf011e300
	if(base>MMIOLIM)
f01011ed:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01011f2:	76 17                	jbe    f010120b <mmio_map_region+0x42>
		panic("mmio_map_region not implemented");
f01011f4:	83 ec 04             	sub    $0x4,%esp
f01011f7:	68 0c 5f 10 f0       	push   $0xf0105f0c
f01011fc:	68 72 02 00 00       	push   $0x272
f0101201:	68 49 67 10 f0       	push   $0xf0106749
f0101206:	e8 35 ee ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir,ret,size,pa,PTE_PCD|PTE_W|PTE_PWT);
f010120b:	83 ec 08             	sub    $0x8,%esp
f010120e:	6a 1a                	push   $0x1a
f0101210:	ff 75 08             	pushl  0x8(%ebp)
f0101213:	89 da                	mov    %ebx,%edx
f0101215:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f010121a:	e8 f2 fd ff ff       	call   f0101011 <boot_map_region>
	return (void*)ret;
}
f010121f:	89 d8                	mov    %ebx,%eax
f0101221:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101224:	c9                   	leave  
f0101225:	c3                   	ret    

f0101226 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	57                   	push   %edi
f010122a:	56                   	push   %esi
f010122b:	53                   	push   %ebx
f010122c:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010122f:	b8 15 00 00 00       	mov    $0x15,%eax
f0101234:	e8 f9 f7 ff ff       	call   f0100a32 <nvram_read>
f0101239:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010123b:	b8 17 00 00 00       	mov    $0x17,%eax
f0101240:	e8 ed f7 ff ff       	call   f0100a32 <nvram_read>
f0101245:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101247:	b8 34 00 00 00       	mov    $0x34,%eax
f010124c:	e8 e1 f7 ff ff       	call   f0100a32 <nvram_read>
f0101251:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101254:	85 c0                	test   %eax,%eax
f0101256:	74 07                	je     f010125f <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101258:	05 00 40 00 00       	add    $0x4000,%eax
f010125d:	eb 0b                	jmp    f010126a <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010125f:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101265:	85 f6                	test   %esi,%esi
f0101267:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010126a:	89 c2                	mov    %eax,%edx
f010126c:	c1 ea 02             	shr    $0x2,%edx
f010126f:	89 15 88 9e 22 f0    	mov    %edx,0xf0229e88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101275:	89 c2                	mov    %eax,%edx
f0101277:	29 da                	sub    %ebx,%edx
f0101279:	52                   	push   %edx
f010127a:	53                   	push   %ebx
f010127b:	50                   	push   %eax
f010127c:	68 2c 5f 10 f0       	push   $0xf0105f2c
f0101281:	e8 35 23 00 00       	call   f01035bb <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101286:	b8 00 10 00 00       	mov    $0x1000,%eax
f010128b:	e8 6a f7 ff ff       	call   f01009fa <boot_alloc>
f0101290:	a3 8c 9e 22 f0       	mov    %eax,0xf0229e8c
	memset(kern_pgdir, 0, PGSIZE);
f0101295:	83 c4 0c             	add    $0xc,%esp
f0101298:	68 00 10 00 00       	push   $0x1000
f010129d:	6a 00                	push   $0x0
f010129f:	50                   	push   %eax
f01012a0:	e8 5d 39 00 00       	call   f0104c02 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012a5:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012aa:	83 c4 10             	add    $0x10,%esp
f01012ad:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012b2:	77 15                	ja     f01012c9 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012b4:	50                   	push   %eax
f01012b5:	68 08 59 10 f0       	push   $0xf0105908
f01012ba:	68 92 00 00 00       	push   $0x92
f01012bf:	68 49 67 10 f0       	push   $0xf0106749
f01012c4:	e8 77 ed ff ff       	call   f0100040 <_panic>
f01012c9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012cf:	83 ca 05             	or     $0x5,%edx
f01012d2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f01012d8:	a1 88 9e 22 f0       	mov    0xf0229e88,%eax
f01012dd:	c1 e0 03             	shl    $0x3,%eax
f01012e0:	e8 15 f7 ff ff       	call   f01009fa <boot_alloc>
f01012e5:	a3 90 9e 22 f0       	mov    %eax,0xf0229e90
        memset(pages,0,npages*sizeof(struct PageInfo));
f01012ea:	83 ec 04             	sub    $0x4,%esp
f01012ed:	8b 0d 88 9e 22 f0    	mov    0xf0229e88,%ecx
f01012f3:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012fa:	52                   	push   %edx
f01012fb:	6a 00                	push   $0x0
f01012fd:	50                   	push   %eax
f01012fe:	e8 ff 38 00 00       	call   f0104c02 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=(struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101303:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101308:	e8 ed f6 ff ff       	call   f01009fa <boot_alloc>
f010130d:	a3 44 92 22 f0       	mov    %eax,0xf0229244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101312:	e8 aa fa ff ff       	call   f0100dc1 <page_init>
	check_page_free_list(1);
f0101317:	b8 01 00 00 00       	mov    $0x1,%eax
f010131c:	e8 9e f7 ff ff       	call   f0100abf <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101321:	83 c4 10             	add    $0x10,%esp
f0101324:	83 3d 90 9e 22 f0 00 	cmpl   $0x0,0xf0229e90
f010132b:	75 17                	jne    f0101344 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f010132d:	83 ec 04             	sub    $0x4,%esp
f0101330:	68 1c 68 10 f0       	push   $0xf010681c
f0101335:	68 08 03 00 00       	push   $0x308
f010133a:	68 49 67 10 f0       	push   $0xf0106749
f010133f:	e8 fc ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101344:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f0101349:	bb 00 00 00 00       	mov    $0x0,%ebx
f010134e:	eb 05                	jmp    f0101355 <mem_init+0x12f>
		++nfree;
f0101350:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101353:	8b 00                	mov    (%eax),%eax
f0101355:	85 c0                	test   %eax,%eax
f0101357:	75 f7                	jne    f0101350 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101359:	83 ec 0c             	sub    $0xc,%esp
f010135c:	6a 00                	push   $0x0
f010135e:	e8 47 fb ff ff       	call   f0100eaa <page_alloc>
f0101363:	89 c7                	mov    %eax,%edi
f0101365:	83 c4 10             	add    $0x10,%esp
f0101368:	85 c0                	test   %eax,%eax
f010136a:	75 19                	jne    f0101385 <mem_init+0x15f>
f010136c:	68 37 68 10 f0       	push   $0xf0106837
f0101371:	68 6f 67 10 f0       	push   $0xf010676f
f0101376:	68 10 03 00 00       	push   $0x310
f010137b:	68 49 67 10 f0       	push   $0xf0106749
f0101380:	e8 bb ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101385:	83 ec 0c             	sub    $0xc,%esp
f0101388:	6a 00                	push   $0x0
f010138a:	e8 1b fb ff ff       	call   f0100eaa <page_alloc>
f010138f:	89 c6                	mov    %eax,%esi
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	85 c0                	test   %eax,%eax
f0101396:	75 19                	jne    f01013b1 <mem_init+0x18b>
f0101398:	68 4d 68 10 f0       	push   $0xf010684d
f010139d:	68 6f 67 10 f0       	push   $0xf010676f
f01013a2:	68 11 03 00 00       	push   $0x311
f01013a7:	68 49 67 10 f0       	push   $0xf0106749
f01013ac:	e8 8f ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b1:	83 ec 0c             	sub    $0xc,%esp
f01013b4:	6a 00                	push   $0x0
f01013b6:	e8 ef fa ff ff       	call   f0100eaa <page_alloc>
f01013bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013be:	83 c4 10             	add    $0x10,%esp
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	75 19                	jne    f01013de <mem_init+0x1b8>
f01013c5:	68 63 68 10 f0       	push   $0xf0106863
f01013ca:	68 6f 67 10 f0       	push   $0xf010676f
f01013cf:	68 12 03 00 00       	push   $0x312
f01013d4:	68 49 67 10 f0       	push   $0xf0106749
f01013d9:	e8 62 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013de:	39 f7                	cmp    %esi,%edi
f01013e0:	75 19                	jne    f01013fb <mem_init+0x1d5>
f01013e2:	68 79 68 10 f0       	push   $0xf0106879
f01013e7:	68 6f 67 10 f0       	push   $0xf010676f
f01013ec:	68 15 03 00 00       	push   $0x315
f01013f1:	68 49 67 10 f0       	push   $0xf0106749
f01013f6:	e8 45 ec ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013fe:	39 c6                	cmp    %eax,%esi
f0101400:	74 04                	je     f0101406 <mem_init+0x1e0>
f0101402:	39 c7                	cmp    %eax,%edi
f0101404:	75 19                	jne    f010141f <mem_init+0x1f9>
f0101406:	68 68 5f 10 f0       	push   $0xf0105f68
f010140b:	68 6f 67 10 f0       	push   $0xf010676f
f0101410:	68 16 03 00 00       	push   $0x316
f0101415:	68 49 67 10 f0       	push   $0xf0106749
f010141a:	e8 21 ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010141f:	8b 0d 90 9e 22 f0    	mov    0xf0229e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101425:	8b 15 88 9e 22 f0    	mov    0xf0229e88,%edx
f010142b:	c1 e2 0c             	shl    $0xc,%edx
f010142e:	89 f8                	mov    %edi,%eax
f0101430:	29 c8                	sub    %ecx,%eax
f0101432:	c1 f8 03             	sar    $0x3,%eax
f0101435:	c1 e0 0c             	shl    $0xc,%eax
f0101438:	39 d0                	cmp    %edx,%eax
f010143a:	72 19                	jb     f0101455 <mem_init+0x22f>
f010143c:	68 8b 68 10 f0       	push   $0xf010688b
f0101441:	68 6f 67 10 f0       	push   $0xf010676f
f0101446:	68 17 03 00 00       	push   $0x317
f010144b:	68 49 67 10 f0       	push   $0xf0106749
f0101450:	e8 eb eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101455:	89 f0                	mov    %esi,%eax
f0101457:	29 c8                	sub    %ecx,%eax
f0101459:	c1 f8 03             	sar    $0x3,%eax
f010145c:	c1 e0 0c             	shl    $0xc,%eax
f010145f:	39 c2                	cmp    %eax,%edx
f0101461:	77 19                	ja     f010147c <mem_init+0x256>
f0101463:	68 a8 68 10 f0       	push   $0xf01068a8
f0101468:	68 6f 67 10 f0       	push   $0xf010676f
f010146d:	68 18 03 00 00       	push   $0x318
f0101472:	68 49 67 10 f0       	push   $0xf0106749
f0101477:	e8 c4 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010147c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010147f:	29 c8                	sub    %ecx,%eax
f0101481:	c1 f8 03             	sar    $0x3,%eax
f0101484:	c1 e0 0c             	shl    $0xc,%eax
f0101487:	39 c2                	cmp    %eax,%edx
f0101489:	77 19                	ja     f01014a4 <mem_init+0x27e>
f010148b:	68 c5 68 10 f0       	push   $0xf01068c5
f0101490:	68 6f 67 10 f0       	push   $0xf010676f
f0101495:	68 19 03 00 00       	push   $0x319
f010149a:	68 49 67 10 f0       	push   $0xf0106749
f010149f:	e8 9c eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014a4:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f01014a9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014ac:	c7 05 40 92 22 f0 00 	movl   $0x0,0xf0229240
f01014b3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014b6:	83 ec 0c             	sub    $0xc,%esp
f01014b9:	6a 00                	push   $0x0
f01014bb:	e8 ea f9 ff ff       	call   f0100eaa <page_alloc>
f01014c0:	83 c4 10             	add    $0x10,%esp
f01014c3:	85 c0                	test   %eax,%eax
f01014c5:	74 19                	je     f01014e0 <mem_init+0x2ba>
f01014c7:	68 e2 68 10 f0       	push   $0xf01068e2
f01014cc:	68 6f 67 10 f0       	push   $0xf010676f
f01014d1:	68 20 03 00 00       	push   $0x320
f01014d6:	68 49 67 10 f0       	push   $0xf0106749
f01014db:	e8 60 eb ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014e0:	83 ec 0c             	sub    $0xc,%esp
f01014e3:	57                   	push   %edi
f01014e4:	e8 31 fa ff ff       	call   f0100f1a <page_free>
	page_free(pp1);
f01014e9:	89 34 24             	mov    %esi,(%esp)
f01014ec:	e8 29 fa ff ff       	call   f0100f1a <page_free>
	page_free(pp2);
f01014f1:	83 c4 04             	add    $0x4,%esp
f01014f4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014f7:	e8 1e fa ff ff       	call   f0100f1a <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101503:	e8 a2 f9 ff ff       	call   f0100eaa <page_alloc>
f0101508:	89 c6                	mov    %eax,%esi
f010150a:	83 c4 10             	add    $0x10,%esp
f010150d:	85 c0                	test   %eax,%eax
f010150f:	75 19                	jne    f010152a <mem_init+0x304>
f0101511:	68 37 68 10 f0       	push   $0xf0106837
f0101516:	68 6f 67 10 f0       	push   $0xf010676f
f010151b:	68 27 03 00 00       	push   $0x327
f0101520:	68 49 67 10 f0       	push   $0xf0106749
f0101525:	e8 16 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010152a:	83 ec 0c             	sub    $0xc,%esp
f010152d:	6a 00                	push   $0x0
f010152f:	e8 76 f9 ff ff       	call   f0100eaa <page_alloc>
f0101534:	89 c7                	mov    %eax,%edi
f0101536:	83 c4 10             	add    $0x10,%esp
f0101539:	85 c0                	test   %eax,%eax
f010153b:	75 19                	jne    f0101556 <mem_init+0x330>
f010153d:	68 4d 68 10 f0       	push   $0xf010684d
f0101542:	68 6f 67 10 f0       	push   $0xf010676f
f0101547:	68 28 03 00 00       	push   $0x328
f010154c:	68 49 67 10 f0       	push   $0xf0106749
f0101551:	e8 ea ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101556:	83 ec 0c             	sub    $0xc,%esp
f0101559:	6a 00                	push   $0x0
f010155b:	e8 4a f9 ff ff       	call   f0100eaa <page_alloc>
f0101560:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101563:	83 c4 10             	add    $0x10,%esp
f0101566:	85 c0                	test   %eax,%eax
f0101568:	75 19                	jne    f0101583 <mem_init+0x35d>
f010156a:	68 63 68 10 f0       	push   $0xf0106863
f010156f:	68 6f 67 10 f0       	push   $0xf010676f
f0101574:	68 29 03 00 00       	push   $0x329
f0101579:	68 49 67 10 f0       	push   $0xf0106749
f010157e:	e8 bd ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101583:	39 fe                	cmp    %edi,%esi
f0101585:	75 19                	jne    f01015a0 <mem_init+0x37a>
f0101587:	68 79 68 10 f0       	push   $0xf0106879
f010158c:	68 6f 67 10 f0       	push   $0xf010676f
f0101591:	68 2b 03 00 00       	push   $0x32b
f0101596:	68 49 67 10 f0       	push   $0xf0106749
f010159b:	e8 a0 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015a3:	39 c7                	cmp    %eax,%edi
f01015a5:	74 04                	je     f01015ab <mem_init+0x385>
f01015a7:	39 c6                	cmp    %eax,%esi
f01015a9:	75 19                	jne    f01015c4 <mem_init+0x39e>
f01015ab:	68 68 5f 10 f0       	push   $0xf0105f68
f01015b0:	68 6f 67 10 f0       	push   $0xf010676f
f01015b5:	68 2c 03 00 00       	push   $0x32c
f01015ba:	68 49 67 10 f0       	push   $0xf0106749
f01015bf:	e8 7c ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01015c4:	83 ec 0c             	sub    $0xc,%esp
f01015c7:	6a 00                	push   $0x0
f01015c9:	e8 dc f8 ff ff       	call   f0100eaa <page_alloc>
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	85 c0                	test   %eax,%eax
f01015d3:	74 19                	je     f01015ee <mem_init+0x3c8>
f01015d5:	68 e2 68 10 f0       	push   $0xf01068e2
f01015da:	68 6f 67 10 f0       	push   $0xf010676f
f01015df:	68 2d 03 00 00       	push   $0x32d
f01015e4:	68 49 67 10 f0       	push   $0xf0106749
f01015e9:	e8 52 ea ff ff       	call   f0100040 <_panic>
f01015ee:	89 f0                	mov    %esi,%eax
f01015f0:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f01015f6:	c1 f8 03             	sar    $0x3,%eax
f01015f9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015fc:	89 c2                	mov    %eax,%edx
f01015fe:	c1 ea 0c             	shr    $0xc,%edx
f0101601:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0101607:	72 12                	jb     f010161b <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101609:	50                   	push   %eax
f010160a:	68 e4 58 10 f0       	push   $0xf01058e4
f010160f:	6a 58                	push   $0x58
f0101611:	68 55 67 10 f0       	push   $0xf0106755
f0101616:	e8 25 ea ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010161b:	83 ec 04             	sub    $0x4,%esp
f010161e:	68 00 10 00 00       	push   $0x1000
f0101623:	6a 01                	push   $0x1
f0101625:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010162a:	50                   	push   %eax
f010162b:	e8 d2 35 00 00       	call   f0104c02 <memset>
	page_free(pp0);
f0101630:	89 34 24             	mov    %esi,(%esp)
f0101633:	e8 e2 f8 ff ff       	call   f0100f1a <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101638:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010163f:	e8 66 f8 ff ff       	call   f0100eaa <page_alloc>
f0101644:	83 c4 10             	add    $0x10,%esp
f0101647:	85 c0                	test   %eax,%eax
f0101649:	75 19                	jne    f0101664 <mem_init+0x43e>
f010164b:	68 f1 68 10 f0       	push   $0xf01068f1
f0101650:	68 6f 67 10 f0       	push   $0xf010676f
f0101655:	68 32 03 00 00       	push   $0x332
f010165a:	68 49 67 10 f0       	push   $0xf0106749
f010165f:	e8 dc e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101664:	39 c6                	cmp    %eax,%esi
f0101666:	74 19                	je     f0101681 <mem_init+0x45b>
f0101668:	68 0f 69 10 f0       	push   $0xf010690f
f010166d:	68 6f 67 10 f0       	push   $0xf010676f
f0101672:	68 33 03 00 00       	push   $0x333
f0101677:	68 49 67 10 f0       	push   $0xf0106749
f010167c:	e8 bf e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101681:	89 f0                	mov    %esi,%eax
f0101683:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0101689:	c1 f8 03             	sar    $0x3,%eax
f010168c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010168f:	89 c2                	mov    %eax,%edx
f0101691:	c1 ea 0c             	shr    $0xc,%edx
f0101694:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f010169a:	72 12                	jb     f01016ae <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010169c:	50                   	push   %eax
f010169d:	68 e4 58 10 f0       	push   $0xf01058e4
f01016a2:	6a 58                	push   $0x58
f01016a4:	68 55 67 10 f0       	push   $0xf0106755
f01016a9:	e8 92 e9 ff ff       	call   f0100040 <_panic>
f01016ae:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01016b4:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016ba:	80 38 00             	cmpb   $0x0,(%eax)
f01016bd:	74 19                	je     f01016d8 <mem_init+0x4b2>
f01016bf:	68 1f 69 10 f0       	push   $0xf010691f
f01016c4:	68 6f 67 10 f0       	push   $0xf010676f
f01016c9:	68 36 03 00 00       	push   $0x336
f01016ce:	68 49 67 10 f0       	push   $0xf0106749
f01016d3:	e8 68 e9 ff ff       	call   f0100040 <_panic>
f01016d8:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01016db:	39 d0                	cmp    %edx,%eax
f01016dd:	75 db                	jne    f01016ba <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01016df:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01016e2:	a3 40 92 22 f0       	mov    %eax,0xf0229240

	// free the pages we took
	page_free(pp0);
f01016e7:	83 ec 0c             	sub    $0xc,%esp
f01016ea:	56                   	push   %esi
f01016eb:	e8 2a f8 ff ff       	call   f0100f1a <page_free>
	page_free(pp1);
f01016f0:	89 3c 24             	mov    %edi,(%esp)
f01016f3:	e8 22 f8 ff ff       	call   f0100f1a <page_free>
	page_free(pp2);
f01016f8:	83 c4 04             	add    $0x4,%esp
f01016fb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016fe:	e8 17 f8 ff ff       	call   f0100f1a <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101703:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f0101708:	83 c4 10             	add    $0x10,%esp
f010170b:	eb 05                	jmp    f0101712 <mem_init+0x4ec>
		--nfree;
f010170d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101710:	8b 00                	mov    (%eax),%eax
f0101712:	85 c0                	test   %eax,%eax
f0101714:	75 f7                	jne    f010170d <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f0101716:	85 db                	test   %ebx,%ebx
f0101718:	74 19                	je     f0101733 <mem_init+0x50d>
f010171a:	68 29 69 10 f0       	push   $0xf0106929
f010171f:	68 6f 67 10 f0       	push   $0xf010676f
f0101724:	68 43 03 00 00       	push   $0x343
f0101729:	68 49 67 10 f0       	push   $0xf0106749
f010172e:	e8 0d e9 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101733:	83 ec 0c             	sub    $0xc,%esp
f0101736:	68 88 5f 10 f0       	push   $0xf0105f88
f010173b:	e8 7b 1e 00 00       	call   f01035bb <cprintf>
	uintptr_t mm1, mm2;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101740:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101747:	e8 5e f7 ff ff       	call   f0100eaa <page_alloc>
f010174c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010174f:	83 c4 10             	add    $0x10,%esp
f0101752:	85 c0                	test   %eax,%eax
f0101754:	75 19                	jne    f010176f <mem_init+0x549>
f0101756:	68 37 68 10 f0       	push   $0xf0106837
f010175b:	68 6f 67 10 f0       	push   $0xf010676f
f0101760:	68 a8 03 00 00       	push   $0x3a8
f0101765:	68 49 67 10 f0       	push   $0xf0106749
f010176a:	e8 d1 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010176f:	83 ec 0c             	sub    $0xc,%esp
f0101772:	6a 00                	push   $0x0
f0101774:	e8 31 f7 ff ff       	call   f0100eaa <page_alloc>
f0101779:	89 c3                	mov    %eax,%ebx
f010177b:	83 c4 10             	add    $0x10,%esp
f010177e:	85 c0                	test   %eax,%eax
f0101780:	75 19                	jne    f010179b <mem_init+0x575>
f0101782:	68 4d 68 10 f0       	push   $0xf010684d
f0101787:	68 6f 67 10 f0       	push   $0xf010676f
f010178c:	68 a9 03 00 00       	push   $0x3a9
f0101791:	68 49 67 10 f0       	push   $0xf0106749
f0101796:	e8 a5 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010179b:	83 ec 0c             	sub    $0xc,%esp
f010179e:	6a 00                	push   $0x0
f01017a0:	e8 05 f7 ff ff       	call   f0100eaa <page_alloc>
f01017a5:	89 c6                	mov    %eax,%esi
f01017a7:	83 c4 10             	add    $0x10,%esp
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	75 19                	jne    f01017c7 <mem_init+0x5a1>
f01017ae:	68 63 68 10 f0       	push   $0xf0106863
f01017b3:	68 6f 67 10 f0       	push   $0xf010676f
f01017b8:	68 aa 03 00 00       	push   $0x3aa
f01017bd:	68 49 67 10 f0       	push   $0xf0106749
f01017c2:	e8 79 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017c7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01017ca:	75 19                	jne    f01017e5 <mem_init+0x5bf>
f01017cc:	68 79 68 10 f0       	push   $0xf0106879
f01017d1:	68 6f 67 10 f0       	push   $0xf010676f
f01017d6:	68 ad 03 00 00       	push   $0x3ad
f01017db:	68 49 67 10 f0       	push   $0xf0106749
f01017e0:	e8 5b e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017e5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017e8:	74 04                	je     f01017ee <mem_init+0x5c8>
f01017ea:	39 c3                	cmp    %eax,%ebx
f01017ec:	75 19                	jne    f0101807 <mem_init+0x5e1>
f01017ee:	68 68 5f 10 f0       	push   $0xf0105f68
f01017f3:	68 6f 67 10 f0       	push   $0xf010676f
f01017f8:	68 ae 03 00 00       	push   $0x3ae
f01017fd:	68 49 67 10 f0       	push   $0xf0106749
f0101802:	e8 39 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101807:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f010180c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010180f:	c7 05 40 92 22 f0 00 	movl   $0x0,0xf0229240
f0101816:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101819:	83 ec 0c             	sub    $0xc,%esp
f010181c:	6a 00                	push   $0x0
f010181e:	e8 87 f6 ff ff       	call   f0100eaa <page_alloc>
f0101823:	83 c4 10             	add    $0x10,%esp
f0101826:	85 c0                	test   %eax,%eax
f0101828:	74 19                	je     f0101843 <mem_init+0x61d>
f010182a:	68 e2 68 10 f0       	push   $0xf01068e2
f010182f:	68 6f 67 10 f0       	push   $0xf010676f
f0101834:	68 b5 03 00 00       	push   $0x3b5
f0101839:	68 49 67 10 f0       	push   $0xf0106749
f010183e:	e8 fd e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101843:	83 ec 04             	sub    $0x4,%esp
f0101846:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101849:	50                   	push   %eax
f010184a:	6a 00                	push   $0x0
f010184c:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101852:	e8 0c f8 ff ff       	call   f0101063 <page_lookup>
f0101857:	83 c4 10             	add    $0x10,%esp
f010185a:	85 c0                	test   %eax,%eax
f010185c:	74 19                	je     f0101877 <mem_init+0x651>
f010185e:	68 a8 5f 10 f0       	push   $0xf0105fa8
f0101863:	68 6f 67 10 f0       	push   $0xf010676f
f0101868:	68 b8 03 00 00       	push   $0x3b8
f010186d:	68 49 67 10 f0       	push   $0xf0106749
f0101872:	e8 c9 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101877:	6a 02                	push   $0x2
f0101879:	6a 00                	push   $0x0
f010187b:	53                   	push   %ebx
f010187c:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101882:	e8 c4 f8 ff ff       	call   f010114b <page_insert>
f0101887:	83 c4 10             	add    $0x10,%esp
f010188a:	85 c0                	test   %eax,%eax
f010188c:	78 19                	js     f01018a7 <mem_init+0x681>
f010188e:	68 e0 5f 10 f0       	push   $0xf0105fe0
f0101893:	68 6f 67 10 f0       	push   $0xf010676f
f0101898:	68 bb 03 00 00       	push   $0x3bb
f010189d:	68 49 67 10 f0       	push   $0xf0106749
f01018a2:	e8 99 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01018a7:	83 ec 0c             	sub    $0xc,%esp
f01018aa:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018ad:	e8 68 f6 ff ff       	call   f0100f1a <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01018b2:	6a 02                	push   $0x2
f01018b4:	6a 00                	push   $0x0
f01018b6:	53                   	push   %ebx
f01018b7:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f01018bd:	e8 89 f8 ff ff       	call   f010114b <page_insert>
f01018c2:	83 c4 20             	add    $0x20,%esp
f01018c5:	85 c0                	test   %eax,%eax
f01018c7:	74 19                	je     f01018e2 <mem_init+0x6bc>
f01018c9:	68 10 60 10 f0       	push   $0xf0106010
f01018ce:	68 6f 67 10 f0       	push   $0xf010676f
f01018d3:	68 bf 03 00 00       	push   $0x3bf
f01018d8:	68 49 67 10 f0       	push   $0xf0106749
f01018dd:	e8 5e e7 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018e2:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018e8:	a1 90 9e 22 f0       	mov    0xf0229e90,%eax
f01018ed:	89 c1                	mov    %eax,%ecx
f01018ef:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01018f2:	8b 17                	mov    (%edi),%edx
f01018f4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01018fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018fd:	29 c8                	sub    %ecx,%eax
f01018ff:	c1 f8 03             	sar    $0x3,%eax
f0101902:	c1 e0 0c             	shl    $0xc,%eax
f0101905:	39 c2                	cmp    %eax,%edx
f0101907:	74 19                	je     f0101922 <mem_init+0x6fc>
f0101909:	68 40 60 10 f0       	push   $0xf0106040
f010190e:	68 6f 67 10 f0       	push   $0xf010676f
f0101913:	68 c0 03 00 00       	push   $0x3c0
f0101918:	68 49 67 10 f0       	push   $0xf0106749
f010191d:	e8 1e e7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101922:	ba 00 00 00 00       	mov    $0x0,%edx
f0101927:	89 f8                	mov    %edi,%eax
f0101929:	e8 2d f1 ff ff       	call   f0100a5b <check_va2pa>
f010192e:	89 da                	mov    %ebx,%edx
f0101930:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101933:	c1 fa 03             	sar    $0x3,%edx
f0101936:	c1 e2 0c             	shl    $0xc,%edx
f0101939:	39 d0                	cmp    %edx,%eax
f010193b:	74 19                	je     f0101956 <mem_init+0x730>
f010193d:	68 68 60 10 f0       	push   $0xf0106068
f0101942:	68 6f 67 10 f0       	push   $0xf010676f
f0101947:	68 c1 03 00 00       	push   $0x3c1
f010194c:	68 49 67 10 f0       	push   $0xf0106749
f0101951:	e8 ea e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101956:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010195b:	74 19                	je     f0101976 <mem_init+0x750>
f010195d:	68 34 69 10 f0       	push   $0xf0106934
f0101962:	68 6f 67 10 f0       	push   $0xf010676f
f0101967:	68 c2 03 00 00       	push   $0x3c2
f010196c:	68 49 67 10 f0       	push   $0xf0106749
f0101971:	e8 ca e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101976:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101979:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010197e:	74 19                	je     f0101999 <mem_init+0x773>
f0101980:	68 45 69 10 f0       	push   $0xf0106945
f0101985:	68 6f 67 10 f0       	push   $0xf010676f
f010198a:	68 c3 03 00 00       	push   $0x3c3
f010198f:	68 49 67 10 f0       	push   $0xf0106749
f0101994:	e8 a7 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101999:	6a 02                	push   $0x2
f010199b:	68 00 10 00 00       	push   $0x1000
f01019a0:	56                   	push   %esi
f01019a1:	57                   	push   %edi
f01019a2:	e8 a4 f7 ff ff       	call   f010114b <page_insert>
f01019a7:	83 c4 10             	add    $0x10,%esp
f01019aa:	85 c0                	test   %eax,%eax
f01019ac:	74 19                	je     f01019c7 <mem_init+0x7a1>
f01019ae:	68 98 60 10 f0       	push   $0xf0106098
f01019b3:	68 6f 67 10 f0       	push   $0xf010676f
f01019b8:	68 c6 03 00 00       	push   $0x3c6
f01019bd:	68 49 67 10 f0       	push   $0xf0106749
f01019c2:	e8 79 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019cc:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f01019d1:	e8 85 f0 ff ff       	call   f0100a5b <check_va2pa>
f01019d6:	89 f2                	mov    %esi,%edx
f01019d8:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f01019de:	c1 fa 03             	sar    $0x3,%edx
f01019e1:	c1 e2 0c             	shl    $0xc,%edx
f01019e4:	39 d0                	cmp    %edx,%eax
f01019e6:	74 19                	je     f0101a01 <mem_init+0x7db>
f01019e8:	68 d4 60 10 f0       	push   $0xf01060d4
f01019ed:	68 6f 67 10 f0       	push   $0xf010676f
f01019f2:	68 c7 03 00 00       	push   $0x3c7
f01019f7:	68 49 67 10 f0       	push   $0xf0106749
f01019fc:	e8 3f e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a01:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a06:	74 19                	je     f0101a21 <mem_init+0x7fb>
f0101a08:	68 56 69 10 f0       	push   $0xf0106956
f0101a0d:	68 6f 67 10 f0       	push   $0xf010676f
f0101a12:	68 c8 03 00 00       	push   $0x3c8
f0101a17:	68 49 67 10 f0       	push   $0xf0106749
f0101a1c:	e8 1f e6 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a21:	83 ec 0c             	sub    $0xc,%esp
f0101a24:	6a 00                	push   $0x0
f0101a26:	e8 7f f4 ff ff       	call   f0100eaa <page_alloc>
f0101a2b:	83 c4 10             	add    $0x10,%esp
f0101a2e:	85 c0                	test   %eax,%eax
f0101a30:	74 19                	je     f0101a4b <mem_init+0x825>
f0101a32:	68 e2 68 10 f0       	push   $0xf01068e2
f0101a37:	68 6f 67 10 f0       	push   $0xf010676f
f0101a3c:	68 cb 03 00 00       	push   $0x3cb
f0101a41:	68 49 67 10 f0       	push   $0xf0106749
f0101a46:	e8 f5 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a4b:	6a 02                	push   $0x2
f0101a4d:	68 00 10 00 00       	push   $0x1000
f0101a52:	56                   	push   %esi
f0101a53:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101a59:	e8 ed f6 ff ff       	call   f010114b <page_insert>
f0101a5e:	83 c4 10             	add    $0x10,%esp
f0101a61:	85 c0                	test   %eax,%eax
f0101a63:	74 19                	je     f0101a7e <mem_init+0x858>
f0101a65:	68 98 60 10 f0       	push   $0xf0106098
f0101a6a:	68 6f 67 10 f0       	push   $0xf010676f
f0101a6f:	68 ce 03 00 00       	push   $0x3ce
f0101a74:	68 49 67 10 f0       	push   $0xf0106749
f0101a79:	e8 c2 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a7e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a83:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f0101a88:	e8 ce ef ff ff       	call   f0100a5b <check_va2pa>
f0101a8d:	89 f2                	mov    %esi,%edx
f0101a8f:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f0101a95:	c1 fa 03             	sar    $0x3,%edx
f0101a98:	c1 e2 0c             	shl    $0xc,%edx
f0101a9b:	39 d0                	cmp    %edx,%eax
f0101a9d:	74 19                	je     f0101ab8 <mem_init+0x892>
f0101a9f:	68 d4 60 10 f0       	push   $0xf01060d4
f0101aa4:	68 6f 67 10 f0       	push   $0xf010676f
f0101aa9:	68 cf 03 00 00       	push   $0x3cf
f0101aae:	68 49 67 10 f0       	push   $0xf0106749
f0101ab3:	e8 88 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ab8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101abd:	74 19                	je     f0101ad8 <mem_init+0x8b2>
f0101abf:	68 56 69 10 f0       	push   $0xf0106956
f0101ac4:	68 6f 67 10 f0       	push   $0xf010676f
f0101ac9:	68 d0 03 00 00       	push   $0x3d0
f0101ace:	68 49 67 10 f0       	push   $0xf0106749
f0101ad3:	e8 68 e5 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ad8:	83 ec 0c             	sub    $0xc,%esp
f0101adb:	6a 00                	push   $0x0
f0101add:	e8 c8 f3 ff ff       	call   f0100eaa <page_alloc>
f0101ae2:	83 c4 10             	add    $0x10,%esp
f0101ae5:	85 c0                	test   %eax,%eax
f0101ae7:	74 19                	je     f0101b02 <mem_init+0x8dc>
f0101ae9:	68 e2 68 10 f0       	push   $0xf01068e2
f0101aee:	68 6f 67 10 f0       	push   $0xf010676f
f0101af3:	68 d4 03 00 00       	push   $0x3d4
f0101af8:	68 49 67 10 f0       	push   $0xf0106749
f0101afd:	e8 3e e5 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b02:	8b 15 8c 9e 22 f0    	mov    0xf0229e8c,%edx
f0101b08:	8b 02                	mov    (%edx),%eax
f0101b0a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b0f:	89 c1                	mov    %eax,%ecx
f0101b11:	c1 e9 0c             	shr    $0xc,%ecx
f0101b14:	3b 0d 88 9e 22 f0    	cmp    0xf0229e88,%ecx
f0101b1a:	72 15                	jb     f0101b31 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b1c:	50                   	push   %eax
f0101b1d:	68 e4 58 10 f0       	push   $0xf01058e4
f0101b22:	68 d7 03 00 00       	push   $0x3d7
f0101b27:	68 49 67 10 f0       	push   $0xf0106749
f0101b2c:	e8 0f e5 ff ff       	call   f0100040 <_panic>
f0101b31:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b39:	83 ec 04             	sub    $0x4,%esp
f0101b3c:	6a 00                	push   $0x0
f0101b3e:	68 00 10 00 00       	push   $0x1000
f0101b43:	52                   	push   %edx
f0101b44:	e8 35 f4 ff ff       	call   f0100f7e <pgdir_walk>
f0101b49:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b4c:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b4f:	83 c4 10             	add    $0x10,%esp
f0101b52:	39 d0                	cmp    %edx,%eax
f0101b54:	74 19                	je     f0101b6f <mem_init+0x949>
f0101b56:	68 04 61 10 f0       	push   $0xf0106104
f0101b5b:	68 6f 67 10 f0       	push   $0xf010676f
f0101b60:	68 d8 03 00 00       	push   $0x3d8
f0101b65:	68 49 67 10 f0       	push   $0xf0106749
f0101b6a:	e8 d1 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b6f:	6a 06                	push   $0x6
f0101b71:	68 00 10 00 00       	push   $0x1000
f0101b76:	56                   	push   %esi
f0101b77:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101b7d:	e8 c9 f5 ff ff       	call   f010114b <page_insert>
f0101b82:	83 c4 10             	add    $0x10,%esp
f0101b85:	85 c0                	test   %eax,%eax
f0101b87:	74 19                	je     f0101ba2 <mem_init+0x97c>
f0101b89:	68 44 61 10 f0       	push   $0xf0106144
f0101b8e:	68 6f 67 10 f0       	push   $0xf010676f
f0101b93:	68 db 03 00 00       	push   $0x3db
f0101b98:	68 49 67 10 f0       	push   $0xf0106749
f0101b9d:	e8 9e e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ba2:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
f0101ba8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bad:	89 f8                	mov    %edi,%eax
f0101baf:	e8 a7 ee ff ff       	call   f0100a5b <check_va2pa>
f0101bb4:	89 f2                	mov    %esi,%edx
f0101bb6:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f0101bbc:	c1 fa 03             	sar    $0x3,%edx
f0101bbf:	c1 e2 0c             	shl    $0xc,%edx
f0101bc2:	39 d0                	cmp    %edx,%eax
f0101bc4:	74 19                	je     f0101bdf <mem_init+0x9b9>
f0101bc6:	68 d4 60 10 f0       	push   $0xf01060d4
f0101bcb:	68 6f 67 10 f0       	push   $0xf010676f
f0101bd0:	68 dc 03 00 00       	push   $0x3dc
f0101bd5:	68 49 67 10 f0       	push   $0xf0106749
f0101bda:	e8 61 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bdf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be4:	74 19                	je     f0101bff <mem_init+0x9d9>
f0101be6:	68 56 69 10 f0       	push   $0xf0106956
f0101beb:	68 6f 67 10 f0       	push   $0xf010676f
f0101bf0:	68 dd 03 00 00       	push   $0x3dd
f0101bf5:	68 49 67 10 f0       	push   $0xf0106749
f0101bfa:	e8 41 e4 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bff:	83 ec 04             	sub    $0x4,%esp
f0101c02:	6a 00                	push   $0x0
f0101c04:	68 00 10 00 00       	push   $0x1000
f0101c09:	57                   	push   %edi
f0101c0a:	e8 6f f3 ff ff       	call   f0100f7e <pgdir_walk>
f0101c0f:	83 c4 10             	add    $0x10,%esp
f0101c12:	f6 00 04             	testb  $0x4,(%eax)
f0101c15:	75 19                	jne    f0101c30 <mem_init+0xa0a>
f0101c17:	68 84 61 10 f0       	push   $0xf0106184
f0101c1c:	68 6f 67 10 f0       	push   $0xf010676f
f0101c21:	68 de 03 00 00       	push   $0x3de
f0101c26:	68 49 67 10 f0       	push   $0xf0106749
f0101c2b:	e8 10 e4 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c30:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f0101c35:	f6 00 04             	testb  $0x4,(%eax)
f0101c38:	75 19                	jne    f0101c53 <mem_init+0xa2d>
f0101c3a:	68 67 69 10 f0       	push   $0xf0106967
f0101c3f:	68 6f 67 10 f0       	push   $0xf010676f
f0101c44:	68 df 03 00 00       	push   $0x3df
f0101c49:	68 49 67 10 f0       	push   $0xf0106749
f0101c4e:	e8 ed e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c53:	6a 02                	push   $0x2
f0101c55:	68 00 10 00 00       	push   $0x1000
f0101c5a:	56                   	push   %esi
f0101c5b:	50                   	push   %eax
f0101c5c:	e8 ea f4 ff ff       	call   f010114b <page_insert>
f0101c61:	83 c4 10             	add    $0x10,%esp
f0101c64:	85 c0                	test   %eax,%eax
f0101c66:	74 19                	je     f0101c81 <mem_init+0xa5b>
f0101c68:	68 98 60 10 f0       	push   $0xf0106098
f0101c6d:	68 6f 67 10 f0       	push   $0xf010676f
f0101c72:	68 e2 03 00 00       	push   $0x3e2
f0101c77:	68 49 67 10 f0       	push   $0xf0106749
f0101c7c:	e8 bf e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c81:	83 ec 04             	sub    $0x4,%esp
f0101c84:	6a 00                	push   $0x0
f0101c86:	68 00 10 00 00       	push   $0x1000
f0101c8b:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101c91:	e8 e8 f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101c96:	83 c4 10             	add    $0x10,%esp
f0101c99:	f6 00 02             	testb  $0x2,(%eax)
f0101c9c:	75 19                	jne    f0101cb7 <mem_init+0xa91>
f0101c9e:	68 b8 61 10 f0       	push   $0xf01061b8
f0101ca3:	68 6f 67 10 f0       	push   $0xf010676f
f0101ca8:	68 e3 03 00 00       	push   $0x3e3
f0101cad:	68 49 67 10 f0       	push   $0xf0106749
f0101cb2:	e8 89 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cb7:	83 ec 04             	sub    $0x4,%esp
f0101cba:	6a 00                	push   $0x0
f0101cbc:	68 00 10 00 00       	push   $0x1000
f0101cc1:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101cc7:	e8 b2 f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101ccc:	83 c4 10             	add    $0x10,%esp
f0101ccf:	f6 00 04             	testb  $0x4,(%eax)
f0101cd2:	74 19                	je     f0101ced <mem_init+0xac7>
f0101cd4:	68 ec 61 10 f0       	push   $0xf01061ec
f0101cd9:	68 6f 67 10 f0       	push   $0xf010676f
f0101cde:	68 e4 03 00 00       	push   $0x3e4
f0101ce3:	68 49 67 10 f0       	push   $0xf0106749
f0101ce8:	e8 53 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101ced:	6a 02                	push   $0x2
f0101cef:	68 00 00 40 00       	push   $0x400000
f0101cf4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cf7:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101cfd:	e8 49 f4 ff ff       	call   f010114b <page_insert>
f0101d02:	83 c4 10             	add    $0x10,%esp
f0101d05:	85 c0                	test   %eax,%eax
f0101d07:	78 19                	js     f0101d22 <mem_init+0xafc>
f0101d09:	68 24 62 10 f0       	push   $0xf0106224
f0101d0e:	68 6f 67 10 f0       	push   $0xf010676f
f0101d13:	68 e7 03 00 00       	push   $0x3e7
f0101d18:	68 49 67 10 f0       	push   $0xf0106749
f0101d1d:	e8 1e e3 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d22:	6a 02                	push   $0x2
f0101d24:	68 00 10 00 00       	push   $0x1000
f0101d29:	53                   	push   %ebx
f0101d2a:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101d30:	e8 16 f4 ff ff       	call   f010114b <page_insert>
f0101d35:	83 c4 10             	add    $0x10,%esp
f0101d38:	85 c0                	test   %eax,%eax
f0101d3a:	74 19                	je     f0101d55 <mem_init+0xb2f>
f0101d3c:	68 60 62 10 f0       	push   $0xf0106260
f0101d41:	68 6f 67 10 f0       	push   $0xf010676f
f0101d46:	68 ea 03 00 00       	push   $0x3ea
f0101d4b:	68 49 67 10 f0       	push   $0xf0106749
f0101d50:	e8 eb e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d55:	83 ec 04             	sub    $0x4,%esp
f0101d58:	6a 00                	push   $0x0
f0101d5a:	68 00 10 00 00       	push   $0x1000
f0101d5f:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101d65:	e8 14 f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101d6a:	83 c4 10             	add    $0x10,%esp
f0101d6d:	f6 00 04             	testb  $0x4,(%eax)
f0101d70:	74 19                	je     f0101d8b <mem_init+0xb65>
f0101d72:	68 ec 61 10 f0       	push   $0xf01061ec
f0101d77:	68 6f 67 10 f0       	push   $0xf010676f
f0101d7c:	68 eb 03 00 00       	push   $0x3eb
f0101d81:	68 49 67 10 f0       	push   $0xf0106749
f0101d86:	e8 b5 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d8b:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
f0101d91:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d96:	89 f8                	mov    %edi,%eax
f0101d98:	e8 be ec ff ff       	call   f0100a5b <check_va2pa>
f0101d9d:	89 c1                	mov    %eax,%ecx
f0101d9f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101da2:	89 d8                	mov    %ebx,%eax
f0101da4:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0101daa:	c1 f8 03             	sar    $0x3,%eax
f0101dad:	c1 e0 0c             	shl    $0xc,%eax
f0101db0:	39 c1                	cmp    %eax,%ecx
f0101db2:	74 19                	je     f0101dcd <mem_init+0xba7>
f0101db4:	68 9c 62 10 f0       	push   $0xf010629c
f0101db9:	68 6f 67 10 f0       	push   $0xf010676f
f0101dbe:	68 ee 03 00 00       	push   $0x3ee
f0101dc3:	68 49 67 10 f0       	push   $0xf0106749
f0101dc8:	e8 73 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dcd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd2:	89 f8                	mov    %edi,%eax
f0101dd4:	e8 82 ec ff ff       	call   f0100a5b <check_va2pa>
f0101dd9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ddc:	74 19                	je     f0101df7 <mem_init+0xbd1>
f0101dde:	68 c8 62 10 f0       	push   $0xf01062c8
f0101de3:	68 6f 67 10 f0       	push   $0xf010676f
f0101de8:	68 ef 03 00 00       	push   $0x3ef
f0101ded:	68 49 67 10 f0       	push   $0xf0106749
f0101df2:	e8 49 e2 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101df7:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dfc:	74 19                	je     f0101e17 <mem_init+0xbf1>
f0101dfe:	68 7d 69 10 f0       	push   $0xf010697d
f0101e03:	68 6f 67 10 f0       	push   $0xf010676f
f0101e08:	68 f1 03 00 00       	push   $0x3f1
f0101e0d:	68 49 67 10 f0       	push   $0xf0106749
f0101e12:	e8 29 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e17:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e1c:	74 19                	je     f0101e37 <mem_init+0xc11>
f0101e1e:	68 8e 69 10 f0       	push   $0xf010698e
f0101e23:	68 6f 67 10 f0       	push   $0xf010676f
f0101e28:	68 f2 03 00 00       	push   $0x3f2
f0101e2d:	68 49 67 10 f0       	push   $0xf0106749
f0101e32:	e8 09 e2 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e37:	83 ec 0c             	sub    $0xc,%esp
f0101e3a:	6a 00                	push   $0x0
f0101e3c:	e8 69 f0 ff ff       	call   f0100eaa <page_alloc>
f0101e41:	83 c4 10             	add    $0x10,%esp
f0101e44:	39 c6                	cmp    %eax,%esi
f0101e46:	75 04                	jne    f0101e4c <mem_init+0xc26>
f0101e48:	85 c0                	test   %eax,%eax
f0101e4a:	75 19                	jne    f0101e65 <mem_init+0xc3f>
f0101e4c:	68 f8 62 10 f0       	push   $0xf01062f8
f0101e51:	68 6f 67 10 f0       	push   $0xf010676f
f0101e56:	68 f5 03 00 00       	push   $0x3f5
f0101e5b:	68 49 67 10 f0       	push   $0xf0106749
f0101e60:	e8 db e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e65:	83 ec 08             	sub    $0x8,%esp
f0101e68:	6a 00                	push   $0x0
f0101e6a:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101e70:	e8 89 f2 ff ff       	call   f01010fe <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e75:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
f0101e7b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e80:	89 f8                	mov    %edi,%eax
f0101e82:	e8 d4 eb ff ff       	call   f0100a5b <check_va2pa>
f0101e87:	83 c4 10             	add    $0x10,%esp
f0101e8a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e8d:	74 19                	je     f0101ea8 <mem_init+0xc82>
f0101e8f:	68 1c 63 10 f0       	push   $0xf010631c
f0101e94:	68 6f 67 10 f0       	push   $0xf010676f
f0101e99:	68 f9 03 00 00       	push   $0x3f9
f0101e9e:	68 49 67 10 f0       	push   $0xf0106749
f0101ea3:	e8 98 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ea8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ead:	89 f8                	mov    %edi,%eax
f0101eaf:	e8 a7 eb ff ff       	call   f0100a5b <check_va2pa>
f0101eb4:	89 da                	mov    %ebx,%edx
f0101eb6:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f0101ebc:	c1 fa 03             	sar    $0x3,%edx
f0101ebf:	c1 e2 0c             	shl    $0xc,%edx
f0101ec2:	39 d0                	cmp    %edx,%eax
f0101ec4:	74 19                	je     f0101edf <mem_init+0xcb9>
f0101ec6:	68 c8 62 10 f0       	push   $0xf01062c8
f0101ecb:	68 6f 67 10 f0       	push   $0xf010676f
f0101ed0:	68 fa 03 00 00       	push   $0x3fa
f0101ed5:	68 49 67 10 f0       	push   $0xf0106749
f0101eda:	e8 61 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101edf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ee4:	74 19                	je     f0101eff <mem_init+0xcd9>
f0101ee6:	68 34 69 10 f0       	push   $0xf0106934
f0101eeb:	68 6f 67 10 f0       	push   $0xf010676f
f0101ef0:	68 fb 03 00 00       	push   $0x3fb
f0101ef5:	68 49 67 10 f0       	push   $0xf0106749
f0101efa:	e8 41 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101eff:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f04:	74 19                	je     f0101f1f <mem_init+0xcf9>
f0101f06:	68 8e 69 10 f0       	push   $0xf010698e
f0101f0b:	68 6f 67 10 f0       	push   $0xf010676f
f0101f10:	68 fc 03 00 00       	push   $0x3fc
f0101f15:	68 49 67 10 f0       	push   $0xf0106749
f0101f1a:	e8 21 e1 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f1f:	6a 00                	push   $0x0
f0101f21:	68 00 10 00 00       	push   $0x1000
f0101f26:	53                   	push   %ebx
f0101f27:	57                   	push   %edi
f0101f28:	e8 1e f2 ff ff       	call   f010114b <page_insert>
f0101f2d:	83 c4 10             	add    $0x10,%esp
f0101f30:	85 c0                	test   %eax,%eax
f0101f32:	74 19                	je     f0101f4d <mem_init+0xd27>
f0101f34:	68 40 63 10 f0       	push   $0xf0106340
f0101f39:	68 6f 67 10 f0       	push   $0xf010676f
f0101f3e:	68 ff 03 00 00       	push   $0x3ff
f0101f43:	68 49 67 10 f0       	push   $0xf0106749
f0101f48:	e8 f3 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101f4d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f52:	75 19                	jne    f0101f6d <mem_init+0xd47>
f0101f54:	68 9f 69 10 f0       	push   $0xf010699f
f0101f59:	68 6f 67 10 f0       	push   $0xf010676f
f0101f5e:	68 00 04 00 00       	push   $0x400
f0101f63:	68 49 67 10 f0       	push   $0xf0106749
f0101f68:	e8 d3 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101f6d:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f70:	74 19                	je     f0101f8b <mem_init+0xd65>
f0101f72:	68 ab 69 10 f0       	push   $0xf01069ab
f0101f77:	68 6f 67 10 f0       	push   $0xf010676f
f0101f7c:	68 01 04 00 00       	push   $0x401
f0101f81:	68 49 67 10 f0       	push   $0xf0106749
f0101f86:	e8 b5 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f8b:	83 ec 08             	sub    $0x8,%esp
f0101f8e:	68 00 10 00 00       	push   $0x1000
f0101f93:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0101f99:	e8 60 f1 ff ff       	call   f01010fe <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f9e:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
f0101fa4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fa9:	89 f8                	mov    %edi,%eax
f0101fab:	e8 ab ea ff ff       	call   f0100a5b <check_va2pa>
f0101fb0:	83 c4 10             	add    $0x10,%esp
f0101fb3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fb6:	74 19                	je     f0101fd1 <mem_init+0xdab>
f0101fb8:	68 1c 63 10 f0       	push   $0xf010631c
f0101fbd:	68 6f 67 10 f0       	push   $0xf010676f
f0101fc2:	68 05 04 00 00       	push   $0x405
f0101fc7:	68 49 67 10 f0       	push   $0xf0106749
f0101fcc:	e8 6f e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fd1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fd6:	89 f8                	mov    %edi,%eax
f0101fd8:	e8 7e ea ff ff       	call   f0100a5b <check_va2pa>
f0101fdd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fe0:	74 19                	je     f0101ffb <mem_init+0xdd5>
f0101fe2:	68 78 63 10 f0       	push   $0xf0106378
f0101fe7:	68 6f 67 10 f0       	push   $0xf010676f
f0101fec:	68 06 04 00 00       	push   $0x406
f0101ff1:	68 49 67 10 f0       	push   $0xf0106749
f0101ff6:	e8 45 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0101ffb:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102000:	74 19                	je     f010201b <mem_init+0xdf5>
f0102002:	68 c0 69 10 f0       	push   $0xf01069c0
f0102007:	68 6f 67 10 f0       	push   $0xf010676f
f010200c:	68 07 04 00 00       	push   $0x407
f0102011:	68 49 67 10 f0       	push   $0xf0106749
f0102016:	e8 25 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010201b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102020:	74 19                	je     f010203b <mem_init+0xe15>
f0102022:	68 8e 69 10 f0       	push   $0xf010698e
f0102027:	68 6f 67 10 f0       	push   $0xf010676f
f010202c:	68 08 04 00 00       	push   $0x408
f0102031:	68 49 67 10 f0       	push   $0xf0106749
f0102036:	e8 05 e0 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010203b:	83 ec 0c             	sub    $0xc,%esp
f010203e:	6a 00                	push   $0x0
f0102040:	e8 65 ee ff ff       	call   f0100eaa <page_alloc>
f0102045:	83 c4 10             	add    $0x10,%esp
f0102048:	85 c0                	test   %eax,%eax
f010204a:	74 04                	je     f0102050 <mem_init+0xe2a>
f010204c:	39 c3                	cmp    %eax,%ebx
f010204e:	74 19                	je     f0102069 <mem_init+0xe43>
f0102050:	68 a0 63 10 f0       	push   $0xf01063a0
f0102055:	68 6f 67 10 f0       	push   $0xf010676f
f010205a:	68 0b 04 00 00       	push   $0x40b
f010205f:	68 49 67 10 f0       	push   $0xf0106749
f0102064:	e8 d7 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102069:	83 ec 0c             	sub    $0xc,%esp
f010206c:	6a 00                	push   $0x0
f010206e:	e8 37 ee ff ff       	call   f0100eaa <page_alloc>
f0102073:	83 c4 10             	add    $0x10,%esp
f0102076:	85 c0                	test   %eax,%eax
f0102078:	74 19                	je     f0102093 <mem_init+0xe6d>
f010207a:	68 e2 68 10 f0       	push   $0xf01068e2
f010207f:	68 6f 67 10 f0       	push   $0xf010676f
f0102084:	68 0e 04 00 00       	push   $0x40e
f0102089:	68 49 67 10 f0       	push   $0xf0106749
f010208e:	e8 ad df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102093:	8b 0d 8c 9e 22 f0    	mov    0xf0229e8c,%ecx
f0102099:	8b 11                	mov    (%ecx),%edx
f010209b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01020a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020a4:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f01020aa:	c1 f8 03             	sar    $0x3,%eax
f01020ad:	c1 e0 0c             	shl    $0xc,%eax
f01020b0:	39 c2                	cmp    %eax,%edx
f01020b2:	74 19                	je     f01020cd <mem_init+0xea7>
f01020b4:	68 40 60 10 f0       	push   $0xf0106040
f01020b9:	68 6f 67 10 f0       	push   $0xf010676f
f01020be:	68 11 04 00 00       	push   $0x411
f01020c3:	68 49 67 10 f0       	push   $0xf0106749
f01020c8:	e8 73 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01020cd:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020db:	74 19                	je     f01020f6 <mem_init+0xed0>
f01020dd:	68 45 69 10 f0       	push   $0xf0106945
f01020e2:	68 6f 67 10 f0       	push   $0xf010676f
f01020e7:	68 13 04 00 00       	push   $0x413
f01020ec:	68 49 67 10 f0       	push   $0xf0106749
f01020f1:	e8 4a df ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01020f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020f9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020ff:	83 ec 0c             	sub    $0xc,%esp
f0102102:	50                   	push   %eax
f0102103:	e8 12 ee ff ff       	call   f0100f1a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102108:	83 c4 0c             	add    $0xc,%esp
f010210b:	6a 01                	push   $0x1
f010210d:	68 00 10 40 00       	push   $0x401000
f0102112:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102118:	e8 61 ee ff ff       	call   f0100f7e <pgdir_walk>
f010211d:	89 c7                	mov    %eax,%edi
f010211f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102122:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f0102127:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010212a:	8b 40 04             	mov    0x4(%eax),%eax
f010212d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102132:	8b 0d 88 9e 22 f0    	mov    0xf0229e88,%ecx
f0102138:	89 c2                	mov    %eax,%edx
f010213a:	c1 ea 0c             	shr    $0xc,%edx
f010213d:	83 c4 10             	add    $0x10,%esp
f0102140:	39 ca                	cmp    %ecx,%edx
f0102142:	72 15                	jb     f0102159 <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102144:	50                   	push   %eax
f0102145:	68 e4 58 10 f0       	push   $0xf01058e4
f010214a:	68 1a 04 00 00       	push   $0x41a
f010214f:	68 49 67 10 f0       	push   $0xf0106749
f0102154:	e8 e7 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102159:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010215e:	39 c7                	cmp    %eax,%edi
f0102160:	74 19                	je     f010217b <mem_init+0xf55>
f0102162:	68 d1 69 10 f0       	push   $0xf01069d1
f0102167:	68 6f 67 10 f0       	push   $0xf010676f
f010216c:	68 1b 04 00 00       	push   $0x41b
f0102171:	68 49 67 10 f0       	push   $0xf0106749
f0102176:	e8 c5 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010217b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010217e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102185:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102188:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010218e:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0102194:	c1 f8 03             	sar    $0x3,%eax
f0102197:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010219a:	89 c2                	mov    %eax,%edx
f010219c:	c1 ea 0c             	shr    $0xc,%edx
f010219f:	39 d1                	cmp    %edx,%ecx
f01021a1:	77 12                	ja     f01021b5 <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021a3:	50                   	push   %eax
f01021a4:	68 e4 58 10 f0       	push   $0xf01058e4
f01021a9:	6a 58                	push   $0x58
f01021ab:	68 55 67 10 f0       	push   $0xf0106755
f01021b0:	e8 8b de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021b5:	83 ec 04             	sub    $0x4,%esp
f01021b8:	68 00 10 00 00       	push   $0x1000
f01021bd:	68 ff 00 00 00       	push   $0xff
f01021c2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01021c7:	50                   	push   %eax
f01021c8:	e8 35 2a 00 00       	call   f0104c02 <memset>
	page_free(pp0);
f01021cd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021d0:	89 3c 24             	mov    %edi,(%esp)
f01021d3:	e8 42 ed ff ff       	call   f0100f1a <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021d8:	83 c4 0c             	add    $0xc,%esp
f01021db:	6a 01                	push   $0x1
f01021dd:	6a 00                	push   $0x0
f01021df:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f01021e5:	e8 94 ed ff ff       	call   f0100f7e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021ea:	89 fa                	mov    %edi,%edx
f01021ec:	2b 15 90 9e 22 f0    	sub    0xf0229e90,%edx
f01021f2:	c1 fa 03             	sar    $0x3,%edx
f01021f5:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021f8:	89 d0                	mov    %edx,%eax
f01021fa:	c1 e8 0c             	shr    $0xc,%eax
f01021fd:	83 c4 10             	add    $0x10,%esp
f0102200:	3b 05 88 9e 22 f0    	cmp    0xf0229e88,%eax
f0102206:	72 12                	jb     f010221a <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102208:	52                   	push   %edx
f0102209:	68 e4 58 10 f0       	push   $0xf01058e4
f010220e:	6a 58                	push   $0x58
f0102210:	68 55 67 10 f0       	push   $0xf0106755
f0102215:	e8 26 de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010221a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102220:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102223:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102229:	f6 00 01             	testb  $0x1,(%eax)
f010222c:	74 19                	je     f0102247 <mem_init+0x1021>
f010222e:	68 e9 69 10 f0       	push   $0xf01069e9
f0102233:	68 6f 67 10 f0       	push   $0xf010676f
f0102238:	68 25 04 00 00       	push   $0x425
f010223d:	68 49 67 10 f0       	push   $0xf0106749
f0102242:	e8 f9 dd ff ff       	call   f0100040 <_panic>
f0102247:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010224a:	39 d0                	cmp    %edx,%eax
f010224c:	75 db                	jne    f0102229 <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010224e:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f0102253:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102259:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010225c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102262:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102265:	89 0d 40 92 22 f0    	mov    %ecx,0xf0229240

	// free the pages we took
	page_free(pp0);
f010226b:	83 ec 0c             	sub    $0xc,%esp
f010226e:	50                   	push   %eax
f010226f:	e8 a6 ec ff ff       	call   f0100f1a <page_free>
	page_free(pp1);
f0102274:	89 1c 24             	mov    %ebx,(%esp)
f0102277:	e8 9e ec ff ff       	call   f0100f1a <page_free>
	page_free(pp2);
f010227c:	89 34 24             	mov    %esi,(%esp)
f010227f:	e8 96 ec ff ff       	call   f0100f1a <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102284:	83 c4 08             	add    $0x8,%esp
f0102287:	68 01 10 00 00       	push   $0x1001
f010228c:	6a 00                	push   $0x0
f010228e:	e8 36 ef ff ff       	call   f01011c9 <mmio_map_region>
f0102293:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102295:	83 c4 08             	add    $0x8,%esp
f0102298:	68 00 10 00 00       	push   $0x1000
f010229d:	6a 00                	push   $0x0
f010229f:	e8 25 ef ff ff       	call   f01011c9 <mmio_map_region>
f01022a4:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01022a6:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01022ac:	83 c4 10             	add    $0x10,%esp
f01022af:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01022b5:	76 07                	jbe    f01022be <mem_init+0x1098>
f01022b7:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01022bc:	76 19                	jbe    f01022d7 <mem_init+0x10b1>
f01022be:	68 c4 63 10 f0       	push   $0xf01063c4
f01022c3:	68 6f 67 10 f0       	push   $0xf010676f
f01022c8:	68 35 04 00 00       	push   $0x435
f01022cd:	68 49 67 10 f0       	push   $0xf0106749
f01022d2:	e8 69 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01022d7:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01022dd:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01022e3:	77 08                	ja     f01022ed <mem_init+0x10c7>
f01022e5:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01022eb:	77 19                	ja     f0102306 <mem_init+0x10e0>
f01022ed:	68 ec 63 10 f0       	push   $0xf01063ec
f01022f2:	68 6f 67 10 f0       	push   $0xf010676f
f01022f7:	68 36 04 00 00       	push   $0x436
f01022fc:	68 49 67 10 f0       	push   $0xf0106749
f0102301:	e8 3a dd ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102306:	89 da                	mov    %ebx,%edx
f0102308:	09 f2                	or     %esi,%edx
f010230a:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102310:	74 19                	je     f010232b <mem_init+0x1105>
f0102312:	68 14 64 10 f0       	push   $0xf0106414
f0102317:	68 6f 67 10 f0       	push   $0xf010676f
f010231c:	68 38 04 00 00       	push   $0x438
f0102321:	68 49 67 10 f0       	push   $0xf0106749
f0102326:	e8 15 dd ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010232b:	39 c6                	cmp    %eax,%esi
f010232d:	73 19                	jae    f0102348 <mem_init+0x1122>
f010232f:	68 00 6a 10 f0       	push   $0xf0106a00
f0102334:	68 6f 67 10 f0       	push   $0xf010676f
f0102339:	68 3a 04 00 00       	push   $0x43a
f010233e:	68 49 67 10 f0       	push   $0xf0106749
f0102343:	e8 f8 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102348:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi
f010234e:	89 da                	mov    %ebx,%edx
f0102350:	89 f8                	mov    %edi,%eax
f0102352:	e8 04 e7 ff ff       	call   f0100a5b <check_va2pa>
f0102357:	85 c0                	test   %eax,%eax
f0102359:	74 19                	je     f0102374 <mem_init+0x114e>
f010235b:	68 3c 64 10 f0       	push   $0xf010643c
f0102360:	68 6f 67 10 f0       	push   $0xf010676f
f0102365:	68 3c 04 00 00       	push   $0x43c
f010236a:	68 49 67 10 f0       	push   $0xf0106749
f010236f:	e8 cc dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102374:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010237a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010237d:	89 c2                	mov    %eax,%edx
f010237f:	89 f8                	mov    %edi,%eax
f0102381:	e8 d5 e6 ff ff       	call   f0100a5b <check_va2pa>
f0102386:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010238b:	74 19                	je     f01023a6 <mem_init+0x1180>
f010238d:	68 60 64 10 f0       	push   $0xf0106460
f0102392:	68 6f 67 10 f0       	push   $0xf010676f
f0102397:	68 3d 04 00 00       	push   $0x43d
f010239c:	68 49 67 10 f0       	push   $0xf0106749
f01023a1:	e8 9a dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01023a6:	89 f2                	mov    %esi,%edx
f01023a8:	89 f8                	mov    %edi,%eax
f01023aa:	e8 ac e6 ff ff       	call   f0100a5b <check_va2pa>
f01023af:	85 c0                	test   %eax,%eax
f01023b1:	74 19                	je     f01023cc <mem_init+0x11a6>
f01023b3:	68 90 64 10 f0       	push   $0xf0106490
f01023b8:	68 6f 67 10 f0       	push   $0xf010676f
f01023bd:	68 3e 04 00 00       	push   $0x43e
f01023c2:	68 49 67 10 f0       	push   $0xf0106749
f01023c7:	e8 74 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01023cc:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01023d2:	89 f8                	mov    %edi,%eax
f01023d4:	e8 82 e6 ff ff       	call   f0100a5b <check_va2pa>
f01023d9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023dc:	74 19                	je     f01023f7 <mem_init+0x11d1>
f01023de:	68 b4 64 10 f0       	push   $0xf01064b4
f01023e3:	68 6f 67 10 f0       	push   $0xf010676f
f01023e8:	68 3f 04 00 00       	push   $0x43f
f01023ed:	68 49 67 10 f0       	push   $0xf0106749
f01023f2:	e8 49 dc ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01023f7:	83 ec 04             	sub    $0x4,%esp
f01023fa:	6a 00                	push   $0x0
f01023fc:	53                   	push   %ebx
f01023fd:	57                   	push   %edi
f01023fe:	e8 7b eb ff ff       	call   f0100f7e <pgdir_walk>
f0102403:	83 c4 10             	add    $0x10,%esp
f0102406:	f6 00 1a             	testb  $0x1a,(%eax)
f0102409:	75 19                	jne    f0102424 <mem_init+0x11fe>
f010240b:	68 e0 64 10 f0       	push   $0xf01064e0
f0102410:	68 6f 67 10 f0       	push   $0xf010676f
f0102415:	68 41 04 00 00       	push   $0x441
f010241a:	68 49 67 10 f0       	push   $0xf0106749
f010241f:	e8 1c dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102424:	83 ec 04             	sub    $0x4,%esp
f0102427:	6a 00                	push   $0x0
f0102429:	53                   	push   %ebx
f010242a:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102430:	e8 49 eb ff ff       	call   f0100f7e <pgdir_walk>
f0102435:	8b 00                	mov    (%eax),%eax
f0102437:	83 c4 10             	add    $0x10,%esp
f010243a:	83 e0 04             	and    $0x4,%eax
f010243d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102440:	74 19                	je     f010245b <mem_init+0x1235>
f0102442:	68 24 65 10 f0       	push   $0xf0106524
f0102447:	68 6f 67 10 f0       	push   $0xf010676f
f010244c:	68 42 04 00 00       	push   $0x442
f0102451:	68 49 67 10 f0       	push   $0xf0106749
f0102456:	e8 e5 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010245b:	83 ec 04             	sub    $0x4,%esp
f010245e:	6a 00                	push   $0x0
f0102460:	53                   	push   %ebx
f0102461:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102467:	e8 12 eb ff ff       	call   f0100f7e <pgdir_walk>
f010246c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102472:	83 c4 0c             	add    $0xc,%esp
f0102475:	6a 00                	push   $0x0
f0102477:	ff 75 d4             	pushl  -0x2c(%ebp)
f010247a:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102480:	e8 f9 ea ff ff       	call   f0100f7e <pgdir_walk>
f0102485:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010248b:	83 c4 0c             	add    $0xc,%esp
f010248e:	6a 00                	push   $0x0
f0102490:	56                   	push   %esi
f0102491:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102497:	e8 e2 ea ff ff       	call   f0100f7e <pgdir_walk>
f010249c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01024a2:	c7 04 24 12 6a 10 f0 	movl   $0xf0106a12,(%esp)
f01024a9:	e8 0d 11 00 00       	call   f01035bb <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f01024ae:	a1 90 9e 22 f0       	mov    0xf0229e90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024b3:	83 c4 10             	add    $0x10,%esp
f01024b6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024bb:	77 15                	ja     f01024d2 <mem_init+0x12ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01024bd:	50                   	push   %eax
f01024be:	68 08 59 10 f0       	push   $0xf0105908
f01024c3:	68 b9 00 00 00       	push   $0xb9
f01024c8:	68 49 67 10 f0       	push   $0xf0106749
f01024cd:	e8 6e db ff ff       	call   f0100040 <_panic>
f01024d2:	83 ec 08             	sub    $0x8,%esp
f01024d5:	6a 05                	push   $0x5
f01024d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01024dc:	50                   	push   %eax
f01024dd:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01024e2:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024e7:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f01024ec:	e8 20 eb ff ff       	call   f0101011 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U|PTE_P);
f01024f1:	a1 44 92 22 f0       	mov    0xf0229244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024f6:	83 c4 10             	add    $0x10,%esp
f01024f9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024fe:	77 15                	ja     f0102515 <mem_init+0x12ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102500:	50                   	push   %eax
f0102501:	68 08 59 10 f0       	push   $0xf0105908
f0102506:	68 c1 00 00 00       	push   $0xc1
f010250b:	68 49 67 10 f0       	push   $0xf0106749
f0102510:	e8 2b db ff ff       	call   f0100040 <_panic>
f0102515:	83 ec 08             	sub    $0x8,%esp
f0102518:	6a 05                	push   $0x5
f010251a:	05 00 00 00 10       	add    $0x10000000,%eax
f010251f:	50                   	push   %eax
f0102520:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102525:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010252a:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f010252f:	e8 dd ea ff ff       	call   f0101011 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102534:	83 c4 10             	add    $0x10,%esp
f0102537:	b8 00 40 11 f0       	mov    $0xf0114000,%eax
f010253c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102541:	77 15                	ja     f0102558 <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102543:	50                   	push   %eax
f0102544:	68 08 59 10 f0       	push   $0xf0105908
f0102549:	68 cd 00 00 00       	push   $0xcd
f010254e:	68 49 67 10 f0       	push   $0xf0106749
f0102553:	e8 e8 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f0102558:	83 ec 08             	sub    $0x8,%esp
f010255b:	6a 03                	push   $0x3
f010255d:	68 00 40 11 00       	push   $0x114000
f0102562:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102567:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010256c:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f0102571:	e8 9b ea ff ff       	call   f0101011 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,ROUNDUP(0xffffffff-KERNBASE,PGSIZE),0x0,PTE_W|PTE_P);
f0102576:	83 c4 08             	add    $0x8,%esp
f0102579:	6a 03                	push   $0x3
f010257b:	6a 00                	push   $0x0
f010257d:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102582:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102587:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f010258c:	e8 80 ea ff ff       	call   f0101011 <boot_map_region>
f0102591:	c7 45 c4 00 b0 22 f0 	movl   $0xf022b000,-0x3c(%ebp)
f0102598:	83 c4 10             	add    $0x10,%esp
f010259b:	bb 00 b0 22 f0       	mov    $0xf022b000,%ebx
f01025a0:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025a5:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01025ab:	77 15                	ja     f01025c2 <mem_init+0x139c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ad:	53                   	push   %ebx
f01025ae:	68 08 59 10 f0       	push   $0xf0105908
f01025b3:	68 0f 01 00 00       	push   $0x10f
f01025b8:	68 49 67 10 f0       	push   $0xf0106749
f01025bd:	e8 7e da ff ff       	call   f0100040 <_panic>
	int i;
	//uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	for(i=0;i<NCPU;i++)
	{
		uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir,kstacktop_i-KSTKSIZE,KSTKSIZE,PADDR(percpu_kstacks[i]),PTE_W|PTE_P);
f01025c2:	83 ec 08             	sub    $0x8,%esp
f01025c5:	6a 03                	push   $0x3
f01025c7:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01025cd:	50                   	push   %eax
f01025ce:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025d3:	89 f2                	mov    %esi,%edx
f01025d5:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
f01025da:	e8 32 ea ff ff       	call   f0101011 <boot_map_region>
f01025df:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01025e5:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	int i;
	//uintptr_t kstacktop_i=KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	for(i=0;i<NCPU;i++)
f01025eb:	83 c4 10             	add    $0x10,%esp
f01025ee:	b8 00 b0 26 f0       	mov    $0xf026b000,%eax
f01025f3:	39 d8                	cmp    %ebx,%eax
f01025f5:	75 ae                	jne    f01025a5 <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025f7:	8b 3d 8c 9e 22 f0    	mov    0xf0229e8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01025fd:	a1 88 9e 22 f0       	mov    0xf0229e88,%eax
f0102602:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102605:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010260c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102611:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102614:	8b 35 90 9e 22 f0    	mov    0xf0229e90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010261a:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010261d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102622:	eb 55                	jmp    f0102679 <mem_init+0x1453>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102624:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010262a:	89 f8                	mov    %edi,%eax
f010262c:	e8 2a e4 ff ff       	call   f0100a5b <check_va2pa>
f0102631:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102638:	77 15                	ja     f010264f <mem_init+0x1429>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010263a:	56                   	push   %esi
f010263b:	68 08 59 10 f0       	push   $0xf0105908
f0102640:	68 5b 03 00 00       	push   $0x35b
f0102645:	68 49 67 10 f0       	push   $0xf0106749
f010264a:	e8 f1 d9 ff ff       	call   f0100040 <_panic>
f010264f:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102656:	39 c2                	cmp    %eax,%edx
f0102658:	74 19                	je     f0102673 <mem_init+0x144d>
f010265a:	68 58 65 10 f0       	push   $0xf0106558
f010265f:	68 6f 67 10 f0       	push   $0xf010676f
f0102664:	68 5b 03 00 00       	push   $0x35b
f0102669:	68 49 67 10 f0       	push   $0xf0106749
f010266e:	e8 cd d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102673:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102679:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010267c:	77 a6                	ja     f0102624 <mem_init+0x13fe>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010267e:	8b 35 44 92 22 f0    	mov    0xf0229244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102684:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102687:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010268c:	89 da                	mov    %ebx,%edx
f010268e:	89 f8                	mov    %edi,%eax
f0102690:	e8 c6 e3 ff ff       	call   f0100a5b <check_va2pa>
f0102695:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010269c:	77 15                	ja     f01026b3 <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010269e:	56                   	push   %esi
f010269f:	68 08 59 10 f0       	push   $0xf0105908
f01026a4:	68 60 03 00 00       	push   $0x360
f01026a9:	68 49 67 10 f0       	push   $0xf0106749
f01026ae:	e8 8d d9 ff ff       	call   f0100040 <_panic>
f01026b3:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01026ba:	39 d0                	cmp    %edx,%eax
f01026bc:	74 19                	je     f01026d7 <mem_init+0x14b1>
f01026be:	68 8c 65 10 f0       	push   $0xf010658c
f01026c3:	68 6f 67 10 f0       	push   $0xf010676f
f01026c8:	68 60 03 00 00       	push   $0x360
f01026cd:	68 49 67 10 f0       	push   $0xf0106749
f01026d2:	e8 69 d9 ff ff       	call   f0100040 <_panic>
f01026d7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026dd:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01026e3:	75 a7                	jne    f010268c <mem_init+0x1466>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01026e5:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01026e8:	c1 e6 0c             	shl    $0xc,%esi
f01026eb:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026f0:	eb 30                	jmp    f0102722 <mem_init+0x14fc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01026f2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01026f8:	89 f8                	mov    %edi,%eax
f01026fa:	e8 5c e3 ff ff       	call   f0100a5b <check_va2pa>
f01026ff:	39 c3                	cmp    %eax,%ebx
f0102701:	74 19                	je     f010271c <mem_init+0x14f6>
f0102703:	68 c0 65 10 f0       	push   $0xf01065c0
f0102708:	68 6f 67 10 f0       	push   $0xf010676f
f010270d:	68 64 03 00 00       	push   $0x364
f0102712:	68 49 67 10 f0       	push   $0xf0106749
f0102717:	e8 24 d9 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010271c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102722:	39 f3                	cmp    %esi,%ebx
f0102724:	72 cc                	jb     f01026f2 <mem_init+0x14cc>
f0102726:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010272b:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010272e:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102731:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102734:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010273a:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010273d:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010273f:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102742:	05 00 80 00 20       	add    $0x20008000,%eax
f0102747:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010274a:	89 da                	mov    %ebx,%edx
f010274c:	89 f8                	mov    %edi,%eax
f010274e:	e8 08 e3 ff ff       	call   f0100a5b <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102753:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102759:	77 15                	ja     f0102770 <mem_init+0x154a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010275b:	56                   	push   %esi
f010275c:	68 08 59 10 f0       	push   $0xf0105908
f0102761:	68 6c 03 00 00       	push   $0x36c
f0102766:	68 49 67 10 f0       	push   $0xf0106749
f010276b:	e8 d0 d8 ff ff       	call   f0100040 <_panic>
f0102770:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102773:	8d 94 0b 00 b0 22 f0 	lea    -0xfdd5000(%ebx,%ecx,1),%edx
f010277a:	39 d0                	cmp    %edx,%eax
f010277c:	74 19                	je     f0102797 <mem_init+0x1571>
f010277e:	68 e8 65 10 f0       	push   $0xf01065e8
f0102783:	68 6f 67 10 f0       	push   $0xf010676f
f0102788:	68 6c 03 00 00       	push   $0x36c
f010278d:	68 49 67 10 f0       	push   $0xf0106749
f0102792:	e8 a9 d8 ff ff       	call   f0100040 <_panic>
f0102797:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010279d:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01027a0:	75 a8                	jne    f010274a <mem_init+0x1524>
f01027a2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027a5:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01027ab:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027ae:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01027b0:	89 da                	mov    %ebx,%edx
f01027b2:	89 f8                	mov    %edi,%eax
f01027b4:	e8 a2 e2 ff ff       	call   f0100a5b <check_va2pa>
f01027b9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027bc:	74 19                	je     f01027d7 <mem_init+0x15b1>
f01027be:	68 30 66 10 f0       	push   $0xf0106630
f01027c3:	68 6f 67 10 f0       	push   $0xf010676f
f01027c8:	68 6e 03 00 00       	push   $0x36e
f01027cd:	68 49 67 10 f0       	push   $0xf0106749
f01027d2:	e8 69 d8 ff ff       	call   f0100040 <_panic>
f01027d7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01027dd:	39 f3                	cmp    %esi,%ebx
f01027df:	75 cf                	jne    f01027b0 <mem_init+0x158a>
f01027e1:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01027e4:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01027eb:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01027f2:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01027f8:	b8 00 b0 26 f0       	mov    $0xf026b000,%eax
f01027fd:	39 f0                	cmp    %esi,%eax
f01027ff:	0f 85 2c ff ff ff    	jne    f0102731 <mem_init+0x150b>
f0102805:	b8 00 00 00 00       	mov    $0x0,%eax
f010280a:	eb 2a                	jmp    f0102836 <mem_init+0x1610>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010280c:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102812:	83 fa 04             	cmp    $0x4,%edx
f0102815:	77 1f                	ja     f0102836 <mem_init+0x1610>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102817:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010281b:	75 7e                	jne    f010289b <mem_init+0x1675>
f010281d:	68 2b 6a 10 f0       	push   $0xf0106a2b
f0102822:	68 6f 67 10 f0       	push   $0xf010676f
f0102827:	68 79 03 00 00       	push   $0x379
f010282c:	68 49 67 10 f0       	push   $0xf0106749
f0102831:	e8 0a d8 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102836:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010283b:	76 3f                	jbe    f010287c <mem_init+0x1656>
				assert(pgdir[i] & PTE_P);
f010283d:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102840:	f6 c2 01             	test   $0x1,%dl
f0102843:	75 19                	jne    f010285e <mem_init+0x1638>
f0102845:	68 2b 6a 10 f0       	push   $0xf0106a2b
f010284a:	68 6f 67 10 f0       	push   $0xf010676f
f010284f:	68 7d 03 00 00       	push   $0x37d
f0102854:	68 49 67 10 f0       	push   $0xf0106749
f0102859:	e8 e2 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010285e:	f6 c2 02             	test   $0x2,%dl
f0102861:	75 38                	jne    f010289b <mem_init+0x1675>
f0102863:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0102868:	68 6f 67 10 f0       	push   $0xf010676f
f010286d:	68 7e 03 00 00       	push   $0x37e
f0102872:	68 49 67 10 f0       	push   $0xf0106749
f0102877:	e8 c4 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010287c:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102880:	74 19                	je     f010289b <mem_init+0x1675>
f0102882:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0102887:	68 6f 67 10 f0       	push   $0xf010676f
f010288c:	68 80 03 00 00       	push   $0x380
f0102891:	68 49 67 10 f0       	push   $0xf0106749
f0102896:	e8 a5 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010289b:	83 c0 01             	add    $0x1,%eax
f010289e:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01028a3:	0f 86 63 ff ff ff    	jbe    f010280c <mem_init+0x15e6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028a9:	83 ec 0c             	sub    $0xc,%esp
f01028ac:	68 54 66 10 f0       	push   $0xf0106654
f01028b1:	e8 05 0d 00 00       	call   f01035bb <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028b6:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028bb:	83 c4 10             	add    $0x10,%esp
f01028be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028c3:	77 15                	ja     f01028da <mem_init+0x16b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028c5:	50                   	push   %eax
f01028c6:	68 08 59 10 f0       	push   $0xf0105908
f01028cb:	68 e5 00 00 00       	push   $0xe5
f01028d0:	68 49 67 10 f0       	push   $0xf0106749
f01028d5:	e8 66 d7 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01028da:	05 00 00 00 10       	add    $0x10000000,%eax
f01028df:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01028e7:	e8 d3 e1 ff ff       	call   f0100abf <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01028ec:	0f 20 c0             	mov    %cr0,%eax
f01028ef:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01028f2:	0d 23 00 05 80       	or     $0x80050023,%eax
f01028f7:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028fa:	83 ec 0c             	sub    $0xc,%esp
f01028fd:	6a 00                	push   $0x0
f01028ff:	e8 a6 e5 ff ff       	call   f0100eaa <page_alloc>
f0102904:	89 c3                	mov    %eax,%ebx
f0102906:	83 c4 10             	add    $0x10,%esp
f0102909:	85 c0                	test   %eax,%eax
f010290b:	75 19                	jne    f0102926 <mem_init+0x1700>
f010290d:	68 37 68 10 f0       	push   $0xf0106837
f0102912:	68 6f 67 10 f0       	push   $0xf010676f
f0102917:	68 57 04 00 00       	push   $0x457
f010291c:	68 49 67 10 f0       	push   $0xf0106749
f0102921:	e8 1a d7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102926:	83 ec 0c             	sub    $0xc,%esp
f0102929:	6a 00                	push   $0x0
f010292b:	e8 7a e5 ff ff       	call   f0100eaa <page_alloc>
f0102930:	89 c7                	mov    %eax,%edi
f0102932:	83 c4 10             	add    $0x10,%esp
f0102935:	85 c0                	test   %eax,%eax
f0102937:	75 19                	jne    f0102952 <mem_init+0x172c>
f0102939:	68 4d 68 10 f0       	push   $0xf010684d
f010293e:	68 6f 67 10 f0       	push   $0xf010676f
f0102943:	68 58 04 00 00       	push   $0x458
f0102948:	68 49 67 10 f0       	push   $0xf0106749
f010294d:	e8 ee d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102952:	83 ec 0c             	sub    $0xc,%esp
f0102955:	6a 00                	push   $0x0
f0102957:	e8 4e e5 ff ff       	call   f0100eaa <page_alloc>
f010295c:	89 c6                	mov    %eax,%esi
f010295e:	83 c4 10             	add    $0x10,%esp
f0102961:	85 c0                	test   %eax,%eax
f0102963:	75 19                	jne    f010297e <mem_init+0x1758>
f0102965:	68 63 68 10 f0       	push   $0xf0106863
f010296a:	68 6f 67 10 f0       	push   $0xf010676f
f010296f:	68 59 04 00 00       	push   $0x459
f0102974:	68 49 67 10 f0       	push   $0xf0106749
f0102979:	e8 c2 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f010297e:	83 ec 0c             	sub    $0xc,%esp
f0102981:	53                   	push   %ebx
f0102982:	e8 93 e5 ff ff       	call   f0100f1a <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102987:	89 f8                	mov    %edi,%eax
f0102989:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f010298f:	c1 f8 03             	sar    $0x3,%eax
f0102992:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102995:	89 c2                	mov    %eax,%edx
f0102997:	c1 ea 0c             	shr    $0xc,%edx
f010299a:	83 c4 10             	add    $0x10,%esp
f010299d:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f01029a3:	72 12                	jb     f01029b7 <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029a5:	50                   	push   %eax
f01029a6:	68 e4 58 10 f0       	push   $0xf01058e4
f01029ab:	6a 58                	push   $0x58
f01029ad:	68 55 67 10 f0       	push   $0xf0106755
f01029b2:	e8 89 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029b7:	83 ec 04             	sub    $0x4,%esp
f01029ba:	68 00 10 00 00       	push   $0x1000
f01029bf:	6a 01                	push   $0x1
f01029c1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029c6:	50                   	push   %eax
f01029c7:	e8 36 22 00 00       	call   f0104c02 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029cc:	89 f0                	mov    %esi,%eax
f01029ce:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f01029d4:	c1 f8 03             	sar    $0x3,%eax
f01029d7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029da:	89 c2                	mov    %eax,%edx
f01029dc:	c1 ea 0c             	shr    $0xc,%edx
f01029df:	83 c4 10             	add    $0x10,%esp
f01029e2:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f01029e8:	72 12                	jb     f01029fc <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029ea:	50                   	push   %eax
f01029eb:	68 e4 58 10 f0       	push   $0xf01058e4
f01029f0:	6a 58                	push   $0x58
f01029f2:	68 55 67 10 f0       	push   $0xf0106755
f01029f7:	e8 44 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01029fc:	83 ec 04             	sub    $0x4,%esp
f01029ff:	68 00 10 00 00       	push   $0x1000
f0102a04:	6a 02                	push   $0x2
f0102a06:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a0b:	50                   	push   %eax
f0102a0c:	e8 f1 21 00 00       	call   f0104c02 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a11:	6a 02                	push   $0x2
f0102a13:	68 00 10 00 00       	push   $0x1000
f0102a18:	57                   	push   %edi
f0102a19:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102a1f:	e8 27 e7 ff ff       	call   f010114b <page_insert>
	assert(pp1->pp_ref == 1);
f0102a24:	83 c4 20             	add    $0x20,%esp
f0102a27:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a2c:	74 19                	je     f0102a47 <mem_init+0x1821>
f0102a2e:	68 34 69 10 f0       	push   $0xf0106934
f0102a33:	68 6f 67 10 f0       	push   $0xf010676f
f0102a38:	68 5e 04 00 00       	push   $0x45e
f0102a3d:	68 49 67 10 f0       	push   $0xf0106749
f0102a42:	e8 f9 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a47:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a4e:	01 01 01 
f0102a51:	74 19                	je     f0102a6c <mem_init+0x1846>
f0102a53:	68 74 66 10 f0       	push   $0xf0106674
f0102a58:	68 6f 67 10 f0       	push   $0xf010676f
f0102a5d:	68 5f 04 00 00       	push   $0x45f
f0102a62:	68 49 67 10 f0       	push   $0xf0106749
f0102a67:	e8 d4 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a6c:	6a 02                	push   $0x2
f0102a6e:	68 00 10 00 00       	push   $0x1000
f0102a73:	56                   	push   %esi
f0102a74:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102a7a:	e8 cc e6 ff ff       	call   f010114b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a7f:	83 c4 10             	add    $0x10,%esp
f0102a82:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a89:	02 02 02 
f0102a8c:	74 19                	je     f0102aa7 <mem_init+0x1881>
f0102a8e:	68 98 66 10 f0       	push   $0xf0106698
f0102a93:	68 6f 67 10 f0       	push   $0xf010676f
f0102a98:	68 61 04 00 00       	push   $0x461
f0102a9d:	68 49 67 10 f0       	push   $0xf0106749
f0102aa2:	e8 99 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102aa7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102aac:	74 19                	je     f0102ac7 <mem_init+0x18a1>
f0102aae:	68 56 69 10 f0       	push   $0xf0106956
f0102ab3:	68 6f 67 10 f0       	push   $0xf010676f
f0102ab8:	68 62 04 00 00       	push   $0x462
f0102abd:	68 49 67 10 f0       	push   $0xf0106749
f0102ac2:	e8 79 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ac7:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102acc:	74 19                	je     f0102ae7 <mem_init+0x18c1>
f0102ace:	68 c0 69 10 f0       	push   $0xf01069c0
f0102ad3:	68 6f 67 10 f0       	push   $0xf010676f
f0102ad8:	68 63 04 00 00       	push   $0x463
f0102add:	68 49 67 10 f0       	push   $0xf0106749
f0102ae2:	e8 59 d5 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ae7:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102aee:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102af1:	89 f0                	mov    %esi,%eax
f0102af3:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0102af9:	c1 f8 03             	sar    $0x3,%eax
f0102afc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102aff:	89 c2                	mov    %eax,%edx
f0102b01:	c1 ea 0c             	shr    $0xc,%edx
f0102b04:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0102b0a:	72 12                	jb     f0102b1e <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b0c:	50                   	push   %eax
f0102b0d:	68 e4 58 10 f0       	push   $0xf01058e4
f0102b12:	6a 58                	push   $0x58
f0102b14:	68 55 67 10 f0       	push   $0xf0106755
f0102b19:	e8 22 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b1e:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b25:	03 03 03 
f0102b28:	74 19                	je     f0102b43 <mem_init+0x191d>
f0102b2a:	68 bc 66 10 f0       	push   $0xf01066bc
f0102b2f:	68 6f 67 10 f0       	push   $0xf010676f
f0102b34:	68 65 04 00 00       	push   $0x465
f0102b39:	68 49 67 10 f0       	push   $0xf0106749
f0102b3e:	e8 fd d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b43:	83 ec 08             	sub    $0x8,%esp
f0102b46:	68 00 10 00 00       	push   $0x1000
f0102b4b:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102b51:	e8 a8 e5 ff ff       	call   f01010fe <page_remove>
	assert(pp2->pp_ref == 0);
f0102b56:	83 c4 10             	add    $0x10,%esp
f0102b59:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b5e:	74 19                	je     f0102b79 <mem_init+0x1953>
f0102b60:	68 8e 69 10 f0       	push   $0xf010698e
f0102b65:	68 6f 67 10 f0       	push   $0xf010676f
f0102b6a:	68 67 04 00 00       	push   $0x467
f0102b6f:	68 49 67 10 f0       	push   $0xf0106749
f0102b74:	e8 c7 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b79:	8b 0d 8c 9e 22 f0    	mov    0xf0229e8c,%ecx
f0102b7f:	8b 11                	mov    (%ecx),%edx
f0102b81:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b87:	89 d8                	mov    %ebx,%eax
f0102b89:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0102b8f:	c1 f8 03             	sar    $0x3,%eax
f0102b92:	c1 e0 0c             	shl    $0xc,%eax
f0102b95:	39 c2                	cmp    %eax,%edx
f0102b97:	74 19                	je     f0102bb2 <mem_init+0x198c>
f0102b99:	68 40 60 10 f0       	push   $0xf0106040
f0102b9e:	68 6f 67 10 f0       	push   $0xf010676f
f0102ba3:	68 6a 04 00 00       	push   $0x46a
f0102ba8:	68 49 67 10 f0       	push   $0xf0106749
f0102bad:	e8 8e d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102bb2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102bb8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102bbd:	74 19                	je     f0102bd8 <mem_init+0x19b2>
f0102bbf:	68 45 69 10 f0       	push   $0xf0106945
f0102bc4:	68 6f 67 10 f0       	push   $0xf010676f
f0102bc9:	68 6c 04 00 00       	push   $0x46c
f0102bce:	68 49 67 10 f0       	push   $0xf0106749
f0102bd3:	e8 68 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102bd8:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102bde:	83 ec 0c             	sub    $0xc,%esp
f0102be1:	53                   	push   %ebx
f0102be2:	e8 33 e3 ff ff       	call   f0100f1a <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102be7:	c7 04 24 e8 66 10 f0 	movl   $0xf01066e8,(%esp)
f0102bee:	e8 c8 09 00 00       	call   f01035bb <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102bf3:	83 c4 10             	add    $0x10,%esp
f0102bf6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bf9:	5b                   	pop    %ebx
f0102bfa:	5e                   	pop    %esi
f0102bfb:	5f                   	pop    %edi
f0102bfc:	5d                   	pop    %ebp
f0102bfd:	c3                   	ret    

f0102bfe <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102bfe:	55                   	push   %ebp
f0102bff:	89 e5                	mov    %esp,%ebp
f0102c01:	57                   	push   %edi
f0102c02:	56                   	push   %esi
f0102c03:	53                   	push   %ebx
f0102c04:	83 ec 1c             	sub    $0x1c,%esp
f0102c07:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102c0a:	8b 45 0c             	mov    0xc(%ebp),%eax
	uintptr_t lva=(uintptr_t)va;
f0102c0d:	89 c3                	mov    %eax,%ebx
	uintptr_t rva=(uintptr_t)va+len-1;
f0102c0f:	8b 55 10             	mov    0x10(%ebp),%edx
f0102c12:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0102c16:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm=perm|PTE_U|PTE_P;
f0102c19:	8b 75 14             	mov    0x14(%ebp),%esi
f0102c1c:	83 ce 05             	or     $0x5,%esi
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f0102c1f:	eb 4b                	jmp    f0102c6c <user_mem_check+0x6e>
	{
		if(idx_va>=ULIM)
f0102c21:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102c27:	76 0d                	jbe    f0102c36 <user_mem_check+0x38>
		{
			user_mem_check_addr=idx_va;
f0102c29:	89 1d 3c 92 22 f0    	mov    %ebx,0xf022923c
			return-E_FAULT;
f0102c2f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c34:	eb 40                	jmp    f0102c76 <user_mem_check+0x78>
		}
		pte=pgdir_walk(env->env_pgdir,(void*)idx_va,0);
f0102c36:	83 ec 04             	sub    $0x4,%esp
f0102c39:	6a 00                	push   $0x0
f0102c3b:	53                   	push   %ebx
f0102c3c:	ff 77 60             	pushl  0x60(%edi)
f0102c3f:	e8 3a e3 ff ff       	call   f0100f7e <pgdir_walk>
		if(pte==NULL||(*pte&perm)!=perm)
f0102c44:	83 c4 10             	add    $0x10,%esp
f0102c47:	85 c0                	test   %eax,%eax
f0102c49:	74 08                	je     f0102c53 <user_mem_check+0x55>
f0102c4b:	89 f1                	mov    %esi,%ecx
f0102c4d:	23 08                	and    (%eax),%ecx
f0102c4f:	39 ce                	cmp    %ecx,%esi
f0102c51:	74 0d                	je     f0102c60 <user_mem_check+0x62>
		{
			user_mem_check_addr=idx_va;
f0102c53:	89 1d 3c 92 22 f0    	mov    %ebx,0xf022923c
			return-E_FAULT;
f0102c59:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c5e:	eb 16                	jmp    f0102c76 <user_mem_check+0x78>
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
f0102c60:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t lva=(uintptr_t)va;
	uintptr_t rva=(uintptr_t)va+len-1;
	perm=perm|PTE_U|PTE_P;
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f0102c66:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c6c:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102c6f:	76 b0                	jbe    f0102c21 <user_mem_check+0x23>
			user_mem_check_addr=idx_va;
			return-E_FAULT;
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
	}
	return	0;
f0102c71:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c76:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c79:	5b                   	pop    %ebx
f0102c7a:	5e                   	pop    %esi
f0102c7b:	5f                   	pop    %edi
f0102c7c:	5d                   	pop    %ebp
f0102c7d:	c3                   	ret    

f0102c7e <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102c7e:	55                   	push   %ebp
f0102c7f:	89 e5                	mov    %esp,%ebp
f0102c81:	53                   	push   %ebx
f0102c82:	83 ec 04             	sub    $0x4,%esp
f0102c85:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102c88:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c8b:	83 c8 04             	or     $0x4,%eax
f0102c8e:	50                   	push   %eax
f0102c8f:	ff 75 10             	pushl  0x10(%ebp)
f0102c92:	ff 75 0c             	pushl  0xc(%ebp)
f0102c95:	53                   	push   %ebx
f0102c96:	e8 63 ff ff ff       	call   f0102bfe <user_mem_check>
f0102c9b:	83 c4 10             	add    $0x10,%esp
f0102c9e:	85 c0                	test   %eax,%eax
f0102ca0:	79 21                	jns    f0102cc3 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102ca2:	83 ec 04             	sub    $0x4,%esp
f0102ca5:	ff 35 3c 92 22 f0    	pushl  0xf022923c
f0102cab:	ff 73 48             	pushl  0x48(%ebx)
f0102cae:	68 14 67 10 f0       	push   $0xf0106714
f0102cb3:	e8 03 09 00 00       	call   f01035bb <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102cb8:	89 1c 24             	mov    %ebx,(%esp)
f0102cbb:	e8 18 06 00 00       	call   f01032d8 <env_destroy>
f0102cc0:	83 c4 10             	add    $0x10,%esp
	}
}
f0102cc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102cc6:	c9                   	leave  
f0102cc7:	c3                   	ret    

f0102cc8 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102cc8:	55                   	push   %ebp
f0102cc9:	89 e5                	mov    %esp,%ebp
f0102ccb:	57                   	push   %edi
f0102ccc:	56                   	push   %esi
f0102ccd:	53                   	push   %ebx
f0102cce:	83 ec 0c             	sub    $0xc,%esp
f0102cd1:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
f0102cd3:	89 d3                	mov    %edx,%ebx
f0102cd5:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
f0102cdb:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102ce2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *pp;
	while(low<high)
f0102ce8:	eb 5d                	jmp    f0102d47 <region_alloc+0x7f>
	{
		pp=page_alloc(ALLOC_ZERO );
f0102cea:	83 ec 0c             	sub    $0xc,%esp
f0102ced:	6a 01                	push   $0x1
f0102cef:	e8 b6 e1 ff ff       	call   f0100eaa <page_alloc>
		pp->pp_ref++;
f0102cf4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		if(pp==NULL)
f0102cf9:	83 c4 10             	add    $0x10,%esp
f0102cfc:	85 c0                	test   %eax,%eax
f0102cfe:	75 17                	jne    f0102d17 <region_alloc+0x4f>
		{
			panic("page_alloc is wrong in region_alloc\n");
f0102d00:	83 ec 04             	sub    $0x4,%esp
f0102d03:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0102d08:	68 26 01 00 00       	push   $0x126
f0102d0d:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0102d12:	e8 29 d3 ff ff       	call   f0100040 <_panic>
		}
		int i=page_insert(e->env_pgdir,pp,(void *)low,PTE_P|PTE_U|PTE_W);
f0102d17:	6a 07                	push   $0x7
f0102d19:	53                   	push   %ebx
f0102d1a:	50                   	push   %eax
f0102d1b:	ff 77 60             	pushl  0x60(%edi)
f0102d1e:	e8 28 e4 ff ff       	call   f010114b <page_insert>
		if(i!=0)
f0102d23:	83 c4 10             	add    $0x10,%esp
f0102d26:	85 c0                	test   %eax,%eax
f0102d28:	74 17                	je     f0102d41 <region_alloc+0x79>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
f0102d2a:	83 ec 04             	sub    $0x4,%esp
f0102d2d:	68 84 6a 10 f0       	push   $0xf0106a84
f0102d32:	68 2b 01 00 00       	push   $0x12b
f0102d37:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0102d3c:	e8 ff d2 ff ff       	call   f0100040 <_panic>
		}
		low=low+PGSIZE;
f0102d41:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
	struct PageInfo *pp;
	while(low<high)
f0102d47:	39 f3                	cmp    %esi,%ebx
f0102d49:	72 9f                	jb     f0102cea <region_alloc+0x22>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
		}
		low=low+PGSIZE;
	}
} 
f0102d4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d4e:	5b                   	pop    %ebx
f0102d4f:	5e                   	pop    %esi
f0102d50:	5f                   	pop    %edi
f0102d51:	5d                   	pop    %ebp
f0102d52:	c3                   	ret    

f0102d53 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102d53:	55                   	push   %ebp
f0102d54:	89 e5                	mov    %esp,%ebp
f0102d56:	56                   	push   %esi
f0102d57:	53                   	push   %ebx
f0102d58:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d5b:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102d5e:	85 c0                	test   %eax,%eax
f0102d60:	75 1a                	jne    f0102d7c <envid2env+0x29>
		*env_store = curenv;
f0102d62:	e8 d0 24 00 00       	call   f0105237 <cpunum>
f0102d67:	6b c0 74             	imul   $0x74,%eax,%eax
f0102d6a:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102d70:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102d73:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102d75:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d7a:	eb 70                	jmp    f0102dec <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102d7c:	89 c3                	mov    %eax,%ebx
f0102d7e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102d84:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102d87:	03 1d 44 92 22 f0    	add    0xf0229244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102d8d:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102d91:	74 05                	je     f0102d98 <envid2env+0x45>
f0102d93:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102d96:	74 10                	je     f0102da8 <envid2env+0x55>
		*env_store = 0;
f0102d98:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d9b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102da1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102da6:	eb 44                	jmp    f0102dec <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102da8:	84 d2                	test   %dl,%dl
f0102daa:	74 36                	je     f0102de2 <envid2env+0x8f>
f0102dac:	e8 86 24 00 00       	call   f0105237 <cpunum>
f0102db1:	6b c0 74             	imul   $0x74,%eax,%eax
f0102db4:	3b 98 28 a0 22 f0    	cmp    -0xfdd5fd8(%eax),%ebx
f0102dba:	74 26                	je     f0102de2 <envid2env+0x8f>
f0102dbc:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102dbf:	e8 73 24 00 00       	call   f0105237 <cpunum>
f0102dc4:	6b c0 74             	imul   $0x74,%eax,%eax
f0102dc7:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102dcd:	3b 70 48             	cmp    0x48(%eax),%esi
f0102dd0:	74 10                	je     f0102de2 <envid2env+0x8f>
		*env_store = 0;
f0102dd2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dd5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ddb:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102de0:	eb 0a                	jmp    f0102dec <envid2env+0x99>
	}

	*env_store = e;
f0102de2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102de5:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102de7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102dec:	5b                   	pop    %ebx
f0102ded:	5e                   	pop    %esi
f0102dee:	5d                   	pop    %ebp
f0102def:	c3                   	ret    

f0102df0 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102df0:	55                   	push   %ebp
f0102df1:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102df3:	b8 20 e3 11 f0       	mov    $0xf011e320,%eax
f0102df8:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102dfb:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e00:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102e02:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102e04:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e09:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102e0b:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102e0d:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102e0f:	ea 16 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e16
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102e16:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e1b:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102e1e:	5d                   	pop    %ebp
f0102e1f:	c3                   	ret    

f0102e20 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102e20:	55                   	push   %ebp
f0102e21:	89 e5                	mov    %esp,%ebp
f0102e23:	56                   	push   %esi
f0102e24:	53                   	push   %ebx
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f0102e25:	8b 35 44 92 22 f0    	mov    0xf0229244,%esi
f0102e2b:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102e31:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102e34:	ba 00 00 00 00       	mov    $0x0,%edx
f0102e39:	89 c1                	mov    %eax,%ecx
f0102e3b:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status=ENV_FREE;
f0102e42:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link=env_free_list;
f0102e49:	89 50 44             	mov    %edx,0x44(%eax)
f0102e4c:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list=&envs[i];
f0102e4f:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
f0102e51:	39 d8                	cmp    %ebx,%eax
f0102e53:	75 e4                	jne    f0102e39 <env_init+0x19>
f0102e55:	89 35 48 92 22 f0    	mov    %esi,0xf0229248
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}	
	//cprintf("%d\n",sizeof(struct Env));	
	// Per-CPU part of the initialization
	env_init_percpu();
f0102e5b:	e8 90 ff ff ff       	call   f0102df0 <env_init_percpu>
}
f0102e60:	5b                   	pop    %ebx
f0102e61:	5e                   	pop    %esi
f0102e62:	5d                   	pop    %ebp
f0102e63:	c3                   	ret    

f0102e64 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102e64:	55                   	push   %ebp
f0102e65:	89 e5                	mov    %esp,%ebp
f0102e67:	53                   	push   %ebx
f0102e68:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102e6b:	8b 1d 48 92 22 f0    	mov    0xf0229248,%ebx
f0102e71:	85 db                	test   %ebx,%ebx
f0102e73:	0f 84 62 01 00 00    	je     f0102fdb <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102e79:	83 ec 0c             	sub    $0xc,%esp
f0102e7c:	6a 01                	push   $0x1
f0102e7e:	e8 27 e0 ff ff       	call   f0100eaa <page_alloc>
f0102e83:	83 c4 10             	add    $0x10,%esp
f0102e86:	85 c0                	test   %eax,%eax
f0102e88:	0f 84 54 01 00 00    	je     f0102fe2 <env_alloc+0x17e>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102e8e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e93:	2b 05 90 9e 22 f0    	sub    0xf0229e90,%eax
f0102e99:	c1 f8 03             	sar    $0x3,%eax
f0102e9c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e9f:	89 c2                	mov    %eax,%edx
f0102ea1:	c1 ea 0c             	shr    $0xc,%edx
f0102ea4:	3b 15 88 9e 22 f0    	cmp    0xf0229e88,%edx
f0102eaa:	72 12                	jb     f0102ebe <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102eac:	50                   	push   %eax
f0102ead:	68 e4 58 10 f0       	push   $0xf01058e4
f0102eb2:	6a 58                	push   $0x58
f0102eb4:	68 55 67 10 f0       	push   $0xf0106755
f0102eb9:	e8 82 d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102ebe:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f0102ec3:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102ec6:	83 ec 04             	sub    $0x4,%esp
f0102ec9:	68 00 10 00 00       	push   $0x1000
f0102ece:	ff 35 8c 9e 22 f0    	pushl  0xf0229e8c
f0102ed4:	50                   	push   %eax
f0102ed5:	e8 dd 1d 00 00       	call   f0104cb7 <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102eda:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102edd:	83 c4 10             	add    $0x10,%esp
f0102ee0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ee5:	77 15                	ja     f0102efc <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ee7:	50                   	push   %eax
f0102ee8:	68 08 59 10 f0       	push   $0xf0105908
f0102eed:	68 c7 00 00 00       	push   $0xc7
f0102ef2:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0102ef7:	e8 44 d1 ff ff       	call   f0100040 <_panic>
f0102efc:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f02:	83 ca 05             	or     $0x5,%edx
f0102f05:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102f0b:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f0e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f13:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f18:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f1d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f20:	89 da                	mov    %ebx,%edx
f0102f22:	2b 15 44 92 22 f0    	sub    0xf0229244,%edx
f0102f28:	c1 fa 02             	sar    $0x2,%edx
f0102f2b:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102f31:	09 d0                	or     %edx,%eax
f0102f33:	89 43 48             	mov    %eax,0x48(%ebx)
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102f36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f39:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102f3c:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102f43:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102f4a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102f51:	83 ec 04             	sub    $0x4,%esp
f0102f54:	6a 44                	push   $0x44
f0102f56:	6a 00                	push   $0x0
f0102f58:	53                   	push   %ebx
f0102f59:	e8 a4 1c 00 00       	call   f0104c02 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102f5e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102f64:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102f6a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102f70:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102f77:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102f7d:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102f84:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102f88:	8b 43 44             	mov    0x44(%ebx),%eax
f0102f8b:	a3 48 92 22 f0       	mov    %eax,0xf0229248
	*newenv_store = e;
f0102f90:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f93:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f95:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102f98:	e8 9a 22 00 00       	call   f0105237 <cpunum>
f0102f9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fa0:	83 c4 10             	add    $0x10,%esp
f0102fa3:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fa8:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0102faf:	74 11                	je     f0102fc2 <env_alloc+0x15e>
f0102fb1:	e8 81 22 00 00       	call   f0105237 <cpunum>
f0102fb6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fb9:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102fbf:	8b 50 48             	mov    0x48(%eax),%edx
f0102fc2:	83 ec 04             	sub    $0x4,%esp
f0102fc5:	53                   	push   %ebx
f0102fc6:	52                   	push   %edx
f0102fc7:	68 c4 6a 10 f0       	push   $0xf0106ac4
f0102fcc:	e8 ea 05 00 00       	call   f01035bb <cprintf>
	return 0;
f0102fd1:	83 c4 10             	add    $0x10,%esp
f0102fd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fd9:	eb 0c                	jmp    f0102fe7 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102fdb:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102fe0:	eb 05                	jmp    f0102fe7 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102fe2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102fe7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102fea:	c9                   	leave  
f0102feb:	c3                   	ret    

f0102fec <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102fec:	55                   	push   %ebp
f0102fed:	89 e5                	mov    %esp,%ebp
f0102fef:	57                   	push   %edi
f0102ff0:	56                   	push   %esi
f0102ff1:	53                   	push   %ebx
f0102ff2:	83 ec 34             	sub    $0x34,%esp
f0102ff5:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f0102ff8:	6a 00                	push   $0x0
f0102ffa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ffd:	50                   	push   %eax
f0102ffe:	e8 61 fe ff ff       	call   f0102e64 <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f0103003:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103006:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f0103009:	83 c4 10             	add    $0x10,%esp
f010300c:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103012:	74 17                	je     f010302b <env_create+0x3f>
		panic("binary document is error\n");
f0103014:	83 ec 04             	sub    $0x4,%esp
f0103017:	68 d9 6a 10 f0       	push   $0xf0106ad9
f010301c:	68 70 01 00 00       	push   $0x170
f0103021:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0103026:	e8 15 d0 ff ff       	call   f0100040 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
f010302b:	89 fb                	mov    %edi,%ebx
f010302d:	03 5f 1c             	add    0x1c(%edi),%ebx
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
f0103030:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103033:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103036:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010303b:	77 15                	ja     f0103052 <env_create+0x66>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010303d:	50                   	push   %eax
f010303e:	68 08 59 10 f0       	push   $0xf0105908
f0103043:	68 73 01 00 00       	push   $0x173
f0103048:	68 b9 6a 10 f0       	push   $0xf0106ab9
f010304d:	e8 ee cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103052:	05 00 00 00 10       	add    $0x10000000,%eax
f0103057:	0f 22 d8             	mov    %eax,%cr3
	for(i=0;i<elf->e_phnum;i++)
f010305a:	be 00 00 00 00       	mov    $0x0,%esi
f010305f:	eb 40                	jmp    f01030a1 <env_create+0xb5>
	{
		if(ph->p_type==ELF_PROG_LOAD)
f0103061:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103064:	75 35                	jne    f010309b <env_create+0xaf>
		{
			//cprintf("load\n");
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f0103066:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103069:	8b 53 08             	mov    0x8(%ebx),%edx
f010306c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010306f:	e8 54 fc ff ff       	call   f0102cc8 <region_alloc>
			memset((void *)(ph->p_va),0,ph->p_memsz);
f0103074:	83 ec 04             	sub    $0x4,%esp
f0103077:	ff 73 14             	pushl  0x14(%ebx)
f010307a:	6a 00                	push   $0x0
f010307c:	ff 73 08             	pushl  0x8(%ebx)
f010307f:	e8 7e 1b 00 00       	call   f0104c02 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f0103084:	83 c4 0c             	add    $0xc,%esp
f0103087:	ff 73 10             	pushl  0x10(%ebx)
f010308a:	89 f8                	mov    %edi,%eax
f010308c:	03 43 04             	add    0x4(%ebx),%eax
f010308f:	50                   	push   %eax
f0103090:	ff 73 08             	pushl  0x8(%ebx)
f0103093:	e8 1f 1c 00 00       	call   f0104cb7 <memcpy>
f0103098:	83 c4 10             	add    $0x10,%esp
			//cprintf("%08x\n",ph->p_va);
		}
		ph++;
f010309b:	83 c3 20             	add    $0x20,%ebx
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
	for(i=0;i<elf->e_phnum;i++)
f010309e:	83 c6 01             	add    $0x1,%esi
f01030a1:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f01030a5:	39 c6                	cmp    %eax,%esi
f01030a7:	72 b8                	jb     f0103061 <env_create+0x75>
		}
		ph++;
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	e->env_tf.tf_eip=elf->e_entry;
f01030a9:	8b 47 18             	mov    0x18(%edi),%eax
f01030ac:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01030af:	89 47 30             	mov    %eax,0x30(%edi)
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f01030b2:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01030b7:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01030bc:	89 f8                	mov    %edi,%eax
f01030be:	e8 05 fc ff ff       	call   f0102cc8 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01030c3:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030cd:	77 15                	ja     f01030e4 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030cf:	50                   	push   %eax
f01030d0:	68 08 59 10 f0       	push   $0xf0105908
f01030d5:	68 85 01 00 00       	push   $0x185
f01030da:	68 b9 6a 10 f0       	push   $0xf0106ab9
f01030df:	e8 5c cf ff ff       	call   f0100040 <_panic>
f01030e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01030e9:	0f 22 d8             	mov    %eax,%cr3
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f01030ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030ef:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030f2:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f01030f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030f8:	5b                   	pop    %ebx
f01030f9:	5e                   	pop    %esi
f01030fa:	5f                   	pop    %edi
f01030fb:	5d                   	pop    %ebp
f01030fc:	c3                   	ret    

f01030fd <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01030fd:	55                   	push   %ebp
f01030fe:	89 e5                	mov    %esp,%ebp
f0103100:	57                   	push   %edi
f0103101:	56                   	push   %esi
f0103102:	53                   	push   %ebx
f0103103:	83 ec 1c             	sub    $0x1c,%esp
f0103106:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103109:	e8 29 21 00 00       	call   f0105237 <cpunum>
f010310e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103111:	39 b8 28 a0 22 f0    	cmp    %edi,-0xfdd5fd8(%eax)
f0103117:	75 29                	jne    f0103142 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f0103119:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010311e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103123:	77 15                	ja     f010313a <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103125:	50                   	push   %eax
f0103126:	68 08 59 10 f0       	push   $0xf0105908
f010312b:	68 ac 01 00 00       	push   $0x1ac
f0103130:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0103135:	e8 06 cf ff ff       	call   f0100040 <_panic>
f010313a:	05 00 00 00 10       	add    $0x10000000,%eax
f010313f:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103142:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103145:	e8 ed 20 00 00       	call   f0105237 <cpunum>
f010314a:	6b c0 74             	imul   $0x74,%eax,%eax
f010314d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103152:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103159:	74 11                	je     f010316c <env_free+0x6f>
f010315b:	e8 d7 20 00 00       	call   f0105237 <cpunum>
f0103160:	6b c0 74             	imul   $0x74,%eax,%eax
f0103163:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103169:	8b 50 48             	mov    0x48(%eax),%edx
f010316c:	83 ec 04             	sub    $0x4,%esp
f010316f:	53                   	push   %ebx
f0103170:	52                   	push   %edx
f0103171:	68 f3 6a 10 f0       	push   $0xf0106af3
f0103176:	e8 40 04 00 00       	call   f01035bb <cprintf>
f010317b:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010317e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103185:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103188:	89 d0                	mov    %edx,%eax
f010318a:	c1 e0 02             	shl    $0x2,%eax
f010318d:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103190:	8b 47 60             	mov    0x60(%edi),%eax
f0103193:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103196:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010319c:	0f 84 a8 00 00 00    	je     f010324a <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01031a2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031a8:	89 f0                	mov    %esi,%eax
f01031aa:	c1 e8 0c             	shr    $0xc,%eax
f01031ad:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01031b0:	39 05 88 9e 22 f0    	cmp    %eax,0xf0229e88
f01031b6:	77 15                	ja     f01031cd <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031b8:	56                   	push   %esi
f01031b9:	68 e4 58 10 f0       	push   $0xf01058e4
f01031be:	68 bb 01 00 00       	push   $0x1bb
f01031c3:	68 b9 6a 10 f0       	push   $0xf0106ab9
f01031c8:	e8 73 ce ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031d0:	c1 e0 16             	shl    $0x16,%eax
f01031d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031d6:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01031db:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01031e2:	01 
f01031e3:	74 17                	je     f01031fc <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031e5:	83 ec 08             	sub    $0x8,%esp
f01031e8:	89 d8                	mov    %ebx,%eax
f01031ea:	c1 e0 0c             	shl    $0xc,%eax
f01031ed:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01031f0:	50                   	push   %eax
f01031f1:	ff 77 60             	pushl  0x60(%edi)
f01031f4:	e8 05 df ff ff       	call   f01010fe <page_remove>
f01031f9:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031fc:	83 c3 01             	add    $0x1,%ebx
f01031ff:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103205:	75 d4                	jne    f01031db <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103207:	8b 47 60             	mov    0x60(%edi),%eax
f010320a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010320d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103214:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103217:	3b 05 88 9e 22 f0    	cmp    0xf0229e88,%eax
f010321d:	72 14                	jb     f0103233 <env_free+0x136>
		panic("pa2page called with invalid pa");
f010321f:	83 ec 04             	sub    $0x4,%esp
f0103222:	68 ec 5e 10 f0       	push   $0xf0105eec
f0103227:	6a 51                	push   $0x51
f0103229:	68 55 67 10 f0       	push   $0xf0106755
f010322e:	e8 0d ce ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103233:	83 ec 0c             	sub    $0xc,%esp
f0103236:	a1 90 9e 22 f0       	mov    0xf0229e90,%eax
f010323b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010323e:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103241:	50                   	push   %eax
f0103242:	e8 10 dd ff ff       	call   f0100f57 <page_decref>
f0103247:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010324a:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010324e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103251:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103256:	0f 85 29 ff ff ff    	jne    f0103185 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010325c:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010325f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103264:	77 15                	ja     f010327b <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103266:	50                   	push   %eax
f0103267:	68 08 59 10 f0       	push   $0xf0105908
f010326c:	68 c9 01 00 00       	push   $0x1c9
f0103271:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0103276:	e8 c5 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010327b:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103282:	05 00 00 00 10       	add    $0x10000000,%eax
f0103287:	c1 e8 0c             	shr    $0xc,%eax
f010328a:	3b 05 88 9e 22 f0    	cmp    0xf0229e88,%eax
f0103290:	72 14                	jb     f01032a6 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103292:	83 ec 04             	sub    $0x4,%esp
f0103295:	68 ec 5e 10 f0       	push   $0xf0105eec
f010329a:	6a 51                	push   $0x51
f010329c:	68 55 67 10 f0       	push   $0xf0106755
f01032a1:	e8 9a cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f01032a6:	83 ec 0c             	sub    $0xc,%esp
f01032a9:	8b 15 90 9e 22 f0    	mov    0xf0229e90,%edx
f01032af:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01032b2:	50                   	push   %eax
f01032b3:	e8 9f dc ff ff       	call   f0100f57 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01032b8:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01032bf:	a1 48 92 22 f0       	mov    0xf0229248,%eax
f01032c4:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01032c7:	89 3d 48 92 22 f0    	mov    %edi,0xf0229248
}
f01032cd:	83 c4 10             	add    $0x10,%esp
f01032d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032d3:	5b                   	pop    %ebx
f01032d4:	5e                   	pop    %esi
f01032d5:	5f                   	pop    %edi
f01032d6:	5d                   	pop    %ebp
f01032d7:	c3                   	ret    

f01032d8 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01032d8:	55                   	push   %ebp
f01032d9:	89 e5                	mov    %esp,%ebp
f01032db:	53                   	push   %ebx
f01032dc:	83 ec 04             	sub    $0x4,%esp
f01032df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01032e2:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01032e6:	75 19                	jne    f0103301 <env_destroy+0x29>
f01032e8:	e8 4a 1f 00 00       	call   f0105237 <cpunum>
f01032ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01032f0:	3b 98 28 a0 22 f0    	cmp    -0xfdd5fd8(%eax),%ebx
f01032f6:	74 09                	je     f0103301 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01032f8:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01032ff:	eb 33                	jmp    f0103334 <env_destroy+0x5c>
	}

	env_free(e);
f0103301:	83 ec 0c             	sub    $0xc,%esp
f0103304:	53                   	push   %ebx
f0103305:	e8 f3 fd ff ff       	call   f01030fd <env_free>

	if (curenv == e) {
f010330a:	e8 28 1f 00 00       	call   f0105237 <cpunum>
f010330f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103312:	83 c4 10             	add    $0x10,%esp
f0103315:	3b 98 28 a0 22 f0    	cmp    -0xfdd5fd8(%eax),%ebx
f010331b:	75 17                	jne    f0103334 <env_destroy+0x5c>
		curenv = NULL;
f010331d:	e8 15 1f 00 00       	call   f0105237 <cpunum>
f0103322:	6b c0 74             	imul   $0x74,%eax,%eax
f0103325:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f010332c:	00 00 00 
		sched_yield();
f010332f:	e8 de 0b 00 00       	call   f0103f12 <sched_yield>
	}
}
f0103334:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103337:	c9                   	leave  
f0103338:	c3                   	ret    

f0103339 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103339:	55                   	push   %ebp
f010333a:	89 e5                	mov    %esp,%ebp
f010333c:	53                   	push   %ebx
f010333d:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103340:	e8 f2 1e 00 00       	call   f0105237 <cpunum>
f0103345:	6b c0 74             	imul   $0x74,%eax,%eax
f0103348:	8b 98 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%ebx
f010334e:	e8 e4 1e 00 00       	call   f0105237 <cpunum>
f0103353:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103356:	8b 65 08             	mov    0x8(%ebp),%esp
f0103359:	61                   	popa   
f010335a:	07                   	pop    %es
f010335b:	1f                   	pop    %ds
f010335c:	83 c4 08             	add    $0x8,%esp
f010335f:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103360:	83 ec 04             	sub    $0x4,%esp
f0103363:	68 09 6b 10 f0       	push   $0xf0106b09
f0103368:	68 00 02 00 00       	push   $0x200
f010336d:	68 b9 6a 10 f0       	push   $0xf0106ab9
f0103372:	e8 c9 cc ff ff       	call   f0100040 <_panic>

f0103377 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103377:	55                   	push   %ebp
f0103378:	89 e5                	mov    %esp,%ebp
f010337a:	53                   	push   %ebx
f010337b:	83 ec 04             	sub    $0x4,%esp
f010337e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0103381:	e8 b1 1e 00 00       	call   f0105237 <cpunum>
f0103386:	6b c0 74             	imul   $0x74,%eax,%eax
f0103389:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103390:	74 29                	je     f01033bb <env_run+0x44>
f0103392:	e8 a0 1e 00 00       	call   f0105237 <cpunum>
f0103397:	6b c0 74             	imul   $0x74,%eax,%eax
f010339a:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01033a0:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01033a4:	75 15                	jne    f01033bb <env_run+0x44>
	{
		curenv->env_status=ENV_RUNNABLE;
f01033a6:	e8 8c 1e 00 00       	call   f0105237 <cpunum>
f01033ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ae:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01033b4:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv=e;
f01033bb:	e8 77 1e 00 00       	call   f0105237 <cpunum>
f01033c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c3:	89 98 28 a0 22 f0    	mov    %ebx,-0xfdd5fd8(%eax)
	curenv->env_status=ENV_RUNNING;
f01033c9:	e8 69 1e 00 00       	call   f0105237 <cpunum>
f01033ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01033d1:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01033d7:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f01033de:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(curenv->env_pgdir));
f01033e2:	e8 50 1e 00 00       	call   f0105237 <cpunum>
f01033e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ea:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01033f0:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033f8:	77 15                	ja     f010340f <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033fa:	50                   	push   %eax
f01033fb:	68 08 59 10 f0       	push   $0xf0105908
f0103400:	68 25 02 00 00       	push   $0x225
f0103405:	68 b9 6a 10 f0       	push   $0xf0106ab9
f010340a:	e8 31 cc ff ff       	call   f0100040 <_panic>
f010340f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103414:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103417:	83 ec 0c             	sub    $0xc,%esp
f010341a:	68 c0 e3 11 f0       	push   $0xf011e3c0
f010341f:	e8 1e 21 00 00       	call   f0105542 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103424:	f3 90                	pause  
	unlock_kernel();
	//cprintf("adsd");
	env_pop_tf(&(curenv->env_tf));
f0103426:	e8 0c 1e 00 00       	call   f0105237 <cpunum>
f010342b:	83 c4 04             	add    $0x4,%esp
f010342e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103431:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103437:	e8 fd fe ff ff       	call   f0103339 <env_pop_tf>

f010343c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010343c:	55                   	push   %ebp
f010343d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010343f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103444:	8b 45 08             	mov    0x8(%ebp),%eax
f0103447:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103448:	ba 71 00 00 00       	mov    $0x71,%edx
f010344d:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010344e:	0f b6 c0             	movzbl %al,%eax
}
f0103451:	5d                   	pop    %ebp
f0103452:	c3                   	ret    

f0103453 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103453:	55                   	push   %ebp
f0103454:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103456:	ba 70 00 00 00       	mov    $0x70,%edx
f010345b:	8b 45 08             	mov    0x8(%ebp),%eax
f010345e:	ee                   	out    %al,(%dx)
f010345f:	ba 71 00 00 00       	mov    $0x71,%edx
f0103464:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103467:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103468:	5d                   	pop    %ebp
f0103469:	c3                   	ret    

f010346a <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010346a:	55                   	push   %ebp
f010346b:	89 e5                	mov    %esp,%ebp
f010346d:	56                   	push   %esi
f010346e:	53                   	push   %ebx
f010346f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103472:	66 a3 a8 e3 11 f0    	mov    %ax,0xf011e3a8
	if (!didinit)
f0103478:	80 3d 4c 92 22 f0 00 	cmpb   $0x0,0xf022924c
f010347f:	74 5a                	je     f01034db <irq_setmask_8259A+0x71>
f0103481:	89 c6                	mov    %eax,%esi
f0103483:	ba 21 00 00 00       	mov    $0x21,%edx
f0103488:	ee                   	out    %al,(%dx)
f0103489:	66 c1 e8 08          	shr    $0x8,%ax
f010348d:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103492:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103493:	83 ec 0c             	sub    $0xc,%esp
f0103496:	68 15 6b 10 f0       	push   $0xf0106b15
f010349b:	e8 1b 01 00 00       	call   f01035bb <cprintf>
f01034a0:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01034a3:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01034a8:	0f b7 f6             	movzwl %si,%esi
f01034ab:	f7 d6                	not    %esi
f01034ad:	0f a3 de             	bt     %ebx,%esi
f01034b0:	73 11                	jae    f01034c3 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f01034b2:	83 ec 08             	sub    $0x8,%esp
f01034b5:	53                   	push   %ebx
f01034b6:	68 a3 6d 10 f0       	push   $0xf0106da3
f01034bb:	e8 fb 00 00 00       	call   f01035bb <cprintf>
f01034c0:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01034c3:	83 c3 01             	add    $0x1,%ebx
f01034c6:	83 fb 10             	cmp    $0x10,%ebx
f01034c9:	75 e2                	jne    f01034ad <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01034cb:	83 ec 0c             	sub    $0xc,%esp
f01034ce:	68 29 6a 10 f0       	push   $0xf0106a29
f01034d3:	e8 e3 00 00 00       	call   f01035bb <cprintf>
f01034d8:	83 c4 10             	add    $0x10,%esp
}
f01034db:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034de:	5b                   	pop    %ebx
f01034df:	5e                   	pop    %esi
f01034e0:	5d                   	pop    %ebp
f01034e1:	c3                   	ret    

f01034e2 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01034e2:	c6 05 4c 92 22 f0 01 	movb   $0x1,0xf022924c
f01034e9:	ba 21 00 00 00       	mov    $0x21,%edx
f01034ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034f3:	ee                   	out    %al,(%dx)
f01034f4:	ba a1 00 00 00       	mov    $0xa1,%edx
f01034f9:	ee                   	out    %al,(%dx)
f01034fa:	ba 20 00 00 00       	mov    $0x20,%edx
f01034ff:	b8 11 00 00 00       	mov    $0x11,%eax
f0103504:	ee                   	out    %al,(%dx)
f0103505:	ba 21 00 00 00       	mov    $0x21,%edx
f010350a:	b8 20 00 00 00       	mov    $0x20,%eax
f010350f:	ee                   	out    %al,(%dx)
f0103510:	b8 04 00 00 00       	mov    $0x4,%eax
f0103515:	ee                   	out    %al,(%dx)
f0103516:	b8 03 00 00 00       	mov    $0x3,%eax
f010351b:	ee                   	out    %al,(%dx)
f010351c:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103521:	b8 11 00 00 00       	mov    $0x11,%eax
f0103526:	ee                   	out    %al,(%dx)
f0103527:	ba a1 00 00 00       	mov    $0xa1,%edx
f010352c:	b8 28 00 00 00       	mov    $0x28,%eax
f0103531:	ee                   	out    %al,(%dx)
f0103532:	b8 02 00 00 00       	mov    $0x2,%eax
f0103537:	ee                   	out    %al,(%dx)
f0103538:	b8 01 00 00 00       	mov    $0x1,%eax
f010353d:	ee                   	out    %al,(%dx)
f010353e:	ba 20 00 00 00       	mov    $0x20,%edx
f0103543:	b8 68 00 00 00       	mov    $0x68,%eax
f0103548:	ee                   	out    %al,(%dx)
f0103549:	b8 0a 00 00 00       	mov    $0xa,%eax
f010354e:	ee                   	out    %al,(%dx)
f010354f:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103554:	b8 68 00 00 00       	mov    $0x68,%eax
f0103559:	ee                   	out    %al,(%dx)
f010355a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010355f:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103560:	0f b7 05 a8 e3 11 f0 	movzwl 0xf011e3a8,%eax
f0103567:	66 83 f8 ff          	cmp    $0xffff,%ax
f010356b:	74 13                	je     f0103580 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010356d:	55                   	push   %ebp
f010356e:	89 e5                	mov    %esp,%ebp
f0103570:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103573:	0f b7 c0             	movzwl %ax,%eax
f0103576:	50                   	push   %eax
f0103577:	e8 ee fe ff ff       	call   f010346a <irq_setmask_8259A>
f010357c:	83 c4 10             	add    $0x10,%esp
}
f010357f:	c9                   	leave  
f0103580:	f3 c3                	repz ret 

f0103582 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103582:	55                   	push   %ebp
f0103583:	89 e5                	mov    %esp,%ebp
f0103585:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103588:	ff 75 08             	pushl  0x8(%ebp)
f010358b:	e8 f2 d1 ff ff       	call   f0100782 <cputchar>
	*cnt++;
}
f0103590:	83 c4 10             	add    $0x10,%esp
f0103593:	c9                   	leave  
f0103594:	c3                   	ret    

f0103595 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103595:	55                   	push   %ebp
f0103596:	89 e5                	mov    %esp,%ebp
f0103598:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010359b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01035a2:	ff 75 0c             	pushl  0xc(%ebp)
f01035a5:	ff 75 08             	pushl  0x8(%ebp)
f01035a8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01035ab:	50                   	push   %eax
f01035ac:	68 82 35 10 f0       	push   $0xf0103582
f01035b1:	e8 27 0f 00 00       	call   f01044dd <vprintfmt>
	return cnt;
}
f01035b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035b9:	c9                   	leave  
f01035ba:	c3                   	ret    

f01035bb <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01035bb:	55                   	push   %ebp
f01035bc:	89 e5                	mov    %esp,%ebp
f01035be:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01035c1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01035c4:	50                   	push   %eax
f01035c5:	ff 75 08             	pushl  0x8(%ebp)
f01035c8:	e8 c8 ff ff ff       	call   f0103595 <vcprintf>
	va_end(ap);

	return cnt;
}
f01035cd:	c9                   	leave  
f01035ce:	c3                   	ret    

f01035cf <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01035cf:	55                   	push   %ebp
f01035d0:	89 e5                	mov    %esp,%ebp
f01035d2:	57                   	push   %edi
f01035d3:	56                   	push   %esi
f01035d4:	53                   	push   %ebx
f01035d5:	83 ec 0c             	sub    $0xc,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0=KSTACKTOP-cpunum()*(KSTKSIZE+KSTKGAP);
f01035d8:	e8 5a 1c 00 00       	call   f0105237 <cpunum>
f01035dd:	89 c3                	mov    %eax,%ebx
f01035df:	e8 53 1c 00 00       	call   f0105237 <cpunum>
f01035e4:	6b db 74             	imul   $0x74,%ebx,%ebx
f01035e7:	c1 e0 10             	shl    $0x10,%eax
f01035ea:	89 c2                	mov    %eax,%edx
f01035ec:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01035f1:	29 d0                	sub    %edx,%eax
f01035f3:	89 83 30 a0 22 f0    	mov    %eax,-0xfdd5fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0=GD_KD;
f01035f9:	e8 39 1c 00 00       	call   f0105237 <cpunum>
f01035fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103601:	66 c7 80 34 a0 22 f0 	movw   $0x10,-0xfdd5fcc(%eax)
f0103608:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f010360a:	e8 28 1c 00 00       	call   f0105237 <cpunum>
f010360f:	8d 58 05             	lea    0x5(%eax),%ebx
f0103612:	e8 20 1c 00 00       	call   f0105237 <cpunum>
f0103617:	89 c7                	mov    %eax,%edi
f0103619:	e8 19 1c 00 00       	call   f0105237 <cpunum>
f010361e:	89 c6                	mov    %eax,%esi
f0103620:	e8 12 1c 00 00       	call   f0105237 <cpunum>
f0103625:	66 c7 04 dd 40 e3 11 	movw   $0x67,-0xfee1cc0(,%ebx,8)
f010362c:	f0 67 00 
f010362f:	6b ff 74             	imul   $0x74,%edi,%edi
f0103632:	81 c7 2c a0 22 f0    	add    $0xf022a02c,%edi
f0103638:	66 89 3c dd 42 e3 11 	mov    %di,-0xfee1cbe(,%ebx,8)
f010363f:	f0 
f0103640:	6b d6 74             	imul   $0x74,%esi,%edx
f0103643:	81 c2 2c a0 22 f0    	add    $0xf022a02c,%edx
f0103649:	c1 ea 10             	shr    $0x10,%edx
f010364c:	88 14 dd 44 e3 11 f0 	mov    %dl,-0xfee1cbc(,%ebx,8)
f0103653:	c6 04 dd 45 e3 11 f0 	movb   $0x99,-0xfee1cbb(,%ebx,8)
f010365a:	99 
f010365b:	c6 04 dd 46 e3 11 f0 	movb   $0x40,-0xfee1cba(,%ebx,8)
f0103662:	40 
f0103663:	6b c0 74             	imul   $0x74,%eax,%eax
f0103666:	05 2c a0 22 f0       	add    $0xf022a02c,%eax
f010366b:	c1 e8 18             	shr    $0x18,%eax
f010366e:	88 04 dd 47 e3 11 f0 	mov    %al,-0xfee1cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;
f0103675:	e8 bd 1b 00 00       	call   f0105237 <cpunum>
f010367a:	80 24 c5 6d e3 11 f0 	andb   $0xef,-0xfee1c93(,%eax,8)
f0103681:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+sizeof(struct Segdesc)*cpunum());
f0103682:	e8 b0 1b 00 00       	call   f0105237 <cpunum>
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103687:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f010368e:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103691:	b8 ac e3 11 f0       	mov    $0xf011e3ac,%eax
f0103696:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103699:	83 c4 0c             	add    $0xc,%esp
f010369c:	5b                   	pop    %ebx
f010369d:	5e                   	pop    %esi
f010369e:	5f                   	pop    %edi
f010369f:	5d                   	pop    %ebp
f01036a0:	c3                   	ret    

f01036a1 <trap_init>:
}


void
trap_init(void)
{
f01036a1:	55                   	push   %ebp
f01036a2:	89 e5                	mov    %esp,%ebp
f01036a4:	83 ec 08             	sub    $0x8,%esp
	extern void floating_point_error();
	extern void alignment_check();
	extern void machine_check(); 
	extern void simd_floating_error();
	extern void system_call(); 
	SETGATE(idt[0],0,GD_KT,divide_error,0);
f01036a7:	b8 c8 3d 10 f0       	mov    $0xf0103dc8,%eax
f01036ac:	66 a3 60 92 22 f0    	mov    %ax,0xf0229260
f01036b2:	66 c7 05 62 92 22 f0 	movw   $0x8,0xf0229262
f01036b9:	08 00 
f01036bb:	c6 05 64 92 22 f0 00 	movb   $0x0,0xf0229264
f01036c2:	c6 05 65 92 22 f0 8e 	movb   $0x8e,0xf0229265
f01036c9:	c1 e8 10             	shr    $0x10,%eax
f01036cc:	66 a3 66 92 22 f0    	mov    %ax,0xf0229266
	SETGATE(idt[1],0,GD_KT,debuf_exception,0);
f01036d2:	b8 ce 3d 10 f0       	mov    $0xf0103dce,%eax
f01036d7:	66 a3 68 92 22 f0    	mov    %ax,0xf0229268
f01036dd:	66 c7 05 6a 92 22 f0 	movw   $0x8,0xf022926a
f01036e4:	08 00 
f01036e6:	c6 05 6c 92 22 f0 00 	movb   $0x0,0xf022926c
f01036ed:	c6 05 6d 92 22 f0 8e 	movb   $0x8e,0xf022926d
f01036f4:	c1 e8 10             	shr    $0x10,%eax
f01036f7:	66 a3 6e 92 22 f0    	mov    %ax,0xf022926e
	SETGATE(idt[2],0,GD_KT,nmi_interrupt,0);
f01036fd:	b8 d4 3d 10 f0       	mov    $0xf0103dd4,%eax
f0103702:	66 a3 70 92 22 f0    	mov    %ax,0xf0229270
f0103708:	66 c7 05 72 92 22 f0 	movw   $0x8,0xf0229272
f010370f:	08 00 
f0103711:	c6 05 74 92 22 f0 00 	movb   $0x0,0xf0229274
f0103718:	c6 05 75 92 22 f0 8e 	movb   $0x8e,0xf0229275
f010371f:	c1 e8 10             	shr    $0x10,%eax
f0103722:	66 a3 76 92 22 f0    	mov    %ax,0xf0229276
	SETGATE(idt[3],0,GD_KT,break_point,3);
f0103728:	b8 da 3d 10 f0       	mov    $0xf0103dda,%eax
f010372d:	66 a3 78 92 22 f0    	mov    %ax,0xf0229278
f0103733:	66 c7 05 7a 92 22 f0 	movw   $0x8,0xf022927a
f010373a:	08 00 
f010373c:	c6 05 7c 92 22 f0 00 	movb   $0x0,0xf022927c
f0103743:	c6 05 7d 92 22 f0 ee 	movb   $0xee,0xf022927d
f010374a:	c1 e8 10             	shr    $0x10,%eax
f010374d:	66 a3 7e 92 22 f0    	mov    %ax,0xf022927e
	SETGATE(idt[4],0,GD_KT,overflow,0);
f0103753:	b8 e0 3d 10 f0       	mov    $0xf0103de0,%eax
f0103758:	66 a3 80 92 22 f0    	mov    %ax,0xf0229280
f010375e:	66 c7 05 82 92 22 f0 	movw   $0x8,0xf0229282
f0103765:	08 00 
f0103767:	c6 05 84 92 22 f0 00 	movb   $0x0,0xf0229284
f010376e:	c6 05 85 92 22 f0 8e 	movb   $0x8e,0xf0229285
f0103775:	c1 e8 10             	shr    $0x10,%eax
f0103778:	66 a3 86 92 22 f0    	mov    %ax,0xf0229286
	SETGATE(idt[5],0,GD_KT,bound_check,0);
f010377e:	b8 e6 3d 10 f0       	mov    $0xf0103de6,%eax
f0103783:	66 a3 88 92 22 f0    	mov    %ax,0xf0229288
f0103789:	66 c7 05 8a 92 22 f0 	movw   $0x8,0xf022928a
f0103790:	08 00 
f0103792:	c6 05 8c 92 22 f0 00 	movb   $0x0,0xf022928c
f0103799:	c6 05 8d 92 22 f0 8e 	movb   $0x8e,0xf022928d
f01037a0:	c1 e8 10             	shr    $0x10,%eax
f01037a3:	66 a3 8e 92 22 f0    	mov    %ax,0xf022928e
	SETGATE(idt[6],0,GD_KT,illegal_opcode,0);
f01037a9:	b8 ec 3d 10 f0       	mov    $0xf0103dec,%eax
f01037ae:	66 a3 90 92 22 f0    	mov    %ax,0xf0229290
f01037b4:	66 c7 05 92 92 22 f0 	movw   $0x8,0xf0229292
f01037bb:	08 00 
f01037bd:	c6 05 94 92 22 f0 00 	movb   $0x0,0xf0229294
f01037c4:	c6 05 95 92 22 f0 8e 	movb   $0x8e,0xf0229295
f01037cb:	c1 e8 10             	shr    $0x10,%eax
f01037ce:	66 a3 96 92 22 f0    	mov    %ax,0xf0229296
	SETGATE(idt[7],0,GD_KT,device_not_available,0);
f01037d4:	b8 f2 3d 10 f0       	mov    $0xf0103df2,%eax
f01037d9:	66 a3 98 92 22 f0    	mov    %ax,0xf0229298
f01037df:	66 c7 05 9a 92 22 f0 	movw   $0x8,0xf022929a
f01037e6:	08 00 
f01037e8:	c6 05 9c 92 22 f0 00 	movb   $0x0,0xf022929c
f01037ef:	c6 05 9d 92 22 f0 8e 	movb   $0x8e,0xf022929d
f01037f6:	c1 e8 10             	shr    $0x10,%eax
f01037f9:	66 a3 9e 92 22 f0    	mov    %ax,0xf022929e
	SETGATE(idt[8],0,GD_KT,segment_not_present,0);
f01037ff:	ba 00 3e 10 f0       	mov    $0xf0103e00,%edx
f0103804:	66 89 15 a0 92 22 f0 	mov    %dx,0xf02292a0
f010380b:	66 c7 05 a2 92 22 f0 	movw   $0x8,0xf02292a2
f0103812:	08 00 
f0103814:	c6 05 a4 92 22 f0 00 	movb   $0x0,0xf02292a4
f010381b:	c6 05 a5 92 22 f0 8e 	movb   $0x8e,0xf02292a5
f0103822:	89 d1                	mov    %edx,%ecx
f0103824:	c1 e9 10             	shr    $0x10,%ecx
f0103827:	66 89 0d a6 92 22 f0 	mov    %cx,0xf02292a6
	SETGATE(idt[10],0,GD_KT,invalid_tss,0);
f010382e:	b8 fc 3d 10 f0       	mov    $0xf0103dfc,%eax
f0103833:	66 a3 b0 92 22 f0    	mov    %ax,0xf02292b0
f0103839:	66 c7 05 b2 92 22 f0 	movw   $0x8,0xf02292b2
f0103840:	08 00 
f0103842:	c6 05 b4 92 22 f0 00 	movb   $0x0,0xf02292b4
f0103849:	c6 05 b5 92 22 f0 8e 	movb   $0x8e,0xf02292b5
f0103850:	c1 e8 10             	shr    $0x10,%eax
f0103853:	66 a3 b6 92 22 f0    	mov    %ax,0xf02292b6
	SETGATE(idt[11],0,GD_KT,segment_not_present,0);
f0103859:	66 89 15 b8 92 22 f0 	mov    %dx,0xf02292b8
f0103860:	66 c7 05 ba 92 22 f0 	movw   $0x8,0xf02292ba
f0103867:	08 00 
f0103869:	c6 05 bc 92 22 f0 00 	movb   $0x0,0xf02292bc
f0103870:	c6 05 bd 92 22 f0 8e 	movb   $0x8e,0xf02292bd
f0103877:	66 89 0d be 92 22 f0 	mov    %cx,0xf02292be
	SETGATE(idt[12],0,GD_KT,stack_exception,0);
f010387e:	b8 04 3e 10 f0       	mov    $0xf0103e04,%eax
f0103883:	66 a3 c0 92 22 f0    	mov    %ax,0xf02292c0
f0103889:	66 c7 05 c2 92 22 f0 	movw   $0x8,0xf02292c2
f0103890:	08 00 
f0103892:	c6 05 c4 92 22 f0 00 	movb   $0x0,0xf02292c4
f0103899:	c6 05 c5 92 22 f0 8e 	movb   $0x8e,0xf02292c5
f01038a0:	c1 e8 10             	shr    $0x10,%eax
f01038a3:	66 a3 c6 92 22 f0    	mov    %ax,0xf02292c6
	SETGATE(idt[13],0,GD_KT, general_protection_fault,0);
f01038a9:	b8 08 3e 10 f0       	mov    $0xf0103e08,%eax
f01038ae:	66 a3 c8 92 22 f0    	mov    %ax,0xf02292c8
f01038b4:	66 c7 05 ca 92 22 f0 	movw   $0x8,0xf02292ca
f01038bb:	08 00 
f01038bd:	c6 05 cc 92 22 f0 00 	movb   $0x0,0xf02292cc
f01038c4:	c6 05 cd 92 22 f0 8e 	movb   $0x8e,0xf02292cd
f01038cb:	c1 e8 10             	shr    $0x10,%eax
f01038ce:	66 a3 ce 92 22 f0    	mov    %ax,0xf02292ce
	SETGATE(idt[14],0,GD_KT,page_fault,0);
f01038d4:	b8 0c 3e 10 f0       	mov    $0xf0103e0c,%eax
f01038d9:	66 a3 d0 92 22 f0    	mov    %ax,0xf02292d0
f01038df:	66 c7 05 d2 92 22 f0 	movw   $0x8,0xf02292d2
f01038e6:	08 00 
f01038e8:	c6 05 d4 92 22 f0 00 	movb   $0x0,0xf02292d4
f01038ef:	c6 05 d5 92 22 f0 8e 	movb   $0x8e,0xf02292d5
f01038f6:	c1 e8 10             	shr    $0x10,%eax
f01038f9:	66 a3 d6 92 22 f0    	mov    %ax,0xf02292d6
	SETGATE(idt[16],0,GD_KT,floating_point_error,0);
f01038ff:	b8 10 3e 10 f0       	mov    $0xf0103e10,%eax
f0103904:	66 a3 e0 92 22 f0    	mov    %ax,0xf02292e0
f010390a:	66 c7 05 e2 92 22 f0 	movw   $0x8,0xf02292e2
f0103911:	08 00 
f0103913:	c6 05 e4 92 22 f0 00 	movb   $0x0,0xf02292e4
f010391a:	c6 05 e5 92 22 f0 8e 	movb   $0x8e,0xf02292e5
f0103921:	c1 e8 10             	shr    $0x10,%eax
f0103924:	66 a3 e6 92 22 f0    	mov    %ax,0xf02292e6
	SETGATE(idt[17],0,GD_KT,alignment_check,0);
f010392a:	b8 16 3e 10 f0       	mov    $0xf0103e16,%eax
f010392f:	66 a3 e8 92 22 f0    	mov    %ax,0xf02292e8
f0103935:	66 c7 05 ea 92 22 f0 	movw   $0x8,0xf02292ea
f010393c:	08 00 
f010393e:	c6 05 ec 92 22 f0 00 	movb   $0x0,0xf02292ec
f0103945:	c6 05 ed 92 22 f0 8e 	movb   $0x8e,0xf02292ed
f010394c:	c1 e8 10             	shr    $0x10,%eax
f010394f:	66 a3 ee 92 22 f0    	mov    %ax,0xf02292ee
	SETGATE(idt[18],0,GD_KT,machine_check,0);
f0103955:	b8 1a 3e 10 f0       	mov    $0xf0103e1a,%eax
f010395a:	66 a3 f0 92 22 f0    	mov    %ax,0xf02292f0
f0103960:	66 c7 05 f2 92 22 f0 	movw   $0x8,0xf02292f2
f0103967:	08 00 
f0103969:	c6 05 f4 92 22 f0 00 	movb   $0x0,0xf02292f4
f0103970:	c6 05 f5 92 22 f0 8e 	movb   $0x8e,0xf02292f5
f0103977:	c1 e8 10             	shr    $0x10,%eax
f010397a:	66 a3 f6 92 22 f0    	mov    %ax,0xf02292f6
	SETGATE(idt[19],0,GD_KT,simd_floating_error,0);
f0103980:	b8 20 3e 10 f0       	mov    $0xf0103e20,%eax
f0103985:	66 a3 f8 92 22 f0    	mov    %ax,0xf02292f8
f010398b:	66 c7 05 fa 92 22 f0 	movw   $0x8,0xf02292fa
f0103992:	08 00 
f0103994:	c6 05 fc 92 22 f0 00 	movb   $0x0,0xf02292fc
f010399b:	c6 05 fd 92 22 f0 8e 	movb   $0x8e,0xf02292fd
f01039a2:	c1 e8 10             	shr    $0x10,%eax
f01039a5:	66 a3 fe 92 22 f0    	mov    %ax,0xf02292fe
	SETGATE(idt[48],0,GD_KT,system_call,3);
f01039ab:	b8 26 3e 10 f0       	mov    $0xf0103e26,%eax
f01039b0:	66 a3 e0 93 22 f0    	mov    %ax,0xf02293e0
f01039b6:	66 c7 05 e2 93 22 f0 	movw   $0x8,0xf02293e2
f01039bd:	08 00 
f01039bf:	c6 05 e4 93 22 f0 00 	movb   $0x0,0xf02293e4
f01039c6:	c6 05 e5 93 22 f0 ee 	movb   $0xee,0xf02293e5
f01039cd:	c1 e8 10             	shr    $0x10,%eax
f01039d0:	66 a3 e6 93 22 f0    	mov    %ax,0xf02293e6
	// Per-CPU setup 
	trap_init_percpu();
f01039d6:	e8 f4 fb ff ff       	call   f01035cf <trap_init_percpu>
}
f01039db:	c9                   	leave  
f01039dc:	c3                   	ret    

f01039dd <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01039dd:	55                   	push   %ebp
f01039de:	89 e5                	mov    %esp,%ebp
f01039e0:	56                   	push   %esi
f01039e1:	53                   	push   %ebx
f01039e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01039e5:	e8 4d 18 00 00       	call   f0105237 <cpunum>
f01039ea:	83 ec 04             	sub    $0x4,%esp
f01039ed:	50                   	push   %eax
f01039ee:	53                   	push   %ebx
f01039ef:	68 50 6b 10 f0       	push   $0xf0106b50
f01039f4:	e8 c2 fb ff ff       	call   f01035bb <cprintf>
	//cprintf("  es   0x----%04x\n", tf->tf_es);
	//cprintf("  ds   0x----%04x\n", tf->tf_ds);
	//cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01039f9:	83 c4 10             	add    $0x10,%esp
f01039fc:	3b 1d 60 9a 22 f0    	cmp    0xf0229a60,%ebx
f0103a02:	75 1a                	jne    f0103a1e <print_trapframe+0x41>
f0103a04:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a08:	75 63                	jne    f0103a6d <print_trapframe+0x90>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103a0a:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103a0d:	83 ec 08             	sub    $0x8,%esp
f0103a10:	50                   	push   %eax
f0103a11:	68 6e 6b 10 f0       	push   $0xf0106b6e
f0103a16:	e8 a0 fb ff ff       	call   f01035bb <cprintf>
f0103a1b:	83 c4 10             	add    $0x10,%esp
	//cprintf("  err  0x%08x", tf->tf_err);
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103a1e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a22:	75 49                	jne    f0103a6d <print_trapframe+0x90>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103a24:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103a27:	89 c2                	mov    %eax,%edx
f0103a29:	83 e2 01             	and    $0x1,%edx
f0103a2c:	ba 34 6b 10 f0       	mov    $0xf0106b34,%edx
f0103a31:	b9 29 6b 10 f0       	mov    $0xf0106b29,%ecx
f0103a36:	0f 44 ca             	cmove  %edx,%ecx
f0103a39:	89 c2                	mov    %eax,%edx
f0103a3b:	83 e2 02             	and    $0x2,%edx
f0103a3e:	ba 46 6b 10 f0       	mov    $0xf0106b46,%edx
f0103a43:	be 40 6b 10 f0       	mov    $0xf0106b40,%esi
f0103a48:	0f 45 d6             	cmovne %esi,%edx
f0103a4b:	83 e0 04             	and    $0x4,%eax
f0103a4e:	be b2 6c 10 f0       	mov    $0xf0106cb2,%esi
f0103a53:	b8 4b 6b 10 f0       	mov    $0xf0106b4b,%eax
f0103a58:	0f 44 c6             	cmove  %esi,%eax
f0103a5b:	51                   	push   %ecx
f0103a5c:	52                   	push   %edx
f0103a5d:	50                   	push   %eax
f0103a5e:	68 7d 6b 10 f0       	push   $0xf0106b7d
f0103a63:	e8 53 fb ff ff       	call   f01035bb <cprintf>
f0103a68:	83 c4 10             	add    $0x10,%esp
f0103a6b:	eb 10                	jmp    f0103a7d <print_trapframe+0xa0>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103a6d:	83 ec 0c             	sub    $0xc,%esp
f0103a70:	68 29 6a 10 f0       	push   $0xf0106a29
f0103a75:	e8 41 fb ff ff       	call   f01035bb <cprintf>
f0103a7a:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103a7d:	83 ec 08             	sub    $0x8,%esp
f0103a80:	ff 73 30             	pushl  0x30(%ebx)
f0103a83:	68 8c 6b 10 f0       	push   $0xf0106b8c
f0103a88:	e8 2e fb ff ff       	call   f01035bb <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103a8d:	83 c4 08             	add    $0x8,%esp
f0103a90:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103a94:	50                   	push   %eax
f0103a95:	68 9b 6b 10 f0       	push   $0xf0106b9b
f0103a9a:	e8 1c fb ff ff       	call   f01035bb <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103a9f:	83 c4 08             	add    $0x8,%esp
f0103aa2:	ff 73 38             	pushl  0x38(%ebx)
f0103aa5:	68 ae 6b 10 f0       	push   $0xf0106bae
f0103aaa:	e8 0c fb ff ff       	call   f01035bb <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103aaf:	83 c4 10             	add    $0x10,%esp
f0103ab2:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ab6:	74 25                	je     f0103add <print_trapframe+0x100>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ab8:	83 ec 08             	sub    $0x8,%esp
f0103abb:	ff 73 3c             	pushl  0x3c(%ebx)
f0103abe:	68 bd 6b 10 f0       	push   $0xf0106bbd
f0103ac3:	e8 f3 fa ff ff       	call   f01035bb <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ac8:	83 c4 08             	add    $0x8,%esp
f0103acb:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103acf:	50                   	push   %eax
f0103ad0:	68 cc 6b 10 f0       	push   $0xf0106bcc
f0103ad5:	e8 e1 fa ff ff       	call   f01035bb <cprintf>
f0103ada:	83 c4 10             	add    $0x10,%esp
	}
}
f0103add:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103ae0:	5b                   	pop    %ebx
f0103ae1:	5e                   	pop    %esi
f0103ae2:	5d                   	pop    %ebp
f0103ae3:	c3                   	ret    

f0103ae4 <print_regs>:

void
print_regs(struct PushRegs *regs)
{
f0103ae4:	55                   	push   %ebp
f0103ae5:	89 e5                	mov    %esp,%ebp
f0103ae7:	53                   	push   %ebx
f0103ae8:	83 ec 0c             	sub    $0xc,%esp
f0103aeb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103aee:	ff 33                	pushl  (%ebx)
f0103af0:	68 df 6b 10 f0       	push   $0xf0106bdf
f0103af5:	e8 c1 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103afa:	83 c4 08             	add    $0x8,%esp
f0103afd:	ff 73 04             	pushl  0x4(%ebx)
f0103b00:	68 ee 6b 10 f0       	push   $0xf0106bee
f0103b05:	e8 b1 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b0a:	83 c4 08             	add    $0x8,%esp
f0103b0d:	ff 73 08             	pushl  0x8(%ebx)
f0103b10:	68 fd 6b 10 f0       	push   $0xf0106bfd
f0103b15:	e8 a1 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b1a:	83 c4 08             	add    $0x8,%esp
f0103b1d:	ff 73 0c             	pushl  0xc(%ebx)
f0103b20:	68 0c 6c 10 f0       	push   $0xf0106c0c
f0103b25:	e8 91 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b2a:	83 c4 08             	add    $0x8,%esp
f0103b2d:	ff 73 10             	pushl  0x10(%ebx)
f0103b30:	68 1b 6c 10 f0       	push   $0xf0106c1b
f0103b35:	e8 81 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b3a:	83 c4 08             	add    $0x8,%esp
f0103b3d:	ff 73 14             	pushl  0x14(%ebx)
f0103b40:	68 2a 6c 10 f0       	push   $0xf0106c2a
f0103b45:	e8 71 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b4a:	83 c4 08             	add    $0x8,%esp
f0103b4d:	ff 73 18             	pushl  0x18(%ebx)
f0103b50:	68 39 6c 10 f0       	push   $0xf0106c39
f0103b55:	e8 61 fa ff ff       	call   f01035bb <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b5a:	83 c4 08             	add    $0x8,%esp
f0103b5d:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b60:	68 48 6c 10 f0       	push   $0xf0106c48
f0103b65:	e8 51 fa ff ff       	call   f01035bb <cprintf>
}
f0103b6a:	83 c4 10             	add    $0x10,%esp
f0103b6d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b70:	c9                   	leave  
f0103b71:	c3                   	ret    

f0103b72 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103b72:	55                   	push   %ebp
f0103b73:	89 e5                	mov    %esp,%ebp
f0103b75:	57                   	push   %edi
f0103b76:	56                   	push   %esi
f0103b77:	53                   	push   %ebx
f0103b78:	83 ec 0c             	sub    $0xc,%esp
f0103b7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103b7e:	0f 20 d6             	mov    %cr2,%esi
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b81:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103b84:	e8 ae 16 00 00       	call   f0105237 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b89:	57                   	push   %edi
f0103b8a:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103b8b:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b8e:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103b94:	ff 70 48             	pushl  0x48(%eax)
f0103b97:	68 bc 6c 10 f0       	push   $0xf0106cbc
f0103b9c:	e8 1a fa ff ff       	call   f01035bb <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ba1:	89 1c 24             	mov    %ebx,(%esp)
f0103ba4:	e8 34 fe ff ff       	call   f01039dd <print_trapframe>
	env_destroy(curenv);
f0103ba9:	e8 89 16 00 00       	call   f0105237 <cpunum>
f0103bae:	83 c4 04             	add    $0x4,%esp
f0103bb1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bb4:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103bba:	e8 19 f7 ff ff       	call   f01032d8 <env_destroy>
}
f0103bbf:	83 c4 10             	add    $0x10,%esp
f0103bc2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bc5:	5b                   	pop    %ebx
f0103bc6:	5e                   	pop    %esi
f0103bc7:	5f                   	pop    %edi
f0103bc8:	5d                   	pop    %ebp
f0103bc9:	c3                   	ret    

f0103bca <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103bca:	55                   	push   %ebp
f0103bcb:	89 e5                	mov    %esp,%ebp
f0103bcd:	57                   	push   %edi
f0103bce:	56                   	push   %esi
f0103bcf:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103bd2:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103bd3:	83 3d 80 9e 22 f0 00 	cmpl   $0x0,0xf0229e80
f0103bda:	74 01                	je     f0103bdd <trap+0x13>
		asm volatile("hlt");
f0103bdc:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103bdd:	e8 55 16 00 00       	call   f0105237 <cpunum>
f0103be2:	6b d0 74             	imul   $0x74,%eax,%edx
f0103be5:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103beb:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bf0:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103bf4:	83 f8 02             	cmp    $0x2,%eax
f0103bf7:	75 10                	jne    f0103c09 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103bf9:	83 ec 0c             	sub    $0xc,%esp
f0103bfc:	68 c0 e3 11 f0       	push   $0xf011e3c0
f0103c01:	e8 9f 18 00 00       	call   f01054a5 <spin_lock>
f0103c06:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103c09:	9c                   	pushf  
f0103c0a:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103c0b:	f6 c4 02             	test   $0x2,%ah
f0103c0e:	74 19                	je     f0103c29 <trap+0x5f>
f0103c10:	68 57 6c 10 f0       	push   $0xf0106c57
f0103c15:	68 6f 67 10 f0       	push   $0xf010676f
f0103c1a:	68 11 01 00 00       	push   $0x111
f0103c1f:	68 70 6c 10 f0       	push   $0xf0106c70
f0103c24:	e8 17 c4 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103c29:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103c2d:	83 e0 03             	and    $0x3,%eax
f0103c30:	66 83 f8 03          	cmp    $0x3,%ax
f0103c34:	0f 85 a0 00 00 00    	jne    f0103cda <trap+0x110>
f0103c3a:	83 ec 0c             	sub    $0xc,%esp
f0103c3d:	68 c0 e3 11 f0       	push   $0xf011e3c0
f0103c42:	e8 5e 18 00 00       	call   f01054a5 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock be  fore doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103c47:	e8 eb 15 00 00       	call   f0105237 <cpunum>
f0103c4c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c4f:	83 c4 10             	add    $0x10,%esp
f0103c52:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103c59:	75 19                	jne    f0103c74 <trap+0xaa>
f0103c5b:	68 7c 6c 10 f0       	push   $0xf0106c7c
f0103c60:	68 6f 67 10 f0       	push   $0xf010676f
f0103c65:	68 19 01 00 00       	push   $0x119
f0103c6a:	68 70 6c 10 f0       	push   $0xf0106c70
f0103c6f:	e8 cc c3 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103c74:	e8 be 15 00 00       	call   f0105237 <cpunum>
f0103c79:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c7c:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103c82:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103c86:	75 2d                	jne    f0103cb5 <trap+0xeb>
			env_free(curenv);
f0103c88:	e8 aa 15 00 00       	call   f0105237 <cpunum>
f0103c8d:	83 ec 0c             	sub    $0xc,%esp
f0103c90:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c93:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103c99:	e8 5f f4 ff ff       	call   f01030fd <env_free>
			curenv = NULL;
f0103c9e:	e8 94 15 00 00       	call   f0105237 <cpunum>
f0103ca3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ca6:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f0103cad:	00 00 00 
			sched_yield();
f0103cb0:	e8 5d 02 00 00       	call   f0103f12 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103cb5:	e8 7d 15 00 00       	call   f0105237 <cpunum>
f0103cba:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cbd:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103cc3:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103cc8:	89 c7                	mov    %eax,%edi
f0103cca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103ccc:	e8 66 15 00 00       	call   f0105237 <cpunum>
f0103cd1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd4:	8b b0 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103cda:	89 35 60 9a 22 f0    	mov    %esi,0xf0229a60
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103ce0:	8b 46 28             	mov    0x28(%esi),%eax
f0103ce3:	83 f8 27             	cmp    $0x27,%eax
f0103ce6:	75 1d                	jne    f0103d05 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103ce8:	83 ec 0c             	sub    $0xc,%esp
f0103ceb:	68 83 6c 10 f0       	push   $0xf0106c83
f0103cf0:	e8 c6 f8 ff ff       	call   f01035bb <cprintf>
		print_trapframe(tf);
f0103cf5:	89 34 24             	mov    %esi,(%esp)
f0103cf8:	e8 e0 fc ff ff       	call   f01039dd <print_trapframe>
f0103cfd:	83 c4 10             	add    $0x10,%esp
f0103d00:	e9 83 00 00 00       	jmp    f0103d88 <trap+0x1be>
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	//print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
f0103d05:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103d0a:	75 17                	jne    f0103d23 <trap+0x159>
		panic("unhandled trap in kernel");
f0103d0c:	83 ec 04             	sub    $0x4,%esp
f0103d0f:	68 a0 6c 10 f0       	push   $0xf0106ca0
f0103d14:	68 e6 00 00 00       	push   $0xe6
f0103d19:	68 70 6c 10 f0       	push   $0xf0106c70
f0103d1e:	e8 1d c3 ff ff       	call   f0100040 <_panic>
	else {
		//cprintf("asdas\n");
		if(tf->tf_trapno ==T_PGFLT)
f0103d23:	83 f8 0e             	cmp    $0xe,%eax
f0103d26:	75 0e                	jne    f0103d36 <trap+0x16c>
		{
			page_fault_handler(tf);
f0103d28:	83 ec 0c             	sub    $0xc,%esp
f0103d2b:	56                   	push   %esi
f0103d2c:	e8 41 fe ff ff       	call   f0103b72 <page_fault_handler>
f0103d31:	83 c4 10             	add    $0x10,%esp
f0103d34:	eb 52                	jmp    f0103d88 <trap+0x1be>
		}
		else if(tf->tf_trapno==T_BRKPT)
f0103d36:	83 f8 03             	cmp    $0x3,%eax
f0103d39:	75 0e                	jne    f0103d49 <trap+0x17f>
		{
			monitor(tf);
f0103d3b:	83 ec 0c             	sub    $0xc,%esp
f0103d3e:	56                   	push   %esi
f0103d3f:	e8 5b cb ff ff       	call   f010089f <monitor>
f0103d44:	83 c4 10             	add    $0x10,%esp
f0103d47:	eb 3f                	jmp    f0103d88 <trap+0x1be>
		}
		else if(tf->tf_trapno==T_SYSCALL)
f0103d49:	83 f8 30             	cmp    $0x30,%eax
f0103d4c:	75 21                	jne    f0103d6f <trap+0x1a5>
		{
			tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103d4e:	83 ec 08             	sub    $0x8,%esp
f0103d51:	ff 76 04             	pushl  0x4(%esi)
f0103d54:	ff 36                	pushl  (%esi)
f0103d56:	ff 76 10             	pushl  0x10(%esi)
f0103d59:	ff 76 18             	pushl  0x18(%esi)
f0103d5c:	ff 76 14             	pushl  0x14(%esi)
f0103d5f:	ff 76 1c             	pushl  0x1c(%esi)
f0103d62:	e8 19 02 00 00       	call   f0103f80 <syscall>
f0103d67:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103d6a:	83 c4 20             	add    $0x20,%esp
f0103d6d:	eb 19                	jmp    f0103d88 <trap+0x1be>
		}
		else
		{
		
			env_destroy(curenv);
f0103d6f:	e8 c3 14 00 00       	call   f0105237 <cpunum>
f0103d74:	83 ec 0c             	sub    $0xc,%esp
f0103d77:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d7a:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103d80:	e8 53 f5 ff ff       	call   f01032d8 <env_destroy>
f0103d85:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103d88:	e8 aa 14 00 00       	call   f0105237 <cpunum>
f0103d8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d90:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103d97:	74 2a                	je     f0103dc3 <trap+0x1f9>
f0103d99:	e8 99 14 00 00       	call   f0105237 <cpunum>
f0103d9e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da1:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103da7:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103dab:	75 16                	jne    f0103dc3 <trap+0x1f9>
		env_run(curenv);
f0103dad:	e8 85 14 00 00       	call   f0105237 <cpunum>
f0103db2:	83 ec 0c             	sub    $0xc,%esp
f0103db5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db8:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103dbe:	e8 b4 f5 ff ff       	call   f0103377 <env_run>
	else
		sched_yield();
f0103dc3:	e8 4a 01 00 00       	call   f0103f12 <sched_yield>

f0103dc8 <divide_error>:
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
TRAPHANDLER_NOEC(divide_error,T_DIVIDE)
f0103dc8:	6a 00                	push   $0x0
f0103dca:	6a 00                	push   $0x0
f0103dcc:	eb 5e                	jmp    f0103e2c <_alltraps>

f0103dce <debuf_exception>:
TRAPHANDLER_NOEC(debuf_exception,T_DEBUG)
f0103dce:	6a 00                	push   $0x0
f0103dd0:	6a 01                	push   $0x1
f0103dd2:	eb 58                	jmp    f0103e2c <_alltraps>

f0103dd4 <nmi_interrupt>:
TRAPHANDLER_NOEC(nmi_interrupt,T_NMI)
f0103dd4:	6a 00                	push   $0x0
f0103dd6:	6a 02                	push   $0x2
f0103dd8:	eb 52                	jmp    f0103e2c <_alltraps>

f0103dda <break_point>:
TRAPHANDLER_NOEC(break_point,T_BRKPT)
f0103dda:	6a 00                	push   $0x0
f0103ddc:	6a 03                	push   $0x3
f0103dde:	eb 4c                	jmp    f0103e2c <_alltraps>

f0103de0 <overflow>:
TRAPHANDLER_NOEC(overflow,T_OFLOW)
f0103de0:	6a 00                	push   $0x0
f0103de2:	6a 04                	push   $0x4
f0103de4:	eb 46                	jmp    f0103e2c <_alltraps>

f0103de6 <bound_check>:
TRAPHANDLER_NOEC(bound_check,T_BOUND);
f0103de6:	6a 00                	push   $0x0
f0103de8:	6a 05                	push   $0x5
f0103dea:	eb 40                	jmp    f0103e2c <_alltraps>

f0103dec <illegal_opcode>:
TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)
f0103dec:	6a 00                	push   $0x0
f0103dee:	6a 06                	push   $0x6
f0103df0:	eb 3a                	jmp    f0103e2c <_alltraps>

f0103df2 <device_not_available>:
TRAPHANDLER_NOEC(device_not_available,T_DEVICE)
f0103df2:	6a 00                	push   $0x0
f0103df4:	6a 07                	push   $0x7
f0103df6:	eb 34                	jmp    f0103e2c <_alltraps>

f0103df8 <double_fault>:
TRAPHANDLER(double_fault,T_DBLFLT)
f0103df8:	6a 08                	push   $0x8
f0103dfa:	eb 30                	jmp    f0103e2c <_alltraps>

f0103dfc <invalid_tss>:
TRAPHANDLER(invalid_tss,T_TSS)
f0103dfc:	6a 0a                	push   $0xa
f0103dfe:	eb 2c                	jmp    f0103e2c <_alltraps>

f0103e00 <segment_not_present>:
TRAPHANDLER(segment_not_present,T_SEGNP)
f0103e00:	6a 0b                	push   $0xb
f0103e02:	eb 28                	jmp    f0103e2c <_alltraps>

f0103e04 <stack_exception>:
TRAPHANDLER(stack_exception,T_STACK)
f0103e04:	6a 0c                	push   $0xc
f0103e06:	eb 24                	jmp    f0103e2c <_alltraps>

f0103e08 <general_protection_fault>:
TRAPHANDLER(general_protection_fault,T_GPFLT)
f0103e08:	6a 0d                	push   $0xd
f0103e0a:	eb 20                	jmp    f0103e2c <_alltraps>

f0103e0c <page_fault>:
TRAPHANDLER(page_fault,T_PGFLT)
f0103e0c:	6a 0e                	push   $0xe
f0103e0e:	eb 1c                	jmp    f0103e2c <_alltraps>

f0103e10 <floating_point_error>:
TRAPHANDLER_NOEC(floating_point_error,T_FPERR)
f0103e10:	6a 00                	push   $0x0
f0103e12:	6a 10                	push   $0x10
f0103e14:	eb 16                	jmp    f0103e2c <_alltraps>

f0103e16 <alignment_check>:
TRAPHANDLER(alignment_check,T_ALIGN)
f0103e16:	6a 11                	push   $0x11
f0103e18:	eb 12                	jmp    f0103e2c <_alltraps>

f0103e1a <machine_check>:
TRAPHANDLER_NOEC(machine_check,T_MCHK)
f0103e1a:	6a 00                	push   $0x0
f0103e1c:	6a 12                	push   $0x12
f0103e1e:	eb 0c                	jmp    f0103e2c <_alltraps>

f0103e20 <simd_floating_error>:
TRAPHANDLER_NOEC(simd_floating_error,T_SIMDERR)
f0103e20:	6a 00                	push   $0x0
f0103e22:	6a 13                	push   $0x13
f0103e24:	eb 06                	jmp    f0103e2c <_alltraps>

f0103e26 <system_call>:
TRAPHANDLER_NOEC(system_call,T_SYSCALL)
f0103e26:	6a 00                	push   $0x0
f0103e28:	6a 30                	push   $0x30
f0103e2a:	eb 00                	jmp    f0103e2c <_alltraps>

f0103e2c <_alltraps>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
_alltraps:
pushl %ds
f0103e2c:	1e                   	push   %ds
pushl %es
f0103e2d:	06                   	push   %es
pushal
f0103e2e:	60                   	pusha  
movl $GD_KD,%eax
f0103e2f:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax,%ds
f0103e34:	8e d8                	mov    %eax,%ds
movw %ax,%es
f0103e36:	8e c0                	mov    %eax,%es
pushl %esp
f0103e38:	54                   	push   %esp
call trap
f0103e39:	e8 8c fd ff ff       	call   f0103bca <trap>

f0103e3e <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103e3e:	55                   	push   %ebp
f0103e3f:	89 e5                	mov    %esp,%ebp
f0103e41:	83 ec 08             	sub    $0x8,%esp
f0103e44:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f0103e49:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103e4c:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103e51:	8b 02                	mov    (%edx),%eax
f0103e53:	83 e8 01             	sub    $0x1,%eax
f0103e56:	83 f8 02             	cmp    $0x2,%eax
f0103e59:	76 10                	jbe    f0103e6b <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103e5b:	83 c1 01             	add    $0x1,%ecx
f0103e5e:	83 c2 7c             	add    $0x7c,%edx
f0103e61:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103e67:	75 e8                	jne    f0103e51 <sched_halt+0x13>
f0103e69:	eb 08                	jmp    f0103e73 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103e6b:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103e71:	75 1f                	jne    f0103e92 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103e73:	83 ec 0c             	sub    $0xc,%esp
f0103e76:	68 e0 6c 10 f0       	push   $0xf0106ce0
f0103e7b:	e8 3b f7 ff ff       	call   f01035bb <cprintf>
f0103e80:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103e83:	83 ec 0c             	sub    $0xc,%esp
f0103e86:	6a 00                	push   $0x0
f0103e88:	e8 12 ca ff ff       	call   f010089f <monitor>
f0103e8d:	83 c4 10             	add    $0x10,%esp
f0103e90:	eb f1                	jmp    f0103e83 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103e92:	e8 a0 13 00 00       	call   f0105237 <cpunum>
f0103e97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9a:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f0103ea1:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103ea4:	a1 8c 9e 22 f0       	mov    0xf0229e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ea9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103eae:	77 12                	ja     f0103ec2 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103eb0:	50                   	push   %eax
f0103eb1:	68 08 59 10 f0       	push   $0xf0105908
f0103eb6:	6a 50                	push   $0x50
f0103eb8:	68 09 6d 10 f0       	push   $0xf0106d09
f0103ebd:	e8 7e c1 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103ec2:	05 00 00 00 10       	add    $0x10000000,%eax
f0103ec7:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103eca:	e8 68 13 00 00       	call   f0105237 <cpunum>
f0103ecf:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ed2:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103ed8:	b8 02 00 00 00       	mov    $0x2,%eax
f0103edd:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103ee1:	83 ec 0c             	sub    $0xc,%esp
f0103ee4:	68 c0 e3 11 f0       	push   $0xf011e3c0
f0103ee9:	e8 54 16 00 00       	call   f0105542 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103eee:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103ef0:	e8 42 13 00 00       	call   f0105237 <cpunum>
f0103ef5:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0103ef8:	8b 80 30 a0 22 f0    	mov    -0xfdd5fd0(%eax),%eax
f0103efe:	bd 00 00 00 00       	mov    $0x0,%ebp
f0103f03:	89 c4                	mov    %eax,%esp
f0103f05:	6a 00                	push   $0x0
f0103f07:	6a 00                	push   $0x0
f0103f09:	fb                   	sti    
f0103f0a:	f4                   	hlt    
f0103f0b:	eb fd                	jmp    f0103f0a <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0103f0d:	83 c4 10             	add    $0x10,%esp
f0103f10:	c9                   	leave  
f0103f11:	c3                   	ret    

f0103f12 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0103f12:	55                   	push   %ebp
f0103f13:	89 e5                	mov    %esp,%ebp
f0103f15:	56                   	push   %esi
f0103f16:	53                   	push   %ebx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;
f0103f17:	e8 1b 13 00 00       	call   f0105237 <cpunum>
f0103f1c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1f:	8b b0 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%esi
    uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;
f0103f25:	85 f6                	test   %esi,%esi
f0103f27:	74 0b                	je     f0103f34 <sched_yield+0x22>
f0103f29:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103f2c:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0103f32:	eb 05                	jmp    f0103f39 <sched_yield+0x27>
f0103f34:	b9 00 00 00 00       	mov    $0x0,%ecx
    uint32_t i = start;
    bool first = true;

    for (; i != start || first; i = (i+1) % NENV, first = false)
    {
        if(envs[i].env_status == ENV_RUNNABLE)
f0103f39:	8b 1d 44 92 22 f0    	mov    0xf0229244,%ebx
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;
    uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;
    uint32_t i = start;
f0103f3f:	89 c8                	mov    %ecx,%eax
    bool first = true;

    for (; i != start || first; i = (i+1) % NENV, first = false)
    {
        if(envs[i].env_status == ENV_RUNNABLE)
f0103f41:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0103f44:	01 da                	add    %ebx,%edx
f0103f46:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0103f4a:	75 09                	jne    f0103f55 <sched_yield+0x43>
        {
            env_run(&envs[i]);
f0103f4c:	83 ec 0c             	sub    $0xc,%esp
f0103f4f:	52                   	push   %edx
f0103f50:	e8 22 f4 ff ff       	call   f0103377 <env_run>
	idle = thiscpu->cpu_env;
    uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;
    uint32_t i = start;
    bool first = true;

    for (; i != start || first; i = (i+1) % NENV, first = false)
f0103f55:	83 c0 01             	add    $0x1,%eax
f0103f58:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103f5d:	39 c1                	cmp    %eax,%ecx
f0103f5f:	75 e0                	jne    f0103f41 <sched_yield+0x2f>
            env_run(&envs[i]);
            return ;
        }
    }

    if (idle && idle->env_status == ENV_RUNNING)
f0103f61:	85 f6                	test   %esi,%esi
f0103f63:	74 0f                	je     f0103f74 <sched_yield+0x62>
f0103f65:	83 7e 54 03          	cmpl   $0x3,0x54(%esi)
f0103f69:	75 09                	jne    f0103f74 <sched_yield+0x62>
    {
        env_run(idle);
f0103f6b:	83 ec 0c             	sub    $0xc,%esp
f0103f6e:	56                   	push   %esi
f0103f6f:	e8 03 f4 ff ff       	call   f0103377 <env_run>
        return ;
    }

	// sched_halt never returns
	sched_halt();
f0103f74:	e8 c5 fe ff ff       	call   f0103e3e <sched_halt>
}
f0103f79:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103f7c:	5b                   	pop    %ebx
f0103f7d:	5e                   	pop    %esi
f0103f7e:	5d                   	pop    %ebp
f0103f7f:	c3                   	ret    

f0103f80 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f80:	55                   	push   %ebp
f0103f81:	89 e5                	mov    %esp,%ebp
f0103f83:	53                   	push   %ebx
f0103f84:	83 ec 14             	sub    $0x14,%esp
f0103f87:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno)
f0103f8a:	83 f8 0a             	cmp    $0xa,%eax
f0103f8d:	0f 87 ef 00 00 00    	ja     f0104082 <syscall+0x102>
f0103f93:	ff 24 85 50 6d 10 f0 	jmp    *-0xfef92b0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f0103f9a:	e8 98 12 00 00       	call   f0105237 <cpunum>
f0103f9f:	6a 04                	push   $0x4
f0103fa1:	ff 75 10             	pushl  0x10(%ebp)
f0103fa4:	ff 75 0c             	pushl  0xc(%ebp)
f0103fa7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103faa:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0103fb0:	e8 c9 ec ff ff       	call   f0102c7e <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103fb5:	83 c4 0c             	add    $0xc,%esp
f0103fb8:	ff 75 0c             	pushl  0xc(%ebp)
f0103fbb:	ff 75 10             	pushl  0x10(%ebp)
f0103fbe:	68 16 6d 10 f0       	push   $0xf0106d16
f0103fc3:	e8 f3 f5 ff ff       	call   f01035bb <cprintf>
f0103fc8:	83 c4 10             	add    $0x10,%esp
		 	sys_yield();	
			break;
		default:
			return -E_INVAL;
	}
	return 0;
f0103fcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fd0:	e9 b2 00 00 00       	jmp    f0104087 <syscall+0x107>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103fd5:	e8 39 c6 ff ff       	call   f0100613 <cons_getc>
	 {
		case 0:
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
f0103fda:	e9 a8 00 00 00       	jmp    f0104087 <syscall+0x107>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103fdf:	e8 53 12 00 00       	call   f0105237 <cpunum>
f0103fe4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fe7:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103fed:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
		case 2:
			return sys_getenvid();	
f0103ff0:	e9 92 00 00 00       	jmp    f0104087 <syscall+0x107>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103ff5:	83 ec 04             	sub    $0x4,%esp
f0103ff8:	6a 01                	push   $0x1
f0103ffa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103ffd:	50                   	push   %eax
f0103ffe:	ff 75 0c             	pushl  0xc(%ebp)
f0104001:	e8 4d ed ff ff       	call   f0102d53 <envid2env>
f0104006:	83 c4 10             	add    $0x10,%esp
f0104009:	85 c0                	test   %eax,%eax
f010400b:	78 7a                	js     f0104087 <syscall+0x107>
		return r;
	if (e == curenv)
f010400d:	e8 25 12 00 00       	call   f0105237 <cpunum>
f0104012:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104015:	6b c0 74             	imul   $0x74,%eax,%eax
f0104018:	39 90 28 a0 22 f0    	cmp    %edx,-0xfdd5fd8(%eax)
f010401e:	75 23                	jne    f0104043 <syscall+0xc3>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104020:	e8 12 12 00 00       	call   f0105237 <cpunum>
f0104025:	83 ec 08             	sub    $0x8,%esp
f0104028:	6b c0 74             	imul   $0x74,%eax,%eax
f010402b:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0104031:	ff 70 48             	pushl  0x48(%eax)
f0104034:	68 1b 6d 10 f0       	push   $0xf0106d1b
f0104039:	e8 7d f5 ff ff       	call   f01035bb <cprintf>
f010403e:	83 c4 10             	add    $0x10,%esp
f0104041:	eb 25                	jmp    f0104068 <syscall+0xe8>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104043:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104046:	e8 ec 11 00 00       	call   f0105237 <cpunum>
f010404b:	83 ec 04             	sub    $0x4,%esp
f010404e:	53                   	push   %ebx
f010404f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104052:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0104058:	ff 70 48             	pushl  0x48(%eax)
f010405b:	68 36 6d 10 f0       	push   $0xf0106d36
f0104060:	e8 56 f5 ff ff       	call   f01035bb <cprintf>
f0104065:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104068:	83 ec 0c             	sub    $0xc,%esp
f010406b:	ff 75 f4             	pushl  -0xc(%ebp)
f010406e:	e8 65 f2 ff ff       	call   f01032d8 <env_destroy>
f0104073:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104076:	b8 00 00 00 00       	mov    $0x0,%eax
f010407b:	eb 0a                	jmp    f0104087 <syscall+0x107>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010407d:	e8 90 fe ff ff       	call   f0103f12 <sched_yield>
			return sys_env_destroy(a1);	
		case SYS_yield:
		 	sys_yield();	
			break;
		default:
			return -E_INVAL;
f0104082:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return 0;
}
f0104087:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010408a:	c9                   	leave  
f010408b:	c3                   	ret    

f010408c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010408c:	55                   	push   %ebp
f010408d:	89 e5                	mov    %esp,%ebp
f010408f:	57                   	push   %edi
f0104090:	56                   	push   %esi
f0104091:	53                   	push   %ebx
f0104092:	83 ec 14             	sub    $0x14,%esp
f0104095:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104098:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010409b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010409e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01040a1:	8b 1a                	mov    (%edx),%ebx
f01040a3:	8b 01                	mov    (%ecx),%eax
f01040a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040a8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01040af:	eb 7f                	jmp    f0104130 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01040b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01040b4:	01 d8                	add    %ebx,%eax
f01040b6:	89 c6                	mov    %eax,%esi
f01040b8:	c1 ee 1f             	shr    $0x1f,%esi
f01040bb:	01 c6                	add    %eax,%esi
f01040bd:	d1 fe                	sar    %esi
f01040bf:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01040c2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040c5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01040c8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040ca:	eb 03                	jmp    f01040cf <stab_binsearch+0x43>
			m--;
f01040cc:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040cf:	39 c3                	cmp    %eax,%ebx
f01040d1:	7f 0d                	jg     f01040e0 <stab_binsearch+0x54>
f01040d3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01040d7:	83 ea 0c             	sub    $0xc,%edx
f01040da:	39 f9                	cmp    %edi,%ecx
f01040dc:	75 ee                	jne    f01040cc <stab_binsearch+0x40>
f01040de:	eb 05                	jmp    f01040e5 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01040e0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01040e3:	eb 4b                	jmp    f0104130 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01040e5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040e8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040eb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01040ef:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040f2:	76 11                	jbe    f0104105 <stab_binsearch+0x79>
			*region_left = m;
f01040f4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01040f7:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01040f9:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040fc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104103:	eb 2b                	jmp    f0104130 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104105:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104108:	73 14                	jae    f010411e <stab_binsearch+0x92>
			*region_right = m - 1;
f010410a:	83 e8 01             	sub    $0x1,%eax
f010410d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104110:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104113:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104115:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010411c:	eb 12                	jmp    f0104130 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010411e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104121:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104123:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104127:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104129:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104130:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104133:	0f 8e 78 ff ff ff    	jle    f01040b1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104139:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010413d:	75 0f                	jne    f010414e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010413f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104142:	8b 00                	mov    (%eax),%eax
f0104144:	83 e8 01             	sub    $0x1,%eax
f0104147:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010414a:	89 06                	mov    %eax,(%esi)
f010414c:	eb 2c                	jmp    f010417a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010414e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104151:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104153:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104156:	8b 0e                	mov    (%esi),%ecx
f0104158:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010415b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010415e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104161:	eb 03                	jmp    f0104166 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104163:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104166:	39 c8                	cmp    %ecx,%eax
f0104168:	7e 0b                	jle    f0104175 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010416a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010416e:	83 ea 0c             	sub    $0xc,%edx
f0104171:	39 df                	cmp    %ebx,%edi
f0104173:	75 ee                	jne    f0104163 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104175:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104178:	89 06                	mov    %eax,(%esi)
	}
}
f010417a:	83 c4 14             	add    $0x14,%esp
f010417d:	5b                   	pop    %ebx
f010417e:	5e                   	pop    %esi
f010417f:	5f                   	pop    %edi
f0104180:	5d                   	pop    %ebp
f0104181:	c3                   	ret    

f0104182 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104182:	55                   	push   %ebp
f0104183:	89 e5                	mov    %esp,%ebp
f0104185:	57                   	push   %edi
f0104186:	56                   	push   %esi
f0104187:	53                   	push   %ebx
f0104188:	83 ec 2c             	sub    $0x2c,%esp
f010418b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010418e:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104191:	c7 06 7c 6d 10 f0    	movl   $0xf0106d7c,(%esi)
	info->eip_line = 0;
f0104197:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010419e:	c7 46 08 7c 6d 10 f0 	movl   $0xf0106d7c,0x8(%esi)
	info->eip_fn_namelen = 9;
f01041a5:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01041ac:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01041af:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01041b6:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01041bc:	0f 87 a3 00 00 00    	ja     f0104265 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
f01041c2:	e8 70 10 00 00       	call   f0105237 <cpunum>
f01041c7:	6a 00                	push   $0x0
f01041c9:	6a 10                	push   $0x10
f01041cb:	68 00 00 20 00       	push   $0x200000
f01041d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01041d3:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f01041d9:	e8 20 ea ff ff       	call   f0102bfe <user_mem_check>
f01041de:	83 c4 10             	add    $0x10,%esp
f01041e1:	85 c0                	test   %eax,%eax
f01041e3:	0f 88 d4 01 00 00    	js     f01043bd <debuginfo_eip+0x23b>
			return -1;
		stabs = usd->stabs;
f01041e9:	a1 00 00 20 00       	mov    0x200000,%eax
f01041ee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01041f1:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01041f7:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01041fd:	89 55 cc             	mov    %edx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0104200:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0104205:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
f0104208:	e8 2a 10 00 00       	call   f0105237 <cpunum>
f010420d:	6a 00                	push   $0x0
f010420f:	89 da                	mov    %ebx,%edx
f0104211:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104214:	29 ca                	sub    %ecx,%edx
f0104216:	c1 fa 02             	sar    $0x2,%edx
f0104219:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010421f:	52                   	push   %edx
f0104220:	51                   	push   %ecx
f0104221:	6b c0 74             	imul   $0x74,%eax,%eax
f0104224:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f010422a:	e8 cf e9 ff ff       	call   f0102bfe <user_mem_check>
f010422f:	83 c4 10             	add    $0x10,%esp
f0104232:	85 c0                	test   %eax,%eax
f0104234:	0f 88 8a 01 00 00    	js     f01043c4 <debuginfo_eip+0x242>
f010423a:	e8 f8 0f 00 00       	call   f0105237 <cpunum>
f010423f:	6a 00                	push   $0x0
f0104241:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104244:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104247:	29 ca                	sub    %ecx,%edx
f0104249:	52                   	push   %edx
f010424a:	51                   	push   %ecx
f010424b:	6b c0 74             	imul   $0x74,%eax,%eax
f010424e:	ff b0 28 a0 22 f0    	pushl  -0xfdd5fd8(%eax)
f0104254:	e8 a5 e9 ff ff       	call   f0102bfe <user_mem_check>
f0104259:	83 c4 10             	add    $0x10,%esp
f010425c:	85 c0                	test   %eax,%eax
f010425e:	79 1f                	jns    f010427f <debuginfo_eip+0xfd>
f0104260:	e9 66 01 00 00       	jmp    f01043cb <debuginfo_eip+0x249>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104265:	c7 45 d0 7f 3f 11 f0 	movl   $0xf0113f7f,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010426c:	c7 45 cc c1 09 11 f0 	movl   $0xf01109c1,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104273:	bb c0 09 11 f0       	mov    $0xf01109c0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104278:	c7 45 d4 58 72 10 f0 	movl   $0xf0107258,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010427f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104282:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104285:	0f 83 47 01 00 00    	jae    f01043d2 <debuginfo_eip+0x250>
f010428b:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010428f:	0f 85 44 01 00 00    	jne    f01043d9 <debuginfo_eip+0x257>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104295:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010429c:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f010429f:	c1 fb 02             	sar    $0x2,%ebx
f01042a2:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01042a8:	83 e8 01             	sub    $0x1,%eax
f01042ab:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042ae:	83 ec 08             	sub    $0x8,%esp
f01042b1:	57                   	push   %edi
f01042b2:	6a 64                	push   $0x64
f01042b4:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01042b7:	89 d1                	mov    %edx,%ecx
f01042b9:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01042bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01042bf:	89 d8                	mov    %ebx,%eax
f01042c1:	e8 c6 fd ff ff       	call   f010408c <stab_binsearch>
	if (lfile == 0)
f01042c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042c9:	83 c4 10             	add    $0x10,%esp
f01042cc:	85 c0                	test   %eax,%eax
f01042ce:	0f 84 0c 01 00 00    	je     f01043e0 <debuginfo_eip+0x25e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01042d4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01042d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042da:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01042dd:	83 ec 08             	sub    $0x8,%esp
f01042e0:	57                   	push   %edi
f01042e1:	6a 24                	push   $0x24
f01042e3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01042e6:	89 d1                	mov    %edx,%ecx
f01042e8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01042eb:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01042ee:	89 d8                	mov    %ebx,%eax
f01042f0:	e8 97 fd ff ff       	call   f010408c <stab_binsearch>

	if (lfun <= rfun) {
f01042f5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01042f8:	83 c4 10             	add    $0x10,%esp
f01042fb:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01042fe:	7f 24                	jg     f0104324 <debuginfo_eip+0x1a2>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104300:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104303:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104306:	8d 14 87             	lea    (%edi,%eax,4),%edx
f0104309:	8b 02                	mov    (%edx),%eax
f010430b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010430e:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104311:	29 f9                	sub    %edi,%ecx
f0104313:	39 c8                	cmp    %ecx,%eax
f0104315:	73 05                	jae    f010431c <debuginfo_eip+0x19a>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104317:	01 f8                	add    %edi,%eax
f0104319:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010431c:	8b 42 08             	mov    0x8(%edx),%eax
f010431f:	89 46 10             	mov    %eax,0x10(%esi)
f0104322:	eb 06                	jmp    f010432a <debuginfo_eip+0x1a8>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104324:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104327:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010432a:	83 ec 08             	sub    $0x8,%esp
f010432d:	6a 3a                	push   $0x3a
f010432f:	ff 76 08             	pushl  0x8(%esi)
f0104332:	e8 af 08 00 00       	call   f0104be6 <strfind>
f0104337:	2b 46 08             	sub    0x8(%esi),%eax
f010433a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010433d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104340:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104343:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104346:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104349:	83 c4 10             	add    $0x10,%esp
f010434c:	eb 06                	jmp    f0104354 <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010434e:	83 eb 01             	sub    $0x1,%ebx
f0104351:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104354:	39 fb                	cmp    %edi,%ebx
f0104356:	7c 2d                	jl     f0104385 <debuginfo_eip+0x203>
	       && stabs[lline].n_type != N_SOL
f0104358:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010435c:	80 fa 84             	cmp    $0x84,%dl
f010435f:	74 0b                	je     f010436c <debuginfo_eip+0x1ea>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104361:	80 fa 64             	cmp    $0x64,%dl
f0104364:	75 e8                	jne    f010434e <debuginfo_eip+0x1cc>
f0104366:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010436a:	74 e2                	je     f010434e <debuginfo_eip+0x1cc>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010436c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010436f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104372:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104375:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104378:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010437b:	29 f8                	sub    %edi,%eax
f010437d:	39 c2                	cmp    %eax,%edx
f010437f:	73 04                	jae    f0104385 <debuginfo_eip+0x203>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104381:	01 fa                	add    %edi,%edx
f0104383:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104385:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104388:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010438b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104390:	39 cb                	cmp    %ecx,%ebx
f0104392:	7d 58                	jge    f01043ec <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
f0104394:	8d 53 01             	lea    0x1(%ebx),%edx
f0104397:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010439a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010439d:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01043a0:	eb 07                	jmp    f01043a9 <debuginfo_eip+0x227>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01043a2:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01043a6:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01043a9:	39 ca                	cmp    %ecx,%edx
f01043ab:	74 3a                	je     f01043e7 <debuginfo_eip+0x265>
f01043ad:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01043b0:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01043b4:	74 ec                	je     f01043a2 <debuginfo_eip+0x220>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01043bb:	eb 2f                	jmp    f01043ec <debuginfo_eip+0x26a>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
			return -1;
f01043bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043c2:	eb 28                	jmp    f01043ec <debuginfo_eip+0x26a>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
		{
			return -1;
f01043c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043c9:	eb 21                	jmp    f01043ec <debuginfo_eip+0x26a>
f01043cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043d0:	eb 1a                	jmp    f01043ec <debuginfo_eip+0x26a>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01043d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043d7:	eb 13                	jmp    f01043ec <debuginfo_eip+0x26a>
f01043d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043de:	eb 0c                	jmp    f01043ec <debuginfo_eip+0x26a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01043e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01043e5:	eb 05                	jmp    f01043ec <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043e7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01043ef:	5b                   	pop    %ebx
f01043f0:	5e                   	pop    %esi
f01043f1:	5f                   	pop    %edi
f01043f2:	5d                   	pop    %ebp
f01043f3:	c3                   	ret    

f01043f4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01043f4:	55                   	push   %ebp
f01043f5:	89 e5                	mov    %esp,%ebp
f01043f7:	57                   	push   %edi
f01043f8:	56                   	push   %esi
f01043f9:	53                   	push   %ebx
f01043fa:	83 ec 1c             	sub    $0x1c,%esp
f01043fd:	89 c7                	mov    %eax,%edi
f01043ff:	89 d6                	mov    %edx,%esi
f0104401:	8b 45 08             	mov    0x8(%ebp),%eax
f0104404:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104407:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010440a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010440d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104410:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104415:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104418:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010441b:	39 d3                	cmp    %edx,%ebx
f010441d:	72 05                	jb     f0104424 <printnum+0x30>
f010441f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104422:	77 45                	ja     f0104469 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104424:	83 ec 0c             	sub    $0xc,%esp
f0104427:	ff 75 18             	pushl  0x18(%ebp)
f010442a:	8b 45 14             	mov    0x14(%ebp),%eax
f010442d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104430:	53                   	push   %ebx
f0104431:	ff 75 10             	pushl  0x10(%ebp)
f0104434:	83 ec 08             	sub    $0x8,%esp
f0104437:	ff 75 e4             	pushl  -0x1c(%ebp)
f010443a:	ff 75 e0             	pushl  -0x20(%ebp)
f010443d:	ff 75 dc             	pushl  -0x24(%ebp)
f0104440:	ff 75 d8             	pushl  -0x28(%ebp)
f0104443:	e8 e8 11 00 00       	call   f0105630 <__udivdi3>
f0104448:	83 c4 18             	add    $0x18,%esp
f010444b:	52                   	push   %edx
f010444c:	50                   	push   %eax
f010444d:	89 f2                	mov    %esi,%edx
f010444f:	89 f8                	mov    %edi,%eax
f0104451:	e8 9e ff ff ff       	call   f01043f4 <printnum>
f0104456:	83 c4 20             	add    $0x20,%esp
f0104459:	eb 18                	jmp    f0104473 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010445b:	83 ec 08             	sub    $0x8,%esp
f010445e:	56                   	push   %esi
f010445f:	ff 75 18             	pushl  0x18(%ebp)
f0104462:	ff d7                	call   *%edi
f0104464:	83 c4 10             	add    $0x10,%esp
f0104467:	eb 03                	jmp    f010446c <printnum+0x78>
f0104469:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010446c:	83 eb 01             	sub    $0x1,%ebx
f010446f:	85 db                	test   %ebx,%ebx
f0104471:	7f e8                	jg     f010445b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104473:	83 ec 08             	sub    $0x8,%esp
f0104476:	56                   	push   %esi
f0104477:	83 ec 04             	sub    $0x4,%esp
f010447a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010447d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104480:	ff 75 dc             	pushl  -0x24(%ebp)
f0104483:	ff 75 d8             	pushl  -0x28(%ebp)
f0104486:	e8 d5 12 00 00       	call   f0105760 <__umoddi3>
f010448b:	83 c4 14             	add    $0x14,%esp
f010448e:	0f be 80 86 6d 10 f0 	movsbl -0xfef927a(%eax),%eax
f0104495:	50                   	push   %eax
f0104496:	ff d7                	call   *%edi
}
f0104498:	83 c4 10             	add    $0x10,%esp
f010449b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010449e:	5b                   	pop    %ebx
f010449f:	5e                   	pop    %esi
f01044a0:	5f                   	pop    %edi
f01044a1:	5d                   	pop    %ebp
f01044a2:	c3                   	ret    

f01044a3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01044a3:	55                   	push   %ebp
f01044a4:	89 e5                	mov    %esp,%ebp
f01044a6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01044a9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01044ad:	8b 10                	mov    (%eax),%edx
f01044af:	3b 50 04             	cmp    0x4(%eax),%edx
f01044b2:	73 0a                	jae    f01044be <sprintputch+0x1b>
		*b->buf++ = ch;
f01044b4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01044b7:	89 08                	mov    %ecx,(%eax)
f01044b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01044bc:	88 02                	mov    %al,(%edx)
}
f01044be:	5d                   	pop    %ebp
f01044bf:	c3                   	ret    

f01044c0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01044c0:	55                   	push   %ebp
f01044c1:	89 e5                	mov    %esp,%ebp
f01044c3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01044c6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01044c9:	50                   	push   %eax
f01044ca:	ff 75 10             	pushl  0x10(%ebp)
f01044cd:	ff 75 0c             	pushl  0xc(%ebp)
f01044d0:	ff 75 08             	pushl  0x8(%ebp)
f01044d3:	e8 05 00 00 00       	call   f01044dd <vprintfmt>
	va_end(ap);
}
f01044d8:	83 c4 10             	add    $0x10,%esp
f01044db:	c9                   	leave  
f01044dc:	c3                   	ret    

f01044dd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01044dd:	55                   	push   %ebp
f01044de:	89 e5                	mov    %esp,%ebp
f01044e0:	57                   	push   %edi
f01044e1:	56                   	push   %esi
f01044e2:	53                   	push   %ebx
f01044e3:	83 ec 2c             	sub    $0x2c,%esp
f01044e6:	8b 75 08             	mov    0x8(%ebp),%esi
f01044e9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01044ec:	8b 7d 10             	mov    0x10(%ebp),%edi
f01044ef:	eb 12                	jmp    f0104503 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01044f1:	85 c0                	test   %eax,%eax
f01044f3:	0f 84 42 04 00 00    	je     f010493b <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f01044f9:	83 ec 08             	sub    $0x8,%esp
f01044fc:	53                   	push   %ebx
f01044fd:	50                   	push   %eax
f01044fe:	ff d6                	call   *%esi
f0104500:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104503:	83 c7 01             	add    $0x1,%edi
f0104506:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010450a:	83 f8 25             	cmp    $0x25,%eax
f010450d:	75 e2                	jne    f01044f1 <vprintfmt+0x14>
f010450f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104513:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010451a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104521:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104528:	b9 00 00 00 00       	mov    $0x0,%ecx
f010452d:	eb 07                	jmp    f0104536 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010452f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104532:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104536:	8d 47 01             	lea    0x1(%edi),%eax
f0104539:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010453c:	0f b6 07             	movzbl (%edi),%eax
f010453f:	0f b6 d0             	movzbl %al,%edx
f0104542:	83 e8 23             	sub    $0x23,%eax
f0104545:	3c 55                	cmp    $0x55,%al
f0104547:	0f 87 d3 03 00 00    	ja     f0104920 <vprintfmt+0x443>
f010454d:	0f b6 c0             	movzbl %al,%eax
f0104550:	ff 24 85 40 6e 10 f0 	jmp    *-0xfef91c0(,%eax,4)
f0104557:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010455a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010455e:	eb d6                	jmp    f0104536 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104560:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104563:	b8 00 00 00 00       	mov    $0x0,%eax
f0104568:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010456b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010456e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104572:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104575:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104578:	83 f9 09             	cmp    $0x9,%ecx
f010457b:	77 3f                	ja     f01045bc <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010457d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104580:	eb e9                	jmp    f010456b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104582:	8b 45 14             	mov    0x14(%ebp),%eax
f0104585:	8b 00                	mov    (%eax),%eax
f0104587:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010458a:	8b 45 14             	mov    0x14(%ebp),%eax
f010458d:	8d 40 04             	lea    0x4(%eax),%eax
f0104590:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104593:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104596:	eb 2a                	jmp    f01045c2 <vprintfmt+0xe5>
f0104598:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010459b:	85 c0                	test   %eax,%eax
f010459d:	ba 00 00 00 00       	mov    $0x0,%edx
f01045a2:	0f 49 d0             	cmovns %eax,%edx
f01045a5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01045ab:	eb 89                	jmp    f0104536 <vprintfmt+0x59>
f01045ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01045b0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01045b7:	e9 7a ff ff ff       	jmp    f0104536 <vprintfmt+0x59>
f01045bc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01045bf:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01045c2:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01045c6:	0f 89 6a ff ff ff    	jns    f0104536 <vprintfmt+0x59>
				width = precision, precision = -1;
f01045cc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01045cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01045d2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01045d9:	e9 58 ff ff ff       	jmp    f0104536 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01045de:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01045e4:	e9 4d ff ff ff       	jmp    f0104536 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01045e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01045ec:	8d 78 04             	lea    0x4(%eax),%edi
f01045ef:	83 ec 08             	sub    $0x8,%esp
f01045f2:	53                   	push   %ebx
f01045f3:	ff 30                	pushl  (%eax)
f01045f5:	ff d6                	call   *%esi
			break;
f01045f7:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01045fa:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104600:	e9 fe fe ff ff       	jmp    f0104503 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104605:	8b 45 14             	mov    0x14(%ebp),%eax
f0104608:	8d 78 04             	lea    0x4(%eax),%edi
f010460b:	8b 00                	mov    (%eax),%eax
f010460d:	99                   	cltd   
f010460e:	31 d0                	xor    %edx,%eax
f0104610:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104612:	83 f8 08             	cmp    $0x8,%eax
f0104615:	7f 0b                	jg     f0104622 <vprintfmt+0x145>
f0104617:	8b 14 85 a0 6f 10 f0 	mov    -0xfef9060(,%eax,4),%edx
f010461e:	85 d2                	test   %edx,%edx
f0104620:	75 1b                	jne    f010463d <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0104622:	50                   	push   %eax
f0104623:	68 9e 6d 10 f0       	push   $0xf0106d9e
f0104628:	53                   	push   %ebx
f0104629:	56                   	push   %esi
f010462a:	e8 91 fe ff ff       	call   f01044c0 <printfmt>
f010462f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104632:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104635:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104638:	e9 c6 fe ff ff       	jmp    f0104503 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010463d:	52                   	push   %edx
f010463e:	68 81 67 10 f0       	push   $0xf0106781
f0104643:	53                   	push   %ebx
f0104644:	56                   	push   %esi
f0104645:	e8 76 fe ff ff       	call   f01044c0 <printfmt>
f010464a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010464d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104650:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104653:	e9 ab fe ff ff       	jmp    f0104503 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104658:	8b 45 14             	mov    0x14(%ebp),%eax
f010465b:	83 c0 04             	add    $0x4,%eax
f010465e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104661:	8b 45 14             	mov    0x14(%ebp),%eax
f0104664:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104666:	85 ff                	test   %edi,%edi
f0104668:	b8 97 6d 10 f0       	mov    $0xf0106d97,%eax
f010466d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104670:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104674:	0f 8e 94 00 00 00    	jle    f010470e <vprintfmt+0x231>
f010467a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010467e:	0f 84 98 00 00 00    	je     f010471c <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104684:	83 ec 08             	sub    $0x8,%esp
f0104687:	ff 75 d0             	pushl  -0x30(%ebp)
f010468a:	57                   	push   %edi
f010468b:	e8 0c 04 00 00       	call   f0104a9c <strnlen>
f0104690:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104693:	29 c1                	sub    %eax,%ecx
f0104695:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104698:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010469b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010469f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01046a2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01046a5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046a7:	eb 0f                	jmp    f01046b8 <vprintfmt+0x1db>
					putch(padc, putdat);
f01046a9:	83 ec 08             	sub    $0x8,%esp
f01046ac:	53                   	push   %ebx
f01046ad:	ff 75 e0             	pushl  -0x20(%ebp)
f01046b0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046b2:	83 ef 01             	sub    $0x1,%edi
f01046b5:	83 c4 10             	add    $0x10,%esp
f01046b8:	85 ff                	test   %edi,%edi
f01046ba:	7f ed                	jg     f01046a9 <vprintfmt+0x1cc>
f01046bc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01046bf:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01046c2:	85 c9                	test   %ecx,%ecx
f01046c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01046c9:	0f 49 c1             	cmovns %ecx,%eax
f01046cc:	29 c1                	sub    %eax,%ecx
f01046ce:	89 75 08             	mov    %esi,0x8(%ebp)
f01046d1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01046d4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01046d7:	89 cb                	mov    %ecx,%ebx
f01046d9:	eb 4d                	jmp    f0104728 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01046db:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01046df:	74 1b                	je     f01046fc <vprintfmt+0x21f>
f01046e1:	0f be c0             	movsbl %al,%eax
f01046e4:	83 e8 20             	sub    $0x20,%eax
f01046e7:	83 f8 5e             	cmp    $0x5e,%eax
f01046ea:	76 10                	jbe    f01046fc <vprintfmt+0x21f>
					putch('?', putdat);
f01046ec:	83 ec 08             	sub    $0x8,%esp
f01046ef:	ff 75 0c             	pushl  0xc(%ebp)
f01046f2:	6a 3f                	push   $0x3f
f01046f4:	ff 55 08             	call   *0x8(%ebp)
f01046f7:	83 c4 10             	add    $0x10,%esp
f01046fa:	eb 0d                	jmp    f0104709 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f01046fc:	83 ec 08             	sub    $0x8,%esp
f01046ff:	ff 75 0c             	pushl  0xc(%ebp)
f0104702:	52                   	push   %edx
f0104703:	ff 55 08             	call   *0x8(%ebp)
f0104706:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104709:	83 eb 01             	sub    $0x1,%ebx
f010470c:	eb 1a                	jmp    f0104728 <vprintfmt+0x24b>
f010470e:	89 75 08             	mov    %esi,0x8(%ebp)
f0104711:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104714:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104717:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010471a:	eb 0c                	jmp    f0104728 <vprintfmt+0x24b>
f010471c:	89 75 08             	mov    %esi,0x8(%ebp)
f010471f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104722:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104725:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104728:	83 c7 01             	add    $0x1,%edi
f010472b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010472f:	0f be d0             	movsbl %al,%edx
f0104732:	85 d2                	test   %edx,%edx
f0104734:	74 23                	je     f0104759 <vprintfmt+0x27c>
f0104736:	85 f6                	test   %esi,%esi
f0104738:	78 a1                	js     f01046db <vprintfmt+0x1fe>
f010473a:	83 ee 01             	sub    $0x1,%esi
f010473d:	79 9c                	jns    f01046db <vprintfmt+0x1fe>
f010473f:	89 df                	mov    %ebx,%edi
f0104741:	8b 75 08             	mov    0x8(%ebp),%esi
f0104744:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104747:	eb 18                	jmp    f0104761 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104749:	83 ec 08             	sub    $0x8,%esp
f010474c:	53                   	push   %ebx
f010474d:	6a 20                	push   $0x20
f010474f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104751:	83 ef 01             	sub    $0x1,%edi
f0104754:	83 c4 10             	add    $0x10,%esp
f0104757:	eb 08                	jmp    f0104761 <vprintfmt+0x284>
f0104759:	89 df                	mov    %ebx,%edi
f010475b:	8b 75 08             	mov    0x8(%ebp),%esi
f010475e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104761:	85 ff                	test   %edi,%edi
f0104763:	7f e4                	jg     f0104749 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104765:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104768:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010476b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010476e:	e9 90 fd ff ff       	jmp    f0104503 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104773:	83 f9 01             	cmp    $0x1,%ecx
f0104776:	7e 19                	jle    f0104791 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0104778:	8b 45 14             	mov    0x14(%ebp),%eax
f010477b:	8b 50 04             	mov    0x4(%eax),%edx
f010477e:	8b 00                	mov    (%eax),%eax
f0104780:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104783:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104786:	8b 45 14             	mov    0x14(%ebp),%eax
f0104789:	8d 40 08             	lea    0x8(%eax),%eax
f010478c:	89 45 14             	mov    %eax,0x14(%ebp)
f010478f:	eb 38                	jmp    f01047c9 <vprintfmt+0x2ec>
	else if (lflag)
f0104791:	85 c9                	test   %ecx,%ecx
f0104793:	74 1b                	je     f01047b0 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0104795:	8b 45 14             	mov    0x14(%ebp),%eax
f0104798:	8b 00                	mov    (%eax),%eax
f010479a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010479d:	89 c1                	mov    %eax,%ecx
f010479f:	c1 f9 1f             	sar    $0x1f,%ecx
f01047a2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01047a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01047a8:	8d 40 04             	lea    0x4(%eax),%eax
f01047ab:	89 45 14             	mov    %eax,0x14(%ebp)
f01047ae:	eb 19                	jmp    f01047c9 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01047b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01047b3:	8b 00                	mov    (%eax),%eax
f01047b5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01047b8:	89 c1                	mov    %eax,%ecx
f01047ba:	c1 f9 1f             	sar    $0x1f,%ecx
f01047bd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01047c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c3:	8d 40 04             	lea    0x4(%eax),%eax
f01047c6:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01047c9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01047cc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01047cf:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01047d4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01047d8:	0f 89 0e 01 00 00    	jns    f01048ec <vprintfmt+0x40f>
				putch('-', putdat);
f01047de:	83 ec 08             	sub    $0x8,%esp
f01047e1:	53                   	push   %ebx
f01047e2:	6a 2d                	push   $0x2d
f01047e4:	ff d6                	call   *%esi
				num = -(long long) num;
f01047e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01047e9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01047ec:	f7 da                	neg    %edx
f01047ee:	83 d1 00             	adc    $0x0,%ecx
f01047f1:	f7 d9                	neg    %ecx
f01047f3:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01047f6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01047fb:	e9 ec 00 00 00       	jmp    f01048ec <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104800:	83 f9 01             	cmp    $0x1,%ecx
f0104803:	7e 18                	jle    f010481d <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0104805:	8b 45 14             	mov    0x14(%ebp),%eax
f0104808:	8b 10                	mov    (%eax),%edx
f010480a:	8b 48 04             	mov    0x4(%eax),%ecx
f010480d:	8d 40 08             	lea    0x8(%eax),%eax
f0104810:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104813:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104818:	e9 cf 00 00 00       	jmp    f01048ec <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010481d:	85 c9                	test   %ecx,%ecx
f010481f:	74 1a                	je     f010483b <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0104821:	8b 45 14             	mov    0x14(%ebp),%eax
f0104824:	8b 10                	mov    (%eax),%edx
f0104826:	b9 00 00 00 00       	mov    $0x0,%ecx
f010482b:	8d 40 04             	lea    0x4(%eax),%eax
f010482e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104831:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104836:	e9 b1 00 00 00       	jmp    f01048ec <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010483b:	8b 45 14             	mov    0x14(%ebp),%eax
f010483e:	8b 10                	mov    (%eax),%edx
f0104840:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104845:	8d 40 04             	lea    0x4(%eax),%eax
f0104848:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010484b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104850:	e9 97 00 00 00       	jmp    f01048ec <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0104855:	83 ec 08             	sub    $0x8,%esp
f0104858:	53                   	push   %ebx
f0104859:	6a 58                	push   $0x58
f010485b:	ff d6                	call   *%esi
			putch('X', putdat);
f010485d:	83 c4 08             	add    $0x8,%esp
f0104860:	53                   	push   %ebx
f0104861:	6a 58                	push   $0x58
f0104863:	ff d6                	call   *%esi
			putch('X', putdat);
f0104865:	83 c4 08             	add    $0x8,%esp
f0104868:	53                   	push   %ebx
f0104869:	6a 58                	push   $0x58
f010486b:	ff d6                	call   *%esi
			break;
f010486d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104870:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0104873:	e9 8b fc ff ff       	jmp    f0104503 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0104878:	83 ec 08             	sub    $0x8,%esp
f010487b:	53                   	push   %ebx
f010487c:	6a 30                	push   $0x30
f010487e:	ff d6                	call   *%esi
			putch('x', putdat);
f0104880:	83 c4 08             	add    $0x8,%esp
f0104883:	53                   	push   %ebx
f0104884:	6a 78                	push   $0x78
f0104886:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104888:	8b 45 14             	mov    0x14(%ebp),%eax
f010488b:	8b 10                	mov    (%eax),%edx
f010488d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104892:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104895:	8d 40 04             	lea    0x4(%eax),%eax
f0104898:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010489b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01048a0:	eb 4a                	jmp    f01048ec <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048a2:	83 f9 01             	cmp    $0x1,%ecx
f01048a5:	7e 15                	jle    f01048bc <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01048a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01048aa:	8b 10                	mov    (%eax),%edx
f01048ac:	8b 48 04             	mov    0x4(%eax),%ecx
f01048af:	8d 40 08             	lea    0x8(%eax),%eax
f01048b2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01048b5:	b8 10 00 00 00       	mov    $0x10,%eax
f01048ba:	eb 30                	jmp    f01048ec <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01048bc:	85 c9                	test   %ecx,%ecx
f01048be:	74 17                	je     f01048d7 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01048c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01048c3:	8b 10                	mov    (%eax),%edx
f01048c5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01048ca:	8d 40 04             	lea    0x4(%eax),%eax
f01048cd:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01048d0:	b8 10 00 00 00       	mov    $0x10,%eax
f01048d5:	eb 15                	jmp    f01048ec <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01048d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01048da:	8b 10                	mov    (%eax),%edx
f01048dc:	b9 00 00 00 00       	mov    $0x0,%ecx
f01048e1:	8d 40 04             	lea    0x4(%eax),%eax
f01048e4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01048e7:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01048ec:	83 ec 0c             	sub    $0xc,%esp
f01048ef:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01048f3:	57                   	push   %edi
f01048f4:	ff 75 e0             	pushl  -0x20(%ebp)
f01048f7:	50                   	push   %eax
f01048f8:	51                   	push   %ecx
f01048f9:	52                   	push   %edx
f01048fa:	89 da                	mov    %ebx,%edx
f01048fc:	89 f0                	mov    %esi,%eax
f01048fe:	e8 f1 fa ff ff       	call   f01043f4 <printnum>
			break;
f0104903:	83 c4 20             	add    $0x20,%esp
f0104906:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104909:	e9 f5 fb ff ff       	jmp    f0104503 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010490e:	83 ec 08             	sub    $0x8,%esp
f0104911:	53                   	push   %ebx
f0104912:	52                   	push   %edx
f0104913:	ff d6                	call   *%esi
			break;
f0104915:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104918:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010491b:	e9 e3 fb ff ff       	jmp    f0104503 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104920:	83 ec 08             	sub    $0x8,%esp
f0104923:	53                   	push   %ebx
f0104924:	6a 25                	push   $0x25
f0104926:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104928:	83 c4 10             	add    $0x10,%esp
f010492b:	eb 03                	jmp    f0104930 <vprintfmt+0x453>
f010492d:	83 ef 01             	sub    $0x1,%edi
f0104930:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104934:	75 f7                	jne    f010492d <vprintfmt+0x450>
f0104936:	e9 c8 fb ff ff       	jmp    f0104503 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010493b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010493e:	5b                   	pop    %ebx
f010493f:	5e                   	pop    %esi
f0104940:	5f                   	pop    %edi
f0104941:	5d                   	pop    %ebp
f0104942:	c3                   	ret    

f0104943 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104943:	55                   	push   %ebp
f0104944:	89 e5                	mov    %esp,%ebp
f0104946:	83 ec 18             	sub    $0x18,%esp
f0104949:	8b 45 08             	mov    0x8(%ebp),%eax
f010494c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010494f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104952:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104956:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104959:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104960:	85 c0                	test   %eax,%eax
f0104962:	74 26                	je     f010498a <vsnprintf+0x47>
f0104964:	85 d2                	test   %edx,%edx
f0104966:	7e 22                	jle    f010498a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104968:	ff 75 14             	pushl  0x14(%ebp)
f010496b:	ff 75 10             	pushl  0x10(%ebp)
f010496e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104971:	50                   	push   %eax
f0104972:	68 a3 44 10 f0       	push   $0xf01044a3
f0104977:	e8 61 fb ff ff       	call   f01044dd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010497c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010497f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104982:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104985:	83 c4 10             	add    $0x10,%esp
f0104988:	eb 05                	jmp    f010498f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010498a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010498f:	c9                   	leave  
f0104990:	c3                   	ret    

f0104991 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104991:	55                   	push   %ebp
f0104992:	89 e5                	mov    %esp,%ebp
f0104994:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104997:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010499a:	50                   	push   %eax
f010499b:	ff 75 10             	pushl  0x10(%ebp)
f010499e:	ff 75 0c             	pushl  0xc(%ebp)
f01049a1:	ff 75 08             	pushl  0x8(%ebp)
f01049a4:	e8 9a ff ff ff       	call   f0104943 <vsnprintf>
	va_end(ap);

	return rc;
}
f01049a9:	c9                   	leave  
f01049aa:	c3                   	ret    

f01049ab <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01049ab:	55                   	push   %ebp
f01049ac:	89 e5                	mov    %esp,%ebp
f01049ae:	57                   	push   %edi
f01049af:	56                   	push   %esi
f01049b0:	53                   	push   %ebx
f01049b1:	83 ec 0c             	sub    $0xc,%esp
f01049b4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01049b7:	85 c0                	test   %eax,%eax
f01049b9:	74 11                	je     f01049cc <readline+0x21>
		cprintf("%s", prompt);
f01049bb:	83 ec 08             	sub    $0x8,%esp
f01049be:	50                   	push   %eax
f01049bf:	68 81 67 10 f0       	push   $0xf0106781
f01049c4:	e8 f2 eb ff ff       	call   f01035bb <cprintf>
f01049c9:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01049cc:	83 ec 0c             	sub    $0xc,%esp
f01049cf:	6a 00                	push   $0x0
f01049d1:	e8 cd bd ff ff       	call   f01007a3 <iscons>
f01049d6:	89 c7                	mov    %eax,%edi
f01049d8:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01049db:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01049e0:	e8 ad bd ff ff       	call   f0100792 <getchar>
f01049e5:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01049e7:	85 c0                	test   %eax,%eax
f01049e9:	79 18                	jns    f0104a03 <readline+0x58>
			cprintf("read error: %e\n", c);
f01049eb:	83 ec 08             	sub    $0x8,%esp
f01049ee:	50                   	push   %eax
f01049ef:	68 c4 6f 10 f0       	push   $0xf0106fc4
f01049f4:	e8 c2 eb ff ff       	call   f01035bb <cprintf>
			return NULL;
f01049f9:	83 c4 10             	add    $0x10,%esp
f01049fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a01:	eb 79                	jmp    f0104a7c <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104a03:	83 f8 08             	cmp    $0x8,%eax
f0104a06:	0f 94 c2             	sete   %dl
f0104a09:	83 f8 7f             	cmp    $0x7f,%eax
f0104a0c:	0f 94 c0             	sete   %al
f0104a0f:	08 c2                	or     %al,%dl
f0104a11:	74 1a                	je     f0104a2d <readline+0x82>
f0104a13:	85 f6                	test   %esi,%esi
f0104a15:	7e 16                	jle    f0104a2d <readline+0x82>
			if (echoing)
f0104a17:	85 ff                	test   %edi,%edi
f0104a19:	74 0d                	je     f0104a28 <readline+0x7d>
				cputchar('\b');
f0104a1b:	83 ec 0c             	sub    $0xc,%esp
f0104a1e:	6a 08                	push   $0x8
f0104a20:	e8 5d bd ff ff       	call   f0100782 <cputchar>
f0104a25:	83 c4 10             	add    $0x10,%esp
			i--;
f0104a28:	83 ee 01             	sub    $0x1,%esi
f0104a2b:	eb b3                	jmp    f01049e0 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104a2d:	83 fb 1f             	cmp    $0x1f,%ebx
f0104a30:	7e 23                	jle    f0104a55 <readline+0xaa>
f0104a32:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104a38:	7f 1b                	jg     f0104a55 <readline+0xaa>
			if (echoing)
f0104a3a:	85 ff                	test   %edi,%edi
f0104a3c:	74 0c                	je     f0104a4a <readline+0x9f>
				cputchar(c);
f0104a3e:	83 ec 0c             	sub    $0xc,%esp
f0104a41:	53                   	push   %ebx
f0104a42:	e8 3b bd ff ff       	call   f0100782 <cputchar>
f0104a47:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104a4a:	88 9e 80 9a 22 f0    	mov    %bl,-0xfdd6580(%esi)
f0104a50:	8d 76 01             	lea    0x1(%esi),%esi
f0104a53:	eb 8b                	jmp    f01049e0 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104a55:	83 fb 0a             	cmp    $0xa,%ebx
f0104a58:	74 05                	je     f0104a5f <readline+0xb4>
f0104a5a:	83 fb 0d             	cmp    $0xd,%ebx
f0104a5d:	75 81                	jne    f01049e0 <readline+0x35>
			if (echoing)
f0104a5f:	85 ff                	test   %edi,%edi
f0104a61:	74 0d                	je     f0104a70 <readline+0xc5>
				cputchar('\n');
f0104a63:	83 ec 0c             	sub    $0xc,%esp
f0104a66:	6a 0a                	push   $0xa
f0104a68:	e8 15 bd ff ff       	call   f0100782 <cputchar>
f0104a6d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104a70:	c6 86 80 9a 22 f0 00 	movb   $0x0,-0xfdd6580(%esi)
			return buf;
f0104a77:	b8 80 9a 22 f0       	mov    $0xf0229a80,%eax
		}
	}
}
f0104a7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a7f:	5b                   	pop    %ebx
f0104a80:	5e                   	pop    %esi
f0104a81:	5f                   	pop    %edi
f0104a82:	5d                   	pop    %ebp
f0104a83:	c3                   	ret    

f0104a84 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104a84:	55                   	push   %ebp
f0104a85:	89 e5                	mov    %esp,%ebp
f0104a87:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a8f:	eb 03                	jmp    f0104a94 <strlen+0x10>
		n++;
f0104a91:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a94:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104a98:	75 f7                	jne    f0104a91 <strlen+0xd>
		n++;
	return n;
}
f0104a9a:	5d                   	pop    %ebp
f0104a9b:	c3                   	ret    

f0104a9c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104a9c:	55                   	push   %ebp
f0104a9d:	89 e5                	mov    %esp,%ebp
f0104a9f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104aa5:	ba 00 00 00 00       	mov    $0x0,%edx
f0104aaa:	eb 03                	jmp    f0104aaf <strnlen+0x13>
		n++;
f0104aac:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104aaf:	39 c2                	cmp    %eax,%edx
f0104ab1:	74 08                	je     f0104abb <strnlen+0x1f>
f0104ab3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104ab7:	75 f3                	jne    f0104aac <strnlen+0x10>
f0104ab9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104abb:	5d                   	pop    %ebp
f0104abc:	c3                   	ret    

f0104abd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104abd:	55                   	push   %ebp
f0104abe:	89 e5                	mov    %esp,%ebp
f0104ac0:	53                   	push   %ebx
f0104ac1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ac4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104ac7:	89 c2                	mov    %eax,%edx
f0104ac9:	83 c2 01             	add    $0x1,%edx
f0104acc:	83 c1 01             	add    $0x1,%ecx
f0104acf:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104ad3:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104ad6:	84 db                	test   %bl,%bl
f0104ad8:	75 ef                	jne    f0104ac9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104ada:	5b                   	pop    %ebx
f0104adb:	5d                   	pop    %ebp
f0104adc:	c3                   	ret    

f0104add <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104add:	55                   	push   %ebp
f0104ade:	89 e5                	mov    %esp,%ebp
f0104ae0:	53                   	push   %ebx
f0104ae1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ae4:	53                   	push   %ebx
f0104ae5:	e8 9a ff ff ff       	call   f0104a84 <strlen>
f0104aea:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104aed:	ff 75 0c             	pushl  0xc(%ebp)
f0104af0:	01 d8                	add    %ebx,%eax
f0104af2:	50                   	push   %eax
f0104af3:	e8 c5 ff ff ff       	call   f0104abd <strcpy>
	return dst;
}
f0104af8:	89 d8                	mov    %ebx,%eax
f0104afa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104afd:	c9                   	leave  
f0104afe:	c3                   	ret    

f0104aff <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104aff:	55                   	push   %ebp
f0104b00:	89 e5                	mov    %esp,%ebp
f0104b02:	56                   	push   %esi
f0104b03:	53                   	push   %ebx
f0104b04:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b07:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b0a:	89 f3                	mov    %esi,%ebx
f0104b0c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b0f:	89 f2                	mov    %esi,%edx
f0104b11:	eb 0f                	jmp    f0104b22 <strncpy+0x23>
		*dst++ = *src;
f0104b13:	83 c2 01             	add    $0x1,%edx
f0104b16:	0f b6 01             	movzbl (%ecx),%eax
f0104b19:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104b1c:	80 39 01             	cmpb   $0x1,(%ecx)
f0104b1f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b22:	39 da                	cmp    %ebx,%edx
f0104b24:	75 ed                	jne    f0104b13 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104b26:	89 f0                	mov    %esi,%eax
f0104b28:	5b                   	pop    %ebx
f0104b29:	5e                   	pop    %esi
f0104b2a:	5d                   	pop    %ebp
f0104b2b:	c3                   	ret    

f0104b2c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104b2c:	55                   	push   %ebp
f0104b2d:	89 e5                	mov    %esp,%ebp
f0104b2f:	56                   	push   %esi
f0104b30:	53                   	push   %ebx
f0104b31:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b34:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b37:	8b 55 10             	mov    0x10(%ebp),%edx
f0104b3a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b3c:	85 d2                	test   %edx,%edx
f0104b3e:	74 21                	je     f0104b61 <strlcpy+0x35>
f0104b40:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104b44:	89 f2                	mov    %esi,%edx
f0104b46:	eb 09                	jmp    f0104b51 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104b48:	83 c2 01             	add    $0x1,%edx
f0104b4b:	83 c1 01             	add    $0x1,%ecx
f0104b4e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b51:	39 c2                	cmp    %eax,%edx
f0104b53:	74 09                	je     f0104b5e <strlcpy+0x32>
f0104b55:	0f b6 19             	movzbl (%ecx),%ebx
f0104b58:	84 db                	test   %bl,%bl
f0104b5a:	75 ec                	jne    f0104b48 <strlcpy+0x1c>
f0104b5c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104b5e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104b61:	29 f0                	sub    %esi,%eax
}
f0104b63:	5b                   	pop    %ebx
f0104b64:	5e                   	pop    %esi
f0104b65:	5d                   	pop    %ebp
f0104b66:	c3                   	ret    

f0104b67 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104b67:	55                   	push   %ebp
f0104b68:	89 e5                	mov    %esp,%ebp
f0104b6a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b6d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104b70:	eb 06                	jmp    f0104b78 <strcmp+0x11>
		p++, q++;
f0104b72:	83 c1 01             	add    $0x1,%ecx
f0104b75:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104b78:	0f b6 01             	movzbl (%ecx),%eax
f0104b7b:	84 c0                	test   %al,%al
f0104b7d:	74 04                	je     f0104b83 <strcmp+0x1c>
f0104b7f:	3a 02                	cmp    (%edx),%al
f0104b81:	74 ef                	je     f0104b72 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b83:	0f b6 c0             	movzbl %al,%eax
f0104b86:	0f b6 12             	movzbl (%edx),%edx
f0104b89:	29 d0                	sub    %edx,%eax
}
f0104b8b:	5d                   	pop    %ebp
f0104b8c:	c3                   	ret    

f0104b8d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104b8d:	55                   	push   %ebp
f0104b8e:	89 e5                	mov    %esp,%ebp
f0104b90:	53                   	push   %ebx
f0104b91:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b94:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b97:	89 c3                	mov    %eax,%ebx
f0104b99:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104b9c:	eb 06                	jmp    f0104ba4 <strncmp+0x17>
		n--, p++, q++;
f0104b9e:	83 c0 01             	add    $0x1,%eax
f0104ba1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104ba4:	39 d8                	cmp    %ebx,%eax
f0104ba6:	74 15                	je     f0104bbd <strncmp+0x30>
f0104ba8:	0f b6 08             	movzbl (%eax),%ecx
f0104bab:	84 c9                	test   %cl,%cl
f0104bad:	74 04                	je     f0104bb3 <strncmp+0x26>
f0104baf:	3a 0a                	cmp    (%edx),%cl
f0104bb1:	74 eb                	je     f0104b9e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bb3:	0f b6 00             	movzbl (%eax),%eax
f0104bb6:	0f b6 12             	movzbl (%edx),%edx
f0104bb9:	29 d0                	sub    %edx,%eax
f0104bbb:	eb 05                	jmp    f0104bc2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104bbd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104bc2:	5b                   	pop    %ebx
f0104bc3:	5d                   	pop    %ebp
f0104bc4:	c3                   	ret    

f0104bc5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104bc5:	55                   	push   %ebp
f0104bc6:	89 e5                	mov    %esp,%ebp
f0104bc8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bcb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104bcf:	eb 07                	jmp    f0104bd8 <strchr+0x13>
		if (*s == c)
f0104bd1:	38 ca                	cmp    %cl,%dl
f0104bd3:	74 0f                	je     f0104be4 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104bd5:	83 c0 01             	add    $0x1,%eax
f0104bd8:	0f b6 10             	movzbl (%eax),%edx
f0104bdb:	84 d2                	test   %dl,%dl
f0104bdd:	75 f2                	jne    f0104bd1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104bdf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104be4:	5d                   	pop    %ebp
f0104be5:	c3                   	ret    

f0104be6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104be6:	55                   	push   %ebp
f0104be7:	89 e5                	mov    %esp,%ebp
f0104be9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104bf0:	eb 03                	jmp    f0104bf5 <strfind+0xf>
f0104bf2:	83 c0 01             	add    $0x1,%eax
f0104bf5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104bf8:	38 ca                	cmp    %cl,%dl
f0104bfa:	74 04                	je     f0104c00 <strfind+0x1a>
f0104bfc:	84 d2                	test   %dl,%dl
f0104bfe:	75 f2                	jne    f0104bf2 <strfind+0xc>
			break;
	return (char *) s;
}
f0104c00:	5d                   	pop    %ebp
f0104c01:	c3                   	ret    

f0104c02 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104c02:	55                   	push   %ebp
f0104c03:	89 e5                	mov    %esp,%ebp
f0104c05:	57                   	push   %edi
f0104c06:	56                   	push   %esi
f0104c07:	53                   	push   %ebx
f0104c08:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c0b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104c0e:	85 c9                	test   %ecx,%ecx
f0104c10:	74 36                	je     f0104c48 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104c12:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104c18:	75 28                	jne    f0104c42 <memset+0x40>
f0104c1a:	f6 c1 03             	test   $0x3,%cl
f0104c1d:	75 23                	jne    f0104c42 <memset+0x40>
		c &= 0xFF;
f0104c1f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104c23:	89 d3                	mov    %edx,%ebx
f0104c25:	c1 e3 08             	shl    $0x8,%ebx
f0104c28:	89 d6                	mov    %edx,%esi
f0104c2a:	c1 e6 18             	shl    $0x18,%esi
f0104c2d:	89 d0                	mov    %edx,%eax
f0104c2f:	c1 e0 10             	shl    $0x10,%eax
f0104c32:	09 f0                	or     %esi,%eax
f0104c34:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104c36:	89 d8                	mov    %ebx,%eax
f0104c38:	09 d0                	or     %edx,%eax
f0104c3a:	c1 e9 02             	shr    $0x2,%ecx
f0104c3d:	fc                   	cld    
f0104c3e:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c40:	eb 06                	jmp    f0104c48 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c42:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c45:	fc                   	cld    
f0104c46:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c48:	89 f8                	mov    %edi,%eax
f0104c4a:	5b                   	pop    %ebx
f0104c4b:	5e                   	pop    %esi
f0104c4c:	5f                   	pop    %edi
f0104c4d:	5d                   	pop    %ebp
f0104c4e:	c3                   	ret    

f0104c4f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c4f:	55                   	push   %ebp
f0104c50:	89 e5                	mov    %esp,%ebp
f0104c52:	57                   	push   %edi
f0104c53:	56                   	push   %esi
f0104c54:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c57:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104c5d:	39 c6                	cmp    %eax,%esi
f0104c5f:	73 35                	jae    f0104c96 <memmove+0x47>
f0104c61:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104c64:	39 d0                	cmp    %edx,%eax
f0104c66:	73 2e                	jae    f0104c96 <memmove+0x47>
		s += n;
		d += n;
f0104c68:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c6b:	89 d6                	mov    %edx,%esi
f0104c6d:	09 fe                	or     %edi,%esi
f0104c6f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104c75:	75 13                	jne    f0104c8a <memmove+0x3b>
f0104c77:	f6 c1 03             	test   $0x3,%cl
f0104c7a:	75 0e                	jne    f0104c8a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104c7c:	83 ef 04             	sub    $0x4,%edi
f0104c7f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104c82:	c1 e9 02             	shr    $0x2,%ecx
f0104c85:	fd                   	std    
f0104c86:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c88:	eb 09                	jmp    f0104c93 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104c8a:	83 ef 01             	sub    $0x1,%edi
f0104c8d:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104c90:	fd                   	std    
f0104c91:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104c93:	fc                   	cld    
f0104c94:	eb 1d                	jmp    f0104cb3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c96:	89 f2                	mov    %esi,%edx
f0104c98:	09 c2                	or     %eax,%edx
f0104c9a:	f6 c2 03             	test   $0x3,%dl
f0104c9d:	75 0f                	jne    f0104cae <memmove+0x5f>
f0104c9f:	f6 c1 03             	test   $0x3,%cl
f0104ca2:	75 0a                	jne    f0104cae <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104ca4:	c1 e9 02             	shr    $0x2,%ecx
f0104ca7:	89 c7                	mov    %eax,%edi
f0104ca9:	fc                   	cld    
f0104caa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104cac:	eb 05                	jmp    f0104cb3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104cae:	89 c7                	mov    %eax,%edi
f0104cb0:	fc                   	cld    
f0104cb1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104cb3:	5e                   	pop    %esi
f0104cb4:	5f                   	pop    %edi
f0104cb5:	5d                   	pop    %ebp
f0104cb6:	c3                   	ret    

f0104cb7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104cb7:	55                   	push   %ebp
f0104cb8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104cba:	ff 75 10             	pushl  0x10(%ebp)
f0104cbd:	ff 75 0c             	pushl  0xc(%ebp)
f0104cc0:	ff 75 08             	pushl  0x8(%ebp)
f0104cc3:	e8 87 ff ff ff       	call   f0104c4f <memmove>
}
f0104cc8:	c9                   	leave  
f0104cc9:	c3                   	ret    

f0104cca <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104cca:	55                   	push   %ebp
f0104ccb:	89 e5                	mov    %esp,%ebp
f0104ccd:	56                   	push   %esi
f0104cce:	53                   	push   %ebx
f0104ccf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cd2:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cd5:	89 c6                	mov    %eax,%esi
f0104cd7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104cda:	eb 1a                	jmp    f0104cf6 <memcmp+0x2c>
		if (*s1 != *s2)
f0104cdc:	0f b6 08             	movzbl (%eax),%ecx
f0104cdf:	0f b6 1a             	movzbl (%edx),%ebx
f0104ce2:	38 d9                	cmp    %bl,%cl
f0104ce4:	74 0a                	je     f0104cf0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104ce6:	0f b6 c1             	movzbl %cl,%eax
f0104ce9:	0f b6 db             	movzbl %bl,%ebx
f0104cec:	29 d8                	sub    %ebx,%eax
f0104cee:	eb 0f                	jmp    f0104cff <memcmp+0x35>
		s1++, s2++;
f0104cf0:	83 c0 01             	add    $0x1,%eax
f0104cf3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104cf6:	39 f0                	cmp    %esi,%eax
f0104cf8:	75 e2                	jne    f0104cdc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104cfa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cff:	5b                   	pop    %ebx
f0104d00:	5e                   	pop    %esi
f0104d01:	5d                   	pop    %ebp
f0104d02:	c3                   	ret    

f0104d03 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104d03:	55                   	push   %ebp
f0104d04:	89 e5                	mov    %esp,%ebp
f0104d06:	53                   	push   %ebx
f0104d07:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104d0a:	89 c1                	mov    %eax,%ecx
f0104d0c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d0f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d13:	eb 0a                	jmp    f0104d1f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d15:	0f b6 10             	movzbl (%eax),%edx
f0104d18:	39 da                	cmp    %ebx,%edx
f0104d1a:	74 07                	je     f0104d23 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d1c:	83 c0 01             	add    $0x1,%eax
f0104d1f:	39 c8                	cmp    %ecx,%eax
f0104d21:	72 f2                	jb     f0104d15 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104d23:	5b                   	pop    %ebx
f0104d24:	5d                   	pop    %ebp
f0104d25:	c3                   	ret    

f0104d26 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104d26:	55                   	push   %ebp
f0104d27:	89 e5                	mov    %esp,%ebp
f0104d29:	57                   	push   %edi
f0104d2a:	56                   	push   %esi
f0104d2b:	53                   	push   %ebx
f0104d2c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d2f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d32:	eb 03                	jmp    f0104d37 <strtol+0x11>
		s++;
f0104d34:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d37:	0f b6 01             	movzbl (%ecx),%eax
f0104d3a:	3c 20                	cmp    $0x20,%al
f0104d3c:	74 f6                	je     f0104d34 <strtol+0xe>
f0104d3e:	3c 09                	cmp    $0x9,%al
f0104d40:	74 f2                	je     f0104d34 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104d42:	3c 2b                	cmp    $0x2b,%al
f0104d44:	75 0a                	jne    f0104d50 <strtol+0x2a>
		s++;
f0104d46:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104d49:	bf 00 00 00 00       	mov    $0x0,%edi
f0104d4e:	eb 11                	jmp    f0104d61 <strtol+0x3b>
f0104d50:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104d55:	3c 2d                	cmp    $0x2d,%al
f0104d57:	75 08                	jne    f0104d61 <strtol+0x3b>
		s++, neg = 1;
f0104d59:	83 c1 01             	add    $0x1,%ecx
f0104d5c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104d61:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104d67:	75 15                	jne    f0104d7e <strtol+0x58>
f0104d69:	80 39 30             	cmpb   $0x30,(%ecx)
f0104d6c:	75 10                	jne    f0104d7e <strtol+0x58>
f0104d6e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104d72:	75 7c                	jne    f0104df0 <strtol+0xca>
		s += 2, base = 16;
f0104d74:	83 c1 02             	add    $0x2,%ecx
f0104d77:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104d7c:	eb 16                	jmp    f0104d94 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104d7e:	85 db                	test   %ebx,%ebx
f0104d80:	75 12                	jne    f0104d94 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104d82:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104d87:	80 39 30             	cmpb   $0x30,(%ecx)
f0104d8a:	75 08                	jne    f0104d94 <strtol+0x6e>
		s++, base = 8;
f0104d8c:	83 c1 01             	add    $0x1,%ecx
f0104d8f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104d94:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d99:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104d9c:	0f b6 11             	movzbl (%ecx),%edx
f0104d9f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104da2:	89 f3                	mov    %esi,%ebx
f0104da4:	80 fb 09             	cmp    $0x9,%bl
f0104da7:	77 08                	ja     f0104db1 <strtol+0x8b>
			dig = *s - '0';
f0104da9:	0f be d2             	movsbl %dl,%edx
f0104dac:	83 ea 30             	sub    $0x30,%edx
f0104daf:	eb 22                	jmp    f0104dd3 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104db1:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104db4:	89 f3                	mov    %esi,%ebx
f0104db6:	80 fb 19             	cmp    $0x19,%bl
f0104db9:	77 08                	ja     f0104dc3 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104dbb:	0f be d2             	movsbl %dl,%edx
f0104dbe:	83 ea 57             	sub    $0x57,%edx
f0104dc1:	eb 10                	jmp    f0104dd3 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104dc3:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104dc6:	89 f3                	mov    %esi,%ebx
f0104dc8:	80 fb 19             	cmp    $0x19,%bl
f0104dcb:	77 16                	ja     f0104de3 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104dcd:	0f be d2             	movsbl %dl,%edx
f0104dd0:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104dd3:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104dd6:	7d 0b                	jge    f0104de3 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104dd8:	83 c1 01             	add    $0x1,%ecx
f0104ddb:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ddf:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104de1:	eb b9                	jmp    f0104d9c <strtol+0x76>

	if (endptr)
f0104de3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104de7:	74 0d                	je     f0104df6 <strtol+0xd0>
		*endptr = (char *) s;
f0104de9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104dec:	89 0e                	mov    %ecx,(%esi)
f0104dee:	eb 06                	jmp    f0104df6 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104df0:	85 db                	test   %ebx,%ebx
f0104df2:	74 98                	je     f0104d8c <strtol+0x66>
f0104df4:	eb 9e                	jmp    f0104d94 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104df6:	89 c2                	mov    %eax,%edx
f0104df8:	f7 da                	neg    %edx
f0104dfa:	85 ff                	test   %edi,%edi
f0104dfc:	0f 45 c2             	cmovne %edx,%eax
}
f0104dff:	5b                   	pop    %ebx
f0104e00:	5e                   	pop    %esi
f0104e01:	5f                   	pop    %edi
f0104e02:	5d                   	pop    %ebp
f0104e03:	c3                   	ret    

f0104e04 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104e04:	fa                   	cli    

	xorw    %ax, %ax
f0104e05:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104e07:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104e09:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104e0b:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104e0d:	0f 01 16             	lgdtl  (%esi)
f0104e10:	74 70                	je     f0104e82 <mpsearch1+0x3>
	movl    %cr0, %eax
f0104e12:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104e15:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104e19:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104e1c:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104e22:	08 00                	or     %al,(%eax)

f0104e24 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104e24:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104e28:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104e2a:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104e2c:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104e2e:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104e32:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104e34:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104e36:	b8 00 c0 11 00       	mov    $0x11c000,%eax
	movl    %eax, %cr3
f0104e3b:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104e3e:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104e41:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104e46:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104e49:	8b 25 84 9e 22 f0    	mov    0xf0229e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104e4f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104e54:	b8 d1 01 10 f0       	mov    $0xf01001d1,%eax
	call    *%eax
f0104e59:	ff d0                	call   *%eax

f0104e5b <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104e5b:	eb fe                	jmp    f0104e5b <spin>
f0104e5d:	8d 76 00             	lea    0x0(%esi),%esi

f0104e60 <gdt>:
	...
f0104e68:	ff                   	(bad)  
f0104e69:	ff 00                	incl   (%eax)
f0104e6b:	00 00                	add    %al,(%eax)
f0104e6d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104e74:	00                   	.byte 0x0
f0104e75:	92                   	xchg   %eax,%edx
f0104e76:	cf                   	iret   
	...

f0104e78 <gdtdesc>:
f0104e78:	17                   	pop    %ss
f0104e79:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104e7e <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104e7e:	90                   	nop

f0104e7f <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104e7f:	55                   	push   %ebp
f0104e80:	89 e5                	mov    %esp,%ebp
f0104e82:	57                   	push   %edi
f0104e83:	56                   	push   %esi
f0104e84:	53                   	push   %ebx
f0104e85:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104e88:	8b 0d 88 9e 22 f0    	mov    0xf0229e88,%ecx
f0104e8e:	89 c3                	mov    %eax,%ebx
f0104e90:	c1 eb 0c             	shr    $0xc,%ebx
f0104e93:	39 cb                	cmp    %ecx,%ebx
f0104e95:	72 12                	jb     f0104ea9 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104e97:	50                   	push   %eax
f0104e98:	68 e4 58 10 f0       	push   $0xf01058e4
f0104e9d:	6a 57                	push   $0x57
f0104e9f:	68 61 71 10 f0       	push   $0xf0107161
f0104ea4:	e8 97 b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104ea9:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104eaf:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104eb1:	89 c2                	mov    %eax,%edx
f0104eb3:	c1 ea 0c             	shr    $0xc,%edx
f0104eb6:	39 ca                	cmp    %ecx,%edx
f0104eb8:	72 12                	jb     f0104ecc <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104eba:	50                   	push   %eax
f0104ebb:	68 e4 58 10 f0       	push   $0xf01058e4
f0104ec0:	6a 57                	push   $0x57
f0104ec2:	68 61 71 10 f0       	push   $0xf0107161
f0104ec7:	e8 74 b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104ecc:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104ed2:	eb 2f                	jmp    f0104f03 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104ed4:	83 ec 04             	sub    $0x4,%esp
f0104ed7:	6a 04                	push   $0x4
f0104ed9:	68 71 71 10 f0       	push   $0xf0107171
f0104ede:	53                   	push   %ebx
f0104edf:	e8 e6 fd ff ff       	call   f0104cca <memcmp>
f0104ee4:	83 c4 10             	add    $0x10,%esp
f0104ee7:	85 c0                	test   %eax,%eax
f0104ee9:	75 15                	jne    f0104f00 <mpsearch1+0x81>
f0104eeb:	89 da                	mov    %ebx,%edx
f0104eed:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104ef0:	0f b6 0a             	movzbl (%edx),%ecx
f0104ef3:	01 c8                	add    %ecx,%eax
f0104ef5:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104ef8:	39 d7                	cmp    %edx,%edi
f0104efa:	75 f4                	jne    f0104ef0 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104efc:	84 c0                	test   %al,%al
f0104efe:	74 0e                	je     f0104f0e <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104f00:	83 c3 10             	add    $0x10,%ebx
f0104f03:	39 f3                	cmp    %esi,%ebx
f0104f05:	72 cd                	jb     f0104ed4 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104f07:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f0c:	eb 02                	jmp    f0104f10 <mpsearch1+0x91>
f0104f0e:	89 d8                	mov    %ebx,%eax
}
f0104f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f13:	5b                   	pop    %ebx
f0104f14:	5e                   	pop    %esi
f0104f15:	5f                   	pop    %edi
f0104f16:	5d                   	pop    %ebp
f0104f17:	c3                   	ret    

f0104f18 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104f18:	55                   	push   %ebp
f0104f19:	89 e5                	mov    %esp,%ebp
f0104f1b:	57                   	push   %edi
f0104f1c:	56                   	push   %esi
f0104f1d:	53                   	push   %ebx
f0104f1e:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104f21:	c7 05 c0 a3 22 f0 20 	movl   $0xf022a020,0xf022a3c0
f0104f28:	a0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f2b:	83 3d 88 9e 22 f0 00 	cmpl   $0x0,0xf0229e88
f0104f32:	75 16                	jne    f0104f4a <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f34:	68 00 04 00 00       	push   $0x400
f0104f39:	68 e4 58 10 f0       	push   $0xf01058e4
f0104f3e:	6a 6f                	push   $0x6f
f0104f40:	68 61 71 10 f0       	push   $0xf0107161
f0104f45:	e8 f6 b0 ff ff       	call   f0100040 <_panic>

	static_assert(sizeof(*mp) == 16);

	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);
	cprintf("bda   %08x\n",bda);
f0104f4a:	83 ec 08             	sub    $0x8,%esp
f0104f4d:	68 00 04 00 f0       	push   $0xf0000400
f0104f52:	68 76 71 10 f0       	push   $0xf0107176
f0104f57:	e8 5f e6 ff ff       	call   f01035bb <cprintf>
	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0104f5c:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0104f63:	83 c4 10             	add    $0x10,%esp
f0104f66:	85 c0                	test   %eax,%eax
f0104f68:	74 16                	je     f0104f80 <mp_init+0x68>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0104f6a:	c1 e0 04             	shl    $0x4,%eax
f0104f6d:	ba 00 04 00 00       	mov    $0x400,%edx
f0104f72:	e8 08 ff ff ff       	call   f0104e7f <mpsearch1>
f0104f77:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f7a:	85 c0                	test   %eax,%eax
f0104f7c:	75 3c                	jne    f0104fba <mp_init+0xa2>
f0104f7e:	eb 20                	jmp    f0104fa0 <mp_init+0x88>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0104f80:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0104f87:	c1 e0 0a             	shl    $0xa,%eax
f0104f8a:	2d 00 04 00 00       	sub    $0x400,%eax
f0104f8f:	ba 00 04 00 00       	mov    $0x400,%edx
f0104f94:	e8 e6 fe ff ff       	call   f0104e7f <mpsearch1>
f0104f99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f9c:	85 c0                	test   %eax,%eax
f0104f9e:	75 1a                	jne    f0104fba <mp_init+0xa2>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0104fa0:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104fa5:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0104faa:	e8 d0 fe ff ff       	call   f0104e7f <mpsearch1>
f0104faf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0104fb2:	85 c0                	test   %eax,%eax
f0104fb4:	0f 84 5d 02 00 00    	je     f0105217 <mp_init+0x2ff>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0104fba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104fbd:	8b 70 04             	mov    0x4(%eax),%esi
f0104fc0:	85 f6                	test   %esi,%esi
f0104fc2:	74 06                	je     f0104fca <mp_init+0xb2>
f0104fc4:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0104fc8:	74 15                	je     f0104fdf <mp_init+0xc7>
		cprintf("SMP: Default configurations not implemented\n");
f0104fca:	83 ec 0c             	sub    $0xc,%esp
f0104fcd:	68 d4 6f 10 f0       	push   $0xf0106fd4
f0104fd2:	e8 e4 e5 ff ff       	call   f01035bb <cprintf>
f0104fd7:	83 c4 10             	add    $0x10,%esp
f0104fda:	e9 38 02 00 00       	jmp    f0105217 <mp_init+0x2ff>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fdf:	89 f0                	mov    %esi,%eax
f0104fe1:	c1 e8 0c             	shr    $0xc,%eax
f0104fe4:	3b 05 88 9e 22 f0    	cmp    0xf0229e88,%eax
f0104fea:	72 15                	jb     f0105001 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104fec:	56                   	push   %esi
f0104fed:	68 e4 58 10 f0       	push   $0xf01058e4
f0104ff2:	68 90 00 00 00       	push   $0x90
f0104ff7:	68 61 71 10 f0       	push   $0xf0107161
f0104ffc:	e8 3f b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105001:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105007:	83 ec 04             	sub    $0x4,%esp
f010500a:	6a 04                	push   $0x4
f010500c:	68 82 71 10 f0       	push   $0xf0107182
f0105011:	53                   	push   %ebx
f0105012:	e8 b3 fc ff ff       	call   f0104cca <memcmp>
f0105017:	83 c4 10             	add    $0x10,%esp
f010501a:	85 c0                	test   %eax,%eax
f010501c:	74 15                	je     f0105033 <mp_init+0x11b>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f010501e:	83 ec 0c             	sub    $0xc,%esp
f0105021:	68 04 70 10 f0       	push   $0xf0107004
f0105026:	e8 90 e5 ff ff       	call   f01035bb <cprintf>
f010502b:	83 c4 10             	add    $0x10,%esp
f010502e:	e9 e4 01 00 00       	jmp    f0105217 <mp_init+0x2ff>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105033:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105037:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010503b:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010503e:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105043:	b8 00 00 00 00       	mov    $0x0,%eax
f0105048:	eb 0d                	jmp    f0105057 <mp_init+0x13f>
		sum += ((uint8_t *)addr)[i];
f010504a:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105051:	f0 
f0105052:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105054:	83 c0 01             	add    $0x1,%eax
f0105057:	39 c7                	cmp    %eax,%edi
f0105059:	75 ef                	jne    f010504a <mp_init+0x132>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010505b:	84 d2                	test   %dl,%dl
f010505d:	74 15                	je     f0105074 <mp_init+0x15c>
		cprintf("SMP: Bad MP configuration checksum\n");
f010505f:	83 ec 0c             	sub    $0xc,%esp
f0105062:	68 38 70 10 f0       	push   $0xf0107038
f0105067:	e8 4f e5 ff ff       	call   f01035bb <cprintf>
f010506c:	83 c4 10             	add    $0x10,%esp
f010506f:	e9 a3 01 00 00       	jmp    f0105217 <mp_init+0x2ff>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105074:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105078:	3c 01                	cmp    $0x1,%al
f010507a:	74 1d                	je     f0105099 <mp_init+0x181>
f010507c:	3c 04                	cmp    $0x4,%al
f010507e:	74 19                	je     f0105099 <mp_init+0x181>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105080:	83 ec 08             	sub    $0x8,%esp
f0105083:	0f b6 c0             	movzbl %al,%eax
f0105086:	50                   	push   %eax
f0105087:	68 5c 70 10 f0       	push   $0xf010705c
f010508c:	e8 2a e5 ff ff       	call   f01035bb <cprintf>
f0105091:	83 c4 10             	add    $0x10,%esp
f0105094:	e9 7e 01 00 00       	jmp    f0105217 <mp_init+0x2ff>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105099:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010509d:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01050a1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01050a6:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01050ab:	01 ce                	add    %ecx,%esi
f01050ad:	eb 0d                	jmp    f01050bc <mp_init+0x1a4>
f01050af:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01050b6:	f0 
f01050b7:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01050b9:	83 c0 01             	add    $0x1,%eax
f01050bc:	39 c7                	cmp    %eax,%edi
f01050be:	75 ef                	jne    f01050af <mp_init+0x197>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01050c0:	89 d0                	mov    %edx,%eax
f01050c2:	02 43 2a             	add    0x2a(%ebx),%al
f01050c5:	74 15                	je     f01050dc <mp_init+0x1c4>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01050c7:	83 ec 0c             	sub    $0xc,%esp
f01050ca:	68 7c 70 10 f0       	push   $0xf010707c
f01050cf:	e8 e7 e4 ff ff       	call   f01035bb <cprintf>
f01050d4:	83 c4 10             	add    $0x10,%esp
f01050d7:	e9 3b 01 00 00       	jmp    f0105217 <mp_init+0x2ff>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01050dc:	85 db                	test   %ebx,%ebx
f01050de:	0f 84 33 01 00 00    	je     f0105217 <mp_init+0x2ff>
		return;
	ismp = 1;
f01050e4:	c7 05 00 a0 22 f0 01 	movl   $0x1,0xf022a000
f01050eb:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01050ee:	8b 43 24             	mov    0x24(%ebx),%eax
f01050f1:	a3 00 b0 26 f0       	mov    %eax,0xf026b000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01050f6:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01050f9:	be 00 00 00 00       	mov    $0x0,%esi
f01050fe:	e9 85 00 00 00       	jmp    f0105188 <mp_init+0x270>
		switch (*p) {
f0105103:	0f b6 07             	movzbl (%edi),%eax
f0105106:	84 c0                	test   %al,%al
f0105108:	74 06                	je     f0105110 <mp_init+0x1f8>
f010510a:	3c 04                	cmp    $0x4,%al
f010510c:	77 55                	ja     f0105163 <mp_init+0x24b>
f010510e:	eb 4e                	jmp    f010515e <mp_init+0x246>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105110:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105114:	74 11                	je     f0105127 <mp_init+0x20f>
				bootcpu = &cpus[ncpu];
f0105116:	6b 05 c4 a3 22 f0 74 	imul   $0x74,0xf022a3c4,%eax
f010511d:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f0105122:	a3 c0 a3 22 f0       	mov    %eax,0xf022a3c0
			if (ncpu < NCPU) {
f0105127:	a1 c4 a3 22 f0       	mov    0xf022a3c4,%eax
f010512c:	83 f8 07             	cmp    $0x7,%eax
f010512f:	7f 13                	jg     f0105144 <mp_init+0x22c>
				cpus[ncpu].cpu_id = ncpu;
f0105131:	6b d0 74             	imul   $0x74,%eax,%edx
f0105134:	88 82 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%edx)
				ncpu++;
f010513a:	83 c0 01             	add    $0x1,%eax
f010513d:	a3 c4 a3 22 f0       	mov    %eax,0xf022a3c4
f0105142:	eb 15                	jmp    f0105159 <mp_init+0x241>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105144:	83 ec 08             	sub    $0x8,%esp
f0105147:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010514b:	50                   	push   %eax
f010514c:	68 ac 70 10 f0       	push   $0xf01070ac
f0105151:	e8 65 e4 ff ff       	call   f01035bb <cprintf>
f0105156:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105159:	83 c7 14             	add    $0x14,%edi
			continue;
f010515c:	eb 27                	jmp    f0105185 <mp_init+0x26d>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010515e:	83 c7 08             	add    $0x8,%edi
			continue;
f0105161:	eb 22                	jmp    f0105185 <mp_init+0x26d>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105163:	83 ec 08             	sub    $0x8,%esp
f0105166:	0f b6 c0             	movzbl %al,%eax
f0105169:	50                   	push   %eax
f010516a:	68 d4 70 10 f0       	push   $0xf01070d4
f010516f:	e8 47 e4 ff ff       	call   f01035bb <cprintf>
			ismp = 0;
f0105174:	c7 05 00 a0 22 f0 00 	movl   $0x0,0xf022a000
f010517b:	00 00 00 
			i = conf->entry;
f010517e:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105182:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105185:	83 c6 01             	add    $0x1,%esi
f0105188:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010518c:	39 c6                	cmp    %eax,%esi
f010518e:	0f 82 6f ff ff ff    	jb     f0105103 <mp_init+0x1eb>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105194:	a1 c0 a3 22 f0       	mov    0xf022a3c0,%eax
f0105199:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01051a0:	83 3d 00 a0 22 f0 00 	cmpl   $0x0,0xf022a000
f01051a7:	75 26                	jne    f01051cf <mp_init+0x2b7>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01051a9:	c7 05 c4 a3 22 f0 01 	movl   $0x1,0xf022a3c4
f01051b0:	00 00 00 
		lapicaddr = 0;
f01051b3:	c7 05 00 b0 26 f0 00 	movl   $0x0,0xf026b000
f01051ba:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01051bd:	83 ec 0c             	sub    $0xc,%esp
f01051c0:	68 f4 70 10 f0       	push   $0xf01070f4
f01051c5:	e8 f1 e3 ff ff       	call   f01035bb <cprintf>
		return;
f01051ca:	83 c4 10             	add    $0x10,%esp
f01051cd:	eb 48                	jmp    f0105217 <mp_init+0x2ff>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01051cf:	83 ec 04             	sub    $0x4,%esp
f01051d2:	ff 35 c4 a3 22 f0    	pushl  0xf022a3c4
f01051d8:	0f b6 00             	movzbl (%eax),%eax
f01051db:	50                   	push   %eax
f01051dc:	68 87 71 10 f0       	push   $0xf0107187
f01051e1:	e8 d5 e3 ff ff       	call   f01035bb <cprintf>

	if (mp->imcrp) {
f01051e6:	83 c4 10             	add    $0x10,%esp
f01051e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051ec:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01051f0:	74 25                	je     f0105217 <mp_init+0x2ff>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01051f2:	83 ec 0c             	sub    $0xc,%esp
f01051f5:	68 20 71 10 f0       	push   $0xf0107120
f01051fa:	e8 bc e3 ff ff       	call   f01035bb <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01051ff:	ba 22 00 00 00       	mov    $0x22,%edx
f0105204:	b8 70 00 00 00       	mov    $0x70,%eax
f0105209:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010520a:	ba 23 00 00 00       	mov    $0x23,%edx
f010520f:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105210:	83 c8 01             	or     $0x1,%eax
f0105213:	ee                   	out    %al,(%dx)
f0105214:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105217:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010521a:	5b                   	pop    %ebx
f010521b:	5e                   	pop    %esi
f010521c:	5f                   	pop    %edi
f010521d:	5d                   	pop    %ebp
f010521e:	c3                   	ret    

f010521f <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f010521f:	55                   	push   %ebp
f0105220:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105222:	8b 0d 04 b0 26 f0    	mov    0xf026b004,%ecx
f0105228:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010522b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010522d:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f0105232:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105235:	5d                   	pop    %ebp
f0105236:	c3                   	ret    

f0105237 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105237:	55                   	push   %ebp
f0105238:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010523a:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f010523f:	85 c0                	test   %eax,%eax
f0105241:	74 08                	je     f010524b <cpunum+0x14>
		return lapic[ID] >> 24;
f0105243:	8b 40 20             	mov    0x20(%eax),%eax
f0105246:	c1 e8 18             	shr    $0x18,%eax
f0105249:	eb 05                	jmp    f0105250 <cpunum+0x19>
	return 0;
f010524b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105250:	5d                   	pop    %ebp
f0105251:	c3                   	ret    

f0105252 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105252:	a1 00 b0 26 f0       	mov    0xf026b000,%eax
f0105257:	85 c0                	test   %eax,%eax
f0105259:	0f 84 21 01 00 00    	je     f0105380 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010525f:	55                   	push   %ebp
f0105260:	89 e5                	mov    %esp,%ebp
f0105262:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105265:	68 00 10 00 00       	push   $0x1000
f010526a:	50                   	push   %eax
f010526b:	e8 59 bf ff ff       	call   f01011c9 <mmio_map_region>
f0105270:	a3 04 b0 26 f0       	mov    %eax,0xf026b004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105275:	ba 27 01 00 00       	mov    $0x127,%edx
f010527a:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010527f:	e8 9b ff ff ff       	call   f010521f <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105284:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105289:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010528e:	e8 8c ff ff ff       	call   f010521f <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105293:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105298:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010529d:	e8 7d ff ff ff       	call   f010521f <lapicw>
	lapicw(TICR, 10000000); 
f01052a2:	ba 80 96 98 00       	mov    $0x989680,%edx
f01052a7:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01052ac:	e8 6e ff ff ff       	call   f010521f <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01052b1:	e8 81 ff ff ff       	call   f0105237 <cpunum>
f01052b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01052b9:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f01052be:	83 c4 10             	add    $0x10,%esp
f01052c1:	39 05 c0 a3 22 f0    	cmp    %eax,0xf022a3c0
f01052c7:	74 0f                	je     f01052d8 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01052c9:	ba 00 00 01 00       	mov    $0x10000,%edx
f01052ce:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01052d3:	e8 47 ff ff ff       	call   f010521f <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01052d8:	ba 00 00 01 00       	mov    $0x10000,%edx
f01052dd:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01052e2:	e8 38 ff ff ff       	call   f010521f <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01052e7:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f01052ec:	8b 40 30             	mov    0x30(%eax),%eax
f01052ef:	c1 e8 10             	shr    $0x10,%eax
f01052f2:	3c 03                	cmp    $0x3,%al
f01052f4:	76 0f                	jbe    f0105305 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01052f6:	ba 00 00 01 00       	mov    $0x10000,%edx
f01052fb:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105300:	e8 1a ff ff ff       	call   f010521f <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105305:	ba 33 00 00 00       	mov    $0x33,%edx
f010530a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010530f:	e8 0b ff ff ff       	call   f010521f <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105314:	ba 00 00 00 00       	mov    $0x0,%edx
f0105319:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010531e:	e8 fc fe ff ff       	call   f010521f <lapicw>
	lapicw(ESR, 0);
f0105323:	ba 00 00 00 00       	mov    $0x0,%edx
f0105328:	b8 a0 00 00 00       	mov    $0xa0,%eax
f010532d:	e8 ed fe ff ff       	call   f010521f <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105332:	ba 00 00 00 00       	mov    $0x0,%edx
f0105337:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010533c:	e8 de fe ff ff       	call   f010521f <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105341:	ba 00 00 00 00       	mov    $0x0,%edx
f0105346:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010534b:	e8 cf fe ff ff       	call   f010521f <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105350:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105355:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010535a:	e8 c0 fe ff ff       	call   f010521f <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010535f:	8b 15 04 b0 26 f0    	mov    0xf026b004,%edx
f0105365:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010536b:	f6 c4 10             	test   $0x10,%ah
f010536e:	75 f5                	jne    f0105365 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105370:	ba 00 00 00 00       	mov    $0x0,%edx
f0105375:	b8 20 00 00 00       	mov    $0x20,%eax
f010537a:	e8 a0 fe ff ff       	call   f010521f <lapicw>
}
f010537f:	c9                   	leave  
f0105380:	f3 c3                	repz ret 

f0105382 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105382:	83 3d 04 b0 26 f0 00 	cmpl   $0x0,0xf026b004
f0105389:	74 13                	je     f010539e <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010538b:	55                   	push   %ebp
f010538c:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010538e:	ba 00 00 00 00       	mov    $0x0,%edx
f0105393:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105398:	e8 82 fe ff ff       	call   f010521f <lapicw>
}
f010539d:	5d                   	pop    %ebp
f010539e:	f3 c3                	repz ret 

f01053a0 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01053a0:	55                   	push   %ebp
f01053a1:	89 e5                	mov    %esp,%ebp
f01053a3:	56                   	push   %esi
f01053a4:	53                   	push   %ebx
f01053a5:	8b 75 08             	mov    0x8(%ebp),%esi
f01053a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053ab:	ba 70 00 00 00       	mov    $0x70,%edx
f01053b0:	b8 0f 00 00 00       	mov    $0xf,%eax
f01053b5:	ee                   	out    %al,(%dx)
f01053b6:	ba 71 00 00 00       	mov    $0x71,%edx
f01053bb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01053c0:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01053c1:	83 3d 88 9e 22 f0 00 	cmpl   $0x0,0xf0229e88
f01053c8:	75 19                	jne    f01053e3 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01053ca:	68 67 04 00 00       	push   $0x467
f01053cf:	68 e4 58 10 f0       	push   $0xf01058e4
f01053d4:	68 98 00 00 00       	push   $0x98
f01053d9:	68 a4 71 10 f0       	push   $0xf01071a4
f01053de:	e8 5d ac ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01053e3:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01053ea:	00 00 
	wrv[1] = addr >> 4;
f01053ec:	89 d8                	mov    %ebx,%eax
f01053ee:	c1 e8 04             	shr    $0x4,%eax
f01053f1:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01053f7:	c1 e6 18             	shl    $0x18,%esi
f01053fa:	89 f2                	mov    %esi,%edx
f01053fc:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105401:	e8 19 fe ff ff       	call   f010521f <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105406:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010540b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105410:	e8 0a fe ff ff       	call   f010521f <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105415:	ba 00 85 00 00       	mov    $0x8500,%edx
f010541a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010541f:	e8 fb fd ff ff       	call   f010521f <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105424:	c1 eb 0c             	shr    $0xc,%ebx
f0105427:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010542a:	89 f2                	mov    %esi,%edx
f010542c:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105431:	e8 e9 fd ff ff       	call   f010521f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105436:	89 da                	mov    %ebx,%edx
f0105438:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010543d:	e8 dd fd ff ff       	call   f010521f <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105442:	89 f2                	mov    %esi,%edx
f0105444:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105449:	e8 d1 fd ff ff       	call   f010521f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010544e:	89 da                	mov    %ebx,%edx
f0105450:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105455:	e8 c5 fd ff ff       	call   f010521f <lapicw>
		microdelay(200);
	}
}
f010545a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010545d:	5b                   	pop    %ebx
f010545e:	5e                   	pop    %esi
f010545f:	5d                   	pop    %ebp
f0105460:	c3                   	ret    

f0105461 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105461:	55                   	push   %ebp
f0105462:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105464:	8b 55 08             	mov    0x8(%ebp),%edx
f0105467:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010546d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105472:	e8 a8 fd ff ff       	call   f010521f <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105477:	8b 15 04 b0 26 f0    	mov    0xf026b004,%edx
f010547d:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105483:	f6 c4 10             	test   $0x10,%ah
f0105486:	75 f5                	jne    f010547d <lapic_ipi+0x1c>
		;
}
f0105488:	5d                   	pop    %ebp
f0105489:	c3                   	ret    

f010548a <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010548a:	55                   	push   %ebp
f010548b:	89 e5                	mov    %esp,%ebp
f010548d:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105490:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105496:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105499:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010549c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01054a3:	5d                   	pop    %ebp
f01054a4:	c3                   	ret    

f01054a5 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01054a5:	55                   	push   %ebp
f01054a6:	89 e5                	mov    %esp,%ebp
f01054a8:	56                   	push   %esi
f01054a9:	53                   	push   %ebx
f01054aa:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01054ad:	83 3b 00             	cmpl   $0x0,(%ebx)
f01054b0:	74 14                	je     f01054c6 <spin_lock+0x21>
f01054b2:	8b 73 08             	mov    0x8(%ebx),%esi
f01054b5:	e8 7d fd ff ff       	call   f0105237 <cpunum>
f01054ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01054bd:	05 20 a0 22 f0       	add    $0xf022a020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01054c2:	39 c6                	cmp    %eax,%esi
f01054c4:	74 07                	je     f01054cd <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f01054c6:	ba 01 00 00 00       	mov    $0x1,%edx
f01054cb:	eb 20                	jmp    f01054ed <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01054cd:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01054d0:	e8 62 fd ff ff       	call   f0105237 <cpunum>
f01054d5:	83 ec 0c             	sub    $0xc,%esp
f01054d8:	53                   	push   %ebx
f01054d9:	50                   	push   %eax
f01054da:	68 b4 71 10 f0       	push   $0xf01071b4
f01054df:	6a 41                	push   $0x41
f01054e1:	68 18 72 10 f0       	push   $0xf0107218
f01054e6:	e8 55 ab ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01054eb:	f3 90                	pause  
f01054ed:	89 d0                	mov    %edx,%eax
f01054ef:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01054f2:	85 c0                	test   %eax,%eax
f01054f4:	75 f5                	jne    f01054eb <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01054f6:	e8 3c fd ff ff       	call   f0105237 <cpunum>
f01054fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01054fe:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f0105503:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105506:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105509:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010550b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105510:	eb 0b                	jmp    f010551d <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105512:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105515:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105518:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010551a:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f010551d:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105523:	76 11                	jbe    f0105536 <spin_lock+0x91>
f0105525:	83 f8 09             	cmp    $0x9,%eax
f0105528:	7e e8                	jle    f0105512 <spin_lock+0x6d>
f010552a:	eb 0a                	jmp    f0105536 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010552c:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105533:	83 c0 01             	add    $0x1,%eax
f0105536:	83 f8 09             	cmp    $0x9,%eax
f0105539:	7e f1                	jle    f010552c <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010553b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010553e:	5b                   	pop    %ebx
f010553f:	5e                   	pop    %esi
f0105540:	5d                   	pop    %ebp
f0105541:	c3                   	ret    

f0105542 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105542:	55                   	push   %ebp
f0105543:	89 e5                	mov    %esp,%ebp
f0105545:	57                   	push   %edi
f0105546:	56                   	push   %esi
f0105547:	53                   	push   %ebx
f0105548:	83 ec 4c             	sub    $0x4c,%esp
f010554b:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010554e:	83 3e 00             	cmpl   $0x0,(%esi)
f0105551:	74 18                	je     f010556b <spin_unlock+0x29>
f0105553:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105556:	e8 dc fc ff ff       	call   f0105237 <cpunum>
f010555b:	6b c0 74             	imul   $0x74,%eax,%eax
f010555e:	05 20 a0 22 f0       	add    $0xf022a020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105563:	39 c3                	cmp    %eax,%ebx
f0105565:	0f 84 a5 00 00 00    	je     f0105610 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010556b:	83 ec 04             	sub    $0x4,%esp
f010556e:	6a 28                	push   $0x28
f0105570:	8d 46 0c             	lea    0xc(%esi),%eax
f0105573:	50                   	push   %eax
f0105574:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105577:	53                   	push   %ebx
f0105578:	e8 d2 f6 ff ff       	call   f0104c4f <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010557d:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105580:	0f b6 38             	movzbl (%eax),%edi
f0105583:	8b 76 04             	mov    0x4(%esi),%esi
f0105586:	e8 ac fc ff ff       	call   f0105237 <cpunum>
f010558b:	57                   	push   %edi
f010558c:	56                   	push   %esi
f010558d:	50                   	push   %eax
f010558e:	68 e0 71 10 f0       	push   $0xf01071e0
f0105593:	e8 23 e0 ff ff       	call   f01035bb <cprintf>
f0105598:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010559b:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010559e:	eb 54                	jmp    f01055f4 <spin_unlock+0xb2>
f01055a0:	83 ec 08             	sub    $0x8,%esp
f01055a3:	57                   	push   %edi
f01055a4:	50                   	push   %eax
f01055a5:	e8 d8 eb ff ff       	call   f0104182 <debuginfo_eip>
f01055aa:	83 c4 10             	add    $0x10,%esp
f01055ad:	85 c0                	test   %eax,%eax
f01055af:	78 27                	js     f01055d8 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01055b1:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01055b3:	83 ec 04             	sub    $0x4,%esp
f01055b6:	89 c2                	mov    %eax,%edx
f01055b8:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01055bb:	52                   	push   %edx
f01055bc:	ff 75 b0             	pushl  -0x50(%ebp)
f01055bf:	ff 75 b4             	pushl  -0x4c(%ebp)
f01055c2:	ff 75 ac             	pushl  -0x54(%ebp)
f01055c5:	ff 75 a8             	pushl  -0x58(%ebp)
f01055c8:	50                   	push   %eax
f01055c9:	68 28 72 10 f0       	push   $0xf0107228
f01055ce:	e8 e8 df ff ff       	call   f01035bb <cprintf>
f01055d3:	83 c4 20             	add    $0x20,%esp
f01055d6:	eb 12                	jmp    f01055ea <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01055d8:	83 ec 08             	sub    $0x8,%esp
f01055db:	ff 36                	pushl  (%esi)
f01055dd:	68 7a 71 10 f0       	push   $0xf010717a
f01055e2:	e8 d4 df ff ff       	call   f01035bb <cprintf>
f01055e7:	83 c4 10             	add    $0x10,%esp
f01055ea:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01055ed:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01055f0:	39 c3                	cmp    %eax,%ebx
f01055f2:	74 08                	je     f01055fc <spin_unlock+0xba>
f01055f4:	89 de                	mov    %ebx,%esi
f01055f6:	8b 03                	mov    (%ebx),%eax
f01055f8:	85 c0                	test   %eax,%eax
f01055fa:	75 a4                	jne    f01055a0 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01055fc:	83 ec 04             	sub    $0x4,%esp
f01055ff:	68 3f 72 10 f0       	push   $0xf010723f
f0105604:	6a 67                	push   $0x67
f0105606:	68 18 72 10 f0       	push   $0xf0107218
f010560b:	e8 30 aa ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105610:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105617:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010561e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105623:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105626:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105629:	5b                   	pop    %ebx
f010562a:	5e                   	pop    %esi
f010562b:	5f                   	pop    %edi
f010562c:	5d                   	pop    %ebp
f010562d:	c3                   	ret    
f010562e:	66 90                	xchg   %ax,%ax

f0105630 <__udivdi3>:
f0105630:	55                   	push   %ebp
f0105631:	57                   	push   %edi
f0105632:	56                   	push   %esi
f0105633:	53                   	push   %ebx
f0105634:	83 ec 1c             	sub    $0x1c,%esp
f0105637:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010563b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010563f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105643:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105647:	85 f6                	test   %esi,%esi
f0105649:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010564d:	89 ca                	mov    %ecx,%edx
f010564f:	89 f8                	mov    %edi,%eax
f0105651:	75 3d                	jne    f0105690 <__udivdi3+0x60>
f0105653:	39 cf                	cmp    %ecx,%edi
f0105655:	0f 87 c5 00 00 00    	ja     f0105720 <__udivdi3+0xf0>
f010565b:	85 ff                	test   %edi,%edi
f010565d:	89 fd                	mov    %edi,%ebp
f010565f:	75 0b                	jne    f010566c <__udivdi3+0x3c>
f0105661:	b8 01 00 00 00       	mov    $0x1,%eax
f0105666:	31 d2                	xor    %edx,%edx
f0105668:	f7 f7                	div    %edi
f010566a:	89 c5                	mov    %eax,%ebp
f010566c:	89 c8                	mov    %ecx,%eax
f010566e:	31 d2                	xor    %edx,%edx
f0105670:	f7 f5                	div    %ebp
f0105672:	89 c1                	mov    %eax,%ecx
f0105674:	89 d8                	mov    %ebx,%eax
f0105676:	89 cf                	mov    %ecx,%edi
f0105678:	f7 f5                	div    %ebp
f010567a:	89 c3                	mov    %eax,%ebx
f010567c:	89 d8                	mov    %ebx,%eax
f010567e:	89 fa                	mov    %edi,%edx
f0105680:	83 c4 1c             	add    $0x1c,%esp
f0105683:	5b                   	pop    %ebx
f0105684:	5e                   	pop    %esi
f0105685:	5f                   	pop    %edi
f0105686:	5d                   	pop    %ebp
f0105687:	c3                   	ret    
f0105688:	90                   	nop
f0105689:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105690:	39 ce                	cmp    %ecx,%esi
f0105692:	77 74                	ja     f0105708 <__udivdi3+0xd8>
f0105694:	0f bd fe             	bsr    %esi,%edi
f0105697:	83 f7 1f             	xor    $0x1f,%edi
f010569a:	0f 84 98 00 00 00    	je     f0105738 <__udivdi3+0x108>
f01056a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01056a5:	89 f9                	mov    %edi,%ecx
f01056a7:	89 c5                	mov    %eax,%ebp
f01056a9:	29 fb                	sub    %edi,%ebx
f01056ab:	d3 e6                	shl    %cl,%esi
f01056ad:	89 d9                	mov    %ebx,%ecx
f01056af:	d3 ed                	shr    %cl,%ebp
f01056b1:	89 f9                	mov    %edi,%ecx
f01056b3:	d3 e0                	shl    %cl,%eax
f01056b5:	09 ee                	or     %ebp,%esi
f01056b7:	89 d9                	mov    %ebx,%ecx
f01056b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01056bd:	89 d5                	mov    %edx,%ebp
f01056bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01056c3:	d3 ed                	shr    %cl,%ebp
f01056c5:	89 f9                	mov    %edi,%ecx
f01056c7:	d3 e2                	shl    %cl,%edx
f01056c9:	89 d9                	mov    %ebx,%ecx
f01056cb:	d3 e8                	shr    %cl,%eax
f01056cd:	09 c2                	or     %eax,%edx
f01056cf:	89 d0                	mov    %edx,%eax
f01056d1:	89 ea                	mov    %ebp,%edx
f01056d3:	f7 f6                	div    %esi
f01056d5:	89 d5                	mov    %edx,%ebp
f01056d7:	89 c3                	mov    %eax,%ebx
f01056d9:	f7 64 24 0c          	mull   0xc(%esp)
f01056dd:	39 d5                	cmp    %edx,%ebp
f01056df:	72 10                	jb     f01056f1 <__udivdi3+0xc1>
f01056e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01056e5:	89 f9                	mov    %edi,%ecx
f01056e7:	d3 e6                	shl    %cl,%esi
f01056e9:	39 c6                	cmp    %eax,%esi
f01056eb:	73 07                	jae    f01056f4 <__udivdi3+0xc4>
f01056ed:	39 d5                	cmp    %edx,%ebp
f01056ef:	75 03                	jne    f01056f4 <__udivdi3+0xc4>
f01056f1:	83 eb 01             	sub    $0x1,%ebx
f01056f4:	31 ff                	xor    %edi,%edi
f01056f6:	89 d8                	mov    %ebx,%eax
f01056f8:	89 fa                	mov    %edi,%edx
f01056fa:	83 c4 1c             	add    $0x1c,%esp
f01056fd:	5b                   	pop    %ebx
f01056fe:	5e                   	pop    %esi
f01056ff:	5f                   	pop    %edi
f0105700:	5d                   	pop    %ebp
f0105701:	c3                   	ret    
f0105702:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105708:	31 ff                	xor    %edi,%edi
f010570a:	31 db                	xor    %ebx,%ebx
f010570c:	89 d8                	mov    %ebx,%eax
f010570e:	89 fa                	mov    %edi,%edx
f0105710:	83 c4 1c             	add    $0x1c,%esp
f0105713:	5b                   	pop    %ebx
f0105714:	5e                   	pop    %esi
f0105715:	5f                   	pop    %edi
f0105716:	5d                   	pop    %ebp
f0105717:	c3                   	ret    
f0105718:	90                   	nop
f0105719:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105720:	89 d8                	mov    %ebx,%eax
f0105722:	f7 f7                	div    %edi
f0105724:	31 ff                	xor    %edi,%edi
f0105726:	89 c3                	mov    %eax,%ebx
f0105728:	89 d8                	mov    %ebx,%eax
f010572a:	89 fa                	mov    %edi,%edx
f010572c:	83 c4 1c             	add    $0x1c,%esp
f010572f:	5b                   	pop    %ebx
f0105730:	5e                   	pop    %esi
f0105731:	5f                   	pop    %edi
f0105732:	5d                   	pop    %ebp
f0105733:	c3                   	ret    
f0105734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105738:	39 ce                	cmp    %ecx,%esi
f010573a:	72 0c                	jb     f0105748 <__udivdi3+0x118>
f010573c:	31 db                	xor    %ebx,%ebx
f010573e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105742:	0f 87 34 ff ff ff    	ja     f010567c <__udivdi3+0x4c>
f0105748:	bb 01 00 00 00       	mov    $0x1,%ebx
f010574d:	e9 2a ff ff ff       	jmp    f010567c <__udivdi3+0x4c>
f0105752:	66 90                	xchg   %ax,%ax
f0105754:	66 90                	xchg   %ax,%ax
f0105756:	66 90                	xchg   %ax,%ax
f0105758:	66 90                	xchg   %ax,%ax
f010575a:	66 90                	xchg   %ax,%ax
f010575c:	66 90                	xchg   %ax,%ax
f010575e:	66 90                	xchg   %ax,%ax

f0105760 <__umoddi3>:
f0105760:	55                   	push   %ebp
f0105761:	57                   	push   %edi
f0105762:	56                   	push   %esi
f0105763:	53                   	push   %ebx
f0105764:	83 ec 1c             	sub    $0x1c,%esp
f0105767:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010576b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010576f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105773:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105777:	85 d2                	test   %edx,%edx
f0105779:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010577d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105781:	89 f3                	mov    %esi,%ebx
f0105783:	89 3c 24             	mov    %edi,(%esp)
f0105786:	89 74 24 04          	mov    %esi,0x4(%esp)
f010578a:	75 1c                	jne    f01057a8 <__umoddi3+0x48>
f010578c:	39 f7                	cmp    %esi,%edi
f010578e:	76 50                	jbe    f01057e0 <__umoddi3+0x80>
f0105790:	89 c8                	mov    %ecx,%eax
f0105792:	89 f2                	mov    %esi,%edx
f0105794:	f7 f7                	div    %edi
f0105796:	89 d0                	mov    %edx,%eax
f0105798:	31 d2                	xor    %edx,%edx
f010579a:	83 c4 1c             	add    $0x1c,%esp
f010579d:	5b                   	pop    %ebx
f010579e:	5e                   	pop    %esi
f010579f:	5f                   	pop    %edi
f01057a0:	5d                   	pop    %ebp
f01057a1:	c3                   	ret    
f01057a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01057a8:	39 f2                	cmp    %esi,%edx
f01057aa:	89 d0                	mov    %edx,%eax
f01057ac:	77 52                	ja     f0105800 <__umoddi3+0xa0>
f01057ae:	0f bd ea             	bsr    %edx,%ebp
f01057b1:	83 f5 1f             	xor    $0x1f,%ebp
f01057b4:	75 5a                	jne    f0105810 <__umoddi3+0xb0>
f01057b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01057ba:	0f 82 e0 00 00 00    	jb     f01058a0 <__umoddi3+0x140>
f01057c0:	39 0c 24             	cmp    %ecx,(%esp)
f01057c3:	0f 86 d7 00 00 00    	jbe    f01058a0 <__umoddi3+0x140>
f01057c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01057cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01057d1:	83 c4 1c             	add    $0x1c,%esp
f01057d4:	5b                   	pop    %ebx
f01057d5:	5e                   	pop    %esi
f01057d6:	5f                   	pop    %edi
f01057d7:	5d                   	pop    %ebp
f01057d8:	c3                   	ret    
f01057d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057e0:	85 ff                	test   %edi,%edi
f01057e2:	89 fd                	mov    %edi,%ebp
f01057e4:	75 0b                	jne    f01057f1 <__umoddi3+0x91>
f01057e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01057eb:	31 d2                	xor    %edx,%edx
f01057ed:	f7 f7                	div    %edi
f01057ef:	89 c5                	mov    %eax,%ebp
f01057f1:	89 f0                	mov    %esi,%eax
f01057f3:	31 d2                	xor    %edx,%edx
f01057f5:	f7 f5                	div    %ebp
f01057f7:	89 c8                	mov    %ecx,%eax
f01057f9:	f7 f5                	div    %ebp
f01057fb:	89 d0                	mov    %edx,%eax
f01057fd:	eb 99                	jmp    f0105798 <__umoddi3+0x38>
f01057ff:	90                   	nop
f0105800:	89 c8                	mov    %ecx,%eax
f0105802:	89 f2                	mov    %esi,%edx
f0105804:	83 c4 1c             	add    $0x1c,%esp
f0105807:	5b                   	pop    %ebx
f0105808:	5e                   	pop    %esi
f0105809:	5f                   	pop    %edi
f010580a:	5d                   	pop    %ebp
f010580b:	c3                   	ret    
f010580c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105810:	8b 34 24             	mov    (%esp),%esi
f0105813:	bf 20 00 00 00       	mov    $0x20,%edi
f0105818:	89 e9                	mov    %ebp,%ecx
f010581a:	29 ef                	sub    %ebp,%edi
f010581c:	d3 e0                	shl    %cl,%eax
f010581e:	89 f9                	mov    %edi,%ecx
f0105820:	89 f2                	mov    %esi,%edx
f0105822:	d3 ea                	shr    %cl,%edx
f0105824:	89 e9                	mov    %ebp,%ecx
f0105826:	09 c2                	or     %eax,%edx
f0105828:	89 d8                	mov    %ebx,%eax
f010582a:	89 14 24             	mov    %edx,(%esp)
f010582d:	89 f2                	mov    %esi,%edx
f010582f:	d3 e2                	shl    %cl,%edx
f0105831:	89 f9                	mov    %edi,%ecx
f0105833:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105837:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010583b:	d3 e8                	shr    %cl,%eax
f010583d:	89 e9                	mov    %ebp,%ecx
f010583f:	89 c6                	mov    %eax,%esi
f0105841:	d3 e3                	shl    %cl,%ebx
f0105843:	89 f9                	mov    %edi,%ecx
f0105845:	89 d0                	mov    %edx,%eax
f0105847:	d3 e8                	shr    %cl,%eax
f0105849:	89 e9                	mov    %ebp,%ecx
f010584b:	09 d8                	or     %ebx,%eax
f010584d:	89 d3                	mov    %edx,%ebx
f010584f:	89 f2                	mov    %esi,%edx
f0105851:	f7 34 24             	divl   (%esp)
f0105854:	89 d6                	mov    %edx,%esi
f0105856:	d3 e3                	shl    %cl,%ebx
f0105858:	f7 64 24 04          	mull   0x4(%esp)
f010585c:	39 d6                	cmp    %edx,%esi
f010585e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105862:	89 d1                	mov    %edx,%ecx
f0105864:	89 c3                	mov    %eax,%ebx
f0105866:	72 08                	jb     f0105870 <__umoddi3+0x110>
f0105868:	75 11                	jne    f010587b <__umoddi3+0x11b>
f010586a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010586e:	73 0b                	jae    f010587b <__umoddi3+0x11b>
f0105870:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105874:	1b 14 24             	sbb    (%esp),%edx
f0105877:	89 d1                	mov    %edx,%ecx
f0105879:	89 c3                	mov    %eax,%ebx
f010587b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010587f:	29 da                	sub    %ebx,%edx
f0105881:	19 ce                	sbb    %ecx,%esi
f0105883:	89 f9                	mov    %edi,%ecx
f0105885:	89 f0                	mov    %esi,%eax
f0105887:	d3 e0                	shl    %cl,%eax
f0105889:	89 e9                	mov    %ebp,%ecx
f010588b:	d3 ea                	shr    %cl,%edx
f010588d:	89 e9                	mov    %ebp,%ecx
f010588f:	d3 ee                	shr    %cl,%esi
f0105891:	09 d0                	or     %edx,%eax
f0105893:	89 f2                	mov    %esi,%edx
f0105895:	83 c4 1c             	add    $0x1c,%esp
f0105898:	5b                   	pop    %ebx
f0105899:	5e                   	pop    %esi
f010589a:	5f                   	pop    %edi
f010589b:	5d                   	pop    %ebp
f010589c:	c3                   	ret    
f010589d:	8d 76 00             	lea    0x0(%esi),%esi
f01058a0:	29 f9                	sub    %edi,%ecx
f01058a2:	19 d6                	sbb    %edx,%esi
f01058a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01058a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01058ac:	e9 18 ff ff ff       	jmp    f01057c9 <__umoddi3+0x69>
