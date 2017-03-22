
obj/user/divzero:     file format elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 e0 0f 80 00       	push   $0x800fe0
  800056:	e8 f0 00 00 00       	call   80014b <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  80006b:	e8 a4 0a 00 00       	call   800b14 <sys_getenvid>
  800070:	25 ff 03 00 00       	and    $0x3ff,%eax
  800075:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800078:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007d:	a3 08 20 80 00       	mov    %eax,0x802008
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800082:	85 db                	test   %ebx,%ebx
  800084:	7e 07                	jle    80008d <libmain+0x2d>
		binaryname = argv[0];
  800086:	8b 06                	mov    (%esi),%eax
  800088:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008d:	83 ec 08             	sub    $0x8,%esp
  800090:	56                   	push   %esi
  800091:	53                   	push   %ebx
  800092:	e8 9c ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800097:	e8 0a 00 00 00       	call   8000a6 <exit>
}
  80009c:	83 c4 10             	add    $0x10,%esp
  80009f:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a2:	5b                   	pop    %ebx
  8000a3:	5e                   	pop    %esi
  8000a4:	5d                   	pop    %ebp
  8000a5:	c3                   	ret    

008000a6 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a6:	55                   	push   %ebp
  8000a7:	89 e5                	mov    %esp,%ebp
  8000a9:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000ac:	6a 00                	push   $0x0
  8000ae:	e8 20 0a 00 00       	call   800ad3 <sys_env_destroy>
}
  8000b3:	83 c4 10             	add    $0x10,%esp
  8000b6:	c9                   	leave  
  8000b7:	c3                   	ret    

008000b8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b8:	55                   	push   %ebp
  8000b9:	89 e5                	mov    %esp,%ebp
  8000bb:	53                   	push   %ebx
  8000bc:	83 ec 04             	sub    $0x4,%esp
  8000bf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c2:	8b 13                	mov    (%ebx),%edx
  8000c4:	8d 42 01             	lea    0x1(%edx),%eax
  8000c7:	89 03                	mov    %eax,(%ebx)
  8000c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d5:	75 1a                	jne    8000f1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000d7:	83 ec 08             	sub    $0x8,%esp
  8000da:	68 ff 00 00 00       	push   $0xff
  8000df:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e2:	50                   	push   %eax
  8000e3:	e8 ae 09 00 00       	call   800a96 <sys_cputs>
		b->idx = 0;
  8000e8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000ee:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f8:	c9                   	leave  
  8000f9:	c3                   	ret    

008000fa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fa:	55                   	push   %ebp
  8000fb:	89 e5                	mov    %esp,%ebp
  8000fd:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800103:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010a:	00 00 00 
	b.cnt = 0;
  80010d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800114:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800117:	ff 75 0c             	pushl  0xc(%ebp)
  80011a:	ff 75 08             	pushl  0x8(%ebp)
  80011d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800123:	50                   	push   %eax
  800124:	68 b8 00 80 00       	push   $0x8000b8
  800129:	e8 1a 01 00 00       	call   800248 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012e:	83 c4 08             	add    $0x8,%esp
  800131:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800137:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013d:	50                   	push   %eax
  80013e:	e8 53 09 00 00       	call   800a96 <sys_cputs>

	return b.cnt;
}
  800143:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800149:	c9                   	leave  
  80014a:	c3                   	ret    

0080014b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014b:	55                   	push   %ebp
  80014c:	89 e5                	mov    %esp,%ebp
  80014e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800151:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800154:	50                   	push   %eax
  800155:	ff 75 08             	pushl  0x8(%ebp)
  800158:	e8 9d ff ff ff       	call   8000fa <vcprintf>
	va_end(ap);

	return cnt;
}
  80015d:	c9                   	leave  
  80015e:	c3                   	ret    

0080015f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80015f:	55                   	push   %ebp
  800160:	89 e5                	mov    %esp,%ebp
  800162:	57                   	push   %edi
  800163:	56                   	push   %esi
  800164:	53                   	push   %ebx
  800165:	83 ec 1c             	sub    $0x1c,%esp
  800168:	89 c7                	mov    %eax,%edi
  80016a:	89 d6                	mov    %edx,%esi
  80016c:	8b 45 08             	mov    0x8(%ebp),%eax
  80016f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800172:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800175:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800178:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800180:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800183:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800186:	39 d3                	cmp    %edx,%ebx
  800188:	72 05                	jb     80018f <printnum+0x30>
  80018a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80018d:	77 45                	ja     8001d4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80018f:	83 ec 0c             	sub    $0xc,%esp
  800192:	ff 75 18             	pushl  0x18(%ebp)
  800195:	8b 45 14             	mov    0x14(%ebp),%eax
  800198:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019b:	53                   	push   %ebx
  80019c:	ff 75 10             	pushl  0x10(%ebp)
  80019f:	83 ec 08             	sub    $0x8,%esp
  8001a2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a5:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a8:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ab:	ff 75 d8             	pushl  -0x28(%ebp)
  8001ae:	e8 9d 0b 00 00       	call   800d50 <__udivdi3>
  8001b3:	83 c4 18             	add    $0x18,%esp
  8001b6:	52                   	push   %edx
  8001b7:	50                   	push   %eax
  8001b8:	89 f2                	mov    %esi,%edx
  8001ba:	89 f8                	mov    %edi,%eax
  8001bc:	e8 9e ff ff ff       	call   80015f <printnum>
  8001c1:	83 c4 20             	add    $0x20,%esp
  8001c4:	eb 18                	jmp    8001de <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c6:	83 ec 08             	sub    $0x8,%esp
  8001c9:	56                   	push   %esi
  8001ca:	ff 75 18             	pushl  0x18(%ebp)
  8001cd:	ff d7                	call   *%edi
  8001cf:	83 c4 10             	add    $0x10,%esp
  8001d2:	eb 03                	jmp    8001d7 <printnum+0x78>
  8001d4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001d7:	83 eb 01             	sub    $0x1,%ebx
  8001da:	85 db                	test   %ebx,%ebx
  8001dc:	7f e8                	jg     8001c6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001de:	83 ec 08             	sub    $0x8,%esp
  8001e1:	56                   	push   %esi
  8001e2:	83 ec 04             	sub    $0x4,%esp
  8001e5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001eb:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ee:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f1:	e8 8a 0c 00 00       	call   800e80 <__umoddi3>
  8001f6:	83 c4 14             	add    $0x14,%esp
  8001f9:	0f be 80 f8 0f 80 00 	movsbl 0x800ff8(%eax),%eax
  800200:	50                   	push   %eax
  800201:	ff d7                	call   *%edi
}
  800203:	83 c4 10             	add    $0x10,%esp
  800206:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800209:	5b                   	pop    %ebx
  80020a:	5e                   	pop    %esi
  80020b:	5f                   	pop    %edi
  80020c:	5d                   	pop    %ebp
  80020d:	c3                   	ret    

0080020e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80020e:	55                   	push   %ebp
  80020f:	89 e5                	mov    %esp,%ebp
  800211:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800214:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800218:	8b 10                	mov    (%eax),%edx
  80021a:	3b 50 04             	cmp    0x4(%eax),%edx
  80021d:	73 0a                	jae    800229 <sprintputch+0x1b>
		*b->buf++ = ch;
  80021f:	8d 4a 01             	lea    0x1(%edx),%ecx
  800222:	89 08                	mov    %ecx,(%eax)
  800224:	8b 45 08             	mov    0x8(%ebp),%eax
  800227:	88 02                	mov    %al,(%edx)
}
  800229:	5d                   	pop    %ebp
  80022a:	c3                   	ret    

