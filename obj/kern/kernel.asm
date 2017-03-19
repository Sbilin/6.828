
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
f0100058:	e8 a7 41 00 00       	call   f0104204 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 46 10 f0       	push   $0xf01046a0
f010006f:	e8 c9 2d 00 00       	call   f0102e3d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 26 0f 00 00       	call   f0100f9f <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 2c 28 00 00       	call   f01028aa <env_init>
	trap_init();
f010007e:	e8 2b 2e 00 00       	call   f0102eae <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 7e 0b 13 f0       	push   $0xf0130b7e
f010008d:	e8 c5 29 00 00       	call   f0102a57 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 48 be 17 f0    	pushl  0xf017be48
f010009b:	e8 d4 2c 00 00       	call   f0102d74 <env_run>

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
f01000c5:	68 bb 46 10 f0       	push   $0xf01046bb
f01000ca:	e8 6e 2d 00 00       	call   f0102e3d <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 3e 2d 00 00       	call   f0102e17 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d6 55 10 f0 	movl   $0xf01055d6,(%esp)
f01000e0:	e8 58 2d 00 00       	call   f0102e3d <cprintf>
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
f0100107:	68 d3 46 10 f0       	push   $0xf01046d3
f010010c:	e8 2c 2d 00 00       	call   f0102e3d <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 fa 2c 00 00       	call   f0102e17 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 d6 55 10 f0 	movl   $0xf01055d6,(%esp)
f0100124:	e8 14 2d 00 00       	call   f0102e3d <cprintf>
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
f01001e3:	0f b6 82 40 48 10 f0 	movzbl -0xfefb7c0(%edx),%eax
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
f010021f:	0f b6 82 40 48 10 f0 	movzbl -0xfefb7c0(%edx),%eax
f0100226:	0b 05 00 bc 17 f0    	or     0xf017bc00,%eax
f010022c:	0f b6 8a 40 47 10 f0 	movzbl -0xfefb8c0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 00 bc 17 f0       	mov    %eax,0xf017bc00

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 20 47 10 f0 	mov    -0xfefb8e0(,%ecx,4),%ecx
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
f010027d:	68 ed 46 10 f0       	push   $0xf01046ed
f0100282:	e8 b6 2b 00 00       	call   f0102e3d <cprintf>
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
f0100431:	e8 1b 3e 00 00       	call   f0104251 <memmove>
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
f0100600:	68 f9 46 10 f0       	push   $0xf01046f9
f0100605:	e8 33 28 00 00       	call   f0102e3d <cprintf>
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
f0100646:	68 40 49 10 f0       	push   $0xf0104940
f010064b:	68 5e 49 10 f0       	push   $0xf010495e
f0100650:	68 63 49 10 f0       	push   $0xf0104963
f0100655:	e8 e3 27 00 00       	call   f0102e3d <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 cc 49 10 f0       	push   $0xf01049cc
f0100662:	68 6c 49 10 f0       	push   $0xf010496c
f0100667:	68 63 49 10 f0       	push   $0xf0104963
f010066c:	e8 cc 27 00 00       	call   f0102e3d <cprintf>
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
f010067e:	68 75 49 10 f0       	push   $0xf0104975
f0100683:	e8 b5 27 00 00       	call   f0102e3d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 f4 49 10 f0       	push   $0xf01049f4
f0100695:	e8 a3 27 00 00       	call   f0102e3d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 1c 4a 10 f0       	push   $0xf0104a1c
f01006ac:	e8 8c 27 00 00       	call   f0102e3d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 91 46 10 00       	push   $0x104691
f01006b9:	68 91 46 10 f0       	push   $0xf0104691
f01006be:	68 40 4a 10 f0       	push   $0xf0104a40
f01006c3:	e8 75 27 00 00       	call   f0102e3d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 ee bb 17 00       	push   $0x17bbee
f01006d0:	68 ee bb 17 f0       	push   $0xf017bbee
f01006d5:	68 64 4a 10 f0       	push   $0xf0104a64
f01006da:	e8 5e 27 00 00       	call   f0102e3d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 10 cb 17 00       	push   $0x17cb10
f01006e7:	68 10 cb 17 f0       	push   $0xf017cb10
f01006ec:	68 88 4a 10 f0       	push   $0xf0104a88
f01006f1:	e8 47 27 00 00       	call   f0102e3d <cprintf>
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
f0100717:	68 ac 4a 10 f0       	push   $0xf0104aac
f010071c:	e8 1c 27 00 00       	call   f0102e3d <cprintf>
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
f010073b:	68 d8 4a 10 f0       	push   $0xf0104ad8
f0100740:	e8 f8 26 00 00       	call   f0102e3d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100745:	c7 04 24 fc 4a 10 f0 	movl   $0xf0104afc,(%esp)
f010074c:	e8 ec 26 00 00       	call   f0102e3d <cprintf>

	if (tf != NULL)
f0100751:	83 c4 10             	add    $0x10,%esp
f0100754:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100758:	74 0e                	je     f0100768 <monitor+0x36>
		print_trapframe(tf);
f010075a:	83 ec 0c             	sub    $0xc,%esp
f010075d:	ff 75 08             	pushl  0x8(%ebp)
f0100760:	e8 10 2b 00 00       	call   f0103275 <print_trapframe>
f0100765:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100768:	83 ec 0c             	sub    $0xc,%esp
f010076b:	68 8e 49 10 f0       	push   $0xf010498e
f0100770:	e8 38 38 00 00       	call   f0103fad <readline>
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
f01007a4:	68 92 49 10 f0       	push   $0xf0104992
f01007a9:	e8 19 3a 00 00       	call   f01041c7 <strchr>
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
f01007c4:	68 97 49 10 f0       	push   $0xf0104997
f01007c9:	e8 6f 26 00 00       	call   f0102e3d <cprintf>
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
f01007ed:	68 92 49 10 f0       	push   $0xf0104992
f01007f2:	e8 d0 39 00 00       	call   f01041c7 <strchr>
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
f0100813:	68 5e 49 10 f0       	push   $0xf010495e
f0100818:	ff 75 a8             	pushl  -0x58(%ebp)
f010081b:	e8 49 39 00 00       	call   f0104169 <strcmp>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 1e                	je     f0100845 <monitor+0x113>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	68 6c 49 10 f0       	push   $0xf010496c
f010082f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100832:	e8 32 39 00 00       	call   f0104169 <strcmp>
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
f010085a:	ff 14 85 2c 4b 10 f0 	call   *-0xfefb4d4(,%eax,4)
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
f0100873:	68 b4 49 10 f0       	push   $0xf01049b4
f0100878:	e8 c0 25 00 00       	call   f0102e3d <cprintf>
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
f01008d0:	e8 01 25 00 00       	call   f0102dd6 <mc146818_read>
f01008d5:	89 c6                	mov    %eax,%esi
f01008d7:	83 c3 01             	add    $0x1,%ebx
f01008da:	89 1c 24             	mov    %ebx,(%esp)
f01008dd:	e8 f4 24 00 00       	call   f0102dd6 <mc146818_read>
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
f0100913:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0100918:	68 31 03 00 00       	push   $0x331
f010091d:	68 25 53 10 f0       	push   $0xf0105325
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
f010096b:	68 60 4b 10 f0       	push   $0xf0104b60
f0100970:	68 6f 02 00 00       	push   $0x26f
f0100975:	68 25 53 10 f0       	push   $0xf0105325
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
f01009c3:	a3 40 be 17 f0       	mov    %eax,0xf017be40
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
f01009cd:	8b 1d 40 be 17 f0    	mov    0xf017be40,%ebx
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
f01009fa:	68 3c 4b 10 f0       	push   $0xf0104b3c
f01009ff:	6a 56                	push   $0x56
f0100a01:	68 31 53 10 f0       	push   $0xf0105331
f0100a06:	e8 95 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a0b:	83 ec 04             	sub    $0x4,%esp
f0100a0e:	68 80 00 00 00       	push   $0x80
f0100a13:	68 97 00 00 00       	push   $0x97
f0100a18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a1d:	50                   	push   %eax
f0100a1e:	e8 e1 37 00 00       	call   f0104204 <memset>
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
f0100a39:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
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
f0100a64:	68 3f 53 10 f0       	push   $0xf010533f
f0100a69:	68 4b 53 10 f0       	push   $0xf010534b
f0100a6e:	68 89 02 00 00       	push   $0x289
f0100a73:	68 25 53 10 f0       	push   $0xf0105325
f0100a78:	e8 23 f6 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100a7d:	39 fa                	cmp    %edi,%edx
f0100a7f:	72 19                	jb     f0100a9a <check_page_free_list+0x148>
f0100a81:	68 60 53 10 f0       	push   $0xf0105360
f0100a86:	68 4b 53 10 f0       	push   $0xf010534b
f0100a8b:	68 8a 02 00 00       	push   $0x28a
f0100a90:	68 25 53 10 f0       	push   $0xf0105325
f0100a95:	e8 06 f6 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a9a:	89 d0                	mov    %edx,%eax
f0100a9c:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a9f:	a8 07                	test   $0x7,%al
f0100aa1:	74 19                	je     f0100abc <check_page_free_list+0x16a>
f0100aa3:	68 84 4b 10 f0       	push   $0xf0104b84
f0100aa8:	68 4b 53 10 f0       	push   $0xf010534b
f0100aad:	68 8b 02 00 00       	push   $0x28b
f0100ab2:	68 25 53 10 f0       	push   $0xf0105325
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
f0100ac6:	68 74 53 10 f0       	push   $0xf0105374
f0100acb:	68 4b 53 10 f0       	push   $0xf010534b
f0100ad0:	68 8e 02 00 00       	push   $0x28e
f0100ad5:	68 25 53 10 f0       	push   $0xf0105325
f0100ada:	e8 c1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100adf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ae4:	75 19                	jne    f0100aff <check_page_free_list+0x1ad>
f0100ae6:	68 85 53 10 f0       	push   $0xf0105385
f0100aeb:	68 4b 53 10 f0       	push   $0xf010534b
f0100af0:	68 8f 02 00 00       	push   $0x28f
f0100af5:	68 25 53 10 f0       	push   $0xf0105325
f0100afa:	e8 a1 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100aff:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b04:	75 19                	jne    f0100b1f <check_page_free_list+0x1cd>
f0100b06:	68 b8 4b 10 f0       	push   $0xf0104bb8
f0100b0b:	68 4b 53 10 f0       	push   $0xf010534b
f0100b10:	68 90 02 00 00       	push   $0x290
f0100b15:	68 25 53 10 f0       	push   $0xf0105325
f0100b1a:	e8 81 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b1f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b24:	75 19                	jne    f0100b3f <check_page_free_list+0x1ed>
f0100b26:	68 9e 53 10 f0       	push   $0xf010539e
f0100b2b:	68 4b 53 10 f0       	push   $0xf010534b
f0100b30:	68 91 02 00 00       	push   $0x291
f0100b35:	68 25 53 10 f0       	push   $0xf0105325
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
f0100b51:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0100b56:	6a 56                	push   $0x56
f0100b58:	68 31 53 10 f0       	push   $0xf0105331
f0100b5d:	e8 3e f5 ff ff       	call   f01000a0 <_panic>
f0100b62:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b67:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b6a:	76 1e                	jbe    f0100b8a <check_page_free_list+0x238>
f0100b6c:	68 dc 4b 10 f0       	push   $0xf0104bdc
f0100b71:	68 4b 53 10 f0       	push   $0xf010534b
f0100b76:	68 92 02 00 00       	push   $0x292
f0100b7b:	68 25 53 10 f0       	push   $0xf0105325
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
f0100b9f:	68 b8 53 10 f0       	push   $0xf01053b8
f0100ba4:	68 4b 53 10 f0       	push   $0xf010534b
f0100ba9:	68 9a 02 00 00       	push   $0x29a
f0100bae:	68 25 53 10 f0       	push   $0xf0105325
f0100bb3:	e8 e8 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bb8:	85 db                	test   %ebx,%ebx
f0100bba:	7f 42                	jg     f0100bfe <check_page_free_list+0x2ac>
f0100bbc:	68 ca 53 10 f0       	push   $0xf01053ca
f0100bc1:	68 4b 53 10 f0       	push   $0xf010534b
f0100bc6:	68 9b 02 00 00       	push   $0x29b
f0100bcb:	68 25 53 10 f0       	push   $0xf0105325
f0100bd0:	e8 cb f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bd5:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0100bda:	85 c0                	test   %eax,%eax
f0100bdc:	0f 85 9d fd ff ff    	jne    f010097f <check_page_free_list+0x2d>
f0100be2:	e9 81 fd ff ff       	jmp    f0100968 <check_page_free_list+0x16>
f0100be7:	83 3d 40 be 17 f0 00 	cmpl   $0x0,0xf017be40
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
f0100c0b:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
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
f0100c27:	68 24 4c 10 f0       	push   $0xf0104c24
f0100c2c:	68 12 01 00 00       	push   $0x112
f0100c31:	68 25 53 10 f0       	push   $0xf0105325
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
f0100cc2:	89 35 40 be 17 f0    	mov    %esi,0xf017be40
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
f0100cd6:	8b 1d 40 be 17 f0    	mov    0xf017be40,%ebx
f0100cdc:	85 db                	test   %ebx,%ebx
f0100cde:	74 58                	je     f0100d38 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100ce0:	8b 03                	mov    (%ebx),%eax
f0100ce2:	a3 40 be 17 f0       	mov    %eax,0xf017be40
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
f0100d0f:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0100d14:	6a 56                	push   $0x56
f0100d16:	68 31 53 10 f0       	push   $0xf0105331
f0100d1b:	e8 80 f3 ff ff       	call   f01000a0 <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100d20:	83 ec 04             	sub    $0x4,%esp
f0100d23:	68 00 10 00 00       	push   $0x1000
f0100d28:	6a 00                	push   $0x0
f0100d2a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d2f:	50                   	push   %eax
f0100d30:	e8 cf 34 00 00       	call   f0104204 <memset>
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
f0100d54:	68 48 4c 10 f0       	push   $0xf0104c48
f0100d59:	68 4b 53 10 f0       	push   $0xf010534b
f0100d5e:	68 4e 01 00 00       	push   $0x14e
f0100d63:	68 25 53 10 f0       	push   $0xf0105325
f0100d68:	e8 33 f3 ff ff       	call   f01000a0 <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100d6d:	8b 15 40 be 17 f0    	mov    0xf017be40,%edx
f0100d73:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100d75:	a3 40 be 17 f0       	mov    %eax,0xf017be40
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
f0100e06:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0100e0b:	68 89 01 00 00       	push   $0x189
f0100e10:	68 25 53 10 f0       	push   $0xf0105325
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
f0100eb8:	68 70 4c 10 f0       	push   $0xf0104c70
f0100ebd:	6a 4f                	push   $0x4f
f0100ebf:	68 31 53 10 f0       	push   $0xf0105331
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
f0100ff5:	68 90 4c 10 f0       	push   $0xf0104c90
f0100ffa:	e8 3e 1e 00 00       	call   f0102e3d <cprintf>
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
f0101019:	e8 e6 31 00 00       	call   f0104204 <memset>
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
f010102e:	68 24 4c 10 f0       	push   $0xf0104c24
f0101033:	68 90 00 00 00       	push   $0x90
f0101038:	68 25 53 10 f0       	push   $0xf0105325
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
f0101077:	e8 88 31 00 00       	call   f0104204 <memset>
	//cprintf("%08x\n",pages);
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs=boot_alloc(NENV*sizeof(struct Env));
f010107c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101081:	e8 07 f8 ff ff       	call   f010088d <boot_alloc>
f0101086:	a3 48 be 17 f0       	mov    %eax,0xf017be48
	memset(envs,0,NENV*sizeof(struct Env));
f010108b:	83 c4 0c             	add    $0xc,%esp
f010108e:	68 00 80 01 00       	push   $0x18000
f0101093:	6a 00                	push   $0x0
f0101095:	50                   	push   %eax
f0101096:	e8 69 31 00 00       	call   f0104204 <memset>
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
f01010b9:	68 db 53 10 f0       	push   $0xf01053db
f01010be:	68 ac 02 00 00       	push   $0x2ac
f01010c3:	68 25 53 10 f0       	push   $0xf0105325
f01010c8:	e8 d3 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010cd:	a1 40 be 17 f0       	mov    0xf017be40,%eax
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
f01010f5:	68 f6 53 10 f0       	push   $0xf01053f6
f01010fa:	68 4b 53 10 f0       	push   $0xf010534b
f01010ff:	68 b4 02 00 00       	push   $0x2b4
f0101104:	68 25 53 10 f0       	push   $0xf0105325
f0101109:	e8 92 ef ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010110e:	83 ec 0c             	sub    $0xc,%esp
f0101111:	6a 00                	push   $0x0
f0101113:	e8 b7 fb ff ff       	call   f0100ccf <page_alloc>
f0101118:	89 c6                	mov    %eax,%esi
f010111a:	83 c4 10             	add    $0x10,%esp
f010111d:	85 c0                	test   %eax,%eax
f010111f:	75 19                	jne    f010113a <mem_init+0x19b>
f0101121:	68 0c 54 10 f0       	push   $0xf010540c
f0101126:	68 4b 53 10 f0       	push   $0xf010534b
f010112b:	68 b5 02 00 00       	push   $0x2b5
f0101130:	68 25 53 10 f0       	push   $0xf0105325
f0101135:	e8 66 ef ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010113a:	83 ec 0c             	sub    $0xc,%esp
f010113d:	6a 00                	push   $0x0
f010113f:	e8 8b fb ff ff       	call   f0100ccf <page_alloc>
f0101144:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101147:	83 c4 10             	add    $0x10,%esp
f010114a:	85 c0                	test   %eax,%eax
f010114c:	75 19                	jne    f0101167 <mem_init+0x1c8>
f010114e:	68 22 54 10 f0       	push   $0xf0105422
f0101153:	68 4b 53 10 f0       	push   $0xf010534b
f0101158:	68 b6 02 00 00       	push   $0x2b6
f010115d:	68 25 53 10 f0       	push   $0xf0105325
f0101162:	e8 39 ef ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101167:	39 f7                	cmp    %esi,%edi
f0101169:	75 19                	jne    f0101184 <mem_init+0x1e5>
f010116b:	68 38 54 10 f0       	push   $0xf0105438
f0101170:	68 4b 53 10 f0       	push   $0xf010534b
f0101175:	68 b9 02 00 00       	push   $0x2b9
f010117a:	68 25 53 10 f0       	push   $0xf0105325
f010117f:	e8 1c ef ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101184:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101187:	39 c6                	cmp    %eax,%esi
f0101189:	74 04                	je     f010118f <mem_init+0x1f0>
f010118b:	39 c7                	cmp    %eax,%edi
f010118d:	75 19                	jne    f01011a8 <mem_init+0x209>
f010118f:	68 cc 4c 10 f0       	push   $0xf0104ccc
f0101194:	68 4b 53 10 f0       	push   $0xf010534b
f0101199:	68 ba 02 00 00       	push   $0x2ba
f010119e:	68 25 53 10 f0       	push   $0xf0105325
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
f01011c5:	68 4a 54 10 f0       	push   $0xf010544a
f01011ca:	68 4b 53 10 f0       	push   $0xf010534b
f01011cf:	68 bb 02 00 00       	push   $0x2bb
f01011d4:	68 25 53 10 f0       	push   $0xf0105325
f01011d9:	e8 c2 ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01011de:	89 f0                	mov    %esi,%eax
f01011e0:	29 c8                	sub    %ecx,%eax
f01011e2:	c1 f8 03             	sar    $0x3,%eax
f01011e5:	c1 e0 0c             	shl    $0xc,%eax
f01011e8:	39 c2                	cmp    %eax,%edx
f01011ea:	77 19                	ja     f0101205 <mem_init+0x266>
f01011ec:	68 67 54 10 f0       	push   $0xf0105467
f01011f1:	68 4b 53 10 f0       	push   $0xf010534b
f01011f6:	68 bc 02 00 00       	push   $0x2bc
f01011fb:	68 25 53 10 f0       	push   $0xf0105325
f0101200:	e8 9b ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101208:	29 c8                	sub    %ecx,%eax
f010120a:	c1 f8 03             	sar    $0x3,%eax
f010120d:	c1 e0 0c             	shl    $0xc,%eax
f0101210:	39 c2                	cmp    %eax,%edx
f0101212:	77 19                	ja     f010122d <mem_init+0x28e>
f0101214:	68 84 54 10 f0       	push   $0xf0105484
f0101219:	68 4b 53 10 f0       	push   $0xf010534b
f010121e:	68 bd 02 00 00       	push   $0x2bd
f0101223:	68 25 53 10 f0       	push   $0xf0105325
f0101228:	e8 73 ee ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010122d:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0101232:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101235:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
f010123c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010123f:	83 ec 0c             	sub    $0xc,%esp
f0101242:	6a 00                	push   $0x0
f0101244:	e8 86 fa ff ff       	call   f0100ccf <page_alloc>
f0101249:	83 c4 10             	add    $0x10,%esp
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 19                	je     f0101269 <mem_init+0x2ca>
f0101250:	68 a1 54 10 f0       	push   $0xf01054a1
f0101255:	68 4b 53 10 f0       	push   $0xf010534b
f010125a:	68 c4 02 00 00       	push   $0x2c4
f010125f:	68 25 53 10 f0       	push   $0xf0105325
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
f010129a:	68 f6 53 10 f0       	push   $0xf01053f6
f010129f:	68 4b 53 10 f0       	push   $0xf010534b
f01012a4:	68 cb 02 00 00       	push   $0x2cb
f01012a9:	68 25 53 10 f0       	push   $0xf0105325
f01012ae:	e8 ed ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01012b3:	83 ec 0c             	sub    $0xc,%esp
f01012b6:	6a 00                	push   $0x0
f01012b8:	e8 12 fa ff ff       	call   f0100ccf <page_alloc>
f01012bd:	89 c7                	mov    %eax,%edi
f01012bf:	83 c4 10             	add    $0x10,%esp
f01012c2:	85 c0                	test   %eax,%eax
f01012c4:	75 19                	jne    f01012df <mem_init+0x340>
f01012c6:	68 0c 54 10 f0       	push   $0xf010540c
f01012cb:	68 4b 53 10 f0       	push   $0xf010534b
f01012d0:	68 cc 02 00 00       	push   $0x2cc
f01012d5:	68 25 53 10 f0       	push   $0xf0105325
f01012da:	e8 c1 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01012df:	83 ec 0c             	sub    $0xc,%esp
f01012e2:	6a 00                	push   $0x0
f01012e4:	e8 e6 f9 ff ff       	call   f0100ccf <page_alloc>
f01012e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012ec:	83 c4 10             	add    $0x10,%esp
f01012ef:	85 c0                	test   %eax,%eax
f01012f1:	75 19                	jne    f010130c <mem_init+0x36d>
f01012f3:	68 22 54 10 f0       	push   $0xf0105422
f01012f8:	68 4b 53 10 f0       	push   $0xf010534b
f01012fd:	68 cd 02 00 00       	push   $0x2cd
f0101302:	68 25 53 10 f0       	push   $0xf0105325
f0101307:	e8 94 ed ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010130c:	39 fe                	cmp    %edi,%esi
f010130e:	75 19                	jne    f0101329 <mem_init+0x38a>
f0101310:	68 38 54 10 f0       	push   $0xf0105438
f0101315:	68 4b 53 10 f0       	push   $0xf010534b
f010131a:	68 cf 02 00 00       	push   $0x2cf
f010131f:	68 25 53 10 f0       	push   $0xf0105325
f0101324:	e8 77 ed ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101329:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010132c:	39 c7                	cmp    %eax,%edi
f010132e:	74 04                	je     f0101334 <mem_init+0x395>
f0101330:	39 c6                	cmp    %eax,%esi
f0101332:	75 19                	jne    f010134d <mem_init+0x3ae>
f0101334:	68 cc 4c 10 f0       	push   $0xf0104ccc
f0101339:	68 4b 53 10 f0       	push   $0xf010534b
f010133e:	68 d0 02 00 00       	push   $0x2d0
f0101343:	68 25 53 10 f0       	push   $0xf0105325
f0101348:	e8 53 ed ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f010134d:	83 ec 0c             	sub    $0xc,%esp
f0101350:	6a 00                	push   $0x0
f0101352:	e8 78 f9 ff ff       	call   f0100ccf <page_alloc>
f0101357:	83 c4 10             	add    $0x10,%esp
f010135a:	85 c0                	test   %eax,%eax
f010135c:	74 19                	je     f0101377 <mem_init+0x3d8>
f010135e:	68 a1 54 10 f0       	push   $0xf01054a1
f0101363:	68 4b 53 10 f0       	push   $0xf010534b
f0101368:	68 d1 02 00 00       	push   $0x2d1
f010136d:	68 25 53 10 f0       	push   $0xf0105325
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
f0101393:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101398:	6a 56                	push   $0x56
f010139a:	68 31 53 10 f0       	push   $0xf0105331
f010139f:	e8 fc ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013a4:	83 ec 04             	sub    $0x4,%esp
f01013a7:	68 00 10 00 00       	push   $0x1000
f01013ac:	6a 01                	push   $0x1
f01013ae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013b3:	50                   	push   %eax
f01013b4:	e8 4b 2e 00 00       	call   f0104204 <memset>
	page_free(pp0);
