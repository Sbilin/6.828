
obj/user/hello:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 e0 0f 80 00       	push   $0x800fe0
  80003e:	e8 06 01 00 00       	call   800149 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 ee 0f 80 00       	push   $0x800fee
  800054:	e8 f0 00 00 00       	call   800149 <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	56                   	push   %esi
  800062:	53                   	push   %ebx
  800063:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800066:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  800069:	e8 a4 0a 00 00       	call   800b12 <sys_getenvid>
  80006e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800073:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800076:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007b:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800080:	85 db                	test   %ebx,%ebx
  800082:	7e 07                	jle    80008b <libmain+0x2d>
		binaryname = argv[0];
  800084:	8b 06                	mov    (%esi),%eax
  800086:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008b:	83 ec 08             	sub    $0x8,%esp
  80008e:	56                   	push   %esi
  80008f:	53                   	push   %ebx
  800090:	e8 9e ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800095:	e8 0a 00 00 00       	call   8000a4 <exit>
}
  80009a:	83 c4 10             	add    $0x10,%esp
  80009d:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a0:	5b                   	pop    %ebx
  8000a1:	5e                   	pop    %esi
  8000a2:	5d                   	pop    %ebp
  8000a3:	c3                   	ret    

008000a4 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a4:	55                   	push   %ebp
  8000a5:	89 e5                	mov    %esp,%ebp
  8000a7:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000aa:	6a 00                	push   $0x0
  8000ac:	e8 20 0a 00 00       	call   800ad1 <sys_env_destroy>
}
  8000b1:	83 c4 10             	add    $0x10,%esp
  8000b4:	c9                   	leave  
  8000b5:	c3                   	ret    

008000b6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b6:	55                   	push   %ebp
  8000b7:	89 e5                	mov    %esp,%ebp
  8000b9:	53                   	push   %ebx
  8000ba:	83 ec 04             	sub    $0x4,%esp
  8000bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c0:	8b 13                	mov    (%ebx),%edx
  8000c2:	8d 42 01             	lea    0x1(%edx),%eax
  8000c5:	89 03                	mov    %eax,(%ebx)
  8000c7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ca:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000ce:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d3:	75 1a                	jne    8000ef <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000d5:	83 ec 08             	sub    $0x8,%esp
  8000d8:	68 ff 00 00 00       	push   $0xff
  8000dd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e0:	50                   	push   %eax
  8000e1:	e8 ae 09 00 00       	call   800a94 <sys_cputs>
		b->idx = 0;
  8000e6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000ec:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000ef:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f6:	c9                   	leave  
  8000f7:	c3                   	ret    

008000f8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f8:	55                   	push   %ebp
  8000f9:	89 e5                	mov    %esp,%ebp
  8000fb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800101:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800108:	00 00 00 
	b.cnt = 0;
  80010b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800112:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800115:	ff 75 0c             	pushl  0xc(%ebp)
  800118:	ff 75 08             	pushl  0x8(%ebp)
  80011b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800121:	50                   	push   %eax
  800122:	68 b6 00 80 00       	push   $0x8000b6
  800127:	e8 1a 01 00 00       	call   800246 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012c:	83 c4 08             	add    $0x8,%esp
  80012f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800135:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013b:	50                   	push   %eax
  80013c:	e8 53 09 00 00       	call   800a94 <sys_cputs>

	return b.cnt;
}
  800141:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800147:	c9                   	leave  
  800148:	c3                   	ret    

00800149 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800149:	55                   	push   %ebp
  80014a:	89 e5                	mov    %esp,%ebp
  80014c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80014f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800152:	50                   	push   %eax
  800153:	ff 75 08             	pushl  0x8(%ebp)
  800156:	e8 9d ff ff ff       	call   8000f8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80015b:	c9                   	leave  
  80015c:	c3                   	ret    

0080015d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80015d:	55                   	push   %ebp
  80015e:	89 e5                	mov    %esp,%ebp
  800160:	57                   	push   %edi
  800161:	56                   	push   %esi
  800162:	53                   	push   %ebx
  800163:	83 ec 1c             	sub    $0x1c,%esp
  800166:	89 c7                	mov    %eax,%edi
  800168:	89 d6                	mov    %edx,%esi
  80016a:	8b 45 08             	mov    0x8(%ebp),%eax
  80016d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800170:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800173:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800176:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800179:	bb 00 00 00 00       	mov    $0x0,%ebx
  80017e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800181:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800184:	39 d3                	cmp    %edx,%ebx
  800186:	72 05                	jb     80018d <printnum+0x30>
  800188:	39 45 10             	cmp    %eax,0x10(%ebp)
  80018b:	77 45                	ja     8001d2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80018d:	83 ec 0c             	sub    $0xc,%esp
  800190:	ff 75 18             	pushl  0x18(%ebp)
  800193:	8b 45 14             	mov    0x14(%ebp),%eax
  800196:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800199:	53                   	push   %ebx
  80019a:	ff 75 10             	pushl  0x10(%ebp)
  80019d:	83 ec 08             	sub    $0x8,%esp
  8001a0:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a3:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a6:	ff 75 dc             	pushl  -0x24(%ebp)
  8001a9:	ff 75 d8             	pushl  -0x28(%ebp)
  8001ac:	e8 9f 0b 00 00       	call   800d50 <__udivdi3>
  8001b1:	83 c4 18             	add    $0x18,%esp
  8001b4:	52                   	push   %edx
  8001b5:	50                   	push   %eax
  8001b6:	89 f2                	mov    %esi,%edx
  8001b8:	89 f8                	mov    %edi,%eax
  8001ba:	e8 9e ff ff ff       	call   80015d <printnum>
  8001bf:	83 c4 20             	add    $0x20,%esp
  8001c2:	eb 18                	jmp    8001dc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c4:	83 ec 08             	sub    $0x8,%esp
  8001c7:	56                   	push   %esi
  8001c8:	ff 75 18             	pushl  0x18(%ebp)
  8001cb:	ff d7                	call   *%edi
  8001cd:	83 c4 10             	add    $0x10,%esp
  8001d0:	eb 03                	jmp    8001d5 <printnum+0x78>
  8001d2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001d5:	83 eb 01             	sub    $0x1,%ebx
  8001d8:	85 db                	test   %ebx,%ebx
  8001da:	7f e8                	jg     8001c4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001dc:	83 ec 08             	sub    $0x8,%esp
  8001df:	56                   	push   %esi
  8001e0:	83 ec 04             	sub    $0x4,%esp
  8001e3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001e9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ec:	ff 75 d8             	pushl  -0x28(%ebp)
  8001ef:	e8 8c 0c 00 00       	call   800e80 <__umoddi3>
  8001f4:	83 c4 14             	add    $0x14,%esp
  8001f7:	0f be 80 0f 10 80 00 	movsbl 0x80100f(%eax),%eax
  8001fe:	50                   	push   %eax
  8001ff:	ff d7                	call   *%edi
}
  800201:	83 c4 10             	add    $0x10,%esp
  800204:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800207:	5b                   	pop    %ebx
  800208:	5e                   	pop    %esi
  800209:	5f                   	pop    %edi
  80020a:	5d                   	pop    %ebp
  80020b:	c3                   	ret    

0080020c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80020c:	55                   	push   %ebp
  80020d:	89 e5                	mov    %esp,%ebp
  80020f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800212:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800216:	8b 10                	mov    (%eax),%edx
  800218:	3b 50 04             	cmp    0x4(%eax),%edx
  80021b:	73 0a                	jae    800227 <sprintputch+0x1b>
		*b->buf++ = ch;
  80021d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800220:	89 08                	mov    %ecx,(%eax)
  800222:	8b 45 08             	mov    0x8(%ebp),%eax
  800225:	88 02                	mov    %al,(%edx)
}
  800227:	5d                   	pop    %ebp
  800228:	c3                   	ret    

00800229 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800229:	55                   	push   %ebp
  80022a:	89 e5                	mov    %esp,%ebp
  80022c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80022f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800232:	50                   	push   %eax
  800233:	ff 75 10             	pushl  0x10(%ebp)
  800236:	ff 75 0c             	pushl  0xc(%ebp)
  800239:	ff 75 08             	pushl  0x8(%ebp)
  80023c:	e8 05 00 00 00       	call   800246 <vprintfmt>
	va_end(ap);
}
  800241:	83 c4 10             	add    $0x10,%esp
  800244:	c9                   	leave  
  800245:	c3                   	ret    

