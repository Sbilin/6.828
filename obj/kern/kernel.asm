
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 10 cb 17 f0       	mov    $0xf017cb10,%eax
f010004b:	2d ee bb 17 f0       	sub    $0xf017bbee,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 ee bb 17 f0       	push   $0xf017bbee
f0100058:	e8 b7 3b 00 00       	call   f0103c14 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 40 10 f0       	push   $0xf01040c0
f010006f:	e8 0e 2d 00 00       	call   f0102d82 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 26 0f 00 00       	call   f0100f9f <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 71 27 00 00       	call   f01027ef <env_init>
	trap_init();
f010007e:	e8 70 2d 00 00       	call   f0102df3 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 0a 29 00 00       	call   f010299c <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010009b:	e8 19 2c 00 00       	call   f0102cb9 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 00 cb 17 f0 00 	cmpl   $0x0,0xf017cb00
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 00 cb 17 f0    	mov    %esi,0xf017cb00

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 db 40 10 f0       	push   $0xf01040db
f01000ca:	e8 b3 2c 00 00       	call   f0102d82 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 83 2c 00 00       	call   f0102d5c <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 be 4f 10 f0 	movl   $0xf0104fbe,(%esp)
f01000e0:	e8 9d 2c 00 00       	call   f0102d82 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 40 06 00 00       	call   f0100732 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 f3 40 10 f0       	push   $0xf01040f3
f010010c:	e8 71 2c 00 00       	call   f0102d82 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 3f 2c 00 00       	call   f0102d5c <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 be 4f 10 f0 	movl   $0xf0104fbe,(%esp)
f0100124:	e8 59 2c 00 00       	call   f0102d82 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 24 be 17 f0    	mov    0xf017be24,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 24 be 17 f0    	mov    %edx,0xf017be24
f010016e:	88 81 20 bc 17 f0    	mov    %al,-0xfe843e0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 24 be 17 f0 00 	movl   $0x0,0xf017be24
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 00 bc 17 f0 40 	orl    $0x40,0xf017bc00
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 60 42 10 f0 	movzbl -0xfefbda0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 00 bc 17 f0    	mov    0xf017bc00,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 00 bc 17 f0    	mov    %ecx,0xf017bc00
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 60 42 10 f0 	movzbl -0xfefbda0(%edx),%eax
f0100226:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f010022c:	0f b6 8a 60 41 10 f0 	movzbl -0xfefbea0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 40 41 10 f0 	mov    -0xfefbec0(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 0d 41 10 f0       	push   $0xf010410d
f0100282:	e8 fb 2a 00 00       	call   f0102d82 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 28 be 17 f0 	addw   $0x50,0xf017be28
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 28 be 17 f0 	movzwl 0xf017be28,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 28 be 17 f0 	mov    %dx,0xf017be28
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 28 be 17 f0 	cmpw   $0x7cf,0xf017be28
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 2c be 17 f0       	mov    0xf017be2c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 2b 38 00 00       	call   f0103c61 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 2c be 17 f0    	mov    0xf017be2c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 28 be 17 f0 	subw   $0x50,0xf017be28
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 30 be 17 f0    	mov    0xf017be30,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 28 be 17 f0 	movzwl 0xf017be28,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 34 be 17 f0 00 	cmpb   $0x0,0xf017be34
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 20 be 17 f0       	mov    0xf017be20,%eax
f01004d8:	3b 05 24 be 17 f0    	cmp    0xf017be24,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 20 be 17 f0    	mov    %edx,0xf017be20
f01004e9:	0f b6 88 20 bc 17 f0 	movzbl -0xfe843e0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 20 be 17 f0 00 	movl   $0x0,0xf017be20
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 30 be 17 f0 b4 	movl   $0x3b4,0xf017be30
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 30 be 17 f0 d4 	movl   $0x3d4,0xf017be30
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 30 be 17 f0    	mov    0xf017be30,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 2c be 17 f0    	mov    %esi,0xf017be2c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 28 be 17 f0    	mov    %ax,0xf017be28
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 34 be 17 f0 	setne  0xf017be34
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 19 41 10 f0       	push   $0xf0104119
f0100605:	e8 78 27 00 00       	call   f0102d82 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 60 43 10 f0       	push   $0xf0104360
f010064b:	68 7e 43 10 f0       	push   $0xf010437e
f0100650:	68 83 43 10 f0       	push   $0xf0104383
f0100655:	e8 28 27 00 00       	call   f0102d82 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 ec 43 10 f0       	push   $0xf01043ec
f0100662:	68 8c 43 10 f0       	push   $0xf010438c
f0100667:	68 83 43 10 f0       	push   $0xf0104383
f010066c:	e8 11 27 00 00       	call   f0102d82 <cprintf>
	return 0;
}
f0100671:	b8 00 00 00 00       	mov    $0x0,%eax
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067e:	68 95 43 10 f0       	push   $0xf0104395
f0100683:	e8 fa 26 00 00       	call   f0102d82 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 14 44 10 f0       	push   $0xf0104414
f0100695:	e8 e8 26 00 00       	call   f0102d82 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 3c 44 10 f0       	push   $0xf010443c
f01006ac:	e8 d1 26 00 00       	call   f0102d82 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 a1 40 10 00       	push   $0x1040a1
f01006b9:	68 a1 40 10 f0       	push   $0xf01040a1
f01006be:	68 60 44 10 f0       	push   $0xf0104460
f01006c3:	e8 ba 26 00 00       	call   f0102d82 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 ee bb 17 00       	push   $0x17bbee
f01006d0:	68 ee bb 17 f0       	push   $0xf017bbee
f01006d5:	68 84 44 10 f0       	push   $0xf0104484
f01006da:	e8 a3 26 00 00       	call   f0102d82 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 10 cb 17 00       	push   $0x17cb10
f01006e7:	68 10 cb 17 f0       	push   $0xf017cb10
f01006ec:	68 a8 44 10 f0       	push   $0xf01044a8
f01006f1:	e8 8c 26 00 00       	call   f0102d82 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 0f cf 17 f0       	mov    $0xf017cf0f,%eax
f01006fb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100700:	83 c4 08             	add    $0x8,%esp
f0100703:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100708:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010070e:	85 c0                	test   %eax,%eax
f0100710:	0f 48 c2             	cmovs  %edx,%eax
f0100713:	c1 f8 0a             	sar    $0xa,%eax
f0100716:	50                   	push   %eax
f0100717:	68 cc 44 10 f0       	push   $0xf01044cc
f010071c:	e8 61 26 00 00       	call   f0102d82 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	c9                   	leave  
f0100727:	c3                   	ret    

f0100728 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010072b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100730:	5d                   	pop    %ebp
f0100731:	c3                   	ret    

f0100732 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100732:	55                   	push   %ebp
f0100733:	89 e5                	mov    %esp,%ebp
f0100735:	57                   	push   %edi
f0100736:	56                   	push   %esi
f0100737:	53                   	push   %ebx
f0100738:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010073b:	68 f8 44 10 f0       	push   $0xf01044f8
f0100740:	e8 3d 26 00 00       	call   f0102d82 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100745:	c7 04 24 1c 45 10 f0 	movl   $0xf010451c,(%esp)
f010074c:	e8 31 26 00 00       	call   f0102d82 <cprintf>

	if (tf != NULL)
f0100751:	83 c4 10             	add    $0x10,%esp
f0100754:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100758:	74 0e                	je     f0100768 <monitor+0x36>
		print_trapframe(tf);
f010075a:	83 ec 0c             	sub    $0xc,%esp
f010075d:	ff 75 08             	pushl  0x8(%ebp)
f0100760:	e8 26 27 00 00       	call   f0102e8b <print_trapframe>
f0100765:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100768:	83 ec 0c             	sub    $0xc,%esp
f010076b:	68 ae 43 10 f0       	push   $0xf01043ae
f0100770:	e8 48 32 00 00       	call   f01039bd <readline>
f0100775:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100777:	83 c4 10             	add    $0x10,%esp
f010077a:	85 c0                	test   %eax,%eax
f010077c:	74 ea                	je     f0100768 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010077e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100785:	be 00 00 00 00       	mov    $0x0,%esi
f010078a:	eb 0a                	jmp    f0100796 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010078c:	c6 03 00             	movb   $0x0,(%ebx)
f010078f:	89 f7                	mov    %esi,%edi
f0100791:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100794:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100796:	0f b6 03             	movzbl (%ebx),%eax
f0100799:	84 c0                	test   %al,%al
f010079b:	74 63                	je     f0100800 <monitor+0xce>
f010079d:	83 ec 08             	sub    $0x8,%esp
f01007a0:	0f be c0             	movsbl %al,%eax
f01007a3:	50                   	push   %eax
f01007a4:	68 b2 43 10 f0       	push   $0xf01043b2
f01007a9:	e8 29 34 00 00       	call   f0103bd7 <strchr>
f01007ae:	83 c4 10             	add    $0x10,%esp
f01007b1:	85 c0                	test   %eax,%eax
f01007b3:	75 d7                	jne    f010078c <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01007b5:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007b8:	74 46                	je     f0100800 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007ba:	83 fe 0f             	cmp    $0xf,%esi
f01007bd:	75 14                	jne    f01007d3 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007bf:	83 ec 08             	sub    $0x8,%esp
f01007c2:	6a 10                	push   $0x10
f01007c4:	68 b7 43 10 f0       	push   $0xf01043b7
f01007c9:	e8 b4 25 00 00       	call   f0102d82 <cprintf>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	eb 95                	jmp    f0100768 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01007d3:	8d 7e 01             	lea    0x1(%esi),%edi
f01007d6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007da:	eb 03                	jmp    f01007df <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007dc:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007df:	0f b6 03             	movzbl (%ebx),%eax
f01007e2:	84 c0                	test   %al,%al
f01007e4:	74 ae                	je     f0100794 <monitor+0x62>
f01007e6:	83 ec 08             	sub    $0x8,%esp
f01007e9:	0f be c0             	movsbl %al,%eax
f01007ec:	50                   	push   %eax
f01007ed:	68 b2 43 10 f0       	push   $0xf01043b2
f01007f2:	e8 e0 33 00 00       	call   f0103bd7 <strchr>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 de                	je     f01007dc <monitor+0xaa>
f01007fe:	eb 94                	jmp    f0100794 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100800:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100807:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100808:	85 f6                	test   %esi,%esi
f010080a:	0f 84 58 ff ff ff    	je     f0100768 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100810:	83 ec 08             	sub    $0x8,%esp
f0100813:	68 7e 43 10 f0       	push   $0xf010437e
f0100818:	ff 75 a8             	pushl  -0x58(%ebp)
f010081b:	e8 59 33 00 00       	call   f0103b79 <strcmp>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 1e                	je     f0100845 <monitor+0x113>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	68 8c 43 10 f0       	push   $0xf010438c
f010082f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100832:	e8 42 33 00 00       	call   f0103b79 <strcmp>
f0100837:	83 c4 10             	add    $0x10,%esp
f010083a:	85 c0                	test   %eax,%eax
f010083c:	75 2f                	jne    f010086d <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010083e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100843:	eb 05                	jmp    f010084a <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100845:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010084a:	83 ec 04             	sub    $0x4,%esp
f010084d:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100850:	01 d0                	add    %edx,%eax
f0100852:	ff 75 08             	pushl  0x8(%ebp)
f0100855:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100858:	51                   	push   %ecx
f0100859:	56                   	push   %esi
f010085a:	ff 14 85 4c 45 10 f0 	call   *-0xfefbab4(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	78 1d                	js     f0100885 <monitor+0x153>
f0100868:	e9 fb fe ff ff       	jmp    f0100768 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010086d:	83 ec 08             	sub    $0x8,%esp
f0100870:	ff 75 a8             	pushl  -0x58(%ebp)
f0100873:	68 d4 43 10 f0       	push   $0xf01043d4
f0100878:	e8 05 25 00 00       	call   f0102d82 <cprintf>
f010087d:	83 c4 10             	add    $0x10,%esp
f0100880:	e9 e3 fe ff ff       	jmp    f0100768 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100885:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100888:	5b                   	pop    %ebx
f0100889:	5e                   	pop    %esi
f010088a:	5f                   	pop    %edi
f010088b:	5d                   	pop    %ebp
f010088c:	c3                   	ret    

f010088d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010088d:	55                   	push   %ebp
f010088e:	89 e5                	mov    %esp,%ebp
f0100890:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100892:	83 3d 38 be 17 f0 00 	cmpl   $0x0,0xf017be38
f0100899:	75 0f                	jne    f01008aa <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010089b:	b8 0f db 17 f0       	mov    $0xf017db0f,%eax
f01008a0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008a5:	a3 38 be 17 f0       	mov    %eax,0xf017be38
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008aa:	a1 38 be 17 f0       	mov    0xf017be38,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f01008af:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01008b5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008bb:	01 c2                	add    %eax,%edx
f01008bd:	89 15 38 be 17 f0    	mov    %edx,0xf017be38
	return result;
}
f01008c3:	5d                   	pop    %ebp
f01008c4:	c3                   	ret    

f01008c5 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008c5:	55                   	push   %ebp
f01008c6:	89 e5                	mov    %esp,%ebp
f01008c8:	56                   	push   %esi
f01008c9:	53                   	push   %ebx
f01008ca:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008cc:	83 ec 0c             	sub    $0xc,%esp
f01008cf:	50                   	push   %eax
f01008d0:	e8 46 24 00 00       	call   f0102d1b <mc146818_read>
f01008d5:	89 c6                	mov    %eax,%esi
f01008d7:	83 c3 01             	add    $0x1,%ebx
f01008da:	89 1c 24             	mov    %ebx,(%esp)
f01008dd:	e8 39 24 00 00       	call   f0102d1b <mc146818_read>
f01008e2:	c1 e0 08             	shl    $0x8,%eax
f01008e5:	09 f0                	or     %esi,%eax
}
f01008e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008ea:	5b                   	pop    %ebx
f01008eb:	5e                   	pop    %esi
f01008ec:	5d                   	pop    %ebp
f01008ed:	c3                   	ret    

f01008ee <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008ee:	89 d1                	mov    %edx,%ecx
f01008f0:	c1 e9 16             	shr    $0x16,%ecx
f01008f3:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008f6:	a8 01                	test   $0x1,%al
f01008f8:	74 52                	je     f010094c <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008ff:	89 c1                	mov    %eax,%ecx
f0100901:	c1 e9 0c             	shr    $0xc,%ecx
f0100904:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f010090a:	72 1b                	jb     f0100927 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010090c:	55                   	push   %ebp
f010090d:	89 e5                	mov    %esp,%ebp
f010090f:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100912:	50                   	push   %eax
f0100913:	68 5c 45 10 f0       	push   $0xf010455c
f0100918:	68 1f 03 00 00       	push   $0x31f
f010091d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100922:	e8 79 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100927:	c1 ea 0c             	shr    $0xc,%edx
f010092a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100930:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100937:	89 c2                	mov    %eax,%edx
f0100939:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010093c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100941:	85 d2                	test   %edx,%edx
f0100943:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100948:	0f 44 c2             	cmove  %edx,%eax
f010094b:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010094c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100951:	c3                   	ret    

f0100952 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100952:	55                   	push   %ebp
f0100953:	89 e5                	mov    %esp,%ebp
f0100955:	57                   	push   %edi
f0100956:	56                   	push   %esi
f0100957:	53                   	push   %ebx
f0100958:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010095b:	84 c0                	test   %al,%al
f010095d:	0f 85 72 02 00 00    	jne    f0100bd5 <check_page_free_list+0x283>
f0100963:	e9 7f 02 00 00       	jmp    f0100be7 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100968:	83 ec 04             	sub    $0x4,%esp
f010096b:	68 80 45 10 f0       	push   $0xf0104580
f0100970:	68 5d 02 00 00       	push   $0x25d
f0100975:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010097a:	e8 21 f7 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010097f:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100982:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100985:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100988:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010098b:	89 c2                	mov    %eax,%edx
f010098d:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0100993:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100999:	0f 95 c2             	setne  %dl
f010099c:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010099f:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009a3:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009a5:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009a9:	8b 00                	mov    (%eax),%eax
f01009ab:	85 c0                	test   %eax,%eax
f01009ad:	75 dc                	jne    f010098b <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009be:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009c0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009c3:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009c8:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009cd:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f01009d3:	eb 53                	jmp    f0100a28 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009d5:	89 d8                	mov    %ebx,%eax
f01009d7:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f01009dd:	c1 f8 03             	sar    $0x3,%eax
f01009e0:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009e3:	89 c2                	mov    %eax,%edx
f01009e5:	c1 ea 16             	shr    $0x16,%edx
f01009e8:	39 f2                	cmp    %esi,%edx
f01009ea:	73 3a                	jae    f0100a26 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009ec:	89 c2                	mov    %eax,%edx
f01009ee:	c1 ea 0c             	shr    $0xc,%edx
f01009f1:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01009f7:	72 12                	jb     f0100a0b <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f9:	50                   	push   %eax
f01009fa:	68 5c 45 10 f0       	push   $0xf010455c
f01009ff:	6a 56                	push   $0x56
f0100a01:	68 19 4d 10 f0       	push   $0xf0104d19
f0100a06:	e8 95 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a0b:	83 ec 04             	sub    $0x4,%esp
f0100a0e:	68 80 00 00 00       	push   $0x80
f0100a13:	68 97 00 00 00       	push   $0x97
f0100a18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a1d:	50                   	push   %eax
f0100a1e:	e8 f1 31 00 00       	call   f0103c14 <memset>
f0100a23:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a26:	8b 1b                	mov    (%ebx),%ebx
f0100a28:	85 db                	test   %ebx,%ebx
f0100a2a:	75 a9                	jne    f01009d5 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a31:	e8 57 fe ff ff       	call   f010088d <boot_alloc>
f0100a36:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a39:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a3f:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
		assert(pp < pages + npages);
f0100a45:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0100a4a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a4d:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a50:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a53:	be 00 00 00 00       	mov    $0x0,%esi
f0100a58:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a5b:	e9 30 01 00 00       	jmp    f0100b90 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a60:	39 ca                	cmp    %ecx,%edx
f0100a62:	73 19                	jae    f0100a7d <check_page_free_list+0x12b>
f0100a64:	68 27 4d 10 f0       	push   $0xf0104d27
f0100a69:	68 33 4d 10 f0       	push   $0xf0104d33
f0100a6e:	68 77 02 00 00       	push   $0x277
f0100a73:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100a78:	e8 23 f6 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100a7d:	39 fa                	cmp    %edi,%edx
f0100a7f:	72 19                	jb     f0100a9a <check_page_free_list+0x148>
f0100a81:	68 48 4d 10 f0       	push   $0xf0104d48
f0100a86:	68 33 4d 10 f0       	push   $0xf0104d33
f0100a8b:	68 78 02 00 00       	push   $0x278
f0100a90:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100a95:	e8 06 f6 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a9a:	89 d0                	mov    %edx,%eax
f0100a9c:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a9f:	a8 07                	test   $0x7,%al
f0100aa1:	74 19                	je     f0100abc <check_page_free_list+0x16a>
f0100aa3:	68 a4 45 10 f0       	push   $0xf01045a4
f0100aa8:	68 33 4d 10 f0       	push   $0xf0104d33
f0100aad:	68 79 02 00 00       	push   $0x279
f0100ab2:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100ab7:	e8 e4 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100abc:	c1 f8 03             	sar    $0x3,%eax
f0100abf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ac2:	85 c0                	test   %eax,%eax
f0100ac4:	75 19                	jne    f0100adf <check_page_free_list+0x18d>
f0100ac6:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0100acb:	68 33 4d 10 f0       	push   $0xf0104d33
f0100ad0:	68 7c 02 00 00       	push   $0x27c
f0100ad5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100ada:	e8 c1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100adf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ae4:	75 19                	jne    f0100aff <check_page_free_list+0x1ad>
f0100ae6:	68 6d 4d 10 f0       	push   $0xf0104d6d
f0100aeb:	68 33 4d 10 f0       	push   $0xf0104d33
f0100af0:	68 7d 02 00 00       	push   $0x27d
f0100af5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100afa:	e8 a1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100aff:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b04:	75 19                	jne    f0100b1f <check_page_free_list+0x1cd>
f0100b06:	68 d8 45 10 f0       	push   $0xf01045d8
f0100b0b:	68 33 4d 10 f0       	push   $0xf0104d33
f0100b10:	68 7e 02 00 00       	push   $0x27e
f0100b15:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100b1a:	e8 81 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b1f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b24:	75 19                	jne    f0100b3f <check_page_free_list+0x1ed>
f0100b26:	68 86 4d 10 f0       	push   $0xf0104d86
f0100b2b:	68 33 4d 10 f0       	push   $0xf0104d33
f0100b30:	68 7f 02 00 00       	push   $0x27f
f0100b35:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100b3a:	e8 61 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b3f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b44:	76 3f                	jbe    f0100b85 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b46:	89 c3                	mov    %eax,%ebx
f0100b48:	c1 eb 0c             	shr    $0xc,%ebx
f0100b4b:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b4e:	77 12                	ja     f0100b62 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b50:	50                   	push   %eax
f0100b51:	68 5c 45 10 f0       	push   $0xf010455c
f0100b56:	6a 56                	push   $0x56
f0100b58:	68 19 4d 10 f0       	push   $0xf0104d19
f0100b5d:	e8 3e f5 ff ff       	call   f01000a0 <_panic>
f0100b62:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b67:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b6a:	76 1e                	jbe    f0100b8a <check_page_free_list+0x238>
f0100b6c:	68 fc 45 10 f0       	push   $0xf01045fc
f0100b71:	68 33 4d 10 f0       	push   $0xf0104d33
f0100b76:	68 80 02 00 00       	push   $0x280
f0100b7b:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100b80:	e8 1b f5 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b85:	83 c6 01             	add    $0x1,%esi
f0100b88:	eb 04                	jmp    f0100b8e <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b8a:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b8e:	8b 12                	mov    (%edx),%edx
f0100b90:	85 d2                	test   %edx,%edx
f0100b92:	0f 85 c8 fe ff ff    	jne    f0100a60 <check_page_free_list+0x10e>
f0100b98:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b9b:	85 f6                	test   %esi,%esi
f0100b9d:	7f 19                	jg     f0100bb8 <check_page_free_list+0x266>
f0100b9f:	68 a0 4d 10 f0       	push   $0xf0104da0
f0100ba4:	68 33 4d 10 f0       	push   $0xf0104d33
f0100ba9:	68 88 02 00 00       	push   $0x288
f0100bae:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100bb3:	e8 e8 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bb8:	85 db                	test   %ebx,%ebx
f0100bba:	7f 42                	jg     f0100bfe <check_page_free_list+0x2ac>
f0100bbc:	68 b2 4d 10 f0       	push   $0xf0104db2
f0100bc1:	68 33 4d 10 f0       	push   $0xf0104d33
f0100bc6:	68 89 02 00 00       	push   $0x289
f0100bcb:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100bd0:	e8 cb f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bd5:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0100bda:	85 c0                	test   %eax,%eax
f0100bdc:	0f 85 9d fd ff ff    	jne    f010097f <check_page_free_list+0x2d>
f0100be2:	e9 81 fd ff ff       	jmp    f0100968 <check_page_free_list+0x16>
f0100be7:	83 3d 3c be 17 f0 00 	cmpl   $0x0,0xf017be3c
f0100bee:	0f 84 74 fd ff ff    	je     f0100968 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bf4:	be 00 04 00 00       	mov    $0x400,%esi
f0100bf9:	e9 cf fd ff ff       	jmp    f01009cd <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100bfe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c01:	5b                   	pop    %ebx
f0100c02:	5e                   	pop    %esi
f0100c03:	5f                   	pop    %edi
f0100c04:	5d                   	pop    %ebp
f0100c05:	c3                   	ret    

f0100c06 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c06:	55                   	push   %ebp
f0100c07:	89 e5                	mov    %esp,%ebp
f0100c09:	56                   	push   %esi
f0100c0a:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
        page_free_list = NULL;
f0100c0b:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f0100c12:	00 00 00 
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
f0100c15:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c1a:	e8 6e fc ff ff       	call   f010088d <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c1f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100c24:	77 15                	ja     f0100c3b <page_init+0x35>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c26:	50                   	push   %eax
f0100c27:	68 44 46 10 f0       	push   $0xf0104644
f0100c2c:	68 12 01 00 00       	push   $0x112
f0100c31:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100c36:	e8 65 f4 ff ff       	call   f01000a0 <_panic>
f0100c3b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c40:	c1 e8 0c             	shr    $0xc,%eax
	for (i = 0; i < npages; i++) {
f0100c43:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c48:	be 00 00 00 00       	mov    $0x0,%esi
f0100c4d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c52:	eb 62                	jmp    f0100cb6 <page_init+0xb0>
            if(i==0)
f0100c54:	85 d2                	test   %edx,%edx
f0100c56:	75 14                	jne    f0100c6c <page_init+0x66>
             {
		pages[i].pp_ref = 1;
f0100c58:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
f0100c5e:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100c64:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100c6a:	eb 47                	jmp    f0100cb3 <page_init+0xad>
             }
             else if(i >= low_pgm && i < upp_pgm)
f0100c6c:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100c72:	76 1b                	jbe    f0100c8f <page_init+0x89>
f0100c74:	39 c2                	cmp    %eax,%edx
f0100c76:	73 17                	jae    f0100c8f <page_init+0x89>
             {
                pages[i].pp_ref=1;
f0100c78:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
f0100c7e:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100c81:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100c87:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100c8d:	eb 24                	jmp    f0100cb3 <page_init+0xad>
f0100c8f:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
             }
             else
             {
                 pages[i].pp_ref=0;
f0100c96:	89 cb                	mov    %ecx,%ebx
f0100c98:	03 1d 0c cb 17 f0    	add    0xf017cb0c,%ebx
f0100c9e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
                 pages[i].pp_link = page_free_list;
f0100ca4:	89 33                	mov    %esi,(%ebx)
                 page_free_list = &pages[i];
f0100ca6:	89 ce                	mov    %ecx,%esi
f0100ca8:	03 35 0c cb 17 f0    	add    0xf017cb0c,%esi
f0100cae:	bb 01 00 00 00       	mov    $0x1,%ebx
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) {
f0100cb3:	83 c2 01             	add    $0x1,%edx
f0100cb6:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100cbc:	72 96                	jb     f0100c54 <page_init+0x4e>
f0100cbe:	84 db                	test   %bl,%bl
f0100cc0:	74 06                	je     f0100cc8 <page_init+0xc2>
f0100cc2:	89 35 3c be 17 f0    	mov    %esi,0xf017be3c
                 pages[i].pp_ref=0;
                 pages[i].pp_link = page_free_list;
                 page_free_list = &pages[i];
             }
          }
}
f0100cc8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ccb:	5b                   	pop    %ebx
f0100ccc:	5e                   	pop    %esi
f0100ccd:	5d                   	pop    %ebp
f0100cce:	c3                   	ret    

f0100ccf <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ccf:	55                   	push   %ebp
f0100cd0:	89 e5                	mov    %esp,%ebp
f0100cd2:	53                   	push   %ebx
f0100cd3:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
        if(page_free_list==NULL)
f0100cd6:	8b 1d 3c be 17 f0    	mov    0xf017be3c,%ebx
f0100cdc:	85 db                	test   %ebx,%ebx
f0100cde:	74 58                	je     f0100d38 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100ce0:	8b 03                	mov    (%ebx),%eax
f0100ce2:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
        result->pp_link=NULL;
f0100ce7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if(alloc_flags & ALLOC_ZERO)
f0100ced:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100cf1:	74 45                	je     f0100d38 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cf3:	89 d8                	mov    %ebx,%eax
f0100cf5:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100cfb:	c1 f8 03             	sar    $0x3,%eax
f0100cfe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d01:	89 c2                	mov    %eax,%edx
f0100d03:	c1 ea 0c             	shr    $0xc,%edx
f0100d06:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100d0c:	72 12                	jb     f0100d20 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d0e:	50                   	push   %eax
f0100d0f:	68 5c 45 10 f0       	push   $0xf010455c
f0100d14:	6a 56                	push   $0x56
f0100d16:	68 19 4d 10 f0       	push   $0xf0104d19
f0100d1b:	e8 80 f3 ff ff       	call   f01000a0 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100d20:	83 ec 04             	sub    $0x4,%esp
f0100d23:	68 00 10 00 00       	push   $0x1000
f0100d28:	6a 00                	push   $0x0
f0100d2a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 df 2e 00 00       	call   f0103c14 <memset>
f0100d35:	83 c4 10             	add    $0x10,%esp
	return result;
}
f0100d38:	89 d8                	mov    %ebx,%eax
f0100d3a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d3d:	c9                   	leave  
f0100d3e:	c3                   	ret    