f01013b9:	89 34 24             	mov    %esi,(%esp)
f01013bc:	e8 7e f9 ff ff       	call   f0100d3f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01013c1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01013c8:	e8 02 f9 ff ff       	call   f0100ccf <page_alloc>
f01013cd:	83 c4 10             	add    $0x10,%esp
f01013d0:	85 c0                	test   %eax,%eax
f01013d2:	75 19                	jne    f01013ed <mem_init+0x44e>
f01013d4:	68 b0 54 10 f0       	push   $0xf01054b0
f01013d9:	68 4b 53 10 f0       	push   $0xf010534b
f01013de:	68 d6 02 00 00       	push   $0x2d6
f01013e3:	68 25 53 10 f0       	push   $0xf0105325
f01013e8:	e8 b3 ec ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01013ed:	39 c6                	cmp    %eax,%esi
f01013ef:	74 19                	je     f010140a <mem_init+0x46b>
f01013f1:	68 ce 54 10 f0       	push   $0xf01054ce
f01013f6:	68 4b 53 10 f0       	push   $0xf010534b
f01013fb:	68 d7 02 00 00       	push   $0x2d7
f0101400:	68 25 53 10 f0       	push   $0xf0105325
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
f0101426:	68 3c 4b 10 f0       	push   $0xf0104b3c
f010142b:	6a 56                	push   $0x56
f010142d:	68 31 53 10 f0       	push   $0xf0105331
f0101432:	e8 69 ec ff ff       	call   f01000a0 <_panic>
f0101437:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010143d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101443:	80 38 00             	cmpb   $0x0,(%eax)
f0101446:	74 19                	je     f0101461 <mem_init+0x4c2>
f0101448:	68 de 54 10 f0       	push   $0xf01054de
f010144d:	68 4b 53 10 f0       	push   $0xf010534b
f0101452:	68 da 02 00 00       	push   $0x2da
f0101457:	68 25 53 10 f0       	push   $0xf0105325
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
f010146b:	a3 40 be 17 f0       	mov    %eax,0xf017be40

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
f010148c:	a1 40 be 17 f0       	mov    0xf017be40,%eax
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
f01014a3:	68 e8 54 10 f0       	push   $0xf01054e8
f01014a8:	68 4b 53 10 f0       	push   $0xf010534b
f01014ad:	68 e7 02 00 00       	push   $0x2e7
f01014b2:	68 25 53 10 f0       	push   $0xf0105325
f01014b7:	e8 e4 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014bc:	83 ec 0c             	sub    $0xc,%esp
f01014bf:	68 ec 4c 10 f0       	push   $0xf0104cec
f01014c4:	e8 74 19 00 00       	call   f0102e3d <cprintf>
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
f01014df:	68 f6 53 10 f0       	push   $0xf01053f6
f01014e4:	68 4b 53 10 f0       	push   $0xf010534b
f01014e9:	68 44 03 00 00       	push   $0x344
f01014ee:	68 25 53 10 f0       	push   $0xf0105325
f01014f3:	e8 a8 eb ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01014f8:	83 ec 0c             	sub    $0xc,%esp
f01014fb:	6a 00                	push   $0x0
f01014fd:	e8 cd f7 ff ff       	call   f0100ccf <page_alloc>
f0101502:	89 c3                	mov    %eax,%ebx
f0101504:	83 c4 10             	add    $0x10,%esp
f0101507:	85 c0                	test   %eax,%eax
f0101509:	75 19                	jne    f0101524 <mem_init+0x585>
f010150b:	68 0c 54 10 f0       	push   $0xf010540c
f0101510:	68 4b 53 10 f0       	push   $0xf010534b
f0101515:	68 45 03 00 00       	push   $0x345
f010151a:	68 25 53 10 f0       	push   $0xf0105325
f010151f:	e8 7c eb ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101524:	83 ec 0c             	sub    $0xc,%esp
f0101527:	6a 00                	push   $0x0
f0101529:	e8 a1 f7 ff ff       	call   f0100ccf <page_alloc>
f010152e:	89 c6                	mov    %eax,%esi
f0101530:	83 c4 10             	add    $0x10,%esp
f0101533:	85 c0                	test   %eax,%eax
f0101535:	75 19                	jne    f0101550 <mem_init+0x5b1>
f0101537:	68 22 54 10 f0       	push   $0xf0105422
f010153c:	68 4b 53 10 f0       	push   $0xf010534b
f0101541:	68 46 03 00 00       	push   $0x346
f0101546:	68 25 53 10 f0       	push   $0xf0105325
f010154b:	e8 50 eb ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101550:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101553:	75 19                	jne    f010156e <mem_init+0x5cf>
f0101555:	68 38 54 10 f0       	push   $0xf0105438
f010155a:	68 4b 53 10 f0       	push   $0xf010534b
f010155f:	68 49 03 00 00       	push   $0x349
f0101564:	68 25 53 10 f0       	push   $0xf0105325
f0101569:	e8 32 eb ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010156e:	39 c3                	cmp    %eax,%ebx
f0101570:	74 05                	je     f0101577 <mem_init+0x5d8>
f0101572:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101575:	75 19                	jne    f0101590 <mem_init+0x5f1>
f0101577:	68 cc 4c 10 f0       	push   $0xf0104ccc
f010157c:	68 4b 53 10 f0       	push   $0xf010534b
f0101581:	68 4a 03 00 00       	push   $0x34a
f0101586:	68 25 53 10 f0       	push   $0xf0105325
f010158b:	e8 10 eb ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101590:	a1 40 be 17 f0       	mov    0xf017be40,%eax
f0101595:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101598:	c7 05 40 be 17 f0 00 	movl   $0x0,0xf017be40
f010159f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015a2:	83 ec 0c             	sub    $0xc,%esp
f01015a5:	6a 00                	push   $0x0
f01015a7:	e8 23 f7 ff ff       	call   f0100ccf <page_alloc>
f01015ac:	83 c4 10             	add    $0x10,%esp
f01015af:	85 c0                	test   %eax,%eax
f01015b1:	74 19                	je     f01015cc <mem_init+0x62d>
f01015b3:	68 a1 54 10 f0       	push   $0xf01054a1
f01015b8:	68 4b 53 10 f0       	push   $0xf010534b
f01015bd:	68 51 03 00 00       	push   $0x351
f01015c2:	68 25 53 10 f0       	push   $0xf0105325
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
f01015e7:	68 0c 4d 10 f0       	push   $0xf0104d0c
f01015ec:	68 4b 53 10 f0       	push   $0xf010534b
f01015f1:	68 54 03 00 00       	push   $0x354
f01015f6:	68 25 53 10 f0       	push   $0xf0105325
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
f0101617:	68 44 4d 10 f0       	push   $0xf0104d44
f010161c:	68 4b 53 10 f0       	push   $0xf010534b
f0101621:	68 57 03 00 00       	push   $0x357
f0101626:	68 25 53 10 f0       	push   $0xf0105325
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
f0101652:	68 74 4d 10 f0       	push   $0xf0104d74
f0101657:	68 4b 53 10 f0       	push   $0xf010534b
f010165c:	68 5b 03 00 00       	push   $0x35b
f0101661:	68 25 53 10 f0       	push   $0xf0105325
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
f0101692:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101697:	68 4b 53 10 f0       	push   $0xf010534b
f010169c:	68 5c 03 00 00       	push   $0x35c
f01016a1:	68 25 53 10 f0       	push   $0xf0105325
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
f01016c6:	68 cc 4d 10 f0       	push   $0xf0104dcc
f01016cb:	68 4b 53 10 f0       	push   $0xf010534b
f01016d0:	68 5d 03 00 00       	push   $0x35d
f01016d5:	68 25 53 10 f0       	push   $0xf0105325
f01016da:	e8 c1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01016df:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01016e4:	74 19                	je     f01016ff <mem_init+0x760>
f01016e6:	68 f3 54 10 f0       	push   $0xf01054f3
f01016eb:	68 4b 53 10 f0       	push   $0xf010534b
f01016f0:	68 5e 03 00 00       	push   $0x35e
f01016f5:	68 25 53 10 f0       	push   $0xf0105325
f01016fa:	e8 a1 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01016ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101702:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101707:	74 19                	je     f0101722 <mem_init+0x783>
f0101709:	68 04 55 10 f0       	push   $0xf0105504
f010170e:	68 4b 53 10 f0       	push   $0xf010534b
f0101713:	68 5f 03 00 00       	push   $0x35f
f0101718:	68 25 53 10 f0       	push   $0xf0105325
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
f0101737:	68 fc 4d 10 f0       	push   $0xf0104dfc
f010173c:	68 4b 53 10 f0       	push   $0xf010534b
f0101741:	68 62 03 00 00       	push   $0x362
f0101746:	68 25 53 10 f0       	push   $0xf0105325
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
f0101771:	68 38 4e 10 f0       	push   $0xf0104e38
f0101776:	68 4b 53 10 f0       	push   $0xf010534b
f010177b:	68 63 03 00 00       	push   $0x363
f0101780:	68 25 53 10 f0       	push   $0xf0105325
f0101785:	e8 16 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010178a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010178f:	74 19                	je     f01017aa <mem_init+0x80b>
f0101791:	68 15 55 10 f0       	push   $0xf0105515
f0101796:	68 4b 53 10 f0       	push   $0xf010534b
f010179b:	68 64 03 00 00       	push   $0x364
f01017a0:	68 25 53 10 f0       	push   $0xf0105325
f01017a5:	e8 f6 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01017aa:	83 ec 0c             	sub    $0xc,%esp
f01017ad:	6a 00                	push   $0x0
f01017af:	e8 1b f5 ff ff       	call   f0100ccf <page_alloc>
f01017b4:	83 c4 10             	add    $0x10,%esp
f01017b7:	85 c0                	test   %eax,%eax
f01017b9:	74 19                	je     f01017d4 <mem_init+0x835>
f01017bb:	68 a1 54 10 f0       	push   $0xf01054a1
f01017c0:	68 4b 53 10 f0       	push   $0xf010534b
f01017c5:	68 67 03 00 00       	push   $0x367
f01017ca:	68 25 53 10 f0       	push   $0xf0105325
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
f01017ee:	68 fc 4d 10 f0       	push   $0xf0104dfc
f01017f3:	68 4b 53 10 f0       	push   $0xf010534b
f01017f8:	68 6a 03 00 00       	push   $0x36a
f01017fd:	68 25 53 10 f0       	push   $0xf0105325
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
f0101828:	68 38 4e 10 f0       	push   $0xf0104e38
f010182d:	68 4b 53 10 f0       	push   $0xf010534b
f0101832:	68 6b 03 00 00       	push   $0x36b
f0101837:	68 25 53 10 f0       	push   $0xf0105325
f010183c:	e8 5f e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101841:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101846:	74 19                	je     f0101861 <mem_init+0x8c2>
f0101848:	68 15 55 10 f0       	push   $0xf0105515
f010184d:	68 4b 53 10 f0       	push   $0xf010534b
f0101852:	68 6c 03 00 00       	push   $0x36c
f0101857:	68 25 53 10 f0       	push   $0xf0105325
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
f0101872:	68 a1 54 10 f0       	push   $0xf01054a1
f0101877:	68 4b 53 10 f0       	push   $0xf010534b
f010187c:	68 70 03 00 00       	push   $0x370
f0101881:	68 25 53 10 f0       	push   $0xf0105325
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
f01018a6:	68 3c 4b 10 f0       	push   $0xf0104b3c
f01018ab:	68 73 03 00 00       	push   $0x373
f01018b0:	68 25 53 10 f0       	push   $0xf0105325
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
f01018df:	68 68 4e 10 f0       	push   $0xf0104e68
f01018e4:	68 4b 53 10 f0       	push   $0xf010534b
f01018e9:	68 74 03 00 00       	push   $0x374
f01018ee:	68 25 53 10 f0       	push   $0xf0105325
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
f0101912:	68 a8 4e 10 f0       	push   $0xf0104ea8
f0101917:	68 4b 53 10 f0       	push   $0xf010534b
f010191c:	68 77 03 00 00       	push   $0x377
f0101921:	68 25 53 10 f0       	push   $0xf0105325
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
f010194f:	68 38 4e 10 f0       	push   $0xf0104e38
f0101954:	68 4b 53 10 f0       	push   $0xf010534b
f0101959:	68 78 03 00 00       	push   $0x378
f010195e:	68 25 53 10 f0       	push   $0xf0105325
f0101963:	e8 38 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101968:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010196d:	74 19                	je     f0101988 <mem_init+0x9e9>
f010196f:	68 15 55 10 f0       	push   $0xf0105515
f0101974:	68 4b 53 10 f0       	push   $0xf010534b
f0101979:	68 79 03 00 00       	push   $0x379
f010197e:	68 25 53 10 f0       	push   $0xf0105325
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
f01019a0:	68 e8 4e 10 f0       	push   $0xf0104ee8
f01019a5:	68 4b 53 10 f0       	push   $0xf010534b
f01019aa:	68 7a 03 00 00       	push   $0x37a
f01019af:	68 25 53 10 f0       	push   $0xf0105325
f01019b4:	e8 e7 e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019b9:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
f01019be:	f6 00 04             	testb  $0x4,(%eax)
f01019c1:	75 19                	jne    f01019dc <mem_init+0xa3d>
f01019c3:	68 26 55 10 f0       	push   $0xf0105526
f01019c8:	68 4b 53 10 f0       	push   $0xf010534b
f01019cd:	68 7b 03 00 00       	push   $0x37b
f01019d2:	68 25 53 10 f0       	push   $0xf0105325
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
f01019f1:	68 fc 4d 10 f0       	push   $0xf0104dfc
f01019f6:	68 4b 53 10 f0       	push   $0xf010534b
f01019fb:	68 7e 03 00 00       	push   $0x37e
f0101a00:	68 25 53 10 f0       	push   $0xf0105325
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
f0101a27:	68 1c 4f 10 f0       	push   $0xf0104f1c
f0101a2c:	68 4b 53 10 f0       	push   $0xf010534b
f0101a31:	68 7f 03 00 00       	push   $0x37f
f0101a36:	68 25 53 10 f0       	push   $0xf0105325
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
f0101a5d:	68 50 4f 10 f0       	push   $0xf0104f50
f0101a62:	68 4b 53 10 f0       	push   $0xf010534b
f0101a67:	68 80 03 00 00       	push   $0x380
f0101a6c:	68 25 53 10 f0       	push   $0xf0105325
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
f0101a92:	68 88 4f 10 f0       	push   $0xf0104f88
f0101a97:	68 4b 53 10 f0       	push   $0xf010534b
f0101a9c:	68 83 03 00 00       	push   $0x383
f0101aa1:	68 25 53 10 f0       	push   $0xf0105325
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
f0101ac5:	68 c4 4f 10 f0       	push   $0xf0104fc4
f0101aca:	68 4b 53 10 f0       	push   $0xf010534b
f0101acf:	68 86 03 00 00       	push   $0x386
f0101ad4:	68 25 53 10 f0       	push   $0xf0105325
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
f0101afb:	68 50 4f 10 f0       	push   $0xf0104f50
f0101b00:	68 4b 53 10 f0       	push   $0xf010534b
f0101b05:	68 87 03 00 00       	push   $0x387
f0101b0a:	68 25 53 10 f0       	push   $0xf0105325
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
f0101b3d:	68 00 50 10 f0       	push   $0xf0105000
f0101b42:	68 4b 53 10 f0       	push   $0xf010534b
f0101b47:	68 8a 03 00 00       	push   $0x38a
f0101b4c:	68 25 53 10 f0       	push   $0xf0105325
f0101b51:	e8 4a e5 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b56:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b5b:	89 f8                	mov    %edi,%eax
f0101b5d:	e8 8c ed ff ff       	call   f01008ee <check_va2pa>
f0101b62:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b65:	74 19                	je     f0101b80 <mem_init+0xbe1>
f0101b67:	68 2c 50 10 f0       	push   $0xf010502c
f0101b6c:	68 4b 53 10 f0       	push   $0xf010534b
f0101b71:	68 8b 03 00 00       	push   $0x38b
f0101b76:	68 25 53 10 f0       	push   $0xf0105325
f0101b7b:	e8 20 e5 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b80:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b85:	74 19                	je     f0101ba0 <mem_init+0xc01>
f0101b87:	68 3c 55 10 f0       	push   $0xf010553c
f0101b8c:	68 4b 53 10 f0       	push   $0xf010534b
f0101b91:	68 8d 03 00 00       	push   $0x38d
f0101b96:	68 25 53 10 f0       	push   $0xf0105325
f0101b9b:	e8 00 e5 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101ba0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ba5:	74 19                	je     f0101bc0 <mem_init+0xc21>
f0101ba7:	68 4d 55 10 f0       	push   $0xf010554d
f0101bac:	68 4b 53 10 f0       	push   $0xf010534b
f0101bb1:	68 8e 03 00 00       	push   $0x38e
f0101bb6:	68 25 53 10 f0       	push   $0xf0105325
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
f0101bd5:	68 5c 50 10 f0       	push   $0xf010505c
f0101bda:	68 4b 53 10 f0       	push   $0xf010534b
f0101bdf:	68 91 03 00 00       	push   $0x391
f0101be4:	68 25 53 10 f0       	push   $0xf0105325
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
f0101c18:	68 80 50 10 f0       	push   $0xf0105080
f0101c1d:	68 4b 53 10 f0       	push   $0xf010534b
f0101c22:	68 95 03 00 00       	push   $0x395
f0101c27:	68 25 53 10 f0       	push   $0xf0105325
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
f0101c4f:	68 2c 50 10 f0       	push   $0xf010502c
f0101c54:	68 4b 53 10 f0       	push   $0xf010534b
f0101c59:	68 96 03 00 00       	push   $0x396
f0101c5e:	68 25 53 10 f0       	push   $0xf0105325
f0101c63:	e8 38 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101c68:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c6d:	74 19                	je     f0101c88 <mem_init+0xce9>
f0101c6f:	68 f3 54 10 f0       	push   $0xf01054f3
f0101c74:	68 4b 53 10 f0       	push   $0xf010534b
f0101c79:	68 97 03 00 00       	push   $0x397
f0101c7e:	68 25 53 10 f0       	push   $0xf0105325
f0101c83:	e8 18 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c88:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xd09>
f0101c8f:	68 4d 55 10 f0       	push   $0xf010554d
f0101c94:	68 4b 53 10 f0       	push   $0xf010534b
f0101c99:	68 98 03 00 00       	push   $0x398
f0101c9e:	68 25 53 10 f0       	push   $0xf0105325
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
f0101cbd:	68 a4 50 10 f0       	push   $0xf01050a4
f0101cc2:	68 4b 53 10 f0       	push   $0xf010534b
f0101cc7:	68 9b 03 00 00       	push   $0x39b
f0101ccc:	68 25 53 10 f0       	push   $0xf0105325
f0101cd1:	e8 ca e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101cd6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cdb:	75 19                	jne    f0101cf6 <mem_init+0xd57>
f0101cdd:	68 5e 55 10 f0       	push   $0xf010555e
f0101ce2:	68 4b 53 10 f0       	push   $0xf010534b
f0101ce7:	68 9c 03 00 00       	push   $0x39c
f0101cec:	68 25 53 10 f0       	push   $0xf0105325
f0101cf1:	e8 aa e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101cf6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101cf9:	74 19                	je     f0101d14 <mem_init+0xd75>
f0101cfb:	68 6a 55 10 f0       	push   $0xf010556a
f0101d00:	68 4b 53 10 f0       	push   $0xf010534b
f0101d05:	68 9d 03 00 00       	push   $0x39d
f0101d0a:	68 25 53 10 f0       	push   $0xf0105325
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
f0101d41:	68 80 50 10 f0       	push   $0xf0105080
f0101d46:	68 4b 53 10 f0       	push   $0xf010534b
f0101d4b:	68 a1 03 00 00       	push   $0x3a1
f0101d50:	68 25 53 10 f0       	push   $0xf0105325
f0101d55:	e8 46 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d5a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d5f:	89 f8                	mov    %edi,%eax
f0101d61:	e8 88 eb ff ff       	call   f01008ee <check_va2pa>
f0101d66:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d69:	74 19                	je     f0101d84 <mem_init+0xde5>
f0101d6b:	68 dc 50 10 f0       	push   $0xf01050dc
f0101d70:	68 4b 53 10 f0       	push   $0xf010534b
f0101d75:	68 a2 03 00 00       	push   $0x3a2
f0101d7a:	68 25 53 10 f0       	push   $0xf0105325
f0101d7f:	e8 1c e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101d84:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d89:	74 19                	je     f0101da4 <mem_init+0xe05>
f0101d8b:	68 7f 55 10 f0       	push   $0xf010557f
f0101d90:	68 4b 53 10 f0       	push   $0xf010534b
f0101d95:	68 a3 03 00 00       	push   $0x3a3
f0101d9a:	68 25 53 10 f0       	push   $0xf0105325
f0101d9f:	e8 fc e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101da4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101da9:	74 19                	je     f0101dc4 <mem_init+0xe25>
f0101dab:	68 4d 55 10 f0       	push   $0xf010554d
f0101db0:	68 4b 53 10 f0       	push   $0xf010534b
f0101db5:	68 a4 03 00 00       	push   $0x3a4
f0101dba:	68 25 53 10 f0       	push   $0xf0105325
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
f0101dd9:	68 04 51 10 f0       	push   $0xf0105104
f0101dde:	68 4b 53 10 f0       	push   $0xf010534b
f0101de3:	68 a7 03 00 00       	push   $0x3a7
f0101de8:	68 25 53 10 f0       	push   $0xf0105325
f0101ded:	e8 ae e2 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101df2:	83 ec 0c             	sub    $0xc,%esp
f0101df5:	6a 00                	push   $0x0
f0101df7:	e8 d3 ee ff ff       	call   f0100ccf <page_alloc>
f0101dfc:	83 c4 10             	add    $0x10,%esp
f0101dff:	85 c0                	test   %eax,%eax
f0101e01:	74 19                	je     f0101e1c <mem_init+0xe7d>
f0101e03:	68 a1 54 10 f0       	push   $0xf01054a1
f0101e08:	68 4b 53 10 f0       	push   $0xf010534b
f0101e0d:	68 aa 03 00 00       	push   $0x3aa
f0101e12:	68 25 53 10 f0       	push   $0xf0105325
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
f0101e3d:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101e42:	68 4b 53 10 f0       	push   $0xf010534b
f0101e47:	68 ad 03 00 00       	push   $0x3ad
f0101e4c:	68 25 53 10 f0       	push   $0xf0105325
f0101e51:	e8 4a e2 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101e56:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e5f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e64:	74 19                	je     f0101e7f <mem_init+0xee0>
f0101e66:	68 04 55 10 f0       	push   $0xf0105504
f0101e6b:	68 4b 53 10 f0       	push   $0xf010534b
f0101e70:	68 af 03 00 00       	push   $0x3af
f0101e75:	68 25 53 10 f0       	push   $0xf0105325
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
f0101ece:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101ed3:	68 b6 03 00 00       	push   $0x3b6
f0101ed8:	68 25 53 10 f0       	push   $0xf0105325
f0101edd:	e8 be e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101ee2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101ee7:	39 c7                	cmp    %eax,%edi
f0101ee9:	74 19                	je     f0101f04 <mem_init+0xf65>
f0101eeb:	68 90 55 10 f0       	push   $0xf0105590
f0101ef0:	68 4b 53 10 f0       	push   $0xf010534b
f0101ef5:	68 b7 03 00 00       	push   $0x3b7
f0101efa:	68 25 53 10 f0       	push   $0xf0105325
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
f0101f2d:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101f32:	6a 56                	push   $0x56
f0101f34:	68 31 53 10 f0       	push   $0xf0105331
f0101f39:	e8 62 e1 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f3e:	83 ec 04             	sub    $0x4,%esp
f0101f41:	68 00 10 00 00       	push   $0x1000
f0101f46:	68 ff 00 00 00       	push   $0xff
f0101f4b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f50:	50                   	push   %eax
f0101f51:	e8 ae 22 00 00       	call   f0104204 <memset>
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
f0101f92:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0101f97:	6a 56                	push   $0x56
f0101f99:	68 31 53 10 f0       	push   $0xf0105331
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
f0101fb7:	68 a8 55 10 f0       	push   $0xf01055a8
f0101fbc:	68 4b 53 10 f0       	push   $0xf010534b
f0101fc1:	68 c1 03 00 00       	push   $0x3c1
f0101fc6:	68 25 53 10 f0       	push   $0xf0105325
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
f0101fee:	89 3d 40 be 17 f0    	mov    %edi,0xf017be40

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
f010200d:	c7 04 24 bf 55 10 f0 	movl   $0xf01055bf,(%esp)
f0102014:	e8 24 0e 00 00       	call   f0102e3d <cprintf>
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
f0102029:	68 24 4c 10 f0       	push   $0xf0104c24
f010202e:	68 b7 00 00 00       	push   $0xb7
f0102033:	68 25 53 10 f0       	push   $0xf0105325
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
f010205c:	a1 48 be 17 f0       	mov    0xf017be48,%eax
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
f010206c:	68 24 4c 10 f0       	push   $0xf0104c24
f0102071:	68 bf 00 00 00       	push   $0xbf
f0102076:	68 25 53 10 f0       	push   $0xf0105325
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
f01020af:	68 24 4c 10 f0       	push   $0xf0104c24
f01020b4:	68 cb 00 00 00       	push   $0xcb
f01020b9:	68 25 53 10 f0       	push   $0xf0105325
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
f0102143:	68 24 4c 10 f0       	push   $0xf0104c24
f0102148:	68 ff 02 00 00       	push   $0x2ff
f010214d:	68 25 53 10 f0       	push   $0xf0105325
f0102152:	e8 49 df ff ff       	call   f01000a0 <_panic>
f0102157:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f010215e:	39 d0                	cmp    %edx,%eax
f0102160:	74 19                	je     f010217b <mem_init+0x11dc>
f0102162:	68 28 51 10 f0       	push   $0xf0105128
f0102167:	68 4b 53 10 f0       	push   $0xf010534b
f010216c:	68 ff 02 00 00       	push   $0x2ff
f0102171:	68 25 53 10 f0       	push   $0xf0105325
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
f0102186:	8b 3d 48 be 17 f0    	mov    0xf017be48,%edi
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
f01021a7:	68 24 4c 10 f0       	push   $0xf0104c24
f01021ac:	68 04 03 00 00       	push   $0x304
f01021b1:	68 25 53 10 f0       	push   $0xf0105325
f01021b6:	e8 e5 de ff ff       	call   f01000a0 <_panic>
f01021bb:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01021c2:	39 c2                	cmp    %eax,%edx
f01021c4:	74 19                	je     f01021df <mem_init+0x1240>
f01021c6:	68 5c 51 10 f0       	push   $0xf010515c
f01021cb:	68 4b 53 10 f0       	push   $0xf010534b
f01021d0:	68 04 03 00 00       	push   $0x304
f01021d5:	68 25 53 10 f0       	push   $0xf0105325
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
f010220b:	68 90 51 10 f0       	push   $0xf0105190
f0102210:	68 4b 53 10 f0       	push   $0xf010534b
f0102215:	68 08 03 00 00       	push   $0x308
f010221a:	68 25 53 10 f0       	push   $0xf0105325
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
f0102246:	68 b8 51 10 f0       	push   $0xf01051b8
f010224b:	68 4b 53 10 f0       	push   $0xf010534b
f0102250:	68 0c 03 00 00       	push   $0x30c
f0102255:	68 25 53 10 f0       	push   $0xf0105325
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
f010227e:	68 00 52 10 f0       	push   $0xf0105200
f0102283:	68 4b 53 10 f0       	push   $0xf010534b
f0102288:	68 0d 03 00 00       	push   $0x30d
f010228d:	68 25 53 10 f0       	push   $0xf0105325
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
f01022b6:	68 d8 55 10 f0       	push   $0xf01055d8
f01022bb:	68 4b 53 10 f0       	push   $0xf010534b
f01022c0:	68 16 03 00 00       	push   $0x316
f01022c5:	68 25 53 10 f0       	push   $0xf0105325
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
f01022e3:	68 d8 55 10 f0       	push   $0xf01055d8
f01022e8:	68 4b 53 10 f0       	push   $0xf010534b
f01022ed:	68 1a 03 00 00       	push   $0x31a
f01022f2:	68 25 53 10 f0       	push   $0xf0105325
f01022f7:	e8 a4 dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01022fc:	f6 c2 02             	test   $0x2,%dl
f01022ff:	75 38                	jne    f0102339 <mem_init+0x139a>
f0102301:	68 e9 55 10 f0       	push   $0xf01055e9
f0102306:	68 4b 53 10 f0       	push   $0xf010534b
f010230b:	68 1b 03 00 00       	push   $0x31b
f0102310:	68 25 53 10 f0       	push   $0xf0105325
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f010231a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010231e:	74 19                	je     f0102339 <mem_init+0x139a>
f0102320:	68 fa 55 10 f0       	push   $0xf01055fa
f0102325:	68 4b 53 10 f0       	push   $0xf010534b
f010232a:	68 1d 03 00 00       	push   $0x31d
f010232f:	68 25 53 10 f0       	push   $0xf0105325
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
f010234a:	68 30 52 10 f0       	push   $0xf0105230
f010234f:	e8 e9 0a 00 00       	call   f0102e3d <cprintf>
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
f0102364:	68 24 4c 10 f0       	push   $0xf0104c24
f0102369:	68 df 00 00 00       	push   $0xdf
f010236e:	68 25 53 10 f0       	push   $0xf0105325
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
f01023ab:	68 f6 53 10 f0       	push   $0xf01053f6
f01023b0:	68 4b 53 10 f0       	push   $0xf010534b
f01023b5:	68 dc 03 00 00       	push   $0x3dc
f01023ba:	68 25 53 10 f0       	push   $0xf0105325
f01023bf:	e8 dc dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01023c4:	83 ec 0c             	sub    $0xc,%esp
f01023c7:	6a 00                	push   $0x0
f01023c9:	e8 01 e9 ff ff       	call   f0100ccf <page_alloc>
f01023ce:	89 c7                	mov    %eax,%edi
f01023d0:	83 c4 10             	add    $0x10,%esp
f01023d3:	85 c0                	test   %eax,%eax
f01023d5:	75 19                	jne    f01023f0 <mem_init+0x1451>
f01023d7:	68 0c 54 10 f0       	push   $0xf010540c
f01023dc:	68 4b 53 10 f0       	push   $0xf010534b
f01023e1:	68 dd 03 00 00       	push   $0x3dd
f01023e6:	68 25 53 10 f0       	push   $0xf0105325
f01023eb:	e8 b0 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01023f0:	83 ec 0c             	sub    $0xc,%esp
f01023f3:	6a 00                	push   $0x0
f01023f5:	e8 d5 e8 ff ff       	call   f0100ccf <page_alloc>
f01023fa:	89 c6                	mov    %eax,%esi
f01023fc:	83 c4 10             	add    $0x10,%esp
f01023ff:	85 c0                	test   %eax,%eax
f0102401:	75 19                	jne    f010241c <mem_init+0x147d>
f0102403:	68 22 54 10 f0       	push   $0xf0105422
f0102408:	68 4b 53 10 f0       	push   $0xf010534b
f010240d:	68 de 03 00 00       	push   $0x3de
f0102412:	68 25 53 10 f0       	push   $0xf0105325
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
f0102444:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0102449:	6a 56                	push   $0x56
f010244b:	68 31 53 10 f0       	push   $0xf0105331
f0102450:	e8 4b dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102455:	83 ec 04             	sub    $0x4,%esp
f0102458:	68 00 10 00 00       	push   $0x1000
f010245d:	6a 01                	push   $0x1
f010245f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102464:	50                   	push   %eax
f0102465:	e8 9a 1d 00 00       	call   f0104204 <memset>
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
f0102489:	68 3c 4b 10 f0       	push   $0xf0104b3c
f010248e:	6a 56                	push   $0x56
f0102490:	68 31 53 10 f0       	push   $0xf0105331
f0102495:	e8 06 dc ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010249a:	83 ec 04             	sub    $0x4,%esp
f010249d:	68 00 10 00 00       	push   $0x1000
f01024a2:	6a 02                	push   $0x2
f01024a4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024a9:	50                   	push   %eax
f01024aa:	e8 55 1d 00 00       	call   f0104204 <memset>
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
f01024cc:	68 f3 54 10 f0       	push   $0xf01054f3
f01024d1:	68 4b 53 10 f0       	push   $0xf010534b
f01024d6:	68 e3 03 00 00       	push   $0x3e3
f01024db:	68 25 53 10 f0       	push   $0xf0105325
f01024e0:	e8 bb db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024e5:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024ec:	01 01 01 
f01024ef:	74 19                	je     f010250a <mem_init+0x156b>
f01024f1:	68 50 52 10 f0       	push   $0xf0105250
f01024f6:	68 4b 53 10 f0       	push   $0xf010534b
f01024fb:	68 e4 03 00 00       	push   $0x3e4
f0102500:	68 25 53 10 f0       	push   $0xf0105325
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
f010252c:	68 74 52 10 f0       	push   $0xf0105274
f0102531:	68 4b 53 10 f0       	push   $0xf010534b
f0102536:	68 e6 03 00 00       	push   $0x3e6
f010253b:	68 25 53 10 f0       	push   $0xf0105325
f0102540:	e8 5b db ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0102545:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010254a:	74 19                	je     f0102565 <mem_init+0x15c6>
f010254c:	68 15 55 10 f0       	push   $0xf0105515
f0102551:	68 4b 53 10 f0       	push   $0xf010534b
f0102556:	68 e7 03 00 00       	push   $0x3e7
f010255b:	68 25 53 10 f0       	push   $0xf0105325
f0102560:	e8 3b db ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0102565:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010256a:	74 19                	je     f0102585 <mem_init+0x15e6>
f010256c:	68 7f 55 10 f0       	push   $0xf010557f
f0102571:	68 4b 53 10 f0       	push   $0xf010534b
f0102576:	68 e8 03 00 00       	push   $0x3e8
f010257b:	68 25 53 10 f0       	push   $0xf0105325
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
f01025ab:	68 3c 4b 10 f0       	push   $0xf0104b3c
f01025b0:	6a 56                	push   $0x56
f01025b2:	68 31 53 10 f0       	push   $0xf0105331
f01025b7:	e8 e4 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025bc:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025c3:	03 03 03 
f01025c6:	74 19                	je     f01025e1 <mem_init+0x1642>
f01025c8:	68 98 52 10 f0       	push   $0xf0105298
f01025cd:	68 4b 53 10 f0       	push   $0xf010534b
f01025d2:	68 ea 03 00 00       	push   $0x3ea
f01025d7:	68 25 53 10 f0       	push   $0xf0105325
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
f01025fe:	68 4d 55 10 f0       	push   $0xf010554d
f0102603:	68 4b 53 10 f0       	push   $0xf010534b
f0102608:	68 ec 03 00 00       	push   $0x3ec
f010260d:	68 25 53 10 f0       	push   $0xf0105325
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
f0102637:	68 a4 4d 10 f0       	push   $0xf0104da4
f010263c:	68 4b 53 10 f0       	push   $0xf010534b
f0102641:	68 ef 03 00 00       	push   $0x3ef
f0102646:	68 25 53 10 f0       	push   $0xf0105325
f010264b:	e8 50 da ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102650:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102656:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010265b:	74 19                	je     f0102676 <mem_init+0x16d7>
f010265d:	68 04 55 10 f0       	push   $0xf0105504
f0102662:	68 4b 53 10 f0       	push   $0xf010534b
f0102667:	68 f1 03 00 00       	push   $0x3f1
f010266c:	68 25 53 10 f0       	push   $0xf0105325
f0102671:	e8 2a da ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102676:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010267c:	83 ec 0c             	sub    $0xc,%esp
f010267f:	53                   	push   %ebx
f0102680:	e8 ba e6 ff ff       	call   f0100d3f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102685:	c7 04 24 c4 52 10 f0 	movl   $0xf01052c4,(%esp)
f010268c:	e8 ac 07 00 00       	call   f0102e3d <cprintf>
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
f01026aa:	57                   	push   %edi
f01026ab:	56                   	push   %esi
f01026ac:	53                   	push   %ebx
f01026ad:	83 ec 1c             	sub    $0x1c,%esp
f01026b0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01026b3:	8b 45 0c             	mov    0xc(%ebp),%eax
	uintptr_t lva=(uintptr_t)va;
