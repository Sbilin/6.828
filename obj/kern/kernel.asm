
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
f0100058:	e8 fe 3a 00 00       	call   f0103b5b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 40 10 f0       	push   $0xf0104000
f010006f:	e8 55 2c 00 00       	call   f0102cc9 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 26 0f 00 00       	call   f0100f9f <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 61 27 00 00       	call   f01027df <env_init>
	trap_init();
f010007e:	e8 b7 2c 00 00       	call   f0102d3a <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 d0 28 00 00       	call   f0102962 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010009b:	e8 87 2b 00 00       	call   f0102c27 <env_run>

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
f01000c5:	68 1b 40 10 f0       	push   $0xf010401b
f01000ca:	e8 fa 2b 00 00       	call   f0102cc9 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 ca 2b 00 00       	call   f0102ca3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 fe 4e 10 f0 	movl   $0xf0104efe,(%esp)
f01000e0:	e8 e4 2b 00 00       	call   f0102cc9 <cprintf>
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
f0100107:	68 33 40 10 f0       	push   $0xf0104033
f010010c:	e8 b8 2b 00 00       	call   f0102cc9 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 86 2b 00 00       	call   f0102ca3 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 fe 4e 10 f0 	movl   $0xf0104efe,(%esp)
f0100124:	e8 a0 2b 00 00       	call   f0102cc9 <cprintf>
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
f01001e3:	0f b6 82 a0 41 10 f0 	movzbl -0xfefbe60(%edx),%eax
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
f010021f:	0f b6 82 a0 41 10 f0 	movzbl -0xfefbe60(%edx),%eax
f0100226:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f010022c:	0f b6 8a a0 40 10 f0 	movzbl -0xfefbf60(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 80 40 10 f0 	mov    -0xfefbf80(,%ecx,4),%ecx
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
f010027d:	68 4d 40 10 f0       	push   $0xf010404d
f0100282:	e8 42 2a 00 00       	call   f0102cc9 <cprintf>
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
f0100431:	e8 72 37 00 00       	call   f0103ba8 <memmove>
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
f0100600:	68 59 40 10 f0       	push   $0xf0104059
f0100605:	e8 bf 26 00 00       	call   f0102cc9 <cprintf>
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
f0100646:	68 a0 42 10 f0       	push   $0xf01042a0
f010064b:	68 be 42 10 f0       	push   $0xf01042be
f0100650:	68 c3 42 10 f0       	push   $0xf01042c3
f0100655:	e8 6f 26 00 00       	call   f0102cc9 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 2c 43 10 f0       	push   $0xf010432c
f0100662:	68 cc 42 10 f0       	push   $0xf01042cc
f0100667:	68 c3 42 10 f0       	push   $0xf01042c3
f010066c:	e8 58 26 00 00       	call   f0102cc9 <cprintf>
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
f010067e:	68 d5 42 10 f0       	push   $0xf01042d5
f0100683:	e8 41 26 00 00       	call   f0102cc9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 54 43 10 f0       	push   $0xf0104354
f0100695:	e8 2f 26 00 00       	call   f0102cc9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 7c 43 10 f0       	push   $0xf010437c
f01006ac:	e8 18 26 00 00       	call   f0102cc9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 e1 3f 10 00       	push   $0x103fe1
f01006b9:	68 e1 3f 10 f0       	push   $0xf0103fe1
f01006be:	68 a0 43 10 f0       	push   $0xf01043a0
f01006c3:	e8 01 26 00 00       	call   f0102cc9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 ee bb 17 00       	push   $0x17bbee
f01006d0:	68 ee bb 17 f0       	push   $0xf017bbee
f01006d5:	68 c4 43 10 f0       	push   $0xf01043c4
f01006da:	e8 ea 25 00 00       	call   f0102cc9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 10 cb 17 00       	push   $0x17cb10
f01006e7:	68 10 cb 17 f0       	push   $0xf017cb10
f01006ec:	68 e8 43 10 f0       	push   $0xf01043e8
f01006f1:	e8 d3 25 00 00       	call   f0102cc9 <cprintf>
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
f0100717:	68 0c 44 10 f0       	push   $0xf010440c
f010071c:	e8 a8 25 00 00       	call   f0102cc9 <cprintf>
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
f010073b:	68 38 44 10 f0       	push   $0xf0104438
f0100740:	e8 84 25 00 00       	call   f0102cc9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100745:	c7 04 24 5c 44 10 f0 	movl   $0xf010445c,(%esp)
f010074c:	e8 78 25 00 00       	call   f0102cc9 <cprintf>

	if (tf != NULL)
f0100751:	83 c4 10             	add    $0x10,%esp
f0100754:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100758:	74 0e                	je     f0100768 <monitor+0x36>
		print_trapframe(tf);
f010075a:	83 ec 0c             	sub    $0xc,%esp
f010075d:	ff 75 08             	pushl  0x8(%ebp)
f0100760:	e8 6d 26 00 00       	call   f0102dd2 <print_trapframe>
f0100765:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100768:	83 ec 0c             	sub    $0xc,%esp
f010076b:	68 ee 42 10 f0       	push   $0xf01042ee
f0100770:	e8 8f 31 00 00       	call   f0103904 <readline>
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
f01007a4:	68 f2 42 10 f0       	push   $0xf01042f2
f01007a9:	e8 70 33 00 00       	call   f0103b1e <strchr>
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
f01007c4:	68 f7 42 10 f0       	push   $0xf01042f7
f01007c9:	e8 fb 24 00 00       	call   f0102cc9 <cprintf>
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
f01007ed:	68 f2 42 10 f0       	push   $0xf01042f2
f01007f2:	e8 27 33 00 00       	call   f0103b1e <strchr>
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
f0100813:	68 be 42 10 f0       	push   $0xf01042be
f0100818:	ff 75 a8             	pushl  -0x58(%ebp)
f010081b:	e8 a0 32 00 00       	call   f0103ac0 <strcmp>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 1e                	je     f0100845 <monitor+0x113>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	68 cc 42 10 f0       	push   $0xf01042cc
f010082f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100832:	e8 89 32 00 00       	call   f0103ac0 <strcmp>
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
f010085a:	ff 14 85 8c 44 10 f0 	call   *-0xfefbb74(,%eax,4)
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
f0100873:	68 14 43 10 f0       	push   $0xf0104314
f0100878:	e8 4c 24 00 00       	call   f0102cc9 <cprintf>
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
f01008d0:	e8 8d 23 00 00       	call   f0102c62 <mc146818_read>
f01008d5:	89 c6                	mov    %eax,%esi
f01008d7:	83 c3 01             	add    $0x1,%ebx
f01008da:	89 1c 24             	mov    %ebx,(%esp)
f01008dd:	e8 80 23 00 00       	call   f0102c62 <mc146818_read>
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
f0100913:	68 9c 44 10 f0       	push   $0xf010449c
f0100918:	68 1e 03 00 00       	push   $0x31e
f010091d:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f010096b:	68 c0 44 10 f0       	push   $0xf01044c0
f0100970:	68 5c 02 00 00       	push   $0x25c
f0100975:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f01009fa:	68 9c 44 10 f0       	push   $0xf010449c
f01009ff:	6a 56                	push   $0x56
f0100a01:	68 59 4c 10 f0       	push   $0xf0104c59
f0100a06:	e8 95 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a0b:	83 ec 04             	sub    $0x4,%esp
f0100a0e:	68 80 00 00 00       	push   $0x80
f0100a13:	68 97 00 00 00       	push   $0x97
f0100a18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a1d:	50                   	push   %eax
f0100a1e:	e8 38 31 00 00       	call   f0103b5b <memset>
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
f0100a64:	68 67 4c 10 f0       	push   $0xf0104c67
f0100a69:	68 73 4c 10 f0       	push   $0xf0104c73
f0100a6e:	68 76 02 00 00       	push   $0x276
f0100a73:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100a78:	e8 23 f6 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100a7d:	39 fa                	cmp    %edi,%edx
f0100a7f:	72 19                	jb     f0100a9a <check_page_free_list+0x148>
f0100a81:	68 88 4c 10 f0       	push   $0xf0104c88
f0100a86:	68 73 4c 10 f0       	push   $0xf0104c73
f0100a8b:	68 77 02 00 00       	push   $0x277
f0100a90:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100a95:	e8 06 f6 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a9a:	89 d0                	mov    %edx,%eax
f0100a9c:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a9f:	a8 07                	test   $0x7,%al
f0100aa1:	74 19                	je     f0100abc <check_page_free_list+0x16a>
f0100aa3:	68 e4 44 10 f0       	push   $0xf01044e4
f0100aa8:	68 73 4c 10 f0       	push   $0xf0104c73
f0100aad:	68 78 02 00 00       	push   $0x278
f0100ab2:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100ac6:	68 9c 4c 10 f0       	push   $0xf0104c9c
f0100acb:	68 73 4c 10 f0       	push   $0xf0104c73
f0100ad0:	68 7b 02 00 00       	push   $0x27b
f0100ad5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100ada:	e8 c1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100adf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ae4:	75 19                	jne    f0100aff <check_page_free_list+0x1ad>
f0100ae6:	68 ad 4c 10 f0       	push   $0xf0104cad
f0100aeb:	68 73 4c 10 f0       	push   $0xf0104c73
f0100af0:	68 7c 02 00 00       	push   $0x27c
f0100af5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100afa:	e8 a1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100aff:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b04:	75 19                	jne    f0100b1f <check_page_free_list+0x1cd>
f0100b06:	68 18 45 10 f0       	push   $0xf0104518
f0100b0b:	68 73 4c 10 f0       	push   $0xf0104c73
f0100b10:	68 7d 02 00 00       	push   $0x27d
f0100b15:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100b1a:	e8 81 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b1f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b24:	75 19                	jne    f0100b3f <check_page_free_list+0x1ed>
f0100b26:	68 c6 4c 10 f0       	push   $0xf0104cc6
f0100b2b:	68 73 4c 10 f0       	push   $0xf0104c73
f0100b30:	68 7e 02 00 00       	push   $0x27e
f0100b35:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100b51:	68 9c 44 10 f0       	push   $0xf010449c
f0100b56:	6a 56                	push   $0x56
f0100b58:	68 59 4c 10 f0       	push   $0xf0104c59
f0100b5d:	e8 3e f5 ff ff       	call   f01000a0 <_panic>
f0100b62:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b67:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b6a:	76 1e                	jbe    f0100b8a <check_page_free_list+0x238>
f0100b6c:	68 3c 45 10 f0       	push   $0xf010453c
f0100b71:	68 73 4c 10 f0       	push   $0xf0104c73
f0100b76:	68 7f 02 00 00       	push   $0x27f
f0100b7b:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100b9f:	68 e0 4c 10 f0       	push   $0xf0104ce0
f0100ba4:	68 73 4c 10 f0       	push   $0xf0104c73
f0100ba9:	68 87 02 00 00       	push   $0x287
f0100bae:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0100bb3:	e8 e8 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bb8:	85 db                	test   %ebx,%ebx
f0100bba:	7f 42                	jg     f0100bfe <check_page_free_list+0x2ac>
f0100bbc:	68 f2 4c 10 f0       	push   $0xf0104cf2
f0100bc1:	68 73 4c 10 f0       	push   $0xf0104c73
f0100bc6:	68 88 02 00 00       	push   $0x288
f0100bcb:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100c27:	68 84 45 10 f0       	push   $0xf0104584
f0100c2c:	68 11 01 00 00       	push   $0x111
f0100c31:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100d0f:	68 9c 44 10 f0       	push   $0xf010449c
f0100d14:	6a 56                	push   $0x56
f0100d16:	68 59 4c 10 f0       	push   $0xf0104c59
f0100d1b:	e8 80 f3 ff ff       	call   f01000a0 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100d20:	83 ec 04             	sub    $0x4,%esp
f0100d23:	68 00 10 00 00       	push   $0x1000
f0100d28:	6a 00                	push   $0x0
f0100d2a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 26 2e 00 00       	call   f0103b5b <memset>
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
f0100d54:	68 a8 45 10 f0       	push   $0xf01045a8
f0100d59:	68 73 4c 10 f0       	push   $0xf0104c73
f0100d5e:	68 4d 01 00 00       	push   $0x14d
f0100d63:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100e06:	68 9c 44 10 f0       	push   $0xf010449c
f0100e0b:	68 88 01 00 00       	push   $0x188
f0100e10:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0100eb8:	68 d0 45 10 f0       	push   $0xf01045d0
f0100ebd:	6a 4f                	push   $0x4f
f0100ebf:	68 59 4c 10 f0       	push   $0xf0104c59
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
f0100ff5:	68 f0 45 10 f0       	push   $0xf01045f0
f0100ffa:	e8 ca 1c 00 00       	call   f0102cc9 <cprintf>
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
f0101019:	e8 3d 2b 00 00       	call   f0103b5b <memset>
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
f010102e:	68 84 45 10 f0       	push   $0xf0104584
f0101033:	68 90 00 00 00       	push   $0x90
f0101038:	68 4d 4c 10 f0       	push   $0xf0104c4d
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
f0101077:	e8 df 2a 00 00       	call   f0103b5b <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=boot_alloc(NENV*sizeof(struct Env));
f010107c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101081:	e8 07 f8 ff ff       	call   f010088d <boot_alloc>
f0101086:	a3 44 be 17 f0       	mov    %eax,0xf017be44
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010108b:	e8 76 fb ff ff       	call   f0100c06 <page_init>
	check_page_free_list(1);
f0101090:	b8 01 00 00 00       	mov    $0x1,%eax
f0101095:	e8 b8 f8 ff ff       	call   f0100952 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010109a:	83 c4 10             	add    $0x10,%esp
f010109d:	83 3d 0c cb 17 f0 00 	cmpl   $0x0,0xf017cb0c
f01010a4:	75 17                	jne    f01010bd <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f01010a6:	83 ec 04             	sub    $0x4,%esp
f01010a9:	68 03 4d 10 f0       	push   $0xf0104d03
f01010ae:	68 99 02 00 00       	push   $0x299
f01010b3:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01010b8:	e8 e3 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010bd:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f01010c2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010c7:	eb 05                	jmp    f01010ce <mem_init+0x12f>
		++nfree;
f01010c9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010cc:	8b 00                	mov    (%eax),%eax
f01010ce:	85 c0                	test   %eax,%eax
f01010d0:	75 f7                	jne    f01010c9 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010d2:	83 ec 0c             	sub    $0xc,%esp
f01010d5:	6a 00                	push   $0x0
f01010d7:	e8 f3 fb ff ff       	call   f0100ccf <page_alloc>
f01010dc:	89 c7                	mov    %eax,%edi
f01010de:	83 c4 10             	add    $0x10,%esp
f01010e1:	85 c0                	test   %eax,%eax
f01010e3:	75 19                	jne    f01010fe <mem_init+0x15f>
f01010e5:	68 1e 4d 10 f0       	push   $0xf0104d1e
f01010ea:	68 73 4c 10 f0       	push   $0xf0104c73
f01010ef:	68 a1 02 00 00       	push   $0x2a1
f01010f4:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01010f9:	e8 a2 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01010fe:	83 ec 0c             	sub    $0xc,%esp
f0101101:	6a 00                	push   $0x0
f0101103:	e8 c7 fb ff ff       	call   f0100ccf <page_alloc>
f0101108:	89 c6                	mov    %eax,%esi
f010110a:	83 c4 10             	add    $0x10,%esp
f010110d:	85 c0                	test   %eax,%eax
f010110f:	75 19                	jne    f010112a <mem_init+0x18b>
f0101111:	68 34 4d 10 f0       	push   $0xf0104d34
f0101116:	68 73 4c 10 f0       	push   $0xf0104c73
f010111b:	68 a2 02 00 00       	push   $0x2a2
f0101120:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101125:	e8 76 ef ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010112a:	83 ec 0c             	sub    $0xc,%esp
f010112d:	6a 00                	push   $0x0
f010112f:	e8 9b fb ff ff       	call   f0100ccf <page_alloc>
f0101134:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101137:	83 c4 10             	add    $0x10,%esp
f010113a:	85 c0                	test   %eax,%eax
f010113c:	75 19                	jne    f0101157 <mem_init+0x1b8>
f010113e:	68 4a 4d 10 f0       	push   $0xf0104d4a
f0101143:	68 73 4c 10 f0       	push   $0xf0104c73
f0101148:	68 a3 02 00 00       	push   $0x2a3
f010114d:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101152:	e8 49 ef ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101157:	39 f7                	cmp    %esi,%edi
f0101159:	75 19                	jne    f0101174 <mem_init+0x1d5>
f010115b:	68 60 4d 10 f0       	push   $0xf0104d60
f0101160:	68 73 4c 10 f0       	push   $0xf0104c73
f0101165:	68 a6 02 00 00       	push   $0x2a6
f010116a:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010116f:	e8 2c ef ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101174:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101177:	39 c6                	cmp    %eax,%esi
f0101179:	74 04                	je     f010117f <mem_init+0x1e0>
f010117b:	39 c7                	cmp    %eax,%edi
f010117d:	75 19                	jne    f0101198 <mem_init+0x1f9>
f010117f:	68 2c 46 10 f0       	push   $0xf010462c
f0101184:	68 73 4c 10 f0       	push   $0xf0104c73
f0101189:	68 a7 02 00 00       	push   $0x2a7
f010118e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101193:	e8 08 ef ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101198:	8b 0d 0c cb 17 f0    	mov    0xf017cb0c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010119e:	8b 15 04 cb 17 f0    	mov    0xf017cb04,%edx
f01011a4:	c1 e2 0c             	shl    $0xc,%edx
f01011a7:	89 f8                	mov    %edi,%eax
f01011a9:	29 c8                	sub    %ecx,%eax
f01011ab:	c1 f8 03             	sar    $0x3,%eax
f01011ae:	c1 e0 0c             	shl    $0xc,%eax
f01011b1:	39 d0                	cmp    %edx,%eax
f01011b3:	72 19                	jb     f01011ce <mem_init+0x22f>
f01011b5:	68 72 4d 10 f0       	push   $0xf0104d72
f01011ba:	68 73 4c 10 f0       	push   $0xf0104c73
f01011bf:	68 a8 02 00 00       	push   $0x2a8
f01011c4:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01011c9:	e8 d2 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011ce:	89 f0                	mov    %esi,%eax
f01011d0:	29 c8                	sub    %ecx,%eax
f01011d2:	c1 f8 03             	sar    $0x3,%eax
f01011d5:	c1 e0 0c             	shl    $0xc,%eax
f01011d8:	39 c2                	cmp    %eax,%edx
f01011da:	77 19                	ja     f01011f5 <mem_init+0x256>
f01011dc:	68 8f 4d 10 f0       	push   $0xf0104d8f
f01011e1:	68 73 4c 10 f0       	push   $0xf0104c73
f01011e6:	68 a9 02 00 00       	push   $0x2a9
f01011eb:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01011f0:	e8 ab ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01011f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011f8:	29 c8                	sub    %ecx,%eax
f01011fa:	c1 f8 03             	sar    $0x3,%eax
f01011fd:	c1 e0 0c             	shl    $0xc,%eax
f0101200:	39 c2                	cmp    %eax,%edx
f0101202:	77 19                	ja     f010121d <mem_init+0x27e>
f0101204:	68 ac 4d 10 f0       	push   $0xf0104dac
f0101209:	68 73 4c 10 f0       	push   $0xf0104c73
f010120e:	68 aa 02 00 00       	push   $0x2aa
f0101213:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101218:	e8 83 ee ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010121d:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101222:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101225:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f010122c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010122f:	83 ec 0c             	sub    $0xc,%esp
f0101232:	6a 00                	push   $0x0
f0101234:	e8 96 fa ff ff       	call   f0100ccf <page_alloc>
f0101239:	83 c4 10             	add    $0x10,%esp
f010123c:	85 c0                	test   %eax,%eax
f010123e:	74 19                	je     f0101259 <mem_init+0x2ba>
f0101240:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0101245:	68 73 4c 10 f0       	push   $0xf0104c73
f010124a:	68 b1 02 00 00       	push   $0x2b1
f010124f:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101254:	e8 47 ee ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101259:	83 ec 0c             	sub    $0xc,%esp
f010125c:	57                   	push   %edi
f010125d:	e8 dd fa ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101262:	89 34 24             	mov    %esi,(%esp)
f0101265:	e8 d5 fa ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f010126a:	83 c4 04             	add    $0x4,%esp
f010126d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101270:	e8 ca fa ff ff       	call   f0100d3f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101275:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010127c:	e8 4e fa ff ff       	call   f0100ccf <page_alloc>
f0101281:	89 c6                	mov    %eax,%esi
f0101283:	83 c4 10             	add    $0x10,%esp
f0101286:	85 c0                	test   %eax,%eax
f0101288:	75 19                	jne    f01012a3 <mem_init+0x304>
f010128a:	68 1e 4d 10 f0       	push   $0xf0104d1e
f010128f:	68 73 4c 10 f0       	push   $0xf0104c73
f0101294:	68 b8 02 00 00       	push   $0x2b8
f0101299:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010129e:	e8 fd ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	6a 00                	push   $0x0
f01012a8:	e8 22 fa ff ff       	call   f0100ccf <page_alloc>
f01012ad:	89 c7                	mov    %eax,%edi
f01012af:	83 c4 10             	add    $0x10,%esp
f01012b2:	85 c0                	test   %eax,%eax
f01012b4:	75 19                	jne    f01012cf <mem_init+0x330>
f01012b6:	68 34 4d 10 f0       	push   $0xf0104d34
f01012bb:	68 73 4c 10 f0       	push   $0xf0104c73
f01012c0:	68 b9 02 00 00       	push   $0x2b9
f01012c5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01012ca:	e8 d1 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012cf:	83 ec 0c             	sub    $0xc,%esp
f01012d2:	6a 00                	push   $0x0
f01012d4:	e8 f6 f9 ff ff       	call   f0100ccf <page_alloc>
f01012d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012dc:	83 c4 10             	add    $0x10,%esp
f01012df:	85 c0                	test   %eax,%eax
f01012e1:	75 19                	jne    f01012fc <mem_init+0x35d>
f01012e3:	68 4a 4d 10 f0       	push   $0xf0104d4a
f01012e8:	68 73 4c 10 f0       	push   $0xf0104c73
f01012ed:	68 ba 02 00 00       	push   $0x2ba
f01012f2:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01012f7:	e8 a4 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012fc:	39 fe                	cmp    %edi,%esi
f01012fe:	75 19                	jne    f0101319 <mem_init+0x37a>
f0101300:	68 60 4d 10 f0       	push   $0xf0104d60
f0101305:	68 73 4c 10 f0       	push   $0xf0104c73
f010130a:	68 bc 02 00 00       	push   $0x2bc
f010130f:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101314:	e8 87 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101319:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010131c:	39 c7                	cmp    %eax,%edi
f010131e:	74 04                	je     f0101324 <mem_init+0x385>
f0101320:	39 c6                	cmp    %eax,%esi
f0101322:	75 19                	jne    f010133d <mem_init+0x39e>
f0101324:	68 2c 46 10 f0       	push   $0xf010462c
f0101329:	68 73 4c 10 f0       	push   $0xf0104c73
f010132e:	68 bd 02 00 00       	push   $0x2bd
f0101333:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101338:	e8 63 ed ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010133d:	83 ec 0c             	sub    $0xc,%esp
f0101340:	6a 00                	push   $0x0
f0101342:	e8 88 f9 ff ff       	call   f0100ccf <page_alloc>
f0101347:	83 c4 10             	add    $0x10,%esp
f010134a:	85 c0                	test   %eax,%eax
f010134c:	74 19                	je     f0101367 <mem_init+0x3c8>
f010134e:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0101353:	68 73 4c 10 f0       	push   $0xf0104c73
f0101358:	68 be 02 00 00       	push   $0x2be
f010135d:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101362:	e8 39 ed ff ff       	call   f01000a0 <_panic>
f0101367:	89 f0                	mov    %esi,%eax
f0101369:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010136f:	c1 f8 03             	sar    $0x3,%eax
f0101372:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101375:	89 c2                	mov    %eax,%edx
f0101377:	c1 ea 0c             	shr    $0xc,%edx
f010137a:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0101380:	72 12                	jb     f0101394 <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101382:	50                   	push   %eax
f0101383:	68 9c 44 10 f0       	push   $0xf010449c
f0101388:	6a 56                	push   $0x56
f010138a:	68 59 4c 10 f0       	push   $0xf0104c59
f010138f:	e8 0c ed ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101394:	83 ec 04             	sub    $0x4,%esp
f0101397:	68 00 10 00 00       	push   $0x1000
f010139c:	6a 01                	push   $0x1
f010139e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013a3:	50                   	push   %eax
f01013a4:	e8 b2 27 00 00       	call   f0103b5b <memset>
	page_free(pp0);
f01013a9:	89 34 24             	mov    %esi,(%esp)
f01013ac:	e8 8e f9 ff ff       	call   f0100d3f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013b8:	e8 12 f9 ff ff       	call   f0100ccf <page_alloc>
f01013bd:	83 c4 10             	add    $0x10,%esp
f01013c0:	85 c0                	test   %eax,%eax
f01013c2:	75 19                	jne    f01013dd <mem_init+0x43e>
f01013c4:	68 d8 4d 10 f0       	push   $0xf0104dd8
f01013c9:	68 73 4c 10 f0       	push   $0xf0104c73
f01013ce:	68 c3 02 00 00       	push   $0x2c3
f01013d3:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01013d8:	e8 c3 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01013dd:	39 c6                	cmp    %eax,%esi
f01013df:	74 19                	je     f01013fa <mem_init+0x45b>
f01013e1:	68 f6 4d 10 f0       	push   $0xf0104df6
f01013e6:	68 73 4c 10 f0       	push   $0xf0104c73
f01013eb:	68 c4 02 00 00       	push   $0x2c4
f01013f0:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01013f5:	e8 a6 ec ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013fa:	89 f0                	mov    %esi,%eax
f01013fc:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101402:	c1 f8 03             	sar    $0x3,%eax
f0101405:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101408:	89 c2                	mov    %eax,%edx
f010140a:	c1 ea 0c             	shr    $0xc,%edx
f010140d:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0101413:	72 12                	jb     f0101427 <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101415:	50                   	push   %eax
f0101416:	68 9c 44 10 f0       	push   $0xf010449c
f010141b:	6a 56                	push   $0x56
f010141d:	68 59 4c 10 f0       	push   $0xf0104c59
f0101422:	e8 79 ec ff ff       	call   f01000a0 <_panic>
f0101427:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010142d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101433:	80 38 00             	cmpb   $0x0,(%eax)
f0101436:	74 19                	je     f0101451 <mem_init+0x4b2>
f0101438:	68 06 4e 10 f0       	push   $0xf0104e06
f010143d:	68 73 4c 10 f0       	push   $0xf0104c73
f0101442:	68 c7 02 00 00       	push   $0x2c7
f0101447:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010144c:	e8 4f ec ff ff       	call   f01000a0 <_panic>
f0101451:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101454:	39 d0                	cmp    %edx,%eax
f0101456:	75 db                	jne    f0101433 <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101458:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010145b:	a3 3c be 17 f0       	mov    %eax,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101460:	83 ec 0c             	sub    $0xc,%esp
f0101463:	56                   	push   %esi
f0101464:	e8 d6 f8 ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101469:	89 3c 24             	mov    %edi,(%esp)
f010146c:	e8 ce f8 ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f0101471:	83 c4 04             	add    $0x4,%esp
f0101474:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101477:	e8 c3 f8 ff ff       	call   f0100d3f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010147c:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101481:	83 c4 10             	add    $0x10,%esp
f0101484:	eb 05                	jmp    f010148b <mem_init+0x4ec>
		--nfree;
f0101486:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101489:	8b 00                	mov    (%eax),%eax
f010148b:	85 c0                	test   %eax,%eax
f010148d:	75 f7                	jne    f0101486 <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f010148f:	85 db                	test   %ebx,%ebx
f0101491:	74 19                	je     f01014ac <mem_init+0x50d>
f0101493:	68 10 4e 10 f0       	push   $0xf0104e10
f0101498:	68 73 4c 10 f0       	push   $0xf0104c73
f010149d:	68 d4 02 00 00       	push   $0x2d4
f01014a2:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01014a7:	e8 f4 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014ac:	83 ec 0c             	sub    $0xc,%esp
f01014af:	68 4c 46 10 f0       	push   $0xf010464c
f01014b4:	e8 10 18 00 00       	call   f0102cc9 <cprintf>
	void *va;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014c0:	e8 0a f8 ff ff       	call   f0100ccf <page_alloc>
f01014c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014c8:	83 c4 10             	add    $0x10,%esp
f01014cb:	85 c0                	test   %eax,%eax
f01014cd:	75 19                	jne    f01014e8 <mem_init+0x549>
f01014cf:	68 1e 4d 10 f0       	push   $0xf0104d1e
f01014d4:	68 73 4c 10 f0       	push   $0xf0104c73
f01014d9:	68 31 03 00 00       	push   $0x331
f01014de:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01014e3:	e8 b8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014e8:	83 ec 0c             	sub    $0xc,%esp
f01014eb:	6a 00                	push   $0x0
f01014ed:	e8 dd f7 ff ff       	call   f0100ccf <page_alloc>
f01014f2:	89 c3                	mov    %eax,%ebx
f01014f4:	83 c4 10             	add    $0x10,%esp
f01014f7:	85 c0                	test   %eax,%eax
f01014f9:	75 19                	jne    f0101514 <mem_init+0x575>
f01014fb:	68 34 4d 10 f0       	push   $0xf0104d34
f0101500:	68 73 4c 10 f0       	push   $0xf0104c73
f0101505:	68 32 03 00 00       	push   $0x332
f010150a:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010150f:	e8 8c eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101514:	83 ec 0c             	sub    $0xc,%esp
f0101517:	6a 00                	push   $0x0
f0101519:	e8 b1 f7 ff ff       	call   f0100ccf <page_alloc>
f010151e:	89 c6                	mov    %eax,%esi
f0101520:	83 c4 10             	add    $0x10,%esp
f0101523:	85 c0                	test   %eax,%eax
f0101525:	75 19                	jne    f0101540 <mem_init+0x5a1>
f0101527:	68 4a 4d 10 f0       	push   $0xf0104d4a
f010152c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101531:	68 33 03 00 00       	push   $0x333
f0101536:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010153b:	e8 60 eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101540:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101543:	75 19                	jne    f010155e <mem_init+0x5bf>
f0101545:	68 60 4d 10 f0       	push   $0xf0104d60
f010154a:	68 73 4c 10 f0       	push   $0xf0104c73
f010154f:	68 36 03 00 00       	push   $0x336
f0101554:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101559:	e8 42 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010155e:	39 c3                	cmp    %eax,%ebx
f0101560:	74 05                	je     f0101567 <mem_init+0x5c8>
f0101562:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101565:	75 19                	jne    f0101580 <mem_init+0x5e1>
f0101567:	68 2c 46 10 f0       	push   $0xf010462c
f010156c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101571:	68 37 03 00 00       	push   $0x337
f0101576:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010157b:	e8 20 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101580:	a1 3c be 17 f0       	mov    0xf017be3c,%eax
f0101585:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101588:	c7 05 3c be 17 f0 00 	movl   $0x0,0xf017be3c
f010158f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101592:	83 ec 0c             	sub    $0xc,%esp
f0101595:	6a 00                	push   $0x0
f0101597:	e8 33 f7 ff ff       	call   f0100ccf <page_alloc>
f010159c:	83 c4 10             	add    $0x10,%esp
f010159f:	85 c0                	test   %eax,%eax
f01015a1:	74 19                	je     f01015bc <mem_init+0x61d>
f01015a3:	68 c9 4d 10 f0       	push   $0xf0104dc9
f01015a8:	68 73 4c 10 f0       	push   $0xf0104c73
f01015ad:	68 3e 03 00 00       	push   $0x33e
f01015b2:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01015b7:	e8 e4 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01015bc:	83 ec 04             	sub    $0x4,%esp
f01015bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015c2:	50                   	push   %eax
f01015c3:	6a 00                	push   $0x0
f01015c5:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01015cb:	e8 af f8 ff ff       	call   f0100e7f <page_lookup>
f01015d0:	83 c4 10             	add    $0x10,%esp
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	74 19                	je     f01015f0 <mem_init+0x651>
f01015d7:	68 6c 46 10 f0       	push   $0xf010466c
f01015dc:	68 73 4c 10 f0       	push   $0xf0104c73
f01015e1:	68 41 03 00 00       	push   $0x341
f01015e6:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01015eb:	e8 b0 ea ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01015f0:	6a 02                	push   $0x2
f01015f2:	6a 00                	push   $0x0
f01015f4:	53                   	push   %ebx
f01015f5:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01015fb:	e8 27 f9 ff ff       	call   f0100f27 <page_insert>
f0101600:	83 c4 10             	add    $0x10,%esp
f0101603:	85 c0                	test   %eax,%eax
f0101605:	78 19                	js     f0101620 <mem_init+0x681>
f0101607:	68 a4 46 10 f0       	push   $0xf01046a4
f010160c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101611:	68 44 03 00 00       	push   $0x344
f0101616:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010161b:	e8 80 ea ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101620:	83 ec 0c             	sub    $0xc,%esp
f0101623:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101626:	e8 14 f7 ff ff       	call   f0100d3f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010162b:	6a 02                	push   $0x2
f010162d:	6a 00                	push   $0x0
f010162f:	53                   	push   %ebx
f0101630:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101636:	e8 ec f8 ff ff       	call   f0100f27 <page_insert>
f010163b:	83 c4 20             	add    $0x20,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	74 19                	je     f010165b <mem_init+0x6bc>
f0101642:	68 d4 46 10 f0       	push   $0xf01046d4
f0101647:	68 73 4c 10 f0       	push   $0xf0104c73
f010164c:	68 48 03 00 00       	push   $0x348
f0101651:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101656:	e8 45 ea ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010165b:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101661:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0101666:	89 c1                	mov    %eax,%ecx
f0101668:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010166b:	8b 17                	mov    (%edi),%edx
f010166d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101673:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101676:	29 c8                	sub    %ecx,%eax
f0101678:	c1 f8 03             	sar    $0x3,%eax
f010167b:	c1 e0 0c             	shl    $0xc,%eax
f010167e:	39 c2                	cmp    %eax,%edx
f0101680:	74 19                	je     f010169b <mem_init+0x6fc>
f0101682:	68 04 47 10 f0       	push   $0xf0104704
f0101687:	68 73 4c 10 f0       	push   $0xf0104c73
f010168c:	68 49 03 00 00       	push   $0x349
f0101691:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101696:	e8 05 ea ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010169b:	ba 00 00 00 00       	mov    $0x0,%edx
f01016a0:	89 f8                	mov    %edi,%eax
f01016a2:	e8 47 f2 ff ff       	call   f01008ee <check_va2pa>
f01016a7:	89 da                	mov    %ebx,%edx
f01016a9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016ac:	c1 fa 03             	sar    $0x3,%edx
f01016af:	c1 e2 0c             	shl    $0xc,%edx
f01016b2:	39 d0                	cmp    %edx,%eax
f01016b4:	74 19                	je     f01016cf <mem_init+0x730>
f01016b6:	68 2c 47 10 f0       	push   $0xf010472c
f01016bb:	68 73 4c 10 f0       	push   $0xf0104c73
f01016c0:	68 4a 03 00 00       	push   $0x34a
f01016c5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01016ca:	e8 d1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01016cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016d4:	74 19                	je     f01016ef <mem_init+0x750>
f01016d6:	68 1b 4e 10 f0       	push   $0xf0104e1b
f01016db:	68 73 4c 10 f0       	push   $0xf0104c73
f01016e0:	68 4b 03 00 00       	push   $0x34b
f01016e5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01016ea:	e8 b1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01016ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016f2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01016f7:	74 19                	je     f0101712 <mem_init+0x773>
f01016f9:	68 2c 4e 10 f0       	push   $0xf0104e2c
f01016fe:	68 73 4c 10 f0       	push   $0xf0104c73
f0101703:	68 4c 03 00 00       	push   $0x34c
f0101708:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010170d:	e8 8e e9 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101712:	6a 02                	push   $0x2
f0101714:	68 00 10 00 00       	push   $0x1000
f0101719:	56                   	push   %esi
f010171a:	57                   	push   %edi
f010171b:	e8 07 f8 ff ff       	call   f0100f27 <page_insert>
f0101720:	83 c4 10             	add    $0x10,%esp
f0101723:	85 c0                	test   %eax,%eax
f0101725:	74 19                	je     f0101740 <mem_init+0x7a1>
f0101727:	68 5c 47 10 f0       	push   $0xf010475c
f010172c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101731:	68 4f 03 00 00       	push   $0x34f
f0101736:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010173b:	e8 60 e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101740:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101745:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010174a:	e8 9f f1 ff ff       	call   f01008ee <check_va2pa>
f010174f:	89 f2                	mov    %esi,%edx
f0101751:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101757:	c1 fa 03             	sar    $0x3,%edx
f010175a:	c1 e2 0c             	shl    $0xc,%edx
f010175d:	39 d0                	cmp    %edx,%eax
f010175f:	74 19                	je     f010177a <mem_init+0x7db>
f0101761:	68 98 47 10 f0       	push   $0xf0104798
f0101766:	68 73 4c 10 f0       	push   $0xf0104c73
f010176b:	68 50 03 00 00       	push   $0x350
f0101770:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101775:	e8 26 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010177a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010177f:	74 19                	je     f010179a <mem_init+0x7fb>
f0101781:	68 3d 4e 10 f0       	push   $0xf0104e3d
f0101786:	68 73 4c 10 f0       	push   $0xf0104c73
f010178b:	68 51 03 00 00       	push   $0x351
f0101790:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101795:	e8 06 e9 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010179a:	83 ec 0c             	sub    $0xc,%esp
f010179d:	6a 00                	push   $0x0
f010179f:	e8 2b f5 ff ff       	call   f0100ccf <page_alloc>
f01017a4:	83 c4 10             	add    $0x10,%esp
f01017a7:	85 c0                	test   %eax,%eax
f01017a9:	74 19                	je     f01017c4 <mem_init+0x825>
f01017ab:	68 c9 4d 10 f0       	push   $0xf0104dc9
f01017b0:	68 73 4c 10 f0       	push   $0xf0104c73
f01017b5:	68 54 03 00 00       	push   $0x354
f01017ba:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01017bf:	e8 dc e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017c4:	6a 02                	push   $0x2
f01017c6:	68 00 10 00 00       	push   $0x1000
f01017cb:	56                   	push   %esi
f01017cc:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01017d2:	e8 50 f7 ff ff       	call   f0100f27 <page_insert>
f01017d7:	83 c4 10             	add    $0x10,%esp
f01017da:	85 c0                	test   %eax,%eax
f01017dc:	74 19                	je     f01017f7 <mem_init+0x858>
f01017de:	68 5c 47 10 f0       	push   $0xf010475c
f01017e3:	68 73 4c 10 f0       	push   $0xf0104c73
f01017e8:	68 57 03 00 00       	push   $0x357
f01017ed:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01017f2:	e8 a9 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017f7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017fc:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101801:	e8 e8 f0 ff ff       	call   f01008ee <check_va2pa>
f0101806:	89 f2                	mov    %esi,%edx
f0101808:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f010180e:	c1 fa 03             	sar    $0x3,%edx
f0101811:	c1 e2 0c             	shl    $0xc,%edx
f0101814:	39 d0                	cmp    %edx,%eax
f0101816:	74 19                	je     f0101831 <mem_init+0x892>
f0101818:	68 98 47 10 f0       	push   $0xf0104798
f010181d:	68 73 4c 10 f0       	push   $0xf0104c73
f0101822:	68 58 03 00 00       	push   $0x358
f0101827:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010182c:	e8 6f e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101831:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101836:	74 19                	je     f0101851 <mem_init+0x8b2>
f0101838:	68 3d 4e 10 f0       	push   $0xf0104e3d
f010183d:	68 73 4c 10 f0       	push   $0xf0104c73
f0101842:	68 59 03 00 00       	push   $0x359
f0101847:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010184c:	e8 4f e8 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101851:	83 ec 0c             	sub    $0xc,%esp
f0101854:	6a 00                	push   $0x0
f0101856:	e8 74 f4 ff ff       	call   f0100ccf <page_alloc>
f010185b:	83 c4 10             	add    $0x10,%esp
f010185e:	85 c0                	test   %eax,%eax
f0101860:	74 19                	je     f010187b <mem_init+0x8dc>
f0101862:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0101867:	68 73 4c 10 f0       	push   $0xf0104c73
f010186c:	68 5d 03 00 00       	push   $0x35d
f0101871:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101876:	e8 25 e8 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010187b:	8b 15 08 cb 17 f0    	mov    0xf017cb08,%edx
f0101881:	8b 02                	mov    (%edx),%eax
f0101883:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101888:	89 c1                	mov    %eax,%ecx
f010188a:	c1 e9 0c             	shr    $0xc,%ecx
f010188d:	3b 0d 04 cb 17 f0    	cmp    0xf017cb04,%ecx
f0101893:	72 15                	jb     f01018aa <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101895:	50                   	push   %eax
f0101896:	68 9c 44 10 f0       	push   $0xf010449c
f010189b:	68 60 03 00 00       	push   $0x360
f01018a0:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01018a5:	e8 f6 e7 ff ff       	call   f01000a0 <_panic>
f01018aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01018b2:	83 ec 04             	sub    $0x4,%esp
f01018b5:	6a 00                	push   $0x0
f01018b7:	68 00 10 00 00       	push   $0x1000
f01018bc:	52                   	push   %edx
f01018bd:	e8 e1 f4 ff ff       	call   f0100da3 <pgdir_walk>
f01018c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018c5:	8d 57 04             	lea    0x4(%edi),%edx
f01018c8:	83 c4 10             	add    $0x10,%esp
f01018cb:	39 d0                	cmp    %edx,%eax
f01018cd:	74 19                	je     f01018e8 <mem_init+0x949>
f01018cf:	68 c8 47 10 f0       	push   $0xf01047c8
f01018d4:	68 73 4c 10 f0       	push   $0xf0104c73
f01018d9:	68 61 03 00 00       	push   $0x361
f01018de:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01018e3:	e8 b8 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01018e8:	6a 06                	push   $0x6
f01018ea:	68 00 10 00 00       	push   $0x1000
f01018ef:	56                   	push   %esi
f01018f0:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01018f6:	e8 2c f6 ff ff       	call   f0100f27 <page_insert>
f01018fb:	83 c4 10             	add    $0x10,%esp
f01018fe:	85 c0                	test   %eax,%eax
f0101900:	74 19                	je     f010191b <mem_init+0x97c>
f0101902:	68 08 48 10 f0       	push   $0xf0104808
f0101907:	68 73 4c 10 f0       	push   $0xf0104c73
f010190c:	68 64 03 00 00       	push   $0x364
f0101911:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101916:	e8 85 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010191b:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101921:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101926:	89 f8                	mov    %edi,%eax
f0101928:	e8 c1 ef ff ff       	call   f01008ee <check_va2pa>
f010192d:	89 f2                	mov    %esi,%edx
f010192f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101935:	c1 fa 03             	sar    $0x3,%edx
f0101938:	c1 e2 0c             	shl    $0xc,%edx
f010193b:	39 d0                	cmp    %edx,%eax
f010193d:	74 19                	je     f0101958 <mem_init+0x9b9>
f010193f:	68 98 47 10 f0       	push   $0xf0104798
f0101944:	68 73 4c 10 f0       	push   $0xf0104c73
f0101949:	68 65 03 00 00       	push   $0x365
f010194e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101953:	e8 48 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101958:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010195d:	74 19                	je     f0101978 <mem_init+0x9d9>
f010195f:	68 3d 4e 10 f0       	push   $0xf0104e3d
f0101964:	68 73 4c 10 f0       	push   $0xf0104c73
f0101969:	68 66 03 00 00       	push   $0x366
f010196e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101973:	e8 28 e7 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101978:	83 ec 04             	sub    $0x4,%esp
f010197b:	6a 00                	push   $0x0
f010197d:	68 00 10 00 00       	push   $0x1000
f0101982:	57                   	push   %edi
f0101983:	e8 1b f4 ff ff       	call   f0100da3 <pgdir_walk>
f0101988:	83 c4 10             	add    $0x10,%esp
f010198b:	f6 00 04             	testb  $0x4,(%eax)
f010198e:	75 19                	jne    f01019a9 <mem_init+0xa0a>
f0101990:	68 48 48 10 f0       	push   $0xf0104848
f0101995:	68 73 4c 10 f0       	push   $0xf0104c73
f010199a:	68 67 03 00 00       	push   $0x367
f010199f:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01019a4:	e8 f7 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019a9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01019ae:	f6 00 04             	testb  $0x4,(%eax)
f01019b1:	75 19                	jne    f01019cc <mem_init+0xa2d>
f01019b3:	68 4e 4e 10 f0       	push   $0xf0104e4e
f01019b8:	68 73 4c 10 f0       	push   $0xf0104c73
f01019bd:	68 68 03 00 00       	push   $0x368
f01019c2:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01019c7:	e8 d4 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019cc:	6a 02                	push   $0x2
f01019ce:	68 00 10 00 00       	push   $0x1000
f01019d3:	56                   	push   %esi
f01019d4:	50                   	push   %eax
f01019d5:	e8 4d f5 ff ff       	call   f0100f27 <page_insert>
f01019da:	83 c4 10             	add    $0x10,%esp
f01019dd:	85 c0                	test   %eax,%eax
f01019df:	74 19                	je     f01019fa <mem_init+0xa5b>
f01019e1:	68 5c 47 10 f0       	push   $0xf010475c
f01019e6:	68 73 4c 10 f0       	push   $0xf0104c73
f01019eb:	68 6b 03 00 00       	push   $0x36b
f01019f0:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01019f5:	e8 a6 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01019fa:	83 ec 04             	sub    $0x4,%esp
f01019fd:	6a 00                	push   $0x0
f01019ff:	68 00 10 00 00       	push   $0x1000
f0101a04:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a0a:	e8 94 f3 ff ff       	call   f0100da3 <pgdir_walk>
f0101a0f:	83 c4 10             	add    $0x10,%esp
f0101a12:	f6 00 02             	testb  $0x2,(%eax)
f0101a15:	75 19                	jne    f0101a30 <mem_init+0xa91>
f0101a17:	68 7c 48 10 f0       	push   $0xf010487c
f0101a1c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101a21:	68 6c 03 00 00       	push   $0x36c
f0101a26:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101a2b:	e8 70 e6 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a30:	83 ec 04             	sub    $0x4,%esp
f0101a33:	6a 00                	push   $0x0
f0101a35:	68 00 10 00 00       	push   $0x1000
f0101a3a:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a40:	e8 5e f3 ff ff       	call   f0100da3 <pgdir_walk>
f0101a45:	83 c4 10             	add    $0x10,%esp
f0101a48:	f6 00 04             	testb  $0x4,(%eax)
f0101a4b:	74 19                	je     f0101a66 <mem_init+0xac7>
f0101a4d:	68 b0 48 10 f0       	push   $0xf01048b0
f0101a52:	68 73 4c 10 f0       	push   $0xf0104c73
f0101a57:	68 6d 03 00 00       	push   $0x36d
f0101a5c:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101a61:	e8 3a e6 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101a66:	6a 02                	push   $0x2
f0101a68:	68 00 00 40 00       	push   $0x400000
f0101a6d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a70:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101a76:	e8 ac f4 ff ff       	call   f0100f27 <page_insert>
f0101a7b:	83 c4 10             	add    $0x10,%esp
f0101a7e:	85 c0                	test   %eax,%eax
f0101a80:	78 19                	js     f0101a9b <mem_init+0xafc>
f0101a82:	68 e8 48 10 f0       	push   $0xf01048e8
f0101a87:	68 73 4c 10 f0       	push   $0xf0104c73
f0101a8c:	68 70 03 00 00       	push   $0x370
f0101a91:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101a96:	e8 05 e6 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a9b:	6a 02                	push   $0x2
f0101a9d:	68 00 10 00 00       	push   $0x1000
f0101aa2:	53                   	push   %ebx
f0101aa3:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101aa9:	e8 79 f4 ff ff       	call   f0100f27 <page_insert>
f0101aae:	83 c4 10             	add    $0x10,%esp
f0101ab1:	85 c0                	test   %eax,%eax
f0101ab3:	74 19                	je     f0101ace <mem_init+0xb2f>
f0101ab5:	68 24 49 10 f0       	push   $0xf0104924
f0101aba:	68 73 4c 10 f0       	push   $0xf0104c73
f0101abf:	68 73 03 00 00       	push   $0x373
f0101ac4:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101ac9:	e8 d2 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ace:	83 ec 04             	sub    $0x4,%esp
f0101ad1:	6a 00                	push   $0x0
f0101ad3:	68 00 10 00 00       	push   $0x1000
f0101ad8:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101ade:	e8 c0 f2 ff ff       	call   f0100da3 <pgdir_walk>
f0101ae3:	83 c4 10             	add    $0x10,%esp
f0101ae6:	f6 00 04             	testb  $0x4,(%eax)
f0101ae9:	74 19                	je     f0101b04 <mem_init+0xb65>
f0101aeb:	68 b0 48 10 f0       	push   $0xf01048b0
f0101af0:	68 73 4c 10 f0       	push   $0xf0104c73
f0101af5:	68 74 03 00 00       	push   $0x374
f0101afa:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101aff:	e8 9c e5 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b04:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101b0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b0f:	89 f8                	mov    %edi,%eax
f0101b11:	e8 d8 ed ff ff       	call   f01008ee <check_va2pa>
f0101b16:	89 c1                	mov    %eax,%ecx
f0101b18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b1b:	89 d8                	mov    %ebx,%eax
f0101b1d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101b23:	c1 f8 03             	sar    $0x3,%eax
f0101b26:	c1 e0 0c             	shl    $0xc,%eax
f0101b29:	39 c1                	cmp    %eax,%ecx
f0101b2b:	74 19                	je     f0101b46 <mem_init+0xba7>
f0101b2d:	68 60 49 10 f0       	push   $0xf0104960
f0101b32:	68 73 4c 10 f0       	push   $0xf0104c73
f0101b37:	68 77 03 00 00       	push   $0x377
f0101b3c:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101b41:	e8 5a e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b4b:	89 f8                	mov    %edi,%eax
f0101b4d:	e8 9c ed ff ff       	call   f01008ee <check_va2pa>
f0101b52:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b55:	74 19                	je     f0101b70 <mem_init+0xbd1>
f0101b57:	68 8c 49 10 f0       	push   $0xf010498c
f0101b5c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101b61:	68 78 03 00 00       	push   $0x378
f0101b66:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101b6b:	e8 30 e5 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b70:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b75:	74 19                	je     f0101b90 <mem_init+0xbf1>
f0101b77:	68 64 4e 10 f0       	push   $0xf0104e64
f0101b7c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101b81:	68 7a 03 00 00       	push   $0x37a
f0101b86:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101b8b:	e8 10 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101b90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b95:	74 19                	je     f0101bb0 <mem_init+0xc11>
f0101b97:	68 75 4e 10 f0       	push   $0xf0104e75
f0101b9c:	68 73 4c 10 f0       	push   $0xf0104c73
f0101ba1:	68 7b 03 00 00       	push   $0x37b
f0101ba6:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101bab:	e8 f0 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101bb0:	83 ec 0c             	sub    $0xc,%esp
f0101bb3:	6a 00                	push   $0x0
f0101bb5:	e8 15 f1 ff ff       	call   f0100ccf <page_alloc>
f0101bba:	83 c4 10             	add    $0x10,%esp
f0101bbd:	39 c6                	cmp    %eax,%esi
f0101bbf:	75 04                	jne    f0101bc5 <mem_init+0xc26>
f0101bc1:	85 c0                	test   %eax,%eax
f0101bc3:	75 19                	jne    f0101bde <mem_init+0xc3f>
f0101bc5:	68 bc 49 10 f0       	push   $0xf01049bc
f0101bca:	68 73 4c 10 f0       	push   $0xf0104c73
f0101bcf:	68 7e 03 00 00       	push   $0x37e
f0101bd4:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101bd9:	e8 c2 e4 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101bde:	83 ec 08             	sub    $0x8,%esp
f0101be1:	6a 00                	push   $0x0
f0101be3:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101be9:	e8 f7 f2 ff ff       	call   f0100ee5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101bee:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101bf4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bf9:	89 f8                	mov    %edi,%eax
f0101bfb:	e8 ee ec ff ff       	call   f01008ee <check_va2pa>
f0101c00:	83 c4 10             	add    $0x10,%esp
f0101c03:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c06:	74 19                	je     f0101c21 <mem_init+0xc82>
f0101c08:	68 e0 49 10 f0       	push   $0xf01049e0
f0101c0d:	68 73 4c 10 f0       	push   $0xf0104c73
f0101c12:	68 82 03 00 00       	push   $0x382
f0101c17:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101c1c:	e8 7f e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c26:	89 f8                	mov    %edi,%eax
f0101c28:	e8 c1 ec ff ff       	call   f01008ee <check_va2pa>
f0101c2d:	89 da                	mov    %ebx,%edx
f0101c2f:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101c35:	c1 fa 03             	sar    $0x3,%edx
f0101c38:	c1 e2 0c             	shl    $0xc,%edx
f0101c3b:	39 d0                	cmp    %edx,%eax
f0101c3d:	74 19                	je     f0101c58 <mem_init+0xcb9>
f0101c3f:	68 8c 49 10 f0       	push   $0xf010498c
f0101c44:	68 73 4c 10 f0       	push   $0xf0104c73
f0101c49:	68 83 03 00 00       	push   $0x383
f0101c4e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101c53:	e8 48 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101c58:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xcd9>
f0101c5f:	68 1b 4e 10 f0       	push   $0xf0104e1b
f0101c64:	68 73 4c 10 f0       	push   $0xf0104c73
f0101c69:	68 84 03 00 00       	push   $0x384
f0101c6e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101c73:	e8 28 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c78:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c7d:	74 19                	je     f0101c98 <mem_init+0xcf9>
f0101c7f:	68 75 4e 10 f0       	push   $0xf0104e75
f0101c84:	68 73 4c 10 f0       	push   $0xf0104c73
f0101c89:	68 85 03 00 00       	push   $0x385
f0101c8e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101c93:	e8 08 e4 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c98:	6a 00                	push   $0x0
f0101c9a:	68 00 10 00 00       	push   $0x1000
f0101c9f:	53                   	push   %ebx
f0101ca0:	57                   	push   %edi
f0101ca1:	e8 81 f2 ff ff       	call   f0100f27 <page_insert>
f0101ca6:	83 c4 10             	add    $0x10,%esp
f0101ca9:	85 c0                	test   %eax,%eax
f0101cab:	74 19                	je     f0101cc6 <mem_init+0xd27>
f0101cad:	68 04 4a 10 f0       	push   $0xf0104a04
f0101cb2:	68 73 4c 10 f0       	push   $0xf0104c73
f0101cb7:	68 88 03 00 00       	push   $0x388
f0101cbc:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101cc1:	e8 da e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101cc6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ccb:	75 19                	jne    f0101ce6 <mem_init+0xd47>
f0101ccd:	68 86 4e 10 f0       	push   $0xf0104e86
f0101cd2:	68 73 4c 10 f0       	push   $0xf0104c73
f0101cd7:	68 89 03 00 00       	push   $0x389
f0101cdc:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101ce1:	e8 ba e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101ce6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101ce9:	74 19                	je     f0101d04 <mem_init+0xd65>
f0101ceb:	68 92 4e 10 f0       	push   $0xf0104e92
f0101cf0:	68 73 4c 10 f0       	push   $0xf0104c73
f0101cf5:	68 8a 03 00 00       	push   $0x38a
f0101cfa:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101cff:	e8 9c e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d04:	83 ec 08             	sub    $0x8,%esp
f0101d07:	68 00 10 00 00       	push   $0x1000
f0101d0c:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101d12:	e8 ce f1 ff ff       	call   f0100ee5 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d17:	8b 3d 08 cb 17 f0    	mov    0xf017cb08,%edi
f0101d1d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d22:	89 f8                	mov    %edi,%eax
f0101d24:	e8 c5 eb ff ff       	call   f01008ee <check_va2pa>
f0101d29:	83 c4 10             	add    $0x10,%esp
f0101d2c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d2f:	74 19                	je     f0101d4a <mem_init+0xdab>
f0101d31:	68 e0 49 10 f0       	push   $0xf01049e0
f0101d36:	68 73 4c 10 f0       	push   $0xf0104c73
f0101d3b:	68 8e 03 00 00       	push   $0x38e
f0101d40:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101d45:	e8 56 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d4a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d4f:	89 f8                	mov    %edi,%eax
f0101d51:	e8 98 eb ff ff       	call   f01008ee <check_va2pa>
f0101d56:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d59:	74 19                	je     f0101d74 <mem_init+0xdd5>
f0101d5b:	68 3c 4a 10 f0       	push   $0xf0104a3c
f0101d60:	68 73 4c 10 f0       	push   $0xf0104c73
f0101d65:	68 8f 03 00 00       	push   $0x38f
f0101d6a:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101d6f:	e8 2c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101d74:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d79:	74 19                	je     f0101d94 <mem_init+0xdf5>
f0101d7b:	68 a7 4e 10 f0       	push   $0xf0104ea7
f0101d80:	68 73 4c 10 f0       	push   $0xf0104c73
f0101d85:	68 90 03 00 00       	push   $0x390
f0101d8a:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101d8f:	e8 0c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d94:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d99:	74 19                	je     f0101db4 <mem_init+0xe15>
f0101d9b:	68 75 4e 10 f0       	push   $0xf0104e75
f0101da0:	68 73 4c 10 f0       	push   $0xf0104c73
f0101da5:	68 91 03 00 00       	push   $0x391
f0101daa:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101daf:	e8 ec e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101db4:	83 ec 0c             	sub    $0xc,%esp
f0101db7:	6a 00                	push   $0x0
f0101db9:	e8 11 ef ff ff       	call   f0100ccf <page_alloc>
f0101dbe:	83 c4 10             	add    $0x10,%esp
f0101dc1:	85 c0                	test   %eax,%eax
f0101dc3:	74 04                	je     f0101dc9 <mem_init+0xe2a>
f0101dc5:	39 c3                	cmp    %eax,%ebx
f0101dc7:	74 19                	je     f0101de2 <mem_init+0xe43>
f0101dc9:	68 64 4a 10 f0       	push   $0xf0104a64
f0101dce:	68 73 4c 10 f0       	push   $0xf0104c73
f0101dd3:	68 94 03 00 00       	push   $0x394
f0101dd8:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101ddd:	e8 be e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101de2:	83 ec 0c             	sub    $0xc,%esp
f0101de5:	6a 00                	push   $0x0
f0101de7:	e8 e3 ee ff ff       	call   f0100ccf <page_alloc>
f0101dec:	83 c4 10             	add    $0x10,%esp
f0101def:	85 c0                	test   %eax,%eax
f0101df1:	74 19                	je     f0101e0c <mem_init+0xe6d>
f0101df3:	68 c9 4d 10 f0       	push   $0xf0104dc9
f0101df8:	68 73 4c 10 f0       	push   $0xf0104c73
f0101dfd:	68 97 03 00 00       	push   $0x397
f0101e02:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101e07:	e8 94 e2 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e0c:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f0101e12:	8b 11                	mov    (%ecx),%edx
f0101e14:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e1d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101e23:	c1 f8 03             	sar    $0x3,%eax
f0101e26:	c1 e0 0c             	shl    $0xc,%eax
f0101e29:	39 c2                	cmp    %eax,%edx
f0101e2b:	74 19                	je     f0101e46 <mem_init+0xea7>
f0101e2d:	68 04 47 10 f0       	push   $0xf0104704
f0101e32:	68 73 4c 10 f0       	push   $0xf0104c73
f0101e37:	68 9a 03 00 00       	push   $0x39a
f0101e3c:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101e41:	e8 5a e2 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101e46:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e4f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e54:	74 19                	je     f0101e6f <mem_init+0xed0>
f0101e56:	68 2c 4e 10 f0       	push   $0xf0104e2c
f0101e5b:	68 73 4c 10 f0       	push   $0xf0104c73
f0101e60:	68 9c 03 00 00       	push   $0x39c
f0101e65:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101e6a:	e8 31 e2 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101e6f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e72:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e78:	83 ec 0c             	sub    $0xc,%esp
f0101e7b:	50                   	push   %eax
f0101e7c:	e8 be ee ff ff       	call   f0100d3f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e81:	83 c4 0c             	add    $0xc,%esp
f0101e84:	6a 01                	push   $0x1
f0101e86:	68 00 10 40 00       	push   $0x401000
f0101e8b:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101e91:	e8 0d ef ff ff       	call   f0100da3 <pgdir_walk>
f0101e96:	89 c7                	mov    %eax,%edi
f0101e98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e9b:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101ea0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ea3:	8b 40 04             	mov    0x4(%eax),%eax
f0101ea6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101eab:	8b 0d 04 cb 17 f0    	mov    0xf017cb04,%ecx
f0101eb1:	89 c2                	mov    %eax,%edx
f0101eb3:	c1 ea 0c             	shr    $0xc,%edx
f0101eb6:	83 c4 10             	add    $0x10,%esp
f0101eb9:	39 ca                	cmp    %ecx,%edx
f0101ebb:	72 15                	jb     f0101ed2 <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ebd:	50                   	push   %eax
f0101ebe:	68 9c 44 10 f0       	push   $0xf010449c
f0101ec3:	68 a3 03 00 00       	push   $0x3a3
f0101ec8:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101ecd:	e8 ce e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ed2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ed7:	39 c7                	cmp    %eax,%edi
f0101ed9:	74 19                	je     f0101ef4 <mem_init+0xf55>
f0101edb:	68 b8 4e 10 f0       	push   $0xf0104eb8
f0101ee0:	68 73 4c 10 f0       	push   $0xf0104c73
f0101ee5:	68 a4 03 00 00       	push   $0x3a4
f0101eea:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101eef:	e8 ac e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ef4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ef7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101efe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f01:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f07:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0101f0d:	c1 f8 03             	sar    $0x3,%eax
f0101f10:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f13:	89 c2                	mov    %eax,%edx
f0101f15:	c1 ea 0c             	shr    $0xc,%edx
f0101f18:	39 d1                	cmp    %edx,%ecx
f0101f1a:	77 12                	ja     f0101f2e <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f1c:	50                   	push   %eax
f0101f1d:	68 9c 44 10 f0       	push   $0xf010449c
f0101f22:	6a 56                	push   $0x56
f0101f24:	68 59 4c 10 f0       	push   $0xf0104c59
f0101f29:	e8 72 e1 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f2e:	83 ec 04             	sub    $0x4,%esp
f0101f31:	68 00 10 00 00       	push   $0x1000
f0101f36:	68 ff 00 00 00       	push   $0xff
f0101f3b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f40:	50                   	push   %eax
f0101f41:	e8 15 1c 00 00       	call   f0103b5b <memset>
	page_free(pp0);
f0101f46:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f49:	89 3c 24             	mov    %edi,(%esp)
f0101f4c:	e8 ee ed ff ff       	call   f0100d3f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f51:	83 c4 0c             	add    $0xc,%esp
f0101f54:	6a 01                	push   $0x1
f0101f56:	6a 00                	push   $0x0
f0101f58:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0101f5e:	e8 40 ee ff ff       	call   f0100da3 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f63:	89 fa                	mov    %edi,%edx
f0101f65:	2b 15 0c cb 17 f0    	sub    0xf017cb0c,%edx
f0101f6b:	c1 fa 03             	sar    $0x3,%edx
f0101f6e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f71:	89 d0                	mov    %edx,%eax
f0101f73:	c1 e8 0c             	shr    $0xc,%eax
f0101f76:	83 c4 10             	add    $0x10,%esp
f0101f79:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0101f7f:	72 12                	jb     f0101f93 <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f81:	52                   	push   %edx
f0101f82:	68 9c 44 10 f0       	push   $0xf010449c
f0101f87:	6a 56                	push   $0x56
f0101f89:	68 59 4c 10 f0       	push   $0xf0104c59
f0101f8e:	e8 0d e1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0101f93:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f9c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fa2:	f6 00 01             	testb  $0x1,(%eax)
f0101fa5:	74 19                	je     f0101fc0 <mem_init+0x1021>
f0101fa7:	68 d0 4e 10 f0       	push   $0xf0104ed0
f0101fac:	68 73 4c 10 f0       	push   $0xf0104c73
f0101fb1:	68 ae 03 00 00       	push   $0x3ae
f0101fb6:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0101fbb:	e8 e0 e0 ff ff       	call   f01000a0 <_panic>
f0101fc0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101fc3:	39 d0                	cmp    %edx,%eax
f0101fc5:	75 db                	jne    f0101fa2 <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101fc7:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0101fcc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101fd2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101fdb:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0101fde:	89 3d 3c be 17 f0    	mov    %edi,0xf017be3c

	// free the pages we took
	page_free(pp0);
f0101fe4:	83 ec 0c             	sub    $0xc,%esp
f0101fe7:	50                   	push   %eax
f0101fe8:	e8 52 ed ff ff       	call   f0100d3f <page_free>
	page_free(pp1);
f0101fed:	89 1c 24             	mov    %ebx,(%esp)
f0101ff0:	e8 4a ed ff ff       	call   f0100d3f <page_free>
	page_free(pp2);
f0101ff5:	89 34 24             	mov    %esi,(%esp)
f0101ff8:	e8 42 ed ff ff       	call   f0100d3f <page_free>

	cprintf("check_page() succeeded!\n");
f0101ffd:	c7 04 24 e7 4e 10 f0 	movl   $0xf0104ee7,(%esp)
f0102004:	e8 c0 0c 00 00       	call   f0102cc9 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f0102009:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010200e:	83 c4 10             	add    $0x10,%esp
f0102011:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102016:	77 15                	ja     f010202d <mem_init+0x108e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102018:	50                   	push   %eax
f0102019:	68 84 45 10 f0       	push   $0xf0104584
f010201e:	68 b6 00 00 00       	push   $0xb6
f0102023:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102028:	e8 73 e0 ff ff       	call   f01000a0 <_panic>
f010202d:	83 ec 08             	sub    $0x8,%esp
f0102030:	6a 05                	push   $0x5
f0102032:	05 00 00 00 10       	add    $0x10000000,%eax
f0102037:	50                   	push   %eax
f0102038:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010203d:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102042:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f0102047:	e8 ea ed ff ff       	call   f0100e36 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir,UENVS,PTSIZE,PADDR(envs),PTE_W|PTE_P);
f010204c:	a1 44 be 17 f0       	mov    0xf017be44,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102051:	83 c4 10             	add    $0x10,%esp
f0102054:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102059:	77 15                	ja     f0102070 <mem_init+0x10d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010205b:	50                   	push   %eax
f010205c:	68 84 45 10 f0       	push   $0xf0104584
f0102061:	68 be 00 00 00       	push   $0xbe
f0102066:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010206b:	e8 30 e0 ff ff       	call   f01000a0 <_panic>
f0102070:	83 ec 08             	sub    $0x8,%esp
f0102073:	6a 03                	push   $0x3
f0102075:	05 00 00 00 10       	add    $0x10000000,%eax
f010207a:	50                   	push   %eax
f010207b:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102080:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102085:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f010208a:	e8 a7 ed ff ff       	call   f0100e36 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010208f:	83 c4 10             	add    $0x10,%esp
f0102092:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f0102097:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010209c:	77 15                	ja     f01020b3 <mem_init+0x1114>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010209e:	50                   	push   %eax
f010209f:	68 84 45 10 f0       	push   $0xf0104584
f01020a4:	68 ca 00 00 00       	push   $0xca
f01020a9:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01020ae:	e8 ed df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f01020b3:	83 ec 08             	sub    $0x8,%esp
f01020b6:	6a 03                	push   $0x3
f01020b8:	68 00 00 11 00       	push   $0x110000
f01020bd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020c2:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020c7:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020cc:	e8 65 ed ff ff       	call   f0100e36 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0x0,PTE_W|PTE_P);
f01020d1:	83 c4 08             	add    $0x8,%esp
f01020d4:	6a 03                	push   $0x3
f01020d6:	6a 00                	push   $0x0
f01020d8:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01020dd:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01020e2:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01020e7:	e8 4a ed ff ff       	call   f0100e36 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01020ec:	8b 1d 08 cb 17 f0    	mov    0xf017cb08,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020f2:	a1 04 cb 17 f0       	mov    0xf017cb04,%eax
f01020f7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020fa:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102101:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102106:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102109:	8b 3d 0c cb 17 f0    	mov    0xf017cb0c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210f:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102112:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102115:	be 00 00 00 00       	mov    $0x0,%esi
f010211a:	eb 55                	jmp    f0102171 <mem_init+0x11d2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010211c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102122:	89 d8                	mov    %ebx,%eax
f0102124:	e8 c5 e7 ff ff       	call   f01008ee <check_va2pa>
f0102129:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102130:	77 15                	ja     f0102147 <mem_init+0x11a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102132:	57                   	push   %edi
f0102133:	68 84 45 10 f0       	push   $0xf0104584
f0102138:	68 ec 02 00 00       	push   $0x2ec
f010213d:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102142:	e8 59 df ff ff       	call   f01000a0 <_panic>
f0102147:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010214e:	39 d0                	cmp    %edx,%eax
f0102150:	74 19                	je     f010216b <mem_init+0x11cc>
f0102152:	68 88 4a 10 f0       	push   $0xf0104a88
f0102157:	68 73 4c 10 f0       	push   $0xf0104c73
f010215c:	68 ec 02 00 00       	push   $0x2ec
f0102161:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102166:	e8 35 df ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010216b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102171:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102174:	77 a6                	ja     f010211c <mem_init+0x117d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102176:	8b 3d 44 be 17 f0    	mov    0xf017be44,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010217c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010217f:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f0102184:	89 f2                	mov    %esi,%edx
f0102186:	89 d8                	mov    %ebx,%eax
f0102188:	e8 61 e7 ff ff       	call   f01008ee <check_va2pa>
f010218d:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102194:	77 15                	ja     f01021ab <mem_init+0x120c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102196:	57                   	push   %edi
f0102197:	68 84 45 10 f0       	push   $0xf0104584
f010219c:	68 f1 02 00 00       	push   $0x2f1
f01021a1:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01021a6:	e8 f5 de ff ff       	call   f01000a0 <_panic>
f01021ab:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01021b2:	39 c2                	cmp    %eax,%edx
f01021b4:	74 19                	je     f01021cf <mem_init+0x1230>
f01021b6:	68 bc 4a 10 f0       	push   $0xf0104abc
f01021bb:	68 73 4c 10 f0       	push   $0xf0104c73
f01021c0:	68 f1 02 00 00       	push   $0x2f1
f01021c5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01021ca:	e8 d1 de ff ff       	call   f01000a0 <_panic>
f01021cf:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d5:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01021db:	75 a7                	jne    f0102184 <mem_init+0x11e5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021dd:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021e0:	c1 e7 0c             	shl    $0xc,%edi
f01021e3:	be 00 00 00 00       	mov    $0x0,%esi
f01021e8:	eb 30                	jmp    f010221a <mem_init+0x127b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021ea:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01021f0:	89 d8                	mov    %ebx,%eax
f01021f2:	e8 f7 e6 ff ff       	call   f01008ee <check_va2pa>
f01021f7:	39 c6                	cmp    %eax,%esi
f01021f9:	74 19                	je     f0102214 <mem_init+0x1275>
f01021fb:	68 f0 4a 10 f0       	push   $0xf0104af0
f0102200:	68 73 4c 10 f0       	push   $0xf0104c73
f0102205:	68 f5 02 00 00       	push   $0x2f5
f010220a:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010220f:	e8 8c de ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102214:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010221a:	39 fe                	cmp    %edi,%esi
f010221c:	72 cc                	jb     f01021ea <mem_init+0x124b>
f010221e:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102223:	89 f2                	mov    %esi,%edx
f0102225:	89 d8                	mov    %ebx,%eax
f0102227:	e8 c2 e6 ff ff       	call   f01008ee <check_va2pa>
f010222c:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102232:	39 c2                	cmp    %eax,%edx
f0102234:	74 19                	je     f010224f <mem_init+0x12b0>
f0102236:	68 18 4b 10 f0       	push   $0xf0104b18
f010223b:	68 73 4c 10 f0       	push   $0xf0104c73
f0102240:	68 f9 02 00 00       	push   $0x2f9
f0102245:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010224a:	e8 51 de ff ff       	call   f01000a0 <_panic>
f010224f:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102255:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010225b:	75 c6                	jne    f0102223 <mem_init+0x1284>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010225d:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102262:	89 d8                	mov    %ebx,%eax
f0102264:	e8 85 e6 ff ff       	call   f01008ee <check_va2pa>
f0102269:	83 f8 ff             	cmp    $0xffffffff,%eax
f010226c:	74 51                	je     f01022bf <mem_init+0x1320>
f010226e:	68 60 4b 10 f0       	push   $0xf0104b60
f0102273:	68 73 4c 10 f0       	push   $0xf0104c73
f0102278:	68 fa 02 00 00       	push   $0x2fa
f010227d:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102282:	e8 19 de ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102287:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010228c:	72 36                	jb     f01022c4 <mem_init+0x1325>
f010228e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102293:	76 07                	jbe    f010229c <mem_init+0x12fd>
f0102295:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010229a:	75 28                	jne    f01022c4 <mem_init+0x1325>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f010229c:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01022a0:	0f 85 83 00 00 00    	jne    f0102329 <mem_init+0x138a>
f01022a6:	68 00 4f 10 f0       	push   $0xf0104f00
f01022ab:	68 73 4c 10 f0       	push   $0xf0104c73
f01022b0:	68 03 03 00 00       	push   $0x303
f01022b5:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01022ba:	e8 e1 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022bf:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022c4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022c9:	76 3f                	jbe    f010230a <mem_init+0x136b>
				assert(pgdir[i] & PTE_P);
