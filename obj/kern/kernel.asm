
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


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
f0100046:	b8 50 69 11 f0       	mov    $0xf0116950,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 e5 2f 00 00       	call   f0103042 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 34 10 f0       	push   $0xf01034e0
f010006f:	e8 e5 24 00 00       	call   f0102559 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 b4 0e 00 00       	call   f0100f2d <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 97 06 00 00       	call   f010071d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 69 11 f0 00 	cmpl   $0x0,0xf0116940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 69 11 f0    	mov    %esi,0xf0116940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 fb 34 10 f0       	push   $0xf01034fb
f01000b5:	e8 9f 24 00 00       	call   f0102559 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 6f 24 00 00       	call   f0102533 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 ad 43 10 f0 	movl   $0xf01043ad,(%esp)
f01000cb:	e8 89 24 00 00       	call   f0102559 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 40 06 00 00       	call   f010071d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 13 35 10 f0       	push   $0xf0103513
f01000f7:	e8 5d 24 00 00       	call   f0102559 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 2b 24 00 00       	call   f0102533 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 ad 43 10 f0 	movl   $0xf01043ad,(%esp)
f010010f:	e8 45 24 00 00       	call   f0102559 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 80 36 10 f0 	movzbl -0xfefc980(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 80 36 10 f0 	movzbl -0xfefc980(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 80 35 10 f0 	movzbl -0xfefca80(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 60 35 10 f0 	mov    -0xfefcaa0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 2d 35 10 f0       	push   $0xf010352d
f010026d:	e8 e7 22 00 00       	call   f0102559 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 6e 2c 00 00       	call   f010308f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 39 35 10 f0       	push   $0xf0103539
f01005f0:	e8 64 1f 00 00       	call   f0102559 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 80 37 10 f0       	push   $0xf0103780
f0100636:	68 9e 37 10 f0       	push   $0xf010379e
f010063b:	68 a3 37 10 f0       	push   $0xf01037a3
f0100640:	e8 14 1f 00 00       	call   f0102559 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 0c 38 10 f0       	push   $0xf010380c
f010064d:	68 ac 37 10 f0       	push   $0xf01037ac
f0100652:	68 a3 37 10 f0       	push   $0xf01037a3
f0100657:	e8 fd 1e 00 00       	call   f0102559 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 b5 37 10 f0       	push   $0xf01037b5
f010066e:	e8 e6 1e 00 00       	call   f0102559 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 34 38 10 f0       	push   $0xf0103834
f0100680:	e8 d4 1e 00 00       	call   f0102559 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 5c 38 10 f0       	push   $0xf010385c
f0100697:	e8 bd 1e 00 00       	call   f0102559 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 d1 34 10 00       	push   $0x1034d1
f01006a4:	68 d1 34 10 f0       	push   $0xf01034d1
f01006a9:	68 80 38 10 f0       	push   $0xf0103880
f01006ae:	e8 a6 1e 00 00       	call   f0102559 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 a4 38 10 f0       	push   $0xf01038a4
f01006c5:	e8 8f 1e 00 00       	call   f0102559 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 c8 38 10 f0       	push   $0xf01038c8
f01006dc:	e8 78 1e 00 00       	call   f0102559 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 6d 11 f0       	mov    $0xf0116d4f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 ec 38 10 f0       	push   $0xf01038ec
f0100707:	e8 4d 1e 00 00       	call   f0102559 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	5d                   	pop    %ebp
f010071c:	c3                   	ret    

f010071d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010071d:	55                   	push   %ebp
f010071e:	89 e5                	mov    %esp,%ebp
f0100720:	57                   	push   %edi
f0100721:	56                   	push   %esi
f0100722:	53                   	push   %ebx
f0100723:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100726:	68 18 39 10 f0       	push   $0xf0103918
f010072b:	e8 29 1e 00 00       	call   f0102559 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 3c 39 10 f0 	movl   $0xf010393c,(%esp)
f0100737:	e8 1d 1e 00 00       	call   f0102559 <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ce 37 10 f0       	push   $0xf01037ce
f0100747:	e8 9f 26 00 00       	call   f0102deb <readline>
f010074c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010074e:	83 c4 10             	add    $0x10,%esp
f0100751:	85 c0                	test   %eax,%eax
f0100753:	74 ea                	je     f010073f <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100755:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010075c:	be 00 00 00 00       	mov    $0x0,%esi
f0100761:	eb 0a                	jmp    f010076d <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100763:	c6 03 00             	movb   $0x0,(%ebx)
f0100766:	89 f7                	mov    %esi,%edi
f0100768:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010076b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010076d:	0f b6 03             	movzbl (%ebx),%eax
f0100770:	84 c0                	test   %al,%al
f0100772:	74 63                	je     f01007d7 <monitor+0xba>
f0100774:	83 ec 08             	sub    $0x8,%esp
f0100777:	0f be c0             	movsbl %al,%eax
f010077a:	50                   	push   %eax
f010077b:	68 d2 37 10 f0       	push   $0xf01037d2
f0100780:	e8 80 28 00 00       	call   f0103005 <strchr>
f0100785:	83 c4 10             	add    $0x10,%esp
f0100788:	85 c0                	test   %eax,%eax
f010078a:	75 d7                	jne    f0100763 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010078c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010078f:	74 46                	je     f01007d7 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100791:	83 fe 0f             	cmp    $0xf,%esi
f0100794:	75 14                	jne    f01007aa <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100796:	83 ec 08             	sub    $0x8,%esp
f0100799:	6a 10                	push   $0x10
f010079b:	68 d7 37 10 f0       	push   $0xf01037d7
f01007a0:	e8 b4 1d 00 00       	call   f0102559 <cprintf>
f01007a5:	83 c4 10             	add    $0x10,%esp
f01007a8:	eb 95                	jmp    f010073f <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01007aa:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ad:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007b1:	eb 03                	jmp    f01007b6 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01007b3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01007b6:	0f b6 03             	movzbl (%ebx),%eax
f01007b9:	84 c0                	test   %al,%al
f01007bb:	74 ae                	je     f010076b <monitor+0x4e>
f01007bd:	83 ec 08             	sub    $0x8,%esp
f01007c0:	0f be c0             	movsbl %al,%eax
f01007c3:	50                   	push   %eax
f01007c4:	68 d2 37 10 f0       	push   $0xf01037d2
f01007c9:	e8 37 28 00 00       	call   f0103005 <strchr>
f01007ce:	83 c4 10             	add    $0x10,%esp
f01007d1:	85 c0                	test   %eax,%eax
f01007d3:	74 de                	je     f01007b3 <monitor+0x96>
f01007d5:	eb 94                	jmp    f010076b <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01007d7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007de:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007df:	85 f6                	test   %esi,%esi
f01007e1:	0f 84 58 ff ff ff    	je     f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007e7:	83 ec 08             	sub    $0x8,%esp
f01007ea:	68 9e 37 10 f0       	push   $0xf010379e
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 b0 27 00 00       	call   f0102fa7 <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 ac 37 10 f0       	push   $0xf01037ac
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 99 27 00 00       	call   f0102fa7 <strcmp>
f010080e:	83 c4 10             	add    $0x10,%esp
f0100811:	85 c0                	test   %eax,%eax
f0100813:	75 2f                	jne    f0100844 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100815:	b8 01 00 00 00       	mov    $0x1,%eax
f010081a:	eb 05                	jmp    f0100821 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010081c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100821:	83 ec 04             	sub    $0x4,%esp
f0100824:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100827:	01 d0                	add    %edx,%eax
f0100829:	ff 75 08             	pushl  0x8(%ebp)
f010082c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010082f:	51                   	push   %ecx
f0100830:	56                   	push   %esi
f0100831:	ff 14 85 6c 39 10 f0 	call   *-0xfefc694(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	78 1d                	js     f010085c <monitor+0x13f>
f010083f:	e9 fb fe ff ff       	jmp    f010073f <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100844:	83 ec 08             	sub    $0x8,%esp
f0100847:	ff 75 a8             	pushl  -0x58(%ebp)
f010084a:	68 f4 37 10 f0       	push   $0xf01037f4
f010084f:	e8 05 1d 00 00       	call   f0102559 <cprintf>
f0100854:	83 c4 10             	add    $0x10,%esp
f0100857:	e9 e3 fe ff ff       	jmp    f010073f <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010085c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010085f:	5b                   	pop    %ebx
f0100860:	5e                   	pop    %esi
f0100861:	5f                   	pop    %edi
f0100862:	5d                   	pop    %ebp
f0100863:	c3                   	ret    

f0100864 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100864:	55                   	push   %ebp
f0100865:	89 e5                	mov    %esp,%ebp
f0100867:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100869:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100870:	75 0f                	jne    f0100881 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100872:	b8 4f 79 11 f0       	mov    $0xf011794f,%eax
f0100877:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010087c:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100881:	a1 38 65 11 f0       	mov    0xf0116538,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f0100886:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010088c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100892:	01 c2                	add    %eax,%edx
f0100894:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	return result;
}
f010089a:	5d                   	pop    %ebp
f010089b:	c3                   	ret    

f010089c <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010089c:	55                   	push   %ebp
f010089d:	89 e5                	mov    %esp,%ebp
f010089f:	56                   	push   %esi
f01008a0:	53                   	push   %ebx
f01008a1:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008a3:	83 ec 0c             	sub    $0xc,%esp
f01008a6:	50                   	push   %eax
f01008a7:	e8 46 1c 00 00       	call   f01024f2 <mc146818_read>
f01008ac:	89 c6                	mov    %eax,%esi
f01008ae:	83 c3 01             	add    $0x1,%ebx
f01008b1:	89 1c 24             	mov    %ebx,(%esp)
f01008b4:	e8 39 1c 00 00       	call   f01024f2 <mc146818_read>
f01008b9:	c1 e0 08             	shl    $0x8,%eax
f01008bc:	09 f0                	or     %esi,%eax
}
f01008be:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008c1:	5b                   	pop    %ebx
f01008c2:	5e                   	pop    %esi
f01008c3:	5d                   	pop    %ebp
f01008c4:	c3                   	ret    

f01008c5 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008c5:	89 d1                	mov    %edx,%ecx
f01008c7:	c1 e9 16             	shr    $0x16,%ecx
f01008ca:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01008cd:	a8 01                	test   $0x1,%al
f01008cf:	74 52                	je     f0100923 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01008d1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01008d6:	89 c1                	mov    %eax,%ecx
f01008d8:	c1 e9 0c             	shr    $0xc,%ecx
f01008db:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f01008e1:	72 1b                	jb     f01008fe <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01008e3:	55                   	push   %ebp
f01008e4:	89 e5                	mov    %esp,%ebp
f01008e6:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01008e9:	50                   	push   %eax
f01008ea:	68 7c 39 10 f0       	push   $0xf010397c
f01008ef:	68 e2 02 00 00       	push   $0x2e2
f01008f4:	68 fc 40 10 f0       	push   $0xf01040fc
f01008f9:	e8 8d f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01008fe:	c1 ea 0c             	shr    $0xc,%edx
f0100901:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100907:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010090e:	89 c2                	mov    %eax,%edx
f0100910:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100913:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100918:	85 d2                	test   %edx,%edx
f010091a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010091f:	0f 44 c2             	cmove  %edx,%eax
f0100922:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100923:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100928:	c3                   	ret    

f0100929 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100929:	55                   	push   %ebp
f010092a:	89 e5                	mov    %esp,%ebp
f010092c:	57                   	push   %edi
f010092d:	56                   	push   %esi
f010092e:	53                   	push   %ebx
f010092f:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100932:	84 c0                	test   %al,%al
f0100934:	0f 85 72 02 00 00    	jne    f0100bac <check_page_free_list+0x283>
f010093a:	e9 7f 02 00 00       	jmp    f0100bbe <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f010093f:	83 ec 04             	sub    $0x4,%esp
f0100942:	68 a0 39 10 f0       	push   $0xf01039a0
f0100947:	68 25 02 00 00       	push   $0x225
f010094c:	68 fc 40 10 f0       	push   $0xf01040fc
f0100951:	e8 35 f7 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100956:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100959:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010095c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010095f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100962:	89 c2                	mov    %eax,%edx
f0100964:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010096a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100970:	0f 95 c2             	setne  %dl
f0100973:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100976:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010097a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f010097c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100980:	8b 00                	mov    (%eax),%eax
f0100982:	85 c0                	test   %eax,%eax
f0100984:	75 dc                	jne    f0100962 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100986:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100989:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010098f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100992:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100995:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100997:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010099a:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010099f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009a4:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f01009aa:	eb 53                	jmp    f01009ff <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009ac:	89 d8                	mov    %ebx,%eax
f01009ae:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01009b4:	c1 f8 03             	sar    $0x3,%eax
f01009b7:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009ba:	89 c2                	mov    %eax,%edx
f01009bc:	c1 ea 16             	shr    $0x16,%edx
f01009bf:	39 f2                	cmp    %esi,%edx
f01009c1:	73 3a                	jae    f01009fd <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c3:	89 c2                	mov    %eax,%edx
f01009c5:	c1 ea 0c             	shr    $0xc,%edx
f01009c8:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01009ce:	72 12                	jb     f01009e2 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d0:	50                   	push   %eax
f01009d1:	68 7c 39 10 f0       	push   $0xf010397c
f01009d6:	6a 52                	push   $0x52
f01009d8:	68 08 41 10 f0       	push   $0xf0104108
f01009dd:	e8 a9 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009e2:	83 ec 04             	sub    $0x4,%esp
f01009e5:	68 80 00 00 00       	push   $0x80
f01009ea:	68 97 00 00 00       	push   $0x97
f01009ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f4:	50                   	push   %eax
f01009f5:	e8 48 26 00 00       	call   f0103042 <memset>
f01009fa:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009fd:	8b 1b                	mov    (%ebx),%ebx
f01009ff:	85 db                	test   %ebx,%ebx
f0100a01:	75 a9                	jne    f01009ac <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a03:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a08:	e8 57 fe ff ff       	call   f0100864 <boot_alloc>
f0100a0d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a10:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a16:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
		assert(pp < pages + npages);
f0100a1c:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100a21:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a24:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a27:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a2a:	be 00 00 00 00       	mov    $0x0,%esi
f0100a2f:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a32:	e9 30 01 00 00       	jmp    f0100b67 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a37:	39 ca                	cmp    %ecx,%edx
f0100a39:	73 19                	jae    f0100a54 <check_page_free_list+0x12b>
f0100a3b:	68 16 41 10 f0       	push   $0xf0104116
f0100a40:	68 22 41 10 f0       	push   $0xf0104122
f0100a45:	68 3f 02 00 00       	push   $0x23f
f0100a4a:	68 fc 40 10 f0       	push   $0xf01040fc
f0100a4f:	e8 37 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a54:	39 fa                	cmp    %edi,%edx
f0100a56:	72 19                	jb     f0100a71 <check_page_free_list+0x148>
f0100a58:	68 37 41 10 f0       	push   $0xf0104137
f0100a5d:	68 22 41 10 f0       	push   $0xf0104122
f0100a62:	68 40 02 00 00       	push   $0x240
f0100a67:	68 fc 40 10 f0       	push   $0xf01040fc
f0100a6c:	e8 1a f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a71:	89 d0                	mov    %edx,%eax
f0100a73:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a76:	a8 07                	test   $0x7,%al
f0100a78:	74 19                	je     f0100a93 <check_page_free_list+0x16a>
f0100a7a:	68 c4 39 10 f0       	push   $0xf01039c4
f0100a7f:	68 22 41 10 f0       	push   $0xf0104122
f0100a84:	68 41 02 00 00       	push   $0x241
f0100a89:	68 fc 40 10 f0       	push   $0xf01040fc
f0100a8e:	e8 f8 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a93:	c1 f8 03             	sar    $0x3,%eax
f0100a96:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	75 19                	jne    f0100ab6 <check_page_free_list+0x18d>
f0100a9d:	68 4b 41 10 f0       	push   $0xf010414b
f0100aa2:	68 22 41 10 f0       	push   $0xf0104122
f0100aa7:	68 44 02 00 00       	push   $0x244
f0100aac:	68 fc 40 10 f0       	push   $0xf01040fc
f0100ab1:	e8 d5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ab6:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100abb:	75 19                	jne    f0100ad6 <check_page_free_list+0x1ad>
f0100abd:	68 5c 41 10 f0       	push   $0xf010415c
f0100ac2:	68 22 41 10 f0       	push   $0xf0104122
f0100ac7:	68 45 02 00 00       	push   $0x245
f0100acc:	68 fc 40 10 f0       	push   $0xf01040fc
f0100ad1:	e8 b5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ad6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100adb:	75 19                	jne    f0100af6 <check_page_free_list+0x1cd>
f0100add:	68 f8 39 10 f0       	push   $0xf01039f8
f0100ae2:	68 22 41 10 f0       	push   $0xf0104122
f0100ae7:	68 46 02 00 00       	push   $0x246
f0100aec:	68 fc 40 10 f0       	push   $0xf01040fc
f0100af1:	e8 95 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100af6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100afb:	75 19                	jne    f0100b16 <check_page_free_list+0x1ed>
f0100afd:	68 75 41 10 f0       	push   $0xf0104175
f0100b02:	68 22 41 10 f0       	push   $0xf0104122
f0100b07:	68 47 02 00 00       	push   $0x247
f0100b0c:	68 fc 40 10 f0       	push   $0xf01040fc
f0100b11:	e8 75 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b16:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b1b:	76 3f                	jbe    f0100b5c <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b1d:	89 c3                	mov    %eax,%ebx
f0100b1f:	c1 eb 0c             	shr    $0xc,%ebx
f0100b22:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b25:	77 12                	ja     f0100b39 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b27:	50                   	push   %eax
f0100b28:	68 7c 39 10 f0       	push   $0xf010397c
f0100b2d:	6a 52                	push   $0x52
f0100b2f:	68 08 41 10 f0       	push   $0xf0104108
f0100b34:	e8 52 f5 ff ff       	call   f010008b <_panic>
f0100b39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b41:	76 1e                	jbe    f0100b61 <check_page_free_list+0x238>
f0100b43:	68 1c 3a 10 f0       	push   $0xf0103a1c
f0100b48:	68 22 41 10 f0       	push   $0xf0104122
f0100b4d:	68 48 02 00 00       	push   $0x248
f0100b52:	68 fc 40 10 f0       	push   $0xf01040fc
f0100b57:	e8 2f f5 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b5c:	83 c6 01             	add    $0x1,%esi
f0100b5f:	eb 04                	jmp    f0100b65 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100b61:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b65:	8b 12                	mov    (%edx),%edx
f0100b67:	85 d2                	test   %edx,%edx
f0100b69:	0f 85 c8 fe ff ff    	jne    f0100a37 <check_page_free_list+0x10e>
f0100b6f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100b72:	85 f6                	test   %esi,%esi
f0100b74:	7f 19                	jg     f0100b8f <check_page_free_list+0x266>
f0100b76:	68 8f 41 10 f0       	push   $0xf010418f
f0100b7b:	68 22 41 10 f0       	push   $0xf0104122
f0100b80:	68 50 02 00 00       	push   $0x250
f0100b85:	68 fc 40 10 f0       	push   $0xf01040fc
f0100b8a:	e8 fc f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b8f:	85 db                	test   %ebx,%ebx
f0100b91:	7f 42                	jg     f0100bd5 <check_page_free_list+0x2ac>
f0100b93:	68 a1 41 10 f0       	push   $0xf01041a1
f0100b98:	68 22 41 10 f0       	push   $0xf0104122
f0100b9d:	68 51 02 00 00       	push   $0x251
f0100ba2:	68 fc 40 10 f0       	push   $0xf01040fc
f0100ba7:	e8 df f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bac:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100bb1:	85 c0                	test   %eax,%eax
f0100bb3:	0f 85 9d fd ff ff    	jne    f0100956 <check_page_free_list+0x2d>
f0100bb9:	e9 81 fd ff ff       	jmp    f010093f <check_page_free_list+0x16>
f0100bbe:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100bc5:	0f 84 74 fd ff ff    	je     f010093f <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bcb:	be 00 04 00 00       	mov    $0x400,%esi
f0100bd0:	e9 cf fd ff ff       	jmp    f01009a4 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100bd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bd8:	5b                   	pop    %ebx
f0100bd9:	5e                   	pop    %esi
f0100bda:	5f                   	pop    %edi
f0100bdb:	5d                   	pop    %ebp
f0100bdc:	c3                   	ret    

f0100bdd <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100bdd:	55                   	push   %ebp
f0100bde:	89 e5                	mov    %esp,%ebp
f0100be0:	56                   	push   %esi
f0100be1:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
        page_free_list = NULL;
f0100be2:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0100be9:	00 00 00 
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
f0100bec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bf1:	e8 6e fc ff ff       	call   f0100864 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bf6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100bfb:	77 15                	ja     f0100c12 <page_init+0x35>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bfd:	50                   	push   %eax
f0100bfe:	68 64 3a 10 f0       	push   $0xf0103a64
f0100c03:	68 03 01 00 00       	push   $0x103
f0100c08:	68 fc 40 10 f0       	push   $0xf01040fc
f0100c0d:	e8 79 f4 ff ff       	call   f010008b <_panic>
f0100c12:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c17:	c1 e8 0c             	shr    $0xc,%eax
	for (i = 0; i < npages; i++) {
f0100c1a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c1f:	be 00 00 00 00       	mov    $0x0,%esi
f0100c24:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c29:	eb 62                	jmp    f0100c8d <page_init+0xb0>
            if(i==0)
f0100c2b:	85 d2                	test   %edx,%edx
f0100c2d:	75 14                	jne    f0100c43 <page_init+0x66>
             {
		pages[i].pp_ref = 1;
f0100c2f:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
f0100c35:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100c3b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100c41:	eb 47                	jmp    f0100c8a <page_init+0xad>
             }
             else if(i >= low_pgm && i < upp_pgm)
f0100c43:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100c49:	76 1b                	jbe    f0100c66 <page_init+0x89>
f0100c4b:	39 c2                	cmp    %eax,%edx
f0100c4d:	73 17                	jae    f0100c66 <page_init+0x89>
             {
                pages[i].pp_ref=1;
f0100c4f:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
f0100c55:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100c58:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link=NULL;
f0100c5e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100c64:	eb 24                	jmp    f0100c8a <page_init+0xad>
f0100c66:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
             }
             else
             {
                 pages[i].pp_ref=0;
f0100c6d:	89 cb                	mov    %ecx,%ebx
f0100c6f:	03 1d 4c 69 11 f0    	add    0xf011694c,%ebx
f0100c75:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
                 pages[i].pp_link = page_free_list;
f0100c7b:	89 33                	mov    %esi,(%ebx)
                 page_free_list = &pages[i];
f0100c7d:	89 ce                	mov    %ecx,%esi
f0100c7f:	03 35 4c 69 11 f0    	add    0xf011694c,%esi
f0100c85:	bb 01 00 00 00       	mov    $0x1,%ebx
	size_t i;
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) {
f0100c8a:	83 c2 01             	add    $0x1,%edx
f0100c8d:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100c93:	72 96                	jb     f0100c2b <page_init+0x4e>
f0100c95:	84 db                	test   %bl,%bl
f0100c97:	74 06                	je     f0100c9f <page_init+0xc2>
f0100c99:	89 35 3c 65 11 f0    	mov    %esi,0xf011653c
                 pages[i].pp_ref=0;
                 pages[i].pp_link = page_free_list;
                 page_free_list = &pages[i];
             }
          }
}
f0100c9f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ca2:	5b                   	pop    %ebx
f0100ca3:	5e                   	pop    %esi
f0100ca4:	5d                   	pop    %ebp
f0100ca5:	c3                   	ret    

f0100ca6 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ca6:	55                   	push   %ebp
f0100ca7:	89 e5                	mov    %esp,%ebp
f0100ca9:	53                   	push   %ebx
f0100caa:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
        if(page_free_list==NULL)
f0100cad:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100cb3:	85 db                	test   %ebx,%ebx
f0100cb5:	74 58                	je     f0100d0f <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100cb7:	8b 03                	mov    (%ebx),%eax
f0100cb9:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
        result->pp_link=NULL;
f0100cbe:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if(alloc_flags & ALLOC_ZERO)
f0100cc4:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100cc8:	74 45                	je     f0100d0f <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100cca:	89 d8                	mov    %ebx,%eax
f0100ccc:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100cd2:	c1 f8 03             	sar    $0x3,%eax
f0100cd5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cd8:	89 c2                	mov    %eax,%edx
f0100cda:	c1 ea 0c             	shr    $0xc,%edx
f0100cdd:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100ce3:	72 12                	jb     f0100cf7 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce5:	50                   	push   %eax
f0100ce6:	68 7c 39 10 f0       	push   $0xf010397c
f0100ceb:	6a 52                	push   $0x52
f0100ced:	68 08 41 10 f0       	push   $0xf0104108
f0100cf2:	e8 94 f3 ff ff       	call   f010008b <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100cf7:	83 ec 04             	sub    $0x4,%esp
f0100cfa:	68 00 10 00 00       	push   $0x1000
f0100cff:	6a 00                	push   $0x0
f0100d01:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d06:	50                   	push   %eax
f0100d07:	e8 36 23 00 00       	call   f0103042 <memset>
f0100d0c:	83 c4 10             	add    $0x10,%esp
	return result;
}
f0100d0f:	89 d8                	mov    %ebx,%eax
f0100d11:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d14:	c9                   	leave  
f0100d15:	c3                   	ret    

