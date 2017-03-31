
obj/user/fairness:     file format elf32-i386


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
  80002c:	e8 70 00 00 00       	call   8000a1 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	56                   	push   %esi
  800037:	53                   	push   %ebx
  800038:	83 ec 10             	sub    $0x10,%esp
	envid_t who, id;

	id = sys_getenvid();
  80003b:	e8 15 0b 00 00       	call   800b55 <sys_getenvid>
  800040:	89 c3                	mov    %eax,%ebx

	if (thisenv == &envs[1]) {
  800042:	81 3d 04 20 80 00 7c 	cmpl   $0xeec0007c,0x802004
  800049:	00 c0 ee 
  80004c:	75 26                	jne    800074 <umain+0x41>
		while (1) {
			ipc_recv(&who, 0, 0);
  80004e:	8d 75 f4             	lea    -0xc(%ebp),%esi
  800051:	83 ec 04             	sub    $0x4,%esp
  800054:	6a 00                	push   $0x0
  800056:	6a 00                	push   $0x0
  800058:	56                   	push   %esi
  800059:	e8 e4 0c 00 00       	call   800d42 <ipc_recv>
			cprintf("%x recv from %x\n", id, who);
  80005e:	83 c4 0c             	add    $0xc,%esp
  800061:	ff 75 f4             	pushl  -0xc(%ebp)
  800064:	53                   	push   %ebx
  800065:	68 20 11 80 00       	push   $0x801120
  80006a:	e8 1d 01 00 00       	call   80018c <cprintf>
  80006f:	83 c4 10             	add    $0x10,%esp
  800072:	eb dd                	jmp    800051 <umain+0x1e>
		}
	} else {
		cprintf("%x loop sending to %x\n", id, envs[1].env_id);
  800074:	a1 c4 00 c0 ee       	mov    0xeec000c4,%eax
  800079:	83 ec 04             	sub    $0x4,%esp
  80007c:	50                   	push   %eax
  80007d:	53                   	push   %ebx
  80007e:	68 31 11 80 00       	push   $0x801131
  800083:	e8 04 01 00 00       	call   80018c <cprintf>
  800088:	83 c4 10             	add    $0x10,%esp
		while (1)
			ipc_send(envs[1].env_id, 0, 0, 0);
  80008b:	a1 c4 00 c0 ee       	mov    0xeec000c4,%eax
  800090:	6a 00                	push   $0x0
  800092:	6a 00                	push   $0x0
  800094:	6a 00                	push   $0x0
  800096:	50                   	push   %eax
  800097:	e8 23 0d 00 00       	call   800dbf <ipc_send>
  80009c:	83 c4 10             	add    $0x10,%esp
  80009f:	eb ea                	jmp    80008b <umain+0x58>

008000a1 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000a1:	55                   	push   %ebp
  8000a2:	89 e5                	mov    %esp,%ebp
  8000a4:	56                   	push   %esi
  8000a5:	53                   	push   %ebx
  8000a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000a9:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = envs+ENVX(sys_getenvid());
  8000ac:	e8 a4 0a 00 00       	call   800b55 <sys_getenvid>
  8000b1:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000b6:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000b9:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000be:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000c3:	85 db                	test   %ebx,%ebx
  8000c5:	7e 07                	jle    8000ce <libmain+0x2d>
		binaryname = argv[0];
  8000c7:	8b 06                	mov    (%esi),%eax
  8000c9:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000ce:	83 ec 08             	sub    $0x8,%esp
  8000d1:	56                   	push   %esi
  8000d2:	53                   	push   %ebx
  8000d3:	e8 5b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  8000d8:	e8 0a 00 00 00       	call   8000e7 <exit>
}
  8000dd:	83 c4 10             	add    $0x10,%esp
  8000e0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000e3:	5b                   	pop    %ebx
  8000e4:	5e                   	pop    %esi
  8000e5:	5d                   	pop    %ebp
  8000e6:	c3                   	ret    

008000e7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000e7:	55                   	push   %ebp
  8000e8:	89 e5                	mov    %esp,%ebp
  8000ea:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000ed:	6a 00                	push   $0x0
  8000ef:	e8 20 0a 00 00       	call   800b14 <sys_env_destroy>
}
  8000f4:	83 c4 10             	add    $0x10,%esp
  8000f7:	c9                   	leave  
  8000f8:	c3                   	ret    

008000f9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000f9:	55                   	push   %ebp
  8000fa:	89 e5                	mov    %esp,%ebp
  8000fc:	53                   	push   %ebx
  8000fd:	83 ec 04             	sub    $0x4,%esp
  800100:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800103:	8b 13                	mov    (%ebx),%edx
  800105:	8d 42 01             	lea    0x1(%edx),%eax
  800108:	89 03                	mov    %eax,(%ebx)
  80010a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80010d:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800111:	3d ff 00 00 00       	cmp    $0xff,%eax
  800116:	75 1a                	jne    800132 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800118:	83 ec 08             	sub    $0x8,%esp
  80011b:	68 ff 00 00 00       	push   $0xff
  800120:	8d 43 08             	lea    0x8(%ebx),%eax
  800123:	50                   	push   %eax
  800124:	e8 ae 09 00 00       	call   800ad7 <sys_cputs>
		b->idx = 0;
  800129:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80012f:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800132:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800136:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800139:	c9                   	leave  
  80013a:	c3                   	ret    

0080013b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800144:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80014b:	00 00 00 
	b.cnt = 0;
  80014e:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800155:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800158:	ff 75 0c             	pushl  0xc(%ebp)
  80015b:	ff 75 08             	pushl  0x8(%ebp)
  80015e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800164:	50                   	push   %eax
  800165:	68 f9 00 80 00       	push   $0x8000f9
  80016a:	e8 1a 01 00 00       	call   800289 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80016f:	83 c4 08             	add    $0x8,%esp
  800172:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800178:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80017e:	50                   	push   %eax
  80017f:	e8 53 09 00 00       	call   800ad7 <sys_cputs>

	return b.cnt;
}
  800184:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80018a:	c9                   	leave  
  80018b:	c3                   	ret    

0080018c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80018c:	55                   	push   %ebp
  80018d:	89 e5                	mov    %esp,%ebp
  80018f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800192:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800195:	50                   	push   %eax
  800196:	ff 75 08             	pushl  0x8(%ebp)
  800199:	e8 9d ff ff ff       	call   80013b <vcprintf>
	va_end(ap);

	return cnt;
}
  80019e:	c9                   	leave  
  80019f:	c3                   	ret    

008001a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001a0:	55                   	push   %ebp
  8001a1:	89 e5                	mov    %esp,%ebp
  8001a3:	57                   	push   %edi
  8001a4:	56                   	push   %esi
  8001a5:	53                   	push   %ebx
  8001a6:	83 ec 1c             	sub    $0x1c,%esp
  8001a9:	89 c7                	mov    %eax,%edi
  8001ab:	89 d6                	mov    %edx,%esi
  8001ad:	8b 45 08             	mov    0x8(%ebp),%eax
  8001b0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001b6:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001b9:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8001bc:	bb 00 00 00 00       	mov    $0x0,%ebx
  8001c1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8001c4:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8001c7:	39 d3                	cmp    %edx,%ebx
  8001c9:	72 05                	jb     8001d0 <printnum+0x30>
  8001cb:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001ce:	77 45                	ja     800215 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001d0:	83 ec 0c             	sub    $0xc,%esp
  8001d3:	ff 75 18             	pushl  0x18(%ebp)
  8001d6:	8b 45 14             	mov    0x14(%ebp),%eax
  8001d9:	8d 58 ff             	lea    -0x1(%eax),%ebx
  8001dc:	53                   	push   %ebx
  8001dd:	ff 75 10             	pushl  0x10(%ebp)
  8001e0:	83 ec 08             	sub    $0x8,%esp
  8001e3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001e9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ec:	ff 75 d8             	pushl  -0x28(%ebp)
  8001ef:	e8 9c 0c 00 00       	call   800e90 <__udivdi3>
  8001f4:	83 c4 18             	add    $0x18,%esp
  8001f7:	52                   	push   %edx
  8001f8:	50                   	push   %eax
  8001f9:	89 f2                	mov    %esi,%edx
  8001fb:	89 f8                	mov    %edi,%eax
  8001fd:	e8 9e ff ff ff       	call   8001a0 <printnum>
  800202:	83 c4 20             	add    $0x20,%esp
  800205:	eb 18                	jmp    80021f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800207:	83 ec 08             	sub    $0x8,%esp
  80020a:	56                   	push   %esi
  80020b:	ff 75 18             	pushl  0x18(%ebp)
  80020e:	ff d7                	call   *%edi
  800210:	83 c4 10             	add    $0x10,%esp
  800213:	eb 03                	jmp    800218 <printnum+0x78>
  800215:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800218:	83 eb 01             	sub    $0x1,%ebx
  80021b:	85 db                	test   %ebx,%ebx
  80021d:	7f e8                	jg     800207 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021f:	83 ec 08             	sub    $0x8,%esp
  800222:	56                   	push   %esi
  800223:	83 ec 04             	sub    $0x4,%esp
  800226:	ff 75 e4             	pushl  -0x1c(%ebp)
  800229:	ff 75 e0             	pushl  -0x20(%ebp)
  80022c:	ff 75 dc             	pushl  -0x24(%ebp)
  80022f:	ff 75 d8             	pushl  -0x28(%ebp)
  800232:	e8 89 0d 00 00       	call   800fc0 <__umoddi3>
  800237:	83 c4 14             	add    $0x14,%esp
  80023a:	0f be 80 52 11 80 00 	movsbl 0x801152(%eax),%eax
  800241:	50                   	push   %eax
  800242:	ff d7                	call   *%edi
}
  800244:	83 c4 10             	add    $0x10,%esp
  800247:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5f                   	pop    %edi
  80024d:	5d                   	pop    %ebp
  80024e:	c3                   	ret    

0080024f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80024f:	55                   	push   %ebp
  800250:	89 e5                	mov    %esp,%ebp
  800252:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800255:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800259:	8b 10                	mov    (%eax),%edx
  80025b:	3b 50 04             	cmp    0x4(%eax),%edx
  80025e:	73 0a                	jae    80026a <sprintputch+0x1b>
		*b->buf++ = ch;
  800260:	8d 4a 01             	lea    0x1(%edx),%ecx
  800263:	89 08                	mov    %ecx,(%eax)
  800265:	8b 45 08             	mov    0x8(%ebp),%eax
  800268:	88 02                	mov    %al,(%edx)
}
  80026a:	5d                   	pop    %ebp
  80026b:	c3                   	ret    

