
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
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
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
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

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
f0100048:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 fe 22 f0    	mov    %esi,0xf022fe80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 7a 59 00 00       	call   f01059db <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 60 10 f0       	push   $0xf0106080
f010006d:	e8 42 35 00 00       	call   f01035b4 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 12 35 00 00       	call   f010358e <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 e9 71 10 f0 	movl   $0xf01071e9,(%esp)
f0100083:	e8 2c 35 00 00       	call   f01035b4 <cprintf>
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
f01000a1:	b8 08 10 27 f0       	mov    $0xf0271008,%eax
f01000a6:	2d 28 e6 22 f0       	sub    $0xf022e628,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 28 e6 22 f0       	push   $0xf022e628
f01000b3:	e8 ee 52 00 00       	call   f01053a6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 60 10 f0       	push   $0xf01060ec
f01000ca:	e8 e5 34 00 00       	call   f01035b4 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 34 11 00 00       	call   f0101208 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 39 2d 00 00       	call   f0102e12 <env_init>
	trap_init();
f01000d9:	e8 bc 35 00 00       	call   f010369a <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 d9 55 00 00       	call   f01056bc <mp_init>
	lapic_init();
f01000e3:	e8 0e 59 00 00       	call   f01059f6 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 ee 33 00 00       	call   f01034db <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 50 5b 00 00       	call   f0105c49 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 fe 22 f0 07 	cmpl   $0x7,0xf022fe88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 a4 60 10 f0       	push   $0xf01060a4
f010010f:	6a 59                	push   $0x59
f0100111:	68 07 61 10 f0       	push   $0xf0106107
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 22 56 10 f0       	mov    $0xf0105622,%eax
f0100123:	2d a8 55 10 f0       	sub    $0xf01055a8,%eax
f0100128:	50                   	push   %eax
f0100129:	68 a8 55 10 f0       	push   $0xf01055a8
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 bb 52 00 00       	call   f01053f3 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 94 58 00 00       	call   f01059db <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 00 23 f0       	sub    $0xf0230020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 90 23 f0       	add    $0xf0239000,%eax
f010016b:	a3 84 fe 22 f0       	mov    %eax,0xf022fe84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 c3 59 00 00       	call   f0105b44 <lapic_startap>
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
f010018f:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0100196:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST) 
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 fc 4b 22 f0       	push   $0xf0224bfc
f01001a9:	e8 37 2e 00 00       	call   f0102fe5 <env_create>
	//ENV_CREATE(user_hello, ENV_TYPE_USER);
	
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 9d 3f 00 00       	call   f0104150 <sched_yield>

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
f01001b9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 c8 60 10 f0       	push   $0xf01060c8
f01001cb:	6a 70                	push   $0x70
f01001cd:	68 07 61 10 f0       	push   $0xf0106107
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 f7 57 00 00       	call   f01059db <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 13 61 10 f0       	push   $0xf0106113
f01001ed:	e8 c2 33 00 00       	call   f01035b4 <cprintf>

	lapic_init();
f01001f2:	e8 ff 57 00 00       	call   f01059f6 <lapic_init>
	env_init_percpu();
f01001f7:	e8 e6 2b 00 00       	call   f0102de2 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 c7 33 00 00       	call   f01035c8 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 d5 57 00 00       	call   f01059db <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010021f:	e8 25 5a 00 00       	call   f0105c49 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 27 3f 00 00       	call   f0104150 <sched_yield>

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
f0100239:	68 29 61 10 f0       	push   $0xf0106129
f010023e:	e8 71 33 00 00       	call   f01035b4 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 3f 33 00 00       	call   f010358e <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 e9 71 10 f0 	movl   $0xf01071e9,(%esp)
f0100256:	e8 59 33 00 00       	call   f01035b4 <cprintf>
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
f0100291:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002a0:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
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
f01002e7:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
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
f01002ff:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 a0 62 10 f0 	movzbl -0xfef9d60(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 a0 62 10 f0 	movzbl -0xfef9d60(%edx),%eax
f0100358:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f010035e:	0f b6 8a a0 61 10 f0 	movzbl -0xfef9e60(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d 80 61 10 f0 	mov    -0xfef9e80(,%ecx,4),%ecx
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
f01003af:	68 43 61 10 f0       	push   $0xf0106143
f01003b4:	e8 fb 31 00 00       	call   f01035b4 <cprintf>
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
f010049b:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
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
f0100525:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 8b 4e 00 00       	call   f01053f3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
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
f0100589:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
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
f01005c7:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
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
f0100605:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f010060a:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f010061b:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
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
f010062c:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
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
f0100665:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
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
f010067d:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
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
f010068c:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
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
f01006b1:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 87 2d 00 00       	call   f0103463 <irq_setmask_8259A>
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
f010073a:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
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
f010074f:	68 4f 61 10 f0       	push   $0xf010614f
f0100754:	e8 5b 2e 00 00       	call   f01035b4 <cprintf>
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
f0100795:	68 a0 63 10 f0       	push   $0xf01063a0
f010079a:	68 be 63 10 f0       	push   $0xf01063be
f010079f:	68 c3 63 10 f0       	push   $0xf01063c3
f01007a4:	e8 0b 2e 00 00       	call   f01035b4 <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 2c 64 10 f0       	push   $0xf010642c
f01007b1:	68 cc 63 10 f0       	push   $0xf01063cc
f01007b6:	68 c3 63 10 f0       	push   $0xf01063c3
f01007bb:	e8 f4 2d 00 00       	call   f01035b4 <cprintf>
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
f01007cd:	68 d5 63 10 f0       	push   $0xf01063d5
f01007d2:	e8 dd 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d7:	83 c4 08             	add    $0x8,%esp
f01007da:	68 0c 00 10 00       	push   $0x10000c
f01007df:	68 54 64 10 f0       	push   $0xf0106454
f01007e4:	e8 cb 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	68 0c 00 10 00       	push   $0x10000c
f01007f1:	68 0c 00 10 f0       	push   $0xf010000c
f01007f6:	68 7c 64 10 f0       	push   $0xf010647c
f01007fb:	e8 b4 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 61 60 10 00       	push   $0x106061
f0100808:	68 61 60 10 f0       	push   $0xf0106061
f010080d:	68 a0 64 10 f0       	push   $0xf01064a0
f0100812:	e8 9d 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 28 e6 22 00       	push   $0x22e628
f010081f:	68 28 e6 22 f0       	push   $0xf022e628
f0100824:	68 c4 64 10 f0       	push   $0xf01064c4
f0100829:	e8 86 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 08 10 27 00       	push   $0x271008
f0100836:	68 08 10 27 f0       	push   $0xf0271008
f010083b:	68 e8 64 10 f0       	push   $0xf01064e8
f0100840:	e8 6f 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100845:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
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
f0100866:	68 0c 65 10 f0       	push   $0xf010650c
f010086b:	e8 44 2d 00 00       	call   f01035b4 <cprintf>
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
f010088a:	68 38 65 10 f0       	push   $0xf0106538
f010088f:	e8 20 2d 00 00       	call   f01035b4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100894:	c7 04 24 5c 65 10 f0 	movl   $0xf010655c,(%esp)
f010089b:	e8 14 2d 00 00       	call   f01035b4 <cprintf>

	if (tf != NULL)
f01008a0:	83 c4 10             	add    $0x10,%esp
f01008a3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008a7:	74 0e                	je     f01008b7 <monitor+0x36>
		print_trapframe(tf);
f01008a9:	83 ec 0c             	sub    $0xc,%esp
f01008ac:	ff 75 08             	pushl  0x8(%ebp)
f01008af:	e8 87 32 00 00       	call   f0103b3b <print_trapframe>
f01008b4:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01008b7:	83 ec 0c             	sub    $0xc,%esp
f01008ba:	68 ee 63 10 f0       	push   $0xf01063ee
f01008bf:	e8 8b 48 00 00       	call   f010514f <readline>
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
f01008f3:	68 f2 63 10 f0       	push   $0xf01063f2
f01008f8:	e8 6c 4a 00 00       	call   f0105369 <strchr>
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
f0100913:	68 f7 63 10 f0       	push   $0xf01063f7
f0100918:	e8 97 2c 00 00       	call   f01035b4 <cprintf>
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
f010093c:	68 f2 63 10 f0       	push   $0xf01063f2
f0100941:	e8 23 4a 00 00       	call   f0105369 <strchr>
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
f0100962:	68 be 63 10 f0       	push   $0xf01063be
f0100967:	ff 75 a8             	pushl  -0x58(%ebp)
f010096a:	e8 9c 49 00 00       	call   f010530b <strcmp>
f010096f:	83 c4 10             	add    $0x10,%esp
f0100972:	85 c0                	test   %eax,%eax
f0100974:	74 1e                	je     f0100994 <monitor+0x113>
f0100976:	83 ec 08             	sub    $0x8,%esp
f0100979:	68 cc 63 10 f0       	push   $0xf01063cc
f010097e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100981:	e8 85 49 00 00       	call   f010530b <strcmp>
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
f01009a9:	ff 14 85 8c 65 10 f0 	call   *-0xfef9a74(,%eax,4)
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
f01009c2:	68 14 64 10 f0       	push   $0xf0106414
f01009c7:	e8 e8 2b 00 00       	call   f01035b4 <cprintf>
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
f01009e1:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f01009e8:	75 0f                	jne    f01009f9 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ea:	b8 07 20 27 f0       	mov    $0xf0272007,%eax
f01009ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f4:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009f9:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f01009fe:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100a04:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a0a:	01 c2                	add    %eax,%edx
f0100a0c:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
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
f0100a1f:	e8 11 2a 00 00       	call   f0103435 <mc146818_read>
f0100a24:	89 c6                	mov    %eax,%esi
f0100a26:	83 c3 01             	add    $0x1,%ebx
f0100a29:	89 1c 24             	mov    %ebx,(%esp)
f0100a2c:	e8 04 2a 00 00       	call   f0103435 <mc146818_read>
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
f0100a53:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
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
f0100a62:	68 a4 60 10 f0       	push   $0xf01060a4
f0100a67:	68 94 03 00 00       	push   $0x394
f0100a6c:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100aba:	68 9c 65 10 f0       	push   $0xf010659c
f0100abf:	68 c7 02 00 00       	push   $0x2c7
f0100ac4:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100adc:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
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
f0100b12:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
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
f0100b1c:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100b22:	eb 53                	jmp    f0100b77 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b24:	89 d8                	mov    %ebx,%eax
f0100b26:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
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
f0100b40:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100b46:	72 12                	jb     f0100b5a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b48:	50                   	push   %eax
f0100b49:	68 a4 60 10 f0       	push   $0xf01060a4
f0100b4e:	6a 58                	push   $0x58
f0100b50:	68 15 6f 10 f0       	push   $0xf0106f15
f0100b55:	e8 e6 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b5a:	83 ec 04             	sub    $0x4,%esp
f0100b5d:	68 80 00 00 00       	push   $0x80
f0100b62:	68 97 00 00 00       	push   $0x97
f0100b67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6c:	50                   	push   %eax
f0100b6d:	e8 34 48 00 00       	call   f01053a6 <memset>
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
f0100b88:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b8e:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100b94:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
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
f0100bb3:	68 23 6f 10 f0       	push   $0xf0106f23
f0100bb8:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100bbd:	68 e1 02 00 00       	push   $0x2e1
f0100bc2:	68 09 6f 10 f0       	push   $0xf0106f09
f0100bc7:	e8 74 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bcc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bcf:	72 19                	jb     f0100bea <check_page_free_list+0x149>
f0100bd1:	68 44 6f 10 f0       	push   $0xf0106f44
f0100bd6:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100bdb:	68 e2 02 00 00       	push   $0x2e2
f0100be0:	68 09 6f 10 f0       	push   $0xf0106f09
f0100be5:	e8 56 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bea:	89 d0                	mov    %edx,%eax
f0100bec:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bef:	a8 07                	test   $0x7,%al
f0100bf1:	74 19                	je     f0100c0c <check_page_free_list+0x16b>
f0100bf3:	68 c0 65 10 f0       	push   $0xf01065c0
f0100bf8:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100bfd:	68 e3 02 00 00       	push   $0x2e3
f0100c02:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100c16:	68 58 6f 10 f0       	push   $0xf0106f58
f0100c1b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100c20:	68 e6 02 00 00       	push   $0x2e6
f0100c25:	68 09 6f 10 f0       	push   $0xf0106f09
f0100c2a:	e8 11 f4 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c34:	75 19                	jne    f0100c4f <check_page_free_list+0x1ae>
f0100c36:	68 69 6f 10 f0       	push   $0xf0106f69
f0100c3b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100c40:	68 e7 02 00 00       	push   $0x2e7
f0100c45:	68 09 6f 10 f0       	push   $0xf0106f09
f0100c4a:	e8 f1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c54:	75 19                	jne    f0100c6f <check_page_free_list+0x1ce>
f0100c56:	68 f4 65 10 f0       	push   $0xf01065f4
f0100c5b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100c60:	68 e8 02 00 00       	push   $0x2e8
f0100c65:	68 09 6f 10 f0       	push   $0xf0106f09
f0100c6a:	e8 d1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c74:	75 19                	jne    f0100c8f <check_page_free_list+0x1ee>
f0100c76:	68 82 6f 10 f0       	push   $0xf0106f82
f0100c7b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100c80:	68 e9 02 00 00       	push   $0x2e9
f0100c85:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100ca5:	68 a4 60 10 f0       	push   $0xf01060a4
f0100caa:	6a 58                	push   $0x58
f0100cac:	68 15 6f 10 f0       	push   $0xf0106f15
f0100cb1:	e8 8a f3 ff ff       	call   f0100040 <_panic>
f0100cb6:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cbc:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100cbf:	0f 86 b6 00 00 00    	jbe    f0100d7b <check_page_free_list+0x2da>
f0100cc5:	68 18 66 10 f0       	push   $0xf0106618
f0100cca:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100ccf:	68 ea 02 00 00       	push   $0x2ea
f0100cd4:	68 09 6f 10 f0       	push   $0xf0106f09
f0100cd9:	e8 62 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100cde:	68 9c 6f 10 f0       	push   $0xf0106f9c
f0100ce3:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100ce8:	68 ec 02 00 00       	push   $0x2ec
f0100ced:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100d0d:	68 b9 6f 10 f0       	push   $0xf0106fb9
f0100d12:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100d17:	68 f4 02 00 00       	push   $0x2f4
f0100d1c:	68 09 6f 10 f0       	push   $0xf0106f09
f0100d21:	e8 1a f3 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d26:	85 db                	test   %ebx,%ebx
f0100d28:	7f 19                	jg     f0100d43 <check_page_free_list+0x2a2>
f0100d2a:	68 cb 6f 10 f0       	push   $0xf0106fcb
f0100d2f:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100d34:	68 f5 02 00 00       	push   $0x2f5
f0100d39:	68 09 6f 10 f0       	push   $0xf0106f09
f0100d3e:	e8 fd f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d43:	83 ec 0c             	sub    $0xc,%esp
f0100d46:	68 60 66 10 f0       	push   $0xf0106660
f0100d4b:	e8 64 28 00 00       	call   f01035b4 <cprintf>
}
f0100d50:	eb 49                	jmp    f0100d9b <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d52:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100d57:	85 c0                	test   %eax,%eax
f0100d59:	0f 85 6f fd ff ff    	jne    f0100ace <check_page_free_list+0x2d>
f0100d5f:	e9 53 fd ff ff       	jmp    f0100ab7 <check_page_free_list+0x16>
f0100d64:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
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
f0100da8:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
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
f0100dc4:	68 c8 60 10 f0       	push   $0xf01060c8
f0100dc9:	68 3b 01 00 00       	push   $0x13b
f0100dce:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0100df5:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
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
f0100e15:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
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
f0100e31:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
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
f0100e4f:	03 35 90 fe 22 f0    	add    0xf022fe90,%esi
f0100e55:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
                 pages[i].pp_link = page_free_list;
f0100e5b:	89 1e                	mov    %ebx,(%esi)
                 page_free_list = &pages[i];
f0100e5d:	89 cb                	mov    %ecx,%ebx
f0100e5f:	03 1d 90 fe 22 f0    	add    0xf022fe90,%ebx
f0100e65:	be 01 00 00 00       	mov    $0x1,%esi
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100e6a:	83 c2 01             	add    $0x1,%edx
f0100e6d:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100e73:	0f 82 78 ff ff ff    	jb     f0100df1 <page_init+0x4e>
f0100e79:	89 f0                	mov    %esi,%eax
f0100e7b:	84 c0                	test   %al,%al
f0100e7d:	74 06                	je     f0100e85 <page_init+0xe2>
f0100e7f:	89 1d 40 f2 22 f0    	mov    %ebx,0xf022f240
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
f0100e93:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100e99:	85 db                	test   %ebx,%ebx
f0100e9b:	74 58                	je     f0100ef5 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100e9d:	8b 03                	mov    (%ebx),%eax
f0100e9f:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
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
f0100eb2:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100eb8:	c1 f8 03             	sar    $0x3,%eax
f0100ebb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ebe:	89 c2                	mov    %eax,%edx
f0100ec0:	c1 ea 0c             	shr    $0xc,%edx
f0100ec3:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100ec9:	72 12                	jb     f0100edd <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ecb:	50                   	push   %eax
f0100ecc:	68 a4 60 10 f0       	push   $0xf01060a4
f0100ed1:	6a 58                	push   $0x58
f0100ed3:	68 15 6f 10 f0       	push   $0xf0106f15
f0100ed8:	e8 63 f1 ff ff       	call   f0100040 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100edd:	83 ec 04             	sub    $0x4,%esp
f0100ee0:	68 00 10 00 00       	push   $0x1000
f0100ee5:	6a 00                	push   $0x0
f0100ee7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100eec:	50                   	push   %eax
f0100eed:	e8 b4 44 00 00       	call   f01053a6 <memset>
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
f0100f11:	68 84 66 10 f0       	push   $0xf0106684
f0100f16:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0100f1b:	68 7d 01 00 00       	push   $0x17d
f0100f20:	68 09 6f 10 f0       	push   $0xf0106f09
f0100f25:	e8 16 f1 ff ff       	call   f0100040 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100f2a:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0100f30:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100f32:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
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
f0100f9d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
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
f0100fba:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100fc0:	72 15                	jb     f0100fd7 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc2:	50                   	push   %eax
f0100fc3:	68 a4 60 10 f0       	push   $0xf01060a4
f0100fc8:	68 b8 01 00 00       	push   $0x1b8
f0100fcd:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101073:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0101079:	72 14                	jb     f010108f <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f010107b:	83 ec 04             	sub    $0x4,%esp
f010107e:	68 ac 66 10 f0       	push   $0xf01066ac
f0101083:	6a 51                	push   $0x51
f0101085:	68 15 6f 10 f0       	push   $0xf0106f15
f010108a:	e8 b1 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010108f:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
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
f01010b1:	e8 25 49 00 00       	call   f01059db <cpunum>
f01010b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01010b9:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01010c0:	74 16                	je     f01010d8 <tlb_invalidate+0x2d>
f01010c2:	e8 14 49 00 00       	call   f01059db <cpunum>
f01010c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01010ca:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
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
f0101175:	2b 1d 90 fe 22 f0    	sub    0xf022fe90,%ebx
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
f01011b2:	8b 1d 00 03 12 f0    	mov    0xf0120300,%ebx
	size=ROUNDUP(size,PGSIZE);
f01011b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011bb:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f01011c1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	base=base+size;
f01011c7:	8d 04 0b             	lea    (%ebx,%ecx,1),%eax
f01011ca:	a3 00 03 12 f0       	mov    %eax,0xf0120300
	if(base>MMIOLIM)
f01011cf:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01011d4:	76 17                	jbe    f01011ed <mmio_map_region+0x42>
		panic("mmio_map_region not implemented");
f01011d6:	83 ec 04             	sub    $0x4,%esp
f01011d9:	68 cc 66 10 f0       	push   $0xf01066cc
f01011de:	68 72 02 00 00       	push   $0x272
f01011e3:	68 09 6f 10 f0       	push   $0xf0106f09
f01011e8:	e8 53 ee ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir,ret,size,pa,PTE_PCD|PTE_W|PTE_PWT);
f01011ed:	83 ec 08             	sub    $0x8,%esp
f01011f0:	6a 1a                	push   $0x1a
f01011f2:	ff 75 08             	pushl  0x8(%ebp)
f01011f5:	89 da                	mov    %ebx,%edx
f01011f7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
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
f0101251:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101257:	89 c2                	mov    %eax,%edx
f0101259:	29 da                	sub    %ebx,%edx
f010125b:	52                   	push   %edx
f010125c:	53                   	push   %ebx
f010125d:	50                   	push   %eax
f010125e:	68 ec 66 10 f0       	push   $0xf01066ec
f0101263:	e8 4c 23 00 00       	call   f01035b4 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101268:	b8 00 10 00 00       	mov    $0x1000,%eax
f010126d:	e8 6a f7 ff ff       	call   f01009dc <boot_alloc>
f0101272:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f0101277:	83 c4 0c             	add    $0xc,%esp
f010127a:	68 00 10 00 00       	push   $0x1000
f010127f:	6a 00                	push   $0x0
f0101281:	50                   	push   %eax
f0101282:	e8 1f 41 00 00       	call   f01053a6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101287:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
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
f0101297:	68 c8 60 10 f0       	push   $0xf01060c8
f010129c:	68 92 00 00 00       	push   $0x92
f01012a1:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01012ba:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f01012bf:	c1 e0 03             	shl    $0x3,%eax
f01012c2:	e8 15 f7 ff ff       	call   f01009dc <boot_alloc>
f01012c7:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
        memset(pages,0,npages*sizeof(struct PageInfo));