f0100d16 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d16:	55                   	push   %ebp
f0100d17:	89 e5                	mov    %esp,%ebp
f0100d19:	83 ec 08             	sub    $0x8,%esp
f0100d1c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0 || pp->pp_link == NULL);  
f0100d1f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d24:	74 1e                	je     f0100d44 <page_free+0x2e>
f0100d26:	83 38 00             	cmpl   $0x0,(%eax)
f0100d29:	74 19                	je     f0100d44 <page_free+0x2e>
f0100d2b:	68 88 3a 10 f0       	push   $0xf0103a88
f0100d30:	68 22 41 10 f0       	push   $0xf0104122
f0100d35:	68 3f 01 00 00       	push   $0x13f
f0100d3a:	68 fc 40 10 f0       	push   $0xf01040fc
f0100d3f:	e8 47 f3 ff ff       	call   f010008b <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100d44:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d4a:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100d4c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100d51:	c9                   	leave  
f0100d52:	c3                   	ret    

f0100d53 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d53:	55                   	push   %ebp
f0100d54:	89 e5                	mov    %esp,%ebp
f0100d56:	83 ec 08             	sub    $0x8,%esp
f0100d59:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d5c:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d60:	83 e8 01             	sub    $0x1,%eax
f0100d63:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d67:	66 85 c0             	test   %ax,%ax
f0100d6a:	75 0c                	jne    f0100d78 <page_decref+0x25>
		page_free(pp);
f0100d6c:	83 ec 0c             	sub    $0xc,%esp
f0100d6f:	52                   	push   %edx
f0100d70:	e8 a1 ff ff ff       	call   f0100d16 <page_free>
f0100d75:	83 c4 10             	add    $0x10,%esp
}
f0100d78:	c9                   	leave  
f0100d79:	c3                   	ret    

f0100d7a <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d7a:	55                   	push   %ebp
f0100d7b:	89 e5                	mov    %esp,%ebp
f0100d7d:	56                   	push   %esi
f0100d7e:	53                   	push   %ebx
f0100d7f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	uint32_t pdx=PDX(va);
	uint32_t ptx=PTX(va);
f0100d82:	89 de                	mov    %ebx,%esi
f0100d84:	c1 ee 0c             	shr    $0xc,%esi
f0100d87:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	pte_t *po_entry;
 	pde_t *pt_entry=pgdir+pdx;
f0100d8d:	c1 eb 16             	shr    $0x16,%ebx
f0100d90:	c1 e3 02             	shl    $0x2,%ebx
f0100d93:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*pt_entry&PTE_P))
f0100d96:	f6 03 01             	testb  $0x1,(%ebx)
f0100d99:	75 2d                	jne    f0100dc8 <pgdir_walk+0x4e>
	{
		if(create==0)
f0100d9b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d9f:	74 59                	je     f0100dfa <pgdir_walk+0x80>
			return NULL;
		struct PageInfo *pp=page_alloc(1);
f0100da1:	83 ec 0c             	sub    $0xc,%esp
f0100da4:	6a 01                	push   $0x1
f0100da6:	e8 fb fe ff ff       	call   f0100ca6 <page_alloc>
			if(pp==NULL)
f0100dab:	83 c4 10             	add    $0x10,%esp
f0100dae:	85 c0                	test   %eax,%eax
f0100db0:	74 4f                	je     f0100e01 <pgdir_walk+0x87>
			{
				return NULL;
			}
		pp->pp_ref++;
f0100db2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
f0100db7:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100dbd:	c1 f8 03             	sar    $0x3,%eax
f0100dc0:	c1 e0 0c             	shl    $0xc,%eax
f0100dc3:	83 c8 07             	or     $0x7,%eax
f0100dc6:	89 03                	mov    %eax,(%ebx)
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
f0100dc8:	8b 03                	mov    (%ebx),%eax
f0100dca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dcf:	89 c2                	mov    %eax,%edx
f0100dd1:	c1 ea 0c             	shr    $0xc,%edx
f0100dd4:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100dda:	72 15                	jb     f0100df1 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ddc:	50                   	push   %eax
f0100ddd:	68 7c 39 10 f0       	push   $0xf010397c
f0100de2:	68 7a 01 00 00       	push   $0x17a
f0100de7:	68 fc 40 10 f0       	push   $0xf01040fc
f0100dec:	e8 9a f2 ff ff       	call   f010008b <_panic>
	return po_entry+ptx;
f0100df1:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100df8:	eb 0c                	jmp    f0100e06 <pgdir_walk+0x8c>
	pte_t *po_entry;
 	pde_t *pt_entry=pgdir+pdx;
	if(!(*pt_entry&PTE_P))
	{
		if(create==0)
			return NULL;
f0100dfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dff:	eb 05                	jmp    f0100e06 <pgdir_walk+0x8c>
		struct PageInfo *pp=page_alloc(1);
			if(pp==NULL)
			{
				return NULL;
f0100e01:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pt_entry=(page2pa(pp)|PTE_P|PTE_U|PTE_W);
	}	
	po_entry=(pte_t *)KADDR(PTE_ADDR(*pt_entry));
	return po_entry+ptx;
}
f0100e06:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e09:	5b                   	pop    %ebx
f0100e0a:	5e                   	pop    %esi
f0100e0b:	5d                   	pop    %ebp
f0100e0c:	c3                   	ret    

f0100e0d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e0d:	55                   	push   %ebp
f0100e0e:	89 e5                	mov    %esp,%ebp
f0100e10:	53                   	push   %ebx
f0100e11:	83 ec 08             	sub    $0x8,%esp
f0100e14:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f0100e17:	6a 00                	push   $0x0
f0100e19:	ff 75 0c             	pushl  0xc(%ebp)
f0100e1c:	ff 75 08             	pushl  0x8(%ebp)
f0100e1f:	e8 56 ff ff ff       	call   f0100d7a <pgdir_walk>
	if(po_entry==NULL)
f0100e24:	83 c4 10             	add    $0x10,%esp
f0100e27:	85 c0                	test   %eax,%eax
f0100e29:	74 37                	je     f0100e62 <page_lookup+0x55>
	{
		return NULL;
	}
	if(!(*po_entry&PTE_P))
f0100e2b:	f6 00 01             	testb  $0x1,(%eax)
f0100e2e:	74 39                	je     f0100e69 <page_lookup+0x5c>
	{
		return NULL;
	}
	if(pte_store!=0)
f0100e30:	85 db                	test   %ebx,%ebx
f0100e32:	74 02                	je     f0100e36 <page_lookup+0x29>
	{
		*pte_store=po_entry;
f0100e34:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e36:	8b 00                	mov    (%eax),%eax
f0100e38:	c1 e8 0c             	shr    $0xc,%eax
f0100e3b:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100e41:	72 14                	jb     f0100e57 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100e43:	83 ec 04             	sub    $0x4,%esp
f0100e46:	68 b0 3a 10 f0       	push   $0xf0103ab0
f0100e4b:	6a 4b                	push   $0x4b
f0100e4d:	68 08 41 10 f0       	push   $0xf0104108
f0100e52:	e8 34 f2 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100e57:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100e5d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
f0100e60:	eb 0c                	jmp    f0100e6e <page_lookup+0x61>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f0100e62:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e67:	eb 05                	jmp    f0100e6e <page_lookup+0x61>
	}
	if(!(*po_entry&PTE_P))
	{
		return NULL;
f0100e69:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
}	
f0100e6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e71:	c9                   	leave  
f0100e72:	c3                   	ret    

f0100e73 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100e73:	55                   	push   %ebp
f0100e74:	89 e5                	mov    %esp,%ebp
f0100e76:	53                   	push   %ebx
f0100e77:	83 ec 18             	sub    $0x18,%esp
f0100e7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f0100e7d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f0100e84:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100e87:	50                   	push   %eax
f0100e88:	53                   	push   %ebx
f0100e89:	ff 75 08             	pushl  0x8(%ebp)
f0100e8c:	e8 7c ff ff ff       	call   f0100e0d <page_lookup>
	if(pp==NULL)
f0100e91:	83 c4 10             	add    $0x10,%esp
f0100e94:	85 c0                	test   %eax,%eax
f0100e96:	74 18                	je     f0100eb0 <page_remove+0x3d>
	{
		return;
	}
	page_decref(pp);
f0100e98:	83 ec 0c             	sub    $0xc,%esp
f0100e9b:	50                   	push   %eax
f0100e9c:	e8 b2 fe ff ff       	call   f0100d53 <page_decref>
	*pte_store=0;
f0100ea1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ea4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100eaa:	0f 01 3b             	invlpg (%ebx)
f0100ead:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);	
}
f0100eb0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eb3:	c9                   	leave  
f0100eb4:	c3                   	ret    

f0100eb5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	57                   	push   %edi
f0100eb9:	56                   	push   %esi
f0100eba:	53                   	push   %ebx
f0100ebb:	83 ec 10             	sub    $0x10,%esp
f0100ebe:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ec1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f0100ec4:	6a 01                	push   $0x1
f0100ec6:	ff 75 10             	pushl  0x10(%ebp)
f0100ec9:	56                   	push   %esi
f0100eca:	e8 ab fe ff ff       	call   f0100d7a <pgdir_walk>
	if(po_entry==NULL)
f0100ecf:	83 c4 10             	add    $0x10,%esp
f0100ed2:	85 c0                	test   %eax,%eax
f0100ed4:	74 4a                	je     f0100f20 <page_insert+0x6b>
f0100ed6:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100ed8:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*po_entry)&PTE_P)
f0100edd:	f6 00 01             	testb  $0x1,(%eax)
f0100ee0:	74 15                	je     f0100ef7 <page_insert+0x42>
f0100ee2:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ee5:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir,va);
		page_remove(pgdir,va);
f0100ee8:	83 ec 08             	sub    $0x8,%esp
f0100eeb:	ff 75 10             	pushl  0x10(%ebp)
f0100eee:	56                   	push   %esi
f0100eef:	e8 7f ff ff ff       	call   f0100e73 <page_remove>
f0100ef4:	83 c4 10             	add    $0x10,%esp
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
f0100ef7:	2b 1d 4c 69 11 f0    	sub    0xf011694c,%ebx
f0100efd:	c1 fb 03             	sar    $0x3,%ebx
f0100f00:	c1 e3 0c             	shl    $0xc,%ebx
f0100f03:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f06:	83 c8 01             	or     $0x1,%eax
f0100f09:	09 c3                	or     %eax,%ebx
f0100f0b:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)]|=perm;
f0100f0d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f10:	c1 e8 16             	shr    $0x16,%eax
f0100f13:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f16:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0100f19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1e:	eb 05                	jmp    f0100f25 <page_insert+0x70>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f0100f20:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
	pgdir[PDX(va)]|=perm;
	return 0;
}
f0100f25:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f28:	5b                   	pop    %ebx
f0100f29:	5e                   	pop    %esi
f0100f2a:	5f                   	pop    %edi
f0100f2b:	5d                   	pop    %ebp
f0100f2c:	c3                   	ret    

f0100f2d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f2d:	55                   	push   %ebp
f0100f2e:	89 e5                	mov    %esp,%ebp
f0100f30:	57                   	push   %edi
f0100f31:	56                   	push   %esi
f0100f32:	53                   	push   %ebx
f0100f33:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f36:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f3b:	e8 5c f9 ff ff       	call   f010089c <nvram_read>
f0100f40:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f42:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f47:	e8 50 f9 ff ff       	call   f010089c <nvram_read>
f0100f4c:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100f4e:	b8 34 00 00 00       	mov    $0x34,%eax
f0100f53:	e8 44 f9 ff ff       	call   f010089c <nvram_read>
f0100f58:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100f5b:	85 c0                	test   %eax,%eax
f0100f5d:	74 07                	je     f0100f66 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100f5f:	05 00 40 00 00       	add    $0x4000,%eax
f0100f64:	eb 0b                	jmp    f0100f71 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100f66:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100f6c:	85 f6                	test   %esi,%esi
f0100f6e:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100f71:	89 c2                	mov    %eax,%edx
f0100f73:	c1 ea 02             	shr    $0x2,%edx
f0100f76:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f7c:	89 c2                	mov    %eax,%edx
f0100f7e:	29 da                	sub    %ebx,%edx
f0100f80:	52                   	push   %edx
f0100f81:	53                   	push   %ebx
f0100f82:	50                   	push   %eax
f0100f83:	68 d0 3a 10 f0       	push   $0xf0103ad0
f0100f88:	e8 cc 15 00 00       	call   f0102559 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100f8d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100f92:	e8 cd f8 ff ff       	call   f0100864 <boot_alloc>
f0100f97:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0100f9c:	83 c4 0c             	add    $0xc,%esp
f0100f9f:	68 00 10 00 00       	push   $0x1000
f0100fa4:	6a 00                	push   $0x0
f0100fa6:	50                   	push   %eax
f0100fa7:	e8 96 20 00 00       	call   f0103042 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100fac:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fb1:	83 c4 10             	add    $0x10,%esp
f0100fb4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fb9:	77 15                	ja     f0100fd0 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fbb:	50                   	push   %eax
f0100fbc:	68 64 3a 10 f0       	push   $0xf0103a64
f0100fc1:	68 8f 00 00 00       	push   $0x8f
f0100fc6:	68 fc 40 10 f0       	push   $0xf01040fc
f0100fcb:	e8 bb f0 ff ff       	call   f010008b <_panic>
f0100fd0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100fd6:	83 ca 05             	or     $0x5,%edx
f0100fd9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages*sizeof(struct PageInfo));
f0100fdf:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100fe4:	c1 e0 03             	shl    $0x3,%eax
f0100fe7:	e8 78 f8 ff ff       	call   f0100864 <boot_alloc>
f0100fec:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
        memset(pages,0,npages*sizeof(struct PageInfo));
f0100ff1:	83 ec 04             	sub    $0x4,%esp
f0100ff4:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0100ffa:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101001:	52                   	push   %edx
f0101002:	6a 00                	push   $0x0
f0101004:	50                   	push   %eax
f0101005:	e8 38 20 00 00       	call   f0103042 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010100a:	e8 ce fb ff ff       	call   f0100bdd <page_init>
	check_page_free_list(1);
f010100f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101014:	e8 10 f9 ff ff       	call   f0100929 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101019:	83 c4 10             	add    $0x10,%esp
f010101c:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f0101023:	75 17                	jne    f010103c <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0101025:	83 ec 04             	sub    $0x4,%esp
f0101028:	68 b2 41 10 f0       	push   $0xf01041b2
f010102d:	68 62 02 00 00       	push   $0x262
f0101032:	68 fc 40 10 f0       	push   $0xf01040fc
f0101037:	e8 4f f0 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010103c:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101041:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101046:	eb 05                	jmp    f010104d <mem_init+0x120>
		++nfree;
f0101048:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010104b:	8b 00                	mov    (%eax),%eax
f010104d:	85 c0                	test   %eax,%eax
f010104f:	75 f7                	jne    f0101048 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101051:	83 ec 0c             	sub    $0xc,%esp
f0101054:	6a 00                	push   $0x0
f0101056:	e8 4b fc ff ff       	call   f0100ca6 <page_alloc>
f010105b:	89 c7                	mov    %eax,%edi
f010105d:	83 c4 10             	add    $0x10,%esp
f0101060:	85 c0                	test   %eax,%eax
f0101062:	75 19                	jne    f010107d <mem_init+0x150>
f0101064:	68 cd 41 10 f0       	push   $0xf01041cd
f0101069:	68 22 41 10 f0       	push   $0xf0104122
f010106e:	68 6a 02 00 00       	push   $0x26a
f0101073:	68 fc 40 10 f0       	push   $0xf01040fc
f0101078:	e8 0e f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010107d:	83 ec 0c             	sub    $0xc,%esp
f0101080:	6a 00                	push   $0x0
f0101082:	e8 1f fc ff ff       	call   f0100ca6 <page_alloc>
f0101087:	89 c6                	mov    %eax,%esi
f0101089:	83 c4 10             	add    $0x10,%esp
f010108c:	85 c0                	test   %eax,%eax
f010108e:	75 19                	jne    f01010a9 <mem_init+0x17c>
f0101090:	68 e3 41 10 f0       	push   $0xf01041e3
f0101095:	68 22 41 10 f0       	push   $0xf0104122
f010109a:	68 6b 02 00 00       	push   $0x26b
f010109f:	68 fc 40 10 f0       	push   $0xf01040fc
f01010a4:	e8 e2 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01010a9:	83 ec 0c             	sub    $0xc,%esp
f01010ac:	6a 00                	push   $0x0
f01010ae:	e8 f3 fb ff ff       	call   f0100ca6 <page_alloc>
f01010b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010b6:	83 c4 10             	add    $0x10,%esp
f01010b9:	85 c0                	test   %eax,%eax
f01010bb:	75 19                	jne    f01010d6 <mem_init+0x1a9>
f01010bd:	68 f9 41 10 f0       	push   $0xf01041f9
f01010c2:	68 22 41 10 f0       	push   $0xf0104122
f01010c7:	68 6c 02 00 00       	push   $0x26c
f01010cc:	68 fc 40 10 f0       	push   $0xf01040fc
f01010d1:	e8 b5 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010d6:	39 f7                	cmp    %esi,%edi
f01010d8:	75 19                	jne    f01010f3 <mem_init+0x1c6>
f01010da:	68 0f 42 10 f0       	push   $0xf010420f
f01010df:	68 22 41 10 f0       	push   $0xf0104122
f01010e4:	68 6f 02 00 00       	push   $0x26f
f01010e9:	68 fc 40 10 f0       	push   $0xf01040fc
f01010ee:	e8 98 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010f6:	39 c6                	cmp    %eax,%esi
f01010f8:	74 04                	je     f01010fe <mem_init+0x1d1>
f01010fa:	39 c7                	cmp    %eax,%edi
f01010fc:	75 19                	jne    f0101117 <mem_init+0x1ea>
f01010fe:	68 0c 3b 10 f0       	push   $0xf0103b0c
f0101103:	68 22 41 10 f0       	push   $0xf0104122
f0101108:	68 70 02 00 00       	push   $0x270
f010110d:	68 fc 40 10 f0       	push   $0xf01040fc
f0101112:	e8 74 ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101117:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010111d:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f0101123:	c1 e2 0c             	shl    $0xc,%edx
f0101126:	89 f8                	mov    %edi,%eax
f0101128:	29 c8                	sub    %ecx,%eax
f010112a:	c1 f8 03             	sar    $0x3,%eax
f010112d:	c1 e0 0c             	shl    $0xc,%eax
f0101130:	39 d0                	cmp    %edx,%eax
f0101132:	72 19                	jb     f010114d <mem_init+0x220>
f0101134:	68 21 42 10 f0       	push   $0xf0104221
f0101139:	68 22 41 10 f0       	push   $0xf0104122
f010113e:	68 71 02 00 00       	push   $0x271
f0101143:	68 fc 40 10 f0       	push   $0xf01040fc
f0101148:	e8 3e ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010114d:	89 f0                	mov    %esi,%eax
f010114f:	29 c8                	sub    %ecx,%eax
f0101151:	c1 f8 03             	sar    $0x3,%eax
f0101154:	c1 e0 0c             	shl    $0xc,%eax
f0101157:	39 c2                	cmp    %eax,%edx
f0101159:	77 19                	ja     f0101174 <mem_init+0x247>
f010115b:	68 3e 42 10 f0       	push   $0xf010423e
f0101160:	68 22 41 10 f0       	push   $0xf0104122
f0101165:	68 72 02 00 00       	push   $0x272
f010116a:	68 fc 40 10 f0       	push   $0xf01040fc
f010116f:	e8 17 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101174:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101177:	29 c8                	sub    %ecx,%eax
f0101179:	c1 f8 03             	sar    $0x3,%eax
f010117c:	c1 e0 0c             	shl    $0xc,%eax
f010117f:	39 c2                	cmp    %eax,%edx
f0101181:	77 19                	ja     f010119c <mem_init+0x26f>
f0101183:	68 5b 42 10 f0       	push   $0xf010425b
f0101188:	68 22 41 10 f0       	push   $0xf0104122
f010118d:	68 73 02 00 00       	push   $0x273
f0101192:	68 fc 40 10 f0       	push   $0xf01040fc
f0101197:	e8 ef ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010119c:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011a1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01011a4:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01011ab:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011ae:	83 ec 0c             	sub    $0xc,%esp
f01011b1:	6a 00                	push   $0x0
f01011b3:	e8 ee fa ff ff       	call   f0100ca6 <page_alloc>
f01011b8:	83 c4 10             	add    $0x10,%esp
f01011bb:	85 c0                	test   %eax,%eax
f01011bd:	74 19                	je     f01011d8 <mem_init+0x2ab>
f01011bf:	68 78 42 10 f0       	push   $0xf0104278
f01011c4:	68 22 41 10 f0       	push   $0xf0104122
f01011c9:	68 7a 02 00 00       	push   $0x27a
f01011ce:	68 fc 40 10 f0       	push   $0xf01040fc
f01011d3:	e8 b3 ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01011d8:	83 ec 0c             	sub    $0xc,%esp
f01011db:	57                   	push   %edi
f01011dc:	e8 35 fb ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f01011e1:	89 34 24             	mov    %esi,(%esp)
f01011e4:	e8 2d fb ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f01011e9:	83 c4 04             	add    $0x4,%esp
f01011ec:	ff 75 d4             	pushl  -0x2c(%ebp)
f01011ef:	e8 22 fb ff ff       	call   f0100d16 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01011fb:	e8 a6 fa ff ff       	call   f0100ca6 <page_alloc>
f0101200:	89 c6                	mov    %eax,%esi
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	85 c0                	test   %eax,%eax
f0101207:	75 19                	jne    f0101222 <mem_init+0x2f5>
f0101209:	68 cd 41 10 f0       	push   $0xf01041cd
f010120e:	68 22 41 10 f0       	push   $0xf0104122
f0101213:	68 81 02 00 00       	push   $0x281
f0101218:	68 fc 40 10 f0       	push   $0xf01040fc
f010121d:	e8 69 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101222:	83 ec 0c             	sub    $0xc,%esp
f0101225:	6a 00                	push   $0x0
f0101227:	e8 7a fa ff ff       	call   f0100ca6 <page_alloc>
f010122c:	89 c7                	mov    %eax,%edi
f010122e:	83 c4 10             	add    $0x10,%esp
f0101231:	85 c0                	test   %eax,%eax
f0101233:	75 19                	jne    f010124e <mem_init+0x321>
f0101235:	68 e3 41 10 f0       	push   $0xf01041e3
f010123a:	68 22 41 10 f0       	push   $0xf0104122
f010123f:	68 82 02 00 00       	push   $0x282
f0101244:	68 fc 40 10 f0       	push   $0xf01040fc
f0101249:	e8 3d ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010124e:	83 ec 0c             	sub    $0xc,%esp
f0101251:	6a 00                	push   $0x0
f0101253:	e8 4e fa ff ff       	call   f0100ca6 <page_alloc>
f0101258:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010125b:	83 c4 10             	add    $0x10,%esp
f010125e:	85 c0                	test   %eax,%eax
f0101260:	75 19                	jne    f010127b <mem_init+0x34e>
f0101262:	68 f9 41 10 f0       	push   $0xf01041f9
f0101267:	68 22 41 10 f0       	push   $0xf0104122
f010126c:	68 83 02 00 00       	push   $0x283
f0101271:	68 fc 40 10 f0       	push   $0xf01040fc
f0101276:	e8 10 ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010127b:	39 fe                	cmp    %edi,%esi
f010127d:	75 19                	jne    f0101298 <mem_init+0x36b>
f010127f:	68 0f 42 10 f0       	push   $0xf010420f
f0101284:	68 22 41 10 f0       	push   $0xf0104122
f0101289:	68 85 02 00 00       	push   $0x285
f010128e:	68 fc 40 10 f0       	push   $0xf01040fc
f0101293:	e8 f3 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101298:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010129b:	39 c6                	cmp    %eax,%esi
f010129d:	74 04                	je     f01012a3 <mem_init+0x376>
f010129f:	39 c7                	cmp    %eax,%edi
f01012a1:	75 19                	jne    f01012bc <mem_init+0x38f>
f01012a3:	68 0c 3b 10 f0       	push   $0xf0103b0c
f01012a8:	68 22 41 10 f0       	push   $0xf0104122
f01012ad:	68 86 02 00 00       	push   $0x286
f01012b2:	68 fc 40 10 f0       	push   $0xf01040fc
f01012b7:	e8 cf ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01012bc:	83 ec 0c             	sub    $0xc,%esp
f01012bf:	6a 00                	push   $0x0
f01012c1:	e8 e0 f9 ff ff       	call   f0100ca6 <page_alloc>
f01012c6:	83 c4 10             	add    $0x10,%esp
f01012c9:	85 c0                	test   %eax,%eax
f01012cb:	74 19                	je     f01012e6 <mem_init+0x3b9>
f01012cd:	68 78 42 10 f0       	push   $0xf0104278
f01012d2:	68 22 41 10 f0       	push   $0xf0104122
f01012d7:	68 87 02 00 00       	push   $0x287
f01012dc:	68 fc 40 10 f0       	push   $0xf01040fc
f01012e1:	e8 a5 ed ff ff       	call   f010008b <_panic>
f01012e6:	89 f0                	mov    %esi,%eax
f01012e8:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01012ee:	c1 f8 03             	sar    $0x3,%eax
f01012f1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012f4:	89 c2                	mov    %eax,%edx
f01012f6:	c1 ea 0c             	shr    $0xc,%edx
f01012f9:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01012ff:	72 12                	jb     f0101313 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101301:	50                   	push   %eax
f0101302:	68 7c 39 10 f0       	push   $0xf010397c
f0101307:	6a 52                	push   $0x52
f0101309:	68 08 41 10 f0       	push   $0xf0104108
f010130e:	e8 78 ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101313:	83 ec 04             	sub    $0x4,%esp
f0101316:	68 00 10 00 00       	push   $0x1000
f010131b:	6a 01                	push   $0x1
f010131d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101322:	50                   	push   %eax
f0101323:	e8 1a 1d 00 00       	call   f0103042 <memset>
	page_free(pp0);