0080026c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80026c:	55                   	push   %ebp
  80026d:	89 e5                	mov    %esp,%ebp
  80026f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800272:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800275:	50                   	push   %eax
  800276:	ff 75 10             	pushl  0x10(%ebp)
  800279:	ff 75 0c             	pushl  0xc(%ebp)
  80027c:	ff 75 08             	pushl  0x8(%ebp)
  80027f:	e8 05 00 00 00       	call   800289 <vprintfmt>
	va_end(ap);
}
  800284:	83 c4 10             	add    $0x10,%esp
  800287:	c9                   	leave  
  800288:	c3                   	ret    

00800289 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800289:	55                   	push   %ebp
  80028a:	89 e5                	mov    %esp,%ebp
  80028c:	57                   	push   %edi
  80028d:	56                   	push   %esi
  80028e:	53                   	push   %ebx
  80028f:	83 ec 2c             	sub    $0x2c,%esp
  800292:	8b 75 08             	mov    0x8(%ebp),%esi
  800295:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800298:	8b 7d 10             	mov    0x10(%ebp),%edi
  80029b:	eb 12                	jmp    8002af <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80029d:	85 c0                	test   %eax,%eax
  80029f:	0f 84 42 04 00 00    	je     8006e7 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
  8002a5:	83 ec 08             	sub    $0x8,%esp
  8002a8:	53                   	push   %ebx
  8002a9:	50                   	push   %eax
  8002aa:	ff d6                	call   *%esi
  8002ac:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002af:	83 c7 01             	add    $0x1,%edi
  8002b2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002b6:	83 f8 25             	cmp    $0x25,%eax
  8002b9:	75 e2                	jne    80029d <vprintfmt+0x14>
  8002bb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002bf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002c6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002cd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002d4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002d9:	eb 07                	jmp    8002e2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002db:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002de:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002e2:	8d 47 01             	lea    0x1(%edi),%eax
  8002e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002e8:	0f b6 07             	movzbl (%edi),%eax
  8002eb:	0f b6 d0             	movzbl %al,%edx
  8002ee:	83 e8 23             	sub    $0x23,%eax
  8002f1:	3c 55                	cmp    $0x55,%al
  8002f3:	0f 87 d3 03 00 00    	ja     8006cc <vprintfmt+0x443>
  8002f9:	0f b6 c0             	movzbl %al,%eax
  8002fc:	ff 24 85 20 12 80 00 	jmp    *0x801220(,%eax,4)
  800303:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800306:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80030a:	eb d6                	jmp    8002e2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80030c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80030f:	b8 00 00 00 00       	mov    $0x0,%eax
  800314:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800317:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80031a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
  80031e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
  800321:	8d 4a d0             	lea    -0x30(%edx),%ecx
  800324:	83 f9 09             	cmp    $0x9,%ecx
  800327:	77 3f                	ja     800368 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800329:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80032c:	eb e9                	jmp    800317 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80032e:	8b 45 14             	mov    0x14(%ebp),%eax
  800331:	8b 00                	mov    (%eax),%eax
  800333:	89 45 d0             	mov    %eax,-0x30(%ebp)
  800336:	8b 45 14             	mov    0x14(%ebp),%eax
  800339:	8d 40 04             	lea    0x4(%eax),%eax
  80033c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800342:	eb 2a                	jmp    80036e <vprintfmt+0xe5>
  800344:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800347:	85 c0                	test   %eax,%eax
  800349:	ba 00 00 00 00       	mov    $0x0,%edx
  80034e:	0f 49 d0             	cmovns %eax,%edx
  800351:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800354:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800357:	eb 89                	jmp    8002e2 <vprintfmt+0x59>
  800359:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80035c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800363:	e9 7a ff ff ff       	jmp    8002e2 <vprintfmt+0x59>
  800368:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  80036b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80036e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800372:	0f 89 6a ff ff ff    	jns    8002e2 <vprintfmt+0x59>
				width = precision, precision = -1;
  800378:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80037b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80037e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800385:	e9 58 ff ff ff       	jmp    8002e2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80038a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800390:	e9 4d ff ff ff       	jmp    8002e2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800395:	8b 45 14             	mov    0x14(%ebp),%eax
  800398:	8d 78 04             	lea    0x4(%eax),%edi
  80039b:	83 ec 08             	sub    $0x8,%esp
  80039e:	53                   	push   %ebx
  80039f:	ff 30                	pushl  (%eax)
  8003a1:	ff d6                	call   *%esi
			break;
  8003a3:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003a6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003ac:	e9 fe fe ff ff       	jmp    8002af <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003b4:	8d 78 04             	lea    0x4(%eax),%edi
  8003b7:	8b 00                	mov    (%eax),%eax
  8003b9:	99                   	cltd   
  8003ba:	31 d0                	xor    %edx,%eax
  8003bc:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003be:	83 f8 08             	cmp    $0x8,%eax
  8003c1:	7f 0b                	jg     8003ce <vprintfmt+0x145>
  8003c3:	8b 14 85 80 13 80 00 	mov    0x801380(,%eax,4),%edx
  8003ca:	85 d2                	test   %edx,%edx
  8003cc:	75 1b                	jne    8003e9 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
  8003ce:	50                   	push   %eax
  8003cf:	68 6a 11 80 00       	push   $0x80116a
  8003d4:	53                   	push   %ebx
  8003d5:	56                   	push   %esi
  8003d6:	e8 91 fe ff ff       	call   80026c <printfmt>
  8003db:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003de:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003e4:	e9 c6 fe ff ff       	jmp    8002af <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003e9:	52                   	push   %edx
  8003ea:	68 73 11 80 00       	push   $0x801173
  8003ef:	53                   	push   %ebx
  8003f0:	56                   	push   %esi
  8003f1:	e8 76 fe ff ff       	call   80026c <printfmt>
  8003f6:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003f9:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ff:	e9 ab fe ff ff       	jmp    8002af <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800404:	8b 45 14             	mov    0x14(%ebp),%eax
  800407:	83 c0 04             	add    $0x4,%eax
  80040a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  80040d:	8b 45 14             	mov    0x14(%ebp),%eax
  800410:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800412:	85 ff                	test   %edi,%edi
  800414:	b8 63 11 80 00       	mov    $0x801163,%eax
  800419:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80041c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800420:	0f 8e 94 00 00 00    	jle    8004ba <vprintfmt+0x231>
  800426:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80042a:	0f 84 98 00 00 00    	je     8004c8 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
  800430:	83 ec 08             	sub    $0x8,%esp
  800433:	ff 75 d0             	pushl  -0x30(%ebp)
  800436:	57                   	push   %edi
  800437:	e8 33 03 00 00       	call   80076f <strnlen>
  80043c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80043f:	29 c1                	sub    %eax,%ecx
  800441:	89 4d c8             	mov    %ecx,-0x38(%ebp)
  800444:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800447:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80044b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80044e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800451:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800453:	eb 0f                	jmp    800464 <vprintfmt+0x1db>
					putch(padc, putdat);
  800455:	83 ec 08             	sub    $0x8,%esp
  800458:	53                   	push   %ebx
  800459:	ff 75 e0             	pushl  -0x20(%ebp)
  80045c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80045e:	83 ef 01             	sub    $0x1,%edi
  800461:	83 c4 10             	add    $0x10,%esp
  800464:	85 ff                	test   %edi,%edi
  800466:	7f ed                	jg     800455 <vprintfmt+0x1cc>
  800468:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80046b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
  80046e:	85 c9                	test   %ecx,%ecx
  800470:	b8 00 00 00 00       	mov    $0x0,%eax
  800475:	0f 49 c1             	cmovns %ecx,%eax
  800478:	29 c1                	sub    %eax,%ecx
  80047a:	89 75 08             	mov    %esi,0x8(%ebp)
  80047d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800480:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800483:	89 cb                	mov    %ecx,%ebx
  800485:	eb 4d                	jmp    8004d4 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800487:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80048b:	74 1b                	je     8004a8 <vprintfmt+0x21f>
  80048d:	0f be c0             	movsbl %al,%eax
  800490:	83 e8 20             	sub    $0x20,%eax
  800493:	83 f8 5e             	cmp    $0x5e,%eax
  800496:	76 10                	jbe    8004a8 <vprintfmt+0x21f>
					putch('?', putdat);
  800498:	83 ec 08             	sub    $0x8,%esp
  80049b:	ff 75 0c             	pushl  0xc(%ebp)
  80049e:	6a 3f                	push   $0x3f
  8004a0:	ff 55 08             	call   *0x8(%ebp)
  8004a3:	83 c4 10             	add    $0x10,%esp
  8004a6:	eb 0d                	jmp    8004b5 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
  8004a8:	83 ec 08             	sub    $0x8,%esp
  8004ab:	ff 75 0c             	pushl  0xc(%ebp)
  8004ae:	52                   	push   %edx
  8004af:	ff 55 08             	call   *0x8(%ebp)
  8004b2:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004b5:	83 eb 01             	sub    $0x1,%ebx
  8004b8:	eb 1a                	jmp    8004d4 <vprintfmt+0x24b>
  8004ba:	89 75 08             	mov    %esi,0x8(%ebp)
  8004bd:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004c0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004c3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004c6:	eb 0c                	jmp    8004d4 <vprintfmt+0x24b>
  8004c8:	89 75 08             	mov    %esi,0x8(%ebp)
  8004cb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004d1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d4:	83 c7 01             	add    $0x1,%edi
  8004d7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004db:	0f be d0             	movsbl %al,%edx
  8004de:	85 d2                	test   %edx,%edx
  8004e0:	74 23                	je     800505 <vprintfmt+0x27c>
  8004e2:	85 f6                	test   %esi,%esi
  8004e4:	78 a1                	js     800487 <vprintfmt+0x1fe>
  8004e6:	83 ee 01             	sub    $0x1,%esi
  8004e9:	79 9c                	jns    800487 <vprintfmt+0x1fe>
  8004eb:	89 df                	mov    %ebx,%edi
  8004ed:	8b 75 08             	mov    0x8(%ebp),%esi
  8004f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004f3:	eb 18                	jmp    80050d <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004f5:	83 ec 08             	sub    $0x8,%esp
  8004f8:	53                   	push   %ebx
  8004f9:	6a 20                	push   $0x20
  8004fb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004fd:	83 ef 01             	sub    $0x1,%edi
  800500:	83 c4 10             	add    $0x10,%esp
  800503:	eb 08                	jmp    80050d <vprintfmt+0x284>
  800505:	89 df                	mov    %ebx,%edi
  800507:	8b 75 08             	mov    0x8(%ebp),%esi
  80050a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80050d:	85 ff                	test   %edi,%edi
  80050f:	7f e4                	jg     8004f5 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800511:	8b 45 cc             	mov    -0x34(%ebp),%eax
  800514:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800517:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80051a:	e9 90 fd ff ff       	jmp    8002af <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80051f:	83 f9 01             	cmp    $0x1,%ecx
  800522:	7e 19                	jle    80053d <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
  800524:	8b 45 14             	mov    0x14(%ebp),%eax
  800527:	8b 50 04             	mov    0x4(%eax),%edx
  80052a:	8b 00                	mov    (%eax),%eax
  80052c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80052f:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800532:	8b 45 14             	mov    0x14(%ebp),%eax
  800535:	8d 40 08             	lea    0x8(%eax),%eax
  800538:	89 45 14             	mov    %eax,0x14(%ebp)
  80053b:	eb 38                	jmp    800575 <vprintfmt+0x2ec>
	else if (lflag)
  80053d:	85 c9                	test   %ecx,%ecx
  80053f:	74 1b                	je     80055c <vprintfmt+0x2d3>
		return va_arg(*ap, long);
  800541:	8b 45 14             	mov    0x14(%ebp),%eax
  800544:	8b 00                	mov    (%eax),%eax
  800546:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800549:	89 c1                	mov    %eax,%ecx
  80054b:	c1 f9 1f             	sar    $0x1f,%ecx
  80054e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800551:	8b 45 14             	mov    0x14(%ebp),%eax
  800554:	8d 40 04             	lea    0x4(%eax),%eax
  800557:	89 45 14             	mov    %eax,0x14(%ebp)
  80055a:	eb 19                	jmp    800575 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
  80055c:	8b 45 14             	mov    0x14(%ebp),%eax
  80055f:	8b 00                	mov    (%eax),%eax
  800561:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800564:	89 c1                	mov    %eax,%ecx
  800566:	c1 f9 1f             	sar    $0x1f,%ecx
  800569:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80056c:	8b 45 14             	mov    0x14(%ebp),%eax
  80056f:	8d 40 04             	lea    0x4(%eax),%eax
  800572:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800575:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800578:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80057b:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800580:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800584:	0f 89 0e 01 00 00    	jns    800698 <vprintfmt+0x40f>
				putch('-', putdat);
  80058a:	83 ec 08             	sub    $0x8,%esp
  80058d:	53                   	push   %ebx
  80058e:	6a 2d                	push   $0x2d
  800590:	ff d6                	call   *%esi
				num = -(long long) num;
  800592:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800595:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  800598:	f7 da                	neg    %edx
  80059a:	83 d1 00             	adc    $0x0,%ecx
  80059d:	f7 d9                	neg    %ecx
  80059f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  8005a2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005a7:	e9 ec 00 00 00       	jmp    800698 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005ac:	83 f9 01             	cmp    $0x1,%ecx
  8005af:	7e 18                	jle    8005c9 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
  8005b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b4:	8b 10                	mov    (%eax),%edx
  8005b6:	8b 48 04             	mov    0x4(%eax),%ecx
  8005b9:	8d 40 08             	lea    0x8(%eax),%eax
  8005bc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005bf:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005c4:	e9 cf 00 00 00       	jmp    800698 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  8005c9:	85 c9                	test   %ecx,%ecx
  8005cb:	74 1a                	je     8005e7 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
  8005cd:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d0:	8b 10                	mov    (%eax),%edx
  8005d2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005d7:	8d 40 04             	lea    0x4(%eax),%eax
  8005da:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005dd:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005e2:	e9 b1 00 00 00       	jmp    800698 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  8005e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ea:	8b 10                	mov    (%eax),%edx
  8005ec:	b9 00 00 00 00       	mov    $0x0,%ecx
  8005f1:	8d 40 04             	lea    0x4(%eax),%eax
  8005f4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
  8005f7:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005fc:	e9 97 00 00 00       	jmp    800698 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800601:	83 ec 08             	sub    $0x8,%esp
  800604:	53                   	push   %ebx
  800605:	6a 58                	push   $0x58
  800607:	ff d6                	call   *%esi
			putch('X', putdat);
  800609:	83 c4 08             	add    $0x8,%esp
  80060c:	53                   	push   %ebx
  80060d:	6a 58                	push   $0x58
  80060f:	ff d6                	call   *%esi
			putch('X', putdat);
  800611:	83 c4 08             	add    $0x8,%esp
  800614:	53                   	push   %ebx
  800615:	6a 58                	push   $0x58
  800617:	ff d6                	call   *%esi
			break;
  800619:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80061c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
  80061f:	e9 8b fc ff ff       	jmp    8002af <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800624:	83 ec 08             	sub    $0x8,%esp
  800627:	53                   	push   %ebx
  800628:	6a 30                	push   $0x30
  80062a:	ff d6                	call   *%esi
			putch('x', putdat);
  80062c:	83 c4 08             	add    $0x8,%esp
  80062f:	53                   	push   %ebx
  800630:	6a 78                	push   $0x78
  800632:	ff d6                	call   *%esi
			num = (unsigned long long)
  800634:	8b 45 14             	mov    0x14(%ebp),%eax
  800637:	8b 10                	mov    (%eax),%edx
  800639:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80063e:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800641:	8d 40 04             	lea    0x4(%eax),%eax
  800644:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
  800647:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  80064c:	eb 4a                	jmp    800698 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80064e:	83 f9 01             	cmp    $0x1,%ecx
  800651:	7e 15                	jle    800668 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
  800653:	8b 45 14             	mov    0x14(%ebp),%eax
  800656:	8b 10                	mov    (%eax),%edx
  800658:	8b 48 04             	mov    0x4(%eax),%ecx
  80065b:	8d 40 08             	lea    0x8(%eax),%eax
  80065e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800661:	b8 10 00 00 00       	mov    $0x10,%eax
  800666:	eb 30                	jmp    800698 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
  800668:	85 c9                	test   %ecx,%ecx
  80066a:	74 17                	je     800683 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
  80066c:	8b 45 14             	mov    0x14(%ebp),%eax
  80066f:	8b 10                	mov    (%eax),%edx
  800671:	b9 00 00 00 00       	mov    $0x0,%ecx
  800676:	8d 40 04             	lea    0x4(%eax),%eax
  800679:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  80067c:	b8 10 00 00 00       	mov    $0x10,%eax
  800681:	eb 15                	jmp    800698 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
  800683:	8b 45 14             	mov    0x14(%ebp),%eax
  800686:	8b 10                	mov    (%eax),%edx
  800688:	b9 00 00 00 00       	mov    $0x0,%ecx
  80068d:	8d 40 04             	lea    0x4(%eax),%eax
  800690:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
  800693:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800698:	83 ec 0c             	sub    $0xc,%esp
  80069b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80069f:	57                   	push   %edi
  8006a0:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a3:	50                   	push   %eax
  8006a4:	51                   	push   %ecx
  8006a5:	52                   	push   %edx
  8006a6:	89 da                	mov    %ebx,%edx
  8006a8:	89 f0                	mov    %esi,%eax
  8006aa:	e8 f1 fa ff ff       	call   8001a0 <printnum>
			break;
  8006af:	83 c4 20             	add    $0x20,%esp
  8006b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006b5:	e9 f5 fb ff ff       	jmp    8002af <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ba:	83 ec 08             	sub    $0x8,%esp
  8006bd:	53                   	push   %ebx
  8006be:	52                   	push   %edx
  8006bf:	ff d6                	call   *%esi
			break;
  8006c1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006c7:	e9 e3 fb ff ff       	jmp    8002af <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006cc:	83 ec 08             	sub    $0x8,%esp
  8006cf:	53                   	push   %ebx
  8006d0:	6a 25                	push   $0x25
  8006d2:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d4:	83 c4 10             	add    $0x10,%esp
  8006d7:	eb 03                	jmp    8006dc <vprintfmt+0x453>
  8006d9:	83 ef 01             	sub    $0x1,%edi
  8006dc:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006e0:	75 f7                	jne    8006d9 <vprintfmt+0x450>
  8006e2:	e9 c8 fb ff ff       	jmp    8002af <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006ea:	5b                   	pop    %ebx
  8006eb:	5e                   	pop    %esi
  8006ec:	5f                   	pop    %edi
  8006ed:	5d                   	pop    %ebp
  8006ee:	c3                   	ret    