f01022cb:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01022ce:	f6 c2 01             	test   $0x1,%dl
f01022d1:	75 19                	jne    f01022ec <mem_init+0x134d>
f01022d3:	68 00 4f 10 f0       	push   $0xf0104f00
f01022d8:	68 73 4c 10 f0       	push   $0xf0104c73
f01022dd:	68 07 03 00 00       	push   $0x307
f01022e2:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01022e7:	e8 b4 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01022ec:	f6 c2 02             	test   $0x2,%dl
f01022ef:	75 38                	jne    f0102329 <mem_init+0x138a>
f01022f1:	68 11 4f 10 f0       	push   $0xf0104f11
f01022f6:	68 73 4c 10 f0       	push   $0xf0104c73
f01022fb:	68 08 03 00 00       	push   $0x308
f0102300:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102305:	e8 96 dd ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010230a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010230e:	74 19                	je     f0102329 <mem_init+0x138a>
f0102310:	68 22 4f 10 f0       	push   $0xf0104f22
f0102315:	68 73 4c 10 f0       	push   $0xf0104c73
f010231a:	68 0a 03 00 00       	push   $0x30a
f010231f:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102324:	e8 77 dd ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102329:	83 c0 01             	add    $0x1,%eax
f010232c:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102331:	0f 86 50 ff ff ff    	jbe    f0102287 <mem_init+0x12e8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102337:	83 ec 0c             	sub    $0xc,%esp
f010233a:	68 90 4b 10 f0       	push   $0xf0104b90
f010233f:	e8 85 09 00 00       	call   f0102cc9 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102344:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102349:	83 c4 10             	add    $0x10,%esp
f010234c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102351:	77 15                	ja     f0102368 <mem_init+0x13c9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102353:	50                   	push   %eax
f0102354:	68 84 45 10 f0       	push   $0xf0104584
f0102359:	68 de 00 00 00       	push   $0xde
f010235e:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102363:	e8 38 dd ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102368:	05 00 00 00 10       	add    $0x10000000,%eax
f010236d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102370:	b8 00 00 00 00       	mov    $0x0,%eax
f0102375:	e8 d8 e5 ff ff       	call   f0100952 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010237a:	0f 20 c0             	mov    %cr0,%eax
f010237d:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102380:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102385:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102388:	83 ec 0c             	sub    $0xc,%esp
f010238b:	6a 00                	push   $0x0
f010238d:	e8 3d e9 ff ff       	call   f0100ccf <page_alloc>
f0102392:	89 c3                	mov    %eax,%ebx
f0102394:	83 c4 10             	add    $0x10,%esp
f0102397:	85 c0                	test   %eax,%eax
f0102399:	75 19                	jne    f01023b4 <mem_init+0x1415>
f010239b:	68 1e 4d 10 f0       	push   $0xf0104d1e
f01023a0:	68 73 4c 10 f0       	push   $0xf0104c73
f01023a5:	68 c9 03 00 00       	push   $0x3c9
f01023aa:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01023af:	e8 ec dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01023b4:	83 ec 0c             	sub    $0xc,%esp
f01023b7:	6a 00                	push   $0x0
f01023b9:	e8 11 e9 ff ff       	call   f0100ccf <page_alloc>
f01023be:	89 c7                	mov    %eax,%edi
f01023c0:	83 c4 10             	add    $0x10,%esp
f01023c3:	85 c0                	test   %eax,%eax
f01023c5:	75 19                	jne    f01023e0 <mem_init+0x1441>
f01023c7:	68 34 4d 10 f0       	push   $0xf0104d34
f01023cc:	68 73 4c 10 f0       	push   $0xf0104c73
f01023d1:	68 ca 03 00 00       	push   $0x3ca
f01023d6:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01023db:	e8 c0 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01023e0:	83 ec 0c             	sub    $0xc,%esp
f01023e3:	6a 00                	push   $0x0
f01023e5:	e8 e5 e8 ff ff       	call   f0100ccf <page_alloc>
f01023ea:	89 c6                	mov    %eax,%esi
f01023ec:	83 c4 10             	add    $0x10,%esp
f01023ef:	85 c0                	test   %eax,%eax
f01023f1:	75 19                	jne    f010240c <mem_init+0x146d>
f01023f3:	68 4a 4d 10 f0       	push   $0xf0104d4a
f01023f8:	68 73 4c 10 f0       	push   $0xf0104c73
f01023fd:	68 cb 03 00 00       	push   $0x3cb
f0102402:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102407:	e8 94 dc ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f010240c:	83 ec 0c             	sub    $0xc,%esp
f010240f:	53                   	push   %ebx
f0102410:	e8 2a e9 ff ff       	call   f0100d3f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102415:	89 f8                	mov    %edi,%eax
f0102417:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010241d:	c1 f8 03             	sar    $0x3,%eax
f0102420:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102423:	89 c2                	mov    %eax,%edx
f0102425:	c1 ea 0c             	shr    $0xc,%edx
f0102428:	83 c4 10             	add    $0x10,%esp
f010242b:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102431:	72 12                	jb     f0102445 <mem_init+0x14a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102433:	50                   	push   %eax
f0102434:	68 9c 44 10 f0       	push   $0xf010449c
f0102439:	6a 56                	push   $0x56
f010243b:	68 59 4c 10 f0       	push   $0xf0104c59
f0102440:	e8 5b dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102445:	83 ec 04             	sub    $0x4,%esp
f0102448:	68 00 10 00 00       	push   $0x1000
f010244d:	6a 01                	push   $0x1
f010244f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102454:	50                   	push   %eax
f0102455:	e8 01 17 00 00       	call   f0103b5b <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010245a:	89 f0                	mov    %esi,%eax
f010245c:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102462:	c1 f8 03             	sar    $0x3,%eax
f0102465:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102468:	89 c2                	mov    %eax,%edx
f010246a:	c1 ea 0c             	shr    $0xc,%edx
f010246d:	83 c4 10             	add    $0x10,%esp
f0102470:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102476:	72 12                	jb     f010248a <mem_init+0x14eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102478:	50                   	push   %eax
f0102479:	68 9c 44 10 f0       	push   $0xf010449c
f010247e:	6a 56                	push   $0x56
f0102480:	68 59 4c 10 f0       	push   $0xf0104c59
f0102485:	e8 16 dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010248a:	83 ec 04             	sub    $0x4,%esp
f010248d:	68 00 10 00 00       	push   $0x1000
f0102492:	6a 02                	push   $0x2
f0102494:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102499:	50                   	push   %eax
f010249a:	e8 bc 16 00 00       	call   f0103b5b <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010249f:	6a 02                	push   $0x2
f01024a1:	68 00 10 00 00       	push   $0x1000
f01024a6:	57                   	push   %edi
f01024a7:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01024ad:	e8 75 ea ff ff       	call   f0100f27 <page_insert>
	assert(pp1->pp_ref == 1);
