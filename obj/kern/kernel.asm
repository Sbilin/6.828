
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
f0100058:	e8 0a 30 00 00       	call   f0103067 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 35 10 f0       	push   $0xf0103500
f010006f:	e8 0a 25 00 00       	call   f010257e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 d9 0e 00 00       	call   f0100f52 <mem_init>
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
f01000b0:	68 1b 35 10 f0       	push   $0xf010351b
f01000b5:	e8 c4 24 00 00       	call   f010257e <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 94 24 00 00       	call   f0102558 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 dd 43 10 f0 	movl   $0xf01043dd,(%esp)
f01000cb:	e8 ae 24 00 00       	call   f010257e <cprintf>
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
f01000f2:	68 33 35 10 f0       	push   $0xf0103533
f01000f7:	e8 82 24 00 00       	call   f010257e <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 50 24 00 00       	call   f0102558 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 dd 43 10 f0 	movl   $0xf01043dd,(%esp)
f010010f:	e8 6a 24 00 00       	call   f010257e <cprintf>
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
f01001ce:	0f b6 82 a0 36 10 f0 	movzbl -0xfefc960(%edx),%eax
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
f010020a:	0f b6 82 a0 36 10 f0 	movzbl -0xfefc960(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a a0 35 10 f0 	movzbl -0xfefca60(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 80 35 10 f0 	mov    -0xfefca80(,%ecx,4),%ecx
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
f0100268:	68 4d 35 10 f0       	push   $0xf010354d
f010026d:	e8 0c 23 00 00       	call   f010257e <cprintf>
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
f010041c:	e8 93 2c 00 00       	call   f01030b4 <memmove>
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
f01005eb:	68 59 35 10 f0       	push   $0xf0103559
f01005f0:	e8 89 1f 00 00       	call   f010257e <cprintf>
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
f0100631:	68 a0 37 10 f0       	push   $0xf01037a0
f0100636:	68 be 37 10 f0       	push   $0xf01037be
f010063b:	68 c3 37 10 f0       	push   $0xf01037c3
f0100640:	e8 39 1f 00 00       	call   f010257e <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 2c 38 10 f0       	push   $0xf010382c
f010064d:	68 cc 37 10 f0       	push   $0xf01037cc
f0100652:	68 c3 37 10 f0       	push   $0xf01037c3
f0100657:	e8 22 1f 00 00       	call   f010257e <cprintf>
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
f0100669:	68 d5 37 10 f0       	push   $0xf01037d5
f010066e:	e8 0b 1f 00 00       	call   f010257e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 54 38 10 f0       	push   $0xf0103854
f0100680:	e8 f9 1e 00 00       	call   f010257e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 7c 38 10 f0       	push   $0xf010387c
f0100697:	e8 e2 1e 00 00       	call   f010257e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 f1 34 10 00       	push   $0x1034f1
f01006a4:	68 f1 34 10 f0       	push   $0xf01034f1
f01006a9:	68 a0 38 10 f0       	push   $0xf01038a0
f01006ae:	e8 cb 1e 00 00       	call   f010257e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 c4 38 10 f0       	push   $0xf01038c4
f01006c5:	e8 b4 1e 00 00       	call   f010257e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 e8 38 10 f0       	push   $0xf01038e8
f01006dc:	e8 9d 1e 00 00       	call   f010257e <cprintf>
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
f0100702:	68 0c 39 10 f0       	push   $0xf010390c
f0100707:	e8 72 1e 00 00       	call   f010257e <cprintf>
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
f0100726:	68 38 39 10 f0       	push   $0xf0103938
f010072b:	e8 4e 1e 00 00       	call   f010257e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 5c 39 10 f0 	movl   $0xf010395c,(%esp)
f0100737:	e8 42 1e 00 00       	call   f010257e <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ee 37 10 f0       	push   $0xf01037ee
f0100747:	e8 c4 26 00 00       	call   f0102e10 <readline>
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
f010077b:	68 f2 37 10 f0       	push   $0xf01037f2
f0100780:	e8 a5 28 00 00       	call   f010302a <strchr>
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
f010079b:	68 f7 37 10 f0       	push   $0xf01037f7
f01007a0:	e8 d9 1d 00 00       	call   f010257e <cprintf>
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
f01007c4:	68 f2 37 10 f0       	push   $0xf01037f2
f01007c9:	e8 5c 28 00 00       	call   f010302a <strchr>
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
f01007ea:	68 be 37 10 f0       	push   $0xf01037be
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 d5 27 00 00       	call   f0102fcc <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 cc 37 10 f0       	push   $0xf01037cc
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 be 27 00 00       	call   f0102fcc <strcmp>
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
f0100831:	ff 14 85 8c 39 10 f0 	call   *-0xfefc674(,%eax,4)


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
f010084a:	68 14 38 10 f0       	push   $0xf0103814
f010084f:	e8 2a 1d 00 00       	call   f010257e <cprintf>
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
f01008a7:	e8 6b 1c 00 00       	call   f0102517 <mc146818_read>
f01008ac:	89 c6                	mov    %eax,%esi
f01008ae:	83 c3 01             	add    $0x1,%ebx
f01008b1:	89 1c 24             	mov    %ebx,(%esp)
f01008b4:	e8 5e 1c 00 00       	call   f0102517 <mc146818_read>
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
f01008ea:	68 9c 39 10 f0       	push   $0xf010399c
f01008ef:	68 e9 02 00 00       	push   $0x2e9
f01008f4:	68 18 41 10 f0       	push   $0xf0104118
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
f0100942:	68 c0 39 10 f0       	push   $0xf01039c0
f0100947:	68 2c 02 00 00       	push   $0x22c
f010094c:	68 18 41 10 f0       	push   $0xf0104118
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
f01009d1:	68 9c 39 10 f0       	push   $0xf010399c
f01009d6:	6a 52                	push   $0x52
f01009d8:	68 24 41 10 f0       	push   $0xf0104124
f01009dd:	e8 a9 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009e2:	83 ec 04             	sub    $0x4,%esp
f01009e5:	68 80 00 00 00       	push   $0x80
f01009ea:	68 97 00 00 00       	push   $0x97
f01009ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f4:	50                   	push   %eax
f01009f5:	e8 6d 26 00 00       	call   f0103067 <memset>
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
f0100a3b:	68 32 41 10 f0       	push   $0xf0104132
f0100a40:	68 3e 41 10 f0       	push   $0xf010413e
f0100a45:	68 46 02 00 00       	push   $0x246
f0100a4a:	68 18 41 10 f0       	push   $0xf0104118
f0100a4f:	e8 37 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a54:	39 fa                	cmp    %edi,%edx
f0100a56:	72 19                	jb     f0100a71 <check_page_free_list+0x148>
f0100a58:	68 53 41 10 f0       	push   $0xf0104153
f0100a5d:	68 3e 41 10 f0       	push   $0xf010413e
f0100a62:	68 47 02 00 00       	push   $0x247
f0100a67:	68 18 41 10 f0       	push   $0xf0104118
f0100a6c:	e8 1a f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a71:	89 d0                	mov    %edx,%eax
f0100a73:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a76:	a8 07                	test   $0x7,%al
f0100a78:	74 19                	je     f0100a93 <check_page_free_list+0x16a>
f0100a7a:	68 e4 39 10 f0       	push   $0xf01039e4
f0100a7f:	68 3e 41 10 f0       	push   $0xf010413e
f0100a84:	68 48 02 00 00       	push   $0x248
f0100a89:	68 18 41 10 f0       	push   $0xf0104118
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
f0100a9d:	68 67 41 10 f0       	push   $0xf0104167
f0100aa2:	68 3e 41 10 f0       	push   $0xf010413e
f0100aa7:	68 4b 02 00 00       	push   $0x24b
f0100aac:	68 18 41 10 f0       	push   $0xf0104118
f0100ab1:	e8 d5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ab6:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100abb:	75 19                	jne    f0100ad6 <check_page_free_list+0x1ad>
f0100abd:	68 78 41 10 f0       	push   $0xf0104178
f0100ac2:	68 3e 41 10 f0       	push   $0xf010413e
f0100ac7:	68 4c 02 00 00       	push   $0x24c
f0100acc:	68 18 41 10 f0       	push   $0xf0104118
f0100ad1:	e8 b5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ad6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100adb:	75 19                	jne    f0100af6 <check_page_free_list+0x1cd>
f0100add:	68 18 3a 10 f0       	push   $0xf0103a18
f0100ae2:	68 3e 41 10 f0       	push   $0xf010413e
f0100ae7:	68 4d 02 00 00       	push   $0x24d
f0100aec:	68 18 41 10 f0       	push   $0xf0104118
f0100af1:	e8 95 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100af6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100afb:	75 19                	jne    f0100b16 <check_page_free_list+0x1ed>
f0100afd:	68 91 41 10 f0       	push   $0xf0104191
f0100b02:	68 3e 41 10 f0       	push   $0xf010413e
f0100b07:	68 4e 02 00 00       	push   $0x24e
f0100b0c:	68 18 41 10 f0       	push   $0xf0104118
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
f0100b28:	68 9c 39 10 f0       	push   $0xf010399c
f0100b2d:	6a 52                	push   $0x52
f0100b2f:	68 24 41 10 f0       	push   $0xf0104124
f0100b34:	e8 52 f5 ff ff       	call   f010008b <_panic>
f0100b39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b41:	76 1e                	jbe    f0100b61 <check_page_free_list+0x238>
f0100b43:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0100b48:	68 3e 41 10 f0       	push   $0xf010413e
f0100b4d:	68 4f 02 00 00       	push   $0x24f
f0100b52:	68 18 41 10 f0       	push   $0xf0104118
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
f0100b76:	68 ab 41 10 f0       	push   $0xf01041ab
f0100b7b:	68 3e 41 10 f0       	push   $0xf010413e
f0100b80:	68 57 02 00 00       	push   $0x257
f0100b85:	68 18 41 10 f0       	push   $0xf0104118
f0100b8a:	e8 fc f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b8f:	85 db                	test   %ebx,%ebx
f0100b91:	7f 42                	jg     f0100bd5 <check_page_free_list+0x2ac>
f0100b93:	68 bd 41 10 f0       	push   $0xf01041bd
f0100b98:	68 3e 41 10 f0       	push   $0xf010413e
f0100b9d:	68 58 02 00 00       	push   $0x258
f0100ba2:	68 18 41 10 f0       	push   $0xf0104118
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
f0100bfe:	68 84 3a 10 f0       	push   $0xf0103a84
f0100c03:	68 05 01 00 00       	push   $0x105
f0100c08:	68 18 41 10 f0       	push   $0xf0104118
f0100c0d:	e8 79 f4 ff ff       	call   f010008b <_panic>
f0100c12:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100c18:	c1 eb 0c             	shr    $0xc,%ebx
	cprintf("%d,%d\n",low_pgm,upp_pgm);
f0100c1b:	83 ec 04             	sub    $0x4,%esp
f0100c1e:	53                   	push   %ebx
f0100c1f:	68 a0 00 00 00       	push   $0xa0
f0100c24:	68 ce 41 10 f0       	push   $0xf01041ce
f0100c29:	e8 50 19 00 00       	call   f010257e <cprintf>
f0100c2e:	8b 35 3c 65 11 f0    	mov    0xf011653c,%esi
	for (i = 0; i < npages; i++) {
f0100c34:	83 c4 10             	add    $0x10,%esp
f0100c37:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c41:	eb 61                	jmp    f0100ca4 <page_init+0xc7>
            if(i==0)
f0100c43:	85 c0                	test   %eax,%eax
f0100c45:	75 14                	jne    f0100c5b <page_init+0x7e>
             {
		pages[i].pp_ref = 1;
f0100c47:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100c4d:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link=NULL;
f0100c53:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100c59:	eb 46                	jmp    f0100ca1 <page_init+0xc4>
             }
             else if(i >= low_pgm && i < upp_pgm)
f0100c5b:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100c60:	76 1b                	jbe    f0100c7d <page_init+0xa0>
f0100c62:	39 d8                	cmp    %ebx,%eax
f0100c64:	73 17                	jae    f0100c7d <page_init+0xa0>
             {
                pages[i].pp_ref=1;
f0100c66:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100c6c:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100c6f:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link=NULL;
f0100c75:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100c7b:	eb 24                	jmp    f0100ca1 <page_init+0xc4>
f0100c7d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
             }
             else
             {
                 pages[i].pp_ref=0;
f0100c84:	89 d1                	mov    %edx,%ecx
f0100c86:	03 0d 4c 69 11 f0    	add    0xf011694c,%ecx
f0100c8c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
                 pages[i].pp_link = page_free_list;
f0100c92:	89 31                	mov    %esi,(%ecx)
                 page_free_list = &pages[i];
f0100c94:	89 d6                	mov    %edx,%esi
f0100c96:	03 35 4c 69 11 f0    	add    0xf011694c,%esi
f0100c9c:	b9 01 00 00 00       	mov    $0x1,%ecx
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	cprintf("%d,%d\n",low_pgm,upp_pgm);
	for (i = 0; i < npages; i++) {
f0100ca1:	83 c0 01             	add    $0x1,%eax
f0100ca4:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100caa:	72 97                	jb     f0100c43 <page_init+0x66>
f0100cac:	84 c9                	test   %cl,%cl
f0100cae:	74 06                	je     f0100cb6 <page_init+0xd9>
f0100cb0:	89 35 3c 65 11 f0    	mov    %esi,0xf011653c
                 pages[i].pp_ref=0;
                 pages[i].pp_link = page_free_list;
                 page_free_list = &pages[i];
             }
          }
}
f0100cb6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100cb9:	5b                   	pop    %ebx
f0100cba:	5e                   	pop    %esi
f0100cbb:	5d                   	pop    %ebp
f0100cbc:	c3                   	ret    

f0100cbd <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100cbd:	55                   	push   %ebp
f0100cbe:	89 e5                	mov    %esp,%ebp
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *result;
        if(page_free_list==NULL)
f0100cc4:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100cca:	85 db                	test   %ebx,%ebx
f0100ccc:	74 58                	je     f0100d26 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100cce:	8b 03                	mov    (%ebx),%eax
f0100cd0:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
        result->pp_link=NULL;
f0100cd5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
        if(alloc_flags & ALLOC_ZERO)
f0100cdb:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100cdf:	74 45                	je     f0100d26 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ce1:	89 d8                	mov    %ebx,%eax
f0100ce3:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100ce9:	c1 f8 03             	sar    $0x3,%eax
f0100cec:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cef:	89 c2                	mov    %eax,%edx
f0100cf1:	c1 ea 0c             	shr    $0xc,%edx
f0100cf4:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100cfa:	72 12                	jb     f0100d0e <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cfc:	50                   	push   %eax
f0100cfd:	68 9c 39 10 f0       	push   $0xf010399c
f0100d02:	6a 52                	push   $0x52
f0100d04:	68 24 41 10 f0       	push   $0xf0104124
f0100d09:	e8 7d f3 ff ff       	call   f010008b <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100d0e:	83 ec 04             	sub    $0x4,%esp
f0100d11:	68 00 10 00 00       	push   $0x1000
f0100d16:	6a 00                	push   $0x0
f0100d18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	e8 44 23 00 00       	call   f0103067 <memset>
f0100d23:	83 c4 10             	add    $0x10,%esp
	return result;
}
f0100d26:	89 d8                	mov    %ebx,%eax
f0100d28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d2b:	c9                   	leave  
f0100d2c:	c3                   	ret    

f0100d2d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d2d:	55                   	push   %ebp
f0100d2e:	89 e5                	mov    %esp,%ebp
f0100d30:	83 ec 08             	sub    $0x8,%esp
f0100d33:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	 assert(pp->pp_ref == 0 || pp->pp_link == NULL);  
f0100d36:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d3b:	74 1e                	je     f0100d5b <page_free+0x2e>
f0100d3d:	83 38 00             	cmpl   $0x0,(%eax)
f0100d40:	74 19                	je     f0100d5b <page_free+0x2e>
f0100d42:	68 a8 3a 10 f0       	push   $0xf0103aa8
f0100d47:	68 3e 41 10 f0       	push   $0xf010413e
f0100d4c:	68 42 01 00 00       	push   $0x142
f0100d51:	68 18 41 10 f0       	push   $0xf0104118
f0100d56:	e8 30 f3 ff ff       	call   f010008b <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100d5b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d61:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100d63:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100d68:	c9                   	leave  
f0100d69:	c3                   	ret    

f0100d6a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d6a:	55                   	push   %ebp
f0100d6b:	89 e5                	mov    %esp,%ebp
f0100d6d:	83 ec 08             	sub    $0x8,%esp
f0100d70:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d73:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d77:	83 e8 01             	sub    $0x1,%eax
f0100d7a:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d7e:	66 85 c0             	test   %ax,%ax
f0100d81:	75 0c                	jne    f0100d8f <page_decref+0x25>
		page_free(pp);
f0100d83:	83 ec 0c             	sub    $0xc,%esp
f0100d86:	52                   	push   %edx
f0100d87:	e8 a1 ff ff ff       	call   f0100d2d <page_free>
f0100d8c:	83 c4 10             	add    $0x10,%esp
}
f0100d8f:	c9                   	leave  
f0100d90:	c3                   	ret    

f0100d91 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d91:	55                   	push   %ebp
f0100d92:	89 e5                	mov    %esp,%ebp
f0100d94:	56                   	push   %esi
f0100d95:	53                   	push   %ebx
f0100d96:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pdx=PDX(va);
	uint32_t ptx=PTX(va);
f0100d99:	89 c3                	mov    %eax,%ebx
f0100d9b:	c1 eb 0c             	shr    $0xc,%ebx
f0100d9e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
	pde_t *po_entry;
 	pde_t *pt_entry=pgdir+pdx;
f0100da4:	c1 e8 16             	shr    $0x16,%eax
f0100da7:	c1 e0 02             	shl    $0x2,%eax
	if(pt_entry==NULL)
f0100daa:	03 45 08             	add    0x8(%ebp),%eax
f0100dad:	89 c6                	mov    %eax,%esi
f0100daf:	75 40                	jne    f0100df1 <pgdir_walk+0x60>
	{
		cprintf("error\n");
f0100db1:	83 ec 0c             	sub    $0xc,%esp
f0100db4:	68 d5 41 10 f0       	push   $0xf01041d5
f0100db9:	e8 c0 17 00 00       	call   f010257e <cprintf>
		if(create==0)
f0100dbe:	83 c4 10             	add    $0x10,%esp
f0100dc1:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100dc5:	74 6e                	je     f0100e35 <pgdir_walk+0xa4>
			return NULL;
		struct PageInfo *pp=page_alloc(1);
f0100dc7:	83 ec 0c             	sub    $0xc,%esp
f0100dca:	6a 01                	push   $0x1
f0100dcc:	e8 ec fe ff ff       	call   f0100cbd <page_alloc>
			if(pp==NULL)
f0100dd1:	83 c4 10             	add    $0x10,%esp
f0100dd4:	85 c0                	test   %eax,%eax
f0100dd6:	74 64                	je     f0100e3c <pgdir_walk+0xab>
			{
				return NULL;
			}
		pp->pp_ref++;
f0100dd8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		*pt_entry= (page2pa(pp)|PTE_P|PTE_U|PTE_W);
f0100ddd:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100de3:	c1 f8 03             	sar    $0x3,%eax
f0100de6:	c1 e0 0c             	shl    $0xc,%eax
f0100de9:	83 c8 07             	or     $0x7,%eax
f0100dec:	a3 00 00 00 00       	mov    %eax,0x0
	}	
	cprintf("%08x\n",*pt_entry);
f0100df1:	83 ec 08             	sub    $0x8,%esp
f0100df4:	ff 36                	pushl  (%esi)
f0100df6:	68 dc 41 10 f0       	push   $0xf01041dc
f0100dfb:	e8 7e 17 00 00       	call   f010257e <cprintf>
	po_entry=KADDR(PTE_ADDR(*pt_entry));
f0100e00:	8b 06                	mov    (%esi),%eax
f0100e02:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e07:	89 c2                	mov    %eax,%edx
f0100e09:	c1 ea 0c             	shr    $0xc,%edx
f0100e0c:	83 c4 10             	add    $0x10,%esp
f0100e0f:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100e15:	72 15                	jb     f0100e2c <pgdir_walk+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e17:	50                   	push   %eax
f0100e18:	68 9c 39 10 f0       	push   $0xf010399c
f0100e1d:	68 7f 01 00 00       	push   $0x17f
f0100e22:	68 18 41 10 f0       	push   $0xf0104118
f0100e27:	e8 5f f2 ff ff       	call   f010008b <_panic>
	return po_entry+ptx;
f0100e2c:	8d 84 98 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,4),%eax
f0100e33:	eb 0c                	jmp    f0100e41 <pgdir_walk+0xb0>
 	pde_t *pt_entry=pgdir+pdx;
	if(pt_entry==NULL)
	{
		cprintf("error\n");
		if(create==0)
			return NULL;
f0100e35:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3a:	eb 05                	jmp    f0100e41 <pgdir_walk+0xb0>
		struct PageInfo *pp=page_alloc(1);
			if(pp==NULL)
			{
				return NULL;
f0100e3c:	b8 00 00 00 00       	mov    $0x0,%eax
		*pt_entry= (page2pa(pp)|PTE_P|PTE_U|PTE_W);
	}	
	cprintf("%08x\n",*pt_entry);
	po_entry=KADDR(PTE_ADDR(*pt_entry));
	return po_entry+ptx;
}
f0100e41:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e44:	5b                   	pop    %ebx
f0100e45:	5e                   	pop    %esi
f0100e46:	5d                   	pop    %ebp
f0100e47:	c3                   	ret    

f0100e48 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e48:	55                   	push   %ebp
f0100e49:	89 e5                	mov    %esp,%ebp
f0100e4b:	53                   	push   %ebx
f0100e4c:	83 ec 08             	sub    $0x8,%esp
f0100e4f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f0100e52:	6a 00                	push   $0x0
f0100e54:	ff 75 0c             	pushl  0xc(%ebp)
f0100e57:	ff 75 08             	pushl  0x8(%ebp)
f0100e5a:	e8 32 ff ff ff       	call   f0100d91 <pgdir_walk>
	if(po_entry==NULL)
f0100e5f:	83 c4 10             	add    $0x10,%esp
f0100e62:	85 c0                	test   %eax,%eax
f0100e64:	74 3c                	je     f0100ea2 <page_lookup+0x5a>
	{
		return NULL;
	}
	if(!(*po_entry))
