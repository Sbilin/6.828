
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f0100046:	b8 50 49 11 f0       	mov    $0xf0114950,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 cc 1e 00 00       	call   f0101f29 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 23 10 f0       	push   $0xf01023c0
f010006f:	e8 cc 13 00 00       	call   f0101440 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 f1 0c 00 00       	call   f0100d6a <mem_init>
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
f0100093:	83 3d 40 49 11 f0 00 	cmpl   $0x0,0xf0114940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 49 11 f0    	mov    %esi,0xf0114940

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
f01000b0:	68 db 23 10 f0       	push   $0xf01023db
f01000b5:	e8 86 13 00 00       	call   f0101440 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 56 13 00 00       	call   f010141a <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 17 24 10 f0 	movl   $0xf0102417,(%esp)
f01000cb:	e8 70 13 00 00       	call   f0101440 <cprintf>
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
f01000f2:	68 f3 23 10 f0       	push   $0xf01023f3
f01000f7:	e8 44 13 00 00       	call   f0101440 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 12 13 00 00       	call   f010141a <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 17 24 10 f0 	movl   $0xf0102417,(%esp)
f010010f:	e8 2c 13 00 00       	call   f0101440 <cprintf>
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
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
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
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
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
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 60 25 10 f0 	movzbl -0xfefdaa0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 60 25 10 f0 	movzbl -0xfefdaa0(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a 60 24 10 f0 	movzbl -0xfefdba0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 40 24 10 f0 	mov    -0xfefdbc0(,%ecx,4),%ecx
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
f0100268:	68 0d 24 10 f0       	push   $0xf010240d
f010026d:	e8 ce 11 00 00       	call   f0101440 <cprintf>
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
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 55 1b 00 00       	call   f0101f76 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
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
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
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
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
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
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
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
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
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
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
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
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
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
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
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
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
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
f01005eb:	68 19 24 10 f0       	push   $0xf0102419
f01005f0:	e8 4b 0e 00 00       	call   f0101440 <cprintf>
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
f0100631:	68 60 26 10 f0       	push   $0xf0102660
f0100636:	68 7e 26 10 f0       	push   $0xf010267e
f010063b:	68 83 26 10 f0       	push   $0xf0102683
f0100640:	e8 fb 0d 00 00       	call   f0101440 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 ec 26 10 f0       	push   $0xf01026ec
f010064d:	68 8c 26 10 f0       	push   $0xf010268c
f0100652:	68 83 26 10 f0       	push   $0xf0102683
f0100657:	e8 e4 0d 00 00       	call   f0101440 <cprintf>
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
f0100669:	68 95 26 10 f0       	push   $0xf0102695
f010066e:	e8 cd 0d 00 00       	call   f0101440 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 14 27 10 f0       	push   $0xf0102714
f0100680:	e8 bb 0d 00 00       	call   f0101440 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 3c 27 10 f0       	push   $0xf010273c
f0100697:	e8 a4 0d 00 00       	call   f0101440 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 b1 23 10 00       	push   $0x1023b1
f01006a4:	68 b1 23 10 f0       	push   $0xf01023b1
f01006a9:	68 60 27 10 f0       	push   $0xf0102760
f01006ae:	e8 8d 0d 00 00       	call   f0101440 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 43 11 00       	push   $0x114300
f01006bb:	68 00 43 11 f0       	push   $0xf0114300
f01006c0:	68 84 27 10 f0       	push   $0xf0102784
f01006c5:	e8 76 0d 00 00       	call   f0101440 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 49 11 00       	push   $0x114950
f01006d2:	68 50 49 11 f0       	push   $0xf0114950
f01006d7:	68 a8 27 10 f0       	push   $0xf01027a8
f01006dc:	e8 5f 0d 00 00       	call   f0101440 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 4d 11 f0       	mov    $0xf0114d4f,%eax
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
f0100702:	68 cc 27 10 f0       	push   $0xf01027cc
f0100707:	e8 34 0d 00 00       	call   f0101440 <cprintf>
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
f0100726:	68 f8 27 10 f0       	push   $0xf01027f8
f010072b:	e8 10 0d 00 00       	call   f0101440 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 1c 28 10 f0 	movl   $0xf010281c,(%esp)
f0100737:	e8 04 0d 00 00       	call   f0101440 <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 ae 26 10 f0       	push   $0xf01026ae
f0100747:	e8 86 15 00 00       	call   f0101cd2 <readline>
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
f010077b:	68 b2 26 10 f0       	push   $0xf01026b2
f0100780:	e8 67 17 00 00       	call   f0101eec <strchr>
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
f010079b:	68 b7 26 10 f0       	push   $0xf01026b7
f01007a0:	e8 9b 0c 00 00       	call   f0101440 <cprintf>
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
f01007c4:	68 b2 26 10 f0       	push   $0xf01026b2
f01007c9:	e8 1e 17 00 00       	call   f0101eec <strchr>
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
f01007ea:	68 7e 26 10 f0       	push   $0xf010267e
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 97 16 00 00       	call   f0101e8e <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 8c 26 10 f0       	push   $0xf010268c
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 80 16 00 00       	call   f0101e8e <strcmp>
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
f0100831:	ff 14 85 4c 28 10 f0 	call   *-0xfefd7b4(,%eax,4)


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
f010084a:	68 d4 26 10 f0       	push   $0xf01026d4
f010084f:	e8 ec 0b 00 00       	call   f0101440 <cprintf>
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
f0100869:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f0100870:	75 0f                	jne    f0100881 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100872:	b8 4f 59 11 f0       	mov    $0xf011594f,%eax
f0100877:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010087c:	a3 38 45 11 f0       	mov    %eax,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100881:	a1 38 45 11 f0       	mov    0xf0114538,%eax
	nextfree=nextfree + ROUNDUP(n,PGSIZE);
f0100886:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f010088c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100892:	01 c2                	add    %eax,%edx
f0100894:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
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
f01008a7:	e8 2d 0b 00 00       	call   f01013d9 <mc146818_read>
f01008ac:	89 c6                	mov    %eax,%esi
f01008ae:	83 c3 01             	add    $0x1,%ebx
f01008b1:	89 1c 24             	mov    %ebx,(%esp)
f01008b4:	e8 20 0b 00 00       	call   f01013d9 <mc146818_read>
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
f01008db:	3b 0d 44 49 11 f0    	cmp    0xf0114944,%ecx
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
f01008ea:	68 5c 28 10 f0       	push   $0xf010285c
f01008ef:	68 a2 02 00 00       	push   $0x2a2
f01008f4:	68 3c 2a 10 f0       	push   $0xf0102a3c
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
f0100942:	68 80 28 10 f0       	push   $0xf0102880
f0100947:	68 e5 01 00 00       	push   $0x1e5
f010094c:	68 3c 2a 10 f0       	push   $0xf0102a3c
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
f0100964:	2b 15 4c 49 11 f0    	sub    0xf011494c,%edx
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
f010099a:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
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
f01009a4:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f01009aa:	eb 53                	jmp    f01009ff <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009ac:	89 d8                	mov    %ebx,%eax
f01009ae:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
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
f01009c8:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f01009ce:	72 12                	jb     f01009e2 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009d0:	50                   	push   %eax
f01009d1:	68 5c 28 10 f0       	push   $0xf010285c
f01009d6:	6a 52                	push   $0x52
f01009d8:	68 48 2a 10 f0       	push   $0xf0102a48
f01009dd:	e8 a9 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009e2:	83 ec 04             	sub    $0x4,%esp
f01009e5:	68 80 00 00 00       	push   $0x80
f01009ea:	68 97 00 00 00       	push   $0x97
f01009ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f4:	50                   	push   %eax
f01009f5:	e8 2f 15 00 00       	call   f0101f29 <memset>
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
f0100a10:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a16:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
		assert(pp < pages + npages);
f0100a1c:	a1 44 49 11 f0       	mov    0xf0114944,%eax
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
f0100a3b:	68 56 2a 10 f0       	push   $0xf0102a56
f0100a40:	68 62 2a 10 f0       	push   $0xf0102a62
f0100a45:	68 ff 01 00 00       	push   $0x1ff
f0100a4a:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100a4f:	e8 37 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a54:	39 fa                	cmp    %edi,%edx
f0100a56:	72 19                	jb     f0100a71 <check_page_free_list+0x148>
f0100a58:	68 77 2a 10 f0       	push   $0xf0102a77
f0100a5d:	68 62 2a 10 f0       	push   $0xf0102a62
f0100a62:	68 00 02 00 00       	push   $0x200
f0100a67:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100a6c:	e8 1a f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a71:	89 d0                	mov    %edx,%eax
f0100a73:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a76:	a8 07                	test   $0x7,%al
f0100a78:	74 19                	je     f0100a93 <check_page_free_list+0x16a>
f0100a7a:	68 a4 28 10 f0       	push   $0xf01028a4
f0100a7f:	68 62 2a 10 f0       	push   $0xf0102a62
f0100a84:	68 01 02 00 00       	push   $0x201
f0100a89:	68 3c 2a 10 f0       	push   $0xf0102a3c
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
f0100a9d:	68 8b 2a 10 f0       	push   $0xf0102a8b
f0100aa2:	68 62 2a 10 f0       	push   $0xf0102a62
f0100aa7:	68 04 02 00 00       	push   $0x204
f0100aac:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100ab1:	e8 d5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ab6:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100abb:	75 19                	jne    f0100ad6 <check_page_free_list+0x1ad>
f0100abd:	68 9c 2a 10 f0       	push   $0xf0102a9c
f0100ac2:	68 62 2a 10 f0       	push   $0xf0102a62
f0100ac7:	68 05 02 00 00       	push   $0x205
f0100acc:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100ad1:	e8 b5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ad6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100adb:	75 19                	jne    f0100af6 <check_page_free_list+0x1cd>
f0100add:	68 d8 28 10 f0       	push   $0xf01028d8
f0100ae2:	68 62 2a 10 f0       	push   $0xf0102a62
f0100ae7:	68 06 02 00 00       	push   $0x206
f0100aec:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100af1:	e8 95 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100af6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100afb:	75 19                	jne    f0100b16 <check_page_free_list+0x1ed>
f0100afd:	68 b5 2a 10 f0       	push   $0xf0102ab5
f0100b02:	68 62 2a 10 f0       	push   $0xf0102a62
f0100b07:	68 07 02 00 00       	push   $0x207
f0100b0c:	68 3c 2a 10 f0       	push   $0xf0102a3c
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
f0100b28:	68 5c 28 10 f0       	push   $0xf010285c
f0100b2d:	6a 52                	push   $0x52
f0100b2f:	68 48 2a 10 f0       	push   $0xf0102a48
f0100b34:	e8 52 f5 ff ff       	call   f010008b <_panic>
f0100b39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b41:	76 1e                	jbe    f0100b61 <check_page_free_list+0x238>
f0100b43:	68 fc 28 10 f0       	push   $0xf01028fc
f0100b48:	68 62 2a 10 f0       	push   $0xf0102a62
f0100b4d:	68 08 02 00 00       	push   $0x208
f0100b52:	68 3c 2a 10 f0       	push   $0xf0102a3c
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
f0100b76:	68 cf 2a 10 f0       	push   $0xf0102acf
f0100b7b:	68 62 2a 10 f0       	push   $0xf0102a62
f0100b80:	68 10 02 00 00       	push   $0x210
f0100b85:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100b8a:	e8 fc f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b8f:	85 db                	test   %ebx,%ebx
f0100b91:	7f 42                	jg     f0100bd5 <check_page_free_list+0x2ac>
f0100b93:	68 e1 2a 10 f0       	push   $0xf0102ae1
f0100b98:	68 62 2a 10 f0       	push   $0xf0102a62
f0100b9d:	68 11 02 00 00       	push   $0x211
f0100ba2:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100ba7:	e8 df f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bac:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100bb1:	85 c0                	test   %eax,%eax
f0100bb3:	0f 85 9d fd ff ff    	jne    f0100956 <check_page_free_list+0x2d>
f0100bb9:	e9 81 fd ff ff       	jmp    f010093f <check_page_free_list+0x16>
f0100bbe:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
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
f0100be2:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
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
f0100bfe:	68 44 29 10 f0       	push   $0xf0102944
f0100c03:	68 05 01 00 00       	push   $0x105
f0100c08:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100c0d:	e8 79 f4 ff ff       	call   f010008b <_panic>
f0100c12:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100c18:	c1 eb 0c             	shr    $0xc,%ebx
	cprintf("%d,%d\n",low_pgm,upp_pgm);
f0100c1b:	83 ec 04             	sub    $0x4,%esp
f0100c1e:	53                   	push   %ebx
f0100c1f:	68 a0 00 00 00       	push   $0xa0
f0100c24:	68 f2 2a 10 f0       	push   $0xf0102af2
f0100c29:	e8 12 08 00 00       	call   f0101440 <cprintf>
f0100c2e:	8b 35 3c 45 11 f0    	mov    0xf011453c,%esi
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
f0100c47:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
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
f0100c66:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
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
f0100c86:	03 0d 4c 49 11 f0    	add    0xf011494c,%ecx
f0100c8c:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
                 pages[i].pp_link = page_free_list;
f0100c92:	89 31                	mov    %esi,(%ecx)
                 page_free_list = &pages[i];
f0100c94:	89 d6                	mov    %edx,%esi
f0100c96:	03 35 4c 49 11 f0    	add    0xf011494c,%esi
f0100c9c:	b9 01 00 00 00       	mov    $0x1,%ecx
        page_free_list = NULL;
	int low_pgm=PGNUM(IOPHYSMEM);

        int upp_pgm = PGNUM(PADDR(boot_alloc(0)));
	cprintf("%d,%d\n",low_pgm,upp_pgm);
	for (i = 0; i < npages; i++) {
f0100ca1:	83 c0 01             	add    $0x1,%eax
f0100ca4:	3b 05 44 49 11 f0    	cmp    0xf0114944,%eax
f0100caa:	72 97                	jb     f0100c43 <page_init+0x66>
f0100cac:	84 c9                	test   %cl,%cl
f0100cae:	74 06                	je     f0100cb6 <page_init+0xd9>
f0100cb0:	89 35 3c 45 11 f0    	mov    %esi,0xf011453c
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
f0100cc4:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100cca:	85 db                	test   %ebx,%ebx
f0100ccc:	74 58                	je     f0100d26 <page_alloc+0x69>
        {
           return NULL;
        }
        result =page_free_list;
        page_free_list=result->pp_link;
f0100cce:	8b 03                	mov    (%ebx),%eax
f0100cd0:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
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
f0100ce3:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100ce9:	c1 f8 03             	sar    $0x3,%eax
f0100cec:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cef:	89 c2                	mov    %eax,%edx
f0100cf1:	c1 ea 0c             	shr    $0xc,%edx
f0100cf4:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100cfa:	72 12                	jb     f0100d0e <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cfc:	50                   	push   %eax
f0100cfd:	68 5c 28 10 f0       	push   $0xf010285c
f0100d02:	6a 52                	push   $0x52
f0100d04:	68 48 2a 10 f0       	push   $0xf0102a48
f0100d09:	e8 7d f3 ff ff       	call   f010008b <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100d0e:	83 ec 04             	sub    $0x4,%esp
f0100d11:	68 00 10 00 00       	push   $0x1000
f0100d16:	6a 00                	push   $0x0
f0100d18:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d1d:	50                   	push   %eax
f0100d1e:	e8 06 12 00 00       	call   f0101f29 <memset>
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
f0100d42:	68 68 29 10 f0       	push   $0xf0102968
f0100d47:	68 62 2a 10 f0       	push   $0xf0102a62
f0100d4c:	68 42 01 00 00       	push   $0x142
f0100d51:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100d56:	e8 30 f3 ff ff       	call   f010008b <_panic>
  
   	 pp->pp_link = page_free_list;  
f0100d5b:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d61:	89 10                	mov    %edx,(%eax)
    	 page_free_list = pp;  
f0100d63:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100d68:	c9                   	leave  
f0100d69:	c3                   	ret    

f0100d6a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100d6a:	55                   	push   %ebp
f0100d6b:	89 e5                	mov    %esp,%ebp
f0100d6d:	57                   	push   %edi
f0100d6e:	56                   	push   %esi
f0100d6f:	53                   	push   %ebx
f0100d70:	83 ec 1c             	sub    $0x1c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100d73:	b8 15 00 00 00       	mov    $0x15,%eax
f0100d78:	e8 1f fb ff ff       	call   f010089c <nvram_read>
f0100d7d:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100d7f:	b8 17 00 00 00       	mov    $0x17,%eax
f0100d84:	e8 13 fb ff ff       	call   f010089c <nvram_read>
f0100d89:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100d8b:	b8 34 00 00 00       	mov    $0x34,%eax
f0100d90:	e8 07 fb ff ff       	call   f010089c <nvram_read>
f0100d95:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100d98:	85 c0                	test   %eax,%eax
f0100d9a:	74 07                	je     f0100da3 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100d9c:	05 00 40 00 00       	add    $0x4000,%eax
f0100da1:	eb 0b                	jmp    f0100dae <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100da3:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100da9:	85 f6                	test   %esi,%esi
f0100dab:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100dae:	89 c2                	mov    %eax,%edx
f0100db0:	c1 ea 02             	shr    $0x2,%edx
f0100db3:	89 15 44 49 11 f0    	mov    %edx,0xf0114944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100db9:	89 c2                	mov    %eax,%edx
f0100dbb:	29 da                	sub    %ebx,%edx
f0100dbd:	52                   	push   %edx
f0100dbe:	53                   	push   %ebx
f0100dbf:	50                   	push   %eax
f0100dc0:	68 90 29 10 f0       	push   $0xf0102990
f0100dc5:	e8 76 06 00 00       	call   f0101440 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100dca:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100dcf:	e8 90 fa ff ff       	call   f0100864 <boot_alloc>
f0100dd4:	a3 48 49 11 f0       	mov    %eax,0xf0114948
	memset(kern_pgdir, 0, PGSIZE);
f0100dd9:	83 c4 0c             	add    $0xc,%esp
f0100ddc:	68 00 10 00 00       	push   $0x1000
f0100de1:	6a 00                	push   $0x0
f0100de3:	50                   	push   %eax
f0100de4:	e8 40 11 00 00       	call   f0101f29 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100de9:	a1 48 49 11 f0       	mov    0xf0114948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dee:	83 c4 10             	add    $0x10,%esp
f0100df1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100df6:	77 15                	ja     f0100e0d <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100df8:	50                   	push   %eax
f0100df9:	68 44 29 10 f0       	push   $0xf0102944
f0100dfe:	68 8f 00 00 00       	push   $0x8f
f0100e03:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100e08:	e8 7e f2 ff ff       	call   f010008b <_panic>
f0100e0d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100e13:	83 ca 05             	or     $0x5,%edx
f0100e16:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages*sizeof(struct PageInfo));
f0100e1c:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100e21:	c1 e0 03             	shl    $0x3,%eax
f0100e24:	e8 3b fa ff ff       	call   f0100864 <boot_alloc>
f0100e29:	a3 4c 49 11 f0       	mov    %eax,0xf011494c
        memset(pages,0,npages*sizeof(struct PageInfo));
f0100e2e:	83 ec 04             	sub    $0x4,%esp
f0100e31:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f0100e37:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100e3e:	52                   	push   %edx
f0100e3f:	6a 00                	push   $0x0
f0100e41:	50                   	push   %eax
f0100e42:	e8 e2 10 00 00       	call   f0101f29 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100e47:	e8 91 fd ff ff       	call   f0100bdd <page_init>

	check_page_free_list(1);
f0100e4c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e51:	e8 d3 fa ff ff       	call   f0100929 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100e56:	83 c4 10             	add    $0x10,%esp
f0100e59:	83 3d 4c 49 11 f0 00 	cmpl   $0x0,0xf011494c
f0100e60:	75 17                	jne    f0100e79 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0100e62:	83 ec 04             	sub    $0x4,%esp
f0100e65:	68 f9 2a 10 f0       	push   $0xf0102af9
f0100e6a:	68 22 02 00 00       	push   $0x222
f0100e6f:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100e74:	e8 12 f2 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100e79:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100e7e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e83:	eb 05                	jmp    f0100e8a <mem_init+0x120>
		++nfree;
f0100e85:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100e88:	8b 00                	mov    (%eax),%eax
f0100e8a:	85 c0                	test   %eax,%eax
f0100e8c:	75 f7                	jne    f0100e85 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100e8e:	83 ec 0c             	sub    $0xc,%esp
f0100e91:	6a 00                	push   $0x0
f0100e93:	e8 25 fe ff ff       	call   f0100cbd <page_alloc>
f0100e98:	89 c7                	mov    %eax,%edi
f0100e9a:	83 c4 10             	add    $0x10,%esp
f0100e9d:	85 c0                	test   %eax,%eax
f0100e9f:	75 19                	jne    f0100eba <mem_init+0x150>
f0100ea1:	68 14 2b 10 f0       	push   $0xf0102b14
f0100ea6:	68 62 2a 10 f0       	push   $0xf0102a62
f0100eab:	68 2a 02 00 00       	push   $0x22a
f0100eb0:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100eb5:	e8 d1 f1 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100eba:	83 ec 0c             	sub    $0xc,%esp
f0100ebd:	6a 00                	push   $0x0
f0100ebf:	e8 f9 fd ff ff       	call   f0100cbd <page_alloc>
f0100ec4:	89 c6                	mov    %eax,%esi
f0100ec6:	83 c4 10             	add    $0x10,%esp
f0100ec9:	85 c0                	test   %eax,%eax
f0100ecb:	75 19                	jne    f0100ee6 <mem_init+0x17c>
f0100ecd:	68 2a 2b 10 f0       	push   $0xf0102b2a
f0100ed2:	68 62 2a 10 f0       	push   $0xf0102a62
f0100ed7:	68 2b 02 00 00       	push   $0x22b
f0100edc:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100ee1:	e8 a5 f1 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100ee6:	83 ec 0c             	sub    $0xc,%esp
f0100ee9:	6a 00                	push   $0x0
f0100eeb:	e8 cd fd ff ff       	call   f0100cbd <page_alloc>
f0100ef0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ef3:	83 c4 10             	add    $0x10,%esp
f0100ef6:	85 c0                	test   %eax,%eax
f0100ef8:	75 19                	jne    f0100f13 <mem_init+0x1a9>
f0100efa:	68 40 2b 10 f0       	push   $0xf0102b40
f0100eff:	68 62 2a 10 f0       	push   $0xf0102a62
f0100f04:	68 2c 02 00 00       	push   $0x22c
f0100f09:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100f0e:	e8 78 f1 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100f13:	39 f7                	cmp    %esi,%edi
f0100f15:	75 19                	jne    f0100f30 <mem_init+0x1c6>
f0100f17:	68 56 2b 10 f0       	push   $0xf0102b56
f0100f1c:	68 62 2a 10 f0       	push   $0xf0102a62
f0100f21:	68 2f 02 00 00       	push   $0x22f
f0100f26:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100f2b:	e8 5b f1 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100f30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f33:	39 c7                	cmp    %eax,%edi
f0100f35:	74 04                	je     f0100f3b <mem_init+0x1d1>
f0100f37:	39 c6                	cmp    %eax,%esi
f0100f39:	75 19                	jne    f0100f54 <mem_init+0x1ea>
f0100f3b:	68 cc 29 10 f0       	push   $0xf01029cc
f0100f40:	68 62 2a 10 f0       	push   $0xf0102a62
f0100f45:	68 30 02 00 00       	push   $0x230
f0100f4a:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100f4f:	e8 37 f1 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f54:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0100f5a:	8b 15 44 49 11 f0    	mov    0xf0114944,%edx
f0100f60:	c1 e2 0c             	shl    $0xc,%edx
f0100f63:	89 f8                	mov    %edi,%eax
f0100f65:	29 c8                	sub    %ecx,%eax
f0100f67:	c1 f8 03             	sar    $0x3,%eax
f0100f6a:	c1 e0 0c             	shl    $0xc,%eax
f0100f6d:	39 d0                	cmp    %edx,%eax
f0100f6f:	72 19                	jb     f0100f8a <mem_init+0x220>
f0100f71:	68 68 2b 10 f0       	push   $0xf0102b68
f0100f76:	68 62 2a 10 f0       	push   $0xf0102a62
f0100f7b:	68 31 02 00 00       	push   $0x231
f0100f80:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100f85:	e8 01 f1 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0100f8a:	89 f0                	mov    %esi,%eax
f0100f8c:	29 c8                	sub    %ecx,%eax
f0100f8e:	c1 f8 03             	sar    $0x3,%eax
f0100f91:	c1 e0 0c             	shl    $0xc,%eax
f0100f94:	39 c2                	cmp    %eax,%edx
f0100f96:	77 19                	ja     f0100fb1 <mem_init+0x247>
f0100f98:	68 85 2b 10 f0       	push   $0xf0102b85
f0100f9d:	68 62 2a 10 f0       	push   $0xf0102a62
f0100fa2:	68 32 02 00 00       	push   $0x232
f0100fa7:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100fac:	e8 da f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0100fb1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fb4:	29 c8                	sub    %ecx,%eax
f0100fb6:	c1 f8 03             	sar    $0x3,%eax
f0100fb9:	c1 e0 0c             	shl    $0xc,%eax
f0100fbc:	39 c2                	cmp    %eax,%edx
f0100fbe:	77 19                	ja     f0100fd9 <mem_init+0x26f>
f0100fc0:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100fc5:	68 62 2a 10 f0       	push   $0xf0102a62
f0100fca:	68 33 02 00 00       	push   $0x233
f0100fcf:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0100fd4:	e8 b2 f0 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0100fd9:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100fde:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0100fe1:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0100fe8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0100feb:	83 ec 0c             	sub    $0xc,%esp
f0100fee:	6a 00                	push   $0x0
f0100ff0:	e8 c8 fc ff ff       	call   f0100cbd <page_alloc>
f0100ff5:	83 c4 10             	add    $0x10,%esp
f0100ff8:	85 c0                	test   %eax,%eax
f0100ffa:	74 19                	je     f0101015 <mem_init+0x2ab>
f0100ffc:	68 bf 2b 10 f0       	push   $0xf0102bbf
f0101001:	68 62 2a 10 f0       	push   $0xf0102a62
f0101006:	68 3a 02 00 00       	push   $0x23a
f010100b:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101010:	e8 76 f0 ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101015:	83 ec 0c             	sub    $0xc,%esp
f0101018:	57                   	push   %edi
f0101019:	e8 0f fd ff ff       	call   f0100d2d <page_free>
	page_free(pp1);
f010101e:	89 34 24             	mov    %esi,(%esp)
f0101021:	e8 07 fd ff ff       	call   f0100d2d <page_free>
	page_free(pp2);
f0101026:	83 c4 04             	add    $0x4,%esp
f0101029:	ff 75 e4             	pushl  -0x1c(%ebp)
f010102c:	e8 fc fc ff ff       	call   f0100d2d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101031:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101038:	e8 80 fc ff ff       	call   f0100cbd <page_alloc>
f010103d:	89 c6                	mov    %eax,%esi
f010103f:	83 c4 10             	add    $0x10,%esp
f0101042:	85 c0                	test   %eax,%eax
f0101044:	75 19                	jne    f010105f <mem_init+0x2f5>
f0101046:	68 14 2b 10 f0       	push   $0xf0102b14
f010104b:	68 62 2a 10 f0       	push   $0xf0102a62
f0101050:	68 41 02 00 00       	push   $0x241
f0101055:	68 3c 2a 10 f0       	push   $0xf0102a3c
f010105a:	e8 2c f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010105f:	83 ec 0c             	sub    $0xc,%esp
f0101062:	6a 00                	push   $0x0
f0101064:	e8 54 fc ff ff       	call   f0100cbd <page_alloc>
f0101069:	89 c7                	mov    %eax,%edi
f010106b:	83 c4 10             	add    $0x10,%esp
f010106e:	85 c0                	test   %eax,%eax
f0101070:	75 19                	jne    f010108b <mem_init+0x321>
f0101072:	68 2a 2b 10 f0       	push   $0xf0102b2a
f0101077:	68 62 2a 10 f0       	push   $0xf0102a62
f010107c:	68 42 02 00 00       	push   $0x242
f0101081:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101086:	e8 00 f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010108b:	83 ec 0c             	sub    $0xc,%esp
f010108e:	6a 00                	push   $0x0
f0101090:	e8 28 fc ff ff       	call   f0100cbd <page_alloc>
f0101095:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101098:	83 c4 10             	add    $0x10,%esp
f010109b:	85 c0                	test   %eax,%eax
f010109d:	75 19                	jne    f01010b8 <mem_init+0x34e>
f010109f:	68 40 2b 10 f0       	push   $0xf0102b40
f01010a4:	68 62 2a 10 f0       	push   $0xf0102a62
f01010a9:	68 43 02 00 00       	push   $0x243
f01010ae:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01010b3:	e8 d3 ef ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01010b8:	39 fe                	cmp    %edi,%esi
f01010ba:	75 19                	jne    f01010d5 <mem_init+0x36b>
f01010bc:	68 56 2b 10 f0       	push   $0xf0102b56
f01010c1:	68 62 2a 10 f0       	push   $0xf0102a62
f01010c6:	68 45 02 00 00       	push   $0x245
f01010cb:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01010d0:	e8 b6 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01010d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010d8:	39 c6                	cmp    %eax,%esi
f01010da:	74 04                	je     f01010e0 <mem_init+0x376>
f01010dc:	39 c7                	cmp    %eax,%edi
f01010de:	75 19                	jne    f01010f9 <mem_init+0x38f>
f01010e0:	68 cc 29 10 f0       	push   $0xf01029cc
f01010e5:	68 62 2a 10 f0       	push   $0xf0102a62
f01010ea:	68 46 02 00 00       	push   $0x246
f01010ef:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01010f4:	e8 92 ef ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01010f9:	83 ec 0c             	sub    $0xc,%esp
f01010fc:	6a 00                	push   $0x0
f01010fe:	e8 ba fb ff ff       	call   f0100cbd <page_alloc>
f0101103:	83 c4 10             	add    $0x10,%esp
f0101106:	85 c0                	test   %eax,%eax
f0101108:	74 19                	je     f0101123 <mem_init+0x3b9>
f010110a:	68 bf 2b 10 f0       	push   $0xf0102bbf
f010110f:	68 62 2a 10 f0       	push   $0xf0102a62
f0101114:	68 47 02 00 00       	push   $0x247
f0101119:	68 3c 2a 10 f0       	push   $0xf0102a3c
f010111e:	e8 68 ef ff ff       	call   f010008b <_panic>
f0101123:	89 f0                	mov    %esi,%eax
f0101125:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f010112b:	c1 f8 03             	sar    $0x3,%eax
f010112e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101131:	89 c2                	mov    %eax,%edx
f0101133:	c1 ea 0c             	shr    $0xc,%edx
f0101136:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f010113c:	72 12                	jb     f0101150 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010113e:	50                   	push   %eax
f010113f:	68 5c 28 10 f0       	push   $0xf010285c
f0101144:	6a 52                	push   $0x52
f0101146:	68 48 2a 10 f0       	push   $0xf0102a48
f010114b:	e8 3b ef ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101150:	83 ec 04             	sub    $0x4,%esp
f0101153:	68 00 10 00 00       	push   $0x1000
f0101158:	6a 01                	push   $0x1
f010115a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010115f:	50                   	push   %eax
f0101160:	e8 c4 0d 00 00       	call   f0101f29 <memset>
	page_free(pp0);
f0101165:	89 34 24             	mov    %esi,(%esp)
f0101168:	e8 c0 fb ff ff       	call   f0100d2d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010116d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101174:	e8 44 fb ff ff       	call   f0100cbd <page_alloc>
f0101179:	83 c4 10             	add    $0x10,%esp
f010117c:	85 c0                	test   %eax,%eax
f010117e:	75 19                	jne    f0101199 <mem_init+0x42f>
f0101180:	68 ce 2b 10 f0       	push   $0xf0102bce
f0101185:	68 62 2a 10 f0       	push   $0xf0102a62
f010118a:	68 4c 02 00 00       	push   $0x24c
f010118f:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101194:	e8 f2 ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101199:	39 c6                	cmp    %eax,%esi
f010119b:	74 19                	je     f01011b6 <mem_init+0x44c>
f010119d:	68 ec 2b 10 f0       	push   $0xf0102bec
f01011a2:	68 62 2a 10 f0       	push   $0xf0102a62
f01011a7:	68 4d 02 00 00       	push   $0x24d
f01011ac:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01011b1:	e8 d5 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011b6:	89 f0                	mov    %esi,%eax
f01011b8:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f01011be:	c1 f8 03             	sar    $0x3,%eax
f01011c1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011c4:	89 c2                	mov    %eax,%edx
f01011c6:	c1 ea 0c             	shr    $0xc,%edx
f01011c9:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f01011cf:	72 12                	jb     f01011e3 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011d1:	50                   	push   %eax
f01011d2:	68 5c 28 10 f0       	push   $0xf010285c
f01011d7:	6a 52                	push   $0x52
f01011d9:	68 48 2a 10 f0       	push   $0xf0102a48
f01011de:	e8 a8 ee ff ff       	call   f010008b <_panic>
f01011e3:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01011e9:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01011ef:	80 38 00             	cmpb   $0x0,(%eax)
f01011f2:	74 19                	je     f010120d <mem_init+0x4a3>
f01011f4:	68 fc 2b 10 f0       	push   $0xf0102bfc
f01011f9:	68 62 2a 10 f0       	push   $0xf0102a62
f01011fe:	68 50 02 00 00       	push   $0x250
f0101203:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101208:	e8 7e ee ff ff       	call   f010008b <_panic>
f010120d:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101210:	39 d0                	cmp    %edx,%eax
f0101212:	75 db                	jne    f01011ef <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101214:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101217:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f010121c:	83 ec 0c             	sub    $0xc,%esp
f010121f:	56                   	push   %esi
f0101220:	e8 08 fb ff ff       	call   f0100d2d <page_free>
	page_free(pp1);
f0101225:	89 3c 24             	mov    %edi,(%esp)
f0101228:	e8 00 fb ff ff       	call   f0100d2d <page_free>
	page_free(pp2);
f010122d:	83 c4 04             	add    $0x4,%esp
f0101230:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101233:	e8 f5 fa ff ff       	call   f0100d2d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101238:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f010123d:	83 c4 10             	add    $0x10,%esp
f0101240:	eb 05                	jmp    f0101247 <mem_init+0x4dd>
		--nfree;
f0101242:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101245:	8b 00                	mov    (%eax),%eax
f0101247:	85 c0                	test   %eax,%eax
f0101249:	75 f7                	jne    f0101242 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f010124b:	85 db                	test   %ebx,%ebx
f010124d:	74 19                	je     f0101268 <mem_init+0x4fe>
f010124f:	68 06 2c 10 f0       	push   $0xf0102c06
f0101254:	68 62 2a 10 f0       	push   $0xf0102a62
f0101259:	68 5d 02 00 00       	push   $0x25d
f010125e:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101263:	e8 23 ee ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101268:	83 ec 0c             	sub    $0xc,%esp
f010126b:	68 ec 29 10 f0       	push   $0xf01029ec
f0101270:	e8 cb 01 00 00       	call   f0101440 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101275:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010127c:	e8 3c fa ff ff       	call   f0100cbd <page_alloc>
f0101281:	89 c3                	mov    %eax,%ebx
f0101283:	83 c4 10             	add    $0x10,%esp
f0101286:	85 c0                	test   %eax,%eax
f0101288:	75 19                	jne    f01012a3 <mem_init+0x539>
f010128a:	68 14 2b 10 f0       	push   $0xf0102b14
f010128f:	68 62 2a 10 f0       	push   $0xf0102a62
f0101294:	68 b6 02 00 00       	push   $0x2b6
f0101299:	68 3c 2a 10 f0       	push   $0xf0102a3c
f010129e:	e8 e8 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012a3:	83 ec 0c             	sub    $0xc,%esp
f01012a6:	6a 00                	push   $0x0
f01012a8:	e8 10 fa ff ff       	call   f0100cbd <page_alloc>
f01012ad:	89 c6                	mov    %eax,%esi
f01012af:	83 c4 10             	add    $0x10,%esp
f01012b2:	85 c0                	test   %eax,%eax
f01012b4:	75 19                	jne    f01012cf <mem_init+0x565>
f01012b6:	68 2a 2b 10 f0       	push   $0xf0102b2a
f01012bb:	68 62 2a 10 f0       	push   $0xf0102a62
f01012c0:	68 b7 02 00 00       	push   $0x2b7
f01012c5:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01012ca:	e8 bc ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01012cf:	83 ec 0c             	sub    $0xc,%esp
f01012d2:	6a 00                	push   $0x0
f01012d4:	e8 e4 f9 ff ff       	call   f0100cbd <page_alloc>
f01012d9:	83 c4 10             	add    $0x10,%esp
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	75 19                	jne    f01012f9 <mem_init+0x58f>
f01012e0:	68 40 2b 10 f0       	push   $0xf0102b40
f01012e5:	68 62 2a 10 f0       	push   $0xf0102a62
f01012ea:	68 b8 02 00 00       	push   $0x2b8
f01012ef:	68 3c 2a 10 f0       	push   $0xf0102a3c
f01012f4:	e8 92 ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012f9:	39 f3                	cmp    %esi,%ebx
f01012fb:	75 19                	jne    f0101316 <mem_init+0x5ac>
f01012fd:	68 56 2b 10 f0       	push   $0xf0102b56
f0101302:	68 62 2a 10 f0       	push   $0xf0102a62
f0101307:	68 bb 02 00 00       	push   $0x2bb
f010130c:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101311:	e8 75 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101316:	39 c6                	cmp    %eax,%esi
f0101318:	74 04                	je     f010131e <mem_init+0x5b4>
f010131a:	39 c3                	cmp    %eax,%ebx
f010131c:	75 19                	jne    f0101337 <mem_init+0x5cd>
f010131e:	68 cc 29 10 f0       	push   $0xf01029cc
f0101323:	68 62 2a 10 f0       	push   $0xf0102a62
f0101328:	68 bc 02 00 00       	push   $0x2bc
f010132d:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101332:	e8 54 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101337:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f010133e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101341:	83 ec 0c             	sub    $0xc,%esp
f0101344:	6a 00                	push   $0x0
f0101346:	e8 72 f9 ff ff       	call   f0100cbd <page_alloc>
f010134b:	83 c4 10             	add    $0x10,%esp
f010134e:	85 c0                	test   %eax,%eax
f0101350:	74 19                	je     f010136b <mem_init+0x601>
f0101352:	68 bf 2b 10 f0       	push   $0xf0102bbf
f0101357:	68 62 2a 10 f0       	push   $0xf0102a62
f010135c:	68 c3 02 00 00       	push   $0x2c3
f0101361:	68 3c 2a 10 f0       	push   $0xf0102a3c
f0101366:	e8 20 ed ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010136b:	68 0c 2a 10 f0       	push   $0xf0102a0c
f0101370:	68 62 2a 10 f0       	push   $0xf0102a62
f0101375:	68 c9 02 00 00       	push   $0x2c9
f010137a:	68 3c 2a 10 f0       	push   $0xf0102a3c
f010137f:	e8 07 ed ff ff       	call   f010008b <_panic>

f0101384 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101384:	55                   	push   %ebp
f0101385:	89 e5                	mov    %esp,%ebp
f0101387:	83 ec 08             	sub    $0x8,%esp
f010138a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010138d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101391:	83 e8 01             	sub    $0x1,%eax
f0101394:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101398:	66 85 c0             	test   %ax,%ax
f010139b:	75 0c                	jne    f01013a9 <page_decref+0x25>
		page_free(pp);
f010139d:	83 ec 0c             	sub    $0xc,%esp
f01013a0:	52                   	push   %edx
f01013a1:	e8 87 f9 ff ff       	call   f0100d2d <page_free>
f01013a6:	83 c4 10             	add    $0x10,%esp
}
f01013a9:	c9                   	leave  
f01013aa:	c3                   	ret    