f0100d3f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d3f:	55                   	push   %ebp
f0100d40:	89 e5                	mov    %esp,%ebp
f0100d42:	83 ec 08             	sub    $0x8,%esp
f0100d45:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0 || pp->pp_link == NULL);  
f0100d48:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d4d:	74 1e                	je     f0100d6d <page_free+0x2e>
f0100d4f:	83 38 00             	cmpl   $0x0,(%eax)
f0100d52:	74 19                	je     f0100d6d <page_free+0x2e>
f0100d54:	68 68 46 10 f0       	push   $0xf0104668
f0100d59:	68 33 4d 10 f0       	push   $0xf0104d33
f0100d5e:	68 4e 01 00 00       	push   $0x14e
f0100d63:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100d68:	e8 33 f3 ff ff       	call   f01000a0 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100d6d:	8b 15 3c be 17 f0    	mov    0xf017be3c,%edx
f0100d73:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100d75:	a3 3c be 17 f0       	mov    %eax,0xf017be3c
}
f0100d7a:	c9                   	leave  
f0100d7b:	c3                   	ret    

f0100d7c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	83 ec 08             	sub    $0x8,%esp
f0100d82:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d85:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d89:	83 e8 01             	sub    $0x1,%eax
f0100d8c:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d90:	66 85 c0             	test   %ax,%ax
f0100d93:	75 0c                	jne    f0100da1 <page_decref+0x25>
		page_free(pp);
f0100d95:	83 ec 0c             	sub    $0xc,%esp
f0100d98:	52                   	push   %edx
f0100d99:	e8 a1 ff ff ff       	call   f0100d3f <page_free>
f0100d9e:	83 c4 10             	add    $0x10,%esp
}
f0100da1:	c9                   	leave  
f0100da2:	c3                   	ret    

f0100da3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100da3:	55                   	push   %ebp
f0100da4:	89 e5                	mov    %esp,%ebp
f0100da6:	56                   	push   %esi
f0100da7:	53                   	push   %ebx
f0100da8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	uint32_t pdx=PDX(va);
	uint32_t ptx=PTX(va);
f0100dab:	89 de                	mov    %ebx,%esi
f0100dad:	c1 ee 0c             	shr    $0xc,%esi
f0100db0:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t *po_entry;
 	pde_t *pt_entry=pgdir+pdx;
f0100db6:	c1 eb 16             	shr    $0x16,%ebx
f0100db9:	c1 e3 02             	shl    $0x2,%ebx
f0100dbc:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pt_entry&PTE_P))
f0100dbf:	f6 03 01             	testb  $0x1,(%ebx)
f0100dc2:	75 2d                	jne    f0100df1 <pgdir_walk+0x4e>
	{
		if(create==0)
f0100dc4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100dc8:	74 59                	je     f0100e23 <pgdir_walk+0x80>
			return NULL;
		struct PageInfo *pp=page_alloc(1);
f0100dca:	83 ec 0c             	sub    $0xc,%esp
f0100dcd:	6a 01                	push   $0x1
f0100dcf:	e8 fb fe ff ff       	call   f0100ccf <page_alloc>
			if(pp==NULL)
f0100dd4:	83 c4 10             	add    $0x10,%esp
f0100dd7:	85 c0                	test   %eax,%eax
f0100dd9:	74 4f                	je     f0100e2a <pgdir_walk+0x87>
			{
				return NULL;
			}
		pp->pp_ref++;
f0100ddb:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
f0100de0:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0100de6:	c1 f8 03             	sar    $0x3,%eax
f0100de9:	c1 e0 0c             	shl    $0xc,%eax
f0100dec:	83 c8 07             	or     $0x7,%eax
f0100def:	89 03                	mov    %eax,(%ebx)
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
f0100df1:	8b 03                	mov    (%ebx),%eax
f0100df3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100df8:	89 c2                	mov    %eax,%edx
f0100dfa:	c1 ea 0c             	shr    $0xc,%edx
f0100dfd:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0100e03:	72 15                	jb     f0100e1a <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e05:	50                   	push   %eax
f0100e06:	68 5c 45 10 f0       	push   $0xf010455c
f0100e0b:	68 89 01 00 00       	push   $0x189
f0100e10:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0100e15:	e8 86 f2 ff ff       	call   f01000a0 <_panic>
	return po_entry+ptx;
f0100e1a:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e21:	eb 0c                	jmp    f0100e2f <pgdir_walk+0x8c>
	pte_t *po_entry;
 	pde_t *pt_entry=pgdir+pdx;
	if(!(*pt_entry&PTE_P))
	{
		if(create==0)
			return NULL;
f0100e23:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e28:	eb 05                	jmp    f0100e2f <pgdir_walk+0x8c>
		struct PageInfo *pp=page_alloc(1);
			if(pp==NULL)
			{
				return NULL;
f0100e2a:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
	return po_entry+ptx;
}
f0100e2f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e32:	5b                   	pop    %ebx
f0100e33:	5e                   	pop    %esi
f0100e34:	5d                   	pop    %ebp
f0100e35:	c3                   	ret    

f0100e36 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e36:	55                   	push   %ebp
f0100e37:	89 e5                	mov    %esp,%ebp
f0100e39:	57                   	push   %edi
f0100e3a:	56                   	push   %esi
f0100e3b:	53                   	push   %ebx
f0100e3c:	83 ec 1c             	sub    $0x1c,%esp
f0100e3f:	89 c7                	mov    %eax,%edi
f0100e41:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e44:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *po_entry;
	uint32_t i;
	for(i=0;i<size;i=i+PGSIZE)
f0100e47:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e4c:	eb 1f                	jmp    f0100e6d <boot_map_region+0x37>
	{	
		po_entry=pgdir_walk(pgdir,(void *)va,1);
f0100e4e:	83 ec 04             	sub    $0x4,%esp
f0100e51:	6a 01                	push   $0x1
f0100e53:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e56:	01 d8                	add    %ebx,%eax
f0100e58:	50                   	push   %eax
f0100e59:	57                   	push   %edi
f0100e5a:	e8 44 ff ff ff       	call   f0100da3 <pgdir_walk>
		*po_entry=pa|perm;
f0100e5f:	0b 75 0c             	or     0xc(%ebp),%esi
f0100e62:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	uint32_t i;
	for(i=0;i<size;i=i+PGSIZE)
f0100e64:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e6a:	83 c4 10             	add    $0x10,%esp
f0100e6d:	89 de                	mov    %ebx,%esi
f0100e6f:	03 75 08             	add    0x8(%ebp),%esi
f0100e72:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100e75:	72 d7                	jb     f0100e4e <boot_map_region+0x18>
		*po_entry=pa|perm;
		pa=pa+PGSIZE;
		va=va+PGSIZE;
	}		
	
}
f0100e77:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e7a:	5b                   	pop    %ebx
f0100e7b:	5e                   	pop    %esi
f0100e7c:	5f                   	pop    %edi
f0100e7d:	5d                   	pop    %ebp
f0100e7e:	c3                   	ret    

f0100e7f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e7f:	55                   	push   %ebp
f0100e80:	89 e5                	mov    %esp,%ebp
f0100e82:	53                   	push   %ebx
f0100e83:	83 ec 08             	sub    $0x8,%esp
f0100e86:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f0100e89:	6a 00                	push   $0x0
f0100e8b:	ff 75 0c             	pushl  0xc(%ebp)
f0100e8e:	ff 75 08             	pushl  0x8(%ebp)
f0100e91:	e8 0d ff ff ff       	call   f0100da3 <pgdir_walk>
	if(po_entry==NULL)
f0100e96:	83 c4 10             	add    $0x10,%esp
f0100e99:	85 c0                	test   %eax,%eax
f0100e9b:	74 37                	je     f0100ed4 <page_lookup+0x55>
	{
		return NULL;
	}
	if(!(*po_entry&PTE_P))
f0100e9d:	f6 00 01             	testb  $0x1,(%eax)
f0100ea0:	74 39                	je     f0100edb <page_lookup+0x5c>
	{
		return NULL;
	}
	if(pte_store!=0)
f0100ea2:	85 db                	test   %ebx,%ebx
f0100ea4:	74 02                	je     f0100ea8 <page_lookup+0x29>
	{
		*pte_store=po_entry;
f0100ea6:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ea8:	8b 00                	mov    (%eax),%eax
f0100eaa:	c1 e8 0c             	shr    $0xc,%eax
f0100ead:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0100eb3:	72 14                	jb     f0100ec9 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100eb5:	83 ec 04             	sub    $0x4,%esp
f0100eb8:	68 90 46 10 f0       	push   $0xf0104690
f0100ebd:	6a 4f                	push   $0x4f
f0100ebf:	68 19 4d 10 f0       	push   $0xf0104d19
f0100ec4:	e8 d7 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100ec9:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0100ecf:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
f0100ed2:	eb 0c                	jmp    f0100ee0 <page_lookup+0x61>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f0100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed9:	eb 05                	jmp    f0100ee0 <page_lookup+0x61>
	}
	if(!(*po_entry&PTE_P))
	{
		return NULL;
f0100edb:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
}	
f0100ee0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ee3:	c9                   	leave  
f0100ee4:	c3                   	ret    

f0100ee5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ee5:	55                   	push   %ebp
f0100ee6:	89 e5                	mov    %esp,%ebp
f0100ee8:	53                   	push   %ebx
f0100ee9:	83 ec 18             	sub    $0x18,%esp
f0100eec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f0100eef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f0100ef6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ef9:	50                   	push   %eax
f0100efa:	53                   	push   %ebx
f0100efb:	ff 75 08             	pushl  0x8(%ebp)
f0100efe:	e8 7c ff ff ff       	call   f0100e7f <page_lookup>
	if(pp==NULL)
f0100f03:	83 c4 10             	add    $0x10,%esp
f0100f06:	85 c0                	test   %eax,%eax
f0100f08:	74 18                	je     f0100f22 <page_remove+0x3d>
	{
		return;
	}
	page_decref(pp);
f0100f0a:	83 ec 0c             	sub    $0xc,%esp
f0100f0d:	50                   	push   %eax
f0100f0e:	e8 69 fe ff ff       	call   f0100d7c <page_decref>
	*pte_store=0;
f0100f13:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f16:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f1c:	0f 01 3b             	invlpg (%ebx)
f0100f1f:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);	
}
f0100f22:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f25:	c9                   	leave  
f0100f26:	c3                   	ret    

f0100f27 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f27:	55                   	push   %ebp
f0100f28:	89 e5                	mov    %esp,%ebp
f0100f2a:	57                   	push   %edi
f0100f2b:	56                   	push   %esi
f0100f2c:	53                   	push   %ebx
f0100f2d:	83 ec 10             	sub    $0x10,%esp
f0100f30:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f33:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f0100f36:	6a 01                	push   $0x1
f0100f38:	ff 75 10             	pushl  0x10(%ebp)
f0100f3b:	56                   	push   %esi
f0100f3c:	e8 62 fe ff ff       	call   f0100da3 <pgdir_walk>
	if(po_entry==NULL)
f0100f41:	83 c4 10             	add    $0x10,%esp
f0100f44:	85 c0                	test   %eax,%eax
f0100f46:	74 4a                	je     f0100f92 <page_insert+0x6b>
f0100f48:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100f4a:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*po_entry)&PTE_P)
f0100f4f:	f6 00 01             	testb  $0x1,(%eax)
f0100f52:	74 15                	je     f0100f69 <page_insert+0x42>
f0100f54:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f57:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir,va);
		page_remove(pgdir,va);
f0100f5a:	83 ec 08             	sub    $0x8,%esp
f0100f5d:	ff 75 10             	pushl  0x10(%ebp)
f0100f60:	56                   	push   %esi
f0100f61:	e8 7f ff ff ff       	call   f0100ee5 <page_remove>
f0100f66:	83 c4 10             	add    $0x10,%esp
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
f0100f69:	2b 1d 0c cb 17 f0    	sub    0xf017cb0c,%ebx
f0100f6f:	c1 fb 03             	sar    $0x3,%ebx
f0100f72:	c1 e3 0c             	shl    $0xc,%ebx
f0100f75:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f78:	83 c8 01             	or     $0x1,%eax
f0100f7b:	09 c3                	or     %eax,%ebx
f0100f7d:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)]|=perm;
f0100f7f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f82:	c1 e8 16             	shr    $0x16,%eax
f0100f85:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f88:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0100f8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f90:	eb 05                	jmp    f0100f97 <page_insert+0x70>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f0100f92:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
	pgdir[PDX(va)]|=perm;
	return 0;
}
f0100f97:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9a:	5b                   	pop    %ebx
f0100f9b:	5e                   	pop    %esi
f0100f9c:	5f                   	pop    %edi
f0100f9d:	5d                   	pop    %ebp
f0100f9e:	c3                   	ret    

f0100f9f <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f9f:	55                   	push   %ebp
f0100fa0:	89 e5                	mov    %esp,%ebp
f0100fa2:	57                   	push   %edi
f0100fa3:	56                   	push   %esi
f0100fa4:	53                   	push   %ebx
f0100fa5:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100fa8:	b8 15 00 00 00       	mov    $0x15,%eax
f0100fad:	e8 13 f9 ff ff       	call   f01008c5 <nvram_read>
f0100fb2:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100fb4:	b8 17 00 00 00       	mov    $0x17,%eax
f0100fb9:	e8 07 f9 ff ff       	call   f01008c5 <nvram_read>
f0100fbe:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100fc0:	b8 34 00 00 00       	mov    $0x34,%eax
f0100fc5:	e8 fb f8 ff ff       	call   f01008c5 <nvram_read>
f0100fca:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100fcd:	85 c0                	test   %eax,%eax
f0100fcf:	74 07                	je     f0100fd8 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100fd1:	05 00 40 00 00       	add    $0x4000,%eax
f0100fd6:	eb 0b                	jmp    f0100fe3 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100fd8:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100fde:	85 f6                	test   %esi,%esi
f0100fe0:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100fe3:	89 c2                	mov    %eax,%edx
f0100fe5:	c1 ea 02             	shr    $0x2,%edx
f0100fe8:	89 15 04 cb 17 f0    	mov    %edx,0xf017cb04
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100fee:	89 c2                	mov    %eax,%edx
f0100ff0:	29 da                	sub    %ebx,%edx
f0100ff2:	52                   	push   %edx
f0100ff3:	53                   	push   %ebx
f0100ff4:	50                   	push   %eax
f0100ff5:	68 b0 46 10 f0       	push   $0xf01046b0
f0100ffa:	e8 83 1d 00 00       	call   f0102d82 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100fff:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101004:	e8 84 f8 ff ff       	call   f010088d <boot_alloc>
f0101009:	a3 08 cb 17 f0       	mov    %eax,0xf017cb08
	memset(kern_pgdir, 0, PGSIZE);
f010100e:	83 c4 0c             	add    $0xc,%esp
f0101011:	68 00 10 00 00       	push   $0x1000
f0101016:	6a 00                	push   $0x0
f0101018:	50                   	push   %eax
f0101019:	e8 f6 2b 00 00       	call   f0103c14 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010101e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101023:	83 c4 10             	add    $0x10,%esp
f0101026:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010102b:	77 15                	ja     f0101042 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010102d:	50                   	push   %eax
f010102e:	68 44 46 10 f0       	push   $0xf0104644
f0101033:	68 90 00 00 00       	push   $0x90
f0101038:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010103d:	e8 5e f0 ff ff       	call   f01000a0 <_panic>
f0101042:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101048:	83 ca 05             	or     $0x5,%edx
f010104b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages*sizeof(struct PageInfo));
f0101051:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0101056:	c1 e0 03             	shl    $0x3,%eax
f0101059:	e8 2f f8 ff ff       	call   f010088d <boot_alloc>
f010105e:	a3 0c cb 17 f0       	mov    %eax,0xf017cb0c
        memset(pages,0,npages*sizeof(struct PageInfo));
f0101063:	83 ec 04             	sub    $0x4,%esp
f0101066:	8b 3d 04 cb 17 f0    	mov    0xf017cb04,%edi
f010106c:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101073:	52                   	push   %edx
f0101074:	6a 00                	push   $0x0
f0101076:	50                   	push   %eax
f0101077:	e8 98 2b 00 00       	call   f0103c14 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=boot_alloc(NENV*sizeof(struct Env));
f010107c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101081:	e8 07 f8 ff ff       	call   f010088d <boot_alloc>
f0101086:	a3 44 be 17 f0       	mov    %eax,0xf017be44
	memset(envs,0,NENV*sizeof(struct Env));
f010108b:	83 c4 0c             	add    $0xc,%esp
f010108e:	68 00 80 01 00       	push   $0x18000
f0101093:	6a 00                	push   $0x0
f0101095:	50                   	push   %eax
f0101096:	e8 79 2b 00 00       	call   f0103c14 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010109b:	e8 66 fb ff ff       	call   f0100c06 <page_init>
	check_page_free_list(1);
f01010a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01010a5:	e8 a8 f8 ff ff       	call   f0100952 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01010aa:	83 c4 10             	add    $0x10,%esp
f01010ad:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01010b4:	75 17                	jne    f01010cd <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f01010b6:	83 ec 04             	sub    $0x4,%esp
f01010b9:	68 c3 4d 10 f0       	push   $0xf0104dc3
f01010be:	68 9a 02 00 00       	push   $0x29a
f01010c3:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01010c8:	e8 d3 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010cd:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01010d2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010d7:	eb 05                	jmp    f01010de <mem_init+0x13f>
		++nfree;
f01010d9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010dc:	8b 00                	mov    (%eax),%eax
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	75 f7                	jne    f01010d9 <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010e2:	83 ec 0c             	sub    $0xc,%esp
f01010e5:	6a 00                	push   $0x0
f01010e7:	e8 e3 fb ff ff       	call   f0100ccf <page_alloc>
f01010ec:	89 c7                	mov    %eax,%edi
f01010ee:	83 c4 10             	add    $0x10,%esp
f01010f1:	85 c0                	test   %eax,%eax
f01010f3:	75 19                	jne    f010110e <mem_init+0x16f>
f01010f5:	68 de 4d 10 f0       	push   $0xf0104dde
f01010fa:	68 33 4d 10 f0       	push   $0xf0104d33
f01010ff:	68 a2 02 00 00       	push   $0x2a2
f0101104:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101109:	e8 92 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010110e:	83 ec 0c             	sub    $0xc,%esp
f0101111:	6a 00                	push   $0x0
f0101113:	e8 b7 fb ff ff       	call   f0100ccf <page_alloc>
f0101118:	89 c6                	mov    %eax,%esi
f010111a:	83 c4 10             	add    $0x10,%esp
f010111d:	85 c0                	test   %eax,%eax
f010111f:	75 19                	jne    f010113a <mem_init+0x19b>
f0101121:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101126:	68 33 4d 10 f0       	push   $0xf0104d33
f010112b:	68 a3 02 00 00       	push   $0x2a3
f0101130:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101135:	e8 66 ef ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010113a:	83 ec 0c             	sub    $0xc,%esp
f010113d:	6a 00                	push   $0x0
f010113f:	e8 8b fb ff ff       	call   f0100ccf <page_alloc>
f0101144:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101147:	83 c4 10             	add    $0x10,%esp
f010114a:	85 c0                	test   %eax,%eax
f010114c:	75 19                	jne    f0101167 <mem_init+0x1c8>
f010114e:	68 0a 4e 10 f0       	push   $0xf0104e0a
f0101153:	68 33 4d 10 f0       	push   $0xf0104d33
f0101158:	68 a4 02 00 00       	push   $0x2a4
f010115d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101162:	e8 39 ef ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101167:	39 f7                	cmp    %esi,%edi
f0101169:	75 19                	jne    f0101184 <mem_init+0x1e5>
f010116b:	68 20 4e 10 f0       	push   $0xf0104e20
f0101170:	68 33 4d 10 f0       	push   $0xf0104d33
f0101175:	68 a7 02 00 00       	push   $0x2a7
f010117a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010117f:	e8 1c ef ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101184:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101187:	39 c6                	cmp    %eax,%esi
f0101189:	74 04                	je     f010118f <mem_init+0x1f0>
f010118b:	39 c7                	cmp    %eax,%edi
f010118d:	75 19                	jne    f01011a8 <mem_init+0x209>
f010118f:	68 ec 46 10 f0       	push   $0xf01046ec
f0101194:	68 33 4d 10 f0       	push   $0xf0104d33
f0101199:	68 a8 02 00 00       	push   $0x2a8
f010119e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01011a3:	e8 f8 ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011a8:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01011ae:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01011b4:	c1 e2 0c             	shl    $0xc,%edx
f01011b7:	89 f8                	mov    %edi,%eax
f01011b9:	29 c8                	sub    %ecx,%eax
f01011bb:	c1 f8 03             	sar    $0x3,%eax
f01011be:	c1 e0 0c             	shl    $0xc,%eax
f01011c1:	39 d0                	cmp    %edx,%eax
f01011c3:	72 19                	jb     f01011de <mem_init+0x23f>
f01011c5:	68 32 4e 10 f0       	push   $0xf0104e32
f01011ca:	68 33 4d 10 f0       	push   $0xf0104d33
f01011cf:	68 a9 02 00 00       	push   $0x2a9
f01011d4:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01011d9:	e8 c2 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011de:	89 f0                	mov    %esi,%eax
f01011e0:	29 c8                	sub    %ecx,%eax
f01011e2:	c1 f8 03             	sar    $0x3,%eax
f01011e5:	c1 e0 0c             	shl    $0xc,%eax
f01011e8:	39 c2                	cmp    %eax,%edx
f01011ea:	77 19                	ja     f0101205 <mem_init+0x266>
f01011ec:	68 4f 4e 10 f0       	push   $0xf0104e4f
f01011f1:	68 33 4d 10 f0       	push   $0xf0104d33
f01011f6:	68 aa 02 00 00       	push   $0x2aa
f01011fb:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101200:	e8 9b ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101208:	29 c8                	sub    %ecx,%eax
f010120a:	c1 f8 03             	sar    $0x3,%eax
f010120d:	c1 e0 0c             	shl    $0xc,%eax
f0101210:	39 c2                	cmp    %eax,%edx
f0101212:	77 19                	ja     f010122d <mem_init+0x28e>
f0101214:	68 6c 4e 10 f0       	push   $0xf0104e6c
f0101219:	68 33 4d 10 f0       	push   $0xf0104d33
f010121e:	68 ab 02 00 00       	push   $0x2ab
f0101223:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101228:	e8 73 ee ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010122d:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101232:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101235:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f010123c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010123f:	83 ec 0c             	sub    $0xc,%esp
f0101242:	6a 00                	push   $0x0
f0101244:	e8 86 fa ff ff       	call   f0100ccf <page_alloc>
f0101249:	83 c4 10             	add    $0x10,%esp
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 19                	je     f0101269 <mem_init+0x2ca>
f0101250:	68 89 4e 10 f0       	push   $0xf0104e89
f0101255:	68 33 4d 10 f0       	push   $0xf0104d33
f010125a:	68 b2 02 00 00       	push   $0x2b2
f010125f:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101264:	e8 37 ee ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101269:	83 ec 0c             	sub    $0xc,%esp
f010126c:	57                   	push   %edi
f010126d:	e8 cd fa ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101272:	89 34 24             	mov    %esi,(%esp)
f0101275:	e8 c5 fa ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f010127a:	83 c4 04             	add    $0x4,%esp
f010127d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101280:	e8 ba fa ff ff       	call   f0100d3f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101285:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010128c:	e8 3e fa ff ff       	call   f0100ccf <page_alloc>
f0101291:	89 c6                	mov    %eax,%esi
f0101293:	83 c4 10             	add    $0x10,%esp
f0101296:	85 c0                	test   %eax,%eax
f0101298:	75 19                	jne    f01012b3 <mem_init+0x314>
f010129a:	68 de 4d 10 f0       	push   $0xf0104dde
f010129f:	68 33 4d 10 f0       	push   $0xf0104d33
f01012a4:	68 b9 02 00 00       	push   $0x2b9
f01012a9:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01012ae:	e8 ed ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012b3:	83 ec 0c             	sub    $0xc,%esp
f01012b6:	6a 00                	push   $0x0
f01012b8:	e8 12 fa ff ff       	call   f0100ccf <page_alloc>
f01012bd:	89 c7                	mov    %eax,%edi
f01012bf:	83 c4 10             	add    $0x10,%esp
f01012c2:	85 c0                	test   %eax,%eax
f01012c4:	75 19                	jne    f01012df <mem_init+0x340>
f01012c6:	68 f4 4d 10 f0       	push   $0xf0104df4
f01012cb:	68 33 4d 10 f0       	push   $0xf0104d33
f01012d0:	68 ba 02 00 00       	push   $0x2ba
f01012d5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01012da:	e8 c1 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012df:	83 ec 0c             	sub    $0xc,%esp
f01012e2:	6a 00                	push   $0x0
f01012e4:	e8 e6 f9 ff ff       	call   f0100ccf <page_alloc>
f01012e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012ec:	83 c4 10             	add    $0x10,%esp
f01012ef:	85 c0                	test   %eax,%eax
f01012f1:	75 19                	jne    f010130c <mem_init+0x36d>
f01012f3:	68 0a 4e 10 f0       	push   $0xf0104e0a
f01012f8:	68 33 4d 10 f0       	push   $0xf0104d33
f01012fd:	68 bb 02 00 00       	push   $0x2bb
f0101302:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101307:	e8 94 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010130c:	39 fe                	cmp    %edi,%esi
f010130e:	75 19                	jne    f0101329 <mem_init+0x38a>
f0101310:	68 20 4e 10 f0       	push   $0xf0104e20
f0101315:	68 33 4d 10 f0       	push   $0xf0104d33
f010131a:	68 bd 02 00 00       	push   $0x2bd
f010131f:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101324:	e8 77 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101329:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010132c:	39 c7                	cmp    %eax,%edi
f010132e:	74 04                	je     f0101334 <mem_init+0x395>
f0101330:	39 c6                	cmp    %eax,%esi
f0101332:	75 19                	jne    f010134d <mem_init+0x3ae>
f0101334:	68 ec 46 10 f0       	push   $0xf01046ec
f0101339:	68 33 4d 10 f0       	push   $0xf0104d33
f010133e:	68 be 02 00 00       	push   $0x2be
f0101343:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101348:	e8 53 ed ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010134d:	83 ec 0c             	sub    $0xc,%esp
f0101350:	6a 00                	push   $0x0
f0101352:	e8 78 f9 ff ff       	call   f0100ccf <page_alloc>
f0101357:	83 c4 10             	add    $0x10,%esp
f010135a:	85 c0                	test   %eax,%eax
f010135c:	74 19                	je     f0101377 <mem_init+0x3d8>
f010135e:	68 89 4e 10 f0       	push   $0xf0104e89
f0101363:	68 33 4d 10 f0       	push   $0xf0104d33
f0101368:	68 bf 02 00 00       	push   $0x2bf
f010136d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101372:	e8 29 ed ff ff       	call   f01000a0 <_panic>
f0101377:	89 f0                	mov    %esi,%eax
f0101379:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010137f:	c1 f8 03             	sar    $0x3,%eax
f0101382:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101385:	89 c2                	mov    %eax,%edx
f0101387:	c1 ea 0c             	shr    $0xc,%edx
f010138a:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0101390:	72 12                	jb     f01013a4 <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101392:	50                   	push   %eax
f0101393:	68 5c 45 10 f0       	push   $0xf010455c
f0101398:	6a 56                	push   $0x56
f010139a:	68 19 4d 10 f0       	push   $0xf0104d19
f010139f:	e8 fc ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013a4:	83 ec 04             	sub    $0x4,%esp
f01013a7:	68 00 10 00 00       	push   $0x1000
f01013ac:	6a 01                	push   $0x1
f01013ae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013b3:	50                   	push   %eax
f01013b4:	e8 5b 28 00 00       	call   f0103c14 <memset>
	page_free(pp0);
