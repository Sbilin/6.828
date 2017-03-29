
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
f0100048:	83 3d 80 ee 22 f0 00 	cmpl   $0x0,0xf022ee80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ee 22 f0    	mov    %esi,0xf022ee80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 ba 56 00 00       	call   f010571b <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 5d 10 f0       	push   $0xf0105dc0
f010006d:	e8 3b 35 00 00       	call   f01035ad <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 0b 35 00 00       	call   f0103587 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 29 6f 10 f0 	movl   $0xf0106f29,(%esp)
f0100083:	e8 25 35 00 00       	call   f01035ad <cprintf>
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
f01000a1:	b8 08 00 27 f0       	mov    $0xf0270008,%eax
f01000a6:	2d 28 d6 22 f0       	sub    $0xf022d628,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 28 d6 22 f0       	push   $0xf022d628
f01000b3:	e8 2d 50 00 00       	call   f01050e5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 5e 10 f0       	push   $0xf0105e2c
f01000ca:	e8 de 34 00 00       	call   f01035ad <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 34 11 00 00       	call   f0101208 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 39 2d 00 00       	call   f0102e12 <env_init>
	trap_init();
f01000d9:	e8 b5 35 00 00       	call   f0103693 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 19 53 00 00       	call   f01053fc <mp_init>
	lapic_init();
f01000e3:	e8 4e 56 00 00       	call   f0105736 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 e7 33 00 00       	call   f01034d4 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 90 58 00 00       	call   f0105989 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ee 22 f0 07 	cmpl   $0x7,0xf022ee88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 5d 10 f0       	push   $0xf0105de4
f010010f:	6a 59                	push   $0x59
f0100111:	68 47 5e 10 f0       	push   $0xf0105e47
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 62 53 10 f0       	mov    $0xf0105362,%eax
f0100123:	2d e8 52 10 f0       	sub    $0xf01052e8,%eax
f0100128:	50                   	push   %eax
f0100129:	68 e8 52 10 f0       	push   $0xf01052e8
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 fa 4f 00 00       	call   f0105132 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 f0 22 f0       	mov    $0xf022f020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 d4 55 00 00       	call   f010571b <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 f0 22 f0       	sub    $0xf022f020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 80 23 f0       	add    $0xf0238000,%eax
f010016b:	a3 84 ee 22 f0       	mov    %eax,0xf022ee84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 03 57 00 00       	call   f0105884 <lapic_startap>
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
f010018f:	6b 05 c4 f3 22 f0 74 	imul   $0x74,0xf022f3c4,%eax
f0100196:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST) 
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 78 d0 1e f0       	push   $0xf01ed078
f01001a9:	e8 30 2e 00 00       	call   f0102fde <env_create>
	//ENV_CREATE(user_hello, ENV_TYPE_USER);
	
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 b3 3e 00 00       	call   f0104066 <sched_yield>

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
f01001b9:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 08 5e 10 f0       	push   $0xf0105e08
f01001cb:	6a 70                	push   $0x70
f01001cd:	68 47 5e 10 f0       	push   $0xf0105e47
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 37 55 00 00       	call   f010571b <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 53 5e 10 f0       	push   $0xf0105e53
f01001ed:	e8 bb 33 00 00       	call   f01035ad <cprintf>

	lapic_init();
f01001f2:	e8 3f 55 00 00       	call   f0105736 <lapic_init>
	env_init_percpu();
f01001f7:	e8 e6 2b 00 00       	call   f0102de2 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 c0 33 00 00       	call   f01035c1 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 15 55 00 00       	call   f010571b <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 65 57 00 00       	call   f0105989 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();
f0100224:	e8 3d 3e 00 00       	call   f0104066 <sched_yield>

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
f0100239:	68 69 5e 10 f0       	push   $0xf0105e69
f010023e:	e8 6a 33 00 00       	call   f01035ad <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 38 33 00 00       	call   f0103587 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 29 6f 10 f0 	movl   $0xf0106f29,(%esp)
f0100256:	e8 52 33 00 00       	call   f01035ad <cprintf>
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
f0100291:	8b 0d 24 e2 22 f0    	mov    0xf022e224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 e2 22 f0    	mov    %edx,0xf022e224
f01002a0:	88 81 20 e0 22 f0    	mov    %al,-0xfdd1fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 e2 22 f0 00 	movl   $0x0,0xf022e224
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
f01002e7:	83 0d 00 e0 22 f0 40 	orl    $0x40,0xf022e000
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
f01002ff:	8b 0d 00 e0 22 f0    	mov    0xf022e000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 e0 5f 10 f0 	movzbl -0xfefa020(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 e0 22 f0       	mov    %eax,0xf022e000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 e0 22 f0    	mov    0xf022e000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 e0 22 f0    	mov    %ecx,0xf022e000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 e0 5f 10 f0 	movzbl -0xfefa020(%edx),%eax
f0100358:	0b 05 00 e0 22 f0    	or     0xf022e000,%eax
f010035e:	0f b6 8a e0 5e 10 f0 	movzbl -0xfefa120(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 e0 22 f0       	mov    %eax,0xf022e000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d c0 5e 10 f0 	mov    -0xfefa140(,%ecx,4),%ecx
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
f01003af:	68 83 5e 10 f0       	push   $0xf0105e83
f01003b4:	e8 f4 31 00 00       	call   f01035ad <cprintf>
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
f010049b:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 e2 22 f0 	addw   $0x50,0xf022e228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228
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
f0100525:	0f b7 05 28 e2 22 f0 	movzwl 0xf022e228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 e2 22 f0 	mov    %dx,0xf022e228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 e2 22 f0 	cmpw   $0x7cf,0xf022e228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c e2 22 f0       	mov    0xf022e22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 ca 4b 00 00       	call   f0105132 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c e2 22 f0    	mov    0xf022e22c,%edx
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
f0100589:	66 83 2d 28 e2 22 f0 	subw   $0x50,0xf022e228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 e2 22 f0    	mov    0xf022e230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 e2 22 f0 	movzwl 0xf022e228,%ebx
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
f01005c7:	80 3d 34 e2 22 f0 00 	cmpb   $0x0,0xf022e234
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
f0100605:	a1 20 e2 22 f0       	mov    0xf022e220,%eax
f010060a:	3b 05 24 e2 22 f0    	cmp    0xf022e224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 e2 22 f0    	mov    %edx,0xf022e220
f010061b:	0f b6 88 20 e0 22 f0 	movzbl -0xfdd1fe0(%eax),%ecx
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
f010062c:	c7 05 20 e2 22 f0 00 	movl   $0x0,0xf022e220
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
f0100665:	c7 05 30 e2 22 f0 b4 	movl   $0x3b4,0xf022e230
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
f010067d:	c7 05 30 e2 22 f0 d4 	movl   $0x3d4,0xf022e230
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
f010068c:	8b 3d 30 e2 22 f0    	mov    0xf022e230,%edi
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
f01006b1:	89 35 2c e2 22 f0    	mov    %esi,0xf022e22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 e2 22 f0    	mov    %ax,0xf022e228

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
f01006d7:	e8 80 2d 00 00       	call   f010345c <irq_setmask_8259A>
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
f010073a:	0f 95 05 34 e2 22 f0 	setne  0xf022e234
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
f010074f:	68 8f 5e 10 f0       	push   $0xf0105e8f
f0100754:	e8 54 2e 00 00       	call   f01035ad <cprintf>
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
f0100795:	68 e0 60 10 f0       	push   $0xf01060e0
f010079a:	68 fe 60 10 f0       	push   $0xf01060fe
f010079f:	68 03 61 10 f0       	push   $0xf0106103
f01007a4:	e8 04 2e 00 00       	call   f01035ad <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 6c 61 10 f0       	push   $0xf010616c
f01007b1:	68 0c 61 10 f0       	push   $0xf010610c
f01007b6:	68 03 61 10 f0       	push   $0xf0106103
f01007bb:	e8 ed 2d 00 00       	call   f01035ad <cprintf>
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
f01007cd:	68 15 61 10 f0       	push   $0xf0106115
f01007d2:	e8 d6 2d 00 00       	call   f01035ad <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d7:	83 c4 08             	add    $0x8,%esp
f01007da:	68 0c 00 10 00       	push   $0x10000c
f01007df:	68 94 61 10 f0       	push   $0xf0106194
f01007e4:	e8 c4 2d 00 00       	call   f01035ad <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	68 0c 00 10 00       	push   $0x10000c
f01007f1:	68 0c 00 10 f0       	push   $0xf010000c
f01007f6:	68 bc 61 10 f0       	push   $0xf01061bc
f01007fb:	e8 ad 2d 00 00       	call   f01035ad <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 a1 5d 10 00       	push   $0x105da1
f0100808:	68 a1 5d 10 f0       	push   $0xf0105da1
f010080d:	68 e0 61 10 f0       	push   $0xf01061e0
f0100812:	e8 96 2d 00 00       	call   f01035ad <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 28 d6 22 00       	push   $0x22d628
f010081f:	68 28 d6 22 f0       	push   $0xf022d628
f0100824:	68 04 62 10 f0       	push   $0xf0106204
f0100829:	e8 7f 2d 00 00       	call   f01035ad <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 08 00 27 00       	push   $0x270008
f0100836:	68 08 00 27 f0       	push   $0xf0270008
f010083b:	68 28 62 10 f0       	push   $0xf0106228
f0100840:	e8 68 2d 00 00       	call   f01035ad <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100845:	b8 07 04 27 f0       	mov    $0xf0270407,%eax
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
f0100866:	68 4c 62 10 f0       	push   $0xf010624c
f010086b:	e8 3d 2d 00 00       	call   f01035ad <cprintf>
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
f010088a:	68 78 62 10 f0       	push   $0xf0106278
f010088f:	e8 19 2d 00 00       	call   f01035ad <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100894:	c7 04 24 9c 62 10 f0 	movl   $0xf010629c,(%esp)
f010089b:	e8 0d 2d 00 00       	call   f01035ad <cprintf>

	if (tf != NULL)
f01008a0:	83 c4 10             	add    $0x10,%esp
f01008a3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008a7:	74 0e                	je     f01008b7 <monitor+0x36>
		print_trapframe(tf);
f01008a9:	83 ec 0c             	sub    $0xc,%esp
f01008ac:	ff 75 08             	pushl  0x8(%ebp)
f01008af:	e8 a9 31 00 00       	call   f0103a5d <print_trapframe>
f01008b4:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01008b7:	83 ec 0c             	sub    $0xc,%esp
f01008ba:	68 2e 61 10 f0       	push   $0xf010612e
f01008bf:	e8 ca 45 00 00       	call   f0104e8e <readline>
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
f01008f3:	68 32 61 10 f0       	push   $0xf0106132
f01008f8:	e8 ab 47 00 00       	call   f01050a8 <strchr>
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
f0100913:	68 37 61 10 f0       	push   $0xf0106137
f0100918:	e8 90 2c 00 00       	call   f01035ad <cprintf>
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
f010093c:	68 32 61 10 f0       	push   $0xf0106132
f0100941:	e8 62 47 00 00       	call   f01050a8 <strchr>
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
f0100962:	68 fe 60 10 f0       	push   $0xf01060fe
f0100967:	ff 75 a8             	pushl  -0x58(%ebp)
f010096a:	e8 db 46 00 00       	call   f010504a <strcmp>
f010096f:	83 c4 10             	add    $0x10,%esp
f0100972:	85 c0                	test   %eax,%eax
f0100974:	74 1e                	je     f0100994 <monitor+0x113>
f0100976:	83 ec 08             	sub    $0x8,%esp
f0100979:	68 0c 61 10 f0       	push   $0xf010610c
f010097e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100981:	e8 c4 46 00 00       	call   f010504a <strcmp>
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
f01009a9:	ff 14 85 cc 62 10 f0 	call   *-0xfef9d34(,%eax,4)
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
f01009c2:	68 54 61 10 f0       	push   $0xf0106154
f01009c7:	e8 e1 2b 00 00       	call   f01035ad <cprintf>
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
f01009e1:	83 3d 38 e2 22 f0 00 	cmpl   $0x0,0xf022e238
f01009e8:	75 0f                	jne    f01009f9 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ea:	b8 07 10 27 f0       	mov    $0xf0271007,%eax
f01009ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f4:	a3 38 e2 22 f0       	mov    %eax,0xf022e238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009f9:	a1 38 e2 22 f0       	mov    0xf022e238,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f01009fe:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100a04:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a0a:	01 c2                	add    %eax,%edx
f0100a0c:	89 15 38 e2 22 f0    	mov    %edx,0xf022e238
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
f0100a1f:	e8 0a 2a 00 00       	call   f010342e <mc146818_read>
f0100a24:	89 c6                	mov    %eax,%esi
f0100a26:	83 c3 01             	add    $0x1,%ebx
f0100a29:	89 1c 24             	mov    %ebx,(%esp)
f0100a2c:	e8 fd 29 00 00       	call   f010342e <mc146818_read>
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
f0100a53:	3b 0d 88 ee 22 f0    	cmp    0xf022ee88,%ecx
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
f0100a62:	68 e4 5d 10 f0       	push   $0xf0105de4
f0100a67:	68 94 03 00 00       	push   $0x394
f0100a6c:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100aba:	68 dc 62 10 f0       	push   $0xf01062dc
f0100abf:	68 c7 02 00 00       	push   $0x2c7
f0100ac4:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100adc:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
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
f0100b12:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
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
f0100b1c:	8b 1d 40 e2 22 f0    	mov    0xf022e240,%ebx
f0100b22:	eb 53                	jmp    f0100b77 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b24:	89 d8                	mov    %ebx,%eax
f0100b26:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0100b40:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100b46:	72 12                	jb     f0100b5a <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b48:	50                   	push   %eax
f0100b49:	68 e4 5d 10 f0       	push   $0xf0105de4
f0100b4e:	6a 58                	push   $0x58
f0100b50:	68 55 6c 10 f0       	push   $0xf0106c55
f0100b55:	e8 e6 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b5a:	83 ec 04             	sub    $0x4,%esp
f0100b5d:	68 80 00 00 00       	push   $0x80
f0100b62:	68 97 00 00 00       	push   $0x97
f0100b67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6c:	50                   	push   %eax
f0100b6d:	e8 73 45 00 00       	call   f01050e5 <memset>
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
f0100b88:	8b 15 40 e2 22 f0    	mov    0xf022e240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b8e:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
		assert(pp < pages + npages);
f0100b94:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
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
f0100bb3:	68 63 6c 10 f0       	push   $0xf0106c63
f0100bb8:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100bbd:	68 e1 02 00 00       	push   $0x2e1
f0100bc2:	68 49 6c 10 f0       	push   $0xf0106c49
f0100bc7:	e8 74 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bcc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bcf:	72 19                	jb     f0100bea <check_page_free_list+0x149>
f0100bd1:	68 84 6c 10 f0       	push   $0xf0106c84
f0100bd6:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100bdb:	68 e2 02 00 00       	push   $0x2e2
f0100be0:	68 49 6c 10 f0       	push   $0xf0106c49
f0100be5:	e8 56 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bea:	89 d0                	mov    %edx,%eax
f0100bec:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bef:	a8 07                	test   $0x7,%al
f0100bf1:	74 19                	je     f0100c0c <check_page_free_list+0x16b>
f0100bf3:	68 00 63 10 f0       	push   $0xf0106300
f0100bf8:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100bfd:	68 e3 02 00 00       	push   $0x2e3
f0100c02:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100c16:	68 98 6c 10 f0       	push   $0xf0106c98
f0100c1b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100c20:	68 e6 02 00 00       	push   $0x2e6
f0100c25:	68 49 6c 10 f0       	push   $0xf0106c49
f0100c2a:	e8 11 f4 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c34:	75 19                	jne    f0100c4f <check_page_free_list+0x1ae>
f0100c36:	68 a9 6c 10 f0       	push   $0xf0106ca9
f0100c3b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100c40:	68 e7 02 00 00       	push   $0x2e7
f0100c45:	68 49 6c 10 f0       	push   $0xf0106c49
f0100c4a:	e8 f1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c54:	75 19                	jne    f0100c6f <check_page_free_list+0x1ce>
f0100c56:	68 34 63 10 f0       	push   $0xf0106334
f0100c5b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100c60:	68 e8 02 00 00       	push   $0x2e8
f0100c65:	68 49 6c 10 f0       	push   $0xf0106c49
f0100c6a:	e8 d1 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c74:	75 19                	jne    f0100c8f <check_page_free_list+0x1ee>
f0100c76:	68 c2 6c 10 f0       	push   $0xf0106cc2
f0100c7b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100c80:	68 e9 02 00 00       	push   $0x2e9
f0100c85:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100ca5:	68 e4 5d 10 f0       	push   $0xf0105de4
f0100caa:	6a 58                	push   $0x58
f0100cac:	68 55 6c 10 f0       	push   $0xf0106c55
f0100cb1:	e8 8a f3 ff ff       	call   f0100040 <_panic>
f0100cb6:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cbc:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100cbf:	0f 86 b6 00 00 00    	jbe    f0100d7b <check_page_free_list+0x2da>
f0100cc5:	68 58 63 10 f0       	push   $0xf0106358
f0100cca:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100ccf:	68 ea 02 00 00       	push   $0x2ea
f0100cd4:	68 49 6c 10 f0       	push   $0xf0106c49
f0100cd9:	e8 62 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100cde:	68 dc 6c 10 f0       	push   $0xf0106cdc
f0100ce3:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100ce8:	68 ec 02 00 00       	push   $0x2ec
f0100ced:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100d0d:	68 f9 6c 10 f0       	push   $0xf0106cf9
f0100d12:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100d17:	68 f4 02 00 00       	push   $0x2f4
f0100d1c:	68 49 6c 10 f0       	push   $0xf0106c49
f0100d21:	e8 1a f3 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d26:	85 db                	test   %ebx,%ebx
f0100d28:	7f 19                	jg     f0100d43 <check_page_free_list+0x2a2>
f0100d2a:	68 0b 6d 10 f0       	push   $0xf0106d0b
f0100d2f:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100d34:	68 f5 02 00 00       	push   $0x2f5
f0100d39:	68 49 6c 10 f0       	push   $0xf0106c49
f0100d3e:	e8 fd f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d43:	83 ec 0c             	sub    $0xc,%esp
f0100d46:	68 a0 63 10 f0       	push   $0xf01063a0
f0100d4b:	e8 5d 28 00 00       	call   f01035ad <cprintf>
}
f0100d50:	eb 49                	jmp    f0100d9b <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d52:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f0100d57:	85 c0                	test   %eax,%eax
f0100d59:	0f 85 6f fd ff ff    	jne    f0100ace <check_page_free_list+0x2d>
f0100d5f:	e9 53 fd ff ff       	jmp    f0100ab7 <check_page_free_list+0x16>
f0100d64:	83 3d 40 e2 22 f0 00 	cmpl   $0x0,0xf022e240
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
f0100da8:	c7 05 40 e2 22 f0 00 	movl   $0x0,0xf022e240
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
f0100dc4:	68 08 5e 10 f0       	push   $0xf0105e08
f0100dc9:	68 3b 01 00 00       	push   $0x13b
f0100dce:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0100df5:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
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
f0100e15:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
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
f0100e31:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
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
f0100e4f:	03 35 90 ee 22 f0    	add    0xf022ee90,%esi
f0100e55:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
                 pages[i].pp_link = page_free_list;
f0100e5b:	89 1e                	mov    %ebx,(%esi)
                 page_free_list = &pages[i];
f0100e5d:	89 cb                	mov    %ecx,%ebx
f0100e5f:	03 1d 90 ee 22 f0    	add    0xf022ee90,%ebx
f0100e65:	be 01 00 00 00       	mov    $0x1,%esi
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100e6a:	83 c2 01             	add    $0x1,%edx
f0100e6d:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100e73:	0f 82 78 ff ff ff    	jb     f0100df1 <page_init+0x4e>
f0100e79:	89 f0                	mov    %esi,%eax
f0100e7b:	84 c0                	test   %al,%al
f0100e7d:	74 06                	je     f0100e85 <page_init+0xe2>
f0100e7f:	89 1d 40 e2 22 f0    	mov    %ebx,0xf022e240
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
f0100e93:	8b 1d 40 e2 22 f0    	mov    0xf022e240,%ebx
f0100e99:	85 db                	test   %ebx,%ebx
f0100e9b:	74 58                	je     f0100ef5 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100e9d:	8b 03                	mov    (%ebx),%eax
f0100e9f:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
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
f0100eb2:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0100eb8:	c1 f8 03             	sar    $0x3,%eax
f0100ebb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ebe:	89 c2                	mov    %eax,%edx
f0100ec0:	c1 ea 0c             	shr    $0xc,%edx
f0100ec3:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100ec9:	72 12                	jb     f0100edd <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ecb:	50                   	push   %eax
f0100ecc:	68 e4 5d 10 f0       	push   $0xf0105de4
f0100ed1:	6a 58                	push   $0x58
f0100ed3:	68 55 6c 10 f0       	push   $0xf0106c55
f0100ed8:	e8 63 f1 ff ff       	call   f0100040 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100edd:	83 ec 04             	sub    $0x4,%esp
f0100ee0:	68 00 10 00 00       	push   $0x1000
f0100ee5:	6a 00                	push   $0x0
f0100ee7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100eec:	50                   	push   %eax
f0100eed:	e8 f3 41 00 00       	call   f01050e5 <memset>
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
f0100f11:	68 c4 63 10 f0       	push   $0xf01063c4
f0100f16:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0100f1b:	68 7d 01 00 00       	push   $0x17d
f0100f20:	68 49 6c 10 f0       	push   $0xf0106c49
f0100f25:	e8 16 f1 ff ff       	call   f0100040 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100f2a:	8b 15 40 e2 22 f0    	mov    0xf022e240,%edx
f0100f30:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100f32:	a3 40 e2 22 f0       	mov    %eax,0xf022e240
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
f0100f9d:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0100fba:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0100fc0:	72 15                	jb     f0100fd7 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc2:	50                   	push   %eax
f0100fc3:	68 e4 5d 10 f0       	push   $0xf0105de4
f0100fc8:	68 b8 01 00 00       	push   $0x1b8
f0100fcd:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101073:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f0101079:	72 14                	jb     f010108f <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f010107b:	83 ec 04             	sub    $0x4,%esp
f010107e:	68 ec 63 10 f0       	push   $0xf01063ec
f0101083:	6a 51                	push   $0x51
f0101085:	68 55 6c 10 f0       	push   $0xf0106c55
f010108a:	e8 b1 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010108f:	8b 15 90 ee 22 f0    	mov    0xf022ee90,%edx
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
f01010b1:	e8 65 46 00 00       	call   f010571b <cpunum>
f01010b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01010b9:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f01010c0:	74 16                	je     f01010d8 <tlb_invalidate+0x2d>
f01010c2:	e8 54 46 00 00       	call   f010571b <cpunum>
f01010c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01010ca:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f0101175:	2b 1d 90 ee 22 f0    	sub    0xf022ee90,%ebx
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
f01011d9:	68 0c 64 10 f0       	push   $0xf010640c
f01011de:	68 72 02 00 00       	push   $0x272
f01011e3:	68 49 6c 10 f0       	push   $0xf0106c49
f01011e8:	e8 53 ee ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir,ret,size,pa,PTE_PCD|PTE_W|PTE_PWT);
f01011ed:	83 ec 08             	sub    $0x8,%esp
f01011f0:	6a 1a                	push   $0x1a
f01011f2:	ff 75 08             	pushl  0x8(%ebp)
f01011f5:	89 da                	mov    %ebx,%edx
f01011f7:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0101251:	89 15 88 ee 22 f0    	mov    %edx,0xf022ee88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101257:	89 c2                	mov    %eax,%edx
f0101259:	29 da                	sub    %ebx,%edx
f010125b:	52                   	push   %edx
f010125c:	53                   	push   %ebx
f010125d:	50                   	push   %eax
f010125e:	68 2c 64 10 f0       	push   $0xf010642c
f0101263:	e8 45 23 00 00       	call   f01035ad <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101268:	b8 00 10 00 00       	mov    $0x1000,%eax
f010126d:	e8 6a f7 ff ff       	call   f01009dc <boot_alloc>
f0101272:	a3 8c ee 22 f0       	mov    %eax,0xf022ee8c
	memset(kern_pgdir, 0, PGSIZE);
f0101277:	83 c4 0c             	add    $0xc,%esp
f010127a:	68 00 10 00 00       	push   $0x1000
f010127f:	6a 00                	push   $0x0
f0101281:	50                   	push   %eax
f0101282:	e8 5e 3e 00 00       	call   f01050e5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101287:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0101297:	68 08 5e 10 f0       	push   $0xf0105e08
f010129c:	68 92 00 00 00       	push   $0x92
f01012a1:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01012ba:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
f01012bf:	c1 e0 03             	shl    $0x3,%eax
f01012c2:	e8 15 f7 ff ff       	call   f01009dc <boot_alloc>
f01012c7:	a3 90 ee 22 f0       	mov    %eax,0xf022ee90
        memset(pages,0,npages*sizeof(struct PageInfo));