f01013ab <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01013ab:	55                   	push   %ebp
f01013ac:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01013ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b3:	5d                   	pop    %ebp
f01013b4:	c3                   	ret    

f01013b5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01013b5:	55                   	push   %ebp
f01013b6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01013b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01013bd:	5d                   	pop    %ebp
f01013be:	c3                   	ret    

f01013bf <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01013bf:	55                   	push   %ebp
f01013c0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01013c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c7:	5d                   	pop    %ebp
f01013c8:	c3                   	ret    

f01013c9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01013c9:	55                   	push   %ebp
f01013ca:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01013cc:	5d                   	pop    %ebp
f01013cd:	c3                   	ret    

f01013ce <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01013ce:	55                   	push   %ebp
f01013cf:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013d1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d4:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01013d7:	5d                   	pop    %ebp
f01013d8:	c3                   	ret    

f01013d9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01013d9:	55                   	push   %ebp
f01013da:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01013dc:	ba 70 00 00 00       	mov    $0x70,%edx
f01013e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01013e5:	ba 71 00 00 00       	mov    $0x71,%edx
f01013ea:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01013eb:	0f b6 c0             	movzbl %al,%eax
}
f01013ee:	5d                   	pop    %ebp
f01013ef:	c3                   	ret    

f01013f0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01013f3:	ba 70 00 00 00       	mov    $0x70,%edx
f01013f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fb:	ee                   	out    %al,(%dx)
f01013fc:	ba 71 00 00 00       	mov    $0x71,%edx
f0101401:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101404:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101405:	5d                   	pop    %ebp
f0101406:	c3                   	ret    

