
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
f0100058:	e8 a8 30 00 00       	call   f0103105 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 35 10 f0       	push   $0xf01035a0
f010006f:	e8 a8 25 00 00       	call   f010261c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 fd 0e 00 00       	call   f0100f76 <mem_init>
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
f01000b0:	68 bb 35 10 f0       	push   $0xf01035bb
f01000b5:	e8 62 25 00 00       	call   f010261c <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 32 25 00 00       	call   f01025f6 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 6d 44 10 f0 	movl   $0xf010446d,(%esp)
f01000cb:	e8 4c 25 00 00       	call   f010261c <cprintf>
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
f01000f2:	68 d3 35 10 f0       	push   $0xf01035d3
f01000f7:	e8 20 25 00 00       	call   f010261c <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ee 24 00 00       	call   f01025f6 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 6d 44 10 f0 	movl   $0xf010446d,(%esp)
f010010f:	e8 08 25 00 00       	call   f010261c <cprintf>
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
f01001ce:	0f b6 82 40 37 10 f0 	movzbl -0xfefc8c0(%edx),%eax
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
f010020a:	0f b6 82 40 37 10 f0 	movzbl -0xfefc8c0(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 40 36 10 f0 	movzbl -0xfefc9c0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 20 36 10 f0 	mov    -0xfefc9e0(,%ecx,4),%ecx
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
f0100268:	68 ed 35 10 f0       	push   $0xf01035ed
f010026d:	e8 aa 23 00 00       	call   f010261c <cprintf>
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
f010041c:	e8 31 2d 00 00       	call   f0103152 <memmove>
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
f01005eb:	68 f9 35 10 f0       	push   $0xf01035f9
f01005f0:	e8 27 20 00 00       	call   f010261c <cprintf>
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
f0100631:	68 40 38 10 f0       	push   $0xf0103840
f0100636:	68 5e 38 10 f0       	push   $0xf010385e
f010063b:	68 63 38 10 f0       	push   $0xf0103863
f0100640:	e8 d7 1f 00 00       	call   f010261c <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 cc 38 10 f0       	push   $0xf01038cc
f010064d:	68 6c 38 10 f0       	push   $0xf010386c
f0100652:	68 63 38 10 f0       	push   $0xf0103863
f0100657:	e8 c0 1f 00 00       	call   f010261c <cprintf>
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
f0100669:	68 75 38 10 f0       	push   $0xf0103875
f010066e:	e8 a9 1f 00 00       	call   f010261c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 f4 38 10 f0       	push   $0xf01038f4
f0100680:	e8 97 1f 00 00       	call   f010261c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 1c 39 10 f0       	push   $0xf010391c
f0100697:	e8 80 1f 00 00       	call   f010261c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 91 35 10 00       	push   $0x103591
f01006a4:	68 91 35 10 f0       	push   $0xf0103591
f01006a9:	68 40 39 10 f0       	push   $0xf0103940
f01006ae:	e8 69 1f 00 00       	call   f010261c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 64 39 10 f0       	push   $0xf0103964
f01006c5:	e8 52 1f 00 00       	call   f010261c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 88 39 10 f0       	push   $0xf0103988
f01006dc:	e8 3b 1f 00 00       	call   f010261c <cprintf>
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
f0100702:	68 ac 39 10 f0       	push   $0xf01039ac
f0100707:	e8 10 1f 00 00       	call   f010261c <cprintf>
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
f0100726:	68 d8 39 10 f0       	push   $0xf01039d8
f010072b:	e8 ec 1e 00 00       	call   f010261c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100730:	c7 04 24 fc 39 10 f0 	movl   $0xf01039fc,(%esp)
f0100737:	e8 e0 1e 00 00       	call   f010261c <cprintf>
f010073c:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010073f:	83 ec 0c             	sub    $0xc,%esp
f0100742:	68 8e 38 10 f0       	push   $0xf010388e
f0100747:	e8 62 27 00 00       	call   f0102eae <readline>
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
f010077b:	68 92 38 10 f0       	push   $0xf0103892
f0100780:	e8 43 29 00 00       	call   f01030c8 <strchr>
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
f010079b:	68 97 38 10 f0       	push   $0xf0103897
f01007a0:	e8 77 1e 00 00       	call   f010261c <cprintf>
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
f01007c4:	68 92 38 10 f0       	push   $0xf0103892
f01007c9:	e8 fa 28 00 00       	call   f01030c8 <strchr>
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
f01007ea:	68 5e 38 10 f0       	push   $0xf010385e
f01007ef:	ff 75 a8             	pushl  -0x58(%ebp)
f01007f2:	e8 73 28 00 00       	call   f010306a <strcmp>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	85 c0                	test   %eax,%eax
f01007fc:	74 1e                	je     f010081c <monitor+0xff>
f01007fe:	83 ec 08             	sub    $0x8,%esp
f0100801:	68 6c 38 10 f0       	push   $0xf010386c
f0100806:	ff 75 a8             	pushl  -0x58(%ebp)
f0100809:	e8 5c 28 00 00       	call   f010306a <strcmp>
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
f0100831:	ff 14 85 2c 3a 10 f0 	call   *-0xfefc5d4(,%eax,4)


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
f010084a:	68 b4 38 10 f0       	push   $0xf01038b4
f010084f:	e8 c8 1d 00 00       	call   f010261c <cprintf>
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
f01008a7:	e8 09 1d 00 00       	call   f01025b5 <mc146818_read>
f01008ac:	89 c6                	mov    %eax,%esi
f01008ae:	83 c3 01             	add    $0x1,%ebx
f01008b1:	89 1c 24             	mov    %ebx,(%esp)
f01008b4:	e8 fc 1c 00 00       	call   f01025b5 <mc146818_read>
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
f01008ea:	68 3c 3a 10 f0       	push   $0xf0103a3c
f01008ef:	68 de 02 00 00       	push   $0x2de
f01008f4:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100942:	68 60 3a 10 f0       	push   $0xf0103a60
f0100947:	68 21 02 00 00       	push   $0x221
f010094c:	68 bc 41 10 f0       	push   $0xf01041bc
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
f01009d1:	68 3c 3a 10 f0       	push   $0xf0103a3c
f01009d6:	6a 52                	push   $0x52
f01009d8:	68 c8 41 10 f0       	push   $0xf01041c8
f01009dd:	e8 a9 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f01009e2:	83 ec 04             	sub    $0x4,%esp
f01009e5:	68 80 00 00 00       	push   $0x80
f01009ea:	68 97 00 00 00       	push   $0x97
f01009ef:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01009f4:	50                   	push   %eax
f01009f5:	e8 0b 27 00 00       	call   f0103105 <memset>
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
f0100a3b:	68 d6 41 10 f0       	push   $0xf01041d6
f0100a40:	68 e2 41 10 f0       	push   $0xf01041e2
f0100a45:	68 3b 02 00 00       	push   $0x23b
f0100a4a:	68 bc 41 10 f0       	push   $0xf01041bc
f0100a4f:	e8 37 f6 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a54:	39 fa                	cmp    %edi,%edx
f0100a56:	72 19                	jb     f0100a71 <check_page_free_list+0x148>
f0100a58:	68 f7 41 10 f0       	push   $0xf01041f7
f0100a5d:	68 e2 41 10 f0       	push   $0xf01041e2
f0100a62:	68 3c 02 00 00       	push   $0x23c
f0100a67:	68 bc 41 10 f0       	push   $0xf01041bc
f0100a6c:	e8 1a f6 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a71:	89 d0                	mov    %edx,%eax
f0100a73:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100a76:	a8 07                	test   $0x7,%al
f0100a78:	74 19                	je     f0100a93 <check_page_free_list+0x16a>
f0100a7a:	68 84 3a 10 f0       	push   $0xf0103a84
f0100a7f:	68 e2 41 10 f0       	push   $0xf01041e2
f0100a84:	68 3d 02 00 00       	push   $0x23d
f0100a89:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100a9d:	68 0b 42 10 f0       	push   $0xf010420b
f0100aa2:	68 e2 41 10 f0       	push   $0xf01041e2
f0100aa7:	68 40 02 00 00       	push   $0x240
f0100aac:	68 bc 41 10 f0       	push   $0xf01041bc
f0100ab1:	e8 d5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ab6:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100abb:	75 19                	jne    f0100ad6 <check_page_free_list+0x1ad>
f0100abd:	68 1c 42 10 f0       	push   $0xf010421c
f0100ac2:	68 e2 41 10 f0       	push   $0xf01041e2
f0100ac7:	68 41 02 00 00       	push   $0x241
f0100acc:	68 bc 41 10 f0       	push   $0xf01041bc
f0100ad1:	e8 b5 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ad6:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100adb:	75 19                	jne    f0100af6 <check_page_free_list+0x1cd>
f0100add:	68 b8 3a 10 f0       	push   $0xf0103ab8
f0100ae2:	68 e2 41 10 f0       	push   $0xf01041e2
f0100ae7:	68 42 02 00 00       	push   $0x242
f0100aec:	68 bc 41 10 f0       	push   $0xf01041bc
f0100af1:	e8 95 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100af6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100afb:	75 19                	jne    f0100b16 <check_page_free_list+0x1ed>
f0100afd:	68 35 42 10 f0       	push   $0xf0104235
f0100b02:	68 e2 41 10 f0       	push   $0xf01041e2
f0100b07:	68 43 02 00 00       	push   $0x243
f0100b0c:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100b28:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0100b2d:	6a 52                	push   $0x52
f0100b2f:	68 c8 41 10 f0       	push   $0xf01041c8
f0100b34:	e8 52 f5 ff ff       	call   f010008b <_panic>
f0100b39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b3e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b41:	76 1e                	jbe    f0100b61 <check_page_free_list+0x238>
f0100b43:	68 dc 3a 10 f0       	push   $0xf0103adc
f0100b48:	68 e2 41 10 f0       	push   $0xf01041e2
f0100b4d:	68 44 02 00 00       	push   $0x244
f0100b52:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100b76:	68 4f 42 10 f0       	push   $0xf010424f
f0100b7b:	68 e2 41 10 f0       	push   $0xf01041e2
f0100b80:	68 4c 02 00 00       	push   $0x24c
f0100b85:	68 bc 41 10 f0       	push   $0xf01041bc
f0100b8a:	e8 fc f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100b8f:	85 db                	test   %ebx,%ebx
f0100b91:	7f 42                	jg     f0100bd5 <check_page_free_list+0x2ac>
f0100b93:	68 61 42 10 f0       	push   $0xf0104261
f0100b98:	68 e2 41 10 f0       	push   $0xf01041e2
f0100b9d:	68 4d 02 00 00       	push   $0x24d
f0100ba2:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100bfe:	68 24 3b 10 f0       	push   $0xf0103b24
f0100c03:	68 03 01 00 00       	push   $0x103
f0100c08:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100ce6:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0100ceb:	6a 52                	push   $0x52
f0100ced:	68 c8 41 10 f0       	push   $0xf01041c8
f0100cf2:	e8 94 f3 ff ff       	call   f010008b <_panic>
          memset(page2kva(result),0,PGSIZE);
f0100cf7:	83 ec 04             	sub    $0x4,%esp
f0100cfa:	68 00 10 00 00       	push   $0x1000
f0100cff:	6a 00                	push   $0x0
f0100d01:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d06:	50                   	push   %eax
f0100d07:	e8 f9 23 00 00       	call   f0103105 <memset>
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
f0100d2b:	68 48 3b 10 f0       	push   $0xf0103b48
f0100d30:	68 e2 41 10 f0       	push   $0xf01041e2
f0100d35:	68 3f 01 00 00       	push   $0x13f
f0100d3a:	68 bc 41 10 f0       	push   $0xf01041bc
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
f0100ddd:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0100de2:	68 7a 01 00 00       	push   $0x17a
f0100de7:	68 bc 41 10 f0       	push   $0xf01041bc
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

f0100e0d <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e0d:	55                   	push   %ebp
f0100e0e:	89 e5                	mov    %esp,%ebp
f0100e10:	57                   	push   %edi
f0100e11:	56                   	push   %esi
f0100e12:	53                   	push   %ebx
f0100e13:	83 ec 1c             	sub    $0x1c,%esp
f0100e16:	89 c7                	mov    %eax,%edi
f0100e18:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e1b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *po_entry;
	uint32_t i;
	for(i=0;i<size;i=i+PGSIZE)
f0100e1e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e23:	eb 1f                	jmp    f0100e44 <boot_map_region+0x37>
	{	
		po_entry=pgdir_walk(pgdir,(void *)va,1);
f0100e25:	83 ec 04             	sub    $0x4,%esp
f0100e28:	6a 01                	push   $0x1
f0100e2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e2d:	01 d8                	add    %ebx,%eax
f0100e2f:	50                   	push   %eax
f0100e30:	57                   	push   %edi
f0100e31:	e8 44 ff ff ff       	call   f0100d7a <pgdir_walk>
		*po_entry=pa|perm;
f0100e36:	0b 75 0c             	or     0xc(%ebp),%esi
f0100e39:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *po_entry;
	uint32_t i;
	for(i=0;i<size;i=i+PGSIZE)
f0100e3b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e41:	83 c4 10             	add    $0x10,%esp
f0100e44:	89 de                	mov    %ebx,%esi
f0100e46:	03 75 08             	add    0x8(%ebp),%esi
f0100e49:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100e4c:	72 d7                	jb     f0100e25 <boot_map_region+0x18>
		*po_entry=pa|perm;
		pa=pa+PGSIZE;
		va=va+PGSIZE;
	}		
	
}
f0100e4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e51:	5b                   	pop    %ebx
f0100e52:	5e                   	pop    %esi
f0100e53:	5f                   	pop    %edi
f0100e54:	5d                   	pop    %ebp
f0100e55:	c3                   	ret    

f0100e56 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e56:	55                   	push   %ebp
f0100e57:	89 e5                	mov    %esp,%ebp
f0100e59:	53                   	push   %ebx
f0100e5a:	83 ec 08             	sub    $0x8,%esp
f0100e5d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
f0100e60:	6a 00                	push   $0x0
f0100e62:	ff 75 0c             	pushl  0xc(%ebp)
f0100e65:	ff 75 08             	pushl  0x8(%ebp)
f0100e68:	e8 0d ff ff ff       	call   f0100d7a <pgdir_walk>
	if(po_entry==NULL)
f0100e6d:	83 c4 10             	add    $0x10,%esp
f0100e70:	85 c0                	test   %eax,%eax
f0100e72:	74 37                	je     f0100eab <page_lookup+0x55>
	{
		return NULL;
	}
	if(!(*po_entry&PTE_P))
f0100e74:	f6 00 01             	testb  $0x1,(%eax)
f0100e77:	74 39                	je     f0100eb2 <page_lookup+0x5c>
	{
		return NULL;
	}
	if(pte_store!=0)
f0100e79:	85 db                	test   %ebx,%ebx
f0100e7b:	74 02                	je     f0100e7f <page_lookup+0x29>
	{
		*pte_store=po_entry;
f0100e7d:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e7f:	8b 00                	mov    (%eax),%eax
f0100e81:	c1 e8 0c             	shr    $0xc,%eax
f0100e84:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100e8a:	72 14                	jb     f0100ea0 <page_lookup+0x4a>
		panic("pa2page called with invalid pa");
f0100e8c:	83 ec 04             	sub    $0x4,%esp
f0100e8f:	68 70 3b 10 f0       	push   $0xf0103b70
f0100e94:	6a 4b                	push   $0x4b
f0100e96:	68 c8 41 10 f0       	push   $0xf01041c8
f0100e9b:	e8 eb f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100ea0:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100ea6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
f0100ea9:	eb 0c                	jmp    f0100eb7 <page_lookup+0x61>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,0);
	if(po_entry==NULL)
	{
		return NULL;
f0100eab:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb0:	eb 05                	jmp    f0100eb7 <page_lookup+0x61>
	}
	if(!(*po_entry&PTE_P))
	{
		return NULL;
f0100eb2:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store!=0)
	{
		*pte_store=po_entry;
	}  
	return pa2page(PTE_ADDR(*po_entry)); 
}	
f0100eb7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100eba:	c9                   	leave  
f0100ebb:	c3                   	ret    

f0100ebc <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ebc:	55                   	push   %ebp
f0100ebd:	89 e5                	mov    %esp,%ebp
f0100ebf:	53                   	push   %ebx
f0100ec0:	83 ec 18             	sub    $0x18,%esp
f0100ec3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	struct PageInfo *pp;
	pte_t *pte_store=NULL;
f0100ec6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pp=page_lookup(pgdir,va,&pte_store);
f0100ecd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ed0:	50                   	push   %eax
f0100ed1:	53                   	push   %ebx
f0100ed2:	ff 75 08             	pushl  0x8(%ebp)
f0100ed5:	e8 7c ff ff ff       	call   f0100e56 <page_lookup>
	if(pp==NULL)
f0100eda:	83 c4 10             	add    $0x10,%esp
f0100edd:	85 c0                	test   %eax,%eax
f0100edf:	74 18                	je     f0100ef9 <page_remove+0x3d>
	{
		return;
	}
	page_decref(pp);
f0100ee1:	83 ec 0c             	sub    $0xc,%esp
f0100ee4:	50                   	push   %eax
f0100ee5:	e8 69 fe ff ff       	call   f0100d53 <page_decref>
	*pte_store=0;
f0100eea:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100eed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ef3:	0f 01 3b             	invlpg (%ebx)
f0100ef6:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);	
}
f0100ef9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100efc:	c9                   	leave  
f0100efd:	c3                   	ret    

f0100efe <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100efe:	55                   	push   %ebp
f0100eff:	89 e5                	mov    %esp,%ebp
f0100f01:	57                   	push   %edi
f0100f02:	56                   	push   %esi
f0100f03:	53                   	push   %ebx
f0100f04:	83 ec 10             	sub    $0x10,%esp
f0100f07:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
f0100f0d:	6a 01                	push   $0x1
f0100f0f:	ff 75 10             	pushl  0x10(%ebp)
f0100f12:	56                   	push   %esi
f0100f13:	e8 62 fe ff ff       	call   f0100d7a <pgdir_walk>
	if(po_entry==NULL)
f0100f18:	83 c4 10             	add    $0x10,%esp
f0100f1b:	85 c0                	test   %eax,%eax
f0100f1d:	74 4a                	je     f0100f69 <page_insert+0x6b>
f0100f1f:	89 c7                	mov    %eax,%edi
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100f21:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*po_entry)&PTE_P)
f0100f26:	f6 00 01             	testb  $0x1,(%eax)
f0100f29:	74 15                	je     f0100f40 <page_insert+0x42>
f0100f2b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f2e:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir,va);
		page_remove(pgdir,va);
f0100f31:	83 ec 08             	sub    $0x8,%esp
f0100f34:	ff 75 10             	pushl  0x10(%ebp)
f0100f37:	56                   	push   %esi
f0100f38:	e8 7f ff ff ff       	call   f0100ebc <page_remove>
f0100f3d:	83 c4 10             	add    $0x10,%esp
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
f0100f40:	2b 1d 4c 69 11 f0    	sub    0xf011694c,%ebx
f0100f46:	c1 fb 03             	sar    $0x3,%ebx
f0100f49:	c1 e3 0c             	shl    $0xc,%ebx
f0100f4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4f:	83 c8 01             	or     $0x1,%eax
f0100f52:	09 c3                	or     %eax,%ebx
f0100f54:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)]|=perm;
f0100f56:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f59:	c1 e8 16             	shr    $0x16,%eax
f0100f5c:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f5f:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0100f62:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f67:	eb 05                	jmp    f0100f6e <page_insert+0x70>
{
	// Fill this function in
	pte_t *po_entry=pgdir_walk(pgdir,va,1);
	if(po_entry==NULL)
	{
		return -E_NO_MEM;
f0100f69:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir,va);
	}
	*po_entry=page2pa(pp)|perm|PTE_P;
	pgdir[PDX(va)]|=perm;
	return 0;
}
f0100f6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f71:	5b                   	pop    %ebx
f0100f72:	5e                   	pop    %esi
f0100f73:	5f                   	pop    %edi
f0100f74:	5d                   	pop    %ebp
f0100f75:	c3                   	ret    

f0100f76 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f76:	55                   	push   %ebp
f0100f77:	89 e5                	mov    %esp,%ebp
f0100f79:	57                   	push   %edi
f0100f7a:	56                   	push   %esi
f0100f7b:	53                   	push   %ebx
f0100f7c:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f7f:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f84:	e8 13 f9 ff ff       	call   f010089c <nvram_read>
f0100f89:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f8b:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f90:	e8 07 f9 ff ff       	call   f010089c <nvram_read>
f0100f95:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100f97:	b8 34 00 00 00       	mov    $0x34,%eax
f0100f9c:	e8 fb f8 ff ff       	call   f010089c <nvram_read>
f0100fa1:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100fa4:	85 c0                	test   %eax,%eax
f0100fa6:	74 07                	je     f0100faf <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100fa8:	05 00 40 00 00       	add    $0x4000,%eax
f0100fad:	eb 0b                	jmp    f0100fba <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100faf:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100fb5:	85 f6                	test   %esi,%esi
f0100fb7:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100fba:	89 c2                	mov    %eax,%edx
f0100fbc:	c1 ea 02             	shr    $0x2,%edx
f0100fbf:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100fc5:	89 c2                	mov    %eax,%edx
f0100fc7:	29 da                	sub    %ebx,%edx
f0100fc9:	52                   	push   %edx
f0100fca:	53                   	push   %ebx
f0100fcb:	50                   	push   %eax
f0100fcc:	68 90 3b 10 f0       	push   $0xf0103b90
f0100fd1:	e8 46 16 00 00       	call   f010261c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100fd6:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100fdb:	e8 84 f8 ff ff       	call   f0100864 <boot_alloc>
f0100fe0:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0100fe5:	83 c4 0c             	add    $0xc,%esp
f0100fe8:	68 00 10 00 00       	push   $0x1000
f0100fed:	6a 00                	push   $0x0
f0100fef:	50                   	push   %eax
f0100ff0:	e8 10 21 00 00       	call   f0103105 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100ff5:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ffa:	83 c4 10             	add    $0x10,%esp
f0100ffd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101002:	77 15                	ja     f0101019 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101004:	50                   	push   %eax
f0101005:	68 24 3b 10 f0       	push   $0xf0103b24
f010100a:	68 8f 00 00 00       	push   $0x8f
f010100f:	68 bc 41 10 f0       	push   $0xf01041bc
f0101014:	e8 72 f0 ff ff       	call   f010008b <_panic>
f0101019:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010101f:	83 ca 05             	or     $0x5,%edx
f0101022:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages*sizeof(struct PageInfo));
f0101028:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f010102d:	c1 e0 03             	shl    $0x3,%eax
f0101030:	e8 2f f8 ff ff       	call   f0100864 <boot_alloc>
f0101035:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
        memset(pages,0,npages*sizeof(struct PageInfo));