0080022b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80022b:	55                   	push   %ebp
  80022c:	89 e5                	mov    %esp,%ebp
  80022e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800231:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800234:	50                   	push   %eax
  800235:	ff 75 10             	pushl  0x10(%ebp)
  800238:	ff 75 0c             	pushl  0xc(%ebp)
  80023b:	ff 75 08             	pushl  0x8(%ebp)
  80023e:	e8 05 00 00 00       	call   800248 <vprintfmt>
	va_end(ap);
}
  800243:	83 c4 10             	add    $0x10,%esp
  800246:	c9                   	leave  
  800247:	c3                   	ret    

00800248 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800248:	55                   	push   %ebp
  800249:	89 e5                	mov    %esp,%ebp
  80024b:	57                   	push   %edi
  80024c:	56                   	push   %esi
  80024d:	53                   	push   %ebx
  80024e:	83 ec 2c             	sub    $0x2c,%esp
  800251:	8b 75 08             	mov    0x8(%ebp),%esi
  800254:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800257:	8b 7d 10             	mov    0x10(%ebp),%edi
  80025a:	eb 12                	jmp    80026e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80025c:	85 c0                	test   %eax,%eax
  80025e:	0f 84 42 04 00 00    	je     8006a6 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  800264:	83 ec 08             	sub    $0x8,%esp
  800267:	53                   	push   %ebx
  800268:	50                   	push   %eax
  800269:	ff d6                	call   *%esi
  80026b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80026e:	83 c7 01             	add    $0x1,%edi
  800271:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800275:	83 f8 25             	cmp    $0x25,%eax
  800278:	75 e2                	jne    80025c <vprintfmt+0x14>
  80027a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80027e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800285:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80028c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800293:	b9 00 00 00 00       	mov    $0x0,%ecx
  800298:	eb 07                	jmp    8002a1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80029a:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80029d:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002a1:	8d 47 01             	lea    0x1(%edi),%eax
  8002a4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002a7:	0f b6 07             	movzbl (%edi),%eax
  8002aa:	0f b6 d0             	movzbl %al,%edx
  8002ad:	83 e8 23             	sub    $0x23,%eax
  8002b0:	3c 55                	cmp    $0x55,%al
  8002b2:	0f 87 d3 03 00 00    	ja     80068b <vprintfmt+0x443>
  8002b8:	0f b6 c0             	movzbl %al,%eax
  8002bb:	ff 24 85 c0 10 80 00 	jmp    *0x8010c0(,%eax,4)
  8002c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002c5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002c9:	eb d6                	jmp    8002a1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002ce:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002d6:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002d9:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  8002dd:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  8002e0:	8d 4a d0             	lea    -0x30(%edx),%ecx
  8002e3:	83 f9 09             	cmp    $0x9,%ecx
  8002e6:	77 3f                	ja     800327 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8002e8:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8002eb:	eb e9                	jmp    8002d6 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8002ed:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f0:	8b 00                	mov    (%eax),%eax
  8002f2:	89 45 d0             	mov    %eax,-0x30(%ebp)
  8002f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8002f8:	8d 40 04             	lea    0x4(%eax),%eax
  8002fb:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800301:	eb 2a                	jmp    80032d <vprintfmt+0xe5>
  800303:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800306:	85 c0                	test   %eax,%eax
  800308:	ba 00 00 00 00       	mov    $0x0,%edx
  80030d:	0f 49 d0             	cmovns %eax,%edx
  800310:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800313:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800316:	eb 89                	jmp    8002a1 <vprintfmt+0x59>
  800318:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80031b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800322:	e9 7a ff ff ff       	jmp    8002a1 <vprintfmt+0x59>
  800327:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80032a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80032d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800331:	0f 89 6a ff ff ff    	jns    8002a1 <vprintfmt+0x59>
				width = precision, precision = -1;
  800337:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80033a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80033d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800344:	e9 58 ff ff ff       	jmp    8002a1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800349:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80034f:	e9 4d ff ff ff       	jmp    8002a1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800354:	8b 45 14             	mov    0x14(%ebp),%eax
  800357:	8d 78 04             	lea    0x4(%eax),%edi
  80035a:	83 ec 08             	sub    $0x8,%esp
  80035d:	53                   	push   %ebx
  80035e:	ff 30                	pushl  (%eax)
  800360:	ff d6                	call   *%esi
			break;
  800362:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800365:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800368:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80036b:	e9 fe fe ff ff       	jmp    80026e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800370:	8b 45 14             	mov    0x14(%ebp),%eax
  800373:	8d 78 04             	lea    0x4(%eax),%edi
  800376:	8b 00                	mov    (%eax),%eax
  800378:	99                   	cltd   
  800379:	31 d0                	xor    %edx,%eax
  80037b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80037d:	83 f8 08             	cmp    $0x8,%eax
  800380:	7f 0b                	jg     80038d <vprintfmt+0x145>
  800382:	8b 14 85 20 12 80 00 	mov    0x801220(,%eax,4),%edx
  800389:	85 d2                	test   %edx,%edx
  80038b:	75 1b                	jne    8003a8 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  80038d:	50                   	push   %eax
  80038e:	68 10 10 80 00       	push   $0x801010
  800393:	53                   	push   %ebx
  800394:	56                   	push   %esi
  800395:	e8 91 fe ff ff       	call   80022b <printfmt>
  80039a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  80039d:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003a3:	e9 c6 fe ff ff       	jmp    80026e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003a8:	52                   	push   %edx
  8003a9:	68 19 10 80 00       	push   $0x801019
  8003ae:	53                   	push   %ebx
  8003af:	56                   	push   %esi
  8003b0:	e8 76 fe ff ff       	call   80022b <printfmt>
  8003b5:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b8:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003be:	e9 ab fe ff ff       	jmp    80026e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003c3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c6:	83 c0 04             	add    $0x4,%eax
  8003c9:	89 45 cc             	mov    %eax,-0x34(%ebp)
  8003cc:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cf:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003d1:	85 ff                	test   %edi,%edi
  8003d3:	b8 09 10 80 00       	mov    $0x801009,%eax
  8003d8:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003db:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003df:	0f 8e 94 00 00 00    	jle    800479 <vprintfmt+0x231>
  8003e5:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003e9:	0f 84 98 00 00 00    	je     800487 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003ef:	83 ec 08             	sub    $0x8,%esp
  8003f2:	ff 75 d0             	pushl  -0x30(%ebp)
  8003f5:	57                   	push   %edi
  8003f6:	e8 33 03 00 00       	call   80072e <strnlen>
  8003fb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8003fe:	29 c1                	sub    %eax,%ecx
  800400:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800403:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800406:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80040a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80040d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800410:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800412:	eb 0f                	jmp    800423 <vprintfmt+0x1db>
					putch(padc, putdat);
  800414:	83 ec 08             	sub    $0x8,%esp
  800417:	53                   	push   %ebx
  800418:	ff 75 e0             	pushl  -0x20(%ebp)
  80041b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80041d:	83 ef 01             	sub    $0x1,%edi
  800420:	83 c4 10             	add    $0x10,%esp
  800423:	85 ff                	test   %edi,%edi
  800425:	7f ed                	jg     800414 <vprintfmt+0x1cc>
  800427:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80042a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80042d:	85 c9                	test   %ecx,%ecx
  80042f:	b8 00 00 00 00       	mov    $0x0,%eax
  800434:	0f 49 c1             	cmovns %ecx,%eax
  800437:	29 c1                	sub    %eax,%ecx
  800439:	89 75 08             	mov    %esi,0x8(%ebp)
  80043c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80043f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800442:	89 cb                	mov    %ecx,%ebx
  800444:	eb 4d                	jmp    800493 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800446:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80044a:	74 1b                	je     800467 <vprintfmt+0x21f>
  80044c:	0f be c0             	movsbl %al,%eax
  80044f:	83 e8 20             	sub    $0x20,%eax
  800452:	83 f8 5e             	cmp    $0x5e,%eax
  800455:	76 10                	jbe    800467 <vprintfmt+0x21f>
					putch('?', putdat);
  800457:	83 ec 08             	sub    $0x8,%esp
  80045a:	ff 75 0c             	pushl  0xc(%ebp)
  80045d:	6a 3f                	push   $0x3f
  80045f:	ff 55 08             	call   *0x8(%ebp)
  800462:	83 c4 10             	add    $0x10,%esp
  800465:	eb 0d                	jmp    800474 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  800467:	83 ec 08             	sub    $0x8,%esp
  80046a:	ff 75 0c             	pushl  0xc(%ebp)
  80046d:	52                   	push   %edx
  80046e:	ff 55 08             	call   *0x8(%ebp)
  800471:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800474:	83 eb 01             	sub    $0x1,%ebx
  800477:	eb 1a                	jmp    800493 <vprintfmt+0x24b>
  800479:	89 75 08             	mov    %esi,0x8(%ebp)
  80047c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80047f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800482:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800485:	eb 0c                	jmp    800493 <vprintfmt+0x24b>
  800487:	89 75 08             	mov    %esi,0x8(%ebp)
  80048a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800490:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800493:	83 c7 01             	add    $0x1,%edi
  800496:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80049a:	0f be d0             	movsbl %al,%edx
  80049d:	85 d2                	test   %edx,%edx
  80049f:	74 23                	je     8004c4 <vprintfmt+0x27c>
  8004a1:	85 f6                	test   %esi,%esi
  8004a3:	78 a1                	js     800446 <vprintfmt+0x1fe>
  8004a5:	83 ee 01             	sub    $0x1,%esi
  8004a8:	79 9c                	jns    800446 <vprintfmt+0x1fe>
  8004aa:	89 df                	mov    %ebx,%edi
  8004ac:	8b 75 08             	mov    0x8(%ebp),%esi
  8004af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004b2:	eb 18                	jmp    8004cc <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004b4:	83 ec 08             	sub    $0x8,%esp
  8004b7:	53                   	push   %ebx
  8004b8:	6a 20                	push   $0x20
  8004ba:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004bc:	83 ef 01             	sub    $0x1,%edi
  8004bf:	83 c4 10             	add    $0x10,%esp
  8004c2:	eb 08                	jmp    8004cc <vprintfmt+0x284>
  8004c4:	89 df                	mov    %ebx,%edi
  8004c6:	8b 75 08             	mov    0x8(%ebp),%esi
  8004c9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004cc:	85 ff                	test   %edi,%edi
  8004ce:	7f e4                	jg     8004b4 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004d0:	8b 45 cc             	mov    -0x34(%ebp),%eax
  8004d3:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004d9:	e9 90 fd ff ff       	jmp    80026e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004de:	83 f9 01             	cmp    $0x1,%ecx
  8004e1:	7e 19                	jle    8004fc <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  8004e3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e6:	8b 50 04             	mov    0x4(%eax),%edx
  8004e9:	8b 00                	mov    (%eax),%eax
  8004eb:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f4:	8d 40 08             	lea    0x8(%eax),%eax
  8004f7:	89 45 14             	mov    %eax,0x14(%ebp)
  8004fa:	eb 38                	jmp    800534 <vprintfmt+0x2ec>
	else if (lflag)
  8004fc:	85 c9                	test   %ecx,%ecx
  8004fe:	74 1b                	je     80051b <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800500:	8b 45 14             	mov    0x14(%ebp),%eax
  800503:	8b 00                	mov    (%eax),%eax
  800505:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800508:	89 c1                	mov    %eax,%ecx
  80050a:	c1 f9 1f             	sar    $0x1f,%ecx
  80050d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800510:	8b 45 14             	mov    0x14(%ebp),%eax
  800513:	8d 40 04             	lea    0x4(%eax),%eax
  800516:	89 45 14             	mov    %eax,0x14(%ebp)
  800519:	eb 19                	jmp    800534 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80051b:	8b 45 14             	mov    0x14(%ebp),%eax
  80051e:	8b 00                	mov    (%eax),%eax
  800520:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800523:	89 c1                	mov    %eax,%ecx
  800525:	c1 f9 1f             	sar    $0x1f,%ecx
  800528:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052b:	8b 45 14             	mov    0x14(%ebp),%eax
  80052e:	8d 40 04             	lea    0x4(%eax),%eax
  800531:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800534:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800537:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80053a:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80053f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800543:	0f 89 0e 01 00 00    	jns    800657 <vprintfmt+0x40f>
				putch('-', putdat);
  800549:	83 ec 08             	sub    $0x8,%esp
  80054c:	53                   	push   %ebx
  80054d:	6a 2d                	push   $0x2d
  80054f:	ff d6                	call   *%esi
				num = -(long long) num;
  800551:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800554:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800557:	f7 da                	neg    %edx
  800559:	83 d1 00             	adc    $0x0,%ecx
  80055c:	f7 d9                	neg    %ecx
  80055e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800561:	b8 0a 00 00 00       	mov    $0xa,%eax
  800566:	e9 ec 00 00 00       	jmp    800657 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80056b:	83 f9 01             	cmp    $0x1,%ecx
  80056e:	7e 18                	jle    800588 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  800570:	8b 45 14             	mov    0x14(%ebp),%eax
  800573:	8b 10                	mov    (%eax),%edx
  800575:	8b 48 04             	mov    0x4(%eax),%ecx
  800578:	8d 40 08             	lea    0x8(%eax),%eax
  80057b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80057e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800583:	e9 cf 00 00 00       	jmp    800657 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800588:	85 c9                	test   %ecx,%ecx
  80058a:	74 1a                	je     8005a6 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  80058c:	8b 45 14             	mov    0x14(%ebp),%eax
  80058f:	8b 10                	mov    (%eax),%edx
  800591:	b9 00 00 00 00       	mov    $0x0,%ecx
  800596:	8d 40 04             	lea    0x4(%eax),%eax
  800599:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  80059c:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a1:	e9 b1 00 00 00       	jmp    800657 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005a6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a9:	8b 10                	mov    (%eax),%edx
  8005ab:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005b0:	8d 40 04             	lea    0x4(%eax),%eax
  8005b3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005b6:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005bb:	e9 97 00 00 00       	jmp    800657 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  8005c0:	83 ec 08             	sub    $0x8,%esp
  8005c3:	53                   	push   %ebx
  8005c4:	6a 58                	push   $0x58
  8005c6:	ff d6                	call   *%esi
			putch('X', putdat);
  8005c8:	83 c4 08             	add    $0x8,%esp
  8005cb:	53                   	push   %ebx
  8005cc:	6a 58                	push   $0x58
  8005ce:	ff d6                	call   *%esi
			putch('X', putdat);
  8005d0:	83 c4 08             	add    $0x8,%esp
  8005d3:	53                   	push   %ebx
  8005d4:	6a 58                	push   $0x58
  8005d6:	ff d6                	call   *%esi
			break;
  8005d8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005db:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  8005de:	e9 8b fc ff ff       	jmp    80026e <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005e3:	83 ec 08             	sub    $0x8,%esp
  8005e6:	53                   	push   %ebx
  8005e7:	6a 30                	push   $0x30
  8005e9:	ff d6                	call   *%esi
			putch('x', putdat);
  8005eb:	83 c4 08             	add    $0x8,%esp
  8005ee:	53                   	push   %ebx
  8005ef:	6a 78                	push   $0x78
  8005f1:	ff d6                	call   *%esi
			num = (unsigned long long)
  8005f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f6:	8b 10                	mov    (%eax),%edx
  8005f8:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005fd:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800600:	8d 40 04             	lea    0x4(%eax),%eax
  800603:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800606:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  80060b:	eb 4a                	jmp    800657 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80060d:	83 f9 01             	cmp    $0x1,%ecx
  800610:	7e 15                	jle    800627 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800612:	8b 45 14             	mov    0x14(%ebp),%eax
  800615:	8b 10                	mov    (%eax),%edx
  800617:	8b 48 04             	mov    0x4(%eax),%ecx
  80061a:	8d 40 08             	lea    0x8(%eax),%eax
  80061d:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800620:	b8 10 00 00 00       	mov    $0x10,%eax
  800625:	eb 30                	jmp    800657 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800627:	85 c9                	test   %ecx,%ecx
  800629:	74 17                	je     800642 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80062b:	8b 45 14             	mov    0x14(%ebp),%eax
  80062e:	8b 10                	mov    (%eax),%edx
  800630:	b9 00 00 00 00       	mov    $0x0,%ecx
  800635:	8d 40 04             	lea    0x4(%eax),%eax
  800638:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80063b:	b8 10 00 00 00       	mov    $0x10,%eax
  800640:	eb 15                	jmp    800657 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800642:	8b 45 14             	mov    0x14(%ebp),%eax
  800645:	8b 10                	mov    (%eax),%edx
  800647:	b9 00 00 00 00       	mov    $0x0,%ecx
  80064c:	8d 40 04             	lea    0x4(%eax),%eax
  80064f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800652:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800657:	83 ec 0c             	sub    $0xc,%esp
  80065a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80065e:	57                   	push   %edi
  80065f:	ff 75 e0             	pushl  -0x20(%ebp)
  800662:	50                   	push   %eax
  800663:	51                   	push   %ecx
  800664:	52                   	push   %edx
  800665:	89 da                	mov    %ebx,%edx
  800667:	89 f0                	mov    %esi,%eax
  800669:	e8 f1 fa ff ff       	call   80015f <printnum>
			break;
  80066e:	83 c4 20             	add    $0x20,%esp
  800671:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800674:	e9 f5 fb ff ff       	jmp    80026e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800679:	83 ec 08             	sub    $0x8,%esp
  80067c:	53                   	push   %ebx
  80067d:	52                   	push   %edx
  80067e:	ff d6                	call   *%esi
			break;
  800680:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800683:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800686:	e9 e3 fb ff ff       	jmp    80026e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80068b:	83 ec 08             	sub    $0x8,%esp
  80068e:	53                   	push   %ebx
  80068f:	6a 25                	push   $0x25
  800691:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800693:	83 c4 10             	add    $0x10,%esp
  800696:	eb 03                	jmp    80069b <vprintfmt+0x453>
  800698:	83 ef 01             	sub    $0x1,%edi
  80069b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80069f:	75 f7                	jne    800698 <vprintfmt+0x450>
  8006a1:	e9 c8 fb ff ff       	jmp    80026e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006a9:	5b                   	pop    %ebx
  8006aa:	5e                   	pop    %esi
  8006ab:	5f                   	pop    %edi
  8006ac:	5d                   	pop    %ebp
  8006ad:	c3                   	ret    