f0101407 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010140d:	ff 75 08             	pushl  0x8(%ebp)
f0101410:	e8 eb f1 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0101415:	83 c4 10             	add    $0x10,%esp
f0101418:	c9                   	leave  
f0101419:	c3                   	ret    

f010141a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010141a:	55                   	push   %ebp
f010141b:	89 e5                	mov    %esp,%ebp
f010141d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101420:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101427:	ff 75 0c             	pushl  0xc(%ebp)
f010142a:	ff 75 08             	pushl  0x8(%ebp)
f010142d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101430:	50                   	push   %eax
f0101431:	68 07 14 10 f0       	push   $0xf0101407
f0101436:	e8 c9 03 00 00       	call   f0101804 <vprintfmt>
	return cnt;
}
f010143b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010143e:	c9                   	leave  
f010143f:	c3                   	ret    

f0101440 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101446:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101449:	50                   	push   %eax
f010144a:	ff 75 08             	pushl  0x8(%ebp)
f010144d:	e8 c8 ff ff ff       	call   f010141a <vcprintf>
	va_end(ap);

	return cnt;
}
f0101452:	c9                   	leave  
f0101453:	c3                   	ret    

f0101454 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101454:	55                   	push   %ebp
f0101455:	89 e5                	mov    %esp,%ebp
f0101457:	57                   	push   %edi
f0101458:	56                   	push   %esi
f0101459:	53                   	push   %ebx
f010145a:	83 ec 14             	sub    $0x14,%esp
f010145d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101460:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101463:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101466:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101469:	8b 1a                	mov    (%edx),%ebx
f010146b:	8b 01                	mov    (%ecx),%eax
f010146d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101470:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101477:	eb 7f                	jmp    f01014f8 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101479:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010147c:	01 d8                	add    %ebx,%eax
f010147e:	89 c6                	mov    %eax,%esi
f0101480:	c1 ee 1f             	shr    $0x1f,%esi
f0101483:	01 c6                	add    %eax,%esi
f0101485:	d1 fe                	sar    %esi
f0101487:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010148a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010148d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101490:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101492:	eb 03                	jmp    f0101497 <stab_binsearch+0x43>
			m--;