f01026b6:	89 c3                	mov    %eax,%ebx
	uintptr_t rva=(uintptr_t)va+len-1;
f01026b8:	8b 55 10             	mov    0x10(%ebp),%edx
f01026bb:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f01026bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm=perm|PTE_U|PTE_P;
f01026c2:	8b 75 14             	mov    0x14(%ebp),%esi
f01026c5:	83 ce 05             	or     $0x5,%esi
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f01026c8:	eb 4b                	jmp    f0102715 <user_mem_check+0x6e>
	{
		if(idx_va>=ULIM)
f01026ca:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01026d0:	76 0d                	jbe    f01026df <user_mem_check+0x38>
		{
			user_mem_check_addr=idx_va;
f01026d2:	89 1d 3c be 17 f0    	mov    %ebx,0xf017be3c
			return-E_FAULT;
f01026d8:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01026dd:	eb 40                	jmp    f010271f <user_mem_check+0x78>
		}
		pte=pgdir_walk(env->env_pgdir,(void*)idx_va,0);
f01026df:	83 ec 04             	sub    $0x4,%esp
f01026e2:	6a 00                	push   $0x0
f01026e4:	53                   	push   %ebx
f01026e5:	ff 77 5c             	pushl  0x5c(%edi)
f01026e8:	e8 b6 e6 ff ff       	call   f0100da3 <pgdir_walk>
		if(pte==NULL||(*pte&perm)!=perm)
f01026ed:	83 c4 10             	add    $0x10,%esp
f01026f0:	85 c0                	test   %eax,%eax
f01026f2:	74 08                	je     f01026fc <user_mem_check+0x55>
f01026f4:	89 f1                	mov    %esi,%ecx
f01026f6:	23 08                	and    (%eax),%ecx
f01026f8:	39 ce                	cmp    %ecx,%esi
f01026fa:	74 0d                	je     f0102709 <user_mem_check+0x62>
		{
			user_mem_check_addr=idx_va;
f01026fc:	89 1d 3c be 17 f0    	mov    %ebx,0xf017be3c
			return-E_FAULT;
f0102702:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102707:	eb 16                	jmp    f010271f <user_mem_check+0x78>
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
f0102709:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t lva=(uintptr_t)va;
	uintptr_t rva=(uintptr_t)va+len-1;
	perm=perm|PTE_U|PTE_P;
	pte_t *pte;
	uintptr_t idx_va;
	for(idx_va=lva;idx_va<=rva;idx_va+=PGSIZE)
f010270f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102715:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102718:	76 b0                	jbe    f01026ca <user_mem_check+0x23>
			user_mem_check_addr=idx_va;
			return-E_FAULT;
		}
		idx_va=ROUNDDOWN(idx_va,PGSIZE);
	}
	return	0;
f010271a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010271f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102722:	5b                   	pop    %ebx
f0102723:	5e                   	pop    %esi
f0102724:	5f                   	pop    %edi
f0102725:	5d                   	pop    %ebp
f0102726:	c3                   	ret    

f0102727 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102727:	55                   	push   %ebp
f0102728:	89 e5                	mov    %esp,%ebp
f010272a:	53                   	push   %ebx
f010272b:	83 ec 04             	sub    $0x4,%esp
f010272e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102731:	8b 45 14             	mov    0x14(%ebp),%eax
f0102734:	83 c8 04             	or     $0x4,%eax
f0102737:	50                   	push   %eax
f0102738:	ff 75 10             	pushl  0x10(%ebp)
f010273b:	ff 75 0c             	pushl  0xc(%ebp)
f010273e:	53                   	push   %ebx
f010273f:	e8 63 ff ff ff       	call   f01026a7 <user_mem_check>
f0102744:	83 c4 10             	add    $0x10,%esp
f0102747:	85 c0                	test   %eax,%eax
f0102749:	79 21                	jns    f010276c <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010274b:	83 ec 04             	sub    $0x4,%esp
f010274e:	ff 35 3c be 17 f0    	pushl  0xf017be3c
f0102754:	ff 73 48             	pushl  0x48(%ebx)
f0102757:	68 f0 52 10 f0       	push   $0xf01052f0
f010275c:	e8 dc 06 00 00       	call   f0102e3d <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102761:	89 1c 24             	mov    %ebx,(%esp)
f0102764:	e8 bb 05 00 00       	call   f0102d24 <env_destroy>
f0102769:	83 c4 10             	add    $0x10,%esp
	}
}
f010276c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010276f:	c9                   	leave  
f0102770:	c3                   	ret    

f0102771 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102771:	55                   	push   %ebp
f0102772:	89 e5                	mov    %esp,%ebp
f0102774:	57                   	push   %edi
f0102775:	56                   	push   %esi
f0102776:	53                   	push   %ebx
f0102777:	83 ec 0c             	sub    $0xc,%esp
f010277a:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
f010277c:	89 d3                	mov    %edx,%ebx
f010277e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
f0102784:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010278b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *pp;
	while(low<high)
f0102791:	eb 5d                	jmp    f01027f0 <region_alloc+0x7f>
	{
		pp=page_alloc(ALLOC_ZERO );
f0102793:	83 ec 0c             	sub    $0xc,%esp
f0102796:	6a 01                	push   $0x1
f0102798:	e8 32 e5 ff ff       	call   f0100ccf <page_alloc>
		pp->pp_ref++;
f010279d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		if(pp==NULL)
f01027a2:	83 c4 10             	add    $0x10,%esp
f01027a5:	85 c0                	test   %eax,%eax
f01027a7:	75 17                	jne    f01027c0 <region_alloc+0x4f>
		{
			panic("page_alloc is wrong in region_alloc\n");
f01027a9:	83 ec 04             	sub    $0x4,%esp
f01027ac:	68 08 56 10 f0       	push   $0xf0105608
f01027b1:	68 1a 01 00 00       	push   $0x11a
f01027b6:	68 9e 56 10 f0       	push   $0xf010569e
f01027bb:	e8 e0 d8 ff ff       	call   f01000a0 <_panic>
		}
		int i=page_insert(e->env_pgdir,pp,(void *)low,PTE_P|PTE_U|PTE_W);
f01027c0:	6a 07                	push   $0x7
f01027c2:	53                   	push   %ebx
f01027c3:	50                   	push   %eax
f01027c4:	ff 77 5c             	pushl  0x5c(%edi)
f01027c7:	e8 5b e7 ff ff       	call   f0100f27 <page_insert>
		if(i!=0)
f01027cc:	83 c4 10             	add    $0x10,%esp
f01027cf:	85 c0                	test   %eax,%eax
f01027d1:	74 17                	je     f01027ea <region_alloc+0x79>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
f01027d3:	83 ec 04             	sub    $0x4,%esp
f01027d6:	68 30 56 10 f0       	push   $0xf0105630
f01027db:	68 1f 01 00 00       	push   $0x11f
f01027e0:	68 9e 56 10 f0       	push   $0xf010569e
f01027e5:	e8 b6 d8 ff ff       	call   f01000a0 <_panic>
		}
		low=low+PGSIZE;
f01027ea:	81 c3 00 10 00 00    	add    $0x1000,%ebx
{
	// LAB 3: Your code here.
	uint32_t low=ROUNDDOWN((uint32_t)va,PGSIZE);
	uint32_t high=ROUNDUP((uint32_t)va+len,PGSIZE);
	struct PageInfo *pp;
	while(low<high)
f01027f0:	39 f3                	cmp    %esi,%ebx
f01027f2:	72 9f                	jb     f0102793 <region_alloc+0x22>
		{
			panic("functiuon named pgdir_walk is wrong in region_alloc\n");
		}
		low=low+PGSIZE;
	}
} 
f01027f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027f7:	5b                   	pop    %ebx
f01027f8:	5e                   	pop    %esi
f01027f9:	5f                   	pop    %edi
f01027fa:	5d                   	pop    %ebp
f01027fb:	c3                   	ret    

f01027fc <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01027fc:	55                   	push   %ebp
f01027fd:	89 e5                	mov    %esp,%ebp
f01027ff:	8b 55 08             	mov    0x8(%ebp),%edx
f0102802:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102805:	85 d2                	test   %edx,%edx
f0102807:	75 11                	jne    f010281a <envid2env+0x1e>
		*env_store = curenv;
f0102809:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f010280e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102811:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102813:	b8 00 00 00 00       	mov    $0x0,%eax
f0102818:	eb 5e                	jmp    f0102878 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010281a:	89 d0                	mov    %edx,%eax
f010281c:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102821:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102824:	c1 e0 05             	shl    $0x5,%eax
f0102827:	03 05 48 be 17 f0    	add    0xf017be48,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010282d:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102831:	74 05                	je     f0102838 <envid2env+0x3c>
f0102833:	3b 50 48             	cmp    0x48(%eax),%edx
f0102836:	74 10                	je     f0102848 <envid2env+0x4c>
		*env_store = 0;
f0102838:	8b 45 0c             	mov    0xc(%ebp),%eax
f010283b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102841:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102846:	eb 30                	jmp    f0102878 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102848:	84 c9                	test   %cl,%cl
f010284a:	74 22                	je     f010286e <envid2env+0x72>
f010284c:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102852:	39 d0                	cmp    %edx,%eax
f0102854:	74 18                	je     f010286e <envid2env+0x72>
f0102856:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102859:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010285c:	74 10                	je     f010286e <envid2env+0x72>
		*env_store = 0;
f010285e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102861:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102867:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010286c:	eb 0a                	jmp    f0102878 <envid2env+0x7c>
	}

	*env_store = e;
f010286e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102871:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102873:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102878:	5d                   	pop    %ebp
f0102879:	c3                   	ret    

f010287a <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010287a:	55                   	push   %ebp
f010287b:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010287d:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102882:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102885:	b8 23 00 00 00       	mov    $0x23,%eax
f010288a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010288c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010288e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102893:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102895:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102897:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102899:	ea a0 28 10 f0 08 00 	ljmp   $0x8,$0xf01028a0
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01028a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01028a5:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01028a8:	5d                   	pop    %ebp
f01028a9:	c3                   	ret    

f01028aa <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01028aa:	55                   	push   %ebp
f01028ab:	89 e5                	mov    %esp,%ebp
f01028ad:	56                   	push   %esi
f01028ae:	53                   	push   %ebx
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
	{
		envs[i].env_id=0;
f01028af:	8b 35 48 be 17 f0    	mov    0xf017be48,%esi
f01028b5:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01028bb:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01028be:	ba 00 00 00 00       	mov    $0x0,%edx
f01028c3:	89 c1                	mov    %eax,%ecx
f01028c5:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status=ENV_FREE;
f01028cc:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link=env_free_list;
f01028d3:	89 50 44             	mov    %edx,0x44(%eax)
f01028d6:	83 e8 60             	sub    $0x60,%eax
		env_free_list=&envs[i];
f01028d9:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list=NULL;
	int i;
	for(i=NENV-1;i>=0;i--)
f01028db:	39 d8                	cmp    %ebx,%eax
f01028dd:	75 e4                	jne    f01028c3 <env_init+0x19>
f01028df:	89 35 4c be 17 f0    	mov    %esi,0xf017be4c
		envs[i].env_link=env_free_list;
		env_free_list=&envs[i];
	}	
	//cprintf("%d\n",sizeof(struct Env));	
	// Per-CPU part of the initialization
	env_init_percpu();
f01028e5:	e8 90 ff ff ff       	call   f010287a <env_init_percpu>
}
f01028ea:	5b                   	pop    %ebx
f01028eb:	5e                   	pop    %esi
f01028ec:	5d                   	pop    %ebp
f01028ed:	c3                   	ret    

f01028ee <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01028ee:	55                   	push   %ebp
f01028ef:	89 e5                	mov    %esp,%ebp
f01028f1:	53                   	push   %ebx
f01028f2:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01028f5:	8b 1d 4c be 17 f0    	mov    0xf017be4c,%ebx
f01028fb:	85 db                	test   %ebx,%ebx
f01028fd:	0f 84 43 01 00 00    	je     f0102a46 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102903:	83 ec 0c             	sub    $0xc,%esp
f0102906:	6a 01                	push   $0x1
f0102908:	e8 c2 e3 ff ff       	call   f0100ccf <page_alloc>
f010290d:	83 c4 10             	add    $0x10,%esp
f0102910:	85 c0                	test   %eax,%eax
f0102912:	0f 84 35 01 00 00    	je     f0102a4d <env_alloc+0x15f>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102918:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010291d:	2b 05 0c cb 17 f0    	sub    0xf017cb0c,%eax
f0102923:	c1 f8 03             	sar    $0x3,%eax
f0102926:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102929:	89 c2                	mov    %eax,%edx
f010292b:	c1 ea 0c             	shr    $0xc,%edx
f010292e:	3b 15 04 cb 17 f0    	cmp    0xf017cb04,%edx
f0102934:	72 12                	jb     f0102948 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102936:	50                   	push   %eax
f0102937:	68 3c 4b 10 f0       	push   $0xf0104b3c
f010293c:	6a 56                	push   $0x56
f010293e:	68 31 53 10 f0       	push   $0xf0105331
f0102943:	e8 58 d7 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102948:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir=(pte_t *)page2kva(p);
f010294d:	89 43 5c             	mov    %eax,0x5c(%ebx)
	memcpy(e->env_pgdir,kern_pgdir,PGSIZE);
f0102950:	83 ec 04             	sub    $0x4,%esp
f0102953:	68 00 10 00 00       	push   $0x1000
f0102958:	ff 35 08 cb 17 f0    	pushl  0xf017cb08
f010295e:	50                   	push   %eax
f010295f:	e8 55 19 00 00       	call   f01042b9 <memcpy>
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102964:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102967:	83 c4 10             	add    $0x10,%esp
f010296a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010296f:	77 15                	ja     f0102986 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102971:	50                   	push   %eax
f0102972:	68 24 4c 10 f0       	push   $0xf0104c24
f0102977:	68 c4 00 00 00       	push   $0xc4
f010297c:	68 9e 56 10 f0       	push   $0xf010569e
f0102981:	e8 1a d7 ff ff       	call   f01000a0 <_panic>
f0102986:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010298c:	83 ca 05             	or     $0x5,%edx
f010298f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102995:	8b 43 48             	mov    0x48(%ebx),%eax
f0102998:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f010299d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029a2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029a7:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029aa:	89 da                	mov    %ebx,%edx
f01029ac:	2b 15 48 be 17 f0    	sub    0xf017be48,%edx
f01029b2:	c1 fa 05             	sar    $0x5,%edx
f01029b5:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01029bb:	09 d0                	or     %edx,%eax
f01029bd:	89 43 48             	mov    %eax,0x48(%ebx)
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01029c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029c3:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01029c6:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01029cd:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01029d4:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01029db:	83 ec 04             	sub    $0x4,%esp
f01029de:	6a 44                	push   $0x44
f01029e0:	6a 00                	push   $0x0
f01029e2:	53                   	push   %ebx
f01029e3:	e8 1c 18 00 00       	call   f0104204 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01029e8:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01029ee:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01029f4:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01029fa:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a01:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a07:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a0a:	a3 4c be 17 f0       	mov    %eax,0xf017be4c
	*newenv_store = e;
f0102a0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a12:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a14:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a17:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0102a1c:	83 c4 10             	add    $0x10,%esp
f0102a1f:	85 c0                	test   %eax,%eax
f0102a21:	74 05                	je     f0102a28 <env_alloc+0x13a>
f0102a23:	8b 40 48             	mov    0x48(%eax),%eax
f0102a26:	eb 05                	jmp    f0102a2d <env_alloc+0x13f>
f0102a28:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a2d:	83 ec 04             	sub    $0x4,%esp
f0102a30:	52                   	push   %edx
f0102a31:	50                   	push   %eax
f0102a32:	68 a9 56 10 f0       	push   $0xf01056a9
f0102a37:	e8 01 04 00 00       	call   f0102e3d <cprintf>
	return 0;
f0102a3c:	83 c4 10             	add    $0x10,%esp
f0102a3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a44:	eb 0c                	jmp    f0102a52 <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a46:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a4b:	eb 05                	jmp    f0102a52 <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a4d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a52:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a55:	c9                   	leave  
f0102a56:	c3                   	ret    

f0102a57 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102a57:	55                   	push   %ebp
f0102a58:	89 e5                	mov    %esp,%ebp
f0102a5a:	57                   	push   %edi
f0102a5b:	56                   	push   %esi
f0102a5c:	53                   	push   %ebx
f0102a5d:	83 ec 34             	sub    $0x34,%esp
f0102a60:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	uint32_t r=env_alloc(&e,0);
f0102a63:	6a 00                	push   $0x0
f0102a65:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102a68:	50                   	push   %eax
f0102a69:	e8 80 fe ff ff       	call   f01028ee <env_alloc>
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
f0102a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf *elf=(struct Elf *)binary;
	if(elf->e_magic!=ELF_MAGIC)
f0102a74:	83 c4 10             	add    $0x10,%esp
f0102a77:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102a7d:	74 17                	je     f0102a96 <env_create+0x3f>
		panic("binary document is error\n");