008006ae <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ae:	55                   	push   %ebp
  8006af:	89 e5                	mov    %esp,%ebp
  8006b1:	83 ec 18             	sub    $0x18,%esp
  8006b4:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006bd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006c1:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006cb:	85 c0                	test   %eax,%eax
  8006cd:	74 26                	je     8006f5 <vsnprintf+0x47>
  8006cf:	85 d2                	test   %edx,%edx
  8006d1:	7e 22                	jle    8006f5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d3:	ff 75 14             	pushl  0x14(%ebp)
  8006d6:	ff 75 10             	pushl  0x10(%ebp)
  8006d9:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006dc:	50                   	push   %eax
  8006dd:	68 0e 02 80 00       	push   $0x80020e
  8006e2:	e8 61 fb ff ff       	call   800248 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006ea:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006f0:	83 c4 10             	add    $0x10,%esp
  8006f3:	eb 05                	jmp    8006fa <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006f5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006fa:	c9                   	leave  
  8006fb:	c3                   	ret    

008006fc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006fc:	55                   	push   %ebp
  8006fd:	89 e5                	mov    %esp,%ebp
  8006ff:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800702:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800705:	50                   	push   %eax
  800706:	ff 75 10             	pushl  0x10(%ebp)
  800709:	ff 75 0c             	pushl  0xc(%ebp)
  80070c:	ff 75 08             	pushl  0x8(%ebp)
  80070f:	e8 9a ff ff ff       	call   8006ae <vsnprintf>
	va_end(ap);

	return rc;
}
  800714:	c9                   	leave  
  800715:	c3                   	ret    