f01013b9:	89 34 24             	mov    %esi,(%esp)
f01013bc:	e8 7e f9 ff ff       	call   f0100d3f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013c1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013c8:	e8 02 f9 ff ff       	call   f0100ccf <page_alloc>
f01013cd:	83 c4 10             	add    $0x10,%esp
f01013d0:	85 c0                	test   %eax,%eax
f01013d2:	75 19                	jne    f01013ed <mem_init+0x44e>
f01013d4:	68 98 4e 10 f0       	push   $0xf0104e98
f01013d9:	68 33 4d 10 f0       	push   $0xf0104d33
f01013de:	68 c4 02 00 00       	push   $0x2c4
f01013e3:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01013e8:	e8 b3 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01013ed:	39 c6                	cmp    %eax,%esi
f01013ef:	74 19                	je     f010140a <mem_init+0x46b>
f01013f1:	68 b6 4e 10 f0       	push   $0xf0104eb6
f01013f6:	68 33 4d 10 f0       	push   $0xf0104d33
f01013fb:	68 c5 02 00 00       	push   $0x2c5
f0101400:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101405:	e8 96 ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010140a:	89 f0                	mov    %esi,%eax
f010140c:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101412:	c1 f8 03             	sar    $0x3,%eax
f0101415:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101418:	89 c2                	mov    %eax,%edx
f010141a:	c1 ea 0c             	shr    $0xc,%edx
f010141d:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0101423:	72 12                	jb     f0101437 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101425:	50                   	push   %eax
f0101426:	68 5c 45 10 f0       	push   $0xf010455c
f010142b:	6a 56                	push   $0x56
f010142d:	68 19 4d 10 f0       	push   $0xf0104d19
f0101432:	e8 69 ec ff ff       	call   f01000a0 <_panic>
f0101437:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010143d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101443:	80 38 00             	cmpb   $0x0,(%eax)
f0101446:	74 19                	je     f0101461 <mem_init+0x4c2>
f0101448:	68 c6 4e 10 f0       	push   $0xf0104ec6
f010144d:	68 33 4d 10 f0       	push   $0xf0104d33
f0101452:	68 c8 02 00 00       	push   $0x2c8
f0101457:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010145c:	e8 3f ec ff ff       	call   f01000a0 <_panic>
f0101461:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101464:	39 d0                	cmp    %edx,%eax
f0101466:	75 db                	jne    f0101443 <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101468:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010146b:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101470:	83 ec 0c             	sub    $0xc,%esp
f0101473:	56                   	push   %esi
f0101474:	e8 c6 f8 ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101479:	89 3c 24             	mov    %edi,(%esp)
f010147c:	e8 be f8 ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f0101481:	83 c4 04             	add    $0x4,%esp
f0101484:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101487:	e8 b3 f8 ff ff       	call   f0100d3f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010148c:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101491:	83 c4 10             	add    $0x10,%esp
f0101494:	eb 05                	jmp    f010149b <mem_init+0x4fc>
		--nfree;
f0101496:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101499:	8b 00                	mov    (%eax),%eax
f010149b:	85 c0                	test   %eax,%eax
f010149d:	75 f7                	jne    f0101496 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f010149f:	85 db                	test   %ebx,%ebx
f01014a1:	74 19                	je     f01014bc <mem_init+0x51d>
f01014a3:	68 d0 4e 10 f0       	push   $0xf0104ed0
f01014a8:	68 33 4d 10 f0       	push   $0xf0104d33
f01014ad:	68 d5 02 00 00       	push   $0x2d5
f01014b2:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01014b7:	e8 e4 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014bc:	83 ec 0c             	sub    $0xc,%esp
f01014bf:	68 0c 47 10 f0       	push   $0xf010470c
f01014c4:	e8 b9 18 00 00       	call   f0102d82 <cprintf>
	void *va;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014d0:	e8 fa f7 ff ff       	call   f0100ccf <page_alloc>
f01014d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014d8:	83 c4 10             	add    $0x10,%esp
f01014db:	85 c0                	test   %eax,%eax
f01014dd:	75 19                	jne    f01014f8 <mem_init+0x559>
f01014df:	68 de 4d 10 f0       	push   $0xf0104dde
f01014e4:	68 33 4d 10 f0       	push   $0xf0104d33
f01014e9:	68 32 03 00 00       	push   $0x332
f01014ee:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01014f3:	e8 a8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014f8:	83 ec 0c             	sub    $0xc,%esp
f01014fb:	6a 00                	push   $0x0
f01014fd:	e8 cd f7 ff ff       	call   f0100ccf <page_alloc>
f0101502:	89 c3                	mov    %eax,%ebx
f0101504:	83 c4 10             	add    $0x10,%esp
f0101507:	85 c0                	test   %eax,%eax
f0101509:	75 19                	jne    f0101524 <mem_init+0x585>
f010150b:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101510:	68 33 4d 10 f0       	push   $0xf0104d33
f0101515:	68 33 03 00 00       	push   $0x333
f010151a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010151f:	e8 7c eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101524:	83 ec 0c             	sub    $0xc,%esp
f0101527:	6a 00                	push   $0x0
f0101529:	e8 a1 f7 ff ff       	call   f0100ccf <page_alloc>
f010152e:	89 c6                	mov    %eax,%esi
f0101530:	83 c4 10             	add    $0x10,%esp
f0101533:	85 c0                	test   %eax,%eax
f0101535:	75 19                	jne    f0101550 <mem_init+0x5b1>
f0101537:	68 0a 4e 10 f0       	push   $0xf0104e0a
f010153c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101541:	68 34 03 00 00       	push   $0x334
f0101546:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010154b:	e8 50 eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101550:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101553:	75 19                	jne    f010156e <mem_init+0x5cf>
f0101555:	68 20 4e 10 f0       	push   $0xf0104e20
f010155a:	68 33 4d 10 f0       	push   $0xf0104d33
f010155f:	68 37 03 00 00       	push   $0x337
f0101564:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101569:	e8 32 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010156e:	39 c3                	cmp    %eax,%ebx
f0101570:	74 05                	je     f0101577 <mem_init+0x5d8>
f0101572:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101575:	75 19                	jne    f0101590 <mem_init+0x5f1>
f0101577:	68 ec 46 10 f0       	push   $0xf01046ec
f010157c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101581:	68 38 03 00 00       	push   $0x338
f0101586:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010158b:	e8 10 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101590:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101595:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101598:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f010159f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015a2:	83 ec 0c             	sub    $0xc,%esp
f01015a5:	6a 00                	push   $0x0
f01015a7:	e8 23 f7 ff ff       	call   f0100ccf <page_alloc>
f01015ac:	83 c4 10             	add    $0x10,%esp
f01015af:	85 c0                	test   %eax,%eax
f01015b1:	74 19                	je     f01015cc <mem_init+0x62d>
f01015b3:	68 89 4e 10 f0       	push   $0xf0104e89
f01015b8:	68 33 4d 10 f0       	push   $0xf0104d33
f01015bd:	68 3f 03 00 00       	push   $0x33f
f01015c2:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01015c7:	e8 d4 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01015cc:	83 ec 04             	sub    $0x4,%esp
f01015cf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015d2:	50                   	push   %eax
f01015d3:	6a 00                	push   $0x0
f01015d5:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01015db:	e8 9f f8 ff ff       	call   f0100e7f <page_lookup>
f01015e0:	83 c4 10             	add    $0x10,%esp
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	74 19                	je     f0101600 <mem_init+0x661>
f01015e7:	68 2c 47 10 f0       	push   $0xf010472c
f01015ec:	68 33 4d 10 f0       	push   $0xf0104d33
f01015f1:	68 42 03 00 00       	push   $0x342
f01015f6:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01015fb:	e8 a0 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101600:	6a 02                	push   $0x2
f0101602:	6a 00                	push   $0x0
f0101604:	53                   	push   %ebx
f0101605:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010160b:	e8 17 f9 ff ff       	call   f0100f27 <page_insert>
f0101610:	83 c4 10             	add    $0x10,%esp
f0101613:	85 c0                	test   %eax,%eax
f0101615:	78 19                	js     f0101630 <mem_init+0x691>
f0101617:	68 64 47 10 f0       	push   $0xf0104764
f010161c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101621:	68 45 03 00 00       	push   $0x345
f0101626:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010162b:	e8 70 ea ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101630:	83 ec 0c             	sub    $0xc,%esp
f0101633:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101636:	e8 04 f7 ff ff       	call   f0100d3f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010163b:	6a 02                	push   $0x2
f010163d:	6a 00                	push   $0x0
f010163f:	53                   	push   %ebx
f0101640:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101646:	e8 dc f8 ff ff       	call   f0100f27 <page_insert>
f010164b:	83 c4 20             	add    $0x20,%esp
f010164e:	85 c0                	test   %eax,%eax
f0101650:	74 19                	je     f010166b <mem_init+0x6cc>
f0101652:	68 94 47 10 f0       	push   $0xf0104794
f0101657:	68 33 4d 10 f0       	push   $0xf0104d33
f010165c:	68 49 03 00 00       	push   $0x349
f0101661:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101666:	e8 35 ea ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010166b:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101671:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0101676:	89 c1                	mov    %eax,%ecx
f0101678:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010167b:	8b 17                	mov    (%edi),%edx
f010167d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101683:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101686:	29 c8                	sub    %ecx,%eax
f0101688:	c1 f8 03             	sar    $0x3,%eax
f010168b:	c1 e0 0c             	shl    $0xc,%eax
f010168e:	39 c2                	cmp    %eax,%edx
f0101690:	74 19                	je     f01016ab <mem_init+0x70c>
f0101692:	68 c4 47 10 f0       	push   $0xf01047c4
f0101697:	68 33 4d 10 f0       	push   $0xf0104d33
f010169c:	68 4a 03 00 00       	push   $0x34a
f01016a1:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01016a6:	e8 f5 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01016ab:	ba 00 00 00 00       	mov    $0x0,%edx
f01016b0:	89 f8                	mov    %edi,%eax
f01016b2:	e8 37 f2 ff ff       	call   f01008ee <check_va2pa>
f01016b7:	89 da                	mov    %ebx,%edx
f01016b9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016bc:	c1 fa 03             	sar    $0x3,%edx
f01016bf:	c1 e2 0c             	shl    $0xc,%edx
f01016c2:	39 d0                	cmp    %edx,%eax
f01016c4:	74 19                	je     f01016df <mem_init+0x740>
f01016c6:	68 ec 47 10 f0       	push   $0xf01047ec
f01016cb:	68 33 4d 10 f0       	push   $0xf0104d33
f01016d0:	68 4b 03 00 00       	push   $0x34b
f01016d5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01016da:	e8 c1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01016df:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016e4:	74 19                	je     f01016ff <mem_init+0x760>
f01016e6:	68 db 4e 10 f0       	push   $0xf0104edb
f01016eb:	68 33 4d 10 f0       	push   $0xf0104d33
f01016f0:	68 4c 03 00 00       	push   $0x34c
f01016f5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01016fa:	e8 a1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01016ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101702:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101707:	74 19                	je     f0101722 <mem_init+0x783>
f0101709:	68 ec 4e 10 f0       	push   $0xf0104eec
f010170e:	68 33 4d 10 f0       	push   $0xf0104d33
f0101713:	68 4d 03 00 00       	push   $0x34d
f0101718:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010171d:	e8 7e e9 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101722:	6a 02                	push   $0x2
f0101724:	68 00 10 00 00       	push   $0x1000
f0101729:	56                   	push   %esi
f010172a:	57                   	push   %edi
f010172b:	e8 f7 f7 ff ff       	call   f0100f27 <page_insert>
f0101730:	83 c4 10             	add    $0x10,%esp
f0101733:	85 c0                	test   %eax,%eax
f0101735:	74 19                	je     f0101750 <mem_init+0x7b1>
f0101737:	68 1c 48 10 f0       	push   $0xf010481c
f010173c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101741:	68 50 03 00 00       	push   $0x350
f0101746:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010174b:	e8 50 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101750:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101755:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010175a:	e8 8f f1 ff ff       	call   f01008ee <check_va2pa>
f010175f:	89 f2                	mov    %esi,%edx
f0101761:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101767:	c1 fa 03             	sar    $0x3,%edx
f010176a:	c1 e2 0c             	shl    $0xc,%edx
f010176d:	39 d0                	cmp    %edx,%eax
f010176f:	74 19                	je     f010178a <mem_init+0x7eb>
f0101771:	68 58 48 10 f0       	push   $0xf0104858
f0101776:	68 33 4d 10 f0       	push   $0xf0104d33
f010177b:	68 51 03 00 00       	push   $0x351
f0101780:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101785:	e8 16 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010178a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010178f:	74 19                	je     f01017aa <mem_init+0x80b>
f0101791:	68 fd 4e 10 f0       	push   $0xf0104efd
f0101796:	68 33 4d 10 f0       	push   $0xf0104d33
f010179b:	68 52 03 00 00       	push   $0x352
f01017a0:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01017a5:	e8 f6 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01017aa:	83 ec 0c             	sub    $0xc,%esp
f01017ad:	6a 00                	push   $0x0
f01017af:	e8 1b f5 ff ff       	call   f0100ccf <page_alloc>
f01017b4:	83 c4 10             	add    $0x10,%esp
f01017b7:	85 c0                	test   %eax,%eax
f01017b9:	74 19                	je     f01017d4 <mem_init+0x835>
f01017bb:	68 89 4e 10 f0       	push   $0xf0104e89
f01017c0:	68 33 4d 10 f0       	push   $0xf0104d33
f01017c5:	68 55 03 00 00       	push   $0x355
f01017ca:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01017cf:	e8 cc e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017d4:	6a 02                	push   $0x2
f01017d6:	68 00 10 00 00       	push   $0x1000
f01017db:	56                   	push   %esi
f01017dc:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01017e2:	e8 40 f7 ff ff       	call   f0100f27 <page_insert>
f01017e7:	83 c4 10             	add    $0x10,%esp
f01017ea:	85 c0                	test   %eax,%eax
f01017ec:	74 19                	je     f0101807 <mem_init+0x868>
f01017ee:	68 1c 48 10 f0       	push   $0xf010481c
f01017f3:	68 33 4d 10 f0       	push   $0xf0104d33
f01017f8:	68 58 03 00 00       	push   $0x358
f01017fd:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101802:	e8 99 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101807:	ba 00 10 00 00       	mov    $0x1000,%edx
f010180c:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101811:	e8 d8 f0 ff ff       	call   f01008ee <check_va2pa>
f0101816:	89 f2                	mov    %esi,%edx
f0101818:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f010181e:	c1 fa 03             	sar    $0x3,%edx
f0101821:	c1 e2 0c             	shl    $0xc,%edx
f0101824:	39 d0                	cmp    %edx,%eax
f0101826:	74 19                	je     f0101841 <mem_init+0x8a2>
f0101828:	68 58 48 10 f0       	push   $0xf0104858
f010182d:	68 33 4d 10 f0       	push   $0xf0104d33
f0101832:	68 59 03 00 00       	push   $0x359
f0101837:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010183c:	e8 5f e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101841:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101846:	74 19                	je     f0101861 <mem_init+0x8c2>
f0101848:	68 fd 4e 10 f0       	push   $0xf0104efd
f010184d:	68 33 4d 10 f0       	push   $0xf0104d33
f0101852:	68 5a 03 00 00       	push   $0x35a
f0101857:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010185c:	e8 3f e8 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101861:	83 ec 0c             	sub    $0xc,%esp
f0101864:	6a 00                	push   $0x0
f0101866:	e8 64 f4 ff ff       	call   f0100ccf <page_alloc>
f010186b:	83 c4 10             	add    $0x10,%esp
f010186e:	85 c0                	test   %eax,%eax
f0101870:	74 19                	je     f010188b <mem_init+0x8ec>
f0101872:	68 89 4e 10 f0       	push   $0xf0104e89
f0101877:	68 33 4d 10 f0       	push   $0xf0104d33
f010187c:	68 5e 03 00 00       	push   $0x35e
f0101881:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101886:	e8 15 e8 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010188b:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f0101891:	8b 02                	mov    (%edx),%eax
f0101893:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101898:	89 c1                	mov    %eax,%ecx
f010189a:	c1 e9 0c             	shr    $0xc,%ecx
f010189d:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f01018a3:	72 15                	jb     f01018ba <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018a5:	50                   	push   %eax
f01018a6:	68 5c 45 10 f0       	push   $0xf010455c
f01018ab:	68 61 03 00 00       	push   $0x361
f01018b0:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01018b5:	e8 e6 e7 ff ff       	call   f01000a0 <_panic>
f01018ba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01018c2:	83 ec 04             	sub    $0x4,%esp
f01018c5:	6a 00                	push   $0x0
f01018c7:	68 00 10 00 00       	push   $0x1000
f01018cc:	52                   	push   %edx
f01018cd:	e8 d1 f4 ff ff       	call   f0100da3 <pgdir_walk>
f01018d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018d5:	8d 57 04             	lea    0x4(%edi),%edx
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	39 d0                	cmp    %edx,%eax
f01018dd:	74 19                	je     f01018f8 <mem_init+0x959>
f01018df:	68 88 48 10 f0       	push   $0xf0104888
f01018e4:	68 33 4d 10 f0       	push   $0xf0104d33
f01018e9:	68 62 03 00 00       	push   $0x362
f01018ee:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01018f3:	e8 a8 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01018f8:	6a 06                	push   $0x6
f01018fa:	68 00 10 00 00       	push   $0x1000
f01018ff:	56                   	push   %esi
f0101900:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101906:	e8 1c f6 ff ff       	call   f0100f27 <page_insert>
f010190b:	83 c4 10             	add    $0x10,%esp
f010190e:	85 c0                	test   %eax,%eax
f0101910:	74 19                	je     f010192b <mem_init+0x98c>
f0101912:	68 c8 48 10 f0       	push   $0xf01048c8
f0101917:	68 33 4d 10 f0       	push   $0xf0104d33
f010191c:	68 65 03 00 00       	push   $0x365
f0101921:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101926:	e8 75 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010192b:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101931:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101936:	89 f8                	mov    %edi,%eax
f0101938:	e8 b1 ef ff ff       	call   f01008ee <check_va2pa>
f010193d:	89 f2                	mov    %esi,%edx
f010193f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101945:	c1 fa 03             	sar    $0x3,%edx
f0101948:	c1 e2 0c             	shl    $0xc,%edx
f010194b:	39 d0                	cmp    %edx,%eax
f010194d:	74 19                	je     f0101968 <mem_init+0x9c9>
f010194f:	68 58 48 10 f0       	push   $0xf0104858
f0101954:	68 33 4d 10 f0       	push   $0xf0104d33
f0101959:	68 66 03 00 00       	push   $0x366
f010195e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101963:	e8 38 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101968:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010196d:	74 19                	je     f0101988 <mem_init+0x9e9>
f010196f:	68 fd 4e 10 f0       	push   $0xf0104efd
f0101974:	68 33 4d 10 f0       	push   $0xf0104d33
f0101979:	68 67 03 00 00       	push   $0x367
f010197e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101983:	e8 18 e7 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101988:	83 ec 04             	sub    $0x4,%esp
f010198b:	6a 00                	push   $0x0
f010198d:	68 00 10 00 00       	push   $0x1000
f0101992:	57                   	push   %edi
f0101993:	e8 0b f4 ff ff       	call   f0100da3 <pgdir_walk>
f0101998:	83 c4 10             	add    $0x10,%esp
f010199b:	f6 00 04             	testb  $0x4,(%eax)
f010199e:	75 19                	jne    f01019b9 <mem_init+0xa1a>
f01019a0:	68 08 49 10 f0       	push   $0xf0104908
f01019a5:	68 33 4d 10 f0       	push   $0xf0104d33
f01019aa:	68 68 03 00 00       	push   $0x368
f01019af:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01019b4:	e8 e7 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019b9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01019be:	f6 00 04             	testb  $0x4,(%eax)
f01019c1:	75 19                	jne    f01019dc <mem_init+0xa3d>
f01019c3:	68 0e 4f 10 f0       	push   $0xf0104f0e
f01019c8:	68 33 4d 10 f0       	push   $0xf0104d33
f01019cd:	68 69 03 00 00       	push   $0x369
f01019d2:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01019d7:	e8 c4 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019dc:	6a 02                	push   $0x2
f01019de:	68 00 10 00 00       	push   $0x1000
f01019e3:	56                   	push   %esi
f01019e4:	50                   	push   %eax
f01019e5:	e8 3d f5 ff ff       	call   f0100f27 <page_insert>
f01019ea:	83 c4 10             	add    $0x10,%esp
f01019ed:	85 c0                	test   %eax,%eax
f01019ef:	74 19                	je     f0101a0a <mem_init+0xa6b>
f01019f1:	68 1c 48 10 f0       	push   $0xf010481c
f01019f6:	68 33 4d 10 f0       	push   $0xf0104d33
f01019fb:	68 6c 03 00 00       	push   $0x36c
f0101a00:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101a05:	e8 96 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a0a:	83 ec 04             	sub    $0x4,%esp
f0101a0d:	6a 00                	push   $0x0
f0101a0f:	68 00 10 00 00       	push   $0x1000
f0101a14:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a1a:	e8 84 f3 ff ff       	call   f0100da3 <pgdir_walk>
f0101a1f:	83 c4 10             	add    $0x10,%esp
f0101a22:	f6 00 02             	testb  $0x2,(%eax)
f0101a25:	75 19                	jne    f0101a40 <mem_init+0xaa1>
f0101a27:	68 3c 49 10 f0       	push   $0xf010493c
f0101a2c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101a31:	68 6d 03 00 00       	push   $0x36d
f0101a36:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101a3b:	e8 60 e6 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a40:	83 ec 04             	sub    $0x4,%esp
f0101a43:	6a 00                	push   $0x0
f0101a45:	68 00 10 00 00       	push   $0x1000
f0101a4a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a50:	e8 4e f3 ff ff       	call   f0100da3 <pgdir_walk>
f0101a55:	83 c4 10             	add    $0x10,%esp
f0101a58:	f6 00 04             	testb  $0x4,(%eax)
f0101a5b:	74 19                	je     f0101a76 <mem_init+0xad7>
f0101a5d:	68 70 49 10 f0       	push   $0xf0104970
f0101a62:	68 33 4d 10 f0       	push   $0xf0104d33
f0101a67:	68 6e 03 00 00       	push   $0x36e
f0101a6c:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101a71:	e8 2a e6 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101a76:	6a 02                	push   $0x2
f0101a78:	68 00 00 40 00       	push   $0x400000
f0101a7d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a80:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a86:	e8 9c f4 ff ff       	call   f0100f27 <page_insert>
f0101a8b:	83 c4 10             	add    $0x10,%esp
f0101a8e:	85 c0                	test   %eax,%eax
f0101a90:	78 19                	js     f0101aab <mem_init+0xb0c>
f0101a92:	68 a8 49 10 f0       	push   $0xf01049a8
f0101a97:	68 33 4d 10 f0       	push   $0xf0104d33
f0101a9c:	68 71 03 00 00       	push   $0x371
f0101aa1:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101aa6:	e8 f5 e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101aab:	6a 02                	push   $0x2
f0101aad:	68 00 10 00 00       	push   $0x1000
f0101ab2:	53                   	push   %ebx
f0101ab3:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101ab9:	e8 69 f4 ff ff       	call   f0100f27 <page_insert>
f0101abe:	83 c4 10             	add    $0x10,%esp
f0101ac1:	85 c0                	test   %eax,%eax
f0101ac3:	74 19                	je     f0101ade <mem_init+0xb3f>
f0101ac5:	68 e4 49 10 f0       	push   $0xf01049e4
f0101aca:	68 33 4d 10 f0       	push   $0xf0104d33
f0101acf:	68 74 03 00 00       	push   $0x374
f0101ad4:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101ad9:	e8 c2 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ade:	83 ec 04             	sub    $0x4,%esp
f0101ae1:	6a 00                	push   $0x0
f0101ae3:	68 00 10 00 00       	push   $0x1000
f0101ae8:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101aee:	e8 b0 f2 ff ff       	call   f0100da3 <pgdir_walk>
f0101af3:	83 c4 10             	add    $0x10,%esp
f0101af6:	f6 00 04             	testb  $0x4,(%eax)
f0101af9:	74 19                	je     f0101b14 <mem_init+0xb75>
f0101afb:	68 70 49 10 f0       	push   $0xf0104970
f0101b00:	68 33 4d 10 f0       	push   $0xf0104d33
f0101b05:	68 75 03 00 00       	push   $0x375
f0101b0a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101b0f:	e8 8c e5 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b14:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101b1a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b1f:	89 f8                	mov    %edi,%eax
f0101b21:	e8 c8 ed ff ff       	call   f01008ee <check_va2pa>
f0101b26:	89 c1                	mov    %eax,%ecx
f0101b28:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b2b:	89 d8                	mov    %ebx,%eax
f0101b2d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101b33:	c1 f8 03             	sar    $0x3,%eax
f0101b36:	c1 e0 0c             	shl    $0xc,%eax
f0101b39:	39 c1                	cmp    %eax,%ecx
f0101b3b:	74 19                	je     f0101b56 <mem_init+0xbb7>
f0101b3d:	68 20 4a 10 f0       	push   $0xf0104a20
f0101b42:	68 33 4d 10 f0       	push   $0xf0104d33
f0101b47:	68 78 03 00 00       	push   $0x378
f0101b4c:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101b51:	e8 4a e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b56:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b5b:	89 f8                	mov    %edi,%eax
f0101b5d:	e8 8c ed ff ff       	call   f01008ee <check_va2pa>
f0101b62:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b65:	74 19                	je     f0101b80 <mem_init+0xbe1>
f0101b67:	68 4c 4a 10 f0       	push   $0xf0104a4c
f0101b6c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101b71:	68 79 03 00 00       	push   $0x379
f0101b76:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101b7b:	e8 20 e5 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b80:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b85:	74 19                	je     f0101ba0 <mem_init+0xc01>
f0101b87:	68 24 4f 10 f0       	push   $0xf0104f24
f0101b8c:	68 33 4d 10 f0       	push   $0xf0104d33
f0101b91:	68 7b 03 00 00       	push   $0x37b
f0101b96:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101b9b:	e8 00 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ba0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ba5:	74 19                	je     f0101bc0 <mem_init+0xc21>
f0101ba7:	68 35 4f 10 f0       	push   $0xf0104f35
f0101bac:	68 33 4d 10 f0       	push   $0xf0104d33
f0101bb1:	68 7c 03 00 00       	push   $0x37c
f0101bb6:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101bbb:	e8 e0 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101bc0:	83 ec 0c             	sub    $0xc,%esp
f0101bc3:	6a 00                	push   $0x0
f0101bc5:	e8 05 f1 ff ff       	call   f0100ccf <page_alloc>
f0101bca:	83 c4 10             	add    $0x10,%esp
f0101bcd:	39 c6                	cmp    %eax,%esi
f0101bcf:	75 04                	jne    f0101bd5 <mem_init+0xc36>
f0101bd1:	85 c0                	test   %eax,%eax
f0101bd3:	75 19                	jne    f0101bee <mem_init+0xc4f>
f0101bd5:	68 7c 4a 10 f0       	push   $0xf0104a7c
f0101bda:	68 33 4d 10 f0       	push   $0xf0104d33
f0101bdf:	68 7f 03 00 00       	push   $0x37f
f0101be4:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101be9:	e8 b2 e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101bee:	83 ec 08             	sub    $0x8,%esp
f0101bf1:	6a 00                	push   $0x0
f0101bf3:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101bf9:	e8 e7 f2 ff ff       	call   f0100ee5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101bfe:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101c04:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c09:	89 f8                	mov    %edi,%eax
f0101c0b:	e8 de ec ff ff       	call   f01008ee <check_va2pa>
f0101c10:	83 c4 10             	add    $0x10,%esp
f0101c13:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c16:	74 19                	je     f0101c31 <mem_init+0xc92>
f0101c18:	68 a0 4a 10 f0       	push   $0xf0104aa0
f0101c1d:	68 33 4d 10 f0       	push   $0xf0104d33
f0101c22:	68 83 03 00 00       	push   $0x383
f0101c27:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101c2c:	e8 6f e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c31:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c36:	89 f8                	mov    %edi,%eax
f0101c38:	e8 b1 ec ff ff       	call   f01008ee <check_va2pa>
f0101c3d:	89 da                	mov    %ebx,%edx
f0101c3f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101c45:	c1 fa 03             	sar    $0x3,%edx
f0101c48:	c1 e2 0c             	shl    $0xc,%edx
f0101c4b:	39 d0                	cmp    %edx,%eax
f0101c4d:	74 19                	je     f0101c68 <mem_init+0xcc9>
f0101c4f:	68 4c 4a 10 f0       	push   $0xf0104a4c
f0101c54:	68 33 4d 10 f0       	push   $0xf0104d33
f0101c59:	68 84 03 00 00       	push   $0x384
f0101c5e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101c63:	e8 38 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101c68:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c6d:	74 19                	je     f0101c88 <mem_init+0xce9>
f0101c6f:	68 db 4e 10 f0       	push   $0xf0104edb
f0101c74:	68 33 4d 10 f0       	push   $0xf0104d33
f0101c79:	68 85 03 00 00       	push   $0x385
f0101c7e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101c83:	e8 18 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c88:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xd09>
f0101c8f:	68 35 4f 10 f0       	push   $0xf0104f35
f0101c94:	68 33 4d 10 f0       	push   $0xf0104d33
f0101c99:	68 86 03 00 00       	push   $0x386
f0101c9e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101ca3:	e8 f8 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ca8:	6a 00                	push   $0x0
f0101caa:	68 00 10 00 00       	push   $0x1000
f0101caf:	53                   	push   %ebx
f0101cb0:	57                   	push   %edi
f0101cb1:	e8 71 f2 ff ff       	call   f0100f27 <page_insert>
f0101cb6:	83 c4 10             	add    $0x10,%esp
f0101cb9:	85 c0                	test   %eax,%eax
f0101cbb:	74 19                	je     f0101cd6 <mem_init+0xd37>
f0101cbd:	68 c4 4a 10 f0       	push   $0xf0104ac4
f0101cc2:	68 33 4d 10 f0       	push   $0xf0104d33
f0101cc7:	68 89 03 00 00       	push   $0x389
f0101ccc:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101cd1:	e8 ca e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101cd6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cdb:	75 19                	jne    f0101cf6 <mem_init+0xd57>
f0101cdd:	68 46 4f 10 f0       	push   $0xf0104f46
f0101ce2:	68 33 4d 10 f0       	push   $0xf0104d33
f0101ce7:	68 8a 03 00 00       	push   $0x38a
f0101cec:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101cf6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101cf9:	74 19                	je     f0101d14 <mem_init+0xd75>
f0101cfb:	68 52 4f 10 f0       	push   $0xf0104f52
f0101d00:	68 33 4d 10 f0       	push   $0xf0104d33
f0101d05:	68 8b 03 00 00       	push   $0x38b
f0101d0a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101d0f:	e8 8c e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d14:	83 ec 08             	sub    $0x8,%esp
f0101d17:	68 00 10 00 00       	push   $0x1000
f0101d1c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d22:	e8 be f1 ff ff       	call   f0100ee5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d27:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d2d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d32:	89 f8                	mov    %edi,%eax
f0101d34:	e8 b5 eb ff ff       	call   f01008ee <check_va2pa>
f0101d39:	83 c4 10             	add    $0x10,%esp
f0101d3c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d3f:	74 19                	je     f0101d5a <mem_init+0xdbb>
f0101d41:	68 a0 4a 10 f0       	push   $0xf0104aa0
f0101d46:	68 33 4d 10 f0       	push   $0xf0104d33
f0101d4b:	68 8f 03 00 00       	push   $0x38f
f0101d50:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101d55:	e8 46 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d5f:	89 f8                	mov    %edi,%eax
f0101d61:	e8 88 eb ff ff       	call   f01008ee <check_va2pa>
f0101d66:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d69:	74 19                	je     f0101d84 <mem_init+0xde5>
f0101d6b:	68 fc 4a 10 f0       	push   $0xf0104afc
f0101d70:	68 33 4d 10 f0       	push   $0xf0104d33
f0101d75:	68 90 03 00 00       	push   $0x390
f0101d7a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101d84:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d89:	74 19                	je     f0101da4 <mem_init+0xe05>
f0101d8b:	68 67 4f 10 f0       	push   $0xf0104f67
f0101d90:	68 33 4d 10 f0       	push   $0xf0104d33
f0101d95:	68 91 03 00 00       	push   $0x391
f0101d9a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101d9f:	e8 fc e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101da4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101da9:	74 19                	je     f0101dc4 <mem_init+0xe25>
f0101dab:	68 35 4f 10 f0       	push   $0xf0104f35
f0101db0:	68 33 4d 10 f0       	push   $0xf0104d33
f0101db5:	68 92 03 00 00       	push   $0x392
f0101dba:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101dbf:	e8 dc e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101dc4:	83 ec 0c             	sub    $0xc,%esp
f0101dc7:	6a 00                	push   $0x0
f0101dc9:	e8 01 ef ff ff       	call   f0100ccf <page_alloc>
f0101dce:	83 c4 10             	add    $0x10,%esp
f0101dd1:	85 c0                	test   %eax,%eax
f0101dd3:	74 04                	je     f0101dd9 <mem_init+0xe3a>
f0101dd5:	39 c3                	cmp    %eax,%ebx
f0101dd7:	74 19                	je     f0101df2 <mem_init+0xe53>
f0101dd9:	68 24 4b 10 f0       	push   $0xf0104b24
f0101dde:	68 33 4d 10 f0       	push   $0xf0104d33
f0101de3:	68 95 03 00 00       	push   $0x395
f0101de8:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101ded:	e8 ae e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101df2:	83 ec 0c             	sub    $0xc,%esp
f0101df5:	6a 00                	push   $0x0
f0101df7:	e8 d3 ee ff ff       	call   f0100ccf <page_alloc>
f0101dfc:	83 c4 10             	add    $0x10,%esp
f0101dff:	85 c0                	test   %eax,%eax
f0101e01:	74 19                	je     f0101e1c <mem_init+0xe7d>
f0101e03:	68 89 4e 10 f0       	push   $0xf0104e89
f0101e08:	68 33 4d 10 f0       	push   $0xf0104d33
f0101e0d:	68 98 03 00 00       	push   $0x398
f0101e12:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101e17:	e8 84 e2 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e1c:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0101e22:	8b 11                	mov    (%ecx),%edx
f0101e24:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e2d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101e33:	c1 f8 03             	sar    $0x3,%eax
f0101e36:	c1 e0 0c             	shl    $0xc,%eax
f0101e39:	39 c2                	cmp    %eax,%edx
f0101e3b:	74 19                	je     f0101e56 <mem_init+0xeb7>
f0101e3d:	68 c4 47 10 f0       	push   $0xf01047c4
f0101e42:	68 33 4d 10 f0       	push   $0xf0104d33
f0101e47:	68 9b 03 00 00       	push   $0x39b
f0101e4c:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101e51:	e8 4a e2 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101e56:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e5f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e64:	74 19                	je     f0101e7f <mem_init+0xee0>
f0101e66:	68 ec 4e 10 f0       	push   $0xf0104eec
f0101e6b:	68 33 4d 10 f0       	push   $0xf0104d33
f0101e70:	68 9d 03 00 00       	push   $0x39d
f0101e75:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101e7a:	e8 21 e2 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101e7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e82:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e88:	83 ec 0c             	sub    $0xc,%esp
f0101e8b:	50                   	push   %eax
f0101e8c:	e8 ae ee ff ff       	call   f0100d3f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e91:	83 c4 0c             	add    $0xc,%esp
f0101e94:	6a 01                	push   $0x1
f0101e96:	68 00 10 40 00       	push   $0x401000
f0101e9b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101ea1:	e8 fd ee ff ff       	call   f0100da3 <pgdir_walk>
f0101ea6:	89 c7                	mov    %eax,%edi
f0101ea8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101eab:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101eb0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101eb3:	8b 40 04             	mov    0x4(%eax),%eax
f0101eb6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ebb:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0101ec1:	89 c2                	mov    %eax,%edx
f0101ec3:	c1 ea 0c             	shr    $0xc,%edx
f0101ec6:	83 c4 10             	add    $0x10,%esp
f0101ec9:	39 ca                	cmp    %ecx,%edx
f0101ecb:	72 15                	jb     f0101ee2 <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ecd:	50                   	push   %eax
f0101ece:	68 5c 45 10 f0       	push   $0xf010455c
f0101ed3:	68 a4 03 00 00       	push   $0x3a4
f0101ed8:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101edd:	e8 be e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ee2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ee7:	39 c7                	cmp    %eax,%edi
f0101ee9:	74 19                	je     f0101f04 <mem_init+0xf65>
f0101eeb:	68 78 4f 10 f0       	push   $0xf0104f78
f0101ef0:	68 33 4d 10 f0       	push   $0xf0104d33
f0101ef5:	68 a5 03 00 00       	push   $0x3a5
f0101efa:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101eff:	e8 9c e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f04:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f07:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f11:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f17:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101f1d:	c1 f8 03             	sar    $0x3,%eax
f0101f20:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f23:	89 c2                	mov    %eax,%edx
f0101f25:	c1 ea 0c             	shr    $0xc,%edx
f0101f28:	39 d1                	cmp    %edx,%ecx
f0101f2a:	77 12                	ja     f0101f3e <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f2c:	50                   	push   %eax
f0101f2d:	68 5c 45 10 f0       	push   $0xf010455c
f0101f32:	6a 56                	push   $0x56
f0101f34:	68 19 4d 10 f0       	push   $0xf0104d19
f0101f39:	e8 62 e1 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f3e:	83 ec 04             	sub    $0x4,%esp
f0101f41:	68 00 10 00 00       	push   $0x1000
f0101f46:	68 ff 00 00 00       	push   $0xff
f0101f4b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f50:	50                   	push   %eax
f0101f51:	e8 be 1c 00 00       	call   f0103c14 <memset>
	page_free(pp0);