f0102a7f:	83 ec 04             	sub    $0x4,%esp
f0102a82:	68 be 56 10 f0       	push   $0xf01056be
f0102a87:	68 64 01 00 00       	push   $0x164
f0102a8c:	68 9e 56 10 f0       	push   $0xf010569e
f0102a91:	e8 0a d6 ff ff       	call   f01000a0 <_panic>
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
f0102a96:	89 fb                	mov    %edi,%ebx
f0102a98:	03 5f 1c             	add    0x1c(%edi),%ebx
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
f0102a9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a9e:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aa1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102aa6:	77 15                	ja     f0102abd <env_create+0x66>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102aa8:	50                   	push   %eax
f0102aa9:	68 24 4c 10 f0       	push   $0xf0104c24
f0102aae:	68 67 01 00 00       	push   $0x167
f0102ab3:	68 9e 56 10 f0       	push   $0xf010569e
f0102ab8:	e8 e3 d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102abd:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ac2:	0f 22 d8             	mov    %eax,%cr3
	for(i=0;i<elf->e_phnum;i++)
f0102ac5:	be 00 00 00 00       	mov    $0x0,%esi
f0102aca:	eb 40                	jmp    f0102b0c <env_create+0xb5>
	{
		//cprintf("%d\n",ph->p_type);
		if(ph->p_type==ELF_PROG_LOAD)
f0102acc:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102acf:	75 35                	jne    f0102b06 <env_create+0xaf>
		{
			//cprintf("load\n");
			region_alloc(e,(void *)ph->p_va,ph->p_memsz);
f0102ad1:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102ad4:	8b 53 08             	mov    0x8(%ebx),%edx
f0102ad7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ada:	e8 92 fc ff ff       	call   f0102771 <region_alloc>
			memset((void *)(ph->p_va),0,ph->p_memsz);
f0102adf:	83 ec 04             	sub    $0x4,%esp
f0102ae2:	ff 73 14             	pushl  0x14(%ebx)
f0102ae5:	6a 00                	push   $0x0
f0102ae7:	ff 73 08             	pushl  0x8(%ebx)
f0102aea:	e8 15 17 00 00       	call   f0104204 <memset>
			memcpy((void *)(ph->p_va),(binary+ph->p_offset), ph->p_filesz);
f0102aef:	83 c4 0c             	add    $0xc,%esp
f0102af2:	ff 73 10             	pushl  0x10(%ebx)
f0102af5:	89 f8                	mov    %edi,%eax
f0102af7:	03 43 04             	add    0x4(%ebx),%eax
f0102afa:	50                   	push   %eax
f0102afb:	ff 73 08             	pushl  0x8(%ebx)
f0102afe:	e8 b6 17 00 00       	call   f01042b9 <memcpy>
f0102b03:	83 c4 10             	add    $0x10,%esp
			//cprintf("%08x\n",ph->p_va);
		}
		ph++;
f0102b06:	83 c3 20             	add    $0x20,%ebx
	if(elf->e_magic!=ELF_MAGIC)
		panic("binary document is error\n");
	struct Proghdr *ph=(struct Proghdr *)(binary+elf->e_phoff);
	uint32_t i;
	lcr3(PADDR(e->env_pgdir));
	for(i=0;i<elf->e_phnum;i++)
f0102b09:	83 c6 01             	add    $0x1,%esi
f0102b0c:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0102b10:	39 c6                	cmp    %eax,%esi
f0102b12:	72 b8                	jb     f0102acc <env_create+0x75>
		}
		ph++;
	}
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	e->env_tf.tf_eip=elf->e_entry;
f0102b14:	8b 47 18             	mov    0x18(%edi),%eax
f0102b17:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b1a:	89 47 30             	mov    %eax,0x30(%edi)
	// LAB 3: Your code here.
	region_alloc(e,(void *)(USTACKTOP - PGSIZE),PGSIZE);
f0102b1d:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102b22:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102b27:	89 f8                	mov    %edi,%eax
f0102b29:	e8 43 fc ff ff       	call   f0102771 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f0102b2e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b33:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b38:	77 15                	ja     f0102b4f <env_create+0xf8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b3a:	50                   	push   %eax
f0102b3b:	68 24 4c 10 f0       	push   $0xf0104c24
f0102b40:	68 7a 01 00 00       	push   $0x17a
f0102b45:	68 9e 56 10 f0       	push   $0xf010569e
f0102b4a:	e8 51 d5 ff ff       	call   f01000a0 <_panic>
f0102b4f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b54:	0f 22 d8             	mov    %eax,%cr3
	if(r<0)
	{
		panic("creating  env  is  wrong!\n");
	}
	load_icode(e,binary);
	e->env_type=type;
f0102b57:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b5a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b5d:	89 50 50             	mov    %edx,0x50(%eax)
	
}
f0102b60:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b63:	5b                   	pop    %ebx
f0102b64:	5e                   	pop    %esi
f0102b65:	5f                   	pop    %edi
f0102b66:	5d                   	pop    %ebp
f0102b67:	c3                   	ret    

f0102b68 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102b68:	55                   	push   %ebp
f0102b69:	89 e5                	mov    %esp,%ebp
f0102b6b:	57                   	push   %edi
f0102b6c:	56                   	push   %esi
f0102b6d:	53                   	push   %ebx
f0102b6e:	83 ec 1c             	sub    $0x1c,%esp
f0102b71:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102b74:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102b7a:	39 fa                	cmp    %edi,%edx
f0102b7c:	75 29                	jne    f0102ba7 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102b7e:	a1 08 cb 17 f0       	mov    0xf017cb08,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b83:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b88:	77 15                	ja     f0102b9f <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b8a:	50                   	push   %eax
f0102b8b:	68 24 4c 10 f0       	push   $0xf0104c24
f0102b90:	68 a1 01 00 00       	push   $0x1a1
f0102b95:	68 9e 56 10 f0       	push   $0xf010569e
f0102b9a:	e8 01 d5 ff ff       	call   f01000a0 <_panic>
f0102b9f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ba4:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ba7:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102baa:	85 d2                	test   %edx,%edx
f0102bac:	74 05                	je     f0102bb3 <env_free+0x4b>
f0102bae:	8b 42 48             	mov    0x48(%edx),%eax
f0102bb1:	eb 05                	jmp    f0102bb8 <env_free+0x50>
f0102bb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb8:	83 ec 04             	sub    $0x4,%esp
f0102bbb:	51                   	push   %ecx
f0102bbc:	50                   	push   %eax
f0102bbd:	68 d8 56 10 f0       	push   $0xf01056d8
f0102bc2:	e8 76 02 00 00       	call   f0102e3d <cprintf>
f0102bc7:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102bca:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102bd1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102bd4:	89 d0                	mov    %edx,%eax
f0102bd6:	c1 e0 02             	shl    $0x2,%eax
f0102bd9:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102bdc:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102bdf:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102be2:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102be8:	0f 84 a8 00 00 00    	je     f0102c96 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102bee:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf4:	89 f0                	mov    %esi,%eax
f0102bf6:	c1 e8 0c             	shr    $0xc,%eax
f0102bf9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bfc:	39 05 04 cb 17 f0    	cmp    %eax,0xf017cb04
f0102c02:	77 15                	ja     f0102c19 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c04:	56                   	push   %esi
f0102c05:	68 3c 4b 10 f0       	push   $0xf0104b3c
f0102c0a:	68 b0 01 00 00       	push   $0x1b0
f0102c0f:	68 9e 56 10 f0       	push   $0xf010569e
f0102c14:	e8 87 d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c19:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c1c:	c1 e0 16             	shl    $0x16,%eax
f0102c1f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c22:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102c27:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102c2e:	01 
f0102c2f:	74 17                	je     f0102c48 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c31:	83 ec 08             	sub    $0x8,%esp
f0102c34:	89 d8                	mov    %ebx,%eax
f0102c36:	c1 e0 0c             	shl    $0xc,%eax
f0102c39:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102c3c:	50                   	push   %eax
f0102c3d:	ff 77 5c             	pushl  0x5c(%edi)
f0102c40:	e8 a0 e2 ff ff       	call   f0100ee5 <page_remove>
f0102c45:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c48:	83 c3 01             	add    $0x1,%ebx
f0102c4b:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102c51:	75 d4                	jne    f0102c27 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102c53:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c56:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102c59:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c60:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102c63:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102c69:	72 14                	jb     f0102c7f <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102c6b:	83 ec 04             	sub    $0x4,%esp
f0102c6e:	68 70 4c 10 f0       	push   $0xf0104c70
f0102c73:	6a 4f                	push   $0x4f
f0102c75:	68 31 53 10 f0       	push   $0xf0105331
f0102c7a:	e8 21 d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102c7f:	83 ec 0c             	sub    $0xc,%esp
f0102c82:	a1 0c cb 17 f0       	mov    0xf017cb0c,%eax
f0102c87:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c8a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102c8d:	50                   	push   %eax
f0102c8e:	e8 e9 e0 ff ff       	call   f0100d7c <page_decref>
f0102c93:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c96:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102c9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c9d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102ca2:	0f 85 29 ff ff ff    	jne    f0102bd1 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102ca8:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cb0:	77 15                	ja     f0102cc7 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cb2:	50                   	push   %eax
f0102cb3:	68 24 4c 10 f0       	push   $0xf0104c24
f0102cb8:	68 be 01 00 00       	push   $0x1be
f0102cbd:	68 9e 56 10 f0       	push   $0xf010569e
f0102cc2:	e8 d9 d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102cc7:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cce:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cd3:	c1 e8 0c             	shr    $0xc,%eax
f0102cd6:	3b 05 04 cb 17 f0    	cmp    0xf017cb04,%eax
f0102cdc:	72 14                	jb     f0102cf2 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102cde:	83 ec 04             	sub    $0x4,%esp
f0102ce1:	68 70 4c 10 f0       	push   $0xf0104c70
f0102ce6:	6a 4f                	push   $0x4f
f0102ce8:	68 31 53 10 f0       	push   $0xf0105331
f0102ced:	e8 ae d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102cf2:	83 ec 0c             	sub    $0xc,%esp
f0102cf5:	8b 15 0c cb 17 f0    	mov    0xf017cb0c,%edx
f0102cfb:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102cfe:	50                   	push   %eax
f0102cff:	e8 78 e0 ff ff       	call   f0100d7c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d04:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d0b:	a1 4c be 17 f0       	mov    0xf017be4c,%eax
f0102d10:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d13:	89 3d 4c be 17 f0    	mov    %edi,0xf017be4c
}
f0102d19:	83 c4 10             	add    $0x10,%esp
f0102d1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d1f:	5b                   	pop    %ebx
f0102d20:	5e                   	pop    %esi
f0102d21:	5f                   	pop    %edi
f0102d22:	5d                   	pop    %ebp
f0102d23:	c3                   	ret    

f0102d24 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102d24:	55                   	push   %ebp
f0102d25:	89 e5                	mov    %esp,%ebp
f0102d27:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102d2a:	ff 75 08             	pushl  0x8(%ebp)
f0102d2d:	e8 36 fe ff ff       	call   f0102b68 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102d32:	c7 04 24 68 56 10 f0 	movl   $0xf0105668,(%esp)
f0102d39:	e8 ff 00 00 00       	call   f0102e3d <cprintf>
f0102d3e:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102d41:	83 ec 0c             	sub    $0xc,%esp
f0102d44:	6a 00                	push   $0x0
f0102d46:	e8 e7 d9 ff ff       	call   f0100732 <monitor>
f0102d4b:	83 c4 10             	add    $0x10,%esp
f0102d4e:	eb f1                	jmp    f0102d41 <env_destroy+0x1d>

f0102d50 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102d50:	55                   	push   %ebp
f0102d51:	89 e5                	mov    %esp,%ebp
f0102d53:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102d56:	8b 65 08             	mov    0x8(%ebp),%esp
f0102d59:	61                   	popa   
f0102d5a:	07                   	pop    %es
f0102d5b:	1f                   	pop    %ds
f0102d5c:	83 c4 08             	add    $0x8,%esp
f0102d5f:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102d60:	68 ee 56 10 f0       	push   $0xf01056ee
f0102d65:	68 e7 01 00 00       	push   $0x1e7
f0102d6a:	68 9e 56 10 f0       	push   $0xf010569e
f0102d6f:	e8 2c d3 ff ff       	call   f01000a0 <_panic>

f0102d74 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102d74:	55                   	push   %ebp
f0102d75:	89 e5                	mov    %esp,%ebp
f0102d77:	83 ec 08             	sub    $0x8,%esp
f0102d7a:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv&&curenv->env_status==ENV_RUNNING)
f0102d7d:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f0102d83:	85 d2                	test   %edx,%edx
f0102d85:	74 0d                	je     f0102d94 <env_run+0x20>
f0102d87:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102d8b:	75 07                	jne    f0102d94 <env_run+0x20>
	{
		curenv->env_status=ENV_RUNNABLE;
f0102d8d:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv=e;
f0102d94:	a3 44 be 17 f0       	mov    %eax,0xf017be44
	curenv->env_status=ENV_RUNNING;
f0102d99:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	e->env_runs++;
f0102da0:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0102da4:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102da7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102dad:	77 15                	ja     f0102dc4 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102daf:	52                   	push   %edx
f0102db0:	68 24 4c 10 f0       	push   $0xf0104c24
f0102db5:	68 0c 02 00 00       	push   $0x20c
f0102dba:	68 9e 56 10 f0       	push   $0xf010569e
f0102dbf:	e8 dc d2 ff ff       	call   f01000a0 <_panic>
f0102dc4:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102dca:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(curenv->env_tf));
f0102dcd:	83 ec 0c             	sub    $0xc,%esp
f0102dd0:	50                   	push   %eax
f0102dd1:	e8 7a ff ff ff       	call   f0102d50 <env_pop_tf>

f0102dd6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102dd6:	55                   	push   %ebp
f0102dd7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102dd9:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dde:	8b 45 08             	mov    0x8(%ebp),%eax
f0102de1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102de2:	ba 71 00 00 00       	mov    $0x71,%edx
f0102de7:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102de8:	0f b6 c0             	movzbl %al,%eax
}
f0102deb:	5d                   	pop    %ebp
f0102dec:	c3                   	ret    

f0102ded <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ded:	55                   	push   %ebp
f0102dee:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102df0:	ba 70 00 00 00       	mov    $0x70,%edx
f0102df5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102df8:	ee                   	out    %al,(%dx)
f0102df9:	ba 71 00 00 00       	mov    $0x71,%edx
f0102dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e01:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e02:	5d                   	pop    %ebp
f0102e03:	c3                   	ret    

f0102e04 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e04:	55                   	push   %ebp
f0102e05:	89 e5                	mov    %esp,%ebp
f0102e07:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e0a:	ff 75 08             	pushl  0x8(%ebp)
f0102e0d:	e8 03 d8 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102e12:	83 c4 10             	add    $0x10,%esp
f0102e15:	c9                   	leave  
f0102e16:	c3                   	ret    

f0102e17 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e17:	55                   	push   %ebp
f0102e18:	89 e5                	mov    %esp,%ebp
f0102e1a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e24:	ff 75 0c             	pushl  0xc(%ebp)
f0102e27:	ff 75 08             	pushl  0x8(%ebp)
f0102e2a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e2d:	50                   	push   %eax
f0102e2e:	68 04 2e 10 f0       	push   $0xf0102e04
f0102e33:	e8 a7 0c 00 00       	call   f0103adf <vprintfmt>
	return cnt;
}
f0102e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e3b:	c9                   	leave  
f0102e3c:	c3                   	ret    

f0102e3d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e3d:	55                   	push   %ebp
f0102e3e:	89 e5                	mov    %esp,%ebp
f0102e40:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e43:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e46:	50                   	push   %eax
f0102e47:	ff 75 08             	pushl  0x8(%ebp)
f0102e4a:	e8 c8 ff ff ff       	call   f0102e17 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e4f:	c9                   	leave  
f0102e50:	c3                   	ret    

f0102e51 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102e51:	55                   	push   %ebp
f0102e52:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102e54:	b8 80 c6 17 f0       	mov    $0xf017c680,%eax
f0102e59:	c7 05 84 c6 17 f0 00 	movl   $0xf0000000,0xf017c684
f0102e60:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102e63:	66 c7 05 88 c6 17 f0 	movw   $0x10,0xf017c688
f0102e6a:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102e6c:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102e73:	67 00 
f0102e75:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102e7b:	89 c2                	mov    %eax,%edx
f0102e7d:	c1 ea 10             	shr    $0x10,%edx
f0102e80:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102e86:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102e8d:	c1 e8 18             	shr    $0x18,%eax
f0102e90:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102e95:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102e9c:	b8 28 00 00 00       	mov    $0x28,%eax
f0102ea1:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102ea4:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102ea9:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102eac:	5d                   	pop    %ebp
f0102ead:	c3                   	ret    

f0102eae <trap_init>:
}


void
trap_init(void)
{
f0102eae:	55                   	push   %ebp
f0102eaf:	89 e5                	mov    %esp,%ebp
	extern void floating_point_error();
	extern void alignment_check();
	extern void machine_check(); 
	extern void simd_floating_error();
	extern void system_call(); 
	SETGATE(idt[0],0,GD_KT,divide_error,0);
f0102eb1:	b8 62 35 10 f0       	mov    $0xf0103562,%eax
f0102eb6:	66 a3 60 be 17 f0    	mov    %ax,0xf017be60
f0102ebc:	66 c7 05 62 be 17 f0 	movw   $0x8,0xf017be62
f0102ec3:	08 00 
f0102ec5:	c6 05 64 be 17 f0 00 	movb   $0x0,0xf017be64
f0102ecc:	c6 05 65 be 17 f0 8e 	movb   $0x8e,0xf017be65
f0102ed3:	c1 e8 10             	shr    $0x10,%eax
f0102ed6:	66 a3 66 be 17 f0    	mov    %ax,0xf017be66
	SETGATE(idt[1],0,GD_KT,debuf_exception,0);
f0102edc:	b8 68 35 10 f0       	mov    $0xf0103568,%eax
f0102ee1:	66 a3 68 be 17 f0    	mov    %ax,0xf017be68
f0102ee7:	66 c7 05 6a be 17 f0 	movw   $0x8,0xf017be6a
f0102eee:	08 00 
f0102ef0:	c6 05 6c be 17 f0 00 	movb   $0x0,0xf017be6c
f0102ef7:	c6 05 6d be 17 f0 8e 	movb   $0x8e,0xf017be6d
f0102efe:	c1 e8 10             	shr    $0x10,%eax
f0102f01:	66 a3 6e be 17 f0    	mov    %ax,0xf017be6e
	SETGATE(idt[2],0,GD_KT,nmi_interrupt,0);
f0102f07:	b8 6e 35 10 f0       	mov    $0xf010356e,%eax
f0102f0c:	66 a3 70 be 17 f0    	mov    %ax,0xf017be70
f0102f12:	66 c7 05 72 be 17 f0 	movw   $0x8,0xf017be72
f0102f19:	08 00 
f0102f1b:	c6 05 74 be 17 f0 00 	movb   $0x0,0xf017be74
f0102f22:	c6 05 75 be 17 f0 8e 	movb   $0x8e,0xf017be75
f0102f29:	c1 e8 10             	shr    $0x10,%eax
f0102f2c:	66 a3 76 be 17 f0    	mov    %ax,0xf017be76
	SETGATE(idt[3],0,GD_KT,break_point,3);
f0102f32:	b8 74 35 10 f0       	mov    $0xf0103574,%eax
f0102f37:	66 a3 78 be 17 f0    	mov    %ax,0xf017be78
f0102f3d:	66 c7 05 7a be 17 f0 	movw   $0x8,0xf017be7a
f0102f44:	08 00 
f0102f46:	c6 05 7c be 17 f0 00 	movb   $0x0,0xf017be7c
f0102f4d:	c6 05 7d be 17 f0 ee 	movb   $0xee,0xf017be7d
f0102f54:	c1 e8 10             	shr    $0x10,%eax
f0102f57:	66 a3 7e be 17 f0    	mov    %ax,0xf017be7e
	SETGATE(idt[4],0,GD_KT,overflow,0);
f0102f5d:	b8 7a 35 10 f0       	mov    $0xf010357a,%eax
f0102f62:	66 a3 80 be 17 f0    	mov    %ax,0xf017be80
f0102f68:	66 c7 05 82 be 17 f0 	movw   $0x8,0xf017be82
f0102f6f:	08 00 
f0102f71:	c6 05 84 be 17 f0 00 	movb   $0x0,0xf017be84
f0102f78:	c6 05 85 be 17 f0 8e 	movb   $0x8e,0xf017be85
f0102f7f:	c1 e8 10             	shr    $0x10,%eax
f0102f82:	66 a3 86 be 17 f0    	mov    %ax,0xf017be86
	SETGATE(idt[5],0,GD_KT,bound_check,0);
f0102f88:	b8 80 35 10 f0       	mov    $0xf0103580,%eax
f0102f8d:	66 a3 88 be 17 f0    	mov    %ax,0xf017be88
f0102f93:	66 c7 05 8a be 17 f0 	movw   $0x8,0xf017be8a
f0102f9a:	08 00 
f0102f9c:	c6 05 8c be 17 f0 00 	movb   $0x0,0xf017be8c
f0102fa3:	c6 05 8d be 17 f0 8e 	movb   $0x8e,0xf017be8d
f0102faa:	c1 e8 10             	shr    $0x10,%eax
f0102fad:	66 a3 8e be 17 f0    	mov    %ax,0xf017be8e
	SETGATE(idt[6],0,GD_KT,illegal_opcode,0);
f0102fb3:	b8 86 35 10 f0       	mov    $0xf0103586,%eax
f0102fb8:	66 a3 90 be 17 f0    	mov    %ax,0xf017be90
f0102fbe:	66 c7 05 92 be 17 f0 	movw   $0x8,0xf017be92
f0102fc5:	08 00 
f0102fc7:	c6 05 94 be 17 f0 00 	movb   $0x0,0xf017be94
f0102fce:	c6 05 95 be 17 f0 8e 	movb   $0x8e,0xf017be95
f0102fd5:	c1 e8 10             	shr    $0x10,%eax
f0102fd8:	66 a3 96 be 17 f0    	mov    %ax,0xf017be96
	SETGATE(idt[7],0,GD_KT,device_not_available,0);
f0102fde:	b8 8c 35 10 f0       	mov    $0xf010358c,%eax
f0102fe3:	66 a3 98 be 17 f0    	mov    %ax,0xf017be98
f0102fe9:	66 c7 05 9a be 17 f0 	movw   $0x8,0xf017be9a
f0102ff0:	08 00 
f0102ff2:	c6 05 9c be 17 f0 00 	movb   $0x0,0xf017be9c
f0102ff9:	c6 05 9d be 17 f0 8e 	movb   $0x8e,0xf017be9d
f0103000:	c1 e8 10             	shr    $0x10,%eax
f0103003:	66 a3 9e be 17 f0    	mov    %ax,0xf017be9e
	SETGATE(idt[8],0,GD_KT,segment_not_present,0);
f0103009:	ba 9a 35 10 f0       	mov    $0xf010359a,%edx
f010300e:	66 89 15 a0 be 17 f0 	mov    %dx,0xf017bea0
f0103015:	66 c7 05 a2 be 17 f0 	movw   $0x8,0xf017bea2
f010301c:	08 00 
f010301e:	c6 05 a4 be 17 f0 00 	movb   $0x0,0xf017bea4
f0103025:	c6 05 a5 be 17 f0 8e 	movb   $0x8e,0xf017bea5
f010302c:	89 d1                	mov    %edx,%ecx
f010302e:	c1 e9 10             	shr    $0x10,%ecx
f0103031:	66 89 0d a6 be 17 f0 	mov    %cx,0xf017bea6
	SETGATE(idt[10],0,GD_KT,invalid_tss,0);
f0103038:	b8 96 35 10 f0       	mov    $0xf0103596,%eax
f010303d:	66 a3 b0 be 17 f0    	mov    %ax,0xf017beb0
f0103043:	66 c7 05 b2 be 17 f0 	movw   $0x8,0xf017beb2
f010304a:	08 00 
f010304c:	c6 05 b4 be 17 f0 00 	movb   $0x0,0xf017beb4
f0103053:	c6 05 b5 be 17 f0 8e 	movb   $0x8e,0xf017beb5
f010305a:	c1 e8 10             	shr    $0x10,%eax
f010305d:	66 a3 b6 be 17 f0    	mov    %ax,0xf017beb6
	SETGATE(idt[11],0,GD_KT,segment_not_present,0);
f0103063:	66 89 15 b8 be 17 f0 	mov    %dx,0xf017beb8
f010306a:	66 c7 05 ba be 17 f0 	movw   $0x8,0xf017beba
f0103071:	08 00 
f0103073:	c6 05 bc be 17 f0 00 	movb   $0x0,0xf017bebc
f010307a:	c6 05 bd be 17 f0 8e 	movb   $0x8e,0xf017bebd
f0103081:	66 89 0d be be 17 f0 	mov    %cx,0xf017bebe
	SETGATE(idt[12],0,GD_KT,stack_exception,0);
f0103088:	b8 9e 35 10 f0       	mov    $0xf010359e,%eax
f010308d:	66 a3 c0 be 17 f0    	mov    %ax,0xf017bec0
f0103093:	66 c7 05 c2 be 17 f0 	movw   $0x8,0xf017bec2
f010309a:	08 00 
f010309c:	c6 05 c4 be 17 f0 00 	movb   $0x0,0xf017bec4
f01030a3:	c6 05 c5 be 17 f0 8e 	movb   $0x8e,0xf017bec5
f01030aa:	c1 e8 10             	shr    $0x10,%eax
f01030ad:	66 a3 c6 be 17 f0    	mov    %ax,0xf017bec6
	SETGATE(idt[13],0,GD_KT, general_protection_fault,0);
f01030b3:	b8 a2 35 10 f0       	mov    $0xf01035a2,%eax
f01030b8:	66 a3 c8 be 17 f0    	mov    %ax,0xf017bec8
f01030be:	66 c7 05 ca be 17 f0 	movw   $0x8,0xf017beca
f01030c5:	08 00 
f01030c7:	c6 05 cc be 17 f0 00 	movb   $0x0,0xf017becc
f01030ce:	c6 05 cd be 17 f0 8e 	movb   $0x8e,0xf017becd
f01030d5:	c1 e8 10             	shr    $0x10,%eax
f01030d8:	66 a3 ce be 17 f0    	mov    %ax,0xf017bece
	SETGATE(idt[14],0,GD_KT,page_fault,0);
f01030de:	b8 a6 35 10 f0       	mov    $0xf01035a6,%eax
f01030e3:	66 a3 d0 be 17 f0    	mov    %ax,0xf017bed0
f01030e9:	66 c7 05 d2 be 17 f0 	movw   $0x8,0xf017bed2
f01030f0:	08 00 
f01030f2:	c6 05 d4 be 17 f0 00 	movb   $0x0,0xf017bed4
f01030f9:	c6 05 d5 be 17 f0 8e 	movb   $0x8e,0xf017bed5
f0103100:	c1 e8 10             	shr    $0x10,%eax
f0103103:	66 a3 d6 be 17 f0    	mov    %ax,0xf017bed6
	SETGATE(idt[16],0,GD_KT,floating_point_error,0);
f0103109:	b8 aa 35 10 f0       	mov    $0xf01035aa,%eax
f010310e:	66 a3 e0 be 17 f0    	mov    %ax,0xf017bee0
f0103114:	66 c7 05 e2 be 17 f0 	movw   $0x8,0xf017bee2
f010311b:	08 00 
f010311d:	c6 05 e4 be 17 f0 00 	movb   $0x0,0xf017bee4
f0103124:	c6 05 e5 be 17 f0 8e 	movb   $0x8e,0xf017bee5
f010312b:	c1 e8 10             	shr    $0x10,%eax
f010312e:	66 a3 e6 be 17 f0    	mov    %ax,0xf017bee6
	SETGATE(idt[17],0,GD_KT,alignment_check,0);
f0103134:	b8 b0 35 10 f0       	mov    $0xf01035b0,%eax
f0103139:	66 a3 e8 be 17 f0    	mov    %ax,0xf017bee8
f010313f:	66 c7 05 ea be 17 f0 	movw   $0x8,0xf017beea
f0103146:	08 00 
f0103148:	c6 05 ec be 17 f0 00 	movb   $0x0,0xf017beec
f010314f:	c6 05 ed be 17 f0 8e 	movb   $0x8e,0xf017beed
f0103156:	c1 e8 10             	shr    $0x10,%eax
f0103159:	66 a3 ee be 17 f0    	mov    %ax,0xf017beee
	SETGATE(idt[18],0,GD_KT,machine_check,0);
f010315f:	b8 b4 35 10 f0       	mov    $0xf01035b4,%eax
f0103164:	66 a3 f0 be 17 f0    	mov    %ax,0xf017bef0
f010316a:	66 c7 05 f2 be 17 f0 	movw   $0x8,0xf017bef2
f0103171:	08 00 
f0103173:	c6 05 f4 be 17 f0 00 	movb   $0x0,0xf017bef4
f010317a:	c6 05 f5 be 17 f0 8e 	movb   $0x8e,0xf017bef5
f0103181:	c1 e8 10             	shr    $0x10,%eax
f0103184:	66 a3 f6 be 17 f0    	mov    %ax,0xf017bef6
	SETGATE(idt[19],0,GD_KT,simd_floating_error,0);
f010318a:	b8 ba 35 10 f0       	mov    $0xf01035ba,%eax
f010318f:	66 a3 f8 be 17 f0    	mov    %ax,0xf017bef8
f0103195:	66 c7 05 fa be 17 f0 	movw   $0x8,0xf017befa
f010319c:	08 00 
f010319e:	c6 05 fc be 17 f0 00 	movb   $0x0,0xf017befc
f01031a5:	c6 05 fd be 17 f0 8e 	movb   $0x8e,0xf017befd
f01031ac:	c1 e8 10             	shr    $0x10,%eax
f01031af:	66 a3 fe be 17 f0    	mov    %ax,0xf017befe
	SETGATE(idt[48],0,GD_KT,system_call,3);
f01031b5:	b8 c0 35 10 f0       	mov    $0xf01035c0,%eax
f01031ba:	66 a3 e0 bf 17 f0    	mov    %ax,0xf017bfe0
f01031c0:	66 c7 05 e2 bf 17 f0 	movw   $0x8,0xf017bfe2
f01031c7:	08 00 
f01031c9:	c6 05 e4 bf 17 f0 00 	movb   $0x0,0xf017bfe4
f01031d0:	c6 05 e5 bf 17 f0 ee 	movb   $0xee,0xf017bfe5
f01031d7:	c1 e8 10             	shr    $0x10,%eax
f01031da:	66 a3 e6 bf 17 f0    	mov    %ax,0xf017bfe6
	// Per-CPU setup 
	trap_init_percpu();
f01031e0:	e8 6c fc ff ff       	call   f0102e51 <trap_init_percpu>
}
f01031e5:	5d                   	pop    %ebp
f01031e6:	c3                   	ret    

