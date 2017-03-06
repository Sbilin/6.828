
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 e0 18 10 f0       	push   $0xf01018e0
f0100050:	e8 cc 08 00 00       	call   f0100921 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0a 07 00 00       	call   f0100785 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 95 08 00 00       	call   f0100921 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 81 13 00 00       	call   f0101432 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 b4 04 00 00       	call   f010056a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 59 08 00 00       	call   f0100921 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 ae 06 00 00       	call   f010078f <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 32 19 10 f0       	push   $0xf0101932
f0100110:	e8 0c 08 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 dc 07 00 00       	call   f01008fb <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f0100126:	e8 f6 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 57 06 00 00       	call   f010078f <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 4a 19 10 f0       	push   $0xf010194a
f0100152:	e8 ca 07 00 00       	call   f0100921 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 98 07 00 00       	call   f01008fb <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 6e 19 10 f0 	movl   $0xf010196e,(%esp)
f010016a:	e8 b2 07 00 00       	call   f0100921 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a c0 19 10 f0 	movzbl -0xfefe640(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 64 19 10 f0       	push   $0xf0101964
f01002c8:	e8 54 06 00 00       	call   f0100921 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 0c             	sub    $0xc,%esp
f01002fb:	89 c6                	mov    %eax,%esi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 fa                	mov    %edi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100326:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010032b:	89 f0                	mov    %esi,%eax
f010032d:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010032e:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100333:	bf 79 03 00 00       	mov    $0x379,%edi
f0100338:	b9 84 00 00 00       	mov    $0x84,%ecx
f010033d:	eb 09                	jmp    f0100348 <cons_putc+0x56>
f010033f:	89 ca                	mov    %ecx,%edx
f0100341:	ec                   	in     (%dx),%al
f0100342:	ec                   	in     (%dx),%al
f0100343:	ec                   	in     (%dx),%al
f0100344:	ec                   	in     (%dx),%al
f0100345:	83 c3 01             	add    $0x1,%ebx
f0100348:	89 fa                	mov    %edi,%edx
f010034a:	ec                   	in     (%dx),%al
f010034b:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100351:	7f 04                	jg     f0100357 <cons_putc+0x65>
f0100353:	84 c0                	test   %al,%al
f0100355:	79 e8                	jns    f010033f <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100357:	ba 78 03 00 00       	mov    $0x378,%edx
f010035c:	89 f0                	mov    %esi,%eax
f010035e:	ee                   	out    %al,(%dx)
f010035f:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100364:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100369:	ee                   	out    %al,(%dx)
f010036a:	b8 08 00 00 00       	mov    $0x8,%eax
f010036f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (c>=48&&c<=57)
f0100370:	8d 46 d0             	lea    -0x30(%esi),%eax
f0100373:	83 f8 09             	cmp    $0x9,%eax
f0100376:	77 07                	ja     f010037f <cons_putc+0x8d>
		c=c|0x0400;
f0100378:	89 f0                	mov    %esi,%eax
f010037a:	80 cc 04             	or     $0x4,%ah
f010037d:	eb 23                	jmp    f01003a2 <cons_putc+0xb0>
	else if(c>=65&&c<=90)
f010037f:	8d 46 bf             	lea    -0x41(%esi),%eax
f0100382:	83 f8 19             	cmp    $0x19,%eax
f0100385:	77 07                	ja     f010038e <cons_putc+0x9c>
		c=c|0x0200;
f0100387:	89 f0                	mov    %esi,%eax
f0100389:	80 cc 02             	or     $0x2,%ah
f010038c:	eb 14                	jmp    f01003a2 <cons_putc+0xb0>
	else if(c>=97&&c<=122)
f010038e:	8d 56 9f             	lea    -0x61(%esi),%edx
		c=c|0x0600;
f0100391:	89 f0                	mov    %esi,%eax
f0100393:	80 cc 06             	or     $0x6,%ah
f0100396:	81 ce 00 07 00 00    	or     $0x700,%esi
f010039c:	83 fa 19             	cmp    $0x19,%edx
f010039f:	0f 47 c6             	cmova  %esi,%eax
   	else
		c=c|0x0700;

	switch (c & 0xff) {
f01003a2:	0f b6 d0             	movzbl %al,%edx
f01003a5:	83 fa 09             	cmp    $0x9,%edx
f01003a8:	74 72                	je     f010041c <cons_putc+0x12a>
f01003aa:	83 fa 09             	cmp    $0x9,%edx
f01003ad:	7f 0a                	jg     f01003b9 <cons_putc+0xc7>
f01003af:	83 fa 08             	cmp    $0x8,%edx
f01003b2:	74 14                	je     f01003c8 <cons_putc+0xd6>
f01003b4:	e9 97 00 00 00       	jmp    f0100450 <cons_putc+0x15e>
f01003b9:	83 fa 0a             	cmp    $0xa,%edx
f01003bc:	74 38                	je     f01003f6 <cons_putc+0x104>
f01003be:	83 fa 0d             	cmp    $0xd,%edx
f01003c1:	74 3b                	je     f01003fe <cons_putc+0x10c>
f01003c3:	e9 88 00 00 00       	jmp    f0100450 <cons_putc+0x15e>
	case '\b':
		if (crt_pos > 0) {
f01003c8:	0f b7 15 28 25 11 f0 	movzwl 0xf0112528,%edx
f01003cf:	66 85 d2             	test   %dx,%dx
f01003d2:	0f 84 e4 00 00 00    	je     f01004bc <cons_putc+0x1ca>
			crt_pos--;
f01003d8:	83 ea 01             	sub    $0x1,%edx
f01003db:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e2:	0f b7 d2             	movzwl %dx,%edx
f01003e5:	b0 00                	mov    $0x0,%al
f01003e7:	83 c8 20             	or     $0x20,%eax
f01003ea:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003f0:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01003f4:	eb 78                	jmp    f010046e <cons_putc+0x17c>
		}
		break;
	case '\n':

		crt_pos =(crt_pos+CRT_COLS);
f01003f6:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003fd:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003fe:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100405:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010040b:	c1 e8 16             	shr    $0x16,%eax
f010040e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100411:	c1 e0 04             	shl    $0x4,%eax
f0100414:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f010041a:	eb 52                	jmp    f010046e <cons_putc+0x17c>
		break;
	case '\t':
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 cc fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 c2 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 b8 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 ae fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100444:	b8 20 00 00 00       	mov    $0x20,%eax
f0100449:	e8 a4 fe ff ff       	call   f01002f2 <cons_putc>
f010044e:	eb 1e                	jmp    f010046e <cons_putc+0x17c>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100450:	0f b7 15 28 25 11 f0 	movzwl 0xf0112528,%edx
f0100457:	8d 4a 01             	lea    0x1(%edx),%ecx
f010045a:	66 89 0d 28 25 11 f0 	mov    %cx,0xf0112528
f0100461:	0f b7 d2             	movzwl %dx,%edx
f0100464:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f010046a:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010046e:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100475:	cf 07 
f0100477:	76 43                	jbe    f01004bc <cons_putc+0x1ca>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100479:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010047e:	83 ec 04             	sub    $0x4,%esp
f0100481:	68 00 0f 00 00       	push   $0xf00
f0100486:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010048c:	52                   	push   %edx
f010048d:	50                   	push   %eax
f010048e:	e8 ec 0f 00 00       	call   f010147f <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100493:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100499:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010049f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004a5:	83 c4 10             	add    $0x10,%esp
f01004a8:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004ad:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004b0:	39 d0                	cmp    %edx,%eax
f01004b2:	75 f4                	jne    f01004a8 <cons_putc+0x1b6>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b4:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004bb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004c7:	89 ca                	mov    %ecx,%edx
f01004c9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004ca:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d1:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d4:	89 d8                	mov    %ebx,%eax
f01004d6:	66 c1 e8 08          	shr    $0x8,%ax
f01004da:	89 f2                	mov    %esi,%edx
f01004dc:	ee                   	out    %al,(%dx)
f01004dd:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e2:	89 ca                	mov    %ecx,%edx
f01004e4:	ee                   	out    %al,(%dx)
f01004e5:	89 d8                	mov    %ebx,%eax
f01004e7:	89 f2                	mov    %esi,%edx
f01004e9:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004ed:	5b                   	pop    %ebx
f01004ee:	5e                   	pop    %esi
f01004ef:	5f                   	pop    %edi
f01004f0:	5d                   	pop    %ebp
f01004f1:	c3                   	ret    

f01004f2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f2:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004f9:	74 11                	je     f010050c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100501:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f0100506:	e8 8b fc ff ff       	call   f0100196 <cons_intr>
}
f010050b:	c9                   	leave  
f010050c:	f3 c3                	repz ret 

f010050e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050e:	55                   	push   %ebp
f010050f:	89 e5                	mov    %esp,%ebp
f0100511:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100514:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100519:	e8 78 fc ff ff       	call   f0100196 <cons_intr>
}
f010051e:	c9                   	leave  
f010051f:	c3                   	ret    

f0100520 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100520:	55                   	push   %ebp
f0100521:	89 e5                	mov    %esp,%ebp
f0100523:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100526:	e8 c7 ff ff ff       	call   f01004f2 <serial_intr>
	kbd_intr();
f010052b:	e8 de ff ff ff       	call   f010050e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100530:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100535:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f010053b:	74 26                	je     f0100563 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010053d:	8d 50 01             	lea    0x1(%eax),%edx
f0100540:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100546:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010054d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010054f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100555:	75 11                	jne    f0100568 <cons_getc+0x48>
			cons.rpos = 0;
f0100557:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010055e:	00 00 00 
f0100561:	eb 05                	jmp    f0100568 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100563:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100568:	c9                   	leave  
f0100569:	c3                   	ret    

f010056a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056a:	55                   	push   %ebp
f010056b:	89 e5                	mov    %esp,%ebp
f010056d:	57                   	push   %edi
f010056e:	56                   	push   %esi
f010056f:	53                   	push   %ebx
f0100570:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100573:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100581:	5a a5 
	if (*cp != 0xA55A) {
f0100583:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058e:	74 11                	je     f01005a1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100590:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100597:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010059f:	eb 16                	jmp    f01005b7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a8:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005af:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b2:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b7:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c2:	89 fa                	mov    %edi,%edx
f01005c4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c5:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c8:	89 da                	mov    %ebx,%edx
f01005ca:	ec                   	in     (%dx),%al
f01005cb:	0f b6 c8             	movzbl %al,%ecx
f01005ce:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d6:	89 fa                	mov    %edi,%edx
f01005d8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d9:	89 da                	mov    %ebx,%edx
f01005db:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005dc:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005e2:	0f b6 c0             	movzbl %al,%eax
f01005e5:	09 c8                	or     %ecx,%eax
f01005e7:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ed:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	89 f2                	mov    %esi,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005ff:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100604:	ee                   	out    %al,(%dx)
f0100605:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060f:	89 da                	mov    %ebx,%edx
f0100611:	ee                   	out    %al,(%dx)
f0100612:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100622:	b8 03 00 00 00       	mov    $0x3,%eax
f0100627:	ee                   	out    %al,(%dx)
f0100628:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010062d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100632:	ee                   	out    %al,(%dx)
f0100633:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100638:	b8 01 00 00 00       	mov    $0x1,%eax
f010063d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010063e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100643:	ec                   	in     (%dx),%al
f0100644:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100646:	3c ff                	cmp    $0xff,%al
f0100648:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010064f:	89 f2                	mov    %esi,%edx
f0100651:	ec                   	in     (%dx),%al
f0100652:	89 da                	mov    %ebx,%edx
f0100654:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100655:	80 f9 ff             	cmp    $0xff,%cl
f0100658:	75 10                	jne    f010066a <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f010065a:	83 ec 0c             	sub    $0xc,%esp
f010065d:	68 70 19 10 f0       	push   $0xf0101970
f0100662:	e8 ba 02 00 00       	call   f0100921 <cprintf>
f0100667:	83 c4 10             	add    $0x10,%esp
}
f010066a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010066d:	5b                   	pop    %ebx
f010066e:	5e                   	pop    %esi
f010066f:	5f                   	pop    %edi
f0100670:	5d                   	pop    %ebp
f0100671:	c3                   	ret    