00800716 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800716:	55                   	push   %ebp
  800717:	89 e5                	mov    %esp,%ebp
  800719:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80071c:	b8 00 00 00 00       	mov    $0x0,%eax
  800721:	eb 03                	jmp    800726 <strlen+0x10>
		n++;
  800723:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800726:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80072a:	75 f7                	jne    800723 <strlen+0xd>
		n++;
	return n;
}
  80072c:	5d                   	pop    %ebp
  80072d:	c3                   	ret    

0080072e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80072e:	55                   	push   %ebp
  80072f:	89 e5                	mov    %esp,%ebp
  800731:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800734:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800737:	ba 00 00 00 00       	mov    $0x0,%edx
  80073c:	eb 03                	jmp    800741 <strnlen+0x13>
		n++;
  80073e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800741:	39 c2                	cmp    %eax,%edx
  800743:	74 08                	je     80074d <strnlen+0x1f>
  800745:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800749:	75 f3                	jne    80073e <strnlen+0x10>
  80074b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80074d:	5d                   	pop    %ebp
  80074e:	c3                   	ret    

0080074f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80074f:	55                   	push   %ebp
  800750:	89 e5                	mov    %esp,%ebp
  800752:	53                   	push   %ebx
  800753:	8b 45 08             	mov    0x8(%ebp),%eax
  800756:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800759:	89 c2                	mov    %eax,%edx
  80075b:	83 c2 01             	add    $0x1,%edx
  80075e:	83 c1 01             	add    $0x1,%ecx
  800761:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800765:	88 5a ff             	mov    %bl,-0x1(%edx)
  800768:	84 db                	test   %bl,%bl
  80076a:	75 ef                	jne    80075b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80076c:	5b                   	pop    %ebx
  80076d:	5d                   	pop    %ebp
  80076e:	c3                   	ret    

0080076f <strcat>:

char *
strcat(char *dst, const char *src)
{
  80076f:	55                   	push   %ebp
  800770:	89 e5                	mov    %esp,%ebp
  800772:	53                   	push   %ebx
  800773:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800776:	53                   	push   %ebx
  800777:	e8 9a ff ff ff       	call   800716 <strlen>
  80077c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80077f:	ff 75 0c             	pushl  0xc(%ebp)
  800782:	01 d8                	add    %ebx,%eax
  800784:	50                   	push   %eax
  800785:	e8 c5 ff ff ff       	call   80074f <strcpy>
	return dst;
}
  80078a:	89 d8                	mov    %ebx,%eax
  80078c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80078f:	c9                   	leave  
  800790:	c3                   	ret    

00800791 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800791:	55                   	push   %ebp
  800792:	89 e5                	mov    %esp,%ebp
  800794:	56                   	push   %esi
  800795:	53                   	push   %ebx
  800796:	8b 75 08             	mov    0x8(%ebp),%esi
  800799:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80079c:	89 f3                	mov    %esi,%ebx
  80079e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a1:	89 f2                	mov    %esi,%edx
  8007a3:	eb 0f                	jmp    8007b4 <strncpy+0x23>
		*dst++ = *src;
  8007a5:	83 c2 01             	add    $0x1,%edx
  8007a8:	0f b6 01             	movzbl (%ecx),%eax
  8007ab:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ae:	80 39 01             	cmpb   $0x1,(%ecx)
  8007b1:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b4:	39 da                	cmp    %ebx,%edx
  8007b6:	75 ed                	jne    8007a5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007b8:	89 f0                	mov    %esi,%eax
  8007ba:	5b                   	pop    %ebx
  8007bb:	5e                   	pop    %esi
  8007bc:	5d                   	pop    %ebp
  8007bd:	c3                   	ret    