f010103a:	83 ec 04             	sub    $0x4,%esp
f010103d:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101043:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010104a:	52                   	push   %edx
f010104b:	6a 00                	push   $0x0
f010104d:	50                   	push   %eax
f010104e:	e8 b2 20 00 00       	call   f0103105 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101053:	e8 85 fb ff ff       	call   f0100bdd <page_init>
	check_page_free_list(1);
f0101058:	b8 01 00 00 00       	mov    $0x1,%eax
f010105d:	e8 c7 f8 ff ff       	call   f0100929 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101062:	83 c4 10             	add    $0x10,%esp
f0101065:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f010106c:	75 17                	jne    f0101085 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f010106e:	83 ec 04             	sub    $0x4,%esp
f0101071:	68 72 42 10 f0       	push   $0xf0104272
f0101076:	68 5e 02 00 00       	push   $0x25e
f010107b:	68 bc 41 10 f0       	push   $0xf01041bc
f0101080:	e8 06 f0 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101085:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010108a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010108f:	eb 05                	jmp    f0101096 <mem_init+0x120>
		++nfree;
f0101091:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101094:	8b 00                	mov    (%eax),%eax
f0101096:	85 c0                	test   %eax,%eax
f0101098:	75 f7                	jne    f0101091 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010109a:	83 ec 0c             	sub    $0xc,%esp
f010109d:	6a 00                	push   $0x0
f010109f:	e8 02 fc ff ff       	call   f0100ca6 <page_alloc>
f01010a4:	89 c7                	mov    %eax,%edi
f01010a6:	83 c4 10             	add    $0x10,%esp
f01010a9:	85 c0                	test   %eax,%eax
f01010ab:	75 19                	jne    f01010c6 <mem_init+0x150>
f01010ad:	68 8d 42 10 f0       	push   $0xf010428d
f01010b2:	68 e2 41 10 f0       	push   $0xf01041e2
f01010b7:	68 66 02 00 00       	push   $0x266
f01010bc:	68 bc 41 10 f0       	push   $0xf01041bc
f01010c1:	e8 c5 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01010c6:	83 ec 0c             	sub    $0xc,%esp
f01010c9:	6a 00                	push   $0x0
f01010cb:	e8 d6 fb ff ff       	call   f0100ca6 <page_alloc>
f01010d0:	89 c6                	mov    %eax,%esi
f01010d2:	83 c4 10             	add    $0x10,%esp
f01010d5:	85 c0                	test   %eax,%eax
f01010d7:	75 19                	jne    f01010f2 <mem_init+0x17c>
f01010d9:	68 a3 42 10 f0       	push   $0xf01042a3
f01010de:	68 e2 41 10 f0       	push   $0xf01041e2
f01010e3:	68 67 02 00 00       	push   $0x267
f01010e8:	68 bc 41 10 f0       	push   $0xf01041bc
f01010ed:	e8 99 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01010f2:	83 ec 0c             	sub    $0xc,%esp
f01010f5:	6a 00                	push   $0x0
f01010f7:	e8 aa fb ff ff       	call   f0100ca6 <page_alloc>
f01010fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01010ff:	83 c4 10             	add    $0x10,%esp
f0101102:	85 c0                	test   %eax,%eax
f0101104:	75 19                	jne    f010111f <mem_init+0x1a9>
f0101106:	68 b9 42 10 f0       	push   $0xf01042b9
f010110b:	68 e2 41 10 f0       	push   $0xf01041e2
f0101110:	68 68 02 00 00       	push   $0x268
f0101115:	68 bc 41 10 f0       	push   $0xf01041bc
f010111a:	e8 6c ef ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010111f:	39 f7                	cmp    %esi,%edi
f0101121:	75 19                	jne    f010113c <mem_init+0x1c6>
f0101123:	68 cf 42 10 f0       	push   $0xf01042cf
f0101128:	68 e2 41 10 f0       	push   $0xf01041e2
f010112d:	68 6b 02 00 00       	push   $0x26b
f0101132:	68 bc 41 10 f0       	push   $0xf01041bc
f0101137:	e8 4f ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010113c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010113f:	39 c6                	cmp    %eax,%esi
f0101141:	74 04                	je     f0101147 <mem_init+0x1d1>
f0101143:	39 c7                	cmp    %eax,%edi
f0101145:	75 19                	jne    f0101160 <mem_init+0x1ea>
f0101147:	68 cc 3b 10 f0       	push   $0xf0103bcc
f010114c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101151:	68 6c 02 00 00       	push   $0x26c
f0101156:	68 bc 41 10 f0       	push   $0xf01041bc
f010115b:	e8 2b ef ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101160:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101166:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f010116c:	c1 e2 0c             	shl    $0xc,%edx
f010116f:	89 f8                	mov    %edi,%eax
f0101171:	29 c8                	sub    %ecx,%eax
f0101173:	c1 f8 03             	sar    $0x3,%eax
f0101176:	c1 e0 0c             	shl    $0xc,%eax
f0101179:	39 d0                	cmp    %edx,%eax
f010117b:	72 19                	jb     f0101196 <mem_init+0x220>
f010117d:	68 e1 42 10 f0       	push   $0xf01042e1
f0101182:	68 e2 41 10 f0       	push   $0xf01041e2
f0101187:	68 6d 02 00 00       	push   $0x26d
f010118c:	68 bc 41 10 f0       	push   $0xf01041bc
f0101191:	e8 f5 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101196:	89 f0                	mov    %esi,%eax
f0101198:	29 c8                	sub    %ecx,%eax
f010119a:	c1 f8 03             	sar    $0x3,%eax
f010119d:	c1 e0 0c             	shl    $0xc,%eax
f01011a0:	39 c2                	cmp    %eax,%edx
f01011a2:	77 19                	ja     f01011bd <mem_init+0x247>
f01011a4:	68 fe 42 10 f0       	push   $0xf01042fe
f01011a9:	68 e2 41 10 f0       	push   $0xf01041e2
f01011ae:	68 6e 02 00 00       	push   $0x26e
f01011b3:	68 bc 41 10 f0       	push   $0xf01041bc
f01011b8:	e8 ce ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01011bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011c0:	29 c8                	sub    %ecx,%eax
f01011c2:	c1 f8 03             	sar    $0x3,%eax
f01011c5:	c1 e0 0c             	shl    $0xc,%eax
f01011c8:	39 c2                	cmp    %eax,%edx
f01011ca:	77 19                	ja     f01011e5 <mem_init+0x26f>
f01011cc:	68 1b 43 10 f0       	push   $0xf010431b
f01011d1:	68 e2 41 10 f0       	push   $0xf01041e2
f01011d6:	68 6f 02 00 00       	push   $0x26f
f01011db:	68 bc 41 10 f0       	push   $0xf01041bc
f01011e0:	e8 a6 ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011e5:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01011ea:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01011ed:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01011f4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011f7:	83 ec 0c             	sub    $0xc,%esp
f01011fa:	6a 00                	push   $0x0
f01011fc:	e8 a5 fa ff ff       	call   f0100ca6 <page_alloc>
f0101201:	83 c4 10             	add    $0x10,%esp
f0101204:	85 c0                	test   %eax,%eax
f0101206:	74 19                	je     f0101221 <mem_init+0x2ab>
f0101208:	68 38 43 10 f0       	push   $0xf0104338
f010120d:	68 e2 41 10 f0       	push   $0xf01041e2
f0101212:	68 76 02 00 00       	push   $0x276
f0101217:	68 bc 41 10 f0       	push   $0xf01041bc
f010121c:	e8 6a ee ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101221:	83 ec 0c             	sub    $0xc,%esp
f0101224:	57                   	push   %edi
f0101225:	e8 ec fa ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f010122a:	89 34 24             	mov    %esi,(%esp)
f010122d:	e8 e4 fa ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f0101232:	83 c4 04             	add    $0x4,%esp
f0101235:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101238:	e8 d9 fa ff ff       	call   f0100d16 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010123d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101244:	e8 5d fa ff ff       	call   f0100ca6 <page_alloc>
f0101249:	89 c6                	mov    %eax,%esi
f010124b:	83 c4 10             	add    $0x10,%esp
f010124e:	85 c0                	test   %eax,%eax
f0101250:	75 19                	jne    f010126b <mem_init+0x2f5>
f0101252:	68 8d 42 10 f0       	push   $0xf010428d
f0101257:	68 e2 41 10 f0       	push   $0xf01041e2
f010125c:	68 7d 02 00 00       	push   $0x27d
f0101261:	68 bc 41 10 f0       	push   $0xf01041bc
f0101266:	e8 20 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010126b:	83 ec 0c             	sub    $0xc,%esp
f010126e:	6a 00                	push   $0x0
f0101270:	e8 31 fa ff ff       	call   f0100ca6 <page_alloc>
f0101275:	89 c7                	mov    %eax,%edi
f0101277:	83 c4 10             	add    $0x10,%esp
f010127a:	85 c0                	test   %eax,%eax
f010127c:	75 19                	jne    f0101297 <mem_init+0x321>
f010127e:	68 a3 42 10 f0       	push   $0xf01042a3
f0101283:	68 e2 41 10 f0       	push   $0xf01041e2
f0101288:	68 7e 02 00 00       	push   $0x27e
f010128d:	68 bc 41 10 f0       	push   $0xf01041bc
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101297:	83 ec 0c             	sub    $0xc,%esp
f010129a:	6a 00                	push   $0x0
f010129c:	e8 05 fa ff ff       	call   f0100ca6 <page_alloc>
f01012a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012a4:	83 c4 10             	add    $0x10,%esp
f01012a7:	85 c0                	test   %eax,%eax
f01012a9:	75 19                	jne    f01012c4 <mem_init+0x34e>
f01012ab:	68 b9 42 10 f0       	push   $0xf01042b9
f01012b0:	68 e2 41 10 f0       	push   $0xf01041e2
f01012b5:	68 7f 02 00 00       	push   $0x27f
f01012ba:	68 bc 41 10 f0       	push   $0xf01041bc
f01012bf:	e8 c7 ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012c4:	39 fe                	cmp    %edi,%esi
f01012c6:	75 19                	jne    f01012e1 <mem_init+0x36b>
f01012c8:	68 cf 42 10 f0       	push   $0xf01042cf
f01012cd:	68 e2 41 10 f0       	push   $0xf01041e2
f01012d2:	68 81 02 00 00       	push   $0x281
f01012d7:	68 bc 41 10 f0       	push   $0xf01041bc
f01012dc:	e8 aa ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e4:	39 c6                	cmp    %eax,%esi
f01012e6:	74 04                	je     f01012ec <mem_init+0x376>
f01012e8:	39 c7                	cmp    %eax,%edi
f01012ea:	75 19                	jne    f0101305 <mem_init+0x38f>
f01012ec:	68 cc 3b 10 f0       	push   $0xf0103bcc
f01012f1:	68 e2 41 10 f0       	push   $0xf01041e2
f01012f6:	68 82 02 00 00       	push   $0x282
f01012fb:	68 bc 41 10 f0       	push   $0xf01041bc
f0101300:	e8 86 ed ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101305:	83 ec 0c             	sub    $0xc,%esp
f0101308:	6a 00                	push   $0x0
f010130a:	e8 97 f9 ff ff       	call   f0100ca6 <page_alloc>
f010130f:	83 c4 10             	add    $0x10,%esp
f0101312:	85 c0                	test   %eax,%eax
f0101314:	74 19                	je     f010132f <mem_init+0x3b9>
f0101316:	68 38 43 10 f0       	push   $0xf0104338
f010131b:	68 e2 41 10 f0       	push   $0xf01041e2
f0101320:	68 83 02 00 00       	push   $0x283
f0101325:	68 bc 41 10 f0       	push   $0xf01041bc
f010132a:	e8 5c ed ff ff       	call   f010008b <_panic>
f010132f:	89 f0                	mov    %esi,%eax
f0101331:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101337:	c1 f8 03             	sar    $0x3,%eax
f010133a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010133d:	89 c2                	mov    %eax,%edx
f010133f:	c1 ea 0c             	shr    $0xc,%edx
f0101342:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101348:	72 12                	jb     f010135c <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010134a:	50                   	push   %eax
f010134b:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0101350:	6a 52                	push   $0x52
f0101352:	68 c8 41 10 f0       	push   $0xf01041c8
f0101357:	e8 2f ed ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010135c:	83 ec 04             	sub    $0x4,%esp
f010135f:	68 00 10 00 00       	push   $0x1000
f0101364:	6a 01                	push   $0x1
f0101366:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010136b:	50                   	push   %eax
f010136c:	e8 94 1d 00 00       	call   f0103105 <memset>
	page_free(pp0);
f0101371:	89 34 24             	mov    %esi,(%esp)
f0101374:	e8 9d f9 ff ff       	call   f0100d16 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101379:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101380:	e8 21 f9 ff ff       	call   f0100ca6 <page_alloc>
f0101385:	83 c4 10             	add    $0x10,%esp
f0101388:	85 c0                	test   %eax,%eax
f010138a:	75 19                	jne    f01013a5 <mem_init+0x42f>
f010138c:	68 47 43 10 f0       	push   $0xf0104347
f0101391:	68 e2 41 10 f0       	push   $0xf01041e2
f0101396:	68 88 02 00 00       	push   $0x288
f010139b:	68 bc 41 10 f0       	push   $0xf01041bc
f01013a0:	e8 e6 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01013a5:	39 c6                	cmp    %eax,%esi
f01013a7:	74 19                	je     f01013c2 <mem_init+0x44c>
f01013a9:	68 65 43 10 f0       	push   $0xf0104365
f01013ae:	68 e2 41 10 f0       	push   $0xf01041e2
f01013b3:	68 89 02 00 00       	push   $0x289
f01013b8:	68 bc 41 10 f0       	push   $0xf01041bc
f01013bd:	e8 c9 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013c2:	89 f0                	mov    %esi,%eax
f01013c4:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01013ca:	c1 f8 03             	sar    $0x3,%eax
f01013cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013d0:	89 c2                	mov    %eax,%edx
f01013d2:	c1 ea 0c             	shr    $0xc,%edx
f01013d5:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01013db:	72 12                	jb     f01013ef <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013dd:	50                   	push   %eax
f01013de:	68 3c 3a 10 f0       	push   $0xf0103a3c
f01013e3:	6a 52                	push   $0x52
f01013e5:	68 c8 41 10 f0       	push   $0xf01041c8
f01013ea:	e8 9c ec ff ff       	call   f010008b <_panic>
f01013ef:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01013f5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013fb:	80 38 00             	cmpb   $0x0,(%eax)
f01013fe:	74 19                	je     f0101419 <mem_init+0x4a3>
f0101400:	68 75 43 10 f0       	push   $0xf0104375
f0101405:	68 e2 41 10 f0       	push   $0xf01041e2
f010140a:	68 8c 02 00 00       	push   $0x28c
f010140f:	68 bc 41 10 f0       	push   $0xf01041bc
f0101414:	e8 72 ec ff ff       	call   f010008b <_panic>
f0101419:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010141c:	39 d0                	cmp    %edx,%eax
f010141e:	75 db                	jne    f01013fb <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101420:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101423:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101428:	83 ec 0c             	sub    $0xc,%esp
f010142b:	56                   	push   %esi
f010142c:	e8 e5 f8 ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f0101431:	89 3c 24             	mov    %edi,(%esp)
f0101434:	e8 dd f8 ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f0101439:	83 c4 04             	add    $0x4,%esp
f010143c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010143f:	e8 d2 f8 ff ff       	call   f0100d16 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101444:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101449:	83 c4 10             	add    $0x10,%esp
f010144c:	eb 05                	jmp    f0101453 <mem_init+0x4dd>
		--nfree;
f010144e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101451:	8b 00                	mov    (%eax),%eax
f0101453:	85 c0                	test   %eax,%eax
f0101455:	75 f7                	jne    f010144e <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101457:	85 db                	test   %ebx,%ebx
f0101459:	74 19                	je     f0101474 <mem_init+0x4fe>
f010145b:	68 7f 43 10 f0       	push   $0xf010437f
f0101460:	68 e2 41 10 f0       	push   $0xf01041e2
f0101465:	68 99 02 00 00       	push   $0x299
f010146a:	68 bc 41 10 f0       	push   $0xf01041bc
f010146f:	e8 17 ec ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101474:	83 ec 0c             	sub    $0xc,%esp
f0101477:	68 ec 3b 10 f0       	push   $0xf0103bec
f010147c:	e8 9b 11 00 00       	call   f010261c <cprintf>
	void *va;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101481:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101488:	e8 19 f8 ff ff       	call   f0100ca6 <page_alloc>