008006ef <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ef:	55                   	push   %ebp
  8006f0:	89 e5                	mov    %esp,%ebp
  8006f2:	83 ec 18             	sub    $0x18,%esp
  8006f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006fe:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800702:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800705:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070c:	85 c0                	test   %eax,%eax
  80070e:	74 26                	je     800736 <vsnprintf+0x47>
  800710:	85 d2                	test   %edx,%edx
  800712:	7e 22                	jle    800736 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800714:	ff 75 14             	pushl  0x14(%ebp)
  800717:	ff 75 10             	pushl  0x10(%ebp)
  80071a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071d:	50                   	push   %eax
  80071e:	68 4f 02 80 00       	push   $0x80024f
  800723:	e8 61 fb ff ff       	call   800289 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800728:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80072e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800731:	83 c4 10             	add    $0x10,%esp
  800734:	eb 05                	jmp    80073b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800736:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80073b:	c9                   	leave  
  80073c:	c3                   	ret    

0080073d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80073d:	55                   	push   %ebp
  80073e:	89 e5                	mov    %esp,%ebp
  800740:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800743:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800746:	50                   	push   %eax
  800747:	ff 75 10             	pushl  0x10(%ebp)
  80074a:	ff 75 0c             	pushl  0xc(%ebp)
  80074d:	ff 75 08             	pushl  0x8(%ebp)
  800750:	e8 9a ff ff ff       	call   8006ef <vsnprintf>
	va_end(ap);

	return rc;
}
  800755:	c9                   	leave  
  800756:	c3                   	ret    

00800757 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800757:	55                   	push   %ebp
  800758:	89 e5                	mov    %esp,%ebp
  80075a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80075d:	b8 00 00 00 00       	mov    $0x0,%eax
  800762:	eb 03                	jmp    800767 <strlen+0x10>
		n++;
  800764:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800767:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80076b:	75 f7                	jne    800764 <strlen+0xd>
		n++;
	return n;
}
  80076d:	5d                   	pop    %ebp
  80076e:	c3                   	ret    

0080076f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80076f:	55                   	push   %ebp
  800770:	89 e5                	mov    %esp,%ebp
  800772:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800775:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800778:	ba 00 00 00 00       	mov    $0x0,%edx
  80077d:	eb 03                	jmp    800782 <strnlen+0x13>
		n++;
  80077f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800782:	39 c2                	cmp    %eax,%edx
  800784:	74 08                	je     80078e <strnlen+0x1f>
  800786:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80078a:	75 f3                	jne    80077f <strnlen+0x10>
  80078c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80078e:	5d                   	pop    %ebp
  80078f:	c3                   	ret    