00800246 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800246:	55                   	push   %ebp
  800247:	89 e5                	mov    %esp,%ebp
  800249:	57                   	push   %edi
  80024a:	56                   	push   %esi
  80024b:	53                   	push   %ebx
  80024c:	83 ec 2c             	sub    $0x2c,%esp
  80024f:	8b 75 08             	mov    0x8(%ebp),%esi
  800252:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800255:	8b 7d 10             	mov    0x10(%ebp),%edi
  800258:	eb 12                	jmp    80026c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80025a:	85 c0                	test   %eax,%eax
  80025c:	0f 84 42 04 00 00    	je     8006a4 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800262:	83 ec 08             	sub    $0x8,%esp
  800265:	53                   	push   %ebx
  800266:	50                   	push   %eax
  800267:	ff d6                	call   *%esi
  800269:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80026c:	83 c7 01             	add    $0x1,%edi
  80026f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800273:	83 f8 25             	cmp    $0x25,%eax
  800276:	75 e2                	jne    80025a <vprintfmt+0x14>
  800278:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80027c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800283:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80028a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800291:	b9 00 00 00 00       	mov    $0x0,%ecx
  800296:	eb 07                	jmp    80029f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800298:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80029b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80029f:	8d 47 01             	lea    0x1(%edi),%eax
  8002a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002a5:	0f b6 07             	movzbl (%edi),%eax
  8002a8:	0f b6 d0             	movzbl %al,%edx
  8002ab:	83 e8 23             	sub    $0x23,%eax
  8002ae:	3c 55                	cmp    $0x55,%al
  8002b0:	0f 87 d3 03 00 00    	ja     800689 <vprintfmt+0x443>
  8002b6:	0f b6 c0             	movzbl %al,%eax
  8002b9:	ff 24 85 e0 10 80 00 	jmp    *0x8010e0(,%eax,4)
  8002c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002c3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002c7:	eb d6                	jmp    80029f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002cc:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d1:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002d7:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002db:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002de:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002e1:	83 f9 09             	cmp    $0x9,%ecx
  8002e4:	77 3f                	ja     800325 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002e6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002e9:	eb e9                	jmp    8002d4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8002ee:	8b 00                	mov    (%eax),%eax
  8002f0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f6:	8d 40 04             	lea    0x4(%eax),%eax
  8002f9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8002ff:	eb 2a                	jmp    80032b <vprintfmt+0xe5>
  800301:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800304:	85 c0                	test   %eax,%eax
  800306:	ba 00 00 00 00       	mov    $0x0,%edx
  80030b:	0f 49 d0             	cmovns %eax,%edx
  80030e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800311:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800314:	eb 89                	jmp    80029f <vprintfmt+0x59>
  800316:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800319:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800320:	e9 7a ff ff ff       	jmp    80029f <vprintfmt+0x59>
  800325:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  800328:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80032b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80032f:	0f 89 6a ff ff ff    	jns    80029f <vprintfmt+0x59>
				width = precision, precision = -1;
  800335:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800338:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80033b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800342:	e9 58 ff ff ff       	jmp    80029f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800347:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80034d:	e9 4d ff ff ff       	jmp    80029f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800352:	8b 45 14             	mov    0x14(%ebp),%eax
  800355:	8d 78 04             	lea    0x4(%eax),%edi
  800358:	83 ec 08             	sub    $0x8,%esp
  80035b:	53                   	push   %ebx
  80035c:	ff 30                	pushl  (%eax)
  80035e:	ff d6                	call   *%esi
			break;
  800360:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800363:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800366:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800369:	e9 fe fe ff ff       	jmp    80026c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80036e:	8b 45 14             	mov    0x14(%ebp),%eax
  800371:	8d 78 04             	lea    0x4(%eax),%edi
  800374:	8b 00                	mov    (%eax),%eax
  800376:	99                   	cltd   
  800377:	31 d0                	xor    %edx,%eax
  800379:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80037b:	83 f8 08             	cmp    $0x8,%eax
  80037e:	7f 0b                	jg     80038b <vprintfmt+0x145>
  800380:	8b 14 85 40 12 80 00 	mov    0x801240(,%eax,4),%edx
  800387:	85 d2                	test   %edx,%edx
  800389:	75 1b                	jne    8003a6 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80038b:	50                   	push   %eax
  80038c:	68 27 10 80 00       	push   $0x801027
  800391:	53                   	push   %ebx
  800392:	56                   	push   %esi
  800393:	e8 91 fe ff ff       	call   800229 <printfmt>
  800398:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80039b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003a1:	e9 c6 fe ff ff       	jmp    80026c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003a6:	52                   	push   %edx
  8003a7:	68 30 10 80 00       	push   $0x801030
  8003ac:	53                   	push   %ebx
  8003ad:	56                   	push   %esi
  8003ae:	e8 76 fe ff ff       	call   800229 <printfmt>
  8003b3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003bc:	e9 ab fe ff ff       	jmp    80026c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c4:	83 c0 04             	add    $0x4,%eax
  8003c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003cf:	85 ff                	test   %edi,%edi
  8003d1:	b8 20 10 80 00       	mov    $0x801020,%eax
  8003d6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003d9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003dd:	0f 8e 94 00 00 00    	jle    800477 <vprintfmt+0x231>
  8003e3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003e7:	0f 84 98 00 00 00    	je     800485 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003ed:	83 ec 08             	sub    $0x8,%esp
  8003f0:	ff 75 d0             	pushl  -0x30(%ebp)
  8003f3:	57                   	push   %edi
  8003f4:	e8 33 03 00 00       	call   80072c <strnlen>
  8003f9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003fc:	29 c1                	sub    %eax,%ecx
  8003fe:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800401:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800404:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800408:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80040b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80040e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800410:	eb 0f                	jmp    800421 <vprintfmt+0x1db>
					putch(padc, putdat);
  800412:	83 ec 08             	sub    $0x8,%esp
  800415:	53                   	push   %ebx
  800416:	ff 75 e0             	pushl  -0x20(%ebp)
  800419:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80041b:	83 ef 01             	sub    $0x1,%edi
  80041e:	83 c4 10             	add    $0x10,%esp
  800421:	85 ff                	test   %edi,%edi
  800423:	7f ed                	jg     800412 <vprintfmt+0x1cc>
  800425:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800428:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80042b:	85 c9                	test   %ecx,%ecx
  80042d:	b8 00 00 00 00       	mov    $0x0,%eax
  800432:	0f 49 c1             	cmovns %ecx,%eax
  800435:	29 c1                	sub    %eax,%ecx
  800437:	89 75 08             	mov    %esi,0x8(%ebp)
  80043a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80043d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800440:	89 cb                	mov    %ecx,%ebx
  800442:	eb 4d                	jmp    800491 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800444:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800448:	74 1b                	je     800465 <vprintfmt+0x21f>
  80044a:	0f be c0             	movsbl %al,%eax
  80044d:	83 e8 20             	sub    $0x20,%eax
  800450:	83 f8 5e             	cmp    $0x5e,%eax
  800453:	76 10                	jbe    800465 <vprintfmt+0x21f>
					putch('?', putdat);
  800455:	83 ec 08             	sub    $0x8,%esp
  800458:	ff 75 0c             	pushl  0xc(%ebp)
  80045b:	6a 3f                	push   $0x3f
  80045d:	ff 55 08             	call   *0x8(%ebp)
  800460:	83 c4 10             	add    $0x10,%esp
  800463:	eb 0d                	jmp    800472 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800465:	83 ec 08             	sub    $0x8,%esp
  800468:	ff 75 0c             	pushl  0xc(%ebp)
  80046b:	52                   	push   %edx
  80046c:	ff 55 08             	call   *0x8(%ebp)
  80046f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800472:	83 eb 01             	sub    $0x1,%ebx
  800475:	eb 1a                	jmp    800491 <vprintfmt+0x24b>
  800477:	89 75 08             	mov    %esi,0x8(%ebp)
  80047a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800480:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800483:	eb 0c                	jmp    800491 <vprintfmt+0x24b>
  800485:	89 75 08             	mov    %esi,0x8(%ebp)
  800488:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80048e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800491:	83 c7 01             	add    $0x1,%edi
  800494:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800498:	0f be d0             	movsbl %al,%edx
  80049b:	85 d2                	test   %edx,%edx
  80049d:	74 23                	je     8004c2 <vprintfmt+0x27c>
  80049f:	85 f6                	test   %esi,%esi
  8004a1:	78 a1                	js     800444 <vprintfmt+0x1fe>
  8004a3:	83 ee 01             	sub    $0x1,%esi
  8004a6:	79 9c                	jns    800444 <vprintfmt+0x1fe>
  8004a8:	89 df                	mov    %ebx,%edi
  8004aa:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004b0:	eb 18                	jmp    8004ca <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004b2:	83 ec 08             	sub    $0x8,%esp
  8004b5:	53                   	push   %ebx
  8004b6:	6a 20                	push   $0x20
  8004b8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004ba:	83 ef 01             	sub    $0x1,%edi
  8004bd:	83 c4 10             	add    $0x10,%esp
  8004c0:	eb 08                	jmp    8004ca <vprintfmt+0x284>
  8004c2:	89 df                	mov    %ebx,%edi
  8004c4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004ca:	85 ff                	test   %edi,%edi
  8004cc:	7f e4                	jg     8004b2 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004ce:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004d1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004d7:	e9 90 fd ff ff       	jmp    80026c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004dc:	83 f9 01             	cmp    $0x1,%ecx
  8004df:	7e 19                	jle    8004fa <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e4:	8b 50 04             	mov    0x4(%eax),%edx
  8004e7:	8b 00                	mov    (%eax),%eax
  8004e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ec:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f2:	8d 40 08             	lea    0x8(%eax),%eax
  8004f5:	89 45 14             	mov    %eax,0x14(%ebp)
  8004f8:	eb 38                	jmp    800532 <vprintfmt+0x2ec>
	else if (lflag)
  8004fa:	85 c9                	test   %ecx,%ecx
  8004fc:	74 1b                	je     800519 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  8004fe:	8b 45 14             	mov    0x14(%ebp),%eax
  800501:	8b 00                	mov    (%eax),%eax
  800503:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800506:	89 c1                	mov    %eax,%ecx
  800508:	c1 f9 1f             	sar    $0x1f,%ecx
  80050b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80050e:	8b 45 14             	mov    0x14(%ebp),%eax
  800511:	8d 40 04             	lea    0x4(%eax),%eax
  800514:	89 45 14             	mov    %eax,0x14(%ebp)
  800517:	eb 19                	jmp    800532 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  800519:	8b 45 14             	mov    0x14(%ebp),%eax
  80051c:	8b 00                	mov    (%eax),%eax
  80051e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800521:	89 c1                	mov    %eax,%ecx
  800523:	c1 f9 1f             	sar    $0x1f,%ecx
  800526:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800529:	8b 45 14             	mov    0x14(%ebp),%eax
  80052c:	8d 40 04             	lea    0x4(%eax),%eax
  80052f:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800532:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800535:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800538:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80053d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800541:	0f 89 0e 01 00 00    	jns    800655 <vprintfmt+0x40f>
				putch('-', putdat);
  800547:	83 ec 08             	sub    $0x8,%esp
  80054a:	53                   	push   %ebx
  80054b:	6a 2d                	push   $0x2d
  80054d:	ff d6                	call   *%esi
				num = -(long long) num;
  80054f:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800552:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800555:	f7 da                	neg    %edx
  800557:	83 d1 00             	adc    $0x0,%ecx
  80055a:	f7 d9                	neg    %ecx
  80055c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80055f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800564:	e9 ec 00 00 00       	jmp    800655 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800569:	83 f9 01             	cmp    $0x1,%ecx
  80056c:	7e 18                	jle    800586 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  80056e:	8b 45 14             	mov    0x14(%ebp),%eax
  800571:	8b 10                	mov    (%eax),%edx
  800573:	8b 48 04             	mov    0x4(%eax),%ecx
  800576:	8d 40 08             	lea    0x8(%eax),%eax
  800579:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80057c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800581:	e9 cf 00 00 00       	jmp    800655 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800586:	85 c9                	test   %ecx,%ecx
  800588:	74 1a                	je     8005a4 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80058a:	8b 45 14             	mov    0x14(%ebp),%eax
  80058d:	8b 10                	mov    (%eax),%edx
  80058f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800594:	8d 40 04             	lea    0x4(%eax),%eax
  800597:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80059a:	b8 0a 00 00 00       	mov    $0xa,%eax
  80059f:	e9 b1 00 00 00       	jmp    800655 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a7:	8b 10                	mov    (%eax),%edx
  8005a9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005ae:	8d 40 04             	lea    0x4(%eax),%eax
  8005b1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005b4:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005b9:	e9 97 00 00 00       	jmp    800655 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005be:	83 ec 08             	sub    $0x8,%esp
  8005c1:	53                   	push   %ebx
  8005c2:	6a 58                	push   $0x58
  8005c4:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c6:	83 c4 08             	add    $0x8,%esp
  8005c9:	53                   	push   %ebx
  8005ca:	6a 58                	push   $0x58
  8005cc:	ff d6                	call   *%esi
			putch('X', putdat);
  8005ce:	83 c4 08             	add    $0x8,%esp
  8005d1:	53                   	push   %ebx
  8005d2:	6a 58                	push   $0x58
  8005d4:	ff d6                	call   *%esi
			break;
  8005d6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005dc:	e9 8b fc ff ff       	jmp    80026c <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e1:	83 ec 08             	sub    $0x8,%esp
  8005e4:	53                   	push   %ebx
  8005e5:	6a 30                	push   $0x30
  8005e7:	ff d6                	call   *%esi
			putch('x', putdat);
  8005e9:	83 c4 08             	add    $0x8,%esp
  8005ec:	53                   	push   %ebx
  8005ed:	6a 78                	push   $0x78
  8005ef:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f4:	8b 10                	mov    (%eax),%edx
  8005f6:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005fb:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005fe:	8d 40 04             	lea    0x4(%eax),%eax
  800601:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800604:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800609:	eb 4a                	jmp    800655 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80060b:	83 f9 01             	cmp    $0x1,%ecx
  80060e:	7e 15                	jle    800625 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800610:	8b 45 14             	mov    0x14(%ebp),%eax
  800613:	8b 10                	mov    (%eax),%edx
  800615:	8b 48 04             	mov    0x4(%eax),%ecx
  800618:	8d 40 08             	lea    0x8(%eax),%eax
  80061b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80061e:	b8 10 00 00 00       	mov    $0x10,%eax
  800623:	eb 30                	jmp    800655 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800625:	85 c9                	test   %ecx,%ecx
  800627:	74 17                	je     800640 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  800629:	8b 45 14             	mov    0x14(%ebp),%eax
  80062c:	8b 10                	mov    (%eax),%edx
  80062e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800633:	8d 40 04             	lea    0x4(%eax),%eax
  800636:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800639:	b8 10 00 00 00       	mov    $0x10,%eax
  80063e:	eb 15                	jmp    800655 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800640:	8b 45 14             	mov    0x14(%ebp),%eax
  800643:	8b 10                	mov    (%eax),%edx
  800645:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064a:	8d 40 04             	lea    0x4(%eax),%eax
  80064d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800650:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800655:	83 ec 0c             	sub    $0xc,%esp
  800658:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80065c:	57                   	push   %edi
  80065d:	ff 75 e0             	pushl  -0x20(%ebp)
  800660:	50                   	push   %eax
  800661:	51                   	push   %ecx
  800662:	52                   	push   %edx
  800663:	89 da                	mov    %ebx,%edx
  800665:	89 f0                	mov    %esi,%eax
  800667:	e8 f1 fa ff ff       	call   80015d <printnum>
			break;
  80066c:	83 c4 20             	add    $0x20,%esp
  80066f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800672:	e9 f5 fb ff ff       	jmp    80026c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800677:	83 ec 08             	sub    $0x8,%esp
  80067a:	53                   	push   %ebx
  80067b:	52                   	push   %edx
  80067c:	ff d6                	call   *%esi
			break;
  80067e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800681:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800684:	e9 e3 fb ff ff       	jmp    80026c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800689:	83 ec 08             	sub    $0x8,%esp
  80068c:	53                   	push   %ebx
  80068d:	6a 25                	push   $0x25
  80068f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800691:	83 c4 10             	add    $0x10,%esp
  800694:	eb 03                	jmp    800699 <vprintfmt+0x453>
  800696:	83 ef 01             	sub    $0x1,%edi
  800699:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80069d:	75 f7                	jne    800696 <vprintfmt+0x450>
  80069f:	e9 c8 fb ff ff       	jmp    80026c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006a7:	5b                   	pop    %ebx
  8006a8:	5e                   	pop    %esi
  8006a9:	5f                   	pop    %edi
  8006aa:	5d                   	pop    %ebp
  8006ab:	c3                   	ret    