f0101f56:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f59:	89 3c 24             	mov    %edi,(%esp)
f0101f5c:	e8 de ed ff ff       	call   f0100d3f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f61:	83 c4 0c             	add    $0xc,%esp
f0101f64:	6a 01                	push   $0x1
f0101f66:	6a 00                	push   $0x0
f0101f68:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101f6e:	e8 30 ee ff ff       	call   f0100da3 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f73:	89 fa                	mov    %edi,%edx
f0101f75:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101f7b:	c1 fa 03             	sar    $0x3,%edx
f0101f7e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f81:	89 d0                	mov    %edx,%eax
f0101f83:	c1 e8 0c             	shr    $0xc,%eax
f0101f86:	83 c4 10             	add    $0x10,%esp
f0101f89:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0101f8f:	72 12                	jb     f0101fa3 <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f91:	52                   	push   %edx
f0101f92:	68 5c 45 10 f0       	push   $0xf010455c
f0101f97:	6a 56                	push   $0x56
f0101f99:	68 19 4d 10 f0       	push   $0xf0104d19
f0101f9e:	e8 fd e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101fa3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fa9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fac:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fb2:	f6 00 01             	testb  $0x1,(%eax)
f0101fb5:	74 19                	je     f0101fd0 <mem_init+0x1031>
f0101fb7:	68 90 4f 10 f0       	push   $0xf0104f90
f0101fbc:	68 33 4d 10 f0       	push   $0xf0104d33
f0101fc1:	68 af 03 00 00       	push   $0x3af
f0101fc6:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0101fcb:	e8 d0 e0 ff ff       	call   f01000a0 <_panic>
f0101fd0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101fd3:	39 d0                	cmp    %edx,%eax
f0101fd5:	75 db                	jne    f0101fb2 <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101fd7:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101fdc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fe2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101feb:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0101fee:	89 3d 3c be 17 f0    	mov    %edi,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101ff4:	83 ec 0c             	sub    $0xc,%esp
f0101ff7:	50                   	push   %eax
f0101ff8:	e8 42 ed ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101ffd:	89 1c 24             	mov    %ebx,(%esp)
f0102000:	e8 3a ed ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f0102005:	89 34 24             	mov    %esi,(%esp)
f0102008:	e8 32 ed ff ff       	call   f0100d3f <page_free>

	cprintf("check_page() succeeded!\n");
f010200d:	c7 04 24 a7 4f 10 f0 	movl   $0xf0104fa7,(%esp)
f0102014:	e8 69 0d 00 00       	call   f0102d82 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f0102019:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010201e:	83 c4 10             	add    $0x10,%esp
f0102021:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102026:	77 15                	ja     f010203d <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102028:	50                   	push   %eax
f0102029:	68 44 46 10 f0       	push   $0xf0104644
f010202e:	68 b7 00 00 00       	push   $0xb7
f0102033:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102038:	e8 63 e0 ff ff       	call   f01000a0 <_panic>
f010203d:	83 ec 08             	sub    $0x8,%esp
f0102040:	6a 05                	push   $0x5
f0102042:	05 00 00 00 10       	add    $0x10000000,%eax
f0102047:	50                   	push   %eax
f0102048:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010204d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102052:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102057:	e8 da ed ff ff       	call   f0100e36 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_U|PTE_P);
f010205c:	a1 44 be 17 f0       	mov    0xf017be44,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102061:	83 c4 10             	add    $0x10,%esp
f0102064:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102069:	77 15                	ja     f0102080 <mem_init+0x10e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010206b:	50                   	push   %eax
f010206c:	68 44 46 10 f0       	push   $0xf0104644
f0102071:	68 bf 00 00 00       	push   $0xbf
f0102076:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010207b:	e8 20 e0 ff ff       	call   f01000a0 <_panic>
f0102080:	83 ec 08             	sub    $0x8,%esp
f0102083:	6a 05                	push   $0x5
f0102085:	05 00 00 00 10       	add    $0x10000000,%eax
f010208a:	50                   	push   %eax
f010208b:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102090:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102095:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010209a:	e8 97 ed ff ff       	call   f0100e36 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010209f:	83 c4 10             	add    $0x10,%esp
f01020a2:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f01020a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020ac:	77 15                	ja     f01020c3 <mem_init+0x1124>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ae:	50                   	push   %eax
f01020af:	68 44 46 10 f0       	push   $0xf0104644
f01020b4:	68 cb 00 00 00       	push   $0xcb
f01020b9:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01020be:	e8 dd df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f01020c3:	83 ec 08             	sub    $0x8,%esp
f01020c6:	6a 03                	push   $0x3
f01020c8:	68 00 00 11 00       	push   $0x110000
f01020cd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020d2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020d7:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020dc:	e8 55 ed ff ff       	call   f0100e36 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0x0,PTE_W|PTE_P);
f01020e1:	83 c4 08             	add    $0x8,%esp
f01020e4:	6a 03                	push   $0x3
f01020e6:	6a 00                	push   $0x0
f01020e8:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01020ed:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01020f2:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020f7:	e8 3a ed ff ff       	call   f0100e36 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01020fc:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102102:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f0102107:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010210a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102111:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102116:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102119:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010211f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102122:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102125:	be 00 00 00 00       	mov    $0x0,%esi
f010212a:	eb 55                	jmp    f0102181 <mem_init+0x11e2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010212c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102132:	89 d8                	mov    %ebx,%eax
f0102134:	e8 b5 e7 ff ff       	call   f01008ee <check_va2pa>
f0102139:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102140:	77 15                	ja     f0102157 <mem_init+0x11b8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102142:	57                   	push   %edi
f0102143:	68 44 46 10 f0       	push   $0xf0104644
f0102148:	68 ed 02 00 00       	push   $0x2ed
f010214d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102152:	e8 49 df ff ff       	call   f01000a0 <_panic>
f0102157:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010215e:	39 d0                	cmp    %edx,%eax
f0102160:	74 19                	je     f010217b <mem_init+0x11dc>
f0102162:	68 48 4b 10 f0       	push   $0xf0104b48
f0102167:	68 33 4d 10 f0       	push   $0xf0104d33
f010216c:	68 ed 02 00 00       	push   $0x2ed
f0102171:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102176:	e8 25 df ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010217b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102181:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102184:	77 a6                	ja     f010212c <mem_init+0x118d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102186:	8b 3d 44 be 17 f0    	mov    0xf017be44,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010218f:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102194:	89 f2                	mov    %esi,%edx
f0102196:	89 d8                	mov    %ebx,%eax
f0102198:	e8 51 e7 ff ff       	call   f01008ee <check_va2pa>
f010219d:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01021a4:	77 15                	ja     f01021bb <mem_init+0x121c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021a6:	57                   	push   %edi
f01021a7:	68 44 46 10 f0       	push   $0xf0104644
f01021ac:	68 f2 02 00 00       	push   $0x2f2
f01021b1:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01021b6:	e8 e5 de ff ff       	call   f01000a0 <_panic>
f01021bb:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01021c2:	39 c2                	cmp    %eax,%edx
f01021c4:	74 19                	je     f01021df <mem_init+0x1240>
f01021c6:	68 7c 4b 10 f0       	push   $0xf0104b7c
f01021cb:	68 33 4d 10 f0       	push   $0xf0104d33
f01021d0:	68 f2 02 00 00       	push   $0x2f2
f01021d5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01021da:	e8 c1 de ff ff       	call   f01000a0 <_panic>
f01021df:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021e5:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01021eb:	75 a7                	jne    f0102194 <mem_init+0x11f5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021ed:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021f0:	c1 e7 0c             	shl    $0xc,%edi
f01021f3:	be 00 00 00 00       	mov    $0x0,%esi
f01021f8:	eb 30                	jmp    f010222a <mem_init+0x128b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021fa:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102200:	89 d8                	mov    %ebx,%eax
f0102202:	e8 e7 e6 ff ff       	call   f01008ee <check_va2pa>
f0102207:	39 c6                	cmp    %eax,%esi
f0102209:	74 19                	je     f0102224 <mem_init+0x1285>
f010220b:	68 b0 4b 10 f0       	push   $0xf0104bb0
f0102210:	68 33 4d 10 f0       	push   $0xf0104d33
f0102215:	68 f6 02 00 00       	push   $0x2f6
f010221a:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010221f:	e8 7c de ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102224:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010222a:	39 fe                	cmp    %edi,%esi
f010222c:	72 cc                	jb     f01021fa <mem_init+0x125b>
f010222e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102233:	89 f2                	mov    %esi,%edx
f0102235:	89 d8                	mov    %ebx,%eax
f0102237:	e8 b2 e6 ff ff       	call   f01008ee <check_va2pa>
f010223c:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102242:	39 c2                	cmp    %eax,%edx
f0102244:	74 19                	je     f010225f <mem_init+0x12c0>
f0102246:	68 d8 4b 10 f0       	push   $0xf0104bd8
f010224b:	68 33 4d 10 f0       	push   $0xf0104d33
f0102250:	68 fa 02 00 00       	push   $0x2fa
f0102255:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010225a:	e8 41 de ff ff       	call   f01000a0 <_panic>
f010225f:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102265:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010226b:	75 c6                	jne    f0102233 <mem_init+0x1294>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010226d:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102272:	89 d8                	mov    %ebx,%eax
f0102274:	e8 75 e6 ff ff       	call   f01008ee <check_va2pa>
f0102279:	83 f8 ff             	cmp    $0xffffffff,%eax
f010227c:	74 51                	je     f01022cf <mem_init+0x1330>
f010227e:	68 20 4c 10 f0       	push   $0xf0104c20
f0102283:	68 33 4d 10 f0       	push   $0xf0104d33
f0102288:	68 fb 02 00 00       	push   $0x2fb
f010228d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102292:	e8 09 de ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102297:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010229c:	72 36                	jb     f01022d4 <mem_init+0x1335>
f010229e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022a3:	76 07                	jbe    f01022ac <mem_init+0x130d>
f01022a5:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022aa:	75 28                	jne    f01022d4 <mem_init+0x1335>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01022ac:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01022b0:	0f 85 83 00 00 00    	jne    f0102339 <mem_init+0x139a>
f01022b6:	68 c0 4f 10 f0       	push   $0xf0104fc0
f01022bb:	68 33 4d 10 f0       	push   $0xf0104d33
f01022c0:	68 04 03 00 00       	push   $0x304
f01022c5:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01022ca:	e8 d1 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022cf:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022d4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022d9:	76 3f                	jbe    f010231a <mem_init+0x137b>
				assert(pgdir[i] & PTE_P);
f01022db:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01022de:	f6 c2 01             	test   $0x1,%dl
f01022e1:	75 19                	jne    f01022fc <mem_init+0x135d>
f01022e3:	68 c0 4f 10 f0       	push   $0xf0104fc0
f01022e8:	68 33 4d 10 f0       	push   $0xf0104d33
f01022ed:	68 08 03 00 00       	push   $0x308
f01022f2:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01022f7:	e8 a4 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01022fc:	f6 c2 02             	test   $0x2,%dl
f01022ff:	75 38                	jne    f0102339 <mem_init+0x139a>
f0102301:	68 d1 4f 10 f0       	push   $0xf0104fd1
f0102306:	68 33 4d 10 f0       	push   $0xf0104d33
f010230b:	68 09 03 00 00       	push   $0x309
f0102310:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010231a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010231e:	74 19                	je     f0102339 <mem_init+0x139a>
f0102320:	68 e2 4f 10 f0       	push   $0xf0104fe2
f0102325:	68 33 4d 10 f0       	push   $0xf0104d33
f010232a:	68 0b 03 00 00       	push   $0x30b
f010232f:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102334:	e8 67 dd ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102339:	83 c0 01             	add    $0x1,%eax
f010233c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102341:	0f 86 50 ff ff ff    	jbe    f0102297 <mem_init+0x12f8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102347:	83 ec 0c             	sub    $0xc,%esp
f010234a:	68 50 4c 10 f0       	push   $0xf0104c50
f010234f:	e8 2e 0a 00 00       	call   f0102d82 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102354:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102359:	83 c4 10             	add    $0x10,%esp
f010235c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102361:	77 15                	ja     f0102378 <mem_init+0x13d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102363:	50                   	push   %eax
f0102364:	68 44 46 10 f0       	push   $0xf0104644
f0102369:	68 df 00 00 00       	push   $0xdf
f010236e:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102373:	e8 28 dd ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102378:	05 00 00 00 10       	add    $0x10000000,%eax
f010237d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102380:	b8 00 00 00 00       	mov    $0x0,%eax
f0102385:	e8 c8 e5 ff ff       	call   f0100952 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010238a:	0f 20 c0             	mov    %cr0,%eax
f010238d:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102390:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102395:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102398:	83 ec 0c             	sub    $0xc,%esp
f010239b:	6a 00                	push   $0x0
f010239d:	e8 2d e9 ff ff       	call   f0100ccf <page_alloc>
f01023a2:	89 c3                	mov    %eax,%ebx
f01023a4:	83 c4 10             	add    $0x10,%esp
f01023a7:	85 c0                	test   %eax,%eax
f01023a9:	75 19                	jne    f01023c4 <mem_init+0x1425>
f01023ab:	68 de 4d 10 f0       	push   $0xf0104dde
f01023b0:	68 33 4d 10 f0       	push   $0xf0104d33
f01023b5:	68 ca 03 00 00       	push   $0x3ca
f01023ba:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01023bf:	e8 dc dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01023c4:	83 ec 0c             	sub    $0xc,%esp
f01023c7:	6a 00                	push   $0x0
f01023c9:	e8 01 e9 ff ff       	call   f0100ccf <page_alloc>
f01023ce:	89 c7                	mov    %eax,%edi
f01023d0:	83 c4 10             	add    $0x10,%esp
f01023d3:	85 c0                	test   %eax,%eax
f01023d5:	75 19                	jne    f01023f0 <mem_init+0x1451>
f01023d7:	68 f4 4d 10 f0       	push   $0xf0104df4
f01023dc:	68 33 4d 10 f0       	push   $0xf0104d33
f01023e1:	68 cb 03 00 00       	push   $0x3cb
f01023e6:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01023eb:	e8 b0 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01023f0:	83 ec 0c             	sub    $0xc,%esp
f01023f3:	6a 00                	push   $0x0
f01023f5:	e8 d5 e8 ff ff       	call   f0100ccf <page_alloc>
f01023fa:	89 c6                	mov    %eax,%esi
f01023fc:	83 c4 10             	add    $0x10,%esp
f01023ff:	85 c0                	test   %eax,%eax
f0102401:	75 19                	jne    f010241c <mem_init+0x147d>
f0102403:	68 0a 4e 10 f0       	push   $0xf0104e0a
f0102408:	68 33 4d 10 f0       	push   $0xf0104d33
f010240d:	68 cc 03 00 00       	push   $0x3cc
f0102412:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102417:	e8 84 dc ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010241c:	83 ec 0c             	sub    $0xc,%esp
f010241f:	53                   	push   %ebx
f0102420:	e8 1a e9 ff ff       	call   f0100d3f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102425:	89 f8                	mov    %edi,%eax
f0102427:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010242d:	c1 f8 03             	sar    $0x3,%eax
f0102430:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102433:	89 c2                	mov    %eax,%edx
f0102435:	c1 ea 0c             	shr    $0xc,%edx
f0102438:	83 c4 10             	add    $0x10,%esp
f010243b:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102441:	72 12                	jb     f0102455 <mem_init+0x14b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102443:	50                   	push   %eax
f0102444:	68 5c 45 10 f0       	push   $0xf010455c
f0102449:	6a 56                	push   $0x56
f010244b:	68 19 4d 10 f0       	push   $0xf0104d19
f0102450:	e8 4b dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102455:	83 ec 04             	sub    $0x4,%esp
f0102458:	68 00 10 00 00       	push   $0x1000
f010245d:	6a 01                	push   $0x1
f010245f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102464:	50                   	push   %eax
f0102465:	e8 aa 17 00 00       	call   f0103c14 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010246a:	89 f0                	mov    %esi,%eax
f010246c:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102472:	c1 f8 03             	sar    $0x3,%eax
f0102475:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102478:	89 c2                	mov    %eax,%edx
f010247a:	c1 ea 0c             	shr    $0xc,%edx
f010247d:	83 c4 10             	add    $0x10,%esp
f0102480:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102486:	72 12                	jb     f010249a <mem_init+0x14fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102488:	50                   	push   %eax
f0102489:	68 5c 45 10 f0       	push   $0xf010455c
f010248e:	6a 56                	push   $0x56
f0102490:	68 19 4d 10 f0       	push   $0xf0104d19
f0102495:	e8 06 dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010249a:	83 ec 04             	sub    $0x4,%esp
f010249d:	68 00 10 00 00       	push   $0x1000
f01024a2:	6a 02                	push   $0x2
f01024a4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024a9:	50                   	push   %eax
f01024aa:	e8 65 17 00 00       	call   f0103c14 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024af:	6a 02                	push   $0x2
f01024b1:	68 00 10 00 00       	push   $0x1000
f01024b6:	57                   	push   %edi
f01024b7:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01024bd:	e8 65 ea ff ff       	call   f0100f27 <page_insert>
	assert(pp1->pp_ref == 1);
f01024c2:	83 c4 20             	add    $0x20,%esp
f01024c5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024ca:	74 19                	je     f01024e5 <mem_init+0x1546>
f01024cc:	68 db 4e 10 f0       	push   $0xf0104edb
f01024d1:	68 33 4d 10 f0       	push   $0xf0104d33
f01024d6:	68 d1 03 00 00       	push   $0x3d1
f01024db:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01024e0:	e8 bb db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024e5:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024ec:	01 01 01 
f01024ef:	74 19                	je     f010250a <mem_init+0x156b>
f01024f1:	68 70 4c 10 f0       	push   $0xf0104c70
f01024f6:	68 33 4d 10 f0       	push   $0xf0104d33
f01024fb:	68 d2 03 00 00       	push   $0x3d2
f0102500:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102505:	e8 96 db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010250a:	6a 02                	push   $0x2
f010250c:	68 00 10 00 00       	push   $0x1000
f0102511:	56                   	push   %esi
f0102512:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102518:	e8 0a ea ff ff       	call   f0100f27 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010251d:	83 c4 10             	add    $0x10,%esp
f0102520:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102527:	02 02 02 
f010252a:	74 19                	je     f0102545 <mem_init+0x15a6>
f010252c:	68 94 4c 10 f0       	push   $0xf0104c94
f0102531:	68 33 4d 10 f0       	push   $0xf0104d33
f0102536:	68 d4 03 00 00       	push   $0x3d4
f010253b:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102540:	e8 5b db ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102545:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010254a:	74 19                	je     f0102565 <mem_init+0x15c6>
f010254c:	68 fd 4e 10 f0       	push   $0xf0104efd
f0102551:	68 33 4d 10 f0       	push   $0xf0104d33
f0102556:	68 d5 03 00 00       	push   $0x3d5
f010255b:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102560:	e8 3b db ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102565:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010256a:	74 19                	je     f0102585 <mem_init+0x15e6>
f010256c:	68 67 4f 10 f0       	push   $0xf0104f67
f0102571:	68 33 4d 10 f0       	push   $0xf0104d33
f0102576:	68 d6 03 00 00       	push   $0x3d6
f010257b:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102580:	e8 1b db ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102585:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010258c:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010258f:	89 f0                	mov    %esi,%eax
f0102591:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102597:	c1 f8 03             	sar    $0x3,%eax
f010259a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010259d:	89 c2                	mov    %eax,%edx
f010259f:	c1 ea 0c             	shr    $0xc,%edx
f01025a2:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f01025a8:	72 12                	jb     f01025bc <mem_init+0x161d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025aa:	50                   	push   %eax
f01025ab:	68 5c 45 10 f0       	push   $0xf010455c
f01025b0:	6a 56                	push   $0x56
f01025b2:	68 19 4d 10 f0       	push   $0xf0104d19
f01025b7:	e8 e4 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025bc:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025c3:	03 03 03 
f01025c6:	74 19                	je     f01025e1 <mem_init+0x1642>
f01025c8:	68 b8 4c 10 f0       	push   $0xf0104cb8
f01025cd:	68 33 4d 10 f0       	push   $0xf0104d33
f01025d2:	68 d8 03 00 00       	push   $0x3d8
f01025d7:	68 0d 4d 10 f0       	push   $0xf0104d0d
f01025dc:	e8 bf da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025e1:	83 ec 08             	sub    $0x8,%esp
f01025e4:	68 00 10 00 00       	push   $0x1000
f01025e9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01025ef:	e8 f1 e8 ff ff       	call   f0100ee5 <page_remove>
	assert(pp2->pp_ref == 0);