f0101328:	89 34 24             	mov    %esi,(%esp)
f010132b:	e8 e6 f9 ff ff       	call   f0100d16 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101330:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101337:	e8 6a f9 ff ff       	call   f0100ca6 <page_alloc>
f010133c:	83 c4 10             	add    $0x10,%esp
f010133f:	85 c0                	test   %eax,%eax
f0101341:	75 19                	jne    f010135c <mem_init+0x42f>
f0101343:	68 87 42 10 f0       	push   $0xf0104287
f0101348:	68 22 41 10 f0       	push   $0xf0104122
f010134d:	68 8c 02 00 00       	push   $0x28c
f0101352:	68 fc 40 10 f0       	push   $0xf01040fc
f0101357:	e8 2f ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010135c:	39 c6                	cmp    %eax,%esi
f010135e:	74 19                	je     f0101379 <mem_init+0x44c>
f0101360:	68 a5 42 10 f0       	push   $0xf01042a5
f0101365:	68 22 41 10 f0       	push   $0xf0104122
f010136a:	68 8d 02 00 00       	push   $0x28d
f010136f:	68 fc 40 10 f0       	push   $0xf01040fc
f0101374:	e8 12 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101379:	89 f0                	mov    %esi,%eax
f010137b:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101381:	c1 f8 03             	sar    $0x3,%eax
f0101384:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101387:	89 c2                	mov    %eax,%edx
f0101389:	c1 ea 0c             	shr    $0xc,%edx
f010138c:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101392:	72 12                	jb     f01013a6 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101394:	50                   	push   %eax
f0101395:	68 7c 39 10 f0       	push   $0xf010397c
f010139a:	6a 52                	push   $0x52
f010139c:	68 08 41 10 f0       	push   $0xf0104108
f01013a1:	e8 e5 ec ff ff       	call   f010008b <_panic>
f01013a6:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01013ac:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013b2:	80 38 00             	cmpb   $0x0,(%eax)
f01013b5:	74 19                	je     f01013d0 <mem_init+0x4a3>
f01013b7:	68 b5 42 10 f0       	push   $0xf01042b5
f01013bc:	68 22 41 10 f0       	push   $0xf0104122
f01013c1:	68 90 02 00 00       	push   $0x290
f01013c6:	68 fc 40 10 f0       	push   $0xf01040fc
f01013cb:	e8 bb ec ff ff       	call   f010008b <_panic>
f01013d0:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013d3:	39 d0                	cmp    %edx,%eax
f01013d5:	75 db                	jne    f01013b2 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01013d7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013da:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f01013df:	83 ec 0c             	sub    $0xc,%esp
f01013e2:	56                   	push   %esi
f01013e3:	e8 2e f9 ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f01013e8:	89 3c 24             	mov    %edi,(%esp)
f01013eb:	e8 26 f9 ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f01013f0:	83 c4 04             	add    $0x4,%esp
f01013f3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013f6:	e8 1b f9 ff ff       	call   f0100d16 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01013fb:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101400:	83 c4 10             	add    $0x10,%esp
f0101403:	eb 05                	jmp    f010140a <mem_init+0x4dd>
		--nfree;
f0101405:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101408:	8b 00                	mov    (%eax),%eax
f010140a:	85 c0                	test   %eax,%eax
f010140c:	75 f7                	jne    f0101405 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f010140e:	85 db                	test   %ebx,%ebx
f0101410:	74 19                	je     f010142b <mem_init+0x4fe>
f0101412:	68 bf 42 10 f0       	push   $0xf01042bf
f0101417:	68 22 41 10 f0       	push   $0xf0104122
f010141c:	68 9d 02 00 00       	push   $0x29d
f0101421:	68 fc 40 10 f0       	push   $0xf01040fc
f0101426:	e8 60 ec ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010142b:	83 ec 0c             	sub    $0xc,%esp
f010142e:	68 2c 3b 10 f0       	push   $0xf0103b2c
f0101433:	e8 21 11 00 00       	call   f0102559 <cprintf>
	void *va;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101438:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010143f:	e8 62 f8 ff ff       	call   f0100ca6 <page_alloc>