f0101494:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101497:	39 c3                	cmp    %eax,%ebx
f0101499:	7f 0d                	jg     f01014a8 <stab_binsearch+0x54>
f010149b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010149f:	83 ea 0c             	sub    $0xc,%edx
f01014a2:	39 f9                	cmp    %edi,%ecx
f01014a4:	75 ee                	jne    f0101494 <stab_binsearch+0x40>
f01014a6:	eb 05                	jmp    f01014ad <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01014a8:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01014ab:	eb 4b                	jmp    f01014f8 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01014ad:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01014b0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01014b3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01014b7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01014ba:	76 11                	jbe    f01014cd <stab_binsearch+0x79>
			*region_left = m;
f01014bc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01014bf:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01014c1:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014c4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01014cb:	eb 2b                	jmp    f01014f8 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01014cd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01014d0:	73 14                	jae    f01014e6 <stab_binsearch+0x92>
			*region_right = m - 1;
f01014d2:	83 e8 01             	sub    $0x1,%eax
f01014d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01014d8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014db:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01014e4:	eb 12                	jmp    f01014f8 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01014e6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01014e9:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01014eb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01014ef:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01014f1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01014f8:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01014fb:	0f 8e 78 ff ff ff    	jle    f0101479 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101501:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101505:	75 0f                	jne    f0101516 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0101507:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010150a:	8b 00                	mov    (%eax),%eax
f010150c:	83 e8 01             	sub    $0x1,%eax
f010150f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101512:	89 06                	mov    %eax,(%esi)
f0101514:	eb 2c                	jmp    f0101542 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101516:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101519:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010151b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010151e:	8b 0e                	mov    (%esi),%ecx
f0101520:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101523:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101526:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101529:	eb 03                	jmp    f010152e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010152b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010152e:	39 c8                	cmp    %ecx,%eax
f0101530:	7e 0b                	jle    f010153d <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101532:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101536:	83 ea 0c             	sub    $0xc,%edx
f0101539:	39 df                	cmp    %ebx,%edi
f010153b:	75 ee                	jne    f010152b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010153d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101540:	89 06                	mov    %eax,(%esi)
	}
}
f0101542:	83 c4 14             	add    $0x14,%esp
f0101545:	5b                   	pop    %ebx
f0101546:	5e                   	pop    %esi
f0101547:	5f                   	pop    %edi
f0101548:	5d                   	pop    %ebp
f0101549:	c3                   	ret    

f010154a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
f010154d:	57                   	push   %edi
f010154e:	56                   	push   %esi
f010154f:	53                   	push   %ebx
f0101550:	83 ec 1c             	sub    $0x1c,%esp
f0101553:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101556:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101559:	c7 06 11 2c 10 f0    	movl   $0xf0102c11,(%esi)
	info->eip_line = 0;
f010155f:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101566:	c7 46 08 11 2c 10 f0 	movl   $0xf0102c11,0x8(%esi)
	info->eip_fn_namelen = 9;
f010156d:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0101574:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101577:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010157e:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0101584:	76 11                	jbe    f0101597 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101586:	b8 6f 95 10 f0       	mov    $0xf010956f,%eax
f010158b:	3d c1 78 10 f0       	cmp    $0xf01078c1,%eax
f0101590:	77 19                	ja     f01015ab <debuginfo_eip+0x61>
f0101592:	e9 62 01 00 00       	jmp    f01016f9 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101597:	83 ec 04             	sub    $0x4,%esp
f010159a:	68 1b 2c 10 f0       	push   $0xf0102c1b
f010159f:	6a 7f                	push   $0x7f
f01015a1:	68 28 2c 10 f0       	push   $0xf0102c28
f01015a6:	e8 e0 ea ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01015ab:	80 3d 6e 95 10 f0 00 	cmpb   $0x0,0xf010956e
f01015b2:	0f 85 48 01 00 00    	jne    f0101700 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01015b8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01015bf:	b8 c0 78 10 f0       	mov    $0xf01078c0,%eax
f01015c4:	2d 44 2e 10 f0       	sub    $0xf0102e44,%eax
f01015c9:	c1 f8 02             	sar    $0x2,%eax
f01015cc:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01015d2:	83 e8 01             	sub    $0x1,%eax
f01015d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01015d8:	83 ec 08             	sub    $0x8,%esp
f01015db:	57                   	push   %edi
f01015dc:	6a 64                	push   $0x64
f01015de:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01015e1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01015e4:	b8 44 2e 10 f0       	mov    $0xf0102e44,%eax
f01015e9:	e8 66 fe ff ff       	call   f0101454 <stab_binsearch>
	if (lfile == 0)
f01015ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015f1:	83 c4 10             	add    $0x10,%esp
f01015f4:	85 c0                	test   %eax,%eax
f01015f6:	0f 84 0b 01 00 00    	je     f0101707 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01015fc:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01015ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101602:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101605:	83 ec 08             	sub    $0x8,%esp
f0101608:	57                   	push   %edi
f0101609:	6a 24                	push   $0x24
f010160b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010160e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101611:	b8 44 2e 10 f0       	mov    $0xf0102e44,%eax
f0101616:	e8 39 fe ff ff       	call   f0101454 <stab_binsearch>

	if (lfun <= rfun) {
f010161b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010161e:	83 c4 10             	add    $0x10,%esp
f0101621:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0101624:	7f 31                	jg     f0101657 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101626:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101629:	c1 e0 02             	shl    $0x2,%eax
f010162c:	8d 90 44 2e 10 f0    	lea    -0xfefd1bc(%eax),%edx
f0101632:	8b 88 44 2e 10 f0    	mov    -0xfefd1bc(%eax),%ecx
f0101638:	b8 6f 95 10 f0       	mov    $0xf010956f,%eax
f010163d:	2d c1 78 10 f0       	sub    $0xf01078c1,%eax
f0101642:	39 c1                	cmp    %eax,%ecx
f0101644:	73 09                	jae    f010164f <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101646:	81 c1 c1 78 10 f0    	add    $0xf01078c1,%ecx
f010164c:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010164f:	8b 42 08             	mov    0x8(%edx),%eax
f0101652:	89 46 10             	mov    %eax,0x10(%esi)
f0101655:	eb 06                	jmp    f010165d <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101657:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010165a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010165d:	83 ec 08             	sub    $0x8,%esp
f0101660:	6a 3a                	push   $0x3a
f0101662:	ff 76 08             	pushl  0x8(%esi)
f0101665:	e8 a3 08 00 00       	call   f0101f0d <strfind>
f010166a:	2b 46 08             	sub    0x8(%esi),%eax
f010166d:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101670:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101673:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101676:	8d 04 85 44 2e 10 f0 	lea    -0xfefd1bc(,%eax,4),%eax
f010167d:	83 c4 10             	add    $0x10,%esp
f0101680:	eb 06                	jmp    f0101688 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101682:	83 eb 01             	sub    $0x1,%ebx
f0101685:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101688:	39 fb                	cmp    %edi,%ebx
f010168a:	7c 34                	jl     f01016c0 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f010168c:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0101690:	80 fa 84             	cmp    $0x84,%dl
f0101693:	74 0b                	je     f01016a0 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101695:	80 fa 64             	cmp    $0x64,%dl
f0101698:	75 e8                	jne    f0101682 <debuginfo_eip+0x138>
f010169a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010169e:	74 e2                	je     f0101682 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01016a0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01016a3:	8b 14 85 44 2e 10 f0 	mov    -0xfefd1bc(,%eax,4),%edx
f01016aa:	b8 6f 95 10 f0       	mov    $0xf010956f,%eax
f01016af:	2d c1 78 10 f0       	sub    $0xf01078c1,%eax
f01016b4:	39 c2                	cmp    %eax,%edx
f01016b6:	73 08                	jae    f01016c0 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01016b8:	81 c2 c1 78 10 f0    	add    $0xf01078c1,%edx
f01016be:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01016c0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01016c3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01016c6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01016cb:	39 cb                	cmp    %ecx,%ebx
f01016cd:	7d 44                	jge    f0101713 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f01016cf:	8d 53 01             	lea    0x1(%ebx),%edx
f01016d2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01016d5:	8d 04 85 44 2e 10 f0 	lea    -0xfefd1bc(,%eax,4),%eax
f01016dc:	eb 07                	jmp    f01016e5 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01016de:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01016e2:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01016e5:	39 ca                	cmp    %ecx,%edx
f01016e7:	74 25                	je     f010170e <debuginfo_eip+0x1c4>
f01016e9:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01016ec:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01016f0:	74 ec                	je     f01016de <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01016f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01016f7:	eb 1a                	jmp    f0101713 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01016f9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01016fe:	eb 13                	jmp    f0101713 <debuginfo_eip+0x1c9>
f0101700:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101705:	eb 0c                	jmp    f0101713 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101707:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010170c:	eb 05                	jmp    f0101713 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010170e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101713:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101716:	5b                   	pop    %ebx
f0101717:	5e                   	pop    %esi
f0101718:	5f                   	pop    %edi
f0101719:	5d                   	pop    %ebp
f010171a:	c3                   	ret    

f010171b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010171b:	55                   	push   %ebp
f010171c:	89 e5                	mov    %esp,%ebp
f010171e:	57                   	push   %edi
f010171f:	56                   	push   %esi
f0101720:	53                   	push   %ebx
f0101721:	83 ec 1c             	sub    $0x1c,%esp
f0101724:	89 c7                	mov    %eax,%edi
f0101726:	89 d6                	mov    %edx,%esi
f0101728:	8b 45 08             	mov    0x8(%ebp),%eax
f010172b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010172e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101731:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101734:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101737:	bb 00 00 00 00       	mov    $0x0,%ebx
f010173c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010173f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101742:	39 d3                	cmp    %edx,%ebx
f0101744:	72 05                	jb     f010174b <printnum+0x30>
f0101746:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101749:	77 45                	ja     f0101790 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010174b:	83 ec 0c             	sub    $0xc,%esp
f010174e:	ff 75 18             	pushl  0x18(%ebp)
f0101751:	8b 45 14             	mov    0x14(%ebp),%eax
f0101754:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101757:	53                   	push   %ebx
f0101758:	ff 75 10             	pushl  0x10(%ebp)
f010175b:	83 ec 08             	sub    $0x8,%esp
f010175e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101761:	ff 75 e0             	pushl  -0x20(%ebp)
f0101764:	ff 75 dc             	pushl  -0x24(%ebp)
f0101767:	ff 75 d8             	pushl  -0x28(%ebp)
f010176a:	e8 c1 09 00 00       	call   f0102130 <__udivdi3>
f010176f:	83 c4 18             	add    $0x18,%esp
f0101772:	52                   	push   %edx
f0101773:	50                   	push   %eax
f0101774:	89 f2                	mov    %esi,%edx
f0101776:	89 f8                	mov    %edi,%eax
f0101778:	e8 9e ff ff ff       	call   f010171b <printnum>
f010177d:	83 c4 20             	add    $0x20,%esp
f0101780:	eb 18                	jmp    f010179a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101782:	83 ec 08             	sub    $0x8,%esp
f0101785:	56                   	push   %esi
f0101786:	ff 75 18             	pushl  0x18(%ebp)
f0101789:	ff d7                	call   *%edi
f010178b:	83 c4 10             	add    $0x10,%esp
f010178e:	eb 03                	jmp    f0101793 <printnum+0x78>
f0101790:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101793:	83 eb 01             	sub    $0x1,%ebx
f0101796:	85 db                	test   %ebx,%ebx
f0101798:	7f e8                	jg     f0101782 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010179a:	83 ec 08             	sub    $0x8,%esp
f010179d:	56                   	push   %esi
f010179e:	83 ec 04             	sub    $0x4,%esp
f01017a1:	ff 75 e4             	pushl  -0x1c(%ebp)
f01017a4:	ff 75 e0             	pushl  -0x20(%ebp)
f01017a7:	ff 75 dc             	pushl  -0x24(%ebp)
f01017aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01017ad:	e8 ae 0a 00 00       	call   f0102260 <__umoddi3>
f01017b2:	83 c4 14             	add    $0x14,%esp
f01017b5:	0f be 80 36 2c 10 f0 	movsbl -0xfefd3ca(%eax),%eax
f01017bc:	50                   	push   %eax
f01017bd:	ff d7                	call   *%edi
}
f01017bf:	83 c4 10             	add    $0x10,%esp
f01017c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017c5:	5b                   	pop    %ebx
f01017c6:	5e                   	pop    %esi
f01017c7:	5f                   	pop    %edi
f01017c8:	5d                   	pop    %ebp
f01017c9:	c3                   	ret    

f01017ca <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01017ca:	55                   	push   %ebp
f01017cb:	89 e5                	mov    %esp,%ebp
f01017cd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01017d0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01017d4:	8b 10                	mov    (%eax),%edx
f01017d6:	3b 50 04             	cmp    0x4(%eax),%edx
f01017d9:	73 0a                	jae    f01017e5 <sprintputch+0x1b>
		*b->buf++ = ch;
f01017db:	8d 4a 01             	lea    0x1(%edx),%ecx
f01017de:	89 08                	mov    %ecx,(%eax)
f01017e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01017e3:	88 02                	mov    %al,(%edx)
}
f01017e5:	5d                   	pop    %ebp
f01017e6:	c3                   	ret    

f01017e7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01017e7:	55                   	push   %ebp
f01017e8:	89 e5                	mov    %esp,%ebp
f01017ea:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01017ed:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01017f0:	50                   	push   %eax
f01017f1:	ff 75 10             	pushl  0x10(%ebp)
f01017f4:	ff 75 0c             	pushl  0xc(%ebp)
f01017f7:	ff 75 08             	pushl  0x8(%ebp)
f01017fa:	e8 05 00 00 00       	call   f0101804 <vprintfmt>
	va_end(ap);
}
f01017ff:	83 c4 10             	add    $0x10,%esp
f0101802:	c9                   	leave  
f0101803:	c3                   	ret    