f0100e66:	83 38 00             	cmpl   $0x0,(%eax)
f0100e69:	74 3e                	je     f0100ea9 <page_lookup+0x61>
	{
		return NULL;
	}
	if(pte_store!=0)
f0100e6b:	85 db                	test   %ebx,%ebx
f0100e6d:	74 02                	je     f0100e71 <page_lookup+0x29>
	{
		*pte_store=po_entry;
f0100e6f:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e71:	8b 00                	mov    (%eax),%eax
f0100e73:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e78:	c1 e8 0c             	shr    $0xc,%eax
f0100e7b:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100e81:	72 14                	jb     f0100e97 <page_lookup+0x4f>
		panic("pa2page called with invalid pa");
f0100e83:	83 ec 04             	sub    $0x4,%esp
f0100e86:	68 d0 3a 10 f0       	push   $0xf0103ad0
f0100e8b:	6a 4b                	push   $0x4b
f0100e8d:	68 24 41 10 f0       	push   $0xf0104124
f0100e92:	e8 f4 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100e97:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100e9d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page((*po_entry)-KERNBASE); 
f0100ea0:	eb 0c                	jmp    f0100eae <page_lookup+0x66>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f0100ea2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea7:	eb 05                	jmp    f0100eae <page_lookup+0x66>
	}
	if(!(*po_entry))
	{
		return NULL;
f0100ea9:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page((*po_entry)-KERNBASE); 
}
f0100eae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eb1:	c9                   	leave  
f0100eb2:	c3                   	ret    

f0100eb3 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100eb3:	55                   	push   %ebp
f0100eb4:	89 e5                	mov    %esp,%ebp
f0100eb6:	53                   	push   %ebx
f0100eb7:	83 ec 18             	sub    $0x18,%esp
f0100eba:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f0100ebd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f0100ec4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ec7:	50                   	push   %eax
f0100ec8:	53                   	push   %ebx
f0100ec9:	ff 75 08             	pushl  0x8(%ebp)
f0100ecc:	e8 77 ff ff ff       	call   f0100e48 <page_lookup>
	if(pp==NULL)
f0100ed1:	83 c4 10             	add    $0x10,%esp
f0100ed4:	85 c0                	test   %eax,%eax
f0100ed6:	74 0f                	je     f0100ee7 <page_remove+0x34>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ed8:	0f 01 3b             	invlpg (%ebx)
	{
		return;
	}
	tlb_invalidate(pgdir,va);
	page_decref(pp);
f0100edb:	83 ec 0c             	sub    $0xc,%esp
f0100ede:	50                   	push   %eax
f0100edf:	e8 86 fe ff ff       	call   f0100d6a <page_decref>
f0100ee4:	83 c4 10             	add    $0x10,%esp
	pte_store=0;
	
	
}
f0100ee7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eea:	c9                   	leave  
f0100eeb:	c3                   	ret    

f0100eec <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100eec:	55                   	push   %ebp
f0100eed:	89 e5                	mov    %esp,%ebp
f0100eef:	57                   	push   %edi
f0100ef0:	56                   	push   %esi
f0100ef1:	53                   	push   %ebx
f0100ef2:	83 ec 10             	sub    $0x10,%esp
f0100ef5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ef8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f0100efb:	6a 01                	push   $0x1
f0100efd:	57                   	push   %edi
f0100efe:	ff 75 08             	pushl  0x8(%ebp)
f0100f01:	e8 8b fe ff ff       	call   f0100d91 <pgdir_walk>
	if(po_entry==NULL)
f0100f06:	83 c4 10             	add    $0x10,%esp
f0100f09:	85 c0                	test   %eax,%eax
f0100f0b:	74 38                	je     f0100f45 <page_insert+0x59>
f0100f0d:	89 c6                	mov    %eax,%esi
	{
		return -E_NO_MEM;
	}
	if(*po_entry)
f0100f0f:	83 38 00             	cmpl   $0x0,(%eax)
f0100f12:	74 0f                	je     f0100f23 <page_insert+0x37>
	{
		//tlb_invalidate(pgdir,va);
		page_remove(pgdir,va);
f0100f14:	83 ec 08             	sub    $0x8,%esp
f0100f17:	57                   	push   %edi
f0100f18:	ff 75 08             	pushl  0x8(%ebp)
f0100f1b:	e8 93 ff ff ff       	call   f0100eb3 <page_remove>
f0100f20:	83 c4 10             	add    $0x10,%esp
	}
	pp->pp_ref++;
f0100f23:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	*po_entry=page2pa(pp)|perm|PTE_P;
f0100f28:	2b 1d 4c 69 11 f0    	sub    0xf011694c,%ebx
f0100f2e:	c1 fb 03             	sar    $0x3,%ebx
f0100f31:	c1 e3 0c             	shl    $0xc,%ebx
f0100f34:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f37:	83 c8 01             	or     $0x1,%eax
f0100f3a:	09 c3                	or     %eax,%ebx
f0100f3c:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100f3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f43:	eb 05                	jmp    f0100f4a <page_insert+0x5e>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f0100f45:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	pp->pp_ref++;
	*po_entry=page2pa(pp)|perm|PTE_P;
	return 0;
}
f0100f4a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f4d:	5b                   	pop    %ebx
f0100f4e:	5e                   	pop    %esi
f0100f4f:	5f                   	pop    %edi
f0100f50:	5d                   	pop    %ebp
f0100f51:	c3                   	ret    

f0100f52 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f52:	55                   	push   %ebp
f0100f53:	89 e5                	mov    %esp,%ebp
f0100f55:	57                   	push   %edi
f0100f56:	56                   	push   %esi
f0100f57:	53                   	push   %ebx
f0100f58:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f5b:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f60:	e8 37 f9 ff ff       	call   f010089c <nvram_read>
f0100f65:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f67:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f6c:	e8 2b f9 ff ff       	call   f010089c <nvram_read>
f0100f71:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100f73:	b8 34 00 00 00       	mov    $0x34,%eax
f0100f78:	e8 1f f9 ff ff       	call   f010089c <nvram_read>
f0100f7d:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100f80:	85 c0                	test   %eax,%eax
f0100f82:	74 07                	je     f0100f8b <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100f84:	05 00 40 00 00       	add    $0x4000,%eax
f0100f89:	eb 0b                	jmp    f0100f96 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100f8b:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100f91:	85 f6                	test   %esi,%esi
f0100f93:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100f96:	89 c2                	mov    %eax,%edx
f0100f98:	c1 ea 02             	shr    $0x2,%edx
f0100f9b:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100fa1:	89 c2                	mov    %eax,%edx
f0100fa3:	29 da                	sub    %ebx,%edx
f0100fa5:	52                   	push   %edx
f0100fa6:	53                   	push   %ebx
f0100fa7:	50                   	push   %eax
f0100fa8:	68 f0 3a 10 f0       	push   $0xf0103af0
f0100fad:	e8 cc 15 00 00       	call   f010257e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100fb2:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100fb7:	e8 a8 f8 ff ff       	call   f0100864 <boot_alloc>
f0100fbc:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0100fc1:	83 c4 0c             	add    $0xc,%esp
f0100fc4:	68 00 10 00 00       	push   $0x1000
f0100fc9:	6a 00                	push   $0x0
f0100fcb:	50                   	push   %eax
f0100fcc:	e8 96 20 00 00       	call   f0103067 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100fd1:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fd6:	83 c4 10             	add    $0x10,%esp
f0100fd9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fde:	77 15                	ja     f0100ff5 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fe0:	50                   	push   %eax
f0100fe1:	68 84 3a 10 f0       	push   $0xf0103a84
f0100fe6:	68 8f 00 00 00       	push   $0x8f
f0100feb:	68 18 41 10 f0       	push   $0xf0104118
f0100ff0:	e8 96 f0 ff ff       	call   f010008b <_panic>
f0100ff5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100ffb:	83 ca 05             	or     $0x5,%edx
f0100ffe:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages*sizeof(struct PageInfo));
f0101004:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101009:	c1 e0 03             	shl    $0x3,%eax
f010100c:	e8 53 f8 ff ff       	call   f0100864 <boot_alloc>
f0101011:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
        memset(pages,0,npages*sizeof(struct PageInfo));
f0101016:	83 ec 04             	sub    $0x4,%esp
f0101019:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f010101f:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101026:	52                   	push   %edx
f0101027:	6a 00                	push   $0x0
f0101029:	50                   	push   %eax
f010102a:	e8 38 20 00 00       	call   f0103067 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010102f:	e8 a9 fb ff ff       	call   f0100bdd <page_init>
	check_page_free_list(1);
f0101034:	b8 01 00 00 00       	mov    $0x1,%eax
f0101039:	e8 eb f8 ff ff       	call   f0100929 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010103e:	83 c4 10             	add    $0x10,%esp
f0101041:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f0101048:	75 17                	jne    f0101061 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f010104a:	83 ec 04             	sub    $0x4,%esp
f010104d:	68 e2 41 10 f0       	push   $0xf01041e2
f0101052:	68 69 02 00 00       	push   $0x269
f0101057:	68 18 41 10 f0       	push   $0xf0104118
f010105c:	e8 2a f0 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101061:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101066:	bb 00 00 00 00       	mov    $0x0,%ebx
f010106b:	eb 05                	jmp    f0101072 <mem_init+0x120>
		++nfree;
f010106d:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101070:	8b 00                	mov    (%eax),%eax
f0101072:	85 c0                	test   %eax,%eax
f0101074:	75 f7                	jne    f010106d <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101076:	83 ec 0c             	sub    $0xc,%esp
f0101079:	6a 00                	push   $0x0
f010107b:	e8 3d fc ff ff       	call   f0100cbd <page_alloc>
f0101080:	89 c7                	mov    %eax,%edi
f0101082:	83 c4 10             	add    $0x10,%esp
f0101085:	85 c0                	test   %eax,%eax
f0101087:	75 19                	jne    f01010a2 <mem_init+0x150>
f0101089:	68 fd 41 10 f0       	push   $0xf01041fd
f010108e:	68 3e 41 10 f0       	push   $0xf010413e
f0101093:	68 71 02 00 00       	push   $0x271
f0101098:	68 18 41 10 f0       	push   $0xf0104118
f010109d:	e8 e9 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01010a2:	83 ec 0c             	sub    $0xc,%esp
f01010a5:	6a 00                	push   $0x0
f01010a7:	e8 11 fc ff ff       	call   f0100cbd <page_alloc>
f01010ac:	89 c6                	mov    %eax,%esi
f01010ae:	83 c4 10             	add    $0x10,%esp
f01010b1:	85 c0                	test   %eax,%eax
f01010b3:	75 19                	jne    f01010ce <mem_init+0x17c>
f01010b5:	68 13 42 10 f0       	push   $0xf0104213
f01010ba:	68 3e 41 10 f0       	push   $0xf010413e
f01010bf:	68 72 02 00 00       	push   $0x272
f01010c4:	68 18 41 10 f0       	push   $0xf0104118
f01010c9:	e8 bd ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01010ce:	83 ec 0c             	sub    $0xc,%esp
f01010d1:	6a 00                	push   $0x0
f01010d3:	e8 e5 fb ff ff       	call   f0100cbd <page_alloc>
f01010d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010db:	83 c4 10             	add    $0x10,%esp
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	75 19                	jne    f01010fb <mem_init+0x1a9>
f01010e2:	68 29 42 10 f0       	push   $0xf0104229
f01010e7:	68 3e 41 10 f0       	push   $0xf010413e
f01010ec:	68 73 02 00 00       	push   $0x273
f01010f1:	68 18 41 10 f0       	push   $0xf0104118
f01010f6:	e8 90 ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010fb:	39 f7                	cmp    %esi,%edi
f01010fd:	75 19                	jne    f0101118 <mem_init+0x1c6>
f01010ff:	68 3f 42 10 f0       	push   $0xf010423f
f0101104:	68 3e 41 10 f0       	push   $0xf010413e
f0101109:	68 76 02 00 00       	push   $0x276
f010110e:	68 18 41 10 f0       	push   $0xf0104118
f0101113:	e8 73 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101118:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010111b:	39 c6                	cmp    %eax,%esi
f010111d:	74 04                	je     f0101123 <mem_init+0x1d1>
f010111f:	39 c7                	cmp    %eax,%edi
f0101121:	75 19                	jne    f010113c <mem_init+0x1ea>
f0101123:	68 2c 3b 10 f0       	push   $0xf0103b2c
f0101128:	68 3e 41 10 f0       	push   $0xf010413e
f010112d:	68 77 02 00 00       	push   $0x277
f0101132:	68 18 41 10 f0       	push   $0xf0104118
f0101137:	e8 4f ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010113c:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101142:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f0101148:	c1 e2 0c             	shl    $0xc,%edx
f010114b:	89 f8                	mov    %edi,%eax
f010114d:	29 c8                	sub    %ecx,%eax
f010114f:	c1 f8 03             	sar    $0x3,%eax
f0101152:	c1 e0 0c             	shl    $0xc,%eax
f0101155:	39 d0                	cmp    %edx,%eax
f0101157:	72 19                	jb     f0101172 <mem_init+0x220>
f0101159:	68 51 42 10 f0       	push   $0xf0104251
f010115e:	68 3e 41 10 f0       	push   $0xf010413e
f0101163:	68 78 02 00 00       	push   $0x278
f0101168:	68 18 41 10 f0       	push   $0xf0104118
f010116d:	e8 19 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101172:	89 f0                	mov    %esi,%eax
f0101174:	29 c8                	sub    %ecx,%eax
f0101176:	c1 f8 03             	sar    $0x3,%eax
f0101179:	c1 e0 0c             	shl    $0xc,%eax
f010117c:	39 c2                	cmp    %eax,%edx
f010117e:	77 19                	ja     f0101199 <mem_init+0x247>
f0101180:	68 6e 42 10 f0       	push   $0xf010426e
f0101185:	68 3e 41 10 f0       	push   $0xf010413e
f010118a:	68 79 02 00 00       	push   $0x279
f010118f:	68 18 41 10 f0       	push   $0xf0104118
f0101194:	e8 f2 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101199:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010119c:	29 c8                	sub    %ecx,%eax
f010119e:	c1 f8 03             	sar    $0x3,%eax
f01011a1:	c1 e0 0c             	shl    $0xc,%eax
f01011a4:	39 c2                	cmp    %eax,%edx
f01011a6:	77 19                	ja     f01011c1 <mem_init+0x26f>
f01011a8:	68 8b 42 10 f0       	push   $0xf010428b
f01011ad:	68 3e 41 10 f0       	push   $0xf010413e
f01011b2:	68 7a 02 00 00       	push   $0x27a
f01011b7:	68 18 41 10 f0       	push   $0xf0104118
f01011bc:	e8 ca ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011c1:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01011c9:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01011d0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011d3:	83 ec 0c             	sub    $0xc,%esp
f01011d6:	6a 00                	push   $0x0
f01011d8:	e8 e0 fa ff ff       	call   f0100cbd <page_alloc>
f01011dd:	83 c4 10             	add    $0x10,%esp
f01011e0:	85 c0                	test   %eax,%eax
f01011e2:	74 19                	je     f01011fd <mem_init+0x2ab>
f01011e4:	68 a8 42 10 f0       	push   $0xf01042a8
f01011e9:	68 3e 41 10 f0       	push   $0xf010413e
f01011ee:	68 81 02 00 00       	push   $0x281
f01011f3:	68 18 41 10 f0       	push   $0xf0104118
f01011f8:	e8 8e ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01011fd:	83 ec 0c             	sub    $0xc,%esp
f0101200:	57                   	push   %edi
f0101201:	e8 27 fb ff ff       	call   f0100d2d <page_free>
	page_free(pp1);
f0101206:	89 34 24             	mov    %esi,(%esp)
f0101209:	e8 1f fb ff ff       	call   f0100d2d <page_free>
	page_free(pp2);
f010120e:	83 c4 04             	add    $0x4,%esp
f0101211:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101214:	e8 14 fb ff ff       	call   f0100d2d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101219:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101220:	e8 98 fa ff ff       	call   f0100cbd <page_alloc>
f0101225:	89 c6                	mov    %eax,%esi
f0101227:	83 c4 10             	add    $0x10,%esp
f010122a:	85 c0                	test   %eax,%eax
f010122c:	75 19                	jne    f0101247 <mem_init+0x2f5>
f010122e:	68 fd 41 10 f0       	push   $0xf01041fd
f0101233:	68 3e 41 10 f0       	push   $0xf010413e
f0101238:	68 88 02 00 00       	push   $0x288
f010123d:	68 18 41 10 f0       	push   $0xf0104118
f0101242:	e8 44 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101247:	83 ec 0c             	sub    $0xc,%esp
f010124a:	6a 00                	push   $0x0
f010124c:	e8 6c fa ff ff       	call   f0100cbd <page_alloc>
f0101251:	89 c7                	mov    %eax,%edi
f0101253:	83 c4 10             	add    $0x10,%esp
f0101256:	85 c0                	test   %eax,%eax
f0101258:	75 19                	jne    f0101273 <mem_init+0x321>
f010125a:	68 13 42 10 f0       	push   $0xf0104213
f010125f:	68 3e 41 10 f0       	push   $0xf010413e
f0101264:	68 89 02 00 00       	push   $0x289
f0101269:	68 18 41 10 f0       	push   $0xf0104118
f010126e:	e8 18 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101273:	83 ec 0c             	sub    $0xc,%esp
f0101276:	6a 00                	push   $0x0
f0101278:	e8 40 fa ff ff       	call   f0100cbd <page_alloc>
f010127d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101280:	83 c4 10             	add    $0x10,%esp
f0101283:	85 c0                	test   %eax,%eax
f0101285:	75 19                	jne    f01012a0 <mem_init+0x34e>
f0101287:	68 29 42 10 f0       	push   $0xf0104229
f010128c:	68 3e 41 10 f0       	push   $0xf010413e
f0101291:	68 8a 02 00 00       	push   $0x28a
f0101296:	68 18 41 10 f0       	push   $0xf0104118
f010129b:	e8 eb ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012a0:	39 fe                	cmp    %edi,%esi
f01012a2:	75 19                	jne    f01012bd <mem_init+0x36b>
f01012a4:	68 3f 42 10 f0       	push   $0xf010423f
f01012a9:	68 3e 41 10 f0       	push   $0xf010413e
f01012ae:	68 8c 02 00 00       	push   $0x28c
f01012b3:	68 18 41 10 f0       	push   $0xf0104118
f01012b8:	e8 ce ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012c0:	39 c6                	cmp    %eax,%esi
f01012c2:	74 04                	je     f01012c8 <mem_init+0x376>
f01012c4:	39 c7                	cmp    %eax,%edi
f01012c6:	75 19                	jne    f01012e1 <mem_init+0x38f>
f01012c8:	68 2c 3b 10 f0       	push   $0xf0103b2c
f01012cd:	68 3e 41 10 f0       	push   $0xf010413e
f01012d2:	68 8d 02 00 00       	push   $0x28d
f01012d7:	68 18 41 10 f0       	push   $0xf0104118
f01012dc:	e8 aa ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01012e1:	83 ec 0c             	sub    $0xc,%esp
f01012e4:	6a 00                	push   $0x0
f01012e6:	e8 d2 f9 ff ff       	call   f0100cbd <page_alloc>
f01012eb:	83 c4 10             	add    $0x10,%esp
f01012ee:	85 c0                	test   %eax,%eax
f01012f0:	74 19                	je     f010130b <mem_init+0x3b9>
f01012f2:	68 a8 42 10 f0       	push   $0xf01042a8
f01012f7:	68 3e 41 10 f0       	push   $0xf010413e
f01012fc:	68 8e 02 00 00       	push   $0x28e
f0101301:	68 18 41 10 f0       	push   $0xf0104118
f0101306:	e8 80 ed ff ff       	call   f010008b <_panic>
f010130b:	89 f0                	mov    %esi,%eax
f010130d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101313:	c1 f8 03             	sar    $0x3,%eax
f0101316:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101319:	89 c2                	mov    %eax,%edx
f010131b:	c1 ea 0c             	shr    $0xc,%edx
f010131e:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101324:	72 12                	jb     f0101338 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101326:	50                   	push   %eax
f0101327:	68 9c 39 10 f0       	push   $0xf010399c
f010132c:	6a 52                	push   $0x52
f010132e:	68 24 41 10 f0       	push   $0xf0104124
f0101333:	e8 53 ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101338:	83 ec 04             	sub    $0x4,%esp
f010133b:	68 00 10 00 00       	push   $0x1000
f0101340:	6a 01                	push   $0x1
f0101342:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101347:	50                   	push   %eax
f0101348:	e8 1a 1d 00 00       	call   f0103067 <memset>
	page_free(pp0);
f010134d:	89 34 24             	mov    %esi,(%esp)
f0101350:	e8 d8 f9 ff ff       	call   f0100d2d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101355:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010135c:	e8 5c f9 ff ff       	call   f0100cbd <page_alloc>
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 19                	jne    f0101381 <mem_init+0x42f>
f0101368:	68 b7 42 10 f0       	push   $0xf01042b7
f010136d:	68 3e 41 10 f0       	push   $0xf010413e
f0101372:	68 93 02 00 00       	push   $0x293
f0101377:	68 18 41 10 f0       	push   $0xf0104118
f010137c:	e8 0a ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101381:	39 c6                	cmp    %eax,%esi
f0101383:	74 19                	je     f010139e <mem_init+0x44c>
f0101385:	68 d5 42 10 f0       	push   $0xf01042d5
f010138a:	68 3e 41 10 f0       	push   $0xf010413e
f010138f:	68 94 02 00 00       	push   $0x294
f0101394:	68 18 41 10 f0       	push   $0xf0104118
f0101399:	e8 ed ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010139e:	89 f0                	mov    %esi,%eax
f01013a0:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01013a6:	c1 f8 03             	sar    $0x3,%eax
f01013a9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013ac:	89 c2                	mov    %eax,%edx
f01013ae:	c1 ea 0c             	shr    $0xc,%edx
f01013b1:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01013b7:	72 12                	jb     f01013cb <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013b9:	50                   	push   %eax
f01013ba:	68 9c 39 10 f0       	push   $0xf010399c
f01013bf:	6a 52                	push   $0x52
f01013c1:	68 24 41 10 f0       	push   $0xf0104124
f01013c6:	e8 c0 ec ff ff       	call   f010008b <_panic>
f01013cb:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01013d1:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013d7:	80 38 00             	cmpb   $0x0,(%eax)
f01013da:	74 19                	je     f01013f5 <mem_init+0x4a3>
f01013dc:	68 e5 42 10 f0       	push   $0xf01042e5
f01013e1:	68 3e 41 10 f0       	push   $0xf010413e
f01013e6:	68 97 02 00 00       	push   $0x297
f01013eb:	68 18 41 10 f0       	push   $0xf0104118
f01013f0:	e8 96 ec ff ff       	call   f010008b <_panic>
f01013f5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013f8:	39 d0                	cmp    %edx,%eax
f01013fa:	75 db                	jne    f01013d7 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01013fc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013ff:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101404:	83 ec 0c             	sub    $0xc,%esp
f0101407:	56                   	push   %esi
f0101408:	e8 20 f9 ff ff       	call   f0100d2d <page_free>
	page_free(pp1);