f01025f4:	83 c4 10             	add    $0x10,%esp
f01025f7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025fc:	74 19                	je     f0102617 <mem_init+0x1678>
f01025fe:	68 35 4f 10 f0       	push   $0xf0104f35
f0102603:	68 33 4d 10 f0       	push   $0xf0104d33
f0102608:	68 da 03 00 00       	push   $0x3da
f010260d:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102612:	e8 89 da ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102617:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f010261d:	8b 11                	mov    (%ecx),%edx
f010261f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102625:	89 d8                	mov    %ebx,%eax
f0102627:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010262d:	c1 f8 03             	sar    $0x3,%eax
f0102630:	c1 e0 0c             	shl    $0xc,%eax
f0102633:	39 c2                	cmp    %eax,%edx
f0102635:	74 19                	je     f0102650 <mem_init+0x16b1>
f0102637:	68 c4 47 10 f0       	push   $0xf01047c4
f010263c:	68 33 4d 10 f0       	push   $0xf0104d33
f0102641:	68 dd 03 00 00       	push   $0x3dd
f0102646:	68 0d 4d 10 f0       	push   $0xf0104d0d
f010264b:	e8 50 da ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102650:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102656:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010265b:	74 19                	je     f0102676 <mem_init+0x16d7>
f010265d:	68 ec 4e 10 f0       	push   $0xf0104eec
f0102662:	68 33 4d 10 f0       	push   $0xf0104d33
f0102667:	68 df 03 00 00       	push   $0x3df
f010266c:	68 0d 4d 10 f0       	push   $0xf0104d0d
f0102671:	e8 2a da ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102676:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010267c:	83 ec 0c             	sub    $0xc,%esp
f010267f:	53                   	push   %ebx
f0102680:	e8 ba e6 ff ff       	call   f0100d3f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102685:	c7 04 24 e4 4c 10 f0 	movl   $0xf0104ce4,(%esp)
f010268c:	e8 f1 06 00 00       	call   f0102d82 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102691:	83 c4 10             	add    $0x10,%esp
f0102694:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102697:	5b                   	pop    %ebx
f0102698:	5e                   	pop    %esi
f0102699:	5f                   	pop    %edi
f010269a:	5d                   	pop    %ebp
f010269b:	c3                   	ret    

f010269c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010269c:	55                   	push   %ebp
f010269d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010269f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026a2:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026a5:	5d                   	pop    %ebp
f01026a6:	c3                   	ret    

f01026a7 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01026a7:	55                   	push   %ebp
f01026a8:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01026aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01026af:	5d                   	pop    %ebp
f01026b0:	c3                   	ret    

f01026b1 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01026b1:	55                   	push   %ebp
f01026b2:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01026b4:	5d                   	pop    %ebp
f01026b5:	c3                   	ret    

f01026b6 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01026b6:	55                   	push   %ebp
f01026b7:	89 e5                	mov    %esp,%ebp
f01026b9:	57                   	push   %edi
f01026ba:	56                   	push   %esi
f01026bb:	53                   	push   %ebx
f01026bc:	83 ec 0c             	sub    $0xc,%esp
f01026bf:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
f01026c1:	89 d3                	mov    %edx,%ebx
f01026c3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
f01026c9:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01026d0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *pp;
	while(low<high)
f01026d6:	eb 5d                	jmp    f0102735 <region_alloc+0x7f>
	{
		pp=page_alloc(ALLOC_ZERO );
f01026d8:	83 ec 0c             	sub    $0xc,%esp
f01026db:	6a 01                	push   $0x1
f01026dd:	e8 ed e5 ff ff       	call   f0100ccf <page_alloc>
		pp->pp_ref++;
f01026e2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		if(pp==NULL)
f01026e7:	83 c4 10             	add    $0x10,%esp
f01026ea:	85 c0                	test   %eax,%eax
f01026ec:	75 17                	jne    f0102705 <region_alloc+0x4f>
		{
			panic("page_alloc is wrong in region_alloc\n");
f01026ee:	83 ec 04             	sub    $0x4,%esp
f01026f1:	68 f0 4f 10 f0       	push   $0xf0104ff0
f01026f6:	68 1a 01 00 00       	push   $0x11a
f01026fb:	68 86 50 10 f0       	push   $0xf0105086
f0102700:	e8 9b d9 ff ff       	call   f01000a0 <_panic>
		}
		int i=page_insert(e->env_pgdir,pp,(void *)low,PTE_P|PTE_U|PTE_W);
f0102705:	6a 07                	push   $0x7
f0102707:	53                   	push   %ebx
f0102708:	50                   	push   %eax
f0102709:	ff 77 5c             	pushl  0x5c(%edi)
f010270c:	e8 16 e8 ff ff       	call   f0100f27 <page_insert>
		if(i!=0)
f0102711:	83 c4 10             	add    $0x10,%esp
f0102714:	85 c0                	test   %eax,%eax
f0102716:	74 17                	je     f010272f <region_alloc+0x79>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
f0102718:	83 ec 04             	sub    $0x4,%esp
f010271b:	68 18 50 10 f0       	push   $0xf0105018
f0102720:	68 1f 01 00 00       	push   $0x11f
f0102725:	68 86 50 10 f0       	push   $0xf0105086
f010272a:	e8 71 d9 ff ff       	call   f01000a0 <_panic>
		}
		low=low+PGSIZE;
f010272f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
	struct PageInfo *pp;
	while(low<high)
f0102735:	39 f3                	cmp    %esi,%ebx
f0102737:	72 9f                	jb     f01026d8 <region_alloc+0x22>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
		}
		low=low+PGSIZE;
	}
} 
f0102739:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010273c:	5b                   	pop    %ebx
f010273d:	5e                   	pop    %esi
f010273e:	5f                   	pop    %edi
f010273f:	5d                   	pop    %ebp
f0102740:	c3                   	ret    

f0102741 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102741:	55                   	push   %ebp
f0102742:	89 e5                	mov    %esp,%ebp
f0102744:	8b 55 08             	mov    0x8(%ebp),%edx
f0102747:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010274a:	85 d2                	test   %edx,%edx
f010274c:	75 11                	jne    f010275f <envid2env+0x1e>
		*env_store = curenv;
f010274e:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0102753:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102756:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102758:	b8 00 00 00 00       	mov    $0x0,%eax
f010275d:	eb 5e                	jmp    f01027bd <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010275f:	89 d0                	mov    %edx,%eax
f0102761:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102766:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102769:	c1 e0 05             	shl    $0x5,%eax
f010276c:	03 05 44 be 17 f0    	add    0xf017be44,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102772:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102776:	74 05                	je     f010277d <envid2env+0x3c>
f0102778:	3b 50 48             	cmp    0x48(%eax),%edx
f010277b:	74 10                	je     f010278d <envid2env+0x4c>
		*env_store = 0;
f010277d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102780:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102786:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010278b:	eb 30                	jmp    f01027bd <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010278d:	84 c9                	test   %cl,%cl
f010278f:	74 22                	je     f01027b3 <envid2env+0x72>
f0102791:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102797:	39 d0                	cmp    %edx,%eax
f0102799:	74 18                	je     f01027b3 <envid2env+0x72>
f010279b:	8b 4a 48             	mov    0x48(%edx),%ecx
f010279e:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01027a1:	74 10                	je     f01027b3 <envid2env+0x72>
		*env_store = 0;
f01027a3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027a6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01027ac:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027b1:	eb 0a                	jmp    f01027bd <envid2env+0x7c>
	}

	*env_store = e;
f01027b3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027b6:	89 01                	mov    %eax,(%ecx)
	return 0;
f01027b8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027bd:	5d                   	pop    %ebp
f01027be:	c3                   	ret    

f01027bf <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01027bf:	55                   	push   %ebp
f01027c0:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01027c2:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01027c7:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01027ca:	b8 23 00 00 00       	mov    $0x23,%eax
f01027cf:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01027d1:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01027d3:	b8 10 00 00 00       	mov    $0x10,%eax
f01027d8:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01027da:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01027dc:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01027de:	ea e5 27 10 f0 08 00 	ljmp   $0x8,$0xf01027e5
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01027e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01027ea:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01027ed:	5d                   	pop    %ebp
f01027ee:	c3                   	ret    

f01027ef <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01027ef:	55                   	push   %ebp
f01027f0:	89 e5                	mov    %esp,%ebp
f01027f2:	56                   	push   %esi
f01027f3:	53                   	push   %ebx
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f01027f4:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
f01027fa:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102800:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102803:	ba 00 00 00 00       	mov    $0x0,%edx
f0102808:	89 c1                	mov    %eax,%ecx
f010280a:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status=ENV_FREE;
f0102811:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link=env_free_list;
f0102818:	89 50 44             	mov    %edx,0x44(%eax)
f010281b:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];
f010281e:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
f0102820:	39 d8                	cmp    %ebx,%eax
f0102822:	75 e4                	jne    f0102808 <env_init+0x19>
f0102824:	89 35 48 be 17 f0    	mov    %esi,0xf017be48
		envs[i].env_status=ENV_FREE;
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}		
	// Per-CPU part of the initialization
	env_init_percpu();
f010282a:	e8 90 ff ff ff       	call   f01027bf <env_init_percpu>
}
f010282f:	5b                   	pop    %ebx
f0102830:	5e                   	pop    %esi
f0102831:	5d                   	pop    %ebp
f0102832:	c3                   	ret    

f0102833 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102833:	55                   	push   %ebp
f0102834:	89 e5                	mov    %esp,%ebp
f0102836:	53                   	push   %ebx
f0102837:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010283a:	8b 1d 48 be 17 f0    	mov    0xf017be48,%ebx
f0102840:	85 db                	test   %ebx,%ebx
f0102842:	0f 84 43 01 00 00    	je     f010298b <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102848:	83 ec 0c             	sub    $0xc,%esp
f010284b:	6a 01                	push   $0x1
f010284d:	e8 7d e4 ff ff       	call   f0100ccf <page_alloc>
f0102852:	83 c4 10             	add    $0x10,%esp
f0102855:	85 c0                	test   %eax,%eax
f0102857:	0f 84 35 01 00 00    	je     f0102992 <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010285d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102862:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102868:	c1 f8 03             	sar    $0x3,%eax
f010286b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010286e:	89 c2                	mov    %eax,%edx
f0102870:	c1 ea 0c             	shr    $0xc,%edx
f0102873:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102879:	72 12                	jb     f010288d <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010287b:	50                   	push   %eax
f010287c:	68 5c 45 10 f0       	push   $0xf010455c
f0102881:	6a 56                	push   $0x56
f0102883:	68 19 4d 10 f0       	push   $0xf0104d19
f0102888:	e8 13 d8 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010288d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f0102892:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102895:	83 ec 04             	sub    $0x4,%esp
f0102898:	68 00 10 00 00       	push   $0x1000
f010289d:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01028a3:	50                   	push   %eax
f01028a4:	e8 20 14 00 00       	call   f0103cc9 <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01028a9:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028ac:	83 c4 10             	add    $0x10,%esp
f01028af:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028b4:	77 15                	ja     f01028cb <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028b6:	50                   	push   %eax
f01028b7:	68 44 46 10 f0       	push   $0xf0104644
f01028bc:	68 c3 00 00 00       	push   $0xc3
f01028c1:	68 86 50 10 f0       	push   $0xf0105086
f01028c6:	e8 d5 d7 ff ff       	call   f01000a0 <_panic>
f01028cb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01028d1:	83 ca 05             	or     $0x5,%edx
f01028d4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01028da:	8b 43 48             	mov    0x48(%ebx),%eax
f01028dd:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01028e2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01028e7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01028ec:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01028ef:	89 da                	mov    %ebx,%edx
f01028f1:	2b 15 44 be 17 f0    	sub    0xf017be44,%edx
f01028f7:	c1 fa 05             	sar    $0x5,%edx
f01028fa:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102900:	09 d0                	or     %edx,%eax
f0102902:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102905:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102908:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010290b:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102912:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102919:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102920:	83 ec 04             	sub    $0x4,%esp
f0102923:	6a 44                	push   $0x44
f0102925:	6a 00                	push   $0x0
f0102927:	53                   	push   %ebx
f0102928:	e8 e7 12 00 00       	call   f0103c14 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010292d:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102933:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102939:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010293f:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102946:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010294c:	8b 43 44             	mov    0x44(%ebx),%eax
f010294f:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	*newenv_store = e;
f0102954:	8b 45 08             	mov    0x8(%ebp),%eax
f0102957:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102959:	8b 53 48             	mov    0x48(%ebx),%edx
f010295c:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0102961:	83 c4 10             	add    $0x10,%esp
f0102964:	85 c0                	test   %eax,%eax
f0102966:	74 05                	je     f010296d <env_alloc+0x13a>
f0102968:	8b 40 48             	mov    0x48(%eax),%eax
f010296b:	eb 05                	jmp    f0102972 <env_alloc+0x13f>
f010296d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102972:	83 ec 04             	sub    $0x4,%esp
f0102975:	52                   	push   %edx
f0102976:	50                   	push   %eax
f0102977:	68 91 50 10 f0       	push   $0xf0105091
f010297c:	e8 01 04 00 00       	call   f0102d82 <cprintf>
	return 0;
f0102981:	83 c4 10             	add    $0x10,%esp
f0102984:	b8 00 00 00 00       	mov    $0x0,%eax
f0102989:	eb 0c                	jmp    f0102997 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010298b:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102990:	eb 05                	jmp    f0102997 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102992:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102997:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010299a:	c9                   	leave  
f010299b:	c3                   	ret    

f010299c <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010299c:	55                   	push   %ebp
f010299d:	89 e5                	mov    %esp,%ebp
f010299f:	57                   	push   %edi
f01029a0:	56                   	push   %esi
f01029a1:	53                   	push   %ebx
f01029a2:	83 ec 34             	sub    $0x34,%esp
f01029a5:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f01029a8:	6a 00                	push   $0x0
f01029aa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01029ad:	50                   	push   %eax
f01029ae:	e8 80 fe ff ff       	call   f0102833 <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f01029b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029b6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f01029b9:	83 c4 10             	add    $0x10,%esp
f01029bc:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01029c2:	74 17                	je     f01029db <env_create+0x3f>
		panic("binary document is error\n");
f01029c4:	83 ec 04             	sub    $0x4,%esp
f01029c7:	68 a6 50 10 f0       	push   $0xf01050a6
f01029cc:	68 64 01 00 00       	push   $0x164
f01029d1:	68 86 50 10 f0       	push   $0xf0105086
f01029d6:	e8 c5 d6 ff ff       	call   f01000a0 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
f01029db:	89 fb                	mov    %edi,%ebx
f01029dd:	03 5f 1c             	add    0x1c(%edi),%ebx
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
f01029e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029e3:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029e6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029eb:	77 15                	ja     f0102a02 <env_create+0x66>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029ed:	50                   	push   %eax
f01029ee:	68 44 46 10 f0       	push   $0xf0104644
f01029f3:	68 67 01 00 00       	push   $0x167
f01029f8:	68 86 50 10 f0       	push   $0xf0105086
f01029fd:	e8 9e d6 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a02:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a07:	0f 22 d8             	mov    %eax,%cr3
	for(i=0;i<elf->e_phnum;i++)
f0102a0a:	be 00 00 00 00       	mov    $0x0,%esi
f0102a0f:	eb 40                	jmp    f0102a51 <env_create+0xb5>
	{
		//cprintf("%d\n",ph->p_type);
		if(ph->p_type==ELF_PROG_LOAD)
f0102a11:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102a14:	75 35                	jne    f0102a4b <env_create+0xaf>
		{
			//cprintf("load\n");
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f0102a16:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102a19:	8b 53 08             	mov    0x8(%ebx),%edx
f0102a1c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a1f:	e8 92 fc ff ff       	call   f01026b6 <region_alloc>
			memset((void *)(ph->p_va),0,ph->p_memsz);
f0102a24:	83 ec 04             	sub    $0x4,%esp
f0102a27:	ff 73 14             	pushl  0x14(%ebx)
f0102a2a:	6a 00                	push   $0x0
f0102a2c:	ff 73 08             	pushl  0x8(%ebx)
f0102a2f:	e8 e0 11 00 00       	call   f0103c14 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f0102a34:	83 c4 0c             	add    $0xc,%esp
f0102a37:	ff 73 10             	pushl  0x10(%ebx)
f0102a3a:	89 f8                	mov    %edi,%eax
f0102a3c:	03 43 04             	add    0x4(%ebx),%eax
f0102a3f:	50                   	push   %eax
f0102a40:	ff 73 08             	pushl  0x8(%ebx)
f0102a43:	e8 81 12 00 00       	call   f0103cc9 <memcpy>
f0102a48:	83 c4 10             	add    $0x10,%esp
			//cprintf("%08x\n",ph->p_va);
		}
		ph++;
f0102a4b:	83 c3 20             	add    $0x20,%ebx
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
	for(i=0;i<elf->e_phnum;i++)
f0102a4e:	83 c6 01             	add    $0x1,%esi
f0102a51:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0102a55:	39 c6                	cmp    %eax,%esi
f0102a57:	72 b8                	jb     f0102a11 <env_create+0x75>
		}
		ph++;
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	e->env_tf.tf_eip=elf->e_entry;
f0102a59:	8b 47 18             	mov    0x18(%edi),%eax
f0102a5c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102a5f:	89 47 30             	mov    %eax,0x30(%edi)
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f0102a62:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102a67:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102a6c:	89 f8                	mov    %edi,%eax
f0102a6e:	e8 43 fc ff ff       	call   f01026b6 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f0102a73:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a78:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a7d:	77 15                	ja     f0102a94 <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a7f:	50                   	push   %eax
f0102a80:	68 44 46 10 f0       	push   $0xf0104644
f0102a85:	68 7a 01 00 00       	push   $0x17a
f0102a8a:	68 86 50 10 f0       	push   $0xf0105086
f0102a8f:	e8 0c d6 ff ff       	call   f01000a0 <_panic>
f0102a94:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a99:	0f 22 d8             	mov    %eax,%cr3
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f0102a9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a9f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102aa2:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f0102aa5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aa8:	5b                   	pop    %ebx
f0102aa9:	5e                   	pop    %esi
f0102aaa:	5f                   	pop    %edi
f0102aab:	5d                   	pop    %ebp
f0102aac:	c3                   	ret    

f0102aad <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102aad:	55                   	push   %ebp
f0102aae:	89 e5                	mov    %esp,%ebp
f0102ab0:	57                   	push   %edi
f0102ab1:	56                   	push   %esi
f0102ab2:	53                   	push   %ebx
f0102ab3:	83 ec 1c             	sub    $0x1c,%esp
f0102ab6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102ab9:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102abf:	39 fa                	cmp    %edi,%edx
f0102ac1:	75 29                	jne    f0102aec <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102ac3:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ac8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102acd:	77 15                	ja     f0102ae4 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102acf:	50                   	push   %eax
f0102ad0:	68 44 46 10 f0       	push   $0xf0104644
f0102ad5:	68 a1 01 00 00       	push   $0x1a1
f0102ada:	68 86 50 10 f0       	push   $0xf0105086
f0102adf:	e8 bc d5 ff ff       	call   f01000a0 <_panic>
f0102ae4:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ae9:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102aec:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102aef:	85 d2                	test   %edx,%edx
f0102af1:	74 05                	je     f0102af8 <env_free+0x4b>
f0102af3:	8b 42 48             	mov    0x48(%edx),%eax
f0102af6:	eb 05                	jmp    f0102afd <env_free+0x50>
f0102af8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102afd:	83 ec 04             	sub    $0x4,%esp
f0102b00:	51                   	push   %ecx
f0102b01:	50                   	push   %eax
f0102b02:	68 c0 50 10 f0       	push   $0xf01050c0
f0102b07:	e8 76 02 00 00       	call   f0102d82 <cprintf>
f0102b0c:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102b0f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102b16:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b19:	89 d0                	mov    %edx,%eax
f0102b1b:	c1 e0 02             	shl    $0x2,%eax
f0102b1e:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102b21:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b24:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102b27:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102b2d:	0f 84 a8 00 00 00    	je     f0102bdb <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102b33:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b39:	89 f0                	mov    %esi,%eax
f0102b3b:	c1 e8 0c             	shr    $0xc,%eax
f0102b3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b41:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102b47:	77 15                	ja     f0102b5e <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b49:	56                   	push   %esi
f0102b4a:	68 5c 45 10 f0       	push   $0xf010455c
f0102b4f:	68 b0 01 00 00       	push   $0x1b0
f0102b54:	68 86 50 10 f0       	push   $0xf0105086
f0102b59:	e8 42 d5 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b61:	c1 e0 16             	shl    $0x16,%eax
f0102b64:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b67:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102b6c:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102b73:	01 
f0102b74:	74 17                	je     f0102b8d <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b76:	83 ec 08             	sub    $0x8,%esp
f0102b79:	89 d8                	mov    %ebx,%eax
f0102b7b:	c1 e0 0c             	shl    $0xc,%eax
f0102b7e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102b81:	50                   	push   %eax
f0102b82:	ff 77 5c             	pushl  0x5c(%edi)
f0102b85:	e8 5b e3 ff ff       	call   f0100ee5 <page_remove>
f0102b8a:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b8d:	83 c3 01             	add    $0x1,%ebx
f0102b90:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102b96:	75 d4                	jne    f0102b6c <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102b98:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b9b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b9e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ba5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ba8:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102bae:	72 14                	jb     f0102bc4 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102bb0:	83 ec 04             	sub    $0x4,%esp
f0102bb3:	68 90 46 10 f0       	push   $0xf0104690
f0102bb8:	6a 4f                	push   $0x4f
f0102bba:	68 19 4d 10 f0       	push   $0xf0104d19
f0102bbf:	e8 dc d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102bc4:	83 ec 0c             	sub    $0xc,%esp
f0102bc7:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102bcc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102bcf:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102bd2:	50                   	push   %eax
f0102bd3:	e8 a4 e1 ff ff       	call   f0100d7c <page_decref>
f0102bd8:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102bdb:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102bdf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102be2:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102be7:	0f 85 29 ff ff ff    	jne    f0102b16 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102bed:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bf0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bf5:	77 15                	ja     f0102c0c <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bf7:	50                   	push   %eax
f0102bf8:	68 44 46 10 f0       	push   $0xf0104644
f0102bfd:	68 be 01 00 00       	push   $0x1be
f0102c02:	68 86 50 10 f0       	push   $0xf0105086
f0102c07:	e8 94 d4 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102c0c:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c13:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c18:	c1 e8 0c             	shr    $0xc,%eax
f0102c1b:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102c21:	72 14                	jb     f0102c37 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102c23:	83 ec 04             	sub    $0x4,%esp
f0102c26:	68 90 46 10 f0       	push   $0xf0104690
f0102c2b:	6a 4f                	push   $0x4f
f0102c2d:	68 19 4d 10 f0       	push   $0xf0104d19
f0102c32:	e8 69 d4 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102c37:	83 ec 0c             	sub    $0xc,%esp
f0102c3a:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102c40:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102c43:	50                   	push   %eax
f0102c44:	e8 33 e1 ff ff       	call   f0100d7c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102c49:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102c50:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0102c55:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102c58:	89 3d 48 be 17 f0    	mov    %edi,0xf017be48
}
f0102c5e:	83 c4 10             	add    $0x10,%esp
f0102c61:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c64:	5b                   	pop    %ebx
f0102c65:	5e                   	pop    %esi
f0102c66:	5f                   	pop    %edi
f0102c67:	5d                   	pop    %ebp
f0102c68:	c3                   	ret    

f0102c69 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102c69:	55                   	push   %ebp
f0102c6a:	89 e5                	mov    %esp,%ebp
f0102c6c:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102c6f:	ff 75 08             	pushl  0x8(%ebp)
f0102c72:	e8 36 fe ff ff       	call   f0102aad <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102c77:	c7 04 24 50 50 10 f0 	movl   $0xf0105050,(%esp)
f0102c7e:	e8 ff 00 00 00       	call   f0102d82 <cprintf>
f0102c83:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102c86:	83 ec 0c             	sub    $0xc,%esp
f0102c89:	6a 00                	push   $0x0
f0102c8b:	e8 a2 da ff ff       	call   f0100732 <monitor>
f0102c90:	83 c4 10             	add    $0x10,%esp
f0102c93:	eb f1                	jmp    f0102c86 <env_destroy+0x1d>

f0102c95 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102c95:	55                   	push   %ebp
f0102c96:	89 e5                	mov    %esp,%ebp
f0102c98:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102c9b:	8b 65 08             	mov    0x8(%ebp),%esp
f0102c9e:	61                   	popa   
f0102c9f:	07                   	pop    %es
f0102ca0:	1f                   	pop    %ds
f0102ca1:	83 c4 08             	add    $0x8,%esp
f0102ca4:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102ca5:	68 d6 50 10 f0       	push   $0xf01050d6
f0102caa:	68 e7 01 00 00       	push   $0x1e7
f0102caf:	68 86 50 10 f0       	push   $0xf0105086
f0102cb4:	e8 e7 d3 ff ff       	call   f01000a0 <_panic>

f0102cb9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102cb9:	55                   	push   %ebp
f0102cba:	89 e5                	mov    %esp,%ebp
f0102cbc:	83 ec 08             	sub    $0x8,%esp
f0102cbf:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0102cc2:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102cc8:	85 d2                	test   %edx,%edx
f0102cca:	74 0d                	je     f0102cd9 <env_run+0x20>
f0102ccc:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102cd0:	75 07                	jne    f0102cd9 <env_run+0x20>
	{
		curenv->env_status=ENV_RUNNABLE;
f0102cd2:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv=e;
f0102cd9:	a3 40 be 17 f0       	mov    %eax,0xf017be40
	curenv->env_status=ENV_RUNNING;
f0102cde:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102ce5:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0102ce9:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cec:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102cf2:	77 15                	ja     f0102d09 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cf4:	52                   	push   %edx
f0102cf5:	68 44 46 10 f0       	push   $0xf0104644
f0102cfa:	68 0c 02 00 00       	push   $0x20c
f0102cff:	68 86 50 10 f0       	push   $0xf0105086
f0102d04:	e8 97 d3 ff ff       	call   f01000a0 <_panic>
f0102d09:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102d0f:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(curenv->env_tf));
f0102d12:	83 ec 0c             	sub    $0xc,%esp
f0102d15:	50                   	push   %eax
f0102d16:	e8 7a ff ff ff       	call   f0102c95 <env_pop_tf>

f0102d1b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d1b:	55                   	push   %ebp
f0102d1c:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d1e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d26:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d27:	ba 71 00 00 00       	mov    $0x71,%edx
f0102d2c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d2d:	0f b6 c0             	movzbl %al,%eax
}
f0102d30:	5d                   	pop    %ebp
f0102d31:	c3                   	ret    

f0102d32 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d32:	55                   	push   %ebp
f0102d33:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d35:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d3d:	ee                   	out    %al,(%dx)
f0102d3e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102d43:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d46:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d47:	5d                   	pop    %ebp
f0102d48:	c3                   	ret    

f0102d49 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d49:	55                   	push   %ebp
f0102d4a:	89 e5                	mov    %esp,%ebp
f0102d4c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102d4f:	ff 75 08             	pushl  0x8(%ebp)
f0102d52:	e8 be d8 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102d57:	83 c4 10             	add    $0x10,%esp
f0102d5a:	c9                   	leave  
f0102d5b:	c3                   	ret    

f0102d5c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d5c:	55                   	push   %ebp
f0102d5d:	89 e5                	mov    %esp,%ebp
f0102d5f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102d62:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d69:	ff 75 0c             	pushl  0xc(%ebp)
f0102d6c:	ff 75 08             	pushl  0x8(%ebp)
f0102d6f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d72:	50                   	push   %eax
f0102d73:	68 49 2d 10 f0       	push   $0xf0102d49
f0102d78:	e8 72 07 00 00       	call   f01034ef <vprintfmt>
	return cnt;
}
f0102d7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d80:	c9                   	leave  
f0102d81:	c3                   	ret    

f0102d82 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d82:	55                   	push   %ebp
f0102d83:	89 e5                	mov    %esp,%ebp
f0102d85:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d88:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d8b:	50                   	push   %eax
f0102d8c:	ff 75 08             	pushl  0x8(%ebp)
f0102d8f:	e8 c8 ff ff ff       	call   f0102d5c <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d94:	c9                   	leave  
f0102d95:	c3                   	ret    

f0102d96 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102d96:	55                   	push   %ebp
f0102d97:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102d99:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102d9e:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102da5:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102da8:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102daf:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102db1:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102db8:	67 00 
f0102dba:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102dc0:	89 c2                	mov    %eax,%edx
f0102dc2:	c1 ea 10             	shr    $0x10,%edx
f0102dc5:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102dcb:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102dd2:	c1 e8 18             	shr    $0x18,%eax
f0102dd5:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102dda:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102de1:	b8 28 00 00 00       	mov    $0x28,%eax
f0102de6:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102de9:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102dee:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102df1:	5d                   	pop    %ebp
f0102df2:	c3                   	ret    