f0101804 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101804:	55                   	push   %ebp
f0101805:	89 e5                	mov    %esp,%ebp
f0101807:	57                   	push   %edi
f0101808:	56                   	push   %esi
f0101809:	53                   	push   %ebx
f010180a:	83 ec 2c             	sub    $0x2c,%esp
f010180d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101810:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101813:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101816:	eb 12                	jmp    f010182a <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101818:	85 c0                	test   %eax,%eax
f010181a:	0f 84 42 04 00 00    	je     f0101c62 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0101820:	83 ec 08             	sub    $0x8,%esp
f0101823:	53                   	push   %ebx
f0101824:	50                   	push   %eax
f0101825:	ff d6                	call   *%esi
f0101827:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010182a:	83 c7 01             	add    $0x1,%edi
f010182d:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101831:	83 f8 25             	cmp    $0x25,%eax
f0101834:	75 e2                	jne    f0101818 <vprintfmt+0x14>
f0101836:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010183a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101841:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101848:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010184f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101854:	eb 07                	jmp    f010185d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101856:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101859:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010185d:	8d 47 01             	lea    0x1(%edi),%eax
f0101860:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101863:	0f b6 07             	movzbl (%edi),%eax
f0101866:	0f b6 d0             	movzbl %al,%edx
f0101869:	83 e8 23             	sub    $0x23,%eax
f010186c:	3c 55                	cmp    $0x55,%al
f010186e:	0f 87 d3 03 00 00    	ja     f0101c47 <vprintfmt+0x443>
f0101874:	0f b6 c0             	movzbl %al,%eax
f0101877:	ff 24 85 c0 2c 10 f0 	jmp    *-0xfefd340(,%eax,4)
f010187e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101881:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101885:	eb d6                	jmp    f010185d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101887:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010188a:	b8 00 00 00 00       	mov    $0x0,%eax
f010188f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101892:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101895:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101899:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010189c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010189f:	83 f9 09             	cmp    $0x9,%ecx
f01018a2:	77 3f                	ja     f01018e3 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01018a4:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01018a7:	eb e9                	jmp    f0101892 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01018a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01018ac:	8b 00                	mov    (%eax),%eax
f01018ae:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01018b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01018b4:	8d 40 04             	lea    0x4(%eax),%eax
f01018b7:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01018ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01018bd:	eb 2a                	jmp    f01018e9 <vprintfmt+0xe5>
f01018bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01018c2:	85 c0                	test   %eax,%eax
f01018c4:	ba 00 00 00 00       	mov    $0x0,%edx
f01018c9:	0f 49 d0             	cmovns %eax,%edx
f01018cc:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01018cf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018d2:	eb 89                	jmp    f010185d <vprintfmt+0x59>
f01018d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01018d7:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01018de:	e9 7a ff ff ff       	jmp    f010185d <vprintfmt+0x59>
f01018e3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01018e6:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01018e9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01018ed:	0f 89 6a ff ff ff    	jns    f010185d <vprintfmt+0x59>
				width = precision, precision = -1;
f01018f3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01018f6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01018f9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101900:	e9 58 ff ff ff       	jmp    f010185d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101905:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101908:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010190b:	e9 4d ff ff ff       	jmp    f010185d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101910:	8b 45 14             	mov    0x14(%ebp),%eax
f0101913:	8d 78 04             	lea    0x4(%eax),%edi
f0101916:	83 ec 08             	sub    $0x8,%esp
f0101919:	53                   	push   %ebx
f010191a:	ff 30                	pushl  (%eax)
f010191c:	ff d6                	call   *%esi
			break;
f010191e:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101921:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101924:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101927:	e9 fe fe ff ff       	jmp    f010182a <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010192c:	8b 45 14             	mov    0x14(%ebp),%eax
f010192f:	8d 78 04             	lea    0x4(%eax),%edi
f0101932:	8b 00                	mov    (%eax),%eax
f0101934:	99                   	cltd   
f0101935:	31 d0                	xor    %edx,%eax
f0101937:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101939:	83 f8 06             	cmp    $0x6,%eax
f010193c:	7f 0b                	jg     f0101949 <vprintfmt+0x145>
f010193e:	8b 14 85 18 2e 10 f0 	mov    -0xfefd1e8(,%eax,4),%edx
f0101945:	85 d2                	test   %edx,%edx
f0101947:	75 1b                	jne    f0101964 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0101949:	50                   	push   %eax
f010194a:	68 4e 2c 10 f0       	push   $0xf0102c4e
f010194f:	53                   	push   %ebx
f0101950:	56                   	push   %esi
f0101951:	e8 91 fe ff ff       	call   f01017e7 <printfmt>
f0101956:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101959:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010195c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010195f:	e9 c6 fe ff ff       	jmp    f010182a <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101964:	52                   	push   %edx
f0101965:	68 74 2a 10 f0       	push   $0xf0102a74
f010196a:	53                   	push   %ebx
f010196b:	56                   	push   %esi
f010196c:	e8 76 fe ff ff       	call   f01017e7 <printfmt>
f0101971:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101974:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101977:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010197a:	e9 ab fe ff ff       	jmp    f010182a <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010197f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101982:	83 c0 04             	add    $0x4,%eax
f0101985:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101988:	8b 45 14             	mov    0x14(%ebp),%eax
f010198b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010198d:	85 ff                	test   %edi,%edi
f010198f:	b8 47 2c 10 f0       	mov    $0xf0102c47,%eax
f0101994:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101997:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010199b:	0f 8e 94 00 00 00    	jle    f0101a35 <vprintfmt+0x231>
f01019a1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01019a5:	0f 84 98 00 00 00    	je     f0101a43 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f01019ab:	83 ec 08             	sub    $0x8,%esp
f01019ae:	ff 75 d0             	pushl  -0x30(%ebp)
f01019b1:	57                   	push   %edi
f01019b2:	e8 0c 04 00 00       	call   f0101dc3 <strnlen>
f01019b7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01019ba:	29 c1                	sub    %eax,%ecx
f01019bc:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01019bf:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01019c2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01019c6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01019c9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01019cc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01019ce:	eb 0f                	jmp    f01019df <vprintfmt+0x1db>
					putch(padc, putdat);
f01019d0:	83 ec 08             	sub    $0x8,%esp
f01019d3:	53                   	push   %ebx
f01019d4:	ff 75 e0             	pushl  -0x20(%ebp)
f01019d7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01019d9:	83 ef 01             	sub    $0x1,%edi
f01019dc:	83 c4 10             	add    $0x10,%esp
f01019df:	85 ff                	test   %edi,%edi
f01019e1:	7f ed                	jg     f01019d0 <vprintfmt+0x1cc>
f01019e3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01019e6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01019e9:	85 c9                	test   %ecx,%ecx
f01019eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01019f0:	0f 49 c1             	cmovns %ecx,%eax
f01019f3:	29 c1                	sub    %eax,%ecx
f01019f5:	89 75 08             	mov    %esi,0x8(%ebp)
f01019f8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01019fb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01019fe:	89 cb                	mov    %ecx,%ebx
f0101a00:	eb 4d                	jmp    f0101a4f <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101a02:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101a06:	74 1b                	je     f0101a23 <vprintfmt+0x21f>
f0101a08:	0f be c0             	movsbl %al,%eax
f0101a0b:	83 e8 20             	sub    $0x20,%eax
f0101a0e:	83 f8 5e             	cmp    $0x5e,%eax
f0101a11:	76 10                	jbe    f0101a23 <vprintfmt+0x21f>
					putch('?', putdat);
f0101a13:	83 ec 08             	sub    $0x8,%esp
f0101a16:	ff 75 0c             	pushl  0xc(%ebp)
f0101a19:	6a 3f                	push   $0x3f
f0101a1b:	ff 55 08             	call   *0x8(%ebp)
f0101a1e:	83 c4 10             	add    $0x10,%esp
f0101a21:	eb 0d                	jmp    f0101a30 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0101a23:	83 ec 08             	sub    $0x8,%esp
f0101a26:	ff 75 0c             	pushl  0xc(%ebp)
f0101a29:	52                   	push   %edx
f0101a2a:	ff 55 08             	call   *0x8(%ebp)
f0101a2d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101a30:	83 eb 01             	sub    $0x1,%ebx
f0101a33:	eb 1a                	jmp    f0101a4f <vprintfmt+0x24b>
f0101a35:	89 75 08             	mov    %esi,0x8(%ebp)
f0101a38:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101a3b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101a3e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101a41:	eb 0c                	jmp    f0101a4f <vprintfmt+0x24b>
f0101a43:	89 75 08             	mov    %esi,0x8(%ebp)
f0101a46:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101a49:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101a4c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101a4f:	83 c7 01             	add    $0x1,%edi
f0101a52:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101a56:	0f be d0             	movsbl %al,%edx
f0101a59:	85 d2                	test   %edx,%edx
f0101a5b:	74 23                	je     f0101a80 <vprintfmt+0x27c>
f0101a5d:	85 f6                	test   %esi,%esi
f0101a5f:	78 a1                	js     f0101a02 <vprintfmt+0x1fe>
f0101a61:	83 ee 01             	sub    $0x1,%esi
f0101a64:	79 9c                	jns    f0101a02 <vprintfmt+0x1fe>
f0101a66:	89 df                	mov    %ebx,%edi
f0101a68:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a6b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a6e:	eb 18                	jmp    f0101a88 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101a70:	83 ec 08             	sub    $0x8,%esp
f0101a73:	53                   	push   %ebx
f0101a74:	6a 20                	push   $0x20
f0101a76:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101a78:	83 ef 01             	sub    $0x1,%edi
f0101a7b:	83 c4 10             	add    $0x10,%esp
f0101a7e:	eb 08                	jmp    f0101a88 <vprintfmt+0x284>
f0101a80:	89 df                	mov    %ebx,%edi
f0101a82:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a85:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a88:	85 ff                	test   %edi,%edi
f0101a8a:	7f e4                	jg     f0101a70 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101a8c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a8f:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a95:	e9 90 fd ff ff       	jmp    f010182a <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101a9a:	83 f9 01             	cmp    $0x1,%ecx
f0101a9d:	7e 19                	jle    f0101ab8 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0101a9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101aa2:	8b 50 04             	mov    0x4(%eax),%edx
f0101aa5:	8b 00                	mov    (%eax),%eax
f0101aa7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101aaa:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101aad:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ab0:	8d 40 08             	lea    0x8(%eax),%eax
f0101ab3:	89 45 14             	mov    %eax,0x14(%ebp)
f0101ab6:	eb 38                	jmp    f0101af0 <vprintfmt+0x2ec>
	else if (lflag)
f0101ab8:	85 c9                	test   %ecx,%ecx
f0101aba:	74 1b                	je     f0101ad7 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0101abc:	8b 45 14             	mov    0x14(%ebp),%eax
f0101abf:	8b 00                	mov    (%eax),%eax
f0101ac1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101ac4:	89 c1                	mov    %eax,%ecx
f0101ac6:	c1 f9 1f             	sar    $0x1f,%ecx
f0101ac9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101acc:	8b 45 14             	mov    0x14(%ebp),%eax
f0101acf:	8d 40 04             	lea    0x4(%eax),%eax
f0101ad2:	89 45 14             	mov    %eax,0x14(%ebp)
f0101ad5:	eb 19                	jmp    f0101af0 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0101ad7:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ada:	8b 00                	mov    (%eax),%eax
f0101adc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101adf:	89 c1                	mov    %eax,%ecx
f0101ae1:	c1 f9 1f             	sar    $0x1f,%ecx
f0101ae4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101ae7:	8b 45 14             	mov    0x14(%ebp),%eax
f0101aea:	8d 40 04             	lea    0x4(%eax),%eax
f0101aed:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101af0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101af3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101af6:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101afb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101aff:	0f 89 0e 01 00 00    	jns    f0101c13 <vprintfmt+0x40f>
				putch('-', putdat);
f0101b05:	83 ec 08             	sub    $0x8,%esp
f0101b08:	53                   	push   %ebx
f0101b09:	6a 2d                	push   $0x2d
f0101b0b:	ff d6                	call   *%esi
				num = -(long long) num;
f0101b0d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101b10:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101b13:	f7 da                	neg    %edx
f0101b15:	83 d1 00             	adc    $0x0,%ecx
f0101b18:	f7 d9                	neg    %ecx
f0101b1a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101b1d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b22:	e9 ec 00 00 00       	jmp    f0101c13 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101b27:	83 f9 01             	cmp    $0x1,%ecx
f0101b2a:	7e 18                	jle    f0101b44 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0101b2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b2f:	8b 10                	mov    (%eax),%edx
f0101b31:	8b 48 04             	mov    0x4(%eax),%ecx
f0101b34:	8d 40 08             	lea    0x8(%eax),%eax
f0101b37:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101b3a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b3f:	e9 cf 00 00 00       	jmp    f0101c13 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101b44:	85 c9                	test   %ecx,%ecx
f0101b46:	74 1a                	je     f0101b62 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0101b48:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b4b:	8b 10                	mov    (%eax),%edx
f0101b4d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101b52:	8d 40 04             	lea    0x4(%eax),%eax
f0101b55:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101b58:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b5d:	e9 b1 00 00 00       	jmp    f0101c13 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101b62:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b65:	8b 10                	mov    (%eax),%edx
f0101b67:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101b6c:	8d 40 04             	lea    0x4(%eax),%eax
f0101b6f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101b72:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101b77:	e9 97 00 00 00       	jmp    f0101c13 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101b7c:	83 ec 08             	sub    $0x8,%esp
f0101b7f:	53                   	push   %ebx
f0101b80:	6a 58                	push   $0x58
f0101b82:	ff d6                	call   *%esi
			putch('X', putdat);
f0101b84:	83 c4 08             	add    $0x8,%esp
f0101b87:	53                   	push   %ebx
f0101b88:	6a 58                	push   $0x58
f0101b8a:	ff d6                	call   *%esi
			putch('X', putdat);
f0101b8c:	83 c4 08             	add    $0x8,%esp
f0101b8f:	53                   	push   %ebx
f0101b90:	6a 58                	push   $0x58
f0101b92:	ff d6                	call   *%esi
			break;
f0101b94:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101b97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101b9a:	e9 8b fc ff ff       	jmp    f010182a <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101b9f:	83 ec 08             	sub    $0x8,%esp
f0101ba2:	53                   	push   %ebx
f0101ba3:	6a 30                	push   $0x30
f0101ba5:	ff d6                	call   *%esi
			putch('x', putdat);