f01024b2:	83 c4 20             	add    $0x20,%esp
f01024b5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024ba:	74 19                	je     f01024d5 <mem_init+0x1536>
f01024bc:	68 1b 4e 10 f0       	push   $0xf0104e1b
f01024c1:	68 73 4c 10 f0       	push   $0xf0104c73
f01024c6:	68 d0 03 00 00       	push   $0x3d0
f01024cb:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01024d0:	e8 cb db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024d5:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024dc:	01 01 01 
f01024df:	74 19                	je     f01024fa <mem_init+0x155b>
f01024e1:	68 b0 4b 10 f0       	push   $0xf0104bb0
f01024e6:	68 73 4c 10 f0       	push   $0xf0104c73
f01024eb:	68 d1 03 00 00       	push   $0x3d1
f01024f0:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01024f5:	e8 a6 db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024fa:	6a 02                	push   $0x2
f01024fc:	68 00 10 00 00       	push   $0x1000
f0102501:	56                   	push   %esi
f0102502:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f0102508:	e8 1a ea ff ff       	call   f0100f27 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010250d:	83 c4 10             	add    $0x10,%esp
f0102510:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102517:	02 02 02 
f010251a:	74 19                	je     f0102535 <mem_init+0x1596>
f010251c:	68 d4 4b 10 f0       	push   $0xf0104bd4
f0102521:	68 73 4c 10 f0       	push   $0xf0104c73
f0102526:	68 d3 03 00 00       	push   $0x3d3
f010252b:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102530:	e8 6b db ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102535:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010253a:	74 19                	je     f0102555 <mem_init+0x15b6>
f010253c:	68 3d 4e 10 f0       	push   $0xf0104e3d
f0102541:	68 73 4c 10 f0       	push   $0xf0104c73
f0102546:	68 d4 03 00 00       	push   $0x3d4
f010254b:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102550:	e8 4b db ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102555:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010255a:	74 19                	je     f0102575 <mem_init+0x15d6>
f010255c:	68 a7 4e 10 f0       	push   $0xf0104ea7
f0102561:	68 73 4c 10 f0       	push   $0xf0104c73
f0102566:	68 d5 03 00 00       	push   $0x3d5
f010256b:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102570:	e8 2b db ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102575:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010257c:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010257f:	89 f0                	mov    %esi,%eax
f0102581:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102587:	c1 f8 03             	sar    $0x3,%eax
f010258a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010258d:	89 c2                	mov    %eax,%edx
f010258f:	c1 ea 0c             	shr    $0xc,%edx
f0102592:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102598:	72 12                	jb     f01025ac <mem_init+0x160d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010259a:	50                   	push   %eax
f010259b:	68 9c 44 10 f0       	push   $0xf010449c
f01025a0:	6a 56                	push   $0x56
f01025a2:	68 59 4c 10 f0       	push   $0xf0104c59
f01025a7:	e8 f4 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025ac:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025b3:	03 03 03 
f01025b6:	74 19                	je     f01025d1 <mem_init+0x1632>
f01025b8:	68 f8 4b 10 f0       	push   $0xf0104bf8
f01025bd:	68 73 4c 10 f0       	push   $0xf0104c73
f01025c2:	68 d7 03 00 00       	push   $0x3d7
f01025c7:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01025cc:	e8 cf da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025d1:	83 ec 08             	sub    $0x8,%esp
f01025d4:	68 00 10 00 00       	push   $0x1000
f01025d9:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f01025df:	e8 01 e9 ff ff       	call   f0100ee5 <page_remove>
	assert(pp2->pp_ref == 0);