f010148d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101490:	83 c4 10             	add    $0x10,%esp
f0101493:	85 c0                	test   %eax,%eax
f0101495:	75 19                	jne    f01014b0 <mem_init+0x53a>
f0101497:	68 8d 42 10 f0       	push   $0xf010428d
f010149c:	68 e2 41 10 f0       	push   $0xf01041e2
f01014a1:	68 f1 02 00 00       	push   $0x2f1
f01014a6:	68 bc 41 10 f0       	push   $0xf01041bc
f01014ab:	e8 db eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014b0:	83 ec 0c             	sub    $0xc,%esp
f01014b3:	6a 00                	push   $0x0
f01014b5:	e8 ec f7 ff ff       	call   f0100ca6 <page_alloc>
f01014ba:	89 c3                	mov    %eax,%ebx
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	75 19                	jne    f01014dc <mem_init+0x566>
f01014c3:	68 a3 42 10 f0       	push   $0xf01042a3
f01014c8:	68 e2 41 10 f0       	push   $0xf01041e2
f01014cd:	68 f2 02 00 00       	push   $0x2f2
f01014d2:	68 bc 41 10 f0       	push   $0xf01041bc
f01014d7:	e8 af eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01014dc:	83 ec 0c             	sub    $0xc,%esp
f01014df:	6a 00                	push   $0x0
f01014e1:	e8 c0 f7 ff ff       	call   f0100ca6 <page_alloc>
f01014e6:	89 c6                	mov    %eax,%esi
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	75 19                	jne    f0101508 <mem_init+0x592>
f01014ef:	68 b9 42 10 f0       	push   $0xf01042b9
f01014f4:	68 e2 41 10 f0       	push   $0xf01041e2
f01014f9:	68 f3 02 00 00       	push   $0x2f3
f01014fe:	68 bc 41 10 f0       	push   $0xf01041bc
f0101503:	e8 83 eb ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101508:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010150b:	75 19                	jne    f0101526 <mem_init+0x5b0>
f010150d:	68 cf 42 10 f0       	push   $0xf01042cf
f0101512:	68 e2 41 10 f0       	push   $0xf01041e2
f0101517:	68 f6 02 00 00       	push   $0x2f6
f010151c:	68 bc 41 10 f0       	push   $0xf01041bc
f0101521:	e8 65 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101526:	39 c3                	cmp    %eax,%ebx
f0101528:	74 05                	je     f010152f <mem_init+0x5b9>
f010152a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010152d:	75 19                	jne    f0101548 <mem_init+0x5d2>
f010152f:	68 cc 3b 10 f0       	push   $0xf0103bcc
f0101534:	68 e2 41 10 f0       	push   $0xf01041e2
f0101539:	68 f7 02 00 00       	push   $0x2f7
f010153e:	68 bc 41 10 f0       	push   $0xf01041bc
f0101543:	e8 43 eb ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101548:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010154d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101550:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101557:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010155a:	83 ec 0c             	sub    $0xc,%esp
f010155d:	6a 00                	push   $0x0
f010155f:	e8 42 f7 ff ff       	call   f0100ca6 <page_alloc>
f0101564:	83 c4 10             	add    $0x10,%esp
f0101567:	85 c0                	test   %eax,%eax
f0101569:	74 19                	je     f0101584 <mem_init+0x60e>
f010156b:	68 38 43 10 f0       	push   $0xf0104338
f0101570:	68 e2 41 10 f0       	push   $0xf01041e2
f0101575:	68 fe 02 00 00       	push   $0x2fe
f010157a:	68 bc 41 10 f0       	push   $0xf01041bc
f010157f:	e8 07 eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101584:	83 ec 04             	sub    $0x4,%esp
f0101587:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010158a:	50                   	push   %eax
f010158b:	6a 00                	push   $0x0
f010158d:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101593:	e8 be f8 ff ff       	call   f0100e56 <page_lookup>
f0101598:	83 c4 10             	add    $0x10,%esp
f010159b:	85 c0                	test   %eax,%eax
f010159d:	74 19                	je     f01015b8 <mem_init+0x642>
f010159f:	68 0c 3c 10 f0       	push   $0xf0103c0c
f01015a4:	68 e2 41 10 f0       	push   $0xf01041e2
f01015a9:	68 01 03 00 00       	push   $0x301
f01015ae:	68 bc 41 10 f0       	push   $0xf01041bc
f01015b3:	e8 d3 ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01015b8:	6a 02                	push   $0x2
f01015ba:	6a 00                	push   $0x0
f01015bc:	53                   	push   %ebx
f01015bd:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015c3:	e8 36 f9 ff ff       	call   f0100efe <page_insert>
f01015c8:	83 c4 10             	add    $0x10,%esp
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	78 19                	js     f01015e8 <mem_init+0x672>
f01015cf:	68 44 3c 10 f0       	push   $0xf0103c44
f01015d4:	68 e2 41 10 f0       	push   $0xf01041e2
f01015d9:	68 04 03 00 00       	push   $0x304
f01015de:	68 bc 41 10 f0       	push   $0xf01041bc
f01015e3:	e8 a3 ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01015e8:	83 ec 0c             	sub    $0xc,%esp
f01015eb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015ee:	e8 23 f7 ff ff       	call   f0100d16 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01015f3:	6a 02                	push   $0x2
f01015f5:	6a 00                	push   $0x0
f01015f7:	53                   	push   %ebx
f01015f8:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01015fe:	e8 fb f8 ff ff       	call   f0100efe <page_insert>
f0101603:	83 c4 20             	add    $0x20,%esp
f0101606:	85 c0                	test   %eax,%eax
f0101608:	74 19                	je     f0101623 <mem_init+0x6ad>
f010160a:	68 74 3c 10 f0       	push   $0xf0103c74
f010160f:	68 e2 41 10 f0       	push   $0xf01041e2
f0101614:	68 08 03 00 00       	push   $0x308
f0101619:	68 bc 41 10 f0       	push   $0xf01041bc
f010161e:	e8 68 ea ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101623:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101629:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f010162e:	89 c1                	mov    %eax,%ecx
f0101630:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101633:	8b 17                	mov    (%edi),%edx
f0101635:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010163b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010163e:	29 c8                	sub    %ecx,%eax
f0101640:	c1 f8 03             	sar    $0x3,%eax
f0101643:	c1 e0 0c             	shl    $0xc,%eax
f0101646:	39 c2                	cmp    %eax,%edx
f0101648:	74 19                	je     f0101663 <mem_init+0x6ed>
f010164a:	68 a4 3c 10 f0       	push   $0xf0103ca4
f010164f:	68 e2 41 10 f0       	push   $0xf01041e2
f0101654:	68 09 03 00 00       	push   $0x309
f0101659:	68 bc 41 10 f0       	push   $0xf01041bc
f010165e:	e8 28 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101663:	ba 00 00 00 00       	mov    $0x0,%edx
f0101668:	89 f8                	mov    %edi,%eax
f010166a:	e8 56 f2 ff ff       	call   f01008c5 <check_va2pa>
f010166f:	89 da                	mov    %ebx,%edx
f0101671:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101674:	c1 fa 03             	sar    $0x3,%edx
f0101677:	c1 e2 0c             	shl    $0xc,%edx
f010167a:	39 d0                	cmp    %edx,%eax
f010167c:	74 19                	je     f0101697 <mem_init+0x721>
f010167e:	68 cc 3c 10 f0       	push   $0xf0103ccc
f0101683:	68 e2 41 10 f0       	push   $0xf01041e2
f0101688:	68 0a 03 00 00       	push   $0x30a
f010168d:	68 bc 41 10 f0       	push   $0xf01041bc
f0101692:	e8 f4 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101697:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010169c:	74 19                	je     f01016b7 <mem_init+0x741>
f010169e:	68 8a 43 10 f0       	push   $0xf010438a
f01016a3:	68 e2 41 10 f0       	push   $0xf01041e2
f01016a8:	68 0b 03 00 00       	push   $0x30b
f01016ad:	68 bc 41 10 f0       	push   $0xf01041bc
f01016b2:	e8 d4 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01016b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016ba:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01016bf:	74 19                	je     f01016da <mem_init+0x764>
f01016c1:	68 9b 43 10 f0       	push   $0xf010439b
f01016c6:	68 e2 41 10 f0       	push   $0xf01041e2
f01016cb:	68 0c 03 00 00       	push   $0x30c
f01016d0:	68 bc 41 10 f0       	push   $0xf01041bc
f01016d5:	e8 b1 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01016da:	6a 02                	push   $0x2
f01016dc:	68 00 10 00 00       	push   $0x1000
f01016e1:	56                   	push   %esi
f01016e2:	57                   	push   %edi
f01016e3:	e8 16 f8 ff ff       	call   f0100efe <page_insert>
f01016e8:	83 c4 10             	add    $0x10,%esp
f01016eb:	85 c0                	test   %eax,%eax
f01016ed:	74 19                	je     f0101708 <mem_init+0x792>
f01016ef:	68 fc 3c 10 f0       	push   $0xf0103cfc
f01016f4:	68 e2 41 10 f0       	push   $0xf01041e2
f01016f9:	68 0f 03 00 00       	push   $0x30f
f01016fe:	68 bc 41 10 f0       	push   $0xf01041bc
f0101703:	e8 83 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101708:	ba 00 10 00 00       	mov    $0x1000,%edx
f010170d:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101712:	e8 ae f1 ff ff       	call   f01008c5 <check_va2pa>
f0101717:	89 f2                	mov    %esi,%edx
f0101719:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010171f:	c1 fa 03             	sar    $0x3,%edx
f0101722:	c1 e2 0c             	shl    $0xc,%edx
f0101725:	39 d0                	cmp    %edx,%eax
f0101727:	74 19                	je     f0101742 <mem_init+0x7cc>
f0101729:	68 38 3d 10 f0       	push   $0xf0103d38
f010172e:	68 e2 41 10 f0       	push   $0xf01041e2
f0101733:	68 10 03 00 00       	push   $0x310
f0101738:	68 bc 41 10 f0       	push   $0xf01041bc
f010173d:	e8 49 e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101742:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101747:	74 19                	je     f0101762 <mem_init+0x7ec>
f0101749:	68 ac 43 10 f0       	push   $0xf01043ac
f010174e:	68 e2 41 10 f0       	push   $0xf01041e2
f0101753:	68 11 03 00 00       	push   $0x311
f0101758:	68 bc 41 10 f0       	push   $0xf01041bc
f010175d:	e8 29 e9 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101762:	83 ec 0c             	sub    $0xc,%esp
f0101765:	6a 00                	push   $0x0
f0101767:	e8 3a f5 ff ff       	call   f0100ca6 <page_alloc>
f010176c:	83 c4 10             	add    $0x10,%esp
f010176f:	85 c0                	test   %eax,%eax
f0101771:	74 19                	je     f010178c <mem_init+0x816>
f0101773:	68 38 43 10 f0       	push   $0xf0104338
f0101778:	68 e2 41 10 f0       	push   $0xf01041e2
f010177d:	68 14 03 00 00       	push   $0x314
f0101782:	68 bc 41 10 f0       	push   $0xf01041bc
f0101787:	e8 ff e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010178c:	6a 02                	push   $0x2
f010178e:	68 00 10 00 00       	push   $0x1000
f0101793:	56                   	push   %esi
f0101794:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010179a:	e8 5f f7 ff ff       	call   f0100efe <page_insert>
f010179f:	83 c4 10             	add    $0x10,%esp
f01017a2:	85 c0                	test   %eax,%eax
f01017a4:	74 19                	je     f01017bf <mem_init+0x849>
f01017a6:	68 fc 3c 10 f0       	push   $0xf0103cfc
f01017ab:	68 e2 41 10 f0       	push   $0xf01041e2
f01017b0:	68 17 03 00 00       	push   $0x317
f01017b5:	68 bc 41 10 f0       	push   $0xf01041bc
f01017ba:	e8 cc e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017c4:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01017c9:	e8 f7 f0 ff ff       	call   f01008c5 <check_va2pa>
f01017ce:	89 f2                	mov    %esi,%edx
f01017d0:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01017d6:	c1 fa 03             	sar    $0x3,%edx
f01017d9:	c1 e2 0c             	shl    $0xc,%edx
f01017dc:	39 d0                	cmp    %edx,%eax
f01017de:	74 19                	je     f01017f9 <mem_init+0x883>
f01017e0:	68 38 3d 10 f0       	push   $0xf0103d38
f01017e5:	68 e2 41 10 f0       	push   $0xf01041e2
f01017ea:	68 18 03 00 00       	push   $0x318
f01017ef:	68 bc 41 10 f0       	push   $0xf01041bc
f01017f4:	e8 92 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017f9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017fe:	74 19                	je     f0101819 <mem_init+0x8a3>
f0101800:	68 ac 43 10 f0       	push   $0xf01043ac
f0101805:	68 e2 41 10 f0       	push   $0xf01041e2
f010180a:	68 19 03 00 00       	push   $0x319
f010180f:	68 bc 41 10 f0       	push   $0xf01041bc
f0101814:	e8 72 e8 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101819:	83 ec 0c             	sub    $0xc,%esp
f010181c:	6a 00                	push   $0x0
f010181e:	e8 83 f4 ff ff       	call   f0100ca6 <page_alloc>
f0101823:	83 c4 10             	add    $0x10,%esp
f0101826:	85 c0                	test   %eax,%eax
f0101828:	74 19                	je     f0101843 <mem_init+0x8cd>
f010182a:	68 38 43 10 f0       	push   $0xf0104338
f010182f:	68 e2 41 10 f0       	push   $0xf01041e2
f0101834:	68 1d 03 00 00       	push   $0x31d
f0101839:	68 bc 41 10 f0       	push   $0xf01041bc
f010183e:	e8 48 e8 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101843:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f0101849:	8b 02                	mov    (%edx),%eax
f010184b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101850:	89 c1                	mov    %eax,%ecx
f0101852:	c1 e9 0c             	shr    $0xc,%ecx
f0101855:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f010185b:	72 15                	jb     f0101872 <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010185d:	50                   	push   %eax
f010185e:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0101863:	68 20 03 00 00       	push   $0x320
f0101868:	68 bc 41 10 f0       	push   $0xf01041bc
f010186d:	e8 19 e8 ff ff       	call   f010008b <_panic>
f0101872:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101877:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010187a:	83 ec 04             	sub    $0x4,%esp
f010187d:	6a 00                	push   $0x0
f010187f:	68 00 10 00 00       	push   $0x1000
f0101884:	52                   	push   %edx
f0101885:	e8 f0 f4 ff ff       	call   f0100d7a <pgdir_walk>
f010188a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010188d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101890:	83 c4 10             	add    $0x10,%esp
f0101893:	39 d0                	cmp    %edx,%eax
f0101895:	74 19                	je     f01018b0 <mem_init+0x93a>
f0101897:	68 68 3d 10 f0       	push   $0xf0103d68
f010189c:	68 e2 41 10 f0       	push   $0xf01041e2
f01018a1:	68 21 03 00 00       	push   $0x321
f01018a6:	68 bc 41 10 f0       	push   $0xf01041bc
f01018ab:	e8 db e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01018b0:	6a 06                	push   $0x6
f01018b2:	68 00 10 00 00       	push   $0x1000
f01018b7:	56                   	push   %esi
f01018b8:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01018be:	e8 3b f6 ff ff       	call   f0100efe <page_insert>
f01018c3:	83 c4 10             	add    $0x10,%esp
f01018c6:	85 c0                	test   %eax,%eax
f01018c8:	74 19                	je     f01018e3 <mem_init+0x96d>
f01018ca:	68 a8 3d 10 f0       	push   $0xf0103da8
f01018cf:	68 e2 41 10 f0       	push   $0xf01041e2
f01018d4:	68 24 03 00 00       	push   $0x324
f01018d9:	68 bc 41 10 f0       	push   $0xf01041bc
f01018de:	e8 a8 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018e3:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f01018e9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018ee:	89 f8                	mov    %edi,%eax
f01018f0:	e8 d0 ef ff ff       	call   f01008c5 <check_va2pa>
f01018f5:	89 f2                	mov    %esi,%edx
f01018f7:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01018fd:	c1 fa 03             	sar    $0x3,%edx
f0101900:	c1 e2 0c             	shl    $0xc,%edx
f0101903:	39 d0                	cmp    %edx,%eax
f0101905:	74 19                	je     f0101920 <mem_init+0x9aa>
f0101907:	68 38 3d 10 f0       	push   $0xf0103d38
f010190c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101911:	68 25 03 00 00       	push   $0x325
f0101916:	68 bc 41 10 f0       	push   $0xf01041bc
f010191b:	e8 6b e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101920:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101925:	74 19                	je     f0101940 <mem_init+0x9ca>
f0101927:	68 ac 43 10 f0       	push   $0xf01043ac
f010192c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101931:	68 26 03 00 00       	push   $0x326
f0101936:	68 bc 41 10 f0       	push   $0xf01041bc
f010193b:	e8 4b e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101940:	83 ec 04             	sub    $0x4,%esp
f0101943:	6a 00                	push   $0x0
f0101945:	68 00 10 00 00       	push   $0x1000
f010194a:	57                   	push   %edi
f010194b:	e8 2a f4 ff ff       	call   f0100d7a <pgdir_walk>
f0101950:	83 c4 10             	add    $0x10,%esp
f0101953:	f6 00 04             	testb  $0x4,(%eax)
f0101956:	75 19                	jne    f0101971 <mem_init+0x9fb>
f0101958:	68 e8 3d 10 f0       	push   $0xf0103de8
f010195d:	68 e2 41 10 f0       	push   $0xf01041e2
f0101962:	68 27 03 00 00       	push   $0x327
f0101967:	68 bc 41 10 f0       	push   $0xf01041bc
f010196c:	e8 1a e7 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101971:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101976:	f6 00 04             	testb  $0x4,(%eax)
f0101979:	75 19                	jne    f0101994 <mem_init+0xa1e>
f010197b:	68 bd 43 10 f0       	push   $0xf01043bd
f0101980:	68 e2 41 10 f0       	push   $0xf01041e2
f0101985:	68 28 03 00 00       	push   $0x328
f010198a:	68 bc 41 10 f0       	push   $0xf01041bc
f010198f:	e8 f7 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101994:	6a 02                	push   $0x2
f0101996:	68 00 10 00 00       	push   $0x1000
f010199b:	56                   	push   %esi
f010199c:	50                   	push   %eax
f010199d:	e8 5c f5 ff ff       	call   f0100efe <page_insert>
f01019a2:	83 c4 10             	add    $0x10,%esp
f01019a5:	85 c0                	test   %eax,%eax
f01019a7:	74 19                	je     f01019c2 <mem_init+0xa4c>
f01019a9:	68 fc 3c 10 f0       	push   $0xf0103cfc
f01019ae:	68 e2 41 10 f0       	push   $0xf01041e2
f01019b3:	68 2b 03 00 00       	push   $0x32b
f01019b8:	68 bc 41 10 f0       	push   $0xf01041bc
f01019bd:	e8 c9 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01019c2:	83 ec 04             	sub    $0x4,%esp
f01019c5:	6a 00                	push   $0x0
f01019c7:	68 00 10 00 00       	push   $0x1000
f01019cc:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019d2:	e8 a3 f3 ff ff       	call   f0100d7a <pgdir_walk>
f01019d7:	83 c4 10             	add    $0x10,%esp
f01019da:	f6 00 02             	testb  $0x2,(%eax)
f01019dd:	75 19                	jne    f01019f8 <mem_init+0xa82>
f01019df:	68 1c 3e 10 f0       	push   $0xf0103e1c
f01019e4:	68 e2 41 10 f0       	push   $0xf01041e2
f01019e9:	68 2c 03 00 00       	push   $0x32c
f01019ee:	68 bc 41 10 f0       	push   $0xf01041bc
f01019f3:	e8 93 e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01019f8:	83 ec 04             	sub    $0x4,%esp
f01019fb:	6a 00                	push   $0x0
f01019fd:	68 00 10 00 00       	push   $0x1000
f0101a02:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a08:	e8 6d f3 ff ff       	call   f0100d7a <pgdir_walk>
f0101a0d:	83 c4 10             	add    $0x10,%esp
f0101a10:	f6 00 04             	testb  $0x4,(%eax)
f0101a13:	74 19                	je     f0101a2e <mem_init+0xab8>
f0101a15:	68 50 3e 10 f0       	push   $0xf0103e50
f0101a1a:	68 e2 41 10 f0       	push   $0xf01041e2
f0101a1f:	68 2d 03 00 00       	push   $0x32d
f0101a24:	68 bc 41 10 f0       	push   $0xf01041bc
f0101a29:	e8 5d e6 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE , PTE_W) < 0);
f0101a2e:	6a 02                	push   $0x2
f0101a30:	68 00 00 40 00       	push   $0x400000
f0101a35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a38:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a3e:	e8 bb f4 ff ff       	call   f0100efe <page_insert>
f0101a43:	83 c4 10             	add    $0x10,%esp
f0101a46:	85 c0                	test   %eax,%eax
f0101a48:	78 19                	js     f0101a63 <mem_init+0xaed>
f0101a4a:	68 88 3e 10 f0       	push   $0xf0103e88
f0101a4f:	68 e2 41 10 f0       	push   $0xf01041e2
f0101a54:	68 30 03 00 00       	push   $0x330
f0101a59:	68 bc 41 10 f0       	push   $0xf01041bc
f0101a5e:	e8 28 e6 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101a63:	6a 02                	push   $0x2
f0101a65:	68 00 10 00 00       	push   $0x1000
f0101a6a:	53                   	push   %ebx
f0101a6b:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a71:	e8 88 f4 ff ff       	call   f0100efe <page_insert>
f0101a76:	83 c4 10             	add    $0x10,%esp
f0101a79:	85 c0                	test   %eax,%eax
f0101a7b:	74 19                	je     f0101a96 <mem_init+0xb20>
f0101a7d:	68 c4 3e 10 f0       	push   $0xf0103ec4
f0101a82:	68 e2 41 10 f0       	push   $0xf01041e2
f0101a87:	68 33 03 00 00       	push   $0x333
f0101a8c:	68 bc 41 10 f0       	push   $0xf01041bc
f0101a91:	e8 f5 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a96:	83 ec 04             	sub    $0x4,%esp
f0101a99:	6a 00                	push   $0x0
f0101a9b:	68 00 10 00 00       	push   $0x1000
f0101aa0:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101aa6:	e8 cf f2 ff ff       	call   f0100d7a <pgdir_walk>
f0101aab:	83 c4 10             	add    $0x10,%esp
f0101aae:	f6 00 04             	testb  $0x4,(%eax)
f0101ab1:	74 19                	je     f0101acc <mem_init+0xb56>
f0101ab3:	68 50 3e 10 f0       	push   $0xf0103e50
f0101ab8:	68 e2 41 10 f0       	push   $0xf01041e2
f0101abd:	68 34 03 00 00       	push   $0x334
f0101ac2:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ac7:	e8 bf e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101acc:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101ad2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ad7:	89 f8                	mov    %edi,%eax
f0101ad9:	e8 e7 ed ff ff       	call   f01008c5 <check_va2pa>
f0101ade:	89 c1                	mov    %eax,%ecx
f0101ae0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ae3:	89 d8                	mov    %ebx,%eax
f0101ae5:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101aeb:	c1 f8 03             	sar    $0x3,%eax
f0101aee:	c1 e0 0c             	shl    $0xc,%eax
f0101af1:	39 c1                	cmp    %eax,%ecx
f0101af3:	74 19                	je     f0101b0e <mem_init+0xb98>
f0101af5:	68 00 3f 10 f0       	push   $0xf0103f00
f0101afa:	68 e2 41 10 f0       	push   $0xf01041e2
f0101aff:	68 37 03 00 00       	push   $0x337
f0101b04:	68 bc 41 10 f0       	push   $0xf01041bc
f0101b09:	e8 7d e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b13:	89 f8                	mov    %edi,%eax
f0101b15:	e8 ab ed ff ff       	call   f01008c5 <check_va2pa>
f0101b1a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101b1d:	74 19                	je     f0101b38 <mem_init+0xbc2>
f0101b1f:	68 2c 3f 10 f0       	push   $0xf0103f2c
f0101b24:	68 e2 41 10 f0       	push   $0xf01041e2
f0101b29:	68 38 03 00 00       	push   $0x338
f0101b2e:	68 bc 41 10 f0       	push   $0xf01041bc
f0101b33:	e8 53 e5 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101b38:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101b3d:	74 19                	je     f0101b58 <mem_init+0xbe2>
f0101b3f:	68 d3 43 10 f0       	push   $0xf01043d3
f0101b44:	68 e2 41 10 f0       	push   $0xf01041e2
f0101b49:	68 3a 03 00 00       	push   $0x33a
f0101b4e:	68 bc 41 10 f0       	push   $0xf01041bc
f0101b53:	e8 33 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b58:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101b5d:	74 19                	je     f0101b78 <mem_init+0xc02>
f0101b5f:	68 e4 43 10 f0       	push   $0xf01043e4
f0101b64:	68 e2 41 10 f0       	push   $0xf01041e2
f0101b69:	68 3b 03 00 00       	push   $0x33b
f0101b6e:	68 bc 41 10 f0       	push   $0xf01041bc
f0101b73:	e8 13 e5 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101b78:	83 ec 0c             	sub    $0xc,%esp
f0101b7b:	6a 00                	push   $0x0
f0101b7d:	e8 24 f1 ff ff       	call   f0100ca6 <page_alloc>
f0101b82:	83 c4 10             	add    $0x10,%esp
f0101b85:	39 c6                	cmp    %eax,%esi
f0101b87:	75 04                	jne    f0101b8d <mem_init+0xc17>
f0101b89:	85 c0                	test   %eax,%eax
f0101b8b:	75 19                	jne    f0101ba6 <mem_init+0xc30>
f0101b8d:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101b92:	68 e2 41 10 f0       	push   $0xf01041e2
f0101b97:	68 3e 03 00 00       	push   $0x33e
f0101b9c:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ba1:	e8 e5 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ba6:	83 ec 08             	sub    $0x8,%esp
f0101ba9:	6a 00                	push   $0x0
f0101bab:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101bb1:	e8 06 f3 ff ff       	call   f0100ebc <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101bb6:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101bbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bc1:	89 f8                	mov    %edi,%eax
f0101bc3:	e8 fd ec ff ff       	call   f01008c5 <check_va2pa>
f0101bc8:	83 c4 10             	add    $0x10,%esp
f0101bcb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101bce:	74 19                	je     f0101be9 <mem_init+0xc73>
f0101bd0:	68 80 3f 10 f0       	push   $0xf0103f80
f0101bd5:	68 e2 41 10 f0       	push   $0xf01041e2
f0101bda:	68 42 03 00 00       	push   $0x342
f0101bdf:	68 bc 41 10 f0       	push   $0xf01041bc
f0101be4:	e8 a2 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bee:	89 f8                	mov    %edi,%eax
f0101bf0:	e8 d0 ec ff ff       	call   f01008c5 <check_va2pa>
f0101bf5:	89 da                	mov    %ebx,%edx
f0101bf7:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101bfd:	c1 fa 03             	sar    $0x3,%edx
f0101c00:	c1 e2 0c             	shl    $0xc,%edx
f0101c03:	39 d0                	cmp    %edx,%eax
f0101c05:	74 19                	je     f0101c20 <mem_init+0xcaa>
f0101c07:	68 2c 3f 10 f0       	push   $0xf0103f2c
f0101c0c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101c11:	68 43 03 00 00       	push   $0x343
f0101c16:	68 bc 41 10 f0       	push   $0xf01041bc
f0101c1b:	e8 6b e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101c20:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c25:	74 19                	je     f0101c40 <mem_init+0xcca>
f0101c27:	68 8a 43 10 f0       	push   $0xf010438a
f0101c2c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101c31:	68 44 03 00 00       	push   $0x344
f0101c36:	68 bc 41 10 f0       	push   $0xf01041bc
f0101c3b:	e8 4b e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c40:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c45:	74 19                	je     f0101c60 <mem_init+0xcea>
f0101c47:	68 e4 43 10 f0       	push   $0xf01043e4
f0101c4c:	68 e2 41 10 f0       	push   $0xf01041e2
f0101c51:	68 45 03 00 00       	push   $0x345
f0101c56:	68 bc 41 10 f0       	push   $0xf01041bc
f0101c5b:	e8 2b e4 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101c60:	6a 00                	push   $0x0
f0101c62:	68 00 10 00 00       	push   $0x1000
f0101c67:	53                   	push   %ebx
f0101c68:	57                   	push   %edi
f0101c69:	e8 90 f2 ff ff       	call   f0100efe <page_insert>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	85 c0                	test   %eax,%eax
f0101c73:	74 19                	je     f0101c8e <mem_init+0xd18>
f0101c75:	68 a4 3f 10 f0       	push   $0xf0103fa4
f0101c7a:	68 e2 41 10 f0       	push   $0xf01041e2
f0101c7f:	68 48 03 00 00       	push   $0x348
f0101c84:	68 bc 41 10 f0       	push   $0xf01041bc
f0101c89:	e8 fd e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101c8e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101c93:	75 19                	jne    f0101cae <mem_init+0xd38>
f0101c95:	68 f5 43 10 f0       	push   $0xf01043f5
f0101c9a:	68 e2 41 10 f0       	push   $0xf01041e2
f0101c9f:	68 49 03 00 00       	push   $0x349
f0101ca4:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ca9:	e8 dd e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101cae:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101cb1:	74 19                	je     f0101ccc <mem_init+0xd56>
f0101cb3:	68 01 44 10 f0       	push   $0xf0104401
f0101cb8:	68 e2 41 10 f0       	push   $0xf01041e2
f0101cbd:	68 4a 03 00 00       	push   $0x34a
f0101cc2:	68 bc 41 10 f0       	push   $0xf01041bc
f0101cc7:	e8 bf e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ccc:	83 ec 08             	sub    $0x8,%esp
f0101ccf:	68 00 10 00 00       	push   $0x1000
f0101cd4:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101cda:	e8 dd f1 ff ff       	call   f0100ebc <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cdf:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101ce5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cea:	89 f8                	mov    %edi,%eax
f0101cec:	e8 d4 eb ff ff       	call   f01008c5 <check_va2pa>
f0101cf1:	83 c4 10             	add    $0x10,%esp
f0101cf4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cf7:	74 19                	je     f0101d12 <mem_init+0xd9c>
f0101cf9:	68 80 3f 10 f0       	push   $0xf0103f80
f0101cfe:	68 e2 41 10 f0       	push   $0xf01041e2
f0101d03:	68 4e 03 00 00       	push   $0x34e
f0101d08:	68 bc 41 10 f0       	push   $0xf01041bc
f0101d0d:	e8 79 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d12:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d17:	89 f8                	mov    %edi,%eax
f0101d19:	e8 a7 eb ff ff       	call   f01008c5 <check_va2pa>
f0101d1e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d21:	74 19                	je     f0101d3c <mem_init+0xdc6>
f0101d23:	68 dc 3f 10 f0       	push   $0xf0103fdc
f0101d28:	68 e2 41 10 f0       	push   $0xf01041e2
f0101d2d:	68 4f 03 00 00       	push   $0x34f
f0101d32:	68 bc 41 10 f0       	push   $0xf01041bc
f0101d37:	e8 4f e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101d3c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d41:	74 19                	je     f0101d5c <mem_init+0xde6>
f0101d43:	68 16 44 10 f0       	push   $0xf0104416
f0101d48:	68 e2 41 10 f0       	push   $0xf01041e2
f0101d4d:	68 50 03 00 00       	push   $0x350
f0101d52:	68 bc 41 10 f0       	push   $0xf01041bc
f0101d57:	e8 2f e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d5c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d61:	74 19                	je     f0101d7c <mem_init+0xe06>
f0101d63:	68 e4 43 10 f0       	push   $0xf01043e4
f0101d68:	68 e2 41 10 f0       	push   $0xf01041e2
f0101d6d:	68 51 03 00 00       	push   $0x351
f0101d72:	68 bc 41 10 f0       	push   $0xf01041bc
f0101d77:	e8 0f e3 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101d7c:	83 ec 0c             	sub    $0xc,%esp
f0101d7f:	6a 00                	push   $0x0
f0101d81:	e8 20 ef ff ff       	call   f0100ca6 <page_alloc>
f0101d86:	83 c4 10             	add    $0x10,%esp
f0101d89:	85 c0                	test   %eax,%eax
f0101d8b:	74 04                	je     f0101d91 <mem_init+0xe1b>
f0101d8d:	39 c3                	cmp    %eax,%ebx
f0101d8f:	74 19                	je     f0101daa <mem_init+0xe34>
f0101d91:	68 04 40 10 f0       	push   $0xf0104004
f0101d96:	68 e2 41 10 f0       	push   $0xf01041e2
f0101d9b:	68 54 03 00 00       	push   $0x354
f0101da0:	68 bc 41 10 f0       	push   $0xf01041bc
f0101da5:	e8 e1 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101daa:	83 ec 0c             	sub    $0xc,%esp
f0101dad:	6a 00                	push   $0x0
f0101daf:	e8 f2 ee ff ff       	call   f0100ca6 <page_alloc>
f0101db4:	83 c4 10             	add    $0x10,%esp
f0101db7:	85 c0                	test   %eax,%eax
f0101db9:	74 19                	je     f0101dd4 <mem_init+0xe5e>
f0101dbb:	68 38 43 10 f0       	push   $0xf0104338
f0101dc0:	68 e2 41 10 f0       	push   $0xf01041e2
f0101dc5:	68 57 03 00 00       	push   $0x357
f0101dca:	68 bc 41 10 f0       	push   $0xf01041bc
f0101dcf:	e8 b7 e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101dd4:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101dda:	8b 11                	mov    (%ecx),%edx
f0101ddc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101de2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de5:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101deb:	c1 f8 03             	sar    $0x3,%eax
f0101dee:	c1 e0 0c             	shl    $0xc,%eax
f0101df1:	39 c2                	cmp    %eax,%edx
f0101df3:	74 19                	je     f0101e0e <mem_init+0xe98>
f0101df5:	68 a4 3c 10 f0       	push   $0xf0103ca4
f0101dfa:	68 e2 41 10 f0       	push   $0xf01041e2
f0101dff:	68 5a 03 00 00       	push   $0x35a
f0101e04:	68 bc 41 10 f0       	push   $0xf01041bc
f0101e09:	e8 7d e2 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101e0e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e17:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e1c:	74 19                	je     f0101e37 <mem_init+0xec1>
f0101e1e:	68 9b 43 10 f0       	push   $0xf010439b
f0101e23:	68 e2 41 10 f0       	push   $0xf01041e2
f0101e28:	68 5c 03 00 00       	push   $0x35c
f0101e2d:	68 bc 41 10 f0       	push   $0xf01041bc
f0101e32:	e8 54 e2 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101e37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e3a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e40:	83 ec 0c             	sub    $0xc,%esp
f0101e43:	50                   	push   %eax
f0101e44:	e8 cd ee ff ff       	call   f0100d16 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e49:	83 c4 0c             	add    $0xc,%esp
f0101e4c:	6a 01                	push   $0x1
f0101e4e:	68 00 10 40 00       	push   $0x401000
f0101e53:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101e59:	e8 1c ef ff ff       	call   f0100d7a <pgdir_walk>
f0101e5e:	89 c7                	mov    %eax,%edi
f0101e60:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e63:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101e68:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e6b:	8b 40 04             	mov    0x4(%eax),%eax
f0101e6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e73:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101e79:	89 c2                	mov    %eax,%edx
f0101e7b:	c1 ea 0c             	shr    $0xc,%edx
f0101e7e:	83 c4 10             	add    $0x10,%esp
f0101e81:	39 ca                	cmp    %ecx,%edx
f0101e83:	72 15                	jb     f0101e9a <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e85:	50                   	push   %eax
f0101e86:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0101e8b:	68 63 03 00 00       	push   $0x363
f0101e90:	68 bc 41 10 f0       	push   $0xf01041bc
f0101e95:	e8 f1 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101e9a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101e9f:	39 c7                	cmp    %eax,%edi
f0101ea1:	74 19                	je     f0101ebc <mem_init+0xf46>
f0101ea3:	68 27 44 10 f0       	push   $0xf0104427
f0101ea8:	68 e2 41 10 f0       	push   $0xf01041e2
f0101ead:	68 64 03 00 00       	push   $0x364
f0101eb2:	68 bc 41 10 f0       	push   $0xf01041bc
f0101eb7:	e8 cf e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ebc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ebf:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ec6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ec9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ecf:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101ed5:	c1 f8 03             	sar    $0x3,%eax
f0101ed8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101edb:	89 c2                	mov    %eax,%edx
f0101edd:	c1 ea 0c             	shr    $0xc,%edx
f0101ee0:	39 d1                	cmp    %edx,%ecx
f0101ee2:	77 12                	ja     f0101ef6 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ee4:	50                   	push   %eax
f0101ee5:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0101eea:	6a 52                	push   $0x52
f0101eec:	68 c8 41 10 f0       	push   $0xf01041c8
f0101ef1:	e8 95 e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ef6:	83 ec 04             	sub    $0x4,%esp
f0101ef9:	68 00 10 00 00       	push   $0x1000
f0101efe:	68 ff 00 00 00       	push   $0xff
f0101f03:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f08:	50                   	push   %eax
f0101f09:	e8 f7 11 00 00       	call   f0103105 <memset>
	page_free(pp0);