f0100672 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
f0100675:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100678:	8b 45 08             	mov    0x8(%ebp),%eax
f010067b:	e8 72 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <getchar>:

int
getchar(void)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
f0100685:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100688:	e8 93 fe ff ff       	call   f0100520 <cons_getc>
f010068d:	85 c0                	test   %eax,%eax
f010068f:	74 f7                	je     f0100688 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100691:	c9                   	leave  
f0100692:	c3                   	ret    

f0100693 <iscons>:

int
iscons(int fdnum)
{
f0100693:	55                   	push   %ebp
f0100694:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100696:	b8 01 00 00 00       	mov    $0x1,%eax
f010069b:	5d                   	pop    %ebp
f010069c:	c3                   	ret    

f010069d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010069d:	55                   	push   %ebp
f010069e:	89 e5                	mov    %esp,%ebp
f01006a0:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006a3:	68 c0 1b 10 f0       	push   $0xf0101bc0
f01006a8:	68 de 1b 10 f0       	push   $0xf0101bde
f01006ad:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006b2:	e8 6a 02 00 00       	call   f0100921 <cprintf>
f01006b7:	83 c4 0c             	add    $0xc,%esp
f01006ba:	68 5c 1c 10 f0       	push   $0xf0101c5c
f01006bf:	68 ec 1b 10 f0       	push   $0xf0101bec
f01006c4:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006c9:	e8 53 02 00 00       	call   f0100921 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	68 f5 1b 10 f0       	push   $0xf0101bf5
f01006e0:	e8 3c 02 00 00       	call   f0100921 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e5:	83 c4 08             	add    $0x8,%esp
f01006e8:	68 0c 00 10 00       	push   $0x10000c
f01006ed:	68 84 1c 10 f0       	push   $0xf0101c84
f01006f2:	e8 2a 02 00 00       	call   f0100921 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 0c 00 10 00       	push   $0x10000c
f01006ff:	68 0c 00 10 f0       	push   $0xf010000c
f0100704:	68 ac 1c 10 f0       	push   $0xf0101cac
f0100709:	e8 13 02 00 00       	call   f0100921 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 c1 18 10 00       	push   $0x1018c1
f0100716:	68 c1 18 10 f0       	push   $0xf01018c1
f010071b:	68 d0 1c 10 f0       	push   $0xf0101cd0
f0100720:	e8 fc 01 00 00       	call   f0100921 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 00 23 11 00       	push   $0x112300
f010072d:	68 00 23 11 f0       	push   $0xf0112300
f0100732:	68 f4 1c 10 f0       	push   $0xf0101cf4
f0100737:	e8 e5 01 00 00       	call   f0100921 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 44 29 11 00       	push   $0x112944
f0100744:	68 44 29 11 f0       	push   $0xf0112944
f0100749:	68 18 1d 10 f0       	push   $0xf0101d18
f010074e:	e8 ce 01 00 00       	call   f0100921 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100753:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	83 c4 08             	add    $0x8,%esp
f0100760:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100765:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076b:	85 c0                	test   %eax,%eax
f010076d:	0f 48 c2             	cmovs  %edx,%eax
f0100770:	c1 f8 0a             	sar    $0xa,%eax
f0100773:	50                   	push   %eax
f0100774:	68 3c 1d 10 f0       	push   $0xf0101d3c
f0100779:	e8 a3 01 00 00       	call   f0100921 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	57                   	push   %edi
f0100793:	56                   	push   %esi
f0100794:	53                   	push   %ebx
f0100795:	83 ec 4c             	sub    $0x4c,%esp
	char *buf;
	int x=1,y=3,z=4;
	cprintf("%d,%x.%d\n",x,y,z);
f0100798:	6a 04                	push   $0x4
f010079a:	6a 03                	push   $0x3
f010079c:	6a 01                	push   $0x1
f010079e:	68 0e 1c 10 f0       	push   $0xf0101c0e
f01007a3:	e8 79 01 00 00       	call   f0100921 <cprintf>
    
	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a8:	c7 04 24 68 1d 10 f0 	movl   $0xf0101d68,(%esp)
f01007af:	e8 6d 01 00 00       	call   f0100921 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b4:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f01007bb:	e8 61 01 00 00       	call   f0100921 <cprintf>
f01007c0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("asdasK>\n");
f01007c3:	83 ec 0c             	sub    $0xc,%esp
f01007c6:	68 18 1c 10 f0       	push   $0xf0101c18
f01007cb:	e8 0b 0a 00 00       	call   f01011db <readline>
f01007d0:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d2:	83 c4 10             	add    $0x10,%esp
f01007d5:	85 c0                	test   %eax,%eax
f01007d7:	74 ea                	je     f01007c3 <monitor+0x34>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007d9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e0:	be 00 00 00 00       	mov    $0x0,%esi
f01007e5:	eb 0a                	jmp    f01007f1 <monitor+0x62>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007e7:	c6 03 00             	movb   $0x0,(%ebx)
f01007ea:	89 f7                	mov    %esi,%edi
f01007ec:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007ef:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f1:	0f b6 03             	movzbl (%ebx),%eax
f01007f4:	84 c0                	test   %al,%al
f01007f6:	74 63                	je     f010085b <monitor+0xcc>
f01007f8:	83 ec 08             	sub    $0x8,%esp
f01007fb:	0f be c0             	movsbl %al,%eax
f01007fe:	50                   	push   %eax
f01007ff:	68 21 1c 10 f0       	push   $0xf0101c21
f0100804:	e8 ec 0b 00 00       	call   f01013f5 <strchr>
f0100809:	83 c4 10             	add    $0x10,%esp
f010080c:	85 c0                	test   %eax,%eax
f010080e:	75 d7                	jne    f01007e7 <monitor+0x58>
			*buf++ = 0;
		if (*buf == 0)
f0100810:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100813:	74 46                	je     f010085b <monitor+0xcc>
			break;

		// save and scan past next arg 
		if (argc == MAXARGS-1) {
f0100815:	83 fe 0f             	cmp    $0xf,%esi
f0100818:	75 14                	jne    f010082e <monitor+0x9f>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010081a:	83 ec 08             	sub    $0x8,%esp
f010081d:	6a 10                	push   $0x10
f010081f:	68 26 1c 10 f0       	push   $0xf0101c26
f0100824:	e8 f8 00 00 00       	call   f0100921 <cprintf>
f0100829:	83 c4 10             	add    $0x10,%esp
f010082c:	eb 95                	jmp    f01007c3 <monitor+0x34>
			return 0;
		}
		argv[argc++] = buf;
f010082e:	8d 7e 01             	lea    0x1(%esi),%edi
f0100831:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100835:	eb 03                	jmp    f010083a <monitor+0xab>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100837:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010083a:	0f b6 03             	movzbl (%ebx),%eax
f010083d:	84 c0                	test   %al,%al
f010083f:	74 ae                	je     f01007ef <monitor+0x60>
f0100841:	83 ec 08             	sub    $0x8,%esp
f0100844:	0f be c0             	movsbl %al,%eax
f0100847:	50                   	push   %eax
f0100848:	68 21 1c 10 f0       	push   $0xf0101c21
f010084d:	e8 a3 0b 00 00       	call   f01013f5 <strchr>
f0100852:	83 c4 10             	add    $0x10,%esp
f0100855:	85 c0                	test   %eax,%eax
f0100857:	74 de                	je     f0100837 <monitor+0xa8>
f0100859:	eb 94                	jmp    f01007ef <monitor+0x60>
			buf++;
	}
	argv[argc] = 0;
f010085b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100862:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100863:	85 f6                	test   %esi,%esi
f0100865:	0f 84 58 ff ff ff    	je     f01007c3 <monitor+0x34>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010086b:	83 ec 08             	sub    $0x8,%esp
f010086e:	68 de 1b 10 f0       	push   $0xf0101bde
f0100873:	ff 75 a8             	pushl  -0x58(%ebp)
f0100876:	e8 1c 0b 00 00       	call   f0101397 <strcmp>
f010087b:	83 c4 10             	add    $0x10,%esp
f010087e:	85 c0                	test   %eax,%eax
f0100880:	74 1e                	je     f01008a0 <monitor+0x111>
f0100882:	83 ec 08             	sub    $0x8,%esp
f0100885:	68 ec 1b 10 f0       	push   $0xf0101bec
f010088a:	ff 75 a8             	pushl  -0x58(%ebp)
f010088d:	e8 05 0b 00 00       	call   f0101397 <strcmp>
f0100892:	83 c4 10             	add    $0x10,%esp
f0100895:	85 c0                	test   %eax,%eax
f0100897:	75 2f                	jne    f01008c8 <monitor+0x139>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100899:	b8 01 00 00 00       	mov    $0x1,%eax
f010089e:	eb 05                	jmp    f01008a5 <monitor+0x116>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a0:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a5:	83 ec 04             	sub    $0x4,%esp
f01008a8:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008ab:	01 d0                	add    %edx,%eax
f01008ad:	ff 75 08             	pushl  0x8(%ebp)
f01008b0:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008b3:	51                   	push   %ecx
f01008b4:	56                   	push   %esi
f01008b5:	ff 14 85 bc 1d 10 f0 	call   *-0xfefe244(,%eax,4)


	while (1) {
		buf = readline("asdasK>\n");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	78 1d                	js     f01008e0 <monitor+0x151>
f01008c3:	e9 fb fe ff ff       	jmp    f01007c3 <monitor+0x34>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008c8:	83 ec 08             	sub    $0x8,%esp
f01008cb:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ce:	68 43 1c 10 f0       	push   $0xf0101c43
f01008d3:	e8 49 00 00 00       	call   f0100921 <cprintf>
f01008d8:	83 c4 10             	add    $0x10,%esp
f01008db:	e9 e3 fe ff ff       	jmp    f01007c3 <monitor+0x34>
		buf = readline("asdasK>\n");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008e3:	5b                   	pop    %ebx
f01008e4:	5e                   	pop    %esi
f01008e5:	5f                   	pop    %edi
f01008e6:	5d                   	pop    %ebp
f01008e7:	c3                   	ret    

f01008e8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008e8:	55                   	push   %ebp
f01008e9:	89 e5                	mov    %esp,%ebp
f01008eb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008ee:	ff 75 08             	pushl  0x8(%ebp)
f01008f1:	e8 7c fd ff ff       	call   f0100672 <cputchar>
	*cnt++;
}
f01008f6:	83 c4 10             	add    $0x10,%esp
f01008f9:	c9                   	leave  
f01008fa:	c3                   	ret    

f01008fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
f01008fe:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100901:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100908:	ff 75 0c             	pushl  0xc(%ebp)
f010090b:	ff 75 08             	pushl  0x8(%ebp)
f010090e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100911:	50                   	push   %eax
f0100912:	68 e8 08 10 f0       	push   $0xf01008e8
f0100917:	e8 c9 03 00 00       	call   f0100ce5 <vprintfmt>
	return cnt;
}
f010091c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010091f:	c9                   	leave  
f0100920:	c3                   	ret    

f0100921 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100921:	55                   	push   %ebp
f0100922:	89 e5                	mov    %esp,%ebp
f0100924:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100927:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010092a:	50                   	push   %eax
f010092b:	ff 75 08             	pushl  0x8(%ebp)
f010092e:	e8 c8 ff ff ff       	call   f01008fb <vcprintf>
	va_end(ap);

	return cnt;
}
f0100933:	c9                   	leave  
f0100934:	c3                   	ret    

f0100935 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100935:	55                   	push   %ebp
f0100936:	89 e5                	mov    %esp,%ebp
f0100938:	57                   	push   %edi
f0100939:	56                   	push   %esi
f010093a:	53                   	push   %ebx
f010093b:	83 ec 14             	sub    $0x14,%esp
f010093e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100941:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100944:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100947:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010094a:	8b 1a                	mov    (%edx),%ebx
f010094c:	8b 01                	mov    (%ecx),%eax
f010094e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100951:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100958:	eb 7f                	jmp    f01009d9 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010095a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010095d:	01 d8                	add    %ebx,%eax
f010095f:	89 c6                	mov    %eax,%esi
f0100961:	c1 ee 1f             	shr    $0x1f,%esi
f0100964:	01 c6                	add    %eax,%esi
f0100966:	d1 fe                	sar    %esi
f0100968:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010096b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010096e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100971:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100973:	eb 03                	jmp    f0100978 <stab_binsearch+0x43>
			m--;