f01025e4:	83 c4 10             	add    $0x10,%esp
f01025e7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025ec:	74 19                	je     f0102607 <mem_init+0x1668>
f01025ee:	68 75 4e 10 f0       	push   $0xf0104e75
f01025f3:	68 73 4c 10 f0       	push   $0xf0104c73
f01025f8:	68 d9 03 00 00       	push   $0x3d9
f01025fd:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102602:	e8 99 da ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102607:	8b 0d 08 cb 17 f0    	mov    0xf017cb08,%ecx
f010260d:	8b 11                	mov    (%ecx),%edx
f010260f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102615:	89 d8                	mov    %ebx,%eax
f0102617:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010261d:	c1 f8 03             	sar    $0x3,%eax
f0102620:	c1 e0 0c             	shl    $0xc,%eax
f0102623:	39 c2                	cmp    %eax,%edx
f0102625:	74 19                	je     f0102640 <mem_init+0x16a1>
f0102627:	68 04 47 10 f0       	push   $0xf0104704
f010262c:	68 73 4c 10 f0       	push   $0xf0104c73
f0102631:	68 dc 03 00 00       	push   $0x3dc
f0102636:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010263b:	e8 60 da ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102640:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102646:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010264b:	74 19                	je     f0102666 <mem_init+0x16c7>
f010264d:	68 2c 4e 10 f0       	push   $0xf0104e2c
f0102652:	68 73 4c 10 f0       	push   $0xf0104c73
f0102657:	68 de 03 00 00       	push   $0x3de
f010265c:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102661:	e8 3a da ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102666:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010266c:	83 ec 0c             	sub    $0xc,%esp
f010266f:	53                   	push   %ebx
f0102670:	e8 ca e6 ff ff       	call   f0100d3f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102675:	c7 04 24 24 4c 10 f0 	movl   $0xf0104c24,(%esp)
f010267c:	e8 48 06 00 00       	call   f0102cc9 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102681:	83 c4 10             	add    $0x10,%esp
f0102684:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102687:	5b                   	pop    %ebx
f0102688:	5e                   	pop    %esi
f0102689:	5f                   	pop    %edi
f010268a:	5d                   	pop    %ebp
f010268b:	c3                   	ret    

f010268c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010268c:	55                   	push   %ebp
f010268d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010268f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102692:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102695:	5d                   	pop    %ebp
f0102696:	c3                   	ret    

f0102697 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102697:	55                   	push   %ebp
f0102698:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f010269a:	b8 00 00 00 00       	mov    $0x0,%eax
f010269f:	5d                   	pop    %ebp
f01026a0:	c3                   	ret    

f01026a1 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01026a1:	55                   	push   %ebp
f01026a2:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01026a4:	5d                   	pop    %ebp
f01026a5:	c3                   	ret    

f01026a6 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01026a6:	55                   	push   %ebp
f01026a7:	89 e5                	mov    %esp,%ebp
f01026a9:	57                   	push   %edi
f01026aa:	56                   	push   %esi
f01026ab:	53                   	push   %ebx
f01026ac:	83 ec 0c             	sub    $0xc,%esp
f01026af:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
f01026b1:	89 d3                	mov    %edx,%ebx
f01026b3:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
f01026b9:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01026c0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *pp;
	while(low<high)
f01026c6:	eb 5d                	jmp    f0102725 <region_alloc+0x7f>
	{
		pp=page_alloc(1);
f01026c8:	83 ec 0c             	sub    $0xc,%esp
f01026cb:	6a 01                	push   $0x1
f01026cd:	e8 fd e5 ff ff       	call   f0100ccf <page_alloc>
		pp->pp_ref++;
f01026d2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		if(pp==NULL)
f01026d7:	83 c4 10             	add    $0x10,%esp
f01026da:	85 c0                	test   %eax,%eax
f01026dc:	75 17                	jne    f01026f5 <region_alloc+0x4f>
		{
			panic("page_alloc is wrong in region_alloc\n");
f01026de:	83 ec 04             	sub    $0x4,%esp
f01026e1:	68 30 4f 10 f0       	push   $0xf0104f30
f01026e6:	68 1a 01 00 00       	push   $0x11a
f01026eb:	68 c6 4f 10 f0       	push   $0xf0104fc6
f01026f0:	e8 ab d9 ff ff       	call   f01000a0 <_panic>
		}
		int i=page_insert(e->env_pgdir,pp,(void *)low,PTE_P|PTE_U|PTE_W);
f01026f5:	6a 07                	push   $0x7
f01026f7:	53                   	push   %ebx
f01026f8:	50                   	push   %eax
f01026f9:	ff 77 5c             	pushl  0x5c(%edi)
f01026fc:	e8 26 e8 ff ff       	call   f0100f27 <page_insert>
		if(i!=0)
f0102701:	83 c4 10             	add    $0x10,%esp
f0102704:	85 c0                	test   %eax,%eax
f0102706:	74 17                	je     f010271f <region_alloc+0x79>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
f0102708:	83 ec 04             	sub    $0x4,%esp
f010270b:	68 58 4f 10 f0       	push   $0xf0104f58
f0102710:	68 1f 01 00 00       	push   $0x11f
f0102715:	68 c6 4f 10 f0       	push   $0xf0104fc6
f010271a:	e8 81 d9 ff ff       	call   f01000a0 <_panic>
		}
		low=low+PGSIZE;
f010271f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
	struct PageInfo *pp;
	while(low<high)
f0102725:	39 f3                	cmp    %esi,%ebx
f0102727:	72 9f                	jb     f01026c8 <region_alloc+0x22>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
		}
		low=low+PGSIZE;
	}
} 
f0102729:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010272c:	5b                   	pop    %ebx
f010272d:	5e                   	pop    %esi
f010272e:	5f                   	pop    %edi
f010272f:	5d                   	pop    %ebp
f0102730:	c3                   	ret    

f0102731 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102731:	55                   	push   %ebp
f0102732:	89 e5                	mov    %esp,%ebp
f0102734:	8b 55 08             	mov    0x8(%ebp),%edx
f0102737:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010273a:	85 d2                	test   %edx,%edx
f010273c:	75 11                	jne    f010274f <envid2env+0x1e>
		*env_store = curenv;
f010273e:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0102743:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102746:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102748:	b8 00 00 00 00       	mov    $0x0,%eax
f010274d:	eb 5e                	jmp    f01027ad <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010274f:	89 d0                	mov    %edx,%eax
f0102751:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102756:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102759:	c1 e0 05             	shl    $0x5,%eax
f010275c:	03 05 44 be 17 f0    	add    0xf017be44,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102762:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102766:	74 05                	je     f010276d <envid2env+0x3c>
f0102768:	3b 50 48             	cmp    0x48(%eax),%edx
f010276b:	74 10                	je     f010277d <envid2env+0x4c>
		*env_store = 0;
f010276d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102770:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102776:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010277b:	eb 30                	jmp    f01027ad <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010277d:	84 c9                	test   %cl,%cl
f010277f:	74 22                	je     f01027a3 <envid2env+0x72>
f0102781:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102787:	39 d0                	cmp    %edx,%eax
f0102789:	74 18                	je     f01027a3 <envid2env+0x72>
f010278b:	8b 4a 48             	mov    0x48(%edx),%ecx
f010278e:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102791:	74 10                	je     f01027a3 <envid2env+0x72>
		*env_store = 0;
f0102793:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102796:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010279c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027a1:	eb 0a                	jmp    f01027ad <envid2env+0x7c>
	}

	*env_store = e;
f01027a3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027a6:	89 01                	mov    %eax,(%ecx)
	return 0;
f01027a8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027ad:	5d                   	pop    %ebp
f01027ae:	c3                   	ret    

f01027af <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01027af:	55                   	push   %ebp
f01027b0:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01027b2:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01027b7:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01027ba:	b8 23 00 00 00       	mov    $0x23,%eax
f01027bf:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01027c1:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01027c3:	b8 10 00 00 00       	mov    $0x10,%eax
f01027c8:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01027ca:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01027cc:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01027ce:	ea d5 27 10 f0 08 00 	ljmp   $0x8,$0xf01027d5
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01027d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01027da:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01027dd:	5d                   	pop    %ebp
f01027de:	c3                   	ret    

f01027df <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01027df:	55                   	push   %ebp
f01027e0:	89 e5                	mov    %esp,%ebp
f01027e2:	56                   	push   %esi
f01027e3:	53                   	push   %ebx
	// LAB 3: Your code here.
	env_free_list=NULL;
	uint32_t i;
	for(i=NENV-1;i>0;i--)
	{
		envs[i].env_link=env_free_list;
f01027e4:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
f01027ea:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01027f0:	89 f3                	mov    %esi,%ebx
f01027f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01027f7:	89 c1                	mov    %eax,%ecx
f01027f9:	89 50 44             	mov    %edx,0x44(%eax)
f01027fc:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];
f01027ff:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list=NULL;
	uint32_t i;
	for(i=NENV-1;i>0;i--)
f0102801:	39 d8                	cmp    %ebx,%eax
f0102803:	75 f2                	jne    f01027f7 <env_init+0x18>
f0102805:	83 c6 60             	add    $0x60,%esi
f0102808:	89 35 48 be 17 f0    	mov    %esi,0xf017be48
	{
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}		
	// Per-CPU part of the initialization
	env_init_percpu();
f010280e:	e8 9c ff ff ff       	call   f01027af <env_init_percpu>
}
f0102813:	5b                   	pop    %ebx
f0102814:	5e                   	pop    %esi
f0102815:	5d                   	pop    %ebp
f0102816:	c3                   	ret    

f0102817 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102817:	55                   	push   %ebp
f0102818:	89 e5                	mov    %esp,%ebp
f010281a:	53                   	push   %ebx
f010281b:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010281e:	8b 1d 48 be 17 f0    	mov    0xf017be48,%ebx
f0102824:	85 db                	test   %ebx,%ebx
f0102826:	0f 84 25 01 00 00    	je     f0102951 <env_alloc+0x13a>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010282c:	83 ec 0c             	sub    $0xc,%esp
f010282f:	6a 01                	push   $0x1
f0102831:	e8 99 e4 ff ff       	call   f0100ccf <page_alloc>
f0102836:	83 c4 10             	add    $0x10,%esp
f0102839:	85 c0                	test   %eax,%eax
f010283b:	0f 84 17 01 00 00    	je     f0102958 <env_alloc+0x141>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102841:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102846:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f010284c:	c1 f8 03             	sar    $0x3,%eax
f010284f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102852:	89 c2                	mov    %eax,%edx
f0102854:	c1 ea 0c             	shr    $0xc,%edx
f0102857:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f010285d:	72 12                	jb     f0102871 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010285f:	50                   	push   %eax
f0102860:	68 9c 44 10 f0       	push   $0xf010449c
f0102865:	6a 56                	push   $0x56
f0102867:	68 59 4c 10 f0       	push   $0xf0104c59
f010286c:	e8 2f d8 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102871:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
	e->env_pgdir=(pte_t *)page2kva(p);
f0102877:	89 53 5c             	mov    %edx,0x5c(%ebx)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010287a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102880:	77 15                	ja     f0102897 <env_alloc+0x80>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102882:	52                   	push   %edx
f0102883:	68 84 45 10 f0       	push   $0xf0104584
f0102888:	68 c1 00 00 00       	push   $0xc1
f010288d:	68 c6 4f 10 f0       	push   $0xf0104fc6
f0102892:	e8 09 d8 ff ff       	call   f01000a0 <_panic>
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102897:	83 c8 05             	or     $0x5,%eax
f010289a:	89 82 f4 0e 00 00    	mov    %eax,0xef4(%edx)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01028a0:	8b 43 48             	mov    0x48(%ebx),%eax
f01028a3:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01028a8:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01028ad:	ba 00 10 00 00       	mov    $0x1000,%edx
f01028b2:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01028b5:	89 da                	mov    %ebx,%edx
f01028b7:	2b 15 44 be 17 f0    	sub    0xf017be44,%edx
f01028bd:	c1 fa 05             	sar    $0x5,%edx
f01028c0:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01028c6:	09 d0                	or     %edx,%eax
f01028c8:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01028cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028ce:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01028d1:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01028d8:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01028df:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01028e6:	83 ec 04             	sub    $0x4,%esp
f01028e9:	6a 44                	push   $0x44
f01028eb:	6a 00                	push   $0x0
f01028ed:	53                   	push   %ebx
f01028ee:	e8 68 12 00 00       	call   f0103b5b <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01028f3:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01028f9:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01028ff:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102905:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010290c:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102912:	8b 43 44             	mov    0x44(%ebx),%eax
f0102915:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	*newenv_store = e;
f010291a:	8b 45 08             	mov    0x8(%ebp),%eax
f010291d:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010291f:	8b 53 48             	mov    0x48(%ebx),%edx
f0102922:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0102927:	83 c4 10             	add    $0x10,%esp
f010292a:	85 c0                	test   %eax,%eax
f010292c:	74 05                	je     f0102933 <env_alloc+0x11c>
f010292e:	8b 40 48             	mov    0x48(%eax),%eax
f0102931:	eb 05                	jmp    f0102938 <env_alloc+0x121>
f0102933:	b8 00 00 00 00       	mov    $0x0,%eax
f0102938:	83 ec 04             	sub    $0x4,%esp
f010293b:	52                   	push   %edx
f010293c:	50                   	push   %eax
f010293d:	68 d1 4f 10 f0       	push   $0xf0104fd1
f0102942:	e8 82 03 00 00       	call   f0102cc9 <cprintf>
	return 0;
f0102947:	83 c4 10             	add    $0x10,%esp
f010294a:	b8 00 00 00 00       	mov    $0x0,%eax
f010294f:	eb 0c                	jmp    f010295d <env_alloc+0x146>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102951:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102956:	eb 05                	jmp    f010295d <env_alloc+0x146>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102958:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010295d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102960:	c9                   	leave  
f0102961:	c3                   	ret    

f0102962 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102962:	55                   	push   %ebp
f0102963:	89 e5                	mov    %esp,%ebp
f0102965:	57                   	push   %edi
f0102966:	56                   	push   %esi
f0102967:	53                   	push   %ebx
f0102968:	83 ec 34             	sub    $0x34,%esp
f010296b:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f010296e:	6a 00                	push   $0x0
f0102970:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102973:	50                   	push   %eax
f0102974:	e8 9e fe ff ff       	call   f0102817 <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f0102979:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010297c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f010297f:	83 c4 10             	add    $0x10,%esp
f0102982:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102988:	74 17                	je     f01029a1 <env_create+0x3f>
		panic("binary document is error\n");
f010298a:	83 ec 04             	sub    $0x4,%esp
f010298d:	68 e6 4f 10 f0       	push   $0xf0104fe6
f0102992:	68 64 01 00 00       	push   $0x164
f0102997:	68 c6 4f 10 f0       	push   $0xf0104fc6
f010299c:	e8 ff d6 ff ff       	call   f01000a0 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(elf->e_phoff);
f01029a1:	8b 5f 1c             	mov    0x1c(%edi),%ebx
	uint32_t i;
	for(i=0;i<elf->e_phnum;i++)