f0101f0e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f11:	89 3c 24             	mov    %edi,(%esp)
f0101f14:	e8 fd ed ff ff       	call   f0100d16 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f19:	83 c4 0c             	add    $0xc,%esp
f0101f1c:	6a 01                	push   $0x1
f0101f1e:	6a 00                	push   $0x0
f0101f20:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101f26:	e8 4f ee ff ff       	call   f0100d7a <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f2b:	89 fa                	mov    %edi,%edx
f0101f2d:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101f33:	c1 fa 03             	sar    $0x3,%edx
f0101f36:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f39:	89 d0                	mov    %edx,%eax
f0101f3b:	c1 e8 0c             	shr    $0xc,%eax
f0101f3e:	83 c4 10             	add    $0x10,%esp
f0101f41:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0101f47:	72 12                	jb     f0101f5b <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f49:	52                   	push   %edx
f0101f4a:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0101f4f:	6a 52                	push   $0x52
f0101f51:	68 c8 41 10 f0       	push   $0xf01041c8
f0101f56:	e8 30 e1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101f5b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f61:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f64:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f6a:	f6 00 01             	testb  $0x1,(%eax)
f0101f6d:	74 19                	je     f0101f88 <mem_init+0x1012>
f0101f6f:	68 3f 44 10 f0       	push   $0xf010443f
f0101f74:	68 e2 41 10 f0       	push   $0xf01041e2
f0101f79:	68 6e 03 00 00       	push   $0x36e
f0101f7e:	68 bc 41 10 f0       	push   $0xf01041bc
f0101f83:	e8 03 e1 ff ff       	call   f010008b <_panic>
f0101f88:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101f8b:	39 d0                	cmp    %edx,%eax
f0101f8d:	75 db                	jne    f0101f6a <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101f8f:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101f94:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f9d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0101fa3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101fa6:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101fac:	83 ec 0c             	sub    $0xc,%esp
f0101faf:	50                   	push   %eax
f0101fb0:	e8 61 ed ff ff       	call   f0100d16 <page_free>
	page_free(pp1);
f0101fb5:	89 1c 24             	mov    %ebx,(%esp)
f0101fb8:	e8 59 ed ff ff       	call   f0100d16 <page_free>
	page_free(pp2);
f0101fbd:	89 34 24             	mov    %esi,(%esp)
f0101fc0:	e8 51 ed ff ff       	call   f0100d16 <page_free>

	cprintf("check_page() succeeded!\n");
f0101fc5:	c7 04 24 56 44 10 f0 	movl   $0xf0104456,(%esp)
f0101fcc:	e8 4b 06 00 00       	call   f010261c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U|PTE_P);
f0101fd1:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101fd6:	83 c4 10             	add    $0x10,%esp
f0101fd9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101fde:	77 15                	ja     f0101ff5 <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101fe0:	50                   	push   %eax
f0101fe1:	68 24 3b 10 f0       	push   $0xf0103b24
f0101fe6:	68 b0 00 00 00       	push   $0xb0
f0101feb:	68 bc 41 10 f0       	push   $0xf01041bc
f0101ff0:	e8 96 e0 ff ff       	call   f010008b <_panic>
f0101ff5:	83 ec 08             	sub    $0x8,%esp
f0101ff8:	6a 05                	push   $0x5
f0101ffa:	05 00 00 00 10       	add    $0x10000000,%eax
f0101fff:	50                   	push   %eax
f0102000:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102005:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010200a:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010200f:	e8 f9 ed ff ff       	call   f0100e0d <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102014:	83 c4 10             	add    $0x10,%esp
f0102017:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f010201c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102021:	77 15                	ja     f0102038 <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102023:	50                   	push   %eax
f0102024:	68 24 3b 10 f0       	push   $0xf0103b24
f0102029:	68 bc 00 00 00       	push   $0xbc
f010202e:	68 bc 41 10 f0       	push   $0xf01041bc
f0102033:	e8 53 e0 ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W|PTE_P);
f0102038:	83 ec 08             	sub    $0x8,%esp
f010203b:	6a 03                	push   $0x3
f010203d:	68 00 c0 10 00       	push   $0x10c000
f0102042:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102047:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010204c:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0102051:	e8 b7 ed ff ff       	call   f0100e0d <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,0xffffffff-KERNBASE,0x0,PTE_W|PTE_P);
f0102056:	83 c4 08             	add    $0x8,%esp
f0102059:	6a 03                	push   $0x3
f010205b:	6a 00                	push   $0x0
f010205d:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102062:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102067:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010206c:	e8 9c ed ff ff       	call   f0100e0d <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102071:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102077:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f010207c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010207f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102086:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010208b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010208e:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102094:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102097:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010209a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010209f:	eb 55                	jmp    f01020f6 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020a1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01020a7:	89 f0                	mov    %esi,%eax
f01020a9:	e8 17 e8 ff ff       	call   f01008c5 <check_va2pa>
f01020ae:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01020b5:	77 15                	ja     f01020cc <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020b7:	57                   	push   %edi
f01020b8:	68 24 3b 10 f0       	push   $0xf0103b24
f01020bd:	68 b1 02 00 00       	push   $0x2b1
f01020c2:	68 bc 41 10 f0       	push   $0xf01041bc
f01020c7:	e8 bf df ff ff       	call   f010008b <_panic>
f01020cc:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01020d3:	39 c2                	cmp    %eax,%edx
f01020d5:	74 19                	je     f01020f0 <mem_init+0x117a>
f01020d7:	68 28 40 10 f0       	push   $0xf0104028
f01020dc:	68 e2 41 10 f0       	push   $0xf01041e2
f01020e1:	68 b1 02 00 00       	push   $0x2b1
f01020e6:	68 bc 41 10 f0       	push   $0xf01041bc
f01020eb:	e8 9b df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020f0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01020f6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01020f9:	77 a6                	ja     f01020a1 <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01020fb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01020fe:	c1 e7 0c             	shl    $0xc,%edi
f0102101:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102106:	eb 30                	jmp    f0102138 <mem_init+0x11c2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102108:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010210e:	89 f0                	mov    %esi,%eax
f0102110:	e8 b0 e7 ff ff       	call   f01008c5 <check_va2pa>
f0102115:	39 c3                	cmp    %eax,%ebx
f0102117:	74 19                	je     f0102132 <mem_init+0x11bc>
f0102119:	68 5c 40 10 f0       	push   $0xf010405c
f010211e:	68 e2 41 10 f0       	push   $0xf01041e2
f0102123:	68 b6 02 00 00       	push   $0x2b6
f0102128:	68 bc 41 10 f0       	push   $0xf01041bc
f010212d:	e8 59 df ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102132:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102138:	39 fb                	cmp    %edi,%ebx
f010213a:	72 cc                	jb     f0102108 <mem_init+0x1192>
f010213c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102141:	89 da                	mov    %ebx,%edx
f0102143:	89 f0                	mov    %esi,%eax
f0102145:	e8 7b e7 ff ff       	call   f01008c5 <check_va2pa>
f010214a:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102150:	39 c2                	cmp    %eax,%edx
f0102152:	74 19                	je     f010216d <mem_init+0x11f7>
f0102154:	68 84 40 10 f0       	push   $0xf0104084
f0102159:	68 e2 41 10 f0       	push   $0xf01041e2
f010215e:	68 ba 02 00 00       	push   $0x2ba
f0102163:	68 bc 41 10 f0       	push   $0xf01041bc
f0102168:	e8 1e df ff ff       	call   f010008b <_panic>
f010216d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102173:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102179:	75 c6                	jne    f0102141 <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010217b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102180:	89 f0                	mov    %esi,%eax
f0102182:	e8 3e e7 ff ff       	call   f01008c5 <check_va2pa>
f0102187:	83 f8 ff             	cmp    $0xffffffff,%eax
f010218a:	74 51                	je     f01021dd <mem_init+0x1267>
f010218c:	68 cc 40 10 f0       	push   $0xf01040cc
f0102191:	68 e2 41 10 f0       	push   $0xf01041e2
f0102196:	68 bb 02 00 00       	push   $0x2bb
f010219b:	68 bc 41 10 f0       	push   $0xf01041bc
f01021a0:	e8 e6 de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01021a5:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01021aa:	72 36                	jb     f01021e2 <mem_init+0x126c>
f01021ac:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01021b1:	76 07                	jbe    f01021ba <mem_init+0x1244>
f01021b3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021b8:	75 28                	jne    f01021e2 <mem_init+0x126c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01021ba:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01021be:	0f 85 83 00 00 00    	jne    f0102247 <mem_init+0x12d1>
f01021c4:	68 6f 44 10 f0       	push   $0xf010446f
f01021c9:	68 e2 41 10 f0       	push   $0xf01041e2
f01021ce:	68 c3 02 00 00       	push   $0x2c3
f01021d3:	68 bc 41 10 f0       	push   $0xf01041bc
f01021d8:	e8 ae de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021dd:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01021e2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021e7:	76 3f                	jbe    f0102228 <mem_init+0x12b2>
				assert(pgdir[i] & PTE_P);