f0100975:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100978:	39 c3                	cmp    %eax,%ebx
f010097a:	7f 0d                	jg     f0100989 <stab_binsearch+0x54>
f010097c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100980:	83 ea 0c             	sub    $0xc,%edx
f0100983:	39 f9                	cmp    %edi,%ecx
f0100985:	75 ee                	jne    f0100975 <stab_binsearch+0x40>
f0100987:	eb 05                	jmp    f010098e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100989:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010098c:	eb 4b                	jmp    f01009d9 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010098e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100991:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100994:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100998:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010099b:	76 11                	jbe    f01009ae <stab_binsearch+0x79>
			*region_left = m;
f010099d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009a0:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009a2:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009a5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009ac:	eb 2b                	jmp    f01009d9 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009ae:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009b1:	73 14                	jae    f01009c7 <stab_binsearch+0x92>
			*region_right = m - 1;
f01009b3:	83 e8 01             	sub    $0x1,%eax
f01009b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009b9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009bc:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009be:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009c5:	eb 12                	jmp    f01009d9 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009c7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009ca:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009cc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009d0:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009d2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009d9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009dc:	0f 8e 78 ff ff ff    	jle    f010095a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009e2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009e6:	75 0f                	jne    f01009f7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009eb:	8b 00                	mov    (%eax),%eax
f01009ed:	83 e8 01             	sub    $0x1,%eax
f01009f0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009f3:	89 06                	mov    %eax,(%esi)
f01009f5:	eb 2c                	jmp    f0100a23 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009fa:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009fc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009ff:	8b 0e                	mov    (%esi),%ecx
f0100a01:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a04:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a07:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a0a:	eb 03                	jmp    f0100a0f <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a0c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a0f:	39 c8                	cmp    %ecx,%eax
f0100a11:	7e 0b                	jle    f0100a1e <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a13:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a17:	83 ea 0c             	sub    $0xc,%edx
f0100a1a:	39 df                	cmp    %ebx,%edi
f0100a1c:	75 ee                	jne    f0100a0c <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a1e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a21:	89 06                	mov    %eax,(%esi)
	}
}
f0100a23:	83 c4 14             	add    $0x14,%esp
f0100a26:	5b                   	pop    %ebx
f0100a27:	5e                   	pop    %esi
f0100a28:	5f                   	pop    %edi
f0100a29:	5d                   	pop    %ebp
f0100a2a:	c3                   	ret    

f0100a2b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a2b:	55                   	push   %ebp
f0100a2c:	89 e5                	mov    %esp,%ebp
f0100a2e:	57                   	push   %edi
f0100a2f:	56                   	push   %esi
f0100a30:	53                   	push   %ebx
f0100a31:	83 ec 1c             	sub    $0x1c,%esp
f0100a34:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a37:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a3a:	c7 06 cc 1d 10 f0    	movl   $0xf0101dcc,(%esi)
	info->eip_line = 0;
f0100a40:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a47:	c7 46 08 cc 1d 10 f0 	movl   $0xf0101dcc,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a4e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a55:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a58:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a5f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a65:	76 11                	jbe    f0100a78 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a67:	b8 07 72 10 f0       	mov    $0xf0107207,%eax
f0100a6c:	3d 4d 59 10 f0       	cmp    $0xf010594d,%eax
f0100a71:	77 19                	ja     f0100a8c <debuginfo_eip+0x61>
f0100a73:	e9 62 01 00 00       	jmp    f0100bda <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a78:	83 ec 04             	sub    $0x4,%esp
f0100a7b:	68 d6 1d 10 f0       	push   $0xf0101dd6
f0100a80:	6a 7f                	push   $0x7f
f0100a82:	68 e3 1d 10 f0       	push   $0xf0101de3
f0100a87:	e8 5a f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a8c:	80 3d 06 72 10 f0 00 	cmpb   $0x0,0xf0107206
f0100a93:	0f 85 48 01 00 00    	jne    f0100be1 <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a99:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100aa0:	b8 4c 59 10 f0       	mov    $0xf010594c,%eax
f0100aa5:	2d 04 20 10 f0       	sub    $0xf0102004,%eax
f0100aaa:	c1 f8 02             	sar    $0x2,%eax
f0100aad:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ab3:	83 e8 01             	sub    $0x1,%eax
f0100ab6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ab9:	83 ec 08             	sub    $0x8,%esp
f0100abc:	57                   	push   %edi
f0100abd:	6a 64                	push   $0x64
f0100abf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ac2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ac5:	b8 04 20 10 f0       	mov    $0xf0102004,%eax
f0100aca:	e8 66 fe ff ff       	call   f0100935 <stab_binsearch>
	if (lfile == 0)
f0100acf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad2:	83 c4 10             	add    $0x10,%esp
f0100ad5:	85 c0                	test   %eax,%eax
f0100ad7:	0f 84 0b 01 00 00    	je     f0100be8 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100add:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ae3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ae6:	83 ec 08             	sub    $0x8,%esp
f0100ae9:	57                   	push   %edi
f0100aea:	6a 24                	push   $0x24
f0100aec:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aef:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af2:	b8 04 20 10 f0       	mov    $0xf0102004,%eax
f0100af7:	e8 39 fe ff ff       	call   f0100935 <stab_binsearch>

	if (lfun <= rfun) {
f0100afc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100aff:	83 c4 10             	add    $0x10,%esp
f0100b02:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b05:	7f 31                	jg     f0100b38 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b07:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b0a:	c1 e0 02             	shl    $0x2,%eax
f0100b0d:	8d 90 04 20 10 f0    	lea    -0xfefdffc(%eax),%edx
f0100b13:	8b 88 04 20 10 f0    	mov    -0xfefdffc(%eax),%ecx
f0100b19:	b8 07 72 10 f0       	mov    $0xf0107207,%eax
f0100b1e:	2d 4d 59 10 f0       	sub    $0xf010594d,%eax
f0100b23:	39 c1                	cmp    %eax,%ecx
f0100b25:	73 09                	jae    f0100b30 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b27:	81 c1 4d 59 10 f0    	add    $0xf010594d,%ecx
f0100b2d:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b30:	8b 42 08             	mov    0x8(%edx),%eax
f0100b33:	89 46 10             	mov    %eax,0x10(%esi)
f0100b36:	eb 06                	jmp    f0100b3e <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b38:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b3b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b3e:	83 ec 08             	sub    $0x8,%esp
f0100b41:	6a 3a                	push   $0x3a
f0100b43:	ff 76 08             	pushl  0x8(%esi)
f0100b46:	e8 cb 08 00 00       	call   f0101416 <strfind>
f0100b4b:	2b 46 08             	sub    0x8(%esi),%eax
f0100b4e:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b54:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b57:	8d 04 85 04 20 10 f0 	lea    -0xfefdffc(,%eax,4),%eax
f0100b5e:	83 c4 10             	add    $0x10,%esp
f0100b61:	eb 06                	jmp    f0100b69 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b63:	83 eb 01             	sub    $0x1,%ebx
f0100b66:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b69:	39 fb                	cmp    %edi,%ebx
f0100b6b:	7c 34                	jl     f0100ba1 <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b6d:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b71:	80 fa 84             	cmp    $0x84,%dl
f0100b74:	74 0b                	je     f0100b81 <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b76:	80 fa 64             	cmp    $0x64,%dl
f0100b79:	75 e8                	jne    f0100b63 <debuginfo_eip+0x138>
f0100b7b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b7f:	74 e2                	je     f0100b63 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b81:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b84:	8b 14 85 04 20 10 f0 	mov    -0xfefdffc(,%eax,4),%edx
f0100b8b:	b8 07 72 10 f0       	mov    $0xf0107207,%eax
f0100b90:	2d 4d 59 10 f0       	sub    $0xf010594d,%eax
f0100b95:	39 c2                	cmp    %eax,%edx
f0100b97:	73 08                	jae    f0100ba1 <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b99:	81 c2 4d 59 10 f0    	add    $0xf010594d,%edx
f0100b9f:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ba1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ba4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ba7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bac:	39 cb                	cmp    %ecx,%ebx
f0100bae:	7d 44                	jge    f0100bf4 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100bb0:	8d 53 01             	lea    0x1(%ebx),%edx
f0100bb3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bb6:	8d 04 85 04 20 10 f0 	lea    -0xfefdffc(,%eax,4),%eax
f0100bbd:	eb 07                	jmp    f0100bc6 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bbf:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bc3:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bc6:	39 ca                	cmp    %ecx,%edx
f0100bc8:	74 25                	je     f0100bef <debuginfo_eip+0x1c4>
f0100bca:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bcd:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bd1:	74 ec                	je     f0100bbf <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bd8:	eb 1a                	jmp    f0100bf4 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bda:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bdf:	eb 13                	jmp    f0100bf4 <debuginfo_eip+0x1c9>
f0100be1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be6:	eb 0c                	jmp    f0100bf4 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100be8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bed:	eb 05                	jmp    f0100bf4 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bf4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bf7:	5b                   	pop    %ebx
f0100bf8:	5e                   	pop    %esi
f0100bf9:	5f                   	pop    %edi
f0100bfa:	5d                   	pop    %ebp
f0100bfb:	c3                   	ret    

f0100bfc <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bfc:	55                   	push   %ebp
f0100bfd:	89 e5                	mov    %esp,%ebp
f0100bff:	57                   	push   %edi
f0100c00:	56                   	push   %esi
f0100c01:	53                   	push   %ebx
f0100c02:	83 ec 1c             	sub    $0x1c,%esp
f0100c05:	89 c7                	mov    %eax,%edi
f0100c07:	89 d6                	mov    %edx,%esi
f0100c09:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c0c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c0f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c12:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c15:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c18:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c1d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c20:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c23:	39 d3                	cmp    %edx,%ebx
f0100c25:	72 05                	jb     f0100c2c <printnum+0x30>
f0100c27:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c2a:	77 45                	ja     f0100c71 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c2c:	83 ec 0c             	sub    $0xc,%esp
f0100c2f:	ff 75 18             	pushl  0x18(%ebp)
f0100c32:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c35:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c38:	53                   	push   %ebx
f0100c39:	ff 75 10             	pushl  0x10(%ebp)
f0100c3c:	83 ec 08             	sub    $0x8,%esp
f0100c3f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c42:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c45:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c48:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c4b:	e8 f0 09 00 00       	call   f0101640 <__udivdi3>
f0100c50:	83 c4 18             	add    $0x18,%esp
f0100c53:	52                   	push   %edx
f0100c54:	50                   	push   %eax
f0100c55:	89 f2                	mov    %esi,%edx
f0100c57:	89 f8                	mov    %edi,%eax
f0100c59:	e8 9e ff ff ff       	call   f0100bfc <printnum>
f0100c5e:	83 c4 20             	add    $0x20,%esp
f0100c61:	eb 18                	jmp    f0100c7b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c63:	83 ec 08             	sub    $0x8,%esp
f0100c66:	56                   	push   %esi
f0100c67:	ff 75 18             	pushl  0x18(%ebp)
f0100c6a:	ff d7                	call   *%edi
f0100c6c:	83 c4 10             	add    $0x10,%esp
f0100c6f:	eb 03                	jmp    f0100c74 <printnum+0x78>
f0100c71:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c74:	83 eb 01             	sub    $0x1,%ebx
f0100c77:	85 db                	test   %ebx,%ebx
f0100c79:	7f e8                	jg     f0100c63 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c7b:	83 ec 08             	sub    $0x8,%esp
f0100c7e:	56                   	push   %esi
f0100c7f:	83 ec 04             	sub    $0x4,%esp
f0100c82:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c85:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c88:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c8b:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c8e:	e8 dd 0a 00 00       	call   f0101770 <__umoddi3>
f0100c93:	83 c4 14             	add    $0x14,%esp
f0100c96:	0f be 80 f1 1d 10 f0 	movsbl -0xfefe20f(%eax),%eax
f0100c9d:	50                   	push   %eax
f0100c9e:	ff d7                	call   *%edi
}
f0100ca0:	83 c4 10             	add    $0x10,%esp
f0100ca3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ca6:	5b                   	pop    %ebx
f0100ca7:	5e                   	pop    %esi
f0100ca8:	5f                   	pop    %edi
f0100ca9:	5d                   	pop    %ebp
f0100caa:	c3                   	ret    