f010140d:	89 3c 24             	mov    %edi,(%esp)
f0101410:	e8 18 f9 ff ff       	call   f0100d2d <page_free>
	page_free(pp2);
f0101415:	83 c4 04             	add    $0x4,%esp
f0101418:	ff 75 d4             	pushl  -0x2c(%ebp)
f010141b:	e8 0d f9 ff ff       	call   f0100d2d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101420:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101425:	83 c4 10             	add    $0x10,%esp
f0101428:	eb 05                	jmp    f010142f <mem_init+0x4dd>
		--nfree;
f010142a:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010142d:	8b 00                	mov    (%eax),%eax
f010142f:	85 c0                	test   %eax,%eax
f0101431:	75 f7                	jne    f010142a <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101433:	85 db                	test   %ebx,%ebx
f0101435:	74 19                	je     f0101450 <mem_init+0x4fe>
f0101437:	68 ef 42 10 f0       	push   $0xf01042ef
f010143c:	68 3e 41 10 f0       	push   $0xf010413e
f0101441:	68 a4 02 00 00       	push   $0x2a4
f0101446:	68 18 41 10 f0       	push   $0xf0104118
f010144b:	e8 3b ec ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101450:	83 ec 0c             	sub    $0xc,%esp
f0101453:	68 4c 3b 10 f0       	push   $0xf0103b4c
f0101458:	e8 21 11 00 00       	call   f010257e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010145d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101464:	e8 54 f8 ff ff       	call   f0100cbd <page_alloc>
f0101469:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010146c:	83 c4 10             	add    $0x10,%esp
f010146f:	85 c0                	test   %eax,%eax
f0101471:	75 19                	jne    f010148c <mem_init+0x53a>
f0101473:	68 fd 41 10 f0       	push   $0xf01041fd
f0101478:	68 3e 41 10 f0       	push   $0xf010413e
f010147d:	68 fd 02 00 00       	push   $0x2fd
f0101482:	68 18 41 10 f0       	push   $0xf0104118
f0101487:	e8 ff eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010148c:	83 ec 0c             	sub    $0xc,%esp
f010148f:	6a 00                	push   $0x0
f0101491:	e8 27 f8 ff ff       	call   f0100cbd <page_alloc>
f0101496:	89 c3                	mov    %eax,%ebx
f0101498:	83 c4 10             	add    $0x10,%esp
f010149b:	85 c0                	test   %eax,%eax
f010149d:	75 19                	jne    f01014b8 <mem_init+0x566>
f010149f:	68 13 42 10 f0       	push   $0xf0104213
f01014a4:	68 3e 41 10 f0       	push   $0xf010413e
f01014a9:	68 fe 02 00 00       	push   $0x2fe
f01014ae:	68 18 41 10 f0       	push   $0xf0104118
f01014b3:	e8 d3 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014b8:	83 ec 0c             	sub    $0xc,%esp
f01014bb:	6a 00                	push   $0x0
f01014bd:	e8 fb f7 ff ff       	call   f0100cbd <page_alloc>
f01014c2:	89 c6                	mov    %eax,%esi
f01014c4:	83 c4 10             	add    $0x10,%esp
f01014c7:	85 c0                	test   %eax,%eax
f01014c9:	75 19                	jne    f01014e4 <mem_init+0x592>
f01014cb:	68 29 42 10 f0       	push   $0xf0104229
f01014d0:	68 3e 41 10 f0       	push   $0xf010413e
f01014d5:	68 ff 02 00 00       	push   $0x2ff
f01014da:	68 18 41 10 f0       	push   $0xf0104118
f01014df:	e8 a7 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014e4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01014e7:	75 19                	jne    f0101502 <mem_init+0x5b0>
f01014e9:	68 3f 42 10 f0       	push   $0xf010423f
f01014ee:	68 3e 41 10 f0       	push   $0xf010413e
f01014f3:	68 02 03 00 00       	push   $0x302
f01014f8:	68 18 41 10 f0       	push   $0xf0104118
f01014fd:	e8 89 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101502:	39 c3                	cmp    %eax,%ebx
f0101504:	74 05                	je     f010150b <mem_init+0x5b9>
f0101506:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101509:	75 19                	jne    f0101524 <mem_init+0x5d2>
f010150b:	68 2c 3b 10 f0       	push   $0xf0103b2c
f0101510:	68 3e 41 10 f0       	push   $0xf010413e
f0101515:	68 03 03 00 00       	push   $0x303
f010151a:	68 18 41 10 f0       	push   $0xf0104118
f010151f:	e8 67 eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101524:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101529:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010152c:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101533:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101536:	83 ec 0c             	sub    $0xc,%esp
f0101539:	6a 00                	push   $0x0
f010153b:	e8 7d f7 ff ff       	call   f0100cbd <page_alloc>
f0101540:	83 c4 10             	add    $0x10,%esp
f0101543:	85 c0                	test   %eax,%eax
f0101545:	74 19                	je     f0101560 <mem_init+0x60e>
f0101547:	68 a8 42 10 f0       	push   $0xf01042a8
f010154c:	68 3e 41 10 f0       	push   $0xf010413e
f0101551:	68 0a 03 00 00       	push   $0x30a
f0101556:	68 18 41 10 f0       	push   $0xf0104118
f010155b:	e8 2b eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101560:	83 ec 04             	sub    $0x4,%esp
f0101563:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101566:	50                   	push   %eax
f0101567:	6a 00                	push   $0x0
f0101569:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010156f:	e8 d4 f8 ff ff       	call   f0100e48 <page_lookup>
f0101574:	83 c4 10             	add    $0x10,%esp
f0101577:	85 c0                	test   %eax,%eax
f0101579:	74 19                	je     f0101594 <mem_init+0x642>
f010157b:	68 6c 3b 10 f0       	push   $0xf0103b6c
f0101580:	68 3e 41 10 f0       	push   $0xf010413e
f0101585:	68 0d 03 00 00       	push   $0x30d
f010158a:	68 18 41 10 f0       	push   $0xf0104118
f010158f:	e8 f7 ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101594:	6a 02                	push   $0x2
f0101596:	6a 00                	push   $0x0
f0101598:	53                   	push   %ebx
f0101599:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010159f:	e8 48 f9 ff ff       	call   f0100eec <page_insert>
f01015a4:	83 c4 10             	add    $0x10,%esp
f01015a7:	85 c0                	test   %eax,%eax
f01015a9:	78 19                	js     f01015c4 <mem_init+0x672>
f01015ab:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01015b0:	68 3e 41 10 f0       	push   $0xf010413e
f01015b5:	68 10 03 00 00       	push   $0x310
f01015ba:	68 18 41 10 f0       	push   $0xf0104118
f01015bf:	e8 c7 ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01015c4:	83 ec 0c             	sub    $0xc,%esp
f01015c7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015ca:	e8 5e f7 ff ff       	call   f0100d2d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01015cf:	6a 02                	push   $0x2
f01015d1:	6a 00                	push   $0x0
f01015d3:	53                   	push   %ebx
f01015d4:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015da:	e8 0d f9 ff ff       	call   f0100eec <page_insert>
f01015df:	83 c4 20             	add    $0x20,%esp
f01015e2:	85 c0                	test   %eax,%eax
f01015e4:	74 19                	je     f01015ff <mem_init+0x6ad>
f01015e6:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01015eb:	68 3e 41 10 f0       	push   $0xf010413e
f01015f0:	68 14 03 00 00       	push   $0x314
f01015f5:	68 18 41 10 f0       	push   $0xf0104118
f01015fa:	e8 8c ea ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01015ff:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101605:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f010160a:	89 c1                	mov    %eax,%ecx
f010160c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010160f:	8b 17                	mov    (%edi),%edx
f0101611:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101617:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010161a:	29 c8                	sub    %ecx,%eax
f010161c:	c1 f8 03             	sar    $0x3,%eax
f010161f:	c1 e0 0c             	shl    $0xc,%eax
f0101622:	39 c2                	cmp    %eax,%edx
f0101624:	74 19                	je     f010163f <mem_init+0x6ed>
f0101626:	68 04 3c 10 f0       	push   $0xf0103c04
f010162b:	68 3e 41 10 f0       	push   $0xf010413e
f0101630:	68 15 03 00 00       	push   $0x315
f0101635:	68 18 41 10 f0       	push   $0xf0104118
f010163a:	e8 4c ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010163f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101644:	89 f8                	mov    %edi,%eax
f0101646:	e8 7a f2 ff ff       	call   f01008c5 <check_va2pa>
f010164b:	89 da                	mov    %ebx,%edx
f010164d:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101650:	c1 fa 03             	sar    $0x3,%edx
f0101653:	c1 e2 0c             	shl    $0xc,%edx
f0101656:	39 d0                	cmp    %edx,%eax
f0101658:	74 19                	je     f0101673 <mem_init+0x721>
f010165a:	68 2c 3c 10 f0       	push   $0xf0103c2c
f010165f:	68 3e 41 10 f0       	push   $0xf010413e
f0101664:	68 16 03 00 00       	push   $0x316
f0101669:	68 18 41 10 f0       	push   $0xf0104118
f010166e:	e8 18 ea ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101673:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101678:	74 19                	je     f0101693 <mem_init+0x741>
f010167a:	68 fa 42 10 f0       	push   $0xf01042fa
f010167f:	68 3e 41 10 f0       	push   $0xf010413e
f0101684:	68 17 03 00 00       	push   $0x317
f0101689:	68 18 41 10 f0       	push   $0xf0104118
f010168e:	e8 f8 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101693:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101696:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010169b:	74 19                	je     f01016b6 <mem_init+0x764>
f010169d:	68 0b 43 10 f0       	push   $0xf010430b
f01016a2:	68 3e 41 10 f0       	push   $0xf010413e
f01016a7:	68 18 03 00 00       	push   $0x318
f01016ac:	68 18 41 10 f0       	push   $0xf0104118
f01016b1:	e8 d5 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01016b6:	6a 02                	push   $0x2
f01016b8:	68 00 10 00 00       	push   $0x1000
f01016bd:	56                   	push   %esi
f01016be:	57                   	push   %edi
f01016bf:	e8 28 f8 ff ff       	call   f0100eec <page_insert>
f01016c4:	83 c4 10             	add    $0x10,%esp
f01016c7:	85 c0                	test   %eax,%eax
f01016c9:	74 19                	je     f01016e4 <mem_init+0x792>
f01016cb:	68 5c 3c 10 f0       	push   $0xf0103c5c
f01016d0:	68 3e 41 10 f0       	push   $0xf010413e
f01016d5:	68 1b 03 00 00       	push   $0x31b
f01016da:	68 18 41 10 f0       	push   $0xf0104118
f01016df:	e8 a7 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01016e4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01016e9:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01016ee:	e8 d2 f1 ff ff       	call   f01008c5 <check_va2pa>
f01016f3:	89 f2                	mov    %esi,%edx
f01016f5:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01016fb:	c1 fa 03             	sar    $0x3,%edx
f01016fe:	c1 e2 0c             	shl    $0xc,%edx
f0101701:	39 d0                	cmp    %edx,%eax
f0101703:	74 19                	je     f010171e <mem_init+0x7cc>
f0101705:	68 98 3c 10 f0       	push   $0xf0103c98
f010170a:	68 3e 41 10 f0       	push   $0xf010413e
f010170f:	68 1c 03 00 00       	push   $0x31c
f0101714:	68 18 41 10 f0       	push   $0xf0104118
f0101719:	e8 6d e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010171e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101723:	74 19                	je     f010173e <mem_init+0x7ec>
f0101725:	68 1c 43 10 f0       	push   $0xf010431c
f010172a:	68 3e 41 10 f0       	push   $0xf010413e
f010172f:	68 1d 03 00 00       	push   $0x31d
f0101734:	68 18 41 10 f0       	push   $0xf0104118
f0101739:	e8 4d e9 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010173e:	83 ec 0c             	sub    $0xc,%esp
f0101741:	6a 00                	push   $0x0
f0101743:	e8 75 f5 ff ff       	call   f0100cbd <page_alloc>
f0101748:	83 c4 10             	add    $0x10,%esp
f010174b:	85 c0                	test   %eax,%eax
f010174d:	74 19                	je     f0101768 <mem_init+0x816>
f010174f:	68 a8 42 10 f0       	push   $0xf01042a8
f0101754:	68 3e 41 10 f0       	push   $0xf010413e
f0101759:	68 20 03 00 00       	push   $0x320
f010175e:	68 18 41 10 f0       	push   $0xf0104118
f0101763:	e8 23 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101768:	6a 02                	push   $0x2
f010176a:	68 00 10 00 00       	push   $0x1000
f010176f:	56                   	push   %esi
f0101770:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101776:	e8 71 f7 ff ff       	call   f0100eec <page_insert>
f010177b:	83 c4 10             	add    $0x10,%esp
f010177e:	85 c0                	test   %eax,%eax
f0101780:	74 19                	je     f010179b <mem_init+0x849>
f0101782:	68 5c 3c 10 f0       	push   $0xf0103c5c
f0101787:	68 3e 41 10 f0       	push   $0xf010413e
f010178c:	68 23 03 00 00       	push   $0x323
f0101791:	68 18 41 10 f0       	push   $0xf0104118
f0101796:	e8 f0 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010179b:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017a0:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01017a5:	e8 1b f1 ff ff       	call   f01008c5 <check_va2pa>
f01017aa:	89 f2                	mov    %esi,%edx
f01017ac:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01017b2:	c1 fa 03             	sar    $0x3,%edx
f01017b5:	c1 e2 0c             	shl    $0xc,%edx
f01017b8:	39 d0                	cmp    %edx,%eax
f01017ba:	74 19                	je     f01017d5 <mem_init+0x883>
f01017bc:	68 98 3c 10 f0       	push   $0xf0103c98
f01017c1:	68 3e 41 10 f0       	push   $0xf010413e
f01017c6:	68 24 03 00 00       	push   $0x324
f01017cb:	68 18 41 10 f0       	push   $0xf0104118
f01017d0:	e8 b6 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017d5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017da:	74 19                	je     f01017f5 <mem_init+0x8a3>
f01017dc:	68 1c 43 10 f0       	push   $0xf010431c
f01017e1:	68 3e 41 10 f0       	push   $0xf010413e
f01017e6:	68 25 03 00 00       	push   $0x325
f01017eb:	68 18 41 10 f0       	push   $0xf0104118
f01017f0:	e8 96 e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01017f5:	83 ec 0c             	sub    $0xc,%esp
f01017f8:	6a 00                	push   $0x0
f01017fa:	e8 be f4 ff ff       	call   f0100cbd <page_alloc>
f01017ff:	83 c4 10             	add    $0x10,%esp
f0101802:	85 c0                	test   %eax,%eax
f0101804:	74 19                	je     f010181f <mem_init+0x8cd>
f0101806:	68 a8 42 10 f0       	push   $0xf01042a8
f010180b:	68 3e 41 10 f0       	push   $0xf010413e
f0101810:	68 29 03 00 00       	push   $0x329
f0101815:	68 18 41 10 f0       	push   $0xf0104118
f010181a:	e8 6c e8 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010181f:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f0101825:	8b 02                	mov    (%edx),%eax
f0101827:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010182c:	89 c1                	mov    %eax,%ecx
f010182e:	c1 e9 0c             	shr    $0xc,%ecx
f0101831:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0101837:	72 15                	jb     f010184e <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101839:	50                   	push   %eax
f010183a:	68 9c 39 10 f0       	push   $0xf010399c
f010183f:	68 2c 03 00 00       	push   $0x32c
f0101844:	68 18 41 10 f0       	push   $0xf0104118
f0101849:	e8 3d e8 ff ff       	call   f010008b <_panic>
f010184e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101853:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101856:	83 ec 04             	sub    $0x4,%esp
f0101859:	6a 00                	push   $0x0
f010185b:	68 00 10 00 00       	push   $0x1000
f0101860:	52                   	push   %edx
f0101861:	e8 2b f5 ff ff       	call   f0100d91 <pgdir_walk>
f0101866:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101869:	8d 51 04             	lea    0x4(%ecx),%edx
f010186c:	83 c4 10             	add    $0x10,%esp
f010186f:	39 d0                	cmp    %edx,%eax
f0101871:	74 19                	je     f010188c <mem_init+0x93a>
f0101873:	68 c8 3c 10 f0       	push   $0xf0103cc8
f0101878:	68 3e 41 10 f0       	push   $0xf010413e
f010187d:	68 2d 03 00 00       	push   $0x32d
f0101882:	68 18 41 10 f0       	push   $0xf0104118
f0101887:	e8 ff e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010188c:	6a 06                	push   $0x6
f010188e:	68 00 10 00 00       	push   $0x1000
f0101893:	56                   	push   %esi
f0101894:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010189a:	e8 4d f6 ff ff       	call   f0100eec <page_insert>
f010189f:	83 c4 10             	add    $0x10,%esp
f01018a2:	85 c0                	test   %eax,%eax
f01018a4:	74 19                	je     f01018bf <mem_init+0x96d>
f01018a6:	68 08 3d 10 f0       	push   $0xf0103d08
f01018ab:	68 3e 41 10 f0       	push   $0xf010413e
f01018b0:	68 30 03 00 00       	push   $0x330
f01018b5:	68 18 41 10 f0       	push   $0xf0104118
f01018ba:	e8 cc e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018bf:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f01018c5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018ca:	89 f8                	mov    %edi,%eax
f01018cc:	e8 f4 ef ff ff       	call   f01008c5 <check_va2pa>
f01018d1:	89 f2                	mov    %esi,%edx
f01018d3:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01018d9:	c1 fa 03             	sar    $0x3,%edx
f01018dc:	c1 e2 0c             	shl    $0xc,%edx
f01018df:	39 d0                	cmp    %edx,%eax
f01018e1:	74 19                	je     f01018fc <mem_init+0x9aa>
f01018e3:	68 98 3c 10 f0       	push   $0xf0103c98
f01018e8:	68 3e 41 10 f0       	push   $0xf010413e
f01018ed:	68 31 03 00 00       	push   $0x331
f01018f2:	68 18 41 10 f0       	push   $0xf0104118
f01018f7:	e8 8f e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018fc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101901:	74 19                	je     f010191c <mem_init+0x9ca>
f0101903:	68 1c 43 10 f0       	push   $0xf010431c
f0101908:	68 3e 41 10 f0       	push   $0xf010413e
f010190d:	68 32 03 00 00       	push   $0x332
f0101912:	68 18 41 10 f0       	push   $0xf0104118
f0101917:	e8 6f e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010191c:	83 ec 04             	sub    $0x4,%esp
f010191f:	6a 00                	push   $0x0
f0101921:	68 00 10 00 00       	push   $0x1000
f0101926:	57                   	push   %edi
f0101927:	e8 65 f4 ff ff       	call   f0100d91 <pgdir_walk>
f010192c:	83 c4 10             	add    $0x10,%esp
f010192f:	f6 00 04             	testb  $0x4,(%eax)
f0101932:	75 19                	jne    f010194d <mem_init+0x9fb>
f0101934:	68 48 3d 10 f0       	push   $0xf0103d48
f0101939:	68 3e 41 10 f0       	push   $0xf010413e
f010193e:	68 33 03 00 00       	push   $0x333
f0101943:	68 18 41 10 f0       	push   $0xf0104118
f0101948:	e8 3e e7 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010194d:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101952:	f6 00 04             	testb  $0x4,(%eax)
f0101955:	75 19                	jne    f0101970 <mem_init+0xa1e>
f0101957:	68 2d 43 10 f0       	push   $0xf010432d
f010195c:	68 3e 41 10 f0       	push   $0xf010413e
f0101961:	68 34 03 00 00       	push   $0x334
f0101966:	68 18 41 10 f0       	push   $0xf0104118
f010196b:	e8 1b e7 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101970:	6a 02                	push   $0x2
f0101972:	68 00 10 00 00       	push   $0x1000
f0101977:	56                   	push   %esi
f0101978:	50                   	push   %eax
f0101979:	e8 6e f5 ff ff       	call   f0100eec <page_insert>
f010197e:	83 c4 10             	add    $0x10,%esp
f0101981:	85 c0                	test   %eax,%eax
f0101983:	74 19                	je     f010199e <mem_init+0xa4c>
f0101985:	68 5c 3c 10 f0       	push   $0xf0103c5c
f010198a:	68 3e 41 10 f0       	push   $0xf010413e
f010198f:	68 37 03 00 00       	push   $0x337
f0101994:	68 18 41 10 f0       	push   $0xf0104118
f0101999:	e8 ed e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010199e:	83 ec 04             	sub    $0x4,%esp
f01019a1:	6a 00                	push   $0x0
f01019a3:	68 00 10 00 00       	push   $0x1000
f01019a8:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019ae:	e8 de f3 ff ff       	call   f0100d91 <pgdir_walk>
f01019b3:	83 c4 10             	add    $0x10,%esp
f01019b6:	f6 00 02             	testb  $0x2,(%eax)
f01019b9:	75 19                	jne    f01019d4 <mem_init+0xa82>
f01019bb:	68 7c 3d 10 f0       	push   $0xf0103d7c
f01019c0:	68 3e 41 10 f0       	push   $0xf010413e
f01019c5:	68 38 03 00 00       	push   $0x338
f01019ca:	68 18 41 10 f0       	push   $0xf0104118
f01019cf:	e8 b7 e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01019d4:	83 ec 04             	sub    $0x4,%esp
f01019d7:	6a 00                	push   $0x0
f01019d9:	68 00 10 00 00       	push   $0x1000
f01019de:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019e4:	e8 a8 f3 ff ff       	call   f0100d91 <pgdir_walk>
f01019e9:	83 c4 10             	add    $0x10,%esp
f01019ec:	f6 00 04             	testb  $0x4,(%eax)
f01019ef:	74 19                	je     f0101a0a <mem_init+0xab8>
f01019f1:	68 b0 3d 10 f0       	push   $0xf0103db0
f01019f6:	68 3e 41 10 f0       	push   $0xf010413e
f01019fb:	68 39 03 00 00       	push   $0x339
f0101a00:	68 18 41 10 f0       	push   $0xf0104118
f0101a05:	e8 81 e6 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101a0a:	6a 02                	push   $0x2
f0101a0c:	68 00 00 40 00       	push   $0x400000
f0101a11:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a14:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a1a:	e8 cd f4 ff ff       	call   f0100eec <page_insert>
f0101a1f:	83 c4 10             	add    $0x10,%esp
f0101a22:	85 c0                	test   %eax,%eax
f0101a24:	78 19                	js     f0101a3f <mem_init+0xaed>
f0101a26:	68 e8 3d 10 f0       	push   $0xf0103de8
f0101a2b:	68 3e 41 10 f0       	push   $0xf010413e
f0101a30:	68 3c 03 00 00       	push   $0x33c
f0101a35:	68 18 41 10 f0       	push   $0xf0104118
f0101a3a:	e8 4c e6 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a3f:	6a 02                	push   $0x2
f0101a41:	68 00 10 00 00       	push   $0x1000
f0101a46:	53                   	push   %ebx
f0101a47:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a4d:	e8 9a f4 ff ff       	call   f0100eec <page_insert>
f0101a52:	83 c4 10             	add    $0x10,%esp
f0101a55:	85 c0                	test   %eax,%eax
f0101a57:	74 19                	je     f0101a72 <mem_init+0xb20>
f0101a59:	68 20 3e 10 f0       	push   $0xf0103e20
f0101a5e:	68 3e 41 10 f0       	push   $0xf010413e
f0101a63:	68 3f 03 00 00       	push   $0x33f
f0101a68:	68 18 41 10 f0       	push   $0xf0104118
f0101a6d:	e8 19 e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a72:	83 ec 04             	sub    $0x4,%esp
f0101a75:	6a 00                	push   $0x0
f0101a77:	68 00 10 00 00       	push   $0x1000
f0101a7c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a82:	e8 0a f3 ff ff       	call   f0100d91 <pgdir_walk>
f0101a87:	83 c4 10             	add    $0x10,%esp
f0101a8a:	f6 00 04             	testb  $0x4,(%eax)
f0101a8d:	74 19                	je     f0101aa8 <mem_init+0xb56>
f0101a8f:	68 b0 3d 10 f0       	push   $0xf0103db0
f0101a94:	68 3e 41 10 f0       	push   $0xf010413e
f0101a99:	68 40 03 00 00       	push   $0x340
f0101a9e:	68 18 41 10 f0       	push   $0xf0104118
f0101aa3:	e8 e3 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101aa8:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101aae:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ab3:	89 f8                	mov    %edi,%eax
f0101ab5:	e8 0b ee ff ff       	call   f01008c5 <check_va2pa>
f0101aba:	89 c1                	mov    %eax,%ecx
f0101abc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101abf:	89 d8                	mov    %ebx,%eax
f0101ac1:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101ac7:	c1 f8 03             	sar    $0x3,%eax
f0101aca:	c1 e0 0c             	shl    $0xc,%eax
f0101acd:	39 c1                	cmp    %eax,%ecx
f0101acf:	74 19                	je     f0101aea <mem_init+0xb98>
f0101ad1:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101ad6:	68 3e 41 10 f0       	push   $0xf010413e
f0101adb:	68 43 03 00 00       	push   $0x343
f0101ae0:	68 18 41 10 f0       	push   $0xf0104118
f0101ae5:	e8 a1 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101aea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aef:	89 f8                	mov    %edi,%eax
f0101af1:	e8 cf ed ff ff       	call   f01008c5 <check_va2pa>
f0101af6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101af9:	74 19                	je     f0101b14 <mem_init+0xbc2>
f0101afb:	68 88 3e 10 f0       	push   $0xf0103e88
f0101b00:	68 3e 41 10 f0       	push   $0xf010413e
f0101b05:	68 44 03 00 00       	push   $0x344
f0101b0a:	68 18 41 10 f0       	push   $0xf0104118
f0101b0f:	e8 77 e5 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b14:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b19:	74 19                	je     f0101b34 <mem_init+0xbe2>
f0101b1b:	68 43 43 10 f0       	push   $0xf0104343
f0101b20:	68 3e 41 10 f0       	push   $0xf010413e
f0101b25:	68 46 03 00 00       	push   $0x346
f0101b2a:	68 18 41 10 f0       	push   $0xf0104118
f0101b2f:	e8 57 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b34:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b39:	74 19                	je     f0101b54 <mem_init+0xc02>
f0101b3b:	68 54 43 10 f0       	push   $0xf0104354
f0101b40:	68 3e 41 10 f0       	push   $0xf010413e
f0101b45:	68 47 03 00 00       	push   $0x347
f0101b4a:	68 18 41 10 f0       	push   $0xf0104118
f0101b4f:	e8 37 e5 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101b54:	83 ec 0c             	sub    $0xc,%esp
f0101b57:	6a 00                	push   $0x0
f0101b59:	e8 5f f1 ff ff       	call   f0100cbd <page_alloc>
f0101b5e:	83 c4 10             	add    $0x10,%esp
f0101b61:	39 c6                	cmp    %eax,%esi
f0101b63:	75 04                	jne    f0101b69 <mem_init+0xc17>
f0101b65:	85 c0                	test   %eax,%eax
f0101b67:	75 19                	jne    f0101b82 <mem_init+0xc30>
f0101b69:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101b6e:	68 3e 41 10 f0       	push   $0xf010413e
f0101b73:	68 4a 03 00 00       	push   $0x34a
f0101b78:	68 18 41 10 f0       	push   $0xf0104118
f0101b7d:	e8 09 e5 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101b82:	83 ec 08             	sub    $0x8,%esp
f0101b85:	6a 00                	push   $0x0
f0101b87:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b8d:	e8 21 f3 ff ff       	call   f0100eb3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101b92:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101b98:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b9d:	89 f8                	mov    %edi,%eax
f0101b9f:	e8 21 ed ff ff       	call   f01008c5 <check_va2pa>
f0101ba4:	83 c4 10             	add    $0x10,%esp
f0101ba7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101baa:	74 19                	je     f0101bc5 <mem_init+0xc73>
f0101bac:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101bb1:	68 3e 41 10 f0       	push   $0xf010413e
f0101bb6:	68 4e 03 00 00       	push   $0x34e
f0101bbb:	68 18 41 10 f0       	push   $0xf0104118
f0101bc0:	e8 c6 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bc5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bca:	89 f8                	mov    %edi,%eax
f0101bcc:	e8 f4 ec ff ff       	call   f01008c5 <check_va2pa>
f0101bd1:	89 da                	mov    %ebx,%edx
f0101bd3:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101bd9:	c1 fa 03             	sar    $0x3,%edx
f0101bdc:	c1 e2 0c             	shl    $0xc,%edx
f0101bdf:	39 d0                	cmp    %edx,%eax
f0101be1:	74 19                	je     f0101bfc <mem_init+0xcaa>
f0101be3:	68 88 3e 10 f0       	push   $0xf0103e88
f0101be8:	68 3e 41 10 f0       	push   $0xf010413e
f0101bed:	68 4f 03 00 00       	push   $0x34f
f0101bf2:	68 18 41 10 f0       	push   $0xf0104118
f0101bf7:	e8 8f e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101bfc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c01:	74 19                	je     f0101c1c <mem_init+0xcca>
f0101c03:	68 fa 42 10 f0       	push   $0xf01042fa
f0101c08:	68 3e 41 10 f0       	push   $0xf010413e
f0101c0d:	68 50 03 00 00       	push   $0x350
f0101c12:	68 18 41 10 f0       	push   $0xf0104118
f0101c17:	e8 6f e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c1c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c21:	74 19                	je     f0101c3c <mem_init+0xcea>
f0101c23:	68 54 43 10 f0       	push   $0xf0104354
f0101c28:	68 3e 41 10 f0       	push   $0xf010413e
f0101c2d:	68 51 03 00 00       	push   $0x351
f0101c32:	68 18 41 10 f0       	push   $0xf0104118
f0101c37:	e8 4f e4 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c3c:	6a 00                	push   $0x0
f0101c3e:	68 00 10 00 00       	push   $0x1000
f0101c43:	53                   	push   %ebx
f0101c44:	57                   	push   %edi
f0101c45:	e8 a2 f2 ff ff       	call   f0100eec <page_insert>
f0101c4a:	83 c4 10             	add    $0x10,%esp
f0101c4d:	85 c0                	test   %eax,%eax
f0101c4f:	74 19                	je     f0101c6a <mem_init+0xd18>
f0101c51:	68 00 3f 10 f0       	push   $0xf0103f00
f0101c56:	68 3e 41 10 f0       	push   $0xf010413e
f0101c5b:	68 54 03 00 00       	push   $0x354
f0101c60:	68 18 41 10 f0       	push   $0xf0104118
f0101c65:	e8 21 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101c6a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101c6f:	75 19                	jne    f0101c8a <mem_init+0xd38>
f0101c71:	68 65 43 10 f0       	push   $0xf0104365
f0101c76:	68 3e 41 10 f0       	push   $0xf010413e
f0101c7b:	68 55 03 00 00       	push   $0x355
f0101c80:	68 18 41 10 f0       	push   $0xf0104118
f0101c85:	e8 01 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101c8a:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xd56>
f0101c8f:	68 71 43 10 f0       	push   $0xf0104371
f0101c94:	68 3e 41 10 f0       	push   $0xf010413e
f0101c99:	68 56 03 00 00       	push   $0x356
f0101c9e:	68 18 41 10 f0       	push   $0xf0104118
f0101ca3:	e8 e3 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ca8:	83 ec 08             	sub    $0x8,%esp
f0101cab:	68 00 10 00 00       	push   $0x1000
f0101cb0:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101cb6:	e8 f8 f1 ff ff       	call   f0100eb3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cbb:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101cc1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc6:	89 f8                	mov    %edi,%eax
f0101cc8:	e8 f8 eb ff ff       	call   f01008c5 <check_va2pa>
f0101ccd:	83 c4 10             	add    $0x10,%esp
f0101cd0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cd3:	74 19                	je     f0101cee <mem_init+0xd9c>
f0101cd5:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101cda:	68 3e 41 10 f0       	push   $0xf010413e
f0101cdf:	68 5a 03 00 00       	push   $0x35a
f0101ce4:	68 18 41 10 f0       	push   $0xf0104118
f0101ce9:	e8 9d e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101cee:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cf3:	89 f8                	mov    %edi,%eax
f0101cf5:	e8 cb eb ff ff       	call   f01008c5 <check_va2pa>
f0101cfa:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cfd:	74 19                	je     f0101d18 <mem_init+0xdc6>
f0101cff:	68 38 3f 10 f0       	push   $0xf0103f38
f0101d04:	68 3e 41 10 f0       	push   $0xf010413e
f0101d09:	68 5b 03 00 00       	push   $0x35b
f0101d0e:	68 18 41 10 f0       	push   $0xf0104118
f0101d13:	e8 73 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101d18:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d1d:	74 19                	je     f0101d38 <mem_init+0xde6>
f0101d1f:	68 86 43 10 f0       	push   $0xf0104386
f0101d24:	68 3e 41 10 f0       	push   $0xf010413e
f0101d29:	68 5c 03 00 00       	push   $0x35c
f0101d2e:	68 18 41 10 f0       	push   $0xf0104118
f0101d33:	e8 53 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d38:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d3d:	74 19                	je     f0101d58 <mem_init+0xe06>
f0101d3f:	68 54 43 10 f0       	push   $0xf0104354
f0101d44:	68 3e 41 10 f0       	push   $0xf010413e
f0101d49:	68 5d 03 00 00       	push   $0x35d
f0101d4e:	68 18 41 10 f0       	push   $0xf0104118
f0101d53:	e8 33 e3 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101d58:	83 ec 0c             	sub    $0xc,%esp
f0101d5b:	6a 00                	push   $0x0
f0101d5d:	e8 5b ef ff ff       	call   f0100cbd <page_alloc>
f0101d62:	83 c4 10             	add    $0x10,%esp
f0101d65:	85 c0                	test   %eax,%eax
f0101d67:	74 04                	je     f0101d6d <mem_init+0xe1b>
f0101d69:	39 c3                	cmp    %eax,%ebx
f0101d6b:	74 19                	je     f0101d86 <mem_init+0xe34>
f0101d6d:	68 60 3f 10 f0       	push   $0xf0103f60
f0101d72:	68 3e 41 10 f0       	push   $0xf010413e
f0101d77:	68 60 03 00 00       	push   $0x360
f0101d7c:	68 18 41 10 f0       	push   $0xf0104118
f0101d81:	e8 05 e3 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101d86:	83 ec 0c             	sub    $0xc,%esp
f0101d89:	6a 00                	push   $0x0
f0101d8b:	e8 2d ef ff ff       	call   f0100cbd <page_alloc>
f0101d90:	83 c4 10             	add    $0x10,%esp
f0101d93:	85 c0                	test   %eax,%eax
f0101d95:	74 19                	je     f0101db0 <mem_init+0xe5e>
f0101d97:	68 a8 42 10 f0       	push   $0xf01042a8
f0101d9c:	68 3e 41 10 f0       	push   $0xf010413e
f0101da1:	68 63 03 00 00       	push   $0x363
f0101da6:	68 18 41 10 f0       	push   $0xf0104118
f0101dab:	e8 db e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101db0:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101db6:	8b 11                	mov    (%ecx),%edx
f0101db8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101dbe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc1:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101dc7:	c1 f8 03             	sar    $0x3,%eax
f0101dca:	c1 e0 0c             	shl    $0xc,%eax
f0101dcd:	39 c2                	cmp    %eax,%edx
f0101dcf:	74 19                	je     f0101dea <mem_init+0xe98>
f0101dd1:	68 04 3c 10 f0       	push   $0xf0103c04
f0101dd6:	68 3e 41 10 f0       	push   $0xf010413e
f0101ddb:	68 66 03 00 00       	push   $0x366
f0101de0:	68 18 41 10 f0       	push   $0xf0104118
f0101de5:	e8 a1 e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101dea:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101df0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101df8:	74 19                	je     f0101e13 <mem_init+0xec1>
f0101dfa:	68 0b 43 10 f0       	push   $0xf010430b
f0101dff:	68 3e 41 10 f0       	push   $0xf010413e
f0101e04:	68 68 03 00 00       	push   $0x368
f0101e09:	68 18 41 10 f0       	push   $0xf0104118
f0101e0e:	e8 78 e2 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101e13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e16:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e1c:	83 ec 0c             	sub    $0xc,%esp
f0101e1f:	50                   	push   %eax
f0101e20:	e8 08 ef ff ff       	call   f0100d2d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e25:	83 c4 0c             	add    $0xc,%esp
f0101e28:	6a 01                	push   $0x1
f0101e2a:	68 00 10 40 00       	push   $0x401000
f0101e2f:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101e35:	e8 57 ef ff ff       	call   f0100d91 <pgdir_walk>
f0101e3a:	89 c7                	mov    %eax,%edi
f0101e3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e3f:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101e44:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e47:	8b 40 04             	mov    0x4(%eax),%eax
f0101e4a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e4f:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101e55:	89 c2                	mov    %eax,%edx
f0101e57:	c1 ea 0c             	shr    $0xc,%edx
f0101e5a:	83 c4 10             	add    $0x10,%esp
f0101e5d:	39 ca                	cmp    %ecx,%edx
f0101e5f:	72 15                	jb     f0101e76 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e61:	50                   	push   %eax
f0101e62:	68 9c 39 10 f0       	push   $0xf010399c
f0101e67:	68 6f 03 00 00       	push   $0x36f
f0101e6c:	68 18 41 10 f0       	push   $0xf0104118
f0101e71:	e8 15 e2 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101e76:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101e7b:	39 c7                	cmp    %eax,%edi
f0101e7d:	74 19                	je     f0101e98 <mem_init+0xf46>
f0101e7f:	68 97 43 10 f0       	push   $0xf0104397
f0101e84:	68 3e 41 10 f0       	push   $0xf010413e
f0101e89:	68 70 03 00 00       	push   $0x370
f0101e8e:	68 18 41 10 f0       	push   $0xf0104118
f0101e93:	e8 f3 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101e98:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101e9b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ea2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101eab:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101eb1:	c1 f8 03             	sar    $0x3,%eax
f0101eb4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101eb7:	89 c2                	mov    %eax,%edx
f0101eb9:	c1 ea 0c             	shr    $0xc,%edx
f0101ebc:	39 d1                	cmp    %edx,%ecx
f0101ebe:	77 12                	ja     f0101ed2 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ec0:	50                   	push   %eax
f0101ec1:	68 9c 39 10 f0       	push   $0xf010399c
f0101ec6:	6a 52                	push   $0x52
f0101ec8:	68 24 41 10 f0       	push   $0xf0104124
f0101ecd:	e8 b9 e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ed2:	83 ec 04             	sub    $0x4,%esp
f0101ed5:	68 00 10 00 00       	push   $0x1000
f0101eda:	68 ff 00 00 00       	push   $0xff
f0101edf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ee4:	50                   	push   %eax
f0101ee5:	e8 7d 11 00 00       	call   f0103067 <memset>
	page_free(pp0);