f01012cc:	83 ec 04             	sub    $0x4,%esp
f01012cf:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f01012d5:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012dc:	52                   	push   %edx
f01012dd:	6a 00                	push   $0x0
f01012df:	50                   	push   %eax
f01012e0:	e8 00 3e 00 00       	call   f01050e5 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=(struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01012e5:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01012ea:	e8 ed f6 ff ff       	call   f01009dc <boot_alloc>
f01012ef:	a3 44 e2 22 f0       	mov    %eax,0xf022e244
	memset(envs,0,NENV*sizeof(struct Env));
f01012f4:	83 c4 0c             	add    $0xc,%esp
f01012f7:	68 00 f0 01 00       	push   $0x1f000
f01012fc:	6a 00                	push   $0x0
f01012fe:	50                   	push   %eax
f01012ff:	e8 e1 3d 00 00       	call   f01050e5 <memset>
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
f0101316:	83 3d 90 ee 22 f0 00 	cmpl   $0x0,0xf022ee90
f010131d:	75 17                	jne    f0101336 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f010131f:	83 ec 04             	sub    $0x4,%esp
f0101322:	68 1c 6d 10 f0       	push   $0xf0106d1c
f0101327:	68 08 03 00 00       	push   $0x308
f010132c:	68 49 6c 10 f0       	push   $0xf0106c49
f0101331:	e8 0a ed ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101336:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
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
f010135e:	68 37 6d 10 f0       	push   $0xf0106d37
f0101363:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101368:	68 10 03 00 00       	push   $0x310
f010136d:	68 49 6c 10 f0       	push   $0xf0106c49
f0101372:	e8 c9 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101377:	83 ec 0c             	sub    $0xc,%esp
f010137a:	6a 00                	push   $0x0
f010137c:	e8 0b fb ff ff       	call   f0100e8c <page_alloc>
f0101381:	89 c6                	mov    %eax,%esi
f0101383:	83 c4 10             	add    $0x10,%esp
f0101386:	85 c0                	test   %eax,%eax
f0101388:	75 19                	jne    f01013a3 <mem_init+0x19b>
f010138a:	68 4d 6d 10 f0       	push   $0xf0106d4d
f010138f:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101394:	68 11 03 00 00       	push   $0x311
f0101399:	68 49 6c 10 f0       	push   $0xf0106c49
f010139e:	e8 9d ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	6a 00                	push   $0x0
f01013a8:	e8 df fa ff ff       	call   f0100e8c <page_alloc>
f01013ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013b0:	83 c4 10             	add    $0x10,%esp
f01013b3:	85 c0                	test   %eax,%eax
f01013b5:	75 19                	jne    f01013d0 <mem_init+0x1c8>
f01013b7:	68 63 6d 10 f0       	push   $0xf0106d63
f01013bc:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01013c1:	68 12 03 00 00       	push   $0x312
f01013c6:	68 49 6c 10 f0       	push   $0xf0106c49
f01013cb:	e8 70 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013d0:	39 f7                	cmp    %esi,%edi
f01013d2:	75 19                	jne    f01013ed <mem_init+0x1e5>
f01013d4:	68 79 6d 10 f0       	push   $0xf0106d79
f01013d9:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01013de:	68 15 03 00 00       	push   $0x315
f01013e3:	68 49 6c 10 f0       	push   $0xf0106c49
f01013e8:	e8 53 ec ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013f0:	39 c6                	cmp    %eax,%esi
f01013f2:	74 04                	je     f01013f8 <mem_init+0x1f0>
f01013f4:	39 c7                	cmp    %eax,%edi
f01013f6:	75 19                	jne    f0101411 <mem_init+0x209>
f01013f8:	68 68 64 10 f0       	push   $0xf0106468
f01013fd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101402:	68 16 03 00 00       	push   $0x316
f0101407:	68 49 6c 10 f0       	push   $0xf0106c49
f010140c:	e8 2f ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101411:	8b 0d 90 ee 22 f0    	mov    0xf022ee90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101417:	8b 15 88 ee 22 f0    	mov    0xf022ee88,%edx
f010141d:	c1 e2 0c             	shl    $0xc,%edx
f0101420:	89 f8                	mov    %edi,%eax
f0101422:	29 c8                	sub    %ecx,%eax
f0101424:	c1 f8 03             	sar    $0x3,%eax
f0101427:	c1 e0 0c             	shl    $0xc,%eax
f010142a:	39 d0                	cmp    %edx,%eax
f010142c:	72 19                	jb     f0101447 <mem_init+0x23f>
f010142e:	68 8b 6d 10 f0       	push   $0xf0106d8b
f0101433:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101438:	68 17 03 00 00       	push   $0x317
f010143d:	68 49 6c 10 f0       	push   $0xf0106c49
f0101442:	e8 f9 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101447:	89 f0                	mov    %esi,%eax
f0101449:	29 c8                	sub    %ecx,%eax
f010144b:	c1 f8 03             	sar    $0x3,%eax
f010144e:	c1 e0 0c             	shl    $0xc,%eax
f0101451:	39 c2                	cmp    %eax,%edx
f0101453:	77 19                	ja     f010146e <mem_init+0x266>
f0101455:	68 a8 6d 10 f0       	push   $0xf0106da8
f010145a:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010145f:	68 18 03 00 00       	push   $0x318
f0101464:	68 49 6c 10 f0       	push   $0xf0106c49
f0101469:	e8 d2 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010146e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101471:	29 c8                	sub    %ecx,%eax
f0101473:	c1 f8 03             	sar    $0x3,%eax
f0101476:	c1 e0 0c             	shl    $0xc,%eax
f0101479:	39 c2                	cmp    %eax,%edx
f010147b:	77 19                	ja     f0101496 <mem_init+0x28e>
f010147d:	68 c5 6d 10 f0       	push   $0xf0106dc5
f0101482:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101487:	68 19 03 00 00       	push   $0x319
f010148c:	68 49 6c 10 f0       	push   $0xf0106c49
f0101491:	e8 aa eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101496:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f010149b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010149e:	c7 05 40 e2 22 f0 00 	movl   $0x0,0xf022e240
f01014a5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014a8:	83 ec 0c             	sub    $0xc,%esp
f01014ab:	6a 00                	push   $0x0
f01014ad:	e8 da f9 ff ff       	call   f0100e8c <page_alloc>
f01014b2:	83 c4 10             	add    $0x10,%esp
f01014b5:	85 c0                	test   %eax,%eax
f01014b7:	74 19                	je     f01014d2 <mem_init+0x2ca>
f01014b9:	68 e2 6d 10 f0       	push   $0xf0106de2
f01014be:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01014c3:	68 20 03 00 00       	push   $0x320
f01014c8:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101503:	68 37 6d 10 f0       	push   $0xf0106d37
f0101508:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010150d:	68 27 03 00 00       	push   $0x327
f0101512:	68 49 6c 10 f0       	push   $0xf0106c49
f0101517:	e8 24 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010151c:	83 ec 0c             	sub    $0xc,%esp
f010151f:	6a 00                	push   $0x0
f0101521:	e8 66 f9 ff ff       	call   f0100e8c <page_alloc>
f0101526:	89 c7                	mov    %eax,%edi
f0101528:	83 c4 10             	add    $0x10,%esp
f010152b:	85 c0                	test   %eax,%eax
f010152d:	75 19                	jne    f0101548 <mem_init+0x340>
f010152f:	68 4d 6d 10 f0       	push   $0xf0106d4d
f0101534:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101539:	68 28 03 00 00       	push   $0x328
f010153e:	68 49 6c 10 f0       	push   $0xf0106c49
f0101543:	e8 f8 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101548:	83 ec 0c             	sub    $0xc,%esp
f010154b:	6a 00                	push   $0x0
f010154d:	e8 3a f9 ff ff       	call   f0100e8c <page_alloc>
f0101552:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101555:	83 c4 10             	add    $0x10,%esp
f0101558:	85 c0                	test   %eax,%eax
f010155a:	75 19                	jne    f0101575 <mem_init+0x36d>
f010155c:	68 63 6d 10 f0       	push   $0xf0106d63
f0101561:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101566:	68 29 03 00 00       	push   $0x329
f010156b:	68 49 6c 10 f0       	push   $0xf0106c49
f0101570:	e8 cb ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101575:	39 fe                	cmp    %edi,%esi
f0101577:	75 19                	jne    f0101592 <mem_init+0x38a>
f0101579:	68 79 6d 10 f0       	push   $0xf0106d79
f010157e:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101583:	68 2b 03 00 00       	push   $0x32b
f0101588:	68 49 6c 10 f0       	push   $0xf0106c49
f010158d:	e8 ae ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101592:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101595:	39 c7                	cmp    %eax,%edi
f0101597:	74 04                	je     f010159d <mem_init+0x395>
f0101599:	39 c6                	cmp    %eax,%esi
f010159b:	75 19                	jne    f01015b6 <mem_init+0x3ae>
f010159d:	68 68 64 10 f0       	push   $0xf0106468
f01015a2:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01015a7:	68 2c 03 00 00       	push   $0x32c
f01015ac:	68 49 6c 10 f0       	push   $0xf0106c49
f01015b1:	e8 8a ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01015b6:	83 ec 0c             	sub    $0xc,%esp
f01015b9:	6a 00                	push   $0x0
f01015bb:	e8 cc f8 ff ff       	call   f0100e8c <page_alloc>
f01015c0:	83 c4 10             	add    $0x10,%esp
f01015c3:	85 c0                	test   %eax,%eax
f01015c5:	74 19                	je     f01015e0 <mem_init+0x3d8>
f01015c7:	68 e2 6d 10 f0       	push   $0xf0106de2
f01015cc:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01015d1:	68 2d 03 00 00       	push   $0x32d
f01015d6:	68 49 6c 10 f0       	push   $0xf0106c49
f01015db:	e8 60 ea ff ff       	call   f0100040 <_panic>
f01015e0:	89 f0                	mov    %esi,%eax
f01015e2:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f01015e8:	c1 f8 03             	sar    $0x3,%eax
f01015eb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015ee:	89 c2                	mov    %eax,%edx
f01015f0:	c1 ea 0c             	shr    $0xc,%edx
f01015f3:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f01015f9:	72 12                	jb     f010160d <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015fb:	50                   	push   %eax
f01015fc:	68 e4 5d 10 f0       	push   $0xf0105de4
f0101601:	6a 58                	push   $0x58
f0101603:	68 55 6c 10 f0       	push   $0xf0106c55
f0101608:	e8 33 ea ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010160d:	83 ec 04             	sub    $0x4,%esp
f0101610:	68 00 10 00 00       	push   $0x1000
f0101615:	6a 01                	push   $0x1
f0101617:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010161c:	50                   	push   %eax
f010161d:	e8 c3 3a 00 00       	call   f01050e5 <memset>
	page_free(pp0);
f0101622:	89 34 24             	mov    %esi,(%esp)
f0101625:	e8 d2 f8 ff ff       	call   f0100efc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010162a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101631:	e8 56 f8 ff ff       	call   f0100e8c <page_alloc>
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	85 c0                	test   %eax,%eax
f010163b:	75 19                	jne    f0101656 <mem_init+0x44e>
f010163d:	68 f1 6d 10 f0       	push   $0xf0106df1
f0101642:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101647:	68 32 03 00 00       	push   $0x332
f010164c:	68 49 6c 10 f0       	push   $0xf0106c49
f0101651:	e8 ea e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101656:	39 c6                	cmp    %eax,%esi
f0101658:	74 19                	je     f0101673 <mem_init+0x46b>
f010165a:	68 0f 6e 10 f0       	push   $0xf0106e0f
f010165f:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101664:	68 33 03 00 00       	push   $0x333
f0101669:	68 49 6c 10 f0       	push   $0xf0106c49
f010166e:	e8 cd e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101673:	89 f0                	mov    %esi,%eax
f0101675:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f010167b:	c1 f8 03             	sar    $0x3,%eax
f010167e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101681:	89 c2                	mov    %eax,%edx
f0101683:	c1 ea 0c             	shr    $0xc,%edx
f0101686:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f010168c:	72 12                	jb     f01016a0 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010168e:	50                   	push   %eax
f010168f:	68 e4 5d 10 f0       	push   $0xf0105de4
f0101694:	6a 58                	push   $0x58
f0101696:	68 55 6c 10 f0       	push   $0xf0106c55
f010169b:	e8 a0 e9 ff ff       	call   f0100040 <_panic>
f01016a0:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01016a6:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016ac:	80 38 00             	cmpb   $0x0,(%eax)
f01016af:	74 19                	je     f01016ca <mem_init+0x4c2>
f01016b1:	68 1f 6e 10 f0       	push   $0xf0106e1f
f01016b6:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01016bb:	68 36 03 00 00       	push   $0x336
f01016c0:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01016d4:	a3 40 e2 22 f0       	mov    %eax,0xf022e240

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
f01016f5:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
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
f010170c:	68 29 6e 10 f0       	push   $0xf0106e29
f0101711:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101716:	68 43 03 00 00       	push   $0x343
f010171b:	68 49 6c 10 f0       	push   $0xf0106c49
f0101720:	e8 1b e9 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101725:	83 ec 0c             	sub    $0xc,%esp
f0101728:	68 88 64 10 f0       	push   $0xf0106488
f010172d:	e8 7b 1e 00 00       	call   f01035ad <cprintf>
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
f0101748:	68 37 6d 10 f0       	push   $0xf0106d37
f010174d:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101752:	68 a8 03 00 00       	push   $0x3a8
f0101757:	68 49 6c 10 f0       	push   $0xf0106c49
f010175c:	e8 df e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101761:	83 ec 0c             	sub    $0xc,%esp
f0101764:	6a 00                	push   $0x0
f0101766:	e8 21 f7 ff ff       	call   f0100e8c <page_alloc>
f010176b:	89 c3                	mov    %eax,%ebx
f010176d:	83 c4 10             	add    $0x10,%esp
f0101770:	85 c0                	test   %eax,%eax
f0101772:	75 19                	jne    f010178d <mem_init+0x585>
f0101774:	68 4d 6d 10 f0       	push   $0xf0106d4d
f0101779:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010177e:	68 a9 03 00 00       	push   $0x3a9
f0101783:	68 49 6c 10 f0       	push   $0xf0106c49
f0101788:	e8 b3 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010178d:	83 ec 0c             	sub    $0xc,%esp
f0101790:	6a 00                	push   $0x0
f0101792:	e8 f5 f6 ff ff       	call   f0100e8c <page_alloc>
f0101797:	89 c6                	mov    %eax,%esi
f0101799:	83 c4 10             	add    $0x10,%esp
f010179c:	85 c0                	test   %eax,%eax
f010179e:	75 19                	jne    f01017b9 <mem_init+0x5b1>
f01017a0:	68 63 6d 10 f0       	push   $0xf0106d63
f01017a5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01017aa:	68 aa 03 00 00       	push   $0x3aa
f01017af:	68 49 6c 10 f0       	push   $0xf0106c49
f01017b4:	e8 87 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017b9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01017bc:	75 19                	jne    f01017d7 <mem_init+0x5cf>
f01017be:	68 79 6d 10 f0       	push   $0xf0106d79
f01017c3:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01017c8:	68 ad 03 00 00       	push   $0x3ad
f01017cd:	68 49 6c 10 f0       	push   $0xf0106c49
f01017d2:	e8 69 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017d7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01017da:	74 04                	je     f01017e0 <mem_init+0x5d8>
f01017dc:	39 c3                	cmp    %eax,%ebx
f01017de:	75 19                	jne    f01017f9 <mem_init+0x5f1>
f01017e0:	68 68 64 10 f0       	push   $0xf0106468
f01017e5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01017ea:	68 ae 03 00 00       	push   $0x3ae
f01017ef:	68 49 6c 10 f0       	push   $0xf0106c49
f01017f4:	e8 47 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017f9:	a1 40 e2 22 f0       	mov    0xf022e240,%eax
f01017fe:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101801:	c7 05 40 e2 22 f0 00 	movl   $0x0,0xf022e240
f0101808:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010180b:	83 ec 0c             	sub    $0xc,%esp
f010180e:	6a 00                	push   $0x0
f0101810:	e8 77 f6 ff ff       	call   f0100e8c <page_alloc>
f0101815:	83 c4 10             	add    $0x10,%esp
f0101818:	85 c0                	test   %eax,%eax
f010181a:	74 19                	je     f0101835 <mem_init+0x62d>
f010181c:	68 e2 6d 10 f0       	push   $0xf0106de2
f0101821:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101826:	68 b5 03 00 00       	push   $0x3b5
f010182b:	68 49 6c 10 f0       	push   $0xf0106c49
f0101830:	e8 0b e8 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101835:	83 ec 04             	sub    $0x4,%esp
f0101838:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010183b:	50                   	push   %eax
f010183c:	6a 00                	push   $0x0
f010183e:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101844:	e8 fc f7 ff ff       	call   f0101045 <page_lookup>
f0101849:	83 c4 10             	add    $0x10,%esp
f010184c:	85 c0                	test   %eax,%eax
f010184e:	74 19                	je     f0101869 <mem_init+0x661>
f0101850:	68 a8 64 10 f0       	push   $0xf01064a8
f0101855:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010185a:	68 b8 03 00 00       	push   $0x3b8
f010185f:	68 49 6c 10 f0       	push   $0xf0106c49
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101869:	6a 02                	push   $0x2
f010186b:	6a 00                	push   $0x0
f010186d:	53                   	push   %ebx
f010186e:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101874:	e8 b4 f8 ff ff       	call   f010112d <page_insert>
f0101879:	83 c4 10             	add    $0x10,%esp
f010187c:	85 c0                	test   %eax,%eax
f010187e:	78 19                	js     f0101899 <mem_init+0x691>
f0101880:	68 e0 64 10 f0       	push   $0xf01064e0
f0101885:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010188a:	68 bb 03 00 00       	push   $0x3bb
f010188f:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01018a9:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01018af:	e8 79 f8 ff ff       	call   f010112d <page_insert>
f01018b4:	83 c4 20             	add    $0x20,%esp
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	74 19                	je     f01018d4 <mem_init+0x6cc>
f01018bb:	68 10 65 10 f0       	push   $0xf0106510
f01018c0:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01018c5:	68 bf 03 00 00       	push   $0x3bf
f01018ca:	68 49 6c 10 f0       	push   $0xf0106c49
f01018cf:	e8 6c e7 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01018d4:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018da:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f01018fb:	68 40 65 10 f0       	push   $0xf0106540
f0101900:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101905:	68 c0 03 00 00       	push   $0x3c0
f010190a:	68 49 6c 10 f0       	push   $0xf0106c49
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
f010192f:	68 68 65 10 f0       	push   $0xf0106568
f0101934:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101939:	68 c1 03 00 00       	push   $0x3c1
f010193e:	68 49 6c 10 f0       	push   $0xf0106c49
f0101943:	e8 f8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101948:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010194d:	74 19                	je     f0101968 <mem_init+0x760>
f010194f:	68 34 6e 10 f0       	push   $0xf0106e34
f0101954:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101959:	68 c2 03 00 00       	push   $0x3c2
f010195e:	68 49 6c 10 f0       	push   $0xf0106c49
f0101963:	e8 d8 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101968:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010196b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101970:	74 19                	je     f010198b <mem_init+0x783>
f0101972:	68 45 6e 10 f0       	push   $0xf0106e45
f0101977:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010197c:	68 c3 03 00 00       	push   $0x3c3
f0101981:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01019a0:	68 98 65 10 f0       	push   $0xf0106598
f01019a5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01019aa:	68 c6 03 00 00       	push   $0x3c6
f01019af:	68 49 6c 10 f0       	push   $0xf0106c49
f01019b4:	e8 87 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019be:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f01019c3:	e8 75 f0 ff ff       	call   f0100a3d <check_va2pa>
f01019c8:	89 f2                	mov    %esi,%edx
f01019ca:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f01019d0:	c1 fa 03             	sar    $0x3,%edx
f01019d3:	c1 e2 0c             	shl    $0xc,%edx
f01019d6:	39 d0                	cmp    %edx,%eax
f01019d8:	74 19                	je     f01019f3 <mem_init+0x7eb>
f01019da:	68 d4 65 10 f0       	push   $0xf01065d4
f01019df:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01019e4:	68 c7 03 00 00       	push   $0x3c7
f01019e9:	68 49 6c 10 f0       	push   $0xf0106c49
f01019ee:	e8 4d e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01019f3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019f8:	74 19                	je     f0101a13 <mem_init+0x80b>
f01019fa:	68 56 6e 10 f0       	push   $0xf0106e56
f01019ff:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101a04:	68 c8 03 00 00       	push   $0x3c8
f0101a09:	68 49 6c 10 f0       	push   $0xf0106c49
f0101a0e:	e8 2d e6 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a13:	83 ec 0c             	sub    $0xc,%esp
f0101a16:	6a 00                	push   $0x0
f0101a18:	e8 6f f4 ff ff       	call   f0100e8c <page_alloc>
f0101a1d:	83 c4 10             	add    $0x10,%esp
f0101a20:	85 c0                	test   %eax,%eax
f0101a22:	74 19                	je     f0101a3d <mem_init+0x835>
f0101a24:	68 e2 6d 10 f0       	push   $0xf0106de2
f0101a29:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101a2e:	68 cb 03 00 00       	push   $0x3cb
f0101a33:	68 49 6c 10 f0       	push   $0xf0106c49
f0101a38:	e8 03 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a3d:	6a 02                	push   $0x2
f0101a3f:	68 00 10 00 00       	push   $0x1000
f0101a44:	56                   	push   %esi
f0101a45:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101a4b:	e8 dd f6 ff ff       	call   f010112d <page_insert>
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	85 c0                	test   %eax,%eax
f0101a55:	74 19                	je     f0101a70 <mem_init+0x868>
f0101a57:	68 98 65 10 f0       	push   $0xf0106598
f0101a5c:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101a61:	68 ce 03 00 00       	push   $0x3ce
f0101a66:	68 49 6c 10 f0       	push   $0xf0106c49
f0101a6b:	e8 d0 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a75:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0101a7a:	e8 be ef ff ff       	call   f0100a3d <check_va2pa>
f0101a7f:	89 f2                	mov    %esi,%edx
f0101a81:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101a87:	c1 fa 03             	sar    $0x3,%edx
f0101a8a:	c1 e2 0c             	shl    $0xc,%edx
f0101a8d:	39 d0                	cmp    %edx,%eax
f0101a8f:	74 19                	je     f0101aaa <mem_init+0x8a2>
f0101a91:	68 d4 65 10 f0       	push   $0xf01065d4
f0101a96:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101a9b:	68 cf 03 00 00       	push   $0x3cf
f0101aa0:	68 49 6c 10 f0       	push   $0xf0106c49
f0101aa5:	e8 96 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101aaa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aaf:	74 19                	je     f0101aca <mem_init+0x8c2>
f0101ab1:	68 56 6e 10 f0       	push   $0xf0106e56
f0101ab6:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101abb:	68 d0 03 00 00       	push   $0x3d0
f0101ac0:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101adb:	68 e2 6d 10 f0       	push   $0xf0106de2
f0101ae0:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101ae5:	68 d4 03 00 00       	push   $0x3d4
f0101aea:	68 49 6c 10 f0       	push   $0xf0106c49
f0101aef:	e8 4c e5 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101af4:	8b 15 8c ee 22 f0    	mov    0xf022ee8c,%edx
f0101afa:	8b 02                	mov    (%edx),%eax
f0101afc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b01:	89 c1                	mov    %eax,%ecx
f0101b03:	c1 e9 0c             	shr    $0xc,%ecx
f0101b06:	3b 0d 88 ee 22 f0    	cmp    0xf022ee88,%ecx
f0101b0c:	72 15                	jb     f0101b23 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b0e:	50                   	push   %eax
f0101b0f:	68 e4 5d 10 f0       	push   $0xf0105de4
f0101b14:	68 d7 03 00 00       	push   $0x3d7
f0101b19:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101b48:	68 04 66 10 f0       	push   $0xf0106604
f0101b4d:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101b52:	68 d8 03 00 00       	push   $0x3d8
f0101b57:	68 49 6c 10 f0       	push   $0xf0106c49
f0101b5c:	e8 df e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b61:	6a 06                	push   $0x6
f0101b63:	68 00 10 00 00       	push   $0x1000
f0101b68:	56                   	push   %esi
f0101b69:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101b6f:	e8 b9 f5 ff ff       	call   f010112d <page_insert>
f0101b74:	83 c4 10             	add    $0x10,%esp
f0101b77:	85 c0                	test   %eax,%eax
f0101b79:	74 19                	je     f0101b94 <mem_init+0x98c>
f0101b7b:	68 44 66 10 f0       	push   $0xf0106644
f0101b80:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101b85:	68 db 03 00 00       	push   $0x3db
f0101b8a:	68 49 6c 10 f0       	push   $0xf0106c49
f0101b8f:	e8 ac e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b94:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101b9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9f:	89 f8                	mov    %edi,%eax
f0101ba1:	e8 97 ee ff ff       	call   f0100a3d <check_va2pa>
f0101ba6:	89 f2                	mov    %esi,%edx
f0101ba8:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101bae:	c1 fa 03             	sar    $0x3,%edx
f0101bb1:	c1 e2 0c             	shl    $0xc,%edx
f0101bb4:	39 d0                	cmp    %edx,%eax
f0101bb6:	74 19                	je     f0101bd1 <mem_init+0x9c9>
f0101bb8:	68 d4 65 10 f0       	push   $0xf01065d4
f0101bbd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101bc2:	68 dc 03 00 00       	push   $0x3dc
f0101bc7:	68 49 6c 10 f0       	push   $0xf0106c49
f0101bcc:	e8 6f e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bd1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bd6:	74 19                	je     f0101bf1 <mem_init+0x9e9>
f0101bd8:	68 56 6e 10 f0       	push   $0xf0106e56
f0101bdd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101be2:	68 dd 03 00 00       	push   $0x3dd
f0101be7:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101c09:	68 84 66 10 f0       	push   $0xf0106684
f0101c0e:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101c13:	68 de 03 00 00       	push   $0x3de
f0101c18:	68 49 6c 10 f0       	push   $0xf0106c49
f0101c1d:	e8 1e e4 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c22:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0101c27:	f6 00 04             	testb  $0x4,(%eax)
f0101c2a:	75 19                	jne    f0101c45 <mem_init+0xa3d>
f0101c2c:	68 67 6e 10 f0       	push   $0xf0106e67
f0101c31:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101c36:	68 df 03 00 00       	push   $0x3df
f0101c3b:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101c5a:	68 98 65 10 f0       	push   $0xf0106598
f0101c5f:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101c64:	68 e2 03 00 00       	push   $0x3e2
f0101c69:	68 49 6c 10 f0       	push   $0xf0106c49
f0101c6e:	e8 cd e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c73:	83 ec 04             	sub    $0x4,%esp
f0101c76:	6a 00                	push   $0x0
f0101c78:	68 00 10 00 00       	push   $0x1000
f0101c7d:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101c83:	e8 d8 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101c88:	83 c4 10             	add    $0x10,%esp
f0101c8b:	f6 00 02             	testb  $0x2,(%eax)
f0101c8e:	75 19                	jne    f0101ca9 <mem_init+0xaa1>
f0101c90:	68 b8 66 10 f0       	push   $0xf01066b8
f0101c95:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101c9a:	68 e3 03 00 00       	push   $0x3e3
f0101c9f:	68 49 6c 10 f0       	push   $0xf0106c49
f0101ca4:	e8 97 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ca9:	83 ec 04             	sub    $0x4,%esp
f0101cac:	6a 00                	push   $0x0
f0101cae:	68 00 10 00 00       	push   $0x1000
f0101cb3:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101cb9:	e8 a2 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101cbe:	83 c4 10             	add    $0x10,%esp
f0101cc1:	f6 00 04             	testb  $0x4,(%eax)
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xad7>
f0101cc6:	68 ec 66 10 f0       	push   $0xf01066ec
f0101ccb:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101cd0:	68 e4 03 00 00       	push   $0x3e4
f0101cd5:	68 49 6c 10 f0       	push   $0xf0106c49
f0101cda:	e8 61 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101cdf:	6a 02                	push   $0x2
f0101ce1:	68 00 00 40 00       	push   $0x400000
f0101ce6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ce9:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101cef:	e8 39 f4 ff ff       	call   f010112d <page_insert>
f0101cf4:	83 c4 10             	add    $0x10,%esp
f0101cf7:	85 c0                	test   %eax,%eax
f0101cf9:	78 19                	js     f0101d14 <mem_init+0xb0c>
f0101cfb:	68 24 67 10 f0       	push   $0xf0106724
f0101d00:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101d05:	68 e7 03 00 00       	push   $0x3e7
f0101d0a:	68 49 6c 10 f0       	push   $0xf0106c49
f0101d0f:	e8 2c e3 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d14:	6a 02                	push   $0x2
f0101d16:	68 00 10 00 00       	push   $0x1000
f0101d1b:	53                   	push   %ebx
f0101d1c:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101d22:	e8 06 f4 ff ff       	call   f010112d <page_insert>
f0101d27:	83 c4 10             	add    $0x10,%esp
f0101d2a:	85 c0                	test   %eax,%eax
f0101d2c:	74 19                	je     f0101d47 <mem_init+0xb3f>
f0101d2e:	68 60 67 10 f0       	push   $0xf0106760
f0101d33:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101d38:	68 ea 03 00 00       	push   $0x3ea
f0101d3d:	68 49 6c 10 f0       	push   $0xf0106c49
f0101d42:	e8 f9 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d47:	83 ec 04             	sub    $0x4,%esp
f0101d4a:	6a 00                	push   $0x0
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101d57:	e8 04 f2 ff ff       	call   f0100f60 <pgdir_walk>
f0101d5c:	83 c4 10             	add    $0x10,%esp
f0101d5f:	f6 00 04             	testb  $0x4,(%eax)
f0101d62:	74 19                	je     f0101d7d <mem_init+0xb75>
f0101d64:	68 ec 66 10 f0       	push   $0xf01066ec
f0101d69:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101d6e:	68 eb 03 00 00       	push   $0x3eb
f0101d73:	68 49 6c 10 f0       	push   $0xf0106c49
f0101d78:	e8 c3 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d7d:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101d83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d88:	89 f8                	mov    %edi,%eax
f0101d8a:	e8 ae ec ff ff       	call   f0100a3d <check_va2pa>
f0101d8f:	89 c1                	mov    %eax,%ecx
f0101d91:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d94:	89 d8                	mov    %ebx,%eax
f0101d96:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0101d9c:	c1 f8 03             	sar    $0x3,%eax
f0101d9f:	c1 e0 0c             	shl    $0xc,%eax
f0101da2:	39 c1                	cmp    %eax,%ecx
f0101da4:	74 19                	je     f0101dbf <mem_init+0xbb7>
f0101da6:	68 9c 67 10 f0       	push   $0xf010679c
f0101dab:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101db0:	68 ee 03 00 00       	push   $0x3ee
f0101db5:	68 49 6c 10 f0       	push   $0xf0106c49
f0101dba:	e8 81 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc4:	89 f8                	mov    %edi,%eax
f0101dc6:	e8 72 ec ff ff       	call   f0100a3d <check_va2pa>
f0101dcb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101dce:	74 19                	je     f0101de9 <mem_init+0xbe1>
f0101dd0:	68 c8 67 10 f0       	push   $0xf01067c8
f0101dd5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101dda:	68 ef 03 00 00       	push   $0x3ef
f0101ddf:	68 49 6c 10 f0       	push   $0xf0106c49
f0101de4:	e8 57 e2 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101de9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101dee:	74 19                	je     f0101e09 <mem_init+0xc01>
f0101df0:	68 7d 6e 10 f0       	push   $0xf0106e7d
f0101df5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101dfa:	68 f1 03 00 00       	push   $0x3f1
f0101dff:	68 49 6c 10 f0       	push   $0xf0106c49
f0101e04:	e8 37 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e09:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e0e:	74 19                	je     f0101e29 <mem_init+0xc21>
f0101e10:	68 8e 6e 10 f0       	push   $0xf0106e8e
f0101e15:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101e1a:	68 f2 03 00 00       	push   $0x3f2
f0101e1f:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101e3e:	68 f8 67 10 f0       	push   $0xf01067f8
f0101e43:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101e48:	68 f5 03 00 00       	push   $0x3f5
f0101e4d:	68 49 6c 10 f0       	push   $0xf0106c49
f0101e52:	e8 e9 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e57:	83 ec 08             	sub    $0x8,%esp
f0101e5a:	6a 00                	push   $0x0
f0101e5c:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101e62:	e8 79 f2 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e67:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101e6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e72:	89 f8                	mov    %edi,%eax
f0101e74:	e8 c4 eb ff ff       	call   f0100a3d <check_va2pa>
f0101e79:	83 c4 10             	add    $0x10,%esp
f0101e7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xc92>
f0101e81:	68 1c 68 10 f0       	push   $0xf010681c
f0101e86:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101e8b:	68 f9 03 00 00       	push   $0x3f9
f0101e90:	68 49 6c 10 f0       	push   $0xf0106c49
f0101e95:	e8 a6 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e9f:	89 f8                	mov    %edi,%eax
f0101ea1:	e8 97 eb ff ff       	call   f0100a3d <check_va2pa>
f0101ea6:	89 da                	mov    %ebx,%edx
f0101ea8:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
f0101eae:	c1 fa 03             	sar    $0x3,%edx
f0101eb1:	c1 e2 0c             	shl    $0xc,%edx
f0101eb4:	39 d0                	cmp    %edx,%eax
f0101eb6:	74 19                	je     f0101ed1 <mem_init+0xcc9>
f0101eb8:	68 c8 67 10 f0       	push   $0xf01067c8
f0101ebd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101ec2:	68 fa 03 00 00       	push   $0x3fa
f0101ec7:	68 49 6c 10 f0       	push   $0xf0106c49
f0101ecc:	e8 6f e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ed1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ed6:	74 19                	je     f0101ef1 <mem_init+0xce9>
f0101ed8:	68 34 6e 10 f0       	push   $0xf0106e34
f0101edd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101ee2:	68 fb 03 00 00       	push   $0x3fb
f0101ee7:	68 49 6c 10 f0       	push   $0xf0106c49
f0101eec:	e8 4f e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ef1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ef6:	74 19                	je     f0101f11 <mem_init+0xd09>
f0101ef8:	68 8e 6e 10 f0       	push   $0xf0106e8e
f0101efd:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101f02:	68 fc 03 00 00       	push   $0x3fc
f0101f07:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0101f26:	68 40 68 10 f0       	push   $0xf0106840
f0101f2b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101f30:	68 ff 03 00 00       	push   $0x3ff
f0101f35:	68 49 6c 10 f0       	push   $0xf0106c49
f0101f3a:	e8 01 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101f3f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f44:	75 19                	jne    f0101f5f <mem_init+0xd57>
f0101f46:	68 9f 6e 10 f0       	push   $0xf0106e9f
f0101f4b:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101f50:	68 00 04 00 00       	push   $0x400
f0101f55:	68 49 6c 10 f0       	push   $0xf0106c49
f0101f5a:	e8 e1 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101f5f:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101f62:	74 19                	je     f0101f7d <mem_init+0xd75>
f0101f64:	68 ab 6e 10 f0       	push   $0xf0106eab
f0101f69:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101f6e:	68 01 04 00 00       	push   $0x401
f0101f73:	68 49 6c 10 f0       	push   $0xf0106c49
f0101f78:	e8 c3 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f7d:	83 ec 08             	sub    $0x8,%esp
f0101f80:	68 00 10 00 00       	push   $0x1000
f0101f85:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0101f8b:	e8 50 f1 ff ff       	call   f01010e0 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f90:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0101f96:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f9b:	89 f8                	mov    %edi,%eax
f0101f9d:	e8 9b ea ff ff       	call   f0100a3d <check_va2pa>
f0101fa2:	83 c4 10             	add    $0x10,%esp
f0101fa5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa8:	74 19                	je     f0101fc3 <mem_init+0xdbb>
f0101faa:	68 1c 68 10 f0       	push   $0xf010681c
f0101faf:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101fb4:	68 05 04 00 00       	push   $0x405
f0101fb9:	68 49 6c 10 f0       	push   $0xf0106c49
f0101fbe:	e8 7d e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fc3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc8:	89 f8                	mov    %edi,%eax
f0101fca:	e8 6e ea ff ff       	call   f0100a3d <check_va2pa>
f0101fcf:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fd2:	74 19                	je     f0101fed <mem_init+0xde5>
f0101fd4:	68 78 68 10 f0       	push   $0xf0106878
f0101fd9:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101fde:	68 06 04 00 00       	push   $0x406
f0101fe3:	68 49 6c 10 f0       	push   $0xf0106c49
f0101fe8:	e8 53 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0101fed:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ff2:	74 19                	je     f010200d <mem_init+0xe05>
f0101ff4:	68 c0 6e 10 f0       	push   $0xf0106ec0
f0101ff9:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0101ffe:	68 07 04 00 00       	push   $0x407
f0102003:	68 49 6c 10 f0       	push   $0xf0106c49
f0102008:	e8 33 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010200d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102012:	74 19                	je     f010202d <mem_init+0xe25>
f0102014:	68 8e 6e 10 f0       	push   $0xf0106e8e
f0102019:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010201e:	68 08 04 00 00       	push   $0x408
f0102023:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102042:	68 a0 68 10 f0       	push   $0xf01068a0
f0102047:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010204c:	68 0b 04 00 00       	push   $0x40b
f0102051:	68 49 6c 10 f0       	push   $0xf0106c49
f0102056:	e8 e5 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010205b:	83 ec 0c             	sub    $0xc,%esp
f010205e:	6a 00                	push   $0x0
f0102060:	e8 27 ee ff ff       	call   f0100e8c <page_alloc>
f0102065:	83 c4 10             	add    $0x10,%esp
f0102068:	85 c0                	test   %eax,%eax
f010206a:	74 19                	je     f0102085 <mem_init+0xe7d>
f010206c:	68 e2 6d 10 f0       	push   $0xf0106de2
f0102071:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102076:	68 0e 04 00 00       	push   $0x40e
f010207b:	68 49 6c 10 f0       	push   $0xf0106c49
f0102080:	e8 bb df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102085:	8b 0d 8c ee 22 f0    	mov    0xf022ee8c,%ecx
f010208b:	8b 11                	mov    (%ecx),%edx
f010208d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102093:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102096:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f010209c:	c1 f8 03             	sar    $0x3,%eax
f010209f:	c1 e0 0c             	shl    $0xc,%eax
f01020a2:	39 c2                	cmp    %eax,%edx
f01020a4:	74 19                	je     f01020bf <mem_init+0xeb7>
f01020a6:	68 40 65 10 f0       	push   $0xf0106540
f01020ab:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01020b0:	68 11 04 00 00       	push   $0x411
f01020b5:	68 49 6c 10 f0       	push   $0xf0106c49
f01020ba:	e8 81 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01020bf:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020cd:	74 19                	je     f01020e8 <mem_init+0xee0>
f01020cf:	68 45 6e 10 f0       	push   $0xf0106e45
f01020d4:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01020d9:	68 13 04 00 00       	push   $0x413
f01020de:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102104:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f010210a:	e8 51 ee ff ff       	call   f0100f60 <pgdir_walk>
f010210f:	89 c7                	mov    %eax,%edi
f0102111:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102114:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0102119:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010211c:	8b 40 04             	mov    0x4(%eax),%eax
f010211f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102124:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f010212a:	89 c2                	mov    %eax,%edx
f010212c:	c1 ea 0c             	shr    $0xc,%edx
f010212f:	83 c4 10             	add    $0x10,%esp
f0102132:	39 ca                	cmp    %ecx,%edx
f0102134:	72 15                	jb     f010214b <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102136:	50                   	push   %eax
f0102137:	68 e4 5d 10 f0       	push   $0xf0105de4
f010213c:	68 1a 04 00 00       	push   $0x41a
f0102141:	68 49 6c 10 f0       	push   $0xf0106c49
f0102146:	e8 f5 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010214b:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102150:	39 c7                	cmp    %eax,%edi
f0102152:	74 19                	je     f010216d <mem_init+0xf65>
f0102154:	68 d1 6e 10 f0       	push   $0xf0106ed1
f0102159:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010215e:	68 1b 04 00 00       	push   $0x41b
f0102163:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102180:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f0102196:	68 e4 5d 10 f0       	push   $0xf0105de4
f010219b:	6a 58                	push   $0x58
f010219d:	68 55 6c 10 f0       	push   $0xf0106c55
f01021a2:	e8 99 de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021a7:	83 ec 04             	sub    $0x4,%esp
f01021aa:	68 00 10 00 00       	push   $0x1000
f01021af:	68 ff 00 00 00       	push   $0xff
f01021b4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01021b9:	50                   	push   %eax
f01021ba:	e8 26 2f 00 00       	call   f01050e5 <memset>
	page_free(pp0);
f01021bf:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021c2:	89 3c 24             	mov    %edi,(%esp)
f01021c5:	e8 32 ed ff ff       	call   f0100efc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021ca:	83 c4 0c             	add    $0xc,%esp
f01021cd:	6a 01                	push   $0x1
f01021cf:	6a 00                	push   $0x0
f01021d1:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f01021d7:	e8 84 ed ff ff       	call   f0100f60 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021dc:	89 fa                	mov    %edi,%edx
f01021de:	2b 15 90 ee 22 f0    	sub    0xf022ee90,%edx
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
f01021f2:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f01021f8:	72 12                	jb     f010220c <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021fa:	52                   	push   %edx
f01021fb:	68 e4 5d 10 f0       	push   $0xf0105de4
f0102200:	6a 58                	push   $0x58
f0102202:	68 55 6c 10 f0       	push   $0xf0106c55
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
f0102220:	68 e9 6e 10 f0       	push   $0xf0106ee9
f0102225:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010222a:	68 25 04 00 00       	push   $0x425
f010222f:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102240:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f0102245:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010224b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010224e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102254:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102257:	89 0d 40 e2 22 f0    	mov    %ecx,0xf022e240

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
f01022b0:	68 c4 68 10 f0       	push   $0xf01068c4
f01022b5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01022ba:	68 35 04 00 00       	push   $0x435
f01022bf:	68 49 6c 10 f0       	push   $0xf0106c49
f01022c4:	e8 77 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01022c9:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01022cf:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01022d5:	77 08                	ja     f01022df <mem_init+0x10d7>
f01022d7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01022dd:	77 19                	ja     f01022f8 <mem_init+0x10f0>
f01022df:	68 ec 68 10 f0       	push   $0xf01068ec
f01022e4:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01022e9:	68 36 04 00 00       	push   $0x436
f01022ee:	68 49 6c 10 f0       	push   $0xf0106c49
f01022f3:	e8 48 dd ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01022f8:	89 da                	mov    %ebx,%edx
f01022fa:	09 f2                	or     %esi,%edx
f01022fc:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102302:	74 19                	je     f010231d <mem_init+0x1115>
f0102304:	68 14 69 10 f0       	push   $0xf0106914
f0102309:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010230e:	68 38 04 00 00       	push   $0x438
f0102313:	68 49 6c 10 f0       	push   $0xf0106c49
f0102318:	e8 23 dd ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010231d:	39 c6                	cmp    %eax,%esi
f010231f:	73 19                	jae    f010233a <mem_init+0x1132>
f0102321:	68 00 6f 10 f0       	push   $0xf0106f00
f0102326:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010232b:	68 3a 04 00 00       	push   $0x43a
f0102330:	68 49 6c 10 f0       	push   $0xf0106c49
f0102335:	e8 06 dd ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010233a:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi
f0102340:	89 da                	mov    %ebx,%edx
f0102342:	89 f8                	mov    %edi,%eax
f0102344:	e8 f4 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102349:	85 c0                	test   %eax,%eax
f010234b:	74 19                	je     f0102366 <mem_init+0x115e>
f010234d:	68 3c 69 10 f0       	push   $0xf010693c
f0102352:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102357:	68 3c 04 00 00       	push   $0x43c
f010235c:	68 49 6c 10 f0       	push   $0xf0106c49
f0102361:	e8 da dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102366:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010236c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010236f:	89 c2                	mov    %eax,%edx
f0102371:	89 f8                	mov    %edi,%eax
f0102373:	e8 c5 e6 ff ff       	call   f0100a3d <check_va2pa>
f0102378:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010237d:	74 19                	je     f0102398 <mem_init+0x1190>
f010237f:	68 60 69 10 f0       	push   $0xf0106960
f0102384:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102389:	68 3d 04 00 00       	push   $0x43d
f010238e:	68 49 6c 10 f0       	push   $0xf0106c49
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102398:	89 f2                	mov    %esi,%edx
f010239a:	89 f8                	mov    %edi,%eax
f010239c:	e8 9c e6 ff ff       	call   f0100a3d <check_va2pa>
f01023a1:	85 c0                	test   %eax,%eax
f01023a3:	74 19                	je     f01023be <mem_init+0x11b6>
f01023a5:	68 90 69 10 f0       	push   $0xf0106990
f01023aa:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01023af:	68 3e 04 00 00       	push   $0x43e
f01023b4:	68 49 6c 10 f0       	push   $0xf0106c49
f01023b9:	e8 82 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01023be:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01023c4:	89 f8                	mov    %edi,%eax
f01023c6:	e8 72 e6 ff ff       	call   f0100a3d <check_va2pa>
f01023cb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023ce:	74 19                	je     f01023e9 <mem_init+0x11e1>
f01023d0:	68 b4 69 10 f0       	push   $0xf01069b4
f01023d5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01023da:	68 3f 04 00 00       	push   $0x43f
f01023df:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01023fd:	68 e0 69 10 f0       	push   $0xf01069e0
f0102402:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102407:	68 41 04 00 00       	push   $0x441
f010240c:	68 49 6c 10 f0       	push   $0xf0106c49
f0102411:	e8 2a dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102416:	83 ec 04             	sub    $0x4,%esp
f0102419:	6a 00                	push   $0x0
f010241b:	53                   	push   %ebx
f010241c:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102422:	e8 39 eb ff ff       	call   f0100f60 <pgdir_walk>
f0102427:	8b 00                	mov    (%eax),%eax
f0102429:	83 c4 10             	add    $0x10,%esp
f010242c:	83 e0 04             	and    $0x4,%eax
f010242f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102432:	74 19                	je     f010244d <mem_init+0x1245>
f0102434:	68 24 6a 10 f0       	push   $0xf0106a24
f0102439:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010243e:	68 42 04 00 00       	push   $0x442
f0102443:	68 49 6c 10 f0       	push   $0xf0106c49
f0102448:	e8 f3 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010244d:	83 ec 04             	sub    $0x4,%esp
f0102450:	6a 00                	push   $0x0
f0102452:	53                   	push   %ebx
f0102453:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102459:	e8 02 eb ff ff       	call   f0100f60 <pgdir_walk>
f010245e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102464:	83 c4 0c             	add    $0xc,%esp
f0102467:	6a 00                	push   $0x0
f0102469:	ff 75 d4             	pushl  -0x2c(%ebp)
f010246c:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102472:	e8 e9 ea ff ff       	call   f0100f60 <pgdir_walk>
f0102477:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010247d:	83 c4 0c             	add    $0xc,%esp
f0102480:	6a 00                	push   $0x0
f0102482:	56                   	push   %esi
f0102483:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102489:	e8 d2 ea ff ff       	call   f0100f60 <pgdir_walk>
f010248e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102494:	c7 04 24 12 6f 10 f0 	movl   $0xf0106f12,(%esp)
f010249b:	e8 0d 11 00 00       	call   f01035ad <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f01024a0:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f01024b0:	68 08 5e 10 f0       	push   $0xf0105e08
f01024b5:	68 b9 00 00 00       	push   $0xb9
f01024ba:	68 49 6c 10 f0       	push   $0xf0106c49
f01024bf:	e8 7c db ff ff       	call   f0100040 <_panic>
f01024c4:	83 ec 08             	sub    $0x8,%esp
f01024c7:	6a 05                	push   $0x5
f01024c9:	05 00 00 00 10       	add    $0x10000000,%eax
f01024ce:	50                   	push   %eax
f01024cf:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01024d4:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024d9:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f01024de:	e8 10 eb ff ff       	call   f0100ff3 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U|PTE_P);
f01024e3:	a1 44 e2 22 f0       	mov    0xf022e244,%eax
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
f01024f3:	68 08 5e 10 f0       	push   $0xf0105e08
f01024f8:	68 c1 00 00 00       	push   $0xc1
f01024fd:	68 49 6c 10 f0       	push   $0xf0106c49
f0102502:	e8 39 db ff ff       	call   f0100040 <_panic>
f0102507:	83 ec 08             	sub    $0x8,%esp
f010250a:	6a 05                	push   $0x5
f010250c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102511:	50                   	push   %eax
f0102512:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102517:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010251c:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0102536:	68 08 5e 10 f0       	push   $0xf0105e08
f010253b:	68 cd 00 00 00       	push   $0xcd
f0102540:	68 49 6c 10 f0       	push   $0xf0106c49
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
f010255e:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f0102579:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
f010257e:	e8 70 ea ff ff       	call   f0100ff3 <boot_map_region>
f0102583:	c7 45 c4 00 00 23 f0 	movl   $0xf0230000,-0x3c(%ebp)
f010258a:	83 c4 10             	add    $0x10,%esp
f010258d:	bb 00 00 23 f0       	mov    $0xf0230000,%ebx
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
f01025a0:	68 08 5e 10 f0       	push   $0xf0105e08
f01025a5:	68 0f 01 00 00       	push   $0x10f
f01025aa:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01025c7:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f01025e0:	b8 00 00 27 f0       	mov    $0xf0270000,%eax
f01025e5:	39 d8                	cmp    %ebx,%eax
f01025e7:	75 ae                	jne    f0102597 <mem_init+0x138f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01025e9:	8b 3d 8c ee 22 f0    	mov    0xf022ee8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01025ef:	a1 88 ee 22 f0       	mov    0xf022ee88,%eax
f01025f4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01025f7:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01025fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102603:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102606:	8b 35 90 ee 22 f0    	mov    0xf022ee90,%esi
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
f010262d:	68 08 5e 10 f0       	push   $0xf0105e08
f0102632:	68 5b 03 00 00       	push   $0x35b
f0102637:	68 49 6c 10 f0       	push   $0xf0106c49
f010263c:	e8 ff d9 ff ff       	call   f0100040 <_panic>
f0102641:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102648:	39 c2                	cmp    %eax,%edx
f010264a:	74 19                	je     f0102665 <mem_init+0x145d>
f010264c:	68 58 6a 10 f0       	push   $0xf0106a58
f0102651:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102656:	68 5b 03 00 00       	push   $0x35b
f010265b:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102670:	8b 35 44 e2 22 f0    	mov    0xf022e244,%esi
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
f0102691:	68 08 5e 10 f0       	push   $0xf0105e08
f0102696:	68 60 03 00 00       	push   $0x360
f010269b:	68 49 6c 10 f0       	push   $0xf0106c49
f01026a0:	e8 9b d9 ff ff       	call   f0100040 <_panic>
f01026a5:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01026ac:	39 d0                	cmp    %edx,%eax
f01026ae:	74 19                	je     f01026c9 <mem_init+0x14c1>
f01026b0:	68 8c 6a 10 f0       	push   $0xf0106a8c
f01026b5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01026ba:	68 60 03 00 00       	push   $0x360
f01026bf:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01026f5:	68 c0 6a 10 f0       	push   $0xf0106ac0
f01026fa:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01026ff:	68 64 03 00 00       	push   $0x364
f0102704:	68 49 6c 10 f0       	push   $0xf0106c49
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
f010274e:	68 08 5e 10 f0       	push   $0xf0105e08
f0102753:	68 6c 03 00 00       	push   $0x36c
f0102758:	68 49 6c 10 f0       	push   $0xf0106c49
f010275d:	e8 de d8 ff ff       	call   f0100040 <_panic>
f0102762:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102765:	8d 94 0b 00 00 23 f0 	lea    -0xfdd0000(%ebx,%ecx,1),%edx
f010276c:	39 d0                	cmp    %edx,%eax
f010276e:	74 19                	je     f0102789 <mem_init+0x1581>
f0102770:	68 e8 6a 10 f0       	push   $0xf0106ae8
f0102775:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010277a:	68 6c 03 00 00       	push   $0x36c
f010277f:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01027b0:	68 30 6b 10 f0       	push   $0xf0106b30
f01027b5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f01027ba:	68 6e 03 00 00       	push   $0x36e
f01027bf:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01027ea:	b8 00 00 27 f0       	mov    $0xf0270000,%eax
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
f010280f:	68 2b 6f 10 f0       	push   $0xf0106f2b
f0102814:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102819:	68 79 03 00 00       	push   $0x379
f010281e:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102837:	68 2b 6f 10 f0       	push   $0xf0106f2b
f010283c:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102841:	68 7d 03 00 00       	push   $0x37d
f0102846:	68 49 6c 10 f0       	push   $0xf0106c49
f010284b:	e8 f0 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102850:	f6 c2 02             	test   $0x2,%dl
f0102853:	75 38                	jne    f010288d <mem_init+0x1685>
f0102855:	68 3c 6f 10 f0       	push   $0xf0106f3c
f010285a:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010285f:	68 7e 03 00 00       	push   $0x37e
f0102864:	68 49 6c 10 f0       	push   $0xf0106c49
f0102869:	e8 d2 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010286e:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102872:	74 19                	je     f010288d <mem_init+0x1685>
f0102874:	68 4d 6f 10 f0       	push   $0xf0106f4d
f0102879:	68 6f 6c 10 f0       	push   $0xf0106c6f
f010287e:	68 80 03 00 00       	push   $0x380
f0102883:	68 49 6c 10 f0       	push   $0xf0106c49
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
f010289e:	68 54 6b 10 f0       	push   $0xf0106b54
f01028a3:	e8 05 0d 00 00       	call   f01035ad <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028a8:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
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
f01028b8:	68 08 5e 10 f0       	push   $0xf0105e08
f01028bd:	68 e5 00 00 00       	push   $0xe5
f01028c2:	68 49 6c 10 f0       	push   $0xf0106c49
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
f01028ff:	68 37 6d 10 f0       	push   $0xf0106d37
f0102904:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102909:	68 57 04 00 00       	push   $0x457
f010290e:	68 49 6c 10 f0       	push   $0xf0106c49
f0102913:	e8 28 d7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102918:	83 ec 0c             	sub    $0xc,%esp
f010291b:	6a 00                	push   $0x0
f010291d:	e8 6a e5 ff ff       	call   f0100e8c <page_alloc>
f0102922:	89 c7                	mov    %eax,%edi
f0102924:	83 c4 10             	add    $0x10,%esp
f0102927:	85 c0                	test   %eax,%eax
f0102929:	75 19                	jne    f0102944 <mem_init+0x173c>
f010292b:	68 4d 6d 10 f0       	push   $0xf0106d4d
f0102930:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102935:	68 58 04 00 00       	push   $0x458
f010293a:	68 49 6c 10 f0       	push   $0xf0106c49
f010293f:	e8 fc d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102944:	83 ec 0c             	sub    $0xc,%esp
f0102947:	6a 00                	push   $0x0
f0102949:	e8 3e e5 ff ff       	call   f0100e8c <page_alloc>
f010294e:	89 c6                	mov    %eax,%esi
f0102950:	83 c4 10             	add    $0x10,%esp
f0102953:	85 c0                	test   %eax,%eax
f0102955:	75 19                	jne    f0102970 <mem_init+0x1768>
f0102957:	68 63 6d 10 f0       	push   $0xf0106d63
f010295c:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102961:	68 59 04 00 00       	push   $0x459
f0102966:	68 49 6c 10 f0       	push   $0xf0106c49
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
f010297b:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f010298f:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102995:	72 12                	jb     f01029a9 <mem_init+0x17a1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102997:	50                   	push   %eax
f0102998:	68 e4 5d 10 f0       	push   $0xf0105de4
f010299d:	6a 58                	push   $0x58
f010299f:	68 55 6c 10 f0       	push   $0xf0106c55
f01029a4:	e8 97 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029a9:	83 ec 04             	sub    $0x4,%esp
f01029ac:	68 00 10 00 00       	push   $0x1000
f01029b1:	6a 01                	push   $0x1
f01029b3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029b8:	50                   	push   %eax
f01029b9:	e8 27 27 00 00       	call   f01050e5 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029be:	89 f0                	mov    %esi,%eax
f01029c0:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
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
f01029d4:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f01029da:	72 12                	jb     f01029ee <mem_init+0x17e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029dc:	50                   	push   %eax
f01029dd:	68 e4 5d 10 f0       	push   $0xf0105de4
f01029e2:	6a 58                	push   $0x58
f01029e4:	68 55 6c 10 f0       	push   $0xf0106c55
f01029e9:	e8 52 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01029ee:	83 ec 04             	sub    $0x4,%esp
f01029f1:	68 00 10 00 00       	push   $0x1000
f01029f6:	6a 02                	push   $0x2
f01029f8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029fd:	50                   	push   %eax
f01029fe:	e8 e2 26 00 00       	call   f01050e5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a03:	6a 02                	push   $0x2
f0102a05:	68 00 10 00 00       	push   $0x1000
f0102a0a:	57                   	push   %edi
f0102a0b:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102a11:	e8 17 e7 ff ff       	call   f010112d <page_insert>
	assert(pp1->pp_ref == 1);