f01031e7 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01031e7:	55                   	push   %ebp
f01031e8:	89 e5                	mov    %esp,%ebp
f01031ea:	53                   	push   %ebx
f01031eb:	83 ec 0c             	sub    $0xc,%esp
f01031ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01031f1:	ff 33                	pushl  (%ebx)
f01031f3:	68 fa 56 10 f0       	push   $0xf01056fa
f01031f8:	e8 40 fc ff ff       	call   f0102e3d <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01031fd:	83 c4 08             	add    $0x8,%esp
f0103200:	ff 73 04             	pushl  0x4(%ebx)
f0103203:	68 09 57 10 f0       	push   $0xf0105709
f0103208:	e8 30 fc ff ff       	call   f0102e3d <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010320d:	83 c4 08             	add    $0x8,%esp
f0103210:	ff 73 08             	pushl  0x8(%ebx)
f0103213:	68 18 57 10 f0       	push   $0xf0105718
f0103218:	e8 20 fc ff ff       	call   f0102e3d <cprintf>
	cprintf("  esp 0x%08x\n", regs->reg_oesp);
f010321d:	83 c4 08             	add    $0x8,%esp
f0103220:	ff 73 0c             	pushl  0xc(%ebx)
f0103223:	68 27 57 10 f0       	push   $0xf0105727
f0103228:	e8 10 fc ff ff       	call   f0102e3d <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010322d:	83 c4 08             	add    $0x8,%esp
f0103230:	ff 73 10             	pushl  0x10(%ebx)
f0103233:	68 35 57 10 f0       	push   $0xf0105735
f0103238:	e8 00 fc ff ff       	call   f0102e3d <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010323d:	83 c4 08             	add    $0x8,%esp
f0103240:	ff 73 14             	pushl  0x14(%ebx)
f0103243:	68 44 57 10 f0       	push   $0xf0105744
f0103248:	e8 f0 fb ff ff       	call   f0102e3d <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010324d:	83 c4 08             	add    $0x8,%esp
f0103250:	ff 73 18             	pushl  0x18(%ebx)
f0103253:	68 53 57 10 f0       	push   $0xf0105753
f0103258:	e8 e0 fb ff ff       	call   f0102e3d <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010325d:	83 c4 08             	add    $0x8,%esp
f0103260:	ff 73 1c             	pushl  0x1c(%ebx)
f0103263:	68 62 57 10 f0       	push   $0xf0105762
f0103268:	e8 d0 fb ff ff       	call   f0102e3d <cprintf>
}
f010326d:	83 c4 10             	add    $0x10,%esp
f0103270:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103273:	c9                   	leave  
f0103274:	c3                   	ret    

f0103275 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103275:	55                   	push   %ebp
f0103276:	89 e5                	mov    %esp,%ebp
f0103278:	56                   	push   %esi
f0103279:	53                   	push   %ebx
f010327a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010327d:	83 ec 08             	sub    $0x8,%esp
f0103280:	53                   	push   %ebx
f0103281:	68 98 58 10 f0       	push   $0xf0105898
f0103286:	e8 b2 fb ff ff       	call   f0102e3d <cprintf>
	print_regs(&tf->tf_regs);
f010328b:	89 1c 24             	mov    %ebx,(%esp)
f010328e:	e8 54 ff ff ff       	call   f01031e7 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103293:	83 c4 08             	add    $0x8,%esp
f0103296:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010329a:	50                   	push   %eax
f010329b:	68 b3 57 10 f0       	push   $0xf01057b3
f01032a0:	e8 98 fb ff ff       	call   f0102e3d <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032a5:	83 c4 08             	add    $0x8,%esp
f01032a8:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01032ac:	50                   	push   %eax
f01032ad:	68 c6 57 10 f0       	push   $0xf01057c6
f01032b2:	e8 86 fb ff ff       	call   f0102e3d <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032b7:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01032ba:	83 c4 10             	add    $0x10,%esp
f01032bd:	83 f8 13             	cmp    $0x13,%eax
f01032c0:	77 09                	ja     f01032cb <print_trapframe+0x56>
		return excnames[trapno];
f01032c2:	8b 14 85 60 5a 10 f0 	mov    -0xfefa5a0(,%eax,4),%edx
f01032c9:	eb 10                	jmp    f01032db <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01032cb:	83 f8 30             	cmp    $0x30,%eax
f01032ce:	b9 7d 57 10 f0       	mov    $0xf010577d,%ecx
f01032d3:	ba 71 57 10 f0       	mov    $0xf0105771,%edx
f01032d8:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032db:	83 ec 04             	sub    $0x4,%esp
f01032de:	52                   	push   %edx
f01032df:	50                   	push   %eax
f01032e0:	68 d9 57 10 f0       	push   $0xf01057d9
f01032e5:	e8 53 fb ff ff       	call   f0102e3d <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01032ea:	83 c4 10             	add    $0x10,%esp
f01032ed:	3b 1d 60 c6 17 f0    	cmp    0xf017c660,%ebx
f01032f3:	75 1a                	jne    f010330f <print_trapframe+0x9a>
f01032f5:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01032f9:	75 14                	jne    f010330f <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01032fb:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01032fe:	83 ec 08             	sub    $0x8,%esp
f0103301:	50                   	push   %eax
f0103302:	68 eb 57 10 f0       	push   $0xf01057eb
f0103307:	e8 31 fb ff ff       	call   f0102e3d <cprintf>
f010330c:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010330f:	83 ec 08             	sub    $0x8,%esp
f0103312:	ff 73 2c             	pushl  0x2c(%ebx)
f0103315:	68 fa 57 10 f0       	push   $0xf01057fa
f010331a:	e8 1e fb ff ff       	call   f0102e3d <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010331f:	83 c4 10             	add    $0x10,%esp
f0103322:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103326:	75 49                	jne    f0103371 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103328:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010332b:	89 c2                	mov    %eax,%edx
f010332d:	83 e2 01             	and    $0x1,%edx
f0103330:	ba 97 57 10 f0       	mov    $0xf0105797,%edx
f0103335:	b9 8c 57 10 f0       	mov    $0xf010578c,%ecx
f010333a:	0f 44 ca             	cmove  %edx,%ecx
f010333d:	89 c2                	mov    %eax,%edx
f010333f:	83 e2 02             	and    $0x2,%edx
f0103342:	ba a9 57 10 f0       	mov    $0xf01057a9,%edx
f0103347:	be a3 57 10 f0       	mov    $0xf01057a3,%esi
f010334c:	0f 45 d6             	cmovne %esi,%edx
f010334f:	83 e0 04             	and    $0x4,%eax
f0103352:	be c3 58 10 f0       	mov    $0xf01058c3,%esi
f0103357:	b8 ae 57 10 f0       	mov    $0xf01057ae,%eax
f010335c:	0f 44 c6             	cmove  %esi,%eax
f010335f:	51                   	push   %ecx
f0103360:	52                   	push   %edx
f0103361:	50                   	push   %eax
f0103362:	68 08 58 10 f0       	push   $0xf0105808
f0103367:	e8 d1 fa ff ff       	call   f0102e3d <cprintf>
f010336c:	83 c4 10             	add    $0x10,%esp
f010336f:	eb 10                	jmp    f0103381 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103371:	83 ec 0c             	sub    $0xc,%esp
f0103374:	68 d6 55 10 f0       	push   $0xf01055d6
f0103379:	e8 bf fa ff ff       	call   f0102e3d <cprintf>
f010337e:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103381:	83 ec 08             	sub    $0x8,%esp
f0103384:	ff 73 30             	pushl  0x30(%ebx)
f0103387:	68 17 58 10 f0       	push   $0xf0105817
f010338c:	e8 ac fa ff ff       	call   f0102e3d <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103391:	83 c4 08             	add    $0x8,%esp
f0103394:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103398:	50                   	push   %eax
f0103399:	68 26 58 10 f0       	push   $0xf0105826
f010339e:	e8 9a fa ff ff       	call   f0102e3d <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01033a3:	83 c4 08             	add    $0x8,%esp
f01033a6:	ff 73 38             	pushl  0x38(%ebx)
f01033a9:	68 39 58 10 f0       	push   $0xf0105839
f01033ae:	e8 8a fa ff ff       	call   f0102e3d <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01033b3:	83 c4 10             	add    $0x10,%esp
f01033b6:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01033ba:	74 25                	je     f01033e1 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01033bc:	83 ec 08             	sub    $0x8,%esp
f01033bf:	ff 73 3c             	pushl  0x3c(%ebx)
f01033c2:	68 48 58 10 f0       	push   $0xf0105848
f01033c7:	e8 71 fa ff ff       	call   f0102e3d <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01033cc:	83 c4 08             	add    $0x8,%esp
f01033cf:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01033d3:	50                   	push   %eax
f01033d4:	68 57 58 10 f0       	push   $0xf0105857
f01033d9:	e8 5f fa ff ff       	call   f0102e3d <cprintf>
f01033de:	83 c4 10             	add    $0x10,%esp
	}
}
f01033e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01033e4:	5b                   	pop    %ebx
f01033e5:	5e                   	pop    %esi
f01033e6:	5d                   	pop    %ebp
f01033e7:	c3                   	ret    

f01033e8 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01033e8:	55                   	push   %ebp
f01033e9:	89 e5                	mov    %esp,%ebp
f01033eb:	53                   	push   %ebx
f01033ec:	83 ec 04             	sub    $0x4,%esp
f01033ef:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01033f2:	0f 20 d0             	mov    %cr2,%eax
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01033f5:	ff 73 30             	pushl  0x30(%ebx)
f01033f8:	50                   	push   %eax
f01033f9:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f01033fe:	ff 70 48             	pushl  0x48(%eax)
f0103401:	68 10 5a 10 f0       	push   $0xf0105a10
f0103406:	e8 32 fa ff ff       	call   f0102e3d <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010340b:	89 1c 24             	mov    %ebx,(%esp)
f010340e:	e8 62 fe ff ff       	call   f0103275 <print_trapframe>
	env_destroy(curenv);
f0103413:	83 c4 04             	add    $0x4,%esp
f0103416:	ff 35 44 be 17 f0    	pushl  0xf017be44
f010341c:	e8 03 f9 ff ff       	call   f0102d24 <env_destroy>
}
f0103421:	83 c4 10             	add    $0x10,%esp
f0103424:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103427:	c9                   	leave  
f0103428:	c3                   	ret    

f0103429 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103429:	55                   	push   %ebp
f010342a:	89 e5                	mov    %esp,%ebp
f010342c:	57                   	push   %edi
f010342d:	56                   	push   %esi
f010342e:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103431:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103432:	9c                   	pushf  
f0103433:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103434:	f6 c4 02             	test   $0x2,%ah
f0103437:	74 19                	je     f0103452 <trap+0x29>
f0103439:	68 6a 58 10 f0       	push   $0xf010586a
f010343e:	68 4b 53 10 f0       	push   $0xf010534b
f0103443:	68 dc 00 00 00       	push   $0xdc
f0103448:	68 83 58 10 f0       	push   $0xf0105883
f010344d:	e8 4e cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103452:	83 ec 08             	sub    $0x8,%esp
f0103455:	56                   	push   %esi
f0103456:	68 8f 58 10 f0       	push   $0xf010588f
f010345b:	e8 dd f9 ff ff       	call   f0102e3d <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103460:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103464:	83 e0 03             	and    $0x3,%eax
f0103467:	83 c4 10             	add    $0x10,%esp
f010346a:	66 83 f8 03          	cmp    $0x3,%ax
f010346e:	75 31                	jne    f01034a1 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103470:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103475:	85 c0                	test   %eax,%eax
f0103477:	75 19                	jne    f0103492 <trap+0x69>
f0103479:	68 aa 58 10 f0       	push   $0xf01058aa
f010347e:	68 4b 53 10 f0       	push   $0xf010534b
f0103483:	68 e2 00 00 00       	push   $0xe2
f0103488:	68 83 58 10 f0       	push   $0xf0105883
f010348d:	e8 0e cc ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103492:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103497:	89 c7                	mov    %eax,%edi
f0103499:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010349b:	8b 35 44 be 17 f0    	mov    0xf017be44,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01034a1:	89 35 60 c6 17 f0    	mov    %esi,0xf017c660
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01034a7:	83 ec 0c             	sub    $0xc,%esp
f01034aa:	56                   	push   %esi
f01034ab:	e8 c5 fd ff ff       	call   f0103275 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01034b0:	83 c4 10             	add    $0x10,%esp
f01034b3:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01034b8:	75 17                	jne    f01034d1 <trap+0xa8>
		panic("unhandled trap in kernel");
f01034ba:	83 ec 04             	sub    $0x4,%esp
f01034bd:	68 b1 58 10 f0       	push   $0xf01058b1
f01034c2:	68 bb 00 00 00       	push   $0xbb
f01034c7:	68 83 58 10 f0       	push   $0xf0105883
f01034cc:	e8 cf cb ff ff       	call   f01000a0 <_panic>
	else {
		if(tf->tf_trapno ==T_PGFLT)
f01034d1:	8b 46 28             	mov    0x28(%esi),%eax
f01034d4:	83 f8 0e             	cmp    $0xe,%eax
f01034d7:	75 0e                	jne    f01034e7 <trap+0xbe>
		{
			page_fault_handler(tf);
f01034d9:	83 ec 0c             	sub    $0xc,%esp
f01034dc:	56                   	push   %esi
f01034dd:	e8 06 ff ff ff       	call   f01033e8 <page_fault_handler>
f01034e2:	83 c4 10             	add    $0x10,%esp
f01034e5:	eb 4a                	jmp    f0103531 <trap+0x108>
		}
		else if(tf->tf_trapno==T_BRKPT)
f01034e7:	83 f8 03             	cmp    $0x3,%eax
f01034ea:	75 0e                	jne    f01034fa <trap+0xd1>
		{
			monitor(tf);
f01034ec:	83 ec 0c             	sub    $0xc,%esp
f01034ef:	56                   	push   %esi
f01034f0:	e8 3d d2 ff ff       	call   f0100732 <monitor>
f01034f5:	83 c4 10             	add    $0x10,%esp
f01034f8:	eb 37                	jmp    f0103531 <trap+0x108>
		}
		else if(tf->tf_trapno==T_SYSCALL)
f01034fa:	83 f8 30             	cmp    $0x30,%eax
f01034fd:	75 21                	jne    f0103520 <trap+0xf7>
		{
			tf->tf_regs.reg_eax=syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f01034ff:	83 ec 08             	sub    $0x8,%esp
f0103502:	ff 76 04             	pushl  0x4(%esi)
f0103505:	ff 36                	pushl  (%esi)
f0103507:	ff 76 10             	pushl  0x10(%esi)
f010350a:	ff 76 18             	pushl  0x18(%esi)
f010350d:	ff 76 14             	pushl  0x14(%esi)
f0103510:	ff 76 1c             	pushl  0x1c(%esi)
f0103513:	e8 c0 00 00 00       	call   f01035d8 <syscall>
f0103518:	89 46 1c             	mov    %eax,0x1c(%esi)
f010351b:	83 c4 20             	add    $0x20,%esp
f010351e:	eb 11                	jmp    f0103531 <trap+0x108>
		}
		else
		{
		
			env_destroy(curenv);
f0103520:	83 ec 0c             	sub    $0xc,%esp
f0103523:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0103529:	e8 f6 f7 ff ff       	call   f0102d24 <env_destroy>
f010352e:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103531:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103536:	85 c0                	test   %eax,%eax
f0103538:	74 06                	je     f0103540 <trap+0x117>
f010353a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010353e:	74 19                	je     f0103559 <trap+0x130>
f0103540:	68 34 5a 10 f0       	push   $0xf0105a34
f0103545:	68 4b 53 10 f0       	push   $0xf010534b
f010354a:	68 f4 00 00 00       	push   $0xf4
f010354f:	68 83 58 10 f0       	push   $0xf0105883
f0103554:	e8 47 cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103559:	83 ec 0c             	sub    $0xc,%esp
f010355c:	50                   	push   %eax
f010355d:	e8 12 f8 ff ff       	call   f0102d74 <env_run>

f0103562 <divide_error>:
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text
TRAPHANDLER_NOEC(divide_error,T_DIVIDE)
f0103562:	6a 00                	push   $0x0
f0103564:	6a 00                	push   $0x0
f0103566:	eb 5e                	jmp    f01035c6 <_alltraps>

f0103568 <debuf_exception>:
TRAPHANDLER_NOEC(debuf_exception,T_DEBUG)
f0103568:	6a 00                	push   $0x0
f010356a:	6a 01                	push   $0x1
f010356c:	eb 58                	jmp    f01035c6 <_alltraps>

f010356e <nmi_interrupt>:
TRAPHANDLER_NOEC(nmi_interrupt,T_NMI)
f010356e:	6a 00                	push   $0x0
f0103570:	6a 02                	push   $0x2
f0103572:	eb 52                	jmp    f01035c6 <_alltraps>

f0103574 <break_point>:
TRAPHANDLER_NOEC(break_point,T_BRKPT)
f0103574:	6a 00                	push   $0x0
f0103576:	6a 03                	push   $0x3
f0103578:	eb 4c                	jmp    f01035c6 <_alltraps>

f010357a <overflow>:
TRAPHANDLER_NOEC(overflow,T_OFLOW)
f010357a:	6a 00                	push   $0x0
f010357c:	6a 04                	push   $0x4
f010357e:	eb 46                	jmp    f01035c6 <_alltraps>

f0103580 <bound_check>:
TRAPHANDLER_NOEC(bound_check,T_BOUND);
f0103580:	6a 00                	push   $0x0
f0103582:	6a 05                	push   $0x5
f0103584:	eb 40                	jmp    f01035c6 <_alltraps>

f0103586 <illegal_opcode>:
TRAPHANDLER_NOEC(illegal_opcode,T_ILLOP)
f0103586:	6a 00                	push   $0x0
f0103588:	6a 06                	push   $0x6
f010358a:	eb 3a                	jmp    f01035c6 <_alltraps>

f010358c <device_not_available>:
TRAPHANDLER_NOEC(device_not_available,T_DEVICE)
f010358c:	6a 00                	push   $0x0
f010358e:	6a 07                	push   $0x7
f0103590:	eb 34                	jmp    f01035c6 <_alltraps>

f0103592 <double_fault>:
TRAPHANDLER(double_fault,T_DBLFLT)
f0103592:	6a 08                	push   $0x8
f0103594:	eb 30                	jmp    f01035c6 <_alltraps>

f0103596 <invalid_tss>:
TRAPHANDLER(invalid_tss,T_TSS)
f0103596:	6a 0a                	push   $0xa
f0103598:	eb 2c                	jmp    f01035c6 <_alltraps>

f010359a <segment_not_present>:
TRAPHANDLER(segment_not_present,T_SEGNP)
f010359a:	6a 0b                	push   $0xb
f010359c:	eb 28                	jmp    f01035c6 <_alltraps>

f010359e <stack_exception>:
TRAPHANDLER(stack_exception,T_STACK)
f010359e:	6a 0c                	push   $0xc
f01035a0:	eb 24                	jmp    f01035c6 <_alltraps>

f01035a2 <general_protection_fault>:
TRAPHANDLER(general_protection_fault,T_GPFLT)
f01035a2:	6a 0d                	push   $0xd
f01035a4:	eb 20                	jmp    f01035c6 <_alltraps>

f01035a6 <page_fault>:
TRAPHANDLER(page_fault,T_PGFLT)
f01035a6:	6a 0e                	push   $0xe
f01035a8:	eb 1c                	jmp    f01035c6 <_alltraps>

f01035aa <floating_point_error>:
TRAPHANDLER_NOEC(floating_point_error,T_FPERR)
f01035aa:	6a 00                	push   $0x0
f01035ac:	6a 10                	push   $0x10
f01035ae:	eb 16                	jmp    f01035c6 <_alltraps>

f01035b0 <alignment_check>:
TRAPHANDLER(alignment_check,T_ALIGN)
f01035b0:	6a 11                	push   $0x11
f01035b2:	eb 12                	jmp    f01035c6 <_alltraps>

f01035b4 <machine_check>:
TRAPHANDLER_NOEC(machine_check,T_MCHK)
f01035b4:	6a 00                	push   $0x0
f01035b6:	6a 12                	push   $0x12
f01035b8:	eb 0c                	jmp    f01035c6 <_alltraps>

f01035ba <simd_floating_error>:
TRAPHANDLER_NOEC(simd_floating_error,T_SIMDERR)
f01035ba:	6a 00                	push   $0x0
f01035bc:	6a 13                	push   $0x13
f01035be:	eb 06                	jmp    f01035c6 <_alltraps>

f01035c0 <system_call>:
TRAPHANDLER_NOEC(system_call,T_SYSCALL)
f01035c0:	6a 00                	push   $0x0
f01035c2:	6a 30                	push   $0x30
f01035c4:	eb 00                	jmp    f01035c6 <_alltraps>

f01035c6 <_alltraps>:
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
_alltraps:
pushl %ds
f01035c6:	1e                   	push   %ds
pushl %es
f01035c7:	06                   	push   %es
pushal
f01035c8:	60                   	pusha  
movl $GD_KD,%eax
f01035c9:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax,%ds
f01035ce:	8e d8                	mov    %eax,%ds
movw %ax,%es
f01035d0:	8e c0                	mov    %eax,%es
pushl %esp
f01035d2:	54                   	push   %esp
call trap
f01035d3:	e8 51 fe ff ff       	call   f0103429 <trap>

f01035d8 <syscall>:
	return 0;
}
// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01035d8:	55                   	push   %ebp
f01035d9:	89 e5                	mov    %esp,%ebp
f01035db:	83 ec 18             	sub    $0x18,%esp
f01035de:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno)
f01035e1:	83 f8 01             	cmp    $0x1,%eax
f01035e4:	74 44                	je     f010362a <syscall+0x52>
f01035e6:	83 f8 01             	cmp    $0x1,%eax
f01035e9:	72 0f                	jb     f01035fa <syscall+0x22>
f01035eb:	83 f8 02             	cmp    $0x2,%eax
f01035ee:	74 41                	je     f0103631 <syscall+0x59>
f01035f0:	83 f8 03             	cmp    $0x3,%eax
f01035f3:	74 46                	je     f010363b <syscall+0x63>
f01035f5:	e9 a6 00 00 00       	jmp    f01036a0 <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv,s,len,PTE_U);
f01035fa:	6a 04                	push   $0x4
f01035fc:	ff 75 10             	pushl  0x10(%ebp)
f01035ff:	ff 75 0c             	pushl  0xc(%ebp)
f0103602:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0103608:	e8 1a f1 ff ff       	call   f0102727 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010360d:	83 c4 0c             	add    $0xc,%esp
f0103610:	ff 75 0c             	pushl  0xc(%ebp)
f0103613:	ff 75 10             	pushl  0x10(%ebp)
f0103616:	68 b0 5a 10 f0       	push   $0xf0105ab0
f010361b:	e8 1d f8 ff ff       	call   f0102e3d <cprintf>
f0103620:	83 c4 10             	add    $0x10,%esp
		case 3:
			return sys_env_destroy(a1);			
		default:
			return -E_INVAL;
	}
	return 0;