f0100cab <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cab:	55                   	push   %ebp
f0100cac:	89 e5                	mov    %esp,%ebp
f0100cae:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cb1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cb5:	8b 10                	mov    (%eax),%edx
f0100cb7:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cba:	73 0a                	jae    f0100cc6 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100cbc:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100cbf:	89 08                	mov    %ecx,(%eax)
f0100cc1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc4:	88 02                	mov    %al,(%edx)
}
f0100cc6:	5d                   	pop    %ebp
f0100cc7:	c3                   	ret    

f0100cc8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100cc8:	55                   	push   %ebp
f0100cc9:	89 e5                	mov    %esp,%ebp
f0100ccb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100cce:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100cd1:	50                   	push   %eax
f0100cd2:	ff 75 10             	pushl  0x10(%ebp)
f0100cd5:	ff 75 0c             	pushl  0xc(%ebp)
f0100cd8:	ff 75 08             	pushl  0x8(%ebp)
f0100cdb:	e8 05 00 00 00       	call   f0100ce5 <vprintfmt>
	va_end(ap);
}
f0100ce0:	83 c4 10             	add    $0x10,%esp
f0100ce3:	c9                   	leave  
f0100ce4:	c3                   	ret    

f0100ce5 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ce5:	55                   	push   %ebp
f0100ce6:	89 e5                	mov    %esp,%ebp
f0100ce8:	57                   	push   %edi
f0100ce9:	56                   	push   %esi
f0100cea:	53                   	push   %ebx
f0100ceb:	83 ec 2c             	sub    $0x2c,%esp
f0100cee:	8b 75 08             	mov    0x8(%ebp),%esi
f0100cf1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100cf4:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100cf7:	eb 12                	jmp    f0100d0b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100cf9:	85 c0                	test   %eax,%eax
f0100cfb:	0f 84 6a 04 00 00    	je     f010116b <vprintfmt+0x486>
				return;
			putch(ch, putdat);
f0100d01:	83 ec 08             	sub    $0x8,%esp
f0100d04:	53                   	push   %ebx
f0100d05:	50                   	push   %eax
f0100d06:	ff d6                	call   *%esi
f0100d08:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d0b:	83 c7 01             	add    $0x1,%edi
f0100d0e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d12:	83 f8 25             	cmp    $0x25,%eax
f0100d15:	75 e2                	jne    f0100cf9 <vprintfmt+0x14>
f0100d17:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d1b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100d22:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100d29:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100d30:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d35:	eb 07                	jmp    f0100d3e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d37:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100d3a:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d3e:	8d 47 01             	lea    0x1(%edi),%eax
f0100d41:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d44:	0f b6 07             	movzbl (%edi),%eax
f0100d47:	0f b6 d0             	movzbl %al,%edx
f0100d4a:	83 e8 23             	sub    $0x23,%eax
f0100d4d:	3c 55                	cmp    $0x55,%al
f0100d4f:	0f 87 fb 03 00 00    	ja     f0101150 <vprintfmt+0x46b>
f0100d55:	0f b6 c0             	movzbl %al,%eax
f0100d58:	ff 24 85 80 1e 10 f0 	jmp    *-0xfefe180(,%eax,4)
f0100d5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100d62:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100d66:	eb d6                	jmp    f0100d3e <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d70:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100d73:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d76:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100d7a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100d7d:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100d80:	83 f9 09             	cmp    $0x9,%ecx
f0100d83:	77 3f                	ja     f0100dc4 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100d85:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100d88:	eb e9                	jmp    f0100d73 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100d8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d8d:	8b 00                	mov    (%eax),%eax
f0100d8f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d92:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d95:	8d 40 04             	lea    0x4(%eax),%eax
f0100d98:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d9b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100d9e:	eb 2a                	jmp    f0100dca <vprintfmt+0xe5>
f0100da0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100da3:	85 c0                	test   %eax,%eax
f0100da5:	ba 00 00 00 00       	mov    $0x0,%edx
f0100daa:	0f 49 d0             	cmovns %eax,%edx
f0100dad:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100db3:	eb 89                	jmp    f0100d3e <vprintfmt+0x59>
f0100db5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100db8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100dbf:	e9 7a ff ff ff       	jmp    f0100d3e <vprintfmt+0x59>
f0100dc4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100dc7:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100dca:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100dce:	0f 89 6a ff ff ff    	jns    f0100d3e <vprintfmt+0x59>
				width = precision, precision = -1;
f0100dd4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100dd7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dda:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100de1:	e9 58 ff ff ff       	jmp    f0100d3e <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100de6:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100dec:	e9 4d ff ff ff       	jmp    f0100d3e <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100df1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100df4:	8d 78 04             	lea    0x4(%eax),%edi
f0100df7:	83 ec 08             	sub    $0x8,%esp
f0100dfa:	53                   	push   %ebx
f0100dfb:	ff 30                	pushl  (%eax)
f0100dfd:	ff d6                	call   *%esi
			break;
f0100dff:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e02:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e08:	e9 fe fe ff ff       	jmp    f0100d0b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e10:	8d 78 04             	lea    0x4(%eax),%edi
f0100e13:	8b 00                	mov    (%eax),%eax
f0100e15:	99                   	cltd   
f0100e16:	31 d0                	xor    %edx,%eax
f0100e18:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e1a:	83 f8 06             	cmp    $0x6,%eax
f0100e1d:	7f 0b                	jg     f0100e2a <vprintfmt+0x145>
f0100e1f:	8b 14 85 d8 1f 10 f0 	mov    -0xfefe028(,%eax,4),%edx
f0100e26:	85 d2                	test   %edx,%edx
f0100e28:	75 1b                	jne    f0100e45 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100e2a:	50                   	push   %eax
f0100e2b:	68 09 1e 10 f0       	push   $0xf0101e09
f0100e30:	53                   	push   %ebx
f0100e31:	56                   	push   %esi
f0100e32:	e8 91 fe ff ff       	call   f0100cc8 <printfmt>
f0100e37:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e3a:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100e40:	e9 c6 fe ff ff       	jmp    f0100d0b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100e45:	52                   	push   %edx
f0100e46:	68 12 1e 10 f0       	push   $0xf0101e12
f0100e4b:	53                   	push   %ebx
f0100e4c:	56                   	push   %esi
f0100e4d:	e8 76 fe ff ff       	call   f0100cc8 <printfmt>
f0100e52:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e55:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e5b:	e9 ab fe ff ff       	jmp    f0100d0b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100e60:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e63:	83 c0 04             	add    $0x4,%eax
f0100e66:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e69:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e6c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100e6e:	85 ff                	test   %edi,%edi
f0100e70:	b8 02 1e 10 f0       	mov    $0xf0101e02,%eax
f0100e75:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100e78:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e7c:	0f 8e 94 00 00 00    	jle    f0100f16 <vprintfmt+0x231>
f0100e82:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100e86:	0f 84 98 00 00 00    	je     f0100f24 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100e8c:	83 ec 08             	sub    $0x8,%esp
f0100e8f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e92:	57                   	push   %edi
f0100e93:	e8 34 04 00 00       	call   f01012cc <strnlen>
f0100e98:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e9b:	29 c1                	sub    %eax,%ecx
f0100e9d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100ea0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100ea3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100ea7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100eaa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ead:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100eaf:	eb 0f                	jmp    f0100ec0 <vprintfmt+0x1db>
					putch(padc, putdat);
f0100eb1:	83 ec 08             	sub    $0x8,%esp
f0100eb4:	53                   	push   %ebx
f0100eb5:	ff 75 e0             	pushl  -0x20(%ebp)
f0100eb8:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100eba:	83 ef 01             	sub    $0x1,%edi
f0100ebd:	83 c4 10             	add    $0x10,%esp
f0100ec0:	85 ff                	test   %edi,%edi
f0100ec2:	7f ed                	jg     f0100eb1 <vprintfmt+0x1cc>
f0100ec4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100ec7:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100eca:	85 c9                	test   %ecx,%ecx
f0100ecc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed1:	0f 49 c1             	cmovns %ecx,%eax
f0100ed4:	29 c1                	sub    %eax,%ecx
f0100ed6:	89 75 08             	mov    %esi,0x8(%ebp)
f0100ed9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100edc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100edf:	89 cb                	mov    %ecx,%ebx
f0100ee1:	eb 4d                	jmp    f0100f30 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100ee3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ee7:	74 1b                	je     f0100f04 <vprintfmt+0x21f>
f0100ee9:	0f be c0             	movsbl %al,%eax
f0100eec:	83 e8 20             	sub    $0x20,%eax
f0100eef:	83 f8 5e             	cmp    $0x5e,%eax
f0100ef2:	76 10                	jbe    f0100f04 <vprintfmt+0x21f>
					putch('?', putdat);
f0100ef4:	83 ec 08             	sub    $0x8,%esp
f0100ef7:	ff 75 0c             	pushl  0xc(%ebp)
f0100efa:	6a 3f                	push   $0x3f
f0100efc:	ff 55 08             	call   *0x8(%ebp)
f0100eff:	83 c4 10             	add    $0x10,%esp
f0100f02:	eb 0d                	jmp    f0100f11 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100f04:	83 ec 08             	sub    $0x8,%esp
f0100f07:	ff 75 0c             	pushl  0xc(%ebp)
f0100f0a:	52                   	push   %edx
f0100f0b:	ff 55 08             	call   *0x8(%ebp)
f0100f0e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f11:	83 eb 01             	sub    $0x1,%ebx
f0100f14:	eb 1a                	jmp    f0100f30 <vprintfmt+0x24b>
f0100f16:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f19:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f1c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f1f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f22:	eb 0c                	jmp    f0100f30 <vprintfmt+0x24b>
f0100f24:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f27:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f2a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f2d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100f30:	83 c7 01             	add    $0x1,%edi
f0100f33:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f37:	0f be d0             	movsbl %al,%edx
f0100f3a:	85 d2                	test   %edx,%edx
f0100f3c:	74 23                	je     f0100f61 <vprintfmt+0x27c>
f0100f3e:	85 f6                	test   %esi,%esi
f0100f40:	78 a1                	js     f0100ee3 <vprintfmt+0x1fe>
f0100f42:	83 ee 01             	sub    $0x1,%esi
f0100f45:	79 9c                	jns    f0100ee3 <vprintfmt+0x1fe>
f0100f47:	89 df                	mov    %ebx,%edi
f0100f49:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f4c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f4f:	eb 18                	jmp    f0100f69 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100f51:	83 ec 08             	sub    $0x8,%esp
f0100f54:	53                   	push   %ebx
f0100f55:	6a 20                	push   $0x20
f0100f57:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100f59:	83 ef 01             	sub    $0x1,%edi
f0100f5c:	83 c4 10             	add    $0x10,%esp
f0100f5f:	eb 08                	jmp    f0100f69 <vprintfmt+0x284>
f0100f61:	89 df                	mov    %ebx,%edi
f0100f63:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f66:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f69:	85 ff                	test   %edi,%edi
f0100f6b:	7f e4                	jg     f0100f51 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f6d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f70:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f76:	e9 90 fd ff ff       	jmp    f0100d0b <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100f7b:	83 f9 01             	cmp    $0x1,%ecx
f0100f7e:	7e 19                	jle    f0100f99 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0100f80:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f83:	8b 50 04             	mov    0x4(%eax),%edx
f0100f86:	8b 00                	mov    (%eax),%eax
f0100f88:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f8b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f91:	8d 40 08             	lea    0x8(%eax),%eax
f0100f94:	89 45 14             	mov    %eax,0x14(%ebp)
f0100f97:	eb 38                	jmp    f0100fd1 <vprintfmt+0x2ec>
	else if (lflag)