008006ac <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ac:	55                   	push   %ebp
  8006ad:	89 e5                	mov    %esp,%ebp
  8006af:	83 ec 18             	sub    $0x18,%esp
  8006b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006bb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006bf:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006c9:	85 c0                	test   %eax,%eax
  8006cb:	74 26                	je     8006f3 <vsnprintf+0x47>
  8006cd:	85 d2                	test   %edx,%edx
  8006cf:	7e 22                	jle    8006f3 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d1:	ff 75 14             	pushl  0x14(%ebp)
  8006d4:	ff 75 10             	pushl  0x10(%ebp)
  8006d7:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006da:	50                   	push   %eax
  8006db:	68 0c 02 80 00       	push   $0x80020c
  8006e0:	e8 61 fb ff ff       	call   800246 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006e8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006ee:	83 c4 10             	add    $0x10,%esp
  8006f1:	eb 05                	jmp    8006f8 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006f3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006f8:	c9                   	leave  
  8006f9:	c3                   	ret    

008006fa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006fa:	55                   	push   %ebp
  8006fb:	89 e5                	mov    %esp,%ebp
  8006fd:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800700:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800703:	50                   	push   %eax
  800704:	ff 75 10             	pushl  0x10(%ebp)
  800707:	ff 75 0c             	pushl  0xc(%ebp)
  80070a:	ff 75 08             	pushl  0x8(%ebp)
  80070d:	e8 9a ff ff ff       	call   8006ac <vsnprintf>
	va_end(ap);

	return rc;
}
  800712:	c9                   	leave  
  800713:	c3                   	ret    

00800714 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800714:	55                   	push   %ebp
  800715:	89 e5                	mov    %esp,%ebp
  800717:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80071a:	b8 00 00 00 00       	mov    $0x0,%eax
  80071f:	eb 03                	jmp    800724 <strlen+0x10>
		n++;
  800721:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800724:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800728:	75 f7                	jne    800721 <strlen+0xd>
		n++;
	return n;
}
  80072a:	5d                   	pop    %ebp
  80072b:	c3                   	ret    

0080072c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80072c:	55                   	push   %ebp
  80072d:	89 e5                	mov    %esp,%ebp
  80072f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800732:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800735:	ba 00 00 00 00       	mov    $0x0,%edx
  80073a:	eb 03                	jmp    80073f <strnlen+0x13>
		n++;
  80073c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80073f:	39 c2                	cmp    %eax,%edx
  800741:	74 08                	je     80074b <strnlen+0x1f>
  800743:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800747:	75 f3                	jne    80073c <strnlen+0x10>
  800749:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80074b:	5d                   	pop    %ebp
  80074c:	c3                   	ret    

0080074d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80074d:	55                   	push   %ebp
  80074e:	89 e5                	mov    %esp,%ebp
  800750:	53                   	push   %ebx
  800751:	8b 45 08             	mov    0x8(%ebp),%eax
  800754:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800757:	89 c2                	mov    %eax,%edx
  800759:	83 c2 01             	add    $0x1,%edx
  80075c:	83 c1 01             	add    $0x1,%ecx
  80075f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800763:	88 5a ff             	mov    %bl,-0x1(%edx)
  800766:	84 db                	test   %bl,%bl
  800768:	75 ef                	jne    800759 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80076a:	5b                   	pop    %ebx
  80076b:	5d                   	pop    %ebp
  80076c:	c3                   	ret    