f0102a16:	83 c4 20             	add    $0x20,%esp
f0102a19:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a1e:	74 19                	je     f0102a39 <mem_init+0x1831>
f0102a20:	68 34 6e 10 f0       	push   $0xf0106e34
f0102a25:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102a2a:	68 5e 04 00 00       	push   $0x45e
f0102a2f:	68 49 6c 10 f0       	push   $0xf0106c49
f0102a34:	e8 07 d6 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a39:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a40:	01 01 01 
f0102a43:	74 19                	je     f0102a5e <mem_init+0x1856>
f0102a45:	68 74 6b 10 f0       	push   $0xf0106b74
f0102a4a:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102a4f:	68 5f 04 00 00       	push   $0x45f
f0102a54:	68 49 6c 10 f0       	push   $0xf0106c49
f0102a59:	e8 e2 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a5e:	6a 02                	push   $0x2
f0102a60:	68 00 10 00 00       	push   $0x1000
f0102a65:	56                   	push   %esi
f0102a66:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102a6c:	e8 bc e6 ff ff       	call   f010112d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a71:	83 c4 10             	add    $0x10,%esp
f0102a74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a7b:	02 02 02 
f0102a7e:	74 19                	je     f0102a99 <mem_init+0x1891>
f0102a80:	68 98 6b 10 f0       	push   $0xf0106b98
f0102a85:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102a8a:	68 61 04 00 00       	push   $0x461
f0102a8f:	68 49 6c 10 f0       	push   $0xf0106c49
f0102a94:	e8 a7 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102a99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102a9e:	74 19                	je     f0102ab9 <mem_init+0x18b1>
f0102aa0:	68 56 6e 10 f0       	push   $0xf0106e56
f0102aa5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102aaa:	68 62 04 00 00       	push   $0x462
f0102aaf:	68 49 6c 10 f0       	push   $0xf0106c49
f0102ab4:	e8 87 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102ab9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102abe:	74 19                	je     f0102ad9 <mem_init+0x18d1>
f0102ac0:	68 c0 6e 10 f0       	push   $0xf0106ec0
f0102ac5:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102aca:	68 63 04 00 00       	push   $0x463
f0102acf:	68 49 6c 10 f0       	push   $0xf0106c49
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
f0102ae5:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102aeb:	c1 f8 03             	sar    $0x3,%eax
f0102aee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af1:	89 c2                	mov    %eax,%edx
f0102af3:	c1 ea 0c             	shr    $0xc,%edx
f0102af6:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102afc:	72 12                	jb     f0102b10 <mem_init+0x1908>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afe:	50                   	push   %eax
f0102aff:	68 e4 5d 10 f0       	push   $0xf0105de4
f0102b04:	6a 58                	push   $0x58
f0102b06:	68 55 6c 10 f0       	push   $0xf0106c55
f0102b0b:	e8 30 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b10:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b17:	03 03 03 
f0102b1a:	74 19                	je     f0102b35 <mem_init+0x192d>
f0102b1c:	68 bc 6b 10 f0       	push   $0xf0106bbc
f0102b21:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102b26:	68 65 04 00 00       	push   $0x465
f0102b2b:	68 49 6c 10 f0       	push   $0xf0106c49
f0102b30:	e8 0b d5 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b35:	83 ec 08             	sub    $0x8,%esp
f0102b38:	68 00 10 00 00       	push   $0x1000
f0102b3d:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102b43:	e8 98 e5 ff ff       	call   f01010e0 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b48:	83 c4 10             	add    $0x10,%esp
f0102b4b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b50:	74 19                	je     f0102b6b <mem_init+0x1963>
f0102b52:	68 8e 6e 10 f0       	push   $0xf0106e8e
f0102b57:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102b5c:	68 67 04 00 00       	push   $0x467
f0102b61:	68 49 6c 10 f0       	push   $0xf0106c49
f0102b66:	e8 d5 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b6b:	8b 0d 8c ee 22 f0    	mov    0xf022ee8c,%ecx
f0102b71:	8b 11                	mov    (%ecx),%edx
f0102b73:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b79:	89 d8                	mov    %ebx,%eax
f0102b7b:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102b81:	c1 f8 03             	sar    $0x3,%eax
f0102b84:	c1 e0 0c             	shl    $0xc,%eax
f0102b87:	39 c2                	cmp    %eax,%edx
f0102b89:	74 19                	je     f0102ba4 <mem_init+0x199c>
f0102b8b:	68 40 65 10 f0       	push   $0xf0106540
f0102b90:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102b95:	68 6a 04 00 00       	push   $0x46a
f0102b9a:	68 49 6c 10 f0       	push   $0xf0106c49
f0102b9f:	e8 9c d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102ba4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102baa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102baf:	74 19                	je     f0102bca <mem_init+0x19c2>
f0102bb1:	68 45 6e 10 f0       	push   $0xf0106e45
f0102bb6:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0102bbb:	68 6c 04 00 00       	push   $0x46c
f0102bc0:	68 49 6c 10 f0       	push   $0xf0106c49
f0102bc5:	e8 76 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102bca:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102bd0:	83 ec 0c             	sub    $0xc,%esp
f0102bd3:	53                   	push   %ebx
f0102bd4:	e8 23 e3 ff ff       	call   f0100efc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bd9:	c7 04 24 e8 6b 10 f0 	movl   $0xf0106be8,(%esp)
f0102be0:	e8 c8 09 00 00       	call   f01035ad <cprintf>
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
f0102c1b:	89 1d 3c e2 22 f0    	mov    %ebx,0xf022e23c
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
f0102c45:	89 1d 3c e2 22 f0    	mov    %ebx,0xf022e23c
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
f0102c97:	ff 35 3c e2 22 f0    	pushl  0xf022e23c
f0102c9d:	ff 73 48             	pushl  0x48(%ebx)
f0102ca0:	68 14 6c 10 f0       	push   $0xf0106c14
f0102ca5:	e8 03 09 00 00       	call   f01035ad <cprintf>
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
f0102cf5:	68 5c 6f 10 f0       	push   $0xf0106f5c
f0102cfa:	68 26 01 00 00       	push   $0x126
f0102cff:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0102d1f:	68 84 6f 10 f0       	push   $0xf0106f84
f0102d24:	68 2b 01 00 00       	push   $0x12b
f0102d29:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0102d54:	e8 c2 29 00 00       	call   f010571b <cpunum>
f0102d59:	6b c0 74             	imul   $0x74,%eax,%eax
f0102d5c:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f0102d79:	03 1d 44 e2 22 f0    	add    0xf022e244,%ebx
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
f0102d9e:	e8 78 29 00 00       	call   f010571b <cpunum>
f0102da3:	6b c0 74             	imul   $0x74,%eax,%eax
f0102da6:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f0102dac:	74 26                	je     f0102dd4 <envid2env+0x8f>
f0102dae:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102db1:	e8 65 29 00 00       	call   f010571b <cpunum>
f0102db6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102db9:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
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
f0102e17:	8b 35 44 e2 22 f0    	mov    0xf022e244,%esi
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
f0102e47:	89 35 48 e2 22 f0    	mov    %esi,0xf022e248
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
f0102e5d:	8b 1d 48 e2 22 f0    	mov    0xf022e248,%ebx
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
f0102e85:	2b 05 90 ee 22 f0    	sub    0xf022ee90,%eax
f0102e8b:	c1 f8 03             	sar    $0x3,%eax
f0102e8e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e91:	89 c2                	mov    %eax,%edx
f0102e93:	c1 ea 0c             	shr    $0xc,%edx
f0102e96:	3b 15 88 ee 22 f0    	cmp    0xf022ee88,%edx
f0102e9c:	72 12                	jb     f0102eb0 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e9e:	50                   	push   %eax
f0102e9f:	68 e4 5d 10 f0       	push   $0xf0105de4
f0102ea4:	6a 58                	push   $0x58
f0102ea6:	68 55 6c 10 f0       	push   $0xf0106c55
f0102eab:	e8 90 d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102eb0:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f0102eb5:	89 43 60             	mov    %eax,0x60(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102eb8:	83 ec 04             	sub    $0x4,%esp
f0102ebb:	68 00 10 00 00       	push   $0x1000
f0102ec0:	ff 35 8c ee 22 f0    	pushl  0xf022ee8c
f0102ec6:	50                   	push   %eax
f0102ec7:	e8 ce 22 00 00       	call   f010519a <memcpy>
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
f0102eda:	68 08 5e 10 f0       	push   $0xf0105e08
f0102edf:	68 c7 00 00 00       	push   $0xc7
f0102ee4:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0102f14:	2b 15 44 e2 22 f0    	sub    0xf022e244,%edx
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
f0102f4b:	e8 95 21 00 00       	call   f01050e5 <memset>
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
f0102f7d:	a3 48 e2 22 f0       	mov    %eax,0xf022e248
	*newenv_store = e;
f0102f82:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f85:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f87:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102f8a:	e8 8c 27 00 00       	call   f010571b <cpunum>
f0102f8f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102f92:	83 c4 10             	add    $0x10,%esp
f0102f95:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f9a:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0102fa1:	74 11                	je     f0102fb4 <env_alloc+0x15e>
f0102fa3:	e8 73 27 00 00       	call   f010571b <cpunum>
f0102fa8:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fab:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0102fb1:	8b 50 48             	mov    0x48(%eax),%edx
f0102fb4:	83 ec 04             	sub    $0x4,%esp
f0102fb7:	53                   	push   %ebx
f0102fb8:	52                   	push   %edx
f0102fb9:	68 c4 6f 10 f0       	push   $0xf0106fc4
f0102fbe:	e8 ea 05 00 00       	call   f01035ad <cprintf>
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
f0103009:	68 d9 6f 10 f0       	push   $0xf0106fd9
f010300e:	68 70 01 00 00       	push   $0x170
f0103013:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0103030:	68 08 5e 10 f0       	push   $0xf0105e08
f0103035:	68 73 01 00 00       	push   $0x173
f010303a:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0103071:	e8 6f 20 00 00       	call   f01050e5 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f0103076:	83 c4 0c             	add    $0xc,%esp
f0103079:	ff 73 10             	pushl  0x10(%ebx)
f010307c:	89 f8                	mov    %edi,%eax
f010307e:	03 43 04             	add    0x4(%ebx),%eax
f0103081:	50                   	push   %eax
f0103082:	ff 73 08             	pushl  0x8(%ebx)
f0103085:	e8 10 21 00 00       	call   f010519a <memcpy>
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
f01030b5:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030bf:	77 15                	ja     f01030d6 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030c1:	50                   	push   %eax
f01030c2:	68 08 5e 10 f0       	push   $0xf0105e08
f01030c7:	68 85 01 00 00       	push   $0x185
f01030cc:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f01030fb:	e8 1b 26 00 00       	call   f010571b <cpunum>
f0103100:	6b c0 74             	imul   $0x74,%eax,%eax
f0103103:	39 b8 28 f0 22 f0    	cmp    %edi,-0xfdd0fd8(%eax)
f0103109:	75 29                	jne    f0103134 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010310b:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103110:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103115:	77 15                	ja     f010312c <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103117:	50                   	push   %eax
f0103118:	68 08 5e 10 f0       	push   $0xf0105e08
f010311d:	68 ac 01 00 00       	push   $0x1ac
f0103122:	68 b9 6f 10 f0       	push   $0xf0106fb9
f0103127:	e8 14 cf ff ff       	call   f0100040 <_panic>
f010312c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103131:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103134:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103137:	e8 df 25 00 00       	call   f010571b <cpunum>
f010313c:	6b c0 74             	imul   $0x74,%eax,%eax
f010313f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103144:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f010314b:	74 11                	je     f010315e <env_free+0x6f>
f010314d:	e8 c9 25 00 00       	call   f010571b <cpunum>
f0103152:	6b c0 74             	imul   $0x74,%eax,%eax
f0103155:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f010315b:	8b 50 48             	mov    0x48(%eax),%edx
f010315e:	83 ec 04             	sub    $0x4,%esp
f0103161:	53                   	push   %ebx
f0103162:	52                   	push   %edx
f0103163:	68 f3 6f 10 f0       	push   $0xf0106ff3
f0103168:	e8 40 04 00 00       	call   f01035ad <cprintf>
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
f01031a2:	39 05 88 ee 22 f0    	cmp    %eax,0xf022ee88
f01031a8:	77 15                	ja     f01031bf <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031aa:	56                   	push   %esi
f01031ab:	68 e4 5d 10 f0       	push   $0xf0105de4
f01031b0:	68 bb 01 00 00       	push   $0x1bb
f01031b5:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f0103209:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f010320f:	72 14                	jb     f0103225 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103211:	83 ec 04             	sub    $0x4,%esp
f0103214:	68 ec 63 10 f0       	push   $0xf01063ec
f0103219:	6a 51                	push   $0x51
f010321b:	68 55 6c 10 f0       	push   $0xf0106c55
f0103220:	e8 1b ce ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103225:	83 ec 0c             	sub    $0xc,%esp
f0103228:	a1 90 ee 22 f0       	mov    0xf022ee90,%eax
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
f0103259:	68 08 5e 10 f0       	push   $0xf0105e08
f010325e:	68 c9 01 00 00       	push   $0x1c9
f0103263:	68 b9 6f 10 f0       	push   $0xf0106fb9
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
f010327c:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f0103282:	72 14                	jb     f0103298 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103284:	83 ec 04             	sub    $0x4,%esp
f0103287:	68 ec 63 10 f0       	push   $0xf01063ec
f010328c:	6a 51                	push   $0x51
f010328e:	68 55 6c 10 f0       	push   $0xf0106c55
f0103293:	e8 a8 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103298:	83 ec 0c             	sub    $0xc,%esp
f010329b:	8b 15 90 ee 22 f0    	mov    0xf022ee90,%edx
f01032a1:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01032a4:	50                   	push   %eax
f01032a5:	e8 8f dc ff ff       	call   f0100f39 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01032aa:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01032b1:	a1 48 e2 22 f0       	mov    0xf022e248,%eax
f01032b6:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01032b9:	89 3d 48 e2 22 f0    	mov    %edi,0xf022e248
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
f01032da:	e8 3c 24 00 00       	call   f010571b <cpunum>
f01032df:	6b c0 74             	imul   $0x74,%eax,%eax
f01032e2:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f01032e8:	74 09                	je     f01032f3 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01032ea:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01032f1:	eb 33                	jmp    f0103326 <env_destroy+0x5c>
	}

	env_free(e);
f01032f3:	83 ec 0c             	sub    $0xc,%esp
f01032f6:	53                   	push   %ebx
f01032f7:	e8 f3 fd ff ff       	call   f01030ef <env_free>
	
	if (curenv == e) {
f01032fc:	e8 1a 24 00 00       	call   f010571b <cpunum>
f0103301:	6b c0 74             	imul   $0x74,%eax,%eax
f0103304:	83 c4 10             	add    $0x10,%esp
f0103307:	3b 98 28 f0 22 f0    	cmp    -0xfdd0fd8(%eax),%ebx
f010330d:	75 17                	jne    f0103326 <env_destroy+0x5c>
		//cprintf("free %08x\n",e->env_id);
		curenv = NULL;
f010330f:	e8 07 24 00 00       	call   f010571b <cpunum>
f0103314:	6b c0 74             	imul   $0x74,%eax,%eax
f0103317:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f010331e:	00 00 00 
		sched_yield();
f0103321:	e8 40 0d 00 00       	call   f0104066 <sched_yield>
	}
}
f0103326:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103329:	c9                   	leave  
f010332a:	c3                   	ret    

f010332b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010332b:	55                   	push   %ebp
f010332c:	89 e5                	mov    %esp,%ebp
f010332e:	53                   	push   %ebx
f010332f:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103332:	e8 e4 23 00 00       	call   f010571b <cpunum>
f0103337:	6b c0 74             	imul   $0x74,%eax,%eax
f010333a:	8b 98 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%ebx
f0103340:	e8 d6 23 00 00       	call   f010571b <cpunum>
f0103345:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103348:	8b 65 08             	mov    0x8(%ebp),%esp
f010334b:	61                   	popa   
f010334c:	07                   	pop    %es
f010334d:	1f                   	pop    %ds
f010334e:	83 c4 08             	add    $0x8,%esp
f0103351:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103352:	83 ec 04             	sub    $0x4,%esp
f0103355:	68 09 70 10 f0       	push   $0xf0107009
f010335a:	68 01 02 00 00       	push   $0x201
f010335f:	68 b9 6f 10 f0       	push   $0xf0106fb9
f0103364:	e8 d7 cc ff ff       	call   f0100040 <_panic>

f0103369 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103369:	55                   	push   %ebp
f010336a:	89 e5                	mov    %esp,%ebp
f010336c:	53                   	push   %ebx
f010336d:	83 ec 04             	sub    $0x4,%esp
f0103370:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0103373:	e8 a3 23 00 00       	call   f010571b <cpunum>
f0103378:	6b c0 74             	imul   $0x74,%eax,%eax
f010337b:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103382:	74 29                	je     f01033ad <env_run+0x44>
f0103384:	e8 92 23 00 00       	call   f010571b <cpunum>
f0103389:	6b c0 74             	imul   $0x74,%eax,%eax
f010338c:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103392:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103396:	75 15                	jne    f01033ad <env_run+0x44>
	{
		curenv->env_status=ENV_RUNNABLE;
f0103398:	e8 7e 23 00 00       	call   f010571b <cpunum>
f010339d:	6b c0 74             	imul   $0x74,%eax,%eax
f01033a0:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01033a6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv=e;
f01033ad:	e8 69 23 00 00       	call   f010571b <cpunum>
f01033b2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033b5:	89 98 28 f0 22 f0    	mov    %ebx,-0xfdd0fd8(%eax)
	curenv->env_status=ENV_RUNNING;
f01033bb:	e8 5b 23 00 00       	call   f010571b <cpunum>
f01033c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c3:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01033c9:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f01033d0:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	lcr3(PADDR(curenv->env_pgdir));
f01033d4:	e8 42 23 00 00       	call   f010571b <cpunum>
f01033d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033dc:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01033e2:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033ea:	77 15                	ja     f0103401 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033ec:	50                   	push   %eax
f01033ed:	68 08 5e 10 f0       	push   $0xf0105e08
f01033f2:	68 26 02 00 00       	push   $0x226
f01033f7:	68 b9 6f 10 f0       	push   $0xf0106fb9
f01033fc:	e8 3f cc ff ff       	call   f0100040 <_panic>
f0103401:	05 00 00 00 10       	add    $0x10000000,%eax
f0103406:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103409:	83 ec 0c             	sub    $0xc,%esp
f010340c:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103411:	e8 10 26 00 00       	call   f0105a26 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103416:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f0103418:	e8 fe 22 00 00       	call   f010571b <cpunum>
f010341d:	83 c4 04             	add    $0x4,%esp
f0103420:	6b c0 74             	imul   $0x74,%eax,%eax
f0103423:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103429:	e8 fd fe ff ff       	call   f010332b <env_pop_tf>

f010342e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010342e:	55                   	push   %ebp
f010342f:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103431:	ba 70 00 00 00       	mov    $0x70,%edx
f0103436:	8b 45 08             	mov    0x8(%ebp),%eax
f0103439:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010343a:	ba 71 00 00 00       	mov    $0x71,%edx
f010343f:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103440:	0f b6 c0             	movzbl %al,%eax
}
f0103443:	5d                   	pop    %ebp
f0103444:	c3                   	ret    

f0103445 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103445:	55                   	push   %ebp
f0103446:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103448:	ba 70 00 00 00       	mov    $0x70,%edx
f010344d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103450:	ee                   	out    %al,(%dx)
f0103451:	ba 71 00 00 00       	mov    $0x71,%edx
f0103456:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103459:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010345a:	5d                   	pop    %ebp
f010345b:	c3                   	ret    

f010345c <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010345c:	55                   	push   %ebp
f010345d:	89 e5                	mov    %esp,%ebp
f010345f:	56                   	push   %esi
f0103460:	53                   	push   %ebx
f0103461:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103464:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f010346a:	80 3d 4c e2 22 f0 00 	cmpb   $0x0,0xf022e24c
f0103471:	74 5a                	je     f01034cd <irq_setmask_8259A+0x71>
f0103473:	89 c6                	mov    %eax,%esi
f0103475:	ba 21 00 00 00       	mov    $0x21,%edx
f010347a:	ee                   	out    %al,(%dx)
f010347b:	66 c1 e8 08          	shr    $0x8,%ax
f010347f:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103484:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103485:	83 ec 0c             	sub    $0xc,%esp
f0103488:	68 15 70 10 f0       	push   $0xf0107015
f010348d:	e8 1b 01 00 00       	call   f01035ad <cprintf>
f0103492:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103495:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010349a:	0f b7 f6             	movzwl %si,%esi
f010349d:	f7 d6                	not    %esi
f010349f:	0f a3 de             	bt     %ebx,%esi
f01034a2:	73 11                	jae    f01034b5 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f01034a4:	83 ec 08             	sub    $0x8,%esp
f01034a7:	53                   	push   %ebx
f01034a8:	68 b3 74 10 f0       	push   $0xf01074b3
f01034ad:	e8 fb 00 00 00       	call   f01035ad <cprintf>
f01034b2:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01034b5:	83 c3 01             	add    $0x1,%ebx
f01034b8:	83 fb 10             	cmp    $0x10,%ebx
f01034bb:	75 e2                	jne    f010349f <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01034bd:	83 ec 0c             	sub    $0xc,%esp
f01034c0:	68 29 6f 10 f0       	push   $0xf0106f29
f01034c5:	e8 e3 00 00 00       	call   f01035ad <cprintf>
f01034ca:	83 c4 10             	add    $0x10,%esp
}
f01034cd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034d0:	5b                   	pop    %ebx
f01034d1:	5e                   	pop    %esi
f01034d2:	5d                   	pop    %ebp
f01034d3:	c3                   	ret    

f01034d4 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01034d4:	c6 05 4c e2 22 f0 01 	movb   $0x1,0xf022e24c
f01034db:	ba 21 00 00 00       	mov    $0x21,%edx
f01034e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01034e5:	ee                   	out    %al,(%dx)
f01034e6:	ba a1 00 00 00       	mov    $0xa1,%edx
f01034eb:	ee                   	out    %al,(%dx)
f01034ec:	ba 20 00 00 00       	mov    $0x20,%edx
f01034f1:	b8 11 00 00 00       	mov    $0x11,%eax
f01034f6:	ee                   	out    %al,(%dx)
f01034f7:	ba 21 00 00 00       	mov    $0x21,%edx
f01034fc:	b8 20 00 00 00       	mov    $0x20,%eax
f0103501:	ee                   	out    %al,(%dx)
f0103502:	b8 04 00 00 00       	mov    $0x4,%eax
f0103507:	ee                   	out    %al,(%dx)
f0103508:	b8 03 00 00 00       	mov    $0x3,%eax
f010350d:	ee                   	out    %al,(%dx)
f010350e:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103513:	b8 11 00 00 00       	mov    $0x11,%eax
f0103518:	ee                   	out    %al,(%dx)
f0103519:	ba a1 00 00 00       	mov    $0xa1,%edx
f010351e:	b8 28 00 00 00       	mov    $0x28,%eax
f0103523:	ee                   	out    %al,(%dx)
f0103524:	b8 02 00 00 00       	mov    $0x2,%eax
f0103529:	ee                   	out    %al,(%dx)
f010352a:	b8 01 00 00 00       	mov    $0x1,%eax
f010352f:	ee                   	out    %al,(%dx)
f0103530:	ba 20 00 00 00       	mov    $0x20,%edx
f0103535:	b8 68 00 00 00       	mov    $0x68,%eax
f010353a:	ee                   	out    %al,(%dx)
f010353b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103540:	ee                   	out    %al,(%dx)
f0103541:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103546:	b8 68 00 00 00       	mov    $0x68,%eax
f010354b:	ee                   	out    %al,(%dx)
f010354c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103551:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103552:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103559:	66 83 f8 ff          	cmp    $0xffff,%ax
f010355d:	74 13                	je     f0103572 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f010355f:	55                   	push   %ebp
f0103560:	89 e5                	mov    %esp,%ebp
f0103562:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103565:	0f b7 c0             	movzwl %ax,%eax
f0103568:	50                   	push   %eax
f0103569:	e8 ee fe ff ff       	call   f010345c <irq_setmask_8259A>
f010356e:	83 c4 10             	add    $0x10,%esp
}
f0103571:	c9                   	leave  
f0103572:	f3 c3                	repz ret 

f0103574 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103574:	55                   	push   %ebp
f0103575:	89 e5                	mov    %esp,%ebp
f0103577:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010357a:	ff 75 08             	pushl  0x8(%ebp)
f010357d:	e8 e2 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0103582:	83 c4 10             	add    $0x10,%esp
f0103585:	c9                   	leave  
f0103586:	c3                   	ret    

f0103587 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103587:	55                   	push   %ebp
f0103588:	89 e5                	mov    %esp,%ebp
f010358a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010358d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103594:	ff 75 0c             	pushl  0xc(%ebp)
f0103597:	ff 75 08             	pushl  0x8(%ebp)
f010359a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010359d:	50                   	push   %eax
f010359e:	68 74 35 10 f0       	push   $0xf0103574
f01035a3:	e8 18 14 00 00       	call   f01049c0 <vprintfmt>
	return cnt;
}
f01035a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035ab:	c9                   	leave  
f01035ac:	c3                   	ret    

f01035ad <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01035ad:	55                   	push   %ebp
f01035ae:	89 e5                	mov    %esp,%ebp
f01035b0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01035b3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01035b6:	50                   	push   %eax
f01035b7:	ff 75 08             	pushl  0x8(%ebp)
f01035ba:	e8 c8 ff ff ff       	call   f0103587 <vcprintf>
	va_end(ap);

	return cnt;
}
f01035bf:	c9                   	leave  
f01035c0:	c3                   	ret    

f01035c1 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01035c1:	55                   	push   %ebp
f01035c2:	89 e5                	mov    %esp,%ebp
f01035c4:	57                   	push   %edi
f01035c5:	56                   	push   %esi
f01035c6:	53                   	push   %ebx
f01035c7:	83 ec 0c             	sub    $0xc,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0=KSTACKTOP-cpunum()*(KSTKSIZE+KSTKGAP);
f01035ca:	e8 4c 21 00 00       	call   f010571b <cpunum>
f01035cf:	89 c3                	mov    %eax,%ebx
f01035d1:	e8 45 21 00 00       	call   f010571b <cpunum>
f01035d6:	6b db 74             	imul   $0x74,%ebx,%ebx
f01035d9:	c1 e0 10             	shl    $0x10,%eax
f01035dc:	89 c2                	mov    %eax,%edx
f01035de:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01035e3:	29 d0                	sub    %edx,%eax
f01035e5:	89 83 30 f0 22 f0    	mov    %eax,-0xfdd0fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0=GD_KD;
f01035eb:	e8 2b 21 00 00       	call   f010571b <cpunum>
f01035f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01035f3:	66 c7 80 34 f0 22 f0 	movw   $0x10,-0xfdd0fcc(%eax)
f01035fa:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f01035fc:	e8 1a 21 00 00       	call   f010571b <cpunum>
f0103601:	8d 58 05             	lea    0x5(%eax),%ebx
f0103604:	e8 12 21 00 00       	call   f010571b <cpunum>
f0103609:	89 c7                	mov    %eax,%edi
f010360b:	e8 0b 21 00 00       	call   f010571b <cpunum>
f0103610:	89 c6                	mov    %eax,%esi
f0103612:	e8 04 21 00 00       	call   f010571b <cpunum>
f0103617:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f010361e:	f0 67 00 
f0103621:	6b ff 74             	imul   $0x74,%edi,%edi
f0103624:	81 c7 2c f0 22 f0    	add    $0xf022f02c,%edi
f010362a:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103631:	f0 
f0103632:	6b d6 74             	imul   $0x74,%esi,%edx
f0103635:	81 c2 2c f0 22 f0    	add    $0xf022f02c,%edx
f010363b:	c1 ea 10             	shr    $0x10,%edx
f010363e:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103645:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f010364c:	99 
f010364d:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103654:	40 
f0103655:	6b c0 74             	imul   $0x74,%eax,%eax
f0103658:	05 2c f0 22 f0       	add    $0xf022f02c,%eax
f010365d:	c1 e8 18             	shr    $0x18,%eax
f0103660:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3)+cpunum()].sd_s = 0;
f0103667:	e8 af 20 00 00       	call   f010571b <cpunum>
f010366c:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f0103673:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0+sizeof(struct Segdesc)*cpunum());
f0103674:	e8 a2 20 00 00       	call   f010571b <cpunum>
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103679:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103680:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103683:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103688:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f010368b:	83 c4 0c             	add    $0xc,%esp
f010368e:	5b                   	pop    %ebx
f010368f:	5e                   	pop    %esi
f0103690:	5f                   	pop    %edi
f0103691:	5d                   	pop    %ebp
f0103692:	c3                   	ret    