f0101eea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101eed:	89 3c 24             	mov    %edi,(%esp)
f0101ef0:	e8 38 ee ff ff       	call   f0100d2d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ef5:	83 c4 0c             	add    $0xc,%esp
f0101ef8:	6a 01                	push   $0x1
f0101efa:	6a 00                	push   $0x0
f0101efc:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101f02:	e8 8a ee ff ff       	call   f0100d91 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f07:	89 fa                	mov    %edi,%edx
f0101f09:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101f0f:	c1 fa 03             	sar    $0x3,%edx
f0101f12:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f15:	89 d0                	mov    %edx,%eax
f0101f17:	c1 e8 0c             	shr    $0xc,%eax
f0101f1a:	83 c4 10             	add    $0x10,%esp
f0101f1d:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0101f23:	72 12                	jb     f0101f37 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f25:	52                   	push   %edx
f0101f26:	68 9c 39 10 f0       	push   $0xf010399c
f0101f2b:	6a 52                	push   $0x52
f0101f2d:	68 24 41 10 f0       	push   $0xf0104124
f0101f32:	e8 54 e1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101f37:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f3d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f40:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f46:	f6 00 01             	testb  $0x1,(%eax)
f0101f49:	74 19                	je     f0101f64 <mem_init+0x1012>
f0101f4b:	68 af 43 10 f0       	push   $0xf01043af
f0101f50:	68 3e 41 10 f0       	push   $0xf010413e
f0101f55:	68 7a 03 00 00       	push   $0x37a
f0101f5a:	68 18 41 10 f0       	push   $0xf0104118
f0101f5f:	e8 27 e1 ff ff       	call   f010008b <_panic>
f0101f64:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101f67:	39 d0                	cmp    %edx,%eax
f0101f69:	75 db                	jne    f0101f46 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101f6b:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101f70:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f76:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f79:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101f7f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101f82:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101f88:	83 ec 0c             	sub    $0xc,%esp
f0101f8b:	50                   	push   %eax
f0101f8c:	e8 9c ed ff ff       	call   f0100d2d <page_free>
	page_free(pp1);
f0101f91:	89 1c 24             	mov    %ebx,(%esp)
f0101f94:	e8 94 ed ff ff       	call   f0100d2d <page_free>
	page_free(pp2);
f0101f99:	89 34 24             	mov    %esi,(%esp)
f0101f9c:	e8 8c ed ff ff       	call   f0100d2d <page_free>

	cprintf("check_page() succeeded!\n");
f0101fa1:	c7 04 24 c6 43 10 f0 	movl   $0xf01043c6,(%esp)
f0101fa8:	e8 d1 05 00 00       	call   f010257e <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0101fad:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0101fb3:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101fb8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fbb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0101fc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101fc7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101fca:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101fd0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101fd3:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101fd6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101fdb:	eb 55                	jmp    f0102032 <mem_init+0x10e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101fdd:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0101fe3:	89 f0                	mov    %esi,%eax
f0101fe5:	e8 db e8 ff ff       	call   f01008c5 <check_va2pa>
f0101fea:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0101ff1:	77 15                	ja     f0102008 <mem_init+0x10b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101ff3:	57                   	push   %edi
f0101ff4:	68 84 3a 10 f0       	push   $0xf0103a84
f0101ff9:	68 bc 02 00 00       	push   $0x2bc
f0101ffe:	68 18 41 10 f0       	push   $0xf0104118
f0102003:	e8 83 e0 ff ff       	call   f010008b <_panic>
f0102008:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010200f:	39 d0                	cmp    %edx,%eax
f0102011:	74 19                	je     f010202c <mem_init+0x10da>
f0102013:	68 84 3f 10 f0       	push   $0xf0103f84
f0102018:	68 3e 41 10 f0       	push   $0xf010413e
f010201d:	68 bc 02 00 00       	push   $0x2bc
f0102022:	68 18 41 10 f0       	push   $0xf0104118
f0102027:	e8 5f e0 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010202c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102032:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102035:	77 a6                	ja     f0101fdd <mem_init+0x108b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102037:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010203a:	c1 e7 0c             	shl    $0xc,%edi
f010203d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102042:	eb 30                	jmp    f0102074 <mem_init+0x1122>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102044:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010204a:	89 f0                	mov    %esi,%eax
f010204c:	e8 74 e8 ff ff       	call   f01008c5 <check_va2pa>
f0102051:	39 c3                	cmp    %eax,%ebx
f0102053:	74 19                	je     f010206e <mem_init+0x111c>
f0102055:	68 b8 3f 10 f0       	push   $0xf0103fb8
f010205a:	68 3e 41 10 f0       	push   $0xf010413e
f010205f:	68 c1 02 00 00       	push   $0x2c1
f0102064:	68 18 41 10 f0       	push   $0xf0104118
f0102069:	e8 1d e0 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010206e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102074:	39 fb                	cmp    %edi,%ebx
f0102076:	72 cc                	jb     f0102044 <mem_init+0x10f2>
f0102078:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010207d:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102082:	89 da                	mov    %ebx,%edx
f0102084:	89 f0                	mov    %esi,%eax
f0102086:	e8 3a e8 ff ff       	call   f01008c5 <check_va2pa>
f010208b:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102091:	77 19                	ja     f01020ac <mem_init+0x115a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102093:	68 00 c0 10 f0       	push   $0xf010c000
f0102098:	68 84 3a 10 f0       	push   $0xf0103a84
f010209d:	68 c5 02 00 00       	push   $0x2c5
f01020a2:	68 18 41 10 f0       	push   $0xf0104118
f01020a7:	e8 df df ff ff       	call   f010008b <_panic>
f01020ac:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f01020b2:	39 d0                	cmp    %edx,%eax
f01020b4:	74 19                	je     f01020cf <mem_init+0x117d>
f01020b6:	68 e0 3f 10 f0       	push   $0xf0103fe0
f01020bb:	68 3e 41 10 f0       	push   $0xf010413e
f01020c0:	68 c5 02 00 00       	push   $0x2c5
f01020c5:	68 18 41 10 f0       	push   $0xf0104118
f01020ca:	e8 bc df ff ff       	call   f010008b <_panic>
f01020cf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01020d5:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01020db:	75 a5                	jne    f0102082 <mem_init+0x1130>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01020dd:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01020e2:	89 f0                	mov    %esi,%eax
f01020e4:	e8 dc e7 ff ff       	call   f01008c5 <check_va2pa>
f01020e9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ec:	74 51                	je     f010213f <mem_init+0x11ed>
f01020ee:	68 28 40 10 f0       	push   $0xf0104028
f01020f3:	68 3e 41 10 f0       	push   $0xf010413e
f01020f8:	68 c6 02 00 00       	push   $0x2c6
f01020fd:	68 18 41 10 f0       	push   $0xf0104118
f0102102:	e8 84 df ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102107:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f010210c:	72 36                	jb     f0102144 <mem_init+0x11f2>
f010210e:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102113:	76 07                	jbe    f010211c <mem_init+0x11ca>
f0102115:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010211a:	75 28                	jne    f0102144 <mem_init+0x11f2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010211c:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102120:	0f 85 83 00 00 00    	jne    f01021a9 <mem_init+0x1257>
f0102126:	68 df 43 10 f0       	push   $0xf01043df
f010212b:	68 3e 41 10 f0       	push   $0xf010413e
f0102130:	68 ce 02 00 00       	push   $0x2ce
f0102135:	68 18 41 10 f0       	push   $0xf0104118
f010213a:	e8 4c df ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010213f:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102144:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102149:	76 3f                	jbe    f010218a <mem_init+0x1238>
				assert(pgdir[i] & PTE_P);