f01029a4:	be 00 00 00 00       	mov    $0x0,%esi
f01029a9:	eb 45                	jmp    f01029f0 <env_create+0x8e>
	{
		if(ph->p_type==ELF_PROG_LOAD)
f01029ab:	83 3b 01             	cmpl   $0x1,(%ebx)
f01029ae:	75 3a                	jne    f01029ea <env_create+0x88>
		{
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f01029b0:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01029b3:	8b 53 08             	mov    0x8(%ebx),%edx
f01029b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029b9:	e8 e8 fc ff ff       	call   f01026a6 <region_alloc>
			memset((void *)(elf+ph->p_offset),0,ph->p_memsz);
f01029be:	83 ec 04             	sub    $0x4,%esp
f01029c1:	ff 73 14             	pushl  0x14(%ebx)
f01029c4:	6a 00                	push   $0x0
f01029c6:	6b 43 04 34          	imul   $0x34,0x4(%ebx),%eax
f01029ca:	01 f8                	add    %edi,%eax
f01029cc:	50                   	push   %eax
f01029cd:	e8 89 11 00 00       	call   f0103b5b <memset>
			memcpy((void *)(ph->p_va),(void *)(elf+ph->p_offset), ph->p_filesz);
f01029d2:	83 c4 0c             	add    $0xc,%esp
f01029d5:	ff 73 10             	pushl  0x10(%ebx)
f01029d8:	6b 43 04 34          	imul   $0x34,0x4(%ebx),%eax
f01029dc:	01 f8                	add    %edi,%eax
f01029de:	50                   	push   %eax
f01029df:	ff 73 08             	pushl  0x8(%ebx)
f01029e2:	e8 29 12 00 00       	call   f0103c10 <memcpy>
f01029e7:	83 c4 10             	add    $0x10,%esp
		}
		ph++;
f01029ea:	83 c3 20             	add    $0x20,%ebx
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(elf->e_phoff);
	uint32_t i;
	for(i=0;i<elf->e_phnum;i++)
f01029ed:	83 c6 01             	add    $0x1,%esi
f01029f0:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f01029f4:	39 c6                	cmp    %eax,%esi
f01029f6:	72 b3                	jb     f01029ab <env_create+0x49>
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f01029f8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01029fd:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102a02:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a05:	e8 9c fc ff ff       	call   f01026a6 <region_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f0102a0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a0d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a10:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f0102a13:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a16:	5b                   	pop    %ebx
f0102a17:	5e                   	pop    %esi
f0102a18:	5f                   	pop    %edi
f0102a19:	5d                   	pop    %ebp
f0102a1a:	c3                   	ret    

f0102a1b <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102a1b:	55                   	push   %ebp
f0102a1c:	89 e5                	mov    %esp,%ebp
f0102a1e:	57                   	push   %edi
f0102a1f:	56                   	push   %esi
f0102a20:	53                   	push   %ebx
f0102a21:	83 ec 1c             	sub    $0x1c,%esp
f0102a24:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102a27:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102a2d:	39 fa                	cmp    %edi,%edx
f0102a2f:	75 29                	jne    f0102a5a <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102a31:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a36:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a3b:	77 15                	ja     f0102a52 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a3d:	50                   	push   %eax
f0102a3e:	68 84 45 10 f0       	push   $0xf0104584
f0102a43:	68 9c 01 00 00       	push   $0x19c
f0102a48:	68 c6 4f 10 f0       	push   $0xf0104fc6
f0102a4d:	e8 4e d6 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102a52:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a57:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a5a:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102a5d:	85 d2                	test   %edx,%edx
f0102a5f:	74 05                	je     f0102a66 <env_free+0x4b>
f0102a61:	8b 42 48             	mov    0x48(%edx),%eax
f0102a64:	eb 05                	jmp    f0102a6b <env_free+0x50>
f0102a66:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a6b:	83 ec 04             	sub    $0x4,%esp
f0102a6e:	51                   	push   %ecx
f0102a6f:	50                   	push   %eax
f0102a70:	68 00 50 10 f0       	push   $0xf0105000
f0102a75:	e8 4f 02 00 00       	call   f0102cc9 <cprintf>
f0102a7a:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102a7d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102a84:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102a87:	89 d0                	mov    %edx,%eax
f0102a89:	c1 e0 02             	shl    $0x2,%eax
f0102a8c:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102a8f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a92:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102a95:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102a9b:	0f 84 a8 00 00 00    	je     f0102b49 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102aa1:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102aa7:	89 f0                	mov    %esi,%eax
f0102aa9:	c1 e8 0c             	shr    $0xc,%eax
f0102aac:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102aaf:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102ab5:	77 15                	ja     f0102acc <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ab7:	56                   	push   %esi
f0102ab8:	68 9c 44 10 f0       	push   $0xf010449c
f0102abd:	68 ab 01 00 00       	push   $0x1ab
f0102ac2:	68 c6 4f 10 f0       	push   $0xf0104fc6
f0102ac7:	e8 d4 d5 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102acc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102acf:	c1 e0 16             	shl    $0x16,%eax
f0102ad2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ad5:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102ada:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102ae1:	01 
f0102ae2:	74 17                	je     f0102afb <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102ae4:	83 ec 08             	sub    $0x8,%esp
f0102ae7:	89 d8                	mov    %ebx,%eax
f0102ae9:	c1 e0 0c             	shl    $0xc,%eax
f0102aec:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102aef:	50                   	push   %eax
f0102af0:	ff 77 5c             	pushl  0x5c(%edi)
f0102af3:	e8 ed e3 ff ff       	call   f0100ee5 <page_remove>
f0102af8:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102afb:	83 c3 01             	add    $0x1,%ebx
f0102afe:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102b04:	75 d4                	jne    f0102ada <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102b06:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b09:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b0c:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b13:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102b16:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102b1c:	72 14                	jb     f0102b32 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102b1e:	83 ec 04             	sub    $0x4,%esp
f0102b21:	68 d0 45 10 f0       	push   $0xf01045d0
f0102b26:	6a 4f                	push   $0x4f
f0102b28:	68 59 4c 10 f0       	push   $0xf0104c59
f0102b2d:	e8 6e d5 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102b32:	83 ec 0c             	sub    $0xc,%esp
f0102b35:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102b3a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102b3d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102b40:	50                   	push   %eax
f0102b41:	e8 36 e2 ff ff       	call   f0100d7c <page_decref>
f0102b46:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102b49:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102b4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b50:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102b55:	0f 85 29 ff ff ff    	jne    f0102a84 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102b5b:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b5e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b63:	77 15                	ja     f0102b7a <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b65:	50                   	push   %eax
f0102b66:	68 84 45 10 f0       	push   $0xf0104584
f0102b6b:	68 b9 01 00 00       	push   $0x1b9
f0102b70:	68 c6 4f 10 f0       	push   $0xf0104fc6
f0102b75:	e8 26 d5 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102b7a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b81:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b86:	c1 e8 0c             	shr    $0xc,%eax
f0102b89:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102b8f:	72 14                	jb     f0102ba5 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102b91:	83 ec 04             	sub    $0x4,%esp
f0102b94:	68 d0 45 10 f0       	push   $0xf01045d0
f0102b99:	6a 4f                	push   $0x4f
f0102b9b:	68 59 4c 10 f0       	push   $0xf0104c59
f0102ba0:	e8 fb d4 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102ba5:	83 ec 0c             	sub    $0xc,%esp
f0102ba8:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102bae:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102bb1:	50                   	push   %eax
f0102bb2:	e8 c5 e1 ff ff       	call   f0100d7c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102bb7:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102bbe:	a1 48 be 17 f0       	mov    0xf017be48,%eax
f0102bc3:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102bc6:	89 3d 48 be 17 f0    	mov    %edi,0xf017be48
}
f0102bcc:	83 c4 10             	add    $0x10,%esp
f0102bcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bd2:	5b                   	pop    %ebx
f0102bd3:	5e                   	pop    %esi
f0102bd4:	5f                   	pop    %edi
f0102bd5:	5d                   	pop    %ebp
f0102bd6:	c3                   	ret    

f0102bd7 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102bd7:	55                   	push   %ebp
f0102bd8:	89 e5                	mov    %esp,%ebp
f0102bda:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102bdd:	ff 75 08             	pushl  0x8(%ebp)
f0102be0:	e8 36 fe ff ff       	call   f0102a1b <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102be5:	c7 04 24 90 4f 10 f0 	movl   $0xf0104f90,(%esp)
f0102bec:	e8 d8 00 00 00       	call   f0102cc9 <cprintf>
f0102bf1:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102bf4:	83 ec 0c             	sub    $0xc,%esp
f0102bf7:	6a 00                	push   $0x0
f0102bf9:	e8 34 db ff ff       	call   f0100732 <monitor>
f0102bfe:	83 c4 10             	add    $0x10,%esp
f0102c01:	eb f1                	jmp    f0102bf4 <env_destroy+0x1d>

f0102c03 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102c03:	55                   	push   %ebp
f0102c04:	89 e5                	mov    %esp,%ebp
f0102c06:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102c09:	8b 65 08             	mov    0x8(%ebp),%esp
f0102c0c:	61                   	popa   
f0102c0d:	07                   	pop    %es
f0102c0e:	1f                   	pop    %ds
f0102c0f:	83 c4 08             	add    $0x8,%esp
f0102c12:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102c13:	68 16 50 10 f0       	push   $0xf0105016
f0102c18:	68 e2 01 00 00       	push   $0x1e2
f0102c1d:	68 c6 4f 10 f0       	push   $0xf0104fc6
f0102c22:	e8 79 d4 ff ff       	call   f01000a0 <_panic>

f0102c27 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102c27:	55                   	push   %ebp
f0102c28:	89 e5                	mov    %esp,%ebp
f0102c2a:	83 ec 08             	sub    $0x8,%esp
f0102c2d:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0102c30:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0102c36:	85 d2                	test   %edx,%edx
f0102c38:	74 0d                	je     f0102c47 <env_run+0x20>
f0102c3a:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102c3e:	75 07                	jne    f0102c47 <env_run+0x20>
	{
		curenv->env_status=ENV_RUNNABLE;
f0102c40:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv=e;
f0102c47:	a3 40 be 17 f0       	mov    %eax,0xf017be40
	curenv->env_status=ENV_RUNNING;
f0102c4c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
f0102c53:	8b 50 5c             	mov    0x5c(%eax),%edx
f0102c56:	0f 22 da             	mov    %edx,%cr3
	lcr3((uint32_t)curenv->env_pgdir);
	env_pop_tf(&curenv->env_tf);
f0102c59:	83 ec 0c             	sub    $0xc,%esp
f0102c5c:	50                   	push   %eax
f0102c5d:	e8 a1 ff ff ff       	call   f0102c03 <env_pop_tf>

f0102c62 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c62:	55                   	push   %ebp
f0102c63:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c65:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c6d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102c6e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102c73:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102c74:	0f b6 c0             	movzbl %al,%eax
}
f0102c77:	5d                   	pop    %ebp
f0102c78:	c3                   	ret    

f0102c79 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102c79:	55                   	push   %ebp
f0102c7a:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c7c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c81:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c84:	ee                   	out    %al,(%dx)
f0102c85:	ba 71 00 00 00       	mov    $0x71,%edx
f0102c8a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c8d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102c8e:	5d                   	pop    %ebp
f0102c8f:	c3                   	ret    

f0102c90 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102c90:	55                   	push   %ebp
f0102c91:	89 e5                	mov    %esp,%ebp
f0102c93:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102c96:	ff 75 08             	pushl  0x8(%ebp)
f0102c99:	e8 77 d9 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102c9e:	83 c4 10             	add    $0x10,%esp
f0102ca1:	c9                   	leave  
f0102ca2:	c3                   	ret    

f0102ca3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ca3:	55                   	push   %ebp
f0102ca4:	89 e5                	mov    %esp,%ebp
f0102ca6:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ca9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102cb0:	ff 75 0c             	pushl  0xc(%ebp)
f0102cb3:	ff 75 08             	pushl  0x8(%ebp)
f0102cb6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cb9:	50                   	push   %eax
f0102cba:	68 90 2c 10 f0       	push   $0xf0102c90
f0102cbf:	e8 72 07 00 00       	call   f0103436 <vprintfmt>
	return cnt;
}
f0102cc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102cc7:	c9                   	leave  
f0102cc8:	c3                   	ret    

f0102cc9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102cc9:	55                   	push   %ebp
f0102cca:	89 e5                	mov    %esp,%ebp
f0102ccc:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ccf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102cd2:	50                   	push   %eax
f0102cd3:	ff 75 08             	pushl  0x8(%ebp)
f0102cd6:	e8 c8 ff ff ff       	call   f0102ca3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102cdb:	c9                   	leave  
f0102cdc:	c3                   	ret    

f0102cdd <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102cdd:	55                   	push   %ebp
f0102cde:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ce0:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102ce5:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102cec:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102cef:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102cf6:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102cf8:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102cff:	67 00 
f0102d01:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102d07:	89 c2                	mov    %eax,%edx
f0102d09:	c1 ea 10             	shr    $0x10,%edx
f0102d0c:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102d12:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102d19:	c1 e8 18             	shr    $0x18,%eax
f0102d1c:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102d21:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102d28:	b8 28 00 00 00       	mov    $0x28,%eax
f0102d2d:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102d30:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102d35:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102d38:	5d                   	pop    %ebp
f0102d39:	c3                   	ret    

f0102d3a <trap_init>:
}


void
trap_init(void)
{
f0102d3a:	55                   	push   %ebp
f0102d3b:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102d3d:	e8 9b ff ff ff       	call   f0102cdd <trap_init_percpu>
}
f0102d42:	5d                   	pop    %ebp
f0102d43:	c3                   	ret    

f0102d44 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102d44:	55                   	push   %ebp
f0102d45:	89 e5                	mov    %esp,%ebp
f0102d47:	53                   	push   %ebx
f0102d48:	83 ec 0c             	sub    $0xc,%esp
f0102d4b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102d4e:	ff 33                	pushl  (%ebx)
f0102d50:	68 22 50 10 f0       	push   $0xf0105022
f0102d55:	e8 6f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102d5a:	83 c4 08             	add    $0x8,%esp
f0102d5d:	ff 73 04             	pushl  0x4(%ebx)
f0102d60:	68 31 50 10 f0       	push   $0xf0105031
f0102d65:	e8 5f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102d6a:	83 c4 08             	add    $0x8,%esp
f0102d6d:	ff 73 08             	pushl  0x8(%ebx)
f0102d70:	68 40 50 10 f0       	push   $0xf0105040
f0102d75:	e8 4f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102d7a:	83 c4 08             	add    $0x8,%esp
f0102d7d:	ff 73 0c             	pushl  0xc(%ebx)
f0102d80:	68 4f 50 10 f0       	push   $0xf010504f
f0102d85:	e8 3f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102d8a:	83 c4 08             	add    $0x8,%esp
f0102d8d:	ff 73 10             	pushl  0x10(%ebx)
f0102d90:	68 5e 50 10 f0       	push   $0xf010505e
f0102d95:	e8 2f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102d9a:	83 c4 08             	add    $0x8,%esp
f0102d9d:	ff 73 14             	pushl  0x14(%ebx)
f0102da0:	68 6d 50 10 f0       	push   $0xf010506d
f0102da5:	e8 1f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102daa:	83 c4 08             	add    $0x8,%esp
f0102dad:	ff 73 18             	pushl  0x18(%ebx)
f0102db0:	68 7c 50 10 f0       	push   $0xf010507c
f0102db5:	e8 0f ff ff ff       	call   f0102cc9 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102dba:	83 c4 08             	add    $0x8,%esp
f0102dbd:	ff 73 1c             	pushl  0x1c(%ebx)
f0102dc0:	68 8b 50 10 f0       	push   $0xf010508b
f0102dc5:	e8 ff fe ff ff       	call   f0102cc9 <cprintf>
}
f0102dca:	83 c4 10             	add    $0x10,%esp
f0102dcd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dd0:	c9                   	leave  
f0102dd1:	c3                   	ret    

f0102dd2 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102dd2:	55                   	push   %ebp
f0102dd3:	89 e5                	mov    %esp,%ebp
f0102dd5:	56                   	push   %esi
f0102dd6:	53                   	push   %ebx
f0102dd7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102dda:	83 ec 08             	sub    $0x8,%esp
f0102ddd:	53                   	push   %ebx
f0102dde:	68 c1 51 10 f0       	push   $0xf01051c1
f0102de3:	e8 e1 fe ff ff       	call   f0102cc9 <cprintf>
	print_regs(&tf->tf_regs);
f0102de8:	89 1c 24             	mov    %ebx,(%esp)
f0102deb:	e8 54 ff ff ff       	call   f0102d44 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102df0:	83 c4 08             	add    $0x8,%esp
f0102df3:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102df7:	50                   	push   %eax
f0102df8:	68 dc 50 10 f0       	push   $0xf01050dc
f0102dfd:	e8 c7 fe ff ff       	call   f0102cc9 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102e02:	83 c4 08             	add    $0x8,%esp
f0102e05:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102e09:	50                   	push   %eax
f0102e0a:	68 ef 50 10 f0       	push   $0xf01050ef
f0102e0f:	e8 b5 fe ff ff       	call   f0102cc9 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e14:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102e17:	83 c4 10             	add    $0x10,%esp
f0102e1a:	83 f8 13             	cmp    $0x13,%eax
f0102e1d:	77 09                	ja     f0102e28 <print_trapframe+0x56>
		return excnames[trapno];
f0102e1f:	8b 14 85 a0 53 10 f0 	mov    -0xfefac60(,%eax,4),%edx
f0102e26:	eb 10                	jmp    f0102e38 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102e28:	83 f8 30             	cmp    $0x30,%eax
f0102e2b:	b9 a6 50 10 f0       	mov    $0xf01050a6,%ecx
f0102e30:	ba 9a 50 10 f0       	mov    $0xf010509a,%edx
f0102e35:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102e38:	83 ec 04             	sub    $0x4,%esp
f0102e3b:	52                   	push   %edx
f0102e3c:	50                   	push   %eax
f0102e3d:	68 02 51 10 f0       	push   $0xf0105102
f0102e42:	e8 82 fe ff ff       	call   f0102cc9 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102e47:	83 c4 10             	add    $0x10,%esp
f0102e4a:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f0102e50:	75 1a                	jne    f0102e6c <print_trapframe+0x9a>
f0102e52:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102e56:	75 14                	jne    f0102e6c <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102e58:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102e5b:	83 ec 08             	sub    $0x8,%esp
f0102e5e:	50                   	push   %eax
f0102e5f:	68 14 51 10 f0       	push   $0xf0105114
f0102e64:	e8 60 fe ff ff       	call   f0102cc9 <cprintf>
f0102e69:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102e6c:	83 ec 08             	sub    $0x8,%esp
f0102e6f:	ff 73 2c             	pushl  0x2c(%ebx)
f0102e72:	68 23 51 10 f0       	push   $0xf0105123
f0102e77:	e8 4d fe ff ff       	call   f0102cc9 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102e7c:	83 c4 10             	add    $0x10,%esp
f0102e7f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102e83:	75 49                	jne    f0102ece <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102e85:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102e88:	89 c2                	mov    %eax,%edx
f0102e8a:	83 e2 01             	and    $0x1,%edx
f0102e8d:	ba c0 50 10 f0       	mov    $0xf01050c0,%edx
f0102e92:	b9 b5 50 10 f0       	mov    $0xf01050b5,%ecx
f0102e97:	0f 44 ca             	cmove  %edx,%ecx
f0102e9a:	89 c2                	mov    %eax,%edx
f0102e9c:	83 e2 02             	and    $0x2,%edx
f0102e9f:	ba d2 50 10 f0       	mov    $0xf01050d2,%edx
f0102ea4:	be cc 50 10 f0       	mov    $0xf01050cc,%esi
f0102ea9:	0f 45 d6             	cmovne %esi,%edx
f0102eac:	83 e0 04             	and    $0x4,%eax
f0102eaf:	be ec 51 10 f0       	mov    $0xf01051ec,%esi
f0102eb4:	b8 d7 50 10 f0       	mov    $0xf01050d7,%eax
f0102eb9:	0f 44 c6             	cmove  %esi,%eax
f0102ebc:	51                   	push   %ecx
f0102ebd:	52                   	push   %edx
f0102ebe:	50                   	push   %eax
f0102ebf:	68 31 51 10 f0       	push   $0xf0105131
f0102ec4:	e8 00 fe ff ff       	call   f0102cc9 <cprintf>
f0102ec9:	83 c4 10             	add    $0x10,%esp
f0102ecc:	eb 10                	jmp    f0102ede <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102ece:	83 ec 0c             	sub    $0xc,%esp
f0102ed1:	68 fe 4e 10 f0       	push   $0xf0104efe
f0102ed6:	e8 ee fd ff ff       	call   f0102cc9 <cprintf>
f0102edb:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102ede:	83 ec 08             	sub    $0x8,%esp
f0102ee1:	ff 73 30             	pushl  0x30(%ebx)
f0102ee4:	68 40 51 10 f0       	push   $0xf0105140
f0102ee9:	e8 db fd ff ff       	call   f0102cc9 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102eee:	83 c4 08             	add    $0x8,%esp
f0102ef1:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102ef5:	50                   	push   %eax
f0102ef6:	68 4f 51 10 f0       	push   $0xf010514f
f0102efb:	e8 c9 fd ff ff       	call   f0102cc9 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102f00:	83 c4 08             	add    $0x8,%esp
f0102f03:	ff 73 38             	pushl  0x38(%ebx)
f0102f06:	68 62 51 10 f0       	push   $0xf0105162
f0102f0b:	e8 b9 fd ff ff       	call   f0102cc9 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102f10:	83 c4 10             	add    $0x10,%esp
f0102f13:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102f17:	74 25                	je     f0102f3e <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102f19:	83 ec 08             	sub    $0x8,%esp
f0102f1c:	ff 73 3c             	pushl  0x3c(%ebx)
f0102f1f:	68 71 51 10 f0       	push   $0xf0105171
f0102f24:	e8 a0 fd ff ff       	call   f0102cc9 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102f29:	83 c4 08             	add    $0x8,%esp
f0102f2c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102f30:	50                   	push   %eax
f0102f31:	68 80 51 10 f0       	push   $0xf0105180
f0102f36:	e8 8e fd ff ff       	call   f0102cc9 <cprintf>
f0102f3b:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f3e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102f41:	5b                   	pop    %ebx
f0102f42:	5e                   	pop    %esi
f0102f43:	5d                   	pop    %ebp
f0102f44:	c3                   	ret    

f0102f45 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102f45:	55                   	push   %ebp
f0102f46:	89 e5                	mov    %esp,%ebp
f0102f48:	57                   	push   %edi
f0102f49:	56                   	push   %esi
f0102f4a:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102f4d:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0102f4e:	9c                   	pushf  
f0102f4f:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102f50:	f6 c4 02             	test   $0x2,%ah
f0102f53:	74 19                	je     f0102f6e <trap+0x29>
f0102f55:	68 93 51 10 f0       	push   $0xf0105193
f0102f5a:	68 73 4c 10 f0       	push   $0xf0104c73
f0102f5f:	68 a7 00 00 00       	push   $0xa7
f0102f64:	68 ac 51 10 f0       	push   $0xf01051ac
f0102f69:	e8 32 d1 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102f6e:	83 ec 08             	sub    $0x8,%esp
f0102f71:	56                   	push   %esi
f0102f72:	68 b8 51 10 f0       	push   $0xf01051b8
f0102f77:	e8 4d fd ff ff       	call   f0102cc9 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0102f7c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0102f80:	83 e0 03             	and    $0x3,%eax
f0102f83:	83 c4 10             	add    $0x10,%esp
f0102f86:	66 83 f8 03          	cmp    $0x3,%ax
f0102f8a:	75 31                	jne    f0102fbd <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0102f8c:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0102f91:	85 c0                	test   %eax,%eax
f0102f93:	75 19                	jne    f0102fae <trap+0x69>
f0102f95:	68 d3 51 10 f0       	push   $0xf01051d3
f0102f9a:	68 73 4c 10 f0       	push   $0xf0104c73
f0102f9f:	68 ad 00 00 00       	push   $0xad
f0102fa4:	68 ac 51 10 f0       	push   $0xf01051ac
f0102fa9:	e8 f2 d0 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0102fae:	b9 11 00 00 00       	mov    $0x11,%ecx
f0102fb3:	89 c7                	mov    %eax,%edi
f0102fb5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0102fb7:	8b 35 40 be 17 f0    	mov    0xf017be40,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0102fbd:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0102fc3:	83 ec 0c             	sub    $0xc,%esp
f0102fc6:	56                   	push   %esi
f0102fc7:	e8 06 fe ff ff       	call   f0102dd2 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0102fcc:	83 c4 10             	add    $0x10,%esp
f0102fcf:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0102fd4:	75 17                	jne    f0102fed <trap+0xa8>
		panic("unhandled trap in kernel");