f0103693 <trap_init>:
}


void
trap_init(void)
{
f0103693:	55                   	push   %ebp
f0103694:	89 e5                	mov    %esp,%ebp
f0103696:	83 ec 08             	sub    $0x8,%esp
	extern void floating_point_error();
	extern void alignment_check();
	extern void machine_check(); 
	extern void simd_floating_error();
	extern void system_call(); 
	SETGATE(idt[0],0,GD_KT,divide_error,0);
f0103699:	b8 1c 3f 10 f0       	mov    $0xf0103f1c,%eax
f010369e:	66 a3 60 e2 22 f0    	mov    %ax,0xf022e260
f01036a4:	66 c7 05 62 e2 22 f0 	movw   $0x8,0xf022e262
f01036ab:	08 00 
f01036ad:	c6 05 64 e2 22 f0 00 	movb   $0x0,0xf022e264
f01036b4:	c6 05 65 e2 22 f0 8e 	movb   $0x8e,0xf022e265
f01036bb:	c1 e8 10             	shr    $0x10,%eax
f01036be:	66 a3 66 e2 22 f0    	mov    %ax,0xf022e266
	SETGATE(idt[1],0,GD_KT,debuf_exception,0);
f01036c4:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f01036c9:	66 a3 68 e2 22 f0    	mov    %ax,0xf022e268
f01036cf:	66 c7 05 6a e2 22 f0 	movw   $0x8,0xf022e26a
f01036d6:	08 00 
f01036d8:	c6 05 6c e2 22 f0 00 	movb   $0x0,0xf022e26c
f01036df:	c6 05 6d e2 22 f0 8e 	movb   $0x8e,0xf022e26d
f01036e6:	c1 e8 10             	shr    $0x10,%eax
f01036e9:	66 a3 6e e2 22 f0    	mov    %ax,0xf022e26e
	SETGATE(idt[2],0,GD_KT,nmi_interrupt,0);
f01036ef:	b8 28 3f 10 f0       	mov    $0xf0103f28,%eax
f01036f4:	66 a3 70 e2 22 f0    	mov    %ax,0xf022e270
f01036fa:	66 c7 05 72 e2 22 f0 	movw   $0x8,0xf022e272
f0103701:	08 00 
f0103703:	c6 05 74 e2 22 f0 00 	movb   $0x0,0xf022e274
f010370a:	c6 05 75 e2 22 f0 8e 	movb   $0x8e,0xf022e275
f0103711:	c1 e8 10             	shr    $0x10,%eax
f0103714:	66 a3 76 e2 22 f0    	mov    %ax,0xf022e276
	SETGATE(idt[3],0,GD_KT,break_point,3);
f010371a:	b8 2e 3f 10 f0       	mov    $0xf0103f2e,%eax
f010371f:	66 a3 78 e2 22 f0    	mov    %ax,0xf022e278
f0103725:	66 c7 05 7a e2 22 f0 	movw   $0x8,0xf022e27a
f010372c:	08 00 
f010372e:	c6 05 7c e2 22 f0 00 	movb   $0x0,0xf022e27c
f0103735:	c6 05 7d e2 22 f0 ee 	movb   $0xee,0xf022e27d
f010373c:	c1 e8 10             	shr    $0x10,%eax
f010373f:	66 a3 7e e2 22 f0    	mov    %ax,0xf022e27e
	SETGATE(idt[4],0,GD_KT,overflow,0);
f0103745:	b8 34 3f 10 f0       	mov    $0xf0103f34,%eax
f010374a:	66 a3 80 e2 22 f0    	mov    %ax,0xf022e280
f0103750:	66 c7 05 82 e2 22 f0 	movw   $0x8,0xf022e282
f0103757:	08 00 
f0103759:	c6 05 84 e2 22 f0 00 	movb   $0x0,0xf022e284
f0103760:	c6 05 85 e2 22 f0 8e 	movb   $0x8e,0xf022e285
f0103767:	c1 e8 10             	shr    $0x10,%eax
f010376a:	66 a3 86 e2 22 f0    	mov    %ax,0xf022e286
	SETGATE(idt[5],0,GD_KT,bound_check,0);
f0103770:	b8 3a 3f 10 f0       	mov    $0xf0103f3a,%eax
f0103775:	66 a3 88 e2 22 f0    	mov    %ax,0xf022e288
f010377b:	66 c7 05 8a e2 22 f0 	movw   $0x8,0xf022e28a
f0103782:	08 00 
f0103784:	c6 05 8c e2 22 f0 00 	movb   $0x0,0xf022e28c
f010378b:	c6 05 8d e2 22 f0 8e 	movb   $0x8e,0xf022e28d
f0103792:	c1 e8 10             	shr    $0x10,%eax
f0103795:	66 a3 8e e2 22 f0    	mov    %ax,0xf022e28e
	SETGATE(idt[6],0,GD_KT,illegal_opcode,0);
f010379b:	b8 40 3f 10 f0       	mov    $0xf0103f40,%eax
f01037a0:	66 a3 90 e2 22 f0    	mov    %ax,0xf022e290
f01037a6:	66 c7 05 92 e2 22 f0 	movw   $0x8,0xf022e292
f01037ad:	08 00 
f01037af:	c6 05 94 e2 22 f0 00 	movb   $0x0,0xf022e294
f01037b6:	c6 05 95 e2 22 f0 8e 	movb   $0x8e,0xf022e295
f01037bd:	c1 e8 10             	shr    $0x10,%eax
f01037c0:	66 a3 96 e2 22 f0    	mov    %ax,0xf022e296
	SETGATE(idt[7],0,GD_KT,device_not_available,0);
f01037c6:	b8 46 3f 10 f0       	mov    $0xf0103f46,%eax
f01037cb:	66 a3 98 e2 22 f0    	mov    %ax,0xf022e298
f01037d1:	66 c7 05 9a e2 22 f0 	movw   $0x8,0xf022e29a
f01037d8:	08 00 
f01037da:	c6 05 9c e2 22 f0 00 	movb   $0x0,0xf022e29c
f01037e1:	c6 05 9d e2 22 f0 8e 	movb   $0x8e,0xf022e29d
f01037e8:	c1 e8 10             	shr    $0x10,%eax
f01037eb:	66 a3 9e e2 22 f0    	mov    %ax,0xf022e29e
	SETGATE(idt[8],0,GD_KT,segment_not_present,0);
f01037f1:	ba 54 3f 10 f0       	mov    $0xf0103f54,%edx
f01037f6:	66 89 15 a0 e2 22 f0 	mov    %dx,0xf022e2a0
f01037fd:	66 c7 05 a2 e2 22 f0 	movw   $0x8,0xf022e2a2
f0103804:	08 00 
f0103806:	c6 05 a4 e2 22 f0 00 	movb   $0x0,0xf022e2a4
f010380d:	c6 05 a5 e2 22 f0 8e 	movb   $0x8e,0xf022e2a5
f0103814:	89 d1                	mov    %edx,%ecx
f0103816:	c1 e9 10             	shr    $0x10,%ecx
f0103819:	66 89 0d a6 e2 22 f0 	mov    %cx,0xf022e2a6
	SETGATE(idt[10],0,GD_KT,invalid_tss,0);
f0103820:	b8 50 3f 10 f0       	mov    $0xf0103f50,%eax
f0103825:	66 a3 b0 e2 22 f0    	mov    %ax,0xf022e2b0
f010382b:	66 c7 05 b2 e2 22 f0 	movw   $0x8,0xf022e2b2
f0103832:	08 00 
f0103834:	c6 05 b4 e2 22 f0 00 	movb   $0x0,0xf022e2b4
f010383b:	c6 05 b5 e2 22 f0 8e 	movb   $0x8e,0xf022e2b5
f0103842:	c1 e8 10             	shr    $0x10,%eax
f0103845:	66 a3 b6 e2 22 f0    	mov    %ax,0xf022e2b6
	SETGATE(idt[11],0,GD_KT,segment_not_present,0);
f010384b:	66 89 15 b8 e2 22 f0 	mov    %dx,0xf022e2b8
f0103852:	66 c7 05 ba e2 22 f0 	movw   $0x8,0xf022e2ba
f0103859:	08 00 
f010385b:	c6 05 bc e2 22 f0 00 	movb   $0x0,0xf022e2bc
f0103862:	c6 05 bd e2 22 f0 8e 	movb   $0x8e,0xf022e2bd
f0103869:	66 89 0d be e2 22 f0 	mov    %cx,0xf022e2be
	SETGATE(idt[12],0,GD_KT,stack_exception,0);
f0103870:	b8 58 3f 10 f0       	mov    $0xf0103f58,%eax
f0103875:	66 a3 c0 e2 22 f0    	mov    %ax,0xf022e2c0
f010387b:	66 c7 05 c2 e2 22 f0 	movw   $0x8,0xf022e2c2
f0103882:	08 00 
f0103884:	c6 05 c4 e2 22 f0 00 	movb   $0x0,0xf022e2c4
f010388b:	c6 05 c5 e2 22 f0 8e 	movb   $0x8e,0xf022e2c5
f0103892:	c1 e8 10             	shr    $0x10,%eax
f0103895:	66 a3 c6 e2 22 f0    	mov    %ax,0xf022e2c6
	SETGATE(idt[13],0,GD_KT, general_protection_fault,0);
f010389b:	b8 5c 3f 10 f0       	mov    $0xf0103f5c,%eax
f01038a0:	66 a3 c8 e2 22 f0    	mov    %ax,0xf022e2c8
f01038a6:	66 c7 05 ca e2 22 f0 	movw   $0x8,0xf022e2ca
f01038ad:	08 00 
f01038af:	c6 05 cc e2 22 f0 00 	movb   $0x0,0xf022e2cc
f01038b6:	c6 05 cd e2 22 f0 8e 	movb   $0x8e,0xf022e2cd
f01038bd:	c1 e8 10             	shr    $0x10,%eax
f01038c0:	66 a3 ce e2 22 f0    	mov    %ax,0xf022e2ce
	SETGATE(idt[14],0,GD_KT,page_fault,0);
f01038c6:	b8 60 3f 10 f0       	mov    $0xf0103f60,%eax
f01038cb:	66 a3 d0 e2 22 f0    	mov    %ax,0xf022e2d0
f01038d1:	66 c7 05 d2 e2 22 f0 	movw   $0x8,0xf022e2d2
f01038d8:	08 00 
f01038da:	c6 05 d4 e2 22 f0 00 	movb   $0x0,0xf022e2d4
f01038e1:	c6 05 d5 e2 22 f0 8e 	movb   $0x8e,0xf022e2d5
f01038e8:	c1 e8 10             	shr    $0x10,%eax
f01038eb:	66 a3 d6 e2 22 f0    	mov    %ax,0xf022e2d6
	SETGATE(idt[16],0,GD_KT,floating_point_error,0);
f01038f1:	b8 64 3f 10 f0       	mov    $0xf0103f64,%eax
f01038f6:	66 a3 e0 e2 22 f0    	mov    %ax,0xf022e2e0
f01038fc:	66 c7 05 e2 e2 22 f0 	movw   $0x8,0xf022e2e2
f0103903:	08 00 
f0103905:	c6 05 e4 e2 22 f0 00 	movb   $0x0,0xf022e2e4
f010390c:	c6 05 e5 e2 22 f0 8e 	movb   $0x8e,0xf022e2e5
f0103913:	c1 e8 10             	shr    $0x10,%eax
f0103916:	66 a3 e6 e2 22 f0    	mov    %ax,0xf022e2e6
	SETGATE(idt[17],0,GD_KT,alignment_check,0);
f010391c:	b8 6a 3f 10 f0       	mov    $0xf0103f6a,%eax
f0103921:	66 a3 e8 e2 22 f0    	mov    %ax,0xf022e2e8
f0103927:	66 c7 05 ea e2 22 f0 	movw   $0x8,0xf022e2ea
f010392e:	08 00 
f0103930:	c6 05 ec e2 22 f0 00 	movb   $0x0,0xf022e2ec
f0103937:	c6 05 ed e2 22 f0 8e 	movb   $0x8e,0xf022e2ed
f010393e:	c1 e8 10             	shr    $0x10,%eax
f0103941:	66 a3 ee e2 22 f0    	mov    %ax,0xf022e2ee
	SETGATE(idt[18],0,GD_KT,machine_check,0);
f0103947:	b8 6e 3f 10 f0       	mov    $0xf0103f6e,%eax
f010394c:	66 a3 f0 e2 22 f0    	mov    %ax,0xf022e2f0
f0103952:	66 c7 05 f2 e2 22 f0 	movw   $0x8,0xf022e2f2
f0103959:	08 00 
f010395b:	c6 05 f4 e2 22 f0 00 	movb   $0x0,0xf022e2f4
f0103962:	c6 05 f5 e2 22 f0 8e 	movb   $0x8e,0xf022e2f5
f0103969:	c1 e8 10             	shr    $0x10,%eax
f010396c:	66 a3 f6 e2 22 f0    	mov    %ax,0xf022e2f6
	SETGATE(idt[19],0,GD_KT,simd_floating_error,0);
f0103972:	b8 74 3f 10 f0       	mov    $0xf0103f74,%eax
f0103977:	66 a3 f8 e2 22 f0    	mov    %ax,0xf022e2f8
f010397d:	66 c7 05 fa e2 22 f0 	movw   $0x8,0xf022e2fa
f0103984:	08 00 
f0103986:	c6 05 fc e2 22 f0 00 	movb   $0x0,0xf022e2fc
f010398d:	c6 05 fd e2 22 f0 8e 	movb   $0x8e,0xf022e2fd
f0103994:	c1 e8 10             	shr    $0x10,%eax
f0103997:	66 a3 fe e2 22 f0    	mov    %ax,0xf022e2fe
	SETGATE(idt[48],0,GD_KT,system_call,3);
f010399d:	b8 7a 3f 10 f0       	mov    $0xf0103f7a,%eax
f01039a2:	66 a3 e0 e3 22 f0    	mov    %ax,0xf022e3e0
f01039a8:	66 c7 05 e2 e3 22 f0 	movw   $0x8,0xf022e3e2
f01039af:	08 00 
f01039b1:	c6 05 e4 e3 22 f0 00 	movb   $0x0,0xf022e3e4
f01039b8:	c6 05 e5 e3 22 f0 ee 	movb   $0xee,0xf022e3e5
f01039bf:	c1 e8 10             	shr    $0x10,%eax
f01039c2:	66 a3 e6 e3 22 f0    	mov    %ax,0xf022e3e6
	// Per-CPU setup 
	trap_init_percpu();
f01039c8:	e8 f4 fb ff ff       	call   f01035c1 <trap_init_percpu>
}
f01039cd:	c9                   	leave  
f01039ce:	c3                   	ret    

f01039cf <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039cf:	55                   	push   %ebp
f01039d0:	89 e5                	mov    %esp,%ebp
f01039d2:	53                   	push   %ebx
f01039d3:	83 ec 0c             	sub    $0xc,%esp
f01039d6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039d9:	ff 33                	pushl  (%ebx)
f01039db:	68 29 70 10 f0       	push   $0xf0107029
f01039e0:	e8 c8 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039e5:	83 c4 08             	add    $0x8,%esp
f01039e8:	ff 73 04             	pushl  0x4(%ebx)
f01039eb:	68 38 70 10 f0       	push   $0xf0107038
f01039f0:	e8 b8 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039f5:	83 c4 08             	add    $0x8,%esp
f01039f8:	ff 73 08             	pushl  0x8(%ebx)
f01039fb:	68 47 70 10 f0       	push   $0xf0107047
f0103a00:	e8 a8 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a05:	83 c4 08             	add    $0x8,%esp
f0103a08:	ff 73 0c             	pushl  0xc(%ebx)
f0103a0b:	68 56 70 10 f0       	push   $0xf0107056
f0103a10:	e8 98 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a15:	83 c4 08             	add    $0x8,%esp
f0103a18:	ff 73 10             	pushl  0x10(%ebx)
f0103a1b:	68 65 70 10 f0       	push   $0xf0107065
f0103a20:	e8 88 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a25:	83 c4 08             	add    $0x8,%esp
f0103a28:	ff 73 14             	pushl  0x14(%ebx)
f0103a2b:	68 74 70 10 f0       	push   $0xf0107074
f0103a30:	e8 78 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a35:	83 c4 08             	add    $0x8,%esp
f0103a38:	ff 73 18             	pushl  0x18(%ebx)
f0103a3b:	68 83 70 10 f0       	push   $0xf0107083
f0103a40:	e8 68 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a45:	83 c4 08             	add    $0x8,%esp
f0103a48:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a4b:	68 92 70 10 f0       	push   $0xf0107092
f0103a50:	e8 58 fb ff ff       	call   f01035ad <cprintf>
}
f0103a55:	83 c4 10             	add    $0x10,%esp
f0103a58:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a5b:	c9                   	leave  
f0103a5c:	c3                   	ret    

f0103a5d <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103a5d:	55                   	push   %ebp
f0103a5e:	89 e5                	mov    %esp,%ebp
f0103a60:	56                   	push   %esi
f0103a61:	53                   	push   %ebx
f0103a62:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a65:	e8 b1 1c 00 00       	call   f010571b <cpunum>
f0103a6a:	83 ec 04             	sub    $0x4,%esp
f0103a6d:	50                   	push   %eax
f0103a6e:	53                   	push   %ebx
f0103a6f:	68 f6 70 10 f0       	push   $0xf01070f6
f0103a74:	e8 34 fb ff ff       	call   f01035ad <cprintf>
	print_regs(&tf->tf_regs);
f0103a79:	89 1c 24             	mov    %ebx,(%esp)
f0103a7c:	e8 4e ff ff ff       	call   f01039cf <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a81:	83 c4 08             	add    $0x8,%esp
f0103a84:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a88:	50                   	push   %eax
f0103a89:	68 14 71 10 f0       	push   $0xf0107114
f0103a8e:	e8 1a fb ff ff       	call   f01035ad <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a93:	83 c4 08             	add    $0x8,%esp
f0103a96:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a9a:	50                   	push   %eax
f0103a9b:	68 27 71 10 f0       	push   $0xf0107127
f0103aa0:	e8 08 fb ff ff       	call   f01035ad <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103aa5:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103aa8:	83 c4 10             	add    $0x10,%esp
f0103aab:	83 f8 13             	cmp    $0x13,%eax
f0103aae:	77 09                	ja     f0103ab9 <print_trapframe+0x5c>
		return excnames[trapno];
f0103ab0:	8b 14 85 a0 73 10 f0 	mov    -0xfef8c60(,%eax,4),%edx
f0103ab7:	eb 1f                	jmp    f0103ad8 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103ab9:	83 f8 30             	cmp    $0x30,%eax
f0103abc:	74 15                	je     f0103ad3 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103abe:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103ac1:	83 fa 10             	cmp    $0x10,%edx
f0103ac4:	b9 c0 70 10 f0       	mov    $0xf01070c0,%ecx
f0103ac9:	ba ad 70 10 f0       	mov    $0xf01070ad,%edx
f0103ace:	0f 43 d1             	cmovae %ecx,%edx
f0103ad1:	eb 05                	jmp    f0103ad8 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103ad3:	ba a1 70 10 f0       	mov    $0xf01070a1,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103ad8:	83 ec 04             	sub    $0x4,%esp
f0103adb:	52                   	push   %edx
f0103adc:	50                   	push   %eax
f0103add:	68 3a 71 10 f0       	push   $0xf010713a
f0103ae2:	e8 c6 fa ff ff       	call   f01035ad <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ae7:	83 c4 10             	add    $0x10,%esp
f0103aea:	3b 1d 60 ea 22 f0    	cmp    0xf022ea60,%ebx
f0103af0:	75 1a                	jne    f0103b0c <print_trapframe+0xaf>
f0103af2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103af6:	75 14                	jne    f0103b0c <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103af8:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103afb:	83 ec 08             	sub    $0x8,%esp
f0103afe:	50                   	push   %eax
f0103aff:	68 4c 71 10 f0       	push   $0xf010714c
f0103b04:	e8 a4 fa ff ff       	call   f01035ad <cprintf>
f0103b09:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b0c:	83 ec 08             	sub    $0x8,%esp
f0103b0f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b12:	68 5b 71 10 f0       	push   $0xf010715b
f0103b17:	e8 91 fa ff ff       	call   f01035ad <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b1c:	83 c4 10             	add    $0x10,%esp
f0103b1f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b23:	75 49                	jne    f0103b6e <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b25:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b28:	89 c2                	mov    %eax,%edx
f0103b2a:	83 e2 01             	and    $0x1,%edx
f0103b2d:	ba da 70 10 f0       	mov    $0xf01070da,%edx
f0103b32:	b9 cf 70 10 f0       	mov    $0xf01070cf,%ecx
f0103b37:	0f 44 ca             	cmove  %edx,%ecx
f0103b3a:	89 c2                	mov    %eax,%edx
f0103b3c:	83 e2 02             	and    $0x2,%edx
f0103b3f:	ba ec 70 10 f0       	mov    $0xf01070ec,%edx
f0103b44:	be e6 70 10 f0       	mov    $0xf01070e6,%esi
f0103b49:	0f 45 d6             	cmovne %esi,%edx
f0103b4c:	83 e0 04             	and    $0x4,%eax
f0103b4f:	be 2e 72 10 f0       	mov    $0xf010722e,%esi
f0103b54:	b8 f1 70 10 f0       	mov    $0xf01070f1,%eax
f0103b59:	0f 44 c6             	cmove  %esi,%eax
f0103b5c:	51                   	push   %ecx
f0103b5d:	52                   	push   %edx
f0103b5e:	50                   	push   %eax
f0103b5f:	68 69 71 10 f0       	push   $0xf0107169
f0103b64:	e8 44 fa ff ff       	call   f01035ad <cprintf>
f0103b69:	83 c4 10             	add    $0x10,%esp
f0103b6c:	eb 10                	jmp    f0103b7e <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b6e:	83 ec 0c             	sub    $0xc,%esp
f0103b71:	68 29 6f 10 f0       	push   $0xf0106f29
f0103b76:	e8 32 fa ff ff       	call   f01035ad <cprintf>
f0103b7b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b7e:	83 ec 08             	sub    $0x8,%esp
f0103b81:	ff 73 30             	pushl  0x30(%ebx)
f0103b84:	68 78 71 10 f0       	push   $0xf0107178
f0103b89:	e8 1f fa ff ff       	call   f01035ad <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b8e:	83 c4 08             	add    $0x8,%esp
f0103b91:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b95:	50                   	push   %eax
f0103b96:	68 87 71 10 f0       	push   $0xf0107187
f0103b9b:	e8 0d fa ff ff       	call   f01035ad <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103ba0:	83 c4 08             	add    $0x8,%esp
f0103ba3:	ff 73 38             	pushl  0x38(%ebx)
f0103ba6:	68 9a 71 10 f0       	push   $0xf010719a
f0103bab:	e8 fd f9 ff ff       	call   f01035ad <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bb0:	83 c4 10             	add    $0x10,%esp
f0103bb3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103bb7:	74 25                	je     f0103bde <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103bb9:	83 ec 08             	sub    $0x8,%esp
f0103bbc:	ff 73 3c             	pushl  0x3c(%ebx)
f0103bbf:	68 a9 71 10 f0       	push   $0xf01071a9
f0103bc4:	e8 e4 f9 ff ff       	call   f01035ad <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103bc9:	83 c4 08             	add    $0x8,%esp
f0103bcc:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103bd0:	50                   	push   %eax
f0103bd1:	68 b8 71 10 f0       	push   $0xf01071b8
f0103bd6:	e8 d2 f9 ff ff       	call   f01035ad <cprintf>
f0103bdb:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bde:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103be1:	5b                   	pop    %ebx
f0103be2:	5e                   	pop    %esi
f0103be3:	5d                   	pop    %ebp
f0103be4:	c3                   	ret    

f0103be5 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103be5:	55                   	push   %ebp
f0103be6:	89 e5                	mov    %esp,%ebp
f0103be8:	57                   	push   %edi
f0103be9:	56                   	push   %esi
f0103bea:	53                   	push   %ebx
f0103beb:	83 ec 0c             	sub    $0xc,%esp
f0103bee:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103bf1:	0f 20 d6             	mov    %cr2,%esi
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if(curenv->env_pgfault_upcall!=NULL)
f0103bf4:	e8 22 1b 00 00       	call   f010571b <cpunum>
f0103bf9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bfc:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103c02:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103c06:	0f 84 c9 00 00 00    	je     f0103cd5 <page_fault_handler+0xf0>
	{
		struct UTrapframe *utf;
		if(UXSTACKTOP-PGSIZE<=tf->tf_esp&&tf->tf_esp<=UXSTACKTOP-1)
f0103c0c:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c0f:	05 00 10 40 11       	add    $0x11401000,%eax
f0103c14:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0103c19:	77 1a                	ja     f0103c35 <page_fault_handler+0x50>
		{
			cprintf("-4\n");
f0103c1b:	83 ec 0c             	sub    $0xc,%esp
f0103c1e:	68 cb 71 10 f0       	push   $0xf01071cb
f0103c23:	e8 85 f9 ff ff       	call   f01035ad <cprintf>
			utf=(struct UTrapframe *)(tf->tf_esp-sizeof(struct UTrapframe)-4);
f0103c28:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c2b:	83 e8 38             	sub    $0x38,%eax
f0103c2e:	89 c7                	mov    %eax,%edi
f0103c30:	83 c4 10             	add    $0x10,%esp
f0103c33:	eb 15                	jmp    f0103c4a <page_fault_handler+0x65>
		}
		else
		{	
			cprintf("-0\n");
f0103c35:	83 ec 0c             	sub    $0xc,%esp
f0103c38:	68 cf 71 10 f0       	push   $0xf01071cf
f0103c3d:	e8 6b f9 ff ff       	call   f01035ad <cprintf>
f0103c42:	83 c4 10             	add    $0x10,%esp
			utf=(struct UTrapframe *)(UXSTACKTOP-sizeof(struct UTrapframe));
f0103c45:	bf cc ff bf ee       	mov    $0xeebfffcc,%edi
		}
		user_mem_assert (curenv, (void *)utf,sizeof(struct UTrapframe),(PTE_U|PTE_W));
f0103c4a:	e8 cc 1a 00 00       	call   f010571b <cpunum>
f0103c4f:	6a 06                	push   $0x6
f0103c51:	6a 34                	push   $0x34
f0103c53:	57                   	push   %edi
f0103c54:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c57:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103c5d:	e8 0e f0 ff ff       	call   f0102c70 <user_mem_assert>
		utf->utf_fault_va=fault_va;
f0103c62:	89 37                	mov    %esi,(%edi)
		utf->utf_err=tf->tf_trapno;
f0103c64:	8b 43 28             	mov    0x28(%ebx),%eax
f0103c67:	89 fa                	mov    %edi,%edx
f0103c69:	89 47 04             	mov    %eax,0x4(%edi)
		utf->utf_regs=tf->tf_regs;
f0103c6c:	8d 7f 08             	lea    0x8(%edi),%edi
f0103c6f:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103c74:	89 de                	mov    %ebx,%esi
f0103c76:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		utf->utf_eip=tf->tf_eip;
f0103c78:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c7b:	89 42 28             	mov    %eax,0x28(%edx)
		utf->utf_eflags=tf->tf_eflags;
f0103c7e:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c81:	89 d7                	mov    %edx,%edi
f0103c83:	89 42 2c             	mov    %eax,0x2c(%edx)
		utf->utf_esp=tf->tf_esp;
f0103c86:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c89:	89 42 30             	mov    %eax,0x30(%edx)
		curenv->env_tf.tf_eip=(uint32_t )curenv->env_pgfault_upcall;
f0103c8c:	e8 8a 1a 00 00       	call   f010571b <cpunum>
f0103c91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c94:	8b 98 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%ebx
f0103c9a:	e8 7c 1a 00 00       	call   f010571b <cpunum>
f0103c9f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ca2:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103ca8:	8b 40 64             	mov    0x64(%eax),%eax
f0103cab:	89 43 30             	mov    %eax,0x30(%ebx)
		curenv->env_tf.tf_esp=(uint32_t)utf;
f0103cae:	e8 68 1a 00 00       	call   f010571b <cpunum>
f0103cb3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb6:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103cbc:	89 78 3c             	mov    %edi,0x3c(%eax)
		env_run(curenv);
f0103cbf:	e8 57 1a 00 00       	call   f010571b <cpunum>
f0103cc4:	83 c4 04             	add    $0x4,%esp
f0103cc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cca:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103cd0:	e8 94 f6 ff ff       	call   f0103369 <env_run>
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cd5:	8b 7b 30             	mov    0x30(%ebx),%edi
			curenv->env_id, fault_va, tf->tf_eip);
f0103cd8:	e8 3e 1a 00 00       	call   f010571b <cpunum>
		curenv->env_tf.tf_esp=(uint32_t)utf;
		env_run(curenv);
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cdd:	57                   	push   %edi
f0103cde:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103cdf:	6b c0 74             	imul   $0x74,%eax,%eax
		curenv->env_tf.tf_esp=(uint32_t)utf;
		env_run(curenv);
	}
	// Destroy the environment that caused the fault.
	
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ce2:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103ce8:	ff 70 48             	pushl  0x48(%eax)
f0103ceb:	68 78 73 10 f0       	push   $0xf0107378
f0103cf0:	e8 b8 f8 ff ff       	call   f01035ad <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103cf5:	89 1c 24             	mov    %ebx,(%esp)
f0103cf8:	e8 60 fd ff ff       	call   f0103a5d <print_trapframe>
		env_destroy(curenv);
f0103cfd:	e8 19 1a 00 00       	call   f010571b <cpunum>
f0103d02:	83 c4 04             	add    $0x4,%esp
f0103d05:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d08:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103d0e:	e8 b7 f5 ff ff       	call   f01032ca <env_destroy>

}
f0103d13:	83 c4 10             	add    $0x10,%esp
f0103d16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d19:	5b                   	pop    %ebx
f0103d1a:	5e                   	pop    %esi
f0103d1b:	5f                   	pop    %edi
f0103d1c:	5d                   	pop    %ebp
f0103d1d:	c3                   	ret    

f0103d1e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d1e:	55                   	push   %ebp
f0103d1f:	89 e5                	mov    %esp,%ebp
f0103d21:	57                   	push   %edi
f0103d22:	56                   	push   %esi
f0103d23:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d26:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d27:	83 3d 80 ee 22 f0 00 	cmpl   $0x0,0xf022ee80
f0103d2e:	74 01                	je     f0103d31 <trap+0x13>
		asm volatile("hlt");
f0103d30:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d31:	e8 e5 19 00 00       	call   f010571b <cpunum>
f0103d36:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d39:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0103d3f:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d44:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d48:	83 f8 02             	cmp    $0x2,%eax
f0103d4b:	75 10                	jne    f0103d5d <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d4d:	83 ec 0c             	sub    $0xc,%esp
f0103d50:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d55:	e8 2f 1c 00 00       	call   f0105989 <spin_lock>
f0103d5a:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103d5d:	9c                   	pushf  
f0103d5e:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d5f:	f6 c4 02             	test   $0x2,%ah
f0103d62:	74 19                	je     f0103d7d <trap+0x5f>
f0103d64:	68 d3 71 10 f0       	push   $0xf01071d3
f0103d69:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0103d6e:	68 11 01 00 00       	push   $0x111
f0103d73:	68 ec 71 10 f0       	push   $0xf01071ec
f0103d78:	e8 c3 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d7d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d81:	83 e0 03             	and    $0x3,%eax
f0103d84:	66 83 f8 03          	cmp    $0x3,%ax
f0103d88:	0f 85 a0 00 00 00    	jne    f0103e2e <trap+0x110>
f0103d8e:	83 ec 0c             	sub    $0xc,%esp
f0103d91:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d96:	e8 ee 1b 00 00       	call   f0105989 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock be  fore doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103d9b:	e8 7b 19 00 00       	call   f010571b <cpunum>
f0103da0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da3:	83 c4 10             	add    $0x10,%esp
f0103da6:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103dad:	75 19                	jne    f0103dc8 <trap+0xaa>
f0103daf:	68 f8 71 10 f0       	push   $0xf01071f8
f0103db4:	68 6f 6c 10 f0       	push   $0xf0106c6f
f0103db9:	68 19 01 00 00       	push   $0x119
f0103dbe:	68 ec 71 10 f0       	push   $0xf01071ec
f0103dc3:	e8 78 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103dc8:	e8 4e 19 00 00       	call   f010571b <cpunum>
f0103dcd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd0:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103dd6:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103dda:	75 2d                	jne    f0103e09 <trap+0xeb>
			env_free(curenv);
f0103ddc:	e8 3a 19 00 00       	call   f010571b <cpunum>
f0103de1:	83 ec 0c             	sub    $0xc,%esp
f0103de4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de7:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103ded:	e8 fd f2 ff ff       	call   f01030ef <env_free>
			curenv = NULL;
f0103df2:	e8 24 19 00 00       	call   f010571b <cpunum>
f0103df7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfa:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f0103e01:	00 00 00 
			sched_yield();
f0103e04:	e8 5d 02 00 00       	call   f0104066 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103e09:	e8 0d 19 00 00       	call   f010571b <cpunum>
f0103e0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e11:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103e17:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e1c:	89 c7                	mov    %eax,%edi
f0103e1e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e20:	e8 f6 18 00 00       	call   f010571b <cpunum>
f0103e25:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e28:	8b b0 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e2e:	89 35 60 ea 22 f0    	mov    %esi,0xf022ea60
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e34:	8b 46 28             	mov    0x28(%esi),%eax
f0103e37:	83 f8 27             	cmp    $0x27,%eax
f0103e3a:	75 1d                	jne    f0103e59 <trap+0x13b>
		cprintf("Spurious interrupt on irq 7\n");
f0103e3c:	83 ec 0c             	sub    $0xc,%esp
f0103e3f:	68 ff 71 10 f0       	push   $0xf01071ff
f0103e44:	e8 64 f7 ff ff       	call   f01035ad <cprintf>
		print_trapframe(tf);
f0103e49:	89 34 24             	mov    %esi,(%esp)
f0103e4c:	e8 0c fc ff ff       	call   f0103a5d <print_trapframe>
f0103e51:	83 c4 10             	add    $0x10,%esp
f0103e54:	e9 83 00 00 00       	jmp    f0103edc <trap+0x1be>
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	//print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
f0103e59:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e5e:	75 17                	jne    f0103e77 <trap+0x159>
		panic("unhandled trap in kernel");