f0101444:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101447:	83 c4 10             	add    $0x10,%esp
f010144a:	85 c0                	test   %eax,%eax
f010144c:	75 19                	jne    f0101467 <mem_init+0x53a>
f010144e:	68 cd 41 10 f0       	push   $0xf01041cd
f0101453:	68 22 41 10 f0       	push   $0xf0104122
f0101458:	68 f5 02 00 00       	push   $0x2f5
f010145d:	68 fc 40 10 f0       	push   $0xf01040fc
f0101462:	e8 24 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101467:	83 ec 0c             	sub    $0xc,%esp
f010146a:	6a 00                	push   $0x0
f010146c:	e8 35 f8 ff ff       	call   f0100ca6 <page_alloc>
f0101471:	89 c3                	mov    %eax,%ebx
f0101473:	83 c4 10             	add    $0x10,%esp
f0101476:	85 c0                	test   %eax,%eax
f0101478:	75 19                	jne    f0101493 <mem_init+0x566>
f010147a:	68 e3 41 10 f0       	push   $0xf01041e3
f010147f:	68 22 41 10 f0       	push   $0xf0104122
f0101484:	68 f6 02 00 00       	push   $0x2f6
f0101489:	68 fc 40 10 f0       	push   $0xf01040fc
f010148e:	e8 f8 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101493:	83 ec 0c             	sub    $0xc,%esp
f0101496:	6a 00                	push   $0x0
f0101498:	e8 09 f8 ff ff       	call   f0100ca6 <page_alloc>
f010149d:	89 c6                	mov    %eax,%esi
f010149f:	83 c4 10             	add    $0x10,%esp
f01014a2:	85 c0                	test   %eax,%eax
f01014a4:	75 19                	jne    f01014bf <mem_init+0x592>
f01014a6:	68 f9 41 10 f0       	push   $0xf01041f9
f01014ab:	68 22 41 10 f0       	push   $0xf0104122
f01014b0:	68 f7 02 00 00       	push   $0x2f7
f01014b5:	68 fc 40 10 f0       	push   $0xf01040fc
f01014ba:	e8 cc eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014bf:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01014c2:	75 19                	jne    f01014dd <mem_init+0x5b0>
f01014c4:	68 0f 42 10 f0       	push   $0xf010420f
f01014c9:	68 22 41 10 f0       	push   $0xf0104122
f01014ce:	68 fa 02 00 00       	push   $0x2fa
f01014d3:	68 fc 40 10 f0       	push   $0xf01040fc
f01014d8:	e8 ae eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014dd:	39 c3                	cmp    %eax,%ebx
f01014df:	74 05                	je     f01014e6 <mem_init+0x5b9>
f01014e1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01014e4:	75 19                	jne    f01014ff <mem_init+0x5d2>
f01014e6:	68 0c 3b 10 f0       	push   $0xf0103b0c
f01014eb:	68 22 41 10 f0       	push   $0xf0104122
f01014f0:	68 fb 02 00 00       	push   $0x2fb
f01014f5:	68 fc 40 10 f0       	push   $0xf01040fc
f01014fa:	e8 8c eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014ff:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101504:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101507:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010150e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101511:	83 ec 0c             	sub    $0xc,%esp
f0101514:	6a 00                	push   $0x0
f0101516:	e8 8b f7 ff ff       	call   f0100ca6 <page_alloc>
f010151b:	83 c4 10             	add    $0x10,%esp
f010151e:	85 c0                	test   %eax,%eax
f0101520:	74 19                	je     f010153b <mem_init+0x60e>
f0101522:	68 78 42 10 f0       	push   $0xf0104278
f0101527:	68 22 41 10 f0       	push   $0xf0104122
f010152c:	68 02 03 00 00       	push   $0x302
f0101531:	68 fc 40 10 f0       	push   $0xf01040fc
f0101536:	e8 50 eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010153b:	83 ec 04             	sub    $0x4,%esp
f010153e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101541:	50                   	push   %eax
f0101542:	6a 00                	push   $0x0
f0101544:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010154a:	e8 be f8 ff ff       	call   f0100e0d <page_lookup>
f010154f:	83 c4 10             	add    $0x10,%esp
f0101552:	85 c0                	test   %eax,%eax
f0101554:	74 19                	je     f010156f <mem_init+0x642>
f0101556:	68 4c 3b 10 f0       	push   $0xf0103b4c
f010155b:	68 22 41 10 f0       	push   $0xf0104122
f0101560:	68 05 03 00 00       	push   $0x305
f0101565:	68 fc 40 10 f0       	push   $0xf01040fc
f010156a:	e8 1c eb ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010156f:	6a 02                	push   $0x2
f0101571:	6a 00                	push   $0x0
f0101573:	53                   	push   %ebx
f0101574:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010157a:	e8 36 f9 ff ff       	call   f0100eb5 <page_insert>
f010157f:	83 c4 10             	add    $0x10,%esp
f0101582:	85 c0                	test   %eax,%eax
f0101584:	78 19                	js     f010159f <mem_init+0x672>
f0101586:	68 84 3b 10 f0       	push   $0xf0103b84
f010158b:	68 22 41 10 f0       	push   $0xf0104122
f0101590:	68 08 03 00 00       	push   $0x308
f0101595:	68 fc 40 10 f0       	push   $0xf01040fc
f010159a:	e8 ec ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010159f:	83 ec 0c             	sub    $0xc,%esp
f01015a2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015a5:	e8 6c f7 ff ff       	call   f0100d16 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01015aa:	6a 02                	push   $0x2
f01015ac:	6a 00                	push   $0x0
f01015ae:	53                   	push   %ebx
f01015af:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015b5:	e8 fb f8 ff ff       	call   f0100eb5 <page_insert>
f01015ba:	83 c4 20             	add    $0x20,%esp
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	74 19                	je     f01015da <mem_init+0x6ad>
f01015c1:	68 b4 3b 10 f0       	push   $0xf0103bb4
f01015c6:	68 22 41 10 f0       	push   $0xf0104122
f01015cb:	68 0c 03 00 00       	push   $0x30c
f01015d0:	68 fc 40 10 f0       	push   $0xf01040fc
f01015d5:	e8 b1 ea ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01015da:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015e0:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f01015e5:	89 c1                	mov    %eax,%ecx
f01015e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01015ea:	8b 17                	mov    (%edi),%edx
f01015ec:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01015f2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f5:	29 c8                	sub    %ecx,%eax
f01015f7:	c1 f8 03             	sar    $0x3,%eax
f01015fa:	c1 e0 0c             	shl    $0xc,%eax
f01015fd:	39 c2                	cmp    %eax,%edx
f01015ff:	74 19                	je     f010161a <mem_init+0x6ed>
f0101601:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101606:	68 22 41 10 f0       	push   $0xf0104122
f010160b:	68 0d 03 00 00       	push   $0x30d
f0101610:	68 fc 40 10 f0       	push   $0xf01040fc
f0101615:	e8 71 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010161a:	ba 00 00 00 00       	mov    $0x0,%edx
f010161f:	89 f8                	mov    %edi,%eax
f0101621:	e8 9f f2 ff ff       	call   f01008c5 <check_va2pa>
f0101626:	89 da                	mov    %ebx,%edx
f0101628:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010162b:	c1 fa 03             	sar    $0x3,%edx
f010162e:	c1 e2 0c             	shl    $0xc,%edx
f0101631:	39 d0                	cmp    %edx,%eax
f0101633:	74 19                	je     f010164e <mem_init+0x721>
f0101635:	68 0c 3c 10 f0       	push   $0xf0103c0c
f010163a:	68 22 41 10 f0       	push   $0xf0104122
f010163f:	68 0e 03 00 00       	push   $0x30e
f0101644:	68 fc 40 10 f0       	push   $0xf01040fc
f0101649:	e8 3d ea ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010164e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101653:	74 19                	je     f010166e <mem_init+0x741>
f0101655:	68 ca 42 10 f0       	push   $0xf01042ca
f010165a:	68 22 41 10 f0       	push   $0xf0104122
f010165f:	68 0f 03 00 00       	push   $0x30f
f0101664:	68 fc 40 10 f0       	push   $0xf01040fc
f0101669:	e8 1d ea ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010166e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101671:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101676:	74 19                	je     f0101691 <mem_init+0x764>
f0101678:	68 db 42 10 f0       	push   $0xf01042db
f010167d:	68 22 41 10 f0       	push   $0xf0104122
f0101682:	68 10 03 00 00       	push   $0x310
f0101687:	68 fc 40 10 f0       	push   $0xf01040fc
f010168c:	e8 fa e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101691:	6a 02                	push   $0x2
f0101693:	68 00 10 00 00       	push   $0x1000
f0101698:	56                   	push   %esi
f0101699:	57                   	push   %edi
f010169a:	e8 16 f8 ff ff       	call   f0100eb5 <page_insert>
f010169f:	83 c4 10             	add    $0x10,%esp
f01016a2:	85 c0                	test   %eax,%eax
f01016a4:	74 19                	je     f01016bf <mem_init+0x792>
f01016a6:	68 3c 3c 10 f0       	push   $0xf0103c3c
f01016ab:	68 22 41 10 f0       	push   $0xf0104122
f01016b0:	68 13 03 00 00       	push   $0x313
f01016b5:	68 fc 40 10 f0       	push   $0xf01040fc
f01016ba:	e8 cc e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01016bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01016c4:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01016c9:	e8 f7 f1 ff ff       	call   f01008c5 <check_va2pa>
f01016ce:	89 f2                	mov    %esi,%edx
f01016d0:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01016d6:	c1 fa 03             	sar    $0x3,%edx
f01016d9:	c1 e2 0c             	shl    $0xc,%edx
f01016dc:	39 d0                	cmp    %edx,%eax
f01016de:	74 19                	je     f01016f9 <mem_init+0x7cc>
f01016e0:	68 78 3c 10 f0       	push   $0xf0103c78
f01016e5:	68 22 41 10 f0       	push   $0xf0104122
f01016ea:	68 14 03 00 00       	push   $0x314
f01016ef:	68 fc 40 10 f0       	push   $0xf01040fc
f01016f4:	e8 92 e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01016f9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01016fe:	74 19                	je     f0101719 <mem_init+0x7ec>
f0101700:	68 ec 42 10 f0       	push   $0xf01042ec
f0101705:	68 22 41 10 f0       	push   $0xf0104122
f010170a:	68 15 03 00 00       	push   $0x315
f010170f:	68 fc 40 10 f0       	push   $0xf01040fc
f0101714:	e8 72 e9 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101719:	83 ec 0c             	sub    $0xc,%esp
f010171c:	6a 00                	push   $0x0
f010171e:	e8 83 f5 ff ff       	call   f0100ca6 <page_alloc>
f0101723:	83 c4 10             	add    $0x10,%esp
f0101726:	85 c0                	test   %eax,%eax
f0101728:	74 19                	je     f0101743 <mem_init+0x816>
f010172a:	68 78 42 10 f0       	push   $0xf0104278
f010172f:	68 22 41 10 f0       	push   $0xf0104122
f0101734:	68 18 03 00 00       	push   $0x318
f0101739:	68 fc 40 10 f0       	push   $0xf01040fc
f010173e:	e8 48 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101743:	6a 02                	push   $0x2
f0101745:	68 00 10 00 00       	push   $0x1000
f010174a:	56                   	push   %esi
f010174b:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101751:	e8 5f f7 ff ff       	call   f0100eb5 <page_insert>
f0101756:	83 c4 10             	add    $0x10,%esp
f0101759:	85 c0                	test   %eax,%eax
f010175b:	74 19                	je     f0101776 <mem_init+0x849>
f010175d:	68 3c 3c 10 f0       	push   $0xf0103c3c
f0101762:	68 22 41 10 f0       	push   $0xf0104122
f0101767:	68 1b 03 00 00       	push   $0x31b
f010176c:	68 fc 40 10 f0       	push   $0xf01040fc
f0101771:	e8 15 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101776:	ba 00 10 00 00       	mov    $0x1000,%edx
f010177b:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101780:	e8 40 f1 ff ff       	call   f01008c5 <check_va2pa>
f0101785:	89 f2                	mov    %esi,%edx
f0101787:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010178d:	c1 fa 03             	sar    $0x3,%edx
f0101790:	c1 e2 0c             	shl    $0xc,%edx
f0101793:	39 d0                	cmp    %edx,%eax
f0101795:	74 19                	je     f01017b0 <mem_init+0x883>
f0101797:	68 78 3c 10 f0       	push   $0xf0103c78
f010179c:	68 22 41 10 f0       	push   $0xf0104122
f01017a1:	68 1c 03 00 00       	push   $0x31c
f01017a6:	68 fc 40 10 f0       	push   $0xf01040fc
f01017ab:	e8 db e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017b0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017b5:	74 19                	je     f01017d0 <mem_init+0x8a3>
f01017b7:	68 ec 42 10 f0       	push   $0xf01042ec
f01017bc:	68 22 41 10 f0       	push   $0xf0104122
f01017c1:	68 1d 03 00 00       	push   $0x31d
f01017c6:	68 fc 40 10 f0       	push   $0xf01040fc
f01017cb:	e8 bb e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01017d0:	83 ec 0c             	sub    $0xc,%esp
f01017d3:	6a 00                	push   $0x0
f01017d5:	e8 cc f4 ff ff       	call   f0100ca6 <page_alloc>
f01017da:	83 c4 10             	add    $0x10,%esp
f01017dd:	85 c0                	test   %eax,%eax
f01017df:	74 19                	je     f01017fa <mem_init+0x8cd>
f01017e1:	68 78 42 10 f0       	push   $0xf0104278
f01017e6:	68 22 41 10 f0       	push   $0xf0104122
f01017eb:	68 21 03 00 00       	push   $0x321
f01017f0:	68 fc 40 10 f0       	push   $0xf01040fc
f01017f5:	e8 91 e8 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01017fa:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f0101800:	8b 02                	mov    (%edx),%eax
f0101802:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101807:	89 c1                	mov    %eax,%ecx
f0101809:	c1 e9 0c             	shr    $0xc,%ecx
f010180c:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0101812:	72 15                	jb     f0101829 <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101814:	50                   	push   %eax
f0101815:	68 7c 39 10 f0       	push   $0xf010397c
f010181a:	68 24 03 00 00       	push   $0x324
f010181f:	68 fc 40 10 f0       	push   $0xf01040fc
f0101824:	e8 62 e8 ff ff       	call   f010008b <_panic>
f0101829:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010182e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101831:	83 ec 04             	sub    $0x4,%esp
f0101834:	6a 00                	push   $0x0
f0101836:	68 00 10 00 00       	push   $0x1000
f010183b:	52                   	push   %edx
f010183c:	e8 39 f5 ff ff       	call   f0100d7a <pgdir_walk>
f0101841:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101844:	8d 51 04             	lea    0x4(%ecx),%edx
f0101847:	83 c4 10             	add    $0x10,%esp
f010184a:	39 d0                	cmp    %edx,%eax
f010184c:	74 19                	je     f0101867 <mem_init+0x93a>
f010184e:	68 a8 3c 10 f0       	push   $0xf0103ca8
f0101853:	68 22 41 10 f0       	push   $0xf0104122
f0101858:	68 25 03 00 00       	push   $0x325
f010185d:	68 fc 40 10 f0       	push   $0xf01040fc
f0101862:	e8 24 e8 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101867:	6a 06                	push   $0x6
f0101869:	68 00 10 00 00       	push   $0x1000
f010186e:	56                   	push   %esi
f010186f:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101875:	e8 3b f6 ff ff       	call   f0100eb5 <page_insert>
f010187a:	83 c4 10             	add    $0x10,%esp
f010187d:	85 c0                	test   %eax,%eax
f010187f:	74 19                	je     f010189a <mem_init+0x96d>
f0101881:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0101886:	68 22 41 10 f0       	push   $0xf0104122
f010188b:	68 28 03 00 00       	push   $0x328
f0101890:	68 fc 40 10 f0       	push   $0xf01040fc
f0101895:	e8 f1 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010189a:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f01018a0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018a5:	89 f8                	mov    %edi,%eax
f01018a7:	e8 19 f0 ff ff       	call   f01008c5 <check_va2pa>
f01018ac:	89 f2                	mov    %esi,%edx
f01018ae:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01018b4:	c1 fa 03             	sar    $0x3,%edx
f01018b7:	c1 e2 0c             	shl    $0xc,%edx
f01018ba:	39 d0                	cmp    %edx,%eax
f01018bc:	74 19                	je     f01018d7 <mem_init+0x9aa>
f01018be:	68 78 3c 10 f0       	push   $0xf0103c78
f01018c3:	68 22 41 10 f0       	push   $0xf0104122
f01018c8:	68 29 03 00 00       	push   $0x329
f01018cd:	68 fc 40 10 f0       	push   $0xf01040fc
f01018d2:	e8 b4 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018d7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018dc:	74 19                	je     f01018f7 <mem_init+0x9ca>
f01018de:	68 ec 42 10 f0       	push   $0xf01042ec
f01018e3:	68 22 41 10 f0       	push   $0xf0104122
f01018e8:	68 2a 03 00 00       	push   $0x32a
f01018ed:	68 fc 40 10 f0       	push   $0xf01040fc
f01018f2:	e8 94 e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01018f7:	83 ec 04             	sub    $0x4,%esp
f01018fa:	6a 00                	push   $0x0
f01018fc:	68 00 10 00 00       	push   $0x1000
f0101901:	57                   	push   %edi
f0101902:	e8 73 f4 ff ff       	call   f0100d7a <pgdir_walk>
f0101907:	83 c4 10             	add    $0x10,%esp
f010190a:	f6 00 04             	testb  $0x4,(%eax)
f010190d:	75 19                	jne    f0101928 <mem_init+0x9fb>
f010190f:	68 28 3d 10 f0       	push   $0xf0103d28
f0101914:	68 22 41 10 f0       	push   $0xf0104122
f0101919:	68 2b 03 00 00       	push   $0x32b
f010191e:	68 fc 40 10 f0       	push   $0xf01040fc
f0101923:	e8 63 e7 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101928:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010192d:	f6 00 04             	testb  $0x4,(%eax)
f0101930:	75 19                	jne    f010194b <mem_init+0xa1e>
f0101932:	68 fd 42 10 f0       	push   $0xf01042fd
f0101937:	68 22 41 10 f0       	push   $0xf0104122
f010193c:	68 2c 03 00 00       	push   $0x32c
f0101941:	68 fc 40 10 f0       	push   $0xf01040fc
f0101946:	e8 40 e7 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010194b:	6a 02                	push   $0x2
f010194d:	68 00 10 00 00       	push   $0x1000
f0101952:	56                   	push   %esi
f0101953:	50                   	push   %eax
f0101954:	e8 5c f5 ff ff       	call   f0100eb5 <page_insert>
f0101959:	83 c4 10             	add    $0x10,%esp
f010195c:	85 c0                	test   %eax,%eax
f010195e:	74 19                	je     f0101979 <mem_init+0xa4c>
f0101960:	68 3c 3c 10 f0       	push   $0xf0103c3c
f0101965:	68 22 41 10 f0       	push   $0xf0104122
f010196a:	68 2f 03 00 00       	push   $0x32f
f010196f:	68 fc 40 10 f0       	push   $0xf01040fc
f0101974:	e8 12 e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101979:	83 ec 04             	sub    $0x4,%esp
f010197c:	6a 00                	push   $0x0
f010197e:	68 00 10 00 00       	push   $0x1000
f0101983:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101989:	e8 ec f3 ff ff       	call   f0100d7a <pgdir_walk>
f010198e:	83 c4 10             	add    $0x10,%esp
f0101991:	f6 00 02             	testb  $0x2,(%eax)
f0101994:	75 19                	jne    f01019af <mem_init+0xa82>
f0101996:	68 5c 3d 10 f0       	push   $0xf0103d5c
f010199b:	68 22 41 10 f0       	push   $0xf0104122
f01019a0:	68 30 03 00 00       	push   $0x330
f01019a5:	68 fc 40 10 f0       	push   $0xf01040fc
f01019aa:	e8 dc e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01019af:	83 ec 04             	sub    $0x4,%esp
f01019b2:	6a 00                	push   $0x0
f01019b4:	68 00 10 00 00       	push   $0x1000
f01019b9:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019bf:	e8 b6 f3 ff ff       	call   f0100d7a <pgdir_walk>
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	f6 00 04             	testb  $0x4,(%eax)
f01019ca:	74 19                	je     f01019e5 <mem_init+0xab8>
f01019cc:	68 90 3d 10 f0       	push   $0xf0103d90
f01019d1:	68 22 41 10 f0       	push   $0xf0104122
f01019d6:	68 31 03 00 00       	push   $0x331
f01019db:	68 fc 40 10 f0       	push   $0xf01040fc
f01019e0:	e8 a6 e6 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f01019e5:	6a 02                	push   $0x2
f01019e7:	68 00 00 40 00       	push   $0x400000
f01019ec:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019ef:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019f5:	e8 bb f4 ff ff       	call   f0100eb5 <page_insert>
f01019fa:	83 c4 10             	add    $0x10,%esp
f01019fd:	85 c0                	test   %eax,%eax
f01019ff:	78 19                	js     f0101a1a <mem_init+0xaed>
f0101a01:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0101a06:	68 22 41 10 f0       	push   $0xf0104122
f0101a0b:	68 34 03 00 00       	push   $0x334
f0101a10:	68 fc 40 10 f0       	push   $0xf01040fc
f0101a15:	e8 71 e6 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a1a:	6a 02                	push   $0x2
f0101a1c:	68 00 10 00 00       	push   $0x1000
f0101a21:	53                   	push   %ebx
f0101a22:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a28:	e8 88 f4 ff ff       	call   f0100eb5 <page_insert>
f0101a2d:	83 c4 10             	add    $0x10,%esp
f0101a30:	85 c0                	test   %eax,%eax
f0101a32:	74 19                	je     f0101a4d <mem_init+0xb20>
f0101a34:	68 04 3e 10 f0       	push   $0xf0103e04
f0101a39:	68 22 41 10 f0       	push   $0xf0104122
f0101a3e:	68 37 03 00 00       	push   $0x337
f0101a43:	68 fc 40 10 f0       	push   $0xf01040fc
f0101a48:	e8 3e e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a4d:	83 ec 04             	sub    $0x4,%esp
f0101a50:	6a 00                	push   $0x0
f0101a52:	68 00 10 00 00       	push   $0x1000
f0101a57:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a5d:	e8 18 f3 ff ff       	call   f0100d7a <pgdir_walk>
f0101a62:	83 c4 10             	add    $0x10,%esp
f0101a65:	f6 00 04             	testb  $0x4,(%eax)
f0101a68:	74 19                	je     f0101a83 <mem_init+0xb56>
f0101a6a:	68 90 3d 10 f0       	push   $0xf0103d90
f0101a6f:	68 22 41 10 f0       	push   $0xf0104122
f0101a74:	68 38 03 00 00       	push   $0x338
f0101a79:	68 fc 40 10 f0       	push   $0xf01040fc
f0101a7e:	e8 08 e6 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101a83:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101a89:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a8e:	89 f8                	mov    %edi,%eax
f0101a90:	e8 30 ee ff ff       	call   f01008c5 <check_va2pa>
f0101a95:	89 c1                	mov    %eax,%ecx
f0101a97:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a9a:	89 d8                	mov    %ebx,%eax
f0101a9c:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101aa2:	c1 f8 03             	sar    $0x3,%eax
f0101aa5:	c1 e0 0c             	shl    $0xc,%eax
f0101aa8:	39 c1                	cmp    %eax,%ecx
f0101aaa:	74 19                	je     f0101ac5 <mem_init+0xb98>
f0101aac:	68 40 3e 10 f0       	push   $0xf0103e40
f0101ab1:	68 22 41 10 f0       	push   $0xf0104122
f0101ab6:	68 3b 03 00 00       	push   $0x33b
f0101abb:	68 fc 40 10 f0       	push   $0xf01040fc
f0101ac0:	e8 c6 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ac5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aca:	89 f8                	mov    %edi,%eax
f0101acc:	e8 f4 ed ff ff       	call   f01008c5 <check_va2pa>
f0101ad1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ad4:	74 19                	je     f0101aef <mem_init+0xbc2>
f0101ad6:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0101adb:	68 22 41 10 f0       	push   $0xf0104122
f0101ae0:	68 3c 03 00 00       	push   $0x33c
f0101ae5:	68 fc 40 10 f0       	push   $0xf01040fc
f0101aea:	e8 9c e5 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101aef:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101af4:	74 19                	je     f0101b0f <mem_init+0xbe2>
f0101af6:	68 13 43 10 f0       	push   $0xf0104313
f0101afb:	68 22 41 10 f0       	push   $0xf0104122
f0101b00:	68 3e 03 00 00       	push   $0x33e
f0101b05:	68 fc 40 10 f0       	push   $0xf01040fc
f0101b0a:	e8 7c e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b0f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b14:	74 19                	je     f0101b2f <mem_init+0xc02>
f0101b16:	68 24 43 10 f0       	push   $0xf0104324
f0101b1b:	68 22 41 10 f0       	push   $0xf0104122
f0101b20:	68 3f 03 00 00       	push   $0x33f
f0101b25:	68 fc 40 10 f0       	push   $0xf01040fc
f0101b2a:	e8 5c e5 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101b2f:	83 ec 0c             	sub    $0xc,%esp
f0101b32:	6a 00                	push   $0x0
f0101b34:	e8 6d f1 ff ff       	call   f0100ca6 <page_alloc>
f0101b39:	83 c4 10             	add    $0x10,%esp
f0101b3c:	39 c6                	cmp    %eax,%esi
f0101b3e:	75 04                	jne    f0101b44 <mem_init+0xc17>
f0101b40:	85 c0                	test   %eax,%eax
f0101b42:	75 19                	jne    f0101b5d <mem_init+0xc30>
f0101b44:	68 9c 3e 10 f0       	push   $0xf0103e9c
f0101b49:	68 22 41 10 f0       	push   $0xf0104122
f0101b4e:	68 42 03 00 00       	push   $0x342
f0101b53:	68 fc 40 10 f0       	push   $0xf01040fc
f0101b58:	e8 2e e5 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101b5d:	83 ec 08             	sub    $0x8,%esp
f0101b60:	6a 00                	push   $0x0
f0101b62:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b68:	e8 06 f3 ff ff       	call   f0100e73 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101b6d:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101b73:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b78:	89 f8                	mov    %edi,%eax
f0101b7a:	e8 46 ed ff ff       	call   f01008c5 <check_va2pa>
f0101b7f:	83 c4 10             	add    $0x10,%esp
f0101b82:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101b85:	74 19                	je     f0101ba0 <mem_init+0xc73>
f0101b87:	68 c0 3e 10 f0       	push   $0xf0103ec0
f0101b8c:	68 22 41 10 f0       	push   $0xf0104122
f0101b91:	68 46 03 00 00       	push   $0x346
f0101b96:	68 fc 40 10 f0       	push   $0xf01040fc
f0101b9b:	e8 eb e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ba0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba5:	89 f8                	mov    %edi,%eax
f0101ba7:	e8 19 ed ff ff       	call   f01008c5 <check_va2pa>
f0101bac:	89 da                	mov    %ebx,%edx
f0101bae:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101bb4:	c1 fa 03             	sar    $0x3,%edx
f0101bb7:	c1 e2 0c             	shl    $0xc,%edx
f0101bba:	39 d0                	cmp    %edx,%eax
f0101bbc:	74 19                	je     f0101bd7 <mem_init+0xcaa>
f0101bbe:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0101bc3:	68 22 41 10 f0       	push   $0xf0104122
f0101bc8:	68 47 03 00 00       	push   $0x347
f0101bcd:	68 fc 40 10 f0       	push   $0xf01040fc
f0101bd2:	e8 b4 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101bd7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bdc:	74 19                	je     f0101bf7 <mem_init+0xcca>
f0101bde:	68 ca 42 10 f0       	push   $0xf01042ca
f0101be3:	68 22 41 10 f0       	push   $0xf0104122
f0101be8:	68 48 03 00 00       	push   $0x348
f0101bed:	68 fc 40 10 f0       	push   $0xf01040fc
f0101bf2:	e8 94 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101bf7:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101bfc:	74 19                	je     f0101c17 <mem_init+0xcea>
f0101bfe:	68 24 43 10 f0       	push   $0xf0104324
f0101c03:	68 22 41 10 f0       	push   $0xf0104122
f0101c08:	68 49 03 00 00       	push   $0x349
f0101c0d:	68 fc 40 10 f0       	push   $0xf01040fc
f0101c12:	e8 74 e4 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c17:	6a 00                	push   $0x0
f0101c19:	68 00 10 00 00       	push   $0x1000
f0101c1e:	53                   	push   %ebx
f0101c1f:	57                   	push   %edi
f0101c20:	e8 90 f2 ff ff       	call   f0100eb5 <page_insert>
f0101c25:	83 c4 10             	add    $0x10,%esp
f0101c28:	85 c0                	test   %eax,%eax
f0101c2a:	74 19                	je     f0101c45 <mem_init+0xd18>
f0101c2c:	68 e4 3e 10 f0       	push   $0xf0103ee4
f0101c31:	68 22 41 10 f0       	push   $0xf0104122
f0101c36:	68 4c 03 00 00       	push   $0x34c
f0101c3b:	68 fc 40 10 f0       	push   $0xf01040fc
f0101c40:	e8 46 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101c45:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101c4a:	75 19                	jne    f0101c65 <mem_init+0xd38>
f0101c4c:	68 35 43 10 f0       	push   $0xf0104335
f0101c51:	68 22 41 10 f0       	push   $0xf0104122
f0101c56:	68 4d 03 00 00       	push   $0x34d
f0101c5b:	68 fc 40 10 f0       	push   $0xf01040fc
f0101c60:	e8 26 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101c65:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101c68:	74 19                	je     f0101c83 <mem_init+0xd56>
f0101c6a:	68 41 43 10 f0       	push   $0xf0104341
f0101c6f:	68 22 41 10 f0       	push   $0xf0104122
f0101c74:	68 4e 03 00 00       	push   $0x34e
f0101c79:	68 fc 40 10 f0       	push   $0xf01040fc
f0101c7e:	e8 08 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101c83:	83 ec 08             	sub    $0x8,%esp
f0101c86:	68 00 10 00 00       	push   $0x1000
f0101c8b:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101c91:	e8 dd f1 ff ff       	call   f0100e73 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c96:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101c9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ca1:	89 f8                	mov    %edi,%eax
f0101ca3:	e8 1d ec ff ff       	call   f01008c5 <check_va2pa>
f0101ca8:	83 c4 10             	add    $0x10,%esp
f0101cab:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cae:	74 19                	je     f0101cc9 <mem_init+0xd9c>
f0101cb0:	68 c0 3e 10 f0       	push   $0xf0103ec0
f0101cb5:	68 22 41 10 f0       	push   $0xf0104122
f0101cba:	68 52 03 00 00       	push   $0x352
f0101cbf:	68 fc 40 10 f0       	push   $0xf01040fc
f0101cc4:	e8 c2 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101cc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cce:	89 f8                	mov    %edi,%eax
f0101cd0:	e8 f0 eb ff ff       	call   f01008c5 <check_va2pa>
f0101cd5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cd8:	74 19                	je     f0101cf3 <mem_init+0xdc6>
f0101cda:	68 1c 3f 10 f0       	push   $0xf0103f1c
f0101cdf:	68 22 41 10 f0       	push   $0xf0104122
f0101ce4:	68 53 03 00 00       	push   $0x353
f0101ce9:	68 fc 40 10 f0       	push   $0xf01040fc
f0101cee:	e8 98 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101cf3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101cf8:	74 19                	je     f0101d13 <mem_init+0xde6>
f0101cfa:	68 56 43 10 f0       	push   $0xf0104356
f0101cff:	68 22 41 10 f0       	push   $0xf0104122
f0101d04:	68 54 03 00 00       	push   $0x354
f0101d09:	68 fc 40 10 f0       	push   $0xf01040fc
f0101d0e:	e8 78 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d13:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d18:	74 19                	je     f0101d33 <mem_init+0xe06>
f0101d1a:	68 24 43 10 f0       	push   $0xf0104324
f0101d1f:	68 22 41 10 f0       	push   $0xf0104122
f0101d24:	68 55 03 00 00       	push   $0x355
f0101d29:	68 fc 40 10 f0       	push   $0xf01040fc
f0101d2e:	e8 58 e3 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101d33:	83 ec 0c             	sub    $0xc,%esp
f0101d36:	6a 00                	push   $0x0
f0101d38:	e8 69 ef ff ff       	call   f0100ca6 <page_alloc>
f0101d3d:	83 c4 10             	add    $0x10,%esp
f0101d40:	85 c0                	test   %eax,%eax
f0101d42:	74 04                	je     f0101d48 <mem_init+0xe1b>
f0101d44:	39 c3                	cmp    %eax,%ebx
f0101d46:	74 19                	je     f0101d61 <mem_init+0xe34>
f0101d48:	68 44 3f 10 f0       	push   $0xf0103f44
f0101d4d:	68 22 41 10 f0       	push   $0xf0104122
f0101d52:	68 58 03 00 00       	push   $0x358
f0101d57:	68 fc 40 10 f0       	push   $0xf01040fc
f0101d5c:	e8 2a e3 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101d61:	83 ec 0c             	sub    $0xc,%esp
f0101d64:	6a 00                	push   $0x0
f0101d66:	e8 3b ef ff ff       	call   f0100ca6 <page_alloc>
f0101d6b:	83 c4 10             	add    $0x10,%esp
f0101d6e:	85 c0                	test   %eax,%eax
f0101d70:	74 19                	je     f0101d8b <mem_init+0xe5e>
f0101d72:	68 78 42 10 f0       	push   $0xf0104278
f0101d77:	68 22 41 10 f0       	push   $0xf0104122
f0101d7c:	68 5b 03 00 00       	push   $0x35b
f0101d81:	68 fc 40 10 f0       	push   $0xf01040fc
f0101d86:	e8 00 e3 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d8b:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101d91:	8b 11                	mov    (%ecx),%edx
f0101d93:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d9c:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101da2:	c1 f8 03             	sar    $0x3,%eax
f0101da5:	c1 e0 0c             	shl    $0xc,%eax
f0101da8:	39 c2                	cmp    %eax,%edx
f0101daa:	74 19                	je     f0101dc5 <mem_init+0xe98>
f0101dac:	68 e4 3b 10 f0       	push   $0xf0103be4
f0101db1:	68 22 41 10 f0       	push   $0xf0104122
f0101db6:	68 5e 03 00 00       	push   $0x35e
f0101dbb:	68 fc 40 10 f0       	push   $0xf01040fc
f0101dc0:	e8 c6 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101dc5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101dcb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dce:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101dd3:	74 19                	je     f0101dee <mem_init+0xec1>
f0101dd5:	68 db 42 10 f0       	push   $0xf01042db
f0101dda:	68 22 41 10 f0       	push   $0xf0104122
f0101ddf:	68 60 03 00 00       	push   $0x360
f0101de4:	68 fc 40 10 f0       	push   $0xf01040fc
f0101de9:	e8 9d e2 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101df7:	83 ec 0c             	sub    $0xc,%esp
f0101dfa:	50                   	push   %eax
f0101dfb:	e8 16 ef ff ff       	call   f0100d16 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e00:	83 c4 0c             	add    $0xc,%esp
f0101e03:	6a 01                	push   $0x1
f0101e05:	68 00 10 40 00       	push   $0x401000
f0101e0a:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101e10:	e8 65 ef ff ff       	call   f0100d7a <pgdir_walk>
f0101e15:	89 c7                	mov    %eax,%edi
f0101e17:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e1a:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101e1f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e22:	8b 40 04             	mov    0x4(%eax),%eax
f0101e25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e2a:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101e30:	89 c2                	mov    %eax,%edx
f0101e32:	c1 ea 0c             	shr    $0xc,%edx
f0101e35:	83 c4 10             	add    $0x10,%esp
f0101e38:	39 ca                	cmp    %ecx,%edx
f0101e3a:	72 15                	jb     f0101e51 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e3c:	50                   	push   %eax
f0101e3d:	68 7c 39 10 f0       	push   $0xf010397c
f0101e42:	68 67 03 00 00       	push   $0x367
f0101e47:	68 fc 40 10 f0       	push   $0xf01040fc
f0101e4c:	e8 3a e2 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101e51:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101e56:	39 c7                	cmp    %eax,%edi
f0101e58:	74 19                	je     f0101e73 <mem_init+0xf46>
f0101e5a:	68 67 43 10 f0       	push   $0xf0104367
f0101e5f:	68 22 41 10 f0       	push   $0xf0104122
f0101e64:	68 68 03 00 00       	push   $0x368
f0101e69:	68 fc 40 10 f0       	push   $0xf01040fc
f0101e6e:	e8 18 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101e73:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101e76:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101e7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e80:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e86:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101e8c:	c1 f8 03             	sar    $0x3,%eax
f0101e8f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e92:	89 c2                	mov    %eax,%edx
f0101e94:	c1 ea 0c             	shr    $0xc,%edx
f0101e97:	39 d1                	cmp    %edx,%ecx
f0101e99:	77 12                	ja     f0101ead <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e9b:	50                   	push   %eax
f0101e9c:	68 7c 39 10 f0       	push   $0xf010397c
f0101ea1:	6a 52                	push   $0x52
f0101ea3:	68 08 41 10 f0       	push   $0xf0104108
f0101ea8:	e8 de e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ead:	83 ec 04             	sub    $0x4,%esp
f0101eb0:	68 00 10 00 00       	push   $0x1000
f0101eb5:	68 ff 00 00 00       	push   $0xff
f0101eba:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ebf:	50                   	push   %eax
f0101ec0:	e8 7d 11 00 00       	call   f0103042 <memset>
	page_free(pp0);