f0103623:	b8 00 00 00 00       	mov    $0x0,%eax
f0103628:	eb 7b                	jmp    f01036a5 <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010362a:	e8 94 ce ff ff       	call   f01004c3 <cons_getc>
	 {
		case 0:
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
f010362f:	eb 74                	jmp    f01036a5 <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103631:	a1 44 be 17 f0       	mov    0xf017be44,%eax
f0103636:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char*)a1,a2);
			break;
		case 1:
			return sys_cgetc();
		case 2:
			return sys_getenvid();	
f0103639:	eb 6a                	jmp    f01036a5 <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010363b:	83 ec 04             	sub    $0x4,%esp
f010363e:	6a 01                	push   $0x1
f0103640:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103643:	50                   	push   %eax
f0103644:	ff 75 0c             	pushl  0xc(%ebp)
f0103647:	e8 b0 f1 ff ff       	call   f01027fc <envid2env>
f010364c:	83 c4 10             	add    $0x10,%esp
f010364f:	85 c0                	test   %eax,%eax
f0103651:	78 52                	js     f01036a5 <syscall+0xcd>
		return r;
	if (e == curenv)
f0103653:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103656:	8b 15 44 be 17 f0    	mov    0xf017be44,%edx
f010365c:	39 d0                	cmp    %edx,%eax
f010365e:	75 15                	jne    f0103675 <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103660:	83 ec 08             	sub    $0x8,%esp
f0103663:	ff 70 48             	pushl  0x48(%eax)
f0103666:	68 b5 5a 10 f0       	push   $0xf0105ab5
f010366b:	e8 cd f7 ff ff       	call   f0102e3d <cprintf>
f0103670:	83 c4 10             	add    $0x10,%esp
f0103673:	eb 16                	jmp    f010368b <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103675:	83 ec 04             	sub    $0x4,%esp
f0103678:	ff 70 48             	pushl  0x48(%eax)
f010367b:	ff 72 48             	pushl  0x48(%edx)
f010367e:	68 d0 5a 10 f0       	push   $0xf0105ad0
f0103683:	e8 b5 f7 ff ff       	call   f0102e3d <cprintf>
f0103688:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010368b:	83 ec 0c             	sub    $0xc,%esp
f010368e:	ff 75 f4             	pushl  -0xc(%ebp)
f0103691:	e8 8e f6 ff ff       	call   f0102d24 <env_destroy>
f0103696:	83 c4 10             	add    $0x10,%esp
	return 0;
f0103699:	b8 00 00 00 00       	mov    $0x0,%eax
f010369e:	eb 05                	jmp    f01036a5 <syscall+0xcd>
		case 2:
			return sys_getenvid();	
		case 3:
			return sys_env_destroy(a1);			
		default:
			return -E_INVAL;
f01036a0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return 0;
}
f01036a5:	c9                   	leave  
f01036a6:	c3                   	ret    

f01036a7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01036a7:	55                   	push   %ebp
f01036a8:	89 e5                	mov    %esp,%ebp
f01036aa:	57                   	push   %edi
f01036ab:	56                   	push   %esi
f01036ac:	53                   	push   %ebx
f01036ad:	83 ec 14             	sub    $0x14,%esp
f01036b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01036b3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01036b6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01036b9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01036bc:	8b 1a                	mov    (%edx),%ebx
f01036be:	8b 01                	mov    (%ecx),%eax
f01036c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01036c3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01036ca:	eb 7f                	jmp    f010374b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01036cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01036cf:	01 d8                	add    %ebx,%eax
f01036d1:	89 c6                	mov    %eax,%esi
f01036d3:	c1 ee 1f             	shr    $0x1f,%esi
f01036d6:	01 c6                	add    %eax,%esi
f01036d8:	d1 fe                	sar    %esi
f01036da:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01036dd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01036e0:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01036e3:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036e5:	eb 03                	jmp    f01036ea <stab_binsearch+0x43>
			m--;
f01036e7:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036ea:	39 c3                	cmp    %eax,%ebx
f01036ec:	7f 0d                	jg     f01036fb <stab_binsearch+0x54>
f01036ee:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01036f2:	83 ea 0c             	sub    $0xc,%edx
f01036f5:	39 f9                	cmp    %edi,%ecx
f01036f7:	75 ee                	jne    f01036e7 <stab_binsearch+0x40>
f01036f9:	eb 05                	jmp    f0103700 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01036fb:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01036fe:	eb 4b                	jmp    f010374b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103700:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103703:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103706:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010370a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010370d:	76 11                	jbe    f0103720 <stab_binsearch+0x79>
			*region_left = m;
f010370f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103712:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103714:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103717:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010371e:	eb 2b                	jmp    f010374b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103720:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103723:	73 14                	jae    f0103739 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103725:	83 e8 01             	sub    $0x1,%eax
f0103728:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010372b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010372e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103730:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103737:	eb 12                	jmp    f010374b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103739:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010373c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010373e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103742:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103744:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010374b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010374e:	0f 8e 78 ff ff ff    	jle    f01036cc <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103754:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103758:	75 0f                	jne    f0103769 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010375a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010375d:	8b 00                	mov    (%eax),%eax
f010375f:	83 e8 01             	sub    $0x1,%eax
f0103762:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103765:	89 06                	mov    %eax,(%esi)
f0103767:	eb 2c                	jmp    f0103795 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103769:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010376c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010376e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103771:	8b 0e                	mov    (%esi),%ecx
f0103773:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103776:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103779:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010377c:	eb 03                	jmp    f0103781 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010377e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103781:	39 c8                	cmp    %ecx,%eax
f0103783:	7e 0b                	jle    f0103790 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103785:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103789:	83 ea 0c             	sub    $0xc,%edx
f010378c:	39 df                	cmp    %ebx,%edi
f010378e:	75 ee                	jne    f010377e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103790:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103793:	89 06                	mov    %eax,(%esi)
	}
}
f0103795:	83 c4 14             	add    $0x14,%esp
f0103798:	5b                   	pop    %ebx
f0103799:	5e                   	pop    %esi
f010379a:	5f                   	pop    %edi
f010379b:	5d                   	pop    %ebp
f010379c:	c3                   	ret    

f010379d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010379d:	55                   	push   %ebp
f010379e:	89 e5                	mov    %esp,%ebp
f01037a0:	57                   	push   %edi
f01037a1:	56                   	push   %esi
f01037a2:	53                   	push   %ebx
f01037a3:	83 ec 2c             	sub    $0x2c,%esp
f01037a6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037a9:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01037ac:	c7 06 e8 5a 10 f0    	movl   $0xf0105ae8,(%esi)
	info->eip_line = 0;
f01037b2:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01037b9:	c7 46 08 e8 5a 10 f0 	movl   $0xf0105ae8,0x8(%esi)
	info->eip_fn_namelen = 9;
f01037c0:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01037c7:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01037ca:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01037d1:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01037d7:	0f 87 8a 00 00 00    	ja     f0103867 <debuginfo_eip+0xca>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
f01037dd:	6a 00                	push   $0x0
f01037df:	6a 10                	push   $0x10
f01037e1:	68 00 00 20 00       	push   $0x200000
f01037e6:	ff 35 44 be 17 f0    	pushl  0xf017be44
f01037ec:	e8 b6 ee ff ff       	call   f01026a7 <user_mem_check>
f01037f1:	83 c4 10             	add    $0x10,%esp
f01037f4:	85 c0                	test   %eax,%eax
f01037f6:	0f 88 c3 01 00 00    	js     f01039bf <debuginfo_eip+0x222>
			return -1;
		stabs = usd->stabs;
f01037fc:	a1 00 00 20 00       	mov    0x200000,%eax
f0103801:	89 c1                	mov    %eax,%ecx
f0103803:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103806:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010380c:	a1 08 00 20 00       	mov    0x200008,%eax
f0103811:	89 45 cc             	mov    %eax,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103814:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010381a:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
f010381d:	6a 00                	push   $0x0
f010381f:	89 d8                	mov    %ebx,%eax
f0103821:	29 c8                	sub    %ecx,%eax
f0103823:	c1 f8 02             	sar    $0x2,%eax
f0103826:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010382c:	50                   	push   %eax
f010382d:	51                   	push   %ecx
f010382e:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0103834:	e8 6e ee ff ff       	call   f01026a7 <user_mem_check>
f0103839:	83 c4 10             	add    $0x10,%esp
f010383c:	85 c0                	test   %eax,%eax
f010383e:	0f 88 82 01 00 00    	js     f01039c6 <debuginfo_eip+0x229>
f0103844:	6a 00                	push   $0x0
f0103846:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103849:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010384c:	29 ca                	sub    %ecx,%edx
f010384e:	52                   	push   %edx
f010384f:	51                   	push   %ecx
f0103850:	ff 35 44 be 17 f0    	pushl  0xf017be44
f0103856:	e8 4c ee ff ff       	call   f01026a7 <user_mem_check>
f010385b:	83 c4 10             	add    $0x10,%esp
f010385e:	85 c0                	test   %eax,%eax
f0103860:	79 1f                	jns    f0103881 <debuginfo_eip+0xe4>
f0103862:	e9 66 01 00 00       	jmp    f01039cd <debuginfo_eip+0x230>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103867:	c7 45 d0 6a fe 10 f0 	movl   $0xf010fe6a,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010386e:	c7 45 cc 65 d4 10 f0 	movl   $0xf010d465,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103875:	bb 64 d4 10 f0       	mov    $0xf010d464,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010387a:	c7 45 d4 00 5d 10 f0 	movl   $0xf0105d00,-0x2c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103881:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103884:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0103887:	0f 83 47 01 00 00    	jae    f01039d4 <debuginfo_eip+0x237>
f010388d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103891:	0f 85 44 01 00 00    	jne    f01039db <debuginfo_eip+0x23e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103897:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010389e:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01038a1:	c1 fb 02             	sar    $0x2,%ebx
f01038a4:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01038aa:	83 e8 01             	sub    $0x1,%eax
f01038ad:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01038b0:	83 ec 08             	sub    $0x8,%esp
f01038b3:	57                   	push   %edi
f01038b4:	6a 64                	push   $0x64
f01038b6:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01038b9:	89 d1                	mov    %edx,%ecx
f01038bb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01038be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01038c1:	89 d8                	mov    %ebx,%eax
f01038c3:	e8 df fd ff ff       	call   f01036a7 <stab_binsearch>
	if (lfile == 0)
f01038c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038cb:	83 c4 10             	add    $0x10,%esp
f01038ce:	85 c0                	test   %eax,%eax
f01038d0:	0f 84 0c 01 00 00    	je     f01039e2 <debuginfo_eip+0x245>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01038d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01038d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01038dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01038df:	83 ec 08             	sub    $0x8,%esp
f01038e2:	57                   	push   %edi
f01038e3:	6a 24                	push   $0x24
f01038e5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01038e8:	89 d1                	mov    %edx,%ecx
f01038ea:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01038ed:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01038f0:	89 d8                	mov    %ebx,%eax
f01038f2:	e8 b0 fd ff ff       	call   f01036a7 <stab_binsearch>

	if (lfun <= rfun) {
f01038f7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01038fa:	83 c4 10             	add    $0x10,%esp
f01038fd:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103900:	7f 24                	jg     f0103926 <debuginfo_eip+0x189>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103902:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103905:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103908:	8d 14 87             	lea    (%edi,%eax,4),%edx
f010390b:	8b 02                	mov    (%edx),%eax
f010390d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103910:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103913:	29 f9                	sub    %edi,%ecx
f0103915:	39 c8                	cmp    %ecx,%eax
f0103917:	73 05                	jae    f010391e <debuginfo_eip+0x181>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103919:	01 f8                	add    %edi,%eax
f010391b:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010391e:	8b 42 08             	mov    0x8(%edx),%eax
f0103921:	89 46 10             	mov    %eax,0x10(%esi)
f0103924:	eb 06                	jmp    f010392c <debuginfo_eip+0x18f>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103926:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103929:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010392c:	83 ec 08             	sub    $0x8,%esp
f010392f:	6a 3a                	push   $0x3a
f0103931:	ff 76 08             	pushl  0x8(%esi)
f0103934:	e8 af 08 00 00       	call   f01041e8 <strfind>
f0103939:	2b 46 08             	sub    0x8(%esi),%eax
f010393c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010393f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103942:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103945:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103948:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010394b:	83 c4 10             	add    $0x10,%esp
f010394e:	eb 06                	jmp    f0103956 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103950:	83 eb 01             	sub    $0x1,%ebx
f0103953:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103956:	39 fb                	cmp    %edi,%ebx
f0103958:	7c 2d                	jl     f0103987 <debuginfo_eip+0x1ea>
	       && stabs[lline].n_type != N_SOL
f010395a:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010395e:	80 fa 84             	cmp    $0x84,%dl
f0103961:	74 0b                	je     f010396e <debuginfo_eip+0x1d1>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103963:	80 fa 64             	cmp    $0x64,%dl
f0103966:	75 e8                	jne    f0103950 <debuginfo_eip+0x1b3>
f0103968:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010396c:	74 e2                	je     f0103950 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010396e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103971:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103974:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103977:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010397a:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010397d:	29 f8                	sub    %edi,%eax
f010397f:	39 c2                	cmp    %eax,%edx
f0103981:	73 04                	jae    f0103987 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103983:	01 fa                	add    %edi,%edx
f0103985:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103987:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010398a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010398d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103992:	39 cb                	cmp    %ecx,%ebx
f0103994:	7d 58                	jge    f01039ee <debuginfo_eip+0x251>
		for (lline = lfun + 1;
f0103996:	8d 53 01             	lea    0x1(%ebx),%edx
f0103999:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010399c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010399f:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01039a2:	eb 07                	jmp    f01039ab <debuginfo_eip+0x20e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01039a4:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01039a8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01039ab:	39 ca                	cmp    %ecx,%edx
f01039ad:	74 3a                	je     f01039e9 <debuginfo_eip+0x24c>
f01039af:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01039b2:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01039b6:	74 ec                	je     f01039a4 <debuginfo_eip+0x207>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01039bd:	eb 2f                	jmp    f01039ee <debuginfo_eip+0x251>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *) USTABDATA,sizeof(struct UserStabData),0)<0)
			return -1;
f01039bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039c4:	eb 28                	jmp    f01039ee <debuginfo_eip+0x251>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv,(void *)stabs,stab_end-stabs,0)<0||user_mem_check(curenv,(void *)stabstr,stabstr_end-stabstr,0)<0)
		{
			return -1;
f01039c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039cb:	eb 21                	jmp    f01039ee <debuginfo_eip+0x251>
f01039cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039d2:	eb 1a                	jmp    f01039ee <debuginfo_eip+0x251>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01039d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039d9:	eb 13                	jmp    f01039ee <debuginfo_eip+0x251>
f01039db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039e0:	eb 0c                	jmp    f01039ee <debuginfo_eip+0x251>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01039e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039e7:	eb 05                	jmp    f01039ee <debuginfo_eip+0x251>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039f1:	5b                   	pop    %ebx
f01039f2:	5e                   	pop    %esi
f01039f3:	5f                   	pop    %edi
f01039f4:	5d                   	pop    %ebp
f01039f5:	c3                   	ret    

f01039f6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01039f6:	55                   	push   %ebp
f01039f7:	89 e5                	mov    %esp,%ebp
f01039f9:	57                   	push   %edi
f01039fa:	56                   	push   %esi
f01039fb:	53                   	push   %ebx
f01039fc:	83 ec 1c             	sub    $0x1c,%esp
f01039ff:	89 c7                	mov    %eax,%edi
f0103a01:	89 d6                	mov    %edx,%esi
f0103a03:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a06:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a09:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a0c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103a0f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103a12:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a17:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103a1a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103a1d:	39 d3                	cmp    %edx,%ebx
f0103a1f:	72 05                	jb     f0103a26 <printnum+0x30>
f0103a21:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103a24:	77 45                	ja     f0103a6b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103a26:	83 ec 0c             	sub    $0xc,%esp
f0103a29:	ff 75 18             	pushl  0x18(%ebp)
f0103a2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a2f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103a32:	53                   	push   %ebx
f0103a33:	ff 75 10             	pushl  0x10(%ebp)
f0103a36:	83 ec 08             	sub    $0x8,%esp
f0103a39:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a3c:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a3f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a42:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a45:	e8 c6 09 00 00       	call   f0104410 <__udivdi3>
f0103a4a:	83 c4 18             	add    $0x18,%esp
f0103a4d:	52                   	push   %edx
f0103a4e:	50                   	push   %eax
f0103a4f:	89 f2                	mov    %esi,%edx
f0103a51:	89 f8                	mov    %edi,%eax
f0103a53:	e8 9e ff ff ff       	call   f01039f6 <printnum>
f0103a58:	83 c4 20             	add    $0x20,%esp
f0103a5b:	eb 18                	jmp    f0103a75 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a5d:	83 ec 08             	sub    $0x8,%esp
f0103a60:	56                   	push   %esi
f0103a61:	ff 75 18             	pushl  0x18(%ebp)
f0103a64:	ff d7                	call   *%edi
f0103a66:	83 c4 10             	add    $0x10,%esp
f0103a69:	eb 03                	jmp    f0103a6e <printnum+0x78>
f0103a6b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103a6e:	83 eb 01             	sub    $0x1,%ebx
f0103a71:	85 db                	test   %ebx,%ebx
f0103a73:	7f e8                	jg     f0103a5d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103a75:	83 ec 08             	sub    $0x8,%esp
f0103a78:	56                   	push   %esi
f0103a79:	83 ec 04             	sub    $0x4,%esp
f0103a7c:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a7f:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a82:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a85:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a88:	e8 b3 0a 00 00       	call   f0104540 <__umoddi3>
f0103a8d:	83 c4 14             	add    $0x14,%esp
f0103a90:	0f be 80 f2 5a 10 f0 	movsbl -0xfefa50e(%eax),%eax
f0103a97:	50                   	push   %eax
f0103a98:	ff d7                	call   *%edi
}
f0103a9a:	83 c4 10             	add    $0x10,%esp
f0103a9d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103aa0:	5b                   	pop    %ebx
f0103aa1:	5e                   	pop    %esi
f0103aa2:	5f                   	pop    %edi
f0103aa3:	5d                   	pop    %ebp
f0103aa4:	c3                   	ret    

f0103aa5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103aa5:	55                   	push   %ebp
f0103aa6:	89 e5                	mov    %esp,%ebp
f0103aa8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103aab:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103aaf:	8b 10                	mov    (%eax),%edx
f0103ab1:	3b 50 04             	cmp    0x4(%eax),%edx
f0103ab4:	73 0a                	jae    f0103ac0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103ab6:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103ab9:	89 08                	mov    %ecx,(%eax)
f0103abb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103abe:	88 02                	mov    %al,(%edx)
}
f0103ac0:	5d                   	pop    %ebp
f0103ac1:	c3                   	ret    

f0103ac2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103ac2:	55                   	push   %ebp
f0103ac3:	89 e5                	mov    %esp,%ebp
f0103ac5:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103ac8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103acb:	50                   	push   %eax
f0103acc:	ff 75 10             	pushl  0x10(%ebp)
f0103acf:	ff 75 0c             	pushl  0xc(%ebp)
f0103ad2:	ff 75 08             	pushl  0x8(%ebp)
f0103ad5:	e8 05 00 00 00       	call   f0103adf <vprintfmt>
	va_end(ap);
}
f0103ada:	83 c4 10             	add    $0x10,%esp
f0103add:	c9                   	leave  
f0103ade:	c3                   	ret    

f0103adf <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103adf:	55                   	push   %ebp
f0103ae0:	89 e5                	mov    %esp,%ebp
f0103ae2:	57                   	push   %edi
f0103ae3:	56                   	push   %esi
f0103ae4:	53                   	push   %ebx
f0103ae5:	83 ec 2c             	sub    $0x2c,%esp
f0103ae8:	8b 75 08             	mov    0x8(%ebp),%esi
f0103aeb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aee:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103af1:	eb 12                	jmp    f0103b05 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103af3:	85 c0                	test   %eax,%eax
f0103af5:	0f 84 42 04 00 00    	je     f0103f3d <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0103afb:	83 ec 08             	sub    $0x8,%esp
f0103afe:	53                   	push   %ebx
f0103aff:	50                   	push   %eax
f0103b00:	ff d6                	call   *%esi
f0103b02:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b05:	83 c7 01             	add    $0x1,%edi
f0103b08:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103b0c:	83 f8 25             	cmp    $0x25,%eax
f0103b0f:	75 e2                	jne    f0103af3 <vprintfmt+0x14>
f0103b11:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103b15:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103b1c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103b23:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103b2a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b2f:	eb 07                	jmp    f0103b38 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b31:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103b34:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b38:	8d 47 01             	lea    0x1(%edi),%eax
f0103b3b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b3e:	0f b6 07             	movzbl (%edi),%eax
f0103b41:	0f b6 d0             	movzbl %al,%edx
f0103b44:	83 e8 23             	sub    $0x23,%eax
f0103b47:	3c 55                	cmp    $0x55,%al
f0103b49:	0f 87 d3 03 00 00    	ja     f0103f22 <vprintfmt+0x443>
f0103b4f:	0f b6 c0             	movzbl %al,%eax
f0103b52:	ff 24 85 7c 5b 10 f0 	jmp    *-0xfefa484(,%eax,4)
f0103b59:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103b5c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103b60:	eb d6                	jmp    f0103b38 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b62:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b65:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b6a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103b6d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103b70:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103b74:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103b77:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0103b7a:	83 f9 09             	cmp    $0x9,%ecx
f0103b7d:	77 3f                	ja     f0103bbe <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103b7f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103b82:	eb e9                	jmp    f0103b6d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103b84:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b87:	8b 00                	mov    (%eax),%eax
f0103b89:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103b8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b8f:	8d 40 04             	lea    0x4(%eax),%eax
f0103b92:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b95:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103b98:	eb 2a                	jmp    f0103bc4 <vprintfmt+0xe5>
f0103b9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b9d:	85 c0                	test   %eax,%eax
f0103b9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ba4:	0f 49 d0             	cmovns %eax,%edx
f0103ba7:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103baa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bad:	eb 89                	jmp    f0103b38 <vprintfmt+0x59>
f0103baf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103bb2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103bb9:	e9 7a ff ff ff       	jmp    f0103b38 <vprintfmt+0x59>
f0103bbe:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103bc1:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103bc4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103bc8:	0f 89 6a ff ff ff    	jns    f0103b38 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103bce:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103bd1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103bd4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103bdb:	e9 58 ff ff ff       	jmp    f0103b38 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103be0:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103be3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103be6:	e9 4d ff ff ff       	jmp    f0103b38 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103beb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bee:	8d 78 04             	lea    0x4(%eax),%edi
f0103bf1:	83 ec 08             	sub    $0x8,%esp
f0103bf4:	53                   	push   %ebx
f0103bf5:	ff 30                	pushl  (%eax)
f0103bf7:	ff d6                	call   *%esi
			break;
f0103bf9:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103bfc:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103c02:	e9 fe fe ff ff       	jmp    f0103b05 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c07:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c0a:	8d 78 04             	lea    0x4(%eax),%edi
f0103c0d:	8b 00                	mov    (%eax),%eax
f0103c0f:	99                   	cltd   
f0103c10:	31 d0                	xor    %edx,%eax
f0103c12:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103c14:	83 f8 06             	cmp    $0x6,%eax
f0103c17:	7f 0b                	jg     f0103c24 <vprintfmt+0x145>
f0103c19:	8b 14 85 d4 5c 10 f0 	mov    -0xfefa32c(,%eax,4),%edx
f0103c20:	85 d2                	test   %edx,%edx
f0103c22:	75 1b                	jne    f0103c3f <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0103c24:	50                   	push   %eax
f0103c25:	68 0a 5b 10 f0       	push   $0xf0105b0a
f0103c2a:	53                   	push   %ebx
f0103c2b:	56                   	push   %esi
f0103c2c:	e8 91 fe ff ff       	call   f0103ac2 <printfmt>
f0103c31:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c34:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103c3a:	e9 c6 fe ff ff       	jmp    f0103b05 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103c3f:	52                   	push   %edx
f0103c40:	68 5d 53 10 f0       	push   $0xf010535d
f0103c45:	53                   	push   %ebx
f0103c46:	56                   	push   %esi
f0103c47:	e8 76 fe ff ff       	call   f0103ac2 <printfmt>
f0103c4c:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103c4f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c55:	e9 ab fe ff ff       	jmp    f0103b05 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c5d:	83 c0 04             	add    $0x4,%eax
f0103c60:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103c63:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c66:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103c68:	85 ff                	test   %edi,%edi
f0103c6a:	b8 03 5b 10 f0       	mov    $0xf0105b03,%eax
f0103c6f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103c72:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103c76:	0f 8e 94 00 00 00    	jle    f0103d10 <vprintfmt+0x231>
f0103c7c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103c80:	0f 84 98 00 00 00    	je     f0103d1e <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c86:	83 ec 08             	sub    $0x8,%esp
f0103c89:	ff 75 d0             	pushl  -0x30(%ebp)
f0103c8c:	57                   	push   %edi
f0103c8d:	e8 0c 04 00 00       	call   f010409e <strnlen>
f0103c92:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c95:	29 c1                	sub    %eax,%ecx
f0103c97:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103c9a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103c9d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103ca1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103ca4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103ca7:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ca9:	eb 0f                	jmp    f0103cba <vprintfmt+0x1db>
					putch(padc, putdat);