f0103e60:	83 ec 04             	sub    $0x4,%esp
f0103e63:	68 1c 72 10 f0       	push   $0xf010721c
f0103e68:	68 e6 00 00 00       	push   $0xe6
f0103e6d:	68 ec 71 10 f0       	push   $0xf01071ec
f0103e72:	e8 c9 c1 ff ff       	call   f0100040 <_panic>
	else {
		//cprintf("asdas\n");
		if(tf->tf_trapno ==T_PGFLT)
f0103e77:	83 f8 0e             	cmp    $0xe,%eax
f0103e7a:	75 0e                	jne    f0103e8a <trap+0x16c>
		{
			page_fault_handler(tf);
f0103e7c:	83 ec 0c             	sub    $0xc,%esp
f0103e7f:	56                   	push   %esi
f0103e80:	e8 60 fd ff ff       	call   f0103be5 <page_fault_handler>
f0103e85:	83 c4 10             	add    $0x10,%esp
f0103e88:	eb 52                	jmp    f0103edc <trap+0x1be>
		}
		else if(tf->tf_trapno==T_BRKPT)
f0103e8a:	83 f8 03             	cmp    $0x3,%eax
f0103e8d:	75 0e                	jne    f0103e9d <trap+0x17f>
		{
			monitor(tf);
f0103e8f:	83 ec 0c             	sub    $0xc,%esp
f0103e92:	56                   	push   %esi
f0103e93:	e8 e9 c9 ff ff       	call   f0100881 <monitor>
f0103e98:	83 c4 10             	add    $0x10,%esp
f0103e9b:	eb 3f                	jmp    f0103edc <trap+0x1be>
		}
		else if(tf->tf_trapno==T_SYSCALL)
f0103e9d:	83 f8 30             	cmp    $0x30,%eax
f0103ea0:	75 21                	jne    f0103ec3 <trap+0x1a5>
		{
			tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103ea2:	83 ec 08             	sub    $0x8,%esp
f0103ea5:	ff 76 04             	pushl  0x4(%esi)
f0103ea8:	ff 36                	pushl  (%esi)
f0103eaa:	ff 76 10             	pushl  0x10(%esi)
f0103ead:	ff 76 18             	pushl  0x18(%esi)
f0103eb0:	ff 76 14             	pushl  0x14(%esi)
f0103eb3:	ff 76 1c             	pushl  0x1c(%esi)
f0103eb6:	e8 19 02 00 00       	call   f01040d4 <syscall>
f0103ebb:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103ebe:	83 c4 20             	add    $0x20,%esp
f0103ec1:	eb 19                	jmp    f0103edc <trap+0x1be>
		}
		else
		{
		
			env_destroy(curenv);
f0103ec3:	e8 53 18 00 00       	call   f010571b <cpunum>
f0103ec8:	83 ec 0c             	sub    $0xc,%esp
f0103ecb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ece:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103ed4:	e8 f1 f3 ff ff       	call   f01032ca <env_destroy>
f0103ed9:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103edc:	e8 3a 18 00 00       	call   f010571b <cpunum>
f0103ee1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee4:	83 b8 28 f0 22 f0 00 	cmpl   $0x0,-0xfdd0fd8(%eax)
f0103eeb:	74 2a                	je     f0103f17 <trap+0x1f9>
f0103eed:	e8 29 18 00 00       	call   f010571b <cpunum>
f0103ef2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef5:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0103efb:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103eff:	75 16                	jne    f0103f17 <trap+0x1f9>
	{
		env_run(curenv);
f0103f01:	e8 15 18 00 00       	call   f010571b <cpunum>
f0103f06:	83 ec 0c             	sub    $0xc,%esp
f0103f09:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0c:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0103f12:	e8 52 f4 ff ff       	call   f0103369 <env_run>
	}
	else
	{
		sched_yield();
f0103f17:	e8 4a 01 00 00       	call   f0104066 <sched_yield>

f0103f1c <divide_error>:
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
TRAPHANDLER_NOEC(divide_error,T_DIVIDE)
f0103f1c:	6a 00                	push   $0x0
f0103f1e:	6a 00                	push   $0x0
f0103f20:	eb 5e                	jmp    f0103f80 <_alltraps>

f0103f22 <debuf_exception>:
TRAPHANDLER_NOEC(debuf_exception,T_DEBUG)
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 01                	push   $0x1
f0103f26:	eb 58                	jmp    f0103f80 <_alltraps>

f0103f28 <nmi_interrupt>:
TRAPHANDLER_NOEC(nmi_interrupt,T_NMI)
f0103f28:	6a 00                	push   $0x0
f0103f2a:	6a 02                	push   $0x2
f0103f2c:	eb 52                	jmp    f0103f80 <_alltraps>

f0103f2e <break_point>:
TRAPHANDLER_NOEC(break_point,T_BRKPT)
f0103f2e:	6a 00                	push   $0x0
f0103f30:	6a 03                	push   $0x3
f0103f32:	eb 4c                	jmp    f0103f80 <_alltraps>

f0103f34 <overflow>:
TRAPHANDLER_NOEC(overflow,T_OFLOW)
f0103f34:	6a 00                	push   $0x0
f0103f36:	6a 04                	push   $0x4
f0103f38:	eb 46                	jmp    f0103f80 <_alltraps>

f0103f3a <bound_check>:
TRAPHANDLER_NOEC(bound_check,T_BOUND);
f0103f3a:	6a 00                	push   $0x0
f0103f3c:	6a 05                	push   $0x5
f0103f3e:	eb 40                	jmp    f0103f80 <_alltraps>

f0103f40 <illegal_opcode>:
TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)
f0103f40:	6a 00                	push   $0x0
f0103f42:	6a 06                	push   $0x6
f0103f44:	eb 3a                	jmp    f0103f80 <_alltraps>

f0103f46 <device_not_available>:
TRAPHANDLER_NOEC(device_not_available,T_DEVICE)
f0103f46:	6a 00                	push   $0x0
f0103f48:	6a 07                	push   $0x7
f0103f4a:	eb 34                	jmp    f0103f80 <_alltraps>

f0103f4c <double_fault>:
TRAPHANDLER(double_fault,T_DBLFLT)
f0103f4c:	6a 08                	push   $0x8
f0103f4e:	eb 30                	jmp    f0103f80 <_alltraps>

f0103f50 <invalid_tss>:
TRAPHANDLER(invalid_tss,T_TSS)
f0103f50:	6a 0a                	push   $0xa
f0103f52:	eb 2c                	jmp    f0103f80 <_alltraps>

f0103f54 <segment_not_present>:
TRAPHANDLER(segment_not_present,T_SEGNP)
f0103f54:	6a 0b                	push   $0xb
f0103f56:	eb 28                	jmp    f0103f80 <_alltraps>

f0103f58 <stack_exception>:
TRAPHANDLER(stack_exception,T_STACK)
f0103f58:	6a 0c                	push   $0xc
f0103f5a:	eb 24                	jmp    f0103f80 <_alltraps>

f0103f5c <general_protection_fault>:
TRAPHANDLER(general_protection_fault,T_GPFLT)
f0103f5c:	6a 0d                	push   $0xd
f0103f5e:	eb 20                	jmp    f0103f80 <_alltraps>

f0103f60 <page_fault>:
TRAPHANDLER(page_fault,T_PGFLT)
f0103f60:	6a 0e                	push   $0xe
f0103f62:	eb 1c                	jmp    f0103f80 <_alltraps>

f0103f64 <floating_point_error>:
TRAPHANDLER_NOEC(floating_point_error,T_FPERR)
f0103f64:	6a 00                	push   $0x0
f0103f66:	6a 10                	push   $0x10
f0103f68:	eb 16                	jmp    f0103f80 <_alltraps>

f0103f6a <alignment_check>:
TRAPHANDLER(alignment_check,T_ALIGN)
f0103f6a:	6a 11                	push   $0x11
f0103f6c:	eb 12                	jmp    f0103f80 <_alltraps>

f0103f6e <machine_check>:
TRAPHANDLER_NOEC(machine_check,T_MCHK)
f0103f6e:	6a 00                	push   $0x0
f0103f70:	6a 12                	push   $0x12
f0103f72:	eb 0c                	jmp    f0103f80 <_alltraps>

f0103f74 <simd_floating_error>:
TRAPHANDLER_NOEC(simd_floating_error,T_SIMDERR)
f0103f74:	6a 00                	push   $0x0
f0103f76:	6a 13                	push   $0x13
f0103f78:	eb 06                	jmp    f0103f80 <_alltraps>

f0103f7a <system_call>:
TRAPHANDLER_NOEC(system_call,T_SYSCALL)
f0103f7a:	6a 00                	push   $0x0
f0103f7c:	6a 30                	push   $0x30
f0103f7e:	eb 00                	jmp    f0103f80 <_alltraps>

f0103f80 <_alltraps>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
_alltraps:
pushl %ds
f0103f80:	1e                   	push   %ds
pushl %es
f0103f81:	06                   	push   %es
pushal
f0103f82:	60                   	pusha  
movl $GD_KD,%eax
f0103f83:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax,%ds
f0103f88:	8e d8                	mov    %eax,%ds
movw %ax,%es
f0103f8a:	8e c0                	mov    %eax,%es
pushl %esp
f0103f8c:	54                   	push   %esp
call trap
f0103f8d:	e8 8c fd ff ff       	call   f0103d1e <trap>

f0103f92 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f92:	55                   	push   %ebp
f0103f93:	89 e5                	mov    %esp,%ebp
f0103f95:	83 ec 08             	sub    $0x8,%esp
f0103f98:	a1 44 e2 22 f0       	mov    0xf022e244,%eax
f0103f9d:	8d 50 54             	lea    0x54(%eax),%edx
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fa0:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103fa5:	8b 02                	mov    (%edx),%eax
f0103fa7:	83 e8 01             	sub    $0x1,%eax
f0103faa:	83 f8 02             	cmp    $0x2,%eax
f0103fad:	76 10                	jbe    f0103fbf <sched_halt+0x2d>
sched_halt(void)
{
	int i; 
	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103faf:	83 c1 01             	add    $0x1,%ecx
f0103fb2:	83 c2 7c             	add    $0x7c,%edx
f0103fb5:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fbb:	75 e8                	jne    f0103fa5 <sched_halt+0x13>
f0103fbd:	eb 08                	jmp    f0103fc7 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fbf:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fc5:	75 1f                	jne    f0103fe6 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fc7:	83 ec 0c             	sub    $0xc,%esp
f0103fca:	68 f0 73 10 f0       	push   $0xf01073f0
f0103fcf:	e8 d9 f5 ff ff       	call   f01035ad <cprintf>
f0103fd4:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103fd7:	83 ec 0c             	sub    $0xc,%esp
f0103fda:	6a 00                	push   $0x0
f0103fdc:	e8 a0 c8 ff ff       	call   f0100881 <monitor>
f0103fe1:	83 c4 10             	add    $0x10,%esp
f0103fe4:	eb f1                	jmp    f0103fd7 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103fe6:	e8 30 17 00 00       	call   f010571b <cpunum>
f0103feb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fee:	c7 80 28 f0 22 f0 00 	movl   $0x0,-0xfdd0fd8(%eax)
f0103ff5:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103ff8:	a1 8c ee 22 f0       	mov    0xf022ee8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ffd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104002:	77 12                	ja     f0104016 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104004:	50                   	push   %eax
f0104005:	68 08 5e 10 f0       	push   $0xf0105e08
f010400a:	6a 4e                	push   $0x4e
f010400c:	68 19 74 10 f0       	push   $0xf0107419
f0104011:	e8 2a c0 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104016:	05 00 00 00 10       	add    $0x10000000,%eax
f010401b:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010401e:	e8 f8 16 00 00       	call   f010571b <cpunum>
f0104023:	6b d0 74             	imul   $0x74,%eax,%edx
f0104026:	81 c2 20 f0 22 f0    	add    $0xf022f020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f010402c:	b8 02 00 00 00       	mov    $0x2,%eax
f0104031:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104035:	83 ec 0c             	sub    $0xc,%esp
f0104038:	68 c0 f3 11 f0       	push   $0xf011f3c0
f010403d:	e8 e4 19 00 00       	call   f0105a26 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104042:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104044:	e8 d2 16 00 00       	call   f010571b <cpunum>
f0104049:	6b c0 74             	imul   $0x74,%eax,%eax
	//cprintf("in the halt\n");
	// Reset stack pointer, enable interrupts and then halt.
	//cprintf("this cpu:%08x\n",thiscpu->cpu_ts.ts_esp0);
	//for(;;);
	
	asm volatile (
f010404c:	8b 80 30 f0 22 f0    	mov    -0xfdd0fd0(%eax),%eax
f0104052:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104057:	89 c4                	mov    %eax,%esp
f0104059:	6a 00                	push   $0x0
f010405b:	6a 00                	push   $0x0
f010405d:	fb                   	sti    
f010405e:	f4                   	hlt    
f010405f:	eb fd                	jmp    f010405e <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104061:	83 c4 10             	add    $0x10,%esp
f0104064:	c9                   	leave  
f0104065:	c3                   	ret    

f0104066 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104066:	55                   	push   %ebp
f0104067:	89 e5                	mov    %esp,%ebp
f0104069:	56                   	push   %esi
f010406a:	53                   	push   %ebx
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
f010406b:	e8 ab 16 00 00       	call   f010571b <cpunum>
f0104070:	6b c0 74             	imul   $0x74,%eax,%eax
f0104073:	8b b0 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%esi
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
f0104079:	85 f6                	test   %esi,%esi
f010407b:	74 0b                	je     f0104088 <sched_yield+0x22>
f010407d:	8b 4e 48             	mov    0x48(%esi),%ecx
f0104080:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0104086:	eb 05                	jmp    f010408d <sched_yield+0x27>
f0104088:	b9 00 00 00 00       	mov    $0x0,%ecx
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f010408d:	8b 1d 44 e2 22 f0    	mov    0xf022e244,%ebx
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
f0104093:	89 c8                	mov    %ecx,%eax
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
    	{  
        	if(envs[i].env_status == ENV_RUNNABLE)  
f0104095:	6b d0 7c             	imul   $0x7c,%eax,%edx
f0104098:	01 da                	add    %ebx,%edx
f010409a:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f010409e:	75 09                	jne    f01040a9 <sched_yield+0x43>
       		{	   
       		        env_run(&envs[i]);  
f01040a0:	83 ec 0c             	sub    $0xc,%esp
f01040a3:	52                   	push   %edx
f01040a4:	e8 c0 f2 ff ff       	call   f0103369 <env_run>
	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;  
    	uint32_t start = (idle != NULL) ? ENVX( idle->env_id) : 0;  
    	uint32_t i = start;  
    	bool first = true;  
   	for (; i != start || first; i = (i+1) % NENV, first = false)  
f01040a9:	83 c0 01             	add    $0x1,%eax
f01040ac:	25 ff 03 00 00       	and    $0x3ff,%eax
f01040b1:	39 c1                	cmp    %eax,%ecx
f01040b3:	75 e0                	jne    f0104095 <sched_yield+0x2f>
       		        env_run(&envs[i]);  
            		return ;  
        	}  
   	 }  
  
        if (idle && idle->env_status == ENV_RUNNING)  
f01040b5:	85 f6                	test   %esi,%esi
f01040b7:	74 0f                	je     f01040c8 <sched_yield+0x62>
f01040b9:	83 7e 54 03          	cmpl   $0x3,0x54(%esi)
f01040bd:	75 09                	jne    f01040c8 <sched_yield+0x62>
	{  
       	 	env_run(idle);  
f01040bf:	83 ec 0c             	sub    $0xc,%esp
f01040c2:	56                   	push   %esi
f01040c3:	e8 a1 f2 ff ff       	call   f0103369 <env_run>
        	return ;  
    	}  
  
    // sched_halt never returns  
    sched_halt();
f01040c8:	e8 c5 fe ff ff       	call   f0103f92 <sched_halt>
}
f01040cd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01040d0:	5b                   	pop    %ebx
f01040d1:	5e                   	pop    %esi
f01040d2:	5d                   	pop    %ebp
f01040d3:	c3                   	ret    

f01040d4 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01040d4:	55                   	push   %ebp
f01040d5:	89 e5                	mov    %esp,%ebp
f01040d7:	57                   	push   %edi
f01040d8:	56                   	push   %esi
f01040d9:	53                   	push   %ebx
f01040da:	83 ec 1c             	sub    $0x1c,%esp
f01040dd:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) 
f01040e0:	83 f8 0a             	cmp    $0xa,%eax
f01040e3:	0f 87 77 04 00 00    	ja     f0104560 <syscall+0x48c>
f01040e9:	ff 24 85 60 74 10 f0 	jmp    *-0xfef8ba0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f01040f0:	e8 26 16 00 00       	call   f010571b <cpunum>
f01040f5:	6a 04                	push   $0x4
f01040f7:	ff 75 10             	pushl  0x10(%ebp)
f01040fa:	ff 75 0c             	pushl  0xc(%ebp)
f01040fd:	6b c0 74             	imul   $0x74,%eax,%eax
f0104100:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0104106:	e8 65 eb ff ff       	call   f0102c70 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010410b:	83 c4 0c             	add    $0xc,%esp
f010410e:	ff 75 0c             	pushl  0xc(%ebp)
f0104111:	ff 75 10             	pushl  0x10(%ebp)
f0104114:	68 26 74 10 f0       	push   $0xf0107426
f0104119:	e8 8f f4 ff ff       	call   f01035ad <cprintf>
f010411e:	83 c4 10             	add    $0x10,%esp
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall(a1, (void *)a2);
		default:
			return -E_INVAL;
	}
	return 0;
f0104121:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104126:	e9 3a 04 00 00       	jmp    f0104565 <syscall+0x491>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010412b:	e8 c5 c4 ff ff       	call   f01005f5 <cons_getc>
f0104130:	89 c3                	mov    %eax,%ebx
	 {
		case 0:
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
f0104132:	e9 2e 04 00 00       	jmp    f0104565 <syscall+0x491>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104137:	e8 df 15 00 00       	call   f010571b <cpunum>
f010413c:	6b c0 74             	imul   $0x74,%eax,%eax
f010413f:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f0104145:	8b 58 48             	mov    0x48(%eax),%ebx
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
		case 2:
			return sys_getenvid();	
f0104148:	e9 18 04 00 00       	jmp    f0104565 <syscall+0x491>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010414d:	83 ec 04             	sub    $0x4,%esp
f0104150:	6a 01                	push   $0x1
f0104152:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104155:	50                   	push   %eax
f0104156:	ff 75 0c             	pushl  0xc(%ebp)
f0104159:	e8 e7 eb ff ff       	call   f0102d45 <envid2env>
f010415e:	83 c4 10             	add    $0x10,%esp
		return r;
f0104161:	89 c3                	mov    %eax,%ebx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104163:	85 c0                	test   %eax,%eax
f0104165:	0f 88 fa 03 00 00    	js     f0104565 <syscall+0x491>
		return r;
	if (e == curenv)
f010416b:	e8 ab 15 00 00       	call   f010571b <cpunum>
f0104170:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104173:	6b c0 74             	imul   $0x74,%eax,%eax
f0104176:	39 90 28 f0 22 f0    	cmp    %edx,-0xfdd0fd8(%eax)
f010417c:	75 23                	jne    f01041a1 <syscall+0xcd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010417e:	e8 98 15 00 00       	call   f010571b <cpunum>
f0104183:	83 ec 08             	sub    $0x8,%esp
f0104186:	6b c0 74             	imul   $0x74,%eax,%eax
f0104189:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f010418f:	ff 70 48             	pushl  0x48(%eax)
f0104192:	68 2b 74 10 f0       	push   $0xf010742b
f0104197:	e8 11 f4 ff ff       	call   f01035ad <cprintf>
f010419c:	83 c4 10             	add    $0x10,%esp
f010419f:	eb 25                	jmp    f01041c6 <syscall+0xf2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01041a1:	8b 5a 48             	mov    0x48(%edx),%ebx
f01041a4:	e8 72 15 00 00       	call   f010571b <cpunum>
f01041a9:	83 ec 04             	sub    $0x4,%esp
f01041ac:	53                   	push   %ebx
f01041ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01041b0:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01041b6:	ff 70 48             	pushl  0x48(%eax)
f01041b9:	68 46 74 10 f0       	push   $0xf0107446
f01041be:	e8 ea f3 ff ff       	call   f01035ad <cprintf>
f01041c3:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01041c6:	83 ec 0c             	sub    $0xc,%esp
f01041c9:	ff 75 e4             	pushl  -0x1c(%ebp)
f01041cc:	e8 f9 f0 ff ff       	call   f01032ca <env_destroy>
f01041d1:	83 c4 10             	add    $0x10,%esp
	return 0;
f01041d4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01041d9:	e9 87 03 00 00       	jmp    f0104565 <syscall+0x491>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01041de:	e8 83 fe ff ff       	call   f0104066 <sched_yield>
	//   allocated!

	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
f01041e3:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01041ea:	0f 87 d6 00 00 00    	ja     f01042c6 <syscall+0x1f2>
f01041f0:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01041f7:	0f 85 d3 00 00 00    	jne    f01042d0 <syscall+0x1fc>
	{
		return -E_INVAL;
	}
	if(envid2env(envid,&e,1)<0)
f01041fd:	83 ec 04             	sub    $0x4,%esp
f0104200:	6a 01                	push   $0x1
f0104202:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104205:	50                   	push   %eax
f0104206:	ff 75 0c             	pushl  0xc(%ebp)
f0104209:	e8 37 eb ff ff       	call   f0102d45 <envid2env>
f010420e:	83 c4 10             	add    $0x10,%esp
f0104211:	85 c0                	test   %eax,%eax
f0104213:	0f 88 c1 00 00 00    	js     f01042da <syscall+0x206>
		return -E_BAD_ENV;
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104219:	8b 45 14             	mov    0x14(%ebp),%eax
f010421c:	83 e0 05             	and    $0x5,%eax
f010421f:	83 f8 05             	cmp    $0x5,%eax
f0104222:	0f 85 bc 00 00 00    	jne    f01042e4 <syscall+0x210>
		return -E_INVAL;
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f0104228:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010422b:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f0104231:	0f 85 b7 00 00 00    	jne    f01042ee <syscall+0x21a>
		return -E_INVAL;
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
f0104237:	83 ec 0c             	sub    $0xc,%esp
f010423a:	6a 01                	push   $0x1
f010423c:	e8 4b cc ff ff       	call   f0100e8c <page_alloc>
f0104241:	89 c6                	mov    %eax,%esi
	if(p==NULL)
f0104243:	83 c4 10             	add    $0x10,%esp
f0104246:	85 c0                	test   %eax,%eax
f0104248:	0f 84 aa 00 00 00    	je     f01042f8 <syscall+0x224>
		return -E_NO_MEM;
	if(page_insert(e->env_pgdir,p,(void *)va,perm)<0)
f010424e:	ff 75 14             	pushl  0x14(%ebp)
f0104251:	ff 75 10             	pushl  0x10(%ebp)
f0104254:	50                   	push   %eax
f0104255:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104258:	ff 70 60             	pushl  0x60(%eax)
f010425b:	e8 cd ce ff ff       	call   f010112d <page_insert>
f0104260:	83 c4 10             	add    $0x10,%esp
f0104263:	85 c0                	test   %eax,%eax
f0104265:	79 16                	jns    f010427d <syscall+0x1a9>
	{
		page_free(p);
f0104267:	83 ec 0c             	sub    $0xc,%esp
f010426a:	56                   	push   %esi
f010426b:	e8 8c cc ff ff       	call   f0100efc <page_free>
f0104270:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f0104273:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
f0104278:	e9 e8 02 00 00       	jmp    f0104565 <syscall+0x491>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010427d:	2b 35 90 ee 22 f0    	sub    0xf022ee90,%esi
f0104283:	c1 fe 03             	sar    $0x3,%esi
f0104286:	c1 e6 0c             	shl    $0xc,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104289:	89 f0                	mov    %esi,%eax
f010428b:	c1 e8 0c             	shr    $0xc,%eax
f010428e:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f0104294:	72 12                	jb     f01042a8 <syscall+0x1d4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104296:	56                   	push   %esi
f0104297:	68 e4 5d 10 f0       	push   $0xf0105de4
f010429c:	6a 58                	push   $0x58
f010429e:	68 55 6c 10 f0       	push   $0xf0106c55
f01042a3:	e8 98 bd ff ff       	call   f0100040 <_panic>
	}
	memset(page2kva(p),0,PGSIZE);
f01042a8:	83 ec 04             	sub    $0x4,%esp
f01042ab:	68 00 10 00 00       	push   $0x1000
f01042b0:	6a 00                	push   $0x0
f01042b2:	81 ee 00 00 00 10    	sub    $0x10000000,%esi
f01042b8:	56                   	push   %esi
f01042b9:	e8 27 0e 00 00       	call   f01050e5 <memset>
f01042be:	83 c4 10             	add    $0x10,%esp
f01042c1:	e9 9f 02 00 00       	jmp    f0104565 <syscall+0x491>
	// LAB 4: Your code here.
	//cprintf("das\n");
	struct Env *e;
	if(va>=(void *)UTOP||(uint32_t)va%PGSIZE!=0)
	{
		return -E_INVAL;
f01042c6:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01042cb:	e9 95 02 00 00       	jmp    f0104565 <syscall+0x491>
f01042d0:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01042d5:	e9 8b 02 00 00       	jmp    f0104565 <syscall+0x491>
	}
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f01042da:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01042df:	e9 81 02 00 00       	jmp    f0104565 <syscall+0x491>
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
		return -E_INVAL;
f01042e4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01042e9:	e9 77 02 00 00       	jmp    f0104565 <syscall+0x491>
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
		return -E_INVAL;
f01042ee:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01042f3:	e9 6d 02 00 00       	jmp    f0104565 <syscall+0x491>
	struct PageInfo *p=page_alloc(ALLOC_ZERO);
	if(p==NULL)
		return -E_NO_MEM;
f01042f8:	bb fc ff ff ff       	mov    $0xfffffffc,%ebx
			return sys_env_destroy(a1);	
		case SYS_yield:
		 	sys_yield();	
			break;
		case SYS_page_alloc:
			return sys_page_alloc(a1,(void *)a2,(int )a3);
f01042fd:	e9 63 02 00 00       	jmp    f0104565 <syscall+0x491>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
f0104302:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104309:	0f 87 cb 00 00 00    	ja     f01043da <syscall+0x306>
f010430f:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104316:	0f 85 c8 00 00 00    	jne    f01043e4 <syscall+0x310>
f010431c:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104323:	0f 87 bb 00 00 00    	ja     f01043e4 <syscall+0x310>
f0104329:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104330:	0f 85 b8 00 00 00    	jne    f01043ee <syscall+0x31a>
	{
		//cprintf("1\n");
		return -E_INVAL;
	}
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
f0104336:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0104339:	83 e0 05             	and    $0x5,%eax
f010433c:	83 f8 05             	cmp    $0x5,%eax
f010433f:	0f 85 b3 00 00 00    	jne    f01043f8 <syscall+0x324>
	{
		//cprintf("2\n");
		return -E_INVAL;
	}
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
f0104345:	8b 5d 1c             	mov    0x1c(%ebp),%ebx
f0104348:	81 e3 f8 f1 ff ff    	and    $0xfffff1f8,%ebx
f010434e:	0f 85 ae 00 00 00    	jne    f0104402 <syscall+0x32e>
		//cprintf("3\n");
		return -E_INVAL;
	}
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
f0104354:	83 ec 04             	sub    $0x4,%esp
f0104357:	6a 01                	push   $0x1
f0104359:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010435c:	50                   	push   %eax
f010435d:	ff 75 0c             	pushl  0xc(%ebp)
f0104360:	e8 e0 e9 ff ff       	call   f0102d45 <envid2env>
f0104365:	83 c4 10             	add    $0x10,%esp
f0104368:	85 c0                	test   %eax,%eax
f010436a:	0f 88 9c 00 00 00    	js     f010440c <syscall+0x338>
	{
		//cprintf("4\n");
		return -E_BAD_ENV;
	}
	if(envid2env(dstenvid,&desenv,1)<0)
f0104370:	83 ec 04             	sub    $0x4,%esp
f0104373:	6a 01                	push   $0x1
f0104375:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104378:	50                   	push   %eax
f0104379:	ff 75 14             	pushl  0x14(%ebp)
f010437c:	e8 c4 e9 ff ff       	call   f0102d45 <envid2env>
f0104381:	83 c4 10             	add    $0x10,%esp
f0104384:	85 c0                	test   %eax,%eax
f0104386:	0f 88 8a 00 00 00    	js     f0104416 <syscall+0x342>
	{	
		//cprintf("5\n");
		return -E_BAD_ENV;
	}
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
f010438c:	83 ec 04             	sub    $0x4,%esp
f010438f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104392:	50                   	push   %eax
f0104393:	ff 75 10             	pushl  0x10(%ebp)
f0104396:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104399:	ff 70 60             	pushl  0x60(%eax)
f010439c:	e8 a4 cc ff ff       	call   f0101045 <page_lookup>
	if (p==NULL||((perm&PTE_W)>0&&(*po_entry&PTE_W)==0))
f01043a1:	83 c4 10             	add    $0x10,%esp
f01043a4:	85 c0                	test   %eax,%eax
f01043a6:	74 78                	je     f0104420 <syscall+0x34c>
f01043a8:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01043ac:	74 08                	je     f01043b6 <syscall+0x2e2>
f01043ae:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01043b1:	f6 02 02             	testb  $0x2,(%edx)
f01043b4:	74 74                	je     f010442a <syscall+0x356>
		return -E_INVAL;
	if(page_insert(desenv->env_pgdir,p,dstva,perm)<0)
f01043b6:	ff 75 1c             	pushl  0x1c(%ebp)
f01043b9:	ff 75 18             	pushl  0x18(%ebp)
f01043bc:	50                   	push   %eax
f01043bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043c0:	ff 70 60             	pushl  0x60(%eax)
f01043c3:	e8 65 cd ff ff       	call   f010112d <page_insert>
f01043c8:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f01043cb:	85 c0                	test   %eax,%eax
f01043cd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01043d2:	0f 48 d8             	cmovs  %eax,%ebx
f01043d5:	e9 8b 01 00 00       	jmp    f0104565 <syscall+0x491>

	// LAB 4: Your code here.
	if(srcva>=(void *)UTOP||(uint32_t)srcva%PGSIZE!=0||dstva>=(void *)UTOP||(uint32_t)dstva%PGSIZE!=0)
	{
		//cprintf("1\n");
		return -E_INVAL;
f01043da:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043df:	e9 81 01 00 00       	jmp    f0104565 <syscall+0x491>
f01043e4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043e9:	e9 77 01 00 00       	jmp    f0104565 <syscall+0x491>
f01043ee:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043f3:	e9 6d 01 00 00       	jmp    f0104565 <syscall+0x491>
	}
	if((perm&PTE_U)==0||(perm&PTE_P)==0)
	{
		//cprintf("2\n");
		return -E_INVAL;
f01043f8:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01043fd:	e9 63 01 00 00       	jmp    f0104565 <syscall+0x491>
	}
	if((perm&~(PTE_U|PTE_P|PTE_W|PTE_AVAIL))!=0)
	{
		//cprintf("3\n");
		return -E_INVAL;
f0104402:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104407:	e9 59 01 00 00       	jmp    f0104565 <syscall+0x491>
	struct Env *srcenv;
	struct Env *desenv;
	if(envid2env(srcenvid,&srcenv,1)<0)
	{
		//cprintf("4\n");
		return -E_BAD_ENV;
f010440c:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f0104411:	e9 4f 01 00 00       	jmp    f0104565 <syscall+0x491>
	}
	if(envid2env(dstenvid,&desenv,1)<0)
	{	
		//cprintf("5\n");
		return -E_BAD_ENV;
f0104416:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f010441b:	e9 45 01 00 00       	jmp    f0104565 <syscall+0x491>
	}
	pte_t *po_entry;
	struct PageInfo *p=page_lookup(srcenv->env_pgdir,srcva,&po_entry);
	if (p==NULL||((perm&PTE_W)>0&&(*po_entry&PTE_W)==0))
		return -E_INVAL;
f0104420:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104425:	e9 3b 01 00 00       	jmp    f0104565 <syscall+0x491>
f010442a:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010442f:	e9 31 01 00 00       	jmp    f0104565 <syscall+0x491>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
f0104434:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010443b:	77 3f                	ja     f010447c <syscall+0x3a8>
f010443d:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104444:	75 40                	jne    f0104486 <syscall+0x3b2>
		return -E_INVAL;
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
f0104446:	83 ec 04             	sub    $0x4,%esp
f0104449:	6a 01                	push   $0x1
f010444b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010444e:	50                   	push   %eax
f010444f:	ff 75 0c             	pushl  0xc(%ebp)
f0104452:	e8 ee e8 ff ff       	call   f0102d45 <envid2env>
f0104457:	83 c4 10             	add    $0x10,%esp
f010445a:	85 c0                	test   %eax,%eax
f010445c:	78 32                	js     f0104490 <syscall+0x3bc>
		return -E_BAD_ENV;
	page_remove(e->env_pgdir,va);
f010445e:	83 ec 08             	sub    $0x8,%esp
f0104461:	ff 75 10             	pushl  0x10(%ebp)
f0104464:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104467:	ff 70 60             	pushl  0x60(%eax)
f010446a:	e8 71 cc ff ff       	call   f01010e0 <page_remove>
f010446f:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104472:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104477:	e9 e9 00 00 00       	jmp    f0104565 <syscall+0x491>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	if(va>=(void*)UTOP||(uint32_t)va%PGSIZE!=0)
		return -E_INVAL;
f010447c:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f0104481:	e9 df 00 00 00       	jmp    f0104565 <syscall+0x491>
f0104486:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010448b:	e9 d5 00 00 00       	jmp    f0104565 <syscall+0x491>
	struct Env *e;
	if(envid2env(envid,&e,1)<0)
		return -E_BAD_ENV;
f0104490:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			return sys_page_alloc(a1,(void *)a2,(int )a3);
		case SYS_page_map:
			return 	sys_page_map((envid_t) a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int) a5); 
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
f0104495:	e9 cb 00 00 00       	jmp    f0104565 <syscall+0x491>
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f010449a:	e8 7c 12 00 00       	call   f010571b <cpunum>
f010449f:	83 ec 08             	sub    $0x8,%esp
f01044a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01044a5:	8b 80 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%eax
f01044ab:	ff 70 48             	pushl  0x48(%eax)
f01044ae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044b1:	50                   	push   %eax
f01044b2:	e8 9f e9 ff ff       	call   f0102e56 <env_alloc>
f01044b7:	83 c4 10             	add    $0x10,%esp
	{
		return r;
f01044ba:	89 c3                	mov    %eax,%ebx
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *newenv;
	int r;
	if((r=env_alloc(&newenv,curenv->env_id))<0)
f01044bc:	85 c0                	test   %eax,%eax
f01044be:	0f 88 a1 00 00 00    	js     f0104565 <syscall+0x491>
	{
		return r;
	}
	newenv->env_status=ENV_NOT_RUNNABLE;
f01044c4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01044c7:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv->env_tf=curenv->env_tf;
f01044ce:	e8 48 12 00 00       	call   f010571b <cpunum>
f01044d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01044d6:	8b b0 28 f0 22 f0    	mov    -0xfdd0fd8(%eax),%esi
f01044dc:	b9 11 00 00 00       	mov    $0x11,%ecx
f01044e1:	89 df                	mov    %ebx,%edi
f01044e3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv->env_tf.tf_regs.reg_eax=0;
f01044e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044e8:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return newenv->env_id;
f01044ef:	8b 58 48             	mov    0x48(%eax),%ebx
f01044f2:	eb 71                	jmp    f0104565 <syscall+0x491>
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
f01044f4:	8b 45 10             	mov    0x10(%ebp),%eax
f01044f7:	83 e8 02             	sub    $0x2,%eax
f01044fa:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01044ff:	75 28                	jne    f0104529 <syscall+0x455>
		return -E_INVAL;
	struct Env *e;
	int r=envid2env(envid,&e,1);
f0104501:	83 ec 04             	sub    $0x4,%esp
f0104504:	6a 01                	push   $0x1
f0104506:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104509:	50                   	push   %eax
f010450a:	ff 75 0c             	pushl  0xc(%ebp)
f010450d:	e8 33 e8 ff ff       	call   f0102d45 <envid2env>
	if(r<0)	
f0104512:	83 c4 10             	add    $0x10,%esp
f0104515:	85 c0                	test   %eax,%eax
f0104517:	78 17                	js     f0104530 <syscall+0x45c>
		return r;
	e->env_status=status;
f0104519:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010451c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010451f:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f0104522:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104527:	eb 3c                	jmp    f0104565 <syscall+0x491>
	// check whether the current environment has permission to set
	// envid's status.
	
	// LAB 4: Your code here.
	if(status!=ENV_RUNNABLE&&status!=ENV_NOT_RUNNABLE)
		return -E_INVAL;
f0104529:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010452e:	eb 35                	jmp    f0104565 <syscall+0x491>
	struct Env *e;
	int r=envid2env(envid,&e,1);
	if(r<0)	
		return r;
f0104530:	89 c3                	mov    %eax,%ebx
		case SYS_page_unmap:
			return  sys_page_unmap((envid_t) a1, (void *)a2);
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
f0104532:	eb 31                	jmp    f0104565 <syscall+0x491>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *e;
	int r=envid2env(envid,&e,1);
f0104534:	83 ec 04             	sub    $0x4,%esp
f0104537:	6a 01                	push   $0x1
f0104539:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010453c:	50                   	push   %eax
f010453d:	ff 75 0c             	pushl  0xc(%ebp)
f0104540:	e8 00 e8 ff ff       	call   f0102d45 <envid2env>
	if(r<0)
f0104545:	83 c4 10             	add    $0x10,%esp
f0104548:	85 c0                	test   %eax,%eax
f010454a:	78 10                	js     f010455c <syscall+0x488>
		return r;
	e->env_pgfault_upcall=func;
f010454c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010454f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104552:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f0104555:	bb 00 00 00 00       	mov    $0x0,%ebx
f010455a:	eb 09                	jmp    f0104565 <syscall+0x491>
{
	// LAB 4: Your code here.
	struct Env *e;
	int r=envid2env(envid,&e,1);
	if(r<0)
		return r;
f010455c:	89 c3                	mov    %eax,%ebx
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status:
			return sys_env_set_status((envid_t) a1, (int) a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall(a1, (void *)a2);
f010455e:	eb 05                	jmp    f0104565 <syscall+0x491>
		default:
			return -E_INVAL;
f0104560:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
	}
	return 0;
}
f0104565:	89 d8                	mov    %ebx,%eax
f0104567:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010456a:	5b                   	pop    %ebx
f010456b:	5e                   	pop    %esi
f010456c:	5f                   	pop    %edi
f010456d:	5d                   	pop    %ebp
f010456e:	c3                   	ret    

f010456f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010456f:	55                   	push   %ebp
f0104570:	89 e5                	mov    %esp,%ebp
f0104572:	57                   	push   %edi
f0104573:	56                   	push   %esi
f0104574:	53                   	push   %ebx
f0104575:	83 ec 14             	sub    $0x14,%esp
f0104578:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010457b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010457e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104581:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104584:	8b 1a                	mov    (%edx),%ebx
f0104586:	8b 01                	mov    (%ecx),%eax
f0104588:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010458b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104592:	eb 7f                	jmp    f0104613 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104594:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104597:	01 d8                	add    %ebx,%eax
f0104599:	89 c6                	mov    %eax,%esi
f010459b:	c1 ee 1f             	shr    $0x1f,%esi
f010459e:	01 c6                	add    %eax,%esi
f01045a0:	d1 fe                	sar    %esi
f01045a2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01045a5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01045a8:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01045ab:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01045ad:	eb 03                	jmp    f01045b2 <stab_binsearch+0x43>
			m--;
f01045af:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01045b2:	39 c3                	cmp    %eax,%ebx
f01045b4:	7f 0d                	jg     f01045c3 <stab_binsearch+0x54>
f01045b6:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01045ba:	83 ea 0c             	sub    $0xc,%edx
f01045bd:	39 f9                	cmp    %edi,%ecx
f01045bf:	75 ee                	jne    f01045af <stab_binsearch+0x40>
f01045c1:	eb 05                	jmp    f01045c8 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01045c3:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01045c6:	eb 4b                	jmp    f0104613 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01045c8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01045cb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01045ce:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01045d2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01045d5:	76 11                	jbe    f01045e8 <stab_binsearch+0x79>
			*region_left = m;
f01045d7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01045da:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01045dc:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01045df:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01045e6:	eb 2b                	jmp    f0104613 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01045e8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01045eb:	73 14                	jae    f0104601 <stab_binsearch+0x92>
			*region_right = m - 1;
f01045ed:	83 e8 01             	sub    $0x1,%eax
f01045f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01045f3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01045f6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01045f8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01045ff:	eb 12                	jmp    f0104613 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104601:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104604:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104606:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010460a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010460c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104613:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104616:	0f 8e 78 ff ff ff    	jle    f0104594 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010461c:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104620:	75 0f                	jne    f0104631 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104622:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104625:	8b 00                	mov    (%eax),%eax
f0104627:	83 e8 01             	sub    $0x1,%eax
f010462a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010462d:	89 06                	mov    %eax,(%esi)
f010462f:	eb 2c                	jmp    f010465d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104631:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104634:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104636:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104639:	8b 0e                	mov    (%esi),%ecx
f010463b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010463e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104641:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104644:	eb 03                	jmp    f0104649 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104646:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104649:	39 c8                	cmp    %ecx,%eax
f010464b:	7e 0b                	jle    f0104658 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010464d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104651:	83 ea 0c             	sub    $0xc,%edx
f0104654:	39 df                	cmp    %ebx,%edi
f0104656:	75 ee                	jne    f0104646 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104658:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010465b:	89 06                	mov    %eax,(%esi)
	}
}
f010465d:	83 c4 14             	add    $0x14,%esp
f0104660:	5b                   	pop    %ebx
f0104661:	5e                   	pop    %esi
f0104662:	5f                   	pop    %edi
f0104663:	5d                   	pop    %ebp
f0104664:	c3                   	ret    