008007be <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007be:	55                   	push   %ebp
  8007bf:	89 e5                	mov    %esp,%ebp
  8007c1:	56                   	push   %esi
  8007c2:	53                   	push   %ebx
  8007c3:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007c9:	8b 55 10             	mov    0x10(%ebp),%edx
  8007cc:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007ce:	85 d2                	test   %edx,%edx
  8007d0:	74 21                	je     8007f3 <strlcpy+0x35>
  8007d2:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007d6:	89 f2                	mov    %esi,%edx
  8007d8:	eb 09                	jmp    8007e3 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007da:	83 c2 01             	add    $0x1,%edx
  8007dd:	83 c1 01             	add    $0x1,%ecx
  8007e0:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007e3:	39 c2                	cmp    %eax,%edx
  8007e5:	74 09                	je     8007f0 <strlcpy+0x32>
  8007e7:	0f b6 19             	movzbl (%ecx),%ebx
  8007ea:	84 db                	test   %bl,%bl
  8007ec:	75 ec                	jne    8007da <strlcpy+0x1c>
  8007ee:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  8007f0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  8007f3:	29 f0                	sub    %esi,%eax
}
  8007f5:	5b                   	pop    %ebx
  8007f6:	5e                   	pop    %esi
  8007f7:	5d                   	pop    %ebp
  8007f8:	c3                   	ret    

008007f9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007f9:	55                   	push   %ebp
  8007fa:	89 e5                	mov    %esp,%ebp
  8007fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007ff:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800802:	eb 06                	jmp    80080a <strcmp+0x11>
		p++, q++;
  800804:	83 c1 01             	add    $0x1,%ecx
  800807:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80080a:	0f b6 01             	movzbl (%ecx),%eax
  80080d:	84 c0                	test   %al,%al
  80080f:	74 04                	je     800815 <strcmp+0x1c>
  800811:	3a 02                	cmp    (%edx),%al
  800813:	74 ef                	je     800804 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800815:	0f b6 c0             	movzbl %al,%eax
  800818:	0f b6 12             	movzbl (%edx),%edx
  80081b:	29 d0                	sub    %edx,%eax
}
  80081d:	5d                   	pop    %ebp
  80081e:	c3                   	ret    

0080081f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80081f:	55                   	push   %ebp
  800820:	89 e5                	mov    %esp,%ebp
  800822:	53                   	push   %ebx
  800823:	8b 45 08             	mov    0x8(%ebp),%eax
  800826:	8b 55 0c             	mov    0xc(%ebp),%edx
  800829:	89 c3                	mov    %eax,%ebx
  80082b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80082e:	eb 06                	jmp    800836 <strncmp+0x17>
		n--, p++, q++;
  800830:	83 c0 01             	add    $0x1,%eax
  800833:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800836:	39 d8                	cmp    %ebx,%eax
  800838:	74 15                	je     80084f <strncmp+0x30>
  80083a:	0f b6 08             	movzbl (%eax),%ecx
  80083d:	84 c9                	test   %cl,%cl
  80083f:	74 04                	je     800845 <strncmp+0x26>
  800841:	3a 0a                	cmp    (%edx),%cl
  800843:	74 eb                	je     800830 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800845:	0f b6 00             	movzbl (%eax),%eax
  800848:	0f b6 12             	movzbl (%edx),%edx
  80084b:	29 d0                	sub    %edx,%eax
  80084d:	eb 05                	jmp    800854 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80084f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800854:	5b                   	pop    %ebx
  800855:	5d                   	pop    %ebp
  800856:	c3                   	ret    

00800857 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800857:	55                   	push   %ebp
  800858:	89 e5                	mov    %esp,%ebp
  80085a:	8b 45 08             	mov    0x8(%ebp),%eax
  80085d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800861:	eb 07                	jmp    80086a <strchr+0x13>
		if (*s == c)
  800863:	38 ca                	cmp    %cl,%dl
  800865:	74 0f                	je     800876 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800867:	83 c0 01             	add    $0x1,%eax
  80086a:	0f b6 10             	movzbl (%eax),%edx
  80086d:	84 d2                	test   %dl,%dl
  80086f:	75 f2                	jne    800863 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800871:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800876:	5d                   	pop    %ebp
  800877:	c3                   	ret    

00800878 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800878:	55                   	push   %ebp
  800879:	89 e5                	mov    %esp,%ebp
  80087b:	8b 45 08             	mov    0x8(%ebp),%eax
  80087e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800882:	eb 03                	jmp    800887 <strfind+0xf>
  800884:	83 c0 01             	add    $0x1,%eax
  800887:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80088a:	38 ca                	cmp    %cl,%dl
  80088c:	74 04                	je     800892 <strfind+0x1a>
  80088e:	84 d2                	test   %dl,%dl
  800890:	75 f2                	jne    800884 <strfind+0xc>
			break;
	return (char *) s;
}
  800892:	5d                   	pop    %ebp
  800893:	c3                   	ret    

00800894 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800894:	55                   	push   %ebp
  800895:	89 e5                	mov    %esp,%ebp
  800897:	57                   	push   %edi
  800898:	56                   	push   %esi
  800899:	53                   	push   %ebx
  80089a:	8b 7d 08             	mov    0x8(%ebp),%edi
  80089d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008a0:	85 c9                	test   %ecx,%ecx
  8008a2:	74 36                	je     8008da <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008a4:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008aa:	75 28                	jne    8008d4 <memset+0x40>
  8008ac:	f6 c1 03             	test   $0x3,%cl
  8008af:	75 23                	jne    8008d4 <memset+0x40>
		c &= 0xFF;
  8008b1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008b5:	89 d3                	mov    %edx,%ebx
  8008b7:	c1 e3 08             	shl    $0x8,%ebx
  8008ba:	89 d6                	mov    %edx,%esi
  8008bc:	c1 e6 18             	shl    $0x18,%esi
  8008bf:	89 d0                	mov    %edx,%eax
  8008c1:	c1 e0 10             	shl    $0x10,%eax
  8008c4:	09 f0                	or     %esi,%eax
  8008c6:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008c8:	89 d8                	mov    %ebx,%eax
  8008ca:	09 d0                	or     %edx,%eax
  8008cc:	c1 e9 02             	shr    $0x2,%ecx
  8008cf:	fc                   	cld    
  8008d0:	f3 ab                	rep stos %eax,%es:(%edi)
  8008d2:	eb 06                	jmp    8008da <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008d7:	fc                   	cld    
  8008d8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008da:	89 f8                	mov    %edi,%eax
  8008dc:	5b                   	pop    %ebx
  8008dd:	5e                   	pop    %esi
  8008de:	5f                   	pop    %edi
  8008df:	5d                   	pop    %ebp
  8008e0:	c3                   	ret    