0080076d <strcat>:

char *
strcat(char *dst, const char *src)
{
  80076d:	55                   	push   %ebp
  80076e:	89 e5                	mov    %esp,%ebp
  800770:	53                   	push   %ebx
  800771:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800774:	53                   	push   %ebx
  800775:	e8 9a ff ff ff       	call   800714 <strlen>
  80077a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80077d:	ff 75 0c             	pushl  0xc(%ebp)
  800780:	01 d8                	add    %ebx,%eax
  800782:	50                   	push   %eax
  800783:	e8 c5 ff ff ff       	call   80074d <strcpy>
	return dst;
}
  800788:	89 d8                	mov    %ebx,%eax
  80078a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80078d:	c9                   	leave  
  80078e:	c3                   	ret    

0080078f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  80078f:	55                   	push   %ebp
  800790:	89 e5                	mov    %esp,%ebp
  800792:	56                   	push   %esi
  800793:	53                   	push   %ebx
  800794:	8b 75 08             	mov    0x8(%ebp),%esi
  800797:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80079a:	89 f3                	mov    %esi,%ebx
  80079c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80079f:	89 f2                	mov    %esi,%edx
  8007a1:	eb 0f                	jmp    8007b2 <strncpy+0x23>
		*dst++ = *src;
  8007a3:	83 c2 01             	add    $0x1,%edx
  8007a6:	0f b6 01             	movzbl (%ecx),%eax
  8007a9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ac:	80 39 01             	cmpb   $0x1,(%ecx)
  8007af:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b2:	39 da                	cmp    %ebx,%edx
  8007b4:	75 ed                	jne    8007a3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007b6:	89 f0                	mov    %esi,%eax
  8007b8:	5b                   	pop    %ebx
  8007b9:	5e                   	pop    %esi
  8007ba:	5d                   	pop    %ebp
  8007bb:	c3                   	ret    

008007bc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007bc:	55                   	push   %ebp
  8007bd:	89 e5                	mov    %esp,%ebp
  8007bf:	56                   	push   %esi
  8007c0:	53                   	push   %ebx
  8007c1:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007c7:	8b 55 10             	mov    0x10(%ebp),%edx
  8007ca:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007cc:	85 d2                	test   %edx,%edx
  8007ce:	74 21                	je     8007f1 <strlcpy+0x35>
  8007d0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007d4:	89 f2                	mov    %esi,%edx
  8007d6:	eb 09                	jmp    8007e1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007d8:	83 c2 01             	add    $0x1,%edx
  8007db:	83 c1 01             	add    $0x1,%ecx
  8007de:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e1:	39 c2                	cmp    %eax,%edx
  8007e3:	74 09                	je     8007ee <strlcpy+0x32>
  8007e5:	0f b6 19             	movzbl (%ecx),%ebx
  8007e8:	84 db                	test   %bl,%bl
  8007ea:	75 ec                	jne    8007d8 <strlcpy+0x1c>
  8007ec:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007ee:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007f1:	29 f0                	sub    %esi,%eax
}
  8007f3:	5b                   	pop    %ebx
  8007f4:	5e                   	pop    %esi
  8007f5:	5d                   	pop    %ebp
  8007f6:	c3                   	ret    

008007f7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007f7:	55                   	push   %ebp
  8007f8:	89 e5                	mov    %esp,%ebp
  8007fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800800:	eb 06                	jmp    800808 <strcmp+0x11>
		p++, q++;
  800802:	83 c1 01             	add    $0x1,%ecx
  800805:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800808:	0f b6 01             	movzbl (%ecx),%eax
  80080b:	84 c0                	test   %al,%al
  80080d:	74 04                	je     800813 <strcmp+0x1c>
  80080f:	3a 02                	cmp    (%edx),%al
  800811:	74 ef                	je     800802 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800813:	0f b6 c0             	movzbl %al,%eax
  800816:	0f b6 12             	movzbl (%edx),%edx
  800819:	29 d0                	sub    %edx,%eax
}
  80081b:	5d                   	pop    %ebp
  80081c:	c3                   	ret    

0080081d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80081d:	55                   	push   %ebp
  80081e:	89 e5                	mov    %esp,%ebp
  800820:	53                   	push   %ebx
  800821:	8b 45 08             	mov    0x8(%ebp),%eax
  800824:	8b 55 0c             	mov    0xc(%ebp),%edx
  800827:	89 c3                	mov    %eax,%ebx
  800829:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80082c:	eb 06                	jmp    800834 <strncmp+0x17>
		n--, p++, q++;
  80082e:	83 c0 01             	add    $0x1,%eax
  800831:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800834:	39 d8                	cmp    %ebx,%eax
  800836:	74 15                	je     80084d <strncmp+0x30>
  800838:	0f b6 08             	movzbl (%eax),%ecx
  80083b:	84 c9                	test   %cl,%cl
  80083d:	74 04                	je     800843 <strncmp+0x26>
  80083f:	3a 0a                	cmp    (%edx),%cl
  800841:	74 eb                	je     80082e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800843:	0f b6 00             	movzbl (%eax),%eax
  800846:	0f b6 12             	movzbl (%edx),%edx
  800849:	29 d0                	sub    %edx,%eax
  80084b:	eb 05                	jmp    800852 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80084d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800852:	5b                   	pop    %ebx
  800853:	5d                   	pop    %ebp
  800854:	c3                   	ret    

00800855 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800855:	55                   	push   %ebp
  800856:	89 e5                	mov    %esp,%ebp
  800858:	8b 45 08             	mov    0x8(%ebp),%eax
  80085b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80085f:	eb 07                	jmp    800868 <strchr+0x13>
		if (*s == c)
  800861:	38 ca                	cmp    %cl,%dl
  800863:	74 0f                	je     800874 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800865:	83 c0 01             	add    $0x1,%eax
  800868:	0f b6 10             	movzbl (%eax),%edx
  80086b:	84 d2                	test   %dl,%dl
  80086d:	75 f2                	jne    800861 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80086f:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800874:	5d                   	pop    %ebp
  800875:	c3                   	ret    

00800876 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800876:	55                   	push   %ebp
  800877:	89 e5                	mov    %esp,%ebp
  800879:	8b 45 08             	mov    0x8(%ebp),%eax
  80087c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800880:	eb 03                	jmp    800885 <strfind+0xf>
  800882:	83 c0 01             	add    $0x1,%eax
  800885:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800888:	38 ca                	cmp    %cl,%dl
  80088a:	74 04                	je     800890 <strfind+0x1a>
  80088c:	84 d2                	test   %dl,%dl
  80088e:	75 f2                	jne    800882 <strfind+0xc>
			break;
	return (char *) s;
}
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	57                   	push   %edi
  800896:	56                   	push   %esi
  800897:	53                   	push   %ebx
  800898:	8b 7d 08             	mov    0x8(%ebp),%edi
  80089b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80089e:	85 c9                	test   %ecx,%ecx
  8008a0:	74 36                	je     8008d8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008a2:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008a8:	75 28                	jne    8008d2 <memset+0x40>
  8008aa:	f6 c1 03             	test   $0x3,%cl
  8008ad:	75 23                	jne    8008d2 <memset+0x40>
		c &= 0xFF;
  8008af:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008b3:	89 d3                	mov    %edx,%ebx
  8008b5:	c1 e3 08             	shl    $0x8,%ebx
  8008b8:	89 d6                	mov    %edx,%esi
  8008ba:	c1 e6 18             	shl    $0x18,%esi
  8008bd:	89 d0                	mov    %edx,%eax
  8008bf:	c1 e0 10             	shl    $0x10,%eax
  8008c2:	09 f0                	or     %esi,%eax
  8008c4:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008c6:	89 d8                	mov    %ebx,%eax
  8008c8:	09 d0                	or     %edx,%eax
  8008ca:	c1 e9 02             	shr    $0x2,%ecx
  8008cd:	fc                   	cld    
  8008ce:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d0:	eb 06                	jmp    8008d8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008d2:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008d5:	fc                   	cld    
  8008d6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008d8:	89 f8                	mov    %edi,%eax
  8008da:	5b                   	pop    %ebx
  8008db:	5e                   	pop    %esi
  8008dc:	5f                   	pop    %edi
  8008dd:	5d                   	pop    %ebp
  8008de:	c3                   	ret    