f0102fd6:	83 ec 04             	sub    $0x4,%esp
f0102fd9:	68 da 51 10 f0       	push   $0xf01051da
f0102fde:	68 96 00 00 00       	push   $0x96
f0102fe3:	68 ac 51 10 f0       	push   $0xf01051ac
f0102fe8:	e8 b3 d0 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0102fed:	83 ec 0c             	sub    $0xc,%esp
f0102ff0:	ff 35 40 be 17 f0    	pushl  0xf017be40
f0102ff6:	e8 dc fb ff ff       	call   f0102bd7 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0102ffb:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0103000:	83 c4 10             	add    $0x10,%esp
f0103003:	85 c0                	test   %eax,%eax
f0103005:	74 06                	je     f010300d <trap+0xc8>
f0103007:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010300b:	74 19                	je     f0103026 <trap+0xe1>
f010300d:	68 38 53 10 f0       	push   $0xf0105338
f0103012:	68 73 4c 10 f0       	push   $0xf0104c73
f0103017:	68 bf 00 00 00       	push   $0xbf
f010301c:	68 ac 51 10 f0       	push   $0xf01051ac
f0103021:	e8 7a d0 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103026:	83 ec 0c             	sub    $0xc,%esp
f0103029:	50                   	push   %eax
f010302a:	e8 f8 fb ff ff       	call   f0102c27 <env_run>

f010302f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010302f:	55                   	push   %ebp
f0103030:	89 e5                	mov    %esp,%ebp
f0103032:	53                   	push   %ebx
f0103033:	83 ec 04             	sub    $0x4,%esp
f0103036:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103039:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010303c:	ff 73 30             	pushl  0x30(%ebx)
f010303f:	50                   	push   %eax
f0103040:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0103045:	ff 70 48             	pushl  0x48(%eax)
f0103048:	68 64 53 10 f0       	push   $0xf0105364
f010304d:	e8 77 fc ff ff       	call   f0102cc9 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103052:	89 1c 24             	mov    %ebx,(%esp)
f0103055:	e8 78 fd ff ff       	call   f0102dd2 <print_trapframe>
	env_destroy(curenv);
f010305a:	83 c4 04             	add    $0x4,%esp
f010305d:	ff 35 40 be 17 f0    	pushl  0xf017be40
f0103063:	e8 6f fb ff ff       	call   f0102bd7 <env_destroy>
}
f0103068:	83 c4 10             	add    $0x10,%esp
f010306b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010306e:	c9                   	leave  
f010306f:	c3                   	ret    

f0103070 <syscall>:
f0103070:	55                   	push   %ebp
f0103071:	89 e5                	mov    %esp,%ebp
f0103073:	83 ec 0c             	sub    $0xc,%esp
f0103076:	68 f0 53 10 f0       	push   $0xf01053f0
f010307b:	6a 49                	push   $0x49
f010307d:	68 08 54 10 f0       	push   $0xf0105408
f0103082:	e8 19 d0 ff ff       	call   f01000a0 <_panic>

f0103087 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103087:	55                   	push   %ebp
f0103088:	89 e5                	mov    %esp,%ebp
f010308a:	57                   	push   %edi
f010308b:	56                   	push   %esi
f010308c:	53                   	push   %ebx
f010308d:	83 ec 14             	sub    $0x14,%esp
f0103090:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103093:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103096:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103099:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010309c:	8b 1a                	mov    (%edx),%ebx
f010309e:	8b 01                	mov    (%ecx),%eax
f01030a0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030a3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01030aa:	eb 7f                	jmp    f010312b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01030ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030af:	01 d8                	add    %ebx,%eax
f01030b1:	89 c6                	mov    %eax,%esi
f01030b3:	c1 ee 1f             	shr    $0x1f,%esi
f01030b6:	01 c6                	add    %eax,%esi
f01030b8:	d1 fe                	sar    %esi
f01030ba:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01030bd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030c0:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01030c3:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01030c5:	eb 03                	jmp    f01030ca <stab_binsearch+0x43>
			m--;
f01030c7:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01030ca:	39 c3                	cmp    %eax,%ebx
f01030cc:	7f 0d                	jg     f01030db <stab_binsearch+0x54>
f01030ce:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01030d2:	83 ea 0c             	sub    $0xc,%edx
f01030d5:	39 f9                	cmp    %edi,%ecx
f01030d7:	75 ee                	jne    f01030c7 <stab_binsearch+0x40>
f01030d9:	eb 05                	jmp    f01030e0 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01030db:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01030de:	eb 4b                	jmp    f010312b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01030e0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01030e3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030e6:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01030ea:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01030ed:	76 11                	jbe    f0103100 <stab_binsearch+0x79>
			*region_left = m;
f01030ef:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01030f2:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01030f4:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030f7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01030fe:	eb 2b                	jmp    f010312b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103100:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103103:	73 14                	jae    f0103119 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103105:	83 e8 01             	sub    $0x1,%eax
f0103108:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010310b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010310e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103110:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103117:	eb 12                	jmp    f010312b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103119:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010311c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010311e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103122:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103124:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010312b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010312e:	0f 8e 78 ff ff ff    	jle    f01030ac <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103134:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103138:	75 0f                	jne    f0103149 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010313a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010313d:	8b 00                	mov    (%eax),%eax
f010313f:	83 e8 01             	sub    $0x1,%eax
f0103142:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103145:	89 06                	mov    %eax,(%esi)
f0103147:	eb 2c                	jmp    f0103175 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103149:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010314c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010314e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103151:	8b 0e                	mov    (%esi),%ecx
f0103153:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103156:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103159:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010315c:	eb 03                	jmp    f0103161 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010315e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103161:	39 c8                	cmp    %ecx,%eax
f0103163:	7e 0b                	jle    f0103170 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103165:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103169:	83 ea 0c             	sub    $0xc,%edx
f010316c:	39 df                	cmp    %ebx,%edi
f010316e:	75 ee                	jne    f010315e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103170:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103173:	89 06                	mov    %eax,(%esi)
	}
}
f0103175:	83 c4 14             	add    $0x14,%esp
f0103178:	5b                   	pop    %ebx
f0103179:	5e                   	pop    %esi
f010317a:	5f                   	pop    %edi
f010317b:	5d                   	pop    %ebp
f010317c:	c3                   	ret    

f010317d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010317d:	55                   	push   %ebp
f010317e:	89 e5                	mov    %esp,%ebp
f0103180:	57                   	push   %edi
f0103181:	56                   	push   %esi
f0103182:	53                   	push   %ebx
f0103183:	83 ec 2c             	sub    $0x2c,%esp
f0103186:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103189:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010318c:	c7 06 17 54 10 f0    	movl   $0xf0105417,(%esi)
	info->eip_line = 0;
f0103192:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103199:	c7 46 08 17 54 10 f0 	movl   $0xf0105417,0x8(%esi)
	info->eip_fn_namelen = 9;
f01031a0:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01031a7:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01031aa:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01031b1:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01031b7:	77 21                	ja     f01031da <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01031b9:	a1 00 00 20 00       	mov    0x200000,%eax
f01031be:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01031c1:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01031c6:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01031cc:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01031cf:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f01031d5:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01031d8:	eb 1a                	jmp    f01031f4 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01031da:	c7 45 d0 d0 f0 10 f0 	movl   $0xf010f0d0,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01031e1:	c7 45 cc 4d c7 10 f0 	movl   $0xf010c74d,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01031e8:	b8 4c c7 10 f0       	mov    $0xf010c74c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01031ed:	c7 45 d4 30 56 10 f0 	movl   $0xf0105630,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01031f4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01031f7:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f01031fa:	0f 83 2b 01 00 00    	jae    f010332b <debuginfo_eip+0x1ae>
f0103200:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103204:	0f 85 28 01 00 00    	jne    f0103332 <debuginfo_eip+0x1b5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010320a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103211:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103214:	29 d8                	sub    %ebx,%eax
f0103216:	c1 f8 02             	sar    $0x2,%eax
f0103219:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010321f:	83 e8 01             	sub    $0x1,%eax
f0103222:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103225:	57                   	push   %edi
f0103226:	6a 64                	push   $0x64
f0103228:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010322b:	89 c1                	mov    %eax,%ecx
f010322d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103230:	89 d8                	mov    %ebx,%eax
f0103232:	e8 50 fe ff ff       	call   f0103087 <stab_binsearch>
	if (lfile == 0)
f0103237:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010323a:	83 c4 08             	add    $0x8,%esp
f010323d:	85 c0                	test   %eax,%eax
f010323f:	0f 84 f4 00 00 00    	je     f0103339 <debuginfo_eip+0x1bc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103245:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103248:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010324b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010324e:	57                   	push   %edi
f010324f:	6a 24                	push   $0x24
f0103251:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103254:	89 c1                	mov    %eax,%ecx
f0103256:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103259:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010325c:	89 d8                	mov    %ebx,%eax
f010325e:	e8 24 fe ff ff       	call   f0103087 <stab_binsearch>

	if (lfun <= rfun) {
f0103263:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103266:	83 c4 08             	add    $0x8,%esp
f0103269:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010326c:	7f 24                	jg     f0103292 <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010326e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103271:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103274:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103277:	8b 02                	mov    (%edx),%eax
f0103279:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010327c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010327f:	29 f9                	sub    %edi,%ecx
f0103281:	39 c8                	cmp    %ecx,%eax
f0103283:	73 05                	jae    f010328a <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103285:	01 f8                	add    %edi,%eax
f0103287:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010328a:	8b 42 08             	mov    0x8(%edx),%eax
f010328d:	89 46 10             	mov    %eax,0x10(%esi)
f0103290:	eb 06                	jmp    f0103298 <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103292:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103295:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103298:	83 ec 08             	sub    $0x8,%esp
f010329b:	6a 3a                	push   $0x3a
f010329d:	ff 76 08             	pushl  0x8(%esi)
f01032a0:	e8 9a 08 00 00       	call   f0103b3f <strfind>
f01032a5:	2b 46 08             	sub    0x8(%esi),%eax
f01032a8:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01032ae:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01032b1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01032b4:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01032b7:	83 c4 10             	add    $0x10,%esp
f01032ba:	eb 06                	jmp    f01032c2 <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01032bc:	83 eb 01             	sub    $0x1,%ebx
f01032bf:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032c2:	39 fb                	cmp    %edi,%ebx
f01032c4:	7c 2d                	jl     f01032f3 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01032c6:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01032ca:	80 fa 84             	cmp    $0x84,%dl
f01032cd:	74 0b                	je     f01032da <debuginfo_eip+0x15d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01032cf:	80 fa 64             	cmp    $0x64,%dl
f01032d2:	75 e8                	jne    f01032bc <debuginfo_eip+0x13f>
f01032d4:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01032d8:	74 e2                	je     f01032bc <debuginfo_eip+0x13f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01032da:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01032dd:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01032e0:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01032e3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01032e6:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01032e9:	29 f8                	sub    %edi,%eax
f01032eb:	39 c2                	cmp    %eax,%edx
f01032ed:	73 04                	jae    f01032f3 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01032ef:	01 fa                	add    %edi,%edx
f01032f1:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01032f3:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01032f6:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032f9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01032fe:	39 cb                	cmp    %ecx,%ebx
f0103300:	7d 43                	jge    f0103345 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
f0103302:	8d 53 01             	lea    0x1(%ebx),%edx
f0103305:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103308:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010330b:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010330e:	eb 07                	jmp    f0103317 <debuginfo_eip+0x19a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103310:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103314:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103317:	39 ca                	cmp    %ecx,%edx
f0103319:	74 25                	je     f0103340 <debuginfo_eip+0x1c3>
f010331b:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010331e:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0103322:	74 ec                	je     f0103310 <debuginfo_eip+0x193>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103324:	b8 00 00 00 00       	mov    $0x0,%eax
f0103329:	eb 1a                	jmp    f0103345 <debuginfo_eip+0x1c8>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010332b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103330:	eb 13                	jmp    f0103345 <debuginfo_eip+0x1c8>
f0103332:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103337:	eb 0c                	jmp    f0103345 <debuginfo_eip+0x1c8>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103339:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010333e:	eb 05                	jmp    f0103345 <debuginfo_eip+0x1c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103340:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103345:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103348:	5b                   	pop    %ebx
f0103349:	5e                   	pop    %esi
f010334a:	5f                   	pop    %edi
f010334b:	5d                   	pop    %ebp
f010334c:	c3                   	ret    

f010334d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010334d:	55                   	push   %ebp
f010334e:	89 e5                	mov    %esp,%ebp
f0103350:	57                   	push   %edi
f0103351:	56                   	push   %esi
f0103352:	53                   	push   %ebx
f0103353:	83 ec 1c             	sub    $0x1c,%esp
f0103356:	89 c7                	mov    %eax,%edi
f0103358:	89 d6                	mov    %edx,%esi
f010335a:	8b 45 08             	mov    0x8(%ebp),%eax
f010335d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103360:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103363:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103366:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103369:	bb 00 00 00 00       	mov    $0x0,%ebx
f010336e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103371:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103374:	39 d3                	cmp    %edx,%ebx
f0103376:	72 05                	jb     f010337d <printnum+0x30>
f0103378:	39 45 10             	cmp    %eax,0x10(%ebp)
f010337b:	77 45                	ja     f01033c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010337d:	83 ec 0c             	sub    $0xc,%esp
f0103380:	ff 75 18             	pushl  0x18(%ebp)
f0103383:	8b 45 14             	mov    0x14(%ebp),%eax
f0103386:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103389:	53                   	push   %ebx
f010338a:	ff 75 10             	pushl  0x10(%ebp)
f010338d:	83 ec 08             	sub    $0x8,%esp
f0103390:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103393:	ff 75 e0             	pushl  -0x20(%ebp)
f0103396:	ff 75 dc             	pushl  -0x24(%ebp)
f0103399:	ff 75 d8             	pushl  -0x28(%ebp)
f010339c:	e8 bf 09 00 00       	call   f0103d60 <__udivdi3>
f01033a1:	83 c4 18             	add    $0x18,%esp
f01033a4:	52                   	push   %edx
f01033a5:	50                   	push   %eax
f01033a6:	89 f2                	mov    %esi,%edx
f01033a8:	89 f8                	mov    %edi,%eax
f01033aa:	e8 9e ff ff ff       	call   f010334d <printnum>
f01033af:	83 c4 20             	add    $0x20,%esp
f01033b2:	eb 18                	jmp    f01033cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01033b4:	83 ec 08             	sub    $0x8,%esp
f01033b7:	56                   	push   %esi
f01033b8:	ff 75 18             	pushl  0x18(%ebp)
f01033bb:	ff d7                	call   *%edi
f01033bd:	83 c4 10             	add    $0x10,%esp
f01033c0:	eb 03                	jmp    f01033c5 <printnum+0x78>
f01033c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01033c5:	83 eb 01             	sub    $0x1,%ebx
f01033c8:	85 db                	test   %ebx,%ebx
f01033ca:	7f e8                	jg     f01033b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01033cc:	83 ec 08             	sub    $0x8,%esp
f01033cf:	56                   	push   %esi
f01033d0:	83 ec 04             	sub    $0x4,%esp
f01033d3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01033d6:	ff 75 e0             	pushl  -0x20(%ebp)
f01033d9:	ff 75 dc             	pushl  -0x24(%ebp)
f01033dc:	ff 75 d8             	pushl  -0x28(%ebp)
f01033df:	e8 ac 0a 00 00       	call   f0103e90 <__umoddi3>
f01033e4:	83 c4 14             	add    $0x14,%esp
f01033e7:	0f be 80 21 54 10 f0 	movsbl -0xfefabdf(%eax),%eax
f01033ee:	50                   	push   %eax
f01033ef:	ff d7                	call   *%edi
}
f01033f1:	83 c4 10             	add    $0x10,%esp
f01033f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033f7:	5b                   	pop    %ebx
f01033f8:	5e                   	pop    %esi
f01033f9:	5f                   	pop    %edi
f01033fa:	5d                   	pop    %ebp
f01033fb:	c3                   	ret    

f01033fc <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033fc:	55                   	push   %ebp
f01033fd:	89 e5                	mov    %esp,%ebp
f01033ff:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103402:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103406:	8b 10                	mov    (%eax),%edx
f0103408:	3b 50 04             	cmp    0x4(%eax),%edx
f010340b:	73 0a                	jae    f0103417 <sprintputch+0x1b>
		*b->buf++ = ch;
f010340d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103410:	89 08                	mov    %ecx,(%eax)
f0103412:	8b 45 08             	mov    0x8(%ebp),%eax
f0103415:	88 02                	mov    %al,(%edx)
}
f0103417:	5d                   	pop    %ebp
f0103418:	c3                   	ret    

f0103419 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103419:	55                   	push   %ebp
f010341a:	89 e5                	mov    %esp,%ebp
f010341c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010341f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103422:	50                   	push   %eax
f0103423:	ff 75 10             	pushl  0x10(%ebp)
f0103426:	ff 75 0c             	pushl  0xc(%ebp)
f0103429:	ff 75 08             	pushl  0x8(%ebp)
f010342c:	e8 05 00 00 00       	call   f0103436 <vprintfmt>
	va_end(ap);
}
f0103431:	83 c4 10             	add    $0x10,%esp
f0103434:	c9                   	leave  
f0103435:	c3                   	ret    

f0103436 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103436:	55                   	push   %ebp
f0103437:	89 e5                	mov    %esp,%ebp
f0103439:	57                   	push   %edi
f010343a:	56                   	push   %esi
f010343b:	53                   	push   %ebx
f010343c:	83 ec 2c             	sub    $0x2c,%esp
f010343f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103442:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103445:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103448:	eb 12                	jmp    f010345c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010344a:	85 c0                	test   %eax,%eax
f010344c:	0f 84 42 04 00 00    	je     f0103894 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103452:	83 ec 08             	sub    $0x8,%esp
f0103455:	53                   	push   %ebx
f0103456:	50                   	push   %eax
f0103457:	ff d6                	call   *%esi
f0103459:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010345c:	83 c7 01             	add    $0x1,%edi
f010345f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103463:	83 f8 25             	cmp    $0x25,%eax
f0103466:	75 e2                	jne    f010344a <vprintfmt+0x14>
f0103468:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010346c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103473:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010347a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103481:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103486:	eb 07                	jmp    f010348f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103488:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010348b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010348f:	8d 47 01             	lea    0x1(%edi),%eax
f0103492:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103495:	0f b6 07             	movzbl (%edi),%eax
f0103498:	0f b6 d0             	movzbl %al,%edx
f010349b:	83 e8 23             	sub    $0x23,%eax
f010349e:	3c 55                	cmp    $0x55,%al
f01034a0:	0f 87 d3 03 00 00    	ja     f0103879 <vprintfmt+0x443>
f01034a6:	0f b6 c0             	movzbl %al,%eax
f01034a9:	ff 24 85 ac 54 10 f0 	jmp    *-0xfefab54(,%eax,4)
f01034b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01034b3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01034b7:	eb d6                	jmp    f010348f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01034c1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01034c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01034c7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01034cb:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01034ce:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01034d1:	83 f9 09             	cmp    $0x9,%ecx
f01034d4:	77 3f                	ja     f0103515 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01034d6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01034d9:	eb e9                	jmp    f01034c4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01034db:	8b 45 14             	mov    0x14(%ebp),%eax
f01034de:	8b 00                	mov    (%eax),%eax
f01034e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01034e6:	8d 40 04             	lea    0x4(%eax),%eax
f01034e9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01034ef:	eb 2a                	jmp    f010351b <vprintfmt+0xe5>
f01034f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034f4:	85 c0                	test   %eax,%eax
f01034f6:	ba 00 00 00 00       	mov    $0x0,%edx
f01034fb:	0f 49 d0             	cmovns %eax,%edx
f01034fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103501:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103504:	eb 89                	jmp    f010348f <vprintfmt+0x59>
f0103506:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103509:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103510:	e9 7a ff ff ff       	jmp    f010348f <vprintfmt+0x59>
f0103515:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103518:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010351b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010351f:	0f 89 6a ff ff ff    	jns    f010348f <vprintfmt+0x59>
				width = precision, precision = -1;
f0103525:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103528:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010352b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103532:	e9 58 ff ff ff       	jmp    f010348f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103537:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010353a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010353d:	e9 4d ff ff ff       	jmp    f010348f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103542:	8b 45 14             	mov    0x14(%ebp),%eax
f0103545:	8d 78 04             	lea    0x4(%eax),%edi
f0103548:	83 ec 08             	sub    $0x8,%esp
f010354b:	53                   	push   %ebx
f010354c:	ff 30                	pushl  (%eax)
f010354e:	ff d6                	call   *%esi
			break;
f0103550:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103553:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103556:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103559:	e9 fe fe ff ff       	jmp    f010345c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010355e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103561:	8d 78 04             	lea    0x4(%eax),%edi
f0103564:	8b 00                	mov    (%eax),%eax
f0103566:	99                   	cltd   
f0103567:	31 d0                	xor    %edx,%eax
f0103569:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010356b:	83 f8 06             	cmp    $0x6,%eax
f010356e:	7f 0b                	jg     f010357b <vprintfmt+0x145>
f0103570:	8b 14 85 04 56 10 f0 	mov    -0xfefa9fc(,%eax,4),%edx
f0103577:	85 d2                	test   %edx,%edx
f0103579:	75 1b                	jne    f0103596 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f010357b:	50                   	push   %eax
f010357c:	68 39 54 10 f0       	push   $0xf0105439
f0103581:	53                   	push   %ebx
f0103582:	56                   	push   %esi
f0103583:	e8 91 fe ff ff       	call   f0103419 <printfmt>
f0103588:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010358b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010358e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103591:	e9 c6 fe ff ff       	jmp    f010345c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103596:	52                   	push   %edx
f0103597:	68 85 4c 10 f0       	push   $0xf0104c85
f010359c:	53                   	push   %ebx
f010359d:	56                   	push   %esi
f010359e:	e8 76 fe ff ff       	call   f0103419 <printfmt>
f01035a3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01035a6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035ac:	e9 ab fe ff ff       	jmp    f010345c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01035b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01035b4:	83 c0 04             	add    $0x4,%eax
f01035b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01035ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01035bd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01035bf:	85 ff                	test   %edi,%edi
f01035c1:	b8 32 54 10 f0       	mov    $0xf0105432,%eax
f01035c6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01035c9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035cd:	0f 8e 94 00 00 00    	jle    f0103667 <vprintfmt+0x231>
f01035d3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01035d7:	0f 84 98 00 00 00    	je     f0103675 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01035dd:	83 ec 08             	sub    $0x8,%esp
f01035e0:	ff 75 d0             	pushl  -0x30(%ebp)
f01035e3:	57                   	push   %edi
f01035e4:	e8 0c 04 00 00       	call   f01039f5 <strnlen>
f01035e9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01035ec:	29 c1                	sub    %eax,%ecx
f01035ee:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01035f1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01035f4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01035f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01035fb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01035fe:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103600:	eb 0f                	jmp    f0103611 <vprintfmt+0x1db>
					putch(padc, putdat);
f0103602:	83 ec 08             	sub    $0x8,%esp
f0103605:	53                   	push   %ebx
f0103606:	ff 75 e0             	pushl  -0x20(%ebp)
f0103609:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010360b:	83 ef 01             	sub    $0x1,%edi
f010360e:	83 c4 10             	add    $0x10,%esp
f0103611:	85 ff                	test   %edi,%edi
f0103613:	7f ed                	jg     f0103602 <vprintfmt+0x1cc>
f0103615:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103618:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010361b:	85 c9                	test   %ecx,%ecx
f010361d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103622:	0f 49 c1             	cmovns %ecx,%eax
f0103625:	29 c1                	sub    %eax,%ecx
f0103627:	89 75 08             	mov    %esi,0x8(%ebp)
f010362a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010362d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103630:	89 cb                	mov    %ecx,%ebx
f0103632:	eb 4d                	jmp    f0103681 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103634:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103638:	74 1b                	je     f0103655 <vprintfmt+0x21f>
f010363a:	0f be c0             	movsbl %al,%eax
f010363d:	83 e8 20             	sub    $0x20,%eax
f0103640:	83 f8 5e             	cmp    $0x5e,%eax
f0103643:	76 10                	jbe    f0103655 <vprintfmt+0x21f>
					putch('?', putdat);