008008e1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008e1:	55                   	push   %ebp
  8008e2:	89 e5                	mov    %esp,%ebp
  8008e4:	57                   	push   %edi
  8008e5:	56                   	push   %esi
  8008e6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e9:	8b 75 0c             	mov    0xc(%ebp),%esi
  8008ec:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8008ef:	39 c6                	cmp    %eax,%esi
  8008f1:	73 35                	jae    800928 <memmove+0x47>
  8008f3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8008f6:	39 d0                	cmp    %edx,%eax
  8008f8:	73 2e                	jae    800928 <memmove+0x47>
		s += n;
		d += n;
  8008fa:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008fd:	89 d6                	mov    %edx,%esi
  8008ff:	09 fe                	or     %edi,%esi
  800901:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800907:	75 13                	jne    80091c <memmove+0x3b>
  800909:	f6 c1 03             	test   $0x3,%cl
  80090c:	75 0e                	jne    80091c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80090e:	83 ef 04             	sub    $0x4,%edi
  800911:	8d 72 fc             	lea    -0x4(%edx),%esi
  800914:	c1 e9 02             	shr    $0x2,%ecx
  800917:	fd                   	std    
  800918:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80091a:	eb 09                	jmp    800925 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80091c:	83 ef 01             	sub    $0x1,%edi
  80091f:	8d 72 ff             	lea    -0x1(%edx),%esi
  800922:	fd                   	std    
  800923:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800925:	fc                   	cld    
  800926:	eb 1d                	jmp    800945 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800928:	89 f2                	mov    %esi,%edx
  80092a:	09 c2                	or     %eax,%edx
  80092c:	f6 c2 03             	test   $0x3,%dl
  80092f:	75 0f                	jne    800940 <memmove+0x5f>
  800931:	f6 c1 03             	test   $0x3,%cl
  800934:	75 0a                	jne    800940 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800936:	c1 e9 02             	shr    $0x2,%ecx
  800939:	89 c7                	mov    %eax,%edi
  80093b:	fc                   	cld    
  80093c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093e:	eb 05                	jmp    800945 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800940:	89 c7                	mov    %eax,%edi
  800942:	fc                   	cld    
  800943:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800945:	5e                   	pop    %esi
  800946:	5f                   	pop    %edi
  800947:	5d                   	pop    %ebp
  800948:	c3                   	ret    

00800949 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800949:	55                   	push   %ebp
  80094a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80094c:	ff 75 10             	pushl  0x10(%ebp)
  80094f:	ff 75 0c             	pushl  0xc(%ebp)
  800952:	ff 75 08             	pushl  0x8(%ebp)
  800955:	e8 87 ff ff ff       	call   8008e1 <memmove>
}
  80095a:	c9                   	leave  
  80095b:	c3                   	ret    

0080095c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80095c:	55                   	push   %ebp
  80095d:	89 e5                	mov    %esp,%ebp
  80095f:	56                   	push   %esi
  800960:	53                   	push   %ebx
  800961:	8b 45 08             	mov    0x8(%ebp),%eax
  800964:	8b 55 0c             	mov    0xc(%ebp),%edx
  800967:	89 c6                	mov    %eax,%esi
  800969:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80096c:	eb 1a                	jmp    800988 <memcmp+0x2c>
		if (*s1 != *s2)
  80096e:	0f b6 08             	movzbl (%eax),%ecx
  800971:	0f b6 1a             	movzbl (%edx),%ebx
  800974:	38 d9                	cmp    %bl,%cl
  800976:	74 0a                	je     800982 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800978:	0f b6 c1             	movzbl %cl,%eax
  80097b:	0f b6 db             	movzbl %bl,%ebx
  80097e:	29 d8                	sub    %ebx,%eax
  800980:	eb 0f                	jmp    800991 <memcmp+0x35>
		s1++, s2++;
  800982:	83 c0 01             	add    $0x1,%eax
  800985:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800988:	39 f0                	cmp    %esi,%eax
  80098a:	75 e2                	jne    80096e <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80098c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800991:	5b                   	pop    %ebx
  800992:	5e                   	pop    %esi
  800993:	5d                   	pop    %ebp
  800994:	c3                   	ret    

00800995 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800995:	55                   	push   %ebp
  800996:	89 e5                	mov    %esp,%ebp
  800998:	53                   	push   %ebx
  800999:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80099c:	89 c1                	mov    %eax,%ecx
  80099e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a1:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009a5:	eb 0a                	jmp    8009b1 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009a7:	0f b6 10             	movzbl (%eax),%edx
  8009aa:	39 da                	cmp    %ebx,%edx
  8009ac:	74 07                	je     8009b5 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ae:	83 c0 01             	add    $0x1,%eax
  8009b1:	39 c8                	cmp    %ecx,%eax
  8009b3:	72 f2                	jb     8009a7 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009b5:	5b                   	pop    %ebx
  8009b6:	5d                   	pop    %ebp
  8009b7:	c3                   	ret    

008009b8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009b8:	55                   	push   %ebp
  8009b9:	89 e5                	mov    %esp,%ebp
  8009bb:	57                   	push   %edi
  8009bc:	56                   	push   %esi
  8009bd:	53                   	push   %ebx
  8009be:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c4:	eb 03                	jmp    8009c9 <strtol+0x11>
		s++;
  8009c6:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009c9:	0f b6 01             	movzbl (%ecx),%eax
  8009cc:	3c 20                	cmp    $0x20,%al
  8009ce:	74 f6                	je     8009c6 <strtol+0xe>
  8009d0:	3c 09                	cmp    $0x9,%al
  8009d2:	74 f2                	je     8009c6 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009d4:	3c 2b                	cmp    $0x2b,%al
  8009d6:	75 0a                	jne    8009e2 <strtol+0x2a>
		s++;
  8009d8:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009db:	bf 00 00 00 00       	mov    $0x0,%edi
  8009e0:	eb 11                	jmp    8009f3 <strtol+0x3b>
  8009e2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  8009e7:	3c 2d                	cmp    $0x2d,%al
  8009e9:	75 08                	jne    8009f3 <strtol+0x3b>
		s++, neg = 1;
  8009eb:	83 c1 01             	add    $0x1,%ecx
  8009ee:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8009f3:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  8009f9:	75 15                	jne    800a10 <strtol+0x58>
  8009fb:	80 39 30             	cmpb   $0x30,(%ecx)
  8009fe:	75 10                	jne    800a10 <strtol+0x58>
  800a00:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a04:	75 7c                	jne    800a82 <strtol+0xca>
		s += 2, base = 16;
  800a06:	83 c1 02             	add    $0x2,%ecx
  800a09:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a0e:	eb 16                	jmp    800a26 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a10:	85 db                	test   %ebx,%ebx
  800a12:	75 12                	jne    800a26 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a14:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a19:	80 39 30             	cmpb   $0x30,(%ecx)
  800a1c:	75 08                	jne    800a26 <strtol+0x6e>
		s++, base = 8;
  800a1e:	83 c1 01             	add    $0x1,%ecx
  800a21:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a26:	b8 00 00 00 00       	mov    $0x0,%eax
  800a2b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a2e:	0f b6 11             	movzbl (%ecx),%edx
  800a31:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a34:	89 f3                	mov    %esi,%ebx
  800a36:	80 fb 09             	cmp    $0x9,%bl
  800a39:	77 08                	ja     800a43 <strtol+0x8b>
			dig = *s - '0';
  800a3b:	0f be d2             	movsbl %dl,%edx
  800a3e:	83 ea 30             	sub    $0x30,%edx
  800a41:	eb 22                	jmp    800a65 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a43:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a46:	89 f3                	mov    %esi,%ebx
  800a48:	80 fb 19             	cmp    $0x19,%bl
  800a4b:	77 08                	ja     800a55 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a4d:	0f be d2             	movsbl %dl,%edx
  800a50:	83 ea 57             	sub    $0x57,%edx
  800a53:	eb 10                	jmp    800a65 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a55:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a58:	89 f3                	mov    %esi,%ebx
  800a5a:	80 fb 19             	cmp    $0x19,%bl
  800a5d:	77 16                	ja     800a75 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a5f:	0f be d2             	movsbl %dl,%edx
  800a62:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a65:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a68:	7d 0b                	jge    800a75 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a6a:	83 c1 01             	add    $0x1,%ecx
  800a6d:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a71:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a73:	eb b9                	jmp    800a2e <strtol+0x76>

	if (endptr)
  800a75:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a79:	74 0d                	je     800a88 <strtol+0xd0>
		*endptr = (char *) s;
  800a7b:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a7e:	89 0e                	mov    %ecx,(%esi)
  800a80:	eb 06                	jmp    800a88 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a82:	85 db                	test   %ebx,%ebx
  800a84:	74 98                	je     800a1e <strtol+0x66>
  800a86:	eb 9e                	jmp    800a26 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a88:	89 c2                	mov    %eax,%edx
  800a8a:	f7 da                	neg    %edx
  800a8c:	85 ff                	test   %edi,%edi
  800a8e:	0f 45 c2             	cmovne %edx,%eax
}
  800a91:	5b                   	pop    %ebx
  800a92:	5e                   	pop    %esi
  800a93:	5f                   	pop    %edi
  800a94:	5d                   	pop    %ebp
  800a95:	c3                   	ret    