00800790 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800790:	55                   	push   %ebp
  800791:	89 e5                	mov    %esp,%ebp
  800793:	53                   	push   %ebx
  800794:	8b 45 08             	mov    0x8(%ebp),%eax
  800797:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80079a:	89 c2                	mov    %eax,%edx
  80079c:	83 c2 01             	add    $0x1,%edx
  80079f:	83 c1 01             	add    $0x1,%ecx
  8007a2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007a6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a9:	84 db                	test   %bl,%bl
  8007ab:	75 ef                	jne    80079c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ad:	5b                   	pop    %ebx
  8007ae:	5d                   	pop    %ebp
  8007af:	c3                   	ret    

008007b0 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b0:	55                   	push   %ebp
  8007b1:	89 e5                	mov    %esp,%ebp
  8007b3:	53                   	push   %ebx
  8007b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b7:	53                   	push   %ebx
  8007b8:	e8 9a ff ff ff       	call   800757 <strlen>
  8007bd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007c0:	ff 75 0c             	pushl  0xc(%ebp)
  8007c3:	01 d8                	add    %ebx,%eax
  8007c5:	50                   	push   %eax
  8007c6:	e8 c5 ff ff ff       	call   800790 <strcpy>
	return dst;
}
  8007cb:	89 d8                	mov    %ebx,%eax
  8007cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007d0:	c9                   	leave  
  8007d1:	c3                   	ret    

008007d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	56                   	push   %esi
  8007d6:	53                   	push   %ebx
  8007d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007dd:	89 f3                	mov    %esi,%ebx
  8007df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e2:	89 f2                	mov    %esi,%edx
  8007e4:	eb 0f                	jmp    8007f5 <strncpy+0x23>
		*dst++ = *src;
  8007e6:	83 c2 01             	add    $0x1,%edx
  8007e9:	0f b6 01             	movzbl (%ecx),%eax
  8007ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f5:	39 da                	cmp    %ebx,%edx
  8007f7:	75 ed                	jne    8007e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f9:	89 f0                	mov    %esi,%eax
  8007fb:	5b                   	pop    %ebx
  8007fc:	5e                   	pop    %esi
  8007fd:	5d                   	pop    %ebp
  8007fe:	c3                   	ret    

008007ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	56                   	push   %esi
  800803:	53                   	push   %ebx
  800804:	8b 75 08             	mov    0x8(%ebp),%esi
  800807:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80080a:	8b 55 10             	mov    0x10(%ebp),%edx
  80080d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80080f:	85 d2                	test   %edx,%edx
  800811:	74 21                	je     800834 <strlcpy+0x35>
  800813:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800817:	89 f2                	mov    %esi,%edx
  800819:	eb 09                	jmp    800824 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80081b:	83 c2 01             	add    $0x1,%edx
  80081e:	83 c1 01             	add    $0x1,%ecx
  800821:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800824:	39 c2                	cmp    %eax,%edx
  800826:	74 09                	je     800831 <strlcpy+0x32>
  800828:	0f b6 19             	movzbl (%ecx),%ebx
  80082b:	84 db                	test   %bl,%bl
  80082d:	75 ec                	jne    80081b <strlcpy+0x1c>
  80082f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800831:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800834:	29 f0                	sub    %esi,%eax
}
  800836:	5b                   	pop    %ebx
  800837:	5e                   	pop    %esi
  800838:	5d                   	pop    %ebp
  800839:	c3                   	ret    

0080083a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80083a:	55                   	push   %ebp
  80083b:	89 e5                	mov    %esp,%ebp
  80083d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800840:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800843:	eb 06                	jmp    80084b <strcmp+0x11>
		p++, q++;
  800845:	83 c1 01             	add    $0x1,%ecx
  800848:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084b:	0f b6 01             	movzbl (%ecx),%eax
  80084e:	84 c0                	test   %al,%al
  800850:	74 04                	je     800856 <strcmp+0x1c>
  800852:	3a 02                	cmp    (%edx),%al
  800854:	74 ef                	je     800845 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800856:	0f b6 c0             	movzbl %al,%eax
  800859:	0f b6 12             	movzbl (%edx),%edx
  80085c:	29 d0                	sub    %edx,%eax
}
  80085e:	5d                   	pop    %ebp
  80085f:	c3                   	ret    

00800860 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	53                   	push   %ebx
  800864:	8b 45 08             	mov    0x8(%ebp),%eax
  800867:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086a:	89 c3                	mov    %eax,%ebx
  80086c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80086f:	eb 06                	jmp    800877 <strncmp+0x17>
		n--, p++, q++;
  800871:	83 c0 01             	add    $0x1,%eax
  800874:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800877:	39 d8                	cmp    %ebx,%eax
  800879:	74 15                	je     800890 <strncmp+0x30>
  80087b:	0f b6 08             	movzbl (%eax),%ecx
  80087e:	84 c9                	test   %cl,%cl
  800880:	74 04                	je     800886 <strncmp+0x26>
  800882:	3a 0a                	cmp    (%edx),%cl
  800884:	74 eb                	je     800871 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800886:	0f b6 00             	movzbl (%eax),%eax
  800889:	0f b6 12             	movzbl (%edx),%edx
  80088c:	29 d0                	sub    %edx,%eax
  80088e:	eb 05                	jmp    800895 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800890:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800895:	5b                   	pop    %ebx
  800896:	5d                   	pop    %ebp
  800897:	c3                   	ret    

00800898 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800898:	55                   	push   %ebp
  800899:	89 e5                	mov    %esp,%ebp
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a2:	eb 07                	jmp    8008ab <strchr+0x13>
		if (*s == c)
  8008a4:	38 ca                	cmp    %cl,%dl
  8008a6:	74 0f                	je     8008b7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008a8:	83 c0 01             	add    $0x1,%eax
  8008ab:	0f b6 10             	movzbl (%eax),%edx
  8008ae:	84 d2                	test   %dl,%dl
  8008b0:	75 f2                	jne    8008a4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b7:	5d                   	pop    %ebp
  8008b8:	c3                   	ret    

008008b9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008b9:	55                   	push   %ebp
  8008ba:	89 e5                	mov    %esp,%ebp
  8008bc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c3:	eb 03                	jmp    8008c8 <strfind+0xf>
  8008c5:	83 c0 01             	add    $0x1,%eax
  8008c8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008cb:	38 ca                	cmp    %cl,%dl
  8008cd:	74 04                	je     8008d3 <strfind+0x1a>
  8008cf:	84 d2                	test   %dl,%dl
  8008d1:	75 f2                	jne    8008c5 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d3:	5d                   	pop    %ebp
  8008d4:	c3                   	ret    

008008d5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d5:	55                   	push   %ebp
  8008d6:	89 e5                	mov    %esp,%ebp
  8008d8:	57                   	push   %edi
  8008d9:	56                   	push   %esi
  8008da:	53                   	push   %ebx
  8008db:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e1:	85 c9                	test   %ecx,%ecx
  8008e3:	74 36                	je     80091b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e5:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008eb:	75 28                	jne    800915 <memset+0x40>
  8008ed:	f6 c1 03             	test   $0x3,%cl
  8008f0:	75 23                	jne    800915 <memset+0x40>
		c &= 0xFF;
  8008f2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f6:	89 d3                	mov    %edx,%ebx
  8008f8:	c1 e3 08             	shl    $0x8,%ebx
  8008fb:	89 d6                	mov    %edx,%esi
  8008fd:	c1 e6 18             	shl    $0x18,%esi
  800900:	89 d0                	mov    %edx,%eax
  800902:	c1 e0 10             	shl    $0x10,%eax
  800905:	09 f0                	or     %esi,%eax
  800907:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800909:	89 d8                	mov    %ebx,%eax
  80090b:	09 d0                	or     %edx,%eax
  80090d:	c1 e9 02             	shr    $0x2,%ecx
  800910:	fc                   	cld    
  800911:	f3 ab                	rep stos %eax,%es:(%edi)
  800913:	eb 06                	jmp    80091b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800915:	8b 45 0c             	mov    0xc(%ebp),%eax
  800918:	fc                   	cld    
  800919:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091b:	89 f8                	mov    %edi,%eax
  80091d:	5b                   	pop    %ebx
  80091e:	5e                   	pop    %esi
  80091f:	5f                   	pop    %edi
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	57                   	push   %edi
  800926:	56                   	push   %esi
  800927:	8b 45 08             	mov    0x8(%ebp),%eax
  80092a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800930:	39 c6                	cmp    %eax,%esi
  800932:	73 35                	jae    800969 <memmove+0x47>
  800934:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800937:	39 d0                	cmp    %edx,%eax
  800939:	73 2e                	jae    800969 <memmove+0x47>
		s += n;
		d += n;
  80093b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093e:	89 d6                	mov    %edx,%esi
  800940:	09 fe                	or     %edi,%esi
  800942:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800948:	75 13                	jne    80095d <memmove+0x3b>
  80094a:	f6 c1 03             	test   $0x3,%cl
  80094d:	75 0e                	jne    80095d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80094f:	83 ef 04             	sub    $0x4,%edi
  800952:	8d 72 fc             	lea    -0x4(%edx),%esi
  800955:	c1 e9 02             	shr    $0x2,%ecx
  800958:	fd                   	std    
  800959:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095b:	eb 09                	jmp    800966 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80095d:	83 ef 01             	sub    $0x1,%edi
  800960:	8d 72 ff             	lea    -0x1(%edx),%esi
  800963:	fd                   	std    
  800964:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800966:	fc                   	cld    
  800967:	eb 1d                	jmp    800986 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800969:	89 f2                	mov    %esi,%edx
  80096b:	09 c2                	or     %eax,%edx
  80096d:	f6 c2 03             	test   $0x3,%dl
  800970:	75 0f                	jne    800981 <memmove+0x5f>
  800972:	f6 c1 03             	test   $0x3,%cl
  800975:	75 0a                	jne    800981 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800977:	c1 e9 02             	shr    $0x2,%ecx
  80097a:	89 c7                	mov    %eax,%edi
  80097c:	fc                   	cld    
  80097d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097f:	eb 05                	jmp    800986 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800981:	89 c7                	mov    %eax,%edi
  800983:	fc                   	cld    
  800984:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800986:	5e                   	pop    %esi
  800987:	5f                   	pop    %edi
  800988:	5d                   	pop    %ebp
  800989:	c3                   	ret    

0080098a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80098a:	55                   	push   %ebp
  80098b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80098d:	ff 75 10             	pushl  0x10(%ebp)
  800990:	ff 75 0c             	pushl  0xc(%ebp)
  800993:	ff 75 08             	pushl  0x8(%ebp)
  800996:	e8 87 ff ff ff       	call   800922 <memmove>
}
  80099b:	c9                   	leave  
  80099c:	c3                   	ret    