f0101ba7:	83 c4 08             	add    $0x8,%esp
f0101baa:	53                   	push   %ebx
f0101bab:	6a 78                	push   $0x78
f0101bad:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101baf:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bb2:	8b 10                	mov    (%eax),%edx
f0101bb4:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101bb9:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101bbc:	8d 40 04             	lea    0x4(%eax),%eax
f0101bbf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101bc2:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101bc7:	eb 4a                	jmp    f0101c13 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101bc9:	83 f9 01             	cmp    $0x1,%ecx
f0101bcc:	7e 15                	jle    f0101be3 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0101bce:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bd1:	8b 10                	mov    (%eax),%edx
f0101bd3:	8b 48 04             	mov    0x4(%eax),%ecx
f0101bd6:	8d 40 08             	lea    0x8(%eax),%eax
f0101bd9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101bdc:	b8 10 00 00 00       	mov    $0x10,%eax
f0101be1:	eb 30                	jmp    f0101c13 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101be3:	85 c9                	test   %ecx,%ecx
f0101be5:	74 17                	je     f0101bfe <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0101be7:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bea:	8b 10                	mov    (%eax),%edx
f0101bec:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101bf1:	8d 40 04             	lea    0x4(%eax),%eax
f0101bf4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101bf7:	b8 10 00 00 00       	mov    $0x10,%eax
f0101bfc:	eb 15                	jmp    f0101c13 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101bfe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c01:	8b 10                	mov    (%eax),%edx
f0101c03:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101c08:	8d 40 04             	lea    0x4(%eax),%eax
f0101c0b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101c0e:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101c13:	83 ec 0c             	sub    $0xc,%esp
f0101c16:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101c1a:	57                   	push   %edi
f0101c1b:	ff 75 e0             	pushl  -0x20(%ebp)
f0101c1e:	50                   	push   %eax
f0101c1f:	51                   	push   %ecx
f0101c20:	52                   	push   %edx
f0101c21:	89 da                	mov    %ebx,%edx
f0101c23:	89 f0                	mov    %esi,%eax
f0101c25:	e8 f1 fa ff ff       	call   f010171b <printnum>
			break;
f0101c2a:	83 c4 20             	add    $0x20,%esp
f0101c2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c30:	e9 f5 fb ff ff       	jmp    f010182a <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101c35:	83 ec 08             	sub    $0x8,%esp
f0101c38:	53                   	push   %ebx
f0101c39:	52                   	push   %edx
f0101c3a:	ff d6                	call   *%esi
			break;
f0101c3c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101c42:	e9 e3 fb ff ff       	jmp    f010182a <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101c47:	83 ec 08             	sub    $0x8,%esp
f0101c4a:	53                   	push   %ebx
f0101c4b:	6a 25                	push   $0x25
f0101c4d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101c4f:	83 c4 10             	add    $0x10,%esp
f0101c52:	eb 03                	jmp    f0101c57 <vprintfmt+0x453>
f0101c54:	83 ef 01             	sub    $0x1,%edi
f0101c57:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101c5b:	75 f7                	jne    f0101c54 <vprintfmt+0x450>
f0101c5d:	e9 c8 fb ff ff       	jmp    f010182a <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101c62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101c65:	5b                   	pop    %ebx
f0101c66:	5e                   	pop    %esi
f0101c67:	5f                   	pop    %edi
f0101c68:	5d                   	pop    %ebp
f0101c69:	c3                   	ret    

f0101c6a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101c6a:	55                   	push   %ebp
f0101c6b:	89 e5                	mov    %esp,%ebp
f0101c6d:	83 ec 18             	sub    $0x18,%esp
f0101c70:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c73:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101c76:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101c79:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101c7d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101c80:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101c87:	85 c0                	test   %eax,%eax
f0101c89:	74 26                	je     f0101cb1 <vsnprintf+0x47>
f0101c8b:	85 d2                	test   %edx,%edx
f0101c8d:	7e 22                	jle    f0101cb1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101c8f:	ff 75 14             	pushl  0x14(%ebp)
f0101c92:	ff 75 10             	pushl  0x10(%ebp)
f0101c95:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101c98:	50                   	push   %eax
f0101c99:	68 ca 17 10 f0       	push   $0xf01017ca
f0101c9e:	e8 61 fb ff ff       	call   f0101804 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101ca3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ca6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101ca9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101cac:	83 c4 10             	add    $0x10,%esp
f0101caf:	eb 05                	jmp    f0101cb6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101cb1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101cb6:	c9                   	leave  
f0101cb7:	c3                   	ret    

f0101cb8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101cb8:	55                   	push   %ebp
f0101cb9:	89 e5                	mov    %esp,%ebp
f0101cbb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101cbe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101cc1:	50                   	push   %eax
f0101cc2:	ff 75 10             	pushl  0x10(%ebp)
f0101cc5:	ff 75 0c             	pushl  0xc(%ebp)
f0101cc8:	ff 75 08             	pushl  0x8(%ebp)
f0101ccb:	e8 9a ff ff ff       	call   f0101c6a <vsnprintf>
	va_end(ap);

	return rc;
}
f0101cd0:	c9                   	leave  
f0101cd1:	c3                   	ret    

f0101cd2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101cd2:	55                   	push   %ebp
f0101cd3:	89 e5                	mov    %esp,%ebp
f0101cd5:	57                   	push   %edi
f0101cd6:	56                   	push   %esi
f0101cd7:	53                   	push   %ebx
f0101cd8:	83 ec 0c             	sub    $0xc,%esp
f0101cdb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101cde:	85 c0                	test   %eax,%eax
f0101ce0:	74 11                	je     f0101cf3 <readline+0x21>
		cprintf("%s", prompt);
f0101ce2:	83 ec 08             	sub    $0x8,%esp
f0101ce5:	50                   	push   %eax
f0101ce6:	68 74 2a 10 f0       	push   $0xf0102a74
f0101ceb:	e8 50 f7 ff ff       	call   f0101440 <cprintf>
f0101cf0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101cf3:	83 ec 0c             	sub    $0xc,%esp
f0101cf6:	6a 00                	push   $0x0
f0101cf8:	e8 24 e9 ff ff       	call   f0100621 <iscons>
f0101cfd:	89 c7                	mov    %eax,%edi
f0101cff:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101d02:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101d07:	e8 04 e9 ff ff       	call   f0100610 <getchar>
f0101d0c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101d0e:	85 c0                	test   %eax,%eax
f0101d10:	79 18                	jns    f0101d2a <readline+0x58>
			cprintf("read error: %e\n", c);
f0101d12:	83 ec 08             	sub    $0x8,%esp
f0101d15:	50                   	push   %eax
f0101d16:	68 34 2e 10 f0       	push   $0xf0102e34
f0101d1b:	e8 20 f7 ff ff       	call   f0101440 <cprintf>
			return NULL;
f0101d20:	83 c4 10             	add    $0x10,%esp
f0101d23:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d28:	eb 79                	jmp    f0101da3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101d2a:	83 f8 08             	cmp    $0x8,%eax
f0101d2d:	0f 94 c2             	sete   %dl
f0101d30:	83 f8 7f             	cmp    $0x7f,%eax
f0101d33:	0f 94 c0             	sete   %al
f0101d36:	08 c2                	or     %al,%dl
f0101d38:	74 1a                	je     f0101d54 <readline+0x82>
f0101d3a:	85 f6                	test   %esi,%esi
f0101d3c:	7e 16                	jle    f0101d54 <readline+0x82>
			if (echoing)
f0101d3e:	85 ff                	test   %edi,%edi
f0101d40:	74 0d                	je     f0101d4f <readline+0x7d>
				cputchar('\b');
f0101d42:	83 ec 0c             	sub    $0xc,%esp
f0101d45:	6a 08                	push   $0x8
f0101d47:	e8 b4 e8 ff ff       	call   f0100600 <cputchar>
f0101d4c:	83 c4 10             	add    $0x10,%esp
			i--;
f0101d4f:	83 ee 01             	sub    $0x1,%esi
f0101d52:	eb b3                	jmp    f0101d07 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101d54:	83 fb 1f             	cmp    $0x1f,%ebx
f0101d57:	7e 23                	jle    f0101d7c <readline+0xaa>
f0101d59:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101d5f:	7f 1b                	jg     f0101d7c <readline+0xaa>
			if (echoing)
f0101d61:	85 ff                	test   %edi,%edi
f0101d63:	74 0c                	je     f0101d71 <readline+0x9f>
				cputchar(c);
f0101d65:	83 ec 0c             	sub    $0xc,%esp
f0101d68:	53                   	push   %ebx
f0101d69:	e8 92 e8 ff ff       	call   f0100600 <cputchar>
f0101d6e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101d71:	88 9e 40 45 11 f0    	mov    %bl,-0xfeebac0(%esi)
f0101d77:	8d 76 01             	lea    0x1(%esi),%esi
f0101d7a:	eb 8b                	jmp    f0101d07 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101d7c:	83 fb 0a             	cmp    $0xa,%ebx
f0101d7f:	74 05                	je     f0101d86 <readline+0xb4>
f0101d81:	83 fb 0d             	cmp    $0xd,%ebx
f0101d84:	75 81                	jne    f0101d07 <readline+0x35>
			if (echoing)
f0101d86:	85 ff                	test   %edi,%edi
f0101d88:	74 0d                	je     f0101d97 <readline+0xc5>
				cputchar('\n');
f0101d8a:	83 ec 0c             	sub    $0xc,%esp
f0101d8d:	6a 0a                	push   $0xa
f0101d8f:	e8 6c e8 ff ff       	call   f0100600 <cputchar>
f0101d94:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101d97:	c6 86 40 45 11 f0 00 	movb   $0x0,-0xfeebac0(%esi)
			return buf;
f0101d9e:	b8 40 45 11 f0       	mov    $0xf0114540,%eax
		}
	}
}
f0101da3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101da6:	5b                   	pop    %ebx
f0101da7:	5e                   	pop    %esi
f0101da8:	5f                   	pop    %edi
f0101da9:	5d                   	pop    %ebp
f0101daa:	c3                   	ret    

f0101dab <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101dab:	55                   	push   %ebp
f0101dac:	89 e5                	mov    %esp,%ebp
f0101dae:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101db1:	b8 00 00 00 00       	mov    $0x0,%eax
f0101db6:	eb 03                	jmp    f0101dbb <strlen+0x10>
		n++;
f0101db8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101dbb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101dbf:	75 f7                	jne    f0101db8 <strlen+0xd>
		n++;
	return n;
}
f0101dc1:	5d                   	pop    %ebp
f0101dc2:	c3                   	ret    

f0101dc3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101dc3:	55                   	push   %ebp
f0101dc4:	89 e5                	mov    %esp,%ebp
f0101dc6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101dc9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101dcc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dd1:	eb 03                	jmp    f0101dd6 <strnlen+0x13>
		n++;
f0101dd3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101dd6:	39 c2                	cmp    %eax,%edx
f0101dd8:	74 08                	je     f0101de2 <strnlen+0x1f>
f0101dda:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101dde:	75 f3                	jne    f0101dd3 <strnlen+0x10>
f0101de0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101de2:	5d                   	pop    %ebp
f0101de3:	c3                   	ret    

f0101de4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101de4:	55                   	push   %ebp
f0101de5:	89 e5                	mov    %esp,%ebp
f0101de7:	53                   	push   %ebx
f0101de8:	8b 45 08             	mov    0x8(%ebp),%eax
f0101deb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101dee:	89 c2                	mov    %eax,%edx
f0101df0:	83 c2 01             	add    $0x1,%edx
f0101df3:	83 c1 01             	add    $0x1,%ecx
f0101df6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101dfa:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101dfd:	84 db                	test   %bl,%bl
f0101dff:	75 ef                	jne    f0101df0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101e01:	5b                   	pop    %ebx
f0101e02:	5d                   	pop    %ebp
f0101e03:	c3                   	ret    

f0101e04 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101e04:	55                   	push   %ebp
f0101e05:	89 e5                	mov    %esp,%ebp
f0101e07:	53                   	push   %ebx
f0101e08:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101e0b:	53                   	push   %ebx
f0101e0c:	e8 9a ff ff ff       	call   f0101dab <strlen>
f0101e11:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101e14:	ff 75 0c             	pushl  0xc(%ebp)
f0101e17:	01 d8                	add    %ebx,%eax
f0101e19:	50                   	push   %eax
f0101e1a:	e8 c5 ff ff ff       	call   f0101de4 <strcpy>
	return dst;
}
f0101e1f:	89 d8                	mov    %ebx,%eax
f0101e21:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101e24:	c9                   	leave  
f0101e25:	c3                   	ret    

f0101e26 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101e26:	55                   	push   %ebp
f0101e27:	89 e5                	mov    %esp,%ebp
f0101e29:	56                   	push   %esi
f0101e2a:	53                   	push   %ebx
f0101e2b:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e2e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101e31:	89 f3                	mov    %esi,%ebx
f0101e33:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101e36:	89 f2                	mov    %esi,%edx
f0101e38:	eb 0f                	jmp    f0101e49 <strncpy+0x23>
		*dst++ = *src;
f0101e3a:	83 c2 01             	add    $0x1,%edx
f0101e3d:	0f b6 01             	movzbl (%ecx),%eax
f0101e40:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101e43:	80 39 01             	cmpb   $0x1,(%ecx)
f0101e46:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101e49:	39 da                	cmp    %ebx,%edx
f0101e4b:	75 ed                	jne    f0101e3a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101e4d:	89 f0                	mov    %esi,%eax
f0101e4f:	5b                   	pop    %ebx
f0101e50:	5e                   	pop    %esi
f0101e51:	5d                   	pop    %ebp
f0101e52:	c3                   	ret    

f0101e53 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101e53:	55                   	push   %ebp
f0101e54:	89 e5                	mov    %esp,%ebp
f0101e56:	56                   	push   %esi
f0101e57:	53                   	push   %ebx
f0101e58:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e5b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101e5e:	8b 55 10             	mov    0x10(%ebp),%edx
f0101e61:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101e63:	85 d2                	test   %edx,%edx
f0101e65:	74 21                	je     f0101e88 <strlcpy+0x35>
f0101e67:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101e6b:	89 f2                	mov    %esi,%edx
f0101e6d:	eb 09                	jmp    f0101e78 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101e6f:	83 c2 01             	add    $0x1,%edx
f0101e72:	83 c1 01             	add    $0x1,%ecx
f0101e75:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101e78:	39 c2                	cmp    %eax,%edx
f0101e7a:	74 09                	je     f0101e85 <strlcpy+0x32>
f0101e7c:	0f b6 19             	movzbl (%ecx),%ebx
f0101e7f:	84 db                	test   %bl,%bl
f0101e81:	75 ec                	jne    f0101e6f <strlcpy+0x1c>
f0101e83:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101e85:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101e88:	29 f0                	sub    %esi,%eax
}
f0101e8a:	5b                   	pop    %ebx
f0101e8b:	5e                   	pop    %esi
f0101e8c:	5d                   	pop    %ebp
f0101e8d:	c3                   	ret    

f0101e8e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101e8e:	55                   	push   %ebp
f0101e8f:	89 e5                	mov    %esp,%ebp
f0101e91:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e94:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101e97:	eb 06                	jmp    f0101e9f <strcmp+0x11>
		p++, q++;