00800a96 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a96:	55                   	push   %ebp
  800a97:	89 e5                	mov    %esp,%ebp
  800a99:	57                   	push   %edi
  800a9a:	56                   	push   %esi
  800a9b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a9c:	b8 00 00 00 00       	mov    $0x0,%eax
  800aa1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aa4:	8b 55 08             	mov    0x8(%ebp),%edx
  800aa7:	89 c3                	mov    %eax,%ebx
  800aa9:	89 c7                	mov    %eax,%edi
  800aab:	89 c6                	mov    %eax,%esi
  800aad:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aaf:	5b                   	pop    %ebx
  800ab0:	5e                   	pop    %esi
  800ab1:	5f                   	pop    %edi
  800ab2:	5d                   	pop    %ebp
  800ab3:	c3                   	ret    

00800ab4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ab4:	55                   	push   %ebp
  800ab5:	89 e5                	mov    %esp,%ebp
  800ab7:	57                   	push   %edi
  800ab8:	56                   	push   %esi
  800ab9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aba:	ba 00 00 00 00       	mov    $0x0,%edx
  800abf:	b8 01 00 00 00       	mov    $0x1,%eax
  800ac4:	89 d1                	mov    %edx,%ecx
  800ac6:	89 d3                	mov    %edx,%ebx
  800ac8:	89 d7                	mov    %edx,%edi
  800aca:	89 d6                	mov    %edx,%esi
  800acc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800ace:	5b                   	pop    %ebx
  800acf:	5e                   	pop    %esi
  800ad0:	5f                   	pop    %edi
  800ad1:	5d                   	pop    %ebp
  800ad2:	c3                   	ret    

00800ad3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ad3:	55                   	push   %ebp
  800ad4:	89 e5                	mov    %esp,%ebp
  800ad6:	57                   	push   %edi
  800ad7:	56                   	push   %esi
  800ad8:	53                   	push   %ebx
  800ad9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800adc:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ae1:	b8 03 00 00 00       	mov    $0x3,%eax
  800ae6:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae9:	89 cb                	mov    %ecx,%ebx
  800aeb:	89 cf                	mov    %ecx,%edi
  800aed:	89 ce                	mov    %ecx,%esi
  800aef:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800af1:	85 c0                	test   %eax,%eax
  800af3:	7e 17                	jle    800b0c <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800af5:	83 ec 0c             	sub    $0xc,%esp
  800af8:	50                   	push   %eax
  800af9:	6a 03                	push   $0x3
  800afb:	68 44 12 80 00       	push   $0x801244
  800b00:	6a 23                	push   $0x23
  800b02:	68 61 12 80 00       	push   $0x801261
  800b07:	e8 f5 01 00 00       	call   800d01 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b0f:	5b                   	pop    %ebx
  800b10:	5e                   	pop    %esi
  800b11:	5f                   	pop    %edi
  800b12:	5d                   	pop    %ebp
  800b13:	c3                   	ret    

00800b14 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b14:	55                   	push   %ebp
  800b15:	89 e5                	mov    %esp,%ebp
  800b17:	57                   	push   %edi
  800b18:	56                   	push   %esi
  800b19:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b1f:	b8 02 00 00 00       	mov    $0x2,%eax
  800b24:	89 d1                	mov    %edx,%ecx
  800b26:	89 d3                	mov    %edx,%ebx
  800b28:	89 d7                	mov    %edx,%edi
  800b2a:	89 d6                	mov    %edx,%esi
  800b2c:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b2e:	5b                   	pop    %ebx
  800b2f:	5e                   	pop    %esi
  800b30:	5f                   	pop    %edi
  800b31:	5d                   	pop    %ebp
  800b32:	c3                   	ret    

00800b33 <sys_yield>:

void
sys_yield(void)
{
  800b33:	55                   	push   %ebp
  800b34:	89 e5                	mov    %esp,%ebp
  800b36:	57                   	push   %edi
  800b37:	56                   	push   %esi
  800b38:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b39:	ba 00 00 00 00       	mov    $0x0,%edx
  800b3e:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b43:	89 d1                	mov    %edx,%ecx
  800b45:	89 d3                	mov    %edx,%ebx
  800b47:	89 d7                	mov    %edx,%edi
  800b49:	89 d6                	mov    %edx,%esi
  800b4b:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800b4d:	5b                   	pop    %ebx
  800b4e:	5e                   	pop    %esi
  800b4f:	5f                   	pop    %edi
  800b50:	5d                   	pop    %ebp
  800b51:	c3                   	ret    

00800b52 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800b52:	55                   	push   %ebp
  800b53:	89 e5                	mov    %esp,%ebp
  800b55:	57                   	push   %edi
  800b56:	56                   	push   %esi
  800b57:	53                   	push   %ebx
  800b58:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b5b:	be 00 00 00 00       	mov    $0x0,%esi
  800b60:	b8 04 00 00 00       	mov    $0x4,%eax
  800b65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b68:	8b 55 08             	mov    0x8(%ebp),%edx
  800b6b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800b6e:	89 f7                	mov    %esi,%edi
  800b70:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b72:	85 c0                	test   %eax,%eax
  800b74:	7e 17                	jle    800b8d <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b76:	83 ec 0c             	sub    $0xc,%esp
  800b79:	50                   	push   %eax
  800b7a:	6a 04                	push   $0x4
  800b7c:	68 44 12 80 00       	push   $0x801244
  800b81:	6a 23                	push   $0x23
  800b83:	68 61 12 80 00       	push   $0x801261
  800b88:	e8 74 01 00 00       	call   800d01 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800b8d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b90:	5b                   	pop    %ebx
  800b91:	5e                   	pop    %esi
  800b92:	5f                   	pop    %edi
  800b93:	5d                   	pop    %ebp
  800b94:	c3                   	ret    

00800b95 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800b95:	55                   	push   %ebp
  800b96:	89 e5                	mov    %esp,%ebp
  800b98:	57                   	push   %edi
  800b99:	56                   	push   %esi
  800b9a:	53                   	push   %ebx
  800b9b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b9e:	b8 05 00 00 00       	mov    $0x5,%eax
  800ba3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ba6:	8b 55 08             	mov    0x8(%ebp),%edx
  800ba9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bac:	8b 7d 14             	mov    0x14(%ebp),%edi
  800baf:	8b 75 18             	mov    0x18(%ebp),%esi
  800bb2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bb4:	85 c0                	test   %eax,%eax
  800bb6:	7e 17                	jle    800bcf <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bb8:	83 ec 0c             	sub    $0xc,%esp
  800bbb:	50                   	push   %eax
  800bbc:	6a 05                	push   $0x5
  800bbe:	68 44 12 80 00       	push   $0x801244
  800bc3:	6a 23                	push   $0x23
  800bc5:	68 61 12 80 00       	push   $0x801261
  800bca:	e8 32 01 00 00       	call   800d01 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800bcf:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bd2:	5b                   	pop    %ebx
  800bd3:	5e                   	pop    %esi
  800bd4:	5f                   	pop    %edi
  800bd5:	5d                   	pop    %ebp
  800bd6:	c3                   	ret    

00800bd7 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800bd7:	55                   	push   %ebp
  800bd8:	89 e5                	mov    %esp,%ebp
  800bda:	57                   	push   %edi
  800bdb:	56                   	push   %esi
  800bdc:	53                   	push   %ebx
  800bdd:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800be0:	bb 00 00 00 00       	mov    $0x0,%ebx
  800be5:	b8 06 00 00 00       	mov    $0x6,%eax
  800bea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bed:	8b 55 08             	mov    0x8(%ebp),%edx
  800bf0:	89 df                	mov    %ebx,%edi
  800bf2:	89 de                	mov    %ebx,%esi
  800bf4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bf6:	85 c0                	test   %eax,%eax
  800bf8:	7e 17                	jle    800c11 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bfa:	83 ec 0c             	sub    $0xc,%esp
  800bfd:	50                   	push   %eax
  800bfe:	6a 06                	push   $0x6
  800c00:	68 44 12 80 00       	push   $0x801244
  800c05:	6a 23                	push   $0x23
  800c07:	68 61 12 80 00       	push   $0x801261
  800c0c:	e8 f0 00 00 00       	call   800d01 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c11:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c14:	5b                   	pop    %ebx
  800c15:	5e                   	pop    %esi
  800c16:	5f                   	pop    %edi
  800c17:	5d                   	pop    %ebp
  800c18:	c3                   	ret    

00800c19 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c19:	55                   	push   %ebp
  800c1a:	89 e5                	mov    %esp,%ebp
  800c1c:	57                   	push   %edi
  800c1d:	56                   	push   %esi
  800c1e:	53                   	push   %ebx
  800c1f:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c22:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c27:	b8 08 00 00 00       	mov    $0x8,%eax
  800c2c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c2f:	8b 55 08             	mov    0x8(%ebp),%edx
  800c32:	89 df                	mov    %ebx,%edi
  800c34:	89 de                	mov    %ebx,%esi
  800c36:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c38:	85 c0                	test   %eax,%eax
  800c3a:	7e 17                	jle    800c53 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c3c:	83 ec 0c             	sub    $0xc,%esp
  800c3f:	50                   	push   %eax
  800c40:	6a 08                	push   $0x8
  800c42:	68 44 12 80 00       	push   $0x801244
  800c47:	6a 23                	push   $0x23
  800c49:	68 61 12 80 00       	push   $0x801261
  800c4e:	e8 ae 00 00 00       	call   800d01 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800c53:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c56:	5b                   	pop    %ebx
  800c57:	5e                   	pop    %esi
  800c58:	5f                   	pop    %edi
  800c59:	5d                   	pop    %ebp
  800c5a:	c3                   	ret    

00800c5b <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800c5b:	55                   	push   %ebp
  800c5c:	89 e5                	mov    %esp,%ebp
  800c5e:	57                   	push   %edi
  800c5f:	56                   	push   %esi
  800c60:	53                   	push   %ebx
  800c61:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c64:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c69:	b8 09 00 00 00       	mov    $0x9,%eax
  800c6e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c71:	8b 55 08             	mov    0x8(%ebp),%edx
  800c74:	89 df                	mov    %ebx,%edi
  800c76:	89 de                	mov    %ebx,%esi
  800c78:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c7a:	85 c0                	test   %eax,%eax
  800c7c:	7e 17                	jle    800c95 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c7e:	83 ec 0c             	sub    $0xc,%esp
  800c81:	50                   	push   %eax
  800c82:	6a 09                	push   $0x9
  800c84:	68 44 12 80 00       	push   $0x801244
  800c89:	6a 23                	push   $0x23
  800c8b:	68 61 12 80 00       	push   $0x801261
  800c90:	e8 6c 00 00 00       	call   800d01 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800c95:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c98:	5b                   	pop    %ebx
  800c99:	5e                   	pop    %esi
  800c9a:	5f                   	pop    %edi
  800c9b:	5d                   	pop    %ebp
  800c9c:	c3                   	ret    

00800c9d <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800c9d:	55                   	push   %ebp
  800c9e:	89 e5                	mov    %esp,%ebp
  800ca0:	57                   	push   %edi
  800ca1:	56                   	push   %esi
  800ca2:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ca3:	be 00 00 00 00       	mov    $0x0,%esi
  800ca8:	b8 0b 00 00 00       	mov    $0xb,%eax
  800cad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cb0:	8b 55 08             	mov    0x8(%ebp),%edx
  800cb3:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cb6:	8b 7d 14             	mov    0x14(%ebp),%edi
  800cb9:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800cbb:	5b                   	pop    %ebx
  800cbc:	5e                   	pop    %esi
  800cbd:	5f                   	pop    %edi
  800cbe:	5d                   	pop    %ebp
  800cbf:	c3                   	ret    

00800cc0 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800cc0:	55                   	push   %ebp
  800cc1:	89 e5                	mov    %esp,%ebp
  800cc3:	57                   	push   %edi
  800cc4:	56                   	push   %esi
  800cc5:	53                   	push   %ebx
  800cc6:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cc9:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cce:	b8 0c 00 00 00       	mov    $0xc,%eax
  800cd3:	8b 55 08             	mov    0x8(%ebp),%edx
  800cd6:	89 cb                	mov    %ecx,%ebx
  800cd8:	89 cf                	mov    %ecx,%edi
  800cda:	89 ce                	mov    %ecx,%esi
  800cdc:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cde:	85 c0                	test   %eax,%eax
  800ce0:	7e 17                	jle    800cf9 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ce2:	83 ec 0c             	sub    $0xc,%esp
  800ce5:	50                   	push   %eax
  800ce6:	6a 0c                	push   $0xc
  800ce8:	68 44 12 80 00       	push   $0x801244
  800ced:	6a 23                	push   $0x23
  800cef:	68 61 12 80 00       	push   $0x801261
  800cf4:	e8 08 00 00 00       	call   800d01 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800cf9:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cfc:	5b                   	pop    %ebx
  800cfd:	5e                   	pop    %esi
  800cfe:	5f                   	pop    %edi
  800cff:	5d                   	pop    %ebp
  800d00:	c3                   	ret    

00800d01 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800d01:	55                   	push   %ebp
  800d02:	89 e5                	mov    %esp,%ebp
  800d04:	56                   	push   %esi
  800d05:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800d06:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800d09:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800d0f:	e8 00 fe ff ff       	call   800b14 <sys_getenvid>
  800d14:	83 ec 0c             	sub    $0xc,%esp
  800d17:	ff 75 0c             	pushl  0xc(%ebp)
  800d1a:	ff 75 08             	pushl  0x8(%ebp)
  800d1d:	56                   	push   %esi
  800d1e:	50                   	push   %eax
  800d1f:	68 70 12 80 00       	push   $0x801270
  800d24:	e8 22 f4 ff ff       	call   80014b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800d29:	83 c4 18             	add    $0x18,%esp
  800d2c:	53                   	push   %ebx
  800d2d:	ff 75 10             	pushl  0x10(%ebp)
  800d30:	e8 c5 f3 ff ff       	call   8000fa <vcprintf>
	cprintf("\n");
  800d35:	c7 04 24 ec 0f 80 00 	movl   $0x800fec,(%esp)
  800d3c:	e8 0a f4 ff ff       	call   80014b <cprintf>
  800d41:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800d44:	cc                   	int3   
  800d45:	eb fd                	jmp    800d44 <_panic+0x43>
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