f01021e9:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01021ec:	f6 c2 01             	test   $0x1,%dl
f01021ef:	75 19                	jne    f010220a <mem_init+0x1294>
f01021f1:	68 6f 44 10 f0       	push   $0xf010446f
f01021f6:	68 e2 41 10 f0       	push   $0xf01041e2
f01021fb:	68 c7 02 00 00       	push   $0x2c7
f0102200:	68 bc 41 10 f0       	push   $0xf01041bc
f0102205:	e8 81 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010220a:	f6 c2 02             	test   $0x2,%dl
f010220d:	75 38                	jne    f0102247 <mem_init+0x12d1>
f010220f:	68 80 44 10 f0       	push   $0xf0104480
f0102214:	68 e2 41 10 f0       	push   $0xf01041e2
f0102219:	68 c8 02 00 00       	push   $0x2c8
f010221e:	68 bc 41 10 f0       	push   $0xf01041bc
f0102223:	e8 63 de ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102228:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010222c:	74 19                	je     f0102247 <mem_init+0x12d1>
f010222e:	68 91 44 10 f0       	push   $0xf0104491
f0102233:	68 e2 41 10 f0       	push   $0xf01041e2
f0102238:	68 ca 02 00 00       	push   $0x2ca
f010223d:	68 bc 41 10 f0       	push   $0xf01041bc
f0102242:	e8 44 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102247:	83 c0 01             	add    $0x1,%eax
f010224a:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010224f:	0f 86 50 ff ff ff    	jbe    f01021a5 <mem_init+0x122f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102255:	83 ec 0c             	sub    $0xc,%esp
f0102258:	68 fc 40 10 f0       	push   $0xf01040fc
f010225d:	e8 ba 03 00 00       	call   f010261c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102262:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102267:	83 c4 10             	add    $0x10,%esp
f010226a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010226f:	77 15                	ja     f0102286 <mem_init+0x1310>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102271:	50                   	push   %eax
f0102272:	68 24 3b 10 f0       	push   $0xf0103b24
f0102277:	68 d0 00 00 00       	push   $0xd0
f010227c:	68 bc 41 10 f0       	push   $0xf01041bc
f0102281:	e8 05 de ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102286:	05 00 00 00 10       	add    $0x10000000,%eax
f010228b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010228e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102293:	e8 91 e6 ff ff       	call   f0100929 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102298:	0f 20 c0             	mov    %cr0,%eax
f010229b:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010229e:	0d 23 00 05 80       	or     $0x80050023,%eax
f01022a3:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01022a6:	83 ec 0c             	sub    $0xc,%esp
f01022a9:	6a 00                	push   $0x0
f01022ab:	e8 f6 e9 ff ff       	call   f0100ca6 <page_alloc>
f01022b0:	89 c3                	mov    %eax,%ebx
f01022b2:	83 c4 10             	add    $0x10,%esp
f01022b5:	85 c0                	test   %eax,%eax
f01022b7:	75 19                	jne    f01022d2 <mem_init+0x135c>
f01022b9:	68 8d 42 10 f0       	push   $0xf010428d
f01022be:	68 e2 41 10 f0       	push   $0xf01041e2
f01022c3:	68 89 03 00 00       	push   $0x389
f01022c8:	68 bc 41 10 f0       	push   $0xf01041bc
f01022cd:	e8 b9 dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01022d2:	83 ec 0c             	sub    $0xc,%esp
f01022d5:	6a 00                	push   $0x0
f01022d7:	e8 ca e9 ff ff       	call   f0100ca6 <page_alloc>
f01022dc:	89 c7                	mov    %eax,%edi
f01022de:	83 c4 10             	add    $0x10,%esp
f01022e1:	85 c0                	test   %eax,%eax
f01022e3:	75 19                	jne    f01022fe <mem_init+0x1388>
f01022e5:	68 a3 42 10 f0       	push   $0xf01042a3
f01022ea:	68 e2 41 10 f0       	push   $0xf01041e2
f01022ef:	68 8a 03 00 00       	push   $0x38a
f01022f4:	68 bc 41 10 f0       	push   $0xf01041bc
f01022f9:	e8 8d dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01022fe:	83 ec 0c             	sub    $0xc,%esp
f0102301:	6a 00                	push   $0x0
f0102303:	e8 9e e9 ff ff       	call   f0100ca6 <page_alloc>
f0102308:	89 c6                	mov    %eax,%esi
f010230a:	83 c4 10             	add    $0x10,%esp
f010230d:	85 c0                	test   %eax,%eax
f010230f:	75 19                	jne    f010232a <mem_init+0x13b4>
f0102311:	68 b9 42 10 f0       	push   $0xf01042b9
f0102316:	68 e2 41 10 f0       	push   $0xf01041e2
f010231b:	68 8b 03 00 00       	push   $0x38b
f0102320:	68 bc 41 10 f0       	push   $0xf01041bc
f0102325:	e8 61 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010232a:	83 ec 0c             	sub    $0xc,%esp
f010232d:	53                   	push   %ebx
f010232e:	e8 e3 e9 ff ff       	call   f0100d16 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102333:	89 f8                	mov    %edi,%eax
f0102335:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010233b:	c1 f8 03             	sar    $0x3,%eax
f010233e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102341:	89 c2                	mov    %eax,%edx
f0102343:	c1 ea 0c             	shr    $0xc,%edx
f0102346:	83 c4 10             	add    $0x10,%esp
f0102349:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f010234f:	72 12                	jb     f0102363 <mem_init+0x13ed>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102351:	50                   	push   %eax
f0102352:	68 3c 3a 10 f0       	push   $0xf0103a3c
f0102357:	6a 52                	push   $0x52
f0102359:	68 c8 41 10 f0       	push   $0xf01041c8
f010235e:	e8 28 dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102363:	83 ec 04             	sub    $0x4,%esp
f0102366:	68 00 10 00 00       	push   $0x1000
f010236b:	6a 01                	push   $0x1
f010236d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102372:	50                   	push   %eax
f0102373:	e8 8d 0d 00 00       	call   f0103105 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102378:	89 f0                	mov    %esi,%eax
f010237a:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102380:	c1 f8 03             	sar    $0x3,%eax
f0102383:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102386:	89 c2                	mov    %eax,%edx
f0102388:	c1 ea 0c             	shr    $0xc,%edx
f010238b:	83 c4 10             	add    $0x10,%esp
f010238e:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0102394:	72 12                	jb     f01023a8 <mem_init+0x1432>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102396:	50                   	push   %eax
f0102397:	68 3c 3a 10 f0       	push   $0xf0103a3c
f010239c:	6a 52                	push   $0x52
f010239e:	68 c8 41 10 f0       	push   $0xf01041c8
f01023a3:	e8 e3 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01023a8:	83 ec 04             	sub    $0x4,%esp
f01023ab:	68 00 10 00 00       	push   $0x1000
f01023b0:	6a 02                	push   $0x2
f01023b2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023b7:	50                   	push   %eax
f01023b8:	e8 48 0d 00 00       	call   f0103105 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01023bd:	6a 02                	push   $0x2
f01023bf:	68 00 10 00 00       	push   $0x1000
f01023c4:	57                   	push   %edi
f01023c5:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01023cb:	e8 2e eb ff ff       	call   f0100efe <page_insert>
	assert(pp1->pp_ref == 1);
f01023d0:	83 c4 20             	add    $0x20,%esp
f01023d3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023d8:	74 19                	je     f01023f3 <mem_init+0x147d>
f01023da:	68 8a 43 10 f0       	push   $0xf010438a
f01023df:	68 e2 41 10 f0       	push   $0xf01041e2
f01023e4:	68 90 03 00 00       	push   $0x390
f01023e9:	68 bc 41 10 f0       	push   $0xf01041bc
f01023ee:	e8 98 dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01023f3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01023fa:	01 01 01 
f01023fd:	74 19                	je     f0102418 <mem_init+0x14a2>
f01023ff:	68 1c 41 10 f0       	push   $0xf010411c
f0102404:	68 e2 41 10 f0       	push   $0xf01041e2
f0102409:	68 91 03 00 00       	push   $0x391
f010240e:	68 bc 41 10 f0       	push   $0xf01041bc
f0102413:	e8 73 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102418:	6a 02                	push   $0x2
f010241a:	68 00 10 00 00       	push   $0x1000
f010241f:	56                   	push   %esi
f0102420:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102426:	e8 d3 ea ff ff       	call   f0100efe <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010242b:	83 c4 10             	add    $0x10,%esp
f010242e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102435:	02 02 02 
f0102438:	74 19                	je     f0102453 <mem_init+0x14dd>
f010243a:	68 40 41 10 f0       	push   $0xf0104140
f010243f:	68 e2 41 10 f0       	push   $0xf01041e2
f0102444:	68 93 03 00 00       	push   $0x393
f0102449:	68 bc 41 10 f0       	push   $0xf01041bc
f010244e:	e8 38 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102453:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102458:	74 19                	je     f0102473 <mem_init+0x14fd>
f010245a:	68 ac 43 10 f0       	push   $0xf01043ac
f010245f:	68 e2 41 10 f0       	push   $0xf01041e2
f0102464:	68 94 03 00 00       	push   $0x394
f0102469:	68 bc 41 10 f0       	push   $0xf01041bc
f010246e:	e8 18 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102473:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102478:	74 19                	je     f0102493 <mem_init+0x151d>
f010247a:	68 16 44 10 f0       	push   $0xf0104416
f010247f:	68 e2 41 10 f0       	push   $0xf01041e2
f0102484:	68 95 03 00 00       	push   $0x395
f0102489:	68 bc 41 10 f0       	push   $0xf01041bc
f010248e:	e8 f8 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102493:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010249a:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010249d:	89 f0                	mov    %esi,%eax
f010249f:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01024a5:	c1 f8 03             	sar    $0x3,%eax
f01024a8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024ab:	89 c2                	mov    %eax,%edx
f01024ad:	c1 ea 0c             	shr    $0xc,%edx
f01024b0:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01024b6:	72 12                	jb     f01024ca <mem_init+0x1554>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024b8:	50                   	push   %eax
f01024b9:	68 3c 3a 10 f0       	push   $0xf0103a3c
f01024be:	6a 52                	push   $0x52
f01024c0:	68 c8 41 10 f0       	push   $0xf01041c8
f01024c5:	e8 c1 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024ca:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01024d1:	03 03 03 
f01024d4:	74 19                	je     f01024ef <mem_init+0x1579>
f01024d6:	68 64 41 10 f0       	push   $0xf0104164
f01024db:	68 e2 41 10 f0       	push   $0xf01041e2
f01024e0:	68 97 03 00 00       	push   $0x397
f01024e5:	68 bc 41 10 f0       	push   $0xf01041bc
f01024ea:	e8 9c db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024ef:	83 ec 08             	sub    $0x8,%esp
f01024f2:	68 00 10 00 00       	push   $0x1000
f01024f7:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01024fd:	e8 ba e9 ff ff       	call   f0100ebc <page_remove>
	assert(pp2->pp_ref == 0);
f0102502:	83 c4 10             	add    $0x10,%esp
f0102505:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010250a:	74 19                	je     f0102525 <mem_init+0x15af>
f010250c:	68 e4 43 10 f0       	push   $0xf01043e4
f0102511:	68 e2 41 10 f0       	push   $0xf01041e2
f0102516:	68 99 03 00 00       	push   $0x399
f010251b:	68 bc 41 10 f0       	push   $0xf01041bc
f0102520:	e8 66 db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102525:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f010252b:	8b 11                	mov    (%ecx),%edx
f010252d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102533:	89 d8                	mov    %ebx,%eax
f0102535:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010253b:	c1 f8 03             	sar    $0x3,%eax
f010253e:	c1 e0 0c             	shl    $0xc,%eax
f0102541:	39 c2                	cmp    %eax,%edx
f0102543:	74 19                	je     f010255e <mem_init+0x15e8>
f0102545:	68 a4 3c 10 f0       	push   $0xf0103ca4
f010254a:	68 e2 41 10 f0       	push   $0xf01041e2
f010254f:	68 9c 03 00 00       	push   $0x39c
f0102554:	68 bc 41 10 f0       	push   $0xf01041bc
f0102559:	e8 2d db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010255e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102564:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102569:	74 19                	je     f0102584 <mem_init+0x160e>
f010256b:	68 9b 43 10 f0       	push   $0xf010439b
f0102570:	68 e2 41 10 f0       	push   $0xf01041e2
f0102575:	68 9e 03 00 00       	push   $0x39e
f010257a:	68 bc 41 10 f0       	push   $0xf01041bc
f010257f:	e8 07 db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102584:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010258a:	83 ec 0c             	sub    $0xc,%esp
f010258d:	53                   	push   %ebx
f010258e:	e8 83 e7 ff ff       	call   f0100d16 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102593:	c7 04 24 90 41 10 f0 	movl   $0xf0104190,(%esp)
f010259a:	e8 7d 00 00 00       	call   f010261c <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010259f:	83 c4 10             	add    $0x10,%esp
f01025a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025a5:	5b                   	pop    %ebx
f01025a6:	5e                   	pop    %esi
f01025a7:	5f                   	pop    %edi
f01025a8:	5d                   	pop    %ebp
f01025a9:	c3                   	ret    

f01025aa <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01025aa:	55                   	push   %ebp
f01025ab:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01025ad:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025b0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01025b3:	5d                   	pop    %ebp
f01025b4:	c3                   	ret    

f01025b5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01025b5:	55                   	push   %ebp
f01025b6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025b8:	ba 70 00 00 00       	mov    $0x70,%edx
f01025bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01025c0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01025c1:	ba 71 00 00 00       	mov    $0x71,%edx
f01025c6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01025c7:	0f b6 c0             	movzbl %al,%eax
}
f01025ca:	5d                   	pop    %ebp
f01025cb:	c3                   	ret    

f01025cc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01025cc:	55                   	push   %ebp
f01025cd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025cf:	ba 70 00 00 00       	mov    $0x70,%edx
f01025d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01025d7:	ee                   	out    %al,(%dx)
f01025d8:	ba 71 00 00 00       	mov    $0x71,%edx
f01025dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025e0:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01025e1:	5d                   	pop    %ebp
f01025e2:	c3                   	ret    

f01025e3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01025e3:	55                   	push   %ebp
f01025e4:	89 e5                	mov    %esp,%ebp
f01025e6:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01025e9:	ff 75 08             	pushl  0x8(%ebp)
f01025ec:	e8 0f e0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01025f1:	83 c4 10             	add    $0x10,%esp
f01025f4:	c9                   	leave  
f01025f5:	c3                   	ret    

f01025f6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01025f6:	55                   	push   %ebp
f01025f7:	89 e5                	mov    %esp,%ebp
f01025f9:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01025fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102603:	ff 75 0c             	pushl  0xc(%ebp)
f0102606:	ff 75 08             	pushl  0x8(%ebp)
f0102609:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010260c:	50                   	push   %eax
f010260d:	68 e3 25 10 f0       	push   $0xf01025e3
f0102612:	e8 c9 03 00 00       	call   f01029e0 <vprintfmt>
	return cnt;
}
f0102617:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010261a:	c9                   	leave  
f010261b:	c3                   	ret    

f010261c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010261c:	55                   	push   %ebp
f010261d:	89 e5                	mov    %esp,%ebp
f010261f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102622:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102625:	50                   	push   %eax
f0102626:	ff 75 08             	pushl  0x8(%ebp)
f0102629:	e8 c8 ff ff ff       	call   f01025f6 <vcprintf>
	va_end(ap);

	return cnt;
}
f010262e:	c9                   	leave  
f010262f:	c3                   	ret    

f0102630 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102630:	55                   	push   %ebp
f0102631:	89 e5                	mov    %esp,%ebp
f0102633:	57                   	push   %edi
f0102634:	56                   	push   %esi
f0102635:	53                   	push   %ebx
f0102636:	83 ec 14             	sub    $0x14,%esp
f0102639:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010263c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010263f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102642:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102645:	8b 1a                	mov    (%edx),%ebx
f0102647:	8b 01                	mov    (%ecx),%eax
f0102649:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010264c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102653:	eb 7f                	jmp    f01026d4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102655:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102658:	01 d8                	add    %ebx,%eax
f010265a:	89 c6                	mov    %eax,%esi
f010265c:	c1 ee 1f             	shr    $0x1f,%esi
f010265f:	01 c6                	add    %eax,%esi
f0102661:	d1 fe                	sar    %esi
f0102663:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102666:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102669:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010266c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010266e:	eb 03                	jmp    f0102673 <stab_binsearch+0x43>
			m--;
f0102670:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102673:	39 c3                	cmp    %eax,%ebx
f0102675:	7f 0d                	jg     f0102684 <stab_binsearch+0x54>
f0102677:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010267b:	83 ea 0c             	sub    $0xc,%edx
f010267e:	39 f9                	cmp    %edi,%ecx
f0102680:	75 ee                	jne    f0102670 <stab_binsearch+0x40>
f0102682:	eb 05                	jmp    f0102689 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102684:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102687:	eb 4b                	jmp    f01026d4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102689:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010268c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010268f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102693:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102696:	76 11                	jbe    f01026a9 <stab_binsearch+0x79>
			*region_left = m;
f0102698:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010269b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010269d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026a7:	eb 2b                	jmp    f01026d4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01026a9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026ac:	73 14                	jae    f01026c2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01026ae:	83 e8 01             	sub    $0x1,%eax
f01026b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026b4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026b7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026c0:	eb 12                	jmp    f01026d4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01026c2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026c5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026c7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026cb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026cd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01026d4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01026d7:	0f 8e 78 ff ff ff    	jle    f0102655 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01026dd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01026e1:	75 0f                	jne    f01026f2 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01026e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01026e6:	8b 00                	mov    (%eax),%eax
f01026e8:	83 e8 01             	sub    $0x1,%eax
f01026eb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026ee:	89 06                	mov    %eax,(%esi)
f01026f0:	eb 2c                	jmp    f010271e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01026f5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01026f7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026fa:	8b 0e                	mov    (%esi),%ecx
f01026fc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026ff:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102702:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102705:	eb 03                	jmp    f010270a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102707:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010270a:	39 c8                	cmp    %ecx,%eax
f010270c:	7e 0b                	jle    f0102719 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010270e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102712:	83 ea 0c             	sub    $0xc,%edx
f0102715:	39 df                	cmp    %ebx,%edi
f0102717:	75 ee                	jne    f0102707 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102719:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010271c:	89 06                	mov    %eax,(%esi)
	}
}
f010271e:	83 c4 14             	add    $0x14,%esp
f0102721:	5b                   	pop    %ebx
f0102722:	5e                   	pop    %esi
f0102723:	5f                   	pop    %edi
f0102724:	5d                   	pop    %ebp
f0102725:	c3                   	ret    

f0102726 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102726:	55                   	push   %ebp
f0102727:	89 e5                	mov    %esp,%ebp
f0102729:	57                   	push   %edi
f010272a:	56                   	push   %esi
f010272b:	53                   	push   %ebx
f010272c:	83 ec 1c             	sub    $0x1c,%esp
f010272f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102732:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102735:	c7 06 9f 44 10 f0    	movl   $0xf010449f,(%esi)
	info->eip_line = 0;
f010273b:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0102742:	c7 46 08 9f 44 10 f0 	movl   $0xf010449f,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102749:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0102750:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102753:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010275a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0102760:	76 11                	jbe    f0102773 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102762:	b8 47 bc 10 f0       	mov    $0xf010bc47,%eax
f0102767:	3d dd 9e 10 f0       	cmp    $0xf0109edd,%eax
f010276c:	77 19                	ja     f0102787 <debuginfo_eip+0x61>
f010276e:	e9 62 01 00 00       	jmp    f01028d5 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102773:	83 ec 04             	sub    $0x4,%esp
f0102776:	68 a9 44 10 f0       	push   $0xf01044a9
f010277b:	6a 7f                	push   $0x7f
f010277d:	68 b6 44 10 f0       	push   $0xf01044b6
f0102782:	e8 04 d9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102787:	80 3d 46 bc 10 f0 00 	cmpb   $0x0,0xf010bc46
f010278e:	0f 85 48 01 00 00    	jne    f01028dc <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102794:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010279b:	b8 dc 9e 10 f0       	mov    $0xf0109edc,%eax
f01027a0:	2d d4 46 10 f0       	sub    $0xf01046d4,%eax
f01027a5:	c1 f8 02             	sar    $0x2,%eax
f01027a8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01027ae:	83 e8 01             	sub    $0x1,%eax
f01027b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01027b4:	83 ec 08             	sub    $0x8,%esp
f01027b7:	57                   	push   %edi
f01027b8:	6a 64                	push   $0x64
f01027ba:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01027bd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01027c0:	b8 d4 46 10 f0       	mov    $0xf01046d4,%eax
f01027c5:	e8 66 fe ff ff       	call   f0102630 <stab_binsearch>
	if (lfile == 0)