f0103cab:	83 ec 08             	sub    $0x8,%esp
f0103cae:	53                   	push   %ebx
f0103caf:	ff 75 e0             	pushl  -0x20(%ebp)
f0103cb2:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103cb4:	83 ef 01             	sub    $0x1,%edi
f0103cb7:	83 c4 10             	add    $0x10,%esp
f0103cba:	85 ff                	test   %edi,%edi
f0103cbc:	7f ed                	jg     f0103cab <vprintfmt+0x1cc>
f0103cbe:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103cc1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0103cc4:	85 c9                	test   %ecx,%ecx
f0103cc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ccb:	0f 49 c1             	cmovns %ecx,%eax
f0103cce:	29 c1                	sub    %eax,%ecx
f0103cd0:	89 75 08             	mov    %esi,0x8(%ebp)
f0103cd3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103cd6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103cd9:	89 cb                	mov    %ecx,%ebx
f0103cdb:	eb 4d                	jmp    f0103d2a <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103cdd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103ce1:	74 1b                	je     f0103cfe <vprintfmt+0x21f>
f0103ce3:	0f be c0             	movsbl %al,%eax
f0103ce6:	83 e8 20             	sub    $0x20,%eax
f0103ce9:	83 f8 5e             	cmp    $0x5e,%eax
f0103cec:	76 10                	jbe    f0103cfe <vprintfmt+0x21f>
					putch('?', putdat);
f0103cee:	83 ec 08             	sub    $0x8,%esp
f0103cf1:	ff 75 0c             	pushl  0xc(%ebp)
f0103cf4:	6a 3f                	push   $0x3f
f0103cf6:	ff 55 08             	call   *0x8(%ebp)
f0103cf9:	83 c4 10             	add    $0x10,%esp
f0103cfc:	eb 0d                	jmp    f0103d0b <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0103cfe:	83 ec 08             	sub    $0x8,%esp
f0103d01:	ff 75 0c             	pushl  0xc(%ebp)
f0103d04:	52                   	push   %edx
f0103d05:	ff 55 08             	call   *0x8(%ebp)
f0103d08:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103d0b:	83 eb 01             	sub    $0x1,%ebx
f0103d0e:	eb 1a                	jmp    f0103d2a <vprintfmt+0x24b>
f0103d10:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d13:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d16:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d19:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d1c:	eb 0c                	jmp    f0103d2a <vprintfmt+0x24b>
f0103d1e:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d21:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d24:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d27:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d2a:	83 c7 01             	add    $0x1,%edi
f0103d2d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d31:	0f be d0             	movsbl %al,%edx
f0103d34:	85 d2                	test   %edx,%edx
f0103d36:	74 23                	je     f0103d5b <vprintfmt+0x27c>
f0103d38:	85 f6                	test   %esi,%esi
f0103d3a:	78 a1                	js     f0103cdd <vprintfmt+0x1fe>
f0103d3c:	83 ee 01             	sub    $0x1,%esi
f0103d3f:	79 9c                	jns    f0103cdd <vprintfmt+0x1fe>
f0103d41:	89 df                	mov    %ebx,%edi
f0103d43:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d46:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d49:	eb 18                	jmp    f0103d63 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103d4b:	83 ec 08             	sub    $0x8,%esp
f0103d4e:	53                   	push   %ebx
f0103d4f:	6a 20                	push   $0x20
f0103d51:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103d53:	83 ef 01             	sub    $0x1,%edi
f0103d56:	83 c4 10             	add    $0x10,%esp
f0103d59:	eb 08                	jmp    f0103d63 <vprintfmt+0x284>
f0103d5b:	89 df                	mov    %ebx,%edi
f0103d5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d60:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d63:	85 ff                	test   %edi,%edi
f0103d65:	7f e4                	jg     f0103d4b <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103d67:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103d6a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d70:	e9 90 fd ff ff       	jmp    f0103b05 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103d75:	83 f9 01             	cmp    $0x1,%ecx
f0103d78:	7e 19                	jle    f0103d93 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0103d7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d7d:	8b 50 04             	mov    0x4(%eax),%edx
f0103d80:	8b 00                	mov    (%eax),%eax
f0103d82:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d85:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103d88:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d8b:	8d 40 08             	lea    0x8(%eax),%eax
f0103d8e:	89 45 14             	mov    %eax,0x14(%ebp)
f0103d91:	eb 38                	jmp    f0103dcb <vprintfmt+0x2ec>
	else if (lflag)
f0103d93:	85 c9                	test   %ecx,%ecx
f0103d95:	74 1b                	je     f0103db2 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0103d97:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d9a:	8b 00                	mov    (%eax),%eax
f0103d9c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d9f:	89 c1                	mov    %eax,%ecx
f0103da1:	c1 f9 1f             	sar    $0x1f,%ecx
f0103da4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103da7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103daa:	8d 40 04             	lea    0x4(%eax),%eax
f0103dad:	89 45 14             	mov    %eax,0x14(%ebp)
f0103db0:	eb 19                	jmp    f0103dcb <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0103db2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103db5:	8b 00                	mov    (%eax),%eax
f0103db7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dba:	89 c1                	mov    %eax,%ecx
f0103dbc:	c1 f9 1f             	sar    $0x1f,%ecx
f0103dbf:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103dc2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dc5:	8d 40 04             	lea    0x4(%eax),%eax
f0103dc8:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103dcb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103dce:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103dd1:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103dd6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103dda:	0f 89 0e 01 00 00    	jns    f0103eee <vprintfmt+0x40f>
				putch('-', putdat);
f0103de0:	83 ec 08             	sub    $0x8,%esp
f0103de3:	53                   	push   %ebx
f0103de4:	6a 2d                	push   $0x2d
f0103de6:	ff d6                	call   *%esi
				num = -(long long) num;
f0103de8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103deb:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103dee:	f7 da                	neg    %edx
f0103df0:	83 d1 00             	adc    $0x0,%ecx
f0103df3:	f7 d9                	neg    %ecx
f0103df5:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103df8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103dfd:	e9 ec 00 00 00       	jmp    f0103eee <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103e02:	83 f9 01             	cmp    $0x1,%ecx
f0103e05:	7e 18                	jle    f0103e1f <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0103e07:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e0a:	8b 10                	mov    (%eax),%edx
f0103e0c:	8b 48 04             	mov    0x4(%eax),%ecx
f0103e0f:	8d 40 08             	lea    0x8(%eax),%eax
f0103e12:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e15:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e1a:	e9 cf 00 00 00       	jmp    f0103eee <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103e1f:	85 c9                	test   %ecx,%ecx
f0103e21:	74 1a                	je     f0103e3d <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0103e23:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e26:	8b 10                	mov    (%eax),%edx
f0103e28:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e2d:	8d 40 04             	lea    0x4(%eax),%eax
f0103e30:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e33:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e38:	e9 b1 00 00 00       	jmp    f0103eee <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103e3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e40:	8b 10                	mov    (%eax),%edx
f0103e42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103e47:	8d 40 04             	lea    0x4(%eax),%eax
f0103e4a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103e4d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103e52:	e9 97 00 00 00       	jmp    f0103eee <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103e57:	83 ec 08             	sub    $0x8,%esp
f0103e5a:	53                   	push   %ebx
f0103e5b:	6a 58                	push   $0x58
f0103e5d:	ff d6                	call   *%esi
			putch('X', putdat);
f0103e5f:	83 c4 08             	add    $0x8,%esp
f0103e62:	53                   	push   %ebx
f0103e63:	6a 58                	push   $0x58
f0103e65:	ff d6                	call   *%esi
			putch('X', putdat);
f0103e67:	83 c4 08             	add    $0x8,%esp
f0103e6a:	53                   	push   %ebx
f0103e6b:	6a 58                	push   $0x58
f0103e6d:	ff d6                	call   *%esi
			break;
f0103e6f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e72:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103e75:	e9 8b fc ff ff       	jmp    f0103b05 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103e7a:	83 ec 08             	sub    $0x8,%esp
f0103e7d:	53                   	push   %ebx
f0103e7e:	6a 30                	push   $0x30
f0103e80:	ff d6                	call   *%esi
			putch('x', putdat);
f0103e82:	83 c4 08             	add    $0x8,%esp
f0103e85:	53                   	push   %ebx
f0103e86:	6a 78                	push   $0x78
f0103e88:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103e8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e8d:	8b 10                	mov    (%eax),%edx
f0103e8f:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103e94:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103e97:	8d 40 04             	lea    0x4(%eax),%eax
f0103e9a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103e9d:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103ea2:	eb 4a                	jmp    f0103eee <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103ea4:	83 f9 01             	cmp    $0x1,%ecx
f0103ea7:	7e 15                	jle    f0103ebe <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0103ea9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eac:	8b 10                	mov    (%eax),%edx
f0103eae:	8b 48 04             	mov    0x4(%eax),%ecx
f0103eb1:	8d 40 08             	lea    0x8(%eax),%eax
f0103eb4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103eb7:	b8 10 00 00 00       	mov    $0x10,%eax
f0103ebc:	eb 30                	jmp    f0103eee <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103ebe:	85 c9                	test   %ecx,%ecx
f0103ec0:	74 17                	je     f0103ed9 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0103ec2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ec5:	8b 10                	mov    (%eax),%edx
f0103ec7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ecc:	8d 40 04             	lea    0x4(%eax),%eax
f0103ecf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103ed2:	b8 10 00 00 00       	mov    $0x10,%eax
f0103ed7:	eb 15                	jmp    f0103eee <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103ed9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103edc:	8b 10                	mov    (%eax),%edx
f0103ede:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ee3:	8d 40 04             	lea    0x4(%eax),%eax
f0103ee6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103ee9:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103eee:	83 ec 0c             	sub    $0xc,%esp
f0103ef1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103ef5:	57                   	push   %edi
f0103ef6:	ff 75 e0             	pushl  -0x20(%ebp)
f0103ef9:	50                   	push   %eax
f0103efa:	51                   	push   %ecx
f0103efb:	52                   	push   %edx
f0103efc:	89 da                	mov    %ebx,%edx
f0103efe:	89 f0                	mov    %esi,%eax
f0103f00:	e8 f1 fa ff ff       	call   f01039f6 <printnum>
			break;
f0103f05:	83 c4 20             	add    $0x20,%esp
f0103f08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f0b:	e9 f5 fb ff ff       	jmp    f0103b05 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103f10:	83 ec 08             	sub    $0x8,%esp
f0103f13:	53                   	push   %ebx
f0103f14:	52                   	push   %edx
f0103f15:	ff d6                	call   *%esi
			break;
f0103f17:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103f1d:	e9 e3 fb ff ff       	jmp    f0103b05 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103f22:	83 ec 08             	sub    $0x8,%esp
f0103f25:	53                   	push   %ebx
f0103f26:	6a 25                	push   $0x25
f0103f28:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103f2a:	83 c4 10             	add    $0x10,%esp
f0103f2d:	eb 03                	jmp    f0103f32 <vprintfmt+0x453>
f0103f2f:	83 ef 01             	sub    $0x1,%edi
f0103f32:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103f36:	75 f7                	jne    f0103f2f <vprintfmt+0x450>
f0103f38:	e9 c8 fb ff ff       	jmp    f0103b05 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103f3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f40:	5b                   	pop    %ebx
f0103f41:	5e                   	pop    %esi
f0103f42:	5f                   	pop    %edi
f0103f43:	5d                   	pop    %ebp
f0103f44:	c3                   	ret    

f0103f45 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103f45:	55                   	push   %ebp
f0103f46:	89 e5                	mov    %esp,%ebp
f0103f48:	83 ec 18             	sub    $0x18,%esp
f0103f4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f4e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103f51:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103f54:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103f58:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103f5b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103f62:	85 c0                	test   %eax,%eax
f0103f64:	74 26                	je     f0103f8c <vsnprintf+0x47>
f0103f66:	85 d2                	test   %edx,%edx
f0103f68:	7e 22                	jle    f0103f8c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103f6a:	ff 75 14             	pushl  0x14(%ebp)
f0103f6d:	ff 75 10             	pushl  0x10(%ebp)
f0103f70:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103f73:	50                   	push   %eax
f0103f74:	68 a5 3a 10 f0       	push   $0xf0103aa5
f0103f79:	e8 61 fb ff ff       	call   f0103adf <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103f7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103f81:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103f84:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f87:	83 c4 10             	add    $0x10,%esp
f0103f8a:	eb 05                	jmp    f0103f91 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103f8c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103f91:	c9                   	leave  
f0103f92:	c3                   	ret    

f0103f93 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103f93:	55                   	push   %ebp
f0103f94:	89 e5                	mov    %esp,%ebp
f0103f96:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103f99:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103f9c:	50                   	push   %eax
f0103f9d:	ff 75 10             	pushl  0x10(%ebp)
f0103fa0:	ff 75 0c             	pushl  0xc(%ebp)
f0103fa3:	ff 75 08             	pushl  0x8(%ebp)
f0103fa6:	e8 9a ff ff ff       	call   f0103f45 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103fab:	c9                   	leave  
f0103fac:	c3                   	ret    

f0103fad <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103fad:	55                   	push   %ebp
f0103fae:	89 e5                	mov    %esp,%ebp
f0103fb0:	57                   	push   %edi
f0103fb1:	56                   	push   %esi
f0103fb2:	53                   	push   %ebx
f0103fb3:	83 ec 0c             	sub    $0xc,%esp
f0103fb6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103fb9:	85 c0                	test   %eax,%eax
f0103fbb:	74 11                	je     f0103fce <readline+0x21>
		cprintf("%s", prompt);
f0103fbd:	83 ec 08             	sub    $0x8,%esp
f0103fc0:	50                   	push   %eax
f0103fc1:	68 5d 53 10 f0       	push   $0xf010535d
f0103fc6:	e8 72 ee ff ff       	call   f0102e3d <cprintf>
f0103fcb:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103fce:	83 ec 0c             	sub    $0xc,%esp
f0103fd1:	6a 00                	push   $0x0
f0103fd3:	e8 5e c6 ff ff       	call   f0100636 <iscons>
f0103fd8:	89 c7                	mov    %eax,%edi
f0103fda:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103fdd:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103fe2:	e8 3e c6 ff ff       	call   f0100625 <getchar>
f0103fe7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103fe9:	85 c0                	test   %eax,%eax
f0103feb:	79 18                	jns    f0104005 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103fed:	83 ec 08             	sub    $0x8,%esp
f0103ff0:	50                   	push   %eax
f0103ff1:	68 f0 5c 10 f0       	push   $0xf0105cf0
f0103ff6:	e8 42 ee ff ff       	call   f0102e3d <cprintf>
			return NULL;
f0103ffb:	83 c4 10             	add    $0x10,%esp
f0103ffe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104003:	eb 79                	jmp    f010407e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104005:	83 f8 08             	cmp    $0x8,%eax
f0104008:	0f 94 c2             	sete   %dl
f010400b:	83 f8 7f             	cmp    $0x7f,%eax
f010400e:	0f 94 c0             	sete   %al
f0104011:	08 c2                	or     %al,%dl
f0104013:	74 1a                	je     f010402f <readline+0x82>
f0104015:	85 f6                	test   %esi,%esi
f0104017:	7e 16                	jle    f010402f <readline+0x82>
			if (echoing)
f0104019:	85 ff                	test   %edi,%edi
f010401b:	74 0d                	je     f010402a <readline+0x7d>
				cputchar('\b');
f010401d:	83 ec 0c             	sub    $0xc,%esp
f0104020:	6a 08                	push   $0x8
f0104022:	e8 ee c5 ff ff       	call   f0100615 <cputchar>
f0104027:	83 c4 10             	add    $0x10,%esp
			i--;
f010402a:	83 ee 01             	sub    $0x1,%esi
f010402d:	eb b3                	jmp    f0103fe2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010402f:	83 fb 1f             	cmp    $0x1f,%ebx
f0104032:	7e 23                	jle    f0104057 <readline+0xaa>
f0104034:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010403a:	7f 1b                	jg     f0104057 <readline+0xaa>
			if (echoing)
f010403c:	85 ff                	test   %edi,%edi
f010403e:	74 0c                	je     f010404c <readline+0x9f>
				cputchar(c);
f0104040:	83 ec 0c             	sub    $0xc,%esp
f0104043:	53                   	push   %ebx
f0104044:	e8 cc c5 ff ff       	call   f0100615 <cputchar>
f0104049:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010404c:	88 9e 00 c7 17 f0    	mov    %bl,-0xfe83900(%esi)
f0104052:	8d 76 01             	lea    0x1(%esi),%esi
f0104055:	eb 8b                	jmp    f0103fe2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104057:	83 fb 0a             	cmp    $0xa,%ebx
f010405a:	74 05                	je     f0104061 <readline+0xb4>
f010405c:	83 fb 0d             	cmp    $0xd,%ebx
f010405f:	75 81                	jne    f0103fe2 <readline+0x35>
			if (echoing)
f0104061:	85 ff                	test   %edi,%edi
f0104063:	74 0d                	je     f0104072 <readline+0xc5>
				cputchar('\n');
f0104065:	83 ec 0c             	sub    $0xc,%esp
f0104068:	6a 0a                	push   $0xa
f010406a:	e8 a6 c5 ff ff       	call   f0100615 <cputchar>
f010406f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104072:	c6 86 00 c7 17 f0 00 	movb   $0x0,-0xfe83900(%esi)
			return buf;
f0104079:	b8 00 c7 17 f0       	mov    $0xf017c700,%eax
		}
	}
}
f010407e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104081:	5b                   	pop    %ebx
f0104082:	5e                   	pop    %esi
f0104083:	5f                   	pop    %edi
f0104084:	5d                   	pop    %ebp
f0104085:	c3                   	ret    

f0104086 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104086:	55                   	push   %ebp
f0104087:	89 e5                	mov    %esp,%ebp
f0104089:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010408c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104091:	eb 03                	jmp    f0104096 <strlen+0x10>
		n++;
f0104093:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104096:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010409a:	75 f7                	jne    f0104093 <strlen+0xd>
		n++;
	return n;
}
f010409c:	5d                   	pop    %ebp
f010409d:	c3                   	ret    

f010409e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010409e:	55                   	push   %ebp
f010409f:	89 e5                	mov    %esp,%ebp
f01040a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040a4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01040ac:	eb 03                	jmp    f01040b1 <strnlen+0x13>
		n++;
f01040ae:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01040b1:	39 c2                	cmp    %eax,%edx
f01040b3:	74 08                	je     f01040bd <strnlen+0x1f>
f01040b5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01040b9:	75 f3                	jne    f01040ae <strnlen+0x10>
f01040bb:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01040bd:	5d                   	pop    %ebp
f01040be:	c3                   	ret    

f01040bf <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01040bf:	55                   	push   %ebp
f01040c0:	89 e5                	mov    %esp,%ebp
f01040c2:	53                   	push   %ebx
f01040c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01040c9:	89 c2                	mov    %eax,%edx
f01040cb:	83 c2 01             	add    $0x1,%edx
f01040ce:	83 c1 01             	add    $0x1,%ecx
f01040d1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01040d5:	88 5a ff             	mov    %bl,-0x1(%edx)
f01040d8:	84 db                	test   %bl,%bl
f01040da:	75 ef                	jne    f01040cb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01040dc:	5b                   	pop    %ebx
f01040dd:	5d                   	pop    %ebp
f01040de:	c3                   	ret    

f01040df <strcat>:

char *
strcat(char *dst, const char *src)
{
f01040df:	55                   	push   %ebp
f01040e0:	89 e5                	mov    %esp,%ebp
f01040e2:	53                   	push   %ebx
f01040e3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01040e6:	53                   	push   %ebx
f01040e7:	e8 9a ff ff ff       	call   f0104086 <strlen>
f01040ec:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01040ef:	ff 75 0c             	pushl  0xc(%ebp)
f01040f2:	01 d8                	add    %ebx,%eax
f01040f4:	50                   	push   %eax
f01040f5:	e8 c5 ff ff ff       	call   f01040bf <strcpy>
	return dst;
}
f01040fa:	89 d8                	mov    %ebx,%eax
f01040fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01040ff:	c9                   	leave  
f0104100:	c3                   	ret    

f0104101 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104101:	55                   	push   %ebp
f0104102:	89 e5                	mov    %esp,%ebp
f0104104:	56                   	push   %esi
f0104105:	53                   	push   %ebx
f0104106:	8b 75 08             	mov    0x8(%ebp),%esi
f0104109:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010410c:	89 f3                	mov    %esi,%ebx
f010410e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104111:	89 f2                	mov    %esi,%edx
f0104113:	eb 0f                	jmp    f0104124 <strncpy+0x23>
		*dst++ = *src;
f0104115:	83 c2 01             	add    $0x1,%edx
f0104118:	0f b6 01             	movzbl (%ecx),%eax
f010411b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010411e:	80 39 01             	cmpb   $0x1,(%ecx)
f0104121:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104124:	39 da                	cmp    %ebx,%edx
f0104126:	75 ed                	jne    f0104115 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104128:	89 f0                	mov    %esi,%eax
f010412a:	5b                   	pop    %ebx
f010412b:	5e                   	pop    %esi
f010412c:	5d                   	pop    %ebp
f010412d:	c3                   	ret    

f010412e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010412e:	55                   	push   %ebp
f010412f:	89 e5                	mov    %esp,%ebp
f0104131:	56                   	push   %esi
f0104132:	53                   	push   %ebx
f0104133:	8b 75 08             	mov    0x8(%ebp),%esi
f0104136:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104139:	8b 55 10             	mov    0x10(%ebp),%edx
f010413c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010413e:	85 d2                	test   %edx,%edx
f0104140:	74 21                	je     f0104163 <strlcpy+0x35>
f0104142:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104146:	89 f2                	mov    %esi,%edx
f0104148:	eb 09                	jmp    f0104153 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010414a:	83 c2 01             	add    $0x1,%edx
f010414d:	83 c1 01             	add    $0x1,%ecx
f0104150:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104153:	39 c2                	cmp    %eax,%edx
f0104155:	74 09                	je     f0104160 <strlcpy+0x32>
f0104157:	0f b6 19             	movzbl (%ecx),%ebx
f010415a:	84 db                	test   %bl,%bl
f010415c:	75 ec                	jne    f010414a <strlcpy+0x1c>
f010415e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104160:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104163:	29 f0                	sub    %esi,%eax
}
f0104165:	5b                   	pop    %ebx
f0104166:	5e                   	pop    %esi
f0104167:	5d                   	pop    %ebp
f0104168:	c3                   	ret    

f0104169 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104169:	55                   	push   %ebp
f010416a:	89 e5                	mov    %esp,%ebp
f010416c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010416f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104172:	eb 06                	jmp    f010417a <strcmp+0x11>
		p++, q++;
f0104174:	83 c1 01             	add    $0x1,%ecx
f0104177:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010417a:	0f b6 01             	movzbl (%ecx),%eax
f010417d:	84 c0                	test   %al,%al
f010417f:	74 04                	je     f0104185 <strcmp+0x1c>
f0104181:	3a 02                	cmp    (%edx),%al
f0104183:	74 ef                	je     f0104174 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104185:	0f b6 c0             	movzbl %al,%eax
f0104188:	0f b6 12             	movzbl (%edx),%edx
f010418b:	29 d0                	sub    %edx,%eax
}
f010418d:	5d                   	pop    %ebp
f010418e:	c3                   	ret    

f010418f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010418f:	55                   	push   %ebp
f0104190:	89 e5                	mov    %esp,%ebp
f0104192:	53                   	push   %ebx
f0104193:	8b 45 08             	mov    0x8(%ebp),%eax
f0104196:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104199:	89 c3                	mov    %eax,%ebx
f010419b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010419e:	eb 06                	jmp    f01041a6 <strncmp+0x17>
		n--, p++, q++;
f01041a0:	83 c0 01             	add    $0x1,%eax
f01041a3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01041a6:	39 d8                	cmp    %ebx,%eax
f01041a8:	74 15                	je     f01041bf <strncmp+0x30>
f01041aa:	0f b6 08             	movzbl (%eax),%ecx
f01041ad:	84 c9                	test   %cl,%cl
f01041af:	74 04                	je     f01041b5 <strncmp+0x26>
f01041b1:	3a 0a                	cmp    (%edx),%cl
f01041b3:	74 eb                	je     f01041a0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01041b5:	0f b6 00             	movzbl (%eax),%eax
f01041b8:	0f b6 12             	movzbl (%edx),%edx
f01041bb:	29 d0                	sub    %edx,%eax
f01041bd:	eb 05                	jmp    f01041c4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01041bf:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01041c4:	5b                   	pop    %ebx
f01041c5:	5d                   	pop    %ebp
f01041c6:	c3                   	ret    

f01041c7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01041c7:	55                   	push   %ebp
f01041c8:	89 e5                	mov    %esp,%ebp
f01041ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01041cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01041d1:	eb 07                	jmp    f01041da <strchr+0x13>
		if (*s == c)
f01041d3:	38 ca                	cmp    %cl,%dl
f01041d5:	74 0f                	je     f01041e6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01041d7:	83 c0 01             	add    $0x1,%eax
f01041da:	0f b6 10             	movzbl (%eax),%edx
f01041dd:	84 d2                	test   %dl,%dl
f01041df:	75 f2                	jne    f01041d3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01041e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01041e6:	5d                   	pop    %ebp
f01041e7:	c3                   	ret    