f01012cc:	83 ec 04             	sub    $0x4,%esp
f01012cf:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01012d5:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012dc:	52                   	push   %edx
f01012dd:	6a 00                	push   $0x0
f01012df:	50                   	push   %eax
f01012e0:	e8 c1 40 00 00       	call   f01053a6 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=(struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01012e5:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01012ea:	e8 ed f6 ff ff       	call   f01009dc <boot_alloc>
f01012ef:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
	memset(envs,0,NENV*sizeof(struct Env));
f01012f4:	83 c4 0c             	add    $0xc,%esp
f01012f7:	68 00 f0 01 00       	push   $0x1f000
f01012fc:	6a 00                	push   $0x0
f01012fe:	50                   	push   %eax
f01012ff:	e8 a2 40 00 00       	call   f01053a6 <memset>
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
f0101316:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f010131d:	75 17                	jne    f0101336 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010131f:	83 ec 04             	sub    $0x4,%esp
f0101322:	68 dc 6f 10 f0       	push   $0xf0106fdc
f0101327:	68 08 03 00 00       	push   $0x308
f010132c:	68 09 6f 10 f0       	push   $0xf0106f09
f0101331:	e8 0a ed ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101336:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
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
f010135e:	68 f7 6f 10 f0       	push   $0xf0106ff7
f0101363:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101368:	68 10 03 00 00       	push   $0x310
f010136d:	68 09 6f 10 f0       	push   $0xf0106f09
f0101372:	e8 c9 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101377:	83 ec 0c             	sub    $0xc,%esp
f010137a:	6a 00                	push   $0x0
f010137c:	e8 0b fb ff ff       	call   f0100e8c <page_alloc>
f0101381:	89 c6                	mov    %eax,%esi
f0101383:	83 c4 10             	add    $0x10,%esp
f0101386:	85 c0                	test   %eax,%eax
f0101388:	75 19                	jne    f01013a3 <mem_init+0x19b>
f010138a:	68 0d 70 10 f0       	push   $0xf010700d
f010138f:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101394:	68 11 03 00 00       	push   $0x311
f0101399:	68 09 6f 10 f0       	push   $0xf0106f09
f010139e:	e8 9d ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	6a 00                	push   $0x0
f01013a8:	e8 df fa ff ff       	call   f0100e8c <page_alloc>
f01013ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013b0:	83 c4 10             	add    $0x10,%esp
f01013b3:	85 c0                	test   %eax,%eax
f01013b5:	75 19                	jne    f01013d0 <mem_init+0x1c8>
f01013b7:	68 23 70 10 f0       	push   $0xf0107023
f01013bc:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01013c1:	68 12 03 00 00       	push   $0x312
f01013c6:	68 09 6f 10 f0       	push   $0xf0106f09
f01013cb:	e8 70 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013d0:	39 f7                	cmp    %esi,%edi
f01013d2:	75 19                	jne    f01013ed <mem_init+0x1e5>
f01013d4:	68 39 70 10 f0       	push   $0xf0107039
f01013d9:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01013de:	68 15 03 00 00       	push   $0x315
f01013e3:	68 09 6f 10 f0       	push   $0xf0106f09
f01013e8:	e8 53 ec ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013f0:	39 c6                	cmp    %eax,%esi
f01013f2:	74 04                	je     f01013f8 <mem_init+0x1f0>
f01013f4:	39 c7                	cmp    %eax,%edi
f01013f6:	75 19                	jne    f0101411 <mem_init+0x209>
f01013f8:	68 28 67 10 f0       	push   $0xf0106728
f01013fd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101402:	68 16 03 00 00       	push   $0x316
f0101407:	68 09 6f 10 f0       	push   $0xf0106f09
f010140c:	e8 2f ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101411:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101417:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f010141d:	c1 e2 0c             	shl    $0xc,%edx
f0101420:	89 f8                	mov    %edi,%eax
f0101422:	29 c8                	sub    %ecx,%eax
f0101424:	c1 f8 03             	sar    $0x3,%eax
f0101427:	c1 e0 0c             	shl    $0xc,%eax
f010142a:	39 d0                	cmp    %edx,%eax
f010142c:	72 19                	jb     f0101447 <mem_init+0x23f>
f010142e:	68 4b 70 10 f0       	push   $0xf010704b
f0101433:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101438:	68 17 03 00 00       	push   $0x317
f010143d:	68 09 6f 10 f0       	push   $0xf0106f09
f0101442:	e8 f9 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101447:	89 f0                	mov    %esi,%eax
f0101449:	29 c8                	sub    %ecx,%eax
f010144b:	c1 f8 03             	sar    $0x3,%eax
f010144e:	c1 e0 0c             	shl    $0xc,%eax
f0101451:	39 c2                	cmp    %eax,%edx
f0101453:	77 19                	ja     f010146e <mem_init+0x266>
f0101455:	68 68 70 10 f0       	push   $0xf0107068
f010145a:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010145f:	68 18 03 00 00       	push   $0x318
f0101464:	68 09 6f 10 f0       	push   $0xf0106f09
f0101469:	e8 d2 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010146e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101471:	29 c8                	sub    %ecx,%eax
f0101473:	c1 f8 03             	sar    $0x3,%eax
f0101476:	c1 e0 0c             	shl    $0xc,%eax
f0101479:	39 c2                	cmp    %eax,%edx
f010147b:	77 19                	ja     f0101496 <mem_init+0x28e>
f010147d:	68 85 70 10 f0       	push   $0xf0107085
f0101482:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101487:	68 19 03 00 00       	push   $0x319
f010148c:	68 09 6f 10 f0       	push   $0xf0106f09
f0101491:	e8 aa eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101496:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f010149b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010149e:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f01014a5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 da f9 ff ff       	call   f0100e8c <page_alloc>
f01014b2:	83 c4 10             	add    $0x10,%esp
f01014b5:	85 c0                	test   %eax,%eax
f01014b7:	74 19                	je     f01014d2 <mem_init+0x2ca>
f01014b9:	68 a2 70 10 f0       	push   $0xf01070a2
f01014be:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01014c3:	68 20 03 00 00       	push   $0x320
f01014c8:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101503:	68 f7 6f 10 f0       	push   $0xf0106ff7
f0101508:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010150d:	68 27 03 00 00       	push   $0x327
f0101512:	68 09 6f 10 f0       	push   $0xf0106f09
f0101517:	e8 24 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010151c:	83 ec 0c             	sub    $0xc,%esp
f010151f:	6a 00                	push   $0x0
f0101521:	e8 66 f9 ff ff       	call   f0100e8c <page_alloc>
f0101526:	89 c7                	mov    %eax,%edi
f0101528:	83 c4 10             	add    $0x10,%esp
f010152b:	85 c0                	test   %eax,%eax
f010152d:	75 19                	jne    f0101548 <mem_init+0x340>
f010152f:	68 0d 70 10 f0       	push   $0xf010700d
f0101534:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101539:	68 28 03 00 00       	push   $0x328
f010153e:	68 09 6f 10 f0       	push   $0xf0106f09
f0101543:	e8 f8 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101548:	83 ec 0c             	sub    $0xc,%esp
f010154b:	6a 00                	push   $0x0
f010154d:	e8 3a f9 ff ff       	call   f0100e8c <page_alloc>
f0101552:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101555:	83 c4 10             	add    $0x10,%esp
f0101558:	85 c0                	test   %eax,%eax
f010155a:	75 19                	jne    f0101575 <mem_init+0x36d>
f010155c:	68 23 70 10 f0       	push   $0xf0107023
f0101561:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101566:	68 29 03 00 00       	push   $0x329
f010156b:	68 09 6f 10 f0       	push   $0xf0106f09
f0101570:	e8 cb ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101575:	39 fe                	cmp    %edi,%esi
f0101577:	75 19                	jne    f0101592 <mem_init+0x38a>
f0101579:	68 39 70 10 f0       	push   $0xf0107039
f010157e:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101583:	68 2b 03 00 00       	push   $0x32b
f0101588:	68 09 6f 10 f0       	push   $0xf0106f09
f010158d:	e8 ae ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101592:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101595:	39 c7                	cmp    %eax,%edi
f0101597:	74 04                	je     f010159d <mem_init+0x395>
f0101599:	39 c6                	cmp    %eax,%esi
f010159b:	75 19                	jne    f01015b6 <mem_init+0x3ae>
f010159d:	68 28 67 10 f0       	push   $0xf0106728
f01015a2:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01015a7:	68 2c 03 00 00       	push   $0x32c
f01015ac:	68 09 6f 10 f0       	push   $0xf0106f09
f01015b1:	e8 8a ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 00                	push   $0x0
f01015bb:	e8 cc f8 ff ff       	call   f0100e8c <page_alloc>
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	74 19                	je     f01015e0 <mem_init+0x3d8>
f01015c7:	68 a2 70 10 f0       	push   $0xf01070a2
f01015cc:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01015d1:	68 2d 03 00 00       	push   $0x32d
f01015d6:	68 09 6f 10 f0       	push   $0xf0106f09
f01015db:	e8 60 ea ff ff       	call   f0100040 <_panic>
f01015e0:	89 f0                	mov    %esi,%eax
f01015e2:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01015e8:	c1 f8 03             	sar    $0x3,%eax
f01015eb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015ee:	89 c2                	mov    %eax,%edx
f01015f0:	c1 ea 0c             	shr    $0xc,%edx
f01015f3:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f01015f9:	72 12                	jb     f010160d <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015fb:	50                   	push   %eax
f01015fc:	68 a4 60 10 f0       	push   $0xf01060a4
f0101601:	6a 58                	push   $0x58
f0101603:	68 15 6f 10 f0       	push   $0xf0106f15
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010160d:	83 ec 04             	sub    $0x4,%esp
f0101610:	68 00 10 00 00       	push   $0x1000
f0101615:	6a 01                	push   $0x1
f0101617:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010161c:	50                   	push   %eax
f010161d:	e8 84 3d 00 00       	call   f01053a6 <memset>
	page_free(pp0);
f0101622:	89 34 24             	mov    %esi,(%esp)
f0101625:	e8 d2 f8 ff ff       	call   f0100efc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010162a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101631:	e8 56 f8 ff ff       	call   f0100e8c <page_alloc>
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	85 c0                	test   %eax,%eax
f010163b:	75 19                	jne    f0101656 <mem_init+0x44e>
f010163d:	68 b1 70 10 f0       	push   $0xf01070b1
f0101642:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101647:	68 32 03 00 00       	push   $0x332
f010164c:	68 09 6f 10 f0       	push   $0xf0106f09
f0101651:	e8 ea e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101656:	39 c6                	cmp    %eax,%esi
f0101658:	74 19                	je     f0101673 <mem_init+0x46b>
f010165a:	68 cf 70 10 f0       	push   $0xf01070cf
f010165f:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101664:	68 33 03 00 00       	push   $0x333
f0101669:	68 09 6f 10 f0       	push   $0xf0106f09
f010166e:	e8 cd e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101673:	89 f0                	mov    %esi,%eax
f0101675:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f010167b:	c1 f8 03             	sar    $0x3,%eax
f010167e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101681:	89 c2                	mov    %eax,%edx
f0101683:	c1 ea 0c             	shr    $0xc,%edx
f0101686:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f010168c:	72 12                	jb     f01016a0 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010168e:	50                   	push   %eax
f010168f:	68 a4 60 10 f0       	push   $0xf01060a4
f0101694:	6a 58                	push   $0x58
f0101696:	68 15 6f 10 f0       	push   $0xf0106f15
f010169b:	e8 a0 e9 ff ff       	call   f0100040 <_panic>
f01016a0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01016a6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016ac:	80 38 00             	cmpb   $0x0,(%eax)
f01016af:	74 19                	je     f01016ca <mem_init+0x4c2>
f01016b1:	68 df 70 10 f0       	push   $0xf01070df
f01016b6:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01016bb:	68 36 03 00 00       	push   $0x336
f01016c0:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01016d4:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

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
f01016f5:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
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
f010170c:	68 e9 70 10 f0       	push   $0xf01070e9
f0101711:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101716:	68 43 03 00 00       	push   $0x343
f010171b:	68 09 6f 10 f0       	push   $0xf0106f09
f0101720:	e8 1b e9 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101725:	83 ec 0c             	sub    $0xc,%esp
f0101728:	68 48 67 10 f0       	push   $0xf0106748
f010172d:	e8 82 1e 00 00       	call   f01035b4 <cprintf>
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
f0101748:	68 f7 6f 10 f0       	push   $0xf0106ff7
f010174d:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101752:	68 a8 03 00 00       	push   $0x3a8
f0101757:	68 09 6f 10 f0       	push   $0xf0106f09
f010175c:	e8 df e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101761:	83 ec 0c             	sub    $0xc,%esp
f0101764:	6a 00                	push   $0x0
f0101766:	e8 21 f7 ff ff       	call   f0100e8c <page_alloc>
f010176b:	89 c3                	mov    %eax,%ebx
f010176d:	83 c4 10             	add    $0x10,%esp
f0101770:	85 c0                	test   %eax,%eax
f0101772:	75 19                	jne    f010178d <mem_init+0x585>
f0101774:	68 0d 70 10 f0       	push   $0xf010700d
f0101779:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010177e:	68 a9 03 00 00       	push   $0x3a9
f0101783:	68 09 6f 10 f0       	push   $0xf0106f09
f0101788:	e8 b3 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010178d:	83 ec 0c             	sub    $0xc,%esp
f0101790:	6a 00                	push   $0x0
f0101792:	e8 f5 f6 ff ff       	call   f0100e8c <page_alloc>
f0101797:	89 c6                	mov    %eax,%esi
f0101799:	83 c4 10             	add    $0x10,%esp
f010179c:	85 c0                	test   %eax,%eax
f010179e:	75 19                	jne    f01017b9 <mem_init+0x5b1>
f01017a0:	68 23 70 10 f0       	push   $0xf0107023
f01017a5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01017aa:	68 aa 03 00 00       	push   $0x3aa
f01017af:	68 09 6f 10 f0       	push   $0xf0106f09
f01017b4:	e8 87 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017b9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01017bc:	75 19                	jne    f01017d7 <mem_init+0x5cf>
f01017be:	68 39 70 10 f0       	push   $0xf0107039
f01017c3:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01017c8:	68 ad 03 00 00       	push   $0x3ad
f01017cd:	68 09 6f 10 f0       	push   $0xf0106f09
f01017d2:	e8 69 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017d7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017da:	74 04                	je     f01017e0 <mem_init+0x5d8>
f01017dc:	39 c3                	cmp    %eax,%ebx
f01017de:	75 19                	jne    f01017f9 <mem_init+0x5f1>
f01017e0:	68 28 67 10 f0       	push   $0xf0106728
f01017e5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01017ea:	68 ae 03 00 00       	push   $0x3ae
f01017ef:	68 09 6f 10 f0       	push   $0xf0106f09
f01017f4:	e8 47 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017f9:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01017fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101801:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101808:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010180b:	83 ec 0c             	sub    $0xc,%esp
f010180e:	6a 00                	push   $0x0
f0101810:	e8 77 f6 ff ff       	call   f0100e8c <page_alloc>
f0101815:	83 c4 10             	add    $0x10,%esp
f0101818:	85 c0                	test   %eax,%eax
f010181a:	74 19                	je     f0101835 <mem_init+0x62d>
f010181c:	68 a2 70 10 f0       	push   $0xf01070a2
f0101821:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101826:	68 b5 03 00 00       	push   $0x3b5
f010182b:	68 09 6f 10 f0       	push   $0xf0106f09
f0101830:	e8 0b e8 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101835:	83 ec 04             	sub    $0x4,%esp
f0101838:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010183b:	50                   	push   %eax
f010183c:	6a 00                	push   $0x0
f010183e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101844:	e8 fc f7 ff ff       	call   f0101045 <page_lookup>
f0101849:	83 c4 10             	add    $0x10,%esp
f010184c:	85 c0                	test   %eax,%eax
f010184e:	74 19                	je     f0101869 <mem_init+0x661>
f0101850:	68 68 67 10 f0       	push   $0xf0106768
f0101855:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010185a:	68 b8 03 00 00       	push   $0x3b8
f010185f:	68 09 6f 10 f0       	push   $0xf0106f09
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101869:	6a 02                	push   $0x2
f010186b:	6a 00                	push   $0x0
f010186d:	53                   	push   %ebx
f010186e:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101874:	e8 b4 f8 ff ff       	call   f010112d <page_insert>
f0101879:	83 c4 10             	add    $0x10,%esp
f010187c:	85 c0                	test   %eax,%eax
f010187e:	78 19                	js     f0101899 <mem_init+0x691>
f0101880:	68 a0 67 10 f0       	push   $0xf01067a0
f0101885:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010188a:	68 bb 03 00 00       	push   $0x3bb
f010188f:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01018a9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01018af:	e8 79 f8 ff ff       	call   f010112d <page_insert>
f01018b4:	83 c4 20             	add    $0x20,%esp
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	74 19                	je     f01018d4 <mem_init+0x6cc>
f01018bb:	68 d0 67 10 f0       	push   $0xf01067d0
f01018c0:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01018c5:	68 bf 03 00 00       	push   $0x3bf
f01018ca:	68 09 6f 10 f0       	push   $0xf0106f09
f01018cf:	e8 6c e7 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018d4:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018da:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
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
f01018fb:	68 00 68 10 f0       	push   $0xf0106800
f0101900:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101905:	68 c0 03 00 00       	push   $0x3c0
f010190a:	68 09 6f 10 f0       	push   $0xf0106f09
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
f010192f:	68 28 68 10 f0       	push   $0xf0106828
f0101934:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101939:	68 c1 03 00 00       	push   $0x3c1
f010193e:	68 09 6f 10 f0       	push   $0xf0106f09
f0101943:	e8 f8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101948:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010194d:	74 19                	je     f0101968 <mem_init+0x760>
f010194f:	68 f4 70 10 f0       	push   $0xf01070f4
f0101954:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101959:	68 c2 03 00 00       	push   $0x3c2
f010195e:	68 09 6f 10 f0       	push   $0xf0106f09
f0101963:	e8 d8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101968:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010196b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101970:	74 19                	je     f010198b <mem_init+0x783>
f0101972:	68 05 71 10 f0       	push   $0xf0107105
f0101977:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010197c:	68 c3 03 00 00       	push   $0x3c3
f0101981:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01019a0:	68 58 68 10 f0       	push   $0xf0106858
f01019a5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01019aa:	68 c6 03 00 00       	push   $0x3c6
f01019af:	68 09 6f 10 f0       	push   $0xf0106f09
f01019b4:	e8 87 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019be:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01019c3:	e8 75 f0 ff ff       	call   f0100a3d <check_va2pa>
f01019c8:	89 f2                	mov    %esi,%edx
f01019ca:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f01019d0:	c1 fa 03             	sar    $0x3,%edx
f01019d3:	c1 e2 0c             	shl    $0xc,%edx
f01019d6:	39 d0                	cmp    %edx,%eax
f01019d8:	74 19                	je     f01019f3 <mem_init+0x7eb>
f01019da:	68 94 68 10 f0       	push   $0xf0106894
f01019df:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01019e4:	68 c7 03 00 00       	push   $0x3c7
f01019e9:	68 09 6f 10 f0       	push   $0xf0106f09
f01019ee:	e8 4d e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01019f3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019f8:	74 19                	je     f0101a13 <mem_init+0x80b>
f01019fa:	68 16 71 10 f0       	push   $0xf0107116
f01019ff:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101a04:	68 c8 03 00 00       	push   $0x3c8
f0101a09:	68 09 6f 10 f0       	push   $0xf0106f09
f0101a0e:	e8 2d e6 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a13:	83 ec 0c             	sub    $0xc,%esp
f0101a16:	6a 00                	push   $0x0
f0101a18:	e8 6f f4 ff ff       	call   f0100e8c <page_alloc>
f0101a1d:	83 c4 10             	add    $0x10,%esp
f0101a20:	85 c0                	test   %eax,%eax
f0101a22:	74 19                	je     f0101a3d <mem_init+0x835>
f0101a24:	68 a2 70 10 f0       	push   $0xf01070a2
f0101a29:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101a2e:	68 cb 03 00 00       	push   $0x3cb
f0101a33:	68 09 6f 10 f0       	push   $0xf0106f09
f0101a38:	e8 03 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a3d:	6a 02                	push   $0x2
f0101a3f:	68 00 10 00 00       	push   $0x1000
f0101a44:	56                   	push   %esi
f0101a45:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101a4b:	e8 dd f6 ff ff       	call   f010112d <page_insert>
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	85 c0                	test   %eax,%eax
f0101a55:	74 19                	je     f0101a70 <mem_init+0x868>
f0101a57:	68 58 68 10 f0       	push   $0xf0106858
f0101a5c:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101a61:	68 ce 03 00 00       	push   $0x3ce
f0101a66:	68 09 6f 10 f0       	push   $0xf0106f09
f0101a6b:	e8 d0 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a75:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101a7a:	e8 be ef ff ff       	call   f0100a3d <check_va2pa>
f0101a7f:	89 f2                	mov    %esi,%edx
f0101a81:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101a87:	c1 fa 03             	sar    $0x3,%edx
f0101a8a:	c1 e2 0c             	shl    $0xc,%edx
f0101a8d:	39 d0                	cmp    %edx,%eax
f0101a8f:	74 19                	je     f0101aaa <mem_init+0x8a2>
f0101a91:	68 94 68 10 f0       	push   $0xf0106894
f0101a96:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101a9b:	68 cf 03 00 00       	push   $0x3cf
f0101aa0:	68 09 6f 10 f0       	push   $0xf0106f09
f0101aa5:	e8 96 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101aaa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aaf:	74 19                	je     f0101aca <mem_init+0x8c2>
f0101ab1:	68 16 71 10 f0       	push   $0xf0107116
f0101ab6:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101abb:	68 d0 03 00 00       	push   $0x3d0
f0101ac0:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101adb:	68 a2 70 10 f0       	push   $0xf01070a2
f0101ae0:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101ae5:	68 d4 03 00 00       	push   $0x3d4
f0101aea:	68 09 6f 10 f0       	push   $0xf0106f09
f0101aef:	e8 4c e5 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101af4:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101afa:	8b 02                	mov    (%edx),%eax
f0101afc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b01:	89 c1                	mov    %eax,%ecx
f0101b03:	c1 e9 0c             	shr    $0xc,%ecx
f0101b06:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101b0c:	72 15                	jb     f0101b23 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b0e:	50                   	push   %eax
f0101b0f:	68 a4 60 10 f0       	push   $0xf01060a4
f0101b14:	68 d7 03 00 00       	push   $0x3d7
f0101b19:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101b48:	68 c4 68 10 f0       	push   $0xf01068c4
f0101b4d:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101b52:	68 d8 03 00 00       	push   $0x3d8
f0101b57:	68 09 6f 10 f0       	push   $0xf0106f09
f0101b5c:	e8 df e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b61:	6a 06                	push   $0x6
f0101b63:	68 00 10 00 00       	push   $0x1000
f0101b68:	56                   	push   %esi
f0101b69:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101b6f:	e8 b9 f5 ff ff       	call   f010112d <page_insert>
f0101b74:	83 c4 10             	add    $0x10,%esp
f0101b77:	85 c0                	test   %eax,%eax
f0101b79:	74 19                	je     f0101b94 <mem_init+0x98c>
f0101b7b:	68 04 69 10 f0       	push   $0xf0106904
f0101b80:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101b85:	68 db 03 00 00       	push   $0x3db
f0101b8a:	68 09 6f 10 f0       	push   $0xf0106f09
f0101b8f:	e8 ac e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b94:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101b9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9f:	89 f8                	mov    %edi,%eax
f0101ba1:	e8 97 ee ff ff       	call   f0100a3d <check_va2pa>
f0101ba6:	89 f2                	mov    %esi,%edx
f0101ba8:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101bae:	c1 fa 03             	sar    $0x3,%edx
f0101bb1:	c1 e2 0c             	shl    $0xc,%edx
f0101bb4:	39 d0                	cmp    %edx,%eax
f0101bb6:	74 19                	je     f0101bd1 <mem_init+0x9c9>
f0101bb8:	68 94 68 10 f0       	push   $0xf0106894
f0101bbd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101bc2:	68 dc 03 00 00       	push   $0x3dc
f0101bc7:	68 09 6f 10 f0       	push   $0xf0106f09
f0101bcc:	e8 6f e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bd1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bd6:	74 19                	je     f0101bf1 <mem_init+0x9e9>
f0101bd8:	68 16 71 10 f0       	push   $0xf0107116
f0101bdd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101be2:	68 dd 03 00 00       	push   $0x3dd
f0101be7:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101c09:	68 44 69 10 f0       	push   $0xf0106944
f0101c0e:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101c13:	68 de 03 00 00       	push   $0x3de
f0101c18:	68 09 6f 10 f0       	push   $0xf0106f09
f0101c1d:	e8 1e e4 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c22:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101c27:	f6 00 04             	testb  $0x4,(%eax)
f0101c2a:	75 19                	jne    f0101c45 <mem_init+0xa3d>
f0101c2c:	68 27 71 10 f0       	push   $0xf0107127
f0101c31:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101c36:	68 df 03 00 00       	push   $0x3df
f0101c3b:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101c5a:	68 58 68 10 f0       	push   $0xf0106858
f0101c5f:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101c64:	68 e2 03 00 00       	push   $0x3e2
f0101c69:	68 09 6f 10 f0       	push   $0xf0106f09
f0101c6e:	e8 cd e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c73:	83 ec 04             	sub    $0x4,%esp
f0101c76:	6a 00                	push   $0x0
f0101c78:	68 00 10 00 00       	push   $0x1000
f0101c7d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101c83:	e8 d8 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101c88:	83 c4 10             	add    $0x10,%esp
f0101c8b:	f6 00 02             	testb  $0x2,(%eax)
f0101c8e:	75 19                	jne    f0101ca9 <mem_init+0xaa1>
f0101c90:	68 78 69 10 f0       	push   $0xf0106978
f0101c95:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101c9a:	68 e3 03 00 00       	push   $0x3e3
f0101c9f:	68 09 6f 10 f0       	push   $0xf0106f09
f0101ca4:	e8 97 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ca9:	83 ec 04             	sub    $0x4,%esp
f0101cac:	6a 00                	push   $0x0
f0101cae:	68 00 10 00 00       	push   $0x1000
f0101cb3:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101cb9:	e8 a2 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101cbe:	83 c4 10             	add    $0x10,%esp
f0101cc1:	f6 00 04             	testb  $0x4,(%eax)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xad7>
f0101cc6:	68 ac 69 10 f0       	push   $0xf01069ac
f0101ccb:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101cd0:	68 e4 03 00 00       	push   $0x3e4
f0101cd5:	68 09 6f 10 f0       	push   $0xf0106f09
f0101cda:	e8 61 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101cdf:	6a 02                	push   $0x2
f0101ce1:	68 00 00 40 00       	push   $0x400000
f0101ce6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ce9:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101cef:	e8 39 f4 ff ff       	call   f010112d <page_insert>
f0101cf4:	83 c4 10             	add    $0x10,%esp
f0101cf7:	85 c0                	test   %eax,%eax
f0101cf9:	78 19                	js     f0101d14 <mem_init+0xb0c>
f0101cfb:	68 e4 69 10 f0       	push   $0xf01069e4
f0101d00:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101d05:	68 e7 03 00 00       	push   $0x3e7
f0101d0a:	68 09 6f 10 f0       	push   $0xf0106f09
f0101d0f:	e8 2c e3 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d14:	6a 02                	push   $0x2
f0101d16:	68 00 10 00 00       	push   $0x1000
f0101d1b:	53                   	push   %ebx
f0101d1c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d22:	e8 06 f4 ff ff       	call   f010112d <page_insert>
f0101d27:	83 c4 10             	add    $0x10,%esp
f0101d2a:	85 c0                	test   %eax,%eax
f0101d2c:	74 19                	je     f0101d47 <mem_init+0xb3f>
f0101d2e:	68 20 6a 10 f0       	push   $0xf0106a20
f0101d33:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101d38:	68 ea 03 00 00       	push   $0x3ea
f0101d3d:	68 09 6f 10 f0       	push   $0xf0106f09
f0101d42:	e8 f9 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d47:	83 ec 04             	sub    $0x4,%esp
f0101d4a:	6a 00                	push   $0x0
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d57:	e8 04 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101d5c:	83 c4 10             	add    $0x10,%esp
f0101d5f:	f6 00 04             	testb  $0x4,(%eax)
f0101d62:	74 19                	je     f0101d7d <mem_init+0xb75>
f0101d64:	68 ac 69 10 f0       	push   $0xf01069ac
f0101d69:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101d6e:	68 eb 03 00 00       	push   $0x3eb
f0101d73:	68 09 6f 10 f0       	push   $0xf0106f09
f0101d78:	e8 c3 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d7d:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101d83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d88:	89 f8                	mov    %edi,%eax
f0101d8a:	e8 ae ec ff ff       	call   f0100a3d <check_va2pa>
f0101d8f:	89 c1                	mov    %eax,%ecx
f0101d91:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d94:	89 d8                	mov    %ebx,%eax
f0101d96:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101d9c:	c1 f8 03             	sar    $0x3,%eax
f0101d9f:	c1 e0 0c             	shl    $0xc,%eax
f0101da2:	39 c1                	cmp    %eax,%ecx
f0101da4:	74 19                	je     f0101dbf <mem_init+0xbb7>
f0101da6:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0101dab:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101db0:	68 ee 03 00 00       	push   $0x3ee
f0101db5:	68 09 6f 10 f0       	push   $0xf0106f09
f0101dba:	e8 81 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc4:	89 f8                	mov    %edi,%eax
f0101dc6:	e8 72 ec ff ff       	call   f0100a3d <check_va2pa>
f0101dcb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101dce:	74 19                	je     f0101de9 <mem_init+0xbe1>
f0101dd0:	68 88 6a 10 f0       	push   $0xf0106a88
f0101dd5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101dda:	68 ef 03 00 00       	push   $0x3ef
f0101ddf:	68 09 6f 10 f0       	push   $0xf0106f09
f0101de4:	e8 57 e2 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101de9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dee:	74 19                	je     f0101e09 <mem_init+0xc01>
f0101df0:	68 3d 71 10 f0       	push   $0xf010713d
f0101df5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101dfa:	68 f1 03 00 00       	push   $0x3f1
f0101dff:	68 09 6f 10 f0       	push   $0xf0106f09
f0101e04:	e8 37 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e09:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e0e:	74 19                	je     f0101e29 <mem_init+0xc21>
f0101e10:	68 4e 71 10 f0       	push   $0xf010714e
f0101e15:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101e1a:	68 f2 03 00 00       	push   $0x3f2
f0101e1f:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101e3e:	68 b8 6a 10 f0       	push   $0xf0106ab8
f0101e43:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101e48:	68 f5 03 00 00       	push   $0x3f5
f0101e4d:	68 09 6f 10 f0       	push   $0xf0106f09
f0101e52:	e8 e9 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e57:	83 ec 08             	sub    $0x8,%esp
f0101e5a:	6a 00                	push   $0x0
f0101e5c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e62:	e8 79 f2 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e67:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101e6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e72:	89 f8                	mov    %edi,%eax
f0101e74:	e8 c4 eb ff ff       	call   f0100a3d <check_va2pa>
f0101e79:	83 c4 10             	add    $0x10,%esp
f0101e7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xc92>
f0101e81:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101e86:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101e8b:	68 f9 03 00 00       	push   $0x3f9
f0101e90:	68 09 6f 10 f0       	push   $0xf0106f09
f0101e95:	e8 a6 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e9f:	89 f8                	mov    %edi,%eax
f0101ea1:	e8 97 eb ff ff       	call   f0100a3d <check_va2pa>
f0101ea6:	89 da                	mov    %ebx,%edx
f0101ea8:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101eae:	c1 fa 03             	sar    $0x3,%edx
f0101eb1:	c1 e2 0c             	shl    $0xc,%edx
f0101eb4:	39 d0                	cmp    %edx,%eax
f0101eb6:	74 19                	je     f0101ed1 <mem_init+0xcc9>
f0101eb8:	68 88 6a 10 f0       	push   $0xf0106a88
f0101ebd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101ec2:	68 fa 03 00 00       	push   $0x3fa
f0101ec7:	68 09 6f 10 f0       	push   $0xf0106f09
f0101ecc:	e8 6f e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ed1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ed6:	74 19                	je     f0101ef1 <mem_init+0xce9>
f0101ed8:	68 f4 70 10 f0       	push   $0xf01070f4
f0101edd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101ee2:	68 fb 03 00 00       	push   $0x3fb
f0101ee7:	68 09 6f 10 f0       	push   $0xf0106f09
f0101eec:	e8 4f e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ef1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ef6:	74 19                	je     f0101f11 <mem_init+0xd09>
f0101ef8:	68 4e 71 10 f0       	push   $0xf010714e
f0101efd:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101f02:	68 fc 03 00 00       	push   $0x3fc
f0101f07:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0101f26:	68 00 6b 10 f0       	push   $0xf0106b00
f0101f2b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101f30:	68 ff 03 00 00       	push   $0x3ff
f0101f35:	68 09 6f 10 f0       	push   $0xf0106f09
f0101f3a:	e8 01 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101f3f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f44:	75 19                	jne    f0101f5f <mem_init+0xd57>
f0101f46:	68 5f 71 10 f0       	push   $0xf010715f
f0101f4b:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101f50:	68 00 04 00 00       	push   $0x400
f0101f55:	68 09 6f 10 f0       	push   $0xf0106f09
f0101f5a:	e8 e1 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101f5f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f62:	74 19                	je     f0101f7d <mem_init+0xd75>
f0101f64:	68 6b 71 10 f0       	push   $0xf010716b
f0101f69:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101f6e:	68 01 04 00 00       	push   $0x401
f0101f73:	68 09 6f 10 f0       	push   $0xf0106f09
f0101f78:	e8 c3 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f7d:	83 ec 08             	sub    $0x8,%esp
f0101f80:	68 00 10 00 00       	push   $0x1000
f0101f85:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101f8b:	e8 50 f1 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f90:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101f96:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f9b:	89 f8                	mov    %edi,%eax
f0101f9d:	e8 9b ea ff ff       	call   f0100a3d <check_va2pa>
f0101fa2:	83 c4 10             	add    $0x10,%esp
f0101fa5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa8:	74 19                	je     f0101fc3 <mem_init+0xdbb>
f0101faa:	68 dc 6a 10 f0       	push   $0xf0106adc
f0101faf:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101fb4:	68 05 04 00 00       	push   $0x405
f0101fb9:	68 09 6f 10 f0       	push   $0xf0106f09
f0101fbe:	e8 7d e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fc3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc8:	89 f8                	mov    %edi,%eax
f0101fca:	e8 6e ea ff ff       	call   f0100a3d <check_va2pa>
f0101fcf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fd2:	74 19                	je     f0101fed <mem_init+0xde5>
f0101fd4:	68 38 6b 10 f0       	push   $0xf0106b38
f0101fd9:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101fde:	68 06 04 00 00       	push   $0x406
f0101fe3:	68 09 6f 10 f0       	push   $0xf0106f09
f0101fe8:	e8 53 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0101fed:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ff2:	74 19                	je     f010200d <mem_init+0xe05>
f0101ff4:	68 80 71 10 f0       	push   $0xf0107180
f0101ff9:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0101ffe:	68 07 04 00 00       	push   $0x407
f0102003:	68 09 6f 10 f0       	push   $0xf0106f09
f0102008:	e8 33 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010200d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102012:	74 19                	je     f010202d <mem_init+0xe25>
f0102014:	68 4e 71 10 f0       	push   $0xf010714e
f0102019:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010201e:	68 08 04 00 00       	push   $0x408
f0102023:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102042:	68 60 6b 10 f0       	push   $0xf0106b60
f0102047:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010204c:	68 0b 04 00 00       	push   $0x40b
f0102051:	68 09 6f 10 f0       	push   $0xf0106f09
f0102056:	e8 e5 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010205b:	83 ec 0c             	sub    $0xc,%esp
f010205e:	6a 00                	push   $0x0
f0102060:	e8 27 ee ff ff       	call   f0100e8c <page_alloc>
f0102065:	83 c4 10             	add    $0x10,%esp
f0102068:	85 c0                	test   %eax,%eax
f010206a:	74 19                	je     f0102085 <mem_init+0xe7d>
f010206c:	68 a2 70 10 f0       	push   $0xf01070a2
f0102071:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102076:	68 0e 04 00 00       	push   $0x40e
f010207b:	68 09 6f 10 f0       	push   $0xf0106f09
f0102080:	e8 bb df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102085:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f010208b:	8b 11                	mov    (%ecx),%edx
f010208d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102093:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102096:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f010209c:	c1 f8 03             	sar    $0x3,%eax
f010209f:	c1 e0 0c             	shl    $0xc,%eax
f01020a2:	39 c2                	cmp    %eax,%edx
f01020a4:	74 19                	je     f01020bf <mem_init+0xeb7>
f01020a6:	68 00 68 10 f0       	push   $0xf0106800
f01020ab:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01020b0:	68 11 04 00 00       	push   $0x411
f01020b5:	68 09 6f 10 f0       	push   $0xf0106f09
f01020ba:	e8 81 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01020bf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020cd:	74 19                	je     f01020e8 <mem_init+0xee0>
f01020cf:	68 05 71 10 f0       	push   $0xf0107105
f01020d4:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01020d9:	68 13 04 00 00       	push   $0x413
f01020de:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102104:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010210a:	e8 51 ee ff ff       	call   f0100f60 <pgdir_walk>
f010210f:	89 c7                	mov    %eax,%edi
f0102111:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102114:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102119:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010211c:	8b 40 04             	mov    0x4(%eax),%eax
f010211f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102124:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f010212a:	89 c2                	mov    %eax,%edx
f010212c:	c1 ea 0c             	shr    $0xc,%edx
f010212f:	83 c4 10             	add    $0x10,%esp
f0102132:	39 ca                	cmp    %ecx,%edx
f0102134:	72 15                	jb     f010214b <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102136:	50                   	push   %eax
f0102137:	68 a4 60 10 f0       	push   $0xf01060a4
f010213c:	68 1a 04 00 00       	push   $0x41a
f0102141:	68 09 6f 10 f0       	push   $0xf0106f09
f0102146:	e8 f5 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010214b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102150:	39 c7                	cmp    %eax,%edi
f0102152:	74 19                	je     f010216d <mem_init+0xf65>
f0102154:	68 91 71 10 f0       	push   $0xf0107191
f0102159:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010215e:	68 1b 04 00 00       	push   $0x41b
f0102163:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102180:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
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
f0102196:	68 a4 60 10 f0       	push   $0xf01060a4
f010219b:	6a 58                	push   $0x58
f010219d:	68 15 6f 10 f0       	push   $0xf0106f15
f01021a2:	e8 99 de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021a7:	83 ec 04             	sub    $0x4,%esp
f01021aa:	68 00 10 00 00       	push   $0x1000
f01021af:	68 ff 00 00 00       	push   $0xff
f01021b4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01021b9:	50                   	push   %eax
f01021ba:	e8 e7 31 00 00       	call   f01053a6 <memset>
	page_free(pp0);
f01021bf:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021c2:	89 3c 24             	mov    %edi,(%esp)
f01021c5:	e8 32 ed ff ff       	call   f0100efc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021ca:	83 c4 0c             	add    $0xc,%esp
f01021cd:	6a 01                	push   $0x1
f01021cf:	6a 00                	push   $0x0
f01021d1:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01021d7:	e8 84 ed ff ff       	call   f0100f60 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021dc:	89 fa                	mov    %edi,%edx
f01021de:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
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
f01021f2:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01021f8:	72 12                	jb     f010220c <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021fa:	52                   	push   %edx
f01021fb:	68 a4 60 10 f0       	push   $0xf01060a4
f0102200:	6a 58                	push   $0x58
f0102202:	68 15 6f 10 f0       	push   $0xf0106f15
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
f0102220:	68 a9 71 10 f0       	push   $0xf01071a9
f0102225:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010222a:	68 25 04 00 00       	push   $0x425
f010222f:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102240:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102245:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010224b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010224e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102254:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102257:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

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
f01022b0:	68 84 6b 10 f0       	push   $0xf0106b84
f01022b5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01022ba:	68 35 04 00 00       	push   $0x435
f01022bf:	68 09 6f 10 f0       	push   $0xf0106f09
f01022c4:	e8 77 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01022c9:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01022cf:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01022d5:	77 08                	ja     f01022df <mem_init+0x10d7>
f01022d7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01022dd:	77 19                	ja     f01022f8 <mem_init+0x10f0>
f01022df:	68 ac 6b 10 f0       	push   $0xf0106bac
f01022e4:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01022e9:	68 36 04 00 00       	push   $0x436
f01022ee:	68 09 6f 10 f0       	push   $0xf0106f09
f01022f3:	e8 48 dd ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01022f8:	89 da                	mov    %ebx,%edx
f01022fa:	09 f2                	or     %esi,%edx
f01022fc:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102302:	74 19                	je     f010231d <mem_init+0x1115>
f0102304:	68 d4 6b 10 f0       	push   $0xf0106bd4
f0102309:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010230e:	68 38 04 00 00       	push   $0x438
f0102313:	68 09 6f 10 f0       	push   $0xf0106f09
f0102318:	e8 23 dd ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010231d:	39 c6                	cmp    %eax,%esi
f010231f:	73 19                	jae    f010233a <mem_init+0x1132>
f0102321:	68 c0 71 10 f0       	push   $0xf01071c0
f0102326:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010232b:	68 3a 04 00 00       	push   $0x43a
f0102330:	68 09 6f 10 f0       	push   $0xf0106f09
f0102335:	e8 06 dd ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010233a:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102340:	89 da                	mov    %ebx,%edx
f0102342:	89 f8                	mov    %edi,%eax
f0102344:	e8 f4 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102349:	85 c0                	test   %eax,%eax
f010234b:	74 19                	je     f0102366 <mem_init+0x115e>
f010234d:	68 fc 6b 10 f0       	push   $0xf0106bfc
f0102352:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102357:	68 3c 04 00 00       	push   $0x43c
f010235c:	68 09 6f 10 f0       	push   $0xf0106f09
f0102361:	e8 da dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102366:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010236c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010236f:	89 c2                	mov    %eax,%edx
f0102371:	89 f8                	mov    %edi,%eax
f0102373:	e8 c5 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102378:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010237d:	74 19                	je     f0102398 <mem_init+0x1190>
f010237f:	68 20 6c 10 f0       	push   $0xf0106c20
f0102384:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102389:	68 3d 04 00 00       	push   $0x43d
f010238e:	68 09 6f 10 f0       	push   $0xf0106f09
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102398:	89 f2                	mov    %esi,%edx
f010239a:	89 f8                	mov    %edi,%eax
f010239c:	e8 9c e6 ff ff       	call   f0100a3d <check_va2pa>
f01023a1:	85 c0                	test   %eax,%eax
f01023a3:	74 19                	je     f01023be <mem_init+0x11b6>
f01023a5:	68 50 6c 10 f0       	push   $0xf0106c50
f01023aa:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01023af:	68 3e 04 00 00       	push   $0x43e
f01023b4:	68 09 6f 10 f0       	push   $0xf0106f09
f01023b9:	e8 82 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01023be:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01023c4:	89 f8                	mov    %edi,%eax
f01023c6:	e8 72 e6 ff ff       	call   f0100a3d <check_va2pa>
f01023cb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023ce:	74 19                	je     f01023e9 <mem_init+0x11e1>
f01023d0:	68 74 6c 10 f0       	push   $0xf0106c74
f01023d5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01023da:	68 3f 04 00 00       	push   $0x43f
f01023df:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01023fd:	68 a0 6c 10 f0       	push   $0xf0106ca0
f0102402:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102407:	68 41 04 00 00       	push   $0x441
f010240c:	68 09 6f 10 f0       	push   $0xf0106f09
f0102411:	e8 2a dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102416:	83 ec 04             	sub    $0x4,%esp
f0102419:	6a 00                	push   $0x0
f010241b:	53                   	push   %ebx
f010241c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102422:	e8 39 eb ff ff       	call   f0100f60 <pgdir_walk>
f0102427:	8b 00                	mov    (%eax),%eax
f0102429:	83 c4 10             	add    $0x10,%esp
f010242c:	83 e0 04             	and    $0x4,%eax
f010242f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102432:	74 19                	je     f010244d <mem_init+0x1245>
f0102434:	68 e4 6c 10 f0       	push   $0xf0106ce4
f0102439:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010243e:	68 42 04 00 00       	push   $0x442
f0102443:	68 09 6f 10 f0       	push   $0xf0106f09
f0102448:	e8 f3 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010244d:	83 ec 04             	sub    $0x4,%esp
f0102450:	6a 00                	push   $0x0
f0102452:	53                   	push   %ebx
f0102453:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102459:	e8 02 eb ff ff       	call   f0100f60 <pgdir_walk>
f010245e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102464:	83 c4 0c             	add    $0xc,%esp
f0102467:	6a 00                	push   $0x0
f0102469:	ff 75 d4             	pushl  -0x2c(%ebp)
f010246c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102472:	e8 e9 ea ff ff       	call   f0100f60 <pgdir_walk>
f0102477:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010247d:	83 c4 0c             	add    $0xc,%esp
f0102480:	6a 00                	push   $0x0
f0102482:	56                   	push   %esi
f0102483:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102489:	e8 d2 ea ff ff       	call   f0100f60 <pgdir_walk>
f010248e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102494:	c7 04 24 d2 71 10 f0 	movl   $0xf01071d2,(%esp)
f010249b:	e8 14 11 00 00       	call   f01035b4 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f01024a0:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
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
f01024b0:	68 c8 60 10 f0       	push   $0xf01060c8
f01024b5:	68 b9 00 00 00       	push   $0xb9
f01024ba:	68 09 6f 10 f0       	push   $0xf0106f09
f01024bf:	e8 7c db ff ff       	call   f0100040 <_panic>
f01024c4:	83 ec 08             	sub    $0x8,%esp
f01024c7:	6a 05                	push   $0x5
f01024c9:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ce:	50                   	push   %eax
f01024cf:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01024d4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024d9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01024de:	e8 10 eb ff ff       	call   f0100ff3 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U|PTE_P);
f01024e3:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
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
f01024f3:	68 c8 60 10 f0       	push   $0xf01060c8
f01024f8:	68 c1 00 00 00       	push   $0xc1
f01024fd:	68 09 6f 10 f0       	push   $0xf0106f09
f0102502:	e8 39 db ff ff       	call   f0100040 <_panic>
f0102507:	83 ec 08             	sub    $0x8,%esp
f010250a:	6a 05                	push   $0x5
f010250c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102511:	50                   	push   %eax
f0102512:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102517:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010251c:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102521:	e8 cd ea ff ff       	call   f0100ff3 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102526:	83 c4 10             	add    $0x10,%esp
f0102529:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f010252e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102533:	77 15                	ja     f010254a <mem_init+0x1342>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102535:	50                   	push   %eax
f0102536:	68 c8 60 10 f0       	push   $0xf01060c8
f010253b:	68 cd 00 00 00       	push   $0xcd
f0102540:	68 09 6f 10 f0       	push   $0xf0106f09
f0102545:	e8 f6 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f010254a:	83 ec 08             	sub    $0x8,%esp
f010254d:	6a 03                	push   $0x3
f010254f:	68 00 60 11 00       	push   $0x116000
f0102554:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102559:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010255e:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
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
f0102579:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010257e:	e8 70 ea ff ff       	call   f0100ff3 <boot_map_region>
f0102583:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f010258a:	83 c4 10             	add    $0x10,%esp
f010258d:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
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
f01025a0:	68 c8 60 10 f0       	push   $0xf01060c8
f01025a5:	68 0f 01 00 00       	push   $0x10f
f01025aa:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01025c7:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
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
f01025e0:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f01025e5:	39 d8                	cmp    %ebx,%eax
f01025e7:	75 ae                	jne    f0102597 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025e9:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01025ef:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f01025f4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01025f7:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01025fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102603:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102606:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
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
f010262d:	68 c8 60 10 f0       	push   $0xf01060c8
f0102632:	68 5b 03 00 00       	push   $0x35b
f0102637:	68 09 6f 10 f0       	push   $0xf0106f09
f010263c:	e8 ff d9 ff ff       	call   f0100040 <_panic>
f0102641:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102648:	39 c2                	cmp    %eax,%edx
f010264a:	74 19                	je     f0102665 <mem_init+0x145d>
f010264c:	68 18 6d 10 f0       	push   $0xf0106d18
f0102651:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102656:	68 5b 03 00 00       	push   $0x35b
f010265b:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102670:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
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
f0102691:	68 c8 60 10 f0       	push   $0xf01060c8
f0102696:	68 60 03 00 00       	push   $0x360
f010269b:	68 09 6f 10 f0       	push   $0xf0106f09
f01026a0:	e8 9b d9 ff ff       	call   f0100040 <_panic>
f01026a5:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01026ac:	39 d0                	cmp    %edx,%eax
f01026ae:	74 19                	je     f01026c9 <mem_init+0x14c1>
f01026b0:	68 4c 6d 10 f0       	push   $0xf0106d4c
f01026b5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01026ba:	68 60 03 00 00       	push   $0x360
f01026bf:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01026f5:	68 80 6d 10 f0       	push   $0xf0106d80
f01026fa:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01026ff:	68 64 03 00 00       	push   $0x364
f0102704:	68 09 6f 10 f0       	push   $0xf0106f09
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
f010274e:	68 c8 60 10 f0       	push   $0xf01060c8
f0102753:	68 6c 03 00 00       	push   $0x36c
f0102758:	68 09 6f 10 f0       	push   $0xf0106f09
f010275d:	e8 de d8 ff ff       	call   f0100040 <_panic>
f0102762:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102765:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f010276c:	39 d0                	cmp    %edx,%eax
f010276e:	74 19                	je     f0102789 <mem_init+0x1581>
f0102770:	68 a8 6d 10 f0       	push   $0xf0106da8
f0102775:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010277a:	68 6c 03 00 00       	push   $0x36c
f010277f:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01027b0:	68 f0 6d 10 f0       	push   $0xf0106df0
f01027b5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f01027ba:	68 6e 03 00 00       	push   $0x36e
f01027bf:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01027ea:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
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
f010280f:	68 eb 71 10 f0       	push   $0xf01071eb
f0102814:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102819:	68 79 03 00 00       	push   $0x379
f010281e:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102837:	68 eb 71 10 f0       	push   $0xf01071eb
f010283c:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102841:	68 7d 03 00 00       	push   $0x37d
f0102846:	68 09 6f 10 f0       	push   $0xf0106f09
f010284b:	e8 f0 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102850:	f6 c2 02             	test   $0x2,%dl
f0102853:	75 38                	jne    f010288d <mem_init+0x1685>
f0102855:	68 fc 71 10 f0       	push   $0xf01071fc
f010285a:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010285f:	68 7e 03 00 00       	push   $0x37e
f0102864:	68 09 6f 10 f0       	push   $0xf0106f09
f0102869:	e8 d2 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010286e:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102872:	74 19                	je     f010288d <mem_init+0x1685>
f0102874:	68 0d 72 10 f0       	push   $0xf010720d
f0102879:	68 2f 6f 10 f0       	push   $0xf0106f2f
f010287e:	68 80 03 00 00       	push   $0x380
f0102883:	68 09 6f 10 f0       	push   $0xf0106f09
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
f010289e:	68 14 6e 10 f0       	push   $0xf0106e14
f01028a3:	e8 0c 0d 00 00       	call   f01035b4 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028a8:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
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
f01028b8:	68 c8 60 10 f0       	push   $0xf01060c8
f01028bd:	68 e5 00 00 00       	push   $0xe5
f01028c2:	68 09 6f 10 f0       	push   $0xf0106f09
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
f01028ff:	68 f7 6f 10 f0       	push   $0xf0106ff7
f0102904:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102909:	68 57 04 00 00       	push   $0x457
f010290e:	68 09 6f 10 f0       	push   $0xf0106f09
f0102913:	e8 28 d7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102918:	83 ec 0c             	sub    $0xc,%esp
f010291b:	6a 00                	push   $0x0
f010291d:	e8 6a e5 ff ff       	call   f0100e8c <page_alloc>
f0102922:	89 c7                	mov    %eax,%edi
f0102924:	83 c4 10             	add    $0x10,%esp
f0102927:	85 c0                	test   %eax,%eax
f0102929:	75 19                	jne    f0102944 <mem_init+0x173c>
f010292b:	68 0d 70 10 f0       	push   $0xf010700d
f0102930:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102935:	68 58 04 00 00       	push   $0x458
f010293a:	68 09 6f 10 f0       	push   $0xf0106f09
f010293f:	e8 fc d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102944:	83 ec 0c             	sub    $0xc,%esp
f0102947:	6a 00                	push   $0x0
f0102949:	e8 3e e5 ff ff       	call   f0100e8c <page_alloc>
f010294e:	89 c6                	mov    %eax,%esi
f0102950:	83 c4 10             	add    $0x10,%esp
f0102953:	85 c0                	test   %eax,%eax
f0102955:	75 19                	jne    f0102970 <mem_init+0x1768>
f0102957:	68 23 70 10 f0       	push   $0xf0107023
f010295c:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102961:	68 59 04 00 00       	push   $0x459
f0102966:	68 09 6f 10 f0       	push   $0xf0106f09
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
f010297b:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
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
f010298f:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102995:	72 12                	jb     f01029a9 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102997:	50                   	push   %eax
f0102998:	68 a4 60 10 f0       	push   $0xf01060a4
f010299d:	6a 58                	push   $0x58
f010299f:	68 15 6f 10 f0       	push   $0xf0106f15
f01029a4:	e8 97 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029a9:	83 ec 04             	sub    $0x4,%esp
f01029ac:	68 00 10 00 00       	push   $0x1000
f01029b1:	6a 01                	push   $0x1
f01029b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029b8:	50                   	push   %eax
f01029b9:	e8 e8 29 00 00       	call   f01053a6 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029be:	89 f0                	mov    %esi,%eax
f01029c0:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
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
f01029d4:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f01029da:	72 12                	jb     f01029ee <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029dc:	50                   	push   %eax
f01029dd:	68 a4 60 10 f0       	push   $0xf01060a4
f01029e2:	6a 58                	push   $0x58
f01029e4:	68 15 6f 10 f0       	push   $0xf0106f15
f01029e9:	e8 52 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01029ee:	83 ec 04             	sub    $0x4,%esp
f01029f1:	68 00 10 00 00       	push   $0x1000
f01029f6:	6a 02                	push   $0x2
f01029f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029fd:	50                   	push   %eax
f01029fe:	e8 a3 29 00 00       	call   f01053a6 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a03:	6a 02                	push   $0x2
f0102a05:	68 00 10 00 00       	push   $0x1000
f0102a0a:	57                   	push   %edi
f0102a0b:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102a11:	e8 17 e7 ff ff       	call   f010112d <page_insert>
	assert(pp1->pp_ref == 1);