f0101e99:	83 c1 01             	add    $0x1,%ecx
f0101e9c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101e9f:	0f b6 01             	movzbl (%ecx),%eax
f0101ea2:	84 c0                	test   %al,%al
f0101ea4:	74 04                	je     f0101eaa <strcmp+0x1c>
f0101ea6:	3a 02                	cmp    (%edx),%al
f0101ea8:	74 ef                	je     f0101e99 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101eaa:	0f b6 c0             	movzbl %al,%eax
f0101ead:	0f b6 12             	movzbl (%edx),%edx
f0101eb0:	29 d0                	sub    %edx,%eax
}
f0101eb2:	5d                   	pop    %ebp
f0101eb3:	c3                   	ret    

f0101eb4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101eb4:	55                   	push   %ebp
f0101eb5:	89 e5                	mov    %esp,%ebp
f0101eb7:	53                   	push   %ebx
f0101eb8:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ebb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101ebe:	89 c3                	mov    %eax,%ebx
f0101ec0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101ec3:	eb 06                	jmp    f0101ecb <strncmp+0x17>
		n--, p++, q++;
f0101ec5:	83 c0 01             	add    $0x1,%eax
f0101ec8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101ecb:	39 d8                	cmp    %ebx,%eax
f0101ecd:	74 15                	je     f0101ee4 <strncmp+0x30>
f0101ecf:	0f b6 08             	movzbl (%eax),%ecx
f0101ed2:	84 c9                	test   %cl,%cl
f0101ed4:	74 04                	je     f0101eda <strncmp+0x26>
f0101ed6:	3a 0a                	cmp    (%edx),%cl
f0101ed8:	74 eb                	je     f0101ec5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101eda:	0f b6 00             	movzbl (%eax),%eax
f0101edd:	0f b6 12             	movzbl (%edx),%edx
f0101ee0:	29 d0                	sub    %edx,%eax
f0101ee2:	eb 05                	jmp    f0101ee9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101ee4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101ee9:	5b                   	pop    %ebx
f0101eea:	5d                   	pop    %ebp
f0101eeb:	c3                   	ret    

f0101eec <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101eec:	55                   	push   %ebp
f0101eed:	89 e5                	mov    %esp,%ebp
f0101eef:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ef2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101ef6:	eb 07                	jmp    f0101eff <strchr+0x13>
		if (*s == c)
f0101ef8:	38 ca                	cmp    %cl,%dl
f0101efa:	74 0f                	je     f0101f0b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101efc:	83 c0 01             	add    $0x1,%eax
f0101eff:	0f b6 10             	movzbl (%eax),%edx
f0101f02:	84 d2                	test   %dl,%dl
f0101f04:	75 f2                	jne    f0101ef8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101f06:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101f0b:	5d                   	pop    %ebp
f0101f0c:	c3                   	ret    

f0101f0d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101f0d:	55                   	push   %ebp
f0101f0e:	89 e5                	mov    %esp,%ebp
f0101f10:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f13:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101f17:	eb 03                	jmp    f0101f1c <strfind+0xf>
f0101f19:	83 c0 01             	add    $0x1,%eax
f0101f1c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101f1f:	38 ca                	cmp    %cl,%dl
f0101f21:	74 04                	je     f0101f27 <strfind+0x1a>
f0101f23:	84 d2                	test   %dl,%dl
f0101f25:	75 f2                	jne    f0101f19 <strfind+0xc>
			break;
	return (char *) s;
}
f0101f27:	5d                   	pop    %ebp
f0101f28:	c3                   	ret    

f0101f29 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101f29:	55                   	push   %ebp
f0101f2a:	89 e5                	mov    %esp,%ebp
f0101f2c:	57                   	push   %edi
f0101f2d:	56                   	push   %esi
f0101f2e:	53                   	push   %ebx
f0101f2f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101f32:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101f35:	85 c9                	test   %ecx,%ecx
f0101f37:	74 36                	je     f0101f6f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101f39:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101f3f:	75 28                	jne    f0101f69 <memset+0x40>
f0101f41:	f6 c1 03             	test   $0x3,%cl
f0101f44:	75 23                	jne    f0101f69 <memset+0x40>
		c &= 0xFF;
f0101f46:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101f4a:	89 d3                	mov    %edx,%ebx
f0101f4c:	c1 e3 08             	shl    $0x8,%ebx
f0101f4f:	89 d6                	mov    %edx,%esi
f0101f51:	c1 e6 18             	shl    $0x18,%esi
f0101f54:	89 d0                	mov    %edx,%eax
f0101f56:	c1 e0 10             	shl    $0x10,%eax
f0101f59:	09 f0                	or     %esi,%eax
f0101f5b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101f5d:	89 d8                	mov    %ebx,%eax
f0101f5f:	09 d0                	or     %edx,%eax
f0101f61:	c1 e9 02             	shr    $0x2,%ecx
f0101f64:	fc                   	cld    
f0101f65:	f3 ab                	rep stos %eax,%es:(%edi)
f0101f67:	eb 06                	jmp    f0101f6f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101f69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f6c:	fc                   	cld    
f0101f6d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101f6f:	89 f8                	mov    %edi,%eax
f0101f71:	5b                   	pop    %ebx
f0101f72:	5e                   	pop    %esi
f0101f73:	5f                   	pop    %edi
f0101f74:	5d                   	pop    %ebp
f0101f75:	c3                   	ret    

f0101f76 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101f76:	55                   	push   %ebp
f0101f77:	89 e5                	mov    %esp,%ebp
f0101f79:	57                   	push   %edi
f0101f7a:	56                   	push   %esi
f0101f7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f7e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101f81:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101f84:	39 c6                	cmp    %eax,%esi
f0101f86:	73 35                	jae    f0101fbd <memmove+0x47>
f0101f88:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101f8b:	39 d0                	cmp    %edx,%eax
f0101f8d:	73 2e                	jae    f0101fbd <memmove+0x47>
		s += n;
		d += n;
f0101f8f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101f92:	89 d6                	mov    %edx,%esi
f0101f94:	09 fe                	or     %edi,%esi
f0101f96:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101f9c:	75 13                	jne    f0101fb1 <memmove+0x3b>
f0101f9e:	f6 c1 03             	test   $0x3,%cl
f0101fa1:	75 0e                	jne    f0101fb1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101fa3:	83 ef 04             	sub    $0x4,%edi
f0101fa6:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101fa9:	c1 e9 02             	shr    $0x2,%ecx
f0101fac:	fd                   	std    
f0101fad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101faf:	eb 09                	jmp    f0101fba <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101fb1:	83 ef 01             	sub    $0x1,%edi
f0101fb4:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101fb7:	fd                   	std    
f0101fb8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101fba:	fc                   	cld    
f0101fbb:	eb 1d                	jmp    f0101fda <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101fbd:	89 f2                	mov    %esi,%edx
f0101fbf:	09 c2                	or     %eax,%edx
f0101fc1:	f6 c2 03             	test   $0x3,%dl
f0101fc4:	75 0f                	jne    f0101fd5 <memmove+0x5f>
f0101fc6:	f6 c1 03             	test   $0x3,%cl
f0101fc9:	75 0a                	jne    f0101fd5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101fcb:	c1 e9 02             	shr    $0x2,%ecx
f0101fce:	89 c7                	mov    %eax,%edi
f0101fd0:	fc                   	cld    
f0101fd1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101fd3:	eb 05                	jmp    f0101fda <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101fd5:	89 c7                	mov    %eax,%edi
f0101fd7:	fc                   	cld    
f0101fd8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101fda:	5e                   	pop    %esi
f0101fdb:	5f                   	pop    %edi
f0101fdc:	5d                   	pop    %ebp
f0101fdd:	c3                   	ret    

f0101fde <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101fde:	55                   	push   %ebp
f0101fdf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101fe1:	ff 75 10             	pushl  0x10(%ebp)
f0101fe4:	ff 75 0c             	pushl  0xc(%ebp)
f0101fe7:	ff 75 08             	pushl  0x8(%ebp)
f0101fea:	e8 87 ff ff ff       	call   f0101f76 <memmove>
}
f0101fef:	c9                   	leave  
f0101ff0:	c3                   	ret    

f0101ff1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101ff1:	55                   	push   %ebp
f0101ff2:	89 e5                	mov    %esp,%ebp
f0101ff4:	56                   	push   %esi
f0101ff5:	53                   	push   %ebx
f0101ff6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ff9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101ffc:	89 c6                	mov    %eax,%esi
f0101ffe:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102001:	eb 1a                	jmp    f010201d <memcmp+0x2c>
		if (*s1 != *s2)
f0102003:	0f b6 08             	movzbl (%eax),%ecx
f0102006:	0f b6 1a             	movzbl (%edx),%ebx
f0102009:	38 d9                	cmp    %bl,%cl
f010200b:	74 0a                	je     f0102017 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010200d:	0f b6 c1             	movzbl %cl,%eax
f0102010:	0f b6 db             	movzbl %bl,%ebx
f0102013:	29 d8                	sub    %ebx,%eax
f0102015:	eb 0f                	jmp    f0102026 <memcmp+0x35>
		s1++, s2++;
f0102017:	83 c0 01             	add    $0x1,%eax
f010201a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010201d:	39 f0                	cmp    %esi,%eax
f010201f:	75 e2                	jne    f0102003 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102021:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102026:	5b                   	pop    %ebx
f0102027:	5e                   	pop    %esi
f0102028:	5d                   	pop    %ebp
f0102029:	c3                   	ret    

f010202a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010202a:	55                   	push   %ebp
f010202b:	89 e5                	mov    %esp,%ebp
f010202d:	53                   	push   %ebx
f010202e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102031:	89 c1                	mov    %eax,%ecx
f0102033:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0102036:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010203a:	eb 0a                	jmp    f0102046 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010203c:	0f b6 10             	movzbl (%eax),%edx
f010203f:	39 da                	cmp    %ebx,%edx
f0102041:	74 07                	je     f010204a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102043:	83 c0 01             	add    $0x1,%eax
f0102046:	39 c8                	cmp    %ecx,%eax
f0102048:	72 f2                	jb     f010203c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010204a:	5b                   	pop    %ebx
f010204b:	5d                   	pop    %ebp
f010204c:	c3                   	ret    

f010204d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010204d:	55                   	push   %ebp
f010204e:	89 e5                	mov    %esp,%ebp
f0102050:	57                   	push   %edi
f0102051:	56                   	push   %esi
f0102052:	53                   	push   %ebx
f0102053:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102056:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102059:	eb 03                	jmp    f010205e <strtol+0x11>
		s++;
f010205b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010205e:	0f b6 01             	movzbl (%ecx),%eax
f0102061:	3c 20                	cmp    $0x20,%al
f0102063:	74 f6                	je     f010205b <strtol+0xe>
f0102065:	3c 09                	cmp    $0x9,%al
f0102067:	74 f2                	je     f010205b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102069:	3c 2b                	cmp    $0x2b,%al
f010206b:	75 0a                	jne    f0102077 <strtol+0x2a>
		s++;
f010206d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102070:	bf 00 00 00 00       	mov    $0x0,%edi
f0102075:	eb 11                	jmp    f0102088 <strtol+0x3b>
f0102077:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010207c:	3c 2d                	cmp    $0x2d,%al
f010207e:	75 08                	jne    f0102088 <strtol+0x3b>
		s++, neg = 1;
f0102080:	83 c1 01             	add    $0x1,%ecx
f0102083:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102088:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010208e:	75 15                	jne    f01020a5 <strtol+0x58>
f0102090:	80 39 30             	cmpb   $0x30,(%ecx)
f0102093:	75 10                	jne    f01020a5 <strtol+0x58>
f0102095:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102099:	75 7c                	jne    f0102117 <strtol+0xca>
		s += 2, base = 16;
f010209b:	83 c1 02             	add    $0x2,%ecx
f010209e:	bb 10 00 00 00       	mov    $0x10,%ebx
f01020a3:	eb 16                	jmp    f01020bb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01020a5:	85 db                	test   %ebx,%ebx
f01020a7:	75 12                	jne    f01020bb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01020a9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01020ae:	80 39 30             	cmpb   $0x30,(%ecx)
f01020b1:	75 08                	jne    f01020bb <strtol+0x6e>
		s++, base = 8;
f01020b3:	83 c1 01             	add    $0x1,%ecx
f01020b6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01020bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01020c0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01020c3:	0f b6 11             	movzbl (%ecx),%edx
f01020c6:	8d 72 d0             	lea    -0x30(%edx),%esi
f01020c9:	89 f3                	mov    %esi,%ebx
f01020cb:	80 fb 09             	cmp    $0x9,%bl
f01020ce:	77 08                	ja     f01020d8 <strtol+0x8b>
			dig = *s - '0';
f01020d0:	0f be d2             	movsbl %dl,%edx
f01020d3:	83 ea 30             	sub    $0x30,%edx
f01020d6:	eb 22                	jmp    f01020fa <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01020d8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01020db:	89 f3                	mov    %esi,%ebx
f01020dd:	80 fb 19             	cmp    $0x19,%bl
f01020e0:	77 08                	ja     f01020ea <strtol+0x9d>
			dig = *s - 'a' + 10;
f01020e2:	0f be d2             	movsbl %dl,%edx
f01020e5:	83 ea 57             	sub    $0x57,%edx
f01020e8:	eb 10                	jmp    f01020fa <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01020ea:	8d 72 bf             	lea    -0x41(%edx),%esi
f01020ed:	89 f3                	mov    %esi,%ebx
f01020ef:	80 fb 19             	cmp    $0x19,%bl
f01020f2:	77 16                	ja     f010210a <strtol+0xbd>
			dig = *s - 'A' + 10;
f01020f4:	0f be d2             	movsbl %dl,%edx
f01020f7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01020fa:	3b 55 10             	cmp    0x10(%ebp),%edx
f01020fd:	7d 0b                	jge    f010210a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01020ff:	83 c1 01             	add    $0x1,%ecx
f0102102:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102106:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0102108:	eb b9                	jmp    f01020c3 <strtol+0x76>

	if (endptr)
f010210a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010210e:	74 0d                	je     f010211d <strtol+0xd0>
		*endptr = (char *) s;
f0102110:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102113:	89 0e                	mov    %ecx,(%esi)
f0102115:	eb 06                	jmp    f010211d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102117:	85 db                	test   %ebx,%ebx
f0102119:	74 98                	je     f01020b3 <strtol+0x66>
f010211b:	eb 9e                	jmp    f01020bb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010211d:	89 c2                	mov    %eax,%edx
f010211f:	f7 da                	neg    %edx
f0102121:	85 ff                	test   %edi,%edi
f0102123:	0f 45 c2             	cmovne %edx,%eax
}
f0102126:	5b                   	pop    %ebx
f0102127:	5e                   	pop    %esi
f0102128:	5f                   	pop    %edi
f0102129:	5d                   	pop    %ebp
f010212a:	c3                   	ret    
f010212b:	66 90                	xchg   %ax,%ax
f010212d:	66 90                	xchg   %ax,%ax
f010212f:	90                   	nop