f0101ec5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101ec8:	89 3c 24             	mov    %edi,(%esp)
f0101ecb:	e8 46 ee ff ff       	call   f0100d16 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ed0:	83 c4 0c             	add    $0xc,%esp
f0101ed3:	6a 01                	push   $0x1
f0101ed5:	6a 00                	push   $0x0
f0101ed7:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101edd:	e8 98 ee ff ff       	call   f0100d7a <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ee2:	89 fa                	mov    %edi,%edx
f0101ee4:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101eea:	c1 fa 03             	sar    $0x3,%edx
f0101eed:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ef0:	89 d0                	mov    %edx,%eax
f0101ef2:	c1 e8 0c             	shr    $0xc,%eax
f0101ef5:	83 c4 10             	add    $0x10,%esp
f0101ef8:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0101efe:	72 12                	jb     f0101f12 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f00:	52                   	push   %edx
f0101f01:	68 7c 39 10 f0       	push   $0xf010397c
f0101f06:	6a 52                	push   $0x52
f0101f08:	68 08 41 10 f0       	push   $0xf0104108
f0101f0d:	e8 79 e1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101f12:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f1b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f21:	f6 00 01             	testb  $0x1,(%eax)
f0101f24:	74 19                	je     f0101f3f <mem_init+0x1012>
f0101f26:	68 7f 43 10 f0       	push   $0xf010437f
f0101f2b:	68 22 41 10 f0       	push   $0xf0104122
f0101f30:	68 72 03 00 00       	push   $0x372
f0101f35:	68 fc 40 10 f0       	push   $0xf01040fc
f0101f3a:	e8 4c e1 ff ff       	call   f010008b <_panic>
f0101f3f:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101f42:	39 d0                	cmp    %edx,%eax
f0101f44:	75 db                	jne    f0101f21 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101f46:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101f4b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f54:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f5a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101f5d:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101f63:	83 ec 0c             	sub    $0xc,%esp
f0101f66:	50                   	push   %eax
f0101f67:	e8 aa ed ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f0101f6c:	89 1c 24             	mov    %ebx,(%esp)
f0101f6f:	e8 a2 ed ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f0101f74:	89 34 24             	mov    %esi,(%esp)
f0101f77:	e8 9a ed ff ff       	call   f0100d16 <page_free>

	cprintf("check_page() succeeded!\n");
f0101f7c:	c7 04 24 96 43 10 f0 	movl   $0xf0104396,(%esp)
f0101f83:	e8 d1 05 00 00       	call   f0102559 <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0101f88:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0101f8e:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101f93:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f96:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0101f9d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101fa2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101fa5:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101fab:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101fae:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101fb1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101fb6:	eb 55                	jmp    f010200d <mem_init+0x10e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101fb8:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0101fbe:	89 f0                	mov    %esi,%eax
f0101fc0:	e8 00 e9 ff ff       	call   f01008c5 <check_va2pa>
f0101fc5:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0101fcc:	77 15                	ja     f0101fe3 <mem_init+0x10b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101fce:	57                   	push   %edi
f0101fcf:	68 64 3a 10 f0       	push   $0xf0103a64
f0101fd4:	68 b5 02 00 00       	push   $0x2b5
f0101fd9:	68 fc 40 10 f0       	push   $0xf01040fc
f0101fde:	e8 a8 e0 ff ff       	call   f010008b <_panic>
f0101fe3:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0101fea:	39 d0                	cmp    %edx,%eax
f0101fec:	74 19                	je     f0102007 <mem_init+0x10da>
f0101fee:	68 68 3f 10 f0       	push   $0xf0103f68
f0101ff3:	68 22 41 10 f0       	push   $0xf0104122
f0101ff8:	68 b5 02 00 00       	push   $0x2b5
f0101ffd:	68 fc 40 10 f0       	push   $0xf01040fc
f0102002:	e8 84 e0 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102007:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010200d:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102010:	77 a6                	ja     f0101fb8 <mem_init+0x108b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102012:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102015:	c1 e7 0c             	shl    $0xc,%edi
f0102018:	bb 00 00 00 00       	mov    $0x0,%ebx
f010201d:	eb 30                	jmp    f010204f <mem_init+0x1122>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010201f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102025:	89 f0                	mov    %esi,%eax
f0102027:	e8 99 e8 ff ff       	call   f01008c5 <check_va2pa>
f010202c:	39 c3                	cmp    %eax,%ebx
f010202e:	74 19                	je     f0102049 <mem_init+0x111c>
f0102030:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0102035:	68 22 41 10 f0       	push   $0xf0104122
f010203a:	68 ba 02 00 00       	push   $0x2ba
f010203f:	68 fc 40 10 f0       	push   $0xf01040fc
f0102044:	e8 42 e0 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102049:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010204f:	39 fb                	cmp    %edi,%ebx
f0102051:	72 cc                	jb     f010201f <mem_init+0x10f2>
f0102053:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102058:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010205d:	89 da                	mov    %ebx,%edx
f010205f:	89 f0                	mov    %esi,%eax
f0102061:	e8 5f e8 ff ff       	call   f01008c5 <check_va2pa>
f0102066:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010206c:	77 19                	ja     f0102087 <mem_init+0x115a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010206e:	68 00 c0 10 f0       	push   $0xf010c000
f0102073:	68 64 3a 10 f0       	push   $0xf0103a64
f0102078:	68 be 02 00 00       	push   $0x2be
f010207d:	68 fc 40 10 f0       	push   $0xf01040fc
f0102082:	e8 04 e0 ff ff       	call   f010008b <_panic>
f0102087:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010208d:	39 d0                	cmp    %edx,%eax
f010208f:	74 19                	je     f01020aa <mem_init+0x117d>
f0102091:	68 c4 3f 10 f0       	push   $0xf0103fc4
f0102096:	68 22 41 10 f0       	push   $0xf0104122
f010209b:	68 be 02 00 00       	push   $0x2be
f01020a0:	68 fc 40 10 f0       	push   $0xf01040fc
f01020a5:	e8 e1 df ff ff       	call   f010008b <_panic>
f01020aa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01020b0:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01020b6:	75 a5                	jne    f010205d <mem_init+0x1130>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01020b8:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01020bd:	89 f0                	mov    %esi,%eax
f01020bf:	e8 01 e8 ff ff       	call   f01008c5 <check_va2pa>
f01020c4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020c7:	74 51                	je     f010211a <mem_init+0x11ed>
f01020c9:	68 0c 40 10 f0       	push   $0xf010400c
f01020ce:	68 22 41 10 f0       	push   $0xf0104122
f01020d3:	68 bf 02 00 00       	push   $0x2bf
f01020d8:	68 fc 40 10 f0       	push   $0xf01040fc
f01020dd:	e8 a9 df ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01020e2:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01020e7:	72 36                	jb     f010211f <mem_init+0x11f2>
f01020e9:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01020ee:	76 07                	jbe    f01020f7 <mem_init+0x11ca>
f01020f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01020f5:	75 28                	jne    f010211f <mem_init+0x11f2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01020f7:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01020fb:	0f 85 83 00 00 00    	jne    f0102184 <mem_init+0x1257>
f0102101:	68 af 43 10 f0       	push   $0xf01043af
f0102106:	68 22 41 10 f0       	push   $0xf0104122
f010210b:	68 c7 02 00 00       	push   $0x2c7
f0102110:	68 fc 40 10 f0       	push   $0xf01040fc
f0102115:	e8 71 df ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010211a:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010211f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102124:	76 3f                	jbe    f0102165 <mem_init+0x1238>
				assert(pgdir[i] & PTE_P);
f0102126:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102129:	f6 c2 01             	test   $0x1,%dl
f010212c:	75 19                	jne    f0102147 <mem_init+0x121a>
f010212e:	68 af 43 10 f0       	push   $0xf01043af
f0102133:	68 22 41 10 f0       	push   $0xf0104122
f0102138:	68 cb 02 00 00       	push   $0x2cb
f010213d:	68 fc 40 10 f0       	push   $0xf01040fc
f0102142:	e8 44 df ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102147:	f6 c2 02             	test   $0x2,%dl
f010214a:	75 38                	jne    f0102184 <mem_init+0x1257>
f010214c:	68 c0 43 10 f0       	push   $0xf01043c0
f0102151:	68 22 41 10 f0       	push   $0xf0104122
f0102156:	68 cc 02 00 00       	push   $0x2cc
f010215b:	68 fc 40 10 f0       	push   $0xf01040fc
f0102160:	e8 26 df ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102165:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102169:	74 19                	je     f0102184 <mem_init+0x1257>
f010216b:	68 d1 43 10 f0       	push   $0xf01043d1
f0102170:	68 22 41 10 f0       	push   $0xf0104122
f0102175:	68 ce 02 00 00       	push   $0x2ce
f010217a:	68 fc 40 10 f0       	push   $0xf01040fc
f010217f:	e8 07 df ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102184:	83 c0 01             	add    $0x1,%eax
f0102187:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010218c:	0f 86 50 ff ff ff    	jbe    f01020e2 <mem_init+0x11b5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102192:	83 ec 0c             	sub    $0xc,%esp
f0102195:	68 3c 40 10 f0       	push   $0xf010403c
f010219a:	e8 ba 03 00 00       	call   f0102559 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010219f:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021a4:	83 c4 10             	add    $0x10,%esp
f01021a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021ac:	77 15                	ja     f01021c3 <mem_init+0x1296>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ae:	50                   	push   %eax
f01021af:	68 64 3a 10 f0       	push   $0xf0103a64
f01021b4:	68 d0 00 00 00       	push   $0xd0
f01021b9:	68 fc 40 10 f0       	push   $0xf01040fc
f01021be:	e8 c8 de ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01021c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01021c8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01021cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01021d0:	e8 54 e7 ff ff       	call   f0100929 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01021d5:	0f 20 c0             	mov    %cr0,%eax
f01021d8:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01021db:	0d 23 00 05 80       	or     $0x80050023,%eax
f01021e0:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01021e3:	83 ec 0c             	sub    $0xc,%esp
f01021e6:	6a 00                	push   $0x0
f01021e8:	e8 b9 ea ff ff       	call   f0100ca6 <page_alloc>
f01021ed:	89 c3                	mov    %eax,%ebx
f01021ef:	83 c4 10             	add    $0x10,%esp
f01021f2:	85 c0                	test   %eax,%eax
f01021f4:	75 19                	jne    f010220f <mem_init+0x12e2>
f01021f6:	68 cd 41 10 f0       	push   $0xf01041cd
f01021fb:	68 22 41 10 f0       	push   $0xf0104122
f0102200:	68 8d 03 00 00       	push   $0x38d
f0102205:	68 fc 40 10 f0       	push   $0xf01040fc
f010220a:	e8 7c de ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010220f:	83 ec 0c             	sub    $0xc,%esp
f0102212:	6a 00                	push   $0x0
f0102214:	e8 8d ea ff ff       	call   f0100ca6 <page_alloc>
f0102219:	89 c7                	mov    %eax,%edi
f010221b:	83 c4 10             	add    $0x10,%esp
f010221e:	85 c0                	test   %eax,%eax
f0102220:	75 19                	jne    f010223b <mem_init+0x130e>
f0102222:	68 e3 41 10 f0       	push   $0xf01041e3
f0102227:	68 22 41 10 f0       	push   $0xf0104122
f010222c:	68 8e 03 00 00       	push   $0x38e
f0102231:	68 fc 40 10 f0       	push   $0xf01040fc
f0102236:	e8 50 de ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010223b:	83 ec 0c             	sub    $0xc,%esp
f010223e:	6a 00                	push   $0x0
f0102240:	e8 61 ea ff ff       	call   f0100ca6 <page_alloc>
f0102245:	89 c6                	mov    %eax,%esi
f0102247:	83 c4 10             	add    $0x10,%esp
f010224a:	85 c0                	test   %eax,%eax
f010224c:	75 19                	jne    f0102267 <mem_init+0x133a>
f010224e:	68 f9 41 10 f0       	push   $0xf01041f9
f0102253:	68 22 41 10 f0       	push   $0xf0104122
f0102258:	68 8f 03 00 00       	push   $0x38f
f010225d:	68 fc 40 10 f0       	push   $0xf01040fc
f0102262:	e8 24 de ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102267:	83 ec 0c             	sub    $0xc,%esp
f010226a:	53                   	push   %ebx
f010226b:	e8 a6 ea ff ff       	call   f0100d16 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102270:	89 f8                	mov    %edi,%eax
f0102272:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102278:	c1 f8 03             	sar    $0x3,%eax
f010227b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010227e:	89 c2                	mov    %eax,%edx
f0102280:	c1 ea 0c             	shr    $0xc,%edx
f0102283:	83 c4 10             	add    $0x10,%esp
f0102286:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f010228c:	72 12                	jb     f01022a0 <mem_init+0x1373>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010228e:	50                   	push   %eax
f010228f:	68 7c 39 10 f0       	push   $0xf010397c
f0102294:	6a 52                	push   $0x52
f0102296:	68 08 41 10 f0       	push   $0xf0104108
f010229b:	e8 eb dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01022a0:	83 ec 04             	sub    $0x4,%esp
f01022a3:	68 00 10 00 00       	push   $0x1000
f01022a8:	6a 01                	push   $0x1
f01022aa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022af:	50                   	push   %eax
f01022b0:	e8 8d 0d 00 00       	call   f0103042 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022b5:	89 f0                	mov    %esi,%eax
f01022b7:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01022bd:	c1 f8 03             	sar    $0x3,%eax
f01022c0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022c3:	89 c2                	mov    %eax,%edx
f01022c5:	c1 ea 0c             	shr    $0xc,%edx
f01022c8:	83 c4 10             	add    $0x10,%esp
f01022cb:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01022d1:	72 12                	jb     f01022e5 <mem_init+0x13b8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022d3:	50                   	push   %eax
f01022d4:	68 7c 39 10 f0       	push   $0xf010397c
f01022d9:	6a 52                	push   $0x52
f01022db:	68 08 41 10 f0       	push   $0xf0104108
f01022e0:	e8 a6 dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01022e5:	83 ec 04             	sub    $0x4,%esp
f01022e8:	68 00 10 00 00       	push   $0x1000
f01022ed:	6a 02                	push   $0x2
f01022ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022f4:	50                   	push   %eax
f01022f5:	e8 48 0d 00 00       	call   f0103042 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01022fa:	6a 02                	push   $0x2
f01022fc:	68 00 10 00 00       	push   $0x1000
f0102301:	57                   	push   %edi
f0102302:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102308:	e8 a8 eb ff ff       	call   f0100eb5 <page_insert>
	assert(pp1->pp_ref == 1);
f010230d:	83 c4 20             	add    $0x20,%esp
f0102310:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102315:	74 19                	je     f0102330 <mem_init+0x1403>
f0102317:	68 ca 42 10 f0       	push   $0xf01042ca
f010231c:	68 22 41 10 f0       	push   $0xf0104122
f0102321:	68 94 03 00 00       	push   $0x394
f0102326:	68 fc 40 10 f0       	push   $0xf01040fc
f010232b:	e8 5b dd ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102330:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102337:	01 01 01 
f010233a:	74 19                	je     f0102355 <mem_init+0x1428>
f010233c:	68 5c 40 10 f0       	push   $0xf010405c
f0102341:	68 22 41 10 f0       	push   $0xf0104122
f0102346:	68 95 03 00 00       	push   $0x395
f010234b:	68 fc 40 10 f0       	push   $0xf01040fc
f0102350:	e8 36 dd ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102355:	6a 02                	push   $0x2
f0102357:	68 00 10 00 00       	push   $0x1000
f010235c:	56                   	push   %esi
f010235d:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102363:	e8 4d eb ff ff       	call   f0100eb5 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102368:	83 c4 10             	add    $0x10,%esp
f010236b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102372:	02 02 02 
f0102375:	74 19                	je     f0102390 <mem_init+0x1463>
f0102377:	68 80 40 10 f0       	push   $0xf0104080
f010237c:	68 22 41 10 f0       	push   $0xf0104122
f0102381:	68 97 03 00 00       	push   $0x397
f0102386:	68 fc 40 10 f0       	push   $0xf01040fc
f010238b:	e8 fb dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102390:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102395:	74 19                	je     f01023b0 <mem_init+0x1483>
f0102397:	68 ec 42 10 f0       	push   $0xf01042ec
f010239c:	68 22 41 10 f0       	push   $0xf0104122
f01023a1:	68 98 03 00 00       	push   $0x398
f01023a6:	68 fc 40 10 f0       	push   $0xf01040fc
f01023ab:	e8 db dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01023b0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01023b5:	74 19                	je     f01023d0 <mem_init+0x14a3>
f01023b7:	68 56 43 10 f0       	push   $0xf0104356
f01023bc:	68 22 41 10 f0       	push   $0xf0104122
f01023c1:	68 99 03 00 00       	push   $0x399
f01023c6:	68 fc 40 10 f0       	push   $0xf01040fc
f01023cb:	e8 bb dc ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01023d0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01023d7:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023da:	89 f0                	mov    %esi,%eax
f01023dc:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01023e2:	c1 f8 03             	sar    $0x3,%eax
f01023e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023e8:	89 c2                	mov    %eax,%edx
f01023ea:	c1 ea 0c             	shr    $0xc,%edx
f01023ed:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01023f3:	72 12                	jb     f0102407 <mem_init+0x14da>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023f5:	50                   	push   %eax
f01023f6:	68 7c 39 10 f0       	push   $0xf010397c
f01023fb:	6a 52                	push   $0x52
f01023fd:	68 08 41 10 f0       	push   $0xf0104108
f0102402:	e8 84 dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102407:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010240e:	03 03 03 
f0102411:	74 19                	je     f010242c <mem_init+0x14ff>
f0102413:	68 a4 40 10 f0       	push   $0xf01040a4
f0102418:	68 22 41 10 f0       	push   $0xf0104122
f010241d:	68 9b 03 00 00       	push   $0x39b
f0102422:	68 fc 40 10 f0       	push   $0xf01040fc
f0102427:	e8 5f dc ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010242c:	83 ec 08             	sub    $0x8,%esp
f010242f:	68 00 10 00 00       	push   $0x1000
f0102434:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010243a:	e8 34 ea ff ff       	call   f0100e73 <page_remove>
	assert(pp2->pp_ref == 0);
f010243f:	83 c4 10             	add    $0x10,%esp
f0102442:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102447:	74 19                	je     f0102462 <mem_init+0x1535>
f0102449:	68 24 43 10 f0       	push   $0xf0104324
f010244e:	68 22 41 10 f0       	push   $0xf0104122
f0102453:	68 9d 03 00 00       	push   $0x39d
f0102458:	68 fc 40 10 f0       	push   $0xf01040fc
f010245d:	e8 29 dc ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102462:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0102468:	8b 11                	mov    (%ecx),%edx
f010246a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102470:	89 d8                	mov    %ebx,%eax
f0102472:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102478:	c1 f8 03             	sar    $0x3,%eax
f010247b:	c1 e0 0c             	shl    $0xc,%eax
f010247e:	39 c2                	cmp    %eax,%edx
f0102480:	74 19                	je     f010249b <mem_init+0x156e>
f0102482:	68 e4 3b 10 f0       	push   $0xf0103be4
f0102487:	68 22 41 10 f0       	push   $0xf0104122
f010248c:	68 a0 03 00 00       	push   $0x3a0
f0102491:	68 fc 40 10 f0       	push   $0xf01040fc
f0102496:	e8 f0 db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010249b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01024a1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024a6:	74 19                	je     f01024c1 <mem_init+0x1594>
f01024a8:	68 db 42 10 f0       	push   $0xf01042db
f01024ad:	68 22 41 10 f0       	push   $0xf0104122
f01024b2:	68 a2 03 00 00       	push   $0x3a2
f01024b7:	68 fc 40 10 f0       	push   $0xf01040fc
f01024bc:	e8 ca db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01024c1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01024c7:	83 ec 0c             	sub    $0xc,%esp
f01024ca:	53                   	push   %ebx
f01024cb:	e8 46 e8 ff ff       	call   f0100d16 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01024d0:	c7 04 24 d0 40 10 f0 	movl   $0xf01040d0,(%esp)
f01024d7:	e8 7d 00 00 00       	call   f0102559 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01024dc:	83 c4 10             	add    $0x10,%esp
f01024df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01024e2:	5b                   	pop    %ebx
f01024e3:	5e                   	pop    %esi
f01024e4:	5f                   	pop    %edi
f01024e5:	5d                   	pop    %ebp
f01024e6:	c3                   	ret    

f01024e7 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01024e7:	55                   	push   %ebp
f01024e8:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01024ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01024ed:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01024f0:	5d                   	pop    %ebp
f01024f1:	c3                   	ret    

f01024f2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01024f2:	55                   	push   %ebp
f01024f3:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01024f5:	ba 70 00 00 00       	mov    $0x70,%edx
f01024fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01024fd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01024fe:	ba 71 00 00 00       	mov    $0x71,%edx
f0102503:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102504:	0f b6 c0             	movzbl %al,%eax
}
f0102507:	5d                   	pop    %ebp
f0102508:	c3                   	ret    

f0102509 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102509:	55                   	push   %ebp
f010250a:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010250c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102511:	8b 45 08             	mov    0x8(%ebp),%eax
f0102514:	ee                   	out    %al,(%dx)
f0102515:	ba 71 00 00 00       	mov    $0x71,%edx
f010251a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010251d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010251e:	5d                   	pop    %ebp
f010251f:	c3                   	ret    

f0102520 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102520:	55                   	push   %ebp
f0102521:	89 e5                	mov    %esp,%ebp
f0102523:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102526:	ff 75 08             	pushl  0x8(%ebp)
f0102529:	e8 d2 e0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f010252e:	83 c4 10             	add    $0x10,%esp
f0102531:	c9                   	leave  
f0102532:	c3                   	ret    

f0102533 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102533:	55                   	push   %ebp
f0102534:	89 e5                	mov    %esp,%ebp
f0102536:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102539:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102540:	ff 75 0c             	pushl  0xc(%ebp)
f0102543:	ff 75 08             	pushl  0x8(%ebp)
f0102546:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102549:	50                   	push   %eax
f010254a:	68 20 25 10 f0       	push   $0xf0102520
f010254f:	e8 c9 03 00 00       	call   f010291d <vprintfmt>
	return cnt;
}
f0102554:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102557:	c9                   	leave  
f0102558:	c3                   	ret    

f0102559 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102559:	55                   	push   %ebp
f010255a:	89 e5                	mov    %esp,%ebp
f010255c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010255f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102562:	50                   	push   %eax
f0102563:	ff 75 08             	pushl  0x8(%ebp)
f0102566:	e8 c8 ff ff ff       	call   f0102533 <vcprintf>
	va_end(ap);

	return cnt;
}
f010256b:	c9                   	leave  
f010256c:	c3                   	ret    

f010256d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010256d:	55                   	push   %ebp
f010256e:	89 e5                	mov    %esp,%ebp
f0102570:	57                   	push   %edi
f0102571:	56                   	push   %esi
f0102572:	53                   	push   %ebx
f0102573:	83 ec 14             	sub    $0x14,%esp
f0102576:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102579:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010257c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010257f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102582:	8b 1a                	mov    (%edx),%ebx
f0102584:	8b 01                	mov    (%ecx),%eax
f0102586:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102589:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102590:	eb 7f                	jmp    f0102611 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102592:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102595:	01 d8                	add    %ebx,%eax
f0102597:	89 c6                	mov    %eax,%esi
f0102599:	c1 ee 1f             	shr    $0x1f,%esi
f010259c:	01 c6                	add    %eax,%esi
f010259e:	d1 fe                	sar    %esi
f01025a0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01025a3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01025a6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01025a9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01025ab:	eb 03                	jmp    f01025b0 <stab_binsearch+0x43>
			m--;
f01025ad:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01025b0:	39 c3                	cmp    %eax,%ebx
f01025b2:	7f 0d                	jg     f01025c1 <stab_binsearch+0x54>
f01025b4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01025b8:	83 ea 0c             	sub    $0xc,%edx
f01025bb:	39 f9                	cmp    %edi,%ecx
f01025bd:	75 ee                	jne    f01025ad <stab_binsearch+0x40>
f01025bf:	eb 05                	jmp    f01025c6 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01025c1:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01025c4:	eb 4b                	jmp    f0102611 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01025c6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01025c9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01025cc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01025d0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01025d3:	76 11                	jbe    f01025e6 <stab_binsearch+0x79>
			*region_left = m;