f0102a16:	83 c4 20             	add    $0x20,%esp
f0102a19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a1e:	74 19                	je     f0102a39 <mem_init+0x1831>
f0102a20:	68 f4 70 10 f0       	push   $0xf01070f4
f0102a25:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102a2a:	68 5e 04 00 00       	push   $0x45e
f0102a2f:	68 09 6f 10 f0       	push   $0xf0106f09
f0102a34:	e8 07 d6 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a39:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a40:	01 01 01 
f0102a43:	74 19                	je     f0102a5e <mem_init+0x1856>
f0102a45:	68 34 6e 10 f0       	push   $0xf0106e34
f0102a4a:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102a4f:	68 5f 04 00 00       	push   $0x45f
f0102a54:	68 09 6f 10 f0       	push   $0xf0106f09
f0102a59:	e8 e2 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a5e:	6a 02                	push   $0x2
f0102a60:	68 00 10 00 00       	push   $0x1000
f0102a65:	56                   	push   %esi
f0102a66:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102a6c:	e8 bc e6 ff ff       	call   f010112d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a71:	83 c4 10             	add    $0x10,%esp
f0102a74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a7b:	02 02 02 
f0102a7e:	74 19                	je     f0102a99 <mem_init+0x1891>
f0102a80:	68 58 6e 10 f0       	push   $0xf0106e58
f0102a85:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102a8a:	68 61 04 00 00       	push   $0x461
f0102a8f:	68 09 6f 10 f0       	push   $0xf0106f09
f0102a94:	e8 a7 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102a99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102a9e:	74 19                	je     f0102ab9 <mem_init+0x18b1>
f0102aa0:	68 16 71 10 f0       	push   $0xf0107116
f0102aa5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102aaa:	68 62 04 00 00       	push   $0x462
f0102aaf:	68 09 6f 10 f0       	push   $0xf0106f09
f0102ab4:	e8 87 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ab9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102abe:	74 19                	je     f0102ad9 <mem_init+0x18d1>
f0102ac0:	68 80 71 10 f0       	push   $0xf0107180
f0102ac5:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102aca:	68 63 04 00 00       	push   $0x463
f0102acf:	68 09 6f 10 f0       	push   $0xf0106f09
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
f0102ae5:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102aeb:	c1 f8 03             	sar    $0x3,%eax
f0102aee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af1:	89 c2                	mov    %eax,%edx
f0102af3:	c1 ea 0c             	shr    $0xc,%edx
f0102af6:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102afc:	72 12                	jb     f0102b10 <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afe:	50                   	push   %eax
f0102aff:	68 a4 60 10 f0       	push   $0xf01060a4
f0102b04:	6a 58                	push   $0x58
f0102b06:	68 15 6f 10 f0       	push   $0xf0106f15
f0102b0b:	e8 30 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b10:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b17:	03 03 03 
f0102b1a:	74 19                	je     f0102b35 <mem_init+0x192d>
f0102b1c:	68 7c 6e 10 f0       	push   $0xf0106e7c
f0102b21:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102b26:	68 65 04 00 00       	push   $0x465
f0102b2b:	68 09 6f 10 f0       	push   $0xf0106f09
f0102b30:	e8 0b d5 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b35:	83 ec 08             	sub    $0x8,%esp
f0102b38:	68 00 10 00 00       	push   $0x1000
f0102b3d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b43:	e8 98 e5 ff ff       	call   f01010e0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b48:	83 c4 10             	add    $0x10,%esp
f0102b4b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b50:	74 19                	je     f0102b6b <mem_init+0x1963>
f0102b52:	68 4e 71 10 f0       	push   $0xf010714e
f0102b57:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102b5c:	68 67 04 00 00       	push   $0x467
f0102b61:	68 09 6f 10 f0       	push   $0xf0106f09
f0102b66:	e8 d5 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b6b:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102b71:	8b 11                	mov    (%ecx),%edx
f0102b73:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b79:	89 d8                	mov    %ebx,%eax
f0102b7b:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102b81:	c1 f8 03             	sar    $0x3,%eax
f0102b84:	c1 e0 0c             	shl    $0xc,%eax
f0102b87:	39 c2                	cmp    %eax,%edx
f0102b89:	74 19                	je     f0102ba4 <mem_init+0x199c>
f0102b8b:	68 00 68 10 f0       	push   $0xf0106800
f0102b90:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102b95:	68 6a 04 00 00       	push   $0x46a
f0102b9a:	68 09 6f 10 f0       	push   $0xf0106f09
f0102b9f:	e8 9c d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102ba4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102baa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102baf:	74 19                	je     f0102bca <mem_init+0x19c2>
f0102bb1:	68 05 71 10 f0       	push   $0xf0107105
f0102bb6:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0102bbb:	68 6c 04 00 00       	push   $0x46c
f0102bc0:	68 09 6f 10 f0       	push   $0xf0106f09
f0102bc5:	e8 76 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102bca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102bd0:	83 ec 0c             	sub    $0xc,%esp
f0102bd3:	53                   	push   %ebx
f0102bd4:	e8 23 e3 ff ff       	call   f0100efc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bd9:	c7 04 24 a8 6e 10 f0 	movl   $0xf0106ea8,(%esp)
f0102be0:	e8 cf 09 00 00       	call   f01035b4 <cprintf>
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
f0102c1b:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
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
f0102c45:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
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
f0102c97:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102c9d:	ff 73 48             	pushl  0x48(%ebx)
f0102ca0:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0102ca5:	e8 0a 09 00 00       	call   f01035b4 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102caa:	89 1c 24             	mov    %ebx,(%esp)
f0102cad:	e8 1f 06 00 00       	call   f01032d1 <env_destroy>
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
f0102cf5:	68 1c 72 10 f0       	push   $0xf010721c
f0102cfa:	68 27 01 00 00       	push   $0x127
f0102cff:	68 79 72 10 f0       	push   $0xf0107279
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
f0102d1f:	68 44 72 10 f0       	push   $0xf0107244
f0102d24:	68 2c 01 00 00       	push   $0x12c
f0102d29:	68 79 72 10 f0       	push   $0xf0107279
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
f0102d54:	e8 82 2c 00 00       	call   f01059db <cpunum>
f0102d59:	6b c0 74             	imul   $0x74,%eax,%eax
f0102d5c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
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
f0102d79:	03 1d 44 f2 22 f0    	add    0xf022f244,%ebx
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
f0102d9e:	e8 38 2c 00 00       	call   f01059db <cpunum>
f0102da3:	6b c0 74             	imul   $0x74,%eax,%eax
f0102da6:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102dac:	74 26                	je     f0102dd4 <envid2env+0x8f>
f0102dae:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102db1:	e8 25 2c 00 00       	call   f01059db <cpunum>
f0102db6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102db9:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
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
f0102de5:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
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
f0102e17:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
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
f0102e47:	89 35 48 f2 22 f0    	mov    %esi,0xf022f248
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
f0102e5d:	8b 1d 48 f2 22 f0    	mov    0xf022f248,%ebx
f0102e63:	85 db                	test   %ebx,%ebx
f0102e65:	0f 84 69 01 00 00    	je     f0102fd4 <env_alloc+0x17e>
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
f0102e7a:	0f 84 5b 01 00 00    	je     f0102fdb <env_alloc+0x185>
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
f0102e85:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102e8b:	c1 f8 03             	sar    $0x3,%eax
f0102e8e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e91:	89 c2                	mov    %eax,%edx
f0102e93:	c1 ea 0c             	shr    $0xc,%edx
f0102e96:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102e9c:	72 12                	jb     f0102eb0 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e9e:	50                   	push   %eax
f0102e9f:	68 a4 60 10 f0       	push   $0xf01060a4
f0102ea4:	6a 58                	push   $0x58
f0102ea6:	68 15 6f 10 f0       	push   $0xf0106f15
f0102eab:	e8 90 d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102eb0:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f0102eb5:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102eb8:	83 ec 04             	sub    $0x4,%esp
f0102ebb:	68 00 10 00 00       	push   $0x1000
f0102ec0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102ec6:	50                   	push   %eax
f0102ec7:	e8 8f 25 00 00       	call   f010545b <memcpy>
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
f0102eda:	68 c8 60 10 f0       	push   $0xf01060c8
f0102edf:	68 c7 00 00 00       	push   $0xc7
f0102ee4:	68 79 72 10 f0       	push   $0xf0107279
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
f0102f14:	2b 15 44 f2 22 f0    	sub    0xf022f244,%edx
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
f0102f4b:	e8 56 24 00 00       	call   f01053a6 <memset>
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
	e->env_tf.tf_eflags|=FL_IF;
f0102f6f:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102f76:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102f7d:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102f81:	8b 43 44             	mov    0x44(%ebx),%eax
f0102f84:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
	*newenv_store = e;
f0102f89:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f8e:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102f91:	e8 45 2a 00 00       	call   f01059db <cpunum>
f0102f96:	6b c0 74             	imul   $0x74,%eax,%eax
f0102f99:	83 c4 10             	add    $0x10,%esp
f0102f9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fa1:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0102fa8:	74 11                	je     f0102fbb <env_alloc+0x165>
f0102faa:	e8 2c 2a 00 00       	call   f01059db <cpunum>
f0102faf:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fb2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102fb8:	8b 50 48             	mov    0x48(%eax),%edx
f0102fbb:	83 ec 04             	sub    $0x4,%esp
f0102fbe:	53                   	push   %ebx
f0102fbf:	52                   	push   %edx
f0102fc0:	68 84 72 10 f0       	push   $0xf0107284
f0102fc5:	e8 ea 05 00 00       	call   f01035b4 <cprintf>
	return 0;
f0102fca:	83 c4 10             	add    $0x10,%esp
f0102fcd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fd2:	eb 0c                	jmp    f0102fe0 <env_alloc+0x18a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102fd4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102fd9:	eb 05                	jmp    f0102fe0 <env_alloc+0x18a>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102fdb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102fe0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102fe3:	c9                   	leave  
f0102fe4:	c3                   	ret    

f0102fe5 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102fe5:	55                   	push   %ebp
f0102fe6:	89 e5                	mov    %esp,%ebp
f0102fe8:	57                   	push   %edi
f0102fe9:	56                   	push   %esi
f0102fea:	53                   	push   %ebx
f0102feb:	83 ec 34             	sub    $0x34,%esp
f0102fee:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f0102ff1:	6a 00                	push   $0x0
f0102ff3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ff6:	50                   	push   %eax
f0102ff7:	e8 5a fe ff ff       	call   f0102e56 <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f0102ffc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f0103002:	83 c4 10             	add    $0x10,%esp
f0103005:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010300b:	74 17                	je     f0103024 <env_create+0x3f>
		panic("binary document is error\n");
f010300d:	83 ec 04             	sub    $0x4,%esp
f0103010:	68 99 72 10 f0       	push   $0xf0107299
f0103015:	68 71 01 00 00       	push   $0x171
f010301a:	68 79 72 10 f0       	push   $0xf0107279
f010301f:	e8 1c d0 ff ff       	call   f0100040 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
f0103024:	89 fb                	mov    %edi,%ebx
f0103026:	03 5f 1c             	add    0x1c(%edi),%ebx
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
f0103029:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010302c:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010302f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103034:	77 15                	ja     f010304b <env_create+0x66>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103036:	50                   	push   %eax
f0103037:	68 c8 60 10 f0       	push   $0xf01060c8
f010303c:	68 74 01 00 00       	push   $0x174
f0103041:	68 79 72 10 f0       	push   $0xf0107279
f0103046:	e8 f5 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010304b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103050:	0f 22 d8             	mov    %eax,%cr3
	for(i=0;i<elf->e_phnum;i++)
f0103053:	be 00 00 00 00       	mov    $0x0,%esi
f0103058:	eb 40                	jmp    f010309a <env_create+0xb5>
	{
		if(ph->p_type==ELF_PROG_LOAD)
f010305a:	83 3b 01             	cmpl   $0x1,(%ebx)
f010305d:	75 35                	jne    f0103094 <env_create+0xaf>
		{
			//cprintf("load\n");
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f010305f:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103062:	8b 53 08             	mov    0x8(%ebx),%edx
f0103065:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103068:	e8 4d fc ff ff       	call   f0102cba <region_alloc>
			memset((void *)(ph->p_va),0,ph->p_memsz);
f010306d:	83 ec 04             	sub    $0x4,%esp
f0103070:	ff 73 14             	pushl  0x14(%ebx)
f0103073:	6a 00                	push   $0x0
f0103075:	ff 73 08             	pushl  0x8(%ebx)
f0103078:	e8 29 23 00 00       	call   f01053a6 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f010307d:	83 c4 0c             	add    $0xc,%esp
f0103080:	ff 73 10             	pushl  0x10(%ebx)
f0103083:	89 f8                	mov    %edi,%eax
f0103085:	03 43 04             	add    0x4(%ebx),%eax
f0103088:	50                   	push   %eax
f0103089:	ff 73 08             	pushl  0x8(%ebx)
f010308c:	e8 ca 23 00 00       	call   f010545b <memcpy>
f0103091:	83 c4 10             	add    $0x10,%esp
			//cprintf("%08x\n",ph->p_va);
		}
		ph++;
f0103094:	83 c3 20             	add    $0x20,%ebx
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
	for(i=0;i<elf->e_phnum;i++)
f0103097:	83 c6 01             	add    $0x1,%esi
f010309a:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f010309e:	39 c6                	cmp    %eax,%esi
f01030a0:	72 b8                	jb     f010305a <env_create+0x75>
		}
		ph++;
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	e->env_tf.tf_eip=elf->e_entry;
f01030a2:	8b 47 18             	mov    0x18(%edi),%eax
f01030a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01030a8:	89 47 30             	mov    %eax,0x30(%edi)
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f01030ab:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01030b0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01030b5:	89 f8                	mov    %edi,%eax
f01030b7:	e8 fe fb ff ff       	call   f0102cba <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01030bc:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030c1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030c6:	77 15                	ja     f01030dd <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030c8:	50                   	push   %eax
f01030c9:	68 c8 60 10 f0       	push   $0xf01060c8
f01030ce:	68 86 01 00 00       	push   $0x186
f01030d3:	68 79 72 10 f0       	push   $0xf0107279
f01030d8:	e8 63 cf ff ff       	call   f0100040 <_panic>
f01030dd:	05 00 00 00 10       	add    $0x10000000,%eax
f01030e2:	0f 22 d8             	mov    %eax,%cr3
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f01030e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030eb:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f01030ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030f1:	5b                   	pop    %ebx
f01030f2:	5e                   	pop    %esi
f01030f3:	5f                   	pop    %edi
f01030f4:	5d                   	pop    %ebp
f01030f5:	c3                   	ret    

f01030f6 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01030f6:	55                   	push   %ebp
f01030f7:	89 e5                	mov    %esp,%ebp
f01030f9:	57                   	push   %edi
f01030fa:	56                   	push   %esi
f01030fb:	53                   	push   %ebx
f01030fc:	83 ec 1c             	sub    $0x1c,%esp
f01030ff:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103102:	e8 d4 28 00 00       	call   f01059db <cpunum>
f0103107:	6b c0 74             	imul   $0x74,%eax,%eax
f010310a:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f0103110:	75 29                	jne    f010313b <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f0103112:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103117:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010311c:	77 15                	ja     f0103133 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010311e:	50                   	push   %eax
f010311f:	68 c8 60 10 f0       	push   $0xf01060c8
f0103124:	68 ad 01 00 00       	push   $0x1ad
f0103129:	68 79 72 10 f0       	push   $0xf0107279
f010312e:	e8 0d cf ff ff       	call   f0100040 <_panic>
f0103133:	05 00 00 00 10       	add    $0x10000000,%eax
f0103138:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010313b:	8b 5f 48             	mov    0x48(%edi),%ebx
f010313e:	e8 98 28 00 00       	call   f01059db <cpunum>
f0103143:	6b c0 74             	imul   $0x74,%eax,%eax
f0103146:	ba 00 00 00 00       	mov    $0x0,%edx
f010314b:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103152:	74 11                	je     f0103165 <env_free+0x6f>
f0103154:	e8 82 28 00 00       	call   f01059db <cpunum>
f0103159:	6b c0 74             	imul   $0x74,%eax,%eax
f010315c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103162:	8b 50 48             	mov    0x48(%eax),%edx
f0103165:	83 ec 04             	sub    $0x4,%esp
f0103168:	53                   	push   %ebx
f0103169:	52                   	push   %edx
f010316a:	68 b3 72 10 f0       	push   $0xf01072b3
f010316f:	e8 40 04 00 00       	call   f01035b4 <cprintf>
f0103174:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103177:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010317e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103181:	89 d0                	mov    %edx,%eax
f0103183:	c1 e0 02             	shl    $0x2,%eax
f0103186:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103189:	8b 47 60             	mov    0x60(%edi),%eax
f010318c:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010318f:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103195:	0f 84 a8 00 00 00    	je     f0103243 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010319b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031a1:	89 f0                	mov    %esi,%eax
f01031a3:	c1 e8 0c             	shr    $0xc,%eax
f01031a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01031a9:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f01031af:	77 15                	ja     f01031c6 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031b1:	56                   	push   %esi
f01031b2:	68 a4 60 10 f0       	push   $0xf01060a4
f01031b7:	68 bc 01 00 00       	push   $0x1bc
f01031bc:	68 79 72 10 f0       	push   $0xf0107279
f01031c1:	e8 7a ce ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031c9:	c1 e0 16             	shl    $0x16,%eax
f01031cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031cf:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01031d4:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01031db:	01 
f01031dc:	74 17                	je     f01031f5 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031de:	83 ec 08             	sub    $0x8,%esp
f01031e1:	89 d8                	mov    %ebx,%eax
f01031e3:	c1 e0 0c             	shl    $0xc,%eax
f01031e6:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01031e9:	50                   	push   %eax
f01031ea:	ff 77 60             	pushl  0x60(%edi)
f01031ed:	e8 ee de ff ff       	call   f01010e0 <page_remove>
f01031f2:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031f5:	83 c3 01             	add    $0x1,%ebx
f01031f8:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01031fe:	75 d4                	jne    f01031d4 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103200:	8b 47 60             	mov    0x60(%edi),%eax
f0103203:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103206:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010320d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103210:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103216:	72 14                	jb     f010322c <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103218:	83 ec 04             	sub    $0x4,%esp
f010321b:	68 ac 66 10 f0       	push   $0xf01066ac
f0103220:	6a 51                	push   $0x51
f0103222:	68 15 6f 10 f0       	push   $0xf0106f15
f0103227:	e8 14 ce ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f010322c:	83 ec 0c             	sub    $0xc,%esp
f010322f:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0103234:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103237:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f010323a:	50                   	push   %eax
f010323b:	e8 f9 dc ff ff       	call   f0100f39 <page_decref>
f0103240:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103243:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103247:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010324a:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010324f:	0f 85 29 ff ff ff    	jne    f010317e <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103255:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103258:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010325d:	77 15                	ja     f0103274 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010325f:	50                   	push   %eax
f0103260:	68 c8 60 10 f0       	push   $0xf01060c8
f0103265:	68 ca 01 00 00       	push   $0x1ca
f010326a:	68 79 72 10 f0       	push   $0xf0107279
f010326f:	e8 cc cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103274:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010327b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103280:	c1 e8 0c             	shr    $0xc,%eax
f0103283:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103289:	72 14                	jb     f010329f <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010328b:	83 ec 04             	sub    $0x4,%esp
f010328e:	68 ac 66 10 f0       	push   $0xf01066ac
f0103293:	6a 51                	push   $0x51
f0103295:	68 15 6f 10 f0       	push   $0xf0106f15
f010329a:	e8 a1 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010329f:	83 ec 0c             	sub    $0xc,%esp
f01032a2:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f01032a8:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01032ab:	50                   	push   %eax
f01032ac:	e8 88 dc ff ff       	call   f0100f39 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01032b1:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01032b8:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f01032bd:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01032c0:	89 3d 48 f2 22 f0    	mov    %edi,0xf022f248
}
f01032c6:	83 c4 10             	add    $0x10,%esp
f01032c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032cc:	5b                   	pop    %ebx
f01032cd:	5e                   	pop    %esi
f01032ce:	5f                   	pop    %edi
f01032cf:	5d                   	pop    %ebp
f01032d0:	c3                   	ret    

f01032d1 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01032d1:	55                   	push   %ebp
f01032d2:	89 e5                	mov    %esp,%ebp
f01032d4:	53                   	push   %ebx
f01032d5:	83 ec 04             	sub    $0x4,%esp
f01032d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01032db:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01032df:	75 19                	jne    f01032fa <env_destroy+0x29>
f01032e1:	e8 f5 26 00 00       	call   f01059db <cpunum>
f01032e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01032e9:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f01032ef:	74 09                	je     f01032fa <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01032f1:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01032f8:	eb 33                	jmp    f010332d <env_destroy+0x5c>
	}

	env_free(e);
f01032fa:	83 ec 0c             	sub    $0xc,%esp
f01032fd:	53                   	push   %ebx
f01032fe:	e8 f3 fd ff ff       	call   f01030f6 <env_free>
	
	if (curenv == e) {
f0103303:	e8 d3 26 00 00       	call   f01059db <cpunum>
f0103308:	6b c0 74             	imul   $0x74,%eax,%eax
f010330b:	83 c4 10             	add    $0x10,%esp
f010330e:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0103314:	75 17                	jne    f010332d <env_destroy+0x5c>
		//cprintf("free %08x\n",e->env_id);
		curenv = NULL;
f0103316:	e8 c0 26 00 00       	call   f01059db <cpunum>
f010331b:	6b c0 74             	imul   $0x74,%eax,%eax
f010331e:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103325:	00 00 00 
		sched_yield();
f0103328:	e8 23 0e 00 00       	call   f0104150 <sched_yield>
	}
}
f010332d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103330:	c9                   	leave  
f0103331:	c3                   	ret    

f0103332 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103332:	55                   	push   %ebp
f0103333:	89 e5                	mov    %esp,%ebp
f0103335:	53                   	push   %ebx
f0103336:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103339:	e8 9d 26 00 00       	call   f01059db <cpunum>
f010333e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103341:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f0103347:	e8 8f 26 00 00       	call   f01059db <cpunum>
f010334c:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f010334f:	8b 65 08             	mov    0x8(%ebp),%esp
f0103352:	61                   	popa   
f0103353:	07                   	pop    %es
f0103354:	1f                   	pop    %ds
f0103355:	83 c4 08             	add    $0x8,%esp
f0103358:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103359:	83 ec 04             	sub    $0x4,%esp
f010335c:	68 c9 72 10 f0       	push   $0xf01072c9
f0103361:	68 02 02 00 00       	push   $0x202
f0103366:	68 79 72 10 f0       	push   $0xf0107279
f010336b:	e8 d0 cc ff ff       	call   f0100040 <_panic>

f0103370 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103370:	55                   	push   %ebp
f0103371:	89 e5                	mov    %esp,%ebp
f0103373:	53                   	push   %ebx
f0103374:	83 ec 04             	sub    $0x4,%esp
f0103377:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f010337a:	e8 5c 26 00 00       	call   f01059db <cpunum>
f010337f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103382:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103389:	74 29                	je     f01033b4 <env_run+0x44>
f010338b:	e8 4b 26 00 00       	call   f01059db <cpunum>
f0103390:	6b c0 74             	imul   $0x74,%eax,%eax
f0103393:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103399:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010339d:	75 15                	jne    f01033b4 <env_run+0x44>
	{
		curenv->env_status=ENV_RUNNABLE;
f010339f:	e8 37 26 00 00       	call   f01059db <cpunum>
f01033a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01033a7:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01033ad:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv=e;
f01033b4:	e8 22 26 00 00       	call   f01059db <cpunum>
f01033b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033bc:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
	curenv->env_status=ENV_RUNNING;
f01033c2:	e8 14 26 00 00       	call   f01059db <cpunum>
f01033c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ca:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01033d0:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f01033d7:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(curenv->env_pgdir));
f01033db:	e8 fb 25 00 00       	call   f01059db <cpunum>
f01033e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e3:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01033e9:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033f1:	77 15                	ja     f0103408 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033f3:	50                   	push   %eax
f01033f4:	68 c8 60 10 f0       	push   $0xf01060c8
f01033f9:	68 27 02 00 00       	push   $0x227
f01033fe:	68 79 72 10 f0       	push   $0xf0107279
f0103403:	e8 38 cc ff ff       	call   f0100040 <_panic>
f0103408:	05 00 00 00 10       	add    $0x10000000,%eax
f010340d:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103410:	83 ec 0c             	sub    $0xc,%esp
f0103413:	68 c0 03 12 f0       	push   $0xf01203c0
f0103418:	e8 c9 28 00 00       	call   f0105ce6 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010341d:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f010341f:	e8 b7 25 00 00       	call   f01059db <cpunum>
f0103424:	83 c4 04             	add    $0x4,%esp
f0103427:	6b c0 74             	imul   $0x74,%eax,%eax
f010342a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103430:	e8 fd fe ff ff       	call   f0103332 <env_pop_tf>

f0103435 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103435:	55                   	push   %ebp
f0103436:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103438:	ba 70 00 00 00       	mov    $0x70,%edx
f010343d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103440:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103441:	ba 71 00 00 00       	mov    $0x71,%edx
f0103446:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103447:	0f b6 c0             	movzbl %al,%eax
}
f010344a:	5d                   	pop    %ebp
f010344b:	c3                   	ret    

f010344c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010344c:	55                   	push   %ebp
f010344d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010344f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103454:	8b 45 08             	mov    0x8(%ebp),%eax
f0103457:	ee                   	out    %al,(%dx)
f0103458:	ba 71 00 00 00       	mov    $0x71,%edx
f010345d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103460:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103461:	5d                   	pop    %ebp
f0103462:	c3                   	ret    

f0103463 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103463:	55                   	push   %ebp
f0103464:	89 e5                	mov    %esp,%ebp
f0103466:	56                   	push   %esi
f0103467:	53                   	push   %ebx
f0103468:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010346b:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103471:	80 3d 4c f2 22 f0 00 	cmpb   $0x0,0xf022f24c
f0103478:	74 5a                	je     f01034d4 <irq_setmask_8259A+0x71>
f010347a:	89 c6                	mov    %eax,%esi
f010347c:	ba 21 00 00 00       	mov    $0x21,%edx
f0103481:	ee                   	out    %al,(%dx)
f0103482:	66 c1 e8 08          	shr    $0x8,%ax
f0103486:	ba a1 00 00 00       	mov    $0xa1,%edx
f010348b:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010348c:	83 ec 0c             	sub    $0xc,%esp
f010348f:	68 d5 72 10 f0       	push   $0xf01072d5
f0103494:	e8 1b 01 00 00       	call   f01035b4 <cprintf>
f0103499:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010349c:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01034a1:	0f b7 f6             	movzwl %si,%esi
f01034a4:	f7 d6                	not    %esi
f01034a6:	0f a3 de             	bt     %ebx,%esi
f01034a9:	73 11                	jae    f01034bc <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f01034ab:	83 ec 08             	sub    $0x8,%esp
f01034ae:	53                   	push   %ebx
f01034af:	68 7b 77 10 f0       	push   $0xf010777b
f01034b4:	e8 fb 00 00 00       	call   f01035b4 <cprintf>
f01034b9:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01034bc:	83 c3 01             	add    $0x1,%ebx
f01034bf:	83 fb 10             	cmp    $0x10,%ebx
f01034c2:	75 e2                	jne    f01034a6 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01034c4:	83 ec 0c             	sub    $0xc,%esp
f01034c7:	68 e9 71 10 f0       	push   $0xf01071e9
f01034cc:	e8 e3 00 00 00       	call   f01035b4 <cprintf>
f01034d1:	83 c4 10             	add    $0x10,%esp
}
f01034d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034d7:	5b                   	pop    %ebx
f01034d8:	5e                   	pop    %esi
f01034d9:	5d                   	pop    %ebp
f01034da:	c3                   	ret    

f01034db <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01034db:	c6 05 4c f2 22 f0 01 	movb   $0x1,0xf022f24c
f01034e2:	ba 21 00 00 00       	mov    $0x21,%edx
f01034e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034ec:	ee                   	out    %al,(%dx)
f01034ed:	ba a1 00 00 00       	mov    $0xa1,%edx
f01034f2:	ee                   	out    %al,(%dx)
f01034f3:	ba 20 00 00 00       	mov    $0x20,%edx
f01034f8:	b8 11 00 00 00       	mov    $0x11,%eax
f01034fd:	ee                   	out    %al,(%dx)
f01034fe:	ba 21 00 00 00       	mov    $0x21,%edx
f0103503:	b8 20 00 00 00       	mov    $0x20,%eax
f0103508:	ee                   	out    %al,(%dx)
f0103509:	b8 04 00 00 00       	mov    $0x4,%eax
f010350e:	ee                   	out    %al,(%dx)
f010350f:	b8 03 00 00 00       	mov    $0x3,%eax
f0103514:	ee                   	out    %al,(%dx)
f0103515:	ba a0 00 00 00       	mov    $0xa0,%edx
f010351a:	b8 11 00 00 00       	mov    $0x11,%eax
f010351f:	ee                   	out    %al,(%dx)
f0103520:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103525:	b8 28 00 00 00       	mov    $0x28,%eax
f010352a:	ee                   	out    %al,(%dx)
f010352b:	b8 02 00 00 00       	mov    $0x2,%eax
f0103530:	ee                   	out    %al,(%dx)
f0103531:	b8 01 00 00 00       	mov    $0x1,%eax
f0103536:	ee                   	out    %al,(%dx)
f0103537:	ba 20 00 00 00       	mov    $0x20,%edx
f010353c:	b8 68 00 00 00       	mov    $0x68,%eax
f0103541:	ee                   	out    %al,(%dx)
f0103542:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103547:	ee                   	out    %al,(%dx)
f0103548:	ba a0 00 00 00       	mov    $0xa0,%edx
f010354d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103552:	ee                   	out    %al,(%dx)
f0103553:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103558:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103559:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f0103560:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103564:	74 13                	je     f0103579 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103566:	55                   	push   %ebp
f0103567:	89 e5                	mov    %esp,%ebp
f0103569:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010356c:	0f b7 c0             	movzwl %ax,%eax
f010356f:	50                   	push   %eax
f0103570:	e8 ee fe ff ff       	call   f0103463 <irq_setmask_8259A>
f0103575:	83 c4 10             	add    $0x10,%esp
}
f0103578:	c9                   	leave  
f0103579:	f3 c3                	repz ret 

f010357b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010357b:	55                   	push   %ebp
f010357c:	89 e5                	mov    %esp,%ebp
f010357e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103581:	ff 75 08             	pushl  0x8(%ebp)
f0103584:	e8 db d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0103589:	83 c4 10             	add    $0x10,%esp
f010358c:	c9                   	leave  
f010358d:	c3                   	ret    

f010358e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010358e:	55                   	push   %ebp
f010358f:	89 e5                	mov    %esp,%ebp
f0103591:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010359b:	ff 75 0c             	pushl  0xc(%ebp)
f010359e:	ff 75 08             	pushl  0x8(%ebp)
f01035a1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01035a4:	50                   	push   %eax
f01035a5:	68 7b 35 10 f0       	push   $0xf010357b
f01035aa:	e8 d2 16 00 00       	call   f0104c81 <vprintfmt>
	return cnt;
}
f01035af:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035b2:	c9                   	leave  
f01035b3:	c3                   	ret    

f01035b4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01035b4:	55                   	push   %ebp
f01035b5:	89 e5                	mov    %esp,%ebp
f01035b7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01035ba:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01035bd:	50                   	push   %eax
f01035be:	ff 75 08             	pushl  0x8(%ebp)
f01035c1:	e8 c8 ff ff ff       	call   f010358e <vcprintf>
	va_end(ap);

	return cnt;
}
f01035c6:	c9                   	leave  
f01035c7:	c3                   	ret    

f01035c8 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01035c8:	55                   	push   %ebp
f01035c9:	89 e5                	mov    %esp,%ebp
f01035cb:	57                   	push   %edi
f01035cc:	56                   	push   %esi
f01035cd:	53                   	push   %ebx
f01035ce:	83 ec 0c             	sub    $0xc,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0=KSTACKTOP-cpunum()*(KSTKSIZE+KSTKGAP);
f01035d1:	e8 05 24 00 00       	call   f01059db <cpunum>
f01035d6:	89 c3                	mov    %eax,%ebx
f01035d8:	e8 fe 23 00 00       	call   f01059db <cpunum>
f01035dd:	6b db 74             	imul   $0x74,%ebx,%ebx
f01035e0:	c1 e0 10             	shl    $0x10,%eax
f01035e3:	89 c2                	mov    %eax,%edx
f01035e5:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01035ea:	29 d0                	sub    %edx,%eax
f01035ec:	89 83 30 00 23 f0    	mov    %eax,-0xfdcffd0(%ebx)
	thiscpu->cpu_ts.ts_ss0=GD_KD;