f01027ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027cd:	83 c4 10             	add    $0x10,%esp
f01027d0:	85 c0                	test   %eax,%eax
f01027d2:	0f 84 0b 01 00 00    	je     f01028e3 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01027d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01027db:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027de:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01027e1:	83 ec 08             	sub    $0x8,%esp
f01027e4:	57                   	push   %edi
f01027e5:	6a 24                	push   $0x24
f01027e7:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01027ea:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01027ed:	b8 d4 46 10 f0       	mov    $0xf01046d4,%eax
f01027f2:	e8 39 fe ff ff       	call   f0102630 <stab_binsearch>

	if (lfun <= rfun) {
f01027f7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01027fa:	83 c4 10             	add    $0x10,%esp
f01027fd:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0102800:	7f 31                	jg     f0102833 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102802:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102805:	c1 e0 02             	shl    $0x2,%eax
f0102808:	8d 90 d4 46 10 f0    	lea    -0xfefb92c(%eax),%edx
f010280e:	8b 88 d4 46 10 f0    	mov    -0xfefb92c(%eax),%ecx
f0102814:	b8 47 bc 10 f0       	mov    $0xf010bc47,%eax
f0102819:	2d dd 9e 10 f0       	sub    $0xf0109edd,%eax
f010281e:	39 c1                	cmp    %eax,%ecx
f0102820:	73 09                	jae    f010282b <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102822:	81 c1 dd 9e 10 f0    	add    $0xf0109edd,%ecx
f0102828:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010282b:	8b 42 08             	mov    0x8(%edx),%eax
f010282e:	89 46 10             	mov    %eax,0x10(%esi)
f0102831:	eb 06                	jmp    f0102839 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102833:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102836:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102839:	83 ec 08             	sub    $0x8,%esp
f010283c:	6a 3a                	push   $0x3a
f010283e:	ff 76 08             	pushl  0x8(%esi)
f0102841:	e8 a3 08 00 00       	call   f01030e9 <strfind>
f0102846:	2b 46 08             	sub    0x8(%esi),%eax
f0102849:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010284c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010284f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102852:	8d 04 85 d4 46 10 f0 	lea    -0xfefb92c(,%eax,4),%eax
f0102859:	83 c4 10             	add    $0x10,%esp
f010285c:	eb 06                	jmp    f0102864 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010285e:	83 eb 01             	sub    $0x1,%ebx
f0102861:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102864:	39 fb                	cmp    %edi,%ebx
f0102866:	7c 34                	jl     f010289c <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0102868:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010286c:	80 fa 84             	cmp    $0x84,%dl
f010286f:	74 0b                	je     f010287c <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102871:	80 fa 64             	cmp    $0x64,%dl
f0102874:	75 e8                	jne    f010285e <debuginfo_eip+0x138>
f0102876:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010287a:	74 e2                	je     f010285e <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010287c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010287f:	8b 14 85 d4 46 10 f0 	mov    -0xfefb92c(,%eax,4),%edx
f0102886:	b8 47 bc 10 f0       	mov    $0xf010bc47,%eax
f010288b:	2d dd 9e 10 f0       	sub    $0xf0109edd,%eax
f0102890:	39 c2                	cmp    %eax,%edx
f0102892:	73 08                	jae    f010289c <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102894:	81 c2 dd 9e 10 f0    	add    $0xf0109edd,%edx
f010289a:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010289c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010289f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028a2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028a7:	39 cb                	cmp    %ecx,%ebx
f01028a9:	7d 44                	jge    f01028ef <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f01028ab:	8d 53 01             	lea    0x1(%ebx),%edx
f01028ae:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028b1:	8d 04 85 d4 46 10 f0 	lea    -0xfefb92c(,%eax,4),%eax
f01028b8:	eb 07                	jmp    f01028c1 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01028ba:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01028be:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01028c1:	39 ca                	cmp    %ecx,%edx
f01028c3:	74 25                	je     f01028ea <debuginfo_eip+0x1c4>
f01028c5:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01028c8:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01028cc:	74 ec                	je     f01028ba <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d3:	eb 1a                	jmp    f01028ef <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01028d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01028da:	eb 13                	jmp    f01028ef <debuginfo_eip+0x1c9>
f01028dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01028e1:	eb 0c                	jmp    f01028ef <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01028e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01028e8:	eb 05                	jmp    f01028ef <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028f2:	5b                   	pop    %ebx
f01028f3:	5e                   	pop    %esi
f01028f4:	5f                   	pop    %edi
f01028f5:	5d                   	pop    %ebp
f01028f6:	c3                   	ret    

f01028f7 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01028f7:	55                   	push   %ebp
f01028f8:	89 e5                	mov    %esp,%ebp
f01028fa:	57                   	push   %edi
f01028fb:	56                   	push   %esi
f01028fc:	53                   	push   %ebx
f01028fd:	83 ec 1c             	sub    $0x1c,%esp
f0102900:	89 c7                	mov    %eax,%edi
f0102902:	89 d6                	mov    %edx,%esi
f0102904:	8b 45 08             	mov    0x8(%ebp),%eax
f0102907:	8b 55 0c             	mov    0xc(%ebp),%edx
f010290a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010290d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102910:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102913:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102918:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010291b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010291e:	39 d3                	cmp    %edx,%ebx
f0102920:	72 05                	jb     f0102927 <printnum+0x30>
f0102922:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102925:	77 45                	ja     f010296c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102927:	83 ec 0c             	sub    $0xc,%esp
f010292a:	ff 75 18             	pushl  0x18(%ebp)
f010292d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102930:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102933:	53                   	push   %ebx
f0102934:	ff 75 10             	pushl  0x10(%ebp)
f0102937:	83 ec 08             	sub    $0x8,%esp
f010293a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010293d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102940:	ff 75 dc             	pushl  -0x24(%ebp)
f0102943:	ff 75 d8             	pushl  -0x28(%ebp)
f0102946:	e8 c5 09 00 00       	call   f0103310 <__udivdi3>
f010294b:	83 c4 18             	add    $0x18,%esp
f010294e:	52                   	push   %edx
f010294f:	50                   	push   %eax
f0102950:	89 f2                	mov    %esi,%edx
f0102952:	89 f8                	mov    %edi,%eax
f0102954:	e8 9e ff ff ff       	call   f01028f7 <printnum>
f0102959:	83 c4 20             	add    $0x20,%esp
f010295c:	eb 18                	jmp    f0102976 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010295e:	83 ec 08             	sub    $0x8,%esp
f0102961:	56                   	push   %esi
f0102962:	ff 75 18             	pushl  0x18(%ebp)
f0102965:	ff d7                	call   *%edi
f0102967:	83 c4 10             	add    $0x10,%esp
f010296a:	eb 03                	jmp    f010296f <printnum+0x78>
f010296c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010296f:	83 eb 01             	sub    $0x1,%ebx
f0102972:	85 db                	test   %ebx,%ebx
f0102974:	7f e8                	jg     f010295e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102976:	83 ec 08             	sub    $0x8,%esp
f0102979:	56                   	push   %esi
f010297a:	83 ec 04             	sub    $0x4,%esp
f010297d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102980:	ff 75 e0             	pushl  -0x20(%ebp)
f0102983:	ff 75 dc             	pushl  -0x24(%ebp)
f0102986:	ff 75 d8             	pushl  -0x28(%ebp)
f0102989:	e8 b2 0a 00 00       	call   f0103440 <__umoddi3>
f010298e:	83 c4 14             	add    $0x14,%esp
f0102991:	0f be 80 c4 44 10 f0 	movsbl -0xfefbb3c(%eax),%eax
f0102998:	50                   	push   %eax
f0102999:	ff d7                	call   *%edi
}
f010299b:	83 c4 10             	add    $0x10,%esp
f010299e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029a1:	5b                   	pop    %ebx
f01029a2:	5e                   	pop    %esi
f01029a3:	5f                   	pop    %edi
f01029a4:	5d                   	pop    %ebp
f01029a5:	c3                   	ret    

f01029a6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01029a6:	55                   	push   %ebp
f01029a7:	89 e5                	mov    %esp,%ebp
f01029a9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01029ac:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01029b0:	8b 10                	mov    (%eax),%edx
f01029b2:	3b 50 04             	cmp    0x4(%eax),%edx
f01029b5:	73 0a                	jae    f01029c1 <sprintputch+0x1b>
		*b->buf++ = ch;
f01029b7:	8d 4a 01             	lea    0x1(%edx),%ecx
f01029ba:	89 08                	mov    %ecx,(%eax)
f01029bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01029bf:	88 02                	mov    %al,(%edx)
}
f01029c1:	5d                   	pop    %ebp
f01029c2:	c3                   	ret    

f01029c3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01029c3:	55                   	push   %ebp
f01029c4:	89 e5                	mov    %esp,%ebp
f01029c6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01029c9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01029cc:	50                   	push   %eax
f01029cd:	ff 75 10             	pushl  0x10(%ebp)
f01029d0:	ff 75 0c             	pushl  0xc(%ebp)
f01029d3:	ff 75 08             	pushl  0x8(%ebp)
f01029d6:	e8 05 00 00 00       	call   f01029e0 <vprintfmt>
	va_end(ap);
}
f01029db:	83 c4 10             	add    $0x10,%esp
f01029de:	c9                   	leave  
f01029df:	c3                   	ret    

f01029e0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01029e0:	55                   	push   %ebp
f01029e1:	89 e5                	mov    %esp,%ebp
f01029e3:	57                   	push   %edi
f01029e4:	56                   	push   %esi
f01029e5:	53                   	push   %ebx
f01029e6:	83 ec 2c             	sub    $0x2c,%esp
f01029e9:	8b 75 08             	mov    0x8(%ebp),%esi
f01029ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01029ef:	8b 7d 10             	mov    0x10(%ebp),%edi
f01029f2:	eb 12                	jmp    f0102a06 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01029f4:	85 c0                	test   %eax,%eax
f01029f6:	0f 84 42 04 00 00    	je     f0102e3e <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f01029fc:	83 ec 08             	sub    $0x8,%esp
f01029ff:	53                   	push   %ebx
f0102a00:	50                   	push   %eax
f0102a01:	ff d6                	call   *%esi
f0102a03:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102a06:	83 c7 01             	add    $0x1,%edi
f0102a09:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102a0d:	83 f8 25             	cmp    $0x25,%eax
f0102a10:	75 e2                	jne    f01029f4 <vprintfmt+0x14>
f0102a12:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102a16:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102a1d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102a24:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102a2b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102a30:	eb 07                	jmp    f0102a39 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a32:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102a35:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a39:	8d 47 01             	lea    0x1(%edi),%eax
f0102a3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a3f:	0f b6 07             	movzbl (%edi),%eax
f0102a42:	0f b6 d0             	movzbl %al,%edx
f0102a45:	83 e8 23             	sub    $0x23,%eax
f0102a48:	3c 55                	cmp    $0x55,%al
f0102a4a:	0f 87 d3 03 00 00    	ja     f0102e23 <vprintfmt+0x443>
f0102a50:	0f b6 c0             	movzbl %al,%eax
f0102a53:	ff 24 85 50 45 10 f0 	jmp    *-0xfefbab0(,%eax,4)
f0102a5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102a5d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102a61:	eb d6                	jmp    f0102a39 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a66:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a6b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102a6e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102a71:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0102a75:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102a78:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102a7b:	83 f9 09             	cmp    $0x9,%ecx
f0102a7e:	77 3f                	ja     f0102abf <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102a80:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102a83:	eb e9                	jmp    f0102a6e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102a85:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a88:	8b 00                	mov    (%eax),%eax
f0102a8a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102a8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a90:	8d 40 04             	lea    0x4(%eax),%eax
f0102a93:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102a96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102a99:	eb 2a                	jmp    f0102ac5 <vprintfmt+0xe5>
f0102a9b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a9e:	85 c0                	test   %eax,%eax
f0102aa0:	ba 00 00 00 00       	mov    $0x0,%edx
f0102aa5:	0f 49 d0             	cmovns %eax,%edx
f0102aa8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102aab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102aae:	eb 89                	jmp    f0102a39 <vprintfmt+0x59>
f0102ab0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102ab3:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102aba:	e9 7a ff ff ff       	jmp    f0102a39 <vprintfmt+0x59>
f0102abf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ac2:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102ac5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ac9:	0f 89 6a ff ff ff    	jns    f0102a39 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102acf:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ad2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ad5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102adc:	e9 58 ff ff ff       	jmp    f0102a39 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102ae1:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ae4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102ae7:	e9 4d ff ff ff       	jmp    f0102a39 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102aec:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aef:	8d 78 04             	lea    0x4(%eax),%edi
f0102af2:	83 ec 08             	sub    $0x8,%esp
f0102af5:	53                   	push   %ebx
f0102af6:	ff 30                	pushl  (%eax)
f0102af8:	ff d6                	call   *%esi
			break;
f0102afa:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102afd:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102b03:	e9 fe fe ff ff       	jmp    f0102a06 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b08:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b0b:	8d 78 04             	lea    0x4(%eax),%edi
f0102b0e:	8b 00                	mov    (%eax),%eax
f0102b10:	99                   	cltd   
f0102b11:	31 d0                	xor    %edx,%eax
f0102b13:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102b15:	83 f8 06             	cmp    $0x6,%eax
f0102b18:	7f 0b                	jg     f0102b25 <vprintfmt+0x145>
f0102b1a:	8b 14 85 a8 46 10 f0 	mov    -0xfefb958(,%eax,4),%edx
f0102b21:	85 d2                	test   %edx,%edx
f0102b23:	75 1b                	jne    f0102b40 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0102b25:	50                   	push   %eax
f0102b26:	68 dc 44 10 f0       	push   $0xf01044dc
f0102b2b:	53                   	push   %ebx
f0102b2c:	56                   	push   %esi
f0102b2d:	e8 91 fe ff ff       	call   f01029c3 <printfmt>
f0102b32:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b35:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102b3b:	e9 c6 fe ff ff       	jmp    f0102a06 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102b40:	52                   	push   %edx
f0102b41:	68 f4 41 10 f0       	push   $0xf01041f4
f0102b46:	53                   	push   %ebx
f0102b47:	56                   	push   %esi
f0102b48:	e8 76 fe ff ff       	call   f01029c3 <printfmt>
f0102b4d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b50:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b56:	e9 ab fe ff ff       	jmp    f0102a06 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102b5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b5e:	83 c0 04             	add    $0x4,%eax
f0102b61:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102b64:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b67:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102b69:	85 ff                	test   %edi,%edi
f0102b6b:	b8 d5 44 10 f0       	mov    $0xf01044d5,%eax
f0102b70:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102b73:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b77:	0f 8e 94 00 00 00    	jle    f0102c11 <vprintfmt+0x231>
f0102b7d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102b81:	0f 84 98 00 00 00    	je     f0102c1f <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102b87:	83 ec 08             	sub    $0x8,%esp
f0102b8a:	ff 75 d0             	pushl  -0x30(%ebp)
f0102b8d:	57                   	push   %edi
f0102b8e:	e8 0c 04 00 00       	call   f0102f9f <strnlen>
f0102b93:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102b96:	29 c1                	sub    %eax,%ecx
f0102b98:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102b9b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102b9e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102ba2:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ba5:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ba8:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102baa:	eb 0f                	jmp    f0102bbb <vprintfmt+0x1db>
					putch(padc, putdat);
f0102bac:	83 ec 08             	sub    $0x8,%esp
f0102baf:	53                   	push   %ebx
f0102bb0:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bb3:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102bb5:	83 ef 01             	sub    $0x1,%edi
f0102bb8:	83 c4 10             	add    $0x10,%esp
f0102bbb:	85 ff                	test   %edi,%edi
f0102bbd:	7f ed                	jg     f0102bac <vprintfmt+0x1cc>
f0102bbf:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102bc2:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102bc5:	85 c9                	test   %ecx,%ecx
f0102bc7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bcc:	0f 49 c1             	cmovns %ecx,%eax
f0102bcf:	29 c1                	sub    %eax,%ecx
f0102bd1:	89 75 08             	mov    %esi,0x8(%ebp)
f0102bd4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102bd7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102bda:	89 cb                	mov    %ecx,%ebx
f0102bdc:	eb 4d                	jmp    f0102c2b <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102bde:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102be2:	74 1b                	je     f0102bff <vprintfmt+0x21f>
f0102be4:	0f be c0             	movsbl %al,%eax
f0102be7:	83 e8 20             	sub    $0x20,%eax
f0102bea:	83 f8 5e             	cmp    $0x5e,%eax
f0102bed:	76 10                	jbe    f0102bff <vprintfmt+0x21f>
					putch('?', putdat);
f0102bef:	83 ec 08             	sub    $0x8,%esp
f0102bf2:	ff 75 0c             	pushl  0xc(%ebp)
f0102bf5:	6a 3f                	push   $0x3f
f0102bf7:	ff 55 08             	call   *0x8(%ebp)
f0102bfa:	83 c4 10             	add    $0x10,%esp
f0102bfd:	eb 0d                	jmp    f0102c0c <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0102bff:	83 ec 08             	sub    $0x8,%esp
f0102c02:	ff 75 0c             	pushl  0xc(%ebp)
f0102c05:	52                   	push   %edx
f0102c06:	ff 55 08             	call   *0x8(%ebp)
f0102c09:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c0c:	83 eb 01             	sub    $0x1,%ebx
f0102c0f:	eb 1a                	jmp    f0102c2b <vprintfmt+0x24b>
f0102c11:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c14:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c17:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c1a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c1d:	eb 0c                	jmp    f0102c2b <vprintfmt+0x24b>
f0102c1f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c22:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c25:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c28:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102c2b:	83 c7 01             	add    $0x1,%edi
f0102c2e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c32:	0f be d0             	movsbl %al,%edx
f0102c35:	85 d2                	test   %edx,%edx
f0102c37:	74 23                	je     f0102c5c <vprintfmt+0x27c>
f0102c39:	85 f6                	test   %esi,%esi
f0102c3b:	78 a1                	js     f0102bde <vprintfmt+0x1fe>
f0102c3d:	83 ee 01             	sub    $0x1,%esi
f0102c40:	79 9c                	jns    f0102bde <vprintfmt+0x1fe>
f0102c42:	89 df                	mov    %ebx,%edi
f0102c44:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c47:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c4a:	eb 18                	jmp    f0102c64 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102c4c:	83 ec 08             	sub    $0x8,%esp
f0102c4f:	53                   	push   %ebx
f0102c50:	6a 20                	push   $0x20
f0102c52:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102c54:	83 ef 01             	sub    $0x1,%edi
f0102c57:	83 c4 10             	add    $0x10,%esp
f0102c5a:	eb 08                	jmp    f0102c64 <vprintfmt+0x284>
f0102c5c:	89 df                	mov    %ebx,%edi
f0102c5e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c61:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c64:	85 ff                	test   %edi,%edi
f0102c66:	7f e4                	jg     f0102c4c <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c68:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102c6b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c71:	e9 90 fd ff ff       	jmp    f0102a06 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102c76:	83 f9 01             	cmp    $0x1,%ecx
f0102c79:	7e 19                	jle    f0102c94 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0102c7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7e:	8b 50 04             	mov    0x4(%eax),%edx
f0102c81:	8b 00                	mov    (%eax),%eax
f0102c83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c86:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102c89:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c8c:	8d 40 08             	lea    0x8(%eax),%eax
f0102c8f:	89 45 14             	mov    %eax,0x14(%ebp)
f0102c92:	eb 38                	jmp    f0102ccc <vprintfmt+0x2ec>
	else if (lflag)
f0102c94:	85 c9                	test   %ecx,%ecx
f0102c96:	74 1b                	je     f0102cb3 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0102c98:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c9b:	8b 00                	mov    (%eax),%eax
f0102c9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ca0:	89 c1                	mov    %eax,%ecx
f0102ca2:	c1 f9 1f             	sar    $0x1f,%ecx
f0102ca5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102ca8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cab:	8d 40 04             	lea    0x4(%eax),%eax
f0102cae:	89 45 14             	mov    %eax,0x14(%ebp)
f0102cb1:	eb 19                	jmp    f0102ccc <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0102cb3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb6:	8b 00                	mov    (%eax),%eax
f0102cb8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cbb:	89 c1                	mov    %eax,%ecx
f0102cbd:	c1 f9 1f             	sar    $0x1f,%ecx
f0102cc0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102cc3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc6:	8d 40 04             	lea    0x4(%eax),%eax
f0102cc9:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102ccc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ccf:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102cd2:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102cd7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102cdb:	0f 89 0e 01 00 00    	jns    f0102def <vprintfmt+0x40f>
				putch('-', putdat);
f0102ce1:	83 ec 08             	sub    $0x8,%esp
f0102ce4:	53                   	push   %ebx
f0102ce5:	6a 2d                	push   $0x2d
f0102ce7:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ce9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102cec:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102cef:	f7 da                	neg    %edx
f0102cf1:	83 d1 00             	adc    $0x0,%ecx
f0102cf4:	f7 d9                	neg    %ecx
f0102cf6:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102cf9:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102cfe:	e9 ec 00 00 00       	jmp    f0102def <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d03:	83 f9 01             	cmp    $0x1,%ecx
f0102d06:	7e 18                	jle    f0102d20 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0102d08:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0b:	8b 10                	mov    (%eax),%edx
f0102d0d:	8b 48 04             	mov    0x4(%eax),%ecx
f0102d10:	8d 40 08             	lea    0x8(%eax),%eax
f0102d13:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d16:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d1b:	e9 cf 00 00 00       	jmp    f0102def <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102d20:	85 c9                	test   %ecx,%ecx
f0102d22:	74 1a                	je     f0102d3e <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0102d24:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d27:	8b 10                	mov    (%eax),%edx
f0102d29:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d2e:	8d 40 04             	lea    0x4(%eax),%eax
f0102d31:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d34:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d39:	e9 b1 00 00 00       	jmp    f0102def <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102d3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d41:	8b 10                	mov    (%eax),%edx
f0102d43:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d48:	8d 40 04             	lea    0x4(%eax),%eax
f0102d4b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102d4e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102d53:	e9 97 00 00 00       	jmp    f0102def <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102d58:	83 ec 08             	sub    $0x8,%esp
f0102d5b:	53                   	push   %ebx
f0102d5c:	6a 58                	push   $0x58
f0102d5e:	ff d6                	call   *%esi
			putch('X', putdat);
f0102d60:	83 c4 08             	add    $0x8,%esp
f0102d63:	53                   	push   %ebx
f0102d64:	6a 58                	push   $0x58
f0102d66:	ff d6                	call   *%esi
			putch('X', putdat);
f0102d68:	83 c4 08             	add    $0x8,%esp
f0102d6b:	53                   	push   %ebx
f0102d6c:	6a 58                	push   $0x58
f0102d6e:	ff d6                	call   *%esi
			break;