f01025d5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01025d8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01025da:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01025dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01025e4:	eb 2b                	jmp    f0102611 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01025e6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01025e9:	73 14                	jae    f01025ff <stab_binsearch+0x92>
			*region_right = m - 1;
f01025eb:	83 e8 01             	sub    $0x1,%eax
f01025ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01025f1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01025f4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01025f6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01025fd:	eb 12                	jmp    f0102611 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01025ff:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102602:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102604:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102608:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010260a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102611:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102614:	0f 8e 78 ff ff ff    	jle    f0102592 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010261a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010261e:	75 0f                	jne    f010262f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102620:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102623:	8b 00                	mov    (%eax),%eax
f0102625:	83 e8 01             	sub    $0x1,%eax
f0102628:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010262b:	89 06                	mov    %eax,(%esi)
f010262d:	eb 2c                	jmp    f010265b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010262f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102632:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102634:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102637:	8b 0e                	mov    (%esi),%ecx
f0102639:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010263c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010263f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102642:	eb 03                	jmp    f0102647 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102644:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102647:	39 c8                	cmp    %ecx,%eax
f0102649:	7e 0b                	jle    f0102656 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010264b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010264f:	83 ea 0c             	sub    $0xc,%edx
f0102652:	39 df                	cmp    %ebx,%edi
f0102654:	75 ee                	jne    f0102644 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102656:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102659:	89 06                	mov    %eax,(%esi)
	}
}
f010265b:	83 c4 14             	add    $0x14,%esp
f010265e:	5b                   	pop    %ebx
f010265f:	5e                   	pop    %esi
f0102660:	5f                   	pop    %edi
f0102661:	5d                   	pop    %ebp
f0102662:	c3                   	ret    

f0102663 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102663:	55                   	push   %ebp
f0102664:	89 e5                	mov    %esp,%ebp
f0102666:	57                   	push   %edi
f0102667:	56                   	push   %esi
f0102668:	53                   	push   %ebx
f0102669:	83 ec 1c             	sub    $0x1c,%esp
f010266c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010266f:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102672:	c7 06 df 43 10 f0    	movl   $0xf01043df,(%esi)
	info->eip_line = 0;
f0102678:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010267f:	c7 46 08 df 43 10 f0 	movl   $0xf01043df,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102686:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010268d:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102690:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102697:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010269d:	76 11                	jbe    f01026b0 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010269f:	b8 44 ba 10 f0       	mov    $0xf010ba44,%eax
f01026a4:	3d 21 9d 10 f0       	cmp    $0xf0109d21,%eax
f01026a9:	77 19                	ja     f01026c4 <debuginfo_eip+0x61>
f01026ab:	e9 62 01 00 00       	jmp    f0102812 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01026b0:	83 ec 04             	sub    $0x4,%esp
f01026b3:	68 e9 43 10 f0       	push   $0xf01043e9
f01026b8:	6a 7f                	push   $0x7f
f01026ba:	68 f6 43 10 f0       	push   $0xf01043f6
f01026bf:	e8 c7 d9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01026c4:	80 3d 43 ba 10 f0 00 	cmpb   $0x0,0xf010ba43
f01026cb:	0f 85 48 01 00 00    	jne    f0102819 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01026d1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01026d8:	b8 20 9d 10 f0       	mov    $0xf0109d20,%eax
f01026dd:	2d 14 46 10 f0       	sub    $0xf0104614,%eax
f01026e2:	c1 f8 02             	sar    $0x2,%eax
f01026e5:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01026eb:	83 e8 01             	sub    $0x1,%eax
f01026ee:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01026f1:	83 ec 08             	sub    $0x8,%esp
f01026f4:	57                   	push   %edi
f01026f5:	6a 64                	push   $0x64
f01026f7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01026fa:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01026fd:	b8 14 46 10 f0       	mov    $0xf0104614,%eax
f0102702:	e8 66 fe ff ff       	call   f010256d <stab_binsearch>
	if (lfile == 0)
f0102707:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010270a:	83 c4 10             	add    $0x10,%esp
f010270d:	85 c0                	test   %eax,%eax
f010270f:	0f 84 0b 01 00 00    	je     f0102820 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102715:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102718:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010271b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010271e:	83 ec 08             	sub    $0x8,%esp
f0102721:	57                   	push   %edi
f0102722:	6a 24                	push   $0x24
f0102724:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102727:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010272a:	b8 14 46 10 f0       	mov    $0xf0104614,%eax
f010272f:	e8 39 fe ff ff       	call   f010256d <stab_binsearch>

	if (lfun <= rfun) {
f0102734:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102737:	83 c4 10             	add    $0x10,%esp
f010273a:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010273d:	7f 31                	jg     f0102770 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010273f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102742:	c1 e0 02             	shl    $0x2,%eax
f0102745:	8d 90 14 46 10 f0    	lea    -0xfefb9ec(%eax),%edx
f010274b:	8b 88 14 46 10 f0    	mov    -0xfefb9ec(%eax),%ecx
f0102751:	b8 44 ba 10 f0       	mov    $0xf010ba44,%eax
f0102756:	2d 21 9d 10 f0       	sub    $0xf0109d21,%eax
f010275b:	39 c1                	cmp    %eax,%ecx
f010275d:	73 09                	jae    f0102768 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010275f:	81 c1 21 9d 10 f0    	add    $0xf0109d21,%ecx
f0102765:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102768:	8b 42 08             	mov    0x8(%edx),%eax
f010276b:	89 46 10             	mov    %eax,0x10(%esi)
f010276e:	eb 06                	jmp    f0102776 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102770:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102773:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102776:	83 ec 08             	sub    $0x8,%esp
f0102779:	6a 3a                	push   $0x3a
f010277b:	ff 76 08             	pushl  0x8(%esi)
f010277e:	e8 a3 08 00 00       	call   f0103026 <strfind>
f0102783:	2b 46 08             	sub    0x8(%esi),%eax
f0102786:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102789:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010278c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010278f:	8d 04 85 14 46 10 f0 	lea    -0xfefb9ec(,%eax,4),%eax
f0102796:	83 c4 10             	add    $0x10,%esp
f0102799:	eb 06                	jmp    f01027a1 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010279b:	83 eb 01             	sub    $0x1,%ebx
f010279e:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01027a1:	39 fb                	cmp    %edi,%ebx
f01027a3:	7c 34                	jl     f01027d9 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01027a5:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01027a9:	80 fa 84             	cmp    $0x84,%dl
f01027ac:	74 0b                	je     f01027b9 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01027ae:	80 fa 64             	cmp    $0x64,%dl
f01027b1:	75 e8                	jne    f010279b <debuginfo_eip+0x138>
f01027b3:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01027b7:	74 e2                	je     f010279b <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01027b9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01027bc:	8b 14 85 14 46 10 f0 	mov    -0xfefb9ec(,%eax,4),%edx
f01027c3:	b8 44 ba 10 f0       	mov    $0xf010ba44,%eax
f01027c8:	2d 21 9d 10 f0       	sub    $0xf0109d21,%eax
f01027cd:	39 c2                	cmp    %eax,%edx
f01027cf:	73 08                	jae    f01027d9 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01027d1:	81 c2 21 9d 10 f0    	add    $0xf0109d21,%edx
f01027d7:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01027d9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01027dc:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01027df:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01027e4:	39 cb                	cmp    %ecx,%ebx
f01027e6:	7d 44                	jge    f010282c <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f01027e8:	8d 53 01             	lea    0x1(%ebx),%edx
f01027eb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01027ee:	8d 04 85 14 46 10 f0 	lea    -0xfefb9ec(,%eax,4),%eax
f01027f5:	eb 07                	jmp    f01027fe <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01027f7:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01027fb:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01027fe:	39 ca                	cmp    %ecx,%edx
f0102800:	74 25                	je     f0102827 <debuginfo_eip+0x1c4>
f0102802:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102805:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0102809:	74 ec                	je     f01027f7 <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010280b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102810:	eb 1a                	jmp    f010282c <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102812:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102817:	eb 13                	jmp    f010282c <debuginfo_eip+0x1c9>
f0102819:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010281e:	eb 0c                	jmp    f010282c <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102820:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102825:	eb 05                	jmp    f010282c <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102827:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010282c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010282f:	5b                   	pop    %ebx
f0102830:	5e                   	pop    %esi
f0102831:	5f                   	pop    %edi
f0102832:	5d                   	pop    %ebp
f0102833:	c3                   	ret    

f0102834 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102834:	55                   	push   %ebp
f0102835:	89 e5                	mov    %esp,%ebp
f0102837:	57                   	push   %edi
f0102838:	56                   	push   %esi
f0102839:	53                   	push   %ebx
f010283a:	83 ec 1c             	sub    $0x1c,%esp
f010283d:	89 c7                	mov    %eax,%edi
f010283f:	89 d6                	mov    %edx,%esi
f0102841:	8b 45 08             	mov    0x8(%ebp),%eax
f0102844:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102847:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010284a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010284d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102850:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102855:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102858:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010285b:	39 d3                	cmp    %edx,%ebx
f010285d:	72 05                	jb     f0102864 <printnum+0x30>
f010285f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102862:	77 45                	ja     f01028a9 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102864:	83 ec 0c             	sub    $0xc,%esp
f0102867:	ff 75 18             	pushl  0x18(%ebp)
f010286a:	8b 45 14             	mov    0x14(%ebp),%eax
f010286d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102870:	53                   	push   %ebx
f0102871:	ff 75 10             	pushl  0x10(%ebp)
f0102874:	83 ec 08             	sub    $0x8,%esp
f0102877:	ff 75 e4             	pushl  -0x1c(%ebp)
f010287a:	ff 75 e0             	pushl  -0x20(%ebp)
f010287d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102880:	ff 75 d8             	pushl  -0x28(%ebp)
f0102883:	e8 c8 09 00 00       	call   f0103250 <__udivdi3>
f0102888:	83 c4 18             	add    $0x18,%esp
f010288b:	52                   	push   %edx
f010288c:	50                   	push   %eax
f010288d:	89 f2                	mov    %esi,%edx
f010288f:	89 f8                	mov    %edi,%eax
f0102891:	e8 9e ff ff ff       	call   f0102834 <printnum>
f0102896:	83 c4 20             	add    $0x20,%esp
f0102899:	eb 18                	jmp    f01028b3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010289b:	83 ec 08             	sub    $0x8,%esp
f010289e:	56                   	push   %esi
f010289f:	ff 75 18             	pushl  0x18(%ebp)
f01028a2:	ff d7                	call   *%edi
f01028a4:	83 c4 10             	add    $0x10,%esp
f01028a7:	eb 03                	jmp    f01028ac <printnum+0x78>
f01028a9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01028ac:	83 eb 01             	sub    $0x1,%ebx
f01028af:	85 db                	test   %ebx,%ebx
f01028b1:	7f e8                	jg     f010289b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01028b3:	83 ec 08             	sub    $0x8,%esp
f01028b6:	56                   	push   %esi
f01028b7:	83 ec 04             	sub    $0x4,%esp
f01028ba:	ff 75 e4             	pushl  -0x1c(%ebp)
f01028bd:	ff 75 e0             	pushl  -0x20(%ebp)
f01028c0:	ff 75 dc             	pushl  -0x24(%ebp)
f01028c3:	ff 75 d8             	pushl  -0x28(%ebp)
f01028c6:	e8 b5 0a 00 00       	call   f0103380 <__umoddi3>
f01028cb:	83 c4 14             	add    $0x14,%esp
f01028ce:	0f be 80 04 44 10 f0 	movsbl -0xfefbbfc(%eax),%eax
f01028d5:	50                   	push   %eax
f01028d6:	ff d7                	call   *%edi
}
f01028d8:	83 c4 10             	add    $0x10,%esp
f01028db:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028de:	5b                   	pop    %ebx
f01028df:	5e                   	pop    %esi
f01028e0:	5f                   	pop    %edi
f01028e1:	5d                   	pop    %ebp
f01028e2:	c3                   	ret    

f01028e3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01028e3:	55                   	push   %ebp
f01028e4:	89 e5                	mov    %esp,%ebp
f01028e6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01028e9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01028ed:	8b 10                	mov    (%eax),%edx
f01028ef:	3b 50 04             	cmp    0x4(%eax),%edx
f01028f2:	73 0a                	jae    f01028fe <sprintputch+0x1b>
		*b->buf++ = ch;
f01028f4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01028f7:	89 08                	mov    %ecx,(%eax)
f01028f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01028fc:	88 02                	mov    %al,(%edx)
}
f01028fe:	5d                   	pop    %ebp
f01028ff:	c3                   	ret    

f0102900 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102900:	55                   	push   %ebp
f0102901:	89 e5                	mov    %esp,%ebp
f0102903:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102906:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102909:	50                   	push   %eax
f010290a:	ff 75 10             	pushl  0x10(%ebp)
f010290d:	ff 75 0c             	pushl  0xc(%ebp)
f0102910:	ff 75 08             	pushl  0x8(%ebp)
f0102913:	e8 05 00 00 00       	call   f010291d <vprintfmt>
	va_end(ap);
}
f0102918:	83 c4 10             	add    $0x10,%esp
f010291b:	c9                   	leave  
f010291c:	c3                   	ret    

f010291d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010291d:	55                   	push   %ebp
f010291e:	89 e5                	mov    %esp,%ebp
f0102920:	57                   	push   %edi
f0102921:	56                   	push   %esi
f0102922:	53                   	push   %ebx
f0102923:	83 ec 2c             	sub    $0x2c,%esp
f0102926:	8b 75 08             	mov    0x8(%ebp),%esi
f0102929:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010292c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010292f:	eb 12                	jmp    f0102943 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102931:	85 c0                	test   %eax,%eax
f0102933:	0f 84 42 04 00 00    	je     f0102d7b <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0102939:	83 ec 08             	sub    $0x8,%esp
f010293c:	53                   	push   %ebx
f010293d:	50                   	push   %eax
f010293e:	ff d6                	call   *%esi
f0102940:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102943:	83 c7 01             	add    $0x1,%edi
f0102946:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010294a:	83 f8 25             	cmp    $0x25,%eax
f010294d:	75 e2                	jne    f0102931 <vprintfmt+0x14>
f010294f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102953:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010295a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102961:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102968:	b9 00 00 00 00       	mov    $0x0,%ecx
f010296d:	eb 07                	jmp    f0102976 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010296f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102972:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102976:	8d 47 01             	lea    0x1(%edi),%eax
f0102979:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010297c:	0f b6 07             	movzbl (%edi),%eax
f010297f:	0f b6 d0             	movzbl %al,%edx
f0102982:	83 e8 23             	sub    $0x23,%eax
f0102985:	3c 55                	cmp    $0x55,%al
f0102987:	0f 87 d3 03 00 00    	ja     f0102d60 <vprintfmt+0x443>
f010298d:	0f b6 c0             	movzbl %al,%eax
f0102990:	ff 24 85 90 44 10 f0 	jmp    *-0xfefbb70(,%eax,4)
f0102997:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010299a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010299e:	eb d6                	jmp    f0102976 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01029a8:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01029ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01029ae:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01029b2:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01029b5:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01029b8:	83 f9 09             	cmp    $0x9,%ecx
f01029bb:	77 3f                	ja     f01029fc <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01029bd:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01029c0:	eb e9                	jmp    f01029ab <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01029c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01029c5:	8b 00                	mov    (%eax),%eax
f01029c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01029ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01029cd:	8d 40 04             	lea    0x4(%eax),%eax
f01029d0:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01029d6:	eb 2a                	jmp    f0102a02 <vprintfmt+0xe5>
f01029d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029db:	85 c0                	test   %eax,%eax
f01029dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01029e2:	0f 49 d0             	cmovns %eax,%edx
f01029e5:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029eb:	eb 89                	jmp    f0102976 <vprintfmt+0x59>
f01029ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01029f0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01029f7:	e9 7a ff ff ff       	jmp    f0102976 <vprintfmt+0x59>
f01029fc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01029ff:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102a02:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102a06:	0f 89 6a ff ff ff    	jns    f0102976 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102a0c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a0f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102a12:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102a19:	e9 58 ff ff ff       	jmp    f0102976 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102a1e:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a21:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102a24:	e9 4d ff ff ff       	jmp    f0102976 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102a29:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a2c:	8d 78 04             	lea    0x4(%eax),%edi
f0102a2f:	83 ec 08             	sub    $0x8,%esp
f0102a32:	53                   	push   %ebx
f0102a33:	ff 30                	pushl  (%eax)
f0102a35:	ff d6                	call   *%esi
			break;
f0102a37:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102a3a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102a40:	e9 fe fe ff ff       	jmp    f0102943 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a45:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a48:	8d 78 04             	lea    0x4(%eax),%edi
f0102a4b:	8b 00                	mov    (%eax),%eax
f0102a4d:	99                   	cltd   
f0102a4e:	31 d0                	xor    %edx,%eax
f0102a50:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102a52:	83 f8 06             	cmp    $0x6,%eax
f0102a55:	7f 0b                	jg     f0102a62 <vprintfmt+0x145>
f0102a57:	8b 14 85 e8 45 10 f0 	mov    -0xfefba18(,%eax,4),%edx
f0102a5e:	85 d2                	test   %edx,%edx
f0102a60:	75 1b                	jne    f0102a7d <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102a62:	50                   	push   %eax
f0102a63:	68 1c 44 10 f0       	push   $0xf010441c
f0102a68:	53                   	push   %ebx
f0102a69:	56                   	push   %esi
f0102a6a:	e8 91 fe ff ff       	call   f0102900 <printfmt>
f0102a6f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a72:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102a78:	e9 c6 fe ff ff       	jmp    f0102943 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102a7d:	52                   	push   %edx
f0102a7e:	68 34 41 10 f0       	push   $0xf0104134
f0102a83:	53                   	push   %ebx
f0102a84:	56                   	push   %esi
f0102a85:	e8 76 fe ff ff       	call   f0102900 <printfmt>
f0102a8a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a8d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a93:	e9 ab fe ff ff       	jmp    f0102943 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102a98:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a9b:	83 c0 04             	add    $0x4,%eax
f0102a9e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102aa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aa4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102aa6:	85 ff                	test   %edi,%edi
f0102aa8:	b8 15 44 10 f0       	mov    $0xf0104415,%eax
f0102aad:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102ab0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ab4:	0f 8e 94 00 00 00    	jle    f0102b4e <vprintfmt+0x231>
f0102aba:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102abe:	0f 84 98 00 00 00    	je     f0102b5c <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ac4:	83 ec 08             	sub    $0x8,%esp
f0102ac7:	ff 75 d0             	pushl  -0x30(%ebp)
f0102aca:	57                   	push   %edi
f0102acb:	e8 0c 04 00 00       	call   f0102edc <strnlen>
f0102ad0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ad3:	29 c1                	sub    %eax,%ecx
f0102ad5:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102ad8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102adb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102adf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ae2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ae5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ae7:	eb 0f                	jmp    f0102af8 <vprintfmt+0x1db>
					putch(padc, putdat);
f0102ae9:	83 ec 08             	sub    $0x8,%esp
f0102aec:	53                   	push   %ebx
f0102aed:	ff 75 e0             	pushl  -0x20(%ebp)
f0102af0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102af2:	83 ef 01             	sub    $0x1,%edi
f0102af5:	83 c4 10             	add    $0x10,%esp
f0102af8:	85 ff                	test   %edi,%edi
f0102afa:	7f ed                	jg     f0102ae9 <vprintfmt+0x1cc>
f0102afc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102aff:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102b02:	85 c9                	test   %ecx,%ecx
f0102b04:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b09:	0f 49 c1             	cmovns %ecx,%eax
f0102b0c:	29 c1                	sub    %eax,%ecx
f0102b0e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b11:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b14:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b17:	89 cb                	mov    %ecx,%ebx
f0102b19:	eb 4d                	jmp    f0102b68 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102b1b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102b1f:	74 1b                	je     f0102b3c <vprintfmt+0x21f>
f0102b21:	0f be c0             	movsbl %al,%eax
f0102b24:	83 e8 20             	sub    $0x20,%eax
f0102b27:	83 f8 5e             	cmp    $0x5e,%eax
f0102b2a:	76 10                	jbe    f0102b3c <vprintfmt+0x21f>
					putch('?', putdat);
f0102b2c:	83 ec 08             	sub    $0x8,%esp
f0102b2f:	ff 75 0c             	pushl  0xc(%ebp)
f0102b32:	6a 3f                	push   $0x3f
f0102b34:	ff 55 08             	call   *0x8(%ebp)
f0102b37:	83 c4 10             	add    $0x10,%esp
f0102b3a:	eb 0d                	jmp    f0102b49 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102b3c:	83 ec 08             	sub    $0x8,%esp
f0102b3f:	ff 75 0c             	pushl  0xc(%ebp)
f0102b42:	52                   	push   %edx
f0102b43:	ff 55 08             	call   *0x8(%ebp)
f0102b46:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102b49:	83 eb 01             	sub    $0x1,%ebx
f0102b4c:	eb 1a                	jmp    f0102b68 <vprintfmt+0x24b>
f0102b4e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b51:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b54:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b57:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102b5a:	eb 0c                	jmp    f0102b68 <vprintfmt+0x24b>
f0102b5c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b5f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b62:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b65:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102b68:	83 c7 01             	add    $0x1,%edi
f0102b6b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b6f:	0f be d0             	movsbl %al,%edx
f0102b72:	85 d2                	test   %edx,%edx
f0102b74:	74 23                	je     f0102b99 <vprintfmt+0x27c>
f0102b76:	85 f6                	test   %esi,%esi
f0102b78:	78 a1                	js     f0102b1b <vprintfmt+0x1fe>
f0102b7a:	83 ee 01             	sub    $0x1,%esi
f0102b7d:	79 9c                	jns    f0102b1b <vprintfmt+0x1fe>
f0102b7f:	89 df                	mov    %ebx,%edi
f0102b81:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b87:	eb 18                	jmp    f0102ba1 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102b89:	83 ec 08             	sub    $0x8,%esp
f0102b8c:	53                   	push   %ebx
f0102b8d:	6a 20                	push   $0x20
f0102b8f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102b91:	83 ef 01             	sub    $0x1,%edi
f0102b94:	83 c4 10             	add    $0x10,%esp
f0102b97:	eb 08                	jmp    f0102ba1 <vprintfmt+0x284>
f0102b99:	89 df                	mov    %ebx,%edi
f0102b9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ba1:	85 ff                	test   %edi,%edi
f0102ba3:	7f e4                	jg     f0102b89 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ba5:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102ba8:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bae:	e9 90 fd ff ff       	jmp    f0102943 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102bb3:	83 f9 01             	cmp    $0x1,%ecx
f0102bb6:	7e 19                	jle    f0102bd1 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102bb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bbb:	8b 50 04             	mov    0x4(%eax),%edx
f0102bbe:	8b 00                	mov    (%eax),%eax
f0102bc0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bc3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102bc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bc9:	8d 40 08             	lea    0x8(%eax),%eax
f0102bcc:	89 45 14             	mov    %eax,0x14(%ebp)
f0102bcf:	eb 38                	jmp    f0102c09 <vprintfmt+0x2ec>
	else if (lflag)