f01035f2:	e8 e4 23 00 00       	call   f01059db <cpunum>
f01035f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035fa:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f0103601:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f0103603:	e8 d3 23 00 00       	call   f01059db <cpunum>
f0103608:	8d 58 05             	lea    0x5(%eax),%ebx
f010360b:	e8 cb 23 00 00       	call   f01059db <cpunum>
f0103610:	89 c7                	mov    %eax,%edi
f0103612:	e8 c4 23 00 00       	call   f01059db <cpunum>
f0103617:	89 c6                	mov    %eax,%esi
f0103619:	e8 bd 23 00 00       	call   f01059db <cpunum>
f010361e:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f0103625:	f0 67 00 
f0103628:	6b ff 74             	imul   $0x74,%edi,%edi
f010362b:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f0103631:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f0103638:	f0 
f0103639:	6b d6 74             	imul   $0x74,%esi,%edx
f010363c:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f0103642:	c1 ea 10             	shr    $0x10,%edx
f0103645:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f010364c:	c6 04 dd 45 03 12 f0 	movb   $0x99,-0xfedfcbb(,%ebx,8)
f0103653:	99 
f0103654:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f010365b:	40 
f010365c:	6b c0 74             	imul   $0x74,%eax,%eax
f010365f:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f0103664:	c1 e8 18             	shr    $0x18,%eax
f0103667:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;
f010366e:	e8 68 23 00 00       	call   f01059db <cpunum>
f0103673:	80 24 c5 6d 03 12 f0 	andb   $0xef,-0xfedfc93(,%eax,8)
f010367a:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+sizeof(struct Segdesc)*cpunum());
f010367b:	e8 5b 23 00 00       	call   f01059db <cpunum>
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103680:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103687:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010368a:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f010368f:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103692:	83 c4 0c             	add    $0xc,%esp
f0103695:	5b                   	pop    %ebx
f0103696:	5e                   	pop    %esi
f0103697:	5f                   	pop    %edi
f0103698:	5d                   	pop    %ebp
f0103699:	c3                   	ret    

f010369a <trap_init>:
}


void
trap_init(void)
{
f010369a:	55                   	push   %ebp
f010369b:	89 e5                	mov    %esp,%ebp
f010369d:	83 ec 08             	sub    $0x8,%esp
	extern void irq_timer();
	extern void irq_kbd();
	extern void irq_serial();
	extern void irq_spurious();
	extern void irq_ide();
	SETGATE(idt[0],0,GD_KT,divide_error,0);
f01036a0:	b8 e8 3f 10 f0       	mov    $0xf0103fe8,%eax
f01036a5:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f01036ab:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f01036b2:	08 00 
f01036b4:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f01036bb:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f01036c2:	c1 e8 10             	shr    $0x10,%eax
f01036c5:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
	SETGATE(idt[1],0,GD_KT,debuf_exception,0);
f01036cb:	b8 ee 3f 10 f0       	mov    $0xf0103fee,%eax
f01036d0:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f01036d6:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f01036dd:	08 00 
f01036df:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f01036e6:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f01036ed:	c1 e8 10             	shr    $0x10,%eax
f01036f0:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
	SETGATE(idt[2],0,GD_KT,nmi_interrupt,0);
f01036f6:	b8 f4 3f 10 f0       	mov    $0xf0103ff4,%eax
f01036fb:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f0103701:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f0103708:	08 00 
f010370a:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f0103711:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f0103718:	c1 e8 10             	shr    $0x10,%eax
f010371b:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
	SETGATE(idt[3],0,GD_KT,break_point,3);
f0103721:	b8 fa 3f 10 f0       	mov    $0xf0103ffa,%eax
f0103726:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f010372c:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f0103733:	08 00 
f0103735:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f010373c:	c6 05 7d f2 22 f0 ee 	movb   $0xee,0xf022f27d
f0103743:	c1 e8 10             	shr    $0x10,%eax
f0103746:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
	SETGATE(idt[4],0,GD_KT,overflow,0);
f010374c:	b8 00 40 10 f0       	mov    $0xf0104000,%eax
f0103751:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f0103757:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f010375e:	08 00 
f0103760:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f0103767:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f010376e:	c1 e8 10             	shr    $0x10,%eax
f0103771:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
	SETGATE(idt[5],0,GD_KT,bound_check,0);
f0103777:	b8 06 40 10 f0       	mov    $0xf0104006,%eax
f010377c:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f0103782:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f0103789:	08 00 
f010378b:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f0103792:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f0103799:	c1 e8 10             	shr    $0x10,%eax
f010379c:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
	SETGATE(idt[6],0,GD_KT,illegal_opcode,0);
f01037a2:	b8 0c 40 10 f0       	mov    $0xf010400c,%eax
f01037a7:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f01037ad:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f01037b4:	08 00 
f01037b6:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f01037bd:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f01037c4:	c1 e8 10             	shr    $0x10,%eax
f01037c7:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
	SETGATE(idt[7],0,GD_KT,device_not_available,0);
f01037cd:	b8 12 40 10 f0       	mov    $0xf0104012,%eax
f01037d2:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f01037d8:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f01037df:	08 00 
f01037e1:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f01037e8:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f01037ef:	c1 e8 10             	shr    $0x10,%eax
f01037f2:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
	SETGATE(idt[8],0,GD_KT,segment_not_present,0);
f01037f8:	ba 20 40 10 f0       	mov    $0xf0104020,%edx
f01037fd:	66 89 15 a0 f2 22 f0 	mov    %dx,0xf022f2a0
f0103804:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f010380b:	08 00 
f010380d:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f0103814:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f010381b:	89 d1                	mov    %edx,%ecx
f010381d:	c1 e9 10             	shr    $0x10,%ecx
f0103820:	66 89 0d a6 f2 22 f0 	mov    %cx,0xf022f2a6
	SETGATE(idt[10],0,GD_KT,invalid_tss,0);
f0103827:	b8 1c 40 10 f0       	mov    $0xf010401c,%eax
f010382c:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f0103832:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f0103839:	08 00 
f010383b:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f0103842:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f0103849:	c1 e8 10             	shr    $0x10,%eax
f010384c:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
	SETGATE(idt[11],0,GD_KT,segment_not_present,0);
f0103852:	66 89 15 b8 f2 22 f0 	mov    %dx,0xf022f2b8
f0103859:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f0103860:	08 00 
f0103862:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f0103869:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f0103870:	66 89 0d be f2 22 f0 	mov    %cx,0xf022f2be
	SETGATE(idt[12],0,GD_KT,stack_exception,0);
f0103877:	b8 24 40 10 f0       	mov    $0xf0104024,%eax
f010387c:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f0103882:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f0103889:	08 00 
f010388b:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f0103892:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f0103899:	c1 e8 10             	shr    $0x10,%eax
f010389c:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
	SETGATE(idt[13],0,GD_KT, general_protection_fault,0);
f01038a2:	b8 28 40 10 f0       	mov    $0xf0104028,%eax
f01038a7:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f01038ad:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f01038b4:	08 00 
f01038b6:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f01038bd:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f01038c4:	c1 e8 10             	shr    $0x10,%eax
f01038c7:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
	SETGATE(idt[14],0,GD_KT,page_fault,0);
f01038cd:	b8 2c 40 10 f0       	mov    $0xf010402c,%eax
f01038d2:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f01038d8:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f01038df:	08 00 
f01038e1:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f01038e8:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f01038ef:	c1 e8 10             	shr    $0x10,%eax
f01038f2:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
	SETGATE(idt[16],0,GD_KT,floating_point_error,0);
f01038f8:	b8 30 40 10 f0       	mov    $0xf0104030,%eax
f01038fd:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f0103903:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f010390a:	08 00 
f010390c:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f0103913:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f010391a:	c1 e8 10             	shr    $0x10,%eax
f010391d:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
	SETGATE(idt[17],0,GD_KT,alignment_check,0);
f0103923:	b8 36 40 10 f0       	mov    $0xf0104036,%eax
f0103928:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f010392e:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f0103935:	08 00 
f0103937:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f010393e:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f0103945:	c1 e8 10             	shr    $0x10,%eax
f0103948:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
	SETGATE(idt[18],0,GD_KT,machine_check,0);
f010394e:	b8 3a 40 10 f0       	mov    $0xf010403a,%eax
f0103953:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103959:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103960:	08 00 
f0103962:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103969:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103970:	c1 e8 10             	shr    $0x10,%eax
f0103973:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
	SETGATE(idt[19],0,GD_KT,simd_floating_error,0);
f0103979:	b8 40 40 10 f0       	mov    $0xf0104040,%eax
f010397e:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103984:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f010398b:	08 00 
f010398d:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103994:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f010399b:	c1 e8 10             	shr    $0x10,%eax
f010399e:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe
	SETGATE(idt[48],0,GD_KT,system_call,3);
f01039a4:	b8 46 40 10 f0       	mov    $0xf0104046,%eax
f01039a9:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f01039af:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f01039b6:	08 00 
f01039b8:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f01039bf:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f01039c6:	c1 e8 10             	shr    $0x10,%eax
f01039c9:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6
	SETGATE(idt[32],0,GD_KT,irq_timer,0);
f01039cf:	b8 4c 40 10 f0       	mov    $0xf010404c,%eax
f01039d4:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f01039da:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f01039e1:	08 00 
f01039e3:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f01039ea:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f01039f1:	c1 e8 10             	shr    $0x10,%eax
f01039f4:	66 a3 66 f3 22 f0    	mov    %ax,0xf022f366
	SETGATE(idt[IRQ_OFFSET+IRQ_KBD],0,GD_KT,irq_kbd,0);
f01039fa:	b8 52 40 10 f0       	mov    $0xf0104052,%eax
f01039ff:	66 a3 68 f3 22 f0    	mov    %ax,0xf022f368
f0103a05:	66 c7 05 6a f3 22 f0 	movw   $0x8,0xf022f36a
f0103a0c:	08 00 
f0103a0e:	c6 05 6c f3 22 f0 00 	movb   $0x0,0xf022f36c
f0103a15:	c6 05 6d f3 22 f0 8e 	movb   $0x8e,0xf022f36d
f0103a1c:	c1 e8 10             	shr    $0x10,%eax
f0103a1f:	66 a3 6e f3 22 f0    	mov    %ax,0xf022f36e
	SETGATE(idt[IRQ_OFFSET+IRQ_SERIAL],0,GD_KT,irq_serial,0);
f0103a25:	b8 58 40 10 f0       	mov    $0xf0104058,%eax
f0103a2a:	66 a3 80 f3 22 f0    	mov    %ax,0xf022f380
f0103a30:	66 c7 05 82 f3 22 f0 	movw   $0x8,0xf022f382
f0103a37:	08 00 
f0103a39:	c6 05 84 f3 22 f0 00 	movb   $0x0,0xf022f384
f0103a40:	c6 05 85 f3 22 f0 8e 	movb   $0x8e,0xf022f385
f0103a47:	c1 e8 10             	shr    $0x10,%eax
f0103a4a:	66 a3 86 f3 22 f0    	mov    %ax,0xf022f386
	SETGATE(idt[IRQ_OFFSET+IRQ_SPURIOUS],0,GD_KT,irq_spurious,0);
f0103a50:	b8 5e 40 10 f0       	mov    $0xf010405e,%eax
f0103a55:	66 a3 98 f3 22 f0    	mov    %ax,0xf022f398
f0103a5b:	66 c7 05 9a f3 22 f0 	movw   $0x8,0xf022f39a
f0103a62:	08 00 
f0103a64:	c6 05 9c f3 22 f0 00 	movb   $0x0,0xf022f39c
f0103a6b:	c6 05 9d f3 22 f0 8e 	movb   $0x8e,0xf022f39d
f0103a72:	c1 e8 10             	shr    $0x10,%eax
f0103a75:	66 a3 9e f3 22 f0    	mov    %ax,0xf022f39e
	SETGATE(idt[IRQ_OFFSET+IRQ_IDE],0,GD_KT,irq_ide,0);
f0103a7b:	b8 64 40 10 f0       	mov    $0xf0104064,%eax
f0103a80:	66 a3 d0 f3 22 f0    	mov    %ax,0xf022f3d0
f0103a86:	66 c7 05 d2 f3 22 f0 	movw   $0x8,0xf022f3d2
f0103a8d:	08 00 
f0103a8f:	c6 05 d4 f3 22 f0 00 	movb   $0x0,0xf022f3d4
f0103a96:	c6 05 d5 f3 22 f0 8e 	movb   $0x8e,0xf022f3d5
f0103a9d:	c1 e8 10             	shr    $0x10,%eax
f0103aa0:	66 a3 d6 f3 22 f0    	mov    %ax,0xf022f3d6
	// Per-CPU setup 
	trap_init_percpu();
f0103aa6:	e8 1d fb ff ff       	call   f01035c8 <trap_init_percpu>
}
f0103aab:	c9                   	leave  
f0103aac:	c3                   	ret    

f0103aad <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103aad:	55                   	push   %ebp
f0103aae:	89 e5                	mov    %esp,%ebp
f0103ab0:	53                   	push   %ebx
f0103ab1:	83 ec 0c             	sub    $0xc,%esp
f0103ab4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103ab7:	ff 33                	pushl  (%ebx)
f0103ab9:	68 e9 72 10 f0       	push   $0xf01072e9
f0103abe:	e8 f1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ac3:	83 c4 08             	add    $0x8,%esp
f0103ac6:	ff 73 04             	pushl  0x4(%ebx)
f0103ac9:	68 f8 72 10 f0       	push   $0xf01072f8
f0103ace:	e8 e1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ad3:	83 c4 08             	add    $0x8,%esp
f0103ad6:	ff 73 08             	pushl  0x8(%ebx)
f0103ad9:	68 07 73 10 f0       	push   $0xf0107307
f0103ade:	e8 d1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103ae3:	83 c4 08             	add    $0x8,%esp
f0103ae6:	ff 73 0c             	pushl  0xc(%ebx)
f0103ae9:	68 16 73 10 f0       	push   $0xf0107316
f0103aee:	e8 c1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103af3:	83 c4 08             	add    $0x8,%esp
f0103af6:	ff 73 10             	pushl  0x10(%ebx)
f0103af9:	68 25 73 10 f0       	push   $0xf0107325
f0103afe:	e8 b1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b03:	83 c4 08             	add    $0x8,%esp
f0103b06:	ff 73 14             	pushl  0x14(%ebx)
f0103b09:	68 34 73 10 f0       	push   $0xf0107334
f0103b0e:	e8 a1 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b13:	83 c4 08             	add    $0x8,%esp
f0103b16:	ff 73 18             	pushl  0x18(%ebx)
f0103b19:	68 43 73 10 f0       	push   $0xf0107343
f0103b1e:	e8 91 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b23:	83 c4 08             	add    $0x8,%esp
f0103b26:	ff 73 1c             	pushl  0x1c(%ebx)
f0103b29:	68 52 73 10 f0       	push   $0xf0107352
f0103b2e:	e8 81 fa ff ff       	call   f01035b4 <cprintf>
}
f0103b33:	83 c4 10             	add    $0x10,%esp
f0103b36:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b39:	c9                   	leave  
f0103b3a:	c3                   	ret    

f0103b3b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b3b:	55                   	push   %ebp
f0103b3c:	89 e5                	mov    %esp,%ebp
f0103b3e:	56                   	push   %esi
f0103b3f:	53                   	push   %ebx
f0103b40:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b43:	e8 93 1e 00 00       	call   f01059db <cpunum>
f0103b48:	83 ec 04             	sub    $0x4,%esp
f0103b4b:	50                   	push   %eax
f0103b4c:	53                   	push   %ebx
f0103b4d:	68 b6 73 10 f0       	push   $0xf01073b6
f0103b52:	e8 5d fa ff ff       	call   f01035b4 <cprintf>
	print_regs(&tf->tf_regs);
f0103b57:	89 1c 24             	mov    %ebx,(%esp)
f0103b5a:	e8 4e ff ff ff       	call   f0103aad <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b5f:	83 c4 08             	add    $0x8,%esp
f0103b62:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b66:	50                   	push   %eax
f0103b67:	68 d4 73 10 f0       	push   $0xf01073d4
f0103b6c:	e8 43 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b71:	83 c4 08             	add    $0x8,%esp
f0103b74:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b78:	50                   	push   %eax
f0103b79:	68 e7 73 10 f0       	push   $0xf01073e7
f0103b7e:	e8 31 fa ff ff       	call   f01035b4 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b83:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103b86:	83 c4 10             	add    $0x10,%esp
f0103b89:	83 f8 13             	cmp    $0x13,%eax
f0103b8c:	77 09                	ja     f0103b97 <print_trapframe+0x5c>
		return excnames[trapno];
f0103b8e:	8b 14 85 60 76 10 f0 	mov    -0xfef89a0(,%eax,4),%edx
f0103b95:	eb 1f                	jmp    f0103bb6 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b97:	83 f8 30             	cmp    $0x30,%eax
f0103b9a:	74 15                	je     f0103bb1 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b9c:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b9f:	83 fa 10             	cmp    $0x10,%edx
f0103ba2:	b9 80 73 10 f0       	mov    $0xf0107380,%ecx
f0103ba7:	ba 6d 73 10 f0       	mov    $0xf010736d,%edx
f0103bac:	0f 43 d1             	cmovae %ecx,%edx
f0103baf:	eb 05                	jmp    f0103bb6 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103bb1:	ba 61 73 10 f0       	mov    $0xf0107361,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bb6:	83 ec 04             	sub    $0x4,%esp
f0103bb9:	52                   	push   %edx
f0103bba:	50                   	push   %eax
f0103bbb:	68 fa 73 10 f0       	push   $0xf01073fa
f0103bc0:	e8 ef f9 ff ff       	call   f01035b4 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bc5:	83 c4 10             	add    $0x10,%esp
f0103bc8:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103bce:	75 1a                	jne    f0103bea <print_trapframe+0xaf>
f0103bd0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bd4:	75 14                	jne    f0103bea <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103bd6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103bd9:	83 ec 08             	sub    $0x8,%esp
f0103bdc:	50                   	push   %eax
f0103bdd:	68 0c 74 10 f0       	push   $0xf010740c
f0103be2:	e8 cd f9 ff ff       	call   f01035b4 <cprintf>
f0103be7:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103bea:	83 ec 08             	sub    $0x8,%esp
f0103bed:	ff 73 2c             	pushl  0x2c(%ebx)
f0103bf0:	68 1b 74 10 f0       	push   $0xf010741b
f0103bf5:	e8 ba f9 ff ff       	call   f01035b4 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bfa:	83 c4 10             	add    $0x10,%esp
f0103bfd:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c01:	75 49                	jne    f0103c4c <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c03:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c06:	89 c2                	mov    %eax,%edx
f0103c08:	83 e2 01             	and    $0x1,%edx
f0103c0b:	ba 9a 73 10 f0       	mov    $0xf010739a,%edx
f0103c10:	b9 8f 73 10 f0       	mov    $0xf010738f,%ecx
f0103c15:	0f 44 ca             	cmove  %edx,%ecx
f0103c18:	89 c2                	mov    %eax,%edx
f0103c1a:	83 e2 02             	and    $0x2,%edx
f0103c1d:	ba ac 73 10 f0       	mov    $0xf01073ac,%edx
f0103c22:	be a6 73 10 f0       	mov    $0xf01073a6,%esi
f0103c27:	0f 45 d6             	cmovne %esi,%edx
f0103c2a:	83 e0 04             	and    $0x4,%eax
f0103c2d:	be e6 74 10 f0       	mov    $0xf01074e6,%esi
f0103c32:	b8 b1 73 10 f0       	mov    $0xf01073b1,%eax
f0103c37:	0f 44 c6             	cmove  %esi,%eax
f0103c3a:	51                   	push   %ecx
f0103c3b:	52                   	push   %edx
f0103c3c:	50                   	push   %eax
f0103c3d:	68 29 74 10 f0       	push   $0xf0107429
f0103c42:	e8 6d f9 ff ff       	call   f01035b4 <cprintf>
f0103c47:	83 c4 10             	add    $0x10,%esp
f0103c4a:	eb 10                	jmp    f0103c5c <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c4c:	83 ec 0c             	sub    $0xc,%esp
f0103c4f:	68 e9 71 10 f0       	push   $0xf01071e9
f0103c54:	e8 5b f9 ff ff       	call   f01035b4 <cprintf>
f0103c59:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c5c:	83 ec 08             	sub    $0x8,%esp
f0103c5f:	ff 73 30             	pushl  0x30(%ebx)
f0103c62:	68 38 74 10 f0       	push   $0xf0107438
f0103c67:	e8 48 f9 ff ff       	call   f01035b4 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c6c:	83 c4 08             	add    $0x8,%esp
f0103c6f:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c73:	50                   	push   %eax
f0103c74:	68 47 74 10 f0       	push   $0xf0107447
f0103c79:	e8 36 f9 ff ff       	call   f01035b4 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c7e:	83 c4 08             	add    $0x8,%esp
f0103c81:	ff 73 38             	pushl  0x38(%ebx)
f0103c84:	68 5a 74 10 f0       	push   $0xf010745a
f0103c89:	e8 26 f9 ff ff       	call   f01035b4 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c8e:	83 c4 10             	add    $0x10,%esp
f0103c91:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c95:	74 25                	je     f0103cbc <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c97:	83 ec 08             	sub    $0x8,%esp
f0103c9a:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c9d:	68 69 74 10 f0       	push   $0xf0107469
f0103ca2:	e8 0d f9 ff ff       	call   f01035b4 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ca7:	83 c4 08             	add    $0x8,%esp
f0103caa:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103cae:	50                   	push   %eax
f0103caf:	68 78 74 10 f0       	push   $0xf0107478
f0103cb4:	e8 fb f8 ff ff       	call   f01035b4 <cprintf>
f0103cb9:	83 c4 10             	add    $0x10,%esp
	}
}
f0103cbc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103cbf:	5b                   	pop    %ebx
f0103cc0:	5e                   	pop    %esi
f0103cc1:	5d                   	pop    %ebp
f0103cc2:	c3                   	ret    

f0103cc3 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cc3:	55                   	push   %ebp
f0103cc4:	89 e5                	mov    %esp,%ebp
f0103cc6:	57                   	push   %edi
f0103cc7:	56                   	push   %esi
f0103cc8:	53                   	push   %ebx
f0103cc9:	83 ec 0c             	sub    $0xc,%esp
f0103ccc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103ccf:	0f 20 d6             	mov    %cr2,%esi
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall!=NULL)
f0103cd2:	e8 04 1d 00 00       	call   f01059db <cpunum>
f0103cd7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cda:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103ce0:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103ce4:	0f 84 a7 00 00 00    	je     f0103d91 <page_fault_handler+0xce>
	{
		struct UTrapframe *utf;
		if(UXSTACKTOP-PGSIZE<=tf->tf_esp&&tf->tf_esp<=UXSTACKTOP-1)
f0103cea:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ced:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
		{
			utf=(struct UTrapframe *)(tf->tf_esp-sizeof(struct UTrapframe)-4);
f0103cf3:	83 e8 38             	sub    $0x38,%eax
f0103cf6:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103cfc:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103d01:	0f 46 d0             	cmovbe %eax,%edx
f0103d04:	89 d7                	mov    %edx,%edi
		}
		else
		{	
			utf=(struct UTrapframe *)(UXSTACKTOP-sizeof(struct UTrapframe));
		}
		user_mem_assert (curenv, (void *)utf,sizeof(struct UTrapframe),(PTE_U|PTE_W));
f0103d06:	e8 d0 1c 00 00       	call   f01059db <cpunum>
f0103d0b:	6a 06                	push   $0x6
f0103d0d:	6a 34                	push   $0x34
f0103d0f:	57                   	push   %edi
f0103d10:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d13:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103d19:	e8 52 ef ff ff       	call   f0102c70 <user_mem_assert>
		utf->utf_fault_va=fault_va;
f0103d1e:	89 fa                	mov    %edi,%edx
f0103d20:	89 37                	mov    %esi,(%edi)
		utf->utf_err=tf->tf_trapno;
f0103d22:	8b 43 28             	mov    0x28(%ebx),%eax
f0103d25:	89 47 04             	mov    %eax,0x4(%edi)
		utf->utf_regs=tf->tf_regs;
f0103d28:	8d 7f 08             	lea    0x8(%edi),%edi
f0103d2b:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103d30:	89 de                	mov    %ebx,%esi
f0103d32:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		utf->utf_eip=tf->tf_eip;
f0103d34:	8b 43 30             	mov    0x30(%ebx),%eax
f0103d37:	89 42 28             	mov    %eax,0x28(%edx)
		utf->utf_eflags=tf->tf_eflags;
f0103d3a:	8b 43 38             	mov    0x38(%ebx),%eax
f0103d3d:	89 d7                	mov    %edx,%edi
f0103d3f:	89 42 2c             	mov    %eax,0x2c(%edx)
		utf->utf_esp=tf->tf_esp;
f0103d42:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103d45:	89 42 30             	mov    %eax,0x30(%edx)
		curenv->env_tf.tf_eip=(uint32_t )curenv->env_pgfault_upcall;
f0103d48:	e8 8e 1c 00 00       	call   f01059db <cpunum>
f0103d4d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d50:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f0103d56:	e8 80 1c 00 00       	call   f01059db <cpunum>
f0103d5b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d5e:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103d64:	8b 40 64             	mov    0x64(%eax),%eax
f0103d67:	89 43 30             	mov    %eax,0x30(%ebx)
		curenv->env_tf.tf_esp=(uint32_t)utf;
f0103d6a:	e8 6c 1c 00 00       	call   f01059db <cpunum>
f0103d6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d72:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103d78:	89 78 3c             	mov    %edi,0x3c(%eax)
		env_run(curenv);
f0103d7b:	e8 5b 1c 00 00       	call   f01059db <cpunum>
f0103d80:	83 c4 04             	add    $0x4,%esp
f0103d83:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d86:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103d8c:	e8 df f5 ff ff       	call   f0103370 <env_run>
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d91:	8b 7b 30             	mov    0x30(%ebx),%edi
			curenv->env_id, fault_va, tf->tf_eip);
f0103d94:	e8 42 1c 00 00       	call   f01059db <cpunum>
		curenv->env_tf.tf_esp=(uint32_t)utf;
		env_run(curenv);
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d99:	57                   	push   %edi
f0103d9a:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103d9b:	6b c0 74             	imul   $0x74,%eax,%eax
		curenv->env_tf.tf_esp=(uint32_t)utf;
		env_run(curenv);
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d9e:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103da4:	ff 70 48             	pushl  0x48(%eax)
f0103da7:	68 30 76 10 f0       	push   $0xf0107630
f0103dac:	e8 03 f8 ff ff       	call   f01035b4 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103db1:	89 1c 24             	mov    %ebx,(%esp)
f0103db4:	e8 82 fd ff ff       	call   f0103b3b <print_trapframe>
		env_destroy(curenv);
f0103db9:	e8 1d 1c 00 00       	call   f01059db <cpunum>
f0103dbe:	83 c4 04             	add    $0x4,%esp
f0103dc1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc4:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103dca:	e8 02 f5 ff ff       	call   f01032d1 <env_destroy>

}
f0103dcf:	83 c4 10             	add    $0x10,%esp
f0103dd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103dd5:	5b                   	pop    %ebx
f0103dd6:	5e                   	pop    %esi
f0103dd7:	5f                   	pop    %edi
f0103dd8:	5d                   	pop    %ebp
f0103dd9:	c3                   	ret    

f0103dda <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103dda:	55                   	push   %ebp
f0103ddb:	89 e5                	mov    %esp,%ebp
f0103ddd:	57                   	push   %edi
f0103dde:	56                   	push   %esi
f0103ddf:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103de2:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103de3:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f0103dea:	74 01                	je     f0103ded <trap+0x13>
		asm volatile("hlt");
f0103dec:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103ded:	e8 e9 1b 00 00       	call   f01059db <cpunum>
f0103df2:	6b d0 74             	imul   $0x74,%eax,%edx
f0103df5:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103dfb:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e00:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103e04:	83 f8 02             	cmp    $0x2,%eax
f0103e07:	75 10                	jne    f0103e19 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103e09:	83 ec 0c             	sub    $0xc,%esp
f0103e0c:	68 c0 03 12 f0       	push   $0xf01203c0
f0103e11:	e8 33 1e 00 00       	call   f0105c49 <spin_lock>
f0103e16:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103e19:	9c                   	pushf  
f0103e1a:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103e1b:	f6 c4 02             	test   $0x2,%ah
f0103e1e:	74 19                	je     f0103e39 <trap+0x5f>
f0103e20:	68 8b 74 10 f0       	push   $0xf010748b
f0103e25:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0103e2a:	68 1e 01 00 00       	push   $0x11e
f0103e2f:	68 a4 74 10 f0       	push   $0xf01074a4
f0103e34:	e8 07 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103e39:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e3d:	83 e0 03             	and    $0x3,%eax
f0103e40:	66 83 f8 03          	cmp    $0x3,%ax
f0103e44:	0f 85 a0 00 00 00    	jne    f0103eea <trap+0x110>
f0103e4a:	83 ec 0c             	sub    $0xc,%esp
f0103e4d:	68 c0 03 12 f0       	push   $0xf01203c0
f0103e52:	e8 f2 1d 00 00       	call   f0105c49 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock be  fore doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103e57:	e8 7f 1b 00 00       	call   f01059db <cpunum>
f0103e5c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e5f:	83 c4 10             	add    $0x10,%esp
f0103e62:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103e69:	75 19                	jne    f0103e84 <trap+0xaa>
f0103e6b:	68 b0 74 10 f0       	push   $0xf01074b0
f0103e70:	68 2f 6f 10 f0       	push   $0xf0106f2f
f0103e75:	68 26 01 00 00       	push   $0x126
f0103e7a:	68 a4 74 10 f0       	push   $0xf01074a4
f0103e7f:	e8 bc c1 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103e84:	e8 52 1b 00 00       	call   f01059db <cpunum>
f0103e89:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e8c:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103e92:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103e96:	75 2d                	jne    f0103ec5 <trap+0xeb>
			env_free(curenv);
f0103e98:	e8 3e 1b 00 00       	call   f01059db <cpunum>
f0103e9d:	83 ec 0c             	sub    $0xc,%esp
f0103ea0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea3:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103ea9:	e8 48 f2 ff ff       	call   f01030f6 <env_free>
			curenv = NULL;
f0103eae:	e8 28 1b 00 00       	call   f01059db <cpunum>
f0103eb3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb6:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103ebd:	00 00 00 
			sched_yield();
f0103ec0:	e8 8b 02 00 00       	call   f0104150 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103ec5:	e8 11 1b 00 00       	call   f01059db <cpunum>
f0103eca:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ecd:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103ed3:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103ed8:	89 c7                	mov    %eax,%edi
f0103eda:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103edc:	e8 fa 1a 00 00       	call   f01059db <cpunum>
f0103ee1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee4:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103eea:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103ef0:	8b 46 28             	mov    0x28(%esi),%eax
f0103ef3:	83 f8 27             	cmp    $0x27,%eax
f0103ef6:	75 1d                	jne    f0103f15 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103ef8:	83 ec 0c             	sub    $0xc,%esp
f0103efb:	68 b7 74 10 f0       	push   $0xf01074b7
f0103f00:	e8 af f6 ff ff       	call   f01035b4 <cprintf>
		print_trapframe(tf);
f0103f05:	89 34 24             	mov    %esi,(%esp)
f0103f08:	e8 2e fc ff ff       	call   f0103b3b <print_trapframe>
f0103f0d:	83 c4 10             	add    $0x10,%esp
f0103f10:	e9 92 00 00 00       	jmp    f0103fa7 <trap+0x1cd>
		return;
	}
	if(tf->tf_trapno==IRQ_OFFSET + IRQ_TIMER)