f0102df3 <trap_init>:
}


void
trap_init(void)
{
f0102df3:	55                   	push   %ebp
f0102df4:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102df6:	e8 9b ff ff ff       	call   f0102d96 <trap_init_percpu>
}
f0102dfb:	5d                   	pop    %ebp
f0102dfc:	c3                   	ret    

f0102dfd <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102dfd:	55                   	push   %ebp
f0102dfe:	89 e5                	mov    %esp,%ebp
f0102e00:	53                   	push   %ebx
f0102e01:	83 ec 0c             	sub    $0xc,%esp
f0102e04:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102e07:	ff 33                	pushl  (%ebx)
f0102e09:	68 e2 50 10 f0       	push   $0xf01050e2
f0102e0e:	e8 6f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102e13:	83 c4 08             	add    $0x8,%esp
f0102e16:	ff 73 04             	pushl  0x4(%ebx)
f0102e19:	68 f1 50 10 f0       	push   $0xf01050f1
f0102e1e:	e8 5f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102e23:	83 c4 08             	add    $0x8,%esp
f0102e26:	ff 73 08             	pushl  0x8(%ebx)
f0102e29:	68 00 51 10 f0       	push   $0xf0105100
f0102e2e:	e8 4f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102e33:	83 c4 08             	add    $0x8,%esp
f0102e36:	ff 73 0c             	pushl  0xc(%ebx)
f0102e39:	68 0f 51 10 f0       	push   $0xf010510f
f0102e3e:	e8 3f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102e43:	83 c4 08             	add    $0x8,%esp
f0102e46:	ff 73 10             	pushl  0x10(%ebx)
f0102e49:	68 1e 51 10 f0       	push   $0xf010511e
f0102e4e:	e8 2f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102e53:	83 c4 08             	add    $0x8,%esp
f0102e56:	ff 73 14             	pushl  0x14(%ebx)
f0102e59:	68 2d 51 10 f0       	push   $0xf010512d
f0102e5e:	e8 1f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102e63:	83 c4 08             	add    $0x8,%esp
f0102e66:	ff 73 18             	pushl  0x18(%ebx)
f0102e69:	68 3c 51 10 f0       	push   $0xf010513c
f0102e6e:	e8 0f ff ff ff       	call   f0102d82 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102e73:	83 c4 08             	add    $0x8,%esp
f0102e76:	ff 73 1c             	pushl  0x1c(%ebx)
f0102e79:	68 4b 51 10 f0       	push   $0xf010514b
f0102e7e:	e8 ff fe ff ff       	call   f0102d82 <cprintf>
}
f0102e83:	83 c4 10             	add    $0x10,%esp
f0102e86:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e89:	c9                   	leave  
f0102e8a:	c3                   	ret    

f0102e8b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102e8b:	55                   	push   %ebp
f0102e8c:	89 e5                	mov    %esp,%ebp
f0102e8e:	56                   	push   %esi
f0102e8f:	53                   	push   %ebx
f0102e90:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102e93:	83 ec 08             	sub    $0x8,%esp
f0102e96:	53                   	push   %ebx
f0102e97:	68 81 52 10 f0       	push   $0xf0105281
f0102e9c:	e8 e1 fe ff ff       	call   f0102d82 <cprintf>
	print_regs(&tf->tf_regs);
f0102ea1:	89 1c 24             	mov    %ebx,(%esp)
f0102ea4:	e8 54 ff ff ff       	call   f0102dfd <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102ea9:	83 c4 08             	add    $0x8,%esp
f0102eac:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102eb0:	50                   	push   %eax
f0102eb1:	68 9c 51 10 f0       	push   $0xf010519c
f0102eb6:	e8 c7 fe ff ff       	call   f0102d82 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102ebb:	83 c4 08             	add    $0x8,%esp
f0102ebe:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102ec2:	50                   	push   %eax
f0102ec3:	68 af 51 10 f0       	push   $0xf01051af
f0102ec8:	e8 b5 fe ff ff       	call   f0102d82 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102ecd:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102ed0:	83 c4 10             	add    $0x10,%esp
f0102ed3:	83 f8 13             	cmp    $0x13,%eax
f0102ed6:	77 09                	ja     f0102ee1 <print_trapframe+0x56>
		return excnames[trapno];
f0102ed8:	8b 14 85 60 54 10 f0 	mov    -0xfefaba0(,%eax,4),%edx
f0102edf:	eb 10                	jmp    f0102ef1 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102ee1:	83 f8 30             	cmp    $0x30,%eax
f0102ee4:	b9 66 51 10 f0       	mov    $0xf0105166,%ecx
f0102ee9:	ba 5a 51 10 f0       	mov    $0xf010515a,%edx
f0102eee:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102ef1:	83 ec 04             	sub    $0x4,%esp
f0102ef4:	52                   	push   %edx
f0102ef5:	50                   	push   %eax
f0102ef6:	68 c2 51 10 f0       	push   $0xf01051c2
f0102efb:	e8 82 fe ff ff       	call   f0102d82 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102f00:	83 c4 10             	add    $0x10,%esp
f0102f03:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0102f09:	75 1a                	jne    f0102f25 <print_trapframe+0x9a>
f0102f0b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102f0f:	75 14                	jne    f0102f25 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102f11:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102f14:	83 ec 08             	sub    $0x8,%esp
f0102f17:	50                   	push   %eax
f0102f18:	68 d4 51 10 f0       	push   $0xf01051d4
f0102f1d:	e8 60 fe ff ff       	call   f0102d82 <cprintf>
f0102f22:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102f25:	83 ec 08             	sub    $0x8,%esp
f0102f28:	ff 73 2c             	pushl  0x2c(%ebx)
f0102f2b:	68 e3 51 10 f0       	push   $0xf01051e3
f0102f30:	e8 4d fe ff ff       	call   f0102d82 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102f35:	83 c4 10             	add    $0x10,%esp
f0102f38:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102f3c:	75 49                	jne    f0102f87 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102f3e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102f41:	89 c2                	mov    %eax,%edx
f0102f43:	83 e2 01             	and    $0x1,%edx
f0102f46:	ba 80 51 10 f0       	mov    $0xf0105180,%edx
f0102f4b:	b9 75 51 10 f0       	mov    $0xf0105175,%ecx
f0102f50:	0f 44 ca             	cmove  %edx,%ecx
f0102f53:	89 c2                	mov    %eax,%edx
f0102f55:	83 e2 02             	and    $0x2,%edx
f0102f58:	ba 92 51 10 f0       	mov    $0xf0105192,%edx
f0102f5d:	be 8c 51 10 f0       	mov    $0xf010518c,%esi
f0102f62:	0f 45 d6             	cmovne %esi,%edx
f0102f65:	83 e0 04             	and    $0x4,%eax
f0102f68:	be ac 52 10 f0       	mov    $0xf01052ac,%esi
f0102f6d:	b8 97 51 10 f0       	mov    $0xf0105197,%eax
f0102f72:	0f 44 c6             	cmove  %esi,%eax
f0102f75:	51                   	push   %ecx
f0102f76:	52                   	push   %edx
f0102f77:	50                   	push   %eax
f0102f78:	68 f1 51 10 f0       	push   $0xf01051f1
f0102f7d:	e8 00 fe ff ff       	call   f0102d82 <cprintf>
f0102f82:	83 c4 10             	add    $0x10,%esp
f0102f85:	eb 10                	jmp    f0102f97 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102f87:	83 ec 0c             	sub    $0xc,%esp
f0102f8a:	68 be 4f 10 f0       	push   $0xf0104fbe
f0102f8f:	e8 ee fd ff ff       	call   f0102d82 <cprintf>
f0102f94:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102f97:	83 ec 08             	sub    $0x8,%esp
f0102f9a:	ff 73 30             	pushl  0x30(%ebx)
f0102f9d:	68 00 52 10 f0       	push   $0xf0105200
f0102fa2:	e8 db fd ff ff       	call   f0102d82 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102fa7:	83 c4 08             	add    $0x8,%esp
f0102faa:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102fae:	50                   	push   %eax
f0102faf:	68 0f 52 10 f0       	push   $0xf010520f
f0102fb4:	e8 c9 fd ff ff       	call   f0102d82 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102fb9:	83 c4 08             	add    $0x8,%esp
f0102fbc:	ff 73 38             	pushl  0x38(%ebx)
f0102fbf:	68 22 52 10 f0       	push   $0xf0105222
f0102fc4:	e8 b9 fd ff ff       	call   f0102d82 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102fc9:	83 c4 10             	add    $0x10,%esp
f0102fcc:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102fd0:	74 25                	je     f0102ff7 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102fd2:	83 ec 08             	sub    $0x8,%esp
f0102fd5:	ff 73 3c             	pushl  0x3c(%ebx)
f0102fd8:	68 31 52 10 f0       	push   $0xf0105231
f0102fdd:	e8 a0 fd ff ff       	call   f0102d82 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102fe2:	83 c4 08             	add    $0x8,%esp
f0102fe5:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102fe9:	50                   	push   %eax
f0102fea:	68 40 52 10 f0       	push   $0xf0105240
f0102fef:	e8 8e fd ff ff       	call   f0102d82 <cprintf>
f0102ff4:	83 c4 10             	add    $0x10,%esp
	}
}
f0102ff7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102ffa:	5b                   	pop    %ebx
f0102ffb:	5e                   	pop    %esi
f0102ffc:	5d                   	pop    %ebp
f0102ffd:	c3                   	ret    

f0102ffe <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102ffe:	55                   	push   %ebp
f0102fff:	89 e5                	mov    %esp,%ebp
f0103001:	57                   	push   %edi
f0103002:	56                   	push   %esi
f0103003:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103006:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103007:	9c                   	pushf  
f0103008:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103009:	f6 c4 02             	test   $0x2,%ah
f010300c:	74 19                	je     f0103027 <trap+0x29>
f010300e:	68 53 52 10 f0       	push   $0xf0105253
f0103013:	68 33 4d 10 f0       	push   $0xf0104d33
f0103018:	68 a7 00 00 00       	push   $0xa7
f010301d:	68 6c 52 10 f0       	push   $0xf010526c
f0103022:	e8 79 d0 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103027:	83 ec 08             	sub    $0x8,%esp
f010302a:	56                   	push   %esi
f010302b:	68 78 52 10 f0       	push   $0xf0105278
f0103030:	e8 4d fd ff ff       	call   f0102d82 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103035:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103039:	83 e0 03             	and    $0x3,%eax
f010303c:	83 c4 10             	add    $0x10,%esp
f010303f:	66 83 f8 03          	cmp    $0x3,%ax
f0103043:	75 31                	jne    f0103076 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103045:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f010304a:	85 c0                	test   %eax,%eax
f010304c:	75 19                	jne    f0103067 <trap+0x69>
f010304e:	68 93 52 10 f0       	push   $0xf0105293
f0103053:	68 33 4d 10 f0       	push   $0xf0104d33
f0103058:	68 ad 00 00 00       	push   $0xad
f010305d:	68 6c 52 10 f0       	push   $0xf010526c
f0103062:	e8 39 d0 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103067:	b9 11 00 00 00       	mov    $0x11,%ecx
f010306c:	89 c7                	mov    %eax,%edi
f010306e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103070:	8b 35 40 be 17 f0    	mov    0xf017be40,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103076:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010307c:	83 ec 0c             	sub    $0xc,%esp
f010307f:	56                   	push   %esi
f0103080:	e8 06 fe ff ff       	call   f0102e8b <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103085:	83 c4 10             	add    $0x10,%esp
f0103088:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010308d:	75 17                	jne    f01030a6 <trap+0xa8>
		panic("unhandled trap in kernel");
f010308f:	83 ec 04             	sub    $0x4,%esp
f0103092:	68 9a 52 10 f0       	push   $0xf010529a
f0103097:	68 96 00 00 00       	push   $0x96
f010309c:	68 6c 52 10 f0       	push   $0xf010526c
f01030a1:	e8 fa cf ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f01030a6:	83 ec 0c             	sub    $0xc,%esp
f01030a9:	ff 35 40 be 17 f0    	pushl  0xf017be40
f01030af:	e8 b5 fb ff ff       	call   f0102c69 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01030b4:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f01030b9:	83 c4 10             	add    $0x10,%esp
f01030bc:	85 c0                	test   %eax,%eax
f01030be:	74 06                	je     f01030c6 <trap+0xc8>
f01030c0:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01030c4:	74 19                	je     f01030df <trap+0xe1>
f01030c6:	68 f8 53 10 f0       	push   $0xf01053f8
f01030cb:	68 33 4d 10 f0       	push   $0xf0104d33
f01030d0:	68 bf 00 00 00       	push   $0xbf
f01030d5:	68 6c 52 10 f0       	push   $0xf010526c
f01030da:	e8 c1 cf ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01030df:	83 ec 0c             	sub    $0xc,%esp
f01030e2:	50                   	push   %eax
f01030e3:	e8 d1 fb ff ff       	call   f0102cb9 <env_run>

f01030e8 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01030e8:	55                   	push   %ebp
f01030e9:	89 e5                	mov    %esp,%ebp
f01030eb:	53                   	push   %ebx
f01030ec:	83 ec 04             	sub    $0x4,%esp
f01030ef:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01030f2:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01030f5:	ff 73 30             	pushl  0x30(%ebx)
f01030f8:	50                   	push   %eax
f01030f9:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f01030fe:	ff 70 48             	pushl  0x48(%eax)
f0103101:	68 24 54 10 f0       	push   $0xf0105424
f0103106:	e8 77 fc ff ff       	call   f0102d82 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010310b:	89 1c 24             	mov    %ebx,(%esp)
f010310e:	e8 78 fd ff ff       	call   f0102e8b <print_trapframe>
	env_destroy(curenv);
f0103113:	83 c4 04             	add    $0x4,%esp
f0103116:	ff 35 40 be 17 f0    	pushl  0xf017be40
f010311c:	e8 48 fb ff ff       	call   f0102c69 <env_destroy>
}
f0103121:	83 c4 10             	add    $0x10,%esp
f0103124:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103127:	c9                   	leave  
f0103128:	c3                   	ret    

f0103129 <syscall>:
f0103129:	55                   	push   %ebp
f010312a:	89 e5                	mov    %esp,%ebp
f010312c:	83 ec 0c             	sub    $0xc,%esp
f010312f:	68 b0 54 10 f0       	push   $0xf01054b0
f0103134:	6a 49                	push   $0x49
f0103136:	68 c8 54 10 f0       	push   $0xf01054c8
f010313b:	e8 60 cf ff ff       	call   f01000a0 <_panic>

f0103140 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103140:	55                   	push   %ebp
f0103141:	89 e5                	mov    %esp,%ebp
f0103143:	57                   	push   %edi
f0103144:	56                   	push   %esi
f0103145:	53                   	push   %ebx
f0103146:	83 ec 14             	sub    $0x14,%esp
f0103149:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010314c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010314f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103152:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103155:	8b 1a                	mov    (%edx),%ebx
f0103157:	8b 01                	mov    (%ecx),%eax
f0103159:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010315c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103163:	eb 7f                	jmp    f01031e4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103165:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103168:	01 d8                	add    %ebx,%eax
f010316a:	89 c6                	mov    %eax,%esi
f010316c:	c1 ee 1f             	shr    $0x1f,%esi
f010316f:	01 c6                	add    %eax,%esi
f0103171:	d1 fe                	sar    %esi
f0103173:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103176:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103179:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010317c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010317e:	eb 03                	jmp    f0103183 <stab_binsearch+0x43>
			m--;
f0103180:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103183:	39 c3                	cmp    %eax,%ebx
f0103185:	7f 0d                	jg     f0103194 <stab_binsearch+0x54>
f0103187:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010318b:	83 ea 0c             	sub    $0xc,%edx
f010318e:	39 f9                	cmp    %edi,%ecx
f0103190:	75 ee                	jne    f0103180 <stab_binsearch+0x40>
f0103192:	eb 05                	jmp    f0103199 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103194:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103197:	eb 4b                	jmp    f01031e4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103199:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010319c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010319f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01031a3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01031a6:	76 11                	jbe    f01031b9 <stab_binsearch+0x79>
			*region_left = m;
f01031a8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031ab:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01031ad:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01031b0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031b7:	eb 2b                	jmp    f01031e4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01031b9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01031bc:	73 14                	jae    f01031d2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01031be:	83 e8 01             	sub    $0x1,%eax
f01031c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01031c4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01031c7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01031c9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01031d0:	eb 12                	jmp    f01031e4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01031d2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031d5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01031d7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01031db:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01031dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01031e4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01031e7:	0f 8e 78 ff ff ff    	jle    f0103165 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01031ed:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01031f1:	75 0f                	jne    f0103202 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01031f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031f6:	8b 00                	mov    (%eax),%eax
f01031f8:	83 e8 01             	sub    $0x1,%eax
f01031fb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01031fe:	89 06                	mov    %eax,(%esi)
f0103200:	eb 2c                	jmp    f010322e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103202:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103205:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103207:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010320a:	8b 0e                	mov    (%esi),%ecx
f010320c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010320f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103212:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103215:	eb 03                	jmp    f010321a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103217:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010321a:	39 c8                	cmp    %ecx,%eax
f010321c:	7e 0b                	jle    f0103229 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010321e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103222:	83 ea 0c             	sub    $0xc,%edx
f0103225:	39 df                	cmp    %ebx,%edi
f0103227:	75 ee                	jne    f0103217 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103229:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010322c:	89 06                	mov    %eax,(%esi)
	}
}
f010322e:	83 c4 14             	add    $0x14,%esp
f0103231:	5b                   	pop    %ebx
f0103232:	5e                   	pop    %esi
f0103233:	5f                   	pop    %edi
f0103234:	5d                   	pop    %ebp
f0103235:	c3                   	ret    

f0103236 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103236:	55                   	push   %ebp
f0103237:	89 e5                	mov    %esp,%ebp
f0103239:	57                   	push   %edi
f010323a:	56                   	push   %esi
f010323b:	53                   	push   %ebx
f010323c:	83 ec 2c             	sub    $0x2c,%esp
f010323f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103242:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103245:	c7 06 d7 54 10 f0    	movl   $0xf01054d7,(%esi)
	info->eip_line = 0;
f010324b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103252:	c7 46 08 d7 54 10 f0 	movl   $0xf01054d7,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103259:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103260:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103263:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010326a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103270:	77 21                	ja     f0103293 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103272:	a1 00 00 20 00       	mov    0x200000,%eax
f0103277:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f010327a:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010327f:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0103285:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103288:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f010328e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103291:	eb 1a                	jmp    f01032ad <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103293:	c7 45 d0 bc f2 10 f0 	movl   $0xf010f2bc,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010329a:	c7 45 cc 39 c9 10 f0 	movl   $0xf010c939,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01032a1:	b8 38 c9 10 f0       	mov    $0xf010c938,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01032a6:	c7 45 d4 f0 56 10 f0 	movl   $0xf01056f0,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01032ad:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01032b0:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f01032b3:	0f 83 2b 01 00 00    	jae    f01033e4 <debuginfo_eip+0x1ae>
f01032b9:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01032bd:	0f 85 28 01 00 00    	jne    f01033eb <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01032c3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01032ca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032cd:	29 d8                	sub    %ebx,%eax
f01032cf:	c1 f8 02             	sar    $0x2,%eax
f01032d2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01032d8:	83 e8 01             	sub    $0x1,%eax
f01032db:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01032de:	57                   	push   %edi
f01032df:	6a 64                	push   $0x64
f01032e1:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01032e4:	89 c1                	mov    %eax,%ecx
f01032e6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01032e9:	89 d8                	mov    %ebx,%eax
f01032eb:	e8 50 fe ff ff       	call   f0103140 <stab_binsearch>
	if (lfile == 0)
f01032f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032f3:	83 c4 08             	add    $0x8,%esp
f01032f6:	85 c0                	test   %eax,%eax
f01032f8:	0f 84 f4 00 00 00    	je     f01033f2 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01032fe:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103301:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103304:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103307:	57                   	push   %edi
f0103308:	6a 24                	push   $0x24
f010330a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010330d:	89 c1                	mov    %eax,%ecx
f010330f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103312:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0103315:	89 d8                	mov    %ebx,%eax
f0103317:	e8 24 fe ff ff       	call   f0103140 <stab_binsearch>

	if (lfun <= rfun) {
f010331c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010331f:	83 c4 08             	add    $0x8,%esp
f0103322:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103325:	7f 24                	jg     f010334b <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103327:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010332a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010332d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103330:	8b 02                	mov    (%edx),%eax
f0103332:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103335:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103338:	29 f9                	sub    %edi,%ecx
f010333a:	39 c8                	cmp    %ecx,%eax
f010333c:	73 05                	jae    f0103343 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010333e:	01 f8                	add    %edi,%eax
f0103340:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103343:	8b 42 08             	mov    0x8(%edx),%eax
f0103346:	89 46 10             	mov    %eax,0x10(%esi)
f0103349:	eb 06                	jmp    f0103351 <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010334b:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010334e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103351:	83 ec 08             	sub    $0x8,%esp
f0103354:	6a 3a                	push   $0x3a
f0103356:	ff 76 08             	pushl  0x8(%esi)
f0103359:	e8 9a 08 00 00       	call   f0103bf8 <strfind>
f010335e:	2b 46 08             	sub    0x8(%esi),%eax
f0103361:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103364:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103367:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010336a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010336d:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0103370:	83 c4 10             	add    $0x10,%esp
f0103373:	eb 06                	jmp    f010337b <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103375:	83 eb 01             	sub    $0x1,%ebx
f0103378:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010337b:	39 fb                	cmp    %edi,%ebx
f010337d:	7c 2d                	jl     f01033ac <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f010337f:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103383:	80 fa 84             	cmp    $0x84,%dl
f0103386:	74 0b                	je     f0103393 <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103388:	80 fa 64             	cmp    $0x64,%dl
f010338b:	75 e8                	jne    f0103375 <debuginfo_eip+0x13f>
f010338d:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103391:	74 e2                	je     f0103375 <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103393:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103396:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103399:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010339c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010339f:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01033a2:	29 f8                	sub    %edi,%eax
f01033a4:	39 c2                	cmp    %eax,%edx
f01033a6:	73 04                	jae    f01033ac <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01033a8:	01 fa                	add    %edi,%edx
f01033aa:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033ac:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01033af:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033b2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01033b7:	39 cb                	cmp    %ecx,%ebx
f01033b9:	7d 43                	jge    f01033fe <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f01033bb:	8d 53 01             	lea    0x1(%ebx),%edx
f01033be:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01033c1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01033c4:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01033c7:	eb 07                	jmp    f01033d0 <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01033c9:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01033cd:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01033d0:	39 ca                	cmp    %ecx,%edx
f01033d2:	74 25                	je     f01033f9 <debuginfo_eip+0x1c3>
f01033d4:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01033d7:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01033db:	74 ec                	je     f01033c9 <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01033e2:	eb 1a                	jmp    f01033fe <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01033e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033e9:	eb 13                	jmp    f01033fe <debuginfo_eip+0x1c8>
f01033eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033f0:	eb 0c                	jmp    f01033fe <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01033f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033f7:	eb 05                	jmp    f01033fe <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01033f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103401:	5b                   	pop    %ebx
f0103402:	5e                   	pop    %esi
f0103403:	5f                   	pop    %edi
f0103404:	5d                   	pop    %ebp
f0103405:	c3                   	ret    

f0103406 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103406:	55                   	push   %ebp
f0103407:	89 e5                	mov    %esp,%ebp
f0103409:	57                   	push   %edi
f010340a:	56                   	push   %esi
f010340b:	53                   	push   %ebx
f010340c:	83 ec 1c             	sub    $0x1c,%esp
f010340f:	89 c7                	mov    %eax,%edi
f0103411:	89 d6                	mov    %edx,%esi
f0103413:	8b 45 08             	mov    0x8(%ebp),%eax
f0103416:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103419:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010341c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010341f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103422:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103427:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010342a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010342d:	39 d3                	cmp    %edx,%ebx
f010342f:	72 05                	jb     f0103436 <printnum+0x30>
f0103431:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103434:	77 45                	ja     f010347b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103436:	83 ec 0c             	sub    $0xc,%esp
f0103439:	ff 75 18             	pushl  0x18(%ebp)
f010343c:	8b 45 14             	mov    0x14(%ebp),%eax
f010343f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103442:	53                   	push   %ebx
f0103443:	ff 75 10             	pushl  0x10(%ebp)
f0103446:	83 ec 08             	sub    $0x8,%esp
f0103449:	ff 75 e4             	pushl  -0x1c(%ebp)
f010344c:	ff 75 e0             	pushl  -0x20(%ebp)
f010344f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103452:	ff 75 d8             	pushl  -0x28(%ebp)
f0103455:	e8 c6 09 00 00       	call   f0103e20 <__udivdi3>
f010345a:	83 c4 18             	add    $0x18,%esp
f010345d:	52                   	push   %edx
f010345e:	50                   	push   %eax
f010345f:	89 f2                	mov    %esi,%edx
f0103461:	89 f8                	mov    %edi,%eax
f0103463:	e8 9e ff ff ff       	call   f0103406 <printnum>
f0103468:	83 c4 20             	add    $0x20,%esp
f010346b:	eb 18                	jmp    f0103485 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010346d:	83 ec 08             	sub    $0x8,%esp
f0103470:	56                   	push   %esi
f0103471:	ff 75 18             	pushl  0x18(%ebp)
f0103474:	ff d7                	call   *%edi
f0103476:	83 c4 10             	add    $0x10,%esp
f0103479:	eb 03                	jmp    f010347e <printnum+0x78>
f010347b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010347e:	83 eb 01             	sub    $0x1,%ebx
f0103481:	85 db                	test   %ebx,%ebx
f0103483:	7f e8                	jg     f010346d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103485:	83 ec 08             	sub    $0x8,%esp
f0103488:	56                   	push   %esi
f0103489:	83 ec 04             	sub    $0x4,%esp
f010348c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010348f:	ff 75 e0             	pushl  -0x20(%ebp)
f0103492:	ff 75 dc             	pushl  -0x24(%ebp)
f0103495:	ff 75 d8             	pushl  -0x28(%ebp)
f0103498:	e8 b3 0a 00 00       	call   f0103f50 <__umoddi3>
f010349d:	83 c4 14             	add    $0x14,%esp
f01034a0:	0f be 80 e1 54 10 f0 	movsbl -0xfefab1f(%eax),%eax
f01034a7:	50                   	push   %eax
f01034a8:	ff d7                	call   *%edi
}
f01034aa:	83 c4 10             	add    $0x10,%esp
f01034ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01034b0:	5b                   	pop    %ebx
f01034b1:	5e                   	pop    %esi
f01034b2:	5f                   	pop    %edi
f01034b3:	5d                   	pop    %ebp
f01034b4:	c3                   	ret    

f01034b5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01034b5:	55                   	push   %ebp
f01034b6:	89 e5                	mov    %esp,%ebp
f01034b8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01034bb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01034bf:	8b 10                	mov    (%eax),%edx
f01034c1:	3b 50 04             	cmp    0x4(%eax),%edx
f01034c4:	73 0a                	jae    f01034d0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01034c6:	8d 4a 01             	lea    0x1(%edx),%ecx
f01034c9:	89 08                	mov    %ecx,(%eax)
f01034cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ce:	88 02                	mov    %al,(%edx)
}
f01034d0:	5d                   	pop    %ebp
f01034d1:	c3                   	ret    

f01034d2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01034d2:	55                   	push   %ebp
f01034d3:	89 e5                	mov    %esp,%ebp
f01034d5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01034d8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01034db:	50                   	push   %eax
f01034dc:	ff 75 10             	pushl  0x10(%ebp)
f01034df:	ff 75 0c             	pushl  0xc(%ebp)
f01034e2:	ff 75 08             	pushl  0x8(%ebp)
f01034e5:	e8 05 00 00 00       	call   f01034ef <vprintfmt>
	va_end(ap);
}
f01034ea:	83 c4 10             	add    $0x10,%esp
f01034ed:	c9                   	leave  
f01034ee:	c3                   	ret    