f0104665 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104665:	55                   	push   %ebp
f0104666:	89 e5                	mov    %esp,%ebp
f0104668:	57                   	push   %edi
f0104669:	56                   	push   %esi
f010466a:	53                   	push   %ebx
f010466b:	83 ec 2c             	sub    $0x2c,%esp
f010466e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104671:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104674:	c7 06 8c 74 10 f0    	movl   $0xf010748c,(%esi)
	info->eip_line = 0;
f010467a:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104681:	c7 46 08 8c 74 10 f0 	movl   $0xf010748c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104688:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010468f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104692:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104699:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010469f:	0f 87 a3 00 00 00    	ja     f0104748 <debuginfo_eip+0xe3>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
f01046a5:	e8 71 10 00 00       	call   f010571b <cpunum>
f01046aa:	6a 00                	push   $0x0
f01046ac:	6a 10                	push   $0x10
f01046ae:	68 00 00 20 00       	push   $0x200000
f01046b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b6:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f01046bc:	e8 2f e5 ff ff       	call   f0102bf0 <user_mem_check>
f01046c1:	83 c4 10             	add    $0x10,%esp
f01046c4:	85 c0                	test   %eax,%eax
f01046c6:	0f 88 d4 01 00 00    	js     f01048a0 <debuginfo_eip+0x23b>
			return -1;
		stabs = usd->stabs;
f01046cc:	a1 00 00 20 00       	mov    0x200000,%eax
f01046d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01046d4:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01046da:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01046e0:	89 55 cc             	mov    %edx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01046e3:	a1 0c 00 20 00       	mov    0x20000c,%eax
f01046e8:	89 45 d0             	mov    %eax,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
f01046eb:	e8 2b 10 00 00       	call   f010571b <cpunum>
f01046f0:	6a 00                	push   $0x0
f01046f2:	89 da                	mov    %ebx,%edx
f01046f4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01046f7:	29 ca                	sub    %ecx,%edx
f01046f9:	c1 fa 02             	sar    $0x2,%edx
f01046fc:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104702:	52                   	push   %edx
f0104703:	51                   	push   %ecx
f0104704:	6b c0 74             	imul   $0x74,%eax,%eax
f0104707:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f010470d:	e8 de e4 ff ff       	call   f0102bf0 <user_mem_check>
f0104712:	83 c4 10             	add    $0x10,%esp
f0104715:	85 c0                	test   %eax,%eax
f0104717:	0f 88 8a 01 00 00    	js     f01048a7 <debuginfo_eip+0x242>
f010471d:	e8 f9 0f 00 00       	call   f010571b <cpunum>
f0104722:	6a 00                	push   $0x0
f0104724:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104727:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010472a:	29 ca                	sub    %ecx,%edx
f010472c:	52                   	push   %edx
f010472d:	51                   	push   %ecx
f010472e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104731:	ff b0 28 f0 22 f0    	pushl  -0xfdd0fd8(%eax)
f0104737:	e8 b4 e4 ff ff       	call   f0102bf0 <user_mem_check>
f010473c:	83 c4 10             	add    $0x10,%esp
f010473f:	85 c0                	test   %eax,%eax
f0104741:	79 1f                	jns    f0104762 <debuginfo_eip+0xfd>
f0104743:	e9 66 01 00 00       	jmp    f01048ae <debuginfo_eip+0x249>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104748:	c7 45 d0 a7 4c 11 f0 	movl   $0xf0114ca7,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010474f:	c7 45 cc 8d 16 11 f0 	movl   $0xf011168d,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104756:	bb 8c 16 11 f0       	mov    $0xf011168c,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010475b:	c7 45 d4 78 79 10 f0 	movl   $0xf0107978,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104762:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104765:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104768:	0f 83 47 01 00 00    	jae    f01048b5 <debuginfo_eip+0x250>
f010476e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104772:	0f 85 44 01 00 00    	jne    f01048bc <debuginfo_eip+0x257>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104778:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010477f:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0104782:	c1 fb 02             	sar    $0x2,%ebx
f0104785:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f010478b:	83 e8 01             	sub    $0x1,%eax
f010478e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104791:	83 ec 08             	sub    $0x8,%esp
f0104794:	57                   	push   %edi
f0104795:	6a 64                	push   $0x64
f0104797:	8d 55 e0             	lea    -0x20(%ebp),%edx
f010479a:	89 d1                	mov    %edx,%ecx
f010479c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010479f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01047a2:	89 d8                	mov    %ebx,%eax
f01047a4:	e8 c6 fd ff ff       	call   f010456f <stab_binsearch>
	if (lfile == 0)
f01047a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01047ac:	83 c4 10             	add    $0x10,%esp
f01047af:	85 c0                	test   %eax,%eax
f01047b1:	0f 84 0c 01 00 00    	je     f01048c3 <debuginfo_eip+0x25e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01047b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01047ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01047c0:	83 ec 08             	sub    $0x8,%esp
f01047c3:	57                   	push   %edi
f01047c4:	6a 24                	push   $0x24
f01047c6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01047c9:	89 d1                	mov    %edx,%ecx
f01047cb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01047ce:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01047d1:	89 d8                	mov    %ebx,%eax
f01047d3:	e8 97 fd ff ff       	call   f010456f <stab_binsearch>

	if (lfun <= rfun) {
f01047d8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01047db:	83 c4 10             	add    $0x10,%esp
f01047de:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01047e1:	7f 24                	jg     f0104807 <debuginfo_eip+0x1a2>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01047e3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01047e6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01047e9:	8d 14 87             	lea    (%edi,%eax,4),%edx
f01047ec:	8b 02                	mov    (%edx),%eax
f01047ee:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01047f1:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01047f4:	29 f9                	sub    %edi,%ecx
f01047f6:	39 c8                	cmp    %ecx,%eax
f01047f8:	73 05                	jae    f01047ff <debuginfo_eip+0x19a>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01047fa:	01 f8                	add    %edi,%eax
f01047fc:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01047ff:	8b 42 08             	mov    0x8(%edx),%eax
f0104802:	89 46 10             	mov    %eax,0x10(%esi)
f0104805:	eb 06                	jmp    f010480d <debuginfo_eip+0x1a8>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104807:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010480a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010480d:	83 ec 08             	sub    $0x8,%esp
f0104810:	6a 3a                	push   $0x3a
f0104812:	ff 76 08             	pushl  0x8(%esi)
f0104815:	e8 af 08 00 00       	call   f01050c9 <strfind>
f010481a:	2b 46 08             	sub    0x8(%esi),%eax
f010481d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104820:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104823:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104826:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104829:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010482c:	83 c4 10             	add    $0x10,%esp
f010482f:	eb 06                	jmp    f0104837 <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104831:	83 eb 01             	sub    $0x1,%ebx
f0104834:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104837:	39 fb                	cmp    %edi,%ebx
f0104839:	7c 2d                	jl     f0104868 <debuginfo_eip+0x203>
	       && stabs[lline].n_type != N_SOL
f010483b:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010483f:	80 fa 84             	cmp    $0x84,%dl
f0104842:	74 0b                	je     f010484f <debuginfo_eip+0x1ea>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104844:	80 fa 64             	cmp    $0x64,%dl
f0104847:	75 e8                	jne    f0104831 <debuginfo_eip+0x1cc>
f0104849:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010484d:	74 e2                	je     f0104831 <debuginfo_eip+0x1cc>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010484f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104852:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104855:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104858:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010485b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010485e:	29 f8                	sub    %edi,%eax
f0104860:	39 c2                	cmp    %eax,%edx
f0104862:	73 04                	jae    f0104868 <debuginfo_eip+0x203>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104864:	01 fa                	add    %edi,%edx
f0104866:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104868:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010486b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010486e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104873:	39 cb                	cmp    %ecx,%ebx
f0104875:	7d 58                	jge    f01048cf <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
f0104877:	8d 53 01             	lea    0x1(%ebx),%edx
f010487a:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010487d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104880:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104883:	eb 07                	jmp    f010488c <debuginfo_eip+0x227>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104885:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104889:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010488c:	39 ca                	cmp    %ecx,%edx
f010488e:	74 3a                	je     f01048ca <debuginfo_eip+0x265>
f0104890:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104893:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0104897:	74 ec                	je     f0104885 <debuginfo_eip+0x220>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104899:	b8 00 00 00 00       	mov    $0x0,%eax
f010489e:	eb 2f                	jmp    f01048cf <debuginfo_eip+0x26a>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
			return -1;
f01048a0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048a5:	eb 28                	jmp    f01048cf <debuginfo_eip+0x26a>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
		{
			return -1;
f01048a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048ac:	eb 21                	jmp    f01048cf <debuginfo_eip+0x26a>
f01048ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048b3:	eb 1a                	jmp    f01048cf <debuginfo_eip+0x26a>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01048b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048ba:	eb 13                	jmp    f01048cf <debuginfo_eip+0x26a>
f01048bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048c1:	eb 0c                	jmp    f01048cf <debuginfo_eip+0x26a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01048c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048c8:	eb 05                	jmp    f01048cf <debuginfo_eip+0x26a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01048ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01048cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01048d2:	5b                   	pop    %ebx
f01048d3:	5e                   	pop    %esi
f01048d4:	5f                   	pop    %edi
f01048d5:	5d                   	pop    %ebp
f01048d6:	c3                   	ret    

f01048d7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01048d7:	55                   	push   %ebp
f01048d8:	89 e5                	mov    %esp,%ebp
f01048da:	57                   	push   %edi
f01048db:	56                   	push   %esi
f01048dc:	53                   	push   %ebx
f01048dd:	83 ec 1c             	sub    $0x1c,%esp
f01048e0:	89 c7                	mov    %eax,%edi
f01048e2:	89 d6                	mov    %edx,%esi
f01048e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01048e7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01048ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048ed:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01048f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01048f3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01048f8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01048fb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01048fe:	39 d3                	cmp    %edx,%ebx
f0104900:	72 05                	jb     f0104907 <printnum+0x30>
f0104902:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104905:	77 45                	ja     f010494c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104907:	83 ec 0c             	sub    $0xc,%esp
f010490a:	ff 75 18             	pushl  0x18(%ebp)
f010490d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104910:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104913:	53                   	push   %ebx
f0104914:	ff 75 10             	pushl  0x10(%ebp)
f0104917:	83 ec 08             	sub    $0x8,%esp
f010491a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010491d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104920:	ff 75 dc             	pushl  -0x24(%ebp)
f0104923:	ff 75 d8             	pushl  -0x28(%ebp)
f0104926:	e8 f5 11 00 00       	call   f0105b20 <__udivdi3>
f010492b:	83 c4 18             	add    $0x18,%esp
f010492e:	52                   	push   %edx
f010492f:	50                   	push   %eax
f0104930:	89 f2                	mov    %esi,%edx
f0104932:	89 f8                	mov    %edi,%eax
f0104934:	e8 9e ff ff ff       	call   f01048d7 <printnum>
f0104939:	83 c4 20             	add    $0x20,%esp
f010493c:	eb 18                	jmp    f0104956 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010493e:	83 ec 08             	sub    $0x8,%esp
f0104941:	56                   	push   %esi
f0104942:	ff 75 18             	pushl  0x18(%ebp)
f0104945:	ff d7                	call   *%edi
f0104947:	83 c4 10             	add    $0x10,%esp
f010494a:	eb 03                	jmp    f010494f <printnum+0x78>
f010494c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010494f:	83 eb 01             	sub    $0x1,%ebx
f0104952:	85 db                	test   %ebx,%ebx
f0104954:	7f e8                	jg     f010493e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104956:	83 ec 08             	sub    $0x8,%esp
f0104959:	56                   	push   %esi
f010495a:	83 ec 04             	sub    $0x4,%esp
f010495d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104960:	ff 75 e0             	pushl  -0x20(%ebp)
f0104963:	ff 75 dc             	pushl  -0x24(%ebp)
f0104966:	ff 75 d8             	pushl  -0x28(%ebp)
f0104969:	e8 e2 12 00 00       	call   f0105c50 <__umoddi3>
f010496e:	83 c4 14             	add    $0x14,%esp
f0104971:	0f be 80 96 74 10 f0 	movsbl -0xfef8b6a(%eax),%eax
f0104978:	50                   	push   %eax
f0104979:	ff d7                	call   *%edi
}
f010497b:	83 c4 10             	add    $0x10,%esp
f010497e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104981:	5b                   	pop    %ebx
f0104982:	5e                   	pop    %esi
f0104983:	5f                   	pop    %edi
f0104984:	5d                   	pop    %ebp
f0104985:	c3                   	ret    

f0104986 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104986:	55                   	push   %ebp
f0104987:	89 e5                	mov    %esp,%ebp
f0104989:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010498c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104990:	8b 10                	mov    (%eax),%edx
f0104992:	3b 50 04             	cmp    0x4(%eax),%edx
f0104995:	73 0a                	jae    f01049a1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104997:	8d 4a 01             	lea    0x1(%edx),%ecx
f010499a:	89 08                	mov    %ecx,(%eax)
f010499c:	8b 45 08             	mov    0x8(%ebp),%eax
f010499f:	88 02                	mov    %al,(%edx)
}
f01049a1:	5d                   	pop    %ebp
f01049a2:	c3                   	ret    

f01049a3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01049a3:	55                   	push   %ebp
f01049a4:	89 e5                	mov    %esp,%ebp
f01049a6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01049a9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01049ac:	50                   	push   %eax
f01049ad:	ff 75 10             	pushl  0x10(%ebp)
f01049b0:	ff 75 0c             	pushl  0xc(%ebp)
f01049b3:	ff 75 08             	pushl  0x8(%ebp)
f01049b6:	e8 05 00 00 00       	call   f01049c0 <vprintfmt>
	va_end(ap);
}
f01049bb:	83 c4 10             	add    $0x10,%esp
f01049be:	c9                   	leave  
f01049bf:	c3                   	ret    

f01049c0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01049c0:	55                   	push   %ebp
f01049c1:	89 e5                	mov    %esp,%ebp
f01049c3:	57                   	push   %edi
f01049c4:	56                   	push   %esi
f01049c5:	53                   	push   %ebx
f01049c6:	83 ec 2c             	sub    $0x2c,%esp
f01049c9:	8b 75 08             	mov    0x8(%ebp),%esi
f01049cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01049cf:	8b 7d 10             	mov    0x10(%ebp),%edi
f01049d2:	eb 12                	jmp    f01049e6 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01049d4:	85 c0                	test   %eax,%eax
f01049d6:	0f 84 42 04 00 00    	je     f0104e1e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f01049dc:	83 ec 08             	sub    $0x8,%esp
f01049df:	53                   	push   %ebx
f01049e0:	50                   	push   %eax
f01049e1:	ff d6                	call   *%esi
f01049e3:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01049e6:	83 c7 01             	add    $0x1,%edi
f01049e9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01049ed:	83 f8 25             	cmp    $0x25,%eax
f01049f0:	75 e2                	jne    f01049d4 <vprintfmt+0x14>
f01049f2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01049f6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01049fd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104a04:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104a0b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104a10:	eb 07                	jmp    f0104a19 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a12:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104a15:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a19:	8d 47 01             	lea    0x1(%edi),%eax
f0104a1c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104a1f:	0f b6 07             	movzbl (%edi),%eax
f0104a22:	0f b6 d0             	movzbl %al,%edx
f0104a25:	83 e8 23             	sub    $0x23,%eax
f0104a28:	3c 55                	cmp    $0x55,%al
f0104a2a:	0f 87 d3 03 00 00    	ja     f0104e03 <vprintfmt+0x443>
f0104a30:	0f b6 c0             	movzbl %al,%eax
f0104a33:	ff 24 85 60 75 10 f0 	jmp    *-0xfef8aa0(,%eax,4)
f0104a3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104a3d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104a41:	eb d6                	jmp    f0104a19 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a4b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104a4e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104a51:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104a55:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104a58:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104a5b:	83 f9 09             	cmp    $0x9,%ecx
f0104a5e:	77 3f                	ja     f0104a9f <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104a60:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104a63:	eb e9                	jmp    f0104a4e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104a65:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a68:	8b 00                	mov    (%eax),%eax
f0104a6a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104a6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a70:	8d 40 04             	lea    0x4(%eax),%eax
f0104a73:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104a79:	eb 2a                	jmp    f0104aa5 <vprintfmt+0xe5>
f0104a7b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a7e:	85 c0                	test   %eax,%eax
f0104a80:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a85:	0f 49 d0             	cmovns %eax,%edx
f0104a88:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a8b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a8e:	eb 89                	jmp    f0104a19 <vprintfmt+0x59>
f0104a90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104a93:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104a9a:	e9 7a ff ff ff       	jmp    f0104a19 <vprintfmt+0x59>
f0104a9f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104aa2:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104aa5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104aa9:	0f 89 6a ff ff ff    	jns    f0104a19 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104aaf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104ab2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ab5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104abc:	e9 58 ff ff ff       	jmp    f0104a19 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104ac1:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ac4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104ac7:	e9 4d ff ff ff       	jmp    f0104a19 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104acc:	8b 45 14             	mov    0x14(%ebp),%eax
f0104acf:	8d 78 04             	lea    0x4(%eax),%edi
f0104ad2:	83 ec 08             	sub    $0x8,%esp
f0104ad5:	53                   	push   %ebx
f0104ad6:	ff 30                	pushl  (%eax)
f0104ad8:	ff d6                	call   *%esi
			break;
f0104ada:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104add:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ae0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104ae3:	e9 fe fe ff ff       	jmp    f01049e6 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104ae8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104aeb:	8d 78 04             	lea    0x4(%eax),%edi
f0104aee:	8b 00                	mov    (%eax),%eax
f0104af0:	99                   	cltd   
f0104af1:	31 d0                	xor    %edx,%eax
f0104af3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104af5:	83 f8 08             	cmp    $0x8,%eax
f0104af8:	7f 0b                	jg     f0104b05 <vprintfmt+0x145>
f0104afa:	8b 14 85 c0 76 10 f0 	mov    -0xfef8940(,%eax,4),%edx
f0104b01:	85 d2                	test   %edx,%edx
f0104b03:	75 1b                	jne    f0104b20 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0104b05:	50                   	push   %eax
f0104b06:	68 ae 74 10 f0       	push   $0xf01074ae
f0104b0b:	53                   	push   %ebx
f0104b0c:	56                   	push   %esi
f0104b0d:	e8 91 fe ff ff       	call   f01049a3 <printfmt>
f0104b12:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104b15:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b18:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104b1b:	e9 c6 fe ff ff       	jmp    f01049e6 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104b20:	52                   	push   %edx
f0104b21:	68 81 6c 10 f0       	push   $0xf0106c81
f0104b26:	53                   	push   %ebx
f0104b27:	56                   	push   %esi
f0104b28:	e8 76 fe ff ff       	call   f01049a3 <printfmt>
f0104b2d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104b30:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b33:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b36:	e9 ab fe ff ff       	jmp    f01049e6 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104b3b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b3e:	83 c0 04             	add    $0x4,%eax
f0104b41:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104b44:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b47:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104b49:	85 ff                	test   %edi,%edi
f0104b4b:	b8 a7 74 10 f0       	mov    $0xf01074a7,%eax
f0104b50:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104b53:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104b57:	0f 8e 94 00 00 00    	jle    f0104bf1 <vprintfmt+0x231>
f0104b5d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104b61:	0f 84 98 00 00 00    	je     f0104bff <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b67:	83 ec 08             	sub    $0x8,%esp
f0104b6a:	ff 75 d0             	pushl  -0x30(%ebp)
f0104b6d:	57                   	push   %edi
f0104b6e:	e8 0c 04 00 00       	call   f0104f7f <strnlen>
f0104b73:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104b76:	29 c1                	sub    %eax,%ecx
f0104b78:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0104b7b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104b7e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104b82:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b85:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104b88:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b8a:	eb 0f                	jmp    f0104b9b <vprintfmt+0x1db>
					putch(padc, putdat);
f0104b8c:	83 ec 08             	sub    $0x8,%esp
f0104b8f:	53                   	push   %ebx
f0104b90:	ff 75 e0             	pushl  -0x20(%ebp)
f0104b93:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104b95:	83 ef 01             	sub    $0x1,%edi
f0104b98:	83 c4 10             	add    $0x10,%esp
f0104b9b:	85 ff                	test   %edi,%edi
f0104b9d:	7f ed                	jg     f0104b8c <vprintfmt+0x1cc>
f0104b9f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104ba2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0104ba5:	85 c9                	test   %ecx,%ecx
f0104ba7:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bac:	0f 49 c1             	cmovns %ecx,%eax
f0104baf:	29 c1                	sub    %eax,%ecx
f0104bb1:	89 75 08             	mov    %esi,0x8(%ebp)
f0104bb4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104bb7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104bba:	89 cb                	mov    %ecx,%ebx
f0104bbc:	eb 4d                	jmp    f0104c0b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104bbe:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104bc2:	74 1b                	je     f0104bdf <vprintfmt+0x21f>
f0104bc4:	0f be c0             	movsbl %al,%eax
f0104bc7:	83 e8 20             	sub    $0x20,%eax
f0104bca:	83 f8 5e             	cmp    $0x5e,%eax
f0104bcd:	76 10                	jbe    f0104bdf <vprintfmt+0x21f>
					putch('?', putdat);
f0104bcf:	83 ec 08             	sub    $0x8,%esp
f0104bd2:	ff 75 0c             	pushl  0xc(%ebp)
f0104bd5:	6a 3f                	push   $0x3f
f0104bd7:	ff 55 08             	call   *0x8(%ebp)
f0104bda:	83 c4 10             	add    $0x10,%esp
f0104bdd:	eb 0d                	jmp    f0104bec <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0104bdf:	83 ec 08             	sub    $0x8,%esp
f0104be2:	ff 75 0c             	pushl  0xc(%ebp)
f0104be5:	52                   	push   %edx
f0104be6:	ff 55 08             	call   *0x8(%ebp)
f0104be9:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104bec:	83 eb 01             	sub    $0x1,%ebx
f0104bef:	eb 1a                	jmp    f0104c0b <vprintfmt+0x24b>
f0104bf1:	89 75 08             	mov    %esi,0x8(%ebp)
f0104bf4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104bf7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104bfa:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104bfd:	eb 0c                	jmp    f0104c0b <vprintfmt+0x24b>
f0104bff:	89 75 08             	mov    %esi,0x8(%ebp)
f0104c02:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104c05:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104c08:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104c0b:	83 c7 01             	add    $0x1,%edi
f0104c0e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104c12:	0f be d0             	movsbl %al,%edx
f0104c15:	85 d2                	test   %edx,%edx
f0104c17:	74 23                	je     f0104c3c <vprintfmt+0x27c>
f0104c19:	85 f6                	test   %esi,%esi
f0104c1b:	78 a1                	js     f0104bbe <vprintfmt+0x1fe>
f0104c1d:	83 ee 01             	sub    $0x1,%esi
f0104c20:	79 9c                	jns    f0104bbe <vprintfmt+0x1fe>
f0104c22:	89 df                	mov    %ebx,%edi
f0104c24:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c2a:	eb 18                	jmp    f0104c44 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104c2c:	83 ec 08             	sub    $0x8,%esp
f0104c2f:	53                   	push   %ebx
f0104c30:	6a 20                	push   $0x20
f0104c32:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104c34:	83 ef 01             	sub    $0x1,%edi
f0104c37:	83 c4 10             	add    $0x10,%esp
f0104c3a:	eb 08                	jmp    f0104c44 <vprintfmt+0x284>
f0104c3c:	89 df                	mov    %ebx,%edi
f0104c3e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c41:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c44:	85 ff                	test   %edi,%edi
f0104c46:	7f e4                	jg     f0104c2c <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104c48:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104c4b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c4e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c51:	e9 90 fd ff ff       	jmp    f01049e6 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104c56:	83 f9 01             	cmp    $0x1,%ecx
f0104c59:	7e 19                	jle    f0104c74 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0104c5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c5e:	8b 50 04             	mov    0x4(%eax),%edx
f0104c61:	8b 00                	mov    (%eax),%eax
f0104c63:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c66:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104c69:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c6c:	8d 40 08             	lea    0x8(%eax),%eax
f0104c6f:	89 45 14             	mov    %eax,0x14(%ebp)
f0104c72:	eb 38                	jmp    f0104cac <vprintfmt+0x2ec>
	else if (lflag)
f0104c74:	85 c9                	test   %ecx,%ecx
f0104c76:	74 1b                	je     f0104c93 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0104c78:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c7b:	8b 00                	mov    (%eax),%eax
f0104c7d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c80:	89 c1                	mov    %eax,%ecx
f0104c82:	c1 f9 1f             	sar    $0x1f,%ecx
f0104c85:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104c88:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c8b:	8d 40 04             	lea    0x4(%eax),%eax
f0104c8e:	89 45 14             	mov    %eax,0x14(%ebp)
f0104c91:	eb 19                	jmp    f0104cac <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0104c93:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c96:	8b 00                	mov    (%eax),%eax
f0104c98:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c9b:	89 c1                	mov    %eax,%ecx
f0104c9d:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ca0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104ca3:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ca6:	8d 40 04             	lea    0x4(%eax),%eax
f0104ca9:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104cac:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104caf:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104cb2:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104cb7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104cbb:	0f 89 0e 01 00 00    	jns    f0104dcf <vprintfmt+0x40f>
				putch('-', putdat);
f0104cc1:	83 ec 08             	sub    $0x8,%esp
f0104cc4:	53                   	push   %ebx
f0104cc5:	6a 2d                	push   $0x2d
f0104cc7:	ff d6                	call   *%esi
				num = -(long long) num;
f0104cc9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104ccc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104ccf:	f7 da                	neg    %edx
f0104cd1:	83 d1 00             	adc    $0x0,%ecx
f0104cd4:	f7 d9                	neg    %ecx
f0104cd6:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104cd9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104cde:	e9 ec 00 00 00       	jmp    f0104dcf <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104ce3:	83 f9 01             	cmp    $0x1,%ecx
f0104ce6:	7e 18                	jle    f0104d00 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0104ce8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ceb:	8b 10                	mov    (%eax),%edx
f0104ced:	8b 48 04             	mov    0x4(%eax),%ecx
f0104cf0:	8d 40 08             	lea    0x8(%eax),%eax
f0104cf3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104cf6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104cfb:	e9 cf 00 00 00       	jmp    f0104dcf <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104d00:	85 c9                	test   %ecx,%ecx
f0104d02:	74 1a                	je     f0104d1e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0104d04:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d07:	8b 10                	mov    (%eax),%edx
f0104d09:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d0e:	8d 40 04             	lea    0x4(%eax),%eax
f0104d11:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104d14:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104d19:	e9 b1 00 00 00       	jmp    f0104dcf <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104d1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d21:	8b 10                	mov    (%eax),%edx
f0104d23:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d28:	8d 40 04             	lea    0x4(%eax),%eax
f0104d2b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0104d2e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104d33:	e9 97 00 00 00       	jmp    f0104dcf <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0104d38:	83 ec 08             	sub    $0x8,%esp
f0104d3b:	53                   	push   %ebx
f0104d3c:	6a 58                	push   $0x58
f0104d3e:	ff d6                	call   *%esi
			putch('X', putdat);
f0104d40:	83 c4 08             	add    $0x8,%esp
f0104d43:	53                   	push   %ebx
f0104d44:	6a 58                	push   $0x58
f0104d46:	ff d6                	call   *%esi
			putch('X', putdat);
f0104d48:	83 c4 08             	add    $0x8,%esp
f0104d4b:	53                   	push   %ebx
f0104d4c:	6a 58                	push   $0x58
f0104d4e:	ff d6                	call   *%esi
			break;
f0104d50:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0104d56:	e9 8b fc ff ff       	jmp    f01049e6 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0104d5b:	83 ec 08             	sub    $0x8,%esp
f0104d5e:	53                   	push   %ebx
f0104d5f:	6a 30                	push   $0x30
f0104d61:	ff d6                	call   *%esi
			putch('x', putdat);
f0104d63:	83 c4 08             	add    $0x8,%esp
f0104d66:	53                   	push   %ebx
f0104d67:	6a 78                	push   $0x78
f0104d69:	ff d6                	call   *%esi
			num = (unsigned long long)
f0104d6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d6e:	8b 10                	mov    (%eax),%edx
f0104d70:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104d75:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104d78:	8d 40 04             	lea    0x4(%eax),%eax
f0104d7b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d7e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104d83:	eb 4a                	jmp    f0104dcf <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104d85:	83 f9 01             	cmp    $0x1,%ecx
f0104d88:	7e 15                	jle    f0104d9f <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0104d8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d8d:	8b 10                	mov    (%eax),%edx
f0104d8f:	8b 48 04             	mov    0x4(%eax),%ecx
f0104d92:	8d 40 08             	lea    0x8(%eax),%eax
f0104d95:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104d98:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d9d:	eb 30                	jmp    f0104dcf <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0104d9f:	85 c9                	test   %ecx,%ecx
f0104da1:	74 17                	je     f0104dba <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0104da3:	8b 45 14             	mov    0x14(%ebp),%eax
f0104da6:	8b 10                	mov    (%eax),%edx
f0104da8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104dad:	8d 40 04             	lea    0x4(%eax),%eax
f0104db0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104db3:	b8 10 00 00 00       	mov    $0x10,%eax
f0104db8:	eb 15                	jmp    f0104dcf <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0104dba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dbd:	8b 10                	mov    (%eax),%edx
f0104dbf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104dc4:	8d 40 04             	lea    0x4(%eax),%eax
f0104dc7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0104dca:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104dcf:	83 ec 0c             	sub    $0xc,%esp
f0104dd2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104dd6:	57                   	push   %edi
f0104dd7:	ff 75 e0             	pushl  -0x20(%ebp)
f0104dda:	50                   	push   %eax
f0104ddb:	51                   	push   %ecx
f0104ddc:	52                   	push   %edx
f0104ddd:	89 da                	mov    %ebx,%edx
f0104ddf:	89 f0                	mov    %esi,%eax
f0104de1:	e8 f1 fa ff ff       	call   f01048d7 <printnum>
			break;
f0104de6:	83 c4 20             	add    $0x20,%esp
f0104de9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dec:	e9 f5 fb ff ff       	jmp    f01049e6 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104df1:	83 ec 08             	sub    $0x8,%esp
f0104df4:	53                   	push   %ebx
f0104df5:	52                   	push   %edx
f0104df6:	ff d6                	call   *%esi
			break;
f0104df8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104dfe:	e9 e3 fb ff ff       	jmp    f01049e6 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104e03:	83 ec 08             	sub    $0x8,%esp
f0104e06:	53                   	push   %ebx
f0104e07:	6a 25                	push   $0x25
f0104e09:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104e0b:	83 c4 10             	add    $0x10,%esp
f0104e0e:	eb 03                	jmp    f0104e13 <vprintfmt+0x453>
f0104e10:	83 ef 01             	sub    $0x1,%edi
f0104e13:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104e17:	75 f7                	jne    f0104e10 <vprintfmt+0x450>
f0104e19:	e9 c8 fb ff ff       	jmp    f01049e6 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104e1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e21:	5b                   	pop    %ebx
f0104e22:	5e                   	pop    %esi
f0104e23:	5f                   	pop    %edi
f0104e24:	5d                   	pop    %ebp
f0104e25:	c3                   	ret    

f0104e26 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104e26:	55                   	push   %ebp
f0104e27:	89 e5                	mov    %esp,%ebp
f0104e29:	83 ec 18             	sub    $0x18,%esp
f0104e2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e2f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104e32:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104e35:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104e39:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104e3c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104e43:	85 c0                	test   %eax,%eax
f0104e45:	74 26                	je     f0104e6d <vsnprintf+0x47>
f0104e47:	85 d2                	test   %edx,%edx
f0104e49:	7e 22                	jle    f0104e6d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104e4b:	ff 75 14             	pushl  0x14(%ebp)
f0104e4e:	ff 75 10             	pushl  0x10(%ebp)
f0104e51:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104e54:	50                   	push   %eax
f0104e55:	68 86 49 10 f0       	push   $0xf0104986
f0104e5a:	e8 61 fb ff ff       	call   f01049c0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104e5f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104e62:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104e65:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e68:	83 c4 10             	add    $0x10,%esp
f0104e6b:	eb 05                	jmp    f0104e72 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104e6d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104e72:	c9                   	leave  
f0104e73:	c3                   	ret    