f0103f15:	83 f8 20             	cmp    $0x20,%eax
f0103f18:	75 0a                	jne    f0103f24 <trap+0x14a>
	{
		lapic_eoi();
f0103f1a:	e8 07 1c 00 00       	call   f0105b26 <lapic_eoi>
		sched_yield();
f0103f1f:	e8 2c 02 00 00       	call   f0104150 <sched_yield>
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
	
	// Unexpected trap: The user process or the kernel has a bug.
	//print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
f0103f24:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103f29:	75 17                	jne    f0103f42 <trap+0x168>
		panic("unhandled trap in kernel");
f0103f2b:	83 ec 04             	sub    $0x4,%esp
f0103f2e:	68 d4 74 10 f0       	push   $0xf01074d4
f0103f33:	68 f4 00 00 00       	push   $0xf4
f0103f38:	68 a4 74 10 f0       	push   $0xf01074a4
f0103f3d:	e8 fe c0 ff ff       	call   f0100040 <_panic>
	else {
		if(tf->tf_trapno ==T_PGFLT)
f0103f42:	83 f8 0e             	cmp    $0xe,%eax
f0103f45:	75 0e                	jne    f0103f55 <trap+0x17b>
		{
			page_fault_handler(tf);
f0103f47:	83 ec 0c             	sub    $0xc,%esp
f0103f4a:	56                   	push   %esi
f0103f4b:	e8 73 fd ff ff       	call   f0103cc3 <page_fault_handler>
f0103f50:	83 c4 10             	add    $0x10,%esp
f0103f53:	eb 52                	jmp    f0103fa7 <trap+0x1cd>
		}
		else if(tf->tf_trapno==T_BRKPT)
f0103f55:	83 f8 03             	cmp    $0x3,%eax
f0103f58:	75 0e                	jne    f0103f68 <trap+0x18e>
		{
			monitor(tf);
f0103f5a:	83 ec 0c             	sub    $0xc,%esp
f0103f5d:	56                   	push   %esi
f0103f5e:	e8 1e c9 ff ff       	call   f0100881 <monitor>
f0103f63:	83 c4 10             	add    $0x10,%esp
f0103f66:	eb 3f                	jmp    f0103fa7 <trap+0x1cd>
		}
		else if(tf->tf_trapno==T_SYSCALL)
f0103f68:	83 f8 30             	cmp    $0x30,%eax
f0103f6b:	75 21                	jne    f0103f8e <trap+0x1b4>
		{
			tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103f6d:	83 ec 08             	sub    $0x8,%esp
f0103f70:	ff 76 04             	pushl  0x4(%esi)
f0103f73:	ff 36                	pushl  (%esi)
f0103f75:	ff 76 10             	pushl  0x10(%esi)
f0103f78:	ff 76 18             	pushl  0x18(%esi)
f0103f7b:	ff 76 14             	pushl  0x14(%esi)
f0103f7e:	ff 76 1c             	pushl  0x1c(%esi)
f0103f81:	e8 38 02 00 00       	call   f01041be <syscall>
f0103f86:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103f89:	83 c4 20             	add    $0x20,%esp
f0103f8c:	eb 19                	jmp    f0103fa7 <trap+0x1cd>
		}
		else
		{
		
			env_destroy(curenv);
f0103f8e:	e8 48 1a 00 00       	call   f01059db <cpunum>
f0103f93:	83 ec 0c             	sub    $0xc,%esp
f0103f96:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f99:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103f9f:	e8 2d f3 ff ff       	call   f01032d1 <env_destroy>
f0103fa4:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103fa7:	e8 2f 1a 00 00       	call   f01059db <cpunum>
f0103fac:	6b c0 74             	imul   $0x74,%eax,%eax
f0103faf:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103fb6:	74 2a                	je     f0103fe2 <trap+0x208>
f0103fb8:	e8 1e 1a 00 00       	call   f01059db <cpunum>
f0103fbd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fc0:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103fc6:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103fca:	75 16                	jne    f0103fe2 <trap+0x208>
	{
		env_run(curenv);
f0103fcc:	e8 0a 1a 00 00       	call   f01059db <cpunum>
f0103fd1:	83 ec 0c             	sub    $0xc,%esp
f0103fd4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fd7:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103fdd:	e8 8e f3 ff ff       	call   f0103370 <env_run>
	}
	else
	{
		sched_yield();
f0103fe2:	e8 69 01 00 00       	call   f0104150 <sched_yield>
f0103fe7:	90                   	nop

f0103fe8 <divide_error>:
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
TRAPHANDLER_NOEC(divide_error,T_DIVIDE)
f0103fe8:	6a 00                	push   $0x0
f0103fea:	6a 00                	push   $0x0
f0103fec:	eb 7c                	jmp    f010406a <_alltraps>

f0103fee <debuf_exception>:
TRAPHANDLER_NOEC(debuf_exception,T_DEBUG)
f0103fee:	6a 00                	push   $0x0
f0103ff0:	6a 01                	push   $0x1
f0103ff2:	eb 76                	jmp    f010406a <_alltraps>

f0103ff4 <nmi_interrupt>:
TRAPHANDLER_NOEC(nmi_interrupt,T_NMI)
f0103ff4:	6a 00                	push   $0x0
f0103ff6:	6a 02                	push   $0x2
f0103ff8:	eb 70                	jmp    f010406a <_alltraps>

f0103ffa <break_point>:
TRAPHANDLER_NOEC(break_point,T_BRKPT)
f0103ffa:	6a 00                	push   $0x0
f0103ffc:	6a 03                	push   $0x3
f0103ffe:	eb 6a                	jmp    f010406a <_alltraps>

f0104000 <overflow>:
TRAPHANDLER_NOEC(overflow,T_OFLOW)
f0104000:	6a 00                	push   $0x0
f0104002:	6a 04                	push   $0x4
f0104004:	eb 64                	jmp    f010406a <_alltraps>

f0104006 <bound_check>:
TRAPHANDLER_NOEC(bound_check,T_BOUND);
f0104006:	6a 00                	push   $0x0
f0104008:	6a 05                	push   $0x5
f010400a:	eb 5e                	jmp    f010406a <_alltraps>

f010400c <illegal_opcode>:
TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)
f010400c:	6a 00                	push   $0x0
f010400e:	6a 06                	push   $0x6
f0104010:	eb 58                	jmp    f010406a <_alltraps>

f0104012 <device_not_available>:
TRAPHANDLER_NOEC(device_not_available,T_DEVICE)
f0104012:	6a 00                	push   $0x0
f0104014:	6a 07                	push   $0x7
f0104016:	eb 52                	jmp    f010406a <_alltraps>

f0104018 <double_fault>:
TRAPHANDLER(double_fault,T_DBLFLT)
f0104018:	6a 08                	push   $0x8
f010401a:	eb 4e                	jmp    f010406a <_alltraps>

f010401c <invalid_tss>:
TRAPHANDLER(invalid_tss,T_TSS)
f010401c:	6a 0a                	push   $0xa
f010401e:	eb 4a                	jmp    f010406a <_alltraps>

f0104020 <segment_not_present>:
TRAPHANDLER(segment_not_present,T_SEGNP)
f0104020:	6a 0b                	push   $0xb
f0104022:	eb 46                	jmp    f010406a <_alltraps>

f0104024 <stack_exception>:
TRAPHANDLER(stack_exception,T_STACK)
f0104024:	6a 0c                	push   $0xc
f0104026:	eb 42                	jmp    f010406a <_alltraps>

f0104028 <general_protection_fault>:
TRAPHANDLER(general_protection_fault,T_GPFLT)
f0104028:	6a 0d                	push   $0xd
f010402a:	eb 3e                	jmp    f010406a <_alltraps>

f010402c <page_fault>:
TRAPHANDLER(page_fault,T_PGFLT)
f010402c:	6a 0e                	push   $0xe
f010402e:	eb 3a                	jmp    f010406a <_alltraps>

f0104030 <floating_point_error>:
TRAPHANDLER_NOEC(floating_point_error,T_FPERR)
f0104030:	6a 00                	push   $0x0
f0104032:	6a 10                	push   $0x10
f0104034:	eb 34                	jmp    f010406a <_alltraps>

f0104036 <alignment_check>:
TRAPHANDLER(alignment_check,T_ALIGN)
f0104036:	6a 11                	push   $0x11
f0104038:	eb 30                	jmp    f010406a <_alltraps>

f010403a <machine_check>:
TRAPHANDLER_NOEC(machine_check,T_MCHK)
f010403a:	6a 00                	push   $0x0
f010403c:	6a 12                	push   $0x12
f010403e:	eb 2a                	jmp    f010406a <_alltraps>

f0104040 <simd_floating_error>:
TRAPHANDLER_NOEC(simd_floating_error,T_SIMDERR)
f0104040:	6a 00                	push   $0x0
f0104042:	6a 13                	push   $0x13
f0104044:	eb 24                	jmp    f010406a <_alltraps>

f0104046 <system_call>:
TRAPHANDLER_NOEC(system_call,T_SYSCALL)
f0104046:	6a 00                	push   $0x0
f0104048:	6a 30                	push   $0x30
f010404a:	eb 1e                	jmp    f010406a <_alltraps>

f010404c <irq_timer>:
TRAPHANDLER_NOEC(irq_timer,IRQ_OFFSET+ IRQ_TIMER)
f010404c:	6a 00                	push   $0x0
f010404e:	6a 20                	push   $0x20
f0104050:	eb 18                	jmp    f010406a <_alltraps>

f0104052 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd,IRQ_OFFSET+IRQ_KBD)
f0104052:	6a 00                	push   $0x0
f0104054:	6a 21                	push   $0x21
f0104056:	eb 12                	jmp    f010406a <_alltraps>

f0104058 <irq_serial>:
TRAPHANDLER_NOEC(irq_serial,IRQ_OFFSET+IRQ_SERIAL)
f0104058:	6a 00                	push   $0x0
f010405a:	6a 24                	push   $0x24
f010405c:	eb 0c                	jmp    f010406a <_alltraps>

f010405e <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious,IRQ_OFFSET+IRQ_SPURIOUS)
f010405e:	6a 00                	push   $0x0
f0104060:	6a 27                	push   $0x27
f0104062:	eb 06                	jmp    f010406a <_alltraps>

f0104064 <irq_ide>:
TRAPHANDLER_NOEC(irq_ide,IRQ_OFFSET+IRQ_IDE)
f0104064:	6a 00                	push   $0x0
f0104066:	6a 2e                	push   $0x2e
f0104068:	eb 00                	jmp    f010406a <_alltraps>

f010406a <_alltraps>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
_alltraps:
pushl %ds
f010406a:	1e                   	push   %ds
pushl %es
f010406b:	06                   	push   %es
pushal
f010406c:	60                   	pusha  
movl $GD_KD,%eax
f010406d:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax,%ds
f0104072:	8e d8                	mov    %eax,%ds
movw %ax,%es
f0104074:	8e c0                	mov    %eax,%es
pushl %esp
f0104076:	54                   	push   %esp
call trap
f0104077:	e8 5e fd ff ff       	call   f0103dda <trap>

f010407c <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010407c:	55                   	push   %ebp
f010407d:	89 e5                	mov    %esp,%ebp
f010407f:	83 ec 08             	sub    $0x8,%esp
f0104082:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f0104087:	8d 50 54             	lea    0x54(%eax),%edx
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010408a:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010408f:	8b 02                	mov    (%edx),%eax
f0104091:	83 e8 01             	sub    $0x1,%eax
f0104094:	83 f8 02             	cmp    $0x2,%eax
f0104097:	76 10                	jbe    f01040a9 <sched_halt+0x2d>
sched_halt(void)
{
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104099:	83 c1 01             	add    $0x1,%ecx
f010409c:	83 c2 7c             	add    $0x7c,%edx
f010409f:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040a5:	75 e8                	jne    f010408f <sched_halt+0x13>
f01040a7:	eb 08                	jmp    f01040b1 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f01040a9:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040af:	75 1f                	jne    f01040d0 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f01040b1:	83 ec 0c             	sub    $0xc,%esp
f01040b4:	68 b0 76 10 f0       	push   $0xf01076b0
f01040b9:	e8 f6 f4 ff ff       	call   f01035b4 <cprintf>
f01040be:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01040c1:	83 ec 0c             	sub    $0xc,%esp
f01040c4:	6a 00                	push   $0x0
f01040c6:	e8 b6 c7 ff ff       	call   f0100881 <monitor>
f01040cb:	83 c4 10             	add    $0x10,%esp
f01040ce:	eb f1                	jmp    f01040c1 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01040d0:	e8 06 19 00 00       	call   f01059db <cpunum>
f01040d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01040d8:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f01040df:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01040e2:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01040e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01040ec:	77 12                	ja     f0104100 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01040ee:	50                   	push   %eax
f01040ef:	68 c8 60 10 f0       	push   $0xf01060c8
f01040f4:	6a 4e                	push   $0x4e
f01040f6:	68 d9 76 10 f0       	push   $0xf01076d9
f01040fb:	e8 40 bf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104100:	05 00 00 00 10       	add    $0x10000000,%eax
f0104105:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104108:	e8 ce 18 00 00       	call   f01059db <cpunum>
f010410d:	6b d0 74             	imul   $0x74,%eax,%edx
f0104110:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0104116:	b8 02 00 00 00       	mov    $0x2,%eax
f010411b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010411f:	83 ec 0c             	sub    $0xc,%esp
f0104122:	68 c0 03 12 f0       	push   $0xf01203c0
f0104127:	e8 ba 1b 00 00       	call   f0105ce6 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010412c:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010412e:	e8 a8 18 00 00       	call   f01059db <cpunum>
f0104133:	6b c0 74             	imul   $0x74,%eax,%eax
	//cprintf("in the halt\n");
	// Reset stack pointer, enable interrupts and then halt.
	//cprintf("this cpu:%08x\n",thiscpu->cpu_ts.ts_esp0);
	//for(;;);
	
	asm volatile (
f0104136:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f010413c:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104141:	89 c4                	mov    %eax,%esp
f0104143:	6a 00                	push   $0x0
f0104145:	6a 00                	push   $0x0
f0104147:	fb                   	sti    
f0104148:	f4                   	hlt    
f0104149:	eb fd                	jmp    f0104148 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010414b:	83 c4 10             	add    $0x10,%esp
f010414e:	c9                   	leave  
f010414f:	c3                   	ret    

f0104150 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104150:	55                   	push   %ebp
f0104151:	89 e5                	mov    %esp,%ebp
f0104153:	56                   	push   %esi
f0104154:	53                   	push   %ebx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
f0104155:	e8 81 18 00 00       	call   f01059db <cpunum>
f010415a:	6b c0 74             	imul   $0x74,%eax,%eax
f010415d:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
f0104163:	85 f6                	test   %esi,%esi
f0104165:	74 0b                	je     f0104172 <sched_yield+0x22>
f0104167:	8b 4e 48             	mov    0x48(%esi),%ecx
f010416a:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0104170:	eb 05                	jmp    f0104177 <sched_yield+0x27>
f0104172:	b9 00 00 00 00       	mov    $0x0,%ecx
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f0104177:	8b 1d 44 f2 22 f0    	mov    0xf022f244,%ebx
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
f010417d:	89 c8                	mov    %ecx,%eax
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f010417f:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0104182:	01 da                	add    %ebx,%edx
f0104184:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104188:	75 09                	jne    f0104193 <sched_yield+0x43>
       		{	   
       		        env_run(&envs[i]);  
f010418a:	83 ec 0c             	sub    $0xc,%esp
f010418d:	52                   	push   %edx
f010418e:	e8 dd f1 ff ff       	call   f0103370 <env_run>
	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
f0104193:	83 c0 01             	add    $0x1,%eax
f0104196:	25 ff 03 00 00       	and    $0x3ff,%eax
f010419b:	39 c1                	cmp    %eax,%ecx
f010419d:	75 e0                	jne    f010417f <sched_yield+0x2f>
       		        env_run(&envs[i]);  
            		return ;  
        	}  
   	 }  
  
        if (idle && idle->env_status == ENV_RUNNING)  
f010419f:	85 f6                	test   %esi,%esi
f01041a1:	74 0f                	je     f01041b2 <sched_yield+0x62>
f01041a3:	83 7e 54 03          	cmpl   $0x3,0x54(%esi)
f01041a7:	75 09                	jne    f01041b2 <sched_yield+0x62>
	{  
       	 	env_run(idle);  
f01041a9:	83 ec 0c             	sub    $0xc,%esp
f01041ac:	56                   	push   %esi
f01041ad:	e8 be f1 ff ff       	call   f0103370 <env_run>
        	return ;  
    	}  
  
    // sched_halt never returns  
    sched_halt();
f01041b2:	e8 c5 fe ff ff       	call   f010407c <sched_halt>
}
f01041b7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01041ba:	5b                   	pop    %ebx
f01041bb:	5e                   	pop    %esi
f01041bc:	5d                   	pop    %ebp
f01041bd:	c3                   	ret    

f01041be <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01041be:	55                   	push   %ebp
f01041bf:	89 e5                	mov    %esp,%ebp
f01041c1:	57                   	push   %edi
f01041c2:	56                   	push   %esi
f01041c3:	53                   	push   %ebx
f01041c4:	83 ec 1c             	sub    $0x1c,%esp
f01041c7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) 
f01041ca:	83 f8 0c             	cmp    $0xc,%eax
f01041cd:	0f 87 40 06 00 00    	ja     f0104813 <syscall+0x655>
f01041d3:	ff 24 85 20 77 10 f0 	jmp    *-0xfef88e0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f01041da:	e8 fc 17 00 00       	call   f01059db <cpunum>
f01041df:	6a 04                	push   $0x4
f01041e1:	ff 75 10             	pushl  0x10(%ebp)
f01041e4:	ff 75 0c             	pushl  0xc(%ebp)
f01041e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01041ea:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01041f0:	e8 7b ea ff ff       	call   f0102c70 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01041f5:	83 c4 0c             	add    $0xc,%esp
f01041f8:	ff 75 0c             	pushl  0xc(%ebp)
f01041fb:	ff 75 10             	pushl  0x10(%ebp)
f01041fe:	68 e6 76 10 f0       	push   $0xf01076e6
f0104203:	e8 ac f3 ff ff       	call   f01035b4 <cprintf>
f0104208:	83 c4 10             	add    $0x10,%esp
		case SYS_ipc_recv:
			return sys_ipc_recv((void *)a1); 
		default:
			return -E_INVAL;
	}
	return 0;
f010420b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104210:	e9 11 06 00 00       	jmp    f0104826 <syscall+0x668>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104215:	e8 db c3 ff ff       	call   f01005f5 <cons_getc>
f010421a:	89 c3                	mov    %eax,%ebx
	 {
		case 0:
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
f010421c:	e9 05 06 00 00       	jmp    f0104826 <syscall+0x668>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104221:	e8 b5 17 00 00       	call   f01059db <cpunum>
f0104226:	6b c0 74             	imul   $0x74,%eax,%eax
f0104229:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010422f:	8b 58 48             	mov    0x48(%eax),%ebx
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
		case 2:
			return sys_getenvid();	
f0104232:	e9 ef 05 00 00       	jmp    f0104826 <syscall+0x668>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104237:	83 ec 04             	sub    $0x4,%esp
f010423a:	6a 01                	push   $0x1
f010423c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010423f:	50                   	push   %eax
f0104240:	ff 75 0c             	pushl  0xc(%ebp)
f0104243:	e8 fd ea ff ff       	call   f0102d45 <envid2env>
f0104248:	83 c4 10             	add    $0x10,%esp
		return r;
f010424b:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010424d:	85 c0                	test   %eax,%eax
f010424f:	0f 88 d1 05 00 00    	js     f0104826 <syscall+0x668>
		return r;
	if (e == curenv)
f0104255:	e8 81 17 00 00       	call   f01059db <cpunum>
f010425a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010425d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104260:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f0104266:	75 23                	jne    f010428b <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104268:	e8 6e 17 00 00       	call   f01059db <cpunum>
f010426d:	83 ec 08             	sub    $0x8,%esp
f0104270:	6b c0 74             	imul   $0x74,%eax,%eax
f0104273:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104279:	ff 70 48             	pushl  0x48(%eax)
f010427c:	68 eb 76 10 f0       	push   $0xf01076eb
f0104281:	e8 2e f3 ff ff       	call   f01035b4 <cprintf>
f0104286:	83 c4 10             	add    $0x10,%esp
f0104289:	eb 25                	jmp    f01042b0 <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010428b:	8b 5a 48             	mov    0x48(%edx),%ebx
f010428e:	e8 48 17 00 00       	call   f01059db <cpunum>
f0104293:	83 ec 04             	sub    $0x4,%esp
f0104296:	53                   	push   %ebx
f0104297:	6b c0 74             	imul   $0x74,%eax,%eax
f010429a:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01042a0:	ff 70 48             	pushl  0x48(%eax)
f01042a3:	68 06 77 10 f0       	push   $0xf0107706
f01042a8:	e8 07 f3 ff ff       	call   f01035b4 <cprintf>
f01042ad:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01042b0:	83 ec 0c             	sub    $0xc,%esp
f01042b3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01042b6:	e8 16 f0 ff ff       	call   f01032d1 <env_destroy>
f01042bb:	83 c4 10             	add    $0x10,%esp
	return 0;
f01042be:	bb 00 00 00 00       	mov    $0x0,%ebx
f01042c3:	e9 5e 05 00 00       	jmp    f0104826 <syscall+0x668>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01042c8:	e8 83 fe ff ff       	call   f0104150 <sched_yield>
	//   allocated!

	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
f01042cd:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01042d4:	0f 87 d6 00 00 00    	ja     f01043b0 <syscall+0x1f2>
f01042da:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01042e1:	0f 85 d3 00 00 00    	jne    f01043ba <syscall+0x1fc>
	{
		return -E_INVAL;
	}
	if(envid2env(envid,&e,1)<0)
f01042e7:	83 ec 04             	sub    $0x4,%esp
f01042ea:	6a 01                	push   $0x1
f01042ec:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01042ef:	50                   	push   %eax
f01042f0:	ff 75 0c             	pushl  0xc(%ebp)
f01042f3:	e8 4d ea ff ff       	call   f0102d45 <envid2env>
f01042f8:	83 c4 10             	add    $0x10,%esp
f01042fb:	85 c0                	test   %eax,%eax
f01042fd:	0f 88 c1 00 00 00    	js     f01043c4 <syscall+0x206>
		return -E_BAD_ENV;
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104303:	8b 45 14             	mov    0x14(%ebp),%eax
f0104306:	83 e0 05             	and    $0x5,%eax
f0104309:	83 f8 05             	cmp    $0x5,%eax
f010430c:	0f 85 bc 00 00 00    	jne    f01043ce <syscall+0x210>
		return -E_INVAL;
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f0104312:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104315:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f010431b:	0f 85 b7 00 00 00    	jne    f01043d8 <syscall+0x21a>
		return -E_INVAL;
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
f0104321:	83 ec 0c             	sub    $0xc,%esp
f0104324:	6a 01                	push   $0x1
f0104326:	e8 61 cb ff ff       	call   f0100e8c <page_alloc>
f010432b:	89 c6                	mov    %eax,%esi
	if(p==NULL)
f010432d:	83 c4 10             	add    $0x10,%esp
f0104330:	85 c0                	test   %eax,%eax
f0104332:	0f 84 aa 00 00 00    	je     f01043e2 <syscall+0x224>
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir,p,(void *)va,perm)<0)
f0104338:	ff 75 14             	pushl  0x14(%ebp)
f010433b:	ff 75 10             	pushl  0x10(%ebp)
f010433e:	50                   	push   %eax
f010433f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104342:	ff 70 60             	pushl  0x60(%eax)
f0104345:	e8 e3 cd ff ff       	call   f010112d <page_insert>
f010434a:	83 c4 10             	add    $0x10,%esp
f010434d:	85 c0                	test   %eax,%eax
f010434f:	79 16                	jns    f0104367 <syscall+0x1a9>
	{
		page_free(p);
f0104351:	83 ec 0c             	sub    $0xc,%esp
f0104354:	56                   	push   %esi
f0104355:	e8 a2 cb ff ff       	call   f0100efc <page_free>
f010435a:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f010435d:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
f0104362:	e9 bf 04 00 00       	jmp    f0104826 <syscall+0x668>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0104367:	2b 35 90 fe 22 f0    	sub    0xf022fe90,%esi
f010436d:	c1 fe 03             	sar    $0x3,%esi
f0104370:	c1 e6 0c             	shl    $0xc,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104373:	89 f0                	mov    %esi,%eax
f0104375:	c1 e8 0c             	shr    $0xc,%eax
f0104378:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f010437e:	72 12                	jb     f0104392 <syscall+0x1d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104380:	56                   	push   %esi
f0104381:	68 a4 60 10 f0       	push   $0xf01060a4
f0104386:	6a 58                	push   $0x58
f0104388:	68 15 6f 10 f0       	push   $0xf0106f15
f010438d:	e8 ae bc ff ff       	call   f0100040 <_panic>
	}
	memset(page2kva(p),0,PGSIZE);
f0104392:	83 ec 04             	sub    $0x4,%esp
f0104395:	68 00 10 00 00       	push   $0x1000
f010439a:	6a 00                	push   $0x0
f010439c:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01043a2:	56                   	push   %esi
f01043a3:	e8 fe 0f 00 00       	call   f01053a6 <memset>
f01043a8:	83 c4 10             	add    $0x10,%esp
f01043ab:	e9 76 04 00 00       	jmp    f0104826 <syscall+0x668>
	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
	{
		return -E_INVAL;
f01043b0:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043b5:	e9 6c 04 00 00       	jmp    f0104826 <syscall+0x668>
f01043ba:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043bf:	e9 62 04 00 00       	jmp    f0104826 <syscall+0x668>
	}
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f01043c4:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01043c9:	e9 58 04 00 00       	jmp    f0104826 <syscall+0x668>
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
		return -E_INVAL;
f01043ce:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043d3:	e9 4e 04 00 00       	jmp    f0104826 <syscall+0x668>
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
		return -E_INVAL;
f01043d8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043dd:	e9 44 04 00 00       	jmp    f0104826 <syscall+0x668>
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
	if(p==NULL)
		return -E_NO_MEM;
f01043e2:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
			return sys_env_destroy(a1);	
		case SYS_yield:
		 	sys_yield();	
			break;
		case SYS_page_alloc:
			return sys_page_alloc(a1,(void *)a2,(int )a3);
f01043e7:	e9 3a 04 00 00       	jmp    f0104826 <syscall+0x668>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
f01043ec:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01043f3:	0f 87 cb 00 00 00    	ja     f01044c4 <syscall+0x306>
f01043f9:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104400:	0f 85 c8 00 00 00    	jne    f01044ce <syscall+0x310>
f0104406:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010440d:	0f 87 bb 00 00 00    	ja     f01044ce <syscall+0x310>
f0104413:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010441a:	0f 85 b8 00 00 00    	jne    f01044d8 <syscall+0x31a>
	{

		return -E_INVAL;
	}
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104420:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104423:	83 e0 05             	and    $0x5,%eax
f0104426:	83 f8 05             	cmp    $0x5,%eax
f0104429:	0f 85 b3 00 00 00    	jne    f01044e2 <syscall+0x324>
	{
		return -E_INVAL;
	}
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f010442f:	8b 5d 1c             	mov    0x1c(%ebp),%ebx
f0104432:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f0104438:	0f 85 ae 00 00 00    	jne    f01044ec <syscall+0x32e>
	{
		return -E_INVAL;
	}
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
f010443e:	83 ec 04             	sub    $0x4,%esp
f0104441:	6a 01                	push   $0x1
f0104443:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104446:	50                   	push   %eax
f0104447:	ff 75 0c             	pushl  0xc(%ebp)
f010444a:	e8 f6 e8 ff ff       	call   f0102d45 <envid2env>
f010444f:	83 c4 10             	add    $0x10,%esp
f0104452:	85 c0                	test   %eax,%eax
f0104454:	0f 88 9c 00 00 00    	js     f01044f6 <syscall+0x338>
	{

		return -E_BAD_ENV;
	}
	if(envid2env(dstenvid,&desenv,1)<0)
f010445a:	83 ec 04             	sub    $0x4,%esp
f010445d:	6a 01                	push   $0x1
f010445f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104462:	50                   	push   %eax
f0104463:	ff 75 14             	pushl  0x14(%ebp)
f0104466:	e8 da e8 ff ff       	call   f0102d45 <envid2env>
f010446b:	83 c4 10             	add    $0x10,%esp
f010446e:	85 c0                	test   %eax,%eax
f0104470:	0f 88 8a 00 00 00    	js     f0104500 <syscall+0x342>
	{	
		return -E_BAD_ENV;
	}
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
f0104476:	83 ec 04             	sub    $0x4,%esp
f0104479:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010447c:	50                   	push   %eax
f010447d:	ff 75 10             	pushl  0x10(%ebp)
f0104480:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104483:	ff 70 60             	pushl  0x60(%eax)
f0104486:	e8 ba cb ff ff       	call   f0101045 <page_lookup>
	if (p==NULL||((perm&PTE_W)>0&&(*po_entry&PTE_W)==0))
f010448b:	83 c4 10             	add    $0x10,%esp
f010448e:	85 c0                	test   %eax,%eax
f0104490:	74 78                	je     f010450a <syscall+0x34c>
f0104492:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104496:	74 08                	je     f01044a0 <syscall+0x2e2>
f0104498:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010449b:	f6 02 02             	testb  $0x2,(%edx)
f010449e:	74 74                	je     f0104514 <syscall+0x356>
		return -E_INVAL;
	if(page_insert(desenv->env_pgdir,p,dstva,perm)<0)
f01044a0:	ff 75 1c             	pushl  0x1c(%ebp)
f01044a3:	ff 75 18             	pushl  0x18(%ebp)
f01044a6:	50                   	push   %eax
f01044a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044aa:	ff 70 60             	pushl  0x60(%eax)
f01044ad:	e8 7b cc ff ff       	call   f010112d <page_insert>
f01044b2:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f01044b5:	85 c0                	test   %eax,%eax
f01044b7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01044bc:	0f 48 d8             	cmovs  %eax,%ebx
f01044bf:	e9 62 03 00 00       	jmp    f0104826 <syscall+0x668>

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
	{

		return -E_INVAL;
f01044c4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01044c9:	e9 58 03 00 00       	jmp    f0104826 <syscall+0x668>
f01044ce:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01044d3:	e9 4e 03 00 00       	jmp    f0104826 <syscall+0x668>
f01044d8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01044dd:	e9 44 03 00 00       	jmp    f0104826 <syscall+0x668>
	}
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
	{
		return -E_INVAL;
f01044e2:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01044e7:	e9 3a 03 00 00       	jmp    f0104826 <syscall+0x668>
	}
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
	{
		return -E_INVAL;
f01044ec:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01044f1:	e9 30 03 00 00       	jmp    f0104826 <syscall+0x668>
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
	{

		return -E_BAD_ENV;
f01044f6:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01044fb:	e9 26 03 00 00       	jmp    f0104826 <syscall+0x668>
	}
	if(envid2env(dstenvid,&desenv,1)<0)
	{	
		return -E_BAD_ENV;
f0104500:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104505:	e9 1c 03 00 00       	jmp    f0104826 <syscall+0x668>
	}
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
	if (p==NULL||((perm&PTE_W)>0&&(*po_entry&PTE_W)==0))
		return -E_INVAL;
f010450a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010450f:	e9 12 03 00 00       	jmp    f0104826 <syscall+0x668>
f0104514:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104519:	e9 08 03 00 00       	jmp    f0104826 <syscall+0x668>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
f010451e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104525:	77 3f                	ja     f0104566 <syscall+0x3a8>
f0104527:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010452e:	75 40                	jne    f0104570 <syscall+0x3b2>
		return -E_INVAL;
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
f0104530:	83 ec 04             	sub    $0x4,%esp
f0104533:	6a 01                	push   $0x1
f0104535:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104538:	50                   	push   %eax
f0104539:	ff 75 0c             	pushl  0xc(%ebp)
f010453c:	e8 04 e8 ff ff       	call   f0102d45 <envid2env>
f0104541:	83 c4 10             	add    $0x10,%esp
f0104544:	85 c0                	test   %eax,%eax
f0104546:	78 32                	js     f010457a <syscall+0x3bc>
		return -E_BAD_ENV;
	page_remove(e->env_pgdir,va);
f0104548:	83 ec 08             	sub    $0x8,%esp
f010454b:	ff 75 10             	pushl  0x10(%ebp)
f010454e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104551:	ff 70 60             	pushl  0x60(%eax)
f0104554:	e8 87 cb ff ff       	call   f01010e0 <page_remove>
f0104559:	83 c4 10             	add    $0x10,%esp
	return 0;
f010455c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104561:	e9 c0 02 00 00       	jmp    f0104826 <syscall+0x668>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
		return -E_INVAL;
f0104566:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010456b:	e9 b6 02 00 00       	jmp    f0104826 <syscall+0x668>
f0104570:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104575:	e9 ac 02 00 00       	jmp    f0104826 <syscall+0x668>
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f010457a:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_page_alloc(a1,(void *)a2,(int )a3);
		case SYS_page_map:
			return 	sys_page_map((envid_t) a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int) a5); 
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
f010457f:	e9 a2 02 00 00       	jmp    f0104826 <syscall+0x668>
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f0104584:	e8 52 14 00 00       	call   f01059db <cpunum>
f0104589:	83 ec 08             	sub    $0x8,%esp
f010458c:	6b c0 74             	imul   $0x74,%eax,%eax
f010458f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104595:	ff 70 48             	pushl  0x48(%eax)
f0104598:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010459b:	50                   	push   %eax
f010459c:	e8 b5 e8 ff ff       	call   f0102e56 <env_alloc>
f01045a1:	83 c4 10             	add    $0x10,%esp
	{
		return r;
f01045a4:	89 c3                	mov    %eax,%ebx
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f01045a6:	85 c0                	test   %eax,%eax
f01045a8:	0f 88 78 02 00 00    	js     f0104826 <syscall+0x668>
	{
		return r;
	}
	newenv->env_status=ENV_NOT_RUNNABLE;
f01045ae:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01045b1:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv->env_tf=curenv->env_tf;
f01045b8:	e8 1e 14 00 00       	call   f01059db <cpunum>
f01045bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01045c0:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
f01045c6:	b9 11 00 00 00       	mov    $0x11,%ecx
f01045cb:	89 df                	mov    %ebx,%edi
f01045cd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv->env_tf.tf_regs.reg_eax=0;
f01045cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045d2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return newenv->env_id;
f01045d9:	8b 58 48             	mov    0x48(%eax),%ebx
f01045dc:	e9 45 02 00 00       	jmp    f0104826 <syscall+0x668>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
f01045e1:	8b 45 10             	mov    0x10(%ebp),%eax
f01045e4:	83 e8 02             	sub    $0x2,%eax
f01045e7:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01045ec:	75 2b                	jne    f0104619 <syscall+0x45b>
		return -E_INVAL;
	struct Env *e;
	int r=envid2env(envid,&e,1);
f01045ee:	83 ec 04             	sub    $0x4,%esp
f01045f1:	6a 01                	push   $0x1
f01045f3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045f6:	50                   	push   %eax
f01045f7:	ff 75 0c             	pushl  0xc(%ebp)
f01045fa:	e8 46 e7 ff ff       	call   f0102d45 <envid2env>
	if(r<0)	
f01045ff:	83 c4 10             	add    $0x10,%esp
f0104602:	85 c0                	test   %eax,%eax
f0104604:	78 1d                	js     f0104623 <syscall+0x465>
		return r;
	e->env_status=status;
f0104606:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104609:	8b 7d 10             	mov    0x10(%ebp),%edi
f010460c:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f010460f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104614:	e9 0d 02 00 00       	jmp    f0104826 <syscall+0x668>
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
		return -E_INVAL;
f0104619:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010461e:	e9 03 02 00 00       	jmp    f0104826 <syscall+0x668>
	struct Env *e;
	int r=envid2env(envid,&e,1);
	if(r<0)	
		return r;
f0104623:	89 c3                	mov    %eax,%ebx
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
f0104625:	e9 fc 01 00 00       	jmp    f0104826 <syscall+0x668>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	int r=envid2env(envid,&e,1);
f010462a:	83 ec 04             	sub    $0x4,%esp
f010462d:	6a 01                	push   $0x1
f010462f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104632:	50                   	push   %eax
f0104633:	ff 75 0c             	pushl  0xc(%ebp)
f0104636:	e8 0a e7 ff ff       	call   f0102d45 <envid2env>
	if(r<0)
f010463b:	83 c4 10             	add    $0x10,%esp
f010463e:	85 c0                	test   %eax,%eax
f0104640:	78 13                	js     f0104655 <syscall+0x497>
		return r;
	e->env_pgfault_upcall=func;
f0104642:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104645:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104648:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f010464b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104650:	e9 d1 01 00 00       	jmp    f0104826 <syscall+0x668>
{
	// LAB 4: Your code here.
	struct Env *e;
	int r=envid2env(envid,&e,1);
	if(r<0)
		return r;
f0104655:	89 c3                	mov    %eax,%ebx
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall(a1, (void *)a2);
f0104657:	e9 ca 01 00 00       	jmp    f0104826 <syscall+0x668>
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
	uint32_t r;
	struct Env *e;
	if(srcva>(void *)UTOP)
f010465c:	81 7d 14 00 00 c0 ee 	cmpl   $0xeec00000,0x14(%ebp)
f0104663:	0f 87 14 01 00 00    	ja     f010477d <syscall+0x5bf>
		return -E_NO_MEM ;
	if((r=envid2env(envid,&e,0))<0)
f0104669:	83 ec 04             	sub    $0x4,%esp
f010466c:	6a 00                	push   $0x0
f010466e:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104671:	50                   	push   %eax
f0104672:	ff 75 0c             	pushl  0xc(%ebp)
f0104675:	e8 cb e6 ff ff       	call   f0102d45 <envid2env>
		return -E_BAD_ENV;
	if((e->env_ipc_recving==0)||(e->env_ipc_from!=0))
f010467a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010467d:	83 c4 10             	add    $0x10,%esp
f0104680:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104684:	0f 84 fd 00 00 00    	je     f0104787 <syscall+0x5c9>
f010468a:	8b 58 74             	mov    0x74(%eax),%ebx
f010468d:	85 db                	test   %ebx,%ebx
f010468f:	0f 85 fc 00 00 00    	jne    f0104791 <syscall+0x5d3>
		return -E_IPC_NOT_RECV;
	if((uint32_t)srcva%PGSIZE!=0)
f0104695:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f010469c:	0f 85 f9 00 00 00    	jne    f010479b <syscall+0x5dd>
		return -E_INVAL ;
	if((perm&~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))!=0)
f01046a2:	f7 45 18 f8 f1 ff ff 	testl  $0xfffff1f8,0x18(%ebp)
f01046a9:	0f 85 f6 00 00 00    	jne    f01047a5 <syscall+0x5e7>
	//struct PageInfo *p=page_lookup(curenv->env_pgdir,srcva,&po_entry);
	//if(po_entry==NULL)
		//return -E_INVAL;
	//if(((perm|PTE_W)!=0)&&((*po_entry&PTE_W)==0))
	//	return -E_INVAL;
	if(e->env_ipc_dstva!=0)
f01046af:	83 78 6c 00          	cmpl   $0x0,0x6c(%eax)
f01046b3:	0f 84 86 00 00 00    	je     f010473f <syscall+0x581>
	{
		if(((perm&PTE_P)==0)||((perm&PTE_U)==0))
f01046b9:	8b 45 18             	mov    0x18(%ebp),%eax
f01046bc:	83 e0 05             	and    $0x5,%eax
f01046bf:	83 f8 05             	cmp    $0x5,%eax
f01046c2:	75 53                	jne    f0104717 <syscall+0x559>
		{
			return -E_INVAL ;
		}
		pte_t *po_entry;
		struct PageInfo *p=page_lookup(curenv->env_pgdir,srcva,&po_entry);
f01046c4:	e8 12 13 00 00       	call   f01059db <cpunum>
f01046c9:	83 ec 04             	sub    $0x4,%esp
f01046cc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046cf:	52                   	push   %edx
f01046d0:	ff 75 14             	pushl  0x14(%ebp)
f01046d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01046d6:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01046dc:	ff 70 60             	pushl  0x60(%eax)
f01046df:	e8 61 c9 ff ff       	call   f0101045 <page_lookup>
		if(po_entry==NULL)
f01046e4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01046e7:	83 c4 10             	add    $0x10,%esp
f01046ea:	85 d2                	test   %edx,%edx
f01046ec:	74 33                	je     f0104721 <syscall+0x563>
			return -E_INVAL;
		if(((perm|PTE_W)!=0)&&((*po_entry&PTE_W)==0))
f01046ee:	f6 02 02             	testb  $0x2,(%edx)
f01046f1:	74 38                	je     f010472b <syscall+0x56d>
			return -E_INVAL;
		if((r=page_insert(e->env_pgdir,p,e->env_ipc_dstva,perm)<0))
f01046f3:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01046f6:	ff 75 18             	pushl  0x18(%ebp)
f01046f9:	ff 72 6c             	pushl  0x6c(%edx)
f01046fc:	50                   	push   %eax
f01046fd:	ff 72 60             	pushl  0x60(%edx)
f0104700:	e8 28 ca ff ff       	call   f010112d <page_insert>
f0104705:	83 c4 10             	add    $0x10,%esp
f0104708:	85 c0                	test   %eax,%eax
f010470a:	78 29                	js     f0104735 <syscall+0x577>
			return -E_NO_MEM;
		e->env_ipc_perm=perm;
f010470c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010470f:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104712:	89 48 78             	mov    %ecx,0x78(%eax)
f0104715:	eb 35                	jmp    f010474c <syscall+0x58e>
	//	return -E_INVAL;
	if(e->env_ipc_dstva!=0)
	{
		if(((perm&PTE_P)==0)||((perm&PTE_U)==0))
		{
			return -E_INVAL ;
f0104717:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010471c:	e9 05 01 00 00       	jmp    f0104826 <syscall+0x668>
		}
		pte_t *po_entry;
		struct PageInfo *p=page_lookup(curenv->env_pgdir,srcva,&po_entry);
		if(po_entry==NULL)
			return -E_INVAL;
f0104721:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104726:	e9 fb 00 00 00       	jmp    f0104826 <syscall+0x668>
		if(((perm|PTE_W)!=0)&&((*po_entry&PTE_W)==0))
			return -E_INVAL;
f010472b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104730:	e9 f1 00 00 00       	jmp    f0104826 <syscall+0x668>
		if((r=page_insert(e->env_pgdir,p,e->env_ipc_dstva,perm)<0))
			return -E_NO_MEM;
f0104735:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
f010473a:	e9 e7 00 00 00       	jmp    f0104826 <syscall+0x668>
		e->env_ipc_perm=perm;
	}
	else
	{
		e->env_ipc_perm=0;
f010473f:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
		e->env_ipc_value=value;
f0104746:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104749:	89 78 70             	mov    %edi,0x70(%eax)
	}
	e->env_ipc_recving=0;
f010474c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010474f:	c6 46 68 00          	movb   $0x0,0x68(%esi)
	e->env_ipc_from=curenv->env_id;
f0104753:	e8 83 12 00 00       	call   f01059db <cpunum>
f0104758:	6b c0 74             	imul   $0x74,%eax,%eax
f010475b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104761:	8b 40 48             	mov    0x48(%eax),%eax
f0104764:	89 46 74             	mov    %eax,0x74(%esi)
	e->env_status=ENV_RUNNABLE;
f0104767:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010476a:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	e->env_tf.tf_regs.reg_eax=0;
f0104771:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
f0104778:	e9 a9 00 00 00       	jmp    f0104826 <syscall+0x668>
{
	// LAB 4: Your code here.
	uint32_t r;
	struct Env *e;
	if(srcva>(void *)UTOP)
		return -E_NO_MEM ;
f010477d:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
f0104782:	e9 9f 00 00 00       	jmp    f0104826 <syscall+0x668>
	if((r=envid2env(envid,&e,0))<0)
		return -E_BAD_ENV;
	if((e->env_ipc_recving==0)||(e->env_ipc_from!=0))
		return -E_IPC_NOT_RECV;
f0104787:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
f010478c:	e9 95 00 00 00       	jmp    f0104826 <syscall+0x668>
f0104791:	bb f9 ff ff ff       	mov    $0xfffffff9,%ebx
f0104796:	e9 8b 00 00 00       	jmp    f0104826 <syscall+0x668>
	if((uint32_t)srcva%PGSIZE!=0)
		return -E_INVAL ;
f010479b:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01047a0:	e9 81 00 00 00       	jmp    f0104826 <syscall+0x668>
	if((perm&~(PTE_U|PTE_P|PTE_AVAIL|PTE_W))!=0)
		return -E_INVAL ;
f01047a5:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall(a1, (void *)a2);
		case SYS_ipc_try_send:
			return sys_ipc_try_send(a1, a2, (void *)a3, a4);
f01047aa:	eb 7a                	jmp    f0104826 <syscall+0x668>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if(dstva>(void *)UTOP)
f01047ac:	81 7d 0c 00 00 c0 ee 	cmpl   $0xeec00000,0xc(%ebp)
f01047b3:	77 65                	ja     f010481a <syscall+0x65c>
		return -E_INVAL;
	if((((uint32_t)dstva%PGSIZE)!=0))
f01047b5:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01047bc:	75 63                	jne    f0104821 <syscall+0x663>
		return -E_INVAL;
	curenv->env_ipc_recving=true;
f01047be:	e8 18 12 00 00       	call   f01059db <cpunum>
f01047c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c6:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01047cc:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva=dstva;
f01047d0:	e8 06 12 00 00       	call   f01059db <cpunum>
f01047d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01047d8:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01047de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01047e1:	89 48 6c             	mov    %ecx,0x6c(%eax)
	curenv->env_ipc_from=0;
f01047e4:	e8 f2 11 00 00       	call   f01059db <cpunum>
f01047e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01047ec:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01047f2:	c7 40 74 00 00 00 00 	movl   $0x0,0x74(%eax)
	curenv->env_status=ENV_NOT_RUNNABLE;
f01047f9:	e8 dd 11 00 00       	call   f01059db <cpunum>
f01047fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0104801:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104807:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f010480e:	e8 3d f9 ff ff       	call   f0104150 <sched_yield>
		case SYS_ipc_try_send:
			return sys_ipc_try_send(a1, a2, (void *)a3, a4);
		case SYS_ipc_recv:
			return sys_ipc_recv((void *)a1); 
		default:
			return -E_INVAL;
f0104813:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104818:	eb 0c                	jmp    f0104826 <syscall+0x668>
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall(a1, (void *)a2);
		case SYS_ipc_try_send:
			return sys_ipc_try_send(a1, a2, (void *)a3, a4);
		case SYS_ipc_recv:
			return sys_ipc_recv((void *)a1); 
f010481a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010481f:	eb 05                	jmp    f0104826 <syscall+0x668>
f0104821:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		default:
			return -E_INVAL;
	}
	return 0;
}
f0104826:	89 d8                	mov    %ebx,%eax
f0104828:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010482b:	5b                   	pop    %ebx
f010482c:	5e                   	pop    %esi
f010482d:	5f                   	pop    %edi
f010482e:	5d                   	pop    %ebp
f010482f:	c3                   	ret    

f0104830 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104830:	55                   	push   %ebp
f0104831:	89 e5                	mov    %esp,%ebp
f0104833:	57                   	push   %edi
f0104834:	56                   	push   %esi
f0104835:	53                   	push   %ebx
f0104836:	83 ec 14             	sub    $0x14,%esp
f0104839:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010483c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010483f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104842:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104845:	8b 1a                	mov    (%edx),%ebx
f0104847:	8b 01                	mov    (%ecx),%eax
f0104849:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010484c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104853:	eb 7f                	jmp    f01048d4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104855:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104858:	01 d8                	add    %ebx,%eax
f010485a:	89 c6                	mov    %eax,%esi
f010485c:	c1 ee 1f             	shr    $0x1f,%esi
f010485f:	01 c6                	add    %eax,%esi
f0104861:	d1 fe                	sar    %esi
f0104863:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104866:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104869:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010486c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010486e:	eb 03                	jmp    f0104873 <stab_binsearch+0x43>
			m--;
f0104870:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104873:	39 c3                	cmp    %eax,%ebx
f0104875:	7f 0d                	jg     f0104884 <stab_binsearch+0x54>
f0104877:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010487b:	83 ea 0c             	sub    $0xc,%edx
f010487e:	39 f9                	cmp    %edi,%ecx
f0104880:	75 ee                	jne    f0104870 <stab_binsearch+0x40>
f0104882:	eb 05                	jmp    f0104889 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104884:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104887:	eb 4b                	jmp    f01048d4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104889:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010488c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010488f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104893:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104896:	76 11                	jbe    f01048a9 <stab_binsearch+0x79>
			*region_left = m;
f0104898:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010489b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010489d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048a7:	eb 2b                	jmp    f01048d4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048a9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048ac:	73 14                	jae    f01048c2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01048ae:	83 e8 01             	sub    $0x1,%eax
f01048b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048b4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048b7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048c0:	eb 12                	jmp    f01048d4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048c2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048c5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01048c7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048cb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048cd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01048d4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01048d7:	0f 8e 78 ff ff ff    	jle    f0104855 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048dd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048e1:	75 0f                	jne    f01048f2 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01048e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048e6:	8b 00                	mov    (%eax),%eax
f01048e8:	83 e8 01             	sub    $0x1,%eax
f01048eb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048ee:	89 06                	mov    %eax,(%esi)
f01048f0:	eb 2c                	jmp    f010491e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01048f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048f5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01048f7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048fa:	8b 0e                	mov    (%esi),%ecx
f01048fc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048ff:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104902:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104905:	eb 03                	jmp    f010490a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104907:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010490a:	39 c8                	cmp    %ecx,%eax
f010490c:	7e 0b                	jle    f0104919 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010490e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104912:	83 ea 0c             	sub    $0xc,%edx
f0104915:	39 df                	cmp    %ebx,%edi
f0104917:	75 ee                	jne    f0104907 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104919:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010491c:	89 06                	mov    %eax,(%esi)
	}
}
f010491e:	83 c4 14             	add    $0x14,%esp
f0104921:	5b                   	pop    %ebx
f0104922:	5e                   	pop    %esi
f0104923:	5f                   	pop    %edi
f0104924:	5d                   	pop    %ebp
f0104925:	c3                   	ret    