f01034ef <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01034ef:	55                   	push   %ebp
f01034f0:	89 e5                	mov    %esp,%ebp
f01034f2:	57                   	push   %edi
f01034f3:	56                   	push   %esi
f01034f4:	53                   	push   %ebx
f01034f5:	83 ec 2c             	sub    $0x2c,%esp
f01034f8:	8b 75 08             	mov    0x8(%ebp),%esi
f01034fb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034fe:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103501:	eb 12                	jmp    f0103515 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103503:	85 c0                	test   %eax,%eax
f0103505:	0f 84 42 04 00 00    	je     f010394d <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f010350b:	83 ec 08             	sub    $0x8,%esp
f010350e:	53                   	push   %ebx
f010350f:	50                   	push   %eax
f0103510:	ff d6                	call   *%esi
f0103512:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103515:	83 c7 01             	add    $0x1,%edi
f0103518:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010351c:	83 f8 25             	cmp    $0x25,%eax
f010351f:	75 e2                	jne    f0103503 <vprintfmt+0x14>
f0103521:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103525:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010352c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103533:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010353a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010353f:	eb 07                	jmp    f0103548 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103541:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103544:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103548:	8d 47 01             	lea    0x1(%edi),%eax
f010354b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010354e:	0f b6 07             	movzbl (%edi),%eax
f0103551:	0f b6 d0             	movzbl %al,%edx
f0103554:	83 e8 23             	sub    $0x23,%eax
f0103557:	3c 55                	cmp    $0x55,%al
f0103559:	0f 87 d3 03 00 00    	ja     f0103932 <vprintfmt+0x443>
f010355f:	0f b6 c0             	movzbl %al,%eax
f0103562:	ff 24 85 6c 55 10 f0 	jmp    *-0xfefaa94(,%eax,4)
f0103569:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010356c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103570:	eb d6                	jmp    f0103548 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103572:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103575:	b8 00 00 00 00       	mov    $0x0,%eax
f010357a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010357d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103580:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103584:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103587:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010358a:	83 f9 09             	cmp    $0x9,%ecx
f010358d:	77 3f                	ja     f01035ce <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010358f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103592:	eb e9                	jmp    f010357d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103594:	8b 45 14             	mov    0x14(%ebp),%eax
f0103597:	8b 00                	mov    (%eax),%eax
f0103599:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010359c:	8b 45 14             	mov    0x14(%ebp),%eax
f010359f:	8d 40 04             	lea    0x4(%eax),%eax
f01035a2:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01035a8:	eb 2a                	jmp    f01035d4 <vprintfmt+0xe5>
f01035aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035ad:	85 c0                	test   %eax,%eax
f01035af:	ba 00 00 00 00       	mov    $0x0,%edx
f01035b4:	0f 49 d0             	cmovns %eax,%edx
f01035b7:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035bd:	eb 89                	jmp    f0103548 <vprintfmt+0x59>
f01035bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01035c2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01035c9:	e9 7a ff ff ff       	jmp    f0103548 <vprintfmt+0x59>
f01035ce:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01035d1:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01035d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035d8:	0f 89 6a ff ff ff    	jns    f0103548 <vprintfmt+0x59>
				width = precision, precision = -1;
f01035de:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01035e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035e4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01035eb:	e9 58 ff ff ff       	jmp    f0103548 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01035f0:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01035f6:	e9 4d ff ff ff       	jmp    f0103548 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01035fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01035fe:	8d 78 04             	lea    0x4(%eax),%edi
f0103601:	83 ec 08             	sub    $0x8,%esp
f0103604:	53                   	push   %ebx
f0103605:	ff 30                	pushl  (%eax)
f0103607:	ff d6                	call   *%esi
			break;
f0103609:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010360c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010360f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103612:	e9 fe fe ff ff       	jmp    f0103515 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103617:	8b 45 14             	mov    0x14(%ebp),%eax
f010361a:	8d 78 04             	lea    0x4(%eax),%edi
f010361d:	8b 00                	mov    (%eax),%eax
f010361f:	99                   	cltd   
f0103620:	31 d0                	xor    %edx,%eax
f0103622:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103624:	83 f8 06             	cmp    $0x6,%eax
f0103627:	7f 0b                	jg     f0103634 <vprintfmt+0x145>
f0103629:	8b 14 85 c4 56 10 f0 	mov    -0xfefa93c(,%eax,4),%edx
f0103630:	85 d2                	test   %edx,%edx
f0103632:	75 1b                	jne    f010364f <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103634:	50                   	push   %eax
f0103635:	68 f9 54 10 f0       	push   $0xf01054f9
f010363a:	53                   	push   %ebx
f010363b:	56                   	push   %esi
f010363c:	e8 91 fe ff ff       	call   f01034d2 <printfmt>
f0103641:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103644:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103647:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010364a:	e9 c6 fe ff ff       	jmp    f0103515 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010364f:	52                   	push   %edx
f0103650:	68 45 4d 10 f0       	push   $0xf0104d45
f0103655:	53                   	push   %ebx
f0103656:	56                   	push   %esi
f0103657:	e8 76 fe ff ff       	call   f01034d2 <printfmt>
f010365c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010365f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103662:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103665:	e9 ab fe ff ff       	jmp    f0103515 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010366a:	8b 45 14             	mov    0x14(%ebp),%eax
f010366d:	83 c0 04             	add    $0x4,%eax
f0103670:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103673:	8b 45 14             	mov    0x14(%ebp),%eax
f0103676:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103678:	85 ff                	test   %edi,%edi
f010367a:	b8 f2 54 10 f0       	mov    $0xf01054f2,%eax
f010367f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103682:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103686:	0f 8e 94 00 00 00    	jle    f0103720 <vprintfmt+0x231>
f010368c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103690:	0f 84 98 00 00 00    	je     f010372e <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103696:	83 ec 08             	sub    $0x8,%esp
f0103699:	ff 75 d0             	pushl  -0x30(%ebp)
f010369c:	57                   	push   %edi
f010369d:	e8 0c 04 00 00       	call   f0103aae <strnlen>
f01036a2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01036a5:	29 c1                	sub    %eax,%ecx
f01036a7:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01036aa:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01036ad:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01036b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01036b4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01036b7:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036b9:	eb 0f                	jmp    f01036ca <vprintfmt+0x1db>
					putch(padc, putdat);
f01036bb:	83 ec 08             	sub    $0x8,%esp
f01036be:	53                   	push   %ebx
f01036bf:	ff 75 e0             	pushl  -0x20(%ebp)
f01036c2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036c4:	83 ef 01             	sub    $0x1,%edi
f01036c7:	83 c4 10             	add    $0x10,%esp
f01036ca:	85 ff                	test   %edi,%edi
f01036cc:	7f ed                	jg     f01036bb <vprintfmt+0x1cc>
f01036ce:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01036d1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01036d4:	85 c9                	test   %ecx,%ecx
f01036d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01036db:	0f 49 c1             	cmovns %ecx,%eax
f01036de:	29 c1                	sub    %eax,%ecx
f01036e0:	89 75 08             	mov    %esi,0x8(%ebp)
f01036e3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01036e6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01036e9:	89 cb                	mov    %ecx,%ebx
f01036eb:	eb 4d                	jmp    f010373a <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01036ed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01036f1:	74 1b                	je     f010370e <vprintfmt+0x21f>
f01036f3:	0f be c0             	movsbl %al,%eax
f01036f6:	83 e8 20             	sub    $0x20,%eax
f01036f9:	83 f8 5e             	cmp    $0x5e,%eax
f01036fc:	76 10                	jbe    f010370e <vprintfmt+0x21f>
					putch('?', putdat);
f01036fe:	83 ec 08             	sub    $0x8,%esp
f0103701:	ff 75 0c             	pushl  0xc(%ebp)
f0103704:	6a 3f                	push   $0x3f
f0103706:	ff 55 08             	call   *0x8(%ebp)
f0103709:	83 c4 10             	add    $0x10,%esp
f010370c:	eb 0d                	jmp    f010371b <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f010370e:	83 ec 08             	sub    $0x8,%esp
f0103711:	ff 75 0c             	pushl  0xc(%ebp)
f0103714:	52                   	push   %edx
f0103715:	ff 55 08             	call   *0x8(%ebp)
f0103718:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010371b:	83 eb 01             	sub    $0x1,%ebx
f010371e:	eb 1a                	jmp    f010373a <vprintfmt+0x24b>
f0103720:	89 75 08             	mov    %esi,0x8(%ebp)
f0103723:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103726:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103729:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010372c:	eb 0c                	jmp    f010373a <vprintfmt+0x24b>
f010372e:	89 75 08             	mov    %esi,0x8(%ebp)
f0103731:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103734:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103737:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010373a:	83 c7 01             	add    $0x1,%edi
f010373d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103741:	0f be d0             	movsbl %al,%edx
f0103744:	85 d2                	test   %edx,%edx
f0103746:	74 23                	je     f010376b <vprintfmt+0x27c>
f0103748:	85 f6                	test   %esi,%esi
f010374a:	78 a1                	js     f01036ed <vprintfmt+0x1fe>
f010374c:	83 ee 01             	sub    $0x1,%esi
f010374f:	79 9c                	jns    f01036ed <vprintfmt+0x1fe>
f0103751:	89 df                	mov    %ebx,%edi
f0103753:	8b 75 08             	mov    0x8(%ebp),%esi
f0103756:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103759:	eb 18                	jmp    f0103773 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010375b:	83 ec 08             	sub    $0x8,%esp
f010375e:	53                   	push   %ebx
f010375f:	6a 20                	push   $0x20
f0103761:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103763:	83 ef 01             	sub    $0x1,%edi
f0103766:	83 c4 10             	add    $0x10,%esp
f0103769:	eb 08                	jmp    f0103773 <vprintfmt+0x284>
f010376b:	89 df                	mov    %ebx,%edi
f010376d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103770:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103773:	85 ff                	test   %edi,%edi
f0103775:	7f e4                	jg     f010375b <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103777:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010377a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010377d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103780:	e9 90 fd ff ff       	jmp    f0103515 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103785:	83 f9 01             	cmp    $0x1,%ecx
f0103788:	7e 19                	jle    f01037a3 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f010378a:	8b 45 14             	mov    0x14(%ebp),%eax
f010378d:	8b 50 04             	mov    0x4(%eax),%edx
f0103790:	8b 00                	mov    (%eax),%eax
f0103792:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103795:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103798:	8b 45 14             	mov    0x14(%ebp),%eax
f010379b:	8d 40 08             	lea    0x8(%eax),%eax
f010379e:	89 45 14             	mov    %eax,0x14(%ebp)
f01037a1:	eb 38                	jmp    f01037db <vprintfmt+0x2ec>
	else if (lflag)
f01037a3:	85 c9                	test   %ecx,%ecx
f01037a5:	74 1b                	je     f01037c2 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01037a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01037aa:	8b 00                	mov    (%eax),%eax
f01037ac:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037af:	89 c1                	mov    %eax,%ecx
f01037b1:	c1 f9 1f             	sar    $0x1f,%ecx
f01037b4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ba:	8d 40 04             	lea    0x4(%eax),%eax
f01037bd:	89 45 14             	mov    %eax,0x14(%ebp)
f01037c0:	eb 19                	jmp    f01037db <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f01037c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01037c5:	8b 00                	mov    (%eax),%eax
f01037c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037ca:	89 c1                	mov    %eax,%ecx
f01037cc:	c1 f9 1f             	sar    $0x1f,%ecx
f01037cf:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01037d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01037d5:	8d 40 04             	lea    0x4(%eax),%eax
f01037d8:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01037db:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037de:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01037e1:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01037e6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01037ea:	0f 89 0e 01 00 00    	jns    f01038fe <vprintfmt+0x40f>
				putch('-', putdat);
f01037f0:	83 ec 08             	sub    $0x8,%esp
f01037f3:	53                   	push   %ebx
f01037f4:	6a 2d                	push   $0x2d
f01037f6:	ff d6                	call   *%esi
				num = -(long long) num;
f01037f8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01037fb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01037fe:	f7 da                	neg    %edx
f0103800:	83 d1 00             	adc    $0x0,%ecx
f0103803:	f7 d9                	neg    %ecx
f0103805:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103808:	b8 0a 00 00 00       	mov    $0xa,%eax
f010380d:	e9 ec 00 00 00       	jmp    f01038fe <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103812:	83 f9 01             	cmp    $0x1,%ecx
f0103815:	7e 18                	jle    f010382f <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103817:	8b 45 14             	mov    0x14(%ebp),%eax
f010381a:	8b 10                	mov    (%eax),%edx
f010381c:	8b 48 04             	mov    0x4(%eax),%ecx
f010381f:	8d 40 08             	lea    0x8(%eax),%eax
f0103822:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103825:	b8 0a 00 00 00       	mov    $0xa,%eax
f010382a:	e9 cf 00 00 00       	jmp    f01038fe <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010382f:	85 c9                	test   %ecx,%ecx
f0103831:	74 1a                	je     f010384d <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103833:	8b 45 14             	mov    0x14(%ebp),%eax
f0103836:	8b 10                	mov    (%eax),%edx
f0103838:	b9 00 00 00 00       	mov    $0x0,%ecx
f010383d:	8d 40 04             	lea    0x4(%eax),%eax
f0103840:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103843:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103848:	e9 b1 00 00 00       	jmp    f01038fe <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010384d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103850:	8b 10                	mov    (%eax),%edx
f0103852:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103857:	8d 40 04             	lea    0x4(%eax),%eax
f010385a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010385d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103862:	e9 97 00 00 00       	jmp    f01038fe <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103867:	83 ec 08             	sub    $0x8,%esp
f010386a:	53                   	push   %ebx
f010386b:	6a 58                	push   $0x58
f010386d:	ff d6                	call   *%esi
			putch('X', putdat);
f010386f:	83 c4 08             	add    $0x8,%esp
f0103872:	53                   	push   %ebx
f0103873:	6a 58                	push   $0x58
f0103875:	ff d6                	call   *%esi
			putch('X', putdat);
f0103877:	83 c4 08             	add    $0x8,%esp
f010387a:	53                   	push   %ebx
f010387b:	6a 58                	push   $0x58
f010387d:	ff d6                	call   *%esi
			break;
f010387f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103882:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103885:	e9 8b fc ff ff       	jmp    f0103515 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010388a:	83 ec 08             	sub    $0x8,%esp
f010388d:	53                   	push   %ebx
f010388e:	6a 30                	push   $0x30
f0103890:	ff d6                	call   *%esi
			putch('x', putdat);
f0103892:	83 c4 08             	add    $0x8,%esp
f0103895:	53                   	push   %ebx
f0103896:	6a 78                	push   $0x78
f0103898:	ff d6                	call   *%esi
			num = (unsigned long long)
f010389a:	8b 45 14             	mov    0x14(%ebp),%eax
f010389d:	8b 10                	mov    (%eax),%edx
f010389f:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01038a4:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01038a7:	8d 40 04             	lea    0x4(%eax),%eax
f01038aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01038ad:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01038b2:	eb 4a                	jmp    f01038fe <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01038b4:	83 f9 01             	cmp    $0x1,%ecx
f01038b7:	7e 15                	jle    f01038ce <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f01038b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038bc:	8b 10                	mov    (%eax),%edx
f01038be:	8b 48 04             	mov    0x4(%eax),%ecx
f01038c1:	8d 40 08             	lea    0x8(%eax),%eax
f01038c4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01038c7:	b8 10 00 00 00       	mov    $0x10,%eax
f01038cc:	eb 30                	jmp    f01038fe <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01038ce:	85 c9                	test   %ecx,%ecx
f01038d0:	74 17                	je     f01038e9 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f01038d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01038d5:	8b 10                	mov    (%eax),%edx
f01038d7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038dc:	8d 40 04             	lea    0x4(%eax),%eax
f01038df:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01038e2:	b8 10 00 00 00       	mov    $0x10,%eax
f01038e7:	eb 15                	jmp    f01038fe <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01038e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ec:	8b 10                	mov    (%eax),%edx
f01038ee:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038f3:	8d 40 04             	lea    0x4(%eax),%eax
f01038f6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01038f9:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01038fe:	83 ec 0c             	sub    $0xc,%esp
f0103901:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103905:	57                   	push   %edi
f0103906:	ff 75 e0             	pushl  -0x20(%ebp)
f0103909:	50                   	push   %eax
f010390a:	51                   	push   %ecx
f010390b:	52                   	push   %edx
f010390c:	89 da                	mov    %ebx,%edx
f010390e:	89 f0                	mov    %esi,%eax
f0103910:	e8 f1 fa ff ff       	call   f0103406 <printnum>
			break;
f0103915:	83 c4 20             	add    $0x20,%esp
f0103918:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010391b:	e9 f5 fb ff ff       	jmp    f0103515 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103920:	83 ec 08             	sub    $0x8,%esp
f0103923:	53                   	push   %ebx
f0103924:	52                   	push   %edx
f0103925:	ff d6                	call   *%esi
			break;
f0103927:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010392a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010392d:	e9 e3 fb ff ff       	jmp    f0103515 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103932:	83 ec 08             	sub    $0x8,%esp
f0103935:	53                   	push   %ebx
f0103936:	6a 25                	push   $0x25
f0103938:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010393a:	83 c4 10             	add    $0x10,%esp
f010393d:	eb 03                	jmp    f0103942 <vprintfmt+0x453>
f010393f:	83 ef 01             	sub    $0x1,%edi
f0103942:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103946:	75 f7                	jne    f010393f <vprintfmt+0x450>
f0103948:	e9 c8 fb ff ff       	jmp    f0103515 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010394d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103950:	5b                   	pop    %ebx
f0103951:	5e                   	pop    %esi
f0103952:	5f                   	pop    %edi
f0103953:	5d                   	pop    %ebp
f0103954:	c3                   	ret    

f0103955 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103955:	55                   	push   %ebp
f0103956:	89 e5                	mov    %esp,%ebp
f0103958:	83 ec 18             	sub    $0x18,%esp
f010395b:	8b 45 08             	mov    0x8(%ebp),%eax
f010395e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103961:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103964:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103968:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010396b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103972:	85 c0                	test   %eax,%eax
f0103974:	74 26                	je     f010399c <vsnprintf+0x47>
f0103976:	85 d2                	test   %edx,%edx
f0103978:	7e 22                	jle    f010399c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010397a:	ff 75 14             	pushl  0x14(%ebp)
f010397d:	ff 75 10             	pushl  0x10(%ebp)
f0103980:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103983:	50                   	push   %eax
f0103984:	68 b5 34 10 f0       	push   $0xf01034b5
f0103989:	e8 61 fb ff ff       	call   f01034ef <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010398e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103991:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103994:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103997:	83 c4 10             	add    $0x10,%esp
f010399a:	eb 05                	jmp    f01039a1 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010399c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01039a1:	c9                   	leave  
f01039a2:	c3                   	ret    

f01039a3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01039a3:	55                   	push   %ebp
f01039a4:	89 e5                	mov    %esp,%ebp
f01039a6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01039a9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01039ac:	50                   	push   %eax
f01039ad:	ff 75 10             	pushl  0x10(%ebp)
f01039b0:	ff 75 0c             	pushl  0xc(%ebp)
f01039b3:	ff 75 08             	pushl  0x8(%ebp)
f01039b6:	e8 9a ff ff ff       	call   f0103955 <vsnprintf>
	va_end(ap);

	return rc;
}
f01039bb:	c9                   	leave  
f01039bc:	c3                   	ret    

f01039bd <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01039bd:	55                   	push   %ebp
f01039be:	89 e5                	mov    %esp,%ebp
f01039c0:	57                   	push   %edi
f01039c1:	56                   	push   %esi
f01039c2:	53                   	push   %ebx
f01039c3:	83 ec 0c             	sub    $0xc,%esp
f01039c6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01039c9:	85 c0                	test   %eax,%eax
f01039cb:	74 11                	je     f01039de <readline+0x21>
		cprintf("%s", prompt);
f01039cd:	83 ec 08             	sub    $0x8,%esp
f01039d0:	50                   	push   %eax
f01039d1:	68 45 4d 10 f0       	push   $0xf0104d45
f01039d6:	e8 a7 f3 ff ff       	call   f0102d82 <cprintf>
f01039db:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01039de:	83 ec 0c             	sub    $0xc,%esp
f01039e1:	6a 00                	push   $0x0
f01039e3:	e8 4e cc ff ff       	call   f0100636 <iscons>
f01039e8:	89 c7                	mov    %eax,%edi
f01039ea:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01039ed:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01039f2:	e8 2e cc ff ff       	call   f0100625 <getchar>
f01039f7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01039f9:	85 c0                	test   %eax,%eax
f01039fb:	79 18                	jns    f0103a15 <readline+0x58>
			cprintf("read error: %e\n", c);
f01039fd:	83 ec 08             	sub    $0x8,%esp
f0103a00:	50                   	push   %eax
f0103a01:	68 e0 56 10 f0       	push   $0xf01056e0
f0103a06:	e8 77 f3 ff ff       	call   f0102d82 <cprintf>
			return NULL;
f0103a0b:	83 c4 10             	add    $0x10,%esp
f0103a0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a13:	eb 79                	jmp    f0103a8e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103a15:	83 f8 08             	cmp    $0x8,%eax
f0103a18:	0f 94 c2             	sete   %dl
f0103a1b:	83 f8 7f             	cmp    $0x7f,%eax
f0103a1e:	0f 94 c0             	sete   %al
f0103a21:	08 c2                	or     %al,%dl
f0103a23:	74 1a                	je     f0103a3f <readline+0x82>
f0103a25:	85 f6                	test   %esi,%esi
f0103a27:	7e 16                	jle    f0103a3f <readline+0x82>
			if (echoing)
f0103a29:	85 ff                	test   %edi,%edi
f0103a2b:	74 0d                	je     f0103a3a <readline+0x7d>
				cputchar('\b');
f0103a2d:	83 ec 0c             	sub    $0xc,%esp
f0103a30:	6a 08                	push   $0x8
f0103a32:	e8 de cb ff ff       	call   f0100615 <cputchar>
f0103a37:	83 c4 10             	add    $0x10,%esp
			i--;
f0103a3a:	83 ee 01             	sub    $0x1,%esi
f0103a3d:	eb b3                	jmp    f01039f2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103a3f:	83 fb 1f             	cmp    $0x1f,%ebx
f0103a42:	7e 23                	jle    f0103a67 <readline+0xaa>
f0103a44:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103a4a:	7f 1b                	jg     f0103a67 <readline+0xaa>
			if (echoing)
f0103a4c:	85 ff                	test   %edi,%edi
f0103a4e:	74 0c                	je     f0103a5c <readline+0x9f>
				cputchar(c);
f0103a50:	83 ec 0c             	sub    $0xc,%esp
f0103a53:	53                   	push   %ebx
f0103a54:	e8 bc cb ff ff       	call   f0100615 <cputchar>
f0103a59:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103a5c:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0103a62:	8d 76 01             	lea    0x1(%esi),%esi
f0103a65:	eb 8b                	jmp    f01039f2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103a67:	83 fb 0a             	cmp    $0xa,%ebx
f0103a6a:	74 05                	je     f0103a71 <readline+0xb4>
f0103a6c:	83 fb 0d             	cmp    $0xd,%ebx
f0103a6f:	75 81                	jne    f01039f2 <readline+0x35>
			if (echoing)
f0103a71:	85 ff                	test   %edi,%edi
f0103a73:	74 0d                	je     f0103a82 <readline+0xc5>
				cputchar('\n');
f0103a75:	83 ec 0c             	sub    $0xc,%esp
f0103a78:	6a 0a                	push   $0xa
f0103a7a:	e8 96 cb ff ff       	call   f0100615 <cputchar>
f0103a7f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103a82:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0103a89:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f0103a8e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a91:	5b                   	pop    %ebx
f0103a92:	5e                   	pop    %esi
f0103a93:	5f                   	pop    %edi
f0103a94:	5d                   	pop    %ebp
f0103a95:	c3                   	ret    

f0103a96 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a96:	55                   	push   %ebp
f0103a97:	89 e5                	mov    %esp,%ebp
f0103a99:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103aa1:	eb 03                	jmp    f0103aa6 <strlen+0x10>
		n++;
f0103aa3:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103aa6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103aaa:	75 f7                	jne    f0103aa3 <strlen+0xd>
		n++;
	return n;
}
f0103aac:	5d                   	pop    %ebp
f0103aad:	c3                   	ret    

f0103aae <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103aae:	55                   	push   %ebp
f0103aaf:	89 e5                	mov    %esp,%ebp
f0103ab1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ab4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ab7:	ba 00 00 00 00       	mov    $0x0,%edx
f0103abc:	eb 03                	jmp    f0103ac1 <strnlen+0x13>
		n++;
f0103abe:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103ac1:	39 c2                	cmp    %eax,%edx
f0103ac3:	74 08                	je     f0103acd <strnlen+0x1f>
f0103ac5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103ac9:	75 f3                	jne    f0103abe <strnlen+0x10>
f0103acb:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103acd:	5d                   	pop    %ebp
f0103ace:	c3                   	ret    

f0103acf <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103acf:	55                   	push   %ebp
f0103ad0:	89 e5                	mov    %esp,%ebp
f0103ad2:	53                   	push   %ebx
f0103ad3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ad6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ad9:	89 c2                	mov    %eax,%edx
f0103adb:	83 c2 01             	add    $0x1,%edx
f0103ade:	83 c1 01             	add    $0x1,%ecx
f0103ae1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103ae5:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103ae8:	84 db                	test   %bl,%bl
f0103aea:	75 ef                	jne    f0103adb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103aec:	5b                   	pop    %ebx
f0103aed:	5d                   	pop    %ebp
f0103aee:	c3                   	ret    

f0103aef <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103aef:	55                   	push   %ebp
f0103af0:	89 e5                	mov    %esp,%ebp
f0103af2:	53                   	push   %ebx
f0103af3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103af6:	53                   	push   %ebx
f0103af7:	e8 9a ff ff ff       	call   f0103a96 <strlen>
f0103afc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103aff:	ff 75 0c             	pushl  0xc(%ebp)
f0103b02:	01 d8                	add    %ebx,%eax
f0103b04:	50                   	push   %eax
f0103b05:	e8 c5 ff ff ff       	call   f0103acf <strcpy>
	return dst;
}
f0103b0a:	89 d8                	mov    %ebx,%eax
f0103b0c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b0f:	c9                   	leave  
f0103b10:	c3                   	ret    

f0103b11 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b11:	55                   	push   %ebp
f0103b12:	89 e5                	mov    %esp,%ebp
f0103b14:	56                   	push   %esi
f0103b15:	53                   	push   %ebx
f0103b16:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b19:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b1c:	89 f3                	mov    %esi,%ebx
f0103b1e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b21:	89 f2                	mov    %esi,%edx
f0103b23:	eb 0f                	jmp    f0103b34 <strncpy+0x23>
		*dst++ = *src;
f0103b25:	83 c2 01             	add    $0x1,%edx
f0103b28:	0f b6 01             	movzbl (%ecx),%eax
f0103b2b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103b2e:	80 39 01             	cmpb   $0x1,(%ecx)
f0103b31:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b34:	39 da                	cmp    %ebx,%edx
f0103b36:	75 ed                	jne    f0103b25 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103b38:	89 f0                	mov    %esi,%eax
f0103b3a:	5b                   	pop    %ebx
f0103b3b:	5e                   	pop    %esi
f0103b3c:	5d                   	pop    %ebp
f0103b3d:	c3                   	ret    

f0103b3e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103b3e:	55                   	push   %ebp
f0103b3f:	89 e5                	mov    %esp,%ebp
f0103b41:	56                   	push   %esi
f0103b42:	53                   	push   %ebx
f0103b43:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103b49:	8b 55 10             	mov    0x10(%ebp),%edx
f0103b4c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103b4e:	85 d2                	test   %edx,%edx
f0103b50:	74 21                	je     f0103b73 <strlcpy+0x35>
f0103b52:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103b56:	89 f2                	mov    %esi,%edx
f0103b58:	eb 09                	jmp    f0103b63 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103b5a:	83 c2 01             	add    $0x1,%edx
f0103b5d:	83 c1 01             	add    $0x1,%ecx
f0103b60:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103b63:	39 c2                	cmp    %eax,%edx
f0103b65:	74 09                	je     f0103b70 <strlcpy+0x32>
f0103b67:	0f b6 19             	movzbl (%ecx),%ebx
f0103b6a:	84 db                	test   %bl,%bl
f0103b6c:	75 ec                	jne    f0103b5a <strlcpy+0x1c>
f0103b6e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103b70:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b73:	29 f0                	sub    %esi,%eax
}
f0103b75:	5b                   	pop    %ebx
f0103b76:	5e                   	pop    %esi
f0103b77:	5d                   	pop    %ebp
f0103b78:	c3                   	ret    

f0103b79 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b79:	55                   	push   %ebp
f0103b7a:	89 e5                	mov    %esp,%ebp
f0103b7c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b7f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b82:	eb 06                	jmp    f0103b8a <strcmp+0x11>
		p++, q++;
f0103b84:	83 c1 01             	add    $0x1,%ecx
f0103b87:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b8a:	0f b6 01             	movzbl (%ecx),%eax
f0103b8d:	84 c0                	test   %al,%al
f0103b8f:	74 04                	je     f0103b95 <strcmp+0x1c>
f0103b91:	3a 02                	cmp    (%edx),%al
f0103b93:	74 ef                	je     f0103b84 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b95:	0f b6 c0             	movzbl %al,%eax
f0103b98:	0f b6 12             	movzbl (%edx),%edx
f0103b9b:	29 d0                	sub    %edx,%eax
}
f0103b9d:	5d                   	pop    %ebp
f0103b9e:	c3                   	ret    