f0102bd1:	85 c9                	test   %ecx,%ecx
f0102bd3:	74 1b                	je     f0102bf0 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102bd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bd8:	8b 00                	mov    (%eax),%eax
f0102bda:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bdd:	89 c1                	mov    %eax,%ecx
f0102bdf:	c1 f9 1f             	sar    $0x1f,%ecx
f0102be2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102be5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be8:	8d 40 04             	lea    0x4(%eax),%eax
f0102beb:	89 45 14             	mov    %eax,0x14(%ebp)
f0102bee:	eb 19                	jmp    f0102c09 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102bf0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bf3:	8b 00                	mov    (%eax),%eax
f0102bf5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bf8:	89 c1                	mov    %eax,%ecx
f0102bfa:	c1 f9 1f             	sar    $0x1f,%ecx
f0102bfd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102c00:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c03:	8d 40 04             	lea    0x4(%eax),%eax
f0102c06:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102c09:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c0c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102c0f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102c14:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102c18:	0f 89 0e 01 00 00    	jns    f0102d2c <vprintfmt+0x40f>
				putch('-', putdat);
f0102c1e:	83 ec 08             	sub    $0x8,%esp
f0102c21:	53                   	push   %ebx
f0102c22:	6a 2d                	push   $0x2d
f0102c24:	ff d6                	call   *%esi
				num = -(long long) num;
f0102c26:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c29:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102c2c:	f7 da                	neg    %edx
f0102c2e:	83 d1 00             	adc    $0x0,%ecx
f0102c31:	f7 d9                	neg    %ecx
f0102c33:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102c36:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c3b:	e9 ec 00 00 00       	jmp    f0102d2c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102c40:	83 f9 01             	cmp    $0x1,%ecx
f0102c43:	7e 18                	jle    f0102c5d <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102c45:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c48:	8b 10                	mov    (%eax),%edx
f0102c4a:	8b 48 04             	mov    0x4(%eax),%ecx
f0102c4d:	8d 40 08             	lea    0x8(%eax),%eax
f0102c50:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102c53:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c58:	e9 cf 00 00 00       	jmp    f0102d2c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102c5d:	85 c9                	test   %ecx,%ecx
f0102c5f:	74 1a                	je     f0102c7b <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102c61:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c64:	8b 10                	mov    (%eax),%edx
f0102c66:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c6b:	8d 40 04             	lea    0x4(%eax),%eax
f0102c6e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102c71:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c76:	e9 b1 00 00 00       	jmp    f0102d2c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102c7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7e:	8b 10                	mov    (%eax),%edx
f0102c80:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c85:	8d 40 04             	lea    0x4(%eax),%eax
f0102c88:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102c8b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c90:	e9 97 00 00 00       	jmp    f0102d2c <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102c95:	83 ec 08             	sub    $0x8,%esp
f0102c98:	53                   	push   %ebx
f0102c99:	6a 58                	push   $0x58
f0102c9b:	ff d6                	call   *%esi
			putch('X', putdat);
f0102c9d:	83 c4 08             	add    $0x8,%esp
f0102ca0:	53                   	push   %ebx
f0102ca1:	6a 58                	push   $0x58
f0102ca3:	ff d6                	call   *%esi
			putch('X', putdat);
f0102ca5:	83 c4 08             	add    $0x8,%esp
f0102ca8:	53                   	push   %ebx
f0102ca9:	6a 58                	push   $0x58
f0102cab:	ff d6                	call   *%esi
			break;
f0102cad:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102cb3:	e9 8b fc ff ff       	jmp    f0102943 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102cb8:	83 ec 08             	sub    $0x8,%esp
f0102cbb:	53                   	push   %ebx
f0102cbc:	6a 30                	push   $0x30
f0102cbe:	ff d6                	call   *%esi
			putch('x', putdat);
f0102cc0:	83 c4 08             	add    $0x8,%esp
f0102cc3:	53                   	push   %ebx
f0102cc4:	6a 78                	push   $0x78
f0102cc6:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102cc8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ccb:	8b 10                	mov    (%eax),%edx
f0102ccd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102cd2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102cd5:	8d 40 04             	lea    0x4(%eax),%eax
f0102cd8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102cdb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102ce0:	eb 4a                	jmp    f0102d2c <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ce2:	83 f9 01             	cmp    $0x1,%ecx
f0102ce5:	7e 15                	jle    f0102cfc <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102ce7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cea:	8b 10                	mov    (%eax),%edx
f0102cec:	8b 48 04             	mov    0x4(%eax),%ecx
f0102cef:	8d 40 08             	lea    0x8(%eax),%eax
f0102cf2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102cf5:	b8 10 00 00 00       	mov    $0x10,%eax
f0102cfa:	eb 30                	jmp    f0102d2c <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102cfc:	85 c9                	test   %ecx,%ecx
f0102cfe:	74 17                	je     f0102d17 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102d00:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d03:	8b 10                	mov    (%eax),%edx
f0102d05:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d0a:	8d 40 04             	lea    0x4(%eax),%eax
f0102d0d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102d10:	b8 10 00 00 00       	mov    $0x10,%eax
f0102d15:	eb 15                	jmp    f0102d2c <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102d17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d1a:	8b 10                	mov    (%eax),%edx
f0102d1c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d21:	8d 40 04             	lea    0x4(%eax),%eax
f0102d24:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102d27:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102d2c:	83 ec 0c             	sub    $0xc,%esp
f0102d2f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102d33:	57                   	push   %edi
f0102d34:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d37:	50                   	push   %eax
f0102d38:	51                   	push   %ecx
f0102d39:	52                   	push   %edx
f0102d3a:	89 da                	mov    %ebx,%edx
f0102d3c:	89 f0                	mov    %esi,%eax
f0102d3e:	e8 f1 fa ff ff       	call   f0102834 <printnum>
			break;
f0102d43:	83 c4 20             	add    $0x20,%esp
f0102d46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d49:	e9 f5 fb ff ff       	jmp    f0102943 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102d4e:	83 ec 08             	sub    $0x8,%esp
f0102d51:	53                   	push   %ebx
f0102d52:	52                   	push   %edx
f0102d53:	ff d6                	call   *%esi
			break;
f0102d55:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102d5b:	e9 e3 fb ff ff       	jmp    f0102943 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102d60:	83 ec 08             	sub    $0x8,%esp
f0102d63:	53                   	push   %ebx
f0102d64:	6a 25                	push   $0x25
f0102d66:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102d68:	83 c4 10             	add    $0x10,%esp
f0102d6b:	eb 03                	jmp    f0102d70 <vprintfmt+0x453>
f0102d6d:	83 ef 01             	sub    $0x1,%edi
f0102d70:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102d74:	75 f7                	jne    f0102d6d <vprintfmt+0x450>
f0102d76:	e9 c8 fb ff ff       	jmp    f0102943 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102d7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d7e:	5b                   	pop    %ebx
f0102d7f:	5e                   	pop    %esi
f0102d80:	5f                   	pop    %edi
f0102d81:	5d                   	pop    %ebp
f0102d82:	c3                   	ret    

f0102d83 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102d83:	55                   	push   %ebp
f0102d84:	89 e5                	mov    %esp,%ebp
f0102d86:	83 ec 18             	sub    $0x18,%esp
f0102d89:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d8c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102d8f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102d92:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102d96:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102d99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102da0:	85 c0                	test   %eax,%eax
f0102da2:	74 26                	je     f0102dca <vsnprintf+0x47>
f0102da4:	85 d2                	test   %edx,%edx
f0102da6:	7e 22                	jle    f0102dca <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102da8:	ff 75 14             	pushl  0x14(%ebp)
f0102dab:	ff 75 10             	pushl  0x10(%ebp)
f0102dae:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102db1:	50                   	push   %eax
f0102db2:	68 e3 28 10 f0       	push   $0xf01028e3
f0102db7:	e8 61 fb ff ff       	call   f010291d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102dbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102dbf:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102dc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102dc5:	83 c4 10             	add    $0x10,%esp
f0102dc8:	eb 05                	jmp    f0102dcf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102dca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102dcf:	c9                   	leave  
f0102dd0:	c3                   	ret    

f0102dd1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102dd1:	55                   	push   %ebp
f0102dd2:	89 e5                	mov    %esp,%ebp
f0102dd4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102dd7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102dda:	50                   	push   %eax
f0102ddb:	ff 75 10             	pushl  0x10(%ebp)
f0102dde:	ff 75 0c             	pushl  0xc(%ebp)
f0102de1:	ff 75 08             	pushl  0x8(%ebp)
f0102de4:	e8 9a ff ff ff       	call   f0102d83 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102de9:	c9                   	leave  
f0102dea:	c3                   	ret    

f0102deb <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102deb:	55                   	push   %ebp
f0102dec:	89 e5                	mov    %esp,%ebp
f0102dee:	57                   	push   %edi
f0102def:	56                   	push   %esi
f0102df0:	53                   	push   %ebx
f0102df1:	83 ec 0c             	sub    $0xc,%esp
f0102df4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102df7:	85 c0                	test   %eax,%eax
f0102df9:	74 11                	je     f0102e0c <readline+0x21>
		cprintf("%s", prompt);
f0102dfb:	83 ec 08             	sub    $0x8,%esp
f0102dfe:	50                   	push   %eax
f0102dff:	68 34 41 10 f0       	push   $0xf0104134
f0102e04:	e8 50 f7 ff ff       	call   f0102559 <cprintf>
f0102e09:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102e0c:	83 ec 0c             	sub    $0xc,%esp
f0102e0f:	6a 00                	push   $0x0
f0102e11:	e8 0b d8 ff ff       	call   f0100621 <iscons>
f0102e16:	89 c7                	mov    %eax,%edi
f0102e18:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102e1b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102e20:	e8 eb d7 ff ff       	call   f0100610 <getchar>
f0102e25:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102e27:	85 c0                	test   %eax,%eax
f0102e29:	79 18                	jns    f0102e43 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102e2b:	83 ec 08             	sub    $0x8,%esp
f0102e2e:	50                   	push   %eax
f0102e2f:	68 04 46 10 f0       	push   $0xf0104604
f0102e34:	e8 20 f7 ff ff       	call   f0102559 <cprintf>
			return NULL;
f0102e39:	83 c4 10             	add    $0x10,%esp
f0102e3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e41:	eb 79                	jmp    f0102ebc <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102e43:	83 f8 08             	cmp    $0x8,%eax
f0102e46:	0f 94 c2             	sete   %dl
f0102e49:	83 f8 7f             	cmp    $0x7f,%eax
f0102e4c:	0f 94 c0             	sete   %al
f0102e4f:	08 c2                	or     %al,%dl
f0102e51:	74 1a                	je     f0102e6d <readline+0x82>
f0102e53:	85 f6                	test   %esi,%esi
f0102e55:	7e 16                	jle    f0102e6d <readline+0x82>
			if (echoing)
f0102e57:	85 ff                	test   %edi,%edi
f0102e59:	74 0d                	je     f0102e68 <readline+0x7d>
				cputchar('\b');
f0102e5b:	83 ec 0c             	sub    $0xc,%esp
f0102e5e:	6a 08                	push   $0x8
f0102e60:	e8 9b d7 ff ff       	call   f0100600 <cputchar>
f0102e65:	83 c4 10             	add    $0x10,%esp
			i--;
f0102e68:	83 ee 01             	sub    $0x1,%esi
f0102e6b:	eb b3                	jmp    f0102e20 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102e6d:	83 fb 1f             	cmp    $0x1f,%ebx
f0102e70:	7e 23                	jle    f0102e95 <readline+0xaa>
f0102e72:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102e78:	7f 1b                	jg     f0102e95 <readline+0xaa>
			if (echoing)
f0102e7a:	85 ff                	test   %edi,%edi
f0102e7c:	74 0c                	je     f0102e8a <readline+0x9f>
				cputchar(c);
f0102e7e:	83 ec 0c             	sub    $0xc,%esp
f0102e81:	53                   	push   %ebx
f0102e82:	e8 79 d7 ff ff       	call   f0100600 <cputchar>
f0102e87:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102e8a:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0102e90:	8d 76 01             	lea    0x1(%esi),%esi
f0102e93:	eb 8b                	jmp    f0102e20 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102e95:	83 fb 0a             	cmp    $0xa,%ebx
f0102e98:	74 05                	je     f0102e9f <readline+0xb4>
f0102e9a:	83 fb 0d             	cmp    $0xd,%ebx
f0102e9d:	75 81                	jne    f0102e20 <readline+0x35>
			if (echoing)
f0102e9f:	85 ff                	test   %edi,%edi
f0102ea1:	74 0d                	je     f0102eb0 <readline+0xc5>
				cputchar('\n');
f0102ea3:	83 ec 0c             	sub    $0xc,%esp
f0102ea6:	6a 0a                	push   $0xa
f0102ea8:	e8 53 d7 ff ff       	call   f0100600 <cputchar>
f0102ead:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102eb0:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102eb7:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0102ebc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ebf:	5b                   	pop    %ebx
f0102ec0:	5e                   	pop    %esi
f0102ec1:	5f                   	pop    %edi
f0102ec2:	5d                   	pop    %ebp
f0102ec3:	c3                   	ret    

f0102ec4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102ec4:	55                   	push   %ebp
f0102ec5:	89 e5                	mov    %esp,%ebp
f0102ec7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102eca:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ecf:	eb 03                	jmp    f0102ed4 <strlen+0x10>
		n++;
f0102ed1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102ed4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102ed8:	75 f7                	jne    f0102ed1 <strlen+0xd>
		n++;
	return n;
}
f0102eda:	5d                   	pop    %ebp
f0102edb:	c3                   	ret    

f0102edc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102edc:	55                   	push   %ebp
f0102edd:	89 e5                	mov    %esp,%ebp
f0102edf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102ee5:	ba 00 00 00 00       	mov    $0x0,%edx
f0102eea:	eb 03                	jmp    f0102eef <strnlen+0x13>
		n++;
f0102eec:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102eef:	39 c2                	cmp    %eax,%edx
f0102ef1:	74 08                	je     f0102efb <strnlen+0x1f>
f0102ef3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102ef7:	75 f3                	jne    f0102eec <strnlen+0x10>
f0102ef9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102efb:	5d                   	pop    %ebp
f0102efc:	c3                   	ret    

f0102efd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102efd:	55                   	push   %ebp
f0102efe:	89 e5                	mov    %esp,%ebp
f0102f00:	53                   	push   %ebx
f0102f01:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f04:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102f07:	89 c2                	mov    %eax,%edx
f0102f09:	83 c2 01             	add    $0x1,%edx
f0102f0c:	83 c1 01             	add    $0x1,%ecx
f0102f0f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102f13:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102f16:	84 db                	test   %bl,%bl
f0102f18:	75 ef                	jne    f0102f09 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102f1a:	5b                   	pop    %ebx
f0102f1b:	5d                   	pop    %ebp
f0102f1c:	c3                   	ret    

f0102f1d <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102f1d:	55                   	push   %ebp
f0102f1e:	89 e5                	mov    %esp,%ebp
f0102f20:	53                   	push   %ebx
f0102f21:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102f24:	53                   	push   %ebx
f0102f25:	e8 9a ff ff ff       	call   f0102ec4 <strlen>
f0102f2a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102f2d:	ff 75 0c             	pushl  0xc(%ebp)
f0102f30:	01 d8                	add    %ebx,%eax
f0102f32:	50                   	push   %eax
f0102f33:	e8 c5 ff ff ff       	call   f0102efd <strcpy>
	return dst;
}
f0102f38:	89 d8                	mov    %ebx,%eax
f0102f3a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f3d:	c9                   	leave  
f0102f3e:	c3                   	ret    

f0102f3f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102f3f:	55                   	push   %ebp
f0102f40:	89 e5                	mov    %esp,%ebp
f0102f42:	56                   	push   %esi
f0102f43:	53                   	push   %ebx
f0102f44:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f47:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f4a:	89 f3                	mov    %esi,%ebx
f0102f4c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102f4f:	89 f2                	mov    %esi,%edx
f0102f51:	eb 0f                	jmp    f0102f62 <strncpy+0x23>
		*dst++ = *src;
f0102f53:	83 c2 01             	add    $0x1,%edx
f0102f56:	0f b6 01             	movzbl (%ecx),%eax
f0102f59:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102f5c:	80 39 01             	cmpb   $0x1,(%ecx)
f0102f5f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102f62:	39 da                	cmp    %ebx,%edx
f0102f64:	75 ed                	jne    f0102f53 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102f66:	89 f0                	mov    %esi,%eax
f0102f68:	5b                   	pop    %ebx
f0102f69:	5e                   	pop    %esi
f0102f6a:	5d                   	pop    %ebp
f0102f6b:	c3                   	ret    

f0102f6c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102f6c:	55                   	push   %ebp
f0102f6d:	89 e5                	mov    %esp,%ebp
f0102f6f:	56                   	push   %esi
f0102f70:	53                   	push   %ebx
f0102f71:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f74:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f77:	8b 55 10             	mov    0x10(%ebp),%edx
f0102f7a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102f7c:	85 d2                	test   %edx,%edx
f0102f7e:	74 21                	je     f0102fa1 <strlcpy+0x35>
f0102f80:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0102f84:	89 f2                	mov    %esi,%edx
f0102f86:	eb 09                	jmp    f0102f91 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102f88:	83 c2 01             	add    $0x1,%edx
f0102f8b:	83 c1 01             	add    $0x1,%ecx
f0102f8e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102f91:	39 c2                	cmp    %eax,%edx
f0102f93:	74 09                	je     f0102f9e <strlcpy+0x32>
f0102f95:	0f b6 19             	movzbl (%ecx),%ebx
f0102f98:	84 db                	test   %bl,%bl
f0102f9a:	75 ec                	jne    f0102f88 <strlcpy+0x1c>
f0102f9c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102f9e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102fa1:	29 f0                	sub    %esi,%eax
}
f0102fa3:	5b                   	pop    %ebx
f0102fa4:	5e                   	pop    %esi
f0102fa5:	5d                   	pop    %ebp
f0102fa6:	c3                   	ret    

f0102fa7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102fa7:	55                   	push   %ebp
f0102fa8:	89 e5                	mov    %esp,%ebp
f0102faa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102fad:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102fb0:	eb 06                	jmp    f0102fb8 <strcmp+0x11>
		p++, q++;
f0102fb2:	83 c1 01             	add    $0x1,%ecx
f0102fb5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102fb8:	0f b6 01             	movzbl (%ecx),%eax
f0102fbb:	84 c0                	test   %al,%al
f0102fbd:	74 04                	je     f0102fc3 <strcmp+0x1c>
f0102fbf:	3a 02                	cmp    (%edx),%al
f0102fc1:	74 ef                	je     f0102fb2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102fc3:	0f b6 c0             	movzbl %al,%eax
f0102fc6:	0f b6 12             	movzbl (%edx),%edx
f0102fc9:	29 d0                	sub    %edx,%eax
}
f0102fcb:	5d                   	pop    %ebp
f0102fcc:	c3                   	ret    

f0102fcd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102fcd:	55                   	push   %ebp
f0102fce:	89 e5                	mov    %esp,%ebp
f0102fd0:	53                   	push   %ebx
f0102fd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102fd7:	89 c3                	mov    %eax,%ebx
f0102fd9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0102fdc:	eb 06                	jmp    f0102fe4 <strncmp+0x17>
		n--, p++, q++;
f0102fde:	83 c0 01             	add    $0x1,%eax
f0102fe1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102fe4:	39 d8                	cmp    %ebx,%eax
f0102fe6:	74 15                	je     f0102ffd <strncmp+0x30>
f0102fe8:	0f b6 08             	movzbl (%eax),%ecx
f0102feb:	84 c9                	test   %cl,%cl
f0102fed:	74 04                	je     f0102ff3 <strncmp+0x26>
f0102fef:	3a 0a                	cmp    (%edx),%cl
f0102ff1:	74 eb                	je     f0102fde <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102ff3:	0f b6 00             	movzbl (%eax),%eax
f0102ff6:	0f b6 12             	movzbl (%edx),%edx
f0102ff9:	29 d0                	sub    %edx,%eax
f0102ffb:	eb 05                	jmp    f0103002 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102ffd:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103002:	5b                   	pop    %ebx
f0103003:	5d                   	pop    %ebp
f0103004:	c3                   	ret    

f0103005 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103005:	55                   	push   %ebp
f0103006:	89 e5                	mov    %esp,%ebp
f0103008:	8b 45 08             	mov    0x8(%ebp),%eax
f010300b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010300f:	eb 07                	jmp    f0103018 <strchr+0x13>
		if (*s == c)
f0103011:	38 ca                	cmp    %cl,%dl
f0103013:	74 0f                	je     f0103024 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103015:	83 c0 01             	add    $0x1,%eax
f0103018:	0f b6 10             	movzbl (%eax),%edx
f010301b:	84 d2                	test   %dl,%dl
f010301d:	75 f2                	jne    f0103011 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010301f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103024:	5d                   	pop    %ebp
f0103025:	c3                   	ret    

f0103026 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103026:	55                   	push   %ebp
f0103027:	89 e5                	mov    %esp,%ebp
f0103029:	8b 45 08             	mov    0x8(%ebp),%eax
f010302c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103030:	eb 03                	jmp    f0103035 <strfind+0xf>
f0103032:	83 c0 01             	add    $0x1,%eax
f0103035:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103038:	38 ca                	cmp    %cl,%dl
f010303a:	74 04                	je     f0103040 <strfind+0x1a>
f010303c:	84 d2                	test   %dl,%dl
f010303e:	75 f2                	jne    f0103032 <strfind+0xc>
			break;
	return (char *) s;
}
f0103040:	5d                   	pop    %ebp
f0103041:	c3                   	ret    

f0103042 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103042:	55                   	push   %ebp
f0103043:	89 e5                	mov    %esp,%ebp
f0103045:	57                   	push   %edi
f0103046:	56                   	push   %esi
f0103047:	53                   	push   %ebx
f0103048:	8b 7d 08             	mov    0x8(%ebp),%edi
f010304b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010304e:	85 c9                	test   %ecx,%ecx
f0103050:	74 36                	je     f0103088 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103052:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103058:	75 28                	jne    f0103082 <memset+0x40>
f010305a:	f6 c1 03             	test   $0x3,%cl
f010305d:	75 23                	jne    f0103082 <memset+0x40>
		c &= 0xFF;
f010305f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103063:	89 d3                	mov    %edx,%ebx
f0103065:	c1 e3 08             	shl    $0x8,%ebx
f0103068:	89 d6                	mov    %edx,%esi
f010306a:	c1 e6 18             	shl    $0x18,%esi
f010306d:	89 d0                	mov    %edx,%eax
f010306f:	c1 e0 10             	shl    $0x10,%eax
f0103072:	09 f0                	or     %esi,%eax
f0103074:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103076:	89 d8                	mov    %ebx,%eax
f0103078:	09 d0                	or     %edx,%eax
f010307a:	c1 e9 02             	shr    $0x2,%ecx
f010307d:	fc                   	cld    
f010307e:	f3 ab                	rep stos %eax,%es:(%edi)
f0103080:	eb 06                	jmp    f0103088 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103082:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103085:	fc                   	cld    
f0103086:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103088:	89 f8                	mov    %edi,%eax
f010308a:	5b                   	pop    %ebx
f010308b:	5e                   	pop    %esi
f010308c:	5f                   	pop    %edi
f010308d:	5d                   	pop    %ebp
f010308e:	c3                   	ret    

f010308f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010308f:	55                   	push   %ebp
f0103090:	89 e5                	mov    %esp,%ebp
f0103092:	57                   	push   %edi
f0103093:	56                   	push   %esi
f0103094:	8b 45 08             	mov    0x8(%ebp),%eax
f0103097:	8b 75 0c             	mov    0xc(%ebp),%esi
f010309a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010309d:	39 c6                	cmp    %eax,%esi
f010309f:	73 35                	jae    f01030d6 <memmove+0x47>
f01030a1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01030a4:	39 d0                	cmp    %edx,%eax
f01030a6:	73 2e                	jae    f01030d6 <memmove+0x47>
		s += n;
		d += n;