f0104926 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104926:	55                   	push   %ebp
f0104927:	89 e5                	mov    %esp,%ebp
f0104929:	57                   	push   %edi
f010492a:	56                   	push   %esi
f010492b:	53                   	push   %ebx
f010492c:	83 ec 2c             	sub    $0x2c,%esp
f010492f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104932:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104935:	c7 06 54 77 10 f0    	movl   $0xf0107754,(%esi)
	info->eip_line = 0;
f010493b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104942:	c7 46 08 54 77 10 f0 	movl   $0xf0107754,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104949:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0104950:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104953:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010495a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104960:	0f 87 a3 00 00 00    	ja     f0104a09 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
f0104966:	e8 70 10 00 00       	call   f01059db <cpunum>
f010496b:	6a 00                	push   $0x0
f010496d:	6a 10                	push   $0x10
f010496f:	68 00 00 20 00       	push   $0x200000
f0104974:	6b c0 74             	imul   $0x74,%eax,%eax
f0104977:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f010497d:	e8 6e e2 ff ff       	call   f0102bf0 <user_mem_check>
f0104982:	83 c4 10             	add    $0x10,%esp
f0104985:	85 c0                	test   %eax,%eax
f0104987:	0f 88 d4 01 00 00    	js     f0104b61 <debuginfo_eip+0x23b>
			return -1;
		stabs = usd->stabs;
f010498d:	a1 00 00 20 00       	mov    0x200000,%eax
f0104992:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104995:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010499b:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01049a1:	89 55 cc             	mov    %edx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01049a4:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01049a9:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
f01049ac:	e8 2a 10 00 00       	call   f01059db <cpunum>
f01049b1:	6a 00                	push   $0x0
f01049b3:	89 da                	mov    %ebx,%edx
f01049b5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01049b8:	29 ca                	sub    %ecx,%edx
f01049ba:	c1 fa 02             	sar    $0x2,%edx
f01049bd:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01049c3:	52                   	push   %edx
f01049c4:	51                   	push   %ecx
f01049c5:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c8:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01049ce:	e8 1d e2 ff ff       	call   f0102bf0 <user_mem_check>
f01049d3:	83 c4 10             	add    $0x10,%esp
f01049d6:	85 c0                	test   %eax,%eax
f01049d8:	0f 88 8a 01 00 00    	js     f0104b68 <debuginfo_eip+0x242>
f01049de:	e8 f8 0f 00 00       	call   f01059db <cpunum>
f01049e3:	6a 00                	push   $0x0
f01049e5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01049e8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01049eb:	29 ca                	sub    %ecx,%edx
f01049ed:	52                   	push   %edx
f01049ee:	51                   	push   %ecx
f01049ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01049f2:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01049f8:	e8 f3 e1 ff ff       	call   f0102bf0 <user_mem_check>
f01049fd:	83 c4 10             	add    $0x10,%esp
f0104a00:	85 c0                	test   %eax,%eax
f0104a02:	79 1f                	jns    f0104a23 <debuginfo_eip+0xfd>
f0104a04:	e9 66 01 00 00       	jmp    f0104b6f <debuginfo_eip+0x249>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a09:	c7 45 d0 bc 51 11 f0 	movl   $0xf01151bc,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a10:	c7 45 cc a5 1b 11 f0 	movl   $0xf0111ba5,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a17:	bb a4 1b 11 f0       	mov    $0xf0111ba4,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a1c:	c7 45 d4 38 7c 10 f0 	movl   $0xf0107c38,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a23:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104a26:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104a29:	0f 83 47 01 00 00    	jae    f0104b76 <debuginfo_eip+0x250>
f0104a2f:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a33:	0f 85 44 01 00 00    	jne    f0104b7d <debuginfo_eip+0x257>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104a39:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104a40:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0104a43:	c1 fb 02             	sar    $0x2,%ebx
f0104a46:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0104a4c:	83 e8 01             	sub    $0x1,%eax
f0104a4f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104a52:	83 ec 08             	sub    $0x8,%esp
f0104a55:	57                   	push   %edi
f0104a56:	6a 64                	push   $0x64
f0104a58:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104a5b:	89 d1                	mov    %edx,%ecx
f0104a5d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104a60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104a63:	89 d8                	mov    %ebx,%eax
f0104a65:	e8 c6 fd ff ff       	call   f0104830 <stab_binsearch>
	if (lfile == 0)
f0104a6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a6d:	83 c4 10             	add    $0x10,%esp
f0104a70:	85 c0                	test   %eax,%eax
f0104a72:	0f 84 0c 01 00 00    	je     f0104b84 <debuginfo_eip+0x25e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104a78:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104a7b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a7e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104a81:	83 ec 08             	sub    $0x8,%esp
f0104a84:	57                   	push   %edi
f0104a85:	6a 24                	push   $0x24
f0104a87:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104a8a:	89 d1                	mov    %edx,%ecx
f0104a8c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104a8f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0104a92:	89 d8                	mov    %ebx,%eax
f0104a94:	e8 97 fd ff ff       	call   f0104830 <stab_binsearch>

	if (lfun <= rfun) {
f0104a99:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104a9c:	83 c4 10             	add    $0x10,%esp
f0104a9f:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104aa2:	7f 24                	jg     f0104ac8 <debuginfo_eip+0x1a2>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104aa4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104aa7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104aaa:	8d 14 87             	lea    (%edi,%eax,4),%edx
f0104aad:	8b 02                	mov    (%edx),%eax
f0104aaf:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104ab2:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104ab5:	29 f9                	sub    %edi,%ecx
f0104ab7:	39 c8                	cmp    %ecx,%eax
f0104ab9:	73 05                	jae    f0104ac0 <debuginfo_eip+0x19a>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104abb:	01 f8                	add    %edi,%eax
f0104abd:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ac0:	8b 42 08             	mov    0x8(%edx),%eax
f0104ac3:	89 46 10             	mov    %eax,0x10(%esi)
f0104ac6:	eb 06                	jmp    f0104ace <debuginfo_eip+0x1a8>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104ac8:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104acb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104ace:	83 ec 08             	sub    $0x8,%esp
f0104ad1:	6a 3a                	push   $0x3a
f0104ad3:	ff 76 08             	pushl  0x8(%esi)
f0104ad6:	e8 af 08 00 00       	call   f010538a <strfind>
f0104adb:	2b 46 08             	sub    0x8(%esi),%eax
f0104ade:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104ae1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ae4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104ae7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104aea:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104aed:	83 c4 10             	add    $0x10,%esp
f0104af0:	eb 06                	jmp    f0104af8 <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104af2:	83 eb 01             	sub    $0x1,%ebx
f0104af5:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104af8:	39 fb                	cmp    %edi,%ebx
f0104afa:	7c 2d                	jl     f0104b29 <debuginfo_eip+0x203>
	       && stabs[lline].n_type != N_SOL
f0104afc:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104b00:	80 fa 84             	cmp    $0x84,%dl
f0104b03:	74 0b                	je     f0104b10 <debuginfo_eip+0x1ea>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104b05:	80 fa 64             	cmp    $0x64,%dl
f0104b08:	75 e8                	jne    f0104af2 <debuginfo_eip+0x1cc>
f0104b0a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104b0e:	74 e2                	je     f0104af2 <debuginfo_eip+0x1cc>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104b10:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104b13:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104b16:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104b19:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104b1c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0104b1f:	29 f8                	sub    %edi,%eax
f0104b21:	39 c2                	cmp    %eax,%edx
f0104b23:	73 04                	jae    f0104b29 <debuginfo_eip+0x203>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104b25:	01 fa                	add    %edi,%edx
f0104b27:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b29:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104b2c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b2f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104b34:	39 cb                	cmp    %ecx,%ebx
f0104b36:	7d 58                	jge    f0104b90 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
f0104b38:	8d 53 01             	lea    0x1(%ebx),%edx
f0104b3b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104b3e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104b41:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104b44:	eb 07                	jmp    f0104b4d <debuginfo_eip+0x227>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104b46:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104b4a:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104b4d:	39 ca                	cmp    %ecx,%edx
f0104b4f:	74 3a                	je     f0104b8b <debuginfo_eip+0x265>
f0104b51:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104b54:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0104b58:	74 ec                	je     f0104b46 <debuginfo_eip+0x220>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b5f:	eb 2f                	jmp    f0104b90 <debuginfo_eip+0x26a>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
			return -1;
f0104b61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b66:	eb 28                	jmp    f0104b90 <debuginfo_eip+0x26a>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
		{
			return -1;
f0104b68:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b6d:	eb 21                	jmp    f0104b90 <debuginfo_eip+0x26a>
f0104b6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b74:	eb 1a                	jmp    f0104b90 <debuginfo_eip+0x26a>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104b76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b7b:	eb 13                	jmp    f0104b90 <debuginfo_eip+0x26a>
f0104b7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b82:	eb 0c                	jmp    f0104b90 <debuginfo_eip+0x26a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104b84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b89:	eb 05                	jmp    f0104b90 <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104b90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b93:	5b                   	pop    %ebx
f0104b94:	5e                   	pop    %esi
f0104b95:	5f                   	pop    %edi
f0104b96:	5d                   	pop    %ebp
f0104b97:	c3                   	ret    

f0104b98 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104b98:	55                   	push   %ebp
f0104b99:	89 e5                	mov    %esp,%ebp
f0104b9b:	57                   	push   %edi
f0104b9c:	56                   	push   %esi
f0104b9d:	53                   	push   %ebx
f0104b9e:	83 ec 1c             	sub    $0x1c,%esp
f0104ba1:	89 c7                	mov    %eax,%edi
f0104ba3:	89 d6                	mov    %edx,%esi
f0104ba5:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ba8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104bab:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104bae:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104bb1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104bb4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104bb9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104bbc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104bbf:	39 d3                	cmp    %edx,%ebx
f0104bc1:	72 05                	jb     f0104bc8 <printnum+0x30>
f0104bc3:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104bc6:	77 45                	ja     f0104c0d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104bc8:	83 ec 0c             	sub    $0xc,%esp
f0104bcb:	ff 75 18             	pushl  0x18(%ebp)
f0104bce:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bd1:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104bd4:	53                   	push   %ebx
f0104bd5:	ff 75 10             	pushl  0x10(%ebp)
f0104bd8:	83 ec 08             	sub    $0x8,%esp
f0104bdb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104bde:	ff 75 e0             	pushl  -0x20(%ebp)
f0104be1:	ff 75 dc             	pushl  -0x24(%ebp)
f0104be4:	ff 75 d8             	pushl  -0x28(%ebp)
f0104be7:	e8 f4 11 00 00       	call   f0105de0 <__udivdi3>
f0104bec:	83 c4 18             	add    $0x18,%esp
f0104bef:	52                   	push   %edx
f0104bf0:	50                   	push   %eax
f0104bf1:	89 f2                	mov    %esi,%edx
f0104bf3:	89 f8                	mov    %edi,%eax
f0104bf5:	e8 9e ff ff ff       	call   f0104b98 <printnum>
f0104bfa:	83 c4 20             	add    $0x20,%esp
f0104bfd:	eb 18                	jmp    f0104c17 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104bff:	83 ec 08             	sub    $0x8,%esp
f0104c02:	56                   	push   %esi
f0104c03:	ff 75 18             	pushl  0x18(%ebp)
f0104c06:	ff d7                	call   *%edi
f0104c08:	83 c4 10             	add    $0x10,%esp
f0104c0b:	eb 03                	jmp    f0104c10 <printnum+0x78>
f0104c0d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104c10:	83 eb 01             	sub    $0x1,%ebx
f0104c13:	85 db                	test   %ebx,%ebx
f0104c15:	7f e8                	jg     f0104bff <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104c17:	83 ec 08             	sub    $0x8,%esp
f0104c1a:	56                   	push   %esi
f0104c1b:	83 ec 04             	sub    $0x4,%esp
f0104c1e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c21:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c24:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c27:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c2a:	e8 e1 12 00 00       	call   f0105f10 <__umoddi3>
f0104c2f:	83 c4 14             	add    $0x14,%esp
f0104c32:	0f be 80 5e 77 10 f0 	movsbl -0xfef88a2(%eax),%eax
f0104c39:	50                   	push   %eax
f0104c3a:	ff d7                	call   *%edi
}
f0104c3c:	83 c4 10             	add    $0x10,%esp
f0104c3f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c42:	5b                   	pop    %ebx
f0104c43:	5e                   	pop    %esi
f0104c44:	5f                   	pop    %edi
f0104c45:	5d                   	pop    %ebp
f0104c46:	c3                   	ret    

f0104c47 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104c47:	55                   	push   %ebp
f0104c48:	89 e5                	mov    %esp,%ebp
f0104c4a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104c4d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104c51:	8b 10                	mov    (%eax),%edx
f0104c53:	3b 50 04             	cmp    0x4(%eax),%edx
f0104c56:	73 0a                	jae    f0104c62 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104c58:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104c5b:	89 08                	mov    %ecx,(%eax)
f0104c5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c60:	88 02                	mov    %al,(%edx)
}
f0104c62:	5d                   	pop    %ebp
f0104c63:	c3                   	ret    

f0104c64 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104c64:	55                   	push   %ebp
f0104c65:	89 e5                	mov    %esp,%ebp
f0104c67:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104c6a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104c6d:	50                   	push   %eax
f0104c6e:	ff 75 10             	pushl  0x10(%ebp)
f0104c71:	ff 75 0c             	pushl  0xc(%ebp)
f0104c74:	ff 75 08             	pushl  0x8(%ebp)
f0104c77:	e8 05 00 00 00       	call   f0104c81 <vprintfmt>
	va_end(ap);
}
f0104c7c:	83 c4 10             	add    $0x10,%esp
f0104c7f:	c9                   	leave  
f0104c80:	c3                   	ret    

f0104c81 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104c81:	55                   	push   %ebp
f0104c82:	89 e5                	mov    %esp,%ebp
f0104c84:	57                   	push   %edi
f0104c85:	56                   	push   %esi
f0104c86:	53                   	push   %ebx
f0104c87:	83 ec 2c             	sub    $0x2c,%esp
f0104c8a:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c8d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c90:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104c93:	eb 12                	jmp    f0104ca7 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104c95:	85 c0                	test   %eax,%eax
f0104c97:	0f 84 42 04 00 00    	je     f01050df <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0104c9d:	83 ec 08             	sub    $0x8,%esp
f0104ca0:	53                   	push   %ebx
f0104ca1:	50                   	push   %eax
f0104ca2:	ff d6                	call   *%esi
f0104ca4:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104ca7:	83 c7 01             	add    $0x1,%edi
f0104caa:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104cae:	83 f8 25             	cmp    $0x25,%eax
f0104cb1:	75 e2                	jne    f0104c95 <vprintfmt+0x14>
f0104cb3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104cb7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104cbe:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104cc5:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104ccc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104cd1:	eb 07                	jmp    f0104cda <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cd3:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104cd6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cda:	8d 47 01             	lea    0x1(%edi),%eax
f0104cdd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104ce0:	0f b6 07             	movzbl (%edi),%eax
f0104ce3:	0f b6 d0             	movzbl %al,%edx
f0104ce6:	83 e8 23             	sub    $0x23,%eax
f0104ce9:	3c 55                	cmp    $0x55,%al
f0104ceb:	0f 87 d3 03 00 00    	ja     f01050c4 <vprintfmt+0x443>
f0104cf1:	0f b6 c0             	movzbl %al,%eax
f0104cf4:	ff 24 85 20 78 10 f0 	jmp    *-0xfef87e0(,%eax,4)
f0104cfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104cfe:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104d02:	eb d6                	jmp    f0104cda <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d07:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d0c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104d0f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104d12:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104d16:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104d19:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104d1c:	83 f9 09             	cmp    $0x9,%ecx
f0104d1f:	77 3f                	ja     f0104d60 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104d21:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104d24:	eb e9                	jmp    f0104d0f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104d26:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d29:	8b 00                	mov    (%eax),%eax
f0104d2b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104d2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d31:	8d 40 04             	lea    0x4(%eax),%eax
f0104d34:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104d3a:	eb 2a                	jmp    f0104d66 <vprintfmt+0xe5>
f0104d3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d3f:	85 c0                	test   %eax,%eax
f0104d41:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d46:	0f 49 d0             	cmovns %eax,%edx
f0104d49:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d4f:	eb 89                	jmp    f0104cda <vprintfmt+0x59>
f0104d51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104d54:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104d5b:	e9 7a ff ff ff       	jmp    f0104cda <vprintfmt+0x59>
f0104d60:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104d63:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104d66:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104d6a:	0f 89 6a ff ff ff    	jns    f0104cda <vprintfmt+0x59>
				width = precision, precision = -1;
f0104d70:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104d73:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d76:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d7d:	e9 58 ff ff ff       	jmp    f0104cda <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104d82:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d85:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104d88:	e9 4d ff ff ff       	jmp    f0104cda <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104d8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d90:	8d 78 04             	lea    0x4(%eax),%edi
f0104d93:	83 ec 08             	sub    $0x8,%esp
f0104d96:	53                   	push   %ebx
f0104d97:	ff 30                	pushl  (%eax)
f0104d99:	ff d6                	call   *%esi
			break;
f0104d9b:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104d9e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104da1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104da4:	e9 fe fe ff ff       	jmp    f0104ca7 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104da9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dac:	8d 78 04             	lea    0x4(%eax),%edi
f0104daf:	8b 00                	mov    (%eax),%eax
f0104db1:	99                   	cltd   
f0104db2:	31 d0                	xor    %edx,%eax
f0104db4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104db6:	83 f8 08             	cmp    $0x8,%eax
f0104db9:	7f 0b                	jg     f0104dc6 <vprintfmt+0x145>
f0104dbb:	8b 14 85 80 79 10 f0 	mov    -0xfef8680(,%eax,4),%edx
f0104dc2:	85 d2                	test   %edx,%edx
f0104dc4:	75 1b                	jne    f0104de1 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0104dc6:	50                   	push   %eax
f0104dc7:	68 76 77 10 f0       	push   $0xf0107776
f0104dcc:	53                   	push   %ebx
f0104dcd:	56                   	push   %esi
f0104dce:	e8 91 fe ff ff       	call   f0104c64 <printfmt>
f0104dd3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104dd6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dd9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104ddc:	e9 c6 fe ff ff       	jmp    f0104ca7 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104de1:	52                   	push   %edx
f0104de2:	68 41 6f 10 f0       	push   $0xf0106f41
f0104de7:	53                   	push   %ebx
f0104de8:	56                   	push   %esi
f0104de9:	e8 76 fe ff ff       	call   f0104c64 <printfmt>
f0104dee:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104df1:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104df7:	e9 ab fe ff ff       	jmp    f0104ca7 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104dfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dff:	83 c0 04             	add    $0x4,%eax
f0104e02:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104e05:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e08:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104e0a:	85 ff                	test   %edi,%edi
f0104e0c:	b8 6f 77 10 f0       	mov    $0xf010776f,%eax
f0104e11:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104e14:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e18:	0f 8e 94 00 00 00    	jle    f0104eb2 <vprintfmt+0x231>
f0104e1e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104e22:	0f 84 98 00 00 00    	je     f0104ec0 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e28:	83 ec 08             	sub    $0x8,%esp
f0104e2b:	ff 75 d0             	pushl  -0x30(%ebp)
f0104e2e:	57                   	push   %edi
f0104e2f:	e8 0c 04 00 00       	call   f0105240 <strnlen>
f0104e34:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104e37:	29 c1                	sub    %eax,%ecx
f0104e39:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104e3c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104e3f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104e43:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e46:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104e49:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e4b:	eb 0f                	jmp    f0104e5c <vprintfmt+0x1db>
					putch(padc, putdat);
f0104e4d:	83 ec 08             	sub    $0x8,%esp
f0104e50:	53                   	push   %ebx
f0104e51:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e54:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e56:	83 ef 01             	sub    $0x1,%edi
f0104e59:	83 c4 10             	add    $0x10,%esp
f0104e5c:	85 ff                	test   %edi,%edi
f0104e5e:	7f ed                	jg     f0104e4d <vprintfmt+0x1cc>
f0104e60:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104e63:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104e66:	85 c9                	test   %ecx,%ecx
f0104e68:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e6d:	0f 49 c1             	cmovns %ecx,%eax
f0104e70:	29 c1                	sub    %eax,%ecx
f0104e72:	89 75 08             	mov    %esi,0x8(%ebp)
f0104e75:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104e78:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104e7b:	89 cb                	mov    %ecx,%ebx
f0104e7d:	eb 4d                	jmp    f0104ecc <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104e7f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104e83:	74 1b                	je     f0104ea0 <vprintfmt+0x21f>
f0104e85:	0f be c0             	movsbl %al,%eax
f0104e88:	83 e8 20             	sub    $0x20,%eax
f0104e8b:	83 f8 5e             	cmp    $0x5e,%eax
f0104e8e:	76 10                	jbe    f0104ea0 <vprintfmt+0x21f>
					putch('?', putdat);
f0104e90:	83 ec 08             	sub    $0x8,%esp
f0104e93:	ff 75 0c             	pushl  0xc(%ebp)
f0104e96:	6a 3f                	push   $0x3f
f0104e98:	ff 55 08             	call   *0x8(%ebp)
f0104e9b:	83 c4 10             	add    $0x10,%esp
f0104e9e:	eb 0d                	jmp    f0104ead <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0104ea0:	83 ec 08             	sub    $0x8,%esp
f0104ea3:	ff 75 0c             	pushl  0xc(%ebp)
f0104ea6:	52                   	push   %edx
f0104ea7:	ff 55 08             	call   *0x8(%ebp)
f0104eaa:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104ead:	83 eb 01             	sub    $0x1,%ebx
f0104eb0:	eb 1a                	jmp    f0104ecc <vprintfmt+0x24b>
f0104eb2:	89 75 08             	mov    %esi,0x8(%ebp)
f0104eb5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104eb8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104ebb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104ebe:	eb 0c                	jmp    f0104ecc <vprintfmt+0x24b>
f0104ec0:	89 75 08             	mov    %esi,0x8(%ebp)
f0104ec3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104ec6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104ec9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104ecc:	83 c7 01             	add    $0x1,%edi
f0104ecf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104ed3:	0f be d0             	movsbl %al,%edx
f0104ed6:	85 d2                	test   %edx,%edx
f0104ed8:	74 23                	je     f0104efd <vprintfmt+0x27c>
f0104eda:	85 f6                	test   %esi,%esi
f0104edc:	78 a1                	js     f0104e7f <vprintfmt+0x1fe>
f0104ede:	83 ee 01             	sub    $0x1,%esi
f0104ee1:	79 9c                	jns    f0104e7f <vprintfmt+0x1fe>
f0104ee3:	89 df                	mov    %ebx,%edi
f0104ee5:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ee8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104eeb:	eb 18                	jmp    f0104f05 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104eed:	83 ec 08             	sub    $0x8,%esp
f0104ef0:	53                   	push   %ebx
f0104ef1:	6a 20                	push   $0x20
f0104ef3:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104ef5:	83 ef 01             	sub    $0x1,%edi
f0104ef8:	83 c4 10             	add    $0x10,%esp
f0104efb:	eb 08                	jmp    f0104f05 <vprintfmt+0x284>
f0104efd:	89 df                	mov    %ebx,%edi
f0104eff:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f02:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f05:	85 ff                	test   %edi,%edi
f0104f07:	7f e4                	jg     f0104eed <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104f09:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104f0c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f0f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f12:	e9 90 fd ff ff       	jmp    f0104ca7 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104f17:	83 f9 01             	cmp    $0x1,%ecx
f0104f1a:	7e 19                	jle    f0104f35 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0104f1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f1f:	8b 50 04             	mov    0x4(%eax),%edx
f0104f22:	8b 00                	mov    (%eax),%eax
f0104f24:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f27:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104f2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f2d:	8d 40 08             	lea    0x8(%eax),%eax
f0104f30:	89 45 14             	mov    %eax,0x14(%ebp)
f0104f33:	eb 38                	jmp    f0104f6d <vprintfmt+0x2ec>
	else if (lflag)
f0104f35:	85 c9                	test   %ecx,%ecx
f0104f37:	74 1b                	je     f0104f54 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0104f39:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f3c:	8b 00                	mov    (%eax),%eax
f0104f3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f41:	89 c1                	mov    %eax,%ecx
f0104f43:	c1 f9 1f             	sar    $0x1f,%ecx
f0104f46:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104f49:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f4c:	8d 40 04             	lea    0x4(%eax),%eax
f0104f4f:	89 45 14             	mov    %eax,0x14(%ebp)
f0104f52:	eb 19                	jmp    f0104f6d <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0104f54:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f57:	8b 00                	mov    (%eax),%eax
f0104f59:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f5c:	89 c1                	mov    %eax,%ecx
f0104f5e:	c1 f9 1f             	sar    $0x1f,%ecx
f0104f61:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104f64:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f67:	8d 40 04             	lea    0x4(%eax),%eax
f0104f6a:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104f6d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104f70:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104f73:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104f78:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104f7c:	0f 89 0e 01 00 00    	jns    f0105090 <vprintfmt+0x40f>
				putch('-', putdat);
f0104f82:	83 ec 08             	sub    $0x8,%esp
f0104f85:	53                   	push   %ebx
f0104f86:	6a 2d                	push   $0x2d
f0104f88:	ff d6                	call   *%esi
				num = -(long long) num;
f0104f8a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104f8d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104f90:	f7 da                	neg    %edx
f0104f92:	83 d1 00             	adc    $0x0,%ecx
f0104f95:	f7 d9                	neg    %ecx
f0104f97:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104f9a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104f9f:	e9 ec 00 00 00       	jmp    f0105090 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104fa4:	83 f9 01             	cmp    $0x1,%ecx
f0104fa7:	7e 18                	jle    f0104fc1 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0104fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fac:	8b 10                	mov    (%eax),%edx
f0104fae:	8b 48 04             	mov    0x4(%eax),%ecx
f0104fb1:	8d 40 08             	lea    0x8(%eax),%eax
f0104fb4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104fb7:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104fbc:	e9 cf 00 00 00       	jmp    f0105090 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104fc1:	85 c9                	test   %ecx,%ecx
f0104fc3:	74 1a                	je     f0104fdf <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0104fc5:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fc8:	8b 10                	mov    (%eax),%edx
f0104fca:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104fcf:	8d 40 04             	lea    0x4(%eax),%eax
f0104fd2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104fd5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104fda:	e9 b1 00 00 00       	jmp    f0105090 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104fdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fe2:	8b 10                	mov    (%eax),%edx
f0104fe4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104fe9:	8d 40 04             	lea    0x4(%eax),%eax
f0104fec:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104fef:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104ff4:	e9 97 00 00 00       	jmp    f0105090 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0104ff9:	83 ec 08             	sub    $0x8,%esp
f0104ffc:	53                   	push   %ebx
f0104ffd:	6a 58                	push   $0x58
f0104fff:	ff d6                	call   *%esi
			putch('X', putdat);
f0105001:	83 c4 08             	add    $0x8,%esp
f0105004:	53                   	push   %ebx
f0105005:	6a 58                	push   $0x58
f0105007:	ff d6                	call   *%esi
			putch('X', putdat);
f0105009:	83 c4 08             	add    $0x8,%esp
f010500c:	53                   	push   %ebx
f010500d:	6a 58                	push   $0x58
f010500f:	ff d6                	call   *%esi
			break;
f0105011:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105014:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0105017:	e9 8b fc ff ff       	jmp    f0104ca7 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010501c:	83 ec 08             	sub    $0x8,%esp
f010501f:	53                   	push   %ebx
f0105020:	6a 30                	push   $0x30
f0105022:	ff d6                	call   *%esi
			putch('x', putdat);
f0105024:	83 c4 08             	add    $0x8,%esp
f0105027:	53                   	push   %ebx
f0105028:	6a 78                	push   $0x78
f010502a:	ff d6                	call   *%esi
			num = (unsigned long long)