f0102d70:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0102d76:	e9 8b fc ff ff       	jmp    f0102a06 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102d7b:	83 ec 08             	sub    $0x8,%esp
f0102d7e:	53                   	push   %ebx
f0102d7f:	6a 30                	push   $0x30
f0102d81:	ff d6                	call   *%esi
			putch('x', putdat);
f0102d83:	83 c4 08             	add    $0x8,%esp
f0102d86:	53                   	push   %ebx
f0102d87:	6a 78                	push   $0x78
f0102d89:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102d8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d8e:	8b 10                	mov    (%eax),%edx
f0102d90:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102d95:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102d98:	8d 40 04             	lea    0x4(%eax),%eax
f0102d9b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102d9e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102da3:	eb 4a                	jmp    f0102def <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102da5:	83 f9 01             	cmp    $0x1,%ecx
f0102da8:	7e 15                	jle    f0102dbf <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0102daa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dad:	8b 10                	mov    (%eax),%edx
f0102daf:	8b 48 04             	mov    0x4(%eax),%ecx
f0102db2:	8d 40 08             	lea    0x8(%eax),%eax
f0102db5:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102db8:	b8 10 00 00 00       	mov    $0x10,%eax
f0102dbd:	eb 30                	jmp    f0102def <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102dbf:	85 c9                	test   %ecx,%ecx
f0102dc1:	74 17                	je     f0102dda <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0102dc3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc6:	8b 10                	mov    (%eax),%edx
f0102dc8:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102dcd:	8d 40 04             	lea    0x4(%eax),%eax
f0102dd0:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102dd3:	b8 10 00 00 00       	mov    $0x10,%eax
f0102dd8:	eb 15                	jmp    f0102def <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102dda:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ddd:	8b 10                	mov    (%eax),%edx
f0102ddf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102de4:	8d 40 04             	lea    0x4(%eax),%eax
f0102de7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0102dea:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102def:	83 ec 0c             	sub    $0xc,%esp
f0102df2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102df6:	57                   	push   %edi
f0102df7:	ff 75 e0             	pushl  -0x20(%ebp)
f0102dfa:	50                   	push   %eax
f0102dfb:	51                   	push   %ecx
f0102dfc:	52                   	push   %edx
f0102dfd:	89 da                	mov    %ebx,%edx
f0102dff:	89 f0                	mov    %esi,%eax
f0102e01:	e8 f1 fa ff ff       	call   f01028f7 <printnum>
			break;
f0102e06:	83 c4 20             	add    $0x20,%esp
f0102e09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e0c:	e9 f5 fb ff ff       	jmp    f0102a06 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e11:	83 ec 08             	sub    $0x8,%esp
f0102e14:	53                   	push   %ebx
f0102e15:	52                   	push   %edx
f0102e16:	ff d6                	call   *%esi
			break;
f0102e18:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e1e:	e9 e3 fb ff ff       	jmp    f0102a06 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e23:	83 ec 08             	sub    $0x8,%esp
f0102e26:	53                   	push   %ebx
f0102e27:	6a 25                	push   $0x25
f0102e29:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e2b:	83 c4 10             	add    $0x10,%esp
f0102e2e:	eb 03                	jmp    f0102e33 <vprintfmt+0x453>
f0102e30:	83 ef 01             	sub    $0x1,%edi
f0102e33:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e37:	75 f7                	jne    f0102e30 <vprintfmt+0x450>
f0102e39:	e9 c8 fb ff ff       	jmp    f0102a06 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e41:	5b                   	pop    %ebx
f0102e42:	5e                   	pop    %esi
f0102e43:	5f                   	pop    %edi
f0102e44:	5d                   	pop    %ebp
f0102e45:	c3                   	ret    

f0102e46 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e46:	55                   	push   %ebp
f0102e47:	89 e5                	mov    %esp,%ebp
f0102e49:	83 ec 18             	sub    $0x18,%esp
f0102e4c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e4f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102e52:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e55:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102e59:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102e5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102e63:	85 c0                	test   %eax,%eax
f0102e65:	74 26                	je     f0102e8d <vsnprintf+0x47>
f0102e67:	85 d2                	test   %edx,%edx
f0102e69:	7e 22                	jle    f0102e8d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e6b:	ff 75 14             	pushl  0x14(%ebp)
f0102e6e:	ff 75 10             	pushl  0x10(%ebp)
f0102e71:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102e74:	50                   	push   %eax
f0102e75:	68 a6 29 10 f0       	push   $0xf01029a6
f0102e7a:	e8 61 fb ff ff       	call   f01029e0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102e7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e82:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102e85:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e88:	83 c4 10             	add    $0x10,%esp
f0102e8b:	eb 05                	jmp    f0102e92 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102e8d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102e92:	c9                   	leave  
f0102e93:	c3                   	ret    

f0102e94 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102e94:	55                   	push   %ebp
f0102e95:	89 e5                	mov    %esp,%ebp
f0102e97:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102e9a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102e9d:	50                   	push   %eax
f0102e9e:	ff 75 10             	pushl  0x10(%ebp)
f0102ea1:	ff 75 0c             	pushl  0xc(%ebp)
f0102ea4:	ff 75 08             	pushl  0x8(%ebp)
f0102ea7:	e8 9a ff ff ff       	call   f0102e46 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102eac:	c9                   	leave  
f0102ead:	c3                   	ret    

f0102eae <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102eae:	55                   	push   %ebp
f0102eaf:	89 e5                	mov    %esp,%ebp
f0102eb1:	57                   	push   %edi
f0102eb2:	56                   	push   %esi
f0102eb3:	53                   	push   %ebx
f0102eb4:	83 ec 0c             	sub    $0xc,%esp
f0102eb7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102eba:	85 c0                	test   %eax,%eax
f0102ebc:	74 11                	je     f0102ecf <readline+0x21>
		cprintf("%s", prompt);
f0102ebe:	83 ec 08             	sub    $0x8,%esp
f0102ec1:	50                   	push   %eax
f0102ec2:	68 f4 41 10 f0       	push   $0xf01041f4
f0102ec7:	e8 50 f7 ff ff       	call   f010261c <cprintf>
f0102ecc:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102ecf:	83 ec 0c             	sub    $0xc,%esp
f0102ed2:	6a 00                	push   $0x0
f0102ed4:	e8 48 d7 ff ff       	call   f0100621 <iscons>
f0102ed9:	89 c7                	mov    %eax,%edi
f0102edb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102ede:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102ee3:	e8 28 d7 ff ff       	call   f0100610 <getchar>
f0102ee8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102eea:	85 c0                	test   %eax,%eax
f0102eec:	79 18                	jns    f0102f06 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102eee:	83 ec 08             	sub    $0x8,%esp
f0102ef1:	50                   	push   %eax
f0102ef2:	68 c4 46 10 f0       	push   $0xf01046c4
f0102ef7:	e8 20 f7 ff ff       	call   f010261c <cprintf>
			return NULL;
f0102efc:	83 c4 10             	add    $0x10,%esp
f0102eff:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f04:	eb 79                	jmp    f0102f7f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f06:	83 f8 08             	cmp    $0x8,%eax
f0102f09:	0f 94 c2             	sete   %dl
f0102f0c:	83 f8 7f             	cmp    $0x7f,%eax
f0102f0f:	0f 94 c0             	sete   %al
f0102f12:	08 c2                	or     %al,%dl
f0102f14:	74 1a                	je     f0102f30 <readline+0x82>
f0102f16:	85 f6                	test   %esi,%esi
f0102f18:	7e 16                	jle    f0102f30 <readline+0x82>
			if (echoing)
f0102f1a:	85 ff                	test   %edi,%edi
f0102f1c:	74 0d                	je     f0102f2b <readline+0x7d>
				cputchar('\b');
f0102f1e:	83 ec 0c             	sub    $0xc,%esp
f0102f21:	6a 08                	push   $0x8
f0102f23:	e8 d8 d6 ff ff       	call   f0100600 <cputchar>
f0102f28:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f2b:	83 ee 01             	sub    $0x1,%esi
f0102f2e:	eb b3                	jmp    f0102ee3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f30:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f33:	7e 23                	jle    f0102f58 <readline+0xaa>
f0102f35:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f3b:	7f 1b                	jg     f0102f58 <readline+0xaa>
			if (echoing)
f0102f3d:	85 ff                	test   %edi,%edi
f0102f3f:	74 0c                	je     f0102f4d <readline+0x9f>
				cputchar(c);
f0102f41:	83 ec 0c             	sub    $0xc,%esp
f0102f44:	53                   	push   %ebx
f0102f45:	e8 b6 d6 ff ff       	call   f0100600 <cputchar>
f0102f4a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f4d:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0102f53:	8d 76 01             	lea    0x1(%esi),%esi
f0102f56:	eb 8b                	jmp    f0102ee3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102f58:	83 fb 0a             	cmp    $0xa,%ebx
f0102f5b:	74 05                	je     f0102f62 <readline+0xb4>
f0102f5d:	83 fb 0d             	cmp    $0xd,%ebx
f0102f60:	75 81                	jne    f0102ee3 <readline+0x35>
			if (echoing)
f0102f62:	85 ff                	test   %edi,%edi
f0102f64:	74 0d                	je     f0102f73 <readline+0xc5>
				cputchar('\n');
f0102f66:	83 ec 0c             	sub    $0xc,%esp
f0102f69:	6a 0a                	push   $0xa
f0102f6b:	e8 90 d6 ff ff       	call   f0100600 <cputchar>
f0102f70:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f73:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102f7a:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0102f7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f82:	5b                   	pop    %ebx
f0102f83:	5e                   	pop    %esi
f0102f84:	5f                   	pop    %edi
f0102f85:	5d                   	pop    %ebp
f0102f86:	c3                   	ret    

f0102f87 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102f87:	55                   	push   %ebp
f0102f88:	89 e5                	mov    %esp,%ebp
f0102f8a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f92:	eb 03                	jmp    f0102f97 <strlen+0x10>
		n++;
f0102f94:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f97:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102f9b:	75 f7                	jne    f0102f94 <strlen+0xd>
		n++;
	return n;
}
f0102f9d:	5d                   	pop    %ebp
f0102f9e:	c3                   	ret    

f0102f9f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f9f:	55                   	push   %ebp
f0102fa0:	89 e5                	mov    %esp,%ebp
f0102fa2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102fa5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fa8:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fad:	eb 03                	jmp    f0102fb2 <strnlen+0x13>
		n++;
f0102faf:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fb2:	39 c2                	cmp    %eax,%edx
f0102fb4:	74 08                	je     f0102fbe <strnlen+0x1f>
f0102fb6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102fba:	75 f3                	jne    f0102faf <strnlen+0x10>
f0102fbc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102fbe:	5d                   	pop    %ebp
f0102fbf:	c3                   	ret    

f0102fc0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102fc0:	55                   	push   %ebp
f0102fc1:	89 e5                	mov    %esp,%ebp
f0102fc3:	53                   	push   %ebx
f0102fc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fc7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102fca:	89 c2                	mov    %eax,%edx
f0102fcc:	83 c2 01             	add    $0x1,%edx
f0102fcf:	83 c1 01             	add    $0x1,%ecx
f0102fd2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102fd6:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102fd9:	84 db                	test   %bl,%bl
f0102fdb:	75 ef                	jne    f0102fcc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102fdd:	5b                   	pop    %ebx
f0102fde:	5d                   	pop    %ebp
f0102fdf:	c3                   	ret    

f0102fe0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
f0102fe3:	53                   	push   %ebx
f0102fe4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102fe7:	53                   	push   %ebx
f0102fe8:	e8 9a ff ff ff       	call   f0102f87 <strlen>
f0102fed:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102ff0:	ff 75 0c             	pushl  0xc(%ebp)
f0102ff3:	01 d8                	add    %ebx,%eax
f0102ff5:	50                   	push   %eax
f0102ff6:	e8 c5 ff ff ff       	call   f0102fc0 <strcpy>
	return dst;
}
f0102ffb:	89 d8                	mov    %ebx,%eax
f0102ffd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103000:	c9                   	leave  
f0103001:	c3                   	ret    

f0103002 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103002:	55                   	push   %ebp
f0103003:	89 e5                	mov    %esp,%ebp
f0103005:	56                   	push   %esi
f0103006:	53                   	push   %ebx
f0103007:	8b 75 08             	mov    0x8(%ebp),%esi
f010300a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010300d:	89 f3                	mov    %esi,%ebx
f010300f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103012:	89 f2                	mov    %esi,%edx
f0103014:	eb 0f                	jmp    f0103025 <strncpy+0x23>
		*dst++ = *src;
f0103016:	83 c2 01             	add    $0x1,%edx
f0103019:	0f b6 01             	movzbl (%ecx),%eax
f010301c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010301f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103022:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103025:	39 da                	cmp    %ebx,%edx
f0103027:	75 ed                	jne    f0103016 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103029:	89 f0                	mov    %esi,%eax
f010302b:	5b                   	pop    %ebx
f010302c:	5e                   	pop    %esi
f010302d:	5d                   	pop    %ebp
f010302e:	c3                   	ret    

f010302f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010302f:	55                   	push   %ebp
f0103030:	89 e5                	mov    %esp,%ebp
f0103032:	56                   	push   %esi
f0103033:	53                   	push   %ebx
f0103034:	8b 75 08             	mov    0x8(%ebp),%esi
f0103037:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010303a:	8b 55 10             	mov    0x10(%ebp),%edx
f010303d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010303f:	85 d2                	test   %edx,%edx
f0103041:	74 21                	je     f0103064 <strlcpy+0x35>
f0103043:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103047:	89 f2                	mov    %esi,%edx
f0103049:	eb 09                	jmp    f0103054 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010304b:	83 c2 01             	add    $0x1,%edx
f010304e:	83 c1 01             	add    $0x1,%ecx
f0103051:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103054:	39 c2                	cmp    %eax,%edx
f0103056:	74 09                	je     f0103061 <strlcpy+0x32>
f0103058:	0f b6 19             	movzbl (%ecx),%ebx
f010305b:	84 db                	test   %bl,%bl
f010305d:	75 ec                	jne    f010304b <strlcpy+0x1c>
f010305f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103061:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103064:	29 f0                	sub    %esi,%eax
}
f0103066:	5b                   	pop    %ebx
f0103067:	5e                   	pop    %esi
f0103068:	5d                   	pop    %ebp
f0103069:	c3                   	ret    

f010306a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010306a:	55                   	push   %ebp
f010306b:	89 e5                	mov    %esp,%ebp
f010306d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103070:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103073:	eb 06                	jmp    f010307b <strcmp+0x11>
		p++, q++;
f0103075:	83 c1 01             	add    $0x1,%ecx
f0103078:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010307b:	0f b6 01             	movzbl (%ecx),%eax
f010307e:	84 c0                	test   %al,%al
f0103080:	74 04                	je     f0103086 <strcmp+0x1c>
f0103082:	3a 02                	cmp    (%edx),%al
f0103084:	74 ef                	je     f0103075 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103086:	0f b6 c0             	movzbl %al,%eax
f0103089:	0f b6 12             	movzbl (%edx),%edx
f010308c:	29 d0                	sub    %edx,%eax
}
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    

f0103090 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103090:	55                   	push   %ebp
f0103091:	89 e5                	mov    %esp,%ebp
f0103093:	53                   	push   %ebx
f0103094:	8b 45 08             	mov    0x8(%ebp),%eax
f0103097:	8b 55 0c             	mov    0xc(%ebp),%edx
f010309a:	89 c3                	mov    %eax,%ebx
f010309c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010309f:	eb 06                	jmp    f01030a7 <strncmp+0x17>
		n--, p++, q++;
f01030a1:	83 c0 01             	add    $0x1,%eax
f01030a4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01030a7:	39 d8                	cmp    %ebx,%eax
f01030a9:	74 15                	je     f01030c0 <strncmp+0x30>
f01030ab:	0f b6 08             	movzbl (%eax),%ecx
f01030ae:	84 c9                	test   %cl,%cl
f01030b0:	74 04                	je     f01030b6 <strncmp+0x26>
f01030b2:	3a 0a                	cmp    (%edx),%cl
f01030b4:	74 eb                	je     f01030a1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01030b6:	0f b6 00             	movzbl (%eax),%eax
f01030b9:	0f b6 12             	movzbl (%edx),%edx
f01030bc:	29 d0                	sub    %edx,%eax
f01030be:	eb 05                	jmp    f01030c5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01030c0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01030c5:	5b                   	pop    %ebx
f01030c6:	5d                   	pop    %ebp
f01030c7:	c3                   	ret    

f01030c8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01030c8:	55                   	push   %ebp
f01030c9:	89 e5                	mov    %esp,%ebp
f01030cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030d2:	eb 07                	jmp    f01030db <strchr+0x13>
		if (*s == c)
f01030d4:	38 ca                	cmp    %cl,%dl
f01030d6:	74 0f                	je     f01030e7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01030d8:	83 c0 01             	add    $0x1,%eax
f01030db:	0f b6 10             	movzbl (%eax),%edx
f01030de:	84 d2                	test   %dl,%dl
f01030e0:	75 f2                	jne    f01030d4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01030e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030e7:	5d                   	pop    %ebp
f01030e8:	c3                   	ret    

f01030e9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01030e9:	55                   	push   %ebp
f01030ea:	89 e5                	mov    %esp,%ebp
f01030ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ef:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030f3:	eb 03                	jmp    f01030f8 <strfind+0xf>
f01030f5:	83 c0 01             	add    $0x1,%eax
f01030f8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01030fb:	38 ca                	cmp    %cl,%dl
f01030fd:	74 04                	je     f0103103 <strfind+0x1a>
f01030ff:	84 d2                	test   %dl,%dl
f0103101:	75 f2                	jne    f01030f5 <strfind+0xc>
			break;
	return (char *) s;
}
f0103103:	5d                   	pop    %ebp
f0103104:	c3                   	ret    

f0103105 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103105:	55                   	push   %ebp
f0103106:	89 e5                	mov    %esp,%ebp
f0103108:	57                   	push   %edi
f0103109:	56                   	push   %esi
f010310a:	53                   	push   %ebx
f010310b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010310e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103111:	85 c9                	test   %ecx,%ecx
f0103113:	74 36                	je     f010314b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103115:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010311b:	75 28                	jne    f0103145 <memset+0x40>
f010311d:	f6 c1 03             	test   $0x3,%cl
f0103120:	75 23                	jne    f0103145 <memset+0x40>
		c &= 0xFF;
f0103122:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103126:	89 d3                	mov    %edx,%ebx
f0103128:	c1 e3 08             	shl    $0x8,%ebx
f010312b:	89 d6                	mov    %edx,%esi
f010312d:	c1 e6 18             	shl    $0x18,%esi
f0103130:	89 d0                	mov    %edx,%eax
f0103132:	c1 e0 10             	shl    $0x10,%eax
f0103135:	09 f0                	or     %esi,%eax
f0103137:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103139:	89 d8                	mov    %ebx,%eax
f010313b:	09 d0                	or     %edx,%eax
f010313d:	c1 e9 02             	shr    $0x2,%ecx
f0103140:	fc                   	cld    
f0103141:	f3 ab                	rep stos %eax,%es:(%edi)
f0103143:	eb 06                	jmp    f010314b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103145:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103148:	fc                   	cld    
f0103149:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010314b:	89 f8                	mov    %edi,%eax
f010314d:	5b                   	pop    %ebx
f010314e:	5e                   	pop    %esi
f010314f:	5f                   	pop    %edi
f0103150:	5d                   	pop    %ebp
f0103151:	c3                   	ret    

f0103152 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103152:	55                   	push   %ebp
f0103153:	89 e5                	mov    %esp,%ebp
f0103155:	57                   	push   %edi
f0103156:	56                   	push   %esi
f0103157:	8b 45 08             	mov    0x8(%ebp),%eax
f010315a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010315d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103160:	39 c6                	cmp    %eax,%esi
f0103162:	73 35                	jae    f0103199 <memmove+0x47>
f0103164:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103167:	39 d0                	cmp    %edx,%eax
f0103169:	73 2e                	jae    f0103199 <memmove+0x47>
		s += n;
		d += n;
f010316b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010316e:	89 d6                	mov    %edx,%esi
f0103170:	09 fe                	or     %edi,%esi
f0103172:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103178:	75 13                	jne    f010318d <memmove+0x3b>
f010317a:	f6 c1 03             	test   $0x3,%cl
f010317d:	75 0e                	jne    f010318d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010317f:	83 ef 04             	sub    $0x4,%edi
f0103182:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103185:	c1 e9 02             	shr    $0x2,%ecx
f0103188:	fd                   	std    
f0103189:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010318b:	eb 09                	jmp    f0103196 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010318d:	83 ef 01             	sub    $0x1,%edi
f0103190:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103193:	fd                   	std    
f0103194:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103196:	fc                   	cld    
f0103197:	eb 1d                	jmp    f01031b6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103199:	89 f2                	mov    %esi,%edx
f010319b:	09 c2                	or     %eax,%edx
f010319d:	f6 c2 03             	test   $0x3,%dl
f01031a0:	75 0f                	jne    f01031b1 <memmove+0x5f>
f01031a2:	f6 c1 03             	test   $0x3,%cl
f01031a5:	75 0a                	jne    f01031b1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01031a7:	c1 e9 02             	shr    $0x2,%ecx
f01031aa:	89 c7                	mov    %eax,%edi
f01031ac:	fc                   	cld    
f01031ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031af:	eb 05                	jmp    f01031b6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01031b1:	89 c7                	mov    %eax,%edi
f01031b3:	fc                   	cld    
f01031b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01031b6:	5e                   	pop    %esi
f01031b7:	5f                   	pop    %edi
f01031b8:	5d                   	pop    %ebp
f01031b9:	c3                   	ret    