f01041e8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01041e8:	55                   	push   %ebp
f01041e9:	89 e5                	mov    %esp,%ebp
f01041eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01041ee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01041f2:	eb 03                	jmp    f01041f7 <strfind+0xf>
f01041f4:	83 c0 01             	add    $0x1,%eax
f01041f7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01041fa:	38 ca                	cmp    %cl,%dl
f01041fc:	74 04                	je     f0104202 <strfind+0x1a>
f01041fe:	84 d2                	test   %dl,%dl
f0104200:	75 f2                	jne    f01041f4 <strfind+0xc>
			break;
	return (char *) s;
}
f0104202:	5d                   	pop    %ebp
f0104203:	c3                   	ret    

f0104204 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104204:	55                   	push   %ebp
f0104205:	89 e5                	mov    %esp,%ebp
f0104207:	57                   	push   %edi
f0104208:	56                   	push   %esi
f0104209:	53                   	push   %ebx
f010420a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010420d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104210:	85 c9                	test   %ecx,%ecx
f0104212:	74 36                	je     f010424a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104214:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010421a:	75 28                	jne    f0104244 <memset+0x40>
f010421c:	f6 c1 03             	test   $0x3,%cl
f010421f:	75 23                	jne    f0104244 <memset+0x40>
		c &= 0xFF;
f0104221:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104225:	89 d3                	mov    %edx,%ebx
f0104227:	c1 e3 08             	shl    $0x8,%ebx
f010422a:	89 d6                	mov    %edx,%esi
f010422c:	c1 e6 18             	shl    $0x18,%esi
f010422f:	89 d0                	mov    %edx,%eax
f0104231:	c1 e0 10             	shl    $0x10,%eax
f0104234:	09 f0                	or     %esi,%eax
f0104236:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104238:	89 d8                	mov    %ebx,%eax
f010423a:	09 d0                	or     %edx,%eax
f010423c:	c1 e9 02             	shr    $0x2,%ecx
f010423f:	fc                   	cld    
f0104240:	f3 ab                	rep stos %eax,%es:(%edi)
f0104242:	eb 06                	jmp    f010424a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104244:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104247:	fc                   	cld    
f0104248:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010424a:	89 f8                	mov    %edi,%eax
f010424c:	5b                   	pop    %ebx
f010424d:	5e                   	pop    %esi
f010424e:	5f                   	pop    %edi
f010424f:	5d                   	pop    %ebp
f0104250:	c3                   	ret    

f0104251 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104251:	55                   	push   %ebp
f0104252:	89 e5                	mov    %esp,%ebp
f0104254:	57                   	push   %edi
f0104255:	56                   	push   %esi
f0104256:	8b 45 08             	mov    0x8(%ebp),%eax
f0104259:	8b 75 0c             	mov    0xc(%ebp),%esi
f010425c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010425f:	39 c6                	cmp    %eax,%esi
f0104261:	73 35                	jae    f0104298 <memmove+0x47>
f0104263:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104266:	39 d0                	cmp    %edx,%eax
f0104268:	73 2e                	jae    f0104298 <memmove+0x47>
		s += n;
		d += n;
f010426a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010426d:	89 d6                	mov    %edx,%esi
f010426f:	09 fe                	or     %edi,%esi
f0104271:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104277:	75 13                	jne    f010428c <memmove+0x3b>
f0104279:	f6 c1 03             	test   $0x3,%cl
f010427c:	75 0e                	jne    f010428c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010427e:	83 ef 04             	sub    $0x4,%edi
f0104281:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104284:	c1 e9 02             	shr    $0x2,%ecx
f0104287:	fd                   	std    
f0104288:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010428a:	eb 09                	jmp    f0104295 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010428c:	83 ef 01             	sub    $0x1,%edi
f010428f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104292:	fd                   	std    
f0104293:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104295:	fc                   	cld    
f0104296:	eb 1d                	jmp    f01042b5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104298:	89 f2                	mov    %esi,%edx
f010429a:	09 c2                	or     %eax,%edx
f010429c:	f6 c2 03             	test   $0x3,%dl
f010429f:	75 0f                	jne    f01042b0 <memmove+0x5f>
f01042a1:	f6 c1 03             	test   $0x3,%cl
f01042a4:	75 0a                	jne    f01042b0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01042a6:	c1 e9 02             	shr    $0x2,%ecx
f01042a9:	89 c7                	mov    %eax,%edi
f01042ab:	fc                   	cld    
f01042ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01042ae:	eb 05                	jmp    f01042b5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01042b0:	89 c7                	mov    %eax,%edi
f01042b2:	fc                   	cld    
f01042b3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01042b5:	5e                   	pop    %esi
f01042b6:	5f                   	pop    %edi
f01042b7:	5d                   	pop    %ebp
f01042b8:	c3                   	ret    

f01042b9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01042b9:	55                   	push   %ebp
f01042ba:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01042bc:	ff 75 10             	pushl  0x10(%ebp)
f01042bf:	ff 75 0c             	pushl  0xc(%ebp)
f01042c2:	ff 75 08             	pushl  0x8(%ebp)
f01042c5:	e8 87 ff ff ff       	call   f0104251 <memmove>
}
f01042ca:	c9                   	leave  
f01042cb:	c3                   	ret    

f01042cc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01042cc:	55                   	push   %ebp
f01042cd:	89 e5                	mov    %esp,%ebp
f01042cf:	56                   	push   %esi
f01042d0:	53                   	push   %ebx
f01042d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01042d4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01042d7:	89 c6                	mov    %eax,%esi
f01042d9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01042dc:	eb 1a                	jmp    f01042f8 <memcmp+0x2c>
		if (*s1 != *s2)
f01042de:	0f b6 08             	movzbl (%eax),%ecx
f01042e1:	0f b6 1a             	movzbl (%edx),%ebx
f01042e4:	38 d9                	cmp    %bl,%cl
f01042e6:	74 0a                	je     f01042f2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01042e8:	0f b6 c1             	movzbl %cl,%eax
f01042eb:	0f b6 db             	movzbl %bl,%ebx
f01042ee:	29 d8                	sub    %ebx,%eax
f01042f0:	eb 0f                	jmp    f0104301 <memcmp+0x35>
		s1++, s2++;
f01042f2:	83 c0 01             	add    $0x1,%eax
f01042f5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01042f8:	39 f0                	cmp    %esi,%eax
f01042fa:	75 e2                	jne    f01042de <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01042fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104301:	5b                   	pop    %ebx
f0104302:	5e                   	pop    %esi
f0104303:	5d                   	pop    %ebp
f0104304:	c3                   	ret    

f0104305 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104305:	55                   	push   %ebp
f0104306:	89 e5                	mov    %esp,%ebp
f0104308:	53                   	push   %ebx
f0104309:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010430c:	89 c1                	mov    %eax,%ecx
f010430e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104311:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104315:	eb 0a                	jmp    f0104321 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104317:	0f b6 10             	movzbl (%eax),%edx
f010431a:	39 da                	cmp    %ebx,%edx
f010431c:	74 07                	je     f0104325 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010431e:	83 c0 01             	add    $0x1,%eax
f0104321:	39 c8                	cmp    %ecx,%eax
f0104323:	72 f2                	jb     f0104317 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104325:	5b                   	pop    %ebx
f0104326:	5d                   	pop    %ebp
f0104327:	c3                   	ret    

f0104328 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104328:	55                   	push   %ebp
f0104329:	89 e5                	mov    %esp,%ebp
f010432b:	57                   	push   %edi
f010432c:	56                   	push   %esi
f010432d:	53                   	push   %ebx
f010432e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104331:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104334:	eb 03                	jmp    f0104339 <strtol+0x11>
		s++;
f0104336:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104339:	0f b6 01             	movzbl (%ecx),%eax
f010433c:	3c 20                	cmp    $0x20,%al
f010433e:	74 f6                	je     f0104336 <strtol+0xe>
f0104340:	3c 09                	cmp    $0x9,%al
f0104342:	74 f2                	je     f0104336 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104344:	3c 2b                	cmp    $0x2b,%al
f0104346:	75 0a                	jne    f0104352 <strtol+0x2a>
		s++;
f0104348:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010434b:	bf 00 00 00 00       	mov    $0x0,%edi
f0104350:	eb 11                	jmp    f0104363 <strtol+0x3b>
f0104352:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104357:	3c 2d                	cmp    $0x2d,%al
f0104359:	75 08                	jne    f0104363 <strtol+0x3b>
		s++, neg = 1;
f010435b:	83 c1 01             	add    $0x1,%ecx
f010435e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104363:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104369:	75 15                	jne    f0104380 <strtol+0x58>
f010436b:	80 39 30             	cmpb   $0x30,(%ecx)
f010436e:	75 10                	jne    f0104380 <strtol+0x58>
f0104370:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104374:	75 7c                	jne    f01043f2 <strtol+0xca>
		s += 2, base = 16;
f0104376:	83 c1 02             	add    $0x2,%ecx
f0104379:	bb 10 00 00 00       	mov    $0x10,%ebx
f010437e:	eb 16                	jmp    f0104396 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104380:	85 db                	test   %ebx,%ebx
f0104382:	75 12                	jne    f0104396 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104384:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104389:	80 39 30             	cmpb   $0x30,(%ecx)
f010438c:	75 08                	jne    f0104396 <strtol+0x6e>
		s++, base = 8;
f010438e:	83 c1 01             	add    $0x1,%ecx
f0104391:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104396:	b8 00 00 00 00       	mov    $0x0,%eax
f010439b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010439e:	0f b6 11             	movzbl (%ecx),%edx
f01043a1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01043a4:	89 f3                	mov    %esi,%ebx
f01043a6:	80 fb 09             	cmp    $0x9,%bl
f01043a9:	77 08                	ja     f01043b3 <strtol+0x8b>
			dig = *s - '0';
f01043ab:	0f be d2             	movsbl %dl,%edx
f01043ae:	83 ea 30             	sub    $0x30,%edx
f01043b1:	eb 22                	jmp    f01043d5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01043b3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01043b6:	89 f3                	mov    %esi,%ebx
f01043b8:	80 fb 19             	cmp    $0x19,%bl
f01043bb:	77 08                	ja     f01043c5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01043bd:	0f be d2             	movsbl %dl,%edx
f01043c0:	83 ea 57             	sub    $0x57,%edx
f01043c3:	eb 10                	jmp    f01043d5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01043c5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01043c8:	89 f3                	mov    %esi,%ebx
f01043ca:	80 fb 19             	cmp    $0x19,%bl
f01043cd:	77 16                	ja     f01043e5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01043cf:	0f be d2             	movsbl %dl,%edx
f01043d2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01043d5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01043d8:	7d 0b                	jge    f01043e5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01043da:	83 c1 01             	add    $0x1,%ecx
f01043dd:	0f af 45 10          	imul   0x10(%ebp),%eax
f01043e1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01043e3:	eb b9                	jmp    f010439e <strtol+0x76>

	if (endptr)
f01043e5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01043e9:	74 0d                	je     f01043f8 <strtol+0xd0>
		*endptr = (char *) s;
f01043eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043ee:	89 0e                	mov    %ecx,(%esi)
f01043f0:	eb 06                	jmp    f01043f8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01043f2:	85 db                	test   %ebx,%ebx
f01043f4:	74 98                	je     f010438e <strtol+0x66>
f01043f6:	eb 9e                	jmp    f0104396 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01043f8:	89 c2                	mov    %eax,%edx
f01043fa:	f7 da                	neg    %edx
f01043fc:	85 ff                	test   %edi,%edi
f01043fe:	0f 45 c2             	cmovne %edx,%eax
}
f0104401:	5b                   	pop    %ebx
f0104402:	5e                   	pop    %esi
f0104403:	5f                   	pop    %edi
f0104404:	5d                   	pop    %ebp
f0104405:	c3                   	ret    
f0104406:	66 90                	xchg   %ax,%ax
f0104408:	66 90                	xchg   %ax,%ax
f010440a:	66 90                	xchg   %ax,%ax
f010440c:	66 90                	xchg   %ax,%ax
f010440e:	66 90                	xchg   %ax,%ax

f0104410 <__udivdi3>:
f0104410:	55                   	push   %ebp
f0104411:	57                   	push   %edi
f0104412:	56                   	push   %esi
f0104413:	53                   	push   %ebx
f0104414:	83 ec 1c             	sub    $0x1c,%esp
f0104417:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010441b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010441f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104423:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104427:	85 f6                	test   %esi,%esi
f0104429:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010442d:	89 ca                	mov    %ecx,%edx
f010442f:	89 f8                	mov    %edi,%eax
f0104431:	75 3d                	jne    f0104470 <__udivdi3+0x60>
f0104433:	39 cf                	cmp    %ecx,%edi
f0104435:	0f 87 c5 00 00 00    	ja     f0104500 <__udivdi3+0xf0>
f010443b:	85 ff                	test   %edi,%edi
f010443d:	89 fd                	mov    %edi,%ebp
f010443f:	75 0b                	jne    f010444c <__udivdi3+0x3c>
f0104441:	b8 01 00 00 00       	mov    $0x1,%eax
f0104446:	31 d2                	xor    %edx,%edx
f0104448:	f7 f7                	div    %edi
f010444a:	89 c5                	mov    %eax,%ebp
f010444c:	89 c8                	mov    %ecx,%eax
f010444e:	31 d2                	xor    %edx,%edx
f0104450:	f7 f5                	div    %ebp
f0104452:	89 c1                	mov    %eax,%ecx
f0104454:	89 d8                	mov    %ebx,%eax
f0104456:	89 cf                	mov    %ecx,%edi
f0104458:	f7 f5                	div    %ebp
f010445a:	89 c3                	mov    %eax,%ebx
f010445c:	89 d8                	mov    %ebx,%eax
f010445e:	89 fa                	mov    %edi,%edx
f0104460:	83 c4 1c             	add    $0x1c,%esp
f0104463:	5b                   	pop    %ebx
f0104464:	5e                   	pop    %esi
f0104465:	5f                   	pop    %edi
f0104466:	5d                   	pop    %ebp
f0104467:	c3                   	ret    
f0104468:	90                   	nop
f0104469:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104470:	39 ce                	cmp    %ecx,%esi
f0104472:	77 74                	ja     f01044e8 <__udivdi3+0xd8>
f0104474:	0f bd fe             	bsr    %esi,%edi
f0104477:	83 f7 1f             	xor    $0x1f,%edi
f010447a:	0f 84 98 00 00 00    	je     f0104518 <__udivdi3+0x108>
f0104480:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104485:	89 f9                	mov    %edi,%ecx
f0104487:	89 c5                	mov    %eax,%ebp
f0104489:	29 fb                	sub    %edi,%ebx
f010448b:	d3 e6                	shl    %cl,%esi
f010448d:	89 d9                	mov    %ebx,%ecx
f010448f:	d3 ed                	shr    %cl,%ebp
f0104491:	89 f9                	mov    %edi,%ecx
f0104493:	d3 e0                	shl    %cl,%eax
f0104495:	09 ee                	or     %ebp,%esi
f0104497:	89 d9                	mov    %ebx,%ecx
f0104499:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010449d:	89 d5                	mov    %edx,%ebp
f010449f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01044a3:	d3 ed                	shr    %cl,%ebp
f01044a5:	89 f9                	mov    %edi,%ecx
f01044a7:	d3 e2                	shl    %cl,%edx
f01044a9:	89 d9                	mov    %ebx,%ecx
f01044ab:	d3 e8                	shr    %cl,%eax
f01044ad:	09 c2                	or     %eax,%edx
f01044af:	89 d0                	mov    %edx,%eax
f01044b1:	89 ea                	mov    %ebp,%edx
f01044b3:	f7 f6                	div    %esi
f01044b5:	89 d5                	mov    %edx,%ebp
f01044b7:	89 c3                	mov    %eax,%ebx
f01044b9:	f7 64 24 0c          	mull   0xc(%esp)
f01044bd:	39 d5                	cmp    %edx,%ebp
f01044bf:	72 10                	jb     f01044d1 <__udivdi3+0xc1>
f01044c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01044c5:	89 f9                	mov    %edi,%ecx
f01044c7:	d3 e6                	shl    %cl,%esi
f01044c9:	39 c6                	cmp    %eax,%esi
f01044cb:	73 07                	jae    f01044d4 <__udivdi3+0xc4>
f01044cd:	39 d5                	cmp    %edx,%ebp
f01044cf:	75 03                	jne    f01044d4 <__udivdi3+0xc4>
f01044d1:	83 eb 01             	sub    $0x1,%ebx
f01044d4:	31 ff                	xor    %edi,%edi
f01044d6:	89 d8                	mov    %ebx,%eax
f01044d8:	89 fa                	mov    %edi,%edx
f01044da:	83 c4 1c             	add    $0x1c,%esp
f01044dd:	5b                   	pop    %ebx
f01044de:	5e                   	pop    %esi
f01044df:	5f                   	pop    %edi
f01044e0:	5d                   	pop    %ebp
f01044e1:	c3                   	ret    
f01044e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044e8:	31 ff                	xor    %edi,%edi
f01044ea:	31 db                	xor    %ebx,%ebx
f01044ec:	89 d8                	mov    %ebx,%eax
f01044ee:	89 fa                	mov    %edi,%edx
f01044f0:	83 c4 1c             	add    $0x1c,%esp
f01044f3:	5b                   	pop    %ebx
f01044f4:	5e                   	pop    %esi
f01044f5:	5f                   	pop    %edi
f01044f6:	5d                   	pop    %ebp
f01044f7:	c3                   	ret    
f01044f8:	90                   	nop
f01044f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104500:	89 d8                	mov    %ebx,%eax
f0104502:	f7 f7                	div    %edi
f0104504:	31 ff                	xor    %edi,%edi
f0104506:	89 c3                	mov    %eax,%ebx
f0104508:	89 d8                	mov    %ebx,%eax
f010450a:	89 fa                	mov    %edi,%edx
f010450c:	83 c4 1c             	add    $0x1c,%esp
f010450f:	5b                   	pop    %ebx
f0104510:	5e                   	pop    %esi
f0104511:	5f                   	pop    %edi
f0104512:	5d                   	pop    %ebp
f0104513:	c3                   	ret    
f0104514:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104518:	39 ce                	cmp    %ecx,%esi
f010451a:	72 0c                	jb     f0104528 <__udivdi3+0x118>
f010451c:	31 db                	xor    %ebx,%ebx
f010451e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104522:	0f 87 34 ff ff ff    	ja     f010445c <__udivdi3+0x4c>
f0104528:	bb 01 00 00 00       	mov    $0x1,%ebx
f010452d:	e9 2a ff ff ff       	jmp    f010445c <__udivdi3+0x4c>
f0104532:	66 90                	xchg   %ax,%ax
f0104534:	66 90                	xchg   %ax,%ax
f0104536:	66 90                	xchg   %ax,%ax
f0104538:	66 90                	xchg   %ax,%ax
f010453a:	66 90                	xchg   %ax,%ax
f010453c:	66 90                	xchg   %ax,%ax
f010453e:	66 90                	xchg   %ax,%ax

f0104540 <__umoddi3>:
f0104540:	55                   	push   %ebp
f0104541:	57                   	push   %edi
f0104542:	56                   	push   %esi
f0104543:	53                   	push   %ebx
f0104544:	83 ec 1c             	sub    $0x1c,%esp
f0104547:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010454b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010454f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104553:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104557:	85 d2                	test   %edx,%edx
f0104559:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010455d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104561:	89 f3                	mov    %esi,%ebx
f0104563:	89 3c 24             	mov    %edi,(%esp)
f0104566:	89 74 24 04          	mov    %esi,0x4(%esp)
f010456a:	75 1c                	jne    f0104588 <__umoddi3+0x48>
f010456c:	39 f7                	cmp    %esi,%edi
f010456e:	76 50                	jbe    f01045c0 <__umoddi3+0x80>
f0104570:	89 c8                	mov    %ecx,%eax
f0104572:	89 f2                	mov    %esi,%edx
f0104574:	f7 f7                	div    %edi
f0104576:	89 d0                	mov    %edx,%eax
f0104578:	31 d2                	xor    %edx,%edx
f010457a:	83 c4 1c             	add    $0x1c,%esp
f010457d:	5b                   	pop    %ebx
f010457e:	5e                   	pop    %esi
f010457f:	5f                   	pop    %edi
f0104580:	5d                   	pop    %ebp
f0104581:	c3                   	ret    
f0104582:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104588:	39 f2                	cmp    %esi,%edx
f010458a:	89 d0                	mov    %edx,%eax
f010458c:	77 52                	ja     f01045e0 <__umoddi3+0xa0>
f010458e:	0f bd ea             	bsr    %edx,%ebp
f0104591:	83 f5 1f             	xor    $0x1f,%ebp
f0104594:	75 5a                	jne    f01045f0 <__umoddi3+0xb0>
f0104596:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010459a:	0f 82 e0 00 00 00    	jb     f0104680 <__umoddi3+0x140>
f01045a0:	39 0c 24             	cmp    %ecx,(%esp)
f01045a3:	0f 86 d7 00 00 00    	jbe    f0104680 <__umoddi3+0x140>
f01045a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01045b1:	83 c4 1c             	add    $0x1c,%esp
f01045b4:	5b                   	pop    %ebx
f01045b5:	5e                   	pop    %esi
f01045b6:	5f                   	pop    %edi
f01045b7:	5d                   	pop    %ebp
f01045b8:	c3                   	ret    
f01045b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045c0:	85 ff                	test   %edi,%edi
f01045c2:	89 fd                	mov    %edi,%ebp
f01045c4:	75 0b                	jne    f01045d1 <__umoddi3+0x91>
f01045c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01045cb:	31 d2                	xor    %edx,%edx
f01045cd:	f7 f7                	div    %edi
f01045cf:	89 c5                	mov    %eax,%ebp
f01045d1:	89 f0                	mov    %esi,%eax
f01045d3:	31 d2                	xor    %edx,%edx
f01045d5:	f7 f5                	div    %ebp
f01045d7:	89 c8                	mov    %ecx,%eax
f01045d9:	f7 f5                	div    %ebp
f01045db:	89 d0                	mov    %edx,%eax
f01045dd:	eb 99                	jmp    f0104578 <__umoddi3+0x38>
f01045df:	90                   	nop
f01045e0:	89 c8                	mov    %ecx,%eax
f01045e2:	89 f2                	mov    %esi,%edx
f01045e4:	83 c4 1c             	add    $0x1c,%esp
f01045e7:	5b                   	pop    %ebx
f01045e8:	5e                   	pop    %esi
f01045e9:	5f                   	pop    %edi
f01045ea:	5d                   	pop    %ebp
f01045eb:	c3                   	ret    
f01045ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01045f0:	8b 34 24             	mov    (%esp),%esi
f01045f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01045f8:	89 e9                	mov    %ebp,%ecx
f01045fa:	29 ef                	sub    %ebp,%edi
f01045fc:	d3 e0                	shl    %cl,%eax
f01045fe:	89 f9                	mov    %edi,%ecx
f0104600:	89 f2                	mov    %esi,%edx
f0104602:	d3 ea                	shr    %cl,%edx
f0104604:	89 e9                	mov    %ebp,%ecx
f0104606:	09 c2                	or     %eax,%edx
f0104608:	89 d8                	mov    %ebx,%eax
f010460a:	89 14 24             	mov    %edx,(%esp)
f010460d:	89 f2                	mov    %esi,%edx
f010460f:	d3 e2                	shl    %cl,%edx
f0104611:	89 f9                	mov    %edi,%ecx
f0104613:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104617:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010461b:	d3 e8                	shr    %cl,%eax
f010461d:	89 e9                	mov    %ebp,%ecx
f010461f:	89 c6                	mov    %eax,%esi
f0104621:	d3 e3                	shl    %cl,%ebx
f0104623:	89 f9                	mov    %edi,%ecx
f0104625:	89 d0                	mov    %edx,%eax
f0104627:	d3 e8                	shr    %cl,%eax
f0104629:	89 e9                	mov    %ebp,%ecx
f010462b:	09 d8                	or     %ebx,%eax
f010462d:	89 d3                	mov    %edx,%ebx
f010462f:	89 f2                	mov    %esi,%edx
f0104631:	f7 34 24             	divl   (%esp)
f0104634:	89 d6                	mov    %edx,%esi
f0104636:	d3 e3                	shl    %cl,%ebx
f0104638:	f7 64 24 04          	mull   0x4(%esp)
f010463c:	39 d6                	cmp    %edx,%esi
f010463e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104642:	89 d1                	mov    %edx,%ecx
f0104644:	89 c3                	mov    %eax,%ebx
f0104646:	72 08                	jb     f0104650 <__umoddi3+0x110>
f0104648:	75 11                	jne    f010465b <__umoddi3+0x11b>
f010464a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010464e:	73 0b                	jae    f010465b <__umoddi3+0x11b>
f0104650:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104654:	1b 14 24             	sbb    (%esp),%edx
f0104657:	89 d1                	mov    %edx,%ecx
f0104659:	89 c3                	mov    %eax,%ebx
f010465b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010465f:	29 da                	sub    %ebx,%edx
f0104661:	19 ce                	sbb    %ecx,%esi
f0104663:	89 f9                	mov    %edi,%ecx
f0104665:	89 f0                	mov    %esi,%eax
f0104667:	d3 e0                	shl    %cl,%eax
f0104669:	89 e9                	mov    %ebp,%ecx
f010466b:	d3 ea                	shr    %cl,%edx
f010466d:	89 e9                	mov    %ebp,%ecx
f010466f:	d3 ee                	shr    %cl,%esi
f0104671:	09 d0                	or     %edx,%eax
f0104673:	89 f2                	mov    %esi,%edx
f0104675:	83 c4 1c             	add    $0x1c,%esp
f0104678:	5b                   	pop    %ebx
f0104679:	5e                   	pop    %esi
f010467a:	5f                   	pop    %edi
f010467b:	5d                   	pop    %ebp
f010467c:	c3                   	ret    
f010467d:	8d 76 00             	lea    0x0(%esi),%esi
f0104680:	29 f9                	sub    %edi,%ecx
f0104682:	19 d6                	sbb    %edx,%esi
f0104684:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104688:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010468c:	e9 18 ff ff ff       	jmp    f01045a9 <__umoddi3+0x69>