f010214b:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010214e:	f6 c2 01             	test   $0x1,%dl
f0102151:	75 19                	jne    f010216c <mem_init+0x121a>
f0102153:	68 df 43 10 f0       	push   $0xf01043df
f0102158:	68 3e 41 10 f0       	push   $0xf010413e
f010215d:	68 d2 02 00 00       	push   $0x2d2
f0102162:	68 18 41 10 f0       	push   $0xf0104118
f0102167:	e8 1f df ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010216c:	f6 c2 02             	test   $0x2,%dl
f010216f:	75 38                	jne    f01021a9 <mem_init+0x1257>
f0102171:	68 f0 43 10 f0       	push   $0xf01043f0
f0102176:	68 3e 41 10 f0       	push   $0xf010413e
f010217b:	68 d3 02 00 00       	push   $0x2d3
f0102180:	68 18 41 10 f0       	push   $0xf0104118
f0102185:	e8 01 df ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f010218a:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010218e:	74 19                	je     f01021a9 <mem_init+0x1257>
f0102190:	68 01 44 10 f0       	push   $0xf0104401
f0102195:	68 3e 41 10 f0       	push   $0xf010413e
f010219a:	68 d5 02 00 00       	push   $0x2d5
f010219f:	68 18 41 10 f0       	push   $0xf0104118
f01021a4:	e8 e2 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01021a9:	83 c0 01             	add    $0x1,%eax
f01021ac:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01021b1:	0f 86 50 ff ff ff    	jbe    f0102107 <mem_init+0x11b5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01021b7:	83 ec 0c             	sub    $0xc,%esp
f01021ba:	68 58 40 10 f0       	push   $0xf0104058
f01021bf:	e8 ba 03 00 00       	call   f010257e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01021c4:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021c9:	83 c4 10             	add    $0x10,%esp
f01021cc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021d1:	77 15                	ja     f01021e8 <mem_init+0x1296>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021d3:	50                   	push   %eax
f01021d4:	68 84 3a 10 f0       	push   $0xf0103a84
f01021d9:	68 d2 00 00 00       	push   $0xd2
f01021de:	68 18 41 10 f0       	push   $0xf0104118
f01021e3:	e8 a3 de ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01021e8:	05 00 00 00 10       	add    $0x10000000,%eax
f01021ed:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01021f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01021f5:	e8 2f e7 ff ff       	call   f0100929 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01021fa:	0f 20 c0             	mov    %cr0,%eax
f01021fd:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102200:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102205:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102208:	83 ec 0c             	sub    $0xc,%esp
f010220b:	6a 00                	push   $0x0
f010220d:	e8 ab ea ff ff       	call   f0100cbd <page_alloc>
f0102212:	89 c3                	mov    %eax,%ebx
f0102214:	83 c4 10             	add    $0x10,%esp
f0102217:	85 c0                	test   %eax,%eax
f0102219:	75 19                	jne    f0102234 <mem_init+0x12e2>
f010221b:	68 fd 41 10 f0       	push   $0xf01041fd
f0102220:	68 3e 41 10 f0       	push   $0xf010413e
f0102225:	68 95 03 00 00       	push   $0x395
f010222a:	68 18 41 10 f0       	push   $0xf0104118
f010222f:	e8 57 de ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102234:	83 ec 0c             	sub    $0xc,%esp
f0102237:	6a 00                	push   $0x0
f0102239:	e8 7f ea ff ff       	call   f0100cbd <page_alloc>
f010223e:	89 c7                	mov    %eax,%edi
f0102240:	83 c4 10             	add    $0x10,%esp
f0102243:	85 c0                	test   %eax,%eax
f0102245:	75 19                	jne    f0102260 <mem_init+0x130e>
f0102247:	68 13 42 10 f0       	push   $0xf0104213
f010224c:	68 3e 41 10 f0       	push   $0xf010413e
f0102251:	68 96 03 00 00       	push   $0x396
f0102256:	68 18 41 10 f0       	push   $0xf0104118
f010225b:	e8 2b de ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102260:	83 ec 0c             	sub    $0xc,%esp
f0102263:	6a 00                	push   $0x0
f0102265:	e8 53 ea ff ff       	call   f0100cbd <page_alloc>
f010226a:	89 c6                	mov    %eax,%esi
f010226c:	83 c4 10             	add    $0x10,%esp
f010226f:	85 c0                	test   %eax,%eax
f0102271:	75 19                	jne    f010228c <mem_init+0x133a>
f0102273:	68 29 42 10 f0       	push   $0xf0104229
f0102278:	68 3e 41 10 f0       	push   $0xf010413e
f010227d:	68 97 03 00 00       	push   $0x397
f0102282:	68 18 41 10 f0       	push   $0xf0104118
f0102287:	e8 ff dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010228c:	83 ec 0c             	sub    $0xc,%esp
f010228f:	53                   	push   %ebx
f0102290:	e8 98 ea ff ff       	call   f0100d2d <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102295:	89 f8                	mov    %edi,%eax
f0102297:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010229d:	c1 f8 03             	sar    $0x3,%eax
f01022a0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022a3:	89 c2                	mov    %eax,%edx
f01022a5:	c1 ea 0c             	shr    $0xc,%edx
f01022a8:	83 c4 10             	add    $0x10,%esp
f01022ab:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01022b1:	72 12                	jb     f01022c5 <mem_init+0x1373>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022b3:	50                   	push   %eax
f01022b4:	68 9c 39 10 f0       	push   $0xf010399c
f01022b9:	6a 52                	push   $0x52
f01022bb:	68 24 41 10 f0       	push   $0xf0104124
f01022c0:	e8 c6 dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01022c5:	83 ec 04             	sub    $0x4,%esp
f01022c8:	68 00 10 00 00       	push   $0x1000
f01022cd:	6a 01                	push   $0x1
f01022cf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022d4:	50                   	push   %eax
f01022d5:	e8 8d 0d 00 00       	call   f0103067 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022da:	89 f0                	mov    %esi,%eax
f01022dc:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01022e2:	c1 f8 03             	sar    $0x3,%eax
f01022e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022e8:	89 c2                	mov    %eax,%edx
f01022ea:	c1 ea 0c             	shr    $0xc,%edx
f01022ed:	83 c4 10             	add    $0x10,%esp
f01022f0:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01022f6:	72 12                	jb     f010230a <mem_init+0x13b8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022f8:	50                   	push   %eax
f01022f9:	68 9c 39 10 f0       	push   $0xf010399c
f01022fe:	6a 52                	push   $0x52
f0102300:	68 24 41 10 f0       	push   $0xf0104124
f0102305:	e8 81 dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010230a:	83 ec 04             	sub    $0x4,%esp
f010230d:	68 00 10 00 00       	push   $0x1000
f0102312:	6a 02                	push   $0x2
f0102314:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102319:	50                   	push   %eax
f010231a:	e8 48 0d 00 00       	call   f0103067 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010231f:	6a 02                	push   $0x2
f0102321:	68 00 10 00 00       	push   $0x1000
f0102326:	57                   	push   %edi
f0102327:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010232d:	e8 ba eb ff ff       	call   f0100eec <page_insert>
	assert(pp1->pp_ref == 1);
f0102332:	83 c4 20             	add    $0x20,%esp
f0102335:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010233a:	74 19                	je     f0102355 <mem_init+0x1403>
f010233c:	68 fa 42 10 f0       	push   $0xf01042fa
f0102341:	68 3e 41 10 f0       	push   $0xf010413e
f0102346:	68 9c 03 00 00       	push   $0x39c
f010234b:	68 18 41 10 f0       	push   $0xf0104118
f0102350:	e8 36 dd ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102355:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010235c:	01 01 01 
f010235f:	74 19                	je     f010237a <mem_init+0x1428>
f0102361:	68 78 40 10 f0       	push   $0xf0104078
f0102366:	68 3e 41 10 f0       	push   $0xf010413e
f010236b:	68 9d 03 00 00       	push   $0x39d
f0102370:	68 18 41 10 f0       	push   $0xf0104118
f0102375:	e8 11 dd ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010237a:	6a 02                	push   $0x2
f010237c:	68 00 10 00 00       	push   $0x1000
f0102381:	56                   	push   %esi
f0102382:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102388:	e8 5f eb ff ff       	call   f0100eec <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010238d:	83 c4 10             	add    $0x10,%esp
f0102390:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102397:	02 02 02 
f010239a:	74 19                	je     f01023b5 <mem_init+0x1463>
f010239c:	68 9c 40 10 f0       	push   $0xf010409c
f01023a1:	68 3e 41 10 f0       	push   $0xf010413e
f01023a6:	68 9f 03 00 00       	push   $0x39f
f01023ab:	68 18 41 10 f0       	push   $0xf0104118
f01023b0:	e8 d6 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01023b5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01023ba:	74 19                	je     f01023d5 <mem_init+0x1483>
f01023bc:	68 1c 43 10 f0       	push   $0xf010431c
f01023c1:	68 3e 41 10 f0       	push   $0xf010413e
f01023c6:	68 a0 03 00 00       	push   $0x3a0
f01023cb:	68 18 41 10 f0       	push   $0xf0104118
f01023d0:	e8 b6 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01023d5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01023da:	74 19                	je     f01023f5 <mem_init+0x14a3>
f01023dc:	68 86 43 10 f0       	push   $0xf0104386
f01023e1:	68 3e 41 10 f0       	push   $0xf010413e
f01023e6:	68 a1 03 00 00       	push   $0x3a1
f01023eb:	68 18 41 10 f0       	push   $0xf0104118
f01023f0:	e8 96 dc ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01023f5:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01023fc:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023ff:	89 f0                	mov    %esi,%eax
f0102401:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102407:	c1 f8 03             	sar    $0x3,%eax
f010240a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010240d:	89 c2                	mov    %eax,%edx
f010240f:	c1 ea 0c             	shr    $0xc,%edx
f0102412:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0102418:	72 12                	jb     f010242c <mem_init+0x14da>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010241a:	50                   	push   %eax
f010241b:	68 9c 39 10 f0       	push   $0xf010399c
f0102420:	6a 52                	push   $0x52
f0102422:	68 24 41 10 f0       	push   $0xf0104124
f0102427:	e8 5f dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010242c:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102433:	03 03 03 
f0102436:	74 19                	je     f0102451 <mem_init+0x14ff>
f0102438:	68 c0 40 10 f0       	push   $0xf01040c0
f010243d:	68 3e 41 10 f0       	push   $0xf010413e
f0102442:	68 a3 03 00 00       	push   $0x3a3
f0102447:	68 18 41 10 f0       	push   $0xf0104118
f010244c:	e8 3a dc ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102451:	83 ec 08             	sub    $0x8,%esp
f0102454:	68 00 10 00 00       	push   $0x1000
f0102459:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010245f:	e8 4f ea ff ff       	call   f0100eb3 <page_remove>
	assert(pp2->pp_ref == 0);
f0102464:	83 c4 10             	add    $0x10,%esp
f0102467:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010246c:	74 19                	je     f0102487 <mem_init+0x1535>
f010246e:	68 54 43 10 f0       	push   $0xf0104354
f0102473:	68 3e 41 10 f0       	push   $0xf010413e
f0102478:	68 a5 03 00 00       	push   $0x3a5
f010247d:	68 18 41 10 f0       	push   $0xf0104118
f0102482:	e8 04 dc ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102487:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f010248d:	8b 11                	mov    (%ecx),%edx
f010248f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102495:	89 d8                	mov    %ebx,%eax
f0102497:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010249d:	c1 f8 03             	sar    $0x3,%eax
f01024a0:	c1 e0 0c             	shl    $0xc,%eax
f01024a3:	39 c2                	cmp    %eax,%edx
f01024a5:	74 19                	je     f01024c0 <mem_init+0x156e>
f01024a7:	68 04 3c 10 f0       	push   $0xf0103c04
f01024ac:	68 3e 41 10 f0       	push   $0xf010413e
f01024b1:	68 a8 03 00 00       	push   $0x3a8
f01024b6:	68 18 41 10 f0       	push   $0xf0104118
f01024bb:	e8 cb db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01024c0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01024c6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024cb:	74 19                	je     f01024e6 <mem_init+0x1594>
f01024cd:	68 0b 43 10 f0       	push   $0xf010430b
f01024d2:	68 3e 41 10 f0       	push   $0xf010413e
f01024d7:	68 aa 03 00 00       	push   $0x3aa
f01024dc:	68 18 41 10 f0       	push   $0xf0104118
f01024e1:	e8 a5 db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01024e6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01024ec:	83 ec 0c             	sub    $0xc,%esp
f01024ef:	53                   	push   %ebx
f01024f0:	e8 38 e8 ff ff       	call   f0100d2d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01024f5:	c7 04 24 ec 40 10 f0 	movl   $0xf01040ec,(%esp)
f01024fc:	e8 7d 00 00 00       	call   f010257e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102501:	83 c4 10             	add    $0x10,%esp
f0102504:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102507:	5b                   	pop    %ebx
f0102508:	5e                   	pop    %esi
f0102509:	5f                   	pop    %edi
f010250a:	5d                   	pop    %ebp
f010250b:	c3                   	ret    

f010250c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010250c:	55                   	push   %ebp
f010250d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010250f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102512:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102515:	5d                   	pop    %ebp
f0102516:	c3                   	ret    

f0102517 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102517:	55                   	push   %ebp
f0102518:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010251a:	ba 70 00 00 00       	mov    $0x70,%edx
f010251f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102522:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102523:	ba 71 00 00 00       	mov    $0x71,%edx
f0102528:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102529:	0f b6 c0             	movzbl %al,%eax
}
f010252c:	5d                   	pop    %ebp
f010252d:	c3                   	ret    

f010252e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010252e:	55                   	push   %ebp
f010252f:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102531:	ba 70 00 00 00       	mov    $0x70,%edx
f0102536:	8b 45 08             	mov    0x8(%ebp),%eax
f0102539:	ee                   	out    %al,(%dx)
f010253a:	ba 71 00 00 00       	mov    $0x71,%edx
f010253f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102542:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102543:	5d                   	pop    %ebp
f0102544:	c3                   	ret    

f0102545 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102545:	55                   	push   %ebp
f0102546:	89 e5                	mov    %esp,%ebp
f0102548:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010254b:	ff 75 08             	pushl  0x8(%ebp)
f010254e:	e8 ad e0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0102553:	83 c4 10             	add    $0x10,%esp
f0102556:	c9                   	leave  
f0102557:	c3                   	ret    

f0102558 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102558:	55                   	push   %ebp
f0102559:	89 e5                	mov    %esp,%ebp
f010255b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010255e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102565:	ff 75 0c             	pushl  0xc(%ebp)
f0102568:	ff 75 08             	pushl  0x8(%ebp)
f010256b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010256e:	50                   	push   %eax
f010256f:	68 45 25 10 f0       	push   $0xf0102545
f0102574:	e8 c9 03 00 00       	call   f0102942 <vprintfmt>
	return cnt;
}
f0102579:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010257c:	c9                   	leave  
f010257d:	c3                   	ret    

f010257e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010257e:	55                   	push   %ebp
f010257f:	89 e5                	mov    %esp,%ebp
f0102581:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102584:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102587:	50                   	push   %eax
f0102588:	ff 75 08             	pushl  0x8(%ebp)
f010258b:	e8 c8 ff ff ff       	call   f0102558 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102590:	c9                   	leave  
f0102591:	c3                   	ret    

f0102592 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102592:	55                   	push   %ebp
f0102593:	89 e5                	mov    %esp,%ebp
f0102595:	57                   	push   %edi
f0102596:	56                   	push   %esi
f0102597:	53                   	push   %ebx
f0102598:	83 ec 14             	sub    $0x14,%esp
f010259b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010259e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01025a1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01025a4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01025a7:	8b 1a                	mov    (%edx),%ebx
f01025a9:	8b 01                	mov    (%ecx),%eax
f01025ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01025ae:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01025b5:	eb 7f                	jmp    f0102636 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01025b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01025ba:	01 d8                	add    %ebx,%eax
f01025bc:	89 c6                	mov    %eax,%esi
f01025be:	c1 ee 1f             	shr    $0x1f,%esi
f01025c1:	01 c6                	add    %eax,%esi
f01025c3:	d1 fe                	sar    %esi
f01025c5:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01025c8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01025cb:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01025ce:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01025d0:	eb 03                	jmp    f01025d5 <stab_binsearch+0x43>
			m--;
f01025d2:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01025d5:	39 c3                	cmp    %eax,%ebx
f01025d7:	7f 0d                	jg     f01025e6 <stab_binsearch+0x54>
f01025d9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01025dd:	83 ea 0c             	sub    $0xc,%edx
f01025e0:	39 f9                	cmp    %edi,%ecx
f01025e2:	75 ee                	jne    f01025d2 <stab_binsearch+0x40>
f01025e4:	eb 05                	jmp    f01025eb <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01025e6:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01025e9:	eb 4b                	jmp    f0102636 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01025eb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01025ee:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01025f1:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01025f5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01025f8:	76 11                	jbe    f010260b <stab_binsearch+0x79>
			*region_left = m;
f01025fa:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01025fd:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01025ff:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102602:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102609:	eb 2b                	jmp    f0102636 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010260b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010260e:	73 14                	jae    f0102624 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102610:	83 e8 01             	sub    $0x1,%eax
f0102613:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102616:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102619:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010261b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102622:	eb 12                	jmp    f0102636 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102624:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102627:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102629:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010262d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010262f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102636:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102639:	0f 8e 78 ff ff ff    	jle    f01025b7 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010263f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102643:	75 0f                	jne    f0102654 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102645:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102648:	8b 00                	mov    (%eax),%eax
f010264a:	83 e8 01             	sub    $0x1,%eax
f010264d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102650:	89 06                	mov    %eax,(%esi)
f0102652:	eb 2c                	jmp    f0102680 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102654:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102657:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102659:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010265c:	8b 0e                	mov    (%esi),%ecx
f010265e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102661:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102664:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102667:	eb 03                	jmp    f010266c <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102669:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010266c:	39 c8                	cmp    %ecx,%eax
f010266e:	7e 0b                	jle    f010267b <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102670:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102674:	83 ea 0c             	sub    $0xc,%edx
f0102677:	39 df                	cmp    %ebx,%edi
f0102679:	75 ee                	jne    f0102669 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010267b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010267e:	89 06                	mov    %eax,(%esi)
	}
}
f0102680:	83 c4 14             	add    $0x14,%esp
f0102683:	5b                   	pop    %ebx
f0102684:	5e                   	pop    %esi
f0102685:	5f                   	pop    %edi
f0102686:	5d                   	pop    %ebp
f0102687:	c3                   	ret    

f0102688 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102688:	55                   	push   %ebp
f0102689:	89 e5                	mov    %esp,%ebp
f010268b:	57                   	push   %edi
f010268c:	56                   	push   %esi
f010268d:	53                   	push   %ebx
f010268e:	83 ec 1c             	sub    $0x1c,%esp
f0102691:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102694:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102697:	c7 06 0f 44 10 f0    	movl   $0xf010440f,(%esi)
	info->eip_line = 0;
f010269d:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01026a4:	c7 46 08 0f 44 10 f0 	movl   $0xf010440f,0x8(%esi)
	info->eip_fn_namelen = 9;