f01031ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01031ba:	55                   	push   %ebp
f01031bb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01031bd:	ff 75 10             	pushl  0x10(%ebp)
f01031c0:	ff 75 0c             	pushl  0xc(%ebp)
f01031c3:	ff 75 08             	pushl  0x8(%ebp)
f01031c6:	e8 87 ff ff ff       	call   f0103152 <memmove>
}
f01031cb:	c9                   	leave  
f01031cc:	c3                   	ret    

f01031cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01031cd:	55                   	push   %ebp
f01031ce:	89 e5                	mov    %esp,%ebp
f01031d0:	56                   	push   %esi
f01031d1:	53                   	push   %ebx
f01031d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031d8:	89 c6                	mov    %eax,%esi
f01031da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031dd:	eb 1a                	jmp    f01031f9 <memcmp+0x2c>
		if (*s1 != *s2)
f01031df:	0f b6 08             	movzbl (%eax),%ecx
f01031e2:	0f b6 1a             	movzbl (%edx),%ebx
f01031e5:	38 d9                	cmp    %bl,%cl
f01031e7:	74 0a                	je     f01031f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01031e9:	0f b6 c1             	movzbl %cl,%eax
f01031ec:	0f b6 db             	movzbl %bl,%ebx
f01031ef:	29 d8                	sub    %ebx,%eax
f01031f1:	eb 0f                	jmp    f0103202 <memcmp+0x35>
		s1++, s2++;
f01031f3:	83 c0 01             	add    $0x1,%eax
f01031f6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031f9:	39 f0                	cmp    %esi,%eax
f01031fb:	75 e2                	jne    f01031df <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01031fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103202:	5b                   	pop    %ebx
f0103203:	5e                   	pop    %esi
f0103204:	5d                   	pop    %ebp
f0103205:	c3                   	ret    

f0103206 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103206:	55                   	push   %ebp
f0103207:	89 e5                	mov    %esp,%ebp
f0103209:	53                   	push   %ebx
f010320a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010320d:	89 c1                	mov    %eax,%ecx
f010320f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103212:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103216:	eb 0a                	jmp    f0103222 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103218:	0f b6 10             	movzbl (%eax),%edx
f010321b:	39 da                	cmp    %ebx,%edx
f010321d:	74 07                	je     f0103226 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010321f:	83 c0 01             	add    $0x1,%eax
f0103222:	39 c8                	cmp    %ecx,%eax
f0103224:	72 f2                	jb     f0103218 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103226:	5b                   	pop    %ebx
f0103227:	5d                   	pop    %ebp
f0103228:	c3                   	ret    

f0103229 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103229:	55                   	push   %ebp
f010322a:	89 e5                	mov    %esp,%ebp
f010322c:	57                   	push   %edi
f010322d:	56                   	push   %esi
f010322e:	53                   	push   %ebx
f010322f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103232:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103235:	eb 03                	jmp    f010323a <strtol+0x11>
		s++;
f0103237:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010323a:	0f b6 01             	movzbl (%ecx),%eax
f010323d:	3c 20                	cmp    $0x20,%al
f010323f:	74 f6                	je     f0103237 <strtol+0xe>
f0103241:	3c 09                	cmp    $0x9,%al
f0103243:	74 f2                	je     f0103237 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103245:	3c 2b                	cmp    $0x2b,%al
f0103247:	75 0a                	jne    f0103253 <strtol+0x2a>
		s++;
f0103249:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010324c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103251:	eb 11                	jmp    f0103264 <strtol+0x3b>
f0103253:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103258:	3c 2d                	cmp    $0x2d,%al
f010325a:	75 08                	jne    f0103264 <strtol+0x3b>
		s++, neg = 1;
f010325c:	83 c1 01             	add    $0x1,%ecx
f010325f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103264:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010326a:	75 15                	jne    f0103281 <strtol+0x58>
f010326c:	80 39 30             	cmpb   $0x30,(%ecx)
f010326f:	75 10                	jne    f0103281 <strtol+0x58>
f0103271:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103275:	75 7c                	jne    f01032f3 <strtol+0xca>
		s += 2, base = 16;
f0103277:	83 c1 02             	add    $0x2,%ecx
f010327a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010327f:	eb 16                	jmp    f0103297 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103281:	85 db                	test   %ebx,%ebx
f0103283:	75 12                	jne    f0103297 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103285:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010328a:	80 39 30             	cmpb   $0x30,(%ecx)
f010328d:	75 08                	jne    f0103297 <strtol+0x6e>
		s++, base = 8;
f010328f:	83 c1 01             	add    $0x1,%ecx
f0103292:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103297:	b8 00 00 00 00       	mov    $0x0,%eax
f010329c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010329f:	0f b6 11             	movzbl (%ecx),%edx
f01032a2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01032a5:	89 f3                	mov    %esi,%ebx
f01032a7:	80 fb 09             	cmp    $0x9,%bl
f01032aa:	77 08                	ja     f01032b4 <strtol+0x8b>
			dig = *s - '0';
f01032ac:	0f be d2             	movsbl %dl,%edx
f01032af:	83 ea 30             	sub    $0x30,%edx
f01032b2:	eb 22                	jmp    f01032d6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01032b4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01032b7:	89 f3                	mov    %esi,%ebx
f01032b9:	80 fb 19             	cmp    $0x19,%bl
f01032bc:	77 08                	ja     f01032c6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01032be:	0f be d2             	movsbl %dl,%edx
f01032c1:	83 ea 57             	sub    $0x57,%edx
f01032c4:	eb 10                	jmp    f01032d6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01032c6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01032c9:	89 f3                	mov    %esi,%ebx
f01032cb:	80 fb 19             	cmp    $0x19,%bl
f01032ce:	77 16                	ja     f01032e6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01032d0:	0f be d2             	movsbl %dl,%edx
f01032d3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01032d6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01032d9:	7d 0b                	jge    f01032e6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01032db:	83 c1 01             	add    $0x1,%ecx
f01032de:	0f af 45 10          	imul   0x10(%ebp),%eax
f01032e2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01032e4:	eb b9                	jmp    f010329f <strtol+0x76>

	if (endptr)
f01032e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01032ea:	74 0d                	je     f01032f9 <strtol+0xd0>
		*endptr = (char *) s;
f01032ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032ef:	89 0e                	mov    %ecx,(%esi)
f01032f1:	eb 06                	jmp    f01032f9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032f3:	85 db                	test   %ebx,%ebx
f01032f5:	74 98                	je     f010328f <strtol+0x66>
f01032f7:	eb 9e                	jmp    f0103297 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01032f9:	89 c2                	mov    %eax,%edx
f01032fb:	f7 da                	neg    %edx
f01032fd:	85 ff                	test   %edi,%edi
f01032ff:	0f 45 c2             	cmovne %edx,%eax
}
f0103302:	5b                   	pop    %ebx
f0103303:	5e                   	pop    %esi
f0103304:	5f                   	pop    %edi
f0103305:	5d                   	pop    %ebp
f0103306:	c3                   	ret    
f0103307:	66 90                	xchg   %ax,%ax
f0103309:	66 90                	xchg   %ax,%ax
f010330b:	66 90                	xchg   %ax,%ax
f010330d:	66 90                	xchg   %ax,%ax
f010330f:	90                   	nop

f0103310 <__udivdi3>:
f0103310:	55                   	push   %ebp
f0103311:	57                   	push   %edi
f0103312:	56                   	push   %esi
f0103313:	53                   	push   %ebx
f0103314:	83 ec 1c             	sub    $0x1c,%esp
f0103317:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010331b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010331f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103323:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103327:	85 f6                	test   %esi,%esi
f0103329:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010332d:	89 ca                	mov    %ecx,%edx
f010332f:	89 f8                	mov    %edi,%eax
f0103331:	75 3d                	jne    f0103370 <__udivdi3+0x60>
f0103333:	39 cf                	cmp    %ecx,%edi
f0103335:	0f 87 c5 00 00 00    	ja     f0103400 <__udivdi3+0xf0>
f010333b:	85 ff                	test   %edi,%edi
f010333d:	89 fd                	mov    %edi,%ebp
f010333f:	75 0b                	jne    f010334c <__udivdi3+0x3c>
f0103341:	b8 01 00 00 00       	mov    $0x1,%eax
f0103346:	31 d2                	xor    %edx,%edx
f0103348:	f7 f7                	div    %edi
f010334a:	89 c5                	mov    %eax,%ebp
f010334c:	89 c8                	mov    %ecx,%eax
f010334e:	31 d2                	xor    %edx,%edx
f0103350:	f7 f5                	div    %ebp
f0103352:	89 c1                	mov    %eax,%ecx
f0103354:	89 d8                	mov    %ebx,%eax
f0103356:	89 cf                	mov    %ecx,%edi
f0103358:	f7 f5                	div    %ebp
f010335a:	89 c3                	mov    %eax,%ebx
f010335c:	89 d8                	mov    %ebx,%eax
f010335e:	89 fa                	mov    %edi,%edx
f0103360:	83 c4 1c             	add    $0x1c,%esp
f0103363:	5b                   	pop    %ebx
f0103364:	5e                   	pop    %esi
f0103365:	5f                   	pop    %edi
f0103366:	5d                   	pop    %ebp
f0103367:	c3                   	ret    
f0103368:	90                   	nop
f0103369:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103370:	39 ce                	cmp    %ecx,%esi
f0103372:	77 74                	ja     f01033e8 <__udivdi3+0xd8>
f0103374:	0f bd fe             	bsr    %esi,%edi
f0103377:	83 f7 1f             	xor    $0x1f,%edi
f010337a:	0f 84 98 00 00 00    	je     f0103418 <__udivdi3+0x108>
f0103380:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103385:	89 f9                	mov    %edi,%ecx
f0103387:	89 c5                	mov    %eax,%ebp
f0103389:	29 fb                	sub    %edi,%ebx
f010338b:	d3 e6                	shl    %cl,%esi
f010338d:	89 d9                	mov    %ebx,%ecx
f010338f:	d3 ed                	shr    %cl,%ebp
f0103391:	89 f9                	mov    %edi,%ecx
f0103393:	d3 e0                	shl    %cl,%eax
f0103395:	09 ee                	or     %ebp,%esi
f0103397:	89 d9                	mov    %ebx,%ecx
f0103399:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010339d:	89 d5                	mov    %edx,%ebp
f010339f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033a3:	d3 ed                	shr    %cl,%ebp
f01033a5:	89 f9                	mov    %edi,%ecx
f01033a7:	d3 e2                	shl    %cl,%edx
f01033a9:	89 d9                	mov    %ebx,%ecx
f01033ab:	d3 e8                	shr    %cl,%eax
f01033ad:	09 c2                	or     %eax,%edx
f01033af:	89 d0                	mov    %edx,%eax
f01033b1:	89 ea                	mov    %ebp,%edx
f01033b3:	f7 f6                	div    %esi
f01033b5:	89 d5                	mov    %edx,%ebp
f01033b7:	89 c3                	mov    %eax,%ebx
f01033b9:	f7 64 24 0c          	mull   0xc(%esp)
f01033bd:	39 d5                	cmp    %edx,%ebp
f01033bf:	72 10                	jb     f01033d1 <__udivdi3+0xc1>
f01033c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01033c5:	89 f9                	mov    %edi,%ecx
f01033c7:	d3 e6                	shl    %cl,%esi
f01033c9:	39 c6                	cmp    %eax,%esi
f01033cb:	73 07                	jae    f01033d4 <__udivdi3+0xc4>
f01033cd:	39 d5                	cmp    %edx,%ebp
f01033cf:	75 03                	jne    f01033d4 <__udivdi3+0xc4>
f01033d1:	83 eb 01             	sub    $0x1,%ebx
f01033d4:	31 ff                	xor    %edi,%edi
f01033d6:	89 d8                	mov    %ebx,%eax
f01033d8:	89 fa                	mov    %edi,%edx
f01033da:	83 c4 1c             	add    $0x1c,%esp
f01033dd:	5b                   	pop    %ebx
f01033de:	5e                   	pop    %esi
f01033df:	5f                   	pop    %edi
f01033e0:	5d                   	pop    %ebp
f01033e1:	c3                   	ret    
f01033e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033e8:	31 ff                	xor    %edi,%edi
f01033ea:	31 db                	xor    %ebx,%ebx
f01033ec:	89 d8                	mov    %ebx,%eax
f01033ee:	89 fa                	mov    %edi,%edx
f01033f0:	83 c4 1c             	add    $0x1c,%esp
f01033f3:	5b                   	pop    %ebx
f01033f4:	5e                   	pop    %esi
f01033f5:	5f                   	pop    %edi
f01033f6:	5d                   	pop    %ebp
f01033f7:	c3                   	ret    
f01033f8:	90                   	nop
f01033f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103400:	89 d8                	mov    %ebx,%eax
f0103402:	f7 f7                	div    %edi
f0103404:	31 ff                	xor    %edi,%edi
f0103406:	89 c3                	mov    %eax,%ebx
f0103408:	89 d8                	mov    %ebx,%eax
f010340a:	89 fa                	mov    %edi,%edx
f010340c:	83 c4 1c             	add    $0x1c,%esp
f010340f:	5b                   	pop    %ebx
f0103410:	5e                   	pop    %esi
f0103411:	5f                   	pop    %edi
f0103412:	5d                   	pop    %ebp
f0103413:	c3                   	ret    
f0103414:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103418:	39 ce                	cmp    %ecx,%esi
f010341a:	72 0c                	jb     f0103428 <__udivdi3+0x118>
f010341c:	31 db                	xor    %ebx,%ebx
f010341e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103422:	0f 87 34 ff ff ff    	ja     f010335c <__udivdi3+0x4c>
f0103428:	bb 01 00 00 00       	mov    $0x1,%ebx
f010342d:	e9 2a ff ff ff       	jmp    f010335c <__udivdi3+0x4c>
f0103432:	66 90                	xchg   %ax,%ax
f0103434:	66 90                	xchg   %ax,%ax
f0103436:	66 90                	xchg   %ax,%ax
f0103438:	66 90                	xchg   %ax,%ax
f010343a:	66 90                	xchg   %ax,%ax
f010343c:	66 90                	xchg   %ax,%ax
f010343e:	66 90                	xchg   %ax,%ax

f0103440 <__umoddi3>:
f0103440:	55                   	push   %ebp
f0103441:	57                   	push   %edi
f0103442:	56                   	push   %esi
f0103443:	53                   	push   %ebx
f0103444:	83 ec 1c             	sub    $0x1c,%esp
f0103447:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010344b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010344f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103453:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103457:	85 d2                	test   %edx,%edx
f0103459:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010345d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103461:	89 f3                	mov    %esi,%ebx
f0103463:	89 3c 24             	mov    %edi,(%esp)
f0103466:	89 74 24 04          	mov    %esi,0x4(%esp)
f010346a:	75 1c                	jne    f0103488 <__umoddi3+0x48>
f010346c:	39 f7                	cmp    %esi,%edi
f010346e:	76 50                	jbe    f01034c0 <__umoddi3+0x80>
f0103470:	89 c8                	mov    %ecx,%eax
f0103472:	89 f2                	mov    %esi,%edx
f0103474:	f7 f7                	div    %edi
f0103476:	89 d0                	mov    %edx,%eax
f0103478:	31 d2                	xor    %edx,%edx
f010347a:	83 c4 1c             	add    $0x1c,%esp
f010347d:	5b                   	pop    %ebx
f010347e:	5e                   	pop    %esi
f010347f:	5f                   	pop    %edi
f0103480:	5d                   	pop    %ebp
f0103481:	c3                   	ret    
f0103482:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103488:	39 f2                	cmp    %esi,%edx
f010348a:	89 d0                	mov    %edx,%eax
f010348c:	77 52                	ja     f01034e0 <__umoddi3+0xa0>
f010348e:	0f bd ea             	bsr    %edx,%ebp
f0103491:	83 f5 1f             	xor    $0x1f,%ebp
f0103494:	75 5a                	jne    f01034f0 <__umoddi3+0xb0>
f0103496:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010349a:	0f 82 e0 00 00 00    	jb     f0103580 <__umoddi3+0x140>
f01034a0:	39 0c 24             	cmp    %ecx,(%esp)
f01034a3:	0f 86 d7 00 00 00    	jbe    f0103580 <__umoddi3+0x140>
f01034a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01034b1:	83 c4 1c             	add    $0x1c,%esp
f01034b4:	5b                   	pop    %ebx
f01034b5:	5e                   	pop    %esi
f01034b6:	5f                   	pop    %edi
f01034b7:	5d                   	pop    %ebp
f01034b8:	c3                   	ret    
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	85 ff                	test   %edi,%edi
f01034c2:	89 fd                	mov    %edi,%ebp
f01034c4:	75 0b                	jne    f01034d1 <__umoddi3+0x91>
f01034c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01034cb:	31 d2                	xor    %edx,%edx
f01034cd:	f7 f7                	div    %edi
f01034cf:	89 c5                	mov    %eax,%ebp
f01034d1:	89 f0                	mov    %esi,%eax
f01034d3:	31 d2                	xor    %edx,%edx
f01034d5:	f7 f5                	div    %ebp
f01034d7:	89 c8                	mov    %ecx,%eax
f01034d9:	f7 f5                	div    %ebp
f01034db:	89 d0                	mov    %edx,%eax
f01034dd:	eb 99                	jmp    f0103478 <__umoddi3+0x38>
f01034df:	90                   	nop
f01034e0:	89 c8                	mov    %ecx,%eax
f01034e2:	89 f2                	mov    %esi,%edx
f01034e4:	83 c4 1c             	add    $0x1c,%esp
f01034e7:	5b                   	pop    %ebx
f01034e8:	5e                   	pop    %esi
f01034e9:	5f                   	pop    %edi
f01034ea:	5d                   	pop    %ebp
f01034eb:	c3                   	ret    
f01034ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034f0:	8b 34 24             	mov    (%esp),%esi
f01034f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01034f8:	89 e9                	mov    %ebp,%ecx
f01034fa:	29 ef                	sub    %ebp,%edi
f01034fc:	d3 e0                	shl    %cl,%eax
f01034fe:	89 f9                	mov    %edi,%ecx
f0103500:	89 f2                	mov    %esi,%edx
f0103502:	d3 ea                	shr    %cl,%edx
f0103504:	89 e9                	mov    %ebp,%ecx
f0103506:	09 c2                	or     %eax,%edx
f0103508:	89 d8                	mov    %ebx,%eax
f010350a:	89 14 24             	mov    %edx,(%esp)
f010350d:	89 f2                	mov    %esi,%edx
f010350f:	d3 e2                	shl    %cl,%edx
f0103511:	89 f9                	mov    %edi,%ecx
f0103513:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103517:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010351b:	d3 e8                	shr    %cl,%eax
f010351d:	89 e9                	mov    %ebp,%ecx
f010351f:	89 c6                	mov    %eax,%esi
f0103521:	d3 e3                	shl    %cl,%ebx
f0103523:	89 f9                	mov    %edi,%ecx
f0103525:	89 d0                	mov    %edx,%eax
f0103527:	d3 e8                	shr    %cl,%eax
f0103529:	89 e9                	mov    %ebp,%ecx
f010352b:	09 d8                	or     %ebx,%eax
f010352d:	89 d3                	mov    %edx,%ebx
f010352f:	89 f2                	mov    %esi,%edx
f0103531:	f7 34 24             	divl   (%esp)
f0103534:	89 d6                	mov    %edx,%esi
f0103536:	d3 e3                	shl    %cl,%ebx
f0103538:	f7 64 24 04          	mull   0x4(%esp)
f010353c:	39 d6                	cmp    %edx,%esi
f010353e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103542:	89 d1                	mov    %edx,%ecx
f0103544:	89 c3                	mov    %eax,%ebx
f0103546:	72 08                	jb     f0103550 <__umoddi3+0x110>
f0103548:	75 11                	jne    f010355b <__umoddi3+0x11b>
f010354a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010354e:	73 0b                	jae    f010355b <__umoddi3+0x11b>
f0103550:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103554:	1b 14 24             	sbb    (%esp),%edx
f0103557:	89 d1                	mov    %edx,%ecx
f0103559:	89 c3                	mov    %eax,%ebx
f010355b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010355f:	29 da                	sub    %ebx,%edx
f0103561:	19 ce                	sbb    %ecx,%esi
f0103563:	89 f9                	mov    %edi,%ecx
f0103565:	89 f0                	mov    %esi,%eax
f0103567:	d3 e0                	shl    %cl,%eax
f0103569:	89 e9                	mov    %ebp,%ecx
f010356b:	d3 ea                	shr    %cl,%edx
f010356d:	89 e9                	mov    %ebp,%ecx
f010356f:	d3 ee                	shr    %cl,%esi
f0103571:	09 d0                	or     %edx,%eax
f0103573:	89 f2                	mov    %esi,%edx
f0103575:	83 c4 1c             	add    $0x1c,%esp
f0103578:	5b                   	pop    %ebx
f0103579:	5e                   	pop    %esi
f010357a:	5f                   	pop    %edi
f010357b:	5d                   	pop    %ebp
f010357c:	c3                   	ret    
f010357d:	8d 76 00             	lea    0x0(%esi),%esi
f0103580:	29 f9                	sub    %edi,%ecx
f0103582:	19 d6                	sbb    %edx,%esi
f0103584:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103588:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010358c:	e9 18 ff ff ff       	jmp    f01034a9 <__umoddi3+0x69>