008008df <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008df:	55                   	push   %ebp
  8008e0:	89 e5                	mov    %esp,%ebp
  8008e2:	57                   	push   %edi
  8008e3:	56                   	push   %esi
  8008e4:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e7:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008ed:	39 c6                	cmp    %eax,%esi
  8008ef:	73 35                	jae    800926 <memmove+0x47>
  8008f1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008f4:	39 d0                	cmp    %edx,%eax
  8008f6:	73 2e                	jae    800926 <memmove+0x47>
		s += n;
		d += n;
  8008f8:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008fb:	89 d6                	mov    %edx,%esi
  8008fd:	09 fe                	or     %edi,%esi
  8008ff:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800905:	75 13                	jne    80091a <memmove+0x3b>
  800907:	f6 c1 03             	test   $0x3,%cl
  80090a:	75 0e                	jne    80091a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80090c:	83 ef 04             	sub    $0x4,%edi
  80090f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800912:	c1 e9 02             	shr    $0x2,%ecx
  800915:	fd                   	std    
  800916:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800918:	eb 09                	jmp    800923 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80091a:	83 ef 01             	sub    $0x1,%edi
  80091d:	8d 72 ff             	lea    -0x1(%edx),%esi
  800920:	fd                   	std    
  800921:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800923:	fc                   	cld    
  800924:	eb 1d                	jmp    800943 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800926:	89 f2                	mov    %esi,%edx
  800928:	09 c2                	or     %eax,%edx
  80092a:	f6 c2 03             	test   $0x3,%dl
  80092d:	75 0f                	jne    80093e <memmove+0x5f>
  80092f:	f6 c1 03             	test   $0x3,%cl
  800932:	75 0a                	jne    80093e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800934:	c1 e9 02             	shr    $0x2,%ecx
  800937:	89 c7                	mov    %eax,%edi
  800939:	fc                   	cld    
  80093a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093c:	eb 05                	jmp    800943 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80093e:	89 c7                	mov    %eax,%edi
  800940:	fc                   	cld    
  800941:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800943:	5e                   	pop    %esi
  800944:	5f                   	pop    %edi
  800945:	5d                   	pop    %ebp
  800946:	c3                   	ret    

00800947 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800947:	55                   	push   %ebp
  800948:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80094a:	ff 75 10             	pushl  0x10(%ebp)
  80094d:	ff 75 0c             	pushl  0xc(%ebp)
  800950:	ff 75 08             	pushl  0x8(%ebp)
  800953:	e8 87 ff ff ff       	call   8008df <memmove>
}
  800958:	c9                   	leave  
  800959:	c3                   	ret    

0080095a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80095a:	55                   	push   %ebp
  80095b:	89 e5                	mov    %esp,%ebp
  80095d:	56                   	push   %esi
  80095e:	53                   	push   %ebx
  80095f:	8b 45 08             	mov    0x8(%ebp),%eax
  800962:	8b 55 0c             	mov    0xc(%ebp),%edx
  800965:	89 c6                	mov    %eax,%esi
  800967:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80096a:	eb 1a                	jmp    800986 <memcmp+0x2c>
		if (*s1 != *s2)
  80096c:	0f b6 08             	movzbl (%eax),%ecx
  80096f:	0f b6 1a             	movzbl (%edx),%ebx
  800972:	38 d9                	cmp    %bl,%cl
  800974:	74 0a                	je     800980 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800976:	0f b6 c1             	movzbl %cl,%eax
  800979:	0f b6 db             	movzbl %bl,%ebx
  80097c:	29 d8                	sub    %ebx,%eax
  80097e:	eb 0f                	jmp    80098f <memcmp+0x35>
		s1++, s2++;
  800980:	83 c0 01             	add    $0x1,%eax
  800983:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800986:	39 f0                	cmp    %esi,%eax
  800988:	75 e2                	jne    80096c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80098a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80098f:	5b                   	pop    %ebx
  800990:	5e                   	pop    %esi
  800991:	5d                   	pop    %ebp
  800992:	c3                   	ret    

00800993 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800993:	55                   	push   %ebp
  800994:	89 e5                	mov    %esp,%ebp
  800996:	53                   	push   %ebx
  800997:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80099a:	89 c1                	mov    %eax,%ecx
  80099c:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  80099f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a3:	eb 0a                	jmp    8009af <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a5:	0f b6 10             	movzbl (%eax),%edx
  8009a8:	39 da                	cmp    %ebx,%edx
  8009aa:	74 07                	je     8009b3 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ac:	83 c0 01             	add    $0x1,%eax
  8009af:	39 c8                	cmp    %ecx,%eax
  8009b1:	72 f2                	jb     8009a5 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009b3:	5b                   	pop    %ebx
  8009b4:	5d                   	pop    %ebp
  8009b5:	c3                   	ret    

008009b6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009b6:	55                   	push   %ebp
  8009b7:	89 e5                	mov    %esp,%ebp
  8009b9:	57                   	push   %edi
  8009ba:	56                   	push   %esi
  8009bb:	53                   	push   %ebx
  8009bc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009bf:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c2:	eb 03                	jmp    8009c7 <strtol+0x11>
		s++;
  8009c4:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c7:	0f b6 01             	movzbl (%ecx),%eax
  8009ca:	3c 20                	cmp    $0x20,%al
  8009cc:	74 f6                	je     8009c4 <strtol+0xe>
  8009ce:	3c 09                	cmp    $0x9,%al
  8009d0:	74 f2                	je     8009c4 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009d2:	3c 2b                	cmp    $0x2b,%al
  8009d4:	75 0a                	jne    8009e0 <strtol+0x2a>
		s++;
  8009d6:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009d9:	bf 00 00 00 00       	mov    $0x0,%edi
  8009de:	eb 11                	jmp    8009f1 <strtol+0x3b>
  8009e0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009e5:	3c 2d                	cmp    $0x2d,%al
  8009e7:	75 08                	jne    8009f1 <strtol+0x3b>
		s++, neg = 1;
  8009e9:	83 c1 01             	add    $0x1,%ecx
  8009ec:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009f1:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009f7:	75 15                	jne    800a0e <strtol+0x58>
  8009f9:	80 39 30             	cmpb   $0x30,(%ecx)
  8009fc:	75 10                	jne    800a0e <strtol+0x58>
  8009fe:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a02:	75 7c                	jne    800a80 <strtol+0xca>
		s += 2, base = 16;
  800a04:	83 c1 02             	add    $0x2,%ecx
  800a07:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a0c:	eb 16                	jmp    800a24 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a0e:	85 db                	test   %ebx,%ebx
  800a10:	75 12                	jne    800a24 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a12:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a17:	80 39 30             	cmpb   $0x30,(%ecx)
  800a1a:	75 08                	jne    800a24 <strtol+0x6e>
		s++, base = 8;
  800a1c:	83 c1 01             	add    $0x1,%ecx
  800a1f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a24:	b8 00 00 00 00       	mov    $0x0,%eax
  800a29:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a2c:	0f b6 11             	movzbl (%ecx),%edx
  800a2f:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a32:	89 f3                	mov    %esi,%ebx
  800a34:	80 fb 09             	cmp    $0x9,%bl
  800a37:	77 08                	ja     800a41 <strtol+0x8b>
			dig = *s - '0';
  800a39:	0f be d2             	movsbl %dl,%edx
  800a3c:	83 ea 30             	sub    $0x30,%edx
  800a3f:	eb 22                	jmp    800a63 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a41:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a44:	89 f3                	mov    %esi,%ebx
  800a46:	80 fb 19             	cmp    $0x19,%bl
  800a49:	77 08                	ja     800a53 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a4b:	0f be d2             	movsbl %dl,%edx
  800a4e:	83 ea 57             	sub    $0x57,%edx
  800a51:	eb 10                	jmp    800a63 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a53:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a56:	89 f3                	mov    %esi,%ebx
  800a58:	80 fb 19             	cmp    $0x19,%bl
  800a5b:	77 16                	ja     800a73 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a5d:	0f be d2             	movsbl %dl,%edx
  800a60:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a63:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a66:	7d 0b                	jge    800a73 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a68:	83 c1 01             	add    $0x1,%ecx
  800a6b:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a6f:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a71:	eb b9                	jmp    800a2c <strtol+0x76>

	if (endptr)
  800a73:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a77:	74 0d                	je     800a86 <strtol+0xd0>
		*endptr = (char *) s;
  800a79:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a7c:	89 0e                	mov    %ecx,(%esi)
  800a7e:	eb 06                	jmp    800a86 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a80:	85 db                	test   %ebx,%ebx
  800a82:	74 98                	je     800a1c <strtol+0x66>
  800a84:	eb 9e                	jmp    800a24 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a86:	89 c2                	mov    %eax,%edx
  800a88:	f7 da                	neg    %edx
  800a8a:	85 ff                	test   %edi,%edi
  800a8c:	0f 45 c2             	cmovne %edx,%eax
}
  800a8f:	5b                   	pop    %ebx
  800a90:	5e                   	pop    %esi
  800a91:	5f                   	pop    %edi
  800a92:	5d                   	pop    %ebp
  800a93:	c3                   	ret    

00800a94 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a94:	55                   	push   %ebp
  800a95:	89 e5                	mov    %esp,%ebp
  800a97:	57                   	push   %edi
  800a98:	56                   	push   %esi
  800a99:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a9a:	b8 00 00 00 00       	mov    $0x0,%eax
  800a9f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aa2:	8b 55 08             	mov    0x8(%ebp),%edx
  800aa5:	89 c3                	mov    %eax,%ebx
  800aa7:	89 c7                	mov    %eax,%edi
  800aa9:	89 c6                	mov    %eax,%esi
  800aab:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aad:	5b                   	pop    %ebx
  800aae:	5e                   	pop    %esi
  800aaf:	5f                   	pop    %edi
  800ab0:	5d                   	pop    %ebp
  800ab1:	c3                   	ret    

00800ab2 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ab2:	55                   	push   %ebp
  800ab3:	89 e5                	mov    %esp,%ebp
  800ab5:	57                   	push   %edi
  800ab6:	56                   	push   %esi
  800ab7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ab8:	ba 00 00 00 00       	mov    $0x0,%edx
  800abd:	b8 01 00 00 00       	mov    $0x1,%eax
  800ac2:	89 d1                	mov    %edx,%ecx
  800ac4:	89 d3                	mov    %edx,%ebx
  800ac6:	89 d7                	mov    %edx,%edi
  800ac8:	89 d6                	mov    %edx,%esi
  800aca:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800acc:	5b                   	pop    %ebx
  800acd:	5e                   	pop    %esi
  800ace:	5f                   	pop    %edi
  800acf:	5d                   	pop    %ebp
  800ad0:	c3                   	ret    