f0103645:	83 ec 08             	sub    $0x8,%esp
f0103648:	ff 75 0c             	pushl  0xc(%ebp)
f010364b:	6a 3f                	push   $0x3f
f010364d:	ff 55 08             	call   *0x8(%ebp)
f0103650:	83 c4 10             	add    $0x10,%esp
f0103653:	eb 0d                	jmp    f0103662 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103655:	83 ec 08             	sub    $0x8,%esp
f0103658:	ff 75 0c             	pushl  0xc(%ebp)
f010365b:	52                   	push   %edx
f010365c:	ff 55 08             	call   *0x8(%ebp)
f010365f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103662:	83 eb 01             	sub    $0x1,%ebx
f0103665:	eb 1a                	jmp    f0103681 <vprintfmt+0x24b>
f0103667:	89 75 08             	mov    %esi,0x8(%ebp)
f010366a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010366d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103670:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103673:	eb 0c                	jmp    f0103681 <vprintfmt+0x24b>
f0103675:	89 75 08             	mov    %esi,0x8(%ebp)
f0103678:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010367b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010367e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103681:	83 c7 01             	add    $0x1,%edi
f0103684:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103688:	0f be d0             	movsbl %al,%edx
f010368b:	85 d2                	test   %edx,%edx
f010368d:	74 23                	je     f01036b2 <vprintfmt+0x27c>
f010368f:	85 f6                	test   %esi,%esi
f0103691:	78 a1                	js     f0103634 <vprintfmt+0x1fe>
f0103693:	83 ee 01             	sub    $0x1,%esi
f0103696:	79 9c                	jns    f0103634 <vprintfmt+0x1fe>
f0103698:	89 df                	mov    %ebx,%edi
f010369a:	8b 75 08             	mov    0x8(%ebp),%esi
f010369d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01036a0:	eb 18                	jmp    f01036ba <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01036a2:	83 ec 08             	sub    $0x8,%esp
f01036a5:	53                   	push   %ebx
f01036a6:	6a 20                	push   $0x20
f01036a8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01036aa:	83 ef 01             	sub    $0x1,%edi
f01036ad:	83 c4 10             	add    $0x10,%esp
f01036b0:	eb 08                	jmp    f01036ba <vprintfmt+0x284>
f01036b2:	89 df                	mov    %ebx,%edi
f01036b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01036b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01036ba:	85 ff                	test   %edi,%edi
f01036bc:	7f e4                	jg     f01036a2 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01036be:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01036c1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036c7:	e9 90 fd ff ff       	jmp    f010345c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01036cc:	83 f9 01             	cmp    $0x1,%ecx
f01036cf:	7e 19                	jle    f01036ea <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f01036d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01036d4:	8b 50 04             	mov    0x4(%eax),%edx
f01036d7:	8b 00                	mov    (%eax),%eax
f01036d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036dc:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036df:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e2:	8d 40 08             	lea    0x8(%eax),%eax
f01036e5:	89 45 14             	mov    %eax,0x14(%ebp)
f01036e8:	eb 38                	jmp    f0103722 <vprintfmt+0x2ec>
	else if (lflag)
f01036ea:	85 c9                	test   %ecx,%ecx
f01036ec:	74 1b                	je     f0103709 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f01036ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f1:	8b 00                	mov    (%eax),%eax
f01036f3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036f6:	89 c1                	mov    %eax,%ecx
f01036f8:	c1 f9 1f             	sar    $0x1f,%ecx
f01036fb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01036fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103701:	8d 40 04             	lea    0x4(%eax),%eax
f0103704:	89 45 14             	mov    %eax,0x14(%ebp)
f0103707:	eb 19                	jmp    f0103722 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103709:	8b 45 14             	mov    0x14(%ebp),%eax
f010370c:	8b 00                	mov    (%eax),%eax
f010370e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103711:	89 c1                	mov    %eax,%ecx
f0103713:	c1 f9 1f             	sar    $0x1f,%ecx
f0103716:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103719:	8b 45 14             	mov    0x14(%ebp),%eax
f010371c:	8d 40 04             	lea    0x4(%eax),%eax
f010371f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103722:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103725:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103728:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010372d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103731:	0f 89 0e 01 00 00    	jns    f0103845 <vprintfmt+0x40f>
				putch('-', putdat);
f0103737:	83 ec 08             	sub    $0x8,%esp
f010373a:	53                   	push   %ebx
f010373b:	6a 2d                	push   $0x2d
f010373d:	ff d6                	call   *%esi
				num = -(long long) num;
f010373f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103742:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103745:	f7 da                	neg    %edx
f0103747:	83 d1 00             	adc    $0x0,%ecx
f010374a:	f7 d9                	neg    %ecx
f010374c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010374f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103754:	e9 ec 00 00 00       	jmp    f0103845 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103759:	83 f9 01             	cmp    $0x1,%ecx
f010375c:	7e 18                	jle    f0103776 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010375e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103761:	8b 10                	mov    (%eax),%edx
f0103763:	8b 48 04             	mov    0x4(%eax),%ecx
f0103766:	8d 40 08             	lea    0x8(%eax),%eax
f0103769:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010376c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103771:	e9 cf 00 00 00       	jmp    f0103845 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103776:	85 c9                	test   %ecx,%ecx
f0103778:	74 1a                	je     f0103794 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f010377a:	8b 45 14             	mov    0x14(%ebp),%eax
f010377d:	8b 10                	mov    (%eax),%edx
f010377f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103784:	8d 40 04             	lea    0x4(%eax),%eax
f0103787:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010378a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010378f:	e9 b1 00 00 00       	jmp    f0103845 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103794:	8b 45 14             	mov    0x14(%ebp),%eax
f0103797:	8b 10                	mov    (%eax),%edx
f0103799:	b9 00 00 00 00       	mov    $0x0,%ecx
f010379e:	8d 40 04             	lea    0x4(%eax),%eax
f01037a1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01037a4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037a9:	e9 97 00 00 00       	jmp    f0103845 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01037ae:	83 ec 08             	sub    $0x8,%esp
f01037b1:	53                   	push   %ebx
f01037b2:	6a 58                	push   $0x58
f01037b4:	ff d6                	call   *%esi
			putch('X', putdat);
f01037b6:	83 c4 08             	add    $0x8,%esp
f01037b9:	53                   	push   %ebx
f01037ba:	6a 58                	push   $0x58
f01037bc:	ff d6                	call   *%esi
			putch('X', putdat);
f01037be:	83 c4 08             	add    $0x8,%esp
f01037c1:	53                   	push   %ebx
f01037c2:	6a 58                	push   $0x58
f01037c4:	ff d6                	call   *%esi
			break;
f01037c6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01037cc:	e9 8b fc ff ff       	jmp    f010345c <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01037d1:	83 ec 08             	sub    $0x8,%esp
f01037d4:	53                   	push   %ebx
f01037d5:	6a 30                	push   $0x30
f01037d7:	ff d6                	call   *%esi
			putch('x', putdat);
f01037d9:	83 c4 08             	add    $0x8,%esp
f01037dc:	53                   	push   %ebx
f01037dd:	6a 78                	push   $0x78
f01037df:	ff d6                	call   *%esi
			num = (unsigned long long)
f01037e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01037e4:	8b 10                	mov    (%eax),%edx
f01037e6:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01037eb:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01037ee:	8d 40 04             	lea    0x4(%eax),%eax
f01037f1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037f4:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01037f9:	eb 4a                	jmp    f0103845 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01037fb:	83 f9 01             	cmp    $0x1,%ecx
f01037fe:	7e 15                	jle    f0103815 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103800:	8b 45 14             	mov    0x14(%ebp),%eax
f0103803:	8b 10                	mov    (%eax),%edx
f0103805:	8b 48 04             	mov    0x4(%eax),%ecx
f0103808:	8d 40 08             	lea    0x8(%eax),%eax
f010380b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010380e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103813:	eb 30                	jmp    f0103845 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103815:	85 c9                	test   %ecx,%ecx
f0103817:	74 17                	je     f0103830 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103819:	8b 45 14             	mov    0x14(%ebp),%eax
f010381c:	8b 10                	mov    (%eax),%edx
f010381e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103823:	8d 40 04             	lea    0x4(%eax),%eax
f0103826:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103829:	b8 10 00 00 00       	mov    $0x10,%eax
f010382e:	eb 15                	jmp    f0103845 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103830:	8b 45 14             	mov    0x14(%ebp),%eax
f0103833:	8b 10                	mov    (%eax),%edx
f0103835:	b9 00 00 00 00       	mov    $0x0,%ecx
f010383a:	8d 40 04             	lea    0x4(%eax),%eax
f010383d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103840:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103845:	83 ec 0c             	sub    $0xc,%esp
f0103848:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010384c:	57                   	push   %edi
f010384d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103850:	50                   	push   %eax
f0103851:	51                   	push   %ecx
f0103852:	52                   	push   %edx
f0103853:	89 da                	mov    %ebx,%edx
f0103855:	89 f0                	mov    %esi,%eax
f0103857:	e8 f1 fa ff ff       	call   f010334d <printnum>
			break;
f010385c:	83 c4 20             	add    $0x20,%esp
f010385f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103862:	e9 f5 fb ff ff       	jmp    f010345c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103867:	83 ec 08             	sub    $0x8,%esp
f010386a:	53                   	push   %ebx
f010386b:	52                   	push   %edx
f010386c:	ff d6                	call   *%esi
			break;
f010386e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103871:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103874:	e9 e3 fb ff ff       	jmp    f010345c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103879:	83 ec 08             	sub    $0x8,%esp
f010387c:	53                   	push   %ebx
f010387d:	6a 25                	push   $0x25
f010387f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103881:	83 c4 10             	add    $0x10,%esp
f0103884:	eb 03                	jmp    f0103889 <vprintfmt+0x453>
f0103886:	83 ef 01             	sub    $0x1,%edi
f0103889:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010388d:	75 f7                	jne    f0103886 <vprintfmt+0x450>
f010388f:	e9 c8 fb ff ff       	jmp    f010345c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103894:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103897:	5b                   	pop    %ebx
f0103898:	5e                   	pop    %esi
f0103899:	5f                   	pop    %edi
f010389a:	5d                   	pop    %ebp
f010389b:	c3                   	ret    

f010389c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010389c:	55                   	push   %ebp
f010389d:	89 e5                	mov    %esp,%ebp
f010389f:	83 ec 18             	sub    $0x18,%esp
f01038a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01038a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038a8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038ab:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038af:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038b2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038b9:	85 c0                	test   %eax,%eax
f01038bb:	74 26                	je     f01038e3 <vsnprintf+0x47>
f01038bd:	85 d2                	test   %edx,%edx
f01038bf:	7e 22                	jle    f01038e3 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038c1:	ff 75 14             	pushl  0x14(%ebp)
f01038c4:	ff 75 10             	pushl  0x10(%ebp)
f01038c7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038ca:	50                   	push   %eax
f01038cb:	68 fc 33 10 f0       	push   $0xf01033fc
f01038d0:	e8 61 fb ff ff       	call   f0103436 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01038d5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01038d8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01038db:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01038de:	83 c4 10             	add    $0x10,%esp
f01038e1:	eb 05                	jmp    f01038e8 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01038e3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01038e8:	c9                   	leave  
f01038e9:	c3                   	ret    

f01038ea <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01038ea:	55                   	push   %ebp
f01038eb:	89 e5                	mov    %esp,%ebp
f01038ed:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01038f0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01038f3:	50                   	push   %eax
f01038f4:	ff 75 10             	pushl  0x10(%ebp)
f01038f7:	ff 75 0c             	pushl  0xc(%ebp)
f01038fa:	ff 75 08             	pushl  0x8(%ebp)
f01038fd:	e8 9a ff ff ff       	call   f010389c <vsnprintf>
	va_end(ap);

	return rc;
}
f0103902:	c9                   	leave  
f0103903:	c3                   	ret    

f0103904 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103904:	55                   	push   %ebp
f0103905:	89 e5                	mov    %esp,%ebp
f0103907:	57                   	push   %edi
f0103908:	56                   	push   %esi
f0103909:	53                   	push   %ebx
f010390a:	83 ec 0c             	sub    $0xc,%esp
f010390d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103910:	85 c0                	test   %eax,%eax
f0103912:	74 11                	je     f0103925 <readline+0x21>
		cprintf("%s", prompt);
f0103914:	83 ec 08             	sub    $0x8,%esp
f0103917:	50                   	push   %eax
f0103918:	68 85 4c 10 f0       	push   $0xf0104c85
f010391d:	e8 a7 f3 ff ff       	call   f0102cc9 <cprintf>
f0103922:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103925:	83 ec 0c             	sub    $0xc,%esp
f0103928:	6a 00                	push   $0x0
f010392a:	e8 07 cd ff ff       	call   f0100636 <iscons>
f010392f:	89 c7                	mov    %eax,%edi
f0103931:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103934:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103939:	e8 e7 cc ff ff       	call   f0100625 <getchar>
f010393e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103940:	85 c0                	test   %eax,%eax
f0103942:	79 18                	jns    f010395c <readline+0x58>
			cprintf("read error: %e\n", c);
f0103944:	83 ec 08             	sub    $0x8,%esp
f0103947:	50                   	push   %eax
f0103948:	68 20 56 10 f0       	push   $0xf0105620
f010394d:	e8 77 f3 ff ff       	call   f0102cc9 <cprintf>
			return NULL;
f0103952:	83 c4 10             	add    $0x10,%esp
f0103955:	b8 00 00 00 00       	mov    $0x0,%eax
f010395a:	eb 79                	jmp    f01039d5 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010395c:	83 f8 08             	cmp    $0x8,%eax
f010395f:	0f 94 c2             	sete   %dl
f0103962:	83 f8 7f             	cmp    $0x7f,%eax
f0103965:	0f 94 c0             	sete   %al
f0103968:	08 c2                	or     %al,%dl
f010396a:	74 1a                	je     f0103986 <readline+0x82>
f010396c:	85 f6                	test   %esi,%esi
f010396e:	7e 16                	jle    f0103986 <readline+0x82>
			if (echoing)
f0103970:	85 ff                	test   %edi,%edi
f0103972:	74 0d                	je     f0103981 <readline+0x7d>
				cputchar('\b');
f0103974:	83 ec 0c             	sub    $0xc,%esp
f0103977:	6a 08                	push   $0x8
f0103979:	e8 97 cc ff ff       	call   f0100615 <cputchar>
f010397e:	83 c4 10             	add    $0x10,%esp
			i--;
f0103981:	83 ee 01             	sub    $0x1,%esi
f0103984:	eb b3                	jmp    f0103939 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103986:	83 fb 1f             	cmp    $0x1f,%ebx
f0103989:	7e 23                	jle    f01039ae <readline+0xaa>
f010398b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103991:	7f 1b                	jg     f01039ae <readline+0xaa>
			if (echoing)
f0103993:	85 ff                	test   %edi,%edi
f0103995:	74 0c                	je     f01039a3 <readline+0x9f>
				cputchar(c);
f0103997:	83 ec 0c             	sub    $0xc,%esp
f010399a:	53                   	push   %ebx
f010399b:	e8 75 cc ff ff       	call   f0100615 <cputchar>
f01039a0:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01039a3:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f01039a9:	8d 76 01             	lea    0x1(%esi),%esi
f01039ac:	eb 8b                	jmp    f0103939 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01039ae:	83 fb 0a             	cmp    $0xa,%ebx
f01039b1:	74 05                	je     f01039b8 <readline+0xb4>
f01039b3:	83 fb 0d             	cmp    $0xd,%ebx
f01039b6:	75 81                	jne    f0103939 <readline+0x35>
			if (echoing)
f01039b8:	85 ff                	test   %edi,%edi
f01039ba:	74 0d                	je     f01039c9 <readline+0xc5>
				cputchar('\n');
f01039bc:	83 ec 0c             	sub    $0xc,%esp
f01039bf:	6a 0a                	push   $0xa
f01039c1:	e8 4f cc ff ff       	call   f0100615 <cputchar>
f01039c6:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01039c9:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f01039d0:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f01039d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039d8:	5b                   	pop    %ebx
f01039d9:	5e                   	pop    %esi
f01039da:	5f                   	pop    %edi
f01039db:	5d                   	pop    %ebp
f01039dc:	c3                   	ret    

f01039dd <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01039dd:	55                   	push   %ebp
f01039de:	89 e5                	mov    %esp,%ebp
f01039e0:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01039e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01039e8:	eb 03                	jmp    f01039ed <strlen+0x10>
		n++;
f01039ea:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01039ed:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01039f1:	75 f7                	jne    f01039ea <strlen+0xd>
		n++;
	return n;
}
f01039f3:	5d                   	pop    %ebp
f01039f4:	c3                   	ret    

f01039f5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01039f5:	55                   	push   %ebp
f01039f6:	89 e5                	mov    %esp,%ebp
f01039f8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039fb:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039fe:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a03:	eb 03                	jmp    f0103a08 <strnlen+0x13>
		n++;
f0103a05:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a08:	39 c2                	cmp    %eax,%edx
f0103a0a:	74 08                	je     f0103a14 <strnlen+0x1f>
f0103a0c:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103a10:	75 f3                	jne    f0103a05 <strnlen+0x10>
f0103a12:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103a14:	5d                   	pop    %ebp
f0103a15:	c3                   	ret    

f0103a16 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a16:	55                   	push   %ebp
f0103a17:	89 e5                	mov    %esp,%ebp
f0103a19:	53                   	push   %ebx
f0103a1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a1d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a20:	89 c2                	mov    %eax,%edx
f0103a22:	83 c2 01             	add    $0x1,%edx
f0103a25:	83 c1 01             	add    $0x1,%ecx
f0103a28:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103a2c:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103a2f:	84 db                	test   %bl,%bl
f0103a31:	75 ef                	jne    f0103a22 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a33:	5b                   	pop    %ebx
f0103a34:	5d                   	pop    %ebp
f0103a35:	c3                   	ret    

f0103a36 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a36:	55                   	push   %ebp
f0103a37:	89 e5                	mov    %esp,%ebp
f0103a39:	53                   	push   %ebx
f0103a3a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a3d:	53                   	push   %ebx
f0103a3e:	e8 9a ff ff ff       	call   f01039dd <strlen>
f0103a43:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103a46:	ff 75 0c             	pushl  0xc(%ebp)
f0103a49:	01 d8                	add    %ebx,%eax
f0103a4b:	50                   	push   %eax
f0103a4c:	e8 c5 ff ff ff       	call   f0103a16 <strcpy>
	return dst;
}
f0103a51:	89 d8                	mov    %ebx,%eax
f0103a53:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a56:	c9                   	leave  
f0103a57:	c3                   	ret    

f0103a58 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a58:	55                   	push   %ebp
f0103a59:	89 e5                	mov    %esp,%ebp
f0103a5b:	56                   	push   %esi
f0103a5c:	53                   	push   %ebx
f0103a5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a60:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a63:	89 f3                	mov    %esi,%ebx
f0103a65:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a68:	89 f2                	mov    %esi,%edx
f0103a6a:	eb 0f                	jmp    f0103a7b <strncpy+0x23>
		*dst++ = *src;
f0103a6c:	83 c2 01             	add    $0x1,%edx
f0103a6f:	0f b6 01             	movzbl (%ecx),%eax
f0103a72:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a75:	80 39 01             	cmpb   $0x1,(%ecx)
f0103a78:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a7b:	39 da                	cmp    %ebx,%edx
f0103a7d:	75 ed                	jne    f0103a6c <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103a7f:	89 f0                	mov    %esi,%eax
f0103a81:	5b                   	pop    %ebx
f0103a82:	5e                   	pop    %esi
f0103a83:	5d                   	pop    %ebp
f0103a84:	c3                   	ret    

f0103a85 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a85:	55                   	push   %ebp
f0103a86:	89 e5                	mov    %esp,%ebp
f0103a88:	56                   	push   %esi
f0103a89:	53                   	push   %ebx
f0103a8a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a8d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103a90:	8b 55 10             	mov    0x10(%ebp),%edx
f0103a93:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a95:	85 d2                	test   %edx,%edx
f0103a97:	74 21                	je     f0103aba <strlcpy+0x35>
f0103a99:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103a9d:	89 f2                	mov    %esi,%edx
f0103a9f:	eb 09                	jmp    f0103aaa <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103aa1:	83 c2 01             	add    $0x1,%edx
f0103aa4:	83 c1 01             	add    $0x1,%ecx
f0103aa7:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103aaa:	39 c2                	cmp    %eax,%edx
f0103aac:	74 09                	je     f0103ab7 <strlcpy+0x32>
f0103aae:	0f b6 19             	movzbl (%ecx),%ebx
f0103ab1:	84 db                	test   %bl,%bl
f0103ab3:	75 ec                	jne    f0103aa1 <strlcpy+0x1c>
f0103ab5:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103ab7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103aba:	29 f0                	sub    %esi,%eax
}
f0103abc:	5b                   	pop    %ebx
f0103abd:	5e                   	pop    %esi
f0103abe:	5d                   	pop    %ebp
f0103abf:	c3                   	ret    

f0103ac0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103ac0:	55                   	push   %ebp
f0103ac1:	89 e5                	mov    %esp,%ebp
f0103ac3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ac6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103ac9:	eb 06                	jmp    f0103ad1 <strcmp+0x11>
		p++, q++;
f0103acb:	83 c1 01             	add    $0x1,%ecx
f0103ace:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103ad1:	0f b6 01             	movzbl (%ecx),%eax
f0103ad4:	84 c0                	test   %al,%al
f0103ad6:	74 04                	je     f0103adc <strcmp+0x1c>
f0103ad8:	3a 02                	cmp    (%edx),%al
f0103ada:	74 ef                	je     f0103acb <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103adc:	0f b6 c0             	movzbl %al,%eax
f0103adf:	0f b6 12             	movzbl (%edx),%edx
f0103ae2:	29 d0                	sub    %edx,%eax
}
f0103ae4:	5d                   	pop    %ebp
f0103ae5:	c3                   	ret    

f0103ae6 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103ae6:	55                   	push   %ebp
f0103ae7:	89 e5                	mov    %esp,%ebp
f0103ae9:	53                   	push   %ebx
f0103aea:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aed:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103af0:	89 c3                	mov    %eax,%ebx
f0103af2:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103af5:	eb 06                	jmp    f0103afd <strncmp+0x17>
		n--, p++, q++;
f0103af7:	83 c0 01             	add    $0x1,%eax
f0103afa:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103afd:	39 d8                	cmp    %ebx,%eax
f0103aff:	74 15                	je     f0103b16 <strncmp+0x30>
f0103b01:	0f b6 08             	movzbl (%eax),%ecx
f0103b04:	84 c9                	test   %cl,%cl
f0103b06:	74 04                	je     f0103b0c <strncmp+0x26>
f0103b08:	3a 0a                	cmp    (%edx),%cl
f0103b0a:	74 eb                	je     f0103af7 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b0c:	0f b6 00             	movzbl (%eax),%eax
f0103b0f:	0f b6 12             	movzbl (%edx),%edx
f0103b12:	29 d0                	sub    %edx,%eax
f0103b14:	eb 05                	jmp    f0103b1b <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b16:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103b1b:	5b                   	pop    %ebx
f0103b1c:	5d                   	pop    %ebp
f0103b1d:	c3                   	ret    

f0103b1e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b1e:	55                   	push   %ebp
f0103b1f:	89 e5                	mov    %esp,%ebp
f0103b21:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b24:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b28:	eb 07                	jmp    f0103b31 <strchr+0x13>
		if (*s == c)
f0103b2a:	38 ca                	cmp    %cl,%dl
f0103b2c:	74 0f                	je     f0103b3d <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b2e:	83 c0 01             	add    $0x1,%eax
f0103b31:	0f b6 10             	movzbl (%eax),%edx
f0103b34:	84 d2                	test   %dl,%dl
f0103b36:	75 f2                	jne    f0103b2a <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b38:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b3d:	5d                   	pop    %ebp
f0103b3e:	c3                   	ret    

f0103b3f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b3f:	55                   	push   %ebp
f0103b40:	89 e5                	mov    %esp,%ebp
f0103b42:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b45:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b49:	eb 03                	jmp    f0103b4e <strfind+0xf>
f0103b4b:	83 c0 01             	add    $0x1,%eax
f0103b4e:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103b51:	38 ca                	cmp    %cl,%dl
f0103b53:	74 04                	je     f0103b59 <strfind+0x1a>
f0103b55:	84 d2                	test   %dl,%dl
f0103b57:	75 f2                	jne    f0103b4b <strfind+0xc>
			break;
	return (char *) s;
}
f0103b59:	5d                   	pop    %ebp
f0103b5a:	c3                   	ret    

f0103b5b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b5b:	55                   	push   %ebp
f0103b5c:	89 e5                	mov    %esp,%ebp
f0103b5e:	57                   	push   %edi
f0103b5f:	56                   	push   %esi
f0103b60:	53                   	push   %ebx
f0103b61:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b64:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103b67:	85 c9                	test   %ecx,%ecx
f0103b69:	74 36                	je     f0103ba1 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103b6b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103b71:	75 28                	jne    f0103b9b <memset+0x40>
f0103b73:	f6 c1 03             	test   $0x3,%cl
f0103b76:	75 23                	jne    f0103b9b <memset+0x40>
		c &= 0xFF;
f0103b78:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103b7c:	89 d3                	mov    %edx,%ebx
f0103b7e:	c1 e3 08             	shl    $0x8,%ebx
f0103b81:	89 d6                	mov    %edx,%esi
f0103b83:	c1 e6 18             	shl    $0x18,%esi
f0103b86:	89 d0                	mov    %edx,%eax
f0103b88:	c1 e0 10             	shl    $0x10,%eax
f0103b8b:	09 f0                	or     %esi,%eax
f0103b8d:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103b8f:	89 d8                	mov    %ebx,%eax
f0103b91:	09 d0                	or     %edx,%eax
f0103b93:	c1 e9 02             	shr    $0x2,%ecx
f0103b96:	fc                   	cld    
f0103b97:	f3 ab                	rep stos %eax,%es:(%edi)
f0103b99:	eb 06                	jmp    f0103ba1 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b9e:	fc                   	cld    
f0103b9f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103ba1:	89 f8                	mov    %edi,%eax
f0103ba3:	5b                   	pop    %ebx
f0103ba4:	5e                   	pop    %esi
f0103ba5:	5f                   	pop    %edi
f0103ba6:	5d                   	pop    %ebp
f0103ba7:	c3                   	ret    