f0102130 <__udivdi3>:
f0102130:	55                   	push   %ebp
f0102131:	57                   	push   %edi
f0102132:	56                   	push   %esi
f0102133:	53                   	push   %ebx
f0102134:	83 ec 1c             	sub    $0x1c,%esp
f0102137:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010213b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010213f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102143:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102147:	85 f6                	test   %esi,%esi
f0102149:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010214d:	89 ca                	mov    %ecx,%edx
f010214f:	89 f8                	mov    %edi,%eax
f0102151:	75 3d                	jne    f0102190 <__udivdi3+0x60>
f0102153:	39 cf                	cmp    %ecx,%edi
f0102155:	0f 87 c5 00 00 00    	ja     f0102220 <__udivdi3+0xf0>
f010215b:	85 ff                	test   %edi,%edi
f010215d:	89 fd                	mov    %edi,%ebp
f010215f:	75 0b                	jne    f010216c <__udivdi3+0x3c>
f0102161:	b8 01 00 00 00       	mov    $0x1,%eax
f0102166:	31 d2                	xor    %edx,%edx
f0102168:	f7 f7                	div    %edi
f010216a:	89 c5                	mov    %eax,%ebp
f010216c:	89 c8                	mov    %ecx,%eax
f010216e:	31 d2                	xor    %edx,%edx
f0102170:	f7 f5                	div    %ebp
f0102172:	89 c1                	mov    %eax,%ecx
f0102174:	89 d8                	mov    %ebx,%eax
f0102176:	89 cf                	mov    %ecx,%edi
f0102178:	f7 f5                	div    %ebp
f010217a:	89 c3                	mov    %eax,%ebx
f010217c:	89 d8                	mov    %ebx,%eax
f010217e:	89 fa                	mov    %edi,%edx
f0102180:	83 c4 1c             	add    $0x1c,%esp
f0102183:	5b                   	pop    %ebx
f0102184:	5e                   	pop    %esi
f0102185:	5f                   	pop    %edi
f0102186:	5d                   	pop    %ebp
f0102187:	c3                   	ret    
f0102188:	90                   	nop
f0102189:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102190:	39 ce                	cmp    %ecx,%esi
f0102192:	77 74                	ja     f0102208 <__udivdi3+0xd8>
f0102194:	0f bd fe             	bsr    %esi,%edi
f0102197:	83 f7 1f             	xor    $0x1f,%edi
f010219a:	0f 84 98 00 00 00    	je     f0102238 <__udivdi3+0x108>
f01021a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01021a5:	89 f9                	mov    %edi,%ecx
f01021a7:	89 c5                	mov    %eax,%ebp
f01021a9:	29 fb                	sub    %edi,%ebx
f01021ab:	d3 e6                	shl    %cl,%esi
f01021ad:	89 d9                	mov    %ebx,%ecx
f01021af:	d3 ed                	shr    %cl,%ebp
f01021b1:	89 f9                	mov    %edi,%ecx
f01021b3:	d3 e0                	shl    %cl,%eax
f01021b5:	09 ee                	or     %ebp,%esi
f01021b7:	89 d9                	mov    %ebx,%ecx
f01021b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01021bd:	89 d5                	mov    %edx,%ebp
f01021bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01021c3:	d3 ed                	shr    %cl,%ebp
f01021c5:	89 f9                	mov    %edi,%ecx
f01021c7:	d3 e2                	shl    %cl,%edx
f01021c9:	89 d9                	mov    %ebx,%ecx
f01021cb:	d3 e8                	shr    %cl,%eax
f01021cd:	09 c2                	or     %eax,%edx
f01021cf:	89 d0                	mov    %edx,%eax
f01021d1:	89 ea                	mov    %ebp,%edx
f01021d3:	f7 f6                	div    %esi
f01021d5:	89 d5                	mov    %edx,%ebp
f01021d7:	89 c3                	mov    %eax,%ebx
f01021d9:	f7 64 24 0c          	mull   0xc(%esp)
f01021dd:	39 d5                	cmp    %edx,%ebp
f01021df:	72 10                	jb     f01021f1 <__udivdi3+0xc1>
f01021e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01021e5:	89 f9                	mov    %edi,%ecx
f01021e7:	d3 e6                	shl    %cl,%esi
f01021e9:	39 c6                	cmp    %eax,%esi
f01021eb:	73 07                	jae    f01021f4 <__udivdi3+0xc4>
f01021ed:	39 d5                	cmp    %edx,%ebp
f01021ef:	75 03                	jne    f01021f4 <__udivdi3+0xc4>
f01021f1:	83 eb 01             	sub    $0x1,%ebx
f01021f4:	31 ff                	xor    %edi,%edi
f01021f6:	89 d8                	mov    %ebx,%eax
f01021f8:	89 fa                	mov    %edi,%edx
f01021fa:	83 c4 1c             	add    $0x1c,%esp
f01021fd:	5b                   	pop    %ebx
f01021fe:	5e                   	pop    %esi
f01021ff:	5f                   	pop    %edi
f0102200:	5d                   	pop    %ebp
f0102201:	c3                   	ret    
f0102202:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102208:	31 ff                	xor    %edi,%edi
f010220a:	31 db                	xor    %ebx,%ebx
f010220c:	89 d8                	mov    %ebx,%eax
f010220e:	89 fa                	mov    %edi,%edx
f0102210:	83 c4 1c             	add    $0x1c,%esp
f0102213:	5b                   	pop    %ebx
f0102214:	5e                   	pop    %esi
f0102215:	5f                   	pop    %edi
f0102216:	5d                   	pop    %ebp
f0102217:	c3                   	ret    
f0102218:	90                   	nop
f0102219:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102220:	89 d8                	mov    %ebx,%eax
f0102222:	f7 f7                	div    %edi
f0102224:	31 ff                	xor    %edi,%edi
f0102226:	89 c3                	mov    %eax,%ebx
f0102228:	89 d8                	mov    %ebx,%eax
f010222a:	89 fa                	mov    %edi,%edx
f010222c:	83 c4 1c             	add    $0x1c,%esp
f010222f:	5b                   	pop    %ebx
f0102230:	5e                   	pop    %esi
f0102231:	5f                   	pop    %edi
f0102232:	5d                   	pop    %ebp
f0102233:	c3                   	ret    
f0102234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102238:	39 ce                	cmp    %ecx,%esi
f010223a:	72 0c                	jb     f0102248 <__udivdi3+0x118>
f010223c:	31 db                	xor    %ebx,%ebx
f010223e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102242:	0f 87 34 ff ff ff    	ja     f010217c <__udivdi3+0x4c>
f0102248:	bb 01 00 00 00       	mov    $0x1,%ebx
f010224d:	e9 2a ff ff ff       	jmp    f010217c <__udivdi3+0x4c>
f0102252:	66 90                	xchg   %ax,%ax
f0102254:	66 90                	xchg   %ax,%ax
f0102256:	66 90                	xchg   %ax,%ax
f0102258:	66 90                	xchg   %ax,%ax
f010225a:	66 90                	xchg   %ax,%ax
f010225c:	66 90                	xchg   %ax,%ax
f010225e:	66 90                	xchg   %ax,%ax

f0102260 <__umoddi3>:
f0102260:	55                   	push   %ebp
f0102261:	57                   	push   %edi
f0102262:	56                   	push   %esi
f0102263:	53                   	push   %ebx
f0102264:	83 ec 1c             	sub    $0x1c,%esp
f0102267:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010226b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010226f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102273:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102277:	85 d2                	test   %edx,%edx
f0102279:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010227d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102281:	89 f3                	mov    %esi,%ebx
f0102283:	89 3c 24             	mov    %edi,(%esp)
f0102286:	89 74 24 04          	mov    %esi,0x4(%esp)
f010228a:	75 1c                	jne    f01022a8 <__umoddi3+0x48>
f010228c:	39 f7                	cmp    %esi,%edi
f010228e:	76 50                	jbe    f01022e0 <__umoddi3+0x80>
f0102290:	89 c8                	mov    %ecx,%eax
f0102292:	89 f2                	mov    %esi,%edx
f0102294:	f7 f7                	div    %edi
f0102296:	89 d0                	mov    %edx,%eax
f0102298:	31 d2                	xor    %edx,%edx
f010229a:	83 c4 1c             	add    $0x1c,%esp
f010229d:	5b                   	pop    %ebx
f010229e:	5e                   	pop    %esi
f010229f:	5f                   	pop    %edi
f01022a0:	5d                   	pop    %ebp
f01022a1:	c3                   	ret    
f01022a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01022a8:	39 f2                	cmp    %esi,%edx
f01022aa:	89 d0                	mov    %edx,%eax
f01022ac:	77 52                	ja     f0102300 <__umoddi3+0xa0>
f01022ae:	0f bd ea             	bsr    %edx,%ebp
f01022b1:	83 f5 1f             	xor    $0x1f,%ebp
f01022b4:	75 5a                	jne    f0102310 <__umoddi3+0xb0>
f01022b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01022ba:	0f 82 e0 00 00 00    	jb     f01023a0 <__umoddi3+0x140>
f01022c0:	39 0c 24             	cmp    %ecx,(%esp)
f01022c3:	0f 86 d7 00 00 00    	jbe    f01023a0 <__umoddi3+0x140>
f01022c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01022cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01022d1:	83 c4 1c             	add    $0x1c,%esp
f01022d4:	5b                   	pop    %ebx
f01022d5:	5e                   	pop    %esi
f01022d6:	5f                   	pop    %edi
f01022d7:	5d                   	pop    %ebp
f01022d8:	c3                   	ret    
f01022d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022e0:	85 ff                	test   %edi,%edi
f01022e2:	89 fd                	mov    %edi,%ebp
f01022e4:	75 0b                	jne    f01022f1 <__umoddi3+0x91>
f01022e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01022eb:	31 d2                	xor    %edx,%edx
f01022ed:	f7 f7                	div    %edi
f01022ef:	89 c5                	mov    %eax,%ebp
f01022f1:	89 f0                	mov    %esi,%eax
f01022f3:	31 d2                	xor    %edx,%edx
f01022f5:	f7 f5                	div    %ebp
f01022f7:	89 c8                	mov    %ecx,%eax
f01022f9:	f7 f5                	div    %ebp
f01022fb:	89 d0                	mov    %edx,%eax
f01022fd:	eb 99                	jmp    f0102298 <__umoddi3+0x38>
f01022ff:	90                   	nop
f0102300:	89 c8                	mov    %ecx,%eax
f0102302:	89 f2                	mov    %esi,%edx
f0102304:	83 c4 1c             	add    $0x1c,%esp
f0102307:	5b                   	pop    %ebx
f0102308:	5e                   	pop    %esi
f0102309:	5f                   	pop    %edi
f010230a:	5d                   	pop    %ebp
f010230b:	c3                   	ret    
f010230c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102310:	8b 34 24             	mov    (%esp),%esi
f0102313:	bf 20 00 00 00       	mov    $0x20,%edi
f0102318:	89 e9                	mov    %ebp,%ecx
f010231a:	29 ef                	sub    %ebp,%edi
f010231c:	d3 e0                	shl    %cl,%eax
f010231e:	89 f9                	mov    %edi,%ecx
f0102320:	89 f2                	mov    %esi,%edx
f0102322:	d3 ea                	shr    %cl,%edx
f0102324:	89 e9                	mov    %ebp,%ecx
f0102326:	09 c2                	or     %eax,%edx
f0102328:	89 d8                	mov    %ebx,%eax
f010232a:	89 14 24             	mov    %edx,(%esp)
f010232d:	89 f2                	mov    %esi,%edx
f010232f:	d3 e2                	shl    %cl,%edx
f0102331:	89 f9                	mov    %edi,%ecx
f0102333:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102337:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010233b:	d3 e8                	shr    %cl,%eax
f010233d:	89 e9                	mov    %ebp,%ecx
f010233f:	89 c6                	mov    %eax,%esi
f0102341:	d3 e3                	shl    %cl,%ebx
f0102343:	89 f9                	mov    %edi,%ecx
f0102345:	89 d0                	mov    %edx,%eax
f0102347:	d3 e8                	shr    %cl,%eax
f0102349:	89 e9                	mov    %ebp,%ecx
f010234b:	09 d8                	or     %ebx,%eax
f010234d:	89 d3                	mov    %edx,%ebx
f010234f:	89 f2                	mov    %esi,%edx
f0102351:	f7 34 24             	divl   (%esp)
f0102354:	89 d6                	mov    %edx,%esi
f0102356:	d3 e3                	shl    %cl,%ebx
f0102358:	f7 64 24 04          	mull   0x4(%esp)
f010235c:	39 d6                	cmp    %edx,%esi
f010235e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102362:	89 d1                	mov    %edx,%ecx
f0102364:	89 c3                	mov    %eax,%ebx
f0102366:	72 08                	jb     f0102370 <__umoddi3+0x110>
f0102368:	75 11                	jne    f010237b <__umoddi3+0x11b>
f010236a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010236e:	73 0b                	jae    f010237b <__umoddi3+0x11b>
f0102370:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102374:	1b 14 24             	sbb    (%esp),%edx
f0102377:	89 d1                	mov    %edx,%ecx
f0102379:	89 c3                	mov    %eax,%ebx
f010237b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010237f:	29 da                	sub    %ebx,%edx
f0102381:	19 ce                	sbb    %ecx,%esi
f0102383:	89 f9                	mov    %edi,%ecx
f0102385:	89 f0                	mov    %esi,%eax
f0102387:	d3 e0                	shl    %cl,%eax
f0102389:	89 e9                	mov    %ebp,%ecx
f010238b:	d3 ea                	shr    %cl,%edx
f010238d:	89 e9                	mov    %ebp,%ecx
f010238f:	d3 ee                	shr    %cl,%esi
f0102391:	09 d0                	or     %edx,%eax
f0102393:	89 f2                	mov    %esi,%edx
f0102395:	83 c4 1c             	add    $0x1c,%esp
f0102398:	5b                   	pop    %ebx
f0102399:	5e                   	pop    %esi
f010239a:	5f                   	pop    %edi
f010239b:	5d                   	pop    %ebp
f010239c:	c3                   	ret    
f010239d:	8d 76 00             	lea    0x0(%esi),%esi
f01023a0:	29 f9                	sub    %edi,%ecx
f01023a2:	19 d6                	sbb    %edx,%esi
f01023a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01023a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01023ac:	e9 18 ff ff ff       	jmp    f01022c9 <__umoddi3+0x69>