0080099d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099d:	55                   	push   %ebp
  80099e:	89 e5                	mov    %esp,%ebp
  8009a0:	56                   	push   %esi
  8009a1:	53                   	push   %ebx
  8009a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009a8:	89 c6                	mov    %eax,%esi
  8009aa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ad:	eb 1a                	jmp    8009c9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009af:	0f b6 08             	movzbl (%eax),%ecx
  8009b2:	0f b6 1a             	movzbl (%edx),%ebx
  8009b5:	38 d9                	cmp    %bl,%cl
  8009b7:	74 0a                	je     8009c3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009b9:	0f b6 c1             	movzbl %cl,%eax
  8009bc:	0f b6 db             	movzbl %bl,%ebx
  8009bf:	29 d8                	sub    %ebx,%eax
  8009c1:	eb 0f                	jmp    8009d2 <memcmp+0x35>
		s1++, s2++;
  8009c3:	83 c0 01             	add    $0x1,%eax
  8009c6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c9:	39 f0                	cmp    %esi,%eax
  8009cb:	75 e2                	jne    8009af <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d2:	5b                   	pop    %ebx
  8009d3:	5e                   	pop    %esi
  8009d4:	5d                   	pop    %ebp
  8009d5:	c3                   	ret    

008009d6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d6:	55                   	push   %ebp
  8009d7:	89 e5                	mov    %esp,%ebp
  8009d9:	53                   	push   %ebx
  8009da:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009dd:	89 c1                	mov    %eax,%ecx
  8009df:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009e6:	eb 0a                	jmp    8009f2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e8:	0f b6 10             	movzbl (%eax),%edx
  8009eb:	39 da                	cmp    %ebx,%edx
  8009ed:	74 07                	je     8009f6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ef:	83 c0 01             	add    $0x1,%eax
  8009f2:	39 c8                	cmp    %ecx,%eax
  8009f4:	72 f2                	jb     8009e8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f6:	5b                   	pop    %ebx
  8009f7:	5d                   	pop    %ebp
  8009f8:	c3                   	ret    

008009f9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f9:	55                   	push   %ebp
  8009fa:	89 e5                	mov    %esp,%ebp
  8009fc:	57                   	push   %edi
  8009fd:	56                   	push   %esi
  8009fe:	53                   	push   %ebx
  8009ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a02:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a05:	eb 03                	jmp    800a0a <strtol+0x11>
		s++;
  800a07:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a0a:	0f b6 01             	movzbl (%ecx),%eax
  800a0d:	3c 20                	cmp    $0x20,%al
  800a0f:	74 f6                	je     800a07 <strtol+0xe>
  800a11:	3c 09                	cmp    $0x9,%al
  800a13:	74 f2                	je     800a07 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a15:	3c 2b                	cmp    $0x2b,%al
  800a17:	75 0a                	jne    800a23 <strtol+0x2a>
		s++;
  800a19:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a1c:	bf 00 00 00 00       	mov    $0x0,%edi
  800a21:	eb 11                	jmp    800a34 <strtol+0x3b>
  800a23:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a28:	3c 2d                	cmp    $0x2d,%al
  800a2a:	75 08                	jne    800a34 <strtol+0x3b>
		s++, neg = 1;
  800a2c:	83 c1 01             	add    $0x1,%ecx
  800a2f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a34:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a3a:	75 15                	jne    800a51 <strtol+0x58>
  800a3c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a3f:	75 10                	jne    800a51 <strtol+0x58>
  800a41:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a45:	75 7c                	jne    800ac3 <strtol+0xca>
		s += 2, base = 16;
  800a47:	83 c1 02             	add    $0x2,%ecx
  800a4a:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a4f:	eb 16                	jmp    800a67 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a51:	85 db                	test   %ebx,%ebx
  800a53:	75 12                	jne    800a67 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a55:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a5a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5d:	75 08                	jne    800a67 <strtol+0x6e>
		s++, base = 8;
  800a5f:	83 c1 01             	add    $0x1,%ecx
  800a62:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a67:	b8 00 00 00 00       	mov    $0x0,%eax
  800a6c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a6f:	0f b6 11             	movzbl (%ecx),%edx
  800a72:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a75:	89 f3                	mov    %esi,%ebx
  800a77:	80 fb 09             	cmp    $0x9,%bl
  800a7a:	77 08                	ja     800a84 <strtol+0x8b>
			dig = *s - '0';
  800a7c:	0f be d2             	movsbl %dl,%edx
  800a7f:	83 ea 30             	sub    $0x30,%edx
  800a82:	eb 22                	jmp    800aa6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a84:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a87:	89 f3                	mov    %esi,%ebx
  800a89:	80 fb 19             	cmp    $0x19,%bl
  800a8c:	77 08                	ja     800a96 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a8e:	0f be d2             	movsbl %dl,%edx
  800a91:	83 ea 57             	sub    $0x57,%edx
  800a94:	eb 10                	jmp    800aa6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a96:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a99:	89 f3                	mov    %esi,%ebx
  800a9b:	80 fb 19             	cmp    $0x19,%bl
  800a9e:	77 16                	ja     800ab6 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800aa0:	0f be d2             	movsbl %dl,%edx
  800aa3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aa6:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aa9:	7d 0b                	jge    800ab6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aab:	83 c1 01             	add    $0x1,%ecx
  800aae:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ab2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ab4:	eb b9                	jmp    800a6f <strtol+0x76>

	if (endptr)
  800ab6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aba:	74 0d                	je     800ac9 <strtol+0xd0>
		*endptr = (char *) s;
  800abc:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abf:	89 0e                	mov    %ecx,(%esi)
  800ac1:	eb 06                	jmp    800ac9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac3:	85 db                	test   %ebx,%ebx
  800ac5:	74 98                	je     800a5f <strtol+0x66>
  800ac7:	eb 9e                	jmp    800a67 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ac9:	89 c2                	mov    %eax,%edx
  800acb:	f7 da                	neg    %edx
  800acd:	85 ff                	test   %edi,%edi
  800acf:	0f 45 c2             	cmovne %edx,%eax
}
  800ad2:	5b                   	pop    %ebx
  800ad3:	5e                   	pop    %esi
  800ad4:	5f                   	pop    %edi
  800ad5:	5d                   	pop    %ebp
  800ad6:	c3                   	ret    

00800ad7 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ad7:	55                   	push   %ebp
  800ad8:	89 e5                	mov    %esp,%ebp
  800ada:	57                   	push   %edi
  800adb:	56                   	push   %esi
  800adc:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800add:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ae5:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae8:	89 c3                	mov    %eax,%ebx
  800aea:	89 c7                	mov    %eax,%edi
  800aec:	89 c6                	mov    %eax,%esi
  800aee:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800af0:	5b                   	pop    %ebx
  800af1:	5e                   	pop    %esi
  800af2:	5f                   	pop    %edi
  800af3:	5d                   	pop    %ebp
  800af4:	c3                   	ret    

00800af5 <sys_cgetc>:

int
sys_cgetc(void)
{
  800af5:	55                   	push   %ebp
  800af6:	89 e5                	mov    %esp,%ebp
  800af8:	57                   	push   %edi
  800af9:	56                   	push   %esi
  800afa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800afb:	ba 00 00 00 00       	mov    $0x0,%edx
  800b00:	b8 01 00 00 00       	mov    $0x1,%eax
  800b05:	89 d1                	mov    %edx,%ecx
  800b07:	89 d3                	mov    %edx,%ebx
  800b09:	89 d7                	mov    %edx,%edi
  800b0b:	89 d6                	mov    %edx,%esi
  800b0d:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b0f:	5b                   	pop    %ebx
  800b10:	5e                   	pop    %esi
  800b11:	5f                   	pop    %edi
  800b12:	5d                   	pop    %ebp
  800b13:	c3                   	ret    

00800b14 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b14:	55                   	push   %ebp
  800b15:	89 e5                	mov    %esp,%ebp
  800b17:	57                   	push   %edi
  800b18:	56                   	push   %esi
  800b19:	53                   	push   %ebx
  800b1a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b22:	b8 03 00 00 00       	mov    $0x3,%eax
  800b27:	8b 55 08             	mov    0x8(%ebp),%edx
  800b2a:	89 cb                	mov    %ecx,%ebx
  800b2c:	89 cf                	mov    %ecx,%edi
  800b2e:	89 ce                	mov    %ecx,%esi
  800b30:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b32:	85 c0                	test   %eax,%eax
  800b34:	7e 17                	jle    800b4d <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b36:	83 ec 0c             	sub    $0xc,%esp
  800b39:	50                   	push   %eax
  800b3a:	6a 03                	push   $0x3
  800b3c:	68 a4 13 80 00       	push   $0x8013a4
  800b41:	6a 23                	push   $0x23
  800b43:	68 c1 13 80 00       	push   $0x8013c1
  800b48:	e8 fb 02 00 00       	call   800e48 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b4d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b50:	5b                   	pop    %ebx
  800b51:	5e                   	pop    %esi
  800b52:	5f                   	pop    %edi
  800b53:	5d                   	pop    %ebp
  800b54:	c3                   	ret    

00800b55 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b55:	55                   	push   %ebp
  800b56:	89 e5                	mov    %esp,%ebp
  800b58:	57                   	push   %edi
  800b59:	56                   	push   %esi
  800b5a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b5b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b60:	b8 02 00 00 00       	mov    $0x2,%eax
  800b65:	89 d1                	mov    %edx,%ecx
  800b67:	89 d3                	mov    %edx,%ebx
  800b69:	89 d7                	mov    %edx,%edi
  800b6b:	89 d6                	mov    %edx,%esi
  800b6d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b6f:	5b                   	pop    %ebx
  800b70:	5e                   	pop    %esi
  800b71:	5f                   	pop    %edi
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <sys_yield>:

void
sys_yield(void)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	57                   	push   %edi
  800b78:	56                   	push   %esi
  800b79:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b7f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b84:	89 d1                	mov    %edx,%ecx
  800b86:	89 d3                	mov    %edx,%ebx
  800b88:	89 d7                	mov    %edx,%edi
  800b8a:	89 d6                	mov    %edx,%esi
  800b8c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800b8e:	5b                   	pop    %ebx
  800b8f:	5e                   	pop    %esi
  800b90:	5f                   	pop    %edi
  800b91:	5d                   	pop    %ebp
  800b92:	c3                   	ret    

00800b93 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
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
  800b9c:	be 00 00 00 00       	mov    $0x0,%esi
  800ba1:	b8 04 00 00 00       	mov    $0x4,%eax
  800ba6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ba9:	8b 55 08             	mov    0x8(%ebp),%edx
  800bac:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800baf:	89 f7                	mov    %esi,%edi
  800bb1:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bb3:	85 c0                	test   %eax,%eax
  800bb5:	7e 17                	jle    800bce <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bb7:	83 ec 0c             	sub    $0xc,%esp
  800bba:	50                   	push   %eax
  800bbb:	6a 04                	push   $0x4
  800bbd:	68 a4 13 80 00       	push   $0x8013a4
  800bc2:	6a 23                	push   $0x23
  800bc4:	68 c1 13 80 00       	push   $0x8013c1
  800bc9:	e8 7a 02 00 00       	call   800e48 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800bce:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800bd1:	5b                   	pop    %ebx
  800bd2:	5e                   	pop    %esi
  800bd3:	5f                   	pop    %edi
  800bd4:	5d                   	pop    %ebp
  800bd5:	c3                   	ret    

00800bd6 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800bd6:	55                   	push   %ebp
  800bd7:	89 e5                	mov    %esp,%ebp
  800bd9:	57                   	push   %edi
  800bda:	56                   	push   %esi
  800bdb:	53                   	push   %ebx
  800bdc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bdf:	b8 05 00 00 00       	mov    $0x5,%eax
  800be4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800be7:	8b 55 08             	mov    0x8(%ebp),%edx
  800bea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bed:	8b 7d 14             	mov    0x14(%ebp),%edi
  800bf0:	8b 75 18             	mov    0x18(%ebp),%esi
  800bf3:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bf5:	85 c0                	test   %eax,%eax
  800bf7:	7e 17                	jle    800c10 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bf9:	83 ec 0c             	sub    $0xc,%esp
  800bfc:	50                   	push   %eax
  800bfd:	6a 05                	push   $0x5
  800bff:	68 a4 13 80 00       	push   $0x8013a4
  800c04:	6a 23                	push   $0x23
  800c06:	68 c1 13 80 00       	push   $0x8013c1
  800c0b:	e8 38 02 00 00       	call   800e48 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c10:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c13:	5b                   	pop    %ebx
  800c14:	5e                   	pop    %esi
  800c15:	5f                   	pop    %edi
  800c16:	5d                   	pop    %ebp
  800c17:	c3                   	ret    

00800c18 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c18:	55                   	push   %ebp
  800c19:	89 e5                	mov    %esp,%ebp
  800c1b:	57                   	push   %edi
  800c1c:	56                   	push   %esi
  800c1d:	53                   	push   %ebx
  800c1e:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c21:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c26:	b8 06 00 00 00       	mov    $0x6,%eax
  800c2b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c2e:	8b 55 08             	mov    0x8(%ebp),%edx
  800c31:	89 df                	mov    %ebx,%edi
  800c33:	89 de                	mov    %ebx,%esi
  800c35:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c37:	85 c0                	test   %eax,%eax
  800c39:	7e 17                	jle    800c52 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c3b:	83 ec 0c             	sub    $0xc,%esp
  800c3e:	50                   	push   %eax
  800c3f:	6a 06                	push   $0x6
  800c41:	68 a4 13 80 00       	push   $0x8013a4
  800c46:	6a 23                	push   $0x23
  800c48:	68 c1 13 80 00       	push   $0x8013c1
  800c4d:	e8 f6 01 00 00       	call   800e48 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c52:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c55:	5b                   	pop    %ebx
  800c56:	5e                   	pop    %esi
  800c57:	5f                   	pop    %edi
  800c58:	5d                   	pop    %ebp
  800c59:	c3                   	ret    

00800c5a <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c5a:	55                   	push   %ebp
  800c5b:	89 e5                	mov    %esp,%ebp
  800c5d:	57                   	push   %edi
  800c5e:	56                   	push   %esi
  800c5f:	53                   	push   %ebx
  800c60:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c63:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c68:	b8 08 00 00 00       	mov    $0x8,%eax
  800c6d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c70:	8b 55 08             	mov    0x8(%ebp),%edx
  800c73:	89 df                	mov    %ebx,%edi
  800c75:	89 de                	mov    %ebx,%esi
  800c77:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c79:	85 c0                	test   %eax,%eax
  800c7b:	7e 17                	jle    800c94 <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c7d:	83 ec 0c             	sub    $0xc,%esp
  800c80:	50                   	push   %eax
  800c81:	6a 08                	push   $0x8
  800c83:	68 a4 13 80 00       	push   $0x8013a4
  800c88:	6a 23                	push   $0x23
  800c8a:	68 c1 13 80 00       	push   $0x8013c1
  800c8f:	e8 b4 01 00 00       	call   800e48 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800c94:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800c97:	5b                   	pop    %ebx
  800c98:	5e                   	pop    %esi
  800c99:	5f                   	pop    %edi
  800c9a:	5d                   	pop    %ebp
  800c9b:	c3                   	ret    

00800c9c <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800c9c:	55                   	push   %ebp
  800c9d:	89 e5                	mov    %esp,%ebp
  800c9f:	57                   	push   %edi
  800ca0:	56                   	push   %esi
  800ca1:	53                   	push   %ebx
  800ca2:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ca5:	bb 00 00 00 00       	mov    $0x0,%ebx
  800caa:	b8 09 00 00 00       	mov    $0x9,%eax
  800caf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cb2:	8b 55 08             	mov    0x8(%ebp),%edx
  800cb5:	89 df                	mov    %ebx,%edi
  800cb7:	89 de                	mov    %ebx,%esi
  800cb9:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cbb:	85 c0                	test   %eax,%eax
  800cbd:	7e 17                	jle    800cd6 <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cbf:	83 ec 0c             	sub    $0xc,%esp
  800cc2:	50                   	push   %eax
  800cc3:	6a 09                	push   $0x9
  800cc5:	68 a4 13 80 00       	push   $0x8013a4
  800cca:	6a 23                	push   $0x23
  800ccc:	68 c1 13 80 00       	push   $0x8013c1
  800cd1:	e8 72 01 00 00       	call   800e48 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800cd6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800cd9:	5b                   	pop    %ebx
  800cda:	5e                   	pop    %esi
  800cdb:	5f                   	pop    %edi
  800cdc:	5d                   	pop    %ebp
  800cdd:	c3                   	ret    

00800cde <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800cde:	55                   	push   %ebp
  800cdf:	89 e5                	mov    %esp,%ebp
  800ce1:	57                   	push   %edi
  800ce2:	56                   	push   %esi
  800ce3:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ce4:	be 00 00 00 00       	mov    $0x0,%esi
  800ce9:	b8 0b 00 00 00       	mov    $0xb,%eax
  800cee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cf1:	8b 55 08             	mov    0x8(%ebp),%edx
  800cf4:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cf7:	8b 7d 14             	mov    0x14(%ebp),%edi
  800cfa:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800cfc:	5b                   	pop    %ebx
  800cfd:	5e                   	pop    %esi
  800cfe:	5f                   	pop    %edi
  800cff:	5d                   	pop    %ebp
  800d00:	c3                   	ret    

00800d01 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d01:	55                   	push   %ebp
  800d02:	89 e5                	mov    %esp,%ebp
  800d04:	57                   	push   %edi
  800d05:	56                   	push   %esi
  800d06:	53                   	push   %ebx
  800d07:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d0a:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d0f:	b8 0c 00 00 00       	mov    $0xc,%eax
  800d14:	8b 55 08             	mov    0x8(%ebp),%edx
  800d17:	89 cb                	mov    %ecx,%ebx
  800d19:	89 cf                	mov    %ecx,%edi
  800d1b:	89 ce                	mov    %ecx,%esi
  800d1d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d1f:	85 c0                	test   %eax,%eax
  800d21:	7e 17                	jle    800d3a <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d23:	83 ec 0c             	sub    $0xc,%esp
  800d26:	50                   	push   %eax
  800d27:	6a 0c                	push   $0xc
  800d29:	68 a4 13 80 00       	push   $0x8013a4
  800d2e:	6a 23                	push   $0x23
  800d30:	68 c1 13 80 00       	push   $0x8013c1
  800d35:	e8 0e 01 00 00       	call   800e48 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800d3a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800d3d:	5b                   	pop    %ebx
  800d3e:	5e                   	pop    %esi
  800d3f:	5f                   	pop    %edi
  800d40:	5d                   	pop    %ebp
  800d41:	c3                   	ret    

00800d42 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  800d42:	55                   	push   %ebp
  800d43:	89 e5                	mov    %esp,%ebp
  800d45:	56                   	push   %esi
  800d46:	53                   	push   %ebx
  800d47:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800d4a:	8b 75 10             	mov    0x10(%ebp),%esi
	// LAB 4: Your code here.
	int r;
	r=sys_ipc_recv(pg);
  800d4d:	83 ec 0c             	sub    $0xc,%esp
  800d50:	ff 75 0c             	pushl  0xc(%ebp)
  800d53:	e8 a9 ff ff ff       	call   800d01 <sys_ipc_recv>
	if(from_env_store!=NULL)
  800d58:	83 c4 10             	add    $0x10,%esp
  800d5b:	85 db                	test   %ebx,%ebx
  800d5d:	74 25                	je     800d84 <ipc_recv+0x42>
	{
		if(r<0)
  800d5f:	85 c0                	test   %eax,%eax
  800d61:	79 11                	jns    800d74 <ipc_recv+0x32>
			*from_env_store=0;
  800d63:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  800d69:	b8 00 00 00 00       	mov    $0x0,%eax
		if(r<0)
			*from_env_store=0;
		else
			*from_env_store=thisenv->env_ipc_from;
	}
	if(perm_store!=NULL)
  800d6e:	85 f6                	test   %esi,%esi
  800d70:	74 46                	je     800db8 <ipc_recv+0x76>
  800d72:	eb 18                	jmp    800d8c <ipc_recv+0x4a>
	if(from_env_store!=NULL)
	{
		if(r<0)
			*from_env_store=0;
		else
			*from_env_store=thisenv->env_ipc_from;
  800d74:	a1 04 20 80 00       	mov    0x802004,%eax
  800d79:	8b 40 74             	mov    0x74(%eax),%eax
  800d7c:	89 03                	mov    %eax,(%ebx)
	}
	if(perm_store!=NULL)
  800d7e:	85 f6                	test   %esi,%esi
  800d80:	75 17                	jne    800d99 <ipc_recv+0x57>
  800d82:	eb 25                	jmp    800da9 <ipc_recv+0x67>
  800d84:	85 f6                	test   %esi,%esi
  800d86:	74 1d                	je     800da5 <ipc_recv+0x63>
	{
		if(r<0)
  800d88:	85 c0                	test   %eax,%eax
  800d8a:	79 0d                	jns    800d99 <ipc_recv+0x57>
			*perm_store=0;
  800d8c:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  800d92:	b8 00 00 00 00       	mov    $0x0,%eax
  800d97:	eb 1f                	jmp    800db8 <ipc_recv+0x76>
	if(perm_store!=NULL)
	{
		if(r<0)
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
  800d99:	a1 04 20 80 00       	mov    0x802004,%eax
  800d9e:	8b 40 78             	mov    0x78(%eax),%eax
  800da1:	89 06                	mov    %eax,(%esi)
  800da3:	eb 04                	jmp    800da9 <ipc_recv+0x67>
	}
	if(r<0)
  800da5:	85 c0                	test   %eax,%eax
  800da7:	78 0a                	js     800db3 <ipc_recv+0x71>
		return 0;
	//panic("ipc_recv not implemented");
	return thisenv->env_ipc_value;
  800da9:	a1 04 20 80 00       	mov    0x802004,%eax
  800dae:	8b 40 70             	mov    0x70(%eax),%eax
  800db1:	eb 05                	jmp    800db8 <ipc_recv+0x76>
			*perm_store=0;
		else
			*perm_store=thisenv->env_ipc_perm;
	}
	if(r<0)
		return 0;
  800db3:	b8 00 00 00 00       	mov    $0x0,%eax
	//panic("ipc_recv not implemented");
	return thisenv->env_ipc_value;
}
  800db8:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800dbb:	5b                   	pop    %ebx
  800dbc:	5e                   	pop    %esi
  800dbd:	5d                   	pop    %ebp
  800dbe:	c3                   	ret    