f0104e74 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104e74:	55                   	push   %ebp
f0104e75:	89 e5                	mov    %esp,%ebp
f0104e77:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104e7a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104e7d:	50                   	push   %eax
f0104e7e:	ff 75 10             	pushl  0x10(%ebp)
f0104e81:	ff 75 0c             	pushl  0xc(%ebp)
f0104e84:	ff 75 08             	pushl  0x8(%ebp)
f0104e87:	e8 9a ff ff ff       	call   f0104e26 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104e8c:	c9                   	leave  
f0104e8d:	c3                   	ret    

f0104e8e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104e8e:	55                   	push   %ebp
f0104e8f:	89 e5                	mov    %esp,%ebp
f0104e91:	57                   	push   %edi
f0104e92:	56                   	push   %esi
f0104e93:	53                   	push   %ebx
f0104e94:	83 ec 0c             	sub    $0xc,%esp
f0104e97:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104e9a:	85 c0                	test   %eax,%eax
f0104e9c:	74 11                	je     f0104eaf <readline+0x21>
		cprintf("%s", prompt);
f0104e9e:	83 ec 08             	sub    $0x8,%esp
f0104ea1:	50                   	push   %eax
f0104ea2:	68 81 6c 10 f0       	push   $0xf0106c81
f0104ea7:	e8 01 e7 ff ff       	call   f01035ad <cprintf>
f0104eac:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104eaf:	83 ec 0c             	sub    $0xc,%esp
f0104eb2:	6a 00                	push   $0x0
f0104eb4:	e8 cc b8 ff ff       	call   f0100785 <iscons>
f0104eb9:	89 c7                	mov    %eax,%edi
f0104ebb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104ebe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104ec3:	e8 ac b8 ff ff       	call   f0100774 <getchar>
f0104ec8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104eca:	85 c0                	test   %eax,%eax
f0104ecc:	79 18                	jns    f0104ee6 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104ece:	83 ec 08             	sub    $0x8,%esp
f0104ed1:	50                   	push   %eax
f0104ed2:	68 e4 76 10 f0       	push   $0xf01076e4
f0104ed7:	e8 d1 e6 ff ff       	call   f01035ad <cprintf>
			return NULL;
f0104edc:	83 c4 10             	add    $0x10,%esp
f0104edf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ee4:	eb 79                	jmp    f0104f5f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ee6:	83 f8 08             	cmp    $0x8,%eax
f0104ee9:	0f 94 c2             	sete   %dl
f0104eec:	83 f8 7f             	cmp    $0x7f,%eax
f0104eef:	0f 94 c0             	sete   %al
f0104ef2:	08 c2                	or     %al,%dl
f0104ef4:	74 1a                	je     f0104f10 <readline+0x82>
f0104ef6:	85 f6                	test   %esi,%esi
f0104ef8:	7e 16                	jle    f0104f10 <readline+0x82>
			if (echoing)
f0104efa:	85 ff                	test   %edi,%edi
f0104efc:	74 0d                	je     f0104f0b <readline+0x7d>
				cputchar('\b');
f0104efe:	83 ec 0c             	sub    $0xc,%esp
f0104f01:	6a 08                	push   $0x8
f0104f03:	e8 5c b8 ff ff       	call   f0100764 <cputchar>
f0104f08:	83 c4 10             	add    $0x10,%esp
			i--;
f0104f0b:	83 ee 01             	sub    $0x1,%esi
f0104f0e:	eb b3                	jmp    f0104ec3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104f10:	83 fb 1f             	cmp    $0x1f,%ebx
f0104f13:	7e 23                	jle    f0104f38 <readline+0xaa>
f0104f15:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104f1b:	7f 1b                	jg     f0104f38 <readline+0xaa>
			if (echoing)
f0104f1d:	85 ff                	test   %edi,%edi
f0104f1f:	74 0c                	je     f0104f2d <readline+0x9f>
				cputchar(c);
f0104f21:	83 ec 0c             	sub    $0xc,%esp
f0104f24:	53                   	push   %ebx
f0104f25:	e8 3a b8 ff ff       	call   f0100764 <cputchar>
f0104f2a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104f2d:	88 9e 80 ea 22 f0    	mov    %bl,-0xfdd1580(%esi)
f0104f33:	8d 76 01             	lea    0x1(%esi),%esi
f0104f36:	eb 8b                	jmp    f0104ec3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104f38:	83 fb 0a             	cmp    $0xa,%ebx
f0104f3b:	74 05                	je     f0104f42 <readline+0xb4>
f0104f3d:	83 fb 0d             	cmp    $0xd,%ebx
f0104f40:	75 81                	jne    f0104ec3 <readline+0x35>
			if (echoing)
f0104f42:	85 ff                	test   %edi,%edi
f0104f44:	74 0d                	je     f0104f53 <readline+0xc5>
				cputchar('\n');
f0104f46:	83 ec 0c             	sub    $0xc,%esp
f0104f49:	6a 0a                	push   $0xa
f0104f4b:	e8 14 b8 ff ff       	call   f0100764 <cputchar>
f0104f50:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104f53:	c6 86 80 ea 22 f0 00 	movb   $0x0,-0xfdd1580(%esi)
			return buf;
f0104f5a:	b8 80 ea 22 f0       	mov    $0xf022ea80,%eax
		}
	}
}
f0104f5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f62:	5b                   	pop    %ebx
f0104f63:	5e                   	pop    %esi
f0104f64:	5f                   	pop    %edi
f0104f65:	5d                   	pop    %ebp
f0104f66:	c3                   	ret    

f0104f67 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104f67:	55                   	push   %ebp
f0104f68:	89 e5                	mov    %esp,%ebp
f0104f6a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104f6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f72:	eb 03                	jmp    f0104f77 <strlen+0x10>
		n++;
f0104f74:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104f77:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104f7b:	75 f7                	jne    f0104f74 <strlen+0xd>
		n++;
	return n;
}
f0104f7d:	5d                   	pop    %ebp
f0104f7e:	c3                   	ret    

f0104f7f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104f7f:	55                   	push   %ebp
f0104f80:	89 e5                	mov    %esp,%ebp
f0104f82:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f85:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f88:	ba 00 00 00 00       	mov    $0x0,%edx
f0104f8d:	eb 03                	jmp    f0104f92 <strnlen+0x13>
		n++;
f0104f8f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f92:	39 c2                	cmp    %eax,%edx
f0104f94:	74 08                	je     f0104f9e <strnlen+0x1f>
f0104f96:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104f9a:	75 f3                	jne    f0104f8f <strnlen+0x10>
f0104f9c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104f9e:	5d                   	pop    %ebp
f0104f9f:	c3                   	ret    

f0104fa0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104fa0:	55                   	push   %ebp
f0104fa1:	89 e5                	mov    %esp,%ebp
f0104fa3:	53                   	push   %ebx
f0104fa4:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fa7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104faa:	89 c2                	mov    %eax,%edx
f0104fac:	83 c2 01             	add    $0x1,%edx
f0104faf:	83 c1 01             	add    $0x1,%ecx
f0104fb2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104fb6:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104fb9:	84 db                	test   %bl,%bl
f0104fbb:	75 ef                	jne    f0104fac <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104fbd:	5b                   	pop    %ebx
f0104fbe:	5d                   	pop    %ebp
f0104fbf:	c3                   	ret    

f0104fc0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104fc0:	55                   	push   %ebp
f0104fc1:	89 e5                	mov    %esp,%ebp
f0104fc3:	53                   	push   %ebx
f0104fc4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104fc7:	53                   	push   %ebx
f0104fc8:	e8 9a ff ff ff       	call   f0104f67 <strlen>
f0104fcd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104fd0:	ff 75 0c             	pushl  0xc(%ebp)
f0104fd3:	01 d8                	add    %ebx,%eax
f0104fd5:	50                   	push   %eax
f0104fd6:	e8 c5 ff ff ff       	call   f0104fa0 <strcpy>
	return dst;
}
f0104fdb:	89 d8                	mov    %ebx,%eax
f0104fdd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104fe0:	c9                   	leave  
f0104fe1:	c3                   	ret    

f0104fe2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104fe2:	55                   	push   %ebp
f0104fe3:	89 e5                	mov    %esp,%ebp
f0104fe5:	56                   	push   %esi
f0104fe6:	53                   	push   %ebx
f0104fe7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104fed:	89 f3                	mov    %esi,%ebx
f0104fef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ff2:	89 f2                	mov    %esi,%edx
f0104ff4:	eb 0f                	jmp    f0105005 <strncpy+0x23>
		*dst++ = *src;
f0104ff6:	83 c2 01             	add    $0x1,%edx
f0104ff9:	0f b6 01             	movzbl (%ecx),%eax
f0104ffc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104fff:	80 39 01             	cmpb   $0x1,(%ecx)
f0105002:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105005:	39 da                	cmp    %ebx,%edx
f0105007:	75 ed                	jne    f0104ff6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105009:	89 f0                	mov    %esi,%eax
f010500b:	5b                   	pop    %ebx
f010500c:	5e                   	pop    %esi
f010500d:	5d                   	pop    %ebp
f010500e:	c3                   	ret    

f010500f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010500f:	55                   	push   %ebp
f0105010:	89 e5                	mov    %esp,%ebp
f0105012:	56                   	push   %esi
f0105013:	53                   	push   %ebx
f0105014:	8b 75 08             	mov    0x8(%ebp),%esi
f0105017:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010501a:	8b 55 10             	mov    0x10(%ebp),%edx
f010501d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010501f:	85 d2                	test   %edx,%edx
f0105021:	74 21                	je     f0105044 <strlcpy+0x35>
f0105023:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105027:	89 f2                	mov    %esi,%edx
f0105029:	eb 09                	jmp    f0105034 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010502b:	83 c2 01             	add    $0x1,%edx
f010502e:	83 c1 01             	add    $0x1,%ecx
f0105031:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105034:	39 c2                	cmp    %eax,%edx
f0105036:	74 09                	je     f0105041 <strlcpy+0x32>
f0105038:	0f b6 19             	movzbl (%ecx),%ebx
f010503b:	84 db                	test   %bl,%bl
f010503d:	75 ec                	jne    f010502b <strlcpy+0x1c>
f010503f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105041:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105044:	29 f0                	sub    %esi,%eax
}
f0105046:	5b                   	pop    %ebx
f0105047:	5e                   	pop    %esi
f0105048:	5d                   	pop    %ebp
f0105049:	c3                   	ret    

f010504a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010504a:	55                   	push   %ebp
f010504b:	89 e5                	mov    %esp,%ebp
f010504d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105050:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105053:	eb 06                	jmp    f010505b <strcmp+0x11>
		p++, q++;
f0105055:	83 c1 01             	add    $0x1,%ecx
f0105058:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010505b:	0f b6 01             	movzbl (%ecx),%eax
f010505e:	84 c0                	test   %al,%al
f0105060:	74 04                	je     f0105066 <strcmp+0x1c>
f0105062:	3a 02                	cmp    (%edx),%al
f0105064:	74 ef                	je     f0105055 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105066:	0f b6 c0             	movzbl %al,%eax
f0105069:	0f b6 12             	movzbl (%edx),%edx
f010506c:	29 d0                	sub    %edx,%eax
}
f010506e:	5d                   	pop    %ebp
f010506f:	c3                   	ret    

f0105070 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105070:	55                   	push   %ebp
f0105071:	89 e5                	mov    %esp,%ebp
f0105073:	53                   	push   %ebx
f0105074:	8b 45 08             	mov    0x8(%ebp),%eax
f0105077:	8b 55 0c             	mov    0xc(%ebp),%edx
f010507a:	89 c3                	mov    %eax,%ebx
f010507c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010507f:	eb 06                	jmp    f0105087 <strncmp+0x17>
		n--, p++, q++;
f0105081:	83 c0 01             	add    $0x1,%eax
f0105084:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105087:	39 d8                	cmp    %ebx,%eax
f0105089:	74 15                	je     f01050a0 <strncmp+0x30>
f010508b:	0f b6 08             	movzbl (%eax),%ecx
f010508e:	84 c9                	test   %cl,%cl
f0105090:	74 04                	je     f0105096 <strncmp+0x26>
f0105092:	3a 0a                	cmp    (%edx),%cl
f0105094:	74 eb                	je     f0105081 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105096:	0f b6 00             	movzbl (%eax),%eax
f0105099:	0f b6 12             	movzbl (%edx),%edx
f010509c:	29 d0                	sub    %edx,%eax
f010509e:	eb 05                	jmp    f01050a5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01050a0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01050a5:	5b                   	pop    %ebx
f01050a6:	5d                   	pop    %ebp
f01050a7:	c3                   	ret    

f01050a8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01050a8:	55                   	push   %ebp
f01050a9:	89 e5                	mov    %esp,%ebp
f01050ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01050ae:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01050b2:	eb 07                	jmp    f01050bb <strchr+0x13>
		if (*s == c)
f01050b4:	38 ca                	cmp    %cl,%dl
f01050b6:	74 0f                	je     f01050c7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01050b8:	83 c0 01             	add    $0x1,%eax
f01050bb:	0f b6 10             	movzbl (%eax),%edx
f01050be:	84 d2                	test   %dl,%dl
f01050c0:	75 f2                	jne    f01050b4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01050c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01050c7:	5d                   	pop    %ebp
f01050c8:	c3                   	ret    

f01050c9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01050c9:	55                   	push   %ebp
f01050ca:	89 e5                	mov    %esp,%ebp
f01050cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01050cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01050d3:	eb 03                	jmp    f01050d8 <strfind+0xf>
f01050d5:	83 c0 01             	add    $0x1,%eax
f01050d8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01050db:	38 ca                	cmp    %cl,%dl
f01050dd:	74 04                	je     f01050e3 <strfind+0x1a>
f01050df:	84 d2                	test   %dl,%dl
f01050e1:	75 f2                	jne    f01050d5 <strfind+0xc>
			break;
	return (char *) s;
}
f01050e3:	5d                   	pop    %ebp
f01050e4:	c3                   	ret    

f01050e5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01050e5:	55                   	push   %ebp
f01050e6:	89 e5                	mov    %esp,%ebp
f01050e8:	57                   	push   %edi
f01050e9:	56                   	push   %esi
f01050ea:	53                   	push   %ebx
f01050eb:	8b 7d 08             	mov    0x8(%ebp),%edi
f01050ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01050f1:	85 c9                	test   %ecx,%ecx
f01050f3:	74 36                	je     f010512b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01050f5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01050fb:	75 28                	jne    f0105125 <memset+0x40>
f01050fd:	f6 c1 03             	test   $0x3,%cl
f0105100:	75 23                	jne    f0105125 <memset+0x40>
		c &= 0xFF;
f0105102:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105106:	89 d3                	mov    %edx,%ebx
f0105108:	c1 e3 08             	shl    $0x8,%ebx
f010510b:	89 d6                	mov    %edx,%esi
f010510d:	c1 e6 18             	shl    $0x18,%esi
f0105110:	89 d0                	mov    %edx,%eax
f0105112:	c1 e0 10             	shl    $0x10,%eax
f0105115:	09 f0                	or     %esi,%eax
f0105117:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0105119:	89 d8                	mov    %ebx,%eax
f010511b:	09 d0                	or     %edx,%eax
f010511d:	c1 e9 02             	shr    $0x2,%ecx
f0105120:	fc                   	cld    
f0105121:	f3 ab                	rep stos %eax,%es:(%edi)
f0105123:	eb 06                	jmp    f010512b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105125:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105128:	fc                   	cld    
f0105129:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010512b:	89 f8                	mov    %edi,%eax
f010512d:	5b                   	pop    %ebx
f010512e:	5e                   	pop    %esi
f010512f:	5f                   	pop    %edi
f0105130:	5d                   	pop    %ebp
f0105131:	c3                   	ret    

f0105132 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105132:	55                   	push   %ebp
f0105133:	89 e5                	mov    %esp,%ebp
f0105135:	57                   	push   %edi
f0105136:	56                   	push   %esi
f0105137:	8b 45 08             	mov    0x8(%ebp),%eax
f010513a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010513d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105140:	39 c6                	cmp    %eax,%esi
f0105142:	73 35                	jae    f0105179 <memmove+0x47>
f0105144:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105147:	39 d0                	cmp    %edx,%eax
f0105149:	73 2e                	jae    f0105179 <memmove+0x47>
		s += n;
		d += n;
f010514b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010514e:	89 d6                	mov    %edx,%esi
f0105150:	09 fe                	or     %edi,%esi
f0105152:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105158:	75 13                	jne    f010516d <memmove+0x3b>
f010515a:	f6 c1 03             	test   $0x3,%cl
f010515d:	75 0e                	jne    f010516d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010515f:	83 ef 04             	sub    $0x4,%edi
f0105162:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105165:	c1 e9 02             	shr    $0x2,%ecx
f0105168:	fd                   	std    
f0105169:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010516b:	eb 09                	jmp    f0105176 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010516d:	83 ef 01             	sub    $0x1,%edi
f0105170:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105173:	fd                   	std    
f0105174:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105176:	fc                   	cld    
f0105177:	eb 1d                	jmp    f0105196 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105179:	89 f2                	mov    %esi,%edx
f010517b:	09 c2                	or     %eax,%edx
f010517d:	f6 c2 03             	test   $0x3,%dl
f0105180:	75 0f                	jne    f0105191 <memmove+0x5f>
f0105182:	f6 c1 03             	test   $0x3,%cl
f0105185:	75 0a                	jne    f0105191 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0105187:	c1 e9 02             	shr    $0x2,%ecx
f010518a:	89 c7                	mov    %eax,%edi
f010518c:	fc                   	cld    
f010518d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010518f:	eb 05                	jmp    f0105196 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105191:	89 c7                	mov    %eax,%edi
f0105193:	fc                   	cld    
f0105194:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105196:	5e                   	pop    %esi
f0105197:	5f                   	pop    %edi
f0105198:	5d                   	pop    %ebp
f0105199:	c3                   	ret    

f010519a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010519a:	55                   	push   %ebp
f010519b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010519d:	ff 75 10             	pushl  0x10(%ebp)
f01051a0:	ff 75 0c             	pushl  0xc(%ebp)
f01051a3:	ff 75 08             	pushl  0x8(%ebp)
f01051a6:	e8 87 ff ff ff       	call   f0105132 <memmove>
}
f01051ab:	c9                   	leave  
f01051ac:	c3                   	ret    

f01051ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01051ad:	55                   	push   %ebp
f01051ae:	89 e5                	mov    %esp,%ebp
f01051b0:	56                   	push   %esi
f01051b1:	53                   	push   %ebx
f01051b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01051b5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01051b8:	89 c6                	mov    %eax,%esi
f01051ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01051bd:	eb 1a                	jmp    f01051d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01051bf:	0f b6 08             	movzbl (%eax),%ecx
f01051c2:	0f b6 1a             	movzbl (%edx),%ebx
f01051c5:	38 d9                	cmp    %bl,%cl
f01051c7:	74 0a                	je     f01051d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01051c9:	0f b6 c1             	movzbl %cl,%eax
f01051cc:	0f b6 db             	movzbl %bl,%ebx
f01051cf:	29 d8                	sub    %ebx,%eax
f01051d1:	eb 0f                	jmp    f01051e2 <memcmp+0x35>
		s1++, s2++;
f01051d3:	83 c0 01             	add    $0x1,%eax
f01051d6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01051d9:	39 f0                	cmp    %esi,%eax
f01051db:	75 e2                	jne    f01051bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01051dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01051e2:	5b                   	pop    %ebx
f01051e3:	5e                   	pop    %esi
f01051e4:	5d                   	pop    %ebp
f01051e5:	c3                   	ret    

f01051e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01051e6:	55                   	push   %ebp
f01051e7:	89 e5                	mov    %esp,%ebp
f01051e9:	53                   	push   %ebx
f01051ea:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01051ed:	89 c1                	mov    %eax,%ecx
f01051ef:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01051f2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01051f6:	eb 0a                	jmp    f0105202 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01051f8:	0f b6 10             	movzbl (%eax),%edx
f01051fb:	39 da                	cmp    %ebx,%edx
f01051fd:	74 07                	je     f0105206 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01051ff:	83 c0 01             	add    $0x1,%eax
f0105202:	39 c8                	cmp    %ecx,%eax
f0105204:	72 f2                	jb     f01051f8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105206:	5b                   	pop    %ebx
f0105207:	5d                   	pop    %ebp
f0105208:	c3                   	ret    

f0105209 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105209:	55                   	push   %ebp
f010520a:	89 e5                	mov    %esp,%ebp
f010520c:	57                   	push   %edi
f010520d:	56                   	push   %esi
f010520e:	53                   	push   %ebx
f010520f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105212:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105215:	eb 03                	jmp    f010521a <strtol+0x11>
		s++;
f0105217:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010521a:	0f b6 01             	movzbl (%ecx),%eax
f010521d:	3c 20                	cmp    $0x20,%al
f010521f:	74 f6                	je     f0105217 <strtol+0xe>
f0105221:	3c 09                	cmp    $0x9,%al
f0105223:	74 f2                	je     f0105217 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105225:	3c 2b                	cmp    $0x2b,%al
f0105227:	75 0a                	jne    f0105233 <strtol+0x2a>
		s++;
f0105229:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010522c:	bf 00 00 00 00       	mov    $0x0,%edi
f0105231:	eb 11                	jmp    f0105244 <strtol+0x3b>
f0105233:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105238:	3c 2d                	cmp    $0x2d,%al
f010523a:	75 08                	jne    f0105244 <strtol+0x3b>
		s++, neg = 1;
f010523c:	83 c1 01             	add    $0x1,%ecx
f010523f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105244:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010524a:	75 15                	jne    f0105261 <strtol+0x58>
f010524c:	80 39 30             	cmpb   $0x30,(%ecx)
f010524f:	75 10                	jne    f0105261 <strtol+0x58>
f0105251:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105255:	75 7c                	jne    f01052d3 <strtol+0xca>
		s += 2, base = 16;
f0105257:	83 c1 02             	add    $0x2,%ecx
f010525a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010525f:	eb 16                	jmp    f0105277 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105261:	85 db                	test   %ebx,%ebx
f0105263:	75 12                	jne    f0105277 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105265:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010526a:	80 39 30             	cmpb   $0x30,(%ecx)
f010526d:	75 08                	jne    f0105277 <strtol+0x6e>
		s++, base = 8;
f010526f:	83 c1 01             	add    $0x1,%ecx
f0105272:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105277:	b8 00 00 00 00       	mov    $0x0,%eax
f010527c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010527f:	0f b6 11             	movzbl (%ecx),%edx
f0105282:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105285:	89 f3                	mov    %esi,%ebx
f0105287:	80 fb 09             	cmp    $0x9,%bl
f010528a:	77 08                	ja     f0105294 <strtol+0x8b>
			dig = *s - '0';
f010528c:	0f be d2             	movsbl %dl,%edx
f010528f:	83 ea 30             	sub    $0x30,%edx
f0105292:	eb 22                	jmp    f01052b6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105294:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105297:	89 f3                	mov    %esi,%ebx
f0105299:	80 fb 19             	cmp    $0x19,%bl
f010529c:	77 08                	ja     f01052a6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010529e:	0f be d2             	movsbl %dl,%edx
f01052a1:	83 ea 57             	sub    $0x57,%edx
f01052a4:	eb 10                	jmp    f01052b6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01052a6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01052a9:	89 f3                	mov    %esi,%ebx
f01052ab:	80 fb 19             	cmp    $0x19,%bl
f01052ae:	77 16                	ja     f01052c6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01052b0:	0f be d2             	movsbl %dl,%edx
f01052b3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01052b6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01052b9:	7d 0b                	jge    f01052c6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01052bb:	83 c1 01             	add    $0x1,%ecx
f01052be:	0f af 45 10          	imul   0x10(%ebp),%eax
f01052c2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01052c4:	eb b9                	jmp    f010527f <strtol+0x76>

	if (endptr)
f01052c6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01052ca:	74 0d                	je     f01052d9 <strtol+0xd0>
		*endptr = (char *) s;
f01052cc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01052cf:	89 0e                	mov    %ecx,(%esi)
f01052d1:	eb 06                	jmp    f01052d9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01052d3:	85 db                	test   %ebx,%ebx
f01052d5:	74 98                	je     f010526f <strtol+0x66>
f01052d7:	eb 9e                	jmp    f0105277 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01052d9:	89 c2                	mov    %eax,%edx
f01052db:	f7 da                	neg    %edx
f01052dd:	85 ff                	test   %edi,%edi
f01052df:	0f 45 c2             	cmovne %edx,%eax
}
f01052e2:	5b                   	pop    %ebx
f01052e3:	5e                   	pop    %esi
f01052e4:	5f                   	pop    %edi
f01052e5:	5d                   	pop    %ebp
f01052e6:	c3                   	ret    
f01052e7:	90                   	nop

f01052e8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01052e8:	fa                   	cli    

	xorw    %ax, %ax
f01052e9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01052eb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01052ed:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01052ef:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01052f1:	0f 01 16             	lgdtl  (%esi)
f01052f4:	74 70                	je     f0105366 <mpsearch1+0x3>
	movl    %cr0, %eax
f01052f6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01052f9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01052fd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105300:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105306:	08 00                	or     %al,(%eax)

f0105308 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105308:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f010530c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010530e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105310:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105312:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105316:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105318:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010531a:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f010531f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105322:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105325:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010532a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010532d:	8b 25 84 ee 22 f0    	mov    0xf022ee84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105333:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105338:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f010533d:	ff d0                	call   *%eax

f010533f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010533f:	eb fe                	jmp    f010533f <spin>
f0105341:	8d 76 00             	lea    0x0(%esi),%esi

f0105344 <gdt>:
	...
f010534c:	ff                   	(bad)  
f010534d:	ff 00                	incl   (%eax)
f010534f:	00 00                	add    %al,(%eax)
f0105351:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105358:	00                   	.byte 0x0
f0105359:	92                   	xchg   %eax,%edx
f010535a:	cf                   	iret   
	...

f010535c <gdtdesc>:
f010535c:	17                   	pop    %ss
f010535d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105362 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105362:	90                   	nop

f0105363 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105363:	55                   	push   %ebp
f0105364:	89 e5                	mov    %esp,%ebp
f0105366:	57                   	push   %edi
f0105367:	56                   	push   %esi
f0105368:	53                   	push   %ebx
f0105369:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010536c:	8b 0d 88 ee 22 f0    	mov    0xf022ee88,%ecx
f0105372:	89 c3                	mov    %eax,%ebx
f0105374:	c1 eb 0c             	shr    $0xc,%ebx
f0105377:	39 cb                	cmp    %ecx,%ebx
f0105379:	72 12                	jb     f010538d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010537b:	50                   	push   %eax
f010537c:	68 e4 5d 10 f0       	push   $0xf0105de4
f0105381:	6a 57                	push   $0x57
f0105383:	68 81 78 10 f0       	push   $0xf0107881
f0105388:	e8 b3 ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010538d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105393:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105395:	89 c2                	mov    %eax,%edx
f0105397:	c1 ea 0c             	shr    $0xc,%edx
f010539a:	39 ca                	cmp    %ecx,%edx
f010539c:	72 12                	jb     f01053b0 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010539e:	50                   	push   %eax
f010539f:	68 e4 5d 10 f0       	push   $0xf0105de4
f01053a4:	6a 57                	push   $0x57
f01053a6:	68 81 78 10 f0       	push   $0xf0107881
f01053ab:	e8 90 ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01053b0:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01053b6:	eb 2f                	jmp    f01053e7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01053b8:	83 ec 04             	sub    $0x4,%esp
f01053bb:	6a 04                	push   $0x4
f01053bd:	68 91 78 10 f0       	push   $0xf0107891
f01053c2:	53                   	push   %ebx
f01053c3:	e8 e5 fd ff ff       	call   f01051ad <memcmp>
f01053c8:	83 c4 10             	add    $0x10,%esp
f01053cb:	85 c0                	test   %eax,%eax
f01053cd:	75 15                	jne    f01053e4 <mpsearch1+0x81>
f01053cf:	89 da                	mov    %ebx,%edx
f01053d1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01053d4:	0f b6 0a             	movzbl (%edx),%ecx
f01053d7:	01 c8                	add    %ecx,%eax
f01053d9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01053dc:	39 d7                	cmp    %edx,%edi
f01053de:	75 f4                	jne    f01053d4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01053e0:	84 c0                	test   %al,%al
f01053e2:	74 0e                	je     f01053f2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01053e4:	83 c3 10             	add    $0x10,%ebx
f01053e7:	39 f3                	cmp    %esi,%ebx
f01053e9:	72 cd                	jb     f01053b8 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01053eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01053f0:	eb 02                	jmp    f01053f4 <mpsearch1+0x91>
f01053f2:	89 d8                	mov    %ebx,%eax
}
f01053f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01053f7:	5b                   	pop    %ebx
f01053f8:	5e                   	pop    %esi
f01053f9:	5f                   	pop    %edi
f01053fa:	5d                   	pop    %ebp
f01053fb:	c3                   	ret    

f01053fc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01053fc:	55                   	push   %ebp
f01053fd:	89 e5                	mov    %esp,%ebp
f01053ff:	57                   	push   %edi
f0105400:	56                   	push   %esi
f0105401:	53                   	push   %ebx
f0105402:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105405:	c7 05 c0 f3 22 f0 20 	movl   $0xf022f020,0xf022f3c0
f010540c:	f0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010540f:	83 3d 88 ee 22 f0 00 	cmpl   $0x0,0xf022ee88
f0105416:	75 16                	jne    f010542e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105418:	68 00 04 00 00       	push   $0x400
f010541d:	68 e4 5d 10 f0       	push   $0xf0105de4
f0105422:	6a 6f                	push   $0x6f
f0105424:	68 81 78 10 f0       	push   $0xf0107881
f0105429:	e8 12 ac ff ff       	call   f0100040 <_panic>

	static_assert(sizeof(*mp) == 16);

	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);
	cprintf("bda   %08x\n",bda);
f010542e:	83 ec 08             	sub    $0x8,%esp
f0105431:	68 00 04 00 f0       	push   $0xf0000400
f0105436:	68 96 78 10 f0       	push   $0xf0107896
f010543b:	e8 6d e1 ff ff       	call   f01035ad <cprintf>
	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105440:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105447:	83 c4 10             	add    $0x10,%esp
f010544a:	85 c0                	test   %eax,%eax
f010544c:	74 16                	je     f0105464 <mp_init+0x68>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010544e:	c1 e0 04             	shl    $0x4,%eax
f0105451:	ba 00 04 00 00       	mov    $0x400,%edx
f0105456:	e8 08 ff ff ff       	call   f0105363 <mpsearch1>
f010545b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010545e:	85 c0                	test   %eax,%eax
f0105460:	75 3c                	jne    f010549e <mp_init+0xa2>
f0105462:	eb 20                	jmp    f0105484 <mp_init+0x88>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105464:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010546b:	c1 e0 0a             	shl    $0xa,%eax
f010546e:	2d 00 04 00 00       	sub    $0x400,%eax
f0105473:	ba 00 04 00 00       	mov    $0x400,%edx
f0105478:	e8 e6 fe ff ff       	call   f0105363 <mpsearch1>
f010547d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105480:	85 c0                	test   %eax,%eax
f0105482:	75 1a                	jne    f010549e <mp_init+0xa2>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105484:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105489:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010548e:	e8 d0 fe ff ff       	call   f0105363 <mpsearch1>
f0105493:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105496:	85 c0                	test   %eax,%eax
f0105498:	0f 84 5d 02 00 00    	je     f01056fb <mp_init+0x2ff>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f010549e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01054a1:	8b 70 04             	mov    0x4(%eax),%esi
f01054a4:	85 f6                	test   %esi,%esi
f01054a6:	74 06                	je     f01054ae <mp_init+0xb2>
f01054a8:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01054ac:	74 15                	je     f01054c3 <mp_init+0xc7>
		cprintf("SMP: Default configurations not implemented\n");
f01054ae:	83 ec 0c             	sub    $0xc,%esp
f01054b1:	68 f4 76 10 f0       	push   $0xf01076f4
f01054b6:	e8 f2 e0 ff ff       	call   f01035ad <cprintf>
f01054bb:	83 c4 10             	add    $0x10,%esp
f01054be:	e9 38 02 00 00       	jmp    f01056fb <mp_init+0x2ff>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054c3:	89 f0                	mov    %esi,%eax
f01054c5:	c1 e8 0c             	shr    $0xc,%eax
f01054c8:	3b 05 88 ee 22 f0    	cmp    0xf022ee88,%eax
f01054ce:	72 15                	jb     f01054e5 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01054d0:	56                   	push   %esi
f01054d1:	68 e4 5d 10 f0       	push   $0xf0105de4
f01054d6:	68 90 00 00 00       	push   $0x90
f01054db:	68 81 78 10 f0       	push   $0xf0107881
f01054e0:	e8 5b ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01054e5:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01054eb:	83 ec 04             	sub    $0x4,%esp
f01054ee:	6a 04                	push   $0x4
f01054f0:	68 a2 78 10 f0       	push   $0xf01078a2
f01054f5:	53                   	push   %ebx
f01054f6:	e8 b2 fc ff ff       	call   f01051ad <memcmp>
f01054fb:	83 c4 10             	add    $0x10,%esp
f01054fe:	85 c0                	test   %eax,%eax
f0105500:	74 15                	je     f0105517 <mp_init+0x11b>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105502:	83 ec 0c             	sub    $0xc,%esp
f0105505:	68 24 77 10 f0       	push   $0xf0107724
f010550a:	e8 9e e0 ff ff       	call   f01035ad <cprintf>
f010550f:	83 c4 10             	add    $0x10,%esp
f0105512:	e9 e4 01 00 00       	jmp    f01056fb <mp_init+0x2ff>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105517:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010551b:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010551f:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105522:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105527:	b8 00 00 00 00       	mov    $0x0,%eax
f010552c:	eb 0d                	jmp    f010553b <mp_init+0x13f>
		sum += ((uint8_t *)addr)[i];
f010552e:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105535:	f0 
f0105536:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105538:	83 c0 01             	add    $0x1,%eax
f010553b:	39 c7                	cmp    %eax,%edi
f010553d:	75 ef                	jne    f010552e <mp_init+0x132>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010553f:	84 d2                	test   %dl,%dl
f0105541:	74 15                	je     f0105558 <mp_init+0x15c>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105543:	83 ec 0c             	sub    $0xc,%esp
f0105546:	68 58 77 10 f0       	push   $0xf0107758
f010554b:	e8 5d e0 ff ff       	call   f01035ad <cprintf>
f0105550:	83 c4 10             	add    $0x10,%esp
f0105553:	e9 a3 01 00 00       	jmp    f01056fb <mp_init+0x2ff>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105558:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010555c:	3c 01                	cmp    $0x1,%al
f010555e:	74 1d                	je     f010557d <mp_init+0x181>
f0105560:	3c 04                	cmp    $0x4,%al
f0105562:	74 19                	je     f010557d <mp_init+0x181>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105564:	83 ec 08             	sub    $0x8,%esp
f0105567:	0f b6 c0             	movzbl %al,%eax
f010556a:	50                   	push   %eax
f010556b:	68 7c 77 10 f0       	push   $0xf010777c
f0105570:	e8 38 e0 ff ff       	call   f01035ad <cprintf>
f0105575:	83 c4 10             	add    $0x10,%esp
f0105578:	e9 7e 01 00 00       	jmp    f01056fb <mp_init+0x2ff>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010557d:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105581:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105585:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010558a:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010558f:	01 ce                	add    %ecx,%esi
f0105591:	eb 0d                	jmp    f01055a0 <mp_init+0x1a4>
f0105593:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f010559a:	f0 
f010559b:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010559d:	83 c0 01             	add    $0x1,%eax
f01055a0:	39 c7                	cmp    %eax,%edi
f01055a2:	75 ef                	jne    f0105593 <mp_init+0x197>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01055a4:	89 d0                	mov    %edx,%eax
f01055a6:	02 43 2a             	add    0x2a(%ebx),%al
f01055a9:	74 15                	je     f01055c0 <mp_init+0x1c4>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01055ab:	83 ec 0c             	sub    $0xc,%esp
f01055ae:	68 9c 77 10 f0       	push   $0xf010779c
f01055b3:	e8 f5 df ff ff       	call   f01035ad <cprintf>
f01055b8:	83 c4 10             	add    $0x10,%esp
f01055bb:	e9 3b 01 00 00       	jmp    f01056fb <mp_init+0x2ff>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01055c0:	85 db                	test   %ebx,%ebx
f01055c2:	0f 84 33 01 00 00    	je     f01056fb <mp_init+0x2ff>
		return;
	ismp = 1;