f010502c:	8b 45 14             	mov    0x14(%ebp),%eax
f010502f:	8b 10                	mov    (%eax),%edx
f0105031:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0105036:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105039:	8d 40 04             	lea    0x4(%eax),%eax
f010503c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010503f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0105044:	eb 4a                	jmp    f0105090 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105046:	83 f9 01             	cmp    $0x1,%ecx
f0105049:	7e 15                	jle    f0105060 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f010504b:	8b 45 14             	mov    0x14(%ebp),%eax
f010504e:	8b 10                	mov    (%eax),%edx
f0105050:	8b 48 04             	mov    0x4(%eax),%ecx
f0105053:	8d 40 08             	lea    0x8(%eax),%eax
f0105056:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0105059:	b8 10 00 00 00       	mov    $0x10,%eax
f010505e:	eb 30                	jmp    f0105090 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0105060:	85 c9                	test   %ecx,%ecx
f0105062:	74 17                	je     f010507b <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0105064:	8b 45 14             	mov    0x14(%ebp),%eax
f0105067:	8b 10                	mov    (%eax),%edx
f0105069:	b9 00 00 00 00       	mov    $0x0,%ecx
f010506e:	8d 40 04             	lea    0x4(%eax),%eax
f0105071:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0105074:	b8 10 00 00 00       	mov    $0x10,%eax
f0105079:	eb 15                	jmp    f0105090 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010507b:	8b 45 14             	mov    0x14(%ebp),%eax
f010507e:	8b 10                	mov    (%eax),%edx
f0105080:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105085:	8d 40 04             	lea    0x4(%eax),%eax
f0105088:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010508b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105090:	83 ec 0c             	sub    $0xc,%esp
f0105093:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0105097:	57                   	push   %edi
f0105098:	ff 75 e0             	pushl  -0x20(%ebp)
f010509b:	50                   	push   %eax
f010509c:	51                   	push   %ecx
f010509d:	52                   	push   %edx
f010509e:	89 da                	mov    %ebx,%edx
f01050a0:	89 f0                	mov    %esi,%eax
f01050a2:	e8 f1 fa ff ff       	call   f0104b98 <printnum>
			break;
f01050a7:	83 c4 20             	add    $0x20,%esp
f01050aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050ad:	e9 f5 fb ff ff       	jmp    f0104ca7 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050b2:	83 ec 08             	sub    $0x8,%esp
f01050b5:	53                   	push   %ebx
f01050b6:	52                   	push   %edx
f01050b7:	ff d6                	call   *%esi
			break;
f01050b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01050bf:	e9 e3 fb ff ff       	jmp    f0104ca7 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01050c4:	83 ec 08             	sub    $0x8,%esp
f01050c7:	53                   	push   %ebx
f01050c8:	6a 25                	push   $0x25
f01050ca:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01050cc:	83 c4 10             	add    $0x10,%esp
f01050cf:	eb 03                	jmp    f01050d4 <vprintfmt+0x453>
f01050d1:	83 ef 01             	sub    $0x1,%edi
f01050d4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01050d8:	75 f7                	jne    f01050d1 <vprintfmt+0x450>
f01050da:	e9 c8 fb ff ff       	jmp    f0104ca7 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01050df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050e2:	5b                   	pop    %ebx
f01050e3:	5e                   	pop    %esi
f01050e4:	5f                   	pop    %edi
f01050e5:	5d                   	pop    %ebp
f01050e6:	c3                   	ret    

f01050e7 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01050e7:	55                   	push   %ebp
f01050e8:	89 e5                	mov    %esp,%ebp
f01050ea:	83 ec 18             	sub    $0x18,%esp
f01050ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01050f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01050f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01050f6:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01050fa:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01050fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105104:	85 c0                	test   %eax,%eax
f0105106:	74 26                	je     f010512e <vsnprintf+0x47>
f0105108:	85 d2                	test   %edx,%edx
f010510a:	7e 22                	jle    f010512e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010510c:	ff 75 14             	pushl  0x14(%ebp)
f010510f:	ff 75 10             	pushl  0x10(%ebp)
f0105112:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105115:	50                   	push   %eax
f0105116:	68 47 4c 10 f0       	push   $0xf0104c47
f010511b:	e8 61 fb ff ff       	call   f0104c81 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105120:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105123:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105126:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105129:	83 c4 10             	add    $0x10,%esp
f010512c:	eb 05                	jmp    f0105133 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010512e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105133:	c9                   	leave  
f0105134:	c3                   	ret    

f0105135 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105135:	55                   	push   %ebp
f0105136:	89 e5                	mov    %esp,%ebp
f0105138:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010513b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010513e:	50                   	push   %eax
f010513f:	ff 75 10             	pushl  0x10(%ebp)
f0105142:	ff 75 0c             	pushl  0xc(%ebp)
f0105145:	ff 75 08             	pushl  0x8(%ebp)
f0105148:	e8 9a ff ff ff       	call   f01050e7 <vsnprintf>
	va_end(ap);

	return rc;
}
f010514d:	c9                   	leave  
f010514e:	c3                   	ret    

f010514f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010514f:	55                   	push   %ebp
f0105150:	89 e5                	mov    %esp,%ebp
f0105152:	57                   	push   %edi
f0105153:	56                   	push   %esi
f0105154:	53                   	push   %ebx
f0105155:	83 ec 0c             	sub    $0xc,%esp
f0105158:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010515b:	85 c0                	test   %eax,%eax
f010515d:	74 11                	je     f0105170 <readline+0x21>
		cprintf("%s", prompt);
f010515f:	83 ec 08             	sub    $0x8,%esp
f0105162:	50                   	push   %eax
f0105163:	68 41 6f 10 f0       	push   $0xf0106f41
f0105168:	e8 47 e4 ff ff       	call   f01035b4 <cprintf>
f010516d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0105170:	83 ec 0c             	sub    $0xc,%esp
f0105173:	6a 00                	push   $0x0
f0105175:	e8 0b b6 ff ff       	call   f0100785 <iscons>
f010517a:	89 c7                	mov    %eax,%edi
f010517c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010517f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105184:	e8 eb b5 ff ff       	call   f0100774 <getchar>
f0105189:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010518b:	85 c0                	test   %eax,%eax
f010518d:	79 18                	jns    f01051a7 <readline+0x58>
			cprintf("read error: %e\n", c);
f010518f:	83 ec 08             	sub    $0x8,%esp
f0105192:	50                   	push   %eax
f0105193:	68 a4 79 10 f0       	push   $0xf01079a4
f0105198:	e8 17 e4 ff ff       	call   f01035b4 <cprintf>
			return NULL;
f010519d:	83 c4 10             	add    $0x10,%esp
f01051a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01051a5:	eb 79                	jmp    f0105220 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01051a7:	83 f8 08             	cmp    $0x8,%eax
f01051aa:	0f 94 c2             	sete   %dl
f01051ad:	83 f8 7f             	cmp    $0x7f,%eax
f01051b0:	0f 94 c0             	sete   %al
f01051b3:	08 c2                	or     %al,%dl
f01051b5:	74 1a                	je     f01051d1 <readline+0x82>
f01051b7:	85 f6                	test   %esi,%esi
f01051b9:	7e 16                	jle    f01051d1 <readline+0x82>
			if (echoing)
f01051bb:	85 ff                	test   %edi,%edi
f01051bd:	74 0d                	je     f01051cc <readline+0x7d>
				cputchar('\b');
f01051bf:	83 ec 0c             	sub    $0xc,%esp
f01051c2:	6a 08                	push   $0x8
f01051c4:	e8 9b b5 ff ff       	call   f0100764 <cputchar>
f01051c9:	83 c4 10             	add    $0x10,%esp
			i--;
f01051cc:	83 ee 01             	sub    $0x1,%esi
f01051cf:	eb b3                	jmp    f0105184 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01051d1:	83 fb 1f             	cmp    $0x1f,%ebx
f01051d4:	7e 23                	jle    f01051f9 <readline+0xaa>
f01051d6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01051dc:	7f 1b                	jg     f01051f9 <readline+0xaa>
			if (echoing)
f01051de:	85 ff                	test   %edi,%edi
f01051e0:	74 0c                	je     f01051ee <readline+0x9f>
				cputchar(c);
f01051e2:	83 ec 0c             	sub    $0xc,%esp
f01051e5:	53                   	push   %ebx
f01051e6:	e8 79 b5 ff ff       	call   f0100764 <cputchar>
f01051eb:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01051ee:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f01051f4:	8d 76 01             	lea    0x1(%esi),%esi
f01051f7:	eb 8b                	jmp    f0105184 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01051f9:	83 fb 0a             	cmp    $0xa,%ebx
f01051fc:	74 05                	je     f0105203 <readline+0xb4>
f01051fe:	83 fb 0d             	cmp    $0xd,%ebx
f0105201:	75 81                	jne    f0105184 <readline+0x35>
			if (echoing)
f0105203:	85 ff                	test   %edi,%edi
f0105205:	74 0d                	je     f0105214 <readline+0xc5>
				cputchar('\n');
f0105207:	83 ec 0c             	sub    $0xc,%esp
f010520a:	6a 0a                	push   $0xa
f010520c:	e8 53 b5 ff ff       	call   f0100764 <cputchar>
f0105211:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105214:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f010521b:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f0105220:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105223:	5b                   	pop    %ebx
f0105224:	5e                   	pop    %esi
f0105225:	5f                   	pop    %edi
f0105226:	5d                   	pop    %ebp
f0105227:	c3                   	ret    

f0105228 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105228:	55                   	push   %ebp
f0105229:	89 e5                	mov    %esp,%ebp
f010522b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010522e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105233:	eb 03                	jmp    f0105238 <strlen+0x10>
		n++;
f0105235:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105238:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010523c:	75 f7                	jne    f0105235 <strlen+0xd>
		n++;
	return n;
}
f010523e:	5d                   	pop    %ebp
f010523f:	c3                   	ret    

f0105240 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105240:	55                   	push   %ebp
f0105241:	89 e5                	mov    %esp,%ebp
f0105243:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105246:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105249:	ba 00 00 00 00       	mov    $0x0,%edx
f010524e:	eb 03                	jmp    f0105253 <strnlen+0x13>
		n++;
f0105250:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105253:	39 c2                	cmp    %eax,%edx
f0105255:	74 08                	je     f010525f <strnlen+0x1f>
f0105257:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010525b:	75 f3                	jne    f0105250 <strnlen+0x10>
f010525d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010525f:	5d                   	pop    %ebp
f0105260:	c3                   	ret    

f0105261 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105261:	55                   	push   %ebp
f0105262:	89 e5                	mov    %esp,%ebp
f0105264:	53                   	push   %ebx
f0105265:	8b 45 08             	mov    0x8(%ebp),%eax
f0105268:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010526b:	89 c2                	mov    %eax,%edx
f010526d:	83 c2 01             	add    $0x1,%edx
f0105270:	83 c1 01             	add    $0x1,%ecx
f0105273:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105277:	88 5a ff             	mov    %bl,-0x1(%edx)
f010527a:	84 db                	test   %bl,%bl
f010527c:	75 ef                	jne    f010526d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010527e:	5b                   	pop    %ebx
f010527f:	5d                   	pop    %ebp
f0105280:	c3                   	ret    

f0105281 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105281:	55                   	push   %ebp
f0105282:	89 e5                	mov    %esp,%ebp
f0105284:	53                   	push   %ebx
f0105285:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105288:	53                   	push   %ebx
f0105289:	e8 9a ff ff ff       	call   f0105228 <strlen>
f010528e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105291:	ff 75 0c             	pushl  0xc(%ebp)
f0105294:	01 d8                	add    %ebx,%eax
f0105296:	50                   	push   %eax
f0105297:	e8 c5 ff ff ff       	call   f0105261 <strcpy>
	return dst;
}
f010529c:	89 d8                	mov    %ebx,%eax
f010529e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052a1:	c9                   	leave  
f01052a2:	c3                   	ret    

f01052a3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01052a3:	55                   	push   %ebp
f01052a4:	89 e5                	mov    %esp,%ebp
f01052a6:	56                   	push   %esi
f01052a7:	53                   	push   %ebx
f01052a8:	8b 75 08             	mov    0x8(%ebp),%esi
f01052ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052ae:	89 f3                	mov    %esi,%ebx
f01052b0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052b3:	89 f2                	mov    %esi,%edx
f01052b5:	eb 0f                	jmp    f01052c6 <strncpy+0x23>
		*dst++ = *src;
f01052b7:	83 c2 01             	add    $0x1,%edx
f01052ba:	0f b6 01             	movzbl (%ecx),%eax
f01052bd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01052c0:	80 39 01             	cmpb   $0x1,(%ecx)
f01052c3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052c6:	39 da                	cmp    %ebx,%edx
f01052c8:	75 ed                	jne    f01052b7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01052ca:	89 f0                	mov    %esi,%eax
f01052cc:	5b                   	pop    %ebx
f01052cd:	5e                   	pop    %esi
f01052ce:	5d                   	pop    %ebp
f01052cf:	c3                   	ret    

f01052d0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01052d0:	55                   	push   %ebp
f01052d1:	89 e5                	mov    %esp,%ebp
f01052d3:	56                   	push   %esi
f01052d4:	53                   	push   %ebx
f01052d5:	8b 75 08             	mov    0x8(%ebp),%esi
f01052d8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052db:	8b 55 10             	mov    0x10(%ebp),%edx
f01052de:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01052e0:	85 d2                	test   %edx,%edx
f01052e2:	74 21                	je     f0105305 <strlcpy+0x35>
f01052e4:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01052e8:	89 f2                	mov    %esi,%edx
f01052ea:	eb 09                	jmp    f01052f5 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01052ec:	83 c2 01             	add    $0x1,%edx
f01052ef:	83 c1 01             	add    $0x1,%ecx
f01052f2:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01052f5:	39 c2                	cmp    %eax,%edx
f01052f7:	74 09                	je     f0105302 <strlcpy+0x32>
f01052f9:	0f b6 19             	movzbl (%ecx),%ebx
f01052fc:	84 db                	test   %bl,%bl
f01052fe:	75 ec                	jne    f01052ec <strlcpy+0x1c>
f0105300:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105302:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105305:	29 f0                	sub    %esi,%eax
}
f0105307:	5b                   	pop    %ebx
f0105308:	5e                   	pop    %esi
f0105309:	5d                   	pop    %ebp
f010530a:	c3                   	ret    

f010530b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010530b:	55                   	push   %ebp
f010530c:	89 e5                	mov    %esp,%ebp
f010530e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105311:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105314:	eb 06                	jmp    f010531c <strcmp+0x11>
		p++, q++;
f0105316:	83 c1 01             	add    $0x1,%ecx
f0105319:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010531c:	0f b6 01             	movzbl (%ecx),%eax
f010531f:	84 c0                	test   %al,%al
f0105321:	74 04                	je     f0105327 <strcmp+0x1c>
f0105323:	3a 02                	cmp    (%edx),%al
f0105325:	74 ef                	je     f0105316 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105327:	0f b6 c0             	movzbl %al,%eax
f010532a:	0f b6 12             	movzbl (%edx),%edx
f010532d:	29 d0                	sub    %edx,%eax
}
f010532f:	5d                   	pop    %ebp
f0105330:	c3                   	ret    

f0105331 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105331:	55                   	push   %ebp
f0105332:	89 e5                	mov    %esp,%ebp
f0105334:	53                   	push   %ebx
f0105335:	8b 45 08             	mov    0x8(%ebp),%eax
f0105338:	8b 55 0c             	mov    0xc(%ebp),%edx
f010533b:	89 c3                	mov    %eax,%ebx
f010533d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105340:	eb 06                	jmp    f0105348 <strncmp+0x17>
		n--, p++, q++;
f0105342:	83 c0 01             	add    $0x1,%eax
f0105345:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105348:	39 d8                	cmp    %ebx,%eax
f010534a:	74 15                	je     f0105361 <strncmp+0x30>
f010534c:	0f b6 08             	movzbl (%eax),%ecx
f010534f:	84 c9                	test   %cl,%cl
f0105351:	74 04                	je     f0105357 <strncmp+0x26>
f0105353:	3a 0a                	cmp    (%edx),%cl
f0105355:	74 eb                	je     f0105342 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105357:	0f b6 00             	movzbl (%eax),%eax
f010535a:	0f b6 12             	movzbl (%edx),%edx
f010535d:	29 d0                	sub    %edx,%eax
f010535f:	eb 05                	jmp    f0105366 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105361:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105366:	5b                   	pop    %ebx
f0105367:	5d                   	pop    %ebp
f0105368:	c3                   	ret    

f0105369 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105369:	55                   	push   %ebp
f010536a:	89 e5                	mov    %esp,%ebp
f010536c:	8b 45 08             	mov    0x8(%ebp),%eax
f010536f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105373:	eb 07                	jmp    f010537c <strchr+0x13>
		if (*s == c)
f0105375:	38 ca                	cmp    %cl,%dl
f0105377:	74 0f                	je     f0105388 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105379:	83 c0 01             	add    $0x1,%eax
f010537c:	0f b6 10             	movzbl (%eax),%edx
f010537f:	84 d2                	test   %dl,%dl
f0105381:	75 f2                	jne    f0105375 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105383:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105388:	5d                   	pop    %ebp
f0105389:	c3                   	ret    

f010538a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010538a:	55                   	push   %ebp
f010538b:	89 e5                	mov    %esp,%ebp
f010538d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105390:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105394:	eb 03                	jmp    f0105399 <strfind+0xf>
f0105396:	83 c0 01             	add    $0x1,%eax
f0105399:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010539c:	38 ca                	cmp    %cl,%dl
f010539e:	74 04                	je     f01053a4 <strfind+0x1a>
f01053a0:	84 d2                	test   %dl,%dl
f01053a2:	75 f2                	jne    f0105396 <strfind+0xc>
			break;
	return (char *) s;
}
f01053a4:	5d                   	pop    %ebp
f01053a5:	c3                   	ret    

f01053a6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01053a6:	55                   	push   %ebp
f01053a7:	89 e5                	mov    %esp,%ebp
f01053a9:	57                   	push   %edi
f01053aa:	56                   	push   %esi
f01053ab:	53                   	push   %ebx
f01053ac:	8b 7d 08             	mov    0x8(%ebp),%edi
f01053af:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01053b2:	85 c9                	test   %ecx,%ecx
f01053b4:	74 36                	je     f01053ec <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01053b6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01053bc:	75 28                	jne    f01053e6 <memset+0x40>
f01053be:	f6 c1 03             	test   $0x3,%cl
f01053c1:	75 23                	jne    f01053e6 <memset+0x40>
		c &= 0xFF;
f01053c3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01053c7:	89 d3                	mov    %edx,%ebx
f01053c9:	c1 e3 08             	shl    $0x8,%ebx
f01053cc:	89 d6                	mov    %edx,%esi
f01053ce:	c1 e6 18             	shl    $0x18,%esi
f01053d1:	89 d0                	mov    %edx,%eax
f01053d3:	c1 e0 10             	shl    $0x10,%eax
f01053d6:	09 f0                	or     %esi,%eax
f01053d8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01053da:	89 d8                	mov    %ebx,%eax
f01053dc:	09 d0                	or     %edx,%eax
f01053de:	c1 e9 02             	shr    $0x2,%ecx
f01053e1:	fc                   	cld    
f01053e2:	f3 ab                	rep stos %eax,%es:(%edi)
f01053e4:	eb 06                	jmp    f01053ec <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01053e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053e9:	fc                   	cld    
f01053ea:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01053ec:	89 f8                	mov    %edi,%eax
f01053ee:	5b                   	pop    %ebx
f01053ef:	5e                   	pop    %esi
f01053f0:	5f                   	pop    %edi
f01053f1:	5d                   	pop    %ebp
f01053f2:	c3                   	ret    

f01053f3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01053f3:	55                   	push   %ebp
f01053f4:	89 e5                	mov    %esp,%ebp
f01053f6:	57                   	push   %edi
f01053f7:	56                   	push   %esi
f01053f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01053fb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01053fe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105401:	39 c6                	cmp    %eax,%esi
f0105403:	73 35                	jae    f010543a <memmove+0x47>
f0105405:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105408:	39 d0                	cmp    %edx,%eax
f010540a:	73 2e                	jae    f010543a <memmove+0x47>
		s += n;
		d += n;
f010540c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010540f:	89 d6                	mov    %edx,%esi
f0105411:	09 fe                	or     %edi,%esi
f0105413:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105419:	75 13                	jne    f010542e <memmove+0x3b>
f010541b:	f6 c1 03             	test   $0x3,%cl
f010541e:	75 0e                	jne    f010542e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0105420:	83 ef 04             	sub    $0x4,%edi
f0105423:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105426:	c1 e9 02             	shr    $0x2,%ecx
f0105429:	fd                   	std    
f010542a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010542c:	eb 09                	jmp    f0105437 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010542e:	83 ef 01             	sub    $0x1,%edi
f0105431:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105434:	fd                   	std    
f0105435:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105437:	fc                   	cld    
f0105438:	eb 1d                	jmp    f0105457 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010543a:	89 f2                	mov    %esi,%edx
f010543c:	09 c2                	or     %eax,%edx
f010543e:	f6 c2 03             	test   $0x3,%dl
f0105441:	75 0f                	jne    f0105452 <memmove+0x5f>
f0105443:	f6 c1 03             	test   $0x3,%cl
f0105446:	75 0a                	jne    f0105452 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0105448:	c1 e9 02             	shr    $0x2,%ecx
f010544b:	89 c7                	mov    %eax,%edi
f010544d:	fc                   	cld    
f010544e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105450:	eb 05                	jmp    f0105457 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105452:	89 c7                	mov    %eax,%edi
f0105454:	fc                   	cld    
f0105455:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105457:	5e                   	pop    %esi
f0105458:	5f                   	pop    %edi
f0105459:	5d                   	pop    %ebp
f010545a:	c3                   	ret    

f010545b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010545b:	55                   	push   %ebp
f010545c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010545e:	ff 75 10             	pushl  0x10(%ebp)
f0105461:	ff 75 0c             	pushl  0xc(%ebp)
f0105464:	ff 75 08             	pushl  0x8(%ebp)
f0105467:	e8 87 ff ff ff       	call   f01053f3 <memmove>
}
f010546c:	c9                   	leave  
f010546d:	c3                   	ret    

f010546e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010546e:	55                   	push   %ebp
f010546f:	89 e5                	mov    %esp,%ebp
f0105471:	56                   	push   %esi
f0105472:	53                   	push   %ebx
f0105473:	8b 45 08             	mov    0x8(%ebp),%eax
f0105476:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105479:	89 c6                	mov    %eax,%esi
f010547b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010547e:	eb 1a                	jmp    f010549a <memcmp+0x2c>
		if (*s1 != *s2)
f0105480:	0f b6 08             	movzbl (%eax),%ecx
f0105483:	0f b6 1a             	movzbl (%edx),%ebx
f0105486:	38 d9                	cmp    %bl,%cl
f0105488:	74 0a                	je     f0105494 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010548a:	0f b6 c1             	movzbl %cl,%eax
f010548d:	0f b6 db             	movzbl %bl,%ebx
f0105490:	29 d8                	sub    %ebx,%eax
f0105492:	eb 0f                	jmp    f01054a3 <memcmp+0x35>
		s1++, s2++;
f0105494:	83 c0 01             	add    $0x1,%eax
f0105497:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010549a:	39 f0                	cmp    %esi,%eax
f010549c:	75 e2                	jne    f0105480 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010549e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054a3:	5b                   	pop    %ebx
f01054a4:	5e                   	pop    %esi
f01054a5:	5d                   	pop    %ebp
f01054a6:	c3                   	ret    

f01054a7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01054a7:	55                   	push   %ebp
f01054a8:	89 e5                	mov    %esp,%ebp
f01054aa:	53                   	push   %ebx
f01054ab:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01054ae:	89 c1                	mov    %eax,%ecx
f01054b0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01054b3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054b7:	eb 0a                	jmp    f01054c3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01054b9:	0f b6 10             	movzbl (%eax),%edx
f01054bc:	39 da                	cmp    %ebx,%edx
f01054be:	74 07                	je     f01054c7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054c0:	83 c0 01             	add    $0x1,%eax
f01054c3:	39 c8                	cmp    %ecx,%eax
f01054c5:	72 f2                	jb     f01054b9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01054c7:	5b                   	pop    %ebx
f01054c8:	5d                   	pop    %ebp
f01054c9:	c3                   	ret    

f01054ca <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01054ca:	55                   	push   %ebp
f01054cb:	89 e5                	mov    %esp,%ebp
f01054cd:	57                   	push   %edi
f01054ce:	56                   	push   %esi
f01054cf:	53                   	push   %ebx
f01054d0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054d3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054d6:	eb 03                	jmp    f01054db <strtol+0x11>
		s++;
f01054d8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054db:	0f b6 01             	movzbl (%ecx),%eax
f01054de:	3c 20                	cmp    $0x20,%al
f01054e0:	74 f6                	je     f01054d8 <strtol+0xe>
f01054e2:	3c 09                	cmp    $0x9,%al
f01054e4:	74 f2                	je     f01054d8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01054e6:	3c 2b                	cmp    $0x2b,%al
f01054e8:	75 0a                	jne    f01054f4 <strtol+0x2a>
		s++;
f01054ea:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01054ed:	bf 00 00 00 00       	mov    $0x0,%edi
f01054f2:	eb 11                	jmp    f0105505 <strtol+0x3b>
f01054f4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01054f9:	3c 2d                	cmp    $0x2d,%al
f01054fb:	75 08                	jne    f0105505 <strtol+0x3b>
		s++, neg = 1;
f01054fd:	83 c1 01             	add    $0x1,%ecx
f0105500:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105505:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010550b:	75 15                	jne    f0105522 <strtol+0x58>
f010550d:	80 39 30             	cmpb   $0x30,(%ecx)
f0105510:	75 10                	jne    f0105522 <strtol+0x58>
f0105512:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105516:	75 7c                	jne    f0105594 <strtol+0xca>
		s += 2, base = 16;
f0105518:	83 c1 02             	add    $0x2,%ecx
f010551b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105520:	eb 16                	jmp    f0105538 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105522:	85 db                	test   %ebx,%ebx
f0105524:	75 12                	jne    f0105538 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105526:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010552b:	80 39 30             	cmpb   $0x30,(%ecx)
f010552e:	75 08                	jne    f0105538 <strtol+0x6e>
		s++, base = 8;
f0105530:	83 c1 01             	add    $0x1,%ecx
f0105533:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105538:	b8 00 00 00 00       	mov    $0x0,%eax
f010553d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105540:	0f b6 11             	movzbl (%ecx),%edx
f0105543:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105546:	89 f3                	mov    %esi,%ebx
f0105548:	80 fb 09             	cmp    $0x9,%bl
f010554b:	77 08                	ja     f0105555 <strtol+0x8b>
			dig = *s - '0';
f010554d:	0f be d2             	movsbl %dl,%edx
f0105550:	83 ea 30             	sub    $0x30,%edx
f0105553:	eb 22                	jmp    f0105577 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105555:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105558:	89 f3                	mov    %esi,%ebx
f010555a:	80 fb 19             	cmp    $0x19,%bl
f010555d:	77 08                	ja     f0105567 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010555f:	0f be d2             	movsbl %dl,%edx
f0105562:	83 ea 57             	sub    $0x57,%edx
f0105565:	eb 10                	jmp    f0105577 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105567:	8d 72 bf             	lea    -0x41(%edx),%esi
f010556a:	89 f3                	mov    %esi,%ebx
f010556c:	80 fb 19             	cmp    $0x19,%bl
f010556f:	77 16                	ja     f0105587 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0105571:	0f be d2             	movsbl %dl,%edx
f0105574:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105577:	3b 55 10             	cmp    0x10(%ebp),%edx
f010557a:	7d 0b                	jge    f0105587 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010557c:	83 c1 01             	add    $0x1,%ecx
f010557f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105583:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105585:	eb b9                	jmp    f0105540 <strtol+0x76>

	if (endptr)
f0105587:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010558b:	74 0d                	je     f010559a <strtol+0xd0>
		*endptr = (char *) s;
f010558d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105590:	89 0e                	mov    %ecx,(%esi)
f0105592:	eb 06                	jmp    f010559a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105594:	85 db                	test   %ebx,%ebx
f0105596:	74 98                	je     f0105530 <strtol+0x66>
f0105598:	eb 9e                	jmp    f0105538 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010559a:	89 c2                	mov    %eax,%edx
f010559c:	f7 da                	neg    %edx
f010559e:	85 ff                	test   %edi,%edi
f01055a0:	0f 45 c2             	cmovne %edx,%eax
}
f01055a3:	5b                   	pop    %ebx
f01055a4:	5e                   	pop    %esi
f01055a5:	5f                   	pop    %edi
f01055a6:	5d                   	pop    %ebp
f01055a7:	c3                   	ret    

f01055a8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01055a8:	fa                   	cli    

	xorw    %ax, %ax
f01055a9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01055ab:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055ad:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055af:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01055b1:	0f 01 16             	lgdtl  (%esi)
f01055b4:	74 70                	je     f0105626 <mpsearch1+0x3>
	movl    %cr0, %eax
f01055b6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01055b9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01055bd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01055c0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01055c6:	08 00                	or     %al,(%eax)

f01055c8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01055c8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01055cc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055ce:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055d0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01055d2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01055d6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01055d8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01055da:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01055df:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01055e2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01055e5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01055ea:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01055ed:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01055f3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01055f8:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f01055fd:	ff d0                	call   *%eax

f01055ff <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01055ff:	eb fe                	jmp    f01055ff <spin>
f0105601:	8d 76 00             	lea    0x0(%esi),%esi

f0105604 <gdt>:
	...
f010560c:	ff                   	(bad)  
f010560d:	ff 00                	incl   (%eax)
f010560f:	00 00                	add    %al,(%eax)
f0105611:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105618:	00                   	.byte 0x0
f0105619:	92                   	xchg   %eax,%edx
f010561a:	cf                   	iret   
	...

f010561c <gdtdesc>:
f010561c:	17                   	pop    %ss
f010561d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105622 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105622:	90                   	nop

f0105623 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105623:	55                   	push   %ebp
f0105624:	89 e5                	mov    %esp,%ebp
f0105626:	57                   	push   %edi
f0105627:	56                   	push   %esi
f0105628:	53                   	push   %ebx
f0105629:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010562c:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0105632:	89 c3                	mov    %eax,%ebx
f0105634:	c1 eb 0c             	shr    $0xc,%ebx
f0105637:	39 cb                	cmp    %ecx,%ebx
f0105639:	72 12                	jb     f010564d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010563b:	50                   	push   %eax
f010563c:	68 a4 60 10 f0       	push   $0xf01060a4
f0105641:	6a 57                	push   $0x57
f0105643:	68 41 7b 10 f0       	push   $0xf0107b41
f0105648:	e8 f3 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010564d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105653:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105655:	89 c2                	mov    %eax,%edx
f0105657:	c1 ea 0c             	shr    $0xc,%edx
f010565a:	39 ca                	cmp    %ecx,%edx
f010565c:	72 12                	jb     f0105670 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010565e:	50                   	push   %eax
f010565f:	68 a4 60 10 f0       	push   $0xf01060a4
f0105664:	6a 57                	push   $0x57
f0105666:	68 41 7b 10 f0       	push   $0xf0107b41
f010566b:	e8 d0 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105670:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105676:	eb 2f                	jmp    f01056a7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105678:	83 ec 04             	sub    $0x4,%esp
f010567b:	6a 04                	push   $0x4
f010567d:	68 51 7b 10 f0       	push   $0xf0107b51
f0105682:	53                   	push   %ebx
f0105683:	e8 e6 fd ff ff       	call   f010546e <memcmp>
f0105688:	83 c4 10             	add    $0x10,%esp
f010568b:	85 c0                	test   %eax,%eax
f010568d:	75 15                	jne    f01056a4 <mpsearch1+0x81>
f010568f:	89 da                	mov    %ebx,%edx
f0105691:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105694:	0f b6 0a             	movzbl (%edx),%ecx
f0105697:	01 c8                	add    %ecx,%eax
f0105699:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010569c:	39 d7                	cmp    %edx,%edi
f010569e:	75 f4                	jne    f0105694 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056a0:	84 c0                	test   %al,%al
f01056a2:	74 0e                	je     f01056b2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01056a4:	83 c3 10             	add    $0x10,%ebx
f01056a7:	39 f3                	cmp    %esi,%ebx
f01056a9:	72 cd                	jb     f0105678 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01056ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01056b0:	eb 02                	jmp    f01056b4 <mpsearch1+0x91>
f01056b2:	89 d8                	mov    %ebx,%eax
}
f01056b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056b7:	5b                   	pop    %ebx
f01056b8:	5e                   	pop    %esi
f01056b9:	5f                   	pop    %edi
f01056ba:	5d                   	pop    %ebp
f01056bb:	c3                   	ret    

f01056bc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01056bc:	55                   	push   %ebp
f01056bd:	89 e5                	mov    %esp,%ebp
f01056bf:	57                   	push   %edi
f01056c0:	56                   	push   %esi
f01056c1:	53                   	push   %ebx
f01056c2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01056c5:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f01056cc:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056cf:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f01056d6:	75 16                	jne    f01056ee <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056d8:	68 00 04 00 00       	push   $0x400
f01056dd:	68 a4 60 10 f0       	push   $0xf01060a4
f01056e2:	6a 6f                	push   $0x6f
f01056e4:	68 41 7b 10 f0       	push   $0xf0107b41
f01056e9:	e8 52 a9 ff ff       	call   f0100040 <_panic>

	static_assert(sizeof(*mp) == 16);

	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);
	cprintf("bda   %08x\n",bda);
f01056ee:	83 ec 08             	sub    $0x8,%esp
f01056f1:	68 00 04 00 f0       	push   $0xf0000400
f01056f6:	68 56 7b 10 f0       	push   $0xf0107b56
f01056fb:	e8 b4 de ff ff       	call   f01035b4 <cprintf>
	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105700:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105707:	83 c4 10             	add    $0x10,%esp
f010570a:	85 c0                	test   %eax,%eax
f010570c:	74 16                	je     f0105724 <mp_init+0x68>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010570e:	c1 e0 04             	shl    $0x4,%eax
f0105711:	ba 00 04 00 00       	mov    $0x400,%edx
f0105716:	e8 08 ff ff ff       	call   f0105623 <mpsearch1>
f010571b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010571e:	85 c0                	test   %eax,%eax
f0105720:	75 3c                	jne    f010575e <mp_init+0xa2>
f0105722:	eb 20                	jmp    f0105744 <mp_init+0x88>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105724:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010572b:	c1 e0 0a             	shl    $0xa,%eax
f010572e:	2d 00 04 00 00       	sub    $0x400,%eax
f0105733:	ba 00 04 00 00       	mov    $0x400,%edx
f0105738:	e8 e6 fe ff ff       	call   f0105623 <mpsearch1>
f010573d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105740:	85 c0                	test   %eax,%eax
f0105742:	75 1a                	jne    f010575e <mp_init+0xa2>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105744:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105749:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010574e:	e8 d0 fe ff ff       	call   f0105623 <mpsearch1>
f0105753:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105756:	85 c0                	test   %eax,%eax
f0105758:	0f 84 5d 02 00 00    	je     f01059bb <mp_init+0x2ff>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f010575e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105761:	8b 70 04             	mov    0x4(%eax),%esi
f0105764:	85 f6                	test   %esi,%esi
f0105766:	74 06                	je     f010576e <mp_init+0xb2>
f0105768:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010576c:	74 15                	je     f0105783 <mp_init+0xc7>
		cprintf("SMP: Default configurations not implemented\n");
f010576e:	83 ec 0c             	sub    $0xc,%esp
f0105771:	68 b4 79 10 f0       	push   $0xf01079b4
f0105776:	e8 39 de ff ff       	call   f01035b4 <cprintf>
f010577b:	83 c4 10             	add    $0x10,%esp
f010577e:	e9 38 02 00 00       	jmp    f01059bb <mp_init+0x2ff>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105783:	89 f0                	mov    %esi,%eax
f0105785:	c1 e8 0c             	shr    $0xc,%eax
f0105788:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f010578e:	72 15                	jb     f01057a5 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105790:	56                   	push   %esi
f0105791:	68 a4 60 10 f0       	push   $0xf01060a4
f0105796:	68 90 00 00 00       	push   $0x90
f010579b:	68 41 7b 10 f0       	push   $0xf0107b41
f01057a0:	e8 9b a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057a5:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057ab:	83 ec 04             	sub    $0x4,%esp
f01057ae:	6a 04                	push   $0x4
f01057b0:	68 62 7b 10 f0       	push   $0xf0107b62
f01057b5:	53                   	push   %ebx
f01057b6:	e8 b3 fc ff ff       	call   f010546e <memcmp>
f01057bb:	83 c4 10             	add    $0x10,%esp
f01057be:	85 c0                	test   %eax,%eax
f01057c0:	74 15                	je     f01057d7 <mp_init+0x11b>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01057c2:	83 ec 0c             	sub    $0xc,%esp
f01057c5:	68 e4 79 10 f0       	push   $0xf01079e4
f01057ca:	e8 e5 dd ff ff       	call   f01035b4 <cprintf>
f01057cf:	83 c4 10             	add    $0x10,%esp
f01057d2:	e9 e4 01 00 00       	jmp    f01059bb <mp_init+0x2ff>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057d7:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01057db:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01057df:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057e2:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01057ec:	eb 0d                	jmp    f01057fb <mp_init+0x13f>
		sum += ((uint8_t *)addr)[i];