00800ad1 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ad1:	55                   	push   %ebp
  800ad2:	89 e5                	mov    %esp,%ebp
  800ad4:	57                   	push   %edi
  800ad5:	56                   	push   %esi
  800ad6:	53                   	push   %ebx
  800ad7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ada:	b9 00 00 00 00       	mov    $0x0,%ecx
  800adf:	b8 03 00 00 00       	mov    $0x3,%eax
  800ae4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae7:	89 cb                	mov    %ecx,%ebx
  800ae9:	89 cf                	mov    %ecx,%edi
  800aeb:	89 ce                	mov    %ecx,%esi
  800aed:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800aef:	85 c0                	test   %eax,%eax
  800af1:	7e 17                	jle    800b0a <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800af3:	83 ec 0c             	sub    $0xc,%esp
  800af6:	50                   	push   %eax
  800af7:	6a 03                	push   $0x3
  800af9:	68 64 12 80 00       	push   $0x801264
  800afe:	6a 23                	push   $0x23
  800b00:	68 81 12 80 00       	push   $0x801281
  800b05:	e8 f5 01 00 00       	call   800cff <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b0d:	5b                   	pop    %ebx
  800b0e:	5e                   	pop    %esi
  800b0f:	5f                   	pop    %edi
  800b10:	5d                   	pop    %ebp
  800b11:	c3                   	ret    

00800b12 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b12:	55                   	push   %ebp
  800b13:	89 e5                	mov    %esp,%ebp
  800b15:	57                   	push   %edi
  800b16:	56                   	push   %esi
  800b17:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b18:	ba 00 00 00 00       	mov    $0x0,%edx
  800b1d:	b8 02 00 00 00       	mov    $0x2,%eax
  800b22:	89 d1                	mov    %edx,%ecx
  800b24:	89 d3                	mov    %edx,%ebx
  800b26:	89 d7                	mov    %edx,%edi
  800b28:	89 d6                	mov    %edx,%esi
  800b2a:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b2c:	5b                   	pop    %ebx
  800b2d:	5e                   	pop    %esi
  800b2e:	5f                   	pop    %edi
  800b2f:	5d                   	pop    %ebp
  800b30:	c3                   	ret    

00800b31 <sys_yield>:

void
sys_yield(void)
{
  800b31:	55                   	push   %ebp
  800b32:	89 e5                	mov    %esp,%ebp
  800b34:	57                   	push   %edi
  800b35:	56                   	push   %esi
  800b36:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b37:	ba 00 00 00 00       	mov    $0x0,%edx
  800b3c:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b41:	89 d1                	mov    %edx,%ecx
  800b43:	89 d3                	mov    %edx,%ebx
  800b45:	89 d7                	mov    %edx,%edi
  800b47:	89 d6                	mov    %edx,%esi
  800b49:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800b4b:	5b                   	pop    %ebx
  800b4c:	5e                   	pop    %esi
  800b4d:	5f                   	pop    %edi
  800b4e:	5d                   	pop    %ebp
  800b4f:	c3                   	ret    

00800b50 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800b50:	55                   	push   %ebp
  800b51:	89 e5                	mov    %esp,%ebp
  800b53:	57                   	push   %edi
  800b54:	56                   	push   %esi
  800b55:	53                   	push   %ebx
  800b56:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b59:	be 00 00 00 00       	mov    $0x0,%esi
  800b5e:	b8 04 00 00 00       	mov    $0x4,%eax
  800b63:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b66:	8b 55 08             	mov    0x8(%ebp),%edx
  800b69:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800b6c:	89 f7                	mov    %esi,%edi
  800b6e:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b70:	85 c0                	test   %eax,%eax
  800b72:	7e 17                	jle    800b8b <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b74:	83 ec 0c             	sub    $0xc,%esp
  800b77:	50                   	push   %eax
  800b78:	6a 04                	push   $0x4
  800b7a:	68 64 12 80 00       	push   $0x801264
  800b7f:	6a 23                	push   $0x23
  800b81:	68 81 12 80 00       	push   $0x801281
  800b86:	e8 74 01 00 00       	call   800cff <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800b8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b8e:	5b                   	pop    %ebx
  800b8f:	5e                   	pop    %esi
  800b90:	5f                   	pop    %edi
  800b91:	5d                   	pop    %ebp
  800b92:	c3                   	ret    

00800b93 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b93:	55                   	push   %ebp
  800b94:	89 e5                	mov    %esp,%ebp
  800b96:	57                   	push   %edi
  800b97:	56                   	push   %esi
  800b98:	53                   	push   %ebx
  800b99:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b9c:	b8 05 00 00 00       	mov    $0x5,%eax
  800ba1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ba4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ba7:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800baa:	8b 7d 14             	mov    0x14(%ebp),%edi
  800bad:	8b 75 18             	mov    0x18(%ebp),%esi
  800bb0:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bb2:	85 c0                	test   %eax,%eax
  800bb4:	7e 17                	jle    800bcd <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bb6:	83 ec 0c             	sub    $0xc,%esp
  800bb9:	50                   	push   %eax
  800bba:	6a 05                	push   $0x5
  800bbc:	68 64 12 80 00       	push   $0x801264
  800bc1:	6a 23                	push   $0x23
  800bc3:	68 81 12 80 00       	push   $0x801281
  800bc8:	e8 32 01 00 00       	call   800cff <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800bcd:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bd0:	5b                   	pop    %ebx
  800bd1:	5e                   	pop    %esi
  800bd2:	5f                   	pop    %edi
  800bd3:	5d                   	pop    %ebp
  800bd4:	c3                   	ret    

00800bd5 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800bd5:	55                   	push   %ebp
  800bd6:	89 e5                	mov    %esp,%ebp
  800bd8:	57                   	push   %edi
  800bd9:	56                   	push   %esi
  800bda:	53                   	push   %ebx
  800bdb:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bde:	bb 00 00 00 00       	mov    $0x0,%ebx
  800be3:	b8 06 00 00 00       	mov    $0x6,%eax
  800be8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800beb:	8b 55 08             	mov    0x8(%ebp),%edx
  800bee:	89 df                	mov    %ebx,%edi
  800bf0:	89 de                	mov    %ebx,%esi
  800bf2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bf4:	85 c0                	test   %eax,%eax
  800bf6:	7e 17                	jle    800c0f <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bf8:	83 ec 0c             	sub    $0xc,%esp
  800bfb:	50                   	push   %eax
  800bfc:	6a 06                	push   $0x6
  800bfe:	68 64 12 80 00       	push   $0x801264
  800c03:	6a 23                	push   $0x23
  800c05:	68 81 12 80 00       	push   $0x801281
  800c0a:	e8 f0 00 00 00       	call   800cff <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c12:	5b                   	pop    %ebx
  800c13:	5e                   	pop    %esi
  800c14:	5f                   	pop    %edi
  800c15:	5d                   	pop    %ebp
  800c16:	c3                   	ret    

00800c17 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c17:	55                   	push   %ebp
  800c18:	89 e5                	mov    %esp,%ebp
  800c1a:	57                   	push   %edi
  800c1b:	56                   	push   %esi
  800c1c:	53                   	push   %ebx
  800c1d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c20:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c25:	b8 08 00 00 00       	mov    $0x8,%eax
  800c2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c2d:	8b 55 08             	mov    0x8(%ebp),%edx
  800c30:	89 df                	mov    %ebx,%edi
  800c32:	89 de                	mov    %ebx,%esi
  800c34:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c36:	85 c0                	test   %eax,%eax
  800c38:	7e 17                	jle    800c51 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c3a:	83 ec 0c             	sub    $0xc,%esp
  800c3d:	50                   	push   %eax
  800c3e:	6a 08                	push   $0x8
  800c40:	68 64 12 80 00       	push   $0x801264
  800c45:	6a 23                	push   $0x23
  800c47:	68 81 12 80 00       	push   $0x801281
  800c4c:	e8 ae 00 00 00       	call   800cff <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800c51:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c54:	5b                   	pop    %ebx
  800c55:	5e                   	pop    %esi
  800c56:	5f                   	pop    %edi
  800c57:	5d                   	pop    %ebp
  800c58:	c3                   	ret    

00800c59 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800c59:	55                   	push   %ebp
  800c5a:	89 e5                	mov    %esp,%ebp
  800c5c:	57                   	push   %edi
  800c5d:	56                   	push   %esi
  800c5e:	53                   	push   %ebx
  800c5f:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c62:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c67:	b8 09 00 00 00       	mov    $0x9,%eax
  800c6c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c6f:	8b 55 08             	mov    0x8(%ebp),%edx
  800c72:	89 df                	mov    %ebx,%edi
  800c74:	89 de                	mov    %ebx,%esi
  800c76:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c78:	85 c0                	test   %eax,%eax
  800c7a:	7e 17                	jle    800c93 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c7c:	83 ec 0c             	sub    $0xc,%esp
  800c7f:	50                   	push   %eax
  800c80:	6a 09                	push   $0x9
  800c82:	68 64 12 80 00       	push   $0x801264
  800c87:	6a 23                	push   $0x23
  800c89:	68 81 12 80 00       	push   $0x801281
  800c8e:	e8 6c 00 00 00       	call   800cff <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800c93:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c96:	5b                   	pop    %ebx
  800c97:	5e                   	pop    %esi
  800c98:	5f                   	pop    %edi
  800c99:	5d                   	pop    %ebp
  800c9a:	c3                   	ret    

00800c9b <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800c9b:	55                   	push   %ebp
  800c9c:	89 e5                	mov    %esp,%ebp
  800c9e:	57                   	push   %edi
  800c9f:	56                   	push   %esi
  800ca0:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ca1:	be 00 00 00 00       	mov    $0x0,%esi
  800ca6:	b8 0b 00 00 00       	mov    $0xb,%eax
  800cab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cae:	8b 55 08             	mov    0x8(%ebp),%edx
  800cb1:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cb4:	8b 7d 14             	mov    0x14(%ebp),%edi
  800cb7:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800cb9:	5b                   	pop    %ebx
  800cba:	5e                   	pop    %esi
  800cbb:	5f                   	pop    %edi
  800cbc:	5d                   	pop    %ebp
  800cbd:	c3                   	ret    

00800cbe <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800cbe:	55                   	push   %ebp
  800cbf:	89 e5                	mov    %esp,%ebp
  800cc1:	57                   	push   %edi
  800cc2:	56                   	push   %esi
  800cc3:	53                   	push   %ebx
  800cc4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cc7:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ccc:	b8 0c 00 00 00       	mov    $0xc,%eax
  800cd1:	8b 55 08             	mov    0x8(%ebp),%edx
  800cd4:	89 cb                	mov    %ecx,%ebx
  800cd6:	89 cf                	mov    %ecx,%edi
  800cd8:	89 ce                	mov    %ecx,%esi
  800cda:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cdc:	85 c0                	test   %eax,%eax
  800cde:	7e 17                	jle    800cf7 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ce0:	83 ec 0c             	sub    $0xc,%esp
  800ce3:	50                   	push   %eax
  800ce4:	6a 0c                	push   $0xc
  800ce6:	68 64 12 80 00       	push   $0x801264
  800ceb:	6a 23                	push   $0x23
  800ced:	68 81 12 80 00       	push   $0x801281
  800cf2:	e8 08 00 00 00       	call   800cff <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800cf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cfa:	5b                   	pop    %ebx
  800cfb:	5e                   	pop    %esi
  800cfc:	5f                   	pop    %edi
  800cfd:	5d                   	pop    %ebp
  800cfe:	c3                   	ret    

00800cff <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800cff:	55                   	push   %ebp
  800d00:	89 e5                	mov    %esp,%ebp
  800d02:	56                   	push   %esi
  800d03:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800d04:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800d07:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800d0d:	e8 00 fe ff ff       	call   800b12 <sys_getenvid>
  800d12:	83 ec 0c             	sub    $0xc,%esp
  800d15:	ff 75 0c             	pushl  0xc(%ebp)
  800d18:	ff 75 08             	pushl  0x8(%ebp)
  800d1b:	56                   	push   %esi
  800d1c:	50                   	push   %eax
  800d1d:	68 90 12 80 00       	push   $0x801290
  800d22:	e8 22 f4 ff ff       	call   800149 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800d27:	83 c4 18             	add    $0x18,%esp
  800d2a:	53                   	push   %ebx
  800d2b:	ff 75 10             	pushl  0x10(%ebp)
  800d2e:	e8 c5 f3 ff ff       	call   8000f8 <vcprintf>
	cprintf("\n");
  800d33:	c7 04 24 ec 0f 80 00 	movl   $0x800fec,(%esp)
  800d3a:	e8 0a f4 ff ff       	call   800149 <cprintf>
  800d3f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d42:	cc                   	int3   
  800d43:	eb fd                	jmp    800d42 <_panic+0x43>
  800d45:	66 90                	xchg   %ax,%ax
  800d47:	66 90                	xchg   %ax,%ax
  800d49:	66 90                	xchg   %ax,%ax
  800d4b:	66 90                	xchg   %ax,%ax
  800d4d:	66 90                	xchg   %ax,%ax
  800d4f:	90                   	nop

00800d50 <__udivdi3>:
  800d50:	55                   	push   %ebp
  800d51:	57                   	push   %edi
  800d52:	56                   	push   %esi
  800d53:	53                   	push   %ebx
  800d54:	83 ec 1c             	sub    $0x1c,%esp
  800d57:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800d5b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800d5f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800d63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800d67:	85 f6                	test   %esi,%esi
  800d69:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d6d:	89 ca                	mov    %ecx,%edx
  800d6f:	89 f8                	mov    %edi,%eax
  800d71:	75 3d                	jne    800db0 <__udivdi3+0x60>
  800d73:	39 cf                	cmp    %ecx,%edi
  800d75:	0f 87 c5 00 00 00    	ja     800e40 <__udivdi3+0xf0>
  800d7b:	85 ff                	test   %edi,%edi
  800d7d:	89 fd                	mov    %edi,%ebp
  800d7f:	75 0b                	jne    800d8c <__udivdi3+0x3c>
  800d81:	b8 01 00 00 00       	mov    $0x1,%eax
  800d86:	31 d2                	xor    %edx,%edx
  800d88:	f7 f7                	div    %edi
  800d8a:	89 c5                	mov    %eax,%ebp
  800d8c:	89 c8                	mov    %ecx,%eax
  800d8e:	31 d2                	xor    %edx,%edx
  800d90:	f7 f5                	div    %ebp
  800d92:	89 c1                	mov    %eax,%ecx
  800d94:	89 d8                	mov    %ebx,%eax
  800d96:	89 cf                	mov    %ecx,%edi
  800d98:	f7 f5                	div    %ebp
  800d9a:	89 c3                	mov    %eax,%ebx
  800d9c:	89 d8                	mov    %ebx,%eax
  800d9e:	89 fa                	mov    %edi,%edx
  800da0:	83 c4 1c             	add    $0x1c,%esp
  800da3:	5b                   	pop    %ebx
  800da4:	5e                   	pop    %esi
  800da5:	5f                   	pop    %edi
  800da6:	5d                   	pop    %ebp
  800da7:	c3                   	ret    
  800da8:	90                   	nop
  800da9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800db0:	39 ce                	cmp    %ecx,%esi
  800db2:	77 74                	ja     800e28 <__udivdi3+0xd8>
  800db4:	0f bd fe             	bsr    %esi,%edi
  800db7:	83 f7 1f             	xor    $0x1f,%edi
  800dba:	0f 84 98 00 00 00    	je     800e58 <__udivdi3+0x108>
  800dc0:	bb 20 00 00 00       	mov    $0x20,%ebx
  800dc5:	89 f9                	mov    %edi,%ecx
  800dc7:	89 c5                	mov    %eax,%ebp
  800dc9:	29 fb                	sub    %edi,%ebx
  800dcb:	d3 e6                	shl    %cl,%esi
  800dcd:	89 d9                	mov    %ebx,%ecx
  800dcf:	d3 ed                	shr    %cl,%ebp
  800dd1:	89 f9                	mov    %edi,%ecx
  800dd3:	d3 e0                	shl    %cl,%eax
  800dd5:	09 ee                	or     %ebp,%esi
  800dd7:	89 d9                	mov    %ebx,%ecx
  800dd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800ddd:	89 d5                	mov    %edx,%ebp
  800ddf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800de3:	d3 ed                	shr    %cl,%ebp
  800de5:	89 f9                	mov    %edi,%ecx
  800de7:	d3 e2                	shl    %cl,%edx
  800de9:	89 d9                	mov    %ebx,%ecx
  800deb:	d3 e8                	shr    %cl,%eax
  800ded:	09 c2                	or     %eax,%edx
  800def:	89 d0                	mov    %edx,%eax
  800df1:	89 ea                	mov    %ebp,%edx
  800df3:	f7 f6                	div    %esi
  800df5:	89 d5                	mov    %edx,%ebp
  800df7:	89 c3                	mov    %eax,%ebx
  800df9:	f7 64 24 0c          	mull   0xc(%esp)
  800dfd:	39 d5                	cmp    %edx,%ebp
  800dff:	72 10                	jb     800e11 <__udivdi3+0xc1>
  800e01:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e05:	89 f9                	mov    %edi,%ecx
  800e07:	d3 e6                	shl    %cl,%esi
  800e09:	39 c6                	cmp    %eax,%esi
  800e0b:	73 07                	jae    800e14 <__udivdi3+0xc4>
  800e0d:	39 d5                	cmp    %edx,%ebp
  800e0f:	75 03                	jne    800e14 <__udivdi3+0xc4>
  800e11:	83 eb 01             	sub    $0x1,%ebx
  800e14:	31 ff                	xor    %edi,%edi
  800e16:	89 d8                	mov    %ebx,%eax
  800e18:	89 fa                	mov    %edi,%edx
  800e1a:	83 c4 1c             	add    $0x1c,%esp
  800e1d:	5b                   	pop    %ebx
  800e1e:	5e                   	pop    %esi
  800e1f:	5f                   	pop    %edi
  800e20:	5d                   	pop    %ebp
  800e21:	c3                   	ret    
  800e22:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e28:	31 ff                	xor    %edi,%edi
  800e2a:	31 db                	xor    %ebx,%ebx
  800e2c:	89 d8                	mov    %ebx,%eax
  800e2e:	89 fa                	mov    %edi,%edx
  800e30:	83 c4 1c             	add    $0x1c,%esp
  800e33:	5b                   	pop    %ebx
  800e34:	5e                   	pop    %esi
  800e35:	5f                   	pop    %edi
  800e36:	5d                   	pop    %ebp
  800e37:	c3                   	ret    
  800e38:	90                   	nop
  800e39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e40:	89 d8                	mov    %ebx,%eax
  800e42:	f7 f7                	div    %edi
  800e44:	31 ff                	xor    %edi,%edi
  800e46:	89 c3                	mov    %eax,%ebx
  800e48:	89 d8                	mov    %ebx,%eax
  800e4a:	89 fa                	mov    %edi,%edx
  800e4c:	83 c4 1c             	add    $0x1c,%esp
  800e4f:	5b                   	pop    %ebx
  800e50:	5e                   	pop    %esi
  800e51:	5f                   	pop    %edi
  800e52:	5d                   	pop    %ebp
  800e53:	c3                   	ret    
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	39 ce                	cmp    %ecx,%esi
  800e5a:	72 0c                	jb     800e68 <__udivdi3+0x118>
  800e5c:	31 db                	xor    %ebx,%ebx
  800e5e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800e62:	0f 87 34 ff ff ff    	ja     800d9c <__udivdi3+0x4c>
  800e68:	bb 01 00 00 00       	mov    $0x1,%ebx
  800e6d:	e9 2a ff ff ff       	jmp    800d9c <__udivdi3+0x4c>
  800e72:	66 90                	xchg   %ax,%ax
  800e74:	66 90                	xchg   %ax,%ax
  800e76:	66 90                	xchg   %ax,%ax
  800e78:	66 90                	xchg   %ax,%ax
  800e7a:	66 90                	xchg   %ax,%ax
  800e7c:	66 90                	xchg   %ax,%ax
  800e7e:	66 90                	xchg   %ax,%ax

00800e80 <__umoddi3>:
  800e80:	55                   	push   %ebp
  800e81:	57                   	push   %edi
  800e82:	56                   	push   %esi
  800e83:	53                   	push   %ebx
  800e84:	83 ec 1c             	sub    $0x1c,%esp
  800e87:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800e8b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800e8f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800e93:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800e97:	85 d2                	test   %edx,%edx
  800e99:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800e9d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ea1:	89 f3                	mov    %esi,%ebx
  800ea3:	89 3c 24             	mov    %edi,(%esp)
  800ea6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800eaa:	75 1c                	jne    800ec8 <__umoddi3+0x48>
  800eac:	39 f7                	cmp    %esi,%edi
  800eae:	76 50                	jbe    800f00 <__umoddi3+0x80>
  800eb0:	89 c8                	mov    %ecx,%eax
  800eb2:	89 f2                	mov    %esi,%edx
  800eb4:	f7 f7                	div    %edi
  800eb6:	89 d0                	mov    %edx,%eax
  800eb8:	31 d2                	xor    %edx,%edx
  800eba:	83 c4 1c             	add    $0x1c,%esp
  800ebd:	5b                   	pop    %ebx
  800ebe:	5e                   	pop    %esi
  800ebf:	5f                   	pop    %edi
  800ec0:	5d                   	pop    %ebp
  800ec1:	c3                   	ret    
  800ec2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ec8:	39 f2                	cmp    %esi,%edx
  800eca:	89 d0                	mov    %edx,%eax
  800ecc:	77 52                	ja     800f20 <__umoddi3+0xa0>
  800ece:	0f bd ea             	bsr    %edx,%ebp
  800ed1:	83 f5 1f             	xor    $0x1f,%ebp
  800ed4:	75 5a                	jne    800f30 <__umoddi3+0xb0>
  800ed6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800eda:	0f 82 e0 00 00 00    	jb     800fc0 <__umoddi3+0x140>
  800ee0:	39 0c 24             	cmp    %ecx,(%esp)
  800ee3:	0f 86 d7 00 00 00    	jbe    800fc0 <__umoddi3+0x140>
  800ee9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800eed:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ef1:	83 c4 1c             	add    $0x1c,%esp
  800ef4:	5b                   	pop    %ebx
  800ef5:	5e                   	pop    %esi
  800ef6:	5f                   	pop    %edi
  800ef7:	5d                   	pop    %ebp
  800ef8:	c3                   	ret    
  800ef9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f00:	85 ff                	test   %edi,%edi
  800f02:	89 fd                	mov    %edi,%ebp
  800f04:	75 0b                	jne    800f11 <__umoddi3+0x91>
  800f06:	b8 01 00 00 00       	mov    $0x1,%eax
  800f0b:	31 d2                	xor    %edx,%edx
  800f0d:	f7 f7                	div    %edi
  800f0f:	89 c5                	mov    %eax,%ebp
  800f11:	89 f0                	mov    %esi,%eax
  800f13:	31 d2                	xor    %edx,%edx
  800f15:	f7 f5                	div    %ebp
  800f17:	89 c8                	mov    %ecx,%eax
  800f19:	f7 f5                	div    %ebp
  800f1b:	89 d0                	mov    %edx,%eax
  800f1d:	eb 99                	jmp    800eb8 <__umoddi3+0x38>
  800f1f:	90                   	nop
  800f20:	89 c8                	mov    %ecx,%eax
  800f22:	89 f2                	mov    %esi,%edx
  800f24:	83 c4 1c             	add    $0x1c,%esp
  800f27:	5b                   	pop    %ebx
  800f28:	5e                   	pop    %esi
  800f29:	5f                   	pop    %edi
  800f2a:	5d                   	pop    %ebp
  800f2b:	c3                   	ret    
  800f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f30:	8b 34 24             	mov    (%esp),%esi
  800f33:	bf 20 00 00 00       	mov    $0x20,%edi
  800f38:	89 e9                	mov    %ebp,%ecx
  800f3a:	29 ef                	sub    %ebp,%edi
  800f3c:	d3 e0                	shl    %cl,%eax
  800f3e:	89 f9                	mov    %edi,%ecx
  800f40:	89 f2                	mov    %esi,%edx
  800f42:	d3 ea                	shr    %cl,%edx
  800f44:	89 e9                	mov    %ebp,%ecx
  800f46:	09 c2                	or     %eax,%edx
  800f48:	89 d8                	mov    %ebx,%eax
  800f4a:	89 14 24             	mov    %edx,(%esp)
  800f4d:	89 f2                	mov    %esi,%edx
  800f4f:	d3 e2                	shl    %cl,%edx
  800f51:	89 f9                	mov    %edi,%ecx
  800f53:	89 54 24 04          	mov    %edx,0x4(%esp)
  800f57:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f5b:	d3 e8                	shr    %cl,%eax
  800f5d:	89 e9                	mov    %ebp,%ecx
  800f5f:	89 c6                	mov    %eax,%esi
  800f61:	d3 e3                	shl    %cl,%ebx
  800f63:	89 f9                	mov    %edi,%ecx
  800f65:	89 d0                	mov    %edx,%eax
  800f67:	d3 e8                	shr    %cl,%eax
  800f69:	89 e9                	mov    %ebp,%ecx
  800f6b:	09 d8                	or     %ebx,%eax
  800f6d:	89 d3                	mov    %edx,%ebx
  800f6f:	89 f2                	mov    %esi,%edx
  800f71:	f7 34 24             	divl   (%esp)
  800f74:	89 d6                	mov    %edx,%esi
  800f76:	d3 e3                	shl    %cl,%ebx
  800f78:	f7 64 24 04          	mull   0x4(%esp)
  800f7c:	39 d6                	cmp    %edx,%esi
  800f7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800f82:	89 d1                	mov    %edx,%ecx
  800f84:	89 c3                	mov    %eax,%ebx
  800f86:	72 08                	jb     800f90 <__umoddi3+0x110>
  800f88:	75 11                	jne    800f9b <__umoddi3+0x11b>
  800f8a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800f8e:	73 0b                	jae    800f9b <__umoddi3+0x11b>
  800f90:	2b 44 24 04          	sub    0x4(%esp),%eax
  800f94:	1b 14 24             	sbb    (%esp),%edx
  800f97:	89 d1                	mov    %edx,%ecx
  800f99:	89 c3                	mov    %eax,%ebx
  800f9b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800f9f:	29 da                	sub    %ebx,%edx
  800fa1:	19 ce                	sbb    %ecx,%esi
  800fa3:	89 f9                	mov    %edi,%ecx
  800fa5:	89 f0                	mov    %esi,%eax
  800fa7:	d3 e0                	shl    %cl,%eax
  800fa9:	89 e9                	mov    %ebp,%ecx
  800fab:	d3 ea                	shr    %cl,%edx
  800fad:	89 e9                	mov    %ebp,%ecx
  800faf:	d3 ee                	shr    %cl,%esi
  800fb1:	09 d0                	or     %edx,%eax
  800fb3:	89 f2                	mov    %esi,%edx
  800fb5:	83 c4 1c             	add    $0x1c,%esp
  800fb8:	5b                   	pop    %ebx
  800fb9:	5e                   	pop    %esi
  800fba:	5f                   	pop    %edi
  800fbb:	5d                   	pop    %ebp
  800fbc:	c3                   	ret    
  800fbd:	8d 76 00             	lea    0x0(%esi),%esi
  800fc0:	29 f9                	sub    %edi,%ecx
  800fc2:	19 d6                	sbb    %edx,%esi
  800fc4:	89 74 24 04          	mov    %esi,0x4(%esp)
  800fc8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fcc:	e9 18 ff ff ff       	jmp    800ee9 <__umoddi3+0x69>