f01026ab:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01026b2:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01026b5:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01026bc:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01026c2:	76 11                	jbe    f01026d5 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01026c4:	b8 5c ba 10 f0       	mov    $0xf010ba5c,%eax
f01026c9:	3d 39 9d 10 f0       	cmp    $0xf0109d39,%eax
f01026ce:	77 19                	ja     f01026e9 <debuginfo_eip+0x61>
f01026d0:	e9 62 01 00 00       	jmp    f0102837 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01026d5:	83 ec 04             	sub    $0x4,%esp
f01026d8:	68 19 44 10 f0       	push   $0xf0104419
f01026dd:	6a 7f                	push   $0x7f
f01026df:	68 26 44 10 f0       	push   $0xf0104426
f01026e4:	e8 a2 d9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01026e9:	80 3d 5b ba 10 f0 00 	cmpb   $0x0,0xf010ba5b
f01026f0:	0f 85 48 01 00 00    	jne    f010283e <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01026f6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01026fd:	b8 38 9d 10 f0       	mov    $0xf0109d38,%eax
f0102702:	2d 44 46 10 f0       	sub    $0xf0104644,%eax
f0102707:	c1 f8 02             	sar    $0x2,%eax
f010270a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102710:	83 e8 01             	sub    $0x1,%eax
f0102713:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102716:	83 ec 08             	sub    $0x8,%esp
f0102719:	57                   	push   %edi
f010271a:	6a 64                	push   $0x64
f010271c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010271f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102722:	b8 44 46 10 f0       	mov    $0xf0104644,%eax
f0102727:	e8 66 fe ff ff       	call   f0102592 <stab_binsearch>
	if (lfile == 0)
f010272c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010272f:	83 c4 10             	add    $0x10,%esp
f0102732:	85 c0                	test   %eax,%eax
f0102734:	0f 84 0b 01 00 00    	je     f0102845 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010273a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010273d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102740:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102743:	83 ec 08             	sub    $0x8,%esp
f0102746:	57                   	push   %edi
f0102747:	6a 24                	push   $0x24
f0102749:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010274c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010274f:	b8 44 46 10 f0       	mov    $0xf0104644,%eax
f0102754:	e8 39 fe ff ff       	call   f0102592 <stab_binsearch>

	if (lfun <= rfun) {
f0102759:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010275c:	83 c4 10             	add    $0x10,%esp
f010275f:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0102762:	7f 31                	jg     f0102795 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102764:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102767:	c1 e0 02             	shl    $0x2,%eax
f010276a:	8d 90 44 46 10 f0    	lea    -0xfefb9bc(%eax),%edx
f0102770:	8b 88 44 46 10 f0    	mov    -0xfefb9bc(%eax),%ecx
f0102776:	b8 5c ba 10 f0       	mov    $0xf010ba5c,%eax
f010277b:	2d 39 9d 10 f0       	sub    $0xf0109d39,%eax
f0102780:	39 c1                	cmp    %eax,%ecx
f0102782:	73 09                	jae    f010278d <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102784:	81 c1 39 9d 10 f0    	add    $0xf0109d39,%ecx
f010278a:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010278d:	8b 42 08             	mov    0x8(%edx),%eax
f0102790:	89 46 10             	mov    %eax,0x10(%esi)
f0102793:	eb 06                	jmp    f010279b <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102795:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102798:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010279b:	83 ec 08             	sub    $0x8,%esp
f010279e:	6a 3a                	push   $0x3a
f01027a0:	ff 76 08             	pushl  0x8(%esi)
f01027a3:	e8 a3 08 00 00       	call   f010304b <strfind>
f01027a8:	2b 46 08             	sub    0x8(%esi),%eax
f01027ab:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01027ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01027b1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01027b4:	8d 04 85 44 46 10 f0 	lea    -0xfefb9bc(,%eax,4),%eax
f01027bb:	83 c4 10             	add    $0x10,%esp
f01027be:	eb 06                	jmp    f01027c6 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01027c0:	83 eb 01             	sub    $0x1,%ebx
f01027c3:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01027c6:	39 fb                	cmp    %edi,%ebx
f01027c8:	7c 34                	jl     f01027fe <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f01027ca:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01027ce:	80 fa 84             	cmp    $0x84,%dl
f01027d1:	74 0b                	je     f01027de <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01027d3:	80 fa 64             	cmp    $0x64,%dl
f01027d6:	75 e8                	jne    f01027c0 <debuginfo_eip+0x138>
f01027d8:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01027dc:	74 e2                	je     f01027c0 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01027de:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01027e1:	8b 14 85 44 46 10 f0 	mov    -0xfefb9bc(,%eax,4),%edx
f01027e8:	b8 5c ba 10 f0       	mov    $0xf010ba5c,%eax
f01027ed:	2d 39 9d 10 f0       	sub    $0xf0109d39,%eax
f01027f2:	39 c2                	cmp    %eax,%edx
f01027f4:	73 08                	jae    f01027fe <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01027f6:	81 c2 39 9d 10 f0    	add    $0xf0109d39,%edx
f01027fc:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01027fe:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102801:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102804:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102809:	39 cb                	cmp    %ecx,%ebx
f010280b:	7d 44                	jge    f0102851 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f010280d:	8d 53 01             	lea    0x1(%ebx),%edx
f0102810:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102813:	8d 04 85 44 46 10 f0 	lea    -0xfefb9bc(,%eax,4),%eax
f010281a:	eb 07                	jmp    f0102823 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010281c:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102820:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102823:	39 ca                	cmp    %ecx,%edx
f0102825:	74 25                	je     f010284c <debuginfo_eip+0x1c4>
f0102827:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010282a:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f010282e:	74 ec                	je     f010281c <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102830:	b8 00 00 00 00       	mov    $0x0,%eax
f0102835:	eb 1a                	jmp    f0102851 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102837:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010283c:	eb 13                	jmp    f0102851 <debuginfo_eip+0x1c9>
f010283e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102843:	eb 0c                	jmp    f0102851 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102845:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010284a:	eb 05                	jmp    f0102851 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010284c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102851:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102854:	5b                   	pop    %ebx
f0102855:	5e                   	pop    %esi
f0102856:	5f                   	pop    %edi
f0102857:	5d                   	pop    %ebp
f0102858:	c3                   	ret    

f0102859 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102859:	55                   	push   %ebp
f010285a:	89 e5                	mov    %esp,%ebp
f010285c:	57                   	push   %edi
f010285d:	56                   	push   %esi
f010285e:	53                   	push   %ebx
f010285f:	83 ec 1c             	sub    $0x1c,%esp
f0102862:	89 c7                	mov    %eax,%edi
f0102864:	89 d6                	mov    %edx,%esi
f0102866:	8b 45 08             	mov    0x8(%ebp),%eax
f0102869:	8b 55 0c             	mov    0xc(%ebp),%edx
f010286c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010286f:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102872:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102875:	bb 00 00 00 00       	mov    $0x0,%ebx
f010287a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010287d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102880:	39 d3                	cmp    %edx,%ebx
f0102882:	72 05                	jb     f0102889 <printnum+0x30>
f0102884:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102887:	77 45                	ja     f01028ce <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102889:	83 ec 0c             	sub    $0xc,%esp
f010288c:	ff 75 18             	pushl  0x18(%ebp)
f010288f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102892:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102895:	53                   	push   %ebx
f0102896:	ff 75 10             	pushl  0x10(%ebp)
f0102899:	83 ec 08             	sub    $0x8,%esp
f010289c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010289f:	ff 75 e0             	pushl  -0x20(%ebp)
f01028a2:	ff 75 dc             	pushl  -0x24(%ebp)
f01028a5:	ff 75 d8             	pushl  -0x28(%ebp)
f01028a8:	e8 c3 09 00 00       	call   f0103270 <__udivdi3>
f01028ad:	83 c4 18             	add    $0x18,%esp
f01028b0:	52                   	push   %edx
f01028b1:	50                   	push   %eax
f01028b2:	89 f2                	mov    %esi,%edx
f01028b4:	89 f8                	mov    %edi,%eax
f01028b6:	e8 9e ff ff ff       	call   f0102859 <printnum>
f01028bb:	83 c4 20             	add    $0x20,%esp
f01028be:	eb 18                	jmp    f01028d8 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01028c0:	83 ec 08             	sub    $0x8,%esp
f01028c3:	56                   	push   %esi
f01028c4:	ff 75 18             	pushl  0x18(%ebp)
f01028c7:	ff d7                	call   *%edi
f01028c9:	83 c4 10             	add    $0x10,%esp
f01028cc:	eb 03                	jmp    f01028d1 <printnum+0x78>
f01028ce:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01028d1:	83 eb 01             	sub    $0x1,%ebx
f01028d4:	85 db                	test   %ebx,%ebx
f01028d6:	7f e8                	jg     f01028c0 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01028d8:	83 ec 08             	sub    $0x8,%esp
f01028db:	56                   	push   %esi
f01028dc:	83 ec 04             	sub    $0x4,%esp
f01028df:	ff 75 e4             	pushl  -0x1c(%ebp)
f01028e2:	ff 75 e0             	pushl  -0x20(%ebp)
f01028e5:	ff 75 dc             	pushl  -0x24(%ebp)
f01028e8:	ff 75 d8             	pushl  -0x28(%ebp)
f01028eb:	e8 b0 0a 00 00       	call   f01033a0 <__umoddi3>
f01028f0:	83 c4 14             	add    $0x14,%esp
f01028f3:	0f be 80 34 44 10 f0 	movsbl -0xfefbbcc(%eax),%eax
f01028fa:	50                   	push   %eax
f01028fb:	ff d7                	call   *%edi
}
f01028fd:	83 c4 10             	add    $0x10,%esp
f0102900:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102903:	5b                   	pop    %ebx
f0102904:	5e                   	pop    %esi
f0102905:	5f                   	pop    %edi
f0102906:	5d                   	pop    %ebp
f0102907:	c3                   	ret    

f0102908 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102908:	55                   	push   %ebp
f0102909:	89 e5                	mov    %esp,%ebp
f010290b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010290e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102912:	8b 10                	mov    (%eax),%edx
f0102914:	3b 50 04             	cmp    0x4(%eax),%edx
f0102917:	73 0a                	jae    f0102923 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102919:	8d 4a 01             	lea    0x1(%edx),%ecx
f010291c:	89 08                	mov    %ecx,(%eax)
f010291e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102921:	88 02                	mov    %al,(%edx)
}
f0102923:	5d                   	pop    %ebp
f0102924:	c3                   	ret    

f0102925 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102925:	55                   	push   %ebp
f0102926:	89 e5                	mov    %esp,%ebp
f0102928:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010292b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010292e:	50                   	push   %eax
f010292f:	ff 75 10             	pushl  0x10(%ebp)
f0102932:	ff 75 0c             	pushl  0xc(%ebp)
f0102935:	ff 75 08             	pushl  0x8(%ebp)
f0102938:	e8 05 00 00 00       	call   f0102942 <vprintfmt>
	va_end(ap);
}
f010293d:	83 c4 10             	add    $0x10,%esp
f0102940:	c9                   	leave  
f0102941:	c3                   	ret    

f0102942 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102942:	55                   	push   %ebp
f0102943:	89 e5                	mov    %esp,%ebp
f0102945:	57                   	push   %edi
f0102946:	56                   	push   %esi
f0102947:	53                   	push   %ebx
f0102948:	83 ec 2c             	sub    $0x2c,%esp
f010294b:	8b 75 08             	mov    0x8(%ebp),%esi
f010294e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102951:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102954:	eb 12                	jmp    f0102968 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102956:	85 c0                	test   %eax,%eax
f0102958:	0f 84 42 04 00 00    	je     f0102da0 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f010295e:	83 ec 08             	sub    $0x8,%esp
f0102961:	53                   	push   %ebx
f0102962:	50                   	push   %eax
f0102963:	ff d6                	call   *%esi
f0102965:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102968:	83 c7 01             	add    $0x1,%edi
f010296b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010296f:	83 f8 25             	cmp    $0x25,%eax
f0102972:	75 e2                	jne    f0102956 <vprintfmt+0x14>
f0102974:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102978:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010297f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102986:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010298d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102992:	eb 07                	jmp    f010299b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102994:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102997:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010299b:	8d 47 01             	lea    0x1(%edi),%eax
f010299e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01029a1:	0f b6 07             	movzbl (%edi),%eax
f01029a4:	0f b6 d0             	movzbl %al,%edx
f01029a7:	83 e8 23             	sub    $0x23,%eax
f01029aa:	3c 55                	cmp    $0x55,%al
f01029ac:	0f 87 d3 03 00 00    	ja     f0102d85 <vprintfmt+0x443>
f01029b2:	0f b6 c0             	movzbl %al,%eax
f01029b5:	ff 24 85 c0 44 10 f0 	jmp    *-0xfefbb40(,%eax,4)
f01029bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01029bf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01029c3:	eb d6                	jmp    f010299b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029cd:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01029d0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01029d3:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01029d7:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01029da:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01029dd:	83 f9 09             	cmp    $0x9,%ecx
f01029e0:	77 3f                	ja     f0102a21 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01029e2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01029e5:	eb e9                	jmp    f01029d0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01029e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01029ea:	8b 00                	mov    (%eax),%eax
f01029ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01029ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01029f2:	8d 40 04             	lea    0x4(%eax),%eax
f01029f5:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01029f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01029fb:	eb 2a                	jmp    f0102a27 <vprintfmt+0xe5>
f01029fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a00:	85 c0                	test   %eax,%eax
f0102a02:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a07:	0f 49 d0             	cmovns %eax,%edx
f0102a0a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a10:	eb 89                	jmp    f010299b <vprintfmt+0x59>
f0102a12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102a15:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102a1c:	e9 7a ff ff ff       	jmp    f010299b <vprintfmt+0x59>
f0102a21:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102a24:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102a27:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102a2b:	0f 89 6a ff ff ff    	jns    f010299b <vprintfmt+0x59>
				width = precision, precision = -1;
f0102a31:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102a34:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102a37:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102a3e:	e9 58 ff ff ff       	jmp    f010299b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102a43:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102a49:	e9 4d ff ff ff       	jmp    f010299b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102a4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a51:	8d 78 04             	lea    0x4(%eax),%edi
f0102a54:	83 ec 08             	sub    $0x8,%esp
f0102a57:	53                   	push   %ebx
f0102a58:	ff 30                	pushl  (%eax)
f0102a5a:	ff d6                	call   *%esi
			break;
f0102a5c:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102a5f:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a62:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102a65:	e9 fe fe ff ff       	jmp    f0102968 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a6d:	8d 78 04             	lea    0x4(%eax),%edi
f0102a70:	8b 00                	mov    (%eax),%eax
f0102a72:	99                   	cltd   
f0102a73:	31 d0                	xor    %edx,%eax
f0102a75:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102a77:	83 f8 06             	cmp    $0x6,%eax
f0102a7a:	7f 0b                	jg     f0102a87 <vprintfmt+0x145>
f0102a7c:	8b 14 85 18 46 10 f0 	mov    -0xfefb9e8(,%eax,4),%edx
f0102a83:	85 d2                	test   %edx,%edx
f0102a85:	75 1b                	jne    f0102aa2 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102a87:	50                   	push   %eax
f0102a88:	68 4c 44 10 f0       	push   $0xf010444c
f0102a8d:	53                   	push   %ebx
f0102a8e:	56                   	push   %esi
f0102a8f:	e8 91 fe ff ff       	call   f0102925 <printfmt>
f0102a94:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a97:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102a9d:	e9 c6 fe ff ff       	jmp    f0102968 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102aa2:	52                   	push   %edx
f0102aa3:	68 50 41 10 f0       	push   $0xf0104150
f0102aa8:	53                   	push   %ebx
f0102aa9:	56                   	push   %esi
f0102aaa:	e8 76 fe ff ff       	call   f0102925 <printfmt>
f0102aaf:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102ab2:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ab5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ab8:	e9 ab fe ff ff       	jmp    f0102968 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102abd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ac0:	83 c0 04             	add    $0x4,%eax
f0102ac3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102ac6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ac9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102acb:	85 ff                	test   %edi,%edi
f0102acd:	b8 45 44 10 f0       	mov    $0xf0104445,%eax
f0102ad2:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102ad5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ad9:	0f 8e 94 00 00 00    	jle    f0102b73 <vprintfmt+0x231>
f0102adf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ae3:	0f 84 98 00 00 00    	je     f0102b81 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ae9:	83 ec 08             	sub    $0x8,%esp
f0102aec:	ff 75 d0             	pushl  -0x30(%ebp)
f0102aef:	57                   	push   %edi
f0102af0:	e8 0c 04 00 00       	call   f0102f01 <strnlen>
f0102af5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102af8:	29 c1                	sub    %eax,%ecx
f0102afa:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102afd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102b00:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102b04:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b07:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102b0a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102b0c:	eb 0f                	jmp    f0102b1d <vprintfmt+0x1db>
					putch(padc, putdat);
f0102b0e:	83 ec 08             	sub    $0x8,%esp
f0102b11:	53                   	push   %ebx
f0102b12:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b15:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102b17:	83 ef 01             	sub    $0x1,%edi
f0102b1a:	83 c4 10             	add    $0x10,%esp
f0102b1d:	85 ff                	test   %edi,%edi
f0102b1f:	7f ed                	jg     f0102b0e <vprintfmt+0x1cc>
f0102b21:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b24:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102b27:	85 c9                	test   %ecx,%ecx
f0102b29:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b2e:	0f 49 c1             	cmovns %ecx,%eax
f0102b31:	29 c1                	sub    %eax,%ecx
f0102b33:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b36:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b39:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b3c:	89 cb                	mov    %ecx,%ebx
f0102b3e:	eb 4d                	jmp    f0102b8d <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102b40:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102b44:	74 1b                	je     f0102b61 <vprintfmt+0x21f>
f0102b46:	0f be c0             	movsbl %al,%eax
f0102b49:	83 e8 20             	sub    $0x20,%eax
f0102b4c:	83 f8 5e             	cmp    $0x5e,%eax
f0102b4f:	76 10                	jbe    f0102b61 <vprintfmt+0x21f>
					putch('?', putdat);
f0102b51:	83 ec 08             	sub    $0x8,%esp
f0102b54:	ff 75 0c             	pushl  0xc(%ebp)
f0102b57:	6a 3f                	push   $0x3f
f0102b59:	ff 55 08             	call   *0x8(%ebp)
f0102b5c:	83 c4 10             	add    $0x10,%esp
f0102b5f:	eb 0d                	jmp    f0102b6e <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102b61:	83 ec 08             	sub    $0x8,%esp
f0102b64:	ff 75 0c             	pushl  0xc(%ebp)
f0102b67:	52                   	push   %edx
f0102b68:	ff 55 08             	call   *0x8(%ebp)
f0102b6b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102b6e:	83 eb 01             	sub    $0x1,%ebx
f0102b71:	eb 1a                	jmp    f0102b8d <vprintfmt+0x24b>
f0102b73:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b76:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b79:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b7c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102b7f:	eb 0c                	jmp    f0102b8d <vprintfmt+0x24b>
f0102b81:	89 75 08             	mov    %esi,0x8(%ebp)
f0102b84:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102b87:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102b8a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102b8d:	83 c7 01             	add    $0x1,%edi
f0102b90:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b94:	0f be d0             	movsbl %al,%edx
f0102b97:	85 d2                	test   %edx,%edx
f0102b99:	74 23                	je     f0102bbe <vprintfmt+0x27c>
f0102b9b:	85 f6                	test   %esi,%esi
f0102b9d:	78 a1                	js     f0102b40 <vprintfmt+0x1fe>
f0102b9f:	83 ee 01             	sub    $0x1,%esi
f0102ba2:	79 9c                	jns    f0102b40 <vprintfmt+0x1fe>
f0102ba4:	89 df                	mov    %ebx,%edi
f0102ba6:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ba9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bac:	eb 18                	jmp    f0102bc6 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102bae:	83 ec 08             	sub    $0x8,%esp
f0102bb1:	53                   	push   %ebx
f0102bb2:	6a 20                	push   $0x20
f0102bb4:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102bb6:	83 ef 01             	sub    $0x1,%edi
f0102bb9:	83 c4 10             	add    $0x10,%esp
f0102bbc:	eb 08                	jmp    f0102bc6 <vprintfmt+0x284>
f0102bbe:	89 df                	mov    %ebx,%edi
f0102bc0:	8b 75 08             	mov    0x8(%ebp),%esi
f0102bc3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102bc6:	85 ff                	test   %edi,%edi
f0102bc8:	7f e4                	jg     f0102bae <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102bca:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102bcd:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bd0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd3:	e9 90 fd ff ff       	jmp    f0102968 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102bd8:	83 f9 01             	cmp    $0x1,%ecx
f0102bdb:	7e 19                	jle    f0102bf6 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102bdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be0:	8b 50 04             	mov    0x4(%eax),%edx
f0102be3:	8b 00                	mov    (%eax),%eax
f0102be5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102be8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102beb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bee:	8d 40 08             	lea    0x8(%eax),%eax
f0102bf1:	89 45 14             	mov    %eax,0x14(%ebp)
f0102bf4:	eb 38                	jmp    f0102c2e <vprintfmt+0x2ec>
	else if (lflag)
f0102bf6:	85 c9                	test   %ecx,%ecx
f0102bf8:	74 1b                	je     f0102c15 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102bfa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bfd:	8b 00                	mov    (%eax),%eax
f0102bff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c02:	89 c1                	mov    %eax,%ecx
f0102c04:	c1 f9 1f             	sar    $0x1f,%ecx
f0102c07:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102c0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c0d:	8d 40 04             	lea    0x4(%eax),%eax
f0102c10:	89 45 14             	mov    %eax,0x14(%ebp)
f0102c13:	eb 19                	jmp    f0102c2e <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102c15:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c18:	8b 00                	mov    (%eax),%eax
f0102c1a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c1d:	89 c1                	mov    %eax,%ecx
f0102c1f:	c1 f9 1f             	sar    $0x1f,%ecx
f0102c22:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102c25:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c28:	8d 40 04             	lea    0x4(%eax),%eax
f0102c2b:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102c2e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c31:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102c34:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102c39:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102c3d:	0f 89 0e 01 00 00    	jns    f0102d51 <vprintfmt+0x40f>
				putch('-', putdat);
f0102c43:	83 ec 08             	sub    $0x8,%esp
f0102c46:	53                   	push   %ebx
f0102c47:	6a 2d                	push   $0x2d
f0102c49:	ff d6                	call   *%esi
				num = -(long long) num;