f0103ba8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ba8:	55                   	push   %ebp
f0103ba9:	89 e5                	mov    %esp,%ebp
f0103bab:	57                   	push   %edi
f0103bac:	56                   	push   %esi
f0103bad:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bb0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103bb3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103bb6:	39 c6                	cmp    %eax,%esi
f0103bb8:	73 35                	jae    f0103bef <memmove+0x47>
f0103bba:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103bbd:	39 d0                	cmp    %edx,%eax
f0103bbf:	73 2e                	jae    f0103bef <memmove+0x47>
		s += n;
		d += n;
f0103bc1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bc4:	89 d6                	mov    %edx,%esi
f0103bc6:	09 fe                	or     %edi,%esi
f0103bc8:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103bce:	75 13                	jne    f0103be3 <memmove+0x3b>
f0103bd0:	f6 c1 03             	test   $0x3,%cl
f0103bd3:	75 0e                	jne    f0103be3 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103bd5:	83 ef 04             	sub    $0x4,%edi
f0103bd8:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103bdb:	c1 e9 02             	shr    $0x2,%ecx
f0103bde:	fd                   	std    
f0103bdf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103be1:	eb 09                	jmp    f0103bec <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103be3:	83 ef 01             	sub    $0x1,%edi
f0103be6:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103be9:	fd                   	std    
f0103bea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103bec:	fc                   	cld    
f0103bed:	eb 1d                	jmp    f0103c0c <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bef:	89 f2                	mov    %esi,%edx
f0103bf1:	09 c2                	or     %eax,%edx
f0103bf3:	f6 c2 03             	test   $0x3,%dl
f0103bf6:	75 0f                	jne    f0103c07 <memmove+0x5f>
f0103bf8:	f6 c1 03             	test   $0x3,%cl
f0103bfb:	75 0a                	jne    f0103c07 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103bfd:	c1 e9 02             	shr    $0x2,%ecx
f0103c00:	89 c7                	mov    %eax,%edi
f0103c02:	fc                   	cld    
f0103c03:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c05:	eb 05                	jmp    f0103c0c <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c07:	89 c7                	mov    %eax,%edi
f0103c09:	fc                   	cld    
f0103c0a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c0c:	5e                   	pop    %esi
f0103c0d:	5f                   	pop    %edi
f0103c0e:	5d                   	pop    %ebp
f0103c0f:	c3                   	ret    

f0103c10 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c10:	55                   	push   %ebp
f0103c11:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103c13:	ff 75 10             	pushl  0x10(%ebp)
f0103c16:	ff 75 0c             	pushl  0xc(%ebp)
f0103c19:	ff 75 08             	pushl  0x8(%ebp)
f0103c1c:	e8 87 ff ff ff       	call   f0103ba8 <memmove>
}
f0103c21:	c9                   	leave  
f0103c22:	c3                   	ret    

f0103c23 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c23:	55                   	push   %ebp
f0103c24:	89 e5                	mov    %esp,%ebp
f0103c26:	56                   	push   %esi
f0103c27:	53                   	push   %ebx
f0103c28:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c2b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c2e:	89 c6                	mov    %eax,%esi
f0103c30:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c33:	eb 1a                	jmp    f0103c4f <memcmp+0x2c>
		if (*s1 != *s2)
f0103c35:	0f b6 08             	movzbl (%eax),%ecx
f0103c38:	0f b6 1a             	movzbl (%edx),%ebx
f0103c3b:	38 d9                	cmp    %bl,%cl
f0103c3d:	74 0a                	je     f0103c49 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103c3f:	0f b6 c1             	movzbl %cl,%eax
f0103c42:	0f b6 db             	movzbl %bl,%ebx
f0103c45:	29 d8                	sub    %ebx,%eax
f0103c47:	eb 0f                	jmp    f0103c58 <memcmp+0x35>
		s1++, s2++;
f0103c49:	83 c0 01             	add    $0x1,%eax
f0103c4c:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c4f:	39 f0                	cmp    %esi,%eax
f0103c51:	75 e2                	jne    f0103c35 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103c53:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c58:	5b                   	pop    %ebx
f0103c59:	5e                   	pop    %esi
f0103c5a:	5d                   	pop    %ebp
f0103c5b:	c3                   	ret    

f0103c5c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c5c:	55                   	push   %ebp
f0103c5d:	89 e5                	mov    %esp,%ebp
f0103c5f:	53                   	push   %ebx
f0103c60:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103c63:	89 c1                	mov    %eax,%ecx
f0103c65:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c68:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103c6c:	eb 0a                	jmp    f0103c78 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c6e:	0f b6 10             	movzbl (%eax),%edx
f0103c71:	39 da                	cmp    %ebx,%edx
f0103c73:	74 07                	je     f0103c7c <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103c75:	83 c0 01             	add    $0x1,%eax
f0103c78:	39 c8                	cmp    %ecx,%eax
f0103c7a:	72 f2                	jb     f0103c6e <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103c7c:	5b                   	pop    %ebx
f0103c7d:	5d                   	pop    %ebp
f0103c7e:	c3                   	ret    

f0103c7f <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103c7f:	55                   	push   %ebp
f0103c80:	89 e5                	mov    %esp,%ebp
f0103c82:	57                   	push   %edi
f0103c83:	56                   	push   %esi
f0103c84:	53                   	push   %ebx
f0103c85:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c88:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c8b:	eb 03                	jmp    f0103c90 <strtol+0x11>
		s++;
f0103c8d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103c90:	0f b6 01             	movzbl (%ecx),%eax
f0103c93:	3c 20                	cmp    $0x20,%al
f0103c95:	74 f6                	je     f0103c8d <strtol+0xe>
f0103c97:	3c 09                	cmp    $0x9,%al
f0103c99:	74 f2                	je     f0103c8d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103c9b:	3c 2b                	cmp    $0x2b,%al
f0103c9d:	75 0a                	jne    f0103ca9 <strtol+0x2a>
		s++;
f0103c9f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ca2:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ca7:	eb 11                	jmp    f0103cba <strtol+0x3b>
f0103ca9:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103cae:	3c 2d                	cmp    $0x2d,%al
f0103cb0:	75 08                	jne    f0103cba <strtol+0x3b>
		s++, neg = 1;
f0103cb2:	83 c1 01             	add    $0x1,%ecx
f0103cb5:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103cba:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103cc0:	75 15                	jne    f0103cd7 <strtol+0x58>
f0103cc2:	80 39 30             	cmpb   $0x30,(%ecx)
f0103cc5:	75 10                	jne    f0103cd7 <strtol+0x58>
f0103cc7:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103ccb:	75 7c                	jne    f0103d49 <strtol+0xca>
		s += 2, base = 16;
f0103ccd:	83 c1 02             	add    $0x2,%ecx
f0103cd0:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103cd5:	eb 16                	jmp    f0103ced <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103cd7:	85 db                	test   %ebx,%ebx
f0103cd9:	75 12                	jne    f0103ced <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103cdb:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ce0:	80 39 30             	cmpb   $0x30,(%ecx)
f0103ce3:	75 08                	jne    f0103ced <strtol+0x6e>
		s++, base = 8;
f0103ce5:	83 c1 01             	add    $0x1,%ecx
f0103ce8:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103ced:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cf2:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103cf5:	0f b6 11             	movzbl (%ecx),%edx
f0103cf8:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103cfb:	89 f3                	mov    %esi,%ebx
f0103cfd:	80 fb 09             	cmp    $0x9,%bl
f0103d00:	77 08                	ja     f0103d0a <strtol+0x8b>
			dig = *s - '0';
f0103d02:	0f be d2             	movsbl %dl,%edx
f0103d05:	83 ea 30             	sub    $0x30,%edx
f0103d08:	eb 22                	jmp    f0103d2c <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103d0a:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103d0d:	89 f3                	mov    %esi,%ebx
f0103d0f:	80 fb 19             	cmp    $0x19,%bl
f0103d12:	77 08                	ja     f0103d1c <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103d14:	0f be d2             	movsbl %dl,%edx
f0103d17:	83 ea 57             	sub    $0x57,%edx
f0103d1a:	eb 10                	jmp    f0103d2c <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103d1c:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103d1f:	89 f3                	mov    %esi,%ebx
f0103d21:	80 fb 19             	cmp    $0x19,%bl
f0103d24:	77 16                	ja     f0103d3c <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103d26:	0f be d2             	movsbl %dl,%edx
f0103d29:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103d2c:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103d2f:	7d 0b                	jge    f0103d3c <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103d31:	83 c1 01             	add    $0x1,%ecx
f0103d34:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103d38:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103d3a:	eb b9                	jmp    f0103cf5 <strtol+0x76>

	if (endptr)
f0103d3c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d40:	74 0d                	je     f0103d4f <strtol+0xd0>
		*endptr = (char *) s;
f0103d42:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d45:	89 0e                	mov    %ecx,(%esi)
f0103d47:	eb 06                	jmp    f0103d4f <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d49:	85 db                	test   %ebx,%ebx
f0103d4b:	74 98                	je     f0103ce5 <strtol+0x66>
f0103d4d:	eb 9e                	jmp    f0103ced <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103d4f:	89 c2                	mov    %eax,%edx
f0103d51:	f7 da                	neg    %edx
f0103d53:	85 ff                	test   %edi,%edi
f0103d55:	0f 45 c2             	cmovne %edx,%eax
}
f0103d58:	5b                   	pop    %ebx
f0103d59:	5e                   	pop    %esi
f0103d5a:	5f                   	pop    %edi
f0103d5b:	5d                   	pop    %ebp
f0103d5c:	c3                   	ret    
f0103d5d:	66 90                	xchg   %ax,%ax
f0103d5f:	90                   	nop

f0103d60 <__udivdi3>:
f0103d60:	55                   	push   %ebp
f0103d61:	57                   	push   %edi
f0103d62:	56                   	push   %esi
f0103d63:	53                   	push   %ebx
f0103d64:	83 ec 1c             	sub    $0x1c,%esp
f0103d67:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103d6b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103d6f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103d73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103d77:	85 f6                	test   %esi,%esi
f0103d79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103d7d:	89 ca                	mov    %ecx,%edx
f0103d7f:	89 f8                	mov    %edi,%eax
f0103d81:	75 3d                	jne    f0103dc0 <__udivdi3+0x60>
f0103d83:	39 cf                	cmp    %ecx,%edi
f0103d85:	0f 87 c5 00 00 00    	ja     f0103e50 <__udivdi3+0xf0>
f0103d8b:	85 ff                	test   %edi,%edi
f0103d8d:	89 fd                	mov    %edi,%ebp
f0103d8f:	75 0b                	jne    f0103d9c <__udivdi3+0x3c>
f0103d91:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d96:	31 d2                	xor    %edx,%edx
f0103d98:	f7 f7                	div    %edi
f0103d9a:	89 c5                	mov    %eax,%ebp
f0103d9c:	89 c8                	mov    %ecx,%eax
f0103d9e:	31 d2                	xor    %edx,%edx
f0103da0:	f7 f5                	div    %ebp
f0103da2:	89 c1                	mov    %eax,%ecx
f0103da4:	89 d8                	mov    %ebx,%eax
f0103da6:	89 cf                	mov    %ecx,%edi
f0103da8:	f7 f5                	div    %ebp
f0103daa:	89 c3                	mov    %eax,%ebx
f0103dac:	89 d8                	mov    %ebx,%eax
f0103dae:	89 fa                	mov    %edi,%edx
f0103db0:	83 c4 1c             	add    $0x1c,%esp
f0103db3:	5b                   	pop    %ebx
f0103db4:	5e                   	pop    %esi
f0103db5:	5f                   	pop    %edi
f0103db6:	5d                   	pop    %ebp
f0103db7:	c3                   	ret    
f0103db8:	90                   	nop
f0103db9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103dc0:	39 ce                	cmp    %ecx,%esi
f0103dc2:	77 74                	ja     f0103e38 <__udivdi3+0xd8>
f0103dc4:	0f bd fe             	bsr    %esi,%edi
f0103dc7:	83 f7 1f             	xor    $0x1f,%edi
f0103dca:	0f 84 98 00 00 00    	je     f0103e68 <__udivdi3+0x108>
f0103dd0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103dd5:	89 f9                	mov    %edi,%ecx
f0103dd7:	89 c5                	mov    %eax,%ebp
f0103dd9:	29 fb                	sub    %edi,%ebx
f0103ddb:	d3 e6                	shl    %cl,%esi
f0103ddd:	89 d9                	mov    %ebx,%ecx
f0103ddf:	d3 ed                	shr    %cl,%ebp
f0103de1:	89 f9                	mov    %edi,%ecx
f0103de3:	d3 e0                	shl    %cl,%eax
f0103de5:	09 ee                	or     %ebp,%esi
f0103de7:	89 d9                	mov    %ebx,%ecx
f0103de9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ded:	89 d5                	mov    %edx,%ebp
f0103def:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103df3:	d3 ed                	shr    %cl,%ebp
f0103df5:	89 f9                	mov    %edi,%ecx
f0103df7:	d3 e2                	shl    %cl,%edx
f0103df9:	89 d9                	mov    %ebx,%ecx
f0103dfb:	d3 e8                	shr    %cl,%eax
f0103dfd:	09 c2                	or     %eax,%edx
f0103dff:	89 d0                	mov    %edx,%eax
f0103e01:	89 ea                	mov    %ebp,%edx
f0103e03:	f7 f6                	div    %esi
f0103e05:	89 d5                	mov    %edx,%ebp
f0103e07:	89 c3                	mov    %eax,%ebx
f0103e09:	f7 64 24 0c          	mull   0xc(%esp)
f0103e0d:	39 d5                	cmp    %edx,%ebp
f0103e0f:	72 10                	jb     f0103e21 <__udivdi3+0xc1>
f0103e11:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103e15:	89 f9                	mov    %edi,%ecx
f0103e17:	d3 e6                	shl    %cl,%esi
f0103e19:	39 c6                	cmp    %eax,%esi
f0103e1b:	73 07                	jae    f0103e24 <__udivdi3+0xc4>
f0103e1d:	39 d5                	cmp    %edx,%ebp
f0103e1f:	75 03                	jne    f0103e24 <__udivdi3+0xc4>
f0103e21:	83 eb 01             	sub    $0x1,%ebx
f0103e24:	31 ff                	xor    %edi,%edi
f0103e26:	89 d8                	mov    %ebx,%eax
f0103e28:	89 fa                	mov    %edi,%edx
f0103e2a:	83 c4 1c             	add    $0x1c,%esp
f0103e2d:	5b                   	pop    %ebx
f0103e2e:	5e                   	pop    %esi
f0103e2f:	5f                   	pop    %edi
f0103e30:	5d                   	pop    %ebp
f0103e31:	c3                   	ret    
f0103e32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e38:	31 ff                	xor    %edi,%edi
f0103e3a:	31 db                	xor    %ebx,%ebx
f0103e3c:	89 d8                	mov    %ebx,%eax
f0103e3e:	89 fa                	mov    %edi,%edx
f0103e40:	83 c4 1c             	add    $0x1c,%esp
f0103e43:	5b                   	pop    %ebx
f0103e44:	5e                   	pop    %esi
f0103e45:	5f                   	pop    %edi
f0103e46:	5d                   	pop    %ebp
f0103e47:	c3                   	ret    
f0103e48:	90                   	nop
f0103e49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e50:	89 d8                	mov    %ebx,%eax
f0103e52:	f7 f7                	div    %edi
f0103e54:	31 ff                	xor    %edi,%edi
f0103e56:	89 c3                	mov    %eax,%ebx
f0103e58:	89 d8                	mov    %ebx,%eax
f0103e5a:	89 fa                	mov    %edi,%edx
f0103e5c:	83 c4 1c             	add    $0x1c,%esp
f0103e5f:	5b                   	pop    %ebx
f0103e60:	5e                   	pop    %esi
f0103e61:	5f                   	pop    %edi
f0103e62:	5d                   	pop    %ebp
f0103e63:	c3                   	ret    
f0103e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e68:	39 ce                	cmp    %ecx,%esi
f0103e6a:	72 0c                	jb     f0103e78 <__udivdi3+0x118>
f0103e6c:	31 db                	xor    %ebx,%ebx
f0103e6e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103e72:	0f 87 34 ff ff ff    	ja     f0103dac <__udivdi3+0x4c>
f0103e78:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103e7d:	e9 2a ff ff ff       	jmp    f0103dac <__udivdi3+0x4c>
f0103e82:	66 90                	xchg   %ax,%ax
f0103e84:	66 90                	xchg   %ax,%ax
f0103e86:	66 90                	xchg   %ax,%ax
f0103e88:	66 90                	xchg   %ax,%ax
f0103e8a:	66 90                	xchg   %ax,%ax
f0103e8c:	66 90                	xchg   %ax,%ax
f0103e8e:	66 90                	xchg   %ax,%ax

f0103e90 <__umoddi3>:
f0103e90:	55                   	push   %ebp
f0103e91:	57                   	push   %edi
f0103e92:	56                   	push   %esi
f0103e93:	53                   	push   %ebx
f0103e94:	83 ec 1c             	sub    $0x1c,%esp
f0103e97:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103e9b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103e9f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103ea3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ea7:	85 d2                	test   %edx,%edx
f0103ea9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ead:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103eb1:	89 f3                	mov    %esi,%ebx
f0103eb3:	89 3c 24             	mov    %edi,(%esp)
f0103eb6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103eba:	75 1c                	jne    f0103ed8 <__umoddi3+0x48>
f0103ebc:	39 f7                	cmp    %esi,%edi
f0103ebe:	76 50                	jbe    f0103f10 <__umoddi3+0x80>
f0103ec0:	89 c8                	mov    %ecx,%eax
f0103ec2:	89 f2                	mov    %esi,%edx
f0103ec4:	f7 f7                	div    %edi
f0103ec6:	89 d0                	mov    %edx,%eax
f0103ec8:	31 d2                	xor    %edx,%edx
f0103eca:	83 c4 1c             	add    $0x1c,%esp
f0103ecd:	5b                   	pop    %ebx
f0103ece:	5e                   	pop    %esi
f0103ecf:	5f                   	pop    %edi
f0103ed0:	5d                   	pop    %ebp
f0103ed1:	c3                   	ret    
f0103ed2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ed8:	39 f2                	cmp    %esi,%edx
f0103eda:	89 d0                	mov    %edx,%eax
f0103edc:	77 52                	ja     f0103f30 <__umoddi3+0xa0>
f0103ede:	0f bd ea             	bsr    %edx,%ebp
f0103ee1:	83 f5 1f             	xor    $0x1f,%ebp
f0103ee4:	75 5a                	jne    f0103f40 <__umoddi3+0xb0>
f0103ee6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103eea:	0f 82 e0 00 00 00    	jb     f0103fd0 <__umoddi3+0x140>
f0103ef0:	39 0c 24             	cmp    %ecx,(%esp)
f0103ef3:	0f 86 d7 00 00 00    	jbe    f0103fd0 <__umoddi3+0x140>
f0103ef9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103efd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103f01:	83 c4 1c             	add    $0x1c,%esp
f0103f04:	5b                   	pop    %ebx
f0103f05:	5e                   	pop    %esi
f0103f06:	5f                   	pop    %edi
f0103f07:	5d                   	pop    %ebp
f0103f08:	c3                   	ret    
f0103f09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f10:	85 ff                	test   %edi,%edi
f0103f12:	89 fd                	mov    %edi,%ebp
f0103f14:	75 0b                	jne    f0103f21 <__umoddi3+0x91>
f0103f16:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f1b:	31 d2                	xor    %edx,%edx
f0103f1d:	f7 f7                	div    %edi
f0103f1f:	89 c5                	mov    %eax,%ebp
f0103f21:	89 f0                	mov    %esi,%eax
f0103f23:	31 d2                	xor    %edx,%edx
f0103f25:	f7 f5                	div    %ebp
f0103f27:	89 c8                	mov    %ecx,%eax
f0103f29:	f7 f5                	div    %ebp
f0103f2b:	89 d0                	mov    %edx,%eax
f0103f2d:	eb 99                	jmp    f0103ec8 <__umoddi3+0x38>
f0103f2f:	90                   	nop
f0103f30:	89 c8                	mov    %ecx,%eax
f0103f32:	89 f2                	mov    %esi,%edx
f0103f34:	83 c4 1c             	add    $0x1c,%esp
f0103f37:	5b                   	pop    %ebx
f0103f38:	5e                   	pop    %esi
f0103f39:	5f                   	pop    %edi
f0103f3a:	5d                   	pop    %ebp
f0103f3b:	c3                   	ret    
f0103f3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f40:	8b 34 24             	mov    (%esp),%esi
f0103f43:	bf 20 00 00 00       	mov    $0x20,%edi
f0103f48:	89 e9                	mov    %ebp,%ecx
f0103f4a:	29 ef                	sub    %ebp,%edi
f0103f4c:	d3 e0                	shl    %cl,%eax
f0103f4e:	89 f9                	mov    %edi,%ecx
f0103f50:	89 f2                	mov    %esi,%edx
f0103f52:	d3 ea                	shr    %cl,%edx
f0103f54:	89 e9                	mov    %ebp,%ecx
f0103f56:	09 c2                	or     %eax,%edx
f0103f58:	89 d8                	mov    %ebx,%eax
f0103f5a:	89 14 24             	mov    %edx,(%esp)
f0103f5d:	89 f2                	mov    %esi,%edx
f0103f5f:	d3 e2                	shl    %cl,%edx
f0103f61:	89 f9                	mov    %edi,%ecx
f0103f63:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f67:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103f6b:	d3 e8                	shr    %cl,%eax
f0103f6d:	89 e9                	mov    %ebp,%ecx
f0103f6f:	89 c6                	mov    %eax,%esi
f0103f71:	d3 e3                	shl    %cl,%ebx
f0103f73:	89 f9                	mov    %edi,%ecx
f0103f75:	89 d0                	mov    %edx,%eax
f0103f77:	d3 e8                	shr    %cl,%eax
f0103f79:	89 e9                	mov    %ebp,%ecx
f0103f7b:	09 d8                	or     %ebx,%eax
f0103f7d:	89 d3                	mov    %edx,%ebx
f0103f7f:	89 f2                	mov    %esi,%edx
f0103f81:	f7 34 24             	divl   (%esp)
f0103f84:	89 d6                	mov    %edx,%esi
f0103f86:	d3 e3                	shl    %cl,%ebx
f0103f88:	f7 64 24 04          	mull   0x4(%esp)
f0103f8c:	39 d6                	cmp    %edx,%esi
f0103f8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103f92:	89 d1                	mov    %edx,%ecx
f0103f94:	89 c3                	mov    %eax,%ebx
f0103f96:	72 08                	jb     f0103fa0 <__umoddi3+0x110>
f0103f98:	75 11                	jne    f0103fab <__umoddi3+0x11b>
f0103f9a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103f9e:	73 0b                	jae    f0103fab <__umoddi3+0x11b>
f0103fa0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103fa4:	1b 14 24             	sbb    (%esp),%edx
f0103fa7:	89 d1                	mov    %edx,%ecx
f0103fa9:	89 c3                	mov    %eax,%ebx
f0103fab:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103faf:	29 da                	sub    %ebx,%edx
f0103fb1:	19 ce                	sbb    %ecx,%esi
f0103fb3:	89 f9                	mov    %edi,%ecx
f0103fb5:	89 f0                	mov    %esi,%eax
f0103fb7:	d3 e0                	shl    %cl,%eax
f0103fb9:	89 e9                	mov    %ebp,%ecx
f0103fbb:	d3 ea                	shr    %cl,%edx
f0103fbd:	89 e9                	mov    %ebp,%ecx
f0103fbf:	d3 ee                	shr    %cl,%esi
f0103fc1:	09 d0                	or     %edx,%eax
f0103fc3:	89 f2                	mov    %esi,%edx
f0103fc5:	83 c4 1c             	add    $0x1c,%esp
f0103fc8:	5b                   	pop    %ebx
f0103fc9:	5e                   	pop    %esi
f0103fca:	5f                   	pop    %edi
f0103fcb:	5d                   	pop    %ebp
f0103fcc:	c3                   	ret    
f0103fcd:	8d 76 00             	lea    0x0(%esi),%esi
f0103fd0:	29 f9                	sub    %edi,%ecx
f0103fd2:	19 d6                	sbb    %edx,%esi
f0103fd4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103fd8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103fdc:	e9 18 ff ff ff       	jmp    f0103ef9 <__umoddi3+0x69>