f01030a8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030ab:	89 d6                	mov    %edx,%esi
f01030ad:	09 fe                	or     %edi,%esi
f01030af:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01030b5:	75 13                	jne    f01030ca <memmove+0x3b>
f01030b7:	f6 c1 03             	test   $0x3,%cl
f01030ba:	75 0e                	jne    f01030ca <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01030bc:	83 ef 04             	sub    $0x4,%edi
f01030bf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01030c2:	c1 e9 02             	shr    $0x2,%ecx
f01030c5:	fd                   	std    
f01030c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01030c8:	eb 09                	jmp    f01030d3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01030ca:	83 ef 01             	sub    $0x1,%edi
f01030cd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01030d0:	fd                   	std    
f01030d1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01030d3:	fc                   	cld    
f01030d4:	eb 1d                	jmp    f01030f3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030d6:	89 f2                	mov    %esi,%edx
f01030d8:	09 c2                	or     %eax,%edx
f01030da:	f6 c2 03             	test   $0x3,%dl
f01030dd:	75 0f                	jne    f01030ee <memmove+0x5f>
f01030df:	f6 c1 03             	test   $0x3,%cl
f01030e2:	75 0a                	jne    f01030ee <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01030e4:	c1 e9 02             	shr    $0x2,%ecx
f01030e7:	89 c7                	mov    %eax,%edi
f01030e9:	fc                   	cld    
f01030ea:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01030ec:	eb 05                	jmp    f01030f3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01030ee:	89 c7                	mov    %eax,%edi
f01030f0:	fc                   	cld    
f01030f1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01030f3:	5e                   	pop    %esi
f01030f4:	5f                   	pop    %edi
f01030f5:	5d                   	pop    %ebp
f01030f6:	c3                   	ret    

f01030f7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01030f7:	55                   	push   %ebp
f01030f8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01030fa:	ff 75 10             	pushl  0x10(%ebp)
f01030fd:	ff 75 0c             	pushl  0xc(%ebp)
f0103100:	ff 75 08             	pushl  0x8(%ebp)
f0103103:	e8 87 ff ff ff       	call   f010308f <memmove>
}
f0103108:	c9                   	leave  
f0103109:	c3                   	ret    

f010310a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010310a:	55                   	push   %ebp
f010310b:	89 e5                	mov    %esp,%ebp
f010310d:	56                   	push   %esi
f010310e:	53                   	push   %ebx
f010310f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103112:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103115:	89 c6                	mov    %eax,%esi
f0103117:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010311a:	eb 1a                	jmp    f0103136 <memcmp+0x2c>
		if (*s1 != *s2)
f010311c:	0f b6 08             	movzbl (%eax),%ecx
f010311f:	0f b6 1a             	movzbl (%edx),%ebx
f0103122:	38 d9                	cmp    %bl,%cl
f0103124:	74 0a                	je     f0103130 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103126:	0f b6 c1             	movzbl %cl,%eax
f0103129:	0f b6 db             	movzbl %bl,%ebx
f010312c:	29 d8                	sub    %ebx,%eax
f010312e:	eb 0f                	jmp    f010313f <memcmp+0x35>
		s1++, s2++;
f0103130:	83 c0 01             	add    $0x1,%eax
f0103133:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103136:	39 f0                	cmp    %esi,%eax
f0103138:	75 e2                	jne    f010311c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010313a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010313f:	5b                   	pop    %ebx
f0103140:	5e                   	pop    %esi
f0103141:	5d                   	pop    %ebp
f0103142:	c3                   	ret    

f0103143 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103143:	55                   	push   %ebp
f0103144:	89 e5                	mov    %esp,%ebp
f0103146:	53                   	push   %ebx
f0103147:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010314a:	89 c1                	mov    %eax,%ecx
f010314c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010314f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103153:	eb 0a                	jmp    f010315f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103155:	0f b6 10             	movzbl (%eax),%edx
f0103158:	39 da                	cmp    %ebx,%edx
f010315a:	74 07                	je     f0103163 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010315c:	83 c0 01             	add    $0x1,%eax
f010315f:	39 c8                	cmp    %ecx,%eax
f0103161:	72 f2                	jb     f0103155 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103163:	5b                   	pop    %ebx
f0103164:	5d                   	pop    %ebp
f0103165:	c3                   	ret    

f0103166 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103166:	55                   	push   %ebp
f0103167:	89 e5                	mov    %esp,%ebp
f0103169:	57                   	push   %edi
f010316a:	56                   	push   %esi
f010316b:	53                   	push   %ebx
f010316c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010316f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103172:	eb 03                	jmp    f0103177 <strtol+0x11>
		s++;
f0103174:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103177:	0f b6 01             	movzbl (%ecx),%eax
f010317a:	3c 20                	cmp    $0x20,%al
f010317c:	74 f6                	je     f0103174 <strtol+0xe>
f010317e:	3c 09                	cmp    $0x9,%al
f0103180:	74 f2                	je     f0103174 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103182:	3c 2b                	cmp    $0x2b,%al
f0103184:	75 0a                	jne    f0103190 <strtol+0x2a>
		s++;
f0103186:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103189:	bf 00 00 00 00       	mov    $0x0,%edi
f010318e:	eb 11                	jmp    f01031a1 <strtol+0x3b>
f0103190:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103195:	3c 2d                	cmp    $0x2d,%al
f0103197:	75 08                	jne    f01031a1 <strtol+0x3b>
		s++, neg = 1;
f0103199:	83 c1 01             	add    $0x1,%ecx
f010319c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01031a1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01031a7:	75 15                	jne    f01031be <strtol+0x58>
f01031a9:	80 39 30             	cmpb   $0x30,(%ecx)
f01031ac:	75 10                	jne    f01031be <strtol+0x58>
f01031ae:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01031b2:	75 7c                	jne    f0103230 <strtol+0xca>
		s += 2, base = 16;
f01031b4:	83 c1 02             	add    $0x2,%ecx
f01031b7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01031bc:	eb 16                	jmp    f01031d4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01031be:	85 db                	test   %ebx,%ebx
f01031c0:	75 12                	jne    f01031d4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01031c2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01031c7:	80 39 30             	cmpb   $0x30,(%ecx)
f01031ca:	75 08                	jne    f01031d4 <strtol+0x6e>
		s++, base = 8;
f01031cc:	83 c1 01             	add    $0x1,%ecx
f01031cf:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01031d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01031d9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01031dc:	0f b6 11             	movzbl (%ecx),%edx
f01031df:	8d 72 d0             	lea    -0x30(%edx),%esi
f01031e2:	89 f3                	mov    %esi,%ebx
f01031e4:	80 fb 09             	cmp    $0x9,%bl
f01031e7:	77 08                	ja     f01031f1 <strtol+0x8b>
			dig = *s - '0';
f01031e9:	0f be d2             	movsbl %dl,%edx
f01031ec:	83 ea 30             	sub    $0x30,%edx
f01031ef:	eb 22                	jmp    f0103213 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01031f1:	8d 72 9f             	lea    -0x61(%edx),%esi
f01031f4:	89 f3                	mov    %esi,%ebx
f01031f6:	80 fb 19             	cmp    $0x19,%bl
f01031f9:	77 08                	ja     f0103203 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01031fb:	0f be d2             	movsbl %dl,%edx
f01031fe:	83 ea 57             	sub    $0x57,%edx
f0103201:	eb 10                	jmp    f0103213 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103203:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103206:	89 f3                	mov    %esi,%ebx
f0103208:	80 fb 19             	cmp    $0x19,%bl
f010320b:	77 16                	ja     f0103223 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010320d:	0f be d2             	movsbl %dl,%edx
f0103210:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103213:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103216:	7d 0b                	jge    f0103223 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103218:	83 c1 01             	add    $0x1,%ecx
f010321b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010321f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103221:	eb b9                	jmp    f01031dc <strtol+0x76>

	if (endptr)
f0103223:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103227:	74 0d                	je     f0103236 <strtol+0xd0>
		*endptr = (char *) s;
f0103229:	8b 75 0c             	mov    0xc(%ebp),%esi
f010322c:	89 0e                	mov    %ecx,(%esi)
f010322e:	eb 06                	jmp    f0103236 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103230:	85 db                	test   %ebx,%ebx
f0103232:	74 98                	je     f01031cc <strtol+0x66>
f0103234:	eb 9e                	jmp    f01031d4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103236:	89 c2                	mov    %eax,%edx
f0103238:	f7 da                	neg    %edx
f010323a:	85 ff                	test   %edi,%edi
f010323c:	0f 45 c2             	cmovne %edx,%eax
}
f010323f:	5b                   	pop    %ebx
f0103240:	5e                   	pop    %esi
f0103241:	5f                   	pop    %edi
f0103242:	5d                   	pop    %ebp
f0103243:	c3                   	ret    
f0103244:	66 90                	xchg   %ax,%ax
f0103246:	66 90                	xchg   %ax,%ax
f0103248:	66 90                	xchg   %ax,%ax
f010324a:	66 90                	xchg   %ax,%ax
f010324c:	66 90                	xchg   %ax,%ax
f010324e:	66 90                	xchg   %ax,%ax

f0103250 <__udivdi3>:
f0103250:	55                   	push   %ebp
f0103251:	57                   	push   %edi
f0103252:	56                   	push   %esi
f0103253:	53                   	push   %ebx
f0103254:	83 ec 1c             	sub    $0x1c,%esp
f0103257:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010325b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010325f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103263:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103267:	85 f6                	test   %esi,%esi
f0103269:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010326d:	89 ca                	mov    %ecx,%edx
f010326f:	89 f8                	mov    %edi,%eax
f0103271:	75 3d                	jne    f01032b0 <__udivdi3+0x60>
f0103273:	39 cf                	cmp    %ecx,%edi
f0103275:	0f 87 c5 00 00 00    	ja     f0103340 <__udivdi3+0xf0>
f010327b:	85 ff                	test   %edi,%edi
f010327d:	89 fd                	mov    %edi,%ebp
f010327f:	75 0b                	jne    f010328c <__udivdi3+0x3c>
f0103281:	b8 01 00 00 00       	mov    $0x1,%eax
f0103286:	31 d2                	xor    %edx,%edx
f0103288:	f7 f7                	div    %edi
f010328a:	89 c5                	mov    %eax,%ebp
f010328c:	89 c8                	mov    %ecx,%eax
f010328e:	31 d2                	xor    %edx,%edx
f0103290:	f7 f5                	div    %ebp
f0103292:	89 c1                	mov    %eax,%ecx
f0103294:	89 d8                	mov    %ebx,%eax
f0103296:	89 cf                	mov    %ecx,%edi
f0103298:	f7 f5                	div    %ebp
f010329a:	89 c3                	mov    %eax,%ebx
f010329c:	89 d8                	mov    %ebx,%eax
f010329e:	89 fa                	mov    %edi,%edx
f01032a0:	83 c4 1c             	add    $0x1c,%esp
f01032a3:	5b                   	pop    %ebx
f01032a4:	5e                   	pop    %esi
f01032a5:	5f                   	pop    %edi
f01032a6:	5d                   	pop    %ebp
f01032a7:	c3                   	ret    
f01032a8:	90                   	nop
f01032a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01032b0:	39 ce                	cmp    %ecx,%esi
f01032b2:	77 74                	ja     f0103328 <__udivdi3+0xd8>
f01032b4:	0f bd fe             	bsr    %esi,%edi
f01032b7:	83 f7 1f             	xor    $0x1f,%edi
f01032ba:	0f 84 98 00 00 00    	je     f0103358 <__udivdi3+0x108>
f01032c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01032c5:	89 f9                	mov    %edi,%ecx
f01032c7:	89 c5                	mov    %eax,%ebp
f01032c9:	29 fb                	sub    %edi,%ebx
f01032cb:	d3 e6                	shl    %cl,%esi
f01032cd:	89 d9                	mov    %ebx,%ecx
f01032cf:	d3 ed                	shr    %cl,%ebp
f01032d1:	89 f9                	mov    %edi,%ecx
f01032d3:	d3 e0                	shl    %cl,%eax
f01032d5:	09 ee                	or     %ebp,%esi
f01032d7:	89 d9                	mov    %ebx,%ecx
f01032d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032dd:	89 d5                	mov    %edx,%ebp
f01032df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01032e3:	d3 ed                	shr    %cl,%ebp
f01032e5:	89 f9                	mov    %edi,%ecx
f01032e7:	d3 e2                	shl    %cl,%edx
f01032e9:	89 d9                	mov    %ebx,%ecx
f01032eb:	d3 e8                	shr    %cl,%eax
f01032ed:	09 c2                	or     %eax,%edx
f01032ef:	89 d0                	mov    %edx,%eax
f01032f1:	89 ea                	mov    %ebp,%edx
f01032f3:	f7 f6                	div    %esi
f01032f5:	89 d5                	mov    %edx,%ebp
f01032f7:	89 c3                	mov    %eax,%ebx
f01032f9:	f7 64 24 0c          	mull   0xc(%esp)
f01032fd:	39 d5                	cmp    %edx,%ebp
f01032ff:	72 10                	jb     f0103311 <__udivdi3+0xc1>
f0103301:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103305:	89 f9                	mov    %edi,%ecx
f0103307:	d3 e6                	shl    %cl,%esi
f0103309:	39 c6                	cmp    %eax,%esi
f010330b:	73 07                	jae    f0103314 <__udivdi3+0xc4>
f010330d:	39 d5                	cmp    %edx,%ebp
f010330f:	75 03                	jne    f0103314 <__udivdi3+0xc4>
f0103311:	83 eb 01             	sub    $0x1,%ebx
f0103314:	31 ff                	xor    %edi,%edi
f0103316:	89 d8                	mov    %ebx,%eax
f0103318:	89 fa                	mov    %edi,%edx
f010331a:	83 c4 1c             	add    $0x1c,%esp
f010331d:	5b                   	pop    %ebx
f010331e:	5e                   	pop    %esi
f010331f:	5f                   	pop    %edi
f0103320:	5d                   	pop    %ebp
f0103321:	c3                   	ret    
f0103322:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103328:	31 ff                	xor    %edi,%edi
f010332a:	31 db                	xor    %ebx,%ebx
f010332c:	89 d8                	mov    %ebx,%eax
f010332e:	89 fa                	mov    %edi,%edx
f0103330:	83 c4 1c             	add    $0x1c,%esp
f0103333:	5b                   	pop    %ebx
f0103334:	5e                   	pop    %esi
f0103335:	5f                   	pop    %edi
f0103336:	5d                   	pop    %ebp
f0103337:	c3                   	ret    
f0103338:	90                   	nop
f0103339:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103340:	89 d8                	mov    %ebx,%eax
f0103342:	f7 f7                	div    %edi
f0103344:	31 ff                	xor    %edi,%edi
f0103346:	89 c3                	mov    %eax,%ebx
f0103348:	89 d8                	mov    %ebx,%eax
f010334a:	89 fa                	mov    %edi,%edx
f010334c:	83 c4 1c             	add    $0x1c,%esp
f010334f:	5b                   	pop    %ebx
f0103350:	5e                   	pop    %esi
f0103351:	5f                   	pop    %edi
f0103352:	5d                   	pop    %ebp
f0103353:	c3                   	ret    
f0103354:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103358:	39 ce                	cmp    %ecx,%esi
f010335a:	72 0c                	jb     f0103368 <__udivdi3+0x118>
f010335c:	31 db                	xor    %ebx,%ebx
f010335e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103362:	0f 87 34 ff ff ff    	ja     f010329c <__udivdi3+0x4c>
f0103368:	bb 01 00 00 00       	mov    $0x1,%ebx
f010336d:	e9 2a ff ff ff       	jmp    f010329c <__udivdi3+0x4c>
f0103372:	66 90                	xchg   %ax,%ax
f0103374:	66 90                	xchg   %ax,%ax
f0103376:	66 90                	xchg   %ax,%ax
f0103378:	66 90                	xchg   %ax,%ax
f010337a:	66 90                	xchg   %ax,%ax
f010337c:	66 90                	xchg   %ax,%ax
f010337e:	66 90                	xchg   %ax,%ax

f0103380 <__umoddi3>:
f0103380:	55                   	push   %ebp
f0103381:	57                   	push   %edi
f0103382:	56                   	push   %esi
f0103383:	53                   	push   %ebx
f0103384:	83 ec 1c             	sub    $0x1c,%esp
f0103387:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010338b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010338f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103393:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103397:	85 d2                	test   %edx,%edx
f0103399:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010339d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01033a1:	89 f3                	mov    %esi,%ebx
f01033a3:	89 3c 24             	mov    %edi,(%esp)
f01033a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033aa:	75 1c                	jne    f01033c8 <__umoddi3+0x48>
f01033ac:	39 f7                	cmp    %esi,%edi
f01033ae:	76 50                	jbe    f0103400 <__umoddi3+0x80>
f01033b0:	89 c8                	mov    %ecx,%eax
f01033b2:	89 f2                	mov    %esi,%edx
f01033b4:	f7 f7                	div    %edi
f01033b6:	89 d0                	mov    %edx,%eax
f01033b8:	31 d2                	xor    %edx,%edx
f01033ba:	83 c4 1c             	add    $0x1c,%esp
f01033bd:	5b                   	pop    %ebx
f01033be:	5e                   	pop    %esi
f01033bf:	5f                   	pop    %edi
f01033c0:	5d                   	pop    %ebp
f01033c1:	c3                   	ret    
f01033c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033c8:	39 f2                	cmp    %esi,%edx
f01033ca:	89 d0                	mov    %edx,%eax
f01033cc:	77 52                	ja     f0103420 <__umoddi3+0xa0>
f01033ce:	0f bd ea             	bsr    %edx,%ebp
f01033d1:	83 f5 1f             	xor    $0x1f,%ebp
f01033d4:	75 5a                	jne    f0103430 <__umoddi3+0xb0>
f01033d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01033da:	0f 82 e0 00 00 00    	jb     f01034c0 <__umoddi3+0x140>
f01033e0:	39 0c 24             	cmp    %ecx,(%esp)
f01033e3:	0f 86 d7 00 00 00    	jbe    f01034c0 <__umoddi3+0x140>
f01033e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01033f1:	83 c4 1c             	add    $0x1c,%esp
f01033f4:	5b                   	pop    %ebx
f01033f5:	5e                   	pop    %esi
f01033f6:	5f                   	pop    %edi
f01033f7:	5d                   	pop    %ebp
f01033f8:	c3                   	ret    
f01033f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103400:	85 ff                	test   %edi,%edi
f0103402:	89 fd                	mov    %edi,%ebp
f0103404:	75 0b                	jne    f0103411 <__umoddi3+0x91>
f0103406:	b8 01 00 00 00       	mov    $0x1,%eax
f010340b:	31 d2                	xor    %edx,%edx
f010340d:	f7 f7                	div    %edi
f010340f:	89 c5                	mov    %eax,%ebp
f0103411:	89 f0                	mov    %esi,%eax
f0103413:	31 d2                	xor    %edx,%edx
f0103415:	f7 f5                	div    %ebp
f0103417:	89 c8                	mov    %ecx,%eax
f0103419:	f7 f5                	div    %ebp
f010341b:	89 d0                	mov    %edx,%eax
f010341d:	eb 99                	jmp    f01033b8 <__umoddi3+0x38>
f010341f:	90                   	nop
f0103420:	89 c8                	mov    %ecx,%eax
f0103422:	89 f2                	mov    %esi,%edx
f0103424:	83 c4 1c             	add    $0x1c,%esp
f0103427:	5b                   	pop    %ebx
f0103428:	5e                   	pop    %esi
f0103429:	5f                   	pop    %edi
f010342a:	5d                   	pop    %ebp
f010342b:	c3                   	ret    
f010342c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103430:	8b 34 24             	mov    (%esp),%esi
f0103433:	bf 20 00 00 00       	mov    $0x20,%edi
f0103438:	89 e9                	mov    %ebp,%ecx
f010343a:	29 ef                	sub    %ebp,%edi
f010343c:	d3 e0                	shl    %cl,%eax
f010343e:	89 f9                	mov    %edi,%ecx
f0103440:	89 f2                	mov    %esi,%edx
f0103442:	d3 ea                	shr    %cl,%edx
f0103444:	89 e9                	mov    %ebp,%ecx
f0103446:	09 c2                	or     %eax,%edx
f0103448:	89 d8                	mov    %ebx,%eax
f010344a:	89 14 24             	mov    %edx,(%esp)
f010344d:	89 f2                	mov    %esi,%edx
f010344f:	d3 e2                	shl    %cl,%edx
f0103451:	89 f9                	mov    %edi,%ecx
f0103453:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103457:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010345b:	d3 e8                	shr    %cl,%eax
f010345d:	89 e9                	mov    %ebp,%ecx
f010345f:	89 c6                	mov    %eax,%esi
f0103461:	d3 e3                	shl    %cl,%ebx
f0103463:	89 f9                	mov    %edi,%ecx
f0103465:	89 d0                	mov    %edx,%eax
f0103467:	d3 e8                	shr    %cl,%eax
f0103469:	89 e9                	mov    %ebp,%ecx
f010346b:	09 d8                	or     %ebx,%eax
f010346d:	89 d3                	mov    %edx,%ebx
f010346f:	89 f2                	mov    %esi,%edx
f0103471:	f7 34 24             	divl   (%esp)
f0103474:	89 d6                	mov    %edx,%esi
f0103476:	d3 e3                	shl    %cl,%ebx
f0103478:	f7 64 24 04          	mull   0x4(%esp)
f010347c:	39 d6                	cmp    %edx,%esi
f010347e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103482:	89 d1                	mov    %edx,%ecx
f0103484:	89 c3                	mov    %eax,%ebx
f0103486:	72 08                	jb     f0103490 <__umoddi3+0x110>
f0103488:	75 11                	jne    f010349b <__umoddi3+0x11b>
f010348a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010348e:	73 0b                	jae    f010349b <__umoddi3+0x11b>
f0103490:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103494:	1b 14 24             	sbb    (%esp),%edx
f0103497:	89 d1                	mov    %edx,%ecx
f0103499:	89 c3                	mov    %eax,%ebx
f010349b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010349f:	29 da                	sub    %ebx,%edx
f01034a1:	19 ce                	sbb    %ecx,%esi
f01034a3:	89 f9                	mov    %edi,%ecx
f01034a5:	89 f0                	mov    %esi,%eax
f01034a7:	d3 e0                	shl    %cl,%eax
f01034a9:	89 e9                	mov    %ebp,%ecx
f01034ab:	d3 ea                	shr    %cl,%edx
f01034ad:	89 e9                	mov    %ebp,%ecx
f01034af:	d3 ee                	shr    %cl,%esi
f01034b1:	09 d0                	or     %edx,%eax
f01034b3:	89 f2                	mov    %esi,%edx
f01034b5:	83 c4 1c             	add    $0x1c,%esp
f01034b8:	5b                   	pop    %ebx
f01034b9:	5e                   	pop    %esi
f01034ba:	5f                   	pop    %edi
f01034bb:	5d                   	pop    %ebp
f01034bc:	c3                   	ret    
f01034bd:	8d 76 00             	lea    0x0(%esi),%esi
f01034c0:	29 f9                	sub    %edi,%ecx
f01034c2:	19 d6                	sbb    %edx,%esi
f01034c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034cc:	e9 18 ff ff ff       	jmp    f01033e9 <__umoddi3+0x69>