f0100f99:	85 c9                	test   %ecx,%ecx
f0100f9b:	74 1b                	je     f0100fb8 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0100f9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa0:	8b 00                	mov    (%eax),%eax
f0100fa2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fa5:	89 c1                	mov    %eax,%ecx
f0100fa7:	c1 f9 1f             	sar    $0x1f,%ecx
f0100faa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fad:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb0:	8d 40 04             	lea    0x4(%eax),%eax
f0100fb3:	89 45 14             	mov    %eax,0x14(%ebp)
f0100fb6:	eb 19                	jmp    f0100fd1 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0100fb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fbb:	8b 00                	mov    (%eax),%eax
f0100fbd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100fc0:	89 c1                	mov    %eax,%ecx
f0100fc2:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fc5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100fc8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fcb:	8d 40 04             	lea    0x4(%eax),%eax
f0100fce:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100fd1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fd4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100fd7:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100fdc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fe0:	0f 89 36 01 00 00    	jns    f010111c <vprintfmt+0x437>
				putch('-', putdat);
f0100fe6:	83 ec 08             	sub    $0x8,%esp
f0100fe9:	53                   	push   %ebx
f0100fea:	6a 2d                	push   $0x2d
f0100fec:	ff d6                	call   *%esi
				num = -(long long) num;
f0100fee:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ff1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ff4:	f7 da                	neg    %edx
f0100ff6:	83 d1 00             	adc    $0x0,%ecx
f0100ff9:	f7 d9                	neg    %ecx
f0100ffb:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0100ffe:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101003:	e9 14 01 00 00       	jmp    f010111c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101008:	83 f9 01             	cmp    $0x1,%ecx
f010100b:	7e 18                	jle    f0101025 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010100d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101010:	8b 10                	mov    (%eax),%edx
f0101012:	8b 48 04             	mov    0x4(%eax),%ecx
f0101015:	8d 40 08             	lea    0x8(%eax),%eax
f0101018:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010101b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101020:	e9 f7 00 00 00       	jmp    f010111c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101025:	85 c9                	test   %ecx,%ecx
f0101027:	74 1a                	je     f0101043 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0101029:	8b 45 14             	mov    0x14(%ebp),%eax
f010102c:	8b 10                	mov    (%eax),%edx
f010102e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101033:	8d 40 04             	lea    0x4(%eax),%eax
f0101036:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101039:	b8 0a 00 00 00       	mov    $0xa,%eax
f010103e:	e9 d9 00 00 00       	jmp    f010111c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101043:	8b 45 14             	mov    0x14(%ebp),%eax
f0101046:	8b 10                	mov    (%eax),%edx
f0101048:	b9 00 00 00 00       	mov    $0x0,%ecx
f010104d:	8d 40 04             	lea    0x4(%eax),%eax
f0101050:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101053:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101058:	e9 bf 00 00 00       	jmp    f010111c <vprintfmt+0x437>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010105d:	83 f9 01             	cmp    $0x1,%ecx
f0101060:	7e 13                	jle    f0101075 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f0101062:	8b 45 14             	mov    0x14(%ebp),%eax
f0101065:	8b 50 04             	mov    0x4(%eax),%edx
f0101068:	8b 00                	mov    (%eax),%eax
f010106a:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010106d:	8d 49 08             	lea    0x8(%ecx),%ecx
f0101070:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101073:	eb 28                	jmp    f010109d <vprintfmt+0x3b8>
	else if (lflag)
f0101075:	85 c9                	test   %ecx,%ecx
f0101077:	74 13                	je     f010108c <vprintfmt+0x3a7>
		return va_arg(*ap, long);
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8b 10                	mov    (%eax),%edx
f010107e:	89 d0                	mov    %edx,%eax
f0101080:	99                   	cltd   
f0101081:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101084:	8d 49 04             	lea    0x4(%ecx),%ecx
f0101087:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010108a:	eb 11                	jmp    f010109d <vprintfmt+0x3b8>
	else
		return va_arg(*ap, int);
f010108c:	8b 45 14             	mov    0x14(%ebp),%eax
f010108f:	8b 10                	mov    (%eax),%edx
f0101091:	89 d0                	mov    %edx,%eax
f0101093:	99                   	cltd   
f0101094:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101097:	8d 49 04             	lea    0x4(%ecx),%ecx
f010109a:	89 4d 14             	mov    %ecx,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getint(&ap,lflag);
f010109d:	89 d1                	mov    %edx,%ecx
f010109f:	89 c2                	mov    %eax,%edx
			base = 8;
f01010a1:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f01010a6:	eb 74                	jmp    f010111c <vprintfmt+0x437>

		// pointer
		case 'p':
			putch('0', putdat);
f01010a8:	83 ec 08             	sub    $0x8,%esp
f01010ab:	53                   	push   %ebx
f01010ac:	6a 30                	push   $0x30
f01010ae:	ff d6                	call   *%esi
			putch('x', putdat);
f01010b0:	83 c4 08             	add    $0x8,%esp
f01010b3:	53                   	push   %ebx
f01010b4:	6a 78                	push   $0x78
f01010b6:	ff d6                	call   *%esi
			num = (unsigned long long)
f01010b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010bb:	8b 10                	mov    (%eax),%edx
f01010bd:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010c2:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010c5:	8d 40 04             	lea    0x4(%eax),%eax
f01010c8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01010cb:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01010d0:	eb 4a                	jmp    f010111c <vprintfmt+0x437>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010d2:	83 f9 01             	cmp    $0x1,%ecx
f01010d5:	7e 15                	jle    f01010ec <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
f01010d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010da:	8b 10                	mov    (%eax),%edx
f01010dc:	8b 48 04             	mov    0x4(%eax),%ecx
f01010df:	8d 40 08             	lea    0x8(%eax),%eax
f01010e2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01010e5:	b8 10 00 00 00       	mov    $0x10,%eax
f01010ea:	eb 30                	jmp    f010111c <vprintfmt+0x437>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010ec:	85 c9                	test   %ecx,%ecx
f01010ee:	74 17                	je     f0101107 <vprintfmt+0x422>
		return va_arg(*ap, unsigned long);
f01010f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f3:	8b 10                	mov    (%eax),%edx
f01010f5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010fa:	8d 40 04             	lea    0x4(%eax),%eax
f01010fd:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101100:	b8 10 00 00 00       	mov    $0x10,%eax
f0101105:	eb 15                	jmp    f010111c <vprintfmt+0x437>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101107:	8b 45 14             	mov    0x14(%ebp),%eax
f010110a:	8b 10                	mov    (%eax),%edx
f010110c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101111:	8d 40 04             	lea    0x4(%eax),%eax
f0101114:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101117:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010111c:	83 ec 0c             	sub    $0xc,%esp
f010111f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101123:	57                   	push   %edi
f0101124:	ff 75 e0             	pushl  -0x20(%ebp)
f0101127:	50                   	push   %eax
f0101128:	51                   	push   %ecx
f0101129:	52                   	push   %edx
f010112a:	89 da                	mov    %ebx,%edx
f010112c:	89 f0                	mov    %esi,%eax
f010112e:	e8 c9 fa ff ff       	call   f0100bfc <printnum>
			break;
f0101133:	83 c4 20             	add    $0x20,%esp
f0101136:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101139:	e9 cd fb ff ff       	jmp    f0100d0b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010113e:	83 ec 08             	sub    $0x8,%esp
f0101141:	53                   	push   %ebx
f0101142:	52                   	push   %edx
f0101143:	ff d6                	call   *%esi
			break;
f0101145:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101148:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010114b:	e9 bb fb ff ff       	jmp    f0100d0b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101150:	83 ec 08             	sub    $0x8,%esp
f0101153:	53                   	push   %ebx
f0101154:	6a 25                	push   $0x25
f0101156:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101158:	83 c4 10             	add    $0x10,%esp
f010115b:	eb 03                	jmp    f0101160 <vprintfmt+0x47b>
f010115d:	83 ef 01             	sub    $0x1,%edi
f0101160:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101164:	75 f7                	jne    f010115d <vprintfmt+0x478>
f0101166:	e9 a0 fb ff ff       	jmp    f0100d0b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010116b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010116e:	5b                   	pop    %ebx
f010116f:	5e                   	pop    %esi
f0101170:	5f                   	pop    %edi
f0101171:	5d                   	pop    %ebp
f0101172:	c3                   	ret    

f0101173 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101173:	55                   	push   %ebp
f0101174:	89 e5                	mov    %esp,%ebp
f0101176:	83 ec 18             	sub    $0x18,%esp
f0101179:	8b 45 08             	mov    0x8(%ebp),%eax
f010117c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010117f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101182:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101186:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101189:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101190:	85 c0                	test   %eax,%eax
f0101192:	74 26                	je     f01011ba <vsnprintf+0x47>
f0101194:	85 d2                	test   %edx,%edx
f0101196:	7e 22                	jle    f01011ba <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101198:	ff 75 14             	pushl  0x14(%ebp)
f010119b:	ff 75 10             	pushl  0x10(%ebp)
f010119e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011a1:	50                   	push   %eax
f01011a2:	68 ab 0c 10 f0       	push   $0xf0100cab
f01011a7:	e8 39 fb ff ff       	call   f0100ce5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011af:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b5:	83 c4 10             	add    $0x10,%esp
f01011b8:	eb 05                	jmp    f01011bf <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ba:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011bf:	c9                   	leave  
f01011c0:	c3                   	ret    

f01011c1 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011c1:	55                   	push   %ebp
f01011c2:	89 e5                	mov    %esp,%ebp
f01011c4:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011c7:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011ca:	50                   	push   %eax
f01011cb:	ff 75 10             	pushl  0x10(%ebp)
f01011ce:	ff 75 0c             	pushl  0xc(%ebp)
f01011d1:	ff 75 08             	pushl  0x8(%ebp)
f01011d4:	e8 9a ff ff ff       	call   f0101173 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011d9:	c9                   	leave  
f01011da:	c3                   	ret    

f01011db <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011db:	55                   	push   %ebp
f01011dc:	89 e5                	mov    %esp,%ebp
f01011de:	57                   	push   %edi
f01011df:	56                   	push   %esi
f01011e0:	53                   	push   %ebx
f01011e1:	83 ec 0c             	sub    $0xc,%esp
f01011e4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011e7:	85 c0                	test   %eax,%eax
f01011e9:	74 11                	je     f01011fc <readline+0x21>
		cprintf("%s", prompt);
f01011eb:	83 ec 08             	sub    $0x8,%esp
f01011ee:	50                   	push   %eax
f01011ef:	68 12 1e 10 f0       	push   $0xf0101e12
f01011f4:	e8 28 f7 ff ff       	call   f0100921 <cprintf>
f01011f9:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011fc:	83 ec 0c             	sub    $0xc,%esp
f01011ff:	6a 00                	push   $0x0
f0101201:	e8 8d f4 ff ff       	call   f0100693 <iscons>
f0101206:	89 c7                	mov    %eax,%edi
f0101208:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010120b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101210:	e8 6d f4 ff ff       	call   f0100682 <getchar>
f0101215:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101217:	85 c0                	test   %eax,%eax
f0101219:	79 18                	jns    f0101233 <readline+0x58>
			cprintf("read error: %e\n", c);
f010121b:	83 ec 08             	sub    $0x8,%esp
f010121e:	50                   	push   %eax
f010121f:	68 f4 1f 10 f0       	push   $0xf0101ff4
f0101224:	e8 f8 f6 ff ff       	call   f0100921 <cprintf>
			return NULL;
f0101229:	83 c4 10             	add    $0x10,%esp
f010122c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101231:	eb 79                	jmp    f01012ac <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101233:	83 f8 08             	cmp    $0x8,%eax
f0101236:	0f 94 c2             	sete   %dl
f0101239:	83 f8 7f             	cmp    $0x7f,%eax
f010123c:	0f 94 c0             	sete   %al
f010123f:	08 c2                	or     %al,%dl
f0101241:	74 1a                	je     f010125d <readline+0x82>
f0101243:	85 f6                	test   %esi,%esi
f0101245:	7e 16                	jle    f010125d <readline+0x82>
			if (echoing)