00800dbf <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  800dbf:	55                   	push   %ebp
  800dc0:	89 e5                	mov    %esp,%ebp
  800dc2:	57                   	push   %edi
  800dc3:	56                   	push   %esi
  800dc4:	53                   	push   %ebx
  800dc5:	83 ec 0c             	sub    $0xc,%esp
  800dc8:	8b 7d 08             	mov    0x8(%ebp),%edi
  800dcb:	8b 75 0c             	mov    0xc(%ebp),%esi
	// LAB 4: Your code here.
	while(1)
	{
		int r=sys_ipc_try_send(to_env,val,pg,perm);
  800dce:	ff 75 14             	pushl  0x14(%ebp)
  800dd1:	ff 75 10             	pushl  0x10(%ebp)
  800dd4:	56                   	push   %esi
  800dd5:	57                   	push   %edi
  800dd6:	e8 03 ff ff ff       	call   800cde <sys_ipc_try_send>
  800ddb:	89 c3                	mov    %eax,%ebx
		if(r<0&&r!= -E_IPC_NOT_RECV)
  800ddd:	c1 e8 1f             	shr    $0x1f,%eax
  800de0:	83 c4 10             	add    $0x10,%esp
  800de3:	84 c0                	test   %al,%al
  800de5:	74 17                	je     800dfe <ipc_send+0x3f>
  800de7:	83 fb f9             	cmp    $0xfffffff9,%ebx
  800dea:	74 12                	je     800dfe <ipc_send+0x3f>
			panic("ipc_send:%e\n",r);
  800dec:	53                   	push   %ebx
  800ded:	68 cf 13 80 00       	push   $0x8013cf
  800df2:	6a 40                	push   $0x40
  800df4:	68 dc 13 80 00       	push   $0x8013dc
  800df9:	e8 4a 00 00 00       	call   800e48 <_panic>
		sys_yield();
  800dfe:	e8 71 fd ff ff       	call   800b74 <sys_yield>
		if(r==0)
  800e03:	85 db                	test   %ebx,%ebx
  800e05:	75 c7                	jne    800dce <ipc_send+0xf>
			break;
	}
	//panic("ipc_send not implemented");
}
  800e07:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800e0a:	5b                   	pop    %ebx
  800e0b:	5e                   	pop    %esi
  800e0c:	5f                   	pop    %edi
  800e0d:	5d                   	pop    %ebp
  800e0e:	c3                   	ret    

00800e0f <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  800e0f:	55                   	push   %ebp
  800e10:	89 e5                	mov    %esp,%ebp
  800e12:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  800e15:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  800e1a:	6b d0 7c             	imul   $0x7c,%eax,%edx
  800e1d:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  800e23:	8b 52 50             	mov    0x50(%edx),%edx
  800e26:	39 ca                	cmp    %ecx,%edx
  800e28:	75 0d                	jne    800e37 <ipc_find_env+0x28>
			return envs[i].env_id;
  800e2a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800e2d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800e32:	8b 40 48             	mov    0x48(%eax),%eax
  800e35:	eb 0f                	jmp    800e46 <ipc_find_env+0x37>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  800e37:	83 c0 01             	add    $0x1,%eax
  800e3a:	3d 00 04 00 00       	cmp    $0x400,%eax
  800e3f:	75 d9                	jne    800e1a <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  800e41:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800e46:	5d                   	pop    %ebp
  800e47:	c3                   	ret    

00800e48 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800e48:	55                   	push   %ebp
  800e49:	89 e5                	mov    %esp,%ebp
  800e4b:	56                   	push   %esi
  800e4c:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800e4d:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800e50:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800e56:	e8 fa fc ff ff       	call   800b55 <sys_getenvid>
  800e5b:	83 ec 0c             	sub    $0xc,%esp
  800e5e:	ff 75 0c             	pushl  0xc(%ebp)
  800e61:	ff 75 08             	pushl  0x8(%ebp)
  800e64:	56                   	push   %esi
  800e65:	50                   	push   %eax
  800e66:	68 e8 13 80 00       	push   $0x8013e8
  800e6b:	e8 1c f3 ff ff       	call   80018c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800e70:	83 c4 18             	add    $0x18,%esp
  800e73:	53                   	push   %ebx
  800e74:	ff 75 10             	pushl  0x10(%ebp)
  800e77:	e8 bf f2 ff ff       	call   80013b <vcprintf>
	cprintf("\n");
  800e7c:	c7 04 24 da 13 80 00 	movl   $0x8013da,(%esp)
  800e83:	e8 04 f3 ff ff       	call   80018c <cprintf>
  800e88:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800e8b:	cc                   	int3   
  800e8c:	eb fd                	jmp    800e8b <_panic+0x43>
  800e8e:	66 90                	xchg   %ax,%ax

00800e90 <__udivdi3>:
  800e90:	55                   	push   %ebp
  800e91:	57                   	push   %edi
  800e92:	56                   	push   %esi
  800e93:	53                   	push   %ebx
  800e94:	83 ec 1c             	sub    $0x1c,%esp
  800e97:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800e9b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800e9f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800ea3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ea7:	85 f6                	test   %esi,%esi
  800ea9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800ead:	89 ca                	mov    %ecx,%edx
  800eaf:	89 f8                	mov    %edi,%eax
  800eb1:	75 3d                	jne    800ef0 <__udivdi3+0x60>
  800eb3:	39 cf                	cmp    %ecx,%edi
  800eb5:	0f 87 c5 00 00 00    	ja     800f80 <__udivdi3+0xf0>
  800ebb:	85 ff                	test   %edi,%edi
  800ebd:	89 fd                	mov    %edi,%ebp
  800ebf:	75 0b                	jne    800ecc <__udivdi3+0x3c>
  800ec1:	b8 01 00 00 00       	mov    $0x1,%eax
  800ec6:	31 d2                	xor    %edx,%edx
  800ec8:	f7 f7                	div    %edi
  800eca:	89 c5                	mov    %eax,%ebp
  800ecc:	89 c8                	mov    %ecx,%eax
  800ece:	31 d2                	xor    %edx,%edx
  800ed0:	f7 f5                	div    %ebp
  800ed2:	89 c1                	mov    %eax,%ecx
  800ed4:	89 d8                	mov    %ebx,%eax
  800ed6:	89 cf                	mov    %ecx,%edi
  800ed8:	f7 f5                	div    %ebp
  800eda:	89 c3                	mov    %eax,%ebx
  800edc:	89 d8                	mov    %ebx,%eax
  800ede:	89 fa                	mov    %edi,%edx
  800ee0:	83 c4 1c             	add    $0x1c,%esp
  800ee3:	5b                   	pop    %ebx
  800ee4:	5e                   	pop    %esi
  800ee5:	5f                   	pop    %edi
  800ee6:	5d                   	pop    %ebp
  800ee7:	c3                   	ret    
  800ee8:	90                   	nop
  800ee9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ef0:	39 ce                	cmp    %ecx,%esi
  800ef2:	77 74                	ja     800f68 <__udivdi3+0xd8>
  800ef4:	0f bd fe             	bsr    %esi,%edi
  800ef7:	83 f7 1f             	xor    $0x1f,%edi
  800efa:	0f 84 98 00 00 00    	je     800f98 <__udivdi3+0x108>
  800f00:	bb 20 00 00 00       	mov    $0x20,%ebx
  800f05:	89 f9                	mov    %edi,%ecx
  800f07:	89 c5                	mov    %eax,%ebp
  800f09:	29 fb                	sub    %edi,%ebx
  800f0b:	d3 e6                	shl    %cl,%esi
  800f0d:	89 d9                	mov    %ebx,%ecx
  800f0f:	d3 ed                	shr    %cl,%ebp
  800f11:	89 f9                	mov    %edi,%ecx
  800f13:	d3 e0                	shl    %cl,%eax
  800f15:	09 ee                	or     %ebp,%esi
  800f17:	89 d9                	mov    %ebx,%ecx
  800f19:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f1d:	89 d5                	mov    %edx,%ebp
  800f1f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f23:	d3 ed                	shr    %cl,%ebp
  800f25:	89 f9                	mov    %edi,%ecx
  800f27:	d3 e2                	shl    %cl,%edx
  800f29:	89 d9                	mov    %ebx,%ecx
  800f2b:	d3 e8                	shr    %cl,%eax
  800f2d:	09 c2                	or     %eax,%edx
  800f2f:	89 d0                	mov    %edx,%eax
  800f31:	89 ea                	mov    %ebp,%edx
  800f33:	f7 f6                	div    %esi
  800f35:	89 d5                	mov    %edx,%ebp
  800f37:	89 c3                	mov    %eax,%ebx
  800f39:	f7 64 24 0c          	mull   0xc(%esp)
  800f3d:	39 d5                	cmp    %edx,%ebp
  800f3f:	72 10                	jb     800f51 <__udivdi3+0xc1>
  800f41:	8b 74 24 08          	mov    0x8(%esp),%esi
  800f45:	89 f9                	mov    %edi,%ecx
  800f47:	d3 e6                	shl    %cl,%esi
  800f49:	39 c6                	cmp    %eax,%esi
  800f4b:	73 07                	jae    800f54 <__udivdi3+0xc4>
  800f4d:	39 d5                	cmp    %edx,%ebp
  800f4f:	75 03                	jne    800f54 <__udivdi3+0xc4>
  800f51:	83 eb 01             	sub    $0x1,%ebx
  800f54:	31 ff                	xor    %edi,%edi
  800f56:	89 d8                	mov    %ebx,%eax
  800f58:	89 fa                	mov    %edi,%edx
  800f5a:	83 c4 1c             	add    $0x1c,%esp
  800f5d:	5b                   	pop    %ebx
  800f5e:	5e                   	pop    %esi
  800f5f:	5f                   	pop    %edi
  800f60:	5d                   	pop    %ebp
  800f61:	c3                   	ret    
  800f62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f68:	31 ff                	xor    %edi,%edi
  800f6a:	31 db                	xor    %ebx,%ebx
  800f6c:	89 d8                	mov    %ebx,%eax
  800f6e:	89 fa                	mov    %edi,%edx
  800f70:	83 c4 1c             	add    $0x1c,%esp
  800f73:	5b                   	pop    %ebx
  800f74:	5e                   	pop    %esi
  800f75:	5f                   	pop    %edi
  800f76:	5d                   	pop    %ebp
  800f77:	c3                   	ret    
  800f78:	90                   	nop
  800f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f80:	89 d8                	mov    %ebx,%eax
  800f82:	f7 f7                	div    %edi
  800f84:	31 ff                	xor    %edi,%edi
  800f86:	89 c3                	mov    %eax,%ebx
  800f88:	89 d8                	mov    %ebx,%eax
  800f8a:	89 fa                	mov    %edi,%edx
  800f8c:	83 c4 1c             	add    $0x1c,%esp
  800f8f:	5b                   	pop    %ebx
  800f90:	5e                   	pop    %esi
  800f91:	5f                   	pop    %edi
  800f92:	5d                   	pop    %ebp
  800f93:	c3                   	ret    
  800f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f98:	39 ce                	cmp    %ecx,%esi
  800f9a:	72 0c                	jb     800fa8 <__udivdi3+0x118>
  800f9c:	31 db                	xor    %ebx,%ebx
  800f9e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800fa2:	0f 87 34 ff ff ff    	ja     800edc <__udivdi3+0x4c>
  800fa8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800fad:	e9 2a ff ff ff       	jmp    800edc <__udivdi3+0x4c>
  800fb2:	66 90                	xchg   %ax,%ax
  800fb4:	66 90                	xchg   %ax,%ax
  800fb6:	66 90                	xchg   %ax,%ax
  800fb8:	66 90                	xchg   %ax,%ax
  800fba:	66 90                	xchg   %ax,%ax
  800fbc:	66 90                	xchg   %ax,%ax
  800fbe:	66 90                	xchg   %ax,%ax