f0102c4b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c4e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102c51:	f7 da                	neg    %edx
f0102c53:	83 d1 00             	adc    $0x0,%ecx
f0102c56:	f7 d9                	neg    %ecx
f0102c58:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102c5b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c60:	e9 ec 00 00 00       	jmp    f0102d51 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102c65:	83 f9 01             	cmp    $0x1,%ecx
f0102c68:	7e 18                	jle    f0102c82 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102c6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c6d:	8b 10                	mov    (%eax),%edx
f0102c6f:	8b 48 04             	mov    0x4(%eax),%ecx
f0102c72:	8d 40 08             	lea    0x8(%eax),%eax
f0102c75:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102c78:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c7d:	e9 cf 00 00 00       	jmp    f0102d51 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102c82:	85 c9                	test   %ecx,%ecx
f0102c84:	74 1a                	je     f0102ca0 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102c86:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c89:	8b 10                	mov    (%eax),%edx
f0102c8b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c90:	8d 40 04             	lea    0x4(%eax),%eax
f0102c93:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102c96:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102c9b:	e9 b1 00 00 00       	jmp    f0102d51 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102ca0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ca3:	8b 10                	mov    (%eax),%edx
f0102ca5:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102caa:	8d 40 04             	lea    0x4(%eax),%eax
f0102cad:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102cb0:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102cb5:	e9 97 00 00 00       	jmp    f0102d51 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102cba:	83 ec 08             	sub    $0x8,%esp
f0102cbd:	53                   	push   %ebx
f0102cbe:	6a 58                	push   $0x58
f0102cc0:	ff d6                	call   *%esi
			putch('X', putdat);
f0102cc2:	83 c4 08             	add    $0x8,%esp
f0102cc5:	53                   	push   %ebx
f0102cc6:	6a 58                	push   $0x58
f0102cc8:	ff d6                	call   *%esi
			putch('X', putdat);
f0102cca:	83 c4 08             	add    $0x8,%esp
f0102ccd:	53                   	push   %ebx
f0102cce:	6a 58                	push   $0x58
f0102cd0:	ff d6                	call   *%esi
			break;
f0102cd2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cd5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102cd8:	e9 8b fc ff ff       	jmp    f0102968 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102cdd:	83 ec 08             	sub    $0x8,%esp
f0102ce0:	53                   	push   %ebx
f0102ce1:	6a 30                	push   $0x30
f0102ce3:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ce5:	83 c4 08             	add    $0x8,%esp
f0102ce8:	53                   	push   %ebx
f0102ce9:	6a 78                	push   $0x78
f0102ceb:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102ced:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cf0:	8b 10                	mov    (%eax),%edx
f0102cf2:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102cf7:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102cfa:	8d 40 04             	lea    0x4(%eax),%eax
f0102cfd:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102d00:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102d05:	eb 4a                	jmp    f0102d51 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d07:	83 f9 01             	cmp    $0x1,%ecx
f0102d0a:	7e 15                	jle    f0102d21 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102d0c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0f:	8b 10                	mov    (%eax),%edx
f0102d11:	8b 48 04             	mov    0x4(%eax),%ecx
f0102d14:	8d 40 08             	lea    0x8(%eax),%eax
f0102d17:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102d1a:	b8 10 00 00 00       	mov    $0x10,%eax
f0102d1f:	eb 30                	jmp    f0102d51 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102d21:	85 c9                	test   %ecx,%ecx
f0102d23:	74 17                	je     f0102d3c <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102d25:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d28:	8b 10                	mov    (%eax),%edx
f0102d2a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d2f:	8d 40 04             	lea    0x4(%eax),%eax
f0102d32:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102d35:	b8 10 00 00 00       	mov    $0x10,%eax
f0102d3a:	eb 15                	jmp    f0102d51 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102d3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d3f:	8b 10                	mov    (%eax),%edx
f0102d41:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d46:	8d 40 04             	lea    0x4(%eax),%eax
f0102d49:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102d4c:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102d51:	83 ec 0c             	sub    $0xc,%esp
f0102d54:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102d58:	57                   	push   %edi
f0102d59:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d5c:	50                   	push   %eax
f0102d5d:	51                   	push   %ecx
f0102d5e:	52                   	push   %edx
f0102d5f:	89 da                	mov    %ebx,%edx
f0102d61:	89 f0                	mov    %esi,%eax
f0102d63:	e8 f1 fa ff ff       	call   f0102859 <printnum>
			break;
f0102d68:	83 c4 20             	add    $0x20,%esp
f0102d6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d6e:	e9 f5 fb ff ff       	jmp    f0102968 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102d73:	83 ec 08             	sub    $0x8,%esp
f0102d76:	53                   	push   %ebx
f0102d77:	52                   	push   %edx
f0102d78:	ff d6                	call   *%esi
			break;
f0102d7a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102d80:	e9 e3 fb ff ff       	jmp    f0102968 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102d85:	83 ec 08             	sub    $0x8,%esp
f0102d88:	53                   	push   %ebx
f0102d89:	6a 25                	push   $0x25
f0102d8b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102d8d:	83 c4 10             	add    $0x10,%esp
f0102d90:	eb 03                	jmp    f0102d95 <vprintfmt+0x453>
f0102d92:	83 ef 01             	sub    $0x1,%edi
f0102d95:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102d99:	75 f7                	jne    f0102d92 <vprintfmt+0x450>
f0102d9b:	e9 c8 fb ff ff       	jmp    f0102968 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102da0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102da3:	5b                   	pop    %ebx
f0102da4:	5e                   	pop    %esi
f0102da5:	5f                   	pop    %edi
f0102da6:	5d                   	pop    %ebp
f0102da7:	c3                   	ret    

f0102da8 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102da8:	55                   	push   %ebp
f0102da9:	89 e5                	mov    %esp,%ebp
f0102dab:	83 ec 18             	sub    $0x18,%esp
f0102dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0102db1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102db4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102db7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102dbb:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102dbe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102dc5:	85 c0                	test   %eax,%eax
f0102dc7:	74 26                	je     f0102def <vsnprintf+0x47>
f0102dc9:	85 d2                	test   %edx,%edx
f0102dcb:	7e 22                	jle    f0102def <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102dcd:	ff 75 14             	pushl  0x14(%ebp)
f0102dd0:	ff 75 10             	pushl  0x10(%ebp)
f0102dd3:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102dd6:	50                   	push   %eax
f0102dd7:	68 08 29 10 f0       	push   $0xf0102908
f0102ddc:	e8 61 fb ff ff       	call   f0102942 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102de1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102de4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102de7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102dea:	83 c4 10             	add    $0x10,%esp
f0102ded:	eb 05                	jmp    f0102df4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102def:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102df4:	c9                   	leave  
f0102df5:	c3                   	ret    

f0102df6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102df6:	55                   	push   %ebp
f0102df7:	89 e5                	mov    %esp,%ebp
f0102df9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102dfc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102dff:	50                   	push   %eax
f0102e00:	ff 75 10             	pushl  0x10(%ebp)
f0102e03:	ff 75 0c             	pushl  0xc(%ebp)
f0102e06:	ff 75 08             	pushl  0x8(%ebp)
f0102e09:	e8 9a ff ff ff       	call   f0102da8 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102e0e:	c9                   	leave  
f0102e0f:	c3                   	ret    

f0102e10 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102e10:	55                   	push   %ebp
f0102e11:	89 e5                	mov    %esp,%ebp
f0102e13:	57                   	push   %edi
f0102e14:	56                   	push   %esi
f0102e15:	53                   	push   %ebx
f0102e16:	83 ec 0c             	sub    $0xc,%esp
f0102e19:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102e1c:	85 c0                	test   %eax,%eax
f0102e1e:	74 11                	je     f0102e31 <readline+0x21>
		cprintf("%s", prompt);
f0102e20:	83 ec 08             	sub    $0x8,%esp
f0102e23:	50                   	push   %eax
f0102e24:	68 50 41 10 f0       	push   $0xf0104150
f0102e29:	e8 50 f7 ff ff       	call   f010257e <cprintf>
f0102e2e:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102e31:	83 ec 0c             	sub    $0xc,%esp
f0102e34:	6a 00                	push   $0x0
f0102e36:	e8 e6 d7 ff ff       	call   f0100621 <iscons>
f0102e3b:	89 c7                	mov    %eax,%edi
f0102e3d:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102e40:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102e45:	e8 c6 d7 ff ff       	call   f0100610 <getchar>
f0102e4a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102e4c:	85 c0                	test   %eax,%eax
f0102e4e:	79 18                	jns    f0102e68 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102e50:	83 ec 08             	sub    $0x8,%esp
f0102e53:	50                   	push   %eax
f0102e54:	68 34 46 10 f0       	push   $0xf0104634
f0102e59:	e8 20 f7 ff ff       	call   f010257e <cprintf>
			return NULL;
f0102e5e:	83 c4 10             	add    $0x10,%esp
f0102e61:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e66:	eb 79                	jmp    f0102ee1 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102e68:	83 f8 08             	cmp    $0x8,%eax
f0102e6b:	0f 94 c2             	sete   %dl
f0102e6e:	83 f8 7f             	cmp    $0x7f,%eax
f0102e71:	0f 94 c0             	sete   %al
f0102e74:	08 c2                	or     %al,%dl
f0102e76:	74 1a                	je     f0102e92 <readline+0x82>
f0102e78:	85 f6                	test   %esi,%esi
f0102e7a:	7e 16                	jle    f0102e92 <readline+0x82>
			if (echoing)
f0102e7c:	85 ff                	test   %edi,%edi
f0102e7e:	74 0d                	je     f0102e8d <readline+0x7d>
				cputchar('\b');
f0102e80:	83 ec 0c             	sub    $0xc,%esp
f0102e83:	6a 08                	push   $0x8
f0102e85:	e8 76 d7 ff ff       	call   f0100600 <cputchar>
f0102e8a:	83 c4 10             	add    $0x10,%esp
			i--;
f0102e8d:	83 ee 01             	sub    $0x1,%esi
f0102e90:	eb b3                	jmp    f0102e45 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102e92:	83 fb 1f             	cmp    $0x1f,%ebx
f0102e95:	7e 23                	jle    f0102eba <readline+0xaa>
f0102e97:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102e9d:	7f 1b                	jg     f0102eba <readline+0xaa>
			if (echoing)
f0102e9f:	85 ff                	test   %edi,%edi
f0102ea1:	74 0c                	je     f0102eaf <readline+0x9f>
				cputchar(c);
f0102ea3:	83 ec 0c             	sub    $0xc,%esp
f0102ea6:	53                   	push   %ebx
f0102ea7:	e8 54 d7 ff ff       	call   f0100600 <cputchar>
f0102eac:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102eaf:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0102eb5:	8d 76 01             	lea    0x1(%esi),%esi
f0102eb8:	eb 8b                	jmp    f0102e45 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102eba:	83 fb 0a             	cmp    $0xa,%ebx
f0102ebd:	74 05                	je     f0102ec4 <readline+0xb4>
f0102ebf:	83 fb 0d             	cmp    $0xd,%ebx
f0102ec2:	75 81                	jne    f0102e45 <readline+0x35>
			if (echoing)
f0102ec4:	85 ff                	test   %edi,%edi
f0102ec6:	74 0d                	je     f0102ed5 <readline+0xc5>
				cputchar('\n');
f0102ec8:	83 ec 0c             	sub    $0xc,%esp
f0102ecb:	6a 0a                	push   $0xa
f0102ecd:	e8 2e d7 ff ff       	call   f0100600 <cputchar>
f0102ed2:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102ed5:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102edc:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0102ee1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ee4:	5b                   	pop    %ebx
f0102ee5:	5e                   	pop    %esi
f0102ee6:	5f                   	pop    %edi
f0102ee7:	5d                   	pop    %ebp
f0102ee8:	c3                   	ret    

f0102ee9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102ee9:	55                   	push   %ebp
f0102eea:	89 e5                	mov    %esp,%ebp
f0102eec:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102eef:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ef4:	eb 03                	jmp    f0102ef9 <strlen+0x10>
		n++;
f0102ef6:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102ef9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102efd:	75 f7                	jne    f0102ef6 <strlen+0xd>
		n++;
	return n;
}
f0102eff:	5d                   	pop    %ebp
f0102f00:	c3                   	ret    

f0102f01 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f01:	55                   	push   %ebp
f0102f02:	89 e5                	mov    %esp,%ebp
f0102f04:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102f07:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f0f:	eb 03                	jmp    f0102f14 <strnlen+0x13>
		n++;
f0102f11:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f14:	39 c2                	cmp    %eax,%edx
f0102f16:	74 08                	je     f0102f20 <strnlen+0x1f>
f0102f18:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102f1c:	75 f3                	jne    f0102f11 <strnlen+0x10>
f0102f1e:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102f20:	5d                   	pop    %ebp
f0102f21:	c3                   	ret    

f0102f22 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102f22:	55                   	push   %ebp
f0102f23:	89 e5                	mov    %esp,%ebp
f0102f25:	53                   	push   %ebx
f0102f26:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f29:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102f2c:	89 c2                	mov    %eax,%edx
f0102f2e:	83 c2 01             	add    $0x1,%edx
f0102f31:	83 c1 01             	add    $0x1,%ecx
f0102f34:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102f38:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102f3b:	84 db                	test   %bl,%bl
f0102f3d:	75 ef                	jne    f0102f2e <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102f3f:	5b                   	pop    %ebx
f0102f40:	5d                   	pop    %ebp
f0102f41:	c3                   	ret    

f0102f42 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102f42:	55                   	push   %ebp
f0102f43:	89 e5                	mov    %esp,%ebp
f0102f45:	53                   	push   %ebx
f0102f46:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102f49:	53                   	push   %ebx
f0102f4a:	e8 9a ff ff ff       	call   f0102ee9 <strlen>
f0102f4f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102f52:	ff 75 0c             	pushl  0xc(%ebp)
f0102f55:	01 d8                	add    %ebx,%eax
f0102f57:	50                   	push   %eax
f0102f58:	e8 c5 ff ff ff       	call   f0102f22 <strcpy>
	return dst;
}
f0102f5d:	89 d8                	mov    %ebx,%eax
f0102f5f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f62:	c9                   	leave  
f0102f63:	c3                   	ret    

f0102f64 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102f64:	55                   	push   %ebp
f0102f65:	89 e5                	mov    %esp,%ebp
f0102f67:	56                   	push   %esi
f0102f68:	53                   	push   %ebx
f0102f69:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f6c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f6f:	89 f3                	mov    %esi,%ebx
f0102f71:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102f74:	89 f2                	mov    %esi,%edx
f0102f76:	eb 0f                	jmp    f0102f87 <strncpy+0x23>
		*dst++ = *src;
f0102f78:	83 c2 01             	add    $0x1,%edx
f0102f7b:	0f b6 01             	movzbl (%ecx),%eax
f0102f7e:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102f81:	80 39 01             	cmpb   $0x1,(%ecx)
f0102f84:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102f87:	39 da                	cmp    %ebx,%edx
f0102f89:	75 ed                	jne    f0102f78 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102f8b:	89 f0                	mov    %esi,%eax
f0102f8d:	5b                   	pop    %ebx
f0102f8e:	5e                   	pop    %esi
f0102f8f:	5d                   	pop    %ebp
f0102f90:	c3                   	ret    

f0102f91 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102f91:	55                   	push   %ebp
f0102f92:	89 e5                	mov    %esp,%ebp
f0102f94:	56                   	push   %esi
f0102f95:	53                   	push   %ebx
f0102f96:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f99:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102f9c:	8b 55 10             	mov    0x10(%ebp),%edx
f0102f9f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102fa1:	85 d2                	test   %edx,%edx
f0102fa3:	74 21                	je     f0102fc6 <strlcpy+0x35>
f0102fa5:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0102fa9:	89 f2                	mov    %esi,%edx
f0102fab:	eb 09                	jmp    f0102fb6 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102fad:	83 c2 01             	add    $0x1,%edx
f0102fb0:	83 c1 01             	add    $0x1,%ecx
f0102fb3:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102fb6:	39 c2                	cmp    %eax,%edx
f0102fb8:	74 09                	je     f0102fc3 <strlcpy+0x32>
f0102fba:	0f b6 19             	movzbl (%ecx),%ebx
f0102fbd:	84 db                	test   %bl,%bl
f0102fbf:	75 ec                	jne    f0102fad <strlcpy+0x1c>
f0102fc1:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102fc3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102fc6:	29 f0                	sub    %esi,%eax
}
f0102fc8:	5b                   	pop    %ebx
f0102fc9:	5e                   	pop    %esi
f0102fca:	5d                   	pop    %ebp
f0102fcb:	c3                   	ret    

f0102fcc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102fcc:	55                   	push   %ebp
f0102fcd:	89 e5                	mov    %esp,%ebp
f0102fcf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102fd2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102fd5:	eb 06                	jmp    f0102fdd <strcmp+0x11>
		p++, q++;
f0102fd7:	83 c1 01             	add    $0x1,%ecx
f0102fda:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102fdd:	0f b6 01             	movzbl (%ecx),%eax
f0102fe0:	84 c0                	test   %al,%al
f0102fe2:	74 04                	je     f0102fe8 <strcmp+0x1c>
f0102fe4:	3a 02                	cmp    (%edx),%al
f0102fe6:	74 ef                	je     f0102fd7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102fe8:	0f b6 c0             	movzbl %al,%eax
f0102feb:	0f b6 12             	movzbl (%edx),%edx
f0102fee:	29 d0                	sub    %edx,%eax
}
f0102ff0:	5d                   	pop    %ebp
f0102ff1:	c3                   	ret    

f0102ff2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102ff2:	55                   	push   %ebp
f0102ff3:	89 e5                	mov    %esp,%ebp
f0102ff5:	53                   	push   %ebx
f0102ff6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ffc:	89 c3                	mov    %eax,%ebx
f0102ffe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103001:	eb 06                	jmp    f0103009 <strncmp+0x17>
		n--, p++, q++;
f0103003:	83 c0 01             	add    $0x1,%eax
f0103006:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103009:	39 d8                	cmp    %ebx,%eax
f010300b:	74 15                	je     f0103022 <strncmp+0x30>
f010300d:	0f b6 08             	movzbl (%eax),%ecx
f0103010:	84 c9                	test   %cl,%cl
f0103012:	74 04                	je     f0103018 <strncmp+0x26>
f0103014:	3a 0a                	cmp    (%edx),%cl
f0103016:	74 eb                	je     f0103003 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103018:	0f b6 00             	movzbl (%eax),%eax
f010301b:	0f b6 12             	movzbl (%edx),%edx
f010301e:	29 d0                	sub    %edx,%eax
f0103020:	eb 05                	jmp    f0103027 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103022:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103027:	5b                   	pop    %ebx
f0103028:	5d                   	pop    %ebp
f0103029:	c3                   	ret    

f010302a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010302a:	55                   	push   %ebp
f010302b:	89 e5                	mov    %esp,%ebp
f010302d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103030:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103034:	eb 07                	jmp    f010303d <strchr+0x13>
		if (*s == c)
f0103036:	38 ca                	cmp    %cl,%dl
f0103038:	74 0f                	je     f0103049 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010303a:	83 c0 01             	add    $0x1,%eax
f010303d:	0f b6 10             	movzbl (%eax),%edx
f0103040:	84 d2                	test   %dl,%dl
f0103042:	75 f2                	jne    f0103036 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103044:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103049:	5d                   	pop    %ebp
f010304a:	c3                   	ret    

f010304b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010304b:	55                   	push   %ebp
f010304c:	89 e5                	mov    %esp,%ebp
f010304e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103051:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103055:	eb 03                	jmp    f010305a <strfind+0xf>
f0103057:	83 c0 01             	add    $0x1,%eax
f010305a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010305d:	38 ca                	cmp    %cl,%dl
f010305f:	74 04                	je     f0103065 <strfind+0x1a>
f0103061:	84 d2                	test   %dl,%dl
f0103063:	75 f2                	jne    f0103057 <strfind+0xc>
			break;
	return (char *) s;
}
f0103065:	5d                   	pop    %ebp
f0103066:	c3                   	ret    

f0103067 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103067:	55                   	push   %ebp
f0103068:	89 e5                	mov    %esp,%ebp
f010306a:	57                   	push   %edi
f010306b:	56                   	push   %esi
f010306c:	53                   	push   %ebx
f010306d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103070:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103073:	85 c9                	test   %ecx,%ecx
f0103075:	74 36                	je     f01030ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103077:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010307d:	75 28                	jne    f01030a7 <memset+0x40>
f010307f:	f6 c1 03             	test   $0x3,%cl
f0103082:	75 23                	jne    f01030a7 <memset+0x40>
		c &= 0xFF;
f0103084:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103088:	89 d3                	mov    %edx,%ebx
f010308a:	c1 e3 08             	shl    $0x8,%ebx
f010308d:	89 d6                	mov    %edx,%esi
f010308f:	c1 e6 18             	shl    $0x18,%esi
f0103092:	89 d0                	mov    %edx,%eax
f0103094:	c1 e0 10             	shl    $0x10,%eax
f0103097:	09 f0                	or     %esi,%eax
f0103099:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010309b:	89 d8                	mov    %ebx,%eax
f010309d:	09 d0                	or     %edx,%eax
f010309f:	c1 e9 02             	shr    $0x2,%ecx
f01030a2:	fc                   	cld    
f01030a3:	f3 ab                	rep stos %eax,%es:(%edi)
f01030a5:	eb 06                	jmp    f01030ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01030a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030aa:	fc                   	cld    
f01030ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01030ad:	89 f8                	mov    %edi,%eax
f01030af:	5b                   	pop    %ebx
f01030b0:	5e                   	pop    %esi
f01030b1:	5f                   	pop    %edi
f01030b2:	5d                   	pop    %ebp
f01030b3:	c3                   	ret    

f01030b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	57                   	push   %edi
f01030b8:	56                   	push   %esi
f01030b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01030bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01030bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01030c2:	39 c6                	cmp    %eax,%esi
f01030c4:	73 35                	jae    f01030fb <memmove+0x47>
f01030c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01030c9:	39 d0                	cmp    %edx,%eax
f01030cb:	73 2e                	jae    f01030fb <memmove+0x47>
		s += n;
		d += n;
f01030cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030d0:	89 d6                	mov    %edx,%esi
f01030d2:	09 fe                	or     %edi,%esi
f01030d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01030da:	75 13                	jne    f01030ef <memmove+0x3b>
f01030dc:	f6 c1 03             	test   $0x3,%cl
f01030df:	75 0e                	jne    f01030ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01030e1:	83 ef 04             	sub    $0x4,%edi
f01030e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01030e7:	c1 e9 02             	shr    $0x2,%ecx
f01030ea:	fd                   	std    
f01030eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01030ed:	eb 09                	jmp    f01030f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01030ef:	83 ef 01             	sub    $0x1,%edi
f01030f2:	8d 72 ff             	lea    -0x1(%edx),%esi
f01030f5:	fd                   	std    
f01030f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01030f8:	fc                   	cld    
f01030f9:	eb 1d                	jmp    f0103118 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01030fb:	89 f2                	mov    %esi,%edx
f01030fd:	09 c2                	or     %eax,%edx
f01030ff:	f6 c2 03             	test   $0x3,%dl
f0103102:	75 0f                	jne    f0103113 <memmove+0x5f>
f0103104:	f6 c1 03             	test   $0x3,%cl
f0103107:	75 0a                	jne    f0103113 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103109:	c1 e9 02             	shr    $0x2,%ecx
f010310c:	89 c7                	mov    %eax,%edi
f010310e:	fc                   	cld    
f010310f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103111:	eb 05                	jmp    f0103118 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103113:	89 c7                	mov    %eax,%edi
f0103115:	fc                   	cld    
f0103116:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103118:	5e                   	pop    %esi
f0103119:	5f                   	pop    %edi
f010311a:	5d                   	pop    %ebp
f010311b:	c3                   	ret    