f0101247:	85 ff                	test   %edi,%edi
f0101249:	74 0d                	je     f0101258 <readline+0x7d>
				cputchar('\b');
f010124b:	83 ec 0c             	sub    $0xc,%esp
f010124e:	6a 08                	push   $0x8
f0101250:	e8 1d f4 ff ff       	call   f0100672 <cputchar>
f0101255:	83 c4 10             	add    $0x10,%esp
			i--;
f0101258:	83 ee 01             	sub    $0x1,%esi
f010125b:	eb b3                	jmp    f0101210 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010125d:	83 fb 1f             	cmp    $0x1f,%ebx
f0101260:	7e 23                	jle    f0101285 <readline+0xaa>
f0101262:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101268:	7f 1b                	jg     f0101285 <readline+0xaa>
			if (echoing)
f010126a:	85 ff                	test   %edi,%edi
f010126c:	74 0c                	je     f010127a <readline+0x9f>
				cputchar(c);
f010126e:	83 ec 0c             	sub    $0xc,%esp
f0101271:	53                   	push   %ebx
f0101272:	e8 fb f3 ff ff       	call   f0100672 <cputchar>
f0101277:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010127a:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101280:	8d 76 01             	lea    0x1(%esi),%esi
f0101283:	eb 8b                	jmp    f0101210 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101285:	83 fb 0a             	cmp    $0xa,%ebx
f0101288:	74 05                	je     f010128f <readline+0xb4>
f010128a:	83 fb 0d             	cmp    $0xd,%ebx
f010128d:	75 81                	jne    f0101210 <readline+0x35>
			if (echoing)
f010128f:	85 ff                	test   %edi,%edi
f0101291:	74 0d                	je     f01012a0 <readline+0xc5>
				cputchar('\n');
f0101293:	83 ec 0c             	sub    $0xc,%esp
f0101296:	6a 0a                	push   $0xa
f0101298:	e8 d5 f3 ff ff       	call   f0100672 <cputchar>
f010129d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012a0:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012a7:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012af:	5b                   	pop    %ebx
f01012b0:	5e                   	pop    %esi
f01012b1:	5f                   	pop    %edi
f01012b2:	5d                   	pop    %ebp
f01012b3:	c3                   	ret    

f01012b4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012b4:	55                   	push   %ebp
f01012b5:	89 e5                	mov    %esp,%ebp
f01012b7:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01012bf:	eb 03                	jmp    f01012c4 <strlen+0x10>
		n++;
f01012c1:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012c4:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012c8:	75 f7                	jne    f01012c1 <strlen+0xd>
		n++;
	return n;
}
f01012ca:	5d                   	pop    %ebp
f01012cb:	c3                   	ret    

f01012cc <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012cc:	55                   	push   %ebp
f01012cd:	89 e5                	mov    %esp,%ebp
f01012cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012d2:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012d5:	ba 00 00 00 00       	mov    $0x0,%edx
f01012da:	eb 03                	jmp    f01012df <strnlen+0x13>
		n++;
f01012dc:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012df:	39 c2                	cmp    %eax,%edx
f01012e1:	74 08                	je     f01012eb <strnlen+0x1f>
f01012e3:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012e7:	75 f3                	jne    f01012dc <strnlen+0x10>
f01012e9:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012eb:	5d                   	pop    %ebp
f01012ec:	c3                   	ret    

f01012ed <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012ed:	55                   	push   %ebp
f01012ee:	89 e5                	mov    %esp,%ebp
f01012f0:	53                   	push   %ebx
f01012f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012f7:	89 c2                	mov    %eax,%edx
f01012f9:	83 c2 01             	add    $0x1,%edx
f01012fc:	83 c1 01             	add    $0x1,%ecx
f01012ff:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101303:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101306:	84 db                	test   %bl,%bl
f0101308:	75 ef                	jne    f01012f9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010130a:	5b                   	pop    %ebx
f010130b:	5d                   	pop    %ebp
f010130c:	c3                   	ret    

f010130d <strcat>:

char *
strcat(char *dst, const char *src)
{
f010130d:	55                   	push   %ebp
f010130e:	89 e5                	mov    %esp,%ebp
f0101310:	53                   	push   %ebx
f0101311:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101314:	53                   	push   %ebx
f0101315:	e8 9a ff ff ff       	call   f01012b4 <strlen>
f010131a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010131d:	ff 75 0c             	pushl  0xc(%ebp)
f0101320:	01 d8                	add    %ebx,%eax
f0101322:	50                   	push   %eax
f0101323:	e8 c5 ff ff ff       	call   f01012ed <strcpy>
	return dst;
}
f0101328:	89 d8                	mov    %ebx,%eax
f010132a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010132d:	c9                   	leave  
f010132e:	c3                   	ret    

f010132f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010132f:	55                   	push   %ebp
f0101330:	89 e5                	mov    %esp,%ebp
f0101332:	56                   	push   %esi
f0101333:	53                   	push   %ebx
f0101334:	8b 75 08             	mov    0x8(%ebp),%esi
f0101337:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010133a:	89 f3                	mov    %esi,%ebx
f010133c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010133f:	89 f2                	mov    %esi,%edx
f0101341:	eb 0f                	jmp    f0101352 <strncpy+0x23>
		*dst++ = *src;
f0101343:	83 c2 01             	add    $0x1,%edx
f0101346:	0f b6 01             	movzbl (%ecx),%eax
f0101349:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010134c:	80 39 01             	cmpb   $0x1,(%ecx)
f010134f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101352:	39 da                	cmp    %ebx,%edx
f0101354:	75 ed                	jne    f0101343 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101356:	89 f0                	mov    %esi,%eax
f0101358:	5b                   	pop    %ebx
f0101359:	5e                   	pop    %esi
f010135a:	5d                   	pop    %ebp
f010135b:	c3                   	ret    

f010135c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010135c:	55                   	push   %ebp
f010135d:	89 e5                	mov    %esp,%ebp
f010135f:	56                   	push   %esi
f0101360:	53                   	push   %ebx
f0101361:	8b 75 08             	mov    0x8(%ebp),%esi
f0101364:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101367:	8b 55 10             	mov    0x10(%ebp),%edx
f010136a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010136c:	85 d2                	test   %edx,%edx
f010136e:	74 21                	je     f0101391 <strlcpy+0x35>
f0101370:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101374:	89 f2                	mov    %esi,%edx
f0101376:	eb 09                	jmp    f0101381 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101378:	83 c2 01             	add    $0x1,%edx
f010137b:	83 c1 01             	add    $0x1,%ecx
f010137e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101381:	39 c2                	cmp    %eax,%edx
f0101383:	74 09                	je     f010138e <strlcpy+0x32>
f0101385:	0f b6 19             	movzbl (%ecx),%ebx
f0101388:	84 db                	test   %bl,%bl
f010138a:	75 ec                	jne    f0101378 <strlcpy+0x1c>
f010138c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010138e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101391:	29 f0                	sub    %esi,%eax
}
f0101393:	5b                   	pop    %ebx
f0101394:	5e                   	pop    %esi
f0101395:	5d                   	pop    %ebp
f0101396:	c3                   	ret    

f0101397 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101397:	55                   	push   %ebp
f0101398:	89 e5                	mov    %esp,%ebp
f010139a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010139d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013a0:	eb 06                	jmp    f01013a8 <strcmp+0x11>
		p++, q++;
f01013a2:	83 c1 01             	add    $0x1,%ecx
f01013a5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013a8:	0f b6 01             	movzbl (%ecx),%eax
f01013ab:	84 c0                	test   %al,%al
f01013ad:	74 04                	je     f01013b3 <strcmp+0x1c>
f01013af:	3a 02                	cmp    (%edx),%al
f01013b1:	74 ef                	je     f01013a2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013b3:	0f b6 c0             	movzbl %al,%eax
f01013b6:	0f b6 12             	movzbl (%edx),%edx
f01013b9:	29 d0                	sub    %edx,%eax
}
f01013bb:	5d                   	pop    %ebp
f01013bc:	c3                   	ret    

f01013bd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013bd:	55                   	push   %ebp
f01013be:	89 e5                	mov    %esp,%ebp
f01013c0:	53                   	push   %ebx
f01013c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013c7:	89 c3                	mov    %eax,%ebx
f01013c9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013cc:	eb 06                	jmp    f01013d4 <strncmp+0x17>
		n--, p++, q++;
f01013ce:	83 c0 01             	add    $0x1,%eax
f01013d1:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013d4:	39 d8                	cmp    %ebx,%eax
f01013d6:	74 15                	je     f01013ed <strncmp+0x30>
f01013d8:	0f b6 08             	movzbl (%eax),%ecx
f01013db:	84 c9                	test   %cl,%cl
f01013dd:	74 04                	je     f01013e3 <strncmp+0x26>
f01013df:	3a 0a                	cmp    (%edx),%cl
f01013e1:	74 eb                	je     f01013ce <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013e3:	0f b6 00             	movzbl (%eax),%eax
f01013e6:	0f b6 12             	movzbl (%edx),%edx
f01013e9:	29 d0                	sub    %edx,%eax
f01013eb:	eb 05                	jmp    f01013f2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013ed:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013f2:	5b                   	pop    %ebx
f01013f3:	5d                   	pop    %ebp
f01013f4:	c3                   	ret    

f01013f5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013f5:	55                   	push   %ebp
f01013f6:	89 e5                	mov    %esp,%ebp
f01013f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013ff:	eb 07                	jmp    f0101408 <strchr+0x13>
		if (*s == c)
f0101401:	38 ca                	cmp    %cl,%dl
f0101403:	74 0f                	je     f0101414 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101405:	83 c0 01             	add    $0x1,%eax
f0101408:	0f b6 10             	movzbl (%eax),%edx
f010140b:	84 d2                	test   %dl,%dl
f010140d:	75 f2                	jne    f0101401 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010140f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101414:	5d                   	pop    %ebp
f0101415:	c3                   	ret    

f0101416 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101416:	55                   	push   %ebp
f0101417:	89 e5                	mov    %esp,%ebp
f0101419:	8b 45 08             	mov    0x8(%ebp),%eax
f010141c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101420:	eb 03                	jmp    f0101425 <strfind+0xf>
f0101422:	83 c0 01             	add    $0x1,%eax
f0101425:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101428:	38 ca                	cmp    %cl,%dl
f010142a:	74 04                	je     f0101430 <strfind+0x1a>
f010142c:	84 d2                	test   %dl,%dl
f010142e:	75 f2                	jne    f0101422 <strfind+0xc>
			break;
	return (char *) s;
}
f0101430:	5d                   	pop    %ebp
f0101431:	c3                   	ret    

f0101432 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101432:	55                   	push   %ebp
f0101433:	89 e5                	mov    %esp,%ebp
f0101435:	57                   	push   %edi
f0101436:	56                   	push   %esi
f0101437:	53                   	push   %ebx
f0101438:	8b 7d 08             	mov    0x8(%ebp),%edi
f010143b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010143e:	85 c9                	test   %ecx,%ecx
f0101440:	74 36                	je     f0101478 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101442:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101448:	75 28                	jne    f0101472 <memset+0x40>
f010144a:	f6 c1 03             	test   $0x3,%cl
f010144d:	75 23                	jne    f0101472 <memset+0x40>
		c &= 0xFF;
f010144f:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101453:	89 d3                	mov    %edx,%ebx
f0101455:	c1 e3 08             	shl    $0x8,%ebx
f0101458:	89 d6                	mov    %edx,%esi
f010145a:	c1 e6 18             	shl    $0x18,%esi
f010145d:	89 d0                	mov    %edx,%eax
f010145f:	c1 e0 10             	shl    $0x10,%eax
f0101462:	09 f0                	or     %esi,%eax
f0101464:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101466:	89 d8                	mov    %ebx,%eax
f0101468:	09 d0                	or     %edx,%eax
f010146a:	c1 e9 02             	shr    $0x2,%ecx
f010146d:	fc                   	cld    
f010146e:	f3 ab                	rep stos %eax,%es:(%edi)
f0101470:	eb 06                	jmp    f0101478 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101472:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101475:	fc                   	cld    
f0101476:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101478:	89 f8                	mov    %edi,%eax
f010147a:	5b                   	pop    %ebx
f010147b:	5e                   	pop    %esi
f010147c:	5f                   	pop    %edi
f010147d:	5d                   	pop    %ebp
f010147e:	c3                   	ret    