f01057ee:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01057f5:	f0 
f01057f6:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057f8:	83 c0 01             	add    $0x1,%eax
f01057fb:	39 c7                	cmp    %eax,%edi
f01057fd:	75 ef                	jne    f01057ee <mp_init+0x132>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057ff:	84 d2                	test   %dl,%dl
f0105801:	74 15                	je     f0105818 <mp_init+0x15c>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105803:	83 ec 0c             	sub    $0xc,%esp
f0105806:	68 18 7a 10 f0       	push   $0xf0107a18
f010580b:	e8 a4 dd ff ff       	call   f01035b4 <cprintf>
f0105810:	83 c4 10             	add    $0x10,%esp
f0105813:	e9 a3 01 00 00       	jmp    f01059bb <mp_init+0x2ff>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105818:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010581c:	3c 01                	cmp    $0x1,%al
f010581e:	74 1d                	je     f010583d <mp_init+0x181>
f0105820:	3c 04                	cmp    $0x4,%al
f0105822:	74 19                	je     f010583d <mp_init+0x181>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105824:	83 ec 08             	sub    $0x8,%esp
f0105827:	0f b6 c0             	movzbl %al,%eax
f010582a:	50                   	push   %eax
f010582b:	68 3c 7a 10 f0       	push   $0xf0107a3c
f0105830:	e8 7f dd ff ff       	call   f01035b4 <cprintf>
f0105835:	83 c4 10             	add    $0x10,%esp
f0105838:	e9 7e 01 00 00       	jmp    f01059bb <mp_init+0x2ff>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010583d:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105841:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105845:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010584a:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010584f:	01 ce                	add    %ecx,%esi
f0105851:	eb 0d                	jmp    f0105860 <mp_init+0x1a4>
f0105853:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f010585a:	f0 
f010585b:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010585d:	83 c0 01             	add    $0x1,%eax
f0105860:	39 c7                	cmp    %eax,%edi
f0105862:	75 ef                	jne    f0105853 <mp_init+0x197>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105864:	89 d0                	mov    %edx,%eax
f0105866:	02 43 2a             	add    0x2a(%ebx),%al
f0105869:	74 15                	je     f0105880 <mp_init+0x1c4>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010586b:	83 ec 0c             	sub    $0xc,%esp
f010586e:	68 5c 7a 10 f0       	push   $0xf0107a5c
f0105873:	e8 3c dd ff ff       	call   f01035b4 <cprintf>
f0105878:	83 c4 10             	add    $0x10,%esp
f010587b:	e9 3b 01 00 00       	jmp    f01059bb <mp_init+0x2ff>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105880:	85 db                	test   %ebx,%ebx
f0105882:	0f 84 33 01 00 00    	je     f01059bb <mp_init+0x2ff>
		return;
	ismp = 1;
f0105888:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f010588f:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105892:	8b 43 24             	mov    0x24(%ebx),%eax
f0105895:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010589a:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010589d:	be 00 00 00 00       	mov    $0x0,%esi
f01058a2:	e9 85 00 00 00       	jmp    f010592c <mp_init+0x270>
		switch (*p) {
f01058a7:	0f b6 07             	movzbl (%edi),%eax
f01058aa:	84 c0                	test   %al,%al
f01058ac:	74 06                	je     f01058b4 <mp_init+0x1f8>
f01058ae:	3c 04                	cmp    $0x4,%al
f01058b0:	77 55                	ja     f0105907 <mp_init+0x24b>
f01058b2:	eb 4e                	jmp    f0105902 <mp_init+0x246>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058b4:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01058b8:	74 11                	je     f01058cb <mp_init+0x20f>
				bootcpu = &cpus[ncpu];
f01058ba:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f01058c1:	05 20 00 23 f0       	add    $0xf0230020,%eax
f01058c6:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f01058cb:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f01058d0:	83 f8 07             	cmp    $0x7,%eax
f01058d3:	7f 13                	jg     f01058e8 <mp_init+0x22c>
				cpus[ncpu].cpu_id = ncpu;
f01058d5:	6b d0 74             	imul   $0x74,%eax,%edx
f01058d8:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f01058de:	83 c0 01             	add    $0x1,%eax
f01058e1:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f01058e6:	eb 15                	jmp    f01058fd <mp_init+0x241>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01058e8:	83 ec 08             	sub    $0x8,%esp
f01058eb:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01058ef:	50                   	push   %eax
f01058f0:	68 8c 7a 10 f0       	push   $0xf0107a8c
f01058f5:	e8 ba dc ff ff       	call   f01035b4 <cprintf>
f01058fa:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01058fd:	83 c7 14             	add    $0x14,%edi
			continue;
f0105900:	eb 27                	jmp    f0105929 <mp_init+0x26d>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105902:	83 c7 08             	add    $0x8,%edi
			continue;
f0105905:	eb 22                	jmp    f0105929 <mp_init+0x26d>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105907:	83 ec 08             	sub    $0x8,%esp
f010590a:	0f b6 c0             	movzbl %al,%eax
f010590d:	50                   	push   %eax
f010590e:	68 b4 7a 10 f0       	push   $0xf0107ab4
f0105913:	e8 9c dc ff ff       	call   f01035b4 <cprintf>
			ismp = 0;
f0105918:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f010591f:	00 00 00 
			i = conf->entry;
f0105922:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105926:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105929:	83 c6 01             	add    $0x1,%esi
f010592c:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105930:	39 c6                	cmp    %eax,%esi
f0105932:	0f 82 6f ff ff ff    	jb     f01058a7 <mp_init+0x1eb>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105938:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f010593d:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105944:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f010594b:	75 26                	jne    f0105973 <mp_init+0x2b7>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f010594d:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f0105954:	00 00 00 
		lapicaddr = 0;
f0105957:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f010595e:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105961:	83 ec 0c             	sub    $0xc,%esp
f0105964:	68 d4 7a 10 f0       	push   $0xf0107ad4
f0105969:	e8 46 dc ff ff       	call   f01035b4 <cprintf>
		return;
f010596e:	83 c4 10             	add    $0x10,%esp
f0105971:	eb 48                	jmp    f01059bb <mp_init+0x2ff>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105973:	83 ec 04             	sub    $0x4,%esp
f0105976:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f010597c:	0f b6 00             	movzbl (%eax),%eax
f010597f:	50                   	push   %eax
f0105980:	68 67 7b 10 f0       	push   $0xf0107b67
f0105985:	e8 2a dc ff ff       	call   f01035b4 <cprintf>

	if (mp->imcrp) {
f010598a:	83 c4 10             	add    $0x10,%esp
f010598d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105990:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105994:	74 25                	je     f01059bb <mp_init+0x2ff>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105996:	83 ec 0c             	sub    $0xc,%esp
f0105999:	68 00 7b 10 f0       	push   $0xf0107b00
f010599e:	e8 11 dc ff ff       	call   f01035b4 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059a3:	ba 22 00 00 00       	mov    $0x22,%edx
f01059a8:	b8 70 00 00 00       	mov    $0x70,%eax
f01059ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059ae:	ba 23 00 00 00       	mov    $0x23,%edx
f01059b3:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059b4:	83 c8 01             	or     $0x1,%eax
f01059b7:	ee                   	out    %al,(%dx)
f01059b8:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01059bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01059be:	5b                   	pop    %ebx
f01059bf:	5e                   	pop    %esi
f01059c0:	5f                   	pop    %edi
f01059c1:	5d                   	pop    %ebp
f01059c2:	c3                   	ret    

f01059c3 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01059c3:	55                   	push   %ebp
f01059c4:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01059c6:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f01059cc:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01059cf:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01059d1:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f01059d6:	8b 40 20             	mov    0x20(%eax),%eax
}
f01059d9:	5d                   	pop    %ebp
f01059da:	c3                   	ret    

f01059db <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01059db:	55                   	push   %ebp
f01059dc:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01059de:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f01059e3:	85 c0                	test   %eax,%eax
f01059e5:	74 08                	je     f01059ef <cpunum+0x14>
		return lapic[ID] >> 24;
f01059e7:	8b 40 20             	mov    0x20(%eax),%eax
f01059ea:	c1 e8 18             	shr    $0x18,%eax
f01059ed:	eb 05                	jmp    f01059f4 <cpunum+0x19>
	return 0;
f01059ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01059f4:	5d                   	pop    %ebp
f01059f5:	c3                   	ret    

f01059f6 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01059f6:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f01059fb:	85 c0                	test   %eax,%eax
f01059fd:	0f 84 21 01 00 00    	je     f0105b24 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a03:	55                   	push   %ebp
f0105a04:	89 e5                	mov    %esp,%ebp
f0105a06:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a09:	68 00 10 00 00       	push   $0x1000
f0105a0e:	50                   	push   %eax
f0105a0f:	e8 97 b7 ff ff       	call   f01011ab <mmio_map_region>
f0105a14:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a19:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a1e:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a23:	e8 9b ff ff ff       	call   f01059c3 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a28:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a2d:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a32:	e8 8c ff ff ff       	call   f01059c3 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a37:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a3c:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a41:	e8 7d ff ff ff       	call   f01059c3 <lapicw>
	lapicw(TICR, 10000000); 
f0105a46:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a4b:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a50:	e8 6e ff ff ff       	call   f01059c3 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105a55:	e8 81 ff ff ff       	call   f01059db <cpunum>
f0105a5a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a5d:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105a62:	83 c4 10             	add    $0x10,%esp
f0105a65:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f0105a6b:	74 0f                	je     f0105a7c <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105a6d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a72:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105a77:	e8 47 ff ff ff       	call   f01059c3 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105a7c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a81:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105a86:	e8 38 ff ff ff       	call   f01059c3 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105a8b:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105a90:	8b 40 30             	mov    0x30(%eax),%eax
f0105a93:	c1 e8 10             	shr    $0x10,%eax
f0105a96:	3c 03                	cmp    $0x3,%al
f0105a98:	76 0f                	jbe    f0105aa9 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105a9a:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a9f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105aa4:	e8 1a ff ff ff       	call   f01059c3 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105aa9:	ba 33 00 00 00       	mov    $0x33,%edx
f0105aae:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105ab3:	e8 0b ff ff ff       	call   f01059c3 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105ab8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105abd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ac2:	e8 fc fe ff ff       	call   f01059c3 <lapicw>
	lapicw(ESR, 0);
f0105ac7:	ba 00 00 00 00       	mov    $0x0,%edx
f0105acc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ad1:	e8 ed fe ff ff       	call   f01059c3 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105ad6:	ba 00 00 00 00       	mov    $0x0,%edx
f0105adb:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105ae0:	e8 de fe ff ff       	call   f01059c3 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105ae5:	ba 00 00 00 00       	mov    $0x0,%edx
f0105aea:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105aef:	e8 cf fe ff ff       	call   f01059c3 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105af4:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105af9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105afe:	e8 c0 fe ff ff       	call   f01059c3 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b03:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105b09:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b0f:	f6 c4 10             	test   $0x10,%ah
f0105b12:	75 f5                	jne    f0105b09 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b14:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b19:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b1e:	e8 a0 fe ff ff       	call   f01059c3 <lapicw>
}
f0105b23:	c9                   	leave  
f0105b24:	f3 c3                	repz ret 

f0105b26 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b26:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105b2d:	74 13                	je     f0105b42 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b2f:	55                   	push   %ebp
f0105b30:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b32:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b37:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b3c:	e8 82 fe ff ff       	call   f01059c3 <lapicw>
}
f0105b41:	5d                   	pop    %ebp
f0105b42:	f3 c3                	repz ret 

f0105b44 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b44:	55                   	push   %ebp
f0105b45:	89 e5                	mov    %esp,%ebp
f0105b47:	56                   	push   %esi
f0105b48:	53                   	push   %ebx
f0105b49:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b4c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b4f:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b54:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105b59:	ee                   	out    %al,(%dx)
f0105b5a:	ba 71 00 00 00       	mov    $0x71,%edx
f0105b5f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105b64:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b65:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105b6c:	75 19                	jne    f0105b87 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105b6e:	68 67 04 00 00       	push   $0x467
f0105b73:	68 a4 60 10 f0       	push   $0xf01060a4
f0105b78:	68 98 00 00 00       	push   $0x98
f0105b7d:	68 84 7b 10 f0       	push   $0xf0107b84
f0105b82:	e8 b9 a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105b87:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105b8e:	00 00 
	wrv[1] = addr >> 4;
f0105b90:	89 d8                	mov    %ebx,%eax
f0105b92:	c1 e8 04             	shr    $0x4,%eax
f0105b95:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105b9b:	c1 e6 18             	shl    $0x18,%esi
f0105b9e:	89 f2                	mov    %esi,%edx
f0105ba0:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105ba5:	e8 19 fe ff ff       	call   f01059c3 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105baa:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105baf:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bb4:	e8 0a fe ff ff       	call   f01059c3 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105bb9:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105bbe:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bc3:	e8 fb fd ff ff       	call   f01059c3 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bc8:	c1 eb 0c             	shr    $0xc,%ebx
f0105bcb:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bce:	89 f2                	mov    %esi,%edx
f0105bd0:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bd5:	e8 e9 fd ff ff       	call   f01059c3 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bda:	89 da                	mov    %ebx,%edx
f0105bdc:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105be1:	e8 dd fd ff ff       	call   f01059c3 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105be6:	89 f2                	mov    %esi,%edx
f0105be8:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bed:	e8 d1 fd ff ff       	call   f01059c3 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bf2:	89 da                	mov    %ebx,%edx
f0105bf4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bf9:	e8 c5 fd ff ff       	call   f01059c3 <lapicw>
		microdelay(200);
	}
}
f0105bfe:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c01:	5b                   	pop    %ebx
f0105c02:	5e                   	pop    %esi
f0105c03:	5d                   	pop    %ebp
f0105c04:	c3                   	ret    

f0105c05 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c05:	55                   	push   %ebp
f0105c06:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c08:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c0b:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c11:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c16:	e8 a8 fd ff ff       	call   f01059c3 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c1b:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105c21:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c27:	f6 c4 10             	test   $0x10,%ah
f0105c2a:	75 f5                	jne    f0105c21 <lapic_ipi+0x1c>
		;
}
f0105c2c:	5d                   	pop    %ebp
f0105c2d:	c3                   	ret    

f0105c2e <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c2e:	55                   	push   %ebp
f0105c2f:	89 e5                	mov    %esp,%ebp
f0105c31:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c34:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c3a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c3d:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c40:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c47:	5d                   	pop    %ebp
f0105c48:	c3                   	ret    

f0105c49 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c49:	55                   	push   %ebp
f0105c4a:	89 e5                	mov    %esp,%ebp
f0105c4c:	56                   	push   %esi
f0105c4d:	53                   	push   %ebx
f0105c4e:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c51:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c54:	74 14                	je     f0105c6a <spin_lock+0x21>
f0105c56:	8b 73 08             	mov    0x8(%ebx),%esi
f0105c59:	e8 7d fd ff ff       	call   f01059db <cpunum>
f0105c5e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c61:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105c66:	39 c6                	cmp    %eax,%esi
f0105c68:	74 07                	je     f0105c71 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0105c6a:	ba 01 00 00 00       	mov    $0x1,%edx
f0105c6f:	eb 20                	jmp    f0105c91 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105c71:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105c74:	e8 62 fd ff ff       	call   f01059db <cpunum>
f0105c79:	83 ec 0c             	sub    $0xc,%esp
f0105c7c:	53                   	push   %ebx
f0105c7d:	50                   	push   %eax
f0105c7e:	68 94 7b 10 f0       	push   $0xf0107b94
f0105c83:	6a 41                	push   $0x41
f0105c85:	68 f8 7b 10 f0       	push   $0xf0107bf8
f0105c8a:	e8 b1 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105c8f:	f3 90                	pause  
f0105c91:	89 d0                	mov    %edx,%eax
f0105c93:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105c96:	85 c0                	test   %eax,%eax
f0105c98:	75 f5                	jne    f0105c8f <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105c9a:	e8 3c fd ff ff       	call   f01059db <cpunum>
f0105c9f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ca2:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105ca7:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105caa:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105cad:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105caf:	b8 00 00 00 00       	mov    $0x0,%eax
f0105cb4:	eb 0b                	jmp    f0105cc1 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105cb6:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105cb9:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105cbc:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cbe:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105cc1:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105cc7:	76 11                	jbe    f0105cda <spin_lock+0x91>
f0105cc9:	83 f8 09             	cmp    $0x9,%eax
f0105ccc:	7e e8                	jle    f0105cb6 <spin_lock+0x6d>
f0105cce:	eb 0a                	jmp    f0105cda <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105cd0:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105cd7:	83 c0 01             	add    $0x1,%eax
f0105cda:	83 f8 09             	cmp    $0x9,%eax
f0105cdd:	7e f1                	jle    f0105cd0 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105cdf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105ce2:	5b                   	pop    %ebx
f0105ce3:	5e                   	pop    %esi
f0105ce4:	5d                   	pop    %ebp
f0105ce5:	c3                   	ret    

f0105ce6 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105ce6:	55                   	push   %ebp
f0105ce7:	89 e5                	mov    %esp,%ebp
f0105ce9:	57                   	push   %edi
f0105cea:	56                   	push   %esi
f0105ceb:	53                   	push   %ebx
f0105cec:	83 ec 4c             	sub    $0x4c,%esp
f0105cef:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105cf2:	83 3e 00             	cmpl   $0x0,(%esi)
f0105cf5:	74 18                	je     f0105d0f <spin_unlock+0x29>
f0105cf7:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105cfa:	e8 dc fc ff ff       	call   f01059db <cpunum>
f0105cff:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d02:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d07:	39 c3                	cmp    %eax,%ebx
f0105d09:	0f 84 a5 00 00 00    	je     f0105db4 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d0f:	83 ec 04             	sub    $0x4,%esp
f0105d12:	6a 28                	push   $0x28
f0105d14:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d17:	50                   	push   %eax
f0105d18:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d1b:	53                   	push   %ebx
f0105d1c:	e8 d2 f6 ff ff       	call   f01053f3 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d21:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d24:	0f b6 38             	movzbl (%eax),%edi
f0105d27:	8b 76 04             	mov    0x4(%esi),%esi
f0105d2a:	e8 ac fc ff ff       	call   f01059db <cpunum>
f0105d2f:	57                   	push   %edi
f0105d30:	56                   	push   %esi
f0105d31:	50                   	push   %eax
f0105d32:	68 c0 7b 10 f0       	push   $0xf0107bc0
f0105d37:	e8 78 d8 ff ff       	call   f01035b4 <cprintf>
f0105d3c:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d3f:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d42:	eb 54                	jmp    f0105d98 <spin_unlock+0xb2>
f0105d44:	83 ec 08             	sub    $0x8,%esp
f0105d47:	57                   	push   %edi
f0105d48:	50                   	push   %eax
f0105d49:	e8 d8 eb ff ff       	call   f0104926 <debuginfo_eip>
f0105d4e:	83 c4 10             	add    $0x10,%esp
f0105d51:	85 c0                	test   %eax,%eax
f0105d53:	78 27                	js     f0105d7c <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105d55:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105d57:	83 ec 04             	sub    $0x4,%esp
f0105d5a:	89 c2                	mov    %eax,%edx
f0105d5c:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105d5f:	52                   	push   %edx
f0105d60:	ff 75 b0             	pushl  -0x50(%ebp)
f0105d63:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105d66:	ff 75 ac             	pushl  -0x54(%ebp)
f0105d69:	ff 75 a8             	pushl  -0x58(%ebp)
f0105d6c:	50                   	push   %eax
f0105d6d:	68 08 7c 10 f0       	push   $0xf0107c08
f0105d72:	e8 3d d8 ff ff       	call   f01035b4 <cprintf>
f0105d77:	83 c4 20             	add    $0x20,%esp
f0105d7a:	eb 12                	jmp    f0105d8e <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105d7c:	83 ec 08             	sub    $0x8,%esp
f0105d7f:	ff 36                	pushl  (%esi)
f0105d81:	68 5a 7b 10 f0       	push   $0xf0107b5a
f0105d86:	e8 29 d8 ff ff       	call   f01035b4 <cprintf>
f0105d8b:	83 c4 10             	add    $0x10,%esp
f0105d8e:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105d91:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105d94:	39 c3                	cmp    %eax,%ebx
f0105d96:	74 08                	je     f0105da0 <spin_unlock+0xba>
f0105d98:	89 de                	mov    %ebx,%esi
f0105d9a:	8b 03                	mov    (%ebx),%eax
f0105d9c:	85 c0                	test   %eax,%eax
f0105d9e:	75 a4                	jne    f0105d44 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105da0:	83 ec 04             	sub    $0x4,%esp
f0105da3:	68 1f 7c 10 f0       	push   $0xf0107c1f
f0105da8:	6a 67                	push   $0x67
f0105daa:	68 f8 7b 10 f0       	push   $0xf0107bf8
f0105daf:	e8 8c a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105db4:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105dbb:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0105dc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0105dc7:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105dca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105dcd:	5b                   	pop    %ebx
f0105dce:	5e                   	pop    %esi
f0105dcf:	5f                   	pop    %edi
f0105dd0:	5d                   	pop    %ebp
f0105dd1:	c3                   	ret    
f0105dd2:	66 90                	xchg   %ax,%ax
f0105dd4:	66 90                	xchg   %ax,%ax
f0105dd6:	66 90                	xchg   %ax,%ax
f0105dd8:	66 90                	xchg   %ax,%ax
f0105dda:	66 90                	xchg   %ax,%ax
f0105ddc:	66 90                	xchg   %ax,%ax
f0105dde:	66 90                	xchg   %ax,%ax

f0105de0 <__udivdi3>:
f0105de0:	55                   	push   %ebp
f0105de1:	57                   	push   %edi
f0105de2:	56                   	push   %esi
f0105de3:	53                   	push   %ebx
f0105de4:	83 ec 1c             	sub    $0x1c,%esp
f0105de7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105deb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105def:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105df3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105df7:	85 f6                	test   %esi,%esi
f0105df9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105dfd:	89 ca                	mov    %ecx,%edx
f0105dff:	89 f8                	mov    %edi,%eax
f0105e01:	75 3d                	jne    f0105e40 <__udivdi3+0x60>
f0105e03:	39 cf                	cmp    %ecx,%edi
f0105e05:	0f 87 c5 00 00 00    	ja     f0105ed0 <__udivdi3+0xf0>
f0105e0b:	85 ff                	test   %edi,%edi
f0105e0d:	89 fd                	mov    %edi,%ebp
f0105e0f:	75 0b                	jne    f0105e1c <__udivdi3+0x3c>
f0105e11:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e16:	31 d2                	xor    %edx,%edx
f0105e18:	f7 f7                	div    %edi
f0105e1a:	89 c5                	mov    %eax,%ebp
f0105e1c:	89 c8                	mov    %ecx,%eax
f0105e1e:	31 d2                	xor    %edx,%edx
f0105e20:	f7 f5                	div    %ebp
f0105e22:	89 c1                	mov    %eax,%ecx
f0105e24:	89 d8                	mov    %ebx,%eax
f0105e26:	89 cf                	mov    %ecx,%edi
f0105e28:	f7 f5                	div    %ebp
f0105e2a:	89 c3                	mov    %eax,%ebx
f0105e2c:	89 d8                	mov    %ebx,%eax
f0105e2e:	89 fa                	mov    %edi,%edx
f0105e30:	83 c4 1c             	add    $0x1c,%esp
f0105e33:	5b                   	pop    %ebx
f0105e34:	5e                   	pop    %esi
f0105e35:	5f                   	pop    %edi
f0105e36:	5d                   	pop    %ebp
f0105e37:	c3                   	ret    
f0105e38:	90                   	nop
f0105e39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e40:	39 ce                	cmp    %ecx,%esi
f0105e42:	77 74                	ja     f0105eb8 <__udivdi3+0xd8>
f0105e44:	0f bd fe             	bsr    %esi,%edi
f0105e47:	83 f7 1f             	xor    $0x1f,%edi
f0105e4a:	0f 84 98 00 00 00    	je     f0105ee8 <__udivdi3+0x108>
f0105e50:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105e55:	89 f9                	mov    %edi,%ecx
f0105e57:	89 c5                	mov    %eax,%ebp
f0105e59:	29 fb                	sub    %edi,%ebx
f0105e5b:	d3 e6                	shl    %cl,%esi
f0105e5d:	89 d9                	mov    %ebx,%ecx
f0105e5f:	d3 ed                	shr    %cl,%ebp
f0105e61:	89 f9                	mov    %edi,%ecx
f0105e63:	d3 e0                	shl    %cl,%eax
f0105e65:	09 ee                	or     %ebp,%esi
f0105e67:	89 d9                	mov    %ebx,%ecx
f0105e69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e6d:	89 d5                	mov    %edx,%ebp
f0105e6f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105e73:	d3 ed                	shr    %cl,%ebp
f0105e75:	89 f9                	mov    %edi,%ecx
f0105e77:	d3 e2                	shl    %cl,%edx
f0105e79:	89 d9                	mov    %ebx,%ecx
f0105e7b:	d3 e8                	shr    %cl,%eax
f0105e7d:	09 c2                	or     %eax,%edx
f0105e7f:	89 d0                	mov    %edx,%eax
f0105e81:	89 ea                	mov    %ebp,%edx
f0105e83:	f7 f6                	div    %esi
f0105e85:	89 d5                	mov    %edx,%ebp
f0105e87:	89 c3                	mov    %eax,%ebx
f0105e89:	f7 64 24 0c          	mull   0xc(%esp)
f0105e8d:	39 d5                	cmp    %edx,%ebp
f0105e8f:	72 10                	jb     f0105ea1 <__udivdi3+0xc1>
f0105e91:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105e95:	89 f9                	mov    %edi,%ecx
f0105e97:	d3 e6                	shl    %cl,%esi
f0105e99:	39 c6                	cmp    %eax,%esi
f0105e9b:	73 07                	jae    f0105ea4 <__udivdi3+0xc4>
f0105e9d:	39 d5                	cmp    %edx,%ebp
f0105e9f:	75 03                	jne    f0105ea4 <__udivdi3+0xc4>
f0105ea1:	83 eb 01             	sub    $0x1,%ebx
f0105ea4:	31 ff                	xor    %edi,%edi
f0105ea6:	89 d8                	mov    %ebx,%eax
f0105ea8:	89 fa                	mov    %edi,%edx
f0105eaa:	83 c4 1c             	add    $0x1c,%esp
f0105ead:	5b                   	pop    %ebx
f0105eae:	5e                   	pop    %esi
f0105eaf:	5f                   	pop    %edi
f0105eb0:	5d                   	pop    %ebp
f0105eb1:	c3                   	ret    
f0105eb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105eb8:	31 ff                	xor    %edi,%edi
f0105eba:	31 db                	xor    %ebx,%ebx
f0105ebc:	89 d8                	mov    %ebx,%eax
f0105ebe:	89 fa                	mov    %edi,%edx
f0105ec0:	83 c4 1c             	add    $0x1c,%esp
f0105ec3:	5b                   	pop    %ebx
f0105ec4:	5e                   	pop    %esi
f0105ec5:	5f                   	pop    %edi
f0105ec6:	5d                   	pop    %ebp
f0105ec7:	c3                   	ret    
f0105ec8:	90                   	nop
f0105ec9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ed0:	89 d8                	mov    %ebx,%eax
f0105ed2:	f7 f7                	div    %edi
f0105ed4:	31 ff                	xor    %edi,%edi
f0105ed6:	89 c3                	mov    %eax,%ebx
f0105ed8:	89 d8                	mov    %ebx,%eax
f0105eda:	89 fa                	mov    %edi,%edx
f0105edc:	83 c4 1c             	add    $0x1c,%esp
f0105edf:	5b                   	pop    %ebx
f0105ee0:	5e                   	pop    %esi
f0105ee1:	5f                   	pop    %edi
f0105ee2:	5d                   	pop    %ebp
f0105ee3:	c3                   	ret    
f0105ee4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105ee8:	39 ce                	cmp    %ecx,%esi
f0105eea:	72 0c                	jb     f0105ef8 <__udivdi3+0x118>
f0105eec:	31 db                	xor    %ebx,%ebx
f0105eee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105ef2:	0f 87 34 ff ff ff    	ja     f0105e2c <__udivdi3+0x4c>
f0105ef8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105efd:	e9 2a ff ff ff       	jmp    f0105e2c <__udivdi3+0x4c>
f0105f02:	66 90                	xchg   %ax,%ax
f0105f04:	66 90                	xchg   %ax,%ax
f0105f06:	66 90                	xchg   %ax,%ax
f0105f08:	66 90                	xchg   %ax,%ax
f0105f0a:	66 90                	xchg   %ax,%ax
f0105f0c:	66 90                	xchg   %ax,%ax
f0105f0e:	66 90                	xchg   %ax,%ax

f0105f10 <__umoddi3>:
f0105f10:	55                   	push   %ebp
f0105f11:	57                   	push   %edi
f0105f12:	56                   	push   %esi
f0105f13:	53                   	push   %ebx
f0105f14:	83 ec 1c             	sub    $0x1c,%esp
f0105f17:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105f1b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105f1f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105f23:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f27:	85 d2                	test   %edx,%edx
f0105f29:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105f2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105f31:	89 f3                	mov    %esi,%ebx
f0105f33:	89 3c 24             	mov    %edi,(%esp)
f0105f36:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105f3a:	75 1c                	jne    f0105f58 <__umoddi3+0x48>
f0105f3c:	39 f7                	cmp    %esi,%edi
f0105f3e:	76 50                	jbe    f0105f90 <__umoddi3+0x80>
f0105f40:	89 c8                	mov    %ecx,%eax
f0105f42:	89 f2                	mov    %esi,%edx
f0105f44:	f7 f7                	div    %edi
f0105f46:	89 d0                	mov    %edx,%eax
f0105f48:	31 d2                	xor    %edx,%edx
f0105f4a:	83 c4 1c             	add    $0x1c,%esp
f0105f4d:	5b                   	pop    %ebx
f0105f4e:	5e                   	pop    %esi
f0105f4f:	5f                   	pop    %edi
f0105f50:	5d                   	pop    %ebp
f0105f51:	c3                   	ret    
f0105f52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105f58:	39 f2                	cmp    %esi,%edx
f0105f5a:	89 d0                	mov    %edx,%eax
f0105f5c:	77 52                	ja     f0105fb0 <__umoddi3+0xa0>
f0105f5e:	0f bd ea             	bsr    %edx,%ebp
f0105f61:	83 f5 1f             	xor    $0x1f,%ebp
f0105f64:	75 5a                	jne    f0105fc0 <__umoddi3+0xb0>
f0105f66:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105f6a:	0f 82 e0 00 00 00    	jb     f0106050 <__umoddi3+0x140>
f0105f70:	39 0c 24             	cmp    %ecx,(%esp)
f0105f73:	0f 86 d7 00 00 00    	jbe    f0106050 <__umoddi3+0x140>
f0105f79:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105f7d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105f81:	83 c4 1c             	add    $0x1c,%esp
f0105f84:	5b                   	pop    %ebx
f0105f85:	5e                   	pop    %esi
f0105f86:	5f                   	pop    %edi
f0105f87:	5d                   	pop    %ebp
f0105f88:	c3                   	ret    
f0105f89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105f90:	85 ff                	test   %edi,%edi
f0105f92:	89 fd                	mov    %edi,%ebp
f0105f94:	75 0b                	jne    f0105fa1 <__umoddi3+0x91>
f0105f96:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f9b:	31 d2                	xor    %edx,%edx
f0105f9d:	f7 f7                	div    %edi
f0105f9f:	89 c5                	mov    %eax,%ebp
f0105fa1:	89 f0                	mov    %esi,%eax
f0105fa3:	31 d2                	xor    %edx,%edx
f0105fa5:	f7 f5                	div    %ebp
f0105fa7:	89 c8                	mov    %ecx,%eax
f0105fa9:	f7 f5                	div    %ebp
f0105fab:	89 d0                	mov    %edx,%eax
f0105fad:	eb 99                	jmp    f0105f48 <__umoddi3+0x38>
f0105faf:	90                   	nop
f0105fb0:	89 c8                	mov    %ecx,%eax
f0105fb2:	89 f2                	mov    %esi,%edx
f0105fb4:	83 c4 1c             	add    $0x1c,%esp
f0105fb7:	5b                   	pop    %ebx
f0105fb8:	5e                   	pop    %esi
f0105fb9:	5f                   	pop    %edi
f0105fba:	5d                   	pop    %ebp
f0105fbb:	c3                   	ret    
f0105fbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fc0:	8b 34 24             	mov    (%esp),%esi
f0105fc3:	bf 20 00 00 00       	mov    $0x20,%edi
f0105fc8:	89 e9                	mov    %ebp,%ecx
f0105fca:	29 ef                	sub    %ebp,%edi
f0105fcc:	d3 e0                	shl    %cl,%eax
f0105fce:	89 f9                	mov    %edi,%ecx
f0105fd0:	89 f2                	mov    %esi,%edx
f0105fd2:	d3 ea                	shr    %cl,%edx
f0105fd4:	89 e9                	mov    %ebp,%ecx
f0105fd6:	09 c2                	or     %eax,%edx
f0105fd8:	89 d8                	mov    %ebx,%eax
f0105fda:	89 14 24             	mov    %edx,(%esp)
f0105fdd:	89 f2                	mov    %esi,%edx
f0105fdf:	d3 e2                	shl    %cl,%edx
f0105fe1:	89 f9                	mov    %edi,%ecx
f0105fe3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105fe7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105feb:	d3 e8                	shr    %cl,%eax
f0105fed:	89 e9                	mov    %ebp,%ecx
f0105fef:	89 c6                	mov    %eax,%esi
f0105ff1:	d3 e3                	shl    %cl,%ebx
f0105ff3:	89 f9                	mov    %edi,%ecx
f0105ff5:	89 d0                	mov    %edx,%eax
f0105ff7:	d3 e8                	shr    %cl,%eax
f0105ff9:	89 e9                	mov    %ebp,%ecx
f0105ffb:	09 d8                	or     %ebx,%eax
f0105ffd:	89 d3                	mov    %edx,%ebx
f0105fff:	89 f2                	mov    %esi,%edx
f0106001:	f7 34 24             	divl   (%esp)
f0106004:	89 d6                	mov    %edx,%esi
f0106006:	d3 e3                	shl    %cl,%ebx
f0106008:	f7 64 24 04          	mull   0x4(%esp)
f010600c:	39 d6                	cmp    %edx,%esi
f010600e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106012:	89 d1                	mov    %edx,%ecx
f0106014:	89 c3                	mov    %eax,%ebx
f0106016:	72 08                	jb     f0106020 <__umoddi3+0x110>
f0106018:	75 11                	jne    f010602b <__umoddi3+0x11b>
f010601a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010601e:	73 0b                	jae    f010602b <__umoddi3+0x11b>
f0106020:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106024:	1b 14 24             	sbb    (%esp),%edx
f0106027:	89 d1                	mov    %edx,%ecx
f0106029:	89 c3                	mov    %eax,%ebx
f010602b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010602f:	29 da                	sub    %ebx,%edx
f0106031:	19 ce                	sbb    %ecx,%esi
f0106033:	89 f9                	mov    %edi,%ecx
f0106035:	89 f0                	mov    %esi,%eax
f0106037:	d3 e0                	shl    %cl,%eax
f0106039:	89 e9                	mov    %ebp,%ecx
f010603b:	d3 ea                	shr    %cl,%edx
f010603d:	89 e9                	mov    %ebp,%ecx
f010603f:	d3 ee                	shr    %cl,%esi
f0106041:	09 d0                	or     %edx,%eax
f0106043:	89 f2                	mov    %esi,%edx
f0106045:	83 c4 1c             	add    $0x1c,%esp
f0106048:	5b                   	pop    %ebx
f0106049:	5e                   	pop    %esi
f010604a:	5f                   	pop    %edi
f010604b:	5d                   	pop    %ebp
f010604c:	c3                   	ret    
f010604d:	8d 76 00             	lea    0x0(%esi),%esi
f0106050:	29 f9                	sub    %edi,%ecx
f0106052:	19 d6                	sbb    %edx,%esi
f0106054:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106058:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010605c:	e9 18 ff ff ff       	jmp    f0105f79 <__umoddi3+0x69>