f010311c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010311c:	55                   	push   %ebp
f010311d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010311f:	ff 75 10             	pushl  0x10(%ebp)
f0103122:	ff 75 0c             	pushl  0xc(%ebp)
f0103125:	ff 75 08             	pushl  0x8(%ebp)
f0103128:	e8 87 ff ff ff       	call   f01030b4 <memmove>
}
f010312d:	c9                   	leave  
f010312e:	c3                   	ret    

f010312f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010312f:	55                   	push   %ebp
f0103130:	89 e5                	mov    %esp,%ebp
f0103132:	56                   	push   %esi
f0103133:	53                   	push   %ebx
f0103134:	8b 45 08             	mov    0x8(%ebp),%eax
f0103137:	8b 55 0c             	mov    0xc(%ebp),%edx
f010313a:	89 c6                	mov    %eax,%esi
f010313c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010313f:	eb 1a                	jmp    f010315b <memcmp+0x2c>
		if (*s1 != *s2)
f0103141:	0f b6 08             	movzbl (%eax),%ecx
f0103144:	0f b6 1a             	movzbl (%edx),%ebx
f0103147:	38 d9                	cmp    %bl,%cl
f0103149:	74 0a                	je     f0103155 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010314b:	0f b6 c1             	movzbl %cl,%eax
f010314e:	0f b6 db             	movzbl %bl,%ebx
f0103151:	29 d8                	sub    %ebx,%eax
f0103153:	eb 0f                	jmp    f0103164 <memcmp+0x35>
		s1++, s2++;
f0103155:	83 c0 01             	add    $0x1,%eax
f0103158:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010315b:	39 f0                	cmp    %esi,%eax
f010315d:	75 e2                	jne    f0103141 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010315f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103164:	5b                   	pop    %ebx
f0103165:	5e                   	pop    %esi
f0103166:	5d                   	pop    %ebp
f0103167:	c3                   	ret    

f0103168 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103168:	55                   	push   %ebp
f0103169:	89 e5                	mov    %esp,%ebp
f010316b:	53                   	push   %ebx
f010316c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010316f:	89 c1                	mov    %eax,%ecx
f0103171:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103174:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103178:	eb 0a                	jmp    f0103184 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010317a:	0f b6 10             	movzbl (%eax),%edx
f010317d:	39 da                	cmp    %ebx,%edx
f010317f:	74 07                	je     f0103188 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103181:	83 c0 01             	add    $0x1,%eax
f0103184:	39 c8                	cmp    %ecx,%eax
f0103186:	72 f2                	jb     f010317a <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103188:	5b                   	pop    %ebx
f0103189:	5d                   	pop    %ebp
f010318a:	c3                   	ret    

f010318b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010318b:	55                   	push   %ebp
f010318c:	89 e5                	mov    %esp,%ebp
f010318e:	57                   	push   %edi
f010318f:	56                   	push   %esi
f0103190:	53                   	push   %ebx
f0103191:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103194:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103197:	eb 03                	jmp    f010319c <strtol+0x11>
		s++;
f0103199:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010319c:	0f b6 01             	movzbl (%ecx),%eax
f010319f:	3c 20                	cmp    $0x20,%al
f01031a1:	74 f6                	je     f0103199 <strtol+0xe>
f01031a3:	3c 09                	cmp    $0x9,%al
f01031a5:	74 f2                	je     f0103199 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01031a7:	3c 2b                	cmp    $0x2b,%al
f01031a9:	75 0a                	jne    f01031b5 <strtol+0x2a>
		s++;
f01031ab:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01031ae:	bf 00 00 00 00       	mov    $0x0,%edi
f01031b3:	eb 11                	jmp    f01031c6 <strtol+0x3b>
f01031b5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01031ba:	3c 2d                	cmp    $0x2d,%al
f01031bc:	75 08                	jne    f01031c6 <strtol+0x3b>
		s++, neg = 1;
f01031be:	83 c1 01             	add    $0x1,%ecx
f01031c1:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01031c6:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01031cc:	75 15                	jne    f01031e3 <strtol+0x58>
f01031ce:	80 39 30             	cmpb   $0x30,(%ecx)
f01031d1:	75 10                	jne    f01031e3 <strtol+0x58>
f01031d3:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01031d7:	75 7c                	jne    f0103255 <strtol+0xca>
		s += 2, base = 16;
f01031d9:	83 c1 02             	add    $0x2,%ecx
f01031dc:	bb 10 00 00 00       	mov    $0x10,%ebx
f01031e1:	eb 16                	jmp    f01031f9 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01031e3:	85 db                	test   %ebx,%ebx
f01031e5:	75 12                	jne    f01031f9 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01031e7:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01031ec:	80 39 30             	cmpb   $0x30,(%ecx)
f01031ef:	75 08                	jne    f01031f9 <strtol+0x6e>
		s++, base = 8;
f01031f1:	83 c1 01             	add    $0x1,%ecx
f01031f4:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01031f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01031fe:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103201:	0f b6 11             	movzbl (%ecx),%edx
f0103204:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103207:	89 f3                	mov    %esi,%ebx
f0103209:	80 fb 09             	cmp    $0x9,%bl
f010320c:	77 08                	ja     f0103216 <strtol+0x8b>
			dig = *s - '0';
f010320e:	0f be d2             	movsbl %dl,%edx
f0103211:	83 ea 30             	sub    $0x30,%edx
f0103214:	eb 22                	jmp    f0103238 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103216:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103219:	89 f3                	mov    %esi,%ebx
f010321b:	80 fb 19             	cmp    $0x19,%bl
f010321e:	77 08                	ja     f0103228 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103220:	0f be d2             	movsbl %dl,%edx
f0103223:	83 ea 57             	sub    $0x57,%edx
f0103226:	eb 10                	jmp    f0103238 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103228:	8d 72 bf             	lea    -0x41(%edx),%esi
f010322b:	89 f3                	mov    %esi,%ebx
f010322d:	80 fb 19             	cmp    $0x19,%bl
f0103230:	77 16                	ja     f0103248 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103232:	0f be d2             	movsbl %dl,%edx
f0103235:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103238:	3b 55 10             	cmp    0x10(%ebp),%edx
f010323b:	7d 0b                	jge    f0103248 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010323d:	83 c1 01             	add    $0x1,%ecx
f0103240:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103244:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103246:	eb b9                	jmp    f0103201 <strtol+0x76>

	if (endptr)
f0103248:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010324c:	74 0d                	je     f010325b <strtol+0xd0>
		*endptr = (char *) s;
f010324e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103251:	89 0e                	mov    %ecx,(%esi)
f0103253:	eb 06                	jmp    f010325b <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103255:	85 db                	test   %ebx,%ebx
f0103257:	74 98                	je     f01031f1 <strtol+0x66>
f0103259:	eb 9e                	jmp    f01031f9 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010325b:	89 c2                	mov    %eax,%edx
f010325d:	f7 da                	neg    %edx
f010325f:	85 ff                	test   %edi,%edi
f0103261:	0f 45 c2             	cmovne %edx,%eax
}
f0103264:	5b                   	pop    %ebx
f0103265:	5e                   	pop    %esi
f0103266:	5f                   	pop    %edi
f0103267:	5d                   	pop    %ebp
f0103268:	c3                   	ret    
f0103269:	66 90                	xchg   %ax,%ax
f010326b:	66 90                	xchg   %ax,%ax
f010326d:	66 90                	xchg   %ax,%ax
f010326f:	90                   	nop

f0103270 <__udivdi3>:
f0103270:	55                   	push   %ebp
f0103271:	57                   	push   %edi
f0103272:	56                   	push   %esi
f0103273:	53                   	push   %ebx
f0103274:	83 ec 1c             	sub    $0x1c,%esp
f0103277:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010327b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010327f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103283:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103287:	85 f6                	test   %esi,%esi
f0103289:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010328d:	89 ca                	mov    %ecx,%edx
f010328f:	89 f8                	mov    %edi,%eax
f0103291:	75 3d                	jne    f01032d0 <__udivdi3+0x60>
f0103293:	39 cf                	cmp    %ecx,%edi
f0103295:	0f 87 c5 00 00 00    	ja     f0103360 <__udivdi3+0xf0>
f010329b:	85 ff                	test   %edi,%edi
f010329d:	89 fd                	mov    %edi,%ebp
f010329f:	75 0b                	jne    f01032ac <__udivdi3+0x3c>
f01032a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01032a6:	31 d2                	xor    %edx,%edx
f01032a8:	f7 f7                	div    %edi
f01032aa:	89 c5                	mov    %eax,%ebp
f01032ac:	89 c8                	mov    %ecx,%eax
f01032ae:	31 d2                	xor    %edx,%edx
f01032b0:	f7 f5                	div    %ebp
f01032b2:	89 c1                	mov    %eax,%ecx
f01032b4:	89 d8                	mov    %ebx,%eax
f01032b6:	89 cf                	mov    %ecx,%edi
f01032b8:	f7 f5                	div    %ebp
f01032ba:	89 c3                	mov    %eax,%ebx
f01032bc:	89 d8                	mov    %ebx,%eax
f01032be:	89 fa                	mov    %edi,%edx
f01032c0:	83 c4 1c             	add    $0x1c,%esp
f01032c3:	5b                   	pop    %ebx
f01032c4:	5e                   	pop    %esi
f01032c5:	5f                   	pop    %edi
f01032c6:	5d                   	pop    %ebp
f01032c7:	c3                   	ret    
f01032c8:	90                   	nop
f01032c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01032d0:	39 ce                	cmp    %ecx,%esi
f01032d2:	77 74                	ja     f0103348 <__udivdi3+0xd8>
f01032d4:	0f bd fe             	bsr    %esi,%edi
f01032d7:	83 f7 1f             	xor    $0x1f,%edi
f01032da:	0f 84 98 00 00 00    	je     f0103378 <__udivdi3+0x108>
f01032e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01032e5:	89 f9                	mov    %edi,%ecx
f01032e7:	89 c5                	mov    %eax,%ebp
f01032e9:	29 fb                	sub    %edi,%ebx
f01032eb:	d3 e6                	shl    %cl,%esi
f01032ed:	89 d9                	mov    %ebx,%ecx
f01032ef:	d3 ed                	shr    %cl,%ebp
f01032f1:	89 f9                	mov    %edi,%ecx
f01032f3:	d3 e0                	shl    %cl,%eax
f01032f5:	09 ee                	or     %ebp,%esi
f01032f7:	89 d9                	mov    %ebx,%ecx
f01032f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032fd:	89 d5                	mov    %edx,%ebp
f01032ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103303:	d3 ed                	shr    %cl,%ebp
f0103305:	89 f9                	mov    %edi,%ecx
f0103307:	d3 e2                	shl    %cl,%edx
f0103309:	89 d9                	mov    %ebx,%ecx
f010330b:	d3 e8                	shr    %cl,%eax
f010330d:	09 c2                	or     %eax,%edx
f010330f:	89 d0                	mov    %edx,%eax
f0103311:	89 ea                	mov    %ebp,%edx
f0103313:	f7 f6                	div    %esi
f0103315:	89 d5                	mov    %edx,%ebp
f0103317:	89 c3                	mov    %eax,%ebx
f0103319:	f7 64 24 0c          	mull   0xc(%esp)
f010331d:	39 d5                	cmp    %edx,%ebp
f010331f:	72 10                	jb     f0103331 <__udivdi3+0xc1>
f0103321:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103325:	89 f9                	mov    %edi,%ecx
f0103327:	d3 e6                	shl    %cl,%esi
f0103329:	39 c6                	cmp    %eax,%esi
f010332b:	73 07                	jae    f0103334 <__udivdi3+0xc4>
f010332d:	39 d5                	cmp    %edx,%ebp
f010332f:	75 03                	jne    f0103334 <__udivdi3+0xc4>
f0103331:	83 eb 01             	sub    $0x1,%ebx
f0103334:	31 ff                	xor    %edi,%edi
f0103336:	89 d8                	mov    %ebx,%eax
f0103338:	89 fa                	mov    %edi,%edx
f010333a:	83 c4 1c             	add    $0x1c,%esp
f010333d:	5b                   	pop    %ebx
f010333e:	5e                   	pop    %esi
f010333f:	5f                   	pop    %edi
f0103340:	5d                   	pop    %ebp
f0103341:	c3                   	ret    
f0103342:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103348:	31 ff                	xor    %edi,%edi
f010334a:	31 db                	xor    %ebx,%ebx
f010334c:	89 d8                	mov    %ebx,%eax
f010334e:	89 fa                	mov    %edi,%edx
f0103350:	83 c4 1c             	add    $0x1c,%esp
f0103353:	5b                   	pop    %ebx
f0103354:	5e                   	pop    %esi
f0103355:	5f                   	pop    %edi
f0103356:	5d                   	pop    %ebp
f0103357:	c3                   	ret    
f0103358:	90                   	nop
f0103359:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103360:	89 d8                	mov    %ebx,%eax
f0103362:	f7 f7                	div    %edi
f0103364:	31 ff                	xor    %edi,%edi
f0103366:	89 c3                	mov    %eax,%ebx
f0103368:	89 d8                	mov    %ebx,%eax
f010336a:	89 fa                	mov    %edi,%edx
f010336c:	83 c4 1c             	add    $0x1c,%esp
f010336f:	5b                   	pop    %ebx
f0103370:	5e                   	pop    %esi
f0103371:	5f                   	pop    %edi
f0103372:	5d                   	pop    %ebp
f0103373:	c3                   	ret    
f0103374:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103378:	39 ce                	cmp    %ecx,%esi
f010337a:	72 0c                	jb     f0103388 <__udivdi3+0x118>
f010337c:	31 db                	xor    %ebx,%ebx
f010337e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103382:	0f 87 34 ff ff ff    	ja     f01032bc <__udivdi3+0x4c>
f0103388:	bb 01 00 00 00       	mov    $0x1,%ebx
f010338d:	e9 2a ff ff ff       	jmp    f01032bc <__udivdi3+0x4c>
f0103392:	66 90                	xchg   %ax,%ax
f0103394:	66 90                	xchg   %ax,%ax
f0103396:	66 90                	xchg   %ax,%ax
f0103398:	66 90                	xchg   %ax,%ax
f010339a:	66 90                	xchg   %ax,%ax
f010339c:	66 90                	xchg   %ax,%ax
f010339e:	66 90                	xchg   %ax,%ax

f01033a0 <__umoddi3>:
f01033a0:	55                   	push   %ebp
f01033a1:	57                   	push   %edi
f01033a2:	56                   	push   %esi
f01033a3:	53                   	push   %ebx
f01033a4:	83 ec 1c             	sub    $0x1c,%esp
f01033a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01033ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01033af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01033b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033b7:	85 d2                	test   %edx,%edx
f01033b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01033bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01033c1:	89 f3                	mov    %esi,%ebx
f01033c3:	89 3c 24             	mov    %edi,(%esp)
f01033c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033ca:	75 1c                	jne    f01033e8 <__umoddi3+0x48>
f01033cc:	39 f7                	cmp    %esi,%edi
f01033ce:	76 50                	jbe    f0103420 <__umoddi3+0x80>
f01033d0:	89 c8                	mov    %ecx,%eax
f01033d2:	89 f2                	mov    %esi,%edx
f01033d4:	f7 f7                	div    %edi
f01033d6:	89 d0                	mov    %edx,%eax
f01033d8:	31 d2                	xor    %edx,%edx
f01033da:	83 c4 1c             	add    $0x1c,%esp
f01033dd:	5b                   	pop    %ebx
f01033de:	5e                   	pop    %esi
f01033df:	5f                   	pop    %edi
f01033e0:	5d                   	pop    %ebp
f01033e1:	c3                   	ret    
f01033e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033e8:	39 f2                	cmp    %esi,%edx
f01033ea:	89 d0                	mov    %edx,%eax
f01033ec:	77 52                	ja     f0103440 <__umoddi3+0xa0>
f01033ee:	0f bd ea             	bsr    %edx,%ebp
f01033f1:	83 f5 1f             	xor    $0x1f,%ebp
f01033f4:	75 5a                	jne    f0103450 <__umoddi3+0xb0>
f01033f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01033fa:	0f 82 e0 00 00 00    	jb     f01034e0 <__umoddi3+0x140>
f0103400:	39 0c 24             	cmp    %ecx,(%esp)
f0103403:	0f 86 d7 00 00 00    	jbe    f01034e0 <__umoddi3+0x140>
f0103409:	8b 44 24 08          	mov    0x8(%esp),%eax
f010340d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103411:	83 c4 1c             	add    $0x1c,%esp
f0103414:	5b                   	pop    %ebx
f0103415:	5e                   	pop    %esi
f0103416:	5f                   	pop    %edi
f0103417:	5d                   	pop    %ebp
f0103418:	c3                   	ret    
f0103419:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103420:	85 ff                	test   %edi,%edi
f0103422:	89 fd                	mov    %edi,%ebp
f0103424:	75 0b                	jne    f0103431 <__umoddi3+0x91>
f0103426:	b8 01 00 00 00       	mov    $0x1,%eax
f010342b:	31 d2                	xor    %edx,%edx
f010342d:	f7 f7                	div    %edi
f010342f:	89 c5                	mov    %eax,%ebp
f0103431:	89 f0                	mov    %esi,%eax
f0103433:	31 d2                	xor    %edx,%edx
f0103435:	f7 f5                	div    %ebp
f0103437:	89 c8                	mov    %ecx,%eax
f0103439:	f7 f5                	div    %ebp
f010343b:	89 d0                	mov    %edx,%eax
f010343d:	eb 99                	jmp    f01033d8 <__umoddi3+0x38>
f010343f:	90                   	nop
f0103440:	89 c8                	mov    %ecx,%eax
f0103442:	89 f2                	mov    %esi,%edx
f0103444:	83 c4 1c             	add    $0x1c,%esp
f0103447:	5b                   	pop    %ebx
f0103448:	5e                   	pop    %esi
f0103449:	5f                   	pop    %edi
f010344a:	5d                   	pop    %ebp
f010344b:	c3                   	ret    
f010344c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103450:	8b 34 24             	mov    (%esp),%esi
f0103453:	bf 20 00 00 00       	mov    $0x20,%edi
f0103458:	89 e9                	mov    %ebp,%ecx
f010345a:	29 ef                	sub    %ebp,%edi
f010345c:	d3 e0                	shl    %cl,%eax
f010345e:	89 f9                	mov    %edi,%ecx
f0103460:	89 f2                	mov    %esi,%edx
f0103462:	d3 ea                	shr    %cl,%edx
f0103464:	89 e9                	mov    %ebp,%ecx
f0103466:	09 c2                	or     %eax,%edx
f0103468:	89 d8                	mov    %ebx,%eax
f010346a:	89 14 24             	mov    %edx,(%esp)
f010346d:	89 f2                	mov    %esi,%edx
f010346f:	d3 e2                	shl    %cl,%edx
f0103471:	89 f9                	mov    %edi,%ecx
f0103473:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103477:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010347b:	d3 e8                	shr    %cl,%eax
f010347d:	89 e9                	mov    %ebp,%ecx
f010347f:	89 c6                	mov    %eax,%esi
f0103481:	d3 e3                	shl    %cl,%ebx
f0103483:	89 f9                	mov    %edi,%ecx
f0103485:	89 d0                	mov    %edx,%eax
f0103487:	d3 e8                	shr    %cl,%eax
f0103489:	89 e9                	mov    %ebp,%ecx
f010348b:	09 d8                	or     %ebx,%eax
f010348d:	89 d3                	mov    %edx,%ebx
f010348f:	89 f2                	mov    %esi,%edx
f0103491:	f7 34 24             	divl   (%esp)
f0103494:	89 d6                	mov    %edx,%esi
f0103496:	d3 e3                	shl    %cl,%ebx
f0103498:	f7 64 24 04          	mull   0x4(%esp)
f010349c:	39 d6                	cmp    %edx,%esi
f010349e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034a2:	89 d1                	mov    %edx,%ecx
f01034a4:	89 c3                	mov    %eax,%ebx
f01034a6:	72 08                	jb     f01034b0 <__umoddi3+0x110>
f01034a8:	75 11                	jne    f01034bb <__umoddi3+0x11b>
f01034aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01034ae:	73 0b                	jae    f01034bb <__umoddi3+0x11b>
f01034b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01034b4:	1b 14 24             	sbb    (%esp),%edx
f01034b7:	89 d1                	mov    %edx,%ecx
f01034b9:	89 c3                	mov    %eax,%ebx
f01034bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01034bf:	29 da                	sub    %ebx,%edx
f01034c1:	19 ce                	sbb    %ecx,%esi
f01034c3:	89 f9                	mov    %edi,%ecx
f01034c5:	89 f0                	mov    %esi,%eax
f01034c7:	d3 e0                	shl    %cl,%eax
f01034c9:	89 e9                	mov    %ebp,%ecx
f01034cb:	d3 ea                	shr    %cl,%edx
f01034cd:	89 e9                	mov    %ebp,%ecx
f01034cf:	d3 ee                	shr    %cl,%esi
f01034d1:	09 d0                	or     %edx,%eax
f01034d3:	89 f2                	mov    %esi,%edx
f01034d5:	83 c4 1c             	add    $0x1c,%esp
f01034d8:	5b                   	pop    %ebx
f01034d9:	5e                   	pop    %esi
f01034da:	5f                   	pop    %edi
f01034db:	5d                   	pop    %ebp
f01034dc:	c3                   	ret    
f01034dd:	8d 76 00             	lea    0x0(%esi),%esi
f01034e0:	29 f9                	sub    %edi,%ecx
f01034e2:	19 d6                	sbb    %edx,%esi
f01034e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034ec:	e9 18 ff ff ff       	jmp    f0103409 <__umoddi3+0x69>