f010147f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010147f:	55                   	push   %ebp
f0101480:	89 e5                	mov    %esp,%ebp
f0101482:	57                   	push   %edi
f0101483:	56                   	push   %esi
f0101484:	8b 45 08             	mov    0x8(%ebp),%eax
f0101487:	8b 75 0c             	mov    0xc(%ebp),%esi
f010148a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010148d:	39 c6                	cmp    %eax,%esi
f010148f:	73 35                	jae    f01014c6 <memmove+0x47>
f0101491:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101494:	39 d0                	cmp    %edx,%eax
f0101496:	73 2e                	jae    f01014c6 <memmove+0x47>
		s += n;
		d += n;
f0101498:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010149b:	89 d6                	mov    %edx,%esi
f010149d:	09 fe                	or     %edi,%esi
f010149f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014a5:	75 13                	jne    f01014ba <memmove+0x3b>
f01014a7:	f6 c1 03             	test   $0x3,%cl
f01014aa:	75 0e                	jne    f01014ba <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014ac:	83 ef 04             	sub    $0x4,%edi
f01014af:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014b2:	c1 e9 02             	shr    $0x2,%ecx
f01014b5:	fd                   	std    
f01014b6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014b8:	eb 09                	jmp    f01014c3 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014ba:	83 ef 01             	sub    $0x1,%edi
f01014bd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014c0:	fd                   	std    
f01014c1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014c3:	fc                   	cld    
f01014c4:	eb 1d                	jmp    f01014e3 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014c6:	89 f2                	mov    %esi,%edx
f01014c8:	09 c2                	or     %eax,%edx
f01014ca:	f6 c2 03             	test   $0x3,%dl
f01014cd:	75 0f                	jne    f01014de <memmove+0x5f>
f01014cf:	f6 c1 03             	test   $0x3,%cl
f01014d2:	75 0a                	jne    f01014de <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014d4:	c1 e9 02             	shr    $0x2,%ecx
f01014d7:	89 c7                	mov    %eax,%edi
f01014d9:	fc                   	cld    
f01014da:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014dc:	eb 05                	jmp    f01014e3 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014de:	89 c7                	mov    %eax,%edi
f01014e0:	fc                   	cld    
f01014e1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014e3:	5e                   	pop    %esi
f01014e4:	5f                   	pop    %edi
f01014e5:	5d                   	pop    %ebp
f01014e6:	c3                   	ret    

f01014e7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014e7:	55                   	push   %ebp
f01014e8:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014ea:	ff 75 10             	pushl  0x10(%ebp)
f01014ed:	ff 75 0c             	pushl  0xc(%ebp)
f01014f0:	ff 75 08             	pushl  0x8(%ebp)
f01014f3:	e8 87 ff ff ff       	call   f010147f <memmove>
}
f01014f8:	c9                   	leave  
f01014f9:	c3                   	ret    

f01014fa <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014fa:	55                   	push   %ebp
f01014fb:	89 e5                	mov    %esp,%ebp
f01014fd:	56                   	push   %esi
f01014fe:	53                   	push   %ebx
f01014ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101502:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101505:	89 c6                	mov    %eax,%esi
f0101507:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010150a:	eb 1a                	jmp    f0101526 <memcmp+0x2c>
		if (*s1 != *s2)
f010150c:	0f b6 08             	movzbl (%eax),%ecx
f010150f:	0f b6 1a             	movzbl (%edx),%ebx
f0101512:	38 d9                	cmp    %bl,%cl
f0101514:	74 0a                	je     f0101520 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101516:	0f b6 c1             	movzbl %cl,%eax
f0101519:	0f b6 db             	movzbl %bl,%ebx
f010151c:	29 d8                	sub    %ebx,%eax
f010151e:	eb 0f                	jmp    f010152f <memcmp+0x35>
		s1++, s2++;
f0101520:	83 c0 01             	add    $0x1,%eax
f0101523:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101526:	39 f0                	cmp    %esi,%eax
f0101528:	75 e2                	jne    f010150c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010152a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010152f:	5b                   	pop    %ebx
f0101530:	5e                   	pop    %esi
f0101531:	5d                   	pop    %ebp
f0101532:	c3                   	ret    

f0101533 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101533:	55                   	push   %ebp
f0101534:	89 e5                	mov    %esp,%ebp
f0101536:	53                   	push   %ebx
f0101537:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010153a:	89 c1                	mov    %eax,%ecx
f010153c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010153f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101543:	eb 0a                	jmp    f010154f <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101545:	0f b6 10             	movzbl (%eax),%edx
f0101548:	39 da                	cmp    %ebx,%edx
f010154a:	74 07                	je     f0101553 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010154c:	83 c0 01             	add    $0x1,%eax
f010154f:	39 c8                	cmp    %ecx,%eax
f0101551:	72 f2                	jb     f0101545 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101553:	5b                   	pop    %ebx
f0101554:	5d                   	pop    %ebp
f0101555:	c3                   	ret    

f0101556 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101556:	55                   	push   %ebp
f0101557:	89 e5                	mov    %esp,%ebp
f0101559:	57                   	push   %edi
f010155a:	56                   	push   %esi
f010155b:	53                   	push   %ebx
f010155c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010155f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101562:	eb 03                	jmp    f0101567 <strtol+0x11>
		s++;
f0101564:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101567:	0f b6 01             	movzbl (%ecx),%eax
f010156a:	3c 20                	cmp    $0x20,%al
f010156c:	74 f6                	je     f0101564 <strtol+0xe>
f010156e:	3c 09                	cmp    $0x9,%al
f0101570:	74 f2                	je     f0101564 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101572:	3c 2b                	cmp    $0x2b,%al
f0101574:	75 0a                	jne    f0101580 <strtol+0x2a>
		s++;
f0101576:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101579:	bf 00 00 00 00       	mov    $0x0,%edi
f010157e:	eb 11                	jmp    f0101591 <strtol+0x3b>
f0101580:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101585:	3c 2d                	cmp    $0x2d,%al
f0101587:	75 08                	jne    f0101591 <strtol+0x3b>
		s++, neg = 1;
f0101589:	83 c1 01             	add    $0x1,%ecx
f010158c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101591:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101597:	75 15                	jne    f01015ae <strtol+0x58>
f0101599:	80 39 30             	cmpb   $0x30,(%ecx)
f010159c:	75 10                	jne    f01015ae <strtol+0x58>
f010159e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015a2:	75 7c                	jne    f0101620 <strtol+0xca>
		s += 2, base = 16;
f01015a4:	83 c1 02             	add    $0x2,%ecx
f01015a7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015ac:	eb 16                	jmp    f01015c4 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015ae:	85 db                	test   %ebx,%ebx
f01015b0:	75 12                	jne    f01015c4 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015b2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015b7:	80 39 30             	cmpb   $0x30,(%ecx)
f01015ba:	75 08                	jne    f01015c4 <strtol+0x6e>
		s++, base = 8;
f01015bc:	83 c1 01             	add    $0x1,%ecx
f01015bf:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01015c9:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015cc:	0f b6 11             	movzbl (%ecx),%edx
f01015cf:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015d2:	89 f3                	mov    %esi,%ebx
f01015d4:	80 fb 09             	cmp    $0x9,%bl
f01015d7:	77 08                	ja     f01015e1 <strtol+0x8b>
			dig = *s - '0';
f01015d9:	0f be d2             	movsbl %dl,%edx
f01015dc:	83 ea 30             	sub    $0x30,%edx
f01015df:	eb 22                	jmp    f0101603 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015e1:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015e4:	89 f3                	mov    %esi,%ebx
f01015e6:	80 fb 19             	cmp    $0x19,%bl
f01015e9:	77 08                	ja     f01015f3 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015eb:	0f be d2             	movsbl %dl,%edx
f01015ee:	83 ea 57             	sub    $0x57,%edx
f01015f1:	eb 10                	jmp    f0101603 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015f3:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015f6:	89 f3                	mov    %esi,%ebx
f01015f8:	80 fb 19             	cmp    $0x19,%bl
f01015fb:	77 16                	ja     f0101613 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015fd:	0f be d2             	movsbl %dl,%edx
f0101600:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101603:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101606:	7d 0b                	jge    f0101613 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101608:	83 c1 01             	add    $0x1,%ecx
f010160b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010160f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101611:	eb b9                	jmp    f01015cc <strtol+0x76>

	if (endptr)
f0101613:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101617:	74 0d                	je     f0101626 <strtol+0xd0>
		*endptr = (char *) s;
f0101619:	8b 75 0c             	mov    0xc(%ebp),%esi
f010161c:	89 0e                	mov    %ecx,(%esi)
f010161e:	eb 06                	jmp    f0101626 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101620:	85 db                	test   %ebx,%ebx
f0101622:	74 98                	je     f01015bc <strtol+0x66>
f0101624:	eb 9e                	jmp    f01015c4 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101626:	89 c2                	mov    %eax,%edx
f0101628:	f7 da                	neg    %edx
f010162a:	85 ff                	test   %edi,%edi
f010162c:	0f 45 c2             	cmovne %edx,%eax
}
f010162f:	5b                   	pop    %ebx
f0101630:	5e                   	pop    %esi
f0101631:	5f                   	pop    %edi
f0101632:	5d                   	pop    %ebp
f0101633:	c3                   	ret    
f0101634:	66 90                	xchg   %ax,%ax
f0101636:	66 90                	xchg   %ax,%ax
f0101638:	66 90                	xchg   %ax,%ax
f010163a:	66 90                	xchg   %ax,%ax
f010163c:	66 90                	xchg   %ax,%ax
f010163e:	66 90                	xchg   %ax,%ax