f0103b9f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b9f:	55                   	push   %ebp
f0103ba0:	89 e5                	mov    %esp,%ebp
f0103ba2:	53                   	push   %ebx
f0103ba3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ba6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ba9:	89 c3                	mov    %eax,%ebx
f0103bab:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103bae:	eb 06                	jmp    f0103bb6 <strncmp+0x17>
		n--, p++, q++;
f0103bb0:	83 c0 01             	add    $0x1,%eax
f0103bb3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103bb6:	39 d8                	cmp    %ebx,%eax
f0103bb8:	74 15                	je     f0103bcf <strncmp+0x30>
f0103bba:	0f b6 08             	movzbl (%eax),%ecx
f0103bbd:	84 c9                	test   %cl,%cl
f0103bbf:	74 04                	je     f0103bc5 <strncmp+0x26>
f0103bc1:	3a 0a                	cmp    (%edx),%cl
f0103bc3:	74 eb                	je     f0103bb0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103bc5:	0f b6 00             	movzbl (%eax),%eax
f0103bc8:	0f b6 12             	movzbl (%edx),%edx
f0103bcb:	29 d0                	sub    %edx,%eax
f0103bcd:	eb 05                	jmp    f0103bd4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103bcf:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103bd4:	5b                   	pop    %ebx
f0103bd5:	5d                   	pop    %ebp
f0103bd6:	c3                   	ret    

f0103bd7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103bd7:	55                   	push   %ebp
f0103bd8:	89 e5                	mov    %esp,%ebp
f0103bda:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bdd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103be1:	eb 07                	jmp    f0103bea <strchr+0x13>
		if (*s == c)
f0103be3:	38 ca                	cmp    %cl,%dl
f0103be5:	74 0f                	je     f0103bf6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103be7:	83 c0 01             	add    $0x1,%eax
f0103bea:	0f b6 10             	movzbl (%eax),%edx
f0103bed:	84 d2                	test   %dl,%dl
f0103bef:	75 f2                	jne    f0103be3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103bf1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bf6:	5d                   	pop    %ebp
f0103bf7:	c3                   	ret    

f0103bf8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103bf8:	55                   	push   %ebp
f0103bf9:	89 e5                	mov    %esp,%ebp
f0103bfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bfe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c02:	eb 03                	jmp    f0103c07 <strfind+0xf>
f0103c04:	83 c0 01             	add    $0x1,%eax
f0103c07:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c0a:	38 ca                	cmp    %cl,%dl
f0103c0c:	74 04                	je     f0103c12 <strfind+0x1a>
f0103c0e:	84 d2                	test   %dl,%dl
f0103c10:	75 f2                	jne    f0103c04 <strfind+0xc>
			break;
	return (char *) s;
}
f0103c12:	5d                   	pop    %ebp
f0103c13:	c3                   	ret    

f0103c14 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c14:	55                   	push   %ebp
f0103c15:	89 e5                	mov    %esp,%ebp
f0103c17:	57                   	push   %edi
f0103c18:	56                   	push   %esi
f0103c19:	53                   	push   %ebx
f0103c1a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c1d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103c20:	85 c9                	test   %ecx,%ecx
f0103c22:	74 36                	je     f0103c5a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c24:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c2a:	75 28                	jne    f0103c54 <memset+0x40>
f0103c2c:	f6 c1 03             	test   $0x3,%cl
f0103c2f:	75 23                	jne    f0103c54 <memset+0x40>
		c &= 0xFF;
f0103c31:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c35:	89 d3                	mov    %edx,%ebx
f0103c37:	c1 e3 08             	shl    $0x8,%ebx
f0103c3a:	89 d6                	mov    %edx,%esi
f0103c3c:	c1 e6 18             	shl    $0x18,%esi
f0103c3f:	89 d0                	mov    %edx,%eax
f0103c41:	c1 e0 10             	shl    $0x10,%eax
f0103c44:	09 f0                	or     %esi,%eax
f0103c46:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103c48:	89 d8                	mov    %ebx,%eax
f0103c4a:	09 d0                	or     %edx,%eax
f0103c4c:	c1 e9 02             	shr    $0x2,%ecx
f0103c4f:	fc                   	cld    
f0103c50:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c52:	eb 06                	jmp    f0103c5a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103c54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c57:	fc                   	cld    
f0103c58:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103c5a:	89 f8                	mov    %edi,%eax
f0103c5c:	5b                   	pop    %ebx
f0103c5d:	5e                   	pop    %esi
f0103c5e:	5f                   	pop    %edi
f0103c5f:	5d                   	pop    %ebp
f0103c60:	c3                   	ret    

f0103c61 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c61:	55                   	push   %ebp
f0103c62:	89 e5                	mov    %esp,%ebp
f0103c64:	57                   	push   %edi
f0103c65:	56                   	push   %esi
f0103c66:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c69:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c6c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c6f:	39 c6                	cmp    %eax,%esi
f0103c71:	73 35                	jae    f0103ca8 <memmove+0x47>
f0103c73:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c76:	39 d0                	cmp    %edx,%eax
f0103c78:	73 2e                	jae    f0103ca8 <memmove+0x47>
		s += n;
		d += n;
f0103c7a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c7d:	89 d6                	mov    %edx,%esi
f0103c7f:	09 fe                	or     %edi,%esi
f0103c81:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c87:	75 13                	jne    f0103c9c <memmove+0x3b>
f0103c89:	f6 c1 03             	test   $0x3,%cl
f0103c8c:	75 0e                	jne    f0103c9c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103c8e:	83 ef 04             	sub    $0x4,%edi
f0103c91:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c94:	c1 e9 02             	shr    $0x2,%ecx
f0103c97:	fd                   	std    
f0103c98:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c9a:	eb 09                	jmp    f0103ca5 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103c9c:	83 ef 01             	sub    $0x1,%edi
f0103c9f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103ca2:	fd                   	std    
f0103ca3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103ca5:	fc                   	cld    
f0103ca6:	eb 1d                	jmp    f0103cc5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103ca8:	89 f2                	mov    %esi,%edx
f0103caa:	09 c2                	or     %eax,%edx
f0103cac:	f6 c2 03             	test   $0x3,%dl
f0103caf:	75 0f                	jne    f0103cc0 <memmove+0x5f>
f0103cb1:	f6 c1 03             	test   $0x3,%cl
f0103cb4:	75 0a                	jne    f0103cc0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103cb6:	c1 e9 02             	shr    $0x2,%ecx
f0103cb9:	89 c7                	mov    %eax,%edi
f0103cbb:	fc                   	cld    
f0103cbc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103cbe:	eb 05                	jmp    f0103cc5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103cc0:	89 c7                	mov    %eax,%edi
f0103cc2:	fc                   	cld    
f0103cc3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103cc5:	5e                   	pop    %esi
f0103cc6:	5f                   	pop    %edi
f0103cc7:	5d                   	pop    %ebp
f0103cc8:	c3                   	ret    

f0103cc9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103cc9:	55                   	push   %ebp
f0103cca:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103ccc:	ff 75 10             	pushl  0x10(%ebp)
f0103ccf:	ff 75 0c             	pushl  0xc(%ebp)
f0103cd2:	ff 75 08             	pushl  0x8(%ebp)
f0103cd5:	e8 87 ff ff ff       	call   f0103c61 <memmove>
}
f0103cda:	c9                   	leave  
f0103cdb:	c3                   	ret    

f0103cdc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103cdc:	55                   	push   %ebp
f0103cdd:	89 e5                	mov    %esp,%ebp
f0103cdf:	56                   	push   %esi
f0103ce0:	53                   	push   %ebx
f0103ce1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ce4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ce7:	89 c6                	mov    %eax,%esi
f0103ce9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103cec:	eb 1a                	jmp    f0103d08 <memcmp+0x2c>
		if (*s1 != *s2)
f0103cee:	0f b6 08             	movzbl (%eax),%ecx
f0103cf1:	0f b6 1a             	movzbl (%edx),%ebx
f0103cf4:	38 d9                	cmp    %bl,%cl
f0103cf6:	74 0a                	je     f0103d02 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103cf8:	0f b6 c1             	movzbl %cl,%eax
f0103cfb:	0f b6 db             	movzbl %bl,%ebx
f0103cfe:	29 d8                	sub    %ebx,%eax
f0103d00:	eb 0f                	jmp    f0103d11 <memcmp+0x35>
		s1++, s2++;
f0103d02:	83 c0 01             	add    $0x1,%eax
f0103d05:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d08:	39 f0                	cmp    %esi,%eax
f0103d0a:	75 e2                	jne    f0103cee <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d11:	5b                   	pop    %ebx
f0103d12:	5e                   	pop    %esi
f0103d13:	5d                   	pop    %ebp
f0103d14:	c3                   	ret    

f0103d15 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d15:	55                   	push   %ebp
f0103d16:	89 e5                	mov    %esp,%ebp
f0103d18:	53                   	push   %ebx
f0103d19:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d1c:	89 c1                	mov    %eax,%ecx
f0103d1e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d21:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d25:	eb 0a                	jmp    f0103d31 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d27:	0f b6 10             	movzbl (%eax),%edx
f0103d2a:	39 da                	cmp    %ebx,%edx
f0103d2c:	74 07                	je     f0103d35 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d2e:	83 c0 01             	add    $0x1,%eax
f0103d31:	39 c8                	cmp    %ecx,%eax
f0103d33:	72 f2                	jb     f0103d27 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d35:	5b                   	pop    %ebx
f0103d36:	5d                   	pop    %ebp
f0103d37:	c3                   	ret    

f0103d38 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d38:	55                   	push   %ebp
f0103d39:	89 e5                	mov    %esp,%ebp
f0103d3b:	57                   	push   %edi
f0103d3c:	56                   	push   %esi
f0103d3d:	53                   	push   %ebx
f0103d3e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d41:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d44:	eb 03                	jmp    f0103d49 <strtol+0x11>
		s++;
f0103d46:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d49:	0f b6 01             	movzbl (%ecx),%eax
f0103d4c:	3c 20                	cmp    $0x20,%al
f0103d4e:	74 f6                	je     f0103d46 <strtol+0xe>
f0103d50:	3c 09                	cmp    $0x9,%al
f0103d52:	74 f2                	je     f0103d46 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d54:	3c 2b                	cmp    $0x2b,%al
f0103d56:	75 0a                	jne    f0103d62 <strtol+0x2a>
		s++;
f0103d58:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103d5b:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d60:	eb 11                	jmp    f0103d73 <strtol+0x3b>
f0103d62:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103d67:	3c 2d                	cmp    $0x2d,%al
f0103d69:	75 08                	jne    f0103d73 <strtol+0x3b>
		s++, neg = 1;
f0103d6b:	83 c1 01             	add    $0x1,%ecx
f0103d6e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d73:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d79:	75 15                	jne    f0103d90 <strtol+0x58>
f0103d7b:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d7e:	75 10                	jne    f0103d90 <strtol+0x58>
f0103d80:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d84:	75 7c                	jne    f0103e02 <strtol+0xca>
		s += 2, base = 16;
f0103d86:	83 c1 02             	add    $0x2,%ecx
f0103d89:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d8e:	eb 16                	jmp    f0103da6 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103d90:	85 db                	test   %ebx,%ebx
f0103d92:	75 12                	jne    f0103da6 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d94:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d99:	80 39 30             	cmpb   $0x30,(%ecx)
f0103d9c:	75 08                	jne    f0103da6 <strtol+0x6e>
		s++, base = 8;
f0103d9e:	83 c1 01             	add    $0x1,%ecx
f0103da1:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103da6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103dab:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103dae:	0f b6 11             	movzbl (%ecx),%edx
f0103db1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103db4:	89 f3                	mov    %esi,%ebx
f0103db6:	80 fb 09             	cmp    $0x9,%bl
f0103db9:	77 08                	ja     f0103dc3 <strtol+0x8b>
			dig = *s - '0';
f0103dbb:	0f be d2             	movsbl %dl,%edx
f0103dbe:	83 ea 30             	sub    $0x30,%edx
f0103dc1:	eb 22                	jmp    f0103de5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103dc3:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103dc6:	89 f3                	mov    %esi,%ebx
f0103dc8:	80 fb 19             	cmp    $0x19,%bl
f0103dcb:	77 08                	ja     f0103dd5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103dcd:	0f be d2             	movsbl %dl,%edx
f0103dd0:	83 ea 57             	sub    $0x57,%edx
f0103dd3:	eb 10                	jmp    f0103de5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103dd5:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103dd8:	89 f3                	mov    %esi,%ebx
f0103dda:	80 fb 19             	cmp    $0x19,%bl
f0103ddd:	77 16                	ja     f0103df5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103ddf:	0f be d2             	movsbl %dl,%edx
f0103de2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103de5:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103de8:	7d 0b                	jge    f0103df5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103dea:	83 c1 01             	add    $0x1,%ecx
f0103ded:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103df1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103df3:	eb b9                	jmp    f0103dae <strtol+0x76>

	if (endptr)
f0103df5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103df9:	74 0d                	je     f0103e08 <strtol+0xd0>
		*endptr = (char *) s;
f0103dfb:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103dfe:	89 0e                	mov    %ecx,(%esi)
f0103e00:	eb 06                	jmp    f0103e08 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e02:	85 db                	test   %ebx,%ebx
f0103e04:	74 98                	je     f0103d9e <strtol+0x66>
f0103e06:	eb 9e                	jmp    f0103da6 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103e08:	89 c2                	mov    %eax,%edx
f0103e0a:	f7 da                	neg    %edx
f0103e0c:	85 ff                	test   %edi,%edi
f0103e0e:	0f 45 c2             	cmovne %edx,%eax
}
f0103e11:	5b                   	pop    %ebx
f0103e12:	5e                   	pop    %esi
f0103e13:	5f                   	pop    %edi
f0103e14:	5d                   	pop    %ebp
f0103e15:	c3                   	ret    
f0103e16:	66 90                	xchg   %ax,%ax
f0103e18:	66 90                	xchg   %ax,%ax
f0103e1a:	66 90                	xchg   %ax,%ax
f0103e1c:	66 90                	xchg   %ax,%ax
f0103e1e:	66 90                	xchg   %ax,%ax

f0103e20 <__udivdi3>:
f0103e20:	55                   	push   %ebp
f0103e21:	57                   	push   %edi
f0103e22:	56                   	push   %esi
f0103e23:	53                   	push   %ebx
f0103e24:	83 ec 1c             	sub    $0x1c,%esp
f0103e27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103e2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103e2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103e33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103e37:	85 f6                	test   %esi,%esi
f0103e39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103e3d:	89 ca                	mov    %ecx,%edx
f0103e3f:	89 f8                	mov    %edi,%eax
f0103e41:	75 3d                	jne    f0103e80 <__udivdi3+0x60>
f0103e43:	39 cf                	cmp    %ecx,%edi
f0103e45:	0f 87 c5 00 00 00    	ja     f0103f10 <__udivdi3+0xf0>
f0103e4b:	85 ff                	test   %edi,%edi
f0103e4d:	89 fd                	mov    %edi,%ebp
f0103e4f:	75 0b                	jne    f0103e5c <__udivdi3+0x3c>
f0103e51:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e56:	31 d2                	xor    %edx,%edx
f0103e58:	f7 f7                	div    %edi
f0103e5a:	89 c5                	mov    %eax,%ebp
f0103e5c:	89 c8                	mov    %ecx,%eax
f0103e5e:	31 d2                	xor    %edx,%edx
f0103e60:	f7 f5                	div    %ebp
f0103e62:	89 c1                	mov    %eax,%ecx
f0103e64:	89 d8                	mov    %ebx,%eax
f0103e66:	89 cf                	mov    %ecx,%edi
f0103e68:	f7 f5                	div    %ebp
f0103e6a:	89 c3                	mov    %eax,%ebx
f0103e6c:	89 d8                	mov    %ebx,%eax
f0103e6e:	89 fa                	mov    %edi,%edx
f0103e70:	83 c4 1c             	add    $0x1c,%esp
f0103e73:	5b                   	pop    %ebx
f0103e74:	5e                   	pop    %esi
f0103e75:	5f                   	pop    %edi
f0103e76:	5d                   	pop    %ebp
f0103e77:	c3                   	ret    
f0103e78:	90                   	nop
f0103e79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e80:	39 ce                	cmp    %ecx,%esi
f0103e82:	77 74                	ja     f0103ef8 <__udivdi3+0xd8>
f0103e84:	0f bd fe             	bsr    %esi,%edi
f0103e87:	83 f7 1f             	xor    $0x1f,%edi
f0103e8a:	0f 84 98 00 00 00    	je     f0103f28 <__udivdi3+0x108>
f0103e90:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103e95:	89 f9                	mov    %edi,%ecx
f0103e97:	89 c5                	mov    %eax,%ebp
f0103e99:	29 fb                	sub    %edi,%ebx
f0103e9b:	d3 e6                	shl    %cl,%esi
f0103e9d:	89 d9                	mov    %ebx,%ecx
f0103e9f:	d3 ed                	shr    %cl,%ebp
f0103ea1:	89 f9                	mov    %edi,%ecx
f0103ea3:	d3 e0                	shl    %cl,%eax
f0103ea5:	09 ee                	or     %ebp,%esi
f0103ea7:	89 d9                	mov    %ebx,%ecx
f0103ea9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ead:	89 d5                	mov    %edx,%ebp
f0103eaf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103eb3:	d3 ed                	shr    %cl,%ebp
f0103eb5:	89 f9                	mov    %edi,%ecx
f0103eb7:	d3 e2                	shl    %cl,%edx
f0103eb9:	89 d9                	mov    %ebx,%ecx
f0103ebb:	d3 e8                	shr    %cl,%eax
f0103ebd:	09 c2                	or     %eax,%edx
f0103ebf:	89 d0                	mov    %edx,%eax
f0103ec1:	89 ea                	mov    %ebp,%edx
f0103ec3:	f7 f6                	div    %esi
f0103ec5:	89 d5                	mov    %edx,%ebp
f0103ec7:	89 c3                	mov    %eax,%ebx
f0103ec9:	f7 64 24 0c          	mull   0xc(%esp)
f0103ecd:	39 d5                	cmp    %edx,%ebp
f0103ecf:	72 10                	jb     f0103ee1 <__udivdi3+0xc1>
f0103ed1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ed5:	89 f9                	mov    %edi,%ecx
f0103ed7:	d3 e6                	shl    %cl,%esi
f0103ed9:	39 c6                	cmp    %eax,%esi
f0103edb:	73 07                	jae    f0103ee4 <__udivdi3+0xc4>
f0103edd:	39 d5                	cmp    %edx,%ebp
f0103edf:	75 03                	jne    f0103ee4 <__udivdi3+0xc4>
f0103ee1:	83 eb 01             	sub    $0x1,%ebx
f0103ee4:	31 ff                	xor    %edi,%edi
f0103ee6:	89 d8                	mov    %ebx,%eax
f0103ee8:	89 fa                	mov    %edi,%edx
f0103eea:	83 c4 1c             	add    $0x1c,%esp
f0103eed:	5b                   	pop    %ebx
f0103eee:	5e                   	pop    %esi
f0103eef:	5f                   	pop    %edi
f0103ef0:	5d                   	pop    %ebp
f0103ef1:	c3                   	ret    
f0103ef2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ef8:	31 ff                	xor    %edi,%edi
f0103efa:	31 db                	xor    %ebx,%ebx
f0103efc:	89 d8                	mov    %ebx,%eax
f0103efe:	89 fa                	mov    %edi,%edx
f0103f00:	83 c4 1c             	add    $0x1c,%esp
f0103f03:	5b                   	pop    %ebx
f0103f04:	5e                   	pop    %esi
f0103f05:	5f                   	pop    %edi
f0103f06:	5d                   	pop    %ebp
f0103f07:	c3                   	ret    
f0103f08:	90                   	nop
f0103f09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f10:	89 d8                	mov    %ebx,%eax
f0103f12:	f7 f7                	div    %edi
f0103f14:	31 ff                	xor    %edi,%edi
f0103f16:	89 c3                	mov    %eax,%ebx
f0103f18:	89 d8                	mov    %ebx,%eax
f0103f1a:	89 fa                	mov    %edi,%edx
f0103f1c:	83 c4 1c             	add    $0x1c,%esp
f0103f1f:	5b                   	pop    %ebx
f0103f20:	5e                   	pop    %esi
f0103f21:	5f                   	pop    %edi
f0103f22:	5d                   	pop    %ebp
f0103f23:	c3                   	ret    
f0103f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f28:	39 ce                	cmp    %ecx,%esi
f0103f2a:	72 0c                	jb     f0103f38 <__udivdi3+0x118>
f0103f2c:	31 db                	xor    %ebx,%ebx
f0103f2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103f32:	0f 87 34 ff ff ff    	ja     f0103e6c <__udivdi3+0x4c>
f0103f38:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103f3d:	e9 2a ff ff ff       	jmp    f0103e6c <__udivdi3+0x4c>
f0103f42:	66 90                	xchg   %ax,%ax
f0103f44:	66 90                	xchg   %ax,%ax
f0103f46:	66 90                	xchg   %ax,%ax
f0103f48:	66 90                	xchg   %ax,%ax
f0103f4a:	66 90                	xchg   %ax,%ax
f0103f4c:	66 90                	xchg   %ax,%ax
f0103f4e:	66 90                	xchg   %ax,%ax

f0103f50 <__umoddi3>:
f0103f50:	55                   	push   %ebp
f0103f51:	57                   	push   %edi
f0103f52:	56                   	push   %esi
f0103f53:	53                   	push   %ebx
f0103f54:	83 ec 1c             	sub    $0x1c,%esp
f0103f57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103f5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103f5f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103f63:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103f67:	85 d2                	test   %edx,%edx
f0103f69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103f6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f71:	89 f3                	mov    %esi,%ebx
f0103f73:	89 3c 24             	mov    %edi,(%esp)
f0103f76:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103f7a:	75 1c                	jne    f0103f98 <__umoddi3+0x48>
f0103f7c:	39 f7                	cmp    %esi,%edi
f0103f7e:	76 50                	jbe    f0103fd0 <__umoddi3+0x80>
f0103f80:	89 c8                	mov    %ecx,%eax
f0103f82:	89 f2                	mov    %esi,%edx
f0103f84:	f7 f7                	div    %edi
f0103f86:	89 d0                	mov    %edx,%eax
f0103f88:	31 d2                	xor    %edx,%edx
f0103f8a:	83 c4 1c             	add    $0x1c,%esp
f0103f8d:	5b                   	pop    %ebx
f0103f8e:	5e                   	pop    %esi
f0103f8f:	5f                   	pop    %edi
f0103f90:	5d                   	pop    %ebp
f0103f91:	c3                   	ret    
f0103f92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f98:	39 f2                	cmp    %esi,%edx
f0103f9a:	89 d0                	mov    %edx,%eax
f0103f9c:	77 52                	ja     f0103ff0 <__umoddi3+0xa0>
f0103f9e:	0f bd ea             	bsr    %edx,%ebp
f0103fa1:	83 f5 1f             	xor    $0x1f,%ebp
f0103fa4:	75 5a                	jne    f0104000 <__umoddi3+0xb0>
f0103fa6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103faa:	0f 82 e0 00 00 00    	jb     f0104090 <__umoddi3+0x140>
f0103fb0:	39 0c 24             	cmp    %ecx,(%esp)
f0103fb3:	0f 86 d7 00 00 00    	jbe    f0104090 <__umoddi3+0x140>
f0103fb9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103fbd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103fc1:	83 c4 1c             	add    $0x1c,%esp
f0103fc4:	5b                   	pop    %ebx
f0103fc5:	5e                   	pop    %esi
f0103fc6:	5f                   	pop    %edi
f0103fc7:	5d                   	pop    %ebp
f0103fc8:	c3                   	ret    
f0103fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fd0:	85 ff                	test   %edi,%edi
f0103fd2:	89 fd                	mov    %edi,%ebp
f0103fd4:	75 0b                	jne    f0103fe1 <__umoddi3+0x91>
f0103fd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fdb:	31 d2                	xor    %edx,%edx
f0103fdd:	f7 f7                	div    %edi
f0103fdf:	89 c5                	mov    %eax,%ebp
f0103fe1:	89 f0                	mov    %esi,%eax
f0103fe3:	31 d2                	xor    %edx,%edx
f0103fe5:	f7 f5                	div    %ebp
f0103fe7:	89 c8                	mov    %ecx,%eax
f0103fe9:	f7 f5                	div    %ebp
f0103feb:	89 d0                	mov    %edx,%eax
f0103fed:	eb 99                	jmp    f0103f88 <__umoddi3+0x38>
f0103fef:	90                   	nop
f0103ff0:	89 c8                	mov    %ecx,%eax
f0103ff2:	89 f2                	mov    %esi,%edx
f0103ff4:	83 c4 1c             	add    $0x1c,%esp
f0103ff7:	5b                   	pop    %ebx
f0103ff8:	5e                   	pop    %esi
f0103ff9:	5f                   	pop    %edi
f0103ffa:	5d                   	pop    %ebp
f0103ffb:	c3                   	ret    
f0103ffc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104000:	8b 34 24             	mov    (%esp),%esi
f0104003:	bf 20 00 00 00       	mov    $0x20,%edi
f0104008:	89 e9                	mov    %ebp,%ecx
f010400a:	29 ef                	sub    %ebp,%edi
f010400c:	d3 e0                	shl    %cl,%eax
f010400e:	89 f9                	mov    %edi,%ecx
f0104010:	89 f2                	mov    %esi,%edx
f0104012:	d3 ea                	shr    %cl,%edx
f0104014:	89 e9                	mov    %ebp,%ecx
f0104016:	09 c2                	or     %eax,%edx
f0104018:	89 d8                	mov    %ebx,%eax
f010401a:	89 14 24             	mov    %edx,(%esp)
f010401d:	89 f2                	mov    %esi,%edx
f010401f:	d3 e2                	shl    %cl,%edx
f0104021:	89 f9                	mov    %edi,%ecx
f0104023:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104027:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010402b:	d3 e8                	shr    %cl,%eax
f010402d:	89 e9                	mov    %ebp,%ecx
f010402f:	89 c6                	mov    %eax,%esi
f0104031:	d3 e3                	shl    %cl,%ebx
f0104033:	89 f9                	mov    %edi,%ecx
f0104035:	89 d0                	mov    %edx,%eax
f0104037:	d3 e8                	shr    %cl,%eax
f0104039:	89 e9                	mov    %ebp,%ecx
f010403b:	09 d8                	or     %ebx,%eax
f010403d:	89 d3                	mov    %edx,%ebx
f010403f:	89 f2                	mov    %esi,%edx
f0104041:	f7 34 24             	divl   (%esp)
f0104044:	89 d6                	mov    %edx,%esi
f0104046:	d3 e3                	shl    %cl,%ebx
f0104048:	f7 64 24 04          	mull   0x4(%esp)
f010404c:	39 d6                	cmp    %edx,%esi
f010404e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104052:	89 d1                	mov    %edx,%ecx
f0104054:	89 c3                	mov    %eax,%ebx
f0104056:	72 08                	jb     f0104060 <__umoddi3+0x110>
f0104058:	75 11                	jne    f010406b <__umoddi3+0x11b>
f010405a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010405e:	73 0b                	jae    f010406b <__umoddi3+0x11b>
f0104060:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104064:	1b 14 24             	sbb    (%esp),%edx
f0104067:	89 d1                	mov    %edx,%ecx
f0104069:	89 c3                	mov    %eax,%ebx
f010406b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010406f:	29 da                	sub    %ebx,%edx
f0104071:	19 ce                	sbb    %ecx,%esi
f0104073:	89 f9                	mov    %edi,%ecx
f0104075:	89 f0                	mov    %esi,%eax
f0104077:	d3 e0                	shl    %cl,%eax
f0104079:	89 e9                	mov    %ebp,%ecx
f010407b:	d3 ea                	shr    %cl,%edx
f010407d:	89 e9                	mov    %ebp,%ecx
f010407f:	d3 ee                	shr    %cl,%esi
f0104081:	09 d0                	or     %edx,%eax
f0104083:	89 f2                	mov    %esi,%edx
f0104085:	83 c4 1c             	add    $0x1c,%esp
f0104088:	5b                   	pop    %ebx
f0104089:	5e                   	pop    %esi
f010408a:	5f                   	pop    %edi
f010408b:	5d                   	pop    %ebp
f010408c:	c3                   	ret    
f010408d:	8d 76 00             	lea    0x0(%esi),%esi
f0104090:	29 f9                	sub    %edi,%ecx
f0104092:	19 d6                	sbb    %edx,%esi
f0104094:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104098:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010409c:	e9 18 ff ff ff       	jmp    f0103fb9 <__umoddi3+0x69>