f01055c8:	c7 05 00 f0 22 f0 01 	movl   $0x1,0xf022f000
f01055cf:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01055d2:	8b 43 24             	mov    0x24(%ebx),%eax
f01055d5:	a3 00 00 27 f0       	mov    %eax,0xf0270000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01055da:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01055dd:	be 00 00 00 00       	mov    $0x0,%esi
f01055e2:	e9 85 00 00 00       	jmp    f010566c <mp_init+0x270>
		switch (*p) {
f01055e7:	0f b6 07             	movzbl (%edi),%eax
f01055ea:	84 c0                	test   %al,%al
f01055ec:	74 06                	je     f01055f4 <mp_init+0x1f8>
f01055ee:	3c 04                	cmp    $0x4,%al
f01055f0:	77 55                	ja     f0105647 <mp_init+0x24b>
f01055f2:	eb 4e                	jmp    f0105642 <mp_init+0x246>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01055f4:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01055f8:	74 11                	je     f010560b <mp_init+0x20f>
				bootcpu = &cpus[ncpu];
f01055fa:	6b 05 c4 f3 22 f0 74 	imul   $0x74,0xf022f3c4,%eax
f0105601:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f0105606:	a3 c0 f3 22 f0       	mov    %eax,0xf022f3c0
			if (ncpu < NCPU) {
f010560b:	a1 c4 f3 22 f0       	mov    0xf022f3c4,%eax
f0105610:	83 f8 07             	cmp    $0x7,%eax
f0105613:	7f 13                	jg     f0105628 <mp_init+0x22c>
				cpus[ncpu].cpu_id = ncpu;
f0105615:	6b d0 74             	imul   $0x74,%eax,%edx
f0105618:	88 82 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%edx)
				ncpu++;
f010561e:	83 c0 01             	add    $0x1,%eax
f0105621:	a3 c4 f3 22 f0       	mov    %eax,0xf022f3c4
f0105626:	eb 15                	jmp    f010563d <mp_init+0x241>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105628:	83 ec 08             	sub    $0x8,%esp
f010562b:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010562f:	50                   	push   %eax
f0105630:	68 cc 77 10 f0       	push   $0xf01077cc
f0105635:	e8 73 df ff ff       	call   f01035ad <cprintf>
f010563a:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010563d:	83 c7 14             	add    $0x14,%edi
			continue;
f0105640:	eb 27                	jmp    f0105669 <mp_init+0x26d>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105642:	83 c7 08             	add    $0x8,%edi
			continue;
f0105645:	eb 22                	jmp    f0105669 <mp_init+0x26d>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105647:	83 ec 08             	sub    $0x8,%esp
f010564a:	0f b6 c0             	movzbl %al,%eax
f010564d:	50                   	push   %eax
f010564e:	68 f4 77 10 f0       	push   $0xf01077f4
f0105653:	e8 55 df ff ff       	call   f01035ad <cprintf>
			ismp = 0;
f0105658:	c7 05 00 f0 22 f0 00 	movl   $0x0,0xf022f000
f010565f:	00 00 00 
			i = conf->entry;
f0105662:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105666:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105669:	83 c6 01             	add    $0x1,%esi
f010566c:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105670:	39 c6                	cmp    %eax,%esi
f0105672:	0f 82 6f ff ff ff    	jb     f01055e7 <mp_init+0x1eb>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105678:	a1 c0 f3 22 f0       	mov    0xf022f3c0,%eax
f010567d:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105684:	83 3d 00 f0 22 f0 00 	cmpl   $0x0,0xf022f000
f010568b:	75 26                	jne    f01056b3 <mp_init+0x2b7>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f010568d:	c7 05 c4 f3 22 f0 01 	movl   $0x1,0xf022f3c4
f0105694:	00 00 00 
		lapicaddr = 0;
f0105697:	c7 05 00 00 27 f0 00 	movl   $0x0,0xf0270000
f010569e:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01056a1:	83 ec 0c             	sub    $0xc,%esp
f01056a4:	68 14 78 10 f0       	push   $0xf0107814
f01056a9:	e8 ff de ff ff       	call   f01035ad <cprintf>
		return;
f01056ae:	83 c4 10             	add    $0x10,%esp
f01056b1:	eb 48                	jmp    f01056fb <mp_init+0x2ff>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01056b3:	83 ec 04             	sub    $0x4,%esp
f01056b6:	ff 35 c4 f3 22 f0    	pushl  0xf022f3c4
f01056bc:	0f b6 00             	movzbl (%eax),%eax
f01056bf:	50                   	push   %eax
f01056c0:	68 a7 78 10 f0       	push   $0xf01078a7
f01056c5:	e8 e3 de ff ff       	call   f01035ad <cprintf>

	if (mp->imcrp) {
f01056ca:	83 c4 10             	add    $0x10,%esp
f01056cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01056d0:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01056d4:	74 25                	je     f01056fb <mp_init+0x2ff>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01056d6:	83 ec 0c             	sub    $0xc,%esp
f01056d9:	68 40 78 10 f0       	push   $0xf0107840
f01056de:	e8 ca de ff ff       	call   f01035ad <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01056e3:	ba 22 00 00 00       	mov    $0x22,%edx
f01056e8:	b8 70 00 00 00       	mov    $0x70,%eax
f01056ed:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01056ee:	ba 23 00 00 00       	mov    $0x23,%edx
f01056f3:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01056f4:	83 c8 01             	or     $0x1,%eax
f01056f7:	ee                   	out    %al,(%dx)
f01056f8:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01056fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056fe:	5b                   	pop    %ebx
f01056ff:	5e                   	pop    %esi
f0105700:	5f                   	pop    %edi
f0105701:	5d                   	pop    %ebp
f0105702:	c3                   	ret    

f0105703 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105703:	55                   	push   %ebp
f0105704:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105706:	8b 0d 04 00 27 f0    	mov    0xf0270004,%ecx
f010570c:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010570f:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105711:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f0105716:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105719:	5d                   	pop    %ebp
f010571a:	c3                   	ret    

f010571b <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010571b:	55                   	push   %ebp
f010571c:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010571e:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f0105723:	85 c0                	test   %eax,%eax
f0105725:	74 08                	je     f010572f <cpunum+0x14>
		return lapic[ID] >> 24;
f0105727:	8b 40 20             	mov    0x20(%eax),%eax
f010572a:	c1 e8 18             	shr    $0x18,%eax
f010572d:	eb 05                	jmp    f0105734 <cpunum+0x19>
	return 0;
f010572f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105734:	5d                   	pop    %ebp
f0105735:	c3                   	ret    

f0105736 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105736:	a1 00 00 27 f0       	mov    0xf0270000,%eax
f010573b:	85 c0                	test   %eax,%eax
f010573d:	0f 84 21 01 00 00    	je     f0105864 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105743:	55                   	push   %ebp
f0105744:	89 e5                	mov    %esp,%ebp
f0105746:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105749:	68 00 10 00 00       	push   $0x1000
f010574e:	50                   	push   %eax
f010574f:	e8 57 ba ff ff       	call   f01011ab <mmio_map_region>
f0105754:	a3 04 00 27 f0       	mov    %eax,0xf0270004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105759:	ba 27 01 00 00       	mov    $0x127,%edx
f010575e:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105763:	e8 9b ff ff ff       	call   f0105703 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105768:	ba 0b 00 00 00       	mov    $0xb,%edx
f010576d:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105772:	e8 8c ff ff ff       	call   f0105703 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105777:	ba 20 00 02 00       	mov    $0x20020,%edx
f010577c:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105781:	e8 7d ff ff ff       	call   f0105703 <lapicw>
	lapicw(TICR, 10000000); 
f0105786:	ba 80 96 98 00       	mov    $0x989680,%edx
f010578b:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105790:	e8 6e ff ff ff       	call   f0105703 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105795:	e8 81 ff ff ff       	call   f010571b <cpunum>
f010579a:	6b c0 74             	imul   $0x74,%eax,%eax
f010579d:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f01057a2:	83 c4 10             	add    $0x10,%esp
f01057a5:	39 05 c0 f3 22 f0    	cmp    %eax,0xf022f3c0
f01057ab:	74 0f                	je     f01057bc <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01057ad:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057b2:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01057b7:	e8 47 ff ff ff       	call   f0105703 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01057bc:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057c1:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01057c6:	e8 38 ff ff ff       	call   f0105703 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01057cb:	a1 04 00 27 f0       	mov    0xf0270004,%eax
f01057d0:	8b 40 30             	mov    0x30(%eax),%eax
f01057d3:	c1 e8 10             	shr    $0x10,%eax
f01057d6:	3c 03                	cmp    $0x3,%al
f01057d8:	76 0f                	jbe    f01057e9 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01057da:	ba 00 00 01 00       	mov    $0x10000,%edx
f01057df:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01057e4:	e8 1a ff ff ff       	call   f0105703 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01057e9:	ba 33 00 00 00       	mov    $0x33,%edx
f01057ee:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01057f3:	e8 0b ff ff ff       	call   f0105703 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01057f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01057fd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105802:	e8 fc fe ff ff       	call   f0105703 <lapicw>
	lapicw(ESR, 0);
f0105807:	ba 00 00 00 00       	mov    $0x0,%edx
f010580c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105811:	e8 ed fe ff ff       	call   f0105703 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105816:	ba 00 00 00 00       	mov    $0x0,%edx
f010581b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105820:	e8 de fe ff ff       	call   f0105703 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105825:	ba 00 00 00 00       	mov    $0x0,%edx
f010582a:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010582f:	e8 cf fe ff ff       	call   f0105703 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105834:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105839:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010583e:	e8 c0 fe ff ff       	call   f0105703 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105843:	8b 15 04 00 27 f0    	mov    0xf0270004,%edx
f0105849:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010584f:	f6 c4 10             	test   $0x10,%ah
f0105852:	75 f5                	jne    f0105849 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105854:	ba 00 00 00 00       	mov    $0x0,%edx
f0105859:	b8 20 00 00 00       	mov    $0x20,%eax
f010585e:	e8 a0 fe ff ff       	call   f0105703 <lapicw>
}
f0105863:	c9                   	leave  
f0105864:	f3 c3                	repz ret 

f0105866 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105866:	83 3d 04 00 27 f0 00 	cmpl   $0x0,0xf0270004
f010586d:	74 13                	je     f0105882 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010586f:	55                   	push   %ebp
f0105870:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105872:	ba 00 00 00 00       	mov    $0x0,%edx
f0105877:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010587c:	e8 82 fe ff ff       	call   f0105703 <lapicw>
}
f0105881:	5d                   	pop    %ebp
f0105882:	f3 c3                	repz ret 

f0105884 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105884:	55                   	push   %ebp
f0105885:	89 e5                	mov    %esp,%ebp
f0105887:	56                   	push   %esi
f0105888:	53                   	push   %ebx
f0105889:	8b 75 08             	mov    0x8(%ebp),%esi
f010588c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010588f:	ba 70 00 00 00       	mov    $0x70,%edx
f0105894:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105899:	ee                   	out    %al,(%dx)
f010589a:	ba 71 00 00 00       	mov    $0x71,%edx
f010589f:	b8 0a 00 00 00       	mov    $0xa,%eax
f01058a4:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01058a5:	83 3d 88 ee 22 f0 00 	cmpl   $0x0,0xf022ee88
f01058ac:	75 19                	jne    f01058c7 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01058ae:	68 67 04 00 00       	push   $0x467
f01058b3:	68 e4 5d 10 f0       	push   $0xf0105de4
f01058b8:	68 98 00 00 00       	push   $0x98
f01058bd:	68 c4 78 10 f0       	push   $0xf01078c4
f01058c2:	e8 79 a7 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01058c7:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01058ce:	00 00 
	wrv[1] = addr >> 4;
f01058d0:	89 d8                	mov    %ebx,%eax
f01058d2:	c1 e8 04             	shr    $0x4,%eax
f01058d5:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01058db:	c1 e6 18             	shl    $0x18,%esi
f01058de:	89 f2                	mov    %esi,%edx
f01058e0:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01058e5:	e8 19 fe ff ff       	call   f0105703 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01058ea:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01058ef:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058f4:	e8 0a fe ff ff       	call   f0105703 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01058f9:	ba 00 85 00 00       	mov    $0x8500,%edx
f01058fe:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105903:	e8 fb fd ff ff       	call   f0105703 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105908:	c1 eb 0c             	shr    $0xc,%ebx
f010590b:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010590e:	89 f2                	mov    %esi,%edx
f0105910:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105915:	e8 e9 fd ff ff       	call   f0105703 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010591a:	89 da                	mov    %ebx,%edx
f010591c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105921:	e8 dd fd ff ff       	call   f0105703 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105926:	89 f2                	mov    %esi,%edx
f0105928:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010592d:	e8 d1 fd ff ff       	call   f0105703 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105932:	89 da                	mov    %ebx,%edx
f0105934:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105939:	e8 c5 fd ff ff       	call   f0105703 <lapicw>
		microdelay(200);
	}
}
f010593e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105941:	5b                   	pop    %ebx
f0105942:	5e                   	pop    %esi
f0105943:	5d                   	pop    %ebp
f0105944:	c3                   	ret    

f0105945 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105945:	55                   	push   %ebp
f0105946:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105948:	8b 55 08             	mov    0x8(%ebp),%edx
f010594b:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105951:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105956:	e8 a8 fd ff ff       	call   f0105703 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010595b:	8b 15 04 00 27 f0    	mov    0xf0270004,%edx
f0105961:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105967:	f6 c4 10             	test   $0x10,%ah
f010596a:	75 f5                	jne    f0105961 <lapic_ipi+0x1c>
		;
}
f010596c:	5d                   	pop    %ebp
f010596d:	c3                   	ret    

f010596e <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010596e:	55                   	push   %ebp
f010596f:	89 e5                	mov    %esp,%ebp
f0105971:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105974:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f010597a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010597d:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105980:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105987:	5d                   	pop    %ebp
f0105988:	c3                   	ret    

f0105989 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105989:	55                   	push   %ebp
f010598a:	89 e5                	mov    %esp,%ebp
f010598c:	56                   	push   %esi
f010598d:	53                   	push   %ebx
f010598e:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105991:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105994:	74 14                	je     f01059aa <spin_lock+0x21>
f0105996:	8b 73 08             	mov    0x8(%ebx),%esi
f0105999:	e8 7d fd ff ff       	call   f010571b <cpunum>
f010599e:	6b c0 74             	imul   $0x74,%eax,%eax
f01059a1:	05 20 f0 22 f0       	add    $0xf022f020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01059a6:	39 c6                	cmp    %eax,%esi
f01059a8:	74 07                	je     f01059b1 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f01059aa:	ba 01 00 00 00       	mov    $0x1,%edx
f01059af:	eb 20                	jmp    f01059d1 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01059b1:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01059b4:	e8 62 fd ff ff       	call   f010571b <cpunum>
f01059b9:	83 ec 0c             	sub    $0xc,%esp
f01059bc:	53                   	push   %ebx
f01059bd:	50                   	push   %eax
f01059be:	68 d4 78 10 f0       	push   $0xf01078d4
f01059c3:	6a 41                	push   $0x41
f01059c5:	68 38 79 10 f0       	push   $0xf0107938
f01059ca:	e8 71 a6 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01059cf:	f3 90                	pause  
f01059d1:	89 d0                	mov    %edx,%eax
f01059d3:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01059d6:	85 c0                	test   %eax,%eax
f01059d8:	75 f5                	jne    f01059cf <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01059da:	e8 3c fd ff ff       	call   f010571b <cpunum>
f01059df:	6b c0 74             	imul   $0x74,%eax,%eax
f01059e2:	05 20 f0 22 f0       	add    $0xf022f020,%eax
f01059e7:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01059ea:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01059ed:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01059ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01059f4:	eb 0b                	jmp    f0105a01 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01059f6:	8b 4a 04             	mov    0x4(%edx),%ecx
f01059f9:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01059fc:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01059fe:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105a01:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105a07:	76 11                	jbe    f0105a1a <spin_lock+0x91>
f0105a09:	83 f8 09             	cmp    $0x9,%eax
f0105a0c:	7e e8                	jle    f01059f6 <spin_lock+0x6d>
f0105a0e:	eb 0a                	jmp    f0105a1a <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105a10:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105a17:	83 c0 01             	add    $0x1,%eax
f0105a1a:	83 f8 09             	cmp    $0x9,%eax
f0105a1d:	7e f1                	jle    f0105a10 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105a1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105a22:	5b                   	pop    %ebx
f0105a23:	5e                   	pop    %esi
f0105a24:	5d                   	pop    %ebp
f0105a25:	c3                   	ret    

f0105a26 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105a26:	55                   	push   %ebp
f0105a27:	89 e5                	mov    %esp,%ebp
f0105a29:	57                   	push   %edi
f0105a2a:	56                   	push   %esi
f0105a2b:	53                   	push   %ebx
f0105a2c:	83 ec 4c             	sub    $0x4c,%esp
f0105a2f:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105a32:	83 3e 00             	cmpl   $0x0,(%esi)
f0105a35:	74 18                	je     f0105a4f <spin_unlock+0x29>
f0105a37:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105a3a:	e8 dc fc ff ff       	call   f010571b <cpunum>
f0105a3f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a42:	05 20 f0 22 f0       	add    $0xf022f020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105a47:	39 c3                	cmp    %eax,%ebx
f0105a49:	0f 84 a5 00 00 00    	je     f0105af4 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105a4f:	83 ec 04             	sub    $0x4,%esp
f0105a52:	6a 28                	push   $0x28
f0105a54:	8d 46 0c             	lea    0xc(%esi),%eax
f0105a57:	50                   	push   %eax
f0105a58:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105a5b:	53                   	push   %ebx
f0105a5c:	e8 d1 f6 ff ff       	call   f0105132 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105a61:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105a64:	0f b6 38             	movzbl (%eax),%edi
f0105a67:	8b 76 04             	mov    0x4(%esi),%esi
f0105a6a:	e8 ac fc ff ff       	call   f010571b <cpunum>
f0105a6f:	57                   	push   %edi
f0105a70:	56                   	push   %esi
f0105a71:	50                   	push   %eax
f0105a72:	68 00 79 10 f0       	push   $0xf0107900
f0105a77:	e8 31 db ff ff       	call   f01035ad <cprintf>
f0105a7c:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105a7f:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105a82:	eb 54                	jmp    f0105ad8 <spin_unlock+0xb2>
f0105a84:	83 ec 08             	sub    $0x8,%esp
f0105a87:	57                   	push   %edi
f0105a88:	50                   	push   %eax
f0105a89:	e8 d7 eb ff ff       	call   f0104665 <debuginfo_eip>
f0105a8e:	83 c4 10             	add    $0x10,%esp
f0105a91:	85 c0                	test   %eax,%eax
f0105a93:	78 27                	js     f0105abc <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105a95:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105a97:	83 ec 04             	sub    $0x4,%esp
f0105a9a:	89 c2                	mov    %eax,%edx
f0105a9c:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105a9f:	52                   	push   %edx
f0105aa0:	ff 75 b0             	pushl  -0x50(%ebp)
f0105aa3:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105aa6:	ff 75 ac             	pushl  -0x54(%ebp)
f0105aa9:	ff 75 a8             	pushl  -0x58(%ebp)
f0105aac:	50                   	push   %eax
f0105aad:	68 48 79 10 f0       	push   $0xf0107948
f0105ab2:	e8 f6 da ff ff       	call   f01035ad <cprintf>
f0105ab7:	83 c4 20             	add    $0x20,%esp
f0105aba:	eb 12                	jmp    f0105ace <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105abc:	83 ec 08             	sub    $0x8,%esp
f0105abf:	ff 36                	pushl  (%esi)
f0105ac1:	68 9a 78 10 f0       	push   $0xf010789a
f0105ac6:	e8 e2 da ff ff       	call   f01035ad <cprintf>
f0105acb:	83 c4 10             	add    $0x10,%esp
f0105ace:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105ad1:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105ad4:	39 c3                	cmp    %eax,%ebx
f0105ad6:	74 08                	je     f0105ae0 <spin_unlock+0xba>
f0105ad8:	89 de                	mov    %ebx,%esi
f0105ada:	8b 03                	mov    (%ebx),%eax
f0105adc:	85 c0                	test   %eax,%eax
f0105ade:	75 a4                	jne    f0105a84 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105ae0:	83 ec 04             	sub    $0x4,%esp
f0105ae3:	68 5f 79 10 f0       	push   $0xf010795f
f0105ae8:	6a 67                	push   $0x67
f0105aea:	68 38 79 10 f0       	push   $0xf0107938
f0105aef:	e8 4c a5 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105af4:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105afb:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"                   
f0105b02:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b07:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105b0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105b0d:	5b                   	pop    %ebx
f0105b0e:	5e                   	pop    %esi
f0105b0f:	5f                   	pop    %edi
f0105b10:	5d                   	pop    %ebp
f0105b11:	c3                   	ret    
f0105b12:	66 90                	xchg   %ax,%ax
f0105b14:	66 90                	xchg   %ax,%ax
f0105b16:	66 90                	xchg   %ax,%ax
f0105b18:	66 90                	xchg   %ax,%ax
f0105b1a:	66 90                	xchg   %ax,%ax
f0105b1c:	66 90                	xchg   %ax,%ax
f0105b1e:	66 90                	xchg   %ax,%ax

f0105b20 <__udivdi3>:
f0105b20:	55                   	push   %ebp
f0105b21:	57                   	push   %edi
f0105b22:	56                   	push   %esi
f0105b23:	53                   	push   %ebx
f0105b24:	83 ec 1c             	sub    $0x1c,%esp
f0105b27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105b2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105b2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105b33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105b37:	85 f6                	test   %esi,%esi
f0105b39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105b3d:	89 ca                	mov    %ecx,%edx
f0105b3f:	89 f8                	mov    %edi,%eax
f0105b41:	75 3d                	jne    f0105b80 <__udivdi3+0x60>
f0105b43:	39 cf                	cmp    %ecx,%edi
f0105b45:	0f 87 c5 00 00 00    	ja     f0105c10 <__udivdi3+0xf0>
f0105b4b:	85 ff                	test   %edi,%edi
f0105b4d:	89 fd                	mov    %edi,%ebp
f0105b4f:	75 0b                	jne    f0105b5c <__udivdi3+0x3c>
f0105b51:	b8 01 00 00 00       	mov    $0x1,%eax
f0105b56:	31 d2                	xor    %edx,%edx
f0105b58:	f7 f7                	div    %edi
f0105b5a:	89 c5                	mov    %eax,%ebp
f0105b5c:	89 c8                	mov    %ecx,%eax
f0105b5e:	31 d2                	xor    %edx,%edx
f0105b60:	f7 f5                	div    %ebp
f0105b62:	89 c1                	mov    %eax,%ecx
f0105b64:	89 d8                	mov    %ebx,%eax
f0105b66:	89 cf                	mov    %ecx,%edi
f0105b68:	f7 f5                	div    %ebp
f0105b6a:	89 c3                	mov    %eax,%ebx
f0105b6c:	89 d8                	mov    %ebx,%eax
f0105b6e:	89 fa                	mov    %edi,%edx
f0105b70:	83 c4 1c             	add    $0x1c,%esp
f0105b73:	5b                   	pop    %ebx
f0105b74:	5e                   	pop    %esi
f0105b75:	5f                   	pop    %edi
f0105b76:	5d                   	pop    %ebp
f0105b77:	c3                   	ret    
f0105b78:	90                   	nop
f0105b79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105b80:	39 ce                	cmp    %ecx,%esi
f0105b82:	77 74                	ja     f0105bf8 <__udivdi3+0xd8>
f0105b84:	0f bd fe             	bsr    %esi,%edi
f0105b87:	83 f7 1f             	xor    $0x1f,%edi
f0105b8a:	0f 84 98 00 00 00    	je     f0105c28 <__udivdi3+0x108>
f0105b90:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105b95:	89 f9                	mov    %edi,%ecx
f0105b97:	89 c5                	mov    %eax,%ebp
f0105b99:	29 fb                	sub    %edi,%ebx
f0105b9b:	d3 e6                	shl    %cl,%esi
f0105b9d:	89 d9                	mov    %ebx,%ecx
f0105b9f:	d3 ed                	shr    %cl,%ebp
f0105ba1:	89 f9                	mov    %edi,%ecx
f0105ba3:	d3 e0                	shl    %cl,%eax
f0105ba5:	09 ee                	or     %ebp,%esi
f0105ba7:	89 d9                	mov    %ebx,%ecx
f0105ba9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105bad:	89 d5                	mov    %edx,%ebp
f0105baf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105bb3:	d3 ed                	shr    %cl,%ebp
f0105bb5:	89 f9                	mov    %edi,%ecx
f0105bb7:	d3 e2                	shl    %cl,%edx
f0105bb9:	89 d9                	mov    %ebx,%ecx
f0105bbb:	d3 e8                	shr    %cl,%eax
f0105bbd:	09 c2                	or     %eax,%edx
f0105bbf:	89 d0                	mov    %edx,%eax
f0105bc1:	89 ea                	mov    %ebp,%edx
f0105bc3:	f7 f6                	div    %esi
f0105bc5:	89 d5                	mov    %edx,%ebp
f0105bc7:	89 c3                	mov    %eax,%ebx
f0105bc9:	f7 64 24 0c          	mull   0xc(%esp)
f0105bcd:	39 d5                	cmp    %edx,%ebp
f0105bcf:	72 10                	jb     f0105be1 <__udivdi3+0xc1>
f0105bd1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105bd5:	89 f9                	mov    %edi,%ecx
f0105bd7:	d3 e6                	shl    %cl,%esi
f0105bd9:	39 c6                	cmp    %eax,%esi
f0105bdb:	73 07                	jae    f0105be4 <__udivdi3+0xc4>
f0105bdd:	39 d5                	cmp    %edx,%ebp
f0105bdf:	75 03                	jne    f0105be4 <__udivdi3+0xc4>
f0105be1:	83 eb 01             	sub    $0x1,%ebx
f0105be4:	31 ff                	xor    %edi,%edi
f0105be6:	89 d8                	mov    %ebx,%eax
f0105be8:	89 fa                	mov    %edi,%edx
f0105bea:	83 c4 1c             	add    $0x1c,%esp
f0105bed:	5b                   	pop    %ebx
f0105bee:	5e                   	pop    %esi
f0105bef:	5f                   	pop    %edi
f0105bf0:	5d                   	pop    %ebp
f0105bf1:	c3                   	ret    
f0105bf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105bf8:	31 ff                	xor    %edi,%edi
f0105bfa:	31 db                	xor    %ebx,%ebx
f0105bfc:	89 d8                	mov    %ebx,%eax
f0105bfe:	89 fa                	mov    %edi,%edx
f0105c00:	83 c4 1c             	add    $0x1c,%esp
f0105c03:	5b                   	pop    %ebx
f0105c04:	5e                   	pop    %esi
f0105c05:	5f                   	pop    %edi
f0105c06:	5d                   	pop    %ebp
f0105c07:	c3                   	ret    
f0105c08:	90                   	nop
f0105c09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105c10:	89 d8                	mov    %ebx,%eax
f0105c12:	f7 f7                	div    %edi
f0105c14:	31 ff                	xor    %edi,%edi
f0105c16:	89 c3                	mov    %eax,%ebx
f0105c18:	89 d8                	mov    %ebx,%eax
f0105c1a:	89 fa                	mov    %edi,%edx
f0105c1c:	83 c4 1c             	add    $0x1c,%esp
f0105c1f:	5b                   	pop    %ebx
f0105c20:	5e                   	pop    %esi
f0105c21:	5f                   	pop    %edi
f0105c22:	5d                   	pop    %ebp
f0105c23:	c3                   	ret    
f0105c24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105c28:	39 ce                	cmp    %ecx,%esi
f0105c2a:	72 0c                	jb     f0105c38 <__udivdi3+0x118>
f0105c2c:	31 db                	xor    %ebx,%ebx
f0105c2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105c32:	0f 87 34 ff ff ff    	ja     f0105b6c <__udivdi3+0x4c>
f0105c38:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105c3d:	e9 2a ff ff ff       	jmp    f0105b6c <__udivdi3+0x4c>
f0105c42:	66 90                	xchg   %ax,%ax
f0105c44:	66 90                	xchg   %ax,%ax
f0105c46:	66 90                	xchg   %ax,%ax
f0105c48:	66 90                	xchg   %ax,%ax
f0105c4a:	66 90                	xchg   %ax,%ax
f0105c4c:	66 90                	xchg   %ax,%ax
f0105c4e:	66 90                	xchg   %ax,%ax

f0105c50 <__umoddi3>:
f0105c50:	55                   	push   %ebp
f0105c51:	57                   	push   %edi
f0105c52:	56                   	push   %esi
f0105c53:	53                   	push   %ebx
f0105c54:	83 ec 1c             	sub    $0x1c,%esp
f0105c57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105c5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105c5f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105c63:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105c67:	85 d2                	test   %edx,%edx
f0105c69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105c6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105c71:	89 f3                	mov    %esi,%ebx
f0105c73:	89 3c 24             	mov    %edi,(%esp)
f0105c76:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105c7a:	75 1c                	jne    f0105c98 <__umoddi3+0x48>
f0105c7c:	39 f7                	cmp    %esi,%edi
f0105c7e:	76 50                	jbe    f0105cd0 <__umoddi3+0x80>
f0105c80:	89 c8                	mov    %ecx,%eax
f0105c82:	89 f2                	mov    %esi,%edx
f0105c84:	f7 f7                	div    %edi
f0105c86:	89 d0                	mov    %edx,%eax
f0105c88:	31 d2                	xor    %edx,%edx
f0105c8a:	83 c4 1c             	add    $0x1c,%esp
f0105c8d:	5b                   	pop    %ebx
f0105c8e:	5e                   	pop    %esi
f0105c8f:	5f                   	pop    %edi
f0105c90:	5d                   	pop    %ebp
f0105c91:	c3                   	ret    
f0105c92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105c98:	39 f2                	cmp    %esi,%edx
f0105c9a:	89 d0                	mov    %edx,%eax
f0105c9c:	77 52                	ja     f0105cf0 <__umoddi3+0xa0>
f0105c9e:	0f bd ea             	bsr    %edx,%ebp
f0105ca1:	83 f5 1f             	xor    $0x1f,%ebp
f0105ca4:	75 5a                	jne    f0105d00 <__umoddi3+0xb0>
f0105ca6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105caa:	0f 82 e0 00 00 00    	jb     f0105d90 <__umoddi3+0x140>
f0105cb0:	39 0c 24             	cmp    %ecx,(%esp)
f0105cb3:	0f 86 d7 00 00 00    	jbe    f0105d90 <__umoddi3+0x140>
f0105cb9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105cbd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105cc1:	83 c4 1c             	add    $0x1c,%esp
f0105cc4:	5b                   	pop    %ebx
f0105cc5:	5e                   	pop    %esi
f0105cc6:	5f                   	pop    %edi
f0105cc7:	5d                   	pop    %ebp
f0105cc8:	c3                   	ret    
f0105cc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105cd0:	85 ff                	test   %edi,%edi
f0105cd2:	89 fd                	mov    %edi,%ebp
f0105cd4:	75 0b                	jne    f0105ce1 <__umoddi3+0x91>
f0105cd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0105cdb:	31 d2                	xor    %edx,%edx
f0105cdd:	f7 f7                	div    %edi
f0105cdf:	89 c5                	mov    %eax,%ebp
f0105ce1:	89 f0                	mov    %esi,%eax
f0105ce3:	31 d2                	xor    %edx,%edx
f0105ce5:	f7 f5                	div    %ebp
f0105ce7:	89 c8                	mov    %ecx,%eax
f0105ce9:	f7 f5                	div    %ebp
f0105ceb:	89 d0                	mov    %edx,%eax
f0105ced:	eb 99                	jmp    f0105c88 <__umoddi3+0x38>
f0105cef:	90                   	nop
f0105cf0:	89 c8                	mov    %ecx,%eax
f0105cf2:	89 f2                	mov    %esi,%edx
f0105cf4:	83 c4 1c             	add    $0x1c,%esp
f0105cf7:	5b                   	pop    %ebx
f0105cf8:	5e                   	pop    %esi
f0105cf9:	5f                   	pop    %edi
f0105cfa:	5d                   	pop    %ebp
f0105cfb:	c3                   	ret    
f0105cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105d00:	8b 34 24             	mov    (%esp),%esi
f0105d03:	bf 20 00 00 00       	mov    $0x20,%edi
f0105d08:	89 e9                	mov    %ebp,%ecx
f0105d0a:	29 ef                	sub    %ebp,%edi
f0105d0c:	d3 e0                	shl    %cl,%eax
f0105d0e:	89 f9                	mov    %edi,%ecx
f0105d10:	89 f2                	mov    %esi,%edx
f0105d12:	d3 ea                	shr    %cl,%edx
f0105d14:	89 e9                	mov    %ebp,%ecx
f0105d16:	09 c2                	or     %eax,%edx
f0105d18:	89 d8                	mov    %ebx,%eax
f0105d1a:	89 14 24             	mov    %edx,(%esp)
f0105d1d:	89 f2                	mov    %esi,%edx
f0105d1f:	d3 e2                	shl    %cl,%edx
f0105d21:	89 f9                	mov    %edi,%ecx
f0105d23:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105d27:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105d2b:	d3 e8                	shr    %cl,%eax
f0105d2d:	89 e9                	mov    %ebp,%ecx
f0105d2f:	89 c6                	mov    %eax,%esi
f0105d31:	d3 e3                	shl    %cl,%ebx
f0105d33:	89 f9                	mov    %edi,%ecx
f0105d35:	89 d0                	mov    %edx,%eax
f0105d37:	d3 e8                	shr    %cl,%eax
f0105d39:	89 e9                	mov    %ebp,%ecx
f0105d3b:	09 d8                	or     %ebx,%eax
f0105d3d:	89 d3                	mov    %edx,%ebx
f0105d3f:	89 f2                	mov    %esi,%edx
f0105d41:	f7 34 24             	divl   (%esp)
f0105d44:	89 d6                	mov    %edx,%esi
f0105d46:	d3 e3                	shl    %cl,%ebx
f0105d48:	f7 64 24 04          	mull   0x4(%esp)
f0105d4c:	39 d6                	cmp    %edx,%esi
f0105d4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105d52:	89 d1                	mov    %edx,%ecx
f0105d54:	89 c3                	mov    %eax,%ebx
f0105d56:	72 08                	jb     f0105d60 <__umoddi3+0x110>
f0105d58:	75 11                	jne    f0105d6b <__umoddi3+0x11b>
f0105d5a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105d5e:	73 0b                	jae    f0105d6b <__umoddi3+0x11b>
f0105d60:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105d64:	1b 14 24             	sbb    (%esp),%edx
f0105d67:	89 d1                	mov    %edx,%ecx
f0105d69:	89 c3                	mov    %eax,%ebx
f0105d6b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105d6f:	29 da                	sub    %ebx,%edx
f0105d71:	19 ce                	sbb    %ecx,%esi
f0105d73:	89 f9                	mov    %edi,%ecx
f0105d75:	89 f0                	mov    %esi,%eax
f0105d77:	d3 e0                	shl    %cl,%eax
f0105d79:	89 e9                	mov    %ebp,%ecx
f0105d7b:	d3 ea                	shr    %cl,%edx
f0105d7d:	89 e9                	mov    %ebp,%ecx
f0105d7f:	d3 ee                	shr    %cl,%esi
f0105d81:	09 d0                	or     %edx,%eax
f0105d83:	89 f2                	mov    %esi,%edx
f0105d85:	83 c4 1c             	add    $0x1c,%esp
f0105d88:	5b                   	pop    %ebx
f0105d89:	5e                   	pop    %esi
f0105d8a:	5f                   	pop    %edi
f0105d8b:	5d                   	pop    %ebp
f0105d8c:	c3                   	ret    
f0105d8d:	8d 76 00             	lea    0x0(%esi),%esi
f0105d90:	29 f9                	sub    %edi,%ecx
f0105d92:	19 d6                	sbb    %edx,%esi
f0105d94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105d98:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105d9c:	e9 18 ff ff ff       	jmp    f0105cb9 <__umoddi3+0x69>