f0101640 <__udivdi3>:
f0101640:	55                   	push   %ebp
f0101641:	57                   	push   %edi
f0101642:	56                   	push   %esi
f0101643:	53                   	push   %ebx
f0101644:	83 ec 1c             	sub    $0x1c,%esp
f0101647:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010164b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010164f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101653:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101657:	85 f6                	test   %esi,%esi
f0101659:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010165d:	89 ca                	mov    %ecx,%edx
f010165f:	89 f8                	mov    %edi,%eax
f0101661:	75 3d                	jne    f01016a0 <__udivdi3+0x60>
f0101663:	39 cf                	cmp    %ecx,%edi
f0101665:	0f 87 c5 00 00 00    	ja     f0101730 <__udivdi3+0xf0>
f010166b:	85 ff                	test   %edi,%edi
f010166d:	89 fd                	mov    %edi,%ebp
f010166f:	75 0b                	jne    f010167c <__udivdi3+0x3c>
f0101671:	b8 01 00 00 00       	mov    $0x1,%eax
f0101676:	31 d2                	xor    %edx,%edx
f0101678:	f7 f7                	div    %edi
f010167a:	89 c5                	mov    %eax,%ebp
f010167c:	89 c8                	mov    %ecx,%eax
f010167e:	31 d2                	xor    %edx,%edx
f0101680:	f7 f5                	div    %ebp
f0101682:	89 c1                	mov    %eax,%ecx
f0101684:	89 d8                	mov    %ebx,%eax
f0101686:	89 cf                	mov    %ecx,%edi
f0101688:	f7 f5                	div    %ebp
f010168a:	89 c3                	mov    %eax,%ebx
f010168c:	89 d8                	mov    %ebx,%eax
f010168e:	89 fa                	mov    %edi,%edx
f0101690:	83 c4 1c             	add    $0x1c,%esp
f0101693:	5b                   	pop    %ebx
f0101694:	5e                   	pop    %esi
f0101695:	5f                   	pop    %edi
f0101696:	5d                   	pop    %ebp
f0101697:	c3                   	ret    
f0101698:	90                   	nop
f0101699:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016a0:	39 ce                	cmp    %ecx,%esi
f01016a2:	77 74                	ja     f0101718 <__udivdi3+0xd8>
f01016a4:	0f bd fe             	bsr    %esi,%edi
f01016a7:	83 f7 1f             	xor    $0x1f,%edi
f01016aa:	0f 84 98 00 00 00    	je     f0101748 <__udivdi3+0x108>
f01016b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016b5:	89 f9                	mov    %edi,%ecx
f01016b7:	89 c5                	mov    %eax,%ebp
f01016b9:	29 fb                	sub    %edi,%ebx
f01016bb:	d3 e6                	shl    %cl,%esi
f01016bd:	89 d9                	mov    %ebx,%ecx
f01016bf:	d3 ed                	shr    %cl,%ebp
f01016c1:	89 f9                	mov    %edi,%ecx
f01016c3:	d3 e0                	shl    %cl,%eax
f01016c5:	09 ee                	or     %ebp,%esi
f01016c7:	89 d9                	mov    %ebx,%ecx
f01016c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016cd:	89 d5                	mov    %edx,%ebp
f01016cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016d3:	d3 ed                	shr    %cl,%ebp
f01016d5:	89 f9                	mov    %edi,%ecx
f01016d7:	d3 e2                	shl    %cl,%edx
f01016d9:	89 d9                	mov    %ebx,%ecx
f01016db:	d3 e8                	shr    %cl,%eax
f01016dd:	09 c2                	or     %eax,%edx
f01016df:	89 d0                	mov    %edx,%eax
f01016e1:	89 ea                	mov    %ebp,%edx
f01016e3:	f7 f6                	div    %esi
f01016e5:	89 d5                	mov    %edx,%ebp
f01016e7:	89 c3                	mov    %eax,%ebx
f01016e9:	f7 64 24 0c          	mull   0xc(%esp)
f01016ed:	39 d5                	cmp    %edx,%ebp
f01016ef:	72 10                	jb     f0101701 <__udivdi3+0xc1>
f01016f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016f5:	89 f9                	mov    %edi,%ecx
f01016f7:	d3 e6                	shl    %cl,%esi
f01016f9:	39 c6                	cmp    %eax,%esi
f01016fb:	73 07                	jae    f0101704 <__udivdi3+0xc4>
f01016fd:	39 d5                	cmp    %edx,%ebp
f01016ff:	75 03                	jne    f0101704 <__udivdi3+0xc4>
f0101701:	83 eb 01             	sub    $0x1,%ebx
f0101704:	31 ff                	xor    %edi,%edi
f0101706:	89 d8                	mov    %ebx,%eax
f0101708:	89 fa                	mov    %edi,%edx
f010170a:	83 c4 1c             	add    $0x1c,%esp
f010170d:	5b                   	pop    %ebx
f010170e:	5e                   	pop    %esi
f010170f:	5f                   	pop    %edi
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    
f0101712:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101718:	31 ff                	xor    %edi,%edi
f010171a:	31 db                	xor    %ebx,%ebx
f010171c:	89 d8                	mov    %ebx,%eax
f010171e:	89 fa                	mov    %edi,%edx
f0101720:	83 c4 1c             	add    $0x1c,%esp
f0101723:	5b                   	pop    %ebx
f0101724:	5e                   	pop    %esi
f0101725:	5f                   	pop    %edi
f0101726:	5d                   	pop    %ebp
f0101727:	c3                   	ret    
f0101728:	90                   	nop
f0101729:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101730:	89 d8                	mov    %ebx,%eax
f0101732:	f7 f7                	div    %edi
f0101734:	31 ff                	xor    %edi,%edi
f0101736:	89 c3                	mov    %eax,%ebx
f0101738:	89 d8                	mov    %ebx,%eax
f010173a:	89 fa                	mov    %edi,%edx
f010173c:	83 c4 1c             	add    $0x1c,%esp
f010173f:	5b                   	pop    %ebx
f0101740:	5e                   	pop    %esi
f0101741:	5f                   	pop    %edi
f0101742:	5d                   	pop    %ebp
f0101743:	c3                   	ret    
f0101744:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101748:	39 ce                	cmp    %ecx,%esi
f010174a:	72 0c                	jb     f0101758 <__udivdi3+0x118>
f010174c:	31 db                	xor    %ebx,%ebx
f010174e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101752:	0f 87 34 ff ff ff    	ja     f010168c <__udivdi3+0x4c>
f0101758:	bb 01 00 00 00       	mov    $0x1,%ebx
f010175d:	e9 2a ff ff ff       	jmp    f010168c <__udivdi3+0x4c>
f0101762:	66 90                	xchg   %ax,%ax
f0101764:	66 90                	xchg   %ax,%ax
f0101766:	66 90                	xchg   %ax,%ax
f0101768:	66 90                	xchg   %ax,%ax
f010176a:	66 90                	xchg   %ax,%ax
f010176c:	66 90                	xchg   %ax,%ax
f010176e:	66 90                	xchg   %ax,%ax

f0101770 <__umoddi3>:
f0101770:	55                   	push   %ebp
f0101771:	57                   	push   %edi
f0101772:	56                   	push   %esi
f0101773:	53                   	push   %ebx
f0101774:	83 ec 1c             	sub    $0x1c,%esp
f0101777:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010177b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010177f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101783:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101787:	85 d2                	test   %edx,%edx
f0101789:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010178d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101791:	89 f3                	mov    %esi,%ebx
f0101793:	89 3c 24             	mov    %edi,(%esp)
f0101796:	89 74 24 04          	mov    %esi,0x4(%esp)
f010179a:	75 1c                	jne    f01017b8 <__umoddi3+0x48>
f010179c:	39 f7                	cmp    %esi,%edi
f010179e:	76 50                	jbe    f01017f0 <__umoddi3+0x80>
f01017a0:	89 c8                	mov    %ecx,%eax
f01017a2:	89 f2                	mov    %esi,%edx
f01017a4:	f7 f7                	div    %edi
f01017a6:	89 d0                	mov    %edx,%eax
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	83 c4 1c             	add    $0x1c,%esp
f01017ad:	5b                   	pop    %ebx
f01017ae:	5e                   	pop    %esi
f01017af:	5f                   	pop    %edi
f01017b0:	5d                   	pop    %ebp
f01017b1:	c3                   	ret    
f01017b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017b8:	39 f2                	cmp    %esi,%edx
f01017ba:	89 d0                	mov    %edx,%eax
f01017bc:	77 52                	ja     f0101810 <__umoddi3+0xa0>
f01017be:	0f bd ea             	bsr    %edx,%ebp
f01017c1:	83 f5 1f             	xor    $0x1f,%ebp
f01017c4:	75 5a                	jne    f0101820 <__umoddi3+0xb0>
f01017c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017ca:	0f 82 e0 00 00 00    	jb     f01018b0 <__umoddi3+0x140>
f01017d0:	39 0c 24             	cmp    %ecx,(%esp)
f01017d3:	0f 86 d7 00 00 00    	jbe    f01018b0 <__umoddi3+0x140>
f01017d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017e1:	83 c4 1c             	add    $0x1c,%esp
f01017e4:	5b                   	pop    %ebx
f01017e5:	5e                   	pop    %esi
f01017e6:	5f                   	pop    %edi
f01017e7:	5d                   	pop    %ebp
f01017e8:	c3                   	ret    
f01017e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	85 ff                	test   %edi,%edi
f01017f2:	89 fd                	mov    %edi,%ebp
f01017f4:	75 0b                	jne    f0101801 <__umoddi3+0x91>
f01017f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017fb:	31 d2                	xor    %edx,%edx
f01017fd:	f7 f7                	div    %edi
f01017ff:	89 c5                	mov    %eax,%ebp
f0101801:	89 f0                	mov    %esi,%eax
f0101803:	31 d2                	xor    %edx,%edx
f0101805:	f7 f5                	div    %ebp
f0101807:	89 c8                	mov    %ecx,%eax
f0101809:	f7 f5                	div    %ebp
f010180b:	89 d0                	mov    %edx,%eax
f010180d:	eb 99                	jmp    f01017a8 <__umoddi3+0x38>
f010180f:	90                   	nop
f0101810:	89 c8                	mov    %ecx,%eax
f0101812:	89 f2                	mov    %esi,%edx
f0101814:	83 c4 1c             	add    $0x1c,%esp
f0101817:	5b                   	pop    %ebx
f0101818:	5e                   	pop    %esi
f0101819:	5f                   	pop    %edi
f010181a:	5d                   	pop    %ebp
f010181b:	c3                   	ret    
f010181c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101820:	8b 34 24             	mov    (%esp),%esi
f0101823:	bf 20 00 00 00       	mov    $0x20,%edi
f0101828:	89 e9                	mov    %ebp,%ecx
f010182a:	29 ef                	sub    %ebp,%edi
f010182c:	d3 e0                	shl    %cl,%eax
f010182e:	89 f9                	mov    %edi,%ecx
f0101830:	89 f2                	mov    %esi,%edx
f0101832:	d3 ea                	shr    %cl,%edx
f0101834:	89 e9                	mov    %ebp,%ecx
f0101836:	09 c2                	or     %eax,%edx
f0101838:	89 d8                	mov    %ebx,%eax
f010183a:	89 14 24             	mov    %edx,(%esp)
f010183d:	89 f2                	mov    %esi,%edx
f010183f:	d3 e2                	shl    %cl,%edx
f0101841:	89 f9                	mov    %edi,%ecx
f0101843:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101847:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010184b:	d3 e8                	shr    %cl,%eax
f010184d:	89 e9                	mov    %ebp,%ecx
f010184f:	89 c6                	mov    %eax,%esi
f0101851:	d3 e3                	shl    %cl,%ebx
f0101853:	89 f9                	mov    %edi,%ecx
f0101855:	89 d0                	mov    %edx,%eax
f0101857:	d3 e8                	shr    %cl,%eax
f0101859:	89 e9                	mov    %ebp,%ecx
f010185b:	09 d8                	or     %ebx,%eax
f010185d:	89 d3                	mov    %edx,%ebx
f010185f:	89 f2                	mov    %esi,%edx
f0101861:	f7 34 24             	divl   (%esp)
f0101864:	89 d6                	mov    %edx,%esi
f0101866:	d3 e3                	shl    %cl,%ebx
f0101868:	f7 64 24 04          	mull   0x4(%esp)
f010186c:	39 d6                	cmp    %edx,%esi
f010186e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101872:	89 d1                	mov    %edx,%ecx
f0101874:	89 c3                	mov    %eax,%ebx
f0101876:	72 08                	jb     f0101880 <__umoddi3+0x110>
f0101878:	75 11                	jne    f010188b <__umoddi3+0x11b>
f010187a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010187e:	73 0b                	jae    f010188b <__umoddi3+0x11b>
f0101880:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101884:	1b 14 24             	sbb    (%esp),%edx
f0101887:	89 d1                	mov    %edx,%ecx
f0101889:	89 c3                	mov    %eax,%ebx
f010188b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010188f:	29 da                	sub    %ebx,%edx
f0101891:	19 ce                	sbb    %ecx,%esi
f0101893:	89 f9                	mov    %edi,%ecx
f0101895:	89 f0                	mov    %esi,%eax
f0101897:	d3 e0                	shl    %cl,%eax
f0101899:	89 e9                	mov    %ebp,%ecx
f010189b:	d3 ea                	shr    %cl,%edx
f010189d:	89 e9                	mov    %ebp,%ecx
f010189f:	d3 ee                	shr    %cl,%esi
f01018a1:	09 d0                	or     %edx,%eax
f01018a3:	89 f2                	mov    %esi,%edx
f01018a5:	83 c4 1c             	add    $0x1c,%esp
f01018a8:	5b                   	pop    %ebx
f01018a9:	5e                   	pop    %esi
f01018aa:	5f                   	pop    %edi
f01018ab:	5d                   	pop    %ebp
f01018ac:	c3                   	ret    
f01018ad:	8d 76 00             	lea    0x0(%esi),%esi
f01018b0:	29 f9                	sub    %edi,%ecx
f01018b2:	19 d6                	sbb    %edx,%esi
f01018b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018bc:	e9 18 ff ff ff       	jmp    f01017d9 <__umoddi3+0x69>