00800fc0 <__umoddi3>:
  800fc0:	55                   	push   %ebp
  800fc1:	57                   	push   %edi
  800fc2:	56                   	push   %esi
  800fc3:	53                   	push   %ebx
  800fc4:	83 ec 1c             	sub    $0x1c,%esp
  800fc7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800fcb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800fcf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800fd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800fd7:	85 d2                	test   %edx,%edx
  800fd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800fdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fe1:	89 f3                	mov    %esi,%ebx
  800fe3:	89 3c 24             	mov    %edi,(%esp)
  800fe6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800fea:	75 1c                	jne    801008 <__umoddi3+0x48>
  800fec:	39 f7                	cmp    %esi,%edi
  800fee:	76 50                	jbe    801040 <__umoddi3+0x80>
  800ff0:	89 c8                	mov    %ecx,%eax
  800ff2:	89 f2                	mov    %esi,%edx
  800ff4:	f7 f7                	div    %edi
  800ff6:	89 d0                	mov    %edx,%eax
  800ff8:	31 d2                	xor    %edx,%edx
  800ffa:	83 c4 1c             	add    $0x1c,%esp
  800ffd:	5b                   	pop    %ebx
  800ffe:	5e                   	pop    %esi
  800fff:	5f                   	pop    %edi
  801000:	5d                   	pop    %ebp
  801001:	c3                   	ret    
  801002:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801008:	39 f2                	cmp    %esi,%edx
  80100a:	89 d0                	mov    %edx,%eax
  80100c:	77 52                	ja     801060 <__umoddi3+0xa0>
  80100e:	0f bd ea             	bsr    %edx,%ebp
  801011:	83 f5 1f             	xor    $0x1f,%ebp
  801014:	75 5a                	jne    801070 <__umoddi3+0xb0>
  801016:	3b 54 24 04          	cmp    0x4(%esp),%edx
  80101a:	0f 82 e0 00 00 00    	jb     801100 <__umoddi3+0x140>
  801020:	39 0c 24             	cmp    %ecx,(%esp)
  801023:	0f 86 d7 00 00 00    	jbe    801100 <__umoddi3+0x140>
  801029:	8b 44 24 08          	mov    0x8(%esp),%eax
  80102d:	8b 54 24 04          	mov    0x4(%esp),%edx
  801031:	83 c4 1c             	add    $0x1c,%esp
  801034:	5b                   	pop    %ebx
  801035:	5e                   	pop    %esi
  801036:	5f                   	pop    %edi
  801037:	5d                   	pop    %ebp
  801038:	c3                   	ret    
  801039:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801040:	85 ff                	test   %edi,%edi
  801042:	89 fd                	mov    %edi,%ebp
  801044:	75 0b                	jne    801051 <__umoddi3+0x91>
  801046:	b8 01 00 00 00       	mov    $0x1,%eax
  80104b:	31 d2                	xor    %edx,%edx
  80104d:	f7 f7                	div    %edi
  80104f:	89 c5                	mov    %eax,%ebp
  801051:	89 f0                	mov    %esi,%eax
  801053:	31 d2                	xor    %edx,%edx
  801055:	f7 f5                	div    %ebp
  801057:	89 c8                	mov    %ecx,%eax
  801059:	f7 f5                	div    %ebp
  80105b:	89 d0                	mov    %edx,%eax
  80105d:	eb 99                	jmp    800ff8 <__umoddi3+0x38>
  80105f:	90                   	nop
  801060:	89 c8                	mov    %ecx,%eax
  801062:	89 f2                	mov    %esi,%edx
  801064:	83 c4 1c             	add    $0x1c,%esp
  801067:	5b                   	pop    %ebx
  801068:	5e                   	pop    %esi
  801069:	5f                   	pop    %edi
  80106a:	5d                   	pop    %ebp
  80106b:	c3                   	ret    
  80106c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801070:	8b 34 24             	mov    (%esp),%esi
  801073:	bf 20 00 00 00       	mov    $0x20,%edi
  801078:	89 e9                	mov    %ebp,%ecx
  80107a:	29 ef                	sub    %ebp,%edi
  80107c:	d3 e0                	shl    %cl,%eax
  80107e:	89 f9                	mov    %edi,%ecx
  801080:	89 f2                	mov    %esi,%edx
  801082:	d3 ea                	shr    %cl,%edx
  801084:	89 e9                	mov    %ebp,%ecx
  801086:	09 c2                	or     %eax,%edx
  801088:	89 d8                	mov    %ebx,%eax
  80108a:	89 14 24             	mov    %edx,(%esp)
  80108d:	89 f2                	mov    %esi,%edx
  80108f:	d3 e2                	shl    %cl,%edx
  801091:	89 f9                	mov    %edi,%ecx
  801093:	89 54 24 04          	mov    %edx,0x4(%esp)
  801097:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80109b:	d3 e8                	shr    %cl,%eax
  80109d:	89 e9                	mov    %ebp,%ecx
  80109f:	89 c6                	mov    %eax,%esi
  8010a1:	d3 e3                	shl    %cl,%ebx
  8010a3:	89 f9                	mov    %edi,%ecx
  8010a5:	89 d0                	mov    %edx,%eax
  8010a7:	d3 e8                	shr    %cl,%eax
  8010a9:	89 e9                	mov    %ebp,%ecx
  8010ab:	09 d8                	or     %ebx,%eax
  8010ad:	89 d3                	mov    %edx,%ebx
  8010af:	89 f2                	mov    %esi,%edx
  8010b1:	f7 34 24             	divl   (%esp)
  8010b4:	89 d6                	mov    %edx,%esi
  8010b6:	d3 e3                	shl    %cl,%ebx
  8010b8:	f7 64 24 04          	mull   0x4(%esp)
  8010bc:	39 d6                	cmp    %edx,%esi
  8010be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8010c2:	89 d1                	mov    %edx,%ecx
  8010c4:	89 c3                	mov    %eax,%ebx
  8010c6:	72 08                	jb     8010d0 <__umoddi3+0x110>
  8010c8:	75 11                	jne    8010db <__umoddi3+0x11b>
  8010ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
  8010ce:	73 0b                	jae    8010db <__umoddi3+0x11b>
  8010d0:	2b 44 24 04          	sub    0x4(%esp),%eax
  8010d4:	1b 14 24             	sbb    (%esp),%edx
  8010d7:	89 d1                	mov    %edx,%ecx
  8010d9:	89 c3                	mov    %eax,%ebx
  8010db:	8b 54 24 08          	mov    0x8(%esp),%edx
  8010df:	29 da                	sub    %ebx,%edx
  8010e1:	19 ce                	sbb    %ecx,%esi
  8010e3:	89 f9                	mov    %edi,%ecx
  8010e5:	89 f0                	mov    %esi,%eax
  8010e7:	d3 e0                	shl    %cl,%eax
  8010e9:	89 e9                	mov    %ebp,%ecx
  8010eb:	d3 ea                	shr    %cl,%edx
  8010ed:	89 e9                	mov    %ebp,%ecx
  8010ef:	d3 ee                	shr    %cl,%esi
  8010f1:	09 d0                	or     %edx,%eax
  8010f3:	89 f2                	mov    %esi,%edx
  8010f5:	83 c4 1c             	add    $0x1c,%esp
  8010f8:	5b                   	pop    %ebx
  8010f9:	5e                   	pop    %esi
  8010fa:	5f                   	pop    %edi
  8010fb:	5d                   	pop    %ebp
  8010fc:	c3                   	ret    
  8010fd:	8d 76 00             	lea    0x0(%esi),%esi
  801100:	29 f9                	sub    %edi,%ecx
  801102:	19 d6                	sbb    %edx,%esi
  801104:	89 74 24 04          	mov    %esi,0x4(%esp)
  801108:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80110c:	e9 18 ff ff ff       	jmp    801029 <__umoddi3+0x69>
